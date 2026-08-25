-- ============================================================
-- Deployment script for BankingDWH
-- Drops and recreates the entire database + security layer from scratch.
-- Run this in SQL Server Management Studio as sysadmin.
--
-- This version is aligned with the actual project scripts under
-- /sql and /sql/security, and with the current data in /data/raw.
-- ============================================================

USE master;
GO

-- ============================================================
-- 0. Drop & recreate database
-- ============================================================
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BankingDWH')
BEGIN
    ALTER DATABASE BankingDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankingDWH;
END
GO

CREATE DATABASE BankingDWH;
GO

-- ============================================================
-- 0.1 Logins (server level) — must exist before we can CREATE USER ... FOR LOGIN
-- CHANGE THESE PASSWORDS before running in anything but a local/dev environment.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'LauraGomez')
    CREATE LOGIN LauraGomez WITH PASSWORD = '<P@ssword1>', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'CarlosMendez')
    CREATE LOGIN CarlosMendez WITH PASSWORD = '<P@ssword2>', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'AuditCompliance')
    CREATE LOGIN AuditCompliance WITH PASSWORD = '<P@ssword3>', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'DWHAdmin')
    CREATE LOGIN DWHAdmin WITH PASSWORD = '<P@ssword4>', CHECK_POLICY = OFF;
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'ETLService')
    CREATE LOGIN ETLService WITH PASSWORD = '<P@ssword5>', CHECK_POLICY = OFF;
GO

-- ============================================================
-- 0.2 Server Audit (server level) — must exist before we can create the
-- Database Audit Specification later in this script.
-- ============================================================
IF EXISTS (SELECT name FROM sys.server_audits WHERE name = 'BankingDWH_Audit')
BEGIN
    ALTER SERVER AUDIT BankingDWH_Audit WITH (STATE = OFF);
    DROP SERVER AUDIT BankingDWH_Audit;
END
GO

CREATE SERVER AUDIT BankingDWH_Audit
TO FILE (
    FILEPATH = 'C:\SQLAudit\',
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = 10,
    RESERVE_DISK_SPACE = OFF
)
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);
GO

ALTER SERVER AUDIT BankingDWH_Audit WITH (STATE = ON);
GO

GRANT VIEW SERVER STATE TO [AuditCompliance];
GRANT VIEW SERVER STATE TO [DWHAdmin];
GO

USE BankingDWH;
GO

-- ============================================================
-- 1. Schema
-- ============================================================
CREATE SCHEMA Security;
GO

-- ============================================================
-- 2. Users mapped to the logins above
-- ============================================================
CREATE USER LauraGomez FOR LOGIN LauraGomez;
CREATE USER CarlosMendez FOR LOGIN CarlosMendez;
CREATE USER AuditCompliance FOR LOGIN AuditCompliance;
CREATE USER DWHAdmin FOR LOGIN DWHAdmin;
CREATE USER ETLService FOR LOGIN ETLService;
GO

GRANT VIEW DEFINITION TO [AuditCompliance];
GRANT VIEW DEFINITION TO [DWHAdmin];
GO

-- ============================================================
-- 3. Dimension & Fact tables
-- ============================================================

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

-- ============================================================
-- 4. Load data (this is the current data found in /data/raw of your project)
-- ============================================================

