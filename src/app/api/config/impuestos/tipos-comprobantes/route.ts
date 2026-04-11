import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCatalogoNCF } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getCatalogoNCF() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar el catálogo NCF." }, { status: 400 })
  }
}
