import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import matplotlib.ticker as mticker
import scipy.stats as stats
import os
import seaborn as sns
import arviz as az
import ast
import pdfplumber
import warnings
import sys
import contextlib

from sklearn.mixture import GaussianMixture
from fitter import Fitter
from scipy.stats import anderson,boxcox,rv_continuous, skew, kurtosis, norm, gaussian_kde,invgamma, skewnorm, nakagami, invweibull, gamma, lognorm, poisson
from scipy.special import beta
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import PowerTransformer
from datetime import datetime
from scipy.integrate import IntegrationWarning

plt.close('all')  # Closes all open figures

# Set seed for reproducibility
np.random.seed(42)

#----------------------- Notes -----------------------
# Input data check Vehicle name and brand and reason codes are the same as different spelling and capitilized vs non capitlaized will through out metrics
# Insure that claim reason is the same as the SOB benefits otherwise the MCMC model will be incorrect
# Map components that do not match SOB to additional component cover
# Update policy number of months (default)
# Update policy Premium
# Update minimum value SOB for simulated claims
#from home edwardl = edwardl


#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
#----------------------- Define manual defaults -----------------------
#Default policy duration
months = 6

# Define reserve level
premium_per_policy = 1000

# Define the minimum claim value to simulate against SOB
min_SOB = 1000



#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 

#####################################################################################################################
#----------------------- Define keys -----------------------

# Define output path
output_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/DPP Turbo/"
QQ_output_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/DPP Turbo/QQ Plots/"

# Define input path
input_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/DPP Turbo/"



# Define Generalized Beta of the Second Kind (GB2) distribution)
class gb2_gen(rv_continuous):
  def _pdf(self, x, a, b, p, q):
        return (a * x**(a * p - 1)) / (b**(a * p) * beta(p, q) * (1 + (x / b)**a)**(p + q))

# Define and add GB2 to the stats module
gb2 = gb2_gen(name="gb2", shapes="a, b, p, q", a=0)
stats.gb2 = gb2  # This lets you refer to stats.gb2.pdf, etc.

# Define the list of distributions to fit including additional heavy-tail ones
distributions_to_fit = [
    'norm',          # Normal/Gaussian distribution
    'weibull_min',   # Weibull
    'gamma',         # Gamma of the first kind
    'lognorm',       #Lognormal
    'expon',         #Exponential
    'pareto',        # (Pareto Type I)
    'burr',          # (Burr Type XII)
    'genextreme',    # (GEV)
    'genpareto',     # Generalized Pareto Distribution (GPD)
    'lomax',         # Pareto Type II (Lomax)
    'fisk',          # Log-logistic Distribution
    'invgamma',      # Inverse Gamma Distribution
    'invweibull',    # Frechet Distribution (via inverse Weibull)
    'gb2',          # Custome Generalized Beta of the Second Kind
    'betaprime',    # Beta Prime Distribution (heavy-tailed)
    'invgauss',     # Inverse Gaussian (positive skew)
    'gengamma',     # Generalized Gamma (flexible)
    't',            # Student’s t (heavy tails, symmetric)
    'nakagami',     # Nakagami (positive, skewed)
    'recipinvgauss', # Reciprocal Inverse Gaussian (extremely heavy-tailed)
    'genlogistic',   # Generalized Logistic (for skew control)
    'skewnorm',      # Skew-Normal (for asymmetry)
    'fatiguelife'    # Fatigue Life (for time-to-failure/claims)
]

# Define remove extreme outliers
def remove_extreme_outliers(df, column):
    mean_val = df[column].mean()
    std_val = df[column].std()
    z_scores = (df[column] - mean_val) / std_val
    return df[np.abs(z_scores) <= 3].copy()


#####################################################################################################################
# ----------------------- determine exposure -----------------------
# ------------------------------ #
# Step 1: Load and preprocess data
# ------------------------------ #
file_path = os.path.join(input_path, "claims_policy_data.xlsx")
df = pd.read_excel(file_path)
df.columns = df.columns.str.strip()

# Convert date columns
df["Inception Date"] = pd.to_datetime(df["Inception Date"], errors='coerce')
df["Expiry Date"] = pd.to_datetime(df["Expiry Date"], errors='coerce')

# ------------------------------ #
# Step 2: Deduplicate by unique Policy number
# ------------------------------ #
df_unique_policies = df.drop_duplicates(subset=["Policy number"]).copy()

# Today's date
today = pd.Timestamp.today().normalize()

# Adjust expiry dates using .loc[] to avoid SettingWithCopyWarning
df_unique_policies.loc[:, "Adjusted Expiry Date"] = np.where(
    df_unique_policies["Expiry Date"] > today,
    today,
    df_unique_policies["Expiry Date"]
)
df_unique_policies["Adjusted Expiry Date"] = pd.to_datetime(df_unique_policies["Adjusted Expiry Date"])

# Calculate exposure in months 
df_unique_policies.loc[:, "Exposure Months"] = (
    (df_unique_policies["Adjusted Expiry Date"] - df_unique_policies["Inception Date"]).dt.days / 30.4375
).clip(lower=0)

# -----------------------
# Step 3: Merge exposure back to full dataset to preserve reason/make/model granularity
# -----------------------

df_with_exposure = pd.merge(
    df,
    df_unique_policies[["Policy number", "Exposure Months"]],
    on="Policy number",
    how="left"
)
df_with_exposure = df_with_exposure.dropna(subset=["Exposure Months"])

# -----------------------
# Filter out invalid claims (< R1)
# -----------------------

df_with_exposure = df_with_exposure[df_with_exposure["Claim Amount"] >= 1]


# ------------------------------
# Step 4: Aggregate exposure by levels
# ------------------------------

# Total Exposure
total_exposure = df_unique_policies["Exposure Months"].sum()

# By Vehicle Make
by_vehicle_make = df_unique_policies.groupby("Vehicle Make")["Exposure Months"].sum().reset_index()
by_vehicle_make.columns = ["Vehicle", "Exposure Months"]

# By Vehicle Make and brand
by_vehicle_make_model = df_unique_policies.groupby(["Vehicle Make","Vehicle Model"])["Exposure Months"].sum().reset_index()
by_vehicle_make_model.columns = ["Vehicle Make", "Vehicle Model", "Exposure Months"]

# By Reason
by_reason = df_with_exposure.groupby("Reason for Claim")["Exposure Months"].sum().reset_index()
by_reason.columns = ["Reason for Claim", "Exposure Months"]

# By Reason and Vehicle Make
by_reason_make = df_with_exposure.groupby(["Reason for Claim", "Vehicle Make"])["Exposure Months"].sum().reset_index()

# By Reason, Make & Model
by_reason_make_model = df_with_exposure.groupby(["Reason for Claim", "Vehicle Make", "Vehicle Model"])["Exposure Months"].sum().reset_index()

# ------------------------------
# Step 5: Combine into single reference table
# ------------------------------

exposure_reference_df = {
    "Total Exposure (months)": total_exposure,
    "By Vehicle Make" : by_vehicle_make,
    "By Vehicle Make and Model" : by_vehicle_make_model,
    "By Reason": by_reason,
    "By Reason and Make": by_reason_make,
    "By Reason, Make & Model": by_reason_make_model,
    "Policy-level Data": df_unique_policies[["Policy number", "Inception Date", "Adjusted Expiry Date", "Exposure Months", ]]
}


# Write all to Excel
output_file = os.path.join(output_path, "Exposure_Analysis_Unique_Policies.xlsx")

with pd.ExcelWriter(output_file, engine="xlsxwriter") as writer:
    columns_to_keep = ["Policy number", "Inception Date", "Expiry Date", "Adjusted Expiry Date", "Exposure Months"]
    df_unique_policies[columns_to_keep].to_excel(writer, sheet_name="Policy Level Exposure", index=False)
    pd.DataFrame({"Total Exposure (Months)": [total_exposure]}).to_excel(writer, sheet_name="Summary", index=False)
    by_vehicle_make.to_excel(writer, sheet_name="By Vehicle Make", index=False)
    by_vehicle_make_model.to_excel(writer, sheet_name="By Vehicle Make and Model", index=False)
    by_reason.to_excel(writer, sheet_name="By Reason", index=False)
    by_reason_make.to_excel(writer, sheet_name="By Reason and Make", index=False)
    by_reason_make_model.to_excel(writer, sheet_name="By Reason Make Model", index=False)

print(f"✅ Exposure analysis exported to: {output_file}")

#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#########################################################################################
# ----------------------- load all claims policy data -----------------------

claims_policy_data = input_path + "claims_policy_data.xlsx"
df_claims_policy_data = pd.read_excel(claims_policy_data)
df_claims_policy_data = df_claims_policy_data[pd.to_numeric(df_claims_policy_data["Claim Amount"], errors="coerce") >= 1]

# Standardize column names
df_claims_policy_data.columns = df_claims_policy_data.columns.str.strip()

# Remove missing values
df_claims_policy_data = df_claims_policy_data.dropna(subset=['Claim Amount'])

# Remove extreme outliers
if 'df_claims_policy_data' in globals():
    df_claims_policy_data = remove_extreme_outliers(df_claims_policy_data, 'Claim Amount')
    print(f"Removed extreme outliers from df_claims_policy_data using ±3 std dev.")


# Convert date fields
df_claims_policy_data["Inception Date"] = pd.to_datetime(df_claims_policy_data["Inception Date"], errors="coerce")
df_claims_policy_data["Claim Date"] = pd.to_datetime(df_claims_policy_data["Claim Date"], errors="coerce")
df_claims_policy_data["Expiry Date"] = pd.to_datetime(df_claims_policy_data["Expiry Date"], errors="coerce")

# Ensure Claim Presence as Boolean
df_claims_policy_data["Claim Count"] = df_claims_policy_data["Claim ID"].notnull().astype(int)

# Save imported dataset for validation
df_claims_policy_data.to_csv(os.path.join(output_path, "Imported_Claims_Data.csv"), index=False)

# Handle missing expiry dates: Assume a standard policy term if expiry date is missing
default_expiry = df_claims_policy_data["Inception Date"] + pd.DateOffset(months)

num_policies = df_claims_policy_data['Policy number'].nunique()
total_reserve = premium_per_policy * num_policies
total_policy_months = months * num_policies


#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
# ----------------------- Complete Credibility Analysis -----------------------
#*********************************************************************************************************************
# ----------------------- Claim Count Analysis -----------------------
excel_file = os.path.join(output_path, "1. Claim Count Analysis.xlsx")

# 1 By Reason for Claim
total_claims_by_reason = df_claims_policy_data.groupby('Reason for Claim').agg(
    Number_of_Claims=('Claim Count', 'sum')
).reset_index()

# 2 By Reason and Vehicle Make
total_claims_by_make = df_claims_policy_data.groupby(['Reason for Claim', 'Vehicle Make']).agg(
    Number_of_Claims=('Claim Count', 'sum')
).reset_index()

# 3 By Reason, Vehicle Make, and Vehicle Model
total_claims_by_model = df_claims_policy_data.groupby(['Reason for Claim', 'Vehicle Make', 'Vehicle Model']).agg(
    Number_of_Claims=('Claim Count', 'sum')
).reset_index()

