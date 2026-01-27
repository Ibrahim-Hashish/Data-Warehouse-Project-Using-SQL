USE master;
GO

-- Checks if DataWarehouse is already created
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	
	ALTER DATABASE DataWarehouse
	-- Allows only one connection on the database
	SET SINGLE_USER
	-- Disconnects any connection on the database and rollback any actions done on it
	WITH ROLLBACK IMMEDIATE;
	-- Drops the database
	DROP DATABASE DataWarehouse;

END
GO

-- Creates the DataWarehouse
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Medallion Architecture (3 schemas: Bronze, Silver, and Gold)
-- Creates Schemas
CREATE SCHEMA Bronze;
GO
CREATE SCHEMA Silver;
GO
CREATE SCHEMA Gold;
GO

