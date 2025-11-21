-- Run time 03:21:00

Use Deloitte
GO


--Declare Variables
Declare					@valuationStart date,
						@valuationEnd date;

-- Assign values to variables
Set						@valuationEnd = cast('2025-08-31' as date);
Set						@valuationStart = EOMONTH((select dateadd(month,-25,DATEADD(month, DATEDIFF(month, 0, @valuationEnd), 0))))--'2019/01/01'


--Clear Previous Result (dropping previous tables that you are going to be replacing with new values or updating )
Drop table if exists	VapsPolInfo;
Drop table if exists	#MTH;
Drop table if exists	#EL;
Drop table if exists	#Pol;
Drop table if exists	#el;
Drop table if exists	#el2;
Drop table if exists	#policies;
Drop table if exists	#elMapping;
Drop table if exists	#applicable;
Drop table if exists	#el3;
Drop table if exists	#el4;
Drop table if exists	#el5;
Drop table if exists	#el6;
Drop table if exists	#el7;
Drop table if exists	#el8;
Drop table if exists	#el9;
Drop table if exists	#el10;
Drop table if exists	#el11;
Drop table if exists	#el12;
Drop table if exists	#el13;
Drop table if exists	#el14;
Drop table if exists	#el15;
Drop table if exists	#el16;
Drop table if exists	#el17;
Drop table if exists	#Premiums;
Drop table if exists	#Products;
Drop table if exists	#ProPlanOption;
Drop table if exists    #Recons;

--select * from PolNgo

-- Create an event log code mapping table+

Create table			#elMapping (
						Code int,
						ID int);
Insert into				#elMapping (Code, ID) values (10292, 1); -- Policy created, for migration
Insert into				#elMapping (Code, ID) values (10516, 0); -- Cover ended
Insert into				#elMapping (Code, ID) values (10514, 1); -- Policy accepted
Insert into				#elMapping (Code, ID) values (10733, 1); -- Policy reinstated
Insert into				#elMapping (Code, ID) values (10515, 0); -- Not taken up 

--Create Table Containing Month-end Date
With cte As				(
Select					DATEADD(month, DATEDIFF(month, 0, @valuationStart), 0) MTH
						, EOMONTH(DATEADD(month, DATEDIFF(month, 0, @valuationStart), 0)) ME
Union all
Select					DATEADD(Month, 1, cte.MTH) MTH, EOMONTH(DATEADD(Month, 1, cte.MTH)) ME
From					cte
Where					EOMONTH(DATEADD(Month, 1, cte.MTH)) <= @valuationEnd
						)
Select					*
Into					#MTH
From					cte 
Option					(Maxrecursion 500);
--############################################################################################################################################


CREATE TABLE #Products (ProductID Varchar(50));




INSERT INTO #Products VALUES ('83A65AC4-37EC-4776-959D-99D46D0A2A10'); --LPP Hollard
INSERT INTO #Products VALUES ('DF78BA49-F342-4745-B3B9-39F21430EB24'); --LPP Centriq
INSERT INTO #Products VALUES ('DDDC2DA4-881F-40B9-A156-8B7EA881863A');  --Adcover (H)
INSERT INTO #Products VALUES ('D0A30440-6F96-4735-A841-F601504BE51C');  --Vehicle Value Protector(Adcover)(H)
INSERT INTO #Products VALUES ('436BB1D0-CB35-4FF0-BD50-A316A08AE87B');  --Adcover (H)
INSERT INTO #Products VALUES ('70292F27-B7EE-4274-8B51-E345F4C1AD18');  --Adcover & Deposit Cover Combo (Q)
INSERT INTO #Products VALUES ('77C92C34-0CBB-4554-BD41-01F2D8F5FC11');  --Vehicle Value Protector(Adcover)(Q)
INSERT INTO #Products VALUES ('86E44060-B546-4A65-9464-9C4F78C1681E');  --Adcover & Deposit Cover Combo (H)
INSERT INTO #Products VALUES ('1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB');   --Deposit Cover (H)
INSERT INTO #Products VALUES ('5557806D-8733-458E-969A-9134F37C77D2');   --Auto Pedigree Plus Plan with Deposit Cover yearly
INSERT INTO #Products VALUES ('A80549F3-E47F-44C1-8037-F065522A03F6');   --Deposit Cover (Q)
INSERT INTO #Products VALUES ('529AFE28-A2BF-4841-9B56-F334660C6CBD');   --Paint Tech (H)
INSERT INTO #Products VALUES ('A68AD927-C8B3-47A1-909E-785BDB017377');   --Paint Tech (Q)


--INSERT INTO #Products VALUES ('01A81AE2-8478-45FB-8C0D-5A6E796C1B39');   --Tyre and Rim
--INSERT INTO #Products VALUES ('20AA9350-3FD9-4FE7-B705-3E1CCD639F94');   --Scratch and Dent

--INSERT INTO #Products VALUES ('219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF');  -- Warranty


---------------------------------------------------------------------------------------------------------------------------------------------------

select  distinct POL_PolicyNumber,  [ITS_Premium] 


into #Premiums

FROM [Evolve].[dbo].[ItemSummary]

  left join [Evolve].[dbo].policy on ITS_Policy_ID = Policy_ID

  where POL_Product_ID in (select * from #Products
						   )
						--   and POL_PolicyNumber = 'HCLL038811POL' 
						   and ITS_ItemType_ID = 9
						   and ITS_Deleted = 0

