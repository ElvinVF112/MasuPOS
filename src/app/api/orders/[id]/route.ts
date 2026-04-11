import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getOrderById, updateOrderHeader } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

type Context = {
  params: Promise<{ id: string }>
}

export async function GET(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.view")
  if (denied) return denied

  const { id } = await context.params

  try {
    const order = await getOrderById(Number(id), auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
      userType: auth.session.userType,
    })
    if (!order) {
      return NextResponse.json({ ok: false, message: "Orden no encontrada." }, { status: 404 })
    }
    return NextResponse.json({ ok: true, order })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo consultar la orden." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.edit")
  if (denied) return denied

  const { id } = await context.params

  try {
    const body = await request.json()
    const order = await updateOrderHeader(Number(id), body, auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
      userType: auth.session.userType,
    })
    return NextResponse.json({ ok: true, order })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la orden." },
      { status: 400 },
    )
  }
}
