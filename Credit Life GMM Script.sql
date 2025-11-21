USE [Evolve] -- Change to IFRS2 database as needed
GO

--**********************************************************************
--This procedure must be run on the IFRS2 database
--**********************************************************************
-- Set your validation parameters here
DECLARE @ValuationMonth date = '2025-10-01' -- Set your valuation month
DECLARE @Insurer varchar(20) = 'Hollard' -- 'Hollard', 'Centriq', or 'All'
--DECLARE @TestPolicyNumber varchar(50) = 'HCLL051025POL' -- Set specific policy for testing

-- Declare variables
Declare					--	@TakeonMonth date = '01-Sep-2023',
							--@FYend date = '01-Jun-2024',
							@Spread float = 0.01,
							@ProbBalloon float = 0.6,
							@BalloonProportion float = 0.3,
							@MortalityFactor float = 0.80,
							@AIDSFactor float = 0.025,
							@CriticalIllnessFactor float = 0.168,
							@PermanentDisabilityFactor float = 0.1503,
							@RetrenchmentCoverStartMonth int = 4,
							@NumberOfInstalments int = 6,
							@RetrenchmentProb float = 0.000416667,
							@TempDisProb float = 0.0000151679,
							@DefaultYield float = 0.06,
							@IlliquidityPremium float = 0.00,
							@MinimumBenefitStartMonth int = 37,
							@MinimumBenefitThreshold float = 30000,
							@PercOfPrincipalDebt float = 0.20,
							@DoubleBenefitStartMonth int = 25,
							@DisbursementsHollard float = 0.29,
							@DisbursementsCentriq float = 0.2475,
							@PercCashback float = 0.10,
							@MinimumYieldCurveMonth date = '01-Jan-2015',
							@RAFactor float = 0.1;



-- Clear previous results-- Drop tables
Drop table if exists		ifrs2.dbo.policy_info1;
Drop table if exists		lppProbs1;
Drop table if exists		lppProbs2;
Drop table if exists		lppProbs3;
Drop table if exists		lppIR1;
Drop table if exists		lppTakeonIRData;
Drop table if exists		#pol;
Drop table if exists		#lppProbs1_;
Drop table if exists		#lppProbs3b;
Drop table if exists		#lppProbs4;
Drop table if exists		#lppInstallmentBenefits1;
Drop table if exists		#lppInstallmentBenefits2;
Drop table if exists		#lppInstallmentBenefits3;
Drop table if exists		#lppInstallmentBenefits4;
Drop table if exists		#lppInstallmentBenefits1_;
Drop table if exists		#lppInstallmentBenefits2_;
Drop table if exists		#lppInstallmentBenefits3_;
Drop table if exists		#lppInstallmentBenefits4_;
Drop table if exists		#lppFCF;
Drop table if exists		#lppFCF2;
Drop table if exists		#lppFCF3;
Drop table if exists		#lppFCF4;
Drop table if exists		#lppFCF4A;
Drop table if exists		#lppFCF_;
Drop table if exists		#lppFCF2_;
Drop table if exists		#lppFCF3_;
Drop table if exists		#lppFCF4_;
Drop table if exists		#lppFCF4A_;
Drop table if exists		#lppFCF4B_;
Drop table if exists		lppTakeonSMDataAggregated;
Drop table if exists		lppTakeonSMData;
Drop table if exists		lppTakeonMovements;
Drop table if exists		#mths;
Drop table if exists		#lppProbs1_;
Drop table if exists		#lppProbs3b_;
Drop table if exists		#lppProbs1__;
Drop table if exists		#lppProbs4_SM;
Drop table if exists		#lppProbs3_;
Drop table if exists		#lppFCF4C_;
Drop table if exists		#lppBELRA1;
Drop table if exists		#lppBELRA2;
Drop table if exists		#lppBELRA3;
Drop table if exists		#lppBELRA4;
Drop table if exists		amort;
Drop table if exists		CSMLCAmortisationSchedule;

-- Get Credit life Policies and Save in #pol
--***********************************************************
--Initial Recognition on Takeon Policies
--***********************************************************
--DECLARE @ValuationMonth date = '2025-10-01'; -- Set your valuation month

--Get the policies as at the takeon month
With t as					( -- information as at the takeon month
Select						* 
From						lpp.dbo.policy_info_history 
Where						valuation_month = @ValuationMonth		
							and cease_date > eomonth(@ValuationMonth, 0) -- Policy still has remaining coverage
							and startdate <= eomonth(@ValuationMonth, 0) -- Policy must have started
               --             and policy_no = @TestPolicyNumber
							)
Select						* 
Into						#pol
From						t; 

--select * from #pol --3540

Create index				i1 on #pol (Policy_no);

---- Select only the fields required for the calculations
--DECLARE @ValuationMonth date = '2025-10-01' -- Set your valuation month
--DECLARE @Insurer varchar(20) = 'Hollard' -- 'Hollard', 'Centriq', or 'All'

if( @Insurer = 'Hollard')

Begin

WITH DuplicatePolicyholders AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Policynumber ORDER BY Balloon DESC) AS rn
    FROM [lpp].[dbo].[PolInfoLPP] p
    WHERE valuation_month = @ValuationMonth
      AND CeaseDate > EOMONTH(@ValuationMonth, 0)
      AND StartMonth <= EOMONTH(@ValuationMonth, 0)
      AND p.[Underwriter] = 'Hollard'
     -- AND Balloon > 0
)
SELECT *
INTO ifrs2.dbo.policy_info1
FROM DuplicatePolicyholders
WHERE rn = 1;


end 




--else 

--if( @Insurer = 'Centriq') 


--Begin

--Select					*
--Into						policy_info1
--From						[lpp].[dbo].[PolInfoLPP] p

--Where						1 = 1
--							and  valuation_month = @ValuationMonth		
--							and CeaseDate > eomonth(@ValuationMonth, 0) -- Policy still has remaining coverage
--							and StartMonth <= eomonth(@ValuationMonth, 0) 
--							and p.[Underwriter] = 'Centriq'
--							--and p.policy_no in ('HCLL002516POL')
--							;

--end 


--else 


--Begin

--Select					*
--Into						policy_info1
--From						[lpp].[dbo].[PolInfoLPP] p

--Where						1 = 1
--							and  valuation_month = @ValuationMonth		
--							and CeaseDate > eomonth(@ValuationMonth, 0) -- Policy still has remaining coverage
--							and StartMonth <= eomonth(@ValuationMonth, 0) 
--						--	and p.[Underwriter] = 'Centriq'
--							--and p.policy_no in ('HCLL002516POL')
--							;

--end 


--select * from  policy_info1 end
select * from ifrs2.dbo.policy_info1
--Declare					--	@TakeonMonth date = '01-Sep-2023',
							--@FYend date = '01-Jun-2024',
--							@Spread float = 0.01,
--							@ProbBalloon float = 0.6,
--							@BalloonProportion float = 0.3;
/* Loan amortization and age of insured lives */
Exec						ifrs2.dbo.ComputeLoanAmortisation @ProbBalloon = @ProbBalloon, @BalloonProportion = @BalloonProportion, @Spread = @Spread; -- Results saved in lppProbs1
---- Add the expected capital values

--Declare					--	@TakeonMonth date = '01-Sep-2023',
							--@FYend date = '01-Jun-2024',
--							@Spread float = 0.01,
--							@ProbBalloon float = 0.6,
--							@BalloonProportion float = 0.3;
Select						l.*
						, Case when p.DataEnriched = 0 then
						@ProbBalloon * CB_balloon +	(1 - @ProbBalloon) * CB_NOballoon
						when (p.DataEnriched = 1 and isnull(p.Balloon, 0) = 0) then
						 CB_NOballoon
						else
						CB_balloon
						end E_CB
						, Case when p.DataEnriched = 0 then
						@ProbBalloon * OB_balloon +	(1 - @ProbBalloon) * OB_NOballoon
						when (p.DataEnriched = 1 and isnull(p.Balloon, 0) = 0) then
						 OB_NOballoon
						else
						OB_balloon
						end E_OB
						, Case when p.DataEnriched = 0 then
						@ProbBalloon * pymt_balloon +	(1 - @ProbBalloon) * pymt_NOBalloon
						when (p.DataEnriched = 1 and isnull(p.Balloon, 0) = 0) then
						 pymt_NOBalloon
						else
						pymt_balloon
						end E_Installment
