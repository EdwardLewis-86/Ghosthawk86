
--drop table #tmp

SELECT   [Policy_ID]
       ,[POL_CreateDate]
      ,[POL_PolicyNumber]
      ,rps.POS_Description as Policy_Status
      ,[POL_Description]
	  ,agt.Agt_Name as Selling_Agent_Name
      ,[POL_StartDate]
      ,[POL_ReceivedDate]
      ,[POL_SoldDate]
      ,[POL_EndDate]
	  ,Prd_Name
	  ,prv1.PRV_Name as Variant_Level_1
     -- ,[POL_PolicyTerm]
      ,prv3.PRV_Name as Variant_Level_3
	  ,prv3.PRV_Code
	  ,prp.PRP_PlanName
	  ,RtF_Description
      ,its.ITS_Premium
	  ,its.ITS_Item_ID
	  ,pmi.PMI_Make
	  ,pmi.PMI_Model
	  into #tmp
  FROM [Evolve].[dbo].[Policy] as POL
  inner join [Evolve].[dbo].ReferencePolicyStatus as RPS on POL.POL_Status = rps.PolicyStatus_ID
  inner join [Evolve].[dbo].PolicyMechanicalBreakdownItem as PMI on POL.Policy_ID = PMI.PMI_Policy_ID
  inner join [Evolve].[dbo].ItemSummary as ITS on PMI.PolicyMechanicalBreakdownItem_ID = its.ITS_Item_ID
  inner join  [Evolve].[dbo].Product  as PRD on POL.POL_Product_ID  = PRD.Product_Id
  inner join  [Evolve].[dbo].ProductVariant as PRV1 on POL.POL_ProductVariantLevel1_ID  = PRV1.ProductVariant_Id 
  inner join  [Evolve].[dbo].ProductVariant as PRV3 on POL.POL_ProductVariantLevel3_ID  = PRV3.ProductVariant_Id 
  inner join [Evolve].[dbo].ProductPlans as PRP on PMI.PMI_Plan_ID = prp.ProductPlans_Id
  inner join [Evolve].[dbo].ReferenceTermFrequency as RtF on POL_ProductTerm_ID = rtf.TermFrequency_Id
  left outer join  [Evolve].[dbo].[Agent] as AGT on AGT.Agent_Id = pol.POL_Agent_ID
  --where prv1.prv_name like '%Option%'
  inner join  [Evolve].[dbo].PolicyInsurerLink as PIL on PIL.PIL_Policy_ID = pol.Policy_ID
  inner join evolve.dbo.Insurer as ins on pil.PIL_Insurer_ID = Insurer_Id
  -- where INS_InsurerName in ( 'Santam Limited','Hollard Short Term')
   --and POL_PolicyNumber  like 'SWTY001490POL%'


   --select * from #tmp

  --drop table #ATS
  select cast(ats.ATS_TransactionNumber as varchar(50)) as ATS_TransactionNumber, ats.AccountTransactionSet_Id, ATS_ReferenceNumber,ATS_EffectiveDate,ATS_Description,
  ATS_AccountTransactionType_ID,ATS_CreateUser_ID,ATS_Product_Id,ATS_AccountArea_ID,ATS_DisbursementRule_ID,ATS_CellCaptive_Id,ats_insurer_id,
  case when ATS_EffectiveDate > ATS_CreateDate then ATS_EffectiveDate else ATS_CreateDate end as Corrected_Efective_Date
  into #ATS
  --select ats.*
  from [Evolve].dbo.AccountTransactionSet AS ATS
  where exists(
  select *
  from #tmp as T
  where t.[Policy_ID] = ats.ATS_ReferenceNumber )
  --and convert(varchar(6),case when ATS_EffectiveDate > ATS_CreateDate then ATS_EffectiveDate else ATS_CreateDate end,112) >= '202304'
  and convert(varchar(6),case when ATS_EffectiveDate > ATS_CreateDate then ATS_EffectiveDate else ATS_CreateDate end,112) <= convert(varchar(6),getdate(),112)

  --select * from #ATS


  insert into   #ATS
    select ats.ATS_TransactionNumber, ats.AccountTransactionSet_Id, ATS_ReferenceNumber,ATS_EffectiveDate,ATS_Description,
  ATS_AccountTransactionType_ID,ATS_CreateUser_ID,ATS_Product_Id,ATS_AccountArea_ID,ATS_DisbursementRule_ID,ATS_CellCaptive_Id,ats_insurer_id,
  case when ATS_EffectiveDate > ATS_CreateDate then ATS_EffectiveDate else ATS_CreateDate end as Corrected_Efective_Date

  --select ats.*
  from [Evolve].dbo.AccountTransactionSet AS ATS
  where exists(
  select *
  from #tmp as T
  inner join evolve.dbo.Claim as CLM on T.Policy_ID = clm.CLM_Policy_ID
  where clm.claim_id = ats.ATS_ReferenceNumber )
  --and convert(varchar(6),case when ATS_EffectiveDate > ATS_CreateDate then ATS_EffectiveDate else ATS_CreateDate end,112) >= '202304'
  and convert(varchar(6),case when ATS_EffectiveDate > ATS_CreateDate then ATS_EffectiveDate else ATS_CreateDate end,112) <= convert(varchar(6),getdate(),112)

  --drop table #ATN
  select *
  into #ATN
  from   [Evolve].dbo.AccountTransaction AS ATN
  where exists (
  select *
  from #ATS as A
  where a.AccountTransactionSet_Id = atn.ATN_AccountTransactionSet_ID )
 
 --drop table #adi
 select *
 into #adi
 from  [Evolve].[dbo].[AccountDetailItem] as d
 where exists (
 select *
 from #ATN as T
 where d.ADI_AccountTransaction_ID = t.AccountTransaction_Id )





 select ADI_AccountTransaction_ID ,ADI_GLCode_ID,ADI_Item_ID, sum(ADI_GrossAmount) as ADI_GrossAmount, 	
 	sum(ADI_NettAmount) as ADI_NettAmount
	into #adi2
  from #adi
