# Diccionario de Datos - Banking Data Warehouse

## Proposito del Documento

Este documento describe todas las tablas y columnas que componen el Data Warehouse del proyecto bancario simuado. Su objetivo es servir como guia de referencia para analistas de negocio, desarrolladores y equipos de gobernabilidad, permitiendo entender el significado de cada dato, su origen y las reglas que lo rigen.

El diccionario esta organizado por tablas, siguiendo el modelo Star Schema. Las tablas de dimension (DIM) contienen informacion descriptiva y las tablas de hechos (FACT) contienen metricas numericas.

---

## Convenciones de Nomenclatura

Para mantener la claridad y consistencia en todo el modelo, se aplican las siguientes convenciones:

**Prefijos (indican el tipo de tabla)**

| Prefijo | Significado |
| :--- | :--- |
| DIM_ | Tabla de Dimensión. Contiene atributos descriptivos para filtrar y agrupar. |
| FACT_ | Tabla de Hechos. Contiene métricas numéricas y claves foráneas que conectan con las dimensiones. |

**Sufijos (indican el tipo de columna)**

| Sufijo | Significado |
| :--- | :--- |
| Key | Indica que la columna es una clave primaria (PK) o foránea (FK). Ejemplo: ClienteKey, ProductoKey. |
| Source | Indica que la columna contiene el identificador original del sistema fuente. Ejemplo: ClienteID_Source. |

---

## Tabla: DIM_Cliente

**Descripcion general:** Tabla maestra de clientes. Consolida informacion de las fuentes Core Bancario y Sistema de Tarjetas. Cada registro representa un cliente unico dentro del Data Warehouse, identificado por una clave sustituta (ClienteKey).

**Volumen estimado:** 10,000 - 50,000 registros.

| Nombre Columna | Tipo Dato | PK/FK | Descripcion de Negocio | Origen | Reglas de Calidad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ClienteKey | INT | PK | Identificador unico generado automaticamente para cada cliente dentro del Data Warehouse. No tiene significado en el negocio. Sirve como clave sustituta para conectar con la tabla de hechos. | Generado por el sistema (IDENTITY) | No nulo. Unico. |
| ClienteID_Source | VARCHAR(50) | - | Identificador original del cliente en el sistema fuente. Permite rastrear el registro hasta su origen. | Core Bancario o Sistema de Tarjetas | No nulo. |
| FuenteOrigen | VARCHAR(20) | - | Nombre del sistema del cual proviene el registro. Valores posibles: 'Core' o 'Tarjetas'. | Sistema origen | No nulo. |
| Cedula | VARCHAR(20) | - | Numero de cedula del cliente. Es la clave de negocio utilizada para unificar un mismo cliente entre diferentes fuentes. | Core Bancario o Sistema de Tarjetas | Puede ser nulo si la fuente no la proporciona. Si existe, debe tener el formato de cedula dominicana. |
| NombreCompleto | VARCHAR(100) | - | Nombre y apellidos completos del cliente. | Core Bancario o Sistema de Tarjetas | Puede ser nulo. |
| FechaNacimiento | DATE | - | Fecha de nacimiento del cliente. | Core Bancario | Puede ser nulo. |
| Genero | CHAR(1) | - | Genero del cliente. Valores posibles: 'M' (Masculino), 'F' (Femenino). | Core Bancario | Puede ser nulo. |
| Email | VARCHAR(100) | - | Correo electronico del cliente. | Core Bancario o Sistema de Tarjetas | Puede ser nulo. Debe tener formato de email valido si existe. |
| Telefono | VARCHAR(20) | - | Numero de telefono del cliente. | Core Bancario | Puede ser nulo. |
| FechaRegistro | DATE | - | Fecha en que el cliente se registro en el banco. | Core Bancario | Puede ser nulo. |
| Pais | VARCHAR(50) | - | Pais de residencia del cliente. | Core Bancario | Puede ser nulo. |
| Ciudad | VARCHAR(50) | - | Ciudad de residencia del cliente. | Core Bancario | Puede ser nulo. |
| EsActivo | BIT | - | Indicador de cliente activo. Valor 1 = Activo, 0 = Inactivo. | Core Bancario | No nulo. Valor por defecto: 1. |
| FechaCarga | DATETIME | - | Marca de tiempo de cuando el registro fue insertado por primera vez en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |
| FechaActualizacion | DATETIME | - | Marca de tiempo de la ultima actualizacion del registro en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |

