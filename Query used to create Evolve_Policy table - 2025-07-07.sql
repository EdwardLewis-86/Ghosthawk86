

select PMI_Policy_ID,PMI_Plan_ID ,PMI_Type_ID ,PMI_SumInsured ,PMI_VINNumber,PMI_EngineNumber,PMI_RegistrationNumber,PMI_Make,PMI_Model,PMI_VehicleCode,PMI_RegistrationDate,PMI_PresentKM, PMI_AutoPremium, PMI_Discount, PMI_RoadsideAssistancePartner
into  #PolicyMechanicalBreakdownItem 
from [EVPRODSQL02].evolve.[dbo].[PolicyMechanicalBreakdownItem]


select PME_Policy_ID,PME_Plan_ID , PME_SumInsured ,PME_VINNumber,PME_EngineNumber,PME_RegistrationNumber,PME_Make,PME_Model,PME_VehicleCode,PME_RegistrationDate,PME_PresentKM, PME_AutoPremium, PME_Discount, PME_RoadsideAssistancePartner
into  #PolicyMotorExtendedItem
--SELECT *
from [EVPRODSQL02].evolve.[dbo].PolicyMotorExtendedItem



--drop table #PolicyCreditLifeItem
select PCI_Policy_ID,pci_Plan_ID , PCI_SumInsured ,PCI_VINNumber,PCI_EngineNumber,PCI_RegistrationNumber,PCI_Make,PCI_Model,PCI_VehicleCode,PCI_RegistrationDate ,PCI_AutoPremium,PCI_Discount,PCI_Type_ID
into #PolicyCreditLifeItem
--SELECT *
from [EVPRODSQL02].evolve.[dbo].PolicyCreditLifeItem


select PGI_Policy_ID,pGi_Plan_ID , PGI_SumInsured ,PGI_Description, PGI_AutoPremium,PGI_Discount
into  #PolicyGenericItem
--SELECT *
from [EVPRODSQL02].evolve.[dbo].[PolicyGenericItem]

select PMI_Policy_ID,PMI_Plan_ID ,PMI_Type_ID ,PMI_SumInsured ,PMI_VINNumber,PMI_EngineNumber,PMI_RegistrationNumber,PMI_Make,PMI_Model,PMI_VehicleCode,PMI_RegistrationDate, PMI_AutoPremium, PMI_Discount 
into  #PolicyMotorItem
--SELECT *
from [EVPRODSQL02].evolve.[dbo].[PolicyMotorItem]



select PCI_Policy_ID,PCI_Plan_ID ,PCI_Type_ID ,PCI_SumInsured ,PCI_VINNumber,PCI_EngineNumber,PCI_RegistrationNumber,PCI_Make,PCI_Model,PCI_VehicleCode,PCI_RegistrationDate, PCI_AutoPremium, PCI_Discount
into  #PolicyCreditShortfallItem
--SELECT *
from [EVPRODSQL02].evolve.[dbo].PolicyCreditShortfallItem

select *
into #ReferenceNumber
from [EVPRODSQL02].Evolve.[dbo].[ReferenceNumber]


select *
into #ReferenceNumberType
from [EVPRODSQL02].Evolve.[dbo].[ReferenceNumberType]

select *
into #Policy
from [EVPRODSQL02].Evolve.dbo.[Policy]

select *
into #ReferenceVehicleType
from [EVPRODSQL02].Evolve.[dbo].[ReferenceVehicleType] 
 


 select *
into #ProductPlans
from [EVPRODSQL02].Evolve.[dbo].[ProductPlans]


 select *
into #ProductVariant
from [EVPRODSQL02].Evolve.[dbo].[ProductVariant]


 select *
into #Itemsummary
from [EVPRODSQL02].Evolve.[dbo].[Itemsummary]

 select *
into #Marketerref
from [EVPRODSQL02].Evolve.[dbo].[Marketerref]


  select *
  into #accountparty
  from [EVPRODSQL02].Evolve.[dbo].[AccountParty]


    select *
  into #AgentConsultantLink
  from [EVPRODSQL02].Evolve.[dbo].[AgentConsultantLink] 


  
    select *
  into #SalesConsultants
  from [EVPRODSQL02].Evolve.[dbo].SalesConsultants 


    
    select *
  into #Agent
  from [EVPRODSQL02].Evolve.[dbo].Agent 


      select *
  into #AgentDivisionLink
  from [EVPRODSQL02].Evolve.[dbo].AgentDivisionLink 

        select *
  into #SalesBranch
  from [EVPRODSQL02].Evolve.[dbo].SalesBranch 


drop table rb_analysis.dbo.Evolve_Policy_input
select *, cast(null as varchar(100)) as Roadside_Partner
into rb_analysis.dbo.Evolve_Policy_input
from [EVPRODSQL02].[BI_ReportData].[dbo].[vw_Evolve_Policy]

