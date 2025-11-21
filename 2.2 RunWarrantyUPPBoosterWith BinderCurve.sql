-- Execution Time { 13:04 }
-- ON THE UPP DATABASE
-- DATE 01-09-2025
Use UPP;

Declare						@ValuationMonth date = '2025-09-30';

-- Declare variables
Declare						@Commission float = 0.125;
Declare						@ClaimsBinder float = 4 * 1.0000000 / 9;
Declare						@Binder float = 0.09;

-- Clear previous results
Drop table if exists		#t1;
Drop table if exists		#t2;
Drop table if exists		#t3;
Drop table if exists		#t4;
Drop table if exists		#t5;
Drop table if exists		#t6;
Drop table if exists		#t7;
Drop table if exists		#t8;
Drop table if exists		#t9;
Drop table if exists		#t10;
Drop table if exists		AndreasFeedback;
Drop table if exists		Bind_Comm;
Drop table if exists		#FinalResult;
Drop table if exists        #Booster_StartDate;
Drop table if exists		#MonthValues;
Drop table if EXISTS		#t10a;
Drop table if EXISTS		#t10b;
Drop table if exists		BoosterRerun;
 
-- ***************************************************************************
-- Indexes
--*****************************************************************************
Use Evolve;
IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE name = 'a1' AND object_id = OBJECT_ID('dbo.Policy'))
BEGIN
    CREATE NONCLUSTERED INDEX a1
    ON [dbo].[Policy] ([POL_Status],[POL_PaymentFrequency_ID])
    INCLUDE ([POL_ProductTerm_ID]);
END

IF NOT EXISTS (SELECT 1
               FROM sys.indexes
               WHERE name = 'a2' AND object_id = OBJECT_ID('dbo.PolicyMechanicalBreakdownItem'))
BEGIN
    CREATE NONCLUSTERED INDEX a2
    ON [dbo].[PolicyMechanicalBreakdownItem] ([PMI_Policy_ID])
INCLUDE ([PMI_RegistrationDate])
END
Use Upp;

-- ***************************************************************************
-- Data fix for policies with no payment frequency value
--*****************************************************************************
Update						Evolve.dbo.[Policy]
Set							POL_PaymentFrequency_ID = Case
							When RTF_Description = 'Annual' Then '2'
							When RTF_Description like 'Term%' Then '3'
							Else null
							End
From						Evolve.dbo.Policy p 
							left join Evolve.dbo.ReferenceTermFrequency rtf
							on rtf.TermFrequency_Id = p.POL_ProductTerm_ID
Where						p.pol_Paymentfrequency_ID is null
							and p.POL_ProductTerm_ID <> 4 --- Exclude monthlies
							and p.POL_Status = 1; --- Fix for only in-force policies