---

## Tabla: DIM_Producto

**Descripcion general:** Tabla maestra de productos financieros. Contiene la informacion de todos los productos que ofrece el banco, como cuentas de ahorro, tarjetas de credito, prestamos, etc.

**Volumen estimado:** 100 - 500 registros.

| Nombre Columna | Tipo Dato | PK/FK | Descripcion de Negocio | Origen | Reglas de Calidad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ProductoKey | INT | PK | Identificador unico generado automaticamente para cada producto dentro del Data Warehouse. Clave sustituta para conectar con la tabla de hechos. | Generado por el sistema (IDENTITY) | No nulo. Unico. |
| ProductoID_Source | VARCHAR(50) | - | Identificador original del producto en el sistema fuente. | Core Bancario o Sistema de Tarjetas | No nulo. |
| FuenteOrigen | VARCHAR(20) | - | Nombre del sistema del cual proviene el registro. Valores posibles: 'Core' o 'Tarjetas'. | Sistema origen | No nulo. |
| CodigoProducto | VARCHAR(20) | - | Codigo interno del producto asignado por el banco. | Core Bancario o Sistema de Tarjetas | Puede ser nulo. |
| NombreProducto | VARCHAR(100) | - | Nombre comercial del producto (ej. 'Cuenta Ahorro Premium', 'Visa Platinum'). | Core Bancario o Sistema de Tarjetas | Puede ser nulo. |
| Categoria | VARCHAR(50) | - | Categoria general del producto. Ejemplos: 'Ahorro', 'Credito', 'Tarjeta', 'Inversion'. | Core Bancario | Puede ser nulo. |
| SubCategoria | VARCHAR(50) | - | Subcategoria dentro de la categoria principal. Ejemplo dentro de 'Tarjeta': 'Credito', 'Debito'. | Core Bancario | Puede ser nulo. |
| TasaInteres | DECIMAL(5,2) | - | Tasa de interes anual asociada al producto, expresada en porcentaje. | Core Bancario | Puede ser nulo. |
| Moneda | VARCHAR(10) | - | Moneda en la que esta denominado el producto. Valor por defecto: 'DOP'. | Core Bancario | No nulo. Valor por defecto: 'DOP'. |
| EsActivo | BIT | - | Indicador de producto activo. Valor 1 = Activo, 0 = Inactivo. | Core Bancario | No nulo. Valor por defecto: 1. |
| FechaCarga | DATETIME | - | Marca de tiempo de cuando el registro fue insertado por primera vez en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |
| FechaActualizacion | DATETIME | - | Marca de tiempo de la ultima actualizacion del registro en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |

---

## Tabla: DIM_Tiempo

**Descripcion general:** Tabla calendario que contiene todos los dias necesarios para el analisis temporal. Permite agrupar y filtrar transacciones por año, trimestre, mes, semana y dia de la semana. Es una de las dimensiones mas utilizadas en los reportes.

**Volumen estimado:** 365 registros por cada año de datos (ej. 1,095 registros para 3 años).

| Nombre Columna | Tipo Dato | PK/FK | Descripcion de Negocio | Origen | Reglas de Calidad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TiempoKey | INT | PK | Identificador unico generado automaticamente para cada fecha dentro del Data Warehouse. | Generado por el sistema (IDENTITY) | No nulo. Unico. |
| Fecha | DATE | - | Fecha exacta en formato dia/mes/anio. | Generado por el sistema | No nulo. Unico. |
| Anio | INT | - | Anio correspondiente a la fecha (ej. 2025, 2026). | Generado por el sistema | No nulo. |
| Trimestre | INT | - | Trimestre del anio. Valores posibles: 1 (Ene-Mar), 2 (Abr-Jun), 3 (Jul-Sep), 4 (Oct-Dic). | Generado por el sistema | No nulo. |
| Mes | INT | - | Numero del mes. Valores posibles: 1 (Enero) a 12 (Diciembre). | Generado por el sistema | No nulo. |
| MesNombre | VARCHAR(20) | - | Nombre del mes en español (ej. 'Enero', 'Febrero'). | Generado por el sistema | No nulo. |
| Semana | INT | - | Numero de semana dentro del anio (1 a 52). | Generado por el sistema | No nulo. |
| DiaSemana | INT | - | Numero del dia de la semana. Valores posibles: 1 (Domingo) a 7 (Sabado). | Generado por el sistema | No nulo. |
| DiaSemanaNombre | VARCHAR(15) | - | Nombre del dia de la semana en español (ej. 'Lunes', 'Martes'). | Generado por el sistema | No nulo. |
| EsFinDeSemana | BIT | - | Indicador de si la fecha cae en fin de semana. Valor 1 = Sabado o Domingo, 0 = Dia laboral. | Generado por el sistema | No nulo. Valor por defecto: 0. |
| EsDiaFestivo | BIT | - | Indicador de si la fecha es un dia festivo en la Republica Dominicana. (Campo habilitado para futura expansion). | Generado por el sistema | No nulo. Valor por defecto: 0. |

