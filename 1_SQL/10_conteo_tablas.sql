SELECT 'raw_superstore' AS tabla, COUNT(*) AS registros FROM dbo.raw_superstore
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dbo.dim_date
UNION ALL
SELECT 'dim_customer', COUNT(*) FROM dbo.dim_customer
UNION ALL
SELECT 'dim_product', COUNT(*) FROM dbo.dim_product
UNION ALL
SELECT 'dim_location', COUNT(*) FROM dbo.dim_location
UNION ALL
SELECT 'dim_shipmode', COUNT(*) FROM dbo.dim_shipmode
UNION ALL
SELECT 'dim_priority', COUNT(*) FROM dbo.dim_priority
UNION ALL
SELECT 'fact_sales', COUNT(*) FROM dbo.fact_sales;