------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT distinct [POL_PolicyNumber]
      
	  ,[PRP_PlanName]
	 
  into #ProPlanOption

  FROM [Evolve].[dbo].[ItemSummary]

  left join [Evolve].[dbo].[Policy] on [ITS_Policy_ID] = Policy_ID
  left join [Evolve].[dbo].[PolicyCreditLifeItem] on [PolicyCreditLifeItem_ID] = ITS_Item_ID
  left join [Evolve].[dbo].[ReferenceTermFrequency] on [POL_ProductTerm_ID] = [TermFrequency_Id]
  left join [Evolve].[dbo].[ProductPlans] on [ProductPlans_Id] = [PCI_Plan_ID]
  left join [Evolve].[dbo].[ProductSection] on [ProductSection_Id] = [PCI_Section_ID]
  where 1=1
        and  POL_Product_ID in (select * from #Products
						   )
       	and ITS_ItemType_ID = 9
		and ITS_Deleted = 0






--########################################################################################################################################

-- Get policies for the valuation
Select					v.*
						, POL_IsMigrated
						, POL_CreateDate
						,[POL_GeneratedPolicyNumber] 
						,[POL_OriginalStartDate]
						,POL_EndDate POL_EndDateO
						,[POL_FinanceTerm_ID]
						,POL_Status
						,CASE
						WHEN v.ProductId IN ('DDDC2DA4-881F-40B9-A156-8B7EA881863A','D0A30440-6F96-4735-A841-F601504BE51C', '436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18','77C92C34-0CBB-4554-BD41-01F2D8F5FC11','86E44060-B546-4A65-9464-9C4F78C1681E') THEN 'Adcover'
						WHEN v.ProductId IN ('22D1B06F-BE25-4FA4-AAD4-447F13E13728','83A65AC4-37EC-4776-959D-99D46D0A2A10','DF78BA49-F342-4745-B3B9-39F21430EB24') THEN 'Lifestyle Protection Plan'
						WHEN v.ProductId IN ('529AFE28-A2BF-4841-9B56-F334660C6CBD','A68AD927-C8B3-47A1-909E-785BDB017377') THEN 'Paint Tech'
						WHEN v.ProductId IN ('A4AF17CF-89D0-47AC-A447-F135310042D7') THEN 'Discovery Warranty'
						WHEN v.ProductId IN ('1CD1AFBF-D6B4-4265-ADEF-56EC8B3186CB', '5557806D-8733-458E-969A-9134F37C77D2', 'A80549F3-E47F-44C1-8037-F065522A03F6') then 'Deposit Cover'
						WHEN v.ProductId IN ('83C026A9-17FF-4A87-9CA9-E82C2535B538' ) and v.InsurerId='28BEBA82-5AD3-49A7-A9F0-714542B6B2A8'  then 'Santam'
						WHEN v.ProductId IN ('83C026A9-17FF-4A87-9CA9-E82C2535B538' ) and v.InsurerId='0F2B8071-42D3-4150-A25E-F58576321AF3'  then 'OMI'
						WHEN v.ProductID IN ('219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF') THEN 'Warranty'
						WHEN v.ProductID IN ('01A81AE2-8478-45FB-8C0D-5A6E796C1B39') THEN 'Tyre And Rim'
						WHEN v.ProductID IN ('20AA9350-3FD9-4FE7-B705-3E1CCD639F94') THEN 'Scratch And Dent'
						Else NULL
						END Product
						,[PRD_Name],[RCC_GLCode] CellCaptive,[PREMIUM],[Evolve].[dbo].CalculateCommission(PolicyId) Commission, 
						[PREMIUM]*0.0325 ComPer,

						case when v.ProductId IN ('DDDC2DA4-881F-40B9-A156-8B7EA881863A','D0A30440-6F96-4735-A841-F601504BE51C',
						                          '436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18',
												  '77C92C34-0CBB-4554-BD41-01F2D8F5FC11','86E44060-B546-4A65-9464-9C4F78C1681E') 
												  and  POL_SoldDate>='2022-10-01' 
                        then 1 
						when v.ProductId IN ('DDDC2DA4-881F-40B9-A156-8B7EA881863A','D0A30440-6F96-4735-A841-F601504BE51C',
						                          '436BB1D0-CB35-4FF0-BD50-A316A08AE87B','70292F27-B7EE-4274-8B51-E345F4C1AD18',
												  '77C92C34-0CBB-4554-BD41-01F2D8F5FC11','86E44060-B546-4A65-9464-9C4F78C1681E') 
												  and  POL_SoldDate<'2022-10-01'
                       then 0 Else null end NewRateInd,

						case when agt_vatnumber in ('4720273004','4690202181','4420175020','4520193881') then 'Telesales'
						else 'POS' end SalesChannel,[RFH_Description] FinanceHouse,
						case when [RPM_Description] in ('Bulked','Bordereaux','EDI') 
						     then 'Bulked' else 'Debit Order' end PaymentMethod,

						case	when Agt_VATNumber = '4720273004' then 'Motor Happy'
				                when Agt_VATNumber = '4520193881' then 'Liquid Capital'
				                when Agt_VATNumber = '4690202181' then 'M-Sure Telesales'
								when Agt_VATNumber = '4420175020' then 'TMS' end Telesales ,

								[RTF_Description],
								[RTF_TermPeriod]

				--TMS: 
							 
							 
							 


