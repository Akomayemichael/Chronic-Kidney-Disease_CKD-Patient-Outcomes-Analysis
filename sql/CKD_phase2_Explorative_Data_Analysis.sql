-- ============================================================
--  CKD PATIENT OUTCOMES & HEALTHCARE ACCESS ANALYSIS
--  Phase 2: Exploratory Data Analysis (EDA)
--  Tool: MySQL 8.0+
--  Author: Adie Michael Williams
--  Date: June 2026
--  Database: ckd_analysis | Table: ckd_clean
-- ============================================================

USE ckd_analysis;

-- ============================================================
-- SECTION 1: DATASET OVERVIEW
-- ============================================================

-- 1A: Total patients and countries
SELECT
    COUNT(*)                        AS total_patients,
    COUNT(DISTINCT country)         AS total_countries,
    COUNT(DISTINCT city)            AS total_cities,
    COUNT(DISTINCT facility_name)   AS total_facilities,
    MIN(diagnosis_date)             AS earliest_diagnosis,
    MAX(diagnosis_date)             AS latest_diagnosis
FROM ckd_clean;

-- 1B: Patient distribution by country
SELECT
    country,
    COUNT(*)                                    AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM ckd_clean
GROUP BY country
ORDER BY total_patients DESC;

-- 1C: Distribution of primary outcomes (the target variable)
SELECT
    primary_outcome,
    COUNT(*)                                            AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)  AS pct_of_total
FROM ckd_clean
GROUP BY primary_outcome
ORDER BY total_patients DESC;

-- 1D: Disease stage distribution
SELECT
    disease_stage_at_diagnosis,
    COUNT(*)                                            AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)  AS pct_of_total
FROM ckd_clean
GROUP BY disease_stage_at_diagnosis
ORDER BY total_patients DESC;

-- 1E: Summary statistics for key numeric columns
SELECT
    ROUND(AVG(age), 1)                      AS avg_age,
    ROUND(AVG(bmi), 1)                      AS avg_bmi,
    ROUND(AVG(monthly_income_usd), 2)       AS avg_income_usd,
    ROUND(AVG(time_to_diagnosis_days), 1)   AS avg_days_to_diagnosis,
    ROUND(AVG(treatment_duration_weeks), 1) AS avg_treatment_weeks,
    ROUND(AVG(treatment_adherence_pct), 1)  AS avg_adherence_pct,
    ROUND(AVG(quality_of_life_score), 2)    AS avg_quality_of_life,
    ROUND(AVG(avg_wait_time_hours), 1)      AS avg_wait_hours,
    ROUND(AVG(equipment_quality_score), 2)  AS avg_equipment_score
FROM ckd_clean;

-- ============================================================
-- SECTION 2: DEMOGRAPHIC ANALYSIS
-- ============================================================

-- 2A: Outcome breakdown by sex
SELECT
    sex,
    primary_outcome,
    COUNT(*)                                                        AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sex), 1) AS pct_within_sex
FROM ckd_clean
GROUP BY sex, primary_outcome
ORDER BY sex, total_patients DESC;

-- 2B: Outcome breakdown by age group
SELECT
    age_group,
    primary_outcome,
    COUNT(*)                                                              AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY age_group), 1) AS pct_within_age_group
FROM ckd_clean
GROUP BY age_group, primary_outcome
ORDER BY age_group, total_patients DESC;

-- 2C: Mortality rate by age group (focused view)
SELECT
    age_group,
    COUNT(*)                                            AS total_patients,
    SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END) AS deceased_count,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                       AS mortality_rate_pct
FROM ckd_clean
GROUP BY age_group
ORDER BY age_group;

-- 2D: BMI category vs outcome
SELECT
    bmi_category,
    primary_outcome,
    COUNT(*)                                                                AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY bmi_category), 1) AS pct_within_bmi_group
FROM ckd_clean
GROUP BY bmi_category, primary_outcome
ORDER BY bmi_category, total_patients DESC;

-- 2E: Average quality of life score by age group and sex
SELECT
    age_group,
    sex,
    ROUND(AVG(quality_of_life_score), 2) AS avg_quality_of_life,
    COUNT(*)                             AS total_patients
