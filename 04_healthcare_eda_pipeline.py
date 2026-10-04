"""
===============================================================================
PROJECT: MaxCare Healthcare 360° Operational & Payout Intelligence Suite
PHASE 4: PYTHON EXPLORATORY DATA ANALYSIS (EDA) & SEABORN VISUAL PIPELINE
AUTHOR: Khyati Rajput (B.Tech CSE Final Year)
===============================================================================
"""

import os
import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Ensure UTF-8 printing in Windows console
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8')

# Set Seaborn visual style
sns.set_theme(style="whitegrid", palette="muted")
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.size'] = 10

# Define File Paths
PROJECT_DIR = r"C:\Users\rajpu\OneDrive\Desktop\Discuss\Healthcare_Analytics_Project"
DATA_FILE = os.path.join(PROJECT_DIR, "MaxCare_Hospital_1000_Patients.csv")

print("=" * 70)
print("MAXCARE HEALTHCARE 360 - PYTHON EDA & STATISTICAL PIPELINE")
print("=" * 70)

# Step 1: Data Ingestion & Audit
df = pd.read_csv(DATA_FILE)

# Ensure Date Columns are Datetime
df['Admission_Date'] = pd.to_datetime(df['Admission_Date'])
df['Discharge_Date'] = pd.to_datetime(df['Discharge_Date'])
df['Length_Of_Stay_Days'] = (df['Discharge_Date'] - df['Admission_Date']).dt.days

print(f"\n[+] Dataset Successfully Loaded: {len(df)} Patient Records")
print("-" * 50)
print(df.info())
print("\n[+] Statistical Summary of Financial Metrics:")
print(df[['Treatment_Cost', 'Insurance_Covered', 'Out_Of_Pocket', 'Length_Of_Stay_Days']].describe().round(2))

# Step 2: Key Executive Business Insights
total_rev = df['Treatment_Cost'].sum()
total_ins = df['Insurance_Covered'].sum()
total_oop = df['Out_Of_Pocket'].sum()
ins_pct = (total_ins / total_rev) * 100
avg_stay = df['Length_Of_Stay_Days'].mean()

print("\n[+] KEY BUSINESS METRICS:")
print(f"  • Total Treatment Revenue: INR {total_rev:,.2f}")
print(f"  • Total Insurance Cover:   INR {total_ins:,.2f} ({ins_pct:.1f}%)")
print(f"  • Total Out-of-Pocket:     INR {total_oop:,.2f} ({100-ins_pct:.1f}%)")
print(f"  • Avg Length of Stay:      {avg_stay:.1f} Days")

# =============================================================================
# VISUALIZATION 1: CORRELATION HEATMAP (Financial & Operational Metrics)
# =============================================================================
plt.figure(figsize=(8, 6))
numeric_cols = ['Age', 'Doctor_Experience_Years', 'Length_Of_Stay_Days', 'Treatment_Cost', 'Insurance_Covered', 'Out_Of_Pocket']
corr_matrix = df[numeric_cols].corr()

sns.heatmap(corr_matrix, annot=True, fmt=".2f", cmap="YlGnBu", linewidths=0.5, cbar=True)
plt.title("MaxCare 360 - Correlation Heatmap (Financial & Clinical Variables)", fontsize=12, fontweight='bold', pad=15)
plt.tight_layout()

chart1_path = os.path.join(PROJECT_DIR, "python_eda_heatmap_correlation.png")
plt.savefig(chart1_path, dpi=300)
plt.close()
print(f"\n[+] Chart 1 Saved: {chart1_path}")

# =============================================================================
# VISUALIZATION 2: DEPARTMENT-WISE TREATMENT COST DISTRIBUTION (BOXPLOT)
# =============================================================================
plt.figure(figsize=(9, 5))
sns.boxplot(data=df, x="Department", y="Treatment_Cost", palette="Blues_r", hue="Department", legend=False)
plt.title("MaxCare 360 - Treatment Cost Spread Across Departments", fontsize=12, fontweight='bold', pad=15)
plt.xlabel("Hospital Department", fontweight='bold')
plt.ylabel("Treatment Cost (INR)", fontweight='bold')
plt.tight_layout()

chart2_path = os.path.join(PROJECT_DIR, "python_eda_boxplot_department.png")
plt.savefig(chart2_path, dpi=300)
plt.close()
print(f"[+] Chart 2 Saved: {chart2_path}")

# =============================================================================
# VISUALIZATION 3: PATIENT LENGTH OF STAY DISTRIBUTION (KDE + HISTOGRAM)
# =============================================================================
plt.figure(figsize=(9, 5))
sns.histplot(df['Length_Of_Stay_Days'], kde=True, color="#06B6D4", bins=14)
plt.axvline(avg_stay, color='red', linestyle='--', linewidth=2, label=f'Avg Stay ({avg_stay:.1f} Days)')
plt.title("MaxCare 360 - Patient Length of Stay Distribution (Days)", fontsize=12, fontweight='bold', pad=15)
plt.xlabel("Length of Stay (Days)", fontweight='bold')
plt.ylabel("Number of Patients", fontweight='bold')
plt.legend()
plt.tight_layout()

chart3_path = os.path.join(PROJECT_DIR, "python_eda_stay_distribution.png")
plt.savefig(chart3_path, dpi=300)
plt.close()
print(f"[+] Chart 3 Saved: {chart3_path}")

print("\n" + "=" * 70)
print("PYTHON EDA PIPELINE COMPLETED SUCCESSFULLY!")
print("=" * 70)
