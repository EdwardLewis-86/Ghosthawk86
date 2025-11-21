--Runtime 
-- Define database
Use							Evolve;

-- Declare variables
Declare						@vmonth date = '30-Sep-2025'; -- Use end of the month of the previous month of interest
--Declare						@commission float = 0.125;


-- Clear previous results
Drop table if exists		#k1;
Drop table if exists		#k2;
Drop table if exists		#k3;
Drop table if exists		#k4;
Drop table if exists		#k5;
Drop table if exists		#k6;
Drop table if exists		#k7;
Drop table if exists		#k8;
Drop table if exists		#Result;



-- Get warranty policies and save in #k1
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
							DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) StartMonth,
							DATEADD(month, DATEDIFF(month, 0, @vmonth), 0) ValuationMonth,
							Case
							When DATEADD(month, DATEDIFF(month, 0, @vmonth), 0)  < DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0) then 0
							Else
							Datediff(month, DATEADD(month, DATEDIFF(month, 0, p.POL_OriginalStartDate), 0), DATEADD(month, DATEDIFF(month, 0, @vmonth), 0)) + 1 End ElapsedMonths,
							p.POL_SoldDate,
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
							from DisbursementCurveHeader inner join DisbursementCurveProduct on [DCP_DisbursementCurveHeader_Id] = [DisbursementCurveHeader_Id] 
							where DCH_TermFrequency_Id = p.POL_ProductTerm_ID and [DCP_Product_Id] =  p.POL_ProductVariantLevel3_ID) PhasingCurves,
							(Select top(1) DCH_Name  
							from DisbursementCurveHeader inner join DisbursementCurveProduct on [DCP_DisbursementCurveHeader_Id] = [DisbursementCurveHeader_Id] 
							where DCH_TermFrequency_Id = p.POL_ProductTerm_ID and [DCP_Product_Id] =  p.POL_ProductVariantLevel3_ID Order by DCH_Name) PhasingCurve1,
							(Select top(1) DCH_Name  
							from DisbursementCurveHeader inner join DisbursementCurveProduct on [DCP_DisbursementCurveHeader_Id] = [DisbursementCurveHeader_Id] 
							where DCH_TermFrequency_Id = p.POL_ProductTerm_ID and [DCP_Product_Id] =  p.POL_ProductVariantLevel3_ID Order by DCH_Name desc) PhasingCurve2,
							a.Agent_Id,
							a.Agt_AgentNumber,
							a.Agt_Name
Into						#k1
From						Policy p
							inner join Product pdt
							on p.POL_Product_ID = pdt.Product_Id
							left join ProductVariant pv1
							on pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID
							left join ProductVariant pv2
							on pv2.ProductVariant_Id = p.POL_ProductVariantLevel2_ID
							left join ProductVariant pv3
							on pv3.ProductVariant_Id = p.POL_ProductVariantLevel3_ID
							left join ReferenceTermFrequency rtf
							on rtf.TermFrequency_Id = p.POL_ProductTerm_ID
							left join vw_PolicySetDetails vpsd
							on vpsd.PolicyId = p.Policy_ID
							left join ReferenceCellCaptive rcc
							on rcc.ReferenceCellCaptive_Code = vpsd.CellCaptiveId
							left join Insurer i
							on i.Insurer_Id = vpsd.InsurerId
							left join Agent a
							on a.Agent_Id = p.POL_Agent_ID
Where						1 = 1
							and pdt.Product_Id in ('83C026A9-17FF-4A87-9CA9-E82C2535B538') -- Combo
							and i.Insurer_Id in ('28BEBA82-5AD3-49A7-A9F0-714542B6B2A8') --Santam
							and p.POL_Deleted = 0
							and p.POL_Status in (1) -- In-force policies only 
							--and p.POL_PaymentFrequency_ID in (2, 3) -- Term products
							and Cast(p.POL_CreateDate as Date) <= @vmonth;
					--		and POL_PolicyNumber = 'SWTY000529POL-03';


