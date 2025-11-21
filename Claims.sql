use [Evolve]	


Drop table  if exists #Claims;
Drop table  if exists #ClaimsPayment;
Drop table  if exists #ClaimsNonPayment;
Drop table  if exists #RCA;
Drop table  if exists #CAP;
Drop table  if exists #CAPD;
Drop table  if exists #ClaimsRejected;
Drop table  if exists #CAPR;
Drop table  if exists #RCAR;
Drop table  if exists #planN;
Drop table  if exists #CAPT;
Drop table  if exists #finalClaims;
Drop table  if exists #finalClaims2;
Drop table  if exists #finalClaims3;
Drop table  if exists #finalClaims4;
Drop table  if exists #finalClaims5;
Drop table  if exists #Products;

CREATE TABLE #Products (ProductID Varchar(50));


Declare				@AsAtDate date = '01 November 2025';
--Declare				@QstartDate date = '2000-10-01';
--Declare				@QEndDate date = '2023-01-01';



--INSERT INTO #Products VALUES ('83A65AC4-37EC-4776-959D-99D46D0A2A10'); --LPP Hollard
--INSERT INTO #Products VALUES ('DF78BA49-F342-4745-B3B9-39F21430EB24'); --LPP Centriq
INSERT INTO #Products VALUES ('DDDC2DA4-881F-40B9-A156-8B7EA881863A');  --Adcover (H)
INSERT INTO #Products VALUES ('D0A30440-6F96-4735-A841-F601504BE51C');  --Vehicle Value Protector(Adcover)(H)
INSERT INTO #Products VALUES ('436BB1D0-CB35-4FF0-BD50-A316A08AE87B');  --Adcover (H)
INSERT INTO #Products VALUES ('70292F27-B7EE-4274-8B51-E345F4C1AD18');  --Adcover & Deposit Cover Combo (Q)
INSERT INTO #Products VALUES ('77C92C34-0CBB-4554-BD41-01F2D8F5FC11');  --Vehicle Value Protector(Adcover)(Q)
INSERT INTO #Products VALUES ('86E44060-B546-4A65-9464-9C4F78C1681E');  --Adcover & Deposit Cover Combo (H)
INSERT INTO #Products VALUES ('1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB');   --Deposit Cover (H)
--INSERT INTO #Products VALUES ('5557806D-8733-458E-969A-9134F37C77D2');   --Auto Pedigree Plus Plan with Deposit Cover yearly
INSERT INTO #Products VALUES ('A80549F3-E47F-44C1-8037-F065522A03F6');   --Deposit Cover (Q)


--select * from #Products

--Payment data

								
select     -- *
            POL_PolicyNumber [Policy Number] ,CLM_ClaimNumber [Claim Number],CIT_ClaimItem_ID,[PRD_Name] [Product Name],[PRD_Name] [Product]
            ,CIS_SectionName [Section],[CLB_PlanName],CIS_Description, CIS_ClaimDescription, CIS_LossTypeDescription, CIS_LossTypeDescription  [Risk Type3]
			,POL_StartDate [Policy Inception Date],POL_FinanceTerm_ID [Policy Term], CLM_LossDate [Date of Loss] 
			,CLM_ReportedDate [Claim Date Reported], CIT_CreateDate [Transaction Date]
			,[PCI_SumInsured] [Sum Insured] ,ATN_NettAmount [Claims Paid Movement (Excl VAT)] , CLS_Description [Claim Status]
			,CIT_TransactionTypeDescription, 'Rand' [Policy Currency Claim currency] 
			,case when CLM_ClientMaskedIDNumber = CLB_MaskedIDNumber then 'Main Life' else 'Addtinal life' end  [Claimant Type] 
			 , case when CLB_Gender_ID = 2 then 'Male' else 'Female' end [Claimant Gender]
		   ---- , cast (left( Year(DATEADD(year,-CLB_Age,CLM_LossDate)) ,2)+SUBSTRING(CLB_MaskedIDNumber,1,2)+'-'+ SUBSTRING(CLB_MaskedIDNumber,3,2)+'-'+SUBSTRING(CLB_MaskedIDNumber,5,2) as date) [Claimant birthdate]