Into					#policies
From					[Evolve].[dbo].vw_PolicySetDetails v
						left join [Evolve].[dbo].Policy p on p.Policy_ID = v.PolicyId
						left join [Evolve].[dbo].[ReferenceCellCaptive] on [ReferenceCellCaptive_Code] = V.CellCaptiveId
						left join [Evolve].[dbo].Agent on p.POL_Agent_ID = Agent_Id
						left join [Evolve].[dbo].[vw_PolicyItemDetails] on [Policy_Item_id] = p.[Policy_ID]
						left join [Evolve].[dbo].ReferenceFinanceHouse on ReferenceFinanceHouse_ID = POL_FinanceHouse_ID   
                        left join [Evolve].[dbo].ReferencePaymentMethod on ReferencePaymentMethod_ID = POL_PaymentMethod_ID
						left join [Evolve].[dbo].[Product] on [Product_Id] = v.ProductId
						left join [Evolve].[dbo].[ReferenceTermFrequency] on POL_ProductTerm_ID = [TermFrequency_Id]
						
						where  v.ProductId  IN ( select * from #Products
												)

												--and  [PolicyNumber] = 'HCLL023269POL'
												--and dbo.CalculateCommission(PolicyId) = 0
												

						;
--########################################################################################################################################

						--select * from #policies where PolicyNumber ='QCLL010372POL'


-- Get the earliest policy accepted date  and last cancel date, if applicable
With f as				(-- Subquery to filter the product and underwriter of interest
Select					*
From					#policies
						),
a as					( --- Subquery for policy accepted date
Select					p.pol_policyNumber,
						p.Policy_ID,
						min(EVL_DateTime) MinPolAcceptedDate
From					[Evolve].[dbo].EventLog el
						inner join [Evolve].[dbo].policy p
						on p.policy_id = el.evl_ReferenceNumber
						inner join f
						on f.PolicyId  = p.policy_id
Where					el.EVL_Event_ID in (10514, 10733) -- Policy accepted date
Group by				p.pol_policyNumber,
						p.Policy_ID
						),
c as					( -- Subquery for the furthest cancel date, if applicable
Select					p.pol_policyNumber,
						p.Policy_ID,
						max(EVL_DateTime) MaxPolCancelDate
From					[Evolve].[dbo].EventLog el
						inner join [Evolve].[dbo].policy p
						on p.policy_id = el.evl_ReferenceNumber
						inner join f
						on f.PolicyId = p.Policy_ID
Where					el.EVL_Event_ID in (10516, 10515) -- Policy cancel date --Not taken up
Group by				p.pol_policyNumber,
						p.Policy_ID)
					    ,
r as					( -- Subquery for the furthest reinstated date, if applicable
Select					p.pol_policyNumber,
						p.Policy_ID,
						max(EVL_DateTime) MaxPolReinstatedDate
From					[Evolve].[dbo].EventLog el
						inner join [Evolve].[dbo].policy p
						on p.policy_id = el.evl_ReferenceNumber
						inner join f
						on f.PolicyId = p.Policy_ID
Where					el.EVL_Event_ID in (10733) -- Policy reinstated date (this is what makes graph c and r different)
Group by				p.pol_policyNumber,
						p.Policy_ID
						),
pol as					( -- Unique policy numbers
Select					pol_PolicyNumber,
						Policy_ID
From					a
Union
Select					pol_PolicyNumber,
						Policy_ID
From					c
Union
Select					pol_PolicyNumber,
						Policy_ID
From					r),
res as					(-- Subquery with the relevant dates
Select					pol.Pol_PolicyNumber,
						pol.Policy_ID,
						Case
							When a.MinPolAcceptedDate is null then DATEADD(month, DATEDIFF(month, 0, @valuationStart), 0)
							Else a.MinPolAcceptedDate
						End EntryDate,
						Case
							When c.MaxPolCancelDate < r.MaxPolReinstatedDate then Dateadd(day, 1, @valuationEnd)
							When c.MaxPolCancelDate is null then Dateadd(day, 1, @valuationEnd)
							Else c.MaxPolCancelDate
						End ExitDate,
						r.MaxPolReinstatedDate ReinstDate
From					pol
						left join a 
						on pol.POL_PolicyNumber = a.POL_PolicyNumber
						left join c
						on pol.POL_PolicyNumber = c.POL_PolicyNumber
						left join r
						on pol.POL_PolicyNumber = r.POL_PolicyNumber
						)
Select					*
Into					#pol
From					res;

---------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------



-- Merge with information from event log
Select			--*		
                       distinct p.*, 
						el.EVL_Event_ID,
						el.EVL_DateTime,
						el.EVL_Description
						,ELD_NewValue
Into					#el
From					[Evolve].[dbo].Eventlog el
						inner join #pol p
						on el.EVL_ReferenceNumber = p.Policy_ID
						left JOIN [Evolve].[dbo].EventLogDetail  ON EventLog_ID = ELD_EventLog_ID and ELD_NewValue <>''
						and ELD_NewValue is not null
						and ELD_Description not in ('Cancelation Comment','NTU Comment','Refund Rule',
						                            'Policy Personal Accident Item Accepted')
                        and ELD_NewValue not like '%-%-%-%-%'

