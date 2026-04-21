-- ============================================================
-- Script 169: Campos de reportería para FacDocumentos
--
-- Cambios en FacDocumentos (cabecera):
--   IdDivision          INT    — desnorm. de PuntoEmision→Sucursal→Division
--   IdSucursal          INT    — desnorm. de PuntoEmision→Sucursal
--   IdVendedor          INT    — FK nueva tabla Vendedores
--   IdDescuento         INT    — FK Descuentos (grupo de descuento)
--   MontoExento         DECIMAL
--   NCFVencimiento      DATE   — fecha vencimiento del comprobante fiscal
--   DocumentoNumero     AS     — columna calculada Codigo+'-'+secuencia 7 dígitos
--   ComentarioInterno   NVARCHAR
--   Referencia          NVARCHAR — referencia del pedido/mesa/habitación
--   IdAlmacen           INT    — almacén origen (del borrador POS)
--   NOTA: NombreCliente se mantiene como campo nullable para migración
--         pero en nuevas inserciones no se desnormaliza (solo IdCliente)
--
-- Cambios en FacDocumentoDetalle:
--   IdUnidadMedida      INT    — FK UnidadesMedida
--   PorcentajeDescuento DECIMAL
--   Exento              BIT AS PERSISTED
--
-- Nueva tabla:
--   Vendedores          — maestro de vendedores independiente de Usuarios
-- ============================================================

-- ── 1. Tabla Vendedores ──────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Vendedores')
BEGIN
    CREATE TABLE dbo.Vendedores (
        IdVendedor          INT            NOT NULL IDENTITY(1,1) PRIMARY KEY,
        Codigo              VARCHAR(20)    NOT NULL,
        Nombre              NVARCHAR(150)  NOT NULL,
        Apellido            NVARCHAR(150)  NULL,
        IdUsuario           INT            NULL REFERENCES dbo.Usuarios(IdUsuario),
        Email               NVARCHAR(200)  NULL,
        Telefono            VARCHAR(30)    NULL,
        ComisionPct         DECIMAL(5,2)   NOT NULL DEFAULT 0,
        Activo              BIT            NOT NULL DEFAULT 1,
        RowStatus           TINYINT        NOT NULL DEFAULT 1,
        FechaCreacion       DATETIME       NOT NULL DEFAULT GETDATE(),
        IdUsuarioCreacion   INT            NULL,
        FechaModificacion   DATETIME       NULL,
        IdUsuarioModif      INT            NULL,
        CONSTRAINT UQ_Vendedores_Codigo UNIQUE (Codigo)
    );
    PRINT 'Tabla Vendedores creada.';
END
ELSE PRINT 'Tabla Vendedores ya existe.';
GO

-- ── 2. Cabecera: IdDivision ──────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'IdDivision')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD IdDivision INT NULL;
    PRINT 'FacDocumentos.IdDivision agregado.';
END
ELSE PRINT 'FacDocumentos.IdDivision ya existe.';
GO

-- ── 3. Cabecera: IdSucursal ──────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'IdSucursal')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD IdSucursal INT NULL;
    PRINT 'FacDocumentos.IdSucursal agregado.';
END
ELSE PRINT 'FacDocumentos.IdSucursal ya existe.';
GO

-- ── 4. Cabecera: IdVendedor → FK Vendedores ──────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'IdVendedor')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD IdVendedor INT NULL
        CONSTRAINT FK_FacDocumentos_Vendedor FOREIGN KEY REFERENCES dbo.Vendedores(IdVendedor);
    PRINT 'FacDocumentos.IdVendedor agregado.';
END
ELSE PRINT 'FacDocumentos.IdVendedor ya existe.';
GO

-- ── 5. Cabecera: IdDescuento ─────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'IdDescuento')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD IdDescuento INT NULL
        CONSTRAINT FK_FacDocumentos_Descuento FOREIGN KEY REFERENCES dbo.Descuentos(IdDescuento);
    PRINT 'FacDocumentos.IdDescuento agregado.';
END
ELSE PRINT 'FacDocumentos.IdDescuento ya existe.';
GO

-- ── 6. Cabecera: MontoExento ─────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'MontoExento')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD MontoExento DECIMAL(18,2) NOT NULL DEFAULT 0;
    PRINT 'FacDocumentos.MontoExento agregado.';
END
ELSE PRINT 'FacDocumentos.MontoExento ya existe.';
GO

