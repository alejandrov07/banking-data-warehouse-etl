import pytest

EXPECTED = {
    'LauraGomez': {'transactions': 31, 'customers': 14},
    'CarlosMendez': {'transactions': 14, 'customers': 12},
    'AuditCompliance': {'transactions': 63, 'customers': 20},
    'DWHAdmin': {'transactions': 63, 'customers': 20},
    'ETLService': {'transactions': 63, 'customers': 20},
}

@pytest.mark.parametrize('username,expected', EXPECTED.items())
def test_rls_counts(dwh_admin_conn, username, expected):
    """
    Test RLS counts by impersonating each user with EXECUTE AS.
    """
    cursor = dwh_admin_conn.cursor()

    # Impersonate user
    cursor.execute(f"EXECUTE AS USER = '{username}';")

    # Get transaction count
    cursor.execute("SELECT COUNT(*) FROM dbo.FACT_Transaction;")
    trans_count = cursor.fetchone()[0]

    # Get customer count
    cursor.execute("SELECT COUNT(*) FROM dbo.DIM_Customer;")
    cust_count = cursor.fetchone()[0]

    # Revert to original user
    cursor.execute("REVERT;")
    dwh_admin_conn.commit()

    assert trans_count == expected['transactions'], \
        f"{username} saw {trans_count} transactions, expected {expected['transactions']}"
    assert cust_count == expected['customers'], \
        f"{username} saw {cust_count} customers, expected {expected['customers']}"