into        #ClaimsPayment				
			
								
from        [Evolve].[dbo].AccountTransaction AT

inner join  [Evolve].[dbo].AccountTransactionSet ATS on AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
inner join  [Evolve].[dbo].AccountParty AP  on ATN_AccountParty_ID = AccountParty_Id
inner join  [Evolve].[dbo].ClaimItemTransaction on CIT_Set_ID = AccountTransactionSet_Id
inner join  [Evolve].[dbo].ClaimItemSummary on CIT_ClaimItem_ID = CIS_ClaimItem_ID
left join   [Evolve].[dbo].claim  on CIS_Claim_ID = Claim_ID
left join   [Evolve].[dbo].policy on CLM_PolicyNumber = POL_PolicyNumber
left join   [Evolve].[dbo].[Product] on POL_Product_ID = [Product_Id]
left join   [Evolve].[dbo].PolicyCreditLifeItem on Policy_ID = [PCI_Policy_ID]
left join   [Evolve].[dbo].ReferenceClaimstatus on ClaimStatus_ID = CLM_Status  

--Left join Agent  on Agent_Id = POL_Agent_ID


left join   ( select distinct CLB_Claim_ID, CLB_Gender_ID, CLB_MaskedIDNumber,[CLB_PlanName] from [Evolve].[dbo].[ClaimCreditLifeBasicItem] ) a on a.CLB_Claim_ID = [Claim_ID]




