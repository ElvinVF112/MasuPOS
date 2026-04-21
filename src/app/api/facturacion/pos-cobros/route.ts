import { requireApiSession } from "@/lib/api-auth"
import { emitirFacturaPOS } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// POST /api/facturacion/pos-cobros
// body: { idDocumentoPOS, idSesionCaja, pagos: [{idFormaPago, monto, referencia?, autorizacion?}], ncf?, idTipoNCF?, rncCliente?, comentario? }
export async function POST(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    const { idDocumentoPOS, idSesionCaja, pagos } = body
    if (!idDocumentoPOS) return NextResponse.json({ ok: false, message: "idDocumentoPOS requerido" }, { status: 400 })
    if (!Array.isArray(pagos) || pagos.length === 0)
      return NextResponse.json({ ok: false, message: "Se requiere al menos una forma de pago" }, { status: 400 })

    const result = await emitirFacturaPOS({
      idDocumentoPOS: Number(idDocumentoPOS),
      idSesionCaja: idSesionCaja != null ? Number(idSesionCaja) : undefined,
      idUsuario: auth.session.userId,
      pagos,
      ncf: body.ncf ?? undefined,
      idTipoNCF: body.idTipoNCF ? Number(body.idTipoNCF) : undefined,
      rncCliente: body.rncCliente ?? undefined,
      idTipoDocumento: body.idTipoDocumento ? Number(body.idTipoDocumento) : undefined,
      fechaDocumento: body.fechaDocumento ?? undefined,
      comentario: body.comentario ?? undefined,
    })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al emitir factura" }, { status: 500 })
  }
}
