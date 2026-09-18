-- =============================================================================
-- DATABASE CONTEXT SELECTION
-- =============================================================================
USE ecommerce_db;


-- =============================================================================
-- STEP 1: STAGING DATA INTEGRITY & ROW COUNT VERIFICATION
-- Purpose: Validate complete record ingestion across primary transactional tables
-- Business Logic: Ensures no data loss or ingestion failure occurred during Python ETL
-- =============================================================================
SELECT 'olist_orders_dataset' AS table_name, COUNT(*) AS row_count FROM olist_orders_dataset
UNION ALL
SELECT 'olist_customers_dataset', COUNT(*) FROM olist_customers_dataset
UNION ALL
SELECT 'olist_order_items_dataset', COUNT(*) FROM olist_order_items_dataset;


-- =============================================================================
-- STEP 2: REVENUE DISTRIBUTION BY CUSTOMER GEOGRAPHY
-- Purpose: Identify the top 10 revenue-generating customer cities
-- Business Logic:
--   1. Join Orders, Customers, and Payments tables on relational primary/foreign keys.
--   2. Filter for order_status = 'delivered' to calculate realized revenue only (excluding canceled/refunded).
--   3. Aggregate total payment value rounded to 2 decimal places and group by city.
-- =============================================================================
SELECT 
    c.customer_city, 
    ROUND(SUM(p.payment_value), 2) AS total_revenue
FROM olist_orders_dataset o
JOIN olist_customers_dataset c 
    ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset p 
    ON o.order_id = p.order_id 
WHERE o.order_status = 'delivered' 
GROUP BY c.customer_city 
ORDER BY total_revenue DESC 
LIMIT 10;


-- =============================================================================
-- STEP 3: SLA & LOGISTICS DELAY ANALYSIS
-- Purpose: Identify the top 5 states suffering from the worst delivery delays
-- Business Logic:
--   1. Filter for 'delivered' status AND orders where delivery date strictly exceeded estimated date.
--   2. Calculate exact delay duration in days using DATEDIFF(actual_delivery, estimated_delivery).
--   3. Average the delay days per customer state to highlight high-risk logistics regions.
-- =============================================================================
SELECT 
    c.customer_state, 
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 0) AS avg_delay_days 
FROM olist_orders_dataset o 
JOIN olist_customers_dataset c 
    ON o.customer_id = c.customer_id 
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date 
GROUP BY c.customer_state 
ORDER BY avg_delay_days DESC 
LIMIT 5;


-- =============================================================================
-- STEP 4: SELLER PERFORMANCE & SATISFACTION EVALUATION
-- Purpose: Evaluate top-revenue sellers against customer satisfaction (review scores)
-- Business Logic:
--   1. Calculate seller revenue as (item_price + freight_value) directly from items table.
--      *(Avoids Cartesian multiplication bug caused by 1:N payment split joins)*
--   2. LEFT JOIN reviews table to calculate average review score per seller.
--   3. Identifies high-grossing vendors with low satisfaction scores requiring operational intervention.
-- =============================================================================
SELECT 
    i.seller_id,
    ROUND(SUM(i.price + i.freight_value), 2) AS total_revenue,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_order_items_dataset i
LEFT JOIN olist_order_reviews_dataset r 
    ON i.order_id = r.order_id
GROUP BY i.seller_id
ORDER BY total_revenue DESC
LIMIT 10;