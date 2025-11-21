USE [Evolve];
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--------------------------------------------------------------------------------
-- Optional filters
--------------------------------------------------------------------------------
DECLARE @InsurerContains NVARCHAR(200) = NULL;  -- e.g. 'Centriq' (NULL = all)
DECLARE @MinLossDate     DATE          = NULL;  -- e.g. '2024-01-01'
DECLARE @MaxLossDate     DATE          = NULL;  -- e.g. '2024-12-31'

;WITH
--------------------------------------------------------------------------------
-- Per-ITEM payments (only PAID is needed for Revised Estimate)
--------------------------------------------------------------------------------
ItemTxn AS (
    SELECT
        cit.CIT_ClaimItem_ID AS ClaimItemID,
        SUM(CASE WHEN cit.CIT_TransactionType_ID = 2 THEN cit.CIT_Amount ELSE 0 END) AS ItemPaid
    FROM Evolve.dbo.ClaimItemTransaction AS cit
    GROUP BY cit.CIT_ClaimItem_ID
)

--------------------------------------------------------------------------------
-- FINAL: one row per Claim Item (no roll-up)
--------------------------------------------------------------------------------
SELECT
    pol.POL_PolicyNumber                                      AS [POLICY NUMBER],
    ins_pick.INS_InsurerName                                   AS [INSURER],

    -- Segment by Loss Date vs Renewal
    CASE WHEN CONVERT(date, cis.CIS_LossDate) >= DATEADD(DAY, 1, CONVERT(date, pol.POL_EndDate))
         THEN N'Post-Renewal' ELSE N'Pre-Renewal' END         AS [PERIOD SEGMENT],

    CONVERT(date, pol.POL_OriginalStartDate)                  AS [ORIGINAL START DATE],
    DATEADD(DAY, 1, CONVERT(date, pol.POL_EndDate))           AS [RENEWAL DATE],

    -- Item window (uniquely matched to the loss date)
    CONVERT(date, isum.ITS_StartDate)                         AS [ITEM START DATE],
    CONVERT(date, isum.ITS_EndDate)                           AS [ITEM END DATE],
    isum.ITS_Premium                                          AS [PREMIUM],

    -- Product code (policy-scoped; prefer L3 if present, else master)
    COALESCE(pv3.PRV_Code, prd.PRD_Code)                      AS [PRODUCT CODE],

    -- PRODUCT CATEGORY (Variant L1 → L2 → L3 → Product Name)
    COALESCE(pv1.PRV_FullName, pv2.PRV_FullName, pv3.PRV_FullName, prd.PRD_Name)
                                                              AS [PRODUCT CATEGORY],

    -- PRODUCT PLAN (prefer item plan name; fall back to motor plan active on loss date; then policy variants)
    COALESCE(NULLIF(LTRIM(RTRIM(cis.CIS_PlanName)), N''),
             pvPlan.PRV_FullName, pv3.PRV_FullName, pv2.PRV_FullName, pv1.PRV_FullName)
                                                              AS [PRODUCT PLAN],

    -- Vehicle details (picked from the item covering the loss date)
    vapi.Make                                                 AS [VEHICLE MAKE],
    vapi.Model                                                AS [VEHICLE MODEL],
    vapi.RegistrationDate                                     AS [REGISTRATION DATE],

    -- Claim header
    clm.CLM_ClaimNumber                                       AS [CLAIM NUMBER],
    cls.CLS_Description                                        AS [CLAIM STATUS],

    -- CLAIM REASON: primary free-text component on the item (e.g., Engine; Turbo/Kompressor)
    comp_pick.Component_Description                            AS [CLAIM REASON],

    CONVERT(date, cis.CIS_LossDate)                           AS [LOSS DATE],

    -- Per-ITEM amounts (no roll-up)
    CAST(ISNULL(cis.CIS_Estimate,            0.00) AS DECIMAL(18,2)) AS [ORIGINAL ESTIMATE],
    CAST(ISNULL(cis.CIS_OutstandingEstimate, 0.00)
        + ISNULL(it.ItemPaid,                0.00) AS DECIMAL(18,2)) AS [REVISED ESTIMATE],
    CAST(ISNULL(it.ItemPaid,                 0.00) AS DECIMAL(18,2)) AS [PAID AMOUNT]

FROM Evolve.dbo.Claim               AS clm
JOIN Evolve.dbo.Policy              AS pol  ON pol.Policy_ID          = clm.CLM_Policy_ID
LEFT JOIN Evolve.dbo.ReferenceClaimStatus AS cls ON cls.ClaimStatus_ID = clm.CLM_Status

-- All claim ITEMS (no roll-up)
JOIN Evolve.dbo.ClaimItemSummary    AS cis  ON cis.CIS_Claim_ID       = clm.Claim_ID
                                           AND (@MinLossDate IS NULL OR cis.CIS_LossDate >= @MinLossDate)
                                           AND (@MaxLossDate IS NULL OR cis.CIS_LossDate < DATEADD(DAY, 1, @MaxLossDate))

