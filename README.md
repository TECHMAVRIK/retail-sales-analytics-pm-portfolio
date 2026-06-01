# 🛒 Retail Sales Performance & Inventory Optimization

> **An end-to-end analytics project** simulating a real-world retail chain scenario — from messy raw data to an executive-ready dashboard — built to demonstrate PM + data skills across Excel, SQL, Tableau, and Power BI.
 Problem Statement

A mid-size retail chain operating **12 branches across 4 regions** had no centralized view of:
- Which branches and product categories were underperforming
- How much revenue was being lost due to stockouts and slow-moving inventory
- How long weekly reporting was taking (manual Excel sheets, 3+ hrs/week)

## Project Objective

| Goal | Outcome |

| Identify revenue leakage | ₹1.8 Cr surfaced across slow-moving SKUs |
| Reduce stockout risk | 18% reduction opportunity flagged across 3 branches |
| Automate weekly reporting | 3 hrs/week saved via Power BI scheduled refresh |
| Enable branch-level decisions | 12-branch comparison dashboard delivered |

## 🛠️ Tech Stack

| Tool | Version / Type | What I Used It For |
|------|---------------|-------------------|
| **Microsoft Excel** | Advanced | Power Query, VLOOKUP, Pivot Tables, What-If Analysis, Dynamic Financial Model |
| **SQL** | MySQL 8.0 | Data exploration, CTEs, Window Functions, Subqueries, JOIN analysis |
| **Tableau** | Tableau Public | Story-based dashboard, heat maps, drill-down branch comparison |
| **Power BI** | Desktop + Service | DAX measures, KPI cards, Row-Level Security, scheduled refresh |

## 🔍 Phase-by-Phase Approach

### Phase 1 — Data Cleaning & Modeling (Excel)
- Imported raw CSV using **Power Query** — removed duplicates, handled nulls, standardized date formats
- Built a **dynamic pivot model** with slicers for region, category, and time period
- Created a **What-If scenario model** to simulate impact of 10% price increase on top 20 SKUs
- Key finding: 23% of rows had missing `cost_price` — imputed using category-level averages

### Phase 2 — Deep-Dive Analysis (SQL)
- Wrote **CTEs** to segment customers by purchase frequency (RFM-lite approach)
- Used **window functions** (`RANK()`, `LAG()`, `LEAD()`) to identify MoM revenue decline by branch
- Identified **top 10 slow-moving SKUs** (high stock, low sales velocity) contributing to ₹1.8Cr leakage
- Flagged 3 branches with recurring stockouts using a **stock-to-sales ratio query**

### Phase 3 — Visual Exploration (Tableau)
- Built a **3-screen story dashboard**: Overview → Branch Drill-Down → Inventory Risk
- **Heat map** showing revenue per branch by month — revealed clear seasonal dip in Q3
- **Scatter plot** of stock levels vs. sales velocity to identify slow-movers visually
- Published to Tableau Public — [View Dashboard →](#)

### Phase 4 — Executive Reporting (Power BI)
- Connected Power BI directly to SQL database via DirectQuery
- Built **DAX measures** for: Gross Margin %, MoM Growth, Inventory Turnover Ratio
- Implemented **Row-Level Security** so each branch manager sees only their own data
- Set up **scheduled refresh** (daily) — eliminated manual Monday morning reports

---

## 📈 Key Findings & Recommendations

### Finding 1 — ₹1.8 Cr revenue leakage
> 14 SKUs across 3 categories had >90 days of stock with near-zero sales velocity.
**Recommendation:** Run clearance pricing on these SKUs; adjust reorder policy for next season.

### Finding 2 — Branch North-07 underperforming by 34%
> Despite similar footfall, North-07 had the lowest conversion rate among all branches.
**Recommendation:** Review store layout and staff training; benchmark against top-performing Branch South-02.

### Finding 3 — Q3 seasonal dip predictable but unplanned
> MoM analysis showed a consistent 22% revenue drop every July–August across 4 years.
**Recommendation:** Pre-plan promotional campaigns for Q3; increase stock of seasonal items in Q2.

### Finding 4 — 18% stockout reduction possible
> 3 high-volume branches ran out of top-10 SKUs an average of 11 days/month.
**Recommendation:** Lower reorder threshold for fast-moving SKUs; implement real-time stock alert in Power BI dashboard.

---

 Key Learnings

- **Power Query vs. raw Excel formulas:** Power Query is significantly faster for 50K+ row datasets — reduced cleaning time from ~4 hrs to 40 mins
- **DirectQuery vs. Import in Power BI:** Used Import mode for this project; DirectQuery would be needed for real-time scenarios
- **Tableau Public limitation:** Cannot implement Row-Level Security on Tableau Public — used Power BI for the secure executive layer
- **SQL window functions are essential:** `LAG()` and `LEAD()` made MoM trend analysis trivial compared to doing it in Excel

---
 Future Scope

- [ ] Integrate Python (pandas) for automated data cleaning pipeline
- [ ] Add forecasting using Power BI's built-in AI visuals
- [ ] Build a real-time stock alert system using Power Automate
- [ ] Expand dataset to include customer demographics for segmentation analysis


