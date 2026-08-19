USE BankingDWH;
GO

CREATE NONCLUSTERED INDEX IX_FACT_Transaction_CustomerKey_BranchKey
ON dbo.FACT_Transaction (CustomerKey, BranchKey);
GO