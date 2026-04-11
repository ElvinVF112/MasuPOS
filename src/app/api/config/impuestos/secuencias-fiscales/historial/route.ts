import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getHistorialDistribucionNCF } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { searchParams } = new URL(request.url)
    const result = await getHistorialDistribucionNCF({
      idSecuenciaMadre: searchParams.get("madre") ? Number(searchParams.get("madre")) : undefined,
      idSecuenciaHija:  searchParams.get("hija")  ? Number(searchParams.get("hija"))  : undefined,
      fechaDesde: searchParams.get("desde") ?? undefined,
      fechaHasta: searchParams.get("hasta") ?? undefined,
    })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar el historial." }, { status: 400 })
  }
}
