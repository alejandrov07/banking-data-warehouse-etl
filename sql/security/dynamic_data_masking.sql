USE BankingDWH;
GO

-- DYNAMIC DATA MASKING (DDM) ON DIM_Customer
-- Purpose: Protect sensitive personally identifiable information (PII) in the customer dimension by masking the Cedula, Email, and Phone columns. Only designated users (AuditCompliance, DWHAdmin, and ETLService) can see the original values via the UNMASK permission.

-- Apply masking to Cedula: show first 4 digits, mask the middle, display no suffix.
ALTER TABLE DIM_Customer
ALTER COLUMN Cedula ADD MASKED WITH (FUNCTION = 'partial(4, "XXXX-", 0)');
GO

-- Apply masking to Email: use the built-in email mask.
ALTER TABLE DIM_Customer
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
GO

-- Apply masking to Phone: show the last 4 digits, mask the rest.
ALTER TABLE DIM_Customer
ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0, "XXXX-XXXX-", 4)');
GO

-- GRANT UNMASK PERMISSIONS
-- AuditCompliance and DWHAdmin need full visibility for auditing and administration. ETLService must read original data during ETL operations (e.g., deduplication, upserts). This aligns with its RLS exemption.
GRANT UNMASK ON DIM_Customer TO AuditCompliance;
GRANT UNMASK ON DIM_Customer TO DWHAdmin;
GRANT UNMASK ON DIM_Customer TO ETLService;
GO