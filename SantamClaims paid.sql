
drop table if exists #PAID ;

Select 

EOMONTH(CIT_PostingDate) Mth ,CIT_ClaimItem_ID,CIS_ClaimNumber,CWI_Make ,-sum(CIT_Amount) Paid_Amount 

INTO #PAID

from [Evolve].[dbo].[ClaimItemTransaction] 

						inner join Evolve.dbo.ClaimItemSummary on CIS_ClaimItem_ID = CIT_ClaimItem_ID
						inner join Evolve.dbo.Claim cm  on Claim_ID = CIS_Claim_ID
						left join [Evolve].[dbo].[ClaimWarrantyItem] on [CIS_ClaimItem_ID] = [ClaimWarrantyItem_ID] 



WHERE 1=1 
and CIT_TransactionType_ID = 2 
and CLM_PolicyNumber like 'S%'



GROUP BY CIT_ClaimItem_ID,EOMONTH(CIT_PostingDate),CIS_ClaimNumber,CWI_Make 


select Mth,		CWI_Make, Count(*) ClaimsCount,	sum(Paid_Amount) Paid_Amount


from #paid

group by Mth,		CWI_Make

--having sum(Paid_Amount) >0