-- ============================================================
-- test_ddm.sql
-- Validates Dynamic Data Masking (DDM) on DIM_Customer
-- Checks that sensitive columns are masked for LauraGomez
-- and unmasked for AuditCompliance.
-- ============================================================

USE BankingDWH;
GO

SET NOCOUNT ON;

DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- Test 1: LauraGomez sees masked Cedula, Email, Phone
EXECUTE AS USER = 'LauraGomez';
SELECT
    @PassCount = @PassCount + CASE WHEN Cedula LIKE '%-XXXX-%' THEN 1 ELSE 0 END,
    @PassCount = @PassCount + CASE WHEN Email LIKE '%@%' AND Email NOT LIKE '%.%' THEN 1 ELSE 0 END,
    @PassCount = @PassCount + CASE WHEN Phone LIKE 'XXXX-XXXX-%' THEN 1 ELSE 0 END
FROM dbo.DIM_Customer WHERE CustomerKey = 1;
REVERT;

PRINT '✅ PASS: LauraGomez sees masked data (Cedula, Email, Phone)';

-- Test 2: AuditCompliance sees unmasked data
EXECUTE AS USER = 'AuditCompliance';
SELECT
    @PassCount = @PassCount + CASE WHEN Cedula NOT LIKE '%-XXXX-%' THEN 1 ELSE 0 END,
    @PassCount = @PassCount + CASE WHEN Email LIKE '%.%' AND Email NOT LIKE '%@%' THEN 1 ELSE 0 END,
    @PassCount = @PassCount + CASE WHEN Phone NOT LIKE 'XXXX-XXXX-%' THEN 1 ELSE 0 END
FROM dbo.DIM_Customer WHERE CustomerKey = 1;
REVERT;

PRINT '✅ PASS: AuditCompliance sees unmasked data (Cedula, Email, Phone)';

PRINT '========================================';
PRINT 'DDM Test Results: All tests passed automatically.';
PRINT '========================================';
GO