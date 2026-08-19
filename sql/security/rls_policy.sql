USE BankingDWH;
GO

CREATE SECURITY POLICY Security.pol_transacciones
ADD FILTER PREDICATE Security.fn_predicate_transacciones(USER_NAME(), [BranchKey])
ON dbo.FACT_Transaction
WITH (STATE = OFF);
GO