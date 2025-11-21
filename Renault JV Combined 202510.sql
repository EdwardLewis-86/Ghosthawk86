


-- Drops
Drop table if exists						#Pol;
Drop table if exists	                    #ClaimsInfo;
Drop table if exists	                    #WWFund;
Drop table if exists	                    #WFund;
Drop table if exists	                    #FundR;
Drop table if exists	                    #Fund;
Drop table if exists	                    #Amh;
Drop table if exists	                    #WWClaims;
Drop table if exists	                    #migaration;
Drop table if exists	                    #EarnedFund;
Drop table if exists	                    #monthlyFund;
Drop table if exists	                    #AggMonthlyFund;
Drop table if exists	                    #res;


--Migatated pols to Centriq from Hollard

SELECT  [POLICY_KEY] [NEW_POLICY_KEY]
     
      ,[OLD_POL_KEY]

	  ,n.MTP_AMOUNT_TOTAL MTP_AMOUNT_TOTAL_N

	  ,o.MTP_AMOUNT_TOTAL MTP_AMOUNT_TOTAL_O

	  into #migaration
      
  FROM [SAWME5].[dbo].[aa_mwpolicy]

  left join [SAWME5].[dbo].[MWTEMPACCUPPVIEW] n on n.MTA_REF_TRAN = [POLICY_KEY]
  left join [SAWME5].[dbo].[MWTEMPACCUPPVIEW] o on o.MTA_REF_TRAN = [OLD_POL_KEY]


  where 1=1
  
       and n.MTP_DISBURSEMENTTYPE_CDE =171
	   and o.MTP_DISBURSEMENTTYPE_CDE =171


--select * from #migaration where NEW_POLICY_KEY = 'SAW-2016676-POL'
--select * from #migaration where NEW_POLICY_KEY = 'SAW-1579531-POL'


--Earned fund for Active Pols

SELECT [POL_PolicyNumber]

      ,[WW_Nett_Fund]

      ,[Evolve_Nett_Fund]

	  ,case when [WW_Nett_Fund] is null then [Evolve_Nett_Fund]
	  else [WW_Nett_Fund] end Fund
      ,[UnearnedFund]
	  ,case when [WW_Nett_Fund] is null then [Evolve_Nett_Fund]
	  else [WW_Nett_Fund] end - [UnearnedFund] [EarnedFund]

	  into #EarnedFund

  FROM [UPP].[dbo].[SAW_UPP_202509] --change

  --select * from SAWME5.dbo.mwtempaccuppview  where MTA_REF_TRAN = 'SAW-1983351-POL'

--WW Fund

SELECT  
[POLICY_KEY],[MWA_DATE_PURCHASED]


     ,sum([EARNED_FUND] ) [EARNED_FUNDIncVAT] 

     ,sum([EARNED_FUND]* 1/(case when [CALENDAR_MONTH] <'2018-04-01'  then 1.14 else 1.15 end) ) [EARNED_FUNDnetVATbyCALENDAR_MONTH] 
	 
	 ,sum([EARNED_FUND]* 1/(case when [MWA_DATE_PURCHASED] <'2018-04-01'  then 1.14 else 1.15 end) ) [EARNED_FUNDnetVATbyDATE_PURCHASED]


	into                    #WFund 

  FROM [SAWME5].[dbo].[fend_aa1_earned_fund_report]

	group by [POLICY_KEY],[MWA_DATE_PURCHASED]


	--add Migration Fund WW Fund

SELECT  
      [POLICY_KEY],[MWA_DATE_PURCHASED]

     ,[EARNED_FUNDIncVAT] 

     , [EARNED_FUNDnetVATbyCALENDAR_MONTH] 
	 
	 , case when  (MTP_AMOUNT_TOTAL_O is null and MTP_AMOUNT_TOTAL_N is null) then [EARNED_FUNDnetVATbyDATE_PURCHASED]

	 Else  (MTP_AMOUNT_TOTAL_O + MTP_AMOUNT_TOTAL_N)/(case when [MWA_DATE_PURCHASED] <'2018-04-01'  then 1.14 else 1.15 end) end  [EARNED_FUNDnetVATbyDATE_PURCHASED]


	into                    #WWFund 

  FROM #WFund

  left join #migaration on [POLICY_KEY] = [NEW_POLICY_KEY] 


  --select * from       #WWFund where POLICY_KEY = 'SAW-2016676-POL'
  --  select * from       #WWFund where POLICY_KEY = 'SAW-2016676-POL'



  -- ***************************************************************************
