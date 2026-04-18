-- ============================================================
-- 03_staging_layer.sql
-- STAGING Layer - Cleaned & Validated Data
-- Author: Ramkumar G
-- Project: End-to-End MDS Pipeline
-- ============================================================

USE DATABASE STAGING_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- STAGING TABLES (cleaned from RAW layer)
-- ============================================================

-- Staging Orders
CREATE OR REPLACE TABLE STG_ORDERS AS
SELECT
    ORDER_ID,
    CUSTOMER_ID,
    PRODUCT_ID,
    ORDER_DATE,
    QUANTITY,
    UNIT_PRICE,
    UPPER(TRIM(STATUS))          AS STATUS,
    QUANTITY * UNIT_PRICE        AS TOTAL_AMOUNT,
    CREATED_AT,
    CURRENT_TIMESTAMP()          AS LOADED_AT
FROM RAW_DB.PUBLIC.RAW_ORDERS
WHERE ORDER_ID   IS NOT NULL
  AND QUANTITY   > 0
  AND UNIT_PRICE > 0;

-- Staging Customers
CREATE OR REPLACE TABLE STG_CUSTOMERS AS
SELECT
    CUSTOMER_ID,
    TRIM(FIRST_NAME)             AS FIRST_NAME,
    TRIM(LAST_NAME)              AS LAST_NAME,
    LOWER(TRIM(EMAIL))           AS EMAIL,
    INITCAP(CITY)                AS CITY,
    UPPER(COUNTRY)               AS COUNTRY,
    CREATED_AT,
    CURRENT_TIMESTAMP()          AS LOADED_AT
FROM RAW_DB.PUBLIC.RAW_CUSTOMERS
WHERE CUSTOMER_ID IS NOT NULL
  AND EMAIL       IS NOT NULL;

-- Staging Products
CREATE OR REPLACE TABLE STG_PRODUCTS AS
SELECT
    PRODUCT_ID,
    TRIM(PRODUCT_NAME)           AS PRODUCT_NAME,
    UPPER(CATEGORY)              AS CATEGORY,
    UNIT_COST,
    CREATED_AT,
    CURRENT_TIMESTAMP()          AS LOADED_AT
FROM RAW_DB.PUBLIC.RAW_PRODUCTS
WHERE PRODUCT_ID IS NOT NULL;

-- ============================================================
-- VERIFY STAGING DATA
-- ============================================================
SELECT COUNT(*) AS order_count    FROM STG_ORDERS;
SELECT COUNT(*) AS customer_count FROM STG_CUSTOMERS;
SELECT COUNT(*) AS product_count  FROM STG_PRODUCTS;

SELECT * FROM STG_ORDERS    LIMIT 5;
SELECT * FROM STG_CUSTOMERS LIMIT 5;
SELECT * FROM STG_PRODUCTS  LIMIT 5;

