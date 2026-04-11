import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateUnit, deleteUnit } from "@/lib/pos-data"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const unitId = Number(id)
    if (isNaN(unitId) || unitId <= 0) {
      return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    }

    const body = (await request.json()) as { name: string; abbreviation: string; baseA?: number; baseB?: number; active?: boolean }
    if (!body.name?.trim()) {
      return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    }

    const result = await updateUnit(unitId, {
      name: body.name.trim(),
      abbreviation: body.abbreviation.trim(),
      baseA: body.baseA ?? 1,
      baseB: body.baseB ?? 1,
      active: body.active ?? true,
    })

    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la unidad." },
      { status: 400 },
    )
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const unitId = Number(id)
    if (isNaN(unitId) || unitId <= 0) {
      return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    }

    await deleteUnit(unitId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar la unidad." },
      { status: 400 },
    )
  }
}
