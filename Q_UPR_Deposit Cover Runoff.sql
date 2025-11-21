---Deposit Cover Runoff
Use [Evolve]
Go

select distinct Acc_Mth, sum(total) earned from (
select 
pol_policynumber,
(select ReferenceCellCaptive.RCC_Description from ReferenceCellCaptive where ReferenceCellCaptive.ReferenceCellCaptive_Code = ATS_CellCaptive_Id) [RCC_Description],
(select ReferenceCellCaptive.RCC_GLCode from ReferenceCellCaptive where ReferenceCellCaptive.ReferenceCellCaptive_Code = ATS_CellCaptive_Id) [RCC_GLCode],
(select PRD_Name from Product where Product_Id = ATS_Product_Id ) [Product],
year(ATS_EffectiveDate) * 100 + month(ATS_EffectiveDate) as Acc_Mth,
ATN_NettAmount [Total]
from AccountTransactionSet,AccountTransaction, policy
where ATN_AccountParty_ID = '9667AD02-B0A9-456C-8D4A-55FC1F1FB6DA'
and ATN_AccountTransactionSet_ID = AccountTransactionSet_id
and ATS_EffectiveDate >= '2025-10-01'
and POL_CreateDate < '2025-10-01'
and POL_Status = 1
and ATS_DisplayNumber = POL_PolicyNumber
and (select PRD_Name from Product where Product_Id = ATS_Product_Id ) in ('Auto Pedigree Plus Plan with Deposit Cover'/*,'Paint Tech'*/)
) t
group by Acc_Mth
order by Acc_Mth;


