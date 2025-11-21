/* ===========================================================
   SALES VOLUME — Full (Evolve only; temp tables; type-safe)
   Adds: City, Province, Sales branch, Consultant
         Cell Captive Code/Group (CASE)
         Product Group Code/Description (CASE by Variant L1)
         Variant defaults + Warranty Booster/Non-Booster + L1 “(H)” cleanup
         "Credit Life" -> "Mobility Credit Life"
   ===========================================================*/
Use Evolve
SET NOCOUNT ON;

DECLARE @StartDate date = '2023-01-01';
DECLARE @EndDate   date = '2025-11-19';  -- inclusive

/* Clean start */
IF OBJECT_ID('tempdb..#Insurers')                IS NOT NULL DROP TABLE #Insurers;
IF OBJECT_ID('tempdb..#BasePolicies')            IS NOT NULL DROP TABLE #BasePolicies;
IF OBJECT_ID('tempdb..#PolicyInsurer')           IS NOT NULL DROP TABLE #PolicyInsurer;
IF OBJECT_ID('tempdb..#ProdMeta')                IS NOT NULL DROP TABLE #ProdMeta;
IF OBJECT_ID('tempdb..#AgentPhysical')           IS NOT NULL DROP TABLE #AgentPhysical;
IF OBJECT_ID('tempdb..#AgentLatestBranch')       IS NOT NULL DROP TABLE #AgentLatestBranch;
IF OBJECT_ID('tempdb..#AgentLatestConsultant')   IS NOT NULL DROP TABLE #AgentLatestConsultant;
IF OBJECT_ID('tempdb..#SalesMeta')               IS NOT NULL DROP TABLE #SalesMeta;
IF OBJECT_ID('tempdb..#Premium')                 IS NOT NULL DROP TABLE #Premium;
IF OBJECT_ID('tempdb..#TermTxt')                 IS NOT NULL DROP TABLE #TermTxt;

/* 0) Allowed insurers */
CREATE TABLE #Insurers(InsurerName nvarchar(200) NOT NULL PRIMARY KEY);
INSERT INTO #Insurers VALUES
(N'Hollard Short Term'),(N'Hollard Life'),(N'Centriq Short Term'),(N'Centriq Life');

/* 1) Base policies (IDs kept as NVARCHAR) */
CREATE TABLE #BasePolicies
(
    PolicyID                 nvarchar(100) NOT NULL,
    PolicyNumber             nvarchar(50)  NOT NULL,
    SaleDate                 date          NOT NULL,
    ProductID                nvarchar(100) NULL,
    ProductOptionID          nvarchar(100) NULL,
    ProductVariantL1_ID      nvarchar(100) NULL,
    ProductVariantL2_ID      nvarchar(100) NULL,
    ProductVariantL3_ID      nvarchar(100) NULL,
    ArrangementID            nvarchar(100) NULL,
    PrimaryAgentID           nvarchar(100) NULL,
    SubAgentID               nvarchar(100) NULL,
    FinanceTermID            int           NULL,
    ProductTermID            int           NULL
);

INSERT INTO #BasePolicies
SELECT
    CONVERT(nvarchar(100), p.Policy_ID),
    p.POL_PolicyNumber,
    CAST(COALESCE(p.POL_OriginalStartDate, p.POL_StartDate) AS date),
    CONVERT(nvarchar(100), p.POL_Product_ID),
    CONVERT(nvarchar(100), p.POL_ProductOption_ID),
    CONVERT(nvarchar(100), p.POL_ProductVariantLevel1_ID),
    CONVERT(nvarchar(100), p.POL_ProductVariantLevel2_ID),
    CONVERT(nvarchar(100), p.POL_ProductVariantLevel3_ID),
    CONVERT(nvarchar(100), p.POL_Arrangement_ID),
    CONVERT(nvarchar(100), p.POL_PrimaryAgent_ID),
    CONVERT(nvarchar(100), p.POL_Agent_ID),
    p.POL_FinanceTerm_ID,
    p.POL_ProductTerm_ID
FROM dbo.Policy p
WHERE p.POL_Deleted = 0
  AND CAST(COALESCE(p.POL_OriginalStartDate, p.POL_StartDate) AS date)
      BETWEEN @StartDate AND @EndDate;

