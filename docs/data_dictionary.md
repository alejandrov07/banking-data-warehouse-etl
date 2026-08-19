# Data Dictionary - Banking Data Warehouse

## Purpose of This Document

This document describes all the tables and columns that make up the Data Warehouse for the simulated banking project. Its goal is to serve as a reference guide for business analysts, developers, and governance teams, so they can understand the meaning of each field and the rules that govern it.

The dictionary is organized by table, following the Star Schema model. Dimension tables (DIM) contain descriptive information and the fact table (FACT) contains numeric metrics.

---

## Naming Conventions

**Prefixes (indicate table type)**

| Prefix | Meaning |
| :--- | :--- |
| DIM_ | Dimension table. Contains descriptive attributes for filtering and grouping. |
| FACT_ | Fact table. Contains numeric metrics and foreign keys connecting to the dimensions. |

**Suffixes (indicate column type)**

| Suffix | Meaning |
| :--- | :--- |
| Key | Indicates the column is a primary key (PK) or foreign key (FK). Example: CustomerKey, ProductKey. |

---

## Table: DIM_Customer

**General description:** Master customer table. Each record represents a unique customer within the Data Warehouse, identified by a surrogate key (CustomerKey).

**Estimated volume:** 20 records in the current synthetic dataset; designed to scale to thousands.

| Column Name | Data Type | PK/FK | Business Description | Quality Rules |
| :--- | :--- | :--- | :--- | :--- |
| CustomerKey | INT (IDENTITY) | PK | Unique identifier automatically generated for each customer within the Data Warehouse. Has no business meaning. | Not null. Unique. |
| CustomerID | NVARCHAR(20) | - | Business-facing customer code (e.g. 'C0001'). | Not null. |
| FullName | NVARCHAR(100) | - | Customer's full name. | Not null. |
| Cedula | NVARCHAR(20) | - | Customer's national ID number. | Not null. |
| Email | NVARCHAR(100) | - | Customer's email address. | Not null. |
| Phone | NVARCHAR(20) | - | Customer's phone number. | Not null. |
| City | NVARCHAR(50) | - | Customer's city of residence. | Not null. |
| RegistrationDate | DATE | - | Date the customer record was created. | Not null. |

---

## Table: DIM_Product

**General description:** Master table of financial products offered by the bank (accounts, cards, loans, investments, insurance).

**Estimated volume:** 10 records in the current synthetic dataset.

| Column Name | Data Type | PK/FK | Business Description | Quality Rules |
| :--- | :--- | :--- | :--- | :--- |
| ProductKey | INT (IDENTITY) | PK | Unique identifier automatically generated for each product within the Data Warehouse. | Not null. Unique. |
| ProductCode | NVARCHAR(20) | - | Internal product code (e.g. 'P001'). | Not null. |
| ProductName | NVARCHAR(100) | - | Commercial product name (e.g. 'Cuenta Corriente', 'Tarjeta Credito Oro'). | Not null. |
| Category | NVARCHAR(50) | - | Product category. Values in the current dataset: 'Cuentas', 'Tarjetas', 'Prestamos', 'Inversiones', 'Seguros'. | Not null. |
| UnitPrice | DECIMAL(10,2) | - | Flat fee or unit price associated with the product, where applicable (0 for accounts and loans). | Not null. |

---

## Table: DIM_Date

**General description:** Calendar table containing every day in the covered range. Allows transactions to be grouped and filtered by year, quarter, month, and day of week.

**Estimated volume:** 366 records, covering 2024-01-01 through 2024-12-31 in the current dataset.

| Column Name | Data Type | PK/FK | Business Description | Quality Rules |
| :--- | :--- | :--- | :--- | :--- |
| DateKey | INT | PK | Date represented as an integer in YYYYMMDD format (e.g. 20240424). Not an IDENTITY column — computed directly from the date. | Not null. Unique. |
| FullDate | DATE | - | The actual calendar date. | Not null. |
| Year | INT | - | Calendar year (e.g. 2024). | Not null. |
| Quarter | INT | - | Quarter of the year (1-4). | Not null. |
| Month | INT | - | Month number (1-12). | Not null. |
| MonthName | NVARCHAR(20) | - | Month name in English (e.g. 'January'). | Not null. |
| DayOfWeek | INT | - | Day-of-week number (1 = Monday through 7 = Sunday, per pandas `dayofweek + 1`). | Not null. |
| DayName | NVARCHAR(20) | - | Day-of-week name in English (e.g. 'Monday'). | Not null. |
| IsWeekend | BIT | - | Indicator of whether the date falls on Saturday or Sunday. Value 1 = Weekend, 0 = Weekday. | Not null. |

