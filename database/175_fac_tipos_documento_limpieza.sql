-- ============================================================
-- Script 175: FacTiposDocumento - Limpieza de columnas
--   - Eliminar GeneraFactura (nunca se implementara)
--   - Mantener AfectaInventario y ReservaStock
--   - Arreglar SecuenciaActual: sincronizar con FacDocumentos
-- ============================================================

-- ── 1. Drop GeneraFactura ─────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacTiposDocumento') AND name = 'GeneraFactura')
    ALTER TABLE dbo.FacTiposDocumento DROP COLUMN GeneraFactura;
GO

-- ── 2. Sincronizar SecuenciaActual con el MAX real ────────────
UPDATE t SET t.SecuenciaActual = ISNULL(d.MaxSec, 0)
FROM dbo.FacTiposDocumento t
LEFT JOIN (
    SELECT IdTipoDocumento, MAX(Secuencia) AS MaxSec
    FROM dbo.FacDocumentos
    WHERE RowStatus = 1
    GROUP BY IdTipoDocumento
) d ON d.IdTipoDocumento = t.IdTipoDocumento;
GO

-- ── 3. Recrear spFacTiposDocumentoCRUD sin GeneraFactura ─────
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
           t.AfectaInventario, t.ReservaStock,
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
           t.AfectaInventario, t.ReservaStock,
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
      AfectaInventario, ReservaStock,
      Activo, UsuarioCreacion
    ) VALUES (
      @TipoOperacion, @Descripcion, @Prefijo, @SecuenciaInicial, 0,
      @IdMoneda, ISNULL(@AplicaPropina, 0), @IdCatalogoNCF,
      ISNULL(@AfectaInventario, 0), ISNULL(@ReservaStock, 0),
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

    UPDATE dbo.FacTiposDocumento SET
      Descripcion         = ISNULL(@Descripcion, Descripcion),
      Prefijo             = ISNULL(@Prefijo, Prefijo),
      SecuenciaInicial    = ISNULL(@SecuenciaInicial, SecuenciaInicial),
      IdMoneda            = @IdMoneda,
      AplicaPropina       = ISNULL(@AplicaPropina, AplicaPropina),
      IdCatalogoNCF       = @IdCatalogoNCF,
      AfectaInventario    = ISNULL(@AfectaInventario, AfectaInventario),
      ReservaStock        = ISNULL(@ReservaStock, ReservaStock),
      Activo              = ISNULL(@Activo, Activo),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioAccion
    WHERE IdTipoDocumento = @IdTipoDocumento AND RowStatus = 1
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

-- ── 4. Actualizar spFacDocumentosCRUD accion 'I': bump SecuenciaActual
IF OBJECT_ID('dbo.spFacDocumentosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spFacDocumentosCRUD;
GO

CREATE PROCEDURE dbo.spFacDocumentosCRUD
  @Accion                CHAR(1),
  @IdDocumento           INT            = NULL,
  @IdTipoDocumento       INT            = NULL,
  @IdDocumentoOrigen     INT            = NULL,
  @IdDocumentoPOSOrigen  INT            = NULL,
  @NCF                   VARCHAR(19)    = NULL,
  @NCFVencimiento        DATE           = NULL,
  @IdTipoNCF             INT            = NULL,
  @RNCCliente            VARCHAR(11)    = NULL,
  @IdPuntoEmision        INT            = NULL,
  @IdDivision            INT            = NULL,
  @IdSucursal            INT            = NULL,
  @IdCaja                INT            = NULL,
  @IdSesionCaja          INT            = NULL,
  @IdUsuario             INT            = NULL,
  @IdVendedor            INT            = NULL,
  @IdCliente             INT            = NULL,
  @IdDescuento           INT            = NULL,
  @Secuencia             INT            = NULL,
  @Referencia            NVARCHAR(100)  = NULL,
  @IdAlmacen             INT            = NULL,
  @FechaDocumento        DATE           = NULL,
  @SubTotal              DECIMAL(18,2)  = 0,
  @Descuento             DECIMAL(18,2)  = 0,
  @Impuesto              DECIMAL(18,2)  = 0,
  @MontoExento           DECIMAL(18,2)  = 0,
  @Propina               DECIMAL(18,2)  = 0,
  @Total                 DECIMAL(18,2)  = 0,
  @IdMoneda              INT            = NULL,
  @TasaCambio            DECIMAL(18,6)  = 1,
  @Comentario            NVARCHAR(500)  = NULL,
  @ComentarioInterno     NVARCHAR(500)  = NULL,
  @MotivoAnulacion       NVARCHAR(500)  = NULL,
  @IdUsuarioAccion       INT            = NULL,
  @FechaDesde            DATE           = NULL,
  @FechaHasta            DATE           = NULL,
  @SoloTipo              INT            = NULL,
  @SoloEstado            CHAR(1)        = NULL,
  @IdPuntoEmisionFiltro  INT            = NULL,
  @SecuenciaDesde        INT            = NULL,
  @SecuenciaHasta        INT            = NULL,
  @PageSize              INT            = 100,
  @PageOffset            INT            = 0
AS
BEGIN
  SET NOCOUNT ON

  IF @Accion = 'I'
  BEGIN
    DECLARE @ResSucursal INT = @IdSucursal
    DECLARE @ResDivision INT = @IdDivision
    DECLARE @Prefijo     VARCHAR(10)
    DECLARE @DocSecuencia VARCHAR(30)

    IF @ResSucursal IS NULL AND @IdPuntoEmision IS NOT NULL
      SELECT @ResSucursal = pe.IdSucursal, @ResDivision = s.IdDivision
      FROM dbo.PuntosEmision pe
      JOIN dbo.Sucursales s ON s.IdSucursal = pe.IdSucursal
      WHERE pe.IdPuntoEmision = @IdPuntoEmision

    SELECT @Prefijo = Prefijo FROM dbo.FacTiposDocumento WHERE IdTipoDocumento = @IdTipoDocumento
    SET @DocSecuencia = ISNULL(@Prefijo, '') + '-' + RIGHT('0000000' + CAST(ISNULL(@Secuencia, 0) AS VARCHAR(10)), 7)

    INSERT INTO dbo.FacDocumentos (
      IdTipoDocumento, DocumentoSecuencia, IdDocumentoOrigen, IdDocumentoPOSOrigen,
      NCF, NCFVencimiento, IdTipoNCF, RNCCliente,
      IdPuntoEmision, IdDivision, IdSucursal, IdCaja, IdSesionCaja,
      IdUsuario, IdVendedor, IdCliente,
      IdDescuento, Secuencia, FechaDocumento,
      Referencia, IdAlmacen,
      SubTotal, Descuento, Impuesto, MontoExento, Propina, Total,
      IdMoneda, TasaCambio, Comentario, ComentarioInterno, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdTipoDocumento, @DocSecuencia, @IdDocumentoOrigen, @IdDocumentoPOSOrigen,
      @NCF, @NCFVencimiento, @IdTipoNCF, @RNCCliente,
      @IdPuntoEmision, @ResDivision, @ResSucursal, @IdCaja, @IdSesionCaja,
      @IdUsuario, @IdVendedor, @IdCliente,
      @IdDescuento, ISNULL(@Secuencia, 0), ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
      @Referencia, @IdAlmacen,
      @SubTotal, @Descuento, @Impuesto, @MontoExento, @Propina, @Total,
      @IdMoneda, ISNULL(@TasaCambio, 1), @Comentario, @ComentarioInterno, 'I',
      @IdUsuarioAccion, GETDATE()
    )

    -- Actualizar secuencia actual del tipo de documento
    UPDATE dbo.FacTiposDocumento
    SET SecuenciaActual = ISNULL(@Secuencia, 0)
    WHERE IdTipoDocumento = @IdTipoDocumento
      AND ISNULL(@Secuencia, 0) > ISNULL(SecuenciaActual, 0)

    SELECT SCOPE_IDENTITY() AS IdDocumento
    RETURN
  END

  IF @Accion = 'U'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.FacDocumentos WHERE IdDocumento = @IdDocumento AND Estado = 'I')
      RAISERROR('El documento no existe o no está en estado modificable.', 16, 1)
    UPDATE dbo.FacDocumentos SET
      IdCliente          = ISNULL(@IdCliente, IdCliente),
      IdVendedor         = @IdVendedor,
      IdDescuento        = @IdDescuento,
      FechaDocumento     = ISNULL(@FechaDocumento, FechaDocumento),
      Referencia         = @Referencia,
      IdAlmacen          = @IdAlmacen,
      NCF                = ISNULL(@NCF, NCF),
      NCFVencimiento     = @NCFVencimiento,
      RNCCliente         = ISNULL(@RNCCliente, RNCCliente),
      SubTotal           = @SubTotal,
      Descuento          = @Descuento,
      Impuesto           = @Impuesto,
      MontoExento        = @MontoExento,
      Propina            = @Propina,
      Total              = @Total,
      TasaCambio         = ISNULL(@TasaCambio, TasaCambio),
      Comentario         = @Comentario,
      ComentarioInterno  = @ComentarioInterno,
      FechaModificacion  = GETDATE(),
      IdUsuarioModif     = @IdUsuarioAccion
    WHERE IdDocumento = @IdDocumento
    SELECT @IdDocumento AS IdDocumento
    RETURN
  END

  IF @Accion = 'A'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.FacDocumentos WHERE IdDocumento = @IdDocumento AND Estado IN ('I','P'))
      RAISERROR('Solo se pueden anular documentos en estado Pendiente o Posteado.', 16, 1)
    UPDATE dbo.FacDocumentos SET
      Estado             = 'N',
      FechaAnulacion     = GETDATE(),
      MotivoAnulacion    = @MotivoAnulacion,
      IdUsuarioAnulacion = @IdUsuarioAccion,
      FechaModificacion  = GETDATE(),
      IdUsuarioModif     = @IdUsuarioAccion
    WHERE IdDocumento = @IdDocumento
    SELECT @IdDocumento AS IdDocumento
    RETURN
  END

  IF @Accion = 'P'
  BEGIN
    UPDATE dbo.FacDocumentos SET
      Estado            = 'P',
      FechaModificacion = GETDATE(),
      IdUsuarioModif    = @IdUsuarioAccion
    WHERE IdDocumento = @IdDocumento AND Estado = 'I'
    SELECT @IdDocumento AS IdDocumento
    RETURN
  END

  IF @Accion = 'G'
  BEGIN
    SELECT
      d.*,
      t.Descripcion        AS TipoDocumentoNombre,
      t.Prefijo            AS TipoDocumentoPrefijo,
      c.Nombre             AS ClienteNombre,
      c.DocumentoIdentificacion AS ClienteDocumento,
      pe.Nombre            AS PuntoEmisionNombre,
      suc.Nombre           AS SucursalNombre,
      div.Nombre           AS DivisionNombre,
      u.NombreUsuario      AS UsuarioNombre,
      ven.Nombre + ISNULL(' ' + ven.Apellido, '') AS VendedorNombre,
      n.Nombre             AS TipoNCFNombre,
      desc_.Nombre         AS DescuentoNombre,
      alm.Descripcion      AS AlmacenNombre
    FROM dbo.FacDocumentos d
    LEFT JOIN dbo.FacTiposDocumento t  ON t.IdTipoDocumento = d.IdTipoDocumento
    LEFT JOIN dbo.Terceros c           ON c.IdTercero = d.IdCliente
    LEFT JOIN dbo.PuntosEmision pe     ON pe.IdPuntoEmision = d.IdPuntoEmision
    LEFT JOIN dbo.Sucursales suc       ON suc.IdSucursal = d.IdSucursal
    LEFT JOIN dbo.Divisiones div       ON div.IdDivision = d.IdDivision
    LEFT JOIN dbo.Usuarios u           ON u.IdUsuario = d.IdUsuario
    LEFT JOIN dbo.Vendedores ven       ON ven.IdVendedor = d.IdVendedor
    LEFT JOIN dbo.CatalogoNCF n        ON n.IdCatalogoNCF = d.IdTipoNCF
    LEFT JOIN dbo.Descuentos desc_     ON desc_.IdDescuento = d.IdDescuento
    LEFT JOIN dbo.Almacenes alm        ON alm.IdAlmacen = d.IdAlmacen
    WHERE d.IdDocumento = @IdDocumento

    SELECT dd.*, um.Abreviatura AS UnidadMedidaAbr, um.Nombre AS UnidadMedidaNombre
    FROM dbo.FacDocumentoDetalle dd
    LEFT JOIN dbo.UnidadesMedida um ON um.IdUnidadMedida = dd.IdUnidadMedida
    WHERE dd.IdDocumento = @IdDocumento AND dd.RowStatus = 1
    ORDER BY dd.NumeroLinea
    RETURN
  END

  IF @Accion = 'L'
  BEGIN
    SELECT
      d.IdDocumento,
      d.DocumentoSecuencia,
      d.Secuencia,
      d.NCF, d.NCFVencimiento,
      d.FechaDocumento,
      d.IdDivision,     div.Nombre   AS DivisionNombre,
      d.IdSucursal,     suc.Nombre   AS SucursalNombre,
      d.IdPuntoEmision, pe.Nombre    AS PuntoEmisionNombre,
      d.IdCaja,
      d.IdCliente,      c.Nombre     AS ClienteNombre,
      d.RNCCliente,
      d.IdVendedor,     ven.Nombre + ISNULL(' ' + ven.Apellido, '') AS VendedorNombre,
      d.Referencia,
      d.IdAlmacen,      alm.Descripcion AS AlmacenNombre,
      d.IdDescuento,    desc_.Nombre AS DescuentoNombre,
      d.SubTotal, d.Descuento, d.Impuesto, d.MontoExento,
      d.Propina, d.Total, d.TotalPagado,
      d.IdMoneda,       mon.Codigo   AS MonedaCodigo,
      d.TasaCambio,
      d.Estado,
      d.Comentario, d.ComentarioInterno,
      u.NombreUsuario   AS UsuarioNombre,
      t.Descripcion     AS TipoDocumentoNombre,
      t.Prefijo         AS TipoDocumentoPrefijo,
      n.Nombre          AS TipoNCFNombre,
      COUNT(*) OVER()   AS TotalRegistros
    FROM dbo.FacDocumentos d
    LEFT JOIN dbo.FacTiposDocumento t  ON t.IdTipoDocumento = d.IdTipoDocumento
    LEFT JOIN dbo.PuntosEmision pe     ON pe.IdPuntoEmision = d.IdPuntoEmision
    LEFT JOIN dbo.Sucursales suc       ON suc.IdSucursal = d.IdSucursal
    LEFT JOIN dbo.Divisiones div       ON div.IdDivision = d.IdDivision
    LEFT JOIN dbo.Usuarios u           ON u.IdUsuario = d.IdUsuario
    LEFT JOIN dbo.Vendedores ven       ON ven.IdVendedor = d.IdVendedor
    LEFT JOIN dbo.CatalogoNCF n        ON n.IdCatalogoNCF = d.IdTipoNCF
    LEFT JOIN dbo.Descuentos desc_     ON desc_.IdDescuento = d.IdDescuento
    LEFT JOIN dbo.Almacenes alm        ON alm.IdAlmacen = d.IdAlmacen
    LEFT JOIN dbo.Monedas mon          ON mon.IdMoneda = d.IdMoneda
    LEFT JOIN dbo.Terceros c           ON c.IdTercero = d.IdCliente
    WHERE d.RowStatus = 1
      AND (@IdPuntoEmisionFiltro IS NULL OR d.IdPuntoEmision = @IdPuntoEmisionFiltro)
      AND (@FechaDesde           IS NULL OR d.FechaDocumento >= @FechaDesde)
      AND (@FechaHasta           IS NULL OR d.FechaDocumento <= @FechaHasta)
      AND (@SoloTipo             IS NULL OR d.IdTipoDocumento = @SoloTipo)
      AND (@SoloEstado           IS NULL OR d.Estado = @SoloEstado)
      AND (@SecuenciaDesde       IS NULL OR d.Secuencia >= @SecuenciaDesde)
      AND (@SecuenciaHasta       IS NULL OR d.Secuencia <= @SecuenciaHasta)
    ORDER BY d.FechaDocumento DESC, d.IdDocumento DESC
    OFFSET @PageOffset ROWS FETCH NEXT @PageSize ROWS ONLY
    RETURN
  END