-- ── 7. Cabecera: NCFVencimiento ──────────────────────────────
--   Fecha de vencimiento del comprobante fiscal asignado.
--   Diferente de FechaVencimiento (que es el vencimiento del crédito).
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'NCFVencimiento')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD NCFVencimiento DATE NULL;
    PRINT 'FacDocumentos.NCFVencimiento agregado.';
END
ELSE PRINT 'FacDocumentos.NCFVencimiento ya existe.';
GO

-- ── 8. Cabecera: ComentarioInterno ───────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'ComentarioInterno')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD ComentarioInterno NVARCHAR(500) NULL;
    PRINT 'FacDocumentos.ComentarioInterno agregado.';
END
ELSE PRINT 'FacDocumentos.ComentarioInterno ya existe.';
GO

-- ── 9. Cabecera: Referencia (mesa/habitación/pedido) ─────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'Referencia')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD Referencia NVARCHAR(100) NULL;
    PRINT 'FacDocumentos.Referencia agregado.';
END
ELSE PRINT 'FacDocumentos.Referencia ya existe.';
GO

-- ── 10. Cabecera: IdAlmacen ──────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'IdAlmacen')
BEGIN
    ALTER TABLE dbo.FacDocumentos ADD IdAlmacen INT NULL;
    PRINT 'FacDocumentos.IdAlmacen agregado.';
END
ELSE PRINT 'FacDocumentos.IdAlmacen ya existe.';
GO

-- ── 11. Cabecera: DocumentoNumero (columna calculada) ─────────
--   TipoDocumentoCodigo + '-' + Secuencia con 7 dígitos
--   Ej: 'FAC-0000042', 'NC-0000001'
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentos') AND name = 'DocumentoNumero')
BEGIN
    ALTER TABLE dbo.FacDocumentos
        ADD DocumentoNumero AS (
            TipoDocumentoCodigo + '-' +
            RIGHT('0000000' + CAST(Secuencia AS VARCHAR(10)), 7)
        ) PERSISTED;
    PRINT 'FacDocumentos.DocumentoNumero (computed) agregado.';
END
ELSE PRINT 'FacDocumentos.DocumentoNumero ya existe.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_DocumentoNumero')
    CREATE INDEX IX_FacDocumentos_DocumentoNumero
        ON dbo.FacDocumentos (DocumentoNumero)
        WHERE RowStatus = 1;
GO

-- ── 12. Detalle: IdUnidadMedida ──────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentoDetalle') AND name = 'IdUnidadMedida')
BEGIN
    ALTER TABLE dbo.FacDocumentoDetalle ADD IdUnidadMedida INT NULL
        CONSTRAINT FK_FacDocumentoDetalle_UM FOREIGN KEY REFERENCES dbo.UnidadesMedida(IdUnidadMedida);
    PRINT 'FacDocumentoDetalle.IdUnidadMedida agregado.';
END
ELSE PRINT 'FacDocumentoDetalle.IdUnidadMedida ya existe.';
GO

-- ── 13. Detalle: PorcentajeDescuento ────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentoDetalle') AND name = 'PorcentajeDescuento')
BEGIN
    ALTER TABLE dbo.FacDocumentoDetalle ADD PorcentajeDescuento DECIMAL(8,2) NOT NULL DEFAULT 0;
    PRINT 'FacDocumentoDetalle.PorcentajeDescuento agregado.';
END
ELSE PRINT 'FacDocumentoDetalle.PorcentajeDescuento ya existe.';
GO

-- ── 14. Detalle: Exento (calculado) ─────────────────────────
SET QUOTED_IDENTIFIER ON;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.FacDocumentoDetalle') AND name = 'Exento')
BEGIN
    ALTER TABLE dbo.FacDocumentoDetalle
        ADD Exento AS (
            CASE WHEN AplicaImpuesto = 0 OR PorcentajeImpuesto = 0
                 THEN CAST(1 AS BIT)
                 ELSE CAST(0 AS BIT) END
        ) PERSISTED;
    PRINT 'FacDocumentoDetalle.Exento (computed) agregado.';
END
ELSE PRINT 'FacDocumentoDetalle.Exento ya existe.';
GO

-- ── 14b. Actualizar CHECK constraint Estado en FacDocumentos ──
-- Estados: I = Pendiente de Postear, P = Posteado, N = Anulado
-- Primero migrar datos, luego reemplazar constraint
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_FacDocumentos_Estado')
    ALTER TABLE dbo.FacDocumentos DROP CONSTRAINT CK_FacDocumentos_Estado;
