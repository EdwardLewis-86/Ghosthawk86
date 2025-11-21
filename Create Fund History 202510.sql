
drop table if exists [UPP].[dbo].[FundHistory];

select * 
  
  into [UPP].[dbo].[FundHistory]

from (

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202510]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202509]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202508]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202507_Test]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202506_Test]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202505]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202504]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202503]

    union


SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202502]

    union


SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202501]

    union



SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202412]

    union




SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202411]

    union



SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202410]

    union


SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202409]

    union


SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202408]

    union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
FROM [UPP].[dbo].[SAW_UPP_202407]

      union

SELECT 
       [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
  FROM [UPP].[dbo].[SAW_UPP_202406]

        union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]
 FROM [UPP].[dbo].[SAW_UPP_202405]

        union

SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

FROM [UPP].[dbo].[SAW_UPP_202404]

  
        union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202403]

  
        union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202402]

  
        union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202401]

  
        union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202312]

          union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202311]

          union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202310]

          union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202309]

            union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202308]

            union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202307]


            union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202306]


            union

  SELECT 
      [POL_PolicyNumber]
      ,[WW_Policy_Key]
	  ,ValuationMonth
      ,[WW_Nett_Fund]
      ,[Evolve_Nett_Fund]

  FROM [UPP].[dbo].[SAW_UPP_202305]

  ) as t