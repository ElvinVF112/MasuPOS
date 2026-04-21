-- ============================================================
-- Script 161: TesMovimientos + TesDepositosBancarios + TesCuentasBancarias
-- Caja central / Tesorería
-- ============================================================

-- ── 1. TesCuentasBancarias ──────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TesCuentasBancarias')
BEGIN
  CREATE TABLE dbo.TesCuentasBancarias (
    IdCuenta          INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    Descripcion       NVARCHAR(150) NOT NULL,
    NumeroCuenta      VARCHAR(30)   NULL,
    Banco             NVARCHAR(100) NULL,
    IdMoneda          INT           NULL,
    SaldoInicial      DECIMAL(18,2) NOT NULL DEFAULT 0,
    Activo            BIT           NOT NULL DEFAULT 1,
    RowStatus         TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion INT           NULL
  )
END
GO

-- ── 2. TesMovimientos ───────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TesMovimientos')
BEGIN
  CREATE TABLE dbo.TesMovimientos (
    IdMovimiento      INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,

    -- DEPOSITO_CAJA = efectivo de cierre → tesorería
    -- DEPOSITO_BANCO = tesorería → cuenta bancaria
    -- EGRESO = pago desde tesorería
    -- AJUSTE = corrección manual
    TipoMovimiento    VARCHAR(20)   NOT NULL
      CONSTRAINT CK_TesMovimientos_Tipo CHECK (
        TipoMovimiento IN ('DEPOSITO_CAJA','DEPOSITO_BANCO','EGRESO','AJUSTE')
      ),

    IdCierre          INT           NULL REFERENCES dbo.FacCierresCaja(IdCierre),
    IdDeposito        INT           NULL,   -- FK TesDepositosBancarios (se actualiza al depositar)
    IdCuenta          INT           NULL REFERENCES dbo.TesCuentasBancarias(IdCuenta),

    Monto             DECIMAL(18,2) NOT NULL DEFAULT 0,
    Descripcion       NVARCHAR(300) NULL,
    Referencia        NVARCHAR(100) NULL,
    FechaMovimiento   DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),

    -- Auditoría
    RowStatus         TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion INT           NULL,
    FechaModificacion DATETIME      NULL,
    IdUsuarioModif    INT           NULL
  )
END
GO

-- ── 3. TesDepositosBancarios ────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TesDepositosBancarios')
BEGIN
  CREATE TABLE dbo.TesDepositosBancarios (
    IdDeposito        INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IdCuenta          INT           NOT NULL REFERENCES dbo.TesCuentasBancarias(IdCuenta),
    FechaDeposito     DATE          NOT NULL,
    MontoDepositado   DECIMAL(18,2) NOT NULL DEFAULT 0,
    Referencia        NVARCHAR(100) NULL,
    Comprobante       NVARCHAR(200) NULL,
    Observaciones     NVARCHAR(500) NULL,

    -- Auditoría
    RowStatus         TINYINT       NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME      NOT NULL DEFAULT GETDATE(),
    IdUsuarioCreacion INT           NULL,
    FechaModificacion DATETIME      NULL,
    IdUsuarioModif    INT           NULL
  )
END
GO

-- FK diferida: TesMovimientos.IdDeposito → TesDepositosBancarios
IF NOT EXISTS (
  SELECT 1 FROM sys.foreign_keys
  WHERE name = 'FK_TesMovimientos_Deposito'
)
  ALTER TABLE dbo.TesMovimientos
    ADD CONSTRAINT FK_TesMovimientos_Deposito
    FOREIGN KEY (IdDeposito) REFERENCES dbo.TesDepositosBancarios(IdDeposito)
GO

-- Índices
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TesMovimientos_Fecha')
  CREATE INDEX IX_TesMovimientos_Fecha
    ON dbo.TesMovimientos (FechaMovimiento)
    INCLUDE (TipoMovimiento, Monto)
GO