-- Data fix for policies with that where not migrated but have Evolve Policy Number
--*****************************************************************************



Update						Evolve.dbo.[Policy]
Set							POL_VATNumber = 'SAW-2488763-POL'							
Where						POL_PolicyNumber = 'QWTY013476POL' ; 

Update						Evolve.dbo.[Policy]
Set							POL_VATNumber = 'SAW-1984182-POL'							
Where						POL_PolicyNumber = 'HWTY097897POL' ; 

Update						Evolve.dbo.[Policy]
Set							POL_VATNumber = ''							
Where						POL_PolicyNumber = 'QWTYM014213POL' ; 

Update						Evolve.dbo.[Policy]
Set							POL_VATNumber = 'SAW-2138231-POL'	,
                            POL_EndDate = '2019-07-31 00:00:00.000'
Where						POL_PolicyNumber = 'QWTY129477POL' ; 


--select POL_EndDate from Evolve.dbo.[Policy]



 


 --select * from #WWFund  where [POLICY_KEY] = 'SAW-2128451-POL'



--WW Mot pols

Select                  * 
into                    #Amh 
From                    sawme5.[dbo].[mwupppolicy] 
Where	                UPL_GROUPNAME = 'AMH -- 3275 --'
                    and UPL_POLICY_CDE  
				 


				 not in (select POL_VATNumber 
					    FROM   [Evolve].[dbo].[Policy] )






---historical Fund


SELECT *

into #Fund

FROM (
    SELECT 
      *,
        ROW_NUMBER() OVER (PARTITION BY POL_PolicyNumber ORDER BY ValuationMonth DESC) AS row_num
    FROM [SAWME5].[dbo].FundHistory
) subquery



WHERE row_num = 1;


----  fund for monthly policies
With pol as									(
Select									ats.ATS_TransactionNumber,
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
											ats.ATS_EffectiveDate,
											DATEADD(month, DATEDIFF(month, 0, IIF(ATS_EffectiveDate > ATS_CreateDate, ATS_EffectiveDate, ATS_CreateDate)), 0) AccountingMonth
From										UPP.dbo.Profiling_Wty_Policy p 
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
Where				                        1 = 1
											and APT.APT_Description = 'Insurer'
											and p.PaymentFrequency = 'Monthly'
											and p.RTF_TermPeriod = 1
											and DBS_SetName is not null
											--and p.POL_PolicyNumber = 'QWTY003489POL'
											--and p.POL_PolicyNumber not IN (Select k.POL_PolicyNumber from UPP.dbo.Profiling_Wty_EarnedFund k)
											),
dmt as										( --Disbursements
Select										pol.POL_PolicyNumber,
											pol.AccountingMonth,
											Sum(Case when GLC_GlCode = '100000' then ATN_NettAmount else 0 end) PremiumExclVaT,
											Sum(Case when GLC_GlCode = '100700' then ATN_NettAmount else 0 end) CommissionExclVaT,
											Sum(Case when GLC_GlCode = '303304' then ATN_NettAmount else 0 end) RoadsideExclVaT,
											Sum(Case when GLC_GlCode IN ('306301', '306302', '306307', '306308', '306309') then ATN_NettAmount else 0 end) BinderExclVaT,
											Sum(Case when GLC_GlCode = '306303' then ATN_NettAmount else 0 end) OutsourceExclVaT,
											Sum(Case when GLC_GlCode = '306304' then ATN_NettAmount else 0 end) UnderwritingExclVaT,
											Sum(Case when GLC_GlCode = '306305' then ATN_NettAmount else 0 end) CellFeeDiffExclVaT,
											Sum(Case when GLC_GlCode = '303302' then ATN_NettAmount else 0 end) PlatformExclVaT,
											Sum(Case when GLC_GlCode = '303307' then ATN_NettAmount else 0 end) BdrxExclVaT,
											Sum(Case when GLC_GlCode = '303300' then ATN_NettAmount else 0 end) BrokerExclVaT,
											Sum(Case when GLC_GlCode = '303308' then ATN_NettAmount else 0 end) BankExclVaT,
											Sum(Case when GLC_GlCode = '303033' then ATN_NettAmount else 0 end) InspectionExclVaT
From										pol
Group by									pol.POL_PolicyNumber,
											pol.AccountingMonth)

