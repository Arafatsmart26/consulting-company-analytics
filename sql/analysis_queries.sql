-- Analysis Queries
-- 20+ queries for business insights

-- 1. Monthly Utilization by Level
SELECT 
    strftime('%Y-%m', work_date) AS month,
    level,
    SUM(billable_hours) AS total_billable_hours,
    SUM(total_hours) AS total_hours,
    ROUND(AVG(utilization_pct), 2) AS avg_utilization_pct
FROM v_utilization_daily
GROUP BY strftime('%Y-%m', work_date), level
ORDER BY month DESC, level;

-- 2. Monthly Utilization by Country
SELECT 
    strftime('%Y-%m', work_date) AS month,
    country,
    SUM(billable_hours) AS total_billable_hours,
    SUM(total_hours) AS total_hours,
    ROUND(AVG(utilization_pct), 2) AS avg_utilization_pct
FROM v_utilization_daily
GROUP BY strftime('%Y-%m', work_date), country
ORDER BY month DESC, country;

-- 3. Bench Trend (Non-billable Hours Share)
SELECT 
    strftime('%Y-%m', work_date) AS month,
    SUM(CASE WHEN billable_flag = 0 THEN hours ELSE 0 END) AS non_billable_hours,
    SUM(hours) AS total_hours,
    ROUND(SUM(CASE WHEN billable_flag = 0 THEN hours ELSE 0 END) * 100.0 / SUM(hours), 2) AS bench_pct
FROM fact_timesheet
GROUP BY strftime('%Y-%m', work_date)
ORDER BY month DESC;

-- 4. Top 10 Clients by Revenue
SELECT 
    cl.client_id,
    cl.client_name,
    cl.sector,
    COUNT(DISTINCT i.invoice_id) AS invoice_count,
    SUM(i.amount_dkk) AS total_revenue,
    SUM(CASE WHEN i.paid_flag = 1 THEN i.amount_dkk ELSE 0 END) AS paid_revenue
FROM dim_client cl
JOIN dim_project p ON cl.client_id = p.client_id
JOIN fact_invoice i ON p.project_id = i.project_id
GROUP BY cl.client_id, cl.client_name, cl.sector
ORDER BY total_revenue DESC
LIMIT 10;

-- 5. Revenue Concentration (Top 5 clients % of total)
WITH client_revenue AS (
    SELECT 
        cl.client_id,
        cl.client_name,
        SUM(i.amount_dkk) AS revenue
    FROM dim_client cl
    JOIN dim_project p ON cl.client_id = p.client_id
    JOIN fact_invoice i ON p.project_id = i.project_id
    GROUP BY cl.client_id, cl.client_name
),
total_revenue AS (
    SELECT SUM(revenue) AS total FROM client_revenue
)
SELECT 
    ROUND(SUM(cr.revenue) * 100.0 / tr.total, 2) AS top5_concentration_pct
FROM (
    SELECT revenue FROM client_revenue ORDER BY revenue DESC LIMIT 5
) cr
CROSS JOIN total_revenue tr;

-- 6. Projects Over Budget Hours
SELECT 
    project_id,
    project_name,
    contract_type,
    budget_hours,
    actual_hours,
    hours_overrun_pct,
    budget_burn_pct
FROM v_project_financials
WHERE actual_hours > budget_hours
ORDER BY hours_overrun_pct DESC;

