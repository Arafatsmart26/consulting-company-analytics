# Power BI Dashboard Wireframe

Dette dokument beskriver layoutet og indholdet af hver dashboard side.

## Page 1: Executive Summary

**Formål**: Høj-niveau KPI overview for ledelsen

### Layout (Grid: 4 kolonner x 3 rækker)

**Række 1 - KPI Cards:**
- [Card] Total Revenue (med YoY % change)
- [Card] Utilization % (med target indicator)
- [Card] Active Projects
- [Card] AR Outstanding

**Række 2 - Trends:**
- [Line Chart] Revenue Trend (Last 18 months)
  - X-axis: Month
  - Y-axis: Revenue (DKK)
  - Series: Total Revenue, Paid Revenue
  - Slicer: Date Range

- [Line Chart] Utilization Trend (Last 18 months)
  - X-axis: Month
  - Y-axis: Utilization %
  - Reference line: 75% target
  - Slicer: Consultant Level, Country

**Række 3 - Tables:**
- [Table] Top 10 Clients by Revenue
  - Columns: Client Name, Sector, Total Revenue, Paid Revenue, Invoice Count
  - Slicer: Sector

- [Card/Matrix] Quick Stats
  - Projects Over Budget: [Count]
  - Average Payment Days: [Days]
  - Collection Rate: [%]

**Slicers (Sidebar):**
- Date Range (work_date, invoice_date)
- Sector
- Country

---

## Page 2: Utilization Analysis

**Formål**: Detaljeret analyse af consultant utilization og performance

### Layout

**Top Section - Overview:**
- [Card] Overall Utilization %
- [Card] Total Billable Hours
- [Card] Total Hours
- [Card] Bench Rate %

**Middle Section - Breakdowns:**
- [Clustered Bar Chart] Utilization by Level
  - X-axis: Level (Junior, Consultant, Senior, Lead)
  - Y-axis: Utilization %
  - Color: By level

- [Clustered Bar Chart] Utilization by Role
  - X-axis: Role (Engineer, Analyst, PM)
  - Y-axis: Utilization %
  - Color: By role

- [Clustered Bar Chart] Utilization by Country
  - X-axis: Country
  - Y-axis: Utilization %
  - Color: By country

**Bottom Section - Trends & Details:**
- [Line Chart] Monthly Utilization Trend
  - X-axis: Month
  - Y-axis: Utilization %
  - Series: By Level (4 lines)
  - Legend: Level

- [Matrix] Consultant Performance Matrix
  - Rows: Consultant Name
  - Columns: Utilization %, Billable Hours, Total Hours, Project Count
  - Conditional formatting: Utilization % (traffic light)

- [Area Chart] Bench Trend (Non-billable hours)
  - X-axis: Month
  - Y-axis: Non-billable Hours
  - Stacked by: Reason (Internal, Training, Bench)

**Slicers:**
- Date Range
- Level
- Role
- Country
- Consultant (multi-select)

---

## Page 3: Project Health

**Formål**: Overvågning af projekt status, budget overruns, og risici

### Layout

**Top Section - KPI Cards:**
- [Card] Total Projects
- [Card] Active Projects
- [Card] Projects Over Budget
- [Card] At-Risk Projects

**Middle Section - Budget Analysis:**
- [Clustered Column Chart] Projects Over Budget by Contract Type
  - X-axis: Contract Type (T&M, Fixed)
  - Y-axis: Count of Projects
  - Color: Over Budget (Yes/No)

- [Scatter Chart] Budget Burn vs Overrun %
  - X-axis: Budget Burn %
  - Y-axis: Hours Overrun %
  - Size: Budget Value
  - Color: Contract Type
  - Reference lines: 100% burn, 0% overrun

- [Bar Chart] Top 10 Projects by Overrun %
  - X-axis: Project Name
  - Y-axis: Hours Overrun %
  - Color: Risk Level (High/Medium/Low)

**Bottom Section - Details:**
- [Table] At-Risk Projects Detail
  - Columns: Project Name, Client, Contract Type, Budget Hours, Actual Hours, Overrun %, Unpaid AR, Risk Level
  - Filter: Risk Level
  - Conditional formatting: Risk Level

- [Line Chart] Budget Burn Trend
  - X-axis: Month
  - Y-axis: Average Budget Burn %
  - Series: By Contract Type

**Slicers:**
- Project Status (Active/Completed/Upcoming)
- Contract Type
- Client Sector
- Date Range

---

## Page 4: Financial Analysis

**Formål**: Revenue, payment behavior, og AR management

### Layout

**Top Section - Revenue KPIs:**
- [Card] Total Revenue
- [Card] Paid Revenue
- [Card] AR Outstanding
- [Card] Collection Rate %

