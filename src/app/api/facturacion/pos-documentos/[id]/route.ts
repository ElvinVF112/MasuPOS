import { requireApiSession } from "@/lib/api-auth"
import {
  anularFacDocumentoPOS,
  getFacDocumentoPOS,
  saveFacDocumentoPOS,
} from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

// GET /api/facturacion/pos-documentos/[id]  → obtener con lineas
export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const { id } = await params
  const numId = Number(id)
  if (!numId) return NextResponse.json({ ok: false, message: "ID inválido" }, { status: 400 })
  try {
    const doc = await getFacDocumentoPOS(numId)
    if (!doc) return NextResponse.json({ ok: false, message: "No encontrado" }, { status: 404 })
    return NextResponse.json({ ok: true, data: doc })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}

// PUT /api/facturacion/pos-documentos/[id]
// body: { accion: "guardar" | "anular", ...campos opcionales }
export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const { id } = await params
  const numId = Number(id)
  if (!numId) return NextResponse.json({ ok: false, message: "ID inválido" }, { status: 400 })
  try {
    const body = await request.json()
    const accion: string = body.accion

    if (accion === "guardar") {
      if (!Array.isArray(body.lineas) || body.lineas.length === 0)
        return NextResponse.json({ ok: false, message: "El documento no tiene líneas." }, { status: 400 })
      await saveFacDocumentoPOS({ ...body, id: numId, idUsuario: auth.session.userId }, "U")
      return NextResponse.json({ ok: true })
    }

    if (accion === "anular") {
      await anularFacDocumentoPOS(numId, auth.session.userId)
      return NextResponse.json({ ok: true })
    }

    return NextResponse.json({ ok: false, message: "Acción no reconocida" }, { status: 400 })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}