Into					#lppProbs1_
From					ifrs2.dbo.lppProbs1 l --257280
						left join ifrs2.dbo.policy_info1 p
						on p.PolicyNumber = l.PolicyNumber;

/* Add joint life mortality rates, critical illness and PD probabilities*/
-- Declare					--	@TakeonMonth date = '01-Sep-2023',
-- 							--@FYend date = '01-Jun-2024',
-- 							@Spread float = 0.01,
-- 							@ProbBalloon float = 0.6,
-- 							@BalloonProportion float = 0.3,
-- 							@MortalityFactor float = 0.80,
-- 							@AIDSFactor float = 0.025,
-- 							@CriticalIllnessFactor float = 0.168,
-- 							@PermanentDisabilityFactor float = 0.1503,
-- 							@RetrenchmentCoverStartMonth int = 4,
-- 							@NumberOfInstalments int = 6,
-- 							@RetrenchmentProb float = 0.000416667,
-- 							@TempDisProb float = 0.0000151679,
-- 							@DefaultYield float = 0.06,
-- 							@IlliquidityPremium float = 0.00,
-- 							@MinimumBenefitStartMonth int = 37,
-- 							@MinimumBenefitThreshold float = 30000,
-- 							@PercOfPrincipalDebt float = 0.20,
-- 							@DoubleBenefitStartMonth int = 25,
-- 							@DisbursementsHollard float = 0.29,
-- 							@DisbursementsCentriq float = 0.2475,
-- 							@PercCashback float = 0.10,
-- 							@MinimumYieldCurveMonth date = '01-Jan-2015',
-- 							@ValuationMonth date = '2025-10-01', -- Set your valuation month
-- 							@Insurer varchar(20) = 'Hollard', 
-- 							@RAFactor float = 0.1;
With pol as				( 
Select					p1.*
						, @MortalityFactor * lpp.[dbo].[monthlyRate](S1.ultimate, -1) Qx
						, @MortalityFactor * lpp.[dbo].[monthlyRate](S2.ultimate, -1) Qy
						, @MortalityFactor * lpp.[dbo].[monthlyRate](S3.ultimate, -1) Qz
						, @AIDSFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.aidstable Where Age = AgeX and yr = year(CalendarMonth)), -1) AIDSx
						, @AIDSFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.aidstable Where Age = AgeY and yr = year(CalendarMonth)), -1) AIDSy
						, @AIDSFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.aidstable Where Age = AgeZ and yr = year(CalendarMonth)), -1) AIDSz
						, Case when l.PlanName in ('Gold', 'Silver') then 
						@CriticalIllnessFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.csidread Where age = AgeX), -1) 
						else 0 end QCIx
						, Case when l.PlanName in ('Gold', 'Silver') then 
						@CriticalIllnessFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.csidread Where age = AgeY), -1) 
						else 0 end QCIy
						, Case when l.PlanName in ('Gold', 'Silver') then 
						@CriticalIllnessFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.csidread Where age = AgeZ), -1) 
						else 0 end QCIz
						, Case when l.PlanName in ('Gold', 'Silver') then 
						@PermanentDisabilityFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.csiskilled Where age = AgeX), -1) 
						else 0 end QPDx
						, Case when l.PlanName in ('Gold', 'Silver') then 
						@PermanentDisabilityFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.csiskilled Where age = AgeY), -1) 
						else 0 end QPDy
						, Case when l.PlanName in ('Gold', 'Silver') then 
						@PermanentDisabilityFactor * lpp.[dbo].[monthlyRate]((Select rate From lpp.dbo.csiskilled Where age = AgeZ), -1) 
						else 0 end QPDz
						, lr.rate LapseRate
From					#lppProbs1_ p1
						Left join LPP.dbo.SA8590 S1 on S1.x3 = p1.AgeX
						Left join LPP.dbo.SA8590 S2 on S2.x3 = p1.AgeY
						Left join LPP.dbo.SA8590 S3 on S3.x3 = p1.AgeZ
						Left join ifrs2.dbo.policy_info1 l on l.PolicyNumber = p1.PolicyNumber
						Left join [ifrs2].[dbo].lapserates lr on lr.mth = p1.ExposureMonth)
Select					pol.*
						, 1 - (1 - (isnull(Qx, 0) + isnull(AIDSx, 0)))*(1 - (isnull(Qy, 0) + isnull(AIDSy, 0)))*(1 - (isnull(Qz, 0) + isnull(AIDSz, 0))) Qxyz
						, 1 - (1 - (isnull(QCIx, 0)))*(1 - (isnull(QCIy, 0)))*(1 - (isnull(QCIz, 0))) QCIxyz
						, 1 - (1 - (isnull(QPDx, 0)))*(1 - (isnull(QPDy, 0)))*(1 - (isnull(QPDz, 0))) QPDxyz
Into					lppProbs2
From					pol;

/* Add index */
Create index			i2 on lppProbs2 (PolicyNumber, CalendarMonth);

--/* Multiple decrement table */
--Add dependent rates (lapse, mortality, permanent disability and critical illness)
Select					l.*
Into					lppProbs3
From					lppProbs2 l;

/* Add index */
Create index			i3 on lppProbs3 (PolicyNumber, CalendarMonth, ExposureMonth);

Select					*
						, (1 - l.LapseRate) * (1 - l.Qxyz) * (1 - l.QPDxyz) * (1 - l.QCIxyz) PrNotExiting
						, exp(SUM(log((1 - l.LapseRate) * (1 - l.Qxyz) * (1 - l.QPDxyz) * (1 - l.QCIxyz))) over (Partition by PolicyNumber Order by CalendarMonth)) SurvEnd
Into					#lppProbs3b
From					lppProbs3 l;


/* Add index */
Create index			ii3b on #lppProbs3b (PolicyNumber, CalendarMonth, ExposureMonth);

-- Save final multiple decrement table
Select					*
						, LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber Order by CalendarMonth) SurvStart
						, [LapseRate] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber Order by CalendarMonth) EventProb_Lapse
						, [Qxyz] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber Order by CalendarMonth) EventProb_Death
						, [QPDxyz] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber Order by CalendarMonth) EventProb_PD
						, [QCIxyz] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber Order by CalendarMonth) EventProb_CI 
Into					#lppProbs4
From					#lppProbs3b;

/* Add index */
Create index			i4 on #lppProbs4 (PolicyNumber, CalendarMonth, ExposureMonth);

/*Compute installment cover benefits*/ 
Select					l.PolicyNumber
						, p2.CalendarMonth ValuationMonth
						, l.CalendarMonth ClaimMonth
						, dateadd(Month, n.exposure, l.CalendarMonth) PaymentMonth
						, l.ExposureMonth
						, n.Exposure ClaimPaymentNo
						, Case when l.ExposureMonth < @RetrenchmentCoverStartMonth then 0 else p2.E_Installment end RetrenchmentPayout
						, Case when l.ExposureMonth < @RetrenchmentCoverStartMonth then 0 else p.Premium end RetrenchmentPremiumWaiver
						, p2.E_Installment TempDisabilityPayout
						, p.Premium TempDisabilityPremiumWaiver	
