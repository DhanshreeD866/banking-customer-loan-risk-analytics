CREATE DATABASE banking_risk_analytics;

USE banking_risk_analytics;

CREATE TABLE loan_risk (
    customer_id INT,
    customer_age INT,
    customer_income INT,
    home_ownership VARCHAR(20),
    employment_duration DECIMAL(5,2),
    loan_intent VARCHAR(50),
    loan_grade VARCHAR(5),
    loan_amnt DECIMAL(12,2),
    loan_int_rate DECIMAL(6,2),
    term_years INT,
    historical_default VARCHAR(20),
    cred_hist_length INT,
    Current_loan_status VARCHAR(50)
);
    
drop table if exists loan_risk;
-- Load data into table -- 
LOAD DATA LOCAL INFILE 'C:/Users/dhanashree/Downloads/LoanDataset.csv'
INTO TABLE loan_risk
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT *
FROM loan_risk
LIMIT 5;

-- 1) Overall portfolio summary -- 
SELECT
    COUNT(*) AS total_loans,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(loan_amnt) AS total_loan_value,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(customer_income), 2) AS avg_customer_income,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate,
    ROUND(AVG(term_years), 2) AS avg_loan_term
FROM loan_risk;

-- 2) Loan status distribution -- 
SELECT
    Current_loan_status,
    COUNT(*) AS total_loans,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS portfolio_percentage
FROM loan_risk
GROUP BY Current_loan_status
ORDER BY total_loans DESC;

-- 3) Risk by home ownership -- 
SELECT
    home_ownership,
    COUNT(*) AS total_loans,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(customer_income), 2) AS avg_income
FROM loan_risk
GROUP BY home_ownership
ORDER BY total_loans DESC;

-- 4) Age segmentation -- 
SELECT
    CASE
        WHEN customer_age < 25 THEN '18-24'
        WHEN customer_age < 35 THEN '25-34'
        WHEN customer_age < 45 THEN '35-44'
        WHEN customer_age < 55 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS total_customers,
    ROUND(AVG(customer_income), 2) AS avg_income,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount
FROM loan_risk
GROUP BY age_group
ORDER BY age_group;

-- 5) Employment segmentation -- 
SELECT
    CASE
        WHEN employment_duration < 2 THEN '0-1 Years'
        WHEN employment_duration < 5 THEN '2-4 Years'
        WHEN employment_duration < 10 THEN '5-9 Years'
        ELSE '10+ Years'
    END AS employment_group,
    COUNT(*) AS total_customers,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(customer_income), 2) AS avg_income
FROM loan_risk
GROUP BY employment_group
ORDER BY employment_group;

-- 6) Loan grade analysis -- 
SELECT
    loan_grade,
    COUNT(*) AS total_loans,
    SUM(loan_amnt) AS total_loan_value,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate
FROM loan_risk
GROUP BY loan_grade
ORDER BY loan_grade;

-- 7) Default rate by loan grade -- 
SELECT
    loan_grade,
    COUNT(*) AS total_loans,
    SUM(Current_loan_status = 'DEFAULT') AS defaults,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY loan_grade
ORDER BY default_rate DESC;

-- 8)  Default rate by loan intent -- 
SELECT
    loan_intent,
    COUNT(*) AS total_loans,
    SUM(Current_loan_status = 'DEFAULT
') AS defaults,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT
') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY loan_intent
ORDER BY default_rate DESC;

-- 9) Default rate by age group -- 
SELECT
    CASE
        WHEN customer_age < 25 THEN '18-24'
        WHEN customer_age < 35 THEN '25-34'
        WHEN customer_age < 45 THEN '35-44'
        WHEN customer_age < 55 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    COUNT(*) AS total_loans,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT
') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY age_group
ORDER BY default_rate DESC;

-- 10) Interest-rate risk bands -- 
SELECT
    CASE
        WHEN loan_int_rate < 8 THEN 'Low Rate'
        WHEN loan_int_rate < 12 THEN 'Medium Rate'
        WHEN loan_int_rate < 16 THEN 'High Rate'
        ELSE 'Very High Rate'
    END AS interest_rate_band,
    COUNT(*) AS total_loans,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT
') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY interest_rate_band
ORDER BY default_rate DESC;

-- 11) Income segmentation -- 
SELECT
    CASE
        WHEN customer_income < 30000 THEN 'Low Income'
        WHEN customer_income < 60000 THEN 'Middle Income'
        WHEN customer_income < 100000 THEN 'Upper Middle Income'
        ELSE 'High Income'
    END AS income_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY income_segment
ORDER BY default_rate DESC;

-- 12) Loan burden analysis -- 
SELECT
    CASE
        WHEN loan_amnt / customer_income < 0.10 THEN 'Low Burden'
        WHEN loan_amnt / customer_income < 0.20 THEN 'Moderate Burden'
        WHEN loan_amnt / customer_income < 0.30 THEN 'High Burden'
        ELSE 'Very High Burden'
    END AS loan_burden,
    COUNT(*) AS total_loans,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate
