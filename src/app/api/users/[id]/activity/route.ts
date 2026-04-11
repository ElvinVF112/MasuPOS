import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPermissionKeysByRole } from "@/lib/auth-session"
import { getUserActivity } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  const permissions = await getPermissionKeysByRole(auth.session.roleId)
  if (!permissions.includes("config.security.users.view")) {
    return NextResponse.json({ ok: false, message: "No autorizado." }, { status: 403 })
  }

  const { id } = await context.params
  const userId = Number(id)
  if (!Number.isFinite(userId) || userId <= 0) {
    return NextResponse.json({ ok: false, message: "Id de usuario invalido." }, { status: 400 })
  }

  try {
    const data = await getUserActivity(userId, 12)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo obtener la actividad del usuario." },
      { status: 400 },
    )
  }
}