-- 7. Projects Over Budget by Contract Type
SELECT 
    contract_type,
    COUNT(*) AS total_projects,
    SUM(CASE WHEN actual_hours > budget_hours THEN 1 ELSE 0 END) AS over_budget_count,
    ROUND(SUM(CASE WHEN actual_hours > budget_hours THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS over_budget_pct,
    ROUND(AVG(CASE WHEN actual_hours > budget_hours THEN hours_overrun_pct ELSE 0 END), 2) AS avg_overrun_pct
FROM v_project_financials
GROUP BY contract_type;

-- 8. Invoice Payment Behavior: Public vs Private
SELECT 
    cl.sector,
    COUNT(*) AS total_invoices,
    SUM(CASE WHEN i.paid_flag = 1 THEN 1 ELSE 0 END) AS paid_count,
    ROUND(SUM(CASE WHEN i.paid_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS paid_pct,
    ROUND(AVG(i.payment_days), 1) AS avg_payment_days,
    ROUND(AVG(CASE WHEN i.paid_flag = 0 THEN (julianday('now') - julianday(i.invoice_date)) ELSE NULL END), 1) AS avg_days_outstanding
FROM fact_invoice i
JOIN dim_project p ON i.project_id = p.project_id
JOIN dim_client cl ON p.client_id = cl.client_id
GROUP BY cl.sector;

-- 9. Revenue Trend Over Time
SELECT 
    strftime('%Y-%m', invoice_date) AS month,
    SUM(amount_dkk) AS total_revenue,
    SUM(CASE WHEN paid_flag = 1 THEN amount_dkk ELSE 0 END) AS paid_revenue,
    COUNT(*) AS invoice_count
FROM fact_invoice
GROUP BY strftime('%Y-%m', invoice_date)
ORDER BY month DESC;

-- 10. Margin Trend (Planned vs Actual Proxy)
-- Using budget burn and planned margin to estimate actual margin
SELECT 
    strftime('%Y-%m', p.start_date) AS project_start_month,
    p.contract_type,
    COUNT(*) AS project_count,
    ROUND(AVG(p.planned_margin_pct) * 100, 2) AS avg_planned_margin_pct,
    ROUND(AVG(pf.budget_burn_pct), 2) AS avg_budget_burn_pct,
    -- Estimated actual margin: if burn > 100%, margin decreases
    ROUND(AVG(p.planned_margin_pct) * 100 - 
          CASE WHEN AVG(pf.budget_burn_pct) > 100 
               THEN (AVG(pf.budget_burn_pct) - 100) * 0.5 
               ELSE 0 END, 2) AS estimated_actual_margin_pct
FROM dim_project p
JOIN v_project_financials pf ON p.project_id = pf.project_id
GROUP BY strftime('%Y-%m', p.start_date), p.contract_type
ORDER BY project_start_month DESC;

-- 11. Consultant Performance by Utilization
SELECT 
    c.consultant_id,
    c.full_name,
    c.level,
    c.country,
    SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) AS total_billable_hours,
    SUM(t.hours) AS total_hours,
    ROUND(SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) * 100.0 / SUM(t.hours), 2) AS utilization_pct,
    COUNT(DISTINCT t.project_id) AS project_count
FROM dim_consultant c
LEFT JOIN fact_timesheet t ON c.consultant_id = t.consultant_id
GROUP BY c.consultant_id, c.full_name, c.level, c.country
HAVING total_hours > 0
ORDER BY utilization_pct DESC;

-- 12. AR Aging Summary
SELECT 
    aging_bucket,
    COUNT(*) AS invoice_count,
    SUM(amount_dkk) AS total_amount,
    ROUND(AVG(days_outstanding), 1) AS avg_days_outstanding
FROM v_ar_aging
GROUP BY aging_bucket
ORDER BY 
    CASE aging_bucket
        WHEN 'Paid' THEN 0
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '90+ days' THEN 4
    END;

-- 13. At-Risk Projects Definition
-- Projects with: utilization drop + overrun + unpaid invoices
SELECT 
    pf.project_id,
    pf.project_name,
    pf.client_name,
    pf.contract_type,
    pf.actual_hours,
    pf.budget_hours,
    pf.hours_overrun_pct,
    COALESCE(ar.unpaid_amount, 0) AS unpaid_invoice_amount,
    CASE 
        WHEN pf.hours_overrun_pct > 10 AND COALESCE(ar.unpaid_amount, 0) > 0 THEN 'High Risk'
        WHEN pf.hours_overrun_pct > 5 OR COALESCE(ar.unpaid_amount, 0) > 50000 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM v_project_financials pf
LEFT JOIN (
    SELECT 
        project_id,
        SUM(amount_dkk) AS unpaid_amount
    FROM fact_invoice
    WHERE paid_flag = 0
    GROUP BY project_id
) ar ON pf.project_id = ar.project_id
WHERE pf.hours_overrun_pct > 0 OR COALESCE(ar.unpaid_amount, 0) > 0
ORDER BY 
    CASE risk_level
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        ELSE 3
    END,
    pf.hours_overrun_pct DESC;

-- 14. Monthly Billable Hours by Role
SELECT 
    strftime('%Y-%m', t.work_date) AS month,
    c.role,
    SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) AS billable_hours,
    COUNT(DISTINCT t.consultant_id) AS active_consultants
FROM fact_timesheet t
JOIN dim_consultant c ON t.consultant_id = c.consultant_id
GROUP BY strftime('%Y-%m', t.work_date), c.role
ORDER BY month DESC, c.role;

-- 15. Project Duration Analysis
SELECT 
    contract_type,
    COUNT(*) AS project_count,
    ROUND(AVG(julianday(end_date) - julianday(start_date)), 1) AS avg_duration_days,
    MIN(julianday(end_date) - julianday(start_date)) AS min_duration_days,
    MAX(julianday(end_date) - julianday(start_date)) AS max_duration_days
FROM dim_project
GROUP BY contract_type;

-- 16. Revenue by Sector and Month
SELECT 
    strftime('%Y-%m', i.invoice_date) AS month,
    cl.sector,
    SUM(i.amount_dkk) AS total_revenue,
    COUNT(*) AS invoice_count,
    ROUND(AVG(i.amount_dkk), 0) AS avg_invoice_amount
FROM fact_invoice i
JOIN dim_project p ON i.project_id = p.project_id
JOIN dim_client cl ON p.client_id = cl.client_id
GROUP BY strftime('%Y-%m', i.invoice_date), cl.sector
ORDER BY month DESC, cl.sector;

-- 17. Consultant Cost vs Revenue Contribution
SELECT 
    c.consultant_id,
    c.full_name,
    c.level,
    c.cost_rate_dkk_per_hour,
    SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) AS billable_hours,
    SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) * c.cost_rate_dkk_per_hour AS cost_dkk,
    -- Estimate revenue contribution (using average blended rate of 800)
    SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) * 800 AS estimated_revenue_dkk
