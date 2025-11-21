import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import seaborn as sns
import pymc as pm
import arviz as az
import os
import pytensor.tensor as pt
from pytensor.tensor import gammaln
from scipy.stats import beta
import multiprocessing
import warnings


#Need to update frequency calculations it is not right

warnings.filterwarnings("ignore")

np.random.seed(42)
months = 84

USE_FULL_POSTERIOR_SAMPLING = True
APPLY_SOB_CAP = True
ALLOW_MULTIPLE_CLAIMS_PER_POLICY = True  # Toggle to simulate multiple claims per pseudo-policy  # Toggle to apply schedule of benefit cap


def sample_gb2(a, b, p, q, size=1):
    u = beta.rvs(p, q, size=size)
    return b * (u / (1 - u)) ** (1 / a)


def main():
    input_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/7 year importer/"
    output_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Bayesian MCMC 7 year importer/"
    risk_summary_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Existing Claim Data Analyses 7 year importer/"
    os.makedirs(output_path, exist_ok=True)

    claims_df = pd.read_csv(os.path.join(risk_summary_path, "claims_policy_data_inflated.csv"))
    claims_df = claims_df[claims_df["Claim Amount (Inflated)"] > 0].dropna(subset=["Reason for Claim", "Vehicle Make"])
    print(f"Claims after filtering: {len(claims_df)}")

    upper_threshold = claims_df["Claim Amount (Inflated)"].quantile(0.995)
    claims_df = claims_df[claims_df["Claim Amount (Inflated)"].le(upper_threshold)]

    sob_df = pd.read_excel(os.path.join(input_path, "schedule_of_benefits.xlsx"))
    sob_map = sob_df.groupby("Benefit Name")["Limit"].max().to_dict()
    print(f"Unique SOBs in map: {len(sob_map)}")
    claims_df["SOB Limit"] = claims_df["Reason for Claim"].map(sob_map)

    claims_df["Claim Reason Code"] = claims_df["Reason for Claim"].astype("category").cat.codes
    claims_df["Vehicle Make Code"] = claims_df["Vehicle Make"].astype("category").cat.codes

    claim_amounts = claims_df["Claim Amount (Inflated)"].values
    print(f"Claim Amounts shape: {claim_amounts.shape}")
    reason_idx = claims_df["Claim Reason Code"].values
    vehicle_idx = claims_df["Vehicle Make Code"].values
    sob_limits = claims_df["SOB Limit"].values

    n_reasons = claims_df["Claim Reason Code"].nunique()
    n_vehicles = claims_df["Vehicle Make Code"].nunique()

    cell_counts = claims_df.groupby(["Claim Reason Code", "Vehicle Make Code"]).size().unstack(fill_value=0)
    credibility_weights = cell_counts / (cell_counts + 30)
    credibility_weights = credibility_weights.reindex(index=range(n_reasons), columns=range(n_vehicles), fill_value=0)
    cred_data = credibility_weights.values

    def gb2_logp(x, a, b, p, q):
        betaln_val = gammaln(p) + gammaln(q) - gammaln(p + q)
        log_pdf = pt.log(a) + (a * p - 1) * pt.log(x) - a * p * pt.log(b) - betaln_val - (p + q) * pt.log1p(
            (x / b) ** a)
        return pt.switch(x > 0, log_pdf, -np.inf)

    with pm.Model() as model:
        mu_a = pm.HalfNormal("mu_a", sigma=5)
        mu_b = pm.HalfNormal("mu_b", sigma=50000)
        mu_p = pm.HalfNormal("mu_p", sigma=5)
        mu_q = pm.HalfNormal("mu_q", sigma=5)

        sigma_a = pm.HalfNormal("sigma_a", sigma=2)
        sigma_b = pm.HalfNormal("sigma_b", sigma=20000)
        sigma_p = pm.HalfNormal("sigma_p", sigma=2)
        sigma_q = pm.HalfNormal("sigma_q", sigma=2)

        a_raw = pm.HalfNormal("a_raw", sigma=sigma_a, shape=(n_reasons, n_vehicles))
        b_raw = pm.HalfNormal("b_raw", sigma=sigma_b, shape=(n_reasons, n_vehicles))
        p_raw = pm.HalfNormal("p_raw", sigma=sigma_p, shape=(n_reasons, n_vehicles))
        q_raw = pm.HalfNormal("q_raw", sigma=sigma_q, shape=(n_reasons, n_vehicles))

        cred_tensor = pm.Data("credibility", cred_data)

        a = mu_a * (1 - cred_tensor) + a_raw * cred_tensor
        b = mu_b * (1 - cred_tensor) + b_raw * cred_tensor
        p = mu_p * (1 - cred_tensor) + p_raw * cred_tensor
        q = mu_q * (1 - cred_tensor) + q_raw * cred_tensor

        obs = pm.CustomDist("obs", a[reason_idx, vehicle_idx], b[reason_idx, vehicle_idx], p[reason_idx, vehicle_idx],
                            q[reason_idx, vehicle_idx], logp=gb2_logp, observed=claim_amounts)

        trace = pm.sample(draws=8000, tune=1000, chains=4, target_accept=0.98, max_treedepth=20,
                          return_inferencedata=True, compute_convergence_checks=True, log_likelihood=True)
        az.to_netcdf(trace, os.path.join(output_path, "saved_trace.nc"))

    bayesian_df = claims_df.copy()

    if USE_FULL_POSTERIOR_SAMPLING:
        posterior = trace.posterior
        n_samples = posterior.sizes["chain"] * posterior.sizes["draw"]

        a_samples = posterior["a_raw"].stack(sample=("chain", "draw")).values
        b_samples = posterior["b_raw"].stack(sample=("chain", "draw")).values
        p_samples = posterior["p_raw"].stack(sample=("chain", "draw")).values
        q_samples = posterior["q_raw"].stack(sample=("chain", "draw")).values

        sim_values = []  # List to hold simulated values for known claims

        # Simulate claims for observed combinations
        for i in range(len(claim_amounts)):
            ridx = reason_idx[i]
            vidx = vehicle_idx[i]
            draw_idx = np.random.randint(n_samples)
            sim_val = sample_gb2(
                a_samples[ridx, vidx][draw_idx],
                b_samples[ridx, vidx][draw_idx],
                p_samples[ridx, vidx][draw_idx],
                q_samples[ridx, vidx][draw_idx],
                size=1
            )[0]
            if APPLY_SOB_CAP and not np.isnan(sob_limits[i]):
                sim_val = min(sim_val, sob_limits[i])
            sim_values.append(sim_val)

        simulated_values = np.array(sim_values)

        # Simulate claims per SOB using credibility-based volume
        inferred_claims = []
        pseudo_policy_id = 0
        sob_counts = claims_df['Reason for Claim'].value_counts()
        avg_sim_count = sob_counts.mean()

        for benefit, limit in sob_map.items():
            print(f"Processing SOB benefit: {benefit}, Limit: {limit}")
            if limit <= 0:
                continue
            count = sob_counts.get(benefit, 0)
            credibility = count / (count + 30)
            sim_count = int(np.round((credibility + 0.1) * 5)) if ALLOW_MULTIPLE_CLAIMS_PER_POLICY else 1
            for _ in range(sim_count):
                draw_idx = np.random.randint(n_samples)
                ridx, vidx = np.random.randint(n_reasons), np.random.randint(n_vehicles)
                sim_val = sample_gb2(
                    a_samples[ridx, vidx][draw_idx],
                    b_samples[ridx, vidx][draw_idx],
                    p_samples[ridx, vidx][draw_idx],
                    q_samples[ridx, vidx][draw_idx],
                    size=1
                )[0]
                sim_val = max(sim_val, 0.6 * limit)
                if sim_val < 3000:
                    sim_val = limit
                inferred_claims.append({
                    "Vehicle Make": "Unknown",
                    "Reason for Claim": benefit,
                    "Claim Amount": sim_val,
                    "Success": True,
                    "Source": "Inferred",
                    "Pseudo Policy ID": pseudo_policy_id
                })
                pseudo_policy_id += 1

        # Collect all simulated claims
        all_simulated_claims = []
        for i in range(len(simulated_values)):
            val = simulated_values[i]
            make = claims_df.iloc[i]["Vehicle Make"]
            reason = claims_df.iloc[i]["Reason for Claim"]
            sob_limit = claims_df.iloc[i]["SOB Limit"]
            success = not pd.isna(sob_limit) and val >= 0.6 * sob_limit
            if val < 3000:
                val = sob_limit
            all_simulated_claims.append({
                "Vehicle Make": make,
                "Reason for Claim": reason,
                "Claim Amount": val,
                "Success": success,
                "Source": "Observed"
            })

        # Add inferred claims for missing benefits
        all_simulated_claims.extend(inferred_claims)
        simulated_claims_df = pd.DataFrame(all_simulated_claims)
        print(f"Simulated claims count: {len(all_simulated_claims)}")
        print(f"Observed: {len([c for c in all_simulated_claims if c['Source'] == 'Observed'])}")
        print(f"Inferred: {len([c for c in all_simulated_claims if c['Source'] == 'Inferred'])}")
        csv_path = os.path.join(output_path, "All_Simulated_Claims.csv")
        simulated_claims_df.to_csv(csv_path, index=False)
        print(f"CSV saved to: {csv_path} — Exists? {os.path.exists(csv_path)}")
    else:
        raise ValueError(
            "USE_FULL_POSTERIOR_SAMPLING must be True because sample_posterior_predictive is not supported for CustomDist")

    bayesian_df["Claim Cost"] = simulated_values

    az.plot_trace(trace)
    plt.savefig(os.path.join(output_path, "Trace_Plots.png"), dpi=300)
    plt.close()

    az.plot_rank(trace)
    plt.savefig(os.path.join(output_path, "Rank_Plots.png"), dpi=300)
    plt.close()

    segment_summary = bayesian_df.groupby(['Vehicle Make', 'Reason for Claim'])['Claim Cost'].agg(
        ['count', 'mean', 'std', 'min', 'median', 'max', 'sum'])
    overall_summary = {"Mean Claim Cost": bayesian_df["Claim Cost"].mean()}
    stop_loss = {"Overall": bayesian_df["Claim Cost"].quantile(0.95)}

    claim_stats = pd.Series(simulated_values).describe(percentiles=[0.25, 0.5, 0.75])


    # Claim Frequency calculation'
    # Load actual policy-level exposure data
    exposure_df = pd.read_excel(
        os.path.join(risk_summary_path, "Exposure_Analysis_Unique_Policies.xlsx"),
        sheet_name="Policy Level Exposure"
    )

    # Calculate total exposure in months from unique policies
    total_exposure_months = exposure_df["Exposure Months"].sum()

    # Calculate adjusted claim frequency
    # Note: all_simulated_claims must already be defined before this
    adjusted_claim_frequency = len(all_simulated_claims) / (total_exposure_months / 12) * 100
    # -----------------------------------------

    summary_stats = {
        'Total Simulated Claims': len(all_simulated_claims),
        'Mean Claim Cost': claim_stats['mean'],
        '25th Percentile': claim_stats['25%'],
        'Median Claim Cost': claim_stats['50%'],
        '75th Percentile': claim_stats['75%'],
        'Max Claim Cost': claim_stats['max'],
        'VaR 95%': np.percentile(simulated_values, 95),
        'VaR 99%': np.percentile(simulated_values, 99),
        'TVaR 95%': simulated_values[simulated_values > np.percentile(simulated_values, 95)].mean(),
        'TVaR 99%': simulated_values[simulated_values > np.percentile(simulated_values, 99)].mean(),
        'Probability of Ruin (Zero)': np.mean(simulated_values <= 0) * 100,
        'Annualized Claim Frequency (%)': len(bayesian_df) / (total_exposure_months / 12) * 100,
        'Adjusted Claim Frequency (%)': adjusted_claim_frequency
    }

    ruin_thresholds = [25000, 40000, 50000, 60000, 75000, 100000]
    ruin_probs = {f"P(Claim > R{t:,})": np.mean(simulated_values > t) for t in ruin_thresholds}
    ruin_probs_df = pd.DataFrame.from_dict(ruin_probs, orient="index", columns=["Probability"])
    ruin_probs_df.to_excel(os.path.join(output_path, "Bayesian_GB2_Ruin_Probabilities.xlsx"))

    plt.figure(figsize=(8, 5))
    plt.plot(ruin_thresholds, [ruin_probs[f"P(Claim > R{t:,})"] for t in ruin_thresholds], marker='o')
    plt.title("Ruin Probability vs Reserve Threshold")
    plt.xlabel("Reserve Threshold (Rands)")
    plt.ylabel("Probability of Ruin")
    plt.grid(True)
    plt.tight_layout()
    plt.gca().xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'R{x / 1000:,.0f}k'))
    plt.savefig(os.path.join(output_path, "Bayesian_GB2_Ruin_Probability_Plot.png"), dpi=300)
    plt.close()

    # KDE Comparison with Risk Metrics
    original_claims = claims_df["Claim Amount (Inflated)"].dropna()
    bayesian_claims = simulated_values

    # Risk metrics
    VaR_95 = np.percentile(bayesian_claims, 95)
    VaR_99 = np.percentile(bayesian_claims, 99)
    TVaR_95 = bayesian_claims[bayesian_claims > VaR_95].mean()
    TVaR_99 = bayesian_claims[bayesian_claims > VaR_99].mean()

    plt.figure(figsize=(12, 7))
    sns.kdeplot(original_claims, color="gray", linewidth=1.5, label="Original KDE", fill=True, alpha=0.4)
    sns.kdeplot(bayesian_claims, color="purple", linewidth=1.5, label="Bayesian KDE", fill=True, alpha=0.4)

    # Vertical lines for risk metrics
    plt.axvline(VaR_95, color='red', linestyle='--', linewidth=2, label='VaR 95%')
    plt.axvline(VaR_99, color='blue', linestyle='--', linewidth=2, label='VaR 99%')
    plt.axvline(TVaR_95, color='green', linestyle='-.', linewidth=2, label='TVaR 95%')
    plt.axvline(TVaR_99, color='orange', linestyle='-.', linewidth=2, label='TVaR 99%')

    plt.title("Bayesian Risk Metrics vs Original KDE")
    plt.xlabel("Claim Cost")
    plt.ylabel("Density")
    plt.legend()
    plt.tight_layout()
    plt.savefig(os.path.join(output_path, "Bayesian_vs_Original_KDE.png"), dpi=300)
    plt.close()

    with pd.ExcelWriter(os.path.join(output_path, "Enhanced_Bayesian_Dashboard.xlsx"), engine="xlsxwriter") as writer:
        segment_summary.to_excel(writer, sheet_name="Segment Summary")
        pd.DataFrame.from_dict(overall_summary, orient="index", columns=["Value"]).to_excel(writer,
                                                                                            sheet_name="Risk Summary")
        pd.DataFrame.from_dict(stop_loss, orient="index", columns=["Stop-Loss Premium"]).to_excel(writer,
                                                                                                  sheet_name="Stop Loss")
        pd.DataFrame.from_dict(summary_stats, orient="index", columns=["Value"]).to_excel(writer,
                                                                                          sheet_name="Summary Statistics")

        # Add Source Summary
        source_stats = simulated_claims_df.groupby("Source")["Claim Amount"].agg(
            Total_Claims="count",
            Mean="mean",
            Median="median",
            VaR_95=lambda x: np.percentile(x, 95),
            TVaR_95=lambda x: x[x > np.percentile(x, 95)].mean(),
            Ruin_Prob=lambda x: np.mean(x <= 0) * 100
        ).reset_index()
        source_stats.to_excel(writer, sheet_name="Source Summary", index=False)

    print("✅ Enhanced Bayesian model with posterior sampling complete.")

if __name__ == "__main__":
    multiprocessing.freeze_support()
    main()

