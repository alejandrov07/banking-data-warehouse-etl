# Testing Suite for BankingDWH

This directory contains automated tests for the BankingDWH project, covering:

- **Row-Level Security (RLS)** – validates that each user sees only the data they should.
- **Dynamic Data Masking (DDM)** – validates that sensitive columns are masked for analysts.
- **Native Auditing** – validates that SELECT, INSERT, UPDATE, and DELETE operations are captured and loaded into `Security.AuditLog`.

---

## Running SQL Tests (SSMS)

These tests run directly inside SQL Server using `EXECUTE AS` and `TRY...CATCH`.

### Prerequisites
- You must have `sysadmin` or `db_owner` rights on the SQL Server instance.
- The `BankingDWH` database must already be deployed (run `deploy.sql` first).

### Steps
1. Open **SQL Server Management Studio (SSMS)**.
2. Connect to your instance with a privileged account.
3. Navigate to the `tests/sql/` folder.
4. Run the scripts individually, or execute `run_all_tests.sql` to run everything at once.

```sql
-- Example: run all tests
:r tests/sql/run_all_tests.sql
```

If `:r` is not available in your SSMS (standard query window), open each file manually and execute them in this order:

1. `test_rls.sql`
2. `test_ddm.sql`
3. `test_audit.sql`

### Expected Output
- Each test prints ✅ PASS or ❌ FAIL.
- A summary shows the total number of passed/failed tests.

---

## Running Python Tests (pytest)

These tests connect to the database using `pyodbc` and verify the same logic programmatically. They are ideal for CI/CD integration.

### 1. Install Dependencies

```bash
cd tests/python
pip install -r requirements.txt
```

### 2. Configure Environment Variables (Optional)

If your logins use SQL Server authentication, set the passwords as environment variables:

```bash
# Windows (PowerShell)
$env:LAURAGOMEZ_PWD = "tu_contraseña"
$env:CARLOSMENDEZ_PWD = "tu_contraseña"
$env:AUDITCOMPLIANCE_PWD = "tu_contraseña"
$env:DWHADMIN_PWD = "tu_contraseña"
$env:ETLSERVICE_PWD = "tu_contraseña"

# Linux / Mac
export LAURAGOMEZ_PWD="tu_contraseña"
export CARLOSMENDEZ_PWD="tu_contraseña"
export AUDITCOMPLIANCE_PWD="tu_contraseña"
export DWHADMIN_PWD="tu_contraseña"
export ETLSERVICE_PWD="tu_contraseña"
```

Alternatively, create a `.env` file in the project root (make sure it's in `.gitignore`):

```env
LAURAGOMEZ_PWD=tu_contraseña
CARLOSMENDEZ_PWD=tu_contraseña
AUDITCOMPLIANCE_PWD=tu_contraseña
DWHADMIN_PWD=tu_contraseña
ETLSERVICE_PWD=tu_contraseña
```

> **Note:** The Python tests are configured to use Windows Authentication (Trusted Connection) by default for the admin connection. If you use SQL authentication, modify `conftest.py` accordingly.

### 3. Run the Tests

From the project root directory:

```bash
# Run all tests
pytest tests/python/ -v

# Run a specific test file
pytest tests/python/test_rls.py -v

# Run a specific test function
pytest tests/python/test_rls.py::test_rls_counts -v
```

### 4. Expected Output

```text
============================= test session starts =============================
platform win32 -- Python 3.11.0, pytest-7.4.3
collected 12 items

tests/python/test_rls.py .......                                        [ 58%]
tests/python/test_ddm.py ..                                             [ 75%]
tests/python/test_audit.py ...                                          [100%]

============================= 12 passed in 4.56s ==============================
```

---

## Troubleshooting Common Issues

| Issue | Solution |
|---|---|
| Login failed for user | Ensure the logins exist in SQL Server and the passwords are correct. For Windows Authentication, use `Trusted_Connection=yes`. |
| No audit events found | Verify the Server Audit is enabled (`ALTER SERVER AUDIT BankingDWH_Audit WITH (STATE = ON);`) and the folder `C:\SQLAudit\` exists and is writable. |
| RLS counts mismatch | Check that the `Security.UserBranch` table is correctly populated and that the RLS policies are ON. |
| DDM does not mask | Confirm that `UNMASK` was granted to the correct users and that the user does not have `UNMASK` if they should be masked. |

---

## Adding New Tests

To extend the test suite:

- **For SQL:** Add a new `.sql` file in `tests/sql/` and include it in `run_all_tests.sql` using `:r`.
- **For Python:** Add a new `test_*.py` file in `tests/python/` following the pytest naming convention. Use the `dwh_admin_conn` fixture to execute SQL statements.

All tests should pass after a fresh deployment. If you encounter failures, refer to the troubleshooting section or check the deployment logs.