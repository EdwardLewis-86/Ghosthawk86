Declare @AsAtDate DATETIME = GETDATE()
--SET @AsAtDate = DATEADD(second, -1, DATEADD(Day, 1, ('30 Apr 2024 00:00:00')))
{ToDate}

SELECT 
	   Insurer,
	   'Creditor' [Party type],
	  -- prd_name as [Product],
	   --pdg_description as [Product Category Group],
       [Party Number] AS [Account Number],
       [Party Name],
       --summation.TOTALDEBITS AS [Total Debits],
       --summation.TOTALCREDITS AS [Total Credits],
       --SUM(summation.Future) AS [Future Dated],
	   'Not Matched Transaction' as Matched_Status,
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
	      --  TOTALOS,
	      --    TOTALOS_EXCLUDE_FUTURE,
		  --[Current],
       --([30 DAYS] + [60 DAYS] + [90 DAYS] + [120 DAYS] + [150 DAYS]) +[180 Days],
       --([210 Days] + [240 Days] + [270 Days] + [300 Days]) +[330 Days],
       --([360 Days] + [2+ Years] AS [Total OS] ,

       --ISNULL(summation.TOTALDEBITS,0) + ISNULL(summation.TOTALCREDITS,0) AS [Total OS],
       --GETDATE()  [Report Run date]	 
FROM
(
    SELECT 
		   "Insurer",
		   prd_name,
		   --pdg_description,
		   APY_PartyNumber [Party Number],
           APY_Name [Party Name],
--(
--    SELECT SUM(atn_grossamount)
--    FROM AccountTransaction ACN,AccountTransactionSet ACS
--    WHERE ACN.atn_AccountParty_id = AccountParty_id
--	      AND ACN.ATN_AccountTransactionSet_ID = ACS.AccountTransactionSet_Id
--          AND ACS.ATS_Insurer_Id = (Select insurer_ID from Insurer where INS_InsurerName = [Insurer])
--          AND atn_grossamount > 0
--) AS TOTALDEBITS,
--(
--    SELECT SUM(atn_grossamount)
--    FROM AccountTransaction ACN,AccountTransactionSet ACS
--    WHERE ACN.atn_AccountParty_id = AccountParty_id
--	      AND ACN.ATN_AccountTransactionSet_ID = ACS.AccountTransactionSet_Id
--          AND ACS.ATS_Insurer_Id = (Select insurer_ID from Insurer where INS_InsurerName = [Insurer])
--          AND atn_grossamount < 0
--) AS TOTALCREDITS,

           --CASE WHEN SourceTable.Datedif > 0 THEN SUM(atn) ELSE 0 END AS Future,
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

		   prd_name,
		   --pdg_description,
		   APY_PartyNumber,
           APY_Name,
           AccountParty_id,
		   atn_grossamount,

		   --(IIF(IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate) <= @AsAtDate, DATEDIFF(MONTH,ATS_CreateDate, ATS_EffectiveDate), +1)) [Datedif], 

			DATEDIFF(MONTH,@AsAtDate,ATS_EffectiveDate) AS Datedif,
		    --DATEDIFF(MONTH,@AsAtDate,(IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate) )) as [Datedif],
         
		
           SUM(atn_grossamount) atn

    FROM AccountTransactionSet(nolock) mainset
	--Left join AccountTransaction on ATN_AccountTransactionSet_ID = AccountTransactionSet_Id
	--Left join AccountMatchSet on AccountMatchSet_Id = AccountTransactionSet_Id
		 left join Product pro ON(pro.Product_Id = mainset.ATS_Product_Id)
		 left join ReferenceProductGroup rpg ON(rpg.ProductGroup_ID = pro.PRD_ProductGroup_Id)
		 left join InsurerGroupLink  on IGL_Insurer_Id = ATS_Insurer_Id,
         AccountTransaction(nolock),
         AccountParty

    WHERE ATN_AccountTransactionSet_ID = AccountTransactionSet_ID
          AND atn_AccountParty_id = AccountParty_id
        AND isnull(ATN_AccountMatch_ID, '') = ''
          AND EXISTS (SELECT 1 FROM AccountPartyType   WHERE APT_Description = 'Creditor' AND APY_PartyType_ID = AccountPartyType_Id)
         AND ATN_DisbursementType_ID IS NOT NULL
        --AND isnull(ATN_DisbursementType_ID, '') <> ''
		--and APY_PartyNumber = '19226855'
		 --and AMS_CreateDate <= @AsAtDate


		--AND IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) < @AsAtDate
          --AND ATS_CreateDate <= @AsAtDate

		 AND IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) <= @AsAtDate -- As Per Rodger Bryant email subject (Evolve Recon - 8 April) 11-04-2024 Request : MSU023130
          --AND ATS_CreateDate <= @AsAtDate
		--and (ATS_EffectiveDate <= @AsAtDate OR CAST(@AsAtDate as date) =   CAST(@AsAtDate as date))

		  --and IGL_InsurerGroup_Id = '147A309F-80CB-4D24-93E2-07E2A82D2012'
		    {InsurerGroup}
		  {ProductCategoryGroup}

	  
    GROUP BY APY_PartyNumber,
             AccountParty_id,
			 atn_grossamount,
			 prd_name,
			 --pdg_description,
             APY_Name,
			 ATS_CreateDate,
             ats_effectivedate,
			 ATS_Insurer_Id
) AS SourceTable
    GROUP BY SourceTable.Datedif,
             AccountParty_id,
			 prd_name,
			 --pdg_description,
             APY_PartyNumber,
             APY_Name, 
			 Insurer
) AS summation

