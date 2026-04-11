SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
  TAREA 14.3
  Seed data-driven de Modulos/Pantallas/Permisos para Roles 3 paneles.
  Principio: agregar modulos/pantallas via INSERT en DB, sin hardcode en frontend.
*/

IF OBJECT_ID('tempdb..#SeedModules') IS NOT NULL DROP TABLE #SeedModules;
CREATE TABLE #SeedModules (
  Nombre NVARCHAR(100) NOT NULL,
  Icono NVARCHAR(100) NULL,
  Orden INT NOT NULL
);

INSERT INTO #SeedModules (Nombre, Icono, Orden)
VALUES
  (N'Dashboard', N'LayoutGrid', 10),
  (N'Ordenes', N'ShoppingCart', 20),
  (N'Punto de Venta', N'Monitor', 30),
  (N'Catalogo', N'Package', 40),
  (N'Reportes', N'BarChart3', 50),
  (N'Configuracion', N'Settings', 60);

/* Opcional: normalizar icono de Seguridad para lucide */
UPDATE M
SET M.Icono = N'Shield'
FROM dbo.Modulos M
WHERE M.RowStatus = 1
  AND M.Nombre = N'Seguridad'
  AND (M.Icono IS NULL OR M.Icono LIKE N'fa-%');

INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
SELECT
  S.Nombre,
  S.Icono,
  S.Orden,
  1,
  GETDATE(),
  1,
  1
FROM #SeedModules S
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.Modulos M
  WHERE M.RowStatus = 1
    AND UPPER(LTRIM(RTRIM(M.Nombre))) = UPPER(LTRIM(RTRIM(S.Nombre)))
);

IF OBJECT_ID('tempdb..#SeedScreens') IS NOT NULL DROP TABLE #SeedScreens;
CREATE TABLE #SeedScreens (
  ModuloNombre NVARCHAR(100) NOT NULL,
  PantallaNombre NVARCHAR(100) NOT NULL,
  Ruta NVARCHAR(200) NOT NULL,
  Controlador NVARCHAR(100) NULL,
  Accion NVARCHAR(100) NULL,
  Icono NVARCHAR(100) NULL,
  Orden INT NOT NULL
);

INSERT INTO #SeedScreens (ModuloNombre, PantallaNombre, Ruta, Controlador, Accion, Icono, Orden)
VALUES
  (N'Dashboard', N'Panel Principal', N'/', N'Dashboard', N'Index', N'LayoutGrid', 1),
  (N'Dashboard', N'Analiticas', N'/queries', N'Dashboard', N'Analytics', N'BarChart3', 2),

  (N'Ordenes', N'Lista de Ordenes', N'/orders', N'Orders', N'List', N'ShoppingCart', 1),
  (N'Ordenes', N'Nueva Orden', N'/orders/new', N'Orders', N'Create', N'Plus', 2),
  (N'Ordenes', N'Pantalla Cocina', N'/orders/kitchen', N'Orders', N'Kitchen', N'Monitor', 3),

  (N'Punto de Venta', N'Terminal POS', N'/cash-register', N'Pos', N'Terminal', N'Monitor', 1),
  (N'Punto de Venta', N'Pagos', N'/cash-register/payments', N'Pos', N'Payments', N'CreditCard', 2),
  (N'Punto de Venta', N'Caja', N'/cash-register', N'Pos', N'Cash', N'Wallet', 3),

  (N'Catalogo', N'Productos', N'/config/catalog/products', N'Catalog', N'Products', N'Package', 1),
  (N'Catalogo', N'Categorias', N'/config/catalog/categories', N'Catalog', N'Categories', N'Tags', 2),
  (N'Catalogo', N'Modificadores', N'/config/catalog/product-types', N'Catalog', N'Modifiers', N'SlidersHorizontal', 3),

  (N'Reportes', N'Ventas', N'/reports', N'Reports', N'Sales', N'BarChart3', 1),
  (N'Reportes', N'Inventario', N'/reports/inventory', N'Reports', N'Inventory', N'Boxes', 2),
  (N'Reportes', N'Personal', N'/reports/staff', N'Reports', N'Staff', N'Users', 3),

  (N'Configuracion', N'Empresa', N'/config/company', N'Config', N'Company', N'Building2', 1),
  (N'Configuracion', N'Usuarios', N'/config/security/users', N'Config', N'Users', N'Users', 2),
  (N'Configuracion', N'Roles', N'/config/security/roles', N'Config', N'Roles', N'Shield', 3),
  (N'Configuracion', N'Catalogo', N'/config/catalog/products', N'Config', N'Catalog', N'Package', 4);

INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
SELECT
  M.IdModulo,
  S.PantallaNombre,
  S.Ruta,
  S.Controlador,
  S.Accion,
  S.Icono,
  S.Orden,
  1,
  GETDATE(),
  1,
  1
FROM #SeedScreens S
INNER JOIN dbo.Modulos M ON M.RowStatus = 1 AND UPPER(LTRIM(RTRIM(M.Nombre))) = UPPER(LTRIM(RTRIM(S.ModuloNombre)))
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.Pantallas P
  WHERE P.RowStatus = 1
    AND P.IdModulo = M.IdModulo
    AND UPPER(LTRIM(RTRIM(P.Nombre))) = UPPER(LTRIM(RTRIM(S.PantallaNombre)))
);

/* Crear permiso default (todos flags en 0) para pantallas sin permiso */
INSERT INTO dbo.Permisos (
  IdPantalla,
  Nombre,
  Descripcion,
  PuedeVer,
  PuedeCrear,
  PuedeEditar,
  PuedeEliminar,
  PuedeAprobar,
  PuedeAnular,
  PuedeImprimir,
  Activo,
  FechaCreacion,
  RowStatus,
  UsuarioCreacion
)
SELECT
  P.IdPantalla,
  CONCAT(N'Permiso ', P.Nombre),
  CONCAT(N'Permiso base para pantalla ', P.Nombre),
  0, 0, 0, 0, 0, 0, 0,
  1,
  GETDATE(),
  1,
  1
FROM dbo.Pantallas P
WHERE P.RowStatus = 1
  AND P.Activo = 1
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.Permisos PE
    WHERE PE.IdPantalla = P.IdPantalla
      AND PE.RowStatus = 1
  );
GO