-- Get warranty and tyre & rim policies and save in #t1
Select						distinct p.Policy_ID,
							p.POL_PolicyNumber,
							p.POL_VatNumber WW_Policy_Key,
							p.POL_CreateDate,
							p.POL_Status,
							Case When p.POL_VatNumber = '' then 0 else 1 end IsSAWMigrated,
							pdt.PRD_Name ProductClass,
							p.POL_ProductTerm_ID,
							p.POL_StartDate,
							p.POL_OriginalStartDate,
							pmi.PMI_RegistrationDate,
							DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) StartMonth,
							DATEADD(month, DATEDIFF(month, 0, @ValuationMonth), 0) ValuationMonth,
							Case
							When DATEADD(month, DATEDIFF(month, 0, @ValuationMonth), 0)  < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then 0
							Else
							Datediff(month, DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0), DATEADD(month, DATEDIFF(month, 0, @ValuationMonth), 0)) + 1 End ElapsedMonths,
							p.POL_SoldDate,

							Case When pv1.PRV_FullName like '%Booster%' then
				            --DATEADD(month, DATEDIFF(month, case when p.POL_OriginalStartDate <= pmi.PMI_RegistrationDate then p.POL_OriginalStartDate else pmi.PMI_RegistrationDate end ,case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then p.POL_OriginalStartDate else pmi.PMI_RegistrationDate end) + RTF_TermPeriod, case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then p.POL_OriginalStartDate else pmi.PMI_RegistrationDate end) - 1 CalculatedEndDate2,
							DATEADD(month, DATEDIFF(month, case when p.POL_OriginalStartDate <= pmi.PMI_RegistrationDate then p.POL_OriginalStartDate else pmi.PMI_registrationDate end,case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then p.POL_OriginalStartDate else pmi.PMI_RegistrationDate end) + RTF_TermPeriod, case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then p.POL_OriginalStartDate else pmi.PMI_RegistrationDate end)-1 
							Else DATEADD(month, DATEDIFF(month, p.POL_OriginalStartDate, p.POL_OriginalStartDate) + RTF_TermPeriod, p.POL_OriginalStartDate)-1 end CalculatedEndDate3,
							DATEADD(month, DATEDIFF(month, case when p.POL_OriginalStartDate <= pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_registrationDate), 0)end,case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0) end) + RTF_TermPeriod, case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0) end) CalculatedEndDate2,
							Case When POL_SoldDate >= '01-Apr-2023' and pv1.PRV_FullName like '%Booster%' then
							(Case When DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0)  <= DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then
							Datediff (month, DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0), DATEADD(month, DATEDIFF(month, case when p.POL_OriginalStartDate <= pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_registrationDate), 0) end, case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0) end) + RTF_TermPeriod -1, case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0) end)) + 1 else
							Datediff(month, DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0), DATEADD(month, DATEDIFF(month, case when p.POL_OriginalStartDate <= pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_registrationDate), 0)end,case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0) end) + RTF_TermPeriod -1, case when p.POL_OriginalStartDate < pmi.PMI_RegistrationDate then DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) else DATEADD(month, DATEDIFF(month, 0, pmi.PMI_RegistrationDate), 0) end)) + 1 end) 
							else 0 end BoosterTerm,
							
							p.POL_EndDate,
							p.POL_PaymentFrequency_ID,
							p.POL_ProductVariantLevel1_ID,
							p.POL_ProductVariantLevel2_ID,
							p.POL_ProductVariantLevel3_ID,
							pv1.PRV_FullName Product_Level1,
							pv2.PRV_FullName Product_Level2,
							pv3.PRV_FullName Product_Level3,
							rcc.RCC_Description CellCaptive,
							i.INS_InsurerName,
							RTF_TermPeriod Term,
							(Select count( distinct DCH_Name) 
							from Evolve.dbo.DisbursementCurveHeader inner join Evolve.dbo.DisbursementCurveProduct on [DCP_DisbursementCurveHeader_Id] = [DisbursementCurveHeader_Id] 
							where DCH_TermFrequency_Id = p.POL_ProductTerm_ID and [DCP_Product_Id] =  p.POL_ProductVariantLevel3_ID) PhasingCurves,
							(Select top(1) DCH_Name  
							from Evolve.dbo.DisbursementCurveHeader inner join Evolve.dbo.DisbursementCurveProduct on [DCP_DisbursementCurveHeader_Id] = [DisbursementCurveHeader_Id] 
							where DCH_TermFrequency_Id = p.POL_ProductTerm_ID and [DCP_Product_Id] =  p.POL_ProductVariantLevel3_ID Order by DCH_Name) PhasingCurve1,
							(Select top(1) DCH_Name  
							from Evolve.dbo.DisbursementCurveHeader inner join Evolve.dbo.DisbursementCurveProduct on [DCP_DisbursementCurveHeader_Id] = [DisbursementCurveHeader_Id] 
							where DCH_TermFrequency_Id = p.POL_ProductTerm_ID and [DCP_Product_Id] =  p.POL_ProductVariantLevel3_ID Order by DCH_Name desc) PhasingCurve2,
							a.Agent_Id,
							a.Agt_AgentNumber,
							a.Agt_Name
Into						#t1
From						Evolve.dbo.[Policy] p
							inner join Evolve.dbo.Product pdt
							on p.POL_Product_ID = pdt.Product_Id
							left join Evolve.dbo.ProductVariant pv1
							on pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID
							left join Evolve.dbo.ProductVariant pv2
							on pv2.ProductVariant_Id = p.POL_ProductVariantLevel2_ID
							left join Evolve.dbo.ProductVariant pv3
							on pv3.ProductVariant_Id = p.POL_ProductVariantLevel3_ID
							left join Evolve.dbo.ReferenceTermFrequency rtf
							on rtf.TermFrequency_Id = p.POL_ProductTerm_ID
							left join Evolve.dbo.PolicyInsurerLink pil
							on pil.PIL_Policy_ID = p.Policy_ID
							left join Evolve.dbo.Arrangement agt
							on agt.Arrangement_Id = p.POL_Arrangement_ID
							left join Evolve.dbo.ReferenceCellCaptive rcc
							on IIF(agt.ARG_CellCaptive is null, Evolve.dbo.GetSystemSetting('AccountCellCaptive'), agt.ARG_CellCaptive) = rcc.ReferenceCellCaptive_Code
							left join Evolve.dbo.Insurer i
							on i.Insurer_Id = pil.PIL_Insurer_ID
							left join Evolve.dbo.Agent a
							on a.Agent_Id = p.POL_Agent_ID
							left join Evolve.dbo.PolicyMechanicalBreakdownItem pmi
							on pmi.PMI_Policy_ID = p.Policy_ID
							left join [UPP].[dbo].[sawenddates] saw
							on saw.POLICY_KEY = POL_VATNumber
