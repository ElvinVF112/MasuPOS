-- ============================================================
-- Eliminar columna Nombre de InvTiposDocumento
-- Descripcion pasa a ser el campo principal identificador
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- Primero hacemos Descripcion NOT NULL (ya que reemplaza a Nombre)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.InvTiposDocumento') AND name = 'Descripcion' AND is_nullable = 1)
BEGIN
  -- Rellenar NULLs existentes con el valor de Nombre antes de hacer NOT NULL
  UPDATE dbo.InvTiposDocumento SET Descripcion = Nombre WHERE Descripcion IS NULL;

  ALTER TABLE dbo.InvTiposDocumento
    ALTER COLUMN Descripcion NVARCHAR(250) NOT NULL;

  PRINT 'Columna Descripcion ahora es NOT NULL.';
END
GO

-- Eliminar columna Nombre
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.InvTiposDocumento') AND name = 'Nombre')
BEGIN
  -- Eliminar constraint UNIQUE si existe sobre Nombre
  DECLARE @constraint NVARCHAR(200)
  SELECT @constraint = dc.name
  FROM sys.default_constraints dc
  JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
  WHERE c.object_id = OBJECT_ID('dbo.InvTiposDocumento') AND c.name = 'Nombre'

  IF @constraint IS NOT NULL
    EXEC('ALTER TABLE dbo.InvTiposDocumento DROP CONSTRAINT ' + @constraint)

  ALTER TABLE dbo.InvTiposDocumento DROP COLUMN Nombre;
  PRINT 'Columna Nombre eliminada de InvTiposDocumento.';
END
GO

-- Actualizar SP para no usar Nombre
IF OBJECT_ID('dbo.spInvTiposDocumentoCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spInvTiposDocumentoCRUD;
GO

CREATE PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion              CHAR(2)        = 'L',
  @IdTipoDocumento     INT            = NULL,
  @TipoOperacion       CHAR(1)        = NULL,
  @Codigo              VARCHAR(10)    = NULL,
  @Nombre              NVARCHAR(80)   = NULL,   -- mantenido por compatibilidad, se ignora
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

  -- L: Listar todos (opcional filtrar por TipoOperacion)
  IF @Accion = 'L'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
      AND t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion;
    RETURN;
  END

  -- O: Obtener uno por ID
  IF @Accion = 'O'
  BEGIN
    SELECT
      t.IdTipoDocumento,
      t.TipoOperacion,
      t.Codigo,
      t.Descripcion,
      t.Prefijo,
      t.SecuenciaInicial,
      t.SecuenciaActual,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    WHERE t.IdTipoDocumento = @IdTipoDocumento
      AND t.RowStatus = 1;
    RETURN;
  END

  -- I: Insertar
  IF @Accion = 'I'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND RowStatus = 1)
      THROW 50001, 'Ya existe un tipo de documento con ese codigo.', 1;

    INSERT INTO dbo.InvTiposDocumento (
      TipoOperacion, Codigo, Descripcion, Prefijo,
      SecuenciaInicial, SecuenciaActual, IdMoneda, Activo,
      UsuarioCreacion, IdSesionCreacion
    )
    VALUES (
      @TipoOperacion, @Codigo, @Descripcion, @Prefijo,
      @SecuenciaInicial, 0, @IdMoneda, @Activo,
      @UsuarioCreacion, @IdSesion
    );

    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId;
    RETURN;
  END

  -- A: Actualizar
  IF @Accion = 'A'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND IdTipoDocumento <> @IdTipoDocumento AND RowStatus = 1)
      THROW 50002, 'Ya existe otro tipo de documento con ese codigo.', 1;

    UPDATE dbo.InvTiposDocumento SET
      Codigo              = ISNULL(@Codigo, Codigo),
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

  -- D: Eliminar (soft delete)
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.InvTiposDocumento SET
      RowStatus           = 0,
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion,
      IdSesionModif       = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

  -- LU: Listar usuarios asignados
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
    UPDATE dbo.InvTipoDocUsuario SET
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoDocumento = @IdTipoDocumento;

    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      INSERT INTO dbo.InvTipoDocUsuario (IdTipoDocumento, IdUsuario, UsuarioCreacion)
      SELECT @IdTipoDocumento, value, @UsuarioCreacion
      FROM STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE TRY_CAST(value AS INT) IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM dbo.InvTipoDocUsuario
          WHERE IdTipoDocumento = @IdTipoDocumento AND IdUsuario = TRY_CAST(value AS INT)
        );

      UPDATE dbo.InvTipoDocUsuario SET
        Activo              = 1,
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
      WHERE IdTipoDocumento = @IdTipoDocumento
        AND IdUsuario IN (
          SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@UsuariosAsignados, ',')
          WHERE TRY_CAST(value AS INT) IS NOT NULL
        );
    END

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'LU', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

END
GO

PRINT 'Script 49_inv_drop_nombre.sql ejecutado correctamente.';
GO
