-- ============================================================
-- Script 173: Completar limpieza de columnas FacDocumentos
-- Continuacion de script 172:
--   - Drop IX_FacDocumentos_PuntoEmision_Fecha (bloqueaba columnas)
--   - Drop TipoDocumentoCodigo y Anulado que quedaron
--   - Recrear indice sin columnas eliminadas
--   - Poblar DocumentoSecuencia (requiere QUOTED_IDENTIFIER ON)
--   - Crear indice IX_FacDocumentos_DocumentoSecuencia
-- ============================================================

-- ── 1. Drop indice que bloqueaba las columnas ────────────────
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_PuntoEmision_Fecha' AND object_id = OBJECT_ID('dbo.FacDocumentos'))
    DROP INDEX IX_FacDocumentos_PuntoEmision_Fecha ON dbo.FacDocumentos;
GO

-- ── 2. Drop TipoDocumentoCodigo ──────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'TipoDocumentoCodigo')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN TipoDocumentoCodigo;
GO

-- ── 3. Drop Anulado ──────────────────────────────────────────
DECLARE @df NVARCHAR(200);
SELECT @df = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE dc.parent_object_id = OBJECT_ID('dbo.FacDocumentos') AND c.name = 'Anulado';
IF @df IS NOT NULL EXEC('ALTER TABLE dbo.FacDocumentos DROP CONSTRAINT [' + @df + ']');
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'Anulado')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN Anulado;
GO

-- ── 4. Recrear indice sin columnas eliminadas ────────────────
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_PuntoEmision_Fecha' AND object_id = OBJECT_ID('dbo.FacDocumentos'))
    CREATE INDEX IX_FacDocumentos_PuntoEmision_Fecha
        ON dbo.FacDocumentos (IdPuntoEmision, FechaDocumento, Estado, Total)
        WHERE RowStatus = 1;
GO

-- ── 5. Poblar DocumentoSecuencia ────────────────────────────
SET QUOTED_IDENTIFIER ON;
GO
UPDATE d SET d.DocumentoSecuencia =
    t.Prefijo + '-' + RIGHT('0000000' + CAST(d.Secuencia AS VARCHAR(10)), 7)
FROM dbo.FacDocumentos d
JOIN dbo.FacTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
WHERE d.DocumentoSecuencia IS NULL;
GO

-- ── 6. Crear indice DocumentoSecuencia ──────────────────────
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_DocumentoSecuencia' AND object_id = OBJECT_ID('dbo.FacDocumentos'))
    CREATE INDEX IX_FacDocumentos_DocumentoSecuencia
        ON dbo.FacDocumentos (DocumentoSecuencia)
        WHERE RowStatus = 1;
GO

-- Verificacion final
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FacDocumentos' ORDER BY ORDINAL_POSITION;
SELECT name AS Indice FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.FacDocumentos') ORDER BY name;
PRINT 'Script 173 aplicado correctamente.';
GO
