/* ================================================================
   Claim Summary (env-aligned, no dynamic SQL) — v7.2
   Improvements:
     - Resolve Policy via CLM_Policy_ID (preferred) OR CLM_PolicyNumber
     - Populate Arrangement_Cell_Captive via POL_Arrangement_ID
     - Vehicle (Make/Model/Reg/Sum_Insured) from ClaimMotorBasicItem
   ================================================================ */

USE [Evolve];
SET NOCOUNT ON;

DECLARE @FromDate date = NULL;   -- start with NULL/NULL to validate rows
DECLARE @ToDate   date = NULL;

IF OBJECT_ID('dbo.Claim','U') IS NULL
BEGIN RAISERROR('Missing dbo.Claim',16,1); RETURN; END;

DECLARE @HasPolicy bit = CASE WHEN OBJECT_ID('dbo.Policy','U')               IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @HasArr    bit = CASE WHEN OBJECT_ID('dbo.Arrangement','U')          IS NOT NULL THEN 1 ELSE 0 END;
DECLARE @HasMotor  bit = CASE WHEN OBJECT_ID('dbo.ClaimMotorBasicItem','U')  IS NOT NULL THEN 1 ELSE 0 END;

IF OBJECT_ID('tempdb..#ClaimSummary') IS NOT NULL DROP TABLE #ClaimSummary;
CREATE TABLE #ClaimSummary (
    [Insurer]                         nvarchar(200)  NULL,
    [CLM_PolicyNumber]                nvarchar(100)  NULL,
    [Sum_Insured]                     decimal(18,2)  NULL,
    [First_Reg_Date]                  nvarchar(100)  NULL,
    [Make]                            nvarchar(100)  NULL,
    [Model]                           nvarchar(200)  NULL,
    [POL_StartDate]                   date           NULL,
    [CLM_ClaimNumber]                 nvarchar(100)  NULL,
    [Claim_item_Create_Date]          datetime       NULL,
    [Claim_Status]                    nvarchar(100)  NULL,
    [Claim_Item_Status]               nvarchar(100)  NULL,
    [Claim_Rejection_reason]          nvarchar(400)  NULL,
    [CLM_ReportedDate]                datetime       NULL,
    [CLM_LossDate]                    datetime       NULL,
    [CLM_CreateDate]                  datetime       NULL,
    [Claim_Item_Sub_Status]           nvarchar(100)  NULL,
    [Amount_Paid]                     decimal(18,2)  NULL,
    [Amount_Paid_excl_VAT]            decimal(18,2)  NULL,
    [Claim_Qty]                       int            NULL,
    [Original_Estimate]               decimal(18,2)  NULL,
    [ PRD_Name ]                      nvarchar(200)  NULL,
    [ Product_Group ]                 nvarchar(200)  NULL,
    [ Product_Plan_Name ]             nvarchar(200)  NULL,
    [ Product_Variant-Level1 ]        nvarchar(200)  NULL,
    [ Product_Variant-Level2 ]        nvarchar(200)  NULL,
    [ Product_Variant-Level3 ]        nvarchar(200)  NULL,
    [ RTF_TermPeriod ]                nvarchar(50)   NULL,
    [ POL_OriginalStartDate ]         date           NULL,
    [ POL_PolicyTerm ]                int            NULL,
    [ Payment_Frequency ]             nvarchar(50)   NULL,
    [ Arrangement_Cell_Captive ]      nvarchar(50)   NULL,
    [ Sales_Region ]                  nvarchar(100)  NULL   -- stays NULL until we know where it lives
);

