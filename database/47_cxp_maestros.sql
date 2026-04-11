-- ═══════════════════════════════════════════════════════════════
-- TAREA 36 — CxP Maestros: TiposProveedor, CategoriasProveedor,
--            FKs en Terceros, SPs CRUD, Permisos
-- ═══════════════════════════════════════════════════════════════

USE DbMasuPOS;
GO

-- Table TiposProveedor
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.TiposProveedor') AND type = 'U')
BEGIN
  CREATE TABLE dbo.TiposProveedor (
    IdTipoProveedor     INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo              VARCHAR(10) NOT NULL,
    Nombre              VARCHAR(80) NOT NULL,
    Activo              BIT         NOT NULL DEFAULT 1,
    RowStatus           TINYINT     NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME    NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT         NULL,
    FechaModificacion   DATETIME    NULL,
    UsuarioModificacion INT         NULL,
    CONSTRAINT UQ_TipoProv_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.TiposProveedor (Codigo, Nombre, UsuarioCreacion)
  VALUES ('FAB','Fabricante',1),('DIS','Distribuidor',1),('IMP','Importador',1),('SER','Servicios',1),('OTR','Otro',1);
END
GO

-- Table CategoriasProveedor
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.CategoriasProveedor') AND type = 'U')
BEGIN
  CREATE TABLE dbo.CategoriasProveedor (
    IdCategoriaProveedor INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo               VARCHAR(10) NOT NULL,
    Nombre               VARCHAR(80) NOT NULL,
    Activo              BIT         NOT NULL DEFAULT 1,
    RowStatus           TINYINT     NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME    NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT         NULL,
    FechaModificacion   DATETIME    NULL,
    UsuarioModificacion INT         NULL,
    CONSTRAINT UQ_CategProv_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.CategoriasProveedor (Codigo, Nombre, UsuarioCreacion)
  VALUES ('A','Nivel A',1),('B','Nivel B',1),('C','Nivel C',1),('LOC','Local',1),('INT','Internacional',1);
END
GO

-- Add columns to Terceros if they don't exist
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Terceros') AND name = 'IdTipoProveedor')
  ALTER TABLE dbo.Terceros ADD IdTipoProveedor INT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Terceros') AND name = 'IdCategoriaProveedor')
  ALTER TABLE dbo.Terceros ADD IdCategoriaProveedor INT NULL;
GO

-- Add FKs to Terceros
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_TipoProv')
  ALTER TABLE dbo.Terceros
    ADD CONSTRAINT FK_Terceros_TipoProv FOREIGN KEY (IdTipoProveedor) REFERENCES dbo.TiposProveedor(IdTipoProveedor);
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Terceros_CategProv')
  ALTER TABLE dbo.Terceros
    ADD CONSTRAINT FK_Terceros_CategProv FOREIGN KEY (IdCategoriaProveedor) REFERENCES dbo.CategoriasProveedor(IdCategoriaProveedor);
GO

-- ─── SP dbo.spTiposProveedorCRUD ────────────────────────────────
IF OBJECT_ID('dbo.spTiposProveedorCRUD', 'P') IS NOT NULL DROP PROCEDURE dbo.spTiposProveedorCRUD;
GO
CREATE PROCEDURE dbo.spTiposProveedorCRUD
  @Accion             VARCHAR(1)   = 'L',
  @IdTipoProveedor    INT          = NULL,
  @Codigo             VARCHAR(10)  = NULL,
  @Nombre             VARCHAR(80)  = NULL,
  @Activo             BIT          = 1,
  @UsuarioCreacion    INT          = NULL,
  @UsuarioModificacion INT         = NULL,
  @IdSesion           INT          = NULL,
  @TokenSesion        NVARCHAR(128)= NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @Accion = 'L'
  BEGIN
    SELECT IdTipoProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.TiposProveedor
    WHERE RowStatus = 1
    ORDER BY Nombre;
  END
  ELSE IF @Accion = 'O'
  BEGIN
    SELECT IdTipoProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.TiposProveedor
    WHERE IdTipoProveedor = @IdTipoProveedor AND RowStatus = 1;
  END
  ELSE IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.TiposProveedor (Codigo, Nombre, Activo, UsuarioCreacion)
    VALUES (UPPER(LTRIM(RTRIM(@Codigo))), LTRIM(RTRIM(@Nombre)), ISNULL(@Activo, 1), @UsuarioCreacion);
    SELECT IdTipoProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.TiposProveedor WHERE IdTipoProveedor = SCOPE_IDENTITY();
  END
  ELSE IF @Accion = 'A'
  BEGIN
    UPDATE dbo.TiposProveedor SET
      Codigo              = UPPER(LTRIM(RTRIM(@Codigo))),
      Nombre              = LTRIM(RTRIM(@Nombre)),
      Activo              = ISNULL(@Activo, 1),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoProveedor = @IdTipoProveedor AND RowStatus = 1;
    SELECT IdTipoProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.TiposProveedor WHERE IdTipoProveedor = @IdTipoProveedor;
  END
  ELSE IF @Accion = 'D'
  BEGIN
    UPDATE dbo.TiposProveedor SET
      RowStatus           = 0,
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoProveedor = @IdTipoProveedor;
  END
END
GO

-- ─── SP dbo.spCategoriasProveedorCRUD ───────────────────────────
IF OBJECT_ID('dbo.spCategoriasProveedorCRUD', 'P') IS NOT NULL DROP PROCEDURE dbo.spCategoriasProveedorCRUD;
GO
CREATE PROCEDURE dbo.spCategoriasProveedorCRUD
  @Accion               VARCHAR(1)   = 'L',
  @IdCategoriaProveedor INT          = NULL,
  @Codigo               VARCHAR(10)  = NULL,
  @Nombre               VARCHAR(80)  = NULL,
  @Activo               BIT          = 1,
  @UsuarioCreacion      INT          = NULL,
  @UsuarioModificacion  INT          = NULL,
  @IdSesion             INT          = NULL,
  @TokenSesion          NVARCHAR(128)= NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @Accion = 'L'
  BEGIN
    SELECT IdCategoriaProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.CategoriasProveedor
    WHERE RowStatus = 1
    ORDER BY Nombre;
  END
  ELSE IF @Accion = 'O'
  BEGIN
    SELECT IdCategoriaProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.CategoriasProveedor
    WHERE IdCategoriaProveedor = @IdCategoriaProveedor AND RowStatus = 1;
  END
  ELSE IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.CategoriasProveedor (Codigo, Nombre, Activo, UsuarioCreacion)
    VALUES (UPPER(LTRIM(RTRIM(@Codigo))), LTRIM(RTRIM(@Nombre)), ISNULL(@Activo, 1), @UsuarioCreacion);
    SELECT IdCategoriaProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.CategoriasProveedor WHERE IdCategoriaProveedor = SCOPE_IDENTITY();
  END
  ELSE IF @Accion = 'A'
  BEGIN
    UPDATE dbo.CategoriasProveedor SET
      Codigo              = UPPER(LTRIM(RTRIM(@Codigo))),
      Nombre              = LTRIM(RTRIM(@Nombre)),
      Activo              = ISNULL(@Activo, 1),
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdCategoriaProveedor = @IdCategoriaProveedor AND RowStatus = 1;
    SELECT IdCategoriaProveedor, Codigo, Nombre, Activo, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.CategoriasProveedor WHERE IdCategoriaProveedor = @IdCategoriaProveedor;
  END
  ELSE IF @Accion = 'D'
  BEGIN
    UPDATE dbo.CategoriasProveedor SET
      RowStatus           = 0,
      Activo              = 0,
      FechaModificacion   = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdCategoriaProveedor = @IdCategoriaProveedor;
  END
END
GO

-- ─── Permissions ────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxp.suppliers.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Proveedores', 'Acceso a la pantalla de Proveedores', 'config.cxp.suppliers.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxp.supplier-types.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Tipos de Proveedores', 'Acceso a la pantalla de Tipos de Proveedores', 'config.cxp.supplier-types.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END

IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.cxp.supplier-categories.view')
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, UsuarioCreacion)
  SELECT TOP 1 IdPantalla, 'Categorias de Proveedores', 'Acceso a la pantalla de Categorias de Proveedores', 'config.cxp.supplier-categories.view', 1, 1
  FROM dbo.Pantallas WHERE RowStatus = 1 ORDER BY IdPantalla;
END
GO

-- Asignar permisos al rol 1
INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, p.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM dbo.Permisos p
WHERE p.Clave IN (
  'config.cxp.suppliers.view',
  'config.cxp.supplier-types.view',
  'config.cxp.supplier-categories.view'
)
AND NOT EXISTS (
  SELECT 1 FROM dbo.RolPantallaPermisos rp
  WHERE rp.IdRol = 1 AND rp.IdPantalla = p.IdPantalla
);
GO
