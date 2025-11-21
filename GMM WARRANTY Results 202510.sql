USE [UPP]
--GO

-- Declare variables
DECLARE @IlliquidityPremium float,
 @RAFactor float,
 @DefaultYield float,
 @MinYieldCurve date,
 @ApplicableEffectiveDate date,
 @ValuationMonth date,
 @Insurer varchar(20);

set @ValuationMonth = '01-Oct-2025';
set @Insurer = 'Hollard';

-- ***************************************************************************
-- Data fix for policies with no payment frequency value
--*****************************************************************************
Update						Evolve.dbo.[Policy]
Set							POL_PaymentFrequency_ID = Case
							When RTF_Description = 'Annual' Then '2'
							When RTF_Description like 'Term%' Then '3'
							Else null
							End
From						Evolve.dbo.[Policy] p 
							left join Evolve.dbo.ReferenceTermFrequency rtf
							on rtf.TermFrequency_Id = p.POL_ProductTerm_ID
Where						1 = 1
							and p.pol_Paymentfrequency_ID is null
							and p.POL_ProductTerm_ID <> 4 --- Exclude monthlies
							and p.POL_Status = 1; --- Fix for only in-force policies

-- Ascribe parameter values
Set                         @ApplicableEffectiveDate = (Select max(EffectiveDate) from basis where effectiveDate <= @ValuationMonth); 
Set							@IlliquidityPremium = (Select Val from basis where parameter = 'Illiquidity Premium' and effectiveDate = @ApplicableEffectiveDate);
Set							@RAFactor = (Select Val from basis where parameter = 'Risk Adjustment Factor' and effectiveDate = @ApplicableEffectiveDate);
Set							@DefaultYield = (Select Val from basis where parameter = 'Default Yield' and effectiveDate = @ApplicableEffectiveDate);
Set							@MinYieldCurve = (Select Val2 from basis where parameter = 'Minimum Yield Curve' and effectiveDate = @ApplicableEffectiveDate);


---- Clear previous results
Drop table if exists		#pol;
Drop table if exists		#pol2;
Drop table if exists		#pol3;
Drop table if exists		#pol4;
Drop table if exists		#pol5;
Drop table if exists		#pol6;
Drop table if exists		#pol7;
Drop table if exists		#pol8;
Drop table if exists		#pol9;
Drop table if exists		#pol10;
Drop table if exists		#pol11;
Drop table if exists		#phasing;
Drop table if exists		#IR0;
Drop table if exists		#IR1;
Drop table if exists		#mths;
Drop table if exists		#Results;
Drop table if exists		#belra0;
Drop table if exists		#belra1;
Drop table if exists		#belra2;
Drop table if exists		#belra3;
Drop table if exists		#belra4;
Drop table if exists		#belra5;
Drop table if exists		#BELRARollForward0;
Drop table if exists		#CSMLCAmortPercentages;
Drop table if exists		#CSMLCAmortisationSchedule;

-- Get Warranty Policies and Save in #Pol
Select						u.POL_PolicyNumber, 
							t.rtf_termPeriod,
							DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) StartMonth,
							DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) CreateMonth,
							CellCaptive,
							isnull(WW_Nett_Premium, Evolve_Nett_Premium) Premium,
							isnull(WW_Nett_Premium, Evolve_Nett_Premium) - isnull(ww_nett_fund, evolve_nett_fund) Disbursements,
							isnull(ww_nett_fund, evolve_nett_fund) Fund,
							u.INS_InsurerName Underwriter,
							Case when cp.PhasingCurve = '60M - Even ALL V0' and pv1.PRV_FullName not like '%Booster%' then 'Non-Booster 60'
							Else cp.CSMPhasing End CSMPhasingKey,
							isnull(u.PhasingCurve, '60M - Even ALL V0') PhasingCurve,
							pv1.PRV_FullName ProductCategory,
							pv1.ProductVariant_Id,
							Case when DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then
							DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) else DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) end IRMonth,
							Case when u.INS_InsurerName != 'Hollard Short Term' then year(Case when DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then
							DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) else DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) end)
							when month(Case when DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then
							DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) else DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) end) > 6 then
							 year(Case when DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then
							DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) else DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) end) + 1
							else  year(Case when DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then
							DATEADD(month, DATEDIFF(month, 0, isnull(c.pol_crt_date, u.POL_CreateDate)), 0) else DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) end)
							end GroupingYear,
							Case when t.rtf_termPeriod = 1 then 'Monthly' else 'Term' end PremiumFrequency,
							a.Agt_Name PrimaryAgent,
							sa.Agt_Name SecondaryAgent,
							a.Agt_AgentNumber PrimaryAgentNumber,
							sa.Agt_AgentNumber SecondaryAgentNumber,
							arg.ARG_Name ArrangementName,
							arg.ARG_ArrangementNumber,
							u.ValuationMonth
