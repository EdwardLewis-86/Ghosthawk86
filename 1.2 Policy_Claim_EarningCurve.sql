/*--------------------------------------------------
Output return all policies with claims and earning curve
---------------------------------------------------*/

USE Evolve;
GO
SET NOCOUNT ON;

------------------------------
-- PARAMETERS
------------------------------
DECLARE @InsurerContains       NVARCHAR(200) = 'Hollard' --NULL;  -- e.g. N'Hollard' (NULL = all)
DECLARE @ProductLevel1Contains NVARCHAR(200) = NULL --NULL;  -- e.g. N'Bumper'  (NULL = all)
DECLARE @CurveNameFilter       NVARCHAR(200) = NULL;  -- exact curve name, NULL = all
DECLARE @MinCurveMonth         INT = 1;               -- 1..84
DECLARE @MaxCurveMonth         INT = 84;              -- 1..84

-- Guards
IF @MinCurveMonth < 1  SET @MinCurveMonth = 1;
IF @MaxCurveMonth > 84 SET @MaxCurveMonth = 84;
IF @MaxCurveMonth < @MinCurveMonth SET @MaxCurveMonth = @MinCurveMonth;

;WITH
/* One motor item per policy by recency (remove AND mp.rn = 1 to show all vehicles) */
MotorPick AS (
    SELECT
        m.*,
        ROW_NUMBER() OVER (
            PARTITION BY m.PMI_Policy_ID
            ORDER BY ISNULL(m.PMI_EndDate, '9999-12-31') DESC,
                     m.PMI_StartDate DESC,
                     m.PMI_CreateDate DESC
        ) AS rn
    FROM Evolve.dbo.PolicyMotorItem m
    WHERE m.PMI_Deleted = 0
),

/* ===========================
   Base: policy + item + joins
   Vehicle Make/Model ONLY from vw_API_GetPolicyItemDetails
   =========================== */
BaseItems AS (
    SELECT
        pol.POL_PolicyNumber                                   AS POL_PolicyNumber,
        isum.ITS_Item_ID                                       AS ITS_Item_ID,

        -- Vehicle from view (per your sample extract)
        vapi.Make                                              AS PMI_MakeOriginal,
        vapi.Model                                             AS Model,

        -- Section / Plan (from motor item)
        pvSection.PRV_FullName                                 AS PDS_SectionGrouping,
        pvPlan.PRV_FullName                                    AS PlanOption,

        isum.ITS_Premium                                       AS ITS_Premium,
        CONVERT(date, isum.ITS_StartDate)                      AS ITS_StartDate,
        CONVERT(date, isum.ITS_EndDate)                        AS ITS_EndDate,
        CONVERT(date, pol.POL_OriginalStartDate)               AS POL_OriginalStartDate,
        DATEADD(DAY, 1, CONVERT(date, pol.POL_EndDate))        AS POL_RenewalDate,

        prd.PRD_Name                                           AS PRD_Name,
        pv1.PRV_FullName                                       AS ProductLevel1,
        pv2.PRV_FullName                                       AS ProductLevel2,
        pv3.PRV_FullName                                       AS ProductLevel3,

        INS.INS_InsurerName                                    AS Insurer,
        RTF.RTF_Description                                    AS PolicyFrequency,

        pol.Policy_ID                                          AS Policy_ID,
        pol.POL_ProductVariantLevel3_ID                        AS ProductLevel3_ID,
        pol.POL_ProductTerm_ID                                 AS TermFrequency_ID,

        -- Registration date from view (mirrors your sample)
        vapi.RegistrationDate                                  AS RegistrationDate
    FROM Evolve.dbo.Policy              AS pol
    JOIN Evolve.dbo.ItemSummary         AS isum
      ON isum.ITS_Policy_ID = pol.Policy_ID
     AND isum.ITS_Deleted   = 0
     AND isum.ITS_Premium   > 0

    -- Product variants from policy
    LEFT JOIN Evolve.dbo.ProductVariant AS pv1
      ON pv1.ProductVariant_Id = pol.POL_ProductVariantLevel1_ID
    LEFT JOIN Evolve.dbo.ProductVariant AS pv2
      ON pv2.ProductVariant_Id = pol.POL_ProductVariantLevel2_ID
    LEFT JOIN Evolve.dbo.ProductVariant AS pv3
      ON pv3.ProductVariant_Id = pol.POL_ProductVariantLevel3_ID

    -- Product name
    LEFT JOIN Evolve.dbo.Product AS prd
      ON prd.Product_Id = pol.POL_Product_Id

    -- Insurer via PolicyInsurerLink → Insurer
    LEFT JOIN Evolve.dbo.PolicyInsurerLink AS PIL
      ON pol.Policy_ID = PIL.PIL_Policy_ID
    LEFT JOIN Evolve.dbo.Insurer AS INS
      ON INS.Insurer_ID = PIL.PIL_Insurer_ID

    -- Policy frequency
    LEFT JOIN Evolve.dbo.ReferenceTermFrequency AS RTF
      ON RTF.TermFrequency_Id = pol.POL_ProductTerm_ID

    -- Motor item back to policy
    LEFT JOIN MotorPick AS mp
      ON mp.PMI_Policy_ID = pol.Policy_ID
     AND mp.rn = 1  -- remove to output one row per vehicle

    -- Optional: plan / section names from motor item
    LEFT JOIN Evolve.dbo.ProductVariant AS pvPlan
      ON pvPlan.ProductVariant_Id = mp.PMI_Plan_ID
    LEFT JOIN Evolve.dbo.ProductVariant AS pvSection
      ON pvSection.ProductVariant_Id = mp.PMI_Section_ID

    -- >>> Vehicle Make/Model source per your sample extract <<<
    LEFT JOIN dbo.vw_API_GetPolicyItemDetails AS vapi WITH (NOLOCK)
      ON vapi.PolicyID = pol.Policy_ID

    -- Filters (NULL = all)
    WHERE
          (@InsurerContains       IS NULL OR INS.INS_InsurerName  LIKE N'%' + @InsurerContains + N'%')
      AND (@ProductLevel1Contains IS NULL OR pv1.PRV_FullName     LIKE N'%' + @ProductLevel1Contains + N'%')
),

