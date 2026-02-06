# Power BI Build Guide

Denne guide forklarer hvordan du bygger et Power BI dashboard baseret på consulting company analytics databasen.

## Forudsætninger

- Power BI Desktop (gratis download fra Microsoft)
- Analytics database (`analytics.db`) eller CSV filer fra `data/raw/`
- Grundlæggende kendskab til Power BI

## 1. Data Import

### Metode A: Import fra SQLite (Anbefalet)

Power BI understøtter ikke direkte SQLite import. Brug en af følgende metoder:

#### Option 1: Via Python Script
1. Åbn Power BI Desktop
2. Gå til **Transform Data** > **Get Data** > **More...**
3. Vælg **Python script**
4. Indsæt følgende script:

```python
import sqlite3
import pandas as pd

conn = sqlite3.connect(r'C:\path\to\analytics.db')

# Load tables
consultants = pd.read_sql_query("SELECT * FROM dim_consultant", conn)
clients = pd.read_sql_query("SELECT * FROM dim_client", conn)
projects = pd.read_sql_query("SELECT * FROM dim_project", conn)
timesheets = pd.read_sql_query("SELECT * FROM fact_timesheet", conn)
invoices = pd.read_sql_query("SELECT * FROM fact_invoice", conn)

conn.close()
```

5. Power BI vil automatisk detektere tabellerne
6. Klik **Transform Data** for at justere datatyper

#### Option 2: Eksporter til CSV først
1. Brug Python script til at eksportere alle tabeller til CSV
2. Import CSV filer via **Get Data** > **Text/CSV**

### Metode B: Import fra CSV filer

1. Gå til **Get Data** > **Text/CSV**
2. Vælg alle CSV filer fra `data/raw/` mappen
3. For hver fil:
   - Bekræft datatyper (datoer, tal, tekst)
   - Omdøb tabellen hvis nødvendigt
   - Klik **Close & Apply**

## 2. Data Model Setup

### Opret Relationer

Gå til **Model** view og opret følgende relationer (star schema):

1. **dim_consultant** (1) → **fact_timesheet** (many)
   - `consultant_id` → `consultant_id`
   - Cardinality: One-to-Many
   - Cross filter direction: Both

2. **dim_project** (1) → **fact_timesheet** (many)
   - `project_id` → `project_id`
   - Cardinality: One-to-Many (allow nulls for non-billable)
   - Cross filter direction: Both

3. **dim_project** (1) → **fact_invoice** (many)
   - `project_id` → `project_id`
   - Cardinality: One-to-Many
   - Cross filter direction: Both

4. **dim_client** (1) → **dim_project** (many)
   - `client_id` → `client_id`
   - Cardinality: One-to-Many
   - Cross filter direction: Both

5. **dim_consultant** (1) → **dim_project** (many) [PM relation]
   - `consultant_id` → `project_manager_id`
   - Cardinality: One-to-Many
   - Cross filter direction: Both

### Datatyper

Tjek at følgende kolonner har korrekt datatype:

- **Datoer**: `work_date`, `start_date`, `end_date`, `invoice_date`, `hire_date`
- **Tal**: `hours`, `amount_dkk`, `cost_rate_dkk_per_hour`, `budget_hours`, `budget_value_dkk`
- **Boolean**: `billable_flag`, `paid_flag` (skal være Whole Number 0/1)

### Beregnede Kolonner (Hvis nødvendigt)

Opret beregnede kolonner for:

- `dim_project[Duration Days]` = DATEDIFF(dim_project[start_date], dim_project[end_date], DAY)
- `fact_timesheet[Is Weekend]` = WEEKDAY(fact_timesheet[work_date]) >= 5

## 3. DAX Measures

Se `dax_measures.md` for komplet liste af DAX measures. Tilføj dem i **Model** view under hver tabel.

Vigtigste measures at tilføje først:

1. **Total Billable Hours**
2. **Total Hours**
3. **Utilization %**
4. **Total Revenue**
5. **Paid Revenue**
6. **AR Outstanding**

## 4. Dashboard Pages

Se `dashboard_wireframe.md` for detaljeret wireframe. Opret følgende sider:

### Page 1: Executive Summary
- KPI cards (Revenue, Utilization, Projects, AR)
- Revenue trend chart
- Utilization trend chart
- Top clients table

### Page 2: Utilization Analysis
- Utilization by level/role/country
- Monthly utilization trend
- Consultant performance matrix
- Bench hours analysis

### Page 3: Project Health
- Projects over budget
- Budget burn rate
- At-risk projects table
- Contract type comparison

### Page 4: Financial Analysis
- Revenue by sector/month
- Payment behavior (Public vs Private)
- AR aging buckets
- Invoice status

### Page 5: Client Insights
- Top clients by revenue
- Client concentration
- Sector analysis
- Payment performance by client

## 5. Visualiseringer

### Anbefalede Visual Types

- **KPI Cards**: Card visual
- **Trends**: Line chart eller Area chart
- **Distributions**: Bar chart, Column chart
- **Comparisons**: Clustered bar/column
- **Tables**: Matrix eller Table visual
- **Hierarchies**: Treemap, Sunburst

### Slicers

Tilføj slicers for:
- Date range (work_date, invoice_date)
- Consultant level
- Role
- Country
- Client sector
- Contract type
- Project status (Active/Completed)

## 6. Formatting og Design

### Farvetema
- Brug konsistent farvepalette
- Brug conditional formatting for at-risk indikatorer
- Rød/Gul/Grøn for status indikatorer

### Layout
- Brug grid layout for konsistent spacing
- Gruppér relaterede visuals sammen
- Tilføj titler og beskrivelser

## 7. Performance Optimization

1. **Remove unused columns**: Fjern kolonner der ikke bruges
2. **Aggregate data**: Brug calculated tables for store aggregations
3. **Limit date ranges**: Brug date filters i slicers
4. **Disable auto date/time**: Slå auto date/time tables fra i Options

## 8. Testing

Test dashboardet ved at:

1. Vælg forskellige slicer kombinationer
2. Verificer at measures beregner korrekt
3. Tjek at relationer fungerer korrekt
4. Valider mod SQL queries fra `sql/analysis_queries.sql`

## 9. Deployment

Når dashboardet er klar:

1. **Save** som `.pbix` fil
2. **Publish** til Power BI Service (hvis du har licens)
3. Opdater data source connection hvis nødvendigt
4. Schedule refresh hvis data opdateres regelmæssigt

## Troubleshooting

### Problem: Measures returnerer fejl
- Tjek at relationer er korrekt oprettet
- Verificer datatyper
- Tjek for null værdier

### Problem: Visuals viser ikke data
- Tjek slicer filters
- Verificer at measures er korrekt defineret
- Tjek cross-filter direction i relationer

### Problem: Performance er langsom
- Reducer antal rows i visuals
- Brug aggregations i stedet for detail data
- Overvej at oprette calculated tables

## Yderligere Ressourcer

- [Power BI Documentation](https://docs.microsoft.com/power-bi/)
- [DAX Guide](https://dax.guide/)
- [SQLBI Resources](https://www.sqlbi.com/)
