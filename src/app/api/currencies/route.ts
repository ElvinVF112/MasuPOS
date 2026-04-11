import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { createCurrency, getCurrencies, updateCurrency } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const data = await getCurrencies()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar las monedas." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json() as Record<string, unknown>
    if (!body.code || !body.name) {
      return NextResponse.json({ ok: false, message: "Codigo y nombre son requeridos." }, { status: 400 })
    }
    const id = await createCurrency({
      code: String(body.code),
      name: String(body.name),
      symbol: body.symbol != null ? String(body.symbol) : null,
      symbolAlt: body.symbolAlt != null ? String(body.symbolAlt) : null,
      bankCode: body.bankCode != null ? String(body.bankCode) : null,
      factorConversionLocal: body.factorConversionLocal != null ? Number(body.factorConversionLocal) : 1,
      factorConversionUSD: body.factorConversionUSD != null ? Number(body.factorConversionUSD) : 1,
      showInPOS: body.showInPOS !== false,
      acceptPayments: body.acceptPayments !== false,
      decimalPOS: body.decimalPOS != null ? Number(body.decimalPOS) : 2,
    })
    return NextResponse.json({ ok: true, id })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear la moneda." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    const { id, ...fields } = body as { id: number } & Record<string, unknown>
    if (!Number.isFinite(id) || id <= 0) {
      return NextResponse.json({ ok: false, message: "Id invalido." }, { status: 400 })
    }
    await updateCurrency(id, fields)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la moneda." },
      { status: 400 },
    )
  }
}
