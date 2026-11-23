/*================================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 04_complete_staging_cleaning.sql
  PURPOSE : Consolidated Phase 4 staging creation, loading and validation

  DATABASE : OlistAnalytics
  SOURCE   : raw schema
  TARGET   : stg schema

  HOW TO USE THIS SCRIPT
  ---------------------
  This file combines the 19 Phase 4 scripts into one readable,
  sectioned reference script.

  Run only when the staging tables have NOT already been created
  and populated. The CREATE TABLE statements will fail if the
  tables already exist, and rerunning INSERT statements would
  duplicate data or encounter primary-key violations.

  REQUIREMENTS
  ------------
  1. OlistAnalytics database exists.
  2. raw and stg schemas exist.
  3. All nine raw source tables have been loaded and validated.
  4. Raw date and numeric values have already passed conversion
     checks in the Phase 3 data-quality audit.

  IMPORTANT DESIGN DECISIONS
  --------------------------
  - The raw layer remains unchanged.
  - Staging columns use appropriate SQL Server data types.
  - Missing optional source values are preserved as NULL.
  - Suspicious values are not automatically corrected or deleted.
  - Primary keys are applied only where a reliable key exists.
  - Geolocation has no primary key because no reliable unique
    source-row identifier was established.

  NOTE
  ----
  GO separates SQL Server batches. It is a batch separator used
  by tools such as SQL Server Management Studio.

================================================================*/

USE OlistAnalytics;
GO

/*================================================================
  SECTION 01 — ORDERS: TABLE STRUCTURE
  ----------------------------------------------------------------
  Create the typed order-level table, then load timestamps from
  raw.orders. The primary key ensures one row per order. The checks
  cover row count, uniqueness, data types and missing timestamps.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 01_create_stg_orders.sql
  PURPOSE : Create the cleaned staging table for orders

  SOURCE  : raw.orders
  TARGET  : stg.orders
==============================================================*/

CREATE TABLE stg.orders
(
    order_id VARCHAR(32) NOT NULL,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20) NOT NULL,

    order_purchase_timestamp DATETIME2(0) NOT NULL,
    order_approved_at DATETIME2(0) NULL,
    order_delivered_carrier_date DATETIME2(0) NULL,
    order_delivered_customer_date DATETIME2(0) NULL,
    order_estimated_delivery_date DATETIME2(0) NOT NULL,

    CONSTRAINT PK_stg_orders
        PRIMARY KEY (order_id)
);
GO
/*================================================================
  SECTION 02 — ORDERS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  Create the typed order-level table, then load timestamps from
  raw.orders. The primary key ensures one row per order. The checks
  cover row count, uniqueness, data types and missing timestamps.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 02_load_stg_orders.sql
  PURPOSE : Load converted order data into the staging table
==============================================================*/