/* 2) Insurer (lead flag if present) */
CREATE TABLE #PolicyInsurer
(
    PolicyID        nvarchar(100) NOT NULL,
    InsurerName     nvarchar(200) NOT NULL,
    LeadIndicator   int           NULL
);
INSERT INTO #PolicyInsurer(PolicyID, InsurerName, LeadIndicator)
SELECT
  CONVERT(nvarchar(100), pil.PIL_Policy_ID),
  ins.INS_InsurerName,
  CASE WHEN COLUMNPROPERTY(OBJECT_ID('dbo.PolicyInsurerLink'),'PIL_Lead_Indicator','ColumnId') IS NOT NULL
       THEN pil.PIL_Lead_Indicator END
FROM dbo.PolicyInsurerLink pil
JOIN dbo.Insurer ins
  ON CONVERT(nvarchar(100), ins.Insurer_Id) = CONVERT(nvarchar(100), pil.PIL_Insurer_ID);

/* 3) Product / Variant names / Product code */
CREATE TABLE #ProdMeta
(
    PolicyID        nvarchar(100) NOT NULL,
    Product         nvarchar(200) NULL,
    Var1            nvarchar(200) NULL,
    Var2            nvarchar(200) NULL,
    Var3            nvarchar(200) NULL,
    ProductCode     nvarchar(100) NULL
);
INSERT INTO #ProdMeta
SELECT
    b.PolicyID,
    prd.PRD_Name,
    pv1.PRV_FullName,
    pv2.PRV_FullName,
    pv3.PRV_FullName,
    pv3.PRV_Code
FROM #BasePolicies b
LEFT JOIN dbo.Product        prd ON CONVERT(nvarchar(100), prd.Product_Id)        = b.ProductID
LEFT JOIN dbo.ProductVariant pv1 ON CONVERT(nvarchar(100), pv1.ProductVariant_Id) = b.ProductVariantL1_ID
LEFT JOIN dbo.ProductVariant pv2 ON CONVERT(nvarchar(100), pv2.ProductVariant_Id) = b.ProductVariantL2_ID
LEFT JOIN dbo.ProductVariant pv3 ON CONVERT(nvarchar(100), pv3.ProductVariant_Id) = b.ProductVariantL3_ID;

/* 4) Latest City/Province, Branch, Consultant for the SUB-AGENT */

/* Latest default physical address per sub-agent */
CREATE TABLE #AgentPhysical
(
  AgentID  nvarchar(100) NOT NULL,
  City     nvarchar(200) NULL,
  Province nvarchar(200) NULL
);
WITH phys AS
(
  SELECT
      CONVERT(nvarchar(100), ADD_ReferenceNumber) AS AgentID,
      ADD_City,
      ADD_ProvinceState,
      ROW_NUMBER() OVER
        (PARTITION BY ADD_ReferenceNumber ORDER BY ADD_UpdateDate DESC) AS rn
  FROM dbo.AddressDetails
  WHERE ADD_Deleted = 0
    AND ADD_Default = 1
    AND ADD_AddressType_ID = 0   -- Physical
    AND ADD_ReferenceType = 501  -- Agent
)
INSERT INTO #AgentPhysical(AgentID, City, Province)
SELECT
  p.AgentID,
  p.ADD_City,
  ap.ADP_Description
FROM phys p
LEFT JOIN dbo.AddressProvinces ap
  ON ap.AddressProvinces_ID = p.ADD_ProvinceState
WHERE p.rn = 1;

/* Latest division/branch per sub-agent */
CREATE TABLE #AgentLatestBranch
(
  AgentID        nvarchar(100) NOT NULL,
  [Sales branch] nvarchar(200) NULL
);
WITH adl AS
(
  SELECT
      CONVERT(nvarchar(100), ADL_Agent_ID) AS AgentID,
      ADL_Division_ID,
      ROW_NUMBER() OVER
        (PARTITION BY ADL_Agent_ID ORDER BY ADL_CreateDate DESC) AS rn
  FROM dbo.AgentDivisionLink
  WHERE ADL_Deleted = 0
    AND (ADL_ToDate IS NULL OR ADL_ToDate = '')
)
INSERT INTO #AgentLatestBranch(AgentID, [Sales branch])
SELECT
  a.AgentID,
  br.SRN_Text
