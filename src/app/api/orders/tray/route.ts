import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getOrdersTrayData } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.view")
  if (denied) return denied

  try {
    const data = await getOrdersTrayData()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la bandeja de ordenes." },
      { status: 400 },
    )
  }
}