INSERT INTO stg.orders
(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    order_id,
    customer_id,
    order_status,

    CONVERT(DATETIME2(0), order_purchase_timestamp),
    CONVERT(DATETIME2(0), order_approved_at),
    CONVERT(DATETIME2(0), order_delivered_carrier_date),
    CONVERT(DATETIME2(0), order_delivered_customer_date),
    CONVERT(DATETIME2(0), order_estimated_delivery_date)

FROM raw.orders;
GO

-- Check the loaded row count and confirm that each order_id is unique.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM stg.orders;

-- Confirm that the staging columns have the intended SQL Server data types.
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'orders'
ORDER BY ORDINAL_POSITION;

SELECT
    COUNT(*) AS total_orders,

    SUM(CASE WHEN order_approved_at IS NULL
        THEN 1 ELSE 0 END) AS missing_approval,

    SUM(CASE WHEN order_delivered_carrier_date IS NULL
        THEN 1 ELSE 0 END) AS missing_carrier_date,

    SUM(CASE WHEN order_delivered_customer_date IS NULL
        THEN 1 ELSE 0 END) AS missing_delivery_date

FROM stg.orders;

GO

/*================================================================
  SECTION 03 — ORDER ITEMS: TABLE STRUCTURE
  ----------------------------------------------------------------
  One order can contain multiple items. Therefore, the composite
  primary key is (order_id, order_item_id). Convert numeric and
  date fields, then check uniqueness and zero freight observations.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 03_create_stg_order_items.sql
  PURPOSE : Create cleaned staging table for order items

  SOURCE  : raw.order_items
  TARGET  : stg.order_items
==============================================================*/

CREATE TABLE stg.order_items
(
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,
    shipping_limit_date DATETIME2(0) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    freight_value DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_stg_order_items
        PRIMARY KEY (order_id, order_item_id)
);
GO
/*================================================================
  SECTION 04 — ORDER ITEMS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  One order can contain multiple items. Therefore, the composite
  primary key is (order_id, order_item_id). Convert numeric and
  date fields, then check uniqueness and zero freight observations.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 04_load_stg_order_items.sql
  PURPOSE : Load converted order item data into staging
==============================================================*/

INSERT INTO stg.order_items
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    order_id,
    CONVERT(INT, order_item_id),
    product_id,
    seller_id,
    CONVERT(DATETIME2(0), shipping_limit_date),
    CONVERT(DECIMAL(18,2), price),
    CONVERT(DECIMAL(18,2), freight_value)
FROM raw.order_items;
GO

-- Check the loaded row count and confirm that each order_id is unique.
-- Check total rows, distinct orders and uniqueness of the composite order-item key.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT CONCAT(order_id, '|', order_item_id))
        AS unique_order_items,
    COUNT(*) -
    COUNT(DISTINCT CONCAT(order_id, '|', order_item_id))
        AS duplicate_order_items
FROM stg.order_items;

SELECT
    COUNT(*) AS zero_freight_records
FROM stg.order_items
WHERE freight_value = 0;

-- Confirm that the staging columns have the intended SQL Server data types.
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'order_items'
ORDER BY ORDINAL_POSITION;

GO

/*================================================================
  SECTION 05 — ORDER PAYMENTS: TABLE STRUCTURE
  ----------------------------------------------------------------
  One order can have multiple payment records. The composite key
  (order_id, payment_sequential) identifies each payment row.
  Validate uniqueness and the previously identified zero values.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 05_create_stg_order_payments.sql
  PURPOSE : Create cleaned staging table for order payments

  SOURCE  : raw.order_payments
  TARGET  : stg.order_payments
==============================================================*/

CREATE TABLE stg.order_payments
(
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_installments INT NOT NULL,
    payment_value DECIMAL(18,2) NOT NULL,

    CONSTRAINT PK_stg_order_payments
        PRIMARY KEY (order_id, payment_sequential)
);
GO
/*================================================================
  SECTION 06 — ORDER PAYMENTS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  One order can have multiple payment records. The composite key
  (order_id, payment_sequential) identifies each payment row.
  Validate uniqueness and the previously identified zero values.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 06_load_stg_order_payments.sql
  PURPOSE : Load converted payment data into staging
==============================================================*/

INSERT INTO stg.order_payments
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    order_id,
    CONVERT(INT, payment_sequential),
    payment_type,
    CONVERT(INT, payment_installments),
    CONVERT(DECIMAL(18,2), payment_value)
FROM raw.order_payments;
GO

-- Check the loaded row count and confirm that each order_id is unique.
-- Check total rows and uniqueness of the composite payment key.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT CONCAT(order_id, '|', payment_sequential))
        AS unique_payment_records,
    COUNT(*) -
    COUNT(DISTINCT CONCAT(order_id, '|', payment_sequential))
        AS duplicate_payment_records
FROM stg.order_payments;

SELECT
    SUM(CASE WHEN payment_value = 0
        THEN 1 ELSE 0 END) AS zero_payment_values,

    SUM(CASE WHEN payment_installments = 0
        THEN 1 ELSE 0 END) AS zero_installments

FROM stg.order_payments;

-- Confirm that the staging columns have the intended SQL Server data types.
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'stg'
  AND TABLE_NAME = 'order_payments'
ORDER BY ORDINAL_POSITION;

GO

