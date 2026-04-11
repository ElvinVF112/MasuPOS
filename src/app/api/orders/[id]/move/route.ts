import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { moveOrderToResource } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

type Context = {
  params: Promise<{ id: string }>
}

export async function POST(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.edit")
  if (denied) return denied

  const { id } = await context.params

  try {
    const body = await request.json()
    const resourceId = Number(body?.resourceId)
    if (!Number.isInteger(resourceId) || resourceId <= 0) {
      throw new Error("Selecciona un recurso valido.")
    }

    const order = await moveOrderToResource(Number(id), resourceId, auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
      userType: auth.session.userType,
    })
    return NextResponse.json({ ok: true, order })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo mover la orden." },
      { status: 400 },
    )
  }
}
