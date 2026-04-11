-- ============================================================
-- Script 42: Productos - Codigo/Barra unico
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Productos', 'Codigo') IS NULL
BEGIN
  ALTER TABLE dbo.Productos ADD Codigo NVARCHAR(60) NULL;
  PRINT 'Columna Codigo creada';
END
GO

-- Limpieza simple de espacios
UPDATE dbo.Productos
SET Codigo = NULLIF(LTRIM(RTRIM(Codigo)), '')
WHERE Codigo IS NOT NULL;
GO

IF EXISTS (
  SELECT Codigo
  FROM dbo.Productos
  WHERE RowStatus = 1
    AND Codigo IS NOT NULL
  GROUP BY Codigo
  HAVING COUNT(*) > 1
)
BEGIN
  THROW 51002, 'Existen codigos duplicados en Productos. Corrige duplicados antes de crear indice unico.', 1;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.indexes
  WHERE object_id = OBJECT_ID('dbo.Productos')
    AND name = 'UX_Productos_Codigo_Activo'
)
BEGIN
  CREATE UNIQUE NONCLUSTERED INDEX UX_Productos_Codigo_Activo
    ON dbo.Productos(Codigo)
    WHERE RowStatus = 1 AND Codigo IS NOT NULL;

  PRINT 'Indice unico UX_Productos_Codigo_Activo creado';
END
ELSE
BEGIN
  PRINT 'Indice unico UX_Productos_Codigo_Activo ya existe';
END
GO

PRINT '=== Script 42 ejecutado correctamente ===';
GO
