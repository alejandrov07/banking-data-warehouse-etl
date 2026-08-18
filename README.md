# Banking Data Warehouse & Security Layer

> **Status: Core DWH Complete | Security Layer Implemented (RLS, DDM, Audit)**  
> *A fully functional Data Warehouse for a simulated banking environment, extended with enterprise-grade security controls.*

---

## Project Overview

This project simulates the integration of two hypothetical banking systems (Core Banking and Card System) to build a unified view of transactions and customers. It solves real-world data quality issues like duplicates, missing standards, and inconsistent formats.

**What makes this project unique:**  
Beyond the standard ETL pipeline and Star Schema modeling, I implemented a **production-ready security layer** using SQL Server native features:

- **Row-Level Security (RLS):** Restricts analysts to only view transactions from their assigned branches.
- **Dynamic Data Masking (DDM):** Automatically obfuscates PII (Cedula, Email, Phone) for non-privileged users.
- **Native Server Auditing:** Tracks every `SELECT`, `INSERT`, `UPDATE`, and `DELETE` on sensitive tables, providing a forensic audit trail.

---

## Professional Objective

This repository is part of my technical portfolio, demonstrating my competencies for **Data Engineering**, **Analytics Engineering**, and **Database Administration** roles:

- Dimensional modeling (Star Schema) for Data Warehousing.
- ETL/ELT pipeline development with Python (Pandas) and SQL Server.
- Implementation of database security controls (RLS, DDM, Auditing).
- Metadata management and data lineage documentation.
- Strategic data visualization with Power BI.

---

## Tech Stack

| Component               | Technology                                          |
| :---------------------- | :-------------------------------------------------- |
| **Extraction & Load**   | Python (Pandas, SQLAlchemy)                         |
| **Database**            | SQL Server (Developer Edition)                      |
| **Modeling**            | Star Schema (Dimensions & Fact)                     |
| **Security Layer**      | Row-Level Security, Dynamic Data Masking, Auditing  |
| **BI / Dashboards**     | Power BI Desktop                                    |
| **Version Control**     | Git / GitHub                                        |

---

## Key Features

### 1. Dimensional Modeling (Star Schema)
Designed a classic Star Schema with 4 dimensions (`DIM_Cliente`, `DIM_Producto`, `DIM_Tiempo`, `DIM_Sucursal`) and 1 fact table (`FACT_Transaccion`) to enable fast analytical queries.

### 2. Automated ETL Pipeline
Built a Python ETL pipeline using Pandas that:
- Generates synthetic banking data.
- Cleans and standardizes formats.
- Deduplicates client records.
- Loads transformed data into SQL Server.

### 3. Enterprise Security Layer (NEW)
- **Row-Level Security (RLS):** A dynamic filtering policy ensures analysts see *only* their branch data. Admins and auditors are exempt.
- **Dynamic Data Masking (DDM):** Sensitive columns (`Cedula`, `Email`, `Phone`) are partially masked for analysts, while auditors and admins see full data.
- **Audit Trail:** SQL Server's native auditing captures all access to `FACT_Transaccion` and `DIM_Cliente`, with a stored procedure to consolidate logs into a queryable table.

### 4. Power BI Dashboards
Interactive dashboards connected to the DWH, displaying:
- Monthly sales trends.
- Top clients by transaction volume.
- Data quality metrics (clean vs. flagged transactions).

![Dashboard Preview](docs/assets/dashboard_tendencia.png)

---

## How to Run This Project

1. **Clone the repository**  
   ```bash
   git clone https://github.com/alejandrov07/banking-data-warehouse-etl.git