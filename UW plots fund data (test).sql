USE Evolve;
SET NOCOUNT ON;

------------------------------------------------------------
-- Parameters 
------------------------------------------------------------
DECLARE @start date = '2019-01-01';
DECLARE @end   date = '2025-08-01';     -- exclusive upper bound (first day after last month)
DECLARE @start_for_opening date = DATEADD(month,-1,@start);

-- Claims cash-out type
DECLARE @CashOutTypeId int = 2;

------------------------------------------------------------
-- Timers
------------------------------------------------------------
DECLARE @t0     datetime2(3) = SYSDATETIME();
DECLARE @t_last datetime2(3) = @t0;
DECLARE @now    datetime2(3);

------------------------------------------------------------
-- Clean-up (drop everything we create)
------------------------------------------------------------
DROP TABLE IF EXISTS #MTH,#Pol,#EV,#EL_month,#PolMonth,#ResPol,
                    #AT_Prem,#AT_Fees,#PolFin,
                    #PayTx,#ClaimsByPolMth,
                    #Final;

------------------------------------------------------------
-- 1) Month calendar (include previous month for OpeningCount)
------------------------------------------------------------
;WITH m AS (
  SELECT CAST(DATEADD(month, DATEDIFF(month,0,@start_for_opening), 0) AS date) AS MTH
  UNION ALL
  SELECT DATEADD(month,1,MTH) FROM m WHERE DATEADD(month,1,MTH) < @end
)
SELECT MTH, EOMONTH(MTH) AS mthd
INTO #MTH
FROM m
OPTION (MAXRECURSION 1200);

SET @now = SYSDATETIME();
PRINT CONCAT('Step 1: #MTH built | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

------------------------------------------------------------
-- 2) Policies + classifiers (#Pol)
--    Keep RAW product; add PRD_Family; compute NewRateInd (Adcover only)
------------------------------------------------------------
SELECT
    p.Policy_ID,
    p.POL_PolicyNumber,
    p.POL_SoldDate,
    p.POL_OriginalStartDate,
    p.POL_EndDate,
    p.POL_Status,
    rtf.RTF_TermPeriod,
    i.INS_InsurerName AS Insurer,
    rcc.RCC_GLCode    AS CellCaptive,

    CASE
      WHEN rcc.RCC_GLCode IN ('WAMP','WAMT','WIAP','WIAT','WAPP','WAPT','WESP','WESB') THEN 'WesBank'
      WHEN rcc.RCC_GLCode IN ('MEY','WMYT','WMYP')                                       THEN 'Meyers'
      WHEN rcc.RCC_GLCode IN ('KMP','WKPT','WKPP')                                       THEN 'Kempston'
      WHEN rcc.RCC_GLCode IN ('MTM','WMTT','WMTP')                                       THEN 'Maritime'
      WHEN rcc.RCC_GLCode IN ('KNT','WKNT','WKNP')                                       THEN 'Kent'
      WHEN rcc.RCC_GLCode IN ('ELSK')                                                    THEN 'Mobility Fund'
      WHEN rcc.RCC_GLCode IN ('IEM')                                                     THEN 'Iemas'
      ELSE rcc.RCC_GLCode
    END AS CellCaptive2,

    CASE WHEN rcc.RCC_GLCode IN ('APD','MST','MOT','OEM') THEN rcc.RCC_GLCode ELSE 'Non-Group' END AS CellGroup,

    -- RAW product name for per-product alignment
    LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) AS PRD_Name_RAW,

    -- Roll-up family
    CASE
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) IN (
           'Adcover','Adcover (H)',
           'Adcover & Deposit Cover Combo','Adcover & Deposit Cover Combo (H)',
           'Deposit Cover','Deposit Cover (H)',
           'Auto Pedigree Plus Plan with Deposit Cover',
           'Vehicle Value Protector'
      ) THEN 'Adcover'
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Mobility Life Cover%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Lifestyle Protection Plan%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) IN ('Mobility Life Cover (H)','Lifestyle Protection Plan (H)')
      THEN 'Mobility Life Cover'
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE '%Tyre%Rim%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Tyre & Rim%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Tyre and Rim%'
      THEN 'Tyre and Rim'
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE '%Scratch%Dent%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Scratch and Dent%'
      THEN 'Scratch and Dent'
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Paint Tech%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Painttech%'
        OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Paint Protection%'
      THEN 'Paint Tech'
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) = 'Warranty Booster' THEN 'Warranty Booster'
      WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE '%Warranty%'     THEN 'Warranty Non-Booster'
      ELSE LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown')))
    END AS PRD_Family,

    -- NewRateInd: only for Adcover family; NULL for others (use ISNULL if you want 0)
    CASE
      WHEN
        CASE
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) IN (
               'Adcover','Adcover (H)',
               'Adcover & Deposit Cover Combo','Adcover & Deposit Cover Combo (H)',
               'Deposit Cover','Deposit Cover (H)',
               'Auto Pedigree Plus Plan with Deposit Cover',
               'Vehicle Value Protector'
          ) THEN 'Adcover'
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Mobility Life Cover%'
            OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Lifestyle Protection Plan%'
            OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) IN ('Mobility Life Cover (H)','Lifestyle Protection Plan (H)')
          THEN 'Mobility Life Cover'
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE '%Tyre%Rim%'
            OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Tyre & Rim%'
            OR LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Tyre and Rim%'
          THEN 'Tyre and Rim'
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE '%Scratch%Dent%'
          THEN 'Scratch and Dent'
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE 'Paint Tech%'
          THEN 'Paint Tech'
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) = 'Warranty Booster' THEN 'Warranty Booster'
          WHEN LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown'))) LIKE '%Warranty%'     THEN 'Warranty Non-Booster'
          ELSE LTRIM(RTRIM(COALESCE(pv1.PRV_FullName, pr.PRD_Name, 'Unknown')))
        END = 'Adcover'
      THEN CASE WHEN p.POL_OriginalStartDate >= '2022-07-27' THEN 1 ELSE 0 END
      ELSE NULL
    END AS NewRateInd
