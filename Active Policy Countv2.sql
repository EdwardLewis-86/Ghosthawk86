USE Evolve
GO

DECLARE @StartDate DATE = '2023-01-01';
DECLARE @EndDate DATE = '2025-06-30';

-- Generate a list of months between @StartDate and @EndDate
WITH MonthRange AS (
    SELECT DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) AS MonthStart
    UNION ALL
    SELECT DATEADD(MONTH, 1, MonthStart)
    FROM MonthRange
    WHERE DATEADD(MONTH, 1, MonthStart) <= @EndDate
)

SELECT 
    FORMAT(m.MonthStart, 'yyyy-MM') AS [YEAR-MONTH],
    
    CASE
        WHEN Product_Id IN 
			('DDDC2DA4-881F-40B9-A156-8B7EA881863A'
			,'D0A30440-6F96-4735-A841-F601504BE51C'
			,'436BB1D0-CB35-4FF0-BD50-A316A08AE87B'
			,'70292F27-B7EE-4274-8B51-E345F4C1AD18'
			,'77C92C34-0CBB-4554-BD41-01F2D8F5FC11'
			,'86E44060-B546-4A65-9464-9C4F78C1681E') 
		THEN 'Adcover'
        
		WHEN Product_Id IN 
			('22D1B06F-BE25-4FA4-AAD4-447F13E13728'
			,'83A65AC4-37EC-4776-959D-99D46D0A2A10'
			,'DF78BA49-F342-4745-B3B9-39F21430EB24') 
		THEN 'Mobility Life Cover'
        
		WHEN Product_Id IN 
			('529AFE28-A2BF-4841-9B56-F334660C6CBD'
			,'A68AD927-C8B3-47A1-909E-785BDB017377'
			,'2374D1AA-B9EA-4015-8C5B-65F6C8EDC7C3'
			,'20AA9350-3FD9-4FE7-B705-3E1CCD639F94') 
		THEN 'Scratch and Dent'

        WHEN Product_Id IN 
			('A4AF17CF-89D0-47AC-A447-F135310042D7') 
		THEN 'Discovery Warranty'

        WHEN Product_Id IN 
			('1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB'
			,'5557806D-8733-458E-969A-9134F37C77D2'
			,'A80549F3-E47F-44C1-8037-F065522A03F6') 
		THEN 'Deposit Cover'

		WHEN Product_Id IN 
			('83C026A9-17FF-4A87-9CA9-E82C2535B538') 
		THEN 'Combo Product'

		WHEN Product_Id = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
             AND pol_productvariantlevel1_id = 'A96B15B6-7922-46BF-93BD-14C735991BB3'
        THEN 'Warranty Booster'
		
		WHEN Product_Id = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
             AND pol_productvariantlevel1_id <> 'A96B15B6-7922-46BF-93BD-14C735991BB3'
        THEN 'Warranty Non-Booster'
		
		WHEN Product_Id IN 
			('01A81AE2-8478-45FB-8C0D-5A6E796C1B39') 
		THEN 'Tyre and Rim'
    END AS [PRODUCT],

    CASE 
        WHEN LOWER(RCC_Description) LIKE '%wesb%' THEN 'Wesbank'
        WHEN LOWER(RCC_Description) LIKE '%- mot%' THEN 'AMH'
        WHEN LOWER(RCC_Description) LIKE '%- oem%' THEN 'Imperial'
        WHEN LOWER(RCC_Description) LIKE '%- apd%' THEN 'Auto Pedigree'
        WHEN LOWER(RCC_Description) = 'motus' THEN 'AMH'
        ELSE RCC_Description
    END AS [REPORTING GROUP],

    -- Insurer logic (from PolicyInsurerLink and Insurer)
    ISNULL(ins.INS_InsurerName, 'Unknown') AS [INSURER],


    COUNT(DISTINCT CASE WHEN POL_Status = 1 AND POL_StartDate <= EOMONTH(m.MonthStart) AND (POL_EndDate IS NULL OR POL_EndDate >= m.MonthStart) THEN POL_PolicyNumber END) AS [ACTIVE COUNT],

    COUNT(DISTINCT CASE WHEN POL_Status = 3 AND POL_EndDate BETWEEN m.MonthStart AND EOMONTH(m.MonthStart) THEN POL_PolicyNumber END) AS [CANCELLED COUNT]