Into						#pol --11 027
From						[UPP].[dbo].[SAW_UPP_202510] u -->Update
							left join evolve.dbo.policy p
							on p.policy_id = u.policy_id
							left join evolve.dbo.ReferenceTermFrequency t
							on p.POL_ProductTerm_ID = t.TermFrequency_Id
							left join upp.dbo.csmphasing cp
							on cp.PhasingCurve = isnull(u.PhasingCurve, '60M - Even ALL V0')
							left join upp.dbo.wwcrt c
							on c.policy_key = u.WW_Policy_Key

							left join Evolve.dbo.ProductVariant pv1
							on pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID


							left join evolve.dbo.Agent a
							on p.POL_PrimaryAgent_ID = a.Agent_Id
							LEFT JOIN evolve.dbo.Agent sa 
							on (sa.Agt_Deleted = 0 AND sa.Agent_Id = p.POL_Agent_ID)
							left join Evolve.dbo.Arrangement arg
							on arg.Arrangement_Id = p.POL_Arrangement_ID
Where						1 = 1
							and u.INS_InsurerName = 'Hollard Short Term'
							and u.valuationMonth = @ValuationMonth   
							--	 and u.POL_PolicyNumber = 'HWTY095789POL' ;

-- Add other fields
Select						#pol.*,
							Dateadd(Month, case when rtf_termPeriod = 1 then 24 else rtf_termPeriod end - 1, StartMonth) ContractBoundary,
							pa.ExitRate, 
							pa.ExitRateFutureActive, 
							pa.BurnRate,
							pa.BurnRate * #pol.Fund ETotalClaims
Into						#pol2
From						#pol 
							left join ProductBasis pa
							on pa.Category = #pol.ProductVariant_Id
							and pa.PremiumFrequency = #pol.PremiumFrequency
Where                    pa.EffectiveDate = (Select MAX(effectiveDate) from ProductBasis where effectiveDate <= @ValuationMonth); --  pa.EffectiveDate = '2025-06-01';

-- Data fix
Update #pol2 set StartMonth = '2023-06-01 00:00:00.000', ContractBoundary = '2025-05-01 00:00:00.000' where pol_PolicyNumber = 'HWTY017579POL';
--select * from #pol2;
--***********************************************************
--Initial Recognition
--***********************************************************
With cte as					(
Select						#pol2.POL_PolicyNumber,
							#pol2.StartMonth,
							#pol2.ContractBoundary,
							#pol2.ExitRate,
							#pol2.ExitRateFutureActive,
							IRMonth Mth,
							1 RowN,
							case when IRMonth < #pol2.StartMonth then 0 else 1 end ExposureMonth,
							cast(1 as float) SurvStart,
							case when IRMonth < #pol2.StartMonth then 1 - #pol2.ExitRateFutureActive 
							else 1 - #pol2.ExitRate end SurvEnd
From						#pol2
Union all
Select						cte.POL_PolicyNumber,
							cte.StartMonth,
							cte.ContractBoundary,
							cte.ExitRate,
							cte.ExitRateFutureActive,
							DATEADD(month, 1, Mth) Mth,
							cte.RowN + 1 RowN,
							cte.ExposureMonth + case when DATEADD(month, 1, Mth) < cte.StartMonth then 0 else 1 end ExposureMonth,
							cte.SurvEnd SurvStart,
							cte.SurvEnd * case when DATEADD(month, 1, Mth) < cte.StartMonth then 1 - cte.ExitRateFutureActive
							else 1 - cte.ExitRate end SurvEnd
From						cte
Where						DATEADD(month, 1, Mth) <= cte.ContractBoundary
							)
Select						*
Into						#pol3
From						cte
--Option						(maxrecursion 200);
Option						(maxrecursion 0);
Create nonclustered index a on #pol3 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Add probability of withdrawal, EPremium, EDisbursements
Select						p3.*,
							p3.SurvStart * iif(p3.ExposureMonth = 0, p3.ExitRateFutureActive, p3.ExitRate) ProbWithdrawal,
							case when p3.ExposureMonth <= 1 then - p2.Premium else -p2.Premium * (p2.rtf_termPeriod - p3.ExposureMonth) * 1.000000 / p2.rtf_termPeriod end WithdrawalBenefit,
							iif(RowN = 1, Premium, 0) EPremium,
							iif(RowN = 1, -Disbursements, 0) EDisbursements 
Into						#pol4
From						#pol3 p3
							left join #pol2 p2
							on p3.Pol_PolicyNumber = p2.POl_PolicyNumber;
Create nonclustered index b on #pol4 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

--Add Phasing
Select						h.DCH_Name, 
							h.DCH_TermFrequency_Id, 
							DCI_Month, 
							DCI_MonthlyPercentage 
Into						#phasing
From						evolve.[dbo].[DisbursementCurveItem] i, 
							evolve.[dbo].[DisbursementCurveHeader] h
Where						i.DCI_DisbursementCurveHeader_Id = h.DisbursementCurveHeader_Id 
							and DCI_Deleted = 0;


