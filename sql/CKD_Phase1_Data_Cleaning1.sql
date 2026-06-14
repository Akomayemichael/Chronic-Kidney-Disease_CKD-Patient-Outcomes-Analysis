-- ============================================================
--  CKD PATIENT OUTCOMES & HEALTHCARE ACCESS ANALYSIS
--  Phase 1: Database Setup & Data Cleaning
--  Tool: MySQL 8.0+
--  Author: Adie Michael Williams
--  Date: June 2026
--  Dataset: 100,000 Synthetic CKD Patient Records
--  Countries: Nigeria, India, Brazil, USA, Kenya
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS ckd_analysis;
USE ckd_analysis;

-- Drop table if re-running the script
DROP TABLE IF EXISTS ckd_raw;

-- Create the raw staging table (mirrors the CSV exactly)
CREATE TABLE ckd_raw (
    patient_id                   VARCHAR(50),
    age                          INT,
    sex                          VARCHAR(10),
    bmi                          FLOAT,
    smoking_status               VARCHAR(20),
    alcohol_use                  VARCHAR(20),
    education_level              VARCHAR(20),
    employment_status            VARCHAR(20),
    monthly_income_usd           FLOAT,
    insurance_status             VARCHAR(20),
    disease_name                 VARCHAR(50),
    disease_stage_at_diagnosis   VARCHAR(20),
    comorbidities                VARCHAR(100),
    symptom_onset_date           DATE,
    diagnosis_date               DATE,
    time_to_diagnosis_days       INT,
    diagnostic_method            VARCHAR(30),
    treatment_type               VARCHAR(30),
    treatment_start_date         DATE,
    treatment_duration_weeks     INT,
    treatment_adherence_pct      FLOAT,
    medication_name              VARCHAR(50),
    drug_availability            VARCHAR(20),
    side_effects_reported        VARCHAR(5),
    follow_up_date               DATE,
    primary_outcome              VARCHAR(30),
    hospital_readmission         VARCHAR(5),
    complication_developed       VARCHAR(5),
    complication_type            VARCHAR(50),
    quality_of_life_score        INT,
    country                      VARCHAR(30),
    city                         VARCHAR(50),
    location_type                VARCHAR(20),
    facility_name                VARCHAR(100),
    facility_tier                VARCHAR(20),
    specialist_available         VARCHAR(5),
    avg_wait_time_hours          FLOAT,
    equipment_quality_score      INT
);

-- ============================================================
-- STEP 1A: LOAD DATA FROM CSV
-- ============================================================

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Data/ckd_analysis/ckd_analysis.csv'
INTO TABLE ckd_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    patient_id, age, sex,
    @bmi, @smoking_status, @alcohol_use, @education_level,
    employment_status, @monthly_income_usd, insurance_status,
    disease_name, disease_stage_at_diagnosis, @comorbidities,
    symptom_onset_date, diagnosis_date, time_to_diagnosis_days,
    diagnostic_method, treatment_type, treatment_start_date,
    treatment_duration_weeks, treatment_adherence_pct,
    medication_name, drug_availability, @side_effects_reported,
    follow_up_date, primary_outcome, hospital_readmission,
    complication_developed, @complication_type,
    quality_of_life_score, country, city, location_type,
    facility_name, facility_tier, specialist_available,
    avg_wait_time_hours, equipment_quality_score
)
SET
    -- Convert empty strings to NULL for nullable columns
    bmi                   = NULLIF(@bmi, ''),
    smoking_status        = NULLIF(@smoking_status, ''),
    alcohol_use           = NULLIF(@alcohol_use, ''),
    education_level       = NULLIF(@education_level, ''),
    monthly_income_usd    = NULLIF(@monthly_income_usd, ''),
    comorbidities         = NULLIF(@comorbidities, ''),
    side_effects_reported = NULLIF(@side_effects_reported, ''),
    complication_type     = NULLIF(@complication_type, '');


-- ============================================================
-- SECTION 2: DATA QUALITY AUDIT
-- ============================================================

-- 2A: Row count — expect 100,000
SELECT COUNT(*) AS total_rows FROM ckd_raw;

-- 2B: Duplicate patient IDs — expect 0
SELECT patient_id, COUNT(*) AS occurrences
FROM ckd_raw
GROUP BY patient_id
HAVING COUNT(*) > 1;

