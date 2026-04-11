import { requireApiSession } from "@/lib/api-auth"
import { getPriceListsForUser } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const { searchParams } = new URL(request.url)
  const productId = searchParams.get("productId") ? Number(searchParams.get("productId")) : undefined

  try {
    const lists = await getPriceListsForUser(auth.session.userId, productId)
    return NextResponse.json({ ok: true, data: lists })
  } catch (error) {
    const message = error instanceof Error ? error.message : "Error al obtener listas de precios"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
