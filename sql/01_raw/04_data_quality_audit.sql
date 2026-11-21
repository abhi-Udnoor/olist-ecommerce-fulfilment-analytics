/*====================================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 04_data_quality_audit.sql
  PURPOSE : Profile raw data quality before any cleaning or transformation

  BEFORE RUNNING:
  1. Run 03_validate_raw_ingestion.sql.
  2. Confirm all nine expected tables exist in the raw schema.

  IMPORTANT:
  - READ-ONLY: this script does not update, delete or clean raw records.
  - A flagged row is a finding to investigate, not automatic proof of error.
  - Run each section separately if you want to inspect results gradually.
  - Keep the result sets and document material findings before cleaning.
====================================================================*/

USE OlistAnalytics;
GO

SET NOCOUNT ON;
GO

/*====================================================================
  1. CANDIDATE KEY: MISSING VALUES AND DUPLICATES

  WHY THIS CHECK EXISTS:
  Every table has a grain (what one row represents). Candidate keys
  help us test whether that grain is respected.

  HOW TO READ THE RESULTS:
  - missing_or_blank_key_rows: rows without a usable candidate key.
  - duplicate_key_groups: key combinations appearing more than once.

  IMPORTANT:
  These are candidate keys, not constraints being enforced here.
  Review the findings before deciding whether a key is truly unique.
====================================================================*/

SELECT
    'raw.orders' AS table_name,
    'order_id' AS candidate_key,
    (SELECT COUNT_BIG(*)
     FROM raw.orders
     WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL) AS missing_or_blank_key_rows,
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(order_id)) AS order_id
         FROM raw.orders
         WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(order_id))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates) AS duplicate_key_groups

UNION ALL

SELECT
    'raw.customers',
    'customer_id',
    (SELECT COUNT_BIG(*)
     FROM raw.customers
     WHERE NULLIF(LTRIM(RTRIM(customer_id)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(customer_id)) AS customer_id
         FROM raw.customers
         WHERE NULLIF(LTRIM(RTRIM(customer_id)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(customer_id))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)

UNION ALL

SELECT
    'raw.order_items',
    'order_id + order_item_id',
    (SELECT COUNT_BIG(*)
     FROM raw.order_items
     WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
        OR NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(order_id)) AS order_id,
                LTRIM(RTRIM(order_item_id)) AS order_item_id
         FROM raw.order_items
         WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
           AND NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(order_id)), LTRIM(RTRIM(order_item_id))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)

UNION ALL

SELECT
    'raw.order_payments',
    'order_id + payment_sequential',
    (SELECT COUNT_BIG(*)
     FROM raw.order_payments
     WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
        OR NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(order_id)) AS order_id,
                LTRIM(RTRIM(payment_sequential)) AS payment_sequential
         FROM raw.order_payments
         WHERE NULLIF(LTRIM(RTRIM(order_id)), '') IS NOT NULL
           AND NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(order_id)), LTRIM(RTRIM(payment_sequential))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)

UNION ALL

