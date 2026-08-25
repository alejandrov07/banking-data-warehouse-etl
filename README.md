# Banking Data Warehouse & Security Layer

**Status:** Core DWH Complete | Security Layer: RLS, DDM & Auditing Fully Implemented | Deployment Orchestrated | Performance Optimized

A fully functional Data Warehouse for a simulated banking environment, extended with SQL Server security controls including Row-Level Security on fact and dimension tables, Dynamic Data Masking, native auditing, role-based permissions, and performance optimization.

---

## Project Overview

This project simulates the integration of two hypothetical banking systems to build a unified view of customers and transactions. It addresses common data engineering challenges such as inconsistent formats, duplicates, standardization, and data quality validation.

### What makes this project unique

Beyond the ETL pipeline and Star Schema model, the project includes a complete SQL Server security layer and an orchestrated deployment script that rebuilds the database and its security controls from scratch.

- **Row-Level Security (RLS) on `FACT_Transaction`:** Analysts are restricted to transactions from their assigned branches. ✅ Implemented & Tested
- **Row-Level Security (RLS) on `DIM_Customer`:** Analysts only see customers associated with transactions in their assigned branches. ✅ Implemented & Tested
- **Performance Optimization:** Composite indexes support the RLS predicates and customer-access subquery. ✅ Optimized & Measured
- **Dynamic Data Masking (DDM):** Masks PII including `Cedula`, `Email`, and `Phone` for non-privileged users. ✅ Implemented & Tested
- **Native SQL Server Auditing:** Captures `SELECT`, `INSERT`, `UPDATE`, and `DELETE` activity on sensitive tables and supports consolidation into `Security.AuditLog`. ✅ Implemented & Tested
- **Orchestrated Deployment:** `deploy.sql` creates the database, server principals, users, data, RLS, DDM, permissions, auditing, and post-deployment verification. ✅ Implemented & Tested

---

## Professional Objective

This repository is part of my technical portfolio, demonstrating competencies for:

- Data Engineering
- Analytics Engineering
- Database Administration
- Dimensional modeling and Data Warehousing
- ETL/ELT pipeline development
- Database security and access control
- SQL Server performance optimization
- Business intelligence and reporting

---

## Tech Stack

| Component | Technology |
|---|---|
| Extraction & Load | Python, Pandas, SQLAlchemy, pyodbc |
| Database | SQL Server Developer Edition |
| Modeling | Star Schema |
| Security | RLS, Dynamic Data Masking, Native Auditing |
| Deployment | T-SQL orchestrated deployment (`deploy.sql`) |
| BI / Dashboards | Power BI Desktop |
| Version Control | Git / GitHub |

---

## Key Features

### 1. Dimensional Modeling

The warehouse uses a classic Star Schema with four dimensions and one fact table:

- `DIM_Customer`
- `DIM_Product`
- `DIM_Date`
- `DIM_Branch`
- `FACT_Transaction`

The current synthetic dataset contains:

| Table | Rows |
|---|---:|
| `DIM_Customer` | 20 |
| `DIM_Product` | 10 |
| `DIM_Date` | 366 |
| `DIM_Branch` | 5 |
| `FACT_Transaction` | 63 |

### 2. Automated ETL Pipeline

The Python pipeline:

- Generates synthetic banking data.
- Cleans and standardizes formats.
- Deduplicates customer records.
- Loads transformed data into SQL Server.
- Maintains key relationships during loading.

Main scripts:

```text
src/generate_data.py
src/etl_pipeline.py
```

### 3. Enterprise Security Layer

#### Row-Level Security — `FACT_Transaction`

The transaction predicate checks the current database user and the row's `BranchKey` against `Security.UserBranch`.

Analyst mappings:

- `LauraGomez` → branches 1 and 2
- `CarlosMendez` → branch 3

`AuditCompliance`, `DWHAdmin`, and `ETLService` are exempted from the RLS filter.

#### Row-Level Security — `DIM_Customer`

The customer predicate checks whether a customer has a transaction in a branch assigned to the current analyst.

Current synthetic test results:

| User | Transactions | Customers |
|---|---:|---:|
| `LauraGomez` | 31 | 14 |
| `CarlosMendez` | 14 | 12 |
| `AuditCompliance` | 63 | 20 |
| `DWHAdmin` | 63 | 20 |

