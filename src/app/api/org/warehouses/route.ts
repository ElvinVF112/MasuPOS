import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getWarehouses, createWarehouse } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getWarehouses() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar almacenes." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
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
    const result = await createWarehouse({
      description: body.description,
      initials: body.initials,
      type: body.type,
      transitWarehouseId: (body.type ?? "O") === "T" ? null : (body.transitWarehouseId ?? null),
      active: body.active,
    })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el almacen." }, { status: 400 })
  }
}
