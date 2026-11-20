/*==============================================================
  PROJECT  : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 01_create_raw_tables.sql
  PURPOSE : Create nine source-shaped raw landing tables
==============================================================*/

USE OlistAnalytics;
GO

-- 1. ORDERS

IF OBJECT_ID(N'raw.orders', N'U') IS NULL
BEGIN
    CREATE TABLE raw.orders
    (
        order_id NVARCHAR(50),
        customer_id NVARCHAR(50),
        order_status NVARCHAR(30),
        order_purchase_timestamp NVARCHAR(40),
        order_approved_at NVARCHAR(40),
        order_delivered_carrier_date NVARCHAR(40),
        order_delivered_customer_date NVARCHAR(40),
        order_estimated_delivery_date NVARCHAR(40)
    );
END;
GO

-- 2. CUSTOMERS

IF OBJECT_ID(N'raw.customers', N'U') IS NULL
BEGIN
    CREATE TABLE raw.customers
    (
        customer_id NVARCHAR(50),
        customer_unique_id NVARCHAR(50),
        customer_zip_code_prefix NVARCHAR(10),
        customer_city NVARCHAR(100),
        customer_state NVARCHAR(10)
    );
END;
GO

-- 3. ORDER ITEMS

IF OBJECT_ID(N'raw.order_items', N'U') IS NULL
BEGIN
    CREATE TABLE raw.order_items
    (
        order_id NVARCHAR(50),
        order_item_id NVARCHAR(20),
        product_id NVARCHAR(50),
        seller_id NVARCHAR(50),
        shipping_limit_date NVARCHAR(40),
        price NVARCHAR(50),
        freight_value NVARCHAR(50)
    );
END;
GO

-- 4. ORDER PAYMENTS

IF OBJECT_ID(N'raw.order_payments', N'U') IS NULL
BEGIN
    CREATE TABLE raw.order_payments
    (
        order_id NVARCHAR(50),
        payment_sequential NVARCHAR(20),
        payment_type NVARCHAR(50),
        payment_installments NVARCHAR(20),
        payment_value NVARCHAR(50)
    );
END;
GO

-- 5. ORDER REVIEWS

IF OBJECT_ID(N'raw.order_reviews', N'U') IS NULL
BEGIN
    CREATE TABLE raw.order_reviews
    (
        review_id NVARCHAR(50),
        order_id NVARCHAR(50),
        review_score NVARCHAR(20),
        review_comment_title NVARCHAR(MAX),
        review_comment_message NVARCHAR(MAX),
        review_creation_date NVARCHAR(40),
        review_answer_timestamp NVARCHAR(40)
    );
END;
GO

-- 6. PRODUCTS

IF OBJECT_ID(N'raw.products', N'U') IS NULL
BEGIN
    CREATE TABLE raw.products
    (
        product_id NVARCHAR(50),
        product_category_name NVARCHAR(150),
        product_name_lenght NVARCHAR(20),
        product_description_lenght NVARCHAR(20),
        product_photos_qty NVARCHAR(20),
        product_weight_g NVARCHAR(30),
        product_length_cm NVARCHAR(30),
        product_height_cm NVARCHAR(30),
        product_width_cm NVARCHAR(30)
    );
END;
GO

-- 7. SELLERS

IF OBJECT_ID(N'raw.sellers', N'U') IS NULL
BEGIN
    CREATE TABLE raw.sellers
    (
        seller_id NVARCHAR(50),
        seller_zip_code_prefix NVARCHAR(10),
        seller_city NVARCHAR(100),
        seller_state NVARCHAR(10)
    );
END;
GO

-- 8. GEOLOCATION

IF OBJECT_ID(N'raw.geolocation', N'U') IS NULL
BEGIN
    CREATE TABLE raw.geolocation
    (
        geolocation_zip_code_prefix NVARCHAR(10),
        geolocation_lat NVARCHAR(40),
        geolocation_lng NVARCHAR(40),
        geolocation_city NVARCHAR(100),
        geolocation_state NVARCHAR(10)
    );
END;
GO

-- 9. PRODUCT CATEGORY TRANSLATION

IF OBJECT_ID(
    N'raw.product_category_translation', N'U'
) IS NULL
BEGIN
    CREATE TABLE raw.product_category_translation
    (
        product_category_name NVARCHAR(150),
        product_category_name_english NVARCHAR(150)
    );
END;
GO

-- Verify raw table creation

SELECT
    s.name AS schema_name,
    t.name AS table_name
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name = 'raw'
ORDER BY t.name;
GO
