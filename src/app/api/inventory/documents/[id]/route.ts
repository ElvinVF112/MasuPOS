import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getInvDocumento, anularInvDocumento, updateInvDocumento } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const data = await getInvDocumento(Number(id))
    if (!data) return NextResponse.json({ ok: false, message: "Documento no encontrado." }, { status: 404 })
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const data = await anularInvDocumento(Number(id), auth.session)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo anular el documento." }, { status: 400 })
  }
}

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    if (!body.idTipoDocumento) return NextResponse.json({ ok: false, message: "El tipo de documento es obligatorio." }, { status: 400 })
    if (!body.fecha) return NextResponse.json({ ok: false, message: "La fecha es obligatoria." }, { status: 400 })
    if (!body.idAlmacen) return NextResponse.json({ ok: false, message: "El almacen es obligatorio." }, { status: 400 })
    if (body.idProveedor != null && (!Number.isFinite(Number(body.idProveedor)) || Number(body.idProveedor) <= 0)) {
      return NextResponse.json({ ok: false, message: "El proveedor es invalido." }, { status: 400 })
    }
    if (!Array.isArray(body.lineas) || body.lineas.length === 0) return NextResponse.json({ ok: false, message: "Debe agregar al menos una linea al documento." }, { status: 400 })
    const data = await updateInvDocumento(Number(id), body, auth.session)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el documento." }, { status: 400 })
  }
}