-- Add Earned Portion to Policy Data
Select						#pol4.*, 
							isnull(#phasing.DCI_MonthlyPercentage, 0) * 1.000000 / 100 Phasing 
Into						#pol5
From						#pol4
							inner join #pol2
							on #pol2.POL_PolicyNumber = #pol4.POL_PolicyNumber
							left join #phasing
							on #phasing.DCH_Name = #pol2.PhasingCurve
							and #phasing.DCI_Month = #pol4.ExposureMonth;
Create nonclustered index c on #pol5 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Add Eclaims and Ewithdrawals
Select						#pol5.*,
							-#pol5.Phasing * ETotalClaims * SurvStart EClaims,
							ProbWithdrawal * WithdrawalBenefit EWithdrawal
Into						#pol6
From						#pol5
							left join #pol2
							on #pol2.Pol_PolicyNumber = #pol5.Pol_PolicyNumber;
Create nonclustered index d on #pol6 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Add forward rates
Select						#pol6.*,
							Dateadd(month, -1, IRMonth) LockedInYieldCurveMonth,
							case when Dateadd(month, -1, IRMonth) < @MinYieldCurve then @DefaultYield
							else r.nominalrate end + @IlliquidityPremium ForwardRateLockedIn
Into						#pol7
From						#pol6
							left join #pol2
							on #pol6.Pol_PolicyNumber = #pol2.Pol_PolicyNumber
							left join lpp.dbo.riskfreerates_history r
							on r.valuationdate = Dateadd(month, -1, IRMonth)
							and DATEADD(month, DATEDIFF(month, 0, r.todate), 0) = #pol6.Mth;
Create nonclustered index e on #pol7 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Add forward factor
Select						#pol7.*,
							Power(1 + ForwardRateLockedIn, -1.000000 / 12) ForwardFactor
Into						#pol8
From						#pol7;
Create nonclustered index f on #pol8 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Calculate the discount factor in arrears
Select						#pol8.*,
							exp(SUM(log(ForwardFactor)) over (Partition by Pol_PolicyNumber Order by RowN)) DF_Arrears
Into						#pol9
From						#pol8;
Create nonclustered index g on #pol9 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Calculate the discount factor in advance
Select						#pol9.*,
							isnull(lag(DF_Arrears, 1) over (Partition by Pol_PolicyNumber Order by RowN), 1) DF_Advance
Into						#pol10
From						#pol9;
Create nonclustered index h on #pol10 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Add the EPVs
Select						#pol10.*,
							DF_Advance * EPremium EPVFCI,
							DF_Advance * EDisbursements EPVDisbursements,
							DF_Arrears * EClaims EPVClaims,
							DF_Arrears * EWithdrawal EPVWithdrawal,
							DF_Advance * EDisbursements + DF_Arrears * EClaims + DF_Arrears * EWithdrawal EPVFCO
Into						#pol11
From						#pol10;
Create nonclustered index i on #pol11 (Pol_PolicyNumber) include (Mth, RowN, ExposureMonth);

-- Initial recognition amounts
Select						POL_PolicyNumber, 
							-sum(EPVFCI) AtIR_EPVFCI, 
							-sum(EPVFCO) AtIR_EPVFCO,
							-sum(EPVFCI) -sum(EPVFCO) AtIR_BEL,
							-sum(EPVClaims + EPVWithdrawal) * @RAFactor AtIR_RA,
							-sum(EPVClaims + EPVWithdrawal) * @RAFactor -sum(EPVFCI) -sum(EPVFCO) AtIR_FCF,
							-SUM(case when Rown = 1 then 0 else EPVDisbursements end)-SUM(EPVClaims)-SUM(EPVWithdrawal) IAIR_BEL,
							-sum(EPVClaims + EPVWithdrawal) * @RAFactor IAIR_RA,
							-SUM(case when Rown = 1 then 0 else EPVDisbursements end)-SUM(EPVClaims)-SUM(EPVWithdrawal)-sum(EPVClaims + EPVWithdrawal) * @RAFactor IAIR_FCF
Into						#IR0
From						#pol11 --where pol_policynumber = 'HWTYM000704POL'
Group by					POL_PolicyNumber;

-- Add the CSM and Loss Component
Select						#IR0.*,
							case when AtIR_FCF < 0 then -AtIR_FCF else 0 end AtIR_CSM,
							case when AtIR_FCF > 0 then -AtIR_FCF else 0 end AtIR_LossComponent,
							case when AtIR_FCF < 0 then -AtIR_FCF else 0 end IAIR_CSM,
							case when AtIR_FCF > 0 then -AtIR_FCF else 0 end IAIR_LC
Into						#IR1
From						#IR0;
-- Intermediate garbage collection
Drop table if exists		#pol3;
Drop table if exists		#pol4;
Drop table if exists		#pol5;
Drop table if exists		#pol6;
Drop table if exists		#pol7;
Drop table if exists		#pol8;
Drop table if exists		#pol9;
Drop table if exists		#pol10;


-- Create valuation months
With cte as					(
Select						MIN(IRMonth) ValuationMonth
From						#pol2
Union all
Select						DATEADD(month, 1, ValuationMonth) ValuationMonth
From						cte
Where						DATEADD(month, 1, ValuationMonth) <= @ValuationMonth
							)
Select						*
Into						#mths
From						cte
--Option						(maxrecursion 200);
Option						(maxrecursion 0);
-- Combine valuation months with #pol2 and #pol11 data
Select						t.Pol_PolicyNumber
							, #mths.ValuationMonth ValuationMonth
							, t.CellCaptive
							, t.Premium
							, t.Disbursements
							, t.Fund
							, t.Underwriter
							, t.CSMPhasingKey
							, t.PhasingCurve
							, t.ProductCategory
							, t.IRMonth
							, Dateadd(month, -1, t.IRMonth) LockedInYieldCurveMonth
							, t.GroupingYear
							, t.PremiumFrequency
							, t.ContractBoundary
							, t.ExitRate
							, ISNULL(t.ExitRateFutureActive, 0) as ExitRateFutureActive
							, t.BurnRate
							, t.ETotalClaims
							, i.RowN
							, i.ExposureMonth
							, i.Mth CalendarMonth
							, i.WithdrawalBenefit
Into						#belra0
From						#pol2 t
							cross join #mths
							left join #pol11 i
							on i.Pol_PolicyNumber = t.Pol_PolicyNumber  
							
Where						#mths.ValuationMonth >= t.IRMonth
							and #mths.ValuationMonth <= @ValuationMonth  
							and i.Mth > #mths.ValuationMonth;
--and #mths.ValuationMonth = @ValuationMonth


--SELECT TOP 10 Pol_PolicyNumber, ExitRate, ExitRateFutureActive
--FROM #belra0;

Create index				b0 on #belra0 (Pol_PolicyNumber, ValuationMonth, CalendarMonth);


--select * from #belra0 where ValuationMonth = '2025-06-01 00:00:00.000'

--********************************************************************
--Multiple Decrement Table
--********************************************************************
Select						b.*,
							Case when ExposureMonth = 0 then 1 - ExitRateFutureActive 
							Else 1 - ExitRate End P_NotExit,
							exp(Sum(log(Case when ExposureMonth = 0 then 1 - ExitRateFutureActive 
							Else 1 - ExitRate End)) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth)) SurvEnd
