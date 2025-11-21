SELECT    [POL_PolicyNumber]
      ,[Policy_ID]
      ,[Policy_Status]
      ,[POL_Client_ID]
      ,[PRD_Name]
      ,[Product_Group]
      ,[Product_Plan_Name]
      ,[POL_Product_ID]
      ,[POL_ProductVariantLevel1_ID]
      ,[POL_ProductVariantLevel2_ID]
      ,[POL_ProductVariantLevel3_ID]
      ,[Product_Variant]
      ,[Mechanical_Breakdown_Plan]
      ,[Product_Category]
      ,[Product_Option]
      ,[RTF_TermPeriod]
      ,[POL_SoldDate]
      ,[POL_CreateDate]
      ,[POL_StartDate]
      ,[POL_ReceivedDate]

      ,[POL_EndDate]
      ,[Policy_Cancellation_date]
      ,[Policy_ReInstatement_date]
      ,[POL_RenewalDate]
      ,[POL_AnniversaryDate]
      ,[POL_Agent_ID]
      ,[Agt_Name]
      ,[Agent_Policy_Number]
      ,[RPM_Description]
      ,[Payment_Frequency]
      ,[POL_FirstCollectionDate]
      ,[Premium]
      ,[FEES]
      ,[Total_Summary_Premium]
      ,[Make]
      ,[Model]
      ,[Vehicle_type]
      ,[MMCode]
      ,[Vin_Number]
      ,[Engine_Number]
      ,[Reg_Number]
      ,[First_Reg_Date]
      ,[Vehicle_odo]
      ,[Sum_Insured]
      ,[Insurer_Name]
      ,[Cancellation_Reason]
      ,[Cancellation_Comment]
      ,[NTU_Reason]
      ,[NTU_Date]
      ,[Revenue_Type]
      ,[Policy_ativation_Date]
      ,[Roadside_Partner]
  FROM [RB_Analysis].[dbo].[Evolve_Policy]
  where Insurer_Name in ('MiWay','Santam Limited')
 -- where Insurer_Name like '%santam%'
 order by Insurer_Name


 select Insurer , CLM_PolicyNumber,	Policy_id,	CMI_PolicyMotorBasicItem_ID ,Claim_ID ,  CLM_ClaimNumber,	CIT_ClaimItem_ID,Claim_Status,	Claim_Item_Status,  --Claim_Rejection_reason ,
 Claim_Item_Sub_Status ,
 CLM_ReportedDate,	CLM_LossDate,	CLM_CreateDate ,CIC_Description ,	CMI_SectionName,CIC_limit, sum(OCR_Movement) as OCR_Balance,
 sum(Invoice_Value) as Invoice_Value, sum(Amount_Paid) as Amount_Paid,sum(Amount_Paid_excl_VAT) as Amount_Paid_excl_VAT,sum(Claim_Qty) as Claim_Qty
 --select *
 from [RB_Analysis].[dbo].[Evolve_Claim_Summary] as C
 where exists (
 select *
  FROM [RB_Analysis].[dbo].[Evolve_Policy] as P
  where Insurer_Name in ('MiWay','Santam Limited')
  and c.policy_id = P.policy_id )
  group by  Insurer ,CLM_PolicyNumber,	Policy_id,	CMI_PolicyMotorBasicItem_ID ,Claim_ID ,  CLM_ClaimNumber,	CIT_ClaimItem_ID,Claim_Status,	Claim_Item_Status,  --Claim_Rejection_reason ,
 Claim_Item_Sub_Status ,
 CLM_ReportedDate,	CLM_LossDate,	CLM_CreateDate ,CIC_Description ,	CMI_SectionName,CIC_limit
 order by 1,5