-- where ADI_AccountTransaction_ID in ('3C21643C-09E0-4609-AB42-A741E72463A6',
--'255EA284-16A3-448E-B3BA-109C1AE76994')
 group by ADI_AccountTransaction_ID ,ADI_GLCode_ID,ADI_Item_ID
 --------------

--drop table #Financials

SELECT   distinct      AAR.AAR_Description 
,ATS_TransactionNumber
,s.USR_FirstName+' '+s.USR_Surname as TX_Created_By
,ats.AccountTransactionSet_Id
,att.ATT_Description
        ,DBS.DBS_SetName
        ,DSM.DSM_RuleName
        ,dbt.DBT_Description
        ,INS.INS_InsurerName
        ,RGL.GLC_Description    
        ,RGL.GLC_GlCode
        ,apy.AccountParty_Id
	    ,apy.APY_Name
		,prd.PRD_Name
		,apt.APT_Description as AccountPartyType
        ,AMS_MatchKey
		,rcc.RCC_Description as Cell_Captive
		,P.POL_PolicyNumber 
		,CLM_ClaimNumber
		,ATS_ReferenceNumber
		,P.POL_CreateDate
		,P.POL_StartDate
		,P.Policy_ID
        ,convert(varchar(6),ATS_EffectiveDate,112) as Effective_month
		,convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) as Corrected_effective_Month
        ,    ATS_EffectiveDate   
        , ATN_CreateDate
        , atn.AccountTransaction_Id
        , ATS.ATS_Description 
        , isnull( adi.ADI_GrossAmount,ATN.ATN_GrossAmount ) as ATN_GrossAmount
        , isnull( adi.ADI_NettAmount,ATN_NettAmount) as ATN_NettAmount
		,  adi.ADI_Item_ID
 --,ATS_Info5
 --,ATS_Info2
into #Financials
--select atn.AccountTransaction_Id, atn.*
FROM #ATS AS ATS
left outer join evolve.dbo.[AccountTransactionType] as ATT on ats.ATS_AccountTransactionType_ID = att.AccountTransactionType_Id
left outer join evolve.dbo.systemusers as S on ats.ATS_CreateUser_ID = s.Users_ID
    INNER JOIN #ATN AS ATN 
                ON ATS.AccountTransactionSet_Id = ATN.ATN_AccountTransactionSet_ID
   inner join [Evolve].dbo.policy as P on P.Policy_ID = ats.ATS_ReferenceNumber
   inner join #tmp as T on P.Policy_ID = T.Policy_ID
    left outer join [Evolve].dbo.Claim as C on c.Claim_ID = ats.ATS_ReferenceNumber
   left outer join [Evolve].dbo.Product as PRD on ats.ATS_Product_Id = prd.Product_Id
    left outer JOIN Evolve.dbo.AccountArea AS AAR 
               ON AAR.AccountArea_Id = ATS.ATS_AccountArea_ID
    left outer join [Evolve].[dbo].[DisbursementType] as DBT on atn.ATN_DisbursementType_ID = dbt.DisbursementType_Id
    LEFT OUTER JOIN  [Evolve].dbo.DisbursementSet AS DBS 
                ON DBS.DisbursementSet_Id = ATS.ATS_DisbursementRule_ID 
    LEFT OUTER JOIN  [Evolve].dbo.Disbursement AS DSM
                ON DSM.Disbursement_Id = DBS.DBS_Disbursement_ID
    left outer join Evolve.[dbo].[ReferenceGLCode] as RGL on ATN_GLCode_ID = RGL.GlCode_ID
    left outer join Evolve.[dbo].Insurer as INS on GLC_Insurer_Id = INS.Insurer_Id 