Into						#belra1
--select *
From						#belra0 b
--where ValuationMonth = '2025-06-01 00:00:00.000'
;


--SELECT TOP 5 ExitRateFutureActive FROM #belra0;

Create index				b1 on #belra1 (Pol_PolicyNumber, ValuationMonth, CalendarMonth);
Drop table if exists		#belra0;


-- Add SurvStart, Exits, Pr(Withdrawal)
Select						b.*,
							1 - P_NotExit Exits,
							isnull(lag(SurvEnd, 1) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth), 1) SurvStart,
							isnull(lag(SurvEnd, 1) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth), 1) * (1 - P_NotExit) PrWithdrawal,
							Case when PremiumFrequency = 'Term' then 0 else 
							isnull(lag(SurvEnd, 1) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth), 1) * Premium End EPremium,
							Case when PremiumFrequency = 'Term' then 0 else 
							isnull(lag(SurvEnd, 1) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth), 1) * Disbursements End EDisbursements,
							isnull(lag(SurvEnd, 1) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth), 1) * (1 - P_NotExit) * WithdrawalBenefit EWithdrawals,
							Case when b.ExposureMonth = 0 then 0 else - isnull(lag(SurvEnd, 1) over (Partition by POL_PolicyNumber, ValuationMonth Order by CalendarMonth), 1) * ETotalClaims 
							* p.DCI_MonthlyPercentage * 1.000000 / 100 End EClaims,
							Iif(b.ValuationMonth < @MinYieldCurve, @DefaultYield, rCurr.nominalrate) + @IlliquidityPremium CurrentCurve,
							Iif(Dateadd(month, -1, b.ValuationMonth) < @MinYieldCurve, @DefaultYield, rPrev.nominalrate) + @IlliquidityPremium PreviousCurve,
							Iif(b.LockedInYieldCurveMonth < @MinYieldCurve, @DefaultYield, rLocked.nominalrate) + @IlliquidityPremium LockedInCurve,
							Power(1 + Iif(b.ValuationMonth < @MinYieldCurve, @DefaultYield, rCurr.nominalrate) + @IlliquidityPremium, -1.000000 / 12) ForwardFactor_CurrentCurve,
							Power(1 + Iif(Dateadd(month, -1, b.ValuationMonth) < @MinYieldCurve, @DefaultYield, rPrev.nominalrate) + @IlliquidityPremium, -1.000000 / 12) ForwardFactor_PreviousCurve,
							Power(1 + Iif(b.LockedInYieldCurveMonth < @MinYieldCurve, @DefaultYield, rLocked.nominalrate) + @IlliquidityPremium, -1.000000 / 12) ForwardFactor_LockedInCurve
Into						#belra2
From						#belra1 b
							left join #phasing p
							on b.PhasingCurve = p.DCH_Name
							and b.ExposureMonth = p.DCI_Month
							left join lpp.dbo.riskfreerates_history rCurr
							on rCurr.valuationdate = b.ValuationMonth
							and DATEADD(month, DATEDIFF(month, 0, rCurr.todate), 0) = b.CalendarMonth
							left join lpp.dbo.riskfreerates_history rPrev
							on rPrev.valuationdate = Dateadd(month, -1, b.ValuationMonth)
							and DATEADD(month, DATEDIFF(month, 0, rPrev.todate), 0) = b.CalendarMonth
							left join lpp.dbo.riskfreerates_history rLocked
							on rLocked.valuationdate = b.LockedInYieldCurveMonth
							and DATEADD(month, DATEDIFF(month, 0, rLocked.todate), 0) = b.CalendarMonth;
Create index				b2 on #belra2 (Pol_PolicyNumber, ValuationMonth, CalendarMonth);
Drop table if exists		#belra1;

-- Add discount factors in arrears
Select						b.*,
							EXP(SUM(log(b.ForwardFactor_CurrentCurve)) over (PARTITION by b.POL_PolicyNumber, b.ValuationMonth Order by b.CalendarMonth)) DFArrears_CurrentCurve,
							EXP(SUM(LOG(b.ForwardFactor_PreviousCurve)) over (PARTITION by b.POL_PolicyNumber, b.ValuationMonth Order by b.CalendarMonth)) DFArrears_PreviousCurve,
							EXP(SUM(LOG(b.ForwardFactor_LockedInCurve)) over (PARTITION by b.POL_PolicyNumber, b.ValuationMonth Order by b.CalendarMonth)) DFArrears_LockedInCurve
