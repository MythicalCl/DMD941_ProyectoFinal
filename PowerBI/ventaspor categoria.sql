SELECT
    p.category,
    SUM(f.sales) AS Total_Sales,
    SUM(f.profit) AS Total_Profit
FROM fact_sales f
JOIN dim_product p 
    ON f.product_key = p.product_key
GROUP BY p.category;