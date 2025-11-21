Use UPP
Go



With prev as             (-- Start of financial period or previous month for YTD or MoM
Select              g.Pol_policyNumber as Policy_key,
                    g.POL_EndDate,
                    g.CellCaptive, 
                    g.Product_Level1, 
                    g.upp,
                    g.INS_InsurerName            
From                [dbo].[SAW_UPP_202506_Test] g
),

cur as               (-- Current valuation month
Select              g.Pol_policyNumber as Policy_key,
                    g.POL_EndDate,
                    g.CellCaptive, 
                    g.Product_Level1, 
                    g.upp,
                    g.INS_InsurerName           
From                [dbo].[SAW_UPP_202509] g
),

pol as              ( -- Subquery for policies explaining movement
Select              policy_key
From                cur 
Union
Select              policy_key
From                prev),

u as                (
Select              pol.Policy_key,
                    prev.POL_EndDate,
                    isnull(cur.CellCaptive, prev.CellCaptive) as cell, 
                    isnull(cur.Product_Level1, prev.Product_Level1) as product, 
                    isnull(cur.INS_InsurerName, prev.INS_InsurerName) as Insurer,   
                    isnull(cur.upp, 0) as CurrentUPP,
                    isnull(prev.UPP, 0) as PreviousUPP, 

                    Case when prev.policy_key is null then 0 else 1 end as PrevCount,
                    Case when cur.policy_key  is null then 0 else 1 end as CurCount,

                    Case when prev.policy_key is null then 1 else 0 end as NewBus,
                    Case when prev.policy_key is null then cur.UPP else 0 end as NewBusUPP,
                    cur.Upp - prev.UPP as UPPRelease
From                pol
left join           prev on prev.policy_key = pol.policy_key
left join           cur  on cur.policy_key  = pol.policy_key
)

Select              --sum(PrevCount) as PrevCount,
                    --sum(CurCount)  as CurCount,
                    sum(CurrentUPP)   as CurrentUPP,
                    sum(PreviousUPP)  as PreviousUPP,
                    NewBus,
                    Insurer,          -- <== now included in output
                    cell, 
                    product
                    --Policy_key,
                    --POL_EndDate
From                u
Group by            NewBus,
                    Insurer,          -- <== now included in grouping
                    cell, 
                    product;
                    --Policy_key,
                    --POL_EndDate;

/*
Diagnostics (optional):
Select u.* , case when UPPRelease is NULL then 0 when UPPRelease = 0 then 0 else 1 end as ReleaseInd
from u 
where product = 'platinum' and cell = 'AMH' and UPPRelease is not NULL and UPPRelease != 0 
*/
