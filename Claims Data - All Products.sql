  select   Insurer.INS_InsurerName [Insurer]
  ,  PRD_Name [Product]
  ,  CIS_SectionName [Product Section]
  ,  Division.SRN_Text [Division]
  ,  SalesBranch.SRN_Text [Sales Branch]
  ,  PrimaryAgent.Agt_Name [Primary Agent]
  ,  SubAgent.Agt_Name [Sub Agent]
  ,  AFG_Description [Agent Group]
  ,  POL_PolicyNumber [Policy Number]
  , AgentPolicyNumber.RNR_Number [Agent Policy Number]
  ,  CONCAT(Cli_Name, ' ', Cli_Surname) [Client]
  ,  CLI_Initials [Client Initials]
  ,  POL_OriginalStartDate [Original Start Date]
  ,  (select sum(ITS_premium) 
  from ItemSummary 
  where ITS_Policy_ID = Policy_ID 
  AND ITS_Deleted = 0) [Premium]
  ,  ClaimTechnicion.USR_Description [Claim Technician]
  ,  RegisterUser.USR_Description [Register User]
  ,  CIS_SectionName [Section]
  ,  ReferenceClaimType.CTI_Description [Component/Risk Type]
  ,  ClaimItemSummary.CIS_LossTypeDescription [Loss Type]
  ,  CLM_ClaimNumber [Claim Number]
  ,  CLM_BrokerAgentClaimNumber [Agent Claim Number]
  ,  CLS_Description [Claim Status]
  ,  CIS_ClaimItemDescription [Item Description]
  ,  CLM_Description [Claim Description]
  ,  CIS_LossDate [Loss Date]
  ,  CLM_CreateDate [Register Date]
  ,  CASE WHEN Dates.[Rejected Date] is not null THEN Dates.[Rejected Date]   
  WHEN Transactions.[Paid Date] is not null then Transactions.[Paid Date]  
  else Dates.[Finalised Date] END [Decision Date]
  ,  Dates.[Finalised Date]
  ,  [Reject Reason]
  ,  [Decline Reason]
  ,  Payments.[Original Estimate]
  ,  Totals.[Total Estimate]
  ,  Payments.Payments
  ,  CLM_ExGratiaAmount [ExGratia Payments]
  ,  Totals.[Total Outstanding]
  ,  Totals.[Recovery Estimate]
  ,  Payments.Recoveries
  ,  (Payments.Recoveries + Payments.Payments) [Incurred]
  ,  (SELECT Count(*) FROM ClaimItemTransaction WHERE CIT_ClaimItem_ID = CIS_ClaimItem_ID) [Total Transaction Count]
  ,  ISNULL(Transactions.Count, 0) [Payment Count]
  ,   Transactions.[Last Transaction Date]
  ,  Transactions.[Paid Date]
  ,  Transactions.[Auth 1 User]
  ,  Transactions.[Auth 2 User]    
  from Policy  
  left join PolicyInsurerLink on PIL_Policy_ID = Policy_ID   
  left join Insurer on PIL_Insurer_ID = Insurer_Id  
  left join InsurerGroupLink on IGL_Insurer_Id = Insurer_Id  
  left join Agent PrimaryAgent on PrimaryAgent.Agent_Id = POL_PrimaryAgent_ID  
  left join Agent SubAgent on SubAgent.Agent_Id = POL_Agent_ID  
  LEFT JOIN ReferenceFactoringGroups on ReferenceFactoringGroup_ID = PrimaryAgent.Agt_FactoringGroup  
  LEFT JOIN AgentDivisionLink on PrimaryAgent.Agent_Id = ADL_Agent_ID  
  LEFT JOIN SalesBranch on SalesRegion_ID = ADL_Division_ID  
  LEFT JOIN SalesBranch Division on Division.SalesRegion_ID = SalesBranch.SRN_Parent_ID  
  left join ReferencePolicyOwner on ReferencePolicyOwner_ID = POL_Owner_ID  
  left join Product on Product_Id = POL_Product_ID  
  left join Claim Claim on CLM_Policy_ID = Policy_ID  
  left join ClaimItemSummary on CIS_Claim_ID = Claim_ID  
  left join ReferenceClaimType on ReferenceClaimType_ID = CIS_ClaimType_ID  
  Left join Client on POL_Client_ID = Client_ID  
  Left join SystemUsers ClaimTechnicion on ClaimTechnicion.Users_ID = CLM_AssignedUser_ID  
  Left join SystemUsers RegisterUser on RegisterUser.Users_ID = POL_CreateUser_ID  
  left join ReferenceLossType on LossType_ID = CIS_SectionLossType_ID  
  left join ReferenceClaimstatus on ClaimStatus_ID = CLM_Status  
  LEFT JOIN ReferenceNumber AgentPolicyNumber on RNR_ItemReferenceNumber = Policy_ID 
  and RNR_NumberType_Id = 122  
  LEFT JOIN (      
  select count(*) [Count]
  , max(CIT_CreateDate) [Last Transaction Date]
  , min(CIT_CreateDate) [Paid Date]
  , CIS_Claim_ID [CISClaimID]
  ,    auth1User.USR_FirstName + ' ' + auth1User.USR_Surname [Auth 1 User]
  ,    auth2User.USR_FirstName + ' ' + auth2User.USR_Surname [Auth 2 User]        
  from ClaimItemSummary, ClaimItemTransaction    
  left join PaymentRequisition on PaymentRequisition_Id = CIT_Payment_ID    
  left join SystemUsers auth1User  on PRQ_Auth1User_ID = Users_ID    
  left join SystemUsers auth2User  on PRQ_Auth2User_ID = auth2User.Users_ID      
  where CIS_ClaimItem_ID = CIT_ClaimItem_ID 
  and PaymentRequisition.PRQ_Status = 5      
  Group by CIS_Claim_ID,auth1User.USR_FirstName
  ,      auth1User.USR_Surname,auth2User.USR_FirstName
  ,      auth2User.USR_Surname     ) Transactions 
  ON CISClaimID = Claim_ID  
  LEFT JOIN (     Select       
  SUM(CASE WHEN CIT_TransactionType_ID = 0 THEN CIT_Amount ELSE 0 END) [Original Estimate]
  ,      SUM(CASE WHEN CIT_TransactionType_ID = 2 THEN CIT_Amount ELSE 0 END) [Payments]
  ,      SUM(CASE WHEN CIT_TransactionType_ID = 3 THEN CIT_Amount ELSE 0 END) [Recoveries]
  ,      CIS_Claim_ID [CISClaimID]     
  from ClaimItemTransaction       
  Left join ClaimItemSummary ON ClaimItemTransaction.CIT_ClaimItem_ID = ClaimItemSummary.CIS_ClaimItem_ID     
  Where CIS_ClaimType_ID IN ('1')      
  group by CIT_Deleted,CIS_Claim_ID     
  HAVING CIT_Deleted = 0    ) Payments 
  ON Payments.CISClaimID = Claim_ID  
  LEFT JOIN (     Select       SUM(CASE WHEN CIS_ClaimType_ID in ('1') THEN CIS_Estimate ELSE 0 END) [Total Estimate]
  ,      SUM(CASE WHEN CIS_ClaimType_ID in ('1') THEN CIS_OutstandingEstimate ELSE 0 END) [Total Outstanding]
  ,      SUM(CASE WHEN CIS_ClaimType_ID in ('2','3','4') THEN CIS_Estimate ELSE 0 END) [Recovery Estimate]
  ,      CIS_Claim_ID [CISClaimID]     
  FROM CLAIMITEMSUMMARY     
  GROUP BY CIS_Deleted,CIS_Claim_ID     
  HAVING CIS_Deleted = 0     ) Totals 
  ON Totals.CISClaimID = Claim_ID  
  left join (     Select Distinct Claim_Id [ClaimID]
  ,      CASE WHEN (       CLM.CLM_Status = 4 AND EVL_Event_ID = 10685       ) THEN EVL_DateTime ELSE NULL END [Finalised Date]
  ,      CASE WHEN (       EVL_Description like 'Claim Rejected'      ) THEN EVL_DateTime ELSE NULL END [Rejected Date]      
  from Claim CLM, EventLog      
  Where CLM.CLM_Deleted = 0      
  AND EVL_ReferenceNumber = CLM.Claim_ID      
  AND EVL_Event_ID in (10685, 10686)      
  AND CLM.CLM_Status < 7      
  AND ISNULL(EVL_User_ID, '') != ''    ) Dates ON Dates.ClaimID = Claim_ID    
  Left join (   Select EVL_ReferenceNumber
  ,    MAX(iif(EVL_Description like 'Claim Rejected',ELD_Description, '')) [Reject Reason]
  ,   MAX(iif(ELD_Description like 'Cancelation Reason' OR ELD_Description like 'NTU Reason', CAST(ELD_Data AS VARCHAR(100)), '')) [Decline Reason]   
  from EventLog, EventLogDetail   
  where ELD_EventLog_ID = EventLog_ID    
  and (EVL_Description like 'Claim Rejected' OR ELD_Description like 'Cancelation Reason' OR ELD_Description like 'NTU Reason')   
  Group by EVL_ReferenceNumber    ) RejectReason 
  on EVL_ReferenceNumber = Claim_ID 
  WHERE CLM_ClaimNumber is not null 
  AND (SELECT Count(*) FROM ClaimItemTransaction WHERE CIT_ClaimItem_ID = CIS_ClaimItem_ID) > 0;