USE DMD941_Superstore_DW;
GO

CREATE OR ALTER PROCEDURE dbo.sp_load_superstore_dw
AS
BEGIN
    SET NOCOUNT ON;

    /* =====================================================
       1. LIMPIEZA DEL MODELO DIMENSIONAL
    ===================================================== */

    DELETE FROM dbo.fact_sales;
    DELETE FROM dbo.dim_priority;
    DELETE FROM dbo.dim_shipmode;
    DELETE FROM dbo.dim_location;
    DELETE FROM dbo.dim_product;
    DELETE FROM dbo.dim_customer;
    DELETE FROM dbo.dim_date;

    DBCC CHECKIDENT ('dbo.fact_sales', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_priority', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_shipmode', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_location', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_product', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_customer', RESEED, 0);

    /* =====================================================
       2. TABLA TEMPORAL LIMPIA
    ===================================================== */

    IF OBJECT_ID('tempdb..#clean_superstore') IS NOT NULL
        DROP TABLE #clean_superstore;

    SELECT
        row_id = TRY_CONVERT(INT, LTRIM(RTRIM(row_id))),
        order_id = NULLIF(LTRIM(RTRIM(order_id)), ''),
        order_date = dbo.fn_to_date(LTRIM(RTRIM(order_date))),
        ship_date = dbo.fn_to_date(LTRIM(RTRIM(ship_date))),
        ship_mode = NULLIF(LTRIM(RTRIM(ship_mode)), ''),

        customer_id = NULLIF(LTRIM(RTRIM(customer_id)), ''),
        customer_name = NULLIF(LTRIM(RTRIM(customer_name)), ''),
        segment = NULLIF(LTRIM(RTRIM(segment)), ''),

        city = NULLIF(LTRIM(RTRIM(city)), ''),
        state = NULLIF(LTRIM(RTRIM(state)), ''),
        country = NULLIF(LTRIM(RTRIM(country)), ''),
        postal_code = ISNULL(NULLIF(LTRIM(RTRIM(postal_code)), ''), 'SIN_CODIGO'),
        market = NULLIF(LTRIM(RTRIM(market)), ''),
        region = NULLIF(LTRIM(RTRIM(region)), ''),

        product_id = NULLIF(LTRIM(RTRIM(product_id)), ''),
        category = NULLIF(LTRIM(RTRIM(category)), ''),
        subcategory = NULLIF(LTRIM(RTRIM(subcategory)), ''),
        product_name = NULLIF(LTRIM(RTRIM(product_name)), ''),

        sales = TRY_CONVERT(
            DECIMAL(18,4), 
            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(sales)), ',', ''), '$', ''), '"', '')
        ),

        quantity = TRY_CONVERT(INT, LTRIM(RTRIM(quantity))),

        discount = TRY_CONVERT(
            DECIMAL(18,4), 
            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(discount)), ',', ''), '$', ''), '"', '')
        ),

        profit = TRY_CONVERT(
            DECIMAL(18,4), 
            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(profit)), ',', ''), '$', ''), '"', '')
        ),

        shipping_cost = TRY_CONVERT(
            DECIMAL(18,4), 
            REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(shipping_cost)), ',', ''), '$', ''), '"', '')
        ),

        order_priority = NULLIF(LTRIM(RTRIM(order_priority)), '')
    INTO #clean_superstore
    FROM dbo.raw_superstore
    WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(product_id)), '') IS NOT NULL;

    /* =====================================================
       3. CARGA DE dim_date
    ===================================================== */

    INSERT INTO dbo.dim_date (
        date_key,
        full_date,
        day_number,
        month_number,
        month_name,
        quarter_number,
        year_number,
        semester_number
    )
    SELECT DISTINCT
        CONVERT(INT, FORMAT(date_value, 'yyyyMMdd')) AS date_key,
        date_value AS full_date,
        DAY(date_value) AS day_number,
        MONTH(date_value) AS month_number,
        DATENAME(MONTH, date_value) AS month_name,
        DATEPART(QUARTER, date_value) AS quarter_number,
        YEAR(date_value) AS year_number,
        CASE 
            WHEN MONTH(date_value) <= 6 THEN 1 
            ELSE 2 
        END AS semester_number
    FROM (
        SELECT order_date AS date_value 
        FROM #clean_superstore 
        WHERE order_date IS NOT NULL

        UNION

        SELECT ship_date AS date_value 
        FROM #clean_superstore 
        WHERE ship_date IS NOT NULL
    ) d;

    /* =====================================================
       4. CARGA DE dim_customer
       Se evita duplicidad por customer_id.
    ===================================================== */

    ;WITH clientes_unicos AS (
        SELECT
            customer_id,
            customer_name,
            segment,
            ROW_NUMBER() OVER (
                PARTITION BY customer_id
                ORDER BY customer_name, segment
            ) AS rn
        FROM #clean_superstore
        WHERE customer_id IS NOT NULL
          AND customer_name IS NOT NULL
    )
    INSERT INTO dbo.dim_customer (
        customer_id,
        customer_name,
        segment
    )
    SELECT
        customer_id,
        customer_name,
        segment
    FROM clientes_unicos
    WHERE rn = 1;

    /* =====================================================
       5. CARGA DE dim_product
       Se evita duplicidad por product_id.
    ===================================================== */

    ;WITH productos_unicos AS (
        SELECT
            product_id,
            product_name,
            category,
            subcategory,
            ROW_NUMBER() OVER (
                PARTITION BY product_id
                ORDER BY product_name, category, subcategory
            ) AS rn
        FROM #clean_superstore
        WHERE product_id IS NOT NULL
          AND product_name IS NOT NULL
    )
    INSERT INTO dbo.dim_product (
        product_id,
        product_name,
        category,
        subcategory
    )
    SELECT
        product_id,
        product_name,
        category,
        subcategory
    FROM productos_unicos
    WHERE rn = 1;

    /* =====================================================
       6. CARGA DE dim_location
    ===================================================== */

    INSERT INTO dbo.dim_location (
        city,
        state,
        country,
        postal_code,
        market,
        region
    )
    SELECT DISTINCT
        city,
        state,
        country,
        postal_code,
        market,
        region
    FROM #clean_superstore;

    /* =====================================================
       7. CARGA DE dim_shipmode
    ===================================================== */

    INSERT INTO dbo.dim_shipmode (
        ship_mode
    )
    SELECT DISTINCT
        ship_mode
    FROM #clean_superstore
    WHERE ship_mode IS NOT NULL;

    /* =====================================================
       8. CARGA DE dim_priority
    ===================================================== */

    INSERT INTO dbo.dim_priority (
        order_priority
    )
    SELECT DISTINCT
        order_priority
    FROM #clean_superstore
    WHERE order_priority IS NOT NULL;

    /* =====================================================
       9. CARGA DE fact_sales
    ===================================================== */

    INSERT INTO dbo.fact_sales (
        customer_key,
        product_key,
        order_date_key,
        ship_date_key,
        location_key,
        shipmode_key,
        priority_key,
        row_id,
        order_id,
        sales,
        quantity,
        discount,
        profit,
        shipping_cost,
        delivery_days,
        profit_margin
    )
    SELECT
        dc.customer_key,
        dp.product_key,
        dod.date_key AS order_date_key,
        dsd.date_key AS ship_date_key,
        dl.location_key,
        ds.shipmode_key,
        dpr.priority_key,
        c.row_id,
        c.order_id,
        c.sales,
        c.quantity,
        c.discount,
        c.profit,
        c.shipping_cost,
        DATEDIFF(DAY, c.order_date, c.ship_date) AS delivery_days,
        CASE
            WHEN c.sales IS NULL OR c.sales = 0 THEN NULL
            ELSE c.profit / c.sales
        END AS profit_margin
    FROM #clean_superstore c
    INNER JOIN dbo.dim_customer dc
        ON dc.customer_id = c.customer_id
    INNER JOIN dbo.dim_product dp
        ON dp.product_id = c.product_id
    INNER JOIN dbo.dim_date dod
        ON dod.full_date = c.order_date
    INNER JOIN dbo.dim_date dsd
        ON dsd.full_date = c.ship_date
    INNER JOIN dbo.dim_location dl
        ON ISNULL(dl.city, '') = ISNULL(c.city, '')
       AND ISNULL(dl.state, '') = ISNULL(c.state, '')
       AND ISNULL(dl.country, '') = ISNULL(c.country, '')
       AND ISNULL(dl.postal_code, '') = ISNULL(c.postal_code, '')
       AND ISNULL(dl.market, '') = ISNULL(c.market, '')
       AND ISNULL(dl.region, '') = ISNULL(c.region, '')
    INNER JOIN dbo.dim_shipmode ds
        ON ds.ship_mode = c.ship_mode
    INNER JOIN dbo.dim_priority dpr
        ON dpr.order_priority = c.order_priority;

END;
GO