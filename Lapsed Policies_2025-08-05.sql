/*
Lapsed Policies
RMFACC_FR00011
MSU016323
*/

SELECT * FROM
(
SELECT distinct
    INS_InsurerName [Insurer],
	ISNULL([Div].SRN_Text,'') [Division],
	IIF(INS_InsurerName LIKE '%Life%', 'Life', 'Short Term') [Company],
	pol_policynumber [Policy No],
	RNR_NUMBER [Agent Policy No],
	IIF(
		POL_PaymentMethod_ID != 3, /*NO EDI Receipt on D/O policy*/
			(SELECT TOP 1 RNR_Number FROM ReferenceNumber WHERE RNR_NumberType_Id = 146 AND RNR_ItemReferenceNumber = Policy_ID),
			''
	) [Bank Product Code],
	POL_FinanceNumber [Primary Finance Number],
	prd_name [Product Name],
	RTF_Description [Policy Frequency],
	ISNULL([SB].SRN_Text,'') [Sales Branch],
	PrimaryAgent.Agt_AgentNumber [Primary Agent No],
	PrimaryAgent.Agt_Name [Primary Agent Name],
	SubAgent.Agt_AgentNumber [Sub Agent No],
	SubAgent.Agt_Name [Sub Agent Name],
	CLI_ClientNumber [Client Number],
	
	/*FDS: If the bank account holder is blank, returns the client’s full name, else returns the bank account holder*/
	IIF(ISNULL(BNK.AccountHolder, '') = '', CONCAT(CLI_Name, ' ', CLI_Surname), AccountHolder) [Policy Holder Name],
	
	IIF(CLI_IDType_ID = 1, CLI_MaskedIDNumber, CLI_MaskedPassportNumber)  As [Client ID No],
	RPM_Description [Payment Method],
	(SELECT CONCAT(USR_FirstName, ' ', USR_Surname) FROM SystemUsers WHERE Users_ID = (SELECT EVL_User_ID FROM EventLog WHERE EventLog_ID = [EventLogID])) [Cancellation User],
	[Cancellation Reason], 
	CASE WHEN [Cancellation Reason] = 'Reason: Cancelled - 2 Consecutive unmets' THEN
	(
		/*Unmets Logic*/
	    SELECT 
			SUM(ATN_GrossAmount)
	    FROM 
			AccountTransactionSet, AccountTransaction    
			INNER JOIN DisbursementType ON (
			       AccountTransaction.ATN_DisbursementType_ID = DisbursementType.DisbursementType_Id
			       AND DisbursementType_Id NOT IN (
			             'BC798944-95AC-4713-9BEA-677487D447E4',         /*Nett Off Broker Fee*/
			             'C5060500-A5DB-46FA-A36F-8D639E0190B6',         /*Nett Off Commission*/
			             '1DB8500A-EEF3-4B13-BB69-E436331969C9',         /*Nett Off Inspection Fee*/
			             'F90FED30-0FE1-4371-8C03-DD5B31C97D74',         /*Nett Off Insurer Fee*/
			             'D861E9ED-E12D-4762-B5B5-272B4B5234C6',         /*Nett Off Paint tech Admin Fee*/
			             'A89D6B90-6E79-418D-8076-09A6946C805F'          /*Nett Off Paint tech Fee*/
			       )
			)
			INNER JOIN AccountParty ON (
				AccountParty_Id = ATN_AccountParty_ID 
				AND APY_PartyType_ID = 1 /*Client*/
			)			

	    WHERE 
			(ATS_ReferenceNumber = Policy_ID OR ATS_DisplayNumber = POL_PolicyNumber)     
			AND ATN_AccountParty_ID = (SELECT AccountParty_Id FROM AccountParty WHERE APY_ItemReferenceNumber = POL_Client_ID)		
			AND ISNULL(ATS_ReversalOfSet_ID, '') != ''
			AND AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
			/*AND AccountPartyTypeId = 500*/
			AND EOMONTH(ATS_CreateDate) =
			(
				SELECT EOMONTH(MAX(ATS_CreateDate)) 
				FROM AccountTransactionSet 
				WHERE 
					ATS_DisplayNumber = POL_PolicyNumber
					AND ATS_AccountTransactionType_ID IN (
					'3E78BCD7-F3A6-4E35-9803-48AE8431DF59' /*Raise*/,
					'67D7E1A2-471F-4CC4-9886-3C392BEEE2A7' /*Unmet*/
					)
					AND ISNULL(ATS_ReversalOfSet_ID, '') != ''
			)
			AND FORMAT(CancelEvent.[Cancellation Date], 'yyyyMMdd') = FORMAT(ATS_CreateDate, 'yyyyMMdd')

     ) ELSE
	 (
		/*Lapsing Logic*/
	    SELECT 
			- SUM(ATN_GrossAmount)
	    FROM 
			AccountTransactionSet, AccountTransaction    
			INNER JOIN DisbursementType ON (
			       AccountTransaction.ATN_DisbursementType_ID = DisbursementType.DisbursementType_Id
			       AND DisbursementType_Id NOT IN (
			             'BC798944-95AC-4713-9BEA-677487D447E4',         /*Nett Off Broker Fee*/
			             'C5060500-A5DB-46FA-A36F-8D639E0190B6',         /*Nett Off Commission*/
			             '1DB8500A-EEF3-4B13-BB69-E436331969C9',         /*Nett Off Inspection Fee*/
			             'F90FED30-0FE1-4371-8C03-DD5B31C97D74',         /*Nett Off Insurer Fee*/
			             'D861E9ED-E12D-4762-B5B5-272B4B5234C6',         /*Nett Off Paint tech Admin Fee*/
			             'A89D6B90-6E79-418D-8076-09A6946C805F'          /*Nett Off Paint tech Fee*/
			       )
			)
			INNER JOIN AccountParty ON (
				AccountParty_Id = ATN_AccountParty_ID 
				AND APY_PartyType_ID = 1 /*Client*/
			)			

	    WHERE 
			(ATS_ReferenceNumber = Policy_ID OR ATS_DisplayNumber = POL_PolicyNumber)     
			AND ATN_AccountParty_ID = (SELECT AccountParty_Id FROM AccountParty WHERE APY_ItemReferenceNumber = POL_Client_ID)
			AND ISNULL(ATS_ReversalOfSet_ID, '') != ''
			AND AccountTransactionSet_Id = ATN_AccountTransactionSet_ID	
			/*AND AccountPartyTypeId = 500*/
			AND EOMONTH(ATS_CreateDate) =
			(
				SELECT EOMONTH(MAX(ATS_CreateDate)) 
				FROM AccountTransactionSet 
				WHERE 
					ATS_DisplayNumber = POL_PolicyNumber
					AND ATS_AccountTransactionType_ID IN (
					'3E78BCD7-F3A6-4E35-9803-48AE8431DF59' /*Raise*/,
					'67D7E1A2-471F-4CC4-9886-3C392BEEE2A7' /*Unmet*/
					)
					AND ISNULL(ATS_ReversalOfSet_ID, '') != ''
			)
			AND FORMAT(CancelEvent.[Cancellation Date], 'yyyyMMdd') = FORMAT(ATS_CreateDate, 'yyyyMMdd')
	)
	END [Value of Reversals],  
	Format(POL_StartDate,'dd/MM/yyyy') [Cover Start Date],
	Format([Cancellation Date], 'dd/MM/yyyy') AS [Posting Date of Cancellation],
	Format(POL_EndDate,'dd/MM/yyyy') [Effective Date of Cancellation],
	Format(POL_FirstPaymentStart,'dd/MM/yyyy')  [First Payment Start Date],
	ISNULL(
			(
				SELECT TOP 1 FORMAT(ATS_EffectiveDate,'dd/MM/yyyy') 
				FROM 
					AccountTransactionSet, 
					AccountTransaction, 
					AccountParty
				WHERE 
					ATS_AccountTransactionType_ID IN (
						'2CF785C3-9056-4E9F-B0C9-835294A0D601', /*Edi Receipt*/
						'86C64389-50C3-437F-A4CE-FD443B7F90C5', /*Assume Payment*/
						'8F68D979-A643-4B06-9E91-B4D6D5891FFC', /*Receipt*/
						'C143BC57-3B66-44A7-80F9-1FF8D1AE8419'  /*Journal*/
					)
					AND AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
					AND ATN_AccountParty_ID = AccountParty_ID
					AND APY_PartyType_ID = 1
					AND ATS_DisplayNumber = POL_PolicyNumber
				ORDER BY ATS_EffectiveDate
			), ''
	) [First Payment Date],
	IIF(
		POL_PaymentMethod_ID = 6, /*BULKED*/
		RBI_Description,
		''
	) [Bulking Institution],
	(
		SELECT SUM(ITS_Premium) 
		FROM ItemSummary 
		WHERE ITS_Policy_ID = policy_id 
			AND ITS_Premium > 0
			AND ITS_Deleted = 0
	) [Policy Premium],
	ISNULL(
			(
				SELECT TOP 1 FORMAT(ATS_EffectiveDate,'dd/MM/yyyy') 
				FROM 
					AccountTransactionSet, 
					AccountTransaction, 
					AccountParty
				WHERE 
					ATS_AccountTransactionType_ID IN (
						'2CF785C3-9056-4E9F-B0C9-835294A0D601', /*Edi Receipt*/
						'86C64389-50C3-437F-A4CE-FD443B7F90C5', /*Assume Payment*/
						'8F68D979-A643-4B06-9E91-B4D6D5891FFC', /*Receipt*/
						'C143BC57-3B66-44A7-80F9-1FF8D1AE8419'  /*Journal*/
					)
					AND AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
					AND ATN_AccountParty_ID = AccountParty_ID
					AND APY_PartyType_ID = 1
					AND ATS_DisplayNumber = POL_PolicyNumber
				ORDER BY ATS_EffectiveDate DESC
			), ''
	) [Last Payment Date],
	ISNULL(ISNULL(PolicyIds.ConsecCount, POL_ConsecutiveUnmetCount), 0) [Bulk Consec Count],
	ISNULL(ISNULL(PolicyIds.IntermitCount, POL_LifetimeUnmetCount), 0) [Bulk Intermittend Count],
	ISNULL(PolicyIds.ACBCount, 0) [ACB Consec Count],
	RCM_Description [Preferred Method of Com],

	IIF(
		POL_Status = 1 /*IN FORCE*/
		AND PRD_ProductGroup_Id = 1, /*Warranties*/
			IIF(
				POL_StartDate > GETDATE(),
					'Future Active',
					dbo.fnc_PolicyPaymentStatus(Policy_ID)
				), ''
	) [Policy Sub Status]

FROM Policy
	 inner join Client on POL_Client_ID = Client_ID
	 inner join Agent PrimaryAgent on Agent_Id = POL_PrimaryAgent_ID
	 inner join Product on Product_Id = POL_Product_ID
	 inner join PolicyInsurerLink on PIL_Policy_ID = Policy_ID
	 inner join Insurer on PIL_Insurer_ID = Insurer_Id
	 inner join ReferencePolicyStatus on PolicyStatus_ID = POL_Status
	 inner join (
		SELECT 
			EVL_ReferenceNumber [Event Policy ID], 
			MAX(EventLog_ID) [EventLogID],
			MAX(EVL_DateTime) [Cancellation Date],
			CAST(ELD_Data AS varchar(100)) [Cancellation Reason]
		FROM EventLog,EventLogDetail 
		WHERE EventLog_ID = ELD_EventLog_ID 
			AND (
				ELD_Data like 'Reason: Cancelled - 2 Consecutive unmets' 
				or ELD_Data like 'Reason: Lapsed - No Premium Received'
			)
			AND  EVL_Event_ID = 10516

		GROUP BY EVL_ReferenceNumber, CAST(ELD_Data AS varchar(100))
	) CancelEvent ON [Event Policy ID] = Policy_ID

	 left join (
			SELECT 
				[PolicyID],
				SUM([Amount]) [Amount],
				ISNULL(SUM(IIF([Type] = 'Lapse', [IntermitCount], 0)), 0) [IntermitCount],
				ISNULL(SUM(IIF([Type] = 'Lapse', [ConsecCount], 0)), 0) [ConsecCount],
				ISNULL(SUM(IIF([Type] != 'Lapse', [IntermitCount], 0)), 0) [ACBCount]
			FROM (
				SELECT 
					APL_Policy_ID [PolicyID], 
					'Lapse' [Type], 
					APL_OutstandingTotal [Amount], 
					case when APL_LapseType = 'Intermittent' then APL_OutstandingNo else 0 end [IntermitCount], 
					case when APL_LapseType = 'Consecutive' then APL_OutstandingNo else 0 end [ConsecCount] 
				FROM AccountPolicyLapse 
				WHERE APL_DeletedInd = 0 
					AND APL_LapseInd = 1
			union 
				SELECT distinct 
					UNM_Policy_Id [PolicyID], 
					'Unmet' [Type], 
					SUM(UNM_Amount) [Amount], 
					Count(*) [IntermitCount], 
					ISNULL(POL_ConsecutiveUnmetCount + POL_TIAConsecutiveUnmetCount, 0) [ConsecCount]
				FROM PolicyUnmets 
					Left join Policy on Policy_ID = UNM_Policy_Id
				WHERE UNM_Deleted = 0
				AND UNM_Reason not like 'EDI Financial Rejections :%'
				group by UNM_Policy_Id, POL_ConsecutiveUnmetCount, POL_TIAConsecutiveUnmetCount
		) Sub
		group by [PolicyID]
	 ) PolicyIds on Policy_ID = PolicyIds.PolicyID AND PolicyIds.Amount > 0

	 left join Agent SubAgent on SubAgent.Agent_Id = POL_Agent_ID
	 LEFT JOIN (
		SELECT 
			[Reference Number],
			MAX([Request Date]) [Request Date],
			MAX([Dispatched Date]) [Dispatched Date],
			MAX([Request ID]) [Request ID]
		FROM vw_DMS_GetLetterSent LapseLetter
		WHERE LapseLetter.[Dispatch Type] <> 'SMS' 
			AND LapseLetter.[Category ID] = 185
		GROUP BY [Reference Number]
	 ) LapseLetter ON (LapseLetter.[Reference Number] = Policy_ID)
     left join ReferenceNumber on RNR_ItemReferenceNumber = policy_id AND RNR_ItemType_ID = 2 AND RNR_NumberType_ID = 122 AND RNR_Deleted = 0
	 LEFT JOIN vw_BankDetails BNK ON ReferenceNumber = Policy_ID AND BankDefault = 1 AND ItemType != -1
	 LEFT JOIN AccountParty ON client_id = APY_ItemReferenceNumber

	 LEFT JOIN AccountTransactionSet [ATS] ON ([ATS].ATS_ReferenceNumber = Policy_ID)
	 LEFT JOIN SalesBranch [Div] ON ([Div].SRN_Deleted = 0 AND [Div].SalesRegion_ID = [ATS].ATS_Division)
	 LEFT JOIN SalesBranch [SB] ON ([SB].SRN_Deleted = 0 AND [SB].SalesRegion_ID = [ATS].ATS_SalesBranch) 
	 
	 left join ReferencePreferredCommunicationMethod on CommunnicationMethod_ID = CLI_PreferredCommunication_ID
	 left join ReferenceBulkingInstitution on BulkingInstitution_ID = POL_BulkInstitution_ID
	 left join ReferencePaymentMethod on ReferencePaymentMethod_ID = POL_PaymentMethod_ID
	 left join ReferenceTermFrequency on TermFrequency_Id = POL_ProductTerm_ID

WHERE 
	POL_Deleted = 0 
	AND POL_PaymentMethod_ID IN ('6','9')
	
	/*PARAMETERS*/
	{FromSheduleDate}
	{FromDate}
	{ToDate}
	{InsurerType}
	{ProductGroup}
	
  ) E
  ORDER BY [Policy Holder Name]