Where						1 = 1
							and p.POL_Deleted = 0
							and pdt.PRD_Deleted = 0
							and pv1.PRV_Deleted = 0
							and pv2.PRV_Deleted = 0
							and pv3.PRV_Deleted = 0
							and rtf.RTF_Deleted = 0
							and pil.PIL_Deleted = 0
							and agt.ARG_Deleted = 0
							and rcc.RCC_Deleted = 0
							and i.INS_Deleted = 0
							and a.Agt_Deleted = 0
							--and pmi.PMI_Deleted = 0
							and pdt.Product_Id in ('219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF', '01A81AE2-8478-45FB-8C0D-5A6E796C1B39') -- Warranties and Tyre & Rim
							and p.POL_Status in (1) -- In-force policies only
							and p.POL_PaymentFrequency_ID in (2, 3) -- Term products
							and Cast(p.POL_CreateDate as Date) <= @ValuationMonth
							and p.POL_ProductTerm_ID <> 4--; -- Exclude monthlies
							and pv1.PRV_FullName like '%Booster%'
							and Dateadd(month, RTF_TermPeriod -1, DATEADD(month, DATEDIFF(month, 0, PMI_RegistrationDate), 0)) >= DATEADD(month, DATEDIFF(month, 0, @ValuationMonth), 0)
							--and pol_policynumber = 'QWTYM031222POL'
							;

Update						#t1
Set							PhasingCurve2 = 'Booster 60'
Where						Term = 60;

Update						#t1
Set							PhasingCurve2 = 'Booster 84'
Where						Term = 84;

-- Check for duplicates
Select						*,
							Row_number() over (Partition by Policy_id order by (Select 1)) RowN
Into						#t2
From						#t1;
Drop table if exists		#t1;

-- remove duplicate
Delete from #t2 where rown > 1;

--****************************************************************************************************
-- Data Fixes
--****************************************************************************************************

 -- Fix 2: Correction of policy start date to align with original policy start date
Update #t2 set POL_StartDate = '2023-03-18 00:00:00.000' where POL_PolicyNumber = 'QWTYM303985POL';
Update #t2 set POL_StartDate = '2023-03-04 00:00:00.000' where POL_PolicyNumber = 'QWTYM295889POL';

--********************************************************************************************************
-- Create the table
CREATE TABLE				#MonthValues (
							Mth INT);

WITH MthCTE AS				(
SELECT						1 AS Mth
UNION ALL
SELECT						Mth + 1
FROM						MthCTE
WHERE						Mth < 84)
INSERT INTO					#MonthValues (Mth)
SELECT						Mth
FROM						MthCTE
OPTION						(MAXRECURSION 0);

-- Add information about earned and unearned portion
With a as					(
Select						#t2.*,
							m.Mth,
							Dateadd(month, m.Mth - 1, DATEADD(month, DATEDIFF(month, 0, PMI_RegistrationDate), 0)) CalendarMonth,
							Case
								When Dateadd(month, m.Mth - 1, DATEADD(month, DATEDIFF(month, 0, PMI_RegistrationDate), 0)) < StartMonth then 0
								Else 1
							End Covered,
							1 OEMCover,
							sum(1) over (Partition by Pol_PolicyNumber order by Mth) ExposureMonth
From						#t2
							Cross join #MonthValues m
Where						m.Mth <= Term)
Select						a.*,
							e.EarningCurve * 1.000000 / 100  EarnedPortion,
							(e.EarningCurve * 1.000000 / 100) * Covered ProRataPortion,

							sum(e.EarningCurve * 1.000000 / 100 * covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and Current row )* 1.00 /
							sum((e.EarningCurve * 1.000000 / 100) * Covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and unbounded following) FinalEarnedPortion,
							
							1-(sum(e.EarningCurve * 1.000000 / 100 * covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and Current row )* 1.00 /
							sum((e.EarningCurve * 1.000000 / 100) * Covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and unbounded following)) FinalUnEarnedPortion,
							
							1-(sum(c.EarningCurve * 1.000000 / 100 * covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and Current row )* 1.00 /
							sum((c.EarningCurve * 1.000000 / 100) * Covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and unbounded following)) FinalUnEarnedPortion2,

							1-((SUM(Covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and Current row )) * 1.00 /
							sum(Covered) over (Partition by Pol_PolicyNumber order by ExposureMonth rows between unbounded preceding and unbounded following)) DACPortion


Into						#t3
From						a
							left join Ecurves e
							on a.PhasingCurve2 = e.curve
							and a.ExposureMonth = e.Month	
							left join Ecurves1 c
							on CAST(a.Term as varchar(50)) = c.curve
							and a.ExposureMonth = c.Month;


-- Get the fund values for policies in Warranty World

Select	                    s.*,
							isnull(mig.mta_nett_prem, p.mta_nett_prem) WW_Nett_Premium
Into						#t4
From						SAWME5.dbo.sawfund s
							inner join SAWME5.dbo.fmspolicy f
							on s.policy_key = f.policy_key
							inner join SAWME5.dbo.mwtempacc p
							on p.mta_ref_tran = s.policy_key
							left join (Select a.policy_key, p.mta_nett_prem
							from SAWME5.dbo.aa_mwpolicy a, SAWME5.dbo.mwtempacc p
							where a.old_pol_key = p.mta_ref_tran) mig
							on mig.policy_key = s.policy_key
