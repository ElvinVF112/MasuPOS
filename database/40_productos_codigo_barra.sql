-- ============================================================
-- Script 40: Productos - columna Codigo / Barra
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Productos', 'Codigo') IS NULL
BEGIN
  ALTER TABLE dbo.Productos ADD Codigo NVARCHAR(60) NULL;
  PRINT 'Columna dbo.Productos.Codigo creada';
END
ELSE
BEGIN
  PRINT 'Columna dbo.Productos.Codigo ya existe';
END
GO

-- Índice para búsqueda rápida por código/barra
IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE object_id = OBJECT_ID('dbo.Productos')
    AND name = 'IX_Productos_Codigo'
)
BEGIN
  CREATE NONCLUSTERED INDEX IX_Productos_Codigo
    ON dbo.Productos (Codigo)
    INCLUDE (IdProducto, Nombre, Descripcion, Activo)
    WHERE RowStatus = 1;
  PRINT 'Indice IX_Productos_Codigo creado';
END
ELSE
BEGIN
  PRINT 'Indice IX_Productos_Codigo ya existe';
END
GO

PRINT '=== Script 40 ejecutado correctamente ===';
GO