GO
UPDATE dbo.FacDocumentos SET Estado = 'I' WHERE Estado IN ('EM');
UPDATE dbo.FacDocumentos SET Estado = 'P' WHERE Estado IN ('EN','CE');
UPDATE dbo.FacDocumentos SET Estado = 'N' WHERE Estado IN ('AN');
GO
ALTER TABLE dbo.FacDocumentos
    ADD CONSTRAINT CK_FacDocumentos_Estado
    CHECK (Estado IN ('I','P','N'));
GO

-- ── 15. Recrear spFacDocumentosCRUD con todos los campos ─────
IF OBJECT_ID('dbo.spFacDocumentosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spFacDocumentosCRUD;
GO

CREATE PROCEDURE dbo.spFacDocumentosCRUD
  @Accion                CHAR(1),
  @IdDocumento           INT            = NULL,
  @IdTipoDocumento       INT            = NULL,
  @TipoDocumentoCodigo   VARCHAR(10)    = NULL,
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
  @FechaDocumento        DATE           = NULL,
  @FechaVencimiento      DATE           = NULL,
  @Referencia            NVARCHAR(100)  = NULL,
  @IdAlmacen             INT            = NULL,
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
  @SoloTipo              VARCHAR(10)    = NULL,
  @SoloEstado            CHAR(2)        = NULL,
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
    IF @ResSucursal IS NULL AND @IdPuntoEmision IS NOT NULL
      SELECT @ResSucursal = pe.IdSucursal, @ResDivision = s.IdDivision
      FROM dbo.PuntosEmision pe
      JOIN dbo.Sucursales s ON s.IdSucursal = pe.IdSucursal
      WHERE pe.IdPuntoEmision = @IdPuntoEmision

    INSERT INTO dbo.FacDocumentos (
      IdTipoDocumento, TipoDocumentoCodigo, IdDocumentoOrigen, IdDocumentoPOSOrigen,
      NCF, NCFVencimiento, IdTipoNCF, RNCCliente,
      IdPuntoEmision, IdDivision, IdSucursal, IdCaja, IdSesionCaja,
      IdUsuario, IdVendedor, IdCliente,
      IdDescuento, Secuencia, FechaDocumento, FechaVencimiento,
      Referencia, IdAlmacen,
      SubTotal, Descuento, Impuesto, MontoExento, Propina, Total,
      IdMoneda, TasaCambio, Comentario, ComentarioInterno, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdTipoDocumento, @TipoDocumentoCodigo, @IdDocumentoOrigen, @IdDocumentoPOSOrigen,
      @NCF, @NCFVencimiento, @IdTipoNCF, @RNCCliente,
      @IdPuntoEmision, @ResDivision, @ResSucursal, @IdCaja, @IdSesionCaja,
      @IdUsuario, @IdVendedor, @IdCliente,
      @IdDescuento, ISNULL(@Secuencia, 0), ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)), @FechaVencimiento,
      @Referencia, @IdAlmacen,
      @SubTotal, @Descuento, @Impuesto, @MontoExento, @Propina, @Total,
      @IdMoneda, ISNULL(@TasaCambio, 1), @Comentario, @ComentarioInterno, 'EM',
      @IdUsuarioAccion, GETDATE()
    )
    SELECT SCOPE_IDENTITY() AS IdDocumento
    RETURN
  END

  -- ── UPDATE ─────────────────────────────────────────────────
  IF @Accion = 'U'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.FacDocumentos WHERE IdDocumento = @IdDocumento AND Estado = 'I')
      RAISERROR('El documento no existe o no está en estado modificable (Pendiente).', 16, 1)
    UPDATE dbo.FacDocumentos SET
      IdCliente          = ISNULL(@IdCliente, IdCliente),
      IdVendedor         = @IdVendedor,
      IdDescuento        = @IdDescuento,
      FechaDocumento     = ISNULL(@FechaDocumento, FechaDocumento),
      FechaVencimiento   = @FechaVencimiento,
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
      RAISERROR('Solo se pueden anular documentos en estado Pendiente (I) o Posteado (P).', 16, 1)
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
      FechaEnvioDGII    = GETDATE(),
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
      alm.Descripcion           AS AlmacenNombre
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

    SELECT
      dd.*,
      um.Abreviatura  AS UnidadMedidaAbr,
      um.Nombre       AS UnidadMedidaNombre
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
      d.DocumentoNumero,
      d.TipoDocumentoCodigo,
      d.Secuencia,
      d.NCF,
      d.NCFVencimiento,
      d.FechaDocumento,
      d.IdDivision,      div.Nombre  AS DivisionNombre,
      d.IdSucursal,      suc.Nombre  AS SucursalNombre,
      d.IdPuntoEmision,  pe.Nombre   AS PuntoEmisionNombre,
      d.IdCaja,
      d.IdCliente,       c.Nombre    AS ClienteNombre,
      d.RNCCliente,
      d.IdVendedor,
      ven.Nombre + ISNULL(' ' + ven.Apellido, '') AS VendedorNombre,
      d.Referencia,
      d.IdAlmacen,       alm.Descripcion  AS AlmacenNombre,
      d.IdDescuento,     desc_.Nombre AS DescuentoNombre,
      d.SubTotal, d.Descuento, d.Impuesto, d.MontoExento,
      d.Propina, d.Total, d.TotalPagado, d.Saldo,
      d.IdMoneda,        mon.Codigo  AS MonedaCodigo,
      d.TasaCambio,
      d.Estado, d.Anulado,
      d.Comentario, d.ComentarioInterno,
      u.NombreUsuario    AS UsuarioNombre,
      t.Descripcion      AS TipoDocumentoNombre,
      t.Prefijo          AS TipoDocumentoPrefijo,
      n.Nombre           AS TipoNCFNombre,
      COUNT(*) OVER()    AS TotalRegistros
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
      AND (@SoloTipo             IS NULL OR d.TipoDocumentoCodigo = @SoloTipo)
      AND (@SoloEstado           IS NULL OR d.Estado = @SoloEstado)
      AND (@SecuenciaDesde       IS NULL OR d.Secuencia >= @SecuenciaDesde)
      AND (@SecuenciaHasta       IS NULL OR d.Secuencia <= @SecuenciaHasta)
    ORDER BY d.FechaDocumento DESC, d.IdDocumento DESC
    OFFSET @PageOffset ROWS FETCH NEXT @PageSize ROWS ONLY
    RETURN
  END

