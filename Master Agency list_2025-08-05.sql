/*

Report Name: Master Agency list

Developer:                  Petunia  Mpe        
Modification Date:          2023-06-06
MSU:                        MSU020043 
MSU:                        MSU020034
Modification Date:          2024-05-28
MSU:                        MSU023549
Modification Date:          2024-06-25
MSU:                        MSU023841

Developer:                  Julian Parker      
Modification Date:          2024-08-27
MSU:                        MSU024536
*/


select * 
into #AgentDivisionLink
from 
(
select *
, ROW_NUMBER() OVER(PARTITION BY ADL_Agent_ID ORDER BY ADL_CreateDate DESC)     AS Row#
from AgentDivisionLink 
)X
WHERE X.Row# = 1

select * 
into #vw_BankDetails 
from 
(
select *
, ROW_NUMBER() OVER(PARTITION BY BNK.ReferenceNumber ORDER BY b.BNK_CreateDate  DESC)     AS Row#
from vw_BankDetails bnk   
left join BankDetails b on bnk.BankDetialsId = b.BankDetails_id
and BNK.BankType = 'Commission' 
)X
WHERE X.Row# = 1


select * 
into #AgentConsultantLink
from 
(
select *
, ROW_NUMBER() OVER(PARTITION BY ACL_Agent_ID ORDER BY ACL_CreateDate DESC)     AS Row#
from AgentConsultantLink
)X
WHERE X.Row# = 1



SELECT --TOP 10
INSURER,PRODUCT_GROUP,AGENT_CATEGORY, SUB_AGENT_NAME,REGISTERED_NAME, SUB_AGENT_CODE, ARRANGEMENT_NUMBER, DIVISION,DIVISION_STARTDATE, SALES_BRANCH, SUBAGENTFSP_NUMBER,FSP_NUMBER_START_DATE,
CELL_CAPTIVE_NAME, FRANCHISE_GROUP, AGREEMENT_GROUPING, PRIMARY_AGENT_NAME,  
PRIMARY_AGENT_CODE, AGENT_TYPE, ARRANGEMENT_TYPE, AGENT_STATUS, 
AGENT_START_DATE, AGENT_END_DATE, Agt_FidelityGuaranteeExpiryDate [FIDELITY_GUARANTEE_EXPIRY_DATE],
case when (SUM(VAPS_COUNT) + SUM(LIFE_POLICY_COUNT)) > 0 then 'Y' else 'N' end POLICY_INDICATOR, 

 

