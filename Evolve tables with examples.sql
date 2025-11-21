/* Unified output: first column = fully-qualified table name; one row per source row, as JSON
   - Scans all ONLINE user DBs whose name matches @DatabaseNamePattern.
   - Takes TOP (@TopN) per table, ordered by the first column asc when feasible.
   - Puts ALL rows in one temp table, then returns a single result set.
*/

SET NOCOUNT ON;

DECLARE @DatabaseNamePattern sysname = N'%Evolve%';
DECLARE @TopN               int     = 50;

IF OBJECT_ID('tempdb..#Evolve_AllRows') IS NOT NULL DROP TABLE #Evolve_AllRows;
CREATE TABLE #Evolve_AllRows
(
    TableName sysname       NOT NULL,  -- first column: [db].[schema].[table]
    RowJson   nvarchar(max) NOT NULL   -- JSON of the row values
);

IF OBJECT_ID('tempdb..#ToProcess') IS NOT NULL DROP TABLE #ToProcess;
CREATE TABLE #ToProcess
(
    DatabaseName sysname NOT NULL,
    SchemaName   sysname NOT NULL,
    TableName    sysname NOT NULL,
    FirstColName sysname NOT NULL,
    TypeName     sysname NOT NULL,
    Orderable    bit     NOT NULL,     -- 1 = can ORDER BY the first column
    NeedsConvert bit     NOT NULL      -- 1 = must CONVERT first col to NVARCHAR for ORDER BY
);

DECLARE @db sysname;

-- Gather candidate databases
DECLARE dbcur CURSOR LOCAL FAST_FORWARD FOR
SELECT name
FROM sys.databases
WHERE name LIKE @DatabaseNamePattern ESCAPE '\'
  AND state_desc = 'ONLINE'
  AND database_id > 4;  -- skip system DBs

OPEN dbcur;
FETCH NEXT FROM dbcur INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Populate #ToProcess from this database's metadata (single dynamic INSERT)
    DECLARE @meta nvarchar(MAX) = N'
        INSERT INTO #ToProcess (DatabaseName, SchemaName, TableName, FirstColName, TypeName, Orderable, NeedsConvert)
        SELECT
            N' + QUOTENAME(REPLACE(@db, '''', ''''''), '''') + N',
            s.name,
            t.name,
            c.name,
            ty.name,
            CASE WHEN ty.name IN (''image'',''hierarchyid'',''geography'',''geometry'',''sql_variant'') THEN 0 ELSE 1 END,
            CASE WHEN ty.name IN (''text'',''ntext'',''xml'') THEN 1 ELSE 0 END
        FROM ' + QUOTENAME(@db) + N'.sys.tables  AS t
        JOIN ' + QUOTENAME(@db) + N'.sys.schemas AS s  ON s.schema_id = t.schema_id
        JOIN ' + QUOTENAME(@db) + N'.sys.columns AS c  ON c.object_id = t.object_id AND c.column_id = 1
        JOIN ' + QUOTENAME(@db) + N'.sys.types   AS ty ON ty.user_type_id = c.user_type_id
        WHERE t.is_ms_shipped = 0;
    ';
    EXEC sys.sp_executesql @meta;

    FETCH NEXT FROM dbcur INTO @db;
END
CLOSE dbcur;
DEALLOCATE dbcur;

-- Now iterate all tables and pull TOP (@TopN) rows into the unified output
DECLARE @SchemaName   sysname,
        @TableName    sysname,
        @FirstColName sysname,
        @TypeName     sysname,
        @Orderable    bit,
        @NeedsConvert bit;

DECLARE tcur CURSOR LOCAL FAST_FORWARD FOR
SELECT DatabaseName, SchemaName, TableName, FirstColName, TypeName, Orderable, NeedsConvert
FROM #ToProcess
ORDER BY DatabaseName, SchemaName, TableName;

OPEN tcur;
FETCH NEXT FROM tcur INTO @db, @SchemaName, @TableName, @FirstColName, @TypeName, @Orderable, @NeedsConvert;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @QualifiedTable  nvarchar(776) = QUOTENAME(@db) + N'.' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName);
    DECLARE @OrderBy         nvarchar(MAX) = N'';
    IF @Orderable = 1
    BEGIN
        IF @NeedsConvert = 1
            SET @OrderBy = N' ORDER BY CONVERT(NVARCHAR(4000), ' + QUOTENAME(@FirstColName) + N') ASC';
        ELSE
            SET @OrderBy = N' ORDER BY ' + QUOTENAME(@FirstColName) + N' ASC';
    END

    DECLARE @q nvarchar(MAX) =
    N'INSERT INTO #Evolve_AllRows (TableName, RowJson)
      SELECT @TableName,
             j.RowData
      FROM (
            SELECT TOP (@TopN) *
            FROM ' + @QualifiedTable + N'
            ' + @OrderBy + N'
      ) AS t
      CROSS APPLY (SELECT t.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS j(RowData);';

    EXEC sys.sp_executesql
        @q,
        N'@TopN int, @TableName sysname',
        @TopN = @TopN,
        @TableName = @QualifiedTable;

    FETCH NEXT FROM tcur INTO @db, @SchemaName, @TableName, @FirstColName, @TypeName, @Orderable, @NeedsConvert;
END

CLOSE tcur;
DEALLOCATE tcur;

-- Final single result set (first column is the table name)
SELECT TableName, RowJson
FROM #Evolve_AllRows
ORDER BY TableName;
