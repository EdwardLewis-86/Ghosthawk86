Use [Evolve]
GO

-- Evolve UPP

Declare @vmth date = '01-September-2025'; -- Enter the day after the monthend of interest.

-- Get the UPP
Select rcc.RCC_Description
, rcc.RCC_GLCode
, pdt.PRD_Name
, sum(atn.ATN_NettAmount) [Total]
From AccountTransaction atn
inner join AccountTransactionSet ats
on atn.ATN_AccountTransactionSet_ID = ats.AccountTransactionSet_Id
inner join policy p
on p.POL_PolicyNumber = ats.ATS_DisplayNumber
left join ReferenceCellCaptive rcc
on rcc.ReferenceCellCaptive_Code = ats.ATS_CellCaptive_Id
left join Product pdt
on pdt.Product_Id = ats.ATS_Product_Id
Left Outer Join Insurer i
on ats.ATS_Insurer_Id = i.Insurer_Id
Where atn.ATN_AccountParty_ID = '9667AD02-B0A9-456C-8D4A-55FC1F1FB6DA' -- UPP Balance Sheet
and ats.ATS_EffectiveDate >= @vmth
and p.POL_CreateDate < @vmth
and p.POL_Status = 1 
--AND IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate) >= @vmth
and i.Insurer_Id in (
--'2DED2E9F-7150-4F27-9E4D-72AD545D4A15' -- Centriq Life
-- '3DB4F358-243D-4965-BCC7-0D7B8BE23DCF' -- Hollard Life
 '44109559-5BBA-473E-831E-E0D285884B6D' -- Centriq Short Term
--, '3DB4F358-243D-4965-BCC7-0D7B8BE23DCF'  -- Hollard Short Term
--, '4D5B12F8-7BE8-4979-8DB0-11559E577A16'  -- Hollard Short Term
)
and i.INS_Deleted = 0
and pdt.PRD_Deleted = 0
and rcc.RCC_Deleted = 0
and p.POL_Deleted = 0
Group by rcc.RCC_Description
, rcc.RCC_GLCode
, pdt.PRD_Name;




--DAC
-- Evolve DAC

--Declare @vmth date = '01-Jun-2023'; -- Enter the day after the monthend of interest.

-- Get the UPP
Select rcc.RCC_Description
, rcc.RCC_GLCode
, pdt.PRD_Name
, sum(atn.ATN_NettAmount) [Total]
From AccountTransaction atn
inner join AccountTransactionSet ats
on atn.ATN_AccountTransactionSet_ID = ats.AccountTransactionSet_Id
inner join policy p
on p.POL_PolicyNumber = ats.ATS_DisplayNumber
left join ReferenceCellCaptive rcc
on rcc.ReferenceCellCaptive_Code = ats.ATS_CellCaptive_Id
left join Product pdt
on pdt.Product_Id = ats.ATS_Product_Id
Left Outer Join Insurer i
on ats.ATS_Insurer_Id = i.Insurer_Id
Left join ReferenceGLCode rgc
on rgc.GlCode_ID = atn.ATN_GLCode_ID
Where atn.ATN_AccountParty_ID = '9667AD02-B0A9-456C-8D4A-55FC1F1FB6DA' -- UPP Balance Sheet
and ats.ATS_EffectiveDate >= @vmth
and p.POL_CreateDate < @vmth
and p.POL_Status = 1 
--AND IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate) >= @vmth
and i.Insurer_Id in (
--'2DED2E9F-7150-4F27-9E4D-72AD545D4A15' -- Centriq Life
-- '3DB4F358-243D-4965-BCC7-0D7B8BE23DCF' -- Hollard Life
 '44109559-5BBA-473E-831E-E0D285884B6D' -- Centriq Short Term
--, '3DB4F358-243D-4965-BCC7-0D7B8BE23DCF'  -- Hollard Short Term
--, '4D5B12F8-7BE8-4979-8DB0-11559E577A16'  -- Hollard Short Term
)
and rgc.GLC_Description = 'Deferred Acquisition Cost - Unearned Premium Reserve'
and POL_IsMigrated = 0 --- DaC excludes migrated policies
and i.INS_Deleted = 0
and pdt.PRD_Deleted = 0
and rcc.RCC_Deleted = 0
and p.POL_Deleted = 0
and rgc.GLC_Deleted = 0
Group by rcc.RCC_Description
, rcc.RCC_GLCode
, pdt.PRD_Name
;

