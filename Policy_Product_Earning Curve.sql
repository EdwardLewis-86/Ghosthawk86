/*------------------------------------------
Returns the earning curve over period of time
Returns the shortened version of the policy info records
---------------------------------------------*/

USE Evolve;
GO

SELECT 
    *
FROM (
    SELECT 
       	DCH.DCH_Name,
        DCI.DCI_Month,
        DCI.DCI_MonthlyPercentage
    FROM [Evolve].[dbo].[DisbursementCurveItem] AS DCI
    INNER JOIN [Evolve].[dbo].[DisbursementCurveHeader] AS DCH
        ON DCI.DCI_DisbursementCurveHeader_Id = DCH.DisbursementCurveHeader_Id
    WHERE 
        DCH.DCH_Deleted = 0 
        AND DCI.DCI_Deleted = 0
        --AND DCH.DCH_Name = '12M -  Curve ALL (CNV)  V0'
) AS SourceTable
PIVOT (
    MAX(DCI_MonthlyPercentage)
    FOR DCI_Month IN (
        [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30],
		[31], [32], [33], [34], [35], [36], [37], [38], [39], [40], [41], [42], [43], [44], [45], [46], [47], [48], [49], [50], [51], [52], [53], [54], [55], [56], [57], [58], [59], [60]
    )
) AS PivotTable;

----------------------------------------------
--Policy Info shortened
----------------------------------------------
WITH CTE_EventLog AS (
    SELECT DISTINCT
        EVL.EVL_ReferenceNumber AS RefNum,
        EVL.EVL_DateTime AS [Date]
    FROM EventLog EVL
    INNER JOIN Policy POL ON EVL.EVL_ReferenceNumber = POL.Policy_ID AND POL.POL_Deleted = 0
    INNER JOIN Product PRD ON PRD.Product_Id = POL.POL_Product_ID AND PRD.PRD_Deleted = 0
    WHERE EVL.EVL_Event_ID IN (10514)
)

SELECT 
    INS.INS_InsurerName AS [INSURER],
    POL.POL_PolicyNumber AS [POLICY NUMBER],
    POS.POS_Description AS [STATUS],
    PRD.PRD_Name AS [PRODUCT NAME],
    RTF.RTF_Description AS [POLICY FREQUENCY], 

    -- Premium calculation
    (
        SELECT SUM(ITS_Premium)
        FROM ItemSummary
        WHERE ITS_Policy_ID = POL.Policy_ID
            AND ITS_Premium > 0
            AND ITS_Deleted = 0
    ) AS [PREMIUM],

    -- Date formatting
    FORMAT(POL.POL_CreateDate, 'dd/MM/yyyy') AS [CREATE DATE],
    FORMAT(POL.POL_OriginalStartDate, 'dd/MM/yyyy') AS [ORIGINAL START DATE],
    FORMAT(POL.POL_EndDate, 'dd/MM/yyyy') AS [END DATE],

    -- Product Variant Level Details
    PV1.PRV_FullName AS [Variant Level 1 Name],
    PV2.PRV_FullName AS [Variant Level 2 Name],
    PV3.PRV_FullName AS [Variant Level 3 Name],
    PV3.PRV_Code AS [Product Code]


FROM Policy POL
INNER JOIN Product PRD ON POL.POL_Product_ID = PRD.Product_Id
LEFT JOIN PolicyInsurerLink PIL ON PIL.PIL_Policy_ID = POL.Policy_ID
LEFT JOIN Insurer INS ON PIL.PIL_Insurer_ID = INS.Insurer_ID
LEFT JOIN ReferencePolicyStatus POS ON POS.PolicyStatus_ID = POL.POL_Status
LEFT JOIN ReferenceTermFrequency RTF ON RTF.TermFrequency_Id = POL.POL_ProductTerm_ID

-- Join ProductVariants for 4 levels
LEFT JOIN ProductVariant PV1 ON POL.POL_ProductVariantLevel1_ID = PV1.ProductVariant_Id
LEFT JOIN ProductVariant PV2 ON POL.POL_ProductVariantLevel2_ID = PV2.ProductVariant_Id
LEFT JOIN ProductVariant PV3 ON POL.POL_ProductVariantLevel3_ID = PV3.ProductVariant_Id
LEFT JOIN ProductVariant PV4 ON POL.POL_ProductVariantLevel4_ID = PV4.ProductVariant_Id

WHERE POS.POS_Description = 'In Force'
AND EXISTS (
    SELECT 1
    FROM DisbursementCurveProduct AS crv
    INNER JOIN DisbursementCurveHeader AS dch
        ON crv.DCP_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
    WHERE crv.DCP_Product_Id = POL.POL_ProductVariantLevel3_ID
        AND crv.DCP_Deleted = 0
        AND dch.DCH_Deleted = 0
        AND dch.DCH_Enabled = 1
        AND dch.DCH_TermFrequency_Id = POL.POL_ProductTerm_ID
)
AND EXISTS (
    SELECT 1
    FROM ItemSummary ISUM
    WHERE ISUM.ITS_Policy_ID = POL.Policy_ID
        AND ISUM.ITS_Deleted = 0
        AND ISUM.ITS_Premium > 0
)

-- Optional filtering:
-- AND POL.POL_PolicyNumber = 'XXXXXXX'
-- AND INS.INS_InsurerName = 'Some Insurer'
-- AND POL.POL_CreateDate BETWEEN '2024-01-01' AND '2024-12-31'

ORDER BY POL.POL_CreateDate, POL.POL_PolicyNumber;
