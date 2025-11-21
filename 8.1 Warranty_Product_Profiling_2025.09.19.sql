USE [Deloitte]
GO

/* ==========================================================================
   Warranty Portfolio Analysis (ProductLevel3 threaded end-to-end + ActiveCount)
   Revision: 2025-09-19
   Notes:
   - Explicit JOINs (no comma joins)
   - Semicolons before every CTE
   - Pending table created as Deloitte.dbo.Pending
   - ActiveCount = count of in-force policies (PolicyStatus_ID = 1) per month
   ========================================================================== */

-- Parameters
DECLARE @start date;
DECLARE @end   date;

SET @start = '2024-07-01';
SET @end   = EOMONTH(DATEADD(month, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)), 0);
-- For reproducibility in back-testing uncomment the next line
SET @end   = '2025-10-01';  -- one day after valuation month-end

-- Housekeeping
DROP TABLE IF EXISTS #Pol;
DROP TABLE IF EXISTS #ClaimsInfo;
DROP TABLE IF EXISTS #GWP;
DROP TABLE IF EXISTS #Exposure;
DROP TABLE IF EXISTS #MTH;
DROP TABLE IF EXISTS #Cancellations;
DROP TABLE IF EXISTS Deloitte.dbo.Pending;
DROP TABLE IF EXISTS Deloitte.dbo.Profiling_Wty_Policy;
DROP TABLE IF EXISTS Deloitte.dbo.Profiling_Wty_GWP;
DROP TABLE IF EXISTS Deloitte.dbo.Profiling_Wty_EarnedFund;
DROP TABLE IF EXISTS Deloitte.dbo.Profiling_Wty_Exposure;
DROP TABLE IF EXISTS Deloitte.dbo.Profiling_Wty;

-- =========================
-- Policy master (#Pol)
-- =========================
SELECT
    p.Policy_ID,
    p.POL_PolicyNumber,
    p.POL_VATNumber,
    DATEADD(month, DATEDIFF(month, 0, p.POL_CreateDate), 0)               AS CreateMonth,
    DATEADD(month, DATEDIFF(month, 0, p.POL_SoldDate), 0)                 AS SoldMonth,
    DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0)        AS StartMonth,
    p.POL_OriginalStartDate,
    p.POL_EndDate,
    p.POL_Status,
    p.POL_ProductTerm_ID,
    rtf.RTF_TermPeriod,
    CASE
        WHEN POL_PaymentFrequency_ID IN (2,3) THEN 'Term'
        WHEN POL_PaymentFrequency_ID = 1      THEN 'Monthly'
        ELSE IIF(RTF_TermPeriod = 1, 'Monthly', 'Term')
    END                                                                   AS PaymentFrequency,
    pv1.PRV_FullName                                                      AS ProductLevel1,
    pv2.PRV_FullName                                                      AS ProductLevel2,
    pv3.PRV_FullName                                                      AS ProductLevel3,
    rcc.RCC_GLCode,
    i.INS_InsurerName,
    UPPER(t.PMI_Make)                                                     AS Make,
    CASE
        WHEN pa.Agt_FullName = 'Dealer Protection Plan Nett' THEN 'POS'
        WHEN pa.Agt_FullName = 'M-Sure Centriq Head Office Direct (Motus Imports) (Nett)'
             AND pv1.PRV_FullName = 'Warranty Booster'                    THEN 'Telesales'
        WHEN a.Agt_VATNumber IN ('4720273004','4520193881','4690202181','4420175020')
                                                                         THEN 'Telesales'
        ELSE 'POS'
    END                                                                   AS Channel,
    CASE
        WHEN pa.Agt_FullName = 'Dealer Protection Plan Nett' THEN 'POS'
        WHEN pa.Agt_FullName = 'M-Sure Centriq Head Office Direct (Motus Imports) (Nett)'
             AND pv1.PRV_FullName = 'Warranty Booster'                    THEN 'Liquid Capital'
        WHEN a.Agt_VATNumber = '4720273004'                               THEN 'Motor Happy'
        WHEN a.Agt_VATNumber = '4520193881'                               THEN 'Liquid Capital'
        WHEN a.Agt_VATNumber = '4690202181'                               THEN 'M-Sure Telesales'
        WHEN a.Agt_VATNumber = '4420175020'                               THEN 'TMS'
        ELSE 'POS'
    END                                                                   AS Channel2,
    pa.Agt_FullName                                                       AS PrimaryAgent,
    a.Agt_FullName                                                        AS SubAgent,
    arg.ARG_Name,
    (SELECT TOP(1) DCH_Name
     FROM  Evolve.dbo.DisbursementCurveHeader AS dch
     INNER JOIN Evolve.dbo.DisbursementCurveProduct AS dcp
             ON dcp.DCP_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
     WHERE dch.DCH_TermFrequency_Id = p.POL_ProductTerm_ID
       AND dcp.DCP_Product_Id       = p.POL_ProductVariantLevel3_ID
     ORDER BY DCH_Name)                                                   AS PhasingCurve,
    (SELECT MTA_NETT_PROD FROM SAWME5.dbo.ClosingoffValues c WHERE p.POL_VATNumber = c.POLICY_KEY AND c.POLICY_KEY <> '') AS WW_Nett_Premium,
    (SELECT NETT_FUND    FROM SAWME5.dbo.ClosingoffValues c WHERE p.POL_VATNumber = c.POLICY_KEY AND c.POLICY_KEY <> '') AS WW_Nett_Fund,
    (SELECT SUM(ITS_Premium)             FROM Evolve.dbo.ItemSummary its JOIN Evolve.dbo.Policy pp ON pp.Policy_ID = its.ITS_Policy_ID WHERE pp.POL_PolicyNumber = p.POL_PolicyNumber)          AS PremiumInclVaT,
    (SELECT SUM(ITS_Premium * 1.0/1.15)  FROM Evolve.dbo.ItemSummary its JOIN Evolve.dbo.Policy pp ON pp.Policy_ID = its.ITS_Policy_ID WHERE pp.POL_PolicyNumber = p.POL_PolicyNumber)          AS PremiumExclVaT