-- 2C: NULL counts for every column
SELECT
    SUM(bmi                   IS NULL) AS null_bmi,
    SUM(smoking_status        IS NULL) AS null_smoking_status,
    SUM(alcohol_use           IS NULL) AS null_alcohol_use,
    SUM(education_level       IS NULL) AS null_education_level,
    SUM(monthly_income_usd    IS NULL) AS null_monthly_income,
    SUM(comorbidities         IS NULL) AS null_comorbidities,
    SUM(side_effects_reported IS NULL) AS null_side_effects,
    SUM(complication_type     IS NULL) AS null_complication_type
FROM ckd_raw;

-- 2D: Negative wait times — data entry error
SELECT COUNT(*) AS negative_wait_times
FROM ckd_raw
WHERE avg_wait_time_hours < 0;

-- 2E: Out-of-range values
SELECT
    MIN(age)                    AS min_age,
    MAX(age)                    AS max_age,
    MIN(bmi)                    AS min_bmi,
    MAX(bmi)                    AS max_bmi,
    MIN(quality_of_life_score)  AS min_qol,
    MAX(quality_of_life_score)  AS max_qol,
    MIN(equipment_quality_score)AS min_equip,
    MAX(equipment_quality_score)AS max_equip,
    MIN(treatment_adherence_pct)AS min_adherence,
    MAX(treatment_adherence_pct)AS max_adherence
FROM ckd_raw;

-- 2F: Distinct values in key categorical columns (spot bad entries)
SELECT DISTINCT sex               FROM ckd_raw;
SELECT DISTINCT smoking_status    FROM ckd_raw;
SELECT DISTINCT alcohol_use       FROM ckd_raw;
SELECT DISTINCT insurance_status  FROM ckd_raw;
SELECT DISTINCT disease_stage_at_diagnosis FROM ckd_raw;
SELECT DISTINCT primary_outcome   FROM ckd_raw;
SELECT DISTINCT treatment_type    FROM ckd_raw;
SELECT DISTINCT drug_availability FROM ckd_raw;
SELECT DISTINCT facility_tier     FROM ckd_raw;
SELECT DISTINCT location_type     FROM ckd_raw;
SELECT DISTINCT country           FROM ckd_raw;


-- ============================================================
-- SECTION 3: CREATE CLEANED TABLE
-- ============================================================

DROP TABLE IF EXISTS ckd_clean;

CREATE TABLE ckd_clean AS
SELECT * FROM ckd_raw;   -- We'll clean in place on this copy


-- ============================================================
-- SECTION 4: HANDLE MISSING VALUES
-- ============================================================

-- ---------------------------------------------------------------
-- 4A: BMI — 5,052 nulls (<6%)
--     Strategy: Impute with median BMI per sex group
--     Reason: BMI varies meaningfully by sex; median is robust
--     to outliers and avoids distorting the distribution.
-- ---------------------------------------------------------------

UPDATE ckd_clean c
JOIN (
    SELECT sex,
           AVG(bmi) AS median_bmi
    FROM (                           
        SELECT sex, bmi,             
               ROW_NUMBER() OVER (PARTITION BY sex ORDER BY bmi) AS rn,
               COUNT(*) OVER (PARTITION BY sex) AS cnt
        FROM ckd_clean
        WHERE bmi IS NOT NULL
    ) ranked
    WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
    GROUP BY sex
) medians ON c.sex = medians.sex
SET c.bmi = ROUND(medians.median_bmi, 1)
WHERE c.bmi IS NULL;

-- ---------------------------------------------------------------
-- 4B: smoking_status — 5,042 nulls (<6%)
--     Strategy: Impute with mode (most frequent value per country)
--     Reason: Smoking habits are culturally influenced; country-
--     level mode is a better proxy than a global default.
-- ---------------------------------------------------------------

UPDATE ckd_clean c
JOIN (
    SELECT country, smoking_status AS mode_smoking
    FROM (
        SELECT country, smoking_status,
               RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rnk
        FROM ckd_clean
        WHERE smoking_status IS NOT NULL
        GROUP BY country, smoking_status
    ) ranked
    WHERE rnk = 1
) modes ON c.country = modes.country
SET c.smoking_status = modes.mode_smoking
WHERE c.smoking_status IS NULL;

