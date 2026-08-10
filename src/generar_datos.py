import pandas as pd
import random
from datetime import datetime, timedelta
import os

os.makedirs('data/raw', exist_ok=True)
random.seed(2026)

# ---------- CLIENTES ----------
nombres = ['Juan Perez', 'Maria Gomez', 'Carlos Rodriguez', 'Ana Martinez', 'Luis Fernandez',
           'Laura Gonzalez', 'Pedro Sanchez', 'Sofia Ramirez', 'Jose Torres', 'Isabel Rivera',
           'Miguel Cruz', 'Elena Ortiz', 'Rafael Castillo', 'Patricia Morales', 'Daniel Reyes']

cedulas_core = ['00123456789', '00198765432', '00111111111', '00222222222', '00333333333',
                '00444444444', '00555555555', '00666666666', '00777777777', '00888888888',
                '00999999999', '00100000000', '00200000000', '00300000000', '00400000000']

# Clientes Core
data_core = []
for i in range(15):
    data_core.append({
        'ClienteID_Source': f'CORE-{1000+i}',
        'NombreCompleto': random.choice(nombres) + ' ' + random.choice(['Sr.', 'Sra.', '']),
        'Cedula': str(cedulas_core[i]).zfill(11),
        'FechaNacimiento': f'{random.randint(1970, 2000)}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}',
        'Genero': random.choice(['M', 'F']),
        'Email': f'cliente{i}@correo.com',
        'Telefono': f'809-{random.randint(100,999)}-{random.randint(1000,9999)}',
        'Ciudad': random.choice(['Santo Domingo', 'Santiago', 'Puerto Plata', 'La Romana']),
        'EsActivo': random.choice([1, 1, 1, 0])
    })
df_core = pd.DataFrame(data_core)

# Clientes Tarjetas (10 clientes, 5 duplicados con Core, 5 únicos)
cedulas_tarjetas = [
    '00123456789',          # duplicado (sin guiones)
    '00198765432',          # duplicado (sin guiones)
    '00555555555',          # duplicado (sin guiones)
    '00999999999',          # duplicado (sin guiones)
    '00100000000',          # duplicado (sin guiones)
    '011-11111111-1',       # único con guiones (para probar limpieza)
    '02222222222',          # único
    '03333333333',          # único
    '04444444444',          # único
    '05555555555'           # único
]

data_tarjetas = []
for i in range(10):
    data_tarjetas.append({
        'ClienteID_Source': f'TARJ-{2000+i}',
        'NombreCompleto': random.choice(nombres) + ' ' + random.choice(['Hijo', 'Hija', '']),
        'Cedula': cedulas_tarjetas[i],
        'FechaNacimiento': f'{random.randint(1970, 2000)}-{random.randint(1, 12):02d}-{random.randint(1, 28):02d}',
        'Genero': random.choice(['M', 'F']),
        'Email': f'tarjeta{i}@correo.com',
        'Telefono': f'809-{random.randint(100,999)}-{random.randint(1000,9999)}',
        'Ciudad': random.choice(['Santo Domingo', 'Santiago', 'Puerto Plata', 'La Romana']),
        'EsActivo': random.choice([1, 1, 1, 0])
    })
df_tarjetas = pd.DataFrame(data_tarjetas)

# Guardar CSVs
df_core.to_csv('data/raw/clientes_core.csv', index=False, encoding='utf-8')
df_tarjetas.to_csv('data/raw/clientes_tarjetas.csv', index=False, encoding='utf-8')

# ---------- PRODUCTOS ----------
productos_core = [
    {'ProductoID_Source': 'P-001', 'NombreProducto': 'Cuenta Ahorro', 'Categoria': 'Ahorro', 'TasaInteres': 3.5},
    {'ProductoID_Source': 'P-002', 'NombreProducto': 'Cuenta Corriente', 'Categoria': 'Corriente', 'TasaInteres': 0.0},
    {'ProductoID_Source': 'P-003', 'NombreProducto': 'Prestamo Personal', 'Categoria': 'Credito', 'TasaInteres': 12.5},
    {'ProductoID_Source': 'P-004', 'NombreProducto': 'Prestamo Hipotecario', 'Categoria': 'Credito', 'TasaInteres': 8.0},
]
df_prod_core = pd.DataFrame(productos_core)
df_prod_core['CodigoProducto'] = ['AH-001', 'CC-001', 'PR-001', 'PH-001']

