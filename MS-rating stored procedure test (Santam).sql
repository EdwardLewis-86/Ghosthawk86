USE [MSureEvolve]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ================================================================================
-- Author: Lucas MANGANYI (Modified version)
-- Create date: 22 September 2025
-- Description: This stored procedure computes the Santam_Quote_Renewal premium.
-- Version: 1.0.1
-- ================================================================================
CREATE PROCEDURE [dbo].[Santam_Quote_Test]
@ratinggroup varchar(20),
@planoption varchar(50),
@premiumfrequency varchar(20),
@term int,
@effectivedate date,
@OEMactive int,
@servicehistory int,
@regdate date,
@make varchar(50),
@MMcode varchar(20),
@odometerreading float,
@productcode varchar(20),
@section varchar(20)
AS
BEGIN
SET NOCOUNT ON;
--Define variables
Declare
@premium float,
@ratingstatus varchar(200),
@quote float,
@vat float,
@rate bit,
@ratinggroup_count int,
@effectivedate_count int,
@premiumfrequncy_count int,
@term_count int,
@plan_count int,
@section_count int,
@make_count int,
@service_history_count int,
@OEMactive_count int,
@criteria int,
@vehicle_age int,
@ageFrom int,
@ageTo int,
@maxAge int,
@minAgeBand int,
@planAvailableForAge int,
@power float,
@mass float,
@power_mass_inverse float,
@makeCategory varchar(50),
@OEMCheck varchar(500),
@exclusions int,
@mmcodecount int,
@brands int,
@avgPrice float,
@pmrExcluded int,
@odometerLimit float,
@VehicleMass float,
@messageCode varchar(4),
@Cohort int,
@plancategory varchar(20); -- New variable for plan categorization


set @effectivedate = GETDATE();

-- NEW: Map the detailed plan option to a simplified category
-- This maps all the various plan options to their base categories
SET @plancategory = CASE 
    WHEN @planoption IN ('Bronze Less than 5 years', 'Bronze Less than 6 years', 
                          'Bronze Less than 8 years', 'Bronze Less than 10 years', 
                          'Bronze Less than 12 years', 'Bronze Less than 15 years') 
        THEN 'Bronze'
    WHEN @planoption IN ('Silver Less than 5 years', 'Silver Less than 6 years', 
                          'Silver Less than 8 years', 'Silver Less than 10 years', 
                          'Silver Less than 12 years', 'Silver Less than 15 years') 
        THEN 'Silver'
    WHEN @planoption IN ('Gold Less than 5 years', 'Gold Less than 6 years', 
                          'Gold Less than 8 years', 'Gold Less than 10 years', 
                          'Gold Less than 12 years', 'Gold Less than 15 years') 
        THEN 'Gold'
    WHEN @planoption IN ('Platinum Less than 5 years', 'Platinum Less than 6 years', 
                          'Platinum Less than 8 years', 'Platinum Less than 10 years', 
                          'Platinum Less than 12 years', 'Platinum Less than 15 years') 
        THEN 'Platinum'
    WHEN @planoption IN ('Chrome Less than 5 years', 'Chrome Less than 6 years', 
                          'Chrome Less than 8 years', 'Chrome Less than 10 years', 
                          'Chrome Less than 12 years', 'Chrome Less than 15 years') 
        THEN 'Chrome'
    WHEN @planoption IN ('Titanium Less than 5 years', 'Titanium Less than 6 years', 
                          'Titanium Less than 8 years', 'Titanium Less than 10 years', 
                          'Titanium Less than 12 years', 'Titanium Less than 15 years') 
        THEN 'Titanium'
    ELSE @planoption -- Keep original if not matching any pattern
END;

Set @VehicleMass = (Select distinct top(1) mass from ViewVehicleModels where ADG_CODE = @MMcode)

If (@VehicleMass > 3500)
Begin
    set @messageCode = '0018'
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Vehicle has GVM greater than 3500kg ';
    Set @quote = -1;

    select @quote Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return;
End

Set @make = isnull((Select top (1) brand from ViewVehicleModels where ADG_CODE = @MMcode), @make);

