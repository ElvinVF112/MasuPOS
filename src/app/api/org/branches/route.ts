import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getBranches, createBranch } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getBranches() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar sucursales." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = (await request.json()) as { divisionId: number; name: string; description?: string; address?: string; active?: boolean }
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    if (!body.divisionId) return NextResponse.json({ ok: false, message: "La division es obligatoria." }, { status: 400 })
    const result = await createBranch({ divisionId: body.divisionId, name: body.name, description: body.description, address: body.address, active: body.active })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear la sucursal." }, { status: 400 })
  }
}
