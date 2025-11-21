USE [Evolve];
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

------------------------------------------------------------
-- 0) Safe loader for product IDs (validates GUIDs first)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Products_raw')  IS NOT NULL DROP TABLE #Products_raw;
IF OBJECT_ID('tempdb..#Products')      IS NOT NULL DROP TABLE #Products;
IF OBJECT_ID('tempdb..#BadProducts')   IS NOT NULL DROP TABLE #BadProducts;

CREATE TABLE #Products_raw (RawId NVARCHAR(64) NOT NULL);

INSERT INTO #Products_raw(RawId) VALUES
(N'83A65AC4-37EC-4776-959D-99D46D0A2A10'), -- LPP Hollard
(N'DF78BA49-F342-4745-B3B9-39F21430EB24'), -- LPP Centriq
(N'DDDC2DA4-881F-40B9-A156-8B7EA881863A'), -- Adcover (H)
(N'D0A30440-6F96-4735-A841-F601504BE51C'), -- VVP (Adcover)(H)
(N'436BB1D0-CB35-4FF0-BD50-A316A08AE87B'), -- Adcover (H)
(N'70292F27-B7EE-4274-8B51-E345F4C1AD18'), -- Adcover & Deposit Cover Combo (Q)
(N'77C92C34-0CBB-4554-BD41-01F2D8F5FC11'), -- VVP (Adcover)(Q)
(N'86E44060-B546-4A65-9464-9C4F78C1681E'), -- Adcover & Deposit Cover Combo (H)
(N'1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB'), -- Deposit Cover (H)
(N'5557806D-8733-458E-969A-9134F37C77D2'), -- AP Plus + Deposit (yearly)
(N'A80549F3-E47F-44C1-8037-F065522A03F6'), -- Deposit Cover (Q)
(N'529AFE28-A2BF-4841-9B56-F334660C6CBD'), -- Paint Tech (H)
(N'A68AD927-C8B3-47A1-909E-785BDB017377'), -- Paint Tech (Q)
(N'01A81AE2-8478-45FB-8C0D-5A6E796C1B39'), -- Tyre & Rim
(N'20AA9350-3FD9-4FE7-B705-3E1CCD639F94'), -- Scratch & Dent
(N'219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'); -- Warranty

-- find any bad GUIDs
SELECT *
INTO #BadProducts
FROM (
    SELECT RawId
    FROM #Products_raw
    WHERE TRY_CONVERT(UNIQUEIDENTIFIER, RawId) IS NULL
) bp;

IF EXISTS (SELECT 1 FROM #BadProducts)
BEGIN
    SELECT 'These product IDs are not valid GUIDs. Fix them first:' AS Message, RawId
    FROM #BadProducts;
    RETURN;
END;

CREATE TABLE #Products (ProductID UNIQUEIDENTIFIER PRIMARY KEY);
INSERT INTO #Products(ProductID)
SELECT TRY_CONVERT(UNIQUEIDENTIFIER, RawId) FROM #Products_raw;

------------------------------------------------------------
-- 1) Policies for those products (scope)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#PolScope') IS NOT NULL DROP TABLE #PolScope;
CREATE TABLE #PolScope (
    Policy_ID   UNIQUEIDENTIFIER PRIMARY KEY,
    Product_Id  UNIQUEIDENTIFIER NOT NULL,
    Level3_Id   UNIQUEIDENTIFIER NOT NULL
);

INSERT INTO #PolScope (Policy_ID, Product_Id, Level3_Id)
SELECT DISTINCT
    TRY_CONVERT(UNIQUEIDENTIFIER, p.Policy_ID),
    TRY_CONVERT(UNIQUEIDENTIFIER, p.POL_Product_ID),
    TRY_CONVERT(UNIQUEIDENTIFIER, p.POL_ProductVariantLevel3_ID)
FROM Evolve.dbo.Policy p WITH (NOLOCK)
JOIN #Products pr ON pr.ProductID = TRY_CONVERT(UNIQUEIDENTIFIER, p.POL_Product_ID)
WHERE p.POL_Deleted = 0
  AND TRY_CONVERT(UNIQUEIDENTIFIER, p.POL_ProductVariantLevel3_ID) IS NOT NULL;