-- 4.1 DIM_Branch
SET IDENTITY_INSERT dbo.DIM_Branch ON;
GO
INSERT INTO dbo.DIM_Branch (BranchKey, BranchCode, BranchName, City, Region) VALUES
(1, 'BR01', 'Santo Domingo Central', 'Santo Domingo', 'Distrito Nacional'),
(2, 'BR02', 'Santiago Centro', 'Santiago', 'Santiago'),
(3, 'BR03', 'La Vega Principal', 'La Vega', 'La Vega'),
(4, 'BR04', 'Puerto Plata Malecon', 'Puerto Plata', 'Puerto Plata'),
(5, 'BR05', 'San Francisco Plaza', 'San Francisco', 'Duarte');
SET IDENTITY_INSERT dbo.DIM_Branch OFF;
GO
-- 4.2 DIM_Product
SET IDENTITY_INSERT dbo.DIM_Product ON;
GO
INSERT INTO dbo.DIM_Product (ProductKey, ProductCode, ProductName, Category, UnitPrice) VALUES
(1, 'P001', 'Cuenta Corriente', 'Cuentas', 0.00),
(2, 'P002', 'Cuenta Ahorro', 'Cuentas', 0.00),
(3, 'P003', 'Tarjeta Credito Oro', 'Tarjetas', 120.00),
(4, 'P004', 'Tarjeta Credito Platinum', 'Tarjetas', 250.00),
(5, 'P005', 'Prestamo Personal', 'Prestamos', 0.00),
(6, 'P006', 'Prestamo Hipotecario', 'Prestamos', 0.00),
(7, 'P007', 'Certificado Deposito', 'Inversiones', 0.00),
(8, 'P008', 'Fondo Inversion', 'Inversiones', 0.00),
(9, 'P009', 'Seguro Vida', 'Seguros', 45.00),
(10, 'P010', 'Seguro Vehicular', 'Seguros', 75.00);
SET IDENTITY_INSERT dbo.DIM_Product OFF;
GO
-- 4.3 DIM_Customer
SET IDENTITY_INSERT dbo.DIM_Customer ON;
GO
INSERT INTO dbo.DIM_Customer (CustomerKey, CustomerID, FullName, Cedula, Email, Phone, City, RegistrationDate) VALUES
(1, 'C0001', 'Ana Garcia', '024-388389-4', 'ana.garcia@email.com', '809-328-3286', 'Santo Domingo', '2026-02-24'),
(2, 'C0002', 'Antonio Cruz', '002-131244-2', 'antonio.cruz@email.com', '809-323-4811', 'Puerto Plata', '2026-06-28'),
(3, 'C0003', 'Patricia Sanchez', '023-781453-9', 'patricia.sanchez@email.com', '809-529-4611', 'San Francisco', '2025-01-29'),
(4, 'C0004', 'Juan Perez', '023-543143-6', 'juan.perez@email.com', '809-384-3547', 'Santiago', '2024-10-01'),
(5, 'C0005', 'Ana Lopez', '013-201414-6', 'ana.lopez@email.com', '809-967-6635', 'Puerto Plata', '2025-02-26'),
(6, 'C0006', 'Maria Reyes', '018-230889-7', 'maria.reyes@email.com', '809-180-5803', 'Puerto Plata', '2024-08-11'),
(7, 'C0007', 'Antonio Sanchez', '023-172933-1', 'antonio.sanchez@email.com', '809-777-4733', 'La Vega', '2026-03-11'),
(8, 'C0008', 'Sofia Martinez', '013-391476-8', 'sofia.martinez@email.com', '809-750-6977', 'Santiago', '2024-07-24'),
(9, 'C0009', 'Carmen Sanchez', '022-379946-2', 'carmen.sanchez@email.com', '809-723-3803', 'Puerto Plata', '2025-04-07'),
(10, 'C0010', 'Laura Reyes', '013-383060-9', 'laura.reyes@email.com', '809-324-6313', 'Santo Domingo', '2025-05-09'),
(11, 'C0011', 'Maria Rivera', '013-380746-2', 'maria.rivera@email.com', '809-316-6155', 'Santiago', '2023-11-03'),
(12, 'C0012', 'David Reyes', '005-377746-3', 'david.reyes@email.com', '809-352-9830', 'La Vega', '2024-03-27'),
(13, 'C0013', 'Antonio Ortiz', '012-329974-3', 'antonio.ortiz@email.com', '809-621-9085', 'Santo Domingo', '2026-05-17'),
(14, 'C0014', 'Ana Gonzalez', '021-267753-7', 'ana.gonzalez@email.com', '809-710-2040', 'San Francisco', '2024-07-01'),
(15, 'C0015', 'Marta Reyes', '017-363626-9', 'marta.reyes@email.com', '809-981-1188', 'Santo Domingo', '2025-02-21'),
(16, 'C0016', 'Jose Martinez', '010-555884-3', 'jose.martinez@email.com', '809-564-1053', 'La Vega', '2023-10-31'),
(17, 'C0017', 'Laura Mendoza', '030-211579-5', 'laura.mendoza@email.com', '809-961-9317', 'Puerto Plata', '2025-07-10'),
(18, 'C0018', 'Luis Morales', '025-269396-9', 'luis.morales@email.com', '809-897-9689', 'Santo Domingo', '2024-10-27'),
(19, 'C0019', 'Teresa Garcia', '004-480612-5', 'teresa.garcia@email.com', '809-345-1949', 'Santiago', '2026-03-13'),
(20, 'C0020', 'Carlos Gutierrez', '027-172574-9', 'carlos.gutierrez@email.com', '809-884-3060', 'Santiago', '2023-12-22');
SET IDENTITY_INSERT dbo.DIM_Customer OFF;
GO
-- 4.4 DIM_Date (366 days, 2024)
INSERT INTO dbo.DIM_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfWeek, DayName, IsWeekend) VALUES
(20240101, '2024-01-01', 2024, 1, 1, 'January', 1, 'Monday', 0),
(20240102, '2024-01-02', 2024, 1, 1, 'January', 2, 'Tuesday', 0),
(20240103, '2024-01-03', 2024, 1, 1, 'January', 3, 'Wednesday', 0),
(20240104, '2024-01-04', 2024, 1, 1, 'January', 4, 'Thursday', 0),
(20240105, '2024-01-05', 2024, 1, 1, 'January', 5, 'Friday', 0),
(20240106, '2024-01-06', 2024, 1, 1, 'January', 6, 'Saturday', 1),
(20240107, '2024-01-07', 2024, 1, 1, 'January', 7, 'Sunday', 1),
(20240108, '2024-01-08', 2024, 1, 1, 'January', 1, 'Monday', 0),
(20240109, '2024-01-09', 2024, 1, 1, 'January', 2, 'Tuesday', 0),
(20240110, '2024-01-10', 2024, 1, 1, 'January', 3, 'Wednesday', 0),
(20240111, '2024-01-11', 2024, 1, 1, 'January', 4, 'Thursday', 0),
(20240112, '2024-01-12', 2024, 1, 1, 'January', 5, 'Friday', 0),
(20240113, '2024-01-13', 2024, 1, 1, 'January', 6, 'Saturday', 1),
(20240114, '2024-01-14', 2024, 1, 1, 'January', 7, 'Sunday', 1),
(20240115, '2024-01-15', 2024, 1, 1, 'January', 1, 'Monday', 0),
(20240116, '2024-01-16', 2024, 1, 1, 'January', 2, 'Tuesday', 0),
(20240117, '2024-01-17', 2024, 1, 1, 'January', 3, 'Wednesday', 0),
(20240118, '2024-01-18', 2024, 1, 1, 'January', 4, 'Thursday', 0),
(20240119, '2024-01-19', 2024, 1, 1, 'January', 5, 'Friday', 0),
(20240120, '2024-01-20', 2024, 1, 1, 'January', 6, 'Saturday', 1),
(20240121, '2024-01-21', 2024, 1, 1, 'January', 7, 'Sunday', 1),
(20240122, '2024-01-22', 2024, 1, 1, 'January', 1, 'Monday', 0),
(20240123, '2024-01-23', 2024, 1, 1, 'January', 2, 'Tuesday', 0),
(20240124, '2024-01-24', 2024, 1, 1, 'January', 3, 'Wednesday', 0),
(20240125, '2024-01-25', 2024, 1, 1, 'January', 4, 'Thursday', 0),
(20240126, '2024-01-26', 2024, 1, 1, 'January', 5, 'Friday', 0),
(20240127, '2024-01-27', 2024, 1, 1, 'January', 6, 'Saturday', 1),
(20240128, '2024-01-28', 2024, 1, 1, 'January', 7, 'Sunday', 1),
(20240129, '2024-01-29', 2024, 1, 1, 'January', 1, 'Monday', 0),
(20240130, '2024-01-30', 2024, 1, 1, 'January', 2, 'Tuesday', 0),
(20240131, '2024-01-31', 2024, 1, 1, 'January', 3, 'Wednesday', 0),
(20240201, '2024-02-01', 2024, 1, 2, 'February', 4, 'Thursday', 0),
(20240202, '2024-02-02', 2024, 1, 2, 'February', 5, 'Friday', 0),
(20240203, '2024-02-03', 2024, 1, 2, 'February', 6, 'Saturday', 1),
(20240204, '2024-02-04', 2024, 1, 2, 'February', 7, 'Sunday', 1),
(20240205, '2024-02-05', 2024, 1, 2, 'February', 1, 'Monday', 0),
(20240206, '2024-02-06', 2024, 1, 2, 'February', 2, 'Tuesday', 0),
(20240207, '2024-02-07', 2024, 1, 2, 'February', 3, 'Wednesday', 0),
(20240208, '2024-02-08', 2024, 1, 2, 'February', 4, 'Thursday', 0),
(20240209, '2024-02-09', 2024, 1, 2, 'February', 5, 'Friday', 0),
(20240210, '2024-02-10', 2024, 1, 2, 'February', 6, 'Saturday', 1),
(20240211, '2024-02-11', 2024, 1, 2, 'February', 7, 'Sunday', 1),
(20240212, '2024-02-12', 2024, 1, 2, 'February', 1, 'Monday', 0),
(20240213, '2024-02-13', 2024, 1, 2, 'February', 2, 'Tuesday', 0),
(20240214, '2024-02-14', 2024, 1, 2, 'February', 3, 'Wednesday', 0),
(20240215, '2024-02-15', 2024, 1, 2, 'February', 4, 'Thursday', 0),
(20240216, '2024-02-16', 2024, 1, 2, 'February', 5, 'Friday', 0),
(20240217, '2024-02-17', 2024, 1, 2, 'February', 6, 'Saturday', 1),
(20240218, '2024-02-18', 2024, 1, 2, 'February', 7, 'Sunday', 1),
(20240219, '2024-02-19', 2024, 1, 2, 'February', 1, 'Monday', 0),
(20240220, '2024-02-20', 2024, 1, 2, 'February', 2, 'Tuesday', 0),
(20240221, '2024-02-21', 2024, 1, 2, 'February', 3, 'Wednesday', 0),
(20240222, '2024-02-22', 2024, 1, 2, 'February', 4, 'Thursday', 0),
(20240223, '2024-02-23', 2024, 1, 2, 'February', 5, 'Friday', 0),
(20240224, '2024-02-24', 2024, 1, 2, 'February', 6, 'Saturday', 1),
(20240225, '2024-02-25', 2024, 1, 2, 'February', 7, 'Sunday', 1),
(20240226, '2024-02-26', 2024, 1, 2, 'February', 1, 'Monday', 0),
(20240227, '2024-02-27', 2024, 1, 2, 'February', 2, 'Tuesday', 0),
(20240228, '2024-02-28', 2024, 1, 2, 'February', 3, 'Wednesday', 0),
(20240229, '2024-02-29', 2024, 1, 2, 'February', 4, 'Thursday', 0),
(20240301, '2024-03-01', 2024, 1, 3, 'March', 5, 'Friday', 0),
(20240302, '2024-03-02', 2024, 1, 3, 'March', 6, 'Saturday', 1),
(20240303, '2024-03-03', 2024, 1, 3, 'March', 7, 'Sunday', 1),
(20240304, '2024-03-04', 2024, 1, 3, 'March', 1, 'Monday', 0),
(20240305, '2024-03-05', 2024, 1, 3, 'March', 2, 'Tuesday', 0),
(20240306, '2024-03-06', 2024, 1, 3, 'March', 3, 'Wednesday', 0),
(20240307, '2024-03-07', 2024, 1, 3, 'March', 4, 'Thursday', 0),
(20240308, '2024-03-08', 2024, 1, 3, 'March', 5, 'Friday', 0),
(20240309, '2024-03-09', 2024, 1, 3, 'March', 6, 'Saturday', 1),
(20240310, '2024-03-10', 2024, 1, 3, 'March', 7, 'Sunday', 1),
(20240311, '2024-03-11', 2024, 1, 3, 'March', 1, 'Monday', 0),
(20240312, '2024-03-12', 2024, 1, 3, 'March', 2, 'Tuesday', 0),
(20240313, '2024-03-13', 2024, 1, 3, 'March', 3, 'Wednesday', 0),
(20240314, '2024-03-14', 2024, 1, 3, 'March', 4, 'Thursday', 0),
(20240315, '2024-03-15', 2024, 1, 3, 'March', 5, 'Friday', 0),
(20240316, '2024-03-16', 2024, 1, 3, 'March', 6, 'Saturday', 1),
(20240317, '2024-03-17', 2024, 1, 3, 'March', 7, 'Sunday', 1),
(20240318, '2024-03-18', 2024, 1, 3, 'March', 1, 'Monday', 0),
(20240319, '2024-03-19', 2024, 1, 3, 'March', 2, 'Tuesday', 0),
(20240320, '2024-03-20', 2024, 1, 3, 'March', 3, 'Wednesday', 0),
(20240321, '2024-03-21', 2024, 1, 3, 'March', 4, 'Thursday', 0),
(20240322, '2024-03-22', 2024, 1, 3, 'March', 5, 'Friday', 0),
(20240323, '2024-03-23', 2024, 1, 3, 'March', 6, 'Saturday', 1),
(20240324, '2024-03-24', 2024, 1, 3, 'March', 7, 'Sunday', 1),
(20240325, '2024-03-25', 2024, 1, 3, 'March', 1, 'Monday', 0),
(20240326, '2024-03-26', 2024, 1, 3, 'March', 2, 'Tuesday', 0),
(20240327, '2024-03-27', 2024, 1, 3, 'March', 3, 'Wednesday', 0),
(20240328, '2024-03-28', 2024, 1, 3, 'March', 4, 'Thursday', 0),
(20240329, '2024-03-29', 2024, 1, 3, 'March', 5, 'Friday', 0),
(20240330, '2024-03-30', 2024, 1, 3, 'March', 6, 'Saturday', 1),
(20240331, '2024-03-31', 2024, 1, 3, 'March', 7, 'Sunday', 1),
(20240401, '2024-04-01', 2024, 2, 4, 'April', 1, 'Monday', 0),
(20240402, '2024-04-02', 2024, 2, 4, 'April', 2, 'Tuesday', 0),
(20240403, '2024-04-03', 2024, 2, 4, 'April', 3, 'Wednesday', 0),
(20240404, '2024-04-04', 2024, 2, 4, 'April', 4, 'Thursday', 0),
(20240405, '2024-04-05', 2024, 2, 4, 'April', 5, 'Friday', 0),
(20240406, '2024-04-06', 2024, 2, 4, 'April', 6, 'Saturday', 1),
(20240407, '2024-04-07', 2024, 2, 4, 'April', 7, 'Sunday', 1),
(20240408, '2024-04-08', 2024, 2, 4, 'April', 1, 'Monday', 0),
(20240409, '2024-04-09', 2024, 2, 4, 'April', 2, 'Tuesday', 0);
GO
INSERT INTO dbo.DIM_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfWeek, DayName, IsWeekend) VALUES
(20240410, '2024-04-10', 2024, 2, 4, 'April', 3, 'Wednesday', 0),
(20240411, '2024-04-11', 2024, 2, 4, 'April', 4, 'Thursday', 0),
(20240412, '2024-04-12', 2024, 2, 4, 'April', 5, 'Friday', 0),
(20240413, '2024-04-13', 2024, 2, 4, 'April', 6, 'Saturday', 1),
(20240414, '2024-04-14', 2024, 2, 4, 'April', 7, 'Sunday', 1),
(20240415, '2024-04-15', 2024, 2, 4, 'April', 1, 'Monday', 0),
(20240416, '2024-04-16', 2024, 2, 4, 'April', 2, 'Tuesday', 0),
(20240417, '2024-04-17', 2024, 2, 4, 'April', 3, 'Wednesday', 0),
(20240418, '2024-04-18', 2024, 2, 4, 'April', 4, 'Thursday', 0),
(20240419, '2024-04-19', 2024, 2, 4, 'April', 5, 'Friday', 0),
(20240420, '2024-04-20', 2024, 2, 4, 'April', 6, 'Saturday', 1),
(20240421, '2024-04-21', 2024, 2, 4, 'April', 7, 'Sunday', 1),
(20240422, '2024-04-22', 2024, 2, 4, 'April', 1, 'Monday', 0),
(20240423, '2024-04-23', 2024, 2, 4, 'April', 2, 'Tuesday', 0),
(20240424, '2024-04-24', 2024, 2, 4, 'April', 3, 'Wednesday', 0),
(20240425, '2024-04-25', 2024, 2, 4, 'April', 4, 'Thursday', 0),
(20240426, '2024-04-26', 2024, 2, 4, 'April', 5, 'Friday', 0),
(20240427, '2024-04-27', 2024, 2, 4, 'April', 6, 'Saturday', 1),
(20240428, '2024-04-28', 2024, 2, 4, 'April', 7, 'Sunday', 1),
(20240429, '2024-04-29', 2024, 2, 4, 'April', 1, 'Monday', 0),
(20240430, '2024-04-30', 2024, 2, 4, 'April', 2, 'Tuesday', 0),
(20240501, '2024-05-01', 2024, 2, 5, 'May', 3, 'Wednesday', 0),
(20240502, '2024-05-02', 2024, 2, 5, 'May', 4, 'Thursday', 0),
(20240503, '2024-05-03', 2024, 2, 5, 'May', 5, 'Friday', 0),
(20240504, '2024-05-04', 2024, 2, 5, 'May', 6, 'Saturday', 1),
(20240505, '2024-05-05', 2024, 2, 5, 'May', 7, 'Sunday', 1),
(20240506, '2024-05-06', 2024, 2, 5, 'May', 1, 'Monday', 0),
(20240507, '2024-05-07', 2024, 2, 5, 'May', 2, 'Tuesday', 0),
(20240508, '2024-05-08', 2024, 2, 5, 'May', 3, 'Wednesday', 0),
(20240509, '2024-05-09', 2024, 2, 5, 'May', 4, 'Thursday', 0),
(20240510, '2024-05-10', 2024, 2, 5, 'May', 5, 'Friday', 0),
(20240511, '2024-05-11', 2024, 2, 5, 'May', 6, 'Saturday', 1),
(20240512, '2024-05-12', 2024, 2, 5, 'May', 7, 'Sunday', 1),
(20240513, '2024-05-13', 2024, 2, 5, 'May', 1, 'Monday', 0),
(20240514, '2024-05-14', 2024, 2, 5, 'May', 2, 'Tuesday', 0),
(20240515, '2024-05-15', 2024, 2, 5, 'May', 3, 'Wednesday', 0),
(20240516, '2024-05-16', 2024, 2, 5, 'May', 4, 'Thursday', 0),
(20240517, '2024-05-17', 2024, 2, 5, 'May', 5, 'Friday', 0),
(20240518, '2024-05-18', 2024, 2, 5, 'May', 6, 'Saturday', 1),
(20240519, '2024-05-19', 2024, 2, 5, 'May', 7, 'Sunday', 1),
(20240520, '2024-05-20', 2024, 2, 5, 'May', 1, 'Monday', 0),
(20240521, '2024-05-21', 2024, 2, 5, 'May', 2, 'Tuesday', 0),
(20240522, '2024-05-22', 2024, 2, 5, 'May', 3, 'Wednesday', 0),
(20240523, '2024-05-23', 2024, 2, 5, 'May', 4, 'Thursday', 0),
(20240524, '2024-05-24', 2024, 2, 5, 'May', 5, 'Friday', 0),
(20240525, '2024-05-25', 2024, 2, 5, 'May', 6, 'Saturday', 1),
(20240526, '2024-05-26', 2024, 2, 5, 'May', 7, 'Sunday', 1),
(20240527, '2024-05-27', 2024, 2, 5, 'May', 1, 'Monday', 0),
(20240528, '2024-05-28', 2024, 2, 5, 'May', 2, 'Tuesday', 0),
(20240529, '2024-05-29', 2024, 2, 5, 'May', 3, 'Wednesday', 0),
(20240530, '2024-05-30', 2024, 2, 5, 'May', 4, 'Thursday', 0),
(20240531, '2024-05-31', 2024, 2, 5, 'May', 5, 'Friday', 0),
(20240601, '2024-06-01', 2024, 2, 6, 'June', 6, 'Saturday', 1),
(20240602, '2024-06-02', 2024, 2, 6, 'June', 7, 'Sunday', 1),
(20240603, '2024-06-03', 2024, 2, 6, 'June', 1, 'Monday', 0),
(20240604, '2024-06-04', 2024, 2, 6, 'June', 2, 'Tuesday', 0),
(20240605, '2024-06-05', 2024, 2, 6, 'June', 3, 'Wednesday', 0),
(20240606, '2024-06-06', 2024, 2, 6, 'June', 4, 'Thursday', 0),
(20240607, '2024-06-07', 2024, 2, 6, 'June', 5, 'Friday', 0),
(20240608, '2024-06-08', 2024, 2, 6, 'June', 6, 'Saturday', 1),
(20240609, '2024-06-09', 2024, 2, 6, 'June', 7, 'Sunday', 1),
(20240610, '2024-06-10', 2024, 2, 6, 'June', 1, 'Monday', 0),
(20240611, '2024-06-11', 2024, 2, 6, 'June', 2, 'Tuesday', 0),
(20240612, '2024-06-12', 2024, 2, 6, 'June', 3, 'Wednesday', 0),
(20240613, '2024-06-13', 2024, 2, 6, 'June', 4, 'Thursday', 0),
(20240614, '2024-06-14', 2024, 2, 6, 'June', 5, 'Friday', 0),
(20240615, '2024-06-15', 2024, 2, 6, 'June', 6, 'Saturday', 1),
(20240616, '2024-06-16', 2024, 2, 6, 'June', 7, 'Sunday', 1),
(20240617, '2024-06-17', 2024, 2, 6, 'June', 1, 'Monday', 0),
(20240618, '2024-06-18', 2024, 2, 6, 'June', 2, 'Tuesday', 0),
(20240619, '2024-06-19', 2024, 2, 6, 'June', 3, 'Wednesday', 0),
(20240620, '2024-06-20', 2024, 2, 6, 'June', 4, 'Thursday', 0),
(20240621, '2024-06-21', 2024, 2, 6, 'June', 5, 'Friday', 0),
(20240622, '2024-06-22', 2024, 2, 6, 'June', 6, 'Saturday', 1),
(20240623, '2024-06-23', 2024, 2, 6, 'June', 7, 'Sunday', 1),
(20240624, '2024-06-24', 2024, 2, 6, 'June', 1, 'Monday', 0),
(20240625, '2024-06-25', 2024, 2, 6, 'June', 2, 'Tuesday', 0),
(20240626, '2024-06-26', 2024, 2, 6, 'June', 3, 'Wednesday', 0),
(20240627, '2024-06-27', 2024, 2, 6, 'June', 4, 'Thursday', 0),
(20240628, '2024-06-28', 2024, 2, 6, 'June', 5, 'Friday', 0),
(20240629, '2024-06-29', 2024, 2, 6, 'June', 6, 'Saturday', 1),
(20240630, '2024-06-30', 2024, 2, 6, 'June', 7, 'Sunday', 1),
(20240701, '2024-07-01', 2024, 3, 7, 'July', 1, 'Monday', 0),
(20240702, '2024-07-02', 2024, 3, 7, 'July', 2, 'Tuesday', 0),
(20240703, '2024-07-03', 2024, 3, 7, 'July', 3, 'Wednesday', 0),
(20240704, '2024-07-04', 2024, 3, 7, 'July', 4, 'Thursday', 0),
(20240705, '2024-07-05', 2024, 3, 7, 'July', 5, 'Friday', 0),
(20240706, '2024-07-06', 2024, 3, 7, 'July', 6, 'Saturday', 1),
(20240707, '2024-07-07', 2024, 3, 7, 'July', 7, 'Sunday', 1),
(20240708, '2024-07-08', 2024, 3, 7, 'July', 1, 'Monday', 0),
(20240709, '2024-07-09', 2024, 3, 7, 'July', 2, 'Tuesday', 0),
(20240710, '2024-07-10', 2024, 3, 7, 'July', 3, 'Wednesday', 0),
(20240711, '2024-07-11', 2024, 3, 7, 'July', 4, 'Thursday', 0),
(20240712, '2024-07-12', 2024, 3, 7, 'July', 5, 'Friday', 0),
(20240713, '2024-07-13', 2024, 3, 7, 'July', 6, 'Saturday', 1),
(20240714, '2024-07-14', 2024, 3, 7, 'July', 7, 'Sunday', 1),
(20240715, '2024-07-15', 2024, 3, 7, 'July', 1, 'Monday', 0),
(20240716, '2024-07-16', 2024, 3, 7, 'July', 2, 'Tuesday', 0),
(20240717, '2024-07-17', 2024, 3, 7, 'July', 3, 'Wednesday', 0),
(20240718, '2024-07-18', 2024, 3, 7, 'July', 4, 'Thursday', 0);
GO
INSERT INTO dbo.DIM_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfWeek, DayName, IsWeekend) VALUES
(20240719, '2024-07-19', 2024, 3, 7, 'July', 5, 'Friday', 0),
(20240720, '2024-07-20', 2024, 3, 7, 'July', 6, 'Saturday', 1),
(20240721, '2024-07-21', 2024, 3, 7, 'July', 7, 'Sunday', 1),
(20240722, '2024-07-22', 2024, 3, 7, 'July', 1, 'Monday', 0),
(20240723, '2024-07-23', 2024, 3, 7, 'July', 2, 'Tuesday', 0),
(20240724, '2024-07-24', 2024, 3, 7, 'July', 3, 'Wednesday', 0),
(20240725, '2024-07-25', 2024, 3, 7, 'July', 4, 'Thursday', 0),
(20240726, '2024-07-26', 2024, 3, 7, 'July', 5, 'Friday', 0),
(20240727, '2024-07-27', 2024, 3, 7, 'July', 6, 'Saturday', 1),
(20240728, '2024-07-28', 2024, 3, 7, 'July', 7, 'Sunday', 1),
(20240729, '2024-07-29', 2024, 3, 7, 'July', 1, 'Monday', 0),
(20240730, '2024-07-30', 2024, 3, 7, 'July', 2, 'Tuesday', 0),
(20240731, '2024-07-31', 2024, 3, 7, 'July', 3, 'Wednesday', 0),
(20240801, '2024-08-01', 2024, 3, 8, 'August', 4, 'Thursday', 0),
(20240802, '2024-08-02', 2024, 3, 8, 'August', 5, 'Friday', 0),
(20240803, '2024-08-03', 2024, 3, 8, 'August', 6, 'Saturday', 1),
(20240804, '2024-08-04', 2024, 3, 8, 'August', 7, 'Sunday', 1),
(20240805, '2024-08-05', 2024, 3, 8, 'August', 1, 'Monday', 0),
(20240806, '2024-08-06', 2024, 3, 8, 'August', 2, 'Tuesday', 0),
(20240807, '2024-08-07', 2024, 3, 8, 'August', 3, 'Wednesday', 0),
(20240808, '2024-08-08', 2024, 3, 8, 'August', 4, 'Thursday', 0),
(20240809, '2024-08-09', 2024, 3, 8, 'August', 5, 'Friday', 0),
(20240810, '2024-08-10', 2024, 3, 8, 'August', 6, 'Saturday', 1),
(20240811, '2024-08-11', 2024, 3, 8, 'August', 7, 'Sunday', 1),
(20240812, '2024-08-12', 2024, 3, 8, 'August', 1, 'Monday', 0),
(20240813, '2024-08-13', 2024, 3, 8, 'August', 2, 'Tuesday', 0),
(20240814, '2024-08-14', 2024, 3, 8, 'August', 3, 'Wednesday', 0),
(20240815, '2024-08-15', 2024, 3, 8, 'August', 4, 'Thursday', 0),
(20240816, '2024-08-16', 2024, 3, 8, 'August', 5, 'Friday', 0),
(20240817, '2024-08-17', 2024, 3, 8, 'August', 6, 'Saturday', 1),
(20240818, '2024-08-18', 2024, 3, 8, 'August', 7, 'Sunday', 1),
(20240819, '2024-08-19', 2024, 3, 8, 'August', 1, 'Monday', 0),
(20240820, '2024-08-20', 2024, 3, 8, 'August', 2, 'Tuesday', 0),
(20240821, '2024-08-21', 2024, 3, 8, 'August', 3, 'Wednesday', 0),
(20240822, '2024-08-22', 2024, 3, 8, 'August', 4, 'Thursday', 0),
(20240823, '2024-08-23', 2024, 3, 8, 'August', 5, 'Friday', 0),
(20240824, '2024-08-24', 2024, 3, 8, 'August', 6, 'Saturday', 1),
(20240825, '2024-08-25', 2024, 3, 8, 'August', 7, 'Sunday', 1),
(20240826, '2024-08-26', 2024, 3, 8, 'August', 1, 'Monday', 0),
(20240827, '2024-08-27', 2024, 3, 8, 'August', 2, 'Tuesday', 0),
(20240828, '2024-08-28', 2024, 3, 8, 'August', 3, 'Wednesday', 0),
(20240829, '2024-08-29', 2024, 3, 8, 'August', 4, 'Thursday', 0),
(20240830, '2024-08-30', 2024, 3, 8, 'August', 5, 'Friday', 0),
(20240831, '2024-08-31', 2024, 3, 8, 'August', 6, 'Saturday', 1),
(20240901, '2024-09-01', 2024, 3, 9, 'September', 7, 'Sunday', 1),
(20240902, '2024-09-02', 2024, 3, 9, 'September', 1, 'Monday', 0),
(20240903, '2024-09-03', 2024, 3, 9, 'September', 2, 'Tuesday', 0),
(20240904, '2024-09-04', 2024, 3, 9, 'September', 3, 'Wednesday', 0),
(20240905, '2024-09-05', 2024, 3, 9, 'September', 4, 'Thursday', 0),
(20240906, '2024-09-06', 2024, 3, 9, 'September', 5, 'Friday', 0),
(20240907, '2024-09-07', 2024, 3, 9, 'September', 6, 'Saturday', 1),
(20240908, '2024-09-08', 2024, 3, 9, 'September', 7, 'Sunday', 1),
(20240909, '2024-09-09', 2024, 3, 9, 'September', 1, 'Monday', 0),
(20240910, '2024-09-10', 2024, 3, 9, 'September', 2, 'Tuesday', 0),
(20240911, '2024-09-11', 2024, 3, 9, 'September', 3, 'Wednesday', 0),
(20240912, '2024-09-12', 2024, 3, 9, 'September', 4, 'Thursday', 0),
(20240913, '2024-09-13', 2024, 3, 9, 'September', 5, 'Friday', 0),
(20240914, '2024-09-14', 2024, 3, 9, 'September', 6, 'Saturday', 1),
(20240915, '2024-09-15', 2024, 3, 9, 'September', 7, 'Sunday', 1),
(20240916, '2024-09-16', 2024, 3, 9, 'September', 1, 'Monday', 0),
(20240917, '2024-09-17', 2024, 3, 9, 'September', 2, 'Tuesday', 0),
(20240918, '2024-09-18', 2024, 3, 9, 'September', 3, 'Wednesday', 0),
(20240919, '2024-09-19', 2024, 3, 9, 'September', 4, 'Thursday', 0),
(20240920, '2024-09-20', 2024, 3, 9, 'September', 5, 'Friday', 0),
(20240921, '2024-09-21', 2024, 3, 9, 'September', 6, 'Saturday', 1),
(20240922, '2024-09-22', 2024, 3, 9, 'September', 7, 'Sunday', 1),
(20240923, '2024-09-23', 2024, 3, 9, 'September', 1, 'Monday', 0),
(20240924, '2024-09-24', 2024, 3, 9, 'September', 2, 'Tuesday', 0),
(20240925, '2024-09-25', 2024, 3, 9, 'September', 3, 'Wednesday', 0),
(20240926, '2024-09-26', 2024, 3, 9, 'September', 4, 'Thursday', 0),
(20240927, '2024-09-27', 2024, 3, 9, 'September', 5, 'Friday', 0),
(20240928, '2024-09-28', 2024, 3, 9, 'September', 6, 'Saturday', 1),
(20240929, '2024-09-29', 2024, 3, 9, 'September', 7, 'Sunday', 1),
(20240930, '2024-09-30', 2024, 3, 9, 'September', 1, 'Monday', 0),
(20241001, '2024-10-01', 2024, 4, 10, 'October', 2, 'Tuesday', 0),
(20241002, '2024-10-02', 2024, 4, 10, 'October', 3, 'Wednesday', 0),
(20241003, '2024-10-03', 2024, 4, 10, 'October', 4, 'Thursday', 0),
(20241004, '2024-10-04', 2024, 4, 10, 'October', 5, 'Friday', 0),
(20241005, '2024-10-05', 2024, 4, 10, 'October', 6, 'Saturday', 1),
(20241006, '2024-10-06', 2024, 4, 10, 'October', 7, 'Sunday', 1),
(20241007, '2024-10-07', 2024, 4, 10, 'October', 1, 'Monday', 0),
(20241008, '2024-10-08', 2024, 4, 10, 'October', 2, 'Tuesday', 0),
(20241009, '2024-10-09', 2024, 4, 10, 'October', 3, 'Wednesday', 0),
(20241010, '2024-10-10', 2024, 4, 10, 'October', 4, 'Thursday', 0),
(20241011, '2024-10-11', 2024, 4, 10, 'October', 5, 'Friday', 0),
(20241012, '2024-10-12', 2024, 4, 10, 'October', 6, 'Saturday', 1),
(20241013, '2024-10-13', 2024, 4, 10, 'October', 7, 'Sunday', 1),
(20241014, '2024-10-14', 2024, 4, 10, 'October', 1, 'Monday', 0),
(20241015, '2024-10-15', 2024, 4, 10, 'October', 2, 'Tuesday', 0),
(20241016, '2024-10-16', 2024, 4, 10, 'October', 3, 'Wednesday', 0),
(20241017, '2024-10-17', 2024, 4, 10, 'October', 4, 'Thursday', 0),
(20241018, '2024-10-18', 2024, 4, 10, 'October', 5, 'Friday', 0),
(20241019, '2024-10-19', 2024, 4, 10, 'October', 6, 'Saturday', 1),
(20241020, '2024-10-20', 2024, 4, 10, 'October', 7, 'Sunday', 1),
(20241021, '2024-10-21', 2024, 4, 10, 'October', 1, 'Monday', 0),
(20241022, '2024-10-22', 2024, 4, 10, 'October', 2, 'Tuesday', 0),
(20241023, '2024-10-23', 2024, 4, 10, 'October', 3, 'Wednesday', 0),
(20241024, '2024-10-24', 2024, 4, 10, 'October', 4, 'Thursday', 0),
(20241025, '2024-10-25', 2024, 4, 10, 'October', 5, 'Friday', 0),
(20241026, '2024-10-26', 2024, 4, 10, 'October', 6, 'Saturday', 1);
GO
INSERT INTO dbo.DIM_Date (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfWeek, DayName, IsWeekend) VALUES
(20241027, '2024-10-27', 2024, 4, 10, 'October', 7, 'Sunday', 1),
(20241028, '2024-10-28', 2024, 4, 10, 'October', 1, 'Monday', 0),
(20241029, '2024-10-29', 2024, 4, 10, 'October', 2, 'Tuesday', 0),
(20241030, '2024-10-30', 2024, 4, 10, 'October', 3, 'Wednesday', 0),
(20241031, '2024-10-31', 2024, 4, 10, 'October', 4, 'Thursday', 0),
(20241101, '2024-11-01', 2024, 4, 11, 'November', 5, 'Friday', 0),
(20241102, '2024-11-02', 2024, 4, 11, 'November', 6, 'Saturday', 1),
(20241103, '2024-11-03', 2024, 4, 11, 'November', 7, 'Sunday', 1),
(20241104, '2024-11-04', 2024, 4, 11, 'November', 1, 'Monday', 0),
(20241105, '2024-11-05', 2024, 4, 11, 'November', 2, 'Tuesday', 0),
(20241106, '2024-11-06', 2024, 4, 11, 'November', 3, 'Wednesday', 0),
(20241107, '2024-11-07', 2024, 4, 11, 'November', 4, 'Thursday', 0),
(20241108, '2024-11-08', 2024, 4, 11, 'November', 5, 'Friday', 0),
(20241109, '2024-11-09', 2024, 4, 11, 'November', 6, 'Saturday', 1),
(20241110, '2024-11-10', 2024, 4, 11, 'November', 7, 'Sunday', 1),
(20241111, '2024-11-11', 2024, 4, 11, 'November', 1, 'Monday', 0),
(20241112, '2024-11-12', 2024, 4, 11, 'November', 2, 'Tuesday', 0),
(20241113, '2024-11-13', 2024, 4, 11, 'November', 3, 'Wednesday', 0),
(20241114, '2024-11-14', 2024, 4, 11, 'November', 4, 'Thursday', 0),
(20241115, '2024-11-15', 2024, 4, 11, 'November', 5, 'Friday', 0),
(20241116, '2024-11-16', 2024, 4, 11, 'November', 6, 'Saturday', 1),
(20241117, '2024-11-17', 2024, 4, 11, 'November', 7, 'Sunday', 1),
(20241118, '2024-11-18', 2024, 4, 11, 'November', 1, 'Monday', 0),
(20241119, '2024-11-19', 2024, 4, 11, 'November', 2, 'Tuesday', 0),
(20241120, '2024-11-20', 2024, 4, 11, 'November', 3, 'Wednesday', 0),
(20241121, '2024-11-21', 2024, 4, 11, 'November', 4, 'Thursday', 0),
(20241122, '2024-11-22', 2024, 4, 11, 'November', 5, 'Friday', 0),
(20241123, '2024-11-23', 2024, 4, 11, 'November', 6, 'Saturday', 1),
(20241124, '2024-11-24', 2024, 4, 11, 'November', 7, 'Sunday', 1),
(20241125, '2024-11-25', 2024, 4, 11, 'November', 1, 'Monday', 0),
(20241126, '2024-11-26', 2024, 4, 11, 'November', 2, 'Tuesday', 0),
(20241127, '2024-11-27', 2024, 4, 11, 'November', 3, 'Wednesday', 0),
(20241128, '2024-11-28', 2024, 4, 11, 'November', 4, 'Thursday', 0),
(20241129, '2024-11-29', 2024, 4, 11, 'November', 5, 'Friday', 0),
(20241130, '2024-11-30', 2024, 4, 11, 'November', 6, 'Saturday', 1),
(20241201, '2024-12-01', 2024, 4, 12, 'December', 7, 'Sunday', 1),
(20241202, '2024-12-02', 2024, 4, 12, 'December', 1, 'Monday', 0),
(20241203, '2024-12-03', 2024, 4, 12, 'December', 2, 'Tuesday', 0),
(20241204, '2024-12-04', 2024, 4, 12, 'December', 3, 'Wednesday', 0),
(20241205, '2024-12-05', 2024, 4, 12, 'December', 4, 'Thursday', 0),
(20241206, '2024-12-06', 2024, 4, 12, 'December', 5, 'Friday', 0),
(20241207, '2024-12-07', 2024, 4, 12, 'December', 6, 'Saturday', 1),
(20241208, '2024-12-08', 2024, 4, 12, 'December', 7, 'Sunday', 1),
(20241209, '2024-12-09', 2024, 4, 12, 'December', 1, 'Monday', 0),
(20241210, '2024-12-10', 2024, 4, 12, 'December', 2, 'Tuesday', 0),
(20241211, '2024-12-11', 2024, 4, 12, 'December', 3, 'Wednesday', 0),
(20241212, '2024-12-12', 2024, 4, 12, 'December', 4, 'Thursday', 0),
(20241213, '2024-12-13', 2024, 4, 12, 'December', 5, 'Friday', 0),
(20241214, '2024-12-14', 2024, 4, 12, 'December', 6, 'Saturday', 1),
(20241215, '2024-12-15', 2024, 4, 12, 'December', 7, 'Sunday', 1),
(20241216, '2024-12-16', 2024, 4, 12, 'December', 1, 'Monday', 0),
(20241217, '2024-12-17', 2024, 4, 12, 'December', 2, 'Tuesday', 0),
(20241218, '2024-12-18', 2024, 4, 12, 'December', 3, 'Wednesday', 0),
(20241219, '2024-12-19', 2024, 4, 12, 'December', 4, 'Thursday', 0),
(20241220, '2024-12-20', 2024, 4, 12, 'December', 5, 'Friday', 0),
(20241221, '2024-12-21', 2024, 4, 12, 'December', 6, 'Saturday', 1),
(20241222, '2024-12-22', 2024, 4, 12, 'December', 7, 'Sunday', 1),
(20241223, '2024-12-23', 2024, 4, 12, 'December', 1, 'Monday', 0),
(20241224, '2024-12-24', 2024, 4, 12, 'December', 2, 'Tuesday', 0),
(20241225, '2024-12-25', 2024, 4, 12, 'December', 3, 'Wednesday', 0),
(20241226, '2024-12-26', 2024, 4, 12, 'December', 4, 'Thursday', 0),
(20241227, '2024-12-27', 2024, 4, 12, 'December', 5, 'Friday', 0),
(20241228, '2024-12-28', 2024, 4, 12, 'December', 6, 'Saturday', 1),
(20241229, '2024-12-29', 2024, 4, 12, 'December', 7, 'Sunday', 1),
(20241230, '2024-12-30', 2024, 4, 12, 'December', 1, 'Monday', 0),
(20241231, '2024-12-31', 2024, 4, 12, 'December', 2, 'Tuesday', 0);
GO
-- 4.5 FACT_Transaction
SET IDENTITY_INSERT dbo.FACT_Transaction ON;
GO
INSERT INTO dbo.FACT_Transaction (TransactionKey, CustomerKey, ProductKey, DateKey, BranchKey, Amount, Quantity, TransactionType, FlagQuality) VALUES
(1, 1, 6, 20240424, 2, 4739.56, 2, 'Deposit', 1),
(2, 9, 3, 20240725, 3, 3072.31, 2, 'Withdrawal', 1),
(3, 4, 2, 20241022, 5, 2055.06, 3, 'Transfer', 1),
(4, 4, 5, 20241204, 1, 2312.28, 2, 'Withdrawal', 0),
(5, 3, 6, 20240130, 2, 203.07, 5, 'Withdrawal', 1),
(6, 8, 3, 20240101, 2, 135.24, 1, 'Withdrawal', 0),
(7, 12, 6, 20241130, 2, 253.92, 3, 'Purchase', 1),
(8, 3, 1, 20240721, 1, 1464.54, 4, 'Withdrawal', 1),
(9, 14, 5, 20240626, 5, 3644.43, 5, 'Transfer', 1),
(10, 6, 10, 20241215, 1, 2417.57, 4, 'Withdrawal', 0),
(11, 18, 3, 20240608, 2, 3329.02, 3, 'Transfer', 1),
(12, 11, 1, 20240415, 5, 4332.80, 1, 'Purchase', 0),
(13, 2, 4, 20240401, 5, 3668.25, 1, 'Withdrawal', 1),
(14, 16, 5, 20241015, 3, 2727.80, 2, 'Transfer', 1),
(15, 7, 3, 20240923, 3, 2366.88, 1, 'Transfer', 1),
(16, 4, 4, 20240906, 2, 4294.24, 1, 'Purchase', 1),
(17, 14, 9, 20240413, 2, 2748.88, 1, 'Purchase', 1),
(18, 4, 3, 20240122, 5, 4258.61, 2, 'Transfer', 1),
(19, 8, 9, 20240705, 4, 1147.36, 4, 'Purchase', 1),
(20, 8, 9, 20240829, 1, 110.56, 4, 'Deposit', 1),
(21, 15, 3, 20241201, 1, 3947.13, 3, 'Transfer', 1),
(22, 15, 8, 20240602, 2, 3679.48, 5, 'Transfer', 1),
(23, 4, 4, 20240511, 2, 1553.87, 1, 'Purchase', 1),
(24, 15, 2, 20240915, 1, 380.11, 5, 'Transfer', 1),
(25, 9, 7, 20241006, 5, 4278.33, 2, 'Purchase', 1),
(26, 5, 5, 20240109, 5, 492.55, 2, 'Purchase', 1),
(27, 11, 5, 20240918, 3, 3408.54, 2, 'Transfer', 1),
(28, 11, 10, 20240225, 4, 4462.41, 2, 'Purchase', 1),
(29, 16, 5, 20240801, 5, 2154.20, 5, 'Deposit', 1),
(30, 2, 3, 20240425, 1, 1100.87, 3, 'Withdrawal', 1),
(31, 5, 5, 20240610, 4, 741.30, 3, 'Transfer', 1),
(32, 11, 4, 20240325, 2, 3784.14, 1, 'Purchase', 1),
(33, 1, 3, 20240304, 2, 4992.43, 1, 'Purchase', 1),
(34, 8, 3, 20240217, 2, 2578.84, 2, 'Deposit', 1),
(35, 7, 5, 20240418, 5, 4408.42, 3, 'Deposit', 1),
(36, 8, 5, 20240602, 3, 4185.35, 3, 'Purchase', 1),
(37, 19, 1, 20240417, 1, 2817.55, 1, 'Withdrawal', 1),
(38, 4, 1, 20240725, 1, 4459.59, 5, 'Withdrawal', 1),
(39, 4, 1, 20240815, 1, 3063.67, 3, 'Withdrawal', 1),
(40, 3, 2, 20240813, 3, 4279.27, 5, 'Transfer', 1),
(41, 17, 6, 20240519, 3, 4549.98, 1, 'Purchase', 1),
(42, 1, 3, 20240216, 3, 4163.81, 1, 'Purchase', 1),
(43, 5, 4, 20241103, 3, 741.02, 3, 'Withdrawal', 1),
(44, 6, 6, 20240615, 4, 2803.23, 4, 'Purchase', 1),
(45, 11, 9, 20241217, 4, 4730.75, 2, 'Purchase', 1),
(46, 10, 3, 20241205, 3, 2954.30, 2, 'Transfer', 1),
(47, 11, 1, 20241116, 3, 1610.47, 1, 'Deposit', 1),
(48, 14, 6, 20241031, 5, 1322.70, 1, 'Deposit', 1),
(49, 1, 3, 20240127, 2, 4432.26, 4, 'Withdrawal', 1),
(50, 1, 8, 20240916, 3, 1260.01, 2, 'Withdrawal', 1),
(51, 11, 2, 20240222, 1, 221.45, 3, 'Transfer', 1),
(52, 13, 9, 20240617, 3, 4333.91, 2, 'Deposit', 1),
(53, 2, 2, 20240905, 3, 3536.26, 4, 'Purchase', 1),
(54, 8, 3, 20240503, 2, 1189.93, 4, 'Deposit', 1),
(55, 11, 7, 20240312, 2, 3997.19, 2, 'Withdrawal', 0),
(56, 10, 6, 20240127, 5, 1046.34, 3, 'Deposit', 1),
(57, 10, 6, 20240307, 1, 4837.76, 3, 'Deposit', 1),
(58, 18, 9, 20240916, 1, 2058.42, 5, 'Deposit', 1),
(59, 13, 9, 20240527, 5, 665.17, 3, 'Withdrawal', 1),
(60, 1, 8, 20240112, 5, 4919.40, 1, 'Purchase', 1),
(61, 18, 7, 20240404, 2, 1793.87, 3, 'Transfer', 1),
(62, 18, 2, 20240330, 1, 2605.97, 4, 'Withdrawal', 1),
(63, 9, 5, 20240310, 2, 3573.05, 1, 'Withdrawal', 1);
SET IDENTITY_INSERT dbo.FACT_Transaction OFF;
GO