Where					el.EVL_Event_ID in (10514, 10516, 10733, 10515)--;
                        --and ELD_NewValue <>'' and ELD_NewValue is not null 
						--and ELD_Description not in ('Cancelation Comment','Refund Rule')
						--and EventLogDetail_ID = (select min (EventLogDetail_ID) From Eventlog el inner join #pol p
						--on el.EVL_ReferenceNumber = p.Policy_ID left JOIN EventLogDetail  ON EventLog_ID = ELD_EventLog_ID 
						--and EVL_Event_ID in (10514, 10516, 10733, 10515) )
                       -- and POL_PolicyNumber ='HCLL034731POL'; --10733 is policy reinstated, 10514 is policy accepted, and 10516 is policy cancelled
 
 



-- Add ring fenced policies
Insert into				#el
Select					pol_policynumber,
						policy_ID,
						pol_createdate EntryDate,
						Dateadd(day, 1, @valuationEnd) ExitDate,
						NULL ReinstDate,
						10514 EVL_Event_ID,
						POL_CreateDate EVL_DateTime,
						'Policy Accepted' EVL_Description,
						Null ELD_NewValue

From					[Evolve].[dbo].policy 
Where					POL_PolicyNumber in ('QVVP000238POL',
						'QVVP000062POL',
						'QVVP000123POL',
						'QVVP000248POL',
						'QVVP000273POL',
						'QVVP000042POL',
						'QVVP000208POL',
						'QVVP000283POL',
						'QVVP000233POL',
						'QVVP000188POL',
						'QVVP000143POL',
						'QVVP000148POL',
						'QVVP000103POL')
						and pol_status = 1 

