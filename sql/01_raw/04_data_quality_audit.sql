/*====================================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 04_data_quality_audit.sql
  PURPOSE : Profile raw data quality before cleaning or transformation

  BEFORE RUNNING:
  1. Run 03_validate_raw_ingestion.sql.
  2. Confirm all nine expected tables exist in the raw schema.

 CHECKS :
      1. Candidate key missing values and duplicates
      2. Geolocation duplicate observations
      3. Foreign key relationships
      4. ID and ZIP-code formatting
      5. NULL and blank values
      6. Timestamp conversion validity
      7. Missing timestamps by order status
      8. Chronological timestamp anomalies
      9. Numeric conversion and suspicious zero values
     10. Product attribute completeness
     11. Unmatched ZIP prefixes and product categories
     12. Review table composite-key validation

  IMPORTANT:
  - This is a diagnostic script, not a cleaning script.
  - READ-ONLY: Do not use UPDATE, DELETE or INSERT statements here.
  - A flagged row is a finding to investigate, not automatic proof of error.
  - Run each section separately to inspect results gradually.
  - Document important findings before proceeding to data cleaning.
====================================================================*/

USE OlistAnalytics;
GO


/*====================================================================
  1. CANDIDATE KEY CHECKS
     Check whether important identifiers contain NULLs or duplicates.
====================================================================*/

-- Customers
SELECT
    'customers' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_keys,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_keys
FROM raw.customers;


-- Orders
SELECT
    'orders' AS table_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS missing_keys,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_keys
FROM raw.orders;


-- Order items: composite key
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE
        WHEN order_id IS NULL OR order_item_id IS NULL
        THEN 1 ELSE 0
    END) AS missing_keys
FROM raw.order_items;

SELECT
    COUNT(*) AS duplicate_key_groups
FROM
(
    SELECT order_id, order_item_id
    FROM raw.order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS duplicates;


-- Order payments: composite key
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE
        WHEN order_id IS NULL OR payment_sequential IS NULL
        THEN 1 ELSE 0
    END) AS missing_keys
FROM raw.order_payments;

SELECT
    COUNT(*) AS duplicate_key_groups
FROM
(
    SELECT order_id, payment_sequential
    FROM raw.order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS duplicates;


-- Order reviews: review_id alone may not be unique
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    COUNT(*) - COUNT(DISTINCT review_id) AS repeated_review_id_occurrences
FROM raw.order_reviews;


-- Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM raw.products;


-- Sellers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids
FROM raw.sellers;


/*====================================================================
  2. GEOLOCATION DUPLICATE CHECK
     Check repeated observations and multiple locations per ZIP prefix.
====================================================================*/

-- Exact duplicate groups across all geolocation columns
SELECT
    COUNT(*) AS exact_duplicate_row_groups
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
    HAVING COUNT(*) > 1
) AS duplicates;


-- ZIP prefixes with multiple geolocation observations
SELECT
    COUNT(*) AS zip_prefixes_with_multiple_observations
FROM
(
    SELECT geolocation_zip_code_prefix
    FROM raw.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(*) > 1
) AS multiple_locations;


/*====================================================================
  3. FOREIGN KEY RELATIONSHIP CHECKS
     Identify records that do not have a matching parent record.
====================================================================*/

-- Orders without a matching customer
SELECT COUNT(*) AS orphan_orders
FROM raw.orders AS o
LEFT JOIN raw.customers AS c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Order items without a matching order
SELECT COUNT(*) AS orphan_order_items
FROM raw.order_items AS oi
LEFT JOIN raw.orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Order items without a matching product
SELECT COUNT(*) AS orphan_products
FROM raw.order_items AS oi
LEFT JOIN raw.products AS p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Order items without a matching seller
SELECT COUNT(*) AS orphan_sellers
FROM raw.order_items AS oi
LEFT JOIN raw.sellers AS s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Payments without a matching order
SELECT COUNT(*) AS orphan_payments
FROM raw.order_payments AS op
LEFT JOIN raw.orders AS o
    ON op.order_id = o.order_id
WHERE o.order_id IS NULL;


-- Reviews without a matching order
SELECT COUNT(*) AS orphan_reviews
FROM raw.order_reviews AS r
LEFT JOIN raw.orders AS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


/*====================================================================
  4. ID AND ZIP-CODE FORMATTING
     Check unexpected string lengths and leading/trailing spaces.
====================================================================*/

SELECT
    'customers.customer_id' AS column_name,
    COUNT(*) AS total_rows,
    MIN(LEN(customer_id)) AS min_length,
    MAX(LEN(customer_id)) AS max_length
FROM raw.customers

UNION ALL

SELECT
    'customers.customer_zip_code_prefix',
    COUNT(*),
    MIN(LEN(customer_zip_code_prefix)),
    MAX(LEN(customer_zip_code_prefix))
FROM raw.customers

UNION ALL

SELECT
    'orders.order_id',
    COUNT(*),
    MIN(LEN(order_id)),
    MAX(LEN(order_id))
FROM raw.orders

UNION ALL

SELECT
    'products.product_id',
    COUNT(*),
    MIN(LEN(product_id)),
    MAX(LEN(product_id))
