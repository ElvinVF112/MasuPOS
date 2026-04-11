import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCurrencyHistory } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const currencyId = searchParams.get("currencyId")
    const dateFrom = searchParams.get("dateFrom")
    const dateTo = searchParams.get("dateTo")
    const page = searchParams.get("page")

    const data = await getCurrencyHistory({
      currencyId: currencyId ? Number(currencyId) : undefined,
      dateFrom: dateFrom ?? undefined,
      dateTo: dateTo ?? undefined,
      page: page ? Number(page) : 1,
    })

    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar el historial." },
      { status: 400 },
    )
  }
}
