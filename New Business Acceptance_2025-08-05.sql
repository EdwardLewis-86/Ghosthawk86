--RMPAPM_FR00017 New Business Acceptance
-----------------------------------------------
/*
Developer:                  Wendy Zola     
Modification Date:          2023-05-03
MSU:                        MSU020254

Developer:                  Petunia Mpe     
Modification Date:          2023-08-15
MSU:                        MSU014368

Developer:                  Julian Parker     
Modification Date:          2023-11-08
MSU:                        MSU017904

Developer:                  Petunia Mpe      
Modification Date:          2024-10-02
MSU:                        MSU017904

Developer:                  Petunia Mpe      
Modification Date:          2025-02-19
MSU:                        MSU026195

Developer:                  Desmond van Wyk        
Modification Date:          2025-05-29
MSU:                        MSU027555

*/
-----------------------------------------------------

IF OBJECT_ID ('Tempdb..#SumInsured') IS NOT NULL 
  DROP TABLE #SumInsured

SELECT DISTINCT ITS_Policy_ID, ITS_SumInsured 
INTO #SumInsured 
FROM  [Evolve].[dbo].[ProductSection] prs with(nolock)
INNER JOIN ItemSummary its with(nolock) on prs.ProductSection_Id = its.ITS_Section_ID
WHERE  PDS_SectionGrouping = 'Credit Shortfall';

----------------------------------------------------------------
WITH CTE_EventLog AS (
		SELECT 
			EVL.EVL_ReferenceNumber [RefNum],
			EVL.EVL_DateTime [Date],
			Users.USR_FirstName [FName],
			Users.USR_Surname [SName]
		FROM 
			EventLog EVL
			LEFT JOIN SystemUsers Users ON (Users.Users_ID = EVL.EVL_User_ID )
			INNER JOIN Policy POL ON (EVL.EVL_ReferenceNumber = POL.Policy_ID AND POL.POL_Deleted = 0)
			INNER JOIN Product PRD ON (PRD.Product_Id = POL.POL_Product_ID AND PRD.PRD_Deleted = 0)

		WHERE 
			EVL.EVL_Event_ID IN (10514, 10292)
			AND PRD.PRD_ProductGroup_Id <> 1 --Exclude Warranties
)

-----------------------------------------------

