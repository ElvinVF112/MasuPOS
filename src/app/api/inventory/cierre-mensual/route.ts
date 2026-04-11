import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { ejecutarCierreMensual } from "@/lib/pos-data"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = (await request.json()) as { periodo?: string }
    const periodo = (body.periodo ?? "").trim()
    if (!/^\d{6}$/.test(periodo)) {
      return NextResponse.json({ ok: false, message: "Periodo invalido. Use YYYYMM." }, { status: 400 })
    }

    const data = await ejecutarCierreMensual(periodo)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo ejecutar cierre mensual." },
      { status: 400 },
    )
  }
}
