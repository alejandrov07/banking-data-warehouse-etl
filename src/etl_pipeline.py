import pandas as pd
import os
from sqlalchemy import create_engine, text
from urllib.parse import quote_plus
from dotenv import load_dotenv
import traceback

load_dotenv()

DB_USER = os.environ["DB_USER"]
DB_PASSWORD = quote_plus(os.environ["DB_PASSWORD"])
DB_SERVER = os.environ["DB_SERVER"]
DB_NAME = os.environ["DB_NAME"]

CONNECTION_STRING = (
    f"mssql+pyodbc://{DB_USER}:{DB_PASSWORD}@{DB_SERVER}/{DB_NAME}"
    f"?driver=ODBC+Driver+17+for+SQL+Server"
)

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')

def load_data():
    engine = create_engine(CONNECTION_STRING)
    
    try:
        df_customers = pd.read_csv(os.path.join(DATA_DIR, 'customers.csv'))
        print(f"Read {len(df_customers)} rows from customers.csv")
        with engine.begin() as conn:
            conn.execute(text("SET IDENTITY_INSERT dbo.DIM_Customer ON;"))
            df_customers.to_sql('DIM_Customer', conn, if_exists='append', index=False)
            conn.execute(text("SET IDENTITY_INSERT dbo.DIM_Customer OFF;"))
        print("DIM_Customer loaded.")
    except Exception as e:
        print("ERROR loading DIM_Customer:")
        traceback.print_exc()
        return

    try:
        df_products = pd.read_csv(os.path.join(DATA_DIR, 'products.csv'))
        print(f"Read {len(df_products)} rows from products.csv")
        with engine.begin() as conn:
            conn.execute(text("SET IDENTITY_INSERT dbo.DIM_Product ON;"))
            df_products.to_sql('DIM_Product', conn, if_exists='append', index=False)
            conn.execute(text("SET IDENTITY_INSERT dbo.DIM_Product OFF;"))
        print("DIM_Product loaded.")
    except Exception as e:
        print("ERROR loading DIM_Product:")
        traceback.print_exc()
        return

    try:
        df_dates = pd.read_csv(os.path.join(DATA_DIR, 'dates.csv'))
        print(f"Read {len(df_dates)} rows from dates.csv")
        df_dates.to_sql('DIM_Date', engine, if_exists='append', index=False)
        print("DIM_Date loaded.")
    except Exception as e:
        print("ERROR loading DIM_Date:")
        traceback.print_exc()
        return

    try:
        df_branches = pd.read_csv(os.path.join(DATA_DIR, 'branches.csv'))
        print(f"Read {len(df_branches)} rows from branches.csv")
        with engine.begin() as conn:
            conn.execute(text("SET IDENTITY_INSERT dbo.DIM_Branch ON;"))
            df_branches.to_sql('DIM_Branch', conn, if_exists='append', index=False)
            conn.execute(text("SET IDENTITY_INSERT dbo.DIM_Branch OFF;"))
        print("DIM_Branch loaded.")
    except Exception as e:
        print("ERROR loading DIM_Branch:")
        traceback.print_exc()
        return

    # --- DEBUG: Load transactions one by one ---
    try:
        df_transactions = pd.read_csv(os.path.join(DATA_DIR, 'transactions.csv'))
        print(f"Read {len(df_transactions)} rows from transactions.csv")
        print("First 5 rows of transactions:")
        print(df_transactions.head())
        print("")

        # Insert each row individually to isolate any problematic row
        with engine.begin() as conn:
            for idx, row in df_transactions.iterrows():
                try:
                    conn.execute(
                        text("""
                            INSERT INTO FACT_Transaction (
                                CustomerKey, ProductKey, DateKey, BranchKey, 
                                Amount, Quantity, TransactionType, FlagQuality
                            ) VALUES (
                                :CustomerKey, :ProductKey, :DateKey, :BranchKey,
                                :Amount, :Quantity, :TransactionType, :FlagQuality
                            )
                        """),
                        {
                            'CustomerKey': int(row['CustomerKey']),
                            'ProductKey': int(row['ProductKey']),
                            'DateKey': int(row['DateKey']),
                            'BranchKey': int(row['BranchKey']),
                            'Amount': float(row['Amount']),
                            'Quantity': int(row['Quantity']),
                            'TransactionType': str(row['TransactionType']),
                            'FlagQuality': int(row['FlagQuality'])
                        }
                    )
                except Exception as e:
                    print(f"ERROR on row {idx + 1}: {row.to_dict()}")
                    print(f"Error: {e}")
                    raise
            print("FACT_Transaction loaded (all 63 rows inserted individually).")
    except Exception as e:
        print("ERROR loading FACT_Transaction:")
        traceback.print_exc()
        return

    print("ETL completed successfully.")

if __name__ == "__main__":
    load_data()