---

## Tabla: DIM_Sucursal

**Descripcion general:** Tabla maestra de sucursales del banco. Contiene informacion geografica de las oficinas fisicas donde los clientes realizan transacciones.

**Volumen estimado:** 50 - 200 registros.

| Nombre Columna | Tipo Dato | PK/FK | Descripcion de Negocio | Origen | Reglas de Calidad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| SucursalKey | INT | PK | Identificador unico generado automaticamente para cada sucursal dentro del Data Warehouse. | Generado por el sistema (IDENTITY) | No nulo. Unico. |
| SucursalID_Source | VARCHAR(20) | - | Identificador original de la sucursal en el sistema origen. | Core Bancario | No nulo. |
| NombreSucursal | VARCHAR(100) | - | Nombre comercial de la sucursal (ej. 'Sucursal Naco', 'Oficina Principal'). | Core Bancario | No nulo. |
| Ciudad | VARCHAR(50) | - | Ciudad donde se encuentra la sucursal. | Core Bancario | Puede ser nulo. |
| Region | VARCHAR(50) | - | Region geografica donde se encuentra la sucursal (ej. 'Distrito Nacional', 'Santiago', 'Este'). | Core Bancario | Puede ser nulo. |
| EsActiva | BIT | - | Indicador de sucursal activa. Valor 1 = Activa, 0 = Inactiva o cerrada. | Core Bancario | No nulo. Valor por defecto: 1. |
| FechaCarga | DATETIME | - | Marca de tiempo de cuando el registro fue insertado por primera vez en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |

---

## Tabla: FACT_Transaccion

**Descripcion general:** Tabla de hechos principal. Contiene todas las transacciones financieras realizadas por los clientes, consolidadas desde el Core Bancario y el Sistema de Tarjetas. Cada registro representa un evento unico (una transaccion) y esta diseñado para ser agregado (sumado, contado) en los reportes de negocio.

**Reglas de negocio aplicables:**
- Cada transacción debe tener al menos una métrica no nula entre `Monto` y `Cantidad`.
- Si el producto asociado pertenece a una categoría que se mide por cantidad (ej. productos de consumo, unidades vendidas), entonces `Monto` puede ser nulo y `Cantidad` debe tener un valor positivo.
- Si el producto se mide por monto monetario (ej. prestamos, depositos), entonces `Cantidad` puede ser nula y `Monto` debe tener un valor positivo.
- Los registros que no cumplan esta regla seran marcados con `FlagCalidad = 0` y se detallara el motivo en `ObservacionCalidad`.

**Volumen estimado:** 100,000 - 1,000,000 de registros por año.

