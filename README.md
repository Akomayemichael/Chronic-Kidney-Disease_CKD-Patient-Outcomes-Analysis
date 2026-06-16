# CKD Patient Outcomes & Healthcare Access Analysis

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow?logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![Records](https://img.shields.io/badge/Records-100%2C000-green)
![Countries](https://img.shields.io/badge/Countries-5-teal)

---

## Overview

![Data Overview](assets/Data_Overview.png)

Chronic Kidney Disease (CKD) is a long-term condition that can lead to kidney failure if not detected and managed early, making timely diagnosis and treatment adherence important factors in patient outcomes. This project analyses 100,000 synthetic Chronic Kidney Disease (CKD) patient records from healthcare facilities across Nigeria, India, Brazil, Kenya, and the United States.

The objective was to identify factors associated with patient outcomes, treatment adherence, diagnosis delays, and healthcare access using MySQL and Power BI.

> The dataset is synthetic and was used strictly for portfolio purposes. No real patient data was involved.

---

## Dataset Overview

| Attribute | Detail |
|---|---|
| Records | 100,000 patients |
| Countries | Nigeria, India, Brazil, Kenya, USA |
| Period | 2019 – 2025 |
| Columns | 46 total (38 original + 8 engineered) |
| Key Variables | Disease stage, treatment type, insurance status, income, facility tier, drug availability, treatment adherence, patient outcomes |

---

## Business Questions

1. What patient and clinical factors drive recovery vs. death?
2. Does insurance status and income affect patient outcomes?
3. Which countries and facility tiers have the worst diagnosis delays?
4. Does treatment adherence improve quality of life and outcomes?
5. How does disease stage at diagnosis relate to mortality and complications?

---

## Tools Used

| Tool | Purpose |
|---|---|
| MySQL 8.0 | Data cleaning, feature engineering, exploratory analysis |
| Power BI Desktop | Interactive dashboard and reporting |
| MySQL ODBC Connector | Live connection between MySQL and Power BI |
| GitHub | Version control and project documentation |

> AI tools (Claude, ChatGPT) were used to assist with dataset generation and code review.

---

## Data Preparation

The dataset contained missing values, inconsistent text fields, and a small number of invalid records.

Data cleaning included:
- Handling missing values across 8 columns using imputation and appropriate labelling
- Standardising categorical fields and correcting negative wait time values
- Engineering 8 new analytical features including age group, income bracket, adherence category and outcome severity
- Validating diagnosis dates against calculated date differences
- Creating 6 Power BI reporting views

Full cleaning process: [sql/CKD_Phase1_Data_Cleaning1.sql](sql/CKD_Phase1_Data_Cleaning1.sql)

---

## Analysis

Performed in MySQL across 40+ queries covering all 5 business questions.

Techniques used:
- Aggregations and conditional aggregations
- Window functions
- CASE statements
- Subqueries and joins
- Views for Power BI integration

Full analysis: [sql/CKD_Phase2_Exploratory_Data_Analysis.sql](sql/CKD_Phase2_Exploratory_Data_Analysis.sql)

---

## Dashboard

The Power BI dashboard contains six report pages:

- Executive Overview
- Clinical Factors & Outcomes
- Healthcare Equity, Insurance & Income
- Diagnosis Delay & Healthcare Access
- Treatment Adherence & Outcomes
- Disease Stage & Early Detection

Each page includes interactive slicers for Country, Sex, and Stage at Diagnosis.

### Previews

| Executive Overview | Healthcare Equity |
|---|---|
| ![Data Overview](assets/Data_Overview.png) | ![Equity Analysis](assets/Equity_Analysis.png) |

| Clinical Factors | Disease Stage |
|---|---|
| ![Clinical Analysis](assets/Clinical_Analysis.png) | ![Detection Analysis](assets/Detection_Analysis.png) |

| Diagnosis Delay | Treatment Adherence |
|---|---|
| ![Patient Access Analysis](assets/Patient_Access_Analysis.png) | ![Adherence Analysis](assets/Adherence_Analysis.png) |

---

## Key Findings

- Severe-stage diagnosis carried the highest mortality rate at 6%+, compared to ~2.4% for early-stage
- Therapy had the highest recovery rate at 45.65%; surgery the lowest at 43.54%
- Current smokers recorded higher mortality (4.04%) than non-smokers (3.74%)
- Primary facilities averaged 34.65 days to diagnosis and 5.27% mortality vs 17.60 days and 3.84% at tertiary
- USA had the longest average diagnosis delay at 35 days and the lowest early detection rate at 21.64%
- Kenya, India, Nigeria and Brazil all achieved early detection rates above 34%
- Higher treatment adherence was consistently associated with better quality of life scores
- Uninsured patients had lower drug availability across all five countries
- Severe-stage patients recorded significantly more complications across all four complication types

---

## Recommendations

- Invest in primary facility capacity to reduce diagnosis delays and improve early detection
- Improve medication availability for uninsured patients across all countries
- Launch targeted CKD screening programmes, particularly in rural areas and the USA
- Prioritise early detection — complication rates drop significantly with earlier diagnosis

---

## How to Run

Requirements: MySQL 8.0+, MySQL ODBC Connector, Power BI Desktop

```bash
git clone https://github.com/Akomayemichael/ckd-patient-outcomes-analysis.git
```
1. Run sql/CKD_Phase1_Data_Cleaning1.sql in MySQL Workbench — update the LOAD DATA INFILE path to your local CSV location
2. Run sql/CKD_Phase2_Exploratory_Data_Analysis.sql
3. Open dashboard/CKD_Analysis_Dashboard.pbix in Power BI Desktop
4. Go to Transform Data → Data Source Settings, update the connection to localhost / ckd_analysis, then click Refresh
---

## Author

**Adie Michael Akomaye**

Data Analyst | Business Intelligence Analyst

- LinkedIn: [Michael Akomaye] https://www.linkedin.com/in/michael-akomaye-4381082ba/
- Email: michaelwilliams4232016@gmail.com
---
*If you found this project useful, feel free to ⭐ star the repository!*