/* Earning curve (pivot 1..84) */
CurveBase AS (
    SELECT
        b.Policy_ID,
        b.POL_PolicyNumber,
        dch.DCH_Name               AS EarningCurveName,
        dci.DCI_Month              AS CurveMonth,
        dci.DCI_MonthlyPercentage  AS CurvePct
    FROM BaseItems b
    JOIN Evolve.dbo.DisbursementCurveProduct AS dcp
      ON dcp.DCP_Product_Id = b.ProductLevel3_ID
     AND dcp.DCP_Deleted    = 0
    JOIN Evolve.dbo.DisbursementCurveHeader  AS dch
      ON dch.DisbursementCurveHeader_Id = dcp.DCP_DisbursementCurveHeader_Id
     AND dch.DCH_Deleted    = 0
     AND dch.DCH_Enabled    = 1
     AND dch.DCH_TermFrequency_Id = b.TermFrequency_ID
    JOIN Evolve.dbo.DisbursementCurveItem    AS dci
      ON dci.DCI_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
     AND dci.DCI_Deleted = 0
    WHERE (@CurveNameFilter IS NULL OR dch.DCH_Name = @CurveNameFilter)
),
CurvePivot AS (
    SELECT *
    FROM (
        SELECT Policy_ID, CurveMonth, CurvePct
        FROM CurveBase
    ) s
    PIVOT (MAX(CurvePct) FOR CurveMonth IN (
        [1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],
        [13],[14],[15],[16],[17],[18],[19],[20],[21],[22],[23],[24],
        [25],[26],[27],[28],[29],[30],[31],[32],[33],[34],[35],[36],
        [37],[38],[39],[40],[41],[42],[43],[44],[45],[46],[47],[48],
        [49],[50],[51],[52],[53],[54],[55],[56],[57],[58],[59],[60],
        [61],[62],[63],[64],[65],[66],[67],[68],[69],[70],[71],[72],
        [73],[74],[75],[76],[77],[78],[79],[80],[81],[82],[83],[84]
    )) p
),

