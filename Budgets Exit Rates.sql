Use Evolve

/*==============================================================
  PARAMETERS
==============================================================*/
DECLARE @StartDate date = '2023-07-01';  -- <== change as needed
DECLARE @EndDate   date = '2024-06-30';  -- <== change as needed

/*==============================================================
  SAFETY: NORMALISE DATES TO MONTH BOUNDARIES
==============================================================*/
;WITH DateNorm AS
(
    SELECT
          DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AS StartMonth
        , EOMONTH(@EndDate)                                     AS EndMonth
)
SELECT
      @StartDate = StartMonth
    , @EndDate   = EndMonth
FROM DateNorm;

/*==============================================================
  1. MONTH DIMENSION (YYYYMM)
==============================================================*/
IF OBJECT_ID('tempdb..#MonthDim') IS NOT NULL DROP TABLE #MonthDim;

;WITH MonthGen AS
(
    SELECT @StartDate AS MonthStart
    UNION ALL
    SELECT DATEADD(MONTH, 1, MonthStart)
    FROM MonthGen
    WHERE MonthStart < @EndDate
)
SELECT
      CAST(CONVERT(char(4), YEAR(MonthStart))
           + RIGHT('0' + CONVERT(varchar(2), MONTH(MonthStart)), 2) AS int) AS MonthKey
    , MonthStart
    , EOMONTH(MonthStart)                                           AS MonthEnd
INTO #MonthDim
FROM MonthGen
OPTION (MAXRECURSION 32767);

/*==============================================================
  2. POLICY / PRODUCT / INSURER / TERM DIMENSION
==============================================================*/
IF OBJECT_ID('tempdb..#PolicyDim') IS NOT NULL DROP TABLE #PolicyDim;

SELECT
      p.Policy_ID
    , p.POL_PolicyNumber                                 AS PolicyNumber
    , ins.INS_InsurerName                                AS Insurer
    , prd.PRD_FullName                                   AS ProductType
    , pf.RPF_Description                                 AS PaymentFrequency
    , CASE
          WHEN pf.RPF_Description = 'Monthly'
              THEN 'Monthly'
          WHEN pf.RPF_Description = 'Annually'
              THEN 'Annual'
          WHEN pf.RPF_Description = 'Term'
               AND ISNULL(p.POL_PolicyTerm, -1) > 0
              THEN 'Term ' + CAST(p.POL_PolicyTerm AS varchar(10))
          WHEN pf.RPF_Description = 'Term'
               AND ISNULL(p.POL_PolicyTerm, -1) <= 0
              THEN 'Term'
          ELSE 'Other'
      END                                               AS Term
    , CAST(p.POL_StartDate AS date)                     AS PolicyStartDate
    , CAST(p.POL_EndDate   AS date)                     AS PolicyEndDate
INTO #PolicyDim
FROM dbo.Policy p
    INNER JOIN dbo.ReferencePaymentFrequency pf
        ON pf.ReferencePaymentFrequency_ID = p.POL_PaymentFrequency_ID
       AND pf.RPF_Deleted = 0
    INNER JOIN dbo.PolicyInsurerLink pil
        ON pil.Policy_ID = p.Policy_ID
       AND pil.PIL_Deleted = 0
       AND pil.PIL_PrimaryInd = 1
    INNER JOIN dbo.Insurer ins
        ON ins.Insurer_Id = pil.PIL_Insurer_ID
       AND ins.INS_Deleted = 0
    INNER JOIN dbo.Product prd
        ON prd.Product_Id = p.POL_Product_ID
       AND prd.PRD_Deleted = 0
WHERE
      p.POL_Deleted = 0
  AND ins.INS_InsurerName IN (
          'Hollard Short Term'
        , 'Hollard Life'
        , 'Centriq Short Term'
        , 'Centriq Life'
      )
  -- Only policies that overlap the analysis window at all
  AND (
          p.POL_StartDate <= @EndDate
      AND (p.POL_EndDate IS NULL OR p.POL_EndDate >= @StartDate)
      );

/*==============================================================
  3. BASE EXPOSURE: POLICIES IN-FORCE PER MONTH
==============================================================*/
IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base;

SELECT
      md.MonthKey
    , pd.Insurer
    , pd.ProductType
    , pd.Term
    , COUNT(DISTINCT pd.Policy_ID) AS PolicyCount
