----EVPRODREP01

Use RB_Analysis
GO

/* Pivot: In-force policy counts by month (columns)
   Rows: Insurer_Name, Arrangement_Cell_Captive, PRD_Name (with Booster rename rule)
*/
DECLARE @cols nvarchar(max);
DECLARE @sql  nvarchar(max);

/* 1) Build the month column list dynamically from in-force rows */
SELECT @cols = STUFF((
    SELECT ',' + QUOTENAME(CAST(s.Measurement_Month AS varchar(6)))
    FROM (
        SELECT DISTINCT Measurement_Month
        FROM dbo.Evolve_policy_Month_end_Snapshot
        WHERE Policy_Status = 'In Force' AND Measurement_Month IS NOT NULL
    ) s
    ORDER BY s.Measurement_Month
    FOR XML PATH(''), TYPE
).value('.','nvarchar(max)'), 1, 1, '');

/* If no months were found, return an empty, typed result set */
IF (@cols IS NULL OR LEN(@cols) = 0)
BEGIN
    SELECT
        CAST(NULL AS nvarchar(200)) AS Insurer_Name,
        CAST(NULL AS nvarchar(200)) AS Arrangement_Cell_Captive,
        CAST(NULL AS nvarchar(200)) AS PRD_Name
    WHERE 1 = 0;
    RETURN;
END

/* 2) Dynamic pivot over the pre-aggregated counts */
SET @sql = N'
WITH base AS (
    SELECT
        epm.Insurer_Name,
        epm.Arrangement_Cell_Captive,
        /* Rename Warranty -> Warranty Booster when Product_Variant contains Booster */
        CASE
            WHEN epm.PRD_Name = ''Warranty''
                 AND epm.Product_Variant LIKE ''%Booster%''
            THEN ''Warranty Booster''
            ELSE epm.PRD_Name
        END AS PRD_Name_Mapped,
        CAST(epm.Measurement_Month AS varchar(6)) AS Measurement_Month,
        epm.POL_PolicyNumber
    FROM dbo.Evolve_policy_Month_end_Snapshot epm
    WHERE epm.Policy_Status = ''In Force''
      AND epm.Measurement_Month IS NOT NULL
)
, agg AS (
    SELECT
        b.Insurer_Name,
        b.Arrangement_Cell_Captive,
        b.PRD_Name_Mapped,
        b.Measurement_Month,
        COUNT(DISTINCT b.POL_PolicyNumber) AS Policy_Count
    FROM base b
    GROUP BY
        b.Insurer_Name,
        b.Arrangement_Cell_Captive,
        b.PRD_Name_Mapped,
        b.Measurement_Month
)
SELECT
    Insurer_Name,
    Arrangement_Cell_Captive,
    PRD_Name_Mapped AS PRD_Name,
    ' + @cols + N'
FROM agg
PIVOT(
    SUM(Policy_Count)
    FOR Measurement_Month IN (' + @cols + N')
) p
ORDER BY
    Insurer_Name,
    Arrangement_Cell_Captive,
    PRD_Name;';

EXEC sys.sp_executesql @sql;
