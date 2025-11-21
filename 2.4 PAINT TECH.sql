Use Evolve
-- PAINT TECH


 drop table if exists #pol;
 drop table if exists #pol2;

--DECLARE VARIABLES
--#####################################################################################
DECLARE @val_Date AS DATETIME2 = '2025-10-31 23:59:59.999'
--#####################################################################################

SELECT			POL_PolicyNumber [Policy Number]
				,Policy_id [Policy ID]
				,PRD_Name [Product]
				, RTF_Description [Term]
				,cast(POL_OriginalStartDate as date ) as [Start Date]
				,cast(POL_EndDate as date) as[End Date]
				--,cast(case when Pol_MaturityDate > DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) then Pol_MaturityDate 
				--else DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate))end as date )  [End Date] 
				,POL_Status [Policy Status]
INTO			#POL
FROM			Policy,Product,ReferenceTermFrequency
WHERE			POL_Product_ID = Product_Id
				AND TermFrequency_Id = POL_ProductTerm_ID
				AND POL_Deleted = 0
				AND POL_OriginalStartDate <= @val_Date
				AND POL_ReceivedDate <= @val_Date
				AND Product_Id in ('529AFE28-A2BF-4841-9B56-F334660C6CBD','A68AD927-C8B3-47A1-909E-785BDB017377');

-- MERGE TABLE WITH EVENTLOG
Select distinct [Policy Number], 
				Product,
				Term, 
				[Start Date],
				[End Date],
				[Policy Status],
				el.EVL_Event_ID,
				el.EVL_DateTime,
				el.EVL_Description
Into			#pol2
From			Eventlog el
left join		#pol p
on				el.EVL_ReferenceNumber = p.[Policy ID]
Where			el.EVL_Event_ID in (10514, 10516, 10733, 10292, 10515)


--- Update table so that results not affected by entries and exits after valuation date
Update			#pol2
set				[Policy Status] = 1 
where			EVL_Event_ID = 10516
				and EVL_DateTime > @val_Date

-- GET RESULTS
SELECT  distinct [Policy Number], 
				  Product,
				  Term, 
				  [Start Date],
				  [End Date],
				  [Policy Status]
From			#pol2
WHERE			[Policy Status] = 1
				AND [POLICY NUMBER] IS NOT NULL

drop table if exists #pol;
 drop table if exists #pol2;
