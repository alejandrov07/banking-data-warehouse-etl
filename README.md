# Banking Data Warehouse & Security Layer

**Status:** Core DWH Complete | Security Layer: RLS Implemented & Tested (Day 2)

A fully functional Data Warehouse for a simulated banking environment, extended with enterprise-grade security controls.

## Project Overview

This project simulates the integration of two hypothetical banking systems (Core Banking and Card System) to build a unified view of transactions and customers. It solves real-world data quality issues like duplicates, missing standards, and inconsistent formats.

**What makes this project unique:**

Beyond the standard ETL pipeline and Star Schema modeling, I implemented a production-ready security layer using SQL Server native features:

- **Row-Level Security (RLS):** Restricts analysts to only view transactions from their assigned branches. Status: ✅ Implemented (Day 2)
- **Dynamic Data Masking (DDM):** Automatically obfuscates PII (Cedula, Email, Phone) for non-privileged users. Status: ⏳ Planned (Day 6)
- **Native Server Auditing:** Tracks every SELECT, INSERT, UPDATE, and DELETE on sensitive tables, providing a forensic audit trail. Status: ⏳ Planned (Day 7-9)

## Professional Objective

This repository is part of my technical portfolio, demonstrating my competencies for Data Engineering, Analytics Engineering, and Database Administration roles:

- Dimensional modeling (Star Schema) for Data Warehousing.
- ETL/ELT pipeline development with Python (Pandas) and SQL Server.
- Implementation of database security controls (RLS, DDM, Auditing).
- Metadata management and data lineage documentation.
- Strategic data visualization with Power BI.

## Tech Stack

| Component | Technology |
|---|---|
| Extraction & Load | Python (Pandas, SQLAlchemy) |
| Database | SQL Server (Developer Edition) |
| Modeling | Star Schema (Dimensions & Fact) |
| Security Layer | Row-Level Security, Dynamic Data Masking, Auditing |
| BI / Dashboards | Power BI Desktop |
| Version Control | Git / GitHub |

## Key Features

### 1. Dimensional Modeling (Star Schema)

Designed a classic Star Schema with 4 dimensions (`DIM_Cliente`, `DIM_Producto`, `DIM_Tiempo`, `DIM_Sucursal`) and 1 fact table (`FACT_Transaccion`) to enable fast analytical queries.

### 2. Automated ETL Pipeline

Built a Python ETL pipeline using Pandas that:

- Generates synthetic banking data.
- Cleans and standardizes formats.
- Deduplicates client records.
- Loads transformed data into SQL Server.

### 3. Enterprise Security Layer (In Progress)

**Row-Level Security (RLS) – COMPLETED:**
A dynamic filtering policy ensures analysts see only their branch data. The predicate function accepts the current user and the row's branch key, cross-references it with a mapping table, and returns 1 only if the user is authorized. Admins and auditors are exempt from the filter. Tested successfully with `EXECUTE AS` across multiple personas.

**Dynamic Data Masking (DDM) – PLANNED:**
Sensitive columns (Cedula, Email, Phone) will be partially masked for analysts, while auditors and admins see full data.

**Audit Trail – PLANNED:**
SQL Server's native auditing will capture all access to `FACT_Transaccion` and `DIM_Cliente`, with a stored procedure to consolidate logs into a queryable table.

### 4. Power BI Dashboards

Interactive dashboards connected to the DWH, displaying:

- Monthly sales trends.
- Top clients by transaction volume.
- Data quality metrics (clean vs. flagged transactions).

![Dashboard Trends](docs/assets/dashboard_tendencia.png)

## Security Implementation Progress

| Day | Milestone | Status |
|---|---|---|
| Day 1 | Created Security schema, server logins, database users, and branch mapping table. Granted base SELECT permissions. | ✅ Complete |
| Day 2 | Built inline RLS predicate function and attached it to `FACT_Transaccion` via a Security Policy. Tested with `EXECUTE AS` for LauraGomez, CarlosMendez, AuditCompliance, and DWHAdmin. | ✅ Complete |
| Day 3 | (Buffer) – Additional testing, performance analysis, and indexing on `Security.UserBranch`. | ⏳ Pending |
| Day 4-5 | Extend RLS to dimensions and perform checkpoint reflection. | ⏳ Pending |
| Day 6-10 | Implement Dynamic Data Masking and Native Auditing. | ⏳ Pending |
| Day 11-15 | Integration testing, documentation, and final reflection. | ⏳ Pending |

## How to Run This Project

**1. Clone the repository**

```bash
git clone https://github.com/alejandrov07/banking-data-warehouse-etl.git
```

**2. Set up the database**

Run the table creation script in SQL Server:

```bash
sql/create_tables.sql
```

**3. Install Python dependencies**

```bash
pip install pandas sqlalchemy pyodbc
```

**4. Generate and load data**

```bash
python src/generar_datos.py
python src/etl_pipeline.py
```

**5. Apply the Security Layer**

Run scripts in order inside `sql/security/`:

- `setup_principals.sql` – Creates logins, users, and security schema.
- `user_branch_mapping.sql` – Defines which analyst owns which branch.
- `grant_base_permissions.sql` – Grants base read permissions.
- `rls_predicate_function.sql` – Creates the inline RLS predicate function.
- `rls_policy.sql` – Binds the function to `FACT_Transaccion` (creates policy in OFF state).
- `rls_test_queries.sql` – Activates the policy and runs validation tests.

**6. Open the Dashboard**

Open `dashboards/banking_dashboard.pbix` in Power BI Desktop.

## Project Structure

```text
banking-data-warehouse-etl/
├── dashboards/
│   └── banking_dashboard.pbix
├── docs/
│   ├── assets/                  # Images for README
│   ├── data_dictionary.md
│   ├── lineage.md
│   └── project_charter.md
├── sql/
│   ├── create_tables.sql
│   └── security/
│       ├── setup_principals.sql
│       ├── user_branch_mapping.sql
│       ├── grant_base_permissions.sql
│       ├── rls_predicate_function.sql
│       ├── rls_policy.sql
│       └── rls_test_queries.sql
├── src/
│   ├── etl_pipeline.py
│   └── generator_datos.py
├── .gitignore
└── README.md
```

## Future Enhancements

- Automate audit log consolidation with SQL Server Agent jobs.
- Implement column-level encryption for highly sensitive data.
- Deploy to Azure SQL Database to test cloud-native security features.

## Contact

**Alejandro Velazquez**
[LinkedIn](https://www.linkedin.com/in/alejandro-velazquez-9b0375387/) · [GitHub](https://github.com/alejandrov07)

*Built as part of my preparation for Data Engineering and Analytics roles.*