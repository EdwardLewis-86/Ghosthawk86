drop table #pegasus					
					
select *, row_number() over (partition by ratinggroup,	premiumfrequency,	product,	PlanName,		term order by effectivedate desc) as seq
into #pegasus					
from [LC-PEGASUS].[MSureEvolve].[dbo].[saw_warranties]					
					
					
					
					
select PRV_Code,	PRV_Name,	PRP_PlanName,	RTF_TermPeriod,	Premium,	Commission, 
sum(case when DVT_Description = 'Inspection' then VSV_Value else 0 end) as Inspection_Fees,					
 sum(case when DVT_Description = 'Liquid Assist Road Side Assistance' then VSV_Value else 0 end) as Liquid_Roadside_Fees,					
  sum(case when DVT_Description = 'M-Sure Road Side Assistance' then VSV_Value else 0 end) as Msure_Roadside_Fees,					
  sum(case when DVT_Description not in ('Inspection', 'Liquid Assist Road Side Assistance' ,'M-Sure Road Side Assistance') then VSV_Value else 0 end) as Other_Fees 					
  from (					
select prv.PRV_Code, prv.PRV_Name, prp.PRP_PlanName ,   rtf.RTF_TermPeriod , cast(peg.premium_exclVAT*1.15 as decimal(10,2)) as Premium ,					
cast(cast(peg.premium_exclVAT*1.15 as decimal(10,2))*0.125 as decimal(10,2)) as Commission,					
 dvt.DVT_Description, vst.VST_Description, vsv.VSV_Value					
--select peg.*					
from #pegasus as peg					
inner join evolve.dbo.productvariant as prv on peg.product = prv.PRV_Code  --2852					
inner join  evolve.dbo.ProductPlans as prp on prp.PRP_PlanName = peg.PlanName  and PRP_Deleted = 0					
inner join evolve.dbo.ReferenceTermFrequency as rtf on rtf.RTF_TermPeriod = peg.term 					
left join evolve.[dbo].[DisbursementValueSetHeader] as vsh on VSH_ProductVariant_Id = prv.ProductVariant_Id and VSH_Deleted = 0					
left join evolve.[dbo].ReferenceRatingGroups as rrg on vsh.VSH_RatingGroup_ID = rrg.RatingGroup_ID and rrg.RGP_Description = peg.ratinggroup and rrg.RGP_Deleted = 0					
 left join evolve.[dbo].[DisbursementValueSetDetail] as vsd on vsd.VSD_DisbursementValueSetHeader_Id = vsh.DisbursementValueSetHeader_Id and vsd.VSD_ProductPlans_Id = prp.ProductPlans_Id and vsd.VSD_TermFrequency_Id = rtf.TermFrequency_Id and vsd.VSD_Deleted = 0					
 left join evolve.[dbo].[DisbursementValueSetValue] as vsv on vsd.DisbursementValueSetDetail_Id = vsv.VSV_DisbursementValueSetDetailId and vsv.VSV_Deleted = 0					
 left join [Evolve].[dbo].[ReferenceDisbursementValueType] as dvt on vsv.VSV_DisbursementRuleName_Id = dvt.DisbursementValueType_Id and DVT_Deleted = 0					
 left join [Evolve].[dbo].[ReferenceDisbursementValueSetType] as vst on vst.DisbursementValueSetType_Id = vsv.VSV_ValueType					
---- where premiumfrequency = 'Monthly'					
where seq =1					
--and peg.product  = 'H-WMCY-V8.1'					
) as X					
group by PRV_Code,	PRV_Name,	PRP_PlanName,	RTF_TermPeriod,	Premium,	Commission
					
					
					
order by 1,2,3,4					
					
 select *					
 from evolve.[dbo].[DisbursementValueSetHeader]					
					
 select *					
 from evolve.dbo.ReferenceTermFrequency 					