Into					#lppInstallmentBenefits1					
From					#lppProbs1_ l
						Left join ifrs2.dbo.policy_info1 p 
						on l.PolicyNumber = p.PolicyNumber
						Cross join #lppProbs1_ p2
						Cross join (Select top(6) Row_Number() over (Order by (Select 1)) Exposure From #lppProbs4) n
						inner join (Select PolicyNumber, min(CalendarMonth) Vmth from #lppProbs1_ group by PolicyNumber) as t
						on t.PolicyNumber = p.PolicyNumber
						and t.Vmth = p2.CalendarMonth
Where					p.PlanName in ('Gold', 'Silver')	
						and p2.PolicyNumber = l.PolicyNumber 
						and dateadd(Month, n.exposure, l.CalendarMonth) <= p.CeaseDate
						and l.CalendarMonth >= p2.CalendarMonth;

/* Add index */
Create index			a1 on #lppInstallmentBenefits1 (PolicyNumber, ValuationMonth, ClaimMonth);

/* Compute Instalment Benefit Probabilities*/
Select					ab.*
						, Case when ab.ExposureMonth < @RetrenchmentCoverStartMonth then 0 else ac.SurvStart * @RetrenchmentProb end RetrechProb
						, ac.SurvStart * @TempDisProb TempDisProb
						, ISNULL(rfr.nominalrate, @DefaultYield) + @IlliquidityPremium ForwardRate
						, POWER(1 + ISNULL(rfr.nominalrate, @DefaultYield) + @IlliquidityPremium, -1.000000 / 12) ForwardFactor
Into					#lppInstallmentBenefits2 
From					#lppInstallmentBenefits1	ab
						Inner join #lppProbs4 ac
						on ab.PolicyNumber = ac.PolicyNumber
						and ab.ClaimMonth = ac.CalendarMonth
						Inner join ifrs2.dbo.policy_info1 p
						on p.PolicyNumber = ac.PolicyNumber
						Left join lpp.dbo.riskfreerates_history rfr
						on rfr.valuationdate = DATEADD(month, -1, p.StartMonth)
						and DATEADD(month, DATEDIFF(month, 0, rfr.todate), 0) = DATEADD(month, DATEDIFF(month, 0, ab.PaymentMonth), 0);

/* Add index */
Create index			a2 on #lppInstallmentBenefits2 (PolicyNumber, ClaimMonth);

/* Compute the EPV Installment Benefits */
Select					i.PolicyNumber
						, i.ClaimMonth
						, i.PaymentMonth
						, i.ExposureMonth
						, i.ClaimPaymentNo
						, i.RetrenchmentPayout
						, i.RetrenchmentPremiumWaiver
						, i.TempDisabilityPayout
						, i.TempDisabilityPremiumWaiver	
						, i.RetrechProb
						, i.TempDisProb
						, i.ForwardRate
						, i.ForwardFactor
						, exp(sum(log(i.ForwardFactor)) over (Partition by PolicyNumber, ClaimMonth Order by PaymentMonth rows between unbounded preceding and current row)) DiscountFactor
						, exp(sum(log(i.ForwardFactor)) over (Partition by PolicyNumber, ClaimMonth Order by PaymentMonth rows between unbounded preceding and current row)) * i.RetrechProb * i.RetrenchmentPayout EPV_Retrenchment
						, exp(sum(log(i.ForwardFactor)) over (Partition by PolicyNumber, ClaimMonth Order by PaymentMonth rows between unbounded preceding and current row)) * i.RetrechProb * i.RetrenchmentPremiumWaiver EPV_RetrenchmentPremiumWaiver
						, exp(sum(log(i.ForwardFactor)) over (Partition by PolicyNumber, ClaimMonth Order by PaymentMonth rows between unbounded preceding and current row)) * i.TempDisProb * i.TempDisabilityPayout EPV_TempDisability
						, exp(sum(log(i.ForwardFactor)) over (Partition by PolicyNumber, ClaimMonth Order by PaymentMonth rows between unbounded preceding and current row)) * i.TempDisProb * i.TempDisabilityPremiumWaiver EPV_TempDisabilityPremiumWaiver
Into					#lppInstallmentBenefits3 
From					#lppInstallmentBenefits2 i;

/* Add index */
Create index			a3 on #lppInstallmentBenefits3 (PolicyNumber, ClaimMonth);

/* Aggregate the installment benefits by claim month */
Select					[PolicyNumber]
						, [ClaimMonth]
						, sum(EPV_Retrenchment) EPV_Retrenchment
						, sum(EPV_RetrenchmentPremiumWaiver) EPV_RetrenchmentPremiumWaiver
						, sum(EPV_TempDisability) EPV_TempDisability
						, sum(EPV_TempDisabilityPremiumWaiver) EPV_TempDisabilityPremiumWaiver
Into					#lppInstallmentBenefits4
From					#lppInstallmentBenefits3
Group by				[PolicyNumber]
						,[ClaimMonth];

/* Calculate the expected cash flows */
Select					l.PolicyNumber
						, l.CalendarMonth
						, p.SumAssuredFuneral Funeral
						, Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end MinimumBenefit

						,Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end MinimumBenefitLevCover


						, Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end 
						BoosterBenefit

						, Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) end 
						BoosterBenefitLevCover

						, (p.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end) TotalDeath

						,(p.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) +
						(Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) end) TotalDeathLevCover

						, l.EventProb_Death * 
						((p.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end)) E_Death
						, l.EventProb_CI * (
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end)) E_CriticalIllness
						, l.EventProb_PD * (
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when p.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when p.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * p.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end))E_PermanentDisability
						, l.SurvStart * p.Premium E_Premium
						, l.SurvStart * p.Premium * iif(p.Underwriter = 'Hollard', @DisbursementsHollard, @DisbursementsCentriq) E_Disbursement
						, Case when p.PlanName not in ('Gold') then 0
						when l.CalendarMonth = DATEADD(month, DATEDIFF(month, 0, p.CeaseDate), 0) then l.SurvEnd * l.ExposureMonth * p.Premium * @PercCashback
						else 0 end E_CashBack
						, isnull(EPV_TempDisability, 0) E_TempDisability
						, isnull(EPV_Retrenchment, 0) E_Retrenchment
						, isnull(EPV_RetrenchmentPremiumWaiver, 0) E_RetrenchmentPremiumWaiver
						, isnull(EPV_TempDisabilityPremiumWaiver, 0) E_TempDisabilityPremiumWaiver
Into					#lppFCF
From					#lppProbs4 l
						Left join ifrs2.dbo.policy_info1 p
						on l.PolicyNumber = p.PolicyNumber
						Left join #lppInstallmentBenefits4 i
						on l.PolicyNumber = i.PolicyNumber 
						and l.CalendarMonth = i.ClaimMonth;

Create index			a4 on #lppFCF (PolicyNumber, CalendarMonth);

--************************************************************************************************
-- IFRS 17 Financials 
--************************************************************************************************

/* Compute E-Claims and Forward Rates */
-- Declare					--	@TakeonMonth date = '01-Sep-2023',
-- 							--@FYend date = '01-Jun-2024',
-- 							@Spread float = 0.01,
-- 							@ProbBalloon float = 0.6,
-- 							@BalloonProportion float = 0.3,
-- 							@MortalityFactor float = 0.80,
-- 							@AIDSFactor float = 0.025,
-- 							@CriticalIllnessFactor float = 0.168,
-- 							@PermanentDisabilityFactor float = 0.1503,
-- 							@RetrenchmentCoverStartMonth int = 4,
-- 							@NumberOfInstalments int = 6,
-- 							@RetrenchmentProb float = 0.000416667,
-- 							@TempDisProb float = 0.0000151679,
-- 							@DefaultYield float = 0.06,
-- 							@IlliquidityPremium float = 0.00,
-- 							@MinimumBenefitStartMonth int = 37,
-- 							@MinimumBenefitThreshold float = 30000,
-- 							@PercOfPrincipalDebt float = 0.20,
-- 							@DoubleBenefitStartMonth int = 25,
-- 							@DisbursementsHollard float = 0.29,
-- 							@DisbursementsCentriq float = 0.2475,
-- 							@PercCashback float = 0.10,
-- 							@MinimumYieldCurveMonth date = '01-Jan-2015',
-- 							@ValuationMonth date = '2025-10-01', -- Set your valuation month
-- 							@Insurer varchar(20) = 'Hollard', 
-- 							@RAFactor float = 0.1;
Select					k.*
						, k.[E_Death]+ k.[E_CriticalIllness] + k.[E_PermanentDisability] + k.[E_TempDisability] + k.[E_Retrenchment] + k.[E_RetrenchmentPremiumWaiver]
						+ k.[E_TempDisabilityPremiumWaiver] + k.[E_CashBack] E_Claims
						,Case when DATEADD(month, -1, p.StartMonth) < @MinimumYieldCurveMonth then 
						@DefaultYield + @IlliquidityPremium 
						else 
						r.nominalrate +@IlliquidityPremium 
						end  Forward_LockedIn
