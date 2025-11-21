--use [Evolve]

drop table if exists #claims;
drop table if exists #claims2;
drop table if exists #claims3;
drop table if exists #claims4;
drop table if exists #Pol;
drop table if exists #res;
drop table if exists #res2;
drop table if exists #res3;
drop table if exists #res4;
drop table if exists #res5;
drop table if exists #res6;
drop table if exists #res7;
drop table if exists #res8;
drop table if exists #res9;
drop table if exists #res10;
drop table if exists #res11;
drop table if exists #CriteriaTab;
drop table if exists #Toyota;
drop table if exists #Toyota2;
drop table if exists #OtherCars;
--drop table if exists #ms_santam_rating;

--Assumptions

Declare @RatingDate date = Getdate();

Declare @vat float = 0.15
Declare @PerIncChange float = 1.2
Declare @PerDecChange float = 0.8
Declare @InflationInc float = 1.06
Declare @MaxIncrease float = 1.2



--select @avgHiluxPrice
--Create tables
CREATE TABLE #CriteriaTab (
    C_Criteria int,
    C_AgeFrom int,
    C_AgeTo int,
	C_OdometerLimit int
);

--Insert into tables

insert into #CriteriaTab Values	(1,0,5,100000);	
insert into #CriteriaTab Values	(2,5,8,160000);	
insert into #CriteriaTab Values	(3,8,10,200000);	
insert into #CriteriaTab Values	(4,10,12,250000);	
insert into #CriteriaTab Values	(5,12,15,300000);	

--SELECT *  INTO 
--#ms_santam_rating 
--FROM  [MSureEvolve].[dbo].[ms_santam_rating] 

--select * from #CriteriaTab 

--Policy Info of only active policies with original start date and original premium and original KM

SELECT [POL_PolicyNumber]
      ,Policy_ID
	  ,ITS_Item_ID
	  ,[PMI_VehicleCode]
	  ,[PMI_Make] [PMI_MakeOriginal]
      ,isnull((select distinct Brand from [MSureEvolve].[dbo].[ViewVehicleModels]  
	              where ADG_CODE = [PMI_VehicleCode]),[PMI_Make]) [PMI_Make]
      ,[PMI_Model]
	  ,[PRP_PlanName]
	  ,[PDS_SectionGrouping]
      ,[ITS_SumInsured]
      ,[ITS_Premium]
	  ,[PMI_PresentKM]
      ,[ITS_Status]
	  ,[RTF_Description]
	  ,POL_OriginalStartDate
	  ,[PMI_RegistrationDate]
	  ,[PMI_PurchaseDate]
	  
	  ,case when POL_SoldDate>='2024-01-01' and POL_SoldDate <'2024-01-23' then '2023-12-31' else POL_SoldDate end POL_SoldDate
	  ,POL_ReceivedDate
	  ,PMI_LastRatedDate
	  ,[PMI_MileageDate]
      ,[ITS_StartDate]
      ,[ITS_EndDate]
	  ,[POL_RenewalDate]

  into #Pol

  FROM [Evolve].[dbo].[ItemSummary]

  left join [Evolve].[dbo].Policy on [ITS_Policy_ID] = Policy_ID
  left join [Evolve].[dbo].[PolicyMechanicalBreakdownItem] on [PolicyMechanicalBreakdownItem_ID] = ITS_Item_ID
  left join [Evolve].[dbo].[ReferenceTermFrequency] on [POL_ProductTerm_ID] = [TermFrequency_Id]
  left join [Evolve].[dbo].[ProductPlans] on [ProductPlans_Id] = [PMI_Plan_ID]
  left join [Evolve].[dbo].[ProductSection] on [ProductSection_Id] = [PMI_Section_ID]
  where 1=1
  --      and [POL_PolicyNumber] --like 'S%'
		
		--in

		--(
		

		--)
		--and POL_PolicyNumber LIKE '%SWTY000021POL%'

		    and POL_PolicyNumber like 'SW%'

	  and POL_PolicyNumber like 'SW%Pol'

    and POL_Status in (1,3)

  --  and PMI_Make = 'Ford'

	and POL_StartDate <= POL_EndDate

	


	SELECT * FROM #Pol
	--	and [POL_Status]=1

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Claims info for policies that has claimed for in the last 365 days