CREATE INDEX IX_PolScope_L3   ON #PolScope(Level3_Id);
CREATE INDEX IX_PolScope_Prod ON #PolScope(Product_Id);

------------------------------------------------------------
-- 2) Variant chain for DISTINCT Level3s
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Var') IS NOT NULL DROP TABLE #Var;
CREATE TABLE #Var (
    Level3_Id UNIQUEIDENTIFIER PRIMARY KEY,
    Product_Code NVARCHAR(100),
    Level3_Name NVARCHAR(400),
    Level2_Id UNIQUEIDENTIFIER NULL,
    Level2_Name NVARCHAR(400) NULL,
    Level1_Id UNIQUEIDENTIFIER NULL,
    Level1_Name NVARCHAR(400) NULL,
    V3_RaiseKey UNIQUEIDENTIFIER NULL,
    V3_CancelKey UNIQUEIDENTIFIER NULL,
    V3_UprKey   UNIQUEIDENTIFIER NULL,
    V2_RaiseKey UNIQUEIDENTIFIER NULL,
    V2_CancelKey UNIQUEIDENTIFIER NULL,
    V2_UprKey   UNIQUEIDENTIFIER NULL,
    V1_RaiseKey UNIQUEIDENTIFIER NULL,
    V1_CancelKey UNIQUEIDENTIFIER NULL,
    V1_UprKey   UNIQUEIDENTIFIER NULL
);

;WITH L3 AS (SELECT DISTINCT Level3_Id FROM #PolScope)
INSERT INTO #Var
SELECT
    v3.ProductVariant_Id,
    v3.PRV_Code,
    v3.PRV_FullName,
    v2.ProductVariant_Id,
    v2.PRV_FullName,
    v1.ProductVariant_Id,
    v1.PRV_FullName,

    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v3.PRV_RaiseRule_Id,'')),
    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v3.PRV_CancelationRule_Id,'')),
    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v3.PRV_UprRule_Id,'')),

    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v2.PRV_RaiseRule_Id,'')),
    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v2.PRV_CancelationRule_Id,'')),
    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v2.PRV_UprRule_Id,'')),

    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v1.PRV_RaiseRule_Id,'')),
    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v1.PRV_CancelationRule_Id,'')),
    TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(v1.PRV_UprRule_Id,''))
FROM L3
JOIN Evolve.dbo.ProductVariant v3 WITH (NOLOCK)
  ON v3.ProductVariant_Id = L3.Level3_Id
LEFT JOIN Evolve.dbo.ProductVariant v2 WITH (NOLOCK)
  ON v2.ProductVariant_Id = v3.PRV_Parent_ID AND v2.PRV_Deleted = 0
LEFT JOIN Evolve.dbo.ProductVariant v1 WITH (NOLOCK)
  ON v1.ProductVariant_Id = v2.PRV_Parent_ID AND v1.PRV_Deleted = 0
WHERE v3.PRV_Deleted = 0;

------------------------------------------------------------
-- 3) Anchor (policies × variants)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#Anchor') IS NOT NULL DROP TABLE #Anchor;
CREATE TABLE #Anchor (
    Policy_ID UNIQUEIDENTIFIER NOT NULL,
    Product_Id UNIQUEIDENTIFIER NOT NULL,
    Level3_Id UNIQUEIDENTIFIER NOT NULL,
    Product_Code NVARCHAR(100),
    Level1_Name NVARCHAR(400),
    Level2_Name NVARCHAR(400),
    Level3_Name NVARCHAR(400),
    V3_RaiseKey UNIQUEIDENTIFIER NULL,
    V3_CancelKey UNIQUEIDENTIFIER NULL,
    V3_UprKey   UNIQUEIDENTIFIER NULL,
    V2_RaiseKey UNIQUEIDENTIFIER NULL,
    V2_CancelKey UNIQUEIDENTIFIER NULL,
    V2_UprKey   UNIQUEIDENTIFIER NULL,
    V1_RaiseKey UNIQUEIDENTIFIER NULL,
    V1_CancelKey UNIQUEIDENTIFIER NULL,
    V1_UprKey   UNIQUEIDENTIFIER NULL,
    PRIMARY KEY (Policy_ID, Level3_Id)   -- unnamed to avoid collisions
);

