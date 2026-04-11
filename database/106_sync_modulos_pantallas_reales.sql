USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('tempdb..#ModuleCatalog') IS NOT NULL DROP TABLE #ModuleCatalog;
IF OBJECT_ID('tempdb..#ScreenCatalog') IS NOT NULL DROP TABLE #ScreenCatalog;
IF OBJECT_ID('tempdb..#PermissionCatalog') IS NOT NULL DROP TABLE #PermissionCatalog;
GO

CREATE TABLE #ModuleCatalog (
    CanonicalName NVARCHAR(200) NOT NULL,
    MatchName NVARCHAR(200) NOT NULL,
    Icono NVARCHAR(200) NULL,
    Orden INT NOT NULL
);

INSERT INTO #ModuleCatalog (CanonicalName, MatchName, Icono, Orden)
VALUES
    (N'Dashboard', N'Dashboard', N'dashboard', 1),
    (N'Órdenes', N'Órdenes', N'orders', 2),
    (N'Órdenes', N'Ordenes', N'orders', 2),
    (N'Salón', N'Salón', N'dining', 3),
    (N'Salón', N'Salon', N'dining', 3),
    (N'Facturación', N'Facturación', N'invoice', 4),
    (N'Facturación', N'Facturacion', N'invoice', 4),
    (N'Impuestos', N'Impuestos', N'tax', 5),
    (N'Reportes', N'Reportes', N'reports', 6),
    (N'Inventario', N'Inventario', N'inventory', 7),
    (N'Cuentas por Cobrar', N'Cuentas por Cobrar', N'cxc', 8),
    (N'Cuentas por Pagar', N'Cuentas por Pagar', N'cxp', 9),
    (N'Configuración', N'Configuración', N'settings', 10),
    (N'Configuración', N'Configuracion', N'settings', 10);

CREATE TABLE #ScreenCatalog (
    Ruta NVARCHAR(400) NOT NULL,
    ModuloNombre NVARCHAR(200) NOT NULL,
    Nombre NVARCHAR(200) NOT NULL,
    Controlador NVARCHAR(200) NULL,
    AccionVista NVARCHAR(200) NULL,
    Icono NVARCHAR(200) NULL,
    Orden INT NOT NULL,
    ClavePermiso NVARCHAR(100) NULL
);