INTO #Pol
FROM Evolve.dbo.Policy p
LEFT JOIN Evolve.dbo.ProductVariant pv1 ON pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID
LEFT JOIN Evolve.dbo.ProductVariant pv2 ON pv2.ProductVariant_Id = p.POL_ProductVariantLevel2_ID
LEFT JOIN Evolve.dbo.ProductVariant pv3 ON pv3.ProductVariant_Id = p.POL_ProductVariantLevel3_ID
LEFT JOIN Evolve.dbo.Arrangement      arg ON arg.Arrangement_Id           = p.POL_Arrangement_ID
LEFT JOIN Evolve.dbo.ReferenceCellCaptive rcc ON rcc.ReferenceCellCaptive_Code = arg.ARG_CellCaptive
LEFT JOIN Evolve.dbo.PolicyInsurerLink  pil ON pil.PIL_Policy_ID          = p.Policy_ID
LEFT JOIN Evolve.dbo.Insurer             i   ON i.Insurer_Id              = pil.PIL_Insurer_ID
LEFT JOIN Evolve.dbo.ReferenceTermFrequency rtf ON rtf.TermFrequency_Id   = p.POL_ProductTerm_ID
LEFT JOIN (
    SELECT pmi.*, ROW_NUMBER() OVER (PARTITION BY pmi.PMI_Policy_ID ORDER BY pmi.PMI_CreateDate DESC) AS RowN
    FROM Evolve.dbo.PolicyMechanicalBreakdownItem pmi
    WHERE pmi.PMI_Deleted = 0 AND pmi.PMI_Status = 1
) AS t ON t.PMI_Policy_ID = p.Policy_ID
LEFT JOIN Evolve.dbo.Agent a  ON p.POL_Agent_ID        = a.Agent_Id
LEFT JOIN Evolve.dbo.Agent pa ON pa.Agent_Id           = p.POL_PrimaryAgent_ID
WHERE p.POL_Deleted = 0
  AND pv1.PRV_Deleted = 0
  AND rcc.RCC_Deleted = 0
  AND arg.ARG_Deleted = 0
  AND pil.PIL_Deleted = 0
  AND p.POL_Status IN (1,3)  -- Active and Cancelled
  AND p.POL_Product_ID = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF' -- Warranties
  AND t.RowN = 1
  AND i.Insurer_Id IN ('44109559-5BBA-473E-831E-E0D285884B6D','4D5B12F8-7BE8-4979-8DB0-11559E577A16');

UPDATE #Pol
SET PhasingCurve = '84M - Even ALL V0'
WHERE PhasingCurve IS NULL AND ProductLevel1 IN ('Warranty Booster') AND RTF_TermPeriod = 84;

UPDATE #Pol
SET PhasingCurve = '60M - Even ALL V0'
WHERE PhasingCurve IS NULL AND ProductLevel1 IN ('Imperial Logistics Warranty','Warranty Booster') AND RTF_TermPeriod = 60;

UPDATE #Pol
SET PhasingCurve = '48M - Even ALL V0'
WHERE PhasingCurve IS NULL AND ProductLevel1 IN ('Truck Warranty') AND RTF_TermPeriod = 48;

UPDATE #Pol
SET PhasingCurve = '24M -  Curve CEN  V1'
WHERE PhasingCurve IS NULL AND ProductLevel1 IN ('Bumper to Bumper') AND RTF_TermPeriod = 24;

SELECT * INTO Deloitte.dbo.Profiling_Wty_Policy FROM #Pol;

-- =========================
-- Latest cancellation event per policy
-- =========================
;WITH c AS (
    SELECT
        EVL_ReferenceNumber,
        EVL_DateTime,
        EVL_Description,
        CASE WHEN EVL_Description IN ('End of Term','Termination - End of Term') THEN 'Expired'
             ELSE 'Cancelled or Lapsed' END      AS ExitCategory,
        DATEADD(month, DATEDIFF(month, 0, EVL_DateTime), 0) AS CancelMonth,
        ROW_NUMBER() OVER (PARTITION BY EVL_ReferenceNumber ORDER BY EVL_DateTime DESC) AS RowN
    FROM Evolve.dbo.EventLog el
    INNER JOIN #Pol p ON p.Policy_ID = el.EVL_ReferenceNumber
    WHERE el.EVL_Event_ID = '10516'
)
SELECT *
INTO #Cancellations
FROM c
WHERE RowN = 1;

-- =========================
-- GWP (GL 100000) by month
-- =========================
;WITH gwp AS (
    SELECT
        ats.ATS_DisplayNumber                            AS DisplayNumber,
        i.INS_InsurerName                                AS Insurer,
        ats.ATS_Description                              AS [Description],
        att.ATT_Description                              AS [Transaction Type],
        Main.GLC_GlCode                                  AS MainGlCode,
        Main.GLC_Description                             AS MainGlDescription,
        ISNULL(VAT.GLC_GlCode,'')                        AS VatGlCode,
        ISNULL(VAT.GLC_Description,'')                   AS VATGlDescription,
        prd.PRD_GLCode                                   AS [Product],
        Main.GLC_Category                                AS [Category],
        ats.ATS_TransactionNumber                        AS [Transaction number],
        Party.APY_PartyNumber                            AS [Party Number],
        Party.APY_Name                                   AS [Party],
        d.DBT_Description                                AS [Disbursement Type],
        ats.ATS_CreateDate,
        ats.ATS_EffectiveDate,
        CASE WHEN atn.ATN_VATAmount = 0 THEN 1 ELSE 2 END AS VATType,
        Main.glc_VATType                                 AS GPVATType,
        atn.ATN_GrossAmount                              AS GrossAmount,
        atn.ATN_VATAmount                                AS VATAmount,
        atn.ATN_NettAmount                               AS NettAmount,
        DATEADD(month, DATEDIFF(month, 0, IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate)), 0) AS AccountingMonth
    FROM Evolve.dbo.AccountTransactionSet ats
    INNER JOIN Evolve.dbo.AccountTransaction atn
        ON atn.ATN_AccountTransactionSet_ID = ats.AccountTransactionSet_Id
    LEFT JOIN Evolve.dbo.Insurer i
        ON ats.ATS_Insurer_Id = i.Insurer_Id
    LEFT JOIN Evolve.dbo.Product prd
        ON ats.ATS_Product_Id = prd.Product_Id
    LEFT JOIN Evolve.dbo.SalesBranch Branch
        ON ats.ATS_SalesBranch = Branch.SalesRegion_ID
    LEFT JOIN Evolve.dbo.ReferenceGLCode Main
        ON atn.ATN_GLCode_ID = Main.GlCode_ID
    LEFT JOIN Evolve.dbo.ReferenceGLCode VAT
        ON atn.ATN_GLCodeVAT_ID = VAT.GlCode_ID
    LEFT JOIN Evolve.dbo.AccountParty Party
        ON Party.AccountParty_Id = atn.ATN_AccountParty_ID
    LEFT JOIN Evolve.dbo.DisbursementType d
        ON atn.ATN_DisbursementType_ID = d.DisbursementType_Id
    LEFT JOIN Evolve.dbo.AccountTransactionType att
        ON atn.ATN_AccountTransactionType_ID = att.AccountTransactionType_Id
    WHERE atn.ATN_GrossAmount <> 0
      AND Main.GLC_GlCode IN ('100000')
      AND IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate) >= @start
      AND IIF(ats.ATS_CreateDate > ats.ATS_EffectiveDate, ats.ATS_CreateDate, ats.ATS_EffectiveDate) <  @end
      AND ats.ATS_CreateDate <= @end
      AND i.INS_Deleted = 0
      AND prd.PRD_Deleted = 0
)
SELECT
    gwp.*,
    p.POL_Status,
    p.PaymentFrequency,
    p.ProductLevel1,
    p.ProductLevel2,
    p.ProductLevel3,
    p.RCC_GLCode,
    p.Channel,
    p.Channel2,
    p.INS_InsurerName,
    p.Make,
    p.PhasingCurve,
    p.PrimaryAgent,
    p.SubAgent,
    p.RTF_TermPeriod,
    p.ARG_Name
