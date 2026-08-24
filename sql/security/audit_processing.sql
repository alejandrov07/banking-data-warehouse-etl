USE BankingDWH;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'AuditLog' AND schema_id = SCHEMA_ID('Security'))
BEGIN
    CREATE TABLE Security.AuditLog (
        AuditLogID INT IDENTITY(1,1) PRIMARY KEY,
        event_time DATETIME2,
        action_id VARCHAR(20),
        session_id INT,
        server_principal_name NVARCHAR(128),
        database_principal_name NVARCHAR(128),
        object_name NVARCHAR(128),
        statement NVARCHAR(MAX),
        processed_date DATETIME2 DEFAULT GETDATE()
    );
END
GO

-- Stored procedure to load new audit events from files into AuditLog table
CREATE OR ALTER PROCEDURE Security.sp_LoadAuditLog
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Security.AuditLog (
        event_time,
        action_id,
        session_id,
        server_principal_name,
        database_principal_name,
        object_name,
        statement
    )
    SELECT
        event_time,
        action_id,
        session_id,
        server_principal_name,
        database_principal_name,
        object_name,
        statement
    FROM
        sys.fn_get_audit_file('C:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT)
    WHERE
        database_name = 'BankingDWH'
        AND object_name IN ('FACT_Transaction', 'DIM_Customer')
        -- Avoid duplicates by checking if event already exists in AuditLog
        AND NOT EXISTS (
            SELECT 1
            FROM Security.AuditLog AL
            WHERE AL.event_time = event_time
              AND AL.action_id = action_id
              AND AL.session_id = session_id
              AND AL.statement = statement
        )
    ORDER BY event_time;

    RETURN 0;
END;
GO

-- Grant execute permission on the stored procedure and select on the log table
GRANT EXECUTE ON Security.sp_LoadAuditLog TO AuditCompliance;
GRANT EXECUTE ON Security.sp_LoadAuditLog TO DWHAdmin;
GRANT SELECT ON Security.AuditLog TO AuditCompliance;
GRANT SELECT ON Security.AuditLog TO DWHAdmin;
GO