INSERT INTO #Anchor
SELECT
    ps.Policy_ID,
    ps.Product_Id,
    ps.Level3_Id,
    v.Product_Code,
    v.Level1_Name,
    v.Level2_Name,
    v.Level3_Name,
    v.V3_RaiseKey, v.V3_CancelKey, v.V3_UprKey,
    v.V2_RaiseKey, v.V2_CancelKey, v.V2_UprKey,
    v.V1_RaiseKey, v.V1_CancelKey, v.V1_UprKey
FROM #PolScope ps
JOIN #Var v ON v.Level3_Id = ps.Level3_Id;

CREATE INDEX IX_Anchor_Prod ON #Anchor(Product_Id);
CREATE INDEX IX_Anchor_L3   ON #Anchor(Level3_Id);

------------------------------------------------------------
-- 4) Plan names (one value per source)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#PlanVar') IS NOT NULL DROP TABLE #PlanVar;
CREATE TABLE #PlanVar (
    Policy_ID UNIQUEIDENTIFIER NOT NULL,
    Level3_Id UNIQUEIDENTIFIER NOT NULL,
    PlanVar NVARCHAR(400) NULL,
    PRIMARY KEY (Policy_ID, Level3_Id)
);

INSERT INTO #PlanVar
SELECT a.Policy_ID, a.Level3_Id, MIN(prp.PRP_PlanName)
FROM #Anchor a
JOIN Evolve.dbo.DisbursementValueSetHeader vsh WITH (NOLOCK)
  ON vsh.VSH_ProductVariant_Id = a.Level3_Id AND vsh.VSH_Deleted = 0
JOIN Evolve.dbo.DisbursementValueSetDetail vsd WITH (NOLOCK)
  ON vsd.VSD_DisbursementValueSetHeader_Id = vsh.DisbursementValueSetHeader_Id AND vsd.VSD_Deleted = 0
JOIN Evolve.dbo.ProductPlans prp WITH (NOLOCK)
  ON prp.ProductPlans_Id = vsd.VSD_ProductPlans_Id AND prp.PRP_Deleted = 0
GROUP BY a.Policy_ID, a.Level3_Id;

IF OBJECT_ID('tempdb..#PlanProd') IS NOT NULL DROP TABLE #PlanProd;
CREATE TABLE #PlanProd (
    Policy_ID UNIQUEIDENTIFIER NOT NULL,
    Level3_Id UNIQUEIDENTIFIER NOT NULL,
    PlanProd NVARCHAR(400) NULL,
    PRIMARY KEY (Policy_ID, Level3_Id)
);

INSERT INTO #PlanProd
SELECT a.Policy_ID, a.Level3_Id, MIN(prp.PRP_PlanName)
FROM #Anchor a
JOIN Evolve.dbo.DisbursementValueSetHeader vsh WITH (NOLOCK)
  ON vsh.VSH_Product_Id = a.Product_Id AND vsh.VSH_Deleted = 0
JOIN Evolve.dbo.DisbursementValueSetDetail vsd WITH (NOLOCK)
  ON vsd.VSD_DisbursementValueSetHeader_Id = vsh.DisbursementValueSetHeader_Id AND vsd.VSD_Deleted = 0
JOIN Evolve.dbo.ProductPlans prp WITH (NOLOCK)
  ON prp.ProductPlans_Id = vsd.VSD_ProductPlans_Id AND prp.PRP_Deleted = 0
GROUP BY a.Policy_ID, a.Level3_Id;

IF OBJECT_ID('tempdb..#PlanPol') IS NOT NULL DROP TABLE #PlanPol;
CREATE TABLE #PlanPol (
    Policy_ID UNIQUEIDENTIFIER PRIMARY KEY,
    PlanPol NVARCHAR(400) NULL
);

