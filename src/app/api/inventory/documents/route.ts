import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { listInvDocumentos, createInvDocumento, type InvTipoOperacion } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { searchParams } = new URL(request.url)
    const data = await listInvDocumentos({
      tipoOperacion: (searchParams.get("tipo") as InvTipoOperacion) || undefined,
      idAlmacen: searchParams.get("almacen") ? Number(searchParams.get("almacen")) : undefined,
      idTipoDocumento: searchParams.get("tipoDoc") ? Number(searchParams.get("tipoDoc")) : undefined,
      fechaDesde: searchParams.get("desde") || undefined,
      fechaHasta: searchParams.get("hasta") || undefined,
      secuenciaDesde: searchParams.get("secDesde") ? Number(searchParams.get("secDesde")) : undefined,
      secuenciaHasta: searchParams.get("secHasta") ? Number(searchParams.get("secHasta")) : undefined,
      page: searchParams.get("page") ? Number(searchParams.get("page")) : undefined,
      pageSize: searchParams.get("pageSize") ? Number(searchParams.get("pageSize")) : undefined,
    })
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar documentos." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.idTipoDocumento) return NextResponse.json({ ok: false, message: "El tipo de documento es obligatorio." }, { status: 400 })
    if (!body.fecha) return NextResponse.json({ ok: false, message: "La fecha es obligatoria." }, { status: 400 })
    if (!body.idAlmacen) return NextResponse.json({ ok: false, message: "El almacen es obligatorio." }, { status: 400 })
    if (body.idProveedor != null && (!Number.isFinite(Number(body.idProveedor)) || Number(body.idProveedor) <= 0)) {
      return NextResponse.json({ ok: false, message: "El proveedor es invalido." }, { status: 400 })
    }
    if (!Array.isArray(body.lineas) || body.lineas.length === 0) return NextResponse.json({ ok: false, message: "Debe agregar al menos una linea al documento." }, { status: 400 })
    const result = await createInvDocumento(body, auth.session)
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el documento." }, { status: 400 })
  }
}
