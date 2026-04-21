import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getVendedores, saveVendedor } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getVendedores() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar vendedores." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El codigo es obligatorio." }, { status: 400 })
    if (!body.nombre?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    const result = await saveVendedor({
      code: body.code,
      nombre: body.nombre,
      apellido: body.apellido || undefined,
      idUsuario: body.idUsuario ?? null,
      email: body.email || undefined,
      telefono: body.telefono || undefined,
      comisionPct: body.comisionPct ?? 0,
      active: body.active ?? true,
    })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el vendedor." }, { status: 400 })
  }
}
