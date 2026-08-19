USE BankingDWH;
GO

GRANT SELECT ON dbo.DIM_Customer TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Product TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Date TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Branch TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.FACT_Transaction TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GO


GRANT INSERT, ALTER ON dbo.DIM_Customer TO ETLService;
GRANT INSERT, ALTER ON dbo.DIM_Product TO ETLService;
GRANT INSERT        ON dbo.DIM_Date TO ETLService;
GRANT INSERT, ALTER ON dbo.DIM_Branch TO ETLService;
GRANT INSERT, DELETE ON dbo.FACT_Transaction TO ETLService;
GO