INTO #GWP
FROM gwp
INNER JOIN #Pol p
    ON p.POL_PolicyNumber = gwp.DisplayNumber;

SELECT * INTO Deloitte.dbo.Profiling_Wty_GWP FROM #GWP;

-- =========================
-- Earned fund
-- =========================
SELECT
    p.POL_PolicyNumber,
    DATEADD(month, DATEDIFF(month, 0, ef.AccountingMonth), 0) AS AccountingMonth,
    SUM(ISNULL(-ef.ATN_GrossAmount,0))                        AS EarnedFund
INTO Deloitte.dbo.Profiling_Wty_EarnedFund
FROM #Pol p
LEFT JOIN [LC-BIMSDATA01].[BI_reportdata].[FinME].[FR_RaiseEarnedWrittenPremiumME] ef
       ON ef.POL_PolicyNumber = p.POL_PolicyNumber
WHERE DATEADD(month, DATEDIFF(month, 0, ef.AccountingMonth), 0) >= @start
  AND DATEADD(month, DATEDIFF(month, 0, ef.AccountingMonth), 0) <  @end
  AND ef.ATT_Description = 'UPR Earned Premium'
GROUP BY p.POL_PolicyNumber, DATEADD(month, DATEDIFF(month, 0, ef.AccountingMonth), 0);

;WITH pol AS (
    SELECT
        ats.ATS_TransactionNumber,
        p.POL_PolicyNumber,
        p.Policy_ID,
        dbt.DBT_Description,
        atn.ATN_AccountParty_ID,
        apt.APT_Description,
        aar.AAR_Description,
        atn.ATN_GrossAmount,
        atn.ATN_NettAmount,
        dbs.DBS_SetName,
        dsm.DSM_RuleName,
        rgl.GLC_Description,
        rgl.GLC_GlCode,
        atn.ATN_DisbursementStep,
        ats.ATS_EffectiveDate,
        DATEADD(month, DATEDIFF(month, 0, IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate)), 0) AS AccountingMonth
    FROM Deloitte.dbo.Profiling_Wty_Policy p
    LEFT JOIN Evolve.dbo.AccountTransactionSet ats ON p.Policy_ID = ats.ATS_ReferenceNumber
    LEFT JOIN Evolve.dbo.AccountTransaction atn    ON ats.AccountTransactionSet_Id = atn.ATN_AccountTransactionSet_ID
    LEFT JOIN Evolve.dbo.AccountParty apy          ON apy.AccountParty_Id = atn.ATN_AccountParty_ID
    LEFT JOIN Evolve.dbo.AccountPartyType apt      ON apt.AccountPartyType_Id = apy.APY_PartyType_ID
    LEFT JOIN Evolve.dbo.AccountArea aar           ON aar.AccountArea_Id = ats.ATS_AccountArea_ID AND aar.AAR_Deleted = 0
    LEFT JOIN Evolve.dbo.DisbursementType dbt      ON atn.ATN_DisbursementType_ID = dbt.DisbursementType_Id AND dbt.DBT_Deleted = 0
    LEFT JOIN Evolve.dbo.DisbursementSet dbs       ON dbs.DisbursementSet_Id = ats.ATS_DisbursementRule_ID AND dbs.DBS_Deleted = 0
    LEFT JOIN Evolve.dbo.Disbursement dsm          ON dsm.Disbursement_Id = dbs.DBS_Disbursement_ID AND dsm.DSM_Deleted = 0
    LEFT JOIN Evolve.dbo.ReferenceGLCode rgl       ON atn.ATN_GLCode_ID = rgl.GlCode_ID AND rgl.GLC_Deleted = 0
    WHERE apt.APT_Description = 'Insurer'
      AND p.PaymentFrequency  = 'Monthly'
      AND p.RTF_TermPeriod    = 1
      AND dbs.DBS_SetName IS NOT NULL
      AND p.POL_PolicyNumber NOT IN (SELECT k.POL_PolicyNumber FROM Deloitte.dbo.Profiling_Wty_EarnedFund k)
),
dmt AS (
    SELECT
        pol.POL_PolicyNumber,
        pol.AccountingMonth,
        SUM(CASE WHEN GLC_GlCode = '100000' THEN ATN_NettAmount ELSE 0 END) AS PremiumExclVaT,
        SUM(CASE WHEN GLC_GlCode = '100700' THEN ATN_NettAmount ELSE 0 END) AS CommissionExclVaT,
        SUM(CASE WHEN GLC_GlCode = '303304' THEN ATN_NettAmount ELSE 0 END) AS RoadsideExclVaT,
        SUM(CASE WHEN GLC_GlCode IN ('306301','306302','306307','306308','306309') THEN ATN_NettAmount ELSE 0 END) AS BinderExclVaT,
        SUM(CASE WHEN GLC_GlCode = '306303' THEN ATN_NettAmount ELSE 0 END) AS OutsourceExclVaT,
        SUM(CASE WHEN GLC_GlCode = '306304' THEN ATN_NettAmount ELSE 0 END) AS UnderwritingExclVaT,
        SUM(CASE WHEN GLC_GlCode = '306305' THEN ATN_NettAmount ELSE 0 END) AS CellFeeDiffExclVaT,
        SUM(CASE WHEN GLC_GlCode = '303302' THEN ATN_NettAmount ELSE 0 END) AS PlatformExclVaT,
        SUM(CASE WHEN GLC_GlCode = '303307' THEN ATN_NettAmount ELSE 0 END) AS BdrxExclVaT,
        SUM(CASE WHEN GLC_GlCode = '303300' THEN ATN_NettAmount ELSE 0 END) AS BrokerExclVaT,
        SUM(CASE WHEN GLC_GlCode = '303308' THEN ATN_NettAmount ELSE 0 END) AS BankExclVaT,
        SUM(CASE WHEN GLC_GlCode = '303033' THEN ATN_NettAmount ELSE 0 END) AS InspectionExclVaT
    FROM pol
    GROUP BY pol.POL_PolicyNumber, pol.AccountingMonth
)
INSERT INTO Deloitte.dbo.Profiling_Wty_EarnedFund (POL_PolicyNumber, AccountingMonth, EarnedFund)
SELECT
    Pol_PolicyNumber,
    AccountingMonth,
    -(PremiumExclVat + CommissionExclVaT + RoadsideExclVaT + BinderExclVaT + OutsourceExclVaT
      + UnderwritingExclVaT + CellFeeDiffExclVaT + PlatformExclVaT + BdrxExclVaT + BrokerExclVaT
      + BankExclVaT + InspectionExclVaT) AS EarnedFund
