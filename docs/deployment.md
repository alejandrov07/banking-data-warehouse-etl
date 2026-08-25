# Deployment Guide

This document explains how to deploy the **BankingDWH** database from scratch using the orchestrated `deploy.sql` script.

> **Prerequisite:** You must have **sysadmin** privileges on your SQL Server instance to run the deployment script.

---

## 1. Prepare the Environment

### 1.1. Update Passwords

Open `deploy.sql` and locate the `CREATE LOGIN` section near the top. Replace the placeholder passwords with strong passwords before running the script outside a local development environment.

```sql
-- CHANGE THESE PASSWORDS before running in anything but a local/dev environment.
CREATE LOGIN LauraGomez WITH PASSWORD = '<P@ssword1>', CHECK_POLICY = OFF;
CREATE LOGIN CarlosMendez WITH PASSWORD = '<P@ssword2>', CHECK_POLICY = OFF;
CREATE LOGIN AuditCompliance WITH PASSWORD = '<P@ssword3>', CHECK_POLICY = OFF;
CREATE LOGIN DWHAdmin WITH PASSWORD = '<P@ssword4>', CHECK_POLICY = OFF;
CREATE LOGIN ETLService WITH PASSWORD = '<P@ssword5>', CHECK_POLICY = OFF;
```

**Note:** `CHECK_POLICY = OFF` is used to simplify local development. For production, use strong passwords and enable password policy with `CHECK_POLICY = ON`.

The deployment script does not recreate these server logins if they already exist, so changing the passwords in the script will not update an existing login. If a login already exists and you need to change its password, update it separately with `ALTER LOGIN`.

---

### 1.2. Create the Audit Folder

The Server Audit writes audit files to `C:\SQLAudit\`. Ensure that the folder exists and that the SQL Server service account has permission to write to it.

Open **PowerShell as Administrator** and run:

```powershell
# Create the folder
New-Item -Path "C:\SQLAudit" -ItemType Directory -Force

# Default SQL Server instance
icacls "C:\SQLAudit" /grant "NT SERVICE\MSSQLSERVER:(OI)(CI)F"

# Named instance example:
# icacls "C:\SQLAudit" /grant "NT SERVICE\MSSQL$YourInstanceName:(OI)(CI)F"
```

> The exact service account depends on your SQL Server installation. If the commands above do not match your instance, identify the SQL Server service account and grant that account write access to `C:\SQLAudit\`.

---

## 2. Execute the Deployment Script

1. Open **SQL Server Management Studio (SSMS)** or the SQL client you use to manage the instance.
2. Connect using a login with **sysadmin** privileges.
3. Open `deploy.sql` from the project root.
4. Execute the entire script.

### What the Script Does

The deployment is orchestrated in the following order:

- Drops `BankingDWH` if it already exists.
- Creates a fresh `BankingDWH` database.
- Creates the server-level logins:
  - `LauraGomez`
  - `CarlosMendez`
  - `AuditCompliance`
  - `DWHAdmin`
  - `ETLService`
- Disables and removes the previous `BankingDWH_Audit` Server Audit when it already exists.
- Creates and enables the `BankingDWH_Audit` Server Audit in `master`.
- Grants server-level permissions such as `VIEW SERVER STATE`.
- Switches to `BankingDWH` and creates database users mapped to the logins.
- Grants database-level permissions such as `VIEW DEFINITION`.
- Creates the dimension and fact tables.
- Loads the synthetic project data:
  - 20 customers
  - 10 products
  - 366 dates
  - 5 branches
  - 63 transactions
- Creates the RLS mapping table `Security.UserBranch`.
- Applies Row-Level Security (RLS) to `FACT_Transaction` and `DIM_Customer`.
- Adds indexes used by the RLS predicates.
- Applies Dynamic Data Masking (DDM) to `Cedula`, `Email`, and `Phone`.
- Creates the native audit table `Security.AuditLog`.
- Creates `Security.sp_LoadAuditLog`.
- Creates and enables the database audit specification.
- Grants the required table, procedure, and `UNMASK` permissions.
- Runs a post-deployment row-count verification.

---

## 3. Post-Deployment Verification

### 3.1. Understand the Row-Count Verification

The deployment script performs a final row-count query.

Because RLS is enabled on `DIM_Customer` and `FACT_Transaction`, the result depends on the execution context.

Do **not** assume that a `0` returned for those two tables means the data was not loaded.

If the verification query is executed under a context that is filtered by RLS, it can return:

| Table | Expected data count |
|---|---:|
| `DIM_Customer` | 20 |
| `DIM_Product` | 10 |
| `DIM_Date` | 366 |
| `DIM_Branch` | 5 |
| `FACT_Transaction` | 63 |

`DIM_Product`, `DIM_Date`, and `DIM_Branch` are not protected by these RLS policies, so they should remain at their full counts.

For an administrative verification of all five tables, execute the verification under the `DWHAdmin` database user:

```sql
USE BankingDWH;
GO

EXECUTE AS USER = 'DWHAdmin';
GO

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
GO

REVERT;
GO
```

The expected result is:

| TableName | TotalRows |
|---|---:|
| `DIM_Customer` | 20 |
| `DIM_Product` | 10 |
| `DIM_Date` | 366 |
| `DIM_Branch` | 5 |
| `FACT_Transaction` | 63 |

---

### 3.2. Validate Row-Level Security (RLS)

The deployment assigns branch access through `Security.UserBranch`.

#### LauraGomez

`LauraGomez` is mapped to branches 1 and 2.

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
```

Expected results for the current synthetic dataset:

- Transactions: **31**
- Customers: **14**

#### CarlosMendez

`CarlosMendez` is mapped to branch 3.

```sql
USE BankingDWH;
GO

EXECUTE AS USER = 'CarlosMendez';

SELECT COUNT(*) AS Carlos_Transactions
FROM dbo.FACT_Transaction;

SELECT COUNT(*) AS Carlos_Customers
FROM dbo.DIM_Customer;

REVERT;
GO
```

Expected results for the current synthetic dataset:

- Transactions: **14**
- Customers: **12**

#### AuditCompliance

`AuditCompliance` is exempted from the RLS predicates and should see all rows.

```sql
USE BankingDWH;
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

- Transactions: **63**
- Customers: **20**

`DWHAdmin` and `ETLService` are also exempted from the RLS predicates.

---

### 3.3. Validate Dynamic Data Masking (DDM)

Test DDM using a user that does **not** have `UNMASK`, such as `LauraGomez`.

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

The values should be masked according to the DDM functions configured in `deploy.sql`.

Users with `UNMASK` permission, including `AuditCompliance`, `DWHAdmin`, and `ETLService`, should see the underlying values.

---

### 3.4. Validate Native Auditing

Generate activity, load the audit events into `Security.AuditLog`, and then inspect the stored entries.

```sql
USE BankingDWH;
GO

-- 1. Generate activity
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

-- 2. Load audit events
EXEC Security.sp_LoadAuditLog;
GO

-- 3. Inspect the stored audit entries
SELECT TOP 10
    event_time,
    server_principal_name,
    object_name,
    action_id
FROM Security.AuditLog
ORDER BY event_time DESC;
GO
```

The audit records should contain activity for the audited objects, including `FACT_Transaction` and `DIM_Customer`.

> The exact `action_id` values depend on the audit event generated. Do not assume that every event will be an `UPDATE`; the deployment audit specification captures `SELECT`, `INSERT`, `UPDATE`, and `DELETE` for the configured objects.

---

## 4. Troubleshooting

| Issue | Likely Cause | Solution |
|---|---|---|
| `Msg 33071` when dropping `BankingDWH_Audit` | The Server Audit is still enabled | The deployment script should run `ALTER SERVER AUDIT ... WITH (STATE = OFF)` before `DROP SERVER AUDIT`. |
| `Msg 15530` — audit already exists | The previous audit was not successfully dropped | Fix the `STATE = OFF` step first, then rerun the deployment. |
| `Msg 15151` for `DWHAdmin` | A database-level permission is being granted while still in the `master` context, or the login/user does not exist | `VIEW SERVER STATE` belongs at the server level. `VIEW DEFINITION` must be granted after `USE BankingDWH` and after `CREATE USER DWHAdmin`. |
| `Access is denied` when writing audit files | SQL Server service account lacks access to `C:\SQLAudit\` | Create the directory and grant the SQL Server service account write permissions. |
| RLS shows `0` rows | The query is running under a user not mapped to an allowed branch, or under a context such as `dbo` that is filtered by the predicates | Check `Security.UserBranch` and run administrative verification as `DWHAdmin` or `AuditCompliance`. |
| Analyst sees unexpected rows | Incorrect branch mapping in `Security.UserBranch` | Review `SELECT * FROM Security.UserBranch;` and verify the assigned `BranchKey` values. |
| DDM does not mask values | The user has `UNMASK` permission or is using a privileged context | Test with `LauraGomez` or another user without `UNMASK`. |
| `Security.sp_LoadAuditLog` returns no new rows | No matching audit events have been generated or events have already been loaded | Generate new `SELECT`/`INSERT`/`UPDATE`/`DELETE` activity on the audited tables, then run the procedure again. |
| `CREATE LOGIN` does not create a changed password | The login already exists | The deploy script intentionally uses `IF NOT EXISTS`. Change an existing login separately with `ALTER LOGIN`. |
| Password validation fails | `CHECK_POLICY = ON` or the password is too weak | Use a strong password. For local development, the script uses `CHECK_POLICY = OFF`. |

---

## 5. Resetting the Database

The deployment is designed to recreate the database from scratch.

To reset `BankingDWH`:

1. Make sure you are connected with **sysadmin** privileges.
2. Run `deploy.sql` again.
3. The script drops the existing `BankingDWH` database and recreates it.
4. Existing server logins are preserved because the script uses `IF NOT EXISTS`.

> The Server Audit is also handled explicitly: when `BankingDWH_Audit` already exists, the script disables it before dropping and recreating it.

---

## 6. Next Steps After Deployment

After the deployment succeeds:

- Run the ETL pipeline (`python scripts/etl_pipeline.py`) if additional data loading is required.
- Connect Power BI to the `BankingDWH` database for reporting and dashboards.
- Run the project validation and security tests in the `tests/` folder.
- Test the RLS behavior using `LauraGomez`, `CarlosMendez`, `AuditCompliance`, and `DWHAdmin`.
- Test DDM with both masked and `UNMASK`-privileged users.
- Generate audit events and verify that `Security.AuditLog` receives them.

---

## 7. Deployment Success Criteria

Consider the deployment successful when:

- No SQL Server `Msg` errors are reported during execution.
- The final verification returns the expected counts.
- RLS tests return the expected restricted rows for analysts.
- `AuditCompliance` and `DWHAdmin` can access the expected unrestricted data.
- DDM masks sensitive fields for non-privileged users.
- Audit events can be captured and loaded into `Security.AuditLog`.

**Deployment complete.** The `BankingDWH` environment is ready for analysis, ETL, reporting, and security validation.