INSERT INTO #PlanPol
SELECT a.Policy_ID, MIN(prp.PRP_PlanName)
FROM #Anchor a
JOIN Evolve.dbo.PolicyCreditLifeItem pci WITH (NOLOCK)
  ON pci.PCI_Policy_ID = a.Policy_ID AND pci.PCI_Deleted = 0
JOIN Evolve.dbo.ProductPlans prp WITH (NOLOCK)
  ON prp.ProductPlans_Id = pci.PCI_Plan_ID AND prp.PRP_Deleted = 0
GROUP BY a.Policy_ID;

------------------------------------------------------------
-- 5) Product-level rule keys (PDL / DBG) — DEDUPED
------------------------------------------------------------
IF OBJECT_ID('tempdb..#ProdRules') IS NOT NULL DROP TABLE #ProdRules;
CREATE TABLE #ProdRules (
    Product_Id  UNIQUEIDENTIFIER PRIMARY KEY,
    P_RaiseKey  UNIQUEIDENTIFIER NULL,
    P_CancelKey UNIQUEIDENTIFIER NULL,
    P_UprKey    UNIQUEIDENTIFIER NULL
);

;WITH DistProd AS (SELECT DISTINCT Product_Id FROM #Anchor)
INSERT INTO #ProdRules(Product_Id, P_RaiseKey, P_CancelKey, P_UprKey)
SELECT
    dp.Product_Id,
    MIN(COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(pdl.PDL_RaiseRule_Id,'')),
                 TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(dbg.DBG_RaiseRule_Id,'')))) AS P_RaiseKey,
    MIN(COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(pdl.PDL_CancelationRule_Id,'')),
                 TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(dbg.DBG_CancelationRule_Id,'')))) AS P_CancelKey,
    MIN(COALESCE(TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(pdl.PDL_UprRule_Id,'')),
                 TRY_CONVERT(UNIQUEIDENTIFIER, NULLIF(dbg.DBG_UprRule_Id,'')))) AS P_UprKey
FROM DistProd dp
LEFT JOIN Evolve.dbo.ProductDisbursementLink pdl WITH (NOLOCK)
       ON pdl.PDL_Product_Id = dp.Product_Id AND pdl.PDL_Deleted = 0
LEFT JOIN Evolve.dbo.DisbursementGroups dbg WITH (NOLOCK)
       ON dbg.DisbursementGroup_Id = pdl.PDL_DisbursementGroup_Id AND dbg.DBG_Deleted = 0
GROUP BY dp.Product_Id;

------------------------------------------------------------
-- 6) Effective rule keys (VL3→VL2→VL1→Product) — DEDUPED
------------------------------------------------------------
IF OBJECT_ID('tempdb..#RuleKey') IS NOT NULL DROP TABLE #RuleKey;
CREATE TABLE #RuleKey(
    Level3_Id  UNIQUEIDENTIFIER NOT NULL,
    Product_Id UNIQUEIDENTIFIER NOT NULL,
    RaiseKey   UNIQUEIDENTIFIER NULL,
    CancelKey  UNIQUEIDENTIFIER NULL,
    UprKey     UNIQUEIDENTIFIER NULL,
    PRIMARY KEY(Level3_Id, Product_Id)
);

INSERT INTO #RuleKey(Level3_Id, Product_Id, RaiseKey, CancelKey, UprKey)
SELECT
    a.Level3_Id,
    a.Product_Id,
    MIN(COALESCE(a.V3_RaiseKey,  a.V2_RaiseKey,  a.V1_RaiseKey,  pr.P_RaiseKey))  AS RaiseKey,
    MIN(COALESCE(a.V3_CancelKey, a.V2_CancelKey, a.V1_CancelKey, pr.P_CancelKey)) AS CancelKey,
    MIN(COALESCE(a.V3_UprKey,    a.V2_UprKey,    a.V1_UprKey,    pr.P_UprKey))    AS UprKey
FROM #Anchor a
LEFT JOIN #ProdRules pr ON pr.Product_Id = a.Product_Id
GROUP BY a.Level3_Id, a.Product_Id;

------------------------------------------------------------
-- 7) Map keys → Disbursement (via Set, else direct)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#AllKeys') IS NOT NULL DROP TABLE #AllKeys;
CREATE TABLE #AllKeys (KeyId UNIQUEIDENTIFIER PRIMARY KEY);