# ----------------------- Generate Charts and Write to Excel -----------------------
with pd.ExcelWriter(excel_file, engine='xlsxwriter') as writer:
    workbook = writer.book

    # Write claim count tables
    total_claims_by_reason.to_excel(writer, sheet_name='By Reason', index=False)
    total_claims_by_make.to_excel(writer, sheet_name='By Reason and Make', index=False)
    total_claims_by_model.to_excel(writer, sheet_name='By Reason, Make & Model', index=False)

    # Chart 1: Bar Chart - Claim Count by Reason
    chart1_path = os.path.join(output_path, "bar_Chart_Claim_Count_by_Reason.png")
    plt.figure(figsize=(12, 6))
    
    # Set y positions
    y_pos = range(len(total_claims_by_reason))

    # Plot with numeric y positions
    plt.barh(y_pos, total_claims_by_reason['Number_of_Claims'], color='skyblue')
    
    # Set y-tick labels
    plt.yticks(y_pos, total_claims_by_reason['Reason for Claim'])
    
    plt.xlabel("Number of Claims")
    plt.title("Claim Count by Reason")
    plt.tight_layout()
    plt.savefig(chart1_path, dpi=300)
    plt.close('all')
   
    # Chart 2: Stacked Bar Chart - Claim Count by Reason and Vehicle Make
    chart2_path = os.path.join(output_path, "bar_Chart_Claim_Count_by_Reason_and_Make.png")
    pivot_make = total_claims_by_make.pivot_table(
        index='Vehicle Make',
        columns='Reason for Claim',
        values='Number_of_Claims',
        fill_value=0
    )

    pivot_make.plot(kind='barh', stacked=True, figsize=(14, 8), colormap='tab20')
    plt.xlabel("Number of Claims")
    plt.title("Claim Count by Reason and Vehicle Make")
    plt.tight_layout()
    plt.savefig(chart2_path, dpi=300)
    plt.close('all')
   

    # ----------------------- Generate Heatmaps for Claim Count -----------------------
    # Chart 4A: Heatmap for Reason of Claim (Standalone)
    chart4a_path = os.path.join(output_path, "Chart_Heatmap_Claim_Count_Reason.png")
    plt.figure(figsize=(12, 8))
    sns.heatmap(total_claims_by_reason.set_index("Reason for Claim")[["Number_of_Claims"]],
                annot=True, fmt=".0f", cmap=sns.color_palette("RdYlGn_r", as_cmap=True))
    plt.title("Claim Count by Reason")
    plt.xlabel("")
    plt.ylabel("Reason for Claim")
    plt.tight_layout()
    plt.savefig(chart4a_path, dpi=300)
    plt.close('all')
   
    # Chart 4B: Heatmap for Reason by Vehicle Make
    chart4b_path = os.path.join(output_path, "Chart_Heatmap_Claim_Count_Vehicle.png")
    pivot_make = total_claims_by_make.pivot_table(
        index='Vehicle Make',
        columns='Reason for Claim',
        values='Number_of_Claims',
        fill_value=0
    )
    plt.figure(figsize=(16, 10))
    sns.heatmap(pivot_make, annot=True, fmt=".0f", cmap=sns.color_palette("RdYlGn_r", as_cmap=True))
    plt.title("Claim Count by Reason and Vehicle Make")
    plt.xlabel("Reason for Claim")
    plt.ylabel("Vehicle Make")
    plt.tight_layout()
    plt.savefig(chart4b_path, dpi=300)
    plt.close('all')
   
    # Chart 4C: Heatmap - Claim Count by Reason, Make, and Model
    chart4c_path = os.path.join(output_path, "Chart_Claim_Count_by_Reason_Make_Model.png")
    
    # Ensure concatenation happens on the full dataset before filtering
    total_claims_by_model['Make_Model'] = total_claims_by_model['Vehicle Make'] + " " + total_claims_by_model['Vehicle Model']
    
    # Filter top 20 models after concatenation
    top_models = total_claims_by_model.groupby('Make_Model')['Number_of_Claims'].sum().nlargest(20).index
    heatmap_data = total_claims_by_model[total_claims_by_model['Make_Model'].isin(top_models)]
    
    
    heatmap_pivot = heatmap_data.pivot_table(
        index='Make_Model',
        columns='Reason for Claim',
        values='Number_of_Claims',
        fill_value=0
    )
    plt.figure(figsize=(16, 10))
    sns.heatmap(heatmap_pivot, annot=True, fmt=".0f", cmap=sns.color_palette("RdYlGn_r", as_cmap=True))
    plt.title("Claim Count by Reason and Top 20 Vehicle Models")
    plt.xlabel("Reason for Claim")
    plt.ylabel("Vehicle Make & Model")
    plt.tight_layout()
    plt.savefig(chart4c_path, dpi=300)
    plt.close('all')
    
print(f"Full actuarial claim count report with charts created: {excel_file}")



#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
#*********************************************************************************************************************
# ----------------------- Actuarial Claim Frequencies -----------------------

excel_file = os.path.join(output_path, "2. Claim Frequency Analysis.xlsx")
# Step 0: Define reason_freq_exposure early
reason_freq_exposure = total_claims_by_reason.copy()

# Step 1: Compute total exposure from unique policies
total_exposure = df_unique_policies["Exposure Months"].sum()

# Step 2: Add exposure to reason-level dataframe
reason_freq_exposure["Exposure Months"] = total_exposure

# Step 3: Calculate annualized frequency at reason level
reason_freq_exposure["Annualized Claim Frequency (%)"] = (
    reason_freq_exposure["Number_of_Claims"] / reason_freq_exposure["Exposure Months"]
) * 12 * 100

# Step 4: Compute total claims from reason_freq_exposure
total_claims = reason_freq_exposure["Number_of_Claims"].sum()

# Step 5: Compute total annualized frequency
total_annualized_claim_frequency = (total_claims / total_exposure) * 12 * 100

# Step 6: Store as summary dataframe
total_frequency_df = pd.DataFrame({
    "Metric": ["Total Claims", "Total Exposure Months", "Total Annualized Frequency (%)"],
    "Value": [total_claims, total_exposure, total_annualized_claim_frequency]
})

# -----------------------1. By Reason using TOTAL exposure ---
reason_freq_exposure = total_claims_by_reason.copy()
reason_freq_exposure["Exposure Months"] = total_exposure
reason_freq_exposure["Annualized Claim Frequency (%)"] = (
    reason_freq_exposure["Number_of_Claims"] / reason_freq_exposure["Exposure Months"]
) * 12 * 100


# -----------------------2. By Reason and Vehicle Make using exposure by Make ---
# Step 1: Start with exposure by Vehicle Make
by_vehicle_make_exposure = exposure_reference_df["By Vehicle Make"].copy()
by_vehicle_make_exposure.columns = ["Vehicle Make", "Exposure Months"]  # standardize column names

# Step 2: Merge with total_claims_by_make (Reason + Make)
# This ensures each (Vehicle Make, Reason) pair keeps its claim count
reason_make_freq_exposure = pd.merge(
    total_claims_by_make,
    by_vehicle_make_exposure,
    on="Vehicle Make",
    how="left"
)

# Step 3: Calculate Frequency
reason_make_freq_exposure["Annualized Claim Frequency (%)"] = (
    reason_make_freq_exposure["Number_of_Claims"] / reason_make_freq_exposure["Exposure Months"]
) * 12 * 100

reason_make_freq_exposure = reason_make_freq_exposure.sort_values(by="Vehicle Make")

# Reorder columns to: Vehicle Make, Reason for Claim, ...
reason_make_freq_exposure = reason_make_freq_exposure[[
    "Vehicle Make",
    "Reason for Claim",
    "Number_of_Claims",
    "Exposure Months",
    "Annualized Claim Frequency (%)"
]]


#----------------------- Step 3: Calculate Annualized Claim Frequency
# ----------------------- Part 3: Frequency by Reason, Make & Model -----------------------

# Step 1: Start with exposure by Make and Model
exposure_df = exposure_reference_df["By Vehicle Make and Model"].copy()
exposure_df.columns = exposure_df.columns.str.strip()
exposure_df.rename(columns={"Exposure Months": "Exposure Months Model"}, inplace=True)

# Step 2: Group claim counts by Reason + Make + Model
claim_counts = df_claims_policy_data.groupby(
    ["Reason for Claim", "Vehicle Make", "Vehicle Model"]
).agg(
    Number_of_Claims=('Claim ID', 'count')
).reset_index()

# Step 3: Merge in exposure by Make and Model (reason is only in claims, not exposure)
reason_make_model_frequency = pd.merge(
    claim_counts,
    exposure_df,
    on=["Vehicle Make", "Vehicle Model"],
    how="left"
)

# Step 4: Drop rows with missing exposure
reason_make_model_frequency = reason_make_model_frequency.dropna(subset=["Exposure Months Model"])

# Step 5: Adjust exposure for low values (to avoid inflated frequencies)
reason_make_model_frequency["Adjusted Exposure Months"] = reason_make_model_frequency["Exposure Months Model"].apply(lambda x: max(x, 3))

# Step 6: Calculate frequency
reason_make_model_frequency["Annualized Claim Frequency (%)"] = (
    reason_make_model_frequency["Number_of_Claims"] /
    reason_make_model_frequency["Adjusted Exposure Months"]
) * 12 * 100

# Step 7: Detect Outliers using IQR method
q1 = reason_make_model_frequency["Annualized Claim Frequency (%)"].quantile(0.25)
q3 = reason_make_model_frequency["Annualized Claim Frequency (%)"].quantile(0.75)
iqr = q3 - q1
outlier_threshold_upper = q3 + 1.5 * iqr

reason_make_model_frequency["Outlier_Flag"] = (
    reason_make_model_frequency["Annualized Claim Frequency (%)"] > outlier_threshold_upper
)

# Step 8: Normalize frequencies for outliers using median exposure
median_exposure = reason_make_model_frequency["Adjusted Exposure Months"].median()
outlier_mask = reason_make_model_frequency["Outlier_Flag"]

reason_make_model_frequency.loc[outlier_mask, "Normalized Annualized Claim Frequency (%)"] = (
    reason_make_model_frequency.loc[outlier_mask, "Number_of_Claims"] / median_exposure
) * 12 * 100

# Step 9: Final Frequency: Apply normalized if outlier
reason_make_model_frequency["Final Annualized Claim Frequency (%)"] = (
    reason_make_model_frequency["Annualized Claim Frequency (%)"]
)

reason_make_model_frequency.loc[outlier_mask, "Final Annualized Claim Frequency (%)"] = (
    reason_make_model_frequency.loc[outlier_mask, "Normalized Annualized Claim Frequency (%)"]
)

# Fill remaining NaNs (if any)
reason_make_model_frequency["Final Annualized Claim Frequency (%)"] = (
    reason_make_model_frequency["Final Annualized Claim Frequency (%)"].fillna(0)
)

reason_make_model_frequency = reason_make_model_frequency.sort_values(by="Vehicle Make")


# 10. Export
final_cols = [
    "Vehicle Make",
    "Reason for Claim",
    "Vehicle Model",
    "Number_of_Claims",
    "Exposure Months Model",
    "Annualized Claim Frequency (%)",
    "Final Annualized Claim Frequency (%)",
    "Outlier_Flag"
]

