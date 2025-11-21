--DROP TABLE #Claim_Item
SELECT *
INTO #Claim_Item
from (
SELECT [CMI_Claim_ID] AS [CLB_Claim_ID], ClaimMotorBasicItem_ID, 
CMI_CreateDate,
CMI_Status,	CMI_SubStatus, CMI_ClaimDescription, CMI_SectionName, CMI_Estimate,	CMI_OdoMeterReading, CMI_Policy_ID ,
CMI_PolicyMotorBasicItem_ID ,
CMI_Make,	CMI_Model, CMI_RegistrationNumber,	CMI_VINNumber,	CMI_EngineNumber,
null as CLB_Name,null as 	CLB_Surname, null as 	CLB_Initials, null as 	CLB_IDNumber
--select *
from  .[dbo].[ClaimMotorBasicItem]

UNION ALL

SELECT [CPA_Claim_ID], ClaimPABasicItem_ID ,CPA_CreateDate,
CPA_STATUS, CPA_SubStatus, CPA_ClaimDescription, CPA_SectionName, CPA_Estimate,null as ODO,  CPA_Policy_ID,
CPA_PolicyPABasicItem_ID  ,
 null as CPA_Make, null as 	CPA_Model, null as  CPA_RegistrationNumber,	 null as CPA_VINNumber,	 null as CPA_EngineNumber,	CPA_Name,	CPA_Surname,NULL AS	CPA_Initials,	CPA_IDNumber
--select *
from  .[dbo].[ClaimPABasicItem]

UNION ALL

select [CGI_Claim_ID], ClaimGenericItem_ID,CGI_CreateDate,
CGI_Status,	CGI_SubStatus, CGI_ClaimDescription,CGI_SectionName, CGI_Estimate,NULL AS	CGI_OdoMeterReading, CGI_Policy_ID ,
CGI_PolicyGenericItem_ID ,
null as CGI_Make,null as 	CGI_Model,null as  CGI_RegistrationNumber,null as 	CGI_VINNumber,null as 	CGI_EngineNumber,
null as CLB_Name,null as 	CLB_Surname, null as 	CLB_Initials, null as 	CLB_IDNumber
--select *
from  .[dbo].[ClaimGenericItem]

UNION ALL

select [Ccs_Claim_ID], ClaimCreditShortfallItem_ID,
Ccs_CreateDate,
CCS_Status,	CCS_SubStatus,CCS_ClaimDescription,CCS_SectionName,CCS_Estimate,	CCS_OdoMeterReading, CCS_Policy_ID ,
CCS_PolicyCreditShortfallItem_ID ,
CCS_Make,	CCS_Model,CCS_RegistrationNumber,	CCS_VINNumber,	CCS_EngineNumber,
null as CLB_Name,null as 	CLB_Surname, null as 	CLB_Initials, null as 	CLB_IDNumber
--select *
from  .[dbo].[ClaimCreditShortfallItem]
where CCS_Deleted = 0

UNION ALL

select [CLB_Claim_ID], [ClaimCreditLifeBasicItem_ID],CLB_CreateDate,

CLB_STATUS, CLB_SubStatus, CLB_ClaimDescription,CLB_SectionName, CLB_Estimate,null as ODO,  CLB_Policy_ID,
CLB_PolicyCreditLifeBasicItem_ID ,
CLB_Make,	CLB_Model, CLB_RegistrationNumber,	CLB_VINNumber,	CLB_EngineNumber,	CLB_Name,	CLB_Surname,	CLB_Initials,	CLB_IDNumber
--select *
from  .[dbo].[ClaimCreditLifeBasicItem] as CLB
where CLB_Deleted = 0

UNION ALL


select CWI_Claim_ID, ClaimWarrantyItem_ID , 
CWI_CreateDate,
CWI_Status, CWI_SubStatus, CWI_ClaimDescription,CWI_SectionName, CWI_Estimate,CWI_OdoMeterReading  as ODO,  CWI_Policy_ID,
CWI_PolicyWarrantyItem_ID ,
CWI_Make,	CWI_Model, CWI_RegistrationNumber,	CWI_VINNumber,	CWI_EngineNumber, null as	CWI_Name, null as		CWI_Surname, null as CWI_Initials, null as CWI_IDNumber
--select *
from  .[dbo].[ClaimWarrantyItem]
where CWI_Deleted = 0


) AS x




