-- ============================================================
-- Script 56: Pantallas y Permisos Completos
-- Inserta modulos, pantallas y permisos faltantes en DbMasuPOS
-- Corrige IdPantalla de permisos existentes mal apuntados
-- ============================================================

USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- 1. MODULOS FALTANTES
-- ============================================================

-- Salon (key: dining)
IF NOT EXISTS (SELECT 1 FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'SALON')
BEGIN
  INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  VALUES (N'Salon', N'Armchair', 25, 1, GETDATE(), 1, 1);
  PRINT 'Modulo Salon insertado.';
END
GO

-- Inventario (key: inventory)
IF NOT EXISTS (SELECT 1 FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'INVENTARIO')
BEGIN
  INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  VALUES (N'Inventario', N'Boxes', 35, 1, GETDATE(), 1, 1);
  PRINT 'Modulo Inventario insertado.';
END
GO

-- Cuentas por Cobrar (key: cxc)
IF NOT EXISTS (SELECT 1 FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'CUENTAS POR COBRAR')
BEGIN
  INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  VALUES (N'Cuentas por Cobrar', N'HandCoins', 45, 1, GETDATE(), 1, 1);
  PRINT 'Modulo Cuentas por Cobrar insertado.';
END
GO

-- Cuentas por Pagar (key: cxp)
IF NOT EXISTS (SELECT 1 FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'CUENTAS POR PAGAR')
BEGIN
  INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  VALUES (N'Cuentas por Pagar', N'Receipt', 46, 1, GETDATE(), 1, 1);
  PRINT 'Modulo Cuentas por Pagar insertado.';
END
GO

-- ============================================================
-- 2. PANTALLAS FALTANTES (32)
-- ============================================================

-- Helper: lookup module IDs
DECLARE @IdModDashboard INT, @IdModSalon INT, @IdModInventario INT,
        @IdModCxC INT, @IdModCxP INT, @IdModConfig INT, @IdModCatalogo INT;

SELECT @IdModDashboard  = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'DASHBOARD';
SELECT @IdModSalon      = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'SALON';
SELECT @IdModInventario = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'INVENTARIO';
SELECT @IdModCxC        = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'CUENTAS POR COBRAR';
SELECT @IdModCxP        = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'CUENTAS POR PAGAR';
SELECT @IdModConfig     = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'CONFIGURACION';
SELECT @IdModCatalogo   = IdModulo FROM dbo.Modulos WHERE RowStatus = 1 AND UPPER(LTRIM(RTRIM(Nombre))) = N'CATALOGO';

-- Temp table with all 32 screens
IF OBJECT_ID('tempdb..#NewScreens') IS NOT NULL DROP TABLE #NewScreens;
CREATE TABLE #NewScreens (
  IdModulo INT NOT NULL,
  Nombre   NVARCHAR(100) NOT NULL,
  Ruta     NVARCHAR(200) NOT NULL,
  Icono    NVARCHAR(100) NULL,
  Orden    INT NOT NULL
);