reason_make_model_freq_exposure = reason_make_model_frequency[final_cols].copy()

#######################################################################################
# ----------------------- Generate Charts and Write to Excel -----------------------

with pd.ExcelWriter(excel_file, engine="xlsxwriter") as writer:
    # Write all dataframes to Excel
    reason_freq_exposure.to_excel(writer, sheet_name="By Reason", index=False)
    reason_make_freq_exposure.to_excel(writer, sheet_name="By Reason and Make", index=False)
    reason_make_model_freq_exposure.to_excel(writer, sheet_name="By Reason, Make & Model", index=False)
    total_frequency_df.to_excel(writer, sheet_name="Total Frequency", index=False)

    

    # Chart 1: Bar Chart - Reason for Claim (FIXED)
    plt.figure(figsize=(12, 6))
    
    # Generate numeric y-positions
    y_pos = range(len(reason_freq_exposure))
    
    # Plot bars using numeric positions
    plt.barh(y_pos, reason_freq_exposure["Annualized Claim Frequency (%)"], color="skyblue")
    
    # Set y-tick labels to string values
    plt.yticks(y_pos, reason_freq_exposure["Reason for Claim"])
    
    plt.xlabel("Annualized Claim Frequency (%)")
    plt.title("Annualized Claim Frequency by Reason")
    plt.tight_layout()
    
    chart1_path = os.path.join(output_path, "bar_chart_reason.png")
    plt.savefig(chart1_path, dpi=300)
    plt.close('all')


    # Chart 2: Stacked Bar Chart - Reason by Vehicle Make
    plt.figure(figsize=(14, 8))
    pivot_make = reason_make_freq_exposure.pivot_table(
        index="Vehicle Make",
        columns="Reason for Claim",
        values="Annualized Claim Frequency (%)",
        fill_value=0,
    )
    pivot_make.plot(kind="barh", stacked=True, colormap="tab20")
    plt.xlabel("Annualized Claim Frequency (%)")
    plt.title("Annualized Claim Frequency by Reason and Vehicle Make")
    plt.tight_layout()
    chart2_path = os.path.join(output_path, "bar_chart_reason_make.png")
    plt.savefig(chart2_path, dpi=300)
    plt.close('all')



    # ----------------------- Generate Heatmaps for Claim Frequency -----------------------

    # Chart 4A: Heatmap for Reason of Claim (Standalone)
    chart4a_path = os.path.join(output_path,"Chart_Heatmap_Frequency_By_Reason_of_Claim.png")
    plt.figure(figsize=(12, 8))
    sns.heatmap(reason_freq_exposure.set_index("Reason for Claim")[["Annualized Claim Frequency (%)"]], 
           annot=True, fmt=".1f", cmap=sns.color_palette("RdYlGn_r", as_cmap=True))
    plt.title("Annualized Claim Frequency (%) by Reason of Claim")
    plt.xlabel("")
    plt.ylabel("Reason for Claim")
    plt.tight_layout()
    plt.savefig(chart4a_path, dpi=300)
    plt.close("all")


    # Chart 4B: Heatmap for Reason by Vehicle Make
    chart4b_path = os.path.join(output_path, "Chart_Heatmap_Frequency_by_Vehicle.png")
    pivot_make = reason_make_freq_exposure.pivot_table(
        index='Vehicle Make',
       columns='Reason for Claim',
       values='Annualized Claim Frequency (%)',
       fill_value=0
    )
    plt.figure(figsize=(16, 10))
    sns.heatmap(pivot_make, annot=True, fmt=".1f", cmap=sns.color_palette("RdYlGn_r", as_cmap=True))
    plt.title("Annualized Claim Frequency (%) by Reason and Vehicle Make")
    plt.xlabel("Reason for Claim")
    plt.ylabel("Vehicle Make")
    plt.tight_layout()
    plt.savefig(chart4b_path, dpi=300)
    plt.close("all")


    # Chart 4C: Heatmap - Reason, Make, and Model (Top 20 Models)
    chart4c_path = os.path.join(output_path,"Chart_Actuarial_Claim_Frequency_by_Reason_Make_Model.png")

    # Ensure concatenation happens before filtering
    reason_make_model_freq_exposure['Make_Model'] = (
    reason_make_model_freq_exposure['Vehicle Make'] + " " + reason_make_model_freq_exposure['Vehicle Model']
    )

    # Filter for top 20 models after concatenation
    top_models = reason_make_model_freq_exposure.groupby('Make_Model')['Number_of_Claims'].sum().nlargest(20).index
    heatmap_data = reason_make_model_freq_exposure[reason_make_model_freq_exposure['Make_Model'].isin(top_models)]

    # Create pivot table using updated "Final Annualized Claim Frequency (%)"
    heatmap_pivot = heatmap_data.pivot_table(
        index='Make_Model',
        columns='Reason for Claim',
        values='Final Annualized Claim Frequency (%)',  # Updated to use Final Annualized Claim Frequency
        fill_value=0
    )

    plt.figure(figsize=(16, 10))
    sns.heatmap(heatmap_pivot, annot=True, fmt=".1f", cmap=sns.color_palette("RdYlGn_r", as_cmap=True))
    plt.title("Final Annualized Claim Frequency (%) by Reason and Top 20 Vehicle Models")
    plt.xlabel("Reason for Claim")
    plt.ylabel("Vehicle Make & Model")
    plt.tight_layout()
    plt.savefig(chart4c_path, dpi=300)
    plt.close("all")


print(f"✅ Full actuarial frequency report with charts created: {excel_file}")







#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
#----------------------- Calculate the claim frequency by month -----------------------
# Paths
excel_file = os.path.join(output_path, "3. Claim Frequency by Month.xlsx")
claim_frequency_path = os.path.join(output_path, "2. Claim Frequency Analysis.xlsx")
sob_path = os.path.join(input_path, "schedule_of_benefits.xlsx")

# Load base frequency table
df_base = pd.read_excel(claim_frequency_path, sheet_name="By Reason and Make")
df_base.columns = df_base.columns.str.strip()

# Create placeholder month columns (1 to 84)
for m in range(1, months + 1):
    df_base[str(m)] = 1  # Temporarily fill with 1s for equal split

# Step 1: Calculate row totals (should be 84 at this point)
df_base["Total"] = df_base[[str(m) for m in range(1, months + 1)]].sum(axis=1)

# Step 2: Replace dummy values with normalized values
month_cols = [str(m) for m in range(1, months + 1)]
df_base[month_cols] = df_base.apply(
    lambda row: pd.Series(
        [row["Annualized Claim Frequency (%)"] / months] * months
        if row["Total"] == months
        else [0] * months,
        index=month_cols
    ),
    axis=1
)

# Step 3: Drop helper total column
df_base.drop(columns=["Total"], inplace=True)

# Rename columns for alignment
pivot_table = df_base.rename(columns={"Reason for Claim": "Benefit Name", "Annualized Claim Frequency (%)": "Expected Total Frequency"})

# Load SOB data
df_sob = pd.read_excel(sob_path)
df_sob.columns = df_sob.columns.str.strip()
df_sob = df_sob.dropna(subset=["Start"])
df_sob = df_sob[["Benefit Name", "Start"]].drop_duplicates()

# Merge SOB to get Start Month
pivot_table = pivot_table.merge(df_sob, on="Benefit Name", how="left")
pivot_table["Start"] = pivot_table["Start"].fillna(1).astype(int)

# Apply SOB Start Month Logic
month_cols = [str(m) for m in range(1, months + 1)]


for idx, row in pivot_table.iterrows():
    start_month = row["Start"]
    expected_total = row["Expected Total Frequency"]

    # Optional: restrict based on SOB End month
    end_month = int(row["End"]) if "End" in row and not pd.isna(row["End"]) else months

    months_before = [str(m) for m in range(1, start_month)]
    months_after = [str(m) for m in range(start_month, end_month + 1)]

    pivot_table.loc[idx, months_before] = 0

    partial_total = pivot_table.loc[idx, months_after].sum()
    if partial_total > 0:
        scale = expected_total / partial_total
        pivot_table.loc[idx, months_after] *= scale
    elif expected_total > 0:
        pivot_table.loc[idx, months_after] = expected_total / len(months_after)

    # Update totals
    pivot_table.loc[idx, "Total"] = pivot_table.loc[idx, month_cols].sum()
    pivot_table.loc[idx, "Difference (%)"] = pivot_table.loc[idx, "Total"] - expected_total

# Restore naming
pivot_table = pivot_table.rename(columns={"Benefit Name": "Reason for Claim"})

# Reorder columns
final_cols = ["Vehicle Make", "Reason for Claim", "Total", "Expected Total Frequency", "Difference (%)"] + month_cols
pivot_table = pivot_table[final_cols]

# Save output
with pd.ExcelWriter(excel_file, engine="xlsxwriter") as writer:
    pivot_table.to_excel(writer, sheet_name="Monthly Claim Frequency", index=False)

    reconciliation_df = pd.DataFrame({
        "Metric": [
            "Total Monthly Claim Frequency (After SOB Rebalancing)",
            "Expected Total Annualized Frequency (From Final Frequency Analysis)",
            "Difference"
        ],
        "Value": [
            pivot_table["Total"].sum(),
            pivot_table["Expected Total Frequency"].sum(),
            pivot_table["Total"].sum() - pivot_table["Expected Total Frequency"].sum()
        ]
    })
    reconciliation_df.to_excel(writer, sheet_name="Reconciliation Summary", index=False)

print("✅ Monthly claim frequency updated using SOB Start logic and saved.")





#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
#------------------Compute Credibility stats----------------------------

exposure_file_path = os.path.join(output_path, "Exposure_Analysis_Unique_Policies.xlsx")
claims_file_path = os.path.join(output_path, "Imported_Claims_Data.csv")
output_file = os.path.join(output_path, "4. Credibility Statistics.xlsx")
threshold = 1082

# ---------------------- Functions ----------------------
def detect_outliers(df, column):
    Q1 = df[column].quantile(0.25)
    Q3 = df[column].quantile(0.75)
    IQR = Q3 - Q1
    lower, upper = Q1 - 1.5 * IQR, Q3 + 1.5 * IQR
    df["Outlier_Flag"] = (df[column] < lower) | (df[column] > upper)
    return df