Select										Pol_PolicyNumber,
											AccountingMonth,
											-(PremiumExclVat + CommissionExclVaT + RoadsideExclVaT + BinderExclVaT + OutsourceExclVaT
											+ UnderwritingExclVaT + CellFeeDiffExclVaT + PlatformExclVaT + BdrxExclVaT + BrokerExclVaT
											+ BankExclVaT + InspectionExclVaT) EarnedFund

											into #monthlyFund

from										dmt


--
Where										1=1

-- Agg fund for monthly policies

select POL_PolicyNumber, sum(EarnedFund) EarnedFund  

INTO #AggMonthlyFund

from #monthlyFund group by POL_PolicyNumber


--select * from  #AggMonthlyFund where POL_PolicyNumber = 'QWTY003489POL'



-- Get Policy Information
Select										--*
											p.POL_PolicyNumber EvolvePolicyNumber,
											p.POL_VATNumber WWPolicyNumber,

											p.POL_OriginalStartDate,
											p.POL_EndDate,
											p.POL_Status,
											RTF_Description,
											case when RTF_Description = 'Monthly' then  POL_PolicyTerm else rtf.RTF_TermPeriod end RTF_TermPeriod,
											datediff(month,case when pv1.PRV_FullName='Warranty Booster' then PMI_RegistrationDate else p.POL_OriginalStartDate end,CASE 
																								WHEN POL_IsMigrated = 1 
																								THEN CASE 
																										 WHEN EVL_DateTime < p.POL_EndDate 
																										 THEN EVL_DateTime 
																										 ELSE p.POL_EndDate 
																									 END 
																								ELSE p.POL_EndDate 
																							END) months,
											case when p.POL_Status = 1 then 'Active' 
											     when (case when RTF_Description = 'Monthly' then  POL_PolicyTerm else rtf.RTF_TermPeriod end) <= datediff(month,case when pv1.PRV_FullName='Warranty Booster' then PMI_RegistrationDate else p.POL_OriginalStartDate end
												                                     ,CASE 
																								WHEN POL_IsMigrated = 1 
																								THEN CASE 
																										 WHEN EVL_DateTime < p.POL_EndDate 
																										 THEN EVL_DateTime 
																										 ELSE p.POL_EndDate 
																									 END 
																								ELSE p.POL_EndDate 
																							END) + 1 then 'Terminated'
																																			 else 'Cancelled' end Status,

											pv1.PRV_FullName ProductLevel1,
											pv2.PRV_FullName ProductLevel2,
											rcc.RCC_GLCode,
											--i.INS_InsurerName,
											Upper(t.PMI_Make) Make,

											
											f.WW_Nett_Fund,
											[Evolve_Nett_Fund],
										     (case when [EARNED_FUNDnetVATbyDATE_PURCHASED] is not null then [EARNED_FUNDnetVATbyDATE_PURCHASED] 
											 
											 when f.WW_Nett_Fund is not null then f.WW_Nett_Fund 
											 when [Evolve_Nett_Fund] is not null then [Evolve_Nett_Fund]
											 else  0 end) + isnull(EarnedFund,0)
											 Fund
                                           
