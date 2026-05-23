SELECT
    l.region,
    SUM(f.sales) AS Total_Sales,
    SUM(f.profit) AS Total_Profit
FROM fact_sales f
JOIN dim_location l 
    ON f.location_key = l.location_key
GROUP BY l.region;