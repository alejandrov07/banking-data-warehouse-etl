# Testing Strategy

This document describes the automated testing approach for the BankingDWH project.

## Overview

Tests are written in two forms:
- **SQL scripts** (for quick validation in SSMS).
- **Python scripts** (for CI/CD integration and automated reporting).

## Running SQL Tests

Open SSMS, connect as `DWHAdmin`, and execute:

```sql
:r tests/sql/run_all_tests.sql