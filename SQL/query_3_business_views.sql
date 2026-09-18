USE ecommerce_db;

-- Monthly Revenue & Growth Rate
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
    ROUND(SUM(price + freight_value), 2) AS current_revenue,
    LAG(ROUND(SUM(price + freight_value), 2)) OVER (ORDER BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) AS prev_revenue,
    ROUND(
        (SUM(price + freight_value) - LAG(SUM(price + freight_value)) OVER (ORDER BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m'))) 
        / LAG(SUM(price + freight_value)) OVER (ORDER BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')) * 100, 2
    ) AS growth_pct
FROM fact_orders
WHERE order_status = 'delivered'
GROUP BY month
ORDER BY month;


-- Task 2: Customer Segmentation by Purchase Volume
SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(price + freight_value), 2) AS total_spent,
    CASE 
        WHEN COUNT(order_id) >= 3 THEN 'VIP / Repeat Buyer'
        WHEN COUNT(order_id) = 2 THEN 'Frequent Customer'
        ELSE 'One-Time Customer'
    END AS customer_segment
FROM fact_orders
WHERE order_status = 'delivered'
GROUP BY customer_id
ORDER BY total_orders DESC
LIMIT 10;


-- Task 3: Rank Product Categories Per State
WITH state_category_revenue AS (
    SELECT 
        s.seller_state,
        p.product_category_name_english AS category,
        ROUND(SUM(f.price + f.freight_value), 2) AS total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY s.seller_state 
            ORDER BY SUM(f.price + f.freight_value) DESC
        ) AS category_rank
    FROM fact_orders f
    JOIN dim_sellers s ON f.seller_id = s.seller_id
    JOIN dim_products p ON f.product_id = p.product_id
    WHERE f.order_status = 'delivered'
    GROUP BY s.seller_state, p.product_category_name_english
)
SELECT 
    seller_state,
    category,
    total_revenue,
    category_rank
FROM state_category_revenue
WHERE category_rank <= 3
ORDER BY seller_state, category_rank;


-- Task 4: Sellers with Highest Delivery Delay Percentage (Min 10 Orders)
SELECT 
    seller_id,
    COUNT(order_id) AS total_orders,
    SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) AS delayed_orders,
    ROUND(
        (SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) / COUNT(order_id)) * 100, 
        2
    ) AS delay_percentage
FROM fact_orders
WHERE order_status = 'delivered'
GROUP BY seller_id
HAVING COUNT(order_id) >= 10
ORDER BY delay_percentage DESC
LIMIT 10;