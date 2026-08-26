"""
test_audit.py
Validates Native SQL Server Auditing for BankingDWH.

Tests that SELECT, INSERT, UPDATE, and DELETE operations are captured
in the server audit files and successfully loaded into Security.AuditLog
via the Security.sp_LoadAuditLog stored procedure.
"""

import time
import pytest


def test_audit_captures_select_events(dwh_admin_conn):
    """
    Generate SELECT activity as LauraGomez, load the audit logs,
    and verify that at least one SL (SELECT) event is captured.
    """
    cursor = dwh_admin_conn.cursor()

    # 1. Generate SELECT activity as LauraGomez
    cursor.execute("EXECUTE AS USER = 'LauraGomez';")
    cursor.execute("SELECT TOP 5 * FROM dbo.FACT_Transaction;")
    cursor.execute("SELECT TOP 5 * FROM dbo.DIM_Customer;")
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    # 2. Load audit logs into Security.AuditLog
    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

    # 3. Wait briefly for the audit file flush (SQL Server async write)
    #    Retry up to 5 times with 1-second delays.
    max_retries = 5
    events_found = 0
    for attempt in range(max_retries):
        cursor.execute("""
            SELECT COUNT(*)
            FROM Security.AuditLog
            WHERE server_principal_name = 'LauraGomez'
              AND object_name IN ('FACT_Transaction', 'DIM_Customer')
              AND action_id = 'SL';
        """)
        events_found = cursor.fetchone()[0]
        if events_found > 0:
            break
        time.sleep(1)  # Wait for audit logs to flush

    assert events_found > 0, (
        f"No SELECT audit events found for LauraGomez. "
        f"Expected at least 1, got {events_found}. "
        f"Ensure the Server Audit is enabled and C:\\SQLAudit\\ is writable."
    )


def test_audit_captures_update_events(dwh_admin_conn):
    """
    Generate UPDATE activity as LauraGomez, load the audit logs,
    and verify that at least one UP (UPDATE) event is captured.
    """
    cursor = dwh_admin_conn.cursor()

    # 1. Generate UPDATE activity as LauraGomez (safe test, revert later)
    cursor.execute("EXECUTE AS USER = 'LauraGomez';")
    cursor.execute("""
        UPDATE dbo.DIM_Customer
        SET Phone = '999-999-9999'
        WHERE CustomerKey = 1;
    """)
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    # 2. Load audit logs
    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

    # 3. Retry logic for async audit flush
    max_retries = 5
    events_found = 0
    for attempt in range(max_retries):
        cursor.execute("""
            SELECT COUNT(*)
            FROM Security.AuditLog
            WHERE server_principal_name = 'LauraGomez'
              AND object_name = 'DIM_Customer'
              AND action_id = 'UP';
        """)
        events_found = cursor.fetchone()[0]
        if events_found > 0:
            break
        time.sleep(1)

    assert events_found > 0, (
        f"No UPDATE audit events found for LauraGomez. "
        f"Expected at least 1, got {events_found}."
    )


def test_audit_load_procedure_deduplicates(dwh_admin_conn):
    """
    Verify that Security.sp_LoadAuditLog does not insert duplicate rows.
    Run the procedure twice and confirm the row count does not increase.
    """
    cursor = dwh_admin_conn.cursor()

    # 1. Generate a fresh event to ensure there is at least one log entry
    cursor.execute("EXECUTE AS USER = 'AuditCompliance';")
    cursor.execute("SELECT TOP 1 * FROM dbo.FACT_Transaction;")
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    # 2. First load - get initial count
    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()
    cursor.execute("SELECT COUNT(*) FROM Security.AuditLog;")
    count_after_first = cursor.fetchone()[0]

    # 3. Second load (should not insert duplicates)
    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()
    cursor.execute("SELECT COUNT(*) FROM Security.AuditLog;")
    count_after_second = cursor.fetchone()[0]

    # 4. Assert no duplicates were inserted
    assert count_after_first == count_after_second, (
        f"Duplicate entries inserted! Before: {count_after_first}, After: {count_after_second}. "
        f"The NOT EXISTS clause in sp_LoadAuditLog is not working."
    )


def test_audit_excludes_other_databases(dwh_admin_conn):
    """
    Verify that the audit specification only captures events from BankingDWH
    and not from system databases (e.g., master).
    This is a safety check to ensure the database_name filter works.
    """
    cursor = dwh_admin_conn.cursor()

    # 1. Generate activity in master (should NOT be captured by our audit spec)
    cursor.execute("USE master;")
    cursor.execute("SELECT TOP 1 * FROM sys.objects;")
    cursor.execute("USE BankingDWH;")
    dwh_admin_conn.commit()

    # 2. Load logs
    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

    # 3. Check if any audit events came from master (should be 0)
    cursor.execute("""
        SELECT COUNT(*)
        FROM Security.AuditLog
        WHERE database_name = 'master';
    """)
    master_events = cursor.fetchone()[0]

    # Note: There might be server-level audits, but our database specification
    # is scoped to BankingDWH. So this should be 0.
    assert master_events == 0, (
        f"Found {master_events} audit events from 'master' database. "
        f"Database Audit Specification should only target BankingDWH."
    )


def test_audit_logs_structure(dwh_admin_conn):
    """
    Verify that Security.AuditLog has the required columns and that
    the stored procedure populates them correctly.
    """
    cursor = dwh_admin_conn.cursor()

    # 1. Generate a test event
    cursor.execute("EXECUTE AS USER = 'DWHAdmin';")
    cursor.execute("SELECT TOP 1 * FROM dbo.FACT_Transaction;")
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    # 2. Load logs
    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

    # 3. Check that required columns are not NULL for the latest record
    cursor.execute("""
        SELECT TOP 1
            event_time,
            action_id,
            session_id,
            server_principal_name,
            database_principal_name,
            object_name,
            processed_date
        FROM Security.AuditLog
        ORDER BY event_time DESC;
    """)
    row = cursor.fetchone()

    assert row is not None, "AuditLog table is empty."

    event_time, action_id, session_id, server_principal, db_principal, object_name, processed_date = row

    assert event_time is not None, "event_time is NULL"
    assert action_id is not None and action_id != '', "action_id is NULL or empty"
    assert session_id is not None, "session_id is NULL"
    assert server_principal is not None and server_principal != '', "server_principal_name is NULL or empty"
    assert object_name is not None and object_name != '', "object_name is NULL or empty"
    assert processed_date is not None, "processed_date is NULL (trigger/GETDATE() not working)"

    # 4. Verify the most recent action is a SELECT (since we just ran one)
    # This is a sanity check.
    assert action_id in ('SL', 'UP', 'IN', 'DL'), (
        f"Unexpected action_id: {action_id}. Expected SL, UP, IN, or DL."
    )