USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- Permitir historico por linea (RowStatus=0) y unicidad solo en activos (RowStatus=1)

IF EXISTS (
  SELECT 1
  FROM sys.key_constraints
  WHERE [type] = 'UQ'
    AND [name] = 'UQ_InvDocDetalle_Linea'
    AND parent_object_id = OBJECT_ID('dbo.InvDocumentoDetalle')
)
BEGIN
  ALTER TABLE dbo.InvDocumentoDetalle DROP CONSTRAINT UQ_InvDocDetalle_Linea;
  PRINT 'Constraint UQ_InvDocDetalle_Linea eliminado.';
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE [name] = 'UQ_InvDocDetalle_Linea_Activos'
    AND object_id = OBJECT_ID('dbo.InvDocumentoDetalle')
)
BEGIN
  CREATE UNIQUE INDEX UQ_InvDocDetalle_Linea_Activos
    ON dbo.InvDocumentoDetalle (IdDocumento, NumeroLinea)
    WHERE RowStatus = 1;
  PRINT 'Indice unico filtrado UQ_InvDocDetalle_Linea_Activos creado.';
END
GO

PRINT 'Ajuste de unicidad para soft delete de detalle aplicado correctamente.';
GO