Where						1 = 1
							and busclass = 'Warranty'
							and pol_end_date >= '01-January-2023';


Select						#t3.*,
							#t4.Nett_Fund WW_Nett_Fund,
							#t4.WW_Nett_Premium,
							s.POL_END_Date WW_End_Date,
							Case when s.POL_End_Date != POL_EndDate then s.POL_End_Date else POL_EndDate end Valuation_End_Date
Into						#t5
From						#t3
							left join #t4
							on #t3.WW_Policy_Key = #t4.Policy_Key
							left join [UPP].[dbo].sawenddates s
							on s.Policy_key = #t3.WW_Policy_Key;
	
Drop table if exists		#t3;
Drop table if exists		#t4;

-- Calculate the fund for policies in Evolve but not in Warranty World
Select						ats.ATS_TransactionNumber,
							p.POL_PolicyNumber,
							p.Policy_ID,
							dbt.DBT_Description,
							atn.ATN_AccountParty_ID,                       
                            apt.APT_Description,
							aar.AAR_Description,                 
                            atn.ATN_GrossAmount,
							atn.ATN_NettAmount,
                            dbs.DBS_SetName,
							dsm.DSM_RuleName,
                            rgl.GLC_Description,
							rgl.GLC_GlCode,
							atn.ATN_DisbursementStep,
                            ats.ATS_EffectiveDate
Into						#t6
From						(Select distinct POL_PolicyNumber, Policy_ID from #t5)p 
                            left join Evolve.dbo.AccountTransactionSet ats
							on p.Policy_ID = ats.ATS_ReferenceNumber
                            left join Evolve.dbo.AccountTransaction atn 
                            on ats.AccountTransactionSet_Id = atn.ATN_AccountTransactionSet_ID
                            left join Evolve.dbo.AccountParty apy 
                            on apy.AccountParty_Id = atn.ATN_AccountParty_ID                    
                            left join Evolve.dbo.AccountPartyType apt
                            on APT.AccountPartyType_Id = APY.APY_PartyType_ID
                            left join Evolve.dbo.AccountArea AAR 
                            on AAR.AccountArea_Id = ATS.ATS_AccountArea_ID
                            and AAR.AAR_Deleted = 0
                            left join [Evolve].[dbo].[DisbursementType] DBT 
                            on atn.ATN_DisbursementType_ID = dbt.DisbursementType_Id
                            and DBT.DBT_Deleted = 0
                            left join [Evolve].dbo.DisbursementSet DBS 
                            on DBS.DisbursementSet_Id = ATS.ATS_DisbursementRule_ID 
                            and DBS.DBS_Deleted = 0
                            left join [Evolve].dbo.Disbursement DSM
                            on DSM.Disbursement_Id = DBS.DBS_Disbursement_ID
                            and DSM.DSM_Deleted = 0
                            left join Evolve.[dbo].[ReferenceGLCode] RGL 
                            on ATN_GLCode_ID = RGL.GlCode_ID
                            and RGL.GLC_Deleted = 0
Where                       1 = 1
                            and APT.APT_Description = 'Insurer';

Select                       * 
Into                         #t7
From 
(
Select                       pol_policyNumber, glc_description, ATN_NettAmount 
From                         #t6
Where                        DBS_SetName is not null
) a
pivot
(
                            Sum(ATN_NettAmount) for 
                            glc_description in (
							[Gross Written Premium],
							[Commission Paid],
							[Inspection Fees Paid],
							[Outsource Fees],
							[Roadside Assistance Fees],
							[Binder Fees - Acquisition Costs],
							[E-Platform Fees],
							[Underwriter Fees Paid],
							[Cell Differential Fees],
							[Binder Fees - Claims],
							[Bordereaux Bank Fees],
							[Bank Fees])
) as D

Select                     #t7.*, -[Gross Written Premium]-(isnull([Commission Paid],0) + isnull([Inspection Fees Paid],0)+ isnull([Outsource Fees],0) + isnull([Roadside Assistance Fees],0)
						   + isnull([Binder Fees - Acquisition Costs],0) + isnull([E-Platform Fees],0) + isnull([Underwriter Fees Paid],0) + isnull([Cell Differential Fees],0) + isnull([Bordereaux Bank Fees],0)
						   + isnull([Binder Fees - Claims],0) + isnull([Bank Fees],0)) Fund										
Into                       #t8
From                       #t7;

