
  -----------------------------------------------------------------------------------------------------------Test
   Select  v.* , [RV_Known]	DataEnriched, [RV_Ind]	BalloonIndicator,   [ResidualAmount] Balloon 

from vw_HollardCLExtract v 
--where 1 = 1
--order by 1 desc

 

left join Balloons 

on  [Policy Number] = [POL_PolicyNumber] 

--where [valuation month] = 'dd-mmm-yyyy'  
where [valuation month] = '2025-09-30'