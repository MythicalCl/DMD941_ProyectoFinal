USE DMD941_Superstore_DW;
GO

/* =====================================================
   LIMPIEZA PREVIA
===================================================== */

IF OBJECT_ID('dbo.fact_sales', 'U') IS NOT NULL DROP TABLE dbo.fact_sales;
IF OBJECT_ID('dbo.dim_priority', 'U') IS NOT NULL DROP TABLE dbo.dim_priority;
IF OBJECT_ID('dbo.dim_shipmode', 'U') IS NOT NULL DROP TABLE dbo.dim_shipmode;
IF OBJECT_ID('dbo.dim_location', 'U') IS NOT NULL DROP TABLE dbo.dim_location;
IF OBJECT_ID('dbo.dim_product', 'U') IS NOT NULL DROP TABLE dbo.dim_product;
IF OBJECT_ID('dbo.dim_customer', 'U') IS NOT NULL DROP TABLE dbo.dim_customer;
IF OBJECT_ID('dbo.dim_date', 'U') IS NOT NULL DROP TABLE dbo.dim_date;
IF OBJECT_ID('dbo.raw_superstore', 'U') IS NOT NULL DROP TABLE dbo.raw_superstore;
GO

/* =====================================================
   TABLA RAW
   Esta tabla recibe los datos originales del Excel.
===================================================== */

CREATE TABLE dbo.raw_superstore (
    row_id NVARCHAR(50) NULL,
    order_id NVARCHAR(50) NULL,
    order_date NVARCHAR(50) NULL,
    ship_date NVARCHAR(50) NULL,
    ship_mode NVARCHAR(100) NULL,
    customer_id NVARCHAR(50) NULL,
    customer_name NVARCHAR(255) NULL,
    segment NVARCHAR(100) NULL,
    city NVARCHAR(150) NULL,
    state NVARCHAR(150) NULL,
    country NVARCHAR(150) NULL,
    postal_code NVARCHAR(50) NULL,
    market NVARCHAR(100) NULL,
    region NVARCHAR(100) NULL,
    product_id NVARCHAR(100) NULL,
    category NVARCHAR(100) NULL,
    subcategory NVARCHAR(100) NULL,
    product_name NVARCHAR(500) NULL,
    sales NVARCHAR(50) NULL,
    quantity NVARCHAR(50) NULL,
    discount NVARCHAR(50) NULL,
    profit NVARCHAR(50) NULL,
    shipping_cost NVARCHAR(50) NULL,
    order_priority NVARCHAR(100) NULL
);
GO

/* =====================================================
   DIMENSIONES
===================================================== */

CREATE TABLE dbo.dim_date (
    date_key INT NOT NULL PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_number INT NOT NULL,
    month_number INT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    quarter_number INT NOT NULL,
    year_number INT NOT NULL,
    semester_number INT NOT NULL
);
GO

CREATE TABLE dbo.dim_customer (
    customer_key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_id NVARCHAR(50) NOT NULL,
    customer_name NVARCHAR(255) NOT NULL,
    segment NVARCHAR(100) NULL,
    CONSTRAINT UQ_dim_customer UNIQUE (customer_id)
);
GO

CREATE TABLE dbo.dim_product (
    product_key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    product_id NVARCHAR(100) NOT NULL,
    product_name NVARCHAR(500) NOT NULL,
    category NVARCHAR(100) NULL,
    subcategory NVARCHAR(100) NULL,
    CONSTRAINT UQ_dim_product UNIQUE (product_id)
);
GO

CREATE TABLE dbo.dim_location (
    location_key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    city NVARCHAR(150) NULL,
    state NVARCHAR(150) NULL,
    country NVARCHAR(150) NULL,
    postal_code NVARCHAR(50) NULL,
    market NVARCHAR(100) NULL,
    region NVARCHAR(100) NULL,
    CONSTRAINT UQ_dim_location UNIQUE (
        city, state, country, postal_code, market, region
    )
);
GO

CREATE TABLE dbo.dim_shipmode (
    shipmode_key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ship_mode NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_dim_shipmode UNIQUE (ship_mode)
);
GO

CREATE TABLE dbo.dim_priority (
    priority_key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    order_priority NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_dim_priority UNIQUE (order_priority)
);
GO

/* =====================================================
   TABLA DE HECHOS
===================================================== */

CREATE TABLE dbo.fact_sales (
    sales_key BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    order_date_key INT NOT NULL,
    ship_date_key INT NOT NULL,
    location_key INT NOT NULL,
    shipmode_key INT NOT NULL,
    priority_key INT NOT NULL,

    row_id INT NULL,
    order_id NVARCHAR(50) NOT NULL,

    sales DECIMAL(18,4) NULL,
    quantity INT NULL,
    discount DECIMAL(18,4) NULL,
    profit DECIMAL(18,4) NULL,
    shipping_cost DECIMAL(18,4) NULL,

    delivery_days INT NULL,
    profit_margin DECIMAL(18,4) NULL,

    CONSTRAINT FK_fact_customer FOREIGN KEY (customer_key)
        REFERENCES dbo.dim_customer(customer_key),

    CONSTRAINT FK_fact_product FOREIGN KEY (product_key)
        REFERENCES dbo.dim_product(product_key),

    CONSTRAINT FK_fact_order_date FOREIGN KEY (order_date_key)
        REFERENCES dbo.dim_date(date_key),

    CONSTRAINT FK_fact_ship_date FOREIGN KEY (ship_date_key)
        REFERENCES dbo.dim_date(date_key),

    CONSTRAINT FK_fact_location FOREIGN KEY (location_key)
        REFERENCES dbo.dim_location(location_key),

    CONSTRAINT FK_fact_shipmode FOREIGN KEY (shipmode_key)
        REFERENCES dbo.dim_shipmode(shipmode_key),

    CONSTRAINT FK_fact_priority FOREIGN KEY (priority_key)
        REFERENCES dbo.dim_priority(priority_key)
);
GO