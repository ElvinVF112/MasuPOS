import { requireApiSession } from "@/lib/api-auth"
import { getDiscountsForUser } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const discounts = await getDiscountsForUser(auth.session.userId)
    return NextResponse.json({ ok: true, data: discounts })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Error al obtener descuentos"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
