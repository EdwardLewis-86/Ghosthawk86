select vl0.PRD_Name as Product_Name, RTF.RTF_TermPeriod as TermPeriod, prgl0.PTL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PTL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PTL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name ,  prgl3.PTL_Deleted  as V3_Deleted 

--select *
from [Evolve].[dbo].[Product] as VL0 left outer join [Evolve].[dbo].[ProductTermLink] as prgl0 on vl0.Product_Id = prgl0.PTL_ProductId left outer join  [Evolve].[dbo].[ReferenceTermFrequency] as RTF on prgl0.PTL_TermID = RTF.TermFrequency_Id
inner join [Evolve].[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join [Evolve].[dbo].[ProductTermLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PTL_ProductId  and  prgl1.PTL_TermID  = prgl0.PTL_TermID 
inner join [Evolve].[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join [Evolve].[dbo].[ProductTermLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PTL_ProductId    and  prgl2.PTL_TermID  = prgl0.PTL_TermID 
inner join [Evolve].[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join [Evolve].[dbo].[ProductTermLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PTL_ProductId    and  prgl3.PTL_TermID  = prgl0.PTL_TermID 
--where vl3.PRV_Name = 'Centriq - Mastercars V11.1.24CEN_V1 -VL3'
where isnull(prgl1.PTL_Deleted,0) = 0
and isnull(prgl2.PTL_Deleted,0) = 0
and isnull(prgl3.PTL_Deleted,0) = 0
  --order by PIL_ProductID,	PIL_InsurerID
 and  vl3.PRV_Name like '%B2B Options V3.02%'
  order by 1,2

------------- Payment Method

select vl0.PRD_Name as Product_Name, [RPM_Description] as Payment_Method, prgl0.PML_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PML_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PML_Deleted  as V2_Deleted , 
vl3.PRV_Code as LVL3_Code,   vl3.PRV_Name  as Lvl3_name ,  prgl3.PML_Deleted  as V3_Deleted 

--select *
from [Evolve].[dbo].[Product] as VL0 left outer join [Evolve].[dbo].[ProductPaymentMethodLink] as prgl0 on vl0.Product_Id = prgl0.PML_Product_ID LEFT OUTER JOIN [Evolve].[dbo].[ReferencePaymentMethod] AS RPM ON RPM.ReferencePaymentMethod_ID = prgl0.PML_PaymentMethod_ID
inner join [Evolve].[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join [Evolve].[dbo].[ProductPaymentMethodLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PML_Product_ID  and  prgl1.PML_PaymentMethod_ID  = prgl0.PML_PaymentMethod_ID 
inner join [Evolve].[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join [Evolve].[dbo].[ProductPaymentMethodLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PML_Product_ID    and  prgl2.PML_PaymentMethod_ID  = prgl0.PML_PaymentMethod_ID 
inner join [Evolve].[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join [Evolve].[dbo].[ProductPaymentMethodLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PML_Product_ID    and  prgl3.PML_PaymentMethod_ID  = prgl0.PML_PaymentMethod_ID 
--where vl3.PRV_Name = 'Centriq - Mastercars V11.1.24CEN_V1 -VL3'
where isnull(prgl1.PML_Deleted,0) = 0
and isnull(prgl2.PML_Deleted,0) = 0
and isnull(prgl3.PML_Deleted,0) = 0
  --order by PIL_ProductID,	PIL_InsurerID

  order by 1,2



------------

select vl0.PRD_Name as Product_Name, prgl0.PRP_PlanName , prgl0.PRP_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PRP_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PRP_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name ,  prgl3.PRP_Deleted  as V3_Deleted 

--select *
from [Evolve].[dbo].[Product] as VL0 INNER JOIN   EVOLVE.[dbo].[ProductPlans] as prgl0 on prgl0.PRP_Product_Id  = VL0.Product_Id 
inner join [Evolve].[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductPlans] as prgl1 on vl1.ProductVariant_Id = prgl1.PRP_Product_Id  and  prgl1.PRP_PlanName  = prgl0.PRP_PlanName 
inner join [Evolve].[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join [Evolve].[dbo].[ProductPlans] as prgl2 on vl2.ProductVariant_Id = prgl2.PRP_Product_Id    and  prgl2.PRP_PlanName  = prgl0.PRP_PlanName 
inner join [Evolve].[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join [Evolve].[dbo].[ProductPlans] as prgl3 on vl3.ProductVariant_Id = prgl3.PRP_Product_Id    and  prgl3.PRP_PlanName  = prgl0.PRP_PlanName 
--where vl3.PRV_Name = 'Centriq - Mastercars V11.1.24CEN_V1 -VL3'
where isnull(prgl0.PRP_Deleted,0) = 0
and isnull(prgl1.PRP_Deleted,0) = 0
and isnull(prgl2.PRP_Deleted,0) = 0
and isnull(prgl3.PRP_Deleted,0) = 0
--and vl0.PRD_Name = 'Scratch and Dent'
--and vl3.PRV_Code = 'Q-B2BIMP-V5.1'
and vl3.PRV_Name in ('SmartWarranty™','VALUE4U')

  order by 1,4,2

------------------


select vl0.PRD_Name as Product_Name, dbg.DBG_Description , prgl0.PDL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PDL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PDL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name ,  prgl3.PDL_Deleted  as V3_Deleted 

--select *
from [Evolve].[dbo].[Product] as VL0 INNER JOIN   EVOLVE.[dbo].[ProductDisbursementLink] as prgl0 on prgl0.PDL_Product_Id  = VL0.Product_Id 
left outer join [Evolve].[dbo].[DisbursementGroups] as dbg on prgl0.PDL_DisbursementGroup_Id = dbg.DisbursementGroup_Id
inner join [Evolve].[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductDisbursementLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PDL_Product_Id  and  prgl1.[PDL_DisbursementGroup_Id]  = prgl0.[PDL_DisbursementGroup_Id] 
inner join [Evolve].[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join [Evolve].[dbo].[ProductDisbursementLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PDL_Product_Id    and  prgl2.[PDL_DisbursementGroup_Id]  = prgl0.[PDL_DisbursementGroup_Id] 
inner join [Evolve].[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join [Evolve].[dbo].[ProductDisbursementLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PDL_Product_Id    and  prgl3.[PDL_DisbursementGroup_Id]  = prgl0.[PDL_DisbursementGroup_Id] 
--where vl3.PRV_Name = 'Centriq - Mastercars V11.1.24CEN_V1 -VL3'
where isnull(prgl0.PDL_Deleted,0) = 0
and isnull(prgl1.PDL_Deleted,0) = 0
and isnull(prgl2.PDL_Deleted,0) = 0
and isnull(prgl3.PDL_Deleted,0) = 0
--and vl0.PRD_Name = 'Scratch and Dent'
and vl3.PRV_Code =  'Q-WSUP-V8.0'

  order by 1,2

------------------
  select *
  from (

  select INS_InsurerName,  vl0.PRD_Name as Product_Name, PRP0.APS_UpdateUser_ID,
  RGP_Description ,
  DBG_Description, 
  BRA.DBR_Name ,
  --prgl0.PSCL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,vl1.PRV_Code as Lvl_1_code, vl1.ProductVariant_Id as VL1_Variant_id , --prgl1.PSCL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name , vl2.PRV_Code as Lvl_2_code,vl2.ProductVariant_Id as VL2_Variant_id ,   -- prgl2.PSCL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name , vl3.PRV_Code as Lvl_3_code, vl3.ProductVariant_Id as VL3_Variant_id ,-- prgl3.PSCL_Deleted  as V3_Deleted , 

isnull(PRP0.APS_Deleted,0) as Product_DEL_Stat,
isnull(prgl1.APS_Deleted,0) as Variant_1_DEL_Stat,
isnull(prgl2.APS_Deleted,0) as Variant_2_DEL_Stat,
isnull(prgl3.APS_Deleted,0) as Variant_3_DEL_Stat 
--select PRP0.*
from EVOLVE.[dbo].[Product] as VL0 
INNER JOIN EVOLVE.[dbo].ArrangementProductStructure as PRP0 ON VL0.Product_Id = PRP0.APS_Product_ID
inner join EVOLVE.[dbo].[ReferenceRatingGroups] as prgl0 on PRP0.APS_RatingGroup_ID = prgl0.RatingGroup_ID  
INNER JOIN EVOLVE.[dbo].DisbursementGroups as DBG on PRP0.APS_DisbursementGroup_ID  = dBg.DisbursementGroup_Id 
INNER JOIN   Evolve.[dbo].[Branding] as BRA on    PRP0.APS_Branding_ID  = BRA.Branding_ID ---PROBLEM
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].ArrangementProductStructure as prgl1 on vl1.ProductVariant_Id = prgl1.APS_Product_ID  and  prgl1.APS_RatingGroup_ID  = prgl0.RatingGroup_ID and prgl1.APS_DisbursementGroup_ID = PRP0.APS_DisbursementGroup_ID and prgl1.APS_Branding_ID = PRP0.APS_Branding_ID
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer  join EVOLVE.[dbo].ArrangementProductStructure as prgl2 on vl2.ProductVariant_Id = prgl2.APS_Product_ID    and  prgl2.APS_RatingGroup_ID  = prgl0.RatingGroup_ID  and prgl2.APS_DisbursementGroup_ID = PRP0.APS_DisbursementGroup_ID and prgl2.APS_Branding_ID = PRP0.APS_Branding_ID
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].ArrangementProductStructure as prgl3 on vl3.ProductVariant_Id = prgl3.APS_Product_ID    and  prgl3.APS_RatingGroup_ID  = prgl0.RatingGroup_ID  and prgl3.APS_DisbursementGroup_ID = PRP0.APS_DisbursementGroup_ID and prgl3.APS_Branding_ID = PRP0.APS_Branding_ID
left outer join #Insurer as I on vl3.ProductVariant_Id = I.ProductVariant_Id
where 1=1
and vl0.PRD_Deleted = 0
-- and vl3.PRV_Code = 'Q-WSUP-V8.0'
) as X
where 1=1
and isnull(Variant_1_DEL_Stat,0) = 0	
and isnull(Variant_2_DEL_Stat	,0) = 0	
and isnull(Variant_3_DEL_Stat,0) = 0	
---- and Lvl3_name like '%term%v5.0%'
 and Lvl_3_code = 'Q-APUC-V1.1'




select vl0.PRD_Name as Product_Name, RTF.RTF_TermPeriod as TermPeriod, prgl0.PTL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PTL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PTL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name ,  prgl3.PTL_Deleted  as V3_Deleted 

--select *
from EVOLVE.[dbo].[Product] as VL0 inner join EVOLVE.[dbo].[ProductTermLink] as prgl0 on vl0.Product_Id = prgl0.PTL_ProductId left outer join  [Evolve].[dbo].[ReferenceTermFrequency] as RTF on prgl0.PTL_TermID = RTF.TermFrequency_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductTermLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PTL_ProductId  and  prgl1.PTL_TermID  = prgl0.PTL_TermID 
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join EVOLVE.[dbo].[ProductTermLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PTL_ProductId    and  prgl2.PTL_TermID  = prgl0.PTL_TermID 
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].[ProductTermLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PTL_ProductId    and  prgl3.PTL_TermID  = prgl0.PTL_TermID 
--where vl3.PRV_Name = 'Centriq - Booster V1.3 Hyundai -VL3'
where isnull(prgl0.PTL_Deleted,0) = 0
and isnull(prgl1.PTL_Deleted,0) = 0
and isnull(prgl2.PTL_Deleted,0) = 0
and isnull(prgl3.PTL_Deleted,0) = 0
--and vl0.PRD_Name = 'Scratch and Dent'
and vl3.PRV_Code = 'Q-B2BIMP-V5.1'
  --order by PIL_ProductID,	PIL_InsurerID

  order by 1,2


  ------------- Product Excesses -----

  
  select distinct *
  from (
  select vl0.PRD_Name as Product_Name, 
  PRP0.PRP_PlanName ,
  prgl0.PEX_Description,   --prgl0.PSCL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,vl1.PRV_Code as Lvl_1_code, vl1.ProductVariant_Id as VL1_Variant_id , --prgl1.PSCL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name , vl2.PRV_Code as Lvl_2_code,  -- prgl2.PSCL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name , vl3.PRV_Code as Lvl_3_code, -- prgl3.PSCL_Deleted  as V3_Deleted , 
       [PEL_Description]
      ,[PEL_MinimumAmount]
      ,[PEL_ClaimPercentage]
      ,[PEL_SumPercentage]
      ,[PEL_MaximumAmount]
      ,[PEL_Default]
  , ISNULL(PRP.PRP_Deleted,0) AS Plan_Variant_1_del_stat
  , ISNULL(PRP2.PRP_Deleted,0) AS Plan_Variant_2_del_stat
  , ISNULL(PRP3.PRP_Deleted,0) AS Plan_Variant_3_del_stat
  ,isnull(prgl0.PEX_Deleted,0) as Product_Excess_stat
    ,isnull(prgl1.PEX_Deleted,0) as Product_variant_1_Excess_stat
    ,isnull(prgl2.PEX_Deleted,0) as Product_variant_2_Excess_stat
	    ,isnull(prgl3.PEX_Deleted,0) as Product_variant_3_Excess_stat
--select prP0.*
from EVOLVE.[dbo].[Product] as VL0 
INNER JOIN EVOLVE.[dbo].[ProductPlans] as PRP0 ON VL0.Product_Id = PRP0.PRP_Product_Id
inner join EVOLVE.[dbo].[ProductExcess] as prgl0 on vl0.Product_Id = prgl0.PEX_Product_Id  left outer join  [Evolve].[dbo].[ProductExcessLink] as RTF on prgl0.ProductExcess_Id = RTF.PEL_ProductExcess_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductExcess] as prgl1 on vl1.ProductVariant_Id = prgl1.PEX_Product_Id  and  prgl1.PEX_Description  = prgl0.PEX_Description and prgl1.PEX_ProductPlans_Id = prgl0.PEX_ProductPlans_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join EVOLVE.[dbo].[ProductExcess] as prgl2 on vl2.ProductVariant_Id = prgl2.PEX_Product_Id    and  prgl2.PEX_Description  = prgl0.PEX_Description  and prgl2.PEX_ProductPlans_Id = prgl1.PEX_ProductPlans_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].[ProductExcess] as prgl3 on vl3.ProductVariant_Id = prgl3.PEX_Product_Id    and  prgl3.PEX_Description  = prgl0.PEX_Description  and prgl3.PEX_ProductPlans_Id = prgl2.PEX_ProductPlans_Id

LEFT OUTER JOIN EVOLVE.[dbo].[ProductPlans] as PRP on  prp.PRP_Product_Id = VL1.ProductVariant_Id and  PRP0.PRP_PlanName = PRP.PRP_PlanName  AND  prgl0.PEX_ProductPlans_Id  = CASE WHEN  prgl0.PEX_ProductPlans_Id ='' THEN '' ELSE   prp.ProductPlans_Id END 

LEFT OUTER JOIN EVOLVE.[dbo].[ProductPlans] as PRP2 on  prp2.PRP_Product_Id = VL2.ProductVariant_Id and  PRP0.PRP_PlanName = PRP2.PRP_PlanName  AND  prgl0.PEX_ProductPlans_Id  = CASE WHEN  prgl0.PEX_ProductPlans_Id ='' THEN '' ELSE   prp2.ProductPlans_Id END 

LEFT OUTER JOIN EVOLVE.[dbo].[ProductPlans] as PRP3 on  prp3.PRP_Product_Id = VL3.ProductVariant_Id and  PRP0.PRP_PlanName = PRP3.PRP_PlanName  AND  prgl0.PEX_ProductPlans_Id  = CASE WHEN  prgl0.PEX_ProductPlans_Id ='' THEN '' ELSE   prp3.ProductPlans_Id END 


where 1=1
and vl0.PRD_Deleted = 0
--AND VL1.PRV_Name = 'Tyre and Rim Protect'
--AND PRP0.PRP_PlanName = '5 Tyres 5 Rims'
--and vl3.PRV_Name like 'Centriq - Booster V1.3%'
--and vl3.PRV_Code = 'Q-B2BIMP-V5.1'

--and isnull(prgl0.PEX_Deleted,0) = 0
--and isnull(prgl1.PEX_Deleted,0) = 0
--and isnull(prgl2.PEX_Deleted,0) = 0
--and isnull(prgl3.PEX_Deleted,0) = 0

  --order by PIL_ProductID,	PIL_InsurerID
--and vl0.PRD_Name = 'Scratch and Dent'
--AND VL3.PRV_Code = 'Q-APPC-V1.01'
) as X
where Product_Excess_stat = 0
--AND Lvl1_name = 'Tyre and Rim Protect'
--and isnull(Product_variant_1_Excess_stat,0) = 0	
--And isnull(Product_variant_2_Excess_stat,0) = 0	
--and isnull(Product_variant_3_Excess_stat,0) = 0	
  order by 1,2

  ------------------------



  select vl0.PRD_Name as Product_Name, 
  PRP_PlanName ,
  RTF.CMP_Description as Component,  --prgl0.PSCL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,vl1.PRV_Code as Lvl_1_code,  --prgl1.PSCL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name , vl2.PRV_Code as Lvl_2_code,  -- prgl2.PSCL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name , vl3.PRV_Code as Lvl_3_code, -- prgl3.PSCL_Deleted  as V3_Deleted , 
prgl2.PSCL_ComponentLimit

--select *
from EVOLVE.[dbo].[Product] as VL0 inner join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl0 on vl0.Product_Id = prgl0.PSCL_Product_Id INNER JOIN EVOLVE.[dbo].[ProductPlans] as PRP on prgl0.PSCL_ProductPlans_Id = prp.ProductPlans_Id left outer join  [Evolve].[dbo].[ReferenceComponent] as RTF on prgl0.PSCL_Component_Id = RTF.Component_ID
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PSCL_Product_Id  and  prgl1.PSCL_Component_Id  = prgl0.PSCL_Component_Id and prgl1.PSCL_ProductPlans_Id = prgl0.PSCL_ProductPlans_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PSCL_Product_Id    and  prgl2.PSCL_Component_Id  = prgl0.PSCL_Component_Id  and prgl2.PSCL_ProductPlans_Id = prgl1.PSCL_ProductPlans_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PSCL_Product_Id    and  prgl3.PSCL_Component_Id  = prgl0.PSCL_Component_Id  and prgl3.PSCL_ProductPlans_Id = prgl2.PSCL_ProductPlans_Id
where 1=1
and vl0.PRD_Deleted = 0
--and vl3.PRV_Name like 'Centriq - Booster V1.3%'
--and vl3.PRV_Code = 'Q-B2BIMP-V5.1'
and isnull(prgl0.PSCL_Deleted,0) = 0
and isnull(prgl1.PSCL_Deleted,0) = 0
and isnull(prgl2.PSCL_Deleted,0) = 0
and isnull(prgl3.PSCL_Deleted,0) = 0
  --order by PIL_ProductID,	PIL_InsurerID
--and vl0.PRD_Name = 'Scratch and Dent'
--AND VL3.PRV_Code = 'Q-APPC-V1.01'
  order by 1,2

  select *
into #claim_Type
from (
select 1 as ClaimTypeid, 'Fixed Amount' as Claim_Type union all
select 2  as ClaimTypeid, '% of Sum Insured' as Claim_Type union all
select 3  as ClaimTypeid, 'Unlimited' as Claim_Type union all
select 4  as ClaimTypeid, '% of Claim' as Claim_Type
) as A

  
  select vl0.PRD_Name as Product_Name, 
  prs.PDS_Description as Section,
  isnull(PRP_PlanName,'All') as Plan_Name ,
  ct.Claim_Type as CLAIM_Type, 
  RLT.LPT_Description as Limit_Type,
  prgl0.PSLL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PSLL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PSLL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name ,  prgl3.PSLL_Deleted  as V3_Deleted , prgl1.[PSLL_ClaimType]
      ,prgl0.[PSLL_ClaimCount]
      ,prgl0.[PSLL_ClaimValue]

--select prgl0.*
from EVOLVE.[dbo].[Product] as VL0 inner join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl0 on vl0.Product_Id = prgl0.PSLL_Product_Id  left outer join #claim_Type as CT on prgl0.PSLL_ClaimType = CT.ClaimTypeid left outer join  [Evolve].[dbo].ReferenceLimitPeriodType as RLT on prgl0.PSLL_PeriodType = RLT.LimitPeriodType_ID left outer join evolve.dbo.ProductPlans as PRP on PRP.ProductPlans_Id = prgl0.PSLL_ProductPlans_Id left outer join Evolve.[dbo].[ProductSection] as PRS on PRS.ProductSection_Id = prgl0.PSLL_Section_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PSLL_Product_Id  and  prgl1.PSLL_ClaimType  = prgl0.PSLL_ClaimType and prgl1.PSLL_ProductPlans_Id = prgl0.PSLL_ProductPlans_Id and prgl1.PSLL_PeriodType = prgl0.PSLL_PeriodType and prgl1.PSLL_Section_Id = prgl0.PSLL_Section_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PSLL_Product_Id    and  prgl2.PSLL_ClaimType  = prgl0.PSLL_ClaimType  and prgl2.PSLL_ProductPlans_Id = prgl1.PSLL_ProductPlans_Id and prgl2.PSLL_PeriodType = prgl1.PSLL_PeriodType and prgl2.PSLL_Section_Id = prgl1.PSLL_Section_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PSLL_Product_Id    and  prgl3.PSLL_ClaimType  = prgl0.PSLL_ClaimType  and prgl3.PSLL_ProductPlans_Id = prgl2.PSLL_ProductPlans_Id and prgl3.PSLL_PeriodType = prgl2.PSLL_PeriodType and prgl3.PSLL_Section_Id = prgl2.PSLL_Section_Id
--where vl3.PRV_Name = 'Centriq - Booster V1.3 Hyundai -VL3'
where isnull(prgl0.PSLL_Deleted,0) = 0
and isnull(prgl1.PSLL_Deleted,0) = 0
and isnull(prgl2.PSLL_Deleted,0) = 0
and isnull(prgl3.PSLL_Deleted,0) = 0
  --order by PIL_ProductID,	PIL_InsurerID
--and vl0.PRD_Name = 'Scratch and Dent'
  order by 1,2

  

  select * from EVOLVE.[dbo].[ProductSectionLimitLink]
  select * from [Evolve].[dbo].[ReferenceClaimType]


  select vl0.PRD_Name as Product_Name, 
  PRP_PlanName ,
  RTF.LOT_Description as Loss_Type, prgl0.PSLL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,  prgl1.PSLL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PSLL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name ,  prgl3.PSLL_Deleted  as V3_Deleted , prgl3.[PSLL_ClaimType]
      ,prgl3.[PSLL_ClaimCount]
      ,prgl3.[PSLL_ClaimValue]

--select *
from EVOLVE.[dbo].[Product] as VL0 inner join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl0 on vl0.Product_Id = prgl0.PSLL_Product_Id INNER JOIN EVOLVE.[dbo].[ProductPlans] as PRP on prgl0.PSLL_ProductPlans_Id = prp.ProductPlans_Id left outer join  [Evolve].[dbo].[ReferenceLossType] as RTF on prgl0.PSLL_LossType_Id = RTF.LossType_ID
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PSLL_Product_Id  and  prgl1.PSLL_LossType_Id  = prgl0.PSLL_LossType_Id and prgl1.PSLL_ProductPlans_Id = prgl0.PSLL_ProductPlans_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PSLL_Product_Id    and  prgl2.PSLL_LossType_Id  = prgl0.PSLL_LossType_Id  and prgl2.PSLL_ProductPlans_Id = prgl1.PSLL_ProductPlans_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].[ProductSectionLimitLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PSLL_Product_Id    and  prgl3.PSLL_LossType_Id  = prgl0.PSLL_LossType_Id  and prgl3.PSLL_ProductPlans_Id = prgl2.PSLL_ProductPlans_Id
--where vl3.PRV_Name = 'Centriq - Booster V1.3 Hyundai -VL3'
where isnull(prgl0.PSLL_Deleted,0) = 0
and isnull(prgl1.PSLL_Deleted,0) = 0
and isnull(prgl2.PSLL_Deleted,0) = 0
and isnull(prgl3.PSLL_Deleted,0) = 0
  --order by PIL_ProductID,	PIL_InsurerID
and vl0.PRD_Name = 'Scratch and Dent'
  order by 1,2



  drop table #Insurer

  select vl0.PRD_Name as Product_Name, IGL.INS_InsurerName , 
     vl1.PRV_Name as Lvl1_name,  prgl1.PIL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name ,  prgl2.PIL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name , vl3.PRV_Code  as Lvl3_Code , 
prgl3.PIL_Deleted  as V3_Deleted , Vl3.PRV_EndDate, vl3.ProductVariant_Id, prgl1.ProductInsurerLink_Id
,vl3.PRV_UpdateUser_ID
into #Insurer
--select prgl3.*
from [Evolve].[dbo].[Product] as VL0
inner join [Evolve].[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join [Evolve].[dbo].[ProductInsurerLink] as prgl1 on vl1.ProductVariant_Id = prgl1.PIL_ProductId  inner join   [Evolve].[dbo].[Insurer] as IGL on prgl1.PIL_InsurerID = IGL.Insurer_Id
inner join [Evolve].[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer join [Evolve].[dbo].[ProductInsurerLink] as prgl2 on vl2.ProductVariant_Id = prgl2.PIL_ProductId    and  prgl2.PIL_InsurerID  = prgl1.PIL_InsurerID 
inner join [Evolve].[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join [Evolve].[dbo].[ProductInsurerLink] as prgl3 on vl3.ProductVariant_Id = prgl3.PIL_ProductId    and  prgl3.PIL_InsurerID  = prgl1.PIL_InsurerID 
where  1=1
--AND isnull(prgl1.PIL_Deleted,0) = 0
--and isnull(prgl2.PIL_Deleted,0) = 0
--and isnull(prgl3.PIL_Deleted,0) = 0
--and vl3.PRV_Name  like '%Centriq - Bumper2Bumper Term V3.1 -VL3%'
  order by 1,2

  select *
  from #Insurer
  where Lvl3_Code like '%H-WSUP-V7.0%'

  --- Product Structure
  
  select distinct *
  from (
  select INS_InsurerName,  vl0.PRD_Name as Product_Name, 
  RGP_Description ,
  DBG_Description, 
  BRA.DBR_Name ,
  --prgl0.PSCL_Deleted as Product_Deleted ,
     vl1.PRV_Name as Lvl1_name,vl1.PRV_Code as Lvl_1_code, vl1.ProductVariant_Id as VL1_Variant_id , --prgl1.PSCL_Deleted as V1_Deleted ,
   vl2.PRV_Name as Lvl2_name , vl2.PRV_Code as Lvl_2_code,vl2.ProductVariant_Id as VL2_Variant_id ,   -- prgl2.PSCL_Deleted  as V2_Deleted , 
vl3.PRV_Name  as Lvl3_name , vl3.PRV_Code as Lvl_3_code, vl3.ProductVariant_Id as VL3_Variant_id ,-- prgl3.PSCL_Deleted  as V3_Deleted , 

isnull(PRP0.APS_Deleted,0) as Product_DEL_Stat,
isnull(prgl1.APS_Deleted,0) as Variant_1_DEL_Stat,
isnull(prgl2.APS_Deleted,0) as Variant_2_DEL_Stat,
isnull(prgl3.APS_Deleted,0) as Variant_3_DEL_Stat 
--select vl0.*
from EVOLVE.[dbo].[Product] as VL0 
INNER JOIN EVOLVE.[dbo].ArrangementProductStructure as PRP0 ON VL0.Product_Id = PRP0.APS_Product_ID
inner join EVOLVE.[dbo].[ReferenceRatingGroups] as prgl0 on PRP0.APS_RatingGroup_ID = prgl0.RatingGroup_ID  
INNER JOIN EVOLVE.[dbo].DisbursementGroups as DBG on PRP0.APS_DisbursementGroup_ID  = dBg.DisbursementGroup_Id 
INNER JOIN   Evolve.[dbo].[Branding] as BRA on    PRP0.APS_Branding_ID  = BRA.Branding_ID ---PROBLEM
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id  left outer join EVOLVE.[dbo].ArrangementProductStructure as prgl1 on vl1.ProductVariant_Id = prgl1.APS_Product_ID  and  prgl1.APS_RatingGroup_ID  = prgl0.RatingGroup_ID and prgl1.APS_DisbursementGroup_ID = PRP0.APS_DisbursementGroup_ID and prgl1.APS_Branding_ID = PRP0.APS_Branding_ID
inner join EVOLVE.[dbo].[ProductVariant] as VL2  on vl2.PRV_Parent_ID = vl1.ProductVariant_Id  left outer  join EVOLVE.[dbo].ArrangementProductStructure as prgl2 on vl2.ProductVariant_Id = prgl2.APS_Product_ID    and  prgl2.APS_RatingGroup_ID  = prgl0.RatingGroup_ID  and prgl2.APS_DisbursementGroup_ID = PRP0.APS_DisbursementGroup_ID and prgl2.APS_Branding_ID = PRP0.APS_Branding_ID
inner join EVOLVE.[dbo].[ProductVariant] as VL3  on vl3.PRV_Parent_ID = vl2.ProductVariant_Id    left outer join EVOLVE.[dbo].ArrangementProductStructure as prgl3 on vl3.ProductVariant_Id = prgl3.APS_Product_ID    and  prgl3.APS_RatingGroup_ID  = prgl0.RatingGroup_ID  and prgl3.APS_DisbursementGroup_ID = PRP0.APS_DisbursementGroup_ID and prgl3.APS_Branding_ID = PRP0.APS_Branding_ID
left outer join #Insurer as I on vl3.ProductVariant_Id = I.ProductVariant_Id
where 1=1
and vl0.PRD_Deleted = 0
) as X
where 1=1
and isnull(Variant_1_DEL_Stat,0) = 0	
and isnull(Variant_2_DEL_Stat	,0) = 0	
and isnull(Variant_3_DEL_Stat,0) = 0	
-- and Lvl3_name like '%term%v5.0%'
 and Lvl_3_code = 'Q-WSUP-V8.0'
--and Product_Name = 'Warranty'
--and DBG_Description = 'Centriq ST Standard - Dealer'

  order by 1,2

  select * from EVOLVE.[dbo].ArrangementProductStructure
 select * from EVOLVE.[dbo].[ProductInsurerLink]