USE BankingDWH;
GO

-- Create database audit specification if it does not already exist
IF NOT EXISTS (SELECT 1 FROM sys.database_audit_specifications WHERE name = 'BankingDWH_Audit_Spec')
BEGIN
    CREATE DATABASE AUDIT SPECIFICATION BankingDWH_Audit_Spec
    FOR SERVER AUDIT BankingDWH_Audit
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.FACT_Transaction BY PUBLIC),
    ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.DIM_Customer BY PUBLIC);
END
GO

-- Enable the database specification (idempotent)
ALTER DATABASE AUDIT SPECIFICATION BankingDWH_Audit_Spec WITH (STATE = ON);
GO