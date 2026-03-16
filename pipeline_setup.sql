-- ============================================================
-- 01_database_setup.sql
-- Snowflake Database & Schema Setup
-- Author: Ramkumar G
-- ============================================================

-- Create Databases
CREATE DATABASE IF NOT EXISTS RAW_DB;
CREATE DATABASE IF NOT EXISTS STAGING_DB;
CREATE DATABASE IF NOT EXISTS ANALYTICS_DB;

-- Create Schemas
CREATE SCHEMA IF NOT EXISTS RAW_DB.PUBLIC;
CREATE SCHEMA IF NOT EXISTS STAGING_DB.PUBLIC;
CREATE SCHEMA IF NOT EXISTS ANALYTICS_DB.PUBLIC;

-- Create Warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH
  WAREHOUSE_SIZE = 'X-SMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- ============================================================
-- 02_raw_layer.sql
-- RAW Layer - Source tables (loaded by Fivetran)
-- ============================================================

USE DATABASE RAW_DB;
USE SCHEMA PUBLIC;

-- Orders Table (source: MySQL RDS via Fivetran)
CREATE OR REPLACE TABLE RAW_ORDERS (
    ORDER_ID        NUMBER,
    CUSTOMER_ID     NUMBER,
    PRODUCT_ID      NUMBER,
    ORDER_DATE      DATE,
    QUANTITY        NUMBER,
    UNIT_PRICE      FLOAT,
    STATUS          VARCHAR(50),
    CREATED_AT      TIMESTAMP_NTZ,
    UPDATED_AT      TIMESTAMP_NTZ
);

-- Customers Table
CREATE OR REPLACE TABLE RAW_CUSTOMERS (
    CUSTOMER_ID     NUMBER,
    FIRST_NAME      VARCHAR(100),
    LAST_NAME       VARCHAR(100),
    EMAIL           VARCHAR(200),
    CITY            VARCHAR(100),
    COUNTRY         VARCHAR(100),
    CREATED_AT      TIMESTAMP_NTZ
);

-- Products Table
CREATE OR REPLACE TABLE RAW_PRODUCTS (
    PRODUCT_ID      NUMBER,
    PRODUCT_NAME    VARCHAR(200),
    CATEGORY        VARCHAR(100),
    UNIT_COST       FLOAT,
    CREATED_AT      TIMESTAMP_NTZ
);

-- ============================================================
-- 03_staging_layer.sql
-- STAGING Layer - Cleaned & Validated Data
-- ============================================================

USE DATABASE STAGING_DB;
USE SCHEMA PUBLIC;

-- Staging Orders
CREATE OR REPLACE TABLE STG_ORDERS AS
SELECT
    ORDER_ID,
    CUSTOMER_ID,
    PRODUCT_ID,
    ORDER_DATE,
    QUANTITY,
    UNIT_PRICE,
    UPPER(TRIM(STATUS))                         AS STATUS,
    QUANTITY * UNIT_PRICE                       AS TOTAL_AMOUNT,
    CREATED_AT,
    CURRENT_TIMESTAMP()                         AS LOADED_AT
FROM RAW_DB.PUBLIC.RAW_ORDERS
WHERE ORDER_ID IS NOT NULL
  AND QUANTITY > 0
  AND UNIT_PRICE > 0;

-- Staging Customers
CREATE OR REPLACE TABLE STG_CUSTOMERS AS
SELECT
    CUSTOMER_ID,
    TRIM(FIRST_NAME)                            AS FIRST_NAME,
    TRIM(LAST_NAME)                             AS LAST_NAME,
    LOWER(TRIM(EMAIL))                          AS EMAIL,
    INITCAP(CITY)                               AS CITY,
    UPPER(COUNTRY)                              AS COUNTRY,
    CREATED_AT,
    CURRENT_TIMESTAMP()                         AS LOADED_AT
FROM RAW_DB.PUBLIC.RAW_CUSTOMERS
WHERE CUSTOMER_ID IS NOT NULL
  AND EMAIL IS NOT NULL;

-- Staging Products
CREATE OR REPLACE TABLE STG_PRODUCTS AS
SELECT
    PRODUCT_ID,
    TRIM(PRODUCT_NAME)                          AS PRODUCT_NAME,
    UPPER(CATEGORY)                             AS CATEGORY,
    UNIT_COST,
    CREATED_AT,
    CURRENT_TIMESTAMP()                         AS LOADED_AT
FROM RAW_DB.PUBLIC.RAW_PRODUCTS
WHERE PRODUCT_ID IS NOT NULL;

-- ============================================================
-- 04_star_schema.sql
-- ANALYTICS Layer - Star Schema (Fact + Dimension Tables)
-- ============================================================

USE DATABASE ANALYTICS_DB;
USE SCHEMA PUBLIC;