SELECT
    'raw.order_reviews',
    'review_id (candidate; validate)',
    (SELECT COUNT_BIG(*)
     FROM raw.order_reviews
     WHERE NULLIF(LTRIM(RTRIM(review_id)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(review_id)) AS review_id
         FROM raw.order_reviews
         WHERE NULLIF(LTRIM(RTRIM(review_id)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(review_id))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)

UNION ALL

SELECT
    'raw.products',
    'product_id',
    (SELECT COUNT_BIG(*)
     FROM raw.products
     WHERE NULLIF(LTRIM(RTRIM(product_id)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(product_id)) AS product_id
         FROM raw.products
         WHERE NULLIF(LTRIM(RTRIM(product_id)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(product_id))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)

UNION ALL

SELECT
    'raw.sellers',
    'seller_id',
    (SELECT COUNT_BIG(*)
     FROM raw.sellers
     WHERE NULLIF(LTRIM(RTRIM(seller_id)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(seller_id)) AS seller_id
         FROM raw.sellers
         WHERE NULLIF(LTRIM(RTRIM(seller_id)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(seller_id))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)

UNION ALL

SELECT
    'raw.product_category_translation',
    'product_category_name',
    (SELECT COUNT_BIG(*)
     FROM raw.product_category_translation
     WHERE NULLIF(LTRIM(RTRIM(product_category_name)), '') IS NULL),
    (SELECT COUNT_BIG(*)
     FROM
     (
         SELECT LTRIM(RTRIM(product_category_name)) AS product_category_name
         FROM raw.product_category_translation
         WHERE NULLIF(LTRIM(RTRIM(product_category_name)), '') IS NOT NULL
         GROUP BY LTRIM(RTRIM(product_category_name))
         HAVING COUNT_BIG(*) > 1
     ) AS duplicates)
ORDER BY table_name;
GO

/*====================================================================
  2. GEOLOCATION GRAIN CHECKS

  WHY THIS CHECK EXISTS:
  Geolocation does not have an obvious single-column primary key.
  A ZIP prefix can legitimately have several coordinate observations.

  We therefore report:
  - Exact duplicate full rows.
  - ZIP prefixes appearing more than once.

  Repeated ZIP prefixes are not automatically errors. They show that
  ZIP prefix alone must not be treated as a unique key.
====================================================================*/

SELECT
    COUNT_BIG(*) AS exact_duplicate_row_groups
FROM
(
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM raw.geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT_BIG(*) > 1
) AS duplicate_rows;
GO

SELECT
    COUNT_BIG(*) AS zip_prefixes_with_multiple_observations
FROM
(
    SELECT geolocation_zip_code_prefix
    FROM raw.geolocation
    WHERE NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), '') IS NOT NULL
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT_BIG(*) > 1
) AS repeated_zip_prefixes;
GO

/*====================================================================
  3. ORPHAN FOREIGN-KEY CHECKS

  WHY THIS CHECK EXISTS:
  A child row contains an orphan reference when it points to a parent
  record that does not exist.

  Example:
  An order item has product_id = 'ABC', but no matching product exists.

  Blank child keys are not counted as orphans here. Missing-key rows
  are covered by Section 1 and the NULL profile in Section 5.

  TRIM NOTE:
  LTRIM/RTRIM is used for matching so accidental outer spaces do not
  create a false orphan. Those spaces are reported in Section 4.
====================================================================*/

SELECT
    'orders.customer_id -> customers.customer_id' AS relationship_name,
    COUNT_BIG(*) AS orphan_rows
FROM raw.orders AS child
WHERE NULLIF(LTRIM(RTRIM(child.customer_id)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.customers AS parent
      WHERE LTRIM(RTRIM(parent.customer_id)) = LTRIM(RTRIM(child.customer_id))
  )

UNION ALL

SELECT
    'order_items.order_id -> orders.order_id',
    COUNT_BIG(*)
FROM raw.order_items AS child
WHERE NULLIF(LTRIM(RTRIM(child.order_id)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.orders AS parent
      WHERE LTRIM(RTRIM(parent.order_id)) = LTRIM(RTRIM(child.order_id))
  )

UNION ALL

SELECT
    'order_items.product_id -> products.product_id',
    COUNT_BIG(*)
FROM raw.order_items AS child
WHERE NULLIF(LTRIM(RTRIM(child.product_id)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.products AS parent
      WHERE LTRIM(RTRIM(parent.product_id)) = LTRIM(RTRIM(child.product_id))
  )

UNION ALL

SELECT
    'order_items.seller_id -> sellers.seller_id',
    COUNT_BIG(*)
FROM raw.order_items AS child
WHERE NULLIF(LTRIM(RTRIM(child.seller_id)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.sellers AS parent
      WHERE LTRIM(RTRIM(parent.seller_id)) = LTRIM(RTRIM(child.seller_id))
  )

UNION ALL

SELECT
    'order_payments.order_id -> orders.order_id',
    COUNT_BIG(*)
FROM raw.order_payments AS child
WHERE NULLIF(LTRIM(RTRIM(child.order_id)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.orders AS parent
      WHERE LTRIM(RTRIM(parent.order_id)) = LTRIM(RTRIM(child.order_id))
  )

UNION ALL

SELECT
    'order_reviews.order_id -> orders.order_id',
    COUNT_BIG(*)
FROM raw.order_reviews AS child
WHERE NULLIF(LTRIM(RTRIM(child.order_id)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.orders AS parent
      WHERE LTRIM(RTRIM(parent.order_id)) = LTRIM(RTRIM(child.order_id))
  )

UNION ALL

SELECT
    'customers ZIP -> geolocation ZIP',
    COUNT_BIG(*)
FROM raw.customers AS child
WHERE NULLIF(LTRIM(RTRIM(child.customer_zip_code_prefix)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.geolocation AS parent
      WHERE LTRIM(RTRIM(parent.geolocation_zip_code_prefix)) = LTRIM(RTRIM(child.customer_zip_code_prefix))
  )

UNION ALL

SELECT
    'sellers ZIP -> geolocation ZIP',
    COUNT_BIG(*)
FROM raw.sellers AS child
WHERE NULLIF(LTRIM(RTRIM(child.seller_zip_code_prefix)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.geolocation AS parent
      WHERE LTRIM(RTRIM(parent.geolocation_zip_code_prefix)) = LTRIM(RTRIM(child.seller_zip_code_prefix))
  )

UNION ALL

SELECT
    'products category -> category translation',
    COUNT_BIG(*)
FROM raw.products AS child
WHERE NULLIF(LTRIM(RTRIM(child.product_category_name)), '') IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.product_category_translation AS parent
      WHERE LTRIM(RTRIM(parent.product_category_name)) = LTRIM(RTRIM(child.product_category_name))
  )
ORDER BY relationship_name;
GO

/*====================================================================
  4. KEY STRING LENGTH AND FORMATTING CHECKS

  WHY THIS CHECK EXISTS:
  Identifiers and ZIP prefixes have expected formats. For example,
  Olist UUID-like identifiers are normally 32 characters and Brazilian
  ZIP-code prefixes are 5 characters.

  This query reports unexpected lengths and leading/trailing spaces.
  It does not change or remove those spaces.

  A wrong length is a finding to investigate, not an automatic reason
  to delete a record.
====================================================================*/

SELECT
    field_name,
    expected_length,
    COUNT_BIG(*) AS nonblank_rows,
    SUM(CASE
            WHEN LEN(LTRIM(RTRIM(raw_value))) <> expected_length
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS wrong_length_rows,
    SUM(CASE
            WHEN DATALENGTH(raw_value) <> DATALENGTH(LTRIM(RTRIM(raw_value)))
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS surrounding_space_rows,
    MIN(LEN(LTRIM(RTRIM(raw_value)))) AS minimum_length,
    MAX(LEN(LTRIM(RTRIM(raw_value)))) AS maximum_length
FROM
(
    SELECT 'orders.order_id' AS field_name, 32 AS expected_length, order_id AS raw_value FROM raw.orders
    UNION ALL SELECT 'orders.customer_id', 32, customer_id FROM raw.orders
    UNION ALL SELECT 'customers.customer_id', 32, customer_id FROM raw.customers
    UNION ALL SELECT 'customers.customer_unique_id', 32, customer_unique_id FROM raw.customers
    UNION ALL SELECT 'customers.customer_zip_code_prefix', 5, customer_zip_code_prefix FROM raw.customers
    UNION ALL SELECT 'customers.customer_state', 2, customer_state FROM raw.customers
    UNION ALL SELECT 'order_items.order_id', 32, order_id FROM raw.order_items
    UNION ALL SELECT 'order_items.product_id', 32, product_id FROM raw.order_items
    UNION ALL SELECT 'order_items.seller_id', 32, seller_id FROM raw.order_items
    UNION ALL SELECT 'order_payments.order_id', 32, order_id FROM raw.order_payments
    UNION ALL SELECT 'order_reviews.review_id', 32, review_id FROM raw.order_reviews
    UNION ALL SELECT 'order_reviews.order_id', 32, order_id FROM raw.order_reviews
    UNION ALL SELECT 'products.product_id', 32, product_id FROM raw.products
    UNION ALL SELECT 'sellers.seller_id', 32, seller_id FROM raw.sellers
    UNION ALL SELECT 'sellers.seller_zip_code_prefix', 5, seller_zip_code_prefix FROM raw.sellers
    UNION ALL SELECT 'sellers.seller_state', 2, seller_state FROM raw.sellers
    UNION ALL SELECT 'geolocation.geolocation_zip_code_prefix', 5, geolocation_zip_code_prefix FROM raw.geolocation
    UNION ALL SELECT 'geolocation.geolocation_state', 2, geolocation_state FROM raw.geolocation
) AS string_fields
WHERE NULLIF(LTRIM(RTRIM(raw_value)), '') IS NOT NULL
GROUP BY field_name, expected_length
ORDER BY field_name;
GO

/*====================================================================
  5. NULL AND BLANK DISTRIBUTION

  WHY THIS CHECK EXISTS:
  Missing information can affect KPI denominators and analysis.
  NULL means no value is stored. Blank means a text field contains
  an empty string or spaces.

  HOW TO READ THE RESULTS:
  - total_rows: rows in the source table.
  - null_rows: actual SQL NULL values in the column.
  - blank_rows: non-NULL text values containing only spaces/empty text.

  This is written as explicit SELECT statements with UNION ALL so the
  checks are visible and easy to modify. No dynamic SQL or cursor is used.
====================================================================*/


-- orders: NULL and blank counts for each source column
SELECT 'orders' AS table_name,
       'order_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'customer_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN customer_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN customer_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(customer_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'order_status' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_status IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_status IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_status)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'order_purchase_timestamp' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_purchase_timestamp IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_purchase_timestamp IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_purchase_timestamp)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'order_approved_at' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_approved_at IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_approved_at IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_approved_at)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'order_delivered_carrier_date' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_delivered_carrier_date IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'order_delivered_customer_date' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_delivered_customer_date IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_delivered_customer_date IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL
SELECT 'orders' AS table_name,
       'order_estimated_delivery_date' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_estimated_delivery_date IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_estimated_delivery_date IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.orders
UNION ALL

-- customers: NULL and blank counts for each source column
SELECT 'customers' AS table_name,
       'customer_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN customer_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN customer_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(customer_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.customers
UNION ALL
SELECT 'customers' AS table_name,
       'customer_unique_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN customer_unique_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN customer_unique_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(customer_unique_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.customers
UNION ALL
SELECT 'customers' AS table_name,
       'customer_zip_code_prefix' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN customer_zip_code_prefix IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.customers
UNION ALL
SELECT 'customers' AS table_name,
       'customer_city' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN customer_city IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN customer_city IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(customer_city)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.customers
UNION ALL
SELECT 'customers' AS table_name,
       'customer_state' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN customer_state IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN customer_state IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(customer_state)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.customers
UNION ALL

-- order_items: NULL and blank counts for each source column
SELECT 'order_items' AS table_name,
       'order_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL
SELECT 'order_items' AS table_name,
       'order_item_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_item_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_item_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_item_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL
SELECT 'order_items' AS table_name,
       'product_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL
SELECT 'order_items' AS table_name,
       'seller_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN seller_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN seller_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(seller_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL
SELECT 'order_items' AS table_name,
       'shipping_limit_date' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN shipping_limit_date IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN shipping_limit_date IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(shipping_limit_date)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL
SELECT 'order_items' AS table_name,
       'price' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN price IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN price IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(price)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL
SELECT 'order_items' AS table_name,
       'freight_value' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN freight_value IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN freight_value IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(freight_value)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_items
UNION ALL

-- order_payments: NULL and blank counts for each source column
SELECT 'order_payments' AS table_name,
       'order_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_payments
UNION ALL
SELECT 'order_payments' AS table_name,
       'payment_sequential' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN payment_sequential IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN payment_sequential IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(payment_sequential)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_payments
UNION ALL
SELECT 'order_payments' AS table_name,
       'payment_type' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN payment_type IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN payment_type IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(payment_type)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_payments
UNION ALL
SELECT 'order_payments' AS table_name,
       'payment_installments' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN payment_installments IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN payment_installments IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(payment_installments)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_payments
UNION ALL
SELECT 'order_payments' AS table_name,
       'payment_value' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN payment_value IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN payment_value IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(payment_value)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_payments
UNION ALL

-- order_reviews: NULL and blank counts for each source column
SELECT 'order_reviews' AS table_name,
       'review_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN review_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN review_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(review_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name,
       'order_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN order_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN order_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(order_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name,
       'review_score' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN review_score IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN review_score IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(review_score)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name,
       'review_comment_title' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN review_comment_title IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN review_comment_title IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(review_comment_title)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name,
       'review_comment_message' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN review_comment_message IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN review_comment_message IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(review_comment_message)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name,
       'review_creation_date' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN review_creation_date IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN review_creation_date IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(review_creation_date)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL
SELECT 'order_reviews' AS table_name,
       'review_answer_timestamp' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN review_answer_timestamp IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN review_answer_timestamp IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(review_answer_timestamp)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.order_reviews
UNION ALL

-- products: NULL and blank counts for each source column
SELECT 'products' AS table_name,
       'product_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_category_name' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_category_name IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_category_name IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_category_name)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_name_lenght' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_name_lenght IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_name_lenght IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_name_lenght)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_description_lenght' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_description_lenght IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_description_lenght IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_description_lenght)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_photos_qty' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_photos_qty IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_photos_qty IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_photos_qty)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_weight_g' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_weight_g IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_weight_g IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_weight_g)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_length_cm' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_length_cm IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_length_cm IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_length_cm)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_height_cm' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_height_cm IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_height_cm IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_height_cm)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL
SELECT 'products' AS table_name,
       'product_width_cm' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_width_cm IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_width_cm IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_width_cm)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.products
UNION ALL

-- sellers: NULL and blank counts for each source column
SELECT 'sellers' AS table_name,
       'seller_id' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN seller_id IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN seller_id IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(seller_id)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.sellers
UNION ALL
SELECT 'sellers' AS table_name,
       'seller_zip_code_prefix' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN seller_zip_code_prefix IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.sellers
UNION ALL
SELECT 'sellers' AS table_name,
       'seller_city' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN seller_city IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN seller_city IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(seller_city)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.sellers
UNION ALL
SELECT 'sellers' AS table_name,
       'seller_state' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN seller_state IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN seller_state IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(seller_state)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.sellers
UNION ALL

-- geolocation: NULL and blank counts for each source column
SELECT 'geolocation' AS table_name,
       'geolocation_zip_code_prefix' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN geolocation_zip_code_prefix IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(geolocation_zip_code_prefix)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.geolocation
UNION ALL
SELECT 'geolocation' AS table_name,
       'geolocation_lat' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN geolocation_lat IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN geolocation_lat IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(geolocation_lat)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.geolocation
UNION ALL
SELECT 'geolocation' AS table_name,
       'geolocation_lng' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN geolocation_lng IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN geolocation_lng IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(geolocation_lng)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.geolocation
UNION ALL
SELECT 'geolocation' AS table_name,
       'geolocation_city' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN geolocation_city IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN geolocation_city IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(geolocation_city)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.geolocation
UNION ALL
SELECT 'geolocation' AS table_name,
       'geolocation_state' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN geolocation_state IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN geolocation_state IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(geolocation_state)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.geolocation
UNION ALL

-- product_category_translation: NULL and blank counts for each source column
SELECT 'product_category_translation' AS table_name,
       'product_category_name' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_category_name IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_category_name IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_category_name)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.product_category_translation
UNION ALL
SELECT 'product_category_translation' AS table_name,
       'product_category_name_english' AS column_name,
       COUNT_BIG(*) AS total_rows,
       SUM(CASE WHEN product_category_name_english IS NULL THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS null_rows,
       SUM(CASE WHEN product_category_name_english IS NOT NULL
                     AND NULLIF(LTRIM(RTRIM(product_category_name_english)), '') IS NULL
                THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0) END) AS blank_rows
FROM raw.product_category_translation


ORDER BY table_name, column_name;
GO

/*====================================================================
  6. TIMESTAMP FORMAT AND CONVERSION CHECKS

  WHY THIS CHECK EXISTS:
  Raw timestamps are stored as text. Before converting them in staging,
  we must know which values are missing and which nonblank values cannot
  be interpreted as SQL datetime values.

  TRY_CONVERT attempts the conversion without stopping the audit when
  an individual value is invalid.
====================================================================*/

SELECT
    field_name,
    COUNT_BIG(*) AS total_rows,
    SUM(CASE
            WHEN NULLIF(LTRIM(RTRIM(raw_value)), '') IS NULL
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS missing_rows,
    SUM(CASE
            WHEN NULLIF(LTRIM(RTRIM(raw_value)), '') IS NOT NULL
             AND TRY_CONVERT(DATETIME2(0), raw_value, 120) IS NULL
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS invalid_timestamp_rows
FROM
(
    SELECT 'orders.order_purchase_timestamp' AS field_name, order_purchase_timestamp AS raw_value FROM raw.orders
    UNION ALL SELECT 'orders.order_approved_at', order_approved_at FROM raw.orders
    UNION ALL SELECT 'orders.order_delivered_carrier_date', order_delivered_carrier_date FROM raw.orders
    UNION ALL SELECT 'orders.order_delivered_customer_date', order_delivered_customer_date FROM raw.orders
    UNION ALL SELECT 'orders.order_estimated_delivery_date', order_estimated_delivery_date FROM raw.orders
    UNION ALL SELECT 'order_items.shipping_limit_date', shipping_limit_date FROM raw.order_items
    UNION ALL SELECT 'order_reviews.review_creation_date', review_creation_date FROM raw.order_reviews
    UNION ALL SELECT 'order_reviews.review_answer_timestamp', review_answer_timestamp FROM raw.order_reviews
) AS timestamp_fields
GROUP BY field_name
ORDER BY field_name;
GO

/*====================================================================
  7. CHRONOLOGICAL TIMESTAMP ANOMALIES

  WHY THIS CHECK EXISTS:
  A timestamp can be valid in format but still be impossible in the
  business process. For example, carrier handover should not happen
  before an order is purchased or approved.

  Only rows where both timestamps can be converted are compared.
  These checks flag potential anomalies; they do not modify records.
====================================================================*/

;WITH ParsedOrders AS
(
    SELECT
        TRY_CONVERT(DATETIME2(0), order_purchase_timestamp, 120) AS purchase_ts,
        TRY_CONVERT(DATETIME2(0), order_approved_at, 120) AS approved_ts,
        TRY_CONVERT(DATETIME2(0), order_delivered_carrier_date, 120) AS carrier_ts,
        TRY_CONVERT(DATETIME2(0), order_delivered_customer_date, 120) AS delivered_ts,
        TRY_CONVERT(DATETIME2(0), order_estimated_delivery_date, 120) AS estimated_ts
    FROM raw.orders
)
SELECT
    'Approval before purchase' AS anomaly,
    COUNT_BIG(*) AS affected_rows
FROM ParsedOrders
WHERE purchase_ts IS NOT NULL
  AND approved_ts IS NOT NULL
  AND approved_ts < purchase_ts

UNION ALL

SELECT 'Carrier handover before purchase', COUNT_BIG(*)
FROM ParsedOrders
WHERE purchase_ts IS NOT NULL
  AND carrier_ts IS NOT NULL
  AND carrier_ts < purchase_ts

UNION ALL

SELECT 'Carrier handover before approval', COUNT_BIG(*)
FROM ParsedOrders
WHERE approved_ts IS NOT NULL
  AND carrier_ts IS NOT NULL
  AND carrier_ts < approved_ts

UNION ALL

SELECT 'Customer delivery before purchase', COUNT_BIG(*)
FROM ParsedOrders
WHERE purchase_ts IS NOT NULL
  AND delivered_ts IS NOT NULL
  AND delivered_ts < purchase_ts

UNION ALL

SELECT 'Customer delivery before carrier handover', COUNT_BIG(*)
FROM ParsedOrders
WHERE carrier_ts IS NOT NULL
  AND delivered_ts IS NOT NULL
  AND delivered_ts < carrier_ts

UNION ALL

SELECT 'Estimated delivery date before purchase', COUNT_BIG(*)
FROM ParsedOrders
WHERE purchase_ts IS NOT NULL
  AND estimated_ts IS NOT NULL
  AND estimated_ts < purchase_ts
ORDER BY anomaly;
GO

-- Check whether shipping deadlines fall before order purchase.
SELECT
    COUNT_BIG(*) AS shipping_limit_before_purchase_rows
FROM raw.order_items AS item
INNER JOIN raw.orders AS orders
    ON LTRIM(RTRIM(orders.order_id)) = LTRIM(RTRIM(item.order_id))
WHERE TRY_CONVERT(DATETIME2(0), item.shipping_limit_date, 120) IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), orders.order_purchase_timestamp, 120) IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), item.shipping_limit_date, 120)
      < TRY_CONVERT(DATETIME2(0), orders.order_purchase_timestamp, 120);
GO

-- Check whether a review answer timestamp is earlier than review creation.
SELECT
    COUNT_BIG(*) AS review_answer_before_creation_rows
FROM raw.order_reviews
WHERE TRY_CONVERT(DATETIME2(0), review_creation_date, 120) IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), review_answer_timestamp, 120) IS NOT NULL
  AND TRY_CONVERT(DATETIME2(0), review_answer_timestamp, 120)
      < TRY_CONVERT(DATETIME2(0), review_creation_date, 120);
GO

/*====================================================================
  8. NUMERIC CONVERSION, ZERO AND NEGATIVE VALUE CHECKS

  WHY THIS CHECK EXISTS:
  Numeric source fields are also stored as text in raw. We must identify
  nonnumeric strings and inspect zero/negative values before conversion.

  IMPORTANT:
  Zero and negative values are reported as flags, not automatically
  labelled as errors. For example, zero freight may be a valid case.
====================================================================*/

SELECT
    field_name,
    COUNT_BIG(*) AS nonblank_rows,
    SUM(CASE
            WHEN TRY_CONVERT(DECIMAL(18,4), raw_value) IS NULL
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS non_numeric_rows,
    SUM(CASE
            WHEN TRY_CONVERT(DECIMAL(18,4), raw_value) = 0
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS zero_rows,
    SUM(CASE
            WHEN TRY_CONVERT(DECIMAL(18,4), raw_value) < 0
            THEN CONVERT(BIGINT, 1) ELSE CONVERT(BIGINT, 0)
        END) AS negative_rows
FROM
(
    SELECT 'order_items.order_item_id' AS field_name, order_item_id AS raw_value FROM raw.order_items
    UNION ALL SELECT 'order_items.price', price FROM raw.order_items
    UNION ALL SELECT 'order_items.freight_value', freight_value FROM raw.order_items
    UNION ALL SELECT 'order_payments.payment_sequential', payment_sequential FROM raw.order_payments
    UNION ALL SELECT 'order_payments.payment_installments', payment_installments FROM raw.order_payments
    UNION ALL SELECT 'order_payments.payment_value', payment_value FROM raw.order_payments
    UNION ALL SELECT 'order_reviews.review_score', review_score FROM raw.order_reviews
    UNION ALL SELECT 'products.product_name_lenght', product_name_lenght FROM raw.products
    UNION ALL SELECT 'products.product_description_lenght', product_description_lenght FROM raw.products
    UNION ALL SELECT 'products.product_photos_qty', product_photos_qty FROM raw.products
    UNION ALL SELECT 'products.product_weight_g', product_weight_g FROM raw.products
    UNION ALL SELECT 'products.product_length_cm', product_length_cm FROM raw.products
    UNION ALL SELECT 'products.product_height_cm', product_height_cm FROM raw.products
    UNION ALL SELECT 'products.product_width_cm', product_width_cm FROM raw.products
) AS numeric_fields
WHERE NULLIF(LTRIM(RTRIM(raw_value)), '') IS NOT NULL
GROUP BY field_name
ORDER BY field_name;
GO

-- Review scores must be integers from 1 through 5.
-- This flags values outside the valid range; nonnumeric values are reported above.
SELECT
    COUNT_BIG(*) AS review_scores_outside_1_to_5
FROM raw.order_reviews
WHERE TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(review_score)), '')) IS NOT NULL
  AND TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(review_score)), '')) NOT BETWEEN 1 AND 5;