-- Add information about when the policy was migrated
Insert into				#el 
Select					p.PolicyNumber Pol_PolicyNumber,
						p.PolicyId Policy_ID,
						--p.CellCaptive,
					--	p.Product,
						p.POL_CreateDate EntryDate,
						(Select max(ExitDate) from #el e where e.Pol_PolicyNumber = p.PolicyNumber) ExitDate,
						(Select max(ReinstDate) from #el e where e.POL_PolicyNumber = p.PolicyNumber) ReinstDate,
						case 
						when p.pol_status = 6 then 10515 else 10292 end
						as EVL_Event_ID,
						p.POL_CreateDate EVL_DateTime,
						'Policy Migrated' as EVL_Description,
						null ELD_NewValue
From					#policies p
						inner join [Evolve].[dbo].policy on PolicyNumber = POL_PolicyNumber 
Where					p.POL_IsMigrated = 1;

-- Create index for efficiency
Create index i on		#el (Pol_PolicyNumber, Policy_ID);

--select top(10) * from #pol
-- Update EVL_DateTime to ensure that it is not less the EntryDate for a policy accepted record 
Update					#el 
Set						EntryDate = p.pol_createdate
From					[Evolve].[dbo].policy p
						--inner join eventlog e
where				    p.pol_policynumber = #el.pol_policynumber
and 					EVL_DateTime < EntryDate;

-- Update
Update					#el
Set						ExitDate = Dateadd(day, 1, @valuationEnd)
Where					EVL_Event_ID = 10514
						and ExitDate < EVL_DateTime
						and POL_PolicyNumber in (select POL_PolicyNumber from [Evolve].[dbo].policy 
						where pol_status = 1);

-- Chop off the incorrectly migrated policies with a prefix x.
Delete from				#el
Where					lower(Pol_PolicyNumber) like 'x%';


-- Update the entry date of policies 
With e as				(
Select					e.Pol_PolicyNumber,
						e.Policy_ID,
						min(e.EntryDate) EntryDate
From					#el e
Group by				e.POL_PolicyNumber,
						e.Policy_ID)

Select					el.Pol_PolicyNumber,
						el.Policy_ID,
						Iif(el.EntryDate > e.EntryDate, e.EntryDate, el.EntryDate) EntryDate,
						el.ExitDate,
						el.ReinstDate,
						el.EVL_Event_ID,
						el.EVL_DateTime,
						el.EVL_Description,
						el.ELD_NewValue
Into					#el2
From					#el el
						left join e
						on e.Policy_ID = el.Policy_ID
						
					--	where e.POL_PolicyNumber = 'HCLL007577POL'

						--select * from #el where POL_PolicyNumber = 'HCLL007577POL'

						;



-- Get applicable policies at the end of each valuation month 
Select					#el2.*,
						#mth.MTH,
						#mth.ME, 
						case 
						when DATEADD(month, DATEDIFF(month, 0, EntryDate), 0) = #mth.MTH and DATEADD(month, DATEDIFF(month, 0, pol_originalstartdate), 0) <= #mth.MTH then 1 else 0 
						end ActivationsNewBus,
						case
						when DATEADD(month, DATEDIFF(month, 0, EntryDate), 0) < #mth.MTH and DATEADD(month, DATEDIFF(month, 0, pol_originalstartdate), 0) = #mth.MTH then 1 else 0 
						end ActivationsExistingBus,
						case
						when DATEADD(month, DATEDIFF(month, 0, ReinstDate), 0) = #mth.MTH then 1 else 0
						end Reinst
Into					#el3
From					#el2
						cross join #mth
						left join [Evolve].[dbo].policy p 
						on p.POL_PolicyNumber = #el2.POL_PolicyNumber
Where					cast(Eomonth(ExitDate) as date) >= cast(#mth.ME as date) 
						OR (ExitDate is null and EVL_Description ='Policy Migrated');

-----------------------------------------------------------------------------------------------------------------------------------------------
Select					MTH,
						ME,
						Pol_PolicyNumber,
						Policy_ID,
						max(EVL_DateTime) EVL_DateTime,
						ActivationsNewBus,
						ActivationsExistingBus,
						Reinst
Into					#el4
From					#el3
Where					cast(EVL_DateTime as date) <= cast(ME as date)
Group by				MTH,
						ME,
						Pol_PolicyNumber,
						Policy_ID,
						ActivationsNewBus,
						ActivationsExistingBus,
						Reinst;

------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Add Event log ID applicable for timestamp
Create index a1	on		#el2(Pol_PolicyNumber, EVL_DateTime);
Create index a2 on		#el4(Pol_PolicyNumber, EVL_DateTime);
Select					#el4.*,
						e.EVL_Event_ID LastEventLogID,
						e.EVL_Description LastEventLogAction,
						e.ELD_NewValue,
						m.ID * iif(#el4.me >= p.pol_originalstartdate, 1, 0) Active 
Into					#el5
From					#el4 
						left join #el2 e
						on #el4.Pol_PolicyNumber = e.Pol_PolicyNumber
						and #el4.EVL_DateTime = e.EVL_DateTime
						left join #elMapping m
						on m.Code = e.EVL_Event_ID
						inner join [Evolve].[dbo].policy p 
						on p.POL_PolicyNumber = #el4.Pol_PolicyNumber
						
						--where #el4.POL_PolicyNumber = 'HCLL007577POL'

						--select * from #el2 where POL_PolicyNumber = 'HCLL007577POL' order by mth


--------------------------------------------------------------------------------------------------------------------------------------------					
select distinct el.*,
		p.CellCaptive,
		p.SalesChannel,
		p.[PREMIUM],
		p.Commission,
		p.ComPer,
		p.NewRateInd,
		p.FinanceHouse,
		p.PaymentMethod,
		p.Telesales,
		p.[RTF_Description],
		p.[RTF_TermPeriod],
		p.[POL_GeneratedPolicyNumber] ,
		p.PolicyId,
		p.[POL_OriginalStartDate],
		p.POL_EndDateO,
		p.[POL_FinanceTerm_ID],
		p.POL_Status,
		p.[PRD_Name],
		p.Product
into #el6
from #el5 el
	left join #policies p
	on el.POL_PolicyNumber=p.PolicyNumber;

-------------------------------------------------------------------------------------------------------------------------------



--SELECT * FROM  #policies

--PolicyId



---------------------------------------------------------------------------------------------------------------------------------------
select e.POL_PolicyNumber,
       mth,
	   cast (EOMONTH(mth) as datetime) mthd,EVL_DateTime,LastEventLogID,LastEventLogAction,ELD_NewValue,
	   product,[PRD_Name],case when LastEventLogID = 10516 then EVL_DateTime else null end EndDate,
	   Case when e.POL_PolicyNumber like 'H%' then 'Hollard' when e.POL_PolicyNumber like 'Q%' then 'Centriq' 
	   else Null End Insurer, CellCaptive,SalesChannel,Telesales,[RTF_Description],[RTF_TermPeriod],[PREMIUM],Commission,ComPer,NewRateInd,FinanceHouse,PaymentMethod,
	   [POL_GeneratedPolicyNumber],PolicyId ,[POL_OriginalStartDate],POL_EndDateO , [POL_FinanceTerm_ID],POL_Status,

	   

	   sum(active) ClosingCount,
	   case when e.POL_PolicyNumber like '%-%' then 0 else sum(ActivationsNewBus) end ActivationsNewBusiness,
	   case when e.POL_PolicyNumber like '%-%' then 0 else sum(ActivationsExistingBus) end ActivationsExistingBusiness,
	   case when e.POL_PolicyNumber like '%-%' then sum(ActivationsNewBus) + sum(ActivationsExistingBus) 
	   else sum(Reinst) end Reinstatements


	  into #el7

from   #el6 e

--left join [Evolve].[dbo].[Policy] p on p.POL_PolicyNumber = e.POL_PolicyNumber



where Product is not null

group by e.POL_PolicyNumber,mth, product,[PRD_Name], CellCaptive,SalesChannel,Telesales,[RTF_Description],[RTF_TermPeriod],[PREMIUM],Commission,ComPer,EVL_DateTime,
LastEventLogID,LastEventLogAction,ELD_NewValue,NewRateInd,FinanceHouse,PaymentMethod,[POL_GeneratedPolicyNumber] ,PolicyId,
[POL_OriginalStartDate],POL_EndDateO,[POL_FinanceTerm_ID],POL_Status
--order by Product, MTH desc ;

-----------------------------------------------------------------------------------------------------------------------------------------------------

select e.*,
           iif(datediff(day,POL_EndDateO,EndDate)>0,Eomonth(EndDate),POL_EndDateO) POL_EndDate ,
            
            case when ClosingCount + ActivationsNewBusiness + ActivationsExistingBusiness + Reinstatements =0 
			and POL_Status  =3 and EOMONTH (mthd) = EOMONTH (iif(datediff(day,POL_EndDateO,EndDate)>0,Eomonth(EndDate),
			POL_EndDateO)) then 1 when LastEventLogID = 10516 then 1 else 0 end exits

			into #el8

from #el7 e

--left join Policy p on e.POL_PolicyNumber = p.POL_PolicyNumber

where 1=1 
--and ClosingCount =0
and POL_Status  in(1,3)
--and POL_Status  = 1
--order by mth
--group by mth,Insurer
--order by mth,Insurer

----------------------------------------------------------------------------------------------------------------------------------------------------

select POL_PolicyNumber	,
       [POL_GeneratedPolicyNumber],
	   PolicyId,
		mth	,
		mthd	,
		EVL_DateTime	,
		LastEventLogID	,
		LastEventLogAction,
		ELD_NewValue,
		product	,
		[PRD_Name],
		[POL_OriginalStartDate],
		[POL_FinanceTerm_ID],
		EndDate	,
		Insurer	,
		CellCaptive	,
		SalesChannel,
		Telesales,
		[RTF_Description],
		[RTF_TermPeriod],
		[PREMIUM],
		Commission,
		ComPer,
		NewRateInd,
		FinanceHouse,
		PaymentMethod,
		ClosingCount	,
		ActivationsNewBusiness	,
		case when ClosingCount = 1 
		          and ActivationsNewBusiness =0 and ActivationsExistingBusiness = 0 
		          and (case when ActivationsNewBusiness = 1 then 0 else  Reinstatements end) = 0  
				  and (select ClosingCount 
				         from #el8  
						 where POL_PolicyNumber = e.POL_PolicyNumber and Mth =  DATEADD(MONTH,-1,e.Mth)) = 0
		     then 1 
			 else ActivationsExistingBusiness end ActivationsExistingBusiness	,
		case when ActivationsNewBusiness = 1 then 0 else  Reinstatements end Reinstatements	,

		POL_EndDate	,
		POL_Status	,
		exits	
 
        , (select TOP 1 ClosingCount from #el8 where POL_PolicyNumber = e.POL_PolicyNumber and Mth =  DATEADD(MONTH,-1,e.Mth))
         OpeningCount

into #el9 

from #el8 e

where 1=1
--and POL_PolicyNumber = 'HCLL007577POL'

--select POL_PolicyNumber,Mth, count(*) N from #el8 group by Mth,POL_PolicyNumber having count(*) >1
--select * from #el5 where 1=1 and POL_PolicyNumber = 'HCLL007577POL'order by Mth and LastEventLogID = 10516 order by Mth


-------------------------------------------------------------------------------------------------------------------------------
select      POL_PolicyNumber	,
            [POL_GeneratedPolicyNumber],
			PolicyId,
			mth	,
			mthd	,
			EVL_DateTime	,
			LastEventLogID	,
			LastEventLogAction,
			ELD_NewValue,
			product	,
			[PRD_Name],
			[POL_OriginalStartDate],
			[POL_FinanceTerm_ID],
			EndDate	,
			Insurer	,
			CellCaptive	,
			SalesChannel,
			Telesales,
			[RTF_Description],
			[RTF_TermPeriod],
			[PREMIUM],
			Commission,
			ComPer,
			NewRateInd,
			FinanceHouse,
		    PaymentMethod,
			ClosingCount	,
			ActivationsNewBusiness	,
			ActivationsExistingBusiness	,
			case when OpeningCount = 1 or ActivationsExistingBusiness=1 then 0 
			when ClosingCount=1 and OpeningCount = 0 and ActivationsNewBusiness = 0 and ActivationsExistingBusiness = 0
			and LastEventLogID = 10733 then 1  else Reinstatements end Reinstatements	,
			POL_EndDate	,
			POL_Status	,
			case when OpeningCount = 0 or OpeningCount is null  then 0 else exits end exits	,

			case when ActivationsNewBusiness =1 or ActivationsExistingBusiness =1 or 
			(case when OpeningCount = 1 or ActivationsExistingBusiness=1 then 0 when ClosingCount=1 and OpeningCount = 0 
			and ActivationsNewBusiness = 0 and ActivationsExistingBusiness = 0 and LastEventLogID = 10733 then 1  else 
			Reinstatements end) = 1
			
			then 0 else OpeningCount end OpeningCount,


            case when ActivationsNewBusiness =1 or ActivationsExistingBusiness =1 or 
			          (case when OpeningCount = 1 or ActivationsExistingBusiness=1 then 0 
					        when ClosingCount=1 and OpeningCount = 0 and ActivationsNewBusiness = 0 
							     and ActivationsExistingBusiness = 0 and LastEventLogID = 10733 then 1  
						    else Reinstatements end) = 1 
				 then 0 
				 else OpeningCount end +
			case when ClosingCount=0 then 0 
			     else (ActivationsNewBusiness + ActivationsExistingBusiness 

						+ case when OpeningCount = 1 or ActivationsExistingBusiness = 1 then 0 
						  when ClosingCount=1 and OpeningCount = 0 and ActivationsNewBusiness = 0 
							   and ActivationsExistingBusiness = 0 and LastEventLogID = 10733 then 1  
							   else Reinstatements end)	   
			end 
			- (case when OpeningCount = 0 or OpeningCount is null  then 0 else exits end)  Recon

into #el10 

from #el9 e

-----------------------------------------------------------------------------------------------------------------------------------
--Remove unwanted rows
--------------------------------------------------------------------------------------------------------------------------------------------------
select * 

into #el11

from #el10

where 

  exits <> 0 or OpeningCount <> 0 or ClosingCount <> 0 
 ---------------------------------------------------------------------------------------------------------------------------------

 select POL_PolicyNumber	,
		POL_GeneratedPolicyNumber	,
		PolicyId,
		mth	,
		mthd	,
		EVL_DateTime	,
		LastEventLogID	,
		LastEventLogAction,
		ELD_NewValue,
		product	,
		[PRD_Name],
		POL_OriginalStartDate	,
		[POL_FinanceTerm_ID],
		EndDate	,
		Insurer	,
		CellCaptive	,
		SalesChannel,
		Telesales,
		[RTF_Description],
		[RTF_TermPeriod],
		[PREMIUM],
		Commission,
		ComPer,
		NewRateInd,
		FinanceHouse,
		PaymentMethod,
        ClosingCount	,
		ActivationsNewBusiness	,
		ActivationsExistingBusiness	,
		Reinstatements	,
		POL_EndDate	,
		POL_Status	,
		exits	,
		(select Sum(OpeningCount) 
           from #el11 
		  where 1=1 
               and e.[POL_GeneratedPolicyNumber] = [POL_GeneratedPolicyNumber] 
               and e.mth = mth
		 Group by [POL_GeneratedPolicyNumber]) OpeningCount,

		Recon	,
 
       (select count([POL_GeneratedPolicyNumber]) 
          from #el11 
		 where 1=1 
               and e.[POL_GeneratedPolicyNumber] = [POL_GeneratedPolicyNumber] 
               and e.mth = mth) VersionCounts

into #el12


from #el11 e

----------------------------------------------------------------------------------------------------------------------------------------
select  POL_PolicyNumber	,
		POL_GeneratedPolicyNumber	,
		PolicyId,
		mth	,
		mthd	,
		EVL_DateTime	,
		LastEventLogID	,
		LastEventLogAction,
		ELD_NewValue,
		case when LastEventLogID = 10516 then isnull(ELD_NewValue,LastEventLogAction) else null end CancelationReason,
		product	,
		[PRD_Name],
		POL_OriginalStartDate	,
		[POL_FinanceTerm_ID],
		eomonth(dateadd(month,[POL_FinanceTerm_ID],[POL_OriginalStartDate])) CalEndDateofTerm,
		EndDate	,
		Insurer	,
		CellCaptive	,
		SalesChannel,
		Telesales,
		[RTF_Description],
		[RTF_TermPeriod],
		[PREMIUM],
		Commission,
		ComPer,
		NewRateInd,
		FinanceHouse,
		PaymentMethod,
		ClosingCount	,
		ActivationsNewBusiness	,
		ActivationsExistingBusiness	,
		case when OpeningCount =1 then 0 else Reinstatements	end Reinstatements	,
		POL_EndDate	,
		POL_Status	,
		exits	,
		OpeningCount	,
		Recon	,
		case when ClosingCount =1 then 1 else VersionCounts end VersionCounts

into #el13

		from #el12

		where (case when ClosingCount =1 then 1 else VersionCounts end) = 1
-----------------------------------------------------------------------------------------------------------------------------
SELECT
  e.POL_PolicyNumber,
  e.POL_GeneratedPolicyNumber,
  e.PolicyId,
  e.mth,
  e.mthd,
  e.EVL_DateTime,
  e.LastEventLogID,
  e.LastEventLogAction,
  e.ELD_NewValue,
  e.CancelationReason,
  e.product,
  e.PRD_Name,
  e.POL_OriginalStartDate,
  e.POL_FinanceTerm_ID,
  e.EndDate,
  e.Insurer,
  e.CellCaptive,
  e.SalesChannel,
  e.Telesales,
  e.RTF_Description,
  e.RTF_TermPeriod,
  e.PREMIUM,
  e.Commission,
  e.ComPer,
  e.NewRateInd,
  e.FinanceHouse,
  e.PaymentMethod,
  e.ClosingCount,
  e.ActivationsNewBusiness,
  e.ActivationsExistingBusiness,
  e.Reinstatements,
  e.POL_EndDate,
  e.POL_Status,
  e.exits,
  e.OpeningCount,
  e.Recon,
  e.VersionCounts -- explicitly include the VersionCounts column from #el13
INTO #el14
FROM #el13 e
WHERE (
  CASE 
    WHEN (
      SELECT COUNT_BIG([POL_GeneratedPolicyNumber]) 
      FROM #el13 
      WHERE [POL_GeneratedPolicyNumber] = e.[POL_GeneratedPolicyNumber] 
        AND mth = e.mth
    ) = 2 AND ClosingCount = 1 AND POL_PolicyNumber LIKE '%-%'
    THEN 1
    ELSE (
      SELECT COUNT_BIG([POL_GeneratedPolicyNumber]) 
      FROM #el13 
      WHERE [POL_GeneratedPolicyNumber] = e.[POL_GeneratedPolicyNumber] 
        AND mth = e.mth
    )
  END
) = 1;


					--and POL_PolicyNumber like 'HCLL006042POL%' order by MTH 



---------------------------------------------------------------------------------------------------------------------------------------
SELECT
  e.*,
  ISNULL(p.[PRP_PlanName], NULL) AS [PRP_PlanName],
  CASE 
    WHEN e.[PREMIUM] = 0 THEN ISNULL(prem.ITS_Premium, 0)
    ELSE e.[PREMIUM]
  END AS [PREMIUM_SAFE]
INTO #el15
FROM #el14 e
LEFT JOIN #ProPlanOption p ON p.POL_PolicyNumber = e.POL_PolicyNumber
OUTER APPLY (
  SELECT TOP 1 ITS_Premium 
  FROM #Premiums p2 
  WHERE p2.POL_PolicyNumber = e.POL_PolicyNumber
) prem;



--Add Disbursement
------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
  POL_PolicyNumber,
  POL_GeneratedPolicyNumber,
  PolicyId,
  mth,
  mthd,
  EVL_DateTime,
  LastEventLogID,
  LastEventLogAction,
  ELD_NewValue,
  CancelationReason,
  product,
  PRD_Name,
  POL_OriginalStartDate,
  EndDate,
  Insurer,
  CellCaptive,
  SalesChannel,
  Telesales,
  [RTF_Description],
  [RTF_TermPeriod],
  PREMIUM,
  CASE 
    WHEN PRD_Name = 'Auto Pedigree Plus Plan with Deposit Cover'
      THEN [PREMIUM] * (
        SELECT TOP 1 [PSL_CommissionPercentage] 
        FROM [Evolve].[dbo].[ProductSectionLink] 
        WHERE [PSL_ProductID] = '5557806D-8733-458E-969A-9134F37C77D2'
      ) / 100
    ELSE [Commission]
  END AS [Commission],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 1, ''), 0) * PREMIUM / 100 AS [Binder Fee - Cat A],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 2, ''), 0) * PREMIUM / 100 AS [Binder Fee - Cat B],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 3, ''), 0) * PREMIUM / 100 AS [Binder Fee - Cat C],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 4, ''), 0) * PREMIUM / 100 AS [Binder Fee - Cat D],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 5, ''), 0) * PREMIUM / 100 AS [Binder Fee - Cat E],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 6, ''), 0) * PREMIUM / 100 AS [Insurer Fee],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 7, ''), 0) * PREMIUM / 100 AS [Outsource Fee],
  ISNULL([Evolve].[dbo].fnc_GetFinanceCentralValue(PolicyId, mthd, 18, '7991CC5D-715C-4615-8B17-3FC52A78299A'), 0) AS [PremiumInputFixedFactor],
  NewRateInd,
  FinanceHouse,
  PaymentMethod,
  DATEDIFF(day, POL_OriginalStartDate, EndDate) AS Exposure,
  ClosingCount,
  ActivationsNewBusiness,
  ActivationsExistingBusiness,
   CASE 
        WHEN POL_OriginalStartDate >= '2024-06-01' THEN 1  -- Adjust the date as per your requirement
        ELSE 0 
    END AS NewBusiness,
  Reinstatements,
  POL_EndDate,
  POL_Status,
  exits,
  OpeningCount,
  Recon,
  VersionCounts,
  PRP_PlanName
