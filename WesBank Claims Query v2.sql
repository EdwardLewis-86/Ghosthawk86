
with filteredclaims as (
    select *
    from 
	(select *,
           sum(ocr_movement) over (partition by clm_policynumber, clm_claimnumber) as ocr_balance
    from [rb_analysis].[dbo].[evolve_claim_summary]
	) c
    where 1=1
	  and c.amount_paid > 0
      and c.cic_description in ('credit shortfall', 'deposit cover', 'violation cover')
      and c.clm_reporteddate < DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	--  and clm_claimnumber = 'HADC049193CLM'
--	  and clm_policynumber = 'HADC091917POL'
),
policies as (
    select *
    from [rb_analysis].[dbo].[evolve_policy]
    where 1=1
	--and agent_insurer_name in ('discovery insure','discovery insure s&d')
	--and pol_policynumber = 'ov4u005832pol'
)

select 
    c.clm_policynumber as [Policy number],
    c.clm_claimnumber as [Benefit number],
    eomonth(c.clm_reporteddate) as MTHD,
    p.pol_originalstartdate as POL_OriginalStartDate,
    c.clm_reporteddate as [Claim report date],
    c.cic_description as [Benefit/Claim type],
	sum(c.amount_paid) + sum(ocr_balance) as  ClaimAmount ,
	    substring(
        arrangement_cell_captive,
        charindex('(', arrangement_cell_captive) + 1,
        charindex(')', arrangement_cell_captive) - charindex('(', arrangement_cell_captive) - 1
    ) as CellCaptive,
	case 
	   when p.pol_product_id in (
	     'dddc2da4-881f-40b9-a156-8b7ea881863a','d0a30440-6f96-4735-a841-f601504be51c',
	     '436bb1d0-cb35-4ff0-bd50-a316a08ae87b','70292f27-b7ee-4274-8b51-e345f4c1ad18',
	     '77c92c34-0cbb-4554-bd41-01f2d8f5fc11','86e44060-b546-4a65-9464-9c4f78c1681e') 
	    and coalesce(p.pol_solddate, p.pol_originalstartdate) >= '2022-10-01' then 1
	   when p.pol_product_id in (
	      'dddc2da4-881f-40b9-a156-8b7ea881863a','d0a30440-6f96-4735-a841-f601504be51c',
	      '436bb1d0-cb35-4ff0-bd50-a316a08ae87b','70292f27-b7ee-4274-8b51-e345f4c1ad18',
	      '77c92c34-0cbb-4554-bd41-01f2d8f5fc11','86e44060-b546-4a65-9464-9c4f78c1681e') 
	    and coalesce(p.pol_solddate, p.pol_originalstartdate) < '2022-10-01' then 0
	   else null 
    end as NewRateInd


from filteredclaims c
left join policies p 
on c.clm_policynumber = p.pol_policynumber

where 1=1
and arrangement_cell_captive in (
        'wesbank (wesb)', 'wesbank amh pos (wamp)', 'wesbank amh telesales (wamt)',
        'wesbank auto pedigree pos (wapp)', 'wesbank auto pedigree telesales (wapt)',
        'wesbank imperial auto retail pos (wiap)', 'wesbank pos independent (wesp)'
    )
and p.pol_product_id in (
	     'dddc2da4-881f-40b9-a156-8b7ea881863a','d0a30440-6f96-4735-a841-f601504be51c',
	     '436bb1d0-cb35-4ff0-bd50-a316a08ae87b','70292f27-b7ee-4274-8b51-e345f4c1ad18',
	     '77c92c34-0cbb-4554-bd41-01f2d8f5fc11','86e44060-b546-4a65-9464-9c4f78c1681e') 
group by 
    c.clm_policynumber,
    c.clm_claimnumber,
    eomonth(c.clm_reporteddate),
    p.pol_originalstartdate,
    c.clm_reporteddate,
    c.cic_description,
	   substring(
        arrangement_cell_captive,
        charindex('(', arrangement_cell_captive) + 1,
        charindex(')', arrangement_cell_captive) - charindex('(', arrangement_cell_captive) - 1
    ),
   	case 
	   when p.pol_product_id in (
	     'dddc2da4-881f-40b9-a156-8b7ea881863a','d0a30440-6f96-4735-a841-f601504be51c',
	     '436bb1d0-cb35-4ff0-bd50-a316a08ae87b','70292f27-b7ee-4274-8b51-e345f4c1ad18',
	     '77c92c34-0cbb-4554-bd41-01f2d8f5fc11','86e44060-b546-4a65-9464-9c4f78c1681e') 
	    and coalesce(p.pol_solddate, p.pol_originalstartdate) >= '2022-10-01' then 1
	   when p.pol_product_id in (
	      'dddc2da4-881f-40b9-a156-8b7ea881863a','d0a30440-6f96-4735-a841-f601504be51c',
	      '436bb1d0-cb35-4ff0-bd50-a316a08ae87b','70292f27-b7ee-4274-8b51-e345f4c1ad18',
	      '77c92c34-0cbb-4554-bd41-01f2d8f5fc11','86e44060-b546-4a65-9464-9c4f78c1681e') 
	    and coalesce(p.pol_solddate, p.pol_originalstartdate) < '2022-10-01' then 0
	   else null
    end

order by 
    c.clm_claimnumber, c.clm_reporteddate;
