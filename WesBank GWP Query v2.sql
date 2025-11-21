SELECT   EOMONTH(CASE 
        WHEN ats.ATS_CreateDate > ats.ATS_EffectiveDate THEN ats.ATS_CreateDate 
        ELSE ats.ATS_EffectiveDate 
    END) AS [ReportingDate]
	,CASE 
        WHEN p.POL_SoldDate >= '2022-10-01' THEN 1 
        WHEN p.POL_SoldDate < '2022-10-01' THEN 0 
        ELSE NULL 
    END AS [NewRateInd]
	--,POL_PolicyNumber
   --     ,policy_id
        ,-sum(ATN.ATN_GrossAmount) as GWP
     --    ,sum(ATN_NettAmount) as ATN_NettAmount

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
    LEFT OUTER JOIN  .dbo.DisbursementSet AS DBS 
                ON DBS.DisbursementSet_Id = ATS.ATS_DisbursementRule_ID 
    LEFT OUTER JOIN  .dbo.Disbursement AS DSM
                ON DSM.Disbursement_Id = DBS.DBS_Disbursement_ID
    left outer join .[dbo].[ReferenceGLCode] as RGL on ATN_GLCode_ID = RGL.GlCode_ID
    left outer join .[dbo].Insurer as INS on ins.Insurer_Id = ats.ATS_Insurer_Id 
left outer join .dbo.AccountParty as apy on ATN_AccountParty_ID = apy.AccountParty_Id
left outer join .dbo.AccountPartyType as Apt on apt.AccountPartyType_Id = apy.APY_PartyType_ID
left outer join   .[dbo].[AccountMatchSet] as ms on ATN_AccountMatch_ID = ms.AccountMatchSet_Id
left outer join  .dbo.ReferenceCellCaptive as RCC on RCC.ReferenceCellCaptive_Code = ATS_CellCaptive_Id
left outer join  [Evolve].[dbo].Insurer as i on ats.ATS_Insurer_Id = i.Insurer_Id 
 
WHERE 1=1
-- and ATS_DisplayNumber in ('HADC077633POL')
and GLC_Description = 'Gross Written Premium'
    AND p.POL_Product_ID IN (
        'DDDC2DA4-881F-40B9-A156-8B7EA881863A','D0A30440-6F96-4735-A841-F601504BE51C', 
        '436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18',
        '77C92C34-0CBB-4554-BD41-01F2D8F5FC11','86E44060-B546-4A65-9464-9C4F78C1681E',
        'A80549F3-E47F-44C1-8037-F065522A03F6','1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB'
    )
   AND rcc.RCC_GLCode IN (
        'WAMP', 'WAMT', 'WIAP', 'WIAT', 'WAPP', 'WAPT', 'WESP', 'WESB'
    )
    AND rcc.RCC_Deleted = 0
	AND i.Insurer_Id IN (
        '2DED2E9F-7150-4F27-9E4D-72AD545D4A15', -- Centriq Life
		 '3DB4F358-243D-4965-BCC7-0D7B8BE23DCF', -- Hollard Life
		 '44109559-5BBA-473E-831E-E0D285884B6D', -- Centriq Short Term
		 '4D5B12F8-7BE8-4979-8DB0-11559E577A16'  -- Hollard Short Term
    )

--AND atn.ATN_AccountTransactionSet_ID = 'A5535510-AE78-46C3-B78A-E4912E41C0F0'
 
group by   EOMONTH(CASE 
        WHEN ats.ATS_CreateDate > ats.ATS_EffectiveDate THEN ats.ATS_CreateDate 
        ELSE ats.ATS_EffectiveDate 
    END),CASE 
        WHEN p.POL_SoldDate >= '2022-10-01' THEN 1 
        WHEN p.POL_SoldDate < '2022-10-01' THEN 0 
        ELSE NULL 
    END