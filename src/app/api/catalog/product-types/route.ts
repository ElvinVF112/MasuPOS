import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getProductTypes, createProductType } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const types = await getProductTypes()
    return NextResponse.json({ ok: true, data: types })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudieron cargar los tipos de producto." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = (await request.json()) as { name: string; description?: string; active?: boolean }
    if (!body.name?.trim()) {
      return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    }

    const result = await createProductType({
      name: body.name.trim(),
      description: body.description?.trim() || "",
      active: body.active ?? true,
    })

    return NextResponse.json({ ok: true, data: result }, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo crear el tipo de producto." },
      { status: 400 },
    )
  }
}