INSERT INTO #ScreenCatalog (Ruta, ModuloNombre, Nombre, Controlador, AccionVista, Icono, Orden, ClavePermiso)
VALUES
    (N'/dashboard', N'Dashboard', N'Panel de Control', N'dashboard-home', N'dashboard.view', NULL, 1, N'dashboard.view'),

    (N'/orders', N'Órdenes', N'Gestión de Órdenes', N'orders-main', N'orders.view', NULL, 1, N'orders.view'),

    (N'/dining-room', N'Salón', N'Mapa de Salón', N'dining-floor', N'dining-room.view', NULL, 1, N'dining-room.view'),
    (N'/config/dining-room/resources', N'Salón', N'Recursos', N'dining-resources', N'config.dining.resources.view', NULL, 10, N'config.dining.resources.view'),
    (N'/config/dining-room/areas', N'Salón', N'Áreas', N'dining-areas', N'config.dining.areas.view', NULL, 11, N'config.dining.areas.view'),
    (N'/config/dining-room/resource-types', N'Salón', N'Tipos de Recurso', N'dining-types', N'config.dining.resource-types.view', NULL, 12, N'config.dining.resource-types.view'),
    (N'/config/dining-room/resource-categories', N'Salón', N'Categorías de Recurso', N'dining-categories', N'config.dining.resource-categories.view', NULL, 13, N'config.dining.resource-categories.view'),

    (N'/facturacion/pos', N'Facturación', N'Punto de Ventas', N'billing-pos', N'facturacion.pos.view', NULL, 1, N'facturacion.pos.view'),
    (N'/facturacion/caja-central', N'Facturación', N'Caja Central', N'billing-central-cash', N'facturacion.caja-central.view', NULL, 2, N'facturacion.caja-central.view'),
    (N'/facturacion/cotizaciones', N'Facturación', N'Cotizaciones', N'billing-quotes', N'facturacion.cotizaciones.view', NULL, 3, N'facturacion.cotizaciones.view'),
    (N'/facturacion/conduces', N'Facturación', N'Conduces', N'billing-delivery', N'facturacion.conduces.view', NULL, 4, N'facturacion.conduces.view'),
    (N'/facturacion/ordenes-pedido', N'Facturación', N'Órdenes de Pedido', N'billing-sales-orders', N'facturacion.ordenes-pedido.view', NULL, 5, N'facturacion.ordenes-pedido.view'),
    (N'/facturacion/devoluciones', N'Facturación', N'Devoluciones de Mercancía', N'billing-returns', N'facturacion.devoluciones.view', NULL, 6, N'facturacion.devoluciones.view'),
    (N'/facturacion/consultas/detalle-ventas', N'Facturación', N'Detalle de Ventas', N'billing-sales-detail', N'facturacion.detalle-ventas.view', NULL, 20, N'facturacion.detalle-ventas.view'),
    (N'/facturacion/consultas/resumen-ventas', N'Facturación', N'Resumen de Ventas', N'billing-sales-summary', N'facturacion.resumen-ventas.view', NULL, 21, N'facturacion.resumen-ventas.view'),
    (N'/config/facturacion/cajas-pos', N'Facturación', N'Cajas POS', N'billing-pos-registers', N'config.facturacion.cajas-pos.view', NULL, 30, N'config.facturacion.cajas-pos.view'),
    (N'/config/facturacion/descuentos', N'Facturación', N'Descuentos', N'billing-discounts', N'config.facturacion.descuentos.view', NULL, 31, N'config.facturacion.descuentos.view'),
    (N'/config/facturacion/formas-pago', N'Facturación', N'Formas de Pago', N'billing-payment-methods', N'config.facturacion.formas-pago.view', NULL, 32, N'config.facturacion.formas-pago.view'),
    (N'/config/facturacion/tipos-facturas', N'Facturación', N'Tipos de Facturas', N'billing-invoice-types', N'config.facturacion.tipos-facturas.view', NULL, 33, N'config.facturacion.tipos-facturas.view'),
    (N'/config/facturacion/tipos-conduces', N'Facturación', N'Tipos de Conduce', N'billing-delivery-types', N'config.facturacion.tipos-conduces.view', NULL, 34, N'config.facturacion.tipos-conduces.view'),
    (N'/config/facturacion/tipos-ordenes-pedido', N'Facturación', N'Tipos de Órdenes de Pedido', N'billing-sales-order-types', N'config.facturacion.tipos-ordenes-pedido.view', NULL, 35, N'config.facturacion.tipos-ordenes-pedido.view'),

    (N'/impuestos/gastos-menores', N'Impuestos', N'Gastos Menores', N'tax-minor-expenses', N'impuestos.gastos-menores.view', NULL, 1, N'impuestos.gastos-menores.view'),
    (N'/impuestos/proveedores-informales', N'Impuestos', N'Proveedores Informales', N'tax-informal-suppliers', N'impuestos.proveedores-informales.view', NULL, 2, N'impuestos.proveedores-informales.view'),
    (N'/impuestos/pagos-exterior', N'Impuestos', N'Pagos al Exterior', N'tax-foreign-payments', N'impuestos.pagos-exterior.view', NULL, 3, N'impuestos.pagos-exterior.view'),
    (N'/impuestos/actualizacion-secuencias', N'Impuestos', N'Actualización de Secuencias', N'tax-seq-update', N'impuestos.actualizacion-secuencias.view', NULL, 4, N'impuestos.actualizacion-secuencias.view'),
    (N'/impuestos/reportes', N'Impuestos', N'Reportes Fiscales', N'tax-reports', N'impuestos.reportes.view', NULL, 20, N'impuestos.reportes.view'),
    (N'/config/impuestos/tipos-comprobantes', N'Impuestos', N'Tipos de Comprobantes', N'tax-voucher-types', N'config.impuestos.tipos-comprobantes.view', NULL, 30, N'config.impuestos.tipos-comprobantes.view'),
    (N'/config/impuestos/secuencias-fiscales', N'Impuestos', N'Secuencias Fiscales', N'tax-sequences', N'config.impuestos.secuencias-fiscales.view', NULL, 31, N'config.impuestos.secuencias-fiscales.view'),

    (N'/reports', N'Reportes', N'Reportes', N'reports-main', N'reports.view', NULL, 1, N'reports.view'),

    (N'/inventory/entries', N'Inventario', N'Entradas de Inventario', N'inventory-entries', N'catalog.view', NULL, 1, N'catalog.view'),
    (N'/inventory/exits', N'Inventario', N'Salidas de Inventario', N'inventory-exits', N'catalog.view', NULL, 2, N'catalog.view'),
    (N'/inventory/purchases', N'Inventario', N'Entradas por Compras', N'inventory-purchases', N'catalog.view', NULL, 3, N'catalog.view'),
    (N'/inventory/transfers', N'Inventario', N'Transferencias', N'inventory-transfers', N'inventory.transfers.view', NULL, 4, N'inventory.transfers.view'),
    (N'/catalog', N'Inventario', N'Consultas de Inventario', N'inventory-queries', N'catalog.view', NULL, 20, N'catalog.view'),
    (N'/config/catalog/products', N'Inventario', N'Productos', N'catalog-products', N'config.catalog.products.view', NULL, 30, N'config.catalog.products.view'),
    (N'/config/catalog/categories', N'Inventario', N'Categorías', N'catalog-categories', N'config.catalog.categories.view', NULL, 31, N'config.catalog.categories.view'),
    (N'/config/catalog/product-types', N'Inventario', N'Tipos', N'catalog-types', N'config.catalog.product-types.view', NULL, 32, N'config.catalog.product-types.view'),
    (N'/config/catalog/units', N'Inventario', N'Unidades', N'catalog-units', N'config.catalog.units.view', NULL, 33, N'config.catalog.units.view'),
    (N'/config/catalog/price-lists', N'Inventario', N'Listas de Precios', N'catalog-price-lists', N'config.catalog.price-lists.view', NULL, 34, N'config.catalog.price-lists.view'),
    (N'/config/catalog/stock-limits', N'Inventario', N'Mínimo, Máximo y Reorden', N'catalog-stock-limits', N'config.catalog.products.view', NULL, 35, N'config.catalog.products.view'),
    (N'/inventory/entry-types', N'Inventario', N'Tipos de Entradas', N'inv-entry-types', N'inventory.entry-types.view', NULL, 40, N'inventory.entry-types.view'),
    (N'/inventory/exit-types', N'Inventario', N'Tipos de Salidas', N'inv-exit-types', N'inventory.exit-types.view', NULL, 41, N'inventory.exit-types.view'),
    (N'/inventory/purchase-types', N'Inventario', N'Tipos de Entradas por Compras', N'inv-purchase-types', N'inventory.purchase-types.view', NULL, 42, N'inventory.purchase-types.view'),
    (N'/inventory/transfer-types', N'Inventario', N'Tipos de Transferencias', N'inv-transfer-types', N'inventory.transfer-types.view', NULL, 43, N'inventory.transfer-types.view'),

    (N'/cxc/invoices', N'Cuentas por Cobrar', N'Facturas a Crédito', N'cxc-invoices', N'cxc.invoices.view', NULL, 1, N'cxc.invoices.view'),
    (N'/cxc/credit-notes', N'Cuentas por Cobrar', N'Notas de Crédito', N'cxc-credit-notes', N'cxc.credit-notes.view', NULL, 2, N'cxc.credit-notes.view'),
    (N'/cxc/debit-notes', N'Cuentas por Cobrar', N'Notas de Débito', N'cxc-debit-notes', N'cxc.debit-notes.view', NULL, 3, N'cxc.debit-notes.view'),
    (N'/config/cxc/customers', N'Cuentas por Cobrar', N'Clientes', N'cxc-customers', N'config.cxc.customers.view', NULL, 10, N'config.cxc.customers.view'),
    (N'/config/cxc/customer-types', N'Cuentas por Cobrar', N'Tipos de Clientes', N'cxc-customer-types', N'config.cxc.customer-types.view', NULL, 11, N'config.cxc.customer-types.view'),
    (N'/config/cxc/customer-categories', N'Cuentas por Cobrar', N'Categorías de Clientes', N'cxc-customer-categories', N'config.cxc.customer-categories.view', NULL, 12, N'config.cxc.customer-categories.view'),
    (N'/config/cxc/discounts', N'Cuentas por Cobrar', N'Descuentos', N'cxc-discounts', N'config.cxc.discounts.view', NULL, 13, N'config.cxc.discounts.view'),
    (N'/cxc/queries', N'Cuentas por Cobrar', N'Consultas CxC', N'cxc-queries', N'cxc.queries.view', NULL, 20, N'cxc.queries.view'),

    (N'/cxp/invoices', N'Cuentas por Pagar', N'Facturas de Proveedores', N'cxp-invoices', N'cxp.invoices.view', NULL, 1, N'cxp.invoices.view'),
    (N'/cxp/credit-notes', N'Cuentas por Pagar', N'Notas de Crédito de Proveedores', N'cxp-credit-notes', N'cxp.credit-notes.view', NULL, 2, N'cxp.credit-notes.view'),
    (N'/cxp/debit-notes', N'Cuentas por Pagar', N'Notas de Débito de Proveedores', N'cxp-debit-notes', N'cxp.debit-notes.view', NULL, 3, N'cxp.debit-notes.view'),
    (N'/config/cxp/suppliers', N'Cuentas por Pagar', N'Proveedores', N'cxp-suppliers', N'config.cxp.suppliers.view', NULL, 10, N'config.cxp.suppliers.view'),
    (N'/config/cxp/supplier-types', N'Cuentas por Pagar', N'Tipos de Proveedores', N'cxp-supplier-types', N'config.cxp.supplier-types.view', NULL, 11, N'config.cxp.supplier-types.view'),
    (N'/config/cxp/supplier-categories', N'Cuentas por Pagar', N'Categorías de Proveedores', N'cxp-supplier-categories', N'config.cxp.supplier-categories.view', NULL, 12, N'config.cxp.supplier-categories.view'),
    (N'/cxp/queries', N'Cuentas por Pagar', N'Consultas CxP', N'cxp-queries', N'cxp.queries.view', NULL, 20, N'cxp.queries.view'),

    (N'/config/company', N'Configuración', N'Datos Generales', N'company-main', N'config.company.view', NULL, 1, N'config.company.view'),
    (N'/config/company/divisions', N'Configuración', N'Divisiones', N'company-divisions', N'config.company.divisions.view', NULL, 2, N'config.company.divisions.view'),
    (N'/config/company/branches', N'Configuración', N'Sucursales', N'company-branches', N'config.company.branches.view', NULL, 3, N'config.company.branches.view'),
    (N'/config/company/emission-points', N'Configuración', N'Puntos de Emisión', N'company-emission', N'config.company.emission-points.view', NULL, 4, N'config.company.emission-points.view'),
    (N'/config/company/warehouses', N'Configuración', N'Almacenes', N'company-warehouses', N'config.company.warehouses.view', NULL, 5, N'config.company.warehouses.view'),
    (N'/config/company/tax-rates', N'Configuración', N'Tasas de Impuesto', N'company-tax-rates', N'config.company.tax-rates.view', NULL, 6, N'config.company.tax-rates.view'),
    (N'/config/currencies', N'Configuración', N'Monedas', N'currencies-main', N'config.currencies.view', NULL, 10, N'config.currencies.view'),
    (N'/config/currencies/rates', N'Configuración', N'Tasas de Monedas', N'currency-rates', N'config.currencies.rates.view', NULL, 11, N'config.currencies.rates.view'),
    (N'/config/currencies/history', N'Configuración', N'Histórico de Tasas', N'currency-history', N'config.currencies.history.view', NULL, 12, N'config.currencies.history.view'),
    (N'/config/company/doc-types', N'Configuración', N'Documentos de Identidad', N'doc-types', N'config.company.doc-types.view', NULL, 20, N'config.company.doc-types.view'),
    (N'/config/security/users', N'Configuración', N'Usuarios', N'security-users', N'config.security.users.view', NULL, 30, N'config.security.users.view'),
    (N'/config/security/roles', N'Configuración', N'Roles', N'security-roles', N'config.security.roles.view', NULL, 31, N'config.security.roles.view'),
    (N'/config/security/modules', N'Configuración', N'Módulos', N'security-modules', N'config.security.modules.view', NULL, 32, N'config.security.modules.view'),
    (N'/config/security/screens', N'Configuración', N'Pantallas', N'security-screens', N'config.security.screens.view', NULL, 33, N'config.security.screens.view'),
    (N'/config/security/permissions', N'Configuración', N'Permisos', N'security-permissions', N'config.security.permissions.view', NULL, 34, N'config.security.permissions.view'),
    (N'/config/security/roles-permissions', N'Configuración', N'Roles y Permisos', N'security-roles-permissions', N'config.security.roles-permissions.view', NULL, 35, N'config.security.roles-permissions.view');

