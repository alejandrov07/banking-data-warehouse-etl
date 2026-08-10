import pandas as pd
import pyodbc
from sqlalchemy import create_engine, text
from datetime import datetime, timedelta
import os

# ============================================
# CONFIGURACIÓN DE CONEXIÓN A SQL SERVER
# ============================================
# Usando autenticación de Windows (trusted_connection=yes)
# Driver: "ODBC Driver 17 for SQL Server" es el más común.
# Si te da error, prueba con "SQL Server Native Client 11.0" o "ODBC Driver 18 for SQL Server"
connection_string = "mssql+pyodbc://./BankingDWH?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
engine = create_engine(connection_string)

def ejecutar_sql(comando):
    """Ejecuta un comando SQL sin retornar resultados."""
    with engine.connect() as conn:
        conn.execute(text(comando))
        conn.commit()

# ============================================
# 1. POBLAR DIM_TIEMPO
# ============================================
def poblar_dim_tiempo():
    """Genera fechas desde 2020-01-01 hasta 2030-12-31 y las inserta en DIM_Tiempo."""
    print("Poblando DIM_Tiempo...")
    fechas = []
    start = datetime(2020, 1, 1)
    end = datetime(2030, 12, 31)
    current = start
    while current <= end:
        fechas.append({
            'Fecha': current.date(),
            'Anio': current.year,
            'Trimestre': (current.month - 1) // 3 + 1,
            'Mes': current.month,
            'MesNombre': current.strftime('%B'),
            'Semana': current.isocalendar()[1],
            'DiaSemana': current.isocalendar()[2] + 1,  # 1=Dom, 7=Sab
            'DiaSemanaNombre': current.strftime('%A'),
            'EsFinDeSemana': 1 if current.isocalendar()[2] >= 6 else 0,
            'EsDiaFestivo': 0
        })
        current += timedelta(days=1)
    df = pd.DataFrame(fechas)
    # Limpiar la tabla antes de insertar (para evitar duplicados al ejecutar varias veces)
    ejecutar_sql("DELETE FROM DIM_Tiempo")
    df.to_sql('DIM_Tiempo', engine, if_exists='append', index=False)
    print(f"DIM_Tiempo poblada con {len(df)} registros.")

# ============================================
# 2. PROCESAR DIM_Cliente
# ============================================
def procesar_clientes():
    print("Procesando DIM_Cliente...")
    df_core = pd.read_csv('data/raw/clientes_core.csv', encoding='utf-8')
    df_tar = pd.read_csv('data/raw/clientes_tarjetas.csv', encoding='utf-8')

    # Limpiar cédulas: solo dígitos y rellenar a 11 dígitos
    def limpiar_cedula(val):
        if pd.isna(val):
            return None
        # Eliminar todo excepto dígitos
        limpio = ''.join(filter(str.isdigit, str(val)))
        # Rellenar con ceros a la izquierda para tener 11 dígitos
        return limpio.zfill(11) if limpio else None

    print("--- Limpiando cédulas ---")
    df_core['Cedula'] = df_core['Cedula'].apply(limpiar_cedula)
    df_tar['Cedula'] = df_tar['Cedula'].apply(limpiar_cedula)

    # Añadir fuente
    df_core['FuenteOrigen'] = 'Core'
    df_tar['FuenteOrigen'] = 'Tarjetas'

    print(f"Core antes de deduplicar: {len(df_core)}")
    print(f"Tarjetas antes de deduplicar: {len(df_tar)}")

    # ---- DEDUPLICACIÓN EXPLÍCITA ----
    # Separar Core y Tarjetas con cédula no nula
    df_core_con_cedula = df_core[df_core['Cedula'].notna()]
    df_tar_con_cedula = df_tar[df_tar['Cedula'].notna()]

    # Cédulas de Core
    cedulas_core_set = set(df_core_con_cedula['Cedula'].unique())
    print(f"Cédulas de Core: {len(cedulas_core_set)}")

    # Filtrar Tarjetas que NO están en Core (las únicas que se agregan)
    df_tar_nuevos = df_tar_con_cedula[~df_tar_con_cedula['Cedula'].isin(cedulas_core_set)]
    print(f"Tarjetas con cédula nueva (no duplicada): {len(df_tar_nuevos)}")

    # Tarjetas sin cédula (se agregan todas porque no pueden duplicar)
    df_tar_sin_cedula = df_tar[df_tar['Cedula'].isna()]
    print(f"Tarjetas sin cédula: {len(df_tar_sin_cedula)}")

    # Concatenar: Core + Tarjetas nuevas + Tarjetas sin cédula
    df_final = pd.concat([df_core, df_tar_nuevos, df_tar_sin_cedula], ignore_index=True)

    print(f"Total de clientes final: {len(df_final)}")

    # Rellenar columnas faltantes
    for col in ['FechaNacimiento', 'Genero', 'Email', 'Telefono', 'Ciudad', 'EsActivo']:
        if col not in df_final.columns:
            df_final[col] = None

    df_final['EsActivo'] = df_final['EsActivo'].fillna(1).astype(int)

    # Seleccionar columnas destino
    columnas_destino = ['ClienteID_Source', 'FuenteOrigen', 'Cedula', 'NombreCompleto',
                        'FechaNacimiento', 'Genero', 'Email', 'Telefono', 'Ciudad', 'EsActivo']
    df_final = df_final[columnas_destino]
    df_final = df_final.dropna(subset=['ClienteID_Source'])

    # Limpiar tabla y cargar
    ejecutar_sql("DELETE FROM DIM_Cliente")
    df_final.to_sql('DIM_Cliente', engine, if_exists='append', index=False)
    print(f"DIM_Cliente cargada con {len(df_final)} registros.")
    return df_final