#### RLS Verification Note

`DIM_Customer` and `FACT_Transaction` are protected by RLS. Therefore, a plain `COUNT(*)` can return `0` when executed under a context that is not exempt from the RLS predicates.

For administrative verification, run the count query as `DWHAdmin` or `AuditCompliance`:

```sql
USE BankingDWH;
GO

EXECUTE AS USER = 'DWHAdmin';

SELECT 'DIM_Customer' AS TableName, COUNT(*) AS TotalRows
FROM dbo.DIM_Customer
UNION ALL
SELECT 'DIM_Product', COUNT(*)
FROM dbo.DIM_Product
UNION ALL
SELECT 'DIM_Date', COUNT(*)
FROM dbo.DIM_Date
UNION ALL
SELECT 'DIM_Branch', COUNT(*)
FROM dbo.DIM_Branch
UNION ALL
SELECT 'FACT_Transaction', COUNT(*)
FROM dbo.FACT_Transaction;

REVERT;
GO
```

Expected counts:

| TableName | TotalRows |
|---|---:|
| `DIM_Customer` | 20 |
| `DIM_Product` | 10 |
| `DIM_Date` | 366 |
| `DIM_Branch` | 5 |
| `FACT_Transaction` | 63 |

### 4. Performance Optimization

The RLS implementation is supported by:

- `Security.UserBranch (UserName, BranchKey)`
- `FACT_Transaction (CustomerKey, BranchKey)`

Measured with SQL Server `STATISTICS IO`:

| Table | Scan Count | Logical Reads | Physical Reads |
|---|---:|---:|---:|
| `FACT_Transaction` | 30 | 60 | 1 |
| `UserBranch` | 20 | 40 | 1 |
| `DIM_Customer` | 1 | 2 | 1 |

**Total Logical Reads: 102**

The indexes reduce the cost of branch authorization and the customer RLS subquery.

### 5. Dynamic Data Masking

Sensitive columns in `DIM_Customer` are masked for non-privileged users:

- `Cedula` → `partial(4, "XXXX-", 0)`
- `Email` → `email()`
- `Phone` → `partial(0, "XXXX-XXXX-", 4)`

`AuditCompliance`, `DWHAdmin`, and `ETLService` receive `UNMASK`.

Documentation:

```text
docs/security_ddm.md
```

### 6. Native SQL Server Auditing

Native auditing captures `SELECT`, `INSERT`, `UPDATE`, and `DELETE` events for:

- `dbo.FACT_Transaction`
- `dbo.DIM_Customer`

The project uses:

- Server Audit: `BankingDWH_Audit`
- Database Audit Specification: `BankingDWH_Audit_Spec`
- Audit table: `Security.AuditLog`
- Processing procedure: `Security.sp_LoadAuditLog`

Documentation:

```text
docs/security_audit.md
```

The deployment also handles an existing `BankingDWH_Audit` by disabling it before dropping and recreating it.

### 7. Orchestrated Deployment

The recommended deployment entry point is:

```text
deploy.sql
```

The script orchestrates:

1. Database recreation
2. Server-level logins
3. Server Audit creation/recreation
4. Security schema and database users
5. Star Schema tables
6. Synthetic data loading
7. RLS and supporting indexes
8. DDM
9. Permissions
10. Native auditing
11. Post-deployment verification

The deployment requires **sysadmin** privileges.

Deployment documentation:

```text
docs/deployment.md
```

---

## Power BI Dashboards

The project includes a Power BI dashboard:

```text
dashboards/banking_dashboard.pbix
```

The documented dashboards include:

- Monthly transaction trends
- Top clients by transaction volume
- Data quality metrics

![Dashboard Tendencia](docs/assets/dashboard_tendencia.png)

---

## Security Implementation Progress

