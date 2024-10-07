-- Calculate summary statistics for numerical features. 
 SELECT 
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM products) AS total_products,
   (SELECT COUNT(DISTINCT user_id) FROM orders) AS total_users;
 -- Examine the distribution of departments . 
SELECT d.department, COUNT(p.product_id) AS total_products
FROM products p
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department;
-- Examine the distribution of Aisles . 
SELECT a.aisle, COUNT(p.product_id) AS total_products
FROM products p
JOIN aisles a ON p.aisle_id = a.aisle_id
GROUP BY a.aisle;
-- Average number of orders per user. 
SELECT user_id, COUNT(order_id) AS total_orders
FROM orders
GROUP BY user_id
ORDER BY total_orders DESC;
-- Calculate the average time between orders for each user
SELECT 
    user_id, 
    AVG(days_since_prior_order) AS avg_days_between_orders
FROM orders
WHERE days_since_prior_order IS NOT NULL  -- Exclude first orders with NULL days_since_prior_order
GROUP BY user_id;
-- Calculate the number of orders placed by each customer
SELECT 
    user_id, 
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY user_id
ORDER BY total_orders DESC;
-- Categorize customers based on the total number of orders they have placed
SELECT 
    user_id,
    COUNT(order_id) AS total_orders,
    CASE
        WHEN COUNT(order_id) <= 5 THEN 'Low'
        WHEN COUNT(order_id) BETWEEN 6 AND 15 THEN 'Medium'
        ELSE 'High'
    END AS order_category
FROM orders
GROUP BY user_id
ORDER BY total_orders DESC;
-- Categorize customers based on purchase frequency (average time between orders)
SELECT 
    user_id, 
    AVG(days_since_prior_order) AS avg_days_between_orders,
    CASE
        WHEN AVG(days_since_prior_order) <= 7 THEN 'High frequency'
        WHEN AVG(days_since_prior_order) BETWEEN 8 AND 20 THEN 'Medium frequency'
        ELSE 'Low frequency'
    END AS purchase_frequency_category
FROM orders
WHERE days_since_prior_order IS NOT NULL  -- Exclude first orders with NULL values
GROUP BY user_id
ORDER BY avg_days_between_orders ASC;
-- Identify customers who haven't placed an order in the last 30 days
SELECT 
    user_id,
    MAX(order_number) AS last_order_number,
    MAX(days_since_prior_order) AS days_since_last_order
FROM orders
GROUP BY user_id
HAVING MAX(days_since_prior_order) > 30 OR MAX(days_since_prior_order) IS NULL
ORDER BY days_since_last_order DESC;
-- What percentage of customers have churned in the past quarter:
-- Step 1: Calculate the total number of customers
WITH all_customers AS (
    SELECT DISTINCT user_id
    FROM orders
),

-- Step 2: Identify customers who haven't placed any orders in the last 90 days
churned_customers AS (
    SELECT user_id
    FROM orders
    WHERE DATEDIFF(NOW(), MAX(order_date)) > 90
    GROUP BY user_id
)

-- Step 3: Calculate the percentage of customers who have churned
SELECT 
    (SELECT COUNT(*) FROM churned_customers) * 100.0 / (SELECT COUNT(*) FROM all_customers) AS churn_percentage
;


-- Identify most popular products by frequency
SELECT p.product_name, COUNT(op.product_id) AS order_count
FROM order_products__prior op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
ORDER BY order_count DESC
LIMIT 10;
-- Determine average order size (number of items per order). 
SELECT AVG(product_count) AS avg_order_size
FROM (
    SELECT order_id, COUNT(product_id) AS product_count
    FROM order_products__prior
    GROUP BY order_id
) AS order_sizes;
--  Analyze orders by day of the week
SELECT order_dow, COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_dow
ORDER BY total_orders DESC;
--  Analyze orders by  hour of the day. 
SELECT order_hour_of_day, COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour_of_day
ORDER BY total_orders DESC;
-- Identify most frequently co-purchased items. 
SELECT op1.product_id AS product_1, op2.product_id AS product_2, COUNT(*) AS frequency
FROM order_products__prior op1
JOIN order_products__prior op2 ON op1.order_id = op2.order_id AND op1.product_id < op2.product_id
GROUP BY op1.product_id, op2.product_id
ORDER BY frequency DESC
LIMIT 10;
-- Products often bought together on weekends vs. weekdays. 
-- Step 1: Calculate the total number of customers
WITH all_customers AS (
    SELECT DISTINCT user_id
    FROM orders
),