| Nombre Columna | Tipo Dato | PK/FK | Descripcion de Negocio | Origen | Reglas de Calidad |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TransaccionKey | INT | PK | Identificador unico generado automaticamente para cada transaccion dentro del Data Warehouse. No tiene significado en el negocio. | Generado por el sistema (IDENTITY) | No nulo. Unico. |
| ClienteKey | INT | FK | Clave foranea que conecta con DIM_Cliente. Identifica al cliente que realizo la transaccion. | DIM_Cliente | No nulo. |
| ProductoKey | INT | FK | Clave foranea que conecta con DIM_Producto. Identifica el producto asociado a la transaccion. | DIM_Producto | No nulo. |
| TiempoKey | INT | FK | Clave foranea que conecta con DIM_Tiempo. Identifica la fecha en que ocurrio la transaccion. | DIM_Tiempo | No nulo. |
| SucursalKey | INT | FK | Clave foranea que conecta con DIM_Sucursal. Identifica la sucursal donde se realizo la transaccion. Puede ser nulo para transacciones digitales. | DIM_Sucursal | Puede ser nulo si la transaccion fue por canal digital. |
| Monto | DECIMAL(18,2) | - | Monto de la transaccion en la moneda original del sistema fuente (usualmente DOP). Es la metrica principal para los analisis financieros. | Core Bancario o Sistema de Tarjetas | Puede ser nulo si la transaccion se mide por cantidad |
| MontoUSD | DECIMAL(18,2) | - | Monto de la transaccion convertido a dolares americanos para analisis comparativos internacionales. | Generado por el sistema (conversion) | Puede ser nulo si no se aplica conversion. |
| Cantidad | INT | - | Numero de unidades involucradas en la transaccion (aplica para productos que se miden por cantidad, no por monto). | Core Bancario o Sistema de Tarjetas | Puede ser nulo. |
| TransaccionID_Source | VARCHAR(50) | - | Identificador unico de la transaccion en el sistema origen. Permite rastrear el evento hasta su fuente original. | Core Bancario o Sistema de Tarjetas | No nulo. |
| FuenteOrigen | VARCHAR(20) | - | Nombre del sistema del cual proviene el registro. Valores posibles: 'Core' o 'Tarjetas'. | Sistema origen | No nulo. |
| TipoTransaccion | VARCHAR(30) | - | Tipo de operacion realizada. Ejemplos: 'Deposito', 'Retiro', 'Pago', 'Consumo', 'Transferencia'. | Core Bancario o Sistema de Tarjetas | Puede ser nulo. |
| Canal | VARCHAR(30) | - | Canal a traves del cual se realizo la transaccion. Ejemplos: 'Sucursal', 'ATM', 'App Movil', 'Web', 'Punto de Venta'. | Core Bancario o Sistema de Tarjetas | Puede ser nulo. |
| Estatus | VARCHAR(20) | - | Estado final de la transaccion. Valores posibles: 'Completada', 'Rechazada', 'Pendiente'. | Core Bancario o Sistema de Tarjetas | No nulo. Valor por defecto: 'Completada'. |
| FechaCarga | DATETIME | - | Marca de tiempo de cuando el registro fue insertado por primera vez en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |
| FechaActualizacion | DATETIME | - | Marca de tiempo de la ultima actualizacion del registro en el Data Warehouse. | Generado por el sistema (GETDATE) | No nulo. |
| FlagCalidad | BIT | - | Bandera de calidad de los datos. Valor 1 = Datos validos y confiables. Valor 0 = Datos sospechosos o que incumplen reglas de calidad. | Generado por el sistema (validacion) | No nulo. Valor por defecto: 1. |
| ObservacionCalidad | VARCHAR(255) | - | Descripcion detallada del error de calidad si FlagCalidad = 0. Ejemplo: 'Monto negativo detectado', 'Cedula del cliente no coincide con el sistema Core'. | Generado por el sistema (validacion) | Puede ser nulo. |

---

## Glosario de Terminos Clave

| Termino | Definicion |
| :--- | :--- |
| Clave Sustituta (Surrogate Key) | Identificador numerico generado automaticamente por el sistema, sin significado en el mundo real. Se usa para garantizar la unicidad y estabilidad de las claves primarias en el Data Warehouse. |
| Clave de Negocio (Business Key / Golden Key) | Identificador del mundo real que el negocio reconoce (ej. Cedula, Codigo de Producto). Se usa para unificar registros de diferentes fuentes. |
| DWH | Data Warehouse. Almacen centralizado de datos historicos optimizado para consultas analiticas. |
| OLTP | Sistema transaccional. Disenado para operaciones diarias (insertar, actualizar, eliminar). |
| OLAP | Sistema analitico. Disenado para consultas complejas y agregaciones (sumas, promedios, agrupaciones). |
| ETL | Extraccion, Transformacion y Carga. Proceso que mueve datos desde los sistemas origen hasta el Data Warehouse. |
| Metadato | Datos que describen otros datos. Ejemplo: el diccionario de datos es un conjunto de metadatos. |

---

**Historial de Versiones**

| Version | Fecha | Autor | Cambios |
| :--- | :--- | :--- | :--- |
| 1.0 | Agosto 2026 | Alejandro Velazquez | Creacion inicial del documento. |