-- ---------------------------------------------------------------
-- 4C: alcohol_use — 47,941 nulls (48%)
--     Strategy: Label as 'Unknown'
--     Reason: Nearly half the column is missing. Imputing this
--     many values would introduce too much bias. 'Unknown' is
--     honest and can still be used as a valid category in analysis.
-- ---------------------------------------------------------------

UPDATE ckd_clean
SET alcohol_use = 'Unknown'
WHERE alcohol_use IS NULL;

-- ---------------------------------------------------------------
-- 4D: education_level — 12,407 nulls (12%)
--     Strategy: Impute with mode per country
--     Reason: Education levels vary significantly by country;
--     country-level mode is more representative than global mode.
-- ---------------------------------------------------------------

UPDATE ckd_clean c
JOIN (
    SELECT country, education_level AS mode_edu
    FROM (
        SELECT country, education_level,
               RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rnk
        FROM ckd_clean
        WHERE education_level IS NOT NULL
        GROUP BY country, education_level
    ) ranked
    WHERE rnk = 1
) modes ON c.country = modes.country
SET c.education_level = modes.mode_edu
WHERE c.education_level IS NULL;

-- ---------------------------------------------------------------
-- 4E: monthly_income_usd — 4,918 nulls (5%)
--     Strategy: Impute with median income per country
--     Reason: Income is heavily skewed (not normally distributed),
--     so median is more appropriate than mean. Country-level
--     grouping captures economic differences.
-- ---------------------------------------------------------------

UPDATE ckd_clean c
JOIN (
    SELECT country,
           AVG(monthly_income_usd) AS median_income
    FROM (
        SELECT country, monthly_income_usd,
               ROW_NUMBER() OVER (PARTITION BY country ORDER BY monthly_income_usd) AS rn,
               COUNT(*) OVER (PARTITION BY country) AS cnt
        FROM ckd_clean
        WHERE monthly_income_usd IS NOT NULL
    ) ranked
    WHERE rn IN (FLOOR((cnt + 1) / 2), CEIL((cnt + 1) / 2))
    GROUP BY country
) medians ON c.country = medians.country
SET c.monthly_income_usd = ROUND(medians.median_income, 2)
WHERE c.monthly_income_usd IS NULL;

-- ---------------------------------------------------------------
-- 4F: comorbidities — 42,304 nulls (42%)
--     Strategy: Label as 'None'
--     Reason: In a medical context, a missing comorbidity field
--     most plausibly means no recorded comorbidity. 'None' is
--     clinically meaningful and analytically usable.
-- ---------------------------------------------------------------

UPDATE ckd_clean
SET comorbidities = 'None'
WHERE comorbidities IS NULL;

-- ---------------------------------------------------------------
-- 4G: side_effects_reported — 4,967 nulls (5%)
--     Strategy: Label as 'Unknown'
--     Reason: We cannot assume 'No' (that would be a clinical
--     assumption). 'Unknown' keeps the data honest.
-- ---------------------------------------------------------------

UPDATE ckd_clean
SET side_effects_reported = 'Unknown'
WHERE side_effects_reported IS NULL;

-- ---------------------------------------------------------------
-- 4H: complication_type — 66,954 nulls (67%)
--     Strategy: Label as 'None'
--     Reason: complication_developed = 'No' for most of these rows.
--     A NULL complication_type where no complication occurred is
--     meaningfully 'None', not missing information.
-- ---------------------------------------------------------------

UPDATE ckd_clean
SET complication_type = 'None'
WHERE complication_type IS NULL;

-- Verify: all nulls resolved
SELECT
    SUM(bmi                   IS NULL) AS null_bmi,
    SUM(smoking_status        IS NULL) AS null_smoking,
    SUM(alcohol_use           IS NULL) AS null_alcohol,
    SUM(education_level       IS NULL) AS null_education,
    SUM(monthly_income_usd    IS NULL) AS null_income,
    SUM(comorbidities         IS NULL) AS null_comorbidities,
    SUM(side_effects_reported IS NULL) AS null_side_effects,
    SUM(complication_type     IS NULL) AS null_complication_type
FROM ckd_clean;


-- ============================================================
-- SECTION 5: FIX DATA ERRORS
-- ============================================================

-- ---------------------------------------------------------------
-- 5A: Negative avg_wait_time_hours — 9 records
--     Strategy: Replace with absolute value (treat as data entry
--     error where a negative sign was accidentally added)
-- ---------------------------------------------------------------

