import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getEmissionPoints, createEmissionPoint } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getEmissionPoints() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar puntos de emision." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
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
    const result = await createEmissionPoint({
      branchId: body.branchId,
      name: body.name,
      code: body.code,
      defaultPriceListId: body.defaultPriceListId,
      defaultPosDocumentTypeId: body.defaultPosDocumentTypeId,
      defaultPosCustomerId: body.defaultPosCustomerId,
      active: body.active,
    })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el punto de emision." }, { status: 400 })
  }
}
