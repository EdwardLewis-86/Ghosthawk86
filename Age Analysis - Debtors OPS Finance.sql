/* Debtors Age Analysis */

Declare @AsAtDate DATETIME = GETDATE()
--SET @AsAtDate = DATEADD(second, -1, DATEADD(Day, 1, ('31 May 2024 00:00:00')))
{ToDate}

SELECT 
	   Insurer,
	   'Client' [Party type],
	      [Policy_Number],
       POS_Description [Policy status ],
       (select RTF_Description from ReferenceTermFrequency where TermFrequency_id = POL_ProductTerm_ID) [Payment Frequency],
      prd_name PRODUCT_DESCRIPTION,
	          RPM_Description [Payment Method],

ARG_ArrangementNumber As [Arrangement Number],
			PrimaryAgents.Agt_Name  As [Primary Agent Name],
			PrimaryAgents.Agt_AgentNumber  As [Primary Agent Code],
			SubAgents.Agt_Name As [Sub Agent Name],
			SubAgents.Agt_AgentNumber As [Sub Agent Code],


       RCC_GLCode CELL_CAPTIVE_DESC,
       [Party Number] AS [Account Number],
       [Party Name],

       SUM(summation.[Current]) AS [Current],
       SUM(summation.[30 Days]) AS [30 Days],
       SUM(summation.[60 Days]) AS [60 Days],
       SUM(summation.[90 Days]) AS [90 Days],
       SUM(summation.[120 Days]) AS [120 Days],
       SUM(summation.[150 Days]) AS [150 Days],
       SUM(summation.[180 Days]) AS [180 Days],
       SUM(summation.[210 Days]) AS [210 Days],
       SUM(summation.[240 Days]) AS [240 Days],
       SUM(summation.[270 Days]) AS [270 Days],
       SUM(summation.[300 Days]) AS [300 Days],
       SUM(summation.[330 Days]) AS [330 Days],
       SUM(summation.[360 Days]) AS [360 Days],
       SUM(summation.[2+ Years]) AS [2+ Years],
       SUM(Summation.[Current]+[30 Days]+[60 Days]+[90 Days]+[120 Days]+[150 Days]+
		[180 Days]+[210 Days]+[240 Days]+[270 Days]+[300 Days]+[330 Days]+[360 Days]+[2+ Years]) AS [Total OS]
	 
