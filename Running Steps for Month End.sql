-- --SELECT *
-- --  FROM [lpp].[dbo].[pricingModelPoints] -- pricingModelPoints -- pricingMultDecrements -- pricingDeathBenefits -- pricingInstallmentBenefits -- pricingModelPointIterationResults

 --EXEC pricingStep1GenerateModelPointData -- 8 Seconds --
 --    @valuationmonth = '2025-01-01',    -- Set to January for the year (as per comment)
 --    @interesttype = 'Fixed',      -- Or your interest type
 --    @sumassured = 100000,              -- Sum assured amount
 --    @radix = 100000,                    -- Starting population seen in data
 --    @mortalityfactor = 0.8,            -- globalassumptions (SA85-90 factor)
 --    @aidsfactor = 0.025                -- globalassumptions (AIDS factor)

-- EXEC pricingStep2GenerateMultipleDecrementTable -- 4 Seconds --
--     @permanentdisabilityrate = 0.1503,
--     @criticalillnessrate = 0.168;

-- EXEC pricingStep3CalcDeathPDandCICostOfBenefit -- 2 Seconds --
--     @funeralbenefit = 3000,
--     @interest = 0.06,
--     @allowforballoon = 1;

-- EXEC pricingStep4InstallmentCoverCostOfBenefits -- 7 Seconds --
--     @tempdisabilityrate = 0.000015167900000001492,    -- globalassumptions: 'Temporary Disability Factor = 0,000182'
--     @retrenchmentrate = 0.000416667,       -- globalassumptions: 'Retrenchment Factor = 0,01154'  
--     @maxretrenchmentage = 65,          
--     @maxinstallments = 6,              
--     @interest = 0.06,                  
--     @allowforballoon = 1               

-- EXEC pricingStep5ModelPointOfficePremium --  10 Hours -- server disconnect
--     @BinderFee = 0.09,
--     @OutsourceFee = 0.02,
--     @LicenseFee = 0.01,
--     @Commission = 0.05,
--     @BurnRate = 0.02,
--     @MaxIterations = 50;

Use lpp
go

EXEC produceHollardValuationExtract -- 1.5 hours --
    @valuationDate = '2025-10-01'

Select v.*, [RV_Known]	DataEnriched, [RV_Ind]	BalloonIndicator,   [ResidualAmount] Balloon
from vw_HollardCLExtract v

left join Balloons
on  [Policy Number] = [POL_PolicyNumber]
where [valuation month] = '31-Oct-2025'



-- EXEC calculateHollard -- 45 mins --
--     @valuationDate = '2025-10-01',
--     @InterestType = 'Fixed',
--     @MortalityMargin = 0,
--     @CriticalIllnessMargin = 0,
--     @PermanentDisabilityMargin = 0,
--     @ExpenseMargin = 0,
--     @ExpenseInflationMargin = 0.,
--     @retrenchmentMargin = 0,
--     @tempDisabilityMargin = 0,
--     @lapseMargin = 0,
--     @CovidShock = 0,
--     @CovidShockPeriod = 0;


