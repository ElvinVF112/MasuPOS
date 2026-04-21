-- ============================================================
-- Script 164: Asignar todas las pantallas de Facturación a todos los Roles
-- Asegura que cada rol tenga una entrada en RolPantallaPermisos
-- para cada pantalla del módulo Facturación (IdModulo=12),
-- de forma que el UI de Roles y Permisos pueda mostrar y gestionar el acceso.
-- ============================================================

-- Roles activos (excepto IdRol=0 que es SIN ROL)
DECLARE @Roles TABLE (IdRol INT)
INSERT INTO @Roles SELECT IdRol FROM dbo.Roles WHERE IdRol > 0

-- Pantallas del módulo Facturación
DECLARE @Pantallas TABLE (IdPantalla INT)
INSERT INTO @Pantallas SELECT IdPantalla FROM dbo.Pantallas WHERE IdModulo = 12 AND RowStatus = 1

-- Insertar combinaciones faltantes con AccessEnabled=0 por defecto
INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint, RowStatus, FechaCreacion)
SELECT r.IdRol, p.IdPantalla, 0, 0, 0, 0, 0, 0, 0, 0, 1, GETDATE()
FROM @Roles r
CROSS JOIN @Pantallas p
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.RolPantallaPermisos rp
  WHERE rp.IdRol = r.IdRol AND rp.IdPantalla = p.IdPantalla
)
GO

-- Habilitar acceso completo para Administrador (IdRol=1) en todas las pantallas de Facturación
UPDATE rp SET
  AccessEnabled = 1, CanCreate = 1, CanEdit = 1, CanDelete = 1,
  CanView = 1, CanApprove = 1, CanCancel = 1, CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 1 AND p.IdModulo = 12 AND p.RowStatus = 1
GO

-- Habilitar acceso para Gerente (IdRol=2): ver + editar + cancelar + imprimir en facturación
UPDATE rp SET
  AccessEnabled = 1, CanView = 1, CanEdit = 1, CanCancel = 1, CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 2 AND p.IdModulo = 12 AND p.RowStatus = 1
  AND p.AccionVista NOT LIKE 'config.%'  -- Gerente no accede a config
GO

-- Habilitar acceso básico para Usuario (IdRol=3): POS + consultas (ver + imprimir)
UPDATE rp SET AccessEnabled = 1, CanView = 1, CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 3 AND p.IdModulo = 12 AND p.RowStatus = 1
  AND p.AccionVista IN ('facturacion.pos.view','facturacion.detalle-ventas.view','facturacion.resumen-ventas.view','facturacion.operaciones.view')
GO

-- Habilitar acceso POS para Camarero (IdRol=4): solo Punto de Ventas
UPDATE rp SET AccessEnabled = 1, CanView = 1, CanCreate = 1, CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 4 AND p.IdModulo = 12 AND p.RowStatus = 1
  AND p.AccionVista IN ('facturacion.pos.view')
GO

-- Verificación final
SELECT
  p.Nombre AS Pantalla,
  p.AccionVista,
  MAX(CASE WHEN r.IdRol = 1 THEN r.AccessEnabled END) AS Admin,
  MAX(CASE WHEN r.IdRol = 2 THEN r.AccessEnabled END) AS Gerente,
  MAX(CASE WHEN r.IdRol = 3 THEN r.AccessEnabled END) AS Usuario,
  MAX(CASE WHEN r.IdRol = 4 THEN r.AccessEnabled END) AS Camarero
FROM dbo.Pantallas p
JOIN dbo.RolPantallaPermisos r ON r.IdPantalla = p.IdPantalla
WHERE p.IdModulo = 12
GROUP BY p.IdPantalla, p.Nombre, p.AccionVista
ORDER BY p.IdPantalla
GO
