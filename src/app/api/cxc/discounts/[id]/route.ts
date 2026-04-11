import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { saveDescuento, deleteDescuento } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    const body = await request.json()
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El codigo es obligatorio." }, { status: 400 })
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    const result = await saveDescuento({
      id: numId,
      code: body.code,
      name: body.name,
      porcentaje: body.porcentaje ?? 0,
      esGlobal: body.esGlobal ?? true,
      fechaInicio: body.fechaInicio || undefined,
      fechaFin: body.fechaFin || undefined,
      active: body.active,
      permiteManual: body.permiteManual ?? true,
      limiteDescuentoManual: body.limiteDescuentoManual !== "" && body.limiteDescuentoManual != null ? Number(body.limiteDescuentoManual) : null,
    })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    await deleteDescuento(numId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar." }, { status: 400 })
  }
}