INSERT INTO #NewScreens (IdModulo, Nombre, Ruta, Icono, Orden) VALUES
  -- 1. Dashboard
  (@IdModDashboard, N'Panel de Control',              N'/dashboard',                           N'LayoutGrid',         1),
  -- 2-6. Salon
  (@IdModSalon,     N'Mapa de Salon',                 N'/dining-room',                         N'Map',                1),
  (@IdModSalon,     N'Recursos',                      N'/config/dining-room/resources',         N'Armchair',           2),
  (@IdModSalon,     N'Areas',                         N'/config/dining-room/areas',             N'LayoutGrid',         3),
  (@IdModSalon,     N'Tipos de Recurso',              N'/config/dining-room/resource-types',    N'Tags',               4),
  (@IdModSalon,     N'Categorias de Recurso',         N'/config/dining-room/resource-categories', N'FolderTree',       5),
  -- 7-14. Inventario
  (@IdModInventario, N'Entradas de Inventario',       N'/inventory/entries',                    N'PackagePlus',        1),
  (@IdModInventario, N'Salidas de Inventario',        N'/inventory/exits',                      N'PackageMinus',       2),
  (@IdModInventario, N'Entradas por Compras',         N'/inventory/purchases',                  N'ShoppingBag',        3),
  (@IdModInventario, N'Transferencias',               N'/inventory/transfers',                  N'ArrowLeftRight',     4),
  (@IdModInventario, N'Tipos de Entradas',            N'/inventory/entry-types',                N'FileInput',          5),
  (@IdModInventario, N'Tipos de Salidas',             N'/inventory/exit-types',                 N'FileOutput',         6),
  (@IdModInventario, N'Tipos Entradas por Compras',   N'/inventory/purchase-types',             N'FileBox',            7),
  (@IdModInventario, N'Tipos de Transferencias',      N'/inventory/transfer-types',             N'FileScan',           8),
  (@IdModInventario, N'Historial de Cambios',         N'/inventory/documents/history',          N'History',            9),
  -- 15-16. Catalogo
  (@IdModCatalogo,  N'Minimo, Maximo, Reorden',       N'/config/catalog/stock-limits',          N'BarChart3',          10),
  (@IdModCatalogo,  N'Unidades',                      N'/config/catalog/units',                 N'Ruler',              11),
  -- 17-24. CxC
  (@IdModCxC,       N'Facturas a Credito',            N'/cxc/invoices',                        N'FileText',           1),
  (@IdModCxC,       N'Notas de Credito',              N'/cxc/credit-notes',                    N'FileDown',           2),
  (@IdModCxC,       N'Notas de Debito',               N'/cxc/debit-notes',                     N'FileUp',             3),
  (@IdModCxC,       N'Consultas CxC',                 N'/cxc/queries',                         N'Search',             4),
  (@IdModCxC,       N'Clientes',                      N'/config/cxc/customers',                N'Users',              5),
  (@IdModCxC,       N'Tipos de Clientes',             N'/config/cxc/customer-types',            N'Tags',               6),
  (@IdModCxC,       N'Categorias de Clientes',        N'/config/cxc/customer-categories',       N'FolderTree',         7),
  (@IdModCxC,       N'Descuentos',                    N'/config/cxc/discounts',                N'Percent',            8),
  -- 25-31. CxP
  (@IdModCxP,       N'Facturas de Proveedores',       N'/cxp/invoices',                        N'FileText',           1),
  (@IdModCxP,       N'Notas de Credito Proveedores',  N'/cxp/credit-notes',                    N'FileDown',           2),
  (@IdModCxP,       N'Notas de Debito Proveedores',   N'/cxp/debit-notes',                     N'FileUp',             3),
  (@IdModCxP,       N'Consultas CxP',                 N'/cxp/queries',                         N'Search',             4),
  (@IdModCxP,       N'Proveedores',                   N'/config/cxp/suppliers',                N'Truck',              5),
  (@IdModCxP,       N'Tipos de Proveedores',          N'/config/cxp/supplier-types',            N'Tags',               6),
  (@IdModCxP,       N'Categorias de Proveedores',     N'/config/cxp/supplier-categories',       N'FolderTree',         7),
  -- 32. Documentos Identidad (modulo Config)
  (@IdModConfig,    N'Documentos Identidad',          N'/config/company/doc-types',             N'IdCard',             10);

-- Insert only missing screens (idempotent by Ruta)
INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
SELECT
  S.IdModulo,
  S.Nombre,
  S.Ruta,
  S.Icono,
  S.Orden,
  1,
  GETDATE(),
  1,
  1
FROM #NewScreens S
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.Pantallas P
  WHERE P.RowStatus = 1
    AND LOWER(LTRIM(RTRIM(P.Ruta))) = LOWER(LTRIM(RTRIM(S.Ruta)))
);

PRINT CONCAT('Pantallas insertadas: ', @@ROWCOUNT);
GO

-- ============================================================
-- 3. PERMISOS FALTANTES (8 claves .view de operaciones CxC/CxP)
-- ============================================================

-- cxc.invoices.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxc.invoices.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Facturas a Credito', N'Acceso a Facturas a Credito CxC', 'cxc.invoices.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxc/invoices';
  PRINT 'Permiso cxc.invoices.view insertado.';
END
GO

-- cxc.credit-notes.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxc.credit-notes.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Notas de Credito CxC', N'Acceso a Notas de Credito CxC', 'cxc.credit-notes.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxc/credit-notes';
  PRINT 'Permiso cxc.credit-notes.view insertado.';
