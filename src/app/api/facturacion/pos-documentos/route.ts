import { requireApiSession } from "@/lib/api-auth"
import { getFacDocumentosPOS, saveFacDocumentoPOS } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// GET /api/facturacion/pos-documentos?idPuntoEmision=X
export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const idPuntoEmision = Number(new URL(request.url).searchParams.get("idPuntoEmision"))
  if (!idPuntoEmision) return NextResponse.json({ ok: false, message: "idPuntoEmision requerido" }, { status: 400 })
  try {
    const docs = await getFacDocumentosPOS(idPuntoEmision)
    return NextResponse.json({ ok: true, data: docs })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}

// POST /api/facturacion/pos-documentos  → pausar nuevo
export async function POST(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.idPuntoEmision) return NextResponse.json({ ok: false, message: "idPuntoEmision requerido" }, { status: 400 })
    if (!Array.isArray(body.lineas) || body.lineas.length === 0)
      return NextResponse.json({ ok: false, message: "El documento no tiene líneas." }, { status: 400 })
    const id = await saveFacDocumentoPOS({ ...body, idUsuario: auth.session.userId }, "I")
    return NextResponse.json({ ok: true, data: { id } }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al pausar" }, { status: 500 })
  }
}
