-- ============================================================
--  FILE 1: DATA EXPLORATION & PROFILING
--  Project : Retail Sales Performance & Inventory Optimization
--  Author  : TECHMAVRIK
--  Tool    : MySQL 8.0
-- ============================================================

-- ── STEP 1: Create the database & table ──────────────────────

CREATE DATABASE IF NOT EXISTS retail_analytics;
USE retail_analytics;

CREATE TABLE IF NOT EXISTS sales (
    order_id        VARCHAR(20)    NOT NULL,
    order_date      DATE           NOT NULL,
    branch_name     VARCHAR(50)    NOT NULL,
    region          VARCHAR(20)    NOT NULL,
    category        VARCHAR(50)    NOT NULL,
    sku_id          VARCHAR(20)    NOT NULL,
    product_name    VARCHAR(100)   NOT NULL,
    quantity_sold   INT            NOT NULL,
    unit_price      DECIMAL(10,2)  NOT NULL,
    cost_price      DECIMAL(10,2)  NOT NULL,
    stock_available INT            NOT NULL,
    customer_type   VARCHAR(20)    NOT NULL   -- 'Retail' or 'Wholesale'
);

-- ── STEP 2: Basic row & column count ────────────────────────

SELECT COUNT(*)            AS total_rows   FROM sales;
SELECT COUNT(DISTINCT order_id)  AS unique_orders  FROM sales;
SELECT COUNT(DISTINCT sku_id)    AS unique_skus    FROM sales;
SELECT COUNT(DISTINCT branch_name) AS total_branches FROM sales;

-- ── STEP 3: Date range of the dataset ───────────────────────

SELECT
    MIN(order_date) AS data_start,
    MAX(order_date) AS data_end,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS total_days
FROM sales;

-- ── STEP 4: Check for NULL values in every column ───────────

SELECT
    SUM(CASE WHEN order_id        IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date      IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN branch_name     IS NULL THEN 1 ELSE 0 END) AS null_branch,
    SUM(CASE WHEN region          IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN category        IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN sku_id          IS NULL THEN 1 ELSE 0 END) AS null_sku,
    SUM(CASE WHEN quantity_sold   IS NULL THEN 1 ELSE 0 END) AS null_qty,
    SUM(CASE WHEN unit_price      IS NULL THEN 1 ELSE 0 END) AS null_price,
    SUM(CASE WHEN cost_price      IS NULL THEN 1 ELSE 0 END) AS null_cost,
    SUM(CASE WHEN stock_available IS NULL THEN 1 ELSE 0 END) AS null_stock
FROM sales;

-- ── STEP 5: Check for duplicate orders ──────────────────────

SELECT
    order_id,
    COUNT(*) AS occurrences
FROM sales
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

-- ── STEP 6: Distribution by region ──────────────────────────

SELECT
    region,
    COUNT(DISTINCT branch_name) AS branches,
    COUNT(*)                    AS total_transactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM sales
GROUP BY region
ORDER BY total_transactions DESC;

-- ── STEP 7: Distribution by category ────────────────────────

SELECT
    category,
    COUNT(DISTINCT sku_id)                      AS unique_skus,
    SUM(quantity_sold)                          AS total_units_sold,
    ROUND(SUM(quantity_sold * unit_price), 2)   AS gross_revenue
FROM sales
GROUP BY category
ORDER BY gross_revenue DESC;

-- ── STEP 8: Check for data quality issues ───────────────────

-- Negative quantities (returns not tagged properly)
SELECT COUNT(*) AS negative_qty_rows
FROM sales
WHERE quantity_sold < 0;

-- Prices lower than cost (margin erosion / data error)
SELECT COUNT(*) AS price_below_cost
FROM sales
WHERE unit_price < cost_price;

-- Zero stock but sale recorded (ghost sales)
SELECT COUNT(*) AS ghost_sales
FROM sales
WHERE stock_available = 0 AND quantity_sold > 0;

-- ── STEP 9: Monthly transaction volume trend ────────────────

SELECT
    DATE_FORMAT(order_date, '%Y-%m')    AS month,
    COUNT(*)                            AS transactions,
    SUM(quantity_sold)                  AS units_sold,
    ROUND(SUM(quantity_sold * unit_price), 2) AS revenue
FROM sales
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;
