/* Agent Age Analysis WARR*/

DECLARE @AsAtDate DateTime = GETDATE()
{ToDate}

BEGIN /* #tmp_SourceTable */
	IF OBJECT_ID('tempdb..#tmp_SourceTable') IS NOT NULL
	    BEGIN
	        DROP TABLE #tmp_SourceTable;
	    END;
SELECT 
	(
		SELECT DISTINCT INS_InsurerName [Insurer]
		FROM Insurer
		WHERE Insurer_Id = mainset.ATS_Insurer_Id	
	) [Insurer], 	
	Agt_FullName,
	APY_PartyNumber,
	AccountParty_id,
	ISNULL([SB].SRN_Text, '') SALES_BRANCH,
	ISNULL([DIV].SRN_Text, '') DIVISION,
	(
		SELECT ATY_Description
		FROM ReferenceAgentRevenueType
		WHERE ReferenceAgentRevenueType_ID = Agt_RevenueType
	) [AGENT_TYPE],
	PRD_Name,
	PDG_Description,
	APY_Name,
	DATEDIFF(MONTH, @AsAtDate, CAST(DATEADD(DAY, -DATEPART(DAY, ATS_EffectiveDate) + 1, ATS_EffectiveDate) AS DATE)) [Datedif],
	SUM(ATN_GrossAmount) [atn],	
	ATS_CreateDate [PostingDate]

	INTO #tmp_SourceTable

    FROM AccountTransactionSet(nolock) mainset
		LEFT JOIN SalesBranch [Div] ON ([Div].SRN_Deleted = 0 AND [Div].SalesRegion_ID = [mainset].ATS_Division)
		LEFT JOIN SalesBranch [SB] ON ([SB].SRN_Deleted = 0 AND [SB].SalesRegion_ID = [mainset].ATS_SalesBranch)
		LEFT JOIN Product pro ON(pro.Product_Id = mainset.ATS_Product_Id)
		LEFT JOIN ReferenceProductGroup rpg ON(rpg.ProductGroup_ID = pro.PRD_ProductGroup_Id)
		LEFT JOIN InsurerGroupLink  ON IGL_Insurer_Id = ATS_Insurer_Id,
         AccountTransaction(nolock),
         AccountParty,
         dbo.Agent a
         
		 --LEFT JOIN AgentDivisionLink adl ON(adl.ADL_Agent_ID = a.Agent_Id)
         --LEFT JOIN SalesBranch Br ON(Adl.ADL_Division_ID = br.SalesRegion_ID)
         --LEFT JOIN SalesBranch div ON(br.SRN_Parent_ID = div.SalesRegion_ID)

    WHERE ATN_AccountTransactionSet_ID = AccountTransactionSet_ID
		AND atn_AccountParty_id = AccountParty_id
		--AND isnull(ATN_AccountMatch_ID, '') = ''
		AND APY_PartyType_ID = 501
		AND APY_ItemReferenceNumber = a.Agent_Id
		--AND Agt_FullName <> ''
		--AND ATN_DisbursementType_ID IS NOT NULL
		--AND isnull(ATN_DisbursementType_ID, '') <> ''
		AND a.Agt_Deleted = 0
		AND ATS_Insurer_Id NOT IN (
			'2DED2E9F-7150-4F27-9E4D-72AD545D4A15',
			'3DB4F358-243D-4965-BCC7-0D7B8BE23DCF',
			'44109559-5BBA-473E-831E-E0D285884B6D',
			'4D5B12F8-7BE8-4979-8DB0-11559E577A16'
		)
		AND ATS_CreateDate <= @AsAtDate
		
		/*Parameters*/
		{InsurerGroup}
		{ProductCategoryGroup}
		/*Parameters*/

--AND ATN_AccountMatch_ID NOT IN (SELECT AccountMatchSet_Id FROM AccountMatchSet  WHERE AMS_CreateDate <= @AsAtDate)
	
    GROUP BY
		Agt_FullName,
		APY_PartyNumber,
		AccountParty_id,
		PRD_Name,
		PDG_Description,
		APY_Name,
		Agt_RevenueType,
		ATS_EffectiveDate,
		[SB].SRN_Text,
		[DIV].SRN_Text,
		ATS_Insurer_Id,
		ATS_CreateDate
	;
END

