# Truck Warranty Claim Simulation Sensitivity Analysis (Classical Model with Varying Average Severities)
import pandas as pd
import numpy as np

# Load inputs
policy_df = pd.read_excel("C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/Truck/claims_policy_data.xlsx")
sob_df = pd.read_excel("C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/Truck/schedule_of_benefits.xlsx")

# Preprocess policy data
policy_df["Inception Date"] = pd.to_datetime(policy_df["Inception Date"])
policy_df["Expiry Date"] = pd.to_datetime(policy_df["Expiry Date"])
today = pd.Timestamp.today()

policy_df["Exposure Months"] = (
    (policy_df["Expiry Date"].clip(upper=today) - policy_df["Inception Date"]).dt.days / 30.44
).clip(lower=0).apply(np.ceil)

# Normalize premiums and inspection fee for actual exposure out of 60-month term
policy_df["Scaled Premium"] = (policy_df["Exposure Months"] / 60.0) * policy_df["Premium"]
policy_df["Scaled Inspection Fee"] = (policy_df["Exposure Months"] / 60.0) * 1000.0

# Preprocess SOB
df_sob = sob_df.dropna(subset=["Benefit Name", "Limit", "Start", "End"]).copy()
df_sob["Limit"] = df_sob["Limit"].astype(float)
df_sob["Min Claim"] = df_sob["Limit"].apply(lambda x: max(0.05 * x, 5000))

# Target mean severities and derived lognormal means (sigma = 0.5)
target_means = [50000, 70000, 90000, 110000, 130000, 150000, 170000]
sigma = 0.5
mu_values = [np.log(m) - 0.5 * sigma ** 2 for m in target_means]
frequencies = [0.025, 0.05, 0.10, 0.15, 0.20, 0.25, 0.30]
n_simulations = 1000

# Run simulations for each severity level
sensitivity_results = []
n_policies = len(policy_df)

for mu, avg_target in zip(mu_values, target_means):
    for freq in frequencies:
        mean_costs, burn_rates, loss_pcts, var_95s, net_results, severity_per_claims = [], [], [], [], [], []

        for _ in range(n_simulations):
            total_claims = []
            total_expenses = []
            total_premiums = []
            losses = 0
            num_claims = 0

            for _, policy in policy_df.iterrows():
                months = policy["Exposure Months"]
                prob = freq * (months / 12)
                premium = (months / 60) * policy["Premium"]

                # Expense calculation
                commission = 0.125 * premium
                binder_fee = 0.09 * premium
                insurer_fee = 0.025 * premium
                inspection_fee = (months / 60) * 1000
                operational_profit = 0.21 * premium
                expenses = commission + binder_fee + insurer_fee + inspection_fee + operational_profit

                if np.random.rand() < prob:
                    benefit = df_sob.sample(1).iloc[0]
                    severity = np.random.lognormal(mean=mu, sigma=sigma)
                    severity = min(severity, benefit["Limit"])
                    severity = max(severity, benefit["Min Claim"])
                    total_claims.append(severity)
                    num_claims += 1

                    if severity > premium:
                        losses += 1
                else:
                    total_claims.append(0)

                total_expenses.append(expenses)
                total_premiums.append(premium)

            total_claim_cost = sum(total_claims)
            total_expense_cost = sum(total_expenses)
            total_premium_collected = sum(total_premiums)

            avg_cost = np.mean(total_claims)
            burn_rate = total_claim_cost / total_premium_collected
            var_95 = np.percentile(total_claims, 95)
            loss_pct = losses / n_policies
            net_result = (total_premium_collected - total_claim_cost - total_expense_cost) / n_policies
            avg_severity_per_claim = total_claim_cost / max(num_claims, 1)

            mean_costs.append(avg_cost)
            burn_rates.append(burn_rate)
            loss_pcts.append(loss_pct)
            var_95s.append(var_95)
            net_results.append(net_result)
            severity_per_claims.append(avg_severity_per_claim)

        sensitivity_results.append({
            "Target Avg Claim": f"R{avg_target:,}",
            "Frequency": f"{int(freq * 100)}%",
            "Mean Cost per Policy (R)": f"{np.mean(mean_costs):,.2f}",
            "Burn Rate Mean": f"{np.mean(burn_rates):.2%}",
            "Burn Rate 95th": f"{np.percentile(burn_rates, 95):.2%}",
            "95% VaR": f"{np.mean(var_95s):,.2f}",
            "Loss-Making % (Mean)": f"{np.mean(loss_pcts):.2%}",
            "Avg Severity per Claim (R)": f"{np.mean(severity_per_claims):,.2f}",
            "Avg Net Result per Policy (R)": f"{np.mean(net_results):,.2f}"
        })

# Save output
final_df = pd.DataFrame(sensitivity_results)

# Clean numeric values for loss-making % to identify most likely scenario at R150,000
clean_df = final_df.copy()
clean_df["Target Avg Claim (R)"] = clean_df["Target Avg Claim"].str.replace("R", "").str.replace(",", "").astype(int)
clean_df["Loss-Making % (Mean)"] = clean_df["Loss-Making % (Mean)"].str.replace("%", "").astype(float)

# Identify most likely scenario based only on average Mean Cost per Policy
clean_df["Mean Cost per Policy"] = clean_df["Mean Cost per Policy (R)"].str.replace(",", "").astype(float)
mean_value = clean_df["Mean Cost per Policy"].mean()
closest_index = (clean_df["Mean Cost per Policy"] - mean_value).abs().idxmin()


final_df["Most Likely Scenario"] = ""
final_df.loc[closest_index, "Most Likely Scenario"] = "Yes"

final_df.to_excel("C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Truck/truck_warranty_classical_sensitivity_by_severity.xlsx", index=False)
print("Classical sensitivity simulation with varying average claim costs completed and exported to Excel.")


