SELECT
    COUNT(*) AS total_rows
FROM transactions;
-- =========================================================
-- 2. CORE BUSINESS KPIs
-- =========================================================

-- Calculate high-level business performance metrics
SELECT
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT "Customer ID") AS total_customers,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(AVG(Revenue), 2) AS avg_revenue_per_line
FROM transactions;
-- =========================================================
-- 3. AVERAGE ORDER VALUE
-- =========================================================

-- First aggregate transaction lines into individual orders,
-- then calculate the average revenue generated per order.
WITH order_totals AS (
    SELECT
        Invoice,
        SUM(Revenue) AS order_revenue
    FROM transactions
    GROUP BY Invoice
)

SELECT
    COUNT(*) AS total_orders,
    ROUND(AVG(order_revenue), 2) AS average_order_value,
    ROUND(MIN(order_revenue), 2) AS smallest_order,
    ROUND(MAX(order_revenue), 2) AS largest_order
FROM order_totals;
-- =========================================================
-- 4. SALES VS RETURNS / CANCELLATIONS
-- =========================================================

-- Classify transaction lines based on revenue
SELECT
    CASE
        WHEN Revenue < 0 THEN 'Return / Cancellation'
        WHEN Revenue > 0 THEN 'Sale'
        ELSE 'Zero Revenue'
    END AS transaction_type,
    COUNT(*) AS transaction_lines,
    ROUND(SUM(Revenue), 2) AS total_revenue
FROM transactions
GROUP BY
    CASE
        WHEN Revenue < 0 THEN 'Return / Cancellation'
        WHEN Revenue > 0 THEN 'Sale'
        ELSE 'Zero Revenue'
    END
ORDER BY total_revenue DESC;

-- =========================================================
-- 5. RETURN / CANCELLATION IMPACT
-- =========================================================

SELECT
    ROUND(SUM(CASE WHEN Revenue > 0 THEN Revenue ELSE 0 END), 2)
        AS gross_sales,

    ROUND(ABS(SUM(CASE WHEN Revenue < 0 THEN Revenue ELSE 0 END)), 2)
        AS returns_value,

    ROUND(SUM(Revenue), 2)
        AS net_revenue,

    ROUND(
        ABS(SUM(CASE WHEN Revenue < 0 THEN Revenue ELSE 0 END))
        / SUM(CASE WHEN Revenue > 0 THEN Revenue ELSE 0 END) * 100,
        2
    ) AS return_rate_pct

FROM transactions;
-- =========================================================
-- 6. SALES-ONLY AVERAGE ORDER VALUE
-- =========================================================

-- Calculate order value using positive sales transactions only
WITH sales_orders AS (
    SELECT
        Invoice,
        SUM(Revenue) AS order_revenue
    FROM transactions
    WHERE Revenue > 0
    GROUP BY Invoice
)

SELECT
    COUNT(*) AS completed_orders,
    ROUND(SUM(order_revenue), 2) AS gross_sales,
    ROUND(AVG(order_revenue), 2) AS average_order_value,
    ROUND(MIN(order_revenue), 2) AS smallest_order,
    ROUND(MAX(order_revenue), 2) AS largest_order
FROM sales_orders;

-- =========================================================
-- 7. MONTHLY REVENUE TREND
-- =========================================================

-- Analyze net revenue and order volume by month
SELECT
    strftime('%Y-%m', InvoiceDate) AS month,
    COUNT(DISTINCT Invoice) AS total_orders,
    ROUND(SUM(Revenue), 2) AS net_revenue
FROM transactions
GROUP BY strftime('%Y-%m', InvoiceDate)
ORDER BY month;
-- =========================================================
-- 8. MONTH-OVER-MONTH REVENUE GROWTH
-- =========================================================

