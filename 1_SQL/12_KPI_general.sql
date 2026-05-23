SELECT
    SUM(sales) AS Total_Sales,
    SUM(profit) AS Total_Profit,
    SUM(quantity) AS Total_Quantity,
    COUNT(DISTINCT order_id) AS Total_Orders,
    SUM(sales) / COUNT(DISTINCT order_id) AS Avg_Ticket,
    (SUM(profit) / SUM(sales)) * 100 AS Profit_Margin
FROM fact_sales;