def compute_detailed_summary(df):
    # Split into claim and all data sets
    df_claims_only = df[df["Claim Count"] > 0].copy()       # rows with claims
    df_exposure_all = df.copy()                             # all policies

    # Initialize an empty summary frame
    summary_frames = []

    # 1. Claim Amount (claims only)
    if "Claim Amount" in df_claims_only.columns:
        claim_summary = df_claims_only["Claim Amount"].describe(percentiles=[0.05, 0.25, 0.5, 0.75, 0.95, 0.99]).to_frame()
        claim_summary.columns = ["Claim Amount"]
        claim_summary.loc["count"] = df_claims_only["Claim Count"].sum()  # Override count
        claim_summary["Skewness"] = df_claims_only["Claim Amount"].skew()
        claim_summary["Kurtosis"] = kurtosis(df_claims_only["Claim Amount"])
        claim_summary["IQR"] = claim_summary.loc["75%"] - claim_summary.loc["25%"]
        claim_summary["Coefficient of Variation (CoV)"] = claim_summary.loc["std"] / claim_summary.loc["mean"]
        summary_frames.append(claim_summary.T)

    # 2. Actuarial Exposure Months (all policies)
    if "Actuarial Exposure Months" in df_exposure_all.columns:
        exposure_summary = df_exposure_all["Actuarial Exposure Months"].describe(percentiles=[0.05, 0.25, 0.5, 0.75, 0.95, 0.99]).to_frame()
        exposure_summary.columns = ["Actuarial Exposure Months"]
        exposure_summary["Skewness"] = df_exposure_all["Actuarial Exposure Months"].skew()
        exposure_summary["Kurtosis"] = kurtosis(df_exposure_all["Actuarial Exposure Months"])
        exposure_summary["IQR"] = exposure_summary.loc["75%"] - exposure_summary.loc["25%"]
        exposure_summary["Coefficient of Variation (CoV)"] = exposure_summary.loc["std"] / exposure_summary.loc["mean"]
        summary_frames.append(exposure_summary.T)

    # 3. Claim Count (claims only)
    if "Claim Count" in df_claims_only.columns:
        count_summary = df_claims_only["Claim Count"].describe(percentiles=[0.05, 0.25, 0.5, 0.75, 0.95, 0.99]).to_frame()
        count_summary.columns = ["Claim Count"]
        count_summary.loc["count"] = df_claims_only["Claim Count"].sum()
        count_summary["Skewness"] = df_claims_only["Claim Count"].skew()
        count_summary["Kurtosis"] = kurtosis(df_claims_only["Claim Count"])
        count_summary["IQR"] = count_summary.loc["75%"] - count_summary.loc["25%"]
        count_summary["Coefficient of Variation (CoV)"] = count_summary.loc["std"] / count_summary.loc["mean"]
        summary_frames.append(count_summary.T)

    # Combine all
    return pd.concat(summary_frames)

def compute_credibility(df):
    exposure = df["Actuarial Exposure Months"].sum()
    claims = df["Claim Count"].sum()
    severity = df["Claim Amount"].mean()
    variance = df["Claim Amount"].var()
    classical = min(1, np.sqrt(claims / threshold))
    buhlmann = exposure / (exposure + variance / severity**2) if severity > 0 else 0
    return pd.DataFrame({
        "Total Exposure Months": [exposure],
        "Total Claims": [claims],
        "Mean Claim Severity": [severity],
        "Variance": [variance],
        "Classical Credibility": [classical],
        "Bühlmann Credibility": [buhlmann]
    })

# ---------------------- Load Data ----------------------
# 1. Load policy-level exposure (no Vehicle Make here)
exposure_df = pd.read_excel(exposure_file_path, sheet_name="Policy Level Exposure")
exposure_df = exposure_df.rename(columns={"Exposure Months": "Actuarial Exposure Months"})

# 2. Load full claims data
claims_df = pd.read_csv(claims_file_path)
claims_df.columns = claims_df.columns.str.strip()
claims_df = claims_df[pd.to_numeric(claims_df["Claim Amount"], errors="coerce") >= 1]

# 3. Extract summarised claims per policy
claims_summary = claims_df.groupby("Policy number").agg(
    Claim_Count=("Claim ID", "count"),
    Claim_Amount_Sum=("Claim Amount", "sum"),
    Reason_Sample=("Reason for Claim", "first"),
    Make_Sample=("Vehicle Make", "first")  # Capture for summary_by_make
).reset_index()

# ---------------------- Merge ----------------------
# Merge policy exposure with claims summary
merged_df = exposure_df.merge(claims_summary, on="Policy number", how="left")
merged_df["Claim Count"] = merged_df["Claim_Count"]
merged_df["Claim Amount"] = merged_df["Claim_Amount_Sum"] 
merged_df["Reason for Claim"] = merged_df["Reason_Sample"].fillna("No Claim")
merged_df["Vehicle Make"] = merged_df["Make_Sample"].fillna("Unknown")

# ---------------------- Analysis ----------------------
merged_df = detect_outliers(merged_df, "Claim Amount")
detailed_summary = compute_detailed_summary(merged_df)
credibility_df = compute_credibility(merged_df)

# Group summaries
summary_by_make = merged_df.groupby("Vehicle Make")[["Claim Amount", "Claim Count", "Actuarial Exposure Months"]].agg(["mean", "sum", "count"])
summary_by_reason = merged_df.groupby("Reason for Claim")[["Claim Amount", "Claim Count", "Actuarial Exposure Months"]].agg(["mean", "sum", "count"])

# Exposure Buckets
merged_df["Exposure Group"] = pd.cut(
    merged_df["Actuarial Exposure Months"],
    bins=[0, 12, 24, 36, 48, 60, 72, 84],
    labels=["0-12m", "13-24m", "25-36m", "37-48m", "49-60m", "61-72m", "73-84m"]
)
summary_by_exposure = merged_df.groupby("Exposure Group", observed=False)[["Claim Amount", "Claim Count", "Actuarial Exposure Months"]].agg(["mean", "sum", "count"])

# ---------------------- Fix Group Summaries ----------------------

def flatten_columns(df):
    df_flat = df.copy()
    df_flat.columns = [' '.join(col).strip() if isinstance(col, tuple) else col for col in df_flat.columns.values]
    return df_flat.reset_index()

summary_by_make_clean = flatten_columns(summary_by_make)
summary_by_reason_clean = flatten_columns(summary_by_reason)
summary_by_exposure_clean = flatten_columns(summary_by_exposure)

# ---------------------- Export to Excel ----------------------

with pd.ExcelWriter(output_file, engine="xlsxwriter") as writer:
    detailed_summary.to_excel(writer, sheet_name="Detailed Summary")
    credibility_df.to_excel(writer, sheet_name="Credibility Analysis", index=False)
    merged_df.to_excel(writer, sheet_name="Policy-Level Data", index=False)
    summary_by_make_clean.to_excel(writer, sheet_name="Summary by Make", index=False)
    summary_by_reason_clean.to_excel(writer, sheet_name="Summary by Reason", index=False)
    summary_by_exposure_clean.to_excel(writer, sheet_name="Summary by Exposure", index=False)


print(f"✅ Final credibility report created and saved to: {output_file}")





#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
# ----------------------- Create claim amounts transformations -----------------------
# Load original dataset
data_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/DPP Turbo/claims_policy_data.xlsx"

df = pd.read_excel(data_path, sheet_name="Sheet1")
df = df[pd.to_numeric(df["Claim Amount"], errors="coerce") >= 1]
df.columns = df.columns.str.strip()
df = df.dropna(subset=['Claim Amount'])

# Remove extreme outliers
if 'df' in globals():
    df = remove_extreme_outliers(df, 'Claim Amount')
    print(f"Removed extreme outliers from df using ±3 std dev.")


# Save imported dataset for validation
#df.to_excel(os.path.join(output_path, "Imported_Claims_Data.csv"), index=False)

#*********************************************************************************************************************
# ---------------------- Apply Transformations ----------------------
raw_claims = df['Claim Amount'].values
min_positive = np.min(raw_claims[raw_claims > 0]) if np.any(raw_claims > 0) else 1e-3

transformations = {
    "Raw": raw_claims,
    "Log": np.log1p(np.where(raw_claims > 0, raw_claims, min_positive)),
    "ShiftedLog": np.log(np.where(raw_claims > 0, raw_claims, min_positive) + 10),
    "BoxCox": boxcox(np.where(raw_claims > 0, raw_claims, min_positive))[0],
    "Sqrt": np.sqrt(np.maximum(raw_claims, 0)),
    "Arcsinh": np.arcsinh(raw_claims),
    "Normalized": (raw_claims - np.mean(raw_claims)) / np.std(raw_claims),
    "YeoJohnson": PowerTransformer(method='yeo-johnson').fit_transform(raw_claims.reshape(-1, 1)).flatten()
}

for name, data in transformations.items():
    transformations[name] = np.nan_to_num(data, nan=min_positive, posinf=min_positive, neginf=min_positive)

#*********************************************************************************************************************    
# ----------------------- Plot transformed histograms -----------------------
for name, data in transformations.items():
    plt.figure(figsize=(14, 8))

    # Plot histogram with grey bins
    sns.histplot(data, bins=50, color="grey", alpha=0.6, kde=False, stat="density", label=f"{name} Transformation")

    # Plot KDE separately (blue color) but exclude label from automatic legend
    sns.kdeplot(data, color="blue", linewidth=2, label=None)

    # Compute histogram values
    hist_values, bin_edges = np.histogram(data, bins=50, density=True)
    bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2  # Bin centers

    # Compute moving average for smoothing
    window_size = 5  # Adjust for more/less smoothing
    smoothed_trend = np.convolve(hist_values, np.ones(window_size) / window_size, mode='same')

    # Plot smoothed trend line in red
    plt.plot(bin_centers, smoothed_trend, color="red", linewidth=2, linestyle="dashed", label=None)

    # Create custom legend handles
    kde_line = mlines.Line2D([], [], color='blue', linewidth=2, label="KDE (Density Estimate)")
    trend_line = mlines.Line2D([], [], color='red', linestyle="dashed", linewidth=2, label="Smoothed Trend Line")
    hist_patch = mlines.Line2D([], [], color='grey', linewidth=8, alpha=0.6, label="Histogram Bins")

    # Add legend
    plt.legend(handles=[hist_patch, kde_line, trend_line])

    # Labels and title
    plt.title(f"{name} Claim Amount Distribution")
    plt.xlabel("Transformed Claim Amount")
    plt.ylabel("Density")
    plt.grid(True)

    # Save plot
    transformed_output_path = os.path.join(output_path, f"{name}_Claim_Distribution.png")
    plt.savefig(transformed_output_path, dpi=300, bbox_inches='tight')
    plt.close("all")

    print(f"Saved histogram: {output_path}{name}_Claim_Distribution.png") 

#*********************************************************************************************************************
#----------------------- Plot raw claims histogram with a bell curve (no normalization)-----------------------
plt.figure(figsize=(14, 8))

# Histogram (actual counts, not density)
plt.hist(raw_claims, bins=50, alpha=0.6, color='grey', label='Raw Claims (Counts)', density=False)

# Bell curve (Normal distribution using mean and std)
mean = np.mean(raw_claims)
std = np.std(raw_claims)
x = np.linspace(min(raw_claims), max(raw_claims), 1000)
bell_curve = stats.norm.pdf(x, mean, std) * len(raw_claims) * (max(raw_claims) - min(raw_claims)) / 50  # Adjust scaling

plt.plot(x, bell_curve, color='red', linewidth=2, label='Normal Distribution (Bell Curve)')

plt.title("Raw Claim Amounts with Bell Curve")
plt.xlabel("Claim Amount")
plt.ylabel("Counts")
plt.legend()
plt.grid(True)

# Optional: format axis for large numbers
# format_axis_x(plt.gca())
# format_axis_y(plt.gca())
histogram_output_path = os.path.join(output_path,"Raw_Claims_Bell_Curve.png")
plt.savefig(histogram_output_path, dpi=300, bbox_inches='tight')
plt.close("all")

#*********************************************************************************************************************
# ---------------------- Outlier Scatter Plot ----------------------
# Compute mean and standard deviation
raw_mean = np.mean(raw_claims)
raw_std = np.std(raw_claims)

