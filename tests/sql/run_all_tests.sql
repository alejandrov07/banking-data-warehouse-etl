-- ============================================================
-- run_all_tests.sql
-- Executes all test scripts in order and prints a summary.
-- Run this in BankingDWH as sysadmin or db_owner.
-- ============================================================

USE BankingDWH;
GO

PRINT '========================================';
PRINT 'Starting automated test suite...';
PRINT '========================================';
PRINT '';

:r test_rls.sql
PRINT '';
:r test_ddm.sql
PRINT '';
:r test_audit.sql
PRINT '';

PRINT '========================================';
PRINT 'All tests completed.';
PRINT '========================================';
GO