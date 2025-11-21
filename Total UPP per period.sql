/* UPP total by month using an explicit allow-list of tables, plus class splits */
USE [UPP];
GO
SET NOCOUNT ON;

DECLARE @sql nvarchar(MAX);

/* 1) Hard-list exactly which table to use for each month */
DECLARE @AllowList TABLE (
    schema_name sysname NOT NULL,
    table_name  sysname NOT NULL,
    yyyymm      char(6) NOT NULL PRIMARY KEY
);

INSERT INTO @AllowList (schema_name, table_name, yyyymm) VALUES
-- 2023
('dbo','SAW_UPP_202308','202308'),
('dbo','SAW_UPP_202309','202309'),
('dbo','SAW_UPP_202310','202310'),
('dbo','SAW_UPP_202311','202311'),
('dbo','SAW_UPP_202312','202312'),
-- 2024
('dbo','SAW_UPP_202401','202401'),
('dbo','SAW_UPP_202402','202402'),
('dbo','SAW_UPP_202403','202403'),
('dbo','SAW_UPP_202404','202404'),
('dbo','SAW_UPP_202405','202405'),
('dbo','SAW_UPP_202406','202406'),
('dbo','SAW_UPP_202407','202407'),
('dbo','SAW_UPP_202408','202408'),
('dbo','SAW_UPP_202409','202409'),
('dbo','SAW_UPP_202410','202410'),
('dbo','SAW_UPP_202411','202411'),
('dbo','SAW_UPP_202412','202412'),
-- 2025
('dbo','SAW_UPP_202501','202501'),
('dbo','SAW_UPP_202502','202502'),
('dbo','SAW_UPP_202503','202503'),
('dbo','SAW_UPP_202504','202504'),
('dbo','SAW_UPP_202505','202505'),
('dbo','SAW_UPP_202506_Test','202506'),
('dbo','SAW_UPP_202507_Test_2','202507');

/* 2) Validate existence */
IF OBJECT_ID('tempdb..#existing') IS NOT NULL DROP TABLE #existing;
SELECT a.schema_name, a.table_name, a.yyyymm
INTO #existing
FROM @AllowList a
JOIN sys.schemas s ON s.name = a.schema_name
JOIN sys.tables  t ON t.name = a.table_name AND t.schema_id = s.schema_id;

IF NOT EXISTS (SELECT 1 FROM #existing)
BEGIN
    RAISERROR('Allow-list produced no existing tables.', 16, 1);
    RETURN;
END

IF OBJECT_ID('tempdb..#missing') IS NOT NULL DROP TABLE #missing;
SELECT a.schema_name + '.' + a.table_name AS fqtn
INTO #missing
FROM @AllowList a
EXCEPT
SELECT e.schema_name + '.' + e.table_name FROM #existing e;

IF EXISTS (SELECT 1 FROM #missing)
BEGIN
    DECLARE @msg nvarchar(MAX) =
        N'Missing table(s) from allow-list: ' +
        STUFF((
            SELECT N', ' + m.fqtn
            FROM #missing m
            FOR XML PATH(''), TYPE
        ).value('.','nvarchar(max)'), 1, 2, N'');
    RAISERROR(@msg, 16, 1);
    RETURN;
END

/* 3) Build UNION ALL across the allow-listed tables (MAX-safe) */
SET @sql =
    N'SELECT [Month],
             [Total UPP],
             [Total Warranties],
             [Total Tyre and Rim]
FROM (
' + STUFF((
      SELECT
          NCHAR(10) + N'    UNION ALL' + NCHAR(10) +
          N'    SELECT ''' + LEFT(e.yyyymm,4) + N'-' + RIGHT(e.yyyymm,2) + N''' AS [Month],
                   COALESCE(SUM(TRY_CONVERT(decimal(38,2), [UPP])), 0) AS [Total UPP],
                   SUM(CASE WHEN [ProductClass] = N''Warranty''
                            THEN COALESCE(TRY_CONVERT(decimal(38,2), [UPP]),0)
                            ELSE 0 END) AS [Total Warranties],
                   SUM(CASE WHEN [ProductClass] = N''Tyre and Rim''
                            THEN COALESCE(TRY_CONVERT(decimal(38,2), [UPP]),0)
                            ELSE 0 END) AS [Total Tyre and Rim]
            FROM ' + QUOTENAME(e.schema_name) + N'.' + QUOTENAME(e.table_name)
      FROM #existing e
      ORDER BY e.yyyymm
      FOR XML PATH(''), TYPE
).value('.','nvarchar(max)'), 1, LEN(NCHAR(10) + N'    UNION ALL' + NCHAR(10)), N'')
+ N'
) AS x
ORDER BY [Month];';

/* 4) Execute once */
EXEC sys.sp_executesql @sql;
