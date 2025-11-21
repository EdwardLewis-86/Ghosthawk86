-- Run on EVPRODREP01
USE [RB_Analysis]
GO

-- Clear all data from the target table (keeps table structure)
DELETE FROM [MS-ACT01].[lpp].[dbo].[Balloons]

-- Then insert fresh data
INSERT INTO [MS-ACT01].[lpp].[dbo].[Balloons]
SELECT * FROM [RB_Analysis].[dbo].[vw_Credit_Life_RV_Values]