left outer join Evolve.dbo.AccountParty as apy on ATN_AccountParty_ID = apy.AccountParty_Id
left outer join Evolve.dbo.AccountPartyType as Apt on apt.AccountPartyType_Id = apy.APY_PartyType_ID
left outer join   Evolve.[dbo].[AccountMatchSet] as ms on ATN_AccountMatch_ID = ms.AccountMatchSet_Id
left outer join  Evolve.dbo.ReferenceCellCaptive as RCC on RCC.ReferenceCellCaptive_Code = ATS_CellCaptive_Id
left outer join #adi2 as adi on adi.ADI_AccountTransaction_ID = atn.AccountTransaction_Id and ADI_Item_ID <> '' and t.ITS_Item_ID = ADI_Item_ID and atn.ATN_GLCode_ID = adi.ADI_GLCode_ID

WHERE 1=1
--and  ATS_TransactionNumber = '36945367'
--and t.pol_policynumber = 'HWTY019232POL'
--and convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) >= '202304'
and convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) <= convert(varchar(6),getdate(),112)
--and AccountTransaction_Id = 'D6750440-5577-49BA-B685-FB80EE0C1AA2'
--and t.POL_PolicyNumber = 'SWTY000717POL'
--39970152

ORDER BY ATS_TransactionNumber --,ATN_DisbursementStep



insert into  #Financials

SELECT   distinct      AAR.AAR_Description 
,ATS_TransactionNumber
,s.USR_FirstName+' '+s.USR_Surname as TX_Created_By
,ats.AccountTransactionSet_Id
,att.ATT_Description
        ,DBS.DBS_SetName
        ,DSM.DSM_RuleName
        ,dbt.DBT_Description
        ,INS.INS_InsurerName
        ,RGL.GLC_Description    
        ,RGL.GLC_GlCode
        ,apy.AccountParty_Id
	    ,apy.APY_Name
		,prd.PRD_Name
		,apt.APT_Description as AccountPartyType
        ,AMS_MatchKey
		,rcc.RCC_Description as Cell_Captive
		,P.POL_PolicyNumber 
		,CLM_ClaimNumber
		,ATS_ReferenceNumber
		,P.POL_CreateDate
		,P.POL_StartDate
		,P.Policy_ID
        ,convert(varchar(6),ATS_EffectiveDate,112) as Effective_month
		,convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) as Corrected_effective_Month
      ,    ATS_EffectiveDate   
     ,ATN_CreateDate
        , atn.AccountTransaction_Id
        ,ATS.ATS_Description 
        , isnull( adi.ADI_GrossAmount,ATN.ATN_GrossAmount ) as ATN_GrossAmount
        , isnull( adi.ADI_NettAmount,ATN_NettAmount) as ATN_NettAmount
		,  adi.ADI_Item_ID
 --,ATS_Info5
-- ,ATS_Info2

FROM [Evolve].dbo.AccountTransactionSet AS ATS
left outer join evolve.dbo.[AccountTransactionType] as ATT on ats.ATS_AccountTransactionType_ID = att.AccountTransactionType_Id
left outer join evolve.dbo.systemusers as S on ats.ATS_CreateUser_ID = s.Users_ID
--inner join [WW_Migration].[dbo].[WW_Financials_to_Transfer]  as F on F.Policy_ID = ats.ATS_ReferenceNumber
--inner join RB_Analysis.[dbo].[WW_Financials_to_Transfer]  as F on F.Policy_ID = ats.ATS_ReferenceNumber
    INNER JOIN [Evolve].dbo.AccountTransaction AS ATN 
                ON ATS.AccountTransactionSet_Id = ATN.ATN_AccountTransactionSet_ID
    inner join [Evolve].dbo.Claim as C on c.Claim_ID = ats.ATS_ReferenceNumber
   inner join [Evolve].dbo.policy as P on P.Policy_ID = c.CLM_Policy_ID
  inner join #tmp as T on P.Policy_ID = T.Policy_ID
  
    
   left outer join [Evolve].dbo.Product as PRD on ats.ATS_Product_Id = prd.Product_Id
    left outer JOIN Evolve.dbo.AccountArea AS AAR 
                ON AAR.AccountArea_Id = ATS.ATS_AccountArea_ID
    left outer join [Evolve].[dbo].[DisbursementType] as DBT on atn.ATN_DisbursementType_ID = dbt.DisbursementType_Id
    LEFT OUTER JOIN  [Evolve].dbo.DisbursementSet AS DBS 
                ON DBS.DisbursementSet_Id = ATS.ATS_DisbursementRule_ID 
    LEFT OUTER JOIN  [Evolve].dbo.Disbursement AS DSM
                ON DSM.Disbursement_Id = DBS.DBS_Disbursement_ID
    left outer join Evolve.[dbo].[ReferenceGLCode] as RGL on ATN_GLCode_ID = RGL.GlCode_ID
    left outer join Evolve.[dbo].Insurer as INS on GLC_Insurer_Id = INS.Insurer_Id 