-- ── SP spTesMovimientosCRUD ─────────────────────────────────
IF OBJECT_ID('dbo.spTesMovimientosCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spTesMovimientosCRUD
GO

CREATE PROCEDURE dbo.spTesMovimientosCRUD
  @Accion           CHAR(1),        -- I=Insert D=RegistrarDeposito L=List S=Saldo
  @IdMovimiento     INT           = NULL,
  @TipoMovimiento   VARCHAR(20)   = NULL,
  @IdCierre         INT           = NULL,
  @IdCuenta         INT           = NULL,
  @Monto            DECIMAL(18,2) = 0,
  @Descripcion      NVARCHAR(300) = NULL,
  @Referencia       NVARCHAR(100) = NULL,
  @FechaMovimiento  DATE          = NULL,
  -- Para depósito bancario
  @FechaDeposito    DATE          = NULL,
  @Comprobante      NVARCHAR(200) = NULL,
  @Observaciones    NVARCHAR(500) = NULL,
  @IdUsuarioAccion  INT           = NULL
AS
BEGIN
  SET NOCOUNT ON

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.TesMovimientos (
      TipoMovimiento, IdCierre, IdCuenta, Monto,
      Descripcion, Referencia, FechaMovimiento,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @TipoMovimiento, @IdCierre, @IdCuenta, @Monto,
      @Descripcion, @Referencia,
      ISNULL(@FechaMovimiento, CAST(GETDATE() AS DATE)),
      @IdUsuarioAccion, GETDATE()
    )
    SELECT SCOPE_IDENTITY() AS IdMovimiento
    RETURN
  END

  -- Registrar depósito bancario y enlazar movimientos pendientes
  IF @Accion = 'D'
  BEGIN
    INSERT INTO dbo.TesDepositosBancarios (
      IdCuenta, FechaDeposito, MontoDepositado,
      Referencia, Comprobante, Observaciones,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdCuenta, ISNULL(@FechaDeposito, CAST(GETDATE() AS DATE)), @Monto,
      @Referencia, @Comprobante, @Observaciones,
      @IdUsuarioAccion, GETDATE()
    )
    DECLARE @IdDepNuevo INT = SCOPE_IDENTITY()

    -- Insertar movimiento DEPOSITO_BANCO
    INSERT INTO dbo.TesMovimientos (
      TipoMovimiento, IdCuenta, IdDeposito, Monto,
      Descripcion, Referencia, FechaMovimiento,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      'DEPOSITO_BANCO', @IdCuenta, @IdDepNuevo, @Monto,
      'Depósito bancario', @Referencia,
      ISNULL(@FechaDeposito, CAST(GETDATE() AS DATE)),
      @IdUsuarioAccion, GETDATE()
    )

    SELECT @IdDepNuevo AS IdDeposito
    RETURN
  END

  -- Saldo disponible en tesorería (DEPOSITO_CAJA - DEPOSITO_BANCO - EGRESO)
  IF @Accion = 'S'
  BEGIN
    SELECT
      SUM(CASE WHEN TipoMovimiento = 'DEPOSITO_CAJA'  THEN Monto ELSE 0 END) AS TotalIngresado,
      SUM(CASE WHEN TipoMovimiento IN ('DEPOSITO_BANCO','EGRESO') THEN Monto ELSE 0 END) AS TotalSalidas,
      SUM(CASE
        WHEN TipoMovimiento = 'DEPOSITO_CAJA'                  THEN  Monto
        WHEN TipoMovimiento IN ('DEPOSITO_BANCO','EGRESO')      THEN -Monto
        ELSE 0
      END) AS SaldoDisponible
    FROM dbo.TesMovimientos
    WHERE RowStatus = 1
    RETURN
  END

  IF @Accion = 'L'
  BEGIN
    SELECT
      m.*,
      c.Descripcion AS CuentaNombre,
      ci.IdSesion   AS CierreIdSesion
    FROM dbo.TesMovimientos m
    LEFT JOIN dbo.TesCuentasBancarias c ON c.IdCuenta = m.IdCuenta
    LEFT JOIN dbo.FacCierresCaja ci     ON ci.IdCierre = m.IdCierre
    WHERE m.RowStatus = 1
    ORDER BY m.FechaMovimiento DESC, m.IdMovimiento DESC
    RETURN
  END

END
GO