FROM raw.products

UNION ALL

SELECT
    'sellers.seller_id',
    COUNT(*),
    MIN(LEN(seller_id)),
    MAX(LEN(seller_id))
FROM raw.sellers;


-- Check leading/trailing spaces in important identifiers
SELECT
    COUNT(*) AS customer_ids_with_extra_spaces
FROM raw.customers
WHERE customer_id <> LTRIM(RTRIM(customer_id));

SELECT
    COUNT(*) AS order_ids_with_extra_spaces
FROM raw.orders
WHERE order_id <> LTRIM(RTRIM(order_id));


/*====================================================================
  5. NULL AND BLANK VALUE CHECKS
     Inspect important optional and business-critical attributes.
====================================================================*/

-- Orders
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END)
        AS missing_approval_timestamp,
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)
        AS missing_carrier_timestamp,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)
        AS missing_delivery_timestamp
FROM raw.orders;


-- Reviews
SELECT
    COUNT(*) AS total_reviews,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END)
        AS missing_review_messages,
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_message)) = ''
        THEN 1 ELSE 0 END) AS blank_review_messages,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END)
        AS missing_review_titles,
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_title)) = ''
        THEN 1 ELSE 0 END) AS blank_review_titles
FROM raw.order_reviews;


-- Products
SELECT
    COUNT(*) AS total_products,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END)
        AS missing_categories,
    SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END)
        AS missing_name_lengths,
    SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END)
        AS missing_description_lengths,
    SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END)
        AS missing_photo_counts,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END)
        AS missing_weights,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END)
        AS missing_lengths,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END)
        AS missing_heights,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END)
        AS missing_widths
FROM raw.products;


/*====================================================================
  6. TIMESTAMP CONVERSION CHECK
     Raw timestamps are strings. Test whether they convert to DATETIME2.
====================================================================*/

SELECT
    'order_purchase_timestamp' AS column_name,
    COUNT(*) AS total_rows,
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_purchase_timestamp) IS NULL
         AND order_purchase_timestamp IS NOT NULL
        THEN 1 ELSE 0
    END) AS invalid_timestamps
FROM raw.orders

UNION ALL

SELECT
    'order_approved_at',
    COUNT(*),
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_approved_at) IS NULL
         AND order_approved_at IS NOT NULL
        THEN 1 ELSE 0
    END)
FROM raw.orders

UNION ALL

SELECT
    'order_delivered_carrier_date',
    COUNT(*),
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_delivered_carrier_date) IS NULL
         AND order_delivered_carrier_date IS NOT NULL
        THEN 1 ELSE 0
    END)
FROM raw.orders

UNION ALL

SELECT
    'order_delivered_customer_date',
    COUNT(*),
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_delivered_customer_date) IS NULL
         AND order_delivered_customer_date IS NOT NULL
        THEN 1 ELSE 0
    END)
FROM raw.orders

UNION ALL

SELECT
    'order_estimated_delivery_date',
    COUNT(*),
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_estimated_delivery_date) IS NULL
         AND order_estimated_delivery_date IS NOT NULL
        THEN 1 ELSE 0
    END)
FROM raw.orders;


/*====================================================================
  7. MISSING TIMESTAMPS BY ORDER STATUS
     Understand whether missing dates are explained by order lifecycle.
====================================================================*/

SELECT
    order_status,
    COUNT(*) AS total_orders,

    SUM(CASE WHEN order_approved_at IS NULL
        THEN 1 ELSE 0 END) AS missing_approval,

    SUM(CASE WHEN order_delivered_carrier_date IS NULL
        THEN 1 ELSE 0 END) AS missing_carrier,

    SUM(CASE WHEN order_delivered_customer_date IS NULL
        THEN 1 ELSE 0 END) AS missing_customer_delivery

FROM raw.orders
GROUP BY order_status
ORDER BY order_status;


/*====================================================================
  8. CHRONOLOGICAL TIMESTAMP ANOMALIES
     Check whether order events happened in the expected sequence.
====================================================================*/

SELECT
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_approved_at)
           < TRY_CONVERT(DATETIME2, order_purchase_timestamp)
        THEN 1 ELSE 0
    END) AS approval_before_purchase,

    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_delivered_carrier_date)
           < TRY_CONVERT(DATETIME2, order_approved_at)
        THEN 1 ELSE 0
    END) AS carrier_before_approval,

    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_delivered_carrier_date)
           < TRY_CONVERT(DATETIME2, order_purchase_timestamp)
        THEN 1 ELSE 0
    END) AS carrier_before_purchase,

    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_delivered_customer_date)
           < TRY_CONVERT(DATETIME2, order_delivered_carrier_date)
        THEN 1 ELSE 0
    END) AS delivery_before_carrier,

    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, order_estimated_delivery_date)
           < TRY_CONVERT(DATETIME2, order_purchase_timestamp)
        THEN 1 ELSE 0
    END) AS estimated_date_before_purchase

FROM raw.orders;


/*====================================================================
  9. NUMERIC CONVERSION AND SUSPICIOUS ZERO VALUES
     Numeric-looking raw columns are stored as NVARCHAR.
     Test conversion before creating typed analytical columns.
====================================================================*/

