import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
import os

np.random.seed(42)
random.seed(42)

RAW_DIR = os.path.join(os.path.dirname(__file__), '..', 'data', 'raw')
os.makedirs(RAW_DIR, exist_ok=True)

def generate_customers(n=20):
    first_names = ['Juan', 'Maria', 'Carlos', 'Ana', 'Luis', 'Laura', 'Pedro', 'Sofia',
                   'Miguel', 'Elena', 'Jose', 'Carmen', 'David', 'Isabel', 'Javier',
                   'Teresa', 'Francisco', 'Patricia', 'Antonio', 'Marta']
    last_names = ['Garcia', 'Rodriguez', 'Lopez', 'Martinez', 'Gonzalez', 'Perez',
                  'Sanchez', 'Ramirez', 'Torres', 'Flores', 'Rivera', 'Morales',
                  'Ortiz', 'Cruz', 'Reyes', 'Gutierrez', 'Mendoza', 'Herrera',
                  'Vargas', 'Castro']

    customers = []
    for i in range(n):
        first = random.choice(first_names)
        last = random.choice(last_names)
        cedula = f"{random.randint(1, 31):03d}-{random.randint(100000, 999999)}-{random.randint(1, 9)}"
        email = f"{first.lower()}.{last.lower()}@email.com"
        phone = f"809-{random.randint(100, 999)}-{random.randint(1000, 9999)}"
        city = random.choice(['Santo Domingo', 'Santiago', 'La Vega', 'San Francisco', 'Puerto Plata'])
        reg_date = datetime.now() - timedelta(days=random.randint(1, 365*3))

        customers.append({
            'CustomerKey': i + 1,
            'CustomerID': f'C{str(i+1).zfill(4)}',
            'FullName': f"{first} {last}",
            'Cedula': cedula,
            'Email': email,
            'Phone': phone,
            'City': city,
            'RegistrationDate': reg_date.date()
        })
    return pd.DataFrame(customers)

def generate_products(n=10):
    products = [
        {'ProductKey': 1, 'ProductCode': 'P001', 'ProductName': 'Cuenta Corriente', 'Category': 'Cuentas', 'UnitPrice': 0},
        {'ProductKey': 2, 'ProductCode': 'P002', 'ProductName': 'Cuenta Ahorro', 'Category': 'Cuentas', 'UnitPrice': 0},
        {'ProductKey': 3, 'ProductCode': 'P003', 'ProductName': 'Tarjeta Credito Oro', 'Category': 'Tarjetas', 'UnitPrice': 120.00},
        {'ProductKey': 4, 'ProductCode': 'P004', 'ProductName': 'Tarjeta Credito Platinum', 'Category': 'Tarjetas', 'UnitPrice': 250.00},
        {'ProductKey': 5, 'ProductCode': 'P005', 'ProductName': 'Prestamo Personal', 'Category': 'Prestamos', 'UnitPrice': 0},
        {'ProductKey': 6, 'ProductCode': 'P006', 'ProductName': 'Prestamo Hipotecario', 'Category': 'Prestamos', 'UnitPrice': 0},
        {'ProductKey': 7, 'ProductCode': 'P007', 'ProductName': 'Certificado Deposito', 'Category': 'Inversiones', 'UnitPrice': 0},
        {'ProductKey': 8, 'ProductCode': 'P008', 'ProductName': 'Fondo Inversion', 'Category': 'Inversiones', 'UnitPrice': 0},
        {'ProductKey': 9, 'ProductCode': 'P009', 'ProductName': 'Seguro Vida', 'Category': 'Seguros', 'UnitPrice': 45.00},
        {'ProductKey': 10, 'ProductCode': 'P010', 'ProductName': 'Seguro Vehicular', 'Category': 'Seguros', 'UnitPrice': 75.00}
    ]
    return pd.DataFrame(products[:n])

def generate_dates(start_date='2024-01-01', end_date='2024-12-31'):
    dates = pd.date_range(start=start_date, end=end_date)
    return pd.DataFrame({
        'DateKey': dates.strftime('%Y%m%d').astype(int),
        'FullDate': dates.date,
        'Year': dates.year,
        'Quarter': dates.quarter,
        'Month': dates.month,
        'MonthName': dates.strftime('%B'),
        'DayOfWeek': dates.dayofweek + 1,
        'DayName': dates.strftime('%A'),
        'IsWeekend': (dates.dayofweek >= 5).astype(int)
    })

def generate_branches():
    branches = [
        {'BranchKey': 1, 'BranchCode': 'BR01', 'BranchName': 'Santo Domingo Central', 'City': 'Santo Domingo', 'Region': 'Distrito Nacional'},
        {'BranchKey': 2, 'BranchCode': 'BR02', 'BranchName': 'Santiago Centro', 'City': 'Santiago', 'Region': 'Santiago'},
        {'BranchKey': 3, 'BranchCode': 'BR03', 'BranchName': 'La Vega Principal', 'City': 'La Vega', 'Region': 'La Vega'},
        {'BranchKey': 4, 'BranchCode': 'BR04', 'BranchName': 'Puerto Plata Malecon', 'City': 'Puerto Plata', 'Region': 'Puerto Plata'},
        {'BranchKey': 5, 'BranchCode': 'BR05', 'BranchName': 'San Francisco Plaza', 'City': 'San Francisco', 'Region': 'Duarte'}
    ]
    return pd.DataFrame(branches)

def generate_transactions(customers_df, products_df, dates_df, branches_df, n=63):
    transactions = []
    for i in range(n):
        customer = customers_df.sample(1).iloc[0]
        product = products_df.sample(1).iloc[0]
        date = dates_df.sample(1).iloc[0]
        branch = branches_df.sample(1).iloc[0]

        transactions.append({
            'CustomerKey': customer['CustomerKey'],
            'ProductKey': product['ProductKey'],
            'DateKey': date['DateKey'],
            'BranchKey': branch['BranchKey'],
            'Amount': round(random.uniform(100, 5000), 2),
            'Quantity': random.randint(1, 5),
            'TransactionType': random.choice(['Purchase', 'Withdrawal', 'Deposit', 'Transfer']),
            'FlagQuality': 1 if random.random() > 0.1 else 0
        })
    return pd.DataFrame(transactions)

def generate_all():
    print("Generating data...")
    customers = generate_customers(20)
    products = generate_products(10)
    dates = generate_dates('2024-01-01', '2024-12-31')
    branches = generate_branches()
    transactions = generate_transactions(customers, products, dates, branches, 63)

    customers.to_csv(os.path.join(RAW_DIR, 'customers.csv'), index=False)
    products.to_csv(os.path.join(RAW_DIR, 'products.csv'), index=False)
    dates.to_csv(os.path.join(RAW_DIR, 'dates.csv'), index=False)
    branches.to_csv(os.path.join(RAW_DIR, 'branches.csv'), index=False)
    transactions.to_csv(os.path.join(RAW_DIR, 'transactions.csv'), index=False)

    print(f"Generated: {len(customers)} customers, {len(products)} products, {len(dates)} dates, {len(branches)} branches, {len(transactions)} transactions")

if __name__ == "__main__":
    generate_all()