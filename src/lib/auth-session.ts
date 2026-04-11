import { getPool } from "@/lib/db"
import { AUTH_COOKIE_PERMISSION_KEYS, AUTH_COOKIE_SESSION_ID, AUTH_COOKIE_SESSION_TOKEN } from "@/lib/auth-cookies"


export { AUTH_COOKIE_PERMISSION_KEYS, AUTH_COOKIE_SESSION_ID, AUTH_COOKIE_SESSION_TOKEN }

export type AuthSession = {
  sessionId: number
  token: string
  userId: number
  roleId: number
  userType: "A" | "S" | "O"
  role: string
  fullName: string
  username: string
  email: string
  defaultRoute: string
  mustChangePassword: boolean
  canDeletePosLines: boolean
  canChangePosDate: boolean
  sessionDurationMinutes: number
  sessionIdleMinutes: number
}

export type RoutePermission = {
  route: string
  canView: boolean
  canCreate: boolean
  canEdit: boolean
  canDelete: boolean
  canApprove: boolean
  canCancel: boolean
  canPrint: boolean
}

type QueryRow = Record<string, unknown>

function toNumber(value: unknown) {
  if (typeof value === "number") return value
  if (typeof value === "bigint") return Number(value)
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : 0
}

function toText(value: unknown) {
  return typeof value === "string" ? value : ""
}

function toUserType(value: unknown, role?: string): "A" | "S" | "O" {
  const normalized = toText(value).trim().toUpperCase()
  if (normalized === "A" || normalized === "S" || normalized === "O") return normalized
  const roleNormalized = (role ?? "").trim().toLowerCase()
  if (roleNormalized.includes("admin")) return "A"
  if (roleNormalized.includes("supervisor")) return "S"
  return "O"
}

function mapSession(row: QueryRow): AuthSession {
  const role = toText(row.Rol)
  return {
    sessionId: toNumber(row.IdSesion),
    token: toText(row.TokenSesion),
    userId: toNumber(row.IdUsuario),
    roleId: toNumber(row.IdRol),
    userType: toUserType(row.TipoUsuario, role),
    role,
    fullName: `${toText(row.Nombres)} ${toText(row.Apellidos)}`.trim(),
    username: toText(row.NombreUsuario),
    email: toText(row.Correo),
    defaultRoute: toText(row.RutaInicio) || "/dashboard",
    mustChangePassword: Boolean(row.RequiereCambioClave),
    canDeletePosLines: Boolean(row.PuedeEliminarLineaPOS),
    canChangePosDate: Boolean(row.PuedeCambiarFechaPOS),
    sessionDurationMinutes: Math.max(1, toNumber(row.SesionDuracionMinutos) || 600),
    sessionIdleMinutes: Math.max(1, toNumber(row.SesionIdleMinutos) || 30),
  }
}

export async function loginSession(input: {
  username: string
  passwordHash: string
  ipAddress?: string
  userAgent?: string
  idCaja?: number
}) {
  const pool = await getPool()
  const request = pool.request()
    .input("NombreUsuario", input.username)
    .input("ClaveHash", input.passwordHash)
    .input("Canal", "WEB")
    .input("IpAddress", input.ipAddress ?? null)
    .input("UserAgent", input.userAgent ?? null)
    .input("IdCaja", input.idCaja ?? null)
    .input("CerrarSesionesPrevias", true)

  const result = await request.execute("dbo.spAuthLogin")
  const row = result.recordset?.[0] as QueryRow | undefined
  if (!row) {
    throw new Error("No fue posible iniciar sesion.")
  }
  return mapSession(row)
}

export async function validateSession(input: { sessionId?: number; token?: string }) {
  const pool = await getPool()
  const result = await pool
    .request()
    .input("IdSesion", input.sessionId ?? 0)
    .input("TokenSesion", input.token ?? null)
    .execute("dbo.spAuthValidarSesion")

  const row = result.recordset?.[0] as QueryRow | undefined
  if (!row) return null
  return mapSession(row)
}

export async function closeSession(input: { sessionId?: number; token?: string; notes?: string }) {
  const pool = await getPool()
  await pool
    .request()
    .input("IdSesion", input.sessionId ?? 0)
    .input("TokenSesion", input.token ?? null)
    .input("Observaciones", input.notes ?? null)
    .execute("dbo.spAuthCerrarSesion")
}

export async function heartbeatSession(input: { sessionId?: number; token?: string }) {
  const pool = await getPool()
  await pool
    .request()
    .input("IdSesion", input.sessionId ?? 0)
    .input("TokenSesion", input.token ?? null)
    .execute("dbo.spAuthHeartbeat")
}

export async function getRoleRoutePermissions(roleId: number): Promise<RoutePermission[]> {
  const pool = await getPool()
  const result = await pool.request().input("IdRol", roleId).query(`
    SET NOCOUNT ON;
    SELECT
      LOWER(LTRIM(RTRIM(PA.Ruta))) AS Ruta,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanView, 0) ELSE 0 END) AS BIT) AS CanView,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanCreate, 0) ELSE 0 END) AS BIT) AS CanCreate,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanEdit, 0) ELSE 0 END) AS BIT) AS CanEdit,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanDelete, 0) ELSE 0 END) AS BIT) AS CanDelete,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanApprove, 0) ELSE 0 END) AS BIT) AS CanApprove,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanCancel, 0) ELSE 0 END) AS BIT) AS CanCancel,
      CAST(MAX(CASE WHEN RPP.AccessEnabled = 1 THEN ISNULL(RPP.CanPrint, 0) ELSE 0 END) AS BIT) AS CanPrint
    FROM dbo.Pantallas PA
    LEFT JOIN dbo.RolPantallaPermisos RPP ON RPP.IdPantalla = PA.IdPantalla AND RPP.IdRol = @IdRol
    WHERE PA.RowStatus = 1 AND PA.Activo = 1 AND NULLIF(LTRIM(RTRIM(PA.Ruta)), '') IS NOT NULL
    GROUP BY LOWER(LTRIM(RTRIM(PA.Ruta)));
  `)

  return result.recordset.map((row) => ({
    route: toText(row.Ruta),
    canView: toNumber(row.CanView) === 1,
    canCreate: toNumber(row.CanCreate) === 1,
    canEdit: toNumber(row.CanEdit) === 1,
    canDelete: toNumber(row.CanDelete) === 1,
    canApprove: toNumber(row.CanApprove) === 1,
    canCancel: toNumber(row.CanCancel) === 1,
    canPrint: toNumber(row.CanPrint) === 1,
  }))
}

export async function getPermissionKeysByRole(roleId: number): Promise<string[]> {
  const pool = await getPool()
  const result = await pool.request().input("IdRol", roleId).execute("dbo.spPermisosObtenerPorRol")
  const keys = new Set<string>()

  for (const row of result.recordset as QueryRow[]) {
    const clave = toText(row.Clave)
    if (clave) keys.add(clave)
  }

  return [...keys]
}