/*================================================================
  SECTION 07 — CUSTOMERS: TABLE STRUCTURE
  ----------------------------------------------------------------
  Use customer_id as the row key. Keep customer_unique_id because
  it identifies the same actual customer across order-specific
  records. Validate IDs, missing values and ZIP-prefix length.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 07_create_stg_customers.sql
  PURPOSE : Create cleaned staging table for customers

  SOURCE  : raw.customers
  TARGET  : stg.customers
==============================================================*/

CREATE TABLE stg.customers
(
    customer_id VARCHAR(32) NOT NULL,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix VARCHAR(5) NOT NULL,
    customer_city VARCHAR(100) NOT NULL,
    customer_state CHAR(2) NOT NULL,

    CONSTRAINT PK_stg_customers
        PRIMARY KEY (customer_id)
);
GO
/*================================================================
  SECTION 08 — CUSTOMERS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  Use customer_id as the row key. Keep customer_unique_id because
  it identifies the same actual customer across order-specific
  records. Validate IDs, missing values and ZIP-prefix length.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 08_load_stg_customers.sql
  PURPOSE : Load converted customer data into staging
==============================================================*/

INSERT INTO stg.customers
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM raw.customers;
GO

-- Confirm customer_id uniqueness and distinguish customer records from actual customers.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_actual_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customer_ids
FROM stg.customers;

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END)
        AS missing_unique_id,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END)
        AS missing_zip,
    SUM(CASE WHEN customer_city IS NULL OR LTRIM(RTRIM(customer_city)) = ''
        THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN customer_state IS NULL OR LTRIM(RTRIM(customer_state)) = ''
        THEN 1 ELSE 0 END) AS missing_state
FROM stg.customers;

SELECT
    COUNT(*) AS total_records,
    MIN(LEN(customer_zip_code_prefix)) AS minimum_zip_length,
    MAX(LEN(customer_zip_code_prefix)) AS maximum_zip_length
FROM stg.customers;

GO

/*================================================================
  SECTION 09 — SELLERS: TABLE STRUCTURE
  ----------------------------------------------------------------
  Use seller_id as the primary key. Validate uniqueness, missing
  values and ZIP-prefix length.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 09_create_stg_sellers.sql
  PURPOSE : Create cleaned staging table for sellers

  SOURCE  : raw.sellers
  TARGET  : stg.sellers
==============================================================*/

CREATE TABLE stg.sellers
(
    seller_id VARCHAR(32) NOT NULL,
    seller_zip_code_prefix VARCHAR(5) NOT NULL,
    seller_city VARCHAR(100) NOT NULL,
    seller_state CHAR(2) NOT NULL,

    CONSTRAINT PK_stg_sellers
        PRIMARY KEY (seller_id)
);
GO
/*================================================================
  SECTION 10 — SELLERS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  Use seller_id as the primary key. Validate uniqueness, missing
  values and ZIP-prefix length.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 10_load_stg_sellers.sql
  PURPOSE : Load converted seller data into staging
==============================================================*/

INSERT INTO stg.sellers
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM raw.sellers;
GO

-- Confirm seller_id uniqueness.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT seller_id) AS unique_sellers,
    COUNT(*) - COUNT(DISTINCT seller_id) AS duplicate_sellers
FROM stg.sellers;

SELECT
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END)
        AS missing_seller_id,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END)
        AS missing_zip,
    SUM(CASE WHEN seller_city IS NULL OR LTRIM(RTRIM(seller_city)) = ''
        THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN seller_state IS NULL OR LTRIM(RTRIM(seller_state)) = ''
        THEN 1 ELSE 0 END) AS missing_state
FROM stg.sellers;

SELECT
    COUNT(*) AS total_records,
    MIN(LEN(seller_zip_code_prefix)) AS minimum_zip_length,
    MAX(LEN(seller_zip_code_prefix)) AS maximum_zip_length
FROM stg.sellers;

GO

