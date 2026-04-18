-- ============================================================
-- 06_s3_integration.sql
-- AWS S3 Stage Configuration for Snowflake
-- Author: Ramkumar G
-- Project: End-to-End MDS Pipeline
-- ============================================================

USE DATABASE RAW_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE COMPUTE_WH;

-- ============================================================
-- STEP 1: Create Storage Integration (IAM Role-based)
-- ============================================================

CREATE OR REPLACE STORAGE INTEGRATION s3_integration
  TYPE                      = EXTERNAL_STAGE
  STORAGE_PROVIDER          = 'S3'
  ENABLED                   = TRUE
  STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::YOUR_ACCOUNT_ID:role/snowflake-s3-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://your-bucket-name/data/');

-- Get Snowflake ARN & External ID
-- Share these with AWS IAM Trust Policy
DESC INTEGRATION s3_integration;

-- ============================================================
-- STEP 2: Create External Stage
-- ============================================================

CREATE OR REPLACE STAGE s3_raw_stage
  STORAGE_INTEGRATION = s3_integration
  URL                 = 's3://your-bucket-name/data/'
  FILE_FORMAT         = (
    TYPE                         = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER                  = 1
    NULL_IF                      = ('NULL', 'null', '')
  );

-- List files in stage
LIST @s3_raw_stage;

-- ============================================================
-- STEP 3: Load Data from S3 into Snowflake
-- ============================================================

COPY INTO RAW_DB.PUBLIC.RAW_ORDERS
FROM @s3_raw_stage/orders/
FILE_FORMAT = (
    TYPE                         = 'CSV'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER                  = 1
)
ON_ERROR = 'CONTINUE';

-- ============================================================
-- STEP 4: Verify Load
-- ============================================================

SELECT COUNT(*) AS total_rows FROM RAW_DB.PUBLIC.RAW_ORDERS;
SELECT * FROM RAW_DB.PUBLIC.RAW_ORDERS LIMIT 10;

