-- ============================================================
--  FILE 3: INVENTORY ANALYSIS
--  Project : Retail Sales Performance & Inventory Optimization
--  Author  : TECHMAVRIK
--  Tool    : MySQL 8.0
-- ============================================================

USE retail_analytics;

-- ── QUERY 1: Stock-to-Sales ratio per SKU ───────────────────
-- High ratio = slow mover (capital locked), Low ratio = stockout risk

SELECT
    sku_id,
    product_name,
    category,
    ROUND(AVG(stock_available), 0)              AS avg_stock,
    SUM(quantity_sold)                          AS total_sold,
    ROUND(AVG(stock_available) / NULLIF(SUM(quantity_sold), 0), 2) AS stock_to_sales_ratio,
    CASE
        WHEN AVG(stock_available) / NULLIF(SUM(quantity_sold), 0) > 5
            THEN '🔴 Slow Mover — Overstocked'
        WHEN AVG(stock_available) / NULLIF(SUM(quantity_sold), 0) < 0.5
            THEN '🟡 Stockout Risk — Reorder Now'
        ELSE '🟢 Healthy'
    END AS inventory_status
FROM sales
GROUP BY sku_id, product_name, category
ORDER BY stock_to_sales_ratio DESC;

-- ── QUERY 2: Top 15 slow-moving SKUs (revenue leakage) ──────

WITH sku_metrics AS (
    SELECT
        sku_id,
        product_name,
        category,
        SUM(quantity_sold)                        AS total_units_sold,
        ROUND(AVG(stock_available), 0)            AS avg_stock,
        ROUND(AVG(cost_price), 2)                 AS avg_cost_price,
        ROUND(AVG(stock_available) * AVG(cost_price), 2) AS capital_locked
    FROM sales
    GROUP BY sku_id, product_name, category
)
SELECT
    sku_id,
    product_name,
    category,
    total_units_sold,
    avg_stock,
    avg_cost_price,
    capital_locked,
    RANK() OVER (ORDER BY capital_locked DESC) AS leakage_rank
FROM sku_metrics
WHERE total_units_sold < 15
ORDER BY leakage_rank
LIMIT 15;

-- ── QUERY 3: Stockout events per branch ─────────────────────
-- A stockout = stock_available = 0 but order still recorded

SELECT
    branch_name,
    region,
    COUNT(*) AS stockout_events,
    COUNT(DISTINCT sku_id) AS skus_affected,
    ROUND(SUM(quantity_sold * unit_price), 2) AS potential_lost_revenue
FROM sales
WHERE stock_available = 0
GROUP BY branch_name, region
ORDER BY stockout_events DESC;

-- ── QUERY 4: Inventory turnover ratio by category ───────────
-- Formula: Total Units Sold / Average Stock Available

SELECT
    category,
    SUM(quantity_sold)               AS total_sold,
    ROUND(AVG(stock_available), 0)   AS avg_stock,
    ROUND(
        SUM(quantity_sold) / NULLIF(AVG(stock_available), 0)
    , 2)                             AS inventory_turnover_ratio
FROM sales
GROUP BY category
ORDER BY inventory_turnover_ratio DESC;

-- ── QUERY 5: Days of stock remaining per SKU ────────────────
-- Based on average daily sales rate

WITH daily_sales AS (
    SELECT
        sku_id,
        product_name,
        category,
        SUM(quantity_sold)  AS total_sold,
        DATEDIFF(MAX(order_date), MIN(order_date)) AS active_days,
        AVG(stock_available) AS current_stock
    FROM sales
    GROUP BY sku_id, product_name, category
)
SELECT
    sku_id,
    product_name,
    category,
    ROUND(current_stock, 0)                         AS stock_left,
    ROUND(total_sold / NULLIF(active_days, 0), 2)   AS avg_daily_sales,
    ROUND(
        current_stock / NULLIF(total_sold / NULLIF(active_days, 0), 0)
    , 0)                                            AS days_of_stock_remaining,
    CASE
        WHEN current_stock / NULLIF(total_sold / NULLIF(active_days, 0), 0) < 7
            THEN '🔴 Critical — Reorder Immediately'
        WHEN current_stock / NULLIF(total_sold / NULLIF(active_days, 0), 0) < 30
            THEN '🟡 Low — Plan Reorder'
        ELSE '🟢 Sufficient'
    END AS reorder_flag
FROM daily_sales
ORDER BY days_of_stock_remaining ASC;

-- ── QUERY 6: Branch-wise overstock vs understock summary ────

SELECT
    branch_name,
    SUM(CASE WHEN stock_available > quantity_sold * 5 THEN 1 ELSE 0 END) AS overstock_skus,
    SUM(CASE WHEN stock_available < quantity_sold * 0.5 THEN 1 ELSE 0 END) AS understock_skus,
    SUM(CASE WHEN stock_available = 0 THEN 1 ELSE 0 END) AS zero_stock_skus,
    COUNT(DISTINCT sku_id) AS total_skus
FROM sales
GROUP BY branch_name
ORDER BY zero_stock_skus DESC;
