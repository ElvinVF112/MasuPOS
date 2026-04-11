export type PermissionKey =
  | "dashboard.view"
  | "orders.view"
  | "orders.create"
  | "orders.edit"
  | "orders.delete"
  | "orders.cancel"
  | "orders.close"
  | "orders.reopen"
  | "orders.history.view"
  | "orders.split.view"
  | "orders.split.manage"
  | "orders.send-to-cash"
  | "orders.prefactura.view"
  | "dining-room.view"
  | "cash-register.view"
  | "facturacion.pos.view"
  | "facturacion.caja-central.view"
  | "facturacion.cotizaciones.view"
  | "facturacion.conduces.view"
  | "facturacion.ordenes-pedido.view"
  | "facturacion.devoluciones.view"
  | "facturacion.detalle-ventas.view"
  | "facturacion.resumen-ventas.view"
  | "config.facturacion.cajas-pos.view"
  | "config.facturacion.descuentos.view"
  | "config.facturacion.formas-pago.view"
  | "config.facturacion.tipos-facturas.view"
  | "config.facturacion.tipos-cotizaciones.view"
  | "config.facturacion.tipos-conduces.view"
  | "config.facturacion.tipos-ordenes-pedido.view"
  | "impuestos.facturas-fiscales.view"
  | "impuestos.gastos-menores.view"
  | "impuestos.proveedores-informales.view"
  | "impuestos.pagos-exterior.view"
  | "impuestos.actualizacion-secuencias.view"
  | "impuestos.reportes.view"
  | "config.impuestos.tipos-comprobantes.view"
  | "config.impuestos.secuencias-fiscales.view"
  | "reports.view"
  | "queries.view"
  | "catalog.view"
  | "security.view"
  | "config.company.view"
  | "config.catalog.categories.view"
  | "config.catalog.product-types.view"
  | "config.catalog.products.view"
  | "config.catalog.units.view"
  | "config.catalog.price-lists.view"
  | "config.dining.resources.view"
  | "config.dining.areas.view"
  | "config.dining.resource-types.view"
  | "config.dining.resource-categories.view"
  | "config.security.users.view"
  | "config.security.roles.view"
  | "config.security.modules.view"
  | "config.security.screens.view"
  | "config.security.permissions.view"
  | "config.security.roles-permissions.view"
  | "config.currencies.view"
  | "config.currencies.rates.view"
  | "config.currencies.history.view"
  | "config.company.divisions.view"
  | "config.company.branches.view"
  | "config.company.emission-points.view"
  | "config.company.warehouses.view"
  | "config.company.tax-rates.view"
  | "cxc.invoices.view"
  | "cxc.credit-notes.view"
  | "cxc.debit-notes.view"
  | "cxc.queries.view"
  | "config.cxc.customers.view"
  | "config.cxc.customer-types.view"
  | "config.cxc.customer-categories.view"
  | "config.cxc.discounts.view"
  | "cxp.invoices.view"
  | "cxp.credit-notes.view"
  | "cxp.debit-notes.view"
  | "cxp.queries.view"
  | "config.cxp.suppliers.view"
  | "config.cxp.supplier-types.view"
  | "config.cxp.supplier-categories.view"
  | "config.company.doc-types.view"
  | "inventory.entry-types.view"
  | "inventory.exit-types.view"
  | "inventory.purchase-types.view"
  | "inventory.transfer-types.view"
  | "inventory.transfers.view"
  | "inventory.transfers.edit"
  | "inventory.transfers.void"
  | "inventory.transfers.print"
  | "inventory.transfers.generate-exit"
  | "inventory.transfers.confirm-reception"
  | "inventory.documents.history.view"

type RoutePermissionRule = {
  pattern: string
  key: PermissionKey
}

const LEGACY_ROUTE_MAP: Record<string, string> = {
  "/": "/dashboard",
  "/usuarios": "/config/security/users",
  "/roles": "/config/security/roles",
  "/permisos": "/config/security/roles",
}