END
GO

-- ── 16. Recrear spEmitirFacturaPOS con todos los campos ──────
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
      @TipoDocCodigo    VARCHAR(10),
      @IdTipoDocFinal   INT

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

    -- Resolver Sucursal y Division
    SELECT @IdSucursal = pe.IdSucursal, @IdDivision = s.IdDivision
    FROM dbo.PuntosEmision pe
    JOIN dbo.Sucursales s ON s.IdSucursal = pe.IdSucursal
    WHERE pe.IdPuntoEmision = @IdPuntoEmision

    -- Fallback moneda desde tipo documento
    IF @IdMoneda IS NULL
      SELECT @IdMoneda = td.IdMoneda
      FROM dbo.FacDocumentosPOS p
      JOIN dbo.FacTiposDocumento td ON td.IdTipoDocumento = p.IdTipoDocumento
      WHERE p.IdDocumentoPOS = @IdDocumentoPOS

    -- Calcular totales con separación exento/gravado
    SELECT
      @SubTotal    = SUM(d.Cantidad * d.PrecioBase),
      @Descuento   = SUM(d.DescuentoLinea),
      @Impuesto    = SUM(CASE WHEN d.AplicaImpuesto = 1 AND d.PorcentajeImpuesto > 0
                              THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0)
                              ELSE 0 END),
      @MontoExento = SUM(CASE WHEN d.AplicaImpuesto = 0 OR d.PorcentajeImpuesto = 0
                              THEN d.Cantidad * d.PrecioBase - d.DescuentoLinea
                              ELSE 0 END),
      @Propina     = 0
    FROM dbo.FacDocumentoPOSDetalle d
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    SET @SubTotal    = ISNULL(@SubTotal, 0)
    SET @Descuento   = ISNULL(@Descuento, 0)
    SET @Impuesto    = ISNULL(@Impuesto, 0)
    SET @MontoExento = ISNULL(@MontoExento, 0)
    SET @Total       = @SubTotal - @Descuento + @Impuesto + @Propina

    -- Tipo de documento
    SELECT @IdTipoDocFinal = ISNULL(@IdTipoDocumento, p.IdTipoDocumento)
    FROM dbo.FacDocumentosPOS p
    WHERE p.IdDocumentoPOS = @IdDocumentoPOS

    IF @IdTipoDocFinal IS NULL
      SET @IdTipoDocFinal = (
        SELECT TOP 1 IdTipoDocumento FROM dbo.FacTiposDocumento
        WHERE Activo = 1 AND RowStatus = 1 ORDER BY IdTipoDocumento
      )

    SELECT @TipoDocCodigo = Codigo FROM dbo.FacTiposDocumento WHERE IdTipoDocumento = @IdTipoDocFinal

    -- Caja de la sesión
    IF @IdSesionCaja IS NOT NULL
      SELECT @IdCaja = IdCaja FROM dbo.FacCajasSesiones WHERE IdSesion = @IdSesionCaja AND Estado = 'AB'

    -- Próxima secuencia
    DECLARE @Secuencia INT
    SELECT @Secuencia = ISNULL(MAX(Secuencia), 0) + 1
    FROM dbo.FacDocumentos
    WHERE IdPuntoEmision = @IdPuntoEmision AND TipoDocumentoCodigo = @TipoDocCodigo

    -- Insertar documento definitivo
    DECLARE @IdDocumento INT

    INSERT INTO dbo.FacDocumentos (
      IdTipoDocumento, TipoDocumentoCodigo, IdDocumentoPOSOrigen,
      NCF, NCFVencimiento, IdTipoNCF, RNCCliente,
      IdPuntoEmision, IdDivision, IdSucursal, IdCaja, IdSesionCaja,
      IdUsuario, IdVendedor, IdCliente,
      IdDescuento, IdAlmacen, Referencia,
      Secuencia, FechaDocumento,
      SubTotal, Descuento, Impuesto, MontoExento, Propina, Total,
      IdMoneda, TasaCambio, Comentario, ComentarioInterno, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdTipoDocFinal, ISNULL(@TipoDocCodigo, 'FAC'), @IdDocumentoPOS,
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

    -- Copiar líneas con IdUnidadMedida y PorcentajeDescuento
    INSERT INTO dbo.FacDocumentoDetalle (
      IdDocumento, NumeroLinea,
      IdProducto, Codigo, Descripcion,
      Cantidad, Unidad, IdUnidadMedida, PrecioBase,
      PorcentajeImpuesto, AplicaImpuesto, AplicaPropina,
      DescuentoLinea, PorcentajeDescuento, ComentarioLinea,
      SubTotalLinea, ImpuestoLinea, TotalLinea
    )
    SELECT
      @IdDocumento,
      ROW_NUMBER() OVER (ORDER BY d.IdDetalle),
      d.IdProducto,
      d.Codigo,
      d.Descripcion,
      d.Cantidad,
      d.Unidad,
      p.IdUnidadMedida,
      d.PrecioBase,
      d.PorcentajeImpuesto,
      d.AplicaImpuesto,
      d.AplicaPropina,
      d.DescuentoLinea,
      CASE WHEN (d.Cantidad * d.PrecioBase) > 0
           THEN ROUND(d.DescuentoLinea / (d.Cantidad * d.PrecioBase) * 100, 2)
           ELSE 0 END,
      d.ComentarioLinea,
      d.Cantidad * d.PrecioBase,
      CASE WHEN d.AplicaImpuesto = 1 AND d.PorcentajeImpuesto > 0
           THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0)
           ELSE 0 END,
      (d.Cantidad * d.PrecioBase)
        + CASE WHEN d.AplicaImpuesto = 1 AND d.PorcentajeImpuesto > 0
               THEN d.Cantidad * d.PrecioBase * (d.PorcentajeImpuesto / 100.0)
               ELSE 0 END
        - d.DescuentoLinea
    FROM dbo.FacDocumentoPOSDetalle d
    LEFT JOIN dbo.Productos p ON p.IdProducto = d.IdProducto
    WHERE d.IdDocumentoPOS = @IdDocumentoPOS AND d.RowStatus = 1

    -- Registrar pagos
    INSERT INTO dbo.FacDocumentoPagos (
      IdDocumento, IdFormaPago, Monto, MontoBase,
      IdMoneda, TasaCambio, Referencia, Autorizacion,
      IdUsuarioCreacion, FechaCreacion
    )
    SELECT
      @IdDocumento,
      CAST(j.IdFormaPago           AS INT),
      CAST(j.Monto                 AS DECIMAL(18,2)),
      CAST(ISNULL(j.MontoBase, j.Monto) AS DECIMAL(18,2)),
      CAST(j.IdMoneda              AS INT),
      CAST(ISNULL(j.TasaCambio, 1) AS DECIMAL(18,6)),
      j.Referencia, j.Autorizacion,
      @IdUsuario, GETDATE()
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
    SELECT @TotalPagado = ISNULL(SUM(Monto), 0)
    FROM dbo.FacDocumentoPagos WHERE IdDocumento = @IdDocumento AND RowStatus = 1

    UPDATE dbo.FacDocumentos SET TotalPagado = @TotalPagado WHERE IdDocumento = @IdDocumento

    -- Movimientos de caja
    IF @IdSesionCaja IS NOT NULL
      INSERT INTO dbo.FacMovimientosCaja (
        IdSesion, IdDocumento, IdFormaPago,
        TipoMovimiento, TipoValor, Monto,
        IdUsuarioCreacion, FechaCreacion
      )
      SELECT @IdSesionCaja, @IdDocumento, p.IdFormaPago,
             'COBRO', f.TipoValor, p.Monto, @IdUsuario, GETDATE()
      FROM dbo.FacDocumentoPagos p
      JOIN dbo.FacFormasPago f ON f.IdFormaPago = p.IdFormaPago
      WHERE p.IdDocumento = @IdDocumento AND p.RowStatus = 1

    -- Marcar borrador procesado
    UPDATE dbo.FacDocumentosPOS SET
      RowStatus = 0, FechaModificacion = GETDATE(), IdUsuarioModif = @IdUsuario
    WHERE IdDocumentoPOS = @IdDocumentoPOS

    COMMIT TRANSACTION

    SELECT d.IdDocumento, d.DocumentoNumero, d.Secuencia,
           d.NCF, d.NCFVencimiento, d.TipoDocumentoCodigo,
           d.Total, d.TotalPagado, d.Estado
    FROM dbo.FacDocumentos d WHERE d.IdDocumento = @IdDocumento

  END TRY
  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
    RAISERROR(@ErrMsg, 16, 1)
  END CATCH
