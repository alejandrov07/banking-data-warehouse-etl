USE BankingDWH;
GO

CREATE FUNCTION Security.fn_predicate_customer(
    @userName sysname,
    @customerKey INT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS can_see
    WHERE 
        -- Admins and auditors see everything
        @userName IN ('AuditCompliance', 'DWHAdmin')
        OR
        -- Analysts only see customers who have transactions in their assigned branches
        EXISTS (
            SELECT 1
            FROM dbo.FACT_Transaction t
            WHERE t.CustomerKey = @customerKey
              AND EXISTS (
                  SELECT 1
                  FROM Security.UserBranch ub
                  WHERE ub.UserName = @userName
                    AND ub.BranchKey = t.BranchKey
              )
        )
);
GO