# Define thresholds for outlier detection
lower_bound_2std = raw_mean - 2 * raw_std
upper_bound_2std = raw_mean + 2 * raw_std
lower_bound_1std = raw_mean - raw_std
upper_bound_1std = raw_mean + raw_std

# Identify outliers
outlier_mask = (raw_claims < lower_bound_2std) | (raw_claims > upper_bound_2std)
outlier_indices = np.where(outlier_mask)[0]
outlier_values = raw_claims[outlier_mask]

# Create scatter plot
plt.figure(figsize=(12, 7))
plt.scatter(range(len(raw_claims)), raw_claims, alpha=0.5, color='blue', label="Data")
plt.scatter(outlier_indices, outlier_values, color='red', label="Outliers")  # Highlight outliers in red

# Plot mean and standard deviation lines
plt.axhline(raw_mean, color='black', linestyle='dashed', label="Mean")
plt.axhline(lower_bound_1std, color='green', linestyle='dotted', label="-1 Std Dev")
plt.axhline(upper_bound_1std, color='green', linestyle='dotted', label="+1 Std Dev")
plt.axhline(lower_bound_2std, color='red', linestyle='dotted', label="-2 Std Dev")
plt.axhline(upper_bound_2std, color='red', linestyle='dotted', label="+2 Std Dev")

# Labels and title
plt.legend()
plt.title("Scatter Plot of Raw Claim Amounts with Outliers")
plt.xlabel("Index")
plt.ylabel("Claim Amount (Rands)")

# Save the plot
outlier_plot_path = os.path.join(output_path, "Outlier_Scatter_Plot.png")
plt.savefig(outlier_plot_path, dpi=300, bbox_inches='tight')
plt.close("all")

print(f"Outlier scatter plot saved: {outlier_plot_path}")




#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################
#*********************************************************************************************************************
# ---------------------- Compute Goodness-of-Fit ----------------------
def compute_gof(data, distribution, params):
    try:
        ks_stat, ks_pvalue = stats.kstest(data, distribution, args=params)
        log_likelihood = np.sum(np.log(stats.__dict__[distribution].pdf(data, *params)))
        aic = -2 * log_likelihood + 2 * len(params)
        bic = -2 * log_likelihood + len(params) * np.log(len(data))

        hist_values, bin_edges = np.histogram(data, bins=50, density=True)
        bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2
        pdf_values = stats.__dict__[distribution].pdf(bin_centers, *params)
        rmse = np.sqrt(mean_squared_error(hist_values, pdf_values))
        chi_square = np.sum(((hist_values - pdf_values) ** 2) / (pdf_values + 1e-6))

        supported_ad = {'norm': 'norm', 'expon': 'expon', 'logistic': 'logistic', 'gumbel': 'gumbel'}
        ad_statistic = anderson(data, dist=supported_ad[distribution]).statistic if distribution in supported_ad else np.nan

        result = {
            "KS_Statistic": ks_stat, "KS_P_Value": ks_pvalue, "AIC": aic, "BIC": bic,
            "Log_Likelihood": log_likelihood, "RMSE": rmse, "Chi_Square": chi_square,
            "Anderson-Darling": ad_statistic,
            "Fitted_Params": str(params) if params and all(np.isfinite(p) for p in params) else None
        }

        return result
    except Exception as e:
        return {
            "KS_Statistic": np.nan,
            "KS_P_Value": np.nan,
            "AIC": np.nan,
            "BIC": np.nan,
            "Log_Likelihood": np.nan,
            "RMSE": np.nan,
            "Chi_Square": np.nan,
            "Anderson-Darling": np.nan,
            "Fitted_Params": str(params),
            "Error": str(e)  # Optional for debugging
        }

# ---------------------- Fit Distributions and Compute GOF per Claim Reason ----------------------


#------------------Inflation Adjustment Section ------------------
inflated_path = os.path.join(output_path, "claims_policy_data_inflated.csv")

claims_inflated_df = df_claims_policy_data.copy()
claims_inflated_df.columns = claims_inflated_df.columns.str.strip()
claims_inflated_df['Claim Date'] = pd.to_datetime(claims_inflated_df['Claim Date'], errors='coerce')
claims_inflated_df = claims_inflated_df.dropna(subset=['Claim Date'])
claims_inflated_df['Claim Amount'] = pd.to_numeric(claims_inflated_df['Claim Amount'], errors='coerce')
claims_inflated_df = claims_inflated_df[claims_inflated_df['Claim Amount'] > 0]

# Remove extreme outliers
if 'claims_inflated_df' in globals():
    claims_inflated_df = remove_extreme_outliers(claims_inflated_df, 'Claim Amount')
    print(f"Removed extreme outliers from claims_inflated_df using ±3 std dev.")

today = pd.to_datetime(datetime.today().strftime('%Y-%m-%d'))
annual_inflation_rate = 0.051
monthly_inflation_rate = (1 + annual_inflation_rate) ** (1/12) - 1

claims_inflated_df['Months Since Claim'] = (
    (today.year - claims_inflated_df['Claim Date'].dt.year) * 12 +
    (today.month - claims_inflated_df['Claim Date'].dt.month)
).clip(lower=0)

claims_inflated_df['Claim Amount (Inflated)'] = claims_inflated_df['Claim Amount'] * (
    (1 + monthly_inflation_rate) ** claims_inflated_df['Months Since Claim']
)

claims_inflated_df.to_csv(inflated_path, index=False)
print("Claims inflated using 5.1% annual rate and saved.")

claim_values = claims_inflated_df[["Reason for Claim", "Claim Amount (Inflated)"]].dropna()

#------------------Goodnes of fit Section ------------------
# Validate claim_values
if claim_values.empty:
    raise ValueError("claim_values is empty. Check inflation logic or missing claim amounts.")

print(f"Proceeding with {len(claim_values)} non-null inflated claim values.")

# Reset index to allow safe alignment with transformations
claim_values = claim_values.reset_index(drop=True)

# Ensure transformation arrays are indexable by integer
transformations_indexed = {
    name: pd.Series(data, index=range(len(data))) for name, data in transformations.items()
}

# GOF storage
gof_results_all = []
with warnings.catch_warnings():
    warnings.simplefilter("ignore", category=RuntimeWarning)
    warnings.simplefilter("ignore", category=UserWarning)
    warnings.simplefilter("ignore", category=FutureWarning)
    warnings.simplefilter("ignore", category=DeprecationWarning) 
    warnings.simplefilter("ignore", category=IntegrationWarning) 
    
    for claim_reason in claim_values["Reason for Claim"].unique():
        # Filter only rows for this reason
        reason_indices = claim_values[claim_values["Reason for Claim"] == claim_reason].index
    
        for trans_name, trans_data in transformations_indexed.items():
            # Align transformation data to same index
            data = trans_data.loc[reason_indices].dropna()
    
            if data.empty:
                print(f"⚠️ Skipping {claim_reason} - {trans_name}: No data after transformation.")
                continue
    
            for dist_name in distributions_to_fit:
                try:
                    dist = getattr(stats, dist_name)
                    params = dist.fit(data)
                    gof_metrics = compute_gof(data, dist_name, params)
    
                    gof_results_all.append({
                        "Claim Reason": claim_reason,
                        "Transformation": trans_name,
                        "Distribution": dist_name,
                        **gof_metrics
                    })
    
                except Exception as e:
                    continue

#Final check
if not gof_results_all:
    raise RuntimeError("No GOF results were produced. Check input data and fitting logic.")

print(f"GOF fitting completed for {len(gof_results_all)} combinations.")

# ---------------------- Aggregate and Rank GOF ----------------------
gof_df = pd.DataFrame(gof_results_all)

# Ensure metric columns exist
metrics_list = ["AIC", "BIC", "KS_Statistic", "KS_P_Value", "RMSE", "Chi_Square", "Anderson-Darling"]
for metric in metrics_list:
    if metric not in gof_df.columns:
        gof_df[metric] = np.nan

# Rank within each Claim Reason and Transformation
def rank_models_weighted(group):
    group = group.copy()
    group["Total_Rank"] = (
        2 * (group["AIC"].rank(method="min") + group["BIC"].rank(method="min")) +
        group["KS_Statistic"].rank(method="min") +
        (-group["KS_P_Value"]).rank(method="min")  # Higher is better
    )
    return group

if not gof_df.empty:
    gof_df = gof_df.groupby(["Claim Reason", "Transformation"], group_keys=False).apply(rank_models_weighted).reset_index(drop=True)
    gof_df["Best_Fit"] = gof_df.groupby(["Claim Reason", "Transformation"])["Total_Rank"].rank(method="first") == 1
else:
    print("No GOF results generated.")

# Final column order
cols_order = ["Claim Reason", "Transformation", "Distribution", "AIC", "BIC", "KS_Statistic", 
              "KS_P_Value", "Log_Likelihood", "RMSE", "Chi_Square", "Anderson-Darling",
              "Fitted_Params", "Total_Rank", "Best_Fit"]

gof_df = gof_df[[col for col in cols_order if col in gof_df.columns]]

# Save to Excel
gof_output_file = os.path.join(output_path, "5. Claim Distribution Statistics.csv")
gof_df.to_csv(gof_output_file, index=False)

print(f"Saved GOF results per Claim Reason and Transformation to: {gof_output_file}")






#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#####################################################################################################################

#*********************************************************************************************************************
# ---------------------- Generate QQ Plots for All Transformations ----------------------
#
gof_results_path = os.path.join(output_path, "5. Claim Distribution Statistics.csv")

# Load stored GOF results
gof_df = pd.read_csv(gof_results_path)

# Ensure the Fitted_Params column exists
if "Fitted_Params" not in gof_df.columns:
    print("Error: Fitted_Params column is missing in GOF results. Aborting QQ plot generation.")
    exit()

# Iterate only through distributions that have fitted parameters

# Filter only the best-fit rows
best_fit_df = gof_df[gof_df.get("Best_Fit", False) == True]

for _, row in best_fit_df.iterrows():
    transformation = row["Transformation"]
    distribution_name = row["Distribution"]
    params_str = row.get("Fitted_Params", None)

    # Skip if parameters are missing
    if not params_str or pd.isnull(params_str):
        print(f"Skipping QQ plot for {transformation} - {distribution_name} due to missing parameters.")
        continue

    try:
        # Convert parameter string to a tuple
        params = ast.literal_eval(params_str)

        # Ensure all parameters are valid
        if not params or any(np.isnan(p) or np.isinf(p) for p in params):
            print(f"Skipping QQ plot for {transformation} - {distribution_name} due to invalid parameters: {params}")
            continue

    except (ValueError, SyntaxError):
        print(f"Skipping QQ plot for {transformation} - {distribution_name} due to parsing error: {params_str}")
        continue

    # Get transformation data
    if transformation not in transformations:
        print(f"Skipping QQ plot for {transformation} as transformation data is missing.")
        continue
    data = transformations[transformation]

    try:
        # Generate theoretical quantiles
        dist = stats.__dict__[distribution_name]
        sorted_data = np.sort(data)
        probs = np.linspace(0.001, 0.999, len(sorted_data))
        theoretical_quantiles = dist.ppf(probs, *params)

        # Validate quantiles
        if np.any(np.isnan(theoretical_quantiles)) or np.any(np.isinf(theoretical_quantiles)):
            print(f"Skipping QQ plot for {transformation} - {distribution_name} due to invalid quantiles.")
            continue

        # Generate QQ Plot
        plt.figure(figsize=(10, 6))
        plt.scatter(theoretical_quantiles, sorted_data, alpha=0.5, label="Observed Data")
        plt.plot(
           [min(theoretical_quantiles), max(theoretical_quantiles)],
           [min(theoretical_quantiles), max(theoretical_quantiles)],
           color='red', linestyle='--', label='Ideal Fit'
        )
        plt.xlabel(f"Theoretical Quantiles ({distribution_name})")
        plt.ylabel(f"Observed Quantiles ({transformation})")
        plt.title(f"QQ Plot - {transformation} ({distribution_name})")
        plt.legend()
        plt.grid(True)

        # Save QQ plot
        qq_filename = os.path.join(QQ_output_path, f"QQ_{transformation}_{distribution_name}.png")
        plt.savefig(qq_filename, dpi=300, bbox_inches='tight')
        plt.close("all")

        

    except Exception as e:
        print(f"Failed to generate QQ plot for {transformation} - {distribution_name}: {e}")

