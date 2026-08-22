# Row-Level Security (RLS) Implementation

## Overview

This document describes the Row-Level Security implementation on the Banking Data Warehouse. RLS restricts data access based on the user's assigned branches, ensuring analysts only see relevant data while auditors and administrators have full visibility.

---

## RLS Policies Implemented

### 1. `Security.pol_transaction` (on `FACT_Transaction`)

- **Purpose:** Restricts analysts to only view transactions from their assigned branches.
- **Predicate Function:** `Security.fn_predicate_transaction(@userName, @branchKey)`
- **Logic:**
  - If user is `AuditCompliance`, `DWHAdmin`, or `ETLService` → return `1` (all rows).
  - Else, check if `@branchKey` exists in `Security.UserBranch` for `@userName`.
- **Status:** Active and tested.

### 2. `Security.pol_customer` (on `DIM_Customer`)

- **Purpose:** Restricts analysts to only see customers who have made transactions in their assigned branches.
- **Predicate Function:** `Security.fn_predicate_customer(@userName, @customerKey)`
- **Logic:**
  - If user is `AuditCompliance` or `DWHAdmin` → return `1` (all rows).
  - Else, check if there exists a transaction in `FACT_Transaction` where `CustomerKey = @customerKey` and `BranchKey` is in the user's assigned branches.
- **Status:** Active and tested.

---

## Test Results

| User | `FACT_Transaction` Count | `DIM_Customer` Count |
| :--- | :--- | :--- |
| `LauraGomez` (Branches 1,2) | 31 | 14 |
| `CarlosMendez` (Branch 3) | 14 | 12 |
| `AuditCompliance` | 63 | 20 |
| `DWHAdmin` | 63 | 20 |

**Observation:** The sum of LauraGomez and CarlosMendez customers (14 + 12 = 26) is greater than 20, indicating that some customers have transactions in both branch groups, which is expected and correct.

---

## Performance Optimization

To ensure RLS predicates execute efficiently, the following indexes were created:

- `IX_UserBranch_UserName_BranchKey` on `Security.UserBranch`
- `IX_FACT_Transaction_CustomerKey_BranchKey` on `FACT_Transaction`

**Performance Metrics (STATISTICS IO):**  
Executing `SELECT * FROM DIM_Customer` as `LauraGomez` resulted in:

| Table | Scan Count | Logical Reads |
| :--- | :--- | :--- |
| `FACT_Transaction` | 30 | 60 |
| `UserBranch` | 20 | 40 |
| `DIM_Customer` | 1 | 2 |

**Total Logical Reads:** 102

**Conclusion:** With proper indexing, RLS adds minimal overhead and scales well with data growth.

---

## Reflection

### 1. Flow of Logic

> **Answer:** [The concept was intuitive (mapping table), but the SCHEMABINDING syntax was a hurdle. Once solved, extending logic to other tables felt natural]

### 2. Handling Exceptions

> **Answer:** [Quite energizing, hardcoding exceptions via IN was elegant, it also proved that the mapping table makes the system dynamic without code changes]

### 3. Scalability

> **Answer:** [Intriguing but not intimidating. Proven by performance metrics (102 logical reads). But would require architectural changes (role-based permissions) which id love to explore]

---

*Documentation completed on Day 5 of the Security Sprint.*