-- ============================================================
-- Script 172: Limpieza de columnas en FacDocumentos y FacTiposDocumento
--
-- FacDocumentos - Eliminar:
--   NombreCliente, Anulado, FechaEnvioDGII, Saldo,
--   FechaVencimiento, TipoDocumentoCodigo, DocumentoNumero
-- FacDocumentos - Agregar:
--   DocumentoSecuencia VARCHAR(30) — ej. 'FAC-0000001'
--
-- FacTiposDocumento - Eliminar:
--   Codigo (reemplazado por Prefijo)
-- ============================================================

-- ── 1. Quitar índice sobre DocumentoNumero ───────────────────
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_DocumentoNumero' AND object_id = OBJECT_ID('dbo.FacDocumentos'))
    DROP INDEX IX_FacDocumentos_DocumentoNumero ON dbo.FacDocumentos;
GO

-- ── 2. Eliminar columna computada DocumentoNumero ────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'DocumentoNumero')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN DocumentoNumero;
GO

-- ── 3. Eliminar TipoDocumentoCodigo ─────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'TipoDocumentoCodigo')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN TipoDocumentoCodigo;
GO

-- ── 4. Eliminar NombreCliente ────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'NombreCliente')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN NombreCliente;
GO

-- ── 5. Eliminar Anulado ──────────────────────────────────────
-- Primero quitar DEFAULT constraint de Anulado si existe
DECLARE @df NVARCHAR(200);
SELECT @df = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE dc.parent_object_id = OBJECT_ID('dbo.FacDocumentos') AND c.name = 'Anulado';
IF @df IS NOT NULL EXEC('ALTER TABLE dbo.FacDocumentos DROP CONSTRAINT [' + @df + ']');
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'Anulado')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN Anulado;
GO

-- ── 6. Eliminar FechaEnvioDGII ───────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'FechaEnvioDGII')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN FechaEnvioDGII;
GO

-- ── 7. Eliminar Saldo ────────────────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'Saldo')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN Saldo;
GO

-- ── 8. Eliminar FechaVencimiento ─────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'FechaVencimiento')
    ALTER TABLE dbo.FacDocumentos DROP COLUMN FechaVencimiento;
GO

-- ── 9. Agregar DocumentoSecuencia ────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'DocumentoSecuencia')
    ALTER TABLE dbo.FacDocumentos ADD DocumentoSecuencia VARCHAR(30) NULL;
GO

-- Poblar DocumentoSecuencia en registros existentes
UPDATE d SET d.DocumentoSecuencia =
    t.Prefijo + '-' + RIGHT('0000000' + CAST(d.Secuencia AS VARCHAR(10)), 7)
FROM dbo.FacDocumentos d
JOIN dbo.FacTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
WHERE d.DocumentoSecuencia IS NULL;
GO

-- Índice para búsquedas por número de documento
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_DocumentoSecuencia')
    CREATE INDEX IX_FacDocumentos_DocumentoSecuencia
        ON dbo.FacDocumentos (DocumentoSecuencia)
        WHERE RowStatus = 1;
GO

-- ── 10. FacTiposDocumento: eliminar Codigo ───────────────────
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.FacTiposDocumento') AND name = 'Codigo')
BEGIN
    -- Quitar constraints sobre Codigo si existen
    DECLARE @ck NVARCHAR(200);
    SELECT @ck = cc.name FROM sys.check_constraints cc
    WHERE cc.parent_object_id = OBJECT_ID('dbo.FacTiposDocumento')
      AND cc.definition LIKE '%Codigo%';
    IF @ck IS NOT NULL EXEC('ALTER TABLE dbo.FacTiposDocumento DROP CONSTRAINT [' + @ck + ']');

    DECLARE @uq NVARCHAR(200);
    SELECT @uq = kc.name FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = OBJECT_ID('dbo.FacTiposDocumento') AND c.name = 'Codigo';
    IF @uq IS NOT NULL EXEC('ALTER TABLE dbo.FacTiposDocumento DROP CONSTRAINT [' + @uq + ']');

    ALTER TABLE dbo.FacTiposDocumento DROP COLUMN Codigo;
    PRINT 'FacTiposDocumento.Codigo eliminado.';
END
ELSE PRINT 'FacTiposDocumento.Codigo ya no existe.';
GO

