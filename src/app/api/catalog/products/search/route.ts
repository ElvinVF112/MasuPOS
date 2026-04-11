import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { searchProducts } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = (await request.json().catch(() => ({}))) as { q?: string; limit?: number }
    const query = String(body.q ?? "")
    const limit = Number(body.limit ?? 80)
    const items = await searchProducts({ query, limit: Number.isFinite(limit) ? limit : 80 })
    return NextResponse.json({ ok: true, items })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo buscar productos." },
      { status: 400 },
    )
  }
}
