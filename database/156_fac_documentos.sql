-- ============================================================
-- Script 156: FacDocumentos + FacDocumentoDetalle
-- Documentos definitivos (facturas, NC, cotizaciones, conduces, pedidos)
-- ============================================================

-- ── 1. FacDocumentos ────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacDocumentos')
BEGIN
  CREATE TABLE dbo.FacDocumentos (
    IdDocumento           INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,

    -- Tipo y origen
    IdTipoDocumento       INT           NOT NULL,  -- FK FacTiposDocumento
    TipoDocumentoCodigo   VARCHAR(10)   NOT NULL,  -- FAC / NC / COT / PED / CON (desnorm.)
    IdDocumentoOrigen     INT           NULL REFERENCES dbo.FacDocumentos(IdDocumento),
    IdDocumentoPOSOrigen  INT           NULL REFERENCES dbo.FacDocumentosPOS(IdDocumentoPOS),

    -- Identificación fiscal
    NCF                   VARCHAR(19)   NULL,       -- B0100000001 etc.
    IdTipoNCF             INT           NULL,       -- FK CatalogoNCF
    RNCCliente            VARCHAR(11)   NULL,

    -- Cabecera operativa
    IdPuntoEmision        INT           NOT NULL,
    IdCaja                INT           NULL,       -- FK FacCajasPOS
    IdSesionCaja          INT           NULL,       -- FK FacCajasSesiones (script 158)
    IdUsuario             INT           NOT NULL,
    IdCliente             INT           NULL,
    NombreCliente         NVARCHAR(200) NULL,       -- desnorm. para historial

    -- Numeración
    Secuencia             INT           NOT NULL DEFAULT 0,

    -- Fechas
    FechaDocumento        DATE          NOT NULL,
    FechaVencimiento      DATE          NULL,

    -- Totales desnormalizados
    SubTotal              DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descuento             DECIMAL(18,2) NOT NULL DEFAULT 0,
    Impuesto              DECIMAL(18,2) NOT NULL DEFAULT 0,
    Propina               DECIMAL(18,2) NOT NULL DEFAULT 0,
    Total                 DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalPagado           DECIMAL(18,2) NOT NULL DEFAULT 0,
    Saldo                 AS (Total - TotalPagado) PERSISTED,

    -- Moneda
    IdMoneda              INT           NULL,
    TasaCambio            DECIMAL(18,6) NOT NULL DEFAULT 1,

    -- Estado del documento
    -- EM=Emitido(editable), EN=EnviadoDGII, CE=Cerrado, AN=Anulado
    Estado                CHAR(2)       NOT NULL DEFAULT 'EM'
      CONSTRAINT CK_FacDocumentos_Estado CHECK (Estado IN ('EM','EN','CE','AN')),

    Anulado               BIT           NOT NULL DEFAULT 0,
    FechaAnulacion        DATETIME      NULL,
    MotivoAnulacion       NVARCHAR(500) NULL,
    IdUsuarioAnulacion    INT           NULL,

    FechaEnvioDGII        DATETIME      NULL,

    -- Notas
    Comentario            NVARCHAR(500) NULL,

    -- Auditoría
    RowStatus             TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion     INT           NULL,
    FechaModificacion     DATETIME      NULL,
    IdUsuarioModif        INT           NULL
  )
END
GO

-- ── 2. FacDocumentoDetalle ──────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacDocumentoDetalle')
BEGIN
  CREATE TABLE dbo.FacDocumentoDetalle (
    IdDocumentoDetalle    INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IdDocumento           INT           NOT NULL REFERENCES dbo.FacDocumentos(IdDocumento),
    NumeroLinea           INT           NOT NULL DEFAULT 1,

    IdProducto            INT           NULL,
    Codigo                VARCHAR(50)   NULL,
    Descripcion           NVARCHAR(300) NOT NULL,
    Cantidad              DECIMAL(18,4) NOT NULL DEFAULT 1,
    Unidad                VARCHAR(20)   NULL,
    PrecioBase            DECIMAL(18,2) NOT NULL DEFAULT 0,
    PorcentajeImpuesto    DECIMAL(8,2)  NOT NULL DEFAULT 0,
    AplicaImpuesto        BIT           NOT NULL DEFAULT 1,
    AplicaPropina         BIT           NOT NULL DEFAULT 0,
    DescuentoLinea        DECIMAL(18,2) NOT NULL DEFAULT 0,
    ComentarioLinea       NVARCHAR(300) NULL,

    -- Totales por línea (desnorm.)
    SubTotalLinea         DECIMAL(18,2) NOT NULL DEFAULT 0,
    ImpuestoLinea         DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalLinea            DECIMAL(18,2) NOT NULL DEFAULT 0,

    RowStatus             TINYINT       NOT NULL DEFAULT 1
  )
END
GO

