-- ============================================================
-- Recrear spInvTiposDocumentoCRUD — version definitiva
-- Corrige posibles errores de columnas en accion LU
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.spInvTiposDocumentoCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spInvTiposDocumentoCRUD;
GO

CREATE PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion              CHAR(2)        = 'L',
  @IdTipoDocumento     INT            = NULL,
  @TipoOperacion       CHAR(1)        = NULL,
  @Codigo              VARCHAR(10)    = NULL,
  @Descripcion         NVARCHAR(250)  = NULL,
  @Prefijo             VARCHAR(10)    = NULL,
  @SecuenciaInicial    INT            = 1,
  @IdMoneda            INT            = NULL,
  @Activo              BIT            = 1,
  @UsuarioCreacion     INT            = 1,
  @UsuarioModificacion INT            = NULL,
  @IdSesion            INT            = NULL,
  @TokenSesion         NVARCHAR(128)  = NULL,
  @UsuariosAsignados   NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: Listar
  IF @Accion = 'L'
  BEGIN
    SELECT
      t.IdTipoDocumento, t.TipoOperacion, t.Codigo, t.Descripcion,
      t.Prefijo, t.SecuenciaInicial, t.SecuenciaActual, t.IdMoneda,
      m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
      t.Activo, t.FechaCreacion, t.UsuarioCreacion, t.FechaModificacion, t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
      AND t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion;
    RETURN;
  END

  -- O: Obtener uno
  IF @Accion = 'O'
  BEGIN
    SELECT
      t.IdTipoDocumento, t.TipoOperacion, t.Codigo, t.Descripcion,
      t.Prefijo, t.SecuenciaInicial, t.SecuenciaActual, t.IdMoneda,
      m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
      t.Activo, t.FechaCreacion, t.UsuarioCreacion, t.FechaModificacion, t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE t.IdTipoDocumento = @IdTipoDocumento AND t.RowStatus = 1;
    RETURN;
  END

  -- I: Insertar — genera Codigo automaticamente desde SCOPE_IDENTITY si no se envia
  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.InvTiposDocumento (
      TipoOperacion, Codigo, Descripcion, Prefijo,
      SecuenciaInicial, SecuenciaActual, IdMoneda, Activo,
      UsuarioCreacion, IdSesionCreacion
    )
    VALUES (
      @TipoOperacion, ISNULL(@Codigo, ''), @Descripcion, @Prefijo,
      @SecuenciaInicial, 0, @IdMoneda, @Activo,
      @UsuarioCreacion, @IdSesion
    );

    DECLARE @NewId INT = SCOPE_IDENTITY();

    -- Si no se envio Codigo, usar el Id formateado
    IF @Codigo IS NULL OR @Codigo = ''
    BEGIN
      UPDATE dbo.InvTiposDocumento
        SET Codigo = CAST(@NewId AS VARCHAR(10))
      WHERE IdTipoDocumento = @NewId;
    END

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId;
    RETURN;
  END

  -- A: Actualizar — Codigo no editable
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.InvTiposDocumento SET
      Descripcion         = ISNULL(@Descripcion, Descripcion),
      Prefijo             = @Prefijo,
      SecuenciaInicial    = ISNULL(@SecuenciaInicial, SecuenciaInicial),
      IdMoneda            = @IdMoneda,
      Activo              = ISNULL(@Activo, Activo),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif       = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1;

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  -- D: Eliminar (soft)
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.InvTiposDocumento SET
      RowStatus = 0, Activo = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  -- LU: Listar todos los usuarios con flag de asignacion
  IF @Accion = 'LU'
  BEGIN
    SELECT
      u.IdUsuario,
      u.NombreUsuario,
      u.Nombres,
      u.Correo,
      CASE WHEN tdu.IdTipoDocUsuario IS NOT NULL THEN 1 ELSE 0 END AS Asignado
    FROM dbo.Usuarios u
    LEFT JOIN dbo.InvTipoDocUsuario tdu
      ON tdu.IdUsuario = u.IdUsuario
      AND tdu.IdTipoDocumento = @IdTipoDocumento
      AND tdu.Activo = 1
    WHERE u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres;
    RETURN;
  END

  -- U: Sincronizar usuarios asignados
  IF @Accion = 'U'
  BEGIN
    -- Desactivar todos los actuales
    UPDATE dbo.InvTipoDocUsuario SET
      Activo = 0, FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoDocumento = @IdTipoDocumento;

    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      -- Insertar los que no existen
      INSERT INTO dbo.InvTipoDocUsuario (IdTipoDocumento, IdUsuario, UsuarioCreacion)
      SELECT @IdTipoDocumento, TRY_CAST(value AS INT), @UsuarioCreacion
      FROM STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE TRY_CAST(value AS INT) IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM dbo.InvTipoDocUsuario
          WHERE IdTipoDocumento = @IdTipoDocumento
            AND IdUsuario = TRY_CAST(value AS INT)
        );

      -- Reactivar los que ya existian
      UPDATE dbo.InvTipoDocUsuario SET
        Activo = 1, FechaModificacion = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
      WHERE IdTipoDocumento = @IdTipoDocumento
        AND IdUsuario IN (
          SELECT TRY_CAST(value AS INT)
          FROM STRING_SPLIT(@UsuariosAsignados, ',')
          WHERE TRY_CAST(value AS INT) IS NOT NULL
        );
    END

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'LU', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END
END
GO

PRINT 'Script 51_inv_sp_recreate_fix.sql ejecutado correctamente.';
GO
