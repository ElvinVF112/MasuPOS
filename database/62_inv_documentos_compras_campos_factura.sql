USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- TAREA 48: Campos de Compras en documentos de inventario
-- Idempotente: puede ejecutarse multiples veces.

IF NOT EXISTS (
  SELECT 1
  FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.InvDocumentos')
    AND name = 'IdProveedor'
)
BEGIN
  ALTER TABLE dbo.InvDocumentos ADD IdProveedor INT NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.InvDocumentos')
    AND name = 'NoFactura'
)
BEGIN
  ALTER TABLE dbo.InvDocumentos ADD NoFactura NVARCHAR(50) NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.InvDocumentos')
    AND name = 'NCF'
)
BEGIN
  ALTER TABLE dbo.InvDocumentos ADD NCF NVARCHAR(50) NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.InvDocumentos')
    AND name = 'FechaFactura'
)
BEGIN
  ALTER TABLE dbo.InvDocumentos ADD FechaFactura DATE NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.foreign_keys
  WHERE name = 'FK_InvDocumentos_Proveedor'
)
BEGIN
  ALTER TABLE dbo.InvDocumentos
    ADD CONSTRAINT FK_InvDocumentos_Proveedor
    FOREIGN KEY (IdProveedor)
    REFERENCES dbo.Terceros(IdTercero);
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE object_id = OBJECT_ID('dbo.InvDocumentos')
    AND name = 'IX_InvDocumentos_Proveedor_FechaFactura'
)
BEGIN
  CREATE INDEX IX_InvDocumentos_Proveedor_FechaFactura
    ON dbo.InvDocumentos (IdProveedor, FechaFactura)
    INCLUDE (NoFactura, NCF, TipoOperacion, NumeroDocumento, Fecha, Estado);
END
GO

PRINT 'Script 62_inv_documentos_compras_campos_factura.sql ejecutado correctamente.';
GO
