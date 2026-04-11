import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getUnits, createUnit } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const units = await getUnits()
    return NextResponse.json({ ok: true, data: units })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudieron cargar las unidades." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = (await request.json()) as { name: string; abbreviation: string; baseA?: number; baseB?: number; active?: boolean }
    if (!body.name?.trim()) {
      return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    }
    if (!body.abbreviation?.trim()) {
      return NextResponse.json({ ok: false, message: "La abreviatura es obligatoria." }, { status: 400 })
    }

    const result = await createUnit({
      name: body.name.trim(),
      abbreviation: body.abbreviation.trim(),
      baseA: body.baseA ?? 1,
      baseB: body.baseB ?? 1,
      active: body.active ?? true,
    })

    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear la unidad." },
      { status: 400 },
    )
  }
}