-- ============================================================
-- 5. Row-Level Security (RLS)
-- ============================================================

-- 5.1 Security.UserBranch — maps analysts to the branch(es) they may see
CREATE TABLE Security.UserBranch (
    UserName NVARCHAR(128) NOT NULL,
    BranchKey INT NOT NULL,
    CONSTRAINT PK_UserBranch PRIMARY KEY (UserName, BranchKey),
    CONSTRAINT FK_UserBranch_Branch FOREIGN KEY (BranchKey) REFERENCES dbo.DIM_Branch(BranchKey)
);
GO

INSERT INTO Security.UserBranch (UserName, BranchKey) VALUES
    ('LauraGomez', 1),
    ('LauraGomez', 2),
    ('CarlosMendez', 3);
GO

-- 5.2 Predicate function for FACT_Transaction
-- Row-correlated: SQL Server calls this once per row and binds the row's
-- BranchKey to @branchKey. AuditCompliance, DWHAdmin and ETLService are
-- exempted so audits, admin work and the ETL load/cleanup are never filtered.
CREATE FUNCTION Security.fn_predicate_transaction(
    @userName sysname,
    @branchKey INT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS can_see
    WHERE
        @userName IN ('AuditCompliance', 'DWHAdmin', 'ETLService')
        OR EXISTS (
            SELECT 1
            FROM Security.UserBranch ub
            WHERE ub.UserName = @userName
              AND ub.BranchKey = @branchKey
        )
);
GO