-- ── 3. Índices ──────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_PuntoEmision_Fecha')
  CREATE INDEX IX_FacDocumentos_PuntoEmision_Fecha
    ON dbo.FacDocumentos (IdPuntoEmision, FechaDocumento)
    INCLUDE (Estado, Anulado, Total, TipoDocumentoCodigo)
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentos_NCF')
  CREATE INDEX IX_FacDocumentos_NCF ON dbo.FacDocumentos (NCF)
  WHERE NCF IS NOT NULL
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentoDetalle_IdDocumento')
  CREATE INDEX IX_FacDocumentoDetalle_IdDocumento
    ON dbo.FacDocumentoDetalle (IdDocumento)
GO

-- ── 4. SP spFacDocumentosCRUD ────────────────────────────────
IF OBJECT_ID('dbo.spFacDocumentosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spFacDocumentosCRUD
GO

CREATE PROCEDURE dbo.spFacDocumentosCRUD
  @Accion                CHAR(1),          -- I=Insert U=Update A=Anular E=EnviarDGII L=List G=Get
  @IdDocumento           INT            = NULL,
  @IdTipoDocumento       INT            = NULL,
  @TipoDocumentoCodigo   VARCHAR(10)    = NULL,
  @IdDocumentoOrigen     INT            = NULL,
  @IdDocumentoPOSOrigen  INT            = NULL,
  @NCF                   VARCHAR(19)    = NULL,
  @IdTipoNCF             INT            = NULL,
  @RNCCliente            VARCHAR(11)    = NULL,
  @IdPuntoEmision        INT            = NULL,
  @IdCaja                INT            = NULL,
  @IdSesionCaja          INT            = NULL,
  @IdUsuario             INT            = NULL,
  @IdCliente             INT            = NULL,
  @NombreCliente         NVARCHAR(200)  = NULL,
  @Secuencia             INT            = NULL,
  @FechaDocumento        DATE           = NULL,
  @FechaVencimiento      DATE           = NULL,
  @SubTotal              DECIMAL(18,2)  = 0,
  @Descuento             DECIMAL(18,2)  = 0,
  @Impuesto              DECIMAL(18,2)  = 0,
  @Propina               DECIMAL(18,2)  = 0,
  @Total                 DECIMAL(18,2)  = 0,
  @IdMoneda              INT            = NULL,
  @TasaCambio            DECIMAL(18,6)  = 1,
  @Comentario            NVARCHAR(500)  = NULL,
  @MotivoAnulacion       NVARCHAR(500)  = NULL,
  @IdUsuarioAccion       INT            = NULL,
  -- Filtros para L
  @FechaDesde            DATE           = NULL,
  @FechaHasta            DATE           = NULL,
  @SoloTipo              VARCHAR(10)    = NULL,
  @SoloEstado            CHAR(2)        = NULL,
  @PageSize              INT            = 100,
  @PageOffset            INT            = 0
AS
BEGIN
  SET NOCOUNT ON

  -- INSERT
  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.FacDocumentos (
      IdTipoDocumento, TipoDocumentoCodigo, IdDocumentoOrigen, IdDocumentoPOSOrigen,
      NCF, IdTipoNCF, RNCCliente,
      IdPuntoEmision, IdCaja, IdSesionCaja, IdUsuario, IdCliente, NombreCliente,
      Secuencia, FechaDocumento, FechaVencimiento,
      SubTotal, Descuento, Impuesto, Propina, Total,
      IdMoneda, TasaCambio, Comentario, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdTipoDocumento, @TipoDocumentoCodigo, @IdDocumentoOrigen, @IdDocumentoPOSOrigen,
      @NCF, @IdTipoNCF, @RNCCliente,
      @IdPuntoEmision, @IdCaja, @IdSesionCaja, @IdUsuario, @IdCliente, @NombreCliente,
      ISNULL(@Secuencia, 0), ISNULL(@FechaDocumento, CAST(GETDATE() AS DATE)), @FechaVencimiento,
      @SubTotal, @Descuento, @Impuesto, @Propina, @Total,
      @IdMoneda, ISNULL(@TasaCambio, 1), @Comentario, 'EM',
      @IdUsuarioAccion, GETDATE()
    )
    SELECT SCOPE_IDENTITY() AS IdDocumento
    RETURN
  END

  -- UPDATE (solo si Estado = EM)
  IF @Accion = 'U'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.FacDocumentos WHERE IdDocumento = @IdDocumento AND Estado = 'EM' AND Anulado = 0)
      RAISERROR('El documento no existe o no está en estado modificable (EM).', 16, 1)

    UPDATE dbo.FacDocumentos SET
      IdCliente         = ISNULL(@IdCliente, IdCliente),
      NombreCliente     = ISNULL(@NombreCliente, NombreCliente),
      FechaDocumento    = ISNULL(@FechaDocumento, FechaDocumento),
      FechaVencimiento  = @FechaVencimiento,
      NCF               = ISNULL(@NCF, NCF),
      RNCCliente        = ISNULL(@RNCCliente, RNCCliente),
      SubTotal          = @SubTotal,
      Descuento         = @Descuento,
      Impuesto          = @Impuesto,
      Propina           = @Propina,
      Total             = @Total,
      TasaCambio        = ISNULL(@TasaCambio, TasaCambio),
      Comentario        = @Comentario,
      FechaModificacion = GETDATE(),
      IdUsuarioModif    = @IdUsuarioAccion
    WHERE IdDocumento = @IdDocumento

    SELECT @IdDocumento AS IdDocumento
    RETURN
  END

  -- ANULAR
  IF @Accion = 'A'
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.FacDocumentos WHERE IdDocumento = @IdDocumento AND Estado IN ('EM') AND Anulado = 0)
      RAISERROR('Solo se pueden anular documentos en estado Emitido (EM).', 16, 1)

    UPDATE dbo.FacDocumentos SET
      Anulado            = 1,
      Estado             = 'AN',
      FechaAnulacion     = GETDATE(),
      MotivoAnulacion    = @MotivoAnulacion,
      IdUsuarioAnulacion = @IdUsuarioAccion,
      FechaModificacion  = GETDATE(),
      IdUsuarioModif     = @IdUsuarioAccion
    WHERE IdDocumento = @IdDocumento

    SELECT @IdDocumento AS IdDocumento
    RETURN
  END

  -- ENVIAR DGII (cierra edición)
  IF @Accion = 'E'
  BEGIN
    UPDATE dbo.FacDocumentos SET
      Estado            = 'EN',
      FechaEnvioDGII    = GETDATE(),
      FechaModificacion = GETDATE(),
      IdUsuarioModif    = @IdUsuarioAccion
    WHERE IdDocumento = @IdDocumento AND Estado = 'EM' AND Anulado = 0

    SELECT @IdDocumento AS IdDocumento
    RETURN
  END

  -- GET por ID
  IF @Accion = 'G'
  BEGIN
    SELECT
      d.*,
      t.Descripcion   AS TipoDocumentoNombre,
      c.Nombre        AS ClienteNombre,
      c.DocumentoIdentificacion AS ClienteDocumento,
      pe.Nombre       AS PuntoEmisionNombre,
      u.NombreUsuario AS UsuarioNombre,
      n.Nombre        AS TipoNCFNombre
    FROM dbo.FacDocumentos d
    LEFT JOIN dbo.FacTiposDocumento t  ON t.IdTipoDocumento = d.IdTipoDocumento
    LEFT JOIN dbo.Terceros c           ON c.IdTercero = d.IdCliente
    LEFT JOIN dbo.PuntosEmision pe     ON pe.IdPuntoEmision = d.IdPuntoEmision
    LEFT JOIN dbo.Usuarios u           ON u.IdUsuario = d.IdUsuario
    LEFT JOIN dbo.CatalogoNCF n        ON n.IdCatalogoNCF = d.IdTipoNCF
    WHERE d.IdDocumento = @IdDocumento

    SELECT * FROM dbo.FacDocumentoDetalle
    WHERE IdDocumento = @IdDocumento AND RowStatus = 1
    ORDER BY NumeroLinea
    RETURN
  END

  -- LIST (con paginación)
  IF @Accion = 'L'
  BEGIN
    SELECT
      d.IdDocumento,
      d.TipoDocumentoCodigo,
      d.Secuencia,
      d.NCF,
      d.FechaDocumento,
      d.NombreCliente,
      d.RNCCliente,
      d.SubTotal, d.Descuento, d.Impuesto, d.Propina, d.Total,
      d.TotalPagado, d.Saldo,
      d.Estado, d.Anulado,
      d.IdPuntoEmision,
      pe.Nombre AS PuntoEmisionNombre,
      u.NombreUsuario AS UsuarioNombre,
      t.Descripcion AS TipoDocumentoNombre,
      COUNT(*) OVER() AS TotalRegistros
    FROM dbo.FacDocumentos d
    LEFT JOIN dbo.FacTiposDocumento t  ON t.IdTipoDocumento = d.IdTipoDocumento
    LEFT JOIN dbo.PuntosEmision pe     ON pe.IdPuntoEmision = d.IdPuntoEmision
    LEFT JOIN dbo.Usuarios u           ON u.IdUsuario = d.IdUsuario
    WHERE d.RowStatus = 1
      AND (@IdPuntoEmision IS NULL OR d.IdPuntoEmision = @IdPuntoEmision)
      AND (@FechaDesde     IS NULL OR d.FechaDocumento >= @FechaDesde)
      AND (@FechaHasta     IS NULL OR d.FechaDocumento <= @FechaHasta)
      AND (@SoloTipo       IS NULL OR d.TipoDocumentoCodigo = @SoloTipo)
      AND (@SoloEstado     IS NULL OR d.Estado = @SoloEstado)
    ORDER BY d.FechaDocumento DESC, d.IdDocumento DESC
    OFFSET @PageOffset ROWS FETCH NEXT @PageSize ROWS ONLY
    RETURN
  END

END
GO
