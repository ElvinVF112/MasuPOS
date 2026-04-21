import { requireApiSession } from "@/lib/api-auth"
import { listFacDocumentos, listFacDocumentosConPagos, saveFacDocumento } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// GET /api/facturacion/documentos?fechaDesde=&fechaHasta=&soloTipo=&soloEstado=&idPuntoEmision=&secuenciaDesde=&secuenciaHasta=&origenDocumento=&pageSize=&pageOffset=&incluirPagos=1
export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const sp = new URL(request.url).searchParams
  const pageSize      = Math.min(500, Math.max(1, Number(sp.get("pageSize")   ?? 100)))
  const pageOffset    = Math.max(0,              Number(sp.get("pageOffset")  ?? 0))
  const incluirPagos  = sp.get("incluirPagos") === "1"
  const origenRaw     = sp.get("origenDocumento")

  const queryParams = {
    fechaDesde:       sp.get("fechaDesde")     ?? undefined,
    fechaHasta:       sp.get("fechaHasta")     ?? undefined,
    soloTipo:         sp.get("soloTipo") ? Number(sp.get("soloTipo")) : undefined,
    soloEstado:       sp.get("soloEstado")     ?? undefined,
    idPuntoEmision:   sp.get("idPuntoEmision") ? Number(sp.get("idPuntoEmision")) : undefined,
    secuenciaDesde:   sp.get("secuenciaDesde") ? Number(sp.get("secuenciaDesde")) : undefined,
    secuenciaHasta:   sp.get("secuenciaHasta") ? Number(sp.get("secuenciaHasta")) : undefined,
    origenDocumento:  (origenRaw === "ORDEN" || origenRaw === "POS") ? (origenRaw as "ORDEN" | "POS") : undefined,
    pageSize,
    pageOffset,
  }

  try {
    const rows = incluirPagos
      ? await listFacDocumentosConPagos(queryParams)
      : await listFacDocumentos(queryParams)
    return NextResponse.json({ ok: true, data: rows, pageSize, pageOffset })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}

// POST /api/facturacion/documentos — crear nuevo documento
export async function POST(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.idTipoDocumento) return NextResponse.json({ ok: false, message: "idTipoDocumento requerido" }, { status: 400 })
    if (!body.idPuntoEmision)  return NextResponse.json({ ok: false, message: "idPuntoEmision requerido" }, { status: 400 })
    if (!Array.isArray(body.lineas) || body.lineas.length === 0)
      return NextResponse.json({ ok: false, message: "Se requiere al menos una línea" }, { status: 400 })

    const result = await saveFacDocumento({
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
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al guardar" }, { status: 500 })
  }
}
