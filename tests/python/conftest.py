import pyodbc
import pytest
import os

@pytest.fixture
def dwh_admin_conn():
    """
    Connection using SQL Authentication with a privileged user.
    Store the password in an environment variable for security.
    """
    return pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=localhost;'
        'DATABASE=BankingDWH;'
        'UID=sa;'
        f'PWD={os.environ["SA_PWD"]};'   # Set environment variable SA_PWD
    )