import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getFacCajasPOS, saveFacCajaPOS } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const data = await getFacCajasPOS()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar cajas." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.descripcion?.trim()) return NextResponse.json({ ok: false, message: "La descripción es obligatoria." }, { status: 400 })
    if (!body.idSucursal) return NextResponse.json({ ok: false, message: "La sucursal es obligatoria." }, { status: 400 })
    const result = await saveFacCajaPOS(body)
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear." }, { status: 400 })
  }
}
