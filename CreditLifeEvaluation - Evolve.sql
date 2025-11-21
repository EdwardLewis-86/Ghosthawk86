  select 
 INS_InsurerName [Insurer],
 FORMAT(DATEADD(Day, -1, GETDATE()), 'yyyyMM') [Account Period],
 PolicyNumber [Policy Number],
 CellCaptive [Cell Captive],
 Type_Of_Policy [Type of Policy],
 PlanName [Plan Name],
 Basic_Premium [Basic Premium],
 Gender1 [Gender 1],Gender2 [Gender 2],Gender3 [Gender 3],
 Sa_Death [Sa Death],Sa_Disability [Sa Disability],SA_Dread_Disease [Sa Dread Disease],SA_Temp_Disability  [Sa Temp Disability],
 SA_Retren_Hosp [Sa Retren Hosp],SA_6 [Sa 6],SA_7 [Sa 7],SA_8 [Sa 8],
 Date_OF_Birth1 [Date Of Birth 1],Date_OF_Birth2 [Date Of Birth 2],Date_OF_Birth3 [Date Of Birth 3],
 Date_Of_Commencement [Date Of Commencement],StartDate [Start Date],
 EvolveStartDate [Evolve Start Date],CeaseDate [Cease Date],Date_Premiums_Cease [Date Premiums Cease],
 Date_Death [Date Death],Date_Disability [Date Disability],Date_Dreaded_disease [Date Dreaded Disease],
 Date_Temp_Disab [Date Temp Disab],Date_Retrenc_Hosp [Date Retrenc Hosp],
 Date_6 [Date 6],Date_7 [Date 7],Date_8 [Date 8],Agent_No [Agent No],Agent_Name [Agent Name],SubAgent_No [Sub Agent No],
 SubAgent_Name [Sub Agent Name],Payment_Type [Payment Type],Tia_Old_Pol_No [TIA Policy No],Movement [Movement], POS_Description [Policy Status],IsMigrated [IsMigrated]
  from vw_CreditLifeValuationExtract, Policy, PolicyInsurerLink, Insurer, InsurerGroupLink, InsurerGroup, ReferencePolicyStatus
 where POL_PolicyNumber = PolicyNumber
 --AND POL_Status = 1
 AND PolicyStatus_ID = POL_Status
 and Policy_ID = PIL_Policy_ID
 and Insurer_Id = PIL_Insurer_ID
 and IGL_Insurer_Id = Insurer_Id
 and InsurerGroup_Id = IGL_InsurerGroup_Id
 {insurer}