INTO #Pol
FROM Evolve.dbo.Policy                         p
LEFT JOIN Evolve.dbo.ReferenceTermFrequency    rtf ON rtf.TermFrequency_Id = p.POL_ProductTerm_ID
LEFT JOIN Evolve.dbo.Arrangement               arg ON arg.Arrangement_Id    = p.POL_Arrangement_ID
LEFT JOIN Evolve.dbo.ReferenceCellCaptive      rcc ON rcc.ReferenceCellCaptive_Code = arg.ARG_CellCaptive
LEFT JOIN Evolve.dbo.PolicyInsurerLink         pil ON pil.PIL_Policy_ID     = p.Policy_ID AND pil.PIL_Deleted = 0
LEFT JOIN Evolve.dbo.Insurer                   i   ON i.Insurer_Id          = pil.PIL_Insurer_ID AND i.INS_Deleted = 0
LEFT JOIN Evolve.dbo.ProductVariant            pv1 ON pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID
LEFT JOIN Evolve.dbo.Product                   pr  ON pr.Product_Id         = p.POL_Product_ID
WHERE p.POL_Deleted = 0
  AND (pv1.PRV_Deleted = 0 OR pv1.PRV_Deleted IS NULL)
  AND (arg.ARG_Deleted = 0 OR arg.ARG_Deleted IS NULL)
  AND p.POL_Status IN (1,3)                                -- active-like
  AND p.POL_OriginalStartDate < @end
  AND (p.POL_EndDate IS NULL OR p.POL_EndDate >= @start_for_opening);

CREATE NONCLUSTERED INDEX IX_Pol ON #Pol(POL_PolicyNumber, PRD_Name_RAW, PRD_Family, NewRateInd, CellCaptive, CellCaptive2, CellGroup, Insurer);

SET @now = SYSDATETIME();
PRINT CONCAT('Step 2: #Pol built | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

------------------------------------------------------------
-- 3) EventLog -> monthly movement counters
--    NOTE: ClosingCount is not based on events.
------------------------------------------------------------
SELECT
    el.EVL_ReferenceNumber AS Policy_ID,
    el.EVL_Event_ID        AS EventID,
    el.EVL_Description     AS EventDesc,
    el.EVL_DateTime
INTO #EV
FROM Evolve.dbo.EventLog el
JOIN #Pol p ON p.Policy_ID = el.EVL_ReferenceNumber
WHERE el.EVL_Event_ID IN (10514,10516,10733)
  AND el.EVL_DateTime < DATEADD(day,1,@end);

CREATE CLUSTERED INDEX IX_EV ON #EV(Policy_ID, EVL_DateTime);

