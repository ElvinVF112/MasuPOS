export type NavIconKey =
  | "dashboard"
  | "orders"
  | "dining"
  | "cash"
  | "invoice"
  | "tax"
  | "reports"
  | "queries"
  | "cxc"
  | "cxp"
  | "settings"
  | "building"
  | "inventory"
  | "currency"
  | "security"

export type NavigationOption = {
  key: string
  label: string
  href: string
  permission?: string
}

export type NavigationCategory = {
  key: string
  label: string
  options: NavigationOption[]
}

export type NavigationModule = {
  key: string
  label: string
  icon: NavIconKey
  permission?: string
  categories: NavigationCategory[]
}

export const NAVIGATION_TREE: NavigationModule[] = [
  {
    key: "dashboard",
    label: "Dashboard",
    icon: "dashboard",
    categories: [
      { key: "general", label: "General", options: [{ key: "dashboard-home", label: "Panel de Control", href: "/dashboard", permission: "dashboard.view" }] },
    ],
  },
  {
    key: "orders",
    label: "Órdenes",
    icon: "orders",
    categories: [
      { key: "operations", label: "Operaciones", options: [{ key: "orders-main", label: "Gestión de Órdenes", href: "/orders", permission: "orders.view" }] },
      { key: "queries", label: "Consultas", options: [{ key: "orders-queries", label: "Consulta de Órdenes", href: "/orders", permission: "orders.view" }] },
      { key: "masters", label: "Maestros", options: [{ key: "orders-masters", label: "Maestros de Órdenes", href: "/orders", permission: "orders.view" }] },
    ],
  },
  {
    key: "dining",
    label: "Salon",
    icon: "dining",
    categories: [
      { key: "operations", label: "Operaciones", options: [{ key: "dining-floor", label: "Mapa de Salon", href: "/dining-room", permission: "dining-room.view" }] },
      { key: "queries", label: "Consultas", options: [{ key: "dining-queries", label: "Consulta de Salon", href: "/dining-room", permission: "dining-room.view" }] },
      {
        key: "masters",
        label: "Maestros",
        options: [
          { key: "dining-resources", label: "Recursos", href: "/config/dining-room/resources", permission: "config.dining.resources.view" },
          { key: "dining-areas", label: "Areas", href: "/config/dining-room/areas", permission: "config.dining.areas.view" },
          { key: "dining-types", label: "Tipos de Recurso", href: "/config/dining-room/resource-types", permission: "config.dining.resource-types.view" },
          { key: "dining-categories", label: "Categorias de Recurso", href: "/config/dining-room/resource-categories", permission: "config.dining.resource-categories.view" },
        ],
      },
    ],
  },
  {
    key: "billing",
    label: "Facturacion",
    icon: "invoice",
    categories: [
      {
        key: "operations",
        label: "Operaciones",
        options: [
          { key: "billing-pos", label: "Punto de Ventas", href: "/facturacion/pos", permission: "facturacion.pos.view" },
          { key: "billing-central-cash", label: "Caja Central", href: "/facturacion/caja-central", permission: "facturacion.caja-central.view" },
          { key: "billing-quotes", label: "Cotizaciones", href: "/facturacion/cotizaciones", permission: "facturacion.cotizaciones.view" },
          { key: "billing-delivery", label: "Conduces", href: "/facturacion/conduces", permission: "facturacion.conduces.view" },
          { key: "billing-sales-orders", label: "Ordenes de Pedido", href: "/facturacion/ordenes-pedido", permission: "facturacion.ordenes-pedido.view" },
          { key: "billing-returns", label: "Devoluciones de Mercancia", href: "/facturacion/devoluciones", permission: "facturacion.devoluciones.view" },
        ],
      },
      {
        key: "queries",
        label: "Consultas",
        options: [
          { key: "billing-sales-detail", label: "Detalle de Ventas", href: "/facturacion/consultas/detalle-ventas", permission: "facturacion.detalle-ventas.view" },
          { key: "billing-sales-summary", label: "Resumen de Ventas", href: "/facturacion/consultas/resumen-ventas", permission: "facturacion.resumen-ventas.view" },
        ],
      },
      {
        key: "masters",
        label: "Maestros",
        options: [
          { key: "billing-pos-registers", label: "Cajas POS", href: "/config/facturacion/cajas-pos", permission: "config.facturacion.cajas-pos.view" },
          { key: "billing-discounts", label: "Descuentos", href: "/config/cxc/discounts", permission: "config.cxc.discounts.view" },
          { key: "billing-payment-methods", label: "Formas de Pago", href: "/config/facturacion/formas-pago", permission: "config.facturacion.formas-pago.view" },
          { key: "billing-invoice-types", label: "Tipos de Facturas", href: "/config/facturacion/tipos-facturas", permission: "config.facturacion.tipos-facturas.view" },
          { key: "billing-quote-types", label: "Tipos de Cotizacion", href: "/config/facturacion/tipos-cotizaciones", permission: "config.facturacion.tipos-cotizaciones.view" },
          { key: "billing-delivery-types", label: "Tipos de Conduce", href: "/config/facturacion/tipos-conduces", permission: "config.facturacion.tipos-conduces.view" },
          { key: "billing-sales-order-types", label: "Tipos de Ordenes de Pedido", href: "/config/facturacion/tipos-ordenes-pedido", permission: "config.facturacion.tipos-ordenes-pedido.view" },
        ],
      },
    ],
  },
  {
    key: "taxes",
    label: "Impuestos",
    icon: "tax",
    categories: [
      {
        key: "operations",
        label: "Operaciones",
        options: [
          { key: "tax-fiscal-invoices", label: "Facturas Fiscales", href: "/impuestos/facturas-fiscales", permission: "impuestos.facturas-fiscales.view" },
          { key: "tax-minor-expenses", label: "Gastos Menores", href: "/impuestos/gastos-menores", permission: "impuestos.gastos-menores.view" },
          { key: "tax-informal-suppliers", label: "Proveedores Informales", href: "/impuestos/proveedores-informales", permission: "impuestos.proveedores-informales.view" },
          { key: "tax-foreign-payments", label: "Pagos al Exterior", href: "/impuestos/pagos-exterior", permission: "impuestos.pagos-exterior.view" },
          { key: "tax-seq-update", label: "Actualizacion de Secuencias", href: "/impuestos/actualizacion-secuencias", permission: "impuestos.actualizacion-secuencias.view" },
        ],
      },
      {
        key: "queries",
        label: "Consultas",
        options: [
          { key: "tax-606", label: "Informe Fiscal 606", href: "/impuestos/informe-606", permission: "impuestos.reportes.view" },
          { key: "tax-607", label: "Informe Fiscal 607", href: "/impuestos/informe-607", permission: "impuestos.reportes.view" },
        ],
      },
      {
        key: "registry",
        label: "Terceros",
        options: [
          { key: "tax-customers", label: "Clientes", href: "/config/cxc/customers", permission: "config.cxc.customers.view" },
          { key: "tax-suppliers", label: "Proveedores", href: "/config/cxp/suppliers", permission: "config.cxp.suppliers.view" },
        ],
      },
      {
        key: "masters",
        label: "Configuración",
        options: [
          { key: "tax-voucher-types", label: "Tipos de Comprobantes", href: "/config/impuestos/tipos-comprobantes", permission: "config.impuestos.tipos-comprobantes.view" },
          { key: "tax-sequences", label: "Secuencias Fiscales", href: "/config/impuestos/secuencias-fiscales", permission: "config.impuestos.secuencias-fiscales.view" },
        ],
      },
    ],
  },
  {
    key: "reports",
    label: "Reportes",
    icon: "reports",
    categories: [
      { key: "analytics", label: "Analitica", options: [{ key: "reports-main", label: "Reportes", href: "/reports", permission: "reports.view" }] },
    ],
  },
  {
    key: "inventory",
    label: "Inventario",
    icon: "inventory",
    categories: [
      {
        key: "operations",
        label: "Operaciones",
        options: [
          { key: "inventory-entries", label: "Entradas de Inventario", href: "/inventory/entries", permission: "catalog.view" },
          { key: "inventory-exits", label: "Salidas de Inventario", href: "/inventory/exits", permission: "catalog.view" },
          { key: "inventory-purchases", label: "Entradas por Compras", href: "/inventory/purchases", permission: "catalog.view" },
          { key: "inventory-transfers", label: "Transferencias", href: "/inventory/transfers", permission: "inventory.transfers.view" },
        ],
      },
      { key: "queries", label: "Consultas", options: [{ key: "inventory-queries", label: "Consultas de Inventario", href: "/catalog", permission: "catalog.view" }] },
      {
        key: "masters",
        label: "Maestros",
        options: [
          { key: "catalog-products", label: "Productos", href: "/config/catalog/products", permission: "config.catalog.products.view" },
          { key: "catalog-categories", label: "Categorias", href: "/config/catalog/categories", permission: "config.catalog.categories.view" },
          { key: "catalog-types", label: "Tipos", href: "/config/catalog/product-types", permission: "config.catalog.product-types.view" },
          { key: "catalog-units", label: "Unidades", href: "/config/catalog/units", permission: "config.catalog.units.view" },
          { key: "catalog-price-lists", label: "Listas Precios", href: "/config/catalog/price-lists", permission: "config.catalog.price-lists.view" },
          { key: "catalog-stock-limits", label: "Minimo, Maximo, Reorden", href: "/config/catalog/stock-limits", permission: "config.catalog.products.view" },
          { key: "inv-entry-types", label: "Tipos de Entradas", href: "/inventory/entry-types", permission: "inventory.entry-types.view" },
          { key: "inv-exit-types", label: "Tipos de Salidas", href: "/inventory/exit-types", permission: "inventory.exit-types.view" },
          { key: "inv-purchase-types", label: "Tipos Entradas por Compras", href: "/inventory/purchase-types", permission: "inventory.purchase-types.view" },
          { key: "inv-transfer-types", label: "Tipos de Transferencias", href: "/inventory/transfer-types", permission: "inventory.transfer-types.view" },
        ],
      },
    ],
  },
  {
    key: "cxc",
    label: "Cuentas por Cobrar",
    icon: "cxc",
    categories: [
      {
        key: "operations", label: "Operaciones",
        options: [
          { key: "cxc-invoices", label: "Facturas a Credito", href: "/cxc/invoices", permission: "cxc.invoices.view" },
          { key: "cxc-credit-notes", label: "Notas de Credito", href: "/cxc/credit-notes", permission: "cxc.credit-notes.view" },
          { key: "cxc-debit-notes", label: "Notas de Debito", href: "/cxc/debit-notes", permission: "cxc.debit-notes.view" },
        ],
      },
      {
        key: "masters", label: "Maestros",
        options: [
          { key: "cxc-customers", label: "Clientes", href: "/config/cxc/customers", permission: "config.cxc.customers.view" },
          { key: "cxc-customer-types", label: "Tipos de Clientes", href: "/config/cxc/customer-types", permission: "config.cxc.customer-types.view" },
          { key: "cxc-customer-categories", label: "Categorias de Clientes", href: "/config/cxc/customer-categories", permission: "config.cxc.customer-categories.view" },
          { key: "cxc-discounts", label: "Descuentos", href: "/config/cxc/discounts", permission: "config.cxc.discounts.view" },
        ],
      },
      {
        key: "queries", label: "Consultas",
        options: [
          { key: "cxc-queries", label: "Consultas CxC", href: "/cxc/queries", permission: "cxc.queries.view" },
        ],
      },
    ],
  },
  {
    key: "cxp",
    label: "Cuentas por Pagar",
    icon: "cxp",
    categories: [
      {
        key: "operations", label: "Operaciones",
        options: [
          { key: "cxp-invoices", label: "Facturas de Proveedores", href: "/cxp/invoices", permission: "cxp.invoices.view" },
          { key: "cxp-credit-notes", label: "Notas de Credito Proveedores", href: "/cxp/credit-notes", permission: "cxp.credit-notes.view" },
          { key: "cxp-debit-notes", label: "Notas de Debito Proveedores", href: "/cxp/debit-notes", permission: "cxp.debit-notes.view" },
        ],
      },
      {
        key: "masters", label: "Maestros",
        options: [
          { key: "cxp-suppliers", label: "Proveedores", href: "/config/cxp/suppliers", permission: "config.cxp.suppliers.view" },
          { key: "cxp-supplier-types", label: "Tipos de Proveedores", href: "/config/cxp/supplier-types", permission: "config.cxp.supplier-types.view" },
          { key: "cxp-supplier-categories", label: "Categorias de Proveedores", href: "/config/cxp/supplier-categories", permission: "config.cxp.supplier-categories.view" },
        ],
      },
      {
        key: "queries", label: "Consultas",
        options: [
          { key: "cxp-queries", label: "Consultas CxP", href: "/cxp/queries", permission: "cxp.queries.view" },
        ],
      },
    ],
  },
  {
    key: "configuration",
    label: "Configuracion",
    icon: "settings",
    categories: [
      {
        key: "company",
        label: "Empresa",
        options: [
          { key: "company-main", label: "Datos Generales", href: "/config/company", permission: "config.company.view" },
          { key: "company-divisions", label: "Divisiones", href: "/config/company/divisions", permission: "config.company.divisions.view" },
          { key: "company-branches", label: "Sucursales", href: "/config/company/branches", permission: "config.company.branches.view" },
          { key: "company-emission", label: "Puntos Emision", href: "/config/company/emission-points", permission: "config.company.emission-points.view" },
          { key: "company-warehouses", label: "Almacenes", href: "/config/company/warehouses", permission: "config.company.warehouses.view" },
          { key: "company-tax-rates", label: "Tasas Impuesto", href: "/config/company/tax-rates", permission: "config.company.tax-rates.view" },
        ],
      },
      {
        key: "currencies",
        label: "Monedas",
        options: [
          { key: "currencies-main", label: "Monedas", href: "/config/currencies", permission: "config.currencies.view" },
          { key: "currency-rates", label: "Tasas", href: "/config/currencies/rates", permission: "config.currencies.rates.view" },
          { key: "currency-history", label: "Historico", href: "/config/currencies/history", permission: "config.currencies.history.view" },
        ],
      },
      {
        key: "referencias",
        label: "Referencias",
        options: [
          { key: "doc-types", label: "Documentos Identidad", href: "/config/company/doc-types", permission: "config.company.doc-types.view" },
        ],
      },
      {
        key: "security",
        label: "Seguridad",
        options: [
          { key: "security-users", label: "Usuarios", href: "/config/security/users", permission: "config.security.users.view" },
          { key: "security-roles", label: "Roles", href: "/config/security/roles", permission: "config.security.roles.view" },
        ],
      },
    ],
  },
]