FROM adl a
LEFT JOIN dbo.SalesBranch br
  ON br.SalesRegion_ID = a.ADL_Division_ID
WHERE a.rn = 1;

/* Latest consultant per sub-agent */
CREATE TABLE #AgentLatestConsultant
(
  AgentID      nvarchar(100) NOT NULL,
  [Consultant] nvarchar(200) NULL
);
WITH acl AS
(
  SELECT
      CONVERT(nvarchar(100), ACL_Agent_ID) AS AgentID,
      ACL_Consultant_ID,
      ROW_NUMBER() OVER
        (PARTITION BY ACL_Agent_ID ORDER BY ACL_CreateDate DESC) AS rn
  FROM dbo.AgentConsultantLink
  WHERE ACL_Deleted = 0
    AND (ACL_ToDate IS NULL OR ACL_ToDate = '')
)
INSERT INTO #AgentLatestConsultant(AgentID, [Consultant])
SELECT
  a.AgentID,
  LTRIM(RTRIM(CONCAT(sc.SCO_Name, N' ', sc.SCO_Surname)))
FROM acl a
LEFT JOIN dbo.SalesConsultants sc
  ON sc.SalesConsultant_ID = a.ACL_Consultant_ID
WHERE a.rn = 1;

/* Sales meta (arrangement, cell captive, agent names/codes + new fields) */
CREATE TABLE #SalesMeta
(
    PolicyID            nvarchar(100) NOT NULL,
    ArrangementCode     nvarchar(50)  NULL,
    CellCaptive         nvarchar(200) NULL,
    AgentName           nvarchar(200) NULL, -- Sub-agent name
    PrimaryAgentCode    nvarchar(50)  NULL,
    SubAgentCode        nvarchar(50)  NULL,
    [City]              nvarchar(200) NULL,
    [Province]          nvarchar(200) NULL,
    [Sales branch]      nvarchar(200) NULL,
    [Consultant]        nvarchar(200) NULL
);
INSERT INTO #SalesMeta
SELECT
    b.PolicyID,
    a.ARG_ArrangementNumber,
    rcc.RCC_Description,
    sub.Agt_Name,
    pa.Agt_AgentNumber,
    sub.Agt_AgentNumber,
    ap.City,
    ap.Province,
    lb.[Sales branch],
    lc.[Consultant]
FROM #BasePolicies b
LEFT JOIN dbo.Arrangement a
       ON CONVERT(nvarchar(100), a.Arrangement_Id) = b.ArrangementID
LEFT JOIN dbo.ReferenceCellCaptive rcc
       ON rcc.ReferenceCellCaptive_Code = a.ARG_CellCaptive
LEFT JOIN dbo.Agent pa
       ON CONVERT(nvarchar(100), pa.Agent_Id) = b.PrimaryAgentID
LEFT JOIN dbo.Agent sub
       ON CONVERT(nvarchar(100), sub.Agent_Id) = b.SubAgentID
LEFT JOIN #AgentPhysical         ap ON ap.AgentID = b.SubAgentID
LEFT JOIN #AgentLatestBranch     lb ON lb.AgentID = b.SubAgentID
LEFT JOIN #AgentLatestConsultant lc ON lc.AgentID = b.SubAgentID;

/* 5) Premium (positive only) */
CREATE TABLE #Premium
(
    PolicyID        nvarchar(100) NOT NULL,
    PolicyPremium   decimal(18,2) NULL
);
INSERT INTO #Premium
SELECT
    b.PolicyID,
    (
      SELECT SUM(ISNULL(its.ITS_Premium,0.00))
      FROM dbo.ItemSummary its
      WHERE CONVERT(nvarchar(100), its.ITS_Policy_ID) = b.PolicyID
        AND its.ITS_Premium   > 0
        AND its.ITS_Deleted   = 0
    )
FROM #BasePolicies b;