/* Claims aggregates */
TxnAgg AS (
    SELECT
        cis.CIS_Claim_ID                        AS ClaimID,
        COUNT(*)                                AS PaymentCount,
        MIN(CIT.CIT_CreateDate)                 AS PaidDate
    FROM Evolve.dbo.ClaimItemTransaction AS CIT
    JOIN Evolve.dbo.ClaimItemSummary     AS cis
      ON cis.CIS_ClaimItem_ID = CIT.CIT_ClaimItem_ID
    JOIN Evolve.dbo.PaymentRequisition   AS prq
      ON prq.PaymentRequisition_Id = CIT.CIT_Payment_ID
    WHERE prq.PRQ_Status = 5  -- Paid
    GROUP BY cis.CIS_Claim_ID
),
PayRecAgg AS (
    SELECT
        cis.CIS_Claim_ID                        AS ClaimID,
        SUM(CASE WHEN CIT_TransactionType_ID = 2 THEN CIT_Amount ELSE 0 END) AS Payments,
        SUM(CASE WHEN CIT_TransactionType_ID = 3 THEN CIT_Amount ELSE 0 END) AS Recoveries
    FROM Evolve.dbo.ClaimItemTransaction AS CIT
    JOIN Evolve.dbo.ClaimItemSummary     AS cis
      ON cis.CIS_ClaimItem_ID = CIT.CIT_ClaimItem_ID
    GROUP BY cis.CIS_Claim_ID
),
TotalsAgg AS (
    SELECT
        cis.CIS_Claim_ID                        AS ClaimID,
        SUM(CASE WHEN cis.CIS_ClaimType_ID IN (1) THEN cis.CIS_Estimate            ELSE 0 END) AS TotalEstimate,
        SUM(CASE WHEN cis.CIS_ClaimType_ID IN (1) THEN cis.CIS_OutstandingEstimate ELSE 0 END) AS TotalOutstanding
    FROM Evolve.dbo.ClaimItemSummary AS cis
    GROUP BY cis.CIS_Claim_ID
)