CREATE TABLE #PermissionCatalog (
    ClavePermiso NVARCHAR(100) NOT NULL,
    Ruta NVARCHAR(400) NOT NULL,
    NombrePermiso NVARCHAR(300) NOT NULL,
    Descripcion NVARCHAR(500) NULL
);

INSERT INTO #PermissionCatalog (ClavePermiso, Ruta, NombrePermiso, Descripcion)
SELECT
    ClavePermiso,
    Ruta,
    N'Acceso - ' + Nombre,
    N'Permite acceder a la pantalla ' + Nombre
FROM #ScreenCatalog
WHERE ClavePermiso IS NOT NULL;

;WITH CanonicalModules AS (
    SELECT DISTINCT CanonicalName, Icono, Orden
    FROM #ModuleCatalog
)
UPDATE M
SET M.Nombre = CM.CanonicalName,
    M.Icono = CM.Icono,
    M.Orden = CM.Orden,
    M.Activo = 1,
    M.RowStatus = 1,
    M.FechaModificacion = GETDATE()
FROM dbo.Modulos M
INNER JOIN #ModuleCatalog MC ON UPPER(LTRIM(RTRIM(M.Nombre))) = UPPER(LTRIM(RTRIM(MC.MatchName)))
INNER JOIN CanonicalModules CM ON CM.CanonicalName = MC.CanonicalName;

