import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updatePriceList, deletePriceList } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const numericId = Number(id)

    if (!Number.isFinite(numericId) || numericId <= 0) {
      return NextResponse.json(
        { ok: false, message: `Id invalido: "${id}" -> ${numericId}` },
        { status: 400 },
      )
    }

    const body = await request.json()
    const record = await updatePriceList(numericId, body)
    return NextResponse.json({ ok: true, data: record })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? `[updatePriceList] ${error.message}` : "No se pudo actualizar la lista de precios." },
      { status: 400 },
    )
  }
}

export async function DELETE(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const numericId = Number(id)

    if (!Number.isFinite(numericId) || numericId <= 0) {
      return NextResponse.json(
        { ok: false, message: `Id invalido: "${id}" -> ${numericId}` },
        { status: 400 },
      )
    }

    await deletePriceList(numericId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? `[deletePriceList] ${error.message}` : "No se pudo eliminar la lista de precios." },
      { status: 400 },
    )
  }
}
