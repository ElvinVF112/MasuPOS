-- ============================================================
-- Script 160: FacCierresCaja
-- Cuadre ciego por sesión de caja
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacCierresCaja')
BEGIN
  CREATE TABLE dbo.FacCierresCaja (
    IdCierre              INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IdSesion              INT           NOT NULL REFERENCES dbo.FacCajasSesiones(IdSesion),

    -- ── Lo que el sistema calculó (de FacMovimientosCaja) ──
    SistEfectivo          DECIMAL(18,2) NOT NULL DEFAULT 0,
    SistTarjeta           DECIMAL(18,2) NOT NULL DEFAULT 0,
    SistCheque            DECIMAL(18,2) NOT NULL DEFAULT 0,
    SistTransferencia     DECIMAL(18,2) NOT NULL DEFAULT 0,
    SistCredito           DECIMAL(18,2) NOT NULL DEFAULT 0,
    SistOtros             DECIMAL(18,2) NOT NULL DEFAULT 0,
    SistTotal             AS (SistEfectivo + SistTarjeta + SistCheque + SistTransferencia + SistCredito + SistOtros) PERSISTED,

    -- ── Lo que el cajero declaró (ingreso ciego) ──
    DeclEfectivo          DECIMAL(18,2) NOT NULL DEFAULT 0,
    DeclTarjeta           DECIMAL(18,2) NOT NULL DEFAULT 0,
    DeclCheque            DECIMAL(18,2) NOT NULL DEFAULT 0,
    DeclTransferencia     DECIMAL(18,2) NOT NULL DEFAULT 0,
    DeclCredito           DECIMAL(18,2) NOT NULL DEFAULT 0,
    DeclOtros             DECIMAL(18,2) NOT NULL DEFAULT 0,
    DeclTotal             AS (DeclEfectivo + DeclTarjeta + DeclCheque + DeclTransferencia + DeclCredito + DeclOtros) PERSISTED,

    -- ── Diferencias (Sistema - Declarado; negativo = faltante) ──
    DifEfectivo           AS (SistEfectivo      - DeclEfectivo)      PERSISTED,
    DifTarjeta            AS (SistTarjeta       - DeclTarjeta)       PERSISTED,
    DifCheque             AS (SistCheque        - DeclCheque)        PERSISTED,
    DifTransferencia      AS (SistTransferencia - DeclTransferencia) PERSISTED,
    DifCredito            AS (SistCredito       - DeclCredito)       PERSISTED,
    DifOtros              AS (SistOtros         - DeclOtros)         PERSISTED,

    -- ── Distribución del efectivo ──
    EfectivoRetenido      DECIMAL(18,2) NOT NULL DEFAULT 0,  -- queda en caja (fondo próx. turno)
    EfectivoADepositar    DECIMAL(18,2) NOT NULL DEFAULT 0,  -- va a caja central / tesorería

    Observaciones         NVARCHAR(500) NULL,

    -- Aprobación por supervisor
    Aprobado              BIT           NOT NULL DEFAULT 0,
    FechaAprobacion       DATETIME      NULL,
    IdUsuarioAprobacion   INT           NULL,

    -- Auditoría
    RowStatus             TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion     INT           NULL,
    FechaModificacion     DATETIME      NULL,
    IdUsuarioModif        INT           NULL
  )
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacCierresCaja_IdSesion')
  CREATE UNIQUE INDEX IX_FacCierresCaja_IdSesion
    ON dbo.FacCierresCaja (IdSesion)
GO

