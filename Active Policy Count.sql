/* =======================================================================================
   PARAMETERS
=========================================================================================*/
USE Evolve;
GO

DECLARE @StartDate DATE = '2023-07-01';
DECLARE @EndDate   DATE = '2025-06-30';

/* =======================================================================================
   1. MONTH CALENDAR
=========================================================================================*/
;WITH MonthRange AS (
    SELECT DATEFROMPARTS(YEAR(@StartDate),MONTH(@StartDate),1) AS MonthStart
    UNION ALL
    SELECT DATEADD(MONTH,1,MonthStart)
    FROM   MonthRange
    WHERE  DATEADD(MONTH,1,MonthStart) <= @EndDate
),

/* =======================================================================================
   2. BASE POLICIES (+ product / insurer mapping, SoldDate added)
=========================================================================================*/
BasePolicies AS (
    SELECT
        p.POL_PolicyNumber,
        p.Policy_ID,
        p.POL_StartDate,
        p.POL_EndDate,
        p.POL_Status,
        p.POL_SoldDate,                       -- << used for New-Business
        p.POL_Product_ID         AS Product_Id,
        p.pol_productvariantlevel1_id,
        pil.PIL_Insurer_ID       AS InsurerId,
        ISNULL(i.INS_InsurerName,'Unknown') AS INS_InsurerName,   -- << keep null-safe
        /* ---------- PRODUCT BUCKET ---------- */
        CASE
            WHEN p.POL_Product_ID IN
                ('77C92C34-0CBB-4554-BD41-01F2D8F5FC11','436BB1D0-CB35-4FF0-BD50-A316A08AE87B',
                 '70292F27-B7EE-4274-8B51-E345F4C1AD18','86E44060-B546-4A65-9464-9C4F78C1681E',
                 'DDDC2DA4-881F-40B9-A156-8B7EA881863A')                                                 
			THEN 'Adcover'
            WHEN p.POL_Product_ID IN
                ('22D1B06F-BE25-4FA4-AAD4-447F13E13728','83A65AC4-37EC-4776-959D-99D46D0A2A10',
                 'DF78BA49-F342-4745-B3B9-39F21430EB24')                                                 
			THEN 'Mobility Life Cover'
            WHEN p.POL_Product_ID IN
                ('529AFE28-A2BF-4841-9B56-F334660C6CBD','A68AD927-C8B3-47A1-909E-785BDB017377')           
			THEN 'Scratch & Dent'
            WHEN p.POL_Product_ID =  'A4AF17CF-89D0-47AC-A447-F135310042D7'                              
			THEN 'Discovery'
            WHEN p.POL_Product_ID IN
                ('1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB','5557806D-8733-458E-969A-9134F37C77D2',
                 'A80549F3-E47F-44C1-8037-F065522A03F6')                                                
			THEN 'Deposit Cover'
            WHEN p.POL_Product_ID =  '83C026A9-17FF-4A87-9CA9-E82C2535B538'
                 AND pil.PIL_Insurer_ID =  '28BEBA82-5AD3-49A7-A9F0-714542B6B2A8'                         
			THEN 'Santam'
            WHEN p.POL_Product_ID =  '83C026A9-17FF-4A87-9CA9-E82C2535B538'
                 AND pil.PIL_Insurer_ID =  '0F2B8071-42D3-4150-A25E-F58576321AF3'                         
			THEN 'OMI'
            WHEN p.POL_Product_ID =  '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
                 AND pil.PIL_Insurer_ID =  '8EFAD6A1-F56B-40FE-B79D-4D8630196F2F'                         
			THEN 'MiWay'
            WHEN p.POL_Product_ID =  '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
                 AND p.pol_productvariantlevel1_id = 'A96B15B6-7922-46BF-93BD-14C735991BB3'               
			THEN 'Warranty Booster'
            WHEN p.POL_Product_ID =  '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
                 AND p.pol_productvariantlevel1_id <> 'A96B15B6-7922-46BF-93BD-14C735991BB3'              
			THEN 'Warranty Non-Booster'
            WHEN p.POL_Product_ID =  '01A81AE2-8478-45FB-8C0D-5A6E796C1B39'                               
			THEN 'Tyre And Rim'
        END                                                       AS PRODUCT
    FROM       Policy             p
    LEFT JOIN  dbo.PolicyInsurerLink pil ON pil.PIL_Policy_ID = p.Policy_ID
                                             AND pil.PIL_Deleted = 0
    LEFT JOIN  dbo.Insurer         i   ON i.Insurer_Id = pil.PIL_Insurer_ID
    WHERE p.POL_Deleted = 0
),

