# DAX Measures for Consulting Analytics

Dette dokument indeholder alle DAX measures til Power BI dashboardet. Tilføj disse measures i **Model** view under de relevante tabeller.

## Measures i fact_timesheet tabel

### Total Billable Hours
```dax
Total Billable Hours = 
CALCULATE(
    SUM(fact_timesheet[hours]),
    fact_timesheet[billable_flag] = 1
)
```

### Total Hours
```dax
Total Hours = 
SUM(fact_timesheet[hours])
```

### Utilization %
```dax
Utilization % = 
DIVIDE(
    [Total Billable Hours],
    [Total Hours],
    0
) * 100
```

### Billable Hours (YTD)
```dax
Billable Hours YTD = 
CALCULATE(
    [Total Billable Hours],
    DATESYTD(dim_date[date])
)
```

### Average Daily Hours per Consultant
```dax
Avg Daily Hours per Consultant = 
DIVIDE(
    [Total Hours],
    DISTINCTCOUNT(fact_timesheet[consultant_id]),
    0
)
```

### Non-Billable Hours
```dax
Non-Billable Hours = 
CALCULATE(
    SUM(fact_timesheet[hours]),
    fact_timesheet[billable_flag] = 0
)
```

### Bench Rate %
```dax
Bench Rate % = 
DIVIDE(
    [Non-Billable Hours],
    [Total Hours],
    0
) * 100
```

## Measures i fact_invoice tabel

### Total Revenue
```dax
Total Revenue = 
SUM(fact_invoice[amount_dkk])
```

### Paid Revenue
```dax
Paid Revenue = 
CALCULATE(
    [Total Revenue],
    fact_invoice[paid_flag] = 1
)
```

### Unpaid Revenue (AR Outstanding)
```dax
AR Outstanding = 
CALCULATE(
    [Total Revenue],
    fact_invoice[paid_flag] = 0
)
```

### Collection Rate %
```dax
Collection Rate % = 
DIVIDE(
    [Paid Revenue],
    [Total Revenue],
    0
) * 100
```

### Revenue (YTD)
```dax
Revenue YTD = 
CALCULATE(
    [Total Revenue],
    DATESYTD(dim_date[date])
)
```

### Average Invoice Amount
```dax
Avg Invoice Amount = 
DIVIDE(
    [Total Revenue],
    COUNTROWS(fact_invoice),
    0
)
```

### Average Payment Days
```dax
Avg Payment Days = 
AVERAGE(fact_invoice[payment_days])
```

### AR Aging 0-30 Days
```dax
AR 0-30 Days = 
CALCULATE(
    [AR Outstanding],
    DATEDIFF(
        fact_invoice[invoice_date],
        TODAY(),
        DAY
    ) <= 30
)
```

### AR Aging 31-60 Days
```dax
AR 31-60 Days = 
CALCULATE(
    [AR Outstanding],
    AND(
        DATEDIFF(
            fact_invoice[invoice_date],
            TODAY(),
            DAY
        ) > 30,
        DATEDIFF(
            fact_invoice[invoice_date],
            TODAY(),
            DAY
        ) <= 60
    )
)
```

### AR Aging 61-90 Days
```dax
AR 61-90 Days = 
CALCULATE(
    [AR Outstanding],
    AND(
        DATEDIFF(
            fact_invoice[invoice_date],
            TODAY(),
            DAY
        ) > 60,
        DATEDIFF(
            fact_invoice[invoice_date],
            TODAY(),
            DAY
        ) <= 90
    )
)
```

### AR Aging 90+ Days
```dax
AR 90+ Days = 
CALCULATE(
    [AR Outstanding],
    DATEDIFF(
        fact_invoice[invoice_date],
        TODAY(),
        DAY
    ) > 90
)
```

## Measures i dim_project tabel

### Total Projects
```dax
Total Projects = 
DISTINCTCOUNT(dim_project[project_id])
```

### Active Projects
```dax
Active Projects = 
CALCULATE(
    [Total Projects],
    AND(
        dim_project[start_date] <= TODAY(),
        dim_project[end_date] >= TODAY()
    )
)
```

### Completed Projects
```dax
Completed Projects = 
CALCULATE(
    [Total Projects],
    dim_project[end_date] < TODAY()
)
```

### Total Budget Value
```dax
Total Budget Value = 
SUM(dim_project[budget_value_dkk])
```

### Total Budget Hours
```dax
Total Budget Hours = 
SUM(dim_project[budget_hours])
```

### Actual Hours (from timesheets)
```dax
Actual Hours = 
CALCULATE(
    SUM(fact_timesheet[hours]),
    fact_timesheet[billable_flag] = 1
)
```