Into					#lppFCF2
From					#lppFCF k
						Left join ifrs2.dbo.policy_info1 p on
						p.PolicyNumber = k.PolicyNumber
						Left join lpp.dbo.riskfreerates_history r on
						r.valuationdate = DATEADD(month, -1, p.StartMonth)
						and DATEADD(month, DATEDIFF(month, 0, r.todate), 0) = k.CalendarMonth;
					
/* Add index */
Create index			a5 on #lppFCF2 (PolicyNumber, CalendarMonth);

/* Calculate Forward Factors */
Select					j.*
						, POWER(1 + Forward_LockedIn, -1.000000/12) ForwardFactor_LockedIn
						, EXP(sum(log((POWER(1 + Forward_LockedIn, -1.000000/12)))) over (Partition by PolicyNumber Order by CalendarMonth rows between unbounded preceding and CURRENT row)) DF_Arrears_LockedIn
Into					#lppFCF3
From					#lppFCF2 j

/* Add index */
Create index			a6 on #lppFCF3 (PolicyNumber, CalendarMonth);

/* Calculate discount Factors */
Select					l.*
						, lag(DF_Arrears_LockedIn, 1, 1) over (Partition by PolicyNumber Order by CalendarMonth) DF_Advance_LockedIn
Into					#lppFCF4
From					#lppFCF3 l;

Create index			ii4 on #lppFCF4 (PolicyNumber, CalendarMonth);

/* Calculate EPVs */
Select					f.*
                   		, f.DF_Advance_LockedIn * f.E_Premium EPVFCI
						, f.DF_Advance_LockedIn * f.E_Disbursement + f.DF_Arrears_LockedIn * f.E_Claims EPVFCO
						, f.DF_Arrears_LockedIn * f.E_Claims EPVClaims
						, f.DF_Advance_LockedIn * f.E_Disbursement EPVDisbursements 
						, p.E_CB
						, p.E_OB
						, p.E_Installment
						, p.AgeX
						, p.AgeY
						, p.AgeZ
						, p.ExposureMonth
						, p2.Qxyz
						, p2.QCIxyz
						, p2.QPDxyz
						, p2.LapseRate
						, pi.PlanName
						, pi.CeaseDate
						, pi.Premium
						, pi.SumAssuredDeath
						, pi.SumAssuredFuneral
						, pi.Underwriter
						, pi.Cell
Into					#lppFCF4A
From					#lppFCF4 f
						left join #lppProbs1_ p
						on f.PolicyNumber = p.PolicyNumber
						and f.CalendarMonth = p.CalendarMonth
						left join lppProbs2 p2
						on p2.PolicyNumber = p.PolicyNumber
						and p2.CalendarMonth = p.CalendarMonth
						left join ifrs2.dbo.policy_info1 pi
						on pi.PolicyNumber = p.PolicyNumber;

Create index			iii1 on #lppFCF4A (PolicyNumber, CalendarMonth);

/* Calculate the BEL, RA, CSM and Loss Component at Initial Recognition */
Select					l.PolicyNumber
						, p.StartMonth ValuationMonth
						, p.Cell
						, p.Underwriter
						, Case when p.Underwriter = 'Centriq' then YEAR(p.StartMonth)
							when MONTH(p.StartMonth) > 6 then YEAR(p.StartMonth) + 1
							else YEAR(p.StartMonth) end GroupingYear
						, -SUM(EPVFCI) EPVFCI_AtIR
						, SUM(EPVFCO) EPVFCO_AtIR
						, -SUM(EPVFCI) + SUM(EPVFCO) BEL_AtIR
						, sum(EPVClaims) * @RAFactor RA
						, (-SUM(EPVFCI) + SUM(EPVFCO)) + (sum(EPVClaims) * @RAFactor) FCF_AtIR
						, iif((-SUM(EPVFCI) + SUM(EPVFCO)) + (sum(EPVClaims) * @RAFactor) > 0, 0, -((-SUM(EPVFCI) + SUM(EPVFCO)) + (sum(EPVClaims) * @RAFactor))) CSM
						, iif((-SUM(EPVFCI) + SUM(EPVFCO)) + (sum(EPVClaims) * @RAFactor) > 0, 1, 0) Onerous
						, -SUM(Case when l.CalendarMonth = p.StartMonth then 0 else EPVFCI end) EPVFCI
						, SUM(Case when l.CalendarMonth = p.StartMonth then EPVClaims else EPVFCO end) EPVFCO
						, -SUM(Case when l.CalendarMonth = p.StartMonth then 0 else EPVFCI end) + SUM(Case when l.CalendarMonth = p.StartMonth then EPVClaims else EPVFCO end) BEL
						, -SUM(Case when l.CalendarMonth = p.StartMonth then 0 else EPVFCI end) + SUM(Case when l.CalendarMonth = p.StartMonth then EPVClaims else EPVFCO end) + sum(EPVClaims) * @RAFactor FCF
						, iif((-SUM(EPVFCI) + SUM(EPVFCO)) + (sum(EPVClaims) * @RAFactor) > 0, -1 * ((-SUM(EPVFCI) + SUM(EPVFCO)) + (sum(EPVClaims) * @RAFactor)), 0) LossComponent
Into					lppIR1
From					#lppFCF4A l
						left join ifrs2.dbo.policy_info1 p
						on p.PolicyNumber = l.PolicyNumber
Group by				l.PolicyNumber
						, p.StartMonth
						, p.Cell
						, p.Underwriter
						, Case when p.Underwriter = 'Centriq' then YEAR(p.StartMonth)
						when MONTH(p.StartMonth) > 6 then YEAR(p.StartMonth) + 1
						else YEAR(p.StartMonth) end;

-- Save the results
Select					* 
Into					lppTakeonIRData from #lppFCF4A;

-- Create valuation months
With cte as				(
Select					MIN(ValuationMonth) Mth
From					lppIR1
Union all
Select					DATEADD(month, 1, Mth) Mth
From					cte
Where					DATEADD(month, 1, Mth) <= @ValuationMonth
						)
Select					*
Into					#mths
From					cte
Option					(maxrecursion 200);

-- Combine valuation months with the takeon data
Select					t.PolicyNumber
						, #mths.Mth ValuationMonth
						, t.CalendarMonth
						, t.E_CB
						, t.E_OB
						, t.E_Installment
						, t.AgeX
						, t.AgeY
						, t.AgeZ
						, t.ExposureMonth
						, t.Qxyz
						, t.QCIxyz
						, t.QPDxyz
						, t.LapseRate
						, t.Premium
						, t.PlanName
						, t.CeaseDate
						, t.SumAssuredDeath
						, t.SumAssuredFuneral
						, t.Underwriter
Into					#lppProbs1__
From					lppTakeonIRData t
						cross join #mths
						left join lppIR1 i
						on i.PolicyNumber = t.PolicyNumber
Where					t.CalendarMonth > #mths.Mth
						and #mths.Mth >= i.ValuationMonth;

/* Add index */
Create index			ii1 on #lppProbs1__ (PolicyNumber, ValuationMonth, CalendarMonth);

--************************************************************************************************
--/* Multiple decrement table  by valuation month*/
--************************************************************************************************

--Add dependent rates (lapse, mortality, permanent disability and critical illness)
Select					l.*
Into					#lppProbs3_
From					#lppProbs1__ l;

