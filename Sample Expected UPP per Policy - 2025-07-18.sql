SELECT  [Policy_ID]
      ,[POL_CreateDate]
      ,[POL_PolicyNumber]
      ,[POL_Status]
      ,[POL_Product_ID]
      ,[POL_ProductOption_ID]
      ,[POL_ProductTerm_ID]
      ,[POL_StartDate]
      ,[POL_ReceivedDate]
      ,[POL_SoldDate]
      ,[POL_EndDate]
      ,[POL_Arrangement_ID]
    
      ,[POL_ProductPlan_ID]
      ,[POL_ProductVariantLevel3_ID]
      ,[POL_WaitingPeriodOverrideInd]
      ,[POL_PolicyTerm]
	  , cast(null as varchar(100)) as Curve_Used
	  ,its.ITS_Section_ID
	  ,its.ITS_Premium
	  into #tmp
  FROM [Evolve].[dbo].[Policy] as Pol
  inner Join [Evolve].[dbo].ItemSummary as ITS on pol.Policy_ID = its.ITS_Policy_ID
  inner join [Evolve].[dbo].Arrangement as arg on pol.POL_Arrangement_ID = arg.Arrangement_Id
  where POL_PolicyNumber =  'QWTY168940POL'

  

drop table #CellFee_Diffs
select rcc.RCC_Description, drn.DRN_Description, fcv.FCV_CellCaptive_ID ,FCV_Insurer_ID ,FCV_FromDate,	FCV_ToDate,FCV_Value
 into #CellFee_Diffs
from evolve.dbo.FinanceCentralValue as fcv
inner join [Evolve].[dbo].[ReferenceDisbursementRuleName] as drn on FCV_DisbursementRuleName_ID = drn.DisbursementRuleName_ID
left join [Evolve].[dbo].ReferenceCellCaptive as rcc on rcc.ReferenceCellCaptive_Code = fcv.FCV_CellCaptive_ID
 
where DRN_Description = 'Cell Fee differential'

Update C
set FCV_CellCaptive_ID = 1
from #CellFee_Diffs as C
where RCC_Description = 'Master Cell'



  drop table #UPPCurve

   select pol.POL_PolicyNumber,pol.POL_Product_ID,    pol.POL_StartDate ,pol_endDate, policy_id, dch.DCH_Name , dci.DCI_Month,	DCI_MonthlyPercentage, 
   dateadd(month,-1,dateadd(day,1,eomonth(dateadd(month,dci.DCI_Month,pol_startdate)))) as Effective_date,
   
   cast(null as decimal(10,2)) as Earned_in_Month
-- into #UPPCurve
 --select distinct dci.*
 from #tmp as Pol
 --inner join evolve.dbo.Arrangement as arg on pol.POL_Arrangement_ID = arg.Arrangement_Id
 inner join [Evolve].[dbo].[DisbursementCurveProduct] as crv on pol.POL_ProductVariantLevel3_ID = crv.DCP_Product_Id and DCP_Deleted = 0
 inner join [Evolve].[dbo].[DisbursementCurveHeader] as dch on dch.DisbursementCurveHeader_Id = crv.DCP_DisbursementCurveHeader_Id and DCH_Deleted = 0 and DCH_TermFrequency_Id = pol.POL_ProductTerm_ID and DCH_Enabled = 1
 inner join  [Evolve].[dbo].[DisbursementCurveItem] as DCI on dci.DCI_DisbursementCurveHeader_Id = dch.DisbursementCurveHeader_Id and  DCI_Deleted = 0
 --inner join #tmp as T on pol.Policy_ID = t.Policy_ID
 --where  POL_PolicyNumber = @PolicyNo
 order by DCI_Month

