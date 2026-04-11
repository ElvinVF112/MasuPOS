import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { createInvTransferencia, listInvTransferencias, type InvTransferenciaEstado } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const data = await listInvTransferencias({
      idAlmacen: searchParams.get("almacen") ? Number(searchParams.get("almacen")) : undefined,
      idAlmacenDestino: searchParams.get("destino") ? Number(searchParams.get("destino")) : undefined,
      idTipoDocumento: searchParams.get("tipoDoc") ? Number(searchParams.get("tipoDoc")) : undefined,
      estadoTransferencia: (searchParams.get("estado") as InvTransferenciaEstado) || undefined,
      fechaDesde: searchParams.get("desde") || undefined,
      fechaHasta: searchParams.get("hasta") || undefined,
      page: searchParams.get("page") ? Number(searchParams.get("page")) : undefined,
      pageSize: searchParams.get("pageSize") ? Number(searchParams.get("pageSize")) : undefined,
    })
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "Error al cargar transferencias." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    if (!body.idTipoDocumento) return NextResponse.json({ ok: false, message: "El tipo de documento es obligatorio." }, { status: 400 })
    if (!body.fecha) return NextResponse.json({ ok: false, message: "La fecha es obligatoria." }, { status: 400 })
    if (!body.idAlmacen) return NextResponse.json({ ok: false, message: "El almacen origen es obligatorio." }, { status: 400 })
    if (!body.idAlmacenDestino) return NextResponse.json({ ok: false, message: "El almacen destino es obligatorio." }, { status: 400 })
    if (Number(body.idAlmacen) === Number(body.idAlmacenDestino)) {
      return NextResponse.json({ ok: false, message: "El almacen origen debe ser diferente al destino." }, { status: 400 })
    }
    if (!Array.isArray(body.lineas) || body.lineas.length === 0) {
      return NextResponse.json({ ok: false, message: "Debe agregar al menos una linea a la transferencia." }, { status: 400 })
    }

    const result = await createInvTransferencia(body, auth.session)
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear la transferencia." },
      { status: 400 },
    )
  }
}