FROM dmt
WHERE AccountingMonth >= @start AND AccountingMonth < @end;

-- =========================
-- Claims (paid + OCR - discounts)
-- =========================
;WITH cpmt AS (
    SELECT cit.CIT_ClaimItem_ID,
           SUM(CIT_Amount)            AS ClaimsPaidInclVaT,
           SUM(CIT_AmountVAT)         AS VAT,
           SUM(CIT_Amount) - SUM(CIT_AmountVAT) AS ClaimsPaidExclVaT
    FROM Evolve.dbo.ClaimItemTransaction cit
    WHERE cit.CIT_Deleted = 0 AND cit.CIT_TransactionType_ID = 2
    GROUP BY cit.CIT_ClaimItem_ID
),
ocr AS (
    SELECT cit.CIT_ClaimItem_ID,
           SUM(CIT_Amount)            AS OCRInclVaT,
           SUM(CIT_AmountVAT)         AS VAT,
           SUM(CIT_Amount) - SUM(CIT_AmountVAT) AS OCRExclVaT
    FROM Evolve.dbo.ClaimItemTransaction cit
    WHERE cit.CIT_Deleted = 0
    GROUP BY cit.CIT_ClaimItem_ID
),
d AS (
    SELECT cit.CIT_ClaimItem_ID,
           SUM(CIT_Discount)                        AS DiscountInclVaT,
           SUM(CIT_Discount - CIT_Discount/1.15)    AS DiscountVAT,
           SUM(CIT_Discount/1.15)                   AS DiscountExclVaT
    FROM Evolve.dbo.ClaimItemTransaction cit
    WHERE cit.CIT_Deleted = 0 AND cit.CIT_TransactionType_ID = 2
    GROUP BY cit.CIT_ClaimItem_ID
),
c AS (
    SELECT CIT_ClaimItem_ID FROM cpmt
    UNION
    SELECT CIT_ClaimItem_ID FROM ocr
    UNION
    SELECT CIT_ClaimItem_ID FROM d
),
cinc AS (
    SELECT
        c.CIT_ClaimItem_ID,
        ISNULL(-cpmt.ClaimsPaidInclVaT,0) AS ClaimsPaidInclVaT,
        ISNULL(-cpmt.VAT,0)               AS VAT,
        ISNULL(-cpmt.ClaimsPaidExclVaT,0) AS ClaimsPaidExclVaT,
        ISNULL(ocr.OCRInclVaT,0)          AS OCRInclVaT,
        CASE WHEN ISNULL(ocr.OCRInclVaT,0) = 0 THEN 0 ELSE ISNULL(ocr.VAT,0)      END AS OCRVaT,
        CASE WHEN ISNULL(ocr.OCRInclVaT,0) = 0 THEN 0 ELSE ISNULL(ocr.OCRExclVaT,0) END AS OCRExclVaT,
        ISNULL(d.DiscountInclVaT,0)       AS DiscountInclVaT,
        ISNULL(d.DiscountVAT,0)           AS DiscountVAT,
        ISNULL(d.DiscountExclVaT,0)       AS DiscountExclVaT
    FROM c
    LEFT JOIN cpmt ON c.CIT_ClaimItem_ID = cpmt.CIT_ClaimItem_ID
    LEFT JOIN ocr  ON c.CIT_ClaimItem_ID = ocr.CIT_ClaimItem_ID
    LEFT JOIN d    ON c.CIT_ClaimItem_ID = d.CIT_ClaimItem_ID
)
SELECT DISTINCT
    cinc.*,
    ISNULL(cinc.OCRExclVaT,0) + ISNULL(cinc.ClaimsPaidExclVaT,0) - ISNULL(cinc.DiscountExclVaT,0) AS ClaimsIncurredExclVaT,
    cis.CIS_PolicyNumber,
    CASE WHEN p.POL_PolicyNumber NOT LIKE '%POL' THEN SUBSTRING(p.POL_PolicyNumber, 1, LEN(p.POL_PolicyNumber) - 3)
         ELSE p.POL_PolicyNumber END AS OriginalPolicyNumber,
    cis.CIS_ClaimNumber,
    cis.CIS_CreateDate,
    DATEADD(month, DATEDIFF(month, 0, cis.CIS_CreateDate), 0) AS LossMonth,
    (DATEDIFF(day,
         (SELECT o.POL_OriginalStartDate FROM Evolve.dbo.Policy o
          WHERE o.POL_PolicyNumber =
              CASE WHEN p.POL_PolicyNumber NOT LIKE '%POL' THEN SUBSTRING(p.POL_PolicyNumber, 1, LEN(p.POL_PolicyNumber) - 3)
                   ELSE p.POL_PolicyNumber END),
         cis.CIS_CreateDate) / (365.25/12.0)) AS ClaimMonth,
    (SELECT o.POL_OriginalStartDate FROM Evolve.dbo.Policy o
     WHERE o.POL_PolicyNumber =
       CASE WHEN p.POL_PolicyNumber NOT LIKE '%POL' THEN SUBSTRING(p.POL_PolicyNumber, 1, LEN(p.POL_PolicyNumber) - 3)
            ELSE p.POL_PolicyNumber END) AS OriginalStartDate,
    p.POL_Status,
    p.PaymentFrequency,
    p.ProductLevel1,
    p.ProductLevel2,
    p.ProductLevel3,
    p.RCC_GLCode,
    p.Channel,
    p.Channel2,
    p.INS_InsurerName,
    p.Make,
    p.PhasingCurve,
    p.PrimaryAgent,
    p.SubAgent,
    p.RTF_TermPeriod,
    p.ARG_Name
