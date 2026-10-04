-- ============================================================================
-- PROJECT: MaxCare Healthcare 360° Operational & Payout Intelligence Suite
-- PHASE 2: STEP 2.4 - ADVANCED SQL ANALYTICS, WINDOW FUNCTIONS & AUDIT TRIGGER TEST
-- AUTHOR: Khyati Rajput (B.Tech CSE Final Year)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SECTION 1: DOCTOR REVENUE RANKING USING WINDOW FUNCTION (DENSE_RANK)
-- Purpose: Ranks doctors by total revenue generated within their respective departments.
-- ----------------------------------------------------------------------------
SELECT 
    d.department,
    d.doctor_name,
    d.experience_years,
    COUNT(a.appointment_id) AS total_patients_treated,
    COALESCE(SUM(b.treatment_cost), 0.00) AS total_revenue,
    COALESCE(ROUND(AVG(b.treatment_cost), 2), 0.00) AS avg_revenue_per_patient,
    DENSE_RANK() OVER (PARTITION BY d.department ORDER BY COALESCE(SUM(b.treatment_cost), 0.00) DESC) AS revenue_rank_in_dept
FROM Dim_Doctors d
LEFT JOIN Fact_Appointments a ON d.doctor_id = a.doctor_id
LEFT JOIN Fact_Billing b ON a.appointment_id = b.appointment_id
GROUP BY d.department, d.doctor_id, d.doctor_name, d.experience_years
ORDER BY d.department, revenue_rank_in_dept;

-- ----------------------------------------------------------------------------
-- SECTION 2: PATIENT FINANCIAL SEGMENTATION USING NTILE(4)
-- Purpose: Divides patients into 4 financial spend quartiles for targeted insurance/payout programs.
-- ----------------------------------------------------------------------------
WITH PatientSpendCTE AS (
    SELECT 
        p.patient_id,
        p.patient_name,
        p.city,
        COALESCE(SUM(b.treatment_cost), 0.00) AS total_spend,
        COALESCE(SUM(b.insurance_covered), 0.00) AS total_insurance,
        COALESCE(SUM(b.out_of_pocket), 0.00) AS total_out_of_pocket
    FROM Dim_Patients p
    JOIN Fact_Appointments a ON p.patient_id = a.patient_id
    JOIN Fact_Billing b ON a.appointment_id = b.appointment_id
    GROUP BY p.patient_id, p.patient_name, p.city
)
SELECT 
    patient_id,
    patient_name,
    city,
    total_spend,
    total_insurance,
    total_out_of_pocket,
    NTILE(4) OVER (ORDER BY total_spend DESC) AS spend_quartile_tier,
    CASE 
        WHEN NTILE(4) OVER (ORDER BY total_spend DESC) = 1 THEN 'High Spend (Tier 1)'
        WHEN NTILE(4) OVER (ORDER BY total_spend DESC) = 2 THEN 'Medium-High Spend (Tier 2)'
        WHEN NTILE(4) OVER (ORDER BY total_spend DESC) = 3 THEN 'Medium-Low Spend (Tier 3)'
        ELSE 'Low Spend (Tier 4)'
    END AS spend_category
FROM PatientSpendCTE
ORDER BY total_spend DESC;

-- ----------------------------------------------------------------------------
-- SECTION 3: DEPARTMENTAL PAYOUT & OPERATIONAL KPIs (CTE + AGGREGATION)
-- Purpose: Comprehensive summary of Revenue, Insurance, Out-of-Pocket, and Payment Realization %.
-- ----------------------------------------------------------------------------
WITH DeptMetrics AS (
    SELECT 
        d.department,
        COUNT(a.appointment_id) AS total_admissions,
        SUM(b.treatment_cost) AS total_revenue,
        SUM(b.insurance_covered) AS total_insurance_claim,
        SUM(b.out_of_pocket) AS total_out_of_pocket,
        COUNT(CASE WHEN b.payment_status = 'Paid' THEN 1 END) AS paid_bills_count,
        COUNT(CASE WHEN b.payment_status = 'Pending' THEN 1 END) AS pending_bills_count,
        AVG(a.discharge_date - a.admission_date) AS avg_length_of_stay_days
    FROM Dim_Doctors d
    JOIN Fact_Appointments a ON d.doctor_id = a.doctor_id
    JOIN Fact_Billing b ON a.appointment_id = b.appointment_id
    GROUP BY d.department
)
SELECT 
    department,
    total_admissions,
    ROUND(total_revenue, 2) AS total_revenue_inr,
    ROUND(total_insurance_claim, 2) AS total_insurance_inr,
    ROUND(total_out_of_pocket, 2) AS total_out_of_pocket_inr,
    ROUND((total_insurance_claim / total_revenue) * 100, 2) AS insurance_coverage_pct,
    ROUND((paid_bills_count::NUMERIC / total_admissions::NUMERIC) * 100, 2) AS payment_realization_pct,
    ROUND(avg_length_of_stay_days, 1) AS avg_stay_duration_days
FROM DeptMetrics
ORDER BY total_revenue_inr DESC;

-- ----------------------------------------------------------------------------
-- SECTION 4: TRIGGER VERIFICATION & AUDIT LOGGING TEST
-- Purpose: Updating a Pending payment to Paid to trigger automated audit record.
-- ----------------------------------------------------------------------------
-- Step 4.1: Find a pending bill
SELECT bill_id, appointment_id, treatment_cost, payment_status 
FROM Fact_Billing 
WHERE payment_status = 'Pending' 
LIMIT 5;

-- Step 4.2: Update payment status to trigger audit log (Execute for top pending bill)
UPDATE Fact_Billing
SET payment_status = 'Paid'
WHERE payment_status = 'Pending'
AND bill_id IN (SELECT bill_id FROM Fact_Billing WHERE payment_status = 'Pending' LIMIT 1);

-- Step 4.3: Verify audit log entry automatically captured by PostgreSQL Trigger
SELECT * FROM Audit_Logs ORDER BY changed_at DESC;

-- ----------------------------------------------------------------------------
-- SECTION 5: CREATING ENTERPRISE POWER BI READ-MODEL VIEW
-- Purpose: Flattened denormalized SQL view for seamless Power BI & Python connectivity.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_hospital_operations_360 AS
SELECT 
    a.appointment_id,
    p.patient_id,
    p.patient_name,
    p.gender,
    p.age,
    p.city,
    d.doctor_id,
    d.doctor_name,
    d.department,
    d.experience_years,
    a.admission_date,
    a.discharge_date,
    (a.discharge_date - a.admission_date) AS length_of_stay_days,
    a.diagnosis,
    a.appointment_status,
    b.bill_id,
    b.treatment_cost,
    b.insurance_covered,
    b.out_of_pocket,
    ROUND((b.insurance_covered / b.treatment_cost) * 100, 2) AS insurance_cover_pct,
    ROUND((b.out_of_pocket / b.treatment_cost) * 100, 2) AS out_of_pocket_pct,
    b.payment_status
FROM Fact_Appointments a
JOIN Dim_Patients p ON a.patient_id = p.patient_id
JOIN Dim_Doctors d ON a.doctor_id = d.doctor_id
JOIN Fact_Billing b ON a.appointment_id = b.appointment_id;

-- Quick View Check
SELECT * FROM vw_hospital_operations_360 LIMIT 10;