SUM(VAPS_COUNT) VAPS_COUNT, 
SUM(LIFE_POLICY_COUNT) LIFE_POLICY_COUNT, 
SUM(WARRANTY_POLICY_COUNT) WARRANTY_POLICY_COUNT,
SUM(VAPS_COUNT) + SUM(LIFE_POLICY_COUNT) + SUM(WARRANTY_POLICY_COUNT) TOTAL_ACTIVE_COUNT,
FORMAT(MAX(IIF(isnull(LAST_INCEPT_VAPS,'01/01/1999') > isnull(LAST_INCEPT_LIFE,'01/01/1999'), LAST_INCEPT_VAPS, LAST_INCEPT_LIFE)),'dd/MM/yyyy') LAST_INCEPT_ALL, 
FORMAT(MAX(LAST_INCEPT_VAPS),'dd/MM/yyyy') LAST_INCEPT_VAPS,
FORMAT(MAX(LAST_INCEPT_LIFE),'dd/MM/yyyy') LAST_INCEPT_LIFE,
FORMAT(MAX(LAST_INCEPT_WARRANTY),'dd/MM/yyyy') LAST_INCEPT_WARRANTY,
SUM(MONTHLY_ONLY_VAPS) MONTHLY_ONLY_VAPS,
SUM(ANNUAL_ONLY_VAPS) ANNUAL_ONLY_VAPS, 
SUM(TERM_ONLY_VAPS) TERM_ONLY_VAPS,
SUM(MONTHLY_ONLY_LIFE) MONTHLY_ONLY_LIFE, 
SUM(ANNUAL_ONLY_LIFE)ANNUAL_ONLY_LIFE, 
SUM(TERM_ONLY_LIFE) TERM_ONLY_LIFE,
SUM(MONTHLY_ONLY_WARRANTY) MONTHLY_ONLY_WARRANTY,
SUM(ANNUAL_ONLY_WARRANTY) ANNUAL_ONLY_WARRANTY,
SUM(TERM_ONLY_WARRANTY) TERM_ONLY_WARRANTY,
FACTOR_SUB, FACTOR_GROUP_SUB, 
SALE_CESSION, SIGNED_TRI_PARTY, 
SIGNED_RATE_ANNEXURE, 
Agt_FidelityGuaranteeExpiryDate [FIDELITY_GUARANTEE_EXPIRY_DATE], 
AGT_pspReviewDate [PSP_REVIEW_DATE], 
AGT_ProfessionalIndemnityExpiryDate [PROFESSIONAL_INDEMNITY_EXPIRY_DATE], 
VAT_NUMBER, VAT_VENDOR,
VAT_NUMBER_START_DATE,
PAY_ON_RECEIPT,
[PROFIT_SHARE_DEALER_%],
[PROFIT_SHARE_MSURE_%],
PROFIT_SHARE_FROM_DATE,
PROFIT_SHARE_TO_DATE,
AGREEMENT_DATE,
BANK_NAME, ACCOUNT_NAME, BANK_ACCOUNT_NUMBER, ACCOUNT_TYPE, BANK_BRANCH_ID, BANK_BRANCH_NAME,
AGENT_OPTION, GUARANTEE_YES_NO, GUARANTEE_NUMBER, GUARANTEE_EXPIRY_DATE, 
OLD_RIMS_SUB_AGENT_NUMBER, OLD_TIA_AGENT_NUMBER, EDI_DEALER_SOURCE_CODE, EDI_DEALER_CODE,
WW_DEALER_NUMBER,
OMI_Reference_Number,
CONTRACT_CODE, SPLIT_PREMIUM_YES_NO, 
LAPSE_LIMIT_CONSECUTIVE, 
LAPSE_LIMIT_INTERMITTENT,
[UNMET_LIMIT_CONSECUTIVE],
[UNMET_LIMIT_INTERMITTENT],
CREDIT_CONTROLLER_ST, CREDIT_CONTROLLER_LIFE,
--COMMISSION_SPLIT,
--BROKER_FEE_SPLIT,
[BROKER_FEE],
[COMMISSION_FEE],
[INSPECTION_FEE],
SALES_CONSULTANT,CONSULTANT_STARTDATE, COMPANY_REG_NO, CUSTOM_COMMISSION,
[BURN_RATE_%],
[ARRANGEMENT_CREATE_DATE],
[AGENT_CREATE_DATE],
[AGENT_UPDATE_DATE],
[AGENT_UPDATED_BY] ,
[ARRANGEMENT_UPDATE_DATE],
[ARRANGEMENT_UPDATED_BY]
From (
select distinct --top 10 
PrimaryAgents.AGT_pspReviewDate, PrimaryAgents.AGT_ProfessionalIndemnityExpiryDate, 
PrimaryAgents.Agt_FidelityGuaranteeExpiryDate,
SubAgents.Agt_Name As SUB_AGENT_NAME, 
SubAgents.Agt_RegisteredName AS REGISTERED_NAME,
SubAgents.Agt_AgentNumber As SUB_AGENT_CODE,
ARG_ArrangementNumber As ARRANGEMENT_NUMBER,
ISNULL(DIV.SRN_Text,'') DIVISION,
ISNULL(BR.SRN_Text,'') SALES_BRANCH,
adl_Fromdate AS DIVISION_STARTDATE,
dbo.fnc_AgentFSPVATDetail_FSPNumber(PrimaryAgents.agent_id,getdate()) As FSP_NUMBER,
dbo.fnc_AgentFSPVATDetail_FSPNumber(SubAgents.agent_id,getdate()) As SubAGentFSP_NUMBER,
dbo.fnc_AgentFSPVATDetail_FSPFromDate(SubAgents.agent_id,getdate()) As FSP_NUMBER_START_DATE,
dbo.fnc_AgentFSPVATDetail_FSPFromDate(SubAgents.agent_id,getdate()) As VAT_NUMBER_START_DATE,

(Select RCC_Description
   from ReferenceCellCaptive
  where ReferenceCellCaptive_Code = ARG_CellCaptive) As CELL_CAPTIVE_NAME,
(select FGP_Description
   from ReferenceFranchiseGroups
  where FranchiseGroup_ID = SubAgents.Agt_FranchiseGroup) As FRANCHISE_GROUP,
AAG_Value As AGREEMENT_GROUPING,
PrimaryAgents.Agt_Name PRIMARY_AGENT_NAME,
PrimaryAgents.Agt_AgentNumber As PRIMARY_AGENT_CODE,
(SELECT ATY_Description FROM ReferenceAgentRevenueType WHERE ReferenceAgentRevenueType_ID = SubAgents.Agt_RevenueType) As AGENT_TYPE,
(case when ARA_Agent_ID = ARA_PrimaryAgent_ID then 'Primary' else 'Sub' end) As ARRANGEMENT_TYPE,
case when ISNULL(ARA_EndDate,'') = '' then 'Active' else 'Expired' end As AGENT_STATUS,
Format(ARA_StartDate,'dd/MM/yyyy') As AGENT_START_DATE,
Format(ARA_EndDate,'dd/MM/yyyy') As AGENT_END_DATE,

 

(select Count(Policy_ID)
from  policy,Product 
where POL_Agent_ID = SubAgents.Agent_Id
and POL_Product_ID = Product_Id 
and POL_Deleted = 0
and POL_Status = 1 
and PRD_Name not like '%Life%'
and Product_Id not in ('A4AF17CF-89D0-47AC-A447-F135310042D7','01A81AE2-8478-45FB-8C0D-5A6E796C1B39')
and PRD_ProductGroup_Id = 2) As VAPS_COUNT,

(select count(Policy_ID)
from  policy,product
where POL_Agent_ID = SubAgents.Agent_Id
and POL_Product_ID = Product_Id 
and POL_Deleted = 0
and POL_Status = 1 
and PRD_Name like '%Life%') As LIFE_POLICY_COUNT,

(select count(Policy_ID)
from  policy,Product 
WHere POL_Deleted = 0
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and POL_Product_ID = Product_Id 
and Product_Id in ('A4AF17CF-89D0-47AC-A447-F135310042D7','01A81AE2-8478-45FB-8C0D-5A6E796C1B39','20AA9350-3FD9-4FE7-B705-3E1CCD639F94'
,'219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF','83C026A9-17FF-4A87-9CA9-E82C2535B538','A4AF17CF-89D0-47AC-A447-F135310042D7')
--and PRD_ProductGroup_Id = 1
) As WARRANTY_POLICY_COUNT,

(Select Max(POL_OriginalStartDate)
FROM policy,product
Where POL_Deleted = 0 
--and POL_Status = 1
and POL_Product_ID = Product_Id    
and POL_Agent_ID = SubAgents.agent_id
and PRD_Name not like '%Life%'
and Product_Id <> 'A4AF17CF-89D0-47AC-A447-F135310042D7'
and PRD_ProductGroup_Id = 2
) As LAST_INCEPT_VAPS,	

(Select Max(POL_OriginalStartDate)  
from  policy,product
where POL_Agent_ID = SubAgents.Agent_Id
and POL_Product_ID = Product_Id 
and POL_Deleted = 0
and POL_Status = 1 
and PRD_Name like '%Life%') As LAST_INCEPT_LIFE,


(Select Max(POL_OriginalStartDate)  
FROM policy 
Where POL_Deleted =0
and POL_Status = 1
and POL_Agent_ID = SubAgents.agent_id
and Product_Id in ('A4AF17CF-89D0-47AC-A447-F135310042D7','01A81AE2-8478-45FB-8C0D-5A6E796C1B39','20AA9350-3FD9-4FE7-B705-3E1CCD639F94'
,'219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF','83C026A9-17FF-4A87-9CA9-E82C2535B538','A4AF17CF-89D0-47AC-A447-F135310042D7')
--and PRD_ProductGroup_Id = 1
)As LAST_INCEPT_WARRANTY,


 (select Count(Policy_ID)
from policy,product
where POL_Agent_ID = SubAgents.Agent_Id
and POL_Product_ID = Product_Id 
and POL_Deleted = 0 
and POL_Status = 1 
and PRD_Name not like '%Life%'
and PRD_ProductGroup_Id = 2
and Product_Id <> 'A4AF17CF-89D0-47AC-A447-F135310042D7'
and POL_ProductTerm_ID = 4) As MONTHLY_ONLY_VAPS,

(select Count(Policy_ID)
from policy,product
where POL_Agent_ID = SubAgents.Agent_Id
and POL_Product_ID = Product_Id 
and POL_Deleted = 0 
and POL_Status = 1 
and PRD_Name not like '%Life%'
and PRD_ProductGroup_Id = 2
AND POL_ProductTerm_ID = 6) As ANNUAL_ONLY_VAPS,

(select  Count(Policy_ID)
from policy,product
where POL_Agent_ID = SubAgents.Agent_Id
and POL_Product_ID = Product_Id 
and POL_Deleted = 0 
and POL_Status = 1 
and PRD_Name not like '%Life%'
and POL_ProductTerm_ID not in (4, 6)
and Product_Id <> 'A4AF17CF-89D0-47AC-A447-F135310042D7'
and PRD_ProductGroup_Id = 2
) As TERM_ONLY_VAPS,

 

(select count(PCI_Policy_ID) 
from PolicyCreditLifeItem, policy
WHere PCI_Policy_ID = Policy_ID 
and PCI_Deleted = 0 
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and PRD_Name like '%Life%'
AND POL_ProductTerm_ID = 4)  As MONTHLY_ONLY_LIFE,


(select count(PCI_Policy_ID) 
from PolicyCreditLifeItem, policy
WHere PCI_Policy_ID = Policy_ID 
and PCI_Deleted = 0 
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and PRD_Name like '%Life%'
AND POL_ProductTerm_ID = 6) As ANNUAL_ONLY_LIFE,

(select count(PCI_Policy_ID) 
from PolicyCreditLifeItem, policy
WHere PCI_Policy_ID = Policy_ID 
and PCI_Deleted = 0 
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and PRD_Name like '%Life%'
AND POL_ProductTerm_ID not in (4, 6)) As TERM_ONLY_LIFE,

 
 

(select count(Policy_ID) 
from  policy
WHere POL_Deleted = 0
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and Product_Id in ('A4AF17CF-89D0-47AC-A447-F135310042D7','01A81AE2-8478-45FB-8C0D-5A6E796C1B39','20AA9350-3FD9-4FE7-B705-3E1CCD639F94'
,'219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF','83C026A9-17FF-4A87-9CA9-E82C2535B538','A4AF17CF-89D0-47AC-A447-F135310042D7')
AND POL_ProductTerm_ID = 6)  As ANNUAL_ONLY_WARRANTY,



(select count(Policy_ID) 
from  policy
WHere POL_Deleted = 0
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and Product_Id in ('A4AF17CF-89D0-47AC-A447-F135310042D7','01A81AE2-8478-45FB-8C0D-5A6E796C1B39','20AA9350-3FD9-4FE7-B705-3E1CCD639F94'
,'219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF','83C026A9-17FF-4A87-9CA9-E82C2535B538','A4AF17CF-89D0-47AC-A447-F135310042D7')
AND POL_ProductTerm_ID not in (4, 6))  As TERM_ONLY_WARRANTY,


(select count(Policy_ID) 
from  policy
WHere POL_Deleted = 0
and POL_Status = 1 
and POL_Agent_ID = SubAgents.agent_id 
and Product_Id in ('A4AF17CF-89D0-47AC-A447-F135310042D7','01A81AE2-8478-45FB-8C0D-5A6E796C1B39','20AA9350-3FD9-4FE7-B705-3E1CCD639F94'
,'219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF','83C026A9-17FF-4A87-9CA9-E82C2535B538','A4AF17CF-89D0-47AC-A447-F135310042D7')
AND POL_ProductTerm_ID = 4)  As MONTHLY_ONLY_WARRANTY,

(case when SubAgents.Agt_FactoredCommission = 1 then 'Yes' else 'No' end ) as FACTOR_SUB,
(select  AFG_Description 
  from ReferenceFactoringGroups 
 where ReferenceFactoringGroup_ID = SubAgents.Agt_FactoringGroup 
) As FACTOR_GROUP_SUB,
Case when SubAgents.Agt_SignedSaleAndSession = 1 then 'Yes' else 'No' end SALE_CESSION,   
Case when SubAgents.Agt_SignedTriPartyAgreement = 1 then 'Yes' else 'No' end SIGNED_TRI_PARTY,   
Case when SubAgents.Agt_SignedRateAnnexure = 1 then 'Yes' else 'No' end SIGNED_RATE_ANNEXURE,    
dbo.fnc_AgentFSPVATDetail_VATNumber(SubAgents.agent_id,getdate()) VAT_NUMBER, 
(case when dbo.fnc_AgentFSPVATDetail_VATRegistered(SubAgents.agent_id,getdate()) = 1 then 'Yes' else 'No' end) as VAT_VENDOR,
BNK.BankType as BANK_TYPE,
BNK.Bank As BANK_NAME,
BNK.AccountHolder As ACCOUNT_NAME,
BNK.MaskedAccountNo As BANK_ACCOUNT_NUMBER,
BNK.AccountType As ACCOUNT_TYPE,
BNK.BranchCode As BANK_BRANCH_ID,
BNK.Branch As BANK_BRANCH_NAME,
(select  ATY_Description from ReferenceAgentType
Where ReferenceAgentType_ID = SubAgents.Agt_Type) As AGENT_OPTION,
Case when SubAgents.Agt_GuaranteeInd = 1 then 'Yes' else 'No' end As GUARANTEE_YES_NO,
SubAgents.Agt_GuaranteeNumber As GUARANTEE_NUMBER,
Format(SubAgents.Agt_GuaranteeExpiryDate,'dd/MM/yyyy')  As GUARANTEE_EXPIRY_DATE,
dbo.GetReferenceNumbers(SubAgents.Agent_Id, 501, 119) As OLD_RIMS_SUB_AGENT_NUMBER, 
dbo.GetReferenceNumbers(SubAgents.Agent_Id, 501, 118) As OLD_TIA_AGENT_NUMBER, 
dbo.GetReferenceNumbersType(SubAgents.Agent_Id, 501, Concat(120,',',102,',',106,',',110,',',114,',',121,',',130,',',134,',',138,',',144,',',145,',',157,',',158,',',161,',',162,',',163,',',164,',',165,',',166,',',167,',',168,',',169))  as EDI_DEALER_SOURCE_CODE,
dbo.GetReferenceNumbers(SubAgents.Agent_Id, 501, Concat(120,',',102,',',106,',',110,',',114,',',121,',',130,',',134,',',138,',',144,',',145,',',157,',',158,',',161,',',162,',',163,',',164,',',165,',',166,',',167,',',168,',',169))  as EDI_DEALER_CODE,
--dbo.GetReferenceNumbers(SubAgents.Agent_Id, 501, 218) As WW_DEALER_NUMBER,
WWDealerCode.SAWNumber as WW_DEALER_NUMBER,
OMIDealerCode.OMI_Reference_Number as OMI_Reference_Number,
(select EDA_Description 
from ReferenceEDIAction
where EDIAction_ID = SubAgents.Agt_EDIEdorsement_ID) As EDI_ACTION,
SubAgents.Agt_ContractCode As CONTRACT_CODE,
(case when SubAgents.Agt_SplitPremium_ID = 1 then 'Yes' else 'No' end) As SPLIT_PREMIUM_YES_NO,
SubAgents.Agt_LimitLapseConsecutive As LAPSE_LIMIT_CONSECUTIVE,
SubAgents.Agt_LimitIntermittent As LAPSE_LIMIT_INTERMITTENT,
(select USR_FirstName + ' ' + USR_Surname from SystemUsers
where Users_ID = SubAgents.Agt_CreditControllerShortTerm) As CREDIT_CONTROLLER_ST,
(select USR_FirstName + ' ' + USR_Surname from SystemUsers
where Users_ID = SubAgents.Agt_CreditControllerLife) As CREDIT_CONTROLLER_LIFE,
--ARA_Commission_Percentage As COMMISSION_SPLIT,
--ARA_Fee_Percentage As BROKER_FEE_SPLIT,
dbo.fnc_ArrangementAgentFee(SubAgents.Agent_Id,ARA_Arrangement_ID,1) as [BROKER_FEE],
dbo.fnc_ArrangementAgentFee(SubAgents.Agent_Id,ARA_Arrangement_ID,3) as [COMMISSION_FEE],
dbo.fnc_ArrangementAgentFee(SubAgents.Agent_Id,ARA_Arrangement_ID,2) as [INSPECTION_FEE],
SCO_Name + ' ' + SCO_Surname As SALES_CONSULTANT,
ACL_FromDate as CONSULTANT_STARTDATE,
SubAgents.Agt_RegisteredNumber As COMPANY_REG_NO,
[dbo].AgentCustomCommission(ARA_Arrangement_ID) As CUSTOM_COMMISSION,
(Select  IGY_Name from InsurerGroup where InsurerGroup_Id = SubAgents.agt_insurer) as INSURER,
--Add Profit Share Details
APS_DealerPerc as [PROFIT_SHARE_DEALER_%],
APS_MsurePerc as [PROFIT_SHARE_MSURE_%],
APS_FromDate as [PROFIT_SHARE_FROM_DATE],
APS_ToDate as [PROFIT_SHARE_TO_DATE],
APS_AgreementDate as [AGREEMENT_DATE],

--Add Product Group
(Select PDG_Description from ReferenceProductGroup where ProductGroup_id = SubAgents.Agt_ProductGroup) as PRODUCT_GROUP,
--Add Agent Category
(Select ACA_Description from ReferenceAgentCategory where ReferenceAgentCategory_ID = SubAgents.Agt_AgentCategory) as AGENT_CATEGORY,
--Added ConsecutiveUnmet
SubAgents.Agt_LimitUnmetConsecutive as [UNMET_LIMIT_CONSECUTIVE],
--Added Intermittent unmet
SubAgents.Agt_LimitUnmetIntermittent as [UNMET_LIMIT_INTERMITTENT],
--Added Agent Burn Rate%
SubAgents.Agt_BurnRatePerc [BURN_RATE_%],
ARG_CreateDate as [ARRANGEMENT_CREATE_DATE],
SubAgents.Agt_CreateDate as [AGENT_CREATE_DATE],
SubAgents.Agt_UpdateDate as [AGENT_UPDATE_DATE],
(Select Concat(usr_FirstName,' ',usr_SUrname)  from  SystemUsers where users_id =  SubAgents.Agt_UpdateUser_ID) as [AGENT_UPDATED_BY] ,
ARG_UpdateDate as [ARRANGEMENT_UPDATE_DATE],
(Select Concat(usr_FirstName,' ',usr_SUrname)  from  SystemUsers where users_id =  ARG_UpdateUser_ID) as [ARRANGEMENT_UPDATED_BY],

(CASE WHEN SubAgents.Agt_PayOnReceipt= 1 THEN 'Yes' ELSE 'No' END) AS PAY_ON_RECEIPT   -- MSU024536
	

from Agent PrimaryAgents, Agent SubAgents
        left join #AgentDivisionLink Adl ON adl.ADL_Agent_ID = SubAgents.Agent_Id and adl.ADL_Deleted = 0 and isnull(adl.ADL_ToDate,'') = ''
        left join SalesBranch Br ON (Adl.ADL_Division_ID = br.SalesRegion_ID ) 
        left join SalesBranch div ON (br.SRN_Parent_ID = div.SalesRegion_ID) 
        left join #AgentConsultantLink on ACL_Agent_ID = Agent_Id and isnull(ACL_ToDate,'') = ''
        Left join Salesconsultants on SalesConsultant_ID =ACL_Consultant_ID and SCO_Deleted = 0
		left join AgentProfitShareLink on APS_Agent_ID = Agent_Id and APS_Deleted = 0 and isnull(APS_TODate, '') =''
        left join AgentArrangementGroupLink on AAG_Agent_ID = SubAgents.Agent_Id AND AAG_Deleted = 0
        left join #vw_BankDetails bnk on  BNK.ReferenceNumber = SubAgents.Agent_Id and BNK.BankType = 'Commission' 
		Left join (select RNR_Number SAWNumber ,RNR_ItemReferenceNumber
from ReferenceNumber as RNR
inner join [ReferenceNumberType] as RNT on RNR.RNR_NumberType_Id = RNT.ReferenceNumberType_Id
where RNT_Description = 'SAW Dealer Code'
and RNR_ItemType_Id = 501
) as WWDealerCode on WWDealerCode.RNR_ItemReferenceNumber = SubAgents.Agent_Id 
left join (select RNR_Number OMI_Reference_Number,RNR_ItemReferenceNumber from 	ReferenceNumber [RNR]
			inner join ReferenceNumberType [RNT] on [RNT].RNT_Deleted = 0 AND [RNT].ReferenceNumberType_Id = RNR.RNR_NumberType_Id
		where
			[RNR].RNR_Deleted = 0
			and RNT_Description = 'OMI TIA Agent Number'
			and  RNR_ItemType_Id = 501
	) [OMIDealerCode] ON [OMIDealerCode].RNR_ItemReferenceNumber = SubAgents.Agent_Id
	,
        ArrangementAgents
        left join Arrangement AR on ARA_Arrangement_ID = AR.Arrangement_ID
        left join ArrangementProduct on AR.Arrangement_ID = ARP_Arrangement_ID AND ARP_Deleted = 0
        Inner join Product pr on ARP_Product_ID = pr.Product_Id AND PRD_Deleted = 0
        left join ArrangementCommission on ARC_ArrangementProduct_Id = ARRANGEMENTPRODUCT_Id and ARC_Deleted = 0
	   	
Where  ArrangementAgents.ARA_PrimaryAgent_ID = PrimaryAgents.Agent_Id
       AND ArrangementAgents.ARA_Agent_ID = SubAgents.Agent_Id
       AND ARA_Deleted = 0
       AND ARA_Arrangement_ID = Ar.Arrangement_Id
       AND ARA_Agent_ID <> ''
       AND PrimaryAgents.Agt_Deleted = 0
       AND SubAgents.Agt_Deleted = 0
	   --AND SubAgents.Agt_Name  =  '1st Auto Car Sales (Pty) Ltd (Nett)'
       --AND SubAgents.Agt_AgentNumber in (6143)  

) E
group by SUB_AGENT_NAME,SUB_AGENT_CODE,REGISTERED_NAME, AGT_pspReviewDate, AGT_ProfessionalIndemnityExpiryDate,
ARRANGEMENT_NUMBER,DIVISION,DIVISION_STARTDATE,SALES_BRANCH,FSP_NUMBER,SubAgentFSP_NUMBER,
CELL_CAPTIVE_NAME,FRANCHISE_GROUP,AGREEMENT_GROUPING,PRIMARY_AGENT_NAME,
PRIMARY_AGENT_CODE,AGENT_TYPE,ARRANGEMENT_TYPE,AGENT_STATUS, AGENT_START_DATE, AGENT_END_DATE,
FACTOR_SUB,FACTOR_GROUP_SUB,SALE_CESSION, SIGNED_TRI_PARTY,SIGNED_RATE_ANNEXURE,
VAT_NUMBER,VAT_VENDOR,BANK_NAME,ACCOUNT_NAME, BANK_ACCOUNT_NUMBER, ACCOUNT_TYPE, BANK_BRANCH_ID,BANK_BRANCH_NAME,--BANK_TYPE,  
AGENT_OPTION, GUARANTEE_YES_NO, GUARANTEE_NUMBER, GUARANTEE_EXPIRY_DATE, OLD_RIMS_SUB_AGENT_NUMBER, OLD_TIA_AGENT_NUMBER,
EDI_DEALER_SOURCE_CODE, EDI_DEALER_CODE,OMI_Reference_Number, CONTRACT_CODE, SPLIT_PREMIUM_YES_NO, LAPSE_LIMIT_CONSECUTIVE, LAPSE_LIMIT_INTERMITTENT,  
[UNMET_LIMIT_CONSECUTIVE],
[UNMET_LIMIT_INTERMITTENT],
CREDIT_CONTROLLER_ST, CREDIT_CONTROLLER_LIFE, 
--COMMISSION_SPLIT, 
--BROKER_FEE_SPLIT,
[BROKER_FEE],
[COMMISSION_FEE],
[INSPECTION_FEE],
SALES_CONSULTANT,CONSULTANT_STARTDATE, COMPANY_REG_NO, CUSTOM_COMMISSION,
CUSTOM_COMMISSION,INSURER, Agt_FidelityGuaranteeExpiryDate,
[PROFIT_SHARE_DEALER_%],
[PROFIT_SHARE_MSURE_%],
PROFIT_SHARE_FROM_DATE,
PROFIT_SHARE_TO_DATE,
AGREEMENT_DATE,
[BURN_RATE_%],AGENT_CATEGORY, PRODUCT_GROUP,WW_DEALER_NUMBER,
[ARRANGEMENT_CREATE_DATE],
[AGENT_CREATE_DATE],
[AGENT_UPDATE_DATE],
[AGENT_UPDATED_BY] ,
[ARRANGEMENT_UPDATE_DATE],
[ARRANGEMENT_UPDATED_BY],
FSP_NUMBER_START_DATE,
VAT_NUMBER_START_DATE,
LAST_INCEPT_VAPS
,PAY_ON_RECEIPT


drop table #AgentDivisionLink
drop table #vw_BankDetails
drop table #AgentConsultantLink