-- in-month movement counters
SELECT
  p.POL_PolicyNumber, m.mthd,
  SUM(CASE WHEN e.EventID = 10514 THEN 1 ELSE 0 END) AS NewBusiness,
  SUM(CASE WHEN e.EventID = 10733 THEN 1 ELSE 0 END) AS Reinstatements,
  SUM(CASE WHEN e.EventID = 10516 AND e.EventDesc IN ('END OF POLICY TERM','END OF TERM','END OF TERM - POLICY NOT RENEWED','TERMINATION - END OF TERM') THEN 1 ELSE 0 END) AS EndOfTerm,
  SUM(CASE WHEN e.EventID = 10516 AND (e.EventDesc NOT IN ('END OF POLICY TERM','END OF TERM','END OF TERM - POLICY NOT RENEWED','TERMINATION - END OF TERM') OR e.EventDesc IS NULL) THEN 1 ELSE 0 END) AS Cancelled,
  SUM(CASE WHEN e.EventID = 10516 THEN 1 ELSE 0 END) AS Exits
INTO #EL_month
FROM #Pol p
CROSS JOIN #MTH m
LEFT JOIN #EV e
  ON e.Policy_ID = p.Policy_ID
 AND e.EVL_DateTime >= m.MTH
 AND e.EVL_DateTime <  DATEADD(month,1,m.MTH)
GROUP BY p.POL_PolicyNumber, m.mthd;

CREATE NONCLUSTERED INDEX IX_EL_month ON #EL_month(POL_PolicyNumber,mthd);

-- Policy × month, with date-based ClosingCount (in force at EOM) + NewRateInd carried through
SELECT
  p.POL_PolicyNumber, m.mthd,
  p.PRD_Name_RAW, p.PRD_Family, p.NewRateInd,
  p.CellCaptive, p.CellCaptive2, p.CellGroup, p.Insurer,

  CASE
    WHEN p.POL_OriginalStartDate <= m.mthd
     AND (p.POL_EndDate IS NULL OR p.POL_EndDate > m.mthd)
     AND p.POL_Status IN (1,3)
    THEN 1 ELSE 0
  END AS ClosingCount,

  em.NewBusiness, em.Reinstatements, em.Cancelled, em.EndOfTerm, em.Exits
INTO #PolMonth
FROM #Pol p
CROSS JOIN #MTH m
LEFT JOIN #EL_month em ON em.POL_PolicyNumber = p.POL_PolicyNumber AND em.mthd = m.mthd;

CREATE NONCLUSTERED INDEX IX_PolMonth ON #PolMonth(POL_PolicyNumber,mthd);

;WITH x AS (
  SELECT *, LAG(ClosingCount) OVER (PARTITION BY POL_PolicyNumber ORDER BY mthd) AS OpeningPrev
  FROM #PolMonth
)
SELECT
  POL_PolicyNumber, mthd,
  PRD_Name_RAW, PRD_Family, NewRateInd,
  CellCaptive, CellCaptive2, CellGroup, Insurer,
  ISNULL(ClosingCount,0)     AS ClosingCount,
  ISNULL(NewBusiness,0)      AS NewBusiness,
  ISNULL(Reinstatements,0)   AS Reinstatements,
  ISNULL(Cancelled,0)        AS Cancelled,
  ISNULL(EndOfTerm,0)        AS EndOfTerm,
  ISNULL(Exits,0)            AS Exits,
  ISNULL(OpeningPrev,0)      AS OpeningCount
INTO #ResPol
FROM x;

CREATE NONCLUSTERED INDEX IX_ResPol ON #ResPol(POL_PolicyNumber,mthd);

SET @now = SYSDATETIME();
PRINT CONCAT('Step 3: Movement + state done (date-based Closing) | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

------------------------------------------------------------
-- 4) Finance (premiums & fees)  ->  #PolFin
------------------------------------------------------------
-- Pre-resolve GLCode_IDs
DROP TABLE IF EXISTS #GL_Prem, #FeeMap;
SELECT GlCode_ID
INTO #GL_Prem
FROM Evolve.dbo.ReferenceGLCode
WHERE GLC_GlCode = '100000';  -- GWP

CREATE TABLE #FeeMap (
  GlCode_ID int PRIMARY KEY,
  FeeType tinyint  -- 1=Commission, 2=Binder, 3=Outsource, 4=Insurer
);

