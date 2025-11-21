-- Drop the temp table if it exists
IF OBJECT_ID('tempdb..#pegasus') IS NOT NULL
    DROP TABLE #pegasus;

-- Create #pegasus with row_number and only one row per group
SELECT *, 
       ROW_NUMBER() OVER (PARTITION BY product ORDER BY (SELECT NULL)) AS seq
INTO #pegasus
FROM [LC-PEGASUS].[MSureEvolve].[dbo].[saw_warranties];

-- Aggregated output
SELECT 
    PRV_Code,
	PRV_Name,
    PlanName,
    term,
	Premium,
	Commission,
    SUM(CASE WHEN DVT_Description = 'Inspection' THEN VSV_Value ELSE 0 END) AS Inspection_Fees,
    SUM(CASE WHEN DVT_Description = 'Liquid Assist Road Side Assistance' THEN VSV_Value ELSE 0 END) AS Liquid_Roadside_Fees,
    SUM(CASE WHEN DVT_Description = 'M-Sure Road Side Assistance' THEN VSV_Value ELSE 0 END) AS Msure_Roadside_Fees,
    SUM(CASE WHEN DVT_Description NOT IN ('Inspection', 'Liquid Assist Road Side Assistance', 'M-Sure Road Side Assistance') THEN VSV_Value ELSE 0 END) AS Other_Fees
FROM (
    SELECT 
        peg.PlanName,
        peg.term,
        prv.PRV_Code, 
        prv.PRV_Name, 
        prp.PRP_PlanName,   
        rtf.RTF_TermPeriod, 
        CAST(peg.premium_exclVAT * 1.15 AS DECIMAL(10,2)) AS Premium,
        CAST(CAST(peg.premium_exclVAT * 1.15 AS DECIMAL(10,2)) * 0.125 AS DECIMAL(10,2)) AS Commission,
        dvt.DVT_Description, 
        vst.VST_Description, 
        vsv.VSV_Value
    FROM #pegasus AS peg
    INNER JOIN [MS-ACT01].[evolve].[dbo].[productvariant] AS prv 
        ON peg.product = prv.PRV_Code
    INNER JOIN [MS-ACT01].[evolve].[dbo].[ProductPlans] AS prp 
        ON prp.PRP_PlanName = peg.PlanName AND prp.PRP_Deleted = 0
    INNER JOIN [MS-ACT01].[evolve].[dbo].[ReferenceTermFrequency] AS rtf 
        ON rtf.RTF_TermPeriod = peg.term 
    LEFT JOIN [MS-ACT01].[evolve].[dbo].[DisbursementValueSetHeader] AS vsh 
        ON VSH_ProductVariant_Id = prv.ProductVariant_Id AND VSH_Deleted = 0
    LEFT JOIN [MS-ACT01].[evolve].[dbo].[ReferenceRatingGroups] AS rrg 
        ON vsh.VSH_RatingGroup_ID = rrg.RatingGroup_ID 
           AND rrg.RGP_Description = peg.ratinggroup 
           AND rrg.RGP_Deleted = 0
    LEFT JOIN [MS-ACT01].[evolve].[dbo].[DisbursementValueSetDetail] AS vsd 
        ON vsd.VSD_DisbursementValueSetHeader_Id = vsh.DisbursementValueSetHeader_Id 
           AND vsd.VSD_ProductPlans_Id = prp.ProductPlans_Id 
           AND vsd.VSD_TermFrequency_Id = rtf.TermFrequency_Id 
           AND vsd.VSD_Deleted = 0
    LEFT JOIN [MS-ACT01].[evolve].[dbo].[DisbursementValueSetValue] AS vsv 
        ON vsd.DisbursementValueSetDetail_Id = vsv.VSV_DisbursementValueSetDetailId 
           AND vsv.VSV_Deleted = 0
    LEFT JOIN [MS-ACT01].[evolve].[dbo].[ReferenceDisbursementValueType] AS dvt 
        ON vsv.VSV_DisbursementRuleName_Id = dvt.DisbursementValueType_Id 
           AND DVT_Deleted = 0
    LEFT JOIN [MS-ACT01].[evolve].[dbo].[ReferenceDisbursementValueSetType] AS vst 
        ON vst.DisbursementValueSetType_Id = vsv.VSV_ValueType
    WHERE seq = 1
) AS X
GROUP BY PRV_Code, PRV_Name, PlanName, term, Premium, Commission
ORDER BY PRV_Code;