FROM ckd_clean
GROUP BY age_group, sex
ORDER BY age_group, sex;


-- ============================================================
-- SECTION 3: BUSINESS QUESTION 1
-- What patient and clinical factors drive recovery vs. death?
-- ============================================================

-- 3A: Recovery and mortality rates by disease stage
SELECT
    disease_stage_at_diagnosis,
    COUNT(*)                                                                        AS total_patients,
    SUM(CASE WHEN primary_outcome = 'Recovered'  THEN 1 ELSE 0 END)                AS recovered,
    SUM(CASE WHEN primary_outcome = 'Deceased'   THEN 1 ELSE 0 END)                AS deceased,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct
FROM ckd_clean
GROUP BY disease_stage_at_diagnosis
ORDER BY mortality_rate_pct DESC;

-- 3B: Impact of comorbidities on outcomes
SELECT
    comorbidities,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score
FROM ckd_clean
GROUP BY comorbidities
ORDER BY mortality_rate_pct DESC;

-- 3C: Has comorbidity — summary mortality comparison
SELECT
    CASE WHEN has_comorbidity = 1 THEN 'Has Comorbidity'
         ELSE 'No Comorbidity' END                                                 AS comorbidity_status,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct
FROM ckd_clean
GROUP BY has_comorbidity;

-- 3D: Treatment type effectiveness
SELECT
    treatment_type,
    COUNT(*)                                                                        AS total_patients,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(SUM(CASE WHEN hospital_readmission = 'Yes'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS readmission_rate_pct
FROM ckd_clean
GROUP BY treatment_type
ORDER BY recovery_rate_pct DESC;

-- 3E: Smoking status impact on outcomes
SELECT
    smoking_status,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score
FROM ckd_clean
GROUP BY smoking_status
ORDER BY mortality_rate_pct DESC;

-- 3F: Complication development vs outcome
SELECT
    complication_developed,
    complication_type,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score
FROM ckd_clean
GROUP BY complication_developed, complication_type
ORDER BY complication_developed DESC, mortality_rate_pct DESC;


-- ============================================================
-- SECTION 4: BUSINESS QUESTION 2
-- Does insurance status and income affect patient outcomes?
-- ============================================================

-- 4A: Outcomes by insurance status
SELECT
    insurance_status,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deteriorated' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS deterioration_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(AVG(avg_wait_time_hours), 1)                                             AS avg_wait_hours
FROM ckd_clean
GROUP BY insurance_status
ORDER BY mortality_rate_pct DESC;

-- 4B: Insurance status breakdown by country
SELECT
    country,
    insurance_status,
    COUNT(*)                                                                        AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY country), 1)        AS pct_within_country
FROM ckd_clean
GROUP BY country, insurance_status
ORDER BY country, total_patients DESC;

-- 4C: Income bracket vs outcomes
SELECT
    income_bracket,
    COUNT(*)                                                                        AS total_patients,
    ROUND(AVG(monthly_income_usd), 2)                                              AS avg_income_usd,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score
FROM ckd_clean
GROUP BY income_bracket
ORDER BY avg_income_usd ASC;

-- 4D: Insurance + income combined effect on mortality
SELECT
    insurance_status,
    income_bracket,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score
FROM ckd_clean
GROUP BY insurance_status, income_bracket
ORDER BY mortality_rate_pct DESC;

-- 4E: Drug availability impact by insurance status
SELECT
    insurance_status,
    drug_availability,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct
FROM ckd_clean
GROUP BY insurance_status, drug_availability
ORDER BY insurance_status, mortality_rate_pct DESC;


-- ============================================================
-- SECTION 5: BUSINESS QUESTION 3
-- Which countries and facility tiers have the worst diagnosis delays?
-- ============================================================

-- 5A: Average diagnosis delay by country
SELECT
    country,
    COUNT(*)                                            AS total_patients,
    ROUND(AVG(time_to_diagnosis_days), 1)               AS avg_days_to_diagnosis,
    MIN(time_to_diagnosis_days)                         AS min_days,
    MAX(time_to_diagnosis_days)                         AS max_days,
    ROUND(AVG(avg_wait_time_hours), 1)                  AS avg_wait_hours