/*================================================================
  SECTION 11 — PRODUCTS: TABLE STRUCTURE
  ----------------------------------------------------------------
  Descriptive and physical product attributes can be NULL in the
  source, so these columns remain nullable. The source misspellings
  product_name_lenght and product_description_lenght are mapped
  to corrected staging column names.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 11_create_stg_products.sql
  PURPOSE : Create cleaned staging table for products

  SOURCE  : raw.products
  TARGET  : stg.products
==============================================================*/

CREATE TABLE stg.products
(
    product_id VARCHAR(32) NOT NULL,
    product_category_name VARCHAR(100) NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL,

    CONSTRAINT PK_stg_products
        PRIMARY KEY (product_id)
);
GO
/*================================================================
  SECTION 12 — PRODUCTS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  Descriptive and physical product attributes can be NULL in the
  source, so these columns remain nullable. The source misspellings
  product_name_lenght and product_description_lenght are mapped
  to corrected staging column names.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 12_load_stg_products.sql
  PURPOSE : Load and convert product data into staging

  SOURCE  : raw.products
  TARGET  : stg.products
==============================================================*/

INSERT INTO stg.products
(
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    product_id,
    product_category_name,
    CONVERT(INT, product_name_lenght),
    CONVERT(INT, product_description_lenght),
    CONVERT(INT, product_photos_qty),
    CONVERT(INT, product_weight_g),
    CONVERT(INT, product_length_cm),
    CONVERT(INT, product_height_cm),
    CONVERT(INT, product_width_cm)
FROM raw.products;
GO

-- Confirm product_id uniqueness.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_products
FROM stg.products;

SELECT
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN product_name_length IS NULL THEN 1 ELSE 0 END) AS missing_name_length,
    SUM(CASE WHEN product_description_length IS NULL THEN 1 ELSE 0 END) AS missing_description_length,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS missing_photos_qty,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS missing_weight,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS missing_length,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS missing_height,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS missing_width
FROM stg.products;

SELECT COUNT(*) AS zero_weight_products
FROM stg.products
WHERE product_weight_g = 0;

GO

/*================================================================
  SECTION 13 — CATEGORY TRANSLATIONS: TABLE STRUCTURE
  ----------------------------------------------------------------
  Create and populate the translation lookup table. The source
  category name is the primary key. Missing English translations
  are not fabricated or inserted.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 13_create_stg_product_category_translation.sql
  PURPOSE : Create staging table for product category translations
==============================================================*/

CREATE TABLE stg.product_category_translation
(
    product_category_name VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100) NOT NULL,

    CONSTRAINT PK_stg_product_category_translation
        PRIMARY KEY (product_category_name)
);
GO
/*================================================================
  SECTION 14 — CATEGORY TRANSLATIONS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  Create and populate the translation lookup table. The source
  category name is the primary key. Missing English translations
  are not fabricated or inserted.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 14_load_stg_product_category_translation.sql
  PURPOSE : Load product category translations into staging
==============================================================*/

INSERT INTO stg.product_category_translation
(
    product_category_name,
    product_category_name_english
)
SELECT
    product_category_name,
    product_category_name_english
FROM raw.product_category_translation;
GO

-- Confirm category key uniqueness.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_category_name) AS unique_categories,
    COUNT(*) - COUNT(DISTINCT product_category_name) AS duplicate_categories
FROM stg.product_category_translation;

SELECT
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS missing_category,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) AS missing_english_translation
FROM stg.product_category_translation;

GO

/*================================================================
  SECTION 15 — ORDER REVIEWS: TABLE STRUCTURE
  ----------------------------------------------------------------
  Use the validated composite key (review_id, order_id), because
  review_id alone is not unique. Optional comments remain nullable.
  Validate key uniqueness, missing comments and score range.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 15_create_stg_order_reviews.sql
  PURPOSE : Create cleaned staging table for order reviews
==============================================================*/