FROM MonthRange m
JOIN Policy ON 
    POL_Deleted = 0 AND
    POL_StartDate <= EOMONTH(m.MonthStart) AND
    (POL_EndDate IS NULL OR POL_EndDate >= m.MonthStart)

LEFT JOIN Product 
    ON POL_Product_ID = Product_Id

LEFT JOIN vw_PolicySetDetails 
    ON PolicyId = Policy_ID

LEFT JOIN ReferenceCellCaptive 
    ON ReferenceCellCaptive_Code = CellCaptiveId

LEFT JOIN dbo.PolicyInsurerLink pil 
    ON Policy.Policy_ID = pil.PIL_Policy_ID 
    AND pil.PIL_Deleted = 0

LEFT JOIN dbo.Insurer ins 
    ON pil.PIL_Insurer_ID = ins.Insurer_Id

GROUP BY 
    FORMAT(m.MonthStart, 'yyyy-MM'),
    CASE
        WHEN Product_Id IN 
			('DDDC2DA4-881F-40B9-A156-8B7EA881863A'
			,'D0A30440-6F96-4735-A841-F601504BE51C'
			,'436BB1D0-CB35-4FF0-BD50-A316A08AE87B'
			,'70292F27-B7EE-4274-8B51-E345F4C1AD18'
			,'77C92C34-0CBB-4554-BD41-01F2D8F5FC11'
			,'86E44060-B546-4A65-9464-9C4F78C1681E') 
		THEN 'Adcover'
        
		WHEN Product_Id IN 
			('22D1B06F-BE25-4FA4-AAD4-447F13E13728'
			,'83A65AC4-37EC-4776-959D-99D46D0A2A10'
			,'DF78BA49-F342-4745-B3B9-39F21430EB24') 
		THEN 'Mobility Life Cover'
        
		WHEN Product_Id IN 
			('529AFE28-A2BF-4841-9B56-F334660C6CBD'
			,'A68AD927-C8B3-47A1-909E-785BDB017377'
			,'2374D1AA-B9EA-4015-8C5B-65F6C8EDC7C3'
			,'20AA9350-3FD9-4FE7-B705-3E1CCD639F94') 
		THEN 'Scratch and Dent'

        WHEN Product_Id IN 
			('A4AF17CF-89D0-47AC-A447-F135310042D7') 
		THEN 'Discovery Warranty'

        WHEN Product_Id IN 
			('1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB'
			,'5557806D-8733-458E-969A-9134F37C77D2'
			,'A80549F3-E47F-44C1-8037-F065522A03F6') 
		THEN 'Deposit Cover'

		WHEN Product_Id IN 
			('83C026A9-17FF-4A87-9CA9-E82C2535B538') 
		THEN 'Combo Product'

		WHEN Product_Id = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
             AND pol_productvariantlevel1_id = 'A96B15B6-7922-46BF-93BD-14C735991BB3'
        THEN 'Warranty Booster'
		
		WHEN Product_Id = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF'
             AND pol_productvariantlevel1_id <> 'A96B15B6-7922-46BF-93BD-14C735991BB3'
        THEN 'Warranty Non-Booster'
		
		WHEN Product_Id IN 
			('01A81AE2-8478-45FB-8C0D-5A6E796C1B39') 
		THEN 'Tyre and Rim'
	END,
    CASE 
        WHEN LOWER(RCC_Description) LIKE '%wesb%' THEN 'Wesbank'
        WHEN LOWER(RCC_Description) LIKE '%- mot%' THEN 'AMH'
        WHEN LOWER(RCC_Description) LIKE '%- oem%' THEN 'Imperial'
        WHEN LOWER(RCC_Description) LIKE '%- apd%' THEN 'Auto Pedigree'
        WHEN LOWER(RCC_Description) = 'motus' THEN 'AMH'
        ELSE RCC_Description
    END,

	ISNULL(ins.INS_InsurerName, 'Unknown')

ORDER BY 
    FORMAT(m.MonthStart, 'yyyy-MM'),
    [PRODUCT],
    [REPORTING GROUP]

OPTION (MAXRECURSION 1000);