Into						#belra3
From						#belra2 b;
Create index				b3 on #belra3 (Pol_PolicyNumber, ValuationMonth, CalendarMonth);
Drop table if exists		#belra2;

-- Add discount factor in advance
Select						b.*,
							Isnull(lag(DFArrears_CurrentCurve, 1) over (Partition by b.POL_PolicyNumber, b.ValuationMonth Order by b.CalendarMonth), 1) DFAdvance_CurrentCurve,
							Isnull(lag(DFArrears_PreviousCurve, 1) over (Partition by b.POL_PolicyNumber, b.ValuationMonth Order by b.CalendarMonth), 1) DFAdvance_PreviousCurve,
							Isnull(lag(DFArrears_LockedInCurve, 1) over (Partition by b.POL_PolicyNumber, b.ValuationMonth Order by b.CalendarMonth), 1) DFAdvance_LockedInCurve
Into						#belra4
From						#belra3 b;
Create index				b4 on #belra4 (Pol_PolicyNumber, ValuationMonth, CalendarMonth);
Drop table if exists		#belra3;


-- Finally, add BEL and RA
Select						b.*,
							-((b.EPremium + b.EDisbursements) * b.DFAdvance_CurrentCurve + (b.EClaims + b.EWithdrawals) * b.DFArrears_CurrentCurve) BEL_CurrentCurve,
							-((b.EPremium + b.EDisbursements) * b.DFAdvance_PreviousCurve + (b.EClaims + b.EWithdrawals) * b.DFArrears_PreviousCurve) BEL_PreviousCurve,
							-((b.EPremium + b.EDisbursements) * b.DFAdvance_LockedInCurve + (b.EClaims + b.EWithdrawals) * b.DFArrears_LockedInCurve) BEL_LockedInCurve,
							-(b.EClaims + b.EWithdrawals) * b.DFArrears_CurrentCurve * 0.10 RA_CurrentCurve,
							-(b.EClaims + b.EWithdrawals) * b.DFArrears_PreviousCurve * 0.10 RA_PreviousCurve,
							-(b.EClaims + b.EWithdrawals) * b.DFArrears_LockedInCurve * 0.10 RA_LockedInCurve,
							Case when b.ValuationMonth = Dateadd(month, 1, ir.LockedInYieldCurveMonth) then 
							(b.EPremium - ir.EPremium) * b.DFAdvance_LockedInCurve 
							Else
							(b.EPremium - bPrev.EPremium) * b.DFAdvance_LockedInCurve 
							End    CRTFS_Premium,
							Case when b.ValuationMonth = Dateadd(month, 1, ir.LockedInYieldCurveMonth) then 
							(b.EDisbursements - ir.EDisbursements) * b.DFAdvance_LockedInCurve 
							Else
							(b.EDisbursements - bPrev.EDisbursements) * b.DFAdvance_LockedInCurve 
							End CRTFS_Disbursements,
							Case when b.ValuationMonth = Dateadd(month, 1, ir.LockedInYieldCurveMonth) then 
							(b.EClaims - ir.EClaims) * b.DFArrears_LockedInCurve 
							Else
							(b.EClaims - bPrev.EClaims) * b.DFArrears_LockedInCurve 
							End CRTFS_Claims,
							Case when b.ValuationMonth = Dateadd(month, 1, ir.LockedInYieldCurveMonth) then 
							(b.EWithdrawals - ir.EWithdrawal) * b.DFArrears_LockedInCurve 
							Else
							(b.EWithdrawals - bPrev.EWithdrawals) * b.DFArrears_LockedInCurve--DFAdvance_LockedInCurve 
							End CRTFS_Withdrawals
Into						#belra5
From						#belra4 b
							left join #belra4 bPrev
							on b.Pol_PolicyNumber = bPrev.Pol_PolicyNumber
							and bPrev.ValuationMonth = Dateadd(month, -1, b.ValuationMonth)
							and b.CalendarMonth = bPrev.CalendarMonth
							left join #pol11 ir
							on ir.POL_PolicyNumber = b.Pol_PolicyNumber
							and ir.Mth = b.CalendarMonth;
Create index				b5 on #belra5 (Pol_PolicyNumber, ValuationMonth, CalendarMonth, ExposureMonth);

-- Add level of cover, coverage units and the CSMLC amortisation
Select                      t.*,
                            t.CoverageUnits * 1.000000 / case when (SUM(t.CoverageUnits) over (PARTITION by t.POL_PolicyNumber, t.ValuationMonth Order by t.CalendarMonth 
                            Rows between CURRENT ROW and unbounded following)) = 0 then 1 else
                            (SUM(t.CoverageUnits) over (PARTITION by t.POL_PolicyNumber, t.ValuationMonth Order by t.CalendarMonth 
                            Rows between CURRENT ROW and unbounded following)) end AmortizationProportion