INTO #ClaimsInfo
FROM cinc
INNER JOIN Evolve.dbo.ClaimItemSummary cis ON cinc.CIT_ClaimItem_ID = cis.CIS_ClaimItem_ID
INNER JOIN #Pol p ON cis.CIS_PolicyNumber = p.POL_PolicyNumber
WHERE (ISNULL(ClaimsPaidInclVaT,0) + ISNULL(OCRInclVaT,0)) <> 0;

UPDATE #ClaimsInfo
SET ClaimMonth = DATEDIFF(day, OriginalStartDate, CIS_CreateDate) / (365.25 / 12.0);

-- =========================
-- Month grid and exposure
-- =========================
;WITH mths AS (
    SELECT DATEADD(month, DATEDIFF(month, 0, @start), 0) AS MTH,
           EOMONTH(DATEADD(month, DATEDIFF(month, 0, @start), 0)) AS ME
    UNION ALL
    SELECT DATEADD(month, 1, mths.MTH),
           EOMONTH(DATEADD(month, 1, mths.MTH))
    FROM mths
    WHERE EOMONTH(DATEADD(month, 1, mths.MTH)) < @end
)
SELECT * INTO #MTH FROM mths OPTION (MAXRECURSION 500);

;WITH e AS (
    SELECT
        p.*,
        m.MTH,
        m.ME,
        CASE
            WHEN EOMONTH(p.POL_OriginalStartDate) = m.ME THEN
                (DATEDIFF(day, p.POL_OriginalStartDate, CASE WHEN p.POL_EndDate < m.ME THEN p.POL_EndDate ELSE m.ME END) + 1.0)
                / (DATEDIFF(day, m.MTH, m.ME) + 1.0)
            WHEN EOMONTH(p.POL_EndDate) = m.ME THEN
                (DATEDIFF(day, m.MTH, p.POL_EndDate) + 1.0) / (DATEDIFF(day, m.MTH, m.ME) + 1.0)
            ELSE 1.0
        END AS Exposure,
        CASE WHEN EOMONTH(m.MTH) < EOMONTH(p.StartMonth) THEN 0
             ELSE DATEDIFF(month, p.StartMonth, m.MTH) + 1 END AS ExposureMonth,
        (SELECT TOP(1) dci.DCI_MonthlyPercentage
         FROM Evolve.dbo.DisbursementCurveItem dci
         JOIN Evolve.dbo.DisbursementCurveHeader dch
           ON dci.DCI_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
         WHERE dci.DCI_Month = (CASE WHEN EOMONTH(m.MTH) < EOMONTH(p.StartMonth) THEN 0 ELSE DATEDIFF(month, p.StartMonth, m.MTH) + 1 END)
           AND dch.DCH_Name = p.PhasingCurve
           AND dch.DCH_TermFrequency_Id = p.POL_ProductTerm_ID) AS EarnedPortion
    FROM #Pol p
    CROSS JOIN #MTH m
    WHERE EOMONTH(p.POL_OriginalStartDate) <= m.ME
      AND EOMONTH(p.POL_EndDate)           >= m.ME
)
SELECT * INTO Deloitte.dbo.Profiling_Wty_Exposure FROM e;

-- =========================
-- Final monthly cube
-- =========================
;WITH classifiers AS (
    SELECT DISTINCT
        p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
        p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
        p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, m.MTH
    FROM Deloitte.dbo.Profiling_Wty_Policy p
    CROSS JOIN #MTH m
),
claims AS (
    SELECT
        POL_Status, PaymentFrequency, ProductLevel1, ProductLevel2, ProductLevel3,
        RCC_GLCode, Channel, Channel2, INS_InsurerName, Make, PhasingCurve,
        PrimaryAgent, SubAgent, RTF_TermPeriod, ARG_Name,
        CAST(LossMonth AS date) AS MTH,
        SUM(ISNULL(ClaimsPaidExclVaT,0))   AS ClaimsPaidExclVaT,
        SUM(ISNULL(OCRExclVaT,0))          AS OCRExclVaT,
        SUM(ISNULL(DiscountExclVaT,0))     AS DiscountExclVaT,
        SUM(ISNULL(ClaimsIncurredExclVaT,0)) AS ClaimsIncurredExclVaT,
        SUM(CASE WHEN ISNULL(ClaimsIncurredExclVaT,0) > 0 THEN 1 ELSE 0 END) AS ClaimsCount
    FROM #ClaimsInfo
    GROUP BY POL_Status, PaymentFrequency, ProductLevel1, ProductLevel2, ProductLevel3,
             RCC_GLCode, Channel, Channel2, INS_InsurerName, Make, PhasingCurve,
             PrimaryAgent, SubAgent, RTF_TermPeriod, ARG_Name, CAST(LossMonth AS date)
),
nb AS (
    SELECT POL_Status, PaymentFrequency, ProductLevel1, ProductLevel2, ProductLevel3,
           RCC_GLCode, Channel, Channel2, INS_InsurerName, Make, PhasingCurve,
           PrimaryAgent, SubAgent, RTF_TermPeriod, ARG_Name, SoldMonth AS MTH,
           COUNT(*) AS NewBusiness
    FROM Deloitte.dbo.Profiling_Wty_Policy
    GROUP BY POL_Status, PaymentFrequency, ProductLevel1, ProductLevel2, ProductLevel3,
             RCC_GLCode, Channel, Channel2, INS_InsurerName, Make, PhasingCurve,
             PrimaryAgent, SubAgent, RTF_TermPeriod, ARG_Name, SoldMonth
),
gwp AS (
    SELECT POL_Status, PaymentFrequency, ProductLevel1, ProductLevel2, ProductLevel3,
           RCC_GLCode, Channel, Channel2, INS_InsurerName, Make, PhasingCurve,
           PrimaryAgent, SubAgent, RTF_TermPeriod, ARG_Name, AccountingMonth AS MTH,
           SUM(-NettAmount) AS GWP
    FROM Deloitte.dbo.Profiling_Wty_GWP
    GROUP BY POL_Status, PaymentFrequency, ProductLevel1, ProductLevel2, ProductLevel3,
             RCC_GLCode, Channel, Channel2, INS_InsurerName, Make, PhasingCurve,
             PrimaryAgent, SubAgent, RTF_TermPeriod, ARG_Name, AccountingMonth
),
ef AS (
    SELECT p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
           p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
           p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, ef.AccountingMonth AS MTH,
           SUM(ef.EarnedFund) AS EarnedFund
    FROM Deloitte.dbo.Profiling_Wty_EarnedFund ef
    JOIN Deloitte.dbo.Profiling_Wty_Policy p ON ef.POL_PolicyNumber = p.POL_PolicyNumber
    GROUP BY p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
             p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
             p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, ef.AccountingMonth
),
ex AS (
    SELECT p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
           p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
           p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, e.MTH,
           SUM(e.Exposure) AS Exposure
    FROM Deloitte.dbo.Profiling_Wty_Exposure e
    JOIN Deloitte.dbo.Profiling_Wty_Policy p ON e.POL_PolicyNumber = p.POL_PolicyNumber
    GROUP BY p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
             p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
             p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, e.MTH
),
ac AS (
    SELECT
        p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
        p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
        p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, e.MTH,
        COUNT(DISTINCT e.POL_PolicyNumber) AS ActiveCount
    FROM Deloitte.dbo.Profiling_Wty_Exposure e
    JOIN Deloitte.dbo.Profiling_Wty_Policy p ON e.POL_PolicyNumber = p.POL_PolicyNumber
    WHERE p.POL_Status = 1  -- In Force
    GROUP BY p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
             p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
             p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, e.MTH
),
can AS (
    SELECT p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
           p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
           p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, c.CancelMonth AS MTH,
           SUM(CASE WHEN c.ExitCategory = 'Cancelled or Lapsed' THEN 1 ELSE 0 END) AS Cancelled,
           SUM(CASE WHEN c.ExitCategory = 'Expired' THEN 1 ELSE 0 END) AS Expired,
           COUNT(*) AS Exits
    FROM #Cancellations c
    JOIN #Pol p ON p.Policy_ID = c.EVL_ReferenceNumber
    GROUP BY p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
             p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
             p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, c.CancelMonth
)
SELECT
    c.*,
    ISNULL(claims.ClaimsPaidExclVaT,0)     AS ClaimsPaidExclVaT,
    ISNULL(claims.OCRExclVaT,0)            AS OCRExclVaT,
    ISNULL(claims.DiscountExclVaT,0)       AS DiscountExclVaT,
    ISNULL(claims.ClaimsIncurredExclVaT,0) AS ClaimsIncurredExclVaT,
    ISNULL(claims.ClaimsCount,0)           AS ClaimsCount,
    ISNULL(nb.NewBusiness,0)               AS NewBusiness,
    ISNULL(gwp.GWP,0)                      AS GWP,
    ISNULL(ef.EarnedFund,0)                AS EarnedFund,
    ISNULL(exposure.Exposure,0)            AS Exposure,
    ISNULL(can.Cancelled,0)                AS Cancelled,
    ISNULL(can.Expired,0)                  AS Expired,
    ISNULL(can.Exits,0)                    AS Exits,
    ISNULL(ac.ActiveCount,0)               AS ActiveCount