INSERT #FeeMap(GlCode_ID, FeeType)
SELECT GlCode_ID, 1 FROM Evolve.dbo.ReferenceGLCode WHERE GLC_GlCode = '100700';
INSERT #FeeMap(GlCode_ID, FeeType)
SELECT GlCode_ID, 2 FROM Evolve.dbo.ReferenceGLCode WHERE GLC_GlCode IN ('306301','306302','306307','306308','306309');
INSERT #FeeMap(GlCode_ID, FeeType)
SELECT GlCode_ID, 3 FROM Evolve.dbo.ReferenceGLCode WHERE GLC_GlCode = '306303';
INSERT #FeeMap(GlCode_ID, FeeType)
SELECT GlCode_ID, 4 FROM Evolve.dbo.ReferenceGLCode WHERE GLC_GlCode = '306304';

-- Stage ATS rows inside the window with a SARGable filter
DROP TABLE IF EXISTS #ATS_mth;
SELECT
  ats.AccountTransactionSet_Id,
  ats.ATS_DisplayNumber AS POL_PolicyNumber,
  CAST(DATEFROMPARTS(YEAR(ats.ATS_CreateDate), MONTH(ats.ATS_CreateDate), 1) AS date) AS MTH
INTO #ATS_mth
FROM Evolve.dbo.AccountTransactionSet ats
WHERE ats.ATS_CreateDate > ats.ATS_EffectiveDate
  AND ats.ATS_CreateDate >= @start_for_opening
  AND ats.ATS_CreateDate <  @end
UNION ALL
SELECT
  ats.AccountTransactionSet_Id,
  ats.ATS_DisplayNumber,
  CAST(DATEFROMPARTS(YEAR(ats.ATS_EffectiveDate), MONTH(ats.ATS_EffectiveDate), 1) AS date)
FROM Evolve.dbo.AccountTransactionSet ats
WHERE ats.ATS_CreateDate <= ats.ATS_EffectiveDate
  AND ats.ATS_EffectiveDate >= @start_for_opening
  AND ats.ATS_EffectiveDate <  @end;

CREATE CLUSTERED INDEX IX_ATS_mth ON #ATS_mth(AccountTransactionSet_Id);
CREATE NONCLUSTERED INDEX IX_ATS_mth_MTH ON #ATS_mth(MTH, POL_PolicyNumber);

-- 4a) GWP
DROP TABLE IF EXISTS #AT_Prem;
SELECT
  a.POL_PolicyNumber,
  a.MTH,
  SUM(atn.ATN_GrossAmount) AS GWP_Amt
INTO #AT_Prem
FROM #ATS_mth a
JOIN Evolve.dbo.AccountTransaction atn
  ON atn.ATN_AccountTransactionSet_ID = a.AccountTransactionSet_Id
JOIN #GL_Prem gp
  ON gp.GlCode_ID = atn.ATN_GLCode_ID
GROUP BY a.POL_PolicyNumber, a.MTH
OPTION (RECOMPILE);

CREATE NONCLUSTERED INDEX IX_AT_Prem ON #AT_Prem(POL_PolicyNumber, MTH);

SET @now = SYSDATETIME();
PRINT CONCAT('Step 4a: GWP (#AT_Prem) done | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

-- 4b) Fees
DROP TABLE IF EXISTS #AT_Fees;
SELECT
  a.POL_PolicyNumber,
  a.MTH,
  SUM(CASE WHEN fm.FeeType = 1 THEN atn.ATN_NettAmount ELSE 0 END) AS Commission_Amt,
  SUM(CASE WHEN fm.FeeType = 2 THEN atn.ATN_NettAmount ELSE 0 END) AS BinderFee_Amt,
  SUM(CASE WHEN fm.FeeType = 3 THEN atn.ATN_NettAmount ELSE 0 END) AS OutsourceFee_Amt,
  SUM(CASE WHEN fm.FeeType = 4 THEN atn.ATN_NettAmount ELSE 0 END) AS InsurerFee_Amt
INTO #AT_Fees
FROM #ATS_mth a
JOIN Evolve.dbo.AccountTransaction atn
  ON atn.ATN_AccountTransactionSet_ID = a.AccountTransactionSet_Id
JOIN #FeeMap fm
  ON fm.GlCode_ID = atn.ATN_GLCode_ID
GROUP BY a.POL_PolicyNumber, a.MTH
OPTION (RECOMPILE);

CREATE NONCLUSTERED INDEX IX_AT_Fees ON #AT_Fees(POL_PolicyNumber, MTH);

