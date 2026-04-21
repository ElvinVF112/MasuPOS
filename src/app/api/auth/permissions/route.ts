import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPermissionKeysByRole, getRoleRoutePermissions, type RoutePermission } from "@/lib/auth-session"
import { ROUTE_PERMISSIONS, routeToPermissionKey } from "@/lib/permissions"

function buildActionPermissionKeys(routePermissions: RoutePermission[]) {
  const keys = new Set<string>()

  for (const permission of routePermissions) {
    const viewKey = routeToPermissionKey(permission.route)
    if (!viewKey) continue

    if (permission.canView) keys.add(viewKey)
    if (!viewKey.endsWith(".view")) continue

    const prefix = viewKey.slice(0, -5)
    if (permission.canCreate) keys.add(`${prefix}.create`)
    if (permission.canEdit) keys.add(`${prefix}.edit`)
    if (permission.canDelete) {
      keys.add(`${prefix}.delete`)
      keys.add(`${prefix}.void`)
    }
    if (permission.canApprove) {
      keys.add(`${prefix}.approve`)
      keys.add(`${prefix}.close`)
      keys.add(`${prefix}.manage`)
      keys.add(`${prefix}.generate-exit`)
      keys.add(`${prefix}.confirm-reception`)
      keys.add(`${prefix}.send-to-cash`)
    }
    if (permission.canCancel) {
      keys.add(`${prefix}.cancel`)
      keys.add(`${prefix}.anular`)
    }
    if (permission.canPrint) {
      keys.add(`${prefix}.print`)
      keys.add(`${prefix}.reimprimir`)
    }
  }

  return [...keys]
}

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  const seededPermissions = await getPermissionKeysByRole(auth.session.roleId)
  const routePermissions = await getRoleRoutePermissions(auth.session.roleId)
  const actionPermissions = buildActionPermissionKeys(routePermissions)
  const roleName = auth.session.role.trim().toLowerCase()
  const isSuperAdmin = auth.session.roleId === 1 || roleName === "administrador" || roleName === "administrador general"
  if (isSuperAdmin) {
    const allKeys = [...new Set([...ROUTE_PERMISSIONS.map((item) => item.key), ...seededPermissions, ...actionPermissions])]
    return NextResponse.json({ ok: true, permissions: allKeys })
  }

  const permissions = [...new Set([...seededPermissions, ...actionPermissions])]
  return NextResponse.json({ ok: true, permissions })
}
