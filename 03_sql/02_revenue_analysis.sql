-- ============================================================
--  FILE 2: REVENUE ANALYSIS
--  Project : Retail Sales Performance & Inventory Optimization
--  Author  : TECHMAVRIK
--  Tool    : MySQL 8.0
-- ============================================================

USE retail_analytics;

-- ── QUERY 1: Total revenue, cost & gross margin by branch ───

SELECT
    branch_name,
    region,
    ROUND(SUM(quantity_sold * unit_price), 2)               AS gross_revenue,
    ROUND(SUM(quantity_sold * cost_price), 2)               AS total_cost,
    ROUND(SUM(quantity_sold * (unit_price - cost_price)), 2) AS gross_profit,
    ROUND(
        SUM(quantity_sold * (unit_price - cost_price)) * 100.0
        / NULLIF(SUM(quantity_sold * unit_price), 0)
    , 2)                                                     AS gross_margin_pct
FROM sales
GROUP BY branch_name, region
ORDER BY gross_revenue DESC;

-- ── QUERY 2: Revenue by category & region (cross-tab) ───────

SELECT
    category,
    ROUND(SUM(CASE WHEN region = 'North' THEN quantity_sold * unit_price ELSE 0 END), 2) AS North,
    ROUND(SUM(CASE WHEN region = 'South' THEN quantity_sold * unit_price ELSE 0 END), 2) AS South,
    ROUND(SUM(CASE WHEN region = 'East'  THEN quantity_sold * unit_price ELSE 0 END), 2) AS East,
    ROUND(SUM(CASE WHEN region = 'West'  THEN quantity_sold * unit_price ELSE 0 END), 2) AS West,
    ROUND(SUM(quantity_sold * unit_price), 2)                                             AS total_revenue
FROM sales
GROUP BY category
ORDER BY total_revenue DESC;

-- ── QUERY 3: Month-over-Month revenue growth (Window fn) ────

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m')          AS month,
        ROUND(SUM(quantity_sold * unit_price), 2) AS revenue
    FROM sales
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month)  AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)
    , 2)                                AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;

-- ── QUERY 4: Top 10 revenue-generating SKUs ─────────────────

SELECT
    sku_id,
    product_name,
    category,
    SUM(quantity_sold)                          AS total_units,
    ROUND(SUM(quantity_sold * unit_price), 2)   AS total_revenue,
    ROUND(SUM(quantity_sold * (unit_price - cost_price)), 2) AS total_profit,
    RANK() OVER (ORDER BY SUM(quantity_sold * unit_price) DESC) AS revenue_rank
FROM sales
GROUP BY sku_id, product_name, category
ORDER BY revenue_rank
LIMIT 10;

-- ── QUERY 5: Bottom 10 SKUs (revenue leakage candidates) ────

SELECT
    sku_id,
    product_name,
    category,
    SUM(quantity_sold)                          AS total_units,
    ROUND(SUM(quantity_sold * unit_price), 2)   AS total_revenue,
    AVG(stock_available)                        AS avg_stock_held,
    ROUND(
        AVG(stock_available) * AVG(cost_price), 2
    )                                           AS estimated_capital_locked
FROM sales
GROUP BY sku_id, product_name, category
HAVING total_units < 20
ORDER BY estimated_capital_locked DESC
LIMIT 10;

-- ── QUERY 6: Revenue split — Retail vs Wholesale ────────────

SELECT
    customer_type,
    COUNT(DISTINCT order_id)                    AS total_orders,
    ROUND(SUM(quantity_sold * unit_price), 2)   AS revenue,
    ROUND(AVG(quantity_sold * unit_price), 2)   AS avg_order_value
FROM sales
GROUP BY customer_type;

-- ── QUERY 7: Quarterly revenue trend by year ────────────────

SELECT
    YEAR(order_date)    AS year,
    QUARTER(order_date) AS quarter,
    ROUND(SUM(quantity_sold * unit_price), 2) AS revenue,
    ROUND(SUM(quantity_sold * (unit_price - cost_price)), 2) AS profit
FROM sales
GROUP BY YEAR(order_date), QUARTER(order_date)
ORDER BY year, quarter;

-- ── QUERY 8: Branch revenue ranking within each region ──────

SELECT
    region,
    branch_name,
    ROUND(SUM(quantity_sold * unit_price), 2) AS revenue,
    RANK() OVER (
        PARTITION BY region
        ORDER BY SUM(quantity_sold * unit_price) DESC
    ) AS rank_in_region
FROM sales
GROUP BY region, branch_name
ORDER BY region, rank_in_region;
