
USE OlistAnalytics;
GO

-- ============================================================
-- SCRIPT 03: LOAD NINE CSV FILES INTO RAW TABLES
-- ============================================================

-- 1. Orders

TRUNCATE TABLE raw.orders;
GO

BULK INSERT raw.orders
FROM 'C:\data\olist\olist_orders_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 2. Customers

TRUNCATE TABLE raw.customers;
GO

BULK INSERT raw.customers
FROM 'C:\data\olist\olist_customers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 3. Sellers

TRUNCATE TABLE raw.sellers;
GO

BULK INSERT raw.sellers
FROM 'C:\data\olist\olist_sellers_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 4. Products

TRUNCATE TABLE raw.products;
GO

BULK INSERT raw.products
FROM 'C:\data\olist\olist_products_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 5. Product Category Translation

TRUNCATE TABLE raw.product_category_translation;
GO

BULK INSERT raw.product_category_translation
FROM 'C:\data\olist\product_category_name_translation.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 6. Order Items

TRUNCATE TABLE raw.order_items;
GO

BULK INSERT raw.order_items
FROM 'C:\data\olist\olist_order_items_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 7. Order Payments

TRUNCATE TABLE raw.order_payments;
GO

BULK INSERT raw.order_payments
FROM 'C:\data\olist\olist_order_payments_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 8. Order Reviews

TRUNCATE TABLE raw.order_reviews;
GO

BULK INSERT raw.order_reviews
FROM 'C:\data\olist\olist_order_reviews_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0d0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO


-- 9. Geolocation (largest file)

TRUNCATE TABLE raw.geolocation;
GO

BULK INSERT raw.geolocation
FROM 'C:\data\olist\olist_geolocation_dataset.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    TABLOCK,
    CODEPAGE = '65001'
);
GO
