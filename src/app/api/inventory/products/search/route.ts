import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { searchInvProducto } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { searchParams } = new URL(request.url)
    const q = searchParams.get("q")?.trim()
    if (!q) return NextResponse.json({ ok: true, data: [] })
    const idAlmacen = searchParams.get("almacen") ? Number(searchParams.get("almacen")) : undefined
    const data = await searchInvProducto(q, idAlmacen)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al buscar productos." }, { status: 400 })
  }
}