left outer join Evolve.dbo.AccountParty as apy on ATN_AccountParty_ID = apy.AccountParty_Id
left outer join Evolve.dbo.AccountPartyType as Apt on apt.AccountPartyType_Id = apy.APY_PartyType_ID
left outer join   Evolve.[dbo].[AccountMatchSet] as ms on ATN_AccountMatch_ID = ms.AccountMatchSet_Id
left outer join  Evolve.dbo.ReferenceCellCaptive as RCC on RCC.ReferenceCellCaptive_Code = ATS_CellCaptive_Id
left outer join #adi2 as adi on adi.ADI_AccountTransaction_ID = atn.AccountTransaction_Id and ADI_Item_ID <> '' and t.ITS_Item_ID = ADI_Item_ID and atn.ATN_GLCode_ID = adi.ADI_GLCode_ID

WHERE 1=1
--and convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) >= '202304'
and convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) <= convert(varchar(6),getdate(),112)

ORDER BY ATS_TransactionNumber --,ATN_DisbursementStep

--select * from #Financials where POL_PolicyNumber = 'HWTY019232POL'





--delete
--from #Financials
--where CLM_ClaimNumber is not NULL
--and exists (
--select *
--from Evolve.[dbo].[Claim] as C
--where c.Claim_ID = #Financials.ATS_ReferenceNumber
--and cast(c.CLM_CreateDate as date) <= '2023-04-01')

drop table RB_analysis.dbo.Evolve_Warranty_performance

select t.POL_PolicyNumber, 
left(t.POL_PolicyNumber,13) as Base_Policy_Number 
  , PMI_Make
	  , PMI_Model
,f.CLM_ClaimNumber,
isnull(ADI_Item_ID,CWI_PolicyWarrantyItem_ID) as ADI_Item_ID ,
t.POL_StartDate, t.POL_EndDate, t.Policy_Status, f.INS_InsurerName ,
Selling_Agent_Name, f.Cell_Captive,
t.Prd_Name ,
t.Variant_Level_1,
t.Variant_Level_3, 
t.PRV_Code ,
t.PRP_PlanName,t.RTF_Description,
f.Corrected_effective_Month, AAR_Description ,
sum(case when GLC_Description = 'Gross Written Premium' then  -ATN_GrossAmount else 0 end) as GWP ,
sum(case when AAR_Description = 'Policy Raise' then  -ATN_NettAmount else 0 end) as Fund_Income ,
sum(case when AAR_Description = 'Claims' then  -ATN_NettAmount else 0 end) as Claims_Expense_Overall,

sum(case when AAR_Description = 'Claims' and GLC_GlCode = '101200' then  -ATN_NettAmount else 0 end) as  Movement_In_Claims_Reserves ,
sum(case when AAR_Description = 'Claims' and GLC_GlCode = '101000' then  -ATN_NettAmount else 0 end) as  Movement_In_Claims_Paid ,
sum(case when isnull(AAR_Description,'') not in  ( 'Claims','Policy Raise') then  -ATN_NettAmount else 0 end) as Other_Atn_Nett,
case when isnull(AAR_Description,'') <> 'Claims' and
convert(varchar(6),t.POL_StartDate,112) <= Corrected_effective_Month and 
convert(varchar(6),t.POL_EndDate,112) >= Corrected_effective_Month then 1 else 0 end as Exposure_Months,
max(case when convert(varchar(6),c.CLM_CreateDate,112) = Corrected_effective_Month then 1 else 0 end) as Claims_Created ,
max(case when convert(varchar(6),c.CLM_CreateDate,112) = Corrected_effective_Month and isnull(CLM_Status,2) <> 2 then 1 else 0 end) as Claims_Created_Excl_Rejected ,
cast(0 as decimal(18,2)) as Fund_Balance
into RB_analysis.dbo.Evolve_Warranty_performance
from #Financials as F
inner join #tmp as T on F.Policy_ID = T.Policy_ID
inner join Evolve.[dbo].[Claim] as C on f.ATS_ReferenceNumber = c.Claim_ID
inner join  ( select distinct  CWI_Claim_ID , CWI_PolicyWarrantyItem_ID 
  FROM [Evolve].[dbo].[ClaimWarrantyItem] as cwi
  where CWI_Deleted = 0 ) as CI on c.Claim_ID = ci.CWI_Claim_ID and ci.CWI_PolicyWarrantyItem_ID = t.ITS_Item_ID
