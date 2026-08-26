import pyodbc
import pytest

@pytest.fixture
def conn():
    """Return a connection to BankingDWH as DWHAdmin (sysadmin equivalent)."""
    return pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=localhost;'
        'DATABASE=BankingDWH;'
        'Trusted_Connection=yes;'
    )

@pytest.fixture
def conn_as_user():
    """Factory fixture to connect as a specific user."""
    def _conn_as_user(username, password):
        return pyodbc.connect(
            'DRIVER={ODBC Driver 17 for SQL Server};'
            'SERVER=localhost;'
            'DATABASE=BankingDWH;'
            f'UID={username};'
            f'PWD={password};'
        )
    return _conn_as_user