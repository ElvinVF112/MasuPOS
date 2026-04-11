import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { distribuirSecuenciaNCF } from "@/lib/pos-data"

export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    if (!body.idSecuenciaMadre) return NextResponse.json({ ok: false, message: "La secuencia madre es obligatoria." }, { status: 400 })
    if (!body.cantidadDistribuir || body.cantidadDistribuir <= 0) return NextResponse.json({ ok: false, message: "La cantidad a distribuir debe ser mayor a cero." }, { status: 400 })
    const result = await distribuirSecuenciaNCF({
      idSecuencia: Number(id),
      idSecuenciaMadre: body.idSecuenciaMadre,
      cantidadDistribuir: body.cantidadDistribuir,
      observacion: body.observacion,
    })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo realizar la distribución." }, { status: 400 })
  }
}
