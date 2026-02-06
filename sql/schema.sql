-- Analytics Database Schema
-- SQLite-compatible star schema for consulting company analytics

-- Dimension: Consultants
CREATE TABLE IF NOT EXISTS dim_consultant (
    consultant_id INTEGER PRIMARY KEY,
    full_name TEXT NOT NULL,
    level TEXT NOT NULL CHECK(level IN ('Junior', 'Consultant', 'Senior', 'Lead')),
    role TEXT NOT NULL CHECK(role IN ('Engineer', 'Analyst', 'PM')),
    country TEXT NOT NULL,
    hire_date DATE NOT NULL,
    cost_rate_dkk_per_hour REAL NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_consultant_level ON dim_consultant(level);
CREATE INDEX IF NOT EXISTS idx_consultant_country ON dim_consultant(country);
CREATE INDEX IF NOT EXISTS idx_consultant_role ON dim_consultant(role);

-- Dimension: Clients
CREATE TABLE IF NOT EXISTS dim_client (
    client_id INTEGER PRIMARY KEY,
    client_name TEXT NOT NULL,
    sector TEXT NOT NULL CHECK(sector IN ('Public', 'Private')),
    country TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_client_sector ON dim_client(sector);
CREATE INDEX IF NOT EXISTS idx_client_country ON dim_client(country);

-- Dimension: Projects
CREATE TABLE IF NOT EXISTS dim_project (
    project_id INTEGER PRIMARY KEY,
    client_id INTEGER NOT NULL,
    project_name TEXT NOT NULL,
    contract_type TEXT NOT NULL CHECK(contract_type IN ('T&M', 'Fixed')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    project_manager_id INTEGER NOT NULL,
    budget_hours INTEGER NOT NULL,
    budget_value_dkk INTEGER NOT NULL,
    planned_margin_pct REAL NOT NULL,
    FOREIGN KEY (client_id) REFERENCES dim_client(client_id),
    FOREIGN KEY (project_manager_id) REFERENCES dim_consultant(consultant_id),
    CHECK(end_date >= start_date)
);

CREATE INDEX IF NOT EXISTS idx_project_client ON dim_project(client_id);
CREATE INDEX IF NOT EXISTS idx_project_contract_type ON dim_project(contract_type);
CREATE INDEX IF NOT EXISTS idx_project_dates ON dim_project(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_project_pm ON dim_project(project_manager_id);

-- Fact: Timesheets
CREATE TABLE IF NOT EXISTS fact_timesheet (
    entry_id INTEGER PRIMARY KEY,
    work_date DATE NOT NULL,
    consultant_id INTEGER NOT NULL,
    project_id INTEGER,
    hours REAL NOT NULL CHECK(hours > 0),
    billable_flag INTEGER NOT NULL CHECK(billable_flag IN (0, 1)),
    FOREIGN KEY (consultant_id) REFERENCES dim_consultant(consultant_id),
    FOREIGN KEY (project_id) REFERENCES dim_project(project_id)
);

CREATE INDEX IF NOT EXISTS idx_timesheet_date ON fact_timesheet(work_date);
CREATE INDEX IF NOT EXISTS idx_timesheet_consultant ON fact_timesheet(consultant_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_project ON fact_timesheet(project_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_billable ON fact_timesheet(billable_flag);

-- Fact: Invoices
CREATE TABLE IF NOT EXISTS fact_invoice (
    invoice_id INTEGER PRIMARY KEY,
    project_id INTEGER NOT NULL,
    invoice_date DATE NOT NULL,
    amount_dkk INTEGER NOT NULL CHECK(amount_dkk > 0),
    paid_flag INTEGER NOT NULL CHECK(paid_flag IN (0, 1)),
    payment_days INTEGER NOT NULL CHECK(payment_days >= 0),
    FOREIGN KEY (project_id) REFERENCES dim_project(project_id)
);

CREATE INDEX IF NOT EXISTS idx_invoice_date ON fact_invoice(invoice_date);
CREATE INDEX IF NOT EXISTS idx_invoice_project ON fact_invoice(project_id);
CREATE INDEX IF NOT EXISTS idx_invoice_paid ON fact_invoice(paid_flag);
