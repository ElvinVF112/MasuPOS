import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPuntosSecuenciaHija, setPuntosSecuenciaHija } from "@/lib/pos-data"

export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const data = await getPuntosSecuenciaHija(Number(id))
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al obtener puntos." }, { status: 400 })
  }
}

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json() as { puntosEmision: number[] }
    const data = await setPuntosSecuenciaHija(Number(id), body.puntosEmision ?? [])
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al guardar puntos." }, { status: 400 })
  }
}