END
GO

-- ── 5. Actualizar spEmitirFacturaPOS: bump SecuenciaActual ────
-- (solo el UPDATE sobre FacTiposDocumento, el resto ya existe)
-- Se recrea completo para consistencia
IF OBJECT_ID('dbo.spEmitirFacturaPOS', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spEmitirFacturaPOS;
GO

CREATE PROCEDURE dbo.spEmitirFacturaPOS
  @IdDocumentoPOS     INT,
  @IdSesionCaja       INT           = NULL,
  @IdUsuario          INT,
  @PagosJSON          NVARCHAR(MAX),
  @IdTipoDocumento    INT           = NULL,
  @NCF                VARCHAR(19)   = NULL,
  @NCFVencimiento     DATE          = NULL,
  @IdTipoNCF          INT           = NULL,
  @RNCCliente         VARCHAR(11)   = NULL,
  @FechaDocumento     DATE          = NULL,
  @Comentario         NVARCHAR(500) = NULL,
  @ComentarioInterno  NVARCHAR(500) = NULL,
  @IdDescuento        INT           = NULL,
  @IdVendedor         INT           = NULL
AS
BEGIN
  SET NOCOUNT ON
  SET XACT_ABORT ON
  BEGIN TRANSACTION
  BEGIN TRY

    DECLARE
      @IdPuntoEmision   INT,
      @IdSucursal       INT,
      @IdDivision       INT,
      @IdCaja           INT,
      @IdCliente        INT,
      @IdAlmacen        INT,
      @Referencia       NVARCHAR(100),
      @SubTotal         DECIMAL(18,2),
      @Descuento        DECIMAL(18,2),
      @Impuesto         DECIMAL(18,2),
      @MontoExento      DECIMAL(18,2),
      @Propina          DECIMAL(18,2),
      @Total            DECIMAL(18,2),
      @IdMoneda         INT,
      @TasaCambio       DECIMAL(18,6),
      @Prefijo          VARCHAR(10),
      @IdTipoDocFinal   INT,
      @Secuencia        INT,
      @DocSecuencia     VARCHAR(30)

    SELECT
      @IdPuntoEmision = p.IdPuntoEmision,
      @IdCliente      = p.IdCliente,
      @IdAlmacen      = p.IdAlmacen,
      @Referencia     = p.Referencia,
      @IdMoneda       = p.IdMoneda,
      @TasaCambio     = ISNULL(p.TasaCambio, 1)
    FROM dbo.FacDocumentosPOS p
    WHERE p.IdDocumentoPOS = @IdDocumentoPOS AND p.RowStatus = 1

    IF @IdPuntoEmision IS NULL
      RAISERROR('Borrador no encontrado o ya fue procesado.', 16, 1)

    SELECT @IdSucursal = pe.IdSucursal, @IdDivision = s.IdDivision
    FROM dbo.PuntosEmision pe
    JOIN dbo.Sucursales s ON s.IdSucursal = pe.IdSucursal
    WHERE pe.IdPuntoEmision = @IdPuntoEmision

    IF @IdMoneda IS NULL
      SELECT @IdMoneda = td.IdMoneda
      FROM dbo.FacDocumentosPOS p
      JOIN dbo.FacTiposDocumento td ON td.IdTipoDocumento = p.IdTipoDocumento
      WHERE p.IdDocumentoPOS = @IdDocumentoPOS

    SELECT
      @SubTotal    = SUM(d.Cantidad * d.PrecioBase),
      @Descuento   = SUM(d.DescuentoLinea),
      @Impuesto    = SUM(CASE WHEN d.AplicaImpuesto = 1 AND d.PorcentajeImpuesto > 0
                              THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0) ELSE 0 END),
      @MontoExento = SUM(CASE WHEN d.AplicaImpuesto = 0 OR d.PorcentajeImpuesto = 0
                              THEN d.Cantidad * d.PrecioBase - d.DescuentoLinea ELSE 0 END),
      @Propina     = 0
    FROM dbo.FacDocumentoPOSDetalle d
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    SET @SubTotal    = ISNULL(@SubTotal, 0)
    SET @Descuento   = ISNULL(@Descuento, 0)
    SET @Impuesto    = ISNULL(@Impuesto, 0)
    SET @MontoExento = ISNULL(@MontoExento, 0)
    SET @Total       = @SubTotal - @Descuento + @Impuesto + @Propina

    SELECT @IdTipoDocFinal = ISNULL(@IdTipoDocumento, p.IdTipoDocumento)
    FROM dbo.FacDocumentosPOS p WHERE p.IdDocumentoPOS = @IdDocumentoPOS

    IF @IdTipoDocFinal IS NULL
      SET @IdTipoDocFinal = (SELECT TOP 1 IdTipoDocumento FROM dbo.FacTiposDocumento WHERE Activo = 1 AND RowStatus = 1 ORDER BY IdTipoDocumento)

    SELECT @Prefijo = Prefijo FROM dbo.FacTiposDocumento WHERE IdTipoDocumento = @IdTipoDocFinal

    IF @IdSesionCaja IS NOT NULL
      SELECT @IdCaja = IdCaja FROM dbo.FacCajasSesiones WHERE IdSesion = @IdSesionCaja AND Estado = 'AB'

    SELECT @Secuencia = ISNULL(MAX(Secuencia), 0) + 1
    FROM dbo.FacDocumentos
    WHERE IdPuntoEmision = @IdPuntoEmision AND IdTipoDocumento = @IdTipoDocFinal

    SET @DocSecuencia = ISNULL(@Prefijo, '') + '-' + RIGHT('0000000' + CAST(@Secuencia AS VARCHAR(10)), 7)

    DECLARE @IdDocumento INT

    INSERT INTO dbo.FacDocumentos (
      IdTipoDocumento, DocumentoSecuencia, IdDocumentoPOSOrigen,
      NCF, NCFVencimiento, IdTipoNCF, RNCCliente,
      IdPuntoEmision, IdDivision, IdSucursal, IdCaja, IdSesionCaja,
      IdUsuario, IdVendedor, IdCliente,
      IdDescuento, IdAlmacen, Referencia,
      Secuencia, FechaDocumento,
      SubTotal, Descuento, Impuesto, MontoExento, Propina, Total,
      IdMoneda, TasaCambio, Comentario, ComentarioInterno, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdTipoDocFinal, @DocSecuencia, @IdDocumentoPOS,
      @NCF, @NCFVencimiento, @IdTipoNCF, @RNCCliente,
      @IdPuntoEmision, @IdDivision, @IdSucursal, @IdCaja, @IdSesionCaja,
      @IdUsuario, @IdVendedor, @IdCliente,
      @IdDescuento, @IdAlmacen, @Referencia,
      @Secuencia, ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)),
      @SubTotal, @Descuento, @Impuesto, @MontoExento, @Propina, @Total,
      @IdMoneda, @TasaCambio, @Comentario, @ComentarioInterno, 'I',
      @IdUsuario, GETDATE()
    )

    SET @IdDocumento = SCOPE_IDENTITY()

    -- Actualizar secuencia actual del tipo de documento
    UPDATE dbo.FacTiposDocumento
    SET SecuenciaActual = @Secuencia
    WHERE IdTipoDocumento = @IdTipoDocFinal
      AND @Secuencia > ISNULL(SecuenciaActual, 0)

    INSERT INTO dbo.FacDocumentoDetalle (
      IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
      Cantidad, Unidad, IdUnidadMedida, PrecioBase,
      PorcentajeImpuesto, AplicaImpuesto, AplicaPropina,
      DescuentoLinea, PorcentajeDescuento, ComentarioLinea,
      SubTotalLinea, ImpuestoLinea, TotalLinea
    )
    SELECT
      @IdDocumento, ROW_NUMBER() OVER (ORDER BY d.IdDetalle),
      d.IdProducto, d.Codigo, d.Descripcion,
      d.Cantidad, d.Unidad, p.IdUnidadMedida, d.PrecioBase,
      d.PorcentajeImpuesto, d.AplicaImpuesto, d.AplicaPropina,
      d.DescuentoLinea,
      CASE WHEN (d.Cantidad * d.PrecioBase) > 0 THEN ROUND(d.DescuentoLinea / (d.Cantidad * d.PrecioBase) * 100, 2) ELSE 0 END,
      d.ComentarioLinea,
      d.Cantidad * d.PrecioBase,
      CASE WHEN d.AplicaImpuesto = 1 AND d.PorcentajeImpuesto > 0
           THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0) ELSE 0 END,
      (d.Cantidad * d.PrecioBase)
        + CASE WHEN d.AplicaImpuesto = 1 AND d.PorcentajeImpuesto > 0
               THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0) ELSE 0 END
        - d.DescuentoLinea
    FROM dbo.FacDocumentoPOSDetalle d
    LEFT JOIN dbo.Productos p ON p.IdProducto = d.IdProducto
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    INSERT INTO dbo.FacDocumentoPagos (
      IdDocumento, IdFormaPago, Monto, MontoBase,
      IdMoneda, TasaCambio, Referencia, Autorizacion,
      IdUsuarioCreacion, FechaCreacion
    )
    SELECT @IdDocumento,
      CAST(j.IdFormaPago AS INT), CAST(j.Monto AS DECIMAL(18,2)),
      CAST(ISNULL(j.MontoBase, j.Monto) AS DECIMAL(18,2)),
      CAST(j.IdMoneda AS INT), CAST(ISNULL(j.TasaCambio, 1) AS DECIMAL(18,6)),
      j.Referencia, j.Autorizacion, @IdUsuario, GETDATE()
    FROM OPENJSON(@PagosJSON) WITH (
      IdFormaPago   INT            '$.IdFormaPago',
      Monto         DECIMAL(18,2)  '$.Monto',
      MontoBase     DECIMAL(18,2)  '$.MontoBase',
      IdMoneda      INT            '$.IdMoneda',
      TasaCambio    DECIMAL(18,6)  '$.TasaCambio',
      Referencia    NVARCHAR(100)  '$.Referencia',
      Autorizacion  NVARCHAR(100)  '$.Autorizacion'
    ) j

    DECLARE @TotalPagado DECIMAL(18,2)
    SELECT @TotalPagado = ISNULL(SUM(Monto), 0) FROM dbo.FacDocumentoPagos WHERE IdDocumento = @IdDocumento AND RowStatus = 1
    UPDATE dbo.FacDocumentos SET TotalPagado = @TotalPagado WHERE IdDocumento = @IdDocumento

    IF @IdSesionCaja IS NOT NULL
      INSERT INTO dbo.FacMovimientosCaja (IdSesion, IdDocumento, IdFormaPago, TipoMovimiento, TipoValor, Monto, IdUsuarioCreacion, FechaCreacion)
      SELECT @IdSesionCaja, @IdDocumento, p.IdFormaPago, 'COBRO', f.TipoValor, p.Monto, @IdUsuario, GETDATE()
      FROM dbo.FacDocumentoPagos p
      JOIN dbo.FacFormasPago f ON f.IdFormaPago = p.IdFormaPago
      WHERE p.IdDocumento = @IdDocumento AND p.RowStatus = 1

    UPDATE dbo.FacDocumentosPOS SET RowStatus = 0, FechaModificacion = GETDATE(), IdUsuarioModif = @IdUsuario
    WHERE IdDocumentoPOS = @IdDocumentoPOS

    COMMIT TRANSACTION

    SELECT d.IdDocumento, d.DocumentoSecuencia, d.Secuencia,
           d.NCF, d.NCFVencimiento, d.Total, d.TotalPagado, d.Estado
    FROM dbo.FacDocumentos d WHERE d.IdDocumento = @IdDocumento

  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
    RAISERROR(@ErrMsg, 16, 1)
  END CATCH
END
GO

-- Verificacion
SELECT IdTipoDocumento, TipoOperacion, Descripcion, Prefijo,
       SecuenciaInicial, SecuenciaActual, AfectaInventario, ReservaStock, Activo
FROM dbo.FacTiposDocumento ORDER BY IdTipoDocumento;
PRINT 'Script 175 aplicado correctamente.';
GO
