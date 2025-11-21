SELECT SU.USR_Description, RN_1.RNT_Description, RN_1.RNR_Number, P.POL_PolicyNumber, P.Policy_ID, PS.POS_Description AS Policy_Status, P.POL_Description, P.POL_Client_ID, CLI.CLI_ClientNumber, CLI.CLI_Initials, CLI.CLI_Name, CLI.CLI_Surname, CLI.CLI_MaskedIDNumber, 
             CLI.CLI_MaskedPassportNumber, CLI.CLI_CompanyName, CLI.CLI_CompanyRegistration, CLI.CLI_VATNumber, PRD.PRD_Name, RPG.PDG_Description AS Product_Group, CAST(NULL AS varchar(100)) AS Product_Plan_Name, P.POL_Product_ID, P.POL_ProductVariantLevel1_ID, 
             P.POL_ProductVariantLevel2_ID, P.POL_ProductVariantLevel3_ID, P.POL_ProductVariantLevel4_ID, CAST(NULL AS varchar(100)) AS Product_Variant, CAST(NULL AS varchar(100)) AS Mechanical_Breakdown_Plan, CAST(NULL AS varchar(100)) AS Product_Category, 
             PRO.PRO_Description AS Product_Option, RTF.RTF_TermPeriod, P.POL_CreateDate, SU.USR_FirstName + ' ' + SU.USR_Surname AS Created_by, SU2.USR_FirstName + ' ' + SU2.USR_Surname AS Modified_by, P.POL_StartDate, P.POL_ReceivedDate, P.POL_SoldDate, 
             P.POL_EndDate, CAST(NULL AS datetime) AS Policy_Cancellation_date, CAST(NULL AS datetime) AS Policy_ReInstatement_date, P.POL_RenewalDate, P.POL_AnniversaryDate, P.POL_Agent_ID, EAD.Agt_Name, CAST(NULL AS varchar(100)) AS Alternate_Agent_Name, 
             EAD.Agt_MigrationAgentNumber, SA.SAG_AgentName, RPO.RPO_Description AS Policy_Owner, rps.RPS_Description AS POL_SalesSource, RPL.PLT_Description AS Sales_Platform, CAST(NULL AS varchar(100)) AS Agent_Policy_Number, CAST(NULL AS varchar(100)) 
             AS Rims_policy_number, RPM.RPM_Description, CASE WHEN RTF_Description IN ('Monthly', 'Annual') THEN RTF_Description ELSE 'Term' END AS Payment_Frequency, P.POL_DebitDay, P.POL_VatableIndicator, P.POL_VATNumber, AR.ARG_ArrangementNumber, 
             RFH.RFH_Description AS Finance_House, P.POL_FinanceNumber, P.POL_FinanceTerm_ID AS Finance_Term, P.POL_FirstCollectionDate, P.POL_OriginalStartDate, P.POL_FirstPaymentStart, P.POL_MaturityDate, P.POL_SignedDate, P.POL_Version, 
             AGT2.Agt_MigrationAgentNumber AS Primary_Agent_MigrationNumber, RBI.RBI_Description AS Bulking_Institution, P.POL_ConsecutiveUnmetCount, P.POL_LifetimeUnmetCount, DBR.DBR_Name AS Policy_Branding, BAT.BAT_Description AS Bank_Account_Type, 
             BNK.BNK_AccountHolder, BNK.BNK_Bank, BNK.BNK_Branch, BNK.BNK_BranchCode, BNK.BNK_MaskedAccountNo, BNK.BNK_BankType, SUM(ISNULL(PCI_1.PCI_AutoPremium, 0) + ISNULL(PGI_1.PGI_AutoPremium, 0) + ISNULL(PMI_1.PMI_AutoPremium, 0) 
             + ISNULL(PCL_1.PCI_AutoPremium, 0) + ISNULL(PPA_1.PPA_AutoPremium, 0)) AS Premium, SUM(ISNULL(Prem_Sum.Fees, 0)) AS FEES, Prem_Sum.Total_Summary_Premium, P.POL_IsMigrated, CAST(NULL AS varchar(100)) AS Make, CAST(NULL AS varchar(100)) AS Model, 
             CAST(NULL AS varchar(100)) AS Vehicle_type, CAST(NULL AS varchar(100)) AS MMCode, CAST(NULL AS varchar(100)) AS Vin_Number, CAST(NULL AS varchar(100)) AS Engine_Number, CAST(NULL AS varchar(100)) AS Reg_Number, CAST(NULL AS date) AS First_Reg_Date, 
             CAST(NULL AS Decimal(10, 0)) AS Vehicle_odo, CAST(NULL AS Decimal(10, 2)) AS Sum_Insured, ins.INS_InsurerName AS Insurer_Name, IGY.IGY_Name AS Agent_Insurer_Name, RCC.RCC_Description AS Arrangement_Cell_Captive, CAST(NULL AS uniqueidentifier) 
             AS AccountParty_Id, CAST(NULL AS varchar(200)) AS Cancellation_Reason, CAST(NULL AS varchar(400)) AS Cancellation_Comment, CAST(NULL AS varchar(200)) AS NTU_Reason, CAST(NULL AS date) AS NTU_Date, CAST(NULL AS varchar(150)) AS Sales_Region, CAST(NULL 
             AS varchar(150)) AS Sales_Consultant, P.POL_TIAConsecutiveUnmetCount, P.POL_TIALifetimeUnmetCount, P.POL_PolicyTerm, CASE WHEN isnull(EAD.Agt_RevenueType, 9) = 0 THEN 'Gross' WHEN isnull(EAD.Agt_RevenueType, 9) 
             = 1 THEN 'Nett' ELSE 'Other' END AS Revenue_Type, CAST(NULL AS varchar(50)) AS Bank_Product_Code, CASE WHEN isnull(POL_IsMigrated, 0) = '1' THEN 'Yes' ELSE 'No' END AS Policy_Migrated, CAST(NULL AS datetime) AS Policy_ativation_Date
