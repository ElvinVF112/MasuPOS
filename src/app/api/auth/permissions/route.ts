import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPermissionKeysByRole } from "@/lib/auth-session"
import { ROUTE_PERMISSIONS } from "@/lib/permissions"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  const roleName = auth.session.role.trim().toLowerCase()
  const isSuperAdmin = auth.session.roleId === 1 || roleName === "administrador" || roleName === "administrador general"
  if (isSuperAdmin) {
    const allKeys = [...new Set(ROUTE_PERMISSIONS.map((item) => item.key))]
    return NextResponse.json({ ok: true, permissions: allKeys })
  }

  const permissions = await getPermissionKeysByRole(auth.session.roleId)
  return NextResponse.json({ ok: true, permissions })
}
