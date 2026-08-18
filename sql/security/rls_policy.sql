-- RLS SECURITY POLICY (CORRECTED)
-- Purpose:
-- Bind the predicate function to FACT_Transaccion.

USE BankingDWH;
GO

CREATE SECURITY POLICY Security.pol_transacciones
ADD FILTER PREDICATE Security.fn_predicate_transacciones(USER_NAME(), [SucursalKey])
ON dbo.FACT_Transaccion
WITH (STATE = OFF);
GO