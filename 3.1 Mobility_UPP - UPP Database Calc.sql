/* ========== Mobility UPP smoothing with strict product ceiling  ========== */
USE [UPP];
GO
SET NOCOUNT ON;

/* -------- Valuation month and tunables -------- */
DECLARE @ValuationMonth       date         = '2025-10-01';

-- Curve and prudence
DECLARE @k                    decimal(6,3) = 0.50;  -- lower k earns faster -> lower UPP
DECLARE @FwdLossRatio         decimal(6,3) = 0.25;  -- forward LR on remaining exposure
DECLARE @SafetyMargin         decimal(6,3) = 1.03;  -- prudence multiplier on the floor
DECLARE @RiskPremiumFactor    decimal(6,3) = 0.85;  -- apply only inside the floor

-- Movement controls
DECLARE @MoMCapPct            decimal(6,3) = 0.40;  -- allow up to 40% MoM drop
DECLARE @ReliefMonths         int          = 24;    -- provision release horizon in months

-- Strict ceiling to force RecommendedUPP below product UPP
DECLARE @MaxPctOfProductUPP   decimal(6,3) = 0.75;  -- hard ceiling at 75% of today’s product UPP

/* -------- Reference: agent and arrangement context (optional for audit columns) -------- */
WITH AgentArrangement AS (
    SELECT
        agt.Agent_Id,
        agt.Agt_Name,
        agt.Agt_AgentNumber,
        arr.ARG_ArrangementNumber,
        arr.ARG_Name,
        ROW_NUMBER() OVER (PARTITION BY agt.Agent_Id ORDER BY arr.ARG_Name) AS rn
    FROM Evolve.dbo.Agent agt
    LEFT JOIN Evolve.dbo.ArrangementAgents arga
        ON agt.Agent_Id = arga.ARA_Agent_ID AND arga.ARA_Deleted = 0
    LEFT JOIN Evolve.dbo.Arrangement arr
        ON arga.ARA_Arrangement_ID = arr.Arrangement_Id AND arr.ARG_Deleted = 0
),

/* -------- Base: current month Mobility policies with product UPP and premium base -------- */
Base AS (
    SELECT
        u.POL_PolicyNumber                                                AS [POL_PolicyNumber],
        COALESCE(agt.Agt_Name, u.Agt_Name)                                AS [Agent Name],
        agt.Agt_AgentNumber                                               AS [Agent Number],
        agt.ARG_ArrangementNumber                                         AS [Arrangement Number],
        agt.ARG_Name                                                      AS [Arrangement Name],
        u.ProductClass                                                    AS [ProductClass],
        u.POL_OriginalStartDate                                           AS [POL_OriginalStartDate],
        u.ElapsedMonths                                                   AS [ElapsedMonths],
        u.Product_Level1                                                  AS [Product_Level1],
        u.Product_Level2                                                  AS [Product_Level2],
        u.Product_Level3                                                  AS [Product_Level3],
        u.CellCaptive                                                     AS [CellCaptive],
        u.INS_InsurerName                                                 AS [INS_InsurerName],
        u.Term                                                            AS [Term],
        u.EarnedPortion                                                   AS [EarnedPortion],
        u.UnearnedPortion                                                 AS [UnearnedPortion],
        u.UPP                                                             AS [UPP],          -- product-curve UPP (initial UPP)
        /* Premium base priority. If UnearnedPortion exists, back out base as UPP / UnearnedPortion */
        CASE
            WHEN u.WW_Nett_Premium     IS NOT NULL AND u.WW_Nett_Premium     <> 0 THEN CAST(u.WW_Nett_Premium     AS decimal(38,10))
            WHEN u.Evolve_Nett_Premium IS NOT NULL AND u.Evolve_Nett_Premium <> 0 THEN CAST(u.Evolve_Nett_Premium AS decimal(38,10))
            WHEN u.UnearnedPortion     IS NOT NULL AND u.UnearnedPortion     >  0 THEN CAST(u.UPP AS decimal(38,10)) / NULLIF(CAST(u.UnearnedPortion AS decimal(38,10)),0)
            ELSE NULL
        END                                                               AS [Premium_Base],
        CASE
            WHEN u.WW_Nett_Premium     IS NOT NULL AND u.WW_Nett_Premium     <> 0 THEN 'WW_Nett_Premium'
            WHEN u.Evolve_Nett_Premium IS NOT NULL AND u.Evolve_Nett_Premium <> 0 THEN 'Evolve_Nett_Premium'
            WHEN u.UnearnedPortion     IS NOT NULL AND u.UnearnedPortion     >  0 THEN 'UPP / UnearnedPortion'
            ELSE 'Unknown'
        END                                                               AS [Premium_Source],
        /* Even straight-line UPP for reference only */
        CASE
            WHEN u.Term IS NULL OR u.Term <= 0 OR u.ElapsedMonths IS NULL THEN NULL
            ELSE
                (
                    CASE
                        WHEN u.WW_Nett_Premium     IS NOT NULL AND u.WW_Nett_Premium     <> 0 THEN CAST(u.WW_Nett_Premium     AS decimal(38,10))
                        WHEN u.Evolve_Nett_Premium IS NOT NULL AND u.Evolve_Nett_Premium <> 0 THEN CAST(u.Evolve_Nett_Premium AS decimal(38,10))
                        WHEN u.UnearnedPortion     IS NOT NULL AND u.UnearnedPortion     >  0 THEN CAST(u.UPP AS decimal(38,10)) / NULLIF(CAST(u.UnearnedPortion AS decimal(38,10)),0)
                        ELSE NULL
                    END
                ) *
                CASE
                    WHEN u.ElapsedMonths <= 0 THEN CAST(1.0 AS decimal(18,10))
                    WHEN u.ElapsedMonths >= u.Term THEN CAST(0.0 AS decimal(18,10))
                    ELSE CAST(1.0 - (CAST(u.ElapsedMonths AS decimal(18,10)) / NULLIF(CAST(u.Term AS decimal(18,10)),0)) AS decimal(18,10))
                END
        END                                                               AS [EvenCurveUPP],
        u.ValuationMonth
    FROM UPP.dbo.SAW_UPP_202510 AS u  ----------- UPDATE
    LEFT JOIN Evolve.dbo.Policy p
        ON u.POL_PolicyNumber = p.POL_PolicyNumber
    LEFT JOIN AgentArrangement agt
        ON p.POL_Agent_ID = agt.Agent_Id AND agt.rn = 1
    WHERE
        u.ValuationMonth = @ValuationMonth
        AND u.CellCaptive = 'M-Sure Mobility'
),