-- Order item prices and freight
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN price IS NOT NULL
              AND TRY_CONVERT(DECIMAL(18,2), price) IS NULL
        THEN 1 ELSE 0 END) AS invalid_prices,

    SUM(CASE WHEN freight_value IS NOT NULL
              AND TRY_CONVERT(DECIMAL(18,2), freight_value) IS NULL
        THEN 1 ELSE 0 END) AS invalid_freight_values,

    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), freight_value) = 0
        THEN 1 ELSE 0 END) AS zero_freight_records

FROM raw.order_items;


-- Payment values and installments
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN payment_value IS NOT NULL
              AND TRY_CONVERT(DECIMAL(18,2), payment_value) IS NULL
        THEN 1 ELSE 0 END) AS invalid_payment_values,

    SUM(CASE WHEN payment_installments IS NOT NULL
              AND TRY_CONVERT(INT, payment_installments) IS NULL
        THEN 1 ELSE 0 END) AS invalid_installments,

    SUM(CASE WHEN TRY_CONVERT(DECIMAL(18,2), payment_value) = 0
        THEN 1 ELSE 0 END) AS zero_payment_records,

    SUM(CASE WHEN TRY_CONVERT(INT, payment_installments) = 0
        THEN 1 ELSE 0 END) AS zero_installment_records

FROM raw.order_payments;


-- Product physical measurements
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN product_weight_g IS NOT NULL
              AND TRY_CONVERT(INT, product_weight_g) IS NULL
        THEN 1 ELSE 0 END) AS invalid_weights,

    SUM(CASE WHEN product_length_cm IS NOT NULL
              AND TRY_CONVERT(INT, product_length_cm) IS NULL
        THEN 1 ELSE 0 END) AS invalid_lengths,

    SUM(CASE WHEN product_height_cm IS NOT NULL
              AND TRY_CONVERT(INT, product_height_cm) IS NULL
        THEN 1 ELSE 0 END) AS invalid_heights,

    SUM(CASE WHEN product_width_cm IS NOT NULL
              AND TRY_CONVERT(INT, product_width_cm) IS NULL
        THEN 1 ELSE 0 END) AS invalid_widths,

    SUM(CASE WHEN TRY_CONVERT(INT, product_weight_g) = 0
        THEN 1 ELSE 0 END) AS zero_weight_records

FROM raw.products;


/*====================================================================
  10. PRODUCT ATTRIBUTE COMPLETENESS
      Identify products with missing descriptive and physical attributes.
====================================================================*/

SELECT
    COUNT(*) AS total_products,

    SUM(CASE
        WHEN product_category_name IS NULL
         AND product_name_lenght IS NULL
         AND product_description_lenght IS NULL
         AND product_photos_qty IS NULL
        THEN 1 ELSE 0
    END) AS all_four_attributes_missing,

    SUM(CASE
        WHEN product_category_name IS NULL
          OR product_name_lenght IS NULL
          OR product_description_lenght IS NULL
          OR product_photos_qty IS NULL
        THEN 1 ELSE 0
    END) AS products_missing_at_least_one_attribute,

    SUM(CASE
        WHEN product_weight_g IS NULL
          OR product_length_cm IS NULL
          OR product_height_cm IS NULL
          OR product_width_cm IS NULL
        THEN 1 ELSE 0
    END) AS products_missing_any_dimension

FROM raw.products;


/*====================================================================
  11. UNMATCHED REFERENCE VALUES
      Check ZIP prefixes and product categories without a match.
====================================================================*/

-- Customer ZIP prefixes without geolocation
SELECT COUNT(*) AS unmatched_customer_zip_prefixes
FROM
(
    SELECT DISTINCT customer_zip_code_prefix
    FROM raw.customers

    EXCEPT

    SELECT DISTINCT geolocation_zip_code_prefix
    FROM raw.geolocation
) AS unmatched;


-- Seller ZIP prefixes without geolocation
SELECT COUNT(*) AS unmatched_seller_zip_prefixes
FROM
(
    SELECT DISTINCT seller_zip_code_prefix
    FROM raw.sellers

    EXCEPT

    SELECT DISTINCT geolocation_zip_code_prefix
    FROM raw.geolocation
) AS unmatched;


-- Product categories without English translation
SELECT DISTINCT
    p.product_category_name
FROM raw.products AS p
WHERE p.product_category_name IS NOT NULL
  AND NOT EXISTS
  (
      SELECT 1
      FROM raw.product_category_translation AS t
      WHERE t.product_category_name = p.product_category_name
  )
ORDER BY p.product_category_name;


/*====================================================================
  12. REVIEW TABLE COMPOSITE KEY VALIDATION
      Check uniqueness of (review_id, order_id).
====================================================================*/

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT CONCAT(review_id, '|', order_id))
        AS unique_review_order_pairs
FROM raw.order_reviews;


/*====================================================================
  END OF DATA QUALITY AUDIT

  This script does not modify raw data.
  Findings will guide Phase 4:
  Data Cleaning & Standardisation.
====================================================================*/