FROM
(
    SELECT 
		   "Insurer",

		   Policy_ID PolId,
           Policy_Number [Policy_Number],
		   APY_PartyNumber [Party Number],
           APY_Name [Party Name],

           CASE WHEN SourceTable.Datedif = 0 THEN SUM(atn) ELSE 0 END AS "Current",
           CASE WHEN SourceTable.Datedif = -1 THEN SUM(atn) ELSE 0 END AS "30 Days",
           CASE WHEN SourceTable.Datedif = -2 THEN SUM(atn) ELSE 0 END AS "60 Days",
           CASE WHEN SourceTable.Datedif = -3 THEN SUM(atn) ELSE 0 END AS "90 Days",
           CASE WHEN SourceTable.Datedif = -4 THEN SUM(atn) ELSE 0 END AS "120 Days",
           CASE WHEN SourceTable.Datedif = -5 THEN SUM(atn) ELSE 0 END AS "150 Days",
           CASE WHEN SourceTable.Datedif = -6 THEN SUM(atn) ELSE 0 END AS "180 Days",
           CASE WHEN SourceTable.Datedif = -7 THEN SUM(atn) ELSE 0 END AS "210 Days",
           CASE WHEN SourceTable.Datedif = -8 THEN SUM(atn) ELSE 0 END AS "240 Days",
           CASE WHEN SourceTable.Datedif = -9 THEN SUM(atn) ELSE 0 END AS "270 Days",
           CASE WHEN SourceTable.Datedif = -10 THEN SUM(atn) ELSE 0 END AS "300 Days",
           CASE WHEN SourceTable.Datedif = -11 THEN SUM(atn) ELSE 0 END AS "330 Days",
           CASE WHEN SourceTable.Datedif = -12 THEN SUM(atn) ELSE 0 END AS "360 Days",
           CASE WHEN SourceTable.Datedif < -12 THEN SUM(atn) ELSE 0 END AS "2+ Years",
           SUM(atn) total 
    FROM

(SELECT (Select Distinct INS_InsurerName [Insurer] From Insurer where Insurer_Id = mainset.ATS_Insurer_Id) As "Insurer",

           Policy_ID,
           POL_POLICYNUMBER+IIF(POL_Deleted <> 0, ' (Deleted)', '')  [Policy_Number],
		   APY_PartyNumber,
           APY_Name,
           AccountParty_id,
		   atn_grossamount,

		   --(IIF(IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate) <= @AsAtDate, DATEDIFF(MONTH,ATS_CreateDate, ATS_EffectiveDate), +1)) [Datedif], 

			DATEDIFF(MONTH,@AsAtDate,ATS_EffectiveDate) AS Datedif,
		    --DATEDIFF(MONTH,@AsAtDate,(IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate) )) as [Datedif],
         
		
           SUM(atn_grossamount) atn

    FROM AccountTransactionSet(nolock) mainset
	    INNER JOIN policy ON ATS_DisplayNumber = replace(POL_PolicyNumber, 'x', '')
        left join PolicyInsurerLink on policy_id = PIL_Policy_ID and PIL_Deleted=0
         LEFT JOIN Insurer ON pil_Insurer_Id = Insurer_Id
          LEFT JOIN Product pro ON(pro.Product_Id = mainset.ATS_Product_Id)
		LEFT JOIN ReferenceProductGroup rpg ON(rpg.ProductGroup_ID = pro.PRD_ProductGroup_Id)
		inner join Agent PrimaryAgents(nolock) on POL_PrimaryAgent_ID = Agent_Id
    --left join SystemUsers CreateUser(nolock) on Users_ID = POL_CreateUser_ID
    --left join SystemUsers UpdateUser(nolock) on UpdateUser.Users_ID = POL_UpdateUser_ID
    Left join Agent SubAgents(nolock) on POL_Agent_ID = SubAgents.Agent_Id
	    left join arrangement(nolock) on POL_Arrangement_ID = Arrangement_Id 
		 left join InsurerGroupLink  on IGL_Insurer_Id = ATS_Insurer_Id,
         AccountTransaction(nolock),
         AccountParty

    WHERE ATN_AccountTransactionSet_ID = AccountTransactionSet_ID
          AND atn_AccountParty_id = AccountParty_id
        AND isnull(ATN_AccountMatch_ID, '') = ''
          AND EXISTS (SELECT 1 FROM AccountPartyType   WHERE APT_Description = 'Client' AND APY_PartyType_ID = AccountPartyType_Id)
         AND ATN_DisbursementType_ID IS NOT NULL
        --AND isnull(ATN_DisbursementType_ID, '') <> ''

		 --and POL_POLICYNUMBER In  ('QCLL000461POL','QCLL000383POL','QADC000002POL','QWTYM305969POL')


		--AND IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) < @AsAtDate
          --AND ATS_CreateDate <= @AsAtDate

		 AND IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) <= @AsAtDate -- As Per Rodger Bryant email subject (Evolve Recon - 8 April) 11-04-2024 Request : MSU023130
          --AND ATS_CreateDate <= @AsAtDate
		--and (ATS_EffectiveDate <= @AsAtDate OR CAST(@AsAtDate as date) =   CAST(@AsAtDate as date))

		  --and IGL_InsurerGroup_Id = '147A309F-80CB-4D24-93E2-07E2A82D2012'
		  --and Insurer_Id = '2DED2E9F-7150-4F27-9E4D-72AD545D4A15'
		  --and Insurer_Id = '0F2B8071-42D3-4150-A25E-F58576321AF3' -- Old Mutual
		  --and Insurer_Id = '28BEBA82-5AD3-49A7-A9F0-714542B6B2A8'  -- Santam
		  --and Insurer_Id = '44109559-5BBA-473E-831E-E0D285884B6D'  -- Centriq ST
		  --and Insurer_Id = '4D5B12F8-7BE8-4979-8DB0-11559E577A16' -- Hollard ST

		    	{Insurer}
		  --{ProductCategoryGroup}

	  
    GROUP BY APY_PartyNumber,
             AccountParty_id,
			 atn_grossamount,
			 prd_name,
			 Policy_ID,
			 POL_PolicyNumber,
			 POL_Deleted,
             APY_Name,
			 ATS_CreateDate,
             ats_effectivedate,
			 ATS_Insurer_Id
) AS SourceTable
    GROUP BY SourceTable.Datedif,
             AccountParty_id,
			 Policy_ID,
			 Policy_Number,
             APY_PartyNumber,
             APY_Name, 
			 Insurer
) AS summation
inner join policy on policy_id = PolId
	 left join ReferencePolicyStatus on PolicyStatus_ID = POL_Status
		 left join ReferencePaymentMethod on ReferencePaymentMethod_ID = POL_PaymentMethod_ID
	     LEFT JOIN vw_PolicySetDetails vw_psd ON policyid = policy_id
         LEFT JOIN product ON POL_Product_ID = Product_Id
         LEFT JOIN ReferenceCellCaptive ON CellCaptiveId = ReferenceCellCaptive_Code
         LEFT JOIN SalesBranch Br ON(vw_psd.Division = br.SalesRegion_ID)
         LEFT JOIN SalesBranch div ON(SalesBranch = div.SalesRegion_ID)  
		   inner join Agent PrimaryAgents(nolock) on POL_PrimaryAgent_ID = Agent_Id
    Left join Agent SubAgents(nolock) on POL_Agent_ID = SubAgents.Agent_Id
	    left join arrangement(nolock) on POL_Arrangement_ID = Arrangement_Id  

GROUP BY 
		Insurer,
		Policy_Number,
		POS_Description,
		POL_ProductTerm_ID,
		RPM_Description,
		ARG_ArrangementNumber,
		PrimaryAgents.Agt_Name  ,
			PrimaryAgents.Agt_AgentNumber ,
			SubAgents.Agt_Name ,
			SubAgents.Agt_AgentNumber,
			ReferenceCellCaptive.RCC_GLCode,
		prd_name,
		summation.[Party Name],
        summation.[Party Number]

ORDER BY summation.[Party Name]