import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getTaxRates, createTaxRate } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    return NextResponse.json({ ok: true, data: await getTaxRates() })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar tasas de impuesto." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const body = (await request.json()) as { name: string; rate: number; code: string; active?: boolean }
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El código es obligatorio." }, { status: 400 })
    if (body.rate == null || isNaN(body.rate)) return NextResponse.json({ ok: false, message: "La tasa es obligatoria." }, { status: 400 })
    const result = await createTaxRate({ name: body.name, rate: body.rate, code: body.code, active: body.active })
    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear la tasa de impuesto." }, { status: 400 })
  }
}
