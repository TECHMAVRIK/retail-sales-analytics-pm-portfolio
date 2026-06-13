-- ============================================================
--  FILE 4: BRANCH PERFORMANCE ANALYSIS
--  Project : Retail Sales Performance & Inventory Optimization
--  Author  : TECHMAVRIK
--  Tool    : MySQL 8.0
--  Highlights: Window functions, CTEs, advanced ranking
-- ============================================================

USE retail_analytics;

-- ── QUERY 1: Full branch scorecard ──────────────────────────

SELECT
    branch_name,
    region,
    COUNT(DISTINCT order_id)                                  AS total_orders,
    SUM(quantity_sold)                                        AS units_sold,
    ROUND(SUM(quantity_sold * unit_price), 2)                 AS gross_revenue,
    ROUND(SUM(quantity_sold * (unit_price - cost_price)), 2)  AS gross_profit,
    ROUND(
        SUM(quantity_sold * (unit_price - cost_price)) * 100.0
        / NULLIF(SUM(quantity_sold * unit_price), 0)
    , 2)                                                      AS margin_pct,
    ROUND(SUM(quantity_sold * unit_price) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value
FROM sales
GROUP BY branch_name, region
ORDER BY gross_revenue DESC;

-- ── QUERY 2: Branch revenue vs regional average ─────────────

WITH branch_rev AS (
    SELECT
        branch_name,
        region,
        ROUND(SUM(quantity_sold * unit_price), 2) AS branch_revenue
    FROM sales
    GROUP BY branch_name, region
),
region_avg AS (
    SELECT
        region,
        ROUND(AVG(branch_revenue), 2) AS avg_regional_revenue
    FROM branch_rev
    GROUP BY region
)
SELECT
    b.branch_name,
    b.region,
    b.branch_revenue,
    r.avg_regional_revenue,
    ROUND(b.branch_revenue - r.avg_regional_revenue, 2) AS vs_regional_avg,
    CASE
        WHEN b.branch_revenue >= r.avg_regional_revenue THEN '✅ Above Average'
        ELSE '❌ Below Average'
    END AS performance_flag
FROM branch_rev b
JOIN region_avg r ON b.region = r.region
ORDER BY b.region, b.branch_revenue DESC;

-- ── QUERY 3: Month-over-Month growth per branch ─────────────

WITH monthly AS (
    SELECT
        branch_name,
        DATE_FORMAT(order_date, '%Y-%m')          AS month,
        ROUND(SUM(quantity_sold * unit_price), 2) AS revenue
    FROM sales
    GROUP BY branch_name, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    branch_name,
    month,
    revenue,
    LAG(revenue) OVER (PARTITION BY branch_name ORDER BY month) AS prev_month,
    ROUND(
        (revenue - LAG(revenue) OVER (PARTITION BY branch_name ORDER BY month)) * 100.0
        / NULLIF(LAG(revenue) OVER (PARTITION BY branch_name ORDER BY month), 0)
    , 2) AS mom_growth_pct
FROM monthly
ORDER BY branch_name, month;

-- ── QUERY 4: Running cumulative revenue per branch ──────────

WITH monthly AS (
    SELECT
        branch_name,
        DATE_FORMAT(order_date, '%Y-%m')          AS month,
        ROUND(SUM(quantity_sold * unit_price), 2) AS monthly_revenue
    FROM sales
    GROUP BY branch_name, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    branch_name,
    month,
    monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (
        PARTITION BY branch_name
        ORDER BY month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2) AS cumulative_revenue
FROM monthly
ORDER BY branch_name, month;

-- ── QUERY 5: Top performing category per branch ─────────────

WITH category_revenue AS (
    SELECT
        branch_name,
        category,
        ROUND(SUM(quantity_sold * unit_price), 2) AS revenue,
        RANK() OVER (
            PARTITION BY branch_name
            ORDER BY SUM(quantity_sold * unit_price) DESC
        ) AS category_rank
    FROM sales
    GROUP BY branch_name, category
)
SELECT
    branch_name,
    category AS top_category,
    revenue  AS top_category_revenue
FROM category_revenue
WHERE category_rank = 1
ORDER BY revenue DESC;

-- ── QUERY 6: Identify consistently declining branches ────────
-- Branches with 3+ consecutive months of negative MoM growth

WITH monthly AS (
    SELECT
        branch_name,
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(quantity_sold * unit_price)  AS revenue
    FROM sales
    GROUP BY branch_name, DATE_FORMAT(order_date, '%Y-%m')
),
growth AS (
    SELECT
        branch_name,
        month,
        revenue,
        LAG(revenue) OVER (PARTITION BY branch_name ORDER BY month) AS prev_rev,
        CASE
            WHEN revenue < LAG(revenue) OVER (PARTITION BY branch_name ORDER BY month)
            THEN 1 ELSE 0
        END AS is_decline
    FROM monthly
)
SELECT
    branch_name,
    COUNT(*) AS decline_months,
    ROUND(AVG(revenue), 2) AS avg_revenue_in_decline_period
FROM growth
WHERE is_decline = 1
GROUP BY branch_name
HAVING decline_months >= 3
ORDER BY decline_months DESC;

-- ── QUERY 7: Best & worst single month per branch ───────────

WITH monthly AS (
    SELECT
        branch_name,
        DATE_FORMAT(order_date, '%Y-%m')          AS month,
        ROUND(SUM(quantity_sold * unit_price), 2) AS revenue
    FROM sales
    GROUP BY branch_name, DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    branch_name,
    MAX(revenue) AS best_month_revenue,
    MIN(revenue) AS worst_month_revenue,
    ROUND(MAX(revenue) - MIN(revenue), 2) AS revenue_volatility
FROM monthly
GROUP BY branch_name
ORDER BY revenue_volatility DESC;

-- ── QUERY 8: Final Executive Summary View ───────────────────

WITH summary AS (
    SELECT
        branch_name,
        region,
        ROUND(SUM(quantity_sold * unit_price), 2)               AS revenue,
        ROUND(SUM(quantity_sold * (unit_price - cost_price)) * 100.0
            / NULLIF(SUM(quantity_sold * unit_price), 0), 2)     AS margin_pct,
        COUNT(CASE WHEN stock_available = 0 THEN 1 END)          AS stockout_events
    FROM sales
    GROUP BY branch_name, region
)
SELECT
    branch_name,
    region,
    revenue,
    margin_pct,
    stockout_events,
    RANK() OVER (ORDER BY revenue DESC)     AS revenue_rank,
    RANK() OVER (ORDER BY margin_pct DESC)  AS margin_rank,
    RANK() OVER (ORDER BY stockout_events)  AS stockout_rank
FROM summary
ORDER BY revenue_rank;