SELECT DISTINCT
	INS.INS_InsurerName																		[INSURER],
	RefCellCapt.RCC_Description															[CELL CAPTIVE],
	(
		SELECT DISTINCT TOP 1 (SRN_text)
		FROM SalesBranch, AgentDivisionLink
		WHERE SalesRegion_ID = ADL_Division_ID
			AND ADL_Agent_ID = POL.POL_Agent_ID
			AND isnull(ADL_ToDate,'')= ''
			AND SRN_Deleted = 0
	)																							[REGION],
	CONCAT(SC.SCO_Name, ' ', SC.SCO_Surname)													[SALES CONSULTANTS],
	MAR.MAR_Name																				[CONSULTANT],
	ISNULL(PrimaryAgents.Agt_Name, '')															[PRIMARY AGENT NAME],
	ISNULL(PrimaryAgents.Agt_AgentNumber, '')													[PRIMARY AGENT NUMBER],
	ISNULL(SubAgents.Agt_Name, '')																[SUB AGENT NAME],
	ISNULL(SubAgents.Agt_AgentNumber, '')														[SUB AGENT NUMBER],
	RefAgtRevType.ATY_Description																[REVENUE TYPE],
	PRD.PRD_Name																				[PRODUCT NAME],
	PrdPlans.PRP_PlanName																		[PRODUCT PLAN],
	POL.POL_PolicyNumber																		[POLICY NUMBER],	
	RefPolStatus.POS_Description																[STATUS],	
	RefPolSource.RPS_Description																[POLICY SOURCE],	
	RefPlatform.PLT_Description																	[EDI PLATFORM],
	RefNum.RNR_Number																			[AGENT POLICY NUMBER],	
	RefTermFreq.RTF_Description																	[POLICY FREQUENCY],
	FORMAT(POL.POL_StartDate, 'dd/MM/yyyy')														[START DATE],
	FORMAT(POL.POL_EndDate, 'dd/MM/yyyy')														[END DATE],
	FORMAT(POL.POL_SignedDate, 'dd/MM/yyyy')													[APPLICATION SIGN DATE],
	FORMAT(POL.POL_CreateDate, 'dd/MM/yyyy')													[POLICY CAPTURE DATE],
	CONCAT(CreateUser.USR_FirstName,' ', CreateUser.USR_Surname)								[CREATE USER],
	ISNULL(Acceptance.[Date], '')																[POLICY ACCEPTANCE DATE],
	ISNULL(CONCAT(Acceptance.FName, ' ', Acceptance.SName), '')									[ACCEPTANCE USER],							
	RefTitle.TIL_Title																			[TITLE],
	CLI.CLI_Initials																			[INITIALS],
	CLI.CLI_Name                                                                                [NAME], 
	CLI.CLI_Surname																				[SURNAME],
	--FORMAT(CLI.CLI_DateOfBirth,'dd/MM/yyyy') [BIRTH DATE],
	CASE WHEN CLI_CompanyName = '' THEN FORMAT(CLI_DateOfBirth,'dd/MM/yyyy') ELSE '' END	    [BIRTH DATE], --MSU018364
	/*CONCAT(CLI.Client_ID, '{decrypt}', CLI.CLI_IDNumber)*/ [CLI_MaskedIDNumber] 				[CLIENT ID NUMBER], --MSU027555
	CLI.CLI_MaskedPassportNumber																[PASSPORT NUMBER],
	CLI.CLI_CompanyName																			[COMPANY NAME],
	CLI.CLI_CompanyRegistration																	[COMPANY REG NO / CC NO],	
	RefFHouse.RFH_Description																	[FINANCE HOUSE],
	POL.POL_FinanceNumber																		[PRIMARY FINANCE NO],
	POL.POL_FinanceNumberAdditional																[SECONDARY FINANCE NO],	
	RefPayMethod.RPM_Description																[PAYMENT METHOD],
	CASE WHEN RefPayMethod.RPM_Description = 'Bulked'  THEN ''ELSE POL.POL_DebitDay END AS		[DEBIT DATE], --MSU014368
	--POL.POL_DebitDay																			[DEBIT DATE],
	IIF(
		POL.POL_PaymentMethod_ID = 3,
			FORMAT(POL.POL_FirstCollectionDate,'dd/MM/yyyy'),
			NULL
	) [FIRST COLLECTION DATE],
	POL.POL_FinanceTerm_ID																		[FINANCE TERM],
	IIF(
		RefPayMethod.ReferencePaymentMethod_ID = 6,
			RefBulkInst.RBI_Description,
			''
	)																							[BULKING INSTITUTION],
	IIF(
		POL.POL_PaymentMethod_ID = 6,
			POL.POL_FirstPaymentStart,
			NULL
	)																							[FIRST PAYMENT START DATE],
	vwPolDetails.Premium																		[PREMIUM],
	dbo.CalcPolicyProrata(Policy_ID, GETDATE())													[PRORATA PREMIUM],
	vwPolDetails.[AutoPremium]																	[AUTO PREMIUM],
	UsrPrem.Premium																				[USER PREMIUM],
	vwPolDetails.[Discount]																		[DISCOUNT LOADING / LOADING PERCENTAGE],
	vwPolDetails.INSURER_FEE																	[INSURER FEE],
	vwPolDetails.BROKER_FEE																		[BROKER FEE],
	vwPolDetails.PAINT_TECH_FEE																	[PAINT TECH FEE],
	dbo.GetContactNumber(Policy_ID, 30)															[WORK EMAIL],
	dbo.GetContactNumber(Policy_ID, 27)															[HOME EMAIL],
	RefPrefCommMethod.RCM_Description															[PREFERRED COMMUNICATION],
	dbo.GetContactNumber(Policy_ID, 28)															[WORK NUMBER],
	dbo.GetContactNumber(Policy_ID, 31)															[MOBILE NUMBER],
	(
	SELECT TOP 1 ADD_Line1
	FROM AddressDetails, AddressLink
	WHERE ADD_Deleted = 0
		AND ADL_AddressDetails_ID = AddressDetails_ID
		AND ADL_ReferenceNumber = Policy_ID
		AND ((ADD_AddressType_ID = 1) OR (ADD_AddressType_ID = 0))
		AND ADL_Default = 1
		AND ADL_Deleted = 0
	ORDER BY ADD_CreateDate DESC
	)																							[ADDRESS LINE 1],
		
	(
		SELECT TOP 1 ADD_Line2
		FROM AddressDetails, AddressLink
		WHERE ADD_Deleted = 0
			AND ADL_AddressDetails_ID = AddressDetails_ID
			AND ADL_ReferenceNumber = Policy_ID
			AND ((ADD_AddressType_ID = 1) OR (ADD_AddressType_ID = 0))
			AND ADL_Default = 1
			AND ADL_Deleted = 0
		ORDER BY ADD_CreateDate DESC
	)																							[ADDRESS LINE 2],
	
	(
		SELECT TOP 1 ADD_Suburb
		FROM AddressDetails, AddressLink
		WHERE ADD_Deleted = 0
			AND ADL_AddressDetails_ID = AddressDetails_ID
			AND ADL_ReferenceNumber = Policy_ID
			AND ((ADD_AddressType_ID = 1) OR (ADD_AddressType_ID = 0))
			AND ADL_Default = 1
			AND ADL_Deleted = 0
		ORDER BY ADD_CreateDate DESC
	)																							[ADDRESS LINE 3],
	
	(
		SELECT TOP 1 ADD_City
		FROM AddressDetails, AddressLink
		WHERE ADD_Deleted = 0
			AND ADL_AddressDetails_ID = AddressDetails_ID
			AND ADL_ReferenceNumber = Policy_ID
			AND ((ADD_AddressType_ID = 1) OR (ADD_AddressType_ID = 0))
			AND ADL_Default = 1
			AND ADL_Deleted = 0
		ORDER BY ADD_CreateDate DESC
	)																							[ADDRESS LINE 4],	
	(
		SELECT TOP 1 ADD_Code
		FROM AddressDetails, AddressLink
		WHERE ADD_Deleted = 0
			AND ADL_AddressDetails_ID = AddressDetails_ID
			AND ADL_ReferenceNumber = Policy_ID
			AND ((ADD_AddressType_ID = 1) OR (ADD_AddressType_ID = 0))
			AND ADL_Default = 1
			AND ADL_Deleted = 0
		ORDER BY ADD_CreateDate DESC
	)																							[ADDRESS LINE 5],
	vwPolDetails.Make																			[VEHICLE MAKE],
	vwPolDetails.Model																			[VEHICLE MODEL],
	vwPolDetails.VehicleCode																	[VEHICLE CODE (M&M)],
    case when vwPolDetails.VehicleCode = '99999999' then vwPolDetails.[Description] else ''end  [VEHICLE MAKE & MODEL],
	vwPolDetails.[Vehicle_type]																	[VEHICLE TYPE],
	--Adcover/Adcover & Deposit Cover Combo
	CASE WHEN PRD.Product_Id IN ('436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18')
	THEN sumInsured.ITS_SumInsured
	ELSE vwPolDetails.SumInsured
	END AS                                                                                  	[SUM INSURED],
	vwPolDetails.VINNumber																		[CHASSIS VIN],
	vwPolDetails.EnginNumber																	[ENIGINE NO],
	vwPolDetails.RegistrationNumber																[REGISTRATION NUMBER],
	vwPolDetails.RegistrationDate																[FIRST REGISTRATION DATE],
	FORMAT(POL_OriginalStartDate,'dd/MM/yyyy')													[ORIGINAL START DATE],
	MigratedPolNumber.RNR_Number																[MIGRATED POLICY NUMBER],
	PrdPlans.PRP_PlanName																		[PLAN TYPE],
	PrdOptions.PRO_Description																	[PLAN OPTION],
	POL.POL_SoldDate																			[POLICY SOLD DATE / PURCHASE DATE],
	dbo.GetContactNumber(Policy_ID, 26)															[HOME NUMBER],
	IIF(
		POL.POL_Status = 1, -- In Force
		dbo.fnc_PolicyPaymentStatus(POL.Policy_ID),
		NULL
	)																							[PAYMENT INDICATOR],
	BankD.BNK_AccountHolder																		[ACCOUNT HOLDER],
	BankAT.BAT_Description																		[ACCOUNT TYPE],
	BankD.BNK_Bank																				[BANK],
	BankD.BNK_Branch																			[BRANCH],
	BANKD.BNK_BranchCode																		[BRANCH CODE],
	BankD.BNK_MaskedAccountNo																	[ACCOUNT NUMBER]

