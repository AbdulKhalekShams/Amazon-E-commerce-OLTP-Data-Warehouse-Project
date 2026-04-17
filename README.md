# Amazon E-commerce OLTP to Data Warehouse Project

An end-to-end **SQL Server** project that starts with a normalized **OLTP database** for e-commerce transactions and then transforms the transactional model into a **star schema Data Warehouse** for analytics and reporting.

This repository demonstrates practical skills in:
- relational database design
- dimensional modeling
- OLTP vs. OLAP architecture
- SQL-based ETL
- data integrity constraints and indexing
- KPI and business query development

---

## Project Overview

The project is divided into three layers:

1. **OLTP layer**  
   A normalized transactional database for day-to-day e-commerce operations.

2. **Data Warehouse layer**  
   A star schema built for analytical reporting.

3. **Analytics layer**  
   Business queries for metrics such as sales, order value, and return rate.

---

## Business Scenario

The dataset models a simplified Amazon-style e-commerce environment with the following domains:
- customers and addresses
- sellers and products
- categories and subcategories
- orders and order items
- payments and shipments
- returns

The goal is to move from operational transaction storage to an analytical model that supports reporting by:
- date
- customer segment
- geography
- seller
- product hierarchy
- channel

---

## Repository Structure

```text
amazon-oltp-dwh-project/
├── README.md
├── LICENSE
├── .gitignore
├── docs/
│   └── erd/
│       ├── oltp-erd.png
│       └── dwh-erd.png
├── sql/
│   ├── 01_oltp/
│   │   └── 01_create_amazon_oltp_load_from_psv.sql
│   ├── 02_dwh/
│   │   └── 02_create_amazon_dwh.sql
│   └── 03_analysis/
│       └── 03_sample_business_queries.sql
└── assets/
```

---

## OLTP Model

The OLTP database is designed to support transactional consistency and normalization.

### Main entities
- `Customers`
- `Addresses`
- `Sellers`
- `Categories`
- `Subcategories`
- `Products`
- `Orders`
- `OrderItems`
- `OrderTotals`
- `Payments`
- `Shipments`
- `Returns`

### OLTP design highlights
- normalized relational structure
- primary and foreign keys for referential integrity
- bulk loading from PSV files
- supporting indexes on frequently queried columns

### OLTP ERD

![OLTP ERD](docs/erd/oltp-erd.png)

---

## Data Warehouse Model

The Data Warehouse is modeled as a **star schema** centered around `FactSales`.

### Fact table
- `FactSales`

### Dimensions
- `DimDate`
- `DimCustomer`
- `DimProduct`
- `DimSeller`
- `DimGeo`

### DWH design highlights
- surrogate keys for dimensions
- business keys preserved for traceability
- degenerate dimensions such as `OrderID` and `OrderItemID`
- analytical measures such as:
  - `RevenueEGP`
  - `CostEGP`
  - `GrossProfitEGP`
- cancelled orders excluded from the fact load to align with reporting logic

### DWH ERD

![DWH ERD](docs/erd/dwh-erd.png)

---

## ETL Logic

The ETL in this project is implemented directly in **T-SQL**.

### ETL flow
1. Create and load the OLTP database from PSV files using `BULK INSERT`
2. Create dimension tables in `AmazonDW`
3. Populate dimensions from OLTP source tables
4. Generate surrogate keys for dimensions
5. Load `FactSales` by joining OLTP tables with dimensions
6. Calculate analytical measures during fact loading

### Transformations implemented
- date dimension generation from min/max order dates
- category and subcategory flattening into `DimProduct`
- address transformation into `DimGeo`
- seller mapping through product ownership
- gross profit calculation in the fact table

---

## Sample KPIs and Queries

The repository includes example SQL queries for business analysis, such as:
- **GMV** (Gross Merchandise Value)
- **Orders count**
- **AOV** (Average Order Value)
- **Sales by governorate**
- **Return rate**

These queries are available in:

```text
sql/03_analysis/03_sample_business_queries.sql
```

---

## How to Run the Project

### 1) Create and load the OLTP database
Run:

```sql
sql/01_oltp/01_create_amazon_oltp_load_from_psv.sql
```

> Update the `@DataPath` variable in the script to match your local dataset path before running it.

### 2) Create the Data Warehouse
Run:

```sql
sql/02_dwh/02_create_amazon_dwh.sql
```

### 3) Run sample analysis queries
Run:

```sql
sql/03_analysis/03_sample_business_queries.sql
```

---

## Technical Skills Demonstrated

- SQL Server
- T-SQL
- Relational Database Design
- Data Warehousing
- Dimensional Modeling
- Star Schema Design
- ETL Development
- PK / FK Constraints
- Indexing
- Analytical SQL
- KPI Development

---

## Possible Future Enhancements

- add stored procedures for ETL orchestration
- add views for reporting abstraction
- implement incremental fact loading
- add Power BI dashboard on top of `AmazonDW`
- add data quality checks and validation scripts
- add SCD logic for selected dimensions

---

## Author

**Ahmed Omar**  
Civil Engineer transitioning into Data and BI projects

If you use this repository in your portfolio, feel free to adapt the scripts and structure to your own datasets and reporting needs.
