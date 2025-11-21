--Top 5 Adcover exposures
Use [Evolve]
Go


SELECT distinct 
	p.pol_policynumber [Policy Number]
	,[PCI_SumInsured] [Sum Insured ]
	, 'Adcover' [Product]
FROM [Evolve].[dbo].[PolicyCreditShortfallItem] pc
inner join policy p
	on PCI_Policy_ID = p.Policy_ID
where p.POL_Status = 1
	and p.POL_EndDate >= '30-June-2025'
	and p.pol_policynumber like 'Q%'
order by [PCI_SumInsured] desc

