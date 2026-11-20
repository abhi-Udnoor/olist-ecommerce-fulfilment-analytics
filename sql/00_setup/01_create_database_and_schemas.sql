/*==============================================================
  PROJECT  : Olist Logistics SLA & Customer Retention Analytics
  SCRIPT  : 01_create_database_and_schemas.sql
  PURPOSE : Create the project database and logical schemas
==============================================================*/

-- 1. Create database if it does not already exist

IF DB_ID(N'OlistAnalytics') IS NULL
BEGIN
    CREATE DATABASE OlistAnalytics;
END;
GO

-- 2. Switch to the project database

USE OlistAnalytics;
GO

-- 3. Create logical schemas

IF SCHEMA_ID(N'raw') IS NULL
    EXEC(N'CREATE SCHEMA raw AUTHORIZATION dbo;');
GO

IF SCHEMA_ID(N'stg') IS NULL
    EXEC(N'CREATE SCHEMA stg AUTHORIZATION dbo;');
GO

IF SCHEMA_ID(N'mart') IS NULL
    EXEC(N'CREATE SCHEMA mart AUTHORIZATION dbo;');
GO

IF SCHEMA_ID(N'audit') IS NULL
    EXEC(N'CREATE SCHEMA audit AUTHORIZATION dbo;');
GO

-- 4. Create a file ingestion audit table

IF OBJECT_ID(N'audit.FileLoadLog', N'U') IS NULL
BEGIN
    CREATE TABLE audit.FileLoadLog
    (
        file_load_id BIGINT IDENTITY(1,1) PRIMARY KEY,

        source_file_name NVARCHAR(260) NOT NULL,

        target_schema SYSNAME NOT NULL,

        target_table SYSNAME NOT NULL,

        rows_loaded BIGINT NOT NULL,

        load_status VARCHAR(20) NOT NULL,

        loaded_at_utc DATETIME2(0)
            NOT NULL DEFAULT SYSUTCDATETIME(),

        notes NVARCHAR(1000) NULL,

        CONSTRAINT CK_FileLoadLog_Status
        CHECK (load_status IN ('SUCCEEDED', 'FAILED'))
    );
END;
GO

-- 5. Verify database and schemas

SELECT
    name AS schema_name
FROM sys.schemas
WHERE name IN ('raw', 'stg', 'mart', 'audit')
ORDER BY name;
GO

SELECT
    DB_NAME() AS current_database;
GO
