-- ============================================================
-- Script: 125_inv_tipos_doc_actualiza_costo.sql
-- Propósito: Activar ActualizaCosto en tipos de documento que
--            corresponde (Entradas). Agregar campo al CRUD de
--            tipos de documento para ser configurable en UI.
-- ============================================================

USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Activar ActualizaCosto en Entradas
UPDATE dbo.InvTiposDocumento
SET ActualizaCosto = 1
WHERE TipoOperacion = 'E' AND RowStatus = 1;

PRINT 'ActualizaCosto activado en tipos de operacion E (Entradas).';
GO

-- 2. Actualizar spInvTiposDocumentoCRUD para incluir ActualizaCosto
CREATE OR ALTER PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion            CHAR(1)        = 'L',
  @IdTipoDocumento   INT            = NULL,
  @Descripcion       NVARCHAR(200)  = NULL,
  @Prefijo           VARCHAR(10)    = NULL,
  @TipoOperacion     CHAR(1)        = NULL,
  @ActualizaCosto    BIT            = NULL,
  @Activo            BIT            = NULL,
  @IdSesion          INT            = NULL,
  @TokenSesion       NVARCHAR(100)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT
      IdTipoDocumento,
      Descripcion,
      Prefijo,
      TipoOperacion,
      ISNULL(ActualizaCosto, 0) AS ActualizaCosto,
      ISNULL(Activo, 1) AS Activo,
      SecuenciaActual
    FROM dbo.InvTiposDocumento
    WHERE RowStatus = 1
    ORDER BY TipoOperacion, Descripcion;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      IdTipoDocumento,
      Descripcion,
      Prefijo,
      TipoOperacion,
      ISNULL(ActualizaCosto, 0) AS ActualizaCosto,
      ISNULL(Activo, 1) AS Activo,
      SecuenciaActual
    FROM dbo.InvTiposDocumento
    WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    IF @TipoOperacion NOT IN ('E', 'S', 'C', 'T')
    BEGIN
      DECLARE @ErrTipo NVARCHAR(200) = 'TipoOperacion invalido. Valores validos: E, S, C, T.';
      THROW 50060, @ErrTipo, 1;
    END

    DECLARE @NewId INT;
    INSERT INTO dbo.InvTiposDocumento (Descripcion, Prefijo, TipoOperacion, ActualizaCosto, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (LTRIM(RTRIM(@Descripcion)), LTRIM(RTRIM(ISNULL(@Prefijo, ''))), @TipoOperacion, ISNULL(@ActualizaCosto, 0), ISNULL(@Activo, 1), 1, GETDATE(), @IdSesion);
    SET @NewId = SCOPE_IDENTITY();

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId;
    RETURN;
  END

  IF @Accion = 'U'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1)
    BEGIN
      DECLARE @ErrU NVARCHAR(200) = 'Tipo de documento no encontrado.';
      THROW 50061, @ErrU, 1;
    END

    UPDATE dbo.InvTiposDocumento
    SET Descripcion    = ISNULL(@Descripcion, Descripcion),
        Prefijo        = ISNULL(@Prefijo, Prefijo),
        ActualizaCosto = ISNULL(@ActualizaCosto, ActualizaCosto),
        Activo         = ISNULL(@Activo, Activo),
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1;

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1)
    BEGIN
      DECLARE @ErrD NVARCHAR(200) = 'Tipo de documento no encontrado.';
      THROW 50061, @ErrD, 1;
    END

    IF EXISTS (SELECT 1 FROM dbo.InvDocumentos WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1)
    BEGIN
      DECLARE @ErrDel NVARCHAR(200) = 'No se puede eliminar un tipo con documentos registrados.';
      THROW 50062, @ErrDel, 1;
    END

    UPDATE dbo.InvTiposDocumento
    SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  DECLARE @ErrAcc NVARCHAR(200) = 'Accion no valida.';
  THROW 50063, @ErrAcc, 1;
END;
GO

PRINT 'Script 125_inv_tipos_doc_actualiza_costo.sql ejecutado.';
GO