--drop table #CL_Claims

SELECT  [Claim_ID]
		,ClaimMotorBasicItem_ID
		,CLM_Policy_ID
		,clb.CMI_PolicyMotorBasicItem_ID
	  , P.PRD_Name
      ,[CLM_CreateUser_ID]
      ,[CLM_CreateDate]
	  ,CMI_CreateDate AS Claim_item_Create_Date
      ,[CLM_UpdateUser_ID]
      ,[CLM_UpdateDate]
      ,[CLM_Deleted]
      ,[CLM_AssignedUser_ID]
      ,[CLM_PolicyNumber]
      ,[CLM_ClaimNumber]
      ,[CLM_Status]
      ,[CLM_Description]
      ,[CLM_ReportedDate]
      ,[CLM_LossDate]
      ,[CLM_BrokerAgentName]
      ,[CLM_BrokerAgentClaimNumber]
      ,[CLM_PoliceCaseNumber]
      ,[CLM_ClientType]
      ,[CLM_ClientTitle]
      ,[CLM_ClientFirstName]
      ,[CLM_ClientSurname]
      ,[CLM_ClientIDType_ID]
      ,[CLM_ClientIDNumber]
      ,[CLM_ClientMaskedIDNumber]
      ,[CLM_ClientPassportNumber]
      ,[CLM_ClientMaskedPassportNumber]
      ,[CLM_ClientDateOfBirth]
      ,[CLM_ClientGender]
      ,[CLM_ClientCompanyName]
      ,[CLM_ClientCompanyRegistration]
      ,[CLM_ClientNatureOfBusiness]
      ,C.[CIC_AdditionalDescription]
      ,[CLM_ExGratiaType_ID]
      ,[CLM_ExGratiaTypeText]
      ,[CLM_ExGratiaReason_ID]
      ,[CLM_ExGratiaReasonText]
      ,[CLM_ExGratiaAmount]
      ,[CLM_ExGratiaUser_ID]
      ,[CLM_ExGratiaDate]
      ,[CLM_EDICaptureFirstName]
      ,[CLM_EDICaptureSurname]
      ,[CLM_EDICaptureEmail]
      ,[CLM_EDICapturePhone]
	  ,CMI_ClaimDescription
	  ,CMI_Estimate	
	  ,CMI_Policy_ID	
	  ,CMI_Make	
	  ,CMI_Model
	  ,CMI_RegistrationNumber	
	  ,CMI_VINNumber	
	  ,CMI_EngineNumber	
	  ,CLB_Name	
	  ,CLB_Surname	
	  ,CLB_Initials	
	  ,CLB_IDNumber	
	  , cic.ClaimItemComponents_ID 
	  ,ROW_NUMBER() over (partition by CIC_ClaimItem_ID order by CIC_createdate) as CIC_Seq
	  ,CIC_Description
	  ,CMI_SectionName
	  ,cic.CIC_CreateDate
	  ,CIC_Limit
	  ,CIC_PartsAmount	
	  ,CIC_LabourAmount	
	  ,CIC_OtherAmount
	  ,CIC_AuthAmount
	  ,CIC_PayeeLink_ID
	  ,CLS_Description AS Claim_Status
	  ,CIS.CIS_Description AS Claim_Item_Status
	  ,CsS.CIS_Description AS Claim_Item_Sub_Status
	  ,CMI_OdoMeterReading
	  ,CAST(NULL AS DECIMAL(10,2)) AS Initial_Estimate
	  ,CAST(NULL AS DECIMAL(10,2)) AS Authorised_Amount
	  ,cast(null as decimal(10,2)) as Invoice_Amount
	  ,cast(null as varchar(6)) as Min_Payment_Month
	  ,cast(null as varchar(6)) as Max_Payment_Month
	  ,cast(null as decimal(10,2)) as Amount_Outstanding
	  ,cast(null as date) as Amount_Outstanding_Update_Date
	  ,USR_FirstName+' '+USR_Surname	as UserName
	  ,USR_EmailAddress
	  ,case when USR_EmailAddress like '%CMC%' then 'CMC' else 'M-Sure' end as Auth_Agent_Company
	  ,cast(null as varchar(100)) as Supplier_type

  into #CL_Claims
  --select cIC.*
  FROM  .[dbo].[Claim] as C
  left outer join  .[dbo].[ReferenceClaimstatus] as CLS on CLS.ClaimStatus_ID	= C.CLM_Status
  INNER join [RB_Analysis].[dbo].[Evolve_Policy] as P on C.CLM_Policy_ID = P.Policy_id
  left outer join #Claim_Item  as CLB on C.[Claim_ID] = CLB.[CLB_Claim_ID]
  left outer join  .[dbo].[ClaimItemComponents] as CIC on CIC.CIC_ClaimItem_ID = CLB.ClaimMotorBasicItem_ID AND CIC_DELETED = 0
  LEFT OUTER JOIN  .[dbo].[ReferenceClaimitemstatus] AS CIS ON CIS.ClaimItemStatus_ID = CLB.CMI_STATUS
  LEFT OUTER JOIN  .[dbo].[ReferenceClaimitemsubstatus] AS CSS ON CSS.ClaimItemSubStatus_ID = CLB.CMI_SubStatus
   left outer join   .[dbo].[SystemUsers] as U on c.CLM_AssignedUser_ID = U.Users_ID
  where c.CLM_CreateDate >= '2019-07-01'
  --and CLM_PolicyNumber = 'DWA000024POL'
  --and CLM_Deleted = 0
     --and P.Insurer_Name = 'Discovery Insure'

	 Update C
	 set Supplier_type = rst.Sup_Description
	 from #CL_Claims as C
	 inner join  .[dbo].[ClaimSupplierLink] as cSl on C.ClaimMotorBasicItem_ID = csl.CSL_ClaimItem_ID
	 inner join  .[dbo].[Supplier] as SUP on CSL.[CSL_Supplier_ID] = sup.[Supplier_Id]
  inner join   .[dbo].[ReferenceSupplierType] as RST on sup.SUP_Type = rst.[SupplierType_ID]
 