END
GO

-- cxc.debit-notes.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxc.debit-notes.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Notas de Debito CxC', N'Acceso a Notas de Debito CxC', 'cxc.debit-notes.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxc/debit-notes';
  PRINT 'Permiso cxc.debit-notes.view insertado.';
END
GO

-- cxc.queries.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxc.queries.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Consultas CxC', N'Acceso a Consultas de Cuentas por Cobrar', 'cxc.queries.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxc/queries';
  PRINT 'Permiso cxc.queries.view insertado.';
END
GO

-- cxp.invoices.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxp.invoices.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Facturas de Proveedores', N'Acceso a Facturas de Proveedores CxP', 'cxp.invoices.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxp/invoices';
  PRINT 'Permiso cxp.invoices.view insertado.';
END
GO

-- cxp.credit-notes.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxp.credit-notes.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Notas de Credito Proveedores', N'Acceso a Notas de Credito CxP', 'cxp.credit-notes.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxp/credit-notes';
  PRINT 'Permiso cxp.credit-notes.view insertado.';
END
GO

-- cxp.debit-notes.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxp.debit-notes.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Notas de Debito Proveedores', N'Acceso a Notas de Debito CxP', 'cxp.debit-notes.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxp/debit-notes';
  PRINT 'Permiso cxp.debit-notes.view insertado.';
END
GO

-- cxp.queries.view
IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'cxp.queries.view' AND RowStatus = 1)
BEGIN
  INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  SELECT P.IdPantalla, N'Consultas CxP', N'Acceso a Consultas de Cuentas por Pagar', 'cxp.queries.view', 1, 1, GETDATE(), 1
  FROM dbo.Pantallas P WHERE P.RowStatus = 1 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/cxp/queries';
  PRINT 'Permiso cxp.queries.view insertado.';
END
GO

-- ============================================================
-- 4. Crear permisos .view para las 32 pantallas que aun no tengan uno
--    (las que no sean las 8 de arriba ni las 12 que ya existian)
-- ============================================================

-- Temp table with route -> clave mapping for ALL 32 screens
IF OBJECT_ID('tempdb..#ScreenPerms') IS NOT NULL DROP TABLE #ScreenPerms;
CREATE TABLE #ScreenPerms (
  Ruta  NVARCHAR(200) NOT NULL,
  Clave NVARCHAR(100) NOT NULL,
  Nombre NVARCHAR(150) NOT NULL,
  Descripcion NVARCHAR(250) NOT NULL
);