--Check if user stated that the manufacturer warranty is still active
if (@OEMactive = 1)
Begin
    set @messageCode = '0001'
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated. OEM warranty stated as being still active.'

    select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if mm code and make combination are available
set @mmcodecount = (select COUNT(*) n from ViewVehicleModels where ADG_CODE = @MMcode); -- check if mm code exists
if (@mmcodecount = 0)
Begin
    set @messageCode = '0002'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated. MM Code and Make not on our records.'

Select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End
Else --MM Code exists in Disk Drive
Begin
Set @avgPrice = (Select AVG(cast(Price as float)) from ViewVehicleModels where ADG_CODE = @MMcode);
End

--Check if policy is still within two months of the expiry of the manufacturer warranty
create table #t (POL_START_DATE date, POL_END_DATE date, START_DATE_CRITERIA varchar(200), MATCHING_CRITERIA varchar(200), RATING_STATUS varchar(200), QUOTE_ID varchar(70))
insert into #t (POL_START_DATE, POL_END_DATE, START_DATE_CRITERIA, MATCHING_CRITERIA, RATING_STATUS, QUOTE_ID)
exec spMS_CalculateWarrantyStartDate
@vehicle_make = @make,
@mm_code = @MMcode,
@first_reg_date = @regdate,
@vehicle_mileage = @odometerreading,
@veh_still_in_OEM_wty = 'yes',
@product = 'BE172608-9E28-431A-A7B6-35C5DE4E2CF4', --This is the product key for the OMI quick qoute extended warranty
@purchase_date = @effectivedate,
@policy_term = 12,
@policy_effective_date = @effectivedate,
@policy_end_date = @effectivedate,
@quote_id = 'OneTwo_Testing'
; --- to make it a term policy as opposed to a monthly product

set @OEMCheck = (select
case
when POL_START_DATE > DateAdd(month, 2, @effectivedate) then
'Tariff not calculated. Vehicle more than two months from expiry of the manufacturer warranty.'
else
'Pass'
end
from #t);
-- Terminate if the OEM warranty is still active and OEMActive is zero.
if (@OEMCheck != 'Pass' )   ---
Begin
  set @messageCode = '0017'
  Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode) --'Tariff not calculated. Vehicle more than two months from expiry of the manufacturer warranty.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if the premium frequency is valid
Set @premiumfrequncy_count = (select case when (@premiumfrequency = 'Monthly') or (@premiumfrequency = 'Annual') then 1 else 0 end);
if (@premiumfrequncy_count = 0)
Begin
    set @messageCode = '0003'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Invalid premium frequency.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if the term is valid
Set @term_count = (select case when (@premiumfrequency = 'Monthly' and @term = 1) or (@premiumfrequency = 'Annual' and @term = 12) then 1 else 0 end);
if (@term_count = 0)
Begin
    set @messageCode = '0004'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Invalid term for the supplied premium frequency.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if rating group is valid
Set @ratinggroup_count = (select count(distinct ratinggroup) from ms_santam_rating where ratinggroup = @ratinggroup and effectivedate = (select max(effectivedate) from ms_santam_rating where effectivedate <= @effectivedate and ratinggroup = @ratinggroup));
if (@ratinggroup_count = 0)
Begin
    set @messageCode = '0005'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Invalid rating group.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if Age is applicable
Set @maxAge = (select max(AgeTo) from ms_santam_rating);
Set @vehicle_age = DATEDIFF(day,@regdate, @effectivedate); --vehicle age in days
If (@vehicle_age * 1.0000 / 365 > @maxAge)
Begin
    set @messageCode = '0006'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Vehicle age not eligible for cover on any plan.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if odometer reading is still permissible
If (@odometerreading > 300000)
Begin
    set @messageCode = '0007'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Vehicle odometer reading not permissible for cover on any plan.' 

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if service history indicator is valid
Set @service_history_count = (select case when (@servicehistory = 1 or @servicehistory = 0) then 1 else 0 end);
If (@service_history_count = 0)
Begin
    set @messageCode = '0008'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Service history indicator not valid.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if the OEM warranty indicator is valid