export function isRouteMatch(pathname: string, href: string) {
  if (href === "/") return pathname === "/"
  return pathname === href || pathname.startsWith(`${href}/`)
}

export function filterNavigationByPermission(modules: NavigationModule[], canView: (permission?: string) => boolean): NavigationModule[] {
  return modules
    .map((module) => {
      if (!canView(module.permission)) return null
      const categories = module.categories
        .map((category) => ({
          ...category,
          options: category.options.filter((option) => canView(option.permission)),
        }))
        .filter((category) => category.options.length > 0)
      if (categories.length === 0) return null
      return { ...module, categories }
    })
    .filter((module): module is NavigationModule => module !== null)
}

export function getNavigationTrail(pathname: string, modules: NavigationModule[]) {
  let best:
    | {
        module: NavigationModule
        category: NavigationCategory
        option: NavigationOption
      }
    | null = null
  let bestLength = -1

  for (const module of modules) {
    for (const category of module.categories) {
      for (const option of category.options) {
        if (isRouteMatch(pathname, option.href)) {
          const currentLength = option.href.length
          if (currentLength <= bestLength) continue
          best = {
            module,
            category,
            option,
          }
          bestLength = currentLength
        }
      }
    }
  }

  return best
}

export function getNavigationOptionLabel(
  href: string,
  fallbackModule?: string,
  fallbackCategory?: string,
  fallbackOption?: string,
) {
  const trail = getNavigationTrail(href, NAVIGATION_TREE)

  if (trail) {
    return `${trail.module.label} >> ${trail.category.label} >> ${trail.option.label}`
  }

  const parts = [fallbackModule, fallbackCategory, fallbackOption].map((part) => (part ?? "").trim()).filter(Boolean)
  if (parts.length > 0) {
    return parts.join(" >> ")
  }

  return href || fallbackOption || ""
}