-- Step 2: Identify customers who haven't placed any orders in the last 90 days
churned_customers AS (
    SELECT user_id
    FROM orders
    WHERE DATEDIFF(NOW(), MAX(order_date)) > 90
    GROUP BY user_id
)

-- Step 3: Calculate the percentage of customers who have churned
SELECT 
    (SELECT COUNT(*) FROM churned_customers) * 100.0 / (SELECT COUNT(*) FROM all_customers) AS churn_percentage
;

-- Analyze sales distribution of top-selling products
SELECT p.product_name, COUNT(op.product_id) AS sales
FROM order_products__prior op
JOIN products p ON op.product_id = p.product_id
GROUP BY p.product_name
ORDER BY sales DESC
LIMIT 5;
-- Identify top 5 products commonly added to the cart first.
SELECT p.product_name, COUNT(op.add_to_cart_order) AS first_added
FROM order_products__prior op
JOIN products p ON op.product_id = p.product_id
WHERE op.add_to_cart_order = 1
GROUP BY p.product_name
ORDER BY first_added DESC
LIMIT 5;
-- Calculate the average number of unique products per order.
SELECT AVG(product_count) AS avg_unique_products_per_order
FROM (
    SELECT order_id, COUNT(DISTINCT product_id) AS product_count
    FROM order_products__prior
    GROUP BY order_id
) AS product_counts;

-- Products reordered the most. 
SELECT p.product_name, COUNT(op.reordered) AS reorder_count
FROM order_products__prior op
JOIN products p ON op.product_id = p.product_id
WHERE op.reordered = 1
GROUP BY p.product_name
ORDER BY reorder_count DESC
LIMIT 10;
--  Reorder behavior based on day of the week and days since prior order.
SELECT order_dow, AVG(reordered) AS avg_reorder_rate
FROM orders o
JOIN order_products__prior op ON o.order_id = op.order_id
GROUP BY order_dow;
-- Calculate reorder rate based on the number of items in the cart
SELECT 
    item_count,
    AVG(reordered) AS avg_reorder_rate
FROM (
    SELECT 
        order_id, 
        COUNT(product_id) AS item_count,  -- Number of items in each order
        AVG(reordered) AS reordered       -- Reorder flag for the products in the order
    FROM order_products__prior
    GROUP BY order_id
) AS order_reorder_stats
GROUP BY item_count
ORDER BY item_count;
-- Best-selling departments based on the number of products sold
SELECT 
    d.department, 
    COUNT(op.product_id) AS total_products_sold
FROM order_products__prior op
JOIN products p ON op.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id
GROUP BY d.department
ORDER BY total_products_sold DESC
LIMIT 5;  -- Top 5 best-selling departments
-- Best-selling aisles based on the number of products sold
SELECT 
    a.aisle, 
    COUNT(op.product_id) AS total_products_sold
FROM order_products__prior op
JOIN products p ON op.product_id = p.product_id
JOIN aisles a ON p.aisle_id = a.aisle_id
GROUP BY a.aisle
ORDER BY total_products_sold DESC
LIMIT 5;  -- Top 5 best-selling aisles
-- Break down the "Produce" department by aisle
SELECT 
    a.aisle, 
    COUNT(p.product_id) AS total_products
FROM products p
JOIN aisles a ON p.aisle_id = a.aisle_id
JOIN departments d ON p.department_id = d.department_id
WHERE d.department = 'Produce'
GROUP BY a.aisle
ORDER BY total_products DESC;
-- Differences in purchasing behavior based on different departments or aisles. 

-- Analyze reorder rate, average order size, and purchase frequency by department or aisle
SELECT 
    d.department AS category_type,  -- Use "a.aisle AS category_type" to analyze by aisle
    AVG(op.reordered) AS avg_reorder_rate,  -- Average reorder rate
    AVG(order_size) AS avg_order_size,      -- Average number of products per order
    AVG(o.days_since_prior_order) AS avg_days_between_orders  -- Purchase frequency
FROM orders o
JOIN order_products__prior op ON o.order_id = op.order_id
JOIN products p ON op.product_id = p.product_id
JOIN departments d ON p.department_id = d.department_id  -- Use "aisles a" and "p.aisle_id = a.aisle_id" for aisles
-- Subquery to calculate order size
JOIN (
    SELECT order_id, COUNT(product_id) AS order_size
    FROM order_products__prior
    GROUP BY order_id
) AS order_sizes ON o.order_id = order_sizes.order_id
WHERE o.days_since_prior_order IS NOT NULL  -- Exclude first orders
GROUP BY d.department  -- Use "a.aisle" for aisles
ORDER BY avg_reorder_rate DESC;  -- Sort by reorder rate or any other metric