| Day | Milestone | Status |
|---|---|---|
| Day 1 | Security schema, server logins, database users, branch mapping, and base permissions. | ✅ Complete |
| Day 2 | RLS predicate and policy for `FACT_Transaction`. | ✅ Complete |
| Day 3 | Schema refactoring and initial RLS optimization. | ✅ Complete |
| Day 4 | RLS on `DIM_Customer`, supporting indexes, and STATISTICS IO measurements. | ✅ Complete |
| Day 5 | RLS checkpoint and documentation. | ✅ Complete |
| Day 6 | Dynamic Data Masking on `DIM_Customer`. | ✅ Complete |
| Day 7 | Native SQL Server Auditing and audit log processing. | ✅ Complete |
| Day 8–10 | Deployment integration, deployment troubleshooting, and final verification. | ✅ Complete |
| Day 11–15 | Additional enhancements and final reflection. | ⏳ Planned |

---

## How to Run This Project

### 1. Clone the repository

```bash
git clone https://github.com/alejandrov07/banking-data-warehouse-etl.git
cd banking-data-warehouse-etl
```

### 2. Prepare SQL Server

Before deployment:

- Use SQL Server with sufficient privileges to create databases, logins, audits, and security objects.
- Connect with **sysadmin** privileges.
- Ensure `C:\SQLAudit\` exists.
- Ensure the SQL Server service account has write access to `C:\SQLAudit\`.
- Replace the placeholder passwords in `deploy.sql` for non-local environments.

### 3. Run the orchestrated deployment

Open:

```text
deploy.sql
```

in SSMS and execute the entire script.

This is the recommended deployment path because it handles the required object dependencies automatically.

### 4. Verify the deployment

The final verification checks row counts.

Because RLS applies to `DIM_Customer` and `FACT_Transaction`, use `DWHAdmin` or `AuditCompliance` for a full administrative verification.

Expected counts:

```text
DIM_Customer        20
DIM_Product         10
DIM_Date            366
DIM_Branch          5
FACT_Transaction    63
```

### 5. Validate RLS

Use `EXECUTE AS`:

```sql
USE BankingDWH;
GO

EXECUTE AS USER = 'LauraGomez';

SELECT COUNT(*) AS Laura_Transactions
FROM dbo.FACT_Transaction;

SELECT COUNT(*) AS Laura_Customers
FROM dbo.DIM_Customer;

REVERT;
GO

EXECUTE AS USER = 'CarlosMendez';

SELECT COUNT(*) AS Carlos_Transactions
FROM dbo.FACT_Transaction;

SELECT COUNT(*) AS Carlos_Customers
FROM dbo.DIM_Customer;

REVERT;
GO

EXECUTE AS USER = 'AuditCompliance';

SELECT COUNT(*) AS All_Transactions
FROM dbo.FACT_Transaction;

SELECT COUNT(*) AS All_Customers
FROM dbo.DIM_Customer;

REVERT;
GO
```

Expected results:

| User | Transactions | Customers |
|---|---:|---:|
| `LauraGomez` | 31 | 14 |
| `CarlosMendez` | 14 | 12 |
| `AuditCompliance` | 63 | 20 |
| `DWHAdmin` | 63 | 20 |

### 6. Validate DDM

```sql
USE BankingDWH;
GO

EXECUTE AS USER = 'LauraGomez';

SELECT TOP 5
    FullName,
    Cedula,
    Email,
    Phone
FROM dbo.DIM_Customer;

REVERT;
GO
```

The sensitive values should be masked for `LauraGomez`.

### 7. Validate Auditing

```sql
USE BankingDWH;
GO

EXECUTE AS USER = 'LauraGomez';

SELECT TOP 5 *
FROM dbo.FACT_Transaction;

SELECT TOP 5
    FullName,
    Cedula,
    Email,
    Phone
FROM dbo.DIM_Customer;

REVERT;
GO

EXEC Security.sp_LoadAuditLog;
GO

SELECT TOP 20
    event_time,
    server_principal_name,
    object_name,
    action_id