print(f"All valid QQ plots saved in: {output_path}")




# ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
#####################################################################################################################
# Reason + Make Level Severity Fitting Script
# ------------ Load Claims Data ------------ #
input_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/DPP Turbo/"
claims_file = os.path.join(input_path, "claims_policy_data.xlsx")
claims_df = pd.read_excel(claims_file)

# Clean data
claims_df = claims_df[pd.to_numeric(claims_df["Claim Amount"], errors="coerce") >= 1].copy()
claims_df["Claim Amount"] = claims_df["Claim Amount"].astype(float)

# Standardize columns
claims_df.columns = claims_df.columns.str.strip()

# Remove extreme outliers
if 'claims_df' in globals():
    claims_df = remove_extreme_outliers(claims_df, 'Claim Amount')
    print(f"Removed extreme outliers from claims_df using ±3 std dev.")

# ------------ Fit Config ------------ #
credibility_threshold = 30  # Minimum claims per (reason, make)
distributions_to_fit = ["gamma", "lognorm"]

# ------------ Filter Credible Groups ------------ #
grouped = claims_df.groupby(["Reason for Claim", "Vehicle Make"])
credible_groups = {group: df for group, df in grouped if len(df) >= credibility_threshold}

# ------------ Fit Best Distribution ------------ #
fit_results = {}

for (reason, make), df_sub in credible_groups.items():
    data = df_sub["Claim Amount"].dropna().values
    try:
        f = Fitter(data, distributions=distributions_to_fit, timeout=10)
        f.fit()
        best_dist = f.get_best(method="sumsquare_error")
        dist_name, params = list(best_dist.items())[0]
        fit_results[(reason, make)] = (dist_name, params)
    except Exception as e:
        continue

# ------------ Save to CSV ------------ #
output_path = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/DPP Turbo/"
fit_results_df = pd.DataFrame([
    {"Claim Reason": reason, "Vehicle Make": make, 
     "Distribution": dist, "Fitted_Params": str(params)}
    for (reason, make), (dist, params) in fit_results.items()
])

fit_results_df.to_csv(os.path.join(output_path, "6.0 Reason-Make Severity Distributions.csv"), index=False)
print("✅ Saved: Reason-Make severity fits")







# ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅
#####################################################################################################################
# ---------------------- MCMC ----------------------
# Define paths
claims_distribution_file = os.path.join(output_path, "5. Claim Distribution Statistics.csv")
schedule_of_benefits_file = os.path.join(input_path, "schedule_of_benefits.xlsx")
actual_freq_path = os.path.join(output_path, "2. Claim Frequency Analysis.xlsx")
simulated_claims_file = os.path.join(output_path, "6.1 Simulated Claims.csv")
simulated_claims_summary = os.path.join(output_path, "6.2 Simulated Claims Summary.xlsx")
policy_data_path = os.path.join(input_path, "claims_policy_data.xlsx")

# Load data
schedule_benefits_df = pd.read_excel(schedule_of_benefits_file, sheet_name="Sheet1")
gof_results_df = pd.read_csv(claims_distribution_file)
gof_results_df.columns = gof_results_df.columns.str.encode('ascii', 'ignore').str.decode('ascii').str.strip()
actual_freq_df = pd.read_excel(actual_freq_path, sheet_name="By Reason")
actual_freq_df.columns = actual_freq_df.columns.str.strip()
policy_data_df = pd.read_excel(policy_data_path, sheet_name=0)

# Fix column name casing
policy_data_df.columns = policy_data_df.columns.str.strip().str.lower()

# Remove extreme outliers
if 'policy_data_df' in globals():
    policy_data_df = remove_extreme_outliers(policy_data_df, 'claim amount')
    print(f"Removed extreme outliers from claims using ±3 std dev.")

# Determine active policies based on expiry date
policy_data_df['expiry date'] = pd.to_datetime(policy_data_df['expiry date'], errors='coerce')
today = pd.to_datetime("today")
active_policy_count = policy_data_df[policy_data_df['expiry date'] >= today].shape[0]
fallback_min_exposure = active_policy_count * months  #fallback based on active policies
print(f"Active policy count: {active_policy_count:,} → Fallback exposure: {fallback_min_exposure:,} months")

# ------------------ Simulation Diagnostics ------------------
sample_claims = claims_inflated_df["Claim Amount (Inflated)"].dropna()
mean_claim = sample_claims.mean()
std_claim = sample_claims.std()
z_score = 1.96
relative_error = 0.02
required_n = int(np.ceil((z_score * std_claim / (relative_error * mean_claim)) ** 2))
num_simulations = max(5000, required_n)
print(f"Estimated minimum simulations: {required_n:,}")

#################################################################################
# ------------------ Simulation Stability Testing ------------------
def calculate_var(data, confidence_level=0.95):
    return np.percentile(data, (1 - confidence_level) * 100)

def calculate_tvar(data, confidence_level=0.95):
    var = calculate_var(data, confidence_level)
    return data[data >= var].mean()

def probability_of_ruin(data, reserve):
    return np.mean(data > reserve)

sim_sizes = [1000, 2000, 5000, 10000, 20000]
stability_results = []

claim_pool = claims_inflated_df["Claim Amount (Inflated)"].dropna().values
reserve = premium_per_policy * num_policies

for n in sim_sizes:
    simulated_sample = np.random.choice(claim_pool, size=n, replace=True)

    mean_claim = simulated_sample.mean()
    std_dev = simulated_sample.std()
    var_95 = calculate_var(simulated_sample, 0.95)
    tvar_95 = calculate_tvar(simulated_sample, 0.95)
    ruin_prob = probability_of_ruin(simulated_sample, reserve)

    stability_results.append({
        "Simulations": n,
        "Mean Claim": round(mean_claim, 2),
        "Std Dev": round(std_dev, 2),
        "VaR 95%": round(var_95, 2),
        "TVaR 95%": round(tvar_95, 2),
        "Ruin Probability": round(ruin_prob, 4)
    })

# Save to Excel
stability_df = pd.DataFrame(stability_results)
stability_output = os.path.join(output_path, "0. Simulation Stability Testing.xlsx")
stability_df.to_excel(stability_output, index=False)
print(f"✅ Simulation Stability Testing saved to: {stability_output}")


###########################################################################################################
actual_freq_df = actual_freq_df[["Reason for Claim", "Annualized Claim Frequency (%)", "Exposure Months"]]
actual_freq_df.rename(columns={"Reason for Claim": "Claim Reason",
                               "Annualized Claim Frequency (%)": "Actual Frequency",
                               "Exposure Months": "Exposure_Months"}, inplace=True)

# ------------------ Claim Reason Weights (Actual with fallback logic) ------------------
weights_df = actual_freq_df[actual_freq_df["Actual Frequency"] > 0].copy()
weights_df["Weight"] = weights_df["Actual Frequency"] / weights_df["Actual Frequency"].sum()

all_reasons = list(schedule_benefits_df["Benefit Name"].unique())
fallback_reasons = list(set(all_reasons) - set(weights_df["Claim Reason"]))
fallback_weights = pd.DataFrame({"Claim Reason": fallback_reasons,
                                 "Weight": [weights_df["Weight"].mean()] * len(fallback_reasons)})
final_weights = pd.concat([weights_df[["Claim Reason", "Weight"]], fallback_weights], ignore_index=True)
final_weights["Target Weight"] = final_weights["Weight"] / final_weights["Weight"].sum()

# ------------------ Historical claim distribution parameters for fallback ------------------
claim_amounts = claims_inflated_df["Claim Amount (Inflated)"].dropna().values
log_claims = np.log(claim_amounts[claim_amounts > 0])
log_mu, log_sigma = log_claims.mean(), log_claims.std()
gamma_shape = (claim_amounts.mean() ** 2) / claim_amounts.var()
gamma_scale = claim_amounts.var() / claim_amounts.mean()

historical_mean = claim_amounts.mean()
claim_values = claim_amounts.reshape(-1, 1)
gmm = GaussianMixture(n_components=min(3, len(claim_values)), random_state=42).fit(claim_values)
benefit_gmm_mapping = {b: np.random.choice(range(gmm.n_components)) for b in all_reasons}

# ------------------ Distributions ------------------
best_fit_distributions = gof_results_df[gof_results_df["Best_Fit"].astype(str) == "TRUE"]
distribution_mapping = {}
for _, row in best_fit_distributions.iterrows():
    name = row["Distribution"]
    try:
        distribution_mapping[name] = getattr(__import__('scipy.stats', fromlist=[name]), name)
    except AttributeError:
        print(f"Warning: {name} not found.")

# ------------------ Simulate fallback claims ------------------
def simulate_fallback_claims(fallback_benefits, schedule_benefits_df, historical_claims_df,
                             log_mu, log_sigma, gamma_shape, gamma_scale,
                             z_score=1.96, relative_error=0.02):
    fallback_claims = []
    vehicle_makes = historical_claims_df["Vehicle Make"].dropna().unique()
    for benefit in fallback_benefits:
        if benefit not in schedule_benefits_df.index:
            continue
        limit, start, end = schedule_benefits_df.loc[benefit, ["Limit", "Start", "End"]]
        start, end = int(start), int(end)
        lambda_prior = 1.5
        sigma = np.sqrt(lambda_prior)
        n_required = int(np.ceil((z_score * sigma / (relative_error * lambda_prior)) ** 2))
        n_required = min(n_required, 5)
        for _ in range(n_required):
            vehicle = np.random.choice(vehicle_makes)
            claim_period = np.random.randint(start, end + 1)
            if np.random.rand() < 0.5:
                raw_claim = lognorm(s=log_sigma, scale=np.exp(log_mu)).rvs()
            else:
                raw_claim = gamma(a=gamma_shape, scale=gamma_scale).rvs()
            random_factor = np.random.uniform(0.95, 1.05)
            claim_cost = raw_claim * random_factor
            claim_cost = round(np.clip(claim_cost, 0.6 * limit, limit), 2)
            fallback_claims.append([vehicle, benefit, claim_period, claim_cost, limit])
    return fallback_claims