# ============================================
# 3. PROCESAR DIM_Producto
# ============================================
def procesar_productos():
    print("Procesando DIM_Producto...")
    df_core = pd.read_csv('data/raw/productos_core.csv', encoding='utf-8')
    df_tar = pd.read_csv('data/raw/productos_tarjetas.csv', encoding='utf-8')

    # Añadir FuenteOrigen
    df_core['FuenteOrigen'] = 'Core'
    df_tar['FuenteOrigen'] = 'Tarjetas'

    # Unificar
    df_productos = pd.concat([df_core, df_tar], ignore_index=True)

    # Si hay productos duplicados por ProductoID_Source, eliminarlos
    df_productos = df_productos.drop_duplicates(subset=['ProductoID_Source'], keep='first')

    # Limpiar nombres
    df_productos['NombreProducto'] = df_productos['NombreProducto'].str.title()

    # Seleccionar columnas destino
    columnas_destino = ['ProductoID_Source', 'FuenteOrigen', 'CodigoProducto', 'NombreProducto',
                        'Categoria', 'TasaInteres']
    # Asegurar que las columnas existen
    for col in columnas_destino:
        if col not in df_productos.columns:
            df_productos[col] = None

    df_productos = df_productos[columnas_destino]

    ejecutar_sql("DELETE FROM DIM_Producto")
    df_productos.to_sql('DIM_Producto', engine, if_exists='append', index=False)
    print(f"DIM_Producto cargada con {len(df_productos)} registros.")
    return df_productos

# ============================================
# 4. PROCESAR DIM_Sucursal
# ============================================
def procesar_sucursales():
    print("Procesando DIM_Sucursal...")
    df = pd.read_csv('data/raw/sucursales_core.csv', encoding='utf-8')
    # Asegurar columnas
    if 'EsActiva' not in df.columns:
        df['EsActiva'] = 1

    columnas_destino = ['SucursalID_Source', 'NombreSucursal', 'Ciudad', 'EsActiva']
    df = df[columnas_destino]

    ejecutar_sql("DELETE FROM DIM_Sucursal")
    df.to_sql('DIM_Sucursal', engine, if_exists='append', index=False)
    print(f"DIM_Sucursal cargada con {len(df)} registros.")
    return df

