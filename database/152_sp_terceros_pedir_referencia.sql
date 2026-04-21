-- ============================================================
-- 152_sp_terceros_pedir_referencia.sql
-- Agrega PedirReferencia a spTercerosCRUD (param, SELECT L/O, INSERT I, UPDATE A)
-- Requiere: 151_fac_documentos_pos.sql ya aplicado (columna Terceros.PedirReferencia)
-- ============================================================

IF OBJECT_ID('dbo.spTercerosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spTercerosCRUD;
GO

CREATE PROCEDURE dbo.spTercerosCRUD
  @Accion                    CHAR(1)         = 'L',
  @IdTercero                 INT             = NULL,
  @Codigo                    VARCHAR(20)     = NULL,
  @Nombre                    NVARCHAR(150)   = NULL,
  @NombreCorto               NVARCHAR(50)    = NULL,
  @TipoPersona               CHAR(1)         = NULL,
  @IdTipoDocIdentificacion   INT             = NULL,
  @DocumentoIdentificacion   VARCHAR(30)     = NULL,
  @EsCliente                 BIT             = NULL,
  @IdTipoCliente             INT             = NULL,
  @IdCategoriaCliente        INT             = NULL,
  @EsProveedor               BIT             = NULL,
  @IdTipoProveedor           INT             = NULL,
  @IdCategoriaProveedor      INT             = NULL,
  @Direccion                 NVARCHAR(300)   = NULL,
  @Ciudad                    NVARCHAR(100)   = NULL,
  @Telefono                  VARCHAR(30)     = NULL,
  @Celular                   VARCHAR(30)     = NULL,
  @Email                     NVARCHAR(150)   = NULL,
  @Web                       NVARCHAR(200)   = NULL,
  @Contacto                  NVARCHAR(100)   = NULL,
  @TelefonoContacto          VARCHAR(30)     = NULL,
  @EmailContacto             NVARCHAR(150)   = NULL,
  @IdListaPrecio             INT             = NULL,
  @LimiteCredito             DECIMAL(18,2)   = NULL,
  @DiasCredito               INT             = NULL,
  @IdDocumentoVenta          INT             = NULL,
  @IdTipoComprobante         INT             = NULL,
  @IdDescuento               INT             = NULL,
  @PedirReferencia           BIT             = NULL,
  @Notas                     NVARCHAR(MAX)   = NULL,
  @Activo                    BIT             = NULL,
  @UsuarioCreacion           INT             = 1,
  @UsuarioModificacion       INT             = 1,
  @IdSesion                  INT             = NULL,
  @TokenSesion               NVARCHAR(128)   = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT
      t.IdTercero,
      t.Codigo,
      t.Nombre,
      t.NombreCorto,
      t.TipoPersona,
      t.IdTipoDocIdentificacion,
      di.Codigo       AS CodigoDocIdent,
      di.Nombre       AS NombreDocIdent,
      di.LongitudMin  AS DocLongitudMin,
      di.LongitudMax  AS DocLongitudMax,
      t.DocumentoIdentificacion,
      t.EsCliente,
      t.IdTipoCliente,
      tc.Codigo       AS CodigoTipoCliente,
      tc.Nombre       AS NombreTipoCliente,
      t.IdCategoriaCliente,
      cc.Codigo       AS CodigoCategoriaCliente,
      cc.Nombre       AS NombreCategoriaCliente,
      t.EsProveedor,
      t.IdTipoProveedor,
      t.IdCategoriaProveedor,
      t.Direccion,
      t.Ciudad,
      t.Telefono,
      t.Celular,
      t.Email,
      t.Web,
      t.Contacto,
      t.TelefonoContacto,
      t.EmailContacto,
      t.IdListaPrecio,
      lp.Descripcion  AS NombreListaPrecio,
      t.LimiteCredito,
      t.DiasCredito,
      t.IdDocumentoVenta,
      t.IdTipoComprobante,
      t.IdDescuento,
      t.PedirReferencia,
      t.Notas,
      t.Activo,
      t.FechaCreacion,
      t.FechaModificacion
    FROM dbo.Terceros t
    LEFT JOIN dbo.DocumentosIdentificacion di ON di.IdDocumentoIdentificacion = t.IdTipoDocIdentificacion
    LEFT JOIN dbo.TiposCliente tc ON tc.IdTipoCliente = t.IdTipoCliente
    LEFT JOIN dbo.CategoriasCliente cc ON cc.IdCategoriaCliente = t.IdCategoriaCliente
    LEFT JOIN dbo.ListasPrecios lp ON lp.IdListaPrecio = t.IdListaPrecio
    WHERE t.RowStatus = 1
      AND (@EsCliente IS NULL OR t.EsCliente = @EsCliente)
      AND (@EsProveedor IS NULL OR t.EsProveedor = @EsProveedor)
    ORDER BY t.Nombre;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      t.IdTercero,
      t.Codigo,
      t.Nombre,
      t.NombreCorto,
      t.TipoPersona,
      t.IdTipoDocIdentificacion,
      di.Codigo       AS CodigoDocIdent,
      di.Nombre       AS NombreDocIdent,
      di.LongitudMin  AS DocLongitudMin,
      di.LongitudMax  AS DocLongitudMax,
      t.DocumentoIdentificacion,
      t.EsCliente,
      t.IdTipoCliente,
      tc.Codigo       AS CodigoTipoCliente,
      tc.Nombre       AS NombreTipoCliente,
      t.IdCategoriaCliente,
      cc.Codigo       AS CodigoCategoriaCliente,
      cc.Nombre       AS NombreCategoriaCliente,
      t.EsProveedor,
      t.IdTipoProveedor,
      t.IdCategoriaProveedor,
      t.Direccion,
      t.Ciudad,
      t.Telefono,
      t.Celular,
      t.Email,
      t.Web,
      t.Contacto,
      t.TelefonoContacto,
      t.EmailContacto,
      t.IdListaPrecio,
      lp.Descripcion  AS NombreListaPrecio,
      t.LimiteCredito,
      t.DiasCredito,
      t.IdDocumentoVenta,
      t.IdTipoComprobante,
      t.IdDescuento,
      t.PedirReferencia,
      t.Notas,
      t.Activo,
      t.FechaCreacion,
      t.FechaModificacion
    FROM dbo.Terceros t
    LEFT JOIN dbo.DocumentosIdentificacion di ON di.IdDocumentoIdentificacion = t.IdTipoDocIdentificacion
    LEFT JOIN dbo.TiposCliente tc ON tc.IdTipoCliente = t.IdTipoCliente
    LEFT JOIN dbo.CategoriasCliente cc ON cc.IdCategoriaCliente = t.IdCategoriaCliente
    LEFT JOIN dbo.ListasPrecios lp ON lp.IdListaPrecio = t.IdListaPrecio
    WHERE t.IdTercero = @IdTercero AND t.RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.Terceros (
      Codigo, Nombre, NombreCorto, TipoPersona,
      IdTipoDocIdentificacion, DocumentoIdentificacion,
      EsCliente, IdTipoCliente, IdCategoriaCliente,
      EsProveedor, IdTipoProveedor, IdCategoriaProveedor,
      Direccion, Ciudad, Telefono, Celular, Email, Web,
      Contacto, TelefonoContacto, EmailContacto,
      IdListaPrecio, LimiteCredito, DiasCredito,
      IdDocumentoVenta, IdTipoComprobante, IdDescuento,
      PedirReferencia, Notas,
      Activo, UsuarioCreacion
    )
    VALUES (
      UPPER(LTRIM(RTRIM(@Codigo))),
      LTRIM(RTRIM(@Nombre)),
      NULLIF(LTRIM(RTRIM(@NombreCorto)), ''),
      ISNULL(@TipoPersona, 'J'),
      @IdTipoDocIdentificacion,
      NULLIF(LTRIM(RTRIM(@DocumentoIdentificacion)), ''),
      ISNULL(@EsCliente, 0),
      @IdTipoCliente,
      @IdCategoriaCliente,
      ISNULL(@EsProveedor, 0),
      @IdTipoProveedor,
      @IdCategoriaProveedor,
      NULLIF(LTRIM(RTRIM(@Direccion)), ''),
      NULLIF(LTRIM(RTRIM(@Ciudad)), ''),
      NULLIF(LTRIM(RTRIM(@Telefono)), ''),
      NULLIF(LTRIM(RTRIM(@Celular)), ''),
      NULLIF(LTRIM(RTRIM(@Email)), ''),
      NULLIF(LTRIM(RTRIM(@Web)), ''),
      NULLIF(LTRIM(RTRIM(@Contacto)), ''),
      NULLIF(LTRIM(RTRIM(@TelefonoContacto)), ''),
      NULLIF(LTRIM(RTRIM(@EmailContacto)), ''),
      @IdListaPrecio,
      ISNULL(@LimiteCredito, 0),
      ISNULL(@DiasCredito, 0),
      @IdDocumentoVenta,
      @IdTipoComprobante,
      @IdDescuento,
      ISNULL(@PedirReferencia, 0),
      @Notas,
      ISNULL(@Activo, 1),
      @UsuarioCreacion
    );
    DECLARE @NewId INT = SCOPE_IDENTITY();
    EXEC dbo.spTercerosCRUD @Accion = 'O', @IdTercero = @NewId;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Terceros
    SET
      Codigo                   = UPPER(LTRIM(RTRIM(@Codigo))),
      Nombre                   = LTRIM(RTRIM(@Nombre)),
      NombreCorto              = NULLIF(LTRIM(RTRIM(@NombreCorto)), ''),
      TipoPersona              = ISNULL(@TipoPersona, TipoPersona),
      IdTipoDocIdentificacion  = @IdTipoDocIdentificacion,
      DocumentoIdentificacion  = NULLIF(LTRIM(RTRIM(@DocumentoIdentificacion)), ''),
      EsCliente                = ISNULL(@EsCliente, EsCliente),
      IdTipoCliente            = @IdTipoCliente,
      IdCategoriaCliente       = @IdCategoriaCliente,
      EsProveedor              = ISNULL(@EsProveedor, EsProveedor),
      IdTipoProveedor          = @IdTipoProveedor,
      IdCategoriaProveedor     = @IdCategoriaProveedor,
      Direccion                = NULLIF(LTRIM(RTRIM(@Direccion)), ''),
      Ciudad                   = NULLIF(LTRIM(RTRIM(@Ciudad)), ''),
      Telefono                 = NULLIF(LTRIM(RTRIM(@Telefono)), ''),
      Celular                  = NULLIF(LTRIM(RTRIM(@Celular)), ''),
      Email                    = NULLIF(LTRIM(RTRIM(@Email)), ''),
      Web                      = NULLIF(LTRIM(RTRIM(@Web)), ''),
      Contacto                 = NULLIF(LTRIM(RTRIM(@Contacto)), ''),
      TelefonoContacto         = NULLIF(LTRIM(RTRIM(@TelefonoContacto)), ''),
      EmailContacto            = NULLIF(LTRIM(RTRIM(@EmailContacto)), ''),
      IdListaPrecio            = @IdListaPrecio,
      LimiteCredito            = ISNULL(@LimiteCredito, LimiteCredito),
      DiasCredito              = ISNULL(@DiasCredito, DiasCredito),
      IdDocumentoVenta         = @IdDocumentoVenta,
      IdTipoComprobante        = @IdTipoComprobante,
      IdDescuento              = @IdDescuento,
      PedirReferencia          = ISNULL(@PedirReferencia, PedirReferencia),
      Notas                    = @Notas,
      Activo                   = ISNULL(@Activo, Activo),
      FechaModificacion        = GETDATE(),
      UsuarioModificacion      = @UsuarioModificacion
    WHERE IdTercero = @IdTercero AND RowStatus = 1;
    EXEC dbo.spTercerosCRUD @Accion = 'O', @IdTercero = @IdTercero;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Terceros
    SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdTercero = @IdTercero;
    RETURN;
  END
END
GO
