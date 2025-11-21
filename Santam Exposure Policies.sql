-- Ensure necessary temporary tables are dropped
DROP TABLE IF EXISTS #Pol;
DROP TABLE IF EXISTS #PolWithMonths;
DROP TABLE IF EXISTS #MTH;
DROP TABLE IF EXISTS #StillActive;
DROP TABLE IF EXISTS #Claims;
DROP TABLE IF EXISTS #Claims2;
DROP TABLE IF EXISTS #Res;





-- Active Pols

SELECT 
       [POL_GeneratedPolicyNumber],
       [POL_Status]
    
	into #StillActive
      
      
  FROM [Evolve].[dbo].[Policy]

  WHERE [POL_PolicyNumber] LIKE 'S%'

and POL_Status in(1)



-- Populate #Pol
SELECT 
    p.[POL_PolicyNumber],
	p.[POL_GeneratedPolicyNumber],
    p.Policy_ID,
    ITS_Item_ID,
    ISNULL([PMI_VehicleCode], [PME_VehicleCode]) AS [PMI_VehicleCode],
    ISNULL([PMI_Make], [PME_Make]) AS [PMI_MakeOriginal],
    						case when [PMI_Make] COLLATE DATABASE_DEFAULT in (select distinct make from [MSureEvolve].[dbo].[ms_rating_warranty] ) then [PMI_Make]
						      when [PME_Make]  COLLATE DATABASE_DEFAULT in (select distinct make from [MSureEvolve].[dbo].[ms_rating_warranty] ) then [PME_Make]
		                 else 'OTHER' end  [Make],
     ISNULL([PMI_Model], [PME_Model]) AS [Model],
    [PRP_PlanName],
    SUBSTRING([PRP_PlanName], 10, 1) AS OriginalCriteria,
    CASE 
        WHEN SUBSTRING([PRP_PlanName], 12, 6) = '' THEN [PRP_PlanName]
        ELSE SUBSTRING([PRP_PlanName], 12, 6)
    END AS PlanOption,
    [PDS_SectionGrouping],
    [ITS_SumInsured],
    case when p.POL_ProductTerm_ID = 6 then [ITS_Premium]/12 else [ITS_Premium] end [ITS_Premium] ,
    ISNULL([PMI_PresentKM], [PME_PresentKM]) AS [PMI_PresentKM],
    p.[POL_Status],
    [ITS_Status],
    [RTF_Description],
    ISNULL([PMI_RegistrationDate], [PME_RegistrationDate]) AS [PMI_RegistrationDate],
    ISNULL([PMI_PurchaseDate], [PME_PurchaseDate]) AS [PMI_PurchaseDate],
    p.[POL_SoldDate],
    ISNULL([PMI_MileageDate], [ITS_StartDate]) AS [PMI_MileageDate],
    [ITS_StartDate],
    CASE WHEN [ITS_EndDate] > p.POL_EndDate THEN p.POL_EndDate ELSE [ITS_EndDate] END [ITS_EndDate] ,
    p.[POL_RenewalDate],
	o.POL_OriginalStartDate,
	p.POL_StartDate,
	p.POL_EndDate

INTO #Pol
FROM [Evolve].[dbo].[ItemSummary]
LEFT JOIN [Evolve].[dbo].[Policy] p ON [ITS_Policy_ID] = Policy_ID
LEFT JOIN [Evolve].[dbo].[PolicyMechanicalBreakdownItem] ON [PolicyMechanicalBreakdownItem_ID] = ITS_Item_ID
LEFT JOIN [Evolve].[dbo].[PolicyMotorExtendedItem] ON [PolicyMotorExtendedItem_ID] = ITS_Item_ID
LEFT JOIN [Evolve].[dbo].[ReferenceTermFrequency] ON [POL_ProductTerm_ID] = [TermFrequency_Id]
LEFT JOIN [Evolve].[dbo].[ProductPlans] ON [ProductPlans_Id] = ISNULL([PMI_Plan_ID], [PME_Plan_ID])
LEFT JOIN [Evolve].[dbo].[ProductSection] ON [ProductSection_Id] = ISNULL([PMI_Section_ID], [PME_Section_ID])
LEFT JOIN [Evolve].[dbo].[Policy] o ON     o.[POL_PolicyNumber] = p.[POL_GeneratedPolicyNumber]


WHERE p.[POL_PolicyNumber] LIKE 'S%'

and p.POL_Status in(1,3)
and o.POL_Status in(1,3)

and p.POL_StartDate < p.POL_EndDate

--and ITS_Status =3

;

--select * from [Evolve].[dbo].[Policy] where POL_PolicyNumber in ('OV4U005109POL','OV4U004564POL')





