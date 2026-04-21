import { getPool, sql, TYPES } from "@/lib/db"
import { getNavigationOptionLabel } from "@/lib/navigation"

export type DashboardSummary = {
  activeOrders: number
  resourcesInUse: number
  activeUsers: number
  products: number
  modulesConfigured: number
  salesTotal: number
}

export type ModuleSnapshot = {
  title: string
  count: number
  detail: string
}

export type ResourceStatus = "disponible" | "ocupada" | "pendiente" | "lista" | "pagando"

export type OrderItem = {
  id: number
  name: string
  quantity: number
  units: number
  personNumber?: number
  price: number
  taxPercent: number
  taxAmount: number
  total: number
  note?: string
  createdAt?: string
  createdBy?: string
}

export type ResourceBoardItem = {
  id: number
  name: string
  category: string
  area: string
  seats: number
  categoryColor: string
  categoryShape?: string
  status: ResourceStatus
  resourceState: string
  orderId?: number
  orderNumber?: string
  orderState?: string
  waiter?: string
  time?: string
  subtotal?: number
  tax?: number
  total?: number
  items: OrderItem[]
}

export type OrderProductOption = {
  id: number
  code: string
  name: string
  category: string
  image: string | null
  categoryImage: string | null
  categoryButtonBackground: string
  categoryButtonColor: string
  categoryButtonText: string
  itemButtonBackground: string
  itemButtonColor: string
  itemButtonText: string
  price: number
  unitId: number
  unitName: string
  applyTax: boolean
  taxRate: number
  applyTip: boolean
  canSellInBilling: boolean
  allowDiscount: boolean
  allowPriceChange: boolean
  managesStock: boolean
  sellWithoutStock: boolean
  stock: number
}

export type OpenOrderTicket = {
  id: number
  number: string
  state: string
  waiter: string
  time: string
  createdAt?: string
  guestCount: number
  ownerUserId: number
  reference: string
  total: number
  items: OrderItem[]
}

export type ResourceOrderTray = {
  id: number
  name: string
  area: string
  category: string
  categoryColor: string
  lockedByUserId: number | null
  lockedByUsername: string
  openOrders: OpenOrderTicket[]
  openCount: number
  totalOpen: number
  firstOrderTime: string
}

export type OrdersTrayData = {
  resources: ResourceOrderTray[]
  products: OrderProductOption[]
  companyApplyTip: boolean
  companyTipPercent: number
  companyRestrictOrdersByUser: boolean
  companyLockTablesByUser: boolean
  currencySymbol: string
}

export type OrderSummaryRecord = {
  id: number
  number: string
  resourceId: number
  resourceName: string
  stateId: number
  stateName: string
  waiterId: number
  waiterName: string
  username: string
  orderDate: string
  closeDate: string | null
  reference: string
  observations: string
  guestCount: number
  subtotal: number
  tax: number
  total: number
  lineCount: number
}

export type OrderLineRecord = {
  id: number
  orderId: number
  productId: number
  productName: string
  unitId: number
  unitName: string
  unitAbbr: string
  stateDetailId: number
  stateDetailName: string
  quantity: number
  units: number
  price: number
  taxPercent: number
  subtotal: number
  tax: number
  total: number
  note: string
  personNumber: number
  createdAt?: string
  createdBy?: string
}

export type OrderRecord = OrderSummaryRecord & {
  detail: OrderLineRecord[]
}

export type OrderHistoryRecord = {
  id: number
  orderId: number
  orderLineId: number | null
  movementType: string
  previousState: string
  currentState: string
  note: string
  movementDate: string
  userId: number
  username: string
  fullName: string
}

export type SupervisorVerificationResult = {
  userId: number
  username: string
  fullName: string
  roleId: number
  roleName: string
  userType: "A" | "S" | "O"
  permissionKey: string
}

export type SecuritySnapshot = {
  totals: {
    users: number
    roles: number
    modules: number
    screens: number
    permissions: number
  }
  users: Array<{
    id: number
    userName: string
    fullName: string
    email: string
    active: boolean
  }>
  roles: Array<{
    id: number
    name: string
    description: string
    usersAssigned: number
  }>
  modules: Array<{
    id: number
    name: string
    screens: number
    icon?: string
  }>
}

export type CatalogSnapshot = {
  totals: {
    categories: number
    productTypes: number
    units: number
    products: number
  }
  products: Array<{
    id: number
    name: string
    category: string
    type: string
    baseUnit: string
    saleUnit: string
    price: number
  }>
  units: Array<{
    id: number
    name: string
    abbreviation: string
    baseA: number
    baseB: number
    factor: number
  }>
}

export type SelectOption = {
  id: number
  name: string
}

export type ProductRecord = {
  id: number
  code: string
  comment: string
  imagen?: string | null
  categoryId: number
  typeId: number
  unitBaseId: number
  unitSaleId: number
  unitPurchaseId: number
  unitAlt1Id?: number
  unitAlt2Id?: number
  unitAlt3Id?: number
  name: string
  description: string
  price: number
  applyTax: boolean
  taxRateId: number | null
  taxRate: number
  stockUnitBase: string
  canSellInBilling: boolean
  allowDiscount: boolean
  allowPriceChange: boolean
  allowManualPrice: boolean
  requestUnit: boolean
  requestUnitInventory: boolean
  allowDecimals: boolean
  sellWithoutStock: boolean
  applyTip: boolean
  managesStock: boolean
  prices: Array<{
    priceListId: number
    profitPercent: number
    price: number
    tax: number
    priceWithTax: number
  }>
  costs: {
    currencyId: number | null
    providerDiscount: number
    providerCost: number
    providerCostWithTax: number
    averageCost: number
    allowManualAvgCost: boolean
  }
  offer: {
    active: boolean
    price: number
    startDate: string
    endDate: string
  }
  active: boolean
  category: string
  type: string
  unitBase: string
  unitSale: string
  unitPurchase: string
}

export type ProductListItem = Pick<ProductRecord, "id" | "code" | "name" | "price" | "active" | "category" | "type" | "imagen">

export type ProductWarehouseRecord = {
  warehouseId: number
  warehouseName: string
  initials: string
  type: string
  quantity: number
  reserved: number
  inTransit: number
  available: number
}

export type ProductStockRow = {
  warehouseId: number
  warehouseName: string
  minimo: number | null
  maximo: number | null
  puntoReorden: number | null
  existencia: number
  pendienteRecibir: number
  pendienteEntregar: number
  existenciaReal: number
  reservado: number
  disponibleBase: number
  unitCompraId: number | null
  unitCompraName: string | null
  unitCompraAbbrev: string | null
  unitCompraDisponible: number | null
  unitName: string
  unitAbbrev: string
  alterna1?: { unitId: number; name: string; abbrev: string; disponible: number } | null
  alterna2?: { unitId: number; name: string; abbrev: string; disponible: number } | null
  alterna3?: { unitId: number; name: string; abbrev: string; disponible: number } | null
}

export type InvKardexRecord = {
  idMovimiento: number
  fecha: string
  tipoMovimiento: string
  numeroDocumento: string
  observacion: string
  entrada: number
  salida: number
  saldo: number
  costoUnitario: number
  costoTotal: number
  costoPromedio: number
  nombreAlmacen: string
}

export type InvMovimientoRecord = {
  idMovimiento: number
  fecha: string
  tipoMovimiento: string
  numeroDocumento: string
  observacion: string
  entrada: number
  salida: number
  costoUnitario: number
  costoTotal: number
  nombreAlmacen: string
}

export type InvExistenciaAlFechaRecord = {
  idProducto: number
  nombreProducto: string
  idAlmacen: number
  nombreAlmacen: string
  fechaConsulta: string
  existencia: number
  costoPromedio: number
}

export type WarehouseOption = {
  id: number
  name: string
  initials: string
  type: string
}

export type CatalogManagerData = {
  totals: CatalogSnapshot["totals"]
  products: ProductRecord[]
  lookups: {
    categories: SelectOption[]
    productTypes: SelectOption[]
    units: Array<SelectOption & { abbreviation: string }>
    priceLists: Array<{ id: number; code: string; description: string; abbreviation: string; currencyId: number | null; active: boolean }>
    currencies: Array<{ id: number; code: string; name: string; symbol: string | null }>
    taxRates: Array<{ id: number; name: string; rate: number; code: string }>
    warehouses: Array<{ id: number; name: string; initials: string; type: string }>
  }
}

export type DiningRoomSnapshot = {
  totals: {
    areas: number
    resourceTypes: number
    resourceCategories: number
    resources: number
  }
  resources: Array<{
    id: number
    name: string
    area: string
    type: string
    category: string
    state: string
    hasActiveOrder: boolean
  }>
}

export type ResourceRecord = {
  id: number
  categoryId: number
  name: string
  state: string
  seats: number
  active: boolean
}

export type DiningRoomManagerData = {
  totals: DiningRoomSnapshot["totals"]
  resources: ResourceRecord[]
  board: ResourceBoardItem[]
  lookups: {
    resourceCategories: Array<SelectOption & { area: string; type: string; color: string }>
  }
}

export type AdminEntityName =
  | "users"
  | "roles"
  | "modules"
  | "screens"
  | "permissions"
  | "role-permissions"
  | "categories"
  | "product-types"
  | "units"
  | "areas"
  | "resource-types"
  | "resource-categories"

export type SecurityManagerData = {
  users: Array<{
    id: number
    roleId: number
    roleName: string
    userType: "A" | "S" | "O"
    startScreenId?: number
    startScreen: string
    startRoute: string
    names: string
    surnames: string
    userName: string
    email: string
    passwordHash: string
    mustChangePassword: boolean
    canDeletePosLines: boolean
    canChangePosDate: boolean
    locked: boolean
    active: boolean
    companyId?: number
    companyName: string
    divisionId?: number
    divisionName: string
    branchId?: number
    branchName: string
    emissionPointId?: number
    emissionPointName: string
    dataAccessLevel: "G" | "E" | "D" | "S" | "P" | "U"
    createdBy: number
    createdAt: string
    updatedBy: number
    updatedAt: string
  }>
  roles: Array<{ id: number; name: string; description: string; active: boolean; createdAt: string }>
  modules: Array<{ id: number; name: string; icon: string; order: number; active: boolean }>
  screens: Array<{ id: number; moduleId: number; module: string; name: string; route: string; controller: string; action: string; icon: string; order: number; active: boolean }>
  permissions: Array<{ id: number; screenId: number; screen: string; module: string; name: string; description: string; clave: string; canView: boolean; canCreate: boolean; canEdit: boolean; canDelete: boolean; canApprove: boolean; canCancel: boolean; canPrint: boolean; active: boolean }>
  rolePermissions: Array<{ id: number; roleId: number; roleName: string; permissionId: number; permissionName: string; module: string; screen: string; active: boolean }>
  lookups: {
    companies: SelectOption[]
    roles: SelectOption[]
    divisions: Array<SelectOption>
    branches: Array<SelectOption & { divisionId: number }>
    emissionPoints: Array<SelectOption & { branchId: number; divisionId: number }>
    modules: SelectOption[]
    screens: SelectOption[]
    permissions: SelectOption[]
  }
}

export type RoleFieldVisibilityKey =
  | "id_registros"
  | "precios"
  | "costos"
  | "cantidades"
  | "descuentos"
  | "impuestos"
  | "subtotales"
  | "totales_netos"
  | "margenes"
  | "comisiones"
  | "info_cliente"
  | "metodos_pago"

export type RoleModulePermissionSnapshot = {
  id: number
  name: string
  icon: string
  enabled: boolean
  screens?: RoleScreenPermissionSnapshot[]
}

export type RoleScreenPermissionSnapshot = {
  id: number
  moduleId: number
  module: string
  name: string
  route: string
  access: boolean
  canCreate: boolean
  canEdit: boolean
  canDelete: boolean
  canView: boolean
  canApprove: boolean
  canCancel: boolean
  canPrint: boolean
}

export type RolePermissionsPayload = {
  modules: RoleModulePermissionSnapshot[]
  screens: RoleScreenPermissionSnapshot[]
  fieldVisibility: Partial<Record<RoleFieldVisibilityKey, boolean>>
}

export type CatalogMastersData = {
  categories: Array<{ id: number; name: string; description: string; active: boolean }>
  productTypes: Array<{ id: number; name: string; description: string; active: boolean }>
  units: Array<{ id: number; name: string; abbreviation: string; baseA: number; baseB: number; factor: number; active: boolean }>
}

export type DiningMastersData = {
  areas: Array<{ id: number; name: string; description: string; order: number; active: boolean }>
  resourceTypes: Array<{ id: number; name: string; description: string; active: boolean }>
  resourceCategories: Array<{ id: number; typeId: number; areaId: number; name: string; description: string; active: boolean; area: string; type: string; color: string; shape: string }>
  lookups: {
    areas: SelectOption[]
    resourceTypes: SelectOption[]
  }
}

export type PriceListRecord = {
  id: number
  code: string
  description: string
  abbreviation: string
  currencyId: number | null
  startDate: string
  endDate: string
  active: boolean
  totalUsers: number
}

export type ProductTypeRecord = {
  id: number
  name: string
  description: string
  active: boolean
  fechaCreacion: string | null
}

export type UnitRecord = {
  id: number
  name: string
  abbreviation: string
  baseA: number
  baseB: number
  factor: number
  active: boolean
}

export type PriceListUser = {
  id: number
  userName: string
  names: string
  surnames: string
}

export type CategoryRecord = {
  id: number
  name: string
  description: string
  active: boolean
  fechaCreacion: string
  codigo: string | null
  codigoCorto: string | null
  nombreCorto: string | null
  idCategoriaPadre: number | null
  idMoneda: number | null
  colorFondo: string
  colorBoton: string
  colorTexto: string
  colorFondoItem: string
  colorBotonItem: string
  colorTextoItem: string
  tamanoTexto: number
  columnasPOS: number
  mostrarEnPOS: boolean
  imagen: string | null
  categoriaPadreNombre: string | null
  monedaCodigo: string | null
  monedaSimbolo: string | null
  totalSubcategorias: number
  totalProductos: number
}

export type CurrencyRecord = {
  id: number
  code: string
  name: string
  symbol: string | null
  symbolAlt: string | null
  isLocal: boolean
  bankCode: string | null
  factorConversionLocal: number
  factorConversionUSD: number
  showInPOS: boolean
  acceptPayments: boolean
  decimalPOS: number
  active: boolean
  lastRateDate: string
  rateAdministrative: number | null
  rateOperative: number | null
  ratePurchase: number | null
  rateSale: number | null
}

export type CurrencyHistoryRecord = {
  id: number
  currencyId: number
  currencyCode: string
  currencyName: string
  symbol: string | null
  date: string
  rateAdministrative: number | null
  rateOperative: number | null
  ratePurchase: number | null
  rateSale: number | null
  userName: string | null
  registrationDate: string
  totalRecords: number
  totalPages: number
  currentPage: number
}

export type CompanySettingsData = {
  id?: number
  fiscalId: string
  businessName: string
  tradeName: string
  address: string
  city: string
  stateProvince: string
  postalCode: string
  country: string
  phone1: string
  phone2: string
  email: string
  website: string
  instagram: string
  facebook: string
  x: string
  logoUrl: string
  hasLogoBinary: boolean
  logoUpdatedAt: string
  currency: string
  secondaryCurrency: string
  active: boolean
  slogan: string
  sessionDurationMinutes: number
  sessionIdleMinutes: number
  applyTax: boolean
  taxName: string
  taxPercent: number
  applyTip: boolean
  tipName: string
  tipPercent: number
  restrictOrdersByUser: boolean
  lockTablesByUser: boolean
}

type QueryRow = Record<string, unknown>

function toNumber(value: unknown) {
  return typeof value === "number" ? value : Number(value ?? 0)
}

function toText(value: unknown, fallback = "") {
  return typeof value === "string" ? value : fallback
}

function toUserType(value: unknown, roleName?: string): "A" | "S" | "O" {
  const normalized = toText(value).trim().toUpperCase()
  if (normalized === "A" || normalized === "S" || normalized === "O") return normalized
  const role = (roleName ?? "").trim().toLowerCase()
  if (role.includes("admin")) return "A"
  if (role.includes("supervisor")) return "S"
  return "O"
}

function mapOrderState(orderState: string | undefined, resourceState: string | undefined): ResourceStatus {
  const normalizedOrder = orderState?.toLowerCase()
  const normalizedResource = resourceState?.toLowerCase()

  if (normalizedOrder === "en proceso") {
    return "pendiente"
  }

  if (normalizedOrder === "abierta") {
    return normalizedResource === "libre" ? "ocupada" : "ocupada"
  }

  if (normalizedOrder === "cerrada") {
    return "lista"
  }

  if (normalizedOrder === "anulada") {
    return "pagando"
  }

  return "disponible"
}

export async function getDashboardSummary(): Promise<DashboardSummary> {
  const pool = await getPool()
  const result = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT
      (SELECT COUNT(*) FROM dbo.Ordenes O INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden WHERE O.RowStatus = 1 AND E.Nombre IN ('Abierta', 'En proceso')) AS ActiveOrders,
      (SELECT COUNT(*) FROM dbo.Recursos R WHERE R.RowStatus = 1 AND EXISTS (SELECT 1 FROM dbo.Ordenes O INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden WHERE O.IdRecurso = R.IdRecurso AND O.RowStatus = 1 AND E.Nombre IN ('Abierta', 'En proceso'))) AS ResourcesInUse,
      (SELECT COUNT(*) FROM dbo.Usuarios WHERE RowStatus = 1 AND Activo = 1) AS ActiveUsers,
      (SELECT COUNT(*) FROM dbo.Productos WHERE RowStatus = 1) AS Products,
      (SELECT COUNT(*) FROM dbo.Modulos WHERE RowStatus = 1) AS ModulesConfigured,
      (SELECT ISNULL(SUM(Total), 0) FROM dbo.Ordenes WHERE RowStatus = 1) AS SalesTotal;
  `)

  const row = result.recordset[0] as QueryRow

  return {
    activeOrders: toNumber(row.ActiveOrders),
    resourcesInUse: toNumber(row.ResourcesInUse),
    activeUsers: toNumber(row.ActiveUsers),
    products: toNumber(row.Products),
    modulesConfigured: toNumber(row.ModulesConfigured),
    salesTotal: toNumber(row.SalesTotal),
  }
}

export async function getModuleSnapshots(): Promise<ModuleSnapshot[]> {
  const pool = await getPool()
  const result = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT 'Seguridad' AS Title, COUNT(*) AS Total, 'Usuarios, roles, modulos, pantallas y permisos configurados.' AS Detail
    FROM dbo.Usuarios WHERE RowStatus = 1
    UNION ALL
    SELECT 'Catalogos', COUNT(*), 'Categorias, tipos, productos y unidades disponibles para pruebas.'
    FROM dbo.Productos WHERE RowStatus = 1
    UNION ALL
    SELECT 'Salon', COUNT(*), 'Recursos operativos asociados a areas y categorias.'
    FROM dbo.Recursos WHERE RowStatus = 1
    UNION ALL
    SELECT 'Ordenes', COUNT(*), 'Ordenes y detalle conectados directamente a SQL Server.'
    FROM dbo.Ordenes WHERE RowStatus = 1;
  `)

  return result.recordset.map((row: QueryRow) => ({
    title: toText(row.Title),
    count: toNumber(row.Total),
    detail: toText(row.Detail),
  }))
}

export async function getSecuritySnapshot(): Promise<SecuritySnapshot> {
  const pool = await getPool()
  const [totalsResult, usersResult, rolesResult, modulesResult] = await Promise.all([
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        (SELECT COUNT(*) FROM dbo.Usuarios WHERE RowStatus = 1) AS Users,
        (SELECT COUNT(*) FROM dbo.Roles WHERE RowStatus = 1) AS Roles,
        (SELECT COUNT(*) FROM dbo.Modulos WHERE RowStatus = 1) AS Modules,
        (SELECT COUNT(*) FROM dbo.Pantallas WHERE RowStatus = 1) AS Screens,
        (SELECT COUNT(*) FROM dbo.Permisos WHERE RowStatus = 1) AS Permissions;
    `),
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT TOP (20)
        IdUsuario,
        NombreUsuario,
        CONCAT(Nombres, ' ', Apellidos) AS FullName,
        ISNULL(Correo, '') AS Correo,
        Activo
      FROM dbo.Usuarios
      WHERE RowStatus = 1
      ORDER BY IdUsuario;
    `),
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT TOP (20)
        R.IdRol,
        R.Nombre,
        ISNULL(R.Descripcion, '') AS Descripcion,
        COUNT(U.IdUsuario) AS UsersAssigned
      FROM dbo.Roles R
      LEFT JOIN dbo.Usuarios U ON U.IdRol = R.IdRol AND U.RowStatus = 1
      WHERE R.RowStatus = 1
      GROUP BY R.IdRol, R.Nombre, R.Descripcion
      ORDER BY R.IdRol;
    `),
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT TOP (20)
        M.IdModulo,
        M.Nombre,
        ISNULL(M.Icono, '') AS Icono,
        COUNT(P.IdPantalla) AS Screens
      FROM dbo.Modulos M
      LEFT JOIN dbo.Pantallas P ON P.IdModulo = M.IdModulo AND P.RowStatus = 1
      WHERE M.RowStatus = 1
      GROUP BY M.IdModulo, M.Nombre, M.Icono, M.Orden
      ORDER BY M.Orden, M.IdModulo;
    `),
  ])

  const totals = totalsResult.recordset[0] as QueryRow

  return {
    totals: {
      users: toNumber(totals.Users),
      roles: toNumber(totals.Roles),
      modules: toNumber(totals.Modules),
      screens: toNumber(totals.Screens),
      permissions: toNumber(totals.Permissions),
    },
    users: usersResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdUsuario),
      userName: toText(row.NombreUsuario),
      fullName: toText(row.FullName),
      email: toText(row.Correo, "Sin correo"),
      active: Boolean(row.Activo),
    })),
    roles: rolesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdRol),
      name: toText(row.Nombre),
      description: toText(row.Descripcion, "Sin descripcion"),
      usersAssigned: toNumber(row.UsersAssigned),
    })),
    modules: modulesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdModulo),
      name: toText(row.Nombre),
      screens: toNumber(row.Screens),
      icon: toText(row.Icono),
    })),
  }
}

export async function getSecurityManagerData(): Promise<SecurityManagerData> {
  const pool = await getPool()
  const company = await getCompanySettingsData()
  const [usersResult, rolesResult, modulesResult, screensResult, permissionsResult, rolePermissionsResult, divisions, branches, emissionPoints] = await Promise.all([
    pool.request().input("Accion", "L").execute("dbo.spUsuariosCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spRolesCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spModulosCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spPantallasCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spPermisosCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spRolesPermisosCRUD"),
    getDivisions(),
    getBranches(),
    getEmissionPoints(),
  ])

  const users = usersResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdUsuario),
    roleId: toNumber(row.IdRol),
    roleName: toText(row.Rol),
    userType: toUserType(row.TipoUsuario, toText(row.Rol)),
    startScreenId: row.IdPantallaInicio ? toNumber(row.IdPantallaInicio) : undefined,
    startScreen: toText(row.PantallaInicio),
    startRoute: toText(row.RutaInicio, "/"),
    names: toText(row.Nombres),
    surnames: toText(row.Apellidos),
    userName: toText(row.NombreUsuario),
    email: toText(row.Correo),
    passwordHash: "",
    mustChangePassword: Boolean(row.RequiereCambioClave),
    canDeletePosLines: Boolean(row.PuedeEliminarLineaPOS),
    canChangePosDate: Boolean(row.PuedeCambiarFechaPOS),
    locked: Boolean(row.Bloqueado),
    active: Boolean(row.Activo),
    companyId: row.IdEmpresa ? toNumber(row.IdEmpresa) : undefined,
    companyName: toText(row.EmpresaNombre || company.tradeName || company.businessName),
    divisionId: row.IdDivision ? toNumber(row.IdDivision) : undefined,
    divisionName: toText(row.DivisionNombre),
    branchId: row.IdSucursal ? toNumber(row.IdSucursal) : undefined,
    branchName: toText(row.SucursalNombre),
    emissionPointId: row.IdPuntoEmision ? toNumber(row.IdPuntoEmision) : undefined,
    emissionPointName: toText(row.PuntoEmisionNombre),
    dataAccessLevel: (toText(row.NivelAcceso, "G").toUpperCase() as "G" | "E" | "D" | "S" | "P" | "U"),
    createdBy: toNumber(row.UsuarioCreacion),
    createdAt: row.FechaCreacion ? String(row.FechaCreacion) : "",
    updatedBy: toNumber(row.UsuarioModificacion),
    updatedAt: row.FechaModificacion ? String(row.FechaModificacion) : "",
  }))

  const roles = rolesResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdRol),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    active: Boolean(row.Activo),
    createdAt: row.FechaCreacion ? String(row.FechaCreacion) : "",
  }))

  const modules = modulesResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdModulo),
    name: toText(row.Nombre),
    icon: toText(row.Icono),
    order: toNumber(row.Orden),
    active: Boolean(row.Activo),
  }))

  const screens = screensResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdPantalla),
    moduleId: toNumber(row.IdModulo),
    module: toText(row.ModuloNombre || row.Modulo),
    name: toText(row.Nombre),
    route: toText(row.Ruta),
    controller: toText(row.Controlador),
    action: toText(row.AccionVista || row.Accion),
    icon: toText(row.Icono),
    order: toNumber(row.Orden),
    active: Boolean(row.Activo),
  }))

  const permissions = permissionsResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdPermiso),
    screenId: toNumber(row.IdPantalla),
    screen: toText(row.Pantalla),
    module: toText(row.ModuloNombre || row.Modulo),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    clave: toText(row.Clave),
    canView: false,
    canCreate: false,
    canEdit: false,
    canDelete: false,
    canApprove: false,
    canCancel: false,
    canPrint: false,
    active: Boolean(row.Activo),
  }))

  return {
    users,
    roles,
    modules,
    screens,
    permissions,
    rolePermissions: rolePermissionsResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdRolPermiso),
      roleId: toNumber(row.IdRol),
      roleName: toText(row.Rol),
      permissionId: toNumber(row.IdPermiso),
      permissionName: toText(row.Permiso),
      module: toText(row.ModuloNombre || row.Modulo),
      screen: toText(row.Pantalla),
      active: Boolean(row.Activo),
    })),
    lookups: {
      companies: company.id ? [{ id: company.id, name: company.tradeName || company.businessName }] : [],
      roles: roles.map((item) => ({ id: item.id, name: item.name })),
      divisions: divisions.map((item) => ({ id: item.id, name: item.name })),
      branches: branches.map((item) => ({ id: item.id, name: item.name, divisionId: item.divisionId })),
      emissionPoints: emissionPoints.map((item) => ({ id: item.id, name: item.name, branchId: item.branchId, divisionId: item.divisionId })),
      modules: modules.map((item) => ({ id: item.id, name: item.name })),
      screens: screens.map((item) => ({ id: item.id, name: `${item.module} - ${item.name}` })),
      permissions: permissions.map((item) => ({ id: item.id, name: `${item.module} - ${item.name}` })),
    },
  }
}

export async function getCatalogSnapshot(): Promise<CatalogSnapshot> {
  const pool = await getPool()
  let productsResultPromise: Promise<{ recordset: QueryRow[] }>
  productsResultPromise = pool.request().input("Accion", "L").execute("dbo.spProductosCRUD") as Promise<{ recordset: QueryRow[] }>
  productsResultPromise = productsResultPromise.catch(async (error) => {
    if (!isMissingColumnError(error, "Imagen")) throw error
    return pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        P.IdProducto,
        P.Nombre,
        C.Nombre AS Categoria,
        TP.Nombre AS TipoProducto,
        UB.Nombre AS UnidadBase,
        UV.Nombre AS UnidadVenta,
        ISNULL((
          SELECT TOP 1 PP.Precio
          FROM dbo.ProductoPrecios PP
          WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
          ORDER BY PP.IdListaPrecio
        ), 0) AS Precio
      FROM dbo.Productos P
      LEFT JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
      LEFT JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
      LEFT JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
      LEFT JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
      WHERE P.RowStatus = 1
      ORDER BY P.IdProducto DESC;
    `) as Promise<{ recordset: QueryRow[] }>
  })

  const [totalsResult, productsResult, unitsResult] = await Promise.all([
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        (SELECT COUNT(*) FROM dbo.Categorias WHERE RowStatus = 1) AS Categories,
        (SELECT COUNT(*) FROM dbo.TiposProducto WHERE RowStatus = 1) AS ProductTypes,
        (SELECT COUNT(*) FROM dbo.UnidadesMedida WHERE RowStatus = 1) AS Units,
        (SELECT COUNT(*) FROM dbo.Productos WHERE RowStatus = 1) AS Products;
    `),
    productsResultPromise,
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT TOP (20)
        IdUnidadMedida,
        Nombre,
        Abreviatura,
        BaseA,
        BaseB,
        Factor
      FROM dbo.UnidadesMedida
      WHERE RowStatus = 1
      ORDER BY IdUnidadMedida;
    `),
  ])

  const totals = totalsResult.recordset[0] as QueryRow

  return {
    totals: {
      categories: toNumber(totals.Categories),
      productTypes: toNumber(totals.ProductTypes),
      units: toNumber(totals.Units),
      products: toNumber(totals.Products),
    },
    products: (productsResult.recordset as QueryRow[]).slice(0, 20).map((row) => ({
      id: toNumber(row.IdProducto),
      name: toText(row.Nombre),
      category: toText(row.Categoria),
      type: toText(row.TipoProducto),
      baseUnit: toText(row.UnidadBase),
      saleUnit: toText(row.UnidadVenta),
      price: toNumber(row.Precio),
    })),
    units: unitsResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdUnidadMedida),
      name: toText(row.Nombre),
      abbreviation: toText(row.Abreviatura),
      baseA: toNumber(row.BaseA),
      baseB: toNumber(row.BaseB),
      factor: toNumber(row.Factor),
    })),
  }
}

function toIsoDate(value: unknown): string {
  if (value == null) return ""
  if (value instanceof Date) {
    const y = value.getFullYear()
    const m = String(value.getMonth() + 1).padStart(2, "0")
    const d = String(value.getDate()).padStart(2, "0")
    return `${y}-${m}-${d}`
  }
  if (typeof value === "string") return value.slice(0, 10)
  return String(value).slice(0, 10)
}

function toIsoDateTime(value: unknown): string {
  if (value == null) return ""
  if (value instanceof Date) {
    const y = value.getFullYear()
    const m = String(value.getMonth() + 1).padStart(2, "0")
    const d = String(value.getDate()).padStart(2, "0")
    const hh = String(value.getHours()).padStart(2, "0")
    const mm = String(value.getMinutes()).padStart(2, "0")
    const ss = String(value.getSeconds()).padStart(2, "0")
    return `${y}-${m}-${d} ${hh}:${mm}:${ss}`
  }
  const text = String(value)
  return text.length >= 19 ? text.slice(0, 19) : text
}

function mapProductRow(row: QueryRow): ProductRecord {
  return {
    id: toNumber(row.IdProducto),
    code: toText(row.Codigo),
    comment: toText(row.Comentario),
    imagen: toText(row.Imagen) || null,
    categoryId: toNumber(row.IdCategoria),
    typeId: toNumber(row.IdTipoProducto),
    unitBaseId: toNumber(row.IdUnidadMedida),
    unitSaleId: toNumber(row.IdUnidadVenta),
    unitPurchaseId: toNumber(row.IdUnidadCompra),
    unitAlt1Id: row.IdUnidadAlterna1 ? toNumber(row.IdUnidadAlterna1) : undefined,
    unitAlt2Id: row.IdUnidadAlterna2 ? toNumber(row.IdUnidadAlterna2) : undefined,
    unitAlt3Id: row.IdUnidadAlterna3 ? toNumber(row.IdUnidadAlterna3) : undefined,
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    price: toNumber(row.Precio),
    applyTax: Boolean(row.AplicaImpuesto),
    taxRateId: row.IdTasaImpuesto != null ? toNumber(row.IdTasaImpuesto) : null,
    taxRate: toNumber(row.TasaImpuesto),
    stockUnitBase: toText(row.UnidadBaseExistencia, "measure") || "measure",
    canSellInBilling: Boolean(row.SeVendeEnFactura ?? true),
    allowDiscount: Boolean(row.PermiteDescuento ?? true),
    allowPriceChange: Boolean(row.PermiteCambioPrecio ?? true),
    allowManualPrice: Boolean(row.PermitePrecioManual ?? true),
    requestUnit: Boolean(row.PideUnidad ?? false),
    requestUnitInventory: Boolean(row.PideUnidadInventario ?? false),
    allowDecimals: Boolean(row.PermiteFraccionesDecimales ?? false),
    sellWithoutStock: Boolean(row.VenderSinExistencia ?? true),
    applyTip: Boolean(row.AplicaPropina ?? false),
    managesStock: Boolean(row.ManejaExistencia ?? true),
    prices: [],
    costs: {
      currencyId: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
      providerDiscount: toNumber(row.DescuentoProveedor),
      providerCost: toNumber(row.CostoProveedor),
      providerCostWithTax: toNumber(row.CostoConImpuesto),
      averageCost: toNumber(row.CostoPromedio),
      allowManualAvgCost: Boolean(row.PermitirCostoManual),
    },
    offer: {
      active: false,
      price: 0,
      startDate: "",
      endDate: "",
    },
    active: Boolean(row.Activo),
    category: toText(row.Categoria),
    type: toText(row.TipoProducto),
    unitBase: toText(row.UnidadBase),
    unitSale: toText(row.UnidadVenta),
    unitPurchase: toText(row.UnidadCompra),
  }
}

export async function getCatalogManagerData(): Promise<CatalogManagerData> {
  const pool = await getPool()
  const [snapshot, categoriesResult, typesResult, unitsResult, priceListsResult, currenciesResult, taxRatesResult, warehousesResult] = await Promise.all([
    getCatalogSnapshot(),
    pool.request().query(`SELECT IdCategoria, Nombre FROM dbo.Categorias WHERE RowStatus = 1 ORDER BY Nombre;`),
    pool.request().query(`SELECT IdTipoProducto, Nombre FROM dbo.TiposProducto WHERE RowStatus = 1 ORDER BY Nombre;`),
    pool.request().query(`SELECT IdUnidadMedida, Nombre, Abreviatura FROM dbo.UnidadesMedida WHERE ISNULL(RowStatus,1) = 1 ORDER BY Nombre;`),
    pool.request().input("Accion", "L").execute("dbo.spListasPreciosCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spMonedasCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spTasasImpuestoCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spAlmacenesCRUD").catch(() => ({ recordset: [] })),
  ])

  return {
    totals: snapshot.totals,
    products: [],
    lookups: {
      categories: categoriesResult.recordset.map((row: QueryRow) => ({ id: toNumber(row.IdCategoria), name: toText(row.Nombre) })),
      productTypes: typesResult.recordset.map((row: QueryRow) => ({ id: toNumber(row.IdTipoProducto), name: toText(row.Nombre) })),
      units: unitsResult.recordset.map((row: QueryRow) => ({ id: toNumber(row.IdUnidadMedida), name: toText(row.Nombre), abbreviation: toText(row.Abreviatura) })),
      priceLists: (priceListsResult.recordset as QueryRow[]).map((row) => ({
        id: toNumber(row.IdListaPrecio),
        code: toText(row.Codigo),
        description: toText(row.Descripcion),
        abbreviation: toText(row.Abreviatura),
        currencyId: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
        active: Boolean(row.Activo),
      })),
      currencies: (currenciesResult.recordset as QueryRow[]).map((row) => ({
        id: toNumber(row.IdMoneda),
        code: toText(row.Codigo),
        name: toText(row.Nombre),
        symbol: toText(row.Simbolo) || null,
      })),
      taxRates: (taxRatesResult.recordset as QueryRow[])
        .filter((row) => row.Activo == null || Boolean(row.Activo))
        .map((row) => ({
          id: toNumber(row.IdTasaImpuesto),
          name: toText(row.Nombre),
          rate: toNumber(row.Tasa),
          code: toText(row.Codigo),
        })),
      warehouses: (warehousesResult.recordset as QueryRow[])
        .filter((row) => row.Activo == null || Boolean(row.Activo))
        .map((row) => ({
          id: toNumber(row.IdAlmacen),
          name: toText(row.Descripcion),
          initials: toText(row.Siglas),
          type: toText(row.TipoAlmacen) || "O",
        })),
    },
  }
}

export async function getCatalogMastersData(): Promise<CatalogMastersData> {
  const pool = await getPool()
  let categoriesResult: { recordset: QueryRow[] }
  try {
    categoriesResult = await pool.request().input("Accion", "L").execute("dbo.spCategoriasCRUD") as { recordset: QueryRow[] }
  } catch (error) {
    if (!isMissingColumnError(error, "Imagen")) throw error
    categoriesResult = await pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        C.IdCategoria,
        C.Nombre,
        C.Descripcion,
        C.Activo
      FROM dbo.Categorias C
      WHERE C.RowStatus = 1
      ORDER BY C.Nombre;
    `) as { recordset: QueryRow[] }
  }

  const [productTypesResult, unitsResult] = await Promise.all([
    pool.request().input("Accion", "L").execute("dbo.spTiposProductoCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spUnidadesMedidaCRUD"),
  ])

  return {
    categories: categoriesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdCategoria),
      name: toText(row.Nombre),
      description: toText(row.Descripcion),
      active: Boolean(row.Activo),
    })),
    productTypes: productTypesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdTipoProducto),
      name: toText(row.Nombre),
      description: toText(row.Descripcion),
      active: Boolean(row.Activo),
    })),
    units: unitsResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdUnidadMedida),
      name: toText(row.Nombre),
      abbreviation: toText(row.Abreviatura),
      baseA: toNumber(row.BaseA),
      baseB: toNumber(row.BaseB),
      factor: toNumber(row.UnidadesCalculadas ?? row.Factor),
      active: Boolean(row.Activo),
    })),
  }
}

function mapCategoryRow(row: QueryRow): CategoryRecord {
  const parseDate = (value: unknown): string => {
    if (value == null) return ""
    if (value instanceof Date) {
      const y = value.getFullYear()
      const m = String(value.getMonth() + 1).padStart(2, "0")
      const d = String(value.getDate()).padStart(2, "0")
      return `${y}-${m}-${d}`
    }
    if (typeof value === "string") return value.slice(0, 10)
    return String(value).slice(0, 10)
  }
  return {
    id: toNumber(row.IdCategoria),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    active: Boolean(row.Activo),
    fechaCreacion: parseDate(row.FechaCreacion),
    codigo: toText(row.Codigo) || null,
    codigoCorto: toText(row.CodigoCorto) || null,
    nombreCorto: toText(row.NombreCorto) || null,
    idCategoriaPadre: row.IdCategoriaPadre != null ? toNumber(row.IdCategoriaPadre) : null,
    idMoneda: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    colorFondo: String(row.ColorFondo ?? "#1e3a5f"),
    colorBoton: String(row.ColorBoton ?? "#12467e"),
    colorTexto: String(row.ColorTexto ?? "#ffffff"),
    colorFondoItem: String(row.ColorFondoItem ?? row.ColorFondo ?? "#1e3a5f"),
    colorBotonItem: String(row.ColorBotonItem ?? row.ColorBoton ?? "#12467e"),
    colorTextoItem: String(row.ColorTextoItem ?? row.ColorTexto ?? "#ffffff"),
    tamanoTexto: toNumber(row.TamanoTexto ?? 14),
    columnasPOS: toNumber(row.ColumnasPOS ?? 3),
    mostrarEnPOS: Boolean(row.MostrarEnPOS ?? true),
    imagen: toText(row.Imagen) || null,
    categoriaPadreNombre: toText(row.CategoriaPadreNombre) || null,
    monedaCodigo: toText(row.MonedaCodigo) || null,
    monedaSimbolo: toText(row.MonedaSimbolo) || null,
    totalSubcategorias: toNumber(row.TotalSubcategorias ?? 0),
    totalProductos: toNumber(row.TotalProductos ?? 0),
  }
}

export async function getCategories(): Promise<CategoryRecord[]> {
  const pool = await getPool()
  let result: { recordset: QueryRow[] }
  try {
    result = await pool.request().input("Accion", "L").execute("dbo.spCategoriasCRUD") as { recordset: QueryRow[] }
  } catch (error) {
    if (!isMissingColumnError(error, "Imagen")) throw error
    result = await pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        C.IdCategoria,
        C.Nombre,
        C.Descripcion,
        C.Activo,
        C.FechaCreacion,
        CAST(NULL AS NVARCHAR(50)) AS Codigo,
        CAST(NULL AS NVARCHAR(50)) AS CodigoCorto,
        CAST(NULL AS NVARCHAR(150)) AS NombreCorto,
        CAST(NULL AS INT) AS IdCategoriaPadre,
        CAST(NULL AS INT) AS IdMoneda,
        C.ColorFondo,
        C.ColorBoton,
        C.ColorTexto,
        CAST(NULL AS NVARCHAR(500)) AS Imagen,
        CAST(NULL AS NVARCHAR(100)) AS CategoriaPadreNombre,
        CAST(NULL AS NVARCHAR(10)) AS MonedaCodigo,
        CAST(NULL AS NVARCHAR(10)) AS MonedaSimbolo,
        0 AS TotalSubcategorias,
        0 AS TotalProductos
      FROM dbo.Categorias C
      WHERE C.RowStatus = 1
      ORDER BY C.Nombre;
    `) as { recordset: QueryRow[] }
  }
  const categories = (result.recordset as QueryRow[]).map(mapCategoryRow)

  const categoryColumnsResult = await pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        CAST(CASE WHEN COL_LENGTH('dbo.Categorias', 'IdCategoriaPadre') IS NOT NULL THEN 1 ELSE 0 END AS INT) AS HasParentColumn,
        CAST(CASE WHEN COL_LENGTH('dbo.Categorias', 'Imagen') IS NOT NULL THEN 1 ELSE 0 END AS INT) AS HasImagenColumn;
  `).catch(() => ({ recordset: [{ HasParentColumn: 0, HasImagenColumn: 0 }] as QueryRow[] }))

  const categoryColumnInfo = (categoryColumnsResult.recordset as QueryRow[])[0] ?? {}
  const hasCategoryParentColumn = toNumber(categoryColumnInfo.HasParentColumn ?? 0) === 1
  const hasCategoryImagenColumn = toNumber(categoryColumnInfo.HasImagenColumn ?? 0) === 1

  await pool.request().query(`
      SET NOCOUNT ON;
      IF COL_LENGTH('dbo.Categorias', 'ColorFondo') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorFondo NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorBoton') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorBoton NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorTexto') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorTexto NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorFondoItem') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorFondoItem NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorBotonItem') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorBotonItem NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorTextoItem') IS NULL
      ALTER TABLE dbo.Categorias ADD ColorTextoItem NVARCHAR(7) NULL;
  `).catch(() => null)

  const extrasResult = await pool.request().query(
    hasCategoryImagenColumn
      ? `
        SET NOCOUNT ON;
        SELECT
          IdCategoria,
          Imagen,
          ColorFondo,
          ColorBoton,
          ColorTexto,
          ISNULL(ColorFondoItem, ColorFondo) AS ColorFondoItem,
          ISNULL(ColorBotonItem, ColorBoton) AS ColorBotonItem,
          ISNULL(ColorTextoItem, ColorTexto) AS ColorTextoItem
        FROM dbo.Categorias;
      `
      : `
        SET NOCOUNT ON;
        SELECT
          IdCategoria,
          CAST(NULL AS NVARCHAR(MAX)) AS Imagen,
          ColorFondo,
          ColorBoton,
          ColorTexto,
          ISNULL(ColorFondoItem, ColorFondo) AS ColorFondoItem,
          ISNULL(ColorBotonItem, ColorBoton) AS ColorBotonItem,
          ISNULL(ColorTextoItem, ColorTexto) AS ColorTextoItem
        FROM dbo.Categorias;
      `,
  ).catch(() => ({ recordset: [] as QueryRow[] }))

  const totalsResult = await pool.request().query(
    hasCategoryParentColumn
      ? `
        SET NOCOUNT ON;
        SELECT
          C.IdCategoria,
          (SELECT COUNT(*) FROM dbo.Categorias SC WHERE SC.IdCategoriaPadre = C.IdCategoria AND ISNULL(SC.RowStatus, 1) = 1) AS TotalSubcategorias,
          (SELECT COUNT(*) FROM dbo.Productos P WHERE P.IdCategoria = C.IdCategoria AND ISNULL(P.RowStatus, 1) = 1) AS TotalProductos
        FROM dbo.Categorias C
        WHERE ISNULL(C.RowStatus, 1) = 1;
      `
      : `
        SET NOCOUNT ON;
        SELECT
          C.IdCategoria,
          0 AS TotalSubcategorias,
          (SELECT COUNT(*) FROM dbo.Productos P WHERE P.IdCategoria = C.IdCategoria AND ISNULL(P.RowStatus, 1) = 1) AS TotalProductos
        FROM dbo.Categorias C
        WHERE ISNULL(C.RowStatus, 1) = 1;
      `,
  ).catch(() => ({ recordset: [] as QueryRow[] }))

  const extrasMap = new Map<number, QueryRow>()
  for (const row of extrasResult.recordset as QueryRow[]) {
    extrasMap.set(toNumber(row.IdCategoria), row)
  }

  const totalsMap = new Map<number, QueryRow>()
  for (const row of totalsResult.recordset as QueryRow[]) {
    totalsMap.set(toNumber(row.IdCategoria), row)
  }

  return categories.map((category) => {
    const extra = extrasMap.get(category.id)
    const totals = totalsMap.get(category.id)
    return extra
      ? {
        ...category,
        imagen: toText(extra.Imagen) || category.imagen,
        colorFondo: toText(extra.ColorFondo) || category.colorFondo,
        colorBoton: toText(extra.ColorBoton) || category.colorBoton,
        colorTexto: toText(extra.ColorTexto) || category.colorTexto,
        colorFondoItem: toText(extra.ColorFondoItem) || category.colorFondo,
        colorBotonItem: toText(extra.ColorBotonItem) || category.colorBoton,
        colorTextoItem: toText(extra.ColorTextoItem) || category.colorTexto,
        totalSubcategorias: toNumber(totals?.TotalSubcategorias ?? category.totalSubcategorias ?? 0),
        totalProductos: toNumber(totals?.TotalProductos ?? category.totalProductos ?? 0),
      }
      : {
        ...category,
        totalSubcategorias: toNumber(totals?.TotalSubcategorias ?? category.totalSubcategorias ?? 0),
        totalProductos: toNumber(totals?.TotalProductos ?? category.totalProductos ?? 0),
      }
  })
}

export async function saveCategory(input: {
  id?: number
  name: string
  description?: string
  active?: boolean
  codigo?: string
  codigoCorto?: string
  nombreCorto?: string
  idCategoriaPadre?: number | null
  idMoneda?: number | null
  colorFondo?: string
  colorBoton?: string
  colorTexto?: string
  colorFondoItem?: string
  colorBotonItem?: string
  colorTextoItem?: string
  tamanoTexto?: number
  columnasPOS?: number
  mostrarEnPOS?: boolean
  imagen?: string | null
}, userId?: number, session?: SessionContext): Promise<CategoryRecord> {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const uid = userId ?? demoUserId
  const req = pool.request()
  req.input("Accion", input.id ? "A" : "I")
  req.input("Nombre", sql.NVarChar(100), input.name.trim())
  req.input("Descripcion", sql.NVarChar(250), input.description?.trim() || null)
  req.input("Activo", sql.Bit, input.active ?? true)
  req.input("Codigo", sql.NVarChar(20), input.codigo?.trim() || null)
  req.input("CodigoCorto", sql.NVarChar(10), input.codigoCorto?.trim() || null)
  req.input("NombreCorto", sql.NVarChar(30), input.nombreCorto?.trim() || null)
  req.input("IdCategoriaPadre", sql.Int, input.idCategoriaPadre ?? null)
  req.input("IdMoneda", sql.Int, input.idMoneda ?? null)
  req.input("ColorFondo", sql.NVarChar(7), input.colorFondo ?? null)
  req.input("ColorBoton", sql.NVarChar(7), input.colorBoton ?? null)
  req.input("ColorTexto", sql.NVarChar(7), input.colorTexto ?? null)
  req.input("TamanoTexto", sql.Int, input.tamanoTexto ?? null)
  req.input("ColumnasPOS", sql.Int, input.columnasPOS ?? null)
  req.input("MostrarEnPOS", sql.Bit, input.mostrarEnPOS ?? null)
  req.input("Imagen", sql.NVarChar(sql.MAX), null)
  req.input("UsuarioCreacion", sql.Int, uid)
  req.input("UsuarioModificacion", sql.Int, uid)
  req.input("IdSesion", sql.Int, session?.sessionId ?? null)
  req.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
  if (input.id) req.input("IdCategoria", sql.Int, input.id)

  const ensureCategoryItemStyleColumns = async () => {
    await pool.request().query(`
      SET NOCOUNT ON;
      IF COL_LENGTH('dbo.Categorias', 'ColorFondo') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorFondo NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorBoton') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorBoton NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorTexto') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorTexto NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorFondoItem') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorFondoItem NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorBotonItem') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorBotonItem NVARCHAR(7) NULL;
      IF COL_LENGTH('dbo.Categorias', 'ColorTextoItem') IS NULL
        ALTER TABLE dbo.Categorias ADD ColorTextoItem NVARCHAR(7) NULL;
    `)
  }
  const persistCategoryVisuals = async (categoryId: number) => {
    await pool.request().query(`
      SET NOCOUNT ON;
      IF COL_LENGTH('dbo.Categorias', 'Imagen') IS NULL
        ALTER TABLE dbo.Categorias ADD Imagen NVARCHAR(MAX) NULL;
      ELSE
      BEGIN
        DECLARE @ImageType NVARCHAR(128) =
          (SELECT DATA_TYPE
           FROM INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Categorias' AND COLUMN_NAME = 'Imagen');
        DECLARE @MaxLen INT =
          (SELECT CHARACTER_MAXIMUM_LENGTH
           FROM INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Categorias' AND COLUMN_NAME = 'Imagen');
        IF @ImageType = 'nvarchar' AND ISNULL(@MaxLen, -1) <> -1
          ALTER TABLE dbo.Categorias ALTER COLUMN Imagen NVARCHAR(MAX) NULL;
      END
    `)
    await pool.request()
      .input("IdCategoria", sql.Int, categoryId)
      .input("Imagen", sql.NVarChar(sql.MAX), input.imagen || null)
      .input("ColorFondo", sql.NVarChar(7), input.colorFondo ?? null)
      .input("ColorBoton", sql.NVarChar(7), input.colorBoton ?? null)
      .input("ColorTexto", sql.NVarChar(7), input.colorTexto ?? null)
      .query(`
        SET NOCOUNT ON;
        UPDATE dbo.Categorias
        SET Imagen = @Imagen,
            ColorFondo = @ColorFondo,
            ColorBoton = @ColorBoton,
            ColorTexto = @ColorTexto
        WHERE IdCategoria = @IdCategoria;
      `)
      .catch(async (err: unknown) => {
        if (!isTypeValidationError(err)) throw err
        await pool.request()
          .input("IdCategoria", categoryId)
          .input("Imagen", input.imagen || null)
          .input("ColorFondo", input.colorFondo ?? null)
          .input("ColorBoton", input.colorBoton ?? null)
          .input("ColorTexto", input.colorTexto ?? null)
          .query(`
            SET NOCOUNT ON;
            UPDATE dbo.Categorias
            SET Imagen = @Imagen,
                ColorFondo = @ColorFondo,
                ColorBoton = @ColorBoton,
                ColorTexto = @ColorTexto
            WHERE IdCategoria = @IdCategoria;
          `)
      })
  }
  try {
    const result = await req.execute("dbo.spCategoriasCRUD")
    const saved = mapCategoryRow(result.recordset[0] as QueryRow)
    const categoryId = saved.id
    await ensureCategoryItemStyleColumns()
    await persistCategoryVisuals(categoryId)
    await pool.request()
      .input("IdCategoria", sql.Int, categoryId)
      .input("ColorFondoItem", sql.NVarChar(7), input.colorFondoItem ?? input.colorFondo ?? null)
      .input("ColorBotonItem", sql.NVarChar(7), input.colorBotonItem ?? input.colorBoton ?? null)
      .input("ColorTextoItem", sql.NVarChar(7), input.colorTextoItem ?? input.colorTexto ?? null)
      .query(`
        SET NOCOUNT ON;
        UPDATE dbo.Categorias
        SET ColorFondoItem = @ColorFondoItem,
            ColorBotonItem = @ColorBotonItem,
            ColorTextoItem = @ColorTextoItem
        WHERE IdCategoria = @IdCategoria;
      `)
      .catch(async (err: unknown) => {
        if (!isTypeValidationError(err)) throw err
        await pool.request()
          .input("IdCategoria", categoryId)
          .input("ColorFondoItem", input.colorFondoItem ?? input.colorFondo ?? null)
          .input("ColorBotonItem", input.colorBotonItem ?? input.colorBoton ?? null)
          .input("ColorTextoItem", input.colorTextoItem ?? input.colorTexto ?? null)
          .query(`
            SET NOCOUNT ON;
            UPDATE dbo.Categorias
            SET ColorFondoItem = @ColorFondoItem,
                ColorBotonItem = @ColorBotonItem,
                ColorTextoItem = @ColorTextoItem
            WHERE IdCategoria = @IdCategoria;
          `)
      })
    return {
      ...saved,
      imagen: input.imagen ?? saved.imagen,
      colorFondo: input.colorFondo ?? saved.colorFondo,
      colorBoton: input.colorBoton ?? saved.colorBoton,
      colorTexto: input.colorTexto ?? saved.colorTexto,
      colorFondoItem: input.colorFondoItem ?? input.colorFondo ?? saved.colorFondo,
      colorBotonItem: input.colorBotonItem ?? input.colorBoton ?? saved.colorBoton,
      colorTextoItem: input.colorTextoItem ?? input.colorTexto ?? saved.colorTexto,
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req2 = pool.request()
    req2.input("Accion", input.id ? "A" : "I")
    req2.input("Nombre", input.name.trim())
    req2.input("Descripcion", input.description?.trim() || null)
    req2.input("Activo", input.active ?? true)
    req2.input("Codigo", input.codigo?.trim() || null)
    req2.input("CodigoCorto", input.codigoCorto?.trim() || null)
    req2.input("NombreCorto", input.nombreCorto?.trim() || null)
    req2.input("IdCategoriaPadre", input.idCategoriaPadre ?? null)
    req2.input("IdMoneda", input.idMoneda ?? null)
    req2.input("ColorFondo", input.colorFondo ?? null)
    req2.input("ColorBoton", input.colorBoton ?? null)
    req2.input("ColorTexto", input.colorTexto ?? null)
    req2.input("TamanoTexto", input.tamanoTexto ?? null)
    req2.input("ColumnasPOS", input.columnasPOS ?? null)
    req2.input("MostrarEnPOS", input.mostrarEnPOS ?? null)
    req2.input("Imagen", null)
    req2.input("UsuarioCreacion", uid)
    req2.input("UsuarioModificacion", uid)
    req2.input("IdSesion", session?.sessionId ?? null)
    req2.input("TokenSesion", session?.token ?? null)
    if (input.id) req2.input("IdCategoria", input.id)
    const result2 = await req2.execute("dbo.spCategoriasCRUD")
    const saved = mapCategoryRow(result2.recordset[0] as QueryRow)
    const categoryId = saved.id
    await ensureCategoryItemStyleColumns()
    await persistCategoryVisuals(categoryId)
    await pool.request()
      .input("IdCategoria", categoryId)
      .input("ColorFondoItem", input.colorFondoItem ?? input.colorFondo ?? null)
      .input("ColorBotonItem", input.colorBotonItem ?? input.colorBoton ?? null)
      .input("ColorTextoItem", input.colorTextoItem ?? input.colorTexto ?? null)
      .query(`
        SET NOCOUNT ON;
        UPDATE dbo.Categorias
        SET ColorFondoItem = @ColorFondoItem,
            ColorBotonItem = @ColorBotonItem,
            ColorTextoItem = @ColorTextoItem
        WHERE IdCategoria = @IdCategoria;
      `)
    return {
      ...saved,
      imagen: input.imagen ?? saved.imagen,
      colorFondo: input.colorFondo ?? saved.colorFondo,
      colorBoton: input.colorBoton ?? saved.colorBoton,
      colorTexto: input.colorTexto ?? saved.colorTexto,
      colorFondoItem: input.colorFondoItem ?? input.colorFondo ?? saved.colorFondo,
      colorBotonItem: input.colorBotonItem ?? input.colorBoton ?? saved.colorBoton,
      colorTextoItem: input.colorTextoItem ?? input.colorTexto ?? saved.colorTexto,
    }
  }
}

export async function deleteCategory(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  await pool.request()
    .input("Accion", "E")
    .input("IdCategoria", sql.Int, id)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spCategoriasCRUD")
}

export type CategoryProduct = {
  idProducto: number
  nombre: string
  activo: boolean
  tipoProducto: string | null
}

export async function getCategoryProducts(categoryId: number, session?: SessionContext): Promise<{ assigned: CategoryProduct[]; available: CategoryProduct[] }> {
  const pool = await getPool()
  const executeList = async (accion: "LA" | "LD") => {
    try {
      return await pool.request()
        .input("Accion", accion)
        .input("IdCategoria", categoryId)
        .input("IdSesion", sql.Int, session?.sessionId ?? null)
        .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
        .execute("dbo.spCategoriaProductos")
    } catch (err) {
      if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
      return await pool.request()
        .input("Accion", accion)
        .input("IdCategoria", categoryId)
        .input("IdSesion", session?.sessionId ?? null)
        .input("TokenSesion", session?.token ?? null)
        .execute("dbo.spCategoriaProductos")
    }
  }

  const assignedResult = await executeList("LA")
  const availableResult = await executeList("LD")

  const mapProduct = (row: QueryRow): CategoryProduct => ({
    idProducto: Number(row.IdProducto),
    nombre: String(row.Nombre),
    activo: Boolean(row.Activo),
    tipoProducto: row.TipoProducto != null ? String(row.TipoProducto) : null,
  })

  return {
    assigned: (assignedResult.recordset as QueryRow[]).map(mapProduct),
    available: (availableResult.recordset as QueryRow[]).map(mapProduct),
  }
}

export async function assignProductToCategory(categoryId: number, productId: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  try {
    await pool.request()
      .input("Accion", "A")
      .input("IdCategoria", sql.Int, categoryId)
      .input("IdProducto", sql.Int, productId)
      .input("IdSesion", sql.Int, session?.sessionId ?? null)
      .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      .execute("dbo.spCategoriaProductos")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool.request()
      .input("Accion", "A")
      .input("IdCategoria", categoryId)
      .input("IdProducto", productId)
      .input("IdSesion", session?.sessionId ?? null)
      .input("TokenSesion", session?.token ?? null)
      .execute("dbo.spCategoriaProductos")
  }
}

export async function removeProductFromCategory(categoryId: number, productId: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  try {
    await pool.request()
      .input("Accion", "Q")
      .input("IdCategoria", sql.Int, categoryId)
      .input("IdProducto", sql.Int, productId)
      .input("IdSesion", sql.Int, session?.sessionId ?? null)
      .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      .execute("dbo.spCategoriaProductos")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool.request()
      .input("Accion", "Q")
      .input("IdCategoria", categoryId)
      .input("IdProducto", productId)
      .input("IdSesion", session?.sessionId ?? null)
      .input("TokenSesion", session?.token ?? null)
      .execute("dbo.spCategoriaProductos")
  }
}

export async function getDiningRoomSnapshot(): Promise<DiningRoomSnapshot> {
  const pool = await getPool()
  const [totalsResult, resourcesResult] = await Promise.all([
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        (SELECT COUNT(*) FROM dbo.Areas WHERE RowStatus = 1) AS Areas,
        (SELECT COUNT(*) FROM dbo.TiposRecurso WHERE RowStatus = 1) AS ResourceTypes,
        (SELECT COUNT(*) FROM dbo.CategoriasRecurso WHERE RowStatus = 1) AS ResourceCategories,
        (SELECT COUNT(*) FROM dbo.Recursos WHERE RowStatus = 1) AS Resources;
    `),
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT
        R.IdRecurso,
        R.Nombre,
        A.Nombre AS Area,
        TR.Nombre AS Tipo,
        CR.Nombre AS Categoria,
        ISNULL(R.Estado, 'Sin estado') AS Estado,
        CASE WHEN EXISTS (
          SELECT 1
          FROM dbo.Ordenes O
          INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
          WHERE O.IdRecurso = R.IdRecurso AND O.RowStatus = 1 AND E.Nombre IN ('Abierta', 'En proceso')
        ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS HasActiveOrder
      FROM dbo.Recursos R
      INNER JOIN dbo.CategoriasRecurso CR ON CR.IdCategoriaRecurso = R.IdCategoriaRecurso
      INNER JOIN dbo.Areas A ON A.IdArea = CR.IdArea
      INNER JOIN dbo.TiposRecurso TR ON TR.IdTipoRecurso = CR.IdTipoRecurso
      WHERE R.RowStatus = 1
      ORDER BY R.IdRecurso;
    `),
  ])

  const totals = totalsResult.recordset[0] as QueryRow

  return {
    totals: {
      areas: toNumber(totals.Areas),
      resourceTypes: toNumber(totals.ResourceTypes),
      resourceCategories: toNumber(totals.ResourceCategories),
      resources: toNumber(totals.Resources),
    },
    resources: resourcesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdRecurso),
      name: toText(row.Nombre),
      area: toText(row.Area),
      type: toText(row.Tipo),
      category: toText(row.Categoria),
      state: toText(row.Estado),
      hasActiveOrder: Boolean(row.HasActiveOrder),
    })),
  }
}

export async function getDiningRoomManagerData(): Promise<DiningRoomManagerData> {
  const pool = await getPool()
  const [snapshot, board, categoriesResult, resourcesResult] = await Promise.all([
    getDiningRoomSnapshot(),
    getOrderBoard(),
    pool.request().query(`
      SELECT CR.IdCategoriaRecurso, CR.Nombre, A.Nombre AS Area, TR.Nombre AS Tipo, ISNULL(CR.ColorTema, '#3b82f6') AS ColorTema, ISNULL(CR.FormaVisual, 'square') AS FormaVisual
      FROM dbo.CategoriasRecurso CR
      INNER JOIN dbo.Areas A ON A.IdArea = CR.IdArea
      INNER JOIN dbo.TiposRecurso TR ON TR.IdTipoRecurso = CR.IdTipoRecurso
      WHERE CR.RowStatus = 1
      ORDER BY A.Nombre, CR.Nombre;
    `),
    pool.request().input("Accion", "L").execute("dbo.spRecursosCRUD"),
  ])

  return {
    totals: snapshot.totals,
    board,
    resources: resourcesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdRecurso),
      categoryId: toNumber(row.IdCategoriaRecurso),
      name: toText(row.Nombre),
      state: toText(row.Estado, "Libre"),
      seats: toNumber(row.CantidadSillas || 4),
      active: Boolean(row.Activo),
    })),
    lookups: {
      resourceCategories: categoriesResult.recordset.map((row: QueryRow) => ({
        id: toNumber(row.IdCategoriaRecurso),
        name: toText(row.Nombre),
        area: toText(row.Area),
        type: toText(row.Tipo),
        color: toText(row.ColorTema, "#3b82f6"),
        shape: toText(row.FormaVisual, "square"),
      })),
    },
  }
}

export async function getDiningMastersData(): Promise<DiningMastersData> {
  const pool = await getPool()
  const [areasResult, typesResult, categoriesResult] = await Promise.all([
    pool.request().input("Accion", "L").execute("dbo.spAreasCRUD"),
    pool.request().input("Accion", "L").execute("dbo.spTiposRecursoCRUD"),
    pool.request().query(`
      SELECT CR.IdCategoriaRecurso, CR.IdTipoRecurso, CR.IdArea, CR.Nombre, CR.Descripcion, CR.Activo, A.Nombre AS Area, TR.Nombre AS Tipo, ISNULL(CR.ColorTema, '#3b82f6') AS ColorTema, ISNULL(CR.FormaVisual, 'square') AS FormaVisual
      FROM dbo.CategoriasRecurso CR
      INNER JOIN dbo.Areas A ON A.IdArea = CR.IdArea
      INNER JOIN dbo.TiposRecurso TR ON TR.IdTipoRecurso = CR.IdTipoRecurso
      WHERE CR.RowStatus = 1
      ORDER BY CR.Nombre;
    `),
  ])

  const areas = areasResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdArea),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    order: toNumber(row.Orden),
    active: Boolean(row.Activo),
  }))

  const resourceTypes = typesResult.recordset.map((row: QueryRow) => ({
    id: toNumber(row.IdTipoRecurso),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    active: Boolean(row.Activo),
  }))

  return {
    areas,
    resourceTypes,
    resourceCategories: categoriesResult.recordset.map((row: QueryRow) => ({
      id: toNumber(row.IdCategoriaRecurso),
      typeId: toNumber(row.IdTipoRecurso),
      areaId: toNumber(row.IdArea),
      name: toText(row.Nombre),
      description: toText(row.Descripcion),
      active: Boolean(row.Activo),
      area: toText(row.Area),
      type: toText(row.Tipo),
      color: toText(row.ColorTema, "#3b82f6"),
      shape: toText(row.FormaVisual, "square"),
    })),
    lookups: {
      areas: areas.map((item) => ({ id: item.id, name: item.name })),
      resourceTypes: resourceTypes.map((item) => ({ id: item.id, name: item.name })),
    },
  }
}

export async function getOrderBoard(): Promise<ResourceBoardItem[]> {
  const pool = await getPool()
  const boardResult = await pool.request().query(`
    SET NOCOUNT ON;
    WITH ActiveOrders AS (
      SELECT
        O.IdOrden,
        O.NumeroOrden,
        O.IdRecurso,
        O.IdEstadoOrden,
        E.Nombre AS EstadoOrden,
        O.IdUsuario,
        CONCAT(U.Nombres, ' ', U.Apellidos) AS Mesero,
        O.FechaOrden,
        O.Subtotal,
        O.Impuesto,
        O.Total,
        ROW_NUMBER() OVER (PARTITION BY O.IdRecurso ORDER BY O.IdOrden DESC) AS RowNum
      FROM dbo.Ordenes O
      INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
      INNER JOIN dbo.Usuarios U ON U.IdUsuario = O.IdUsuario
      WHERE O.RowStatus = 1 AND E.Nombre IN ('Abierta', 'En proceso')
    )
    SELECT
      R.IdRecurso,
      R.Nombre AS Recurso,
      ISNULL(R.CantidadSillas, 4) AS CantidadSillas,
      CR.Nombre AS Categoria,
      ISNULL(CR.ColorTema, '#3b82f6') AS ColorCategoria,
      ISNULL(CR.FormaVisual, 'square') AS FormaCategoria,
      A.Nombre AS Area,
      ISNULL(R.Estado, 'Sin estado') AS EstadoRecurso,
      AO.IdOrden,
      AO.NumeroOrden,
      AO.EstadoOrden,
      AO.Mesero,
      AO.FechaOrden,
      AO.Subtotal,
      AO.Impuesto,
      AO.Total
    FROM dbo.Recursos R
    INNER JOIN dbo.CategoriasRecurso CR ON CR.IdCategoriaRecurso = R.IdCategoriaRecurso
    INNER JOIN dbo.Areas A ON A.IdArea = CR.IdArea
    LEFT JOIN ActiveOrders AO ON AO.IdRecurso = R.IdRecurso AND AO.RowNum = 1
    WHERE R.RowStatus = 1
    ORDER BY R.IdRecurso;
  `)

  const detailResult = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT
      D.IdOrdenDetalle,
      D.IdOrden,
      P.Nombre AS Producto,
      D.Cantidad,
      D.Unidades,
      D.PrecioUnitario,
      ISNULL(D.PorcentajeImpuesto, 0) AS PorcentajeImpuesto,
      ISNULL(D.MontoImpuesto, 0) AS MontoImpuesto,
      D.TotalLinea,
      ISNULL(D.ObservacionLinea, '') AS ObservacionLinea,
      D.FechaCreacion,
      ISNULL(U.NombreUsuario, '') AS UsuarioCreacionNombre
    FROM dbo.OrdenesDetalle D
    INNER JOIN dbo.Productos P ON P.IdProducto = D.IdProducto
    LEFT JOIN dbo.Usuarios U ON U.IdUsuario = D.UsuarioCreacion
    WHERE D.RowStatus = 1
    ORDER BY D.IdOrdenDetalle;
  `)

  const itemsByOrder = new Map<number, OrderItem[]>()

  detailResult.recordset.forEach((row: QueryRow) => {
    const orderId = toNumber(row.IdOrden)
    const item: OrderItem = {
      id: toNumber(row.IdOrdenDetalle),
      name: toText(row.Producto),
      quantity: toNumber(row.Cantidad),
      units: toNumber(row.Unidades),
      price: toNumber(row.PrecioUnitario),
      taxPercent: toNumber(row.PorcentajeImpuesto),
      taxAmount: toNumber(row.MontoImpuesto),
      total: toNumber(row.TotalLinea),
      note: toText(row.ObservacionLinea),
      createdAt: row.FechaCreacion ? toIsoDateTime(row.FechaCreacion) : undefined,
      createdBy: toText(row.UsuarioCreacionNombre),
    }

    const current = itemsByOrder.get(orderId) ?? []
    current.push(item)
    itemsByOrder.set(orderId, current)
  })

  return boardResult.recordset.map((row: QueryRow) => {
    const orderId = row.IdOrden ? toNumber(row.IdOrden) : undefined
    const orderState = toText(row.EstadoOrden)
    const resourceState = toText(row.EstadoRecurso, "Libre")

    return {
      id: toNumber(row.IdRecurso),
      name: toText(row.Recurso),
      category: toText(row.Categoria),
      area: toText(row.Area),
      seats: toNumber(row.CantidadSillas || 4),
      categoryColor: toText(row.ColorCategoria, "#3b82f6"),
      categoryShape: toText(row.FormaCategoria, "square"),
      status: mapOrderState(orderState || undefined, resourceState),
      resourceState,
      orderId,
      orderNumber: toText(row.NumeroOrden),
      orderState,
      waiter: toText(row.Mesero),
      time: row.FechaOrden instanceof Date ? row.FechaOrden.toLocaleTimeString("es-DO", { hour: "2-digit", minute: "2-digit" }) : undefined,
      subtotal: orderId ? toNumber(row.Subtotal) : undefined,
      tax: orderId ? toNumber(row.Impuesto) : undefined,
      total: orderId ? toNumber(row.Total) : undefined,
      items: orderId ? itemsByOrder.get(orderId) ?? [] : [],
    }
  })
}

function mapOrderSummaryRow(row: QueryRow): OrderSummaryRecord {
  return {
    id: toNumber(row.IdOrden),
    number: toText(row.NumeroOrden),
    resourceId: toNumber(row.IdRecurso),
    resourceName: toText(row.Recurso),
    stateId: toNumber(row.IdEstadoOrden),
    stateName: toText(row.EstadoOrden),
    waiterId: toNumber(row.IdUsuario),
    waiterName: toText(row.NombreCompletoUsuario) || toText(row.NombreUsuario),
    username: toText(row.NombreUsuario),
    orderDate: toIsoDateTime(row.FechaOrden),
    closeDate: row.FechaCierre ? toIsoDateTime(row.FechaCierre) : null,
    reference: toText(row.ReferenciaCliente),
    observations: toText(row.Observaciones),
    guestCount: Math.max(1, toNumber(row.CantidadPersonas) || 1),
    subtotal: toNumber(row.Subtotal),
    tax: toNumber(row.Impuesto),
    total: toNumber(row.Total),
    lineCount: toNumber(row.CantidadLineas),
  }
}

function mapOrderLineRow(row: QueryRow): OrderLineRecord {
  return {
    id: toNumber(row.IdOrdenDetalle),
    orderId: toNumber(row.IdOrden),
    productId: toNumber(row.IdProducto),
    productName: toText(row.Producto),
    unitId: toNumber(row.IdUnidadMedida),
    unitName: toText(row.UnidadMedida),
    unitAbbr: toText(row.Abreviatura),
    stateDetailId: toNumber(row.IdEstadoDetalleOrden),
    stateDetailName: toText(row.EstadoDetalleOrden),
    quantity: toNumber(row.Cantidad),
    units: toNumber(row.Unidades),
    price: toNumber(row.PrecioUnitario),
    taxPercent: toNumber(row.PorcentajeImpuesto),
    subtotal: toNumber(row.SubtotalLinea),
    tax: toNumber(row.MontoImpuesto),
    total: toNumber(row.TotalLinea),
    note: toText(row.ObservacionLinea),
    personNumber: Math.max(1, toNumber(row.NumeroPersona) || 1),
    createdAt: row.FechaCreacion ? toIsoDateTime(row.FechaCreacion) : undefined,
    createdBy: toText(row.UsuarioCreacionNombre),
  }
}

function mapOrderHistoryRow(row: QueryRow): OrderHistoryRecord {
  return {
    id: toNumber(row.IdOrdenMovimiento),
    orderId: toNumber(row.IdOrden),
    orderLineId: row.IdOrdenDetalle == null ? null : toNumber(row.IdOrdenDetalle),
    movementType: toText(row.TipoMovimiento),
    previousState: toText(row.EstadoAnterior),
    currentState: toText(row.EstadoNuevo),
    note: toText(row.Observacion),
    movementDate: toIsoDateTime(row.FechaMovimiento),
    userId: toNumber(row.UsuarioMovimiento),
    username: toText(row.NombreUsuario),
    fullName: toText(row.NombreCompleto),
  }
}

function getOrderActor(userId?: number, session?: SessionContext) {
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const resolvedUserId = userId ?? demoUserId
  return {
    userId: resolvedUserId,
    sessionId: session?.sessionId ?? null,
    token: session?.token ?? null,
    userType: session?.userType ?? "O",
  }
}

async function validateOrderUserAccess(input: {
  operation: string
  userId: number
  userType?: "A" | "S" | "O"
  orderId?: number | null
  resourceId?: number | null
}) {
  const pool = await getPool()
  const request = pool.request().input("Operacion", input.operation).input("IdUsuario", input.userId).input("TipoUsuario", input.userType ?? "O")
  if (input.orderId != null) request.input("IdOrden", input.orderId)
  if (input.resourceId != null) request.input("IdRecurso", input.resourceId)
  return request.execute("dbo.spOrdenesValidarAccesoUsuario")
}

async function syncOrderResourceLock(resourceId: number, userId?: number) {
  if (!Number.isInteger(resourceId) || resourceId <= 0) return
  const pool = await getPool()
  await pool
    .request()
    .input("IdRecurso", resourceId)
    .input("UsuarioAccion", userId ?? null)
    .execute("dbo.spOrdenesSincronizarBloqueoRecurso")
}

export async function getProductsForOrderCapture() {
  const pool = await getPool()
  await pool.request().query(`
    SET NOCOUNT ON;
    IF COL_LENGTH('dbo.Categorias', 'ColorFondoItem') IS NULL
      ALTER TABLE dbo.Categorias ADD ColorFondoItem NVARCHAR(7) NULL;
    IF COL_LENGTH('dbo.Categorias', 'ColorBotonItem') IS NULL
      ALTER TABLE dbo.Categorias ADD ColorBotonItem NVARCHAR(7) NULL;
    IF COL_LENGTH('dbo.Categorias', 'ColorTextoItem') IS NULL
      ALTER TABLE dbo.Categorias ADD ColorTextoItem NVARCHAR(7) NULL;
  `).catch(() => null)

  const productImageExistsResult = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT CASE WHEN COL_LENGTH('dbo.Productos', 'Imagen') IS NOT NULL THEN 1 ELSE 0 END AS Existe;
  `).catch(() => ({ recordset: [{ Existe: 0 }] as QueryRow[] }))
  const hasProductImageColumn = toNumber(productImageExistsResult.recordset?.[0]?.Existe) === 1

  const result = await pool.request().query(hasProductImageColumn ? `
    SET NOCOUNT ON;
    SELECT
      P.IdProducto,
      ISNULL(P.Codigo, '') AS Codigo,
      P.Nombre,
      C.Nombre AS Categoria,
      ISNULL(P.Imagen, '') AS Imagen,
      ISNULL(C.Imagen, '') AS CategoriaImagen,
      ISNULL(C.ColorFondo, '#1e3a5f') AS ColorFondo,
      ISNULL(C.ColorBoton, '#12467e') AS ColorBoton,
      ISNULL(C.ColorTexto, '#ffffff') AS ColorTexto,
      ISNULL(C.ColorFondoItem, ISNULL(C.ColorFondo, '#1e3a5f')) AS ColorFondoItem,
      ISNULL(C.ColorBotonItem, ISNULL(C.ColorBoton, '#12467e')) AS ColorBotonItem,
      ISNULL(C.ColorTextoItem, ISNULL(C.ColorTexto, '#ffffff')) AS ColorTextoItem,
      P.IdUnidadVenta,
      UV.Nombre AS UnidadVenta,
      ISNULL(P.AplicaImpuesto, 0) AS AplicaImpuesto,
      ISNULL(TI.Tasa, 0) AS TasaImpuesto,
      ISNULL(P.AplicaPropina, 0) AS AplicaPropina,
      ISNULL(P.SeVendeEnFactura, 1) AS SeVendeEnFactura,
      ISNULL(P.PermiteDescuento, 1) AS PermiteDescuento,
      ISNULL(P.PermiteCambioPrecio, 1) AS PermiteCambioPrecio,
      ISNULL(P.ManejaExistencia, 0) AS ManejaExistencia,
      ISNULL(P.VenderSinExistencia, 1) AS VenderSinExistencia,
      ISNULL((SELECT ISNULL(SUM(pa.Cantidad), 0) FROM dbo.ProductoAlmacenes pa WHERE pa.IdProducto = P.IdProducto AND pa.RowStatus = 1), 0) AS Existencia,
      ISNULL((
        SELECT TOP 1 PP.Precio
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
        ORDER BY LP.IdListaPrecio ASC
      ), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
    LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
    WHERE P.RowStatus = 1
    ORDER BY C.Nombre, P.Nombre;
  ` : `
    SET NOCOUNT ON;
    SELECT
      P.IdProducto,
      ISNULL(P.Codigo, '') AS Codigo,
      P.Nombre,
      C.Nombre AS Categoria,
      CAST('' AS NVARCHAR(500)) AS Imagen,
      ISNULL(C.Imagen, '') AS CategoriaImagen,
      ISNULL(C.ColorFondo, '#1e3a5f') AS ColorFondo,
      ISNULL(C.ColorBoton, '#12467e') AS ColorBoton,
      ISNULL(C.ColorTexto, '#ffffff') AS ColorTexto,
      ISNULL(C.ColorFondoItem, ISNULL(C.ColorFondo, '#1e3a5f')) AS ColorFondoItem,
      ISNULL(C.ColorBotonItem, ISNULL(C.ColorBoton, '#12467e')) AS ColorBotonItem,
      ISNULL(C.ColorTextoItem, ISNULL(C.ColorTexto, '#ffffff')) AS ColorTextoItem,
      P.IdUnidadVenta,
      UV.Nombre AS UnidadVenta,
      ISNULL(P.AplicaImpuesto, 0) AS AplicaImpuesto,
      ISNULL(TI.Tasa, 0) AS TasaImpuesto,
      ISNULL(P.AplicaPropina, 0) AS AplicaPropina,
      ISNULL(P.SeVendeEnFactura, 1) AS SeVendeEnFactura,
      ISNULL(P.PermiteDescuento, 1) AS PermiteDescuento,
      ISNULL(P.PermiteCambioPrecio, 1) AS PermiteCambioPrecio,
      ISNULL(P.ManejaExistencia, 0) AS ManejaExistencia,
      ISNULL(P.VenderSinExistencia, 1) AS VenderSinExistencia,
      ISNULL((SELECT ISNULL(SUM(pa.Cantidad), 0) FROM dbo.ProductoAlmacenes pa WHERE pa.IdProducto = P.IdProducto AND pa.RowStatus = 1), 0) AS Existencia,
      ISNULL((
        SELECT TOP 1 PP.Precio
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
        ORDER BY LP.IdListaPrecio ASC
      ), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
    LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
    WHERE P.RowStatus = 1
    ORDER BY C.Nombre, P.Nombre;
  `)
  return (result.recordset as QueryRow[]).map((row) => ({
    id: toNumber(row.IdProducto),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    category: toText(row.Categoria) || "Sin categoría",
    image: toText(row.Imagen) || null,
    categoryImage: toText(row.CategoriaImagen) || null,
    categoryButtonBackground: toText(row.ColorFondo) || "#1e3a5f",
    categoryButtonColor: toText(row.ColorBoton) || "#12467e",
    categoryButtonText: toText(row.ColorTexto) || "#ffffff",
    itemButtonBackground: toText(row.ColorFondoItem) || toText(row.ColorFondo) || "#1e3a5f",
    itemButtonColor: toText(row.ColorBotonItem) || toText(row.ColorBoton) || "#12467e",
    itemButtonText: toText(row.ColorTextoItem) || toText(row.ColorTexto) || "#ffffff",
    price: toNumber(row.Precio),
    unitId: toNumber(row.IdUnidadVenta),
    unitName: toText(row.UnidadVenta),
    applyTax: Boolean(row.AplicaImpuesto),
    taxRate: toNumber(row.TasaImpuesto),
    applyTip: Boolean(row.AplicaPropina),
    canSellInBilling: row.SeVendeEnFactura !== false && row.SeVendeEnFactura !== 0,
    allowDiscount: row.PermiteDescuento !== false && row.PermiteDescuento !== 0,
    allowPriceChange: row.PermiteCambioPrecio !== false && row.PermiteCambioPrecio !== 0,
    managesStock: Boolean(row.ManejaExistencia),
    sellWithoutStock: row.VenderSinExistencia !== false && row.VenderSinExistencia !== 0,
    stock: toNumber(row.Existencia),
  }))
}

function mapOrderProductOptionForBilling(row: QueryRow): OrderProductOption {
  return {
    id: toNumber(row.IdProducto),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    category: toText(row.Categoria) || "Sin categorÃ­a",
    image: toText(row.Imagen) || null,
    categoryImage: toText(row.CategoriaImagen) || null,
    categoryButtonBackground: toText(row.ColorFondo) || "#1e3a5f",
    categoryButtonColor: toText(row.ColorBoton) || "#12467e",
    categoryButtonText: toText(row.ColorTexto) || "#ffffff",
    itemButtonBackground: toText(row.ColorFondoItem) || toText(row.ColorFondo) || "#1e3a5f",
    itemButtonColor: toText(row.ColorBotonItem) || toText(row.ColorBoton) || "#12467e",
    itemButtonText: toText(row.ColorTextoItem) || toText(row.ColorTexto) || "#ffffff",
    price: toNumber(row.Precio),
    unitId: toNumber(row.IdUnidadVenta),
    unitName: toText(row.UnidadVenta),
    applyTax: Boolean(row.AplicaImpuesto),
    taxRate: toNumber(row.TasaImpuesto),
    applyTip: Boolean(row.AplicaPropina),
    canSellInBilling: row.SeVendeEnFactura !== false && row.SeVendeEnFactura !== 0,
    allowDiscount: row.PermiteDescuento !== false && row.PermiteDescuento !== 0,
    allowPriceChange: row.PermiteCambioPrecio !== false && row.PermiteCambioPrecio !== 0,
    managesStock: Boolean(row.ManejaExistencia),
    sellWithoutStock: row.VenderSinExistencia !== false && row.VenderSinExistencia !== 0,
    stock: toNumber(row.Existencia),
  }
}

function isMissingStoredProcedure(error: unknown, procedureName: string) {
  return error instanceof Error
    && error.message.toLowerCase().includes(`could not find stored procedure '${procedureName.toLowerCase()}'`)
}

export async function getBillingProductByExactCode(code: string): Promise<OrderProductOption | null> {
  const pool = await getPool()
  const normalizedCode = code.trim()
  if (!normalizedCode) return null

  try {
    let result
    try {
      result = await pool.request()
        .input("Codigo", sql.NVarChar(60), normalizedCode)
        .execute("dbo.spFacBuscarProductoPOSPorCodigo")
    } catch (error) {
      if (!isTypeValidationError(error)) throw error
      result = await pool.request()
        .input("Codigo", normalizedCode)
        .execute("dbo.spFacBuscarProductoPOSPorCodigo")
    }
    const row = (result.recordset as QueryRow[])[0]
    return row ? mapOrderProductOptionForBilling(row) : null
  } catch (error) {
    if (!isMissingStoredProcedure(error, "dbo.spFacBuscarProductoPOSPorCodigo")) throw error
  }

  const metadataResult = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT
      CASE WHEN COL_LENGTH('dbo.Productos', 'Imagen') IS NOT NULL THEN 1 ELSE 0 END AS HasImage,
      CASE WHEN COL_LENGTH('dbo.Productos', 'CodigoCorto') IS NOT NULL THEN 1 ELSE 0 END AS HasCodigoCorto;
  `).catch(() => ({ recordset: [{ HasImage: 0, HasCodigoCorto: 0 }] as QueryRow[] }))

  const hasProductImageColumn = toNumber(metadataResult.recordset?.[0]?.HasImage) === 1
  const hasShortCodeColumn = toNumber(metadataResult.recordset?.[0]?.HasCodigoCorto) === 1
  const exactCodeFilter = hasShortCodeColumn
    ? `AND (ISNULL(P.Codigo, '') = @Codigo OR ISNULL(P.CodigoCorto, '') = @Codigo)`
    : `AND ISNULL(P.Codigo, '') = @Codigo`

  const exactLookupQuery = hasProductImageColumn ? `
    SET NOCOUNT ON;
    SELECT TOP 1
      P.IdProducto,
      ISNULL(P.Codigo, '') AS Codigo,
      P.Nombre,
      C.Nombre AS Categoria,
      ISNULL(P.Imagen, '') AS Imagen,
      ISNULL(C.Imagen, '') AS CategoriaImagen,
      ISNULL(C.ColorFondo, '#1e3a5f') AS ColorFondo,
      ISNULL(C.ColorBoton, '#12467e') AS ColorBoton,
      ISNULL(C.ColorTexto, '#ffffff') AS ColorTexto,
      ISNULL(C.ColorFondoItem, ISNULL(C.ColorFondo, '#1e3a5f')) AS ColorFondoItem,
      ISNULL(C.ColorBotonItem, ISNULL(C.ColorBoton, '#12467e')) AS ColorBotonItem,
      ISNULL(C.ColorTextoItem, ISNULL(C.ColorTexto, '#ffffff')) AS ColorTextoItem,
      P.IdUnidadVenta,
      UV.Nombre AS UnidadVenta,
      ISNULL(P.AplicaImpuesto, 0) AS AplicaImpuesto,
      ISNULL(TI.Tasa, 0) AS TasaImpuesto,
      ISNULL(P.AplicaPropina, 0) AS AplicaPropina,
      ISNULL(P.SeVendeEnFactura, 1) AS SeVendeEnFactura,
      ISNULL(P.PermiteDescuento, 1) AS PermiteDescuento,
      ISNULL(P.PermiteCambioPrecio, 1) AS PermiteCambioPrecio,
      ISNULL(P.ManejaExistencia, 0) AS ManejaExistencia,
      ISNULL(P.VenderSinExistencia, 1) AS VenderSinExistencia,
      ISNULL((SELECT ISNULL(SUM(pa.Cantidad), 0) FROM dbo.ProductoAlmacenes pa WHERE pa.IdProducto = P.IdProducto AND pa.RowStatus = 1), 0) AS Existencia,
      ISNULL((
        SELECT TOP 1 PP.Precio
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
        ORDER BY LP.IdListaPrecio ASC
      ), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
    LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
    WHERE P.RowStatus = 1
      ${exactCodeFilter}
    ORDER BY P.IdProducto;
  ` : `
    SET NOCOUNT ON;
    SELECT TOP 1
      P.IdProducto,
      ISNULL(P.Codigo, '') AS Codigo,
      P.Nombre,
      C.Nombre AS Categoria,
      CAST('' AS NVARCHAR(500)) AS Imagen,
      ISNULL(C.Imagen, '') AS CategoriaImagen,
      ISNULL(C.ColorFondo, '#1e3a5f') AS ColorFondo,
      ISNULL(C.ColorBoton, '#12467e') AS ColorBoton,
      ISNULL(C.ColorTexto, '#ffffff') AS ColorTexto,
      ISNULL(C.ColorFondoItem, ISNULL(C.ColorFondo, '#1e3a5f')) AS ColorFondoItem,
      ISNULL(C.ColorBotonItem, ISNULL(C.ColorBoton, '#12467e')) AS ColorBotonItem,
      ISNULL(C.ColorTextoItem, ISNULL(C.ColorTexto, '#ffffff')) AS ColorTextoItem,
      P.IdUnidadVenta,
      UV.Nombre AS UnidadVenta,
      ISNULL(P.AplicaImpuesto, 0) AS AplicaImpuesto,
      ISNULL(TI.Tasa, 0) AS TasaImpuesto,
      ISNULL(P.AplicaPropina, 0) AS AplicaPropina,
      ISNULL(P.SeVendeEnFactura, 1) AS SeVendeEnFactura,
      ISNULL(P.PermiteDescuento, 1) AS PermiteDescuento,
      ISNULL(P.PermiteCambioPrecio, 1) AS PermiteCambioPrecio,
      ISNULL(P.ManejaExistencia, 0) AS ManejaExistencia,
      ISNULL(P.VenderSinExistencia, 1) AS VenderSinExistencia,
      ISNULL((SELECT ISNULL(SUM(pa.Cantidad), 0) FROM dbo.ProductoAlmacenes pa WHERE pa.IdProducto = P.IdProducto AND pa.RowStatus = 1), 0) AS Existencia,
      ISNULL((
        SELECT TOP 1 PP.Precio
        FROM dbo.ProductoPrecios PP
        INNER JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PP.IdListaPrecio
        WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
        ORDER BY LP.IdListaPrecio ASC
      ), 0) AS Precio
    FROM dbo.Productos P
    INNER JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
    INNER JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
    LEFT JOIN dbo.TasasImpuesto TI ON TI.IdTasaImpuesto = P.IdTasaImpuesto
    WHERE P.RowStatus = 1
      ${exactCodeFilter}
    ORDER BY P.IdProducto;
  `

  let result
  try {
    result = await pool.request()
      .input("Codigo", sql.NVarChar(60), normalizedCode)
      .query(exactLookupQuery)
  } catch (error) {
    if (!isTypeValidationError(error)) throw error
    result = await pool.request()
      .input("Codigo", normalizedCode)
      .query(exactLookupQuery)
  }

  const row = (result.recordset as QueryRow[])[0]
  return row ? mapOrderProductOptionForBilling(row) : null
}

export async function listOrders(): Promise<OrderSummaryRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spOrdenesCRUD")
  return (result.recordset as QueryRow[]).map(mapOrderSummaryRow)
}

export async function getOrderLines(orderId: number): Promise<OrderLineRecord[]> {
  const pool = await getPool()
  try {
    const result = await pool.request().input("Accion", "L").input("IdOrden", sql.Int, orderId).execute("dbo.spOrdenesDetalleCRUD")
    return (result.recordset as QueryRow[]).map(mapOrderLineRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request().input("Accion", "L").input("IdOrden", orderId).execute("dbo.spOrdenesDetalleCRUD")
    return (result.recordset as QueryRow[]).map(mapOrderLineRow)
  }
}

async function getOrderLineById(orderLineId: number): Promise<OrderLineRecord | null> {
  if (!Number.isInteger(orderLineId) || orderLineId <= 0) return null
  const pool = await getPool()
  const result = await pool.request().input("Accion", "O").input("IdOrdenDetalle", sql.Int, orderLineId).execute("dbo.spOrdenesDetalleCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  return row ? mapOrderLineRow(row) : null
}

export async function getOrderById(orderId: number, userId?: number, session?: SessionContext): Promise<OrderRecord | null> {
  if (!Number.isInteger(orderId) || orderId <= 0) {
    throw new Error("Orden invalida.")
  }

  if (userId != null) {
    const actor = getOrderActor(userId, session)
    await validateOrderUserAccess({
      operation: "VER_ORDEN",
      userId: actor.userId,
      userType: actor.userType,
      orderId,
    })
  }

  const pool = await getPool()
  const [orderResult, detail] = await Promise.all([
    (async () => {
      try {
        return await pool.request().input("Accion", "O").input("IdOrden", sql.Int, orderId).execute("dbo.spOrdenesCRUD")
      } catch (err) {
        if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
        return await pool.request().input("Accion", "O").input("IdOrden", orderId).execute("dbo.spOrdenesCRUD")
      }
    })(),
    getOrderLines(orderId),
  ])

  const row = orderResult.recordset?.[0] as QueryRow | undefined
  if (!row) return null

  return {
    ...mapOrderSummaryRow(row),
    detail,
  }
}

export async function getOrderHistory(orderId: number): Promise<OrderHistoryRecord[]> {
  if (!Number.isInteger(orderId) || orderId <= 0) {
    throw new Error("Orden invalida.")
  }

  const pool = await getPool()
  const result = await pool.request().input("IdOrden", sql.Int, orderId).execute("dbo.spOrdenesHistorial")
  return (result.recordset as QueryRow[]).map(mapOrderHistoryRow)
}

export async function getOrdersTrayData(): Promise<OrdersTrayData> {
  const pool = await getPool()
  const [dashboardResult, detailsResult, products, companyResult, resourcesResult] = await Promise.all([
    pool.request().execute("dbo.spOrdenesDashboard"),
    pool.request().execute("dbo.spOrdenesDashboardDetalle"),
    getProductsForOrderCapture(),
    pool.request().input("Accion", "O").execute("dbo.spEmpresaCRUD").catch(() => ({ recordset: [] as QueryRow[] })),
    pool.request().input("Accion", "L").execute("dbo.spRecursosCRUD").catch(() => ({ recordset: [] as QueryRow[] })),
  ])

  const companyRow = (companyResult as { recordset: QueryRow[] }).recordset?.[0]
  const companyApplyTip = Boolean(companyRow?.AplicaPropina)
  const companyTipPercent = Number(companyRow?.PorcentajePropina ?? 10)
  const companyRestrictOrdersByUser = Boolean(companyRow?.RestringirOrdenesPorUsuario)
  const companyLockTablesByUser = Boolean(companyRow?.BloquearMesaPorUsuario)
  const currencyCode = toText(companyRow?.Moneda, "DOP")
  const currencies = await getCurrencies().catch(() => [])
  const currencySymbol = currencies.find((item) => item.code === currencyCode)?.symbol || "RD$"

  const detailMap = new Map<number, OrderItem[]>()
  detailsResult.recordset.forEach((row: QueryRow) => {
    const orderId = toNumber(row.IdOrden)
    const list = detailMap.get(orderId) ?? []
    list.push({
      id: toNumber(row.IdOrdenDetalle),
      name: toText(row.Producto),
      quantity: toNumber(row.Cantidad),
      units: toNumber(row.Unidades),
      price: toNumber(row.PrecioUnitario),
      taxPercent: toNumber(row.PorcentajeImpuesto),
      taxAmount: toNumber(row.MontoImpuesto),
      total: toNumber(row.TotalLinea),
      note: toText(row.ObservacionLinea),
      personNumber: Math.max(1, toNumber(row.NumeroPersona) || 1),
      createdAt: row.FechaCreacion ? toIsoDateTime(row.FechaCreacion) : undefined,
      createdBy: toText(row.UsuarioCreacionNombre),
    })
    detailMap.set(orderId, list)
  })

  const resourceBaseMap = new Map<number, { id: number; name: string; area: string; category: string; categoryColor: string; lockedByUserId: number | null; lockedByUsername: string }>()
  const ordersByResource = new Map<number, OpenOrderTicket[]>()
  const resourceLockMap = new Map<number, { lockedByUserId: number | null; lockedByUsername: string }>()

  for (const row of (resourcesResult as { recordset: QueryRow[] }).recordset ?? []) {
    const resourceId = toNumber(row.IdRecurso)
    const lock = {
      lockedByUserId: toNumber(row.IdUsuarioBloqueoOrdenes) || null,
      lockedByUsername: toText(row.UsuarioBloqueo),
    }
    resourceLockMap.set(resourceId, lock)
    if (!resourceBaseMap.has(resourceId)) {
      resourceBaseMap.set(resourceId, {
        id: resourceId,
        name: toText(row.Nombre),
        area: toText(row.Area),
        category: toText(row.Categoria),
        categoryColor: toText(row.ColorTema, "#3b82f6"),
        lockedByUserId: lock.lockedByUserId,
        lockedByUsername: lock.lockedByUsername,
      })
    }
  }

  for (const row of dashboardResult.recordset as QueryRow[]) {
    const resourceId = toNumber(row.IdRecurso)
    if (!resourceBaseMap.has(resourceId)) {
      const lock = resourceLockMap.get(resourceId)
      resourceBaseMap.set(resourceId, {
        id: resourceId,
        name: toText(row.Recurso),
        area: toText(row.Area),
        category: toText(row.Categoria),
        categoryColor: toText(row.ColorTema, "#3b82f6"),
        lockedByUserId: lock?.lockedByUserId ?? null,
        lockedByUsername: lock?.lockedByUsername ?? "",
      })
    }

    const orderId = toNumber(row.IdOrden)
    if (!orderId) continue

    const list = ordersByResource.get(resourceId) ?? []
    list.push({
      id: orderId,
      number: toText(row.NumeroOrden),
      state: toText(row.EstadoOrden),
      waiter: toText(row.Mesero),
      time: row.FechaOrden instanceof Date ? row.FechaOrden.toLocaleTimeString("es-DO", { hour: "2-digit", minute: "2-digit" }) : "-",
      createdAt: row.FechaOrden ? toIsoDateTime(row.FechaOrden) : undefined,
      guestCount: Math.max(1, toNumber(row.CantidadPersonas) || 1),
      ownerUserId: toNumber(row.IdUsuario),
      reference: toText(row.ReferenciaCliente),
      total: toNumber(row.Total),
      items: detailMap.get(orderId) ?? [],
    })
    ordersByResource.set(resourceId, list)
  }

  const resources = [...resourceBaseMap.values()].map((resource) => {
    const openOrders = (ordersByResource.get(resource.id) ?? []).sort((a, b) => a.id - b.id)
    return {
      ...resource,
      openOrders,
      openCount: openOrders.length,
      totalOpen: openOrders.reduce((sum, order) => sum + order.total, 0),
      firstOrderTime: openOrders[0]?.time ?? "-",
    }
  })

  return { resources, products, companyApplyTip, companyTipPercent, companyRestrictOrdersByUser, companyLockTablesByUser, currencySymbol }
}

export async function createOrder(input: {
  resourceId: number
  reference?: string
  observations?: string
  guestCount?: number
  waiterUserId?: number
  items?: Array<{ productId: number; quantity: number; personNumber?: number; note?: string }>
}, userId?: number, session?: SessionContext) {
  if (!Number.isInteger(input.resourceId) || input.resourceId <= 0) {
    throw new Error("Recurso invalido para la orden.")
  }

  const actor = getOrderActor(userId, session)
  await validateOrderUserAccess({
    operation: "CREAR_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    resourceId: input.resourceId,
  })
  const pool = await getPool()
  const insertOrder = await pool
    .request()
    .input("Accion", "I")
    .input("IdRecurso", input.resourceId)
    .input("IdUsuario", input.waiterUserId ?? actor.userId)
    .input("ReferenciaCliente", input.reference?.trim() || null)
    .input("Observaciones", input.observations?.trim() || null)
    .input("CantidadPersonas", Math.max(1, Math.floor(input.guestCount ?? 1)))
    .input("UsuarioCreacion", actor.userId)
    .input("IdSesion", actor.sessionId)
    .input("TokenSesion", actor.token)
    .execute("dbo.spOrdenesCRUD")

  const created = insertOrder.recordset[0] as QueryRow | undefined
  const orderId = created ? toNumber(created.IdOrden) : 0
  if (!orderId) {
    throw new Error("No fue posible crear la orden.")
  }

  const normalizedItems = (input.items ?? [])
    .map((item) => ({
      productId: Number(item.productId),
      quantity: Number(item.quantity),
      note: item.note,
      personNumber: Number(item.personNumber ?? 1),
    }))
    .filter((item) => item.productId > 0 && item.quantity > 0)

  if (normalizedItems.length > 0) {
    const allProducts = await getProductsForOrderCapture()
    const productMap = new Map<number, { price: number; unitId: number }>()
    for (const product of allProducts) {
      productMap.set(product.id, { price: product.price, unitId: product.unitId })
    }

    for (const item of normalizedItems) {
      const product = productMap.get(item.productId)
      if (!product) continue
      await addOrderLine(orderId, {
        productId: item.productId,
        unitId: product.unitId,
        quantity: item.quantity,
        units: 1,
        price: product.price,
        taxPercent: 18,
        note: item.note ?? "",
        personNumber: item.personNumber,
      }, actor.userId, session)
    }
  }

  await syncOrderResourceLock(input.resourceId, actor.userId)

  return { id: orderId }
}

export async function updateOrderHeader(orderId: number, input: {
  resourceId?: number
  stateId?: number
  reference?: string
  observations?: string
  guestCount?: number
  active?: boolean
}, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  await validateOrderUserAccess({
    operation: "ACTUALIZAR_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
    resourceId: input.resourceId ?? null,
  })
  const pool = await getPool()
  const result = await pool
    .request()
    .input("Accion", "A")
    .input("IdOrden", sql.Int, orderId)
    .input("IdRecurso", sql.Int, input.resourceId ?? null)
    .input("IdEstadoOrden", sql.Int, input.stateId ?? null)
    .input("ReferenciaCliente", sql.VarChar(200), input.reference ?? null)
    .input("Observaciones", sql.VarChar(500), input.observations ?? null)
    .input("CantidadPersonas", sql.Int, input.guestCount ?? null)
    .input("Activo", sql.Bit, input.active ?? null)
    .input("UsuarioModificacion", sql.Int, actor.userId)
    .input("IdSesion", sql.Int, actor.sessionId)
    .input("TokenSesion", sql.NVarChar(128), actor.token)
    .execute("dbo.spOrdenesCRUD")
  return mapOrderSummaryRow(result.recordset[0] as QueryRow)
}

export async function addOrderLine(orderId: number, input: {
  productId: number
  unitId: number
  quantity: number
  units?: number
  price: number
  taxPercent?: number
  personNumber?: number
  note?: string
}, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  await validateOrderUserAccess({
    operation: "AGREGAR_LINEA",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
  })
  const pool = await getPool()
  function buildOrderLineRequest(request: ReturnType<typeof pool.request>, typed: boolean) {
    request.input("Accion", "I")
    if (typed) {
      request
        .input("IdOrden", sql.Int, orderId)
        .input("IdProducto", sql.Int, input.productId)
        .input("IdUnidadMedida", sql.Int, input.unitId)
        .input("Cantidad", sql.Decimal(12, 2), input.quantity)
        .input("Unidades", sql.Int, input.units ?? 1)
        .input("PrecioUnitario", sql.Decimal(12, 2), input.price)
        .input("PorcentajeImpuesto", sql.Decimal(5, 2), input.taxPercent ?? 18)
        .input("ObservacionLinea", sql.VarChar(250), input.note?.trim() || null)
        .input("NumeroPersona", sql.Int, Math.max(1, Math.floor(input.personNumber ?? 1)))
        .input("UsuarioCreacion", sql.Int, actor.userId)
    } else {
      request
        .input("IdOrden", orderId)
        .input("IdProducto", input.productId)
        .input("IdUnidadMedida", input.unitId)
        .input("Cantidad", input.quantity)
        .input("Unidades", input.units ?? 1)
        .input("PrecioUnitario", input.price)
        .input("PorcentajeImpuesto", input.taxPercent ?? 18)
        .input("ObservacionLinea", input.note?.trim() || null)
        .input("NumeroPersona", Math.max(1, Math.floor(input.personNumber ?? 1)))
        .input("UsuarioCreacion", actor.userId)
    }
    return request
  }
  let result
  try {
    result = await buildOrderLineRequest(pool.request(), true).execute("dbo.spOrdenesDetalleCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    result = await buildOrderLineRequest(pool.request(), false).execute("dbo.spOrdenesDetalleCRUD")
  }
  return mapOrderLineRow(result.recordset[0] as QueryRow)
}

export async function updateOrderLine(orderLineId: number, input: {
  productId?: number
  unitId?: number
  quantity?: number
  units?: number
  price?: number
  taxPercent?: number
  personNumber?: number
  note?: string
}, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentLine = await getOrderLineById(orderLineId)
  if (!currentLine) throw new Error("La linea no existe.")
  const existingLine = currentLine
  await validateOrderUserAccess({
    operation: "ACTUALIZAR_LINEA",
    userId: actor.userId,
    userType: actor.userType,
    orderId: currentLine.orderId,
  })
  const pool = await getPool()
  function buildUpdateOrderLineRequest(request: ReturnType<typeof pool.request>, typed: boolean) {
    request.input("Accion", "A")
    if (typed) {
      request
        .input("IdOrdenDetalle", sql.Int, orderLineId)
        .input("IdProducto", sql.Int, input.productId ?? existingLine.productId ?? null)
        .input("IdUnidadMedida", sql.Int, input.unitId ?? existingLine.unitId ?? null)
        .input("Cantidad", sql.Decimal(12, 2), input.quantity ?? existingLine.quantity)
        .input("Unidades", sql.Int, input.units ?? 1)
        .input("PrecioUnitario", sql.Decimal(12, 2), input.price ?? existingLine.price)
        .input("PorcentajeImpuesto", sql.Decimal(5, 2), input.taxPercent ?? existingLine.taxPercent ?? 18)
        .input("ObservacionLinea", sql.VarChar(250), (input.note?.trim() ?? existingLine.note?.trim()) || null)
        .input("NumeroPersona", sql.Int, input.personNumber ?? null)
        .input("UsuarioModificacion", sql.Int, actor.userId)
    } else {
      request
        .input("IdOrdenDetalle", orderLineId)
        .input("IdProducto", input.productId ?? existingLine.productId ?? null)
        .input("IdUnidadMedida", input.unitId ?? existingLine.unitId ?? null)
        .input("Cantidad", input.quantity ?? existingLine.quantity)
        .input("Unidades", input.units ?? 1)
        .input("PrecioUnitario", input.price ?? existingLine.price)
        .input("PorcentajeImpuesto", input.taxPercent ?? existingLine.taxPercent ?? 18)
        .input("ObservacionLinea", (input.note?.trim() ?? existingLine.note?.trim()) || null)
        .input("NumeroPersona", input.personNumber ?? null)
        .input("UsuarioModificacion", actor.userId)
    }
    return request
  }
  let result
  try {
    result = await buildUpdateOrderLineRequest(pool.request(), true).execute("dbo.spOrdenesDetalleCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    result = await buildUpdateOrderLineRequest(pool.request(), false).execute("dbo.spOrdenesDetalleCRUD")
  }
  return mapOrderLineRow(result.recordset[0] as QueryRow)
}

export async function removeOrderLine(orderLineId: number, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentLine = await getOrderLineById(orderLineId)
  if (!currentLine) throw new Error("La linea no existe.")
  await validateOrderUserAccess({
    operation: "ELIMINAR_LINEA",
    userId: actor.userId,
    userType: actor.userType,
    orderId: currentLine.orderId,
  })
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "D")
      .input("IdOrdenDetalle", sql.Int, orderLineId)
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenesDetalleCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "D")
      .input("IdOrdenDetalle", orderLineId)
      .input("UsuarioModificacion", actor.userId)
      .execute("dbo.spOrdenesDetalleCRUD")
  }
  await syncOrderResourceLock(currentLine.orderId > 0 ? (await getOrderById(currentLine.orderId))?.resourceId ?? 0 : 0, actor.userId)
}

export async function createOrderForResource(input: {
  resourceId: number
  reference: string
  guestCount?: number
  items?: Array<{ productId: number; quantity: number; personNumber?: number; note?: string }>
}, userId?: number, session?: SessionContext) {
  return createOrder({
    resourceId: input.resourceId,
    reference: input.reference,
    guestCount: input.guestCount,
    observations: "Orden creada desde bandeja de ordenes",
    items: input.items,
  }, userId, session)
}

export async function closeAllOpenOrdersByResource(resourceId: number, userId?: number, session?: SessionContext) {
  if (!Number.isInteger(resourceId) || resourceId <= 0) {
    throw new Error("Recurso invalido.")
  }

  const actor = getOrderActor(userId, session)
  const pool = await getPool()
  const ordersResult = await pool.request().input("IdRecurso", sql.Int, resourceId).query(`
    SET NOCOUNT ON;
    SELECT O.IdOrden
    FROM dbo.Ordenes O
    INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
    WHERE O.RowStatus = 1
      AND O.IdRecurso = @IdRecurso
      AND E.Nombre IN ('Abierta', 'En proceso', 'Reabierta')
    ORDER BY O.IdOrden;
  `)

  for (const row of ordersResult.recordset as QueryRow[]) {
    await closeOrder(toNumber(row.IdOrden), actor.userId, session)
  }
}

export async function createDemoOrder(userId?: number, session?: SessionContext) {
  const pool = await getPool()
  const actor = getOrderActor(userId, session)

  const [resourceResult, products] = await Promise.all([
    pool.request().query(`
      SET NOCOUNT ON;
      SELECT TOP (1) R.IdRecurso
      FROM dbo.Recursos R
      WHERE R.RowStatus = 1
        AND NOT EXISTS (
          SELECT 1
          FROM dbo.Ordenes O
          INNER JOIN dbo.EstadosOrden E ON E.IdEstadoOrden = O.IdEstadoOrden
          WHERE O.IdRecurso = R.IdRecurso AND O.RowStatus = 1 AND E.Nombre IN ('Abierta', 'En proceso', 'Reabierta')
        )
      ORDER BY R.IdRecurso;
    `),
    getProductsForOrderCapture(),
  ])

  const resourceRow = (resourceResult.recordset as QueryRow[])[0]
  const product = products[0]
  if (!resourceRow || !product) {
    throw new Error("No hay recursos libres o productos activos para crear una orden demo.")
  }

  return createOrder({
    resourceId: toNumber(resourceRow.IdRecurso),
    observations: "Orden creada desde V2 para prueba funcional",
    items: [
      {
        productId: product.id,
        quantity: 1,
        note: "Demo creada desde V2",
      },
    ],
  }, actor.userId, session)
}

export async function moveOrderToInProgress(orderId: number, userId?: number, session?: SessionContext) {
  const pool = await getPool()
  const actor = getOrderActor(userId, session)
  await validateOrderUserAccess({
    operation: "CAMBIAR_ESTADO_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
  })
  const stateResult = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT TOP (1) IdEstadoOrden
    FROM dbo.EstadosOrden
    WHERE Nombre = 'En proceso' AND RowStatus = 1;
  `)
  const state = stateResult.recordset[0] as QueryRow | undefined
  if (!state) {
    throw new Error("No existe el estado 'En proceso'.")
  }
  await updateOrderHeader(orderId, { stateId: toNumber(state.IdEstadoOrden) }, actor.userId, session)
}

export async function closeOrder(orderId: number, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentOrder = await getOrderById(orderId)
  if (!currentOrder) throw new Error("La orden no existe.")
  await validateOrderUserAccess({
    operation: "CERRAR_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
  })
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "C")
      .input("IdOrden", sql.Int, orderId)
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenesCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "C")
      .input("IdOrden", orderId)
      .input("UsuarioModificacion", actor.userId)
      .execute("dbo.spOrdenesCRUD")
  }
  await syncOrderResourceLock(currentOrder.resourceId, actor.userId)
}

export async function cancelOrder(orderId: number, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentOrder = await getOrderById(orderId)
  if (!currentOrder) throw new Error("La orden no existe.")
  await validateOrderUserAccess({
    operation: "CANCELAR_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
  })
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "X")
      .input("IdOrden", sql.Int, orderId)
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenesCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "X")
      .input("IdOrden", orderId)
      .input("UsuarioModificacion", actor.userId)
      .execute("dbo.spOrdenesCRUD")
  }
  await syncOrderResourceLock(currentOrder.resourceId, actor.userId)
}

export async function reopenOrder(orderId: number, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentOrder = await getOrderById(orderId)
  if (!currentOrder) throw new Error("La orden no existe.")
  await validateOrderUserAccess({
    operation: "REABRIR_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
    resourceId: currentOrder.resourceId,
  })
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "R")
      .input("IdOrden", sql.Int, orderId)
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenesCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "R")
      .input("IdOrden", orderId)
      .input("UsuarioModificacion", actor.userId)
      .execute("dbo.spOrdenesCRUD")
  }
  await syncOrderResourceLock(currentOrder.resourceId, actor.userId)
}

export async function moveOrderToResource(orderId: number, resourceId: number, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentOrder = await getOrderById(orderId)
  if (!currentOrder) throw new Error("La orden no existe.")
  await validateOrderUserAccess({
    operation: "MOVER_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId,
    resourceId,
  })
  const pool = await getPool()
  let result
  try {
    result = await pool
      .request()
      .input("Accion", "A")
      .input("IdOrden", sql.Int, orderId)
      .input("IdRecurso", sql.Int, resourceId)
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .input("IdSesion", sql.BigInt, actor.sessionId)
      .input("TokenSesion", sql.NVarChar(200), actor.token)
      .execute("dbo.spOrdenesCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    result = await pool
      .request()
      .input("Accion", "A")
      .input("IdOrden", orderId)
      .input("IdRecurso", resourceId)
      .input("UsuarioModificacion", actor.userId)
      .input("IdSesion", actor.sessionId)
      .input("TokenSesion", actor.token)
      .execute("dbo.spOrdenesCRUD")
  }
  await syncOrderResourceLock(currentOrder.resourceId, actor.userId)
  await syncOrderResourceLock(resourceId, actor.userId)
  return mapOrderSummaryRow(result.recordset[0] as QueryRow)
}

export async function splitOrder(input: {
  orderId: number
  orderLineIds: number[]
  reference?: string
}, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const currentOrder = await getOrderById(input.orderId)
  if (!currentOrder) throw new Error("La orden no existe.")
  await validateOrderUserAccess({
    operation: "DIVIDIR_ORDEN",
    userId: actor.userId,
    userType: actor.userType,
    orderId: input.orderId,
  })
  const lineCsv = input.orderLineIds
    .map((value) => Number(value))
    .filter((value) => Number.isInteger(value) && value > 0)
    .join(",")

  if (!lineCsv) {
    throw new Error("Selecciona al menos una linea para dividir.")
  }

  const pool = await getPool()
  let result
  try {
    result = await pool
      .request()
      .input("IdOrdenOrigen", sql.Int, input.orderId)
      .input("IdsOrdenDetalleCsv", sql.NVarChar(sql.MAX), lineCsv)
      .input("ReferenciaCliente", sql.VarChar(200), input.reference?.trim() || null)
      .input("UsuarioAccion", sql.Int, actor.userId)
      .execute("dbo.spOrdenesDividir")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    result = await pool
      .request()
      .input("IdOrdenOrigen", input.orderId)
      .input("IdsOrdenDetalleCsv", lineCsv)
      .input("ReferenciaCliente", input.reference?.trim() || null)
      .input("UsuarioAccion", actor.userId)
      .execute("dbo.spOrdenesDividir")
  }

  const row = result.recordset?.[0] as QueryRow | undefined
  return {
    orderId: toNumber(row?.IdOrdenNueva),
    orderNumber: toText(row?.NumeroOrdenNueva),
  }
}

export async function mergeOrders(input: {
  targetOrderId: number
  sourceOrderIds: number[]
}, userId?: number, session?: SessionContext) {
  const actor = getOrderActor(userId, session)
  const targetOrder = await getOrderById(input.targetOrderId)
  if (!targetOrder) throw new Error("La orden destino no existe.")

  const sourceOrderIds = input.sourceOrderIds
    .map((value) => Number(value))
    .filter((value, index, array) => Number.isInteger(value) && value > 0 && value !== input.targetOrderId && array.indexOf(value) === index)

  if (!sourceOrderIds.length) {
    throw new Error("Selecciona al menos una orden origen para unificar.")
  }

  for (const sourceOrderId of sourceOrderIds) {
    const sourceOrder = await getOrderById(sourceOrderId)
    if (!sourceOrder) throw new Error("Una de las ordenes origen no existe.")
  }

  const sourceCsv = sourceOrderIds.join(",")
  const pool = await getPool()
  try {
    await pool.request()
      .input("IdOrdenDestino", sql.Int, input.targetOrderId)
      .input("IdsOrdenOrigenCsv", sql.NVarChar(sql.MAX), sourceCsv)
      .input("UsuarioAccion", sql.Int, actor.userId)
      .input("TipoUsuario", sql.Char(1), actor.userType)
      .execute("dbo.spOrdenesUnificar")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool.request()
      .input("IdOrdenDestino", input.targetOrderId)
      .input("IdsOrdenOrigenCsv", sourceCsv)
      .input("UsuarioAccion", actor.userId)
      .input("TipoUsuario", actor.userType)
      .execute("dbo.spOrdenesUnificar")
  }

  await syncOrderResourceLock(targetOrder.resourceId, actor.userId)
  const merged = await getOrderById(input.targetOrderId)
  if (!merged) throw new Error("No se pudo cargar la orden unificada.")
  return merged
}

export async function verifySupervisorCredentials(input: {
  username: string
  passwordHash: string
  permissionKey: string
}) {
  const pool = await getPool()
  const result = await pool
    .request()
    .input("NombreUsuario", input.username.trim())
    .input("ClaveHash", input.passwordHash)
    .input("ClavePermiso", input.permissionKey.trim())
    .execute("dbo.spAuthVerificarSupervisor")

  const row = result.recordset?.[0] as QueryRow | undefined
  if (!row) {
    throw new Error("No fue posible verificar el supervisor.")
  }

  return {
    userId: toNumber(row.IdUsuario),
    username: toText(row.NombreUsuario),
    fullName: `${toText(row.Nombres)} ${toText(row.Apellidos)}`.trim(),
    roleId: toNumber(row.IdRol),
    roleName: toText(row.Rol),
    userType: toUserType(row.TipoUsuario, toText(row.Rol)),
    permissionKey: toText(row.ClavePermiso),
  } satisfies SupervisorVerificationResult
}

type ProductPriceInput = {
  priceListId: number
  profitPercent: number
  price: number
  tax: number
  priceWithTax: number
}

type ProductCostsInput = {
  currencyId: number | null
  providerDiscount: number
  providerCost: number
  providerCostWithTax: number
  averageCost: number
  allowManualAvgCost: boolean
}

type ProductOfferInput = {
  active: boolean
  price: number
  startDate: string
  endDate: string
}

type ProductMutationInput = {
  code?: string
  comment?: string
  imagen?: string | null
  categoryId: number
  typeId: number
  unitBaseId: number
  unitSaleId: number
  unitPurchaseId: number
  unitAlt1Id?: number
  unitAlt2Id?: number
  unitAlt3Id?: number
  name: string
  description?: string
  price: number
  applyTax?: boolean
  taxRateId?: number | null
  stockUnitBase?: string
  canSellInBilling?: boolean
  allowDiscount?: boolean
  allowPriceChange?: boolean
  allowManualPrice?: boolean
  requestUnit?: boolean
  requestUnitInventory?: boolean
  allowDecimals?: boolean
  sellWithoutStock?: boolean
  applyTip?: boolean
  managesStock?: boolean
  prices?: ProductPriceInput[]
  costs?: ProductCostsInput
  offer?: ProductOfferInput
  active: boolean
}

function isTypeValidationError(error: unknown) {
  return error instanceof Error && error.message.includes("parameter.type.validate is not a function")
}

function isMissingColumnError(error: unknown, columnName: string) {
  return error instanceof Error && error.message.toLowerCase().includes(`invalid column name '${columnName.toLowerCase()}'`)
}

export async function searchProducts(input: { query?: string; limit?: number }): Promise<ProductListItem[]> {
  const pool = await getPool()
  const q = (input.query ?? "").trim()
  const limit = Math.max(1, Math.min(input.limit ?? 60, 200))

  const result = await pool.request()
    .input("Busqueda", sql.NVarChar(150), q)
    .input("Top", sql.Int, limit)
    .execute("dbo.spBuscarProductos")
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      return pool.request()
        .input("Busqueda", q)
        .input("Top", limit)
        .execute("dbo.spBuscarProductos")
    })

  const items = (result.recordset as QueryRow[]).map((row) => ({
    id: toNumber(row.IdProducto),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    price: toNumber(row.Precio),
    active: Boolean(row.Activo),
    category: toText(row.Categoria),
    type: toText(row.TipoProducto),
    imagen: null,
  }))

  if (!items.length) return items

  const imageRows = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT CASE WHEN COL_LENGTH('dbo.Productos', 'Imagen') IS NOT NULL THEN 1 ELSE 0 END AS HasImage;
  `).catch(() => ({ recordset: [{ HasImage: 0 }] as QueryRow[] }))

  if (toNumber(imageRows.recordset?.[0]?.HasImage) !== 1) {
    return items
  }

  const ids = items.map((item) => item.id).filter((id) => id > 0)
  const imageResult = await pool.request().query(`
    SET NOCOUNT ON;
    SELECT IdProducto, ISNULL(Imagen, '') AS Imagen
    FROM dbo.Productos
    WHERE RowStatus = 1
      AND IdProducto IN (${ids.join(",")});
  `).catch(() => ({ recordset: [] as QueryRow[] }))

  const imageMap = new Map<number, string>()
  for (const row of imageResult.recordset as QueryRow[]) {
    imageMap.set(toNumber(row.IdProducto), toText(row.Imagen))
  }

  return items.map((item) => ({
    ...item,
    imagen: imageMap.get(item.id) || null,
  }))
}

async function loadProductCode(productId: number, pool?: Awaited<ReturnType<typeof getPool>>): Promise<string> {
  const conn = pool ?? await getPool()
  const codeResult = await conn.request().input("IdProducto", sql.Int, productId).query(`
    SET NOCOUNT ON;
    IF COL_LENGTH('dbo.Productos', 'Codigo') IS NOT NULL
      SELECT TOP 1 ISNULL(Codigo, '') AS Codigo FROM dbo.Productos WHERE IdProducto = @IdProducto;
    ELSE
      SELECT CAST('' AS NVARCHAR(60)) AS Codigo;
  `).catch(async (err: unknown) => {
    if (!isTypeValidationError(err)) throw err
    return conn.request().input("IdProducto", productId).query(`
      SET NOCOUNT ON;
      IF COL_LENGTH('dbo.Productos', 'Codigo') IS NOT NULL
        SELECT TOP 1 ISNULL(Codigo, '') AS Codigo FROM dbo.Productos WHERE IdProducto = @IdProducto;
      ELSE
        SELECT CAST('' AS NVARCHAR(60)) AS Codigo;
    `)
  })
  return toText(codeResult.recordset?.[0]?.Codigo)
}

async function loadProductComment(productId: number, pool?: Awaited<ReturnType<typeof getPool>>): Promise<string> {
  const conn = pool ?? await getPool()
  const result = await conn.request().input("IdProducto", sql.Int, productId).query(`
    SET NOCOUNT ON;
    IF COL_LENGTH('dbo.Productos', 'Comentario') IS NOT NULL
      SELECT TOP 1 ISNULL(Comentario, '') AS Comentario FROM dbo.Productos WHERE IdProducto = @IdProducto;
    ELSE
      SELECT CAST('' AS NVARCHAR(MAX)) AS Comentario;
  `).catch(async (err: unknown) => {
    if (!isTypeValidationError(err)) throw err
    return conn.request().input("IdProducto", productId).query(`
      SET NOCOUNT ON;
      IF COL_LENGTH('dbo.Productos', 'Comentario') IS NOT NULL
        SELECT TOP 1 ISNULL(Comentario, '') AS Comentario FROM dbo.Productos WHERE IdProducto = @IdProducto;
      ELSE
        SELECT CAST('' AS NVARCHAR(MAX)) AS Comentario;
    `)
  })
  return toText(result.recordset?.[0]?.Comentario)
}

async function loadProductImage(productId: number, pool?: Awaited<ReturnType<typeof getPool>>): Promise<string | null> {
  const conn = pool ?? await getPool()
  const existsResult = await conn.request().query(`
    SET NOCOUNT ON;
    SELECT CASE WHEN COL_LENGTH('dbo.Productos', 'Imagen') IS NOT NULL THEN 1 ELSE 0 END AS Existe;
  `).catch(async (err: unknown) => {
    if (!isTypeValidationError(err)) throw err
    return conn.request().query(`
      SET NOCOUNT ON;
      SELECT CASE WHEN COL_LENGTH('dbo.Productos', 'Imagen') IS NOT NULL THEN 1 ELSE 0 END AS Existe;
    `)
  })
  const hasImageColumn = toNumber(existsResult.recordset?.[0]?.Existe) === 1
  if (!hasImageColumn) return null

  const result = await conn.request().input("IdProducto", sql.Int, productId).query(`
    SET NOCOUNT ON;
    SELECT TOP 1 ISNULL(Imagen, '') AS Imagen FROM dbo.Productos WHERE IdProducto = @IdProducto;
  `).catch(async (err: unknown) => {
    if (!isTypeValidationError(err)) throw err
    return conn.request().input("IdProducto", productId).query(`
      SET NOCOUNT ON;
      SELECT TOP 1 ISNULL(Imagen, '') AS Imagen FROM dbo.Productos WHERE IdProducto = @IdProducto;
    `)
  })
  return toText(result.recordset?.[0]?.Imagen) || null
}

async function persistProductCode(productId: number, code: string | undefined, pool?: Awaited<ReturnType<typeof getPool>>) {
  const conn = pool ?? await getPool()
  const normalized = (code ?? "").trim()
  const query = `
    SET NOCOUNT ON;
    IF COL_LENGTH('dbo.Productos', 'Codigo') IS NULL
      ALTER TABLE dbo.Productos ADD Codigo NVARCHAR(60) NULL;

    IF @Codigo IS NOT NULL
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM dbo.Productos P
        WHERE P.RowStatus = 1
          AND ISNULL(P.Codigo, '') = @Codigo
          AND P.IdProducto <> @IdProducto
      )
        THROW 51001, 'El codigo/barra ya existe en otro producto.', 1;
    END

    UPDATE dbo.Productos
    SET Codigo = @Codigo
    WHERE IdProducto = @IdProducto;
  `

  await conn.request()
    .input("IdProducto", sql.Int, productId)
    .input("Codigo", sql.NVarChar(60), normalized || null)
    .query(query)
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      await conn.request()
        .input("IdProducto", productId)
        .input("Codigo", normalized || null)
        .query(query)
    })
}

async function persistProductComment(productId: number, comment: string | undefined, pool?: Awaited<ReturnType<typeof getPool>>) {
  const conn = pool ?? await getPool()
  const value = (comment ?? "").trim() || null
  const query = `
    SET NOCOUNT ON;
    IF COL_LENGTH('dbo.Productos', 'Comentario') IS NULL
      ALTER TABLE dbo.Productos ADD Comentario NVARCHAR(MAX) NULL;
    UPDATE dbo.Productos SET Comentario = @Comentario WHERE IdProducto = @IdProducto;
  `

  await conn.request()
    .input("IdProducto", sql.Int, productId)
    .input("Comentario", sql.NVarChar(sql.MAX), value)
    .query(query)
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      await conn.request()
        .input("IdProducto", productId)
        .input("Comentario", value)
        .query(query)
    })
}

async function persistProductImage(productId: number, image: string | null | undefined, pool?: Awaited<ReturnType<typeof getPool>>) {
  const conn = pool ?? await getPool()
  const value = (image ?? "").trim() || null
  const ensureQuery = `
    SET NOCOUNT ON;
    IF COL_LENGTH('dbo.Productos', 'Imagen') IS NULL
      ALTER TABLE dbo.Productos ADD Imagen NVARCHAR(MAX) NULL;
    ELSE
    BEGIN
      DECLARE @ImageType NVARCHAR(128) =
        (SELECT DATA_TYPE
         FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Productos' AND COLUMN_NAME = 'Imagen');
      DECLARE @MaxLen INT =
        (SELECT CHARACTER_MAXIMUM_LENGTH
         FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'Productos' AND COLUMN_NAME = 'Imagen');
      IF @ImageType = 'nvarchar' AND ISNULL(@MaxLen, -1) <> -1
        ALTER TABLE dbo.Productos ALTER COLUMN Imagen NVARCHAR(MAX) NULL;
    END
  `
  const updateQuery = `
    SET NOCOUNT ON;
    UPDATE dbo.Productos SET Imagen = @Imagen WHERE IdProducto = @IdProducto;
  `

  await conn.request().query(ensureQuery).catch(async (err: unknown) => {
    if (!isTypeValidationError(err)) throw err
    await conn.request().query(ensureQuery)
  })

  await conn.request()
    .input("IdProducto", sql.Int, productId)
    .input("Imagen", sql.NVarChar(sql.MAX), value)
    .query(updateQuery)
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      await conn.request()
        .input("IdProducto", productId)
        .input("Imagen", value)
        .query(updateQuery)
    })
}

async function getProductByIdInternal(id: number, pool?: Awaited<ReturnType<typeof getPool>>): Promise<ProductRecord> {
  const conn = pool ?? await getPool()

  const productPromise = conn.request()
    .input("Accion", "O")
    .input("IdProducto", sql.Int, id)
    .execute("dbo.spProductosCRUD")
    .catch(async (err: unknown) => {
      if (isMissingColumnError(err, "Imagen")) {
        return conn.request().input("IdProducto", sql.Int, id).query(`
          SET NOCOUNT ON;
          SELECT TOP 1
            P.IdProducto,
            CAST('' AS NVARCHAR(60)) AS Codigo,
            CAST('' AS NVARCHAR(MAX)) AS Comentario,
            CAST('' AS NVARCHAR(500)) AS Imagen,
            P.IdCategoria,
            P.IdTipoProducto,
            P.IdUnidadMedida,
            P.IdUnidadVenta,
            P.IdUnidadCompra,
            P.IdUnidadAlterna1,
            P.IdUnidadAlterna2,
            P.IdUnidadAlterna3,
            P.Nombre,
            P.Descripcion,
            ISNULL((
              SELECT TOP 1 PP.Precio
              FROM dbo.ProductoPrecios PP
              WHERE PP.IdProducto = P.IdProducto AND PP.RowStatus = 1
              ORDER BY PP.IdListaPrecio
            ), 0) AS Precio,
            P.AplicaImpuesto,
            P.IdTasaImpuesto,
            CAST(0 AS DECIMAL(10,4)) AS TasaImpuesto,
            P.UnidadBaseExistencia,
            P.SeVendeEnFactura,
            P.PermiteDescuento,
            P.PermiteCambioPrecio,
            P.PermitePrecioManual,
            P.PideUnidad,
            P.PideUnidadInventario,
            P.PermiteFraccionesDecimales,
            P.VenderSinExistencia,
            P.AplicaPropina,
            P.ManejaExistencia,
            P.Activo,
            C.Nombre AS Categoria,
            TP.Nombre AS TipoProducto,
            UB.Nombre AS UnidadBase,
            UV.Nombre AS UnidadVenta,
            UC.Nombre AS UnidadCompra
          FROM dbo.Productos P
          LEFT JOIN dbo.Categorias C ON C.IdCategoria = P.IdCategoria
          LEFT JOIN dbo.TiposProducto TP ON TP.IdTipoProducto = P.IdTipoProducto
          LEFT JOIN dbo.UnidadesMedida UB ON UB.IdUnidadMedida = P.IdUnidadMedida
          LEFT JOIN dbo.UnidadesMedida UV ON UV.IdUnidadMedida = P.IdUnidadVenta
          LEFT JOIN dbo.UnidadesMedida UC ON UC.IdUnidadMedida = P.IdUnidadCompra
          WHERE P.IdProducto = @IdProducto AND P.RowStatus = 1;
        `)
      }
      if (!isTypeValidationError(err)) throw err
      return conn.request().input("Accion", "O").input("IdProducto", id).execute("dbo.spProductosCRUD")
    })

  const pricesPromise = conn.request()
    .input("Accion", "G")
    .input("IdProducto", sql.Int, id)
    .execute("dbo.spProductosPreciosCRUD")
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      return conn.request().input("Accion", "G").input("IdProducto", id).execute("dbo.spProductosPreciosCRUD")
    })

  const offerPromise = conn.request()
    .input("Accion", "G")
    .input("IdProducto", sql.Int, id)
    .execute("dbo.spProductosOfertasCRUD")
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      return conn.request().input("Accion", "G").input("IdProducto", id).execute("dbo.spProductosOfertasCRUD")
    })

  const [productResult, pricesResult, offerResult] = await Promise.all([
    productPromise,
    pricesPromise,
    offerPromise,
  ])

  const productRow = (productResult.recordset?.[0] as QueryRow | undefined)
  if (!productRow) throw new Error("Producto no encontrado.")

  const mapped = mapProductRow(productRow)
  mapped.code = await loadProductCode(id, conn)
  mapped.comment = await loadProductComment(id, conn)
  mapped.imagen = await loadProductImage(id, conn)
  mapped.prices = (pricesResult.recordset as QueryRow[]).map((row) => ({
    priceListId: toNumber(row.IdListaPrecio),
    profitPercent: toNumber(row.PorcentajeGanancia),
    price: toNumber(row.Precio),
    tax: toNumber(row.Impuesto),
    priceWithTax: toNumber(row.PrecioConImpuesto),
  }))

  const offerRow = offerResult.recordset?.[0] as QueryRow | undefined
  if (offerRow) {
    mapped.offer = {
      active: Boolean(offerRow.Activo),
      price: toNumber(offerRow.PrecioOferta),
      startDate: toIsoDate(offerRow.FechaInicio),
      endDate: toIsoDate(offerRow.FechaFin),
    }
  }

  return mapped
}

export async function getProductById(id: number): Promise<ProductRecord> {
  return getProductByIdInternal(id)
}

async function upsertProductDetailData(pool: Awaited<ReturnType<typeof getPool>>, productId: number, input: ProductMutationInput, userId: number) {
  const priceRows = input.prices ?? []
  await Promise.all(priceRows.map(async (row) => {
    try {
      await pool.request()
        .input("Accion", "U")
        .input("IdProducto", sql.Int, productId)
        .input("IdListaPrecio", sql.Int, row.priceListId)
        .input("PorcentajeGanancia", sql.Decimal(10, 4), row.profitPercent)
        .input("Precio", sql.Decimal(10, 4), row.price)
        .input("Impuesto", sql.Decimal(10, 4), row.tax)
        .input("PrecioConImpuesto", sql.Decimal(10, 4), row.priceWithTax)
        .input("UsuarioCreacion", sql.Int, userId)
        .input("UsuarioModificacion", sql.Int, userId)
        .execute("dbo.spProductosPreciosCRUD")
    } catch (err) {
      if (!isTypeValidationError(err)) throw err
      await pool.request()
        .input("Accion", "U")
        .input("IdProducto", productId)
        .input("IdListaPrecio", row.priceListId)
        .input("PorcentajeGanancia", row.profitPercent)
        .input("Precio", row.price)
        .input("Impuesto", row.tax)
        .input("PrecioConImpuesto", row.priceWithTax)
        .input("UsuarioCreacion", userId)
        .input("UsuarioModificacion", userId)
        .execute("dbo.spProductosPreciosCRUD")
    }
  }))

  const offer = input.offer ?? { active: false, price: 0, startDate: "", endDate: "" }
  try {
    await pool.request()
      .input("Accion", "U")
      .input("IdProducto", sql.Int, productId)
      .input("Activo", sql.Bit, offer.active)
      .input("PrecioOferta", sql.Decimal(10, 4), offer.price)
      .input("FechaInicio", sql.Date, offer.startDate || null)
      .input("FechaFin", sql.Date, offer.endDate || null)
      .input("UsuarioCreacion", sql.Int, userId)
      .input("UsuarioModificacion", sql.Int, userId)
      .execute("dbo.spProductosOfertasCRUD")
  } catch (err) {
    if (!isTypeValidationError(err)) throw err
    await pool.request()
      .input("Accion", "U")
      .input("IdProducto", productId)
      .input("Activo", offer.active)
      .input("PrecioOferta", offer.price)
      .input("FechaInicio", offer.startDate || null)
      .input("FechaFin", offer.endDate || null)
      .input("UsuarioCreacion", userId)
      .input("UsuarioModificacion", userId)
      .execute("dbo.spProductosOfertasCRUD")
  }
}

export async function createProduct(input: ProductMutationInput): Promise<ProductRecord> {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  let insertResult: { recordset?: QueryRow[] }
  try {
    insertResult = await pool.request()
      .input("Accion", "I")
      .input("IdCategoria", sql.Int, input.categoryId)
      .input("IdTipoProducto", sql.Int, input.typeId)
      .input("IdUnidadMedida", sql.Int, input.unitBaseId)
      .input("IdUnidadVenta", sql.Int, input.unitSaleId)
      .input("IdUnidadCompra", sql.Int, input.unitPurchaseId)
      .input("IdUnidadAlterna1", sql.Int, input.unitAlt1Id ?? null)
      .input("IdUnidadAlterna2", sql.Int, input.unitAlt2Id ?? null)
      .input("IdUnidadAlterna3", sql.Int, input.unitAlt3Id ?? null)
      .input("Nombre", sql.NVarChar(150), input.name)
      .input("Descripcion", sql.NVarChar(250), input.description ?? null)
      .input("AplicaImpuesto", sql.Bit, input.applyTax ?? false)
      .input("IdTasaImpuesto", sql.Int, input.taxRateId ?? null)
      .input("UnidadBaseExistencia", sql.NVarChar(20), "measure")
      .input("SeVendeEnFactura", sql.Bit, input.canSellInBilling ?? true)
      .input("PermiteDescuento", sql.Bit, input.allowDiscount ?? true)
      .input("PermiteCambioPrecio", sql.Bit, input.allowPriceChange ?? true)
      .input("PermitePrecioManual", sql.Bit, input.allowManualPrice ?? true)
      .input("PideUnidad", sql.Bit, input.requestUnit ?? false)
      .input("PideUnidadInventario", sql.Bit, input.requestUnitInventory ?? false)
      .input("PermiteFraccionesDecimales", sql.Bit, input.allowDecimals ?? false)
      .input("VenderSinExistencia", sql.Bit, input.sellWithoutStock ?? true)
      .input("AplicaPropina", sql.Bit, input.applyTip ?? false)
      .input("ManejaExistencia", sql.Bit, input.managesStock ?? true)
      .input("IdMoneda", sql.Int, input.costs?.currencyId ?? null)
      .input("DescuentoProveedor", sql.Decimal(10, 4), input.costs?.providerDiscount ?? 0)
      .input("CostoProveedor", sql.Decimal(10, 4), input.costs?.providerCost ?? 0)
      .input("CostoConImpuesto", sql.Decimal(10, 4), input.costs?.providerCostWithTax ?? 0)
      .input("CostoPromedio", sql.Decimal(10, 4), input.costs?.averageCost ?? 0)
      .input("PermitirCostoManual", sql.Bit, input.costs?.allowManualAvgCost ?? false)
      .input("Activo", sql.Bit, input.active)
      .input("UsuarioCreacion", sql.Int, demoUserId)
      .execute("dbo.spProductosCRUD")
  } catch (err) {
    if (!isTypeValidationError(err)) throw err
    insertResult = await pool.request()
      .input("Accion", "I")
      .input("IdCategoria", input.categoryId)
      .input("IdTipoProducto", input.typeId)
      .input("IdUnidadMedida", input.unitBaseId)
      .input("IdUnidadVenta", input.unitSaleId)
      .input("IdUnidadCompra", input.unitPurchaseId)
      .input("IdUnidadAlterna1", input.unitAlt1Id ?? null)
      .input("IdUnidadAlterna2", input.unitAlt2Id ?? null)
      .input("IdUnidadAlterna3", input.unitAlt3Id ?? null)
      .input("Nombre", input.name)
      .input("Descripcion", input.description ?? null)
      .input("AplicaImpuesto", input.applyTax ?? false)
      .input("IdTasaImpuesto", input.taxRateId ?? null)
      .input("UnidadBaseExistencia", "measure")
      .input("SeVendeEnFactura", input.canSellInBilling ?? true)
      .input("PermiteDescuento", input.allowDiscount ?? true)
      .input("PermiteCambioPrecio", input.allowPriceChange ?? true)
      .input("PermitePrecioManual", input.allowManualPrice ?? true)
      .input("PideUnidad", input.requestUnit ?? false)
      .input("PideUnidadInventario", input.requestUnitInventory ?? false)
      .input("PermiteFraccionesDecimales", input.allowDecimals ?? false)
      .input("VenderSinExistencia", input.sellWithoutStock ?? true)
      .input("AplicaPropina", input.applyTip ?? false)
      .input("ManejaExistencia", input.managesStock ?? true)
      .input("IdMoneda", input.costs?.currencyId ?? null)
      .input("DescuentoProveedor", input.costs?.providerDiscount ?? 0)
      .input("CostoProveedor", input.costs?.providerCost ?? 0)
      .input("CostoConImpuesto", input.costs?.providerCostWithTax ?? 0)
      .input("CostoPromedio", input.costs?.averageCost ?? 0)
      .input("PermitirCostoManual", input.costs?.allowManualAvgCost ?? false)
      .input("Activo", input.active)
      .input("UsuarioCreacion", demoUserId)
      .execute("dbo.spProductosCRUD")
  }

  const createdRow = insertResult.recordset?.[0] as QueryRow | undefined
  const productId = createdRow?.IdProducto != null ? toNumber(createdRow.IdProducto) : 0
  if (!productId) throw new Error("No se pudo determinar el producto creado.")

  await persistProductCode(productId, input.code, pool)
  await persistProductComment(productId, input.comment, pool)
  await persistProductImage(productId, input.imagen, pool)
  await upsertProductDetailData(pool, productId, input, demoUserId)
  return getProductByIdInternal(productId, pool)
}

export async function updateProduct(id: number, input: ProductMutationInput): Promise<ProductRecord> {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    await pool.request()
      .input("Accion", "A")
      .input("IdProducto", sql.Int, id)
      .input("IdCategoria", sql.Int, input.categoryId)
      .input("IdTipoProducto", sql.Int, input.typeId)
      .input("IdUnidadMedida", sql.Int, input.unitBaseId)
      .input("IdUnidadVenta", sql.Int, input.unitSaleId)
      .input("IdUnidadCompra", sql.Int, input.unitPurchaseId)
      .input("IdUnidadAlterna1", sql.Int, input.unitAlt1Id ?? null)
      .input("IdUnidadAlterna2", sql.Int, input.unitAlt2Id ?? null)
      .input("IdUnidadAlterna3", sql.Int, input.unitAlt3Id ?? null)
      .input("Nombre", sql.NVarChar(150), input.name)
      .input("Descripcion", sql.NVarChar(250), input.description ?? null)
      .input("AplicaImpuesto", sql.Bit, input.applyTax ?? false)
      .input("IdTasaImpuesto", sql.Int, input.taxRateId ?? null)
      .input("UnidadBaseExistencia", sql.NVarChar(20), "measure")
      .input("SeVendeEnFactura", sql.Bit, input.canSellInBilling ?? true)
      .input("PermiteDescuento", sql.Bit, input.allowDiscount ?? true)
      .input("PermiteCambioPrecio", sql.Bit, input.allowPriceChange ?? true)
      .input("PermitePrecioManual", sql.Bit, input.allowManualPrice ?? true)
      .input("PideUnidad", sql.Bit, input.requestUnit ?? false)
      .input("PideUnidadInventario", sql.Bit, input.requestUnitInventory ?? false)
      .input("PermiteFraccionesDecimales", sql.Bit, input.allowDecimals ?? false)
      .input("VenderSinExistencia", sql.Bit, input.sellWithoutStock ?? true)
      .input("AplicaPropina", sql.Bit, input.applyTip ?? false)
      .input("ManejaExistencia", sql.Bit, input.managesStock ?? true)
      .input("IdMoneda", sql.Int, input.costs?.currencyId ?? null)
      .input("DescuentoProveedor", sql.Decimal(10, 4), input.costs?.providerDiscount ?? 0)
      .input("CostoProveedor", sql.Decimal(10, 4), input.costs?.providerCost ?? 0)
      .input("CostoConImpuesto", sql.Decimal(10, 4), input.costs?.providerCostWithTax ?? 0)
      .input("CostoPromedio", sql.Decimal(10, 4), input.costs?.averageCost ?? 0)
      .input("PermitirCostoManual", sql.Bit, input.costs?.allowManualAvgCost ?? false)
      .input("Activo", sql.Bit, input.active)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spProductosCRUD")
  } catch (err) {
    if (!isTypeValidationError(err)) throw err
    await pool.request()
      .input("Accion", "A")
      .input("IdProducto", id)
      .input("IdCategoria", input.categoryId)
      .input("IdTipoProducto", input.typeId)
      .input("IdUnidadMedida", input.unitBaseId)
      .input("IdUnidadVenta", input.unitSaleId)
      .input("IdUnidadCompra", input.unitPurchaseId)
      .input("IdUnidadAlterna1", input.unitAlt1Id ?? null)
      .input("IdUnidadAlterna2", input.unitAlt2Id ?? null)
      .input("IdUnidadAlterna3", input.unitAlt3Id ?? null)
      .input("Nombre", input.name)
      .input("Descripcion", input.description ?? null)
      .input("AplicaImpuesto", input.applyTax ?? false)
      .input("IdTasaImpuesto", input.taxRateId ?? null)
      .input("UnidadBaseExistencia", "measure")
      .input("SeVendeEnFactura", input.canSellInBilling ?? true)
      .input("PermiteDescuento", input.allowDiscount ?? true)
      .input("PermiteCambioPrecio", input.allowPriceChange ?? true)
      .input("PermitePrecioManual", input.allowManualPrice ?? true)
      .input("PideUnidad", input.requestUnit ?? false)
      .input("PideUnidadInventario", input.requestUnitInventory ?? false)
      .input("PermiteFraccionesDecimales", input.allowDecimals ?? false)
      .input("VenderSinExistencia", input.sellWithoutStock ?? true)
      .input("AplicaPropina", input.applyTip ?? false)
      .input("ManejaExistencia", input.managesStock ?? true)
      .input("IdMoneda", input.costs?.currencyId ?? null)
      .input("DescuentoProveedor", input.costs?.providerDiscount ?? 0)
      .input("CostoProveedor", input.costs?.providerCost ?? 0)
      .input("CostoConImpuesto", input.costs?.providerCostWithTax ?? 0)
      .input("CostoPromedio", input.costs?.averageCost ?? 0)
      .input("PermitirCostoManual", input.costs?.allowManualAvgCost ?? false)
      .input("Activo", input.active)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spProductosCRUD")
  }

  await persistProductCode(id, input.code, pool)
  await persistProductComment(id, input.comment, pool)
  await persistProductImage(id, input.imagen, pool)
  await upsertProductDetailData(pool, id, input, demoUserId)
  return getProductByIdInternal(id, pool)
}

export async function deleteProduct(id: number) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    await pool
      .request()
      .input("Accion", "D")
      .input("IdProducto", sql.Int, id)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spProductosCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "D")
      .input("IdProducto", id)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spProductosCRUD")
  }
}

type SessionContext = { sessionId?: number; token?: string; userType?: "A" | "S" | "O" }

function applySessionContext(request: import("mssql").Request, session?: SessionContext) {
  request.input("IdSesion", session?.sessionId ?? null)
  request.input("TokenSesion", session?.token ?? null)
}

export async function createResource(input: { categoryId: number; name: string; state: string; seats?: number; active: boolean }, session?: SessionContext) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const payload = {
    categoryId: toNumber(input.categoryId),
    name: toText(input.name),
    state: toText(input.state),
    seats: toNumber(input.seats || 4),
    active: Boolean(input.active),
  }

  try {
    const request = pool
      .request()
      .input("Accion", "I")
      .input("IdCategoriaRecurso", sql.Int, payload.categoryId)
      .input("Nombre", sql.VarChar(100), payload.name)
      .input("Estado", sql.VarChar(20), payload.state)
      .input("CantidadSillas", sql.Int, payload.seats)
      .input("Activo", sql.Bit, payload.active)
      .input("UsuarioCreacion", sql.Int, demoUserId)

    applySessionContext(request, session)
    await request.execute("dbo.spRecursosCRUD")
    return
  } catch (error) {
    if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) {
      throw error
    }

    const fallbackRequest = pool
      .request()
      .input("Accion", "I")
      .input("IdCategoriaRecurso", payload.categoryId)
      .input("Nombre", payload.name)
      .input("Estado", payload.state)
      .input("CantidadSillas", payload.seats)
      .input("Activo", payload.active)
      .input("UsuarioCreacion", demoUserId)

    applySessionContext(fallbackRequest, session)
    await fallbackRequest.execute("dbo.spRecursosCRUD")
  }
}

export async function updateResource(id: number, input: { categoryId: number; name: string; state: string; seats?: number; active: boolean }, session?: SessionContext) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const payload = {
    id: toNumber(id),
    categoryId: toNumber(input.categoryId),
    name: toText(input.name),
    state: toText(input.state),
    seats: toNumber(input.seats || 4),
    active: Boolean(input.active),
  }

  try {
    const request = pool
      .request()
      .input("Accion", "A")
      .input("IdRecurso", sql.Int, payload.id)
      .input("IdCategoriaRecurso", sql.Int, payload.categoryId)
      .input("Nombre", sql.VarChar(100), payload.name)
      .input("Estado", sql.VarChar(20), payload.state)
      .input("CantidadSillas", sql.Int, payload.seats)
      .input("Activo", sql.Bit, payload.active)
      .input("UsuarioModificacion", sql.Int, demoUserId)

    applySessionContext(request, session)
    await request.execute("dbo.spRecursosCRUD")
    return
  } catch (error) {
    if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) {
      throw error
    }

    const fallbackRequest = pool
      .request()
      .input("Accion", "A")
      .input("IdRecurso", payload.id)
      .input("IdCategoriaRecurso", payload.categoryId)
      .input("Nombre", payload.name)
      .input("Estado", payload.state)
      .input("CantidadSillas", payload.seats)
      .input("Activo", payload.active)
      .input("UsuarioModificacion", demoUserId)

    applySessionContext(fallbackRequest, session)
    await fallbackRequest.execute("dbo.spRecursosCRUD")
  }
}

export async function deleteResource(id: number, session?: SessionContext) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const resourceId = toNumber(id)

  try {
    const request = pool
      .request()
      .input("Accion", "D")
      .input("IdRecurso", sql.Int, resourceId)
      .input("UsuarioModificacion", sql.Int, demoUserId)

    applySessionContext(request, session)
    await request.execute("dbo.spRecursosCRUD")
    return
  } catch (error) {
    if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) {
      throw error
    }

    const fallbackRequest = pool
      .request()
      .input("Accion", "D")
      .input("IdRecurso", resourceId)
      .input("UsuarioModificacion", demoUserId)

    applySessionContext(fallbackRequest, session)
    await fallbackRequest.execute("dbo.spRecursosCRUD")
  }
}

export async function generateResourcesFromCategory(
  input: {
    categoryId: number
    prefix: string
    quantity: number
    startAt?: number
    seats?: number
    state?: string
  },
  session?: SessionContext,
) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  const payload = {
    categoryId: toNumber(input.categoryId),
    prefix: toText(input.prefix).trim(),
    quantity: Math.max(1, toNumber(input.quantity)),
    startAt: Math.max(1, toNumber(input.startAt || 1)),
    seats: Math.max(1, toNumber(input.seats || 4)),
    state: toText(input.state || "Libre") || "Libre",
  }

  try {
    const request = pool
      .request()
      .input("IdCategoriaRecurso", sql.Int, payload.categoryId)
      .input("Prefijo", sql.VarChar(40), payload.prefix)
      .input("Cantidad", sql.Int, payload.quantity)
      .input("NumeroInicial", sql.Int, payload.startAt)
      .input("CantidadSillas", sql.Int, payload.seats)
      .input("Estado", sql.VarChar(20), payload.state)
      .input("UsuarioCreacion", sql.Int, demoUserId)

    applySessionContext(request, session)
    await request.execute("dbo.spRecursosGenerarMasivo")
    return
  } catch (error) {
    if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) {
      throw error
    }

    const fallbackRequest = pool
      .request()
      .input("IdCategoriaRecurso", payload.categoryId)
      .input("Prefijo", payload.prefix)
      .input("Cantidad", payload.quantity)
      .input("NumeroInicial", payload.startAt)
      .input("CantidadSillas", payload.seats)
      .input("Estado", payload.state)
      .input("UsuarioCreacion", demoUserId)

    applySessionContext(fallbackRequest, session)
    await fallbackRequest.execute("dbo.spRecursosGenerarMasivo")
  }
}

export async function getCompanySettingsData(): Promise<CompanySettingsData> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "O").execute("dbo.spEmpresaCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined

  if (!row) {
    return {
      fiscalId: "",
      businessName: "",
      tradeName: "",
      address: "",
      city: "",
      stateProvince: "",
      postalCode: "",
      country: "Republica Dominicana",
      phone1: "",
      phone2: "",
      email: "",
      website: "",
      instagram: "",
      facebook: "",
      x: "",
      logoUrl: "",
      hasLogoBinary: false,
      logoUpdatedAt: "",
      currency: "DOP",
      secondaryCurrency: "",
      active: true,
      slogan: "",
      sessionDurationMinutes: 600,
      sessionIdleMinutes: 30,
      applyTax: true,
      taxName: "ITBIS",
      taxPercent: 18,
      applyTip: false,
      tipName: "Propina Legal",
      tipPercent: 10,
      restrictOrdersByUser: false,
      lockTablesByUser: false,
    }
  }

  return {
    id: toNumber(row.IdEmpresa),
    fiscalId: toText(row.IdentificacionFiscal),
    businessName: toText(row.RazonSocial),
    tradeName: toText(row.NombreComercial),
    address: toText(row.Direccion),
    city: toText(row.Ciudad),
    stateProvince: toText(row.ProvinciaEstado),
    postalCode: toText(row.CodigoPostal),
    country: toText(row.Pais, "Republica Dominicana"),
    phone1: toText(row.Telefono1),
    phone2: toText(row.Telefono2),
    email: toText(row.Correo),
    website: toText(row.SitioWeb),
    instagram: toText(row.Instagram),
    facebook: toText(row.Facebook),
    x: toText(row.XTwitter),
    logoUrl: toText(row.LogoUrl),
    hasLogoBinary: Boolean(row.TieneLogo),
    logoUpdatedAt: row.LogoActualizacion ? String(row.LogoActualizacion) : "",
    currency: toText(row.Moneda, "DOP"),
    secondaryCurrency: toText(row.MonedaSecundaria, ""),
    active: Boolean(row.Activo),
    slogan: toText(row.Eslogan, ""),
    sessionDurationMinutes: Math.max(1, toNumber(row.SesionDuracionMinutos) || 600),
    sessionIdleMinutes: Math.max(1, toNumber(row.SesionIdleMinutos) || 30),
    applyTax: Boolean(row.AplicaImpuesto),
    taxName: toText(row.NombreImpuesto, "ITBIS"),
    taxPercent: Number(row.PorcentajeImpuesto ?? 18),
    applyTip: Boolean(row.AplicaPropina),
    tipName: toText(row.NombrePropina, "Propina Legal"),
    tipPercent: Number(row.PorcentajePropina ?? 10),
    restrictOrdersByUser: Boolean(row.RestringirOrdenesPorUsuario),
    lockTablesByUser: Boolean(row.BloquearMesaPorUsuario),
  }
}

export async function saveCompanySettings(input: CompanySettingsData) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  const action = input.id ? "A" : "I"
  const request = pool
    .request()
    .input("Accion", action)
    .input("IdEmpresa", input.id ?? null)
    .input("IdentificacionFiscal", input.fiscalId || null)
    .input("RazonSocial", input.businessName)
    .input("NombreComercial", input.tradeName || null)
    .input("Direccion", input.address || null)
    .input("Ciudad", input.city || null)
    .input("ProvinciaEstado", input.stateProvince || null)
    .input("CodigoPostal", input.postalCode || null)
    .input("Pais", input.country || null)
    .input("Telefono1", input.phone1 || null)
    .input("Telefono2", input.phone2 || null)
    .input("Correo", input.email || null)
    .input("SitioWeb", input.website || null)
    .input("Instagram", input.instagram || null)
    .input("Facebook", input.facebook || null)
    .input("XTwitter", input.x || null)
    .input("LogoUrl", input.logoUrl || null)
    .input("Moneda", input.currency || "DOP")
    .input("MonedaSecundaria", input.secondaryCurrency || null)
    .input("Activo", input.active)
    .input("Eslogan", input.slogan || null)
    .input("SesionDuracionMinutos", input.sessionDurationMinutes ?? 600)
    .input("SesionIdleMinutos", input.sessionIdleMinutes ?? 30)
    .input("AplicaImpuesto", input.applyTax ?? true)
    .input("NombreImpuesto", input.taxName || "ITBIS")
    .input("PorcentajeImpuesto", input.taxPercent ?? 18)
    .input("AplicaPropina", input.applyTip ?? false)
    .input("NombrePropina", input.tipName || "Propina Legal")
    .input("PorcentajePropina", input.tipPercent ?? 10)
    .input("RestringirOrdenesPorUsuario", input.restrictOrdersByUser ?? false)
    .input("BloquearMesaPorUsuario", input.lockTablesByUser ?? false)

  request.input(action === "I" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
  await request.execute("dbo.spEmpresaCRUD")
}

export async function saveCompanyLogoBinary(input: { companyId: number; fileName: string; mimeType: string; fileData: Buffer }) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  await pool
    .request()
    .input("IdEmpresa", input.companyId)
    .input("LogoData", input.fileData)
    .input("LogoMimeType", input.mimeType)
    .input("LogoFileName", input.fileName)
    .input("UsuarioModificacion", demoUserId)
    .execute("dbo.spEmpresaLogoGuardar")
}

export async function removeCompanyLogoBinary(companyId: number) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  await pool
    .request()
    .input("IdEmpresa", companyId)
    .input("UsuarioModificacion", demoUserId)
    .execute("dbo.spEmpresaLogoEliminar")
}

export async function getCompanyBrandingData() {
  const company = await getCompanySettingsData()
  return {
    tradeName: company.tradeName || "Masu POS",
    hasLogoBinary: company.hasLogoBinary,
    logoUrl: company.logoUrl,
    slogan: company.slogan,
  }
}

export async function getCompanyLogoBinary() {
  const pool = await getPool()
  const result = await pool.request().execute("dbo.spEmpresaLogoObtener")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (!row || !row.LogoData) {
    return null
  }

  return {
    mimeType: toText(row.LogoMimeType, "image/png"),
    fileName: toText(row.LogoFileName, "logo.png"),
    updatedAt: row.LogoActualizacion ? String(row.LogoActualizacion) : "",
    data: Buffer.isBuffer(row.LogoData) ? row.LogoData : Buffer.from(row.LogoData as ArrayBuffer),
  }
}

export async function getUserActivity(userId: number, topN = 10) {
  const pool = await getPool()
  const result = await pool
    .request()
    .input("IdUsuario", userId)
    .input("TopN", topN)
    .execute("dbo.spUsuarioActividad")

  const recordsetsRaw = result.recordsets as unknown
  const recordsets = Array.isArray(recordsetsRaw) ? (recordsetsRaw as QueryRow[][]) : []
  const summaryRow = (recordsets[0]?.[0] ?? null) as QueryRow | null
  const sessionsRows = (recordsets[1] ?? []) as QueryRow[]

  return {
    summary: {
      totalSessions: toNumber(summaryRow?.TotalSesiones),
      lastLogin: summaryRow?.UltimoLogin ? String(summaryRow.UltimoLogin) : "",
      accountCreatedAt: summaryRow?.FechaCreacionCuenta ? String(summaryRow.FechaCreacionCuenta) : "",
      accountUpdatedAt: summaryRow?.FechaModificacionCuenta ? String(summaryRow.FechaModificacionCuenta) : "",
    },
    sessions: sessionsRows.map((row) => ({
      id: toNumber(row.IdSesion),
      channel: toText(row.Canal),
      ipAddress: toText(row.IpAddress),
      isActive: Boolean(row.SesionActiva),
      startedAt: row.FechaInicio ? String(row.FechaInicio) : "",
      lastActivityAt: row.FechaUltimaActividad ? String(row.FechaUltimaActividad) : "",
      endedAt: row.FechaCierre ? String(row.FechaCierre) : "",
      durationMinutes: toNumber(row.DuracionMinutos),
    })),
  }
}

export async function getRolePermissionsByModule(roleId: number): Promise<RolePermissionsPayload> {
  const pool = await getPool()
  const result = await pool.request().input("IdRol", roleId).execute("dbo.spRolPermisosPorModulo")

  const recordsetsRaw = result.recordsets as unknown
  const recordsets = Array.isArray(recordsetsRaw) ? (recordsetsRaw as QueryRow[][]) : []

  const modules = (recordsets[0] ?? []).map((row) => ({
    id: toNumber(row.IdModulo),
    name: toText(row.Nombre),
    icon: toText(row.Icono),
    enabled: Boolean(row.Habilitado),
  }))

  const screens = (recordsets[1] ?? []).map((row) => ({
    id: toNumber(row.IdPantalla),
    moduleId: toNumber(row.IdModulo),
    module: toText(row.ModuloNombre || row.Modulo),
    name: toText(row.Pantalla),
    route: toText(row.Ruta),
    access: Boolean(row.AccessEnabled),
    canCreate: Boolean(row.CanCreate),
    canEdit: Boolean(row.CanEdit),
    canDelete: Boolean(row.CanDelete),
    canView: Boolean(row.CanView),
    canApprove: Boolean(row.CanApprove),
    canCancel: Boolean(row.CanCancel),
    canPrint: Boolean(row.CanPrint),
  }))

  const fieldVisibilityRows = recordsets[2] ?? []
  const fieldVisibility: Partial<Record<RoleFieldVisibilityKey, boolean>> = {}
  for (const row of fieldVisibilityRows) {
    const key = toText(row.ClaveCampo) as RoleFieldVisibilityKey
    fieldVisibility[key] = Boolean(row.Visible)
  }

  const modulesWithScreens = modules.map((moduleItem) => ({
    ...moduleItem,
    screens: screens.filter((screen) => screen.moduleId === moduleItem.id),
  }))

  return { modules: modulesWithScreens, screens, fieldVisibility }
}

export async function updateRolePermission(input: {
  roleId: number
  type: "MODULO" | "PANTALLA" | "PERMISO_GRANULAR" | "CAMPO"
  objectId?: number
  fieldKey?: string
  value: boolean
  permissionField?: string
}) {
  const pool = await getPool()
  await pool
    .request()
    .input("IdRol", input.roleId)
    .input("Tipo", input.type)
    .input("IdObjeto", input.objectId ?? null)
    .input("ClaveCampo", input.fieldKey ?? null)
    .input("Valor", input.value)
    .input("CampoPermiso", input.permissionField ?? null)
    .execute("dbo.spRolPermisosActualizar")
}

export async function assignRoleUser(input: { roleId: number; userId: number; action: "A" | "Q" }) {
  const pool = await getPool()
  await pool
    .request()
    .input("IdRol", input.roleId)
    .input("IdUsuario", input.userId)
    .input("Accion", input.action)
    .execute("dbo.spRolUsuariosAsignar")
}

export async function mutateAdminEntity(
  entity: AdminEntityName,
  operation: "create" | "update" | "delete",
  input: Record<string, unknown>,
  session?: SessionContext,
) {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const request = pool.request()

  if (entity === "users") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdUsuario", toNumber(input.id))
    if (operation !== "delete") {
      request.input("IdRol", toNumber(input.roleId))
      request.input("TipoUsuario", toText(input.userType || "O"))
      request.input("IdPantallaInicio", input.startScreenId ? toNumber(input.startScreenId) : null)
      request.input("IdEmpresa", input.companyId ? toNumber(input.companyId) : null)
      request.input("IdDivision", input.divisionId ? toNumber(input.divisionId) : null)
      request.input("IdSucursal", input.branchId ? toNumber(input.branchId) : null)
      request.input("IdPuntoEmision", input.emissionPointId ? toNumber(input.emissionPointId) : null)
      request.input("NivelAcceso", toText(input.dataAccessLevel || "G"))
      request.input("Nombres", toText(input.names))
      request.input("Apellidos", toText(input.surnames))
      request.input("NombreUsuario", toText(input.userName))
      request.input("Correo", toText(input.email) || null)
      request.input("ClaveHash", toText(input.passwordHash) || null)
      request.input("RequiereCambioClave", Boolean(input.mustChangePassword))
      request.input("PuedeEliminarLineaPOS", Boolean(input.canDeletePosLines))
      request.input("PuedeCambiarFechaPOS", Boolean(input.canChangePosDate))
      request.input("Bloqueado", Boolean(input.locked))
      request.input("Activo", Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
    try {
      await request.execute("dbo.spUsuariosCRUD")
    } catch (error) {
      const message = error instanceof Error ? error.message : ""
      if (
        !message.includes("RequiereCambioClave") &&
        !message.includes("Bloqueado") &&
        !message.includes("TipoUsuario") &&
        !message.includes("IdEmpresa") &&
        !message.includes("IdDivision") &&
        !message.includes("IdSucursal") &&
        !message.includes("IdPuntoEmision") &&
        !message.includes("NivelAcceso") &&
        !message.includes("PuedeEliminarLineaPOS") &&
        !message.includes("PuedeCambiarFechaPOS")
      ) {
        throw error
      }

      const legacyRequest = pool.request()
      legacyRequest.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") legacyRequest.input("IdUsuario", toNumber(input.id))
      if (operation !== "delete") {
        legacyRequest.input("IdRol", toNumber(input.roleId))
        legacyRequest.input("IdPantallaInicio", input.startScreenId ? toNumber(input.startScreenId) : null)
        legacyRequest.input("Nombres", toText(input.names))
        legacyRequest.input("Apellidos", toText(input.surnames))
        legacyRequest.input("NombreUsuario", toText(input.userName))
        legacyRequest.input("Correo", toText(input.email) || null)
        legacyRequest.input("ClaveHash", toText(input.passwordHash) || null)
        legacyRequest.input("Activo", Boolean(input.active))
      }
      applySessionContext(legacyRequest, session)
      legacyRequest.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
      await legacyRequest.execute("dbo.spUsuariosCRUD")
    }
    return
  }

  if (entity === "roles") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdRol", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("Nombre", sql.NVarChar(100), toText(input.name))
      request.input("Descripcion", sql.NVarChar(250), toText(input.description) || null)
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    try {
      await request.execute("dbo.spRolesCRUD")
    } catch (error) {
      const message = error instanceof Error ? error.message : ""
      if (!message.includes("parameter.type.validate is not a function")) {
        throw error
      }

      const fallbackRequest = pool.request()
      fallbackRequest.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") fallbackRequest.input("IdRol", toNumber(input.id))
      if (operation !== "delete") {
        fallbackRequest.input("Nombre", toText(input.name))
        fallbackRequest.input("Descripcion", toText(input.description) || null)
        fallbackRequest.input("Activo", Boolean(input.active))
      }
      applySessionContext(fallbackRequest, session)
      fallbackRequest.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
      await fallbackRequest.execute("dbo.spRolesCRUD")
    }
    return
  }

  if (entity === "modules") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdModulo", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("Nombre", sql.NVarChar(100), toText(input.name))
      request.input("Icono", sql.NVarChar(100), toText(input.icon) || null)
      request.input("Orden", sql.Int, toNumber(input.order))
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spModulosCRUD")
    return
  }

  if (entity === "screens") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdPantalla", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("IdModulo", sql.Int, toNumber(input.moduleId))
      request.input("Nombre", sql.NVarChar(100), toText(input.name))
      request.input("Ruta", sql.NVarChar(200), toText(input.route) || null)
      request.input("Controlador", sql.NVarChar(100), toText(input.controller) || null)
      request.input("AccionNombre", sql.NVarChar(100), toText(input.actionName || input.action) || null)
      request.input("Icono", sql.NVarChar(100), toText(input.icon) || null)
      request.input("Orden", sql.Int, toNumber(input.order))
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spPantallasCRUD")
    return
  }

  if (entity === "permissions") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdPermiso", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("IdPantalla", sql.Int, toNumber(input.screenId))
      request.input("Nombre", sql.NVarChar(150), toText(input.name))
      request.input("Descripcion", sql.NVarChar(250), toText(input.description) || null)
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spPermisosCRUD")
    return
  }

  if (entity === "role-permissions") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdRolPermiso", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("IdRol", sql.Int, toNumber(input.roleId))
      request.input("IdPermiso", sql.Int, toNumber(input.permissionId))
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spRolesPermisosCRUD")
    return
  }

  if (entity === "categories") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdCategoria", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("Nombre", sql.NVarChar(100), toText(input.name))
      request.input("Descripcion", sql.NVarChar(250), toText(input.description) || null)
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spCategoriasCRUD")
    return
  }

  if (entity === "product-types") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdTipoProducto", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("Nombre", sql.NVarChar(100), toText(input.name))
      request.input("Descripcion", sql.NVarChar(250), toText(input.description) || null)
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spTiposProductoCRUD")
    return
  }

  if (entity === "units") {
    request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
    if (operation !== "create") request.input("IdUnidadMedida", sql.Int, toNumber(input.id))
    if (operation !== "delete") {
      request.input("Nombre", sql.NVarChar(100), toText(input.name))
      request.input("Abreviatura", sql.NVarChar(20), toText(input.abbreviation))
      request.input("BaseA", sql.Int, toNumber(input.baseA))
      request.input("BaseB", sql.Int, toNumber(input.baseB))
      request.input("Activo", sql.Bit, Boolean(input.active))
    }
    applySessionContext(request, session)
    request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
    await request.execute("dbo.spUnidadesMedidaCRUD")
    return
  }

  if (entity === "areas") {
    try {
      request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") request.input("IdArea", sql.Int, toNumber(input.id))
      if (operation !== "delete") {
        request.input("Nombre", sql.VarChar(100), toText(input.name))
        request.input("Descripcion", sql.VarChar(250), toText(input.description) || null)
        request.input("Orden", sql.Int, toNumber(input.order))
        request.input("Activo", sql.Bit, Boolean(input.active))
      }
      applySessionContext(request, session)
      request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
      await request.execute("dbo.spAreasCRUD")
    } catch (error) {
      if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) throw error
      const fallbackRequest = pool.request()
      fallbackRequest.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") fallbackRequest.input("IdArea", toNumber(input.id))
      if (operation !== "delete") {
        fallbackRequest.input("Nombre", toText(input.name))
        fallbackRequest.input("Descripcion", toText(input.description) || null)
        fallbackRequest.input("Orden", toNumber(input.order))
        fallbackRequest.input("Activo", Boolean(input.active))
      }
      applySessionContext(fallbackRequest, session)
      fallbackRequest.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
      await fallbackRequest.execute("dbo.spAreasCRUD")
    }
    return
  }

  if (entity === "resource-types") {
    try {
      request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") request.input("IdTipoRecurso", sql.Int, toNumber(input.id))
      if (operation !== "delete") {
        request.input("Nombre", sql.VarChar(100), toText(input.name))
        request.input("Descripcion", sql.VarChar(250), toText(input.description) || null)
        request.input("Activo", sql.Bit, Boolean(input.active))
      }
      request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
      await request.execute("dbo.spTiposRecursoCRUD")
    } catch (error) {
      if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) throw error
      const fallbackRequest = pool.request()
      fallbackRequest.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") fallbackRequest.input("IdTipoRecurso", toNumber(input.id))
      if (operation !== "delete") {
        fallbackRequest.input("Nombre", toText(input.name))
        fallbackRequest.input("Descripcion", toText(input.description) || null)
        fallbackRequest.input("Activo", Boolean(input.active))
      }
      fallbackRequest.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
      await fallbackRequest.execute("dbo.spTiposRecursoCRUD")
    }
    return
  }

  if (entity === "resource-categories") {
    try {
      request.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") request.input("IdCategoriaRecurso", sql.Int, toNumber(input.id))
      if (operation !== "delete") {
        request.input("IdTipoRecurso", sql.Int, toNumber(input.typeId))
        request.input("IdArea", sql.Int, toNumber(input.areaId))
        request.input("Nombre", sql.VarChar(100), toText(input.name))
        request.input("Descripcion", sql.VarChar(250), toText(input.description) || null)
        request.input("ColorTema", sql.NVarChar(7), toText(input.color) || "#3b82f6")
        request.input("FormaVisual", sql.VarChar(20), toText(input.shape) || "square")
        request.input("Activo", sql.Bit, Boolean(input.active))
      }
      request.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, demoUserId)
      await request.execute("dbo.spCategoriasRecursoCRUD")
    } catch (error) {
      if (!(error instanceof Error && error.message.includes("parameter.type.validate is not a function"))) throw error
      const fallbackRequest = pool.request()
      fallbackRequest.input("Accion", operation === "create" ? "I" : operation === "update" ? "A" : "D")
      if (operation !== "create") fallbackRequest.input("IdCategoriaRecurso", toNumber(input.id))
      if (operation !== "delete") {
        fallbackRequest.input("IdTipoRecurso", toNumber(input.typeId))
        fallbackRequest.input("IdArea", toNumber(input.areaId))
        fallbackRequest.input("Nombre", toText(input.name))
        fallbackRequest.input("Descripcion", toText(input.description) || null)
        fallbackRequest.input("ColorTema", toText(input.color) || "#3b82f6")
        fallbackRequest.input("FormaVisual", toText(input.shape) || "square")
        fallbackRequest.input("Activo", Boolean(input.active))
      }
      fallbackRequest.input(operation === "create" ? "UsuarioCreacion" : "UsuarioModificacion", demoUserId)
      await fallbackRequest.execute("dbo.spCategoriasRecursoCRUD")
    }
    return
  }
}

// ─── Listas de Precios ────────────────────────────────────────────────────────

function mapPriceListRow(row: QueryRow): PriceListRecord {
  const parseDate = (value: unknown): string => {
    if (value == null) return ""
    if (value instanceof Date) {
      const y = value.getFullYear()
      const m = String(value.getMonth() + 1).padStart(2, "0")
      const d = String(value.getDate()).padStart(2, "0")
      return `${y}-${m}-${d}`
    }
    if (typeof value === "string") return value.slice(0, 10)
    return String(value).slice(0, 10)
  }
  return {
    id: toNumber(row.IdListaPrecio),
    code: toText(row.Codigo),
    description: toText(row.Descripcion),
    abbreviation: toText(row.Abreviatura),
    currencyId: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    startDate: parseDate(row.FechaInicio),
    endDate: parseDate(row.FechaFin),
    active: Boolean(row.Activo),
    totalUsers: toNumber(row.TotalUsuarios),
  }
}

export async function getPriceLists(): Promise<PriceListRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spListasPreciosCRUD")
  return (result.recordset as QueryRow[]).map(mapPriceListRow)
}

export type PriceListWithProductPrice = {
  id: number
  code: string
  description: string
  abbreviation: string
  price: number | null
}

export async function getPriceListsForUser(userId: number, productId?: number): Promise<PriceListWithProductPrice[]> {
  const pool = await getPool()
  const result = await pool.request().query<QueryRow>(`
    SELECT
      LP.IdListaPrecio,
      LP.Codigo,
      LP.Descripcion,
      LP.Abreviatura,
      ${productId ? `(SELECT TOP 1 PP.Precio FROM dbo.ProductoPrecios PP WHERE PP.IdListaPrecio = LP.IdListaPrecio AND PP.IdProducto = ${Number(productId)} AND PP.RowStatus = 1) AS Precio` : "NULL AS Precio"}
    FROM dbo.ListasPrecios LP
    WHERE LP.RowStatus = 1
      AND LP.Activo = 1
      AND (
        -- Sin usuarios asignados = disponible para todos
        NOT EXISTS (SELECT 1 FROM dbo.ListaPrecioUsuarios LU WHERE LU.IdListaPrecio = LP.IdListaPrecio AND LU.RowStatus = 1)
        OR
        -- Usuario está asignado
        EXISTS (SELECT 1 FROM dbo.ListaPrecioUsuarios LU WHERE LU.IdListaPrecio = LP.IdListaPrecio AND LU.IdUsuario = ${Number(userId)} AND LU.RowStatus = 1)
      )
    ORDER BY LP.Codigo
  `)
  return (result.recordset as QueryRow[]).map((row) => ({
    id: toNumber(row.IdListaPrecio),
    code: toText(row.Codigo),
    description: toText(row.Descripcion),
    abbreviation: toText(row.Abreviatura),
    price: row.Precio != null ? toNumber(row.Precio) : null,
  }))
}

export async function getPricesByList(listId: number): Promise<{ productId: number; price: number }[]> {
  const pool = await getPool()
  const result = await pool.request().query<QueryRow>(`
    SELECT PP.IdProducto, PP.Precio
    FROM dbo.ProductoPrecios PP
    WHERE PP.IdListaPrecio = ${Number(listId)} AND PP.RowStatus = 1
  `)
  return (result.recordset as QueryRow[]).map((row) => ({
    productId: toNumber(row.IdProducto),
    price: toNumber(row.Precio),
  }))
}

export async function createPriceList(input: {
  code?: string
  description?: string
  abbreviation?: string
  currencyId?: number | null
  startDate?: string
  endDate?: string
  active?: boolean
}): Promise<PriceListRecord> {
  if (!(input.code || "").trim()) throw new Error("createPriceList: codigo requerido")
  if (!(input.description || "").trim()) throw new Error("createPriceList: descripcion requerida")
  if (!input.startDate?.trim()) throw new Error("createPriceList: fecha de inicio requerida")
  if (!input.endDate?.trim()) throw new Error("createPriceList: fecha de fin requerida")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const startDate = new Date(input.startDate.trim() + "T00:00:00")
  const endDate = new Date(input.endDate.trim() + "T00:00:00")
  try {
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("Codigo", sql.NVarChar(20), (input.code || "").trim())
      .input("Descripcion", sql.NVarChar(200), (input.description || "").trim())
      .input("Abreviatura", sql.NVarChar(10), (input.abbreviation || "").trim() || null)
      .input("IdMoneda", sql.Int, input.currencyId ?? null)
      .input("FechaInicio", sql.Date, startDate)
      .input("FechaFin", sql.Date, endDate)
      .input("Activo", sql.Bit, input.active ?? true)
      .input("UsuarioCreacion", sql.Int, demoUserId)
      .execute("dbo.spListasPreciosCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("createPriceList: el SP no devolvio resultado")
    return mapPriceListRow(row)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("Codigo", (input.code || "").trim())
      .input("Descripcion", (input.description || "").trim())
      .input("Abreviatura", (input.abbreviation || "").trim() || null)
      .input("IdMoneda", input.currencyId ?? null)
      .input("FechaInicio", startDate)
      .input("FechaFin", endDate)
      .input("Activo", input.active ?? true)
      .input("UsuarioCreacion", demoUserId)
      .execute("dbo.spListasPreciosCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("createPriceList: el SP no devolvio resultado")
    return mapPriceListRow(row)
  }
}

export async function updatePriceList(
  id: number,
  input: {
    code?: string
    description: string
    abbreviation?: string
    currencyId?: number | null
    startDate?: string
    endDate?: string
    active?: boolean
  },
): Promise<PriceListRecord> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`updatePriceList: id invalido = ${id}`)
  if (!input.description?.trim()) throw new Error("updatePriceList: descripcion requerida")
  if (!input.startDate?.trim()) throw new Error("updatePriceList: fecha de inicio requerida")
  if (!input.endDate?.trim()) throw new Error("updatePriceList: fecha de fin requerida")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const startDate = new Date(input.startDate.trim() + "T00:00:00")
  const endDate = new Date(input.endDate.trim() + "T00:00:00")
  try {
    const result = await pool
      .request()
      .input("Accion", "A")
      .input("IdListaPrecio", sql.Int, id)
      .input("Codigo", sql.NVarChar(20), (input.code || "").trim() || null)
      .input("Descripcion", sql.NVarChar(200), input.description.trim())
      .input("Abreviatura", sql.NVarChar(10), (input.abbreviation || "").trim() || null)
      .input("IdMoneda", sql.Int, input.currencyId ?? null)
      .input("FechaInicio", sql.Date, startDate)
      .input("FechaFin", sql.Date, endDate)
      .input("Activo", sql.Bit, input.active ?? true)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spListasPreciosCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("updatePriceList: el SP no devolvio resultado")
    return mapPriceListRow(row)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "A")
      .input("IdListaPrecio", id)
      .input("Codigo", (input.code || "").trim() || null)
      .input("Descripcion", input.description.trim())
      .input("Abreviatura", (input.abbreviation || "").trim() || null)
      .input("IdMoneda", input.currencyId ?? null)
      .input("FechaInicio", startDate)
      .input("FechaFin", endDate)
      .input("Activo", input.active ?? true)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spListasPreciosCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("updatePriceList: el SP no devolvio resultado")
    return mapPriceListRow(row)
  }
}

export async function deletePriceList(id: number): Promise<void> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`deletePriceList: id invalido = ${id}`)
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    await pool
      .request()
      .input("Accion", "D")
      .input("IdListaPrecio", sql.Int, id)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spListasPreciosCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "D")
      .input("IdListaPrecio", id)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spListasPreciosCRUD")
  }
}

function mapProductTypeRow(row: QueryRow): ProductTypeRecord {
  return {
    id: toNumber(row.IdTipoProducto),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    active: Boolean(row.Activo),
    fechaCreacion: row.FechaCreacion ? String(row.FechaCreacion) : null,
  }
}

export async function getProductTypes(): Promise<ProductTypeRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spTiposProductoCRUD")
  return (result.recordset as QueryRow[]).map(mapProductTypeRow)
}

export async function createProductType(input: {
  name: string
  description?: string
  active?: boolean
}): Promise<ProductTypeRecord> {
  if (!input.name?.trim()) throw new Error("createProductType: nombre requerido")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("Nombre", sql.NVarChar(100), input.name.trim())
      .input("Descripcion", sql.NVarChar(500), input.description?.trim() || null)
      .input("Activo", sql.Bit, input.active ?? true)
      .input("UsuarioCreacion", sql.Int, demoUserId)
      .execute("dbo.spTiposProductoCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("createProductType: el SP no devolvio resultado")
    return mapProductTypeRow(row)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("Nombre", input.name.trim())
      .input("Descripcion", input.description?.trim() || null)
      .input("Activo", input.active ?? true)
      .input("UsuarioCreacion", demoUserId)
      .execute("dbo.spTiposProductoCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("createProductType: el SP no devolvio resultado")
    return mapProductTypeRow(row)
  }
}

export async function updateProductType(
  id: number,
  input: {
    name: string
    description?: string
    active?: boolean
  },
): Promise<ProductTypeRecord> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`updateProductType: id invalido = ${id}`)
  if (!input.name?.trim()) throw new Error("updateProductType: nombre requerido")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    const result = await pool
      .request()
      .input("Accion", "A")
      .input("IdTipoProducto", sql.Int, id)
      .input("Nombre", sql.NVarChar(100), input.name.trim())
      .input("Descripcion", sql.NVarChar(500), input.description?.trim() || null)
      .input("Activo", sql.Bit, input.active ?? true)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spTiposProductoCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("updateProductType: el SP no devolvio resultado")
    return mapProductTypeRow(row)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "A")
      .input("IdTipoProducto", id)
      .input("Nombre", input.name.trim())
      .input("Descripcion", input.description?.trim() || null)
      .input("Activo", input.active ?? true)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spTiposProductoCRUD")
    const row = result.recordset?.[0] as QueryRow | undefined
    if (!row) throw new Error("updateProductType: el SP no devolvio resultado")
    return mapProductTypeRow(row)
  }
}

export async function deleteProductType(id: number): Promise<void> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`deleteProductType: id invalido = ${id}`)
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    await pool
      .request()
      .input("Accion", "D")
      .input("IdTipoProducto", sql.Int, id)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spTiposProductoCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "D")
      .input("IdTipoProducto", id)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spTiposProductoCRUD")
  }
}

function mapUserRow(row: QueryRow): PriceListUser {
  return {
    id: toNumber(row.IdUsuario),
    userName: toText(row.NombreUsuario),
    names: toText(row.Nombres),
    surnames: toText(row.Apellidos),
  }
}

export async function getPriceListUsers(id: number): Promise<{ assigned: PriceListUser[]; available: PriceListUser[] }> {
  const pool = await getPool()
  try {
    const [ra, rd] = await Promise.all([
      pool.request().input("Accion", "LA").input("IdListaPrecio", sql.Int, id).execute("dbo.spListaPrecioUsuarios"),
      pool.request().input("Accion", "LD").input("IdListaPrecio", sql.Int, id).execute("dbo.spListaPrecioUsuarios"),
    ])
    return {
      assigned: (ra.recordset as QueryRow[]).map(mapUserRow),
      available: (rd.recordset as QueryRow[]).map(mapUserRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const [ra, rd] = await Promise.all([
      pool.request().input("Accion", "LA").input("IdListaPrecio", id).execute("dbo.spListaPrecioUsuarios"),
      pool.request().input("Accion", "LD").input("IdListaPrecio", id).execute("dbo.spListaPrecioUsuarios"),
    ])
    return {
      assigned: (ra.recordset as QueryRow[]).map(mapUserRow),
      available: (rd.recordset as QueryRow[]).map(mapUserRow),
    }
  }
}

export async function assignPriceListUser(
  priceListId: number,
  userId: number,
): Promise<{ assigned: PriceListUser[]; available: PriceListUser[] }> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "A")
      .input("IdListaPrecio", sql.Int, priceListId)
      .input("IdUsuario", sql.Int, userId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "A")
      .input("IdListaPrecio", priceListId)
      .input("IdUsuario", userId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  }
}

export async function removePriceListUser(
  priceListId: number,
  userId: number,
): Promise<{ assigned: PriceListUser[]; available: PriceListUser[] }> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "Q")
      .input("IdListaPrecio", sql.Int, priceListId)
      .input("IdUsuario", sql.Int, userId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "Q")
      .input("IdListaPrecio", priceListId)
      .input("IdUsuario", userId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  }
}

export async function assignAllPriceListUsers(priceListId: number): Promise<{ assigned: PriceListUser[]; available: PriceListUser[] }> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "AA")
      .input("IdListaPrecio", sql.Int, priceListId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "AA")
      .input("IdListaPrecio", priceListId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  }
}

export async function removeAllPriceListUsers(priceListId: number): Promise<{ assigned: PriceListUser[]; available: PriceListUser[] }> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "QA")
      .input("IdListaPrecio", sql.Int, priceListId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "QA")
      .input("IdListaPrecio", priceListId)
      .execute("dbo.spListaPrecioUsuarios")
    const sets = result.recordsets as unknown as QueryRow[][]
    return {
      assigned: (sets[0] ?? []).map(mapUserRow),
      available: (sets[1] ?? []).map(mapUserRow),
    }
  }
}

function mapCurrencyRow(row: QueryRow): CurrencyRecord {
  const parseDate = (value: unknown): string => {
    if (value == null) return ""
    if (value instanceof Date) {
      const y = value.getFullYear()
      const m = String(value.getMonth() + 1).padStart(2, "0")
      const d = String(value.getDate()).padStart(2, "0")
      return `${y}-${m}-${d}`
    }
    if (typeof value === "string") return value.slice(0, 10)
    return String(value).slice(0, 10)
  }
  return {
    id: toNumber(row.IdMoneda),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    symbol: toText(row.Simbolo),
    symbolAlt: toText(row.SimboloAlt),
    isLocal: Boolean(row.EsLocal),
    bankCode: toText(row.CodigoBanco),
    factorConversionLocal: toNumber(row.FactorConversionLocal),
    factorConversionUSD: toNumber(row.FactorConversionUSD),
    showInPOS: Boolean(row.MostrarEnPOS),
    acceptPayments: Boolean(row.AceptaPagos),
    decimalPOS: toNumber(row.DecimalesPOS),
    active: Boolean(row.Activo),
    lastRateDate: parseDate(row.UltimaFechaTasa),
    rateAdministrative: row.TasaAdministrativa != null ? toNumber(row.TasaAdministrativa) : null,
    rateOperative: row.TasaOperativa != null ? toNumber(row.TasaOperativa) : null,
    ratePurchase: row.TasaCompra != null ? toNumber(row.TasaCompra) : null,
    rateSale: row.TasaVenta != null ? toNumber(row.TasaVenta) : null,
  }
}

function mapHistoryRow(row: QueryRow): CurrencyHistoryRecord {
  const parseDate = (value: unknown): string => {
    if (value == null) return ""
    if (value instanceof Date) {
      const y = value.getFullYear()
      const m = String(value.getMonth() + 1).padStart(2, "0")
      const d = String(value.getDate()).padStart(2, "0")
      return `${y}-${m}-${d}`
    }
    if (typeof value === "string") return value.slice(0, 10)
    return String(value).slice(0, 10)
  }
  return {
    id: toNumber(row.IdTasa),
    currencyId: toNumber(row.IdMoneda),
    currencyCode: toText(row.CodigoMoneda),
    currencyName: toText(row.NombreMoneda),
    symbol: toText(row.Simbolo),
    date: parseDate(row.Fecha),
    rateAdministrative: row.TasaAdministrativa != null ? toNumber(row.TasaAdministrativa) : null,
    rateOperative: row.TasaOperativa != null ? toNumber(row.TasaOperativa) : null,
    ratePurchase: row.TasaCompra != null ? toNumber(row.TasaCompra) : null,
    rateSale: row.TasaVenta != null ? toNumber(row.TasaVenta) : null,
    userName: toText(row.UsuarioRegistro),
    registrationDate: parseDate(row.FechaRegistro),
    totalRecords: toNumber(row.TotalRegistros),
    totalPages: toNumber(row.TotalPaginas),
    currentPage: toNumber(row.PaginaActual),
  }
}

export async function getCurrencies(): Promise<CurrencyRecord[]> {
  const pool = await getPool()
  try {
    const result = await pool.request().input("Accion", "L").execute("dbo.spMonedasCRUD")
    return (result.recordset as QueryRow[]).map(mapCurrencyRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request().input("Accion", "L").execute("dbo.spMonedasCRUD")
    return (result.recordset as QueryRow[]).map(mapCurrencyRow)
  }
}

export async function updateCurrency(
  id: number,
  input: Partial<{
    name: string
    symbol: string | null
    symbolAlt: string | null
    bankCode: string | null
    factorConversionLocal: number
    factorConversionUSD: number
    showInPOS: boolean
    acceptPayments: boolean
    decimalPOS: number
    active: boolean
  }>,
): Promise<void> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`updateCurrency: id invalido = ${id}`)
  if (!input.name?.trim()) throw new Error("updateCurrency: nombre requerido")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    await pool
      .request()
      .input("Accion", "A")
      .input("IdMoneda", sql.Int, id)
      .input("Nombre", sql.NVarChar(100), input.name.trim())
      .input("Simbolo", sql.NVarChar(10), (input.symbol || "").trim() || null)
      .input("SimboloAlt", sql.NVarChar(10), (input.symbolAlt || "").trim() || null)
      .input("CodigoBanco", sql.NVarChar(20), (input.bankCode || "").trim() || null)
      .input("FactorConversionLocal", sql.Decimal(18, 6), input.factorConversionLocal ?? 1)
      .input("FactorConversionUSD", sql.Decimal(18, 6), input.factorConversionUSD ?? 1)
      .input("MostrarEnPOS", sql.Bit, input.showInPOS ?? true)
      .input("AceptaPagos", sql.Bit, input.acceptPayments ?? true)
      .input("DecimalesPOS", sql.Int, input.decimalPOS ?? 2)
      .input("Activo", sql.Bit, input.active ?? true)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spMonedasCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "A")
      .input("IdMoneda", id)
      .input("Nombre", input.name.trim())
      .input("Simbolo", (input.symbol || "").trim() || null)
      .input("SimboloAlt", (input.symbolAlt || "").trim() || null)
      .input("CodigoBanco", (input.bankCode || "").trim() || null)
      .input("FactorConversionLocal", input.factorConversionLocal ?? 1)
      .input("FactorConversionUSD", input.factorConversionUSD ?? 1)
      .input("MostrarEnPOS", input.showInPOS ?? true)
      .input("AceptaPagos", input.acceptPayments ?? true)
      .input("DecimalesPOS", input.decimalPOS ?? 2)
      .input("Activo", input.active ?? true)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spMonedasCRUD")
  }
}

export async function createCurrency(input: {
  code: string
  name: string
  symbol?: string | null
  symbolAlt?: string | null
  bankCode?: string | null
  factorConversionLocal?: number
  factorConversionUSD?: number
  showInPOS?: boolean
  acceptPayments?: boolean
  decimalPOS?: number
}): Promise<number> {
  if (!input.code?.trim()) throw new Error("createCurrency: codigo requerido")
  if (!input.name?.trim()) throw new Error("createCurrency: nombre requerido")

  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("Codigo", sql.NVarChar(5), input.code.trim().toUpperCase())
      .input("Nombre", sql.NVarChar(100), input.name.trim())
      .input("Simbolo", sql.NVarChar(10), (input.symbol || "").trim() || null)
      .input("SimboloAlt", sql.NVarChar(10), (input.symbolAlt || "").trim() || null)
      .input("CodigoBanco", sql.NVarChar(20), (input.bankCode || "").trim() || null)
      .input("FactorConversionLocal", sql.Decimal(18, 6), input.factorConversionLocal ?? 1)
      .input("FactorConversionUSD", sql.Decimal(18, 6), input.factorConversionUSD ?? 1)
      .input("MostrarEnPOS", sql.Bit, input.showInPOS ?? true)
      .input("AceptaPagos", sql.Bit, input.acceptPayments ?? true)
      .input("DecimalesPOS", sql.Int, input.decimalPOS ?? 2)
      .execute("dbo.spMonedasCRUD")
    return Number(result.recordset[0]?.IdMoneda ?? 0)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("Codigo", input.code.trim().toUpperCase())
      .input("Nombre", input.name.trim())
      .input("Simbolo", (input.symbol || "").trim() || null)
      .input("SimboloAlt", (input.symbolAlt || "").trim() || null)
      .input("CodigoBanco", (input.bankCode || "").trim() || null)
      .input("FactorConversionLocal", input.factorConversionLocal ?? 1)
      .input("FactorConversionUSD", input.factorConversionUSD ?? 1)
      .input("MostrarEnPOS", input.showInPOS ?? true)
      .input("AceptaPagos", input.acceptPayments ?? true)
      .input("DecimalesPOS", input.decimalPOS ?? 2)
      .execute("dbo.spMonedasCRUD")
    return Number(result.recordset[0]?.IdMoneda ?? 0)
  }
}

export async function deleteCurrency(id: number): Promise<void> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`deleteCurrency: id invalido = ${id}`)
  const pool = await getPool()
  try {
    await pool.request().input("Accion", "D").input("IdMoneda", sql.Int, id).execute("dbo.spMonedasCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool.request().input("Accion", "D").input("IdMoneda", id).execute("dbo.spMonedasCRUD")
  }
}

export async function saveCurrencyRate(input: {
  currencyId: number
  date: string
  administrativeRate?: number
  operativeRate?: number
  purchaseRate?: number
  saleRate?: number
}): Promise<CurrencyRecord> {
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const rateDate = new Date(input.date + "T00:00:00")
  try {
    const result = await pool
      .request()
      .input("IdMoneda", sql.Int, input.currencyId)
      .input("Fecha", sql.Date, rateDate)
      .input("TasaAdministrativa", sql.Decimal(18, 6), input.administrativeRate ?? null)
      .input("TasaOperativa", sql.Decimal(18, 6), input.operativeRate ?? null)
      .input("TasaCompra", sql.Decimal(18, 6), input.purchaseRate ?? null)
      .input("TasaVenta", sql.Decimal(18, 6), input.saleRate ?? null)
      .input("IdUsuario", sql.Int, demoUserId)
      .execute("dbo.spMonedaTasasGuardar")
    const row = result.recordset?.[0] as (QueryRow & { IdMoneda: number; Codigo: string; Nombre: string; UltimaFechaTasa: string; TasaAdministrativa: number; TasaOperativa: number; TasaCompra: number; TasaVenta: number }) | undefined
    if (!row) throw new Error("saveCurrencyRate: el SP no devolvio resultado")
    return mapCurrencyRow(row)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("IdMoneda", input.currencyId)
      .input("Fecha", rateDate)
      .input("TasaAdministrativa", input.administrativeRate ?? null)
      .input("TasaOperativa", input.operativeRate ?? null)
      .input("TasaCompra", input.purchaseRate ?? null)
      .input("TasaVenta", input.saleRate ?? null)
      .input("IdUsuario", demoUserId)
      .execute("dbo.spMonedaTasasGuardar")
    const row = result.recordset?.[0] as (QueryRow & { IdMoneda: number; Codigo: string; Nombre: string; UltimaFechaTasa: string; TasaAdministrativa: number; TasaOperativa: number; TasaCompra: number; TasaVenta: number }) | undefined
    if (!row) throw new Error("saveCurrencyRate: el SP no devolvio resultado")
    return mapCurrencyRow(row)
  }
}

export async function getCurrencyHistory(input: {
  currencyId?: number
  dateFrom?: string
  dateTo?: string
  page?: number
}): Promise<CurrencyHistoryRecord[]> {
  const pool = await getPool()
  const page = input.page ?? 1
  const dateFrom = input.dateFrom ? new Date(input.dateFrom + "T00:00:00") : null
  const dateTo = input.dateTo ? new Date(input.dateTo + "T00:00:00") : null
  try {
    const req = pool.request()
      .input("Pagina", sql.Int, page)
      .input("TamanoPagina", sql.Int, 50)
    if (input.currencyId != null) req.input("IdMoneda", sql.Int, input.currencyId)
    if (dateFrom) req.input("FechaDesde", sql.Date, dateFrom)
    if (dateTo) req.input("FechaHasta", sql.Date, dateTo)
    const result = await req.execute("dbo.spMonedaTasasHistorial")
    return (result.recordset as QueryRow[]).map(mapHistoryRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request()
      .input("Pagina", page)
      .input("TamanoPagina", 50)
    if (input.currencyId != null) req.input("IdMoneda", input.currencyId)
    if (dateFrom) req.input("FechaDesde", dateFrom)
    if (dateTo) req.input("FechaHasta", dateTo)
    const result = await req.execute("dbo.spMonedaTasasHistorial")
    return (result.recordset as QueryRow[]).map(mapHistoryRow)
  }
}

// --- Units CRUD ---
function mapUnitRow(row: QueryRow): UnitRecord {
  return {
    id: toNumber(row.IdUnidadMedida),
    name: toText(row.Nombre),
    abbreviation: toText(row.Abreviatura),
    baseA: toNumber(row.BaseA ?? 1),
    baseB: toNumber(row.BaseB ?? 1),
    factor: toNumber(row.UnidadesCalculadas ?? row.Factor ?? 1),
    active: Boolean(row.Activo),
  }
}

export async function getUnits(): Promise<UnitRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spUnidadesMedidaCRUD")
  return (result.recordset as QueryRow[]).map(mapUnitRow)
}

async function runUnitMutate(
  pool: Awaited<ReturnType<typeof getPool>>,
  params: Record<string, unknown>,
): Promise<QueryRow | undefined> {
  const { accion, id, name, abbreviation, baseA, baseB, active, userId } = params
  try {
    const req = pool.request().input("Accion", accion as string)
    if (id != null) req.input("IdUnidadMedida", sql.Int, id as number)
    if (accion !== "D") {
      req.input("Nombre", sql.NVarChar(100), name as string)
      req.input("Abreviatura", sql.NVarChar(20), abbreviation as string)
      req.input("BaseA", sql.Int, (baseA as number) ?? 1)
      req.input("BaseB", sql.Int, (baseB as number) ?? 1)
      req.input("Activo", sql.Bit, active as boolean)
    }
    req.input(accion === "I" ? "UsuarioCreacion" : "UsuarioModificacion", sql.Int, userId as number)
    const result = await req.execute("dbo.spUnidadesMedidaCRUD")
    return result.recordset?.[0] as QueryRow | undefined
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req2 = pool.request().input("Accion", accion as string)
    if (id != null) req2.input("IdUnidadMedida", id as number)
    if (accion !== "D") {
      req2.input("Nombre", name as string)
      req2.input("Abreviatura", abbreviation as string)
      req2.input("BaseA", (baseA as number) ?? 1)
      req2.input("BaseB", (baseB as number) ?? 1)
      req2.input("Activo", active as boolean)
    }
    req2.input(accion === "I" ? "UsuarioCreacion" : "UsuarioModificacion", userId as number)
    const result = await req2.execute("dbo.spUnidadesMedidaCRUD")
    return result.recordset?.[0] as QueryRow | undefined
  }
}

export async function createUnit(input: {
  name: string
  abbreviation: string
  baseA?: number
  baseB?: number
  active?: boolean
}): Promise<UnitRecord> {
  if (!input.name?.trim()) throw new Error("createUnit: nombre requerido")
  if (!input.abbreviation?.trim()) throw new Error("createUnit: abreviatura requerida")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  const row = await runUnitMutate(pool, {
    accion: "I", name: input.name.trim(), abbreviation: input.abbreviation.trim(),
    baseA: input.baseA ?? 1, baseB: input.baseB ?? 1, active: input.active ?? true, userId: demoUserId,
  })

  if (row) return mapUnitRow(row)

  // Fallback: SP doesn't return row yet (pre-migration). Fetch list and find by name.
  const list = await pool.request().input("Accion", "L").execute("dbo.spUnidadesMedidaCRUD")
  const units = (list.recordset as QueryRow[]).map(mapUnitRow)
  const found = units.filter((u) => u.name.toLowerCase() === input.name.trim().toLowerCase()).sort((a, b) => b.id - a.id)[0]
  if (!found) throw new Error("createUnit: no se pudo obtener la unidad creada")
  return found
}

export async function updateUnit(
  id: number,
  input: {
    name: string
    abbreviation: string
    baseA?: number
    baseB?: number
    active?: boolean
  },
): Promise<UnitRecord> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`updateUnit: id invalido = ${id}`)
  if (!input.name?.trim()) throw new Error("updateUnit: nombre requerido")

  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  const row = await runUnitMutate(pool, {
    accion: "A", id, name: input.name.trim(), abbreviation: input.abbreviation.trim(),
    baseA: input.baseA ?? 1, baseB: input.baseB ?? 1, active: input.active ?? true, userId: demoUserId,
  })

  if (row) return mapUnitRow(row)

  // Fallback: SP doesn't return row yet (pre-migration). Fetch list and find by id.
  const list = await pool.request().input("Accion", "L").execute("dbo.spUnidadesMedidaCRUD")
  const units = (list.recordset as QueryRow[]).map(mapUnitRow)
  const found = units.find((u) => u.id === id)
  if (!found) throw new Error("updateUnit: no se pudo obtener la unidad actualizada")
  return found
}

// ═══════════════════════════════════════════════
// ORG STRUCTURE — Types
// ═══════════════════════════════════════════════

export type DivisionRecord = {
  id: number
  name: string
  description: string
  active: boolean
}

export type BranchRecord = {
  id: number
  divisionId: number
  divisionName: string
  name: string
  description: string
  address: string
  active: boolean
}

export type EmissionPointRecord = {
  id: number
  branchId: number
  branchName: string
  divisionId: number
  divisionName: string
  name: string
  code: string
  defaultPriceListId: number | null
  defaultPriceListName: string | null
  defaultPosDocumentTypeId: number | null
  defaultPosDocumentTypeName: string | null
  defaultPosCustomerId: number | null
  defaultPosCustomerName: string | null
  active: boolean
}

export type WarehouseRecord = {
  id: number
  description: string
  initials: string
  type: "C" | "V" | "T" | "N" | "O"
  transitWarehouseId: number | null
  transitWarehouseName: string
  active: boolean
}

export type TaxRateRecord = {
  id: number
  name: string
  rate: number
  code: string
  active: boolean
}

export async function deleteUnit(id: number): Promise<void> {
  if (!Number.isFinite(id) || id <= 0) throw new Error(`deleteUnit: id invalido = ${id}`)
  const pool = await getPool()
  const demoUserId = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    await pool
      .request()
      .input("Accion", "D")
      .input("IdUnidadMedida", sql.Int, id)
      .input("UsuarioModificacion", sql.Int, demoUserId)
      .execute("dbo.spUnidadesMedidaCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "D")
      .input("IdUnidadMedida", id)
      .input("UsuarioModificacion", demoUserId)
      .execute("dbo.spUnidadesMedidaCRUD")
  }
}

// ═══════════════════════════════════════════════
// DIVISIONES
// ═══════════════════════════════════════════════

function mapDivisionRow(row: QueryRow): DivisionRecord {
  return {
    id: toNumber(row.IdDivision),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    active: Boolean(row.Activo),
  }
}

export async function getDivisions(): Promise<DivisionRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spDivisionesCRUD")
  return (result.recordset as QueryRow[]).map(mapDivisionRow)
}

export async function createDivision(input: { name: string; description?: string; active?: boolean }): Promise<DivisionRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "I")
    .input("Nombre", input.name.trim())
    .input("Descripcion", input.description ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioCreacion", userId)
    .execute("dbo.spDivisionesCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapDivisionRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spDivisionesCRUD")
  const found = (list.recordset as QueryRow[]).map(mapDivisionRow)
    .filter(d => d.name.toLowerCase() === input.name.trim().toLowerCase())
    .sort((a, b) => b.id - a.id)[0]
  if (!found) throw new Error("createDivision: no se pudo obtener el registro creado")
  return found
}

export async function updateDivision(id: number, input: { name: string; description?: string; active?: boolean }): Promise<DivisionRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "A")
    .input("IdDivision", id)
    .input("Nombre", input.name.trim())
    .input("Descripcion", input.description ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spDivisionesCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapDivisionRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spDivisionesCRUD")
  const found = (list.recordset as QueryRow[]).map(mapDivisionRow).find(d => d.id === id)
  if (!found) throw new Error("updateDivision: no se pudo obtener el registro actualizado")
  return found
}

export async function deleteDivision(id: number): Promise<void> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdDivision", id)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spDivisionesCRUD")
}

// ═══════════════════════════════════════════════
// SUCURSALES
// ═══════════════════════════════════════════════

function mapBranchRow(row: QueryRow): BranchRecord {
  return {
    id: toNumber(row.IdSucursal),
    divisionId: toNumber(row.IdDivision),
    divisionName: toText(row.NombreDivision),
    name: toText(row.Nombre),
    description: toText(row.Descripcion),
    address: toText(row.Direccion),
    active: Boolean(row.Activo),
  }
}

export async function getBranches(): Promise<BranchRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spSucursalesCRUD")
  return (result.recordset as QueryRow[]).map(mapBranchRow)
}

export async function createBranch(input: { divisionId: number; name: string; description?: string; address?: string; active?: boolean }): Promise<BranchRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "I")
    .input("IdDivision", input.divisionId)
    .input("Nombre", input.name.trim())
    .input("Descripcion", input.description ?? null)
    .input("Direccion", input.address ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioCreacion", userId)
    .execute("dbo.spSucursalesCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapBranchRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spSucursalesCRUD")
  const found = (list.recordset as QueryRow[]).map(mapBranchRow)
    .filter(b => b.divisionId === input.divisionId && b.name.toLowerCase() === input.name.trim().toLowerCase())
    .sort((a, b) => b.id - a.id)[0]
  if (!found) throw new Error("createBranch: no se pudo obtener el registro creado")
  return found
}

export async function updateBranch(id: number, input: { divisionId: number; name: string; description?: string; address?: string; active?: boolean }): Promise<BranchRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "A")
    .input("IdSucursal", id)
    .input("IdDivision", input.divisionId)
    .input("Nombre", input.name.trim())
    .input("Descripcion", input.description ?? null)
    .input("Direccion", input.address ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spSucursalesCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapBranchRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spSucursalesCRUD")
  const found = (list.recordset as QueryRow[]).map(mapBranchRow).find(b => b.id === id)
  if (!found) throw new Error("updateBranch: no se pudo obtener el registro actualizado")
  return found
}

export async function deleteBranch(id: number): Promise<void> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdSucursal", id)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spSucursalesCRUD")
}

// ═══════════════════════════════════════════════
// PUNTOS DE EMISION
// ═══════════════════════════════════════════════

function mapEmissionPointRow(row: QueryRow): EmissionPointRecord {
  return {
    id: toNumber(row.IdPuntoEmision),
    branchId: toNumber(row.IdSucursal),
    branchName: toText(row.NombreSucursal),
    divisionId: toNumber(row.IdDivision),
    divisionName: toText(row.NombreDivision),
    name: toText(row.Nombre),
    code: toText(row.Codigo),
    defaultPriceListId: row.IdListaPrecioPredeterminada != null ? toNumber(row.IdListaPrecioPredeterminada) : null,
    defaultPriceListName: row.NombreListaPrecio != null ? toText(row.NombreListaPrecio) : null,
    defaultPosDocumentTypeId: row.IdFacTipoDocumentoPOSPredeterminado != null ? toNumber(row.IdFacTipoDocumentoPOSPredeterminado) : null,
    defaultPosDocumentTypeName: row.NombreFacTipoDocumentoPOSPredeterminado != null ? toText(row.NombreFacTipoDocumentoPOSPredeterminado) : null,
    defaultPosCustomerId: row.IdClientePOSPredeterminado != null ? toNumber(row.IdClientePOSPredeterminado) : null,
    defaultPosCustomerName: row.NombreClientePOSPredeterminado != null ? toText(row.NombreClientePOSPredeterminado) : null,
    active: Boolean(row.Activo),
  }
}

export async function getEmissionPoints(): Promise<EmissionPointRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spPuntosEmisionCRUD")
  return (result.recordset as QueryRow[]).map(mapEmissionPointRow)
}

export async function createEmissionPoint(input: {
  branchId: number
  name: string
  code?: string
  defaultPriceListId?: number | null
  defaultPosDocumentTypeId?: number | null
  defaultPosCustomerId?: number | null
  active?: boolean
}): Promise<EmissionPointRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "I")
    .input("IdSucursal", input.branchId)
    .input("Nombre", input.name.trim())
    .input("Codigo", input.code ?? "")
    .input("IdListaPrecioPredeterminada", input.defaultPriceListId ?? null)
    .input("IdFacTipoDocumentoPOSPredeterminado", input.defaultPosDocumentTypeId ?? null)
    .input("IdClientePOSPredeterminado", input.defaultPosCustomerId ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioCreacion", userId)
    .execute("dbo.spPuntosEmisionCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapEmissionPointRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spPuntosEmisionCRUD")
  const found = (list.recordset as QueryRow[]).map(mapEmissionPointRow)
    .filter(p => p.branchId === input.branchId && p.name.toLowerCase() === input.name.trim().toLowerCase())
    .sort((a, b) => b.id - a.id)[0]
  if (!found) throw new Error("createEmissionPoint: no se pudo obtener el registro creado")
  return found
}

export async function updateEmissionPoint(id: number, input: {
  branchId: number
  name: string
  code?: string
  defaultPriceListId?: number | null
  defaultPosDocumentTypeId?: number | null
  defaultPosCustomerId?: number | null
  active?: boolean
}): Promise<EmissionPointRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "A")
    .input("IdPuntoEmision", id)
    .input("IdSucursal", input.branchId)
    .input("Nombre", input.name.trim())
    .input("Codigo", input.code ?? "")
    .input("IdListaPrecioPredeterminada", input.defaultPriceListId ?? null)
    .input("IdFacTipoDocumentoPOSPredeterminado", input.defaultPosDocumentTypeId ?? null)
    .input("IdClientePOSPredeterminado", input.defaultPosCustomerId ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spPuntosEmisionCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapEmissionPointRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spPuntosEmisionCRUD")
  const found = (list.recordset as QueryRow[]).map(mapEmissionPointRow).find(p => p.id === id)
  if (!found) throw new Error("updateEmissionPoint: no se pudo obtener el registro actualizado")
  return found
}

export async function deleteEmissionPoint(id: number): Promise<void> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdPuntoEmision", id)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spPuntosEmisionCRUD")
}

// ═══════════════════════════════════════════════
// ALMACENES
// ═══════════════════════════════════════════════

function mapWarehouseRow(row: QueryRow): WarehouseRecord {
  return {
    id: toNumber(row.IdAlmacen),
    description: toText(row.Descripcion),
    initials: toText(row.Siglas),
    type: (toText(row.TipoAlmacen) || "O") as WarehouseRecord["type"],
    transitWarehouseId: row.IdAlmacenTransito != null ? toNumber(row.IdAlmacenTransito) : null,
    transitWarehouseName: toText(row.NombreAlmacenTransito),
    active: Boolean(row.Activo),
  }
}

export async function getWarehouses(): Promise<WarehouseRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spAlmacenesCRUD")
  return (result.recordset as QueryRow[]).map(mapWarehouseRow)
}

export async function createWarehouse(input: {
  description: string
  initials: string
  type?: string
  transitWarehouseId?: number | null
  active?: boolean
}): Promise<WarehouseRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "I")
    .input("Descripcion", input.description.trim())
    .input("Siglas", input.initials.trim())
    .input("TipoAlmacen", input.type ?? "O")
    .input("IdAlmacenTransito", input.transitWarehouseId ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioCreacion", userId)
    .execute("dbo.spAlmacenesCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapWarehouseRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spAlmacenesCRUD")
  const found = (list.recordset as QueryRow[]).map(mapWarehouseRow)
    .filter(w => w.initials.toLowerCase() === input.initials.trim().toLowerCase())
    .sort((a, b) => b.id - a.id)[0]
  if (!found) throw new Error("createWarehouse: no se pudo obtener el registro creado")
  return found
}

export async function updateWarehouse(id: number, input: {
  description: string
  initials: string
  type?: string
  transitWarehouseId?: number | null
  active?: boolean
}): Promise<WarehouseRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "A")
    .input("IdAlmacen", id)
    .input("Descripcion", input.description.trim())
    .input("Siglas", input.initials.trim())
    .input("TipoAlmacen", input.type ?? "O")
    .input("IdAlmacenTransito", input.transitWarehouseId ?? null)
    .input("Activo", input.active ?? true)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spAlmacenesCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapWarehouseRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spAlmacenesCRUD")
  const found = (list.recordset as QueryRow[]).map(mapWarehouseRow).find(w => w.id === id)
  if (!found) throw new Error("updateWarehouse: no se pudo obtener el registro actualizado")
  return found
}

export async function deleteWarehouse(id: number): Promise<void> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdAlmacen", id)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spAlmacenesCRUD")
}

// ═══════════════════════════════════════════════
// TASAS DE IMPUESTO
// ═══════════════════════════════════════════════

function mapTaxRateRow(row: QueryRow): TaxRateRecord {
  return {
    id: toNumber(row.IdTasaImpuesto),
    name: toText(row.Nombre),
    rate: Number(row.Tasa ?? 0),
    code: toText(row.Codigo),
    active: Boolean(row.Activo),
  }
}

export async function getTaxRates(): Promise<TaxRateRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spTasasImpuestoCRUD")
  return (result.recordset as QueryRow[]).map(mapTaxRateRow)
}

export async function createTaxRate(input: { name: string; rate: number; code: string; active?: boolean }): Promise<TaxRateRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "I")
    .input("Nombre", input.name.trim())
    .input("Tasa", input.rate)
    .input("Codigo", input.code.trim().toUpperCase())
    .input("Activo", input.active ?? true)
    .input("UsuarioCreacion", userId)
    .execute("dbo.spTasasImpuestoCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapTaxRateRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spTasasImpuestoCRUD")
  const found = (list.recordset as QueryRow[]).map(mapTaxRateRow)
    .filter(r => r.code.toLowerCase() === input.code.trim().toLowerCase())
    .sort((a, b) => b.id - a.id)[0]
  if (!found) throw new Error("createTaxRate: no se pudo obtener el registro creado")
  return found
}

export async function updateTaxRate(id: number, input: { name: string; rate: number; code: string; active?: boolean }): Promise<TaxRateRecord> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const result = await pool.request()
    .input("Accion", "A")
    .input("IdTasaImpuesto", id)
    .input("Nombre", input.name.trim())
    .input("Tasa", input.rate)
    .input("Codigo", input.code.trim().toUpperCase())
    .input("Activo", input.active ?? true)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spTasasImpuestoCRUD")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (row) return mapTaxRateRow(row)
  const list = await pool.request().input("Accion", "L").execute("dbo.spTasasImpuestoCRUD")
  const found = (list.recordset as QueryRow[]).map(mapTaxRateRow).find(r => r.id === id)
  if (!found) throw new Error("updateTaxRate: no se pudo obtener el registro actualizado")
  return found
}

export async function deleteTaxRate(id: number): Promise<void> {
  const pool = await getPool()
  const userId = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdTasaImpuesto", id)
    .input("UsuarioModificacion", userId)
    .execute("dbo.spTasasImpuestoCRUD")
}

// ─── Producto Almacenes ──────────────────────────────────────────────────────

function mapProductWarehouseRow(row: QueryRow): ProductWarehouseRecord {
  return {
    warehouseId: toNumber(row.IdAlmacen),
    warehouseName: toText(row.NombreAlmacen),
    initials: toText(row.Siglas),
    type: toText(row.TipoAlmacen) || "O",
    quantity: toNumber(row.Cantidad),
    reserved: toNumber(row.CantidadReservada),
    inTransit: toNumber(row.CantidadTransito),
    available: toNumber(row.CantidadDisponible),
  }
}

function mapWarehouseOptionRow(row: QueryRow): WarehouseOption {
  return {
    id: toNumber(row.IdAlmacen),
    name: toText(row.NombreAlmacen),
    initials: toText(row.Siglas),
    type: toText(row.TipoAlmacen) || "O",
  }
}

export async function getProductWarehouses(
  productId: number,
): Promise<{ assigned: ProductWarehouseRecord[]; available: WarehouseOption[] }> {
  const pool = await getPool()
  const [assignedResult, availableResult] = await Promise.all([
    pool.request()
      .input("Accion", "LA")
      .input("IdProducto", productId)
      .execute("dbo.spProductoAlmacenesCRUD"),
    pool.request()
      .input("Accion", "LD")
      .input("IdProducto", productId)
      .execute("dbo.spProductoAlmacenesCRUD"),
  ])
  return {
    assigned: (assignedResult.recordset as QueryRow[]).map(mapProductWarehouseRow),
    available: (availableResult.recordset as QueryRow[]).map(mapWarehouseOptionRow),
  }
}

export async function assignProductWarehouse(
  productId: number,
  warehouseId: number,
  sessionId?: number,
): Promise<{ assigned: ProductWarehouseRecord[]; available: WarehouseOption[] }> {
  const pool = await getPool()
  const sid = sessionId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    await pool.request()
      .input("Accion", sql.NVarChar, "A")
      .input("IdProducto", sql.Int, productId)
      .input("IdAlmacen", sql.Int, warehouseId)
      .input("IdSesion", sql.Int, sid)
      .execute("dbo.spProductoAlmacenesCRUD")
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes("parameter.type.validate")) {
      await pool.request()
        .input("Accion", "A")
        .input("IdProducto", productId)
        .input("IdAlmacen", warehouseId)
        .input("IdSesion", sid)
        .execute("dbo.spProductoAlmacenesCRUD")
    } else throw err
  }
  return getProductWarehouses(productId)
}

export async function removeProductWarehouse(
  productId: number,
  warehouseId: number,
  sessionId?: number,
): Promise<{ assigned: ProductWarehouseRecord[]; available: WarehouseOption[] }> {
  const pool = await getPool()
  const sid = sessionId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    await pool.request()
      .input("Accion", sql.NVarChar, "Q")
      .input("IdProducto", sql.Int, productId)
      .input("IdAlmacen", sql.Int, warehouseId)
      .input("IdSesion", sql.Int, sid)
      .execute("dbo.spProductoAlmacenesCRUD")
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes("parameter.type.validate")) {
      await pool.request()
        .input("Accion", "Q")
        .input("IdProducto", productId)
        .input("IdAlmacen", warehouseId)
        .input("IdSesion", sid)
        .execute("dbo.spProductoAlmacenesCRUD")
    } else throw err
  }
  return getProductWarehouses(productId)
}

export async function updateProductWarehouseStock(
  productId: number,
  warehouseId: number,
  quantity: number,
  sessionId?: number,
): Promise<void> {
  const pool = await getPool()
  const sid = sessionId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    await pool.request()
      .input("Accion", sql.NVarChar, "U")
      .input("IdProducto", sql.Int, productId)
      .input("IdAlmacen", sql.Int, warehouseId)
      .input("Cantidad", sql.Decimal(18, 4), quantity)
      .input("IdSesion", sql.Int, sid)
      .execute("dbo.spProductoAlmacenesCRUD")
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    if (msg.includes("parameter.type.validate")) {
      await pool.request()
        .input("Accion", "U")
        .input("IdProducto", productId)
        .input("IdAlmacen", warehouseId)
        .input("Cantidad", quantity)
        .input("IdSesion", sid)
        .execute("dbo.spProductoAlmacenesCRUD")
    } else throw err
  }
}

function mapProductStockRow(row: QueryRow): ProductStockRow {
  const unitSaleId = row.IdUnidadVenta == null ? null : toNumber(row.IdUnidadVenta)
  const usedAlternateUnitIds = new Set<number>()
  if (unitSaleId != null) {
    usedAlternateUnitIds.add(unitSaleId)
  }
  // Agregar unidad de compra al set de usadas para deduplicación
  const unitCompraId = row.IdUnidadCompra == null ? null : toNumber(row.IdUnidadCompra)
  if (unitCompraId != null) {
    usedAlternateUnitIds.add(unitCompraId)
  }
  const mapAlternate = (unitIdValue: unknown, nameValue: unknown, abbrevValue: unknown, availableValue: unknown) => {
    if (unitIdValue == null) return null
    const unitId = toNumber(unitIdValue)
    if (usedAlternateUnitIds.has(unitId)) return null
    usedAlternateUnitIds.add(unitId)
    return {
      unitId,
      name: toText(nameValue),
      abbrev: toText(abbrevValue),
      disponible: toNumber(availableValue),
    }
  }

  return {
    warehouseId: toNumber(row.IdAlmacen),
    warehouseName: toText(row.NombreAlmacen),
    minimo: row.Minimo == null ? null : toNumber(row.Minimo),
    maximo: row.Maximo == null ? null : toNumber(row.Maximo),
    puntoReorden: row.PuntoReorden == null ? null : toNumber(row.PuntoReorden),
    existencia: toNumber(row.Existencia),
    pendienteRecibir: toNumber(row.PendienteRecibir),
    pendienteEntregar: toNumber(row.PendienteEntregar),
    existenciaReal: toNumber(row.ExistenciaReal),
    reservado: toNumber(row.Reservado),
    disponibleBase: toNumber(row.DisponibleBase),
    unitCompraId,
    unitCompraName: row.NombreUnidadCompra == null ? null : toText(row.NombreUnidadCompra),
    unitCompraAbbrev: row.AbreviaturaUnidadCompra == null ? null : toText(row.AbreviaturaUnidadCompra),
    unitCompraDisponible: row.DisponibleUnitCompra == null ? null : toNumber(row.DisponibleUnitCompra),
    unitName: toText(row.NombreUnidadVenta),
    unitAbbrev: toText(row.AbreviaturaUnidadVenta),
    alterna1: mapAlternate(row.IdUnidadAlterna1, row.NombreAlterna1, row.AbreviaturaAlterna1, row.DisponibleAlterna1),
    alterna2: mapAlternate(row.IdUnidadAlterna2, row.NombreAlterna2, row.AbreviaturaAlterna2, row.DisponibleAlterna2),
    alterna3: mapAlternate(row.IdUnidadAlterna3, row.NombreAlterna3, row.AbreviaturaAlterna3, row.DisponibleAlterna3),
  }
}

export async function getProductStock(productId: number): Promise<ProductStockRow[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("IdProducto", sql.Int, productId)
    .execute("dbo.spProductoExistencias")
    .catch(async (err: unknown) => {
      if (!isTypeValidationError(err)) throw err
      return pool.request().input("IdProducto", productId).execute("dbo.spProductoExistencias")
    })
  return (result.recordset as QueryRow[]).map(mapProductStockRow)
}

// ═══════════════════════════════════════════════════════════════
// CxC MAESTROS — Documentos Identidad, Tipos/Categorias Cliente,
//                Descuentos, Terceros (Clientes)
// ═══════════════════════════════════════════════════════════════

export type DocIdentOption = {
  id: number
  code: string
  name: string
  minLen: number
  maxLen: number
  active: boolean
}

export type TipoClienteOption = {
  id: number
  code: string
  name: string
  active: boolean
}

export type CategClienteOption = {
  id: number
  code: string
  name: string
  active: boolean
}

export type DescuentoRecord = {
  id: number
  code: string
  name: string
  porcentaje: number
  esGlobal: boolean
  fechaInicio: string
  fechaFin: string
  active: boolean
  permiteManual: boolean
  limiteDescuentoManual: number | null
}

export type DescuentoForUser = {
  id: number
  code: string
  name: string
  porcentaje: number
  esGlobal: boolean
  permiteManual: boolean
  limiteDescuentoManual: number | null
}

export type TerceroRecord = {
  id: number
  code: string
  name: string
  shortName: string
  tipoPersona: string
  idTipoDocIdent: number | null
  codigoDocIdent: string
  nombreDocIdent: string
  docLongitudMin: number
  docLongitudMax: number
  documento: string
  esCliente: boolean
  idTipoCliente: number | null
  codigoTipoCliente: string
  nombreTipoCliente: string
  idCategoriaCliente: number | null
  codigoCategoriaCliente: string
  nombreCategoriaCliente: string
  esProveedor: boolean
  idTipoProveedor: number | null
  idCategoriaProveedor: number | null
  direccion: string
  ciudad: string
  telefono: string
  celular: string
  email: string
  web: string
  contacto: string
  telefonoContacto: string
  emailContacto: string
  idListaPrecio: number | null
  nombreListaPrecio: string
  limiteCredito: number
  diasCredito: number
  idDocumentoVenta: number | null
  idTipoComprobante: number | null
  idDescuento: number | null
  notas: string
  pedirReferencia: boolean
  active: boolean
}

export type CxCMaestrosData = {
  customers: TerceroRecord[]
  discounts: DescuentoRecord[]
  lookups: {
    tiposCliente: TipoClienteOption[]
    categoriasCliente: CategClienteOption[]
    docTypes: DocIdentOption[]
    priceLists: Array<{ id: number; code: string; description: string; abbreviation: string; currencyId: number | null; active: boolean }>
    salesDocumentTypes: FacTipoDocumentoRecord[]
    taxVoucherTypes: CatalogoNCFRecord[]
  }
}

function mapDocIdentRow(row: QueryRow): DocIdentOption {
  return {
    id: toNumber(row.IdDocumentoIdentificacion),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    minLen: toNumber(row.LongitudMin ?? 1),
    maxLen: toNumber(row.LongitudMax ?? 30),
    active: Boolean(row.Activo),
  }
}

function mapTipoClienteRow(row: QueryRow): TipoClienteOption {
  return {
    id: toNumber(row.IdTipoCliente),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    active: Boolean(row.Activo),
  }
}

function mapCategClienteRow(row: QueryRow): CategClienteOption {
  return {
    id: toNumber(row.IdCategoriaCliente),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    active: Boolean(row.Activo),
  }
}

function mapDescuentoRow(row: QueryRow): DescuentoRecord {
  return {
    id: toNumber(row.IdDescuento),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    porcentaje: Number(row.Porcentaje ?? 0),
    esGlobal: Boolean(row.EsGlobal ?? true),
    fechaInicio: row.FechaInicio ? toIsoDate(row.FechaInicio) : "",
    fechaFin: row.FechaFin ? toIsoDate(row.FechaFin) : "",
    active: Boolean(row.Activo),
    permiteManual: row.PermiteManual !== undefined ? Boolean(row.PermiteManual) : true,
    limiteDescuentoManual: row.LimiteDescuentoManual != null ? Number(row.LimiteDescuentoManual) : null,
  }
}

function mapDescuentoForUserRow(row: QueryRow): DescuentoForUser {
  return {
    id: toNumber(row.IdDescuento),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    porcentaje: Number(row.Porcentaje ?? 0),
    esGlobal: Boolean(row.EsGlobal ?? true),
    permiteManual: row.PermiteManual !== undefined ? Boolean(row.PermiteManual) : true,
    limiteDescuentoManual: row.LimiteDescuentoManual != null ? Number(row.LimiteDescuentoManual) : null,
  }
}

export async function getDiscountsForUser(userId: number): Promise<DescuentoForUser[]> {
  const pool = await getPool()
  try {
    const result = await pool.request()
      .input("IdUsuario", sql.Int, userId)
      .execute("dbo.spDescuentosPorUsuario")
    return (result.recordset as QueryRow[]).map(mapDescuentoForUserRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("IdUsuario", userId)
      .execute("dbo.spDescuentosPorUsuario")
    return (result.recordset as QueryRow[]).map(mapDescuentoForUserRow)
  }
}

function mapTerceroRow(row: QueryRow): TerceroRecord {
  return {
    id: toNumber(row.IdTercero),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
    shortName: toText(row.NombreCorto),
    tipoPersona: toText(row.TipoPersona, "J"),
    idTipoDocIdent: row.IdTipoDocIdentificacion != null ? toNumber(row.IdTipoDocIdentificacion) : null,
    codigoDocIdent: toText(row.CodigoDocIdent),
    nombreDocIdent: toText(row.NombreDocIdent),
    docLongitudMin: toNumber(row.DocLongitudMin ?? 1),
    docLongitudMax: toNumber(row.DocLongitudMax ?? 30),
    documento: toText(row.DocumentoIdentificacion),
    esCliente: Boolean(row.EsCliente),
    idTipoCliente: row.IdTipoCliente != null ? toNumber(row.IdTipoCliente) : null,
    codigoTipoCliente: toText(row.CodigoTipoCliente),
    nombreTipoCliente: toText(row.NombreTipoCliente),
    idCategoriaCliente: row.IdCategoriaCliente != null ? toNumber(row.IdCategoriaCliente) : null,
    codigoCategoriaCliente: toText(row.CodigoCategoriaCliente),
    nombreCategoriaCliente: toText(row.NombreCategoriaCliente),
    esProveedor: Boolean(row.EsProveedor),
    idTipoProveedor: row.IdTipoProveedor != null ? toNumber(row.IdTipoProveedor) : null,
    idCategoriaProveedor: row.IdCategoriaProveedor != null ? toNumber(row.IdCategoriaProveedor) : null,
    direccion: toText(row.Direccion),
    ciudad: toText(row.Ciudad),
    telefono: toText(row.Telefono),
    celular: toText(row.Celular),
    email: toText(row.Email),
    web: toText(row.Web),
    contacto: toText(row.Contacto),
    telefonoContacto: toText(row.TelefonoContacto),
    emailContacto: toText(row.EmailContacto),
    idListaPrecio: row.IdListaPrecio != null ? toNumber(row.IdListaPrecio) : null,
    nombreListaPrecio: toText(row.NombreListaPrecio),
    limiteCredito: Number(row.LimiteCredito ?? 0),
    diasCredito: toNumber(row.DiasCredito ?? 0),
    idDocumentoVenta: row.IdDocumentoVenta != null ? toNumber(row.IdDocumentoVenta) : null,
    idTipoComprobante: row.IdTipoComprobante != null ? toNumber(row.IdTipoComprobante) : null,
    idDescuento: row.IdDescuento != null ? toNumber(row.IdDescuento) : null,
    notas: toText(row.Notas),
    pedirReferencia: Boolean(row.PedirReferencia),
    active: Boolean(row.Activo),
  }
}

export async function getCxCMaestrosData(): Promise<CxCMaestrosData> {
  const pool = await getPool()
  const [customersResult, discountsResult, tiposResult, categResult, docTypesResult, priceListsResult, salesDocumentTypes, taxVoucherTypes] = await Promise.all([
    pool.request().input("Accion", "L").input("EsCliente", 1).execute("dbo.spTercerosCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spDescuentosCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spTiposClienteCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spCategoriasClienteCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spDocumentosIdentificacionCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spListasPreciosCRUD").catch(() => ({ recordset: [] })),
    getFacTiposDocumento("F").catch(() => []),
    getCatalogoNCF().catch(() => []),
  ])
  return {
    customers: (customersResult.recordset as QueryRow[]).map(mapTerceroRow),
    discounts: (discountsResult.recordset as QueryRow[]).map(mapDescuentoRow),
    lookups: {
      tiposCliente: (tiposResult.recordset as QueryRow[]).map(mapTipoClienteRow),
      categoriasCliente: (categResult.recordset as QueryRow[]).map(mapCategClienteRow),
      docTypes: (docTypesResult.recordset as QueryRow[]).map(mapDocIdentRow),
      priceLists: (priceListsResult.recordset as QueryRow[]).map((row) => ({
        id: toNumber(row.IdListaPrecio),
        code: toText(row.Codigo),
        description: toText(row.Descripcion),
        abbreviation: toText(row.Abreviatura),
        currencyId: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
        active: Boolean(row.Activo),
      })),
      salesDocumentTypes: salesDocumentTypes.filter((item) => item.active),
      taxVoucherTypes: taxVoucherTypes.filter((item) => item.active),
    },
  }
}

export async function getCustomers(): Promise<TerceroRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .input("EsCliente", 1)
    .execute("dbo.spTercerosCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapTerceroRow)
}

export async function getCustomerById(id: number): Promise<TerceroRecord | null> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "O")
    .input("IdTercero", sql.Int, id)
    .execute("dbo.spTercerosCRUD")
    .catch(() => ({ recordset: [] }))
  const row = (result.recordset as QueryRow[])[0]
  return row ? mapTerceroRow(row) : null
}

export async function saveCustomer(
  input: Partial<TerceroRecord> & { code: string; name: string },
  userId?: number,
  session?: SessionContext,
): Promise<TerceroRecord> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  function buildTerceroRequest(r: ReturnType<typeof pool.request>, typed: boolean) {
    const accion = input.id ? "A" : "I"
    r.input("Accion", accion)
    if (typed) {
      r.input("Codigo", sql.VarChar(20), input.code.trim().toUpperCase())
      r.input("Nombre", sql.NVarChar(150), input.name.trim())
      r.input("NombreCorto", sql.NVarChar(50), input.shortName?.trim() || null)
      r.input("TipoPersona", sql.Char(1), input.tipoPersona ?? "J")
      r.input("IdTipoDocIdentificacion", sql.Int, input.idTipoDocIdent ?? null)
      r.input("DocumentoIdentificacion", sql.VarChar(30), input.documento?.trim() || null)
      r.input("EsCliente", sql.Bit, true)
      r.input("IdTipoCliente", sql.Int, input.idTipoCliente ?? null)
      r.input("IdCategoriaCliente", sql.Int, input.idCategoriaCliente ?? null)
      r.input("EsProveedor", sql.Bit, input.esProveedor ?? false)
      r.input("IdTipoProveedor", sql.Int, input.idTipoProveedor ?? null)
      r.input("IdCategoriaProveedor", sql.Int, input.idCategoriaProveedor ?? null)
      r.input("Direccion", sql.NVarChar(300), input.direccion?.trim() || null)
      r.input("Ciudad", sql.NVarChar(100), input.ciudad?.trim() || null)
      r.input("Telefono", sql.VarChar(30), input.telefono?.trim() || null)
      r.input("Celular", sql.VarChar(30), input.celular?.trim() || null)
      r.input("Email", sql.NVarChar(150), input.email?.trim() || null)
      r.input("Web", sql.NVarChar(200), input.web?.trim() || null)
      r.input("Contacto", sql.NVarChar(100), input.contacto?.trim() || null)
      r.input("TelefonoContacto", sql.VarChar(30), input.telefonoContacto?.trim() || null)
      r.input("EmailContacto", sql.NVarChar(150), input.emailContacto?.trim() || null)
      r.input("IdListaPrecio", sql.Int, input.idListaPrecio ?? null)
      r.input("LimiteCredito", sql.Decimal(18, 2), input.limiteCredito ?? 0)
      r.input("DiasCredito", sql.Int, input.diasCredito ?? 0)
      r.input("IdDocumentoVenta", sql.Int, input.idDocumentoVenta ?? null)
      r.input("IdTipoComprobante", sql.Int, input.idTipoComprobante ?? null)
      r.input("IdDescuento", sql.Int, input.idDescuento ?? null)
      r.input("PedirReferencia", sql.Bit, input.pedirReferencia ?? false)
      r.input("Notas", sql.NVarChar(sql.MAX), input.notas?.trim() || null)
      r.input("Activo", sql.Bit, input.active ?? true)
      r.input("UsuarioCreacion", sql.Int, uid)
      r.input("UsuarioModificacion", sql.Int, uid)
      r.input("IdSesion", sql.Int, session?.sessionId ?? null)
      r.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) r.input("IdTercero", sql.Int, input.id)
    } else {
      r.input("Codigo", input.code.trim().toUpperCase())
      r.input("Nombre", input.name.trim())
      r.input("NombreCorto", input.shortName?.trim() || null)
      r.input("TipoPersona", input.tipoPersona ?? "J")
      r.input("IdTipoDocIdentificacion", input.idTipoDocIdent ?? null)
      r.input("DocumentoIdentificacion", input.documento?.trim() || null)
      r.input("EsCliente", true)
      r.input("IdTipoCliente", input.idTipoCliente ?? null)
      r.input("IdCategoriaCliente", input.idCategoriaCliente ?? null)
      r.input("EsProveedor", input.esProveedor ?? false)
      r.input("IdTipoProveedor", input.idTipoProveedor ?? null)
      r.input("IdCategoriaProveedor", input.idCategoriaProveedor ?? null)
      r.input("Direccion", input.direccion?.trim() || null)
      r.input("Ciudad", input.ciudad?.trim() || null)
      r.input("Telefono", input.telefono?.trim() || null)
      r.input("Celular", input.celular?.trim() || null)
      r.input("Email", input.email?.trim() || null)
      r.input("Web", input.web?.trim() || null)
      r.input("Contacto", input.contacto?.trim() || null)
      r.input("TelefonoContacto", input.telefonoContacto?.trim() || null)
      r.input("EmailContacto", input.emailContacto?.trim() || null)
      r.input("IdListaPrecio", input.idListaPrecio ?? null)
      r.input("LimiteCredito", input.limiteCredito ?? 0)
      r.input("DiasCredito", input.diasCredito ?? 0)
      r.input("IdDocumentoVenta", input.idDocumentoVenta ?? null)
      r.input("IdTipoComprobante", input.idTipoComprobante ?? null)
      r.input("IdDescuento", input.idDescuento ?? null)
      r.input("PedirReferencia", input.pedirReferencia ?? false)
      r.input("Notas", input.notas?.trim() || null)
      r.input("Activo", input.active ?? true)
      r.input("UsuarioCreacion", uid)
      r.input("UsuarioModificacion", uid)
      r.input("IdSesion", session?.sessionId ?? null)
      r.input("TokenSesion", session?.token ?? null)
      if (input.id) r.input("IdTercero", input.id)
    }
    return r
  }
  try {
    const result = await buildTerceroRequest(pool.request(), true).execute("dbo.spTercerosCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapTerceroRow(row)
    throw new Error("saveCustomer: SP no devolvio registro")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await buildTerceroRequest(pool.request(), false).execute("dbo.spTercerosCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapTerceroRow(row)
    throw new Error("saveCustomer: SP no devolvio registro")
  }
}

export async function deleteCustomer(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdTercero", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spTercerosCRUD")
}

// ─── Documentos Identidad ─────────────────────────────────────

export async function getDocIdentOptions(): Promise<DocIdentOption[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spDocumentosIdentificacionCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapDocIdentRow)
}

export async function saveDocIdent(
  input: { id?: number; code: string; name: string; minLen?: number; maxLen?: number; active?: boolean },
  userId?: number,
  session?: SessionContext,
): Promise<DocIdentOption> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const req = pool.request()
    .input("Accion", input.id ? "A" : "I")
    .input("Codigo", sql.VarChar(10), input.code.trim().toUpperCase())
    .input("Nombre", sql.NVarChar(80), input.name.trim())
    .input("LongitudMin", sql.Int, input.minLen ?? 1)
    .input("LongitudMax", sql.Int, input.maxLen ?? 30)
    .input("Activo", sql.Bit, input.active ?? true)
    .input("UsuarioCreacion", sql.Int, uid)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
  if (input.id) req.input("IdDocumentoIdentificacion", sql.Int, input.id)
  const result = await req.execute("dbo.spDocumentosIdentificacionCRUD")
  const row = (result.recordset as QueryRow[])[0]
  if (row) return mapDocIdentRow(row)
  throw new Error("saveDocIdent: SP no devolvio registro")
}

export async function deleteDocIdent(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdDocumentoIdentificacion", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spDocumentosIdentificacionCRUD")
}

// ─── Tipos de Cliente ─────────────────────────────────────────

export async function getTiposCliente(): Promise<TipoClienteOption[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spTiposClienteCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapTipoClienteRow)
}

export async function saveTipoCliente(
  input: { id?: number; code: string; name: string; active?: boolean },
  userId?: number,
  session?: SessionContext,
): Promise<TipoClienteOption> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const execute = async (typed: boolean) => {
    const req = pool.request()
      .input("Accion", input.id ? "A" : "I")
    if (typed) {
      req.input("Codigo", sql.VarChar(10), input.code.trim().toUpperCase())
      req.input("Nombre", sql.NVarChar(80), input.name.trim())
      req.input("Activo", sql.Bit, input.active ?? true)
      req.input("UsuarioCreacion", sql.Int, uid)
      req.input("UsuarioModificacion", sql.Int, uid)
      req.input("IdSesion", sql.Int, session?.sessionId ?? null)
      req.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) req.input("IdTipoCliente", sql.Int, input.id)
    } else {
      req.input("Codigo", input.code.trim().toUpperCase())
      req.input("Nombre", input.name.trim())
      req.input("Activo", input.active ?? true)
      req.input("UsuarioCreacion", uid)
      req.input("UsuarioModificacion", uid)
      req.input("IdSesion", session?.sessionId ?? null)
      req.input("TokenSesion", session?.token ?? null)
      if (input.id) req.input("IdTipoCliente", input.id)
    }
    return req.execute("dbo.spTiposClienteCRUD")
  }
  let result
  try {
    result = await execute(true)
  } catch (error) {
    if (error instanceof Error && error.message.includes("parameter.type.validate is not a function")) {
      result = await execute(false)
    } else {
      throw error
    }
  }
  const row = (result.recordset as QueryRow[])[0]
  if (row) return mapTipoClienteRow(row)
  throw new Error("saveTipoCliente: SP no devolvio registro")
}

export async function deleteTipoCliente(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdTipoCliente", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spTiposClienteCRUD")
}

// ─── Categorias de Cliente ────────────────────────────────────

export async function getCategoriasCliente(): Promise<CategClienteOption[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spCategoriasClienteCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapCategClienteRow)
}

export async function saveCategoriaCliente(
  input: { id?: number; code: string; name: string; active?: boolean },
  userId?: number,
  session?: SessionContext,
): Promise<CategClienteOption> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const execute = async (typed: boolean) => {
    const req = pool.request()
      .input("Accion", input.id ? "A" : "I")
    if (typed) {
      req.input("Codigo", sql.VarChar(10), input.code.trim().toUpperCase())
      req.input("Nombre", sql.NVarChar(80), input.name.trim())
      req.input("Activo", sql.Bit, input.active ?? true)
      req.input("UsuarioCreacion", sql.Int, uid)
      req.input("UsuarioModificacion", sql.Int, uid)
      req.input("IdSesion", sql.Int, session?.sessionId ?? null)
      req.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) req.input("IdCategoriaCliente", sql.Int, input.id)
    } else {
      req.input("Codigo", input.code.trim().toUpperCase())
      req.input("Nombre", input.name.trim())
      req.input("Activo", input.active ?? true)
      req.input("UsuarioCreacion", uid)
      req.input("UsuarioModificacion", uid)
      req.input("IdSesion", session?.sessionId ?? null)
      req.input("TokenSesion", session?.token ?? null)
      if (input.id) req.input("IdCategoriaCliente", input.id)
    }
    return req.execute("dbo.spCategoriasClienteCRUD")
  }
  let result
  try {
    result = await execute(true)
  } catch (error) {
    if (error instanceof Error && error.message.includes("parameter.type.validate is not a function")) {
      result = await execute(false)
    } else {
      throw error
    }
  }
  const row = (result.recordset as QueryRow[])[0]
  if (row) return mapCategClienteRow(row)
  throw new Error("saveCategoriaCliente: SP no devolvio registro")
}

export async function deleteCategoriaCliente(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdCategoriaCliente", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spCategoriasClienteCRUD")
}

// ─── Descuentos ───────────────────────────────────────────────

export async function getDescuentos(): Promise<DescuentoRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spDescuentosCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapDescuentoRow)
}

export async function saveDescuento(
  input: { id?: number; code: string; name: string; porcentaje?: number; esGlobal?: boolean; fechaInicio?: string; fechaFin?: string; active?: boolean; permiteManual?: boolean; limiteDescuentoManual?: number | null },
  userId?: number,
  session?: SessionContext,
): Promise<DescuentoRecord> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  function buildDescuentoRequest(r: ReturnType<typeof pool.request>, typed: boolean) {
    r.input("Accion", input.id ? "A" : "I")
    if (typed) {
      r.input("Codigo", sql.VarChar(10), input.code.trim().toUpperCase())
      r.input("Nombre", sql.NVarChar(80), input.name.trim())
      r.input("Porcentaje", sql.Decimal(5, 2), input.porcentaje ?? 0)
      r.input("EsGlobal", sql.Bit, input.esGlobal ?? true)
      r.input("FechaInicio", sql.Date, input.fechaInicio ? new Date(input.fechaInicio + "T00:00:00") : null)
      r.input("FechaFin", sql.Date, input.fechaFin ? new Date(input.fechaFin + "T00:00:00") : null)
      r.input("Activo", sql.Bit, input.active ?? true)
      r.input("PermiteManual", sql.Bit, input.permiteManual ?? true)
      r.input("LimiteDescuentoManual", sql.Decimal(5, 2), input.limiteDescuentoManual ?? null)
      r.input("UsuarioCreacion", sql.Int, uid)
      r.input("UsuarioModificacion", sql.Int, uid)
      r.input("IdSesion", sql.Int, session?.sessionId ?? null)
      r.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) r.input("IdDescuento", sql.Int, input.id)
    } else {
      r.input("Codigo", input.code.trim().toUpperCase())
      r.input("Nombre", input.name.trim())
      r.input("Porcentaje", input.porcentaje ?? 0)
      r.input("EsGlobal", input.esGlobal ?? true)
      r.input("FechaInicio", input.fechaInicio ? new Date(input.fechaInicio + "T00:00:00") : null)
      r.input("FechaFin", input.fechaFin ? new Date(input.fechaFin + "T00:00:00") : null)
      r.input("Activo", input.active ?? true)
      r.input("PermiteManual", input.permiteManual ?? true)
      r.input("LimiteDescuentoManual", input.limiteDescuentoManual ?? null)
      r.input("UsuarioCreacion", uid)
      r.input("UsuarioModificacion", uid)
      r.input("IdSesion", session?.sessionId ?? null)
      r.input("TokenSesion", session?.token ?? null)
      if (input.id) r.input("IdDescuento", input.id)
    }
    return r
  }
  try {
    const result = await buildDescuentoRequest(pool.request(), true).execute("dbo.spDescuentosCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapDescuentoRow(row)
    throw new Error("saveDescuento: SP no devolvio registro")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await buildDescuentoRequest(pool.request(), false).execute("dbo.spDescuentosCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapDescuentoRow(row)
    throw new Error("saveDescuento: SP no devolvio registro")
  }
}

export async function deleteDescuento(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdDescuento", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spDescuentosCRUD")
}

// ── Descuento Usuarios ─────────────────────────────────────────

export type DiscountUser = {
  id: number
  userName: string
  names: string
  surnames: string
  limiteDescuentoManual: number | null
}

function mapDiscountUserRow(row: QueryRow): DiscountUser {
  return {
    id: toNumber(row.IdUsuario),
    userName: toText(row.NombreUsuario),
    names: toText(row.Nombres),
    surnames: toText(row.Apellidos),
    limiteDescuentoManual: row.LimiteDescuentoManual != null ? Number(row.LimiteDescuentoManual) : null,
  }
}

export async function getDiscountUsers(id: number): Promise<{ assigned: DiscountUser[]; available: DiscountUser[] }> {
  const pool = await getPool()
  try {
    const [ra, rd] = await Promise.all([
      pool.request().input("Accion", "LA").input("IdDescuento", sql.Int, id).execute("dbo.spDescuentoUsuarios"),
      pool.request().input("Accion", "LD").input("IdDescuento", sql.Int, id).execute("dbo.spDescuentoUsuarios"),
    ])
    return {
      assigned: (ra.recordset as QueryRow[]).map(mapDiscountUserRow),
      available: (rd.recordset as QueryRow[]).map(mapDiscountUserRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const [ra, rd] = await Promise.all([
      pool.request().input("Accion", "LA").input("IdDescuento", id).execute("dbo.spDescuentoUsuarios"),
      pool.request().input("Accion", "LD").input("IdDescuento", id).execute("dbo.spDescuentoUsuarios"),
    ])
    return {
      assigned: (ra.recordset as QueryRow[]).map(mapDiscountUserRow),
      available: (rd.recordset as QueryRow[]).map(mapDiscountUserRow),
    }
  }
}

async function callDiscountUsersAction(
  action: string,
  discountId: number,
  userId?: number,
): Promise<{ assigned: DiscountUser[]; available: DiscountUser[] }> {
  const pool = await getPool()
  const run = (typed: boolean) => {
    const r = pool.request().input("Accion", action)
    if (typed) {
      r.input("IdDescuento", sql.Int, discountId)
      if (userId !== undefined) r.input("IdUsuario", sql.Int, userId)
    } else {
      r.input("IdDescuento", discountId)
      if (userId !== undefined) r.input("IdUsuario", userId)
    }
    return r.execute("dbo.spDescuentoUsuarios")
  }
  try {
    const result = await run(true)
    const sets = result.recordsets as unknown as QueryRow[][]
    return { assigned: (sets[0] ?? []).map(mapDiscountUserRow), available: (sets[1] ?? []).map(mapDiscountUserRow) }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await run(false)
    const sets = result.recordsets as unknown as QueryRow[][]
    return { assigned: (sets[0] ?? []).map(mapDiscountUserRow), available: (sets[1] ?? []).map(mapDiscountUserRow) }
  }
}

export async function assignDiscountUser(discountId: number, userId: number) {
  return callDiscountUsersAction("A", discountId, userId)
}
export async function removeDiscountUser(discountId: number, userId: number) {
  return callDiscountUsersAction("Q", discountId, userId)
}
export async function assignAllDiscountUsers(discountId: number) {
  return callDiscountUsersAction("AA", discountId)
}
export async function removeAllDiscountUsers(discountId: number) {
  return callDiscountUsersAction("QA", discountId)
}
export async function updateDiscountUserLimit(discountId: number, userId: number, limite: number | null) {
  const pool = await getPool()
  const run = (typed: boolean) => {
    const r = pool.request().input("Accion", "UL")
    if (typed) {
      r.input("IdDescuento", sql.Int, discountId)
      r.input("IdUsuario", sql.Int, userId)
      r.input("LimiteDescuentoManual", sql.Decimal(5, 2), limite)
    } else {
      r.input("IdDescuento", discountId)
      r.input("IdUsuario", userId)
      r.input("LimiteDescuentoManual", limite)
    }
    return r.execute("dbo.spDescuentoUsuarios")
  }
  try {
    const result = await run(true)
    const sets = result.recordsets as unknown as QueryRow[][]
    return { assigned: (sets[0] ?? []).map(mapDiscountUserRow), available: (sets[1] ?? []).map(mapDiscountUserRow) }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await run(false)
    const sets = result.recordsets as unknown as QueryRow[][]
    return { assigned: (sets[0] ?? []).map(mapDiscountUserRow), available: (sets[1] ?? []).map(mapDiscountUserRow) }
  }
}

// ═══════════════════════════════════════════════════════════════
// CxP MAESTROS — Tipos/Categorias Proveedor, Terceros (Proveedores)
// ═══════════════════════════════════════════════════════════════

export type TipoProveedorOption  = { id: number; code: string; name: string }
export type CategProveedorOption = { id: number; code: string; name: string }

export type CxPMaestrosData = {
  suppliers: TerceroRecord[]
  lookups: {
    supplierTypes: TipoProveedorOption[]
    supplierCategories: CategProveedorOption[]
    docTypes: DocIdentOption[]
  }
}

function mapTipoProveedorRow(row: QueryRow): TipoProveedorOption {
  return {
    id: toNumber(row.IdTipoProveedor),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
  }
}

function mapCategProveedorRow(row: QueryRow): CategProveedorOption {
  return {
    id: toNumber(row.IdCategoriaProveedor),
    code: toText(row.Codigo),
    name: toText(row.Nombre),
  }
}

// ─── Tipos de Proveedor ───────────────────────────────────────

export async function getTiposProveedor(): Promise<TipoProveedorOption[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spTiposProveedorCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapTipoProveedorRow)
}

export async function saveTipoProveedor(
  input: { id?: number; code: string; name: string },
  userId?: number,
  session?: SessionContext,
): Promise<TipoProveedorOption> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const execute = async (typed: boolean) => {
    const req = pool.request()
      .input("Accion", input.id ? "A" : "I")
    if (typed) {
      req.input("Codigo", sql.VarChar(10), input.code.trim().toUpperCase())
      req.input("Nombre", sql.NVarChar(80), input.name.trim())
      req.input("UsuarioCreacion", sql.Int, uid)
      req.input("UsuarioModificacion", sql.Int, uid)
      req.input("IdSesion", sql.Int, session?.sessionId ?? null)
      req.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) req.input("IdTipoProveedor", sql.Int, input.id)
    } else {
      req.input("Codigo", input.code.trim().toUpperCase())
      req.input("Nombre", input.name.trim())
      req.input("UsuarioCreacion", uid)
      req.input("UsuarioModificacion", uid)
      req.input("IdSesion", session?.sessionId ?? null)
      req.input("TokenSesion", session?.token ?? null)
      if (input.id) req.input("IdTipoProveedor", input.id)
    }
    return req.execute("dbo.spTiposProveedorCRUD")
  }
  let result
  try {
    result = await execute(true)
  } catch (error) {
    if (error instanceof Error && error.message.includes("parameter.type.validate is not a function")) {
      result = await execute(false)
    } else {
      throw error
    }
  }
  const row = (result.recordset as QueryRow[])[0]
  if (row) return mapTipoProveedorRow(row)
  throw new Error("saveTipoProveedor: SP no devolvio registro")
}

export async function deleteTipoProveedor(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdTipoProveedor", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spTiposProveedorCRUD")
}

// ─── Categorias de Proveedor ──────────────────────────────────

export async function getCategoriasProveedor(): Promise<CategProveedorOption[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spCategoriasProveedorCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapCategProveedorRow)
}

export async function saveCategoriaProveedor(
  input: { id?: number; code: string; name: string },
  userId?: number,
  session?: SessionContext,
): Promise<CategProveedorOption> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const execute = async (typed: boolean) => {
    const req = pool.request()
      .input("Accion", input.id ? "A" : "I")
    if (typed) {
      req.input("Codigo", sql.VarChar(10), input.code.trim().toUpperCase())
      req.input("Nombre", sql.NVarChar(80), input.name.trim())
      req.input("UsuarioCreacion", sql.Int, uid)
      req.input("UsuarioModificacion", sql.Int, uid)
      req.input("IdSesion", sql.Int, session?.sessionId ?? null)
      req.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) req.input("IdCategoriaProveedor", sql.Int, input.id)
    } else {
      req.input("Codigo", input.code.trim().toUpperCase())
      req.input("Nombre", input.name.trim())
      req.input("UsuarioCreacion", uid)
      req.input("UsuarioModificacion", uid)
      req.input("IdSesion", session?.sessionId ?? null)
      req.input("TokenSesion", session?.token ?? null)
      if (input.id) req.input("IdCategoriaProveedor", input.id)
    }
    return req.execute("dbo.spCategoriasProveedorCRUD")
  }
  let result
  try {
    result = await execute(true)
  } catch (error) {
    if (error instanceof Error && error.message.includes("parameter.type.validate is not a function")) {
      result = await execute(false)
    } else {
      throw error
    }
  }
  const row = (result.recordset as QueryRow[])[0]
  if (row) return mapCategProveedorRow(row)
  throw new Error("saveCategoriaProveedor: SP no devolvio registro")
}

export async function deleteCategoriaProveedor(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdCategoriaProveedor", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spCategoriasProveedorCRUD")
}

// ─── CxP Maestros agregados ───────────────────────────────────

export async function getCxPMaestrosData(): Promise<CxPMaestrosData> {
  const pool = await getPool()
  const [suppliersResult, tiposResult, categResult, docTypesResult] = await Promise.all([
    pool.request().input("Accion", "L").input("EsProveedor", 1).execute("dbo.spTercerosCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spTiposProveedorCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spCategoriasProveedorCRUD").catch(() => ({ recordset: [] })),
    pool.request().input("Accion", "L").execute("dbo.spDocumentosIdentificacionCRUD").catch(() => ({ recordset: [] })),
  ])
  return {
    suppliers: (suppliersResult.recordset as QueryRow[]).map(mapTerceroRow),
    lookups: {
      supplierTypes: (tiposResult.recordset as QueryRow[]).map(mapTipoProveedorRow),
      supplierCategories: (categResult.recordset as QueryRow[]).map(mapCategProveedorRow),
      docTypes: (docTypesResult.recordset as QueryRow[]).map(mapDocIdentRow),
    },
  }
}

export async function getSupplierById(id: number): Promise<TerceroRecord | null> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "O")
    .input("IdTercero", sql.Int, id)
    .execute("dbo.spTercerosCRUD")
    .catch(() => ({ recordset: [] }))
  const row = (result.recordset as QueryRow[])[0]
  return row ? mapTerceroRow(row) : null
}

export async function saveSupplier(
  input: Partial<TerceroRecord> & { code: string; name: string },
  userId?: number,
  session?: SessionContext,
): Promise<TerceroRecord> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  function buildSupplierRequest(r: ReturnType<typeof pool.request>, typed: boolean) {
    r.input("Accion", input.id ? "A" : "I")
    if (typed) {
      r.input("Codigo", sql.VarChar(20), input.code.trim().toUpperCase())
      r.input("Nombre", sql.NVarChar(150), input.name.trim())
      r.input("NombreCorto", sql.NVarChar(50), input.shortName?.trim() || null)
      r.input("TipoPersona", sql.Char(1), input.tipoPersona ?? "J")
      r.input("IdTipoDocIdentificacion", sql.Int, input.idTipoDocIdent ?? null)
      r.input("DocumentoIdentificacion", sql.VarChar(30), input.documento?.trim() || null)
      r.input("EsCliente", sql.Bit, input.esCliente ?? false)
      r.input("IdTipoCliente", sql.Int, input.idTipoCliente ?? null)
      r.input("IdCategoriaCliente", sql.Int, input.idCategoriaCliente ?? null)
      r.input("EsProveedor", sql.Bit, true)
      r.input("IdTipoProveedor", sql.Int, input.idTipoProveedor ?? null)
      r.input("IdCategoriaProveedor", sql.Int, input.idCategoriaProveedor ?? null)
      r.input("Direccion", sql.NVarChar(300), input.direccion?.trim() || null)
      r.input("Ciudad", sql.NVarChar(100), input.ciudad?.trim() || null)
      r.input("Telefono", sql.VarChar(30), input.telefono?.trim() || null)
      r.input("Celular", sql.VarChar(30), input.celular?.trim() || null)
      r.input("Email", sql.NVarChar(150), input.email?.trim() || null)
      r.input("Web", sql.NVarChar(200), input.web?.trim() || null)
      r.input("Contacto", sql.NVarChar(100), input.contacto?.trim() || null)
      r.input("TelefonoContacto", sql.VarChar(30), input.telefonoContacto?.trim() || null)
      r.input("EmailContacto", sql.NVarChar(150), input.emailContacto?.trim() || null)
      r.input("IdListaPrecio", sql.Int, input.idListaPrecio ?? null)
      r.input("LimiteCredito", sql.Decimal(18, 2), input.limiteCredito ?? 0)
      r.input("DiasCredito", sql.Int, input.diasCredito ?? 0)
      r.input("IdDocumentoVenta", sql.Int, input.idDocumentoVenta ?? null)
      r.input("IdTipoComprobante", sql.Int, input.idTipoComprobante ?? null)
      r.input("IdDescuento", sql.Int, input.idDescuento ?? null)
      r.input("Notas", sql.NVarChar(sql.MAX), input.notas?.trim() || null)
      r.input("Activo", sql.Bit, input.active ?? true)
      r.input("UsuarioCreacion", sql.Int, uid)
      r.input("UsuarioModificacion", sql.Int, uid)
      r.input("IdSesion", sql.Int, session?.sessionId ?? null)
      r.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) r.input("IdTercero", sql.Int, input.id)
    } else {
      r.input("Codigo", input.code.trim().toUpperCase())
      r.input("Nombre", input.name.trim())
      r.input("NombreCorto", input.shortName?.trim() || null)
      r.input("TipoPersona", input.tipoPersona ?? "J")
      r.input("IdTipoDocIdentificacion", input.idTipoDocIdent ?? null)
      r.input("DocumentoIdentificacion", input.documento?.trim() || null)
      r.input("EsCliente", input.esCliente ?? false)
      r.input("IdTipoCliente", input.idTipoCliente ?? null)
      r.input("IdCategoriaCliente", input.idCategoriaCliente ?? null)
      r.input("EsProveedor", true)
      r.input("IdTipoProveedor", input.idTipoProveedor ?? null)
      r.input("IdCategoriaProveedor", input.idCategoriaProveedor ?? null)
      r.input("Direccion", input.direccion?.trim() || null)
      r.input("Ciudad", input.ciudad?.trim() || null)
      r.input("Telefono", input.telefono?.trim() || null)
      r.input("Celular", input.celular?.trim() || null)
      r.input("Email", input.email?.trim() || null)
      r.input("Web", input.web?.trim() || null)
      r.input("Contacto", input.contacto?.trim() || null)
      r.input("TelefonoContacto", input.telefonoContacto?.trim() || null)
      r.input("EmailContacto", input.emailContacto?.trim() || null)
      r.input("IdListaPrecio", input.idListaPrecio ?? null)
      r.input("LimiteCredito", input.limiteCredito ?? 0)
      r.input("DiasCredito", input.diasCredito ?? 0)
      r.input("IdDocumentoVenta", input.idDocumentoVenta ?? null)
      r.input("IdTipoComprobante", input.idTipoComprobante ?? null)
      r.input("IdDescuento", input.idDescuento ?? null)
      r.input("Notas", input.notas?.trim() || null)
      r.input("Activo", input.active ?? true)
      r.input("UsuarioCreacion", uid)
      r.input("UsuarioModificacion", uid)
      r.input("IdSesion", session?.sessionId ?? null)
      r.input("TokenSesion", session?.token ?? null)
      if (input.id) r.input("IdTercero", input.id)
    }
    return r
  }
  try {
    const result = await buildSupplierRequest(pool.request(), true).execute("dbo.spTercerosCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapTerceroRow(row)
    throw new Error("saveSupplier: SP no devolvio registro")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await buildSupplierRequest(pool.request(), false).execute("dbo.spTercerosCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapTerceroRow(row)
    throw new Error("saveSupplier: SP no devolvio registro")
  }
}

export async function deleteSupplier(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdTercero", sql.Int, id)
    .input("UsuarioModificacion", sql.Int, uid)
    .input("IdSesion", sql.Int, session?.sessionId ?? null)
    .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
    .execute("dbo.spTercerosCRUD")
}

// ═══════════════════════════════════════════════════════════════
// INVENTARIO — Tipos de Documentos
// ═══════════════════════════════════════════════════════════════

export type InvTipoOperacion = "E" | "S" | "C" | "T"

export type InvTipoDocumentoRecord = {
  id: number
  tipoOperacion: InvTipoOperacion
  description: string
  prefijo: string
  secuenciaInicial: number
  secuenciaActual: number
  actualizaCosto: boolean
  idMoneda: number | null
  nombreMoneda: string
  simboloMoneda: string
  idTipoDocumentoEntrada: number | null
  descripcionTipoDocumentoEntrada: string
  idTipoDocumentoSalida: number | null
  descripcionTipoDocumentoSalida: string
  active: boolean
}

export type InvTipoDocUsuarioRecord = {
  id: number
  username: string
  nombres: string
  email: string
  assigned: boolean
}

function mapInvTipoDocRow(row: QueryRow): InvTipoDocumentoRecord {
  return {
    id: toNumber(row.IdTipoDocumento),
    tipoOperacion: toText(row.TipoOperacion) as InvTipoOperacion,
    description: toText(row.Descripcion),
    prefijo: toText(row.Prefijo),
    secuenciaInicial: toNumber(row.SecuenciaInicial ?? 1),
    secuenciaActual: toNumber(row.SecuenciaActual ?? 0),
    actualizaCosto: Boolean(row.ActualizaCosto),
    idMoneda: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    nombreMoneda: toText(row.NombreMoneda),
    simboloMoneda: toText(row.SimboloMoneda),
    idTipoDocumentoEntrada: row.IdTipoDocumentoEntrada != null ? toNumber(row.IdTipoDocumentoEntrada) : null,
    descripcionTipoDocumentoEntrada: toText(row.DescripcionTipoDocumentoEntrada),
    idTipoDocumentoSalida: row.IdTipoDocumentoSalida != null ? toNumber(row.IdTipoDocumentoSalida) : null,
    descripcionTipoDocumentoSalida: toText(row.DescripcionTipoDocumentoSalida),
    active: Boolean(row.Activo),
  }
}

function mapInvTipoDocUsuarioRow(row: QueryRow): InvTipoDocUsuarioRecord {
  return {
    id: toNumber(row.IdUsuario),
    username: toText(row.NombreUsuario),
    nombres: toText(row.Nombres),
    email: toText(row.Correo),
    assigned: Boolean(row.Asignado),
  }
}

export async function getInvTiposDocumento(tipoOperacion?: InvTipoOperacion): Promise<InvTipoDocumentoRecord[]> {
  const pool = await getPool()
  const req = pool.request().input("Accion", "L")
  if (tipoOperacion) req.input("TipoOperacion", tipoOperacion)
  const result = await req.execute("dbo.spInvTiposDocumentoCRUD")
  return (result.recordset as QueryRow[]).map(mapInvTipoDocRow)
}

export async function saveInvTipoDocumento(
  input: {
    id?: number
    tipoOperacion: InvTipoOperacion
    description: string
    prefijo?: string
    secuenciaInicial?: number
    actualizaCosto?: boolean
    idMoneda?: number | null
    idTipoDocumentoEntrada?: number | null
    idTipoDocumentoSalida?: number | null
    active?: boolean
  },
  session?: SessionContext,
): Promise<InvTipoDocumentoRecord> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const desc = input.description.trim()

  function build(r: ReturnType<typeof pool.request>, typed: boolean) {
    r.input("Accion", input.id ? "A" : "I")
    if (typed) {
      r.input("TipoOperacion", sql.Char(1), input.tipoOperacion)
      r.input("Descripcion", sql.NVarChar(250), desc)
      r.input("Prefijo", sql.VarChar(10), input.prefijo?.trim() || null)
      r.input("SecuenciaInicial", sql.Int, input.secuenciaInicial ?? 1)
      r.input("ActualizaCosto", sql.Bit, input.actualizaCosto ?? false)
      r.input("IdMoneda", sql.Int, input.idMoneda ?? null)
      r.input("IdTipoDocumentoEntrada", sql.Int, input.idTipoDocumentoEntrada ?? null)
      r.input("IdTipoDocumentoSalida", sql.Int, input.idTipoDocumentoSalida ?? null)
      r.input("Activo", sql.Bit, input.active ?? true)
      r.input("UsuarioCreacion", sql.Int, uid)
      r.input("UsuarioModificacion", sql.Int, uid)
      r.input("IdSesion", sql.Int, session?.sessionId ?? null)
      r.input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      if (input.id) r.input("IdTipoDocumento", sql.Int, input.id)
    } else {
      r.input("TipoOperacion", input.tipoOperacion)
      r.input("Descripcion", desc)
      r.input("Prefijo", input.prefijo?.trim() || null)
      r.input("SecuenciaInicial", input.secuenciaInicial ?? 1)
      r.input("ActualizaCosto", input.actualizaCosto ?? false)
      r.input("IdMoneda", input.idMoneda ?? null)
      r.input("IdTipoDocumentoEntrada", input.idTipoDocumentoEntrada ?? null)
      r.input("IdTipoDocumentoSalida", input.idTipoDocumentoSalida ?? null)
      r.input("Activo", input.active ?? true)
      r.input("UsuarioCreacion", uid)
      r.input("UsuarioModificacion", uid)
      r.input("IdSesion", session?.sessionId ?? null)
      r.input("TokenSesion", session?.token ?? null)
      if (input.id) r.input("IdTipoDocumento", input.id)
    }
    return r
  }

  try {
    const result = await build(pool.request(), true).execute("dbo.spInvTiposDocumentoCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapInvTipoDocRow(row)
    throw new Error("saveInvTipoDocumento: SP no devolvio registro")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await build(pool.request(), false).execute("dbo.spInvTiposDocumentoCRUD")
    const row = (result.recordset as QueryRow[])[0]
    if (row) return mapInvTipoDocRow(row)
    throw new Error("saveInvTipoDocumento: SP no devolvio registro")
  }
}

export async function deleteInvTipoDocumento(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    await pool.request()
      .input("Accion", "D")
      .input("IdTipoDocumento", sql.Int, id)
      .input("UsuarioModificacion", sql.Int, uid)
      .input("IdSesion", sql.Int, session?.sessionId ?? null)
      .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      .execute("dbo.spInvTiposDocumentoCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool.request()
      .input("Accion", "D")
      .input("IdTipoDocumento", id)
      .input("UsuarioModificacion", uid)
      .input("IdSesion", session?.sessionId ?? null)
      .input("TokenSesion", session?.token ?? null)
      .execute("dbo.spInvTiposDocumentoCRUD")
  }
}

export async function getInvTipoDocUsuarios(idTipoDocumento: number): Promise<InvTipoDocUsuarioRecord[]> {
  const pool = await getPool()
  try {
    const result = await pool.request()
      .input("Accion", "LU")
      .input("IdTipoDocumento", sql.Int, idTipoDocumento)
      .execute("dbo.spInvTiposDocumentoCRUD")
    return (result.recordset as QueryRow[]).map(mapInvTipoDocUsuarioRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "LU")
      .input("IdTipoDocumento", idTipoDocumento)
      .execute("dbo.spInvTiposDocumentoCRUD")
    return (result.recordset as QueryRow[]).map(mapInvTipoDocUsuarioRow)
  }
}

export async function syncInvTipoDocUsuarios(
  idTipoDocumento: number,
  userIds: number[],
  session?: SessionContext,
): Promise<InvTipoDocUsuarioRecord[]> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    const result = await pool.request()
      .input("Accion", "U")
      .input("IdTipoDocumento", sql.Int, idTipoDocumento)
      .input("UsuariosAsignados", sql.NVarChar(sql.MAX), userIds.join(","))
      .input("UsuarioCreacion", sql.Int, uid)
      .input("UsuarioModificacion", sql.Int, uid)
      .input("IdSesion", sql.Int, session?.sessionId ?? null)
      .input("TokenSesion", sql.NVarChar(128), session?.token ?? null)
      .execute("dbo.spInvTiposDocumentoCRUD")
    return (result.recordset as QueryRow[]).map(mapInvTipoDocUsuarioRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "U")
      .input("IdTipoDocumento", idTipoDocumento)
      .input("UsuariosAsignados", userIds.join(","))
      .input("UsuarioCreacion", uid)
      .input("UsuarioModificacion", uid)
      .input("IdSesion", session?.sessionId ?? null)
      .input("TokenSesion", session?.token ?? null)
      .execute("dbo.spInvTiposDocumentoCRUD")
    return (result.recordset as QueryRow[]).map(mapInvTipoDocUsuarioRow)
  }
}

// ── Documentos de Inventario (Entradas / Salidas) ──────────────────

export type InvDocumentoRecord = {
  id: number
  idTipoDocumento: number
  nombreTipoDocumento: string
  tipoOperacion: InvTipoOperacion
  periodo: string
  secuencia: number
  numeroDocumento: string
  fecha: string
  idAlmacen: number
  nombreAlmacen: string
  idMoneda: number | null
  nombreMoneda: string
  simboloMoneda: string
  tasaCambio: number
  referencia: string
  observacion: string
  idProveedor: number | null
  nombreProveedor: string
  noFactura: string
  ncf: string
  fechaFactura: string
  totalDocumento: number
  estado: string
}

export type InvSupplierOption = {
  id: number
  code: string
  name: string
}

type InvCompraMeta = {
  idProveedor: number | null
  nombreProveedor: string
  noFactura: string
  ncf: string
  fechaFactura: string
}

export type InvDocumentoDetalleRecord = {
  id: number
  numeroLinea: number
  idProducto: number
  codigo: string
  descripcion: string
  idUnidadMedida: number | null
  nombreUnidad: string
  cantidad: number
  costo: number
  total: number
}

export type InvDocumentoDetalleHistoryRecord = {
  id: number
  numeroLinea: number
  idProducto: number
  codigo: string
  descripcion: string
  idUnidadMedida: number | null
  nombreUnidad: string
  cantidad: number
  costo: number
  total: number
  rowStatus: number
  fechaCreacion: string
  usuarioCreacionId: number | null
  usuarioCreacionNombre: string
}

export type UnidadOpcion = {
  id: number
  nombre: string
  abreviatura: string
  baseA?: number
  baseB?: number
}

export type InvProductoParaDocumento = {
  id: number
  codigo: string
  nombre: string
  idUnidadBase: number | null
  idUnidadMedida: number | null
  idUnidadVenta: number | null
  nombreUnidad: string
  abreviaturaUnidad: string
  costoPromedio: number
  manejaExistencia: boolean
  existencia: number
  pideUnidadInventario: boolean
  unidades: UnidadOpcion[]
}

export type InvDocumentosListResult = {
  items: InvDocumentoRecord[]
  total: number
  page: number
  pageSize: number
}

export type InvTransferenciaEstado = "B" | "T" | "C" | "N"

export type InvTransferenciaRecord = InvDocumentoRecord & {
  idAlmacenDestino: number
  nombreAlmacenDestino: string
  idAlmacenTransito: number
  nombreAlmacenTransito: string
  estadoTransferencia: InvTransferenciaEstado
  fechaSalida: string
  fechaRecepcion: string
  referenciaDocumentoSalida: string
  referenciaDocumentoEntrada: string
  referenciaDocumentoTransitoEntrada: string
  referenciaDocumentoTransitoSalida: string
  usuarioSalida: string
  usuarioRecepcion: string
}

export type InvTransferenciasListResult = {
  items: InvTransferenciaRecord[]
  total: number
  page: number
  pageSize: number
}

function mapInvDocumentoRow(row: QueryRow): InvDocumentoRecord {
  return {
    id: toNumber(row.IdDocumento),
    idTipoDocumento: toNumber(row.IdTipoDocumento),
    nombreTipoDocumento: toText(row.NombreTipoDocumento),
    tipoOperacion: toText(row.TipoOperacion) as InvTipoOperacion,
    periodo: toText(row.Periodo),
    secuencia: toNumber(row.Secuencia),
    numeroDocumento: toText(row.NumeroDocumento),
    fecha: toIsoDate(row.Fecha),
    idAlmacen: toNumber(row.IdAlmacen),
    nombreAlmacen: toText(row.NombreAlmacen),
    idMoneda: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    nombreMoneda: toText(row.NombreMoneda),
    simboloMoneda: toText(row.SimboloMoneda),
    tasaCambio: Number(row.TasaCambio ?? 1),
    referencia: toText(row.Referencia),
    observacion: toText(row.Observacion),
    idProveedor: row.IdProveedor != null ? toNumber(row.IdProveedor) : null,
    nombreProveedor: toText(row.NombreProveedor),
    noFactura: toText(row.NoFactura),
    ncf: toText(row.NCF),
    fechaFactura: row.FechaFactura ? toIsoDate(row.FechaFactura) : "",
    totalDocumento: Number(row.TotalDocumento ?? 0),
    estado: toText(row.Estado),
  }
}

function mapInvTransferenciaRow(row: QueryRow): InvTransferenciaRecord {
  const base = mapInvDocumentoRow(row)
  return {
    ...base,
    idAlmacenDestino: toNumber(row.IdAlmacenDestino),
    nombreAlmacenDestino: toText(row.NombreAlmacenDestino),
    idAlmacenTransito: toNumber(row.IdAlmacenTransito),
    nombreAlmacenTransito: toText(row.NombreAlmacenTransito),
    estadoTransferencia: (toText(row.EstadoTransferencia) || (base.estado === "N" ? "N" : "B")) as InvTransferenciaEstado,
    fechaSalida: row.FechaSalida ? toIsoDateTime(row.FechaSalida) : "",
    fechaRecepcion: row.FechaRecepcion ? toIsoDateTime(row.FechaRecepcion) : "",
    referenciaDocumentoSalida: toText(row.ReferenciaDocumentoSalida),
    referenciaDocumentoEntrada: toText(row.ReferenciaDocumentoEntrada),
    referenciaDocumentoTransitoEntrada: toText(row.ReferenciaDocumentoTransitoEntrada),
    referenciaDocumentoTransitoSalida: toText(row.ReferenciaDocumentoTransitoSalida),
    usuarioSalida: toText(row.UsuarioSalidaNombre),
    usuarioRecepcion: toText(row.UsuarioRecepcionNombre),
  }
}

type InvTransferenciaMeta = {
  referenciaDocumentoSalida: string
  referenciaDocumentoEntrada: string
  referenciaDocumentoTransitoEntrada: string
  referenciaDocumentoTransitoSalida: string
  usuarioSalida: string
  usuarioRecepcion: string
}

function mapInvTransferenciaMetaRow(row: QueryRow): InvTransferenciaMeta & { idDocumento: number } {
  const numeroDocumentoSalida = toText(row.NumeroDocumentoSalida)
  const numeroDocumentoEntradaTransito = toText(row.NumeroDocumentoEntradaTransito)
  const numeroDocumentoSalidaTransito = toText(row.NumeroDocumentoSalidaTransito)
  const numeroDocumentoEntrada = toText(row.NumeroDocumentoEntrada)
  const fechaSalida = row.FechaSalida ? toIsoDateTime(row.FechaSalida) : ""
  const fechaRecepcion = row.FechaRecepcion ? toIsoDateTime(row.FechaRecepcion) : ""
  const nombreSalida = [toText(row.UsuarioSalidaUser), toText(row.UsuarioSalidaFull)].filter(Boolean).join(" - ")
  const nombreRecepcion = [toText(row.UsuarioRecepcionUser), toText(row.UsuarioRecepcionFull)].filter(Boolean).join(" - ")

  return {
    idDocumento: toNumber(row.IdDocumento),
    referenciaDocumentoSalida: numeroDocumentoSalida,
    referenciaDocumentoEntrada: numeroDocumentoEntrada,
    referenciaDocumentoTransitoEntrada: numeroDocumentoEntradaTransito,
    referenciaDocumentoTransitoSalida: numeroDocumentoSalidaTransito,
    usuarioSalida: nombreSalida,
    usuarioRecepcion: nombreRecepcion,
  }
}

async function getInvTransferenciasMetaMap(ids: number[]): Promise<Map<number, InvTransferenciaMeta>> {
  if (ids.length === 0) return new Map()
  const pool = await getPool()
  const placeholders = ids.map((_, idx) => `@id${idx}`).join(", ")
  const query = `
    SELECT
      d.IdDocumento,
      t.FechaSalida,
      t.FechaRecepcion,
      ds.NumeroDocumento AS NumeroDocumentoSalida,
      det.NumeroDocumento AS NumeroDocumentoEntradaTransito,
      dst.NumeroDocumento AS NumeroDocumentoSalidaTransito,
      de.NumeroDocumento AS NumeroDocumentoEntrada,
      us.NombreUsuario AS UsuarioSalidaUser,
      CONCAT(ISNULL(us.Nombres, ''), CASE WHEN us.Apellidos IS NULL OR us.Apellidos = '' THEN '' ELSE ' ' + us.Apellidos END) AS UsuarioSalidaFull,
      ur.NombreUsuario AS UsuarioRecepcionUser,
      CONCAT(ISNULL(ur.Nombres, ''), CASE WHEN ur.Apellidos IS NULL OR ur.Apellidos = '' THEN '' ELSE ' ' + ur.Apellidos END) AS UsuarioRecepcionFull
    FROM dbo.InvDocumentos d
    INNER JOIN dbo.InvTransferencias t ON t.IdDocumento = d.IdDocumento
    LEFT JOIN dbo.InvDocumentos ds ON ds.IdDocumento = t.IdDocumentoSalida
    LEFT JOIN dbo.InvDocumentos det ON det.IdDocumento = t.IdDocumentoEntradaTransito
    LEFT JOIN dbo.InvDocumentos dst ON dst.IdDocumento = t.IdDocumentoSalidaTransito
    LEFT JOIN dbo.InvDocumentos de ON de.IdDocumento = t.IdDocumentoEntrada
    LEFT JOIN dbo.Usuarios us ON us.IdUsuario = t.UsuarioSalida
    LEFT JOIN dbo.Usuarios ur ON ur.IdUsuario = t.UsuarioRecepcion
    WHERE d.IdDocumento IN (${placeholders});
  `

  try {
    const req = pool.request()
    ids.forEach((id, idx) => req.input(`id${idx}`, sql.Int, id))
    const result = await req.query(query)
    const map = new Map<number, InvTransferenciaMeta>()
    for (const row of result.recordset as QueryRow[]) {
      const parsed = mapInvTransferenciaMetaRow(row)
      map.set(parsed.idDocumento, {
        referenciaDocumentoSalida: parsed.referenciaDocumentoSalida,
        referenciaDocumentoEntrada: parsed.referenciaDocumentoEntrada,
        referenciaDocumentoTransitoEntrada: parsed.referenciaDocumentoTransitoEntrada,
        referenciaDocumentoTransitoSalida: parsed.referenciaDocumentoTransitoSalida,
        usuarioSalida: parsed.usuarioSalida,
        usuarioRecepcion: parsed.usuarioRecepcion,
      })
    }
    return map
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request()
    ids.forEach((id, idx) => req.input(`id${idx}`, id))
    const result = await req.query(query)
    const map = new Map<number, InvTransferenciaMeta>()
    for (const row of result.recordset as QueryRow[]) {
      const parsed = mapInvTransferenciaMetaRow(row)
      map.set(parsed.idDocumento, {
        referenciaDocumentoSalida: parsed.referenciaDocumentoSalida,
        referenciaDocumentoEntrada: parsed.referenciaDocumentoEntrada,
        referenciaDocumentoTransitoEntrada: parsed.referenciaDocumentoTransitoEntrada,
        referenciaDocumentoTransitoSalida: parsed.referenciaDocumentoTransitoSalida,
        usuarioSalida: parsed.usuarioSalida,
        usuarioRecepcion: parsed.usuarioRecepcion,
      })
    }
    return map
  }
}

async function enrichInvTransferenciasMeta(items: InvTransferenciaRecord[]): Promise<InvTransferenciaRecord[]> {
  if (items.length === 0) return items
  const metaMap = await getInvTransferenciasMetaMap(items.map((item) => item.id))
  return items.map((item) => {
    const meta = metaMap.get(item.id)
    if (!meta) return item
    return {
      ...item,
      referenciaDocumentoSalida: meta.referenciaDocumentoSalida,
      referenciaDocumentoEntrada: meta.referenciaDocumentoEntrada,
      referenciaDocumentoTransitoEntrada: meta.referenciaDocumentoTransitoEntrada,
      referenciaDocumentoTransitoSalida: meta.referenciaDocumentoTransitoSalida,
      usuarioSalida: meta.usuarioSalida,
      usuarioRecepcion: meta.usuarioRecepcion,
    }
  })
}

export async function listInvSuppliers(): Promise<InvSupplierOption[]> {
  const pool = await getPool()

  function mapRows(rows: QueryRow[]) {
    return rows
      .map((row) => ({
        id: toNumber(row.IdTercero),
        code: toText(row.Codigo),
        name: toText(row.Nombre),
        active: Boolean(row.Activo),
      }))
      .filter((item) => item.id > 0 && item.active)
      .map(({ active: _active, ...item }) => item)
  }

  try {
    const result = await pool.request()
      .input("Accion", sql.Char(1), "L")
      .input("EsProveedor", sql.Bit, true)
      .execute("dbo.spTercerosCRUD")
    return mapRows(result.recordset as QueryRow[])
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "L")
      .input("EsProveedor", true)
      .execute("dbo.spTercerosCRUD")
    return mapRows(result.recordset as QueryRow[])
  }
}

function mapInvCompraMetaRow(row: QueryRow): InvCompraMeta & { idDocumento: number } {
  return {
    idDocumento: toNumber(row.IdDocumento),
    idProveedor: row.IdProveedor != null ? toNumber(row.IdProveedor) : null,
    nombreProveedor: toText(row.NombreProveedor),
    noFactura: toText(row.NoFactura),
    ncf: toText(row.NCF),
    fechaFactura: row.FechaFactura ? toIsoDate(row.FechaFactura) : "",
  }
}

async function getInvDocumentosCompraMetaMap(ids: number[]): Promise<Map<number, InvCompraMeta>> {
  if (ids.length === 0) return new Map()
  const pool = await getPool()

  const placeholders = ids.map((_, idx) => `@id${idx}`).join(", ")
  const query = `
    SELECT
      d.IdDocumento,
      d.IdProveedor,
      t.Nombre AS NombreProveedor,
      d.NoFactura,
      d.NCF,
      d.FechaFactura
    FROM dbo.InvDocumentos d
    LEFT JOIN dbo.Terceros t ON t.IdTercero = d.IdProveedor
    WHERE d.IdDocumento IN (${placeholders});
  `

  try {
    const req = pool.request()
    ids.forEach((id, idx) => req.input(`id${idx}`, sql.Int, id))
    const result = await req.query(query)
    const map = new Map<number, InvCompraMeta>()
    for (const row of (result.recordset as QueryRow[])) {
      const parsed = mapInvCompraMetaRow(row)
      map.set(parsed.idDocumento, {
        idProveedor: parsed.idProveedor,
        nombreProveedor: parsed.nombreProveedor,
        noFactura: parsed.noFactura,
        ncf: parsed.ncf,
        fechaFactura: parsed.fechaFactura,
      })
    }
    return map
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request()
    ids.forEach((id, idx) => req.input(`id${idx}`, id))
    const result = await req.query(query)
    const map = new Map<number, InvCompraMeta>()
    for (const row of (result.recordset as QueryRow[])) {
      const parsed = mapInvCompraMetaRow(row)
      map.set(parsed.idDocumento, {
        idProveedor: parsed.idProveedor,
        nombreProveedor: parsed.nombreProveedor,
        noFactura: parsed.noFactura,
        ncf: parsed.ncf,
        fechaFactura: parsed.fechaFactura,
      })
    }
    return map
  }
}

async function enrichInvDocumentosCompraMeta(items: InvDocumentoRecord[]): Promise<InvDocumentoRecord[]> {
  if (items.length === 0) return items
  const metaMap = await getInvDocumentosCompraMetaMap(items.map((item) => item.id))
  return items.map((item) => {
    const meta = metaMap.get(item.id)
    if (!meta) return item
    return {
      ...item,
      idProveedor: meta.idProveedor,
      nombreProveedor: meta.nombreProveedor,
      noFactura: meta.noFactura,
      ncf: meta.ncf,
      fechaFactura: meta.fechaFactura,
    }
  })
}

async function saveInvDocumentoCompraMeta(
  idDocumento: number,
  input: {
    idProveedor?: number | null
    noFactura?: string | null
    ncf?: string | null
    fechaFactura?: string | null
  },
  userId: number,
) {
  const pool = await getPool()

  const idProveedor = input.idProveedor ?? null
  const noFactura = input.noFactura?.trim() || null
  const ncf = input.ncf?.trim() || null
  const fechaFactura = input.fechaFactura ?? null

  const query = `
    UPDATE dbo.InvDocumentos
    SET
      IdProveedor = @IdProveedor,
      NoFactura = @NoFactura,
      NCF = @NCF,
      FechaFactura = @FechaFactura,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @IdUsuario
    WHERE IdDocumento = @IdDocumento;
  `

  try {
    await pool.request()
      .input("IdDocumento", sql.Int, idDocumento)
      .input("IdProveedor", sql.Int, idProveedor)
      .input("NoFactura", sql.NVarChar(50), noFactura)
      .input("NCF", sql.NVarChar(50), ncf)
      .input("FechaFactura", sql.Date, fechaFactura)
      .input("IdUsuario", sql.Int, userId)
      .query(query)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool.request()
      .input("IdDocumento", idDocumento)
      .input("IdProveedor", idProveedor)
      .input("NoFactura", noFactura)
      .input("NCF", ncf)
      .input("FechaFactura", fechaFactura)
      .input("IdUsuario", userId)
      .query(query)
  }
}

function mapInvDocDetalleRow(row: QueryRow): InvDocumentoDetalleRecord {
  return {
    id: toNumber(row.IdDetalle),
    numeroLinea: toNumber(row.NumeroLinea),
    idProducto: toNumber(row.IdProducto),
    codigo: toText(row.Codigo),
    descripcion: toText(row.Descripcion),
    idUnidadMedida: row.IdUnidadMedida != null ? toNumber(row.IdUnidadMedida) : null,
    nombreUnidad: toText(row.NombreUnidad),
    cantidad: Number(row.Cantidad ?? 0),
    costo: Number(row.Costo ?? 0),
    total: Number(row.Total ?? 0),
  }
}

function mapInvDocDetalleHistoryRow(row: QueryRow): InvDocumentoDetalleHistoryRecord {
  return {
    id: toNumber(row.IdDetalle),
    numeroLinea: toNumber(row.NumeroLinea),
    idProducto: toNumber(row.IdProducto),
    codigo: toText(row.Codigo),
    descripcion: toText(row.Descripcion),
    idUnidadMedida: row.IdUnidadMedida != null ? toNumber(row.IdUnidadMedida) : null,
    nombreUnidad: toText(row.NombreUnidad),
    cantidad: Number(row.Cantidad ?? 0),
    costo: Number(row.Costo ?? 0),
    total: Number(row.Total ?? 0),
    rowStatus: toNumber(row.RowStatus),
    fechaCreacion: toIsoDateTime(row.FechaCreacion),
    usuarioCreacionId: row.UsuarioCreacion != null ? toNumber(row.UsuarioCreacion) : null,
    usuarioCreacionNombre: toText(row.UsuarioCreacionNombre),
  }
}

function mapInvProductoParaDocRow(row: QueryRow): InvProductoParaDocumento {
  const unidades: UnidadOpcion[] = []
  const seen = new Set<number>()
  const normalizeFactor = (value: unknown) => Array.isArray(value) ? toNumber(value[0]) : toNumber(value)

  function addUnit(id: number | null, nombre: string, abreviatura: string, baseA?: unknown, baseB?: unknown) {
    if (!id || seen.has(id)) return
    seen.add(id)
    unidades.push({
      id,
      nombre,
      abreviatura,
      baseA: baseA == null ? undefined : normalizeFactor(baseA),
      baseB: baseB == null ? undefined : normalizeFactor(baseB),
    })
  }

  addUnit(row.IdUnidadMedida != null ? toNumber(row.IdUnidadMedida) : null, toText(row.NombreUnidad), toText(row.AbreviaturaUnidad), row.BaseAUnidad, row.BaseBUnidad)
  addUnit(row.IdUnidadVenta != null ? toNumber(row.IdUnidadVenta) : null, toText(row.NombreUnidadVenta), toText(row.AbreviaturaUnidadVenta), row.BaseAUnidadVenta, row.BaseBUnidadVenta)
  addUnit(row.IdUnidadCompra != null ? toNumber(row.IdUnidadCompra) : null, toText(row.NombreUnidadCompra), toText(row.AbreviaturaUnidadCompra), row.BaseAUnidadCompra, row.BaseBUnidadCompra)
  addUnit(row.IdUnidadAlterna1 != null ? toNumber(row.IdUnidadAlterna1) : null, toText(row.NombreUnidadAlterna1), toText(row.AbreviaturaUnidadAlterna1), row.BaseAUnidadAlterna1, row.BaseBUnidadAlterna1)
  addUnit(row.IdUnidadAlterna2 != null ? toNumber(row.IdUnidadAlterna2) : null, toText(row.NombreUnidadAlterna2), toText(row.AbreviaturaUnidadAlterna2), row.BaseAUnidadAlterna2, row.BaseBUnidadAlterna2)
  addUnit(row.IdUnidadAlterna3 != null ? toNumber(row.IdUnidadAlterna3) : null, toText(row.NombreUnidadAlterna3), toText(row.AbreviaturaUnidadAlterna3), row.BaseAUnidadAlterna3, row.BaseBUnidadAlterna3)

  const defaultUnitId = row.IdUnidadVenta != null ? toNumber(row.IdUnidadVenta) : (row.IdUnidadMedida != null ? toNumber(row.IdUnidadMedida) : null)
  const defaultUnit = defaultUnitId != null ? unidades.find((item) => item.id === defaultUnitId) ?? null : null

  return {
    id: toNumber(row.IdProducto),
    codigo: toText(row.Codigo),
    nombre: toText(row.Nombre),
    idUnidadBase: row.IdUnidadMedida != null ? toNumber(row.IdUnidadMedida) : null,
    idUnidadMedida: defaultUnitId,
    idUnidadVenta: row.IdUnidadVenta != null ? toNumber(row.IdUnidadVenta) : null,
    nombreUnidad: defaultUnit?.nombre ?? toText(row.NombreUnidad),
    abreviaturaUnidad: defaultUnit?.abreviatura ?? toText(row.AbreviaturaUnidad),
    costoPromedio: Number(row.CostoPromedio ?? 0),
    manejaExistencia: Boolean(row.ManejaExistencia),
    existencia: Number(row.Existencia ?? 0),
    pideUnidadInventario: Boolean(row.PideUnidadInventario ?? false),
    unidades,
  }
}

export async function listInvDocumentos(filters: {
  tipoOperacion?: InvTipoOperacion
  idAlmacen?: number
  idTipoDocumento?: number
  fechaDesde?: string
  fechaHasta?: string
  secuenciaDesde?: number
  secuenciaHasta?: number
  page?: number
  pageSize?: number
}): Promise<InvDocumentosListResult> {
  const pool = await getPool()
  const page = filters.page && filters.page > 0 ? filters.page : 1
  const pageSize = filters.pageSize && filters.pageSize > 0 ? filters.pageSize : 20

  async function mapListResult(recordset: QueryRow[]): Promise<InvDocumentosListResult> {
    const items = recordset.map(mapInvDocumentoRow)
    const itemsWithMeta = await enrichInvDocumentosCompraMeta(items)
    const totalRaw = recordset[0]?.TotalRows
    const total = totalRaw != null ? Number(totalRaw) : itemsWithMeta.length
    return { items: itemsWithMeta, total, page, pageSize }
  }

  try {
    const req = pool.request().input("Accion", "L")
    if (filters.tipoOperacion) req.input("TipoOperacion", sql.Char(1), filters.tipoOperacion)
    if (filters.idAlmacen) req.input("IdAlmacen", sql.Int, filters.idAlmacen)
    if (filters.idTipoDocumento) req.input("IdTipoDocumento", sql.Int, filters.idTipoDocumento)
    if (filters.fechaDesde) req.input("FechaDesde", sql.Date, filters.fechaDesde)
    if (filters.fechaHasta) req.input("FechaHasta", sql.Date, filters.fechaHasta)
    if (filters.secuenciaDesde != null) req.input("SecuenciaDesde", sql.Int, filters.secuenciaDesde)
    if (filters.secuenciaHasta != null) req.input("SecuenciaHasta", sql.Int, filters.secuenciaHasta)
    req.input("NumeroPagina", sql.Int, page)
    req.input("TamanoPagina", sql.Int, pageSize)
    const result = await req.execute("dbo.spInvDocumentosCRUD")
    return await mapListResult(result.recordset as QueryRow[])
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("Accion", "L")
    if (filters.tipoOperacion) req.input("TipoOperacion", filters.tipoOperacion)
    if (filters.idAlmacen) req.input("IdAlmacen", filters.idAlmacen)
    if (filters.idTipoDocumento) req.input("IdTipoDocumento", filters.idTipoDocumento)
    if (filters.fechaDesde) req.input("FechaDesde", filters.fechaDesde)
    if (filters.fechaHasta) req.input("FechaHasta", filters.fechaHasta)
    if (filters.secuenciaDesde != null) req.input("SecuenciaDesde", filters.secuenciaDesde)
    if (filters.secuenciaHasta != null) req.input("SecuenciaHasta", filters.secuenciaHasta)
    req.input("NumeroPagina", page)
    req.input("TamanoPagina", pageSize)
    const result = await req.execute("dbo.spInvDocumentosCRUD")
    return await mapListResult(result.recordset as QueryRow[])
  }
}

export async function getInvDocumento(id: number): Promise<{ header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] } | null> {
  const pool = await getPool()
  try {
    const result = await pool.request()
      .input("Accion", "O")
      .input("IdDocumento", sql.Int, id)
      .execute("dbo.spInvDocumentosCRUD")
    const headerRow = ((result.recordsets as unknown as QueryRow[][])[0])[0]
    if (!headerRow) return null
    const [headerWithMeta] = await enrichInvDocumentosCompraMeta([mapInvDocumentoRow(headerRow)])
    return {
      header: headerWithMeta,
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "O")
      .input("IdDocumento", id)
      .execute("dbo.spInvDocumentosCRUD")
    const headerRow = ((result.recordsets as unknown as QueryRow[][])[0])[0]
    if (!headerRow) return null
    const [headerWithMeta] = await enrichInvDocumentosCompraMeta([mapInvDocumentoRow(headerRow)])
    return {
      header: headerWithMeta,
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  }
}

export async function getInvDocumentoDetalleHistory(idDocumento: number): Promise<InvDocumentoDetalleHistoryRecord[]> {
  const pool = await getPool()

  const query = `
    SELECT
      det.IdDetalle,
      det.NumeroLinea,
      det.IdProducto,
      det.Codigo,
      det.Descripcion,
      det.IdUnidadMedida,
      det.NombreUnidad,
      det.Cantidad,
      det.Costo,
      det.Total,
      det.RowStatus,
      det.FechaCreacion,
      det.UsuarioCreacion,
      CONCAT(ISNULL(u.Nombres, ''), CASE WHEN ISNULL(u.Apellidos, '') <> '' THEN ' ' + u.Apellidos ELSE '' END) AS UsuarioCreacionNombre
    FROM dbo.InvDocumentoDetalle det
    LEFT JOIN dbo.Usuarios u ON u.IdUsuario = det.UsuarioCreacion
    WHERE det.IdDocumento = @IdDocumento
    ORDER BY det.FechaCreacion DESC, det.NumeroLinea ASC, det.IdDetalle DESC;
  `

  try {
    const result = await pool.request()
      .input("IdDocumento", sql.Int, idDocumento)
      .query(query)
    return (result.recordset as QueryRow[]).map(mapInvDocDetalleHistoryRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("IdDocumento", idDocumento)
      .query(query)
    return (result.recordset as QueryRow[]).map(mapInvDocDetalleHistoryRow)
  }
}

export async function createInvDocumento(
  input: {
    idTipoDocumento: number
    fecha: string
    idAlmacen: number
    idMoneda?: number | null
    tasaCambio?: number
    referencia?: string
    observacion?: string
    idProveedor?: number | null
    noFactura?: string | null
    ncf?: string | null
    fechaFactura?: string | null
    lineas: Array<{
      linea: number
      idProducto: number
      codigo: string
      descripcion: string
      idUnidadMedida: number | null
      unidad: string
      cantidad: number
      costo: number
    }>
  },
  session?: SessionContext,
): Promise<{ header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] }> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const detalleJSON = JSON.stringify(input.lineas)

  function build(r: ReturnType<typeof pool.request>, typed: boolean) {
    r.input("Accion", "I")
    if (typed) {
      r.input("IdTipoDocumento", sql.Int, input.idTipoDocumento)
      r.input("Fecha", sql.Date, input.fecha)
      r.input("IdAlmacen", sql.Int, input.idAlmacen)
      r.input("IdMoneda", sql.Int, input.idMoneda ?? null)
      r.input("TasaCambio", sql.Decimal(18, 6), input.tasaCambio ?? 1)
      r.input("Referencia", sql.NVarChar(250), input.referencia ?? null)
      r.input("Observacion", sql.NVarChar(500), input.observacion ?? null)
      r.input("DetalleJSON", sql.NVarChar(sql.MAX), detalleJSON)
      r.input("IdUsuario", sql.Int, uid)
      r.input("IdSesion", sql.Int, session?.sessionId ?? null)
    } else {
      r.input("IdTipoDocumento", input.idTipoDocumento)
      r.input("Fecha", input.fecha)
      r.input("IdAlmacen", input.idAlmacen)
      r.input("IdMoneda", input.idMoneda ?? null)
      r.input("TasaCambio", input.tasaCambio ?? 1)
      r.input("Referencia", input.referencia ?? null)
      r.input("Observacion", input.observacion ?? null)
      r.input("DetalleJSON", detalleJSON)
      r.input("IdUsuario", uid)
      r.input("IdSesion", session?.sessionId ?? null)
    }
    return r
  }

  try {
    const result = await build(pool.request(), true).execute("dbo.spInvDocumentosCRUD")
    const headerRow = ((result.recordsets as unknown as QueryRow[][])[0])[0]
    if (!headerRow) throw new Error("createInvDocumento: SP no devolvio registro")
    await saveInvDocumentoCompraMeta(toNumber(headerRow.IdDocumento), input, uid)
    const [headerWithMeta] = await enrichInvDocumentosCompraMeta([mapInvDocumentoRow(headerRow)])
    return {
      header: headerWithMeta,
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await build(pool.request(), false).execute("dbo.spInvDocumentosCRUD")
    const headerRow = ((result.recordsets as unknown as QueryRow[][])[0])[0]
    if (!headerRow) throw new Error("createInvDocumento: SP no devolvio registro")
    await saveInvDocumentoCompraMeta(toNumber(headerRow.IdDocumento), input, uid)
    const [headerWithMeta] = await enrichInvDocumentosCompraMeta([mapInvDocumentoRow(headerRow)])
    return {
      header: headerWithMeta,
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  }
}

export async function updateInvDocumento(
  idDocumento: number,
  input: {
    idTipoDocumento: number
    fecha: string
    idAlmacen: number
    idMoneda?: number | null
    tasaCambio?: number
    referencia?: string
    observacion?: string
    idProveedor?: number | null
    noFactura?: string | null
    ncf?: string | null
    fechaFactura?: string | null
    lineas: Array<{
      linea: number
      idProducto: number
      codigo: string
      descripcion: string
      idUnidadMedida: number | null
      unidad: string
      cantidad: number
      costo: number
    }>
  },
  session?: SessionContext,
): Promise<{ header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] }> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const detalleJSON = JSON.stringify(input.lineas)

  function build(r: ReturnType<typeof pool.request>, typed: boolean) {
    if (typed) {
      r.input("IdDocumento", sql.Int, idDocumento)
      r.input("IdTipoDocumento", sql.Int, input.idTipoDocumento)
      r.input("Fecha", sql.Date, input.fecha)
      r.input("IdAlmacen", sql.Int, input.idAlmacen)
      r.input("IdMoneda", sql.Int, input.idMoneda ?? null)
      r.input("TasaCambio", sql.Decimal(18, 6), input.tasaCambio ?? 1)
      r.input("Referencia", sql.NVarChar(250), input.referencia ?? null)
      r.input("Observacion", sql.NVarChar(500), input.observacion ?? null)
      r.input("DetalleJSON", sql.NVarChar(sql.MAX), detalleJSON)
      r.input("IdUsuario", sql.Int, uid)
      r.input("IdSesion", sql.Int, session?.sessionId ?? null)
    } else {
      r.input("IdDocumento", idDocumento)
      r.input("IdTipoDocumento", input.idTipoDocumento)
      r.input("Fecha", input.fecha)
      r.input("IdAlmacen", input.idAlmacen)
      r.input("IdMoneda", input.idMoneda ?? null)
      r.input("TasaCambio", input.tasaCambio ?? 1)
      r.input("Referencia", input.referencia ?? null)
      r.input("Observacion", input.observacion ?? null)
      r.input("DetalleJSON", detalleJSON)
      r.input("IdUsuario", uid)
      r.input("IdSesion", session?.sessionId ?? null)
    }
    return r
  }

  try {
    const result = await build(pool.request(), true).execute("dbo.spInvActualizarDocumento")
    const headerRow = ((result.recordsets as unknown as QueryRow[][])[0])[0]
    if (!headerRow) throw new Error("updateInvDocumento: SP no devolvio registro")
    await saveInvDocumentoCompraMeta(idDocumento, input, uid)
    const [headerWithMeta] = await enrichInvDocumentosCompraMeta([mapInvDocumentoRow(headerRow)])
    return {
      header: headerWithMeta,
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await build(pool.request(), false).execute("dbo.spInvActualizarDocumento")
    const headerRow = ((result.recordsets as unknown as QueryRow[][])[0])[0]
    if (!headerRow) throw new Error("updateInvDocumento: SP no devolvio registro")
    await saveInvDocumentoCompraMeta(idDocumento, input, uid)
    const [headerWithMeta] = await enrichInvDocumentosCompraMeta([mapInvDocumentoRow(headerRow)])
    return {
      header: headerWithMeta,
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  }
}

export async function anularInvDocumento(id: number, session?: SessionContext): Promise<{ header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] }> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  try {
    const result = await pool.request()
      .input("Accion", "N")
      .input("IdDocumento", sql.Int, id)
      .input("IdUsuario", sql.Int, uid)
      .input("IdSesion", sql.Int, session?.sessionId ?? null)
      .execute("dbo.spInvDocumentosCRUD")
    return {
      header: mapInvDocumentoRow(((result.recordsets as unknown as QueryRow[][])[0])[0]),
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "N")
      .input("IdDocumento", id)
      .input("IdUsuario", uid)
      .input("IdSesion", session?.sessionId ?? null)
      .execute("dbo.spInvDocumentosCRUD")
    return {
      header: mapInvDocumentoRow(((result.recordsets as unknown as QueryRow[][])[0])[0]),
      lines: ((result.recordsets as unknown as QueryRow[][])[1]).map(mapInvDocDetalleRow),
    }
  }
}

type InvTransferenciaLineaInput = {
  linea: number
  idProducto: number
  codigo: string
  descripcion: string
  idUnidadMedida: number | null
  unidad: string
  cantidad: number
  costo: number
}

type InvTransferenciaInput = {
  idTipoDocumento: number
  fecha: string
  idAlmacen: number
  idAlmacenDestino: number
  referencia?: string
  observacion?: string
  lineas: InvTransferenciaLineaInput[]
}

function applyInvTransferenciaMutateInputs(
  req: ReturnType<Awaited<ReturnType<typeof getPool>>["request"]>,
  input: InvTransferenciaInput,
  detalleJSON: string,
  uid: number,
  session: SessionContext | undefined,
  typed: boolean,
  idDocumento?: number,
) {
  if (idDocumento != null) {
    if (typed) req.input("IdDocumento", sql.Int, idDocumento)
    else req.input("IdDocumento", idDocumento)
  }

  if (typed) {
    req.input("IdTipoDocumento", sql.Int, input.idTipoDocumento)
    req.input("Fecha", sql.Date, input.fecha)
    req.input("IdAlmacen", sql.Int, input.idAlmacen)
    req.input("IdAlmacenDestino", sql.Int, input.idAlmacenDestino)
    req.input("Referencia", sql.NVarChar(250), input.referencia ?? null)
    req.input("Observacion", sql.NVarChar(500), input.observacion ?? null)
    req.input("DetalleJSON", sql.NVarChar(sql.MAX), detalleJSON)
    req.input("IdUsuario", sql.Int, uid)
    req.input("IdSesion", sql.Int, session?.sessionId ?? null)
  } else {
    req.input("IdTipoDocumento", input.idTipoDocumento)
    req.input("Fecha", input.fecha)
    req.input("IdAlmacen", input.idAlmacen)
    req.input("IdAlmacenDestino", input.idAlmacenDestino)
    req.input("Referencia", input.referencia ?? null)
    req.input("Observacion", input.observacion ?? null)
    req.input("DetalleJSON", detalleJSON)
    req.input("IdUsuario", uid)
    req.input("IdSesion", session?.sessionId ?? null)
  }
}

async function executeInvTransferenciaAction(
  accion: "GS" | "CR" | "N",
  idDocumento: number,
  session?: SessionContext,
): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")

  try {
    const result = await pool.request()
      .input("Accion", accion)
      .input("IdDocumento", sql.Int, idDocumento)
      .input("IdUsuario", sql.Int, uid)
      .input("IdSesion", sql.Int, session?.sessionId ?? null)
      .execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow((sets[0] ?? [])[0])])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", accion)
      .input("IdDocumento", idDocumento)
      .input("IdUsuario", uid)
      .input("IdSesion", session?.sessionId ?? null)
      .execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow((sets[0] ?? [])[0])])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  }
}

export async function listInvTransferencias(filters: {
  idAlmacen?: number
  idAlmacenDestino?: number
  idTipoDocumento?: number
  estadoTransferencia?: InvTransferenciaEstado
  fechaDesde?: string
  fechaHasta?: string
  page?: number
  pageSize?: number
}): Promise<InvTransferenciasListResult> {
  const pool = await getPool()
  const page = filters.page && filters.page > 0 ? filters.page : 1
  const pageSize = filters.pageSize && filters.pageSize > 0 ? filters.pageSize : 20

  async function mapList(recordset: QueryRow[]): Promise<InvTransferenciasListResult> {
    const items = await enrichInvTransferenciasMeta(recordset.map(mapInvTransferenciaRow))
    const totalRaw = recordset[0]?.TotalRows
    const total = totalRaw != null ? Number(totalRaw) : items.length
    return { items, total, page, pageSize }
  }

  try {
    const req = pool.request().input("Accion", "L")
    if (filters.idAlmacen) req.input("IdAlmacen", sql.Int, filters.idAlmacen)
    if (filters.idAlmacenDestino) req.input("IdAlmacenDestino", sql.Int, filters.idAlmacenDestino)
    if (filters.idTipoDocumento) req.input("IdTipoDocumento", sql.Int, filters.idTipoDocumento)
    if (filters.estadoTransferencia) req.input("EstadoTransferencia", sql.Char(1), filters.estadoTransferencia)
    if (filters.fechaDesde) req.input("FechaDesde", sql.Date, filters.fechaDesde)
    if (filters.fechaHasta) req.input("FechaHasta", sql.Date, filters.fechaHasta)
    req.input("NumeroPagina", sql.Int, page)
    req.input("TamanoPagina", sql.Int, pageSize)
    const result = await req.execute("dbo.spInvTransferenciasCRUD")
    return await mapList(result.recordset as QueryRow[])
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("Accion", "L")
    if (filters.idAlmacen) req.input("IdAlmacen", filters.idAlmacen)
    if (filters.idAlmacenDestino) req.input("IdAlmacenDestino", filters.idAlmacenDestino)
    if (filters.idTipoDocumento) req.input("IdTipoDocumento", filters.idTipoDocumento)
    if (filters.estadoTransferencia) req.input("EstadoTransferencia", filters.estadoTransferencia)
    if (filters.fechaDesde) req.input("FechaDesde", filters.fechaDesde)
    if (filters.fechaHasta) req.input("FechaHasta", filters.fechaHasta)
    req.input("NumeroPagina", page)
    req.input("TamanoPagina", pageSize)
    const result = await req.execute("dbo.spInvTransferenciasCRUD")
    return await mapList(result.recordset as QueryRow[])
  }
}

export async function getInvTransferencia(id: number): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] } | null> {
  const pool = await getPool()

  try {
    const result = await pool.request()
      .input("Accion", "O")
      .input("IdDocumento", sql.Int, id)
      .execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const headerRow = (sets[0] ?? [])[0]
    if (!headerRow) return null
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow(headerRow)])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "O")
      .input("IdDocumento", id)
      .execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const headerRow = (sets[0] ?? [])[0]
    if (!headerRow) return null
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow(headerRow)])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  }
}

export async function createInvTransferencia(
  input: InvTransferenciaInput,
  session?: SessionContext,
): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const detalleJSON = JSON.stringify(input.lineas)

  try {
    const req = pool.request().input("Accion", "I")
    applyInvTransferenciaMutateInputs(req, input, detalleJSON, uid, session, true)
    const result = await req.execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow((sets[0] ?? [])[0])])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("Accion", "I")
    applyInvTransferenciaMutateInputs(req, input, detalleJSON, uid, session, false)
    const result = await req.execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow((sets[0] ?? [])[0])])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  }
}

export async function updateInvTransferencia(
  id: number,
  input: InvTransferenciaInput,
  session?: SessionContext,
): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const detalleJSON = JSON.stringify(input.lineas)

  try {
    const req = pool.request().input("Accion", "U")
    applyInvTransferenciaMutateInputs(req, input, detalleJSON, uid, session, true, id)
    const result = await req.execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow((sets[0] ?? [])[0])])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("Accion", "U")
    applyInvTransferenciaMutateInputs(req, input, detalleJSON, uid, session, false, id)
    const result = await req.execute("dbo.spInvTransferenciasCRUD")
    const sets = result.recordsets as unknown as QueryRow[][]
    const [header] = await enrichInvTransferenciasMeta([mapInvTransferenciaRow((sets[0] ?? [])[0])])
    return {
      header,
      lines: (sets[1] ?? []).map(mapInvDocDetalleRow),
    }
  }
}

export async function generarSalidaTransferencia(
  idDocumento: number,
  session?: SessionContext,
): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }> {
  return executeInvTransferenciaAction("GS", idDocumento, session)
}

export async function confirmarRecepcionTransferencia(
  idDocumento: number,
  session?: SessionContext,
): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }> {
  return executeInvTransferenciaAction("CR", idDocumento, session)
}

export async function anularTransferencia(
  idDocumento: number,
  session?: SessionContext,
): Promise<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }> {
  return executeInvTransferenciaAction("N", idDocumento, session)
}

export async function getInvTiposDocumentoParaUsuario(tipoOperacion: InvTipoOperacion, userId: number): Promise<InvTipoDocumentoRecord[]> {
  const pool = await getPool()
  try {
    const result = await pool.request()
      .input("Accion", "LT")
      .input("TipoOperacion", sql.Char(1), tipoOperacion)
      .input("IdUsuario", sql.Int, userId)
      .execute("dbo.spInvDocumentosCRUD")
    return (result.recordset as QueryRow[]).map(mapInvTipoDocRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Accion", "LT")
      .input("TipoOperacion", tipoOperacion)
      .input("IdUsuario", userId)
      .execute("dbo.spInvDocumentosCRUD")
    return (result.recordset as QueryRow[]).map(mapInvTipoDocRow)
  }
}

export async function searchInvProducto(busqueda: string, idAlmacen?: number): Promise<InvProductoParaDocumento[]> {
  const pool = await getPool()
  try {
    const req = pool.request()
      .input("Modo", sql.Char(1), "P")
      .input("Busqueda", sql.NVarChar(100), busqueda)
    if (idAlmacen) req.input("IdAlmacen", sql.Int, idAlmacen)
    const result = await req.execute("dbo.spInvBuscarProducto")
    return (result.recordset as QueryRow[]).map(mapInvProductoParaDocRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request()
      .input("Modo", "P")
      .input("Busqueda", busqueda)
    if (idAlmacen) req.input("IdAlmacen", idAlmacen)
    const result = await req.execute("dbo.spInvBuscarProducto")
    return (result.recordset as QueryRow[]).map(mapInvProductoParaDocRow)
  }
}

export async function getInvProductoPorCodigo(codigo: string, idAlmacen?: number): Promise<InvProductoParaDocumento | null> {
  const pool = await getPool()
  try {
    const req = pool.request()
      .input("Modo", sql.Char(1), "E")
      .input("Busqueda", sql.NVarChar(100), codigo)
    if (idAlmacen) req.input("IdAlmacen", sql.Int, idAlmacen)
    const result = await req.execute("dbo.spInvBuscarProducto")
    const row = (result.recordset as QueryRow[])[0]
    return row ? mapInvProductoParaDocRow(row) : null
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request()
      .input("Modo", "E")
      .input("Busqueda", codigo)
    if (idAlmacen) req.input("IdAlmacen", idAlmacen)
    const result = await req.execute("dbo.spInvBuscarProducto")
    const row = (result.recordset as QueryRow[])[0]
    return row ? mapInvProductoParaDocRow(row) : null
  }
}

function mapInvKardexRow(row: QueryRow): InvKardexRecord {
  return {
    idMovimiento: toNumber(row.IdMovimiento),
    fecha: toIsoDate(row.Fecha),
    tipoMovimiento: toText(row.TipoMovimiento),
    numeroDocumento: toText(row.NumeroDocumento),
    observacion: toText(row.Observacion),
    entrada: Number(row.Entrada ?? 0),
    salida: Number(row.Salida ?? 0),
    saldo: Number(row.Saldo ?? 0),
    costoUnitario: Number(row.CostoUnitario ?? 0),
    costoTotal: Number(row.CostoTotal ?? 0),
    costoPromedio: Number(row.CostoPromedio ?? 0),
    nombreAlmacen: toText(row.NombreAlmacen),
  }
}

function mapInvMovimientoRow(row: QueryRow): InvMovimientoRecord {
  return {
    idMovimiento: toNumber(row.IdMovimiento),
    fecha: toIsoDate(row.Fecha),
    tipoMovimiento: toText(row.TipoMovimiento),
    numeroDocumento: toText(row.NumeroDocumento),
    observacion: toText(row.Observacion),
    entrada: Number(row.Entrada ?? 0),
    salida: Number(row.Salida ?? 0),
    costoUnitario: Number(row.CostoUnitario ?? 0),
    costoTotal: Number(row.CostoTotal ?? 0),
    nombreAlmacen: toText(row.NombreAlmacen),
  }
}

function mapInvExistenciaAlFechaRow(row: QueryRow): InvExistenciaAlFechaRecord {
  return {
    idProducto: toNumber(row.IdProducto),
    nombreProducto: toText(row.NombreProducto),
    idAlmacen: toNumber(row.IdAlmacen),
    nombreAlmacen: toText(row.NombreAlmacen),
    fechaConsulta: toIsoDate(row.FechaConsulta),
    existencia: Number(row.Existencia ?? 0),
    costoPromedio: Number(row.CostoPromedio ?? 0),
  }
}

export async function getInvKardex(
  idProducto: number,
  idAlmacen?: number,
  fechaDesde?: string,
  fechaHasta?: string,
): Promise<InvKardexRecord[]> {
  const pool = await getPool()
  try {
    const req = pool.request().input("IdProducto", sql.Int, idProducto)
    if (idAlmacen) req.input("IdAlmacen", sql.Int, idAlmacen)
    if (fechaDesde) req.input("FechaDesde", sql.Date, fechaDesde)
    if (fechaHasta) req.input("FechaHasta", sql.Date, fechaHasta)
    const result = await req.execute("dbo.spInvKardex")
    return (result.recordset as QueryRow[]).map(mapInvKardexRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("IdProducto", idProducto)
    if (idAlmacen) req.input("IdAlmacen", idAlmacen)
    if (fechaDesde) req.input("FechaDesde", fechaDesde)
    if (fechaHasta) req.input("FechaHasta", fechaHasta)
    const result = await req.execute("dbo.spInvKardex")
    return (result.recordset as QueryRow[]).map(mapInvKardexRow)
  }
}

export async function getInvMovimientos(
  idProducto: number,
  idAlmacen?: number,
  fechaDesde?: string,
  fechaHasta?: string,
): Promise<InvMovimientoRecord[]> {
  const pool = await getPool()
  try {
    const req = pool.request().input("IdProducto", sql.Int, idProducto)
    req.input("IdAlmacen", sql.Int, idAlmacen ?? null)
    req.input("FechaDesde", sql.Date, fechaDesde ?? null)
    req.input("FechaHasta", sql.Date, fechaHasta ?? null)
    const result = await req.execute("dbo.spInvMovimientos")
    return (result.recordset as QueryRow[]).map(mapInvMovimientoRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("IdProducto", idProducto)
    req.input("IdAlmacen", idAlmacen ?? null)
    req.input("FechaDesde", fechaDesde ?? null)
    req.input("FechaHasta", fechaHasta ?? null)
    const result = await req.execute("dbo.spInvMovimientos")
    return (result.recordset as QueryRow[]).map(mapInvMovimientoRow)
  }
}

export async function ejecutarCierreMensual(periodo: string): Promise<{ periodo: string; registrosCerrados: number }> {
  const pool = await getPool()
  try {
    const result = await pool.request()
      .input("Periodo", sql.VarChar(6), periodo)
      .execute("dbo.spInvCierreMensual")
    const row = (result.recordset as QueryRow[])[0]
    return {
      periodo: toText(row?.Periodo, periodo),
      registrosCerrados: toNumber(row?.RegistrosCerrados),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool.request()
      .input("Periodo", periodo)
      .execute("dbo.spInvCierreMensual")
    const row = (result.recordset as QueryRow[])[0]
    return {
      periodo: toText(row?.Periodo, periodo),
      registrosCerrados: toNumber(row?.RegistrosCerrados),
    }
  }
}

export async function getExistenciaAlFecha(
  fecha: string,
  idProducto?: number,
  idAlmacen?: number,
): Promise<InvExistenciaAlFechaRecord[]> {
  const pool = await getPool()
  try {
    const req = pool.request().input("Fecha", sql.Date, fecha)
    if (idProducto) req.input("IdProducto", sql.Int, idProducto)
    if (idAlmacen) req.input("IdAlmacen", sql.Int, idAlmacen)
    const result = await req.execute("dbo.spInvExistenciaAlFecha")
    return (result.recordset as QueryRow[]).map(mapInvExistenciaAlFechaRow)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const req = pool.request().input("Fecha", fecha)
    if (idProducto) req.input("IdProducto", idProducto)
    if (idAlmacen) req.input("IdAlmacen", idAlmacen)
    const result = await req.execute("dbo.spInvExistenciaAlFecha")
    return (result.recordset as QueryRow[]).map(mapInvExistenciaAlFechaRow)
  }
}

// ============================================================================
// TIPOS: DIVISION DE CUENTAS
// ============================================================================

export type OrdenCuenta = {
  idOrdenCuenta: number
  idOrden: number
  numeroCuenta: number
  nombre: string | null
  subtotal: number
  impuesto: number
  descuento: number
  propina: number
  total: number
  nombreEstado: string
  fechaCreacion: string
  usuarioCreacion: number | null
}

export type OrdenCuentaDetalleItem = {
  idOrdenCuentaDetalle: number
  idOrdenDetalle: number
  cantidadAsignada: number
  cantidad: number
  precioUnitario: number
  porcentajeImpuesto: number
  subtotalLinea: number
  montoImpuesto: number
  totalLinea: number
  codigo: string
  descripcion: string
}

export type OrdenCuentaMovimiento = {
  idOrdenCuentaMovimiento: number
  idOrdenCuenta: number
  idOrden: number
  tipoMovimiento: string
  observacion: string | null
  fechaMovimiento: string
  usuarioMovimiento: number | null
}

export type OrdenCuentaPrefactura = {
  idOrdenCuenta: number
  idOrden: number
  numeroCuenta: number
  nombre: string | null
  numeroOrden: string
  referenciaCliente: string
  nombreMesa: string
  subtotal: number
  impuesto: number
  descuento: number
  propina: number
  total: number
  estadoCuenta: string
  fechaCreacion: string
  usuarioCreacion: string | null
  detalle: OrdenCuentaDetalleItem[]
}

// ============================================================================
// FUNCIONES: DIVISION DE CUENTAS
// ============================================================================

function getOrderAccountActor(userId?: number, session?: SessionContext) {
  return { userId: userId || 0, sessionId: session?.sessionId || 0, token: session?.token || "" }
}

export async function listOrdenCuentas(idOrden: number): Promise<OrdenCuenta[]> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "L")
      .input("IdOrden", sql.Int, idOrden)
      .execute("dbo.spOrdenCuentasCRUD")
    return (result.recordset as QueryRow[]).map((row) => ({
      idOrdenCuenta: Number(row.IdOrdenCuenta),
      idOrden: Number(row.IdOrden),
      numeroCuenta: Number(row.NumeroCuenta),
      nombre: (row.Nombre as string | null) ?? null,
      subtotal: Number(row.Subtotal ?? 0),
      impuesto: Number(row.Impuesto ?? 0),
      descuento: Number(row.Descuento ?? 0),
      propina: Number(row.Propina ?? 0),
      total: Number(row.Total ?? 0),
      nombreEstado: (row.NombreEstado as string) ?? "",
      fechaCreacion: (row.FechaCreacion as string) ?? "",
      usuarioCreacion: (row.UsuarioCreacion as number | null) ?? null,
    })) as OrdenCuenta[]
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "L")
      .input("IdOrden", idOrden)
      .execute("dbo.spOrdenCuentasCRUD")
    return (result.recordset as QueryRow[]).map((row) => ({
      idOrdenCuenta: Number(row.IdOrdenCuenta),
      idOrden: Number(row.IdOrden),
      numeroCuenta: Number(row.NumeroCuenta),
      nombre: (row.Nombre as string | null) ?? null,
      subtotal: Number(row.Subtotal ?? 0),
      impuesto: Number(row.Impuesto ?? 0),
      descuento: Number(row.Descuento ?? 0),
      propina: Number(row.Propina ?? 0),
      total: Number(row.Total ?? 0),
      nombreEstado: (row.NombreEstado as string) ?? "",
      fechaCreacion: (row.FechaCreacion as string) ?? "",
      usuarioCreacion: (row.UsuarioCreacion as number | null) ?? null,
    })) as OrdenCuenta[]
  }
}

export async function getOrdenCuenta(idOrdenCuenta: number): Promise<OrdenCuenta | null> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "O")
      .input("IdOrdenCuenta", sql.Int, idOrdenCuenta)
      .execute("dbo.spOrdenCuentasCRUD")
    const row = result.recordset[0] as QueryRow | undefined
    if (!row) return null
    return {
      idOrdenCuenta: Number(row.IdOrdenCuenta),
      idOrden: Number(row.IdOrden),
      numeroCuenta: Number(row.NumeroCuenta),
      nombre: (row.Nombre as string | null) ?? null,
      subtotal: Number(row.Subtotal ?? 0),
      impuesto: Number(row.Impuesto ?? 0),
      descuento: Number(row.Descuento ?? 0),
      propina: Number(row.Propina ?? 0),
      total: Number(row.Total ?? 0),
      nombreEstado: (row.NombreEstado as string) ?? "",
      fechaCreacion: (row.FechaCreacion as string) ?? "",
      usuarioCreacion: (row.UsuarioCreacion as number | null) ?? null,
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "O")
      .input("IdOrdenCuenta", idOrdenCuenta)
      .execute("dbo.spOrdenCuentasCRUD")
    const row = result.recordset[0] as QueryRow | undefined
    if (!row) return null
    return {
      idOrdenCuenta: Number(row.IdOrdenCuenta),
      idOrden: Number(row.IdOrden),
      numeroCuenta: Number(row.NumeroCuenta),
      nombre: (row.Nombre as string | null) ?? null,
      subtotal: Number(row.Subtotal ?? 0),
      impuesto: Number(row.Impuesto ?? 0),
      descuento: Number(row.Descuento ?? 0),
      propina: Number(row.Propina ?? 0),
      total: Number(row.Total ?? 0),
      nombreEstado: (row.NombreEstado as string) ?? "",
      fechaCreacion: (row.FechaCreacion as string) ?? "",
      usuarioCreacion: (row.UsuarioCreacion as number | null) ?? null,
    }
  }
}

export async function createOrdenCuenta(
  idOrden: number,
  numeroCuenta: number,
  nombre: string | null,
  userId?: number,
  session?: SessionContext,
): Promise<number> {
  const actor = getOrderAccountActor(userId, session)
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("IdOrden", sql.Int, idOrden)
      .input("NumeroCuenta", sql.Int, numeroCuenta)
      .input("Nombre", sql.VarChar(100), nombre || null)
      .input("IdEstadoCuenta", sql.Int, 1) // Abierta
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenCuentasCRUD")
    return Number((result.recordset[0] as QueryRow).IdOrdenCuenta)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("IdOrden", idOrden)
      .input("NumeroCuenta", numeroCuenta)
      .input("Nombre", nombre || null)
      .input("IdEstadoCuenta", 1)
      .input("UsuarioModificacion", actor.userId)
      .execute("dbo.spOrdenCuentasCRUD")
    return Number((result.recordset[0] as QueryRow).IdOrdenCuenta)
  }
}

export async function updateOrdenCuenta(
  idOrdenCuenta: number,
  updates: { nombre?: string | null; idEstadoCuenta?: number },
  userId?: number,
  session?: SessionContext,
): Promise<void> {
  const actor = getOrderAccountActor(userId, session)
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "A")
      .input("IdOrdenCuenta", sql.Int, idOrdenCuenta)
      .input("Nombre", sql.VarChar(100), updates.nombre ?? null)
      .input("IdEstadoCuenta", sql.Int, updates.idEstadoCuenta ?? null)
      .input("UsuarioModificacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenCuentasCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "A")
      .input("IdOrdenCuenta", idOrdenCuenta)
      .input("Nombre", updates.nombre ?? null)
      .input("IdEstadoCuenta", updates.idEstadoCuenta ?? null)
      .input("UsuarioModificacion", actor.userId)
      .execute("dbo.spOrdenCuentasCRUD")
  }
}

export async function listOrdenCuentaDetalle(idOrdenCuenta: number): Promise<OrdenCuentaDetalleItem[]> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "L")
      .input("IdOrdenCuenta", sql.Int, idOrdenCuenta)
      .execute("dbo.spOrdenCuentaDetalleCRUD")
    return (result.recordset as QueryRow[]).map((row) => ({
      idOrdenCuentaDetalle: Number(row.IdOrdenCuentaDetalle),
      idOrdenDetalle: Number(row.IdOrdenDetalle),
      cantidadAsignada: Number(row.CantidadAsignada ?? 0),
      cantidad: Number(row.Cantidad ?? 0),
      precioUnitario: Number(row.PrecioUnitario ?? 0),
      porcentajeImpuesto: Number(row.PorcentajeImpuesto ?? 0),
      subtotalLinea: Number(row.SubtotalLinea ?? 0),
      montoImpuesto: Number(row.MontoImpuesto ?? 0),
      totalLinea: Number(row.TotalLinea ?? 0),
      codigo: (row.Codigo as string) ?? "",
      descripcion: (row.Descripcion as string) ?? "",
    }))
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "L")
      .input("IdOrdenCuenta", idOrdenCuenta)
      .execute("dbo.spOrdenCuentaDetalleCRUD")
    return (result.recordset as QueryRow[]).map((row) => ({
      idOrdenCuentaDetalle: Number(row.IdOrdenCuentaDetalle),
      idOrdenDetalle: Number(row.IdOrdenDetalle),
      cantidadAsignada: Number(row.CantidadAsignada ?? 0),
      cantidad: Number(row.Cantidad ?? 0),
      precioUnitario: Number(row.PrecioUnitario ?? 0),
      porcentajeImpuesto: Number(row.PorcentajeImpuesto ?? 0),
      subtotalLinea: Number(row.SubtotalLinea ?? 0),
      montoImpuesto: Number(row.MontoImpuesto ?? 0),
      totalLinea: Number(row.TotalLinea ?? 0),
      codigo: (row.Codigo as string) ?? "",
      descripcion: (row.Descripcion as string) ?? "",
    }))
  }
}

export async function splitOrdenCuentas(
  idOrden: number,
  modoDivision: "PERSONA" | "EQUITATIVA" | "ITEM" | "UNIFICAR",
  cantidadSubcuentas?: number,
  payloadJson?: string,
  observacion?: string,
  userId?: number,
  session?: SessionContext,
): Promise<void> {
  const actor = getOrderAccountActor(userId, session)
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("IdOrden", sql.Int, idOrden)
      .input("ModoDivision", modoDivision)
      .input("CantidadSubcuentas", sql.Int, cantidadSubcuentas ?? null)
      .input("PayloadJson", sql.NVarChar(sql.MAX), payloadJson ?? null)
      .input("Observacion", sql.VarChar(500), observacion ?? null)
      .input("UsuarioCreacion", sql.Int, actor.userId)
      .execute("dbo.spOrdenCuentasDividir")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("IdOrden", idOrden)
      .input("ModoDivision", modoDivision)
      .input("CantidadSubcuentas", cantidadSubcuentas ?? null)
      .input("PayloadJson", payloadJson ?? null)
      .input("Observacion", observacion ?? null)
      .input("UsuarioCreacion", actor.userId)
      .execute("dbo.spOrdenCuentasDividir")
  }
}

export async function getOrdenCuentaPrefactura(idOrdenCuenta: number): Promise<OrdenCuentaPrefactura | null> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("IdOrdenCuenta", sql.Int, idOrdenCuenta)
      .execute("dbo.spOrdenCuentasPrefactura")

    const sets = result.recordsets as unknown as QueryRow[][]
    const headerRow = (sets[0] ?? [])[0]
    if (!headerRow) return null

    const detalleRows = (sets[1] ?? []) as QueryRow[]

    return {
      idOrdenCuenta: Number(headerRow.IdOrdenCuenta),
      idOrden: Number(headerRow.IdOrden),
      numeroCuenta: Number(headerRow.NumeroCuenta),
      nombre: (headerRow.Nombre as string | null) ?? null,
      numeroOrden: (headerRow.NumeroOrden as string) ?? "",
      referenciaCliente: (headerRow.ReferenciaCliente as string) ?? "",
      nombreMesa: (headerRow.NombreMesa as string) ?? "",
      subtotal: Number(headerRow.Subtotal ?? 0),
      impuesto: Number(headerRow.Impuesto ?? 0),
      descuento: Number(headerRow.Descuento ?? 0),
      propina: Number(headerRow.Propina ?? 0),
      total: Number(headerRow.Total ?? 0),
      estadoCuenta: (headerRow.EstadoCuenta as string) ?? "",
      fechaCreacion: (headerRow.FechaCreacion as string) ?? "",
      usuarioCreacion: (headerRow.UsuarioCreacion as string | null) ?? null,
      detalle: detalleRows.map((row) => ({
        idOrdenCuentaDetalle: 0,
        idOrdenDetalle: 0,
        cantidadAsignada: Number(row.CantidadAsignada ?? 0),
        cantidad: Number(row.CantidadAsignada ?? 0),
        precioUnitario: 0,
        porcentajeImpuesto: 0,
        subtotalLinea: Number(row.SubtotalLinea ?? 0),
        montoImpuesto: Number(row.MontoImpuesto ?? 0),
        totalLinea: Number(row.TotalLinea ?? 0),
        codigo: (row.Codigo as string) ?? "",
        descripcion: (row.Descripcion as string) ?? "",
      })),
    }
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("IdOrdenCuenta", idOrdenCuenta)
      .execute("dbo.spOrdenCuentasPrefactura")

    const sets = result.recordsets as unknown as QueryRow[][]
    const headerRow = (sets[0] ?? [])[0]
    if (!headerRow) return null

    const detalleRows = (sets[1] ?? []) as QueryRow[]

    return {
      idOrdenCuenta: Number(headerRow.IdOrdenCuenta),
      idOrden: Number(headerRow.IdOrden),
      numeroCuenta: Number(headerRow.NumeroCuenta),
      nombre: (headerRow.Nombre as string | null) ?? null,
      numeroOrden: (headerRow.NumeroOrden as string) ?? "",
      referenciaCliente: (headerRow.ReferenciaCliente as string) ?? "",
      nombreMesa: (headerRow.NombreMesa as string) ?? "",
      subtotal: Number(headerRow.Subtotal ?? 0),
      impuesto: Number(headerRow.Impuesto ?? 0),
      descuento: Number(headerRow.Descuento ?? 0),
      propina: Number(headerRow.Propina ?? 0),
      total: Number(headerRow.Total ?? 0),
      estadoCuenta: (headerRow.EstadoCuenta as string) ?? "",
      fechaCreacion: (headerRow.FechaCreacion as string) ?? "",
      usuarioCreacion: (headerRow.UsuarioCreacion as string | null) ?? null,
      detalle: detalleRows.map((row) => ({
        idOrdenCuentaDetalle: 0,
        idOrdenDetalle: 0,
        cantidadAsignada: Number(row.CantidadAsignada ?? 0),
        cantidad: Number(row.CantidadAsignada ?? 0),
        precioUnitario: 0,
        porcentajeImpuesto: 0,
        subtotalLinea: Number(row.SubtotalLinea ?? 0),
        montoImpuesto: Number(row.MontoImpuesto ?? 0),
        totalLinea: Number(row.TotalLinea ?? 0),
        codigo: (row.Codigo as string) ?? "",
        descripcion: (row.Descripcion as string) ?? "",
      })),
    }
  }
}

// ============================================================================
// FUNCIONES ADICIONALES: CRUD DE DETALLE Y ANULACION DE CUENTAS
// ============================================================================

export async function createOrdenCuentaDetalle(
  idOrdenCuenta: number,
  idOrdenDetalle: number,
  cantidadAsignada: number,
  userId?: number,
): Promise<number> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("IdOrdenCuenta", sql.Int, idOrdenCuenta)
      .input("IdOrdenDetalle", sql.Int, idOrdenDetalle)
      .input("CantidadAsignada", sql.Decimal(12, 2), cantidadAsignada)
      .input("UsuarioModificacion", sql.Int, userId || 0)
      .execute("dbo.spOrdenCuentaDetalleCRUD")

    const row = (result.recordset as QueryRow[])[0]
    return row ? Number(row.IdOrdenCuentaDetalle) : 0
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Accion", "I")
      .input("IdOrdenCuenta", idOrdenCuenta)
      .input("IdOrdenDetalle", idOrdenDetalle)
      .input("CantidadAsignada", cantidadAsignada)
      .input("UsuarioModificacion", userId || 0)
      .execute("dbo.spOrdenCuentaDetalleCRUD")

    const row = (result.recordset as QueryRow[])[0]
    return row ? Number(row.IdOrdenCuentaDetalle) : 0
  }
}

export async function updateOrdenCuentaDetalle(
  idOrdenCuentaDetalle: number,
  cantidadAsignada: number,
  userId?: number,
): Promise<void> {
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "A")
      .input("IdOrdenCuentaDetalle", sql.Int, idOrdenCuentaDetalle)
      .input("CantidadAsignada", sql.Decimal(12, 2), cantidadAsignada)
      .input("UsuarioModificacion", sql.Int, userId || 0)
      .execute("dbo.spOrdenCuentaDetalleCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "A")
      .input("IdOrdenCuentaDetalle", idOrdenCuentaDetalle)
      .input("CantidadAsignada", cantidadAsignada)
      .input("UsuarioModificacion", userId || 0)
      .execute("dbo.spOrdenCuentaDetalleCRUD")
  }
}

export async function deleteOrdenCuentaDetalle(
  idOrdenCuentaDetalle: number,
  userId?: number,
): Promise<void> {
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "D")
      .input("IdOrdenCuentaDetalle", sql.Int, idOrdenCuentaDetalle)
      .input("UsuarioModificacion", sql.Int, userId || 0)
      .execute("dbo.spOrdenCuentaDetalleCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "D")
      .input("IdOrdenCuentaDetalle", idOrdenCuentaDetalle)
      .input("UsuarioModificacion", userId || 0)
      .execute("dbo.spOrdenCuentaDetalleCRUD")
  }
}

export async function deleteOrdenCuenta(
  idOrdenCuenta: number,
  userId?: number,
  session?: SessionContext,
): Promise<void> {
  const pool = await getPool()
  try {
    await pool
      .request()
      .input("Accion", "X")
      .input("IdOrdenCuenta", sql.Int, idOrdenCuenta)
      .input("UsuarioModificacion", sql.Int, userId || 0)
      .execute("dbo.spOrdenCuentasCRUD")
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    await pool
      .request()
      .input("Accion", "X")
      .input("IdOrdenCuenta", idOrdenCuenta)
      .input("UsuarioModificacion", userId || 0)
      .execute("dbo.spOrdenCuentasCRUD")
  }
}

export async function getEstadoCuentaId(nombre: string): Promise<number> {
  const pool = await getPool()
  try {
    const result = await pool
      .request()
      .input("Nombre", sql.VarChar(100), nombre)
      .query("SELECT TOP 1 IdEstadoCuenta FROM dbo.EstadosCuenta WHERE Nombre = @Nombre AND RowStatus = 1")

    const row = (result.recordset as QueryRow[])[0]
    if (!row) throw new Error(`Estado de cuenta '${nombre}' no encontrado`)
    return Number(row.IdEstadoCuenta)
  } catch (err) {
    if (!(err instanceof Error && err.message.includes("parameter.type.validate is not a function"))) throw err
    const result = await pool
      .request()
      .input("Nombre", nombre)
      .query("SELECT TOP 1 IdEstadoCuenta FROM dbo.EstadosCuenta WHERE Nombre = @Nombre AND RowStatus = 1")

    const row = (result.recordset as QueryRow[])[0]
    if (!row) throw new Error(`Estado de cuenta '${nombre}' no encontrado`)
    return Number(row.IdEstadoCuenta)
  }
}

// ============================================================
// IMPUESTOS — CatalogoNCF
// ============================================================

export type CatalogoNCFRecord = {
  id: number
  codigo: string
  nombre: string
  nombreInterno: string
  descripcion: string
  esElectronico: boolean
  aplicaCredito: boolean
  aplicaContado: boolean
  requiereRNC: boolean
  aplicaImpuesto: boolean
  exoneraImpuesto: boolean
  active: boolean
}

function mapCatalogoNCFRow(row: QueryRow): CatalogoNCFRecord {
  return {
    id: toNumber(row.IdCatalogoNCF),
    codigo: toText(row.Codigo),
    nombre: toText(row.Nombre),
    nombreInterno: toText(row.NombreInterno),
    descripcion: toText(row.Descripcion),
    esElectronico: Boolean(row.EsElectronico),
    aplicaCredito: Boolean(row.AplicaCredito),
    aplicaContado: Boolean(row.AplicaContado),
    requiereRNC: Boolean(row.RequiereRNC),
    aplicaImpuesto: Boolean(row.AplicaImpuesto),
    exoneraImpuesto: Boolean(row.ExoneraImpuesto),
    active: Boolean(row.Activo),
  }
}

export async function getCatalogoNCF(): Promise<CatalogoNCFRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spCatalogoNCFCRUD")
  return (result.recordset as QueryRow[]).map(mapCatalogoNCFRow)
}

export async function updateCatalogoNCF(
  id: number,
  input: { nombreInterno?: string; active?: boolean }
): Promise<CatalogoNCFRecord> {
  const pool = await getPool()
  const r = pool.request()
    .input("Accion", "A")
    .input("IdCatalogoNCF", sql.Int, id)
    .input("NombreInterno", sql.NVarChar(150), input.nombreInterno ?? null)
    .input("Activo", sql.Bit, input.active ?? null)
  const result = await r.execute("dbo.spCatalogoNCFCRUD")
  return mapCatalogoNCFRow((result.recordset as QueryRow[])[0])
}

// ============================================================
// IMPUESTOS — SecuenciasNCF
// ============================================================

export type SecuenciasNCFRecord = {
  id: number
  idCatalogoNCF: number
  codigoNCF: string
  nombreNCF: string
  idPuntoEmision: number | null
  nombrePuntoEmision: string
  idSecuenciaMadre: number | null
  descripcionMadre: string
  usoComprobante: "D" | "O"
  descripcion: string
  esElectronico: boolean
  digitosSecuencia: number
  prefijo: string
  rangoDesde: number
  rangoHasta: number
  secuenciaActual: number
  fechaVencimiento: string
  colaPrefijo: string
  colaRangoDesde: number | null
  colaRangoHasta: number | null
  colaFechaVencimiento: string
  minimoParaAlertar: number
  RellenoAutomatico: number | null
  cantidadRestante: number
  cantidadRegistrada: number
  agotado: boolean
  active: boolean
}

function mapSecuenciasNCFRow(row: QueryRow): SecuenciasNCFRecord {
  return {
    id: toNumber(row.IdSecuencia),
    idCatalogoNCF: toNumber(row.IdCatalogoNCF),
    codigoNCF: toText(row.CodigoNCF),
    nombreNCF: toText(row.NombreNCF),
    idPuntoEmision: row.IdPuntoEmision != null ? toNumber(row.IdPuntoEmision) : null,
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
    idSecuenciaMadre: row.IdSecuenciaMadre != null ? toNumber(row.IdSecuenciaMadre) : null,
    descripcionMadre: toText(row.DescripcionMadre),
    usoComprobante: (toText(row.UsoComprobante) || "D") as "D" | "O",
    descripcion: toText(row.Descripcion),
    esElectronico: Boolean(row.EsElectronico),
    digitosSecuencia: toNumber(row.DigitosSecuencia) || 8,
    prefijo: toText(row.Prefijo),
    rangoDesde: toNumber(row.RangoDesde),
    rangoHasta: toNumber(row.RangoHasta),
    secuenciaActual: toNumber(row.SecuenciaActual),
    fechaVencimiento: row.FechaVencimiento ? String(row.FechaVencimiento).substring(0, 10) : "",
    colaPrefijo: toText(row.ColaPrefijo),
    colaRangoDesde: row.ColaRangoDesde != null ? toNumber(row.ColaRangoDesde) : null,
    colaRangoHasta: row.ColaRangoHasta != null ? toNumber(row.ColaRangoHasta) : null,
    colaFechaVencimiento: row.ColaFechaVencimiento ? String(row.ColaFechaVencimiento).substring(0, 10) : "",
    minimoParaAlertar: toNumber(row.MinimoParaAlertar),
    RellenoAutomatico: row.RellenoAutomatico != null ? toNumber(row.RellenoAutomatico) : null,
    cantidadRestante: toNumber(row.CantidadRestante),
    cantidadRegistrada: toNumber(row.CantidadRegistrada),
    agotado: Boolean(row.Agotado),
    active: Boolean(row.Activo),
  }
}

export async function getSecuenciasNCF(): Promise<SecuenciasNCFRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spSecuenciasNCFCRUD")
  return (result.recordset as QueryRow[]).map(mapSecuenciasNCFRow)
}

export async function saveSecuenciaNCF(
  input: Partial<SecuenciasNCFRecord> & { usuarioAccion?: number }
): Promise<SecuenciasNCFRecord> {
  const pool = await getPool()
  const isNew = !input.id
  const r = pool.request().input("Accion", isNew ? "I" : "A")
  if (!isNew) r.input("IdSecuencia", sql.Int, input.id!)
  r.input("IdCatalogoNCF", sql.Int, input.idCatalogoNCF ?? null)
  r.input("IdPuntoEmision", sql.Int, input.idPuntoEmision ?? null)
  r.input("IdSecuenciaMadre", sql.Int, input.idSecuenciaMadre ?? null)
  r.input("UsoComprobante", sql.Char(1), input.usoComprobante ?? "D")
  r.input("Descripcion", sql.NVarChar(200), input.descripcion ?? null)
  r.input("EsElectronico", sql.Bit, input.esElectronico ?? false)
  r.input("DigitosSecuencia", sql.TinyInt, input.digitosSecuencia ?? 8)
  r.input("Prefijo", sql.NVarChar(10), input.prefijo ?? null)
  r.input("RangoDesde", sql.BigInt, input.rangoDesde ?? null)
  r.input("RangoHasta", sql.BigInt, input.rangoHasta ?? null)
  r.input("SecuenciaActual", sql.BigInt, input.secuenciaActual ?? null)
  r.input("FechaVencimiento", sql.Date, input.fechaVencimiento || null)
  r.input("ColaPrefijo", sql.NVarChar(10), input.colaPrefijo ?? null)
  r.input("ColaRangoDesde", sql.BigInt, input.colaRangoDesde ?? null)
  r.input("ColaRangoHasta", sql.BigInt, input.colaRangoHasta ?? null)
  r.input("ColaFechaVencimiento", sql.Date, input.colaFechaVencimiento || null)
  r.input("MinimoParaAlertar", sql.Int, input.minimoParaAlertar ?? 10)
  r.input("RellenoAutomatico", sql.Int, input.RellenoAutomatico ?? null)
  r.input("Activo", sql.Bit, input.active ?? true)
  r.input("UsuarioAccion", sql.Int, input.usuarioAccion ?? null)
  const result = await r.execute("dbo.spSecuenciasNCFCRUD")
  return mapSecuenciasNCFRow((result.recordset as QueryRow[])[0])
}

export async function deleteSecuenciaNCF(id: number): Promise<void> {
  const pool = await getPool()
  await pool.request()
    .input("Accion", "D")
    .input("IdSecuencia", sql.Int, id)
    .execute("dbo.spSecuenciasNCFCRUD")
}

export type SecuenciaPuntoEmisionRecord = {
  idSecuencia: number
  idPuntoEmision: number
  nombrePuntoEmision: string
}

export async function getPuntosSecuenciaHija(idSecuencia: number): Promise<SecuenciaPuntoEmisionRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "LP")
    .input("IdSecuencia", sql.Int, idSecuencia)
    .execute("dbo.spSecuenciasNCFCRUD")
  return (result.recordset as QueryRow[]).map((row) => ({
    idSecuencia: toNumber(row.IdSecuencia),
    idPuntoEmision: toNumber(row.IdPuntoEmision),
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
  }))
}

export async function setPuntosSecuenciaHija(idSecuencia: number, puntosEmision: number[]): Promise<SecuenciaPuntoEmisionRecord[]> {
  const pool = await getPool()
  const csvPuntos = puntosEmision.length > 0 ? puntosEmision.join(",") : null
  const result = await pool.request()
    .input("Accion", "SP")
    .input("IdSecuencia", sql.Int, idSecuencia)
    .input("PuntosEmision", sql.NVarChar(sql.MAX), csvPuntos)
    .execute("dbo.spSecuenciasNCFCRUD")
  return (result.recordset as QueryRow[]).map((row) => ({
    idSecuencia: toNumber(row.IdSecuencia),
    idPuntoEmision: toNumber(row.IdPuntoEmision),
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
  }))
}

export async function distribuirSecuenciaNCF(input: {
  idSecuencia: number
  idSecuenciaMadre: number
  cantidadDistribuir: number
  observacion?: string
}): Promise<SecuenciasNCFRecord> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "DIST")
    .input("IdSecuencia", sql.Int, input.idSecuencia)
    .input("IdSecuenciaMadre", sql.Int, input.idSecuenciaMadre)
    .input("CantidadDistribuir", sql.BigInt, input.cantidadDistribuir)
    .input("Observacion", sql.NVarChar(300), input.observacion ?? null)
    .execute("dbo.spSecuenciasNCFCRUD")
  return mapSecuenciasNCFRow((result.recordset as QueryRow[])[0])
}

// ============================================================
// IMPUESTOS — HistorialDistribucionNCF
// ============================================================

export type HistorialDistribucionRecord = {
  id: number
  idSecuenciaMadre: number
  descripcionMadre: string
  idSecuenciaHija: number
  descripcionHija: string
  nombrePuntoEmision: string
  nombreNCF: string
  cantidadDistribuida: number
  rangoDesde: number
  rangoHasta: number
  fechaDistribucion: string
  observacion: string
}

function mapHistorialDistribucionRow(row: QueryRow): HistorialDistribucionRecord {
  return {
    id: toNumber(row.IdHistorial),
    idSecuenciaMadre: toNumber(row.IdSecuenciaMadre),
    descripcionMadre: toText(row.DescripcionMadre),
    idSecuenciaHija: toNumber(row.IdSecuenciaHija),
    descripcionHija: toText(row.DescripcionHija),
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
    nombreNCF: toText(row.NombreNCF),
    cantidadDistribuida: toNumber(row.CantidadDistribuida),
    rangoDesde: toNumber(row.RangoDesde),
    rangoHasta: toNumber(row.RangoHasta),
    fechaDistribucion: row.FechaDistribucion ? String(row.FechaDistribucion).substring(0, 19) : "",
    observacion: toText(row.Observacion),
  }
}

export async function getHistorialDistribucionNCF(input?: {
  idSecuenciaMadre?: number
  idSecuenciaHija?: number
  fechaDesde?: string
  fechaHasta?: string
}): Promise<HistorialDistribucionRecord[]> {
  const pool = await getPool()
  const r = pool.request().input("Accion", "L")
  if (input?.idSecuenciaMadre) r.input("IdSecuenciaMadre", sql.Int, input.idSecuenciaMadre)
  if (input?.idSecuenciaHija)  r.input("IdSecuenciaHija", sql.Int, input.idSecuenciaHija)
  if (input?.fechaDesde) r.input("FechaDesde", sql.Date, input.fechaDesde)
  if (input?.fechaHasta) r.input("FechaHasta", sql.Date, input.fechaHasta)
  const result = await r.execute("dbo.spHistorialDistribucionNCF")
  return (result.recordset as QueryRow[]).map(mapHistorialDistribucionRow)
}

// ============================================================
// FACTURACIÓN — Tipos de Documentos
// ============================================================

export type FacTipoOperacion = "F" | "Q" | "K" | "P" | "N"

export type FacTipoDocumentoRecord = {
  id: number
  tipoOperacion: FacTipoOperacion
  description: string
  prefijo: string
  secuenciaInicial: number
  secuenciaActual: number
  idMoneda: number | null
  nombreMoneda: string
  simboloMoneda: string
  aplicaPropina: boolean
  idCatalogoNCF: number | null
  codigoNCF: string
  nombreNCF: string
  afectaInventario: boolean
  reservaStock: boolean
  active: boolean
}

export type FacTipoDocUsuarioRecord = {
  id: number
  username: string
  nombres: string
  email: string
  assigned: boolean
}

function mapFacTipoDocRow(row: QueryRow): FacTipoDocumentoRecord {
  return {
    id: toNumber(row.IdTipoDocumento),
    tipoOperacion: toText(row.TipoOperacion) as FacTipoOperacion,
    description: toText(row.Descripcion),
    prefijo: toText(row.Prefijo),
    secuenciaInicial: toNumber(row.SecuenciaInicial ?? 1),
    secuenciaActual: toNumber(row.SecuenciaActual ?? 0),
    idMoneda: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    nombreMoneda: toText(row.NombreMoneda),
    simboloMoneda: toText(row.SimboloMoneda),
    aplicaPropina: Boolean(row.AplicaPropina),
    idCatalogoNCF: row.IdCatalogoNCF != null ? toNumber(row.IdCatalogoNCF) : null,
    codigoNCF: toText(row.CodigoNCF),
    nombreNCF: toText(row.NombreNCF),
    afectaInventario: Boolean(row.AfectaInventario),
    reservaStock: Boolean(row.ReservaStock),
    active: Boolean(row.Activo),
  }
}

function mapFacTipoDocUsuarioRow(row: QueryRow): FacTipoDocUsuarioRecord {
  return {
    id: toNumber(row.IdUsuario),
    username: toText(row.NombreUsuario),
    nombres: toText(row.Nombres),
    email: toText(row.Correo),
    assigned: Boolean(row.Asignado),
  }
}

export async function getFacTiposDocumento(tipoOperacion?: FacTipoOperacion): Promise<FacTipoDocumentoRecord[]> {
  const pool = await getPool()
  const req = pool.request().input("Accion", "L")
  if (tipoOperacion) req.input("TipoOperacion", tipoOperacion)
  const result = await req.execute("dbo.spFacTiposDocumentoCRUD")
  return (result.recordset as QueryRow[]).map(mapFacTipoDocRow)
}

export async function saveFacTipoDocumento(input: {
  id?: number
  tipoOperacion: FacTipoOperacion
  description: string
  prefijo?: string
  secuenciaInicial?: number
  idMoneda?: number | null
  aplicaPropina?: boolean
  idCatalogoNCF?: number | null
  afectaInventario?: boolean
  reservaStock?: boolean
  generaFactura?: boolean
  active?: boolean
}): Promise<FacTipoDocumentoRecord> {
  const pool = await getPool()
  const isNew = !input.id
  const r = pool.request().input("Accion", isNew ? "I" : "A")
  if (!isNew) r.input("IdTipoDocumento", input.id!)
  r.input("TipoOperacion", input.tipoOperacion)
  r.input("Descripcion", input.description)
  r.input("Prefijo", input.prefijo ?? null)
  r.input("SecuenciaInicial", input.secuenciaInicial ?? 1)
  r.input("IdMoneda", input.idMoneda ?? null)
  r.input("AplicaPropina", input.aplicaPropina ?? false)
  r.input("IdCatalogoNCF", input.idCatalogoNCF ?? null)
  r.input("AfectaInventario", input.afectaInventario ?? false)
  r.input("ReservaStock", input.reservaStock ?? false)
  r.input("GeneraFactura", input.generaFactura ?? false)
  r.input("Activo", input.active ?? true)
  const result = await r.execute("dbo.spFacTiposDocumentoCRUD")
  return mapFacTipoDocRow((result.recordset as QueryRow[])[0])
}

export async function deleteFacTipoDocumento(id: number): Promise<void> {
  const pool = await getPool()
  await pool.request().input("Accion", "D").input("IdTipoDocumento", id).execute("dbo.spFacTiposDocumentoCRUD")
}

export async function getFacTipoDocUsuarios(idTipoDocumento: number): Promise<FacTipoDocUsuarioRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "LU").input("IdTipoDocumento", idTipoDocumento).execute("dbo.spFacTiposDocumentoCRUD")
  return (result.recordset as QueryRow[]).map(mapFacTipoDocUsuarioRow)
}

export async function syncFacTipoDocUsuarios(idTipoDocumento: number, userIds: number[]): Promise<FacTipoDocUsuarioRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "U")
    .input("IdTipoDocumento", idTipoDocumento)
    .input("UsuariosAsignados", userIds.join(","))
    .execute("dbo.spFacTiposDocumentoCRUD")
  return (result.recordset as QueryRow[]).map(mapFacTipoDocUsuarioRow)
}

// ============================================================
// FACTURACIÓN — Formas de Pago
// ============================================================

export type FacFormaPagoRecord = {
  id: number
  descripcion: string
  comentario: string
  tipoValor: string
  tipoValor607: string
  idMonedaBase: number | null
  nombreMonedaBase: string
  simboloMonedaBase: string
  idMonedaOrigen: number | null
  nombreMonedaOrigen: string
  simboloMonedaOrigen: string
  tasaCambioOrigen: number
  tasaCambioBase: number
  factor: number
  mostrarEnPantallaCobro: boolean
  autoConsumo: boolean
  mostrarEnCobrosMixtos: boolean
  afectaCuadreCaja: boolean
  abreCajon: boolean
  requiereReferencia: boolean
  requiereAutorizacion: boolean
  posicion: number
  grupoCierre: string
  cantidadImpresiones: number
  colorFondo: string
  colorTexto: string
  icono: string
  active: boolean
}

function mapFacFormaPagoRow(row: QueryRow): FacFormaPagoRecord {
  return {
    id: toNumber(row.IdFormaPago),
    descripcion: toText(row.Descripcion),
    comentario: toText(row.Comentario),
    tipoValor: toText(row.TipoValor),
    tipoValor607: toText(row.TipoValor607),
    idMonedaBase: row.IdMonedaBase != null ? toNumber(row.IdMonedaBase) : null,
    nombreMonedaBase: toText(row.NombreMonedaBase),
    simboloMonedaBase: toText(row.SimboloMonedaBase),
    idMonedaOrigen: row.IdMonedaOrigen != null ? toNumber(row.IdMonedaOrigen) : null,
    nombreMonedaOrigen: toText(row.NombreMonedaOrigen),
    simboloMonedaOrigen: toText(row.SimboloMonedaOrigen),
    tasaCambioOrigen: Number(row.TasaCambioOrigen ?? 1),
    tasaCambioBase: Number(row.TasaCambioBase ?? 1),
    factor: Number(row.Factor ?? 1),
    mostrarEnPantallaCobro: Boolean(row.MostrarEnPantallaCobro),
    autoConsumo: Boolean(row.AutoConsumo),
    mostrarEnCobrosMixtos: Boolean(row.MostrarEnCobrosMixtos),
    afectaCuadreCaja: Boolean(row.AfectaCuadreCaja),
    abreCajon: Boolean(row.AbreCajon),
    requiereReferencia: Boolean(row.RequiereReferencia),
    requiereAutorizacion: Boolean(row.RequiereAutorizacion),
    posicion: toNumber(row.Posicion),
    grupoCierre: toText(row.GrupoCierre),
    cantidadImpresiones: toNumber(row.CantidadImpresiones) || 1,
    colorFondo: toText(row.ColorFondo),
    colorTexto: toText(row.ColorTexto),
    icono: toText(row.Icono),
    active: Boolean(row.Activo),
  }
}

export async function getFacFormasPago(): Promise<FacFormaPagoRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "L").execute("dbo.spFacFormasPagoCRUD")
  return (result.recordset as QueryRow[]).map(mapFacFormaPagoRow)
}

// Formas de pago habilitadas para cobro en un punto de emisión
// Si el punto no tiene formas asignadas, devuelve todas las activas con MostrarEnPantallaCobro=1
export async function getFormasPagoParaCobro(idPuntoEmision: number): Promise<FacFormaPagoRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .query(`
      SELECT f.IdFormaPago, f.Descripcion, f.Comentario,
             f.TipoValor, f.TipoValor607,
             f.IdMonedaBase, mb.Nombre AS NombreMonedaBase, mb.Simbolo AS SimboloMonedaBase,
             f.IdMonedaOrigen, mo.Nombre AS NombreMonedaOrigen, mo.Simbolo AS SimboloMonedaOrigen,
             f.TasaCambioOrigen, f.TasaCambioBase, f.Factor,
             f.MostrarEnPantallaCobro, f.AutoConsumo, f.MostrarEnCobrosMixtos, f.AfectaCuadreCaja,
             f.AbreCajon, f.RequiereReferencia, f.RequiereAutorizacion,
             f.Posicion, f.GrupoCierre, f.CantidadImpresiones,
             f.ColorFondo, f.ColorTexto, f.Icono, f.Activo
      FROM dbo.FacFormasPago f
      LEFT JOIN dbo.Monedas mb ON mb.IdMoneda = f.IdMonedaBase
      LEFT JOIN dbo.Monedas mo ON mo.IdMoneda = f.IdMonedaOrigen
      WHERE f.RowStatus = 1 AND f.Activo = 1 AND (f.MostrarEnPantallaCobro = 1 OR f.MostrarEnCobrosMixtos = 1)
        AND (
          EXISTS (SELECT 1 FROM dbo.FacFormaPagoPuntoEmision fp WHERE fp.IdFormaPago = f.IdFormaPago AND fp.IdPuntoEmision = ${idPuntoEmision})
          OR NOT EXISTS (SELECT 1 FROM dbo.FacFormaPagoPuntoEmision WHERE IdFormaPago = f.IdFormaPago)
        )
      ORDER BY f.Posicion, f.Descripcion
    `)
  return (result.recordset as QueryRow[]).map(mapFacFormaPagoRow)
}

export async function saveFacFormaPago(input: Partial<FacFormaPagoRecord> & { id?: number }): Promise<FacFormaPagoRecord> {
  const pool = await getPool()
  const isNew = !input.id
  const r = pool.request().input("Accion", isNew ? "I" : "A")
  if (!isNew) r.input("IdFormaPago", input.id!)
  r.input("Descripcion", input.descripcion ?? null)
  r.input("Comentario", input.comentario ?? null)
  r.input("TipoValor", input.tipoValor ?? "EF")
  r.input("TipoValor607", input.tipoValor607 ?? null)
  r.input("IdMonedaBase", input.idMonedaBase ?? null)
  r.input("IdMonedaOrigen", input.idMonedaOrigen ?? null)
  r.input("TasaCambioOrigen", input.tasaCambioOrigen ?? 1)
  r.input("TasaCambioBase", input.tasaCambioBase ?? 1)
  r.input("Factor", input.factor ?? 1)
  r.input("MostrarEnPantallaCobro", input.mostrarEnPantallaCobro ?? true)
  r.input("AutoConsumo", input.autoConsumo ?? false)
  r.input("MostrarEnCobrosMixtos", input.mostrarEnCobrosMixtos ?? false)
  r.input("AfectaCuadreCaja", input.afectaCuadreCaja ?? true)
  r.input("AbreCajon", input.abreCajon ?? false)
  r.input("RequiereReferencia", input.requiereReferencia ?? false)
  r.input("RequiereAutorizacion", input.requiereAutorizacion ?? false)
  r.input("Posicion", input.posicion ?? 1)
  r.input("GrupoCierre", input.grupoCierre ?? null)
  r.input("CantidadImpresiones", input.cantidadImpresiones ?? 1)
  r.input("ColorFondo", input.colorFondo ?? null)
  r.input("ColorTexto", input.colorTexto ?? null)
  r.input("Icono", input.icono ?? null)
  r.input("Activo", input.active ?? true)
  const result = await r.execute("dbo.spFacFormasPagoCRUD")
  return mapFacFormaPagoRow((result.recordset as QueryRow[])[0])
}

export async function deleteFacFormaPago(id: number): Promise<void> {
  const pool = await getPool()
  await pool.request().input("Accion", "D").input("IdFormaPago", id).execute("dbo.spFacFormasPagoCRUD")
}

export type FacFormaPagoPERecord = { idFormaPago: number; idPuntoEmision: number; nombrePuntoEmision: string }

export async function getPuntosFacFormaPago(id: number): Promise<FacFormaPagoPERecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "LP").input("IdFormaPago", id).execute("dbo.spFacFormasPagoCRUD")
  return (result.recordset as QueryRow[]).map((row) => ({
    idFormaPago: toNumber(row.IdFormaPago),
    idPuntoEmision: toNumber(row.IdPuntoEmision),
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
  }))
}

export async function setPuntosFacFormaPago(id: number, puntos: number[]): Promise<FacFormaPagoPERecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "SP")
    .input("IdFormaPago", id)
    .input("PuntosEmision", puntos.length > 0 ? puntos.join(",") : null)
    .execute("dbo.spFacFormasPagoCRUD")
  return (result.recordset as QueryRow[]).map((row) => ({
    idFormaPago: toNumber(row.IdFormaPago),
    idPuntoEmision: toNumber(row.IdPuntoEmision),
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
  }))
}

// ============================================================
// FACTURACIÓN — Cajas POS
// ============================================================

export type FacCajaPOSRecord = {
  id: number
  descripcion: string
  idSucursal: number
  nombreSucursal: string
  tipoCierre: string
  idPuntoEmision: number | null
  nombrePuntoEmision: string
  idMoneda: number | null
  nombreMoneda: string
  simboloMoneda: string
  idTerminal: string
  cajaAbierta: boolean
  fechaApertura: string
  fechaCierre: string
  manejaFondo: boolean
  fondoFijo: boolean
  fondoCaja: number
  active: boolean
}

export type FacCajaPOSUsuarioRecord = {
  id: number
  username: string
  nombres: string
  email: string
  assigned: boolean
}

function mapFacCajaPOSRow(row: QueryRow): FacCajaPOSRecord {
  return {
    id: toNumber(row.IdCajaPOS),
    descripcion: toText(row.Descripcion),
    idSucursal: toNumber(row.IdSucursal),
    nombreSucursal: toText(row.NombreSucursal),
    tipoCierre: toText(row.TipoCierre),
    idPuntoEmision: row.IdPuntoEmision != null ? toNumber(row.IdPuntoEmision) : null,
    nombrePuntoEmision: toText(row.NombrePuntoEmision),
    idMoneda: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    nombreMoneda: toText(row.NombreMoneda),
    simboloMoneda: toText(row.SimboloMoneda),
    idTerminal: toText(row.IdTerminal),
    cajaAbierta: Boolean(row.CajaAbierta),
    fechaApertura: row.FechaApertura ? String(row.FechaApertura).substring(0, 19) : "",
    fechaCierre: row.FechaCierre ? String(row.FechaCierre).substring(0, 19) : "",
    manejaFondo: Boolean(row.ManejaFondo),
    fondoFijo: Boolean(row.FondoFijo),
    fondoCaja: Number(row.FondoCaja ?? 0),
    active: Boolean(row.Activo),
  }
}

function mapFacCajaPOSUsuarioRow(row: QueryRow): FacCajaPOSUsuarioRecord {
  return {
    id: toNumber(row.IdUsuario),
    username: toText(row.NombreUsuario),
    nombres: toText(row.Nombres),
    email: toText(row.Correo),
    assigned: Boolean(row.Asignado),
  }
}

export async function getFacCajasPOS(idSucursal?: number): Promise<FacCajaPOSRecord[]> {
  const pool = await getPool()
  const req = pool.request().input("Accion", "L")
  if (idSucursal) req.input("IdSucursal", idSucursal)
  const result = await req.execute("dbo.spFacCajasPOSCRUD")
  return (result.recordset as QueryRow[]).map(mapFacCajaPOSRow)
}

export async function saveFacCajaPOS(input: Partial<FacCajaPOSRecord> & { id?: number }): Promise<FacCajaPOSRecord> {
  const pool = await getPool()
  const isNew = !input.id
  const r = pool.request().input("Accion", isNew ? "I" : "A")
  if (!isNew) r.input("IdCajaPOS", input.id!)
  r.input("Descripcion", input.descripcion ?? null)
  r.input("IdSucursal", input.idSucursal ?? null)
  r.input("IdPuntoEmision", input.idPuntoEmision ?? null)
  r.input("IdMoneda", input.idMoneda ?? null)
  r.input("IdTerminal", input.idTerminal ?? null)
  r.input("ManejaFondo", input.manejaFondo ?? false)
  r.input("FondoFijo", input.fondoFijo ?? false)
  r.input("FondoCaja", input.fondoCaja ?? 0)
  r.input("Activo", input.active ?? true)
  const result = await r.execute("dbo.spFacCajasPOSCRUD")
  return mapFacCajaPOSRow((result.recordset as QueryRow[])[0])
}

export async function deleteFacCajaPOS(id: number): Promise<void> {
  const pool = await getPool()
  await pool.request().input("Accion", "D").input("IdCajaPOS", id).execute("dbo.spFacCajasPOSCRUD")
}

export async function getFacCajaPOSUsuarios(id: number): Promise<FacCajaPOSUsuarioRecord[]> {
  const pool = await getPool()
  const result = await pool.request().input("Accion", "LU").input("IdCajaPOS", id).execute("dbo.spFacCajasPOSCRUD")
  return (result.recordset as QueryRow[]).map(mapFacCajaPOSUsuarioRow)
}

export async function syncFacCajaPOSUsuarios(id: number, userIds: number[]): Promise<FacCajaPOSUsuarioRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "U")
    .input("IdCajaPOS", id)
    .input("UsuariosAsignados", userIds.join(","))
    .execute("dbo.spFacCajasPOSCRUD")
  return (result.recordset as QueryRow[]).map(mapFacCajaPOSUsuarioRow)
}

// ─────────────────────────────────────────────────────────────
// FacDocumentosPOS — documentos pausados / pendientes POS
// ─────────────────────────────────────────────────────────────

export type FacDocumentoPOSLinea = {
  numLinea: number
  productId: number
  code: string
  description: string
  quantity: number
  unit: string
  basePrice: number
  taxRate: number
  applyTax: boolean
  applyTip: boolean
  lineDiscount: number
  lineComment?: string | null
}

export type FacDocumentoPOS = {
  id: number
  idPuntoEmision: number
  idUsuario: number
  idCliente: number | null
  referenciaCliente: string | null
  referencia: string | null
  comentarioGeneral: string | null
  idTipoDocumento: number | null
  nombreTipoDocumento: string | null
  idAlmacen: number | null
  fechaDocumento: string
  vendedor: string | null
  notas: string | null
  idMoneda: number | null
  tasaCambio: number
  fechaCreacion: string
  cantidadLineas: number
  totalEstimado: number | null
}

export type FacDocumentoPOSDetalle = FacDocumentoPOS & {
  lineas: FacDocumentoPOSLinea[]
}

function mapFacDocumentoPOSRow(row: QueryRow): FacDocumentoPOS {
  return {
    id: toNumber(row.IdDocumentoPOS),
    idPuntoEmision: toNumber(row.IdPuntoEmision),
    idUsuario: toNumber(row.IdUsuario),
    idCliente: row.IdCliente != null ? toNumber(row.IdCliente) : null,
    referenciaCliente: row.ReferenciaCliente != null ? toText(row.ReferenciaCliente) : null,
    referencia: row.Referencia != null ? toText(row.Referencia) : null,
    comentarioGeneral: row.ComentarioGeneral != null ? toText(row.ComentarioGeneral) : null,
    idTipoDocumento: row.IdTipoDocumento != null ? toNumber(row.IdTipoDocumento) : null,
    nombreTipoDocumento: row.NombreTipoDocumento != null ? toText(row.NombreTipoDocumento) : null,
    idAlmacen: row.IdAlmacen != null ? toNumber(row.IdAlmacen) : null,
    fechaDocumento: toText(row.FechaDocumento),
    vendedor: row.Vendedor != null ? toText(row.Vendedor) : null,
    notas: row.Notas != null ? toText(row.Notas) : null,
    idMoneda: row.IdMoneda != null ? toNumber(row.IdMoneda) : null,
    tasaCambio: row.TasaCambio != null ? toNumber(row.TasaCambio) : 1,
    fechaCreacion: toText(row.FechaCreacion),
    cantidadLineas: row.CantidadLineas != null ? toNumber(row.CantidadLineas) : 0,
    totalEstimado: row.TotalEstimado != null ? toNumber(row.TotalEstimado) : null,
  }
}

function mapFacDocumentoPOSLineaRow(row: QueryRow): FacDocumentoPOSLinea {
  return {
    numLinea: toNumber(row.NumLinea),
    productId: row.IdProducto != null ? toNumber(row.IdProducto) : 0,
    code: toText(row.Codigo),
    description: toText(row.Descripcion),
    quantity: toNumber(row.Cantidad),
    unit: toText(row.Unidad),
    basePrice: toNumber(row.PrecioBase),
    taxRate: toNumber(row.PorcentajeImpuesto),
    applyTax: Boolean(row.AplicaImpuesto),
    applyTip: Boolean(row.AplicaPropina),
    lineDiscount: toNumber(row.DescuentoLinea),
    lineComment: row.ComentarioLinea != null ? toText(row.ComentarioLinea) : null,
  }
}

export async function getFacDocumentosPOS(idPuntoEmision: number): Promise<FacDocumentoPOS[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .input("IdPuntoEmision", idPuntoEmision)
    .execute("dbo.spFacDocumentosPOSCRUD")
  return (result.recordset as QueryRow[]).map(mapFacDocumentoPOSRow)
}

export async function getFacDocumentoPOS(id: number): Promise<FacDocumentoPOSDetalle | null> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "O")
    .input("IdDocumentoPOS", id)
    .execute("dbo.spFacDocumentosPOSCRUD")
  const recordsets = result.recordsets as QueryRow[][]
  const header = recordsets[0]?.[0]
  if (!header) return null
  const lineas = (recordsets[1] ?? []).map(mapFacDocumentoPOSLineaRow)
  return {
    ...mapFacDocumentoPOSRow(header),
    cantidadLineas: lineas.length,
    totalEstimado: null,
    lineas,
  }
}

export type SaveFacDocumentoPOSInput = {
  id?: number
  idPuntoEmision: number
  idUsuario: number
  idCliente?: number | null
  referenciaCliente?: string | null
  referencia?: string | null
  comentarioGeneral?: string | null
  idTipoDocumento?: number | null
  idAlmacen?: number | null
  fechaDocumento?: string
  vendedor?: string | null
  notas?: string | null
  idMoneda?: number | null
  tasaCambio?: number
  lineas: FacDocumentoPOSLinea[]
}

export async function saveFacDocumentoPOS(
  input: SaveFacDocumentoPOSInput,
  accion: "I" | "U" = "I"
): Promise<number> {
  const pool = await getPool()
  const lineasJson = JSON.stringify(
    input.lineas.map((l, idx) => ({ ...l, numLinea: idx + 1 }))
  )
  const result = await pool.request()
    .input("Accion", accion)
    .input("IdDocumentoPOS", input.id ?? null)
    .input("IdPuntoEmision", input.idPuntoEmision)
    .input("IdUsuario", input.idUsuario)
    .input("IdCliente", input.idCliente ?? null)
    .input("ReferenciaCliente", input.referenciaCliente ?? null)
    .input("Referencia", input.referencia ?? null)
    .input("ComentarioGeneral", input.comentarioGeneral ?? null)
    .input("IdTipoDocumento", input.idTipoDocumento ?? null)
    .input("IdAlmacen", input.idAlmacen ?? null)
    .input("FechaDocumento", input.fechaDocumento ?? null)
    .input("Vendedor", input.vendedor ?? null)
    .input("Notas", input.notas ?? null)
    .input("IdMoneda", input.idMoneda ?? null)
    .input("TasaCambio", input.tasaCambio ?? 1)
    .input("LineasJson", lineasJson)
    .execute("dbo.spFacDocumentosPOSCRUD")
  return toNumber((result.recordset as QueryRow[])[0]?.IdDocumentoPOS ?? 0)
}

export async function anularFacDocumentoPOS(id: number, idUsuario: number): Promise<void> {
  const pool = await getPool()
  await pool.request()
    .input("Accion", "X")
    .input("IdDocumentoPOS", id)
    .input("IdUsuario", idUsuario)
    .execute("dbo.spFacDocumentosPOSCRUD")
}

// ─────────────────────────────────────────────────────────────
// FacDocumentos — documentos definitivos
// ─────────────────────────────────────────────────────────────

export type FacDocEstado = "I" | "P" | "N"

export type FacDocumentoRecord = {
  idDocumento: number
  idTipoDocumento: number
  documentoSecuencia: string
  tipoPrefijo: string
  tipoDocumentoNombre: string | null
  idDocumentoOrigen: number | null
  idDocumentoPOSOrigen: number | null
  ncf: string | null
  idTipoNCF: number | null
  tipoNCFNombre: string | null
  rncCliente: string | null
  idPuntoEmision: number
  puntoEmisionNombre: string | null
  idCaja: number | null
  idSesionCaja: number | null
  idUsuario: number
  usuarioNombre: string | null
  idCliente: number | null
  nombreCliente: string | null
  secuencia: number
  fechaDocumento: string
  subTotal: number
  descuento: number
  impuesto: number
  propina: number
  total: number
  totalPagado: number
  idMoneda: number | null
  tasaCambio: number
  estado: FacDocEstado
  fechaAnulacion: string | null
  motivoAnulacion: string | null
  comentario: string | null
  origenDocumento: "ORDEN" | "POS" | null
  totalRegistros: number
}

export type FacDocumentoDetalleRecord = {
  idDocumentoDetalle: number
  idDocumento: number
  numeroLinea: number
  idProducto: number | null
  codigo: string | null
  descripcion: string
  cantidad: number
  unidad: string | null
  precioBase: number
  porcentajeImpuesto: number
  aplicaImpuesto: boolean
  aplicaPropina: boolean
  descuentoLinea: number
  comentarioLinea: string | null
  subTotalLinea: number
  impuestoLinea: number
  totalLinea: number
}

export type FacDocumentoPagoRecord = {
  idPago: number
  idDocumento: number
  idFormaPago: number
  formaPagoNombre: string
  tipoValor: string
  tipoValor607: string | null
  monto: number
  montoBase: number
  idMoneda: number | null
  tasaCambio: number
  referencia: string | null
  autorizacion: string | null
}

function mapFacDocumentoRow(row: QueryRow): FacDocumentoRecord {
  return {
    idDocumento:          Number(row.IdDocumento),
    idTipoDocumento:      Number(row.IdTipoDocumento),
    documentoSecuencia:   String(row.DocumentoSecuencia ?? ""),
    tipoPrefijo:          String(row.TipoDocumentoPrefijo ?? ""),
    tipoDocumentoNombre:  row.TipoDocumentoNombre ? String(row.TipoDocumentoNombre) : null,
    idDocumentoOrigen:    row.IdDocumentoOrigen != null ? Number(row.IdDocumentoOrigen) : null,
    idDocumentoPOSOrigen: row.IdDocumentoPOSOrigen != null ? Number(row.IdDocumentoPOSOrigen) : null,
    ncf:                  row.NCF ? String(row.NCF) : null,
    idTipoNCF:            row.IdTipoNCF != null ? Number(row.IdTipoNCF) : null,
    tipoNCFNombre:        row.TipoNCFNombre ? String(row.TipoNCFNombre) : null,
    rncCliente:           row.RNCCliente ? String(row.RNCCliente) : null,
    idPuntoEmision:       Number(row.IdPuntoEmision),
    puntoEmisionNombre:   row.PuntoEmisionNombre ? String(row.PuntoEmisionNombre) : null,
    idCaja:               row.IdCaja != null ? Number(row.IdCaja) : null,
    idSesionCaja:         row.IdSesionCaja != null ? Number(row.IdSesionCaja) : null,
    idUsuario:            Number(row.IdUsuario),
    usuarioNombre:        row.UsuarioNombre ? String(row.UsuarioNombre) : null,
    idCliente:            row.IdCliente != null ? Number(row.IdCliente) : null,
    nombreCliente:        row.ClienteNombre ? String(row.ClienteNombre) : null,
    secuencia:            Number(row.Secuencia ?? 0),
    fechaDocumento:       row.FechaDocumento ? (row.FechaDocumento instanceof Date ? row.FechaDocumento.toISOString().slice(0, 10) : String(row.FechaDocumento).slice(0, 10)) : "",
    subTotal:             Number(row.SubTotal ?? 0),
    descuento:            Number(row.Descuento ?? 0),
    impuesto:             Number(row.Impuesto ?? 0),
    propina:              Number(row.Propina ?? 0),
    total:                Number(row.Total ?? 0),
    totalPagado:          Number(row.TotalPagado ?? 0),
    idMoneda:             row.IdMoneda != null ? Number(row.IdMoneda) : null,
    tasaCambio:           Number(row.TasaCambio ?? 1),
    estado:               (String(row.Estado ?? "I").trim()) as FacDocEstado,
    fechaAnulacion:       row.FechaAnulacion ? String(row.FechaAnulacion) : null,
    motivoAnulacion:      row.MotivoAnulacion ? String(row.MotivoAnulacion) : null,
    comentario:           row.Comentario ? String(row.Comentario) : null,
    origenDocumento:      (row.OrigenDocumento || row.OrigenDocumentoEfectivo)
                            ? ((row.OrigenDocumento || row.OrigenDocumentoEfectivo) as "ORDEN" | "POS")
                            : null,
    totalRegistros:       Number(row.TotalRegistros ?? 0),
  }
}

function mapFacDocumentoDetalleRow(row: QueryRow): FacDocumentoDetalleRecord {
  return {
    idDocumentoDetalle:   Number(row.IdDocumentoDetalle),
    idDocumento:          Number(row.IdDocumento),
    numeroLinea:          Number(row.NumeroLinea ?? 1),
    idProducto:           row.IdProducto != null ? Number(row.IdProducto) : null,
    codigo:               row.Codigo ? String(row.Codigo) : null,
    descripcion:          String(row.Descripcion ?? ""),
    cantidad:             Number(row.Cantidad ?? 1),
    unidad:               row.Unidad ? String(row.Unidad) : null,
    precioBase:           Number(row.PrecioBase ?? 0),
    porcentajeImpuesto:   Number(row.PorcentajeImpuesto ?? 0),
    aplicaImpuesto:       Boolean(row.AplicaImpuesto),
    aplicaPropina:        Boolean(row.AplicaPropina),
    descuentoLinea:       Number(row.DescuentoLinea ?? 0),
    comentarioLinea:      row.ComentarioLinea ? String(row.ComentarioLinea) : null,
    subTotalLinea:        Number(row.SubTotalLinea ?? 0),
    impuestoLinea:        Number(row.ImpuestoLinea ?? 0),
    totalLinea:           Number(row.TotalLinea ?? 0),
  }
}

function mapFacDocumentoPagoRow(row: QueryRow): FacDocumentoPagoRecord {
  return {
    idPago:          Number(row.IdPago),
    idDocumento:     Number(row.IdDocumento),
    idFormaPago:     Number(row.IdFormaPago),
    formaPagoNombre: String(row.FormaPagoNombre ?? ""),
    tipoValor:       String(row.TipoValor ?? ""),
    tipoValor607:    row.TipoValor607 ? String(row.TipoValor607) : null,
    monto:           Number(row.Monto ?? 0),
    montoBase:       Number(row.MontoBase ?? 0),
    idMoneda:        row.IdMoneda != null ? Number(row.IdMoneda) : null,
    tasaCambio:      Number(row.TasaCambio ?? 1),
    referencia:      row.Referencia ? String(row.Referencia) : null,
    autorizacion:    row.Autorizacion ? String(row.Autorizacion) : null,
  }
}

export async function listFacDocumentos(params: {
  idPuntoEmision?: number
  fechaDesde?: string
  fechaHasta?: string
  soloTipo?: number
  soloEstado?: string
  secuenciaDesde?: number
  secuenciaHasta?: number
  origenDocumento?: "ORDEN" | "POS" | null
  pageSize?: number
  pageOffset?: number
}): Promise<FacDocumentoRecord[]> {
  const pool = await getPool()
  const r = pool.request().input("Accion", "L")
  if (params.idPuntoEmision)  r.input("IdPuntoEmision",  params.idPuntoEmision)
  if (params.fechaDesde)      r.input("FechaDesde",      params.fechaDesde)
  if (params.fechaHasta)      r.input("FechaHasta",      params.fechaHasta)
  if (params.soloTipo)        r.input("SoloTipo",        params.soloTipo)
  if (params.soloEstado)      r.input("SoloEstado",      params.soloEstado)
  if (params.secuenciaDesde)  r.input("SecuenciaDesde",  params.secuenciaDesde)
  if (params.secuenciaHasta)  r.input("SecuenciaHasta",  params.secuenciaHasta)
  if (params.origenDocumento) r.input("OrigenDocumento", params.origenDocumento)
  r.input("PageSize",   params.pageSize   ?? 100)
  r.input("PageOffset", params.pageOffset ?? 0)
  const result = await r.execute("dbo.spFacDocumentosCRUD")
  return (result.recordset as QueryRow[]).map(mapFacDocumentoRow)
}

export type FacDocumentoConPagosRecord = FacDocumentoRecord & {
  pagoEfectivo: number
  pagoTarjeta: number
  pagoCheque: number
  pagoTransferencia: number
  pagoCredito: number
  pagoOtros: number
}

export async function listFacDocumentosConPagos(params: {
  idPuntoEmision?: number
  fechaDesde?: string
  fechaHasta?: string
  soloTipo?: number
  soloEstado?: string
  secuenciaDesde?: number
  secuenciaHasta?: number
  pageSize?: number
  pageOffset?: number
}): Promise<FacDocumentoConPagosRecord[]> {
  const pool = await getPool()
  const pageSize   = params.pageSize   ?? 100
  const pageOffset = params.pageOffset ?? 0

  const result = await pool.request()
    .input("FechaDesde",     params.fechaDesde     ?? null)
    .input("FechaHasta",     params.fechaHasta     ?? null)
    .input("IdPuntoEmision", params.idPuntoEmision ?? null)
    .input("SoloTipo",       params.soloTipo       ?? null)
    .input("SoloEstado",     params.soloEstado     ?? null)
    .input("SecuenciaDesde", params.secuenciaDesde ?? null)
    .input("SecuenciaHasta", params.secuenciaHasta ?? null)
    .input("PageSize",       pageSize)
    .input("PageOffset",     pageOffset)
    .query(`
      SELECT
        d.IdDocumento, d.IdTipoDocumento,
        d.DocumentoSecuencia, t.Prefijo AS TipoDocumentoPrefijo,
        t.Descripcion AS TipoDocumentoNombre,
        d.IdDocumentoOrigen, d.IdDocumentoPOSOrigen,
        d.NCF, d.IdTipoNCF, d.RNCCliente,
        d.IdPuntoEmision, pe.Nombre AS PuntoEmisionNombre,
        d.IdCaja, d.IdSesionCaja, d.IdUsuario, u.NombreUsuario AS UsuarioNombre,
        d.IdCliente, c.Nombre AS ClienteNombre, d.Secuencia,
        d.FechaDocumento,
        d.SubTotal, d.Descuento, d.Impuesto, d.Propina, d.Total,
        d.TotalPagado,
        d.IdMoneda, d.TasaCambio, d.Estado,
        d.FechaAnulacion, d.MotivoAnulacion, d.Comentario,
        d.IdUsuarioCreacion,
        NULL AS TipoNCFNombre,
        COUNT(*) OVER() AS TotalRegistros,
        SUM(CASE WHEN f.TipoValor = 'EF' THEN p.Monto ELSE 0 END) AS PagoEfectivo,
        SUM(CASE WHEN f.TipoValor = 'TC' THEN p.Monto ELSE 0 END) AS PagoTarjeta,
        SUM(CASE WHEN f.TipoValor = 'CH' THEN p.Monto ELSE 0 END) AS PagoCheque,
        SUM(CASE WHEN f.TipoValor = 'OV' THEN p.Monto ELSE 0 END) AS PagoTransferencia,
        SUM(CASE WHEN f.TipoValor = 'VC' THEN p.Monto ELSE 0 END) AS PagoCredito,
        SUM(CASE WHEN f.TipoValor NOT IN ('EF','TC','CH','OV','VC') THEN p.Monto ELSE 0 END) AS PagoOtros
      FROM dbo.FacDocumentos d
      JOIN dbo.FacTiposDocumento t    ON t.IdTipoDocumento = d.IdTipoDocumento
      LEFT JOIN dbo.PuntosEmision pe  ON pe.IdPuntoEmision = d.IdPuntoEmision
      LEFT JOIN dbo.Usuarios u        ON u.IdUsuario = d.IdUsuario
      LEFT JOIN dbo.Terceros c        ON c.IdTercero = d.IdCliente
      LEFT JOIN dbo.FacDocumentoPagos p ON p.IdDocumento = d.IdDocumento AND p.RowStatus = 1
      LEFT JOIN dbo.FacFormasPago f   ON f.IdFormaPago = p.IdFormaPago
      WHERE d.RowStatus = 1
        AND (@IdPuntoEmision IS NULL OR d.IdPuntoEmision  = @IdPuntoEmision)
        AND (@FechaDesde     IS NULL OR d.FechaDocumento >= @FechaDesde)
        AND (@FechaHasta     IS NULL OR d.FechaDocumento <= @FechaHasta)
        AND (@SoloTipo       IS NULL OR d.IdTipoDocumento = @SoloTipo)
        AND (@SoloEstado     IS NULL OR d.Estado          = @SoloEstado)
        AND (@SecuenciaDesde IS NULL OR d.Secuencia      >= @SecuenciaDesde)
        AND (@SecuenciaHasta IS NULL OR d.Secuencia      <= @SecuenciaHasta)
      GROUP BY
        d.IdDocumento, d.IdTipoDocumento,
        d.DocumentoSecuencia, t.Prefijo,
        t.Descripcion,
        d.IdDocumentoOrigen, d.IdDocumentoPOSOrigen,
        d.NCF, d.IdTipoNCF, d.RNCCliente,
        d.IdPuntoEmision, pe.Nombre,
        d.IdCaja, d.IdSesionCaja, d.IdUsuario, u.NombreUsuario,
        d.IdCliente, c.Nombre, d.Secuencia,
        d.FechaDocumento,
        d.SubTotal, d.Descuento, d.Impuesto, d.Propina, d.Total,
        d.TotalPagado,
        d.IdMoneda, d.TasaCambio, d.Estado,
        d.FechaAnulacion, d.MotivoAnulacion, d.Comentario,
        d.IdUsuarioCreacion
      ORDER BY d.FechaDocumento DESC, d.IdDocumento DESC
      OFFSET @PageOffset ROWS FETCH NEXT @PageSize ROWS ONLY
    `)

  return (result.recordset as QueryRow[]).map((row) => ({
    ...mapFacDocumentoRow(row),
    pagoEfectivo:      Number(row.PagoEfectivo      ?? 0),
    pagoTarjeta:       Number(row.PagoTarjeta       ?? 0),
    pagoCheque:        Number(row.PagoCheque        ?? 0),
    pagoTransferencia: Number(row.PagoTransferencia ?? 0),
    pagoCredito:       Number(row.PagoCredito       ?? 0),
    pagoOtros:         Number(row.PagoOtros         ?? 0),
  }))
}

export async function getFacDocumento(idDocumento: number): Promise<{
  doc: FacDocumentoRecord
  lineas: FacDocumentoDetalleRecord[]
  pagos: FacDocumentoPagoRecord[]
} | null> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "G")
    .input("IdDocumento", idDocumento)
    .execute("dbo.spFacDocumentosCRUD")

  const sets = result.recordsets as unknown as QueryRow[][]
  if (!sets[0]?.length) return null

  const doc = mapFacDocumentoRow(sets[0][0])
  const lineas = (sets[1] ?? []).map(mapFacDocumentoDetalleRow)

  // Pagos los cargamos aparte
  const pagosResult = await pool.request()
    .input("Accion", "L")
    .input("IdDocumento", idDocumento)
    .execute("dbo.spFacDocumentoPagosCRUD")
  const pagos = (pagosResult.recordset as QueryRow[]).map(mapFacDocumentoPagoRow)

  return { doc, lineas, pagos }
}

export type SaveFacDocumentoInput = {
  idDocumento?: number  // undefined = INSERT, provided = UPDATE
  idTipoDocumento: number
  idPuntoEmision: number
  idUsuario: number
  idCliente?: number | null
  rncCliente?: string | null
  ncf?: string | null
  idTipoNCF?: number | null
  fecha: string
  comentario?: string | null
  lineas: Array<{
    descripcion: string
    cantidad: number
    precioBase: number
    porcentajeImpuesto: number
    aplicaImpuesto: boolean
    descuentoLinea: number
    idProducto?: number | null
    codigo?: string | null
    unidad?: string | null
  }>
}

export async function saveFacDocumento(input: SaveFacDocumentoInput): Promise<{ idDocumento: number; secuencia: number }> {
  const pool = await getPool()
  const accion = input.idDocumento ? "U" : "I"

  // Calcular totales
  let subTotal = 0, impuesto = 0, descuento = 0
  for (const l of input.lineas) {
    const lineSub = l.cantidad * l.precioBase
    const lineDesc = l.descuentoLinea
    const lineImp = l.aplicaImpuesto ? (lineSub - lineDesc) * (l.porcentajeImpuesto / 100) : 0
    subTotal += lineSub
    descuento += lineDesc
    impuesto += lineImp
  }
  const total = subTotal - descuento + impuesto

  // Si es INSERT, obtener próxima secuencia
  let proxSecuencia = 0
  if (!input.idDocumento) {
    const seqRes = await pool.request()
      .input("IdTipoDocumentoSeq", input.idTipoDocumento)
      .query(`
        SELECT ISNULL(MAX(Secuencia), 0) + 1 AS ProxSecuencia
        FROM dbo.FacDocumentos
        WHERE IdTipoDocumento = @IdTipoDocumentoSeq AND RowStatus = 1
      `)
    proxSecuencia = Number((seqRes.recordset as QueryRow[])[0]?.ProxSecuencia ?? 1)
  }

  // Cabecera
  const cabeceraRes = await pool.request()
    .input("Accion",               accion)
    .input("IdDocumento",          input.idDocumento ?? null)
    .input("IdTipoDocumento",      input.idTipoDocumento)
    .input("IdPuntoEmision",       input.idPuntoEmision)
    .input("IdUsuario",            input.idUsuario)
    .input("IdCliente",            input.idCliente ?? null)
    .input("RNCCliente",           input.rncCliente ?? null)
    .input("NCF",                  input.ncf ?? null)
    .input("IdTipoNCF",            input.idTipoNCF ?? null)
    .input("Secuencia",            input.idDocumento ? null : proxSecuencia)
    .input("FechaDocumento",       input.fecha)
    .input("SubTotal",             subTotal)
    .input("Descuento",            descuento)
    .input("Impuesto",             impuesto)
    .input("Total",                total)
    .input("Comentario",           input.comentario ?? null)
    .input("IdUsuarioAccion",      input.idUsuario)
    .execute("dbo.spFacDocumentosCRUD")

  const idDocumento = input.idDocumento ?? Number((cabeceraRes.recordset as QueryRow[])[0]?.IdDocumento ?? 0)
  if (!idDocumento) throw new Error("Error al guardar el documento.")

  // Si es edición, eliminar líneas previas
  if (input.idDocumento) {
    await pool.request().query(`
      DELETE FROM dbo.FacDocumentoDetalle WHERE IdDocumento = ${idDocumento}
    `)
    // Obtener secuencia actual
    const docRes = await pool.request().query(`SELECT Secuencia FROM dbo.FacDocumentos WHERE IdDocumento = ${idDocumento}`)
    proxSecuencia = Number((docRes.recordset as QueryRow[])[0]?.Secuencia ?? 0)
  }

  // Insertar líneas
  for (let i = 0; i < input.lineas.length; i++) {
    const l = input.lineas[i]
    const lineSub = l.cantidad * l.precioBase
    const lineDesc = l.descuentoLinea
    const lineImp = l.aplicaImpuesto ? (lineSub - lineDesc) * (l.porcentajeImpuesto / 100) : 0
    const lineTotal = lineSub - lineDesc + lineImp

    await pool.request()
      .input("IdDocumento",        idDocumento)
      .input("NumeroLinea",        i + 1)
      .input("IdProducto",         l.idProducto ?? null)
      .input("Codigo",             l.codigo ?? null)
      .input("Descripcion",        l.descripcion)
      .input("Cantidad",           l.cantidad)
      .input("Unidad",             l.unidad ?? null)
      .input("PrecioBase",         l.precioBase)
      .input("PorcentajeImpuesto", l.porcentajeImpuesto)
      .input("AplicaImpuesto",     l.aplicaImpuesto ? 1 : 0)
      .input("DescuentoLinea",     lineDesc)
      .input("SubTotalLinea",      lineSub)
      .input("ImpuestoLinea",      lineImp)
      .input("TotalLinea",         lineTotal)
      .query(`
        INSERT INTO dbo.FacDocumentoDetalle (
          IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
          Cantidad, Unidad, PrecioBase, PorcentajeImpuesto, AplicaImpuesto,
          AplicaPropina, DescuentoLinea, SubTotalLinea, ImpuestoLinea, TotalLinea, RowStatus
        ) VALUES (
          @IdDocumento, @NumeroLinea, @IdProducto, @Codigo, @Descripcion,
          @Cantidad, @Unidad, @PrecioBase, @PorcentajeImpuesto, @AplicaImpuesto,
          0, @DescuentoLinea, @SubTotalLinea, @ImpuestoLinea, @TotalLinea, 1
        )
      `)
  }

  return { idDocumento, secuencia: proxSecuencia }
}

export async function anularFacDocumento(
  idDocumento: number,
  motivoAnulacion: string,
  idUsuario: number,
): Promise<void> {
  const pool = await getPool()
  await pool.request()
    .input("Accion", "A")
    .input("IdDocumento", idDocumento)
    .input("MotivoAnulacion", motivoAnulacion)
    .input("IdUsuarioAccion", idUsuario)
    .execute("dbo.spFacDocumentosCRUD")
}

export async function createNotaCreditoDesdeFactura(params: {
  idDocumentoOrigen: number
  idUsuario: number
  motivo?: string
  lineas: Array<{ idDocumentoDetalle: number; cantidadDevolucion: number }>
}): Promise<{ idDocumento: number; secuencia: number }> {
  const pool = await getPool()

  // 1. Cargar cabecera + detalle de la factura origen
  const origen = await getFacDocumento(params.idDocumentoOrigen)
  if (!origen) throw new Error("Factura origen no encontrada.")
  if (origen.doc.tipoPrefijo !== "FAC")
    throw new Error("Solo se pueden generar notas de crédito desde facturas.")

  // 2. Obtener el tipo de documento NC
  const tiposRes = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spFacTiposDocumentoCRUD")
  const tipoNC = ((tiposRes.recordset as QueryRow[]).map(mapFacTipoDocRow)).find((t) => t.prefijo === "NC" && t.active)
  if (!tipoNC) throw new Error("No existe tipo de documento NC configurado. Configure un tipo con prefijo 'NC' en Facturación > Configuración.")

  // 3. Calcular la próxima secuencia para NC
  const seqResult = await pool.request()
    .input("IdTipoDocNC", tipoNC.id)
    .query(`
      SELECT ISNULL(MAX(Secuencia), 0) + 1 AS ProxSecuencia
      FROM dbo.FacDocumentos
      WHERE IdTipoDocumento = @IdTipoDocNC AND RowStatus = 1
    `)
  const proxSecuencia: number = Number((seqResult.recordset as QueryRow[])[0]?.ProxSecuencia ?? 1)

  // 4. Filtrar las líneas de devolución (solo las que tienen cantidad > 0)
  const lineasDevolucion = params.lineas.filter((l) => l.cantidadDevolucion > 0)
  if (lineasDevolucion.length === 0) throw new Error("Debe seleccionar al menos una línea para devolver.")

  const lineasOrigen = origen.lineas.filter((l) =>
    lineasDevolucion.some((d) => d.idDocumentoDetalle === l.idDocumentoDetalle)
  )

  // 5. Recalcular totales de la NC
  let subTotal = 0, descuento = 0, impuesto = 0, propina = 0
  for (const linea of lineasOrigen) {
    const devolucion = lineasDevolucion.find((d) => d.idDocumentoDetalle === linea.idDocumentoDetalle)
    if (!devolucion) continue
    const factor = devolucion.cantidadDevolucion / (linea.cantidad || 1)
    subTotal  += linea.subTotalLinea  * factor
    impuesto  += linea.impuestoLinea  * factor
    descuento += linea.descuentoLinea * factor
  }
  const total = subTotal + impuesto - descuento + propina

  // 6. Insertar cabecera NC
  const cabeceraRes = await pool.request()
    .input("Accion",               "I")
    .input("IdTipoDocumento",      tipoNC.id)
    .input("IdDocumentoOrigen",    params.idDocumentoOrigen)
    .input("IdPuntoEmision",       origen.doc.idPuntoEmision)
    .input("IdUsuario",            params.idUsuario)
    .input("IdCliente",            origen.doc.idCliente ?? null)
    .input("RNCCliente",           origen.doc.rncCliente ?? null)
    .input("Secuencia",            proxSecuencia)
    .input("FechaDocumento",       new Date().toISOString().slice(0, 10))
    .input("SubTotal",             subTotal)
    .input("Descuento",            descuento)
    .input("Impuesto",             impuesto)
    .input("Propina",              propina)
    .input("Total",                total)
    .input("Comentario",           params.motivo ?? null)
    .input("IdUsuarioAccion",      params.idUsuario)
    .execute("dbo.spFacDocumentosCRUD")

  const idDocumento = Number((cabeceraRes.recordset as QueryRow[])[0]?.IdDocumento ?? 0)
  if (!idDocumento) throw new Error("Error al crear la nota de crédito.")

  // 7. Insertar líneas NC con cantidades de devolución
  for (const linea of lineasOrigen) {
    const devolucion = lineasDevolucion.find((d) => d.idDocumentoDetalle === linea.idDocumentoDetalle)
    if (!devolucion) continue
    const factor = devolucion.cantidadDevolucion / (linea.cantidad || 1)
    const cantDev = devolucion.cantidadDevolucion
    const subtotalLinea = linea.subTotalLinea  * factor
    const impuestoLinea = linea.impuestoLinea  * factor
    const descuentoLinea = linea.descuentoLinea * factor
    const totalLinea = subtotalLinea + impuestoLinea - descuentoLinea

    await pool.request()
      .input("IdDocumento",         idDocumento)
      .input("NumeroLinea",         linea.numeroLinea)
      .input("IdProducto",          linea.idProducto ?? null)
      .input("Codigo",              linea.codigo ?? null)
      .input("Descripcion",         linea.descripcion)
      .input("Cantidad",            cantDev)
      .input("Unidad",              linea.unidad ?? null)
      .input("PrecioBase",          linea.precioBase)
      .input("PorcentajeImpuesto",  linea.porcentajeImpuesto)
      .input("AplicaImpuesto",      linea.aplicaImpuesto ? 1 : 0)
      .input("AplicaPropina",       linea.aplicaPropina ? 1 : 0)
      .input("DescuentoLinea",      descuentoLinea)
      .input("SubTotalLinea",       subtotalLinea)
      .input("ImpuestoLinea",       impuestoLinea)
      .input("TotalLinea",          totalLinea)
      .query(`
        INSERT INTO dbo.FacDocumentoDetalle (
          IdDocumento, NumeroLinea, IdProducto, Codigo, Descripcion,
          Cantidad, Unidad, PrecioBase, PorcentajeImpuesto, AplicaImpuesto,
          AplicaPropina, DescuentoLinea, ComentarioLinea,
          SubTotalLinea, ImpuestoLinea, TotalLinea, RowStatus
        ) VALUES (
          @IdDocumento, @NumeroLinea, @IdProducto, @Codigo, @Descripcion,
          @Cantidad, @Unidad, @PrecioBase, @PorcentajeImpuesto, @AplicaImpuesto,
          @AplicaPropina, @DescuentoLinea, NULL,
          @SubTotalLinea, @ImpuestoLinea, @TotalLinea, 1
        )
      `)
  }

  return { idDocumento, secuencia: proxSecuencia }
}

export type ResumenVentasRow = {
  periodo: string
  tipoPrefijo: string
  cantidadDocumentos: number
  subTotal: number
  descuento: number
  impuesto: number
  propina: number
  total: number
  pagoEfectivo: number
  pagoTarjeta: number
  pagoCheque: number
  pagoTransferencia: number
  pagoCredito: number
  pagoOtros: number
}

export async function getResumenVentas(params: {
  idPuntoEmision?: number
  fechaDesde: string
  fechaHasta: string
  agrupador: "dia" | "semana" | "mes" | "tipo"
}): Promise<ResumenVentasRow[]> {
  const pool = await getPool()

  const groupExpr = params.agrupador === "tipo"
    ? "t.Prefijo"
    : params.agrupador === "mes"
    ? "FORMAT(d.FechaDocumento, 'yyyy-MM')"
    : params.agrupador === "semana"
    ? "CAST(DATEPART(year, d.FechaDocumento) AS VARCHAR) + '-W' + RIGHT('0' + CAST(DATEPART(week, d.FechaDocumento) AS VARCHAR), 2)"
    : "CAST(d.FechaDocumento AS VARCHAR(10))"

  const result = await pool.request()
    .input("FechaDesde", params.fechaDesde)
    .input("FechaHasta", params.fechaHasta)
    .input("IdPuntoEmision", params.idPuntoEmision ?? null)
    .query(`
      SELECT
        ${groupExpr}                                                      AS Periodo,
        t.Prefijo                                                         AS TipoPrefijo,
        COUNT(d.IdDocumento)                                              AS CantidadDocumentos,
        SUM(d.SubTotal)                                                   AS SubTotal,
        SUM(d.Descuento)                                                  AS Descuento,
        SUM(d.Impuesto)                                                   AS Impuesto,
        SUM(d.Propina)                                                    AS Propina,
        SUM(d.Total)                                                      AS Total,
        SUM(CASE WHEN f.TipoValor = 'EF' THEN p.Monto ELSE 0 END)        AS PagoEfectivo,
        SUM(CASE WHEN f.TipoValor = 'TC' THEN p.Monto ELSE 0 END)        AS PagoTarjeta,
        SUM(CASE WHEN f.TipoValor = 'CH' THEN p.Monto ELSE 0 END)        AS PagoCheque,
        SUM(CASE WHEN f.TipoValor = 'OV' THEN p.Monto ELSE 0 END)        AS PagoTransferencia,
        SUM(CASE WHEN f.TipoValor = 'VC' THEN p.Monto ELSE 0 END)        AS PagoCredito,
        SUM(CASE WHEN f.TipoValor NOT IN ('EF','TC','CH','OV','VC') THEN p.Monto ELSE 0 END) AS PagoOtros
      FROM dbo.FacDocumentos d
      JOIN dbo.FacTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
      LEFT JOIN dbo.FacDocumentoPagos p ON p.IdDocumento = d.IdDocumento AND p.RowStatus = 1
      LEFT JOIN dbo.FacFormasPago f      ON f.IdFormaPago = p.IdFormaPago
      WHERE d.RowStatus = 1
        AND d.Estado <> 'N'
        AND t.Prefijo IN ('FAC','NC')
        AND d.FechaDocumento >= @FechaDesde
        AND d.FechaDocumento <= @FechaHasta
        AND (@IdPuntoEmision IS NULL OR d.IdPuntoEmision = @IdPuntoEmision)
      GROUP BY ${groupExpr}, t.Prefijo
      ORDER BY 1
    `)

  return (result.recordset as QueryRow[]).map((row) => ({
    periodo:              String(row.Periodo ?? ""),
    tipoPrefijo:          String(row.TipoPrefijo ?? ""),
    cantidadDocumentos:   Number(row.CantidadDocumentos ?? 0),
    subTotal:             Number(row.SubTotal ?? 0),
    descuento:            Number(row.Descuento ?? 0),
    impuesto:             Number(row.Impuesto ?? 0),
    propina:              Number(row.Propina ?? 0),
    total:                Number(row.Total ?? 0),
    pagoEfectivo:         Number(row.PagoEfectivo ?? 0),
    pagoTarjeta:          Number(row.PagoTarjeta ?? 0),
    pagoCheque:           Number(row.PagoCheque ?? 0),
    pagoTransferencia:    Number(row.PagoTransferencia ?? 0),
    pagoCredito:          Number(row.PagoCredito ?? 0),
    pagoOtros:            Number(row.PagoOtros ?? 0),
  }))
}

// ── Emitir factura desde POS ────────────────────────────────

export type EmitirFacturaPOSInput = {
  idDocumentoPOS: number
  idSesionCaja?: number | null
  idUsuario: number
  pagos: Array<{
    idFormaPago: number
    monto: number
    montoBase?: number
    idMoneda?: number | null
    tasaCambio?: number
    referencia?: string | null
    autorizacion?: string | null
  }>
  idTipoDocumento?: number
  ncf?: string | null
  idTipoNCF?: number | null
  rncCliente?: string | null
  fechaDocumento?: string
  comentario?: string | null
}

export type EmitirFacturaPOSResult = {
  idDocumento: number
  secuencia: number
  ncf: string | null
  documentoSecuencia: string
  total: number
  totalPagado: number
  estado: FacDocEstado
}

export async function emitirFacturaPOS(input: EmitirFacturaPOSInput): Promise<EmitirFacturaPOSResult> {
  const pool = await getPool()
  const pagosJSON = JSON.stringify(input.pagos.map((p) => ({
    IdFormaPago:  p.idFormaPago,
    Monto:        p.monto,
    MontoBase:    p.montoBase ?? p.monto,
    IdMoneda:     p.idMoneda ?? null,
    TasaCambio:   p.tasaCambio ?? 1,
    Referencia:   p.referencia ?? null,
    Autorizacion: p.autorizacion ?? null,
  })))

  const r = pool.request()
    .input("IdDocumentoPOS",   input.idDocumentoPOS)
    .input("IdSesionCaja",     input.idSesionCaja ?? null)
    .input("IdUsuario",        input.idUsuario)
    .input("PagosJSON",        pagosJSON)
    .input("IdTipoDocumento",  input.idTipoDocumento   ?? null)
    .input("NCF",              input.ncf               ?? null)
    .input("IdTipoNCF",        input.idTipoNCF         ?? null)
    .input("RNCCliente",       input.rncCliente        ?? null)
    .input("FechaDocumento",   input.fechaDocumento    ?? null)
    .input("Comentario",       input.comentario        ?? null)

  const result = await r.execute("dbo.spEmitirFacturaPOS")
  const row = (result.recordset as QueryRow[])[0]
  if (!row) throw new Error("spEmitirFacturaPOS no retornó resultado")

  return {
    idDocumento:        Number(row.IdDocumento),
    secuencia:          Number(row.Secuencia),
    ncf:                row.NCF ? String(row.NCF) : null,
    documentoSecuencia: String(row.DocumentoSecuencia ?? ""),
    total:              Number(row.Total ?? 0),
    totalPagado:        Number(row.TotalPagado ?? 0),
    estado:             (String(row.Estado ?? "I")) as FacDocEstado,
  }
}

// ─── Vendedores ────────────────────────────────────────────────

export type VendedorRecord = {
  id: number
  code: string
  nombre: string
  apellido: string
  idUsuario: number | null
  email: string
  telefono: string
  comisionPct: number
  active: boolean
}

function mapVendedorRow(row: QueryRow): VendedorRecord {
  return {
    id: toNumber(row.IdVendedor),
    code: toText(row.Codigo),
    nombre: toText(row.Nombre),
    apellido: toText(row.Apellido),
    idUsuario: row.IdUsuario != null ? toNumber(row.IdUsuario) : null,
    email: toText(row.Email),
    telefono: toText(row.Telefono),
    comisionPct: row.ComisionPct != null ? Number(row.ComisionPct) : 0,
    active: Boolean(row.Activo),
  }
}

export async function getVendedores(): Promise<VendedorRecord[]> {
  const pool = await getPool()
  const result = await pool.request()
    .input("Accion", "L")
    .execute("dbo.spVendedoresCRUD")
    .catch(() => ({ recordset: [] }))
  return (result.recordset as QueryRow[]).map(mapVendedorRow)
}

export async function saveVendedor(
  input: { id?: number; code: string; nombre: string; apellido?: string; idUsuario?: number | null; email?: string; telefono?: string; comisionPct?: number; active?: boolean },
  userId?: number,
  session?: SessionContext,
): Promise<VendedorRecord> {
  const pool = await getPool()
  const uid = userId ?? Number(process.env.MASU_DEMO_USER_ID ?? "1")
  const accion = input.id ? "U" : "I"
  const r = pool.request()
    .input("Accion", accion)
    .input("Codigo", input.code.trim().toUpperCase())
    .input("Nombre", input.nombre.trim())
    .input("Apellido", input.apellido?.trim() ?? null)
    .input("IdUsuario", input.idUsuario ?? null)
    .input("Email", input.email?.trim() ?? null)
    .input("Telefono", input.telefono?.trim() ?? null)
    .input("ComisionPct", input.comisionPct ?? 0)
    .input("Activo", input.active ?? true)
    .input("UsuarioCreacion", uid)
    .input("UsuarioModificacion", uid)
    .input("IdSesion", session?.sessionId ?? null)
    .input("TokenSesion", session?.token ?? null)
  if (input.id) r.input("IdVendedor", input.id)
  const result = await r.execute("dbo.spVendedoresCRUD")
  const row = (result.recordset as QueryRow[])[0]
  if (row) return mapVendedorRow(row)
  throw new Error("saveVendedor: SP no devolvió registro")
}

export async function deleteVendedor(id: number, session?: SessionContext): Promise<void> {
  const pool = await getPool()
  const uid = Number(process.env.MASU_DEMO_USER_ID ?? "1")
  await pool.request()
    .input("Accion", "D")
    .input("IdVendedor", id)
    .input("UsuarioModificacion", uid)
    .input("IdSesion", session?.sessionId ?? null)
    .input("TokenSesion", session?.token ?? null)
    .execute("dbo.spVendedoresCRUD")
}