CREATE TABLE stg.order_reviews
(
    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32) NOT NULL,
    review_score INT NOT NULL,
    review_comment_title VARCHAR(1000) NULL,
    review_comment_message VARCHAR(4000) NULL,
    review_creation_date DATETIME2(0) NOT NULL,
    review_answer_timestamp DATETIME2(0) NOT NULL,

    CONSTRAINT PK_stg_order_reviews
        PRIMARY KEY (review_id, order_id)
);
GO
/*================================================================
  SECTION 16 — ORDER REVIEWS: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  Use the validated composite key (review_id, order_id), because
  review_id alone is not unique. Optional comments remain nullable.
  Validate key uniqueness, missing comments and score range.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 16_load_stg_order_reviews.sql
  PURPOSE : Load and convert order review data into staging
==============================================================*/

INSERT INTO stg.order_reviews
(
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    review_id,
    order_id,
    CONVERT(INT, review_score),
    review_comment_title,
    review_comment_message,
    CONVERT(DATETIME2(0), review_creation_date),
    CONVERT(DATETIME2(0), review_answer_timestamp)
FROM raw.order_reviews;
GO

-- Confirm total reviews and uniqueness of the validated review-order composite key.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(DISTINCT CONCAT(review_id, '|', order_id)) AS unique_review_order_pairs
FROM stg.order_reviews;

SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS missing_titles,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS missing_messages
FROM stg.order_reviews;

SELECT
    MIN(review_score) AS minimum_score,
    MAX(review_score) AS maximum_score,
    COUNT(*) AS total_records
FROM stg.order_reviews;

GO

/*================================================================
  SECTION 17 — GEOLOCATION: TABLE STRUCTURE
  ----------------------------------------------------------------
  No reliable unique row identifier was established, so this table
  has no primary key. Convert coordinates to DECIMAL(10,7), load all
  observations and validate missing values and global coordinate ranges.
================================================================*/

-- Define the structure and constraints of this staging table.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 17_create_stg_geolocation.sql
  PURPOSE : Create staging table for geolocation data
==============================================================*/

CREATE TABLE stg.geolocation
(
    geolocation_zip_code_prefix VARCHAR(5) NOT NULL,
    geolocation_lat DECIMAL(10,7) NOT NULL,
    geolocation_lng DECIMAL(10,7) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state CHAR(2) NOT NULL
);
GO
/*================================================================
  SECTION 18 — GEOLOCATION: DATA LOAD AND CHECKS
  ----------------------------------------------------------------
  No reliable unique row identifier was established, so this table
  has no primary key. Convert coordinates to DECIMAL(10,7), load all
  observations and validate missing values and global coordinate ranges.
================================================================*/

-- Insert converted source records, then run the checks below.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 18_load_stg_geolocation.sql
  PURPOSE : Load and convert geolocation data into staging

  SOURCE  : raw.geolocation
  TARGET  : stg.geolocation
==============================================================*/

INSERT INTO stg.geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT
    geolocation_zip_code_prefix,
    CONVERT(DECIMAL(10,7), geolocation_lat),
    CONVERT(DECIMAL(10,7), geolocation_lng),
    geolocation_city,
    geolocation_state
FROM raw.geolocation;
GO

-- Check for missing values after loading geolocation observations.
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS missing_zip,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS missing_latitude,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS missing_longitude,
    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS missing_state
FROM stg.geolocation;

SELECT
    MIN(geolocation_lat) AS minimum_latitude,
    MAX(geolocation_lat) AS maximum_latitude,
    MIN(geolocation_lng) AS minimum_longitude,
    MAX(geolocation_lng) AS maximum_longitude,

    SUM(CASE
        WHEN geolocation_lat < -90 OR geolocation_lat > 90
        THEN 1 ELSE 0
    END) AS invalid_latitudes,

    SUM(CASE
        WHEN geolocation_lng < -180 OR geolocation_lng > 180
        THEN 1 ELSE 0
    END) AS invalid_longitudes
FROM stg.geolocation;

GO

/*================================================================
  SECTION 19 — CROSS-TABLE RELATIONSHIP VALIDATION
  ----------------------------------------------------------------
  Run read-only LEFT JOIN checks across the staging tables. These
  identify unmatched records and ZIP-prefix references. They do
  not modify data.
================================================================*/

-- Each query reports unmatched records; zero means the relationship check passed.
/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 19_validate_staging_relationships.sql
  PURPOSE : Validate relationships between staging tables

  NOTE    : READ-ONLY diagnostic script.
==============================================================*/

-- 1. Orders -> Customers

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE
        WHEN c.customer_id IS NULL THEN 1
        ELSE 0
    END) AS orders_without_customer
