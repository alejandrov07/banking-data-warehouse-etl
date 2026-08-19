USE BankingDWH;
GO

CREATE TABLE dbo.DIM_Customer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID NVARCHAR(20) NOT NULL,
    FullName NVARCHAR(100) NOT NULL,
    Cedula NVARCHAR(20) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    Phone NVARCHAR(20) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    RegistrationDate DATE NOT NULL
);
GO

CREATE TABLE dbo.DIM_Product (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductCode NVARCHAR(20) NOT NULL,
    ProductName NVARCHAR(100) NOT NULL,
    Category NVARCHAR(50) NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL
);
GO

CREATE TABLE dbo.DIM_Date (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName NVARCHAR(20) NOT NULL,
    IsWeekend BIT NOT NULL
);
GO

CREATE TABLE dbo.DIM_Branch (
    BranchKey INT IDENTITY(1,1) PRIMARY KEY,
    BranchCode NVARCHAR(10) NOT NULL,
    BranchName NVARCHAR(100) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    Region NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.FACT_Transaction (
    TransactionKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    DateKey INT NOT NULL,
    BranchKey INT NOT NULL,
    Amount DECIMAL(15,2) NOT NULL,
    Quantity INT NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    FlagQuality BIT NOT NULL DEFAULT 1
);
GO

ALTER TABLE dbo.FACT_Transaction ADD CONSTRAINT FK_FACT_Customer
    FOREIGN KEY (CustomerKey) REFERENCES dbo.DIM_Customer(CustomerKey);
ALTER TABLE dbo.FACT_Transaction ADD CONSTRAINT FK_FACT_Product
    FOREIGN KEY (ProductKey) REFERENCES dbo.DIM_Product(ProductKey);
ALTER TABLE dbo.FACT_Transaction ADD CONSTRAINT FK_FACT_Date
    FOREIGN KEY (DateKey) REFERENCES dbo.DIM_Date(DateKey);
ALTER TABLE dbo.FACT_Transaction ADD CONSTRAINT FK_FACT_Branch
    FOREIGN KEY (BranchKey) REFERENCES dbo.DIM_Branch(BranchKey);
GO