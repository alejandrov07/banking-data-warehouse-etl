-- RLS PREDICATE FUNCTION
-- Purpose:
-- This inline table-valued function determines which rows a user can see in FACT_Transaccion. It is the "brain" of Row-Level Security.

-- Logic:
-- If the current user is 'AuditCompliance', 'DWHAdmin', or 'ETLService', return 1 (no filter) so they see everything.
-- ETLService is exempt because the ETL pipeline loads and deletes rows across all branches; without this
-- exemption, RLS silently hides rows from the service account during load/cleanup, breaking the ETL.
-- Otherwise, join to Security.UserBranch to get the BranchKeys assigned to that user, and return only those keys.

-- Performance:
-- Inline functions are folded into the query plan, so they perform much better than scalar functions.
-- We will create an index on Security.UserBranch tomorrow to speed up the lookup.


USE BankingDWH;
GO

-- Drop the old function (it has the wrong signature)
DROP FUNCTION IF EXISTS Security.fn_predicate_transacciones;
GO

CREATE FUNCTION Security.fn_predicate_transacciones(
    @usuario sysname,
    @sucursalKey INT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS can_see
    WHERE 
        -- Exceptions: Auditor and Admin see everything
        @usuario IN ('AuditCompliance', 'DWHAdmin', 'ETLService')
        OR
        -- For analysts: check the mapping table
        EXISTS (
            SELECT 1
            FROM Security.UserBranch ub
            WHERE ub.UserName = @usuario
              AND ub.BranchKey = @sucursalKey
        )
);
GO