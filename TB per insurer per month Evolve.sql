/* ==========================================================
   TB per Insurer per Month (by NAME) — includes ALL GLs
   De-duplicates multiple Insurer_IDs per name
   Conversion-safe (NVARCHAR) insurer join
   Safe to re-run (no temp tables)
   ========================================================== */

-- USE Evolve; -- uncomment if needed

DECLARE @StartDate     date          = '2025-01-01';   -- <-- change me
DECLARE @EndDate       date          = '2025-06-30';   -- <-- change me
DECLARE @InsurerName   nvarchar(200) = NULL;           -- e.g. N'Centriq Life' or NULL for all

-- Derived ranges
DECLARE @StartMonth      date = DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1);
DECLARE @EndMonth        date = DATEFROMPARTS(YEAR(@EndDate),   MONTH(@EndDate),   1);
DECLARE @EndDatePlus1 datetime2(0) = DATEADD(day, 1, CAST(@EndDate AS datetime2(0)));

-- 1) Build month list as a table variable (drives horizontal columns)
DECLARE @MonthList TABLE (MonthStart date PRIMARY KEY);
;WITH MonthList AS (
    SELECT @StartMonth AS MonthStart
    UNION ALL
    SELECT DATEADD(month, 1, MonthStart)
    FROM MonthList
    WHERE MonthStart < @EndMonth
)
INSERT INTO @MonthList(MonthStart)
SELECT MonthStart FROM MonthList
OPTION (MAXRECURSION 0);

-- 2) Dynamic column expressions for each month:
--    [YYYY-MM Amount] and [YYYY-MM Amount excl VAT]
DECLARE @colExpr nvarchar(max) = N'';
SELECT @colExpr = (
    SELECT
          ' ,CAST(COALESCE(SUM(CASE WHEN A.MonthStart = ''' + CONVERT(varchar(10), ml.MonthStart, 120) + ''' THEN A.Amount END),0.0) AS decimal(18,2)) AS [' + CONVERT(char(7), ml.MonthStart, 126) + ' Amount]'
        + ' ,CAST(COALESCE(SUM(CASE WHEN A.MonthStart = ''' + CONVERT(varchar(10), ml.MonthStart, 120) + ''' THEN A.AmountExVAT END),0.0) AS decimal(18,2)) AS [' + CONVERT(char(7), ml.MonthStart, 126) + ' Amount excl VAT]'
    FROM @MonthList AS ml
    ORDER BY ml.MonthStart
    FOR XML PATH(''), TYPE
).value('.', 'nvarchar(max)');

-- 3) Dynamic SQL (by-name grouping, full GL coverage, conversion-safe)
DECLARE @sql nvarchar(max) = N'
;WITH InsurerGroups AS
(
    /* Distinct insurer NAMES to group on.
       If a single @InsurerName is provided, only that name; else add an Unspecified bucket. */
    SELECT DISTINCT
        NormalizedName = LTRIM(RTRIM(I.INS_InsurerName)),
        DisplayName    = LTRIM(RTRIM(I.INS_InsurerName))
    FROM Insurer AS I
    WHERE @InsurerName IS NULL
       OR LTRIM(RTRIM(I.INS_InsurerName)) = LTRIM(RTRIM(@InsurerName))

    UNION ALL
    SELECT N''Unspecified'', N''Unspecified''
    WHERE @InsurerName IS NULL
),
GLDim AS
(
    /* One row per GL Code + GL Name. If your master has variants for the same code,
       switch to grouping by code only and pick MAX(name). */
    SELECT DISTINCT
        GLC_GlCode,
        GLC_Description
    FROM ReferenceGLCode
    WHERE GLC_GlCode IS NOT NULL
),
Driver AS
(
    /* Insurer-by-name × GL dimension: guarantees every GL appears,
       even when there are no transactions. */
    SELECT
        IG.DisplayName     AS InsurerName,
        IG.NormalizedName,
        G.GLC_GlCode,
        G.GLC_Description
    FROM InsurerGroups AS IG
    CROSS JOIN GLDim AS G
),
TxnAgg AS
(
    /* Aggregate actual transactions by (InsurerName × GL × Month).
       Join Insurer by casting IDs to NVARCHAR(50) to avoid GUID conversion issues.
       Bucket NULL/unknown names into ''Unspecified''. */
    SELECT
        InsurerName  = COALESCE(NULLIF(LTRIM(RTRIM(I.INS_InsurerName)), N''''), N''Unspecified''),
        R.GLC_GlCode,
        R.GLC_Description,
        MonthStart   = DATEFROMPARTS(YEAR(ed.EffDate), MONTH(ed.EffDate), 1),
        Amount       = SUM(ATN.ATN_GrossAmount),
        AmountExVAT  = SUM(ATN.ATN_GrossAmount - ATN.ATN_VATAmount)
    FROM AccountTransactionSet    AS ATS
    INNER JOIN AccountTransaction AS ATN
        ON ATN.ATN_AccountTransactionSet_ID = ATS.AccountTransactionSet_ID
    INNER JOIN ReferenceGLCode     AS R
        ON R.GlCode_ID = ATN.ATN_GLCode_ID
    LEFT  JOIN Insurer             AS I
        ON CAST(I.Insurer_Id AS nvarchar(50)) = CAST(ATS.ATS_Insurer_Id AS nvarchar(50))
    CROSS APPLY (SELECT IIF(ATS.ATS_CreateDate > ATS.ATS_EffectiveDate, ATS.ATS_CreateDate, ATS.ATS_EffectiveDate) AS EffDate) AS ed
    WHERE
        ed.EffDate >= @StartDate
        AND ed.EffDate <  @EndDatePlus1
        AND (@InsurerName IS NULL
             OR LTRIM(RTRIM(I.INS_InsurerName)) = LTRIM(RTRIM(@InsurerName)))
    GROUP BY
        COALESCE(NULLIF(LTRIM(RTRIM(I.INS_InsurerName)), N''''), N''Unspecified''),
        R.GLC_GlCode,
        R.GLC_Description,
        DATEFROMPARTS(YEAR(ed.EffDate), MONTH(ed.EffDate), 1)
)
SELECT
    D.InsurerName AS [Insurer Name],
    D.GLC_GlCode  AS [GL Code],
    D.GLC_Description AS [GL Name]' + @colExpr + '
FROM Driver AS D
LEFT JOIN TxnAgg AS A
    ON A.InsurerName      = D.NormalizedName
   AND A.GLC_GlCode       = D.GLC_GlCode
   AND A.GLC_Description  = D.GLC_Description
GROUP BY
    D.InsurerName, D.GLC_GlCode, D.GLC_Description
ORDER BY
    [Insurer Name], [GL Code], [GL Name];
';

EXEC sp_executesql
    @sql,
    N'@StartDate datetime2(0), @EndDatePlus1 datetime2(0), @InsurerName nvarchar(200)',
    @StartDate     = @StartDate,
    @EndDatePlus1  = @EndDatePlus1,
    @InsurerName   = @InsurerName;
