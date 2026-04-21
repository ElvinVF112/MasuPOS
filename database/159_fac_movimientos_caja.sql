-- ============================================================
-- Script 159: FacMovimientosCaja
-- Cada transacción de entrada/salida en una sesión de caja
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacMovimientosCaja')
BEGIN
  CREATE TABLE dbo.FacMovimientosCaja (
    IdMovimiento      INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IdSesion          INT           NOT NULL REFERENCES dbo.FacCajasSesiones(IdSesion),
    IdDocumento       INT           NULL REFERENCES dbo.FacDocumentos(IdDocumento),
    IdFormaPago       INT           NULL REFERENCES dbo.FacFormasPago(IdFormaPago),

    -- COBRO=entrada por venta, DEVOLUCION=salida por NC,
    -- APERTURA=fondo inicial, DESEMBOLSO=salida con justificación, AJUSTE=corrección
    TipoMovimiento    VARCHAR(12)   NOT NULL
      CONSTRAINT CK_FacMovCaja_Tipo CHECK (TipoMovimiento IN ('COBRO','DEVOLUCION','APERTURA','DESEMBOLSO','AJUSTE')),

    -- TipoValor desnorm. para agrupación en cierre (EF/TC/CH/OV/VC/NC...)
    TipoValor         VARCHAR(5)    NULL,

    -- Positivo=entrada, Negativo=salida
    Monto             DECIMAL(18,2) NOT NULL DEFAULT 0,

    Motivo            NVARCHAR(300) NULL,   -- obligatorio en DESEMBOLSO y AJUSTE
    Referencia        NVARCHAR(100) NULL,

    -- Auditoría
    RowStatus         TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion INT           NULL,
    FechaModificacion DATETIME      NULL,
    IdUsuarioModif    INT           NULL
  )
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacMovimientosCaja_Sesion')
  CREATE INDEX IX_FacMovimientosCaja_Sesion
    ON dbo.FacMovimientosCaja (IdSesion)
    INCLUDE (TipoValor, Monto, TipoMovimiento)
GO

-- ── SP spFacMovimientosCajaCRUD ─────────────────────────────
IF OBJECT_ID('dbo.spFacMovimientosCajaCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spFacMovimientosCajaCRUD
GO

CREATE PROCEDURE dbo.spFacMovimientosCajaCRUD
  @Accion           CHAR(1),        -- I=Insert L=ListBySesion R=ResumenBySesion
  @IdMovimiento     INT           = NULL,
  @IdSesion         INT           = NULL,
  @IdDocumento      INT           = NULL,
  @IdFormaPago      INT           = NULL,
  @TipoMovimiento   VARCHAR(12)   = NULL,
  @TipoValor        VARCHAR(5)    = NULL,
  @Monto            DECIMAL(18,2) = 0,
  @Motivo           NVARCHAR(300) = NULL,
  @Referencia       NVARCHAR(100) = NULL,
  @IdUsuarioAccion  INT           = NULL
AS
BEGIN
  SET NOCOUNT ON

  IF @Accion = 'I'
  BEGIN
    -- DESEMBOLSO y AJUSTE requieren Motivo
    IF @TipoMovimiento IN ('DESEMBOLSO','AJUSTE') AND ISNULL(@Motivo, '') = ''
      RAISERROR('Se requiere un Motivo para DESEMBOLSO y AJUSTE.', 16, 1)

    -- Sesión debe estar abierta
    IF NOT EXISTS (SELECT 1 FROM dbo.FacCajasSesiones WHERE IdSesion = @IdSesion AND Estado = 'AB' AND RowStatus = 1)
      RAISERROR('La sesión de caja no está abierta.', 16, 1)

    INSERT INTO dbo.FacMovimientosCaja (
      IdSesion, IdDocumento, IdFormaPago,
      TipoMovimiento, TipoValor, Monto,
      Motivo, Referencia,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdSesion, @IdDocumento, @IdFormaPago,
      @TipoMovimiento, @TipoValor, @Monto,
      @Motivo, @Referencia,
      @IdUsuarioAccion, GETDATE()
    )

    SELECT SCOPE_IDENTITY() AS IdMovimiento
    RETURN
  END

  -- Lista todos los movimientos de una sesión
  IF @Accion = 'L'
  BEGIN
    SELECT
      m.*,
      f.Descripcion AS FormaPagoNombre,
      d.Secuencia   AS DocumentoSecuencia,
      d.NCF         AS DocumentoNCF
    FROM dbo.FacMovimientosCaja m
    LEFT JOIN dbo.FacFormasPago f  ON f.IdFormaPago = m.IdFormaPago
    LEFT JOIN dbo.FacDocumentos d  ON d.IdDocumento = m.IdDocumento
    WHERE m.IdSesion = @IdSesion AND m.RowStatus = 1
    ORDER BY m.FechaCreacion
    RETURN
  END

  -- Resumen por TipoValor para el cierre (lo que el sistema calculó)
  IF @Accion = 'R'
  BEGIN
    SELECT
      TipoValor,
      SUM(Monto)                                    AS TotalSistema,
      SUM(CASE WHEN TipoMovimiento = 'COBRO'      THEN Monto ELSE 0 END) AS TotalCobros,
      SUM(CASE WHEN TipoMovimiento = 'DEVOLUCION' THEN Monto ELSE 0 END) AS TotalDevoluciones,
      SUM(CASE WHEN TipoMovimiento = 'APERTURA'   THEN Monto ELSE 0 END) AS TotalApertura,
      SUM(CASE WHEN TipoMovimiento = 'DESEMBOLSO' THEN Monto ELSE 0 END) AS TotalDesembolsos,
      SUM(CASE WHEN TipoMovimiento = 'AJUSTE'     THEN Monto ELSE 0 END) AS TotalAjustes
    FROM dbo.FacMovimientosCaja
    WHERE IdSesion = @IdSesion AND RowStatus = 1
    GROUP BY TipoValor
    ORDER BY TipoValor
    RETURN
  END

END
GO
