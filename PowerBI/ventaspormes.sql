SELECT
    d.year_number,
    d.month_name,
    SUM(f.sales) AS Total_Sales
FROM fact_sales f
JOIN dim_date d 
    ON f.order_date_key = d.date_key
GROUP BY 
    d.year_number, 
    d.month_name, 
    d.month_number
ORDER BY 
    d.year_number, 
    d.month_number;