FROM ckd_clean
GROUP BY country
ORDER BY avg_days_to_diagnosis DESC;

-- 5B: Diagnosis delay category distribution by country
SELECT
    country,
    diagnosis_delay_category,
    COUNT(*)                                                                        AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY country), 1)        AS pct_within_country
FROM ckd_clean
GROUP BY country, diagnosis_delay_category
ORDER BY country, total_patients DESC;

-- 5C: Facility tier vs diagnosis delay and outcomes
SELECT
    facility_tier,
    COUNT(*)                                            AS total_patients,
    ROUND(AVG(time_to_diagnosis_days), 1)               AS avg_days_to_diagnosis,
    ROUND(AVG(avg_wait_time_hours), 1)                  AS avg_wait_hours,
    ROUND(AVG(equipment_quality_score), 2)              AS avg_equipment_score,
    ROUND(SUM(CASE WHEN specialist_available = 'Yes' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                        AS specialist_availability_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                        AS mortality_rate_pct
FROM ckd_clean
GROUP BY facility_tier
ORDER BY avg_days_to_diagnosis DESC;

-- 5D: Location type (Urban/Rural/Semi-Urban) vs healthcare access
SELECT
    location_type,
    COUNT(*)                                            AS total_patients,
    ROUND(AVG(time_to_diagnosis_days), 1)               AS avg_days_to_diagnosis,
    ROUND(AVG(avg_wait_time_hours), 1)                  AS avg_wait_hours,
    ROUND(AVG(equipment_quality_score), 2)              AS avg_equipment_score,
    ROUND(SUM(CASE WHEN specialist_available = 'Yes' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                        AS specialist_availability_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                        AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                AS avg_qol_score
FROM ckd_clean
GROUP BY location_type
ORDER BY avg_days_to_diagnosis DESC;

-- 5E: Impact of delayed diagnosis on outcomes
SELECT
    diagnosis_delay_category,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(SUM(CASE WHEN disease_stage_at_diagnosis = 'Severe' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS pct_severe_at_diagnosis
FROM ckd_clean
GROUP BY diagnosis_delay_category
ORDER BY mortality_rate_pct DESC;

-- 5F: Cities with worst average diagnosis delay
SELECT
    country,
    city,
    COUNT(*)                                    AS total_patients,
    ROUND(AVG(time_to_diagnosis_days), 1)       AS avg_days_to_diagnosis,
    ROUND(AVG(avg_wait_time_hours), 1)          AS avg_wait_hours
FROM ckd_clean
GROUP BY country, city
HAVING COUNT(*) >= 100            -- Filter out cities with too few patients for reliability
ORDER BY avg_days_to_diagnosis DESC;


-- ============================================================
-- SECTION 6: BUSINESS QUESTION 4
-- Does treatment adherence improve quality of life and outcomes?
-- ============================================================

-- 6A: Adherence category vs outcomes
SELECT
    adherence_category,
    COUNT(*)                                                                        AS total_patients,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(AVG(treatment_duration_weeks), 1)                                        AS avg_treatment_weeks,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(SUM(CASE WHEN hospital_readmission = 'Yes'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS readmission_rate_pct,
    ROUND(SUM(CASE WHEN complication_developed = 'Yes' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS complication_rate_pct
FROM ckd_clean
GROUP BY adherence_category
ORDER BY avg_qol_score DESC;

-- 6B: Factors that influence treatment adherence
SELECT
    insurance_status,
    drug_availability,
    ROUND(AVG(treatment_adherence_pct), 1)      AS avg_adherence_pct,
    COUNT(*)                                    AS total_patients
FROM ckd_clean
GROUP BY insurance_status, drug_availability
ORDER BY avg_adherence_pct DESC;

-- 6C: Adherence vs side effects
SELECT
    side_effects_reported,
    ROUND(AVG(treatment_adherence_pct), 1)      AS avg_adherence_pct,
    COUNT(*)                                    AS total_patients,
    ROUND(AVG(quality_of_life_score), 2)        AS avg_qol_score
FROM ckd_clean
GROUP BY side_effects_reported
ORDER BY avg_adherence_pct DESC;

-- 6D: Drug availability impact on adherence and outcomes
SELECT
    drug_availability,
    COUNT(*)                                                                        AS total_patients,
    ROUND(AVG(treatment_adherence_pct), 1)                                         AS avg_adherence_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct
FROM ckd_clean
GROUP BY drug_availability
ORDER BY avg_adherence_pct DESC;

-- 6E: Adherence by country (identifies systemic barriers)
SELECT
    country,
    ROUND(AVG(treatment_adherence_pct), 1)      AS avg_adherence_pct,
    ROUND(AVG(quality_of_life_score), 2)        AS avg_qol_score,
    ROUND(SUM(CASE WHEN drug_availability = 'Always' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                AS pct_always_drug_available
FROM ckd_clean
GROUP BY country
ORDER BY avg_adherence_pct DESC;


-- ============================================================
-- SECTION 7: BUSINESS QUESTION 5
-- How does disease stage at diagnosis relate to mortality
-- and complications?
-- ============================================================

-- 7A: Full outcome profile by disease stage
SELECT
    disease_stage_at_diagnosis,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered'         THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Ongoing Treatment' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS ongoing_treatment_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deteriorated'      THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS deterioration_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'          THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(SUM(CASE WHEN complication_developed = 'Yes'        THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS complication_rate_pct,
    ROUND(SUM(CASE WHEN hospital_readmission = 'Yes'          THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS readmission_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(AVG(treatment_duration_weeks), 1)                                        AS avg_treatment_weeks
FROM ckd_clean
GROUP BY disease_stage_at_diagnosis
ORDER BY mortality_rate_pct DESC;

-- 7B: Disease stage by country (early detection rates)
SELECT
    country,
    disease_stage_at_diagnosis,
    COUNT(*)                                                                        AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY country), 1)        AS pct_within_country
FROM ckd_clean
GROUP BY country, disease_stage_at_diagnosis
ORDER BY country, total_patients DESC;

-- 7C: Stage at diagnosis vs diagnostic method
-- (Did method of detection influence how early disease was caught?)
SELECT
    diagnostic_method,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN disease_stage_at_diagnosis = 'Early'    THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS pct_early_detection,
    ROUND(SUM(CASE WHEN disease_stage_at_diagnosis = 'Moderate' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS pct_moderate_detection,
    ROUND(SUM(CASE WHEN disease_stage_at_diagnosis = 'Severe'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS pct_severe_detection,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'            THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct
FROM ckd_clean
GROUP BY diagnostic_method
ORDER BY pct_early_detection DESC;

-- 7D: Stage at diagnosis vs facility tier
-- (Do better facilities catch disease earlier?)
SELECT
    facility_tier,
    ROUND(SUM(CASE WHEN disease_stage_at_diagnosis = 'Early'    THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS pct_early_detection,
    ROUND(SUM(CASE WHEN disease_stage_at_diagnosis = 'Severe'   THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS pct_severe_detection,
    ROUND(AVG(equipment_quality_score), 2)                                         AS avg_equipment_score,
    ROUND(AVG(time_to_diagnosis_days), 1)                                          AS avg_days_to_diagnosis,
    COUNT(*)                                                                        AS total_patients
FROM ckd_clean
GROUP BY facility_tier
ORDER BY pct_early_detection DESC;


-- ============================================================
-- SECTION 8: CROSS-CUTTING INSIGHTS
-- Powerful multi-dimensional queries for deep insights
-- ============================================================

-- 8A: The Healthcare Equity Index
-- Compares mortality, QoL and wait times across insurance + location
SELECT
    insurance_status,
    location_type,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(AVG(avg_wait_time_hours), 1)                                             AS avg_wait_hours
FROM ckd_clean
GROUP BY insurance_status, location_type
ORDER BY mortality_rate_pct DESC;

-- 8B: Most at-risk patient profile
-- Patients with ALL high-risk factors — who are they?
SELECT
    country,
    age_group,
    sex,
    disease_stage_at_diagnosis,
    insurance_status,
    COUNT(*)                                                                        AS high_risk_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score
FROM ckd_clean
WHERE disease_stage_at_diagnosis = 'Severe'
  AND insurance_status           = 'Uninsured'
  AND has_comorbidity            = 1
GROUP BY country, age_group, sex, disease_stage_at_diagnosis, insurance_status
HAVING COUNT(*) >= 10
ORDER BY mortality_rate_pct DESC;

-- 8C: Country-level healthcare performance scorecard
SELECT
    country,
    COUNT(*)                                                                        AS total_patients,
    ROUND(AVG(time_to_diagnosis_days), 1)                                          AS avg_diagnosis_delay_days,
    ROUND(AVG(avg_wait_time_hours), 1)                                             AS avg_wait_hours,
    ROUND(AVG(equipment_quality_score), 2)                                         AS avg_equipment_score,
    ROUND(AVG(treatment_adherence_pct), 1)                                         AS avg_adherence_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(SUM(CASE WHEN specialist_available = 'Yes'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS specialist_availability_pct
FROM ckd_clean
GROUP BY country
ORDER BY mortality_rate_pct DESC;

-- 8D: Trend — Outcomes by diagnosis year
-- (Has patient outcome improved over time?)
SELECT
    YEAR(diagnosis_date)                                                            AS diagnosis_year,
    COUNT(*)                                                                        AS total_patients,
    ROUND(SUM(CASE WHEN primary_outcome = 'Recovered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS recovery_rate_pct,
    ROUND(SUM(CASE WHEN primary_outcome = 'Deceased'  THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 1)                                                   AS mortality_rate_pct,
    ROUND(AVG(quality_of_life_score), 2)                                           AS avg_qol_score,
    ROUND(AVG(treatment_adherence_pct), 1)                                         AS avg_adherence_pct
FROM ckd_clean
GROUP BY YEAR(diagnosis_date)
ORDER BY diagnosis_year;


-- ============================================================
-- SECTION 9: EXPORT VIEWS FOR POWER BI
-- Create clean summary views that Power BI will connect to
-- ============================================================

-- View 1: Patient demographics summary
CREATE OR REPLACE VIEW vw_demographics AS
SELECT
    patient_id, age, age_group, sex, bmi, bmi_category,
    country, city, location_type,
    education_level, employment_status,
    insurance_status, income_bracket, monthly_income_usd
FROM ckd_clean;

-- View 2: Clinical profile
CREATE OR REPLACE VIEW vw_clinical_profile AS
SELECT
    patient_id, disease_name, disease_stage_at_diagnosis,
    comorbidities, has_comorbidity, smoking_status, alcohol_use,
    diagnostic_method, diagnosis_delay_category, time_to_diagnosis_days,
    symptom_onset_date, diagnosis_date
FROM ckd_clean;

-- View 3: Treatment summary
CREATE OR REPLACE VIEW vw_treatment AS
SELECT
    patient_id, treatment_type, treatment_start_date,
    treatment_duration_weeks, treatment_adherence_pct,
    adherence_category, medication_name, drug_availability,
    side_effects_reported
FROM ckd_clean;

-- View 4: Outcomes summary
CREATE OR REPLACE VIEW vw_outcomes AS
SELECT
    patient_id, primary_outcome, outcome_severity,
    hospital_readmission, complication_developed, complication_type,
    quality_of_life_score, follow_up_date
FROM ckd_clean;

-- View 5: Healthcare facility summary
CREATE OR REPLACE VIEW vw_facility AS
SELECT
    patient_id, country, city, location_type,
    facility_name, facility_tier, specialist_available,
    avg_wait_time_hours, equipment_quality_score
FROM ckd_clean;

-- View 6: Master Power BI view (all columns — use for main report)
CREATE OR REPLACE VIEW vw_powerbi_master AS
SELECT * FROM ckd_clean;


-- ============================================================
-- END OF EDA
