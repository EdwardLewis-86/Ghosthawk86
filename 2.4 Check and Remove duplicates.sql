-- Execution Time { 00:00 }
-- ON THE UPP DATABASE
-- DATE 02-09-2025

WITH CTE_Duplicates AS (
    SELECT
        Policy_ID,  -- Primary key
        POL_PolicyNumber,
        
        -- Add any other columns that define a duplicate record
        ROW_NUMBER() OVER (
            PARTITION BY POL_PolicyNumber, ValuationMonth
            ORDER BY POL_CreateDate DESC  -- Keep the latest by CreateDate, or choose your criteria
        ) AS RN
    FROM
        [UPP].[dbo].[SAW_UPP_202509]  --No duplicates found
)

-- Delete only rows that are duplicates (RN > 1)
DELETE FROM CTE_Duplicates
WHERE RN > 1;

-- ========================================================
-- Verify that duplicates are removed:
-- ========================================================
-- SELECT POL_PolicyNumber, ValuationMonth, COUNT(*) 
-- FROM [UPP].[dbo].[SAW_UPP_202507_Test]
-- GROUP BY POL_PolicyNumber, ValuationMonth
-- HAVING COUNT(*) > 1;
