import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCategoriasCliente, saveCategoriaCliente } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getCategoriasCliente() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar categorias de cliente." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El codigo es obligatorio." }, { status: 400 })
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    const result = await saveCategoriaCliente({ code: body.code, name: body.name, active: body.active })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear la categoria." }, { status: 400 })
  }
}
