-- Execution Time { 00:06 }
-- ON THE UPP DATABASE
-- DATE 01-09-2025


WITH a as (
SELECT * FROM [UPP].[dbo].[SAW_UPP_202509_NonBooster_TEST]
UNION
SELECT * FROM  [UPP].[dbo].[SAW_UPP_202509_Booster_Test]
  )
SELECT *  Into [UPP].[dbo].[SAW_UPP_202509_TEST] FROM a