INSERT INTO #ScreenPerms (Ruta, Clave, Nombre, Descripcion) VALUES
  (N'/dashboard',                            N'dashboard.view',                          N'Panel de Control',              N'Acceso al Panel de Control'),
  (N'/dining-room',                          N'dining-room.view',                        N'Mapa de Salon',                 N'Acceso al Mapa de Salon'),
  (N'/config/dining-room/resources',         N'config.dining.resources.view',            N'Recursos',                      N'Acceso a Recursos de Salon'),
  (N'/config/dining-room/areas',             N'config.dining.areas.view',                N'Areas',                         N'Acceso a Areas de Salon'),
  (N'/config/dining-room/resource-types',    N'config.dining.resource-types.view',       N'Tipos de Recurso',              N'Acceso a Tipos de Recurso de Salon'),
  (N'/config/dining-room/resource-categories', N'config.dining.resource-categories.view', N'Categorias de Recurso',         N'Acceso a Categorias de Recurso de Salon'),
  (N'/inventory/entries',                    N'catalog.view',                            N'Entradas de Inventario',        N'Acceso a Entradas de Inventario'),
  (N'/inventory/exits',                      N'catalog.view',                            N'Salidas de Inventario',         N'Acceso a Salidas de Inventario'),
  (N'/inventory/purchases',                  N'catalog.view',                            N'Entradas por Compras',          N'Acceso a Entradas por Compras'),
  (N'/inventory/transfers',                  N'catalog.view',                            N'Transferencias',                N'Acceso a Transferencias de Inventario'),
  (N'/inventory/entry-types',                N'inventory.entry-types.view',              N'Tipos de Entradas',             N'Acceso a Tipos de Entradas de Inventario'),
  (N'/inventory/exit-types',                 N'inventory.exit-types.view',               N'Tipos de Salidas',              N'Acceso a Tipos de Salidas de Inventario'),
  (N'/inventory/purchase-types',             N'inventory.purchase-types.view',           N'Tipos Entradas por Compras',    N'Acceso a Tipos de Entradas por Compras'),
  (N'/inventory/transfer-types',             N'inventory.transfer-types.view',           N'Tipos de Transferencias',       N'Acceso a Tipos de Transferencias'),
  (N'/inventory/documents/history',          N'inventory.documents.history.view',        N'Historial Cambios Inventario',  N'Acceso al Historial de Cambios de Documentos de Inventario'),
  (N'/config/catalog/stock-limits',          N'config.catalog.products.view',            N'Minimo, Maximo, Reorden',       N'Acceso a limites de stock'),
  (N'/config/catalog/units',                 N'config.catalog.units.view',               N'Unidades',                      N'Acceso a Unidades de Medida'),
  (N'/cxc/invoices',                         N'cxc.invoices.view',                       N'Facturas a Credito',            N'Acceso a Facturas a Credito CxC'),
  (N'/cxc/credit-notes',                     N'cxc.credit-notes.view',                   N'Notas de Credito CxC',          N'Acceso a Notas de Credito CxC'),
  (N'/cxc/debit-notes',                      N'cxc.debit-notes.view',                    N'Notas de Debito CxC',           N'Acceso a Notas de Debito CxC'),
  (N'/cxc/queries',                          N'cxc.queries.view',                        N'Consultas CxC',                 N'Acceso a Consultas de Cuentas por Cobrar'),
  (N'/config/cxc/customers',                 N'config.cxc.customers.view',               N'Clientes',                      N'Acceso a la pantalla de Clientes'),
  (N'/config/cxc/customer-types',            N'config.cxc.customer-types.view',          N'Tipos de Clientes',             N'Acceso a la pantalla de Tipos de Clientes'),
  (N'/config/cxc/customer-categories',       N'config.cxc.customer-categories.view',     N'Categorias de Clientes',        N'Acceso a la pantalla de Categorias de Clientes'),
  (N'/config/cxc/discounts',                 N'config.cxc.discounts.view',               N'Descuentos',                    N'Acceso a la pantalla de Descuentos'),
  (N'/cxp/invoices',                         N'cxp.invoices.view',                       N'Facturas de Proveedores',       N'Acceso a Facturas de Proveedores CxP'),
  (N'/cxp/credit-notes',                     N'cxp.credit-notes.view',                   N'Notas de Credito Proveedores',  N'Acceso a Notas de Credito CxP'),
  (N'/cxp/debit-notes',                      N'cxp.debit-notes.view',                    N'Notas de Debito Proveedores',   N'Acceso a Notas de Debito CxP'),
  (N'/cxp/queries',                          N'cxp.queries.view',                        N'Consultas CxP',                 N'Acceso a Consultas de Cuentas por Pagar'),
  (N'/config/cxp/suppliers',                 N'config.cxp.suppliers.view',               N'Proveedores',                   N'Acceso a la pantalla de Proveedores'),
  (N'/config/cxp/supplier-types',            N'config.cxp.supplier-types.view',          N'Tipos de Proveedores',          N'Acceso a la pantalla de Tipos de Proveedores'),
  (N'/config/cxp/supplier-categories',       N'config.cxp.supplier-categories.view',     N'Categorias de Proveedores',     N'Acceso a la pantalla de Categorias de Proveedores'),
  (N'/config/company/doc-types',             N'config.company.doc-types.view',           N'Documentos Identidad',          N'Acceso a la pantalla de Documentos de Identidad');

-- Insert missing permissions for screens that have no permission yet
INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
SELECT
  PA.IdPantalla,
  SP.Nombre,
  SP.Descripcion,
  SP.Clave,
  1,
  1,
  GETDATE(),
  1
FROM #ScreenPerms SP
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = LOWER(LTRIM(RTRIM(SP.Ruta)))
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.Permisos PE
  WHERE PE.RowStatus = 1
    AND LOWER(LTRIM(RTRIM(PE.Clave))) = LOWER(LTRIM(RTRIM(SP.Clave)))
);

