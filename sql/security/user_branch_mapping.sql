-- USER-BRANCH MAPPING TABLE

USE BankingDWH;
GO

CREATE TABLE Security.UserBranch (
    UserName NVARCHAR(128) NOT NULL,
    BranchKey INT NOT NULL,
    CONSTRAINT PK_UserBranch PRIMARY KEY (UserName, BranchKey)
);
GO

INSERT INTO Security.UserBranch (UserName, BranchKey) VALUES
    ('LauraGomez', 1),
    ('LauraGomez', 2),
    ('CarlosMendez', 3);
GO