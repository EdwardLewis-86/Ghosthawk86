-- Generate UPP run-off by month
WITH PolicyData AS (
    SELECT 
       *,
        Term - ElapsedMonths AS RemainingMonths
    FROM [UPP].[dbo].[SAW_UPP_202510]
    WHERE 1= 1-- pol_policynumber = 'QWTYM224482POL'
      AND UPP > 0
),
-- Generate month offsets up to max 120 (adjust if needed)
Numbers AS (
    SELECT TOP 120 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.all_objects
),
RunOffPlan AS (
    SELECT 
         p.[ProductClass],
		 p.[INS_InsurerName],
		 p.[CellCaptive],
        DATEADD(MONTH, n.n - 1, p.ValuationMonth) AS RunOffMonth,
        ROUND(p.[UPP] / NULLIF(p.RemainingMonths, 0), 6) AS [UPP],
		  ROUND(p.DAC / NULLIF(p.RemainingMonths, 0), 6) AS [DAC],
		    ROUND(p.[BinderUPP] / NULLIF(p.RemainingMonths, 0), 6) AS [BinderUPP],
		 ROUND(p.[RoadsideUPP] / NULLIF(p.RemainingMonths, 0), 6) AS	[RoadsideUPP]
    FROM PolicyData p
    JOIN Numbers n ON n.n <= p.RemainingMonths
)
SELECT
[ProductClass],
		 [INS_InsurerName],
		 [CellCaptive],
		 CAST([RunOffMonth] AS DATE) AS [RunOffMonth],
SUM([UPP]) AS [UPP],
SUM([DAC]) AS [DAC],
SUM([BinderUPP]) AS [BinderUPP],
SUM([RoadsideUPP]) AS [RoadsideUPP]
FROM RunOffPlan
WHERE 1 = 1
GROUP BY 
[ProductClass],
		 [INS_InsurerName],
		 [CellCaptive],
		 CAST([RunOffMonth] AS DATE)
ORDER BY [RunOffMonth];