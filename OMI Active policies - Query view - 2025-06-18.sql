select o.*, M.Mo, 1 as LineCount,  case when convert(varchar(6),Effective_End_Date,112) = Mo AND Renewed = 0 then 1 else 0 end as Cancel_in_Month
from (
select Base_Policy_Number,O.POL_PolicyNumber ,	Section_Description,	replace(replace(replace(O.Mechanical_Breakdown_Plan,'Criteria 1 ',''),'Criteria 2 ',''),'Criteria 3 ','')  as Clean_Plan, 
sum( cast(O.Premium/case when O.Payment_Frequency = 'Annual' then 12 else 1 end as decimal(10,2)) ) as Monthly_Premium ,
 O.Make, O.model, O.Vin_Number, O.Reg_Number,
 (case when O.policy_status in ('in Force','Cancelled') then 
      case when ITS_StartDate > O.pol_startdate then ITS_StartDate else O.pol_startdate end else '2050-01-01' end) as Effective_Start_Date,
  
  (case when O.policy_status in ('in Force','Cancelled') then  
  case when ITS_Enddate < O.pol_Enddate then ITS_Enddate else O.pol_Enddate end else '2050-01-01' end) as Effective_End_Date,
  (case when ISNULL(P.Cancellation_Reason,'') like '%renewed%' then 1 else 0 end) as Renewed,
  ISNULL(P.Cancellation_Reason,'') AS Cancellation_Reason
 --select o.*, p.Cancellation_Reason 
 from [EVPRODSQL02].[BI_ReportData].[dbo].[vw_OMI_Policies] as O
 left join  [RB_Analysis].[dbo].[Evolve_Policy] as P on o.pol_policynumber = p.POL_PolicyNumber
  where 1=1
  --and Base_Policy_number = 'OV4U001384POL'
  and O.Policy_Status not in ('Renewal')
 group by Base_Policy_Number,	Section_Description,	replace(replace(replace(O.Mechanical_Breakdown_Plan,'Criteria 1 ',''),'Criteria 2 ',''),'Criteria 3 ','')   ,  
 O.Make, O.model,O.Vin_Number, O.Reg_Number ,case when O.policy_status in ('in Force','Cancelled') then 
      case when ITS_StartDate > O.pol_startdate then ITS_StartDate else O.pol_startdate end else '2050-01-01' end,  (case when O.policy_status in ('in Force','Cancelled') then  
  case when ITS_Enddate < O.pol_Enddate then ITS_Enddate else O.pol_Enddate end else '2050-01-01' end) ,
  case when ISNULL(P.Cancellation_Reason,'') like '%renewed%' then 1 else 0 end, O.POL_PolicyNumber,  ISNULL(P.Cancellation_Reason,'')
 
 
 ) as O ,
  [RB_Analysis].[dbo].[rb_months] as M
  where 1=1
  --and    Base_Policy_Number = 'OV4U001329POL'
  --and Item_Status = 'In Force'
  and o.Effective_Start_Date <= m.month_start
  and o.Effective_End_Date >= m.month_start 
  and m.date_end < getdate()
  order by mo



  ----------

select Base_Policy_Number,		Effective_Start_Date,	Effective_End_Date ,	Section_Description,		sum(Monthly_Premium ) as Monthly_Premium,		Mo,	1 as Policy_Count

from (
select o.*, M.Mo, 1 as LineCount,  case when convert(varchar(6),Effective_End_Date,112) = Mo AND Renewed = 0 then 1 else 0 end as Cancel_in_Month
from (
select Base_Policy_Number,O.POL_PolicyNumber ,	Section_Description,	replace(replace(replace(O.Mechanical_Breakdown_Plan,'Criteria 1 ',''),'Criteria 2 ',''),'Criteria 3 ','')  as Clean_Plan, 
sum( cast(O.Premium/case when O.Payment_Frequency = 'Annual' then 12 else 1 end as decimal(10,2)) ) as Monthly_Premium ,
 O.Make, O.model, O.Vin_Number, O.Reg_Number,
 (case when O.policy_status in ('in Force','Cancelled') then 
      case when ITS_StartDate > O.pol_startdate then ITS_StartDate else O.pol_startdate end else '2050-01-01' end) as Effective_Start_Date,
  
  (case when O.policy_status in ('in Force','Cancelled') then  
  case when ITS_Enddate < O.pol_Enddate then ITS_Enddate else O.pol_Enddate end else '2050-01-01' end) as Effective_End_Date,
  (case when ISNULL(P.Cancellation_Reason,'') like '%renewed%' then 1 else 0 end) as Renewed,
  ISNULL(P.Cancellation_Reason,'') AS Cancellation_Reason
 --select o.*, p.Cancellation_Reason 
 from [EVPRODSQL02].[BI_ReportData].[dbo].[vw_OMI_Policies] as O
 left join  [RB_Analysis].[dbo].[Evolve_Policy] as P on o.pol_policynumber = p.POL_PolicyNumber
  where 1=1
  --and Base_Policy_number = 'OV4U001384POL'
  and O.Policy_Status not in ('Renewal')
 group by Base_Policy_Number,	Section_Description,	replace(replace(replace(O.Mechanical_Breakdown_Plan,'Criteria 1 ',''),'Criteria 2 ',''),'Criteria 3 ','')   ,  
 O.Make, O.model,O.Vin_Number, O.Reg_Number ,case when O.policy_status in ('in Force','Cancelled') then 
      case when ITS_StartDate > O.pol_startdate then ITS_StartDate else O.pol_startdate end else '2050-01-01' end,  (case when O.policy_status in ('in Force','Cancelled') then  
  case when ITS_Enddate < O.pol_Enddate then ITS_Enddate else O.pol_Enddate end else '2050-01-01' end) ,
  case when ISNULL(P.Cancellation_Reason,'') like '%renewed%' then 1 else 0 end, O.POL_PolicyNumber,  ISNULL(P.Cancellation_Reason,'')
 
 
 ) as O ,
  [RB_Analysis].[dbo].[rb_months] as M
  where 1=1
  --and    Base_Policy_Number = 'OV4U001329POL'
  --and Item_Status = 'In Force'
  and o.Effective_Start_Date <= m.month_start
  and o.Effective_End_Date >= m.month_start 
  and m.date_end < getdate()
  ) as X
  group by Base_Policy_Number,		Effective_Start_Date,	Effective_End_Date ,	Section_Description,		Mo 	 	
  order by mo