--where CLM_ClaimNumber is not NULL
where Corrected_effective_Month <= convert(varchar(6),getdate(),112)
--and t.Policy_id =   'CC4E8852-0C57-44ED-8EFE-4AFDD9B7BFBA'
and glc_GLcode in (
'101200',
'101000')
and isnull(ATT_Description,'') <>  'UPP Written Premium'
--and t.POL_PolicyNumber = 'HWTY000305POL' 
group by  t.POL_PolicyNumber, t.POL_StartDate, t.POL_EndDate, t.Policy_Status, t.Variant_Level_3,
t.PRV_Code,
t.PRP_PlanName,
Selling_Agent_Name, f.Cell_Captive,t.Prd_Name ,  t.Variant_Level_1,
f.Corrected_effective_Month, AAR_Description ,t.RTF_Description, f.INS_InsurerName,isnull(ADI_Item_ID,CWI_PolicyWarrantyItem_ID),f.CLM_ClaimNumber
  , PMI_Make
	  , PMI_Model


insert into RB_analysis.dbo.Evolve_Warranty_performance
select t.POL_PolicyNumber, 
left(t.POL_PolicyNumber,13) as Base_Policy_Number 
, PMI_Make
	  , PMI_Model
,f.CLM_ClaimNumber 
,ADI_Item_ID ,
t.POL_StartDate, t.POL_EndDate, t.Policy_Status, f.INS_InsurerName ,
Selling_Agent_Name, f.Cell_Captive,
t.prd_name ,
t.Variant_Level_1,
t.Variant_Level_3,
t.PRV_Code ,
t.PRP_PlanName,t.RTF_Description,
f.Corrected_effective_Month, AAR_Description ,
sum(case when GLC_Description = 'Gross Written Premium' then  -ATN_GrossAmount else 0 end) as GWP ,
sum(case when AAR_Description = 'Policy Raise' then  -ATN_NettAmount else 0 end) as Fund_Income ,
sum(case when AAR_Description = 'Claims' then  -ATN_NettAmount else 0 end) as Claims_Expense_Overall,

sum(case when AAR_Description = 'Claims' and GLC_GlCode = '101200' then  -ATN_NettAmount else 0 end) as  Movement_In_Claims_Reserves ,
sum(case when AAR_Description = 'Claims' and GLC_GlCode = '101000' then  -ATN_NettAmount else 0 end) as  Movement_In_Claims_Paid ,
sum(case when isnull(AAR_Description,'') not in  ( 'Claims','Policy Raise') then  -ATN_NettAmount else 0 end) as Other_Atn_Nett,
case when isnull(AAR_Description,'') <> 'Claims' and
convert(varchar(6),t.POL_StartDate,112) <= Corrected_effective_Month and 
convert(varchar(6),t.POL_EndDate,112) >= Corrected_effective_Month then 1 else 0 end as Exposure_Months,
0 as Claims_Created ,
0 as Claims_Created_Excl_Rejected ,
cast(0 as decimal(18,2)) as Fund_Balance
--select f.*
from #Financials as F
inner join #tmp as T on F.Policy_ID = T.Policy_ID

--where CLM_ClaimNumber is not NULL
where 1=1
--and t.POL_PolicyNumber = 'HWTY019232POL'
--and  ATS_TransactionNumber = '36945367'
--and Corrected_effective_Month <= convert(varchar(6),getdate(),112)
--and t.Policy_id =   'CC4E8852-0C57-44ED-8EFE-4AFDD9B7BFBA'
and glc_GLcode in ('100400' )
and isnull(ATT_Description,'') <>  'UPP Written Premium'
--and t.POL_PolicyNumber = 'HWTY019232POL' 
group by  t.POL_PolicyNumber, t.POL_StartDate, t.POL_EndDate, t.Policy_Status, t.Variant_Level_3, 
t.PRV_Code ,
t.PRP_PlanName,
Selling_Agent_Name, f.Cell_Captive, t.prd_name, t.Variant_Level_1,
f.Corrected_effective_Month, AAR_Description ,t.RTF_Description, f.INS_InsurerName, ADI_Item_ID 
, PMI_Make
	  , PMI_Model
	  ,f.CLM_ClaimNumber 
--select * from RB_analysis.dbo.Evolve_Warranty_performance where POL_PolicyNumber = 'HWTY019232POL'


---------------- select * from #tmp

insert into RB_analysis.dbo.Evolve_Warranty_performance
select t.POL_PolicyNumber,
left(t.POL_PolicyNumber,13) as Base_Policy_Number 
, PMI_Make
	  , PMI_Model
,f.CLM_ClaimNumber 
,ADI_Item_ID, t.POL_StartDate, t.POL_EndDate, t.Policy_Status,  f.INS_InsurerName,
Selling_Agent_Name, f.Cell_Captive,
t.prd_name ,
t.Variant_Level_1,
t.Variant_Level_3, 
t.PRV_Code ,
t.PRP_PlanName,t.RTF_Description,
f.Corrected_effective_Month, AAR_Description ,
sum(case when GLC_Description = 'Gross Written Premium' then  -ATN_GrossAmount else 0 end) as GWP ,
sum(case when AAR_Description = 'Policy Raise' and t.RtF_Description = 'Monthly'  then  -ATN_NettAmount else 0 end) as Fund_Income ,
sum(case when AAR_Description = 'Claims' then  -ATN_NettAmount else 0 end) as Claims_Expense_Overall,