FROM Security.AuditLog
ORDER BY event_time DESC;
GO
```

### 8. Install Python dependencies

```bash
pip install pandas sqlalchemy pyodbc
```

### 9. Generate and load data

```bash
python src/generate_data.py
python src/etl_pipeline.py
```

### 10. Open the dashboard

Open:

```text
dashboards/banking_dashboard.pbix
```

in Power BI Desktop.

---

## Project Structure

```text
banking-data-warehouse-etl/
├── dashboards/
│   └── banking_dashboard.pbix
├── data/
│   ├── logs/
│   └── raw/
├── docs/
│   ├── assets/
│   │   ├── dashboard_calidad.png
│   │   ├── dashboard_clientes.png
│   │   └── dashboard_tendencia.png
│   ├── data_dictionary.md
│   ├── deployment.md
│   ├── lineage.md
│   ├── project_charter.md
│   ├── security_audit.md
│   ├── security_ddm.md
│   └── security_rls.md
├── sql/
│   ├── create_tables.sql
│   └── security/
│       ├── setup_principals.sql
│       ├── user_branch_mapping.sql
│       ├── grant_base_permissions.sql
│       ├── rls_predicate_function.sql
│       ├── rls_policy.sql
│       ├── rls_index_optimization.sql
│       ├── rls_dim_customer_function.sql
│       ├── rls_dim_customer_policy.sql
│       ├── rls_dim_customer_index.sql
│       ├── dynamic_data_masking.sql
│       ├── audit_setup_master.sql
│       ├── audit_setup_database.sql
│       ├── audit_processing.sql
│       ├── test_ddm.sql
│       └── rename_spanish_objects_to_english.sql
├── src/
│   ├── generate_data.py
│   └── etl_pipeline.py
├── deploy.sql
├── .env.example
├── .gitignore
└── README.md
```

---

## Troubleshooting

### RLS verification returns 0 rows

This can be expected when the query is executed under a user/context filtered by RLS.

Use:

```sql
EXECUTE AS USER = 'DWHAdmin';
```

or:

```sql
EXECUTE AS USER = 'AuditCompliance';
```

for unrestricted administrative verification.

### `Msg 33071` when deploying

The existing Server Audit must be disabled before it can be dropped. The current `deploy.sql` handles this with:

```sql
ALTER SERVER AUDIT BankingDWH_Audit WITH (STATE = OFF);
```

before `DROP SERVER AUDIT`.

### `Msg 15530` — audit already exists

This usually indicates that the existing audit was not successfully dropped. Verify the `STATE = OFF` step before the `DROP SERVER AUDIT`.

### `Msg 15151` for `DWHAdmin`

`VIEW SERVER STATE` is a server-level permission, while `VIEW DEFINITION` is a database-level permission. They must be granted in their respective contexts.

### Audit file access errors

Verify that:

```text
C:\SQLAudit\
```

exists and that the SQL Server service account has write access.

### Login password changes are not applied

The deployment uses `IF NOT EXISTS` when creating server logins. If a login already exists, its existing password is not changed by the deployment. Use `ALTER LOGIN` to change an existing password.

---

## Performance Metrics (STATISTICS IO)

After implementing RLS on `DIM_Customer`, the measured query was:

```text
SELECT * FROM DIM_Customer
```

executed as `LauraGomez`.

| Table | Scan Count | Logical Reads | Physical Reads |
|---|---:|---:|---:|
| `FACT_Transaction` | 30 | 60 | 1 |
| `UserBranch` | 20 | 40 | 1 |
| `DIM_Customer` | 1 | 2 | 1 |

**Total Logical Reads: 102**

The results demonstrate that the security predicates remain efficient when the supporting indexes are present.

---

## Future Enhancements

- Automate audit log consolidation with SQL Server Agent jobs.
- Implement column-level encryption for highly sensitive data.
- Deploy to Azure SQL Database to test cloud-native security features.
- Expand automated deployment and integration tests.
- Add further validation around deployment success/failure handling.

---

## Contact

**Alejandro Velazquez**

[LinkedIn](#) · [GitHub](https://github.com/alejandrov07)

Built as part of my preparation for Data Engineering and Analytics roles.

---

## Changelog — README Update

| Section | Change |
|---|---|
| Status | Updated to reflect the completed security layer and orchestrated deployment |
| Deployment | Added `deploy.sql` as the recommended deployment entry point |
| Verification | Documented RLS-aware verification and `DWHAdmin` administrative verification |
| Troubleshooting | Added Server Audit and `DWHAdmin` deployment issues identified during testing |
| Structure | Confirmed actual repository paths from the project archive |
| Documentation | Linked `docs/deployment.md`, `docs/security_rls.md`, `docs/security_ddm.md`, and `docs/security_audit.md` |
| Execution | Updated Python paths to `src/` and deployment flow to the current repository structure |
| Progress | Marked deployment integration and verification as complete |