INTO Deloitte.dbo.Profiling_Wty
FROM classifiers c
LEFT JOIN claims ON 1=1
    AND c.POL_Status      = claims.POL_Status
    AND c.PaymentFrequency= claims.PaymentFrequency
    AND c.ProductLevel1   = claims.ProductLevel1
    AND c.ProductLevel2   = claims.ProductLevel2
    AND c.ProductLevel3   = claims.ProductLevel3
    AND c.RCC_GLCode      = claims.RCC_GLCode
    AND c.Channel         = claims.Channel
    AND c.Channel2        = claims.Channel2
    AND c.INS_InsurerName = claims.INS_InsurerName
    AND c.Make            = claims.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(claims.PhasingCurve,'')
    AND c.PrimaryAgent    = claims.PrimaryAgent
    AND c.SubAgent        = claims.SubAgent
    AND c.RTF_TermPeriod  = claims.RTF_TermPeriod
    AND c.ARG_Name        = claims.ARG_Name
    AND c.MTH             = claims.MTH
LEFT JOIN nb ON 1=1
    AND c.POL_Status      = nb.POL_Status
    AND c.PaymentFrequency= nb.PaymentFrequency
    AND c.ProductLevel1   = nb.ProductLevel1
    AND c.ProductLevel2   = nb.ProductLevel2
    AND c.ProductLevel3   = nb.ProductLevel3
    AND c.RCC_GLCode      = nb.RCC_GLCode
    AND c.Channel         = nb.Channel
    AND c.Channel2        = nb.Channel2
    AND c.INS_InsurerName = nb.INS_InsurerName
    AND c.Make            = nb.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(nb.PhasingCurve,'')
    AND c.PrimaryAgent    = nb.PrimaryAgent
    AND c.SubAgent        = nb.SubAgent
    AND c.RTF_TermPeriod  = nb.RTF_TermPeriod
    AND c.ARG_Name        = nb.ARG_Name
    AND c.MTH             = nb.MTH
LEFT JOIN gwp ON 1=1
    AND c.POL_Status      = gwp.POL_Status
    AND c.PaymentFrequency= gwp.PaymentFrequency
    AND c.ProductLevel1   = gwp.ProductLevel1
    AND c.ProductLevel2   = gwp.ProductLevel2
    AND c.ProductLevel3   = gwp.ProductLevel3
    AND c.RCC_GLCode      = gwp.RCC_GLCode
    AND c.Channel         = gwp.Channel
    AND c.Channel2        = gwp.Channel2
    AND c.INS_InsurerName = gwp.INS_InsurerName
    AND c.Make            = gwp.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(gwp.PhasingCurve,'')
    AND c.PrimaryAgent    = gwp.PrimaryAgent
    AND c.SubAgent        = gwp.SubAgent
    AND c.RTF_TermPeriod  = gwp.RTF_TermPeriod
    AND c.ARG_Name        = gwp.ARG_Name
    AND c.MTH             = gwp.MTH
LEFT JOIN ef ON 1=1
    AND c.POL_Status      = ef.POL_Status
    AND c.PaymentFrequency= ef.PaymentFrequency
    AND c.ProductLevel1   = ef.ProductLevel1
    AND c.ProductLevel2   = ef.ProductLevel2
    AND c.ProductLevel3   = ef.ProductLevel3
    AND c.RCC_GLCode      = ef.RCC_GLCode
    AND c.Channel         = ef.Channel
    AND c.Channel2        = ef.Channel2
    AND c.INS_InsurerName = ef.INS_InsurerName
    AND c.Make            = ef.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(ef.PhasingCurve,'')
    AND c.PrimaryAgent    = ef.PrimaryAgent
    AND c.SubAgent        = ef.SubAgent
    AND c.RTF_TermPeriod  = ef.RTF_TermPeriod
    AND c.ARG_Name        = ef.ARG_Name
    AND c.MTH             = ef.MTH