-- Check for duplicates
Select						*,
							Row_number() over (Partition by Policy_id order by (Select 1)) RowN
Into						#k2
From						#k1;
--select * from #k2
-- Add information about earned and unearned portion
Select						#k2.*,
							Case
							When ElapsedMonths = 0 then 0
							When ElapsedMonths > Term then 1
							When lower(#k2.PhasingCurve2) like '%cnv%' then (ElapsedMonths * 1.000000 / Term)
							Else
							(Select Sum(DCI_MonthlyPercentage * 1.000000 / 100)
							From DisbursementCurveItem dci, DisbursementCurveHeader dch
							Where dci.DCI_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
							and dch.DCH_Name = #k2.PhasingCurve2
							and dci.DCI_Month <= ElapsedMonths
							) End EarnedPortion,
							Case
							When ElapsedMonths = 0 then 1
							When ElapsedMonths > Term then 0
							When lower(#k2.PhasingCurve2) like '%cnv%' then 1 - (ElapsedMonths * 1.000000 / Term)
							Else
							(Select 1 - Sum(DCI_MonthlyPercentage * 1.000000 / 100)
							From DisbursementCurveItem dci, DisbursementCurveHeader dch
							Where dci.DCI_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id
							and dch.DCH_Name = #k2.PhasingCurve2
							and dci.DCI_Month <= ElapsedMonths
							) End UnearnedPortion
Into						#k3
From						#k2
Where						1 = 1
							and Rown = 1;
--select * from #k3;
						
-- Calculate the fund for policies
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
Into						#k4
From						#k3 p 
                            left join AccountTransactionSet ats
							on p.Policy_ID = ats.ATS_ReferenceNumber
                            left join AccountTransaction atn 
                            on ats.AccountTransactionSet_Id = atn.ATN_AccountTransactionSet_ID
                            left join AccountParty apy 
                            on apy.AccountParty_Id = atn.ATN_AccountParty_ID                    
                            left join AccountPartyType apt
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
Into                         #k5
From 
(
Select                       pol_policyNumber, glc_description, ATN_NettAmount 
From                         #k4
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

Select                     #k5.*, -[Gross Written Premium]-(isnull([Commission Paid],0) + isnull([Inspection Fees Paid],0)+ isnull([Outsource Fees],0) + isnull([Roadside Assistance Fees],0)
						   + isnull([Binder Fees - Acquisition Costs],0) + isnull([E-Platform Fees],0) + isnull([Underwriter Fees Paid],0) + isnull([Cell Differential Fees],0) + isnull([Bordereaux Bank Fees],0)
						   + isnull([Binder Fees - Claims],0) + isnull([Bank Fees],0)) Fund
Into                       #k6
From                       #k5;

Select                     h.* , 
						   j.Fund Evolve_Fund, 
						   -j.[Gross Written Premium] Evolve_Premium
Into                       #k7                       
From                       #k3 h
                           left join #k6 j
						   on j.POL_PolicyNumber = h.POL_PolicyNumber;

						   select * from #k7

--*********************************************************************************************
-- Calculate UPP
--**********************************************************************************************
Select						#k7.*,
							case when ElapsedMonths > Term then 0
							when ElapsedMonths = 0 then 1
							Else UnearnedPortion End 
							* Evolve_Fund UnearnedFund,
							case when ElapsedMonths > Term then 0
							when ElapsedMonths = 0 then 1
							Else UnearnedPortion End 
							*
							 Evolve_Fund * 1.000000 / 0.95 UPP
							
Into                        #Result
From						#k7;

WITH A AS(
select --ValuationMonth, 
CellCaptive , POL_PolicyNumber, 
SUM(UPP) AS [UPP] from #Result
Where                       UnearnedFund is not null
                            and UnearnedFund >= 0
							GROUP BY  CellCaptive ,  POL_PolicyNumber
							)
							SELECT * FROM A WHERE UPP>0;