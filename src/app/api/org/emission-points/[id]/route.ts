import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateEmissionPoint, deleteEmissionPoint } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    const body = (await request.json()) as {
      branchId: number
      name: string
      code?: string
      defaultPriceListId?: number | null
      defaultPosDocumentTypeId?: number | null
      defaultPosCustomerId?: number | null
      active?: boolean
    }
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    if (!body.branchId) return NextResponse.json({ ok: false, message: "La sucursal es obligatoria." }, { status: 400 })
    const result = await updateEmissionPoint(numId, {
      branchId: body.branchId,
      name: body.name,
      code: body.code,
      defaultPriceListId: body.defaultPriceListId,
      defaultPosDocumentTypeId: body.defaultPosDocumentTypeId,
      defaultPosCustomerId: body.defaultPosCustomerId,
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
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    await deleteEmissionPoint(numId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar." }, { status: 400 })
  }
}
