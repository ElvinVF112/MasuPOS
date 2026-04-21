-- ============================================================
-- Script 158: FacCajasSesiones
-- Turno/sesión por cajero — una apertura → un cierre
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacCajasSesiones')
BEGIN
  CREATE TABLE dbo.FacCajasSesiones (
    IdSesion          INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    IdCaja            INT           NOT NULL REFERENCES dbo.FacCajasPOS(IdCajaPOS),
    IdUsuario         INT           NOT NULL,
    FechaApertura     DATETIME      NOT NULL DEFAULT GETDATE(),
    FechaCierre       DATETIME      NULL,
    FondoInicial      DECIMAL(18,2) NOT NULL DEFAULT 0,
    -- AB=Abierta, CE=Cerrada
    Estado            CHAR(2)       NOT NULL DEFAULT 'AB'
      CONSTRAINT CK_FacCajasSesiones_Estado CHECK (Estado IN ('AB','CE')),
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

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacCajasSesiones_Caja_Estado')
  CREATE INDEX IX_FacCajasSesiones_Caja_Estado
    ON dbo.FacCajasSesiones (IdCaja, Estado)
GO

-- ── SP spFacCajasSesionesCRUD ───────────────────────────────
IF OBJECT_ID('dbo.spFacCajasSesionesCRUD', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spFacCajasSesionesCRUD
GO

CREATE PROCEDURE dbo.spFacCajasSesionesCRUD
  @Accion           CHAR(1),      -- A=Abrir C=Cerrar G=GetActiva L=List
  @IdSesion         INT         = NULL,
  @IdCaja           INT         = NULL,
  @IdUsuario        INT         = NULL,
  @FondoInicial     DECIMAL(18,2) = 0,
  @Observaciones    NVARCHAR(500) = NULL,
  @IdUsuarioAccion  INT         = NULL
AS
BEGIN
  SET NOCOUNT ON

  -- ABRIR sesión
  IF @Accion = 'A'
  BEGIN
    -- Validar que no haya sesión abierta para esta caja
    IF EXISTS (SELECT 1 FROM dbo.FacCajasSesiones WHERE IdCaja = @IdCaja AND Estado = 'AB' AND RowStatus = 1)
      RAISERROR('Ya existe una sesión abierta para esta caja.', 16, 1)

    INSERT INTO dbo.FacCajasSesiones (
      IdCaja, IdUsuario, FechaApertura, FondoInicial, Estado,
      IdUsuarioCreacion, FechaCreacion
    ) VALUES (
      @IdCaja, @IdUsuario, GETDATE(), ISNULL(@FondoInicial, 0), 'AB',
      @IdUsuarioAccion, GETDATE()
    )

    -- Actualizar estado de la caja
    UPDATE dbo.FacCajasPOS SET
      CajaAbierta = 1, FechaApertura = GETDATE()
    WHERE IdCajaPOS = @IdCaja

    SELECT SCOPE_IDENTITY() AS IdSesion
    RETURN
  END

  -- CERRAR sesión (solo marca — el cuadre lo hace spFacCierreCaja)
  IF @Accion = 'C'
  BEGIN
    UPDATE dbo.FacCajasSesiones SET
      Estado = 'CE',
      FechaCierre = GETDATE(),
      Observaciones = @Observaciones,
      FechaModificacion = GETDATE(),
      IdUsuarioModif = @IdUsuarioAccion
    WHERE IdSesion = @IdSesion AND Estado = 'AB'

    UPDATE dbo.FacCajasPOS SET
      CajaAbierta = 0, FechaCierre = GETDATE()
    WHERE IdCajaPOS = (SELECT IdCaja FROM dbo.FacCajasSesiones WHERE IdSesion = @IdSesion)

    SELECT @IdSesion AS IdSesion
    RETURN
  END

  -- GET sesión activa de una caja
  IF @Accion = 'G'
  BEGIN
    SELECT TOP 1
      s.*,
      c.Descripcion AS CajaNombre,
      u.NombreUsuario AS UsuarioNombre
    FROM dbo.FacCajasSesiones s
    JOIN dbo.FacCajasPOS c ON c.IdCajaPOS = s.IdCaja
    LEFT JOIN dbo.Usuarios u ON u.IdUsuario = s.IdUsuario
    WHERE s.IdCaja = @IdCaja AND s.Estado = 'AB' AND s.RowStatus = 1
    ORDER BY s.FechaApertura DESC
    RETURN
  END

  -- LIST sesiones de una caja
  IF @Accion = 'L'
  BEGIN
    SELECT
      s.*,
      c.Descripcion AS CajaNombre,
      u.NombreUsuario AS UsuarioNombre
    FROM dbo.FacCajasSesiones s
    JOIN dbo.FacCajasPOS c ON c.IdCajaPOS = s.IdCaja
    LEFT JOIN dbo.Usuarios u ON u.IdUsuario = s.IdUsuario
    WHERE (@IdCaja IS NULL OR s.IdCaja = @IdCaja)
      AND s.RowStatus = 1
    ORDER BY s.FechaApertura DESC
    RETURN
  END

END
GO
