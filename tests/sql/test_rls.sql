-- ============================================================
-- test_rls.sql
-- Validates Row-Level Security (RLS) on FACT_Transaction and DIM_Customer
-- Run this in BankingDWH as a user with sysadmin or db_owner rights.
-- Expected results are hardcoded based on the current data.
-- ============================================================

USE BankingDWH;
GO

SET NOCOUNT ON;

DECLARE @TestName NVARCHAR(100) = 'RLS Validation';
DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- Helper: print test result
CREATE OR ALTER PROCEDURE #TestResult
    @TestName NVARCHAR(100),
    @Expected INT,
    @Actual INT,
    @Description NVARCHAR(200)
AS
BEGIN
    IF @Expected = @Actual
    BEGIN
        PRINT '✅ PASS: ' + @TestName + ' - ' + @Description;
        SET @PassCount = @PassCount + 1;
    END
    ELSE
    BEGIN
        PRINT '❌ FAIL: ' + @TestName + ' - Expected ' + CAST(@Expected AS NVARCHAR(10)) + ', got ' + CAST(@Actual AS NVARCHAR(10)) + ' - ' + @Description;
        SET @FailCount = @FailCount + 1;
    END
END
GO

-- Test 1: LauraGomez transaction count (expected 31)
EXECUTE AS USER = 'LauraGomez';
DECLARE @LauraTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
EXEC #TestResult 'LauraGomez_Transactions', 31, @LauraTrans, 'LauraGomez should see 31 transactions';

-- Test 2: LauraGomez customer count (expected 14)
EXECUTE AS USER = 'LauraGomez';
DECLARE @LauraCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
EXEC #TestResult 'LauraGomez_Customers', 14, @LauraCust, 'LauraGomez should see 14 customers';

-- Test 3: CarlosMendez transaction count (expected 14)
EXECUTE AS USER = 'CarlosMendez';
DECLARE @CarlosTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
EXEC #TestResult 'CarlosMendez_Transactions', 14, @CarlosTrans, 'CarlosMendez should see 14 transactions';

-- Test 4: CarlosMendez customer count (expected 12)
EXECUTE AS USER = 'CarlosMendez';
DECLARE @CarlosCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
EXEC #TestResult 'CarlosMendez_Customers', 12, @CarlosCust, 'CarlosMendez should see 12 customers';

-- Test 5: AuditCompliance transaction count (expected 63 - all data)
EXECUTE AS USER = 'AuditCompliance';
DECLARE @AuditTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
EXEC #TestResult 'AuditCompliance_Transactions', 63, @AuditTrans, 'AuditCompliance should see all 63 transactions';

-- Test 6: AuditCompliance customer count (expected 20 - all customers)
EXECUTE AS USER = 'AuditCompliance';
DECLARE @AuditCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
EXEC #TestResult 'AuditCompliance_Customers', 20, @AuditCust, 'AuditCompliance should see all 20 customers';

-- Test 7: ETLService transaction count (expected 63 - all data, RLS exempt)
EXECUTE AS USER = 'ETLService';
DECLARE @ETLTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
EXEC #TestResult 'ETLService_Transactions', 63, @ETLTrans, 'ETLService should see all 63 transactions (RLS exempt)';

-- Test 8: ETLService customer count (expected 20 - all customers, RLS exempt)
EXECUTE AS USER = 'ETLService';
DECLARE @ETLCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
EXEC #TestResult 'ETLService_Customers', 20, @ETLCust, 'ETLService should see all 20 customers (RLS exempt)';

-- Summary
PRINT '========================================';
PRINT 'RLS Test Results:';
PRINT '  Passed: ' + CAST(@PassCount AS NVARCHAR(10));
PRINT '  Failed: ' + CAST(@FailCount AS NVARCHAR(10));
PRINT '========================================';

DROP PROCEDURE #TestResult;
GO