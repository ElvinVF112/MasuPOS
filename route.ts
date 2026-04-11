import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateUnit, deleteUnit } from "@/lib/pos-data"
import { z } from "zod"

export const dynamic = "force-dynamic"

const putBodySchema = z.object({
  name: z.string().min(1, "El nombre es requerido"),
  abbreviation: z.string().optional(),
  baseA: z.number().int().min(1),
  baseB: z.number().int().min(1),
  active: z.boolean(),
})

export async function PUT(
  request: Request,
  { params }: { params: { id: string } }
) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const id = Number(params.id)
  if (isNaN(id)) {
    return NextResponse.json({ message: "ID de unidad inválido" }, { status: 400 })
  }

  const body = await request.json()
  const validation = putBodySchema.safeParse(body)
  if (!validation.success) {
    return NextResponse.json(validation.error.format(), { status: 400 })
  }

  try {
    const updatedUnit = await updateUnit(id, { ...validation.data, abbreviation: validation.data.abbreviation ?? "" })
    return NextResponse.json(updatedUnit)
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Error al actualizar la unidad"
    return NextResponse.json({ message: errorMessage }, { status: 500 })
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: { id: string } }
) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const id = Number(params.id)
  if (isNaN(id)) {
    return NextResponse.json({ message: "ID de unidad inválido" }, { status: 400 })
  }

  try {
    await deleteUnit(id)
    return new Response(null, { status: 204 })
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : "Error al eliminar la unidad"
    return NextResponse.json({ message: errorMessage }, { status: 500 })
  }
}

