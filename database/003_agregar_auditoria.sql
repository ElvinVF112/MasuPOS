-- ============================================================
-- Script: 003_agregar_auditoria.sql
-- Propósito: Agregar campos de auditoría faltantes a tablas
-- ============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. Categorias - Faltan: RowStatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Categorias' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.Categorias ADD RowStatus BIT NOT NULL CONSTRAINT DF_Categorias_RowStatus DEFAULT 1;
  PRINT 'Categorias: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Categorias' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.Categorias ADD UsuarioCreacion INT NULL;
  PRINT 'Categorias: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Categorias' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.Categorias ADD FechaModificacion DATETIME NULL;
  PRINT 'Categorias: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Categorias' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.Categorias ADD UsuarioModificacion INT NULL;
  PRINT 'Categorias: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 2. EstadosCuenta - Faltan: FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EstadosCuenta' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.EstadosCuenta ADD FechaModificacion DATETIME NULL;
  PRINT 'EstadosCuenta: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EstadosCuenta' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.EstadosCuenta ADD UsuarioModificacion INT NULL;
  PRINT 'EstadosCuenta: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 3. ListaPrecioUsuarios - Faltan: UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ListaPrecioUsuarios' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.ListaPrecioUsuarios ADD UsuarioCreacion INT NULL;
  PRINT 'ListaPrecioUsuarios: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ListaPrecioUsuarios' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.ListaPrecioUsuarios ADD FechaModificacion DATETIME NULL;
  PRINT 'ListaPrecioUsuarios: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ListaPrecioUsuarios' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.ListaPrecioUsuarios ADD UsuarioModificacion INT NULL;
  PRINT 'ListaPrecioUsuarios: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 4. MonedaTasas - Faltan todos los campos: RowStatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonedaTasas' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.MonedaTasas ADD RowStatus BIT NOT NULL CONSTRAINT DF_MonedaTasas_RowStatus DEFAULT 1;
  PRINT 'MonedaTasas: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonedaTasas' AND COLUMN_NAME = 'FechaCreacion')
BEGIN
  ALTER TABLE dbo.MonedaTasas ADD FechaCreacion DATETIME NOT NULL CONSTRAINT DF_MonedaTasas_FechaCreacion DEFAULT GETDATE();
  PRINT 'MonedaTasas: FechaCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonedaTasas' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.MonedaTasas ADD UsuarioCreacion INT NULL;
  PRINT 'MonedaTasas: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonedaTasas' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.MonedaTasas ADD FechaModificacion DATETIME NULL;
  PRINT 'MonedaTasas: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MonedaTasas' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.MonedaTasas ADD UsuarioModificacion INT NULL;
  PRINT 'MonedaTasas: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 5. OrdenesMovimientos - Faltan: FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OrdenesMovimientos' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.OrdenesMovimientos ADD FechaModificacion DATETIME NULL;
  PRINT 'OrdenesMovimientos: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OrdenesMovimientos' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.OrdenesMovimientos ADD UsuarioModificacion INT NULL;
  PRINT 'OrdenesMovimientos: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 6. Productos - Faltan: RowStatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Productos' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.Productos ADD RowStatus BIT NOT NULL CONSTRAINT DF_Productos_RowStatus DEFAULT 1;
  PRINT 'Productos: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Productos' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.Productos ADD UsuarioCreacion INT NULL;
  PRINT 'Productos: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Productos' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.Productos ADD FechaModificacion DATETIME NULL;
  PRINT 'Productos: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Productos' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.Productos ADD UsuarioModificacion INT NULL;
  PRINT 'Productos: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 7. RolCamposVisibilidad - Faltan todos: RowStatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolCamposVisibilidad' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.RolCamposVisibilidad ADD RowStatus BIT NOT NULL CONSTRAINT DF_RolCamposVisibilidad_RowStatus DEFAULT 1;
  PRINT 'RolCamposVisibilidad: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolCamposVisibilidad' AND COLUMN_NAME = 'FechaCreacion')
