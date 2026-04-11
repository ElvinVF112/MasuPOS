import { NextResponse } from "next/server"
import { AUTH_COOKIE_SESSION_ID, AUTH_COOKIE_SESSION_TOKEN, validateSession } from "@/lib/auth-session"

export async function requireApiSession(request: Request) {
  const sessionIdRaw = request.headers.get("cookie")?.match(new RegExp(`${AUTH_COOKIE_SESSION_ID}=([^;]+)`))?.[1]
  const tokenRaw = request.headers.get("cookie")?.match(new RegExp(`${AUTH_COOKIE_SESSION_TOKEN}=([^;]+)`))?.[1]

  const sessionId = sessionIdRaw ? Number(decodeURIComponent(sessionIdRaw)) : 0
  const token = tokenRaw ? decodeURIComponent(tokenRaw) : ""

  if (!sessionId && !token) {
    return { ok: false as const, response: NextResponse.json({ ok: false, message: "Sesion requerida." }, { status: 401 }) }
  }

  const session = await validateSession({ sessionId: sessionId || undefined, token: token || undefined })
  if (!session) {
    return { ok: false as const, response: NextResponse.json({ ok: false, message: "Sesion invalida o expirada." }, { status: 401 }) }
  }

  return { ok: true as const, session }
}