;WITH CanonicalModules AS (
    SELECT DISTINCT CanonicalName, Icono, Orden
    FROM #ModuleCatalog
)
INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, RowStatus, FechaCreacion)
SELECT CM.CanonicalName, CM.Icono, CM.Orden, 1, 1, GETDATE()
FROM CanonicalModules CM
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Modulos M
    WHERE M.RowStatus = 1
      AND UPPER(LTRIM(RTRIM(M.Nombre))) = UPPER(LTRIM(RTRIM(CM.CanonicalName)))
);

UPDATE M
SET M.RowStatus = 0,
    M.Activo = 0,
    M.FechaModificacion = GETDATE()
FROM dbo.Modulos M
WHERE M.RowStatus = 1
  AND NOT EXISTS (
      SELECT 1
      FROM #ModuleCatalog MC
      WHERE UPPER(LTRIM(RTRIM(M.Nombre))) = UPPER(LTRIM(RTRIM(MC.MatchName)))
  );

UPDATE P
SET P.IdModulo = M.IdModulo,
    P.Nombre = SC.Nombre,
    P.Controlador = SC.Controlador,
    P.AccionVista = SC.AccionVista,
    P.Icono = SC.Icono,
    P.Orden = SC.Orden,
    P.Activo = 1,
    P.RowStatus = 1,
    P.FechaModificacion = GETDATE()