/* Add index */
Create index			ii3 on #lppProbs3_ (PolicyNumber, ValuationMonth, CalendarMonth, ExposureMonth);

Select					*
						, (1 - l.LapseRate) * (1 - l.Qxyz) * (1 - l.QPDxyz) * (1 - l.QCIxyz) PrNotExiting
						, exp(SUM(log((1 - l.LapseRate) * (1 - l.Qxyz) * (1 - l.QPDxyz) * (1 - l.QCIxyz))) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth)) SurvEnd
Into					#lppProbs3b_
From					#lppProbs3_ l;

/* Add index */
Create index			ii3b on #lppProbs3b_ (PolicyNumber, ValuationMonth, CalendarMonth, ExposureMonth);

-- Save final multiple decrement table
Select					*
						, LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) SurvStart
						, [LapseRate] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) EventProb_Lapse
						, [Qxyz] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) EventProb_Death
						, [QPDxyz] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) EventProb_PD
						, [QCIxyz] * LAG(SurvEnd, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) EventProb_CI 
Into					#lppProbs4_SM
From					#lppProbs3b_;

/* Add index */
Create index			ii4 on #lppProbs4_SM (PolicyNumber, ValuationMonth, CalendarMonth, ExposureMonth);

--****************************************************************************************************************

/*Compute installment cover benefits*/ 
Select					l.PolicyNumber
						, l.ValuationMonth
						, l.CalendarMonth ClaimMonth
						, dateadd(Month, n.exposure, l.CalendarMonth) PaymentMonth
						, l.ExposureMonth
						, n.Exposure ClaimPaymentNo
						, Case when l.ExposureMonth < @RetrenchmentCoverStartMonth then 0 else l.E_Installment end RetrenchmentPayout
						, Case when l.ExposureMonth < @RetrenchmentCoverStartMonth then 0 else l.Premium end RetrenchmentPremiumWaiver
						, l.E_Installment TempDisabilityPayout
						, l.Premium TempDisabilityPremiumWaiver	
						, Case when l.ExposureMonth < @RetrenchmentCoverStartMonth then 0 else l.SurvStart * @RetrenchmentProb end RetrechProb
						, l.SurvStart * @TempDisProb TempDisProb
Into					#lppInstallmentBenefits1_					
From					#lppProbs4_SM l
						Cross join (Select top(6) Row_Number() over (Order by (Select 1)) Exposure From #lppProbs4_SM) n
Where					l.PlanName in ('Gold', 'Silver')
						and dateadd(Month, n.exposure, l.CalendarMonth) <= l.CeaseDate;

/* Add index */
Create index			a1 on #lppInstallmentBenefits1_ (PolicyNumber, ValuationMonth, ClaimMonth);

/* Compute Instalment Benefit Probabilities*/
Select					ab.*
						, ISNULL(rfr.nominalrate, @DefaultYield) + @IlliquidityPremium ForwardRate
						, POWER(1 + ISNULL(rfr.nominalrate, @DefaultYield) + @IlliquidityPremium, -1.000000 / 12) ForwardFactor
						, EXP(SUM(LOG(POWER(1 + ISNULL(rfr.nominalrate, @DefaultYield) + @IlliquidityPremium, -1.000000 / 12))) 
						over (Partition by ab.PolicyNumber, ab.ValuationMonth, ab.ClaimMonth Order by ab.PaymentMonth)) DiscountFactor
Into					#lppInstallmentBenefits2_ 
From					#lppInstallmentBenefits1_	ab
						Left join lppIR1 i
						on i.PolicyNumber = ab.PolicyNumber
						Left join lpp.dbo.riskfreerates_history rfr
						on rfr.valuationdate = DATEADD(month, -1, i.ValuationMonth)
						and DATEADD(month, DATEDIFF(month, 0, rfr.todate), 0) = DATEADD(month, DATEDIFF(month, 0, ab.PaymentMonth), 0);

/* Add index */
Create index			a2 on #lppInstallmentBenefits2_ (PolicyNumber, ValuationMonth, ClaimMonth);

/* Compute the EPV Installment Benefits */
Select					i.*
   						, i.DiscountFactor * i.RetrechProb * i.RetrenchmentPayout EPV_Retrenchment
   						, i.DiscountFactor * i.RetrechProb * i.RetrenchmentPremiumWaiver EPV_RetrenchmentPremiumWaiver
   						, i.DiscountFactor * TempDisProb * TempDisabilityPayout EPV_TempDisability
   						, i.DiscountFactor * TempDisProb * TempDisabilityPremiumWaiver EPV_TempDisabilityPremiumWaiver
Into					#lppInstallmentBenefits3_
From					#lppInstallmentBenefits2_ i;

/* Add index */
Create index			a3 on #lppInstallmentBenefits3_ (PolicyNumber, ValuationMonth, ClaimMonth);

/* Aggregate the installment benefits by claim month */
Select					[PolicyNumber]
						,[ValuationMonth]
						,[ClaimMonth]
						, sum(EPV_Retrenchment) EPV_Retrenchment
						, sum(EPV_RetrenchmentPremiumWaiver) EPV_RetrenchmentPremiumWaiver
						, sum(EPV_TempDisability) EPV_TempDisability
						, sum(EPV_TempDisabilityPremiumWaiver) EPV_TempDisabilityPremiumWaiver
Into					#lppInstallmentBenefits4_
From					#lppInstallmentBenefits3_
Group by				PolicyNumber
						, ValuationMonth
						, ClaimMonth;

/* Calculate the expected cash flows */
Select					l.PolicyNumber
						, l.ValuationMonth
						, l.CalendarMonth
						, p.Cell
						, l.Underwriter
						, l.SumAssuredFuneral Funeral
						, Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end MinimumBenefit

						,Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end MinimumBenefitLevCover


						, Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end 
						BoosterBenefit

						, Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) end 
						BoosterBenefitLevCover

						, (l.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end) TotalDeath

						,(l.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) +
						(Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) end) TotalDeathLevCover

						,((l.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) +
						(Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_OB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_OB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_OB end) end)) * l.SurvStart FutureCoverageUnits

						, l.EventProb_Death * 
						((l.SumAssuredFuneral) +
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end)) E_Death
						, l.EventProb_CI * (
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end)) E_CriticalIllness
						, l.EventProb_PD * (
						(Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) +
						(Case when l.PlanName not in ('Gold') then 0
						when l.ExposureMonth < @DoubleBenefitStartMonth then 0
						else (Case when l.ExposureMonth < @MinimumBenefitStartMonth then l.E_CB
						when l.SumAssuredDeath <= @MinimumBenefitThreshold then @PercOfPrincipalDebt * l.SumAssuredDeath
						when l.E_CB < @MinimumBenefitThreshold then @MinimumBenefitThreshold
						else l.E_CB end) end))E_PermanentDisability
						, l.SurvStart * l.Premium E_Premium
						, l.SurvStart * l.Premium * iif(l.Underwriter = 'Hollard', @DisbursementsHollard, @DisbursementsCentriq) E_Disbursement
						, Case when l.PlanName not in ('Gold') then 0
						when l.CalendarMonth = DATEADD(month, DATEDIFF(month, 0, l.CeaseDate), 0) then l.SurvEnd * l.ExposureMonth * l.Premium * @PercCashback
						else 0 end E_CashBack
						, isnull(EPV_TempDisability, 0) E_TempDisability
						, isnull(EPV_Retrenchment, 0) E_Retrenchment
						, isnull(EPV_RetrenchmentPremiumWaiver, 0) E_RetrenchmentPremiumWaiver
						, isnull(EPV_TempDisabilityPremiumWaiver, 0) E_TempDisabilityPremiumWaiver
Into					#lppFCF_
From					#lppProbs4_SM l
						Left join #lppInstallmentBenefits4_ i
						on l.PolicyNumber = i.PolicyNumber
						and l.ValuationMonth = i.ValuationMonth
						and l.CalendarMonth = i.ClaimMonth
						Left join lppIR1 p on
						p.PolicyNumber = l.PolicyNumber;

