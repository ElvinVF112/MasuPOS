import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPuntosFacFormaPago, setPuntosFacFormaPago } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const data = await getPuntosFacFormaPago(Number(id))
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error." }, { status: 400 })
  }
}

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json() as { puntosEmision: number[] }
    const data = await setPuntosFacFormaPago(Number(id), body.puntosEmision ?? [])
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error." }, { status: 400 })
  }
}
