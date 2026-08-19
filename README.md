# Banking Data Warehouse & Security Layer

**Status:** Core DWH Complete | Security Layer: RLS Fully Implemented (Fact + Dimensions) | Performance Optimized

A fully functional Data Warehouse for a simulated banking environment, extended with enterprise-grade security controls including Row-Level Security on both fact and dimension tables, with performance metrics to prove scalability.

---

## Project Overview

This project simulates the integration of two hypothetical banking systems to build a unified view of transactions and customers. It solves real-world data quality issues like duplicates, missing standards, and inconsistent formats.

**What makes this project unique:**

Beyond the standard ETL pipeline and Star Schema modeling, I implemented a production-ready security layer using SQL Server native features:

- **Row-Level Security (RLS) on FACT_Transaction:** Restricts analysts to only view transactions from their assigned branches. **Status:** ✅ Implemented & Tested
- **Row-Level Security (RLS) on DIM_Customer:** Analysts only see customers who have transactions in their assigned branches. Uses subquery logic against FACT_Transaction. **Status:** ✅ Implemented & Tested (Day 4)
- **Performance Optimization:** Composite indexes on FACT_Transaction (CustomerKey, BranchKey) and Security.UserBranch (UserName, BranchKey) ensure RLS predicates execute efficiently. **Status:** ✅ Optimized & Measured
- **Dynamic Data Masking (DDM):** Automatically obfuscates PII (Cedula, Email, Phone) for non-privileged users. **Status:** ⏳ Planned
- **Native Server Auditing:** Tracks every SELECT, INSERT, UPDATE, and DELETE on sensitive tables, providing a forensic audit trail. **Status:** ⏳ Planned

---

## Professional Objective

This repository is part of my technical portfolio, demonstrating my competencies for Data Engineering, Analytics Engineering, and Database Administration roles:

- Dimensional modeling (Star Schema) for Data Warehousing.
- ETL/ELT pipeline development with Python (Pandas) and SQL Server.
- Implementation of database security controls (RLS, DDM, Auditing).
- Performance tuning and index optimization for security predicates.
- Strategic data visualization with Power BI.

---

## Tech Stack

| Component | Technology |
|---|---|
| Extraction & Load | Python (Pandas, SQLAlchemy) |
| Database | SQL Server (Developer Edition) |
| Modeling | Star Schema (Dimensions & Fact) |
| Security Layer | Row-Level Security (Fact + Dimensions), Dynamic Data Masking, Auditing |
| BI / Dashboards | Power BI Desktop |
| Version Control | Git / GitHub |

---

## Key Features

### 1. Dimensional Modeling (Star Schema)

Designed a classic Star Schema with 4 dimensions (DIM_Customer, DIM_Product, DIM_Date, DIM_Branch) and 1 fact table (FACT_Transaction) to enable fast analytical queries.

### 2. Automated ETL Pipeline

Built a Python ETL pipeline using Pandas that:

- Generates synthetic banking data (20 customers, 10 products, 366 dates, 5 branches, 63 transactions).
- Cleans and standardizes formats.
- Deduplicates client records.
- Loads transformed data into SQL Server using `IDENTITY_INSERT` to maintain foreign key integrity.

### 3. Enterprise Security Layer (In Progress)

**Row-Level Security (RLS) on FACT_Transaction — COMPLETED & OPTIMIZED:**
A dynamic filtering policy ensures analysts see only their branch data. The predicate function accepts the current user and the row's branch key, cross-references it with `Security.UserBranch`, and returns 1 only if the user is authorized. `AuditCompliance`, `DWHAdmin`, and `ETLService` are exempt from the filter. Tested successfully with `EXECUTE AS` across multiple personas.

**Row-Level Security (RLS) on DIM_Customer — COMPLETED & OPTIMIZED (Day 4):**
Extended RLS to the customer dimension using a subquery against FACT_Transaction. Analysts only see customers who have made transactions in their assigned branches.

Test results:
- `LauraGomez` sees 14 customers (branches 1, 2)
- `CarlosMendez` sees 12 customers (branch 3)
- `AuditCompliance` / `DWHAdmin` see all 20 customers

**Performance Optimization — COMPLETED (Day 4):**
To ensure RLS scales with data growth, I created:

- Composite index on `FACT_Transaction (CustomerKey, BranchKey)` for fast subquery lookups.
- Composite index on `Security.UserBranch (UserName, BranchKey)` for fast user-branch resolution.

**Performance Metrics (STATISTICS IO):**
After optimization, executing `SELECT * FROM DIM_Customer` as `LauraGomez` produced:

- FACT_Transaction: 30 scans, 60 logical reads (2 per customer)
- UserBranch: 20 scans, 40 logical reads (2 per customer)
- DIM_Customer: 1 scan, 2 logical reads

**Total logical reads: 102.** This demonstrates that even with subqueries, RLS can be highly performant with proper indexing.

**Dynamic Data Masking (DDM) — PLANNED:**
Sensitive columns (Cedula, Email, Phone) will be partially masked for analysts, while auditors and admins see full data.

**Audit Trail — PLANNED:**
SQL Server's native auditing will capture all access to FACT_Transaction and DIM_Customer, with a stored procedure to consolidate logs into a queryable table.

### 4. Power BI Dashboards

Interactive dashboards connected to the DWH, displaying:

- Monthly sales trends.
- Top clients by transaction volume.
- Data quality metrics (clean vs. flagged transactions).

`https://docs/assets/dashboard_tendencia.png`

---

## Security Implementation Progress

