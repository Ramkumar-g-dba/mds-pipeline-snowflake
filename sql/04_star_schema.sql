-- ============================================================
-- 04_star_schema.sql
-- ANALYTICS Layer - Star Schema (Fact + Dimension Tables)
-- Author: Ramkumar G
-- Project: End-to-End MDS Pipeline
-- ============================================================

USE DATABASE ANALYTICS_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- DIMENSION TABLES
-- ============================================================

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
    FIRST_NAME || ' ' || LAST_NAME  AS FULL_NAME,
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

-- ============================================================
-- FACT TABLE
-- ============================================================

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
-- VERIFY ANALYTICS DATA
-- ============================================================
SELECT COUNT(*) FROM DIM_DATE;
SELECT COUNT(*) FROM DIM_CUSTOMER;
SELECT COUNT(*) FROM DIM_PRODUCT;
SELECT COUNT(*) FROM FACT_SALES;

-- Sample analytics query
SELECT
    p.PRODUCT_NAME,
    SUM(f.TOTAL_REVENUE) AS REVENUE
FROM FACT_SALES f
JOIN DIM_PRODUCT p ON f.PRODUCT_ID = p.PRODUCT_ID
GROUP BY p.PRODUCT_NAME
ORDER BY REVENUE DESC;

