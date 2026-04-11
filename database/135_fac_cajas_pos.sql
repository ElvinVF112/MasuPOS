-- ============================================================
-- Script 135: Facturación — Cajas POS
-- Tablas:  dbo.FacCajasPOS
--          dbo.FacCajaPOSUsuario
-- Columna: dbo.Sucursales.TipoCierre
-- SP:      dbo.spFacCajasPOSCRUD (L/O/I/A/D/LU/U)
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- Columna TipoCierre en Sucursales
-- U=Por Usuario, T=Por Terminal/Caja, S=Por Sucursal
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Sucursales' AND COLUMN_NAME = 'TipoCierre')
  ALTER TABLE dbo.Sucursales ADD TipoCierre CHAR(1) NOT NULL DEFAULT 'T' CONSTRAINT CK_Sucursales_TipoCierre CHECK (TipoCierre IN ('U','T','S'));
GO

-- ============================================================
-- TABLE: FacCajasPOS
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacCajasPOS' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.FacCajasPOS (
    IdCajaPOS             INT            NOT NULL IDENTITY(1,1) CONSTRAINT PK_FacCajasPOS PRIMARY KEY,
    Descripcion           NVARCHAR(150)  NOT NULL,
    IdSucursal            INT            NOT NULL CONSTRAINT FK_FacCajasPOS_Sucursal FOREIGN KEY REFERENCES dbo.Sucursales(IdSucursal),
    IdPuntoEmision        INT            NULL CONSTRAINT FK_FacCajasPOS_PE FOREIGN KEY REFERENCES dbo.PuntosEmision(IdPuntoEmision),
    IdMoneda              INT            NULL CONSTRAINT FK_FacCajasPOS_Moneda FOREIGN KEY REFERENCES dbo.Monedas(IdMoneda),

    -- Estado de la caja
    CajaAbierta           BIT            NOT NULL DEFAULT 0,
    FechaApertura         DATETIME       NULL,
    FechaCierre           DATETIME       NULL,

    -- Fondo
    ManejaFondo           BIT            NOT NULL DEFAULT 0,
    FondoFijo             BIT            NOT NULL DEFAULT 0,
    FondoCaja             DECIMAL(18,2)  NOT NULL DEFAULT 0,

    -- Control
    Activo                BIT            NOT NULL DEFAULT 1,
    RowStatus             INT            NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME       NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion       INT            NULL,
    FechaModificacion     DATETIME       NULL,
    UsuarioModificacion   INT            NULL
  )
  PRINT 'TABLE FacCajasPOS CREATED'
END
GO

-- ============================================================
-- TABLE: FacCajaPOSUsuario
-- Usuarios asignados a cada caja
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'FacCajaPOSUsuario' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
  CREATE TABLE dbo.FacCajaPOSUsuario (
    IdCajaPOS      INT NOT NULL,
    IdUsuario      INT NOT NULL,
    Activo         BIT NOT NULL DEFAULT 1,
    FechaCreacion  DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion INT NULL,
    CONSTRAINT PK_FacCajaPOSUsuario PRIMARY KEY (IdCajaPOS, IdUsuario),
    CONSTRAINT FK_FacCajaPOSUsuario_Caja FOREIGN KEY (IdCajaPOS) REFERENCES dbo.FacCajasPOS(IdCajaPOS),
    CONSTRAINT FK_FacCajaPOSUsuario_Usr FOREIGN KEY (IdUsuario) REFERENCES dbo.Usuarios(IdUsuario)
  )
  PRINT 'TABLE FacCajaPOSUsuario CREATED'
END
GO