SET @now = SYSDATETIME();
PRINT CONCAT('Step 4b: Fees (#AT_Fees) done | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

-- 4c) Link finance to month grid
DROP TABLE IF EXISTS #PolFin;
SELECT
  po.POL_PolicyNumber,
  m.mthd,
  po.PRD_Name_RAW, po.PRD_Family, po.NewRateInd,
  po.CellCaptive, po.CellCaptive2, po.CellGroup, po.Insurer,
  ISNULL(pr.GWP_Amt,0) AS GWP_Amt,
  CASE WHEN ISNULL(pr.GWP_Amt,0) = 0 THEN 0 ELSE
       ISNULL(pr.GWP_Amt,0)
     - ISNULL(f.Commission_Amt,0)
     - ISNULL(f.BinderFee_Amt,0)
     - ISNULL(f.InsurerFee_Amt,0)
     - ISNULL(f.OutsourceFee_Amt,0) END AS EarnedFund_Amt
INTO #PolFin
FROM #Pol po
CROSS JOIN #MTH m
LEFT JOIN #AT_Prem pr ON pr.POL_PolicyNumber = po.POL_PolicyNumber AND pr.MTH = m.MTH
LEFT JOIN #AT_Fees f  ON f.POL_PolicyNumber  = po.POL_PolicyNumber AND f.MTH  = m.MTH;

SET @now = SYSDATETIME();
PRINT CONCAT('Step 4c: Finance aggregate (#PolFin) done | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

------------------------------------------------------------
-- 5) Claims (Cash-out = Type 2); ex-VAT net of discounts
------------------------------------------------------------
DROP TABLE IF EXISTS #PayTx, #ClaimsByPolMth;

-- One row per ClaimItem per pay month with ex-VAT Paid & Discount
SELECT
  cit.CIT_ClaimItem_ID,
  CAST(DATEFROMPARTS(YEAR(cit.CIT_postingDate), MONTH(cit.CIT_postingDate), 1) AS date) AS PayMTH,
  SUM(cit.CIT_Amount - cit.CIT_AmountVAT)                       AS PaidExVAT,
  SUM(CAST(COALESCE(cit.CIT_Discount,0) AS decimal(18,4))/1.15) AS DiscExVAT
INTO #PayTx
FROM Evolve.dbo.ClaimItemTransaction cit
WHERE cit.CIT_Deleted = 0
  AND cit.CIT_IsReversed = 0
  AND cit.CIT_TransactionType_ID = @CashOutTypeId
  AND cit.CIT_EffectiveDate <  cit.CIT_postingDate
  AND cit.CIT_postingDate >= @start_for_opening
  AND cit.CIT_postingDate <  @end
GROUP BY cit.CIT_ClaimItem_ID,
         CAST(DATEFROMPARTS(YEAR(cit.CIT_postingDate), MONTH(cit.CIT_postingDate), 1) AS date)

UNION ALL

SELECT
  cit.CIT_ClaimItem_ID,
  CAST(DATEFROMPARTS(YEAR(cit.CIT_EffectiveDate), MONTH(cit.CIT_EffectiveDate), 1) AS date) AS PayMTH,
  SUM(cit.CIT_Amount - cit.CIT_AmountVAT),
  SUM(CAST(COALESCE(cit.CIT_Discount,0) AS decimal(18,4))/1.15)
FROM Evolve.dbo.ClaimItemTransaction cit
WHERE cit.CIT_Deleted = 0
  AND cit.CIT_IsReversed = 0
  AND cit.CIT_TransactionType_ID = @CashOutTypeId
  AND cit.CIT_EffectiveDate >= cit.CIT_postingDate
  AND cit.CIT_EffectiveDate >= @start_for_opening
  AND cit.CIT_EffectiveDate <  @end
GROUP BY cit.CIT_ClaimItem_ID,
         CAST(DATEFROMPARTS(YEAR(cit.CIT_EffectiveDate), MONTH(cit.CIT_EffectiveDate), 1) AS date)
OPTION (RECOMPILE);

CREATE NONCLUSTERED INDEX IX_PayTx ON #PayTx(CIT_ClaimItem_ID, PayMTH);

-- Per policy × month: ClaimCount & ClaimAmount (ex-VAT, net discounts, ABS)
SELECT
  LTRIM(RTRIM(cis.CIS_PolicyNumber)) AS CIS_PolicyNumber,
  m.mthd,
  COUNT(DISTINCT pt.CIT_ClaimItem_ID)                       AS ClaimCount,
  SUM(ABS(ISNULL(pt.PaidExVAT,0) - ISNULL(pt.DiscExVAT,0))) AS ClaimAmount