# Benefit limits index
benefit_limits = schedule_benefits_df.set_index("Benefit Name")[["Limit", "Start", "End"]]


#To ensure each insured component under the SOB is reflected in the simulation outputs, we enforced a single simulated claim per benefit at the start of the sampling process.
#This technique ensures product completeness and supports downstream reserve, frequency, and pricing analyses for every benefit line item.
#In low-frequency environments to ensure representation without distorting the aggregate risk distribution.


# Simulate
# Step 1: Force at least one claim per benefit
forced_reasons = list(schedule_benefits_df["Benefit Name"].unique())
forced_periods = np.random.randint(1, months + 1, len(forced_reasons))
forced_makes = np.random.choice(claims_inflated_df["Vehicle Make"].dropna().unique(), len(forced_reasons))

# Step 2: Sample the remaining needed
remaining_n = num_simulations - len(forced_reasons)
sampled_reasons = np.random.choice(final_weights["Claim Reason"], size=remaining_n, p=final_weights["Target Weight"])
sampled_periods = np.random.randint(1, months + 1, remaining_n)
sampled_makes = np.random.choice(claims_inflated_df["Vehicle Make"].dropna().unique(), remaining_n)

# Step 3: Combine both
claim_reasons = list(forced_reasons) + list(sampled_reasons)
claim_periods = list(forced_periods) + list(sampled_periods)
vehicle_makes = list(forced_makes) + list(sampled_makes)




simulated_claims = []

for i in range(num_simulations):
    benefit_name = claim_reasons[i]
    
    if benefit_name in benefit_limits.index:
        start, end = benefit_limits.loc[benefit_name, ["Start", "End"]]
        
        if not (start <= claim_periods[i] <= end):
            claim_periods[i] = np.random.randint(start, end + 1)
        limit = float(benefit_limits.loc[benefit_name, "Limit"])
        
        if benefit_name in best_fit_distributions["Claim Reason"].values:
            dist_row = best_fit_distributions[best_fit_distributions["Claim Reason"] == benefit_name].iloc[0]
            dist_name = dist_row["Distribution"]
            params = eval(dist_row["Fitted_Params"])
            
            dist_func = distribution_mapping.get(dist_name, None)
            if dist_func:
                raw_value = dist_func.rvs(*params)
            else:
                # fallback
                if np.random.rand() < 0.5:
                    raw_value = lognorm(s=log_sigma, scale=np.exp(log_mu)).rvs()
                else:
                    raw_value = gamma(a=gamma_shape, scale=gamma_scale).rvs()
        else:
            # fallback
            if np.random.rand() < 0.5:
                raw_value = lognorm(s=log_sigma, scale=np.exp(log_mu)).rvs()
            else:
                raw_value = gamma(a=gamma_shape, scale=gamma_scale).rvs()
        
        gmm_sample = float(gmm.sample()[0][0][0])
        random_factor = np.random.uniform(0.95, 1.05)
        value = raw_value * (gmm_sample / max(historical_mean, 1)) * random_factor
        value = round(np.clip(value, 0.6 * limit, limit), 2)
        value = max(value, np.random.uniform(0.95, 1.5) * limit)
        simulated_claims.append([vehicle_makes[i], benefit_name, claim_periods[i], value, limit])

simulated_df = pd.DataFrame(simulated_claims, columns=["Vehicle Make", "Claim Reason", "Claim Period", "Claim Cost", "Benefit Limit"])
simulated_reasons = set(simulated_df["Claim Reason"])
all_reasons = set(schedule_benefits_df["Benefit Name"])
fallback_reasons = list(all_reasons - simulated_reasons)

fallback_claims = simulate_fallback_claims(
    fallback_benefits=fallback_reasons,
    schedule_benefits_df=schedule_benefits_df,
    historical_claims_df=claims_inflated_df,
    log_mu=log_mu,
    log_sigma=log_sigma,
    gamma_shape=gamma_shape,
    gamma_scale=gamma_scale
)
simulated_claims.extend(fallback_claims)

if not simulated_claims:
    raise ValueError("No claims were simulated. Check SOB 'Start'/'End' windows or final_weights content.")

print(f"Total claims simulated: {len(simulated_claims)}")

# Post-simulation: Ensure all SOB reasons are represented
simulated_df = pd.DataFrame(simulated_claims, columns=["Vehicle Make", "Claim Reason", "Claim Period", "Claim Cost", "Benefit Limit"])
simulated_reasons = set(simulated_df["Claim Reason"])
all_reasons = set(schedule_benefits_df["Benefit Name"])
fallback_reasons = list(all_reasons - simulated_reasons)

if fallback_reasons:
    print("❗Missing simulated claims for the following SOB benefits:")
    for reason in fallback_reasons:
        print(" -", reason)
else:
    print("✅ All SOB benefits are represented in the simulated claims.")

################################################### Create the DataFrame##################################################################
simulated_claims_df = pd.DataFrame(simulated_claims, columns=["Vehicle Make", "Claim Reason", "Claim Period", "Claim Cost", "Benefit Limit"])

# Enforce SOB cap post-simulation
simulated_claims_df["Capped Claim Cost"] = np.where(
    simulated_claims_df["Claim Cost"] > simulated_claims_df["Benefit Limit"],
    simulated_claims_df["Benefit Limit"],
    simulated_claims_df["Claim Cost"]
)
simulated_claims_df["Claim Cost"] = simulated_claims_df["Capped Claim Cost"]

simulated_claims_df["GMM Component"] = simulated_claims_df["Claim Reason"].map(benefit_gmm_mapping)

simulated_claims_df["Frequency Source"] = np.where(simulated_claims_df["Claim Reason"].isin(weights_df["Claim Reason"]), "Actual", "Simulated")

#################################################### Summary##################################################################
summary_stats = simulated_claims_df.groupby("Claim Reason")["Claim Cost"].describe(percentiles=[.25, .5, .75]).reset_index()
summary_stats.rename(columns={"mean": "Mean", "std": "Std Dev", "min": "Min", "25%": "P25", "50%": "Median", "75%": "P75", "max": "Max"}, inplace=True)

claim_counts = simulated_claims_df["Claim Reason"].value_counts().reset_index()
claim_counts.columns = ["Claim Reason", "Total Claims"]

summary_stats = pd.merge(pd.DataFrame({"Claim Reason": list(all_reasons)}), summary_stats, on="Claim Reason", how="left")
summary_stats = pd.merge(summary_stats, claim_counts, on="Claim Reason", how="left")
summary_stats[["Mean", "Std Dev", "Min", "P25", "Median", "P75", "Max", "Total Claims"]] = summary_stats[["Mean", "Std Dev", "Min", "P25", "Median", "P75", "Max", "Total Claims"]].fillna(0)

# Merge actual frequency and exposure
actual_inputs = actual_freq_df[["Claim Reason", "Exposure_Months", "Actual Frequency"]].rename(columns={"Exposure_Months": "Actual Exposure"})
summary_stats = summary_stats.merge(actual_inputs, on="Claim Reason", how="left")

# Simulated exposure fallback
# Build exposure map and assign fallback exposures
actual_inputs = actual_freq_df[["Claim Reason", "Exposure_Months", "Actual Frequency"]].rename(columns={"Exposure_Months": "Actual Exposure"})
exposure_map = actual_inputs.set_index("Claim Reason")["Actual Exposure"].to_dict()
simulated_exposure = num_simulations * months  
sim_reason_weights = final_weights.set_index("Claim Reason")["Target Weight"].to_dict()
total_weight = sum(sim_reason_weights.values())

summary_stats["Exposure"] = summary_stats["Claim Reason"].apply(
    lambda reason: exposure_map.get(
        reason,
        max(fallback_min_exposure, sim_reason_weights.get(reason, 0) / total_weight * simulated_exposure)
    )
)

summary_stats["Frequency"] = summary_stats.apply(
    lambda row: round((row["Total Claims"] / row["Exposure"]) * 12 * 100, 8) if row["Exposure"] > 0 else 0.0,
    axis=1
)

summary_stats["Data Source"] = summary_stats["Claim Reason"].apply(lambda x: "Actual" if x in weights_df["Claim Reason"].values else "Simulated")
summary_stats["Frequency Source"] = summary_stats["Data Source"]
summary_stats.drop(columns=["Actual Frequency", "Actual Exposure"], inplace=True, errors="ignore")

# Order
ordered_cols = [
    "Claim Reason", "Mean", "Std Dev", "Min", "P25", "Median", "P75", "Max",
    "Total Claims", "Exposure", "Frequency", "Data Source"
]
summary_stats = summary_stats[[col for col in ordered_cols if col in summary_stats.columns]].sort_values(by="Claim Reason")

    
# Save outputs
with pd.ExcelWriter(simulated_claims_summary, engine="xlsxwriter") as writer:
    summary_stats.to_excel(writer, sheet_name="Summary Statistics", index=False)
    simulated_claims_df.to_csv(simulated_claims_file, index=False)

print(f"Simulated summary saved to: {simulated_claims_summary}")
print(f"Simulated claims saved to: {simulated_claims_file}")





#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
#***********************************************************************************
# Define output file path for the plot
histogram_plot_path = os.path.join(output_path, "Simulated_Claims_Histogram.png")

# Plot histogram with KDE and linear trend
plt.figure(figsize=(10, 6))
sns.histplot(simulated_claims_df["Claim Cost"], bins=50, kde=True, color="blue", alpha=0.6)
sns.regplot(x=np.arange(len(simulated_claims_df)), y=simulated_claims_df["Claim Cost"], scatter=False, color="red")

# Add labels and title
plt.title("Histogram of Simulated Claim Costs with KDE and Linear Trend")
plt.xlabel("Claim Cost")
plt.ylabel("Number of Claims")

# Save the plot to the output directory
plt.savefig(histogram_plot_path, dpi=300, bbox_inches='tight')
plt.close("all")  # Close the figure to free memory

print(f"Histogram plot saved to: {histogram_plot_path}")










#✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ ✅ 
################################################################################
# ----------------------- Risk Analyses -----------------------
def calculate_var(data, confidence_level=0.95):
    return np.percentile(data, (1 - confidence_level) * 100)

def calculate_tvar(data, confidence_level=0.95):
    var = calculate_var(data, confidence_level)
    return data[data >= var].mean()  # Use values >= var for TVaR calculation

def probability_of_ruin(data, reserve):
    return np.mean(data > reserve)

# Extract claim amounts from simulation
simulated_claims_file = os.path.join(output_path, "6.1 Simulated Claims.csv")
simulated_claims_df = pd.read_csv(simulated_claims_file)

#Extract claim ammounts from actuals
actual_claims_file = os.path.join(output_path, "Imported_Claims_Data.csv")
actual_claims_df = pd.read_csv(actual_claims_file)

non_zero_claims = simulated_claims_df[simulated_claims_df["Claim Cost"] > 0]

# Extract the "Claim Cost" column for risk analysis, ensuring it is numeric
claim_amounts = pd.to_numeric(simulated_claims_df["Claim Cost"], errors='coerce').dropna().values.astype(float)

# Calculate VaR and TVaR
confidence_levels = [0.95, 0.99]
var_results = {level: calculate_var(claim_amounts, level) for level in confidence_levels}
tvar_results = {level: calculate_tvar(claim_amounts, level) for level in confidence_levels}

