-- BASE SELECT PERMISSIONS

USE BankingDWH;
GO

GRANT SELECT ON dbo.DIM_Cliente TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Producto TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Tiempo TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.DIM_Sucursal TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GRANT SELECT ON dbo.FACT_Transaccion TO LauraGomez, CarlosMendez, AuditCompliance, DWHAdmin, ETLService;
GO