/* 6) Term text */
CREATE TABLE #TermTxt
(
    PolicyID    nvarchar(100) NOT NULL,
    TermText    nvarchar(50)  NULL
);
INSERT INTO #TermTxt
SELECT
  b.PolicyID,
  CASE
    WHEN rtf.RTF_Description IS NOT NULL AND LEN(LTRIM(RTRIM(rtf.RTF_Description)))>0 THEN rtf.RTF_Description
    WHEN b.FinanceTermID IS NOT NULL THEN CONCAT(N'Term ', b.FinanceTermID)
    ELSE NULL
  END
FROM #BasePolicies b
LEFT JOIN dbo.ReferenceTermFrequency rtf
  ON rtf.TermFrequency_Id = b.ProductTermID;

/* 7) Final detail & rollup with rules/mappings */
WITH Detail AS
(
  SELECT
      COALESCE(NULLIF(pi_lead.InsurerName, N''), pi_any.InsurerName) AS [Insurer],

      sm.AgentName             AS [Agent],
      sm.PrimaryAgentCode      AS [Primary Agent Code],
      sm.SubAgentCode          AS [Sub Agent Code],
      sm.ArrangementCode       AS [Arrangement Code],
      sm.CellCaptive           AS [Cell Captive],

      sm.[City]                AS AgentCity,
      sm.[Province]            AS AgentProvince,
      sm.[Sales branch]        AS AgentSalesBranch,
      sm.[Consultant]          AS AgentConsultant,

      CASE WHEN pm.Product LIKE N'%Credit Life%'
           THEN REPLACE(pm.Product, N'Credit Life', N'Mobility Credit Life')
           ELSE pm.Product END                                          AS [Product],

      CASE WHEN pm.Var1 LIKE N'%Credit Life%'
           THEN REPLACE(pm.Var1, N'Credit Life', N'Mobility Credit Life')
           ELSE pm.Var1 END                                             AS [Variant Level 1],

      CASE WHEN pm.Var2 LIKE N'%Credit Life%'
           THEN REPLACE(pm.Var2, N'Credit Life', N'Mobility Credit Life')
           ELSE pm.Var2 END                                             AS [Variant Level 2],

      CASE WHEN pm.Var3 LIKE N'%Credit Life%'
           THEN REPLACE(pm.Var3, N'Credit Life', N'Mobility Credit Life')
           ELSE pm.Var3 END                                             AS [Variant Level 3],

      pm.ProductCode                                               AS [Product Code],
      ISNULL(pr.PolicyPremium, 0.00)                               AS [Policy premium],
      tt.TermText                                                  AS [Policy Term],
      b.SaleDate                                                   AS [Date]
  FROM #BasePolicies b
  LEFT JOIN #PolicyInsurer pi_lead
    ON pi_lead.PolicyID = b.PolicyID AND ISNULL(pi_lead.LeadIndicator,0) = 1
  LEFT JOIN #PolicyInsurer pi_any
    ON pi_any.PolicyID = b.PolicyID
  LEFT JOIN #ProdMeta  pm ON pm.PolicyID = b.PolicyID
  LEFT JOIN #SalesMeta sm ON sm.PolicyID = b.PolicyID
  LEFT JOIN #Premium   pr ON pr.PolicyID = b.PolicyID
  LEFT JOIN #TermTxt   tt ON tt.PolicyID = b.PolicyID
),
Norm AS
(
  SELECT
    d.*,
    V1_norm = CASE WHEN NULLIF(LTRIM(RTRIM(d.[Variant Level 1])), N'') IS NULL THEN d.[Product] ELSE d.[Variant Level 1] END,
    V2_norm = CASE WHEN NULLIF(LTRIM(RTRIM(d.[Variant Level 2])), N'') IS NULL THEN d.[Product] ELSE d.[Variant Level 2] END,
    V3_norm = CASE WHEN NULLIF(LTRIM(RTRIM(d.[Variant Level 3])), N'') IS NULL THEN d.[Product] ELSE d.[Variant Level 3] END
  FROM Detail d
),
AppliedRules AS
(
  SELECT
    n.*,
    Product_Derived =
      CASE
        WHEN n.V1_norm = N'Warranty Booster'
          OR n.V2_norm = N'Warranty Booster'
          OR n.V3_norm = N'Warranty Booster'
          OR n.[Product] = N'Warranty Booster'
          THEN N'Warranty Booster'
        WHEN n.[Product] LIKE N'%Warranty%'
          OR n.V1_norm LIKE N'%Warranty%'
          OR n.V2_norm LIKE N'%Warranty%'
          OR n.V3_norm LIKE N'%Warranty%'
          THEN N'Warranty Non-Booster'
        ELSE n.[Product]
      END
  FROM Norm n
),
Finalized AS
(
  SELECT
    Insurer            = a.[Insurer],
    Agent              = a.[Agent],
    PrimaryAgentCode   = a.[Primary Agent Code],
    SubAgentCode       = a.[Sub Agent Code],
    ArrangementCode    = a.[Arrangement Code],
    CellCaptive        = a.[Cell Captive],

    AgentCity          = a.AgentCity,
    AgentProvince      = a.AgentProvince,
    AgentSalesBranch   = a.AgentSalesBranch,
    AgentConsultant    = a.AgentConsultant,

    Product            = a.[Product],
    V1_norm            = a.V1_norm,
    V2_norm            = a.V2_norm,
    V3_norm            = a.V3_norm,
    Product_Derived    = a.Product_Derived,

    V1_clean           = LTRIM(RTRIM(REPLACE(REPLACE(a.V1_norm, N' (H)', N''), N'(H)', N''))),

    ProductCode        = a.[Product Code],
    PolicyPremium      = a.[Policy premium],
    PolicyTerm         = a.[Policy Term],
    [Date]             = a.[Date],

    CellCaptiveCode =
      CASE a.[Cell Captive]
        WHEN N'Auto Pedigree' THEN N'APD'
        WHEN N'Kempston Group' THEN N'KMP'
        WHEN N'Master Cell' THEN N'MST'
        WHEN N'Meyers Group' THEN N'MEY'
        WHEN N'Motus Imports' THEN N'MOT'
        WHEN N'Motus OEM' THEN N'OEM'
        WHEN N'M-Sure Mobility' THEN N'ELSK'
        WHEN N'IEMAS' THEN N'IEM'
        WHEN N'CMH' THEN N'CMH'
        WHEN N'Maritime Motors' THEN N'MTM'
        WHEN N'Wesbank (WESB)' THEN N'WESB'
        WHEN N'Wesbank AMH POS (WAMP)' THEN N'WAMP'
        WHEN N'Wesbank AMH Telesales (WAMT)' THEN N'WAMT'
        WHEN N'Wesbank Auto Pedigree POS (WAPP)' THEN N'WAPP'
        WHEN N'Wesbank Auto Pedigree Telesales (WAPT)' THEN N'WAPT'
        WHEN N'Wesbank Imperial Auto Retail POS (WIAP)' THEN N'WIAP'
        WHEN N'Wesbank Imperial Auto Retail Telesales (WIAT)' THEN N'WIAT'
        WHEN N'Wesbank Kempston POS (WKPP)' THEN N'WKPP'
        WHEN N'Wesbank Kent POS (WKNP)' THEN N'WKNP'
        WHEN N'Wesbank Maritime Motors POS (WMTP)' THEN N'WMTP'
        WHEN N'Wesbank Meyers POS (WMYP)' THEN N'WMYP'
        WHEN N'Wesbank POS independent (WESP)' THEN N'WESP'
        WHEN N'MEYERS TELESALES (WESBANK)' THEN N'WMYT'
        WHEN N'KEMPSTON TELESALES (WESBANK)' THEN N'WKPT'
        WHEN N'KENT' THEN N'KNT'
        WHEN N'KENT TELESALES (WESBANK)' THEN N'WKNT'
        WHEN N'MARITIME TELESALES (WESBANK)' THEN N'WMTT'
        ELSE NULL
      END,
    CellCaptiveGroup =
      CASE a.[Cell Captive]
        WHEN N'Auto Pedigree' THEN N'AUTO PEDIGREE'
        WHEN N'Kempston Group' THEN N'KEMPSTON CONSOLIDATED'
        WHEN N'Master Cell' THEN N'MASTER CELL (INDEPENDENTS)'
        WHEN N'Meyers Group' THEN N'MEYERS CONSOLIDATED'
        WHEN N'Motus Imports' THEN N'MOT IMPORTERS'
        WHEN N'Motus OEM' THEN N'OEM'
        WHEN N'M-Sure Mobility' THEN N'MOBILITY FUND'
        WHEN N'IEMAS' THEN N'IEMAS'
        WHEN N'CMH' THEN N'CMH HOLDINGS'
        WHEN N'Maritime Motors' THEN N'MARITIME MOTORS CONSOLIDATED'
        WHEN N'Wesbank (WESB)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank AMH POS (WAMP)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank AMH Telesales (WAMT)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank Auto Pedigree POS (WAPP)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank Auto Pedigree Telesales (WAPT)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank Imperial Auto Retail POS (WIAP)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank Imperial Auto Retail Telesales (WIAT)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'Wesbank Kempston POS (WKPP)' THEN N'KEMPSTON CONSOLIDATED'
        WHEN N'Wesbank Kent POS (WKNP)' THEN N'KENT CONSOLIDATED'
        WHEN N'Wesbank Maritime Motors POS (WMTP)' THEN N'MARITIME MOTORS CONSOLIDATED'
        WHEN N'Wesbank Meyers POS (WMYP)' THEN N'MEYERS CONSOLIDATED'
        WHEN N'Wesbank POS independent (WESP)' THEN N'WESBANK CONSOLIDATED'
        WHEN N'MEYERS TELESALES (WESBANK)' THEN N'MEYERS CONSOLIDATED'
        WHEN N'KEMPSTON TELESALES (WESBANK)' THEN N'KEMPSTON CONSOLIDATED'
        WHEN N'KENT' THEN N'KENT CONSOLIDATED'
        WHEN N'KENT TELESALES (WESBANK)' THEN N'KENT CONSOLIDATED'
        WHEN N'MARITIME TELESALES (WESBANK)' THEN N'MARITIME MOTORS CONSOLIDATED'
        ELSE NULL
      END,
    ProductGroupCode =
      CASE LTRIM(RTRIM(REPLACE(REPLACE(a.V1_norm, N' (H)', N''), N'(H)', N'')))
        WHEN N'Adcover' THEN N'ADC'
        WHEN N'Annual Deposit Cover' THEN N'DEP'
        WHEN N'Auto Pedigree Step up - Wear and Tear' THEN N'WTY'
        WHEN N'Bumper to Bumper' THEN N'WTY'
        WHEN N'Bumper to Bumper Options' THEN N'WTY'
        WHEN N'Certified New Vehicle Warranty' THEN N'WTY'
        WHEN N'Combined Adcover and Deposit Cover' THEN N'ADC'
        WHEN N'Mobility Life Cover' THEN N'LPP'
        WHEN N'Dealer Protection Plan' THEN N'WTY'
        WHEN N'Imperial Logistics Warranty' THEN N'WTY'
        WHEN N'Mastercars' THEN N'WTY'
        WHEN N'Motorcycle Warranty' THEN N'WTY'
        WHEN N'Outdoor Warranty' THEN N'WTY'
        WHEN N'Paint Tech' THEN N'SCR'
        WHEN N'Platinum' THEN N'WTY'
        WHEN N'Step Up Warranty' THEN N'WTY'
        WHEN N'Taxi' THEN N'WTY'
        WHEN N'Truck Protection Plan' THEN N'WTY'
        WHEN N'Truck Warranty' THEN N'WTY'
        WHEN N'Tyre & Rim' THEN N'TYR'
        WHEN N'Tyre and Rim - The Unlimited' THEN N'TYR'
        WHEN N'Tyre and Rim Protect' THEN N'TYR'
        WHEN N'Vehicle Value Protector' THEN N'ADC'
        WHEN N'Warranty Booster' THEN N'WTY'
        ELSE NULL
      END,
    ProductGroupDescription =
      CASE LTRIM(RTRIM(REPLACE(REPLACE(a.V1_norm, N' (H)', N''), N'(H)', N'')))
        WHEN N'Adcover' THEN N'ADCOVER & DEPOSIT COVER'
        WHEN N'Annual Deposit Cover' THEN N'ADCOVER & DEPOSIT COVER'
        WHEN N'Auto Pedigree Step up - Wear and Tear' THEN N'WARRANTY'
        WHEN N'Bumper to Bumper' THEN N'WARRANTY'
        WHEN N'Bumper to Bumper Options' THEN N'WARRANTY'
        WHEN N'Certified New Vehicle Warranty' THEN N'WARRANTY'
        WHEN N'Combined Adcover and Deposit Cover' THEN N'ADCOVER & DEPOSIT COVER'
        WHEN N'Mobility Life Cover' THEN N'LIFE'
        WHEN N'Dealer Protection Plan' THEN N'WARRANTY'
        WHEN N'Imperial Logistics Warranty' THEN N'WARRANTY'
        WHEN N'Mastercars' THEN N'WARRANTY'
        WHEN N'Motorcycle Warranty' THEN N'WARRANTY'
        WHEN N'Outdoor Warranty' THEN N'WARRANTY'
        WHEN N'Paint Tech' THEN N'SCRATCH AND DENT'
        WHEN N'Platinum' THEN N'WARRANTY'
        WHEN N'Step Up Warranty' THEN N'WARRANTY'
        WHEN N'Taxi' THEN N'WARRANTY'
        WHEN N'Truck Protection Plan' THEN N'WARRANTY'
        WHEN N'Truck Warranty' THEN N'WARRANTY'
        WHEN N'Tyre & Rim' THEN N'TYRE AND RIM'
        WHEN N'Tyre and Rim - The Unlimited' THEN N'TYRE AND RIM'
        WHEN N'Tyre and Rim Protect' THEN N'TYRE AND RIM'
        WHEN N'Vehicle Value Protector' THEN N'ADCOVER & DEPOSIT COVER'
        WHEN N'Warranty Booster' THEN N'WARRANTY'
        ELSE NULL
      END
  FROM AppliedRules a
)
SELECT
    f.Insurer,
    f.Agent,
    f.PrimaryAgentCode          AS [Primary Agent Code],
    f.SubAgentCode              AS [Sub Agent Code],
    f.ArrangementCode           AS [Arrangement Code],
    f.CellCaptive               AS [Cell Captive],
    f.CellCaptiveCode           AS [Cell Captive Code],
    f.CellCaptiveGroup          AS [Cell Captive Group],
    f.ProductGroupCode          AS [Product Group Code],
    f.ProductGroupDescription   AS [Product Group Description],
    f.AgentCity                 AS [City],
    f.AgentProvince             AS [Province],
    f.AgentSalesBranch          AS [Sales branch],
    f.AgentConsultant           AS [Consultant],
    f.Product_Derived           AS [Product],
    f.V1_clean                  AS [Variant Level 1],
    f.V2_norm                   AS [Variant Level 2],
    f.V3_norm                   AS [Variant Level 3],
    f.ProductCode               AS [Product Code],
    SUM(f.PolicyPremium)        AS [Policy premium],
    f.PolicyTerm                AS [Policy Term],
    f.[Date],
    COUNT_BIG(*)                AS [Sales Count]
FROM Finalized f
WHERE f.Insurer IN (SELECT InsurerName FROM #Insurers)
and f.ProductGroupCode is not NULL
GROUP BY
    f.Insurer,
    f.Agent,
    f.PrimaryAgentCode,
    f.SubAgentCode,
    f.ArrangementCode,
    f.CellCaptive,
    f.CellCaptiveCode,
    f.CellCaptiveGroup,
    f.ProductGroupCode,
    f.ProductGroupDescription,
    f.AgentCity,
    f.AgentProvince,
    f.AgentSalesBranch,
    f.AgentConsultant,
    f.Product_Derived,
    f.V1_clean,
    f.V2_norm,
    f.V3_norm,
    f.ProductCode,
    f.PolicyTerm,
    f.[Date]
ORDER BY f.[Date], f.Insurer, f.Product_Derived, f.V1_clean;
