USE DMD941_Superstore_DW;
GO

IF OBJECT_ID('dbo.raw_superstore', 'U') IS NOT NULL
    DROP TABLE dbo.raw_superstore;
GO

CREATE TABLE dbo.raw_superstore (
    row_id NVARCHAR(MAX) NULL,
    order_id NVARCHAR(MAX) NULL,
    order_date NVARCHAR(MAX) NULL,
    ship_date NVARCHAR(MAX) NULL,
    ship_mode NVARCHAR(MAX) NULL,
    customer_id NVARCHAR(MAX) NULL,
    customer_name NVARCHAR(MAX) NULL,
    segment NVARCHAR(MAX) NULL,
    city NVARCHAR(MAX) NULL,
    state NVARCHAR(MAX) NULL,
    country NVARCHAR(MAX) NULL,
    postal_code NVARCHAR(MAX) NULL,
    market NVARCHAR(MAX) NULL,
    region NVARCHAR(MAX) NULL,
    product_id NVARCHAR(MAX) NULL,
    category NVARCHAR(MAX) NULL,
    subcategory NVARCHAR(MAX) NULL,
    product_name NVARCHAR(MAX) NULL,
    sales NVARCHAR(MAX) NULL,
    quantity NVARCHAR(MAX) NULL,
    discount NVARCHAR(MAX) NULL,
    profit NVARCHAR(MAX) NULL,
    shipping_cost NVARCHAR(MAX) NULL,
    order_priority NVARCHAR(MAX) NULL
);
GO