/* Add index */
Create index			a4 on #lppFCF_ (PolicyNumber, ValuationMonth, CalendarMonth);

--************************************************************************************************
-- IFRS 17 Financials 
--************************************************************************************************

/* Compute E-Claims and Forward Rates stopped here*/ 
-- Declare					--	@TakeonMonth date = '01-Sep-2023',
-- 							--@FYend date = '01-Jun-2024',
-- 							@Spread float = 0.01,
-- 							@ProbBalloon float = 0.6,
-- 							@BalloonProportion float = 0.3,
-- 							@MortalityFactor float = 0.80,
-- 							@AIDSFactor float = 0.025,
-- 							@CriticalIllnessFactor float = 0.168,
-- 							@PermanentDisabilityFactor float = 0.1503,
-- 							@RetrenchmentCoverStartMonth int = 4,
-- 							@NumberOfInstalments int = 6,
-- 							@RetrenchmentProb float = 0.000416667,
-- 							@TempDisProb float = 0.0000151679,
-- 							@DefaultYield float = 0.06,
-- 							@IlliquidityPremium float = 0.00,
-- 							@MinimumBenefitStartMonth int = 37,
-- 							@MinimumBenefitThreshold float = 30000,
-- 							@PercOfPrincipalDebt float = 0.20,
-- 							@DoubleBenefitStartMonth int = 25,
-- 							@DisbursementsHollard float = 0.29,
-- 							@DisbursementsCentriq float = 0.2475,
-- 							@PercCashback float = 0.10,
-- 							@MinimumYieldCurveMonth date = '01-Jan-2015',
-- 							@ValuationMonth date = '2025-10-01', -- Set your valuation month
-- 							@Insurer varchar(20) = 'Hollard', 
-- 							@RAFactor float = 0.1;
Select					k.*
						, k.[E_Death] + k.[E_CriticalIllness] + k.[E_PermanentDisability]+ k.[E_TempDisability] + k.[E_Retrenchment] + k.[E_RetrenchmentPremiumWaiver]
						+ k.[E_TempDisabilityPremiumWaiver] + k.[E_CashBack] E_Claims
						, Case when DATEADD(month, -1, p.ValuationMonth) < @MinimumYieldCurveMonth then 
						@DefaultYield + @IlliquidityPremium 
						else 
						r.nominalrate + @IlliquidityPremium 
						end  Forward_LockedIn
						,Case when p.ValuationMonth = k.ValuationMonth then 
						(Case when DATEADD(month, -1, p.ValuationMonth) < @MinimumYieldCurveMonth then 
						@DefaultYield + @IlliquidityPremium 
						else 
						r.nominalrate +@IlliquidityPremium 
						end) /*formula inside bracket thesame as the forward_ LockedIn*/ 
						when DATEADD(MONTH,-1,k.ValuationMonth) < @MinimumYieldCurveMonth then 
						@DefaultYield + @IlliquidityPremium 
						else
						r2.nominalrate +@IlliquidityPremium 
						end Forward_Current
						,Case when p.ValuationMonth = k.ValuationMonth then 
						(Case when DATEADD(month, -1, p.ValuationMonth) < @MinimumYieldCurveMonth then 
						@DefaultYield + @IlliquidityPremium 
						else 
						r.nominalrate +@IlliquidityPremium 
						end) /*formula inside bracket thesame as the forward_ LockedIn*/ 
						when DATEADD(MONTH,-2, k.ValuationMonth) < @MinimumYieldCurveMonth then 
						@DefaultYield + @IlliquidityPremium 
						else
						r3.nominalrate +@IlliquidityPremium 
						end  Forward_Previous
Into					#lppFCF2_
From					#lppFCF_ k
						Left join lppIR1 p on
						p.PolicyNumber = k.PolicyNumber
						Left join lpp.dbo.riskfreerates_history r on
						r.valuationdate = DATEADD(month, -1, p.ValuationMonth)
						and DATEADD(month, DATEDIFF(month, 0, r.todate), 0) = k.CalendarMonth
						Left join lpp.dbo.riskfreerates_history r2 on
						r2.valuationdate = DATEADD(month,-1, k.ValuationMonth) 
						and DATEADD(month, DATEDIFF(month, 0, r2.todate), 0) = k.CalendarMonth
						Left join lpp.dbo.riskfreerates_history r3 on
						r3.valuationdate = DATEADD(month,-2, k.ValuationMonth) 
						and DATEADD(month, DATEDIFF(month, 0, r3.todate), 0) = k.CalendarMonth
					
/* Add index */
Create index			a5 on #lppFCF2_ (PolicyNumber, ValuationMonth, CalendarMonth);

/* Calculate Forward Factors */
Select					j.*
						, POWER(1 + Forward_LockedIn, -1.000000 / 12) ForwardFactor_LockedIn
						, POWER(1 + Forward_Current, -1.000000 / 12) ForwardFactor_Current
						, POWER(1 + Forward_Previous, -1.000000 / 12) ForwardFactor_Previous
						, EXP(sum(log((POWER(1 + Forward_LockedIn, -1.000000 / 12)))) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth rows between unbounded preceding and CURRENT row)) DF_Arrears_LockedIn
						, EXP(sum(log((POWER(1 + Forward_Current, -1.000000 / 12)))) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth rows between unbounded preceding and CURRENT row)) DF_Arrears_Current
						, EXP(sum(log((POWER(1 + Forward_Previous, -1.000000 / 12)))) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth rows between unbounded preceding and CURRENT row)) DF_Arrears_Previous
into					#lppFCF3_
From					#lppFCF2_ j;

/* Add index */
Create index			a6 on #lppFCF3_ (PolicyNumber, ValuationMonth, CalendarMonth);

--/* Calculate discount Factors */
Select					l.*
						, lag(DF_Arrears_LockedIn, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) DF_Advance_LockedIn
						, lag(DF_Arrears_Current, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) DF_Advance_Current
						, lag(DF_Arrears_Previous, 1, 1) over (Partition by PolicyNumber, ValuationMonth Order by CalendarMonth) DF_Advance_Previous
Into					#lppFCF4_
From					#lppFCF3_ l;

/* Add index */
Create index			a7 on #lppFCF4_ (PolicyNumber, ValuationMonth, CalendarMonth);

