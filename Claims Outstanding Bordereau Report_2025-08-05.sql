DECLARE @VAT int = 15;
SELECT Distinct
INS_InsurerName [Insurer],
POL_PolicyNumber [Policy Number],
PRD_Name [Product Name],
FORMAT(POL_OriginalStartDate, 'yyyy-MM-dd') [Policy Original Inception Date],
FORMAT(POL_StartDate, 'yyyy-MM-dd') [Policy Start Date],
FORMAT(POL_RenewalDate, 'yyyy-MM-dd') [Policy Renewal Date],
POL_FinanceTerm_ID [Policy Term],
CLI_NatureOfBusiness [Line of Business],
PDS_Description [Section],
ItemDescription [Cover Descriptor],
Agent.Agt_Name [Broker Name],
SalesBranch.SRN_Text [Broker Branch],
(
CASE WHEN dbo.fnc_AgentFSPVATDetail_VATRegistered(Agent.Agent_id,getdate()) = 1 THEN
dbo.fnc_AgentFSPVATDetail_VATNumber(Agent.Agent_id,getdate())
WHEN (SELECT top 1 ADD_Country FROM AddressDetails WHERE ADD_ReferenceNumber = Agent_Id ORDER BY ADD_Default DESC) != 1 THEN
'Not Vat'
ELSE 'Foeign' END
) [Broker VAT Number],
CASE WHEN CLI_ForeignIndicator = 0 THEN 'Local' ELSE 'Foreign' END [Risk Location],
CIS_SumInsured [Sum Insured],
FORMAT(EffectiveDate, 'yyyy-MM-dd') [Effective Date],
FORMAT(PostingDate, 'yyyy-MM-dd') [Transaction Date],
TransactionType [Transaction Type],
CASE WHEN Debit IS NULL THEN CreditNett ELSE DebitNett END [Gross Claims Paid Excluding VAT],
CASE WHEN Debit IS NULL THEN CreditVAT ELSE DebitVAT END [Gross Claims Paid VAT],
CASE WHEN Debit IS NULL THEN Credit ELSE Debit END [Gross Claims Paid Including VAT],

