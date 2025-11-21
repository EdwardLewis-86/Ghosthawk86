SELECT
    Measurement_Month,
    Insurer_Name,
    PRD_Name,
    COUNT(*) AS ActivePolicyCount
FROM [RB_Analysis].[dbo].[Evolve_policy_Month_end_Snapshot]
WHERE Policy_Status = 'In Force'
GROUP BY
    Measurement_Month,
    Insurer_Name,
    PRD_Name
ORDER BY
    Measurement_Month,
    Insurer_Name,
    PRD_Name;
