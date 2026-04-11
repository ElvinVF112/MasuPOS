-- Agregar columna Eslogan a la tabla Empresa
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Empresa' AND COLUMN_NAME = 'Eslogan')
BEGIN
    ALTER TABLE dbo.Empresa ADD Eslogan NVARCHAR(500) NULL;
END
GO

-- Actualizar el stored procedure para incluir Eslogan
-- Esto es un script de referencia; el SP se actualiza en el archivo de migración correspondiente
PRINT 'Columna Eslogan agregada exitosamente';