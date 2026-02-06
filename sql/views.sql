-- Analytics Views
-- Pre-aggregated views for common analytics queries

-- View: Daily Utilization by Consultant
CREATE VIEW IF NOT EXISTS v_utilization_daily AS
SELECT 
    t.work_date,
    t.consultant_id,
    c.full_name,
    c.level,
    c.country,
    SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) AS billable_hours,
    SUM(t.hours) AS total_hours,
    CASE 
        WHEN SUM(t.hours) > 0 
        THEN ROUND(SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END) * 100.0 / SUM(t.hours), 2)
        ELSE 0 
    END AS utilization_pct
FROM fact_timesheet t
JOIN dim_consultant c ON t.consultant_id = c.consultant_id
GROUP BY t.work_date, t.consultant_id, c.full_name, c.level, c.country;

-- View: Project Financials
CREATE VIEW IF NOT EXISTS v_project_financials AS
SELECT 
    p.project_id,
    p.project_name,
    p.client_id,
    cl.client_name,
    cl.sector,
    p.contract_type,
    p.start_date,
    p.end_date,
    p.budget_hours,
    p.budget_value_dkk,
    p.planned_margin_pct,
    COALESCE(SUM(t.hours), 0) AS actual_hours,
    CASE 
        WHEN p.budget_hours > 0 
        THEN ROUND((COALESCE(SUM(t.hours), 0) - p.budget_hours) * 100.0 / p.budget_hours, 2)
        ELSE 0 
    END AS hours_overrun_pct,
    CASE 
        WHEN p.budget_hours > 0 
        THEN ROUND(COALESCE(SUM(t.hours), 0) * 100.0 / p.budget_hours, 2)
        ELSE 0 
    END AS budget_burn_pct,
    COALESCE(SUM(CASE WHEN t.billable_flag = 1 THEN t.hours ELSE 0 END), 0) AS billable_hours,
    COALESCE(SUM(i.amount_dkk), 0) AS invoiced_amount,
    CASE 
        WHEN p.budget_value_dkk > 0 
        THEN ROUND(COALESCE(SUM(i.amount_dkk), 0) * 100.0 / p.budget_value_dkk, 2)
        ELSE 0 
    END AS invoiced_pct
FROM dim_project p
LEFT JOIN fact_timesheet t ON p.project_id = t.project_id AND t.billable_flag = 1
LEFT JOIN fact_invoice i ON p.project_id = i.project_id
LEFT JOIN dim_client cl ON p.client_id = cl.client_id
GROUP BY p.project_id, p.project_name, p.client_id, cl.client_name, cl.sector, 
         p.contract_type, p.start_date, p.end_date, p.budget_hours, 
         p.budget_value_dkk, p.planned_margin_pct;

-- View: Client Revenue
CREATE VIEW IF NOT EXISTS v_client_revenue AS
SELECT 
    cl.client_id,
    cl.client_name,
    cl.sector,
    cl.country,
    strftime('%Y-%m', i.invoice_date) AS invoice_month,
    COUNT(DISTINCT i.invoice_id) AS invoice_count,
    SUM(i.amount_dkk) AS total_revenue,
    SUM(CASE WHEN i.paid_flag = 1 THEN i.amount_dkk ELSE 0 END) AS paid_revenue,
    SUM(CASE WHEN i.paid_flag = 0 THEN i.amount_dkk ELSE 0 END) AS unpaid_revenue,
    AVG(i.payment_days) AS avg_payment_days
FROM dim_client cl
JOIN dim_project p ON cl.client_id = p.client_id
JOIN fact_invoice i ON p.project_id = i.project_id
GROUP BY cl.client_id, cl.client_name, cl.sector, cl.country, strftime('%Y-%m', i.invoice_date);

-- View: Accounts Receivable Aging
CREATE VIEW IF NOT EXISTS v_ar_aging AS
SELECT 
    i.invoice_id,
    i.project_id,
    p.project_name,
    cl.client_id,
    cl.client_name,
    cl.sector,
    i.invoice_date,
    i.amount_dkk,
    i.paid_flag,
    i.payment_days,
    CASE 
        WHEN i.paid_flag = 1 THEN 0
        ELSE (julianday('now') - julianday(i.invoice_date))
    END AS days_outstanding,
    CASE 
        WHEN i.paid_flag = 1 THEN 'Paid'
        WHEN (julianday('now') - julianday(i.invoice_date)) <= 30 THEN '0-30 days'
        WHEN (julianday('now') - julianday(i.invoice_date)) <= 60 THEN '31-60 days'
        WHEN (julianday('now') - julianday(i.invoice_date)) <= 90 THEN '61-90 days'
        ELSE '90+ days'
    END AS aging_bucket
FROM fact_invoice i
JOIN dim_project p ON i.project_id = p.project_id
JOIN dim_client cl ON p.client_id = cl.client_id
WHERE i.paid_flag = 0;
