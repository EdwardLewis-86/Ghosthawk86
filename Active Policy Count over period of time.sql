-- Create faster calendar CTE with month-end dates from 2023-07-31 to 2025-05-31

Use [Evolve]
Go

DECLARE @StartDate DATE = '2023-07-31';
DECLARE @MonthEnd DATE = '2025-06-30';

IF OBJECT_ID('tempdb..#Results') IS NOT NULL DROP TABLE #Results;

WITH Calendar AS (
    SELECT CAST(@StartDate AS DATE) AS MthEnd
    UNION ALL
    SELECT EOMONTH(DATEADD(MONTH, 1, MthEnd))
    FROM Calendar
    WHERE MthEnd < @MonthEnd
)

-- Main CTE with policy and event data
, CTE_Main AS (
SELECT 
    100 * YEAR(c.MthEnd) + MONTH(c.MthEnd) AS Mth,
    pr.PRD_Name AS Product,
    ins.INS_InsurerName AS Insurer_Name,
    e.EVL_Event_ID,
    p.Policy_ID,
    p.POL_PolicyNumber,
    p.POL_Status,
    p.POL_OriginalStartDate,
    e.EVL_DateTime
FROM Calendar c
INNER JOIN dbo.Policy p
    ON p.POL_OriginalStartDate < c.MthEnd
LEFT JOIN dbo.Product pr 
    ON p.POL_Product_ID = pr.Product_Id
LEFT JOIN dbo.PolicyInsurerLink pil 
    ON p.Policy_ID = pil.PIL_Policy_ID 
    AND pil.PIL_Deleted = 0
LEFT JOIN dbo.Insurer ins 
    ON pil.PIL_Insurer_ID = ins.Insurer_Id
LEFT JOIN dbo.EventLog e 
    ON e.EVL_ReferenceNumber = p.Policy_ID
    AND e.EVL_Event_ID IN (10514, 10733, 10292, 10516, 10515, 10294)
WHERE p.POL_Deleted = 0
  AND p.POL_ReceivedDate <= c.MthEnd
)

-- Insert results
SELECT 
    Mth,
    Product,
    Insurer_Name,
	SUM(CASE WHEN EVL_Event_ID = 10292 THEN 1 ELSE 0 END) AS [Policy Created],
	SUM(CASE WHEN EVL_Event_ID = 10294 THEN 1 ELSE 0 END) AS [Policy Deleted],
	SUM(CASE WHEN EVL_Event_ID = 10514 THEN 1 ELSE 0 END) AS [Policy Accepted], 
	SUM(CASE WHEN EVL_Event_ID = 10515 THEN 1 ELSE 0 END) AS [Policy NTU],
	SUM(CASE WHEN EVL_Event_ID = 10516 THEN 1 ELSE 0 END) AS [Policy Cancelled],
	SUM(CASE WHEN EVL_Event_ID = 10733 THEN 1 ELSE 0 END) AS [Policy Reinstated],
	COUNT(DISTINCT Policy_ID) AS [Policy Count],
    SUM(CASE 
            WHEN EVL_Event_ID = 10516 AND EVL_DateTime <= CAST(CONCAT(Mth/100, '-', RIGHT('00' + CAST(Mth % 100 AS VARCHAR), 2), '-01') AS DATE) THEN 1
            WHEN POL_Status = 0 AND POL_OriginalStartDate < CAST(CONCAT(Mth/100, '-', RIGHT('00' + CAST(Mth % 100 AS VARCHAR), 2), '-01') AS DATE) THEN 1
            ELSE 0
        END) AS Exits
INTO #Results
FROM CTE_Main
GROUP BY 
    Mth,
    Product,
    Insurer_Name
OPTION (MAXRECURSION 1000);

-- Final output
SELECT *
FROM #Results
--WHERE Insurer_Name <> Null
ORDER BY Mth, Product, Insurer_Name;

-- Debug output: Policies without Insurer Name
WITH DebugCalendar AS (
    SELECT CAST(@StartDate AS DATE) AS MthEnd
    UNION ALL
    SELECT EOMONTH(DATEADD(MONTH, 1, MthEnd))
    FROM DebugCalendar
    WHERE MthEnd < @MonthEnd
),
CTE_Debug AS (
SELECT 
    100 * YEAR(c.MthEnd) + MONTH(c.MthEnd) AS Mth,
    p.Policy_ID,
    p.POL_PolicyNumber,
    pr.PRD_Name AS Product,
    pil.PIL_Policy_ID,
    pil.PIL_Insurer_ID,
    ins.INS_InsurerName
FROM DebugCalendar c
INNER JOIN dbo.Policy p
    ON p.POL_OriginalStartDate < c.MthEnd
LEFT JOIN dbo.Product pr 
    ON p.POL_Product_ID = pr.Product_Id
LEFT JOIN dbo.PolicyInsurerLink pil 
    ON p.Policy_ID = pil.PIL_Policy_ID 
    AND pil.PIL_Deleted = 0
LEFT JOIN dbo.Insurer ins 
    ON pil.PIL_Insurer_ID = ins.Insurer_Id
WHERE p.POL_Deleted = 0
  AND p.POL_ReceivedDate <= c.MthEnd
  AND ins.INS_InsurerName IS NULL
)
SELECT *
FROM CTE_Debug
ORDER BY Mth, Product, POL_PolicyNumber