--[Main Life insured details]
		,RT2.TIL_Title																			[MAINLIFE_TITLE]	
		,PolCredLifeItm.PCI_Initials															[MAINLIFE_INITIALS]
		,PolCredLifeItm.PCI_Surname																[MAINLIFE_SURNAME]
		,PolCredLifeItm.PCI_MaskedIDNumber 														[MAINLIFE_ID]
		,PolCredLifeItm.PCI_MaskedPassportNumber												[MAINLIFE_PASSPORT NUMBER]
		,PolCredLifeItm.PCI_DateOfBirth															[MAINLIFE_DATE OF BIRTH]
		,PolCredLifeItm.PCI_Age																	[MAINLIFE_AGE]	
--[Additional Life insured details]
	    ,PCP1T.TIL_Title																		[ADDITIONALLIFE_TITLE]	 
		,PCP1.PCP_Initials																		[ADDITIONALLIFE_INITIALS]
		,PCP1.PCP_Surname																		[ADDITIONALLIFE_SURNAME]
--		,PCP1.PCP_Name																			[ADDITIONALLIFE_FIRST NAMES]
		,PCP1.PCP_MaskedIDNumber 															    [ADDITIONALLIFE_ID]
		,PCP1.PCP_MaskedPassportNumber															[ADDITIONALLIFE_PASSPORT NUMBER]
		,PCP1.PCP_DateOfBirth																	[ADDITIONALLIFE_DATE OF BIRTH]
		,PCP1.PCP_Age																			[ADDITIONALLIFE_AGE]
		--,DATEDIFF(YEAR,PCP1.PCP_DateOfBirth,GETDATE())	AS [ADDITIONALLIFE_AGE]
