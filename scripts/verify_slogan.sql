-- Script para actualizar spEmpresaCRUD con parámetro Eslogan
-- Este script agrega el parámetro @Eslogan y lo incluye en los SELECTs

-- Agregar columna Eslogan si no existe
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Empresa' AND COLUMN_NAME = 'Eslogan')
BEGIN
    ALTER TABLE dbo.Empresa ADD Eslogan NVARCHAR(500) NULL;
END
GO

-- Verificar y actualizar el SP
IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'spEmpresaCRUD')
BEGIN
    -- Agregar parámetro si no existe
    IF NOT EXISTS (
        SELECT 1 FROM sys.parameters p 
        JOIN sys.procedures s ON p.object_id = s.object_id 
        WHERE s.name = 'spEmpresaCRUD' AND p.name = '@Eslogan'
    )
    BEGIN
        PRINT 'El SP necesita ser recreado con el nuevo parámetro';
    END
    ELSE
    BEGIN
        PRINT 'El parámetro @Eslogan ya existe';
    END
END
GO

PRINT 'Verificación completada';