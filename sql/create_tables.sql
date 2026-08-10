-- ============================================
-- SCRIPT: CREACIÓN DE ESQUEMA ESTRELLA (STAR SCHEMA)
-- PROYECTO: Banking Data Warehouse
-- BASE DE DATOS: SQL Server
-- ============================================


-- ============================================
--  TABLAS DE DIMENSIÓN (DIM)
-- ============================================

-- DIMENSIÓN CLIENTE
CREATE TABLE DIM_Cliente (
    ClienteKey INT IDENTITY(1,1) PRIMARY KEY, -- Clave sustituta (Surrogate Key)
    ClienteID_Source VARCHAR(50) NOT NULL, -- ID del sistema fuente
    FuenteOrigen VARCHAR(20) NOT NULL, -- 'Core' o 'Tarjetas'
    Cedula VARCHAR(20) NULL, -- Identificador único de negocio (Golden Key)
    NombreCompleto VARCHAR(100) NULL,
    FechaNacimiento DATE NULL,
    Genero CHAR(1) NULL, -- 'M', 'F'
    Email VARCHAR(100) NULL,
    Telefono VARCHAR(20) NULL,
    FechaRegistro DATE NULL,
    Pais VARCHAR(50) NULL,
    Ciudad VARCHAR(50) NULL,
    EsActivo BIT DEFAULT 1,
    -- Metadatos de auditoría
    FechaCarga DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE()
);

-- DIMENSIÓN PRODUCTO
CREATE TABLE DIM_Producto (
    ProductoKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID_Source VARCHAR(50) NOT NULL,
    FuenteOrigen VARCHAR(20) NOT NULL, -- 'Core' o 'Tarjetas'
    CodigoProducto VARCHAR(20) NULL, -- Código interno del banco
    NombreProducto VARCHAR(100) NULL,
    Categoria VARCHAR(50) NULL, -- 'Ahorro', 'Credito', 'Tarjeta', etc.
    SubCategoria VARCHAR(50) NULL,
    TasaInteres DECIMAL(5,2) NULL,
    Moneda VARCHAR(10) DEFAULT 'DOP',
    EsActivo BIT DEFAULT 1,
    FechaCarga DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE()
);

-- DIMENSIÓN TIEMPO (Calendario)
CREATE TABLE DIM_Tiempo (
    TiempoKey INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    Anio INT NOT NULL,
    Trimestre INT NOT NULL,
    Mes INT NOT NULL,
    MesNombre VARCHAR(20) NOT NULL,
    Semana INT NOT NULL,
    DiaSemana INT NOT NULL, -- 1 = Domingo, 7 = Sábado
    DiaSemanaNombre VARCHAR(15) NOT NULL,
    EsFinDeSemana BIT DEFAULT 0,
    EsDiaFestivo BIT DEFAULT 0
);

-- DIMENSIÓN SUCURSAL
CREATE TABLE DIM_Sucursal (
    SucursalKey INT IDENTITY(1,1) PRIMARY KEY,
    SucursalID_Source VARCHAR(20) NOT NULL,
    NombreSucursal VARCHAR(100) NOT NULL,
    Ciudad VARCHAR(50) NULL,
    Region VARCHAR(50) NULL,
    EsActiva BIT DEFAULT 1,
    FechaCarga DATETIME DEFAULT GETDATE()
);

-- ============================================
-- TABLA DE HECHOS (FACT) - TRANSACCIONES
-- ============================================

CREATE TABLE FACT_Transaccion (
    TransaccionKey INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves foráneas hacia dimensiones
    ClienteKey INT NOT NULL,
    ProductoKey INT NOT NULL,
    TiempoKey INT NOT NULL,
    SucursalKey INT NULL,
    
    -- Métricas (Hechos)
    Monto DECIMAL(18,2) NULL, -- Permite NULL (productos medidos por cantidad)
    MontoUSD DECIMAL(18,2) NULL, -- Conversión para análisis global
    Cantidad INT NULL, -- Para transacciones por unidades
    
    -- Atributos de la transacción
    TransaccionID_Source VARCHAR(50) NOT NULL, -- ID único del sistema fuente
    FuenteOrigen VARCHAR(20) NOT NULL, -- 'Core' o 'Tarjetas'
    TipoTransaccion VARCHAR(30) NULL, -- 'Deposito', 'Retiro', 'Pago', 'Consumo'
    Canal VARCHAR(30) NULL, -- 'ATM', 'Sucursal', 'App', 'Web'
    Estatus VARCHAR(20) DEFAULT 'Completada', -- 'Completada', 'Rechazada', 'Pendiente'
    
    -- Metadatos de auditoría y calidad
    FechaCarga DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE(),
    FlagCalidad BIT DEFAULT 1, -- 1 = Datos limpios, 0 = Datos sospechosos
    ObservacionCalidad VARCHAR(255) NULL, -- Detalle de errores de calidad
);

-- ============================================
-- RESTRICCIONES DE INTEGRIDAD REFERENCIAL
-- ============================================

ALTER TABLE FACT_Transaccion ADD CONSTRAINT FK_FACT_Cliente 
    FOREIGN KEY (ClienteKey) REFERENCES DIM_Cliente(ClienteKey);

ALTER TABLE FACT_Transaccion ADD CONSTRAINT FK_FACT_Producto 
    FOREIGN KEY (ProductoKey) REFERENCES DIM_Producto(ProductoKey);

ALTER TABLE FACT_Transaccion ADD CONSTRAINT FK_FACT_Tiempo 
    FOREIGN KEY (TiempoKey) REFERENCES DIM_Tiempo(TiempoKey);

ALTER TABLE FACT_Transaccion ADD CONSTRAINT FK_FACT_Sucursal 
    FOREIGN KEY (SucursalKey) REFERENCES DIM_Sucursal(SucursalKey);

-- ============================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ============================================

CREATE INDEX IDX_FACT_ClienteKey ON FACT_Transaccion(ClienteKey);
CREATE INDEX IDX_FACT_ProductoKey ON FACT_Transaccion(ProductoKey);
CREATE INDEX IDX_FACT_TiempoKey ON FACT_Transaccion(TiempoKey);
CREATE INDEX IDX_FACT_FuenteOrigen ON FACT_Transaccion(FuenteOrigen);
CREATE INDEX IDX_FACT_Estatus ON FACT_Transaccion(Estatus);

-- ============================================
-- COMENTARIOS DE METADATOS
-- ============================================

EXEC sp_addextendedproperty 
    @name = N'Descripcion', 
    @value = N'Dimensión que contiene la información maestra de clientes unificada de múltiples fuentes.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'DIM_Cliente';

EXEC sp_addextendedproperty 
    @name = N'Descripcion', 
    @value = N'Tabla de hechos que almacena las transacciones financieras consolidadas del banco.',
    @level0type = N'SCHEMA', @level0name = N'dbo',
    @level1type = N'TABLE',  @level1name = N'FACT_Transaccion';