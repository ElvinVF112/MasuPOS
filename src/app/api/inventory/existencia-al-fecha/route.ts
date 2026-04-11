import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getExistenciaAlFecha } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const fecha = (searchParams.get("fecha") || "").trim()
    if (!fecha) {
      return NextResponse.json({ ok: false, message: "Parametro fecha es requerido." }, { status: 400 })
    }

    const productoRaw = searchParams.get("producto")
    const almacenRaw = searchParams.get("almacen")
    const idProducto = productoRaw ? Number(productoRaw) : undefined
    const idAlmacen = almacenRaw ? Number(almacenRaw) : undefined

    if (productoRaw && (!Number.isFinite(idProducto) || Number(idProducto) <= 0)) {
      return NextResponse.json({ ok: false, message: "Parametro producto invalido." }, { status: 400 })
    }
    if (almacenRaw && (!Number.isFinite(idAlmacen) || Number(idAlmacen) <= 0)) {
      return NextResponse.json({ ok: false, message: "Parametro almacen invalido." }, { status: 400 })
    }

    const data = await getExistenciaAlFecha(fecha, idProducto, idAlmacen)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo consultar existencia." },
      { status: 400 },
    )
  }
}
