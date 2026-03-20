
CREATE TABLE silver_products AS
SELECT DISTINCT 
    product_id, 
    category_code, 
    brand, 
    price
FROM raw_events
WHERE brand IS NOT NULL 
  AND price > 0;


CREATE TABLE silver_events AS
SELECT 
    CAST(event_time AS TIMESTAMP) AS event_time,
    event_type,
    product_id,
    user_id,
    user_session
FROM raw_events
WHERE user_id IS NOT NULL;




CREATE TABLE gold_brand_funnel AS
SELECT 
    p.brand,
    COUNT(CASE WHEN e.event_type = 'view' THEN 1 END) AS total_views,
    COUNT(CASE WHEN e.event_type = 'cart' THEN 1 END) AS total_adds_to_cart,
    COUNT(CASE WHEN e.event_type = 'purchase' THEN 1 END) AS total_purchases
FROM silver_events e
JOIN silver_products p ON e.product_id = p.product_id
GROUP BY p.brand
HAVING COUNT(CASE WHEN e.event_type = 'purchase' THEN 1 END) > 50
ORDER BY total_purchases DESC;