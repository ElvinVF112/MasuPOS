import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { createOrder, listOrders } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.view")
  if (denied) return denied

  try {
    const orders = await listOrders()
    return NextResponse.json({ ok: true, orders })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudieron listar las ordenes." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.create")
  if (denied) return denied

  try {
    const body = await request.json()
    const created = await createOrder(body, auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
      userType: auth.session.userType,
    })
    return NextResponse.json({ ok: true, orderId: created.id })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear la orden." },
      { status: 400 },
    )
  }
}
