USE BankingDWH;
GO

CREATE NONCLUSTERED INDEX IX_UserBranch_UserName_BranchKey
ON Security.UserBranch (UserName, BranchKey);
GO