




/*

Developer          Petunia Mpe
Modification Date: 14-11-2023
MSU Number:	   MSU021655 

Developer            Petunia Mpe
Modification Date:   21-02-2024
MSU Number:	         MSU022662 

Developer            Petunia Mpe
Modification Date:   27-03-2024
MSU Number:	         MSU022992 

Developer            Petunia Mpe
Modification Date:   12-06-2024
MSU Number:	         MSU022992 

*/

WITH CTE_EventLog AS (
		SELECT DISTINCT
			EVL.EVL_ReferenceNumber [RefNum],
			EVL.EVL_DateTime [Date]
			--Users.USR_FirstName [FName],
			--Users.USR_Surname [SName]
		FROM 
			EventLog EVL
			LEFT JOIN SystemUsers Users ON (Users.Users_ID = EVL.EVL_User_ID )
			INNER JOIN Policy POL ON (EVL.EVL_ReferenceNumber = POL.Policy_ID AND POL.POL_Deleted = 0)
			INNER JOIN Product PRD ON (PRD.Product_Id = POL.POL_Product_ID AND PRD.PRD_Deleted = 0)

		WHERE 
			EVL.EVL_Event_ID IN (10514)
			--EVL.EVL_Event_ID IN (10514, 10292)
			--AND PRD.PRD_ProductGroup_Id <> 1 --Exclude Warranties
)


SELECT 
		 [INSURER]	
		,[REGION]	
		,[ARRANGEMENT NUMBER]	
		,[PRIMARY AGENT NAME]	
		,[PRIMARY AGENT CODE]	
		,[SUB AGENT NAME]	
		,[SUB AGENT CODE]	
		,[SALES CONSULTANT]	
		,[REVENUE TYPE]	
		,[PRODUCT NAME]	
		,[PRODUCT PLAN]	
		,[PLAN TYPE]	
		,[PRODUCT GROUP]	
		,[RULE SET]	
		,[EDI PLATFORM]	
		,[POLICY SOURCE]	
		,[POLICY FREQUENCY]	
		,[POLICY NUMBER]
		,[AGENT POLICY NUMBER]	
		,[STATUS]	
		,CASE WHEN [STATUS] = 'NTU' THEN NULL 
			ELSE   [CANCELLATION_REASON]	
			END AS [CANCELLATION_REASON]	
        ,[NTU REASON]
		,[CANCELLATION POSTING DATE]
		,[NTU POSTING DATE]
		,[TITLE]	
		,[INITIALS]	
		,[SURNAME]	
		,[CLIENT NUMBER]	
		,[ID NUMBER]	
		,[BIRTH DATE]	
		,[PASSPORT NO]	
		,[COMPANY REG NO/CC NO]	
		,[PURCHASE DATE / SOLD DATE]	
		,[APPLICATION SIGN DATE]	
		,[CREATE USER]	
		,[UPDATE USER]	
		,[PAYMENT METHOD]	
		,[BULKING]	
		,[BULKING_INSTITUTION]	
		,[EDI BANK PRODUCT CODE]	
		,[FIRST COLLECTION DATE]	
		,[FIRST PAYMENT START DATE]	
		,[FINANCE HOUSE]	
		,[FINANCE TERM]
		,[PRIMARY FINANCE ACCOUNT NO]	
		,[SECONDARY FINANCE ACCOUNT NO]		
		,[PREMIUM]		
		,[DAYS IN PENDING ACCEPTANCE STATUS]	
		,[PREFERRED COMM METHOD]	
		,[EMAIL]	
		,[BUSINESS EMAIL]	
		,[MIGRATED]	
		,[MIGRATION POLICY NUMBER]	
		,[CREATE DATE]	
		,[ORIGINAL START DATE]	
		,[START DATE]	 
		,[ANNIVERSARY DATE]	
		,[RENEWAL DATE]	
		,[MATURITY DATE]	
		,[END DATE]	
		,[POLICY ACCEPTANCE DATE]
		,[DEBIT DATE]
