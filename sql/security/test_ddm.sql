USE BankingDWH;
GO

-- DDM VERIFICATION SCRIPT
-- Purpose: Validate that masking applies correctly to analysts and shows clear text for privileged users.

-- Test 1: Analyst sees masked data (LauraGomez)
EXECUTE AS USER = 'LauraGomez';
SELECT 'LauraGomez (Masked)' AS TestUser, CustomerKey, Cedula, Email, Phone FROM DIM_Customer WHERE CustomerKey = 1;
REVERT;
GO

-- Test 2: Administrator sees unmasked data (DWHAdmin)
EXECUTE AS USER = 'DWHAdmin';
SELECT 'DWHAdmin (Unmasked)' AS TestUser, CustomerKey, Cedula, Email, Phone FROM DIM_Customer WHERE CustomerKey = 1;
REVERT;
GO

-- Test 3: ETLService sees unmasked data (ETLService)
EXECUTE AS USER = 'ETLService';
SELECT 'ETLService (Unmasked)' AS TestUser, CustomerKey, Cedula, Email, Phone FROM DIM_Customer WHERE CustomerKey = 1;
REVERT;
GO

-- Expected results:
-- LauraGomez should see: Cedula with 'XXXX-', Email with 'XXX@', Phone with 'XXXX-XXXX-'
-- DWHAdmin and ETLService should see the full original values.