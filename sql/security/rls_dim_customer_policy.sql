USE BankingDWH;
GO

CREATE SECURITY POLICY Security.pol_customer
ADD FILTER PREDICATE Security.fn_predicate_customer(USER_NAME(), [CustomerKey])
ON dbo.DIM_Customer
WITH (STATE = OFF);
GO