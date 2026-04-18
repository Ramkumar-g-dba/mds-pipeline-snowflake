-- ============================================================
-- 02_raw_layer.sql
-- RAW Layer - Source Tables (loaded by Fivetran)
-- Author: Ramkumar G
-- Project: End-to-End MDS Pipeline
-- ============================================================

USE DATABASE RAW_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- RAW TABLES (exact copy from MySQL via Fivetran)
-- ============================================================

-- Orders Table
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

-- Verify
SHOW TABLES IN DATABASE RAW_DB;