-- ── 11. Recrear spFacDocumentosCRUD sin columnas eliminadas ──
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
  -- Filtros L
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

  -- ── INSERT ─────────────────────────────────────────────────
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
    SELECT SCOPE_IDENTITY() AS IdDocumento
    RETURN
  END

  -- ── UPDATE ─────────────────────────────────────────────────
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

  -- ── ANULAR ─────────────────────────────────────────────────
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

  -- ── POSTEAR ──────────────────────────────────────────────────
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

  -- ── GET ─────────────────────────────────────────────────────
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

  -- ── LIST ────────────────────────────────────────────────────
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

-- ── 12. Recrear spEmitirFacturaPOS sin TipoDocumentoCodigo ───
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

-- ── 13. Recrear vista vFacDocumentosReporte ──────────────────
CREATE OR ALTER VIEW dbo.vFacDocumentosReporte AS
SELECT
  d.IdDocumento,
  d.DocumentoSecuencia,
  d.Secuencia,
  t.Descripcion          AS TipoDocumento,
  t.Prefijo,
  CAST(d.FechaCreacion AS DATETIME) AS FechaHoraEmision,
  d.FechaDocumento,
  d.NCF,
  d.NCFVencimiento,
  n.Nombre               AS TipoNCFNombre,
  n.Codigo               AS TipoNCFCodigo,
  d.RNCCliente,
  d.IdDivision,          div.Nombre      AS Division,
  d.IdSucursal,          suc.Nombre      AS Sucursal,
  d.IdPuntoEmision,      pe.Nombre       AS PuntoEmision,
  d.IdCaja,              caj.Descripcion AS CajaPOS,
  d.IdSesionCaja,
  d.IdCliente,           c.Nombre        AS Cliente,
  d.IdVendedor,          ven.Nombre + ISNULL(' ' + ven.Apellido, '') AS Vendedor,
  d.IdUsuario,           u.NombreUsuario AS Cajero,
  d.Referencia,
  d.IdAlmacen,           alm.Descripcion AS Almacen,
  d.IdDescuento,         desc_.Nombre    AS GrupoDescuento,
  d.IdMoneda,            mon.Codigo      AS Moneda,
  d.TasaCambio,
  d.IdTipoDocumento,
  d.SubTotal, d.Descuento, d.Impuesto, d.MontoExento, d.Propina, d.Total, d.TotalPagado,
  d.Comentario, d.ComentarioInterno,
  d.Estado,
  CASE d.Estado WHEN 'I' THEN 'Pendiente de Postear' WHEN 'P' THEN 'Posteado' WHEN 'N' THEN 'Anulado' ELSE d.Estado END AS EstadoNombre,
  d.MotivoAnulacion,
  d.FechaCreacion, d.FechaModificacion
FROM dbo.FacDocumentos d
LEFT JOIN dbo.FacTiposDocumento t  ON t.IdTipoDocumento = d.IdTipoDocumento
LEFT JOIN dbo.CatalogoNCF n        ON n.IdCatalogoNCF = d.IdTipoNCF
LEFT JOIN dbo.PuntosEmision pe     ON pe.IdPuntoEmision = d.IdPuntoEmision
LEFT JOIN dbo.Sucursales suc       ON suc.IdSucursal = d.IdSucursal
LEFT JOIN dbo.Divisiones div       ON div.IdDivision = d.IdDivision
LEFT JOIN dbo.FacCajasPOS caj      ON caj.IdCajaPOS = d.IdCaja
LEFT JOIN dbo.Terceros c           ON c.IdTercero = d.IdCliente
LEFT JOIN dbo.Vendedores ven       ON ven.IdVendedor = d.IdVendedor
LEFT JOIN dbo.Usuarios u           ON u.IdUsuario = d.IdUsuario
LEFT JOIN dbo.Descuentos desc_     ON desc_.IdDescuento = d.IdDescuento
LEFT JOIN dbo.Almacenes alm        ON alm.IdAlmacen = d.IdAlmacen
LEFT JOIN dbo.Monedas mon          ON mon.IdMoneda = d.IdMoneda
WHERE d.RowStatus = 1;
GO

-- Verificación
SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FacDocumentos' ORDER BY ORDINAL_POSITION;
PRINT 'Script 172 aplicado correctamente.';
GO
