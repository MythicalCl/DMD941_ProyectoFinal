/* ============================================================
   PROCEDIMIENTO: sp_load_superstore_dw

   OBJETIVO:
   Este procedimiento realiza el proceso ETL del proyecto.
   Toma los datos cargados previamente en la tabla RAW
   raw_superstore, los limpia, transforma y carga en el modelo
   dimensional del Data Warehouse.

   FLUJO GENERAL:
   raw_superstore
        ↓
   #clean_superstore
        ↓
   dim_date, dim_customer, dim_product, dim_location,
   dim_shipmode, dim_priority
        ↓
   fact_sales

   MODELO:
   Esquema estrella, con fact_sales como tabla central.
============================================================ */

USE DMD941_Superstore_DW;
GO

CREATE OR ALTER PROCEDURE dbo.sp_load_superstore_dw
AS
BEGIN
    /*
       SET NOCOUNT ON evita que SQL Server devuelva mensajes
       de cantidad de filas afectadas en cada operación.

       Esto hace que la ejecución del procedimiento sea más limpia,
       especialmente cuando se ejecutan varios INSERT, DELETE o SELECT.
    */
    SET NOCOUNT ON;

    /* =====================================================
       1. LIMPIEZA DEL MODELO DIMENSIONAL
       =====================================================

       Antes de cargar nuevamente el Data Warehouse, se eliminan
       los registros actuales de la tabla de hechos y dimensiones.

       Primero se limpia fact_sales porque depende de las dimensiones
       mediante claves foráneas. Luego se limpian las dimensiones.

       Esto permite ejecutar el ETL varias veces sin duplicar datos.
    ===================================================== */

    DELETE FROM dbo.fact_sales;
    DELETE FROM dbo.dim_priority;
    DELETE FROM dbo.dim_shipmode;
    DELETE FROM dbo.dim_location;
    DELETE FROM dbo.dim_product;
    DELETE FROM dbo.dim_customer;
    DELETE FROM dbo.dim_date;

    /*
       DBCC CHECKIDENT reinicia los valores IDENTITY de las tablas.

       Esto permite que las llaves sustitutas vuelvan a comenzar
       desde 1 después de limpiar las tablas.

       Ejemplo:
       customer_key, product_key, location_key, etc.
    */
    DBCC CHECKIDENT ('dbo.fact_sales', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_priority', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_shipmode', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_location', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_product', RESEED, 0);
    DBCC CHECKIDENT ('dbo.dim_customer', RESEED, 0);

    /* =====================================================
       2. CREACIÓN DE TABLA TEMPORAL LIMPIA
       =====================================================

       Se crea una tabla temporal llamada #clean_superstore.

       Esta tabla toma los datos de raw_superstore y aplica reglas
       de limpieza y transformación, por ejemplo:

       - Quitar espacios en blanco.
       - Convertir fechas.
       - Convertir números.
       - Reemplazar valores vacíos.
       - Descartar registros incompletos.

       La tabla RAW conserva los datos originales, mientras que
       #clean_superstore representa los datos ya preparados para
       cargar el Data Warehouse.
    ===================================================== */

    IF OBJECT_ID('tempdb..#clean_superstore') IS NOT NULL
        DROP TABLE #clean_superstore;

    SELECT
        /*
           row_id se convierte a entero porque en la tabla RAW
           pudo haber ingresado como texto desde el CSV.
        */
        row_id = TRY_CONVERT(INT, LTRIM(RTRIM(row_id))),

        /*
           NULLIF convierte cadenas vacías en NULL.
           LTRIM y RTRIM eliminan espacios al inicio y al final.
        */
        order_id = NULLIF(LTRIM(RTRIM(order_id)), ''),

        /*
           Las fechas se convierten usando la función fn_to_date.
           Esto permite manejar diferentes formatos de fecha
           provenientes del archivo CSV/Excel.
        */
        order_date = dbo.fn_to_date(LTRIM(RTRIM(order_date))),
        ship_date = dbo.fn_to_date(LTRIM(RTRIM(ship_date))),

        ship_mode = NULLIF(LTRIM(RTRIM(ship_mode)), ''),

        /* Datos del cliente */
        customer_id = NULLIF(LTRIM(RTRIM(customer_id)), ''),
        customer_name = NULLIF(LTRIM(RTRIM(customer_name)), ''),
        segment = NULLIF(LTRIM(RTRIM(segment)), ''),

        /* Datos geográficos */
        city = NULLIF(LTRIM(RTRIM(city)), ''),
        state = NULLIF(LTRIM(RTRIM(state)), ''),
        country = NULLIF(LTRIM(RTRIM(country)), ''),

        /*
           Si postal_code viene vacío, se reemplaza por SIN_CODIGO.
           Esto evita valores nulos en la dimensión de ubicación.
        */
        postal_code = ISNULL(NULLIF(LTRIM(RTRIM(postal_code)), ''), 'SIN_CODIGO'),

        market = NULLIF(LTRIM(RTRIM(market)), ''),
        region = NULLIF(LTRIM(RTRIM(region)), ''),

        /* Datos del producto */
        product_id = NULLIF(LTRIM(RTRIM(product_id)), ''),
        category = NULLIF(LTRIM(RTRIM(category)), ''),
        subcategory = NULLIF(LTRIM(RTRIM(subcategory)), ''),
        product_name = NULLIF(LTRIM(RTRIM(product_name)), ''),

        /*
           sales se convierte a DECIMAL.

           Se eliminan:
           - comas
           - símbolo de dólar
           - comillas

           TRY_CONVERT evita que el proceso falle si algún dato
           no puede convertirse; en ese caso devuelve NULL.
        */
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

    /*
       Se cargan únicamente registros que tengan order_id y product_id,
       ya que ambos son necesarios para identificar transacciones y productos.
    */
    WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
      AND NULLIF(LTRIM(RTRIM(product_id)), '') IS NOT NULL;

    /* =====================================================
       3. CARGA DE dim_date
       =====================================================

       La dimensión de fecha se construye a partir de dos campos:
       - order_date
       - ship_date

       Esto permite analizar tanto la fecha de orden como la fecha
       de envío.

       date_key se genera en formato yyyyMMdd.
       Ejemplo:
       2024-05-21 → 20240521
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
       =====================================================

       Se crea la dimensión de clientes.

       Se utiliza ROW_NUMBER para evitar duplicados por customer_id.
       Si un mismo customer_id aparece varias veces en el origen,
       se conserva solamente un registro.

       customer_key se genera automáticamente como llave sustituta.
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
       =====================================================

       Se crea la dimensión de productos.

       Se utiliza ROW_NUMBER para evitar duplicados por product_id.
       Esto fue necesario porque el archivo origen puede contener
       el mismo product_id en varias filas.

       product_key se genera automáticamente como llave sustituta.
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
       =====================================================

       Se crea la dimensión de ubicación.

       Esta dimensión permite analizar ventas por:
       - ciudad
       - estado
       - país
       - código postal
       - mercado
       - región

       SELECT DISTINCT evita duplicar combinaciones geográficas.
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
       =====================================================

       Se crea la dimensión de modo de envío.

       Esta dimensión permite analizar ventas y tiempos de entrega
       según la modalidad de envío.
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
       =====================================================

       Se crea la dimensión de prioridad de orden.

       Esta dimensión permite analizar ventas según la prioridad
       asignada a cada pedido.
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
       =====================================================

       En esta sección se carga la tabla de hechos fact_sales.

       fact_sales almacena las métricas principales del negocio:
       - sales
       - quantity
       - discount
       - profit
       - shipping_cost
       - delivery_days
       - profit_margin

       También almacena las claves foráneas hacia las dimensiones.

       Cada fila representa una línea de venta, es decir:
       un producto dentro de una orden.
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
        /*
           Se obtienen las llaves sustitutas desde las dimensiones.
           Estas llaves son las que conectan fact_sales con el modelo estrella.
        */
        dc.customer_key,
        dp.product_key,
        dod.date_key AS order_date_key,
        dsd.date_key AS ship_date_key,
        dl.location_key,
        ds.shipmode_key,
        dpr.priority_key,

        /*
           row_id y order_id se mantienen como referencia al origen.
           order_id funciona como dimensión degenerada dentro de la fact.
        */
        c.row_id,
        c.order_id,

        /*
           Métricas de ventas y finanzas.
        */
        c.sales,
        c.quantity,
        c.discount,
        c.profit,
        c.shipping_cost,

        /*
           Campo calculado:
           delivery_days mide la diferencia entre fecha de orden
           y fecha de envío.
        */
        DATEDIFF(DAY, c.order_date, c.ship_date) AS delivery_days,

        /*
           Campo calculado:
           profit_margin mide la relación entre utilidad y ventas.
           Si sales es 0 o NULL, se devuelve NULL para evitar división entre cero.
        */
        CASE
            WHEN c.sales IS NULL OR c.sales = 0 THEN NULL
            ELSE c.profit / c.sales
        END AS profit_margin

    FROM #clean_superstore c

    /*
       JOIN con dim_customer:
       convierte customer_id del origen en customer_key del DW.
    */
    INNER JOIN dbo.dim_customer dc
        ON dc.customer_id = c.customer_id

    /*
       JOIN con dim_product:
       convierte product_id del origen en product_key del DW.
    */
    INNER JOIN dbo.dim_product dp
        ON dp.product_id = c.product_id

    /*
       JOIN con dim_date para fecha de orden.
       Aquí se implementa el análisis por order_date.
    */
    INNER JOIN dbo.dim_date dod
        ON dod.full_date = c.order_date

    /*
       JOIN con dim_date para fecha de envío.
       Es la misma dimensión de tiempo utilizada con otro rol.
    */
    INNER JOIN dbo.dim_date dsd
        ON dsd.full_date = c.ship_date

    /*
       JOIN con dim_location:
       se compara la combinación geográfica completa.
       ISNULL evita problemas cuando algún atributo viene nulo.
    */
    INNER JOIN dbo.dim_location dl
        ON ISNULL(dl.city, '') = ISNULL(c.city, '')
       AND ISNULL(dl.state, '') = ISNULL(c.state, '')
       AND ISNULL(dl.country, '') = ISNULL(c.country, '')
       AND ISNULL(dl.postal_code, '') = ISNULL(c.postal_code, '')
       AND ISNULL(dl.market, '') = ISNULL(c.market, '')
       AND ISNULL(dl.region, '') = ISNULL(c.region, '')

    /*
       JOIN con modo de envío.
    */
    INNER JOIN dbo.dim_shipmode ds
        ON ds.ship_mode = c.ship_mode

    /*
       JOIN con prioridad de orden.
    */
    INNER JOIN dbo.dim_priority dpr
        ON dpr.order_priority = c.order_priority;

END;
GO