### Budget Burn %
```dax
Budget Burn % = 
DIVIDE(
    [Actual Hours],
    [Total Budget Hours],
    0
) * 100
```

### Hours Overrun %
```dax
Hours Overrun % = 
DIVIDE(
    [Actual Hours] - [Total Budget Hours],
    [Total Budget Hours],
    0
) * 100
```

### Projects Over Budget
```dax
Projects Over Budget = 
CALCULATE(
    [Total Projects],
    [Actual Hours] > [Total Budget Hours]
)
```

### Average Planned Margin %
```dax
Avg Planned Margin % = 
AVERAGE(dim_project[planned_margin_pct]) * 100
```

### Estimated Actual Margin %
```dax
Estimated Actual Margin % = 
[Avg Planned Margin %] - 
IF(
    [Budget Burn %] > 100,
    ([Budget Burn %] - 100) * 0.5,
    0
)
```

## Measures i dim_consultant tabel

### Total Consultants
```dax
Total Consultants = 
DISTINCTCOUNT(dim_consultant[consultant_id])
```

### Consultants by Level
```dax
Consultants by Level = 
CALCULATE(
    [Total Consultants],
    VALUES(dim_consultant[level])
)
```

### Average Utilization by Level
```dax
Avg Utilization by Level = 
CALCULATE(
    [Utilization %],
    VALUES(dim_consultant[level])
)
```

### Total Consultant Cost
```dax
Total Consultant Cost = 
SUMX(
    dim_consultant,
    dim_consultant[cost_rate_dkk_per_hour] * 
    CALCULATE([Total Hours])
)
```

### Revenue per Consultant
```dax
Revenue per Consultant = 
DIVIDE(
    [Total Revenue],
    [Total Consultants],
    0
)
```

## Measures i dim_client tabel

### Total Clients
```dax
Total Clients = 
DISTINCTCOUNT(dim_client[client_id])
```

### Revenue by Sector
```dax
Revenue by Sector = 
CALCULATE(
    [Total Revenue],
    VALUES(dim_client[sector])
)
```

### Top Client Revenue %
```dax
Top Client Revenue % = 
VAR Top5Revenue = 
    CALCULATE(
        [Total Revenue],
        TOPN(
            5,
            ALL(dim_client[client_id]),
            [Total Revenue],
            DESC
        )
    )
RETURN
    DIVIDE(
        Top5Revenue,
        [Total Revenue],
        0
    ) * 100
```

## Time Intelligence Measures

*Note: Disse kræver en dim_date tabel. Opret en date table hvis den ikke findes.*

### Previous Month Revenue
```dax
Revenue Previous Month = 
CALCULATE(
    [Total Revenue],
    PREVIOUSMONTH(dim_date[date])
)
```

### Month-over-Month Revenue Growth %
```dax
Revenue MoM Growth % = 
VAR CurrentMonth = [Total Revenue]
VAR PreviousMonth = [Revenue Previous Month]
RETURN
    DIVIDE(
        CurrentMonth - PreviousMonth,
        PreviousMonth,
        0
    ) * 100
```

### Year-over-Year Revenue Growth %
```dax
Revenue YoY Growth % = 
VAR CurrentYear = [Revenue YTD]
VAR PreviousYear = 
    CALCULATE(
        [Revenue YTD],
        SAMEPERIODLASTYEAR(dim_date[date])
    )
RETURN
    DIVIDE(
        CurrentYear - PreviousYear,
        PreviousYear,
        0
    ) * 100
```

## Composite Measures (At-Risk Projects)

### At-Risk Projects Count
```dax
At-Risk Projects = 
CALCULATE(
    [Total Projects],
    OR(
        [Hours Overrun %] > 10,
        [AR Outstanding] > 50000
    )
)
```

### High-Risk Projects
```dax
High-Risk Projects = 
CALCULATE(
    [Total Projects],
    AND(
        [Hours Overrun %] > 10,
        [AR Outstanding] > 0
    )
)
```

## Tips til Brug

1. **Tilføj measures til relevante tabeller**: Placer measures i den tabel hvor de logisk hører hjemme
2. **Brug formatering**: Formatér procent measures som %, tal som currency eller number med decimaler
3. **Test measures**: Verificer at measures returnerer korrekte værdier mod SQL queries
4. **Performance**: Brug CALCULATE sparsomt og overvej calculated columns for simple beregninger
5. **Documentation**: Tilføj beskrivelser til measures i Power BI (right-click > Properties)

## Yderligere Ressourcer

- [DAX Guide](https://dax.guide/)
- [SQLBI DAX Patterns](https://www.daxpatterns.com/)
