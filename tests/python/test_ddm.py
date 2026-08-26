import pytest

def test_ddm_masked_for_analyst(conn_as_user):
    """LauraGomez should see masked values."""
    conn = conn_as_user('LauraGomez', 'password')
    cursor = conn.cursor()
    cursor.execute("SELECT Cedula, Email, Phone FROM dbo.DIM_Customer WHERE CustomerKey = 1")
    row = cursor.fetchone()
    cedula, email, phone = row

    assert 'XXXX-' in cedula, "Cedula should be masked with XXXX-"
    assert email.startswith('a') and email.endswith('@email.com'), "Email should be masked"
    assert 'XXXX-XXXX-' in phone, "Phone should be masked"
    conn.close()

def test_ddm_unmasked_for_auditor(conn_as_user):
    """AuditCompliance should see unmasked values."""
    conn = conn_as_user('AuditCompliance', 'password')
    cursor = conn.cursor()
    cursor.execute("SELECT Cedula, Email, Phone FROM dbo.DIM_Customer WHERE CustomerKey = 1")
    row = cursor.fetchone()
    cedula, email, phone = row

    assert 'XXXX-' not in cedula, "Cedula should not be masked"
    assert '@' in email and '.' in email, "Email should be fully visible"
    assert 'XXXX-XXXX-' not in phone, "Phone should not be masked"
    conn.close()