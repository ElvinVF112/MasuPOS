import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getInvTiposDocumentoParaUsuario, type InvTipoOperacion } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { searchParams } = new URL(request.url)
    const tipo = searchParams.get("tipo") as InvTipoOperacion | null
    if (!tipo) return NextResponse.json({ ok: false, message: "El tipo de operacion es obligatorio." }, { status: 400 })
    const userId = auth.session?.userId ?? 1
    const data = await getInvTiposDocumentoParaUsuario(tipo, userId)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar tipos de documento." }, { status: 400 })
  }
}
