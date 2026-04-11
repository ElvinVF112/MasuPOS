import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getProductStock } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const params = await context.params
  const productId = Number(params.id)
  if (!Number.isFinite(productId) || productId <= 0) {
    return NextResponse.json({ ok: false, message: "Id de producto invalido." }, { status: 400 })
  }

  try {
    const stock = await getProductStock(productId)
    return NextResponse.json({ ok: true, stock })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo obtener existencias." },
      { status: 400 },
    )
  }
}