INSERT INTO #AllKeys(KeyId)
SELECT DISTINCT RaiseKey  FROM #RuleKey WHERE RaiseKey  IS NOT NULL
UNION SELECT DISTINCT CancelKey FROM #RuleKey WHERE CancelKey IS NOT NULL
UNION SELECT DISTINCT UprKey    FROM #RuleKey WHERE UprKey    IS NOT NULL;

IF OBJECT_ID('tempdb..#MapSet') IS NOT NULL DROP TABLE #MapSet;
CREATE TABLE #MapSet (
    KeyId UNIQUEIDENTIFIER PRIMARY KEY,
    Disbursement_Id UNIQUEIDENTIFIER NULL
);

INSERT INTO #MapSet(KeyId, Disbursement_Id)
SELECT ak.KeyId, ds.DBS_Disbursement_ID
FROM #AllKeys ak
JOIN Evolve.dbo.DisbursementSet ds WITH (NOLOCK)
  ON ds.DisbursementSet_Id = ak.KeyId AND ds.DBS_Deleted = 0;

IF OBJECT_ID('tempdb..#MapDisb') IS NOT NULL DROP TABLE #MapDisb;
CREATE TABLE #MapDisb (
    KeyId UNIQUEIDENTIFIER PRIMARY KEY,
    DSM_RuleName NVARCHAR(400) NULL,
    DSM_RuleDescription NVARCHAR(MAX) NULL
);

-- From set
INSERT INTO #MapDisb(KeyId, DSM_RuleName, DSM_RuleDescription)
SELECT ms.KeyId, d.DSM_RuleName, d.DSM_RuleDescription
FROM #MapSet ms
JOIN Evolve.dbo.Disbursement d WITH (NOLOCK)
  ON d.Disbursement_Id = ms.Disbursement_Id AND d.DSM_Deleted = 0;

-- Direct (keys which weren't sets)
INSERT INTO #MapDisb(KeyId, DSM_RuleName, DSM_RuleDescription)
SELECT ak.KeyId, d.DSM_RuleName, d.DSM_RuleDescription
FROM #AllKeys ak
LEFT JOIN #MapDisb md ON md.KeyId = ak.KeyId
JOIN Evolve.dbo.Disbursement d WITH (NOLOCK)
  ON d.Disbursement_Id = ak.KeyId AND d.DSM_Deleted = 0
WHERE md.KeyId IS NULL;

------------------------------------------------------------
-- 8) Main detailed output (unchanged)
------------------------------------------------------------
SELECT
    a.Product_Code                              AS Product_Code,
    a.Level3_Name                               AS Product_Name,
    COALESCE(pv.PlanVar, pp.PlanProd, ppl.PlanPol) AS Plan_Name,
    a.Level1_Name                               AS [Variant_Level_1],
    a.Level2_Name                               AS [Variant_Level_2],
    a.Level3_Name                               AS [Variant_Level_3],
    mdR.DSM_RuleName                            AS Raise_RuleName,
    mdR.DSM_RuleDescription                     AS Raise_RuleDescription,
    mdC.DSM_RuleName                            AS Cancel_RuleName,
    mdC.DSM_RuleDescription                     AS Cancel_RuleDescription,
    mdU.DSM_RuleName                            AS Upr_RuleName,
    mdU.DSM_RuleDescription                     AS Upr_RuleDescription
FROM #Anchor a
LEFT JOIN #PlanVar pv ON pv.Policy_ID = a.Policy_ID AND pv.Level3_Id = a.Level3_Id
LEFT JOIN #PlanProd pp ON pp.Policy_ID = a.Policy_ID AND pp.Level3_Id = a.Level3_Id
LEFT JOIN #PlanPol  ppl ON ppl.Policy_ID = a.Policy_ID
LEFT JOIN #RuleKey rk ON rk.Level3_Id = a.Level3_Id AND rk.Product_Id = a.Product_Id
LEFT JOIN #MapDisb mdR ON mdR.KeyId = rk.RaiseKey
LEFT JOIN #MapDisb mdC ON mdC.KeyId = rk.CancelKey
LEFT JOIN #MapDisb mdU ON mdU.KeyId = rk.UprKey
ORDER BY a.Product_Code, Plan_Name, [Variant_Level_1], [Variant_Level_2], [Variant_Level_3]
OPTION (RECOMPILE);

