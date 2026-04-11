import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { closeOrder } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

type Context = {
  params: Promise<{ id: string }>
}

export async function POST(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.close")
  if (denied) return denied

  const { id } = await context.params

  try {
    await closeOrder(Number(id), auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
      userType: auth.session.userType,
    })
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cerrar la orden." },
      { status: 400 },
    )
  }
}
