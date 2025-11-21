/* ==============================================
   TB per Insurer (by NAME) — includes ALL GLs
   De-duplicates multiple Insurer_IDs per name
   ============================================== */

DECLARE @StartDate     date          = '2019-01-01';   -- <-- change me
DECLARE @EndDate       date          = '2025-09-30';   -- <-- change me
DECLARE @InsurerName   nvarchar(200) = NULL;           -- e.g. N'Centriq Life' or NULL for all

-- Inclusive end date
DECLARE @EndDatePlus1 datetime2(0) = DATEADD(day, 1, CAST(@EndDate AS datetime2(0)));

-- Normalizer for names (trim only; keep original case for display)
-- If you want stronger dedupe, replace LTRIM(RTRIM(...)) with UPPER(LTRIM(RTRIM(...))) everywhere it appears.
;WITH InsurerGroups AS
(
    SELECT DISTINCT
        NormalizedName = LTRIM(RTRIM(I.INS_InsurerName)),
        DisplayName    = LTRIM(RTRIM(I.INS_InsurerName))
    FROM Insurer AS I
    WHERE @InsurerName IS NULL
       OR LTRIM(RTRIM(I.INS_InsurerName)) = LTRIM(RTRIM(@InsurerName))

    UNION ALL
    -- Add an "Unspecified" bucket only when showing ALL insurers
    SELECT N'Unspecified', N'Unspecified'
    WHERE @InsurerName IS NULL
),
GLDim AS
(
    -- One row per distinct GL Code + GL Name (prevents GL master duplicates)
    SELECT DISTINCT
        GLC_GlCode,
        GLC_Description
    FROM ReferenceGLCode
    WHERE GLC_GlCode IS NOT NULL
),
Driver AS
(
    -- Cartesian of InsurerGroup (by name) × GLDim:
    -- guarantees every GL appears for every insurer name
    SELECT
        IG.DisplayName AS InsurerName,
        IG.NormalizedName,
        G.GLC_GlCode,
        G.GLC_Description
    FROM InsurerGroups AS IG
    CROSS JOIN GLDim AS G
),
TxnAgg AS
(
    /* Aggregate actual transactions by (InsurerName-by-join × GL Code+Name)
       Join Insurer by casting both IDs to NVARCHAR(50) to avoid GUID conversion issues.
       Bucket NULL / empty names into 'Unspecified'. */
    SELECT
        InsurerName = COALESCE(NULLIF(LTRIM(RTRIM(I.INS_InsurerName)), N''), N'Unspecified'),
        R.GLC_GlCode,
        R.GLC_Description,
        Amount      = SUM(ATN.ATN_GrossAmount),
        AmountExVAT = SUM(ATN.ATN_GrossAmount - ATN.ATN_VATAmount)
    FROM AccountTransactionSet    AS ATS
    INNER JOIN AccountTransaction AS ATN
        ON ATN.ATN_AccountTransactionSet_ID = ATS.AccountTransactionSet_ID
    INNER JOIN ReferenceGLCode     AS R
        ON R.GlCode_ID = ATN.ATN_GLCode_ID
    LEFT  JOIN Insurer             AS I
        ON CAST(I.Insurer_Id AS nvarchar(50)) = CAST(ATS.ATS_Insurer_Id AS nvarchar(50))
    WHERE
        -- Effective date window, inclusive end
        IIF(ATS.ATS_CreateDate > ATS.ATS_EffectiveDate, ATS.ATS_CreateDate, ATS.ATS_EffectiveDate) >= @StartDate
        AND IIF(ATS.ATS_CreateDate > ATS.ATS_EffectiveDate, ATS.ATS_CreateDate, ATS.ATS_EffectiveDate) <  @EndDatePlus1
        -- If a single insurer is requested, keep only rows for that name
        AND (@InsurerName IS NULL
             OR LTRIM(RTRIM(I.INS_InsurerName)) = LTRIM(RTRIM(@InsurerName)))
    GROUP BY
        COALESCE(NULLIF(LTRIM(RTRIM(I.INS_InsurerName)), N''), N'Unspecified'),
        R.GLC_GlCode, R.GLC_Description
)
SELECT
    D.InsurerName                         AS [Insurer Name],
    D.GLC_GlCode                          AS [GL Code],
    D.GLC_Description                     AS [GL Name],
    CAST(COALESCE(A.Amount,      0.0) AS decimal(18,2)) AS [Amount],
    CAST(COALESCE(A.AmountExVAT,  0.0) AS decimal(18,2)) AS [Amount excl Vat]
FROM Driver AS D
LEFT JOIN TxnAgg AS A
    ON A.InsurerName  = D.NormalizedName  -- match by normalized Insurer name
   AND A.GLC_GlCode   = D.GLC_GlCode
   AND A.GLC_Description = D.GLC_Description
ORDER BY
    [Insurer Name], [GL Code], [GL Name];
