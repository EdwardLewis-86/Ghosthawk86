USE Evolve;
GO

;WITH RankedAgents AS (
    SELECT
        i.INS_InsurerName AS [Insurer Name],
        agt.Agt_Name AS [Agent Name],
        agt.Agt_AgentNumber AS [Agent Number],
        agt.Agt_RegisteredName AS [Agent Registered Name],
        agt.Agt_RegisteredNumber AS [Agent Registered Number],
        agt.Agt_VATNumber AS [Agent VAT Number],
        arr.ARG_ArrangementNumber AS [Arrangement Number],
        arr.ARG_Name AS [Arrangement Name],
        ROW_NUMBER() OVER (
            PARTITION BY agt.Agt_AgentNumber
            ORDER BY arr.ARG_Name
        ) AS rn
    FROM [Evolve].[dbo].[Policy] p

    -- Join to Agent
    LEFT JOIN [Evolve].[dbo].[Agent] agt
        ON p.POL_Agent_ID = agt.Agent_Id

    -- Join Agent to Arrangement
    LEFT JOIN [Evolve].[dbo].[ArrangementAgents] arga
        ON agt.Agent_Id = arga.ARA_Agent_ID

    LEFT JOIN [Evolve].[dbo].[Arrangement] arr
        ON arga.ARA_Arrangement_ID = arr.Arrangement_Id

    -- Join Policy to Transaction Set to get Insurer
    LEFT JOIN [Evolve].[dbo].[AccountTransactionSet] ats
        ON ats.ATS_DisplayNumber = p.POL_PolicyNumber

    LEFT JOIN [Evolve].[dbo].[Insurer] i
        ON ats.ATS_Insurer_Id = i.Insurer_Id
)

SELECT
    [Insurer Name],
    [Agent Name],
    [Agent Number],
    [Agent Registered Name],
    [Agent Registered Number],
    [Agent VAT Number],
    [Arrangement Number],
    [Arrangement Name]
FROM RankedAgents
WHERE rn = 1
ORDER BY
    [Insurer Name],
    [Agent Name],
    [Arrangement Name];