INTO #el16
FROM #el15;


----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
  [POL_PolicyNumber],
  [POL_GeneratedPolicyNumber],
  [PolicyId],
  [mth],
  [mthd],
  [EVL_DateTime],
  [LastEventLogID],
  [LastEventLogAction],
  [ELD_NewValue],
  [CancelationReason],
  [product],
  [PRD_Name],
  [POL_OriginalStartDate],
  [EndDate],
  [Insurer],
  [CellCaptive],
  CASE WHEN [CellCaptive] IN ('APD','MST','MOT','OEM') THEN [CellCaptive] ELSE 'Non-Group' END AS CellGroup,
  [SalesChannel],
  Telesales,
  [RTF_Description],
  [RTF_TermPeriod],
  [PREMIUM]/[RTF_TermPeriod] AS [PREMIUM],
  [Commission]/[RTF_TermPeriod] AS [Commission],
  ([Binder Fee - Cat A] + [Binder Fee - Cat B] + [Binder Fee - Cat C] + [Binder Fee - Cat D] + [Binder Fee - Cat E]) / [RTF_TermPeriod] AS [Binder Fee],
  [Insurer Fee]/[RTF_TermPeriod] AS [Insurer Fee],
  [Outsource Fee]/[RTF_TermPeriod] AS [Outsource Fee],
  [PremiumInputFixedFactor],
  [NewRateInd],
  [FinanceHouse],
  [PaymentMethod],
  [Exposure],
  [ClosingCount],
  [ActivationsNewBusiness],
  [ActivationsExistingBusiness],
  [NewBusiness],
  [Reinstatements],
  [POL_EndDate],
  [POL_Status],
  [exits],
  [OpeningCount],
  [Recon],
  [VersionCounts],
  [PRP_PlanName]