export const ROUTE_PERMISSIONS: RoutePermissionRule[] = [
  { pattern: "/config/security/roles", key: "config.security.roles.view" },
  { pattern: "/config/security/users", key: "config.security.users.view" },
  { pattern: "/config/security/modules", key: "config.security.modules.view" },
  { pattern: "/config/security/screens", key: "config.security.screens.view" },
  { pattern: "/config/security/permissions", key: "config.security.permissions.view" },
  { pattern: "/config/security/roles-permissions", key: "config.security.roles-permissions.view" },
  { pattern: "/config/dining-room/resource-categories", key: "config.dining.resource-categories.view" },
  { pattern: "/config/dining-room/resource-types", key: "config.dining.resource-types.view" },
  { pattern: "/config/dining-room/areas", key: "config.dining.areas.view" },
  { pattern: "/config/dining-room/resources", key: "config.dining.resources.view" },
  { pattern: "/config/catalog/product-types", key: "config.catalog.product-types.view" },
  { pattern: "/config/catalog/categories", key: "config.catalog.categories.view" },
  { pattern: "/config/catalog/products", key: "config.catalog.products.view" },
  { pattern: "/config/catalog/stock-limits", key: "config.catalog.products.view" },
  { pattern: "/config/catalog/units", key: "config.catalog.units.view" },
  { pattern: "/config/catalog/price-lists", key: "config.catalog.price-lists.view" },
  { pattern: "/cxc/invoices", key: "cxc.invoices.view" },
  { pattern: "/cxc/credit-notes", key: "cxc.credit-notes.view" },
  { pattern: "/cxc/debit-notes", key: "cxc.debit-notes.view" },
  { pattern: "/cxc/queries", key: "cxc.queries.view" },
  { pattern: "/config/cxc/customers", key: "config.cxc.customers.view" },
  { pattern: "/config/cxc/customer-types", key: "config.cxc.customer-types.view" },
  { pattern: "/config/cxc/customer-categories", key: "config.cxc.customer-categories.view" },
  { pattern: "/config/cxc/discounts", key: "config.cxc.discounts.view" },
  { pattern: "/cxp/invoices", key: "cxp.invoices.view" },
  { pattern: "/cxp/credit-notes", key: "cxp.credit-notes.view" },
  { pattern: "/cxp/debit-notes", key: "cxp.debit-notes.view" },
  { pattern: "/cxp/queries", key: "cxp.queries.view" },
  { pattern: "/config/cxp/suppliers", key: "config.cxp.suppliers.view" },
  { pattern: "/config/cxp/supplier-types", key: "config.cxp.supplier-types.view" },
  { pattern: "/config/cxp/supplier-categories", key: "config.cxp.supplier-categories.view" },
  { pattern: "/config/company/doc-types", key: "config.company.doc-types.view" },
  { pattern: "/inventory/entry-types", key: "inventory.entry-types.view" },
  { pattern: "/inventory/exit-types", key: "inventory.exit-types.view" },
  { pattern: "/inventory/purchase-types", key: "inventory.purchase-types.view" },
  { pattern: "/inventory/transfer-types", key: "inventory.transfer-types.view" },
  { pattern: "/inventory/entries", key: "catalog.view" },
  { pattern: "/inventory/exits", key: "catalog.view" },
  { pattern: "/inventory/purchases", key: "catalog.view" },
  { pattern: "/inventory/transfers", key: "inventory.transfers.view" },
  { pattern: "/inventory/documents/history", key: "inventory.documents.history.view" },
  { pattern: "/config/currencies", key: "config.currencies.view" },
  { pattern: "/config/currencies/rates", key: "config.currencies.rates.view" },
  { pattern: "/config/currencies/history", key: "config.currencies.history.view" },
  { pattern: "/config/company/divisions", key: "config.company.divisions.view" },
  { pattern: "/config/company/branches", key: "config.company.branches.view" },
  { pattern: "/config/company/emission-points", key: "config.company.emission-points.view" },
  { pattern: "/config/company/warehouses", key: "config.company.warehouses.view" },
  { pattern: "/config/company/tax-rates", key: "config.company.tax-rates.view" },
  { pattern: "/config/facturacion/cajas-pos", key: "config.facturacion.cajas-pos.view" },
  { pattern: "/config/facturacion/descuentos", key: "config.facturacion.descuentos.view" },
  { pattern: "/config/facturacion/formas-pago", key: "config.facturacion.formas-pago.view" },
  { pattern: "/config/facturacion/tipos-facturas", key: "config.facturacion.tipos-facturas.view" },
  { pattern: "/config/facturacion/tipos-cotizaciones", key: "config.facturacion.tipos-cotizaciones.view" },
  { pattern: "/config/facturacion/tipos-conduces", key: "config.facturacion.tipos-conduces.view" },
  { pattern: "/config/facturacion/tipos-ordenes-pedido", key: "config.facturacion.tipos-ordenes-pedido.view" },
  { pattern: "/config/impuestos/tipos-comprobantes", key: "config.impuestos.tipos-comprobantes.view" },
  { pattern: "/config/impuestos/secuencias-fiscales", key: "config.impuestos.secuencias-fiscales.view" },
  { pattern: "/config/company", key: "config.company.view" },
  { pattern: "/facturacion/pos", key: "facturacion.pos.view" },
  { pattern: "/facturacion/caja-central", key: "facturacion.caja-central.view" },
  { pattern: "/facturacion/cotizaciones", key: "facturacion.cotizaciones.view" },
  { pattern: "/facturacion/conduces", key: "facturacion.conduces.view" },
  { pattern: "/facturacion/ordenes-pedido", key: "facturacion.ordenes-pedido.view" },
  { pattern: "/facturacion/devoluciones", key: "facturacion.devoluciones.view" },
  { pattern: "/facturacion/consultas/detalle-ventas", key: "facturacion.detalle-ventas.view" },
  { pattern: "/facturacion/consultas/resumen-ventas", key: "facturacion.resumen-ventas.view" },
  { pattern: "/impuestos/facturas-fiscales", key: "impuestos.facturas-fiscales.view" },
  { pattern: "/impuestos/gastos-menores", key: "impuestos.gastos-menores.view" },
  { pattern: "/impuestos/proveedores-informales", key: "impuestos.proveedores-informales.view" },
  { pattern: "/impuestos/pagos-exterior", key: "impuestos.pagos-exterior.view" },
  { pattern: "/impuestos/actualizacion-secuencias", key: "impuestos.actualizacion-secuencias.view" },
  { pattern: "/impuestos/informe-606", key: "impuestos.reportes.view" },
  { pattern: "/impuestos/informe-607", key: "impuestos.reportes.view" },
  { pattern: "/orders", key: "orders.view" },
  { pattern: "/dining-room", key: "dining-room.view" },
  { pattern: "/cash-register", key: "cash-register.view" },
  { pattern: "/reports", key: "reports.view" },
  { pattern: "/queries", key: "queries.view" },
  { pattern: "/dashboard", key: "dashboard.view" },
  { pattern: "/catalog", key: "catalog.view" },
  { pattern: "/security", key: "security.view" },
]

export function normalizeRoute(pathname: string) {
  const normalized = pathname.trim().toLowerCase()
  return LEGACY_ROUTE_MAP[normalized] || normalized
}

function isPathMatch(pattern: string, pathname: string) {
  if (pattern === "/") {
    return pathname === "/"
  }
  return pathname === pattern || pathname.startsWith(`${pattern}/`)
}

export function getPermissionKeyByPath(pathname: string): PermissionKey | null {
  const normalized = normalizeRoute(pathname)
  const match = ROUTE_PERMISSIONS.find((rule) => isPathMatch(rule.pattern, normalized))
  return match?.key ?? null
}

export function routeToPermissionKey(route: string): PermissionKey | null {
  return getPermissionKeyByPath(route)
}

export function serializePermissionKeys(keys: string[]) {
  return keys.join("|")
}

export function parsePermissionKeys(rawValue?: string) {
  if (!rawValue) return []
  return rawValue.split("|").map((item) => item.trim()).filter(Boolean)
}
