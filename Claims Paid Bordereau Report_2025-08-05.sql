DECLARE @VAT int = 15,
@Schedule DATETIME = FORMAT(GETDATE(), 'yyyy-MM-dd') + ' 10:00:00';

SELECT Distinct
INS_InsurerName [Insurer],
POL_PolicyNumber [Policy Number],
CLM_ClaimNumber [Claim Number],
PRQ_ReferenceNumber [Payment Reference number],
PRQ_PayeeName [Payee Name],
CIT_PayeeName,
TransactionType [Transaction Type],
ATS_TransactionNumber [Transaction number],
CIT_TransactionTypeDescription [Payment Type],
CLM_BrokerAgentClaimNumber [Agent Claim Number],
PRD_Name [Product Name],
FORMAT(POL_OriginalStartDate, 'yyyy-MM-dd') [Policy Original Inception Date],
FORMAT(POL_StartDate, 'yyyy-MM-dd') [Policy Start Date],
FORMAT(POL_RenewalDate, 'yyyy-MM-dd') [Policy Renewal Date],
POL_FinanceTerm_ID [Policy Term],
CLI_NatureOfBusiness [Line of Business],
PDS_Description [Section],
ItemDescription [Cover Descriptor],
Agent.Agt_Name [Broker Name],
(SELECT top 1 SRN_text
FROM SalesBranch, AgentDivisionLink
WHERE SalesRegion_ID = ADL_Division_ID
AND ADL_Agent_ID = POL_AGent_ID
AND SRN_Deleted = 0
Order by ADL_UpdateDate desc) [Broker Branch],
Agent.Agt_VATNumber [Broker VAT Number],
CASE WHEN CLI_ForeignIndicator = 0 THEN 'Local' ELSE 'Foreign' END [Risk Location],
FORMAT(EffectiveDate, 'yyyy-MM-dd') [Effective Date],
FORMAT(PostingDate, 'yyyy-MM-dd') [Transaction Date],
FORMAT(PRQ_Auth2Date, 'yyyy-MM-dd') [Date Released to Hyphen],
CASE WHEN HPA_Reversed = 1 THEN 'Yes' ELSE 'No' END [Transaction Reversed],
--TransactionType [Transaction Type],
CIS_SumInsured [Sum Insured],
HPA_TransactionAmount [Hyphen Amount],
CIT_Discount [Settlement Discount],

---CIT_Amount [Gross Claims Paid],
---CIT_AmountVAT [Claims Paid VAT],
--''[Nett Amount],
--Sum(Case When CIT_AmountVAT > 0 Then CIT_Amount Else (CIT_Amount - CIT_AmountVAT) End ) [Nett Amount],