sum(case when AAR_Description = 'Claims' and GLC_GlCode = '101200' then  -ATN_NettAmount else 0 end) as  Movement_In_Claims_Reserves ,
sum(case when AAR_Description = 'Claims' and GLC_GlCode = '101000' then  -ATN_NettAmount else 0 end) as  Movement_In_Claims_Paid ,
sum(case when isnull(AAR_Description,'') not in  ( 'Claims','Policy Raise') then  -ATN_NettAmount else 0 end) as Other_Atn_Nett,
case when convert(varchar(6),t.POL_StartDate,112) <= Corrected_effective_Month and 
convert(varchar(6),t.POL_EndDate,112) >= Corrected_effective_Month then 1 else 0 end as Exposure_Months,
max(case when convert(varchar(6),c.CLM_CreateDate,112) = Corrected_effective_Month then 1 else 0 end) as Claims_Created ,
max(case when convert(varchar(6),c.CLM_CreateDate,112) = Corrected_effective_Month and isnull(CLM_Status,2) <> 2 then 1 else 0 end) as Claims_Created_Excl_Rejected ,
0 as Fund_Balance
 --select f.*
from #Financials as F
inner join #tmp as T on F.Policy_ID = T.Policy_ID and f.ADI_Item_ID = t.ITS_Item_ID
left outer join Evolve.[dbo].[Claim] as C on f.ATS_ReferenceNumber = c.Claim_ID
--where CLM_ClaimNumber is not NULL
where Corrected_effective_Month <= convert(varchar(6),getdate(),112)
--and t.RtF_Description = 'Monthly' 
--and t.POL_PolicyNumber = 'HWTY019232POL' 
and isnull(ATT_Description,'') <>  'UPP Written Premium'
--and ADI_Item_ID =  '9ED7CFE8-31C9-41DE-8E4A-A672D60ECD0F'
and  isnull(ATT_Description,'')+isnull(DBT_Description,'') <> 'JournalCell Captive Fee Differential'
--and t.Policy_id =   'CC4E8852-0C57-44ED-8EFE-4AFDD9B7BFBA'
and glc_GLcode in (
'306302',
'306301',
'306305',
'100700',
'100000',
'306303',
'303304',
'306304'
)
--and isnull(ATT_Description,'') <>  'UPP Written Premium'
group by  t.POL_PolicyNumber, t.POL_StartDate, t.POL_EndDate, t.Policy_Status, t.Variant_Level_3,
t.PRV_Code ,
t.PRP_PlanName,
Selling_Agent_Name, f.Cell_Captive, t.prd_name,t.Variant_Level_1,
f.Corrected_effective_Month, AAR_Description ,t.RTF_Description, f.INS_InsurerName,ADI_Item_ID
,left(t.POL_PolicyNumber,13) 
, PMI_Make
	  , PMI_Model
,f.CLM_ClaimNumber 




--drop table #FundInput
SELECT  distinct    P.POL_PolicyNumber 
		,P.Policy_ID
		,rcc.RCC_Description as Cell_Captive
		,INS_InsurerName
     ,convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) as Corrected_effective_Month
     ,isnull(ADI_NettAmount,  ATN_NettAmount) as ATN_NettAmount
	 ,ADI_Item_ID
	 into #FundInput