------------------------------------------------------------
-- 9) NEW: Distinct-by-product RULE SUMMARY (text)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#ProductRuleSummary') IS NOT NULL DROP TABLE #ProductRuleSummary;
CREATE TABLE #ProductRuleSummary (
    Product_Code NVARCHAR(100) NOT NULL,
    Raise_RuleName NVARCHAR(400) NULL,
    Raise_RuleDescription NVARCHAR(MAX) NULL,
    Cancel_RuleName NVARCHAR(400) NULL,
    Cancel_RuleDescription NVARCHAR(MAX) NULL,
    Upr_RuleName NVARCHAR(400) NULL,
    Upr_RuleDescription NVARCHAR(MAX) NULL,
    RaiseKey UNIQUEIDENTIFIER NULL,
    CancelKey UNIQUEIDENTIFIER NULL,
    UprKey UNIQUEIDENTIFIER NULL
);

;WITH Base AS (
    SELECT DISTINCT
        a.Product_Code,
        mdR.DSM_RuleName        AS Raise_RuleName,
        mdR.DSM_RuleDescription AS Raise_RuleDescription,
        mdC.DSM_RuleName        AS Cancel_RuleName,
        mdC.DSM_RuleDescription AS Cancel_RuleDescription,
        mdU.DSM_RuleName        AS Upr_RuleName,
        mdU.DSM_RuleDescription AS Upr_RuleDescription,
        rk.RaiseKey,
        rk.CancelKey,
        rk.UprKey
    FROM #Anchor a
    LEFT JOIN #RuleKey rk
           ON rk.Level3_Id = a.Level3_Id
          AND rk.Product_Id = a.Product_Id
    LEFT JOIN #MapDisb mdR ON mdR.KeyId = rk.RaiseKey
    LEFT JOIN #MapDisb mdC ON mdC.KeyId = rk.CancelKey
    LEFT JOIN #MapDisb mdU ON mdU.KeyId = rk.UprKey
)
INSERT INTO #ProductRuleSummary (Product_Code, Raise_RuleName, Raise_RuleDescription,
                                 Cancel_RuleName, Cancel_RuleDescription,
                                 Upr_RuleName, Upr_RuleDescription,
                                 RaiseKey, CancelKey, UprKey)
SELECT DISTINCT
    Product_Code,
    Raise_RuleName, Raise_RuleDescription,
    Cancel_RuleName, Cancel_RuleDescription,
    Upr_RuleName, Upr_RuleDescription,
    RaiseKey, CancelKey, UprKey
FROM Base;

-- Output #1
SELECT
    Product_Code,
    Raise_RuleName,  Raise_RuleDescription,
    Cancel_RuleName, Cancel_RuleDescription,
    Upr_RuleName,    Upr_RuleDescription
FROM #ProductRuleSummary
ORDER BY Product_Code, Raise_RuleName, Cancel_RuleName, Upr_RuleName;

------------------------------------------------------------
-- 10) NEW: Up to 5 "active" policies per summary row
--       (policy number added at SELECT time via dynamic SQL)
------------------------------------------------------------
IF OBJECT_ID('tempdb..#SamplePolicies') IS NOT NULL DROP TABLE #SamplePolicies;
CREATE TABLE #SamplePolicies (
    Product_Code NVARCHAR(100) NOT NULL,
    Raise_RuleName NVARCHAR(400) NULL,
    Cancel_RuleName NVARCHAR(400) NULL,
    Upr_RuleName NVARCHAR(400) NULL,
    SampleOrder INT NOT NULL,
    Policy_ID UNIQUEIDENTIFIER NOT NULL,
    Plan_Name NVARCHAR(400) NULL,
    Variant_Level_1 NVARCHAR(400) NULL,
    Variant_Level_2 NVARCHAR(400) NULL,
    Variant_Level_3 NVARCHAR(400) NULL
);

