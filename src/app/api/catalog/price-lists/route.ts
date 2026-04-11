import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPriceLists, createPriceList } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const data = await getPriceLists()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar las listas de precios." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    const record = await createPriceList(body)
    return NextResponse.json({ ok: true, data: record }, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear la lista de precios." },
      { status: 400 },
    )
  }
}
