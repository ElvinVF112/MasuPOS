import { createHash } from "node:crypto"
import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { verifySupervisorCredentials } from "@/lib/pos-data"

function toSha256Base64(value: string) {
  return createHash("sha256").update(value).digest("base64")
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = (await request.json()) as { username?: string; password?: string; permissionKey?: string }
    const username = body.username?.trim() ?? ""
    const password = body.password ?? ""
    const permissionKey = body.permissionKey?.trim() ?? ""

    if (!username || !password || !permissionKey) {
      return NextResponse.json({ ok: false, message: "Usuario, clave y permiso son requeridos." }, { status: 400 })
    }

    let supervisor
    try {
      supervisor = await verifySupervisorCredentials({
        username,
        passwordHash: toSha256Base64(password),
        permissionKey,
      })
    } catch {
      supervisor = await verifySupervisorCredentials({
        username,
        passwordHash: password,
        permissionKey,
      })
    }

    return NextResponse.json({ ok: true, supervisor })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo verificar el supervisor." },
      { status: 401 },
    )
  }
}
