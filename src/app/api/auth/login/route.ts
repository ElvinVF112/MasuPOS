import { createHash } from "node:crypto"
import { NextResponse } from "next/server"
import { AUTH_COOKIE_PERMISSION_KEYS, AUTH_COOKIE_SESSION_ID, AUTH_COOKIE_SESSION_TOKEN, getPermissionKeysByRole, loginSession } from "@/lib/auth-session"
import { serializePermissionKeys } from "@/lib/permissions"

function toSha256Base64(value: string) {
  return createHash("sha256").update(value).digest("base64")
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as { username?: string; password?: string; idCaja?: number }
    const username = body.username?.trim() ?? ""
    const password = body.password ?? ""

    if (!username || !password) {
      return NextResponse.json({ ok: false, message: "Usuario y clave son requeridos." }, { status: 400 })
    }

    const ipAddress = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "127.0.0.1"
    const userAgent = request.headers.get("user-agent") ?? "web-client"

    let session
    try {
      session = await loginSession({
        username,
        passwordHash: toSha256Base64(password),
        ipAddress,
        userAgent,
        idCaja: body.idCaja,
      })
    } catch {
      session = await loginSession({
        username,
        passwordHash: password,
        ipAddress,
        userAgent,
        idCaja: body.idCaja,
      })
    }

    const permissionKeys = await getPermissionKeysByRole(session.roleId)

    const response = NextResponse.json({ ok: true, user: session, permissions: permissionKeys })
    const secure = process.env.NODE_ENV === "production"

    const maxAge = session.sessionDurationMinutes * 60

    response.cookies.set(AUTH_COOKIE_SESSION_ID, String(session.sessionId), {
      httpOnly: true,
      secure,
      sameSite: "strict",
      path: "/",
      maxAge,
    })

    response.cookies.set(AUTH_COOKIE_SESSION_TOKEN, session.token, {
      httpOnly: true,
      secure,
      sameSite: "strict",
      path: "/",
      maxAge,
    })

    response.cookies.set(AUTH_COOKIE_PERMISSION_KEYS, serializePermissionKeys(permissionKeys), {
      httpOnly: true,
      secure,
      sameSite: "strict",
      path: "/",
      maxAge,
    })

    return response
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo iniciar sesion." },
      { status: 401 },
    )
  }
}