BEGIN /* #tmp_Summation */
	IF OBJECT_ID('tempdb..#tmp_Summation') IS NOT NULL
	    BEGIN
	        DROP TABLE #tmp_Summation;
	    END;
 SELECT
	
	[Insurer],
	PRD_Name,
	PDG_Description,
	APY_PartyNumber [Party Number],
	APY_Name [Party Name],
	Agt_FullName [agent],
	AGENT_TYPE,
	(
		SELECT TOP 1 SALES_BRANCH
		FROM #tmp_SourceTable SelfJoin_Summation
		WHERE SelfJoin_Summation.APY_PartyNumber = #tmp_SourceTable.APY_PartyNumber
		ORDER BY #tmp_SourceTable.PostingDate DESC
	) SALES_BRANCH,
	DIVISION,
	#tmp_SourceTable.Datedif,
	(
		SELECT isnull(SUM(atn_grossamount), 0)
		FROM AccountTransaction ACN
		WHERE ACN.atn_AccountParty_id = AccountParty_id
			AND atn_grossamount > 0
			AND ACN.ATN_AccountMatch_ID = ''
			AND EXISTS
				(
				    SELECT 1
				    FROM dbo.AccountTransactionSet ats
				    WHERE ACN.ATN_AccountTransactionSet_ID = AccountTransactionSet_ID
				          AND ATS_Insurer_Id NOT IN (
							'2DED2E9F-7150-4F27-9E4D-72AD545D4A15',
							'3DB4F358-243D-4965-BCC7-0D7B8BE23DCF',
							'44109559-5BBA-473E-831E-E0D285884B6D',
							'4D5B12F8-7BE8-4979-8DB0-11559E577A16'
						  )
				)
	) AS TOTALDEBITS,
	(
		SELECT isnull(SUM(atn_grossamount), 0)
		FROM AccountTransaction ACN
		WHERE ACN.atn_AccountParty_id = AccountParty_id
			AND atn_grossamount < 0
			AND ACN.ATN_AccountMatch_ID = ''
			AND EXISTS
				(
					SELECT 1
					FROM dbo.AccountTransactionSet ats
					WHERE ACN.ATN_AccountTransactionSet_ID = ats.AccountTransactionSet_ID
						AND ats.ATS_Insurer_Id NOT IN (
							'2DED2E9F-7150-4F27-9E4D-72AD545D4A15',
							'3DB4F358-243D-4965-BCC7-0D7B8BE23DCF',
							'44109559-5BBA-473E-831E-E0D285884B6D',
							'4D5B12F8-7BE8-4979-8DB0-11559E577A16'
						)
				)
	) AS TOTALCREDITS,
	--CASE WHEN #tmp_SourceTable.Datedif > 0 THEN SUM(atn) ELSE 0 END [Future],
	CASE WHEN #tmp_SourceTable.Datedif = 0 THEN SUM(atn) ELSE 0 END [Current],
	CASE WHEN #tmp_SourceTable.Datedif = -1 THEN SUM(atn) ELSE 0 END [30 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -2 THEN SUM(atn) ELSE 0 END [60 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -3 THEN SUM(atn) ELSE 0 END [90 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -4 THEN SUM(atn) ELSE 0 END [120 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -5 THEN SUM(atn) ELSE 0 END [150 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -6 THEN SUM(atn) ELSE 0 END [180 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -7 THEN SUM(atn) ELSE 0 END [210 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -8 THEN SUM(atn) ELSE 0 END [240 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -9 THEN SUM(atn) ELSE 0 END [270 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -10 THEN SUM(atn) ELSE 0 END [300 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -11 THEN SUM(atn) ELSE 0 END [330 Days],
	CASE WHEN #tmp_SourceTable.Datedif = -12 THEN SUM(atn) ELSE 0 END [360 Days],
	CASE WHEN #tmp_SourceTable.Datedif < -12 THEN SUM(atn) ELSE 0 END [2+ Years],
	SUM(atn) total
	--[PostingDate]

INTO #tmp_Summation

    FROM #tmp_SourceTable

    GROUP BY
		Agt_FullName,
		#tmp_SourceTable.Datedif,
		APY_PartyNumber,
		AccountParty_id,
		PRD_Name,
		PDG_Description,
		APY_Name,
		AGENT_TYPE,
		SALES_BRANCH,
		DIVISION,
		Insurer,			 
		[PostingDate]
	;
END

BEGIN /* Result */
	SELECT 
		Insurer, 
		'Agent' [Party type],
		REPLACE(
			(
				SELECT DISTINCT (
					STUFF (
						(
							SELECT DISTINCT '; ' + CAST(PRD_Name AS VARCHAR(MAX))
							FROM #tmp_SourceTable SelfJoin_Summation
							WHERE SelfJoin_Summation.APY_PartyNumber = #tmp_Summation.[Party Number]
							FOR XML PATH ('')
						), 1, 1, ''
					)
				) 
			) , 
				'&amp;', '&'
		) [Product],
		PDG_Description [Product Category Group],
		[Party Number] [Account Number],
		[Party Name],
		DIVISION,
		SALES_BRANCH,
		AGENT_TYPE,
		--#tmp_Summation.TOTALDEBITS [Total Debits],
		--#tmp_Summation.TOTALCREDITS [Total Credits],
		--SUM(#tmp_Summation.Future) [Future Dated],
		SUM(#tmp_Summation.[Current]) [Current],
		SUM(#tmp_Summation.[30 Days]) [30 Days],
		SUM(#tmp_Summation.[60 Days]) [60 Days],
		SUM(#tmp_Summation.[90 Days]) [90 Days],
		SUM(#tmp_Summation.[120 Days]) [120 Days],
		SUM(#tmp_Summation.[150 Days]) [150 Days],
		SUM(#tmp_Summation.[180 Days]) [180 Days],
		SUM(#tmp_Summation.[210 Days]) [210 Days],
		SUM(#tmp_Summation.[240 Days]) [240 Days],
		SUM(#tmp_Summation.[270 Days]) [270 Days],
		SUM(#tmp_Summation.[300 Days]) [300 Days],
		SUM(#tmp_Summation.[330 Days]) [330 Days],
		SUM(#tmp_Summation.[360 Days]) [360 Days],
		SUM(#tmp_Summation.[2+ Years]) [2+ Years],
		SUM(#tmp_Summation.[Current]+[30 Days]+[60 Days]+[90 Days]+[120 Days]+[150 Days]+
		[180 Days]+[210 Days]+[240 Days]+[270 Days]+[300 Days]+[330 Days]+[360 Days]+[2+ Years]) AS [Total OS]
		--GETDATE() [Report Run date]	    
	
	FROM #tmp_Summation
	
	GROUP BY
		Insurer, 
		PDG_Description,
		#tmp_Summation.agent,
		#tmp_Summation.[Party Name],
		#tmp_Summation.[Party Number],
		AGENT_TYPE,
		SALES_BRANCH,
		DIVISION
		--#tmp_Summation.TOTALDEBITS,
		--#tmp_Summation.TOTALCREDITS
	
	ORDER BY 3
	;
END