---------------------------------
-- FINAL OUTPUT (order requested)
---------------------------------
SELECT
    b.POL_PolicyNumber		AS [POLICY NUMBER],
    b.Insurer				AS [INSURER],
    b.PMI_MakeOriginal		AS [VEHICLE MAKE],            -- from vw_API_GetPolicyItemDetails.Make
    b.Model					AS [VEHICLE MODEL],           -- from vw_API_GetPolicyItemDetails.Model
    b.RegistrationDate		AS [REGISTRATION DATE],
    b.ITS_Premium			AS [PREMIUM],
    b.ITS_StartDate			AS [START DATE],
    b.ITS_EndDate			AS [END DATE],
    b.POL_OriginalStartDate	AS [ORIGINAL START DATE],
    b.POL_RenewalDate		AS [RENEWAL DATE],
    b.PRD_Name				AS [PRODUCT NAME],
    b.ProductLevel1			AS [VARIANT LEVEL 1],
    b.ProductLevel2			AS [VARIANT LEVEL 2],
    b.ProductLevel3			AS [VARIANT LEVEL 3],



    -- Claims at item-level (comment out if you want policy-only)
    clm.CLM_ClaimNumber		AS [CLAIM NUMBER],
    cls.CLS_Description		AS [CLAIM STATUS],
    cis.CIS_LossDate		AS [LOSS DATE],
    tx.PaidDate				AS [PAID DATE],
    cis.CIS_ClaimItemDescription AS [CLAIM DESCRIPTION],

    CAST(ISNULL(pay.Recoveries,0) + ISNULL(pay.Payments,0) AS DECIMAL(18,2)) AS [CLAIMED AMOUNT],
    CAST(ISNULL(pay.Payments,0)                              AS DECIMAL(18,2)) AS [PAID AMOUNT],

    b.PolicyFrequency      AS [POLICY FREQUENCY],

    -- Earning curve horizontally (clipped to requested range)
    CASE WHEN @MinCurveMonth<=1  AND 1  <=@MaxCurveMonth THEN p.[1]  END AS M01,
    CASE WHEN @MinCurveMonth<=2  AND 2  <=@MaxCurveMonth THEN p.[2]  END AS M02,
    CASE WHEN @MinCurveMonth<=3  AND 3  <=@MaxCurveMonth THEN p.[3]  END AS M03,
    CASE WHEN @MinCurveMonth<=4  AND 4  <=@MaxCurveMonth THEN p.[4]  END AS M04,
    CASE WHEN @MinCurveMonth<=5  AND 5  <=@MaxCurveMonth THEN p.[5]  END AS M05,
    CASE WHEN @MinCurveMonth<=6  AND 6  <=@MaxCurveMonth THEN p.[6]  END AS M06,
    CASE WHEN @MinCurveMonth<=7  AND 7  <=@MaxCurveMonth THEN p.[7]  END AS M07,
    CASE WHEN @MinCurveMonth<=8  AND 8  <=@MaxCurveMonth THEN p.[8]  END AS M08,
    CASE WHEN @MinCurveMonth<=9  AND 9  <=@MaxCurveMonth THEN p.[9]  END AS M09,
    CASE WHEN @MinCurveMonth<=10 AND 10 <=@MaxCurveMonth THEN p.[10] END AS M10,
    CASE WHEN @MinCurveMonth<=11 AND 11 <=@MaxCurveMonth THEN p.[11] END AS M11,
    CASE WHEN @MinCurveMonth<=12 AND 12 <=@MaxCurveMonth THEN p.[12] END AS M12,
    CASE WHEN @MinCurveMonth<=13 AND 13 <=@MaxCurveMonth THEN p.[13] END AS M13,
    CASE WHEN @MinCurveMonth<=14 AND 14 <=@MaxCurveMonth THEN p.[14] END AS M14,
    CASE WHEN @MinCurveMonth<=15 AND 15 <=@MaxCurveMonth THEN p.[15] END AS M15,
    CASE WHEN @MinCurveMonth<=16 AND 16 <=@MaxCurveMonth THEN p.[16] END AS M16,
    CASE WHEN @MinCurveMonth<=17 AND 17 <=@MaxCurveMonth THEN p.[17] END AS M17,
    CASE WHEN @MinCurveMonth<=18 AND 18 <=@MaxCurveMonth THEN p.[18] END AS M18,
    CASE WHEN @MinCurveMonth<=19 AND 19 <=@MaxCurveMonth THEN p.[19] END AS M19,
    CASE WHEN @MinCurveMonth<=20 AND 20 <=@MaxCurveMonth THEN p.[20] END AS M20,
    CASE WHEN @MinCurveMonth<=21 AND 21 <=@MaxCurveMonth THEN p.[21] END AS M21,
    CASE WHEN @MinCurveMonth<=22 AND 22 <=@MaxCurveMonth THEN p.[22] END AS M22,
    CASE WHEN @MinCurveMonth<=23 AND 23 <=@MaxCurveMonth THEN p.[23] END AS M23,
    CASE WHEN @MinCurveMonth<=24 AND 24 <=@MaxCurveMonth THEN p.[24] END AS M24,
    CASE WHEN @MinCurveMonth<=25 AND 25 <=@MaxCurveMonth THEN p.[25] END AS M25,
    CASE WHEN @MinCurveMonth<=26 AND 26 <=@MaxCurveMonth THEN p.[26] END AS M26,
    CASE WHEN @MinCurveMonth<=27 AND 27 <=@MaxCurveMonth THEN p.[27] END AS M27,
    CASE WHEN @MinCurveMonth<=28 AND 28 <=@MaxCurveMonth THEN p.[28] END AS M28,
    CASE WHEN @MinCurveMonth<=29 AND 29 <=@MaxCurveMonth THEN p.[29] END AS M29,
    CASE WHEN @MinCurveMonth<=30 AND 30 <=@MaxCurveMonth THEN p.[30] END AS M30,
    CASE WHEN @MinCurveMonth<=31 AND 31 <=@MaxCurveMonth THEN p.[31] END AS M31,
    CASE WHEN @MinCurveMonth<=32 AND 32 <=@MaxCurveMonth THEN p.[32] END AS M32,
    CASE WHEN @MinCurveMonth<=33 AND 33 <=@MaxCurveMonth THEN p.[33] END AS M33,
    CASE WHEN @MinCurveMonth<=34 AND 34 <=@MaxCurveMonth THEN p.[34] END AS M34,
    CASE WHEN @MinCurveMonth<=35 AND 35 <=@MaxCurveMonth THEN p.[35] END AS M35,
    CASE WHEN @MinCurveMonth<=36 AND 36 <=@MaxCurveMonth THEN p.[36] END AS M36,
    CASE WHEN @MinCurveMonth<=37 AND 37 <=@MaxCurveMonth THEN p.[37] END AS M37,
    CASE WHEN @MinCurveMonth<=38 AND 38 <=@MaxCurveMonth THEN p.[38] END AS M38,
    CASE WHEN @MinCurveMonth<=39 AND 39 <=@MaxCurveMonth THEN p.[39] END AS M39,
    CASE WHEN @MinCurveMonth<=40 AND 40 <=@MaxCurveMonth THEN p.[40] END AS M40,
    CASE WHEN @MinCurveMonth<=41 AND 41 <=@MaxCurveMonth THEN p.[41] END AS M41,
    CASE WHEN @MinCurveMonth<=42 AND 42 <=@MaxCurveMonth THEN p.[42] END AS M42,
    CASE WHEN @MinCurveMonth<=43 AND 43 <=@MaxCurveMonth THEN p.[43] END AS M43,
    CASE WHEN @MinCurveMonth<=44 AND 44 <=@MaxCurveMonth THEN p.[44] END AS M44,
    CASE WHEN @MinCurveMonth<=45 AND 45 <=@MaxCurveMonth THEN p.[45] END AS M45,
    CASE WHEN @MinCurveMonth<=46 AND 46 <=@MaxCurveMonth THEN p.[46] END AS M46,
    CASE WHEN @MinCurveMonth<=47 AND 47 <=@MaxCurveMonth THEN p.[47] END AS M47,
    CASE WHEN @MinCurveMonth<=48 AND 48 <=@MaxCurveMonth THEN p.[48] END AS M48,
    CASE WHEN @MinCurveMonth<=49 AND 49 <=@MaxCurveMonth THEN p.[49] END AS M49,
    CASE WHEN @MinCurveMonth<=50 AND 50 <=@MaxCurveMonth THEN p.[50] END AS M50,
    CASE WHEN @MinCurveMonth<=51 AND 51 <=@MaxCurveMonth THEN p.[51] END AS M51,
    CASE WHEN @MinCurveMonth<=52 AND 52 <=@MaxCurveMonth THEN p.[52] END AS M52,
    CASE WHEN @MinCurveMonth<=53 AND 53 <=@MaxCurveMonth THEN p.[53] END AS M53,
    CASE WHEN @MinCurveMonth<=54 AND 54 <=@MaxCurveMonth THEN p.[54] END AS M54,
    CASE WHEN @MinCurveMonth<=55 AND 55 <=@MaxCurveMonth THEN p.[55] END AS M55,
    CASE WHEN @MinCurveMonth<=56 AND 56 <=@MaxCurveMonth THEN p.[56] END AS M56,
    CASE WHEN @MinCurveMonth<=57 AND 57 <=@MaxCurveMonth THEN p.[57] END AS M57,
    CASE WHEN @MinCurveMonth<=58 AND 58 <=@MaxCurveMonth THEN p.[58] END AS M58,
    CASE WHEN @MinCurveMonth<=59 AND 59 <=@MaxCurveMonth THEN p.[59] END AS M59,
    CASE WHEN @MinCurveMonth<=60 AND 60 <=@MaxCurveMonth THEN p.[60] END AS M60,
    CASE WHEN @MinCurveMonth<=61 AND 61 <=@MaxCurveMonth THEN p.[61] END AS M61,
    CASE WHEN @MinCurveMonth<=62 AND 62 <=@MaxCurveMonth THEN p.[62] END AS M62,
    CASE WHEN @MinCurveMonth<=63 AND 63 <=@MaxCurveMonth THEN p.[63] END AS M63,
    CASE WHEN @MinCurveMonth<=64 AND 64 <=@MaxCurveMonth THEN p.[64] END AS M64,
    CASE WHEN @MinCurveMonth<=65 AND 65 <=@MaxCurveMonth THEN p.[65] END AS M65,
    CASE WHEN @MinCurveMonth<=66 AND 66 <=@MaxCurveMonth THEN p.[66] END AS M66,
    CASE WHEN @MinCurveMonth<=67 AND 67 <=@MaxCurveMonth THEN p.[67] END AS M67,
    CASE WHEN @MinCurveMonth<=68 AND 68 <=@MaxCurveMonth THEN p.[68] END AS M68,
    CASE WHEN @MinCurveMonth<=69 AND 69 <=@MaxCurveMonth THEN p.[69] END AS M69,
    CASE WHEN @MinCurveMonth<=70 AND 70 <=@MaxCurveMonth THEN p.[70] END AS M70,
    CASE WHEN @MinCurveMonth<=71 AND 71 <=@MaxCurveMonth THEN p.[71] END AS M71,
    CASE WHEN @MinCurveMonth<=72 AND 72 <=@MaxCurveMonth THEN p.[72] END AS M72,
    CASE WHEN @MinCurveMonth<=73 AND 73 <=@MaxCurveMonth THEN p.[73] END AS M73,
    CASE WHEN @MinCurveMonth<=74 AND 74 <=@MaxCurveMonth THEN p.[74] END AS M74,
    CASE WHEN @MinCurveMonth<=75 AND 75 <=@MaxCurveMonth THEN p.[75] END AS M75,
    CASE WHEN @MinCurveMonth<=76 AND 76 <=@MaxCurveMonth THEN p.[76] END AS M76,
    CASE WHEN @MinCurveMonth<=77 AND 77 <=@MaxCurveMonth THEN p.[77] END AS M77,
    CASE WHEN @MinCurveMonth<=78 AND 78 <=@MaxCurveMonth THEN p.[78] END AS M78,
    CASE WHEN @MinCurveMonth<=79 AND 79 <=@MaxCurveMonth THEN p.[79] END AS M79,
    CASE WHEN @MinCurveMonth<=80 AND 80 <=@MaxCurveMonth THEN p.[80] END AS M80,
    CASE WHEN @MinCurveMonth<=81 AND 81 <=@MaxCurveMonth THEN p.[81] END AS M81,
    CASE WHEN @MinCurveMonth<=82 AND 82 <=@MaxCurveMonth THEN p.[82] END AS M82,
    CASE WHEN @MinCurveMonth<=83 AND 83 <=@MaxCurveMonth THEN p.[83] END AS M83,
    CASE WHEN @MinCurveMonth<=84 AND 84 <=@MaxCurveMonth THEN p.[84] END AS M84

FROM BaseItems b
LEFT JOIN CurvePivot p
  ON p.Policy_ID = b.Policy_ID
LEFT JOIN Evolve.dbo.Claim              AS clm
  ON clm.CLM_Policy_ID = b.Policy_ID
LEFT JOIN Evolve.dbo.ClaimItemSummary   AS cis
  ON cis.CIS_Claim_ID = clm.Claim_ID
LEFT JOIN Evolve.dbo.ReferenceClaimStatus AS cls
  ON cls.ClaimStatus_ID = clm.CLM_Status
LEFT JOIN TxnAgg  AS tx  ON tx.ClaimID = clm.Claim_ID
LEFT JOIN PayRecAgg AS pay ON pay.ClaimID = clm.Claim_ID
LEFT JOIN TotalsAgg AS tot ON tot.ClaimID = clm.Claim_ID
ORDER BY b.POL_PolicyNumber, cis.CIS_LossDate, clm.CLM_ClaimNumber;