# ============================================
# 5. PROCESAR FACT_Transaccion (La más compleja)
# ============================================
def procesar_transacciones():
    print("Procesando FACT_Transaccion...")

    # Leer mapas de claves desde la base de datos
    # (Leemos las claves sustitutas recién generadas para poder mapear los IDs origen)
    print("Cargando mapas de claves desde la base de datos...")

    # Mapa de ClienteKey (usando ClienteID_Source)
    df_cli_map = pd.read_sql("SELECT ClienteKey, ClienteID_Source FROM DIM_Cliente", engine)
    # Mapa de ProductoKey
    df_prod_map = pd.read_sql("SELECT ProductoKey, ProductoID_Source FROM DIM_Producto", engine)
    # Mapa de SucursalKey
    df_suc_map = pd.read_sql("SELECT SucursalKey, SucursalID_Source FROM DIM_Sucursal", engine)
    # Mapa de TiempoKey (por Fecha)
    df_tiempo_map = pd.read_sql("SELECT TiempoKey, Fecha FROM DIM_Tiempo", engine)

    # Leer transacciones de ambas fuentes
    df_core = pd.read_csv('data/raw/transacciones_core.csv', encoding='utf-8')
    df_tar = pd.read_csv('data/raw/transacciones_tarjetas.csv', encoding='utf-8')

    # Añadir FuenteOrigen
    df_core['FuenteOrigen'] = 'Core'
    df_tar['FuenteOrigen'] = 'Tarjetas'

    # Unificar
    df_trans = pd.concat([df_core, df_tar], ignore_index=True)

    # Asegurar columnas
    for col in ['Monto', 'Cantidad']:
        if col not in df_trans.columns:
            df_trans[col] = None

    # Convertir fechas a tipo date
    df_trans['Fecha'] = pd.to_datetime(df_trans['Fecha']).dt.date

    # ---- MAPEO DE CLAVES ----
    # Unir con los mapas para obtener las claves sustitutas
    df_trans = df_trans.merge(df_cli_map, left_on='ClienteID_Source', right_on='ClienteID_Source', how='left')
    df_trans = df_trans.merge(df_prod_map, left_on='ProductoID_Source', right_on='ProductoID_Source', how='left')
    df_trans = df_trans.merge(df_suc_map, left_on='SucursalID_Source', right_on='SucursalID_Source', how='left')
    df_trans = df_trans.merge(df_tiempo_map, left_on='Fecha', right_on='Fecha', how='left')

    # Si algún mapeo falló, esos registros se perderán. Vamos a filtrar solo los que tienen todas las claves.
    df_trans = df_trans.dropna(subset=['ClienteKey', 'ProductoKey', 'TiempoKey'])

    # ---- REGLAS DE CALIDAD ----
    # R001: Al menos una métrica (Monto o Cantidad) debe tener valor
    df_trans['FlagCalidad'] = 1
    df_trans['ObservacionCalidad'] = None

    # Condición R001
    cond_r001 = (df_trans['Monto'].isna()) & (df_trans['Cantidad'].isna())
    df_trans.loc[cond_r001, 'FlagCalidad'] = 0
    df_trans.loc[cond_r001, 'ObservacionCalidad'] = 'Transaccion sin monto ni cantidad'

    # R002: Monto no puede ser negativo
    cond_r002 = (df_trans['Monto'] < 0) & (~df_trans['Monto'].isna())
    df_trans.loc[cond_r002, 'FlagCalidad'] = 0
    df_trans.loc[cond_r002, 'ObservacionCalidad'] = 'Monto negativo detectado'

    # ---- CONVERSIÓN DE MONEDA ----
    # Simular tasa de cambio fija (1 USD = 60 DOP) para el ejemplo
    tasa_cambio = 60
    df_trans['MontoUSD'] = df_trans['Monto'] / tasa_cambio

    # ---- PREPARAR DATOS FINALES ----
    # Seleccionar columnas que van a la tabla FACT_Transaccion
    columnas_destino = ['ClienteKey', 'ProductoKey', 'TiempoKey', 'SucursalKey',
                        'Monto', 'MontoUSD', 'Cantidad', 'TransaccionID_Source',
                        'FuenteOrigen', 'TipoTransaccion', 'Canal', 'Estatus',
                        'FlagCalidad', 'ObservacionCalidad']

    # Asegurar que todas las columnas existen
    for col in columnas_destino:
        if col not in df_trans.columns:
            df_trans[col] = None

    df_trans = df_trans[columnas_destino]

    # Para campos que sean nulos pero deben ser NOT NULL en la BD (por ej. ClienteKey ya lo aseguramos)
    # Convertir NaN a None para SQL
    df_trans = df_trans.where(pd.notnull(df_trans), None)

    # Limpiar la tabla
    ejecutar_sql("DELETE FROM FACT_Transaccion")
    df_trans.to_sql('FACT_Transaccion', engine, if_exists='append', index=False)
    print(f"FACT_Transaccion cargada con {len(df_trans)} registros.")

    # ---- GENERAR LOG DE CALIDAD ----
    df_errores = df_trans[df_trans['FlagCalidad'] == 0][['TransaccionID_Source', 'ObservacionCalidad']]
    if not df_errores.empty:
        os.makedirs('data/logs', exist_ok=True)
        df_errores.to_csv('data/logs/errores_calidad.csv', index=False, encoding='utf-8')
        print(f"Se generó log de errores con {len(df_errores)} registros en data/logs/errores_calidad.csv")
    else:
        print("No se detectaron errores de calidad.")

# ============================================
# EJECUCIÓN PRINCIPAL DEL PIPELINE
# ============================================
if __name__ == "__main__":
    print("=== INICIANDO PIPELINE ETL ===")

    # Verificar que los CSVs existen
    if not os.path.exists('data/raw/clientes_core.csv'):
        print("ERROR: No se encuentran los archivos CSV en data/raw/.")
        print("Ejecuta primero 'generar_datos.py' para crear los archivos.")
        exit(1)

    try:
        # Poblar dimensión tiempo
        poblar_dim_tiempo()

        # Procesar dimensiones
        procesar_clientes()
        procesar_productos()
        procesar_sucursales()

        # Procesar hechos (depende de las claves generadas en las dimensiones)
        procesar_transacciones()

        print("=== PIPELINE ETL COMPLETADO EXITOSAMENTE ===")
    except Exception as e:
        print(f"ERROR durante la ejecución del ETL: {e}")
        import traceback
        traceback.print_exc()