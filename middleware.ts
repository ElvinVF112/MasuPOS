import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"
import { AUTH_COOKIE_PERMISSION_KEYS } from "@/lib/auth-cookies"
import { getPermissionKeyByPath, parsePermissionKeys } from "@/lib/permissions"

const PUBLIC_PATHS = new Set(["/login"])

function isPublicPath(pathname: string) {
  if (PUBLIC_PATHS.has(pathname)) return true
  if (pathname.includes(".")) return true
  if (pathname.startsWith("/_next")) return true
  if (pathname.startsWith("/favicon")) return true
  if (pathname.startsWith("/api/auth/login")) return true
  if (pathname.startsWith("/api/auth/logout")) return true
  if (pathname.startsWith("/api/auth/me")) return true
  if (pathname.startsWith("/api/company/public")) return true
  if (pathname.startsWith("/api/company/logo/public")) return true
  return false
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  const sessionId = request.cookies.get("masu_session_id")?.value
  const token = request.cookies.get("masu_session_token")?.value
  const permissionRaw = request.cookies.get(AUTH_COOKIE_PERMISSION_KEYS)?.value

  if (isPublicPath(pathname)) {
    return NextResponse.next()
  }

  if (pathname === "/") {
    if (!sessionId || !token) {
      return NextResponse.redirect(new URL("/login", request.url))
    }
    return NextResponse.redirect(new URL("/dashboard", request.url))
  }

  if (!sessionId || !token) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ ok: false, message: "Sesion requerida." }, { status: 401 })
    }
    return NextResponse.redirect(new URL("/login", request.url))
  }

  const requiredPermission = getPermissionKeyByPath(pathname)
  if (!requiredPermission) {
    return NextResponse.next()
  }

  const permissionKeys = parsePermissionKeys(permissionRaw)
  if (!permissionKeys.includes(requiredPermission)) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ ok: false, message: "No autorizado." }, { status: 403 })
    }
    return new NextResponse("No autorizado.", { status: 403 })
  }

  return NextResponse.next()
}

export const config = {
  matcher: ["/:path*"],
}