-- Calculate monthly revenue and compare each month
-- with the previous month using the LAG window function.
WITH monthly_revenue AS (
    SELECT
        strftime('%Y-%m', InvoiceDate) AS month,
        SUM(Revenue) AS net_revenue
    FROM transactions
    GROUP BY strftime('%Y-%m', InvoiceDate)
),

revenue_comparison AS (
    SELECT
        month,
        net_revenue,
        LAG(net_revenue) OVER (ORDER BY month) AS previous_month_revenue
    FROM monthly_revenue
)

SELECT
    month,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,

    ROUND(
        (net_revenue - previous_month_revenue)
        / previous_month_revenue * 100,
        2
    ) AS month_over_month_growth_pct

FROM revenue_comparison
ORDER BY month;
LAG(net_revenue) OVER (ORDER BY month)
(Current Month − Previous Month)
──────────────────────────────── × 100
       Previous Month

-- =========================================================
-- 
-- =========================================================
-- 9. TOP MERCHANDISE PRODUCTS BY REVENUE
-- =========================================================

-- Exclude non-merchandise transaction codes such as
-- manual adjustments and postage charges.
SELECT
    StockCode,
    Description,
    SUM(Quantity) AS units_sold,
    ROUND(SUM(Revenue), 2) AS product_revenue
FROM transactions
WHERE Revenue > 0
    AND Description IS NOT NULL
    AND StockCode NOT IN ('M', 'DOT', 'POST')
GROUP BY StockCode, Description
ORDER BY product_revenue DESC
LIMIT 10;
-- =========================================================
-- 10. CUSTOMER VALUE ANALYSIS
-- =========================================================

-- Aggregate transaction data to the customer level
-- to measure revenue, order frequency and average order value.
WITH customer_orders AS (
    SELECT
        "Customer ID" AS customer_id,
        Invoice,
        SUM(Revenue) AS order_revenue
    FROM transactions
    WHERE Revenue > 0
        AND "Customer ID" IS NOT NULL
    GROUP BY "Customer ID", Invoice
),

customer_metrics AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(order_revenue) AS customer_revenue,
        AVG(order_revenue) AS customer_aov
    FROM customer_orders
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_orders,
    ROUND(customer_revenue, 2) AS customer_revenue,
    ROUND(customer_aov, 2) AS average_order_value,
    DENSE_RANK() OVER (
        ORDER BY customer_revenue DESC
    ) AS revenue_rank
FROM customer_metrics
ORDER BY customer_revenue DESC
LIMIT 10;
-- =========================================================
-- 11. CUSTOMER SEGMENTATION
-- =========================================================

-- Segment customers based on purchase frequency and total
-- revenue to identify high-value and repeat customers.
WITH customer_metrics AS (
    SELECT
        "Customer ID" AS customer_id,
        COUNT(DISTINCT Invoice) AS total_orders,
        SUM(Revenue) AS total_revenue
    FROM transactions
    WHERE Revenue > 0
        AND "Customer ID" IS NOT NULL
    GROUP BY "Customer ID"
),

customer_segments AS (
    SELECT
        customer_id,
        total_orders,
        total_revenue,
        CASE
            WHEN total_orders >= 20 AND total_revenue >= 10000
                THEN 'High Value'
            WHEN total_orders >= 5
                THEN 'Loyal'
            WHEN total_orders >= 2
                THEN 'Repeat'
            ELSE 'One-Time'
        END AS customer_segment
    FROM customer_metrics
)

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(total_revenue), 2) AS segment_revenue,
    ROUND(AVG(total_revenue), 2) AS avg_customer_revenue
FROM customer_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;
-- =========================================================
-- 12. TOP COUNTRIES BY REVENUE
-- =========================================================

-- Compare geographic markets using positive sales.
SELECT
    Country,
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT "Customer ID") AS unique_customers,
    ROUND(SUM(Revenue), 2) AS gross_sales
FROM transactions
WHERE Revenue > 0
GROUP BY Country
ORDER BY gross_sales DESC
LIMIT 10;