/* =======================================================================================
   3. LATEST TERMINATION EVENT PER POLICY (Event 10516)
=========================================================================================*/
LatestTermEvent AS (
    SELECT
        e.EVL_ReferenceNumber AS Policy_ID,
        e.EVL_DateTime,
        e.EVL_Description,
        ROW_NUMBER() OVER (PARTITION BY e.EVL_ReferenceNumber
                           ORDER BY e.EVL_DateTime DESC) AS rn
    FROM EventLog e
    WHERE e.EVL_Event_ID = 10516          -- Termination / cancellation master event
),

LatestEvent AS (
    SELECT *
    FROM   LatestTermEvent
    WHERE  rn = 1                         -- keep only most-recent event per policy
),

/* =======================================================================================
   4. CANCELLED & EXPIRED POLICY SETS
=========================================================================================*/
Cancelled AS (
    SELECT Policy_ID,
           EOMONTH(EVL_DateTime) AS MonthEnd
    FROM   LatestEvent
    WHERE  EVL_Description IN ( 'Policy Cancelled','Cancelled - 2 Consecutive unmets','Cancelled by policyholder','CANCELLED BY POLICY HOLDER','Client request')
),

Expired AS (
    SELECT Policy_ID,
           EOMONTH(EVL_DateTime) AS MonthEnd
    FROM   LatestEvent
    WHERE  EVL_Description IN ('End of Term','Termination - End of Term')
),

/* =======================================================================================
   5. NEW BUSINESS (POL_SoldDate – plus pending/future)
=========================================================================================*/
NewBusiness AS (
    SELECT p.Policy_ID,
           DATEFROMPARTS(YEAR(p.POL_SoldDate),MONTH(p.POL_SoldDate),1) AS SoldMonth
    FROM   BasePolicies p
    WHERE  p.POL_SoldDate IS NOT NULL
      AND  p.POL_Status IN (1,4,8)                 -- Active, Pending, Future Active
)

/* =======================================================================================
   6. FINAL AGGREGATION
=========================================================================================*/
SELECT
    FORMAT(m.MonthStart,'yyyy-MM')                  AS [YEAR-MONTH],
    bp.PRODUCT                                      AS [PRODUCT],
    bp.INS_InsurerName                              AS [INSURER],

    /* ---------- ACTIVE COUNT (unchanged) ---------- */
    COUNT(DISTINCT CASE
        WHEN  (bp.POL_Status = 1
               OR (bp.POL_Status = 3
                   AND COALESCE(le.EVL_DateTime,'9999-12-31') > EOMONTH(m.MonthStart)))
          AND bp.POL_StartDate <= EOMONTH(m.MonthStart)
          AND (bp.POL_EndDate  IS NULL
               OR bp.POL_EndDate  >= m.MonthStart)
        THEN bp.POL_PolicyNumber
    END)                                            AS [ACTIVE COUNT],

    /* ---------- CANCELLED ---------- */
    COUNT(DISTINCT CASE
        WHEN c.MonthEnd = EOMONTH(m.MonthStart)
        THEN bp.POL_PolicyNumber
    END)                                            AS [CANCELLED COUNT],

    /* ---------- NEW BUSINESS ---------- */
    COUNT(DISTINCT CASE
        WHEN nb.SoldMonth = m.MonthStart
        THEN bp.POL_PolicyNumber
    END)                                            AS [NEW BUSINESS COUNT],

    /* ---------- EXPIRED ---------- */
    COUNT(DISTINCT CASE
        WHEN x.MonthEnd = EOMONTH(m.MonthStart)
        THEN bp.POL_PolicyNumber
    END)                                            AS [EXPIRED COUNT]

FROM       MonthRange  m
/* Every policy that is in-force at ANY time in this month */
JOIN       BasePolicies bp
       ON  bp.POL_StartDate <= EOMONTH(m.MonthStart)
       AND (bp.POL_EndDate IS NULL OR bp.POL_EndDate >= m.MonthStart)

/* bring in latest termination event once (for active-count logic) */
LEFT JOIN  LatestEvent  le  ON le.Policy_ID = bp.Policy_ID
/* join new sets for counting */
LEFT JOIN  Cancelled    c   ON c.Policy_ID = bp.Policy_ID
LEFT JOIN  Expired      x   ON x.Policy_ID = bp.Policy_ID
LEFT JOIN  NewBusiness  nb  ON nb.Policy_ID = bp.Policy_ID

GROUP BY
    FORMAT(m.MonthStart,'yyyy-MM'),
    bp.PRODUCT,
    bp.INS_InsurerName

ORDER BY
    [YEAR-MONTH], [PRODUCT], [INSURER]
OPTION (MAXRECURSION 0);
