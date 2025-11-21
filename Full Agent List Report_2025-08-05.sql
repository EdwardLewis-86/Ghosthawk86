SELECT 
	(SELECT IGY_Name FROM InsurerGroup WHERE InsurerGroup_Id = SubAgents.Agt_Insurer) AS Insurer,
	(SELECT PDG_Description FROM ReferenceProductGroup WHERE ProductGroup_id = SubAgents.Agt_ProductGroup) AS Product_Group,
	SubAgents.Agt_AgentNumber,
	SubAgents.Agt_Name,
	dbo.fnc_AgentFSPVATDetail_FSPNumber(SubAgents.agent_id,GETDATE()) AS FSP_Number,
	AR.ARG_ArrangementNumber Arrangement_Number,
	(SELECT ATY_Description FROM ReferenceAgentRevenueType WHERE ReferenceAgentRevenueType_ID = SubAgents.Agt_RevenueType) AS Agent_type,
	CASE WHEN ISNULL(ARA_EndDate,'') = '' THEN 'Active' ELSE 'Expired' END AS Agent_status,
	FORMAT(ARA_StartDate,'dd/MM/yyyy') AS AGENT_START_DATE,
	FORMAT(ARA_EndDate,'dd/MM/yyyy') AS AGENT_END_DATE,
	(SELECT ACA_Description FROM ReferenceAgentCategory WHERE ReferenceAgentCategory_ID = SubAgents.Agt_AgentCategory) AS Agent_Category,
	SubAgents.Agt_FullName AS [Description],
	/*(SELECT ATY_Description FROM ReferenceAgentRevenueType WHERE ReferenceAgentRevenueType_ID = SubAgents.Agt_RevenueType) AS AGENT_TYPE,*/
	TIA.RNR_NUmber AS TIA_AgentNumer,
	(SELECT COT_Description FROM ReferenceCompanyType WHERE CompanyType_ID = SubAgents.agt_CompanyType_id) AS Company_type,
	SubAgents.Agt_NatureOfBusiness AS Nature_of_Business,
	(
		CASE
			WHEN dbo.fnc_AgentFSPVATDetail_FSPInd(SubAgents.agent_id,GETDATE()) = 1 THEN 'Yes'
			ELSE 'No'
		END
	) AS "FSP_Yes/No",
	(SELECT EDA_Description FROM ReferenceEDIAction WHERE EDIAction_ID = SubAgents.Agt_EDIEdorsement_ID) AS EDI_ACTION,
	(SELECT Lan_Description FROM ReferenceLanguage WHERE Language_ID = SubAgents.Agt_PreferredLanguage_ID) AS Preferred_Language,
	(SELECT UNS_Description FROM ReferenceUnmetSMS WHERE UnmetSMS_ID = SubAgents.Agt_UnmetSMS) AS Unmet_SMS,
	SubAgents.Agt_AgentSMSName AS Agent_SMS_Name,
	SubAgents.Agt_PaymentDays AS Payment_Days,
	/*(SELECT PSE_Description FROM ReferencePaymentStatusExcel WHERE PaymentStatementExcel_ID = SubAgents.Agt_PaymentStatementExcel) AS Payment_Statement_Excel,*/
	(
		CASE
			WHEN  SubAgents.Agt_PaymentStatementExcel = 1 THEN 'DMS Only'
			WHEN SubAgents.Agt_PaymentStatementExcel = 2 THEN 'Email - Simple'
			WHEN SubAgents.Agt_PaymentStatementExcel = 2 THEN 'Email- Complex'
			ELSE 'None'
		END 
	) AS Payment_Statement_Excel,
	(SELECT PSP_Description FROM ReferencePaymentStatusPDF WHERE PaymentStatementPDF_ID = SubAgents.Agt_paymentStatementPDF) AS Payment_Statement_PDF,

	/*Contact Details*/
	STUFF(
		(
			SELECT '; ' + psd.PCD_Description
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) [ Contact Description],
	
	STUFF(
		(
			SELECT '; ' + TIL_Title
			FROM PartyContactDetails psd,ReferenceTitle
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_Title_ID = Title_ID
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) Title,
	STUFF(
		(
			SELECT '; ' + psd.PCD_FirstName
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) FirstName,
	
	STUFF(
		(
			SELECT '; ' + psd.PCD_Surname
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) [Surname],
	
	STUFF(
		(
			SELECT '; ' + psd.PCD_Email
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) [Email],

	STUFF(
		(
			SELECT '; ' + psd.PCD_WorkNumber
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) WorkNumber,

	STUFF(
		(
			SELECT '; ' + psd.PCD_MobileNumber
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) Mobile_number,
	
	STUFF(
		(
			SELECT '; ' + psd.PCD_FaxNumber
			FROM PartyContactDetails psd
			WHERE psd.PCD_ReferenceNumber = SubAgents.Agent_Id
			AND psd.PCD_ReferenceType = 501 AND psd.PCD_Deleted = 0
			FOR XML PATH('')
		), 1, 1, ''
	) Fax_Number,

	/*Address Details*/
	Postal.ADD_Line1 AS Postal_Address_line1,
	Postal.ADD_Line2 AS Postal_Address_line2,
	Postal.ADD_Suburb AS Postal_Suburb,
	Postal.ADD_City AS Postal_City,
	(SELECT ADP_Description FROM AddressProvinces WHERE AddressProvinces_ID = Postal.ADD_ProvinceState) AS Postal_Province,
	Postal.ADD_Code AS Postal_Code,
	(SELECT ACO_Description FROM AddressCountry WHERE AddressCountry_ID =Postal.ADD_Country) AS Postal_Country,
	Physical.ADD_Line1 AS Physical_Address_line1,
	Physical.ADD_Line2 AS Physical_Address_line2,
	Physical.ADD_Suburb AS Physical_Suburb,
	Physical.ADD_City AS Physical_City,
	(SELECT ADP_Description FROM AddressProvinces WHERE AddressProvinces_ID = Physical.ADD_ProvinceState) AS Physical_Province,
	Physical.ADD_Code AS Physical_Code,
	(SELECT ACO_Description FROM AddressCountry WHERE AddressCountry_ID =  Physical.ADD_Country) AS Physical_Country,

	/*Bank Details*/
	Comm.BNK_Bank AS Commission_Bank,
	Comm.BNK_AccountHolder AS Commission_Account_Name,
	Comm.BNK_MaskedAccountNo AS Commission_Masked_AccountNo,
	(SELECT BAT_Description FROM BankAccountType WHERE BankAccountType_ID=Comm.BNK_BankAccountType_ID) AS Commission_Account_type,
	Comm.BNK_Branch AS Commisson_Branch,

	Disb.BNK_Bank AS Disbursement_Bank,
	Disb.BNK_AccountHolder AS Disbursement_Bank_Account_Name,
	Disb.BNK_MaskedAccountNo AS Disbursement_Bank_Masked_AccountNo,
	(SELECT BAT_Description FROM BankAccountType WHERE BankAccountType_ID=Disb.BNK_BankAccountType_ID ) AS Disbursement_Bank_Account_type,
	Disb.BNK_Branch AS Disbursement_Bank_Branch,
	(CASE WHEN SubAgents.Agt_FactoredOnReceipt = 1 THEN 'Yes' ELSE 'No' END) AS Facored_on_Receipt,
	FORMAT(SubAgents.Agt_FactoredFrom, 'dd/MM/yyyy') AS Factored_From_Date,
	FORMAT(SubAgents.Agt_FactoredTo, 'dd/MM/yyyy')  AS Factored_To_Date,
	FORMAT(AR.ARG_StartDate, 'dd/MM/yyyy')  AS Arrangement_Start_Date,
	FORMAT(AR.ARG_EndDate, 'dd/MM/yyyy')  AS Arrangement_End_Date,
	(SELECT TER_Description FROM ReferenceTerminationReason WHERE TerminationReason_ID = ARA_TerminationReason_ID) AS Termination_Reason,
	(CASE WHEN SubAgents.Agt_PayOnReceipt= 1 THEN 'Yes' ELSE 'No' END) AS Pay_on_Receipt,
	(SELECT Prd_name FROM Product WHERE Product_Id = ClaimNotifications.INO_Product_ID) AS Claims_Product,
	ClaimNotifications.INO_Message AS Claims_Message,
	(SELECT RGA_Name FROM RateGatewayAgent WHERE RateGatewayAgent_Id = SubAgents.Agt_RateGatewayAgent_Id) AS [Rate_Gateway_agent],
	WWDealerCode.SAWNumber AS [WW_Dealer_code]
FROM
	Agent [SubAgents]
	/*INNER JOINS*/
	INNER JOIN (
		SELECT DISTINCT
			ARA_Arrangement_ID,
			ARA_Agent_ID,
			ARA_TerminationReason_ID,
			ARA_StartDate,
			ARA_EndDate
		FROM 
			ArrangementAgents [ARA]
			INNER JOIN Agent [PrimaryAgents] ON ([PrimaryAgents].Agt_Deleted = 0 AND [PrimaryAgents].Agent_Id = [ARA].ARA_PrimaryAgent_ID)
		WHERE
			[ARA].ARA_Deleted = 0
			AND [ARA].ARA_Agent_ID <> ''
	) [ArrangementAgents] ON ([ArrangementAgents].ARA_Agent_ID = [SubAgents].Agent_Id)
	INNER JOIN Arrangement [AR] ON ([AR].ARG_Deleted = 0 AND [AR].Arrangement_Id = [ArrangementAgents].ARA_Arrangement_ID)
	
	/*LEFT JOINS*/
	/*LEFT JOIN PartyContactDetails ON PCD_ReferenceNumber = SubAgents.Agent_id AND PCD_ReferenceType = 501 AND PCD_Deleted = 0 AND PCD_UpdateDate = (SELECT max(PCD_UpdateDate) FROM PartyContactDetails WHERE PCD_ReferenceNumber = SubAgents.Agent_id AND PCD_ReferenceType = 501 AND PCD_Deleted = 0)*/
	/*
	LEFT JOIN AddressDetails Postal ON Postal.ADD_ReferenceNumber = SubAgents.Agent_id AND Postal.ADD_ReferenceType = 501 AND Postal.ADD_AddressType_ID = 1 AND Postal.ADD_Deleted= 0
	LEFT JOIN AddressDetails Physical ON Physical.ADD_ReferenceNumber = SubAgents.Agent_id AND Physical.ADD_ReferenceType = 501 AND Physical.ADD_AddressType_ID = 0 AND Physical.ADD_Deleted= 0		
	*/
	LEFT JOIN (
	SELECT 
		ADD_ReferenceNumber [RefNum],
		ADD_CreateDate [CreateDate],
		ADD_UpdateDate [UpdateDate],
		ADD_Line1,
		ADD_Line2,
		ADD_Suburb,
		ADD_City,
		ADD_ProvinceState,
		ADD_Code,
		ADD_Country
	FROM
		AddressDetails
		INNER JOIN (
			SELECT
				ADD_ReferenceNumber [RefNum],
				MAX(ADD_UpdateDate) [Last Updated]
			FROM AddressDetails
			WHERE
				ADD_Deleted = 0
				AND ADD_Default = 1 
				AND ADD_AddressType_ID = 1
				AND ADD_ReferenceType = 501
			GROUP BY ADD_ReferenceNumber
		) [GetDate] ON ([GetDate].RefNum = ADD_ReferenceNumber AND [GetDate].[Last Updated] = ADD_UpdateDate)
	WHERE
		ADD_Deleted = 0
		AND ADD_Default = 1 
		AND ADD_AddressType_ID = 1
		AND ADD_ReferenceType = 501
	) [Postal] ON ([Postal].[RefNum] = [SubAgents].Agent_id)
	LEFT JOIN (
	SELECT 
		ADD_ReferenceNumber [RefNum],
		ADD_CreateDate [CreateDate],
		ADD_UpdateDate [UpdateDate],
		ADD_Line1,
		ADD_Line2,
		ADD_Suburb,
		ADD_City,
		ADD_ProvinceState,
		ADD_Code,
		ADD_Country
	FROM
		AddressDetails
		INNER JOIN (
			SELECT
				ADD_ReferenceNumber [RefNum],
				MAX(ADD_UpdateDate) [Last Updated]
			FROM
				AddressDetails
			WHERE
				ADD_Deleted = 0
				AND ADD_Default = 1 
				AND ADD_AddressType_ID = 0
				AND ADD_ReferenceType = 501
			GROUP BY ADD_ReferenceNumber
		) [GetDate] ON ([GetDate].RefNum = ADD_ReferenceNumber AND [GetDate].[Last Updated] = ADD_UpdateDate)
	WHERE
		ADD_Deleted = 0
		AND ADD_Default = 1 
		AND ADD_AddressType_ID = 0
		AND ADD_ReferenceType = 501
	) [Physical] ON ([Physical].[RefNum] = [SubAgents].Agent_id)
	/*
	LEFT JOIN BankDetails Comm ON Comm.BNK_REFNo = SubAgents.Agent_Id AND Comm.BNK_REFType = 501 AND Comm.BNK_Deleted = 0 AND Comm.BNK_BankType = 1 AND Comm.BNK_UpdateDate = (SELECT Max(BNK_Updatedate) FROM BankDetails WHERE BNK_REFNo =SubAgents.Agent_Id)
	LEFT JOIN BankDetails Disb ON Disb.BNK_REFNo = SubAgents.Agent_Id AND Disb.BNK_REFType = 501 AND Disb.BNK_Deleted = 0 AND Disb.BNK_BankType = 2 AND Disb.BNK_UpdateDate = (SELECT Max(BNK_Updatedate) FROM BankDetails WHERE BNK_REFNo =SubAgents.Agent_Id)
	*/
	LEFT JOIN (
		SELECT DISTINCT
			BNK_REFNo [RefNum],
			BNK_UpdateDate [UpdateDate],
			BNK_Bank,
			BNK_AccountHolder,
			BNK_MaskedAccountNo,
			BNK_BankAccountType_ID,
			BNK_Branch
		FROM
			BankDetails [BNK]
		WHERE
			[BNK].BNK_Deleted = 0
			AND BNK_REFType = 501
			AND BNK_BankType = 1 
	) [Comm] ON ([Comm].[RefNum] = [SubAgents].Agent_Id AND [Comm].[UpdateDate] = (SELECT MAX(BNK_Updatedate) FROM BankDetails WHERE BNK_REFNo = [SubAgents].Agent_Id))
	LEFT JOIN (
		SELECT DISTINCT
			BNK_REFNo [RefNum],
			BNK_UpdateDate [UpdateDate],
			BNK_Bank,
			BNK_AccountHolder,
			BNK_MaskedAccountNo,
			BNK_BankAccountType_ID,
			BNK_Branch
		FROM
			BankDetails [BNK]
		WHERE
			[BNK].BNK_Deleted = 0
			AND BNK_REFType = 501
			AND BNK_BankType = 2 
	) [Disb] ON ([Disb].[RefNum] = [SubAgents].Agent_Id AND [Disb].[UpdateDate] = (SELECT MAX(BNK_Updatedate) FROM BankDetails WHERE BNK_REFNo = [SubAgents].Agent_Id))
	LEFT JOIN ReferenceNumber [TIA] ON ([TIA].RNR_ItemReferenceNumber = [SubAgents].Agent_id AND [TIA].RNR_ItemType_Id = 501 AND [TIA].RNR_NumberType_Id = 118 AND [TIA].RNR_Deleted = 0)
	LEFT JOIN (
		SELECT
			RNR_Number [SAWNumber],
			RNR_ItemReferenceNumber
		FROM
			ReferenceNumber [RNR]
			INNER JOIN ReferenceNumberType [RNT] ON ([RNT].RNT_Deleted = 0 AND [RNT].ReferenceNumberType_Id = RNR.RNR_NumberType_Id)
			/*INNER JOIN [Evolve].[dbo].[ReferenceNumberType] AS RNT ON RNR.RNR_NumberType_Id = RNT.ReferenceNumberType_Id*/
		WHERE
			[RNR].RNR_Deleted = 0
			AND RNT_Description = 'SAW Dealer Code'
			AND RNR_ItemType_Id = 501
	) [WWDealerCode] ON ([WWDealerCode].RNR_ItemReferenceNumber = [SubAgents].Agent_Id)
	/*LEFT JOIN ItemNotification ClaimNotifications ON ClaimNotifications.INO_ItemReference = SubAgents.Agent_id AND ClaimNotifications.INO_ItemType_ID = 501*/
	LEFT JOIN (
		SELECT DISTINCT
			INO_ItemReference,
			INO_Product_ID,
			CAST(INO_Message AS nvarchar(250)) [INO_Message]
		FROM
			ItemNotification
		WHERE
			INO_Deleted = 0
			AND INO_ItemType_ID = 501
	) [ClaimNotifications] ON ([ClaimNotifications].INO_ItemReference = [SubAgents].Agent_id)
WHERE
	SubAgents.Agt_Deleted = 0

	/*AND isnull(ARA_StartDate,'') <> isnull(ARA_EndDate,'')*/	
	/*AND Subagents.Agt_AgentNumber in (7627)*/

