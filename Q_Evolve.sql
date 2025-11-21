--All data
with policy_data as (
select 
RCC_Description [RCC_Description],
RCC_GLCode [RCC_GLCode],
PRD_Name [Product],
POL_OriginalStartDate,
POL_EndDate,
POL_PolicyNumber

from Evolve.dbo.AccountTransactionSet,
Evolve.dbo.AccountTransaction , 
Evolve.dbo.policy, 
Evolve.dbo.ReferenceGLCode, 
Evolve.dbo.AccountParty, 
Evolve.dbo.ReferenceCellCaptive, 
Evolve.dbo.Product
where 1=1 

and ATN_AccountTransactionSet_ID = AccountTransactionSet_id
and ATN_GLCode_ID = GlCode_ID
and AccountParty_id = atn_AccountParty_id
and ReferenceCellCaptive_Code = ATS_CellCaptive_Id
and  Product_Id = ATS_Product_Id

--####################################################################################################################
and POL_CreateDate < '2025-10-01'
and POL_EndDate >= '2025-10-01'

and POL_Status = 1
and ATS_DisplayNumber = POL_PolicyNumber

and (select PRD_Name from Evolve.dbo.Product where Product_Id = ATS_Product_Id ) = 'Auto Pedigree Plus Plan with Deposit Cover'

and ATN_NettAmount < 0
group by RCC_Description, RCC_GLCode, PRD_Name, POL_PolicyNumber, POL_OriginalStartDate, POL_EndDate

)
Select * from policy_data 


