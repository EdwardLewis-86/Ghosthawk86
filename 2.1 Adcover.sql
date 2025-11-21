Use Evolve
--Adcover
drop table if exists #pol;

--- Create table with applicable policies
--#####################################################################################
DECLARE @val_Date AS DATETIME2 = '2025-10-31 23:59:59.999' 
--#####################################################################################

SELECT				POL_PolicyNumber [Policy Number]
					,PRD_Name [Product]
					, RTF_Description [Term]
					,POL_OriginalStartDate [Start Date]
					,case 
							when Pol_MaturityDate > DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) 
								then Pol_MaturityDate else DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) 
					end [End Date] 
					,POL_Status [Policy Status]
FROM				Policy,Product,ReferenceTermFrequency
WHERE				POL_Product_ID = Product_Id
					AND TermFrequency_Id = POL_ProductTerm_ID
					AND POL_Status = 1
					AND POL_Deleted = 0
					AND POL_OriginalStartDate <= @val_Date
					AND(case when Pol_MaturityDate > DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) 
								then Pol_MaturityDate else DateAdd(day,-1,Dateadd(month, POL_FinanceTerm_ID,POL_OriginalStartDate)) end >= @val_Date or POL_ProductTerm_ID = 4)
					AND Product_Id in ('77C92C34-0CBB-4554-BD41-01F2D8F5FC11','436BB1D0-CB35-4FF0-BD50-A316A08AE87B', '70292F27-B7EE-4274-8B51-E345F4C1AD18', 
									   '86E44060-B546-4A65-9464-9C4F78C1681E','DDDC2DA4-881F-40B9-A156-8B7EA881863A')
					AND POL_ReceivedDate <= @val_Date;

