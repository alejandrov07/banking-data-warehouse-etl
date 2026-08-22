USE BankingDWH;
GO

CREATE SECURITY POLICY Security.pol_transaction
ADD FILTER PREDICATE Security.fn_predicate_transaction(USER_NAME(), [BranchKey])
ON dbo.FACT_Transaction
WITH (STATE = OFF);
GO