-- ============================================================
-- SP: spFacCajasPOSCRUD
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spFacCajasPOSCRUD
  @Accion               NVARCHAR(10)   = 'L',
  @IdCajaPOS            INT            = NULL,
  @Descripcion          NVARCHAR(150)  = NULL,
  @IdSucursal           INT            = NULL,
  @IdPuntoEmision       INT            = NULL,
  @IdMoneda             INT            = NULL,
  @ManejaFondo          BIT            = NULL,
  @FondoFijo            BIT            = NULL,
  @FondoCaja            DECIMAL(18,2)  = NULL,
  @Activo               BIT            = NULL,
  @UsuarioAccion        INT            = NULL,
  @UsuariosAsignados    NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  -- L: Listar (opcionalmente filtrar por sucursal)
  IF @Accion = 'L'
  BEGIN
    SELECT c.IdCajaPOS, c.Descripcion,
           c.IdSucursal, s.Nombre AS NombreSucursal, s.TipoCierre,
           c.IdPuntoEmision, pe.Nombre AS NombrePuntoEmision,
           c.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           c.CajaAbierta, c.FechaApertura, c.FechaCierre,
           c.ManejaFondo, c.FondoFijo, c.FondoCaja,
           c.Activo,
           c.FechaCreacion, c.UsuarioCreacion, c.FechaModificacion, c.UsuarioModificacion
    FROM   dbo.FacCajasPOS c
    JOIN   dbo.Sucursales s ON s.IdSucursal = c.IdSucursal
    LEFT JOIN dbo.PuntosEmision pe ON pe.IdPuntoEmision = c.IdPuntoEmision
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = c.IdMoneda
    WHERE  c.RowStatus = 1
      AND  (@IdSucursal IS NULL OR c.IdSucursal = @IdSucursal)
    ORDER BY s.Nombre, c.Descripcion
    RETURN
  END

  -- O: Obtener uno
  IF @Accion = 'O'
  BEGIN
    SELECT c.IdCajaPOS, c.Descripcion,
           c.IdSucursal, s.Nombre AS NombreSucursal, s.TipoCierre,
           c.IdPuntoEmision, pe.Nombre AS NombrePuntoEmision,
           c.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           c.CajaAbierta, c.FechaApertura, c.FechaCierre,
           c.ManejaFondo, c.FondoFijo, c.FondoCaja,
           c.Activo,
           c.FechaCreacion, c.UsuarioCreacion, c.FechaModificacion, c.UsuarioModificacion
    FROM   dbo.FacCajasPOS c
    JOIN   dbo.Sucursales s ON s.IdSucursal = c.IdSucursal
    LEFT JOIN dbo.PuntosEmision pe ON pe.IdPuntoEmision = c.IdPuntoEmision
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = c.IdMoneda
    WHERE  c.IdCajaPOS = @IdCajaPOS AND c.RowStatus = 1
    RETURN
  END

  -- I: Insertar
  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.FacCajasPOS (
      Descripcion, IdSucursal, IdPuntoEmision, IdMoneda,
      ManejaFondo, FondoFijo, FondoCaja,
      Activo, UsuarioCreacion
    ) VALUES (
      @Descripcion, @IdSucursal, @IdPuntoEmision, @IdMoneda,
      ISNULL(@ManejaFondo, 0), ISNULL(@FondoFijo, 0), ISNULL(@FondoCaja, 0),
      ISNULL(@Activo, 1), @UsuarioAccion
    )
    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spFacCajasPOSCRUD @Accion = 'O', @IdCajaPOS = @NewId
    RETURN
  END

  -- A: Actualizar
  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.FacCajasPOS
    SET    Descripcion       = ISNULL(@Descripcion, Descripcion),
           IdSucursal        = ISNULL(@IdSucursal, IdSucursal),
           IdPuntoEmision    = @IdPuntoEmision,
           IdMoneda          = @IdMoneda,
           ManejaFondo       = ISNULL(@ManejaFondo, ManejaFondo),
           FondoFijo         = ISNULL(@FondoFijo, FondoFijo),
           FondoCaja         = ISNULL(@FondoCaja, FondoCaja),
           Activo            = ISNULL(@Activo, Activo),
           FechaModificacion = GETDATE(),
           UsuarioModificacion = @UsuarioAccion
    WHERE  IdCajaPOS = @IdCajaPOS AND RowStatus = 1
    EXEC dbo.spFacCajasPOSCRUD @Accion = 'O', @IdCajaPOS = @IdCajaPOS
    RETURN
  END

  -- D: Soft-delete
  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacCajasPOS SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion WHERE IdCajaPOS = @IdCajaPOS
    DELETE FROM dbo.FacCajaPOSUsuario WHERE IdCajaPOS = @IdCajaPOS
    SELECT 'OK' AS Resultado
    RETURN
  END

  -- LU: Listar usuarios (asignados + disponibles)
  IF @Accion = 'LU'
  BEGIN
    SELECT u.IdUsuario, u.NombreUsuario, u.Nombres, u.Correo,
           CASE WHEN cu.IdCajaPOS IS NOT NULL AND cu.Activo = 1 THEN 1 ELSE 0 END AS Asignado
    FROM   dbo.Usuarios u
    LEFT JOIN dbo.FacCajaPOSUsuario cu ON cu.IdUsuario = u.IdUsuario AND cu.IdCajaPOS = @IdCajaPOS
    WHERE  u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres
    RETURN
  END

  -- U: Sincronizar usuarios asignados
  IF @Accion = 'U'
  BEGIN
    -- Desactivar todos
    UPDATE dbo.FacCajaPOSUsuario SET Activo = 0 WHERE IdCajaPOS = @IdCajaPOS

    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      -- Insertar nuevos
      INSERT INTO dbo.FacCajaPOSUsuario (IdCajaPOS, IdUsuario, UsuarioCreacion)
      SELECT @IdCajaPOS, TRY_CAST(value AS INT), @UsuarioAccion
      FROM   STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE  TRY_CAST(value AS INT) IS NOT NULL
        AND  NOT EXISTS (SELECT 1 FROM dbo.FacCajaPOSUsuario WHERE IdCajaPOS = @IdCajaPOS AND IdUsuario = TRY_CAST(value AS INT))

      -- Reactivar existentes
      UPDATE dbo.FacCajaPOSUsuario SET Activo = 1
      WHERE  IdCajaPOS = @IdCajaPOS
        AND  IdUsuario IN (SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@UsuariosAsignados, ',') WHERE TRY_CAST(value AS INT) IS NOT NULL)
    END

    EXEC dbo.spFacCajasPOSCRUD @Accion = 'LU', @IdCajaPOS = @IdCajaPOS
    RETURN
  END
