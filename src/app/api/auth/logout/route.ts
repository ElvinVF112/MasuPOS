import { NextResponse } from "next/server"
import { AUTH_COOKIE_PERMISSION_KEYS, AUTH_COOKIE_SESSION_ID, AUTH_COOKIE_SESSION_TOKEN, closeSession } from "@/lib/auth-session"

export async function POST(request: Request) {
  const cookieHeader = request.headers.get("cookie") ?? ""
  const sessionIdRaw = cookieHeader.match(new RegExp(`${AUTH_COOKIE_SESSION_ID}=([^;]+)`))?.[1]
  const tokenRaw = cookieHeader.match(new RegExp(`${AUTH_COOKIE_SESSION_TOKEN}=([^;]+)`))?.[1]

  const sessionId = sessionIdRaw ? Number(decodeURIComponent(sessionIdRaw)) : 0
  const token = tokenRaw ? decodeURIComponent(tokenRaw) : ""

  try {
    if (sessionId || token) {
      await closeSession({ sessionId: sessionId || undefined, token: token || undefined, notes: "Logout web" })
    }
  } catch {
    // ignore close session errors on logout
  }

  const response = NextResponse.json({ ok: true })
  response.cookies.set(AUTH_COOKIE_SESSION_ID, "", { httpOnly: true, path: "/", expires: new Date(0) })
  response.cookies.set(AUTH_COOKIE_SESSION_TOKEN, "", { httpOnly: true, path: "/", expires: new Date(0) })
  response.cookies.set(AUTH_COOKIE_PERMISSION_KEYS, "", { httpOnly: true, path: "/", expires: new Date(0) })
  return response
}