---

## Table: DIM_Branch

**General description:** Master table of bank branches — the physical offices where transactions are attributed.

**Estimated volume:** 5 records in the current synthetic dataset.

| Column Name | Data Type | PK/FK | Business Description | Quality Rules |
| :--- | :--- | :--- | :--- | :--- |
| BranchKey | INT (IDENTITY) | PK | Unique identifier automatically generated for each branch within the Data Warehouse. | Not null. Unique. |
| BranchCode | NVARCHAR(10) | - | Internal branch code (e.g. 'BR01'). | Not null. |
| BranchName | NVARCHAR(100) | - | Commercial branch name (e.g. 'Santo Domingo Central'). | Not null. |
| City | NVARCHAR(50) | - | City where the branch is located. | Not null. |
| Region | NVARCHAR(50) | - | Geographic region where the branch is located (e.g. 'Distrito Nacional'). | Not null. |

---

## Table: FACT_Transaction

**General description:** Fact table containing all financial transactions. Each record represents a unique transaction event and is designed to be aggregated (summed, counted) in business reports. This table is subject to Row-Level Security, restricting which branches a given analyst can see (see `sql/security/`).

**Estimated volume:** 63 records in the current synthetic dataset; designed to scale to hundreds of thousands.

| Column Name | Data Type | PK/FK | Business Description | Quality Rules |
| :--- | :--- | :--- | :--- | :--- |
| TransactionKey | INT (IDENTITY) | PK | Unique identifier automatically generated for each transaction within the Data Warehouse. | Not null. Unique. |
| CustomerKey | INT | FK | Foreign key to DIM_Customer. Identifies the customer who made the transaction. | Not null. |
| ProductKey | INT | FK | Foreign key to DIM_Product. Identifies the product involved in the transaction. | Not null. |
| DateKey | INT | FK | Foreign key to DIM_Date. Identifies the date the transaction occurred. | Not null. |
| BranchKey | INT | FK | Foreign key to DIM_Branch. Identifies the branch the transaction is attributed to. | Not null. |
| Amount | DECIMAL(15,2) | - | Transaction amount. Primary metric for financial analysis. | Not null. |
| Quantity | INT | - | Number of units involved in the transaction. | Not null. |
| TransactionType | NVARCHAR(20) | - | Type of operation. Values in the current dataset: 'Purchase', 'Withdrawal', 'Deposit', 'Transfer'. | Not null. |
| FlagQuality | BIT | - | Data quality flag. Value 1 = clean record, 0 = flagged record. In the current synthetic dataset this is generated randomly (~10% flagged) rather than derived from a business validation rule. | Not null. Default value: 1. |

---

## Key Terms Glossary

| Term | Definition |
| :--- | :--- |
| Surrogate Key | System-generated numeric identifier with no real-world meaning. Used to guarantee the uniqueness and stability of primary keys in the Data Warehouse. |
| DWH | Data Warehouse. Centralized store of historical data optimized for analytical queries. |
| OLTP | Transactional system. Designed for day-to-day operations (insert, update, delete). |
| OLAP | Analytical system. Designed for complex queries and aggregations (sums, averages, groupings). |
| ETL | Extract, Transform, and Load. Process that moves data from source files into the Data Warehouse. |
| RLS | Row-Level Security. SQL Server feature used in this project to restrict which rows of FACT_Transaction each user can see, based on branch assignment. |

---

**Version History**

| Version | Date | Author | Changes |
| :--- | :--- | :--- | :--- |
| 1.0 | August 2026 | Alejandro Velazquez | Initial document creation (Spanish). |
| 2.0 | August 2026 | Alejandro Velazquez | Translated to English and rewritten to match the actual implemented schema (`sql/create_tables.sql`). |