GROUP BY 
		Insurer,
		--prd_name,
		--pdg_description,
		summation.[Party Name],
        summation.[Party Number]
	    --summation.TOTALDEBITS ,
	    --summation.TOTALCREDITS
--ORDER BY summation.[Party Name]

--Declare @AsAtDate DATETIME = GETDATE()

--SET @AsAtDate = DATEADD(second, -1, DATEADD(Day, 1, ('30 Apr 2024 00:00:00')))
Union all
SELECT 
	   Insurer,
	   'Creditor' [Party type],
	  -- prd_name as [Product],
	   --pdg_description as [Product Category Group],
       [Party Number] AS [Account Number],
       [Party Name],
       --summation.TOTALDEBITS AS [Total Debits],
       --summation.TOTALCREDITS AS [Total Credits],
       --SUM(summation.Future) AS [Future Dated],
	   'Matched Transaction' as Matched_Status,
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
	      --  TOTALOS,
	      --    TOTALOS_EXCLUDE_FUTURE,
		  --[Current],
       --([30 DAYS] + [60 DAYS] + [90 DAYS] + [120 DAYS] + [150 DAYS]) +[180 Days],
       --([210 Days] + [240 Days] + [270 Days] + [300 Days]) +[330 Days],
       --([360 Days] + [2+ Years] AS [Total OS] ,

       --ISNULL(summation.TOTALDEBITS,0) + ISNULL(summation.TOTALCREDITS,0) AS [Total OS],
       --GETDATE()  [Report Run date]	 
FROM
(
    SELECT 
		   "Insurer",
		   prd_name,
		   --pdg_description,
		   APY_PartyNumber [Party Number],
           APY_Name [Party Name],
--(
--    SELECT SUM(atn_grossamount)
--    FROM AccountTransaction ACN,AccountTransactionSet ACS
--    WHERE ACN.atn_AccountParty_id = AccountParty_id
--	      AND ACN.ATN_AccountTransactionSet_ID = ACS.AccountTransactionSet_Id
--          AND ACS.ATS_Insurer_Id = (Select insurer_ID from Insurer where INS_InsurerName = [Insurer])
--          AND atn_grossamount > 0
--) AS TOTALDEBITS,
--(
--    SELECT SUM(atn_grossamount)
--    FROM AccountTransaction ACN,AccountTransactionSet ACS
--    WHERE ACN.atn_AccountParty_id = AccountParty_id
--	      AND ACN.ATN_AccountTransactionSet_ID = ACS.AccountTransactionSet_Id
--          AND ACS.ATS_Insurer_Id = (Select insurer_ID from Insurer where INS_InsurerName = [Insurer])
--          AND atn_grossamount < 0
--) AS TOTALCREDITS,

           --CASE WHEN SourceTable.Datedif > 0 THEN SUM(atn) ELSE 0 END AS Future,
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

		   prd_name,
		   --pdg_description,
		   APY_PartyNumber,
           APY_Name,
           AccountParty_id,
		   atn_grossamount,

		   --(IIF(IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate) <= @AsAtDate, DATEDIFF(MONTH,ATS_CreateDate, ATS_EffectiveDate), +1)) [Datedif], 

			DATEDIFF(MONTH,@AsAtDate,ATS_EffectiveDate) AS Datedif,
		    --DATEDIFF(MONTH,@AsAtDate,(IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate) )) as [Datedif],
         
		
           SUM(atn_grossamount) atn

    FROM AccountTransactionSet(nolock) mainset
	--Left join AccountTransaction on ATN_AccountTransactionSet_ID = AccountTransactionSet_Id
	--Left join AccountMatchSet on AccountMatchSet_Id = AccountTransactionSet_Id
		 left join Product pro ON(pro.Product_Id = mainset.ATS_Product_Id)
		 left join ReferenceProductGroup rpg ON(rpg.ProductGroup_ID = pro.PRD_ProductGroup_Id)
		 left join InsurerGroupLink  on IGL_Insurer_Id = ATS_Insurer_Id,
         AccountTransaction(nolock),
         AccountParty

    WHERE ATN_AccountTransactionSet_ID = AccountTransactionSet_ID
          AND atn_AccountParty_id = AccountParty_id
        AND isnull(ATN_AccountMatch_ID, '') <> ''
          AND EXISTS (SELECT 1 FROM AccountPartyType   WHERE APT_Description = 'Creditor' AND APY_PartyType_ID = AccountPartyType_Id)
         AND ATN_DisbursementType_ID IS NOT NULL
        --AND isnull(ATN_DisbursementType_ID, '') <> ''
		--and APY_PartyNumber = '19226855'
		 --and AMS_CreateDate <= @AsAtDate


		--AND IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) < @AsAtDate
          --AND ATS_CreateDate <= @AsAtDate

		 AND IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) <= @AsAtDate -- As Per Rodger Bryant email subject (Evolve Recon - 8 April) 11-04-2024 Request : MSU023130
          --AND ATS_CreateDate <= @AsAtDate
		--and (ATS_EffectiveDate <= @AsAtDate OR CAST(@AsAtDate as date) =   CAST(@AsAtDate as date))

		  --and IGL_InsurerGroup_Id = '147A309F-80CB-4D24-93E2-07E2A82D2012'

		    {InsurerGroup}
		  {ProductCategoryGroup}
		    
    GROUP BY APY_PartyNumber,
             AccountParty_id,
			 atn_grossamount,
			 prd_name,
			 --pdg_description,
             APY_Name,
			 ATS_CreateDate,
             ats_effectivedate,
			 ATS_Insurer_Id
) AS SourceTable
    GROUP BY SourceTable.Datedif,
             AccountParty_id,
			 prd_name,
			 --pdg_description,
             APY_PartyNumber,
             APY_Name, 
			 Insurer
) AS summation

GROUP BY 
		Insurer,
		--prd_name,
		--pdg_description,
		summation.[Party Name],
        summation.[Party Number]
	    --summation.TOTALDEBITS ,
	    --summation.TOTALCREDITS
ORDER BY summation.[Party Name]