FROM dbo.Pantallas P
INNER JOIN #ScreenCatalog SC ON LTRIM(RTRIM(ISNULL(P.Ruta, ''))) = SC.Ruta
INNER JOIN dbo.Modulos M ON M.Nombre = SC.ModuloNombre AND M.RowStatus = 1;

INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, AccionVista, Icono, Orden, Activo, RowStatus, FechaCreacion)
SELECT M.IdModulo, SC.Nombre, SC.Ruta, SC.Controlador, SC.AccionVista, SC.Icono, SC.Orden, 1, 1, GETDATE()
FROM #ScreenCatalog SC
INNER JOIN dbo.Modulos M ON M.Nombre = SC.ModuloNombre AND M.RowStatus = 1
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Pantallas P
    WHERE P.RowStatus = 1
      AND LTRIM(RTRIM(ISNULL(P.Ruta, ''))) = SC.Ruta
);

UPDATE P
SET P.RowStatus = 0,
    P.Activo = 0,
    P.FechaModificacion = GETDATE()
FROM dbo.Pantallas P
WHERE P.RowStatus = 1
  AND (
      NULLIF(LTRIM(RTRIM(ISNULL(P.Ruta, ''))), '') IS NULL
      OR NOT EXISTS (
          SELECT 1
          FROM #ScreenCatalog SC
          WHERE SC.Ruta = LTRIM(RTRIM(ISNULL(P.Ruta, '')))
      )
  );