-- Pick the single policy ItemSummary row that covers the Loss Date
CROSS APPLY (
    SELECT TOP (1) s.*
    FROM Evolve.dbo.ItemSummary AS s
    WHERE s.ITS_Policy_ID = pol.Policy_ID
      AND s.ITS_Deleted   = 0
      AND (s.ITS_StartDate IS NULL OR cis.CIS_LossDate >= s.ITS_StartDate)
      AND (s.ITS_EndDate   IS NULL OR cis.CIS_LossDate < DATEADD(DAY, 1, s.ITS_EndDate))
    ORDER BY ISNULL(s.ITS_EndDate, '9999-12-31') DESC, s.ITS_StartDate DESC, s.ITS_CreateDate DESC
) AS isum

-- Pick the single Motor Item covering the Loss Date (for plan fallback)
OUTER APPLY (
    SELECT TOP (1) m.*
    FROM Evolve.dbo.PolicyMotorItem AS m
    WHERE m.PMI_Policy_ID = pol.Policy_ID
      AND m.PMI_Deleted   = 0
      AND (cis.CIS_LossDate >= m.PMI_StartDate)
      AND (cis.CIS_LossDate <  DATEADD(DAY, 1, ISNULL(m.PMI_EndDate, '9999-12-31')))
    ORDER BY ISNULL(m.PMI_EndDate, '9999-12-31') DESC, m.PMI_StartDate DESC, m.PMI_CreateDate DESC
) AS mp

-- Choose a single (lead) insurer to avoid duplication
OUTER APPLY (
    SELECT TOP (1) i.INS_InsurerName
    FROM Evolve.dbo.PolicyInsurerLink AS pil
    JOIN Evolve.dbo.Insurer           AS i   ON i.Insurer_ID = pil.PIL_Insurer_ID
    WHERE pil.PIL_Policy_ID = pol.Policy_ID
    ORDER BY pil.PIL_Lead_Indicator DESC, pil.PIL_UpdateDate DESC, pil.PIL_CreateDate DESC
) AS ins_pick

-- Product & Variants (policy level)
LEFT JOIN Evolve.dbo.Product         AS prd  ON prd.Product_Id               = pol.POL_Product_ID
LEFT JOIN Evolve.dbo.ProductVariant  AS pv1  ON pv1.ProductVariant_Id        = pol.POL_ProductVariantLevel1_ID
LEFT JOIN Evolve.dbo.ProductVariant  AS pv2  ON pv2.ProductVariant_Id        = pol.POL_ProductVariantLevel2_ID
LEFT JOIN Evolve.dbo.ProductVariant  AS pv3  ON pv3.ProductVariant_Id        = pol.POL_ProductVariantLevel3_ID

-- Motor plan fallback
LEFT JOIN Evolve.dbo.ProductVariant  AS pvPlan ON pvPlan.ProductVariant_Id   = mp.PMI_Plan_ID

-- Per-item payments
LEFT JOIN ItemTxn AS it ON it.ClaimItemID = cis.CIS_ClaimItem_ID

-- VEHICLE DETAILS: pick the record covering the loss date (and matching the chosen item when possible)
OUTER APPLY (
    SELECT TOP (1) d.*
    FROM dbo.vw_API_GetPolicyItemDetails AS d WITH (NOLOCK)
    WHERE d.PolicyID = pol.Policy_ID
      AND (d.ItemID = isum.ITS_Item_ID OR d.ItemID IS NULL)
      AND (cis.CIS_LossDate >= ISNULL(d.StartDate, '19000101'))
      AND (cis.CIS_LossDate <  DATEADD(DAY, 1, ISNULL(d.EndDate, '99991231')))
    ORDER BY ISNULL(d.EndDate,'9999-12-31') DESC, d.StartDate DESC
) AS vapi

-- Primary component (risk/reason) per item, chosen without multiplying rows
OUTER APPLY (
    SELECT TOP (1)
        COALESCE(NULLIF(LTRIM(RTRIM(cic.CIC_Description)), N''),
                 NULLIF(LTRIM(RTRIM(cic.CIC_AdditionalDescription)), N'')) AS Component_Description
    FROM Evolve.dbo.ClaimItemComponents AS cic
    WHERE cic.CIC_ClaimItem_ID = cis.CIS_ClaimItem_ID
    ORDER BY 
        (ISNULL(cic.CIC_ActualAmount, 0)
         + ISNULL(cic.CIC_PartsAmount, 0)
         + ISNULL(cic.CIC_LabourAmount, 0)
         + ISNULL(cic.CIC_OtherAmount, 0)) DESC,
        cic.CIC_CreateDate ASC
) AS comp_pick

WHERE (@InsurerContains IS NULL OR ins_pick.INS_InsurerName LIKE N'%' + @InsurerContains + N'%')

ORDER BY
    pol.POL_PolicyNumber,
    [PERIOD SEGMENT] DESC,
    clm.CLM_ClaimNumber,
    cis.CIS_ClaimItem_ID;
