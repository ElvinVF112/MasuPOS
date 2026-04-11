import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { anularTransferencia, getInvTransferencia, updateInvTransferencia } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const data = await getInvTransferencia(Number(id))
    if (!data) return NextResponse.json({ ok: false, message: "Transferencia no encontrada." }, { status: 404 })
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error." }, { status: 400 })
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
    if (!body.idAlmacen) return NextResponse.json({ ok: false, message: "El almacen origen es obligatorio." }, { status: 400 })
    if (!body.idAlmacenDestino) return NextResponse.json({ ok: false, message: "El almacen destino es obligatorio." }, { status: 400 })
    if (Number(body.idAlmacen) === Number(body.idAlmacenDestino)) {
      return NextResponse.json({ ok: false, message: "El almacen origen debe ser diferente al destino." }, { status: 400 })
    }
    if (!Array.isArray(body.lineas) || body.lineas.length === 0) {
      return NextResponse.json({ ok: false, message: "Debe agregar al menos una linea a la transferencia." }, { status: 400 })
    }

    const data = await updateInvTransferencia(Number(id), body, auth.session)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la transferencia." },
      { status: 400 },
    )
  }
}

export async function DELETE(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const data = await anularTransferencia(Number(id), auth.session)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo anular la transferencia." },
      { status: 400 },
    )
  }
}