GO

-- Negative latitude/longitude values are valid in Brazil.
-- Only values outside the global coordinate ranges are flagged.
SELECT
    'Latitude outside -90 to 90' AS check_name,
    COUNT_BIG(*) AS affected_rows
FROM raw.geolocation
WHERE TRY_CONVERT(DECIMAL(10,7), NULLIF(LTRIM(RTRIM(geolocation_lat)), '')) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,7), NULLIF(LTRIM(RTRIM(geolocation_lat)), '')) NOT BETWEEN -90 AND 90

UNION ALL

SELECT
    'Longitude outside -180 to 180',
    COUNT_BIG(*)
FROM raw.geolocation
WHERE TRY_CONVERT(DECIMAL(10,7), NULLIF(LTRIM(RTRIM(geolocation_lng)), '')) IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,7), NULLIF(LTRIM(RTRIM(geolocation_lng)), '')) NOT BETWEEN -180 AND 180
ORDER BY check_name;
GO

-- Report nonblank latitude and longitude values that cannot be converted.
SELECT
    'Latitude non-numeric values' AS check_name,
    COUNT_BIG(*) AS affected_rows
FROM raw.geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lat)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,7), geolocation_lat) IS NULL

UNION ALL

SELECT
    'Longitude non-numeric values',
    COUNT_BIG(*)
FROM raw.geolocation
WHERE NULLIF(LTRIM(RTRIM(geolocation_lng)), '') IS NOT NULL
  AND TRY_CONVERT(DECIMAL(10,7), geolocation_lng) IS NULL
ORDER BY check_name;
GO

/*====================================================================
  END OF AUDIT

  No raw data has been changed.
  Review the results, investigate material findings and document the
  decisions before creating any staging or cleaning scripts.
====================================================================*/
