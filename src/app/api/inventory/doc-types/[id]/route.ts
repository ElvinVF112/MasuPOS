import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { saveInvTipoDocumento, deleteInvTipoDocumento, getInvTipoDocUsuarios, syncInvTipoDocUsuarios } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numericId = Number(id)
    const { searchParams } = new URL(request.url)
    if (searchParams.get("section") === "users") {
      const data = await getInvTipoDocUsuarios(numericId)
      return NextResponse.json({ ok: true, data })
    }
    return NextResponse.json({ ok: false, message: "Seccion no encontrada." }, { status: 404 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error." }, { status: 400 })
  }
}

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numericId = Number(id)
    const body = await request.json()
    if (!body.description?.trim()) return NextResponse.json({ ok: false, message: "La descripcion es obligatoria." }, { status: 400 })
    const result = await saveInvTipoDocumento({ ...body, id: numericId }, auth.session)
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el tipo de documento." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    await deleteInvTipoDocumento(Number(id), auth.session)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el tipo de documento." }, { status: 400 })
  }
}

export async function PATCH(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numericId = Number(id)
    const body = await request.json()
    if (!Array.isArray(body.userIds)) return NextResponse.json({ ok: false, message: "userIds debe ser un array." }, { status: 400 })
    const data = await syncInvTipoDocUsuarios(numericId, body.userIds as number[], auth.session)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo sincronizar usuarios." }, { status: 400 })
  }
}