/* -------- Previous month UPP to apply MoM drop cap -------- */
Prev AS (
    SELECT POL_PolicyNumber, UPP AS PrevUPP
    FROM UPP.dbo.SAW_UPP_202508
    WHERE ValuationMonth = DATEADD(MONTH, -1, @ValuationMonth)
)

/* -------- Final select with layered APPLY to keep aliases valid -------- */
SELECT
    b.POL_PolicyNumber,
    [Agent Name] = b.[Agent Name],
    [Agent Number] = b.[Agent Number],
    [Arrangement Number] = b.[Arrangement Number],
    [Arrangement Name] = b.[Arrangement Name],
    b.ProductClass,
    b.POL_OriginalStartDate,
    b.ElapsedMonths,
    b.Product_Level1, b.Product_Level2, b.Product_Level3,
    b.CellCaptive, b.INS_InsurerName,
    b.Term,
    b.EarnedPortion, b.UnearnedPortion,
    b.Premium_Base, b.Premium_Source,
    b.UPP AS ProductCurveUPP,
    b.EvenCurveUPP,
    s.RemainingShare,
    f.SmoothedUPP_Raw,
    f.UPP_FwdClaimsFloor,
    fcap.UPP_FwdClaimsFloor_Strict,   -- floor capped to % of product UPP
    c1.SmoothedUPP_PreCap,
    cCap.SmoothedUPP        AS RecommendedUPP,   -- always < product UPP due to strict ceiling
    prov.DealerReliefProvision,
    c2.DealerReliefMonthlyRelease,
    b.ValuationMonth
FROM Base b
LEFT JOIN Prev p
  ON p.POL_PolicyNumber = b.POL_PolicyNumber

/* Remaining unearned share of term */
CROSS APPLY (
    SELECT
      CASE
        WHEN b.Term IS NULL OR b.Term <= 0 OR b.ElapsedMonths IS NULL THEN NULL
        WHEN b.ElapsedMonths <= 0 THEN CAST(1.0 AS decimal(18,10))
        WHEN b.ElapsedMonths >= b.Term THEN CAST(0.0 AS decimal(18,10))
        ELSE CAST(1.0 - (CAST(b.ElapsedMonths AS decimal(18,10)) / NULLIF(CAST(b.Term AS decimal(18,10)),0)) AS decimal(18,10))
      END AS RemainingShare
) s

