-- ============================================================
-- Script 157: FacDocumentoPagos
-- Líneas de cobro por documento definitivo
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacDocumentoPagos')
BEGIN
  CREATE TABLE dbo.FacDocumentoPagos (
    IdPago            INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IdDocumento       INT           NOT NULL REFERENCES dbo.FacDocumentos(IdDocumento),
    IdFormaPago       INT           NOT NULL REFERENCES dbo.FacFormasPago(IdFormaPago),

    -- Monto en moneda del documento
    Monto             DECIMAL(18,2) NOT NULL DEFAULT 0,
    -- Monto en moneda base (DOP) — para consolidados
    MontoBase         DECIMAL(18,2) NOT NULL DEFAULT 0,
    IdMoneda          INT           NULL,
    TasaCambio        DECIMAL(18,6) NOT NULL DEFAULT 1,

    Referencia        NVARCHAR(100) NULL,   -- # cheque, # autorización tarjeta, etc.
    Autorizacion      NVARCHAR(100) NULL,

    -- Auditoría
    RowStatus         TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion INT           NULL,
    FechaModificacion DATETIME      NULL,
    IdUsuarioModif    INT           NULL
  )
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacDocumentoPagos_IdDocumento')
  CREATE INDEX IX_FacDocumentoPagos_IdDocumento
    ON dbo.FacDocumentoPagos (IdDocumento)
GO

-- ── SP spFacDocumentoPagosCRUD ──────────────────────────────
IF OBJECT_ID('dbo.spFacDocumentoPagosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spFacDocumentoPagosCRUD
GO

CREATE PROCEDURE dbo.spFacDocumentoPagosCRUD
  @Accion           CHAR(1),      -- I=Insert D=Delete L=ListByDoc
  @IdPago           INT         = NULL,
  @IdDocumento      INT         = NULL,
  @IdFormaPago      INT         = NULL,
  @Monto            DECIMAL(18,2) = 0,
  @MontoBase        DECIMAL(18,2) = 0,
  @IdMoneda         INT         = NULL,
  @TasaCambio       DECIMAL(18,6) = 1,
  @Referencia       NVARCHAR(100) = NULL,
  @Autorizacion     NVARCHAR(100) = NULL,
  @IdUsuarioAccion  INT         = NULL
AS
BEGIN
  SET NOCOUNT ON

  IF @Accion = 'I'
  BEGIN
    -- Solo permitir insertar si documento está en EM
    IF NOT EXISTS (SELECT 1 FROM dbo.FacDocumentos WHERE IdDocumento = @IdDocumento AND Estado = 'EM' AND Anulado = 0)
      RAISERROR('El documento no está en estado modificable.', 16, 1)

    INSERT INTO dbo.FacDocumentoPagos (
      IdDocumento, IdFormaPago, Monto, MontoBase,
      IdMoneda, TasaCambio, Referencia, Autorizacion,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdDocumento, @IdFormaPago, @Monto, ISNULL(@MontoBase, @Monto),
      @IdMoneda, ISNULL(@TasaCambio, 1), @Referencia, @Autorizacion,
      @IdUsuarioAccion, GETDATE()
    )

    -- Actualizar TotalPagado en el documento
    UPDATE dbo.FacDocumentos SET
      TotalPagado = (
        SELECT ISNULL(SUM(Monto), 0)
        FROM dbo.FacDocumentoPagos
        WHERE IdDocumento = @IdDocumento AND RowStatus = 1
      ),
      FechaModificacion = GETDATE()
    WHERE IdDocumento = @IdDocumento

    SELECT SCOPE_IDENTITY() AS IdPago
    RETURN
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacDocumentoPagos SET
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      IdUsuarioModif = @IdUsuarioAccion
    WHERE IdPago = @IdPago

    -- Recalcular TotalPagado
    UPDATE dbo.FacDocumentos SET
      TotalPagado = (
        SELECT ISNULL(SUM(Monto), 0)
        FROM dbo.FacDocumentoPagos
        WHERE IdDocumento = @IdDocumento AND RowStatus = 1
      ),
      FechaModificacion = GETDATE()
    WHERE IdDocumento = @IdDocumento

    SELECT @IdPago AS IdPago
    RETURN
  END

  IF @Accion = 'L'
  BEGIN
    SELECT
      p.IdPago,
      p.IdDocumento,
      p.IdFormaPago,
      f.Descripcion     AS FormaPagoNombre,
      f.TipoValor,
      f.TipoValor607,
      p.Monto,
      p.MontoBase,
      p.IdMoneda,
      p.TasaCambio,
      p.Referencia,
      p.Autorizacion
    FROM dbo.FacDocumentoPagos p
    JOIN dbo.FacFormasPago f ON f.IdFormaPago = p.IdFormaPago
    WHERE p.IdDocumento = @IdDocumento AND p.RowStatus = 1
    ORDER BY p.IdPago
    RETURN
  END

END
GO