**Middle Section - Revenue Analysis:**
- [Line Chart] Revenue Trend by Sector
  - X-axis: Month
  - Y-axis: Revenue (DKK)
  - Series: Public, Private
  - Legend: Sector

- [Clustered Bar Chart] Revenue by Sector and Month
  - X-axis: Month
  - Y-axis: Revenue
  - Legend: Sector
  - Stacked: Yes

- [Pie Chart] Revenue Distribution by Sector
  - Values: Revenue by Sector
  - Labels: Sector

**Bottom Section - Payment & AR:**
- [Clustered Column Chart] Payment Days by Sector
  - X-axis: Sector
  - Y-axis: Average Payment Days
  - Color: Sector

- [Stacked Bar Chart] AR Aging Buckets
  - X-axis: Aging Bucket (0-30, 31-60, 61-90, 90+)
  - Y-axis: Amount (DKK)
  - Color: By bucket

- [Table] Invoice Payment Status
  - Columns: Invoice ID, Client, Invoice Date, Amount, Payment Days, Paid Status, Days Outstanding
  - Filter: Paid Status, Sector

- [Waterfall Chart] Revenue Recognition vs Cash Collection
  - Categories: Revenue Recognized, Cash Collected, Outstanding AR
  - Values: Amount (DKK)

**Slicers:**
- Date Range
- Sector
- Client
- Payment Status

---

## Page 5: Client Insights

**Formål**: Client performance, concentration, og relationship management

### Layout

**Top Section - Client KPIs:**
- [Card] Total Clients
- [Card] Top 5 Client Concentration %
- [Card] Average Revenue per Client
- [Card] Clients with Outstanding AR

**Middle Section - Client Performance:**
- [Bar Chart] Top 10 Clients by Revenue
  - X-axis: Client Name
  - Y-axis: Total Revenue
  - Color: Sector

- [Treemap] Revenue by Client
  - Size: Revenue
  - Color: Sector
  - Labels: Client Name

- [Clustered Bar Chart] Revenue by Sector
  - X-axis: Sector
  - Y-axis: Revenue
  - Breakdown: By Country (optional)

**Bottom Section - Payment Performance:**
- [Table] Client Payment Performance
  - Columns: Client Name, Sector, Total Revenue, Paid Revenue, Unpaid Revenue, Avg Payment Days, Collection Rate %
  - Sort: By Unpaid Revenue (descending)
  - Conditional formatting: Collection Rate %

- [Scatter Chart] Revenue vs Payment Days
  - X-axis: Total Revenue
  - Y-axis: Average Payment Days
  - Size: Invoice Count
  - Color: Sector

- [Line Chart] Client Revenue Trend (Top 5)
  - X-axis: Month
  - Y-axis: Revenue
  - Series: Top 5 Clients
  - Legend: Client Name

**Slicers:**
- Sector
- Country
- Client (multi-select)
- Date Range

---

## Cross-Page Elements

### Navigation
- Navigation pane med links til alle sider
- Breadcrumb navigation
- Page titles med ikoner

### Consistent Slicers (Sidebar)
Alle sider bør have:
- Date Range slicer (standard på alle sider)
- Sector slicer (hvor relevant)
- Country slicer (hvor relevant)

### Formatting Standards
- **Colors**: 
  - Primary: #0078D4 (Microsoft Blue)
  - Success: #107C10 (Green)
  - Warning: #FFB900 (Yellow)
  - Danger: #E81123 (Red)
- **Fonts**: Segoe UI (standard)
- **Card backgrounds**: White med subtle shadow
- **Chart backgrounds**: Light gray (#F2F2F2)

### Tooltips
Tilføj tooltips til alle visuals med:
- Definition af metric
- Beregningsmetode
- Data source
- Last updated timestamp

---

## Responsive Design Notes

- Dashboard skal fungere på både desktop og tablet
- Overvej at gruppere visuals i containers for nemmere layout
- Brug responsive visuals hvor muligt
- Test på forskellige skærmstørrelser

---

## Interactivity Features

1. **Cross-filtering**: Alle visuals skal reagere på slicer selections
2. **Drill-through**: Tilføj drill-through pages for detaljeret data
3. **Tooltips**: Rich tooltips med yderligere kontekst
4. **Bookmarks**: Opret bookmarks for specifikke views/scenarios
5. **Buttons**: Navigation buttons mellem relaterede sider

---

## Data Refresh

- Indikér "Last refreshed" timestamp på hver side
- Overvej at tilføje refresh button (hvis data opdateres manuelt)
- Schedule automatic refresh hvis muligt