INTO #ClaimsByPolMth
FROM #PayTx pt
JOIN Evolve.dbo.ClaimItemSummary cis ON cis.CIS_ClaimItem_ID = pt.CIT_ClaimItem_ID
JOIN #MTH m ON m.MTH = pt.PayMTH
GROUP BY LTRIM(RTRIM(cis.CIS_PolicyNumber)), m.mthd
OPTION (RECOMPILE);

CREATE NONCLUSTERED INDEX IX_ClaimsByPolMth ON #ClaimsByPolMth(CIS_PolicyNumber, mthd);

SET @now = SYSDATETIME();
PRINT CONCAT('Step 5: Claims aggregate | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');
SET @t_last = @now;

------------------------------------------------------------
-- 6) Final monthly rollup (group by RAW product; include NewRateInd)
------------------------------------------------------------
;WITH agg AS (
  SELECT
      pm.mthd,
      pm.PRD_Name_RAW     AS PRD_Name,     -- RAW for per-product view
      pm.PRD_Family,                       -- optional roll-up
      pm.NewRateInd,                       -- Adcover split (1/0/NULL)
      pm.CellCaptive,
      pm.CellCaptive2,
      pm.CellGroup,
      pm.Insurer,

      ABS(SUM(ISNULL(pf.GWP_Amt,0)))        AS GWP,
      ABS(SUM(ISNULL(pf.EarnedFund_Amt,0))) AS EarnedFund,

      SUM(CAST(pm.ClosingCount   AS bigint)) AS ClosingCount,
      SUM(CAST(pm.NewBusiness    AS bigint)) AS NewBusiness,
      SUM(CAST(pm.Reinstatements AS bigint)) AS Reinstatements,
      SUM(CAST(pm.Cancelled      AS bigint)) AS Cancelled,
      SUM(CAST(pm.EndOfTerm      AS bigint)) AS EndOfTerm,
      SUM(CAST(pm.Exits          AS bigint)) AS Exits,
      SUM(CAST(pm.OpeningCount   AS bigint)) AS OpeningCount,

      SUM(CAST(ISNULL(cb.ClaimCount,0) AS bigint)) AS ClaimCount,
      ABS(SUM(ISNULL(cb.ClaimAmount,0)))          AS ClaimAmount
  FROM #ResPol pm
  LEFT JOIN #PolFin pf
         ON pf.POL_PolicyNumber = pm.POL_PolicyNumber
        AND pf.mthd            = pm.mthd
  LEFT JOIN #ClaimsByPolMth cb
         ON LTRIM(RTRIM(cb.CIS_PolicyNumber)) = LTRIM(RTRIM(pm.POL_PolicyNumber))
        AND cb.mthd            = pm.mthd
  WHERE pm.mthd BETWEEN EOMONTH(@start) AND EOMONTH(DATEADD(month,-1,@end))
  GROUP BY pm.mthd, pm.PRD_Name_RAW, pm.PRD_Family, pm.NewRateInd,
           pm.CellCaptive, pm.CellCaptive2, pm.CellGroup, pm.Insurer
)
SELECT
    a.mthd,
    a.PRD_Name,
    a.PRD_Family,
    a.NewRateInd,                                 -- visible split
    a.CellCaptive,
    a.CellCaptive2,
    a.CellGroup,
    a.Insurer,
    CASE WHEN a.ClaimAmount = 0 THEN 'Zero' ELSE 'Non-Zero' END AS claim_category,
    CAST(a.GWP        AS decimal(18,2)) AS [GWP],
    CAST(a.EarnedFund AS decimal(18,2)) AS [EarnedFund],
    a.ClosingCount,
    a.NewBusiness,
    a.Reinstatements,
    a.Cancelled,
    a.EndOfTerm,
    a.Exits,
    a.OpeningCount,
    a.ClaimCount,
    CAST(a.ClaimAmount AS decimal(18,2)) AS ClaimAmount
INTO #Final
FROM agg a;

SET @now = SYSDATETIME();
PRINT CONCAT('Step 6: Final built | step=', DATEDIFF(millisecond,@t_last,@now),' ms | total=', DATEDIFF(millisecond,@t0,@now),' ms');

------------------------------------------------------------
-- Output
------------------------------------------------------------
SELECT *
FROM #Final
ORDER BY PRD_Name, CellCaptive2, CellGroup, mthd, NewRateInd;