CREATE SECURITY POLICY Security.pol_transaction
ADD FILTER PREDICATE Security.fn_predicate_transaction(USER_NAME(), [BranchKey])
ON dbo.FACT_Transaction
WITH (STATE = ON);
GO

-- 5.3 Predicate function for DIM_Customer
-- Analysts only see customers who have a transaction in one of their branches.
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
        @userName IN ('AuditCompliance', 'DWHAdmin', 'ETLService')
        OR EXISTS (
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

CREATE SECURITY POLICY Security.pol_customer
ADD FILTER PREDICATE Security.fn_predicate_customer(USER_NAME(), [CustomerKey])
ON dbo.DIM_Customer
WITH (STATE = ON);
GO

-- 5.4 Performance indexes to support the RLS predicates
CREATE NONCLUSTERED INDEX IX_UserBranch_UserName_BranchKey
ON Security.UserBranch (UserName, BranchKey);
GO

CREATE NONCLUSTERED INDEX IX_FACT_Transaction_CustomerKey_BranchKey
ON dbo.FACT_Transaction (CustomerKey, BranchKey);
GO

-- ============================================================
-- 6. Dynamic Data Masking (DDM)
-- ============================================================

ALTER TABLE dbo.DIM_Customer
ALTER COLUMN Cedula ADD MASKED WITH (FUNCTION = 'partial(4, "XXXX-", 0)');
GO

ALTER TABLE dbo.DIM_Customer
ALTER COLUMN Email ADD MASKED WITH (FUNCTION = 'email()');
GO

ALTER TABLE dbo.DIM_Customer
ALTER COLUMN Phone ADD MASKED WITH (FUNCTION = 'partial(0, "XXXX-XXXX-", 4)');
GO

GRANT UNMASK ON dbo.DIM_Customer TO AuditCompliance;
GRANT UNMASK ON dbo.DIM_Customer TO DWHAdmin;
GRANT UNMASK ON dbo.DIM_Customer TO ETLService;
GO

-- ============================================================
-- 7. Base permissions
-- ============================================================

GRANT SELECT ON dbo.DIM_Customer   TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Product    TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Date       TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Branch     TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.FACT_Transaction TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GO

GRANT INSERT, ALTER ON dbo.DIM_Customer TO ETLService;
GRANT INSERT, ALTER ON dbo.DIM_Product  TO ETLService;
GRANT INSERT         ON dbo.DIM_Date    TO ETLService;
GRANT INSERT, ALTER ON dbo.DIM_Branch   TO ETLService;
GRANT INSERT, DELETE ON dbo.FACT_Transaction TO ETLService;
GO

-- ============================================================
-- 8. Native Auditing (database-level object)
-- The SERVER AUDIT object (BankingDWH_Audit) was already created in
-- master in section 0.2 above.
-- ============================================================

CREATE TABLE Security.AuditLog (
    AuditLogID INT IDENTITY(1,1) PRIMARY KEY,
    event_time DATETIME2 NOT NULL,
    action_id NVARCHAR(20) NOT NULL,
    session_id INT NOT NULL,
    server_principal_name NVARCHAR(128) NOT NULL,
    database_principal_name NVARCHAR(128) NOT NULL,
    object_name NVARCHAR(128) NOT NULL,
    statement NVARCHAR(MAX) NULL,
    processed_date DATETIME2 DEFAULT GETDATE()
);
GO

CREATE PROCEDURE Security.sp_LoadAuditLog
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Security.AuditLog (
        event_time, action_id, session_id,
        server_principal_name, database_principal_name,
        object_name, statement
    )
    SELECT
        event_time, action_id, session_id,
        server_principal_name, database_principal_name,
        object_name, statement
    FROM sys.fn_get_audit_file('C:\SQLAudit\*.sqlaudit', DEFAULT, DEFAULT)
    WHERE database_name = 'BankingDWH'
      AND object_name IN ('FACT_Transaction', 'DIM_Customer')
      AND NOT EXISTS (
          SELECT 1 FROM Security.AuditLog AL
          WHERE AL.event_time = event_time
            AND AL.action_id = action_id
            AND AL.session_id = session_id
            AND AL.statement = statement
      )
    ORDER BY event_time;

    PRINT 'Audit logs loaded successfully.';
END
GO

CREATE DATABASE AUDIT SPECIFICATION BankingDWH_Audit_Spec
FOR SERVER AUDIT BankingDWH_Audit
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.FACT_Transaction BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON dbo.DIM_Customer BY PUBLIC);
GO

