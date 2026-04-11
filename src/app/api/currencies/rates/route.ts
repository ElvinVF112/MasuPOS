import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCurrencies, saveCurrencyRate } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const data = await getCurrencies()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar las tasas." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json() as {
      items: Array<{
        currencyId: number
        date: string
        administrativeRate?: number
        operativeRate?: number
        purchaseRate?: number
        saleRate?: number
      }>
    }
    if (!Array.isArray(body.items) || body.items.length === 0) {
      return NextResponse.json({ ok: false, message: "Debe enviar al menos una tasa." }, { status: 400 })
    }

    const saved = []
    for (const item of body.items) {
      const rate = await saveCurrencyRate({
        currencyId: item.currencyId,
        date: item.date,
        administrativeRate: item.administrativeRate,
        operativeRate: item.operativeRate,
        purchaseRate: item.purchaseRate,
        saleRate: item.saleRate,
      })
      saved.push(rate)
    }

    return NextResponse.json({ ok: true, data: saved })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo guardar las tasas." },
      { status: 400 },
    )
  }
}
