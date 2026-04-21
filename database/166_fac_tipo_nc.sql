-- ============================================================
-- Script 166: Agregar TipoOperacion 'N' (Nota Crédito/Débito)
-- y sembrar tipo de documento NC si no existe
-- ============================================================

-- 1. Ampliar el CHECK constraint para incluir 'N'
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_FacTiposDocumento_TipoOp')
BEGIN
  ALTER TABLE dbo.FacTiposDocumento DROP CONSTRAINT CK_FacTiposDocumento_TipoOp
  ALTER TABLE dbo.FacTiposDocumento
    ADD CONSTRAINT CK_FacTiposDocumento_TipoOp
    CHECK (TipoOperacion IN ('F','Q','K','P','N'))
  PRINT 'CHECK constraint CK_FacTiposDocumento_TipoOp actualizado con N'
END
GO

-- 2. Actualizar tipo FacTipoOperacion en SP (no requiere cambio de SP, solo dato)

-- 3. Sembrar tipo NC si no existe
IF NOT EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE Codigo = 'NC' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.FacTiposDocumento (
    TipoOperacion, Codigo, Descripcion, Prefijo,
    SecuenciaInicial, SecuenciaActual,
    AplicaPropina, Activo, RowStatus, FechaCreacion
  ) VALUES (
    'N', 'NC', 'Nota de Crédito', 'NC',
    1, 0,
    0, 1, 1, GETDATE()
  )
  PRINT 'SEED: Tipo Nota de Crédito (NC) insertado'
END
ELSE
BEGIN
  PRINT 'SEED: Tipo NC ya existe, omitido'
END
GO
