import { NextResponse } from "next/server"
import { getPermissionKeysByRole, type AuthSession } from "@/lib/auth-session"

function isPrivilegedUserType(userType?: string) {
  return userType === "A" || userType === "S"
}

export async function requireOrderPermission(
  session: AuthSession,
  requiredPermission: string,
  fallbacks: string[] = ["orders.view"],
) {
  if (isPrivilegedUserType(session.userType)) {
    return null
  }

  const permissionKeys = await getPermissionKeysByRole(session.roleId)
  const allowed = permissionKeys.includes(requiredPermission) || fallbacks.some((key) => permissionKeys.includes(key))

  if (!allowed) {
    return NextResponse.json(
      { ok: false, message: "No tienes permisos para ejecutar esta operacion de órdenes." },
      { status: 403 },
    )
  }

  return null
}