-- ── SP spFacCierreCaja ──────────────────────────────────────
-- Recibe los valores declarados por el cajero,
-- calcula los del sistema, guarda diferencias,
-- cierra la sesión y genera movimiento a tesorería.
IF OBJECT_ID('dbo.spFacCierreCaja', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spFacCierreCaja
GO

CREATE PROCEDURE dbo.spFacCierreCaja
  @Accion               CHAR(1),       -- G=GuardarCierre A=Aprobar L=List
  @IdSesion             INT          = NULL,
  @IdCierre             INT          = NULL,
  -- Valores declarados por el cajero
  @DeclEfectivo         DECIMAL(18,2) = 0,
  @DeclTarjeta          DECIMAL(18,2) = 0,
  @DeclCheque           DECIMAL(18,2) = 0,
  @DeclTransferencia    DECIMAL(18,2) = 0,
  @DeclCredito          DECIMAL(18,2) = 0,
  @DeclOtros            DECIMAL(18,2) = 0,
  -- Distribución efectivo
  @EfectivoRetenido     DECIMAL(18,2) = 0,
  @EfectivoADepositar   DECIMAL(18,2) = 0,
  @Observaciones        NVARCHAR(500) = NULL,
  @IdUsuarioAccion      INT          = NULL
AS
BEGIN
  SET NOCOUNT ON

  -- GUARDAR CIERRE CIEGO
  IF @Accion = 'G'
  BEGIN
    IF EXISTS (SELECT 1 FROM dbo.FacCierresCaja WHERE IdSesion = @IdSesion AND RowStatus = 1)
      RAISERROR('Ya existe un cierre para esta sesión.', 16, 1)

    -- Calcular totales del sistema desde FacMovimientosCaja
    DECLARE
      @SistEfectivo      DECIMAL(18,2) = 0,
      @SistTarjeta       DECIMAL(18,2) = 0,
      @SistCheque        DECIMAL(18,2) = 0,
      @SistTransferencia DECIMAL(18,2) = 0,
      @SistCredito       DECIMAL(18,2) = 0,
      @SistOtros         DECIMAL(18,2) = 0

    SELECT
      @SistEfectivo      = SUM(CASE WHEN TipoValor = 'EF' THEN Monto ELSE 0 END),
      @SistTarjeta       = SUM(CASE WHEN TipoValor = 'TC' THEN Monto ELSE 0 END),
      @SistCheque        = SUM(CASE WHEN TipoValor = 'CH' THEN Monto ELSE 0 END),
      @SistTransferencia = SUM(CASE WHEN TipoValor = 'OV' THEN Monto ELSE 0 END),
      @SistCredito       = SUM(CASE WHEN TipoValor = 'VC' THEN Monto ELSE 0 END),
      @SistOtros         = SUM(CASE WHEN TipoValor NOT IN ('EF','TC','CH','OV','VC') THEN Monto ELSE 0 END)
    FROM dbo.FacMovimientosCaja
    WHERE IdSesion = @IdSesion AND RowStatus = 1

    INSERT INTO dbo.FacCierresCaja (
      IdSesion,
      SistEfectivo, SistTarjeta, SistCheque, SistTransferencia, SistCredito, SistOtros,
      DeclEfectivo, DeclTarjeta, DeclCheque, DeclTransferencia, DeclCredito, DeclOtros,
      EfectivoRetenido, EfectivoADepositar,
      Observaciones,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdSesion,
      ISNULL(@SistEfectivo, 0), ISNULL(@SistTarjeta, 0), ISNULL(@SistCheque, 0),
      ISNULL(@SistTransferencia, 0), ISNULL(@SistCredito, 0), ISNULL(@SistOtros, 0),
      @DeclEfectivo, @DeclTarjeta, @DeclCheque, @DeclTransferencia, @DeclCredito, @DeclOtros,
      @EfectivoRetenido, @EfectivoADepositar,
      @Observaciones,
      @IdUsuarioAccion, GETDATE()
    )

    DECLARE @IdCierreNuevo INT = SCOPE_IDENTITY()

    -- Cerrar la sesión
    EXEC dbo.spFacCajasSesionesCRUD
      @Accion = 'C',
      @IdSesion = @IdSesion,
      @IdUsuarioAccion = @IdUsuarioAccion

    -- Registrar movimiento en tesorería si hay efectivo a depositar
    IF @EfectivoADepositar > 0
    BEGIN
      INSERT INTO dbo.TesMovimientos (
        TipoMovimiento, IdCierre, Monto, Descripcion,
        IdUsuarioCreacion, FechaCreacion
      ) VALUES (
        'DEPOSITO_CAJA', @IdCierreNuevo, @EfectivoADepositar,
        'Depósito de efectivo desde cierre de caja sesión #' + CAST(@IdSesion AS VARCHAR),
        @IdUsuarioAccion, GETDATE()
      )
    END

    SELECT @IdCierreNuevo AS IdCierre
    RETURN
  END

  -- APROBAR CIERRE (supervisor)
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.FacCierresCaja SET
      Aprobado            = 1,
      FechaAprobacion     = GETDATE(),
      IdUsuarioAprobacion = @IdUsuarioAccion,
      FechaModificacion   = GETDATE(),
      IdUsuarioModif      = @IdUsuarioAccion
    WHERE IdCierre = @IdCierre AND RowStatus = 1

    SELECT @IdCierre AS IdCierre
    RETURN
  END

  -- LIST cierres
  IF @Accion = 'L'
  BEGIN
    SELECT
      c.*,
      s.IdCaja,
      s.IdUsuario,
      s.FechaApertura,
      s.FechaCierre,
      ca.Descripcion   AS CajaNombre,
      u.NombreUsuario  AS UsuarioNombre
    FROM dbo.FacCierresCaja c
    JOIN dbo.FacCajasSesiones s ON s.IdSesion = c.IdSesion
    JOIN dbo.FacCajasPOS ca     ON ca.IdCajaPOS = s.IdCaja
    LEFT JOIN dbo.Usuarios u    ON u.IdUsuario = s.IdUsuario
    WHERE c.RowStatus = 1
    ORDER BY c.FechaCreacion DESC
    RETURN
  END

END
GO