LEFT JOIN ex AS exposure ON 1=1
    AND c.POL_Status      = exposure.POL_Status
    AND c.PaymentFrequency= exposure.PaymentFrequency
    AND c.ProductLevel1   = exposure.ProductLevel1
    AND c.ProductLevel2   = exposure.ProductLevel2
    AND c.ProductLevel3   = exposure.ProductLevel3
    AND c.RCC_GLCode      = exposure.RCC_GLCode
    AND c.Channel         = exposure.Channel
    AND c.Channel2        = exposure.Channel2
    AND c.INS_InsurerName = exposure.INS_InsurerName
    AND c.Make            = exposure.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(exposure.PhasingCurve,'')
    AND c.PrimaryAgent    = exposure.PrimaryAgent
    AND c.SubAgent        = exposure.SubAgent
    AND c.RTF_TermPeriod  = exposure.RTF_TermPeriod
    AND c.ARG_Name        = exposure.ARG_Name
    AND c.MTH             = exposure.MTH
LEFT JOIN ac ON 1=1
    AND c.POL_Status      = ac.POL_Status
    AND c.PaymentFrequency= ac.PaymentFrequency
    AND c.ProductLevel1   = ac.ProductLevel1
    AND c.ProductLevel2   = ac.ProductLevel2
    AND c.ProductLevel3   = ac.ProductLevel3
    AND c.RCC_GLCode      = ac.RCC_GLCode
    AND c.Channel         = ac.Channel
    AND c.Channel2        = ac.Channel2
    AND c.INS_InsurerName = ac.INS_InsurerName
    AND c.Make            = ac.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(ac.PhasingCurve,'')
    AND c.PrimaryAgent    = ac.PrimaryAgent
    AND c.SubAgent        = ac.SubAgent
    AND c.RTF_TermPeriod  = ac.RTF_TermPeriod
    AND c.ARG_Name        = ac.ARG_Name
    AND c.MTH             = ac.MTH
LEFT JOIN can ON 1=1
    AND c.POL_Status      = can.POL_Status
    AND c.PaymentFrequency= can.PaymentFrequency
    AND c.ProductLevel1   = can.ProductLevel1
    AND c.ProductLevel2   = can.ProductLevel2
    AND c.ProductLevel3   = can.ProductLevel3
    AND c.RCC_GLCode      = can.RCC_GLCode
    AND c.Channel         = can.Channel
    AND c.Channel2        = can.Channel2
    AND c.INS_InsurerName = can.INS_InsurerName
    AND c.Make            = can.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(can.PhasingCurve,'')
    AND c.PrimaryAgent    = can.PrimaryAgent
    AND c.SubAgent        = can.SubAgent
    AND c.RTF_TermPeriod  = can.RTF_TermPeriod
    AND c.ARG_Name        = can.ARG_Name
    AND c.MTH             = can.MTH;

-- =========================
-- Add Pending policies to New Business
-- =========================
SELECT
    p.Policy_ID,
    p.POL_PolicyNumber,
    p.POL_VATNumber,
    DATEADD(month, DATEDIFF(month, 0, p.POL_CreateDate), 0)        AS CreateMonth,
    DATEADD(month, DATEDIFF(month, 0, p.POL_SoldDate), 0)          AS SoldMonth,
    DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) AS StartMonth,
    p.POL_OriginalStartDate,
    p.POL_EndDate,
    p.POL_Status,
    p.POL_ProductTerm_ID,
    rtf.RTF_TermPeriod,
    CASE
        WHEN POL_PaymentFrequency_ID IN (2,3) THEN 'Term'
        WHEN POL_PaymentFrequency_ID = 1      THEN 'Monthly'
        ELSE IIF(RTF_TermPeriod = 1, 'Monthly', 'Term')
    END AS PaymentFrequency,
    pv1.PRV_FullName AS ProductLevel1,
    pv2.PRV_FullName AS ProductLevel2,
    pv3.PRV_FullName AS ProductLevel3,
    rcc.RCC_GLCode,
    i.INS_InsurerName,
    UPPER(t.PMI_Make) AS Make,
    CASE
        WHEN pa.Agt_FullName = 'Dealer Protection Plan Nett' THEN 'POS'
        WHEN pa.Agt_FullName = 'M-Sure Centriq Head Office Direct (Motus Imports) (Nett)' AND pv1.PRV_FullName = 'Warranty Booster' THEN 'Telesales'
        WHEN a.Agt_VATNumber IN ('4720273004','4520193881','4690202181','4420175020') THEN 'Telesales'
        ELSE 'POS'
    END AS Channel,
    CASE
        WHEN pa.Agt_FullName = 'Dealer Protection Plan Nett' THEN 'POS'
        WHEN pa.Agt_FullName = 'M-Sure Centriq Head Office Direct (Motus Imports) (Nett)' AND pv1.PRV_FullName = 'Warranty Booster' THEN 'Liquid Capital'
        WHEN a.Agt_VATNumber = '4720273004' THEN 'Motor Happy'
        WHEN a.Agt_VATNumber = '4520193881' THEN 'Liquid Capital'
        WHEN a.Agt_VATNumber = '4690202181' THEN 'M-Sure Telesales'
        WHEN a.Agt_VATNumber = '4420175020' THEN 'TMS'
        ELSE 'POS'
    END AS Channel2,
    pa.Agt_FullName AS PrimaryAgent,
    a.Agt_FullName  AS SubAgent,
    arg.ARG_Name,
    (SELECT TOP(1) DCH_Name
     FROM Evolve.dbo.DisbursementCurveHeader dch
     INNER JOIN Evolve.dbo.DisbursementCurveProduct dcp ON dcp.DCP_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
     WHERE dch.DCH_TermFrequency_Id = p.POL_ProductTerm_ID
       AND dcp.DCP_Product_Id       = p.POL_ProductVariantLevel3_ID
     ORDER BY DCH_Name) AS PhasingCurve,
    (SELECT MTA_NETT_PROD FROM SAWME5.dbo.ClosingoffValues c WHERE p.POL_VATNumber = c.POLICY_KEY AND c.POLICY_KEY <> '') AS WW_Nett_Premium,
    (SELECT NETT_FUND    FROM SAWME5.dbo.ClosingoffValues c WHERE p.POL_VATNumber = c.POLICY_KEY AND c.POLICY_KEY <> '') AS WW_Nett_Fund,
    (SELECT SUM(ITS_Premium)            FROM Evolve.dbo.ItemSummary its JOIN Evolve.dbo.Policy pp ON pp.Policy_ID = its.ITS_Policy_ID WHERE pp.POL_PolicyNumber = p.POL_PolicyNumber)         AS PremiumInclVaT,
    (SELECT SUM(ITS_Premium * 1.0/1.15) FROM Evolve.dbo.ItemSummary its JOIN Evolve.dbo.Policy pp ON pp.Policy_ID = its.ITS_Policy_ID WHERE pp.POL_PolicyNumber = p.POL_PolicyNumber)         AS PremiumExclVaT
