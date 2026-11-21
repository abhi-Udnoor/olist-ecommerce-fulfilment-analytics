/*==============================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 03_validate_raw_ingestion.sql
  PURPOSE : Check expected raw tables and report loaded row counts
==============================================================*/

USE OlistAnalytics;
GO

-- 1. List the nine tables expected in the raw schema.
DECLARE @ExpectedTables TABLE
(
    table_name SYSNAME PRIMARY KEY
);

INSERT INTO @ExpectedTables (table_name)
VALUES
    ('orders'),
    ('customers'),
    ('order_items'),
    ('order_payments'),
    ('order_reviews'),
    ('products'),
    ('sellers'),
    ('geolocation'),
    ('product_category_translation');

-- 2. Check that every expected table exists in the raw schema.
SELECT
    e.table_name,
    CASE
        WHEN t.TABLE_NAME IS NOT NULL THEN 'PRESENT'
        ELSE 'MISSING'
    END AS table_status
FROM @ExpectedTables AS e
LEFT JOIN INFORMATION_SCHEMA.TABLES AS t
    ON  t.TABLE_SCHEMA = 'raw'
    AND t.TABLE_NAME = e.table_name
    AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY e.table_name;

-- 3. Stop here if one or more expected raw tables are missing.
IF EXISTS
(
    SELECT 1
    FROM @ExpectedTables AS e
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM INFORMATION_SCHEMA.TABLES AS t
        WHERE t.TABLE_SCHEMA = 'raw'
          AND t.TABLE_NAME = e.table_name
          AND t.TABLE_TYPE = 'BASE TABLE'
    )
)
BEGIN
    ;THROW 51001,
        'Raw ingestion validation stopped: one or more expected tables are missing from the raw schema.',
        1;
END;

-- 4. Report the number of rows currently loaded in each raw table.
SELECT 'orders' AS table_name, COUNT_BIG(*) AS rows_loaded
FROM raw.orders
UNION ALL
SELECT 'customers', COUNT_BIG(*)
FROM raw.customers
UNION ALL
SELECT 'order_items', COUNT_BIG(*)
FROM raw.order_items
UNION ALL
SELECT 'order_payments', COUNT_BIG(*)
FROM raw.order_payments
UNION ALL
SELECT 'order_reviews', COUNT_BIG(*)
FROM raw.order_reviews
UNION ALL
SELECT 'products', COUNT_BIG(*)
FROM raw.products
UNION ALL
SELECT 'sellers', COUNT_BIG(*)
FROM raw.sellers
UNION ALL
SELECT 'geolocation', COUNT_BIG(*)
FROM raw.geolocation
UNION ALL
SELECT 'product_category_translation', COUNT_BIG(*)
FROM raw.product_category_translation
ORDER BY table_name;
GO

-- STEP 5: Inspect column counts

SELECT
    TABLE_NAME,
    COUNT(*) AS total_columns

FROM INFORMATION_SCHEMA.COLUMNS

WHERE TABLE_SCHEMA = 'raw'

GROUP BY TABLE_NAME

ORDER BY TABLE_NAME;





