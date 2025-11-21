USE Evolve;
GO

DECLARE @ValuationMonth DATE = '2025-07-01';                 ---------------> Update

-- Step 1: Pre-aggregate UPP per policy
WITH PreAggregatedUPP AS (
    SELECT
        POL_PolicyNumber,
        ValuationMonth,
        CellCaptive,
        INS_InsurerName,
        SUM(UPP) AS UPP_Total
    FROM [UPP].[dbo].[SAW_UPP_202507_Test_2]                    ---------------> Update
    WHERE ValuationMonth = @ValuationMonth
    GROUP BY POL_PolicyNumber, ValuationMonth, CellCaptive, INS_InsurerName
),

-- Step 2: Select only 1 arrangement row per agent using ROW_NUMBER
AgentArrangement AS (
    SELECT
        agt.Agent_Id,
        agt.Agt_Name,
        agt.Agt_AgentNumber,
        arr.ARG_ArrangementNumber,
        arr.ARG_Name,
        ROW_NUMBER() OVER (PARTITION BY agt.Agent_Id ORDER BY arr.ARG_Name) AS rn
    FROM [Evolve].[dbo].[Agent] agt
    LEFT JOIN [Evolve].[dbo].[ArrangementAgents] arga
        ON agt.Agent_Id = arga.ARA_Agent_ID AND arga.ARA_Deleted = 0
    LEFT JOIN [Evolve].[dbo].[Arrangement] arr
        ON arga.ARA_Arrangement_ID = arr.Arrangement_Id AND arr.ARG_Deleted = 0
)

-- Step 3: Final join and filter only the first arrangement per agent
SELECT
    pUPP.ValuationMonth,
    pUPP.CellCaptive,
    pUPP.INS_InsurerName,
    agt.Agt_Name AS [Agent Name],
    agt.Agt_AgentNumber AS [Agent Number],
    agt.ARG_ArrangementNumber AS [Arrangement Number],
    agt.ARG_Name AS [Arrangement Name],
    SUM(pUPP.UPP_Total) AS Total_UPP

FROM PreAggregatedUPP pUPP

LEFT JOIN [Evolve].[dbo].[Policy] p
    ON pUPP.POL_PolicyNumber = p.POL_PolicyNumber

LEFT JOIN AgentArrangement agt
    ON p.POL_Agent_ID = agt.Agent_Id AND agt.rn = 1  -- <--- only one row per agent

--WHERE agt.Agt_Name = 'Autodrome (Mobility)'

GROUP BY
    pUPP.ValuationMonth,
    pUPP.CellCaptive,
    pUPP.INS_InsurerName,
    agt.Agt_Name,
    agt.Agt_AgentNumber,
    agt.ARG_ArrangementNumber,
    agt.ARG_Name

ORDER BY
    pUPP.ValuationMonth,
    pUPP.CellCaptive,
    pUPP.INS_InsurerName,
    agt.Agt_Name;