END
GO

-- ── 17. SP básico para maestro Vendedores ────────────────────
CREATE OR ALTER PROCEDURE dbo.spVendedoresCRUD
  @Accion           CHAR(1)       = 'L',
  @IdVendedor       INT           = NULL,
  @Codigo           VARCHAR(20)   = NULL,
  @Nombre           NVARCHAR(150) = NULL,
  @Apellido         NVARCHAR(150) = NULL,
  @IdUsuario        INT           = NULL,
  @Email            NVARCHAR(200) = NULL,
  @Telefono         VARCHAR(30)   = NULL,
  @ComisionPct      DECIMAL(5,2)  = 0,
  @Activo           BIT           = 1,
  @UsuarioAccion    INT           = NULL
AS
BEGIN
  SET NOCOUNT ON

  IF @Accion = 'L'
  BEGIN
    SELECT v.*, u.NombreUsuario AS UsuarioNombre
    FROM dbo.Vendedores v
    LEFT JOIN dbo.Usuarios u ON u.IdUsuario = v.IdUsuario
    WHERE v.RowStatus = 1 AND (@Activo IS NULL OR v.Activo = @Activo)
    ORDER BY v.Nombre
    RETURN
  END

  IF @Accion = 'G'
  BEGIN
    SELECT v.*, u.NombreUsuario AS UsuarioNombre
    FROM dbo.Vendedores v
    LEFT JOIN dbo.Usuarios u ON u.IdUsuario = v.IdUsuario
    WHERE v.IdVendedor = @IdVendedor AND v.RowStatus = 1
    RETURN
  END

  IF @Accion = 'I'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.Vendedores WHERE Codigo = @Codigo AND RowStatus = 1)
      RAISERROR('Ya existe un vendedor con ese código.', 16, 1)
    INSERT INTO dbo.Vendedores (Codigo, Nombre, Apellido, IdUsuario, Email, Telefono, ComisionPct, Activo, IdUsuarioCreacion)
    VALUES (@Codigo, @Nombre, @Apellido, @IdUsuario, @Email, @Telefono, ISNULL(@ComisionPct, 0), ISNULL(@Activo, 1), @UsuarioAccion)
    SELECT SCOPE_IDENTITY() AS IdVendedor
    RETURN
  END

  IF @Accion = 'U'
  BEGIN
    UPDATE dbo.Vendedores SET
      Codigo             = ISNULL(@Codigo,    Codigo),
      Nombre             = ISNULL(@Nombre,    Nombre),
      Apellido           = @Apellido,
      IdUsuario          = @IdUsuario,
      Email              = @Email,
      Telefono           = @Telefono,
      ComisionPct        = ISNULL(@ComisionPct, ComisionPct),
      Activo             = ISNULL(@Activo,    Activo),
      FechaModificacion  = GETDATE(),
      IdUsuarioModif     = @UsuarioAccion
    WHERE IdVendedor = @IdVendedor AND RowStatus = 1
    SELECT @IdVendedor AS IdVendedor
    RETURN
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Vendedores SET RowStatus = 0, FechaModificacion = GETDATE(), IdUsuarioModif = @UsuarioAccion
    WHERE IdVendedor = @IdVendedor
    RETURN
  END