Set @OEMactive_count = (select case when (@OEMactive = 1 or @OEMactive = 0) then 1 else 0 end);
If (@OEMactive_count = 0)
Begin
    set @messageCode = '0009'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: OEM warranty indicator not valid.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if TITANIUM and no service history - use the categorized plan value
If ((@OEMactive_count = 0) and (@plancategory = 'TITANIUM'))
Begin
    set @messageCode = '0010'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Up-to-date service history is required for TITANIUM cover.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if plan is valid - use the categorized plan value
Set @plan_count = (select case when @plancategory IN (select distinct planoption from ms_santam_rating) then 1 else 0 end);
if (@plan_count = 0)
Begin
    set @messageCode = '0011'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Plan not valid.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check if the section is valid
Set @section_count = (select case when @section IN (select distinct section from ms_santam_rating) then 1 else 0 end);
if (@section_count = 0)
Begin
    set @messageCode = '0012'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Section not valid.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Exclusions by Power to Mass relationship
set @pmrExcluded = (select COUNT(*) from pmrExclusions where mmcode = @MMcode);
if (@pmrExcluded > 0)
begin
    set @messageCode = '0013'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); -- 'Tariff not calculated. Vehicle classified as an exotic due to high power to mass ratio.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
end

-- Exclusions by Make
set @exclusions = (select COUNT(*) from vehiclemakeexclusions where LOWER(make) = LOWER(@make));
if (@exclusions > 0)
Begin
    set @messageCode = '0014'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated. Vehicle make classified as an exotic.' 

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

