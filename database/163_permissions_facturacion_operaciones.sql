-- ============================================================
-- Script 163: Pantalla + Permisos — Facturación / Operaciones
-- Agrega la pantalla de Operaciones (Mantenimiento) al módulo
-- de Facturación y asigna permisos a todos los roles.
-- ============================================================

-- 1. Insertar pantalla si no existe
IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE AccionVista = 'facturacion.operaciones.view')
BEGIN
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, AccionVista, Orden, Activo, RowStatus, FechaCreacion)
  VALUES (
    12,                               -- Módulo Facturación
    'Operaciones (Mantenimiento)',
    '/facturacion/operaciones',
    'facturacion.operaciones.view',
    60,
    1, 1, GETDATE()
  )
END
GO

-- 2. Asignar a todos los roles (IdRol 1=Admin, 2=Gerente, 3=Usuario, 4=Camarero)
--    Admin y Gerente → acceso completo (editar + anular + devolucion + reimprimir)
--    Usuario → solo ver + reimprimir
--    Camarero → sin acceso

DECLARE @IdPantalla INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE AccionVista = 'facturacion.operaciones.view')

-- Rol 1 (Administrador) — acceso total
IF NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos WHERE IdRol = 1 AND IdPantalla = @IdPantalla)
  INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint, RowStatus, FechaCreacion)
  VALUES (1, @IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1, 1, GETDATE())
ELSE
  UPDATE dbo.RolPantallaPermisos SET AccessEnabled=1, CanView=1, CanEdit=1, CanDelete=1, CanCancel=1, CanPrint=1
  WHERE IdRol = 1 AND IdPantalla = @IdPantalla

-- Rol 2 (Gerente) — acceso total
IF NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos WHERE IdRol = 2 AND IdPantalla = @IdPantalla)
  INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint, RowStatus, FechaCreacion)
  VALUES (2, @IdPantalla, 1, 0, 1, 0, 1, 1, 1, 1, 1, GETDATE())
ELSE
  UPDATE dbo.RolPantallaPermisos SET AccessEnabled=1, CanView=1, CanEdit=1, CanCancel=1, CanPrint=1
  WHERE IdRol = 2 AND IdPantalla = @IdPantalla

-- Rol 3 (Usuario) — solo ver y reimprimir
IF NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos WHERE IdRol = 3 AND IdPantalla = @IdPantalla)
  INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint, RowStatus, FechaCreacion)
  VALUES (3, @IdPantalla, 1, 0, 0, 0, 1, 0, 0, 1, 1, GETDATE())
ELSE
  UPDATE dbo.RolPantallaPermisos SET AccessEnabled=1, CanView=1, CanEdit=0, CanCancel=0, CanPrint=1
  WHERE IdRol = 3 AND IdPantalla = @IdPantalla

-- Rol 4 (Camarero) — sin acceso
IF NOT EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos WHERE IdRol = 4 AND IdPantalla = @IdPantalla)
  INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint, RowStatus, FechaCreacion)
  VALUES (4, @IdPantalla, 0, 0, 0, 0, 0, 0, 0, 0, 1, GETDATE())
GO

-- 3. Verificación
SELECT p.IdPantalla, p.Nombre, p.AccionVista, r.IdRol, ro.Nombre AS Rol,
       r.AccessEnabled, r.CanView, r.CanEdit, r.CanCancel, r.CanPrint
FROM dbo.Pantallas p
JOIN dbo.RolPantallaPermisos r ON r.IdPantalla = p.IdPantalla
JOIN dbo.Roles ro ON ro.IdRol = r.IdRol
WHERE p.AccionVista = 'facturacion.operaciones.view'
ORDER BY r.IdRol
GO