INSERT INTO #SamplePolicies (
    Product_Code, Raise_RuleName, Cancel_RuleName, Upr_RuleName,
    SampleOrder, Policy_ID, Plan_Name, Variant_Level_1, Variant_Level_2, Variant_Level_3
)
SELECT
    prs.Product_Code,
    prs.Raise_RuleName,
    prs.Cancel_RuleName,
    prs.Upr_RuleName,
    x.rn AS SampleOrder,
    x.Policy_ID,
    x.Plan_Name,
    x.Level1_Name,
    x.Level2_Name,
    x.Level3_Name
FROM #ProductRuleSummary prs
CROSS APPLY (
    SELECT TOP (5)
        a.Policy_ID,
        COALESCE(pv.PlanVar, pp.PlanProd, ppl.PlanPol) AS Plan_Name,
        a.Level1_Name,
        a.Level2_Name,
        a.Level3_Name,
        ROW_NUMBER() OVER (ORDER BY a.Policy_ID) AS rn
    FROM #Anchor a
    JOIN #RuleKey rk
         ON rk.Level3_Id = a.Level3_Id
        AND rk.Product_Id = a.Product_Id
    LEFT JOIN #PlanVar pv ON pv.Policy_ID = a.Policy_ID AND pv.Level3_Id = a.Level3_Id
    LEFT JOIN #PlanProd pp ON pp.Policy_ID = a.Policy_ID AND pp.Level3_Id = a.Level3_Id
    LEFT JOIN #PlanPol  ppl ON ppl.Policy_ID = a.Policy_ID
    WHERE
        a.Product_Code = prs.Product_Code
        AND ( (rk.RaiseKey  = prs.RaiseKey)  OR (rk.RaiseKey  IS NULL AND prs.RaiseKey  IS NULL) )
        AND ( (rk.CancelKey = prs.CancelKey) OR (rk.CancelKey IS NULL AND prs.CancelKey IS NULL) )
        AND ( (rk.UprKey    = prs.UprKey)    OR (rk.UprKey    IS NULL AND prs.UprKey    IS NULL) )
    ORDER BY a.Policy_ID
) x
ORDER BY prs.Product_Code, prs.Raise_RuleName, prs.Cancel_RuleName, prs.Upr_RuleName, x.rn;

-- Detect which policy-number column exists, then output dynamically
DECLARE @PolicyNumberCol SYSNAME;

SELECT TOP (1) @PolicyNumberCol = c.name
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(N'Evolve.dbo.Policy')
  AND c.name IN (N'POL_PolicyNumber', N'POL_GeneratedPolicyNumber', N'POL_PolicyNo', N'PolicyNumber')
ORDER BY CASE c.name
           WHEN N'POL_PolicyNumber'          THEN 1
           WHEN N'POL_GeneratedPolicyNumber' THEN 2
           WHEN N'POL_PolicyNo'              THEN 3
           WHEN N'PolicyNumber'              THEN 4
           ELSE 5
         END;

IF @PolicyNumberCol IS NULL
    SET @PolicyNumberCol = N'POL_PolicyNumber'; -- harmless fallback

DECLARE @sql NVARCHAR(MAX) = N'
SELECT
    sp.Product_Code,
    sp.Raise_RuleName,
    sp.Cancel_RuleName,
    sp.Upr_RuleName,
    sp.SampleOrder,
    sp.Policy_ID,
    CAST(p.' + QUOTENAME(@PolicyNumberCol) + N' AS NVARCHAR(256)) AS Policy_Number,
    sp.Plan_Name,
    sp.Variant_Level_1,
    sp.Variant_Level_2,
    sp.Variant_Level_3
FROM #SamplePolicies sp
JOIN Evolve.dbo.Policy p WITH (NOLOCK)
  ON p.Policy_ID = sp.Policy_ID
ORDER BY sp.Product_Code, sp.Raise_RuleName, sp.Cancel_RuleName, sp.Upr_RuleName, sp.SampleOrder;';

EXEC sys.sp_executesql @sql;
