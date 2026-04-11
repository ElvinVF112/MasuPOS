import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { mergeOrders } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.edit")
  if (denied) return denied

  try {
    const body = await request.json()
    const targetOrderId = Number(body?.targetOrderId)
    const sourceOrderIds = Array.isArray(body?.sourceOrderIds) ? body.sourceOrderIds.map((value: unknown) => Number(value)) : []

    if (!Number.isInteger(targetOrderId) || targetOrderId <= 0) {
      throw new Error("Selecciona una orden destino valida.")
    }

    if (!sourceOrderIds.length) {
      throw new Error("Selecciona al menos una orden origen para unificar.")
    }

    const order = await mergeOrders(
      { targetOrderId, sourceOrderIds },
      auth.session.userId,
      {
        sessionId: auth.session.sessionId,
        token: auth.session.token,
        userType: auth.session.userType,
      },
    )

    return NextResponse.json({ ok: true, order })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo unificar las ordenes." },
      { status: 400 },
    )
  }
}