/* Raw power-curve result and prudence floor using net risk premium factor */
CROSS APPLY (
    SELECT
      /* Faster-earning curve: lowers UPP when k<1 */
      CASE
        WHEN b.Premium_Base IS NULL OR b.Term <= 0 OR b.ElapsedMonths IS NULL THEN NULL
        ELSE b.Premium_Base * POWER(
               CASE
                 WHEN b.ElapsedMonths <= 0 THEN 1.0
                 WHEN b.ElapsedMonths >= b.Term THEN 0.0
                 ELSE s.RemainingShare
               END, @k)
      END AS SmoothedUPP_Raw,

      /* Prudence floor on forward exposure using scaled risk premium only */
      CASE
        WHEN b.Premium_Base IS NULL OR b.Term <= 0 OR b.ElapsedMonths IS NULL THEN NULL
        ELSE (b.Premium_Base * @RiskPremiumFactor) * s.RemainingShare * @FwdLossRatio * @SafetyMargin
      END AS UPP_FwdClaimsFloor
) f

/* Strict floor cap: never let floor exceed @MaxPctOfProductUPP * Product UPP */
CROSS APPLY (
    SELECT
      CASE
        WHEN f.UPP_FwdClaimsFloor IS NULL THEN NULL
        WHEN b.UPP IS NULL THEN f.UPP_FwdClaimsFloor
        ELSE
            CASE
              WHEN f.UPP_FwdClaimsFloor > (b.UPP * @MaxPctOfProductUPP)
              THEN b.UPP * @MaxPctOfProductUPP
              ELSE f.UPP_FwdClaimsFloor
            END
      END AS UPP_FwdClaimsFloor_Strict
) fcap

/* Pre-cap: take the max of curve result and the strictly capped floor */
CROSS APPLY (
    SELECT
      CASE
        WHEN f.SmoothedUPP_Raw IS NULL THEN fcap.UPP_FwdClaimsFloor_Strict
        WHEN fcap.UPP_FwdClaimsFloor_Strict IS NULL THEN f.SmoothedUPP_Raw
        WHEN f.SmoothedUPP_Raw < fcap.UPP_FwdClaimsFloor_Strict THEN fcap.UPP_FwdClaimsFloor_Strict
        ELSE f.SmoothedUPP_Raw
      END AS SmoothedUPP_PreCap
) c1

/* Final cap order:
   1) Hard ceiling to @MaxPctOfProductUPP * Product UPP
   2) Month-over-month drop limiter if prior UPP exists
*/
CROSS APPLY (
    SELECT
      CASE
        WHEN c1.SmoothedUPP_PreCap IS NULL THEN NULL
        /* Hard ceiling forces < product UPP */
        WHEN b.UPP IS NOT NULL AND c1.SmoothedUPP_PreCap > b.UPP * @MaxPctOfProductUPP
             THEN b.UPP * @MaxPctOfProductUPP
        /* Apply MoM drop cap */
        WHEN p.PrevUPP IS NOT NULL AND c1.SmoothedUPP_PreCap < p.PrevUPP * (1 - @MoMCapPct)
             THEN p.PrevUPP * (1 - @MoMCapPct)
        ELSE c1.SmoothedUPP_PreCap
      END AS SmoothedUPP
) cCap

/* Dealer relief provision equals what we remove from product UPP today */
CROSS APPLY (
    SELECT
      CASE
        WHEN b.UPP IS NULL OR cCap.SmoothedUPP IS NULL THEN NULL
        WHEN b.UPP > cCap.SmoothedUPP THEN b.UPP - cCap.SmoothedUPP
        ELSE CAST(0 AS decimal(38,10))
      END AS DealerReliefProvision
) prov

/* Straight-line release plan for the provision */
CROSS APPLY (
    SELECT
      CASE
        WHEN @ReliefMonths IS NULL OR @ReliefMonths <= 0 OR prov.DealerReliefProvision IS NULL THEN NULL
        ELSE prov.DealerReliefProvision / @ReliefMonths
      END AS DealerReliefMonthlyRelease
) c2

ORDER BY
    b.POL_PolicyNumber,
    b.Product_Level1, b.Product_Level2, b.Product_Level3,
    b.Term, b.ElapsedMonths;
