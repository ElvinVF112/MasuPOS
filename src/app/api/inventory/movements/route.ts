import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getInvMovimientos } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const idProducto = Number(searchParams.get("producto"))
    const idAlmacenRaw = searchParams.get("almacen")
    const desde = searchParams.get("desde") || undefined
    const hasta = searchParams.get("hasta") || undefined

    if (!Number.isFinite(idProducto) || idProducto <= 0) {
      return NextResponse.json({ ok: false, message: "Parametro producto invalido." }, { status: 400 })
    }

    const idAlmacen = idAlmacenRaw ? Number(idAlmacenRaw) : undefined
    if (idAlmacenRaw && (!Number.isFinite(idAlmacen) || Number(idAlmacen) <= 0)) {
      return NextResponse.json({ ok: false, message: "Parametro almacen invalido." }, { status: 400 })
    }

    const data = await getInvMovimientos(idProducto, idAlmacen, desde, hasta)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo consultar movimientos." },
      { status: 400 },
    )
  }
}