/* Calculate EPVs */
Select					f.*
                   		, f.DF_Advance_LockedIn * f.E_Premium EPVFCI_LockedIn
						, f.DF_Advance_LockedIn * f.E_Disbursement + f.DF_Arrears_LockedIn * f.E_Claims EPVFCO_LockedIn
						, f.DF_Arrears_LockedIn * f.E_Claims EPVClaims_LockedIn
						, f.DF_Advance_LockedIn * f.E_Disbursement EPVDisbursements_LockedIn 

						, f.DF_Advance_Current * f.E_Premium EPVFCI_Current
						, f.DF_Advance_Current * f.E_Disbursement + f.DF_Arrears_Current * f.E_Claims EPVFCO_Current
						, f.DF_Arrears_Current * f.E_Claims EPVClaims_Current
						, f.DF_Advance_Current * f.E_Disbursement EPVDisbursements_Current 

						, f.DF_Advance_Previous * f.E_Premium EPVFCI_Previous
						, f.DF_Advance_Previous * f.E_Disbursement + f.DF_Arrears_Previous * f.E_Claims EPVFCO_Previous
						, f.DF_Arrears_Previous * f.E_Claims EPVClaims_Previous
						, f.DF_Advance_Previous * f.E_Disbursement EPVDisbursements_Previous 

						, Isnull(Case when f.ValuationMonth = ir.ValuationMonth then (fcf.E_Premium) else (Select i.E_Premium from #lppFCF4_ i where i.PolicyNumber = f.PolicyNumber and i.ValuationMonth = DATEADD(month, -1, f.ValuationMonth) and i.CalendarMonth = f.CalendarMonth) end, 0) E_Premium_PreviousValuation	
						, Isnull(Case when f.ValuationMonth = ir.ValuationMonth then (fcf.E_Disbursement) else (Select i.E_Disbursement from #lppFCF4_ i where i.PolicyNumber = f.PolicyNumber and i.ValuationMonth = DATEADD(month, -1, f.ValuationMonth) and i.CalendarMonth = f.CalendarMonth) end, 0) E_Disbursement_PreviousValuation	
						, Isnull(Case when f.ValuationMonth = ir.ValuationMonth then (fcf.E_Claims) else (Select i.E_Claims from #lppFCF4_ i where i.PolicyNumber = f.PolicyNumber and i.ValuationMonth = DATEADD(month, -1, f.ValuationMonth) and i.CalendarMonth = f.CalendarMonth) end, 0) E_Claims_PreviousValuation	

Into					#lppFCF4A_
From					#lppFCF4_ f
						left join lppIR1 ir
						on ir.PolicyNumber = f.PolicyNumber
						and ir.ValuationMonth = f.ValuationMonth
						left join #lppFCF4A fcf
						on fcf.PolicyNumber = f.PolicyNumber
						and fcf.CalendarMonth = f.CalendarMonth;

/* Add index */
Create index			a8 on #lppFCF4A_ (PolicyNumber, ValuationMonth, CalendarMonth);

-- Calculate changes to premium, disbursement and claims cashflows
Select					l.*
						, l.E_Premium - l.E_Premium_PreviousValuation E_Premium_Change	
						, l.E_Disbursement - l.E_Disbursement_PreviousValuation E_Disbursement_Change	
						, l.E_Claims - l.E_Claims_PreviousValuation E_Claims_Change	
Into					#lppFCF4B_
From					#lppFCF4A_ l
						left join lppIR1 ir
						on ir.PolicyNumber = l.PolicyNumber;

/* Add index */
Create index			a9 on #lppFCF4B_ (PolicyNumber, ValuationMonth, CalendarMonth);

-- Calculate the changes relating to future services
Select					l.*
						, E_Premium_Change * DF_Advance_LockedIn - E_Disbursement_Change * DF_Advance_LockedIn - E_Claims_Change * DF_Arrears_LockedIn CRTFS_BEL	
						, -E_Claims_Change * DF_Arrears_LockedIn * @RAFactor CRTFS_RA	
						, (E_Premium_Change * DF_Advance_LockedIn - E_Disbursement_Change * DF_Advance_LockedIn - E_Claims_Change * DF_Arrears_LockedIn) 
						+
						(-E_Claims_Change * DF_Arrears_LockedIn * @RAFactor) Change_To_CSM
						, (-(l.E_Premium - l.E_Disbursement) * DF_Advance_Current + l.E_Claims * l.DF_Arrears_Current) BEL_CurrentCurve
						, (-(l.E_Premium - l.E_Disbursement) * DF_Advance_Previous + l.E_Claims * l.DF_Arrears_Previous) BEL_PreviousCurve
						, (-(l.E_Premium - l.E_Disbursement) * l.DF_Advance_LockedIn + l.E_Claims * l.DF_Arrears_LockedIn) BEL_LockedInCurve
						, l.E_Claims * l.DF_Arrears_Current * @RAFactor RA_CurrentCurve
						, l.E_Claims * l.DF_Arrears_Previous * @RAFactor RA_PreviousCurve
						, l.E_Claims * l.DF_Arrears_LockedIn * @RAFactor RA_LockedInCurve
Into					#lppFCF4C_
From					#lppFCF4B_ l;

/* Add index */
Create index			a10 on #lppFCF4C_ (PolicyNumber, ValuationMonth, CalendarMonth);

--/* Aggregate BEL and RA for current, previous and lockedin yield curve */
Select					l.PolicyNumber
						, l.ValuationMonth
 						, p.Cell
 						, l.Underwriter
						, SUM(BEL_CurrentCurve) BEL_CurrentCurve
						, SUM(BEL_PreviousCurve) BEL_PreviousCurve
						, SUM(BEL_LockedInCurve) BEL_LockedInCurve
						, SUM(RA_CurrentCurve) RA_CurrentCurve
						, SUM(RA_PreviousCurve) RA_PreviousCurve
						, SUM(RA_LockedInCurve) RA_LockedInCurve
						, SUM(CRTFS_BEL) CRTFS_BEL
						, SUM(CRTFS_RA) CRTFS_RA
						, SUM(Change_To_CSM) Change_To_CSM
Into					#lppBELRA1
From					#lppFCF4C_ l
						Left join lppIR1 p on
						p.PolicyNumber = l.PolicyNumber
Group by				l.PolicyNumber
						, l.ValuationMonth
 						, p.Cell
 						, l.Underwriter;

Create index			u0 on #lppBELRA1 (PolicyNumber, ValuationMonth);

Select					l.*
						, isnull(LAG(BEL_LockedInCurve) over (Partition by l.PolicyNumber Order by l.ValuationMonth), (Select BEL from lppIR1 where PolicyNumber = l.PolicyNumber)) Opening_BEL_LockedIn
						, isnull(LAG(RA_LockedInCurve) over (Partition by l.PolicyNumber Order by l.ValuationMonth), (Select RA from lppIR1 where PolicyNumber = l.PolicyNumber)) Opening_RA_LockedIn
						, isnull(LAG(BEL_CurrentCurve) over (Partition by l.PolicyNumber Order by l.ValuationMonth), (Select BEL from lppIR1 where PolicyNumber = l.PolicyNumber)) Opening_BEL_Current
						, isnull(LAG(RA_CurrentCurve) over (Partition by l.PolicyNumber Order by l.ValuationMonth), (Select RA from lppIR1 where PolicyNumber = l.PolicyNumber)) Opening_RA_Current
						, Case when Dateadd(month, -1, i.ValuationMonth) < @MinimumYieldCurveMonth then @DefaultYield + @IlliquidityPremium else r.nominalrate + @IlliquidityPremium end ForwardRate_LockedIn
Into					#lppBELRA2
From					#lppBELRA1 l
						left join lppir1 i
						on l.PolicyNumber = i.PolicyNumber
						Left join lpp.dbo.riskfreerates_history r on
						r.valuationdate = DATEADD(month, -1, i.ValuationMonth)
						and DATEADD(month, DATEDIFF(month, 0, r.todate), 0) = l.ValuationMonth;

Create index			u1 on #lppBELRA2(PolicyNumber, ValuationMonth);

-- Calculate interest accreted on BEL and RA
Select					l.*
						, l.Opening_BEL_LockedIn * POWER(1 + ForwardRate_LockedIn, 1.00000000/12) - l.Opening_BEL_LockedIn InterestAccreted_BEL
						, l.Opening_RA_LockedIn * POWER(1 + ForwardRate_LockedIn, 1.00000000/12) - l.Opening_RA_LockedIn InterestAccreted_RA
Into					#lppBELRA3
From					#lppBELRA2 l; 
Create index			u2 on #lppBELRA3(PolicyNumber, ValuationMonth);

-- Calculate the Transfer BEL and RA
Select					l.*
						, (BEL_CurrentCurve - Opening_BEL_Current) - (InterestAccreted_BEL + CRTFS_BEL) Transfer_BEL
						, (RA_CurrentCurve - Opening_RA_Current) - (InterestAccreted_RA + CRTFS_RA) TransferRA
Into					#lppBELRA4
From					#lppBELRA3 l;

-- Add the amortisation percentage
Select b.PolicyNumber, b.ValuationMonth, TotalDeath, FutureCoverageUnits, Case when (TotalDeath + FutureCoverageUnits) = 0 then 1 else TotalDeath * 1.000000 / (TotalDeath + FutureCoverageUnits) end AmortPerc 
into amort
from #lppProbs1_ a
inner join #lppBELRA4 b
on a.PolicyNumber = b.PolicyNumber
and a.CalendarMonth = b.ValuationMonth
inner join (
Select PolicyNumber, ValuationMonth, sum(FutureCoverageUnits) FutureCoverageUnits
from #lppFCF_
group by PolicyNumber, ValuationMonth) as t
on t.PolicyNumber = b.PolicyNumber
and t.ValuationMonth = b.ValuationMonth
inner join 	#lppFCF f
on f.PolicyNumber = t.PolicyNumber
and f.CalendarMonth = t.ValuationMonth;
;

---- Save results into some permanent tables
Select					*
Into					lppTakeonSMDataAggregated
From					#lppBELRA4;
Create index			u3 on lppTakeonSMDataAggregated (PolicyNumber, ValuationMonth);

-- CSM Amort
With cte as					(
Select						ir.PolicyNumber,
							ir.Cell,
							ir.Underwriter,
							p.CeaseDate ContractBoundary,
							ir.ForwardRate_LockedIn,
							cast(1 as int) RowN,
							p.StartMonth CalendarMonth,
							ir.Change_To_CSM CRTFS,
							a.AmortPerc Amort,
							i.CSM OB_CSM,
							i.LossComponent OB_LC,
							UPP.dbo.InterestAccreted(i.CSM, ir.ForwardRate_LockedIn) IR_CSM,
							UPP.dbo.InterestAccreted(i.LossComponent, ir.ForwardRate_LockedIn) IR_LC,
							UPP.dbo.CalculateCRTFS_CSM(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn) CRTFS_CSM,
							UPP.dbo.CalculateCRTFS_LC(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn) CRTFS_LC,
							UPP.dbo.CalculateBalanceBeforeAmort_CSM(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn) BB_Amort_CSM,
							UPP.dbo.CalculateBalanceBeforeAmort_LC(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn) BB_Amort_LC,
							UPP.dbo.Amortisation_CSM(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) Amort_CSM,
							UPP.dbo.Amortisation_LC(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) Amort_LC,
							UPP.dbo.ClosingBalance_CSM(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) CB_CSM,
							UPP.dbo.ClosingBalance_LC(i.CSM, i.LossComponent, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) CB_LC							
From						lppTakeonSMDataAggregated ir
							inner join ifrs2.dbo.policy_info1 p
							on p.PolicyNumber = ir.PolicyNumber
							and p.StartMonth = ir.ValuationMonth
							left join amort a
							on a.PolicyNumber = ir.PolicyNumber
							and a.ValuationMonth = ir.ValuationMonth
							left join lppIR1 i
							on i.PolicyNumber = ir.PolicyNumber
Union all
Select						cte.PolicyNumber,
							cte.Cell,
							cte.Underwriter,
							cte.ContractBoundary,
							ir.ForwardRate_LockedIn,
							cte.Rown + 1 Rown,
							Dateadd(month, 1, cte.CalendarMonth) CalendarMonth,
							ir.Change_To_CSM CRTFS,
							a.AmortPerc Amort,
							cte.CB_CSM OB_CSM,
							cte.CB_LC OB_LC,
							UPP.dbo.InterestAccreted(cte.CB_CSM, ir.ForwardRate_LockedIn) IR_CSM,
							UPP.dbo.InterestAccreted(cte.CB_LC, ir.ForwardRate_LockedIn) IR_LC,
							UPP.dbo.CalculateCRTFS_CSM(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn) CRTFS_CSM,
							UPP.dbo.CalculateCRTFS_LC(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn) CRTFS_LC,
							UPP.dbo.CalculateBalanceBeforeAmort_CSM(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn) BB_Amort_CSM,
							UPP.dbo.CalculateBalanceBeforeAmort_LC(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn) BB_Amort_LC,
							UPP.dbo.Amortisation_CSM(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) Amort_CSM,
							UPP.dbo.Amortisation_LC(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) Amort_LC,
							UPP.dbo.ClosingBalance_CSM(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) CB_CSM,
							UPP.dbo.ClosingBalance_LC(cte.CB_CSM, cte.CB_LC, ir.Change_To_CSM, ir.ForwardRate_LockedIn, a.AmortPerc) CB_LC
From						cte
							inner join lppTakeonSMDataAggregated ir
							on cte.PolicyNumber = ir.PolicyNumber
							and Dateadd(month, 1, cte.CalendarMonth) = ir.ValuationMonth
							inner join amort a
							on a.PolicyNumber = ir.PolicyNumber
							and a.ValuationMonth = ir.ValuationMonth
Where						Dateadd(month, 1, cte.CalendarMonth) <= cte.ContractBoundary
							)
Select						*
Into						CSMLCAmortisationSchedule
From						cte	
Option						(maxrecursion 200); 

-- Summary Results
Select						ir.PolicyNumber,
							i.EPVFCI_AtIR,
							i.EPVFCO_AtIR,
							i.BEL_AtIR,
							i.RA RA_AtIR,
							i.FCF_AtIR,
							i.CSM,
							i.LossComponent,
							i.BEL,
							i.RA IAIR_RA,
							i.CSM IAIR_CSM,
							i.LossComponent IAIR_LC,
							isnull(ir.BEL_CurrentCurve, 0) SM_BEL,
							isnull(ir.RA_CurrentCurve, 0) SM_RA,
							isnull(c.CB_CSM, 0) SM_CSM,
							isnull(-c.CB_LC, 0) SM_LC,
							case when i.LossComponent < 0 then 1 else 0 end OnerousAtIR,
							ir.Underwriter,
							i.GroupingYear,
							ir.Cell
From						lppTakeonSMDataAggregated ir
							left join lppIR1 i
							on i.PolicyNumber = ir.PolicyNumber
							left join CSMLCAmortisationSchedule c
							on c.PolicyNumber = i.PolicyNumber
							and c.CalendarMonth = @ValuationMonth
Where						1 = 1
							and ir.ValuationMonth = @ValuationMonth;

--- Summary of the data set used for the measurement
Select					
--p.*, 
--							b.RV_Known DataEnriched, 
--							b.RV_Ind BalloonIndicator,
--							b.ResidualAmount Balloon 

PolicyNumber			[Policy Number]		,
Cell			[Cell]		,
PlanCode			[Plan Code]		,
PlanName			[Plan Name]		,
Premium			[Premium]		,
GenderMainLife			[Gender Main Life]		,
GenderAdditionalLife1			[Gender Additional Life 1]		,
GenderAdditionalLife2			[Gender Additional Life 2]		,
SumAssuredDeath			[Sum Assured Death]		,
SumAssuredDisability			[Sum Assured Disability]		,
SumAssuredDreadedDisease			[Sum Assured Dreaded Disease]		,
SumAssuredTemporaryDisability			[Sum Assured Temporary Disability]		,
SumAssuredRetrenchment			[Sum Assured Retrenchment]		,
''			[Sum Assured Other 1]		,
SumAssuredFuneral			[Sum Assured Funeral]		,
''			[Sum Assured Other 2]		,
DateOfBirthMainLife			[Date of Birth Main Life]		,
DateOfBirthAdditionalLife1			[Date of Birth Additional Life 1]		,
DateOfBirthAdditionalLife2			[Date of Birth Additional Life 2]		,
CommencementDate			[Commencement Date]		,
StartMonth			[Start Month]		,
EvolveStartDate			[Evolve Start Date]		,
CeaseDate			[Cease Date]		,
''			[date_premiums_cease]		,
''			[date_death_cover ends]		,
''			[date_disability]		,
''			[date_dreaded_disease]		,
''			[date_temp_disab]		,
''			[date_retren_hosp]		,
''			[date6]		,
''			[date7]		,
DataEnriched			[Data Enriched]		,
BalloonIndicator			[Balloon Indicator]		,
Balloon			[Balloon]		,
Underwriter			[Underwriter]		




From						ifrs2.dbo.policy_info1 p
							left join lpp.dbo.Balloons b
							on b.POL_PolicyNumber = p.PolicyNumber




Select c.* 
from CSMLCAmortisationSchedule c
--END
