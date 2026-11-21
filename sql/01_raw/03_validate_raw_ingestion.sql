/*====================================================================
  PROJECT : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 03_validate_raw_ingestion.sql
  PURPOSE : Verify expected raw tables exist before running any
            row-count queries, then inspect raw table row counts.

  IMPORTANT:
  - Run after database/schema creation, raw table creation and CSV load.
  - This script does not modify or clean raw data.
  - A non-empty table is not proof that its row count matches the CSV.
    Reconcile the results against source-file row counts separately.
====================================================================*/

USE OlistAnalytics;
GO
SET NOCOUNT ON;
GO

/*--------------------------------------------------------------------
  STEP 1: Explicit metadata check for all nine expected raw tables
--------------------------------------------------------------------*/
DECLARE @ExpectedRawTables TABLE
(
    table_name SYSNAME PRIMARY KEY
);

INSERT INTO @ExpectedRawTables (table_name)
VALUES
    (N'orders'),
    (N'customers'),
    (N'order_items'),
    (N'order_payments'),
    (N'order_reviews'),
    (N'products'),
    (N'sellers'),
    (N'geolocation'),
    (N'product_category_translation');

-- Display PRESENT / MISSING for every expected table.
-- If a table is missing from raw, show whether it exists elsewhere.
SELECT
    e.table_name AS expected_table,
    CASE
        WHEN raw_table.TABLE_NAME IS NOT NULL THEN 'PRESENT'
        ELSE 'MISSING'
    END AS raw_table_status,
    COALESCE(other_schema.TABLE_SCHEMA, N'(not found elsewhere)')
        AS found_in_other_schema
FROM @ExpectedRawTables AS e
LEFT JOIN INFORMATION_SCHEMA.TABLES AS raw_table
    ON raw_table.TABLE_SCHEMA = N'raw'
   AND raw_table.TABLE_NAME = e.table_name
   AND raw_table.TABLE_TYPE = N'BASE TABLE'
OUTER APPLY
(
    SELECT TOP (1)
        t.TABLE_SCHEMA
    FROM INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_NAME = e.table_name
      AND t.TABLE_TYPE = N'BASE TABLE'
      AND t.TABLE_SCHEMA <> N'raw'
    ORDER BY
        CASE WHEN t.TABLE_SCHEMA = N'dbo' THEN 0 ELSE 1 END,
        t.TABLE_SCHEMA
) AS other_schema
ORDER BY e.table_name;

/*--------------------------------------------------------------------
  STEP 2: Stop before row counts if any expected raw table is missing
--------------------------------------------------------------------*/
DECLARE @MissingRawTableCount INT;

SELECT
    @MissingRawTableCount = COUNT(*)
FROM @ExpectedRawTables AS e
WHERE NOT EXISTS
(
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES AS t
    WHERE t.TABLE_SCHEMA = N'raw'
      AND t.TABLE_NAME = e.table_name
      AND t.TABLE_TYPE = N'BASE TABLE'
);

IF @MissingRawTableCount > 0
BEGIN
    DECLARE @MissingTableMessage NVARCHAR(2048) =
        CONCAT(
            N'Raw ingestion validation stopped: ',
            @MissingRawTableCount,
            N' expected table(s) are missing from the raw schema. ',
            N'Review the metadata result above. Row counts were not run.'
        );

    ;THROW 51001, @MissingTableMessage, 1;
END;

/*--------------------------------------------------------------------
  STEP 3: Row counts (executed only after all nine raw tables exist)
--------------------------------------------------------------------*/
DECLARE @RawRowCounts TABLE
(
    table_name SYSNAME NOT NULL,
    rows_loaded BIGINT NOT NULL
);

INSERT INTO @RawRowCounts (table_name, rows_loaded)
SELECT N'orders', COUNT_BIG(*) FROM raw.orders
UNION ALL
SELECT N'customers', COUNT_BIG(*) FROM raw.customers
UNION ALL
SELECT N'order_items', COUNT_BIG(*) FROM raw.order_items
UNION ALL
SELECT N'order_payments', COUNT_BIG(*) FROM raw.order_payments
UNION ALL
SELECT N'order_reviews', COUNT_BIG(*) FROM raw.order_reviews
UNION ALL
SELECT N'products', COUNT_BIG(*) FROM raw.products
UNION ALL
SELECT N'sellers', COUNT_BIG(*) FROM raw.sellers
UNION ALL
SELECT N'geolocation', COUNT_BIG(*) FROM raw.geolocation
UNION ALL
SELECT N'product_category_translation', COUNT_BIG(*)
FROM raw.product_category_translation;

SELECT
    table_name,
    rows_loaded,
    CASE
        WHEN rows_loaded = 0 THEN 'EMPTY'
        ELSE 'NONEMPTY - RECONCILE TO SOURCE FILE'
    END AS load_check_status
FROM @RawRowCounts
ORDER BY table_name;
GO

/*--------------------------------------------------------------------
  STEP 4: Confirm column counts for the raw landing tables
--------------------------------------------------------------------*/
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COUNT(*) AS total_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = N'raw'
GROUP BY TABLE_SCHEMA, TABLE_NAME
ORDER BY TABLE_NAME;
GO

/*--------------------------------------------------------------------
  STEP 5: Inspect representative records and Unicode text
--------------------------------------------------------------------*/
SELECT TOP (10) * FROM raw.orders;
GO

SELECT TOP (10) * FROM raw.customers;
GO

SELECT TOP (10)
    review_id,
    order_id,
    review_score,
    review_comment_message
FROM raw.order_reviews;
GO

SELECT TOP (10) * FROM raw.geolocation;
GO

/*--------------------------------------------------------------------
  STEP 6: Source-file reconciliation

  Compare the SQL row counts above with the actual CSV data-row counts
  (excluding the header). Record the verified counts in the audit log
  only after reconciliation. This script deliberately does not label
  a merely non-empty table as SUCCEEDED.
--------------------------------------------------------------------*/

SELECT
    file_load_id,
    source_file_name,
    target_schema,
    target_table,
    rows_loaded,
    load_status,
    loaded_at_utc,
    notes
FROM audit.FileLoadLog
ORDER BY file_load_id DESC;
GO
