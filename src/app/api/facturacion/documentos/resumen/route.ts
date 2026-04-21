import { requireApiSession } from "@/lib/api-auth"
import { getResumenVentas } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// GET /api/facturacion/documentos/resumen?fechaDesde=&fechaHasta=&agrupador=dia|semana|mes|tipo
export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const sp = new URL(request.url).searchParams
  const fechaDesde = sp.get("fechaDesde")
  const fechaHasta = sp.get("fechaHasta")
  if (!fechaDesde || !fechaHasta)
    return NextResponse.json({ ok: false, message: "fechaDesde y fechaHasta son requeridos" }, { status: 400 })
  const agrupador = (sp.get("agrupador") ?? "dia") as "dia" | "semana" | "mes" | "tipo"
  try {
    const rows = await getResumenVentas({ fechaDesde, fechaHasta, agrupador })
    return NextResponse.json({ ok: true, data: rows })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}