UPDATE PERM
SET PERM.IdPantalla = P.IdPantalla,
    PERM.Nombre = PC.NombrePermiso,
    PERM.Descripcion = PC.Descripcion,
    PERM.PuedeVer = 1,
    PERM.Activo = 1,
    PERM.RowStatus = 1,
    PERM.FechaModificacion = GETDATE()
FROM dbo.Permisos PERM
INNER JOIN #PermissionCatalog PC ON PERM.Clave = PC.ClavePermiso
INNER JOIN dbo.Pantallas P ON P.Ruta = PC.Ruta AND P.RowStatus = 1;

INSERT INTO dbo.Permisos (
    IdPantalla,
    Nombre,
    Descripcion,
    Clave,
    PuedeVer,
    PuedeCrear,
    PuedeEditar,
    PuedeEliminar,
    PuedeAprobar,
    PuedeAnular,
    PuedeImprimir,
    Activo,
    RowStatus,
    FechaCreacion
)
SELECT
    P.IdPantalla,
    PC.NombrePermiso,
    PC.Descripcion,
    PC.ClavePermiso,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    GETDATE()
FROM #PermissionCatalog PC
INNER JOIN dbo.Pantallas P ON P.Ruta = PC.Ruta AND P.RowStatus = 1
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.Permisos PERM
    WHERE PERM.RowStatus = 1
      AND PERM.Clave = PC.ClavePermiso
);

;WITH AdminRoles AS (
    SELECT R.IdRol
    FROM dbo.Roles R
    WHERE R.RowStatus = 1
      AND R.Activo = 1
      AND (
          R.IdRol = 1
          OR UPPER(LTRIM(RTRIM(R.Nombre))) IN (N'ADMIN', N'ADMINISTRADOR', N'ADMINISTRADOR GENERAL')
      )
),
CatalogScreens AS (
    SELECT P.IdPantalla
    FROM dbo.Pantallas P
    INNER JOIN #ScreenCatalog SC ON SC.Ruta = P.Ruta
    WHERE P.RowStatus = 1
      AND P.Activo = 1
)
UPDATE RPP
SET RPP.AccessEnabled = 1,
    RPP.CanCreate = 1,
    RPP.CanEdit = 1,
    RPP.CanDelete = 1,
    RPP.CanView = 1,
    RPP.CanApprove = 1,
    RPP.CanCancel = 1,
    RPP.CanPrint = 1
FROM dbo.RolPantallaPermisos RPP
INNER JOIN AdminRoles AR ON AR.IdRol = RPP.IdRol
INNER JOIN CatalogScreens CS ON CS.IdPantalla = RPP.IdPantalla;

;WITH AdminRoles AS (
    SELECT R.IdRol
    FROM dbo.Roles R
    WHERE R.RowStatus = 1
      AND R.Activo = 1
      AND (
          R.IdRol = 1
          OR UPPER(LTRIM(RTRIM(R.Nombre))) IN (N'ADMIN', N'ADMINISTRADOR', N'ADMINISTRADOR GENERAL')
      )
),
CatalogScreens AS (
    SELECT P.IdPantalla
    FROM dbo.Pantallas P
    INNER JOIN #ScreenCatalog SC ON SC.Ruta = P.Ruta
    WHERE P.RowStatus = 1
      AND P.Activo = 1
)
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
    CanPrint
)
SELECT
    AR.IdRol,
    CS.IdPantalla,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1
FROM AdminRoles AR
CROSS JOIN CatalogScreens CS
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.RolPantallaPermisos RPP
    WHERE RPP.IdRol = AR.IdRol
      AND RPP.IdPantalla = CS.IdPantalla
);

DECLARE @IdPantallaDashboard INT;
SELECT TOP (1) @IdPantallaDashboard = IdPantalla
FROM dbo.Pantallas
WHERE Ruta = N'/dashboard'
  AND RowStatus = 1
  AND Activo = 1
ORDER BY IdPantalla;

IF @IdPantallaDashboard IS NOT NULL
BEGIN
    UPDATE U
    SET U.IdPantallaInicio = @IdPantallaDashboard,
        U.FechaModificacion = GETDATE()
    FROM dbo.Usuarios U
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    WHERE U.RowStatus = 1
      AND (
          U.IdPantallaInicio IS NULL
          OR P.IdPantalla IS NULL
          OR P.RowStatus = 0
          OR P.Activo = 0
      );
END;
GO
