
select Base_Policy_Number, Make, Clean_Plan, Section_description, Monthly_premium, Mo, Cancel_in_Month, Effective_Start_Date, Effective_End_Date, 1 as Exposure

from (
select o.*, M.Mo, 1 as LineCount,  case when convert(varchar(6),Effective_End_Date,112) = Mo AND Renewed = 0 then 1 else 0 end as Cancel_in_Month
from (

select POL_GeneratedPolicyNumber as Base_Policy_Number ,pol.POL_PolicyNumber ,	PDS_SectionGrouping	as Section_Description,	replace(replace(replace([PRP_PlanName],'Criteria 1 ',''),'Criteria 2 ',''),'Criteria 3 ','')  as Clean_Plan, 
case when RTF_Description = 'Annual' then  ITS_Premium/12 else ITS_Premium END Monthly_Premium ,
 ISNULL([PMI_Make], [PME_Make]) AS Make,
 (case when pol.policy_status in ('in Force','Cancelled') then 
      case when ITS_StartDate > pol.pol_startdate then ITS_StartDate else pol.pol_startdate end else '2050-01-01' end) as Effective_Start_Date,
  
  (case when pol.policy_status in ('in Force','Cancelled') then  
  case when ITS_Enddate < pol.pol_Enddate then ITS_Enddate else pol.pol_Enddate end else '2050-01-01' end) as Effective_End_Date,
  (case when ISNULL(Pol.Cancellation_Reason,'') like '%renewed%' then 1 else 0 end) as Renewed,
  ISNULL(Pol.Cancellation_Reason,'') AS Cancellation_Reason
 --select o.*, p.Cancellation_Reason 
--select * from [EVPRODSQL02].[BI_ReportData].[dbo].[vw_OMI_Policies] as O
--select TOP(100) * 
FROM [Evolve].[dbo].[ItemSummary] as O
LEFT JOIN [Evolve].[dbo].[Policy] p ON [ITS_Policy_ID] = Policy_ID
LEFT JOIN [RB_Analysis].[dbo].[Evolve_Policy] rp ON [ITS_Policy_ID] = rp.Policy_ID
LEFT JOIN [Evolve].[dbo].[PolicyMechanicalBreakdownItem] ON [PolicyMechanicalBreakdownItem_ID] = ITS_Item_ID
LEFT JOIN [Evolve].[dbo].[PolicyMotorExtendedItem] ON [PolicyMotorExtendedItem_ID] = ITS_Item_ID
LEFT JOIN [Evolve].[dbo].[ReferenceTermFrequency] ON [POL_ProductTerm_ID] = [TermFrequency_Id]
LEFT JOIN [Evolve].[dbo].[ProductPlans] ON [ProductPlans_Id] = ISNULL([PMI_Plan_ID], [PME_Plan_ID])
LEFT JOIN [Evolve].[dbo].[ProductSection] ON [ProductSection_Id] = ISNULL([PMI_Section_ID], [PME_Section_ID])
left join [RB_Analysis].[dbo].[Evolve_Policy] as pol on p.POL_PolicyNumber = pol.POL_PolicyNumber
  where 1=1
  --and pol.[POL_PolicyNumber] = 'OV4U005109POL'
  and pol.Policy_Status not in ('Renewal')
  and pol.[POL_PolicyNumber] LIKE 'OV%'
  and its_deleted = '0'
  and ITS_StartDate != ITS_EndDate
-- group by POL_GeneratedPolicyNumber,	pol.POL_PolicyNumber, PDS_SectionGrouping,	replace(replace(replace(pol.Mechanical_Breakdown_Plan,'Criteria 1 ',''),'Criteria 2 ',''),'Criteria 3 ','')   ,  
--pol.Make, pol.model, pol.Vin_Number, pol.Reg_Number,
-- (case when pol.policy_status in ('in Force','Cancelled') then 
--      case when ITS_StartDate > pol.pol_startdate then ITS_StartDate else pol.pol_startdate end else '2050-01-01' end),
  
--  (case when pol.policy_status in ('in Force','Cancelled') then  
--  case when ITS_Enddate < pol.pol_Enddate then ITS_Enddate else pol.pol_Enddate end else '2050-01-01' end) ,
--  (case when ISNULL(Pol.Cancellation_Reason,'') like '%renewed%' then 1 else 0 end),
--  ISNULL(Pol.Cancellation_Reason,'')
 
 
 ) as O ,
  [RB_Analysis].[dbo].[rb_months] as M
  where 1=1
  --and    Base_Policy_Number = 'OV4U000760POL'
  --and Item_Status = 'In Force'
  and o.Effective_Start_Date <= m.month_start
  and o.Effective_End_Date >= m.month_start 
  and m.date_end < getdate()
  and o.Effective_End_Date != o.Effective_Start_Date
  ) as X
--  group by Base_Policy_Number,		Effective_Start_Date,	Effective_End_Date ,	Section_Description,		Mo 	 	
  order by   mo, Base_Policy_Number