-- EVPRODREP01 — Active, Cancelled, Termination, New Business
USE RB_Analysis;

DECLARE @StartMonth INT = 202306;                 -- inclusive YYYYMM
DECLARE @EndMonth   INT = 202508;                 -- inclusive YYYYMM
DECLARE @TyreRimStartMonth INT = 202410;          -- Tyre & Rim counts start from 202410
DECLARE @UnlimitedName NVARCHAR(100) = N'THE UNLIMITED - CENTRIQ';

--------------------------------------------------------------------------------
-- 1) ACTIVE
--------------------------------------------------------------------------------
;WITH base AS (
    SELECT
        mm       = TRY_CAST(s.Measurement_Month AS INT),
        prd      = UPPER(LTRIM(RTRIM(s.PRD_Name))),
        variant  = UPPER(LTRIM(RTRIM(CONVERT(VARCHAR(400), s.Product_Variant)))),
        insurer  = UPPER(LTRIM(RTRIM(s.Insurer_Name))),
        sold_dt  = CONVERT(date, s.POL_SoldDate),
        s.Policy_id
    FROM [RB_Analysis].[dbo].[Evolve_policy_Month_end_Snapshot] AS s WITH (NOLOCK)
    WHERE UPPER(s.Policy_Status) = 'IN FORCE'
      AND TRY_CAST(s.Measurement_Month AS INT) BETWEEN @StartMonth AND @EndMonth
),
policy_month AS ( -- de-dupe per policy per month
    SELECT mm, Policy_id, prd, variant, insurer, MIN(sold_dt) AS sold_dt
    FROM base
    GROUP BY mm, Policy_id, prd, variant, insurer
)
SELECT
    [Month]      = pm.mm,
	[Month Text] = CONVERT(varchar(10), DATEFROMPARTS(pm.mm/100, pm.mm%100, 1), 111),

    -- PRODUCTS (Centriq/Hollard only, excluding Unlimited)
    [Warranties] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd LIKE '%WARRANTY%' THEN 1 ELSE 0 END),

    [Warranty Booster] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd LIKE '%WARRANTY%' AND COALESCE(pm.variant,'') LIKE '%BOOSTER%' THEN 1 ELSE 0 END),

    [Warranty Non-Booster] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd LIKE '%WARRANTY%' AND COALESCE(pm.variant,'') NOT LIKE '%BOOSTER%' THEN 1 ELSE 0 END),

    [Mobility Life Cover] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                            'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),

    [Scratch and Dent] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd IN ('SCRATCH & DENT','PAINT TECH','PAINT TECH (H)') THEN 1 ELSE 0 END),

    [Adcover] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd IN ('ADCOVER','ADCOVER & DEPOSIT COVER COMBO',
                            'ADCOVER & DEPOSIT COVER COMBO (H)','ADCOVER (H)',
                            'AUTO PEDIGREE PLUS PLAN WITH DEPOSIT COVER',
                            'COMBO PRODUCTS',
                            'VEHICLE VALUE PROTECTOR') THEN 1 ELSE 0 END),

    [Deposit Cover] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd IN ('DEPOSIT COVER','DEPOSIT COVER (H)') THEN 1 ELSE 0 END),

    -- Tyre & Rim: Centriq/Hollard only, exclude Unlimited, start at 202410
    [Tyre and Rim] = SUM(CASE
        WHEN ((pm.insurer LIKE '%CENTRIQ%' OR pm.insurer LIKE '%HOLLARD%') AND pm.insurer <> @UnlimitedName)
             AND pm.prd = 'TYRE AND RIM'
             AND pm.mm >= @TyreRimStartMonth THEN 1 ELSE 0 END),

    -- INSURERS (excluding Unlimited)
    [Centriq Short Term] = SUM(CASE
        WHEN (pm.insurer LIKE '%CENTRIQ%' AND pm.insurer <> @UnlimitedName)
             AND pm.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),

    [Centriq Life] = SUM(CASE
        WHEN (pm.insurer LIKE '%CENTRIQ%' AND pm.insurer <> @UnlimitedName)
             AND pm.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                            'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),

    [Hollard Short Term] = SUM(CASE
        WHEN pm.insurer LIKE '%HOLLARD%'
             AND pm.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),

    [Hollard Life] = SUM(CASE
        WHEN pm.insurer LIKE '%HOLLARD%'
             AND pm.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                            'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),

    -- Separate column
    [The Unlimited - Centriq] = SUM(CASE WHEN pm.insurer = @UnlimitedName THEN 1 ELSE 0 END),

    -- Other insurers
    [Discovery Insure] = SUM(CASE WHEN pm.insurer LIKE '%DISCOVERY%' THEN 1 ELSE 0 END),
    [MiWay]            = SUM(CASE WHEN pm.insurer LIKE '%MIWAY%'     THEN 1 ELSE 0 END),
    [Santam Limited]   = SUM(CASE WHEN pm.insurer LIKE '%SANTAM%'    THEN 1 ELSE 0 END),
    [Old Mutual Insurance] = SUM(CASE WHEN pm.insurer LIKE '%OLD MUTUAL%' OR pm.insurer LIKE '%OLDMUTUAL%' THEN 1 ELSE 0 END)
FROM policy_month pm
GROUP BY pm.mm
ORDER BY pm.mm;

--------------------------------------------------------------------------------
-- 2) CANCELLED & 3) TERMINATION (Policy_Status = 'CANCELLED'
--    AND Policy_Cancellation_date must fall in Measurement_Month)
--------------------------------------------------------------------------------
DECLARE @TerminationReasons TABLE (Reason NVARCHAR(200) PRIMARY KEY);
INSERT INTO @TerminationReasons(Reason) VALUES
(N'END OF POLICY TERM'),
(N'END OF TERM'),
(N'END OF TERM - POLICY NOT RENEWED'),
(N'TERMINATION - END OF TERM');