into										#Pol
From										Evolve.dbo.Policy p
											left join Evolve.dbo.ProductVariant pv1
											on pv1.ProductVariant_Id = p.POL_ProductVariantLevel1_ID
											left join Evolve.dbo.ProductVariant pv2
											on pv2.ProductVariant_Id = p.POL_ProductVariantLevel2_ID
											left join Evolve.dbo.ProductVariant pv3
											on pv3.ProductVariant_Id = p.POL_ProductVariantLevel3_ID
											left join Evolve.dbo.Arrangement arg
											on arg.Arrangement_Id = p.POL_Arrangement_ID
											left join Evolve.dbo.ReferenceCellCaptive rcc
											on rcc.ReferenceCellCaptive_Code = arg.ARG_CellCaptive
											left join Evolve.dbo.PolicyInsurerLink pil
											on pil.PIL_Policy_ID = p.Policy_ID
											LEFT join Evolve.dbo.Insurer i
											on i.Insurer_Id = pil.PIL_Insurer_ID
											LEFT join Evolve.dbo.ReferenceTermFrequency rtf
											on rtf.TermFrequency_Id = p.POL_ProductTerm_ID

											LEFT join Evolve.dbo.PolicyMechanicalBreakdownItem t
											

											on t.PMI_Policy_ID = p.Policy_ID

											left join Evolve.dbo.Agent a
											on p.POL_Agent_ID = a.Agent_Id	
											LEFT join Evolve.dbo.Agent pa
											on pa.Agent_Id = p.POL_PrimaryAgent_ID

											left join #WWFund w on w.[POLICY_KEY] = p.POL_VATNumber

											LEFT join #fund f 
											on p.POL_PolicyNumber = f.[POL_PolicyNumber]

											LEFT join #AggMonthlyFund g 
											on p.POL_PolicyNumber = g.[POL_PolicyNumber]

											LEFT JOIN (
															SELECT EVL_ReferenceNumber, MAX(EVL_DateTime) AS Max_EV_Date
															FROM Evolve.dbo.EventLog
															WHERE EVL_Event_ID = 10516
															GROUP BY EVL_ReferenceNumber
														) AS MaxEvents ON MaxEvents.EVL_ReferenceNumber = Policy_ID

											LEFT JOIN Evolve.dbo.EventLog AS EL 
												ON EL.EVL_ReferenceNumber = Policy_ID 
												AND EL.EVL_DateTime = MaxEvents.Max_EV_Date 
												AND EL.EVL_Event_ID = 10516

								---			left join Evolve.dbo.EventLog on EVL_ReferenceNumber = Policy_ID AND EVL_Event_ID = 10516



Where										1 = 1
                                            and p.POL_Deleted = 0
											and pv1.PRV_Deleted = 0
											and rcc.RCC_Deleted = 0
											and arg.ARG_Deleted = 0
											and pil.PIL_Deleted = 0
											and p.POL_Status in (1, 3) --Active and cancelled
											and p.POL_Product_ID = '219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF' -- Warranties
											--and t.RowN = 1
										    and i.Insurer_Id in (
											'44109559-5BBA-473E-831E-E0D285884B6D', -- Centriq
											'4D5B12F8-7BE8-4979-8DB0-11559E577A16'-- hollard
											)
											and t.PMI_Make = 'Renault'
											and RCC_GLCode = 'MOT'
											and p.POL_SoldDate >='2010-01-01'

										--and p.POL_PolicyNumber in ('QWTY013476POL')


--**************************************************************
--Claims information
--**************************************************************
;With										cpmt as (-- Claims Paid
Select										cit.CIT_ClaimItem_ID,
											sum(CIT_Amount) ClaimsPaidInclVaT,
											sum(CIT_AmountVAT) VAT,
											sum(CIT_Amount) - sum(CIT_AmountVAT) ClaimsPaidExclVaT
From										Evolve.dbo.ClaimItemTransaction cit
Where										1 = 1
											and cit.CIT_Deleted = 0
											and cit.CIT_TransactionType_ID = 2
Group by									cit.CIT_ClaimItem_ID
											),
ocr as										(-- Outstanding Claims Reserve
Select										cit.CIT_ClaimItem_ID,
											sum(CIT_Amount) OCRInclVaT,
											sum(CIT_AmountVAT) VAT,
											sum(CIT_Amount) - sum(CIT_AmountVAT) OCRExclVaT
From										Evolve.dbo.ClaimItemTransaction cit
Where										1 = 1
											and cit.CIT_Deleted = 0
Group by									cit.CIT_ClaimItem_ID
											),
d as										( -- Discounts on claims
Select										cit.CIT_ClaimItem_ID,
											sum(CIT_Discount) DiscountInclVaT,
											sum(CIT_Discount - CIT_Discount/1.15) DiscountVAT,
											sum(CIT_Discount/1.15) DiscountExclVaT
From										Evolve.dbo.ClaimItemTransaction cit
Where										1 = 1
											and cit.CIT_Deleted = 0
											and cit.CIT_TransactionType_ID = 2
Group by									cit.CIT_ClaimItem_ID),
c as										(
Select										cpmt.CIT_ClaimItem_ID
From										cpmt
Union
Select										ocr.CIT_ClaimItem_ID
From										ocr
Union
Select										d.CIT_ClaimItem_ID
From										d
											),