Select                     h.* , 
						   --j.Fund Evolve_Fund, 
						   Case When j.Fund < 0 Then -j.Fund Else j.Fund End Evolve_Fund,
						   Case When -j.[Gross Written Premium] < 0 Then j.[Gross Written Premium] Else -j.[Gross Written Premium] End Evolve_Premium,
						   Case When j.[Commission Paid] < 0 Then -j.[Commission Paid] Else j.[Commission Paid] End Evolve_Commission,
						   (Case When j.[Binder Fees - Claims] < 0 Then -j.[Binder Fees - Claims] Else j.[Binder Fees - Claims] End)
						   + (Case When j.[Binder Fees - Acquisition Costs] < 0 Then -j.[Binder Fees - Acquisition Costs] Else j.[Binder Fees - Acquisition Costs] End) Evolve_Binder,
						   Case When j.[Roadside Assistance Fees] < 0 Then -j.[Roadside Assistance Fees] Else j.[Roadside Assistance Fees] End Evolve_Roadside,
						   Case When j.[Binder Fees - Claims] < 0 Then -j.[Binder Fees - Claims] Else j.[Binder Fees - Claims] End [Binder Fees - Claims],
						   Case When j.[Binder Fees - Acquisition Costs] < 0 Then -j.[Binder Fees - Acquisition Costs] Else j.[Binder Fees - Acquisition Costs] End [Binder Fees - Acquisition Costs],
						   Case When j.[Outsource Fees] < 0 Then -j.[Outsource Fees] Else j.[Outsource Fees] End [Outsource Fees],
						   Case When j.[Underwriter Fees Paid] < 0 Then -j.[Underwriter Fees Paid] Else j.[Underwriter Fees Paid] End [Underwriter Fees Paid]
Into                       #t9              
From                       #t5 h
                           left join #t8 j
						   on j.POL_PolicyNumber = h.POL_PolicyNumber;

Drop table if exists		#t5;
Drop table if exists		#t6;
Drop table if exists		#t7;
Drop table if exists		#t8;

-- Adjustments from Andreas
Create table				AndreasFeedback (PolicyNumber varchar(50), PremiumIncVaT float, SAWPdtCode varchar(10), FundPerc float, FundExclVaT float);
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM295886POL', '995', '9072', '0.699989949748744', '605.64347826087');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM297996POL', '995', '9072', '0.699989949748744', '605.64347826087');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM297573POL', '995', '9072', '0.699989949748744', '605.64347826087');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM303774POL', '995', '9072', '0.699989949748744', '605.64347826087');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM296659POL', '995', '9072', '0.699989949748744', '605.64347826087');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM305720POL', '995', '9072', '0.699989949748744', '605.64347826087');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM303023POL', '2250', '10914', '0.472417777777778', '924.295652173913');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM302728POL', '2250', '10914', '0.472417777777778', '924.295652173913');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTYM303341POL', '2250', '7078', '0.477777777777778', '934.782608695652');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTYM301509POL', '2250', '7078', '0.477777777777778', '934.782608695652');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTYM305322POL', '2250', '7078', '0.477777777777778', '934.782608695652');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM296646POL', '3250', '10551', '0.542443076923077', '1532.99130434783');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM296468POL', '3250', '10551', '0.542443076923077', '1532.99130434783');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTY000114POL', '3250', '10551', '0.542443076923077', '1532.99130434783');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM295885POL', '3250', '10551', '0.542443076923077', '1532.99130434783');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM289582POL', '5040', '11177', '0.583257936507936', '2556.19130434783');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM176729POL', '5040', '11177', '0.583257936507936', '2556.19130434783');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM303166POL', '5495', '10846', '0.427022747952684', '2040.42608695652');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM296227POL', '5495', '10846', '0.427022747952684', '2040.42608695652');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM295626POL', '7110', '9144', '0.417150492264416', '2579.07826086957');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTY000102POL', '7315', '11187', '0.646904989747095', '4114.87826086957');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTY000445POL', '7547', '10834', '0.397140585663177', '2606.27826086957');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTY000258POL', '7899', '11248', '0.650830484871503', '4470.35652173913');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTYM305148POL', '7899', '11248', '0.650830484871503', '4470.35652173913');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('QWTY000353POL', '7899', '11248', '0.650830484871503', '4470.35652173913');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTYM306113POL', '10900', '10779', '0.454862385321101', '4311.30434782609');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTY000413POL', '10900', '10779', '0.454862385321101', '4311.30434782609');
Insert into					AndreasFeedback (PolicyNumber, PremiumIncVaT, SAWPdtCode, FundPerc, FundExclVaT) values ('HWTYM295557POL', '16300', '10818', '0.497147239263804', '7046.52173913043');