Into                        #CSMLCAmortPercentages
From                        
(Select                     b.POL_PolicyNumber,
                            b.CSMPhasingKey,
                            b.ExposureMonth,
                            b.ValuationMonth,
                            b.CalendarMonth,
                            ISNULL(c.LevelOfCover, 0) LevelOfCover,
                            b.SurvStart,
                            ISNULL(c.LevelOfCover, 0) * b.SurvStart CoverageUnits
From                        #belra5 b
                            left join CoverageUnits c
                            on b.CSMPhasingKey = c.CSMPhasingKey
                            and b.ExposureMonth = c.ExposureMonth 
Union
Select                      p.Pol_PolicyNumber,
                            n.CSMPhasingKey,
                            p.ExposureMonth,
                            p.Mth ValuationMonth,
                            p.Mth CalendarMonth,
                            ISNULL(c.LevelOfCover, 0) LevelOfCover,
                            CAST(1 as float) SurvStart,
                            ISNULL(c.LevelOfCover, 0) CoverageUnits
From                        #pol11 p
                            left join #pol2 n
                            on n.Pol_PolicyNumber = p.POL_PolicyNumber
                            left join CoverageUnits c
                            on n.CSMPhasingKey = c.CSMPhasingKey
                            and p.ExposureMonth = c.ExposureMonth) as t
                            ;
CREATE NONCLUSTERED INDEX	ff
ON							#CSMLCAmortPercentages ([POL_PolicyNumber],[ValuationMonth])
INCLUDE						([CalendarMonth],[AmortizationProportion]);

-- Table for the BEL and RA Roll forward needed to determine the CSM roll forward
Select	 					POL_PolicyNumber,
							ValuationMonth,
							sum(BEL_CurrentCurve) BEL_CurrentCurve,
							sum(BEL_PreviousCurve) BEL_PreviousCurve,
							sum(BEL_LockedInCurve) BEL_LockedInCurve,
							sum(RA_CurrentCurve) RA_CurrentCurve,
							sum(RA_PreviousCurve) RA_PreviousCurve,
							sum(RA_LockedInCurve) RA_LockedInCurve,
							sum(CRTFS_Premium + CRTFS_Disbursements + CRTFS_Claims + CRTFS_Withdrawals) CRTFS_BEL,
							sum(CRTFS_Claims + CRTFS_Withdrawals) * @RAFactor CRTFS_RA
Into						#BELRARollForward0
From						#belra5
Group by					POL_PolicyNumber,
							ValuationMonth;

