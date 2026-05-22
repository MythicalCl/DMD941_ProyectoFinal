SELECT TOP 10
    c.customer_name,
    SUM(f.sales) AS Total_Sales
FROM fact_sales f
JOIN dim_customer c 
    ON f.customer_key = c.customer_key
GROUP BY c.customer_name
ORDER BY Total_Sales DESC;
``