| Day | Milestone | Status |
|---|---|---|
| Day 1 | Created Security schema, server logins, database users, and branch mapping table. Granted base SELECT permissions. | ✅ Complete |
| Day 2 | Built inline RLS predicate function and attached it to FACT_Transaction via a Security Policy. Tested with `EXECUTE AS` for all roles. | ✅ Complete |
| Day 3 | Refactored entire schema to English table/column names. Optimized RLS with a composite index. Validated RLS with real tests. | ✅ Complete |
| Day 4 | Extended RLS to DIM_Customer with subquery logic. Created performance index on FACT_Transaction. Measured and documented performance metrics. | ✅ Complete |
| Day 5 | (Checkpoint 1) – Reflection on RLS experience and documentation. | ⏳ Upcoming |
| Day 6–10 | Implement Dynamic Data Masking and Native Auditing. | ⏳ Planned |
| Day 11–15 | Integration testing, documentation, and final reflection. | ⏳ Planned |

---

## How to Run This Project

### 1. Clone the repository

```bash
git clone https://github.com/alejandrov07/banking-data-warehouse-etl.git
```

### 2. Set up the database

Run the table creation script in SQL Server:

```bash
sql/create_tables_english.sql
```

### 3. Apply the Security Layer

Run scripts in order inside `sql/security/`:

1. `setup_principals.sql` – Creates logins, users, and security schema.
2. `user_branch_mapping.sql` – Defines which analyst owns which branch.
3. `grant_base_permissions.sql` – Grants base read permissions.
4. `rls_predicate_function.sql` – Creates the inline RLS predicate function for FACT_Transaction.
5. `rls_policy.sql` – Binds the function to FACT_Transaction (creates policy in OFF state).
6. `rls_index_optimization.sql` – Creates the performance index on Security.UserBranch.
7. `rls_dim_customer_function.sql` – Creates the RLS predicate function for DIM_Customer.
8. `rls_dim_customer_policy.sql` – Binds the function to DIM_Customer (creates policy in OFF state).
9. `rls_dim_customer_index.sql` – Creates the performance index on FACT_Transaction for subquery optimization.
10. `rls_dim_customer_test.sql` – Activates both policies and runs validation tests.

### 4. Install Python dependencies

```bash
pip install pandas sqlalchemy pyodbc
```

### 5. Generate and load data

```bash
python src/generate_data.py
python src/etl_pipeline.py
```

### 6. Activate RLS and test

Turn both policies ON and verify with `EXECUTE AS`:

- `LauraGomez`: 31 transactions, 14 customers
- `CarlosMendez`: 14 transactions, 12 customers
- `AuditCompliance`: 63 transactions, 20 customers
- `DWHAdmin`: 63 transactions, 20 customers

### 7. Open the Dashboard

Open `dashboards/banking_dashboard.pbix` in Power BI Desktop.

---

## Project Structure

```text
banking-data-warehouse-etl/
├── dashboards/
│   └── banking_dashboard.pbix
├── docs/
│   ├── assets/                    # Images for README
│   ├── data_dictionary.md
│   ├── lineage.md
│   └── project_charter.md
├── sql/
│   ├── create_tables_english.sql
│   ├── clear_all_tables.sql
│   └── security/
│       ├── setup_principals.sql
│       ├── user_branch_mapping.sql
│       ├── grant_base_permissions.sql
│       ├── rls_predicate_function.sql
│       ├── rls_policy.sql
│       ├── rls_index_optimization.sql
│       ├── rls_dim_customer_function.sql      # NEW (Day 4)
│       ├── rls_dim_customer_policy.sql        # NEW (Day 4)
│       ├── rls_dim_customer_index.sql         # NEW (Day 4)
│       └── rls_dim_customer_test.sql          # NEW (Day 4)
├── src/
│   ├── generate_data.py
│   └── etl_pipeline.py
├── .gitignore
└── README.md
```

---

## Performance Metrics (STATISTICS IO)

After implementing RLS on DIM_Customer, I measured the performance using SQL Server's `STATISTICS IO`:

**Query:** `SELECT * FROM DIM_Customer` as `LauraGomez`

| Table | Scan Count | Logical Reads | Physical Reads |
|---|---|---|---|
| FACT_Transaction | 30 | 60 | 1 |
| UserBranch | 20 | 40 | 1 |
| DIM_Customer | 1 | 2 | 1 |

**Total Logical Reads: 102**

**Analysis:** With composite indexes on `FACT_Transaction (CustomerKey, BranchKey)` and `Security.UserBranch (UserName, BranchKey)`, the RLS predicate executes efficiently. Each customer evaluation requires only 3 logical reads on average (2 on FACT_Transaction + 1 on UserBranch), proving that security does not sacrifice performance when properly optimized.

---

## Future Enhancements

- Automate audit log consolidation with SQL Server Agent jobs.
- Implement column-level encryption for highly sensitive data.
- Deploy to Azure SQL Database to test cloud-native security features.

---

## Contact

**Alejandro Velazquez**
[LinkedIn](#) · [GitHub](#)

Built as part of my preparation for Data Engineering and Analytics roles.

---

## Changelog — README Update

| Section | Change |
|---|---|
| Status | Updated to reflect RLS on dimensions + performance optimization |
| Key Features | Added full section on DIM_Customer RLS with subquery logic |
| Performance Metrics | Added table with STATISTICS IO results (Scan Count, Logical Reads) |
| Security Implementation Progress | Added Day 4 as completed |
| How to Run | Added new Day 4 scripts |
| Project Structure | Added the 4 new Day 4 files |
| Future Enhancements | Kept unchanged |