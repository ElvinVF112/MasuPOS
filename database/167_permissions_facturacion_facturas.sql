-- ============================================================
-- Script 167: Pantalla + Permisos - Facturacion / Facturas
-- Crea la pantalla de Facturas y garantiza filas en
-- RolPantallaPermisos para que el UI pueda administrarlas.
-- ============================================================

DECLARE @IdModuloFacturacion INT = 12;
DECLARE @RutaFacturas NVARCHAR(200) = N'/facturacion/facturas';
DECLARE @AccionVistaFacturas NVARCHAR(150) = N'facturacion.facturas.view';
DECLARE @NombrePantalla NVARCHAR(150) = N'Facturas';
DECLARE @IdPantallaFacturas INT;

IF NOT EXISTS (
    SELECT 1
    FROM dbo.Pantallas
    WHERE Ruta = @RutaFacturas
       OR AccionVista = @AccionVistaFacturas
)
BEGIN
    INSERT INTO dbo.Pantallas (
        IdModulo,
        Nombre,
        Ruta,
        AccionVista,
        Orden,
        Activo,
        RowStatus,
        FechaCreacion
    )
    VALUES (
        @IdModuloFacturacion,
        @NombrePantalla,
        @RutaFacturas,
        @AccionVistaFacturas,
        24,
        1,
        1,
        GETDATE()
    );
END;
GO

DECLARE @IdPantallaFacturas INT = (
    SELECT TOP (1) IdPantalla
    FROM dbo.Pantallas
    WHERE Ruta = N'/facturacion/facturas'
       OR AccionVista = N'facturacion.facturas.view'
);

IF @IdPantallaFacturas IS NULL
BEGIN
    RAISERROR(N'No se pudo resolver la pantalla de Facturas.', 16, 1);
    RETURN;
END;

-- Garantiza una fila por rol para que Roles y Permisos pueda gestionarla.
INSERT INTO dbo.RolPantallaPermisos (
    IdRol,
    IdPantalla,
    AccessEnabled,
    CanCreate,
    CanEdit,
    CanDelete,
    CanView,
    CanApprove,
    CanCancel,
    CanPrint,
    RowStatus,
    FechaCreacion
)
SELECT
    r.IdRol,
    @IdPantallaFacturas,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    GETDATE()
FROM dbo.Roles r
WHERE r.IdRol > 0
  AND NOT EXISTS (
      SELECT 1
      FROM dbo.RolPantallaPermisos rp
      WHERE rp.IdRol = r.IdRol
        AND rp.IdPantalla = @IdPantallaFacturas
  );
GO

-- Admin: acceso completo
UPDATE rp
SET
    AccessEnabled = 1,
    CanCreate = 1,
    CanEdit = 1,
    CanDelete = 1,
    CanView = 1,
    CanApprove = 1,
    CanCancel = 1,
    CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 1
  AND p.AccionVista = N'facturacion.facturas.view';
GO

-- Gerente: ver + editar + cancelar + imprimir
UPDATE rp
SET
    AccessEnabled = 1,
    CanView = 1,
    CanEdit = 1,
    CanCancel = 1,
    CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 2
  AND p.AccionVista = N'facturacion.facturas.view';
GO

-- Usuario: ver + crear + imprimir
UPDATE rp
SET
    AccessEnabled = 1,
    CanCreate = 1,
    CanView = 1,
    CanPrint = 1
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 3
  AND p.AccionVista = N'facturacion.facturas.view';
GO

-- Camarero: sin acceso
UPDATE rp
SET
    AccessEnabled = 0,
    CanCreate = 0,
    CanEdit = 0,
    CanDelete = 0,
    CanView = 0,
    CanApprove = 0,
    CanCancel = 0,
    CanPrint = 0
FROM dbo.RolPantallaPermisos rp
JOIN dbo.Pantallas p ON p.IdPantalla = rp.IdPantalla
WHERE rp.IdRol = 4
  AND p.AccionVista = N'facturacion.facturas.view';
GO

SELECT
    p.IdPantalla,
    p.Nombre,
    p.Ruta,
    p.AccionVista,
    r.IdRol,
    ro.Nombre AS Rol,
    r.AccessEnabled,
    r.CanCreate,
    r.CanEdit,
    r.CanCancel,
    r.CanPrint
FROM dbo.Pantallas p
JOIN dbo.RolPantallaPermisos r ON r.IdPantalla = p.IdPantalla
JOIN dbo.Roles ro ON ro.IdRol = r.IdRol
WHERE p.AccionVista = N'facturacion.facturas.view'
ORDER BY r.IdRol;
GO
