/****** Script for SelectTopNRows command from SSMS  ******/

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
Declare @AssumedMonthlyKMs int = 2000;
Declare @vat float = 0.15
Declare @PerIncChange float = 1.1
Declare @PerDecChange float = 0.9
Declare @InflationInc float = 1.06

--Declare @avgHiluxPrice float= (select avg(cast(price as float)) 
--                               from [MSureEvolve].[dbo].[ViewVehicleModels] 
--							   where brand like 'TOYOTA' and range like '%HILUX%' and doors = 4)

--select @avgHiluxPrice
--Create tables
CREATE TABLE #CriteriaTab (
    C_Criteria int,
       C_AgeTo int,
	C_OdometerLimit int
);

--Insert into tables

insert into #CriteriaTab Values	(1,4,120000);	
insert into #CriteriaTab Values	(2,10,200000);	
insert into #CriteriaTab Values	(3,15,250000);	


--SELECT *  INTO 
--#ms_OMI_rating 
--FROM  [MSureEvolve].[dbo].[ms_rating_warranty]

--select * from #CriteriaTab 

--Policy Info

SELECT [POL_PolicyNumber]
      ,Policy_ID
	  ,ITS_Item_ID
	  ,isnull([PMI_VehicleCode],[PME_VehicleCode]) [PMI_VehicleCode]
	  ,isnull([PMI_Make],[PME_Make]) [PMI_MakeOriginal]
      ,isnull((select distinct Brand from [MSureEvolve].[dbo].[ViewVehicleModels]  
	              where ADG_CODE = isnull([PMI_VehicleCode],[PME_VehicleCode])),isnull([PMI_Make],[PME_Make])) [PMI_Make]
      ,isnull([PMI_Model],[PME_Model]) [PMI_Model]
	  ,[PRP_PlanName]
	  ,SUBSTRING([PRP_PlanName],10,1) OriginalCriteria
	  ,case when SUBSTRING([PRP_PlanName],12,6)='' then [PRP_PlanName] else SUBSTRING([PRP_PlanName],12,6) end  PlanOption

	  ,[PDS_SectionGrouping]
      ,[ITS_SumInsured]
      ,[ITS_Premium]
	  ,isnull([PMI_PresentKM],[PME_PresentKM]) [PMI_PresentKM]
      ,[ITS_Status]
	  ,[RTF_Description]
	  ,isnull([PMI_RegistrationDate],[PME_RegistrationDate]) [PMI_RegistrationDate]
	  ,isnull([PMI_PurchaseDate],[PME_PurchaseDate]) [PMI_PurchaseDate]
	  ,POL_SoldDate
	  , isnull([PMI_MileageDate],[ITS_StartDate]) [PMI_MileageDate]
      ,[ITS_StartDate]
      ,[ITS_EndDate]
	  ,[POL_RenewalDate]
	  
  into #Pol

  FROM [Evolve].[dbo].[ItemSummary]

  left join [Evolve].[dbo].Policy on [ITS_Policy_ID] = Policy_ID
  left join [Evolve].[dbo].[PolicyMechanicalBreakdownItem] on [PolicyMechanicalBreakdownItem_ID] = ITS_Item_ID
  left join [Evolve].[dbo].[PolicyMotorExtendedItem] on [PolicyMotorExtendedItem_ID] = ITS_Item_ID
  left join [Evolve].[dbo].[ReferenceTermFrequency] on [POL_ProductTerm_ID] = [TermFrequency_Id]
  left join [Evolve].[dbo].[ProductPlans] on [ProductPlans_Id] = isnull([PMI_Plan_ID],[PME_Plan_ID])
  left join [Evolve].[dbo].[ProductSection] on [ProductSection_Id] = isnull([PMI_Section_ID],[PME_Section_ID])
  where 1=1
        and [POL_PolicyNumber]  in --like 'OV%' --in('OV4U002314POL','OV4U001299POL','OV4U001302POL','OV4U001700POL','OV4U001834POL','OV4U000984POL')
	
	--select * from #Pol
	
		(
'OV4U005563POL',
'OV4U005422POL',
'OV4U005297POL',
'OV4U005290POL',
'OV4U005359POL',
'OV4U005232POL',
'OV4U005544POL',
'OV4U002637POL-01',
'OV4U005331POL',
'OV4U002843POL-01',
'OV4U005483POL',
'OV4U005333POL',
'OV4U002607POL-01',
'OV4U002881POL-01',
'OV4U005538POL',
'OV4U005173POL',
'OV4U002713POL-01',
'OV4U002804POL-01',
'OV4U005373POL',
'OV4U002781POL-01',
'OV4U005512POL',
'OV4U002574POL-01',
'OV4U002801POL-01',
'OV4U005235POL',
'OV4U005598POL',
'OV4U005321POL',
'OV4U005296POL',
'OV4U005607POL',
'OV4U002533POL-01',
'OV4U002617POL-01',
'OV4U005432POL',
'OV4U005262POL',
'OV4U005654POL',
'OV4U005201POL',
'OV4U005374POL',
'OV4U002521POL-01',
'OV4U005385POL',
'OV4U005164POL',
'OV4U005261POL'
)

		and [POL_Status]=1
		and ITS_Status = 1



	--	select * from #Pol where POL_PolicyNumber='OV4U000915POL'


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Claims info