INTO Deloitte.dbo.Pending
FROM Evolve.dbo.Policy p
LEFT JOIN Evolve.dbo.ProductVariant pv1 ON pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID
LEFT JOIN Evolve.dbo.ProductVariant pv2 ON pv2.ProductVariant_Id = p.POL_ProductVariantLevel2_ID
LEFT JOIN Evolve.dbo.ProductVariant pv3 ON pv3.ProductVariant_Id = p.POL_ProductVariantLevel3_ID
LEFT JOIN Evolve.dbo.Arrangement arg    ON arg.Arrangement_Id    = p.POL_Arrangement_ID
LEFT JOIN Evolve.dbo.ReferenceCellCaptive rcc ON rcc.ReferenceCellCaptive_Code = arg.ARG_CellCaptive
LEFT JOIN Evolve.dbo.PolicyInsurerLink  pil ON pil.PIL_Policy_ID = p.Policy_ID
LEFT JOIN Evolve.dbo.Insurer            i   ON i.Insurer_Id      = pil.PIL_Insurer_ID
LEFT JOIN Evolve.dbo.ReferenceTermFrequency rtf ON rtf.TermFrequency_Id = p.POL_ProductTerm_ID
LEFT JOIN (
    SELECT pmi.*, ROW_NUMBER() OVER (PARTITION BY pmi.PMI_Policy_ID ORDER BY pmi.PMI_CreateDate DESC) AS RowN
    FROM Evolve.dbo.PolicyMechanicalBreakdownItem pmi
    WHERE pmi.PMI_Deleted = 0 AND pmi.PMI_Status = 1
) AS t ON t.PMI_Policy_ID = p.Policy_ID
LEFT JOIN Evolve.dbo.Agent a  ON p.POL_Agent_ID = a.Agent_Id
LEFT JOIN Evolve.dbo.Agent pa ON pa.Agent_Id    = p.POL_PrimaryAgent_ID
WHERE p.POL_Deleted = 0
  AND pv1.PRV_Deleted = 0
  AND rcc.RCC_Deleted = 0
  AND arg.ARG_Deleted = 0
  AND pil.PIL_Deleted = 0
  AND p.POL_Status IN (4,8) -- Pending & Future Active
  AND p.POL_Product_ID = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
  AND t.RowN = 1
  AND i.Insurer_Id IN ('44109559-5BBA-473E-831E-E0D285884B6D','4D5B12F8-7BE8-4979-8DB0-11559E577A16');

;WITH classifiers AS (
    SELECT DISTINCT
        p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
        p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
        p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, m.MTH
    FROM Deloitte.dbo.Profiling_Wty_Policy p
    CROSS JOIN #MTH m
),
nb2 AS (
    SELECT
        p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
        p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
        p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, p.SoldMonth AS MTH,
        COUNT(*) AS NewBusiness
    FROM Deloitte.dbo.Pending p
    GROUP BY p.POL_Status, p.PaymentFrequency, p.ProductLevel1, p.ProductLevel2, p.ProductLevel3,
             p.RCC_GLCode, p.Channel, p.Channel2, p.INS_InsurerName, p.Make, p.PhasingCurve,
             p.PrimaryAgent, p.SubAgent, p.RTF_TermPeriod, p.ARG_Name, p.SoldMonth
)
UPDATE N
SET N.NewBusiness = N.NewBusiness + ISNULL(nb2.NewBusiness,0)
FROM Deloitte.dbo.Profiling_Wty AS N
JOIN classifiers c ON 1=1
    AND c.POL_Status      = N.POL_Status
    AND c.PaymentFrequency= N.PaymentFrequency
    AND c.ProductLevel1   = N.ProductLevel1
    AND c.ProductLevel2   = N.ProductLevel2
    AND c.ProductLevel3   = N.ProductLevel3
    AND c.RCC_GLCode      = N.RCC_GLCode
    AND c.Channel         = N.Channel
    AND c.Channel2        = N.Channel2
    AND c.INS_InsurerName = N.INS_InsurerName
    AND c.Make            = N.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(N.PhasingCurve,'')
    AND c.PrimaryAgent    = N.PrimaryAgent
    AND c.SubAgent        = N.SubAgent
    AND c.RTF_TermPeriod  = N.RTF_TermPeriod
    AND c.ARG_Name        = N.ARG_Name
    AND c.MTH             = N.MTH
LEFT JOIN nb2 ON 1=1
    AND c.POL_Status      = nb2.POL_Status
    AND c.PaymentFrequency= nb2.PaymentFrequency
    AND c.ProductLevel1   = nb2.ProductLevel1
    AND c.ProductLevel2   = nb2.ProductLevel2
    AND c.ProductLevel3   = nb2.ProductLevel3
    AND c.RCC_GLCode      = nb2.RCC_GLCode
    AND c.Channel         = nb2.Channel
    AND c.Channel2        = nb2.Channel2
    AND c.INS_InsurerName = nb2.INS_InsurerName
    AND c.Make            = nb2.Make
    AND ISNULL(c.PhasingCurve,'') = ISNULL(nb2.PhasingCurve,'')
    AND c.PrimaryAgent    = nb2.PrimaryAgent
    AND c.SubAgent        = nb2.SubAgent
    AND c.RTF_TermPeriod  = nb2.RTF_TermPeriod
    AND c.ARG_Name        = nb2.ARG_Name
    AND c.MTH             = nb2.MTH;

-- Optional sanity check
SELECT * FROM Deloitte.dbo.Profiling_Wty ORDER BY MTH DESC;

-- Garbage collection of temps
DROP TABLE IF EXISTS #Pol;
DROP TABLE IF EXISTS #ClaimsInfo;
DROP TABLE IF EXISTS #GWP;
DROP TABLE IF EXISTS #Exposure;
DROP TABLE IF EXISTS #MTH;
DROP TABLE IF EXISTS #Cancellations;
-- Persisted outputs remain:
--   Deloitte.dbo.Profiling_Wty_Policy
--   Deloitte.dbo.Profiling_Wty_GWP
--   Deloitte.dbo.Profiling_Wty_EarnedFund
--   Deloitte.dbo.Profiling_Wty_Exposure
--   Deloitte.dbo.Profiling_Wty