cinc as										(
Select										c.*,
											isnull(-cpmt.ClaimsPaidInclVaT, 0) ClaimsPaidInclVaT,
											isnull(-cpmt.VAT, 0) VAT,
											isnull(-cpmt.ClaimsPaidExclVaT, 0) ClaimsPaidExclVaT,
											isnull(ocr.OCRInclVaT, 0) OCRInclVaT,
											Case when isnull(ocr.OCRInclVaT, 0) = 0 then 0
											Else isnull(ocr.VAT, 0) End OCRVaT,
											Case when isnull(ocr.OCRInclVaT, 0) = 0 then 0
											Else isnull(ocr.OCRExclVaT, 0) End OCRExclVaT,
											isnull(d.DiscountInclVaT, 0) DiscountInclVaT,
											isnull(d.DiscountVAT, 0) DiscountVAT,
											isnull(d.DiscountExclVaT, 0) DiscountExclVaT
From										c
											left join cpmt
											on c.CIT_ClaimItem_ID = cpmt.CIT_ClaimItem_ID
											left join ocr
											on c.CIT_ClaimItem_ID = ocr.CIT_ClaimItem_ID
											left join d
											on c.CIT_ClaimItem_ID = d.CIT_ClaimItem_ID
											)
Select										distinct cinc.*,
											isnull(cinc.OCRExclVaT, 0) + isnull(cinc.ClaimsPaidExclVaT, 0) - isnull(cinc.DiscountExclVaT, 0) ClaimsIncurredExclVaT,
											cis.CIS_PolicyNumber,
											Case 
												When p.EvolvePolicyNumber not like '%POL' then 
													SUBSTRING(p.EvolvePolicyNumber, 1, len(p.EvolvePolicyNumber) - 3) 
												Else 
													p.EvolvePolicyNumber 
											End OriginalPolicyNumber,
											cis.CIS_ClaimNumber,
											cis.CIS_CreateDate,
											DATEADD(month, DATEDIFF(month, 0, cis.CIS_CreateDate), 0) LossMonth,
											(DATEDIFF(day, (Select o.POL_OriginalStartDate from Evolve.dbo.Policy o where o.POL_PolicyNumber = 
											Case 
												When p.EvolvePolicyNumber not like '%POL' then 
													SUBSTRING(p.EvolvePolicyNumber, 1, len(p.EvolvePolicyNumber) - 3) 
												Else 
													p.EvolvePolicyNumber 
											End
											), cis.CIS_CreateDate) / (365.25 / 12)) ClaimMonth,
											(Select o.POL_OriginalStartDate from Evolve.dbo.Policy o where o.POL_PolicyNumber = 
											Case 
												When p.EvolvePolicyNumber not like '%POL' then 
													SUBSTRING(p.EvolvePolicyNumber, 1, len(p.EvolvePolicyNumber) - 3) 
												Else 
													p.EvolvePolicyNumber 
											End
											) OriginalStartDate,
											p.POL_Status,
											p.EvolvePolicyNumber
											--p.Policy_ID
Into										#ClaimsInfo
From										cinc
											inner join Evolve.dbo.ClaimItemSummary cis
											on cinc.CIT_ClaimItem_ID = cis.CIS_ClaimItem_ID
											inner join #pol p
											on cis.CIS_PolicyNumber = p.EvolvePolicyNumber 
Where										1 = 1
											and ClaimsPaidInclVaT + OCRInclVaT <> 0;

-- Update claim month for renewed policies
Update										#ClaimsInfo
Set											ClaimMonth = DATEDIFF(day, OriginalStartDate, CIS_CreateDate) / (365.25 / 12);



-- WW claims