;WITH CLM AS (
    SELECT
        c.Claim_ID,
        c.CLM_ClaimNumber,
        c.CLM_PolicyNumber,
        c.CLM_CreateDate,
        c.CLM_ReportedDate,
        c.CLM_LossDate,
        c.CLM_Status,
        c.CLM_Policy_ID
    FROM dbo.Claim c
    WHERE ( @FromDate IS NULL OR COALESCE(c.CLM_CreateDate, c.CLM_ReportedDate, c.CLM_LossDate) >= @FromDate )
      AND ( @ToDate   IS NULL OR COALESCE(c.CLM_CreateDate, c.CLM_ReportedDate, c.CLM_LossDate) < DATEADD(DAY,1,@ToDate) )
),
-- Vehicle/cover info from ClaimMotorBasicItem; one aggregated row per Claim_ID
VEH AS (
    SELECT
        m.CMI_Claim_ID AS Claim_ID,
        MAX(m.CMI_RegistrationNumber) AS First_Reg_Date,
        MAX(m.CMI_Make)               AS Make,
        MAX(m.CMI_Model)              AS Model,
        MAX(TRY_CONVERT(decimal(18,2), m.CMI_SumInsured)) AS Sum_Insured
    FROM dbo.ClaimMotorBasicItem m WITH (NOLOCK)
    WHERE @HasMotor = 1
    GROUP BY m.CMI_Claim_ID
)
INSERT INTO #ClaimSummary (
    [Insurer], [CLM_PolicyNumber], [Sum_Insured], [First_Reg_Date], [Make], [Model],
    [POL_StartDate], [CLM_ClaimNumber], [Claim_item_Create_Date],
    [Claim_Status], [Claim_Item_Status], [Claim_Rejection_reason],
    [CLM_ReportedDate], [CLM_LossDate], [CLM_CreateDate], [Claim_Item_Sub_Status],
    [Amount_Paid], [Amount_Paid_excl_VAT], [Claim_Qty], [Original_Estimate],
    [ PRD_Name ], [ Product_Group ], [ Product_Plan_Name ],
    [ Product_Variant-Level1 ], [ Product_Variant-Level2 ], [ Product_Variant-Level3 ],
    [ RTF_TermPeriod ], [ POL_OriginalStartDate ], [ POL_PolicyTerm ], [ Payment_Frequency ],
    [ Arrangement_Cell_Captive ], [ Sales_Region ]
)
SELECT
    /* Insurer unresolved for now (no link in verified tables) */
    NULL                                        AS [Insurer],
    CLM.CLM_PolicyNumber                        AS [CLM_PolicyNumber],
    VEH.Sum_Insured                             AS [Sum_Insured],
    VEH.First_Reg_Date                          AS [First_Reg_Date],
    VEH.Make                                    AS [Make],
    VEH.Model                                   AS [Model],
    POL.POL_StartDate                           AS [POL_StartDate],
    CLM.CLM_ClaimNumber                         AS [CLM_ClaimNumber],
    NULL                                        AS [Claim_item_Create_Date],
    CLM.CLM_Status                              AS [Claim_Status],
    NULL                                        AS [Claim_Item_Status],
    NULL                                        AS [Claim_Rejection_reason],
    CLM.CLM_ReportedDate                        AS [CLM_ReportedDate],
    CLM.CLM_LossDate                            AS [CLM_LossDate],
    CLM.CLM_CreateDate                          AS [CLM_CreateDate],
    NULL                                        AS [Claim_Item_Sub_Status],
    NULL                                        AS [Amount_Paid],
    NULL                                        AS [Amount_Paid_excl_VAT],
    NULL                                        AS [Claim_Qty],
    NULL                                        AS [Original_Estimate],
    NULL                                        AS [ PRD_Name ],
    NULL                                        AS [ Product_Group ],
    NULL                                        AS [ Product_Plan_Name ],
    NULL                                        AS [ Product_Variant-Level1 ],
    NULL                                        AS [ Product_Variant-Level2 ],
    NULL                                        AS [ Product_Variant-Level3 ],
    NULL                                        AS [ RTF_TermPeriod ],
    POL.POL_OriginalStartDate                   AS [ POL_OriginalStartDate ],
    POL.POL_PolicyTerm                          AS [ POL_PolicyTerm ],
    CAST(POL.POL_PaymentFrequency_ID AS nvarchar(50)) AS [ Payment_Frequency ],
    ARR.ARG_CellCaptive                         AS [ Arrangement_Cell_Captive ],
    NULL                                        AS [ Sales_Region ]
FROM CLM
OUTER APPLY (
    /* Prefer Policy by ID; else by matching Policy Number */
    SELECT TOP 1 p.*
    FROM dbo.Policy p WITH (NOLOCK)
    WHERE @HasPolicy = 1
      AND (
            (CLM.CLM_Policy_ID IS NOT NULL AND p.Policy_ID = CLM.CLM_Policy_ID)
         OR (p.POL_PolicyNumber = CLM.CLM_PolicyNumber)
      )
) AS POL
LEFT JOIN dbo.Arrangement ARR WITH (NOLOCK)
       ON @HasArr = 1 AND ARR.Arrangement_Id = POL.POL_Arrangement_ID
LEFT JOIN VEH
       ON @HasMotor = 1 AND VEH.Claim_ID = CLM.Claim_ID
ORDER BY CLM.CLM_CreateDate, CLM.CLM_ClaimNumber;

SELECT TOP (200) * FROM #ClaimSummary ORDER BY [CLM_CreateDate], [CLM_ClaimNumber];
