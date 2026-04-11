import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getOrderHistory } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

type Context = {
  params: Promise<{ id: string }>
}

export async function GET(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.history.view", ["orders.view"])
  if (denied) return denied

  const { id } = await context.params

  try {
    const history = await getOrderHistory(Number(id))
    return NextResponse.json({ ok: true, history })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo consultar el historial de la orden." },
      { status: 400 },
    )
  }
}
