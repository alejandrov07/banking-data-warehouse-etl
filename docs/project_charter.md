# Project Charter - Banking Data Warehouse

## 1. Identificación del Proyecto

| Campo | Valor |
| :--- | :--- |
| **Nombre del Proyecto** | Banking Data Warehouse & ETL Pipeline |
| **Líder de Proyecto** | Alejandro Velázquez |
| **Fecha de Inicio** | Agosto 2026 |
| **Fecha Estimada de Cierre** | Septiembre 2026 |

---

## 2. Objetivo del Proyecto

Construir un Data Warehouse para el área de Negocios que consolide información de dos sistemas fuente (Core Bancario y Tarjetas), aplicando estándares de gobernabilidad, calidad de datos y modelado dimensional, con el fin de facilitar la toma de decisiones estratégicas.

---

## 3. Alcance

### Dentro del Alcance:
- Diseño de modelo dimensional en estrella (Star Schema).
- Pipeline ETL en Python para extraer, limpiar y cargar datos.
- Controles automatizados de calidad de datos (nulos, duplicados, formatos).
- Documentación de metadatos y linaje.
- Tablero ejecutivo en Power BI.

### Fuera del Alcance:
- Migración de datos en producción (es un entorno simulado).
- Automatización en tiempo real (procesamiento batch).
- Implementación de Data Lake o Big Data.

---

## 4. Riesgos Identificados y Mitigación

| Riesgo | Impacto | Mitigación |
| :--- | :--- | :--- |
| **Calidad de datos inconsistentes** en fuentes origen | Alto | Implementar reglas de validación y rechazo en la fase de transformación. Generar logs de errores. |
| **Duplicidad de clientes** entre sistemas | Alto | Definir una clave de negocio única (Cédula/RNC) como *golden key* para el MDM. |
| **Obsolescencia tecnológica** del modelo | Medio | Diseñar el modelo con estándares abiertos y documentación clara para facilitar futuras migraciones. |
| **Resistencia al cambio** de equipos operativos | Medio | Involucrar a las áreas de negocio en la definición de las dimensiones clave. |

---

## 5. Cronograma de Alto Nivel (Sprints)

| Sprint | Duración | Entregable |
| :--- | :--- | :--- |
| **Sprint 1** | 2 Semanas | Definición de requerimientos y diseño del Star Schema. |
| **Sprint 2** | 2 Semanas | Desarrollo del pipeline ETL (Extracción y Limpieza). |
| **Sprint 3** | 2 Semanas | Carga al Data Warehouse y validación de calidad. |
| **Sprint 4** | 1 Semana | Construcción de Dashboards y documentación final. |

---

## 6. Aprobaciones

| Rol | Nombre | Firma |
| :--- | :--- | :--- |
| **Líder de Proyecto** | Alejandro Velázquez | *(En curso)* |
| **Arquitecto de Datos (Revisor)** | *(Por definir)* | *(En curso)* |

---

*Documento elaborado bajo los estándares de gobernabilidad y gestión de proyectos.*