-- Dimension: Date
CREATE OR REPLACE TABLE DIM_DATE AS
SELECT
    TO_NUMBER(TO_CHAR(DATEADD(DAY, SEQ4(), '2020-01-01'), 'YYYYMMDD'))  AS DATE_KEY,
    DATEADD(DAY, SEQ4(), '2020-01-01')                                   AS FULL_DATE,
    YEAR(DATEADD(DAY, SEQ4(), '2020-01-01'))                             AS YEAR,
    MONTH(DATEADD(DAY, SEQ4(), '2020-01-01'))                            AS MONTH,
    MONTHNAME(DATEADD(DAY, SEQ4(), '2020-01-01'))                        AS MONTH_NAME,
    QUARTER(DATEADD(DAY, SEQ4(), '2020-01-01'))                          AS QUARTER,
    DAYOFWEEK(DATEADD(DAY, SEQ4(), '2020-01-01'))                        AS DAY_OF_WEEK,
    DAYNAME(DATEADD(DAY, SEQ4(), '2020-01-01'))                          AS DAY_NAME
FROM TABLE(GENERATOR(ROWCOUNT => 1826));  -- 5 years

-- Dimension: Customer
CREATE OR REPLACE TABLE DIM_CUSTOMER AS
SELECT
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    FIRST_NAME || ' ' || LAST_NAME              AS FULL_NAME,
    EMAIL,
    CITY,
    COUNTRY,
    CREATED_AT
FROM STAGING_DB.PUBLIC.STG_CUSTOMERS;

-- Dimension: Product
CREATE OR REPLACE TABLE DIM_PRODUCT AS
SELECT
    PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    UNIT_COST
FROM STAGING_DB.PUBLIC.STG_PRODUCTS;

-- Fact: Sales
CREATE OR REPLACE TABLE FACT_SALES AS
SELECT
    o.ORDER_ID,
    o.CUSTOMER_ID,
    o.PRODUCT_ID,
    TO_NUMBER(TO_CHAR(o.ORDER_DATE, 'YYYYMMDD'))  AS DATE_KEY,
    o.QUANTITY,
    o.UNIT_PRICE,
    o.TOTAL_AMOUNT                                AS TOTAL_REVENUE,
    o.STATUS
FROM STAGING_DB.PUBLIC.STG_ORDERS o;

-- ============================================================
-- 05_streams_tasks.sql
-- Snowflake Streams & Tasks for Automation
-- ============================================================

USE DATABASE RAW_DB;
USE SCHEMA PUBLIC;

-- Stream: Capture incremental changes on RAW_ORDERS
CREATE OR REPLACE STREAM orders_stream
ON TABLE RAW_ORDERS
APPEND_ONLY = TRUE;

-- Task: Load new orders from Stream into Staging every 5 minutes
CREATE OR REPLACE TASK load_staging_orders
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '5 MINUTE'
WHEN
  SYSTEM$STREAM_HAS_DATA('RAW_DB.PUBLIC.ORDERS_STREAM')
AS
  INSERT INTO STAGING_DB.PUBLIC.STG_ORDERS (
    ORDER_ID, CUSTOMER_ID, PRODUCT_ID,
    ORDER_DATE, QUANTITY, UNIT_PRICE,
    STATUS, TOTAL_AMOUNT, CREATED_AT, LOADED_AT
  )
  SELECT
    ORDER_ID, CUSTOMER_ID, PRODUCT_ID,
    ORDER_DATE, QUANTITY, UNIT_PRICE,
    UPPER(TRIM(STATUS)),
    QUANTITY * UNIT_PRICE,
    CREATED_AT,
    CURRENT_TIMESTAMP()
  FROM RAW_DB.PUBLIC.ORDERS_STREAM
  WHERE METADATA$ACTION = 'INSERT'
    AND QUANTITY > 0
    AND UNIT_PRICE > 0;

-- Enable the Task
ALTER TASK load_staging_orders RESUME;

-- ============================================================
-- 06_s3_integration.sql
-- AWS S3 Stage Configuration for Snowflake
-- ============================================================

USE DATABASE RAW_DB;
USE SCHEMA PUBLIC;

-- Create Storage Integration (IAM Role-based)
CREATE OR REPLACE STORAGE INTEGRATION s3_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::YOUR_ACCOUNT_ID:role/snowflake-s3-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://your-bucket-name/data/');

-- Describe integration to get Snowflake AWS ARN & External ID
DESC INTEGRATION s3_integration;

-- Create External Stage
CREATE OR REPLACE STAGE s3_raw_stage
  STORAGE_INTEGRATION = s3_integration
  URL = 's3://your-bucket-name/data/'
  FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

-- Load data from S3 into Snowflake table
COPY INTO RAW_DB.PUBLIC.RAW_ORDERS
FROM @s3_raw_stage/orders/
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';

-- Verify load
SELECT * FROM RAW_DB.PUBLIC.RAW_ORDERS LIMIT 10;