BEGIN
  ALTER TABLE dbo.RolCamposVisibilidad ADD FechaCreacion DATETIME NOT NULL CONSTRAINT DF_RolCamposVisibilidad_FechaCreacion DEFAULT GETDATE();
  PRINT 'RolCamposVisibilidad: FechaCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolCamposVisibilidad' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.RolCamposVisibilidad ADD UsuarioCreacion INT NULL;
  PRINT 'RolCamposVisibilidad: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolCamposVisibilidad' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.RolCamposVisibilidad ADD FechaModificacion DATETIME NULL;
  PRINT 'RolCamposVisibilidad: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolCamposVisibilidad' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.RolCamposVisibilidad ADD UsuarioModificacion INT NULL;
  PRINT 'RolCamposVisibilidad: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 8. RolPantallaPermisos - Faltan todos: RowStatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolPantallaPermisos' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.RolPantallaPermisos ADD RowStatus BIT NOT NULL CONSTRAINT DF_RolPantallaPermisos_RowStatus DEFAULT 1;
  PRINT 'RolPantallaPermisos: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolPantallaPermisos' AND COLUMN_NAME = 'FechaCreacion')
BEGIN
  ALTER TABLE dbo.RolPantallaPermisos ADD FechaCreacion DATETIME NOT NULL CONSTRAINT DF_RolPantallaPermisos_FechaCreacion DEFAULT GETDATE();
  PRINT 'RolPantallaPermisos: FechaCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolPantallaPermisos' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.RolPantallaPermisos ADD UsuarioCreacion INT NULL;
  PRINT 'RolPantallaPermisos: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolPantallaPermisos' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.RolPantallaPermisos ADD FechaModificacion DATETIME NULL;
  PRINT 'RolPantallaPermisos: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RolPantallaPermisos' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.RolPantallaPermisos ADD UsuarioModificacion INT NULL;
  PRINT 'RolPantallaPermisos: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 9. SesionesActivas - Faltan todos: RowStatus, FechaCreacion, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- (Esta tabla es transaccional, pero agregamos por consistencia)
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SesionesActivas' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.SesionesActivas ADD RowStatus BIT NOT NULL CONSTRAINT DF_SesionesActivas_RowStatus DEFAULT 1;
  PRINT 'SesionesActivas: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SesionesActivas' AND COLUMN_NAME = 'FechaCreacion')
BEGIN
  ALTER TABLE dbo.SesionesActivas ADD FechaCreacion DATETIME NOT NULL CONSTRAINT DF_SesionesActivas_FechaCreacion DEFAULT GETDATE();
  PRINT 'SesionesActivas: FechaCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SesionesActivas' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.SesionesActivas ADD UsuarioCreacion INT NULL;
  PRINT 'SesionesActivas: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SesionesActivas' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.SesionesActivas ADD FechaModificacion DATETIME NULL;
  PRINT 'SesionesActivas: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SesionesActivas' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.SesionesActivas ADD UsuarioModificacion INT NULL;
  PRINT 'SesionesActivas: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 10. TiposProducto - Faltan: RowStatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TiposProducto' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.TiposProducto ADD RowStatus BIT NOT NULL CONSTRAINT DF_TiposProducto_RowStatus DEFAULT 1;
  PRINT 'TiposProducto: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TiposProducto' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.TiposProducto ADD UsuarioCreacion INT NULL;
  PRINT 'TiposProducto: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TiposProducto' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.TiposProducto ADD FechaModificacion DATETIME NULL;
  PRINT 'TiposProducto: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TiposProducto' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.TiposProducto ADD UsuarioModificacion INT NULL;
  PRINT 'TiposProducto: UsuarioModificacion agregado';
END;
GO

-- ============================================================
-- 11. UnidadesMedida - Faltan: RowStatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnidadesMedida' AND COLUMN_NAME = 'RowStatus')
BEGIN
  ALTER TABLE dbo.UnidadesMedida ADD RowStatus BIT NOT NULL CONSTRAINT DF_UnidadesMedida_RowStatus DEFAULT 1;
  PRINT 'UnidadesMedida: RowStatus agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnidadesMedida' AND COLUMN_NAME = 'UsuarioCreacion')
BEGIN
  ALTER TABLE dbo.UnidadesMedida ADD UsuarioCreacion INT NULL;
  PRINT 'UnidadesMedida: UsuarioCreacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnidadesMedida' AND COLUMN_NAME = 'FechaModificacion')
BEGIN
  ALTER TABLE dbo.UnidadesMedida ADD FechaModificacion DATETIME NULL;
  PRINT 'UnidadesMedida: FechaModificacion agregado';
END;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'UnidadesMedida' AND COLUMN_NAME = 'UsuarioModificacion')
BEGIN
  ALTER TABLE dbo.UnidadesMedida ADD UsuarioModificacion INT NULL;
  PRINT 'UnidadesMedida: UsuarioModificacion agregado';
END;
GO

PRINT '============================================================';
PRINT 'Auditoría agregada a todas las tablas';
PRINT '============================================================';
