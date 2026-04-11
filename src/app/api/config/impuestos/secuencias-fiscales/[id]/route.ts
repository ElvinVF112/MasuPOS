import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { saveSecuenciaNCF, deleteSecuenciaNCF } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    if (!body.idCatalogoNCF) return NextResponse.json({ ok: false, message: "El tipo de comprobante es obligatorio." }, { status: 400 })
    const result = await saveSecuenciaNCF({ ...body, id: Number(id) })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la secuencia NCF." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    await deleteSecuenciaNCF(Number(id))
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar la secuencia NCF." }, { status: 400 })
  }
}