INTO #Base
FROM #MonthDim md
    INNER JOIN #PolicyDim pd
        ON pd.PolicyStartDate <= md.MonthEnd
       AND (pd.PolicyEndDate IS NULL OR pd.PolicyEndDate >= md.MonthStart)
GROUP BY
      md.MonthKey
    , pd.Insurer
    , pd.ProductType
    , pd.Term;

/*==============================================================
  4. EXIT EVENTS FROM dbo.WesbankCancel
     - Map Reason -> Category (Lapse / Cancelled)
==============================================================*/
IF OBJECT_ID('tempdb..#ExitEvents') IS NOT NULL DROP TABLE #ExitEvents;

SELECT
      wc.Policy_ID
    , CAST(wc.CancelDate AS date) AS CancelDate
    , CAST(CONVERT(char(4), YEAR(wc.CancelDate))
           + RIGHT('0' + CONVERT(varchar(2), MONTH(wc.CancelDate)), 2) AS int) AS MonthKey
    , wc.Reason
    , CASE
          -- Lapse reasons (from your mapping list)
          WHEN wc.Reason IN (
                   'Cancelled - 3 Consecutive unmets'
                 , 'Cancelled - 2 Consecutive unmets'
                 , 'Non-payment'
                 , 'Lapsed - No Premium Received'
                 , 'Cancelled - 6 Intermittent unmets'
                 , 'None payment'
                 , 'Failed 3 consecutive monthly debits'
                 , 'Non payment '
                 , 'Non-receipt of debit order authority'
             )
              THEN 'Lapse'
          ELSE 'Cancelled'
      END AS ExitCategory
INTO #ExitEvents
FROM dbo.WesbankCancel wc
WHERE
      wc.CancelDate >= @StartDate
  AND wc.CancelDate <  DATEADD(DAY, 1, @EndDate);  -- inclusive end-date

/*==============================================================
  5. EXIT COUNTS (LAPSE / CANCELLED) BY POLICY + MONTH
==============================================================*/
IF OBJECT_ID('tempdb..#ExitCounts') IS NOT NULL DROP TABLE #ExitCounts;

SELECT
      ee.MonthKey
    , pd.Insurer
    , pd.ProductType
    , pd.Term
    , SUM(CASE WHEN ee.ExitCategory = 'Lapse'     THEN 1 ELSE 0 END) AS LapseCount
    , SUM(CASE WHEN ee.ExitCategory = 'Cancelled' THEN 1 ELSE 0 END) AS CancelCount
INTO #ExitCounts
FROM #ExitEvents ee
    INNER JOIN #PolicyDim pd
        ON pd.Policy_ID = ee.Policy_ID
GROUP BY
      ee.MonthKey
    , pd.Insurer
    , pd.ProductType
    , pd.Term;

/*==============================================================
  6. FULL RATE GRID (ONE ROW PER COMBO)
==============================================================*/
IF OBJECT_ID('tempdb..#RateLong') IS NOT NULL DROP TABLE #RateLong;

SELECT
      b.MonthKey
    , b.Insurer
    , b.ProductType
    , b.Term
    , ISNULL(ec.LapseCount , 0)                             AS LapseCount
    , ISNULL(ec.CancelCount, 0)                             AS CancelCount
    , b.PolicyCount
    , CAST(
          CASE WHEN b.PolicyCount > 0
               THEN ISNULL(ec.LapseCount , 0.0) / b.PolicyCount
               ELSE 0.0
          END AS decimal(18, 6))                            AS LapseRate
    , CAST(
          CASE WHEN b.PolicyCount > 0
               THEN ISNULL(ec.CancelCount, 0.0) / b.PolicyCount
               ELSE 0.0
          END AS decimal(18, 6))                            AS CancelRate
    , CAST(
          CASE WHEN b.PolicyCount > 0
               THEN (ISNULL(ec.LapseCount, 0.0)
                   + ISNULL(ec.CancelCount, 0.0)) / b.PolicyCount
               ELSE 0.0
          END AS decimal(18, 6))                            AS TotalExitRate
