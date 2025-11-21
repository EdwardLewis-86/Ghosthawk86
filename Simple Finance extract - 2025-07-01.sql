
 

SELECT         AAR.AAR_Description 
		,POL_PolicyNumber
		,POL_Status
						,ATS_CreateDate
,ATS_TransactionNumber
,ATS_CreateUser_ID
,s.USR_FirstName+' '+s.USR_Surname as TX_Created_By
,ats.AccountTransactionSet_Id
,AccountTransaction_Id
,att.ATT_Description
,ATS_AccountTransactionType_ID
        ,DBS.DBS_SetName
        ,DSM.DSM_RuleName
        ,dbt.DBT_Description
        ,ats.ATS_Insurer_Id
        ,INS.INS_InsurerName
        ,RGL.GLC_Description    
        ,RGL.GLC_GlCode
  ,ATN_GLCode_ID
 ,ATN_GLCodeVAT_ID
       ,atn.ATN_DisbursementStep
        ,atn.ATN_AccountParty_ID
	    ,apy.APY_Name
		,apy.APY_PartyNumber
		,apy.APY_HasVAT
		,prd.PRD_Name
		,prv.prv_name
		,prd.PRD_GLCode
		,apt.APT_Description as AccountPartyType
		,ATN_AccountMatch_ID
        ,AMS_MatchKey
		,rcc.RCC_Description as Cell_Captive

		,RPM_Description as Payment_Method
		,RBI_Description as Bulking_Institution
		,POL_Deleted
		,ATS_DisplayNumber
		,CLM_ClaimNumber
		,POL_CreateDate
		,POL_StartDate
		,Policy_ID
		,POL_Client_ID
		,CLI_Name+' '+cli_surname as Client_Name
		,ats.ATS_ReferenceNumber

        ,convert(varchar(6),ATS_EffectiveDate,112) as Effective_month
		,convert(varchar(6), case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end,112) as Corrected_effective_Month
		, case when ATN_CreateDate > ATS_EffectiveDate then ATN_CreateDate else ATS_EffectiveDate end  as Corrected_effective_date
 ,    ATS_EffectiveDate   
 ,ATN_CreateDate
        ,ATS.ATS_Description 
        ,ATN.ATN_GrossAmount
        ,atn_vatamount
        ,ATN_NettAmount
 ,ATS_Info5
 ,ATS_Info2
 ,ATS_ReversalOfSet_ID
  ,ATS_ReversedBySet_ID
  ,isnull(nullif(ATS_ReversalOfSet_ID,''), ats.AccountTransactionSet_Id) as Related_Set
  ,ATN_DisbursementType_ID
  ,case when ATS_ReversalOfSet_ID <> '' then 'Reversed' when ATS_ReversedBySet_ID <> '' then 'Reversed' else '' end as Reversed_Tx_Flag
  ,ATS_SalesBranch
 ,ATS_UppAccountTransactionSet_Id
 ,ATS_ReversalReason
 -- ,case when apt.APT_Description <> 'Unallocated' then 'Incorrect Party Type' else 'OK' end as Error_Type
  --select ats.*--, atn.*
 -- into #tmp
-- select p.*
FROM .dbo.AccountTransactionSet AS ATS
left outer join .dbo.[AccountTransactionType] as ATT on ats.ATS_AccountTransactionType_ID = att.AccountTransactionType_Id
left outer join .dbo.systemusers as S on ats.ATS_CreateUser_ID = s.Users_ID
--inner join [WW_Migration].[dbo].[WW_Financials_to_Transfer]  as F on F.Policy_ID = ats.ATS_ReferenceNumber
--inner join RB_Analysis.[dbo].[WW_Financials_to_Transfer]  as F on F.Policy_ID = ats.ATS_ReferenceNumber
    INNER JOIN .dbo.AccountTransaction AS ATN 
                ON ATS.AccountTransactionSet_Id = ATN.ATN_AccountTransactionSet_ID
   left outer join .dbo.policy as P on P.Policy_ID = ats.ATS_ReferenceNumber

   left join [dbo].[ReferenceBulkingInstitution] as BI on POL_BulkInstitution_ID = bi.BulkingInstitution_ID
   left join [Evolve].[dbo].[ReferencePaymentMethod] as rpm on rpm.ReferencePaymentMethod_ID = POL_PaymentMethod_ID
   left join .dbo.ProductVariant as prv on p.POL_ProductVariantLevel3_ID = prv.ProductVariant_Id
   left join evolve.dbo.client as cli on p.POL_Client_ID = cli.Client_ID
    left outer join .dbo.Claim as C on c.Claim_ID = ats.ATS_ReferenceNumber
   left outer join .dbo.Product as PRD on ats.ATS_Product_Id = prd.Product_Id
    left outer JOIN .dbo.AccountArea AS AAR 
                ON AAR.AccountArea_Id = ATS.ATS_AccountArea_ID
    left outer join .[dbo].[DisbursementType] as DBT on atn.ATN_DisbursementType_ID = dbt.DisbursementType_Id
    LEFT OUTER JOIN  .dbo.DisbursementSet AS DBS 
                ON DBS.DisbursementSet_Id = ATS.ATS_DisbursementRule_ID 
    LEFT OUTER JOIN  .dbo.Disbursement AS DSM
                ON DSM.Disbursement_Id = DBS.DBS_Disbursement_ID
    left outer join .[dbo].[ReferenceGLCode] as RGL on ATN_GLCode_ID = RGL.GlCode_ID
    left outer join .[dbo].Insurer as INS on ins.Insurer_Id = ats.ATS_Insurer_Id 
left outer join .dbo.AccountParty as apy on ATN_AccountParty_ID = apy.AccountParty_Id
left outer join .dbo.AccountPartyType as Apt on apt.AccountPartyType_Id = apy.APY_PartyType_ID
left outer join   .[dbo].[AccountMatchSet] as ms on ATN_AccountMatch_ID = ms.AccountMatchSet_Id
left outer join  .dbo.ReferenceCellCaptive as RCC on RCC.ReferenceCellCaptive_Code = ATS_CellCaptive_Id

WHERE 1=1

 and ATS_DisplayNumber in ('QWTY149731POL')
 
ORDER BY  ATS_EffectiveDate, ATN_CreateDate , AccountTransaction_Id , CLM_ClaimNumber,  ATS_TransactionNumber ,ATN_DisbursementStep