FROM stg.orders o
LEFT JOIN stg.customers c
    ON o.customer_id = c.customer_id;

GO

-- 2. Order Items -> Orders

SELECT
    COUNT(*) AS total_order_items,
    SUM(CASE
        WHEN o.order_id IS NULL THEN 1
        ELSE 0
    END) AS order_items_without_order
FROM stg.order_items oi
LEFT JOIN stg.orders o
    ON oi.order_id = o.order_id;

GO

-- 3. Order Items -> Products

SELECT
    COUNT(*) AS total_order_items,
    SUM(CASE
        WHEN p.product_id IS NULL THEN 1
        ELSE 0
    END) AS order_items_without_product
FROM stg.order_items oi
LEFT JOIN stg.products p
    ON oi.product_id = p.product_id;

GO

-- 4. Order Items -> Sellers

SELECT
    COUNT(*) AS total_order_items,
    SUM(CASE
        WHEN s.seller_id IS NULL THEN 1
        ELSE 0
    END) AS order_items_without_seller
FROM stg.order_items oi
LEFT JOIN stg.sellers s
    ON oi.seller_id = s.seller_id;

GO

-- 5. Order Payments -> Orders

SELECT
    COUNT(*) AS total_payment_records,
    SUM(CASE
        WHEN o.order_id IS NULL THEN 1
        ELSE 0
    END) AS payments_without_order
FROM stg.order_payments op
LEFT JOIN stg.orders o
    ON op.order_id = o.order_id;

GO

-- 6. Order Reviews -> Orders

SELECT
    COUNT(*) AS total_review_records,
    SUM(CASE
        WHEN o.order_id IS NULL THEN 1
        ELSE 0
    END) AS reviews_without_order
FROM stg.order_reviews r
LEFT JOIN stg.orders o
    ON r.order_id = o.order_id;

GO

-- 7. Products -> Category Translations

SELECT
    COUNT(*) AS products_with_category,
    SUM(CASE
        WHEN t.product_category_name IS NULL THEN 1
        ELSE 0
    END) AS products_without_translation
FROM stg.products p
LEFT JOIN stg.product_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL;

GO

-- 8. Orders -> Order Payments
-- Identify orders without payment records

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE
        WHEN op.order_id IS NULL THEN 1
        ELSE 0
    END) AS orders_without_payment
FROM stg.orders o
LEFT JOIN
(
    SELECT DISTINCT order_id
    FROM stg.order_payments
) op
    ON o.order_id = op.order_id;

GO

-- 9. Customers -> Geolocation

SELECT
    COUNT(DISTINCT c.customer_zip_code_prefix) AS total_customer_zip_prefixes,
    COUNT(DISTINCT CASE
        WHEN g.geolocation_zip_code_prefix IS NULL
        THEN c.customer_zip_code_prefix
    END) AS unmatched_customer_zip_prefixes
FROM stg.customers c
LEFT JOIN
(
    SELECT DISTINCT geolocation_zip_code_prefix
    FROM stg.geolocation
) g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix;

GO

-- 10. Sellers -> Geolocation

SELECT
    COUNT(DISTINCT s.seller_zip_code_prefix) AS total_seller_zip_prefixes,
    COUNT(DISTINCT CASE
        WHEN g.geolocation_zip_code_prefix IS NULL
        THEN s.seller_zip_code_prefix
    END) AS unmatched_seller_zip_prefixes
FROM stg.sellers s
LEFT JOIN
(
    SELECT DISTINCT geolocation_zip_code_prefix
    FROM stg.geolocation
) g
    ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;

GO
/*================================================================
  END OF PHASE 4
  All nine staging tables have been created, loaded and checked.
  Review the query results and compare them with the documented
  findings in docs/data_quality_summary.md.
================================================================*/
