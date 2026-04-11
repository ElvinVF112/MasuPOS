import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { saveFacCajaPOS, deleteFacCajaPOS, getFacCajaPOSUsuarios, syncFacCajaPOSUsuarios } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    if (!body.descripcion?.trim()) return NextResponse.json({ ok: false, message: "La descripción es obligatoria." }, { status: 400 })
    const result = await saveFacCajaPOS({ ...body, id: Number(id) })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    await deleteFacCajaPOS(Number(id))
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar." }, { status: 400 })
  }
}

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const { searchParams } = new URL(request.url)
    if (searchParams.get("section") === "users") {
      const data = await getFacCajaPOSUsuarios(Number(id))
      return NextResponse.json({ ok: true, data })
    }
    return NextResponse.json({ ok: false, message: "Sección no encontrada." }, { status: 404 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error." }, { status: 400 })
  }
}

export async function PATCH(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const body = await request.json()
    if (!Array.isArray(body.userIds)) return NextResponse.json({ ok: false, message: "userIds debe ser un array." }, { status: 400 })
    const data = await syncFacCajaPOSUsuarios(Number(id), body.userIds as number[])
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo sincronizar usuarios." }, { status: 400 })
  }
}
