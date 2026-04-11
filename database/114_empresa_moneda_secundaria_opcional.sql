USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

PRINT '=== Script 114: moneda secundaria opcional ===';
GO

IF OBJECT_ID('DF_Empresa_MonedaSecundaria', 'D') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Empresa DROP CONSTRAINT DF_Empresa_MonedaSecundaria;
END
GO

IF COL_LENGTH('dbo.Empresa', 'MonedaSecundaria') IS NULL
BEGIN
    ALTER TABLE dbo.Empresa ADD MonedaSecundaria NVARCHAR(10) NULL;
END
GO

-- Dejar el valor existente si el usuario ya configuro una moneda secundaria.
-- Si se desea ocultar el total secundario en POS, guardar Empresa con Moneda Secundaria vacia.
