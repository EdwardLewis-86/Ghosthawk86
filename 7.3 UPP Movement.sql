Use UPP
Go

With cur as         (-- Current valuation month
Select              g.Pol_policyNumber Policy_key,
                    g.POL_EndDate,
                    g.CellCaptive, 
                    g.Product_Level1, 
                    g.upp
From                [dbo].[SAW_UPP_202507_Test_2] g 
                   
                    ),
prev as             (-- Start of financial period or previos mont for YTD or MoM
Select              g.Pol_policyNumber Policy_key,
                    g.POL_EndDate,
                    g.CellCaptive, 
                    g.Product_Level1, 
                    g.upp
From                [dbo].[SAW_UPP_202504] g
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
                    isnull(cur.CellCaptive, prev.CellCaptive) cell, 
                    isnull(cur.Product_Level1, prev.Product_Level1) product, 
                    isnull(cur.upp, 0) CurrentUPP,
                    isnull(prev.UPP, 0) PreviousUPP, 

					Case 
                        when prev.policy_key is null then 0
                        else 1
                    end PrevCount,
					Case 
                        when cur.policy_key is null then 0
                        else 1
                    end CurCount,

                    Case 
                        when prev.policy_key is null then 1 
                        else 0 
                    end NewBus,
                    Case 
                        when prev.policy_key is null then cur.UPP 
                        else 0 
                    end NewBusUPP,
                    cur.Upp - prev.UPP UPPRelease
From                pol
                    left join prev 
                    on prev.policy_key = pol.policy_key
                    left join cur 
                    on cur.policy_key = pol.policy_key
                    )

Select              --sum(PrevCount) PrevCount,
                    --sum(CurCount) CurCount,
                    sum(currentupp) CurrentUPP,
                    sum(previousupp) PreviousUPP, NewBus,
                    cell, 
                    product
					--Policy_key,
					--POL_EndDate
From                u
Group by            NewBus,
                    cell, 
                    product;
					--Policy_key,
					--POL_EndDate;
					
/*

Select u.* , case when UPPRelease is NULL then 0 when UPPRelease =0 then 0 else 1 end ReleaseInd
from u 
where product = 'platinum' and cell = 'AMH' and UPPRelease is not NULL and UPPRelease !=0 

*/

