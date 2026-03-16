# Pipeline Architecture

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     SOURCE LAYER                                 │
│                                                                  │
│   ┌──────────────────┐                                          │
│   │  AWS RDS (MySQL)  │  ← Transactional data (Orders,         │
│   │  - orders         │     Customers, Products)                │
│   │  - customers      │                                         │
│   │  - products       │                                         │
│   └────────┬─────────┘                                          │
└────────────│────────────────────────────────────────────────────┘
             │
             │  Fivetran (Incremental Sync - every 5 min)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SNOWFLAKE DATA WAREHOUSE                       │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  RAW_DB  (Layer 1)                                       │   │
│  │  - RAW_ORDERS    (exact copy from MySQL)                 │   │
│  │  - RAW_CUSTOMERS                                         │   │
│  │  - RAW_PRODUCTS                                          │   │
│  │  - orders_stream (Snowflake Stream - CDC)                │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                            │ Snowflake Task (auto, 5 min)        │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  STAGING_DB  (Layer 2)                                   │   │
│  │  - STG_ORDERS    (cleaned, validated)                    │   │
│  │  - STG_CUSTOMERS (normalized)                            │   │
│  │  - STG_PRODUCTS  (standardized)                          │   │
│  └────────────────────────┬────────────────────────────────┘   │
│                            │ SQL Transformations                  │
│                            ▼                                     │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  ANALYTICS_DB  (Layer 3 - Star Schema)                   │   │
│  │                                                           │   │
│  │        DIM_DATE ──┐                                      │   │
│  │     DIM_CUSTOMER ─┼──→ FACT_SALES                        │   │
│  │      DIM_PRODUCT ─┘                                      │   │
│  │                                                           │   │
│  └────────────────────────┬────────────────────────────────┘   │
└───────────────────────────│─────────────────────────────────────┘
                            │ DirectQuery
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REPORTING LAYER                               │
│                                                                  │
│   ┌──────────────────────────────────────────┐                 │
│   │  Power BI Dashboard                       │                 │
│   │  - Total Revenue KPI                      │                 │
│   │  - Sales by Month (Line Chart)            │                 │
│   │  - Top Products (Bar Chart)               │                 │
│   │  - Customer Distribution (Map)            │                 │
│   └──────────────────────────────────────────┘                 │
└─────────────────────────────────────────────────────────────────┘
```

## Star Schema Design

```
             ┌──────────────┐
             │   DIM_DATE   │
             │  - DATE_KEY  │
             │  - FULL_DATE │
             │  - YEAR      │
             │  - MONTH     │
             │  - QUARTER   │
             └──────┬───────┘
                    │
┌──────────────┐    │    ┌──────────────────┐
│ DIM_CUSTOMER │    │    │   FACT_SALES      │
│ - CUSTOMER_ID│────┼────│ - ORDER_ID (PK)   │
│ - FULL_NAME  │    │    │ - CUSTOMER_ID (FK)│
│ - EMAIL      │    │    │ - PRODUCT_ID (FK) │
│ - CITY       │    │    │ - DATE_KEY (FK)   │
│ - COUNTRY    │    │    │ - QUANTITY        │
└──────────────┘    │    │ - UNIT_PRICE      │
                    │    │ - TOTAL_REVENUE   │
┌──────────────┐    │    │ - STATUS          │
│ DIM_PRODUCT  │────┘    └──────────────────┘
│ - PRODUCT_ID │
│ - PRODUCT_NM │
│ - CATEGORY   │
│ - UNIT_COST  │
└──────────────┘
```

## Key Design Decisions

| Decision | Reason |
|----------|--------|
| ELT over ETL | Transform inside Snowflake — more scalable & cost-effective |
| Fivetran for ingestion | Handles schema evolution & incremental syncs automatically |
| Streams + Tasks | Automates pipeline without external orchestrators |
| Star Schema | Optimized for BI queries — fast aggregations |
| DirectQuery in Power BI | Live data — no stale reports |
| IAM Role for S3 | Secure, credential-free access to AWS S3 |