productos_tarjetas = [
    {'ProductoID_Source': 'T-101', 'NombreProducto': 'Visa Platinum', 'Categoria': 'Tarjeta', 'TasaInteres': 0.0},
    {'ProductoID_Source': 'T-102', 'NombreProducto': 'Mastercard Gold', 'Categoria': 'Tarjeta', 'TasaInteres': 0.0},
    {'ProductoID_Source': 'T-103', 'NombreProducto': 'Visa Clasica', 'Categoria': 'Tarjeta', 'TasaInteres': 0.0},
]
df_prod_tarjetas = pd.DataFrame(productos_tarjetas)
df_prod_tarjetas['CodigoProducto'] = ['VP-101', 'MG-102', 'VC-103']

df_prod_core.to_csv('data/raw/productos_core.csv', index=False, encoding='utf-8')
df_prod_tarjetas.to_csv('data/raw/productos_tarjetas.csv', index=False, encoding='utf-8')

# ---------- SUCURSALES ----------
sucursales = [
    {'SucursalID_Source': 'S-001', 'NombreSucursal': 'Sucursal Naco', 'Ciudad': 'Santo Domingo'},
    {'SucursalID_Source': 'S-002', 'NombreSucursal': 'Oficina Principal', 'Ciudad': 'Santo Domingo'},
    {'SucursalID_Source': 'S-003', 'NombreSucursal': 'Sucursal Santiago', 'Ciudad': 'Santiago'},
    {'SucursalID_Source': 'S-004', 'NombreSucursal': 'Sucursal Puerto Plata', 'Ciudad': 'Puerto Plata'},
]
df_suc = pd.DataFrame(sucursales)
df_suc.to_csv('data/raw/sucursales_core.csv', index=False, encoding='utf-8')

# ---------- TRANSACCIONES ----------
fecha_inicio = datetime(2025, 1, 1)

trans_core = []
for i in range(50):
    fecha = fecha_inicio + timedelta(days=random.randint(0, 500))
    monto = random.randint(100, 10000)
    if i % 10 == 0:
        monto = -monto
    if i == 45:
        monto = None
    trans_core.append({
        'TransaccionID_Source': f'TRC-{1000+i}',
        'ClienteID_Source': f'CORE-{1000 + random.randint(0, 14)}',
        'ProductoID_Source': random.choice(['P-001', 'P-002', 'P-003', 'P-004']),
        'SucursalID_Source': random.choice(['S-001', 'S-002', 'S-003', 'S-004']),
        'Fecha': fecha.strftime('%Y-%m-%d'),
        'Monto': monto,
        'Cantidad': None,
        'TipoTransaccion': random.choice(['Deposito', 'Retiro', 'Pago']),
        'Canal': random.choice(['Sucursal', 'ATM', 'App Movil', 'Web']),
        'Estatus': 'Completada'
    })
df_tr_core = pd.DataFrame(trans_core)

trans_tar = []
for i in range(30):
    fecha = fecha_inicio + timedelta(days=random.randint(0, 500))
    if i % 5 == 0:
        cantidad = random.randint(1, 10)
        monto = None
    else:
        cantidad = None
        monto = random.randint(500, 20000)
    trans_tar.append({
        'TransaccionID_Source': f'TRT-{2000+i}',
        'ClienteID_Source': f'TARJ-{2000 + random.randint(0, 9)}',
        'ProductoID_Source': random.choice(['T-101', 'T-102', 'T-103']),
        'SucursalID_Source': None,
        'Fecha': fecha.strftime('%Y-%m-%d'),
        'Monto': monto,
        'Cantidad': cantidad,
        'TipoTransaccion': random.choice(['Consumo', 'Pago']),
        'Canal': random.choice(['Punto de Venta', 'Web', 'App Movil']),
        'Estatus': random.choice(['Completada', 'Completada', 'Completada', 'Rechazada'])
    })
df_tr_tar = pd.DataFrame(trans_tar)

df_tr_core.to_csv('data/raw/transacciones_core.csv', index=False, encoding='utf-8')
df_tr_tar.to_csv('data/raw/transacciones_tarjetas.csv', index=False, encoding='utf-8')

print("Datos generados correctamente.")