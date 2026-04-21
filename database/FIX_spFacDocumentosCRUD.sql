-- FIX: Recrear spFacDocumentosCRUD sin columna Anulado
-- Pegar completo en SSMS y ejecutar con F5

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

    DECLARE @AlmacenDoc INT
    DECLARE @AfectaInv  BIT
    SELECT @AlmacenDoc = d.IdAlmacen, @AfectaInv = ISNULL(t.AfectaInventario, 0)
    FROM dbo.FacDocumentos d
    JOIN dbo.FacTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
    WHERE d.IdDocumento = @IdDocumento

    IF @AfectaInv = 1 AND @AlmacenDoc IS NOT NULL
    BEGIN
      UPDATE pa
      SET pa.Cantidad = pa.Cantidad + dd.Cantidad,
          pa.FechaModificacion = GETDATE(),
          pa.UsuarioModificacion = @IdUsuarioAccion
      FROM dbo.ProductoAlmacenes pa
      JOIN dbo.FacDocumentoDetalle dd ON dd.IdDocumento = @IdDocumento AND dd.IdProducto = pa.IdProducto AND dd.RowStatus = 1
      JOIN dbo.Productos pr ON pr.IdProducto = dd.IdProducto
      WHERE pa.IdAlmacen = @AlmacenDoc AND pa.RowStatus = 1
        AND pr.ManejaExistencia = 1
    END

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

PRINT 'spFacDocumentosCRUD recreado OK'
GO

-- Verificar que no queda Anulado en el SP
SELECT CASE WHEN OBJECT_DEFINITION(OBJECT_ID('dbo.spFacDocumentosCRUD')) LIKE '%Anulado%'
       THEN 'ERROR: todavia tiene Anulado'
       ELSE 'OK: sin Anulado' END AS Resultado
GO