END
GO

-- ── 18. Vistas para reportería ───────────────────────────────
CREATE OR ALTER VIEW dbo.vFacDocumentosReporte AS
SELECT
  d.IdDocumento,
  d.DocumentoNumero,
  d.TipoDocumentoCodigo,
  t.Descripcion          AS TipoDocumento,
  t.Prefijo              AS TipoDocumentoPrefijo,
  d.Secuencia,
  CAST(d.FechaCreacion AS DATETIME) AS FechaHoraEmision,
  d.FechaDocumento,
  d.NCF,
  d.NCFVencimiento,
  n.Nombre               AS TipoNCFNombre,
  n.Codigo               AS TipoNCFCodigo,
  d.RNCCliente,
  d.IdDivision,          div.Nombre           AS Division,
  d.IdSucursal,          suc.Nombre           AS Sucursal,
  d.IdPuntoEmision,      pe.Nombre            AS PuntoEmision,
  d.IdCaja,              caj.Descripcion      AS CajaPOS,
  d.IdSesionCaja,
  d.IdCliente,           c.Nombre             AS Cliente,
  d.IdVendedor,          ven.Nombre + ISNULL(' ' + ven.Apellido, '') AS Vendedor,
  d.IdUsuario,           u.NombreUsuario      AS Cajero,
  d.Referencia,
  d.IdAlmacen,           alm.Descripcion           AS Almacen,
  d.IdDescuento,         desc_.Nombre         AS GrupoDescuento,
  d.IdMoneda,            mon.Codigo           AS Moneda,
  d.TasaCambio,
  d.IdTipoDocumento,
  d.SubTotal,
  d.Descuento,
  d.Impuesto,
  d.MontoExento,
  d.Propina,
  d.Total,
  d.TotalPagado,
  d.Saldo,
  d.Comentario,
  d.ComentarioInterno,
  d.Estado,
  CASE d.Estado
    WHEN 'I' THEN 'Pendiente de Postear'
    WHEN 'P' THEN 'Posteado'
    WHEN 'N' THEN 'Anulado'
    ELSE d.Estado
  END AS EstadoNombre,
  d.MotivoAnulacion,
  d.FechaCreacion,
  d.FechaModificacion
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

CREATE OR ALTER VIEW dbo.vFacDocumentoDetalleReporte AS
SELECT
  dd.IdDocumentoDetalle,
  dd.IdDocumento,
  dd.NumeroLinea,
  dd.IdProducto,
  dd.Codigo,
  dd.Descripcion,
  dd.Cantidad,
  dd.Unidad,
  dd.IdUnidadMedida,     um.Abreviatura  AS UnidadMedidaAbr,
  um.Nombre              AS UnidadMedidaNombre,
  dd.PrecioBase,
  dd.PorcentajeImpuesto,
  dd.AplicaImpuesto,
  dd.Exento,
  dd.AplicaPropina,
  dd.DescuentoLinea,
  dd.PorcentajeDescuento,
  dd.ComentarioLinea,
  dd.SubTotalLinea,
  dd.ImpuestoLinea,
  dd.TotalLinea
FROM dbo.FacDocumentoDetalle dd
LEFT JOIN dbo.UnidadesMedida um ON um.IdUnidadMedida = dd.IdUnidadMedida
WHERE dd.RowStatus = 1;
GO

PRINT 'Script 169 aplicado correctamente.';
GO
