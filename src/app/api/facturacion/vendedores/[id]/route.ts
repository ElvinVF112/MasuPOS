import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { saveVendedor, deleteVendedor } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const idNum = Number(id)
    if (!idNum) return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    const body = await request.json()
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El codigo es obligatorio." }, { status: 400 })
    if (!body.nombre?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    const result = await saveVendedor({
      id: idNum,
      code: body.code,
      nombre: body.nombre,
      apellido: body.apellido || undefined,
      idUsuario: body.idUsuario ?? null,
      email: body.email || undefined,
      telefono: body.telefono || undefined,
      comisionPct: body.comisionPct ?? 0,
      active: body.active ?? true,
    })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el vendedor." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const idNum = Number(id)
    if (!idNum) return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    await deleteVendedor(idNum)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el vendedor." }, { status: 400 })
  }
}
