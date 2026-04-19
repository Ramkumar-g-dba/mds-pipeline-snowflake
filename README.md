# End-to-End Modern Data Stack (MDS) Pipeline

> **Tech Stack:** AWS RDS (MySQL) → Fivetran → Snowflake → Power BI

![Pipeline](https://img.shields.io/badge/Snowflake-Advanced-29B5E8?style=flat&logo=snowflake)
![Fivetran](https://img.shields.io/badge/Fivetran-ELT-00A1E0?style=flat)
![Power BI](https://img.shields.io/badge/PowerBI-Dashboard-F2C811?style=flat&logo=powerbi)
![AWS](https://img.shields.io/badge/AWS-RDS%20%7C%20S3-FF9900?style=flat&logo=amazonaws)

---

## Project Overview

This project demonstrates a **production-grade ELT pipeline** using modern cloud data stack tools. Data flows from a MySQL source database hosted on AWS RDS, through Fivetran for automated ingestion, into Snowflake for transformation and storage, and finally into Power BI for business reporting.

---

## Pipeline Architecture

```
AWS RDS (MySQL)
      │
      │  Fivetran (Incremental Sync)
      ▼
Snowflake — RAW Layer
      │
      │  SQL Transformations (Streams + Tasks)
      ▼
Snowflake — STAGING Layer
      │
      │  Star Schema Modeling
      ▼
Snowflake — ANALYTICS Layer
      │
      │  DirectQuery
      ▼
Power BI Dashboard
```

---

## Tech Stack

| Tool | Purpose | Level |
|------|---------|-------|
| AWS RDS (MySQL) | Source database | Intermediate |
| AWS S3 | Staging / File storage | Intermediate |
| Fivetran | Automated ELT connector | Intermediate |
| Snowflake | Cloud Data Warehouse | Advanced |
| Power BI | Business Intelligence | Intermediate |
| SQL | Transformations & Queries | Advanced |

---

## Key Features

### 1. Multi-Layer Data Architecture
- **RAW Layer** — Raw, unmodified source data loaded via Fivetran
- **STAGING Layer** — Cleaned and validated data using SQL transformations
- **ANALYTICS Layer** — Star Schema dimensional model for reporting

### 2. Snowflake Automation
- **Streams** — Capture incremental data changes (CDC)
- **Tasks** — Automate SQL transformation pipelines on schedule

### 3. Fivetran Integration
- Incremental syncs to minimize Snowflake credit usage
- Schema evolution handling without pipeline breakage

### 4. Star Schema Design
- **Fact Table** — Measurable business metrics (sales, orders, revenue)
- **Dimension Tables** — Date, Product, Customer, Region

### 5. AWS S3 Integration
- Secure data load/unload using IAM Roles and Trust Policies
- Stage configuration for bulk data operations

### 6. Power BI Dashboard
- DirectQuery mode for live data from Snowflake
- Advanced DAX measures for KPIs

---

## Project Structure

```
mds-pipeline-snowflake/
│
├── README.md
├── architecture.md
│
├── sql/
│   ├── 01_database_setup.sql       -- Create databases and schemas
│   ├── 02_raw_layer.sql            -- RAW layer tables
│   ├── 03_staging_layer.sql        -- STAGING transformations
│   ├── 04_star_schema.sql          -- ANALYTICS layer - Star Schema
│   ├── 05_streams_tasks.sql        -- Automation with Streams & Tasks
│   └── 06_s3_integration.sql       -- AWS S3 stage configuration
│
├── data/
│   ├── customers.csv               -- Sample dataset (reference only)
│   ├── products.csv                -- Sample dataset (reference only)
│   └── orders.csv                  -- Sample dataset (reference only)
│
└── docs/
    └── pipeline_notes.md           -- Implementation notes
```

> **Note on Data:** Actual data was inserted directly into MySQL tables using MySQL Workbench and hosted on AWS RDS. Fivetran then synced this data into Snowflake using CDC (binary log). The CSV files in the `data/` folder represent the same dataset in flat-file format for reference and reproducibility purposes.

---

## Setup Guide

### Prerequisites
- Snowflake account (free trial: snowflake.com)
- AWS account with RDS MySQL instance
- Fivetran account (free trial available)
- Power BI Desktop
- MySQL Workbench

### Step 1: MySQL RDS Setup
1. Create AWS RDS MySQL instance
2. Connect via MySQL Workbench
3. Create database and tables:
```sql
CREATE DATABASE ecommerce_db;
USE ecommerce_db;
-- Create customers, products, orders tables
-- Insert sample data from data/ folder
```

### Step 2: Snowflake Setup
```sql
-- Run 01_database_setup.sql
-- Creates: RAW_DB, STAGING_DB, ANALYTICS_DB
```

### Step 3: Fivetran Configuration
1. Create Fivetran connector → Source: MySQL (AWS RDS)
2. Destination: Snowflake → RAW_DB
3. Update method: Binary Log (CDC)
4. Enable incremental sync

### Step 4: Run Transformations
```sql
-- Run in order:
-- 02_raw_layer.sql
-- 03_staging_layer.sql
-- 04_star_schema.sql
-- 05_streams_tasks.sql
```

### Step 5: Power BI Connection
1. Get Data → Snowflake
2. Server: `your-account.snowflakecomputing.com`
3. Database: `ANALYTICS_DB`
4. Mode: DirectQuery

---

## SQL Highlights

### Snowflake Stream (CDC)
```sql
CREATE OR REPLACE STREAM raw_orders_stream
ON TABLE RAW_DB.PUBLIC.ORDERS;
```

### Snowflake Task (Automation)
```sql
CREATE OR REPLACE TASK load_staging_orders
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = '5 MINUTE'
AS
  INSERT INTO STAGING_DB.PUBLIC.STG_ORDERS
  SELECT * FROM RAW_DB.PUBLIC.ORDERS
  WHERE METADATA$ACTION = 'INSERT';
```

### Star Schema Fact Table
```sql
CREATE OR REPLACE TABLE ANALYTICS_DB.PUBLIC.FACT_SALES AS
SELECT
    o.ORDER_ID,
    o.CUSTOMER_ID,
    o.PRODUCT_ID,
    d.DATE_KEY,
    o.QUANTITY,
    o.UNIT_PRICE,
    o.QUANTITY * o.UNIT_PRICE AS TOTAL_REVENUE
FROM STAGING_DB.PUBLIC.STG_ORDERS o
JOIN ANALYTICS_DB.PUBLIC.DIM_DATE d ON o.ORDER_DATE = d.FULL_DATE;
```

---

## Results

- Automated ELT pipeline reducing manual intervention by ~90%
- Near real-time data availability (5-minute refresh cycle)
- Optimized Star Schema improving query performance
- Live Power BI dashboards with DirectQuery

---

## Author

**Ramkumar G**
- LinkedIn: [linkedin.com/in/ramdba](https://linkedin.com/in/ramdba)
- GitHub: [github.com/Ramkumar-g-dba](https://github.com/Ramkumar-g-dba)
- Portfolio: [ramkumar-g-dba.github.io/ramkumar-portfolio](https://ramkumar-g-dba.github.io/ramkumar-portfolio)

