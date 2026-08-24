# Native SQL Server Auditing

## Overview
Native SQL Server auditing captures detailed activity on sensitive tables (`FACT_Transaction` and `DIM_Customer`). The audit logs are written to files on disk and can be consolidated into a queryable table for compliance reviews and forensic analysis.

## Setup Instructions (run in this order)
1. **Run `audit_setup_master.sql` in the `master` database** – Creates the server audit and grants server permissions to `AuditCompliance`.
2. **Run `audit_setup_database.sql` in the `BankingDWH` database** – Creates the database audit specification and enables it.
3. **Run `audit_processing.sql` in the `BankingDWH` database** – Creates the `Security.AuditLog` table and the stored procedure `Security.sp_LoadAuditLog` to import audit events.

## Permissions
- `AuditCompliance` and `DWHAdmin` have `VIEW SERVER STATE` and `VIEW DEFINITION` to read audit files.
- `AuditCompliance` can execute `Security.sp_LoadAuditLog` and query the `Security.AuditLog` table.
- `DWHAdmin` has full control.

## Loading and Querying Audit Logs
After generating some activity (e.g., SELECT queries on `FACT_Transaction`), run:
```sql
EXEC Security.sp_LoadAuditLog;