--  select C.Claim_ID,CLM_PolicyNumber,	CLM_ClaimNumber, C.Claim_Status, Claim_Item_Status, CIT_ClaimItem_ID, CIT_EffectiveDate, CIT_TransactionTypeDescription,	
--  CIT_AmountEstimate,	CIT_Amount as OCR_Movement,	CIT_AmountOutstanding, CIT_InvoiceAmount, cit_PayeeName ,
--  row_Number() over (partition by CIT_ClaimItem_ID order by CIT_UpdateDate) as SeqNum
--  -- select *
--from #CL_Claims as C
--inner join  .[dbo].[ClaimItemTransaction] as CIT on C.ClaimMotorBasicItem_ID = CIT.CIT_ClaimItem_ID
--where 1=1
----and CLM_PolicyNumber = 'QADC003282POL'
--and CIT_Deleted = 0
----and CIT_ClaimItem_ID = '4F921592-EC64-4940-9386-0B3DFD5D5A57'
--and CIT_IsReversed = 0
--order by CIT_ClaimItem_ID, CIT_UpdateDate

select AccountPartyType_Id,APT_Description
 into #apt
from  .[dbo].[AccountPartyType]

insert into #apt
select 10, 'Policy Beneficiary'


insert into #apt
select 4, 'SASRIA'


 drop table [RB_Analysis].dbo.Evolve_Claim_Summary
 
 select Insurer, CLM_PolicyNumber,Policy_id,
 CMI_PolicyMotorBasicItem_ID,
 Sum_Insured, First_Reg_Date, Make,  Model ,POL_StartDate,Vin_Number,
 CLM_ClaimNumber, CIT_ClaimItem_ID,Claim_item_Create_Date,
 ClaimItemTransaction_ID,CMI_OdoMeterReading,
 case when datediff(month,Claim_item_Create_Date,isnull(case when CIT_EffectiveDate < CIT_postingDate then CIT_postingDate else CIT_EffectiveDate end,CIC_CreateDate)) > 1 
 and isnull(CIC_Description,'') not in ('Instalment Cover')  then   Claim_Abandoned_indicator else '' end as Claim_Abandoned_indicator,
 Claim_ID,  ClaimMotorBasicItem_ID,
 Claim_Status, Claim_Item_Status,
 cast(null as varchar(250)) as Claim_Rejection_reason ,
 CLM_ReportedDate,	CLM_LossDate,CLM_CreateDate ,
 Payee_Type ,
 CIT_PayeeID,	CIT_PayeeName,
  supplier_type,
  Claim_Item_Sub_Status,CIC_Description,CMI_SectionName ,
  CLM_Description,
  CMI_ClaimDescription,
  CIC_limit,CIC_Seq,CIT_Seq,CIT_CreateDate,
  UserName ,USR_EmailAddress  , Auth_Agent_Company
 ,CIC_PartsAmount	
	  ,CIC_LabourAmount	
	  ,CIC_OtherAmount
	  ,CIC_AuthAmount
	  ,isnull(case when CIT_EffectiveDate < CIT_postingDate then CIT_postingDate else CIT_EffectiveDate end ,CIC_CreateDate) as Transaction_date
	  ,CIT_EffectiveDate
 ,convert(varchar(6),isnull(case when CIT_EffectiveDate < CIT_postingDate then CIT_postingDate else CIT_EffectiveDate end,CIC_CreateDate),112) as Trans_Month,sum(isnull(OCR_Movement,0)) as OCR_Movement, 
 sum(case when OCR_Movement >0 then  OCR_Movement else 0 end) as OCR_Raised,
 sum(case when OCR_Movement < 0 then  OCR_Movement else 0 end) as OCR_Released,
 sum(isnull(CIT_InvoiceAmount,0)) as Invoice_Value,
 -sum(isnull(Amount_Paid,0)) as Amount_Paid,
  -sum(isnull(Amount_Paid_excl_VAT,0)) as Amount_Paid_excl_VAT,
 sum(case when seqNum = 1 then 1 else 0 end) as Claim_Qty,
 sum(case when seqNum = 1 then OCR_Movement else 0 end) as Original_Estimate
 into [RB_Analysis].dbo.Evolve_Claim_Summary
 from (
  select p.Insurer_Name +' - '+ case when  P.PRD_Name like '%life%' then 'Life' else 'Short Term' end as Insurer, 
  p.Sum_Insured, p.First_Reg_Date,p.make,  p.Model,p.Vin_Number,
  C.Claim_ID,CIC_Description  , CMI_SectionName ,CMI_ClaimDescription ,CMI_OdoMeterReading,
  CIC_CreateDate,CIT_CreateDate,
   UserName ,USR_EmailAddress  , Auth_Agent_Company
  ,case when ROW_NUMBER() over (partition by ClaimItemTransaction_ID order by CIT_CreateDate) = 1 then CIC_limit else 0 end as  CIC_limit 
  ,CIC_Seq
  	  ,case when ROW_NUMBER() over (partition by CIC_Seq,ClaimMotorBasicItem_ID order by CIT_CreateDate) = 1 then CIC_PartsAmount else 0 end as CIC_PartsAmount	
	  ,case when ROW_NUMBER() over (partition by CIC_Seq,ClaimMotorBasicItem_ID order by CIT_CreateDate) = 1 then CIC_LabourAmount else 0 end as CIC_LabourAmount	
	  ,case when ROW_NUMBER() over (partition by CIC_Seq,ClaimMotorBasicItem_ID order by CIT_CreateDate) = 1 then CIC_OtherAmount else 0 end as CIC_OtherAmount
	  ,case when ROW_NUMBER() over (partition by CIC_Seq,ClaimMotorBasicItem_ID order by CIT_CreateDate) = 1 then CIC_AuthAmount else 0 end as CIC_AuthAmount
  ,POL_StartDate,
  CLM_ReportedDate,	CLM_LossDate,CLM_CreateDate ,
  CLM_PolicyNumber,Policy_id,
  CMI_PolicyMotorBasicItem_ID,
  CLM_ClaimNumber, isnull(CIT_ClaimItem_ID,C.ClaimMotorBasicItem_ID) as CIT_ClaimItem_ID,ClaimItemTransaction_ID, cast( CLM_Description as varchar(100)) as CLM_Description,
  ClaimMotorBasicItem_ID,Claim_item_Create_Date,
  C.Claim_Status, Claim_Item_Status, Claim_Item_Sub_Status,
   CIT_PayeeID,	APT_Description as Payee_Type,CIT_PayeeType_ID,
   CIT_PayeeName,
    c.supplier_type ,
   CIT_EffectiveDate,CIT_postingDate,
   CIT_TransactionTypeDescription,	
  CIT_AmountEstimate,	CIT_Amount as OCR_Movement,	CIT_AmountOutstanding, CIT_InvoiceAmount, 
  isnull(CASE WHEN CIT_TransactionType_ID = 2 THEN CIT_Amount ELSE 0 END,0) as Amount_Paid,
   isnull(CASE WHEN CIT_TransactionType_ID = 2 THEN isnull(CIT_Amount,0) - isnull(CIT_AmountVAT,0) ELSE 0 END,0) as Amount_Paid_excl_VAT,
  ROW_NUMBER() over (partition by ClaimItemTransaction_ID order by CIT_CreateDate) as CIT_Seq
  ,row_Number() over (partition by CIT_ClaimItem_ID order by CIT_UpdateDate) as SeqNum
  ,case when CIT_AmountOutstanding = 0  and CIT_TransactionTypeDescription = 'Estimate Adjust' then 'Claim Abandoned' else '' end as Claim_Abandoned_indicator
  -- select  c.*
from #CL_Claims as C
inner join [RB_Analysis].[dbo].[Evolve_Policy] as P on c.CLM_Policy_ID = p.Policy_id
left outer join  .[dbo].[ClaimItemTransaction] as CIT on C.ClaimMotorBasicItem_ID = CIT.CIT_ClaimItem_ID 
and CIT_Deleted = 0 and CIT_IsReversed = 0 and CIC_Seq = 1 --and isnull(c.Supplier_type,'') <> 'Assessor'   --RB Removed Assessor Restriction -- 2024-06-20
left outer join #apt as apt on apt.AccountPartyType_Id = cit.CIT_PayeeType_ID
where 1=1
--and CLM_ClaimNumber = 'DWA013266CLM'
--and CLM_PolicyNumber = 'QPAB007915POL'
and CLM_Deleted = 0
--and CIT_ClaimItem_ID = '4F921592-EC64-4940-9386-0B3DFD5D5A57'
--order by CIT_ClaimItem_ID, CIT_UpdateDate 
) as X
group by Insurer, CLM_PolicyNumber,Policy_id, CLM_ClaimNumber,POL_StartDate, Claim_Status, Claim_Item_Status, Claim_Item_Sub_Status, 
convert(varchar(6),isnull(case when CIT_EffectiveDate < CIT_postingDate then CIT_postingDate else CIT_EffectiveDate end,CIC_CreateDate),112),CIC_Description, Sum_Insured, First_Reg_Date, 
Make, Model, Vin_Number, CIC_limit,
 CLM_ReportedDate,	CLM_LossDate,CLM_CreateDate,  CIT_ClaimItem_ID ,ClaimItemTransaction_ID,
 case when datediff(month,Claim_item_Create_Date,isnull(case when CIT_EffectiveDate < CIT_postingDate then CIT_postingDate else CIT_EffectiveDate end,CIC_CreateDate)) > 1 
 and isnull(CIC_Description,'') not in ('Instalment Cover')  then   Claim_Abandoned_indicator else '' end,
 ClaimMotorBasicItem_ID,CIT_PayeeID,	CIT_PayeeName,
   supplier_type,
  UserName ,USR_EmailAddress  , Auth_Agent_Company
  ,CIC_PartsAmount	
	  ,CIC_LabourAmount	
	  ,CIC_OtherAmount
	  ,CIC_AuthAmount
	  ,CIT_Seq
	  ,CIC_Seq
	  ,CLM_Description
	  ,Claim_ID
	  ,isnull(case when CIT_EffectiveDate < CIT_postingDate then CIT_postingDate else CIT_EffectiveDate end,CIC_CreateDate)
	  ,Claim_item_Create_Date
	  ,CIT_EffectiveDate
	  ,CIT_CreateDate
	  ,CMI_PolicyMotorBasicItem_ID
	  ,CMI_SectionName
	  ,Payee_Type
	  ,CMI_ClaimDescription
	  ,CMI_OdoMeterReading
