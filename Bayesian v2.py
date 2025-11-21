# ✅ Final Bayesian Script with Frequency Fix, Robust Priors, and Enhanced Risk Visualization

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pymc as pm
import arviz as az
import os
import matplotlib.ticker as mticker
import pytensor.tensor as pt
import multiprocessing

if __name__ == "__main__":
    multiprocessing.freeze_support()

    np.random.seed(42)

    # from home edwardl = Lewis
    # Define paths
    input_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/"
    output_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Bayesian MCMC/"
    risk_summary_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Existing Claim Data Analyses/"

    # Load claims data
    claims_df = pd.read_csv(os.path.join(risk_summary_path, "claims_policy_data_inflated.csv"))
    claims_df = claims_df[claims_df["Claim Amount (Inflated)"] > 0].dropna(subset=["Reason for Claim", "Vehicle Make"])

    # Remove extreme outliers (outside 1st and 99th percentile)
    lower = claims_df["Claim Amount (Inflated)"].quantile(0.01)
    upper = claims_df["Claim Amount (Inflated)"].quantile(0.99)
    claims_df = claims_df[(claims_df["Claim Amount (Inflated)"] >= lower) & (claims_df["Claim Amount (Inflated)"] <= upper)]

    claims_df["Claim Reason Code"] = claims_df["Reason for Claim"].astype("category").cat.codes
    claims_df["Vehicle Make Code"] = claims_df["Vehicle Make"].astype("category").cat.codes

    claim_amounts = claims_df["Claim Amount (Inflated)"].values
    reason_idx = claims_df["Claim Reason Code"].values
    vehicle_idx = claims_df["Vehicle Make Code"].values
    n_reasons = claims_df["Claim Reason Code"].nunique()
    n_vehicles = claims_df["Vehicle Make Code"].nunique()
    log_claims = np.log(claim_amounts)

    # ------------------ Bayesian Hierarchical Model with Robust Priors ------------------
    with pm.Model() as model:
        mu_global = pm.StudentT("mu_global", nu=3, mu=log_claims.mean(), sigma=1)
        sigma_global = pm.HalfStudentT("sigma_global", nu=3, sigma=1)

        sigma_reason = pm.HalfStudentT("sigma_reason", nu=3, sigma=1.0, shape=n_reasons)
        mu_reason_offset_raw = pm.StudentT("mu_reason_offset_raw", nu=3, mu=0, sigma=1, shape=n_reasons)
        mu_reason_offset = pm.Deterministic("mu_reason_offset", mu_reason_offset_raw * sigma_reason)

        mu_vehicle_offset = pm.StudentT("mu_vehicle_offset", nu=3, mu=0, sigma=0.5, shape=n_vehicles)
        sigma_vehicle = pm.HalfStudentT("sigma_vehicle", nu=3, sigma=0.5, shape=n_vehicles)

        w = pm.Dirichlet("w", a=np.ones(2))
        mu_raw = pm.StudentT("mu_raw", nu=3, mu=mu_global, sigma=0.5, shape=2)
        mu_comp = pm.Deterministic("mu_comp", pt.sort(mu_raw))
        sigma_comp = pm.HalfStudentT("sigma_comp", nu=3, sigma=0.5, shape=2)

        obs = pm.Mixture(
            "obs",
            w=w,
            comp_dists=pm.Lognormal.dist(mu=mu_comp, sigma=sigma_comp),
            observed=log_claims
        )

        trace = pm.sample(
            draws=8000,
            tune=1000,
            chains=4,
            target_accept=0.98,
            max_treedepth=20,
            return_inferencedata=True
        )

        posterior_pred = pm.sample_posterior_predictive(trace, var_names=["obs"], random_seed=42)

    # ------------------ Post-processing ------------------
    posterior_samples = np.exp(posterior_pred.posterior_predictive["obs"].values.flatten())
    posterior_samples = posterior_samples[np.isfinite(posterior_samples)]
    posterior_samples = posterior_samples[(posterior_samples > 0) & (posterior_samples < 1e6)]

    pd.DataFrame({"Simulated Claim Cost": posterior_samples}).to_csv(
        os.path.join(output_path, "Bayesian2_StudentT_Simulated_Claims.csv"), index=False
    )

    # KDE Plot
    if len(posterior_samples) > 10:
        plt.figure(figsize=(10, 6))
        sns.histplot(claim_amounts, bins=50, color='grey', alpha=0.3, label='Actual Claims')
        sns.histplot(posterior_samples, bins=50, kde=True, color='purple', alpha=0.6, label='Bayesian Posterior')
        plt.title('Bayesian Posterior vs Actual Claim Costs (Robust)')
        plt.xlabel('Claim Cost (Rands)')
        plt.ylabel('Frequency')
        plt.legend()
        plt.tight_layout()
        plt.gca().xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000):,}k'))
        plt.savefig(os.path.join(output_path, 'Bayesian2_StudentT_KDE.png'), dpi=300)
        plt.close()

    # Summary Stats
    summary_stats = pd.Series(posterior_samples).describe(percentiles=[0.25, 0.5, 0.75])
    summary_stats.to_frame(name="Value").to_excel(
        os.path.join(output_path, "Bayesian2_StudentT_Summary.xlsx")
    )

    # Actual Frequency
    actual_freq_val = pd.read_excel(
        os.path.join(risk_summary_path, '7. Risk Analysis Results.xlsx'),
        sheet_name='Claim Summary',
        index_col=0
    ).loc['Annualized Frequency', 'Value']

    mean_actual = claim_amounts.mean()
    mean_sim = posterior_samples.mean()
    severity_ratio = mean_sim / mean_actual
    months = 84

    # Simulated Frequency
    simulated_claims = posterior_samples[posterior_samples > 1]
    num_simulated_claims = len(simulated_claims)
    num_policies = claims_df["Policy number"].nunique()
    simulated_freq = (num_simulated_claims / (months * num_policies)) * 12 * 100

    # Risk Metrics
    adjusted_freq = actual_freq_val * severity_ratio
    var_95 = np.percentile(posterior_samples, 5)
    var_99 = np.percentile(posterior_samples, 1)
    tvar_95 = posterior_samples[posterior_samples >= var_95].mean()
    tvar_99 = posterior_samples[posterior_samples >= var_99].mean()
    reserve_limit = var_95
    prob_ruin = np.mean(posterior_samples > reserve_limit)

    # Ruin Probability Table and Plot
    ruin_thresholds = [25000, 40000, 50000, 60000, 75000, 100000]
    ruin_probs = {f"P(Claim > R{t:,})": np.mean(posterior_samples > t) for t in ruin_thresholds}
    ruin_probs_df = pd.DataFrame.from_dict(ruin_probs, orient="index", columns=["Probability"])
    ruin_probs_df.to_excel(os.path.join(output_path, "Bayesian2_StudentT_Ruin_Probabilities.xlsx"))

    plt.figure(figsize=(8, 5))
    plt.plot(ruin_thresholds, [ruin_probs[f"P(Claim > R{t:,})"] for t in ruin_thresholds], marker='o')
    plt.title("Ruin Probability vs Reserve Threshold")
    plt.xlabel("Reserve Threshold (Rands)")
    plt.ylabel("Probability of Ruin")
    plt.grid(True)
    plt.tight_layout()
    plt.gca().xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'R{x/1000:,.0f}k'))
    plt.savefig(os.path.join(output_path, "Bayesian2_StudentT_Ruin_Probability_Plot.png"), dpi=300)
    plt.close()

    # Cumulative Distribution (Loss Curve)
    sorted_claims = np.sort(posterior_samples)
    cum_probs = np.linspace(0, 1, len(sorted_claims))
    plt.figure(figsize=(8, 5))
    plt.plot(sorted_claims, cum_probs)
    plt.title("Cumulative Loss Curve")
    plt.xlabel("Claim Cost (Rands)")
    plt.ylabel("Cumulative Probability")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(os.path.join(output_path, "Bayesian2_StudentT_Loss_Curve.png"), dpi=300)
    plt.close()

    # Stop-loss Premium Estimate: E[max(Claim - limit, 0)]
    stop_loss_limits = [25000, 50000, 75000, 100000]
    stop_loss_premiums = {
        f"E[max(Claim - R{limit:,}, 0)]": np.mean(np.maximum(posterior_samples - limit, 0))
        for limit in stop_loss_limits
    }
    pd.DataFrame.from_dict(stop_loss_premiums, orient="index", columns=["Stop-Loss Premium"]).to_excel(
        os.path.join(output_path, "Bayesian2_StudentT_Stop_Loss_Premiums.xlsx")
    )

    # Summary
    bayes_summary = {
        "Total Simulated Samples": len(posterior_samples),
        "Simulated Claims (Amount > R1)": num_simulated_claims,
        "Mean Claim Cost": mean_sim,
        "25th Percentile": np.percentile(posterior_samples, 25),
        "Median Claim Cost": np.percentile(posterior_samples, 50),
        "75th Percentile": np.percentile(posterior_samples, 75),
        "Max Claim Cost": np.max(posterior_samples),
        "VaR 95% (Reserve Limit)": reserve_limit,
        "VaR 99%": var_99,
        "TVaR 95%": tvar_95,
        "TVaR 99%": tvar_99,
        "Probability of Ruin (Claim > Reserve Limit)": prob_ruin,
        "Actual Claims Frequency": actual_freq_val,
        "Adjusted Frequency (by severity ratio)": adjusted_freq,
        "Simulated Frequency (Annualized per 100 policies)": simulated_freq
    }

    pd.DataFrame.from_dict(bayes_summary, orient="index", columns=["Value"]).to_excel(
        os.path.join(output_path, "Bayesian2_StudentT_Risk_Summary.xlsx")
    )

    az.plot_trace(trace)
    plt.tight_layout()
    plt.savefig(os.path.join(output_path, "Bayesian2_StudentT_Trace_Plots.png"), dpi=300)
    plt.close()

    az.plot_energy(trace)
    plt.tight_layout()
    plt.savefig(os.path.join(output_path, "Bayesian2_StudentT_Energy_Plot.png"), dpi=300)
    plt.close()

    az.plot_rank(trace)
    plt.tight_layout()
    plt.savefig(os.path.join(output_path, "Bayesian2_StudentT_Rank_Plot.png"), dpi=300)
    plt.close()

    print("\n✅ Bayesian risk outputs completed: ruin table, loss curve, stop-loss premiums, and summary saved.")
