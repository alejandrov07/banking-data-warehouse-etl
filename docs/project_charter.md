# Project Charter - Banking Data Warehouse

## 1. Project Identification

| Field | Value |
| :--- | :--- |
| **Project Name** | Banking Data Warehouse & ETL Pipeline |
| **Project Lead** | Alejandro Velazquez |
| **Start Date** | August 2026 |
| **Estimated Close Date** | September 2026 |

---

## 2. Project Objective

Build a Data Warehouse for the Business area that consolidates information from two source systems (Core Banking and Card System), applying governance standards, data quality controls, and dimensional modeling, in order to support strategic decision-making.

---

## 3. Scope

### In Scope:
- Star Schema dimensional model design.
- Python ETL pipeline to extract, clean, and load data.
- Automated data quality controls (nulls, duplicates, formats).
- Metadata and lineage documentation.
- Executive dashboard in Power BI.

### Out of Scope:
- Production data migration (this is a simulated environment).
- Real-time automation (batch processing only).
- Data Lake or Big Data implementation.

---

## 4. Identified Risks and Mitigation

| Risk | Impact | Mitigation |
| :--- | :--- | :--- |
| **Inconsistent data quality** in source systems | High | Implement validation and rejection rules in the transformation phase. Generate error logs. |
| **Duplicate customers** across systems | High | Define a unique business key (National ID) as the *golden key* for MDM. |
| **Technological obsolescence** of the model | Medium | Design the model with open standards and clear documentation to facilitate future migrations. |
| **Resistance to change** from operational teams | Medium | Involve business areas in defining key dimensions. |

---

## 5. High-Level Timeline (Sprints)

| Sprint | Duration | Deliverable |
| :--- | :--- | :--- |
| **Sprint 1** | 2 Weeks | Requirements definition and Star Schema design. |
| **Sprint 2** | 2 Weeks | ETL pipeline development (Extraction and Cleansing). |
| **Sprint 3** | 2 Weeks | Data Warehouse load and quality validation. |
| **Sprint 4** | 1 Week | Dashboard build-out and final documentation. |

---

## 6. Approvals

| Role | Name | Signature |
| :--- | :--- | :--- |
| **Project Lead** | Alejandro Velazquez | *(In progress)* |
| **Data Architect (Reviewer)** | *(To be defined)* | *(In progress)* |

---

*Document prepared under project governance and management standards.*