PRINT CONCAT('Permisos adicionales insertados: ', @@ROWCOUNT);
GO

-- ============================================================
-- 5. FIX: UPDATE permisos existentes que apuntan a IdPantalla incorrecto
--    Estos fueron insertados con SELECT TOP 1 IdPantalla FROM dbo.Pantallas
-- ============================================================

-- config.cxc.customers.view -> /config/cxc/customers
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxc/customers'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxc.customers.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.cxc.customer-types.view -> /config/cxc/customer-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxc/customer-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxc.customer-types.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.cxc.customer-categories.view -> /config/cxc/customer-categories
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxc/customer-categories'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxc.customer-categories.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.cxc.discounts.view -> /config/cxc/discounts
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxc/discounts'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxc.discounts.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.company.doc-types.view -> /config/company/doc-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/company/doc-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.company.doc-types.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.cxp.suppliers.view -> /config/cxp/suppliers
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxp/suppliers'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxp.suppliers.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.cxp.supplier-types.view -> /config/cxp/supplier-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxp/supplier-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxp.supplier-types.view' AND PE.IdPantalla <> PA.IdPantalla;

-- config.cxp.supplier-categories.view -> /config/cxp/supplier-categories
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/config/cxp/supplier-categories'
WHERE PE.RowStatus = 1 AND PE.Clave = 'config.cxp.supplier-categories.view' AND PE.IdPantalla <> PA.IdPantalla;

-- inventory.entry-types.view -> /inventory/entry-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/inventory/entry-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'inventory.entry-types.view' AND PE.IdPantalla <> PA.IdPantalla;

-- inventory.exit-types.view -> /inventory/exit-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/inventory/exit-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'inventory.exit-types.view' AND PE.IdPantalla <> PA.IdPantalla;

-- inventory.purchase-types.view -> /inventory/purchase-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/inventory/purchase-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'inventory.purchase-types.view' AND PE.IdPantalla <> PA.IdPantalla;

-- inventory.transfer-types.view -> /inventory/transfer-types
UPDATE PE SET PE.IdPantalla = PA.IdPantalla
FROM dbo.Permisos PE
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = '/inventory/transfer-types'
WHERE PE.RowStatus = 1 AND PE.Clave = 'inventory.transfer-types.view' AND PE.IdPantalla <> PA.IdPantalla;

PRINT 'Permisos con IdPantalla incorrecto corregidos.';
GO

-- ============================================================
-- 6. ASIGNAR permisos al rol Administrador (IdRol = 1)
--    Tabla RolesPermisos (IdRol, IdPermiso, Activo, RowStatus)
-- ============================================================

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
SELECT 1, PE.IdPermiso, 1, 1, GETDATE(), 1
FROM dbo.Permisos PE
WHERE PE.RowStatus = 1
  AND PE.Activo = 1
  AND PE.Clave IN (
    -- Dashboard
    'dashboard.view',
    -- Salon
    'dining-room.view',
    'config.dining.resources.view',
    'config.dining.areas.view',
    'config.dining.resource-types.view',
    'config.dining.resource-categories.view',
    -- Inventario operaciones (usan catalog.view, ya asignado por scripts previos)
    -- Inventario tipos
    'inventory.entry-types.view',
    'inventory.exit-types.view',
    'inventory.purchase-types.view',
    'inventory.transfer-types.view',
    -- Inventario historial
    'inventory.documents.history.view',
    -- Catalogo
    'config.catalog.units.view',
    -- CxC operaciones
    'cxc.invoices.view',
    'cxc.credit-notes.view',
    'cxc.debit-notes.view',
    'cxc.queries.view',
    -- CxC maestros
    'config.cxc.customers.view',
    'config.cxc.customer-types.view',
    'config.cxc.customer-categories.view',
    'config.cxc.discounts.view',
    -- CxP operaciones
    'cxp.invoices.view',
    'cxp.credit-notes.view',
    'cxp.debit-notes.view',
    'cxp.queries.view',
    -- CxP maestros
    'config.cxp.suppliers.view',
    'config.cxp.supplier-types.view',
    'config.cxp.supplier-categories.view',
    -- Empresa
    'config.company.doc-types.view'
  )
  AND NOT EXISTS (
    SELECT 1 FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = 1
      AND RP.IdPermiso = PE.IdPermiso
      AND RP.RowStatus = 1
  );