select 	                                  POLICY_KEY CIS_PolicyNumber,	sum((case when FAILURE_DATE< '2018-04-01' then PAID/1.14  else  PAID/1.15  end))  ClaimsPaidExclVaT 
into                                      #WWClaims
from                                      [SAWME5].[dbo].fmsclaims 
where                                     CLAIM_KEY 
                                   not in (select CIS_ClaimNumber 
								           from   #ClaimsInfo)
group by                                   POLICY_KEY ;






with res as(

Select    case when WWPolicyNumber <>'' then 1 else 0 end Migration
          ,p.*
		  , [EarnedFund]
          , isnull(t.ClaimsPaidExclVaT,0) EvolveClaimsPaidExclVaT  
          , isnull(y.ClaimsPaidExclVaT,0) + isnull(z.ClaimsPaidExclVaT,0)  WWClaimsPaidExclVaT
		  



from #pol p

left join #EarnedFund on POL_PolicyNumber = p.EvolvePolicyNumber

left join #migaration aa on [NEW_POLICY_KEY] = WWPolicyNumber


left join ( select CIS_PolicyNumber, sum(ClaimsPaidExclVaT) ClaimsPaidExclVaT from  #ClaimsInfo  group by CIS_PolicyNumber ) as t
             on t.CIS_PolicyNumber = p.EvolvePolicyNumber 
left join (select 	POLICY_KEY CIS_PolicyNumber,	sum((case when FAILURE_DATE< '2018-04-01' then Paid/1.14  else  Paid/1.15  end))  ClaimsPaidExclVaT 
             from  [SAWME5].[dbo].fmsclaims where  CLAIM_KEY not in (select CIS_ClaimNumber from  #ClaimsInfo) group by POLICY_KEY )  as y
          
		     on y.CIS_PolicyNumber = WWPolicyNumber

left join (select 	POLICY_KEY CIS_PolicyNumber,	sum((case when FAILURE_DATE< '2018-04-01' then Paid/1.14  else  Paid/1.15  end))  ClaimsPaidExclVaT 
             from  [SAWME5].[dbo].fmsclaims where  CLAIM_KEY not in (select CIS_ClaimNumber from  #ClaimsInfo) group by POLICY_KEY )  as z
          
		     on z.CIS_PolicyNumber = [OLD_POL_KEY]


			 where  1=1

			 --and EvolvePolicyNumber =  'QWTY003489POL'

union

--WW policies
Select	--*
        				0 Migration,
                        '' EvolvePolicyNumber,
                        f.	POLICY_KEY	WWPolicyNumber,
						f.	POL_START_DATE	POL_OriginalStartDate,
						mw.MWA_DELETE_DATE 	POL_EndDate,
						f.	POL_STATUS_CDE	POL_Status,
						case when f.	MPR_PERIOD =1 then 'Monthly' else 'Term' end RTF_Description,
						f.	MPR_PERIOD	RTF_TermPeriod,
						
						--datediff(month,case when SEC_REP_GROUP='Warranty Booster' then PMI_RegistrationDate else p.POL_OriginalStartDate end,CASE 
						--							WHEN POL_IsMigrated = 1 
						--							THEN CASE 
						--										WHEN EVL_DateTime < p.POL_EndDate 
						--										THEN EVL_DateTime 
						--										ELSE p.POL_EndDate 
						--									END 
						--							ELSE p.POL_EndDate 
						--						END)
												
							datediff(month,	f.	POL_START_DATE,mw.MWA_DELETE_DATE)				months,
						case when f.POL_STATUS_CDE = 1 and  POL_END_DATE<=mw.MWA_DELETE_DATE then 'Terminated' else 'Cancelled' end Status,

				
						f.	SEC_REP_GROUP	ProductLevel1,
						f.	MPR_PRODUCT	ProductLevel2,
	
					    f.	REP_GROUP	RCC_GLCode,

						mw.MWA_MAKE Make, 

						0 WW_Nett_Fund,
                        0 Evolve_Nett_Fund,

						[EARNED_FUNDnetVATbyDATE_PURCHASED] Fund,

						0 [EarnedFund],
						isnull(cc.ClaimsPaidExclVaT,0)  EvolveClaimsPaidExclVaT,
						isnull(c.ClaimsPaidExclVaT,0)  WWClaimsPaidExclVaT


From					SAWME5.dbo.fmspolicy f
						left join sawme5.dbo.motor_warranty mw
						
						on mw.mwa_policy_cde = f.policy_key

						left join #migaration aa

						on [NEW_POLICY_KEY] = f.policy_key

						inner join #Amh amh

						on amh.UPL_POLICY_CDE = f.POLICY_KEY
						left join #WWFund w on  w.[POLICY_KEY] = f.POLICY_KEY

                        left join #WWClaims  as c
          
		            on c.CIS_PolicyNumber = f.POLICY_KEY

					   left join #WWClaims  as cc
          
		            on cc.CIS_PolicyNumber = [OLD_POL_KEY]


Where					BUSCLASS = 'Warranty'
                        and f.MWA_DATE_PURCHASED >= '2010-01-01'
					--	and (case when POL_STATUS_CDE = 1 then END_MONTH else DELETE_MONTH end) < '2023-04-01'


						and mw.MWA_MAKE = 'Renault'

						and f.	POLICY_KEY not in ( select OLD_POL_KEY from #migaration)

				--		and f.	POLICY_KEY  = 'SAW-2016676-POL'



)

select * into #res from res


--select * from 						#Pol where EvolvePolicyNumber = 'QWTYM236981POL';
--select * from 	                    #ClaimsInfo where CIS_PolicyNumber = 'QWTYM236981POL';
--select * from 	                    #WFund where POLICY_KEY = 'SAW-3189762-POL';
--select * from 	                    #WWFund where POLICY_KEY = 'SAW-3189762-POL';



--select * from 	                    #Fund where WW_Policy_Key = 'SAW-3189762-POL';
--select * from 	                    #migaration where OLD_POL_KEY = 'SAW-3189762-POL' ;

--select * from 	                    #Fund where Pol_PolicyNumber = 'QWTYM276716POL';

--select * from #monthlyFund where Pol_PolicyNumber = 'QWTYM236981POL' order by AccountingMonth
--select * from 	                     [SAWME5].[dbo].[fend_aa1_earned_fund_report] where POLICY_KEY = 'SAW-2016676-POL' order by DURA_TION;
--select * from 	                    #Amh;
--select * from 	                    #WWClaims;
--select * from 	                    #EarnedFund;
--select * from #res where EvolvePolicyNumber = 'QWTYM276716POL'

--select * from [SAWME5].[dbo].[MWTEMPACCUPPVIEW] where MTA_REF_TRAN = 'SAW-2016676-POL'

--select * from fmsclaims where OUTSTANDING <> 0

--select * from FMSPOLICY where POLICY_KEY = 'SAW-2016676-POL'


DECLARE @Values TABLE (A NVARCHAR(20));

INSERT INTO @Values (A)
VALUES   ('-');
    --   ,('SAW-2081229-POL')
    --   ,('SAW-1877944-POL')
	   --,('QWTY074694POL')
	   --,('SAW-3017901-POL')
	   --;


select * from #res where 1=1



--and volvePolicyNumber = 'QWTY013476POL'
-- and WWPolicyNumber in (select * from @Values)
--select A from @Values

--select * from #res where ( EvolvePolicyNumber in(select * from @Values) or WWPolicyNumber in(select * from @Values))

-- select * from #migaration where NEW_POLICY_KEY in(select * from @Values)

-- select * from FMSPOLICY where POLICY_KEY  in (select * from @Values) 

--  select * from MWPOLICY where POLICY_KEY  in (select * from @Values) 

--   select * from  [SAWME5].[dbo].[motor_warranty] where MWA_POLICY_CDE in (select * from @Values) 

--  select * from aa_mwpolicy where POLICY_KEY  in (select * from @Values) 


-- select * from [SAWME5].[dbo].[MWTEMPACCUPPVIEW] where MTA_REF_TRAN in (select * from @Values) and  MTP_DISBURSEMENTTYPE_CDE =171

--select * from mwtempacc where MTA_REF_TRAN in (select * from @Values) 

--select *  FROM [SAWME5].[dbo].[mwproductref]  where MWPRODUCTREF_KEY in (select MWPRODUCTREF_KEY from  FMSPOLICY where POLICY_KEY  in (select * from @Values) )

 


--select * from 	                    #WWClaims




--select * from #Pol where EvolvePolicyNumber =  'QWTY013476POL'


--select * from mwtempacc where MTA_REF_TRAN = 'SAW-2016676-POL'