END
GO

-- ============================================================
-- SEED
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM dbo.FacCajasPOS WHERE RowStatus = 1)
BEGIN
  DECLARE @IdSuc INT = (SELECT TOP 1 IdSucursal FROM dbo.Sucursales WHERE RowStatus = 1)
  DECLARE @IdPE INT = (SELECT TOP 1 IdPuntoEmision FROM dbo.PuntosEmision WHERE RowStatus = 1)
  IF @IdSuc IS NOT NULL
    INSERT INTO dbo.FacCajasPOS (Descripcion, IdSucursal, IdPuntoEmision, ManejaFondo, FondoFijo, FondoCaja, UsuarioCreacion)
    VALUES (N'CAJA 1', @IdSuc, @IdPE, 1, 0, 0, 1)
  PRINT 'SEED: Caja POS insertada'
END
GO

-- ============================================================
-- PERMISOS
-- ============================================================
DECLARE @IdMod INT = (SELECT TOP 1 IdModulo FROM dbo.Modulos WHERE Nombre LIKE '%Factur%' AND RowStatus = 1)
IF @IdMod IS NULL SET @IdMod = 1

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/facturacion/cajas-pos')
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, UsuarioCreacion) VALUES (@IdMod, N'Cajas POS', '/config/facturacion/cajas-pos', 1)
GO

SET QUOTED_IDENTIFIER ON;
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.facturacion.cajas-pos.view')
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Clave, Activo, UsuarioCreacion)
  SELECT p.IdPantalla, N'Cajas POS', 'config.facturacion.cajas-pos.view', 1, 1
  FROM dbo.Pantallas p WHERE p.Ruta = '/config/facturacion/cajas-pos' AND p.RowStatus = 1
GO

INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, p.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM dbo.Pantallas p WHERE p.Ruta = '/config/facturacion/cajas-pos' AND p.RowStatus = 1
  AND NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos rp WHERE rp.IdRol = 1 AND rp.IdPantalla = p.IdPantalla)
GO

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, UsuarioCreacion)
SELECT 1, pe.IdPermiso, 1, 1
FROM dbo.Permisos pe WHERE pe.Clave = 'config.facturacion.cajas-pos.view'
  AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos rp WHERE rp.IdRol = 1 AND rp.IdPermiso = pe.IdPermiso)
GO

PRINT '=== Script 135 completado ==='
GO
