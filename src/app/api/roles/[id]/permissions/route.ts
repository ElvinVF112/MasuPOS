import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getRoleRoutePermissions } from "@/lib/auth-session"
import { getRolePermissionsByModule, updateRolePermission } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

function isSuperAdmin(roleId: number, roleName: string) {
  const normalized = roleName.trim().toLowerCase()
  return roleId === 1 || normalized === "admin" || normalized === "administrador" || normalized === "administrador general"
}

export async function GET(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const routePermissions = await getRoleRoutePermissions(auth.session.roleId)
  const roleRoute = routePermissions.find((item) => item.route === "/config/security/roles")
  if (!isSuperAdmin(auth.session.roleId, auth.session.role) && !roleRoute?.canView) {
    return NextResponse.json({ ok: false, message: "No autorizado." }, { status: 403 })
  }

  const { id } = await context.params
  const roleId = Number(id)
  if (!Number.isFinite(roleId) || roleId <= 0) {
    return NextResponse.json({ ok: false, message: "Id de rol invalido." }, { status: 400 })
  }

  try {
    const data = await getRolePermissionsByModule(roleId)
    return NextResponse.json({ ok: true, ...data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo obtener permisos del rol." }, { status: 400 })
  }
}

export async function PUT(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const routePermissions = await getRoleRoutePermissions(auth.session.roleId)
  const roleRoute = routePermissions.find((item) => item.route === "/config/security/roles")
  if (!isSuperAdmin(auth.session.roleId, auth.session.role) && !roleRoute?.canEdit) {
    return NextResponse.json({ ok: false, message: "No autorizado." }, { status: 403 })
  }

  const { id } = await context.params
  const roleId = Number(id)
  if (!Number.isFinite(roleId) || roleId <= 0) {
    return NextResponse.json({ ok: false, message: "Id de rol invalido." }, { status: 400 })
  }

  try {
    const body = (await request.json()) as {
      type?: "MODULO" | "PANTALLA" | "PERMISO_GRANULAR" | "CAMPO"
      objectId?: number
      fieldKey?: string
      value?: boolean
      permissionField?: string
    }

    if (!body.type || typeof body.value !== "boolean") {
      return NextResponse.json({ ok: false, message: "Payload invalido." }, { status: 400 })
    }

    await updateRolePermission({
      roleId,
      type: body.type,
      objectId: body.objectId,
      fieldKey: body.fieldKey,
      value: body.value,
      permissionField: body.permissionField,
    })

    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar permisos del rol." }, { status: 400 })
  }
}
