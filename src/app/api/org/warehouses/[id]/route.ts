import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateWarehouse, deleteWarehouse } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    const body = (await request.json()) as {
      description: string
      initials: string
      type?: string
      transitWarehouseId?: number | null
      active?: boolean
    }
    if (!body.description?.trim()) return NextResponse.json({ ok: false, message: "La descripcion es obligatoria." }, { status: 400 })
    if (!body.initials?.trim()) return NextResponse.json({ ok: false, message: "Las siglas son obligatorias." }, { status: 400 })
    if ((body.type ?? "O") !== "T" && !body.transitWarehouseId) {
      return NextResponse.json({ ok: false, message: "El almacen de transito es obligatorio." }, { status: 400 })
    }
    const result = await updateWarehouse(numId, {
      description: body.description,
      initials: body.initials,
      type: body.type,
      transitWarehouseId: (body.type ?? "O") === "T" ? null : (body.transitWarehouseId ?? null),
      active: body.active,
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
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    await deleteWarehouse(numId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar." }, { status: 400 })
  }
}
