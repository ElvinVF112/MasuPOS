import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { splitOrder } from "@/lib/pos-data"
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
    const lineIds = Array.isArray(body?.lineIds) ? body.lineIds.map((value: unknown) => Number(value)) : []
    const reference = typeof body?.reference === "string" ? body.reference : ""

    const result = await splitOrder(
      {
        orderId: Number(id),
        orderLineIds: lineIds,
        reference,
      },
      auth.session.userId,
      {
        sessionId: auth.session.sessionId,
        token: auth.session.token,
        userType: auth.session.userType,
      },
    )

    return NextResponse.json({ ok: true, ...result })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo dividir la orden." },
      { status: 400 },
    )
  }
}