--order by 1,2,3,7


----------

drop table [RB_Analysis].[dbo].Evolve_Abandoned_Claims_days_to_reopen
select f.CIT_ClaimItem_ID,a.Transaction_date, min( datediff(day, a.Transaction_date, f.Transaction_date)) as days_to_Reopen
into [RB_Analysis].[dbo].Evolve_Abandoned_Claims_days_to_reopen
from (
select *
from [RB_Analysis].[dbo].[Evolve_Claim_Summary]
where Claim_Abandoned_indicator = 'Claim Abandoned'
--and CLM_ClaimNumber = 'HCLL001567CLM' 
) as A
inner join  [RB_Analysis].[dbo].[Evolve_Claim_Summary] as F on a.CIT_ClaimItem_ID = F.CIT_ClaimItem_ID and F.Transaction_date >= A.Transaction_date and f.OCR_Raised > 0
group by f.CIT_ClaimItem_ID,a.Transaction_date


Update E
Set Claim_Abandoned_indicator = ''
--select R.*
from [RB_Analysis].[dbo].[Evolve_Claim_Summary] as E
inner join
[RB_Analysis].[dbo].Evolve_Abandoned_Claims_days_to_reopen as R on E.CIT_ClaimItem_ID = R.CIT_ClaimItem_ID and e.Transaction_date = R.Transaction_date 
and e.Claim_Abandoned_indicator = 'Claim Abandoned'
and R.days_to_Reopen = 0