-------------

   --drop table #cancel
    select [EVL_Event_ID] ,
	[EVL_ReferenceNumber]  ,
	[EVL_User_ID]  ,
	[EVL_DateTime],
	EventLog_ID,
	EVL_Description
	into #cancel
 from [EVPRODSQL02].Evolve.[dbo].[EventLog]  as C
 where evl_event_id in( 10516,10733)


 --drop table #cancelandReinstate
  select C.*
  into #cancelandReinstate
  from #cancel  as C
 
  INNER JOIN #cancel as C2 ON c2.evl_event_id = '10733' and C.[EVL_ReferenceNumber] = C2.[EVL_ReferenceNumber] AND CAST(C.EVL_DateTime AS DATE) = CAST(C2.EVL_DateTime AS DATE)
  WHERE c.evl_event_id = '10516'
  
 

    select C2.*
  into #ReinstateandCancel
  from #cancel as C
  INNER JOIN #cancel as C2 ON C.[EVL_ReferenceNumber] = C2.[EVL_ReferenceNumber] AND CAST(C.EVL_DateTime AS DATE) = CAST(C2.EVL_DateTime AS DATE)
  WHERE C.evl_event_id = 10516 AND C2.evl_event_id = 10733





  Update P
  set AccountParty_Id = AP.AccountParty_Id
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  INNER JOIN #accountparty as AP on P.Pol_Client_id = AP.APY_ItemReferenceNumber
   where ISNULL(P.Pol_Client_id,'') <> ''


  Update P
  Set Policy_Cancellation_date = c.Cancellation_date
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join (select [EVL_ReferenceNumber], max([EVL_DateTime]) as Cancellation_date
  --select *
  from #cancel  as Z
  inner join rb_analysis.dbo.Evolve_Policy_input as P on z.[EVL_ReferenceNumber] = p.Policy_id -- and [EVL_DateTime] > p.POL_EndDate
  where  z.evl_event_id = 10516
  --and not exists (select * from #cancelandReinstate as R where r.[EVL_ReferenceNumber] = z.[EVL_ReferenceNumber] )

  group by [EVL_ReferenceNumber] )  as C on P.Policy_id = c.[EVL_ReferenceNumber]
  where Policy_Status = 'Cancelled'


    Update P
  Set Policy_ReInstatement_date = c.Cancellation_date
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join (select [EVL_ReferenceNumber], max([EVL_DateTime]) as Cancellation_date
  --select *
  from #cancel  as Z
  where z.evl_event_id = 10733
  and not exists (select * from #ReinstateandCancel as R where r.[EVL_ReferenceNumber] = z.[EVL_ReferenceNumber] )

  group by [EVL_ReferenceNumber] )  as C on P.Policy_id = c.[EVL_ReferenceNumber]
  where Policy_Status <> 'Cancelled'

     --drop table #polactivation
    select [EVL_Event_ID] ,
	[EVL_ReferenceNumber]  ,
	[EVL_User_ID]  ,
	[EVL_DateTime],
	EventLog_ID
	into #polactivation
 from [EVPRODSQL02].Evolve.[dbo].[EventLog]  as C
 where evl_event_id in( 10514)
  
  --select EVL_ReferenceNumber , min(EVL_DateTime) as Act_dat
  -- from   #polactivation
  --group by EVL_ReferenceNumber
 

   update P
   set Policy_ativation_Date = a.Act_dat
   FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join (  select EVL_ReferenceNumber , min(EVL_DateTime) as Act_dat
   from   #polactivation
  group by EVL_ReferenceNumber) as A on p.Policy_ID = a.EVL_ReferenceNumber

------------------

  
  update P
  set Bank_Product_Code = rnr.[RNR_Number]
  FROM   rb_analysis.dbo.Evolve_Policy_input as P
  inner join   #ReferenceNumber  as rnr on p.policy_id = rnr.RNR_ItemReferenceNumber and [RNR_NumberType_Id] = '146'

  --where rnr_number = 'MIDPPP'

  ------------

     --drop table #NTU
    select [EVL_Event_ID] ,
	[EVL_ReferenceNumber]  ,
	[EVL_User_ID]  ,
	[EVL_DateTime],
	EventLog_ID
	into #NTU
 from [EVPRODSQL02].Evolve.[dbo].[EventLog]  as C
 where evl_event_id in( 10515)



   select *
  into #NTUReason
  from [EVPRODSQL02].Evolve.[dbo].[EventLogDetail] as eld
  where exists (
  select *
  from #NTU as C
  where c.EventLog_ID = eld.ELD_EventLog_ID)


 Update P
 set NTU_Date = n.EVL_DateTime,
 NTU_Reason = R.ELD_NewValue 
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #NTU as N on P.policy_id = N.EVL_ReferenceNumber --8434
left outer join #NTUReason as R on n.EventLog_ID = r.ELD_EventLog_ID and ELD_Description = 'NTU Reason'


  -----------------



Update P
Set Vin_Number = MI.PMI_VINNumber,
Engine_Number = PMI_EngineNumber,
Reg_Number = PMI_RegistrationNumber,
Make = MI.PMI_Make,
Model = MI.PMI_Model,
MMCode = MI.PMI_VehicleCode,
First_Reg_Date = MI.PMI_RegistrationDate,
Sum_Insured = MI.PMI_SumInsured,
Vehicle_type = VT.VET_Description,
Product_Plan_Name = PRP_PlanName

--select mi.*
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #PolicyMotorItem  as MI on P.Policy_id = MI.PMI_Policy_ID
left outer join #ReferenceVehicleType as VT on MI.PMI_Type_ID = VT.VehicleType_ID
left outer join  #ProductPlans  as PP on MI.PMI_Plan_ID = PP.ProductPlans_Id
----------------------------



Update P
Set Vin_Number = MI.PMI_VINNumber,
Engine_Number = PMI_EngineNumber,
Reg_Number = PMI_RegistrationNumber,
Make = MI.PMI_Make,
Model = MI.PMI_Model,
MMCode = MI.PMI_VehicleCode,
First_Reg_Date = MI.PMI_RegistrationDate,
Vehicle_odo = mi.PMI_PresentKM,
Sum_Insured = case when isnumeric(MI.PMI_SumInsured) = 0 then null 
when MI.PMI_SumInsured > 10000000 then null else MI.PMI_SumInsured end,
Vehicle_type = VT.VET_Description,
Product_Plan_Name = PRP_PlanName,
Roadside_Partner = PMI_RoadsideAssistancePartner
--select mi.*
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #PolicyMechanicalBreakdownItem as MI on P.Policy_id = MI.PMI_Policy_ID
left outer join  #ReferenceVehicleType  as VT on MI.PMI_Type_ID = VT.VehicleType_ID
left outer join  #ProductPlans  as PP on MI.PMI_Plan_ID = PP.ProductPlans_Id
 
----------------------------

Update P
Set Vin_Number = MI.PME_VINNumber,
Engine_Number = PME_EngineNumber,
Reg_Number = PME_RegistrationNumber,
Make = MI.PME_Make,
Model = MI.PME_Model,
MMCode = MI.PME_VehicleCode,
First_Reg_Date = MI.PME_RegistrationDate,
Vehicle_odo = mi.PME_PresentKM,
Sum_Insured = case when isnumeric(MI.PME_SumInsured) = 0 then null 
when MI.PME_SumInsured > 10000000 then null else MI.PME_SumInsured end,
--Vehicle_type = VT.VET_Description,
Product_Plan_Name = PRP_PlanName,
Roadside_Partner = PME_RoadsideAssistancePartner
--select mi.*
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #PolicyMotorExtendedItem as MI on P.Policy_id = MI.PMe_Policy_ID
--left outer join  [EVPRODSQL01].[Evolve].[dbo].[ReferenceVehicleType] as VT on MI.PME_Type_ID = VT.VehicleType_ID
left outer join  #ProductPlans  as PP on MI.PME_Plan_ID = PP.ProductPlans_Id
 


----------------------------





Update P
Set Vin_Number = MI.PCI_VINNumber,
Engine_Number = PCI_EngineNumber,
Reg_Number = PCI_RegistrationNumber,
Make = MI.PCI_Make,
Model = MI.PCI_Model,
MMCode = MI.PCI_VehicleCode,
First_Reg_Date = MI.PCI_RegistrationDate,
Sum_Insured = MI.PCI_SumInsured,
Vehicle_type = VT.VET_Description,
Product_Plan_Name = PRP_PlanName
--select MI.*, PRP_PlanName
-- select P.*
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #PolicyCreditLifeItem as MI on P.Policy_id = MI.PCI_Policy_ID
left outer join #ReferenceVehicleType  as VT on MI.PCI_Type_ID = VT.VehicleType_ID
left outer join  #ProductPlans  as PP on MI.PCI_Plan_ID = PP.ProductPlans_Id
--where POL_PolicyNumber = 'HCLL035920POL'




Update P
Set Vin_Number = MI.PCI_VINNumber,
Engine_Number = PCI_EngineNumber,
Reg_Number = PCI_RegistrationNumber,
Make = MI.PCI_Make,
Model = MI.PCI_Model,
MMCode = MI.PCI_VehicleCode,
First_Reg_Date = MI.PCI_RegistrationDate,
Sum_Insured = MI.PCI_SumInsured,
Vehicle_type = VT.VET_Description,
Product_Plan_Name = PRP_PlanName
--select MI.*
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #PolicyCreditShortfallItem  as MI on P.Policy_id = MI.PCI_Policy_ID
left outer join  #ReferenceVehicleType  as VT on MI.PCI_Type_ID = VT.VehicleType_ID
left outer join  #ProductPlans  as PP on MI.PCI_Plan_ID = PP.ProductPlans_Id

--select * from  rb_analysis.dbo.Evolve_Policy_input as P
--where POL_PolicyNumber = 'HCLL019657POL'

Update P
Set Product_Category = CASE WHEN REPLACE(p.PRD_Name,' (H)','')  in ('Adcover','Adcover & Deposit Cover Combo','Deposit Cover') then 'Adcover'
	        WHEN REPLACE(p.PRD_Name,' (H)','')  in ('Auto Pedigree Plus Plan with Deposit Cover') then 'Autopedigree Plus'
			when REPLACE(p.PRD_Name,' (H)','')  in ('Discovery Warranty') then 'Warranty'
			when REPLACE(p.PRD_Name,' (H)','')  in ('Lifestyle Protection Plan','Mobility Life Cover') then 'Credit Life'
					when REPLACE(p.PRD_Name,' (H)','')  in ('Paint Tech') then 'Paint Tech'
			when REPLACE(p.PRD_Name,' (H)','')  in ('Vehicle Value Protector') then 'VVP' else 'Other' end
--select distinct PRD_Name
from rb_analysis.dbo.Evolve_Policy_input as P


Update P
set Product_Category =  prv_name
from rb_analysis.dbo.Evolve_Policy_input as P
inner join #ProductVariant as PRV on P.POL_ProductVariantLevel1_ID = prv.ProductVariant_Id
where POL_ProductVariantLevel1_ID is not NULL

--select *
--from [Evolve].[dbo].[PolicyCreditShortfallItem]




Update P
Set Agent_Policy_Number = RN.RNR_Number
from rb_analysis.dbo.Evolve_Policy_input as P
 inner join (
select * from #ReferenceNumber  as RN 
inner join #ReferenceNumberType as RNT on RN.RNR_NumberType_Id = RNT.ReferenceNumberType_Id and rnt.RNT_Description  in ('Agent Policy Number')
--and RNT_Description = 'TIA to Evolve' 
) as RN on P.Policy_ID = RN.RNR_ItemReferenceNumber and RN.RNR_ItemType_Id = 2



Update P
Set Rims_Policy_Number = RN.RNR_Number
from rb_analysis.dbo.Evolve_Policy_input as P
 inner join (
select * from #ReferenceNumber as RN 
inner join #ReferenceNumberType as RNT on RN.RNR_NumberType_Id = RNT.ReferenceNumberType_Id and rnt.RNT_Description  in ('Rims Policy Number')
--and RNT_Description = 'TIA to Evolve' 
) as RN on P.Policy_ID = RN.RNR_ItemReferenceNumber and RN.RNR_ItemType_Id = 2

------------------------


  Update P
  Set Payment_Frequency = 'Monthly'
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  --where Payment_Frequency is null
  where RPM_Description = 'Bulked'
  and Payment_Frequency is null


  

  Update P
  Set Payment_Frequency = 'Monthly'
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  --where Payment_Frequency is null
  where RPM_Description = 'Debit Order'
  and Payment_Frequency is null


--------------------

  Update P
  Set Payment_Frequency = 'Term'
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  --where Payment_Frequency is null
  where RPM_Description = 'Bordereaux'
  and Payment_Frequency is null
  and RTF_TermPeriod > 1

-------------------------


    Update P
  Set Payment_Frequency = 'Monthly'
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  --where Payment_Frequency is null
  where  Payment_Frequency is null
  and RTF_TermPeriod = 1


  
    Update P
  Set Payment_Frequency = 'Annual'
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  --where Payment_Frequency is null
  where  Payment_Frequency is null
  and RTF_TermPeriod = 12

  --      Update P
  --Set Payment_Frequency = 'Annual'
  ----select *
  --FROM rb_analysis.dbo.Evolve_Policy_input as P
  ----where Payment_Frequency is null
  --where   RTF_TermPeriod = 12
  --drop table #cancellationReason
  select *
  into #cancellationReason
  from [EVPRODSQL02].Evolve.[dbo].[EventLogDetail] as eld
  where exists (
  select *
  from #cancel as C
  where c.EventLog_ID = eld.ELD_EventLog_ID)


  
    Update P
  Set Cancellation_Reason = el.eld_newValue
  --SELECT *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join #cancel as c on p.Policy_ID = c.EVL_ReferenceNumber
  --inner join [EVPRODSQL02].Evolve.dbo.Eventlog as evl on c.EventLog_ID = evl.EventLog_ID
 inner join #cancellationReason as EL on  el.ELD_EventLog_ID = c.EventLog_ID and p.Policy_Cancellation_date = c.EVL_DateTime
  where ELD_Description = 'Cancelation Reason'
  --and p.POL_PolicyNumber = 'HCLL046612POL'
  and EVL_Description = 'Policy Cancelled'


      Update P
  Set Cancellation_Comment  = el.eld_newValue
  --SELECT len(el.eld_newValue)
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join #cancel as c on p.Policy_ID = c.EVL_ReferenceNumber
  --inner join [EVPRODSQL02].Evolve.dbo.Eventlog as evl on c.EventLog_ID = evl.EventLog_ID
 inner join #cancellationReason as EL on  el.ELD_EventLog_ID = c.EventLog_ID and p.Policy_Cancellation_date = c.EVL_DateTime
  where ELD_Description = 'Cancelation Comment'
  --and p.POL_PolicyNumber = 'HCLL046612POL'
  and EVL_Description = 'Policy Cancelled'
  and  ELD_NewValue <> ''

  --select * from #cancellationReason where ELD_Description = 'Cancelation Comment' and ELD_NewValue <> '' and ELD_EventLog_ID in ('509419551','509419546')


   Update P
  Set Cancellation_Reason = el.eld_newValue
  --select el.eld_newValue
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join #cancel as c on p.Policy_ID = c.EVL_ReferenceNumber and p.Policy_Cancellation_date = c.EVL_DateTime
  --inner join [EVPRODSQL02].Evolve.dbo.Eventlog as evl on c.EventLog_ID = evl.EventLog_ID
  left join #cancellationReason as EL on  el.ELD_EventLog_ID = c.EventLog_ID and p.Policy_Cancellation_date = c.EVL_DateTime
 
  where ELD_Description = 'Cancelation Comment'
  and isnull(eld_newValue,'') <> ''
  and p.Insurer_Name like '%discovery%'


 

   Update P
  Set Cancellation_Reason = c.EVL_Description
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join #cancel as c on p.Policy_ID = c.EVL_ReferenceNumber and p.Policy_Cancellation_date = c.EVL_DateTime
  --inner join [EVPRODSQL02].Evolve.dbo.Eventlog as evl on c.EventLog_ID = evl.EventLog_ID
 --inner join #cancellationReason as EL on  el.ELD_EventLog_ID = c.EventLog_ID and p.Policy_Cancellation_date = evl.EVL_DateTime
 WHERE P.Cancellation_Reason IS NULL
  --where ELD_Description = 'Cancelation Reason'
 -- where p.POL_PolicyNumber = 'HCLL046612POL'


  
   Update P
  Set Cancellation_Reason = c.EVL_Description
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join #cancel as c on p.Policy_ID = c.EVL_ReferenceNumber
  --inner join [EVPRODSQL02].Evolve.dbo.Eventlog as evl on c.EventLog_ID = evl.EventLog_ID and p.Policy_Cancellation_date = c.EVL_DateTime
--inner join #cancellationReason as EL on  el.ELD_EventLog_ID = c.EventLog_ID and p.Policy_Cancellation_date = evl.EVL_DateTime
  --where ELD_Description = 'Cancelation / Lapsing Reason'
  --and p.POL_PolicyNumber = 'HADC011438POL'
   WHERE P.Cancellation_Reason IS NULL


--------------------

 Update P
 Set Make =  left([ITS_Description], CHARINDEX(',',[ITS_Description])-1),
 Model = substring([ITS_Description], CHARINDEX(',',[ITS_Description])+1,100)
 --select [ITS_Description], I.*
 from rb_analysis.dbo.Evolve_Policy_input as P
  inner join #ItemSummary  as I on P.Policy_id = I.its_policy_id and ITS_Description like '%,%'
  and ITS_Description not in ('Insurer Fee')
  --where PRD_Name = 'Discovery Warranty'
  where Model is null

---------

 Update P
 Set Make =  left([ITS_Description], CHARINDEX(' ',[ITS_Description])-1),
 Model = substring([ITS_Description], CHARINDEX(' ',[ITS_Description])+1,100)
 --select [ITS_Description], I.*
 from rb_analysis.dbo.Evolve_Policy_input as P
  inner join #ItemSummary  as I on P.Policy_id = I.its_policy_id and ITS_Description not like '%,%' and ITS_Description  like '% %'
  and ITS_Description not in ('Insurer Fee')
   where Model is null

-----------------------


select *
into #Models
from LCBI01.Intelliapp_to_Crm.dbo.[VehicleModels]

select *
into #Types
from LCBI01.Intelliapp_to_Crm.dbo.[VehicleTypes]


Update E
set Vehicle_type = 'Taxi'
from rb_analysis.dbo.Evolve_Policy_input as E
inner join #Models as M on e.MMCode = m.MMCode
inner join #Types as T on M.VehicleTypeId = T.VehicleTypeId
where 1=1
--and m.VehicleModel like '%quantum%'
and VehicleType = 'MINIBUS'
and make not in ('VOLKSWAGEN','Hyundai')
and isnull(Vehicle_type,'') <> 'Taxi'


------


update P
set  Vehicle_type = 'Taxi'
from rb_analysis.dbo.Evolve_Policy_input as P
where Vehicle_type <> 'Taxi'
--and model like '%inyati%'
and make like '%jinbei%'


update P
set  Vehicle_type = 'Taxi'
from rb_analysis.dbo.Evolve_Policy_input as P
where Vehicle_type <> 'Taxi'
--and model like '%inyati%'
and make like '%Inyathi%'


   drop table [RB_Analysis].[dbo].Evolve_Alternate_Dealer_Name
  select  Policy_id, POL_Agent_ID,	Agt_Name,RNR.RNR_Number as Alt_Dealer_Code,max(MAR_NAME) as Alt_Dealer_Name ,min(MAR_CODE2) as Cell_Captive_ind,
  cast(null as varchar(100)) as Final_Dealer_Dealer_Group, cast(null as varchar(100)) as Dealer_or_Group_Indicator, 0 as Telesales_Indicator, cast(null as varchar(100)) as FSP_Number,
  cast(null as varchar(100)) as FSP_Name,[RNR_NumberType_Id] ,RNR_ItemReferenceNumber,MAR_COMMENT
  into [RB_Analysis].[dbo].Evolve_Alternate_Dealer_Name
  from rb_analysis.dbo.Evolve_Policy_input as EP
  left outer join #ReferenceNumber  as RNR on ep.Policy_id = RNR_ItemReferenceNumber and  [RNR_NumberType_Id] in ( '171','172') and rnr.RNR_ItemType_Id = '2'
  left outer join  #MARKETERREF as MAR on RNR.RNR_Number = Mar.MAR_CODE1 -- and MAR_COMMENT = 'POS'
  group by  Policy_id, POL_Agent_ID,	Agt_Name,RNR.RNR_Number, [RNR_NumberType_Id] ,RNR_ItemReferenceNumber,MAR_COMMENT



  Update P
  Set Alternate_Agent_Name = A.Alt_Dealer_Name
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join [RB_Analysis].[dbo].Evolve_Alternate_Dealer_Name as A on P.Policy_id = A.Policy_id and a.[RNR_NumberType_Id] in ( '171') and a.MAR_COMMENT = 'POS'


  
  Update P
  Set Alternate_Agent_Name = A.Alt_Dealer_Name
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join [RB_Analysis].[dbo].Evolve_Alternate_Dealer_Name as A on P.Policy_id = A.Policy_id and a.[RNR_NumberType_Id] in ( '171') --and a.MAR_COMMENT = 'POS'
  and A.Alt_Dealer_Name is not null
  where p.Alternate_Agent_Name is null

    Update P
  Set Alternate_Agent_Name = A.Alt_Dealer_Name
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  inner join [RB_Analysis].[dbo].Evolve_Alternate_Dealer_Name as A on P.Policy_id = A.Policy_id --and a.[RNR_NumberType_Id] in ( '171') --and a.MAR_COMMENT = 'POS'
  and A.Alt_Dealer_Name is not null
  where p.Alternate_Agent_Name is null


  -------- RB Added ------ 2022-03-15


  --drop table #Agent_Region
  select AGT.Agent_Id, sco.SCO_Name ,sco.SCO_Name +	SCO_Surname as Consultant_Name,SRN.SRN_Text as Sales_Region,
  ACL_FromDate,	ACL_ToDate
  into #Agent_Region
  --select acl.*
  from    #AgentConsultantLink  as ACL 
  inner join #SalesConsultants  as SCO on ACL.ACL_Consultant_ID = SCO.SalesConsultant_ID and SCO.SCO_Deleted in ('0','2')
  Inner Join  #Agent as AGT on ACL.ACL_Agent_ID = AGT.Agent_Id and Agt_Deleted in ('0','2')

  left outer join #AgentDivisionLink  as ADL on ADL.ADL_Agent_ID = AGT.Agent_Id and ADL_Deleted in ('0','2')
  left outer join #SalesBranch  as SRN on ADL.ADL_Division_ID = SRN.SalesRegion_ID and SRN_Deleted in ('0','2')
 --where Agent_id = '9E472F8B-941D-4AE3-9D04-7DA0271FACCB'
  where acl_deleted in ('0','2')

  Update P
  Set Sales_Consultant = Consultant_Name, 
  sales_region = ar.Sales_Region
 -- select *
 from rb_analysis.dbo.Evolve_Policy_input as P
 inner join #Agent_Region as AR on P.POL_Agent_ID = AR.Agent_Id 
 and p.POL_SignedDate >= ACL_FromDate 
 and p.POL_SignedDate <  isnull(ACL_ToDate,'2070-01-01')


 
  Update P
  Set sales_region = ar.Sales_Region
 -- select *
 from rb_analysis.dbo.Evolve_Policy_input as P
 inner join (
 select Agent_Id , min(ACL_FromDate) as Min_Date
 From #Agent_Region as AR 
 group by Agent_Id ) as M on M.Agent_Id = P.POL_Agent_ID 
 inner join #Agent_Region as AR on p.POL_Agent_ID = ar.Agent_Id and ar.ACL_FromDate = M.Min_Date
 where p.sales_region is null

-------

  Update P
  set premium = Total_Summary_Premium - isnull(FEES,0)
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  where premium = 0
  and Total_Summary_Premium > 0
  and Total_Summary_Premium - isnull(FEES,0) > 0

  
    Update P
	Set Product_Variant = PRV_Name
    FROM rb_analysis.dbo.Evolve_Policy_input as P
	inner join #ProductVariant  as PV on isnull(isnull(isnull(nullif(P.POL_ProductVariantLevel4_ID,''),nullif(P.POL_ProductVariantLevel3_ID,'')),nullif(P.POL_ProductVariantLevel2_ID,'')),nullif(P.POL_ProductVariantLevel1_ID,'')) = PV.ProductVariant_Id



 Update P
 Set Mechanical_Breakdown_Plan = prp.PRP_PlanName
 -- select *
 from rb_analysis.dbo.Evolve_Policy_input as P
  inner join #PolicyMechanicalBreakdownItem  as I on P.Policy_id = I.[PMI_Policy_ID]
  inner join #ProductPlans  as PRP on I.PMI_Plan_ID = PRP.ProductPlans_Id
  --where p.pol_policynumber = 'HWTY104065POL'


 update Pol
 set Rims_policy_number = e.POL_VATNumber
 FROM rb_analysis.dbo.Evolve_Policy_input AS pOL
  INNER JOIN #Policy as E on pol.Policy_id = e.Policy_id
  where isnull(e.POL_VATNumber,'') like 'SAW%'
  and Rims_policy_number is  NULL


  
  Update P
  Set Sales_Consultant =  sc.SCO_Name+' '+sc.SCO_Surname
 -- select *
 from rb_analysis.dbo.Evolve_Policy_input as P
 inner join  #Policy as Pol on p.Policy_ID = pol.Policy_ID
 inner join #SalesConsultants  as sc on pol.POL_Agent_Consultant_ID = sc.SalesConsultant_ID


  update P 
 set POL_SoldDate =  cast(POL_SignedDate as date) 
 from rb_analysis.dbo.Evolve_Policy_input as P
 WHERE POL_SignedDate < POL_SoldDate
 and USR_Description = 'Migration'


drop table RB_Analysis.dbo.Evolve_Alternate_Agent_policy_Numbers
SELECT  policy_id 
,POL_PolicyNumber
,[RNR_Number]
      ,[RNR_AllowEdit]
      ,[RNR_AllowDelete]
	  ,RNT.RNT_Description
  --select distinct RNT_Description 
  into RB_Analysis.dbo.Evolve_Alternate_Agent_policy_Numbers
  FROM #Policy as pol
  inner join #ReferenceNumber  AS rnr on pol.Policy_ID = rnr.RNR_ItemReferenceNumber
  INNER JOIN #ReferenceNumberType AS rnt ON rnr.RNR_NumberType_Id = RNT.ReferenceNumberType_Id
  where RNT_Description in ('Agent Policy Number','DealerNet Policy ID','Liquid Capital Policy ID','Motor Happy Policy ID','Motor Happy Policy ID Warranty',
  'Seriti Policy ID','Signio Policy ID','Warranty World Policy Number','Wesbank LC Policy ID','Wesbank Policy ID','Wesbank POS Policy ID','WW Policy Number')




  Update P
  set NTU_Date = null
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  where NTU_Date is not null
  and Policy_Status <> 'NTU'

    Update P
  set NTU_Reason = null
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  where NTU_Reason is not null
  and Policy_Status <> 'NTU'



  
  Update P
  set Policy_Cancellation_date = null
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  where Policy_Cancellation_date is not null
  and Policy_Status <> 'Cancelled'

    Update P
  set Cancellation_Reason = null
  --select *
  FROM rb_analysis.dbo.Evolve_Policy_input as P
  where Cancellation_Reason is not null
  and Policy_Status <> 'Cancelled'

------------ Snapshot -- added -- 2024-07-31

delete
from [RB_Analysis].[dbo].Evolve_policy_Month_end_Snapshot
where measurement_month = convert(varchar(6),dateadd(day,-1,getdate()),112)


insert into   [RB_Analysis].[dbo].Evolve_policy_Month_end_Snapshot
SELECT  [POL_PolicyNumber]
      ,[Policy_id]
      ,[Policy_Status]
      ,[Pol_Client_id]
      ,[PRD_Name]
      ,[Product_Group]
      ,[Product_Plan_Name]
      ,[POL_ProductVariantLevel3_ID]
      ,[Product_Variant]
      ,[Mechanical_Breakdown_Plan]
      ,[RTF_TermPeriod]
      ,[POL_CreateDate]
      ,[POL_StartDate]
      ,[POL_ReceivedDate]
      ,[POL_SoldDate]
      ,[POL_EndDate]
      ,[Policy_Cancellation_date]
      ,[Policy_ReInstatement_date]
      ,[POL_RenewalDate]
      ,[POL_AnniversaryDate]
      ,[POL_Agent_ID]
      ,[Agent_Policy_Number]
      ,[Payment_Frequency]
      ,[POL_DebitDay]
       ,[POL_MaturityDate]
      ,[Total_Summary_Premium]
      ,[Make]
      ,[Model]
      ,[Vehicle_type]
      ,[MMCode]
      ,[Vin_Number]
      ,[Engine_Number]
      ,[Reg_Number]
      ,[First_Reg_Date]
      ,[Vehicle_odo]
      ,[Sum_Insured]
      ,[Insurer_Name]
      ,[Arrangement_Cell_Captive]
      ,[Cancellation_Reason]
      ,[NTU_Reason]
      ,[NTU_Date]
      ,[POL_PolicyTerm]
      ,[Policy_Migrated]
      ,[Policy_ativation_Date]
	  ,0 as Paid_Indicator
	  ,convert(varchar(6),dateadd(day,-1,getdate()),112) as Measurement_Month
	  ,getdate() as Insert_execute_time

  FROM rb_analysis.dbo.Evolve_Policy_input


---------------------

drop table RB_analysis.dbo.Evolve_Latest_DN_Sent

select *
into RB_analysis.dbo.Evolve_Latest_DN_Sent
from (
SELECT *  ,row_number() over (partition by DMS_ItemReference order by DMS_CreateDate desc) as seq

    FROM OPENQUERY ([EVPRODSQL02], 
        '

SELECT  [DMS_CreateDate]
      ,[DMS_Name]
      ,[DMS_Description]
      ,[DMS_ItemReference]
      ,rds.RDS_Description
	 
  FROM [Evolve].[dbo].[Document] as D
  left join [Evolve].[dbo].[ReferenceDeliveryStatus] as rds on d.DMS_DeliveryStatus = rds.DeliveryStatus_ID
  where DMS_ItemType_ID = ''2''
  and DMS_Name like ''%Disclosure%''
  and isnull(DMS_ItemReference,'''') <> ''''
  and DMS_CreateDate >= dateadd(year,-1,getdate())
  and [DMS_Deleted] = 0

  union

  SELECT  [DMS_CreateDate]
      ,[DMS_Name]
      ,[DMS_Description]
      ,[DMS_ItemReference]
      ,rds.RDS_Description
  FROM [Evolve].[dbo].[Document] as D
  left join [Evolve].[dbo].[ReferenceDeliveryStatus] as rds on d.DMS_DeliveryStatus = rds.DeliveryStatus_ID
  where DMS_ItemType_ID = ''2''
  and DMS_Name not like ''%Disclosure%''
  and DMS_Name  like ''%DN%''
  and isnull(DMS_ItemReference,'''') <> ''''
  and DMS_CreateDate >= dateadd(year,-1,getdate())
  and [DMS_Deleted] = 0

 ' )
 ) as Z
 where seq = 1


Update P set  [Cancellation_Comment]= replace(BI_ReportData.[dbo].[StripSpecialCharacters]([Cancellation_Comment]),',',';')

  FROM rb_analysis.dbo.Evolve_Policy_input as P
  where Cancellation_Comment is not NULL


 drop table rb_analysis.dbo.Evolve_Policy
 select *
 into rb_analysis.dbo.Evolve_Policy
 FROM rb_analysis.dbo.Evolve_Policy_input




insert into RB_analysis.dbo.RB_Evolve_Base_Policy_numbers
SELECT [Policy_ID]
      ,[POL_PolicyNumber]
	 ,left([POL_PolicyNumber],charindex('POL',[POL_PolicyNumber])+2) as Base_policy_no
  FROM [RB_Analysis].[dbo].[Evolve_Policy] as P
where not exists (
select *
from RB_analysis.dbo.RB_Evolve_Base_Policy_numbers as E
where e.Policy_ID = p.Policy_ID )
