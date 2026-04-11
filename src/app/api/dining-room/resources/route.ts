import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { createResource, deleteResource, updateResource } from "@/lib/pos-data"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    await createResource(body, { sessionId: auth.session.sessionId, token: auth.session.token })
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el recurso." }, { status: 400 })
  }
}

export async function PUT(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    await updateResource(Number(body.id), body, { sessionId: auth.session.sessionId, token: auth.session.token })
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el recurso." }, { status: 400 })
  }
}

export async function DELETE(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    await deleteResource(Number(body.id), { sessionId: auth.session.sessionId, token: auth.session.token })
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el recurso." }, { status: 400 })
  }
}
