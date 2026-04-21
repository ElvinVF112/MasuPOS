-- ============================================================
-- Script 170: Pantalla + Permisos - Facturacion / Vendedores
-- ============================================================

DECLARE @IdModuloFacturacion INT = 12;
DECLARE @Ruta NVARCHAR(200) = N'/config/facturacion/vendedores';
DECLARE @AccionVista NVARCHAR(150) = N'config.facturacion.vendedores.view';
DECLARE @NombrePantalla NVARCHAR(150) = N'Vendedores';

IF NOT EXISTS (
    SELECT 1
    FROM dbo.Pantallas
    WHERE Ruta = @Ruta OR AccionVista = @AccionVista
)
BEGIN
    INSERT INTO dbo.Pantallas (
        IdModulo, Nombre, Ruta, AccionVista, Orden, Activo, RowStatus, FechaCreacion
    )
    VALUES (
        @IdModuloFacturacion, @NombrePantalla, @Ruta, @AccionVista, 25, 1, 1, GETDATE()
    );
END;
GO

DECLARE @IdPantalla INT = (
    SELECT TOP (1) IdPantalla
    FROM dbo.Pantallas
    WHERE Ruta = N'/config/facturacion/vendedores'
       OR AccionVista = N'config.facturacion.vendedores.view'
);

IF @IdPantalla IS NULL
BEGIN
    RAISERROR(N'No se pudo resolver la pantalla de Vendedores.', 16, 1);
    RETURN;
END;

-- Garantiza una fila por rol
INSERT INTO dbo.RolPantallaPermisos (
    IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete,
    CanView, CanApprove, CanCancel, CanPrint, RowStatus, FechaCreacion
)
SELECT
    r.IdRol, @IdPantalla, 0, 0, 0, 0, 0, 0, 0, 0, 1, GETDATE()
FROM dbo.Roles r
WHERE r.IdRol > 0
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolPantallaPermisos rp
      WHERE rp.IdRol = r.IdRol AND rp.IdPantalla = @IdPantalla
  );
GO

-- Admin: acceso completo
UPDATE rp
SET AccessEnabled=1, CanCreate=1, CanEdit=1, CanDelete=1, CanView=1, CanApprove=1, CanCancel=1, CanPrint=1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 1 AND p.AccionVista = N'config.facturacion.vendedores.view';
GO

-- Gerente: ver + editar + crear
UPDATE rp
SET AccessEnabled=1, CanCreate=1, CanEdit=1, CanView=1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 2 AND p.AccionVista = N'config.facturacion.vendedores.view';
GO

-- Usuario: ver
UPDATE rp
SET AccessEnabled=1, CanView=1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 3 AND p.AccionVista = N'config.facturacion.vendedores.view';
GO

-- Camarero: sin acceso
UPDATE rp
SET AccessEnabled=0, CanCreate=0, CanEdit=0, CanDelete=0, CanView=0, CanApprove=0, CanCancel=0, CanPrint=0
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 4 AND p.AccionVista = N'config.facturacion.vendedores.view';
GO

SELECT
    p.IdPantalla, p.Nombre, p.Ruta, p.AccionVista,
    r.IdRol, ro.Nombre AS Rol,
    r.AccessEnabled, r.CanCreate, r.CanEdit, r.CanDelete, r.CanView
FROM dbo.Pantallas p
JOIN dbo.RolPantallaPermisos r ON r.IdPantalla = p.IdPantalla
JOIN dbo.Roles ro ON ro.IdRol = r.IdRol
WHERE p.AccionVista = N'config.facturacion.vendedores.view'
ORDER BY r.IdRol;
GO
