-- ============================================================
-- 05_streams_tasks.sql
-- Snowflake Streams & Tasks for Automation
-- Author: Ramkumar G
-- Project: End-to-End MDS Pipeline
-- ============================================================

USE DATABASE RAW_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- STREAM: Capture incremental changes on RAW_ORDERS
-- ============================================================

CREATE OR REPLACE STREAM orders_stream
ON TABLE RAW_ORDERS
APPEND_ONLY = TRUE;

-- Verify stream created
SHOW STREAMS;

-- Check if stream has data
SELECT SYSTEM$STREAM_HAS_DATA('RAW_DB.PUBLIC.ORDERS_STREAM');

-- ============================================================
-- TASK: Load new orders into Staging every 5 minutes
-- ============================================================

CREATE OR REPLACE TASK load_staging_orders
  WAREHOUSE = COMPUTE_WH
  SCHEDULE  = '5 MINUTE'
WHEN
  SYSTEM$STREAM_HAS_DATA('RAW_DB.PUBLIC.ORDERS_STREAM')
AS
  INSERT INTO STAGING_DB.PUBLIC.STG_ORDERS (
    ORDER_ID, CUSTOMER_ID, PRODUCT_ID,
    ORDER_DATE, QUANTITY, UNIT_PRICE,
    STATUS, TOTAL_AMOUNT, CREATED_AT, LOADED_AT
  )
  SELECT
    ORDER_ID,
    CUSTOMER_ID,
    PRODUCT_ID,
    ORDER_DATE,
    QUANTITY,
    UNIT_PRICE,
    UPPER(TRIM(STATUS)),
    QUANTITY * UNIT_PRICE,
    CREATED_AT,
    CURRENT_TIMESTAMP()
  FROM RAW_DB.PUBLIC.ORDERS_STREAM
  WHERE METADATA$ACTION = 'INSERT'
    AND QUANTITY         > 0
    AND UNIT_PRICE       > 0;

-- Enable the Task (RESUME to activate)
ALTER TASK load_staging_orders RESUME;

-- Verify task is running
SHOW TASKS;

-- Check task history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;

