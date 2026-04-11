import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getInvTiposDocumento, saveInvTipoDocumento, type InvTipoOperacion } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { searchParams } = new URL(request.url)
    const tipo = searchParams.get("tipo") as InvTipoOperacion | null
    const data = await getInvTiposDocumento(tipo ?? undefined)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar tipos de documento." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = await request.json()
    if (!body.description?.trim()) return NextResponse.json({ ok: false, message: "La descripcion es obligatoria." }, { status: 400 })
    if (!body.tipoOperacion) return NextResponse.json({ ok: false, message: "El tipo de operacion es obligatorio." }, { status: 400 })
    const result = await saveInvTipoDocumento(body, auth.session)
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el tipo de documento." }, { status: 400 })
  }
}
