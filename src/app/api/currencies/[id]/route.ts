import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { deleteCurrency } from "@/lib/pos-data"

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id: idStr } = await params
    const id = Number(idStr)
    if (!Number.isFinite(id) || id <= 0) {
      return NextResponse.json({ ok: false, message: "Id invalido." }, { status: 400 })
    }
    await deleteCurrency(id)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar la moneda." },
      { status: 400 },
    )
  }
}