FROM loan_risk
WHERE customer_income > 0
GROUP BY loan_burden
ORDER BY default_rate DESC;

-- 13)  Historical default vs current default -- 
SELECT
    historical_default,
    COUNT(*) AS total_customers,
    SUM(Current_loan_status = 'DEFAULT') AS current_defaults,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS current_default_rate
FROM loan_risk
GROUP BY historical_default
ORDER BY current_default_rate DESC;

-- 14) Credit history length vs default-- 
SELECT
    CASE
        WHEN cred_hist_length < 3 THEN '0-2 Years'
        WHEN cred_hist_length < 6 THEN '3-5 Years'
        WHEN cred_hist_length < 10 THEN '6-9 Years'
        ELSE '10+ Years'
    END AS credit_history_group,
    COUNT(*) AS total_customers,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY credit_history_group
ORDER BY default_rate DESC;

-- 15) Grade × Historical Default -- 
SELECT
    loan_grade,
    historical_default,
    COUNT(*) AS total_loans,
    SUM(Current_loan_status = 'DEFAULT') AS defaults,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY
    loan_grade,
    historical_default
ORDER BY default_rate DESC;

-- 16) Grade × Home Ownership -- 
SELECT
    loan_grade,
    home_ownership,
    COUNT(*) AS total_loans,
    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate
FROM loan_risk
GROUP BY
    loan_grade,
    home_ownership
HAVING COUNT(*) >= 20
ORDER BY default_rate DESC;

-- 17) High-risk loans -- 
SELECT
    customer_id,
    customer_age,
    customer_income,
    loan_amnt,
    loan_int_rate,
    loan_grade,
    historical_default,
    Current_loan_status
FROM loan_risk
WHERE Current_loan_status = 'DEFAULT'
  AND loan_int_rate > 12
  AND loan_amnt / customer_income > 0.20
ORDER BY loan_int_rate DESC;

-- 18) Large loans with high interest -- 
SELECT
    customer_id,
    loan_amnt,
    loan_int_rate,
    customer_income,
    loan_grade,
    Current_loan_status
FROM loan_risk
WHERE loan_amnt >
      (SELECT AVG(loan_amnt) FROM loan_risk)
  AND loan_int_rate >
      (SELECT AVG(loan_int_rate) FROM loan_risk)
ORDER BY loan_amnt DESC;

-- 19) Risk Classification- Low / Medium / High Risk -- 
WITH scored_customers AS (
    SELECT
        customer_id,

        (
            CASE
                WHEN loan_grade IN ('D','E','F','G') THEN 3
                WHEN loan_grade = 'C' THEN 2
                ELSE 1
            END

            +

            CASE
                WHEN loan_int_rate > 15 THEN 3
                WHEN loan_int_rate > 10 THEN 2
                ELSE 1
            END

            +

            CASE
                WHEN loan_amnt / customer_income > 0.30 THEN 3
                WHEN loan_amnt / customer_income > 0.20 THEN 2
                ELSE 1
            END

            +

            CASE
                WHEN historical_default = 'Y' THEN 3
                ELSE 0
            END

            +

            CASE
                WHEN employment_duration < 2 THEN 1
                ELSE 0
            END

        ) AS risk_score

    FROM loan_risk
    WHERE customer_income > 0
)

SELECT
    customer_id,
    risk_score,

    CASE
        WHEN risk_score >= 9 THEN 'High Risk'
        WHEN risk_score >= 6 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category

FROM scored_customers
ORDER BY risk_score DESC;

-- 20) Overall Risk Matrix  -- 
SELECT
    loan_grade,
    historical_default,
    home_ownership,
    COUNT(*) AS total_loans,
    SUM(Current_loan_status = 'DEFAULT') AS defaults,

    ROUND(
        AVG(Current_loan_status = 'DEFAULT') * 100,
        2
    ) AS default_rate,

    ROUND(AVG(loan_amnt), 2) AS avg_loan_amount,

    ROUND(AVG(loan_int_rate), 2) AS avg_interest_rate,

    ROUND(
        AVG(loan_amnt / NULLIF(customer_income, 0)) * 100,
        2
    ) AS avg_loan_income_ratio

FROM loan_risk

GROUP BY
    loan_grade,
    historical_default,
    home_ownership

HAVING COUNT(*) >= 20

ORDER BY default_rate DESC;


























SELECT Current_loan_status, LENGTH(Current_loan_status)
FROM loan_risk
LIMIT 20;

UPDATE loan_risk
SET Current_loan_status =
    TRIM(
        REPLACE(
            REPLACE(Current_loan_status, CHAR(13), ''),
            CHAR(10), ''
        )
    )
WHERE customer_id IS NOT NULL;

SET SQL_SAFE_UPDATES = 1;

UPDATE loan_risk
SET Current_loan_status =
    TRIM(
        REPLACE(
            REPLACE(Current_loan_status, CHAR(13), ''),
            CHAR(10), ''
        )
    );

