SELECT * FROM
(
	SELECT 
		INS_InsurerName As INSURER,
		(
			SELECT distinct top 1 RCC_Description 
			FROM ReferenceCellCaptive, vw_PolicySetDetails 
			WHERE CellCaptiveId = ReferenceCellCaptive_Code 
				AND policyid = Policy_ID
		)As "CELL CAPTIVE",
		
		(
			select top 1 ATS_Info3  
			from AccountTransactionSet
			where ATS_AccountTransactionType_ID in ('2CF785C3-9056-4E9F-B0C9-835294A0D601','77633D76-D04F-4313-89B3-8DEA37C72AA8')
				and ATS_DisplayNumber = POL_PolicyNumber
				and POL_Status = 3
			order by ATS_TransactionNumber desc
		) As "EDI PROD CODE",
		prd_name As "PRODUCT NAME",
		(
			SELECT distinct top 1 (SRN_text) 
			FROM SalesBranch, AgentDivisionLink 
			WHERE SalesRegion_ID = ADL_Division_ID 
		       AND ADL_Agent_ID = POL_AGent_ID
		       AND isnull(ADL_ToDate,'')= '' 
		       AND SRN_Deleted = 0
		) As REGION,
		(
			Select distinct top 1 (Agt_name) 
			from ArrangementAgents, agent
			Where ARA_PrimaryAgent_ID = agent_id and Agt_Deleted = 0 and ARA_Deleted = 0
				and ARA_Agent_ID  = POL_Agent_ID 
		) As "PRIMARY AGENT NAME",
		Agt_Name  As "SUB AGENT NAME",
		POL_PolicyNumber As "POLICY NO",
		RNR_Number As "AGENT POLICY NUMBER",
		CLI_ClientNumber As "CLIENT NUMBER", 
		(
			SELECT top 1 TIL_Title
			FROM ReferenceTitle
			WHERE Title_ID = CLI_Title_ID
		) As TITLE,
		CLI_Initials As INITIALS,
		CLI_Name + ' ' + CLI_Surname As CLIENTNAME,
		Client_ID + '{decrypt}' + CLI_IDNumber As "CLIENT ID NUMBER",
		CONVERT(VARCHAR(11), CLI_DateOfBirth, 111) As "BIRTH DATE",
		CLI_MaskedPassportNumber As "PASSPORT NUMBER",
		CLI_CompanyRegistration aS "COMPANY REG / CC NO",
		(
			select top 1 RNR_Number 
			from ReferenceNumber
			where RNR_ItemReferenceNumber = Policy_ID
				and RNR_NumberType_Id = 143
		) As "MIGRATION POLICY NO",
		POL_FinanceNumber As "PRIMARY FINANCE ACCOUNT NUMBER",
		POL_FinanceNumberAdditional As "SECONDARY FINANCE ACCOUNT NUMBER",
		(
			SELECT top 1 POS_Description
			FROM ReferencePolicyStatus
			WHERE PolicyStatus_ID = POL_Status
		) As STATUS,
		[Cancellation Reason] As "CANCELLATION REASON",
		POL_EndDate As "CANCELLATION DATE",
		[Cancellation Date] As "CXD POSTING DATE",
		[Cancellation User] As "CANCELLATION USER",
		RPM_Description As "PAYMENT METHOD",
		(
			SELECT  top 1 RTF_Description
		    FROM ReferenceTermFrequency
			WHERE TermFrequency_Id = POL_ProductTerm_ID
		) As "POLICY FREQUENCY",
		vwPolDetails.Premium As PREMIUM,
		CASE 
			WHEN ISNULL((
				SELECT count([Category ID])
				FROM vw_DMS_GetLetterSent
				WHERE "Reference Number" = policy_id
				AND [Category ID] in (210,211,212,213)), '0') <> '0'
			THEN  'Yes' 		
			ELSE 'None' 
		END "LETTER SEND",
		(
			SELECT top 1 RCM_Description
			FROM ReferencePreferredCommunicationMethod
			WHERE CommunnicationMethod_ID = CLI_PreferredCommunication_ID
		) As "PREFERRED METHOD OF COM",
		dbo.GetPolicyPremiumOutstanding(Policy_ID) As "OUTSTANDING AMOUNT"
	FROM Client,
	Product, 
	Agent,
	ReferenceTermFrequency, 
	Policy  
		LEFT JOIN (
			Select 
				EVL_ReferenceNumber [EventPolicyID],
				EVL_DateTime [Cancellation Date],
				ISNULL(ELD_NewValue, EVL_Description) [Cancellation Reason],
				(Select CONCAT(USR_FirstName, ' ', USR_Surname) From SystemUsers WHERE Users_ID =  EVL_User_ID) [Cancellation User]
			from EventLog,EventLogDetail
			where EventLog_ID = ELD_EventLog_ID 
				AND EVL_Event_ID = 10516
				AND ELD_Description not in ('Cancelation Comment', 'Refund Rule')
		) CancellationEventLog on [EventPolicyID] = Policy_ID
		Left Join ProductOptions on ProductOptions_ID = POL_ProductOption_ID
		left join ReferencePaymentMethod on ReferencePaymentMethod_ID = POL_PaymentMethod_ID
		left join SalesConsultants on POL_Agent_Consultant_ID = SalesConsultant_ID
		left join vw_PolicyItemDetails as vwPolDetails on vwPolDetails.Policy_Item_id = policy_id 
		left join  ReferenceNumber on RNR_ItemReferenceNumber = policy_id AND RNR_ItemType_ID = 2 AND RNR_NumberType_ID = 122 AND RNR_Deleted = 0,
	PolicyInsurerLink,  
	Insurer
	WHERE POL_Client_ID = Client_ID  
		AND Product_ID = POL_Product_ID 
		AND Agent_Id = POL_Agent_ID 
		AND POL_ProductTerm_ID = TermFrequency_ID 
		AND pol_status = 3
		AND POL_Deleted = 0 
		AND CLI_Deleted = 0 
		AND PIL_Insurer_ID = Insurer_Id
		AND policy_id = PIL_Policy_ID 
	    AND  [Cancellation Date] >= dateadd( month,-1,CONVERT(VARCHAR(10), getdate(), 111)) AND [Cancellation Date] <= (CONVERT(VARCHAR(10), getdate(), 111))
	    AND [Cancellation Date]  >= dbo.VarcharToDate('1 Oct 2019 00:00:00')
	    AND [Cancellation Date]  <= dbo.VarcharToDate('31 Oct 2019 00:00:00')                                
)E