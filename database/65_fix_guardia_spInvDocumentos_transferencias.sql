USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

DECLARE @ProcDef NVARCHAR(MAX) = OBJECT_DEFINITION(OBJECT_ID('dbo.spInvDocumentosCRUD'));

IF @ProcDef IS NULL
BEGIN
  THROW 50060, 'No existe dbo.spInvDocumentosCRUD.', 1;
END

IF @ProcDef LIKE '%THROW 50030%'
BEGIN
  PRINT 'Guardia 50030 ya existe en spInvDocumentosCRUD.';
  RETURN;
END

SET @ProcDef = REPLACE(
  @ProcDef,
  'CREATE   PROCEDURE dbo.spInvDocumentosCRUD',
  'CREATE OR ALTER PROCEDURE dbo.spInvDocumentosCRUD'
);

SET @ProcDef = REPLACE(
  @ProcDef,
  'CREATE PROCEDURE dbo.spInvDocumentosCRUD',
  'CREATE OR ALTER PROCEDURE dbo.spInvDocumentosCRUD'
);

SET @ProcDef = REPLACE(
  @ProcDef,
  'ALTER PROCEDURE dbo.spInvDocumentosCRUD',
  'CREATE OR ALTER PROCEDURE dbo.spInvDocumentosCRUD'
);

SET @ProcDef = REPLACE(
  @ProcDef,
  '      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumento;

      SET @NumDoc = CASE WHEN @Prefijo <> '''' THEN @Prefijo + ''-'' + RIGHT(''0000'' + CAST(@NuevaSecuencia AS VARCHAR), 4) ELSE RIGHT(''0000'' + CAST(@NuevaSecuencia AS VARCHAR), 4) END;',
  '      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumento;

      IF @TipoOp = ''T''
        THROW 50030, ''Las transferencias deben manejarse via spInvTransferenciasCRUD.'', 1;

      SET @NumDoc = CASE WHEN @Prefijo <> '''' THEN @Prefijo + ''-'' + RIGHT(''0000'' + CAST(@NuevaSecuencia AS VARCHAR), 4) ELSE RIGHT(''0000'' + CAST(@NuevaSecuencia AS VARCHAR), 4) END;'
);

SET @ProcDef = REPLACE(
  @ProcDef,
  '      IF @DocTipoOp IS NULL
        THROW 50010, ''Documento no encontrado o ya anulado.'', 1;

      DECLARE @NLinea INT, @NProdId INT, @NCant DECIMAL(18,4), @NCosto DECIMAL(18,4), @NTotal DECIMAL(18,4);',
  '      IF @DocTipoOp IS NULL
        THROW 50010, ''Documento no encontrado o ya anulado.'', 1;

      IF @DocTipoOp = ''T''
        THROW 50030, ''Las transferencias deben manejarse via spInvTransferenciasCRUD.'', 1;

      DECLARE @NLinea INT, @NProdId INT, @NCant DECIMAL(18,4), @NCosto DECIMAL(18,4), @NTotal DECIMAL(18,4);'
);

EXEC sys.sp_executesql @ProcDef;
GO

PRINT '65_fix_guardia_spInvDocumentos_transferencias.sql ejecutado correctamente.';
GO
