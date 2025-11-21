-- =====================================================
-- MASTER SCRIPT - UPP MONTHLY ROLL FORWARD
-- Run this script once per month
-- =====================================================
-- INSTRUCTIONS:
-- 1. Update the parameters in STEP 1 below
-- 2. Press F5 to execute the entire script
-- 3. Wait for completion (approximately 60 minutes)
-- 4. Review the output for any errors
-- =====================================================

USE UPP;
GO

-- =====================================================
-- STEP 1: SET YOUR PARAMETERS HERE (ONLY PLACE TO EDIT)
-- =====================================================
DECLARE @ValuationMonth DATE = '2025-07-31';  -- CHANGE THIS EACH MONTH
DECLARE @OutputTable1 VARCHAR(100) = 'SAW_UPP_202507_NonBooster_TEST_LM';  -- CHANGE THIS EACH MONTH
DECLARE @OutputTable2 VARCHAR(100) = 'SAW_UPP_202507_Booster_TEST_LM';     -- CHANGE THIS EACH MONTH
DECLARE @OutputTableFinal VARCHAR(100) = 'SAW_UPP_202507_TEST_LM';          -- CHANGE THIS EACH MONTH

-- Constants (usually don't change)
DECLARE @Commission FLOAT = 0.125;
DECLARE @ClaimsBinder FLOAT = 4 * 1.0000000 / 9;
DECLARE @Binder FLOAT = 0.09;

-- Track overall execution time
DECLARE @OverallStartTime DATETIME = GETDATE();
DECLARE @StepStartTime DATETIME;

PRINT '';
PRINT '========================================';
PRINT '  UPP MONTHLY ROLL FORWARD PROCESS';
PRINT '========================================';
PRINT 'Valuation Month: ' + CONVERT(VARCHAR, @ValuationMonth, 120);
PRINT 'Run Date: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '========================================';
PRINT '';

-- =====================================================
-- STEP 2: RUN NON-BOOSTER STORED PROCEDURE
-- =====================================================
PRINT '';
PRINT 'STEP 2: Running Non-Booster Script...';
SET @StepStartTime = GETDATE();
PRINT 'Start Time: ' + CONVERT(VARCHAR, @StepStartTime, 120);

EXEC dbo.sp_RunWarrantyUPPNonBooster 
    @ValuationMonth = @ValuationMonth,
    @Commission = @Commission,
    @ClaimsBinder = @ClaimsBinder,
    @Binder = @Binder,
    @OutputTableName = @OutputTable1;

PRINT 'Non-Booster Complete: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT 'Duration: ' + CAST(DATEDIFF(MINUTE, @StepStartTime, GETDATE()) AS VARCHAR) + ' minutes';
PRINT '';

-- =====================================================
-- STEP 3: RUN BOOSTER STORED PROCEDURE
-- =====================================================
PRINT '';
PRINT 'STEP 3: Running Booster Script...';
SET @StepStartTime = GETDATE();
PRINT 'Start Time: ' + CONVERT(VARCHAR, @StepStartTime, 120);

EXEC dbo.sp_RunWarrantyUPPBooster 
    @ValuationMonth = @ValuationMonth,
    @Commission = @Commission,
    @ClaimsBinder = @ClaimsBinder,
    @Binder = @Binder,
    @OutputTableName = @OutputTable2;

PRINT 'Booster Complete: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT 'Duration: ' + CAST(DATEDIFF(MINUTE, @StepStartTime, GETDATE()) AS VARCHAR) + ' minutes';
PRINT '';

-- =====================================================
-- STEP 4: MERGE TABLES
-- =====================================================
PRINT '';
PRINT 'STEP 4: Merging Tables...';
SET @StepStartTime = GETDATE();
PRINT 'Start Time: ' + CONVERT(VARCHAR, @StepStartTime, 120);

-- Drop final table if it exists
DECLARE @DropSQL NVARCHAR(500);
SET @DropSQL = N'DROP TABLE IF EXISTS [UPP].[dbo].[' + @OutputTableFinal + N'];';
EXEC sp_executesql @DropSQL;

-- Merge the two tables
DECLARE @MergeSQL NVARCHAR(MAX);
SET @MergeSQL = N'
WITH a AS (
    SELECT * FROM [UPP].[dbo].[' + @OutputTable1 + N']
    UNION
    SELECT * FROM [UPP].[dbo].[' + @OutputTable2 + N']
)
SELECT * INTO [UPP].[dbo].[' + @OutputTableFinal + N'] FROM a;';

EXEC sp_executesql @MergeSQL;

PRINT 'Merge Complete: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
PRINT '';

-- =====================================================
-- STEP 5: CHECK AND REMOVE DUPLICATES
-- =====================================================
PRINT '';
PRINT 'STEP 5: Checking and Removing Duplicates...';
SET @StepStartTime = GETDATE();
PRINT 'Start Time: ' + CONVERT(VARCHAR, @StepStartTime, 120);

DECLARE @DuplicateSQL NVARCHAR(MAX);
SET @DuplicateSQL = N'
WITH CTE_Duplicates AS (
    SELECT
        Policy_ID,
        POL_PolicyNumber,
        ROW_NUMBER() OVER (
            PARTITION BY POL_PolicyNumber, ValuationMonth
            ORDER BY POL_CreateDate DESC
        ) AS RN
    FROM [UPP].[dbo].[' + @OutputTableFinal + N']
)
DELETE FROM CTE_Duplicates WHERE RN > 1;';

EXEC sp_executesql @DuplicateSQL;

DECLARE @DeletedRows INT = @@ROWCOUNT;
PRINT 'Duplicates Removed: ' + CAST(@DeletedRows AS VARCHAR);
PRINT 'Duplicate Check Complete: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
PRINT '';

-- =====================================================
-- STEP 6: FINAL VERIFICATION
-- =====================================================
PRINT '';
PRINT '========================================';
PRINT '  FINAL VERIFICATION';
PRINT '========================================';

DECLARE @Count1 INT, @Count2 INT, @CountFinal INT;
DECLARE @CountSQL NVARCHAR(500);

-- Count Non-Booster records
SET @CountSQL = N'SELECT @Count = COUNT(*) FROM [UPP].[dbo].[' + @OutputTable1 + N'];';
EXEC sp_executesql @CountSQL, N'@Count INT OUTPUT', @Count = @Count1 OUTPUT;

-- Count Booster records
SET @CountSQL = N'SELECT @Count = COUNT(*) FROM [UPP].[dbo].[' + @OutputTable2 + N'];';
EXEC sp_executesql @CountSQL, N'@Count INT OUTPUT', @Count = @Count2 OUTPUT;

-- Count Final merged records
SET @CountSQL = N'SELECT @Count = COUNT(*) FROM [UPP].[dbo].[' + @OutputTableFinal + N'];';
EXEC sp_executesql @CountSQL, N'@Count INT OUTPUT', @Count = @CountFinal OUTPUT;

PRINT 'Non-Booster Records: ' + CAST(@Count1 AS VARCHAR);
PRINT 'Booster Records: ' + CAST(@Count2 AS VARCHAR);
PRINT 'Final Merged Records: ' + CAST(@CountFinal AS VARCHAR);
PRINT 'Duplicates Removed: ' + CAST(@DeletedRows AS VARCHAR);
PRINT '';
PRINT 'Expected Total: ' + CAST((@Count1 + @Count2) AS VARCHAR);
PRINT 'Match Status: ' + CASE 
    WHEN @CountFinal = (@Count1 + @Count2 - @DeletedRows) THEN 'YES ✓ (After removing duplicates)' 
    WHEN @CountFinal = (@Count1 + @Count2) THEN 'YES ✓ (Perfect match - no duplicates)'
    ELSE 'NO ✗ - CHECK FOR ISSUES' 
END;

DECLARE @TotalDuration INT = DATEDIFF(MINUTE, @OverallStartTime, GETDATE());

PRINT '';
PRINT '========================================';
PRINT '  PROCESS COMPLETE';
PRINT '========================================';
PRINT 'End Time: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT 'Total Duration: ' + CAST(@TotalDuration / 60 AS VARCHAR) + ' hours ' + CAST(@TotalDuration % 60 AS VARCHAR) + ' minutes';
PRINT '';
PRINT 'Output Tables Created:';
PRINT '  - ' + @OutputTable1;
PRINT '  - ' + @OutputTable2;
PRINT '  - ' + @OutputTableFinal;
PRINT '========================================';
PRINT '';
GO