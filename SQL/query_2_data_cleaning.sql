USE ecommerce_db;

-- =============================================================================
-- FACT TABLE: fact_orders
-- Granularity: One record per order item
-- =============================================================================
DROP TABLE IF EXISTS fact_orders;

CREATE TABLE fact_orders (
    order_id VARCHAR(50),
    order_item_id INT,
    customer_id VARCHAR(50),
    seller_id VARCHAR(50),
    product_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    delivery_delay_days INT,
    PRIMARY KEY (order_id, order_item_id)
);

-- =============================================================================
-- POPULATE FACT TABLE: fact_orders
-- Purpose: Extract core transaction attributes, joining order metadata with item details.
-- Data Cleansing: Computes exact delivery delay in days using DATEDIFF.
-- =============================================================================
INSERT INTO fact_orders (
    order_id,
    order_item_id,
    customer_id,
    seller_id,
    product_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    price,
    freight_value,
    delivery_delay_days
)
SELECT 
    o.order_id,
    i.order_item_id,
    o.customer_id,
    i.seller_id,
    i.product_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    i.price,
    i.freight_value,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delivery_delay_days
FROM olist_orders_dataset o
JOIN olist_order_items_dataset i 
    ON o.order_id = i.order_id;
    
    SELECT COUNT(*) AS total_fact_records FROM fact_orders;
    
    
    
    
-- =============================================================================
-- DIMENSION 1: dim_customers
-- Granularity: Unique Customer IDs
-- =============================================================================
CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

INSERT INTO dim_customers
SELECT DISTINCT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM olist_customers_dataset;

-- =============================================================================
-- DIMENSION 2: dim_products
-- Granularity: Unique Product IDs (Mapped with English Category Names)
-- =============================================================================
CREATE TABLE IF NOT EXISTS dim_products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100),
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

INSERT INTO dim_products
SELECT DISTINCT 
    p.product_id,
    p.product_category_name,
    COALESCE(t.product_category_name_english, 'Other') AS product_category_name_english,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM olist_products_dataset p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name;

-- =============================================================================
-- DIMENSION 3: dim_sellers
-- Granularity: Unique Seller IDs
-- =============================================================================
CREATE TABLE IF NOT EXISTS dim_sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);

INSERT INTO dim_sellers
SELECT DISTINCT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM olist_sellers_dataset;

SELECT 'dim_customers' AS dim_table, COUNT(*) AS total_rows FROM dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'dim_sellers', COUNT(*) FROM dim_sellers;