FROM #ATS AS ATS
left outer join evolve.dbo.[AccountTransactionType] as ATT on ats.ATS_AccountTransactionType_ID = att.AccountTransactionType_Id
left outer join evolve.dbo.systemusers as S on ats.ATS_CreateUser_ID = s.Users_ID
--inner join [WW_Migration].[dbo].[WW_Financials_to_Transfer]  as F on F.Policy_ID = ats.ATS_ReferenceNumber
--inner join RB_Analysis.[dbo].[WW_Financials_to_Transfer]  as F on F.Policy_ID = ats.ATS_ReferenceNumber
    INNER JOIN #ATN AS ATN 
                ON ATS.AccountTransactionSet_Id = ATN.ATN_AccountTransactionSet_ID
   inner join [Evolve].dbo.policy as P on P.Policy_ID = ats.ATS_ReferenceNumber
   inner join #tmp as T on P.Policy_ID = T.Policy_ID
   left outer join [Evolve].dbo.Product as PRD on ats.ATS_Product_Id = prd.Product_Id
    left outer JOIN Evolve.dbo.AccountArea AS AAR 
                ON AAR.AccountArea_Id = ATS.ATS_AccountArea_ID
    left outer join [Evolve].[dbo].[DisbursementType] as DBT on atn.ATN_DisbursementType_ID = dbt.DisbursementType_Id
    LEFT OUTER JOIN  [Evolve].dbo.DisbursementSet AS DBS 
                ON DBS.DisbursementSet_Id = ATS.ATS_DisbursementRule_ID 
    LEFT OUTER JOIN  [Evolve].dbo.Disbursement AS DSM
                ON DSM.Disbursement_Id = DBS.DBS_Disbursement_ID
    left outer join Evolve.[dbo].[ReferenceGLCode] as RGL on ATN_GLCode_ID = RGL.GlCode_ID
   left outer join  Evolve.dbo.ReferenceCellCaptive as RCC on RCC.ReferenceCellCaptive_Code = ATS_CellCaptive_Id
     left outer join Evolve.[dbo].Insurer as INS on GLC_Insurer_Id = INS.Insurer_Id 
   left outer join #adi2 as adi on adi.ADI_AccountTransaction_ID = atn.AccountTransaction_Id and ADI_Item_ID <> '' and t.ITS_Item_ID = ADI_Item_ID and atn.ATN_GLCode_ID = adi.ADI_GLCode_ID

WHERE 1=1
and convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) >= '202304'
and convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) <= convert(varchar(6),getdate(),112)
and GLC_GlCode = '707000'
--and p.policy_id = '003A325E-9FF1-4089-B3FE-637C7F4C3261'



select distinct Corrected_effective_Month 
into #measMo
from #FundInput



--drop table #FundBalance
select Policy_ID,ADI_Item_ID,  Cell_Captive,INS_InsurerName, B.Corrected_effective_Month, sum(-ATN_NettAmount) as Fund_Balance
into #FundBalance
from #measMo as B,
#FundInput as I
where i.Corrected_effective_Month <=B.Corrected_effective_Month
--and Policy_ID = '003A325E-9FF1-4089-B3FE-637C7F4C3261'
group by Policy_ID, B.Corrected_effective_Month,Cell_Captive,INS_InsurerName,ADI_Item_ID


--select pol.pol_policynumber, f.*
--from #FundBalance as F
--inner join evolve.dbo.Policy as pol on f.Policy_ID = pol.Policy_ID
----where  pol.pol_policynumber = 'HWTY000096POL'

--order by pol_policynumber, Corrected_effective_Month
 

insert into RB_analysis.dbo.Evolve_Warranty_performance
select t.POL_PolicyNumber  
,left(t.POL_PolicyNumber,13) as Base_Policy_Number 
, PMI_Make
	  , PMI_Model
,null as CLM_ClaimNumber 	 
,ADI_Item_ID
,t.POL_StartDate, t.POL_EndDate, t.Policy_Status,  f.INS_InsurerName,
Selling_Agent_Name, f.Cell_Captive,
t.prd_name ,
t.Variant_Level_1,
t.Variant_Level_3, 
t.PRV_Code ,
t.PRP_PlanName,t.RTF_Description,
f.Corrected_effective_Month, 'Fund Balance' as AAR ,
0 as GWP ,
0 as Fund_Income ,
0 as Claims_Expense_Overall,
0 as  Movement_In_Claims_Reserves ,
0 as  Movement_In_Claims_Paid ,
0 as Other_Atn_Nett,
0 as Exposure_Months,
0 as Claims_Created ,
0 as Claims_Created_Excl_Rejected ,
sum(Fund_Balance) as Fund_Balance
from #FundBalance as F
inner join #tmp as T on F.Policy_ID = T.Policy_ID

group by  t.POL_PolicyNumber, t.POL_StartDate, t.POL_EndDate, t.Policy_Status,  f.INS_InsurerName,
Selling_Agent_Name, f.Cell_Captive,
  t.prd_name ,
t.Variant_Level_1,
t.Variant_Level_3, 
t.PRV_Code ,
t.PRP_PlanName,t.RTF_Description,
f.Corrected_effective_Month,ADI_Item_ID
	  , PMI_Make
	  , PMI_Model
 