UPDATE ckd_clean
SET avg_wait_time_hours = ABS(avg_wait_time_hours)
WHERE avg_wait_time_hours < 0;

-- Verify
SELECT COUNT(*) AS remaining_negative_wait_times
FROM ckd_clean
WHERE avg_wait_time_hours < 0;


-- ============================================================
-- SECTION 6: STANDARDISE DATA FORMATS
-- ============================================================

-- ---------------------------------------------------------------
-- 6A: Trim whitespace from all string columns
--     Reason: CSV imports often introduce leading/trailing spaces
--     that cause mismatches in GROUP BY and JOIN operations.
-- ---------------------------------------------------------------

UPDATE ckd_clean SET
    sex                        = TRIM(sex),
    smoking_status             = TRIM(smoking_status),
    alcohol_use                = TRIM(alcohol_use),
    education_level            = TRIM(education_level),
    employment_status          = TRIM(employment_status),
    insurance_status           = TRIM(insurance_status),
    disease_stage_at_diagnosis = TRIM(disease_stage_at_diagnosis),
    diagnostic_method          = TRIM(diagnostic_method),
    treatment_type             = TRIM(treatment_type),
    medication_name            = TRIM(medication_name),
    drug_availability          = TRIM(drug_availability),
    side_effects_reported      = TRIM(side_effects_reported),
    primary_outcome            = TRIM(primary_outcome),
    hospital_readmission       = TRIM(hospital_readmission),
    complication_developed     = TRIM(complication_developed),
    complication_type          = TRIM(complication_type),
    country                    = TRIM(country),
    city                       = TRIM(city),
    location_type              = TRIM(location_type),
    facility_tier              = TRIM(facility_tier),
    specialist_available       = TRIM(specialist_available),
    comorbidities              = TRIM(comorbidities);

-- ---------------------------------------------------------------
-- 6B: Standardise Yes/No columns to consistent casing
-- ---------------------------------------------------------------

UPDATE ckd_clean SET hospital_readmission  = 'Yes' WHERE LOWER(hospital_readmission)  = 'yes';
UPDATE ckd_clean SET hospital_readmission  = 'No'  WHERE LOWER(hospital_readmission)  = 'no';
UPDATE ckd_clean SET complication_developed= 'Yes' WHERE LOWER(complication_developed)= 'yes';
UPDATE ckd_clean SET complication_developed= 'No'  WHERE LOWER(complication_developed)= 'no';
UPDATE ckd_clean SET specialist_available  = 'Yes' WHERE LOWER(specialist_available)  = 'yes';
UPDATE ckd_clean SET specialist_available  = 'No'  WHERE LOWER(specialist_available)  = 'no';

-- ---------------------------------------------------------------
-- 6C: Round numeric columns to sensible decimal places
-- ---------------------------------------------------------------

UPDATE ckd_clean SET
    bmi                    = ROUND(bmi, 1),
    monthly_income_usd     = ROUND(monthly_income_usd, 2),
    treatment_adherence_pct= ROUND(treatment_adherence_pct, 1),
    avg_wait_time_hours    = ROUND(avg_wait_time_hours, 1);


-- ============================================================
-- SECTION 7: FEATURE ENGINEERING
-- (New calculated columns to enrich analysis)
-- ============================================================

-- ---------------------------------------------------------------
-- 7A: age_group — for demographic segmentation
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN age_group VARCHAR(20);

UPDATE ckd_clean
SET age_group = CASE
    WHEN age BETWEEN 18 AND 30 THEN '18–30'
    WHEN age BETWEEN 31 AND 45 THEN '31–45'
    WHEN age BETWEEN 46 AND 60 THEN '46–60'
    WHEN age BETWEEN 61 AND 75 THEN '61–75'
    ELSE '76+'
END;

-- ---------------------------------------------------------------
-- 7B: bmi_category — standard WHO classifications
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN bmi_category VARCHAR(20);

UPDATE ckd_clean
SET bmi_category = CASE
    WHEN bmi < 18.5 THEN 'Underweight'
    WHEN bmi < 25.0 THEN 'Normal'
    WHEN bmi < 30.0 THEN 'Overweight'
    ELSE 'Obese'
END;

-- ---------------------------------------------------------------
-- 7C: income_bracket — for socioeconomic analysis
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN income_bracket VARCHAR(20);

