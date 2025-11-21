/* -----------------------------------------------------------------------
   Monthly cancellation summary – policy level (optimised)
   Insurers: OMI, Discovery, MiWay, Santam (incl. SWTY* policies)
   Source: MS-ACT01.Evolve (Policy table only)
   RB_Analysis via EVPRODREP01

   1H38
------------------------------------------------------------------------ */

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

----------------------------------------------------------
-- 0) Set your reporting window here
----------------------------------------------------------
DECLARE @StartDateInclusive date = '2024-07-01';  -- << change this
DECLARE @EndDateInclusive   date = '2025-10-31';  -- << and this

----------------------------------------------------------
-- 1) Pull only relevant policies into a temp table
--    - Filter early by:
--        * insurer (incl. SWTY = Santam)
--        * status (In Force / Cancelled / Renewal)
--        * date overlap with reporting window
----------------------------------------------------------
IF OBJECT_ID('tempdb..#RawPolicies') IS NOT NULL DROP TABLE #RawPolicies;

SELECT
    -- Normalised insurer name
    CASE 
        WHEN INS.INS_InsurerName LIKE 'Old Mutual%'  THEN 'OMI'
        WHEN INS.INS_InsurerName LIKE 'Discovery%'   THEN 'Discovery'
        WHEN INS.INS_InsurerName LIKE 'MiWay%'       THEN 'MiWay'
        WHEN INS.INS_InsurerName LIKE 'Santam%'      THEN 'Santam'
        WHEN INS.INS_InsurerName IS NULL
             AND P.POL_PolicyNumber LIKE 'SWTY%'     THEN 'Santam'  -- Santam SWTY portfolio
        ELSE INS.INS_InsurerName
    END AS Insurer,

    P.POL_PolicyNumber              AS POL_PolicyNumber,
    POS.POS_Description             AS Policy_Status,
    P.POL_StartDate                 AS pol_startdate,
    P.POL_EndDate                   AS pol_Enddate
INTO #RawPolicies
FROM [MS-ACT01].[Evolve].[dbo].[Policy] AS P
LEFT JOIN [MS-ACT01].[Evolve].[dbo].[ReferencePolicyStatus] AS POS
    ON POS.PolicyStatus_ID = P.POL_Status
   AND POS.POS_Deleted     = 0
LEFT JOIN [MS-ACT01].[Evolve].[dbo].[PolicyInsurerLink] AS PIL
    ON PIL.PIL_Policy_ID      = P.Policy_ID
   AND PIL.PIL_Deleted        = 0
   AND PIL.PIL_Lead_Indicator = 1
LEFT JOIN [MS-ACT01].[Evolve].[dbo].[Insurer] AS INS
    ON INS.Insurer_Id = PIL.PIL_Insurer_ID
WHERE
    -- Only our four insurers (including SWTY as Santam)
    (
         INS.INS_InsurerName LIKE 'Old Mutual%'
      OR INS.INS_InsurerName LIKE 'Discovery%'
      OR INS.INS_InsurerName LIKE 'MiWay%'
      OR INS.INS_InsurerName LIKE 'Santam%'
      OR (INS.INS_InsurerName IS NULL AND P.POL_PolicyNumber LIKE 'SWTY%')
    )
    -- Only statuses we actually care about for exposure / cancellation
    AND POS.POS_Description IN ('In Force','Cancelled','Renewal')
    -- Only policies that overlap our reporting window
    AND P.POL_EndDate   >= @StartDateInclusive
    AND P.POL_StartDate <= @EndDateInclusive;

-- Helpful index for later joins
CREATE INDEX IX_RawPolicies_InsurerDates
    ON #RawPolicies(Insurer, pol_startdate, pol_Enddate);


----------------------------------------------------------
-- 2) Add effective dates + Renewed flag (cross-server join,
--    but only for the filtered policy set)
----------------------------------------------------------
IF OBJECT_ID('tempdb..#AggPolicies') IS NOT NULL DROP TABLE #AggPolicies;

SELECT
    R.Insurer,
    R.POL_PolicyNumber,

    CASE
        WHEN R.Policy_Status IN ('In Force','Cancelled') THEN R.pol_startdate
        ELSE CONVERT(date,'2050-01-01')
    END AS Effective_Start_Date,

    CASE
        WHEN R.Policy_Status IN ('In Force','Cancelled') THEN R.pol_Enddate
        ELSE CONVERT(date,'2050-01-01')
    END AS Effective_End_Date,

    CASE
        WHEN ISNULL(EP.Cancellation_Reason,'') LIKE '%renewed%' THEN 1
        ELSE 0
    END AS Renewed
INTO #AggPolicies
FROM #RawPolicies AS R
LEFT JOIN [EVPRODREP01].[RB_Analysis].[dbo].[Evolve_Policy] AS EP
    ON R.POL_PolicyNumber = EP.POL_PolicyNumber
WHERE
    R.Policy_Status <> 'Renewal';

CREATE INDEX IX_AggPolicies_InsurerDates
    ON #AggPolicies(Insurer, Effective_Start_Date, Effective_End_Date);


----------------------------------------------------------
-- 3) Get months in range into a small temp table
----------------------------------------------------------
IF OBJECT_ID('tempdb..#Months') IS NOT NULL DROP TABLE #Months;

SELECT
    Mo,
    month_start,
    date_end
INTO #Months
FROM [EVPRODREP01].[RB_Analysis].[dbo].[rb_months]
WHERE
    date_end   < GETDATE()              -- completed months
    AND month_start >= @StartDateInclusive
    AND date_end    <= @EndDateInclusive;

CREATE INDEX IX_Months_Dates
    ON #Months(month_start, date_end);


----------------------------------------------------------
-- 4) Final aggregation:
--    - Only join actual policies to relevant months
--    - No CROSS JOIN to all insurers; just GROUP BY Insurer
----------------------------------------------------------
SELECT
    M.Mo,
    A.Insurer,
    M.month_start AS StartDate_Inclusive,
    M.date_end    AS EndDate_Inclusive,
    COUNT(A.POL_PolicyNumber) AS LineCount,
    SUM(
        CASE
            WHEN A.Effective_End_Date >= M.month_start
             AND A.Effective_End_Date <= M.date_end
             AND A.Renewed = 0
            THEN 1 ELSE 0
        END
    ) AS Cancel_in_Month,
    CASE
        WHEN COUNT(A.POL_PolicyNumber) = 0 THEN 0
        ELSE CAST(
            SUM(
                CASE
                    WHEN A.Effective_End_Date >= M.month_start
                     AND A.Effective_End_Date <= M.date_end
                     AND A.Renewed = 0
                    THEN 1 ELSE 0
                END
            ) AS decimal(10,4)
        ) / COUNT(A.POL_PolicyNumber)
    END AS CancellationRate
FROM #AggPolicies AS A
JOIN #Months      AS M
  ON A.Effective_Start_Date <= M.month_start
 AND A.Effective_End_Date   >= M.month_start
GROUP BY
    M.Mo,
    M.month_start,
    M.date_end,
    A.Insurer
ORDER BY
    M.Mo,
    A.Insurer;
