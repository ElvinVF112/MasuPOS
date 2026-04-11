-- ============================================================
-- Script 136: Usuarios — Datos Administrativos
-- Agrega estructura administrativa y nivel de acceso a datos
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Columnas nuevas en Usuarios
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Usuarios' AND COLUMN_NAME = 'IdDivision')
  ALTER TABLE dbo.Usuarios ADD IdDivision INT NULL CONSTRAINT FK_Usuarios_Division FOREIGN KEY REFERENCES dbo.Divisiones(IdDivision);

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Usuarios' AND COLUMN_NAME = 'IdSucursal')
  ALTER TABLE dbo.Usuarios ADD IdSucursal INT NULL CONSTRAINT FK_Usuarios_Sucursal FOREIGN KEY REFERENCES dbo.Sucursales(IdSucursal);

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Usuarios' AND COLUMN_NAME = 'IdPuntoEmision')
  ALTER TABLE dbo.Usuarios ADD IdPuntoEmision INT NULL CONSTRAINT FK_Usuarios_PuntoEmision FOREIGN KEY REFERENCES dbo.PuntosEmision(IdPuntoEmision);

-- NivelAcceso: G=Global, E=Empresa, D=Division, S=Sucursal, P=Punto Emision, U=Usuario
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Usuarios' AND COLUMN_NAME = 'NivelAcceso')
  ALTER TABLE dbo.Usuarios ADD NivelAcceso CHAR(1) NOT NULL DEFAULT 'G' CONSTRAINT CK_Usuarios_NivelAcceso CHECK (NivelAcceso IN ('G','E','D','S','P','U'));
GO

PRINT '=== Script 136 completado ==='
GO