where		1=1
								
			and CIT_TransactionTypeDescription  like '%Payment%'
			and APY_RegisteredName = 'Gross Outstanding Claims'
			
			and ATS_CreateDate < @AsAtDate

			and [Product_Id] IN (select * from #Products) 
         ---  and Agt_Name like '%TMS%'


           -- and CLS_Description <> 'Rejected'
	--		and POL_PolicyNumber = 'HADC014926POL'

		--	select * from #ClaimsPayment where [Transaction Date]>= '2024-12-01' 
		--select distinct CLM_Status from Claim left join   ReferenceClaimstatus on ClaimStatus_ID = CLM_Status 
		--select distinct ClaimStatus_ID,CLS_Description from Claim left join   ReferenceClaimstatus on ClaimStatus_ID = CLM_Status 





--Nonpaynent data

									  						
select          POL_PolicyNumber [Policy Number] ,CLM_ClaimNumber [Claim Number],CIT_ClaimItem_ID,[PRD_Name] [Product Name],[PRD_Name] [Product]
			   ,CIS_SectionName [Section],[CLB_PlanName], CIS_Description	,CIS_ClaimDescription	,CIS_LossTypeDescription, CIS_LossTypeDescription  [Risk Type3]
			   ,POL_StartDate [Policy Inception Date], POL_FinanceTerm_ID [Policy Term], CLM_LossDate [Date of Loss] 
			   ,CLM_ReportedDate [Claim Date Reported], CIT_CreateDate [Transaction Date], [PCI_SumInsured] [Sum Insured] 
			   ,ATN_NettAmount [Claims Paid Movement (Excl VAT)] , CLS_Description [Claim Status], CIT_TransactionTypeDescription
			   ,'Rand' [Policy Currency Claim currency] 
			   ,case when CLM_ClientMaskedIDNumber = CLB_MaskedIDNumber then 'Main Life' else 'Addtinal life' end  [Claimant Type] 
			    , case when CLB_Gender_ID = 2 then 'Male' else 'Female' end [Claimant Gender]
		   --  , cast (left( Year(DATEADD(year,-CLB_Age,CLM_LossDate)) ,2)+SUBSTRING(CLB_MaskedIDNumber,1,2)+'-'
		   --  + SUBSTRING(CLB_MaskedIDNumber,3,2)+'-'+SUBSTRING(CLB_MaskedIDNumber,5,2) as date) [Claimant birthdate]

into            #ClaimsNonPayment				
			 
								
from			[Evolve].[dbo].AccountTransaction AT

inner join      [Evolve].[dbo].AccountTransactionSet ATS on AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
inner join      [Evolve].[dbo].AccountParty AP  on ATN_AccountParty_ID = AccountParty_Id
inner join      [Evolve].[dbo].ClaimItemTransaction on CIT_Set_ID = AccountTransactionSet_Id
inner join      [Evolve].[dbo].ClaimItemSummary on CIT_ClaimItem_ID = CIS_ClaimItem_ID
left join       [Evolve].[dbo].claim  on CIS_Claim_ID = Claim_ID
left join       [Evolve].[dbo].policy on CLM_PolicyNumber = POL_PolicyNumber
left join       [Evolve].[dbo].[Product] on POL_Product_ID = [Product_Id]
left join       [Evolve].[dbo].PolicyCreditLifeItem on Policy_ID = [PCI_Policy_ID]
left join       [Evolve].[dbo].ReferenceClaimstatus on ClaimStatus_ID = CLM_Status  

--Left join Agent  on Agent_Id = POL_Agent_ID


left join       ( select distinct CLB_Claim_ID, CLB_Gender_ID, CLB_MaskedIDNumber,[CLB_PlanName] from [Evolve].[dbo].[ClaimCreditLifeBasicItem] ) a
				on a.CLB_Claim_ID = [Claim_ID]




where			1=1

								
and CIT_TransactionTypeDescription not like '%Payment%'
								
							
and APY_RegisteredName = 'Gross Outstanding Claims'

								
and ATS_CreateDate < @AsAtDate


and [Product_Id] IN (select * from #Products)
--and Agt_Name like '%TMS%'

--and CLS_Description <> 'Rejected'


--Rejected data

									  						
select          POL_PolicyNumber [Policy Number] ,CLM_ClaimNumber [Claim Number],CIT_ClaimItem_ID,[PRD_Name] [Product Name],[PRD_Name] [Product]
			   ,CIS_SectionName [Section],[CLB_PlanName], CIS_Description	,CIS_ClaimDescription	,CIS_LossTypeDescription, CIS_LossTypeDescription  [Risk Type3]
			   ,POL_StartDate [Policy Inception Date], POL_FinanceTerm_ID [Policy Term], CLM_LossDate [Date of Loss] 
			   ,CLM_ReportedDate [Claim Date Reported], CIT_CreateDate [Transaction Date], [PCI_SumInsured] [Sum Insured] 
			   ,ATN_NettAmount [Claims Paid Movement (Excl VAT)] , CLS_Description [Claim Status], CIT_TransactionTypeDescription
			   ,'Rand' [Policy Currency Claim currency] 
			   ,case when CLM_ClientMaskedIDNumber = CLB_MaskedIDNumber then 'Main Life' else 'Addtinal life' end  [Claimant Type] 
			    , case when CLB_Gender_ID = 2 then 'Male' else 'Female' end [Claimant Gender]
		   --  , cast (left( Year(DATEADD(year,-CLB_Age,CLM_LossDate)) ,2)+SUBSTRING(CLB_MaskedIDNumber,1,2)+'-'
		   --  + SUBSTRING(CLB_MaskedIDNumber,3,2)+'-'+SUBSTRING(CLB_MaskedIDNumber,5,2) as date) [Claimant birthdate]

into            #ClaimsRejected				
			 
								
from			[Evolve].[dbo].AccountTransaction AT

inner join      [Evolve].[dbo].AccountTransactionSet ATS on AccountTransactionSet_Id = ATN_AccountTransactionSet_ID
inner join      [Evolve].[dbo].AccountParty AP  on ATN_AccountParty_ID = AccountParty_Id
inner join      [Evolve].[dbo].ClaimItemTransaction on CIT_Set_ID = AccountTransactionSet_Id
inner join      [Evolve].[dbo].ClaimItemSummary on CIT_ClaimItem_ID = CIS_ClaimItem_ID
left join       [Evolve].[dbo].claim  on CIS_Claim_ID = Claim_ID
left join       [Evolve].[dbo].policy on CLM_PolicyNumber = POL_PolicyNumber
left join       [Evolve].[dbo].[Product] on POL_Product_ID = [Product_Id]
left join       [Evolve].[dbo].PolicyCreditLifeItem on Policy_ID = [PCI_Policy_ID]
left join       [Evolve].[dbo].ReferenceClaimstatus on ClaimStatus_ID = CLM_Status  

--Left join Agent  on Agent_Id = POL_Agent_ID


left join       ( select distinct CLB_Claim_ID,  CLB_Gender_ID, CLB_MaskedIDNumber,[CLB_PlanName] from [Evolve].[dbo].[ClaimCreditLifeBasicItem] ) a
				on a.CLB_Claim_ID = [Claim_ID]




where			1=1

								
--and CIT_TransactionTypeDescription not like '%Payment%'
								
							
and APY_RegisteredName = 'Gross Outstanding Claims'


								
and ATS_CreateDate < @AsAtDate

and CLS_Description = 'Rejected'

and [Product_Id] IN (select * from #Products) 
--and Agt_Name like '%TMS%'





--aggregate paid claims 


select [Claim Number] ,CIT_ClaimItem_ID, sum([Claims Paid Movement (Excl VAT)]) ClaimAmountPaid 
								

into #CAP

from #ClaimsPayment


								
where 1=1 

--and [Claim Number] = 'HCLL011423CLM'

group by [Claim Number],CIT_ClaimItem_ID




--aggregate non paid claims ie Claim Amount Raised
									  
select [Claim Number],CIT_ClaimItem_ID , sum([Claims Paid Movement (Excl VAT)]) RaisedClaimAmount

into #RCA
from #ClaimsNonPayment
								

where 1=1 

--and [Claim Number] = 'HCLL011423CLM'

group by CIT_ClaimItem_ID,[Claim Number]






--Select the latest payment  Transaction date

select [Claim Number],CIT_ClaimItem_ID , Max([Transaction Date]) PaymentDate
								

into #CAPD

from #ClaimsPayment



where 1=1 
--and [Claim Number] = 'HCLL005679CLM'

group by [Claim Number],CIT_ClaimItem_ID
							

					--		select * from #RCA


--Select the latest rejection Transaction date

select [Claim Number],CIT_ClaimItem_ID , Max([Transaction Date]) RejectionDate
								

into #CAPR

from #ClaimsRejected



where 1=1 



group by [Claim Number],CIT_ClaimItem_ID


--Select the latest  Transaction date

select t.[Claim Number],t.CIT_ClaimItem_ID , Max([Transaction Date]) latestTransactionDate
								

into #CAPT 

from #ClaimsNonPayment t

left join #RCA r
on r.CIT_ClaimItem_ID = t.CIT_ClaimItem_ID
left join #CAP a
on a.CIT_ClaimItem_ID = t.CIT_ClaimItem_ID




where 1=1 

and t.CIT_ClaimItem_ID not in (select CIT_ClaimItem_ID from  #CAPD)
and t.CIT_ClaimItem_ID not in (select CIT_ClaimItem_ID from  #CAPR)
and [Claim Status] in ('Finalised')
and r.RaisedClaimAmount + isnull (a.ClaimAmountPaid,0) = 0 



group by t.[Claim Number],t.CIT_ClaimItem_ID



--Plan name 

select distinct       [CIC_ClaimItem_ID],[CIC_Description]

into #planN

from [Evolve].[dbo].[ClaimItemComponents]




--Final claims data

select [Policy Number],	
c.[Claim Number],	
c.CIT_ClaimItem_ID,
[Product Name],	
[Product],	
[Section],
[CLB_PlanName],
[CIC_Description],
[CIS_Description],	
[CIS_ClaimDescription],	
[CIS_LossTypeDescription],	
[Risk Type3],	
[Policy Inception Date],	
[Policy Term],	
[Date of Loss],	
[Claim Date Reported],	
case when [Claim Status] = 'Rejected' then NULL else  d.PaymentDate end PaymentDate,
p.RejectionDate,
latestTransactionDate,
datediff(day,[Claim Date Reported],latestTransactionDate) TransAge,
[Sum Insured],	
case when [Claim Status] = 'Rejected' then 0 else  r.RaisedClaimAmount end RaisedClaimAmount ,
case when [Claim Status] = 'Rejected' then 0 else isnull (a.ClaimAmountPaid,0) end ClaimAmountPaid, 
case when [Claim Status] = 'Rejected' then 0 else r.RaisedClaimAmount + isnull (a.ClaimAmountPaid,0) end OutstandingClaimAmount,

case when r.RaisedClaimAmount + isnull (a.ClaimAmountPaid,0) <>0 and [Claim Status] = 'Finalised' 
     then 'Open' else [Claim Status] end [Claim Status],	

[CIT_TransactionTypeDescription],	
[Policy Currency Claim currency],	
[Claimant Type],	

[Claimant Gender]	
--	,[Claimant birthdate]

into #claims

--select * from #claims

from #ClaimsNonPayment c
											
left join #RCA r
on r.CIT_ClaimItem_ID = c.CIT_ClaimItem_ID
left join #CAP a
on a.CIT_ClaimItem_ID = c.CIT_ClaimItem_ID
left join #CAPD d
on d.CIT_ClaimItem_ID = c.CIT_ClaimItem_ID
left join #CAPR p
on p.CIT_ClaimItem_ID = c.CIT_ClaimItem_ID

left join #CAPT t
on t.CIT_ClaimItem_ID = c.CIT_ClaimItem_ID

left join #planN n
on [CIC_ClaimItem_ID] = c.CIT_ClaimItem_ID

where 1=1
and CIT_TransactionTypeDescription = 'Original Estimate'


--Populate results


select 
[Policy Number],
[Claim Number],
[CIT_ClaimItem_ID],
[Product Name],
[Product],
[Section],
[CLB_PlanName],
[CIC_Description],
[CIS_Description],
[CIS_ClaimDescription],
[CIS_LossTypeDescription],
[Risk Type3],
[Policy Inception Date],
[Policy Term],
[Date of Loss],
[Claim Date Reported],
[PaymentDate],
[RejectionDate],
[latestTransactionDate],
[TransAge],
[Sum Insured],
[RaisedClaimAmount],
[ClaimAmountPaid],
[OutstandingClaimAmount],
[Claim Status],
case when [OutstandingClaimAmount] = 0 and  [RaisedClaimAmount] = 0 and [ClaimAmountPaid] = 0 and [Claim Status] ='Rejected' then 'Rejected'
     when [OutstandingClaimAmount] = 0 and  [RaisedClaimAmount] = 0 and [ClaimAmountPaid] = 0 and [Claim Status] ='Open' then 'Open'
	 when [OutstandingClaimAmount] = 0 and  [RaisedClaimAmount] = 0 and [ClaimAmountPaid] = 0 and [Claim Status] ='Finalised' 
	 and [TransAge] <365 then 'Not paid'
	 	 when [OutstandingClaimAmount] = 0 and  [RaisedClaimAmount] = 0 and [ClaimAmountPaid] = 0 and [Claim Status] ='Finalised' 
	 and [TransAge] >= 365 then 'Abandoned'
	 when [OutstandingClaimAmount] = 0 and [Claim Status] ='Finalised' then 'Fully paid'
	 when [OutstandingClaimAmount] <> 0 and  [RaisedClaimAmount] <> 0 and [ClaimAmountPaid] <> 0 and [Claim Status] ='Finalised' then 'Partially paid'
	 when [OutstandingClaimAmount] <> 0 and  [RaisedClaimAmount] <> 0 and [ClaimAmountPaid] <> 0 and [Claim Status] ='Open' then 'Partially paid'
	 when [RaisedClaimAmount] <> 0 and [ClaimAmountPaid] = 0 and [Claim Status] ='Open' then 'Raised'
	 when [OutstandingClaimAmount] = 0 and  [RaisedClaimAmount] <> 0 and [ClaimAmountPaid] <> 0 and [Claim Status] ='Open' then 'Partially paid'
end [Claim Status2],

[CIT_TransactionTypeDescription],
[Policy Currency Claim currency],
[Claimant Type],
[Claimant Gender]

into #finalClaims


from #claims

where 1=1 
--and [Claim Status] = 'Rejected'
--and [Policy Number] in ('HCLL035621POL','HCLL026677POL','HCLL035904POL','HCLL013624POL','HCLL021669POL') 
--and OutstandingClaimAmount = 0
--and ClaimAmountPaid <> 0
--and [Claim Number] in ('HCLL011423CLM')

--delete 1
delete from #finalClaims

where [Claim Number] in ( select [Claim Number] from #finalClaims where [Claim Status2] = 'Fully paid')
      and [Claim Status2] in ( 'Not paid','Raised','Abandoned')

--delete 2
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Bronze - Option 1', 'Bronze - Option 2') and [Claim Status2] = 'Fully paid')
      and [Claim Status2] in ( 'Not paid','Abandoned')

--delete 3
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Silver') and [Claim Status2] = 'Fully paid')
      and [Claim Status2] in ( 'Not paid','Abandoned')


	  --delete 4
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Silver') and [Claim Status2] = 'Rejected')
      and [Claim Status2] in ( 'Not paid','Abandoned')

	  	  --delete 5
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Bronze - Option 1', 'Bronze - Option 2') and [Claim Status2] = 'Abandoned')
      and [Claim Status2] in ( 'Not paid')

		  	  --delete 6
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Silver') and [Claim Status2] = 'Abandoned')
      and [Claim Status2] in ( 'Not paid')

	  		  	  --delete 7
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Wesbank CL MP New Rate') and [Claim Status2] = 'Fully paid')
      and [Claim Status2] in ( 'Not paid')

	  	  		  	  --delete 8
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Gold') and [Claim Status2] = 'Fully paid')
      and [Claim Status2] in ( 'Not paid')

	  	  	  		  	  --delete 9
	  delete from #finalClaims

where [Policy Number] in ( select [Policy Number] from #finalClaims 
                            where CLB_PlanName in ('Gold') and [Claim Status2] = 'Raised')
      and [Claim Status2] in ( 'Not paid')
  
    	  	  		  	  --delete 10
	  delete from #finalClaims

where TransAge < 50

	  





select  
[Policy Number],
[Claim Number],
[CIT_ClaimItem_ID],
[Product Name],
[Product],
[Section],
[CLB_PlanName],
[CIC_Description],
[CIS_Description],
[CIS_ClaimDescription],
[CIS_LossTypeDescription],
[Risk Type3],
[Policy Inception Date],
[Policy Term],
[Date of Loss],
[Claim Date Reported],
[PaymentDate],
[RejectionDate],
[latestTransactionDate],
[TransAge],
[Sum Insured],
[RaisedClaimAmount],
[ClaimAmountPaid],
[OutstandingClaimAmount],
[Claim Status],
[Claim Status2],
case when  [Claim Status2] in ('Partially paid','Raised') then 'Open'
     when  [Claim Status2] in ('Not paid','Abandoned') then 'Abandoned'
	 when  [Claim Status2] in ('Fully paid') then 'Finalised'
	 when  [Claim Status2] in ('Rejected') then 'Rejected'
end [Claim Status3],
[CIT_TransactionTypeDescription],
[Policy Currency Claim currency],
[Claimant Type],
[Claimant Gender]


into #finalClaims2


from  #finalClaims


where 1=1
 --  and  [TransAge] is not null
 --and [Claim Status2] is null


 select
 case when [Claim Status3] not in('Finalised') then null  
      when [Claim Status3] in ('Finalised') and [ClaimAmountPaid] =0  then null else  [PaymentDate] end	[Claim paid date],
[Claim Date Reported]  	[Claim report date],
[Date of Loss]  	[Claim incurrred date],
[Risk Type3]  	[Claim description],
[CIC_Description]  	[Benefit/Claim type],
[CLB_PlanName],
[Claim Status3]  	[Claim status],
[Policy Number]  	[Policy number],
[Claim Number]  	[Benefit number],
[RaisedClaimAmount]  	[ClaimAmount],
[RejectionDate]  	[Claim rejection date],
[ClaimAmountPaid]  	[Paid],
[Claimant Type]  	[Life assured type]



into #finalClaims3




 from #finalClaims2


 --where CIS_Description like '%Refund%'


--order by [Claim Date Reported]

-----------------------------------------------------------------------------------------------------------------------------------

select 
eomonth([Claim report date]) MTHD,
POL_OriginalStartDate,
[Claim paid date]	,
[Claim report date]	,
[Claim incurrred date]	,
[Claim rejection date]	,
[Claim description]	,
[Benefit/Claim type]	,
[CLB_PlanName],
[RFH_Description] FinanceHouse,
case when agt_vatnumber in ('4720273004','4690202181','4420175020','4520193881') then 'Telesales'
else 'POS' end SalesChannel,
[Claim status]	,
[Policy number]	,
[Benefit number]	,
[ClaimAmount]	,
[Paid]	,
ClaimAmount + Paid Outstanding,
[Life assured type]
,case when [RPM_Description] in ('Bulked','Bordereaux','EDI') then 'Bulked' else 'Debit Order' end PaymentMethod,
[RCC_GLCode] CellCaptive,[RCC_Description],
case when [Product_Id] IN ('DDDC2DA4-881F-40B9-A156-8B7EA881863A','D0A30440-6F96-4735-A841-F601504BE51C',
						    '436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18',
							'77C92C34-0CBB-4554-BD41-01F2D8F5FC11','86E44060-B546-4A65-9464-9C4F78C1681E',
							'1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB') 
							and  POL_SoldDate>='2022-10-01' 
then 1 
when [Product_Id] IN ('DDDC2DA4-881F-40B9-A156-8B7EA881863A','D0A30440-6F96-4735-A841-F601504BE51C',
						    '436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18',
							'77C92C34-0CBB-4554-BD41-01F2D8F5FC11','86E44060-B546-4A65-9464-9C4F78C1681E',
							'1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB') 
							and  POL_SoldDate<'2022-10-01'
then 0 Else 0 end NewRateInd


into #finalClaims4

--select distinct *  

from #finalClaims3 f

 inner join [Evolve].[dbo].Policy on [Policy number] = POL_PolicyNumber
 left join [Evolve].[dbo].ReferenceFinanceHouse on ReferenceFinanceHouse_ID = POL_FinanceHouse_ID   
 left join [Evolve].[dbo].ReferencePaymentMethod on ReferencePaymentMethod_ID = POL_PaymentMethod_ID
 left join [Evolve].[dbo].[Product] on [Product_Id] = POL_Product_ID 
 left join [Evolve].[dbo].Agent on POL_Agent_ID = Agent_Id
 left join (select distinct [PolicyId],[CellCaptiveId] from  [Evolve].[dbo].vw_PolicySetDetails) p  on Policy_ID = p.PolicyId
 left join [Evolve].[dbo].[ReferenceCellCaptive] on [ReferenceCellCaptive_Code] = CellCaptiveId


where 1=1 
and [Claim status] not in ('Rejected','Abandoned')
and ClaimAmount <>0 and	Paid <> 0 
--Or [Policy number] in (select [CIS_PolicyNumber] from [Evolve].[dbo].[ClaimItemSummary] inner join Policy on
--                        [CIS_PolicyNumber] = POL_PolicyNumber where POL_Product_ID in(Select * from #Products)
--						and  
--and [Benefit number] like 'HADC015351CLM%'  

      

---------------------------------------------------------------------------------------------------------------------------------------------





--RESULTS					  
--=====================================================================================================================

select 
[Policy number],
[Benefit number],
[MTHD],
POL_OriginalStartDate,
--[Claim paid date],
[Claim report date],
--[Claim incurrred date],
--[Claim rejection date],
--[Claim description],
[Benefit/Claim type],
--[FinanceHouse],
--[SalesChannel],
--[Claim status],
[ClaimAmount],
--[Paid],
--[Outstanding],
--[Life assured type],
--[PaymentMethod],
[CellCaptive],
--[RCC_Description],
[NewRateInd]



from #finalClaims4

where 1=1
and [CellCaptive] in( 'WAMP',
					  'WAMT',
					  'WIAP',
					  'WIAT',
					  'WAPP',
					  'WAPT',
					  'WESP',
					  'WESB')
--and MTHD >='2024/12/01'

--and [Policy number] = 'HADC112834POL'


order by [Claim report date]





--==========================================================================================================================