CLM_ClaimNumber [Claim Number],
FORMAT(EffectiveDate, 'MMM') [Effective Month],
CLM_ClaimNumber [Master Claim Number],
'' [Risk Item Number],
PRD_Name [Product],
CTI_Description [Risk Item Type],
CASE WHEN
(SELECT PolicyCoInsuredLink_ID FROM PolicyCoInsuredLink WHERE PCL_Policy_ID = Policy_ID) > 0 THEN
1 ELSE 0 END [Co-Insurance Indicator],
'' [Co-Insurance Percentage],
(SELECT TOP 1 CONCAT(ADD_Line1 + ' ', ADD_Line2 + ' ', ADD_City + ' ') FROM AddressDetails WHERE ADD_ReferenceNumber = CIS_ClaimItem_ID ORDER BY ADD_Default DESC) [Risk Address],
(SELECT TOP 1 ADD_Code FROM AddressDetails WHERE ADD_ReferenceNumber = CIS_ClaimItem_ID ORDER BY ADD_Default DESC) [Risk Address Postal Code],
RPF_Description [Policy Payment Frequency],
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
[Original Estimate],
Round((([Original Estimate] / (100 + @VAT)) * @VAT), 2) [Original Estimate VAT],
[Total Outstanding] [Gross Claim Outstanding],
Round((([Total Outstanding] / (100 + @VAT)) * @VAT), 2) [Gross Claim Outstanding VAT],
'' [Third Party Damage Estimate],
IIF(Dbo.CheckPayeeTypeForFinanceHouse(CIT_PayeeID) = 2, 'Insurer', PartyType) [Claim Payment Party Type],
Party [Payee Name],
IIF(
Dbo.CheckPayeeTypeForFinanceHouse(CIT_PayeeID) = 1, 'Indemnity Payment',
IIF(Dbo.CheckPayeeTypeForFinanceHouse(CIT_PayeeID) = 2, 'Premium Recovery',
IIF(CIT_TransactionTypeDescription = 'Client Payment', 'Indemnity Payment',
IIF(CIT_TransactionTypeDescription = 'Supplier Payment', 'Trade Payment',
CIT_TransactionTypeDescription)
)
)
) [Payment Type],
PaymentStatus.PYS_Description [Payment Status],
CellCaptive [Cell captive] from ClaimItemTransaction
LEFT JOIN PaymentRequisition ON PaymentRequisition_Id = CIT_Payment_ID
left join vw_AccountViewer on TransactionSetID = CIT_Set_ID
left join ClaimItemSummary on CIS_ClaimItem_ID = CIT_ClaimItem_ID
left JOIN Claim ON CIS_Claim_ID = Claim_ID
LEFT JOIN Policy ON Policy_ID = CLM_Policy_ID
left join ReferenceClaimType on ReferenceClaimType_ID = CIS_ClaimType_ID
left join ReferenceClaimstatus on ClaimStatus_ID = CLM_Status
LEFT JOIN (
Select
SUM(CASE WHEN CIT_TransactionType_ID = 0 THEN CIT_Amount ELSE 0 END) [Original Estimate],
SUM(CASE WHEN CIT_TransactionType_ID = 2 THEN CIT_Amount ELSE 0 END) [Payments],
SUM(CASE WHEN CIT_TransactionType_ID = 3 THEN CIT_Amount ELSE 0 END) [Recoveries],
CIS_Claim_ID [CISClaimID]
from ClaimItemTransaction
Left join ClaimItemSummary ON ClaimItemTransaction.CIT_ClaimItem_ID = ClaimItemSummary.CIS_ClaimItem_ID
Where CIS_ClaimType_ID IN ('1')
group by CIT_Deleted,CIS_Claim_ID
HAVING CIT_Deleted = 0
) Payments ON Payments.CISClaimID = Claim_ID
LEFT JOIN (
Select
SUM(CASE WHEN CIS_ClaimType_ID in ('1') THEN CIS_Estimate ELSE 0 END) [Total Estimate],
SUM(CASE WHEN CIS_ClaimType_ID in ('1') THEN CIS_OutstandingEstimate ELSE 0 END) [Total Outstanding],
SUM(CASE WHEN CIS_ClaimType_ID in ('2','3','4') THEN CIS_Estimate ELSE 0 END) [Recovery Estimate],
CIS_Claim_ID [CISClaimID]
FROM CLAIMITEMSUMMARY
GROUP BY CIS_Deleted,CIS_Claim_ID
HAVING CIS_Deleted = 0
) Totals ON Totals.CISClaimID = Claim_ID
left JOIN vw_POL_GetPolicyItems on Policy_ID = PolicyID AND ItemDeleted = 0
left JOIN ProductSection ON ProductSection_Id = cis_section_id AND PDS_Deleted = 0
LEFT JOIN Client ON Client_ID = POL_Client_ID
LEFT JOIN Product ON Product_Id = POL_Product_ID
LEFT JOIN ReferencePaymentFrequency ON ReferencePaymentFrequency_ID = POL_PaymentFrequency_ID
LEFT JOIN PolicyInsurerLink on Policy_ID = PIL_Policy_ID
LEFT JOIN Insurer on Insurer_Id = PIL_Insurer_ID
Left join InsurerGroupLink on IGL_Insurer_Id = Insurer_Id
-- Broker Data
LEFT JOIN Agent ON Agent_id = POL_PrimaryAgent_ID
LEFT JOIN AgentDivisionLink ON ADL_Agent_ID = POL_PrimaryAgent_ID
LEFT JOIN SalesBranch ON SalesBranch.SalesRegion_ID = ADL_Division_ID
LEFT JOIN (
SELECT Distinct Arrangement_Id, ARA_Agent_ID, ARP_Product_ID, ARA_Commission_Percentage, ARA_Fee_Percentage FROM Arrangement
LEFT JOIN ArrangementAgents ON ARA_Arrangement_ID = Arrangement_Id
LEFT JOIN ArrangementProduct ON ARP_Arrangement_Id = Arrangement_Id
WHERE ARG_Deleted = 0
AND ARA_Deleted = 0
AND ARP_Deleted = 0
AND ARA_Commission_Percentage > 0
AND ARA_Fee_Percentage > 0
) Arrangement ON ARA_Agent_ID = Agent_Id AND ARP_Product_ID = POL_Product_ID
LEFT JOIN PaymentStatus on PaymentStatus_ID = PRQ_Status
Where PRQ_Status not in (5, 4)
AND Reversed = 'No' AND CIT_IsReversed = 0
And partytype in (
Select apt_description from accountpartytype where accountpartytype_id in (1, 502, 203)
)

{TransactionType}
{Insurer}
--{ScheduleDate}
{FromDate}
{ToDate}
{InsurerGroup}
