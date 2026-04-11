import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getInvProductoPorCodigo } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { searchParams } = new URL(request.url)
    const code = searchParams.get("code")?.trim()
    if (!code) return NextResponse.json({ ok: false, message: "El codigo es obligatorio." }, { status: 400 })
    const idAlmacen = searchParams.get("almacen") ? Number(searchParams.get("almacen")) : undefined
    const data = await getInvProductoPorCodigo(code, idAlmacen)
    if (!data) return NextResponse.json({ ok: false, message: "Producto no encontrado." }, { status: 404 })
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al buscar producto." }, { status: 400 })
  }
}
