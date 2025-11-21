import pandas as pd
from scipy.optimize import minimize
from scipy.stats import weibull_min

# Constants
DISCOUNT_RATE_MONTHLY = (1 + 0.08) ** (1 / 12) - 1  # Convert 8% annual to monthly discount factor
RISK_FACTOR = 1.05  # 5% increase for uncertainty adjustment

old_time_months = 24
new_time_months = 36
old_mileage = 100000
new_mileage = 200000

def weibull_objective(params, limit, claim_freq, coverage_months, target_risk_premium):
    """Objective function to estimate Weibull shape and scale parameters."""
    k, l = params
    expected_loss = (l * weibull_min.mean(k, scale=l)) * claim_freq * (coverage_months / 12)
    return abs(expected_loss - target_risk_premium)

def calculate_risk_premium_weibull(k, l, claim_freq, coverage_months):
    """Calculates the risk premium using the Weibull method."""
    expected_loss = (l * weibull_min.mean(k, scale=l)) * claim_freq * (coverage_months / 12)
    return expected_loss * RISK_FACTOR

# Input paths
input_excel_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Finance/2. Finance/5. Actuaries/0. Products/RStudio_Python Inputs/weibull_optimization.xlsx"
output_path_weibull = "C:/Users/edwardl/OneDrive - Motus Corporation/Finance/2. Finance/5. Actuaries/0. Products/RStudio_Python Outputs/optimized_weibull_params.csv"
output_path_claims = "C:/Users/edwardl/OneDrive - Motus Corporation/Finance/2. Finance/5. Actuaries/0. Products/RStudio_Python Outputs/claims_by_month_transposed.csv"

# Load Excel data
df_updated = pd.read_excel(input_excel_path)

# Keep only necessary columns
expected_columns = ["Benefit Name", "Limit", "Start", "End", "Annualized Claim Frequency", "Risk Premium"]
df_updated = df_updated[expected_columns]

# Prepare containers
optimized_params_updated = []
claims_by_month_data = []

# Process each benefit
for _, row in df_updated.iterrows():
    benefit_name = row["Benefit Name"]
    limit = row["Limit"]
    claim_freq = row["Annualized Claim Frequency"]
    start_month = row["Start"]
    end_month = row["End"]
    coverage_months = end_month - start_month + 1
    target_risk_premium = row["Risk Premium"]

    # Initial guess
    initial_guess = [2.0, 100]

    # Optimize Weibull parameters
    result = minimize(
        weibull_objective,
        initial_guess,
        args=(limit, claim_freq, coverage_months, target_risk_premium),
        method="Nelder-Mead"
    )

    k_opt, l_opt = result.x

    # Calculate Weibull risk premium
    weibull_risk_premium = calculate_risk_premium_weibull(k_opt, l_opt, claim_freq, coverage_months)

    # Linear risk adjustment
    linear_risk_adjustment = (new_time_months / old_time_months + new_mileage / old_mileage) / 2

    # Weibull-based risk adjustment
    F_36 = weibull_min.cdf(new_time_months, k_opt, scale=l_opt)
    F_24 = weibull_min.cdf(old_time_months, k_opt, scale=l_opt)
    weibull_risk_adjustment = F_36 / F_24 if F_24 > 0 else float("inf")

    # Store final results
    optimized_params_updated.append((
        benefit_name,
        k_opt,
        l_opt,
        coverage_months,
        weibull_risk_premium,
        linear_risk_adjustment,
        weibull_risk_adjustment
    ))

    # Monthly breakdown
    monthly_claim_freq = [0] * 84
    expected_monthly_cost = [0] * 84
    increased_monthly_cost = [0] * 84

    for month in range(start_month - 1, end_month):
        monthly_claim_freq[month] = claim_freq / 12
        expected_monthly_cost[month] = (l_opt * weibull_min.mean(k_opt, scale=l_opt)) * monthly_claim_freq[month] * RISK_FACTOR
        increased_monthly_cost[month] = expected_monthly_cost[month] * ((1 + DISCOUNT_RATE_MONTHLY) ** (month + 1))

    # Store monthly breakdown
    claims_by_month_data.append([benefit_name + " Claim Frequency", sum(monthly_claim_freq)] + monthly_claim_freq)
    claims_by_month_data.append([benefit_name + " Expected Cost Per Month", sum(expected_monthly_cost)] + expected_monthly_cost)
    claims_by_month_data.append([benefit_name + " Increased Cost Per Month", sum(increased_monthly_cost)] + increased_monthly_cost)

# Final DataFrame for Weibull results
optimized_df_updated = pd.DataFrame(
    optimized_params_updated,
    columns=[
        "Benefit Name",
        "Optimized Weibull Shape (κ)",
        "Optimized Weibull Scale (λ)",
        "Coverage Months",
        "Weibull Risk Premium",
        "Linear Risk Adjustment (36mo/200k)",
        "Weibull Risk Adjustment (F(36)/F(24))"
    ]
)

# Final DataFrame for monthly claim costs
months = ["Total"] + list(range(1, 85))
claims_by_month_final_df = pd.DataFrame(claims_by_month_data, columns=["Benefit Name"] + months)

# Save results
optimized_df_updated.to_csv(output_path_weibull, index=False)
claims_by_month_final_df.to_csv(output_path_claims, index=False)

print(f"File saved to: {output_path_weibull}")
print(f"File saved to: {output_path_claims}")
