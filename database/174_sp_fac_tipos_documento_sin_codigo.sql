-- ============================================================
-- Script 174: Recrear spFacTiposDocumentoCRUD sin columna Codigo
-- Codigo fue eliminado en script 172 — Prefijo es el identificador
-- ============================================================

IF OBJECT_ID('dbo.spFacTiposDocumentoCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spFacTiposDocumentoCRUD;
GO

CREATE PROCEDURE dbo.spFacTiposDocumentoCRUD
  @Accion              CHAR(2)        = 'L',
  @IdTipoDocumento     INT            = NULL,
  @TipoOperacion       CHAR(1)        = NULL,
  @Descripcion         NVARCHAR(250)  = NULL,
  @Prefijo             VARCHAR(10)    = NULL,
  @SecuenciaInicial    INT            = 1,
  @IdMoneda            INT            = NULL,
  @AplicaPropina       BIT            = 0,
  @IdCatalogoNCF       INT            = NULL,
  @AfectaInventario    BIT            = NULL,
  @ReservaStock        BIT            = NULL,
  @GeneraFactura       BIT            = NULL,
  @Activo              BIT            = 1,
  @UsuarioAccion       INT            = NULL,
  @UsuariosAsignados   NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT t.IdTipoDocumento, t.TipoOperacion, t.Descripcion,
           t.Prefijo, t.SecuenciaInicial, t.SecuenciaActual,
           t.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           t.AplicaPropina,
           t.IdCatalogoNCF, c.Codigo AS CodigoNCF, ISNULL(c.NombreInterno, c.Nombre) AS NombreNCF,
           t.AfectaInventario, t.ReservaStock, t.GeneraFactura,
           t.Activo,
           t.FechaCreacion, t.UsuarioCreacion, t.FechaModificacion, t.UsuarioModificacion
    FROM   dbo.FacTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.CatalogoNCF c ON c.IdCatalogoNCF = t.IdCatalogoNCF
    WHERE  (@TipoOperacion IS NULL OR t.TipoOperacion = @TipoOperacion) AND t.RowStatus = 1
    ORDER BY t.TipoOperacion, t.Descripcion
    RETURN
  END

  IF @Accion = 'O'
  BEGIN
    SELECT t.IdTipoDocumento, t.TipoOperacion, t.Descripcion,
           t.Prefijo, t.SecuenciaInicial, t.SecuenciaActual,
           t.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           t.AplicaPropina,
           t.IdCatalogoNCF, c.Codigo AS CodigoNCF, ISNULL(c.NombreInterno, c.Nombre) AS NombreNCF,
           t.AfectaInventario, t.ReservaStock, t.GeneraFactura,
           t.Activo,
           t.FechaCreacion, t.UsuarioCreacion, t.FechaModificacion, t.UsuarioModificacion
    FROM   dbo.FacTiposDocumento t
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = t.IdMoneda
    LEFT JOIN dbo.CatalogoNCF c ON c.IdCatalogoNCF = t.IdCatalogoNCF
    WHERE  t.IdTipoDocumento = @IdTipoDocumento AND t.RowStatus = 1
    RETURN
  END

  IF @Accion = 'I'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.FacTiposDocumento WHERE Prefijo = @Prefijo AND RowStatus = 1)
      THROW 50030, 'Ya existe un tipo de documento con ese prefijo.', 1

    INSERT INTO dbo.FacTiposDocumento (
      TipoOperacion, Descripcion, Prefijo, SecuenciaInicial, SecuenciaActual,
      IdMoneda, AplicaPropina, IdCatalogoNCF,
      AfectaInventario, ReservaStock, GeneraFactura,
      Activo, UsuarioCreacion
    ) VALUES (
      @TipoOperacion, @Descripcion, @Prefijo, @SecuenciaInicial, 0,
      @IdMoneda, ISNULL(@AplicaPropina, 0), @IdCatalogoNCF,
      ISNULL(@AfectaInventario, 0), ISNULL(@ReservaStock, 0), ISNULL(@GeneraFactura, 0),
      ISNULL(@Activo, 1), @UsuarioAccion
    )
    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @NewId
    RETURN
  END

  IF @Accion = 'A'
  BEGIN
    IF @Prefijo IS NOT NULL AND EXISTS (
        SELECT 1 FROM dbo.FacTiposDocumento
        WHERE Prefijo = @Prefijo AND IdTipoDocumento <> @IdTipoDocumento AND RowStatus = 1)
      THROW 50031, 'Ya existe otro tipo de documento con ese prefijo.', 1

    UPDATE dbo.FacTiposDocumento
    SET    Descripcion         = ISNULL(@Descripcion, Descripcion),
           Prefijo             = ISNULL(@Prefijo, Prefijo),
           SecuenciaInicial    = ISNULL(@SecuenciaInicial, SecuenciaInicial),
           IdMoneda            = @IdMoneda,
           AplicaPropina       = ISNULL(@AplicaPropina, AplicaPropina),
           IdCatalogoNCF       = @IdCatalogoNCF,
           AfectaInventario    = ISNULL(@AfectaInventario, AfectaInventario),
           ReservaStock        = ISNULL(@ReservaStock, ReservaStock),
           GeneraFactura       = ISNULL(@GeneraFactura, GeneraFactura),
           Activo              = ISNULL(@Activo, Activo),
           FechaModificacion   = GETDATE(),
           UsuarioModificacion = @UsuarioAccion
    WHERE  IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1
    EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'O', @IdTipoDocumento = @IdTipoDocumento
    RETURN
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacTiposDocumento
    SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE IdTipoDocumento = @IdTipoDocumento
    RETURN
  END

  IF @Accion = 'LU'
  BEGIN
    SELECT u.IdUsuario, u.NombreUsuario, u.Nombres, u.Correo,
           CASE WHEN tdu.IdTipoDocUsuario IS NOT NULL THEN 1 ELSE 0 END AS Asignado
    FROM   dbo.Usuarios u
    LEFT JOIN dbo.FacTipoDocUsuario tdu ON tdu.IdUsuario = u.IdUsuario AND tdu.IdTipoDocumento = @IdTipoDocumento AND tdu.Activo = 1
    WHERE  u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres
    RETURN
  END

  IF @Accion = 'U'
  BEGIN
    UPDATE dbo.FacTipoDocUsuario
    SET Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
    WHERE IdTipoDocumento = @IdTipoDocumento

    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      INSERT INTO dbo.FacTipoDocUsuario (IdTipoDocumento, IdUsuario, UsuarioCreacion)
      SELECT @IdTipoDocumento, TRY_CAST(value AS INT), ISNULL(@UsuarioAccion, 1)
      FROM STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE TRY_CAST(value AS INT) IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM dbo.FacTipoDocUsuario
            WHERE IdTipoDocumento = @IdTipoDocumento AND IdUsuario = TRY_CAST(value AS INT))

      UPDATE dbo.FacTipoDocUsuario
      SET Activo = 1, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion
      WHERE IdTipoDocumento = @IdTipoDocumento
        AND IdUsuario IN (
            SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@UsuariosAsignados, ',')
            WHERE TRY_CAST(value AS INT) IS NOT NULL)
    END
    EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'LU', @IdTipoDocumento = @IdTipoDocumento
    RETURN
  END
END
GO

-- Verificacion
EXEC dbo.spFacTiposDocumentoCRUD @Accion = 'L';
GO
