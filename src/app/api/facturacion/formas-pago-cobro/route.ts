import { requireApiSession } from "@/lib/api-auth"
import { getFormasPagoParaCobro } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// GET /api/facturacion/formas-pago-cobro?idPuntoEmision=X
export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const idPuntoEmision = Number(new URL(request.url).searchParams.get("idPuntoEmision"))
  if (!idPuntoEmision) return NextResponse.json({ ok: false, message: "idPuntoEmision requerido" }, { status: 400 })
  try {
    const data = await getFormasPagoParaCobro(idPuntoEmision)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}