--Process the make category descriptions
if(LOWER(@make) = 'volkswagen')
begin
select distinct [Desc]
, case
when LOWER([Desc]) like '%polo%' then
1
else
0
end Polo
into #vw
from [ViewVehicleModels]
where ADG_CODE = @MMcode;
set @makeCategory = (select
case
when (select sum(Polo) from #vw) > 0 then
'VOLKSWAGEN Polo'
else
'VOLKSWAGEN Other'
end);

drop table #vw;
end
else if (lower(@make) = 'ford')
begin
select distinct [Desc],
case
when LOWER([Desc]) like '%ranger%' then 1
when lower([Desc]) like '%everest%' then 1
else 0
end RangerEverest
into #ford
from [ViewVehicleModels] where ADG_CODE = @MMcode;
set @makeCategory = (select case when (select sum(RangerEverest) from #ford) > 0 then 'FORD Ranger and Everest' else 'FORD Other' end);
drop table #ford;
end
else if (lower(@make) = 'toyota')
begin
-- Get the average price of a double cab toyota hilux
Declare @avgHiluxPrice float;
set @avgHiluxPrice = (select avg(cast(price as float)) from [ViewVehicleModels] where brand like 'TOYOTA' and range like '%HILUX%' and doors = 4)
select distinct [Desc],
cast(price as float) Price
into #toyota
from [ViewVehicleModels]
where ADG_CODE = @MMcode;
set @makeCategory = (select case when (select avg(price) from #toyota) >= @avgHiluxPrice then 'TOYOTA High' else 'TOYOTA Other' end);
drop table #toyota;
end

--Get inputs
Set @vat = (select vat from ms_rating_vat where effectivedate = (select max(effectivedate) from ms_rating_vat where effectivedate <= @effectivedate));
Set @minAgeBand = (select min(AgeTo) from ms_santam_rating);
Set @make_count = (select case when @make in (select distinct make from ms_santam_rating)
then 1 else 0 end)
if (@make_count > 0)
Begin
set @makeCategory = @make;
End

if (@makeCategory is null) --Process Other
Begin
Set @makeCategory = (Select case when @avgPrice <= 200000 then 'OTHER Low' when @avgPrice <= 300000 then 'OTHER Standard' else 'OTHER High' end);
End

Set @ageTo = (select
case when (@vehicle_age * 1.0000/365.25) > @maxAge then null
when (@vehicle_age * 1.0000/365.25) <= @minAgeBand then @minAgeBand
else (select top(1) AgeTo from ms_santam_rating where AgeTo > (@vehicle_age * 1.0000/365.25) order by AgeTo asc)
end);
Set @ageFrom = (select case when @ageTo is null then null
else (select distinct AgeFrom from ms_santam_rating where AgeTo = @ageto)
end);
-- Check Age
if (@ageTo is null)
Begin
    set @messageCode = '0015'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Vehicle age not eligible for cover.' 

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
End

-- Check plan availability using the categorized plan value
Set @planAvailableForAge = (select count(*) from ms_santam_rating where AgeFrom = @ageFrom and AgeTo = @ageTo and Make = @makeCategory and PlanOption = @plancategory and
Effectivedate = (select max(effectivedate)
from ms_santam_rating
where effectivedate <= @effectivedate
and ratinggroup = @ratinggroup
and section = @section
and make = @makeCategory
and agefrom = @ageFrom
and ageTo = @ageTo
and planoption = @plancategory));

If (@planAvailableForAge = 0)
Begin
    set @messageCode = '0016'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode);  --'Tariff not calculated: Vehicle not eligible to be covered under the plan '

select -1 Premium, @ratingstatus + @plancategory RatingStatus, @messageCode Message_Code;
return
End

-- Check the odometer limit
Set @odometerLimit = (Select distinct OdometerLimit from ms_santam_rating where ratinggroup = @ratinggroup 
and section = 'Warranty'
and AgeFrom = @ageFrom);

-- Determine the cohort
Set @Cohort = (select case when @vehicle_age * 1.0000 / 365 <= 5 and @odometerreading < 100000 then 1
                       when @vehicle_age * 1.0000 / 365 <= 8 and @odometerreading < 160000 then 2
                       when @vehicle_age * 1.0000 / 365 <= 10 and @odometerreading < 200000 then 3
                       when @vehicle_age * 1.0000 / 365 <= 12 and @odometerreading < 250000 then 4
                       when @vehicle_age * 1.0000 / 365 <= 15 and @odometerreading < 300000 then 5
                       else 999 end);

-- Use the categorized plan value for cohort restrictions
if (@Cohort = 2 and @plancategory in ('Titanium')) 
or (@Cohort = 3 and @plancategory in ('Titanium', 'Platinum'))
or (@Cohort = 4 and @plancategory in ('Titanium', 'Platinum', 'Gold'))
or (@Cohort = 5 and @plancategory in ('Titanium', 'Platinum', 'Gold', 'Silver'))
begin
    set @messageCode = '0016'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Vehicle not eligible to be covered under the plan '

select -1 Premium, @ratingstatus + @plancategory RatingStatus, @messageCode Message_Code;
return
end

if (@Cohort = 999)
begin
    set @messageCode = '0017'	
    Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode); --'Tariff not calculated: Vehicle not eligible to be covered under any plan.'

select -1 Premium, @ratingstatus RatingStatus, @messageCode Message_Code;
return
end

--Calculate rates - use the categorized plan value
IF (@section ='Warranty')
Begin
Set @premium = (select premium_exclVAT
from ms_santam_rating
where ratinggroup = @ratinggroup
and section = @section
and make = @makeCategory
and agefrom = @ageFrom
and ageTo = @ageTo
and planoption = @plancategory
and effectivedate =
(select max(effectivedate)
from ms_santam_rating
where effectivedate <= @effectivedate
and ratinggroup = @ratinggroup
and section = @section
and make = @makeCategory
and agefrom = @ageFrom
and ageTo = @ageTo
and planoption = @plancategory));

Set @quote = (select case when @term = 1 then @premium * (1 + @vat) else @premium * (1 + @vat) * 11 end);
set @messageCode = '0000'
Set @ratingstatus = (select Message from Message_Code where messageCode = @messageCode) + cast(@plancategory as varchar(20));  --'Success: Eligible for plan '
------Present results
select case when @effectivedate >= '25-Jul-2022' then isnull(floor(@quote),-1) else isnull(round(@quote, 2),-1) end as Premium, @ratingstatus as RatingStatus, @messageCode Message_Code;
End

END