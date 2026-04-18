-- ============================================================
-- 01_database_setup.sql
-- Snowflake Database & Schema Setup
-- Author: Ramkumar G
-- Project: End-to-End MDS Pipeline
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
  AUTO_SUSPEND   = 60
  AUTO_RESUME    = TRUE;

-- Use Warehouse
USE WAREHOUSE COMPUTE_WH;

-- Verify
SHOW DATABASES;
SHOW WAREHOUSES;