# Probability of Ruin Calculation
ruin_probability = probability_of_ruin(claim_amounts, total_reserve)



# ----------------------- Plot VaR and TVaR -----------------------
plt.figure(figsize=(10, 6))
sns.kdeplot(claim_amounts, fill=True, label='Claim Distribution')

# Plot VaR
plt.axvline(var_results[0.95], color='red', linestyle='--', label='VaR 95%')
plt.axvline(var_results[0.99], color='blue', linestyle='--', label='VaR 99%')

# Plot TVaR
plt.axvline(tvar_results[0.95], color='green', linestyle='-.', label='TVaR 95%')
plt.axvline(tvar_results[0.99], color='purple', linestyle='-.', label='TVaR 99%')

# Ensure legend and title
plt.legend()
plt.title('Value at Risk and Tail Value at Risk')
plt.xlabel('Claim Cost')
plt.ylabel('Density')

# Save plot
plot_output_path =os.path.join(output_path,"Risk Analysis VaR TVar Plot.png")
plt.savefig(plot_output_path)
plt.close("all")

# ----------------------- Statistical Summary -----------------------
# Number of simulated claims (non-zero ones)
simulated_claim_count = len(non_zero_claims)

# Actual total exposure in months across all policies
total_exposure_months_sim = num_policies * months

# Extract total annualized claim frequency from summary DataFrame
try:
    actual_frequency = float(
        total_frequency_df.loc[total_frequency_df["Metric"] == "Total Annualized Frequency (%)", "Value"].values[0]
    )
except (KeyError, IndexError, ValueError):
    actual_frequency = None
    print("⚠️ Warning: Could not extract actual_frequency.")

# Compute the expected claim value under the new schedule
mean_simulated_claim = simulated_claims_df["Claim Cost"].mean()

# Compute the historical average claim value
mean_actual_claim = actual_claims_df["Claim Amount"].mean()

# Compute severity ratio (adjustment factor)
severity_ratio = mean_simulated_claim / mean_actual_claim

adjusted_annualized_frequency = (actual_frequency * severity_ratio)

claim_cost_summary = non_zero_claims["Claim Cost"].describe(percentiles=[0.25, 0.50, 0.75])
num_1000_claims = (non_zero_claims["Claim Cost"] == 1000).sum()
percentage_1000_claims = (num_1000_claims / len(non_zero_claims)) * 100
claims_hitting_low_threshold = (non_zero_claims["Claim Cost"] <= 1000).sum()
percentage_hitting_low_threshold = (claims_hitting_low_threshold / len(non_zero_claims)) * 100
claim_reason_counts = non_zero_claims["Claim Reason"].value_counts(normalize=True) * 100

# Prepare results for display
updated_analysis_results = {
    "Total Claims": len(non_zero_claims),
    "Mean Claim Cost": claim_cost_summary["mean"],
    "25th Percentile": claim_cost_summary["25%"],
    "Median (50th Percentile)": claim_cost_summary["50%"],
    "75th Percentile": claim_cost_summary["75%"],
    "Max Claim Cost": claim_cost_summary["max"],
    "Number of Claims at R1000": num_1000_claims,
    "Percentage of Claims at R1000": percentage_1000_claims,
    "Claims ≤ R1000": claims_hitting_low_threshold,
    "Percentage of Claims ≤ R1000": percentage_hitting_low_threshold,
    "Top Claim Reason %": claim_reason_counts.iloc[0] if not claim_reason_counts.empty else 0,
    "Top Claim Reason": claim_reason_counts.idxmax() if not claim_reason_counts.empty else "N/A",
    "Annualized Frequency": actual_frequency,
    "Adjusted Annualized Frequency": adjusted_annualized_frequency,
}

# Convert to DataFrame for easy export
summary_df = pd.DataFrame.from_dict(updated_analysis_results, orient="index", columns=["Value"])

# ----------------------- Save results to Excel -----------------------
# Save risk metrics to Excel
risk_output_path = os.path.join(output_path, "7. Risk Analysis Results.xlsx")
with pd.ExcelWriter(risk_output_path, engine="xlsxwriter") as writer:
    pd.DataFrame.from_dict(var_results, orient='index', columns=['VaR']).to_excel(writer, sheet_name='VaR')
    pd.DataFrame.from_dict(tvar_results, orient='index', columns=['TVaR']).to_excel(writer, sheet_name='TVaR')
    pd.DataFrame({'Probability of Ruin': [ruin_probability]}).to_excel(writer, sheet_name='Probability of Ruin')

    non_zero_claims.to_excel(writer, sheet_name="Simulated Claims", index=False)
    summary_df.to_excel(writer, sheet_name="Claim Summary", index=True)
    workbook = writer.book
    worksheet = writer.sheets["Simulated Claims"]



    
#*********************************************************************************************************************
# ---------------------- Gaussian Mixture Model (GMM) ----------------------
# Re-load actual claims data
imported_claims_file = os.path.join(output_path, "Imported_Claims_Data.csv")
raw_claims_df = pd.read_csv(imported_claims_file)
raw_claims_df = raw_claims_df[pd.to_numeric(raw_claims_df["Claim Amount"], errors="coerce") >= 1]
raw_claims = pd.to_numeric(raw_claims_df["Claim Amount"], errors='coerce').dropna().values

# Load simulated claims data
simulated_claims_file = os.path.join(output_path, "6.1 Simulated Claims.csv")
simulated_claims_df = pd.read_csv(simulated_claims_file)
simulated_claims_df = simulated_claims_df[simulated_claims_df["Claim Cost"] > 0]
simulated_claims = pd.to_numeric(simulated_claims_df["Claim Cost"], errors='coerce').dropna().values


# ---------------------- GMM Graph Actuals & Simulated ----------------------
simulated_claims_array = simulated_claims.reshape(-1, 1)

# Generate x values for KDE estimation
x_actual = np.linspace(min(raw_claims), max(raw_claims), 1000)
x_simulated = np.linspace(min(simulated_claims), max(simulated_claims), 1000)

# Kernel Density Estimation (KDE) for actual and simulated claims
kde_actual = stats.gaussian_kde(raw_claims)
kde_pdf_actual = kde_actual(x_actual)

kde_simulated = stats.gaussian_kde(simulated_claims)
kde_pdf_simulated = kde_simulated(x_simulated)

# ---------------------- Plot histograms with borders and KDE ----------------------
plt.figure(figsize=(14, 8))

# Histogram for actual claims with black border
plt.hist(raw_claims, bins=50, alpha=0.6, color='grey', edgecolor='black', density=True, label="Actual Data")

# Histogram for simulated claims with black border
plt.hist(simulated_claims, bins=50, alpha=0.4, color='red', edgecolor='black', density=True, label="Simulated Data")

# KDE plot for actual claims
plt.plot(x_actual, kde_pdf_actual, color='black', linestyle='solid', label="Actual KDE")

# KDE plot for simulated claims
plt.plot(x_simulated, kde_pdf_simulated, color='red', linestyle='dashed', label="Simulated KDE")

# Dynamically set y-axis based on max of both KDEs
y_max_combined = max(np.max(kde_pdf_actual), np.max(kde_pdf_simulated)) * 1.1  # Add 10% buffer
plt.ylim(0, y_max_combined)

plt.title("Gaussian Mixture Model - Actual vs Simulated Claims with Bins & KDE")
plt.xlabel("Claim Amount")
plt.ylabel("Density")
plt.legend()

# Save the new plot
gmm_binned_kde_plot_path = os.path.join(output_path, "6.1. Gaussian_Mixture_Model_Actual_Simulated.png")
plt.gca().xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f'{int(x/1000):,}k'))
plt.savefig(gmm_binned_kde_plot_path, dpi=300, bbox_inches='tight')


print(f"Binned GMM plot with KDE for actual and simulated claims saved: {gmm_binned_kde_plot_path}")







################################################################################
# ----------------------- MCMC Scatter Plot -----------------------

# Load simulated claims data
simulated_claims_file = os.path.join(output_path, "6.1 Simulated Claims.csv")
simulated_claims_df = pd.read_csv(simulated_claims_file)
simulated_claims_df = simulated_claims_df[simulated_claims_df["Claim Cost"] > 0]
simulated_claims = pd.to_numeric(simulated_claims_df["Claim Cost"], errors='coerce').dropna().values

# Extract values
claim_period = simulated_claims_df["Claim Period"]
claim_cost = simulated_claims_df["Claim Cost"]
gmm_component = simulated_claims_df["GMM Component"]


# Prepare data
mean_cost = claim_cost.mean()
std_cost = claim_cost.std()

# Identify outliers: beyond ±2 standard deviations
outliers_mask = (claim_cost > mean_cost + 2 * std_cost) | (claim_cost < mean_cost - 2 * std_cost)
outliers = claim_cost[outliers_mask]
non_outliers = claim_cost[~outliers_mask]

# Create scatter plot with index on x-axis
plt.figure(figsize=(14, 7))

# Plot non-outliers
plt.scatter(non_outliers.index, non_outliers, label='Data', color='blue', alpha=0.6)

# Plot outliers
plt.scatter(outliers.index, outliers, label='Outliers', color='red', alpha=0.8)

# Plot mean and standard deviation lines
plt.axhline(mean_cost, color='black', linestyle='--', label='Mean')
plt.axhline(mean_cost + std_cost, color='green', linestyle='dotted', label='+1 Std Dev')
plt.axhline(mean_cost - std_cost, color='green', linestyle='dotted', label='-1 Std Dev')
plt.axhline(mean_cost + 2 * std_cost, color='red', linestyle='dotted', label='+2 Std Dev')
plt.axhline(mean_cost - 2 * std_cost, color='red', linestyle='dotted', label='-2 Std Dev')

# Format plot
plt.title("Scatter Plot of Claim Cost with Outliers Highlighted")
plt.xlabel("Index")
plt.ylabel("Claim Cost (Rands)")
plt.legend()
plt.grid(True)
plt.tight_layout()
scatter_plot_path = os.path.join(output_path, "Simulated_scatter_plot.png")
plt.savefig(scatter_plot_path, dpi=300, bbox_inches='tight')

# trace plot
plt.figure(figsize=(14, 5))
plt.plot(simulated_claims, color='blue', alpha=0.6)
plt.title("MCMC Trace Plot of Simulated Claim Costs")
plt.xlabel("Iteration")
plt.ylabel("Claim Cost (Rands)")
plt.grid(True)
plt.tight_layout()
trace_plot_path = os.path.join(output_path, "MCMC_trace_plot.png")
plt.savefig(trace_plot_path, dpi=300, bbox_inches='tight')


#Posterior
plt.figure(figsize=(10, 6))
plt.hist(simulated_claims, bins=50, color='skyblue', edgecolor='black', density=True)
plt.title("Posterior Distribution of Simulated Claim Costs")
plt.xlabel("Claim Cost (Rands)")
plt.ylabel("Density")
plt.grid(True)
plt.tight_layout()
posterior_plot_path = os.path.join(output_path, "MCMC_posterior_distribution.png")
plt.savefig(posterior_plot_path, dpi=300, bbox_inches='tight')






# -----------------------Risk Analyses on Simulations-----------------------
# Additional stress tests, scenario analysis, MCMC plot.

