# Dynamic Data Masking on `DIM_Customer`

## Overview
Dynamic Data Masking (DDM) limits exposure of sensitive personal information in the `DIM_Customer` table. The masking is applied at the presentation layer, meaning the underlying data remains unchanged in storage, but masked values are returned to non-privileged users during query execution.

## Masked Columns
The following personally identifiable information (PII) columns are masked:

| Column   | Mask Function                        | Visible Output Example                           |
|----------|--------------------------------------|--------------------------------------------------|
| `Cedula` | `partial(4, "XXXX-", 0)`             | First 4 digits, then `XXXX-` (e.g., `1234-XXXX-`) |
| `Email`  | `email()`                            | `aXXX@XXXX.com` (first character + `XXX@XXXX.com`) |
| `Phone`  | `partial(0, "XXXX-XXXX-", 4)`        | Last 4 digits only, preceded by `XXXX-XXXX-`     |

## Users with `UNMASK` Permission
The following accounts have the `UNMASK` permission on `DIM_Customer`, allowing them to see the original unmasked values:

- **AuditCompliance** – Required for auditing and compliance reviews.
- **DWHAdmin** – Required for database administration and troubleshooting.
- **ETLService** – Required for ETL operations (deduplication, lookups, and upserts). Masked values would break the pipeline logic, so this exemption is consistent with the Row-Level Security exemption already granted to this account.

All other users, including analysts (e.g., `LauraGomez`, `CarlosMendez`), receive only masked data.

## Expected Behavior
- **Analysts** querying `DIM_Customer` see masked values. A `Cedula` of `1234567890` becomes `1234-XXXX-`, and a phone `+1234567890` becomes `XXXX-XXXX-7890`.
- **Auditors, Admins, and ETL Service** see the original plain text values.

## Testing Instructions
Run the following queries to verify the masking behavior under different user contexts:

```sql
-- Test as a restricted user (e.g., LauraGomez)
EXECUTE AS USER = 'LauraGomez';
SELECT CustomerKey, Cedula, Email, Phone FROM DIM_Customer;
REVERT;

-- Test as a privileged user (e.g., DWHAdmin)
EXECUTE AS USER = 'DWHAdmin';
SELECT CustomerKey, Cedula, Email, Phone FROM DIM_Customer;
REVERT;
```

## Integration with Power BI and RLS

- **Power BI**: Reports querying `DIM_Customer` respect the user's database permissions. If a Power BI user connects with an analyst's credentials, they see masked values.
- **Row-Level Security (RLS)**: DDM operates orthogonally to RLS. RLS restricts which rows a user can access, while DDM restricts the visibility of data within the columns of those rows. Together, they provide layered security.

---

*Part of the Banking Data Warehouse security documentation*