SELECT [ClaimItemSummary_ID]
      ,[CWI_PolicyWarrantyItem_ID]
      ,[CIS_CreateUser_ID]
      ,[CIS_CreateDate]
      ,[CIS_UpdateUser_ID]
      ,[CIS_UpdateDate]
     -- ,[CIS_Deleted]
      ,[CIS_AssignedUser_ID]
      ,[CIS_Section_ID]
      ,[CIS_Claim_ID]
      ,[CIS_ClaimItem_ID]
      ,[CIS_SectionLossType_ID]
      ,[CIS_Plan_ID]
  --   ,[CIS_Description]
      ,[CIS_ClaimDescription]
      ,[CIS_LossTypeDescription]
      ,[CIS_ClaimItemDescription]
      ,[CIS_PlanName]
      ,[CIS_Status]
	  ,[CWI_OdoMeterReading]
	  ,[CWI_FailureDate]
      ,[CIS_SumInsured]
      ,[CIS_Estimate] CIS_AuthAmount
      ,[CIS_Paid]
      ,[CIS_OutstandingEstimate]
      ,[CIS_ThirdPartyAmount]
      ,[CIS_OwnDamageAmount]
      ,[CIS_Policy_ID]
      ,[CIS_PolicyNumber]
      ,[CIS_ClaimNumber]
      ,[CIS_LossDate]
      ,[CIS_SectionName]
      ,[CIS_AuthorizationNumber]
      ,[CIS_AuthBy]
      ,[CIS_AuthDate]
     -- ,[CIS_AuthAmount]
      ,[CIS_MaxLiability]
      ,[CIS_ClaimType_ID]
      ,[CIS_SubAuthAmount]
      ,[CIS_PendingReasons]
      ,[CIS_AbandonedReason]
	  ,[CLS_Description]
	  ,d.[CIS_Description]

	  into #claims

  FROM [Evolve].[dbo].[ClaimItemSummary] a

  left join [Evolve].[dbo].[Claim] on [CLM_ClaimNumber] = [CIS_ClaimNumber]
  left join [Evolve].[dbo].[ReferenceClaimstatus] on [ClaimStatus_ID] = [CLM_Status]
  left join [Evolve].[dbo].[ReferenceClaimitemstatus] d on [ClaimItemStatus_ID] = [CIS_Status]
  left join [Evolve].[dbo].[ClaimWarrantyItem] on [CIS_ClaimItem_ID] = [ClaimWarrantyItem_ID] 
  where 1=1
       -- and [CIS_Policy_ID] = 'DFC34627-44B8-4078-B1C6-28EC16C8B049'
	    --and [CLS_Description] <>'Rejected'
		--and CIS_PolicyNumber LIKE '%SWTY000021POL%'
		--

		--and d.[CIS_Description] <>'Rejected'
		and a.[CIS_Deleted] = 0
		and [CIS_CreateDate]>= DATEADD(day,-365,@RatingDate)
		and CIS_PolicyNumber in (select [POL_PolicyNumber] from #pol)

		--SELECT * FROM #claims2

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- This groups the claims by different product plan or policies

select [CWI_PolicyWarrantyItem_ID] ,count(distinct CIS_ClaimNumber) ClaimsCount
 
 into #claims2

 from #Claims

  where 1=1
  
  and CIS_AuthAmount>0
  --and CWI_PolicyWarrantyItem_ID = '103E270B-83A3-4241-B7E3-EB64F063DD33'

 
 group by [CWI_PolicyWarrantyItem_ID]


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


 select o.[CWI_PolicyWarrantyItem_ID] ,ClaimsCount,sum(CIS_AuthAmount) CIS_AuthAmount, [CWI_OdoMeterReading],[CWI_FailureDate]

 into #claims3 

 from  #claims2 c 

 left join #Claims o on o.[CWI_PolicyWarrantyItem_ID] = c.[CWI_PolicyWarrantyItem_ID]




 group by o.[CWI_PolicyWarrantyItem_ID] ,[CWI_OdoMeterReading],[CWI_FailureDate],ClaimsCount

 ----------------------------------------------------------------------------------------------------------------


 select [CWI_PolicyWarrantyItem_ID],ClaimsCount,sum(CIS_AuthAmount) CIS_AuthAmount, max([CWI_OdoMeterReading]) [CWI_OdoMeterReading]
        ,max([CWI_FailureDate]) [CWI_FailureDate]

 into #claims4

 from #Claims3



 group by [CWI_PolicyWarrantyItem_ID],ClaimsCount


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 -- joins the claims information to each of the original policies - still no renewals here
 
 select p.*,c.*
 
 into #res 

 from #pol p
 left join #claims4 c on  ITS_Item_ID  = [CWI_PolicyWarrantyItem_ID]
-- left join [MSureEvolve].[dbo].[ViewVehicleModels] on [ADG_CODE] = PMI_VehicleCode

 order by POL_PolicyNumber

 select * from #res
------------------------------------------------------------------------------------------------------------------------------------------
Select ADG_CODE, AVG(cast(Price as float)) AvePrice 

into #OtherCars

from [MSureEvolve].[dbo].[ViewVehicleModels] group by ADG_CODE
---------------------------------------------------------------------------------------------------------------------------------------------------------
select distinct ADG_CODE,[Desc],
cast(price as float) Price
into #toyota
from [MSureEvolve].[dbo].[ViewVehicleModels]
where brand like 'TOYOTA'


---------------------------------------------------------------------------------------------------------------------------------
select ADG_CODE ,avg(Price) ToyotaPrice
into #toyota2
from #toyota
group by ADG_CODE


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Declare @avgHiluxPrice float= (select avg(cast(price as float)) 
                               from [MSureEvolve].[dbo].[ViewVehicleModels] 
							   where brand like 'TOYOTA' and range like '%HILUX%' and doors = 4)


select *,case when PMI_Make ='Volkswagen' and PMI_Model like '%polo%' then 'VOLKSWAGEN Polo'
         when PMI_Make ='Volkswagen' and PMI_Model not like '%polo%' then 'VOLKSWAGEN Other'
         when PMI_Make ='Ford' and PMI_Model like '%ranger%'  then 'FORD Ranger and Everest'
		 when PMI_Make ='Ford' and PMI_Model like '%everest%'  then 'FORD Ranger and Everest'
		 when PMI_Make ='Ford'  then 'FORD Other'
		 when PMI_Make ='Toyota' and (select ToyotaPrice from #toyota2 where PMI_VehicleCode = ADG_CODE ) >= @avgHiluxPrice 
		 then 'TOYOTA High' 
		 when PMI_Make ='Toyota' and (select ToyotaPrice from #toyota2 where PMI_VehicleCode = ADG_CODE ) < @avgHiluxPrice  
		 then 'TOYOTA Other' 
		 when PMI_Make COLLATE DATABASE_DEFAULT in (select distinct make from [MSureEvolve].[dbo].[ms_santam_rating] ) then PMI_Make
         when  (select avePrice from #OtherCars where ADG_CODE = PMI_VehicleCode ) <= 200000 then 'OTHER Low' 
		 when  (select avePrice from #OtherCars where ADG_CODE = PMI_VehicleCode ) <= 300000 then 'OTHER Standard' 
		 else 'OTHER High'

		--else PMI_Make 
		end Make

		
		


	--	select * from #OtherCars

        ,'Standard' RatingG , 'Warranty' Sect_ion--, case when 

        ,((DATEDIFF(day,PMI_RegistrationDate,case when POL_PolicyNumber like '%-%' then ITS_StartDate 
		 else POL_SoldDate end )*1.000000-
		      (case when DATEDIFF(day,POL_ReceivedDate,POL_SoldDate) <35 and POL_ReceivedDate < POL_SoldDate  then DATEDIFF(day,POL_ReceivedDate,POL_SoldDate) else 35 end)  )/365) VehicleAgeAtStart

		         ,(DATEDIFF(day,PMI_RegistrationDate,case when POL_PolicyNumber like '%-%' then ITS_StartDate
				 
		 else POL_ReceivedDate end )*1.000000/365) VehicleAgeAtReceivedDate

        ,(DATEDIFF(day,PMI_RegistrationDate,POL_RenewalDate)*1.000000/365) VehicleAgeAtRenewal
		,ISNULL(CWI_OdoMeterReading,PMI_PresentKM) latestOdoMeterReading
		,ISNULL(CWI_FailureDate,case when PMI_MileageDate=0 then (case when POL_PolicyNumber like '%-%' then ITS_StartDate 
		 else POL_SoldDate end) else PMI_MileageDate end ) latestMileageDate

into #res2 
from #res 

select * from #res2
-------------------------------------------------------------------------------------------------------------------------------------------------
-- projects the initial policies odometer rating at renewal - why not use existing information if the policy has renewed

Declare @AssumedMonthlyKMs int = 2000;

select *,case when VehicleAgeAtStart * 1.0000  <= 5 and PMI_PresentKM < 100000 then 1
              when VehicleAgeAtStart * 1.0000  <= 8 and PMI_PresentKM < 160000 then 2
              when VehicleAgeAtStart * 1.0000  <= 10 and PMI_PresentKM < 200000 then 3
              when VehicleAgeAtStart * 1.0000  <= 12 and PMI_PresentKM < 250000 then 4
              when VehicleAgeAtStart * 1.0000  <= 15 and PMI_PresentKM < 300000 then 5
              else 999 end CriteriaStart

      ,case when VehicleAgeAtStart * 1.0000  <= 5 and PMI_PresentKM < 100000 then 1
              when VehicleAgeAtStart * 1.0000  <= 8 and PMI_PresentKM < 160000 then 2
              when VehicleAgeAtStart * 1.0000  <= 10 and PMI_PresentKM < 200000 then 3
              when VehicleAgeAtStart * 1.0000  <= 12 and PMI_PresentKM < 250000 then 4
              when VehicleAgeAtStart * 1.0000  <= 15 and PMI_PresentKM < 300000 then 5
              else 999 end OriPlanCriteriaStart

        ,case when VehicleAgeAtStart * 1.0000  <= 5  then 1
              when VehicleAgeAtStart * 1.0000  <= 8  then 2
              when VehicleAgeAtStart * 1.0000  <= 10  then 3
              when VehicleAgeAtStart * 1.0000  <= 12  then 4
              when VehicleAgeAtStart * 1.0000  <= 15 and PMI_PresentKM < 300000 then 5
              else 999 end OriCriteriaStart




        ,Cast( latestOdoMeterReading + 
		@AssumedMonthlyKMs * (DATEDIFF(day,latestMileageDate,POL_RenewalDate)*1.0/365*12) as int) RenewalAssumedOdoMeterReading
	
into #res3
	
from #res2
--select * from #CriteriaTab

select * from #res3
------------------------------------------------------------------------------------------------------------------------------------------------
select r.*, o.C_AgeFrom StartAgeFrom,o.C_AgeTo StartAgeTo,o.C_OdometerLimit StartOdometerLimit
          , Ori.C_AgeFrom OriStartAgeFrom,Ori.C_AgeTo OriStartAgeTo,Ori.C_OdometerLimit OriStartOdometerLimit

		   ,case when PRP_PlanName='Chrome' then PRP_PlanName

		when PRP_PlanName='Bronze' then PRP_PlanName
								  
		when PRP_PlanName='Silver' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Silver' and OriPlanCriteriaStart in (1,2,3,4) then PRP_PlanName

		when PRP_PlanName='Gold' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Gold' and OriPlanCriteriaStart = 4 then 'Silver'
		when PRP_PlanName='Gold' and OriPlanCriteriaStart in (1,2,3) then PRP_PlanName

		when PRP_PlanName='Platinum' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Platinum' and OriPlanCriteriaStart = 4 then 'Silver'
		when PRP_PlanName='Platinum' and OriPlanCriteriaStart = 3 then 'Gold'
		when PRP_PlanName='Platinum' and OriPlanCriteriaStart in (1,2) then PRP_PlanName

		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 5 then 'Bronze'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 4 then 'Silver'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 3 then 'Gold'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 2 then 'Platinum'
		when PRP_PlanName='Titanium' and OriPlanCriteriaStart = 1 then PRP_PlanName

		end OriPlanOption 



       , case when RenewalAssumedOdoMeterReading >= 300000 then 999
	          when VehicleAgeAtRenewal * 1.0000  <= 5 and RenewalAssumedOdoMeterReading < 100000 then 1
              when VehicleAgeAtRenewal * 1.0000  <= 8 and RenewalAssumedOdoMeterReading < 160000 then 2
              when VehicleAgeAtRenewal * 1.0000  <= 10 and RenewalAssumedOdoMeterReading < 200000 then 3
              when VehicleAgeAtRenewal * 1.0000  <= 12 and RenewalAssumedOdoMeterReading < 250000 then 4
              when VehicleAgeAtRenewal * 1.0000  <= 15 and RenewalAssumedOdoMeterReading < 300000 then 5
              else 999 end CriteriaRenewal

              , case when RenewalAssumedOdoMeterReading >= 300000 then 999
			  when VehicleAgeAtRenewal * 1.0000  <= 5 and RenewalAssumedOdoMeterReading < 100000 then 1
              when VehicleAgeAtRenewal * 1.0000  <= 8 and RenewalAssumedOdoMeterReading < 160000 then 2
              when VehicleAgeAtRenewal * 1.0000  <= 10 and RenewalAssumedOdoMeterReading < 200000 then 3
              when VehicleAgeAtRenewal * 1.0000  <= 12 and RenewalAssumedOdoMeterReading < 250000 then 4
              when VehicleAgeAtRenewal * 1.0000  <= 15 and RenewalAssumedOdoMeterReading < 300000 then 5
              else 999 end OriPlanCriteriaRenewal

       , case when RenewalAssumedOdoMeterReading >= 300000 then 999
	          when VehicleAgeAtRenewal * 1.0000  <= 5  then 1
              when VehicleAgeAtRenewal * 1.0000  <= 8  then 2
              when VehicleAgeAtRenewal * 1.0000  <= 10  then 3
              when VehicleAgeAtRenewal * 1.0000  <= 12  then 4
              when VehicleAgeAtRenewal * 1.0000  <= 15 and RenewalAssumedOdoMeterReading < 300000 then 5
              else 999 end OriCriteriaRenewal
       
into #res4

from #res3 r
left join #CriteriaTab o on C_Criteria = CriteriaStart
left join #CriteriaTab Ori on Ori.C_Criteria = OriCriteriaStart

select * from #res4
--select * from #res5
-----------------------------------------------------------------------------------------------------------------------------------------------------------

--Declare @vat float = 0.15;

select r.*
,c.C_AgeFrom ReAgeFrom,
c.C_AgeTo ReAgeTo,c.C_OdometerLimit ReOdometerLimit 

          ,Ori.C_AgeFrom OriReAgeFrom,Ori.C_AgeTo OriReAgeTo,Ori.C_OdometerLimit OriReOdometerLimit



 ,case when PRP_PlanName='Chrome' then PRP_PlanName

		when PRP_PlanName='Bronze' then PRP_PlanName
								  
		when PRP_PlanName='Silver' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Silver' and CriteriaRenewal in (1,2,3,4) then PRP_PlanName

		when PRP_PlanName='Gold' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Gold' and CriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Gold' and CriteriaRenewal in (1,2,3) then PRP_PlanName

		when PRP_PlanName='Platinum' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Platinum' and CriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Platinum' and CriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Platinum' and CriteriaRenewal in (1,2) then PRP_PlanName

		when PRP_PlanName='Titanium' and CriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 2 then 'Platinum'
		when PRP_PlanName='Titanium' and CriteriaRenewal = 1 then PRP_PlanName

		end RenewalPlanOption 

 ,case when PRP_PlanName='Chrome' then PRP_PlanName

		when PRP_PlanName='Bronze' then PRP_PlanName
								  
		when PRP_PlanName='Silver' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Silver' and OriPlanCriteriaRenewal in (1,2,3,4) then PRP_PlanName

		when PRP_PlanName='Gold' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Gold' and OriPlanCriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Gold' and OriPlanCriteriaRenewal in (1,2,3) then PRP_PlanName

		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Platinum' and OriPlanCriteriaRenewal in (1,2) then PRP_PlanName

		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 5 then 'Bronze'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 4 then 'Silver'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 3 then 'Gold'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 2 then 'Platinum'
		when PRP_PlanName='Titanium' and OriPlanCriteriaRenewal = 1 then PRP_PlanName

		end OriRenewalPlanOption 



       ,round(s.[Premium_exclVAT] * (1+@vat)* (case when [RTF_Description] = 'Annual' then 11 else 1 end),2) E_StartPremium
	   ,round(O.[Premium_exclVAT] * (1+@vat)* (case when [RTF_Description] = 'Annual' then 11 else 1 end),2) OriE_StartPremium
	   , ITS_Premium PremiumAtInception 

		  into #res5

from #res4 r
left join #CriteriaTab c on C_Criteria = CriteriaRenewal
left join [MSureEvolve].[dbo].[ms_santam_rating] s on s.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and [section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and s.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and [AgeFrom] = StartAgeFrom --COLLATE DATABASE_DEFAULT
													  and [AgeTo] = StartAgeTo --COLLATE DATABASE_DEFAULT
													  and [OdometerLimit] = StartOdometerLimit --COLLATE DATABASE_DEFAULT
													  and [PlanOption] = [PRP_PlanName] COLLATE DATABASE_DEFAULT
													  and [PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and [Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])


left join #CriteriaTab Ori on Ori.C_Criteria = OriCriteriaRenewal
left join [MSureEvolve].[dbo].[ms_santam_rating] O on O.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and o.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and o.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and o.[AgeFrom] = OriStartAgeFrom --COLLATE DATABASE_DEFAULT
													  and o.[AgeTo] = OriStartAgeTo --COLLATE DATABASE_DEFAULT
													  and o.[OdometerLimit] = OriStartOdometerLimit --COLLATE DATABASE_DEFAULT
													  and o.[PlanOption] = [PRP_PlanName] COLLATE DATABASE_DEFAULT
													  and o.[PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and o.[Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])



													 
--where POL_PolicyNumber like 'SWTY001465POL%'

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
select r.*,round(s.[Premium_exclVAT] * (1+@vat) * (case when [RTF_Description] = 'Annual' then 11 else 1 end)  ,2) E_NewPremiumRew 
          ,round(o.[Premium_exclVAT] * (1+@vat) * (case when [RTF_Description] = 'Annual' then 11 else 1 end)  ,2) OriE_NewPremiumRew 

into #res6 

from #res5 r
left join [MSureEvolve].[dbo].[ms_santam_rating] s on s.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and [section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and s.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and [AgeFrom] = ReAgeFrom --COLLATE DATABASE_DEFAULT
													  and [AgeTo] = ReAgeTo --COLLATE DATABASE_DEFAULT
													  and [OdometerLimit] = ReOdometerLimit --COLLATE DATABASE_DEFAULT
													  and [PlanOption] = RenewalPlanOption COLLATE DATABASE_DEFAULT
													  and [PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and [Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])

left join [MSureEvolve].[dbo].[ms_santam_rating] o on o.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and o.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and o.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and o.[AgeFrom] = OriReAgeFrom --COLLATE DATABASE_DEFAULT
													  and o.[AgeTo] = OriReAgeTo --COLLATE DATABASE_DEFAULT
													  and o.[OdometerLimit] = OriReOdometerLimit --COLLATE DATABASE_DEFAULT
													  and o.[PlanOption] = OriRenewalPlanOption COLLATE DATABASE_DEFAULT
													  and o.[PremiumFrequency] = 'Monthly'--[RTF_Description] COLLATE DATABASE_DEFAULT
													  and o.[Effectivedate] = (select max([Effectivedate]) from [MSureEvolve].[dbo].[ms_santam_rating] where POL_SoldDate>=[Effectivedate])


--select *  from #res6 where ITS_Premium = 0--OriE_StartPremium =0 --E_NewPremiumRew =0 --E_StartPremium = 0
---------------------------------------------------------------------------------------------------------------------------------------------
select *, E_NewPremiumRew/isnull(E_StartPremium,E_NewPremiumRew) PerChange, 
          OriE_NewPremiumRew/isnull(OriE_StartPremium,OriE_NewPremiumRew) OriPerChange, 
		  OriE_NewPremiumRew/(case when ITS_Premium =0 then 1 else ITS_Premium end) OldPerChange,

       case when RenewalAssumedOdoMeterReading >300000
	        then 'Tariff not calculated: Vehicle odometer reading not permissible for cover on any plan.'
			when  VehicleAgeAtRenewal > 15 then 'Tariff not calculated: Vehicle age not eligible for cover on any plan.'
			when E_StartPremium is NULL then 'This policy was not qualifying for '+[PRP_PlanName] +' at inception.'
			when E_StartPremium <> ITS_Premium  then 'The premium at inception was suppose to be ' 
			     + cast (E_StartPremium as varchar) +'.'

			else '' end Comments,
			       case when RenewalAssumedOdoMeterReading >300000
	        then 'Tariff not calculated: Vehicle odometer reading not permissible for cover on any plan.'
			when  VehicleAgeAtRenewal > 15 then 'Tariff not calculated: Vehicle age not eligible for cover on any plan.'
			when OriE_StartPremium is NULL then 'This policy was not qualifying for '+[PRP_PlanName] +' at inception.'
			when OriE_StartPremium <> ITS_Premium  then 'The premium at inception was suppose to be ' 
			     + cast (OriE_StartPremium as varchar) +'.'

			else '' end OriComments



into #res7

from #res6
-----------------------------------------------------------------------------------------------------------------------------------------------
select *, round( case --when CriteriaRenewal = CriteriaStart and RenewalPlanOption = PRP_PlanName then E_StartPremium
               when RenewalPlanOption = PRP_PlanName and  PerChange < @PerIncChange and PerChange >1 then E_NewPremiumRew
			   when RenewalPlanOption = PRP_PlanName and  PerChange < @PerIncChange  then E_StartPremium
			   when RenewalPlanOption = PRP_PlanName and  PerChange >= @PerIncChange then E_StartPremium * @PerIncChange
			   

			   when E_NewPremiumRew = E_StartPremium and RenewalPlanOption <> PRP_PlanName then E_StartPremium
			   when PerChange >= @PerIncChange and RenewalPlanOption <> PRP_PlanName then E_StartPremium * @PerIncChange
			   when PerChange < @PerIncChange  and PerChange > @PerDecChange  
			        and RenewalPlanOption <> PRP_PlanName then E_NewPremiumRew 
               when PerChange <= @PerDecChange and RenewalPlanOption <> PRP_PlanName then E_StartPremium * @PerDecChange
			   else null end,2) RenewalPremiumBeClaims ,

         round( case --when OriCriteriaRenewal = OriCriteriaStart and OriRenewalPlanOption = PRP_PlanName then OriE_StartPremium
		       when OriRenewalPlanOption = PRP_PlanName and  OriPerChange < @PerIncChange and OriPerChange>1 then OriE_NewPremiumRew
               when OriRenewalPlanOption = PRP_PlanName and  OriPerChange < @PerIncChange then OriE_StartPremium
			   when OriRenewalPlanOption = PRP_PlanName and  OriPerChange >= @PerIncChange then OriE_StartPremium * @PerIncChange

			   when OriE_NewPremiumRew = OriE_StartPremium and OriRenewalPlanOption <> PRP_PlanName then OriE_StartPremium
			   when OriPerChange >= @PerIncChange and OriRenewalPlanOption <> PRP_PlanName then OriE_StartPremium * @PerIncChange
			   when OriPerChange < @PerIncChange  and OriPerChange > @PerDecChange  
			        and OriRenewalPlanOption <> PRP_PlanName then OriE_NewPremiumRew 
               when OriPerChange <= @PerDecChange and OriRenewalPlanOption <> PRP_PlanName then OriE_StartPremium * @PerDecChange
			   else null end,2) OriRenewalPremiumBeClaims ,

         round( case --when OriCriteriaRenewal = OriCriteriaStart and OriRenewalPlanOption = PRP_PlanName then ITS_Premium
               when OriRenewalPlanOption = PRP_PlanName and  OldPerChange < @PerIncChange and OldPerChange > 1 then OriE_NewPremiumRew
			   when OriRenewalPlanOption = PRP_PlanName and  OldPerChange < @PerIncChange then ITS_Premium
			   when OriRenewalPlanOption = PRP_PlanName and  OldPerChange >= @PerIncChange then ITS_Premium * @PerIncChange

			   when OriE_NewPremiumRew = ITS_Premium and OriRenewalPlanOption <> PRP_PlanName then ITS_Premium
			   when OldPerChange >= @PerIncChange and OriRenewalPlanOption <> PRP_PlanName then ITS_Premium * @PerIncChange
			   when OldPerChange < @PerIncChange  and OldPerChange > @PerDecChange  
			        and OriRenewalPlanOption <> PRP_PlanName then OriE_NewPremiumRew 
               when OldPerChange <= @PerDecChange and OriRenewalPlanOption <> PRP_PlanName then ITS_Premium * @PerDecChange
			   else null end,2) OldRenewalPremiumBeClaims 



into #res8

from #res7
--------------------------------------------------------------------------------------------------------------------------------------------------------------
select *, round( case when ClaimsCount is null and CIS_AuthAmount is null then RenewalPremiumBeClaims 
               when ClaimsCount = 1 and  CIS_AuthAmount >0  then RenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  CIS_AuthAmount >0  then RenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  CIS_AuthAmount = 0  then RenewalPremiumBeClaims

               else null end,2) RenewalPremium,

			   round( case when ClaimsCount is null and CIS_AuthAmount is null then OriRenewalPremiumBeClaims 
               when ClaimsCount = 1 and  CIS_AuthAmount >0  then OriRenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  CIS_AuthAmount >0  then OriRenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  CIS_AuthAmount = 0  then OriRenewalPremiumBeClaims

               else null end,2) ORiRenewalPremium,

			   round( case when ClaimsCount is null and CIS_AuthAmount is null then OldRenewalPremiumBeClaims 
               when ClaimsCount = 1 and  CIS_AuthAmount >0  then OldRenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  CIS_AuthAmount >0  then OldRenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  CIS_AuthAmount = 0  then OldRenewalPremiumBeClaims

               else null end,2) OldRenewalPremium

into #res9

from #res8

--------------------------------------------------------------------------------------------------------------------------------------------------

select --distinct
POL_PolicyNumber	PolicyNumber	,
--ITS_Item_ID	ITS_Item_ID	,
PMI_VehicleCode	VehicleCode	,
PMI_Make	Make	,
PMI_Model	Model	,
Make MakeSys,
PRP_PlanName	OriginalPlanOption	,
RTF_Description PaymentFrequency,
ITS_Premium	CurrentPremium	,
--OriE_NewPremiumRew CurrentPremiumForNewPol,
PMI_PresentKM OriginalOdoMeterReading,
POL_OriginalStartDate OriginalStartDate,
PMI_RegistrationDate	RegistrationDate	, POL_SoldDate, POL_ReceivedDate,
E_StartPremium,	OriE_StartPremium,	PremiumAtInception,
VehicleAgeAtStart,VehicleAgeAtReceivedDate,

case
     when VehicleAgeAtStart<=5 and VehicleAgeAtReceivedDate<=5 then 'Same Age'
	 when VehicleAgeAtStart >5 and VehicleAgeAtReceivedDate >5 and VehicleAgeAtStart<=8 and VehicleAgeAtReceivedDate<=8 then 'Same Age'
	 when VehicleAgeAtStart >8 and VehicleAgeAtReceivedDate >8 and VehicleAgeAtStart<=10 and VehicleAgeAtReceivedDate<=10 then 'Same Age'
	 when VehicleAgeAtStart >10 and VehicleAgeAtReceivedDate >10 and VehicleAgeAtStart<=12 and VehicleAgeAtReceivedDate<=12 then 'Same Age'
	 when VehicleAgeAtStart >12 and VehicleAgeAtReceivedDate >12 and VehicleAgeAtStart<=15 and VehicleAgeAtReceivedDate<=15 then 'Same Age'

	 else 'Diff Age' end Age,

case when abs( OriE_StartPremium	- PremiumAtInception)<=1 then 'Fine'
     when POL_SoldDate> POL_ReceivedDate  and  POL_SoldDate>='2024-01-01' then 'Old rates used' 



else 'Error' end PCheck



--riComments	Comments	
 
 into #res10

from #res9


where 1=1

and ITS_Item_ID not in ('15E6B613-3D4A-4D48-A918-09BDBACF2C55' -- Averag changed
                         ,'7FB2FC11-ED27-4BE1-8224-14DCDCDA3540' -- rounding off issue
						 )



--and POL_RenewalDate >='2024/01/01' --in('2023/06/01','2023/07/01','2023/08/01','2023/09/01')
--and POL_RenewalDate <='2024/02/29'
--and POL_PolicyNumber not like '%-%'
 --and POL_PolicyNumber ='SWTY000027POL'
 --and Comments<>''
--and E_StartPremium is null
--and E_NewPremiumRew is null


---------------------------------------------------------------------------------------------------------------------------------------------

select * from #res10  

where PCheck <> 'Fine'

--and Make ='VOLKSWAGEN'

--and Age = 'Diff Age'

order by PolicyNumber
--where POL_PolicyNumber like 'SWTY000257POL%'

--where POL_PolicyNumber in(
--'SWTY000027POL',
--'SWTY000043POL',
--'SWTY000080POL'
--)

--E_StartPremium	PremiumAtInception
--RenewalPremiumBeClaims	RenewalPremium


--select * from #res10 where PolicyNumber = 'SWTY007034POL'
--select * from #res9 where POL_PolicyNumber = 'SWTY006554POL'

--select * from #pol where POL_PolicyNumber = 'SWTY007034POL'



-- where POL_PolicyNumber='SWTY001863POL'

 

--select * from #claims  order by [CWI_PolicyWarrantyItem_ID]
--select * from #claims2 order by [CWI_PolicyWarrantyItem_ID]
--select * from #claims3 order by [CWI_PolicyWarrantyItem_ID]

--left join #claims2 on CIS