drop table RB_analysis.dbo.Evolve_Warranty_performance_summary
select Selling_Agent_Name ,INS_InsurerName,  Cell_Captive,  prd_name,	Variant_Level_1,	Variant_Level_3,
PRV_Code ,
case when  RTF_Description = 'Monthly' then 'Monthly' else 'Upfront' end as Monthly_indicator,
isnull(s.Corrected_Make,PMI_Make) as Make ,
Age_Band,	Vehicle_Age ,
PRP_PlanName,
isnull(s.Price_Check,'Unknown') as Price_Check,
RTF_Description,	
year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) as Fin_Year,
case when year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) >= year(dateadd(month,6,getdate()))- 1 then  Corrected_effective_Month else year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) end as Corrected_effective_Month,
 sum(GWP) as GWP	,
 sum(Fund_Income) as Fund_Income	,
 sum(Claims_Expense_Overall	) as Claims_Expense_Overall,
 sum(Movement_In_Claims_Reserves) as 	Movement_In_Claims_Reserves,
 sum(Movement_In_Claims_Paid) as Movement_In_Claims_Paid	,
 sum(Other_Atn_Nett	) as Other_Atn_Nett,
 sum(Exposure_Months) as Exposure_Months	,
 sum(Claims_Created) as Claims_Created,
  sum(Claims_Created_Excl_Rejected) as Claims_Created_Excl_Rejected,
 sum(case when year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) >= year(dateadd(month,6,getdate()))- 1 then  Fund_Balance  
  when right(Corrected_effective_Month,2) = '06' then Fund_Balance else 0 end ) as Fund_Balance
 into RB_analysis.dbo.Evolve_Warranty_performance_summary 
 --select f.*
 from RB_analysis.dbo.Evolve_Warranty_performance as F
 left outer join [LC-FORECAST].RB_analysis.[dbo].[vw_Santam_Premium_Checks] as S on s.POL_PolicyNumber = f.POL_PolicyNumber and s.ITS_Item_ID = f.ADI_Item_ID

--where f.POL_PolicyNumber in ('HWTY019232POL')  --HWTY012339POL

 --where INS_InsurerName = 'Santam Limited'
 
 
group by Selling_Agent_Name ,Cell_Captive,  prd_name,	Variant_Level_1,	Variant_Level_3,
PRV_Code ,
RTF_Description,
year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) ,
case when year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) >= year(dateadd(month,6,getdate()))- 1 then  Corrected_effective_Month else year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) end   ,

INS_InsurerName,
case when  RTF_Description = 'Monthly' then 'Monthly' else 'Upfront' end,isnull(s.Price_Check,'Unknown'),
isnull(s.Corrected_Make,PMI_Make)  ,
PRP_PlanName, Age_Band,	Vehicle_Age  


----------RB added - 2025-06-12


drop table RB_analysis.dbo.Evolve_Warranty_performance_summary_model
select INS_InsurerName,  Cell_Captive,  prd_name,	Variant_Level_1,	Variant_Level_3,
PRV_Code ,
case when  RTF_Description = 'Monthly' then 'Monthly' else 'Upfront' end as Monthly_indicator,
isnull(s.Corrected_Make,PMI_Make) as Make ,PMI_Model ,
Age_Band,	Vehicle_Age ,
PRP_PlanName,
isnull(s.Price_Check,'Unknown') as Price_Check,
RTF_Description,	
year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) as Fin_Year,
case when year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) >= year(dateadd(month,6,getdate()))- 1 then  Corrected_effective_Month else year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) end as Corrected_effective_Month,
 sum(GWP) as GWP	,
 sum(Fund_Income) as Fund_Income	,
 sum(Claims_Expense_Overall	) as Claims_Expense_Overall,
 sum(Movement_In_Claims_Reserves) as 	Movement_In_Claims_Reserves,
 sum(Movement_In_Claims_Paid) as Movement_In_Claims_Paid	,
 sum(Other_Atn_Nett	) as Other_Atn_Nett,
 sum(Exposure_Months) as Exposure_Months	,
 sum(Claims_Created) as Claims_Created,
  sum(Claims_Created_Excl_Rejected) as Claims_Created_Excl_Rejected,
 sum(case when year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) >= year(dateadd(month,6,getdate()))- 1 then  Fund_Balance  
  when right(Corrected_effective_Month,2) = '06' then Fund_Balance else 0 end ) as Fund_Balance
 into RB_analysis.dbo.Evolve_Warranty_performance_summary_Model 
 --select f.*
 from RB_analysis.dbo.Evolve_Warranty_performance as F
 left outer join [LC-FORECAST].RB_analysis.[dbo].[vw_Santam_Premium_Checks] as S on s.POL_PolicyNumber = f.POL_PolicyNumber and s.ITS_Item_ID = f.ADI_Item_ID

--where f.POL_PolicyNumber in ('HWTY019232POL')  --HWTY012339POL

 --where INS_InsurerName = 'Santam Limited'
 
 
group by Cell_Captive,  prd_name,	Variant_Level_1,	Variant_Level_3,
PRV_Code ,
RTF_Description,
year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) ,
case when year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) >= year(dateadd(month,6,getdate()))- 1 then  Corrected_effective_Month else year(dateadd(month,6,cast(Corrected_effective_Month+'01' as date))) end   ,

INS_InsurerName,
case when  RTF_Description = 'Monthly' then 'Monthly' else 'Upfront' end,isnull(s.Price_Check,'Unknown'),
isnull(s.Corrected_Make,PMI_Make),PMI_Model  ,
PRP_PlanName, Age_Band,	Vehicle_Age