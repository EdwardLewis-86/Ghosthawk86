select  Variant_2_Code, PRV_Code as Variant_code, v.Variant_Name, PRP_PlanName,  rtf.CMP_Description, 
--prgl0.PSCL_Deleted,prgl0.PSCL_Type, prgl0.PSCL_ComponentLimit,
--isnull(prgl1.PSCL_Deleted,0) as Deleted_LVL_1 , prgl1.PSCL_Type, prgl1.PSCL_ComponentLimit ,
--isnull(prgl2.PSCL_Deleted,0) as Deleted_LVL_2 , prgl2.PSCL_Type, prgl2.PSCL_ComponentLimit  ,
isnull(prgl3.PSCL_Deleted,0) as Deleted_LVL_3 , 
case when isnull(prgl3.PSCL_Type,prgl2.PSCL_Type) = 1 then 'Unlimited'
when isnull(prgl3.PSCL_Type,prgl2.PSCL_Type) = 2 then 'Fixed Value'
when isnull(prgl3.PSCL_Type,prgl2.PSCL_Type) = 3 then 'Not Available'
else 'Unknown' end as Limit_Type,
case when prgl3.PSCL_Type is not null then 'VL3' else 'VL2' end as Component_Limit_Level
 
, isnull(prgl3.PSCL_ComponentLimit, prgl2.PSCL_ComponentLimit) as Component_limit
--select prgl0.*
from (
select Product_Id, vl1.ProductVariant_Id as Variant1 ,vl2.ProductVariant_Id  as Variant2 ,
vl2.PRV_Code as Variant_2_Code,vl2.PRV_Name as Variant_2_name,
vl3.ProductVariant_Id  as Variant3 ,
vl3.PRV_Code, vl3.PRV_Name as Variant_Name,
prp.PRP_PlanName, prp.ProductPlans_Id,
prp1.PRP_Deleted  
from   EVOLVE.[dbo].[Product] as VL0
INNER JOIN EVOLVE.[dbo].[ProductPlans] as PRP on vl0.Product_Id = prp.PRP_Product_Id
inner join EVOLVE.[dbo].[ProductVariant] as VL1 on vl1.PRV_Parent_ID = vl0.Product_Id
left outer JOIN EVOLVE.[dbo].[ProductPlans] as PRP1 on vl1.ProductVariant_Id = prp1.PRP_Product_Id and prp.PRP_PlanName = prp1.PRP_PlanName and prp1.PRP_Deleted <> 1
inner join EVOLVE.[dbo].[ProductVariant] as VL2 on vl2.PRV_Parent_ID = vl1.ProductVariant_Id
left outer JOIN EVOLVE.[dbo].[ProductPlans] as PRP2 on vl2.ProductVariant_Id = prp2.PRP_Product_Id and prp.PRP_PlanName = prp2.PRP_PlanName and prp2.PRP_Deleted <> 1
inner join EVOLVE.[dbo].[ProductVariant] as VL3 on vl3.PRV_Parent_ID = vl2.ProductVariant_Id
left outer JOIN EVOLVE.[dbo].[ProductPlans] as PRP3 on vl3.ProductVariant_Id = prp3.PRP_Product_Id and prp.PRP_PlanName = prp3.PRP_PlanName and prp3.PRP_Deleted <> 1
where 1=1
and vl3.PRV_Code = 'H-B2BO-V5.1'
and isnull(prp1.PRP_Deleted,0) = 0
and isnull(prp2.PRP_Deleted,0) = 0
and isnull(prp3.PRP_Deleted,0) = 0
--and prp.ProductPlans_Id = '703CDF1A-EBC2-4D3F-8288-B9F581491289'
 
) as V
inner join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl0 on v.Product_Id = prgl0.PSCL_Product_Id  and v.ProductPlans_Id = prgl0.PSCL_ProductPlans_Id
--INNER JOIN EVOLVE.[dbo].[ProductPlans] as PRP on prgl0.PSCL_ProductPlans_Id = prp.ProductPlans_Id 
INNER JOIN  [Evolve].[dbo].[ReferenceComponent] as RTF on prgl0.PSCL_Component_Id = RTF.Component_ID
left join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl1 on v.Variant1 = prgl1.PSCL_Product_Id and prgl1.PSCL_ProductPlans_Id = prgl0.PSCL_ProductPlans_Id and prgl0.PSCL_Component_Id = prgl1.PSCL_Component_Id
left join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl2 on v.Variant2 = prgl2.PSCL_Product_Id and prgl2.PSCL_ProductPlans_Id = prgl0.PSCL_ProductPlans_Id and prgl0.PSCL_Component_Id = prgl2.PSCL_Component_Id
left join EVOLVE.[dbo].[ProductSectionComponentLink] as prgl3 on v.Variant3 = prgl3.PSCL_Product_Id and prgl3.PSCL_ProductPlans_Id = prgl0.PSCL_ProductPlans_Id and prgl0.PSCL_Component_Id = prgl3.PSCL_Component_Id
 
--INNER JOIN EVOLVE.[dbo].[ProductPlans] as PRP1 on prgl1.PSCL_ProductPlans_Id = prp1.ProductPlans_Id 
--INNER JOIN  [Evolve].[dbo].[ReferenceComponent] as RTF1 on prgl0.PSCL_Component_Id = RTF.Component_ID
where prgl0.PSCL_Deleted = 0
--and PRP_PlanName = 'Criteria Four: Option 4'
and isnull(prgl1.PSCL_Deleted,0) = 0
and isnull(prgl2.PSCL_Deleted,0) = 0
and isnull(prgl3.PSCL_Deleted,0) = 0
order by 1,2,3,4,5