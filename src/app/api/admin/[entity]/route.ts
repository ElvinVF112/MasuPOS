import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getRoleRoutePermissions } from "@/lib/auth-session"
import { mutateAdminEntity, type AdminEntityName } from "@/lib/pos-data"

type Context = { params: Promise<{ entity: string }> }

const validEntities = new Set<AdminEntityName>([
  "users",
  "roles",
  "modules",
  "screens",
  "permissions",
  "role-permissions",
  "categories",
  "product-types",
  "units",
  "areas",
  "resource-types",
  "resource-categories",
])

const securityEntityRouteMap: Partial<Record<AdminEntityName, string>> = {
  users: "/config/security/users",
  roles: "/config/security/roles",
  modules: "/config/security/modules",
  screens: "/config/security/screens",
  permissions: "/config/security/permissions",
  "role-permissions": "/config/security/roles",
}

function isSuperAdmin(roleId: number, roleName: string) {
  const normalized = roleName.trim().toLowerCase()
  return roleId === 1 || normalized === "admin" || normalized === "administrador" || normalized === "administrador general"
}

async function canManageEntity(
  roleId: number,
  roleName: string,
  entity: AdminEntityName,
  method: "create" | "update" | "delete",
) {
  if (isSuperAdmin(roleId, roleName)) return true

  const route = securityEntityRouteMap[entity]
  if (!route) return true

  const permissions = await getRoleRoutePermissions(roleId)
  const match = permissions.find((item) => item.route === route)
  if (!match) return false

  if (method === "create") return match.canCreate
  if (method === "update") return match.canEdit
  return match.canDelete
}

async function handle(method: "create" | "update" | "delete", request: Request, context: Context) {
  const { entity } = await context.params
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  try {
    if (!validEntities.has(entity as AdminEntityName)) {
      return NextResponse.json({ ok: false, message: "Entidad no soportada." }, { status: 404 })
    }
    const entityName = entity as AdminEntityName
    const authorized = await canManageEntity(auth.session.roleId, auth.session.role, entityName, method)
    if (!authorized) {
      return NextResponse.json({ ok: false, message: "No autorizado." }, { status: 403 })
    }
    const body = await request.json()
    await mutateAdminEntity(entityName, method, body, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
    })
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo completar la operacion." }, { status: 400 })
  }
}

export async function POST(request: Request, context: Context) { return handle("create", request, context) }
export async function PUT(request: Request, context: Context) { return handle("update", request, context) }
export async function DELETE(request: Request, context: Context) { return handle("delete", request, context) }
