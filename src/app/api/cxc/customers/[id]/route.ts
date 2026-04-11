import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCustomerById, saveCustomer, deleteCustomer } from "@/lib/pos-data"

export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    const data = await getCustomerById(numId)
    if (!data) return NextResponse.json({ ok: false, message: "Cliente no encontrado." }, { status: 404 })
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error al cargar el cliente." }, { status: 400 })
  }
}

export async function PUT(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    const body = await request.json()
    if (!body.code?.trim()) return NextResponse.json({ ok: false, message: "El codigo es obligatorio." }, { status: 400 })
    if (!body.name?.trim()) return NextResponse.json({ ok: false, message: "El nombre es obligatorio." }, { status: 400 })
    const result = await saveCustomer({ ...body, id: numId, esCliente: true })
    return NextResponse.json({ ok: true, data: result })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el cliente." }, { status: 400 })
  }
}

export async function DELETE(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  try {
    const { id } = await params
    const numId = Number(id)
    if (isNaN(numId) || numId <= 0) return NextResponse.json({ ok: false, message: "ID invalido." }, { status: 400 })
    await deleteCustomer(numId)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el cliente." }, { status: 400 })
  }
}
