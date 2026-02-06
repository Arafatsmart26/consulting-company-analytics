# Data Dictionary

Dette dokument beskriver alle tabeller, kolonner og business rules i consulting company analytics databasen.

## Data Model Overview

Databasen følger en star schema struktur med dimension tables og fact tables:

```
dim_consultant (1) ──┐
                     ├──> fact_timesheet (many)
dim_project (1) ────┘

dim_client (1) ──> dim_project (many) ──> fact_invoice (many)
```

## Dimension Tables

### dim_consultant

Beskriver konsulenter i organisationen.

| Kolonne | Type | Beskrivelse | Constraints |
|---------|------|-------------|-------------|
| consultant_id | INTEGER | Unik identifier for konsulent | PRIMARY KEY |
| full_name | TEXT | Fulde navn på konsulent | NOT NULL |
| level | TEXT | Niveau: Junior, Consultant, Senior, Lead | NOT NULL, CHECK |
| role | TEXT | Rolle: Engineer, Analyst, PM | NOT NULL, CHECK |
| country | TEXT | Land hvor konsulent er baseret | NOT NULL |
| hire_date | DATE | Ansættelsesdato | NOT NULL |
| cost_rate_dkk_per_hour | REAL | Timepris i DKK | NOT NULL |

**Business Rules:**
- Cost rates varierer efter level:
  - Junior: 450 DKK/time
  - Consultant: 650 DKK/time
  - Senior: 900 DKK/time
  - Lead: 1200 DKK/time
- Hire dates spredt over de sidste 3 år
- 45 konsulenter totalt

### dim_client

Beskriver kunder.

| Kolonne | Type | Beskrivelse | Constraints |
|---------|------|-------------|-------------|
| client_id | INTEGER | Unik identifier for kunde | PRIMARY KEY |
| client_name | TEXT | Kunde navn | NOT NULL |
| sector | TEXT | Sektor: Public, Private | NOT NULL, CHECK |
| country | TEXT | Land hvor kunde er baseret | NOT NULL |

**Business Rules:**
- 25 kunder totalt
- Public sector kunder har typisk længere payment days (45 dage vs 25 dage)
- Public sector navne inkluderer typisk "Kommunen", "Region", "Styrelse", "Ministerium"

### dim_project

Beskriver projekter.

| Kolonne | Type | Beskrivelse | Constraints |
|---------|------|-------------|-------------|
| project_id | INTEGER | Unik identifier for projekt | PRIMARY KEY |
| client_id | INTEGER | Reference til kunde | FOREIGN KEY → dim_client |
| project_name | TEXT | Projekt navn | NOT NULL |
| contract_type | TEXT | Kontrakt type: T&M, Fixed | NOT NULL, CHECK |
| start_date | DATE | Projekt startdato | NOT NULL |
| end_date | DATE | Projekt slutdato | NOT NULL |
| project_manager_id | INTEGER | Reference til projekt manager | FOREIGN KEY → dim_consultant |
| budget_hours | INTEGER | Budgetterede timer | NOT NULL |
| budget_value_dkk | INTEGER | Budgetteret værdi i DKK | NOT NULL |
| planned_margin_pct | REAL | Planlagt margin procent | NOT NULL |

**Business Rules:**
- 45 projekter totalt (30-60 range)
- Projekt varighed: 30-270 dage (1-9 måneder)
- Fixed price projekter har typisk højere margin target (20-35%) end T&M (15-25%)
- Fixed price projekter har typisk strammere budget (200-1500 timer) end T&M (300-2000 timer)
- Budget value beregnes baseret på budget hours og estimeret blended rate (700-900 DKK/time)
- end_date skal være >= start_date

## Fact Tables

### fact_timesheet

Tidsregistreringer fra konsulenter.

| Kolonne | Type | Beskrivelse | Constraints |
|---------|------|-------------|-------------|
| entry_id | INTEGER | Unik identifier for entry | PRIMARY KEY |
| work_date | DATE | Arbejdsdato | NOT NULL |
| consultant_id | INTEGER | Reference til konsulent | FOREIGN KEY → dim_consultant |
| project_id | INTEGER | Reference til projekt (NULL for non-billable) | FOREIGN KEY → dim_project, NULL allowed |
| hours | REAL | Antal timer | NOT NULL, CHECK > 0 |
| billable_flag | INTEGER | Er timerne fakturerbare? (0/1) | NOT NULL, CHECK (0,1) |

**Business Rules:**
- Daglige timer på hverdage: 6-8 timer
- Weekend arbejde: Sjældent (10% sandsynlighed), typisk 0-4 timer
- Utilization varierer efter level:
  - Junior: ~70%
  - Consultant: ~80%
  - Senior: ~85%
  - Lead: ~75% (pga. management overhead)
- Non-billable timer (bench, training, internal) har project_id = NULL
- Billable timer skal have project_id != NULL

### fact_invoice

Fakturaer sendt til kunder.