FROM   Evolve.dbo.Policy AS P LEFT OUTER JOIN
             Evolve.dbo.PolicyInsurerLink AS pil ON P.Policy_ID = pil.PIL_Policy_ID LEFT OUTER JOIN
             Evolve.dbo.Insurer AS ins ON pil.PIL_Insurer_ID = ins.Insurer_Id LEFT OUTER JOIN
             Evolve.dbo.SystemUsers AS SU ON P.POL_CreateUser_ID = SU.Users_ID LEFT OUTER JOIN
             Evolve.dbo.SystemUsers AS SU2 ON P.POL_UpdateUser_ID = SU2.Users_ID LEFT OUTER JOIN
             Evolve.dbo.Client AS CLI ON P.POL_Client_ID = CLI.Client_ID LEFT OUTER JOIN
             Evolve.dbo.Product AS PRD ON P.POL_Product_ID = PRD.Product_Id AND PRD.PRD_Deleted = 0 LEFT OUTER JOIN
             Evolve.dbo.ReferenceProductGroup AS RPG ON RPG.ProductGroup_ID = PRD.PRD_ProductGroup_Id LEFT OUTER JOIN
             Evolve.dbo.ReferenceTermFrequency AS RTF ON P.POL_ProductTerm_ID = RTF.TermFrequency_Id LEFT OUTER JOIN
             Evolve.dbo.ProductOptions AS PRO ON P.POL_ProductOption_ID = PRO.ProductOptions_Id LEFT OUTER JOIN
             Evolve.dbo.Agent AS EAD ON P.POL_Agent_ID = EAD.Agent_Id LEFT OUTER JOIN
             Evolve.dbo.InsurerGroup AS IGY ON EAD.Agt_Insurer = IGY.InsurerGroup_Id AND IGY.IGY_Deleted = 0 LEFT OUTER JOIN
             Evolve.dbo.SalesAgents AS SA ON P.POL_AgentSalesConsultant = SA.SalesAgents_ID LEFT OUTER JOIN
             Evolve.dbo.ReferencePolicyOwner AS RPO ON P.POL_Owner_ID = RPO.ReferencePolicyOwner_ID LEFT OUTER JOIN
             Evolve.dbo.ReferencePaymentMethod AS RPM ON P.POL_PaymentMethod_ID = RPM.ReferencePaymentMethod_ID LEFT OUTER JOIN
             Evolve.dbo.ReferencePaymentFrequency AS RPF ON P.POL_PaymentFrequency_ID = RPF.ReferencePaymentFrequency_ID LEFT OUTER JOIN
             Evolve.dbo.ReferencePolicyStatus AS PS ON P.POL_Status = PS.PolicyStatus_ID LEFT OUTER JOIN
             Evolve.dbo.ReferencePlatform AS RPL ON P.POL_SourcePlatform_ID = RPL.Platform_Id LEFT OUTER JOIN
             Evolve.dbo.ReferencePolicySource AS rps ON P.POL_PolicySource_ID = rps.PolicySource_ID LEFT OUTER JOIN
                 (SELECT RN.ReferenceNumber_Id, RN.RNR_CreateUser_ID, RN.RNR_CreateDate, RN.RNR_UpdateUser_ID, RN.RNR_UpdateDate, RN.RNR_Deleted, RN.RNR_ItemReferenceNumber, RN.RNR_ItemType_Id, RN.RNR_NumberType_Id, RN.RNR_Number, RN.RNR_AllowEdit, 
                              RN.RNR_AllowDelete, RNT.ReferenceNumberType_Id, RNT.RNT_ItemType_Id, RNT.RNT_Description, RNT.RNT_AllowMultiple, RNT.RNT_Deleted, RNT.RNT_AllowDuplicates, RNT.RNT_Order, RNT.RNT_AllowEdit, RNT.RNT_Mandate_ID
                 FROM    Evolve.dbo.ReferenceNumber AS RN INNER JOIN
                              Evolve.dbo.ReferenceNumberType AS RNT ON RN.RNR_NumberType_Id = RNT.ReferenceNumberType_Id AND RN.RNR_NumberType_Id = 143) AS RN_1 ON P.Policy_ID = RN_1.RNR_ItemReferenceNumber AND RN_1.RNR_ItemType_Id = 2 LEFT OUTER JOIN
                 (SELECT PGI_Policy_ID, SUM(ISNULL(PGI_AutoPremium, 0) * (1 + ISNULL(PGI_Discount, 0) / 100)) AS PGI_AutoPremium
                 FROM    Evolve.dbo.PolicyGenericItem AS PGI
                 GROUP BY PGI_Policy_ID) AS PGI_1 ON P.Policy_ID = PGI_1.PGI_Policy_ID LEFT OUTER JOIN
                 (SELECT PMI_Policy_ID, CAST(SUM(CAST(ISNULL(PMI_AutoPremium, 0) * (1 + ISNULL(PMI_Discount, 0) / 100) AS decimal(20, 2))) AS decimal(20, 2)) AS PMI_AutoPremium
                 FROM    Evolve.dbo.PolicyMotorItem AS PMI
                 GROUP BY PMI_Policy_ID) AS PMI_1 ON P.Policy_ID = PMI_1.PMI_Policy_ID LEFT OUTER JOIN
                 (SELECT PCI_Policy_ID, CAST(SUM(CAST(ISNULL(PCI_AutoPremium, 0) * (1 + ISNULL(PCI_Discount, 0) / 100) AS decimal(20, 2))) AS decimal(20, 2)) AS PCI_AutoPremium
                 FROM    Evolve.dbo.PolicyCreditShortfallItem AS PCI
                 GROUP BY PCI_Policy_ID) AS PCI_1 ON P.Policy_ID = PCI_1.PCI_Policy_ID LEFT OUTER JOIN
                 (SELECT PCI_Policy_ID, CAST(SUM(CAST(ISNULL(PCI_AutoPremium, 0) * (1 + ISNULL(PCI_Discount, 0) / 100) AS decimal(20, 2))) AS decimal(20, 2)) AS PCI_AutoPremium
                 FROM    Evolve.dbo.PolicyCreditLifeItem AS PCL
                 GROUP BY PCI_Policy_ID) AS PCL_1 ON P.Policy_ID = PCL_1.PCI_Policy_ID LEFT OUTER JOIN
                 (SELECT PPA_Policy_ID, CAST(SUM(CAST(ISNULL(PPA_AutoPremium, 0) * (1 + ISNULL(PPA_Discount, 0) / 100) AS decimal(20, 2))) AS decimal(20, 2)) AS PPA_AutoPremium
                 FROM    Evolve.dbo.PolicyPAItem AS PPA
                 GROUP BY PPA_Policy_ID) AS PPA_1 ON P.Policy_ID = PPA_1.PPA_Policy_ID LEFT OUTER JOIN
             Evolve.dbo.Arrangement AS AR ON P.POL_Arrangement_ID = AR.Arrangement_Id LEFT OUTER JOIN
             Evolve.dbo.ReferenceFinanceHouse AS RFH ON P.POL_FinanceHouse_ID = RFH.ReferenceFinanceHouse_ID LEFT OUTER JOIN
             Evolve.dbo.Agent AS AGT2 ON P.POL_PrimaryAgent_ID = AGT2.Agent_Id LEFT OUTER JOIN
             Evolve.dbo.ReferenceBulkingInstitution AS RBI ON P.POL_BulkInstitution_ID = RBI.BulkingInstitution_ID LEFT OUTER JOIN
             Evolve.dbo.Branding AS DBR ON P.POL_Branding_ID = DBR.Branding_ID LEFT OUTER JOIN
             Evolve.dbo.BankLink AS BL ON P.Policy_ID = BL.BKL_ReferenceNumber AND BL.BKL_ReferenceType = 2 AND BL.BKL_Default = 1 LEFT OUTER JOIN
             Evolve.dbo.BankDetails AS BNK ON BNK.BankDetails_ID = BL.BKL_BankDetails_ID LEFT OUTER JOIN
             Evolve.dbo.BankAccountType AS BAT ON BNK.BNK_BankAccountType_ID = BAT.BankAccountType_ID AND BAT.BAT_Deleted = 0 LEFT OUTER JOIN
             Evolve.dbo.ReferenceCellCaptive AS RCC ON RCC.ReferenceCellCaptive_Code = AR.ARG_CellCaptive LEFT OUTER JOIN
                 (SELECT ITS_Policy_ID, SUM(ITS_Premium) AS Total_Summary_Premium, SUM(CASE WHEN isnull(ITS_ProductFee_ID, '') <> '' THEN isnull(ITS_Premium, 0) ELSE 0 END) AS Fees
                 FROM    Evolve.dbo.ItemSummary
                 WHERE (ISNULL(ITS_Deleted, 0) = 0)
                 GROUP BY ITS_Policy_ID) AS Prem_Sum ON P.Policy_ID = Prem_Sum.ITS_Policy_ID
