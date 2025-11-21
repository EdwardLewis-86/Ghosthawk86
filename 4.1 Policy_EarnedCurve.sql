/*------------------------------------------
Returns the policy linked to an earning curve
Returns the policy not linked to an earning curve
       - if Evolve.Policy.POL_PolicyTerm = -1 -> 'Open-ended'
       - if Evolve.Policy.POL_PolicyTerm IS NULL -> use UPP.Term
--------------------------------------------*/

USE Evolve;
GO

-- Step 0: Drop temp tables if they already exist
IF OBJECT_ID('tempdb..#PivotedCurveResult') IS NOT NULL DROP TABLE #PivotedCurveResult;
IF OBJECT_ID('tempdb..#InForcePolicies') IS NOT NULL DROP TABLE #InForcePolicies;

-- Step 1: Define the CTEs
WITH BaseData AS (
    SELECT 
        INS.INS_InsurerName                      AS Insurer,
        pol.POL_PolicyNumber                     AS PolicyNumber,
        pol.policy_id                            AS PolicyID,
        POS.POS_Description                      AS PolicyStatus,
        PRD.PRD_Name                             AS ProductName,
        pol.POL_Product_ID                       AS ProductID,

        -- >>> Inserted, positioned just before PolicyFrequency
        pol.POL_PolicyTerm                       AS POL_PolicyTerm,
        RTF.RTF_TermPeriod                       AS RTF_TermPeriod,
        RTF.RTF_Description                      AS PolicyFrequency,

        rcc.RCC_Description                      AS CellCaptive,
        SUM(ISNULL(ISUM.ITS_Premium, 0))         AS Premium,
        CONVERT(date, pol.POL_OriginalStartDate) AS OriginalStartDate,
        CONVERT(date, pol.POL_StartDate)         AS StartDate,
        CONVERT(date, pol.POL_EndDate)           AS EndDate,
        PV1.PRV_FullName                         AS VariantLevel1Name,
        PV2.PRV_FullName                         AS VariantLevel2Name,
        PV3.PRV_FullName                         AS VariantLevel3Name,
        PV3.PRV_Code                             AS ProductCode,
        dch.DCH_Name                             AS EarningCurve,
        dci.DCI_Month,
        dci.DCI_MonthlyPercentage
    FROM Evolve.dbo.Policy AS pol
    INNER JOIN Evolve.dbo.Arrangement AS arg 
        ON pol.POL_Arrangement_ID = arg.Arrangement_Id
    INNER JOIN Evolve.dbo.DisbursementCurveProduct AS crv 
        ON pol.POL_ProductVariantLevel3_ID = crv.DCP_Product_Id 
        AND crv.DCP_Deleted = 0
    INNER JOIN Evolve.dbo.DisbursementCurveHeader AS dch 
        ON dch.DisbursementCurveHeader_Id = crv.DCP_DisbursementCurveHeader_Id 
        AND dch.DCH_Deleted = 0 
        AND dch.DCH_TermFrequency_Id = pol.POL_ProductTerm_ID 
        AND dch.DCH_Enabled = 1
    INNER JOIN Evolve.dbo.DisbursementCurveItem AS dci 
        ON dci.DCI_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id 
        AND dci.DCI_Deleted = 0
    LEFT JOIN Evolve.dbo.PolicyInsurerLink AS PIL 
        ON pol.Policy_ID = PIL.PIL_Policy_ID
    LEFT JOIN Evolve.dbo.Insurer AS INS 
        ON INS.Insurer_ID = PIL.PIL_Insurer_ID
    LEFT JOIN Evolve.dbo.ReferencePolicyStatus AS POS 
        ON POS.PolicyStatus_ID = pol.POL_Status
    LEFT JOIN Evolve.dbo.Product AS PRD 
        ON PRD.Product_Id = pol.POL_Product_ID
    LEFT JOIN Evolve.dbo.ReferenceTermFrequency AS RTF 
        ON RTF.TermFrequency_Id = pol.POL_ProductTerm_ID
    LEFT JOIN Evolve.dbo.ProductVariant AS PV1 
        ON PV1.ProductVariant_Id = pol.POL_ProductVariantLevel1_ID
    LEFT JOIN Evolve.dbo.ProductVariant AS PV2 
        ON PV2.ProductVariant_Id = pol.POL_ProductVariantLevel2_ID
    LEFT JOIN Evolve.dbo.ProductVariant AS PV3 
        ON PV3.ProductVariant_Id = pol.POL_ProductVariantLevel3_ID
    LEFT JOIN Evolve.dbo.ReferenceCellCaptive AS rcc 
        ON arg.ARG_CellCaptive = rcc.ReferenceCellCaptive_Code AND rcc.RCC_Deleted = 0
    LEFT JOIN Evolve.dbo.ItemSummary AS ISUM
        ON ISUM.ITS_Policy_ID = pol.Policy_ID
        AND ISUM.ITS_Premium > 0
        AND ISUM.ITS_Deleted = 0
    WHERE POS.POS_Description = 'In Force'
    GROUP BY
        INS.INS_InsurerName,
        pol.POL_PolicyNumber,
        pol.policy_id,
        POS.POS_Description,
        PRD.PRD_Name,
        pol.POL_Product_ID,
        pol.POL_PolicyTerm,
        RTF.RTF_TermPeriod,
        RTF.RTF_Description,
        rcc.RCC_Description,
        pol.POL_OriginalStartDate,
        pol.POL_StartDate,
        pol.POL_EndDate,
        PV1.PRV_FullName,
        PV2.PRV_FullName,
        PV3.PRV_FullName,
        PV3.PRV_Code,
        dch.DCH_Name,
        dci.DCI_Month,
        dci.DCI_MonthlyPercentage
),
PivotedCurve AS (
    SELECT *
    FROM (
        SELECT  
            Insurer,
            PolicyNumber,
            PolicyID,
            PolicyStatus,
            ProductName,
            ProductID,

            -- >>> Keep order: the two new fields just before PolicyFrequency
            POL_PolicyTerm,
            RTF_TermPeriod,
            PolicyFrequency,

            CellCaptive,
            Premium,
            OriginalStartDate,
            StartDate,
            EndDate,
            EarningCurve,
            VariantLevel1Name,
            VariantLevel2Name,
            VariantLevel3Name,
            ProductCode,
            DCI_Month,
            DCI_MonthlyPercentage
        FROM BaseData
    ) AS SourceTable
    PIVOT (
        MAX(DCI_MonthlyPercentage)
        FOR DCI_Month IN (
            [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12],
            [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24],
            [25], [26], [27], [28], [29], [30], [31], [32], [33], [34], [35], [36],
            [37], [38], [39], [40], [41], [42], [43], [44], [45], [46], [47], [48],
            [49], [50], [51], [52], [53], [54], [55], [56], [57], [58], [59], [60],
            [61], [62], [63], [64], [65], [66], [67], [68], [69], [70], [71], [72],
            [73], [74], [75], [76], [77], [78], [79], [80], [81], [82], [83], [84]
        )
    ) AS P
)