IF OBJECT_ID('tempdb..#tagged') IS NOT NULL DROP TABLE #tagged;

;WITH base_c AS (
    SELECT
        mm              = TRY_CAST(s.Measurement_Month AS INT),
        prd             = UPPER(LTRIM(RTRIM(s.PRD_Name))),
        variant         = UPPER(LTRIM(RTRIM(CONVERT(VARCHAR(400), s.Product_Variant)))),
        insurer         = UPPER(LTRIM(RTRIM(s.Insurer_Name))),
        cancel_reason   = UPPER(LTRIM(RTRIM(s.Cancellation_Reason))),
        cancel_dt       = CONVERT(date, s.Policy_Cancellation_date),
        cancel_mm       = CASE WHEN s.Policy_Cancellation_date IS NULL THEN NULL
                               ELSE YEAR(s.Policy_Cancellation_date) * 100 + MONTH(s.Policy_Cancellation_date) END,
        s.Policy_id
    FROM [RB_Analysis].[dbo].[Evolve_policy_Month_end_Snapshot] AS s WITH (NOLOCK)
    WHERE UPPER(s.Policy_Status) = 'CANCELLED'
      AND TRY_CAST(s.Measurement_Month AS INT) BETWEEN @StartMonth AND @EndMonth
      AND s.Policy_Cancellation_date IS NOT NULL                 -- <<< ensure a real cancellation date
),
policy_month_c AS ( -- de-dupe per policy per month; keep only rows whose cancel month = measurement month
    SELECT
        mm, Policy_id, prd, variant, insurer, cancel_reason,
        MIN(cancel_dt) AS cancel_dt
    FROM base_c
    WHERE cancel_mm = mm                                         -- <<< the key fix
    GROUP BY mm, Policy_id, prd, variant, insurer, cancel_reason
)
SELECT
    pmc.*,
    ReasonBucket = CASE
        WHEN EXISTS (SELECT 1 FROM @TerminationReasons r WHERE r.Reason = COALESCE(pmc.cancel_reason,N'')) THEN 'TERMINATION'
        ELSE 'CANCELLED'
    END
INTO #tagged
FROM policy_month_c pmc;

