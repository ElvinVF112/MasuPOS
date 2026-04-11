import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateCatalogoNCF } from "@/lib/pos-data"

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    const result = await updateCatalogoNCF(Number(id), {
      nombreInterno: body.nombreInterno,
      active: body.active,
    })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el tipo de comprobante." }, { status: 400 })
  }
}