| Kolonne | Type | Beskrivelse | Constraints |
|---------|------|-------------|-------------|
| invoice_id | INTEGER | Unik identifier for faktura | PRIMARY KEY |
| project_id | INTEGER | Reference til projekt | FOREIGN KEY → dim_project |
| invoice_date | DATE | Faktura dato | NOT NULL |
| amount_dkk | INTEGER | Faktura beløb i DKK | NOT NULL, CHECK > 0 |
| paid_flag | INTEGER | Er fakturaen betalt? (0/1) | NOT NULL, CHECK (0,1) |
| payment_days | INTEGER | Forventet betalingsdage | NOT NULL, CHECK >= 0 |

**Business Rules:**
- Fakturaer genereres månedligt (hver 30. dag) mens projektet er aktivt
- Payment days varierer efter kunde sektor:
  - Public: Normal distribution, mean=45, std=15
  - Private: Normal distribution, mean=25, std=10
- Faktura beløb:
  - Fixed price: Distribueret budget over fakturaer med variation ±10%
  - T&M: Baseret på estimerede månedlige timer (40-160) og rate (700-900 DKK/time)
- Payment status:
  - Hvis faktura er forfalden (days_since_invoice > payment_days): 80% sandsynlighed for betalt
  - Hvis faktura ikke er forfalden: 40% sandsynlighed for betalt

## Views

### v_utilization_daily

Daglig utilization per konsulent.

| Kolonne | Beskrivelse |
|---------|-------------|
| work_date | Arbejdsdato |
| consultant_id | Konsulent ID |
| full_name | Konsulent navn |
| level | Konsulent niveau |
| country | Land |
| billable_hours | Fakturerbare timer |
| total_hours | Samlede timer |
| utilization_pct | Utilization procent |

### v_project_financials

Finansiel status for projekter.

| Kolonne | Beskrivelse |
|---------|-------------|
| project_id | Projekt ID |
| project_name | Projekt navn |
| client_id | Kunde ID |
| client_name | Kunde navn |
| sector | Kunde sektor |
| contract_type | Kontrakt type |
| start_date | Startdato |
| end_date | Slutdato |
| budget_hours | Budgetterede timer |
| budget_value_dkk | Budgetteret værdi |
| planned_margin_pct | Planlagt margin |
| actual_hours | Faktiske timer (fra timesheets) |
| hours_overrun_pct | Overrun procent |
| budget_burn_pct | Budget burn procent |
| billable_hours | Fakturerbare timer |
| invoiced_amount | Faktureret beløb |
| invoiced_pct | Faktureret procent af budget |

### v_client_revenue

Revenue per kunde per måned.

| Kolonne | Beskrivelse |
|---------|-------------|
| client_id | Kunde ID |
| client_name | Kunde navn |
| sector | Sektor |
| country | Land |
| invoice_month | Faktura måned (YYYY-MM) |
| invoice_count | Antal fakturaer |
| total_revenue | Samlet revenue |
| paid_revenue | Betalt revenue |
| unpaid_revenue | Ubetalt revenue |
| avg_payment_days | Gennemsnitlig betalingsdage |

### v_ar_aging

Accounts Receivable aging analyse.

| Kolonne | Beskrivelse |
|---------|-------------|
| invoice_id | Faktura ID |
| project_id | Projekt ID |
| project_name | Projekt navn |
| client_id | Kunde ID |
| client_name | Kunde navn |
| sector | Sektor |
| invoice_date | Faktura dato |
| amount_dkk | Beløb |
| paid_flag | Betalt status |
| payment_days | Forventet betalingsdage |
| days_outstanding | Dage udestående |
| aging_bucket | Aging bucket (0-30, 31-60, 61-90, 90+ dage) |

## Data Generation Assumptions

### Distributions

- **Consultants**: 45 totalt, jævnt fordelt på levels og roles
- **Clients**: 25 totalt, ~50/50 Public/Private
- **Projects**: 45 totalt, ~50/50 T&M/Fixed
- **Timesheets**: Daglig grain, 18 måneder (2023-01-01 til 2024-06-30)
- **Invoices**: Månedlig frekvens per aktivt projekt

### Realistic Constraints

1. **Weekend Work**: Kun 10% sandsynlighed for weekend arbejde
2. **Utilization**: Varierer realistisk efter level
3. **Payment Behavior**: Public sector betaler langsommere end private
4. **Budget Overruns**: Fixed price projekter har højere risiko for overrun
5. **Project Overlap**: Projekter kan overlappe i tid

## Data Quality Rules

1. **Referential Integrity**: Alle foreign keys skal referere til eksisterende records
2. **Date Validity**: end_date >= start_date for alle projekter
3. **Hours Validation**: hours > 0 for alle timesheet entries
4. **Amount Validation**: amount_dkk > 0 for alle fakturaer
5. **Billable Logic**: billable_flag = 1 kun hvis project_id != NULL

## Indexes

Følgende indexes er oprettet for performance:

- `dim_consultant`: level, country, role
- `dim_client`: sector, country
- `dim_project`: client_id, contract_type, dates, project_manager_id
- `fact_timesheet`: work_date, consultant_id, project_id, billable_flag
- `fact_invoice`: invoice_date, project_id, paid_flag