WHERE (P.POL_Deleted = 0)
GROUP BY SU.USR_Description, RN_1.RNT_Description, RN_1.RNR_Number, P.POL_PolicyNumber, PS.POS_Description, P.POL_Description, CLI.CLI_ClientNumber, CLI.CLI_Initials, CLI.CLI_Name, CLI.CLI_Surname, CLI.CLI_MaskedIDNumber, CLI.CLI_MaskedPassportNumber, 
             CLI.CLI_CompanyName, CLI.CLI_CompanyRegistration, CLI.CLI_VATNumber, PRD.PRD_Name, PRO.PRO_Description, RTF.RTF_TermPeriod, P.POL_StartDate, P.POL_ReceivedDate, P.POL_SoldDate, P.POL_EndDate, P.POL_RenewalDate, P.POL_AnniversaryDate, EAD.Agt_Name, 
             EAD.Agt_MigrationAgentNumber, SA.SAG_AgentName, RPO.RPO_Description, rps.RPS_Description, RPM.RPM_Description, CASE WHEN RTF_Description IN ('Monthly', 'Annual') THEN RTF_Description ELSE 'Term' END, P.POL_DebitDay, P.POL_VatableIndicator, P.POL_VATNumber, 
             AR.ARG_ArrangementNumber, RFH.RFH_Description, P.POL_FinanceNumber, P.POL_FirstCollectionDate, P.POL_OriginalStartDate, P.POL_FirstPaymentStart, P.POL_MaturityDate, P.POL_SignedDate, P.POL_Version, AGT2.Agt_MigrationAgentNumber, RBI.RBI_Description, 
             P.POL_ConsecutiveUnmetCount, P.POL_LifetimeUnmetCount, DBR.DBR_Name, BAT.BAT_Description, BNK.BNK_AccountHolder, BNK.BNK_Bank, BNK.BNK_Branch, BNK.BNK_BranchCode, BNK.BNK_MaskedAccountNo, BNK.BNK_BankType, Prem_Sum.Total_Summary_Premium, 
             P.POL_IsMigrated, P.Policy_ID, IGY.IGY_Name, RCC.RCC_Description, P.POL_Client_ID, P.POL_Agent_ID, P.POL_FinanceTerm_ID, P.POL_CreateDate, P.POL_TIAConsecutiveUnmetCount, P.POL_TIALifetimeUnmetCount, P.POL_Product_ID, P.POL_ProductVariantLevel1_ID, 
             P.POL_ProductVariantLevel2_ID, P.POL_ProductVariantLevel3_ID, P.POL_ProductVariantLevel4_ID, RPG.PDG_Description, RPL.PLT_Description, P.POL_PolicyTerm, SU.USR_FirstName + ' ' + SU.USR_Surname, SU2.USR_FirstName + ' ' + SU2.USR_Surname, 
             CASE WHEN isnull(POL_IsMigrated, 0) = '1' THEN 'Yes' ELSE 'No' END, CASE WHEN isnull(EAD.Agt_RevenueType, 9) = 0 THEN 'Gross' WHEN isnull(EAD.Agt_RevenueType, 9) = 1 THEN 'Nett' ELSE 'Other' END, ins.INS_InsurerName