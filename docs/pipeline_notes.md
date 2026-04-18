# Pipeline Implementation Notes

## Project: End-to-End Modern Data Stack Pipeline

---

## Overview

This project builds a complete ELT pipeline from AWS RDS MySQL to Power BI using Snowflake as the cloud data warehouse.

---

## Layer Explanation

### RAW Layer (RAW_DB)
- Exact copy of source data from MySQL via Fivetran
- No transformations applied
- Serves as source of truth

### STAGING Layer (STAGING_DB)
- Data cleaned and validated
- Transformations applied:
  - STATUS → UPPERCASE + TRIM
  - EMAIL → LOWERCASE + TRIM
  - CITY → INITCAP
  - COUNTRY → UPPERCASE
  - TOTAL_AMOUNT calculated (QUANTITY × UNIT_PRICE)
- NULL checks applied

### ANALYTICS Layer (ANALYTICS_DB)
- Star Schema with Fact + Dimension tables
- Optimized for BI queries
- Connected to Power BI via DirectQuery

---

## Fivetran Setup

### Connection details:
- Source: AWS RDS (MySQL)
- Connector type: Amazon Aurora MySQL
- Sync method: Binary Log (CDC)
- Schedule: Every 5 minutes
- Tables synced: orders, customers, products

### Key settings:
- Update method: Read Changes via Binary Log
- Schema naming: Source naming (preserves original names)
- Destination: Snowflake → DBT_DB

---

## Snowflake Streams & Tasks

### Stream (orders_stream):
- Type: APPEND_ONLY
- Tracks: New INSERT operations only
- Purpose: Detect new orders in RAW layer

### Task (load_staging_orders):
- Schedule: Every 5 minutes
- Condition: SYSTEM$STREAM_HAS_DATA()
- Action: Load new orders into STAGING layer

---

## Power BI Dashboard

### Connection:
- Type: DirectQuery (live data)
- Server: Snowflake account URL
- Database: ANALYTICS_DB

### Relationships:
- FACT_SALES[CUSTOMER_ID] → DIM_CUSTOMER[CUSTOMER_ID]
- FACT_SALES[PRODUCT_ID] → DIM_PRODUCT[PRODUCT_ID]
- FACT_SALES[DATE_KEY] → DIM_DATE[DATE_KEY]

### Visuals:
- Card: Total Revenue (₹1.78L)
- Bar Chart: Revenue by Product
- Line Chart: Monthly Sales Trend
- Donut Chart: Order Status

---

## Key Learnings

| Topic | Learning |
|-------|---------|
| Fivetran CDC | Binary log captures changes efficiently |
| Snowflake Streams | APPEND_ONLY for insert-only pipelines |
| Star Schema | Fact + Dimensions optimize BI queries |
| DirectQuery | Live data without refresh delays |
| IAM Roles | Secure S3 access without credentials |