--(Select ATN_VATAmount from Accounttransaction where 

ATN_GrossAmount [Gross Claims Paid],
(ATN_VATAmount) [Claims Paid VAT], 
(ATN_NettAmount) [Nett Amount],

--CASE WHEN Debit IS NULL THEN CreditNett ELSE DebitNett END [Gross Claims Paid],

--CASE WHEN (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END) = 0 AND INS_InsurerName = 'Discovery Insure' THEN - ATN_VATAmount
--WHEN (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END) = 0 AND INS_InsurerName <> 'Discovery Insure' THEN ATN_VATAmount
--ELSE (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END)
--END AS [Claims Paid VAT],

--CASE WHEN (CASE WHEN Debit IS NULL THEN Credit ELSE Debit END) >= (CASE WHEN Debit IS NULL THEN CreditNett ELSE DebitNett END) AND INS_InsurerName ='Discovery Insure'
--THEN (CASE WHEN Debit IS NULL THEN Credit ELSE Debit END) -+- (CASE WHEN (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END) = 0 THEN ATN_VATAmount
--ELSE (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END)
--END)
--WHEN (CASE WHEN Debit IS NULL THEN Credit ELSE Debit END) >=(CASE WHEN Debit IS NULL THEN CreditNett ELSE DebitNett END) AND INS_InsurerName <> 'Discovery Insure'
--THEN (CASE WHEN Debit IS NULL THEN Credit ELSE Debit END) - (CASE WHEN (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END) = 0 THEN ATN_VATAmount

--ELSE (CASE WHEN Debit IS NULL THEN ISNULL(CreditVAT,0) ELSE ISNULL(DebitVAT,0) END)
--END)
--ELSE (CASE WHEN Debit IS NULL THEN Credit ELSE Debit END)
--END AS [Nett Amount],


FORMAT(EffectiveDate, 'MMM') [Effective Month],
CLM_ClaimNumber [Master Claim Number],
'' [Risk Item Number],
--PRD_Name [Product],
CTI_Description [Risk Item Type],
--CASE WHEN
--(SELECT PolicyCoInsuredLink_ID FROM PolicyCoInsuredLink WHERE PCL_Policy_ID = Policy_ID) > 0 THEN
--1 ELSE 0 END [Co-Insurance Indicator],
--'' [Co-Insurance Percentage],

(SELECT TOP 1 CONCAT(ADD_Line1 + ' ', ADD_Line2 + ' ', ADD_City + ' ') FROM AddressDetails WHERE ADD_ReferenceNumber = CIS_ClaimItem_ID ORDER BY ADD_Default DESC) [Risk Address],
(SELECT TOP 1 ADD_Code FROM AddressDetails WHERE ADD_ReferenceNumber = CIS_ClaimItem_ID ORDER BY ADD_Default DESC) [Risk Address Postal Code],
RTF_Description [Policy Payment Frequency],
FORMAT(POL_StartDate, 'yyyy-MM-dd') [Policy Current Inception Date],
FORMAT(POL_MaturityDate, 'yyyy-MM-dd') [Policy Maturity Date],
FORMAT(CIS_LossDate, 'yyyy-MM-dd') [Date of Loss],
FORMAT(POL_SignedDate, 'yyyy') [Underwriting Year],
FORMAT(CLM_CreateDate,'yyyy-MM-dd') [Claim Date Reported],
CLS_Description [Claim Status],
'' [Claim Cause Catastrophe Code],
'Rand' [Policy Currency Claim currency],
'Rand' [Sum Insured currency],
Round(((CIS_SumInsured / (100 + @VAT)) * @VAT), 2) [Sum Insured VAT],
--[Original Estimate],
--Round((([Original Estimate] / (100 + @VAT)) * @VAT), 2) [Original Estimate VAT],
--[Total Outstanding] [Gross Claim Outstanding],
--Round((([Total Outstanding] / (100 + @VAT)) * @VAT), 2) [Gross Claim Outstanding VAT],
'' [Third Party Damage Estimate],

--IIF((CIT_PayeeID) = 2, 'Insurer', PartyType) [Claim Payment Party Type],
--Party [Payee Name],
--''[Claim Payment Party Type],


IIF(CIT_TransactionTypeDescription = 'Client Payment', 'Indemnity Payment',
IIF(CIT_TransactionTypeDescription = 'Supplier Payment', 'Trade Payment',
IIF(CIT_TransactionTypeDescription = 'Supplier Payment| Ex-Gratia', 'Trade Payment',
IIF(CIT_TransactionTypeDescription = 'Third Party Payment', 'Trade Payment',

CIT_TransactionTypeDescription)))) [Payment Type Description],
 --''[Payment Type],

CellCaptive [Cell captive],
(Select top 1 CIC_Description from ClaimItemComponents where CIC_ClaimItem_ID = CIS_ClaimItem_ID)  [Risk Type],
PYS_Description [Payment Status]

from PaymentRequisition--HyphenPayment

Left join HyphenPayment on HPA_PaymentRequisition_ID = PaymentRequisition_Id

--Inner JOIN PaymentRequisition ON PaymentRequisition_Id = CIT_Payment_ID
--Inner JOIN PaymentRequisition ON PaymentRequisition_Id = HPA_PaymentRequisition_ID

Inner JOIN ClaimItemTransaction ON PaymentRequisition_Id = CIT_Payment_ID
inner join PaymentStatus on PaymentStatus_ID = PRQ_Status
Inner JOIN vw_AccountViewer on TransactionSetID = CIT_Set_ID
Inner JOIN ClaimItemSummary on CIS_ClaimItem_ID = CIT_ClaimItem_ID
Inner JOIN Claim ON CIS_Claim_ID = Claim_ID
LEFT JOIN Policy ON Policy_ID = CLM_Policy_ID
left join ReferenceClaimType on ReferenceClaimType_ID = CIS_ClaimType_ID
left join ReferenceClaimstatus on ClaimStatus_ID = CLM_Status
LEFT join AccountTransactionSet on CIT_Set_ID = AccountTransactionSet_Id
LEFT join AccountTransaction on AccountTransactionSet_Id = ATN_AccountTransactionSet_ID and ATN_DisbursementStep = 1
Left join AccountTransactionType on AccounttransactionType_Id = ATS_AccountTransactionType_ID
left JOIN vw_POL_GetPolicyItems on Policy_ID = PolicyID AND ItemDeleted = 0
left JOIN ProductSection ON ProductSection_Id = cis_section_id AND PDS_Deleted = 0
LEFT JOIN Client ON Client_ID = POL_Client_ID
LEFT JOIN Product ON Product_Id = POL_Product_ID
LEFT JOIN ReferenceTermFrequency ON TermFrequency_ID = POL_PaymentFrequency_ID
LEFT JOIN PolicyInsurerLink on Policy_ID = PIL_Policy_ID
LEFT JOIN Insurer on Insurer_Id = PIL_Insurer_ID
LEFT JOIN Agent ON Agent_id = POL_PrimaryAgent_ID
LEFT JOIN AgentDivisionLink ON ADL_Agent_ID = POL_PrimaryAgent_ID
LEFT JOIN SalesBranch ON SalesBranch.SalesRegion_ID = ADL_Division_ID

--left join ReferenceGLCode Main on ATN_GLCode_ID = Main.GlCode_ID
--left join ReferenceGLCode VAT on ATN_GLCodeVAT_ID = VAT.GlCode_ID

Where AccountPartyTypeId in (1, 502, 203)
And CIT_IsReversed in (0,1)
--and CIT_Amount <> 0
and CIT_TransactionType_ID = 2
and PaymentStatus_ID = 5
--and ATN_GrossAmount <> 0
and CIT_Deleted = 0
--and ATN_GLCode_ID = 414
--and CIT_TransactionTypeDescription not like ('%Reversal%')


--and INS_InsurerName = 'Discovery Insure'

--and CLM_ClaimNumber in ('SWTY023109CLM','HADC019687CLM','DWA017750CLM')


--and CLM_ClaimNumber in ('HADC019454CLM','DWA014891CLM','DWA019491CLM','HWTY018209CLM','DWA014891CLM',
--'DWA017750CLM',
--'DWA019397CLM',
--'DWA019417CLM',
--'DWA019491CLM')


--AND HPA_CreateDate >= ('29 Nov 2023 00:00:00')
--AND HPA_CreateDate  <= DATEADD(ss, -1, DATEADD(Day, 1, (replace('2 Dec 2023 00:00:00','00:00:00','23:59:59'))  )) 

{ScheduleDate}
{StartDate}
{EndDate}

Order by CLM_ClaimNumber



