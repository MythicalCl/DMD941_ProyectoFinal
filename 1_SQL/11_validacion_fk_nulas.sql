SELECT
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS fk_customer_nulas,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS fk_product_nulas,
    SUM(CASE WHEN order_date_key IS NULL THEN 1 ELSE 0 END) AS fk_order_date_nulas,
    SUM(CASE WHEN ship_date_key IS NULL THEN 1 ELSE 0 END) AS fk_ship_date_nulas,
    SUM(CASE WHEN location_key IS NULL THEN 1 ELSE 0 END) AS fk_location_nulas,
    SUM(CASE WHEN shipmode_key IS NULL THEN 1 ELSE 0 END) AS fk_shipmode_nulas,
    SUM(CASE WHEN priority_key IS NULL THEN 1 ELSE 0 END) AS fk_priority_nulas
FROM dbo.fact_sales;