INTO #RateLong
FROM #Base b
    LEFT JOIN #ExitCounts ec
        ON ec.MonthKey    = b.MonthKey
       AND ec.Insurer     = b.Insurer
       AND ec.ProductType = b.ProductType
       AND ec.Term        = b.Term;

/*==============================================================
  7. PIVOT: LAPSE RATE TABLE
==============================================================*/
PRINT 'LAPSE RATE TABLE';

SELECT
      rl.Insurer
    , rl.ProductType
    , rl.Term
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202307 THEN rl.LapseRate END), 0.000000) AS [202307]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202308 THEN rl.LapseRate END), 0.000000) AS [202308]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202309 THEN rl.LapseRate END), 0.000000) AS [202309]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202310 THEN rl.LapseRate END), 0.000000) AS [202310]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202311 THEN rl.LapseRate END), 0.000000) AS [202311]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202312 THEN rl.LapseRate END), 0.000000) AS [202312]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202401 THEN rl.LapseRate END), 0.000000) AS [202401]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202402 THEN rl.LapseRate END), 0.000000) AS [202402]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202403 THEN rl.LapseRate END), 0.000000) AS [202403]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202404 THEN rl.LapseRate END), 0.000000) AS [202404]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202405 THEN rl.LapseRate END), 0.000000) AS [202405]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202406 THEN rl.LapseRate END), 0.000000) AS [202406]
FROM #RateLong rl
GROUP BY
      rl.Insurer
    , rl.ProductType
    , rl.Term
ORDER BY
      rl.Insurer
    , rl.ProductType
    , rl.Term;

/*==============================================================
  8. PIVOT: CANCELLATION RATE TABLE
==============================================================*/
PRINT 'CANCELLATION RATE TABLE';

SELECT
      rl.Insurer
    , rl.ProductType
    , rl.Term
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202307 THEN rl.CancelRate END), 0.000000) AS [202307]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202308 THEN rl.CancelRate END), 0.000000) AS [202308]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202309 THEN rl.CancelRate END), 0.000000) AS [202309]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202310 THEN rl.CancelRate END), 0.000000) AS [202310]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202311 THEN rl.CancelRate END), 0.000000) AS [202311]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202312 THEN rl.CancelRate END), 0.000000) AS [202312]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202401 THEN rl.CancelRate END), 0.000000) AS [202401]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202402 THEN rl.CancelRate END), 0.000000) AS [202402]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202403 THEN rl.CancelRate END), 0.000000) AS [202403]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202404 THEN rl.CancelRate END), 0.000000) AS [202404]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202405 THEN rl.CancelRate END), 0.000000) AS [202405]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202406 THEN rl.CancelRate END), 0.000000) AS [202406]
FROM #RateLong rl
GROUP BY
      rl.Insurer
    , rl.ProductType
    , rl.Term
ORDER BY
      rl.Insurer
    , rl.ProductType
    , rl.Term;

/*==============================================================
  9. PIVOT: TOTAL EXIT RATE TABLE
==============================================================*/
PRINT 'TOTAL EXIT RATE TABLE';

SELECT
      rl.Insurer
    , rl.ProductType
    , rl.Term
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202307 THEN rl.TotalExitRate END), 0.000000) AS [202307]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202308 THEN rl.TotalExitRate END), 0.000000) AS [202308]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202309 THEN rl.TotalExitRate END), 0.000000) AS [202309]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202310 THEN rl.TotalExitRate END), 0.000000) AS [202310]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202311 THEN rl.TotalExitRate END), 0.000000) AS [202311]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202312 THEN rl.TotalExitRate END), 0.000000) AS [202312]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202401 THEN rl.TotalExitRate END), 0.000000) AS [202401]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202402 THEN rl.TotalExitRate END), 0.000000) AS [202402]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202403 THEN rl.TotalExitRate END), 0.000000) AS [202403]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202404 THEN rl.TotalExitRate END), 0.000000) AS [202404]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202405 THEN rl.TotalExitRate END), 0.000000) AS [202405]
    , ISNULL(MAX(CASE WHEN rl.MonthKey = 202406 THEN rl.TotalExitRate END), 0.000000) AS [202406]
FROM #RateLong rl
GROUP BY
      rl.Insurer
    , rl.ProductType
    , rl.Term
ORDER BY
      rl.Insurer
    , rl.ProductType
    , rl.Term;
