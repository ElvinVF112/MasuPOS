SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.spInvTiposDocumentoCRUD
  @Accion                CHAR(2)        = 'L',
  @IdTipoDocumento       INT            = NULL,
  @TipoOperacion         CHAR(1)        = NULL,
  @Codigo                VARCHAR(10)    = NULL,
  @Descripcion           NVARCHAR(250)  = NULL,
  @Prefijo               VARCHAR(10)    = NULL,
  @SecuenciaInicial      INT            = 1,
  @ActualizaCosto        BIT            = 0,
  @IdMoneda              INT            = NULL,
  @IdTipoDocumentoEntrada INT           = NULL,
  @IdTipoDocumentoSalida INT            = NULL,
  @Activo                BIT            = 1,
  @UsuarioCreacion       INT            = 1,
  @UsuarioModificacion   INT            = NULL,
  @IdSesion              INT            = NULL,
  @TokenSesion           NVARCHAR(128)  = NULL,
  @UsuariosAsignados     NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion IN ('I', 'A') AND @TipoOperacion = 'T'
  BEGIN
    IF @IdTipoDocumentoEntrada IS NULL
      THROW 50083, 'El tipo de documento de entrada es obligatorio para transferencias.', 1;

    IF @IdTipoDocumentoSalida IS NULL
      THROW 50084, 'El tipo de documento de salida es obligatorio para transferencias.', 1;

    IF NOT EXISTS (
      SELECT 1
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumentoEntrada
        AND TipoOperacion = 'E'
        AND Activo = 1
        AND RowStatus = 1
    )
      THROW 50085, 'El tipo de documento de entrada configurado no es valido.', 1;

    IF NOT EXISTS (
      SELECT 1
      FROM dbo.InvTiposDocumento
      WHERE IdTipoDocumento = @IdTipoDocumentoSalida
        AND TipoOperacion = 'S'
        AND Activo = 1
        AND RowStatus = 1
    )
      THROW 50086, 'El tipo de documento de salida configurado no es valido.', 1;
  END

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
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.IdTipoDocumentoEntrada,
      te.Descripcion  AS DescripcionTipoDocumentoEntrada,
      t.IdTipoDocumentoSalida,
      ts.Descripcion  AS DescripcionTipoDocumentoSalida,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.InvTiposDocumento te ON te.IdTipoDocumento = t.IdTipoDocumentoEntrada
    LEFT JOIN dbo.InvTiposDocumento ts ON ts.IdTipoDocumento = t.IdTipoDocumentoSalida
    WHERE (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion)
      AND t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion;
    RETURN;
  END

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
      ISNULL(t.ActualizaCosto, 0) AS ActualizaCosto,
      t.IdMoneda,
      m.Nombre        AS NombreMoneda,
      m.Simbolo       AS SimboloMoneda,
      t.IdTipoDocumentoEntrada,
      te.Descripcion  AS DescripcionTipoDocumentoEntrada,
      t.IdTipoDocumentoSalida,
      ts.Descripcion  AS DescripcionTipoDocumentoSalida,
      t.Activo,
      t.FechaCreacion,
      t.UsuarioCreacion,
      t.FechaModificacion,
      t.UsuarioModificacion
    FROM dbo.InvTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.InvTiposDocumento te ON te.IdTipoDocumento = t.IdTipoDocumentoEntrada
    LEFT JOIN dbo.InvTiposDocumento ts ON ts.IdTipoDocumento = t.IdTipoDocumentoSalida
    WHERE t.IdTipoDocumento = @IdTipoDocumento
      AND t.RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    SET @Codigo = NULLIF(LTRIM(RTRIM(@Codigo)), '');
    IF @Codigo IS NULL
    BEGIN
      DECLARE @NextId INT;
      SELECT @NextId = ISNULL(MAX(IdTipoDocumento), 0) + 1
      FROM dbo.InvTiposDocumento WITH (UPDLOCK, HOLDLOCK);
      SET @Codigo = CAST(@NextId AS VARCHAR(10));
    END

    IF EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND RowStatus = 1)
      THROW 50001, 'Ya existe un tipo de documento con ese codigo.', 1;

    INSERT INTO dbo.InvTiposDocumento (
      TipoOperacion, Codigo, Descripcion, Prefijo,
      SecuenciaInicial, SecuenciaActual, ActualizaCosto, IdMoneda,
      IdTipoDocumentoEntrada, IdTipoDocumentoSalida, Activo,
      UsuarioCreacion, IdSesionCreacion
    )
    VALUES (
      @TipoOperacion, @Codigo, @Descripcion, @Prefijo,
      @SecuenciaInicial, 0,
      CASE WHEN @TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      @IdMoneda,
      CASE WHEN @TipoOperacion = 'T' THEN @IdTipoDocumentoEntrada ELSE NULL END,
      CASE WHEN @TipoOperacion = 'T' THEN @IdTipoDocumentoSalida ELSE NULL END,
      @Activo,
      @UsuarioCreacion, @IdSesion
    );

    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    SET @Codigo = NULLIF(LTRIM(RTRIM(@Codigo)), '');

    IF @Codigo IS NOT NULL
      AND EXISTS (SELECT 1 FROM dbo.InvTiposDocumento WHERE Codigo = @Codigo AND IdTipoDocumento <> @IdTipoDocumento AND RowStatus = 1)
      THROW 50002, 'Ya existe otro tipo de documento con ese codigo.', 1;

    UPDATE dbo.InvTiposDocumento
    SET
      Codigo                 = ISNULL(@Codigo, Codigo),
      Descripcion            = @Descripcion,
      Prefijo                = @Prefijo,
      SecuenciaInicial       = ISNULL(@SecuenciaInicial, SecuenciaInicial),
      ActualizaCosto         = CASE WHEN TipoOperacion IN ('E', 'C') THEN ISNULL(@ActualizaCosto, 0) ELSE 0 END,
      IdMoneda               = @IdMoneda,
      IdTipoDocumentoEntrada = CASE WHEN TipoOperacion = 'T' THEN @IdTipoDocumentoEntrada ELSE NULL END,
      IdTipoDocumentoSalida  = CASE WHEN TipoOperacion = 'T' THEN @IdTipoDocumentoSalida ELSE NULL END,
      Activo                 = ISNULL(@Activo, Activo),
      FechaModificacion      = GETDATE(),
      UsuarioModificacion    = @UsuarioModificacion,
      IdSesionModif          = @IdSesion
    WHERE IdTipoDocumento = @IdTipoDocumento
      AND RowStatus = 1;

    EXEC dbo.spInvTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento;
    RETURN;
  END

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