-- Bring commission, binder and migration indicator from warranty world
With com                    as (-- Dealer commission
Select                      mta_ref_tran Policy_key,
                            sum(mtp_nett_total) Commission
From                        sawme5.dbo.mwtempaccuppview
Where                       dbt_Desc in ('Dealer Commission', 'Telesales Comm')
Group by					mta_ref_tran),
b as                        ( -- Binder fees
Select                      mta_ref_tran Policy_key,
                            mtp_nett_total Binder
From                        sawme5.dbo.mwtempaccuppview
Where                       dbt_Desc = 'Binder Fee'),
rsa as                      ( -- Roadside assistance fee
Select                      mta_ref_tran Policy_key,
                            mtp_nett_total Roadside
From                        sawme5.dbo.mwtempaccuppview
Where                       mtp_disbursementtype_cde = 210),
pol as                      ( -- distinct list of policy numbers
Select                      Policy_key from com union
Select                      Policy_key from b union
Select                      Policy_key from rsa),
res as                      (
Select                      pol.Policy_key,
                            isnull(com.Commission, 0) Commission,
                            isnull(b.Binder, 0) Binder,
                            isnull(rsa.Roadside, 0) Roadside
From                        pol
                            left join com
                            on pol.Policy_key =  com.Policy_key
                            left join b
                            on b.Policy_key = pol.Policy_key
                            left join rsa
                            on rsa.Policy_key = pol.Policy_key
                            )
Select                      r.*, isnull(gc.is_migrated,0) Is_Migrated
Into                        [dbo].Bind_Comm
From                        res r
                            left join sawme5.dbo.group_cells gc
                            on gc.policy_key = r.policy_key;  

-- Combine the various data sources
Select						#t9.*,
							bc.Binder WW_Binder,
							bc.Commission WW_Commission,
							bc.Roadside WW_Roadside,
							bc.Is_Migrated WW_IsMigrated,
							ud.WW_Net_Comm WW_Nett_Comm,
							ud.WW_Net_Outsource WW_Nett_Outsource,
							ud.WW_Net_BA WW_Nett_BA,
							ud.WW_Net_BC WW_Nett_BC,
							ud.WW_Net_Underwriter_Fee WW_Nett_Underwriter_Fee,
							af.SAWPdtCode,
							af.PremiumIncVaT * 1.000000 / 1.15 EvolvePremiumExcVaTUpdated,
							af.FundExclVaT,
							af.FundPerc
Into						#t10
From						#t9
							left join [UPP].[dbo].Bind_Comm bc
							on bc.Policy_key = #t9.WW_Policy_Key
							left join [SAWME5].[dbo].[UPP_Disbursement] ud
							on ud.Policy_key = #t9.WW_Policy_Key
							left join AndreasFeedback af
							on af.PolicyNumber = #t9.POL_PolicyNumber;
Drop table if exists		#t9;

--*****************************************************************************************************
---Data Fixes
--*****************************************************************************************************

-- Fix 1: Migrated policy that has no account transaction information: SAW-2961895-POL

Update						#t10 
Set							Evolve_Premium  = 6182.61, 
							Evolve_Fund = 2577.19, 
							Evolve_Binder = 556.42, 
							Evolve_Commission = 772.83, 
							Evolve_Roadside = 346.96
Where						POL_PolicyNumber = 'QWTYM303431POL';


Update						#t10 
Set							Evolve_Premium  = 4382.61, 
							Evolve_Fund = 2530.11, 
							Evolve_Binder = 394.42, 
							Evolve_Commission = 547.83, 
							Evolve_Roadside = 337.72
Where						POL_PolicyNumber = 'QWTY011241POL';


Update						#t10 
Set							Evolve_Premium  = 4778.26, 
							Evolve_Fund = 2028.15, 
							Evolve_Binder = 430.06, 
							Evolve_Commission = 597.29
Where						POL_PolicyNumber = 'QWTY000790POL';


Update						#t10 
Set							Evolve_Premium  = 6868.7, 
							Evolve_Fund = 3066.7, 
							Evolve_Binder = 618.17, 
							Evolve_Commission = 858.59, 
							Evolve_Roadside = 337.72
Where						POL_PolicyNumber = 'QWTY002649POL';

Update						#t10 
Set							Evolve_Premium  = 6868.7, 
							Evolve_Fund = 3066.7, 
							Evolve_Binder = 618.17, 
							Evolve_Commission = 858.59, 
							Evolve_Roadside = 337.72
Where						POL_PolicyNumber = 'QWTYM303972POL';

Update						#t10 
Set							Evolve_Premium  = 7477.39, 
							Evolve_Fund = 3483.52, 
							Evolve_Binder = 672.97, 
							Evolve_Commission = 934.68, 
							Evolve_Roadside = 346.96
Where						POL_PolicyNumber = 'QWTY002752POL';

Update						#t10 
Set							Evolve_Premium  = 2826.09, 
							Evolve_Fund = 1965.89, 
							Evolve_Binder = 254.34, 
							Evolve_Commission = 353.26, 
							Evolve_Roadside = 0
Where						POL_PolicyNumber = 'QWTY019322POL';

Update						#t10 
Set							Evolve_Premium  = 6607.83, 
							Evolve_Fund = 598.71, 
							Evolve_Binder = 594.7, 
							Evolve_Commission = 825.98, 
							Evolve_Roadside = 693.92
