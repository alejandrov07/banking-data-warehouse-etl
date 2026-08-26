import pytest

def test_ddm_masked_for_analyst(dwh_admin_conn):
    """LauraGomez should see masked values."""
    cursor = dwh_admin_conn.cursor()

    cursor.execute("EXECUTE AS USER = 'LauraGomez';")
    cursor.execute("SELECT TOP 1 Cedula, Email, Phone FROM dbo.DIM_Customer WHERE CustomerKey = 1;")
    row = cursor.fetchone()
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    cedula, email, phone = row

    assert 'XXXX-' in cedula, "Cedula should be masked with XXXX-"
    assert email == 'aXXX@XXXX.com' or (email.startswith('a') and '@XXXX.' in email), "Email should be masked using SQL Server's built-in email() format"
    assert 'XXXX-XXXX-' in phone, "Phone should be masked"

def test_ddm_unmasked_for_auditor(dwh_admin_conn):
    """AuditCompliance should see unmasked values."""
    cursor = dwh_admin_conn.cursor()

    cursor.execute("EXECUTE AS USER = 'AuditCompliance';")
    cursor.execute("SELECT TOP 1 Cedula, Email, Phone FROM dbo.DIM_Customer WHERE CustomerKey = 1;")
    row = cursor.fetchone()
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    cedula, email, phone = row

    assert 'XXXX-' not in cedula, "Cedula should not be masked"
    assert '@' in email and '.' in email, "Email should be fully visible"
    assert 'XXXX-XXXX-' not in phone, "Phone should not be masked"