import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { generarSalidaTransferencia } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function POST(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const data = await generarSalidaTransferencia(Number(id), auth.session)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo generar la salida." },
      { status: 400 },
    )
  }
}
