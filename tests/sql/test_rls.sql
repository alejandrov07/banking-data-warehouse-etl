-- ============================================================
-- test_rls.sql
-- Validates Row-Level Security (RLS) on FACT_Transaction and DIM_Customer
-- Run this in BankingDWH as a user with sysadmin or db_owner rights.
-- ============================================================

USE BankingDWH;
GO

SET NOCOUNT ON;

DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

-- Test 1: LauraGomez transaction count (expected 31)
EXECUTE AS USER = 'LauraGomez';
DECLARE @LauraTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
IF @LauraTrans = 31
BEGIN
    PRINT '✅ PASS: LauraGomez_Transactions - LauraGomez should see 31 transactions';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: LauraGomez_Transactions - Expected 31, got ' + CAST(@LauraTrans AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 2: LauraGomez customer count (expected 14)
EXECUTE AS USER = 'LauraGomez';
DECLARE @LauraCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
IF @LauraCust = 14
BEGIN
    PRINT '✅ PASS: LauraGomez_Customers - LauraGomez should see 14 customers';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: LauraGomez_Customers - Expected 14, got ' + CAST(@LauraCust AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 3: CarlosMendez transaction count (expected 14)
EXECUTE AS USER = 'CarlosMendez';
DECLARE @CarlosTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
IF @CarlosTrans = 14
BEGIN
    PRINT '✅ PASS: CarlosMendez_Transactions - CarlosMendez should see 14 transactions';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: CarlosMendez_Transactions - Expected 14, got ' + CAST(@CarlosTrans AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 4: CarlosMendez customer count (expected 12)
EXECUTE AS USER = 'CarlosMendez';
DECLARE @CarlosCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
IF @CarlosCust = 12
BEGIN
    PRINT '✅ PASS: CarlosMendez_Customers - CarlosMendez should see 12 customers';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: CarlosMendez_Customers - Expected 12, got ' + CAST(@CarlosCust AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 5: AuditCompliance transaction count (expected 63)
EXECUTE AS USER = 'AuditCompliance';
DECLARE @AuditTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
IF @AuditTrans = 63
BEGIN
    PRINT '✅ PASS: AuditCompliance_Transactions - AuditCompliance should see all 63 transactions';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: AuditCompliance_Transactions - Expected 63, got ' + CAST(@AuditTrans AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 6: AuditCompliance customer count (expected 20)
EXECUTE AS USER = 'AuditCompliance';
DECLARE @AuditCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
IF @AuditCust = 20
BEGIN
    PRINT '✅ PASS: AuditCompliance_Customers - AuditCompliance should see all 20 customers';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: AuditCompliance_Customers - Expected 20, got ' + CAST(@AuditCust AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 7: ETLService transaction count (expected 63)
EXECUTE AS USER = 'ETLService';
DECLARE @ETLTrans INT = (SELECT COUNT(*) FROM dbo.FACT_Transaction);
REVERT;
IF @ETLTrans = 63
BEGIN
    PRINT '✅ PASS: ETLService_Transactions - ETLService should see all 63 transactions (RLS exempt)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: ETLService_Transactions - Expected 63, got ' + CAST(@ETLTrans AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Test 8: ETLService customer count (expected 20)
EXECUTE AS USER = 'ETLService';
DECLARE @ETLCust INT = (SELECT COUNT(*) FROM dbo.DIM_Customer);
REVERT;
IF @ETLCust = 20
BEGIN
    PRINT '✅ PASS: ETLService_Customers - ETLService should see all 20 customers (RLS exempt)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '❌ FAIL: ETLService_Customers - Expected 20, got ' + CAST(@ETLCust AS VARCHAR);
    SET @FailCount = @FailCount + 1;
END

-- Summary
PRINT '========================================';
PRINT 'RLS Test Results:';
PRINT '  Passed: ' + CAST(@PassCount AS VARCHAR);
PRINT '  Failed: ' + CAST(@FailCount AS VARCHAR);
PRINT '========================================';
GO