ALTER DATABASE AUDIT SPECIFICATION BankingDWH_Audit_Spec WITH (STATE = ON);
GO

GRANT EXECUTE ON Security.sp_LoadAuditLog TO AuditCompliance;
GRANT EXECUTE ON Security.sp_LoadAuditLog TO DWHAdmin;
GRANT SELECT  ON Security.AuditLog TO AuditCompliance;
GRANT SELECT  ON Security.AuditLog TO DWHAdmin;
GO

-- ============================================================
-- 9. Post-Deployment Verification
-- ============================================================

EXECUTE AS USER = 'DWHAdmin';
GO

SELECT USER_NAME() AS CurrentUser;

SELECT 'DIM_Customer' AS TableName, COUNT(*) AS TotalRows
FROM dbo.DIM_Customer
UNION ALL
SELECT 'DIM_Product', COUNT(*)
FROM dbo.DIM_Product
UNION ALL
SELECT 'DIM_Date', COUNT(*)
FROM dbo.DIM_Date
UNION ALL
SELECT 'DIM_Branch', COUNT(*)
FROM dbo.DIM_Branch
UNION ALL
SELECT 'FACT_Transaction', COUNT(*)
FROM dbo.FACT_Transaction;
GO

REVERT;
GO

PRINT 'Post-deployment verification completed successfully.';
GO