FROM		
(SELECT  --TOP 10	
			INS_InsurerName INSURER,
  			RCC_Description "CELL CAPTIVE",
			SRN_text REGION,
--			Policy_id,
			ARG_ArrangementNumber As "ARRANGEMENT NUMBER",
			PrimaryAgents.Agt_Name  As "PRIMARY AGENT NAME",
			PrimaryAgents.Agt_AgentNumber  As "PRIMARY AGENT CODE",
			SubAgents.Agt_Name As "SUB AGENT NAME",
			SubAgents.Agt_AgentNumber As "SUB AGENT CODE",
			Concat(sco_Name, '', sco_Surname) As "SALES CONSULTANT",
			ATY_Description "REVENUE TYPE",
			prd_name As "PRODUCT NAME",
			PRO_Description AS  "PRODUCT PLAN",
			PRP_PlanName "PLAN TYPE",
			PDG_Description As "PRODUCT GROUP",
			DBG_Description As "RULE SET",
			PLT_Description "EDI PLATFORM",
			RPS_Description "POLICY SOURCE",
			RTF_Description "POLICY FREQUENCY",
			POL_PolicyNumber As "POLICY NUMBER",
			AgentPolicyNumber.RNR_Number "AGENT POLICY NUMBER",
			POS_Description STATUS,
			IIF(POL_Status not in (1, 4,9),
				(-- Only show cancellation reason for policies which are not in force/pending    
					IIF (EXISTS (
						Select * from EventLog,EventLogDetail  
						where EventLog_ID = ELD_EventLog_ID   
						AND ELD_Description in ('Cancelation Reason','Cancelation / Lapsing Reason','Failed Reason')  
						AND EVL_Event_ID in (12242, 10516)
						AND EVL_ReferenceNumber = policy_id
					),  (
							Select top 1 REPLACE(REPLACE(ISNULL(NULLIF(ELD_NewValue,''),ELD_Data),'Reason:',''),'Failed Reason :','')  
							from EventLog,EventLogDetail  
							where EventLog_ID = ELD_EventLog_ID   
								AND  ELD_Description in ('Cancelation Reason','Cancelation / Lapsing Reason', 'Failed Reason') 
								AND EVL_ReferenceNumber = policy_id  
								AND EVL_Event_ID in (12242, 10516)
							order by EVL_DateTime desc
						), 'Migrated As Cancelled'
					)   
				), 
		NULL) As CANCELLATION_REASON,
		--   ELD_Data As "NTU REASON 2",
			TIL_Title TITLE,
			CLI_Initials As INITIALS,
			CLI_Surname As SURNAME,
			CLI_ClientNumber As "CLIENT NUMBER", 
			CLI_MaskedIDNumber As "ID NUMBER",
			--CASE WHEN ISNULL(CLI_IDNumber,'') <> '' THEN dbo.evolvedecrypt(CLI_IDNumber,client_id) ELSE NULL END As [ID NUMBER],
			FORMAT(CLI_DateOfBirth,'dd/MM/yyyy') As "BIRTH DATE",
			CLI_MaskedPassportNumber As "PASSPORT NO",
			CLI_CompanyRegistration As "COMPANY REG NO/CC NO",    
			-- POL_CreateDate AS "CREATE DATE ",
			POL_SoldDate AS "PURCHASE DATE / SOLD DATE",
			POL_SignedDate AS "APPLICATION SIGN DATE",
			(CreateUser.USR_FirstName + ' ' + CreateUser.USR_Surname) "CREATE USER",
			(UpdateUser.USR_FirstName + ' ' + UpdateUser.USR_Surname) "UPDATE USER",
			RPM_Description As "PAYMENT METHOD",
			IIF(isnull(RBI_Description,'') = '', 'N', 'Y') As BULKING,
			RBI_Description As BULKING_INSTITUTION,
			EDIProductBankCode.RNR_Number As "EDI BANK PRODUCT CODE",
			--BNK_ACCOUNTHOLDER [ACCOUNT HOLDER], 
			--BAT_DESCRIPTION [ACCOUNT TYPE],
			--BNK_BANK [BANK],
			--BNK_BRANCH [BRANCH],
			--BNK_BRANCHCODE [BRANCH CODE],
			--BNK_MASKEDACCOUNTNO [ACCOUNT NO],
			--IIF(BankLink_ID is not null,IIF(ISNULL(BNK_Default, -1) = 1, 'Y', IIF(ISNULL(BNK_Default, -1) = -1, 'N/A', 'N')),	'N/A') [BANK DEFAULT],
			--IIF(BankDetails_ID is not null,IIF(isnull(BNK_RefNo, 'isnull') != POL_Client_ID, 'N', 'Y'), 'N/A') [Client Linked Correctly], 
			--IIF(BankDetails_ID is not null, IIF(isnull(BKL_ReferenceType, -1) != 2, 'N', 'Y'),'N/A') [Bank Item Type Correct], 
			IIF(POL_PaymentMethod_ID = 3, FORMAT(POL_FirstCollectionDate,'dd/MM/yyyy'), null)  "FIRST COLLECTION DATE",
			--IIF(POL_PaymentMethod_ID = 6, '', POL_DebitDay)  As "DEBIT DATE",
			IIF(POL_PaymentMethod_ID = 6, POL_FirstPaymentStart, null) As "FIRST PAYMENT START DATE",
				(
				SELECT top 1 RFH_Description
				   FROM ReferenceFinanceHouse
				  WHERE ReferenceFinanceHouse_ID = POL_FinanceHouse_ID
				) As "FINANCE HOUSE",
			POL_FinanceNumber As "PRIMARY FINANCE ACCOUNT NO",
			POL_FinanceNumberAdditional As "SECONDARY FINANCE ACCOUNT NO",
			case when POL_FinanceTerm_ID = -1 then null
			     when POL_FinanceTerm_ID = 1 then null
				 when POL_FinanceTerm_ID = 0 then null
			else POL_FinanceTerm_ID end  As "FINANCE TERM",
			(
				SELECT SUM(ITS_Premium)
				FROM ItemSummary
				WHERE ITS_Policy_ID = policy_id
					AND its_premium > 0
					AND ITS_Deleted = 0
			) As PREMIUM,
			iif(POL_Status = 4, DATEDIFF(DAY, POL_CreateDate, GETDATE()), 0) As "DAYS IN PENDING ACCEPTANCE STATUS",
 	     	dbo.GetContactNumber(Policy_ID, 31) As "CELL_PHONE",
			RCM_Description "PREFERRED COMM METHOD",

			(select top 1 CON_Value from ContactDetailLink,ContactDetails
				where Policy_ID = CDL_ReferenceNumber
				and CDL_ContactDetails_ID = ContactDetails_ID
				and CON_Deleted = 0
				and CDL_Default = 1
				and ((CON_ContactType_ID = 27) or (CON_ContactType_ID = 11))
				order by CON_UpdateDate desc)
				As "EMAIL",

 			(select top 1 CON_Value from ContactDetailLink,ContactDetails
				where Policy_ID = CDL_ReferenceNumber
				and CDL_ContactDetails_ID = ContactDetails_ID
				and CON_Deleted = 0
				and CDL_Default = 1
				and CON_ContactType_ID = 30
				order by CON_UpdateDate desc)
				As "BUSINESS EMAIL",
		    dbo.AddressList(POL_Client_ID, 1)  As "POSTAL ADDRESS",
			case when POL_IsMigrated = 1 then 'Yes' else 'No' end As MIGRATED,
			MigrationPolicyNumber.RNR_Number As "MIGRATION POLICY NUMBER",    
			FORMAT(POL_CreateDate,'dd/MM/yyyy') As "CREATE DATE",	
--			POL_SignedDate As "APPLICATION SIGN DATE",
			FORMAT(POL_OriginalStartDate,'dd/MM/yyy') As "ORIGINAL START DATE",  
			FORMAT(POL_StartDate,'dd/MM/yyy') As "START DATE",
			POL_AnniversaryDate AS "ANNIVERSARY DATE",
			POL_RenewalDate AS "RENEWAL DATE",
			REPLACE(FORMAT(POL_MaturityDate,'dd/MM/yyyy'),'01/01/1800','NO INFO') AS "MATURITY DATE",
			POL_EndDate As "END DATE",
--			POL_SoldDate AS "POLICY SOLDDATE",
			(
			Select top 1 ELD_Data
			from EventLog,EventLogDetail
			where EventLog_ID = ELD_EventLog_ID 
			AND  ELD_Description like ('%NTU Reason%')
			AND EVL_ReferenceNumber = policy_id
			AND ISNULL(Cast(ELD_NewValue as varchar(Max) ),'') <> '' 
			) As "NTU REASON",
			(
			Select MAX(EVL_DateTime) [NTU Posting date ]
			from EventLog,EventLogDetail
			where EventLog_ID = ELD_EventLog_ID 
			AND  ELD_Description like ('%NTU Reason%')
			AND EVL_ReferenceNumber = policy_id
			AND ISNULL(Cast(ELD_NewValue as varchar(Max) ),'') <> '' 
			) As [NTU POSTING DATE],
           (

             SELECT  MAX(EVL_DateTime) [Cancellation Date]
             FROM EventLog,
            EventLogDetail
            WHERE EventLog_ID = ELD_EventLog_ID
           AND EVL_Event_ID = 10516
           AND ELD_Description NOT IN('Cancelation Comment', 'Refund Rule')
		   AND EVL_ReferenceNumber = policy_id
		   )[CANCELLATION POSTING DATE]
		 		 ,CASE WHEN Acceptance.[Date] = '1900-01-01 00:00:00.000'
		     THEN ''
          ELSE
		  Acceptance.[Date] END AS  [POLICY ACCEPTANCE DATE]
		 ,CASE WHEN RPM_Description = 'Bulked'  THEN ''
		       WHEN RPM_Description = 'Bordereaux' THEN ''
	        ELSE 
	      POL_DebitDay END AS  [DEBIT DATE]
  from Client
    inner join Policy on POL_Client_ID = Client_ID
--	left join EventLog on EVL_ReferenceNumber = Policy_ID 
--	left join EventLogDetail on EventLog_ID = ELD_EventLog_ID 
    inner join Product on POL_Product_ID = Product_Id
	LEFT JOIN ProductOptions ON  POL_ProductOption_ID = ProductOptions_id
	left join ReferenceProductGroup on ProductGroup_ID = PRD_ProductGroup_Id
    inner join Agent PrimaryAgents on POL_PrimaryAgent_ID = Agent_Id
    left join SystemUsers CreateUser on Users_ID = POL_CreateUser_ID
    left join SystemUsers UpdateUser on UpdateUser.Users_ID = POL_UpdateUser_ID
    left join ReferencePolicyStatus on PolicyStatus_ID = POL_Status
    left join PolicyInsurerLink on PIL_Policy_ID = Policy_ID
    left join Insurer on PIL_insurer_ID = Insurer_ID
    left join InsurerGroupLink on IGL_Insurer_Id = Insurer_Id    
    left join ReferenceTitle on Title_ID = CLI_Title_ID
    Left join Agent SubAgents on POL_Agent_ID = SubAgents.Agent_Id     
    left join ReferenceAgentrevenuetype on ReferenceAgentRevenueType_ID = SubAgents.Agt_RevenueType
    left join AgentDivisionLink on ADL_Agent_ID = PrimaryAgents.Agent_Id AND ADL_Deleted = 0 AND isnull(ADL_ToDate,'')= '' 
    left join SalesBranch on SalesRegion_ID = ADL_Division_ID 
    left join (select RNR_ItemReferenceNumber, MAX(RNR_Number) RNR_Number From ReferenceNumber where RNR_NumberType_Id= 146  AND RNR_Deleted = 0 Group by RNR_ItemReferenceNumber) EDIProductBankCode on Policy_ID = RNR_ItemReferenceNumber
    left join (select RNR_ItemReferenceNumber, MAX(RNR_Number) RNR_Number From ReferenceNumber where RNR_NumberType_Id= 143  AND RNR_Deleted = 0 Group by RNR_ItemReferenceNumber) MigrationPolicyNumber on Policy_ID = MigrationPolicyNumber.RNR_ItemReferenceNumber
    left join (select RNR_ItemReferenceNumber, MAX(RNR_Number) RNR_Number From ReferenceNumber where RNR_NumberType_Id= 122  AND RNR_Deleted = 0 AND RNR_ItemType_ID = 2 Group by RNR_ItemReferenceNumber) AgentPolicyNumber on Policy_ID = AgentPolicyNumber.RNR_ItemReferenceNumber
    left join ReferencePaymentMethod on ReferencePaymentMethod_ID = POL_PaymentMethod_ID
    left join SalesConsultants on POL_Agent_Consultant_ID = SalesConsultant_ID
    left join arrangement on POL_Arrangement_ID = Arrangement_Id 
    left join ReferenceCellCaptive on IIF(ARG_CellCaptive is null, dbo.GetSystemSetting('AccountCellCaptive'), ARG_CellCaptive) = ReferenceCellCaptive_Code
    left join PolicyFactoringCommissionLink on  policy_id = PFC_PolicyID
    left join ReferenceBulkingInstitution on BulkingInstitution_ID = POL_BulkInstitution_ID    and POL_PaymentMethod_ID = 6
    left join PolicyCreditLifeItem on PCI_Policy_ID = policy_id AND PCI_Deleted = 0
    left join ProductPlans on ProductPlans_id = PCI_Plan_ID
    left join ReferencePlatform on Platform_Id = POL_SourcePlatform_ID
    left join ReferencePolicySource on PolicySource_ID = POL_PolicySource_ID
    left join ReferenceTermFrequency on TermFrequency_Id = POL_ProductTerm_ID
    left join ReferencePreferredCommunicationMethod on CommunnicationMethod_ID = CLI_PreferredCommunication_ID
    left join BankLink on BKL_ReferenceNumber = Policy_ID AND BKL_Deleted = 0 AND BKL_Default = 1
    Left join BankDetails on BankDetails_ID = BKL_BankDetails_ID AND POL_PaymentMethod_ID not in (5, 6) AND BNK_Deleted = 0 
	
	-----Added code for Acceotance date 
	left join CTE_EventLog Acceptance on (	Acceptance.RefNum = Policy_ID 
		and  Acceptance.[Date] = (
			select top 1 CTE_EventLog.[Date]
			from CTE_EventLog 
			where CTE_EventLog.RefNum = Policy_ID
			order by CTE_EventLog.[Date] desc
		)
	)

    left join BankAccountType on BankAccountType_ID = BNK_BankAccountType_ID   
    left join (
        Select 
            ARP_Arrangement_ID [ARP_ID],
            ARP_Product_ID,
            PAL_ProductPlan_Id,
            DBG_Description
        from ArrangementProduct
            inner join ProductArrangementPlanLink on ProductArrangementPlanLink_Id = ARP_ProductArrangementPlanLink AND PAL_Product_Id = ARP_Product_ID
            left join DisbursementGroups on DisbursementGroup_Id = ARP_DisbursementGroup_ID
    ) ARP on Arrangement_Id = [ARP_ID] AND ARP_Product_ID = POL_Product_ID AND PAL_ProductPlan_Id = POL_ProductPlan_ID 
WHERE Client_ID is not null
AND POL_Deleted <> 1  ---Request : MSU017186
--AND POL_PolicyNumber = 'OV4U000056POL'

{Insurer}
{FromDate}
{ToDate}

{ProductGroup}
{Product}
{CellCaptive}
{PolicyStatus}


--AND POL_PolicyNumber IN 
--(
-- 'QAPD059005POL'
--,'QAPD059005POL'
--,'QADC037479POL'
--,'HADC079776POL'
--,'QADC010252POL'
--,'HCLL044604POL'
--,'QADC092405POL'
--,'QAPD051515POL'
--,'QADC121767POL'
--)
 --Order by POL_CreateDate, POL_PolicyNumber
 
 ) AS A 




