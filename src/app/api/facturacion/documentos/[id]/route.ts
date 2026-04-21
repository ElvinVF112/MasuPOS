import { requireApiSession } from "@/lib/api-auth"
import { anularFacDocumento, createNotaCreditoDesdeFactura, getFacDocumento, saveFacDocumento } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// GET /api/facturacion/documentos/[id]
export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const { id } = await params
  const numId = Number(id)
  if (!numId) return NextResponse.json({ ok: false, message: "ID inválido" }, { status: 400 })
  try {
    const doc = await getFacDocumento(numId)
    if (!doc) return NextResponse.json({ ok: false, message: "No encontrado" }, { status: 404 })
    return NextResponse.json({ ok: true, data: doc })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}

// PUT /api/facturacion/documentos/[id]
// body: { accion: "anular", motivo: string }
export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const { id } = await params
  const numId = Number(id)
  if (!numId) return NextResponse.json({ ok: false, message: "ID inválido" }, { status: 400 })
  try {
    const body = await request.json()
    if (body.accion === "anular") {
      if (!body.motivo?.trim())
        return NextResponse.json({ ok: false, message: "El motivo de anulación es requerido." }, { status: 400 })
      await anularFacDocumento(numId, body.motivo, auth.session.userId)
      return NextResponse.json({ ok: true })
    }

    if (body.accion === "devolucion") {
      if (!Array.isArray(body.lineas) || body.lineas.length === 0)
        return NextResponse.json({ ok: false, message: "Se requieren las líneas de devolución." }, { status: 400 })
      const result = await createNotaCreditoDesdeFactura({
        idDocumentoOrigen: numId,
        idUsuario: auth.session.userId,
        motivo: body.motivo ?? undefined,
        lineas: body.lineas,
      })
      return NextResponse.json({ ok: true, data: result }, { status: 201 })
    }

    if (body.accion === "editar") {
      if (!Array.isArray(body.lineas) || body.lineas.length === 0)
        return NextResponse.json({ ok: false, message: "Se requiere al menos una línea" }, { status: 400 })
      const result = await saveFacDocumento({
        idDocumento:         numId,
        idTipoDocumento:     body.idTipoDocumento,
        idPuntoEmision:      body.idPuntoEmision,
        idUsuario:           auth.session.userId,
        idCliente:           body.idCliente ?? null,
        rncCliente:          body.rncCliente ?? null,
        ncf:                 body.ncf ?? null,
        idTipoNCF:           body.idTipoNCF ?? null,
        fecha:               body.fecha,
        comentario:          body.comentario ?? null,
        lineas:              body.lineas,
      })
      return NextResponse.json({ ok: true, data: result })
    }

    return NextResponse.json({ ok: false, message: "Acción no reconocida" }, { status: 400 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}