FROM dim_consultant c
LEFT JOIN fact_timesheet t ON c.consultant_id = t.consultant_id
GROUP BY c.consultant_id, c.full_name, c.level, c.cost_rate_dkk_per_hour
HAVING billable_hours > 0
ORDER BY estimated_revenue_dkk DESC;

-- 18. Projects by Status (Active/Completed)
SELECT 
    CASE 
        WHEN date('now') BETWEEN start_date AND end_date THEN 'Active'
        WHEN date('now') > end_date THEN 'Completed'
        ELSE 'Upcoming'
    END AS project_status,
    contract_type,
    COUNT(*) AS project_count,
    SUM(budget_value_dkk) AS total_budget_value
FROM dim_project
GROUP BY project_status, contract_type
ORDER BY project_status, contract_type;

-- 19. Payment Days Distribution
SELECT 
    cl.sector,
    CASE 
        WHEN i.payment_days <= 30 THEN '0-30 days'
        WHEN i.payment_days <= 45 THEN '31-45 days'
        WHEN i.payment_days <= 60 THEN '46-60 days'
        ELSE '60+ days'
    END AS payment_days_bucket,
    COUNT(*) AS invoice_count,
    ROUND(AVG(i.payment_days), 1) AS avg_payment_days
FROM fact_invoice i
JOIN dim_project p ON i.project_id = p.project_id
JOIN dim_client cl ON p.client_id = cl.client_id
GROUP BY cl.sector, payment_days_bucket
ORDER BY cl.sector, payment_days_bucket;

-- 20. Monthly Utilization Trend (Overall)
SELECT 
    strftime('%Y-%m', work_date) AS month,
    SUM(billable_hours) AS total_billable_hours,
    SUM(total_hours) AS total_hours,
    ROUND(AVG(utilization_pct), 2) AS avg_utilization_pct,
    COUNT(DISTINCT consultant_id) AS active_consultants
FROM v_utilization_daily
GROUP BY strftime('%Y-%m', work_date)
ORDER BY month DESC;

-- 21. Top Project Managers by Project Count and Budget
SELECT 
    c.consultant_id,
    c.full_name,
    COUNT(DISTINCT p.project_id) AS project_count,
    SUM(p.budget_value_dkk) AS total_budget_managed,
    ROUND(AVG(p.planned_margin_pct) * 100, 2) AS avg_planned_margin_pct
FROM dim_consultant c
JOIN dim_project p ON c.consultant_id = p.project_manager_id
GROUP BY c.consultant_id, c.full_name
ORDER BY project_count DESC, total_budget_managed DESC;

-- 22. Revenue Recognition vs Cash Collection
SELECT 
    strftime('%Y-%m', invoice_date) AS month,
    SUM(amount_dkk) AS revenue_recognized,
    SUM(CASE WHEN paid_flag = 1 THEN amount_dkk ELSE 0 END) AS cash_collected,
    SUM(CASE WHEN paid_flag = 0 THEN amount_dkk ELSE 0 END) AS outstanding_ar,
    ROUND(SUM(CASE WHEN paid_flag = 1 THEN amount_dkk ELSE 0 END) * 100.0 / SUM(amount_dkk), 2) AS collection_rate_pct
FROM fact_invoice
GROUP BY strftime('%Y-%m', invoice_date)
ORDER BY month DESC;