-- Define start and end dates
DECLARE @valuationStart DATE = (SELECT MIN(ITS_StartDate) FROM #Pol);
DECLARE @valuationEnd DATE = GETDATE();

-- Generate month ranges
WITH DateRange AS (
    SELECT 
        DATEADD(MONTH, DATEDIFF(MONTH, 0, @valuationStart), 0) AS MTH,
        EOMONTH(DATEADD(MONTH, DATEDIFF(MONTH, 0, @valuationStart), 0)) AS ME
    UNION ALL
    SELECT 
        DATEADD(MONTH, 1, MTH) AS MTH,
        EOMONTH(DATEADD(MONTH, 1, MTH)) AS ME
    FROM DateRange
    WHERE DATEADD(MONTH, 1, MTH) <= @valuationEnd
)
SELECT *
INTO #MTH
FROM DateRange
OPTION (MAXRECURSION 500);

-- Join and filter rows
SELECT 
    p.*,
    m.MTH AS EffectiveMonth,
    m.ME AS MonthEnd
INTO #PolWithMonths
FROM #Pol p
CROSS JOIN #MTH m
WHERE p.ITS_StartDate <= m.ME
  AND p.ITS_EndDate >= m.MTH
  AND eomonth(p.ITS_StartDate) <> eomonth(p.ITS_EndDate);

  --select * from #Pol where POL_PolicyNumber like 'OV4U000777POL%' and PMI_MakeOriginal = 'TOYOTA' order by POL_PolicyNumber


  

-- View final results


SELECT 

POL_PolicyNumber	,
--p.[POL_GeneratedPolicyNumber],
ITS_Item_ID,
PMI_MakeOriginal	,
Make	,
Model,
--PRP_PlanName	,
--OriginalCriteria	,
PlanOption	,
PDS_SectionGrouping	,
ITS_SumInsured	,
ITS_Premium	,
--PMI_PresentKM	,
--a.POL_Status,
--ITS_Status	,
--RTF_Description	,
--PMI_RegistrationDate	,
--PMI_PurchaseDate	,
--POL_SoldDate	,
--PMI_MileageDate	,
ITS_StartDate	,
ITS_EndDate	,
POL_OriginalStartDate,
POL_RenewalDate	,

EffectiveMonth	,
MonthEnd	,
case when ITS_StartDate <> DATEADD(DAY, 1, EOMONTH(ITS_StartDate, -1)) and EOMONTH(ITS_StartDate, 0) = MonthEnd then  (DATEDIFF(DAY, ITS_StartDate, EOMONTH(ITS_StartDate,0)) +1)*1.000000 /DAY(EOMONTH(ITS_StartDate))*1.000000 
     when ITS_EndDate <> EOMONTH(ITS_EndDate, 0) and EOMONTH(ITS_EndDate, 0) = MonthEnd then  (DATEDIFF(DAY, EOMONTH(ITS_EndDate, -1),ITS_EndDate))*1.000000 /DAY(EOMONTH(ITS_EndDate))*1.000000
	 else 1 end Exposure 

--Case when eomonth (ITS_EndDate) = MonthEnd and eomonth (ITS_EndDate) <> POL_RenewalDate-1  then 1
--else 0 end Cancelled,

--SELECT DATEADD(DAY, 1, EOMONTH(GETDATE(), -1)) AS FirstDayOfMonth;

--SELECT DATEDIFF(DAY, '2024-01-01', '2024-01-31')

--SELECT DAY(EOMONTH(GETDATE()))

--case when POL_RenewalDate -1 = MonthEnd then 1 else 0 end	 RenewalDueInd,

--case when month(POL_OriginalStartDate) = month(EffectiveMonth	)  and Year(POL_OriginalStartDate)<Year(EffectiveMonth)  then 1 else 0 end	 RenewedInd,

--  datediff(year, POL_OriginalStartDate,POL_RenewalDate)		 UnderwritingYear



  into #res

FROM #PolWithMonths p


where MonthEnd <='2025-10-31'

--and POL_PolicyNumber like 'OV4U001589POL%'

--and PDS_SectionGrouping ='Mechanical Breakdown'
--and  [CIS_Estimate] is not null

--and PMI_MakeOriginal ='VOLKSWAGEN'


ORDER BY POL_PolicyNumber,PMI_MakeOriginal,Make,Model, PDS_SectionGrouping, EffectiveMonth;


--select * FROM #PolWithMonths where POL_PolicyNumber ='OV4U005832POL' ORDER BY POL_PolicyNumber,PMI_MakeOriginal, PDS_SectionGrouping, EffectiveMonth;

--select * from #pol where POL_PolicyNumber like 'OV4U005818POL%' order by POL_PolicyNumber  and PMI_MakeOriginal = 'VOLKSWAGEN' order by POL_PolicyNumber

--select* from #res where UnderwritingYear=7 MonthEnd = '2024/10/31'AND RenewalDueInd=1 and RenewedInd =1 


select MonthEnd ,PMI_MakeOriginal Make, count(*) ActiveCount, sum(ITS_Premium * Exposure) GWP
 from #res where 1=1 

 --and MonthEnd = '2024-12-31'
 --and POL_PolicyNumber = 'OV4U005306POL'


 group by MonthEnd ,PMI_MakeOriginal 

 --order by POL_PolicyNumber


