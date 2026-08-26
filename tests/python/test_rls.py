import pytest

EXPECTED = {
    'LauraGomez': {'transactions': 31, 'customers': 14},
    'CarlosMendez': {'transactions': 14, 'customers': 12},
    'AuditCompliance': {'transactions': 63, 'customers': 20},
    'DWHAdmin': {'transactions': 63, 'customers': 20},
    'ETLService': {'transactions': 63, 'customers': 20},
}

@pytest.mark.parametrize('username,expected', EXPECTED.items())
def test_rls_counts(conn_as_user, username, expected):
    """Test that each user sees the correct row counts."""
    # Skip if we don't have passwords for all users – for local testing we use Trusted Connection
    # For a real test, you would need to pass passwords or use EXECUTE AS.
    # This version uses the connection as DWHAdmin and impersonates with EXECUTE AS.
    # Alternatively, you can use a separate connection string per user.
    conn = conn_as_user(username, 'password')  # Replace with actual password logic
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM dbo.FACT_Transaction")
    trans_count = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM dbo.DIM_Customer")
    cust_count = cursor.fetchone()[0]

    assert trans_count == expected['transactions'], \
        f"{username} saw {trans_count} transactions, expected {expected['transactions']}"
    assert cust_count == expected['customers'], \
        f"{username} saw {cust_count} customers, expected {expected['customers']}"

    conn.close()