--		,POL.Policy_ID 
		--,BT.*
	 	--,PCP1.*
FROM
	Policy POL
	--INNER JOINS
    INNER JOIN Product PRD ON (POL.POL_Product_ID = PRD.Product_Id AND PRD.PRD_Deleted = 0)

	--LEFT JOINS
    LEFT JOIN PolicyCreditLifeItem PolCredLifeItm ON (PolCredLifeItm.PCI_Policy_ID = POL.Policy_ID AND PolCredLifeItm.PCI_Deleted = 0)
	LEFT JOIN [dbo].[ReferenceTitle] AS RT2 WITH (NOLOCK)on RT2.Title_ID = PolCredLifeItm.PCI_Title_ID AND RT2.TIL_Deleted = 0

---ADDITIONALLIFE --MSU017904
LEFT JOIN  [dbo].[PolicyCreditLifeParty]  AS PCP1 WITH (NOLOCK) 
		ON PCP1.PCP_Item_ID = PolCredLifeItm.PolicyCreditLifeItem_ID
 		AND PCP1.PCP_PartyType = 0
		AND PCP1.PCP_Deleted = 0
LEFT JOIN [dbo].[ReferenceTitle] AS PCP1T WITH (NOLOCK)
		on PCP1T.Title_ID = PCP1.PCP_Title_ID
		and PCP1T.TIL_Deleted = 0

	LEFT JOIN ProductPlans PrdPlans ON (PrdPlans.ProductPlans_Id = PolCredLifeItm.PCI_Plan_ID AND PrdPlans.PRP_Deleted = 0)
	LEFT JOIN ProductOptions PrdOptions ON (PrdOptions.ProductOptions_Id = POL.POL_ProductOption_ID AND PrdOptions.PRO_Deleted = 0)
	LEFT JOIN PolicyInsurerLink PolInsLnk ON (PolInsLnk.PIL_Policy_ID = POL.Policy_ID AND PolInsLnk.PIL_Deleted = 0)
    LEFT JOIN Insurer INS ON (PolInsLnk.PIL_Insurer_ID = INS.Insurer_ID AND INS.INS_Deleted = 0)
    LEFT JOIN InsurerGroupLink InsGrpLnk ON (InsGrpLnk.IGL_Insurer_Id = INS.Insurer_Id AND InsGrpLnk.IGL_Deleted = 0)
	LEFT JOIN SalesConsultants SC on POL.POL_Agent_Consultant_ID = SC.SalesConsultant_ID
	LEFT JOIN Marketer MAR ON (MAR.Marketer_ID = POL.POL_Marketer_ID AND MAR.MAR_Deleted = 0)
    LEFT JOIN SystemUsers CreateUser ON (CreateUser.Users_ID = POL.POL_CreateUser_ID)
	LEFT JOIN Agent PrimaryAgents ON (POL.POL_PrimaryAgent_ID = PrimaryAgents.Agent_Id AND PrimaryAgents.Agt_Deleted = 0)
	LEFT JOIN Agent SubAgents ON (POL.POL_Agent_ID = SubAgents.Agent_Id AND SubAgents.Agt_Deleted = 0)
	LEFT JOIN AgentDivisionLink AgtDivLnk ON (AgtDivLnk.ADL_Agent_ID = PrimaryAgents.Agent_Id AND AgtDivLnk.ADL_Deleted = 0 AND ISNULL(AgtDivLnk.ADL_ToDate, '') = '' AND AgtDivLnk.ADL_Deleted = 0)
	LEFT JOIN Client CLI ON (CLI.Client_ID = POL.POL_Client_ID AND CLI.CLI_Deleted = 0)
	LEFT JOIN BankLink BankL ON (BankL.BKL_ReferenceNumber = POL.Policy_ID AND BankL.BKL_Deleted = 0 AND BankL.BKL_Default = 1)
	LEFT JOIN BankDetails BankD ON (BankD.BankDetails_ID = BankL.BKL_BankDetails_ID AND BankD.BNK_Deleted = 0)
	LEFT JOIN BankAccountType BankAT ON (BankAT.BankAccountType_ID = BankD.BNK_BankAccountType_ID AND BankAT.BAT_Deleted = 0)	
	LEFT JOIN ReferenceNumber MigratedPolNumber ON (MigratedPolNumber.RNR_ItemReferenceNumber = POL.Policy_ID AND MigratedPolNumber.RNR_NumberType_Id = 143 AND MigratedPolNumber.RNR_Deleted = 0)
	LEFT JOIN ReferenceNumber RefNum ON (
		RefNum.RNR_ItemReferenceNumber = POL.Policy_ID 
		AND RefNum.RNR_ItemType_ID = 2 
		AND RefNum.RNR_NumberType_ID = 122 
		AND RefNum.RNR_Deleted = 0
	)
	LEFT JOIN Arrangement on POL.POL_Arrangement_ID = Arrangement.Arrangement_Id 
	LEFT JOIN ReferenceCellCaptive RefCellCapt on IIF(Arrangement.ARG_CellCaptive is null, dbo.GetSystemSetting('AccountCellCaptive'), Arrangement.ARG_CellCaptive) = RefCellCapt.ReferenceCellCaptive_Code
	LEFT JOIN CTE_EventLog Acceptance ON (
		Acceptance.RefNum = POL.Policy_ID 
		AND Acceptance.[Date] = (
			SELECT TOP 1 CTE_EventLog.[Date]
			FROM CTE_EventLog 
			WHERE CTE_EventLog.RefNum = POL.Policy_ID
			ORDER BY CTE_EventLog.[Date] DESC
		)
	)
	LEFT JOIN (
		SELECT 
			SUM(ITS_Premium) Premium,
			ITS_Policy_ID
		FROM ItemSummary ITS
		WHERE 
			ITS_Premium > 0
			AND ITS_Deleted = 0
			AND ITS_Status = 1
		GROUP BY ITS_Policy_ID
	) UsrPrem ON UsrPrem.ITS_Policy_ID = POL.Policy_ID

	--REFERENCE TABLES 
	LEFT JOIN ReferenceAgentrevenuetype RefAgtRevType ON (RefAgtRevType.ReferenceAgentRevenueType_ID = SubAgents.Agt_RevenueType AND RefAgtRevType.ATY_Deleted = 0)
	LEFT JOIN ReferencePolicyStatus RefPolStatus ON (RefPolStatus.PolicyStatus_ID = POL.POL_Status AND RefPolStatus.POS_Deleted = 0)
	LEFT JOIN ReferencePolicySource RefPolSource ON (RefPolSource.PolicySource_ID = POL.POL_PolicySource_ID AND RefPolSource.RPS_Deleted = 0)
	LEFT JOIN ReferencePlatform RefPlatform ON (RefPlatform.Platform_Id = POL.POL_SourcePlatform_ID AND RefPlatform.PLT_Deleted = 0)
	LEFT JOIN ReferenceTermFrequency RefTermFreq ON (RefTermFreq.TermFrequency_Id = POL.POL_ProductTerm_ID AND RefTermFreq.RTF_Deleted = 0)
	LEFT JOIN ReferenceTitle RefTitle ON (RefTitle.Title_ID = CLI.CLI_Title_ID AND RefTitle.TIL_Deleted = 0)
	LEFT JOIN ReferenceFinanceHouse RefFHouse ON (RefFHouse.ReferenceFinanceHouse_ID = POL.POL_FinanceHouse_ID AND RefFHouse.RFH_Deleted = 0)
	LEFT JOIN ReferencePaymentMethod RefPayMethod ON (RefPayMethod.ReferencePaymentMethod_ID = POL.POL_PaymentMethod_ID AND RefPayMethod.RPM_Deleted = 0)
	LEFT JOIN ReferenceFinanceTerm RefFTerm ON (RefFTerm.FinanceTerm_Id = POL.POL_FinanceTerm_ID and RefFTerm.FIT_Deleted = 0)
	LEFT JOIN ReferenceBulkingInstitution RefBulkInst ON (RefBulkInst.BulkingInstitution_ID = POL.POL_BulkInstitution_ID AND RefBulkInst.RBI_Deleted = 0)
	LEFT JOIN ReferencePreferredCommunicationMethod RefPrefCommMethod ON (RefPrefCommMethod.CommunnicationMethod_ID = CLI.CLI_PreferredCommunication_ID AND RefPrefCommMethod.RCM_Deleted = 0)

	--VIEWS
	LEFT JOIN vw_PolicyItemDetails vwPolDetails ON (vwPolDetails.Policy_Item_id = POL.Policy_ID)
	LEFT JOIN #SumInsured sumInsured ON sumInsured.ITS_Policy_ID = POL.Policy_ID


WHERE 
	POL.POL_Deleted = 0
	AND POL.POL_Status = 1
	AND PRD.PRD_ProductGroup_Id <> 1 --Exclude Warranties
--	AND POL_PolicyNumber  = 'HCLL056342POL' 
	--PARAMETERS
	{FromAcceptanceDate}
	{ToAcceptanceDate}
	{FromScheduledDate}
	{ProductID}
	{CellCaptive}
	{Insurer}
	{PolicyStatus}
	{ProductGroupID}

ORDER BY
[POLICY ACCEPTANCE DATE],
[POLICY NUMBER]