-- ============================================================
-- Script 41: Productos - Descripcion/Referencia/Comentario
-- - Nombre se usa como Descripcion
-- - Descripcion se usa como Referencia
-- - Comentario se agrega como texto largo
-- ============================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRY
  IF COL_LENGTH('dbo.Productos', 'Nombre') IS NOT NULL
  BEGIN
    UPDATE dbo.Productos
    SET Nombre = LEFT(ISNULL(Nombre, ''), 100)
    WHERE LEN(ISNULL(Nombre, '')) > 100;

    ALTER TABLE dbo.Productos ALTER COLUMN Nombre NVARCHAR(100) NOT NULL;
    PRINT 'Column Nombre ajustada a NVARCHAR(100)';
  END
END TRY
BEGIN CATCH
  PRINT 'No se pudo ajustar longitud de Nombre (revisar índices/constraints).';
END CATCH;
GO

BEGIN TRY
  IF COL_LENGTH('dbo.Productos', 'Descripcion') IS NOT NULL
  BEGIN
    UPDATE dbo.Productos
    SET Descripcion = LEFT(ISNULL(Descripcion, ''), 100)
    WHERE LEN(ISNULL(Descripcion, '')) > 100;

    ALTER TABLE dbo.Productos ALTER COLUMN Descripcion NVARCHAR(100) NULL;
    PRINT 'Column Descripcion ajustada a NVARCHAR(100)';
  END
END TRY
BEGIN CATCH
  PRINT 'No se pudo ajustar longitud de Descripcion (revisar índices/constraints).';
END CATCH;
GO

IF COL_LENGTH('dbo.Productos', 'Comentario') IS NULL
BEGIN
  ALTER TABLE dbo.Productos ADD Comentario NVARCHAR(MAX) NULL;
  PRINT 'Columna Comentario creada';
END
ELSE
BEGIN
  PRINT 'Columna Comentario ya existe';
END
GO

PRINT '=== Script 41 ejecutado correctamente ===';
GO
