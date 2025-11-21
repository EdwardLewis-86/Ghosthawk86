# === LIBRARIES ===
import pandas as pd
import numpy as np

# === CONFIGURATION ===
input_file = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/2. RStudio_Python Inputs/Summary IFRS 17 Results MLC 202505.xlsx"
results_sheet = "Results"  # For MLC use 'Results'; for Warranties use 'Policy Results'
data_sheet = "Data"
product_type = "MLC"  # Change to "Warranties" or "MLC" if needed
output_file = "C:/Users/edwardl/OneDrive - Motus Corporation/Documents/3. RStudio_Python Outputs/Reasonability_Validation.xlsx"

# === LOAD DATA ===
header_row_results = 0
header_row_data = 0

xls = pd.ExcelFile(input_file)
df_results = xls.parse(results_sheet, header=header_row_results)
df_data = xls.parse(data_sheet, header=header_row_data)

# Strip whitespace from column names to avoid hidden issues
df_data.columns = df_data.columns.str.strip()
df_results.columns = df_results.columns.str.strip()

# Display column names if PolicyNumber not found
print("DATA COLUMNS:", df_data.columns.tolist())
print("RESULTS COLUMNS:", df_results.columns.tolist())

# Handle policy number naming
if product_type == "MLC":
    if "Policy Number" in df_data.columns:
        df_data.rename(columns={"Policy Number": "PolicyNumber"}, inplace=True)
    if "PolicyNumber" not in df_results.columns:
        raise KeyError("PolicyNumber not found in 'Results' sheet for MLC.")
else:
    if "Policy Key" in df_data.columns:
        df_data.rename(columns={"Policy Key": "PolicyNumber"}, inplace=True)
    if "Pol_PolicyNumber" in df_results.columns:
        df_results.rename(columns={"Pol_PolicyNumber": "PolicyNumber"}, inplace=True)

# === MERGE ===
df_merged = pd.merge(df_results, df_data, on="PolicyNumber", how="left")

# === SET METRIC COLUMNS ===
if product_type == "MLC":
    numeric_cols = ["Premium", "EPVFCI_AtIR", "EPVFCO_AtIR", "BEL_AtIR", 
                    "RA_AtIR", "FCF_AtIR", "CSM", "LossComponent"]
    group_col = "Cell_x"
else:
    numeric_cols = ["Premium", "AtIR_EPVFCI", "AtIR_EPVFCO", "AtIR_BEL", 
                    "AtIR_RA", "AtIR_FCF", "AtIR_CSM", "AtIR_LossComponent"]
    group_col = "CellCaptive"

# Convert columns to numeric
for col in numeric_cols:
    df_merged[col] = pd.to_numeric(df_merged[col], errors="coerce")

# === GROUP SUMMARY ===
summary = df_merged.groupby(group_col)[numeric_cols].sum().round(2)
summary["Policy Count"] = df_merged.groupby(group_col)["PolicyNumber"].count()

# === COMMENTARY GENERATION ===
def generate_comment(row):
    comments = []
    if row.get("LossComponent", 0) > 0 or row.get("AtIR_LossComponent", 0) > 0:
        comments.append("⚠️ Loss Component present - review onerous contract drivers.")
    if row.get("BEL_AtIR", row.get("AtIR_BEL", 0)) > 0:
        comments.append("❗ Positive BEL - unexpected for liability.")
    if abs(row.get("RA_AtIR", row.get("AtIR_RA", 0))) > 1.5 * abs(row.get("BEL_AtIR", row.get("AtIR_BEL", 0))):
        comments.append("📌 RA unusually high vs BEL.")
    if row.get("CSM", row.get("AtIR_CSM", 0)) == 0 and row.get("LossComponent", row.get("AtIR_LossComponent", 0)) == 0:
        comments.append("ℹ️ No CSM or Loss Component - possibly short-term group or closed.")
    if len(comments) == 0:
        return "✅ No anomalies detected."
    return " | ".join(comments)

summary["Commentary"] = summary.apply(generate_comment, axis=1)

# === OUTPUT ===
with pd.ExcelWriter(output_file, engine="xlsxwriter") as writer:
    df_merged.to_excel(writer, sheet_name="Merged Raw Data", index=False)
    summary.to_excel(writer, sheet_name="Reasonability Summary")

print(f"✅ Reasonability analysis complete. Output saved to: {output_file}")
