import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { createDemoOrder } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.create")
  if (denied) return denied

  try {
    const result = await createDemoOrder(auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
    })
    return NextResponse.json({ ok: true, orderId: result.id })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear la orden demo." },
      { status: 400 },
    )
  }
}