SELECT [ClaimItemSummary_ID]
      ,isnull([CWI_PolicyWarrantyItem_ID],[CMI_PolicyMotorBasicItem_ID]) [CWI_PolicyWarrantyItem_ID]
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
	  ,isnull([CWI_OdoMeterReading],CMI_OdoMeterReading) [CWI_OdoMeterReading]
	  ,[CWI_FailureDate]
      ,[CIS_SumInsured]
    
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
      ,[CIS_Estimate]
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
  left join [Evolve].[dbo].[ClaimItemComponents] c on [CIS_ClaimItem_ID] = [CIC_ClaimItem_ID]
  left join [Evolve].[dbo].[ClaimWarrantyItem] on [CIS_ClaimItem_ID] = [ClaimWarrantyItem_ID] 
  left join [Evolve].[dbo].[ClaimMotorBasicItem] on [CIS_ClaimItem_ID] = [ClaimMotorBasicItem_ID]
  where 1=1
       -- and [CIS_Policy_ID] = 'DFC34627-44B8-4078-B1C6-28EC16C8B049'
	   -- and [CLS_Description] <>'Rejected'
		--and CIS_PolicyNumber = 'SWTY000043POL'

	--	and d.[CIS_Description] <>'Rejected'
		and a.[CIS_Deleted] = 0
		and a.[CIS_Deleted] = 0
		and [CIS_CreateDate]>= DATEADD(day,-365,@RatingDate)


		and CIS_PolicyNumber in (select [POL_PolicyNumber] from #pol)

--select * from #claims
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select [CWI_PolicyWarrantyItem_ID] ,count(distinct CIS_ClaimNumber) ClaimsCount
 
 into #claims2

 from #Claims

  where 1=1
  
  and [CIS_Estimate]>0
  --and CWI_PolicyWarrantyItem_ID = '103E270B-83A3-4241-B7E3-EB64F063DD33'

 
 group by [CWI_PolicyWarrantyItem_ID]

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 select o.[CWI_PolicyWarrantyItem_ID] ,ClaimsCount,sum([CIS_Estimate]) [CIS_Estimate], [CWI_OdoMeterReading],[CWI_FailureDate]

 into #claims3 

 from  #claims2 c 

 left join #Claims o on o.[CWI_PolicyWarrantyItem_ID] = c.[CWI_PolicyWarrantyItem_ID]




 group by o.[CWI_PolicyWarrantyItem_ID] ,[CWI_OdoMeterReading],[CWI_FailureDate],ClaimsCount
 ----------------------------------------------------------------------------------------------------------------


 select [CWI_PolicyWarrantyItem_ID],ClaimsCount,sum([CIS_Estimate]) [CIS_Estimate], max([CWI_OdoMeterReading]) [CWI_OdoMeterReading]
        ,max([CWI_FailureDate]) [CWI_FailureDate]

 into #claims4

 from #Claims3



 group by [CWI_PolicyWarrantyItem_ID],ClaimsCount


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 select p.*,c.*
 
 into #res 

 from #pol p
 left join #claims4 c on  ITS_Item_ID  = [CWI_PolicyWarrantyItem_ID]
-- left join [MSureEvolve].[dbo].[ViewVehicleModels] on [ADG_CODE] = PMI_VehicleCode

 order by POL_PolicyNumber

 --select * from #res

------------------------------------------------------------------------------------------------------------------------------------------



-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select *,case 
   --      when PMI_Make ='Ford' and PMI_Model like '%ranger%'  then 'FORD Ranger and Everest'
		 --when PMI_Make ='Ford' and PMI_Model like '%everest%'  then 'FORD Ranger and Everest'
		 --when PMI_Make ='Ford'  then 'FORD Other'
		 --when PMI_Make ='Toyota' and (select ToyotaPrice from #toyota2 where PMI_VehicleCode = ADG_CODE ) >= @avgHiluxPrice 
		 --then 'TOYOTA High' 
		 --when PMI_Make ='Toyota' and (select ToyotaPrice from #toyota2 where PMI_VehicleCode = ADG_CODE ) < @avgHiluxPrice  
		 --then 'TOYOTA Other' 
		 when PMI_Make ='MERCEDES' then 'MERCEDES-BENZ'
		 when PMI_Make COLLATE DATABASE_DEFAULT in (select distinct make from [MSureEvolve].[dbo].[ms_rating_warranty] ) then PMI_Make
   --      when  (select avePrice from #OtherCars where ADG_CODE = PMI_VehicleCode ) <= 200000 then 'OTHER Low' 
		 --when  (select avePrice from #OtherCars where ADG_CODE = PMI_VehicleCode ) <= 300000 then 'OTHER Standard' 
		 else 'OTHER'

		--else PMI_Make 
		end Make

		
		


	--	select * from #OtherCars

        ,'Standard' RatingG , 
		case when [PDS_SectionGrouping] = 'Mechanical Breakdown' then 'Warranty' 
		when [PDS_SectionGrouping] = 'Scratch & Dent' then 'Scratch and Dent' 
		when [PDS_SectionGrouping] = 'Tyre & Rim' then 'Tyre and Rim' 
		
		else [PDS_SectionGrouping] end Sect_ion--, case when 


        ,(DATEDIFF(day,PMI_RegistrationDate,case when POL_PolicyNumber like '%-%' then ITS_StartDate 
		 else ITS_StartDate end )*1.000000/365) VehicleAgeAtStart
        ,(DATEDIFF(day,PMI_RegistrationDate,POL_RenewalDate)*1.000000/365) VehicleAgeAtRenewal

		,ISNULL(
		(case when CWI_OdoMeterReading<PMI_PresentKM then PMI_PresentKM else CWI_OdoMeterReading end) 
		,PMI_PresentKM) latestOdoMeterReading

		,ISNULL(
		(case when CWI_OdoMeterReading<PMI_PresentKM then PMI_MileageDate else CWI_FailureDate end)
		,case when PMI_MileageDate=0 then (case when POL_PolicyNumber like '%-%' then ITS_StartDate 
		 else ITS_StartDate end) else PMI_MileageDate end ) latestMileageDate

into #res2 
from #res 

-------------------------------------------------------------------------------------------------------------------------------------------------
select *

        ,Cast( latestOdoMeterReading + 
		@AssumedMonthlyKMs * DATEDIFF(month,latestMileageDate,POL_RenewalDate) as int) RenewalAssumedOdoMeterReading
	
into #res3
	
from #res2

------------------------------------------------------------------------------------------------------------------------------------------------
select r.*



       , case when VehicleAgeAtRenewal * 1.0000  < 4 and RenewalAssumedOdoMeterReading < 120000 then 1
              when VehicleAgeAtRenewal * 1.0000  < 10 and RenewalAssumedOdoMeterReading < 200000 then 2
              when VehicleAgeAtRenewal * 1.0000  < 15 and RenewalAssumedOdoMeterReading < 250000 then 3

              else 999 end CriteriaRenewal


       
into #res4

from #res3 r

-----------------------------------------------------------------------------------------------------------------------------------------------------------
select r.*

		,case when  r.Planoption=''then PRP_PlanName else r.Planoption end  RenewalPlanOption 



       ,isnull(round(s.[Premium_exclVAT] * (1+@vat),2),round(t.[Premium_exclVAT] * (1+@vat),2)) E_StartPremium
	 
	   , ITS_Premium PremiumAtInception 

		  into #res5

from #res4 r

left join [MSureEvolve].[dbo].[ms_rating_warranty] s on s.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and s.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and s.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and s.[criteria] = r.[OriginalCriteria]

													  and s.[PlanOption] = r.[PlanOption] COLLATE DATABASE_DEFAULT
													  and s.[PremiumFrequency] = [RTF_Description] COLLATE DATABASE_DEFAULT

left join [MSureEvolve].[dbo].[ms_rating_OMI] t on  t.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT

													  and t.[PlanOption] = r.[PlanOption] COLLATE DATABASE_DEFAULT
													  and t.[premiumfrequency] = [RTF_Description] COLLATE DATABASE_DEFAULT

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
select r.*,isnull(round(s.[Premium_exclVAT] * (1+@vat),2),round(t.[Premium_exclVAT] * (1+@vat),2)) E_NewPremiumRew 


into #res6 


from #res5 r
left join [MSureEvolve].[dbo].[ms_rating_warranty] s on s.[make] = r.Make COLLATE DATABASE_DEFAULT


													  and s.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT
													  and s.[make] = r.Make COLLATE DATABASE_DEFAULT
													  and s.[criteria] = CriteriaRenewal --COLLATE DATABASE_DEFAULT
							
													  and s.[PlanOption] = r.[PlanOption] COLLATE DATABASE_DEFAULT
													  and s.[PremiumFrequency] = [RTF_Description] COLLATE DATABASE_DEFAULT

left join [MSureEvolve].[dbo].[ms_rating_OMI] t on  t.[section] = [Sect_ion] COLLATE DATABASE_DEFAULT

													  and t.[PlanOption] = r.[PlanOption] COLLATE DATABASE_DEFAULT
													  and t.[premiumfrequency] = [RTF_Description] COLLATE DATABASE_DEFAULT

---------------------------------------------------------------------------------------------------------------------------------------------
select *, E_NewPremiumRew/isnull(ITS_Premium,E_NewPremiumRew) PerChange--, 
      


into #res7

from #res6
-----------------------------------------------------------------------------------------------------------------------------------------------
select *, round( case when ITS_Premium = E_NewPremiumRew  then ITS_Premium
               when PerChange > @PerDecChange and PerChange < @PerIncChange then ITS_Premium
			   when   PerChange >= @PerIncChange then ITS_Premium * @PerIncChange
			   when PerChange <= @PerDecChange  then ITS_Premium * @PerDecChange
			   else null end,2) RenewalPremiumBeClaims 


into #res8

from #res7
--------------------------------------------------------------------------------------------------------------------------------------------------------------
select *, round( case when ClaimsCount is null and [CIS_Estimate] is null then RenewalPremiumBeClaims 
               when ClaimsCount = 1 and  [CIS_Estimate] >0  then RenewalPremiumBeClaims * @InflationInc
			   when ClaimsCount > 1 and  [CIS_Estimate] >0  then RenewalPremiumBeClaims * @PerIncChange
			    when ClaimsCount = 1 and  [CIS_Estimate] = 0  then RenewalPremiumBeClaims

               else null end,2) RenewalPremium



into #res9

from #res8

--------------------------------------------------------------------------------------------------------------------------------------------------

select 
POL_PolicyNumber	PolicyNumber	,
--ITS_Item_ID	ITS_Item_ID	,
PMI_VehicleCode	VehicleCode	,
PMI_Make	Make	,
PMI_Model	Model	,
PRP_PlanName	OriginalPlanOption	,
OriginalCriteria,
PDS_SectionGrouping Section,
[PMI_PresentKM] OriginalOdoMeterReading,
ITS_Premium	CurrentPremium	,
PMI_RegistrationDate	RegistrationDate	,
POL_RenewalDate	RenewalDate	,
isnull(ClaimsCount,'')	NumberOfClaims	,
isnull([CIS_Estimate],0)	ClaimAmount	,
RenewalAssumedOdoMeterReading	RenewalAssumedOdoMeterReading	,
RenewalPlanOption	,
case when PDS_SectionGrouping = 'Mechanical Breakdown' then  CriteriaRenewal else Null end CriteriaRenewal,
[RTF_Description] Term
,	Case when RenewalPremium	is null then -1 else RenewalPremium end RenewalPremium

,case when CriteriaRenewal = 999 and PDS_SectionGrouping = 'Mechanical Breakdown' then 'Not eligible for renewal' else '' end Comments

--riComments	Comments	
 

from #res9



---------------------------------------------------------------------------------------------------------------------------------------------

--select * from #res9
--where  1=1
------and RenewalPremium is null

--and POL_PolicyNumber like 'OV4U003944POL%' 

--select * from #pol where  POL_PolicyNumber like 'OV4U002450POL%' 

--order by E_StartPremium, PDS_SectionGrouping









