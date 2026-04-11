import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { saveFacFormaPago, deleteFacFormaPago } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    if (!body.descripcion?.trim()) return NextResponse.json({ ok: false, message: "La descripción es obligatoria." }, { status: 400 })
    const result = await saveFacFormaPago({ ...body, id: Number(id) })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    await deleteFacFormaPago(Number(id))
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar." }, { status: 400 })
  }
}
