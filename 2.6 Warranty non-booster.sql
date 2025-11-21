Use Evolve
-- Warranty Non-Booster

 drop table if exists #pol;
 drop table if exists #pol2

--DECLARE VARIABLES
--#####################################################################################
DECLARE @val_Date AS DATETIME2 = '2025-10-31 23:59:59.999'
--#####################################################################################

SELECT				POL_PolicyNumber [Policy Number]
					,Policy_id [Policy ID]
					,Case 
							when pol_productvariantlevel1_id in ('A96B15B6-7922-46BF-93BD-14C735991BB3') THEN 'Wty Booster' 
							else 'Wty Non-Booster' 
					end [Product]
					,RTF_Description [Term]
					,POL_OriginalStartDate [Start Date]
					,POL_EndDate [End Date]
					,POL_Status [Policy Status]
INTO				#POL
FROM				Policy,Product,ReferenceTermFrequency
WHERE				POL_Product_ID = Product_Id
					AND TermFrequency_Id = POL_ProductTerm_ID
					AND POL_Deleted = 0
					and POL_OriginalStartDate < POL_EndDate
					AND POL_ReceivedDate <= @val_Date
					AND Product_Id in ('219527F3-1FFA-45B8-8D41-5C1E0E6F4CEF')
					AND pol_productvariantlevel1_id not in ('A96B15B6-7922-46BF-93BD-14C735991BB3');

-- MERGE TABLE WITH EVENTLOG
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
					on el.EVL_ReferenceNumber = p.[Policy ID]
Where				el.EVL_Event_ID in (10514, 10516, 10733, 10292, 10515)

--- Update table so that results not affected by entries and exits after valuation date
Update				#pol2
set					[Policy Status] = 1 
where				EVL_Event_ID = 10516
					and EVL_DateTime > @val_Date

-- GET RESULTS
SELECT  distinct	[Policy Number], 
					Product,
					Term, 
					CAST([Start Date] AS DATE) AS [Start Date] ,
					CAST([End Date] AS DATE) AS [End Date] ,
					[Policy Status]
From				#pol2
WHERE				[Policy Status] = 1
					AND [POLICY NUMBER] IS NOT NULL
-- DROP TABLES
 drop table if exists #pol;
 drop table if exists #pol2