-- 2) CANCELLED TABLE
SELECT
    [Month]      = t.mm,
    [Month Text] = CONVERT(varchar(10), DATEFROMPARTS(t.mm/100, t.mm%100, 1), 111),
    [Warranties] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                 AND t.prd LIKE '%WARRANTY%' THEN 1 ELSE 0 END),
    [Warranty Booster] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                      AND t.prd LIKE '%WARRANTY%' AND COALESCE(t.variant,'') LIKE '%BOOSTER%' THEN 1 ELSE 0 END),
    [Warranty Non-Booster] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                          AND t.prd LIKE '%WARRANTY%' AND COALESCE(t.variant,'') NOT LIKE '%BOOSTER%' THEN 1 ELSE 0 END),
    [Mobility Life Cover] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                          AND t.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                        'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Scratch and Dent] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                      AND t.prd IN ('SCRATCH & DENT','PAINT TECH','PAINT TECH (H)') THEN 1 ELSE 0 END),
    [Adcover] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                             AND t.prd IN ('ADCOVER','ADCOVER & DEPOSIT COVER COMBO',
                                           'ADCOVER & DEPOSIT COVER COMBO (H)','ADCOVER (H)',
                                           'AUTO PEDIGREE PLUS PLAN WITH DEPOSIT COVER',
                                           'COMBO PRODUCTS',
                                           'VEHICLE VALUE PROTECTOR') THEN 1 ELSE 0 END),
    [Deposit Cover] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                   AND t.prd IN ('DEPOSIT COVER','DEPOSIT COVER (H)') THEN 1 ELSE 0 END),
    [Tyre and Rim] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                   AND t.prd = 'TYRE AND RIM'
                                   AND t.mm >= @TyreRimStartMonth THEN 1 ELSE 0 END),
    [Centriq Short Term] = SUM(CASE WHEN (t.insurer LIKE '%CENTRIQ%' AND t.insurer <> @UnlimitedName)
                                         AND t.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                           'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Centriq Life] = SUM(CASE WHEN (t.insurer LIKE '%CENTRIQ%' AND t.insurer <> @UnlimitedName)
                                   AND t.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                 'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Hollard Short Term] = SUM(CASE WHEN t.insurer LIKE '%HOLLARD%'
                                         AND t.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                           'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Hollard Life] = SUM(CASE WHEN t.insurer LIKE '%HOLLARD%'
                                   AND t.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                 'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [The Unlimited - Centriq] = SUM(CASE WHEN t.insurer = @UnlimitedName THEN 1 ELSE 0 END),
    [Discovery Insure] = SUM(CASE WHEN t.insurer LIKE '%DISCOVERY%' THEN 1 ELSE 0 END),
    [MiWay]            = SUM(CASE WHEN t.insurer LIKE '%MIWAY%'     THEN 1 ELSE 0 END),
    [Santam Limited]   = SUM(CASE WHEN t.insurer LIKE '%SANTAM%'    THEN 1 ELSE 0 END),
    [Old Mutual Insurance] = SUM(CASE WHEN t.insurer LIKE '%OLD MUTUAL%' OR t.insurer LIKE '%OLDMUTUAL%' THEN 1 ELSE 0 END)
FROM #tagged t
WHERE t.ReasonBucket = 'CANCELLED'
GROUP BY t.mm
ORDER BY t.mm;

-- 3) TERMINATION TABLE
SELECT
    [Month]      = t.mm,
    [Month Text] = CONVERT(varchar(10), DATEFROMPARTS(t.mm/100, t.mm%100, 1), 111),
    [Warranties] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                 AND t.prd LIKE '%WARRANTY%' THEN 1 ELSE 0 END),
    [Warranty Booster] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                      AND t.prd LIKE '%WARRANTY%' AND COALESCE(t.variant,'') LIKE '%BOOSTER%' THEN 1 ELSE 0 END),
    [Warranty Non-Booster] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                          AND t.prd LIKE '%WARRANTY%' AND COALESCE(t.variant,'') NOT LIKE '%BOOSTER%' THEN 1 ELSE 0 END),
    [Mobility Life Cover] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                          AND t.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                        'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Scratch and Dent] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                      AND t.prd IN ('SCRATCH & DENT','PAINT TECH','PAINT TECH (H)') THEN 1 ELSE 0 END),
    [Adcover] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                             AND t.prd IN ('ADCOVER','ADCOVER & DEPOSIT COVER COMBO',
                                           'ADCOVER & DEPOSIT COVER COMBO (H)','ADCOVER (H)',
                                           'AUTO PEDIGREE PLUS PLAN WITH DEPOSIT COVER',
                                           'COMBO PRODUCTS',
                                           'VEHICLE VALUE PROTECTOR') THEN 1 ELSE 0 END),
    [Deposit Cover] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                   AND t.prd IN ('DEPOSIT COVER','DEPOSIT COVER (H)') THEN 1 ELSE 0 END),
    [Tyre and Rim] = SUM(CASE WHEN ((t.insurer LIKE '%CENTRIQ%' OR t.insurer LIKE '%HOLLARD%') AND t.insurer <> @UnlimitedName)
                                   AND t.prd = 'TYRE AND RIM'
                                   AND t.mm >= @TyreRimStartMonth THEN 1 ELSE 0 END),
    [Centriq Short Term] = SUM(CASE WHEN (t.insurer LIKE '%CENTRIQ%' AND t.insurer <> @UnlimitedName)
                                         AND t.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                           'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Centriq Life] = SUM(CASE WHEN (t.insurer LIKE '%CENTRIQ%' AND t.insurer <> @UnlimitedName)
                                   AND t.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                 'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Hollard Short Term] = SUM(CASE WHEN t.insurer LIKE '%HOLLARD%'
                                         AND t.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                           'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Hollard Life] = SUM(CASE WHEN t.insurer LIKE '%HOLLARD%'
                                   AND t.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                 'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [The Unlimited - Centriq] = SUM(CASE WHEN t.insurer = @UnlimitedName THEN 1 ELSE 0 END),
    [Discovery Insure] = SUM(CASE WHEN t.insurer LIKE '%DISCOVERY%' THEN 1 ELSE 0 END),
    [MiWay]            = SUM(CASE WHEN t.insurer LIKE '%MIWAY%'     THEN 1 ELSE 0 END),
    [Santam Limited]   = SUM(CASE WHEN t.insurer LIKE '%SANTAM%'    THEN 1 ELSE 0 END),
    [Old Mutual Insurance] = SUM(CASE WHEN t.insurer LIKE '%OLD MUTUAL%' OR t.insurer LIKE '%OLDMUTUAL%' THEN 1 ELSE 0 END)
FROM #tagged t
WHERE t.ReasonBucket = 'TERMINATION'
GROUP BY t.mm
ORDER BY t.mm;

--------------------------------------------------------------------------------
-- 4) NEW BUSINESS (Status In Force, NTU, Pending, Renewal AND SoldDate in month)
--------------------------------------------------------------------------------
;WITH base_nb AS (
    SELECT
        mm        = TRY_CAST(s.Measurement_Month AS INT),
        prd       = UPPER(LTRIM(RTRIM(s.PRD_Name))),
        variant   = UPPER(LTRIM(RTRIM(CONVERT(VARCHAR(400), s.Product_Variant)))),
        insurer   = UPPER(LTRIM(RTRIM(s.Insurer_Name))),
        sold_dt   = CONVERT(date, s.POL_SoldDate),
        sold_mm   = CASE WHEN s.POL_SoldDate IS NULL THEN NULL
                         ELSE (YEAR(s.POL_SoldDate) * 100 + MONTH(s.POL_SoldDate)) END,
        s.Policy_id
    FROM [RB_Analysis].[dbo].[Evolve_policy_Month_end_Snapshot] AS s WITH (NOLOCK)
    WHERE UPPER(s.Policy_Status) IN ('IN FORCE','NTU','PENDING','RENEWAL')
      AND TRY_CAST(s.Measurement_Month AS INT) BETWEEN @StartMonth AND @EndMonth
      AND s.POL_SoldDate IS NOT NULL
),
policy_month_nb AS ( -- de-dupe per policy per month, keep only sold in month
    SELECT
        mm, Policy_id, prd, variant, insurer,
        MIN(sold_dt) AS sold_dt
    FROM base_nb
    WHERE sold_mm = mm
    GROUP BY mm, Policy_id, prd, variant, insurer
)
SELECT
    [Month]      = nb.mm,
    [Month Text] = CONVERT(varchar(10), DATEFROMPARTS(nb.mm/100, nb.mm%100, 1), 111),
    [Warranties] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                 AND nb.prd LIKE '%WARRANTY%' THEN 1 ELSE 0 END),
    [Warranty Booster] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                      AND nb.prd LIKE '%WARRANTY%' AND COALESCE(nb.variant,'') LIKE '%BOOSTER%' THEN 1 ELSE 0 END),
    [Warranty Non-Booster] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                          AND nb.prd LIKE '%WARRANTY%' AND COALESCE(nb.variant,'') NOT LIKE '%BOOSTER%' THEN 1 ELSE 0 END),
    [Mobility Life Cover] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                          AND nb.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                         'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Scratch and Dent] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                      AND nb.prd IN ('SCRATCH & DENT','PAINT TECH','PAINT TECH (H)') THEN 1 ELSE 0 END),
    [Adcover] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                             AND nb.prd IN ('ADCOVER','ADCOVER & DEPOSIT COVER COMBO',
                                            'ADCOVER & DEPOSIT COVER COMBO (H)','ADCOVER (H)',
                                            'AUTO PEDIGREE PLUS PLAN WITH DEPOSIT COVER',
                                            'COMBO PRODUCTS',
                                            'VEHICLE VALUE PROTECTOR') THEN 1 ELSE 0 END),
    [Deposit Cover] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                   AND nb.prd IN ('DEPOSIT COVER','DEPOSIT COVER (H)') THEN 1 ELSE 0 END),
    [Tyre and Rim] = SUM(CASE WHEN ((nb.insurer LIKE '%CENTRIQ%' OR nb.insurer LIKE '%HOLLARD%') AND nb.insurer <> @UnlimitedName)
                                   AND nb.prd = 'TYRE AND RIM'
                                   AND nb.mm >= @TyreRimStartMonth THEN 1 ELSE 0 END),
    [Centriq Short Term] = SUM(CASE WHEN (nb.insurer LIKE '%CENTRIQ%' AND nb.insurer <> @UnlimitedName)
                                         AND nb.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                            'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Centriq Life] = SUM(CASE WHEN (nb.insurer LIKE '%CENTRIQ%' AND nb.insurer <> @UnlimitedName)
                                   AND nb.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                  'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Hollard Short Term] = SUM(CASE WHEN nb.insurer LIKE '%HOLLARD%'
                                         AND nb.prd NOT IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                            'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [Hollard Life] = SUM(CASE WHEN nb.insurer LIKE '%HOLLARD%'
                                   AND nb.prd IN ('MOBILITY LIFE COVER','MOBILITY LIFE COVER (H)',
                                                  'LIFESTYLE PROTECTION PLAN','LIFESTYLE PROTECTION PLAN (H)') THEN 1 ELSE 0 END),
    [The Unlimited - Centriq] = SUM(CASE WHEN nb.insurer = @UnlimitedName THEN 1 ELSE 0 END),
    [Discovery Insure] = SUM(CASE WHEN nb.insurer LIKE '%DISCOVERY%' THEN 1 ELSE 0 END),
    [MiWay]            = SUM(CASE WHEN nb.insurer LIKE '%MIWAY%'     THEN 1 ELSE 0 END),
    [Santam Limited]   = SUM(CASE WHEN nb.insurer LIKE '%SANTAM%'    THEN 1 ELSE 0 END),
    [Old Mutual Insurance] = SUM(CASE WHEN nb.insurer LIKE '%OLD MUTUAL%' OR nb.insurer LIKE '%OLDMUTUAL%' THEN 1 ELSE 0 END)
FROM policy_month_nb nb
GROUP BY nb.mm
ORDER BY nb.mm;