-- CSM Amort
With cte as					(
Select						ir.POL_PolicyNumber,
							p2.CellCaptive,
							p2.Underwriter,
							p2.ProductCategory,
							p2.ContractBoundary,
							p11.ForwardRateLockedIn,
							cast(1 as int) RowN,
							p11.ExposureMonth,
							p2.IRMonth CalendarMonth,
							dbo.TotalCRTFS(b.CRTFS_BEL, b.CRTFS_RA) CRTFS,
							c.AmortizationProportion Amort,
							ir.IAIR_CSM OB_CSM,
							ir.IAIR_LC OB_LC,
							dbo.InterestAccreted(ir.IAIR_CSM, p11.ForwardRateLockedIn) IR_CSM,
							dbo.InterestAccreted(ir.IAIR_LC, p11.ForwardRateLockedIn) IR_LC,
							dbo.CalculateCRTFS_CSM(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) CRTFS_CSM,
							dbo.CalculateCRTFS_LC(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) CRTFS_LC,
							dbo.CalculateBalanceBeforeAmort_CSM(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) BB_Amort_CSM,
							dbo.CalculateBalanceBeforeAmort_LC(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) BB_Amort_LC,
							dbo.Amortisation_CSM(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) Amort_CSM,
							dbo.Amortisation_LC(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) Amort_LC,
							dbo.ClosingBalance_CSM(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) CB_CSM,
							dbo.ClosingBalance_LC(ir.IAIR_CSM, ir.IAIR_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) CB_LC							
From						[dbo].[#IR1]	 ir
							left Join #pol2 p2
							on ir.POL_PolicyNumber = p2.POL_PolicyNumber
							left join #BELRARollForward0 b
							on b.Pol_PolicyNumber = p2.[POL_PolicyNumber] 
							and b.ValuationMonth = p2.IRMonth
							left join #CSMLCAmortPercentages c
							on	c.POL_PolicyNumber = p2.[POL_PolicyNumber] 
							and c.ValuationMonth = c.CalendarMonth 
							and c.ValuationMonth = p2.IRMonth
							left join #pol11 p11
							on p11.POL_PolicyNumber = p2.[POL_PolicyNumber] 
							and  p11.Mth = p2.IRMonth 
Union all
Select						cte.POL_PolicyNumber,
							cte.CellCaptive,
							cte.Underwriter,
							cte.ProductCategory,
							cte.ContractBoundary,
							p11.ForwardRateLockedIn ForwardRateLockedIn,
							cte.Rown + 1 Rown,
							p11.ExposureMonth,
							Dateadd(month, 1, cte.CalendarMonth) CalendarMonth,
							b.CRTFS_BEL + b.CRTFS_RA CRTFS,
							c.AmortizationProportion Amort,
							cte.CB_CSM OB_CSM,
							cte.CB_LC OB_LC,
							dbo.InterestAccreted(cte.CB_CSM, p11.ForwardRateLockedIn) IR_CSM,
							dbo.InterestAccreted(cte.CB_LC, p11.ForwardRateLockedIn) IR_LC,
							dbo.CalculateCRTFS_CSM(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) CRTFS_CSM,
							dbo.CalculateCRTFS_LC(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) CRTFS_LC,
							dbo.CalculateBalanceBeforeAmort_CSM(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) BB_Amort_CSM,
							dbo.CalculateBalanceBeforeAmort_LC(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn) BB_Amort_LC,
							dbo.Amortisation_CSM(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) Amort_CSM,
							dbo.Amortisation_LC(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) Amort_LC,
							dbo.ClosingBalance_CSM(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) CB_CSM,
							dbo.ClosingBalance_LC(cte.CB_CSM, cte.CB_LC, b.CRTFS_BEL + b.CRTFS_RA, p11.ForwardRateLockedIn, c.AmortizationProportion) CB_LC
From						cte
							inner join #pol11 p11
on							p11.POL_PolicyNumber = cte.[POL_PolicyNumber] and p11.Mth = Dateadd(month, 1, cte.CalendarMonth) 
							inner join #BELRARollForward0 b
on							b.Pol_PolicyNumber = cte.[POL_PolicyNumber] and b.ValuationMonth = Dateadd(month, 1, cte.CalendarMonth)
							inner join	#CSMLCAmortPercentages c
on							c.POL_PolicyNumber = cte.[POL_PolicyNumber] and c.ValuationMonth = c.CalendarMonth and c.ValuationMonth = Dateadd(month, 1, cte.CalendarMonth)
Where						Dateadd(month, 1, cte.CalendarMonth) <= cte.ContractBoundary
							)
Select						*
Into						#CSMLCAmortisationSchedule
From						cte	
--Option						(maxrecursion 200); 
Option						(maxrecursion 0); 
-- Summary Results
Select						i.Pol_PolicyNumber,
							i.AtIR_EPVFCI,
							i.AtIR_EPVFCO,
							i.AtIR_BEL,
							i.AtIR_RA,
							i.AtIR_FCF,
							i.AtIR_CSM,
							i.AtIR_LossComponent,
							i.IAIR_BEL,
							i.IAIR_RA,
							i.IAIR_CSM,
							i.IAIR_LC,
							isnull(b.BEL_CurrentCurve, 0) SM_BEL,
							isnull(b.RA_CurrentCurve, 0) SM_RA,
							isnull(c.CB_CSM, 0) SM_CSM,
							isnull(-c.CB_LC, 0) SM_LC,
							case when ir_lc < 0 then 1 else 0 end OnerousAtIR,
							p2.Underwriter,
							p2.GroupingYear,
							p2.CellCaptive,
							p2.PrimaryAgentNumber,
							p2.SecondaryAgentNumber,
							p2.ARG_ArrangementNumber
Into						#Results
From						#IR1 i
							left join #BELRARollForward0 b
							on b.Pol_PolicyNumber = i.POL_PolicyNumber
							and b.ValuationMonth = @ValuationMonth
							left join #CSMLCAmortisationSchedule c
							on c.POL_PolicyNumber = i.POL_PolicyNumber
							and c.CalendarMonth = @ValuationMonth
							left join #pol2 p2
							on p2.POL_PolicyNumber = i.POL_PolicyNumber
Where						1 = 1
							and b.ValuationMonth = @ValuationMonth;
Select * from #Results;
--Select * from #IR1;
--Select * from #BELRARollForward0;
--select * from #pol;
-- Data set for cashflows to be supplied on the SFTP site
--Select						
----b.Pol_PolicyNumber,
----							b.ValuationMonth,
----							CellCaptive,
----							Underwriter,
----							b.CSMPhasingKey,
----							PhasingCurve,
----							ProductCategory,
----							IRMonth,
----							LockedInYieldCurveMonth,
----							GroupingYear,
----							PremiumFrequency,
----							ContractBoundary,
----							b.ExposureMonth,
----							b.CalendarMonth,
----							b.SurvStart,
----							SurvEnd,
----							EPremium,
----							EWithdrawals,
----							EDisbursements,
----							EClaims,
----							LockedInCurve,
----							CurrentCurve,
----							c.LevelOfCover,
----							c.CoverageUnits,
----							c.AmortizationProportion,
----							Case
----								When CellCaptive = 'Auto Pedigree' Then '01-HPS-IW-WW-AP1-81-WAP'
----								When CellCaptive = 'CMH' Then '01-HPS-IW-WW-CMH-81-WCM'
----								When CellCaptive = 'Motus OEM' Then '01-HPS-IW-WW-IMP-81-WIM'
----								When CellCaptive = 'IEMAS' Then '01-HPS-IW-WW-IET-81-WIE'
----								When CellCaptive = 'M-Sure Mobility' Then '01-HPS-IW-WW-ELS-81-WEL'
----								When CellCaptive = 'Master Cell' Then '01-HPS-IW-WW-000-81-W00'
----								When CellCaptive = 'Kempston Group' Then '01-HPS-IW-WW-KMG-81-WKM'
----								When CellCaptive = 'Wesbank (WESB)' Then '01-HPS-IW-WW-WPI-81-WW3'
----								When CellCaptive = 'Maritime Motors' Then '01-HPS-IW-WW-MTM-81-WMT'
----								When CellCaptive = 'Meyers Group' Then '01-HPS-IW-WW-MEY-81-WME'
----								When CellCaptive = 'Motus Imports' Then '01-HPS-IW-WW-AMH-81-WAM'
----								Else Null
----							End IFRS_Group
----select *
--	b.Pol_PolicyNumber,
--							b.ValuationMonth,
--							b.ExitRate,
--							b.ExitRateFutureActive,
--							b.ExposureMonth,
--							b.RowN,
--							b.PrWithdrawal
--							CellCaptive,
--							Underwriter,
--							b.CSMPhasingKey,
--							PhasingCurve,
--							ProductCategory,
--							IRMonth,
--							LockedInYieldCurveMonth,
--							GroupingYear,
--							PremiumFrequency,
--							ContractBoundary,
--							--b.ExposureMonth,
--							b.CalendarMonth,
--							b.SurvStart,
--							--B.PrWithdrawal,
--							B.WithdrawalBenefit,
--							--B.EPremium,
--						--	B.EDisbursements,
--							B.ForwardFactor_CurrentCurve, B.ForwardFactor_LockedInCurve, B.ForwardFactor_PreviousCurve,
--							B.DFArrears_CurrentCurve, B.DFArrears_LockedInCurve, B.DFArrears_PreviousCurve,
--							B.DFAdvance_CurrentCurve, B.DFAdvance_LockedInCurve, B.DFAdvance_PreviousCurve,
--							--B.EClaims, B.ETotalClaims,
						
--							SurvEnd,
--							EPremium,
--							EWithdrawals,
--							EDisbursements,
--							EClaims,
--							LockedInCurve,
--							CurrentCurve,
--							c.LevelOfCover,
--							c.CoverageUnits,
--							c.AmortizationProportion,
--							Case
--								When CellCaptive = 'Auto Pedigree' Then '01-HPS-IW-WW-AP1-81-WAP'
--								When CellCaptive = 'CMH' Then '01-HPS-IW-WW-CMH-81-WCM'
--								When CellCaptive = 'Motus OEM' Then '01-HPS-IW-WW-IMP-81-WIM'
--								When CellCaptive = 'IEMAS' Then '01-HPS-IW-WW-IET-81-WIE'
--								When CellCaptive = 'M-Sure Mobility' Then '01-HPS-IW-WW-ELS-81-WEL'
--								When CellCaptive = 'Master Cell' Then '01-HPS-IW-WW-000-81-W00'
--								When CellCaptive = 'Kempston Group' Then '01-HPS-IW-WW-KMG-81-WKM'
--								When CellCaptive = 'Wesbank (WESB)' Then '01-HPS-IW-WW-WPI-81-WW3'
--								When CellCaptive = 'Maritime Motors' Then '01-HPS-IW-WW-MTM-81-WMT'
--								When CellCaptive = 'Meyers Group' Then '01-HPS-IW-WW-MEY-81-WME'
--								When CellCaptive = 'Motus Imports' Then '01-HPS-IW-WW-AMH-81-WAM'
--								Else Null
--							End IFRS_Group
--From						#belra5 b
--							left join [UPP].[dbo].[#CSMLCAmortPercentages] c
--							on b.Pol_PolicyNumber = c.POL_PolicyNumber
--							and b.ValuationMonth = c.ValuationMonth
--							and b.CalendarMonth = c.CalendarMonth
--Where						b.ValuationMonth = @ValuationMonth
--order by					b.pol_policynumber,
--							b.calendarmonth;

-- Information to be pasted in the Data sheet
select						#pol.* 
From						#pol
							inner join #Results
							on #pol.POL_PolicyNumber = #Results.Pol_PolicyNumber;

------ Information to be pasted in the Model sheet
--Select						*
--From						#Results;

---- Initial Recognition Data to be supplied on the SFTP site
--Select						*,
--							Case
--								When t.CellCaptive = 'Auto Pedigree' Then '01-HPS-IW-WW-AP1-81-WAP'
--								When t.CellCaptive = 'CMH' Then '01-HPS-IW-WW-CMH-81-WCM'
--								When t.CellCaptive = 'Motus OEM' Then '01-HPS-IW-WW-IMP-81-WIM'
--								When t.CellCaptive = 'IEMAS' Then '01-HPS-IW-WW-IET-81-WIE'
--								When t.CellCaptive = 'M-Sure Mobility' Then '01-HPS-IW-WW-ELS-81-WEL'
--								When t.CellCaptive = 'Master Cell' Then '01-HPS-IW-WW-000-81-W00'
--								When t.CellCaptive = 'Kempston Group' Then '01-HPS-IW-WW-KMG-81-WKM'
--								When t.CellCaptive = 'Wesbank (WESB)' Then '01-HPS-IW-WW-WPI-81-WW3'
--								When t.CellCaptive = 'Maritime Motors' Then '01-HPS-IW-WW-MTM-81-WMT'
--								When t.CellCaptive = 'Meyers Group' Then '01-HPS-IW-WW-MEY-81-WME'
--								When t.CellCaptive = 'Motus Imports' Then '01-HPS-IW-WW-AMH-81-WAM'
--								Else Null
--							End IFRSGroup
--From						#IR1 i
--							left join (Select distinct POL_PolicyNumber, CellCaptive from #pol) as t
--							on i.POL_PolicyNumber = t.POL_PolicyNumber
--							inner join #Results
--							on t.POL_PolicyNumber = #Results.Pol_PolicyNumber;
							

