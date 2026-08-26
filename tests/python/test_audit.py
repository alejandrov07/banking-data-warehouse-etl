"""
test_audit.py
Validates Native SQL Server Auditing for BankingDWH.
"""

import time
import pytest

def test_audit_captures_select_events(dwh_admin_conn):
    cursor = dwh_admin_conn.cursor()

    cursor.execute("EXECUTE AS USER = 'LauraGomez';")
    cursor.execute("SELECT TOP 5 * FROM dbo.FACT_Transaction;")
    cursor.execute("SELECT TOP 5 * FROM dbo.DIM_Customer;")
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

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
        time.sleep(1)

    assert events_found > 0, (
        f"No SELECT audit events found for LauraGomez. "
        f"Expected at least 1, got {events_found}. "
        f"Ensure the Server Audit is enabled and C:\\SQLAudit\\ is writable."
    )

def test_audit_captures_update_events(dwh_admin_conn):
    cursor = dwh_admin_conn.cursor()

    cursor.execute("EXECUTE AS USER = 'DWHAdmin';")
    cursor.execute("""
        UPDATE dbo.DIM_Customer
        SET Phone = '999-999-9999'
        WHERE CustomerKey = 1;
    """)
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

    max_retries = 5
    events_found = 0
    for attempt in range(max_retries):
        cursor.execute("""
            SELECT COUNT(*)
            FROM Security.AuditLog
            WHERE server_principal_name = 'DWHAdmin'
              AND object_name = 'DIM_Customer'
              AND action_id = 'UP';
        """)
        events_found = cursor.fetchone()[0]
        if events_found > 0:
            break
        time.sleep(1)

    assert events_found > 0, (
        f"No UPDATE audit events found for DWHAdmin. "
        f"Expected at least 1, got {events_found}."
    )

def test_audit_load_procedure_deduplicates(dwh_admin_conn):
    cursor = dwh_admin_conn.cursor()

    cursor.execute("EXECUTE AS USER = 'AuditCompliance';")
    cursor.execute("SELECT TOP 1 * FROM dbo.FACT_Transaction;")
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()
    cursor.execute("SELECT COUNT(*) FROM Security.AuditLog;")
    count_after_first = cursor.fetchone()[0]

    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()
    cursor.execute("SELECT COUNT(*) FROM Security.AuditLog;")
    count_after_second = cursor.fetchone()[0]

    assert count_after_first == count_after_second, (
        f"Duplicate entries inserted! Before: {count_after_first}, After: {count_after_second}."
    )

def test_audit_logs_structure(dwh_admin_conn):
    cursor = dwh_admin_conn.cursor()

    cursor.execute("EXECUTE AS USER = 'DWHAdmin';")
    cursor.execute("SELECT TOP 1 * FROM dbo.FACT_Transaction;")
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    cursor.execute("EXEC Security.sp_LoadAuditLog;")
    dwh_admin_conn.commit()

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
    assert processed_date is not None, "processed_date is NULL"

    assert action_id.strip() in ('SL', 'UP', 'IN', 'DL'), (
        f"Unexpected action_id: '{action_id}'. Expected SL, UP, IN, or DL."
    )