Where						POL_PolicyNumber = 'HWTY055874POL';


Update						#t10 
Set							WW_Nett_Fund = 7400.869565, 
							WW_Nett_Premium = 14173.91304, 
							WW_Binder = 1275.652174, 
							WW_Commission = 1771.73913, 
							WW_Roadside = 346.956522,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-3272024-POL';

Update						#t10 
Set							WW_Nett_Fund = 2581.756522, 
							WW_Nett_Premium = 4382.608696, 
							WW_Binder = 394.434783, 
							WW_Commission = 547.826087, 
							WW_Roadside = 0,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-3249068-POL';

Update						#t10 
Set							WW_Nett_Fund = 3030.32 * 1.0000 / 1.15, 
							WW_Nett_Premium = 7599 * 1.0000 / 1.15, 
							WW_Binder = 0.09 * 7599 * 1.0000 / 1.15, 
							WW_Commission = 949.88 * 1.0000 / 1.15, 
							WW_Roadside = 399 * 1.0000 / 1.15,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-2961895-POL';

Update						#t10 
Set							WW_Nett_Fund = 2346.49 * 1.0000 / 1.15, 
							WW_Nett_Premium = 5495 * 1.0000 / 1.15, 
							WW_Binder = 0.09 * 5495  * 1.0000 / 1.15, 
							WW_Commission = 686.88 * 1.0000 / 1.15, 
							WW_Roadside = 0,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-3265842-POL';

Update						#t10 
Set							WW_Nett_Fund = 1587.9 * 1.0000 / 1.15, 
							WW_Nett_Premium = 2485.20 * 1.0000 / 1.15, 
							WW_Binder = 0.09 * 2485.20 * 1.0000 / 1.15, 
							WW_Commission = 310.65 * 1.0000 / 1.15, 
							WW_Roadside = 137.5 * 1.0000 / 1.15,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-3295443-POL';

Update						#t10 
Set							Evolve_Premium = 6878.1, 
							Evolve_Fund = 3073.26, 
							Evolve_Binder = 619.02, 
							Evolve_Commission = 859.77, 
							Evolve_Roadside = 337.72,
							WW_IsMigrated = 0 
Where						POL_PolicyNumber = 'QWTY001440POL';

Update						#t10 
Set							Evolve_Premium = 4771.71, 
							Evolve_Fund = 3327.94, 
							Evolve_Binder = 429.46, 
							Evolve_Commission = 596.46, 
							Evolve_Roadside = 0,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-3300581-POL';

Update						#t10 
Set							Evolve_Premium = 4784.81, 
							Evolve_Fund = 3337.13, 
							Evolve_Binder = 430.62, 
							Evolve_Commission = 598.10, 
							Evolve_Roadside = 0,
							WW_IsMigrated = 0 
Where						WW_Policy_Key = 'SAW-3294961-POL';

-- Fix 2: Correct the binder fee disbursement which is negative for policy SAW-1648983-POL.
Update						#t10 
Set							WW_Binder = '1005.652174',
							WW_Roadside = 0
Where						WW_Policy_Key = 'SAW-1648983-POL';


Update						#t10 
Set							Evolve_Fund = '276.19',
							Evolve_Premium = '684.25',
							Evolve_commission = '85.53', 
							Evolve_Binder = '61.57'
Where						POL_PolicyNumber = 'QWTY006001POL';

Update						#t10 
Set							Evolve_Fund = '290.94',
							Evolve_Premium = '681.28',
							Evolve_commission = '85.15', 
							Evolve_Binder = '61.31'
Where						POL_PolicyNumber = 'QWTY000815POL';

Update						#t10 
Set							CellCaptive = 'Auto Pedigree'
Where						POL_PolicyNumber = 'QWTYM057372POL';

Update						#t10 
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY068234POL';

Update						#t10 
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY066806POL';

Update						#t10 
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY067381POL';

--*********************************************************************************************
-- Calculate UPP --calculation changed compared to the 202506 valuation month
--**********************************************************************************************

Select						t.*,
							ISNULL(WW_Nett_Fund, Isnull(FundExclVaT, Evolve_Fund)) * FinalEarnedPortion EarnedFund,
							/*
							ISNULL(WW_Nett_Fund, Isnull(FundExclVaT, Evolve_Fund)) 
							-
							sum(ISNULL(WW_Nett_Fund, Isnull(FundExclVaT, Evolve_Fund)) * FinalEarnedPortion) over (Partition by Pol_PolicyNumber order by Mth) 
							*/
							ISNULL(WW_Nett_Fund, Isnull(FundExclVaT, Evolve_Fund)) * FinalUnEarnedPortion UnearnedFund
Into						#t10a
From						#t10 t;


