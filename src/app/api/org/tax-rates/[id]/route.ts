import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateTaxRate, deleteTaxRate } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    const body = (await request.json()) as { name: string; rate: number; code: string; active?: boolean }
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El código es obligatorio." }, { status: 400 })
    const result = await updateTaxRate(numId, { name: body.name, rate: body.rate, code: body.code, active: body.active })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la tasa de impuesto." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    await deleteTaxRate(numId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar la tasa de impuesto." }, { status: 400 })
  }
}