-- Step 2: Materialize PivotedCurve into temp table
SELECT *
INTO #PivotedCurveResult
FROM PivotedCurve;

-- Step 3: Materialize all In Force policies into temp table
SELECT 
    POL.Policy_ID                              AS PolicyID,
    POL.POL_PolicyNumber                       AS PolicyNumber,
    INS.INS_InsurerName                        AS Insurer,
    POS.POS_Description                        AS PolicyStatus,
    PRD.PRD_Name                               AS ProductName,
    POL.POL_Product_ID                         AS ProductID,

    -- >>> Inserted, positioned just before PolicyFrequency
    POL.POL_PolicyTerm                         AS POL_PolicyTerm,
    RTF.RTF_TermPeriod                         AS RTF_TermPeriod,
    RTF.RTF_Description                        AS PolicyFrequency,

    RCC.RCC_Description                        AS CellCaptive,
    (
        SELECT SUM(ISNULL(ITS_Premium, 0))
        FROM ItemSummary
        WHERE ITS_Policy_ID = POL.Policy_ID
          AND ITS_Premium > 0
          AND ITS_Deleted = 0
    )                                          AS Premium,
    CONVERT(date, POL.POL_OriginalStartDate)   AS OriginalStartDate,
    CONVERT(date, POL.POL_StartDate)           AS StartDate,
    CONVERT(date, POL.POL_EndDate)             AS EndDate,
    PV1.PRV_FullName                           AS VariantLevel1Name,
    PV2.PRV_FullName                           AS VariantLevel2Name,
    PV3.PRV_FullName                           AS VariantLevel3Name,
    PV3.PRV_Code                               AS ProductCode
INTO #InForcePolicies
FROM Policy POL
INNER JOIN Product PRD ON POL.POL_Product_ID = PRD.Product_Id AND PRD.PRD_Deleted = 0
LEFT JOIN PolicyInsurerLink PIL ON POL.Policy_ID = PIL.PIL_Policy_ID
LEFT JOIN Insurer INS ON PIL.PIL_Insurer_ID = INS.Insurer_ID
LEFT JOIN ReferencePolicyStatus POS ON POS.PolicyStatus_ID = POL.POL_Status
LEFT JOIN ReferenceTermFrequency RTF ON RTF.TermFrequency_Id = POL.POL_ProductTerm_ID
LEFT JOIN Arrangement ARG ON POL.POL_Arrangement_ID = ARG.Arrangement_Id
LEFT JOIN ReferenceCellCaptive RCC ON ARG.ARG_CellCaptive = RCC.ReferenceCellCaptive_Code AND RCC.RCC_Deleted = 0
LEFT JOIN ProductVariant PV1 ON POL.POL_ProductVariantLevel1_ID = PV1.ProductVariant_Id
LEFT JOIN ProductVariant PV2 ON POL.POL_ProductVariantLevel2_ID = PV2.ProductVariant_Id
LEFT JOIN ProductVariant PV3 ON POL.POL_ProductVariantLevel3_ID = PV3.ProductVariant_Id
WHERE POL.POL_Deleted = 0
  AND POS.POS_Description = 'In Force';

-- Step 4: Return both result sets

-- Policies with valid curves
SELECT * FROM #PivotedCurveResult;

-- In Force Policies missing from curve AND frequency NOT Monthly
SELECT *
FROM #InForcePolicies IFP
WHERE PolicyFrequency <> 'Monthly'
  AND OriginalStartDate < '2025-09-01'  
  AND PolicyStatus = 'In Force'
  AND NOT EXISTS (
    SELECT 1
    FROM #PivotedCurveResult PC
    WHERE PC.PolicyID = IFP.PolicyID
);
