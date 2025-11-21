Use Evolve
--Lifestyle Protection Plam
 
 drop table if exists #pol;
 drop table if exists #pol2

--Declare varibles
--#####################################################################################
DECLARE @val_Date AS DATETIME2 = '2025-10-31 23:59:59.999'
--#####################################################################################

SELECT				POL_PolicyNumber [Policy Number]
					,Policy_id [Policy ID]
					,PRD_Name [Product]
					, RTF_Description [Term]
					,cast(POL_OriginalStartDate as date) as [Start Date]
					,cast(case 
							when Pol_MaturityDate > DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) 
								then Pol_MaturityDate 
							else DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) 
					end as date) [End Date]
					,POL_Status [Policy Status]
INTO				#POL
FROM				Policy,Product,ReferenceTermFrequency
WHERE				POL_Product_ID = Product_Id
					AND TermFrequency_Id = POL_ProductTerm_ID
					AND POL_Deleted = 0
					AND POL_OriginalStartDate <= @val_Date
					AND (case when Pol_MaturityDate > DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) then Pol_MaturityDate else DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) end  >= @val_Date or POL_ProductTerm_ID = 4)
					AND Product_Id in ('22D1B06F-BE25-4FA4-AAD4-447F13E13728','83A65AC4-37EC-4776-959D-99D46D0A2A10','DF78BA49-F342-4745-B3B9-39F21430EB24')
					AND POL_ReceivedDate <= @val_Date;

--- JOIN TABLE WITH EVENTLOG
Select distinct		[Policy Number], 
					Product,
					Term, 
					[Start Date],
					[End Date],
					[Policy Status],
					el.EVL_Event_ID,
					el.EVL_DateTime,
					el.EVL_Description
Into				#pol2
From				Eventlog el
left join			#pol p
on					el.EVL_ReferenceNumber = p.[Policy ID]
Where				el.EVL_Event_ID in (10514, 10516, 10733, 10292, 10515)

--- Update table so that results not affected by entries and exits after valuation date
Update				#pol2
set					[Policy Status] = 1 
where				EVL_Event_ID = 10516
and					EVL_DateTime > @val_Date

-- GET RESULTS
SELECT  distinct	[Policy Number], 
					Product,
					Term, 
					[Start Date],
					[End Date],
					[Policy Status]
From				#pol2
WHERE				[Policy Status] = 1
					AND [POLICY NUMBER] IS NOT NULL


					 
 drop table if exists #pol;
 drop table if exists #pol2;
 
