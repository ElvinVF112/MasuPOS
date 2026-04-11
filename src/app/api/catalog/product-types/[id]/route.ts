import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateProductType, deleteProductType } from "@/lib/pos-data"

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const typeId = Number(id)
    if (isNaN(typeId)) {
      return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    }

    const body = (await request.json()) as { name: string; description?: string; active?: boolean }
    if (!body.name?.trim()) {
      return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    }

    const result = await updateProductType(typeId, {
      name: body.name.trim(),
      description: body.description?.trim() || "",
      active: body.active ?? true,
    })

    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el tipo de producto." },
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
    const typeId = Number(id)
    if (isNaN(typeId)) {
      return NextResponse.json({ ok: false, message: "ID inválido." }, { status: 400 })
    }

    await deleteProductType(typeId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el tipo de producto." },
      { status: 400 },
    )
  }
}