-------------------



--drop table #eventlogClaim
select [EventLog_ID]
      ,[EventLogDetail_ID]
      ,[clm_claimnumber]
      ,[EVL_Description]
      ,[ELD_Description]
      ,[ELD_NewValue]
      ,[EVL_DateTime]
	  ,0 as Record_exists
	  into #eventlogClaim
--select top 100 *
from [dbo].[EventLog] as EL
left outer join [dbo].[EventLogDetail] as ED on el.[EventLog_ID] = ed.ELD_EventLog_ID
inner join [dbo].[Claim] as P on el.EVL_ReferenceNumber = p.claim_id 
where EVL_DateTime >= dateadd(day,-14,getdate())
 

Update I
Set Record_Exists = 1
from #eventlogClaim as I
inner join [RB_Analysis].[dbo].[Evolve_Claims_Logs] as PL on i.EventLog_ID = pl.EventLog_ID and isnull(i.EventLogDetail_ID,'') = isnull(pl.EventLogDetail_ID,'')

 

insert into [RB_Analysis].[dbo].[Evolve_Claims_Logs]
select * 
from #eventlogClaim as I
where Record_Exists = 0
order by EVL_DateTime




select distinct EventLog_ID
into #RejectReasonid
from [RB_Analysis].[dbo].[Evolve_Claims_Logs]
where ELD_Description = 'Reject Reason'


Update C
set Claim_Rejection_reason = left(ELD_Description,250)
--select distinct left(ELD_Description,250)
from [RB_Analysis].[dbo].[Evolve_Claims_Logs] as L
inner join [RB_Analysis].dbo.Evolve_Claim_Summary as C on L.clm_claimnumber = c.CLM_ClaimNumber
where exists (select *
from #RejectReasonid as R
where l.EventLog_ID = r.EventLog_ID )
and ELD_Description not in (
'Claim Item Rejected',
'Reject Reason',
'Reject Comment',
'Claim Rejection = Claim Repudiation!',
'ClaimItemID',
'Reopening Reason',
'Reopening Comment',
'.  ',
'.  ',
'Free text field',
'refer claim items  '  

)
and nullif(ELD_Description,'') is not null


