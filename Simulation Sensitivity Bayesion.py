# Truck Warranty Claim Simulation Sensitivity Analysis (Bayesian Enhanced)
import pandas as pd
import numpy as np
import pymc as pm
import arviz as az
import multiprocessing as mp


def run_single_simulation(avg_claim, policy_df, df_sob):
    sigma_val = 0.6
    mu_val = np.log(avg_claim) - (sigma_val**2 / 2)

    with pm.Model() as model:
        freq = pm.Beta("freq", alpha=2, beta=18)
        n_policies = len(policy_df)
        exp_months_data = policy_df["Exposure Months"].values.astype("float32")
        premium_data = policy_df["Scaled Premium"].values.astype("float32")

        exposure_months = pm.Data("exposure_months", exp_months_data)
        premiums = pm.Data("premiums", premium_data)

        commission = 0.125 * premiums
        binder_fee = 0.09 * premiums
        insurer_fee = 0.025 * premiums
        inspection_fee = 1000.0
        operational_profit = 0.21 * premiums
        total_expenses = commission + binder_fee + insurer_fee + inspection_fee + operational_profit

        prob_claim = freq * (exposure_months / 12.0)
        claim_occurred = pm.Bernoulli("claim_occurred", p=prob_claim, shape=n_policies)

        raw_severity = pm.Lognormal("raw_severity", mu=mu_val, sigma=sigma_val, shape=n_policies)

        chosen_benefits = df_sob.sample(n=n_policies, replace=True).reset_index(drop=True)
        limits = chosen_benefits["Limit"].values.astype("float32")
        floors = chosen_benefits["Min Claim"].values.astype("float32")

        capped_severity = pm.Deterministic("capped_severity",
            pm.math.minimum(pm.math.maximum(raw_severity, floors), limits)
        )

        claim_amount = pm.Deterministic("claim_amount", capped_severity * claim_occurred)
        total_claim_cost = pm.Deterministic("total_claim_cost", pm.math.sum(claim_amount))
        total_expense_cost = pm.Deterministic("total_expense_cost", pm.math.sum(total_expenses))
        burn_rate = pm.Deterministic("burn_rate", total_claim_cost / pm.math.sum(premiums))
        net_result = pm.Deterministic("net_result", pm.math.sum(premiums) - total_claim_cost - total_expense_cost)
        avg_net_result_per_policy = pm.Deterministic("avg_net_result_per_policy", net_result / n_policies)

        trace = pm.sample(
            1000,
            tune=1000,
            target_accept=0.9,
            return_inferencedata=True,
            chains=1,
            cores=1,
            progressbar=False
        )

    burn_rate_samples = trace.posterior["burn_rate"].values.flatten()
    claim_amount_samples = trace.posterior["claim_amount"].values.reshape(-1, n_policies)
    avg_net_result_samples = trace.posterior["avg_net_result_per_policy"].values.flatten()
    severity_samples = claim_amount_samples[claim_amount_samples > 0]

    avg_severity_per_claim = severity_samples.mean()
    loss_pct = (avg_net_result_samples < 0).mean() * 100
    burn95 = np.percentile(burn_rate_samples, 95)

    score = (
        abs(avg_severity_per_claim - 150000) / 150000 +
        0.01 * loss_pct +
        0.001 * burn95
    )

    return {
        "Target Avg Severity (R)": avg_claim,
        "Mean Cost per Policy (R)": round(claim_amount_samples.sum(axis=1).mean() / n_policies, 2),
        "Burn Rate Mean": round(burn_rate_samples.mean() * 100, 2),
        "Burn Rate 95th": round(burn95 * 100, 2),
        "95% VaR": round(np.percentile(claim_amount_samples.sum(axis=1)/1000, 95), 2),
        "Loss-Making % (Mean)": round(loss_pct, 2),
        "Avg Severity per Claim (R)": round(avg_severity_per_claim, 2),
        "Avg Net Result per Policy (R)": round(avg_net_result_samples.mean(), 2),
        "Likelihood Score (lower is better)": round(score, 6)
    }


def run_severity_sensitivity():
    policy_df = pd.read_excel("C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/Truck/claims_policy_data.xlsx")
    sob_df = pd.read_excel("C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/Truck/schedule_of_benefits.xlsx")

    policy_df["Inception Date"] = pd.to_datetime(policy_df["Inception Date"])
    policy_df["Expiry Date"] = pd.to_datetime(policy_df["Expiry Date"])
    today = pd.Timestamp.today()

    policy_df["Exposure Months"] = (
        (policy_df["Expiry Date"].clip(upper=today) - policy_df["Inception Date"]).dt.days / 30.44
    ).clip(lower=0).apply(np.ceil)
    policy_df["Scaled Premium"] = (policy_df["Exposure Months"] / 60.0) * policy_df["Premium"]
    policy_df = policy_df.dropna(subset=["Exposure Months", "Scaled Premium"])

    df_sob = sob_df.dropna(subset=["Benefit Name", "Limit", "Start", "End"]).copy()
    df_sob["Limit"] = df_sob["Limit"].astype(float)
    df_sob["Min Claim"] = df_sob["Limit"].apply(lambda x: max(0.05 * x, 5000))

    target_averages = [50000, 70000, 90000, 110000, 130000, 150000, 170000]
    args = [(avg, policy_df, df_sob) for avg in target_averages]

    with mp.get_context("spawn").Pool(processes=mp.cpu_count()) as pool:
        results = pool.starmap(run_single_simulation, args)

    summary_df = pd.DataFrame(results)

    # Determine the scenario closest to the median of Loss-Making % (Mean)
    median_loss_pct = summary_df["Loss-Making % (Mean)"].median()
    closest_idx = (summary_df["Loss-Making % (Mean)"].sub(median_loss_pct).abs()).idxmin()
    summary_df["Most Likely by Loss %"] = ""
    summary_df.loc[closest_idx, "Most Likely by Loss %"] = "Yes"

    avg_loss_pct = summary_df["Loss-Making % (Mean)"].mean()
    closest_idx = (summary_df["Loss-Making % (Mean)"].sub(avg_loss_pct).abs()).idxmin()
    summary_df["Most Likely by Loss %"] = ""
    summary_df.loc[closest_idx, "Most Likely by Loss %"] = "Yes"

    summary_df.sort_values("Target Avg Severity (R)", inplace=True)
    summary_df.to_excel("C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Truck/truck_warranty_severity_sensitivity_Bayesion.xlsx",index=False)
    print("Severity sensitivity simulation completed and saved. Scenario closest to average loss %:")
    print(summary_df.loc[closest_idx])


if __name__ == "__main__":
    run_severity_sensitivity()