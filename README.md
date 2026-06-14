# 🏥 CKD Patient Outcomes & Healthcare Access Analysis

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow?logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Records](https://img.shields.io/badge/Records-100%2C000-green)
![Countries](https://img.shields.io/badge/Countries-5-teal)

---

## 📌 Project Overview

Chronic Kidney Disease (CKD) affects over **850 million people globally**, yet patient outcomes vary dramatically based on geography, income, insurance status, and quality of healthcare access.

This end-to-end data analytics project analyses **100,000 synthetic CKD patient records** across **Nigeria, India, Brazil, USA, and Kenya** to answer one central question:

> **What drives recovery versus death in CKD patients — and what systemic barriers prevent better outcomes?**

Built as a professional portfolio piece demonstrating real-world skills across data cleaning, exploratory data analysis, business intelligence, and data storytelling.

---

## 🗂️ Repository Structure

```
ckd-patient-outcomes-analysis/
│
├── README.md
│
├── sql/
│   ├── CKD_Phase1_Data_Cleaning.sql   ← Full data cleaning script
│   └── CKD_Phase2_EDA.sql             ← 40+ EDA queries across 5 BQs
│
├── dashboard/
│   └── CKD_Analysis_Dashboard.pbix    ← Power BI dashboard (6 pages)
│
├── presentation/
│   └── CKD_Analysis_Presentation.pptx ← 11-slide executive presentation
│
└── assets/
    ├── dashboard_preview_p1.png        ← Executive Overview
    ├── dashboard_preview_p2.png        ← Clinical Factors
    ├── dashboard_preview_p3.png        ← Healthcare Equity
    ├── dashboard_preview_p4.png        ← Diagnosis Delay
    ├── dashboard_preview_p5.png        ← Treatment Adherence
    └── dashboard_preview_p6.png        ← Disease Stage
```

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| **MySQL 8.0** | Data cleaning, feature engineering, EDA (40+ queries) |
| **Power BI Desktop** | 6-page interactive dashboard, 12 DAX measures |
| **MySQL ODBC Connector** | Live connection between MySQL and Power BI |
| **PowerPoint** | Executive presentation of findings |
| **GitHub** | Version control and project hosting |

---

## 📊 Dataset

| Attribute | Detail |
|---|---|
| Source | Synthetic CKD patient dataset |
| Records | 100,000 patients |
| Columns | 38 original + 8 engineered features |
| Countries | Nigeria, India, Brazil, USA, Kenya |
| Period | 2019 – 2025 |
| Key Variables | Demographics, disease stage, treatment type, insurance status, income, facility tier, outcomes, quality of life |

> ⚠️ This dataset is entirely synthetic and was generated for portfolio and educational purposes only. No real patient data was used at any stage of this project.

---

## 🔍 The 5 Business Questions

| # | Business Question |
|---|---|
| **BQ1** | What patient and clinical factors drive recovery vs. death? |
| **BQ2** | Does insurance status and income affect patient outcomes? |
| **BQ3** | Which countries and facility tiers have the worst diagnosis delays? |
| **BQ4** | Does treatment adherence improve quality of life and outcomes? |
| **BQ5** | How does disease stage at diagnosis relate to mortality and complications? |

---

## ⚙️ Phase 1 — Data Cleaning (MySQL)

**File:** `sql/CKD_Phase1_Data_Cleaning.sql`

| Issue | Columns Affected | Strategy |
|---|---|---|
| Missing ~5% | BMI, smoking status, income | Median/mode imputation grouped by country or sex |
| Missing ~12% | Education level | Mode imputation by country |
| Missing ~48% | Alcohol use | Labelled `Unknown` — too high to impute reliably |
| Missing ~42% | Comorbidities | Labelled `None` — clinically meaningful |
| Missing ~67% | Complication type | Labelled `None` — aligns with no complication recorded |
| Negative values (9 rows) | avg_wait_time_hours | Replaced with `ABS()` — data entry error |
| Inconsistent casing/spacing | All string columns | Trimmed and standardised |

**8 engineered features added:**
`age_group` · `bmi_category` · `income_bracket` · `diagnosis_delay_category` · `adherence_category` · `outcome_severity` · `has_comorbidity` · `calculated_diagnosis_gap`

**Result:** 100,000 rows · 46 columns · **100% column quality confirmed in Power Query** ✅

---

## 🔍 Phase 2 — Exploratory Data Analysis (MySQL)

**File:** `sql/CKD_Phase2_EDA.sql`

40+ queries across 9 sections answering all 5 business questions.

**Key SQL techniques used:**
- Window functions — `ROW_NUMBER`, `RANK`, `COUNT OVER PARTITION BY`
- Conditional aggregation — `SUM(CASE WHEN ... END)`
- Median approximation using ranked subqueries
- Date functions — `DATEDIFF`, `YEAR()`
- `CREATE OR REPLACE VIEW` for Power BI integration

**6 Power BI export views created:**
```sql
vw_demographics       -- Patient demographics
vw_clinical_profile   -- Disease and diagnosis data  
vw_treatment          -- Treatment and adherence data
vw_outcomes           -- Patient outcomes
vw_facility           -- Healthcare facility metrics
vw_powerbi_master     -- Full master view (primary dashboard source)
```

---

## 📈 Phase 3 — Power BI Dashboard

**File:** `dashboard/CKD_Analysis_Dashboard.pbix`

**Theme:** Green & White Healthcare | **Connection:** MySQL ODBC | **Pages:** 6

| Page | Title | Key Visuals |
|---|---|---|
| 1 | Executive Overview | KPI cards, outcome donut, country bar, trends line chart |
| 2 | Clinical Factors & Outcomes | Comorbidity stacked bar, treatment effectiveness, smoking vs mortality |
| 3 | Healthcare Equity | Insurance by country, drug availability, mortality heatmap |
| 4 | Diagnosis Delay & Access | Facility scorecard, country delay bar, urban/rural access gap |
| 5 | Treatment Adherence | Adherence vs outcomes, adherence by country, QoL scatter |
| 6 | Disease Stage & Detection | Outcome by stage, early detection by country, diagnostic method |

**12 DAX Measures:**
`Total Patients` · `Recovery Rate %` · `Mortality Rate %` · `Deterioration Rate %` · `Avg QoL Score` · `Avg Diagnosis Delay` · `Avg Adherence %` · `Avg Wait Time (hrs)` · `Complication Rate %` · `Readmission Rate %` · `Uninsured Mortality Rate %` · `Early Detection %`

### Dashboard Previews

| Executive Overview | Healthcare Equity |
|---|---|
| ![P1](assets/dashboard_preview_p1.png) | ![P3](assets/dashboard_preview_p3.png) |

| Diagnosis Delay | Treatment Adherence |
|---|---|
| ![P4](assets/dashboard_preview_p4.png) | ![P5](assets/dashboard_preview_p5.png) |

---

## 💡 Key Findings

### BQ1 — Clinical Factors
- HIV comorbidity + severe-stage diagnosis = **highest mortality risk** across all patient groups
- Therapy-based treatment leads all treatment types with a **47% recovery rate**
- Current smokers face **~14% higher mortality** than non-smokers
- BMI category shows minimal QoL variation — **disease stage at diagnosis matters far more**

### BQ2 — Healthcare Equity
- Uninsured patients consistently receive **lower drug availability** across all 5 countries
- A counterintuitive finding: **Insured high-income patients show 5.42% mortality** — the highest rate in the heatmap — suggesting complex systemic factors beyond just coverage
- **Brazil has the highest insured proportion (48%)**, Nigeria and Kenya the lowest (~31%)

### BQ3 — Diagnosis Delays
- **USA has the worst average diagnosis delay at 35 days** — nearly 2× Nigeria, Brazil and Kenya (all ~18 days)
- **Primary facilities delay diagnosis 2× longer** than tertiary (34.65 vs 17.60 days)
- Severely delayed diagnosis strongly predicts **late-stage detection and higher mortality**
- Rural patients face consistently longer delays and lower specialist availability

### BQ4 — Treatment Adherence
- Higher adherence directly and clearly correlates with **better quality of life scores**
- **Brazil leads average adherence at 70.1%**, Nigeria trails at 68.5%
- **Drug unavailability is the #1 systemic adherence barrier** — exceeding side effects and patient factors
- High-adherence patients show the lowest hospital readmission and complication rates

### BQ5 — Disease Stage & Early Detection
- **USA records the lowest early detection rate at 21.4%** — worst of all 5 countries
- Kenya, India and Nigeria achieve **~34–35% early detection rates**
- **Lab Tests are the most effective diagnostic method** for early-stage detection
- Primary facilities catch only **24.5% of cases early** vs 35%+ at secondary and tertiary

---

## 📋 Recommendations

| # | Recommendation | Supporting Evidence |
|---|---|---|
| 1 | **Expand insurance coverage** in Nigeria, India and Kenya | 33–35% uninsured with demonstrably lower drug access |
| 2 | **Invest in primary facility capacity** — equipment and specialists | Primary: 34.65-day delay, 7.48-hr wait, 5.27% mortality |
| 3 | **Strengthen drug supply chains** for uninsured patients | Drug unavailability = #1 adherence barrier across all countries |
| 4 | **Launch CKD early screening programmes in the USA** | 21.4% early detection rate — lowest of all 5 countries |
| 5 | **Implement fast-track diagnostic referrals** for high-risk patients | USA: 35-day avg delay · India: 28-day avg delay |
| 6 | **Develop integrated care protocols** for HIV + Hypertension patients | Highest combined mortality risk group in the dataset |

---

## 🚀 How to Run This Project

### Prerequisites
- MySQL 8.0+
- MySQL ODBC Connector 8.0
- Power BI Desktop (latest version)

### Steps

**1. Clone this repository**
```bash
git clone https://github.com/[your-username]/ckd-patient-outcomes-analysis.git
cd ckd-patient-outcomes-analysis
```

**2. Run the SQL scripts in MySQL Workbench**
```sql
-- Step 1: Open sql/CKD_Phase1_Data_Cleaning.sql
-- Update the file path in LOAD DATA INFILE to your local CSV location
-- Run the full script — this creates the ckd_analysis database and ckd_clean table

-- Step 2: Open sql/CKD_Phase2_EDA.sql
-- Run the full script — this generates all EDA results and Power BI views
```

**3. Connect Power BI to MySQL**
- Open `dashboard/CKD_Analysis_Dashboard.pbix`
- Go to **Transform Data → Data Source Settings**
- Update the server to `localhost` and database to `ckd_analysis`
- Enter your MySQL credentials and click **OK**

**4. Refresh the dashboard**
- Click **Refresh** in Power BI Desktop
- All 6 pages will populate from your local MySQL database

---

## 👤 Author

**[Your Full Name]**
Microsoft Certified Data Analyst

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?logo=linkedin)](https://linkedin.com/in/your-profile)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?logo=github)](https://github.com/your-username)

---

*If you found this project useful, feel free to ⭐ star the repository!*
