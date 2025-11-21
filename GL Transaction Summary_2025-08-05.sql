Select 
		ATS_DisplayNumber [Display Number], 
		INS_InsurerName [Insurer], 
		ATS_Description [Description], 
		ATT_Description [Transaction Type], 
		Main.GLC_GlCode MainGlCode, 
		Main.GLC_Description MainGlDescription, 
		isnull(VAT.GLC_GlCode,'') VatGlCode, 
		isnull(VAT.GLC_Description,'') VATGlDescription, 
		INS_GLCode [Insurer Code], 
		Division.SRN_GLCode [Division], 
		case when isnull(main.GLC_DepartmentOverride,'') = '' then Branch.SRN_GLCode else main.GLC_DepartmentOverride end [SalesBranch], 
		PrimaryAgents.Agt_Name  As [Primary Agent Name],
		SubAgents.Agt_Name As [Sub Agent Name],
		RCC_GLCode [CellCaptive], 
		PRD_GLCode [Product], 
		main.GLC_Category [Category], 
		ATS_TransactionNumber [Transaction number], 
		APY_PartyNumber [Party Number], 
		APY_Name [Party Name], 
		APT_Description [Party Type],
		DBT_Description [Disbursement Type],
		IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate) [Effective Date],
		--ATS_CreateDate [Create Date], 
		--ATS_EffectiveDate [Effective Date],
		ATS_EffectiveDate [Effective Date], 
		case when ATN_VATAmount = 0 then 1 else 2 end VATType, 
		--case when ATN_VATAmount = 0 then dbo.GPTaxSchedule(ATS_Insurer_Id,Main.glc_VATType) ELSE Main.glc_VATType END GPVATType, 
		(ATN_GrossAmount) GrossAmount, 
		(ATN_VATAmount) VATAmount, 
		(ATN_NettAmount) NettAmount 
	from 
		AccountTransactionSet 
			left outer join Insurer on ATS_Insurer_Id = Insurer_Id 
			left outer join Product on ATS_Product_Id = Product_Id 
			left outer join ReferenceCellCaptive on ATS_CellCaptive_Id = ReferenceCellCaptive.ReferenceCellCaptive_Code 
			left outer join SalesBranch Division on ATS_Division = Division.SalesRegion_ID 
			left outer join SalesBranch Branch on ATS_SalesBranch = Branch.SalesRegion_ID
			left join Policy on ATS_DisplayNumber = POL_PolicyNumber
		    Left join Agent PrimaryAgents(nolock) on POL_PrimaryAgent_ID = Agent_Id
            Left join Agent SubAgents(nolock) on POL_Agent_ID = SubAgents.Agent_Id,
		AccountTransaction 
			left outer join ReferenceGLCode Main on ATN_GLCode_ID = Main.GlCode_ID 
			left outer join ReferenceGLCode VAT on ATN_GLCodeVAT_ID = VAT.GlCode_ID 
			left outer join AccountParty Party on AccountParty_Id = ATN_AccountParty_ID 
			LEFT JOIN AccountPartyType on AccountPartyType_Id = APY_PartyType_ID
			Left join DisbursementType on ATN_DisbursementType_ID = DisbursementType_Id

			LEFT JOIN AccountTransactionType on ATN_AccountTransactionType_ID = AccountTransactionType_Id 
	where ATN_AccountTransactionSet_ID = AccountTransactionSet_ID 
		and ATN_GrossAmount <> 0 
		--AND IIF(ATS_CreateDate > ATS_EffectiveDate,ATS_CreateDate, ATS_EffectiveDate) >= {FromDate}
		--AND IIF(ATS_CreateDate > ATS_EffectiveDate,ATS_CreateDate, ATS_EffectiveDate) <= {ToDate}
		--AND IIF((DATEDIFF(Month, ATS_CreateDate, ATS_EffectiveDate) > 2 OR DATEDIFF(Month, ATS_CreateDate, ATS_EffectiveDate) < -2),
		--	ATS_EffectiveDate,
		--	IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate)
		--) >= {FromDate}
		--AND IIF((DATEDIFF(Month, ATS_CreateDate, ATS_EffectiveDate) > 2 OR DATEDIFF(Month, ATS_CreateDate, ATS_EffectiveDate) < -2),
		--	ATS_EffectiveDate,
		--	IIF(ATS_CreateDate > ATS_EffectiveDate, ATS_CreateDate, ATS_EffectiveDate)
		--) <=  {ToDate}
		{FromDate}
		{ToDate}
		{Insurer}
ORDER BY ATS_DisplayNumber DESC