INTO #el17
FROM #el16;

-----------------------------------------------------------------------------------------------------------------------------------------

--RESULTS					  
--=====================================================================================================================
	
-- Drop the table if it exists
DROP TABLE IF EXISTS [Deloitte].[dbo].[VapsPolInfo];	
	
	select *
	into [Deloitte].[dbo].[VapsPolInfo]
from #el17

--====================================================================================================================================
--Drop table if exists VapsPolInfo;

Drop table if exists	#MTH;
Drop table if exists	#EL;
Drop table if exists	#Pol;
Drop table if exists	#el;
Drop table if exists	#el2;
Drop table if exists	#policies;
Drop table if exists	#elMapping;
Drop table if exists	#applicable;
Drop table if exists	#el3;
Drop table if exists	#el4;
Drop table if exists	#el5;
Drop table if exists	#el6;
Drop table if exists	#el7;
Drop table if exists	#el8;
Drop table if exists	#el9;
Drop table if exists	#el10;
Drop table if exists	#el11;
Drop table if exists	#el12;
Drop table if exists	#el13;
Drop table if exists	#el14;
Drop table if exists	#el15;
Drop table if exists	#el16;
Drop table if exists	#el17;
Drop table if exists	#Premiums;
Drop table if exists	#Products;
Drop table if exists	#ProPlanOption;
Drop table if exists    #Recons;
