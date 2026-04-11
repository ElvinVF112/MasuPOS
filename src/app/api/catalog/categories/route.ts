import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCategories, saveCategory, deleteCategory } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const data = await getCategories()
    return NextResponse.json(
      { ok: true, data },
      { headers: { "Cache-Control": "no-store, no-cache, must-revalidate" } },
    )
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudieron cargar las categorías." },
      { status: 400 },
    )
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    const saved = await saveCategory(body, auth.session.userId, auth.session)
    return NextResponse.json({ ok: true, data: saved })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo guardar la categoría." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    if (!body.id) {
      return NextResponse.json({ ok: false, message: "Se requiere el ID para actualizar." }, { status: 400 })
    }
    const saved = await saveCategory(body, auth.session.userId, auth.session)
    return NextResponse.json({ ok: true, data: saved })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la categoría." },
      { status: 400 },
    )
  }
}

export async function DELETE(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    if (!body.id) {
      return NextResponse.json({ ok: false, message: "Se requiere el ID para eliminar." }, { status: 400 })
    }
    await deleteCategory(body.id, auth.session)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar la categoría." },
      { status: 400 },
    )
  }
}