UPDATE ckd_clean
SET income_bracket = CASE
    WHEN monthly_income_usd < 200  THEN 'Low'
    WHEN monthly_income_usd < 1000 THEN 'Lower-Middle'
    WHEN monthly_income_usd < 5000 THEN 'Upper-Middle'
    ELSE 'High'
END;

-- ---------------------------------------------------------------
-- 7D: diagnosis_delay_category — time from symptom to diagnosis
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN diagnosis_delay_category VARCHAR(50);


UPDATE ckd_clean
SET diagnosis_delay_category = CASE
    WHEN time_to_diagnosis_days <= 14  THEN 'Fast (≤2 weeks)'
    WHEN time_to_diagnosis_days <= 30  THEN 'Moderate (2–4 weeks)'
    WHEN time_to_diagnosis_days <= 60  THEN 'Delayed (1–2 months)'
    ELSE 'Severely Delayed (>2 months)'
END;

-- ---------------------------------------------------------------
-- 7E: adherence_category — treatment compliance tiers
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN adherence_category VARCHAR(30);

UPDATE ckd_clean
SET adherence_category = CASE
    WHEN treatment_adherence_pct >= 80 THEN 'High (≥80%)'
    WHEN treatment_adherence_pct >= 50 THEN 'Moderate (50–79%)'
    ELSE 'Low (<50%)'
END;

-- ---------------------------------------------------------------
-- 7F: outcome_severity — numeric encoding for aggregation
--     1 = best outcome, 4 = worst
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN outcome_severity TINYINT;

UPDATE ckd_clean
SET outcome_severity = CASE
    WHEN primary_outcome = 'Recovered'          THEN 1
    WHEN primary_outcome = 'Ongoing Treatment'  THEN 2
    WHEN primary_outcome = 'Deteriorated'       THEN 3
    WHEN primary_outcome = 'Deceased'           THEN 4
    ELSE NULL
END;

-- ---------------------------------------------------------------
-- 7G: has_comorbidity — simple flag for quick filtering
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN has_comorbidity TINYINT(1);

UPDATE ckd_clean
SET has_comorbidity = CASE
    WHEN comorbidities = 'None' THEN 0
    ELSE 1
END;

-- ---------------------------------------------------------------
-- 7H: symptom_to_diagnosis_gap_days — validation cross-check
--     (should match time_to_diagnosis_days; flags data errors)
-- ---------------------------------------------------------------

ALTER TABLE ckd_clean ADD COLUMN calculated_diagnosis_gap INT;

UPDATE ckd_clean
SET calculated_diagnosis_gap = DATEDIFF(diagnosis_date, symptom_onset_date);

-- Check for mismatches between provided and calculated values
SELECT COUNT(*) AS mismatched_gap_records
FROM ckd_clean
WHERE time_to_diagnosis_days != calculated_diagnosis_gap;


-- ============================================================
-- SECTION 8: FINAL QUALITY CHECK
-- ============================================================

-- 8A: Row count — should still be 100,000
SELECT COUNT(*) AS final_row_count FROM ckd_clean;

-- 8B: Confirm zero nulls remain in critical columns
SELECT
    SUM(age                    IS NULL) AS null_age,
    SUM(sex                    IS NULL) AS null_sex,
    SUM(bmi                    IS NULL) AS null_bmi,
    SUM(smoking_status         IS NULL) AS null_smoking,
    SUM(alcohol_use            IS NULL) AS null_alcohol,
    SUM(education_level        IS NULL) AS null_education,
    SUM(monthly_income_usd     IS NULL) AS null_income,
    SUM(comorbidities          IS NULL) AS null_comorbidities,
    SUM(primary_outcome        IS NULL) AS null_outcome,
    SUM(age_group              IS NULL) AS null_age_group,
    SUM(bmi_category           IS NULL) AS null_bmi_cat,
    SUM(income_bracket         IS NULL) AS null_income_bracket,
    SUM(diagnosis_delay_category IS NULL) AS null_diag_delay,
    SUM(adherence_category     IS NULL) AS null_adherence_cat,
    SUM(outcome_severity       IS NULL) AS null_outcome_severity
FROM ckd_clean;

-- 8C: Preview the final cleaned table
SELECT * FROM ckd_clean LIMIT 10;

-- 8D: Column list with new engineered features
DESCRIBE ckd_clean;


-- ============================================================
-- END OF PHASE 1
-- ============================================================