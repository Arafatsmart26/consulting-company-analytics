# Consulting Analytics – Synligt dashboard

Grønt/hvidt dashboard med **Penge Vulkan**, KPI-kort, månedlig utilization, finansiel tabel og risk overview.

## Hurtig start (uden Node/npm)

1. Åbn `index.html` direkte i browseren (dobbeltklik eller **File → Open**).
2. Eller start en lokal server i `dashboard`-mappen og åbn fx `http://localhost:3000`:
   ```bash
   npx serve . -p 3000
   ```
   (Første gang hentes `serve` automatisk.)

## Med Node.js (valgfrit)

For at bygge Tailwind lokalt og køre med `npm run start`:

```bash
cd dashboard
npm install
npm run build   # genererer dist/output.css
npm run start   # bygger og starter server på port 3000
```

## Indhold

- **Penge Vulkan** – illustration øverst til venstre
- **Executive KPIs** – Utilization, Bench Rate, Revenue, Overrun, Margin
- **Monthly Utilization Overview** – søjler + trendlinje (grønt tema)
- **Risk Overview** – antal at-risk projekter + fordeling Fixed Fee / Time & Mat
- **Financial Overview** – tabel efter Billing Type og Country

Data er mock. Senere kan du forbinde til `analytics.db` via et lille API og udskifte mock med live data.