PRINT CONCAT('Permisos asignados a Administrador en RolesPermisos: ', @@ROWCOUNT);
GO

-- ============================================================
-- 7. ASIGNAR en RolPantallaPermisos (tabla de permisos granulares)
-- ============================================================

INSERT INTO dbo.RolPantallaPermisos (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
SELECT 1, PA.IdPantalla, 1, 1, 1, 1, 1, 1, 1, 1
FROM dbo.Pantallas PA
WHERE PA.RowStatus = 1
  AND LOWER(LTRIM(RTRIM(PA.Ruta))) IN (
    '/dashboard',
    '/dining-room',
    '/config/dining-room/resources',
    '/config/dining-room/areas',
    '/config/dining-room/resource-types',
    '/config/dining-room/resource-categories',
    '/inventory/entries',
    '/inventory/exits',
    '/inventory/purchases',
    '/inventory/transfers',
    '/inventory/entry-types',
    '/inventory/exit-types',
    '/inventory/purchase-types',
    '/inventory/transfer-types',
    '/inventory/documents/history',
    '/config/catalog/stock-limits',
    '/config/catalog/units',
    '/cxc/invoices',
    '/cxc/credit-notes',
    '/cxc/debit-notes',
    '/cxc/queries',
    '/config/cxc/customers',
    '/config/cxc/customer-types',
    '/config/cxc/customer-categories',
    '/config/cxc/discounts',
    '/cxp/invoices',
    '/cxp/credit-notes',
    '/cxp/debit-notes',
    '/cxp/queries',
    '/config/cxp/suppliers',
    '/config/cxp/supplier-types',
    '/config/cxp/supplier-categories',
    '/config/company/doc-types'
  )
  AND NOT EXISTS (
    SELECT 1 FROM dbo.RolPantallaPermisos RPP
    WHERE RPP.IdRol = 1 AND RPP.IdPantalla = PA.IdPantalla
  );

PRINT CONCAT('Pantallas asignadas a Administrador en RolPantallaPermisos: ', @@ROWCOUNT);
GO

-- ============================================================
-- 8. VERIFICACION
-- ============================================================

PRINT '';
PRINT '========================================';
PRINT ' VERIFICACION FINAL';
PRINT '========================================';

SELECT 'Modulos' AS Tabla, COUNT(*) AS Total
FROM dbo.Modulos WHERE RowStatus = 1
UNION ALL
SELECT 'Pantallas', COUNT(*)
FROM dbo.Pantallas WHERE RowStatus = 1
UNION ALL
SELECT 'Permisos', COUNT(*)
FROM dbo.Permisos WHERE RowStatus = 1
UNION ALL
SELECT 'RolesPermisos (Admin)', COUNT(*)
FROM dbo.RolesPermisos WHERE IdRol = 1 AND RowStatus = 1 AND Activo = 1
UNION ALL
SELECT 'RolPantallaPermisos (Admin)', COUNT(*)
FROM dbo.RolPantallaPermisos WHERE IdRol = 1;

-- Verificar que no hay permisos apuntando a IdPantalla incorrecto
SELECT 'Permisos con IdPantalla incorrecto' AS Check_,
  COUNT(*) AS Total
FROM dbo.Permisos PE
INNER JOIN #ScreenPerms SP ON LOWER(LTRIM(RTRIM(PE.Clave))) = LOWER(LTRIM(RTRIM(SP.Clave)))
INNER JOIN dbo.Pantallas PA ON PA.RowStatus = 1 AND LOWER(LTRIM(RTRIM(PA.Ruta))) = LOWER(LTRIM(RTRIM(SP.Ruta)))
WHERE PE.RowStatus = 1
  AND PE.IdPantalla <> PA.IdPantalla;

DROP TABLE IF EXISTS #NewScreens;
DROP TABLE IF EXISTS #ScreenPerms;

PRINT '';
PRINT '=== Script 56_pantallas_permisos_completos.sql ejecutado correctamente ===';
GO
