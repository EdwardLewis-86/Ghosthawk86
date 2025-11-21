Select 
	INS_InsurerName [Insurer], 
	POL_PolicyNumber [Policy Number],
	PRD_Name [Product Name],
	POL_OriginalStartDate [Policy Original Inception Date],
	POL_StartDate [Policy Start Date],
	POL_RenewalDate [Policy Renewal Date],
	POL_SignedDate [Policy Signed Date],
	RTF_Description [Policy Type],
	CLI_NatureOfBusiness [Line of Business], 
	CLI_Name [Policy Holder Name],
	CLI_Surname [Policy Holder Surname],
	dbo.GetContactNumber(Policy_ID, 31) [Policy Holder Contact Number],
	PDS_Description [Section], 
	ITS_Description [Cover Description],
	agt_name [Agent Name],
	SalesBranch.SRN_Text [Sales Branch],
	dbo.fnc_AgentFSPVATDetail_VATNumber(Agent_id,getdate()) [Agent VAT Number],
	CASE  WHEN CLI_ForeignIndicator = 0 THEN 'Local'  ELSE 'Foreign' END [Risk Location],
	ITS_SumInsured [Sum Insured],
	ATS_EffectiveDate [Effective Date],
	ATS_CreateDate [Transaction Date],
	ATT_Description [Transaction Type],
	LEFT(format(ATS_EffectiveDate, 'yyyyMM'), 6) [Effective Month],
	-GP.ADI_GrossAmount [Gross Premium],
	-GP.ADI_VATAmount [Gross Premium VAT],
	-GP.ADI_NettAmount [Gross Premium Excl VAT],
	BC.ADI_GrossAmount [Broker Commission],
	BC.ADI_VATAmount [Broker Commission VAT],
	BC.ADI_NettAmount [Broker Commission Excl VAT],
	'' [Binder Fee Excl VAT],
    '' [Binder Fee VAT],
    '' [Binder Fee Incl VAT],
    '' [Management Fee],
	PCI_SumInsured [Death Cover Amount],
	'' [Death Premium],
	CASE WHEN RCV_Disability = 1 THEN PCI_SumInsured ELSE 0 END [Total Permanent Disability Amount],
	'' [Total Permanent Disability Premium],
	CASE WHEN RCV_Dread = 1 THEN PCI_SumInsured ELSE 0 END [Temporary Disablity Amount],
	'' [Temporary Disablity Premium],
    '' [Loss of Income Amount],
    '' [Loss of Income Premium],
    '' [Monthly Loan Installments],
    '' [Initial Loan Amount],
    '' [Outstanding Loan Amount],
	POL_FinanceTerm_ID [Original Term],
	(POL_FinanceTerm_ID - DATEDIFF(month, POL_StartDate, GETDATE())) [Outstanding Term],
	PDS_Description [Cover Descriptor],
	'' [Risk Item Type], 
	RTF_Description [Policy Payment Frequency],
	'' [Scheme Type],
	RCC_Description + ' ' + RCC_GLCode [Cell Captive]
from Client
inner join Policy on POL_Client_ID = Client_ID
Inner join Product on POL_Product_ID = Product_Id
Inner join Agent on POL_PrimaryAgent_ID = Agent_Id

Inner join AccountTransactionSet GPS on ATS_DisplayNumber = POL_PolicyNumber
Inner join AccountTransaction GPT on AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
Inner join AccountDetailItem GP on AccountTransaction_Id = gp.ADI_AccountTransaction_ID AND GP.ADI_GLCode_ID in (49,198,322,410, 589) AND ATN_GLCode_ID in (49,198,322,410)
Left join AccountDetailItem BC on (
              BC.ADI_AccountTransactionSet_ID  = GP.ADI_AccountTransactionSet_ID 
              AND BC.adi_item_id = GP.adi_item_id 
			  AND BC.ADI_GLCode_ID in (56,205,332,420,593)
			  AND BC.ADI_AccountParty_ID in (
					Select AccountParty_Id from AccountParty where APY_PartyType_ID = 500
			  )
       )
Left join AccountParty BCP on BCP.AccountParty_Id = BC.ADI_AccountParty_ID
Inner join ItemSummary on ITS_Policy_ID = Policy_ID AND ITS_Item_ID = GP.ADI_Item_ID
Inner join ProductSection on ITS_Section_ID = ProductSection_Id
left join PolicyCreditLifeItem on Policy_ID = PCI_Policy_ID
left join Insurer on ATS_Insurer_Id = Insurer_Id
Left join ReferenceTermFrequency on TermFrequency_Id = POL_ProductTerm_ID
left join ReferenceCreditLifeValuationExtract on RCV_ProductPlan_Id = PCI_Plan_ID
left JOIN insurergrouplink ON igl_insurer_id = ats_insurer_id
left JOIN insurergroup ON igl_insurergroup_id = insurergroup_id
left join SalesBranch on SalesRegion_ID = ATS_SalesBranch
left join AccountTransactionType on AccountTransactionType_Id = ATN_AccountTransactionType_ID
LEFT JOIN ReferenceCellCaptive ON ReferenceCellCaptive_Code = ATS_CellCaptive_Id

WHERE INS_InsurerName like '%short term%'
{InsurerGroup}
{FromDate}
{ToDate}