-- Only take rows corresponding to the valuation month
Select						t.*,
							DACPortion
							*
							ISNULL(WW_Commission, Isnull(EvolvePremiumExcVaTUpdated, case when Evolve_Premium < 0 Then 0 Else Evolve_Premium end) * @Commission) 
							*
							Isnull(1 - WW_IsMigrated, 1)
							* Case when INS_InsurerName = 'Centriq Short Term' then 1 else 0 end 
							DAC,		
							DACPortion
							*
							ISNULL(WW_Nett_Outsource, [Outsource Fees]) 
							*
							Isnull(1 - WW_IsMigrated, 1)
							* Case when INS_InsurerName = 'Centriq Short Term' then 1 else 0 end 
							DAC_Out,
							DACPortion
							*
							ISNULL(WW_Nett_BA, [Binder Fees - Acquisition Costs]) 
							*
							Isnull(1 - WW_IsMigrated, 1)
							* Case when INS_InsurerName = 'Centriq Short Term' then 1 else 0 end 
							DAC_Acq,
							DACPortion
							*
							ISNULL(WW_Nett_BC, [Binder Fees - Claims]) 
							*
							Isnull(1 - WW_IsMigrated, 1)
							* Case when INS_InsurerName = 'Centriq Short Term' then 1 else 0 end 
							DAC_Binder_Claims,
							DACPortion
							*
							ISNULL(WW_Nett_Underwriter_Fee, [Underwriter Fees Paid]) 
							*
							Isnull(1 - WW_IsMigrated, 1)
							* Case when INS_InsurerName = 'Centriq Short Term' then 1 else 0 end 
							DAC_Underwriter,
						    FinalUnEarnedPortion2
							*
							ISNULL(WW_Binder, Isnull(EvolvePremiumExcVaTUpdated, Case When Evolve_Premium < 0 Then 0 Else Evolve_Premium end ) * @Binder) 
							* @ClaimsBinder * Isnull(1 - WW_IsMigrated, 1) BinderUPP,
							Case
								When ISNULL(WW_Nett_Fund, Isnull(FundExclVaT, Evolve_Fund)) = 0 Then 0
								Else (UnearnedFund * 1.00 / ISNULL(WW_Nett_Fund, Isnull(FundExclVaT, Evolve_Fund)))
							End
							*
							ISNULL(WW_Roadside, Evolve_Roadside) 
							 *
							Case when CellCaptive in ('AMH','Motus Imports') then 0 else 1 end
							RoadsideUPP
Into                        #FinalResult
From						#t10a t
Where						ValuationMonth = CalendarMonth;

--Policies Fixes
Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY055215POL';

Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY044575POL';

Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY062544POL';

Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY061907POL';

Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY071874POL';

Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY072143POL';

Update						#FinalResult
Set							CellCaptive = 'Motus Imports'
Where						POL_PolicyNumber = 'QWTY072574POL';

Drop table if exists		#t10a;

--*********************************************************************************************
-- Export file
--*********************************************************************************************

Select						Policy_ID,
							POL_PolicyNumber,
							WW_Policy_Key,
							ProductClass,
							POL_OriginalStartDate,
							StartMonth,
							ValuationMonth,
							ElapsedMonths,
							Case When POL_SoldDate > ValuationMonth Then POL_CreateDate Else POL_SoldDate End Pol_SoldDate,	
							CalculatedEndDate3 POL_EndDate,
							Product_Level1,
							Product_Level2,
							Product_Level3,
							CellCaptive,
							INS_InsurerName,
							Term,
							PhasingCurve2 PhasingCurve,
							Agt_Name,
							FinalEarnedPortion EarnedPortion,
                            FinalUnEarnedPortion UnearnedPortion,
							WW_Nett_Premium,
							WW_Nett_Fund,
							WW_Binder WW_Nett_Binder,
							WW_Commission WW_Nett_Commission,
							WW_Roadside,
							WW_IsMigrated,
							Isnull(EvolvePremiumExcVaTUpdated, Evolve_Premium) Evolve_Nett_Premium,
							Isnull(FundExclVaT, Evolve_Fund) Evolve_Nett_Fund,
							Evolve_Binder Evolve_Nett_Binder,
							Evolve_Commission Evolve_Nett_Commission,
							Evolve_Roadside Evolve_Roadside,
							UnearnedFund,
							UnearnedFund UPP,
							DAC,
							BinderUPP,
							RoadsideUPP,
							BoosterTerm,
							POL_CreateDate,
							DAC_Out,
							DAC_Acq,
							DAC_Binder_Claims,
							DAC_Underwriter,
							PMI_RegistrationDate

Into						[UPP].[dbo].[SAW_UPP_202509_Booster]
From						#FinalResult
Where                       UnearnedFund is not null
                            and UnearnedFund >= 0;

Drop table if exists #FinalResult;
-----------------------------------------------------------------------------------------------TEST
--SELECT COUNT(*) FROM [UPP].[dbo].[SAW_UPP_202508_Booster] --126 583
--SELECT COUNT(*) FROM [UPP].[dbo].[SAW_UPP_202507_Booster_2] --126 988














