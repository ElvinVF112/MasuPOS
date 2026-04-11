import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import {
  assignProductWarehouse,
  getProductWarehouses,
  removeProductWarehouse,
  updateProductWarehouseStock,
} from "@/lib/pos-data"

export async function GET(request: Request, context: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const params = await context.params
  const productId = Number(params.id)
  if (!Number.isFinite(productId) || productId <= 0) {
    return NextResponse.json({ ok: false, message: "Id de producto invalido." }, { status: 400 })
  }

  try {
    const result = await getProductWarehouses(productId)
    return NextResponse.json({ ok: true, ...result })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo obtener los almacenes." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request, context: { params: Promise<{ id: string }> }) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const params = await context.params
  const productId = Number(params.id)
  if (!Number.isFinite(productId) || productId <= 0) {
    return NextResponse.json({ ok: false, message: "Id de producto invalido." }, { status: 400 })
  }

  try {
    const body = await request.json() as Record<string, unknown>
    const action = String(body.action ?? "")
    const warehouseId = Number(body.warehouseId ?? 0)

    if (!warehouseId) {
      return NextResponse.json({ ok: false, message: "Id de almacen invalido." }, { status: 400 })
    }

    if (action === "assign") {
      const result = await assignProductWarehouse(productId, warehouseId, auth.session.sessionId)
      return NextResponse.json({ ok: true, ...result })
    }

    if (action === "remove") {
      const result = await removeProductWarehouse(productId, warehouseId, auth.session.sessionId)
      return NextResponse.json({ ok: true, ...result })
    }

    if (action === "update-stock") {
      const quantity = Number(body.quantity ?? 0)
      await updateProductWarehouseStock(productId, warehouseId, quantity, auth.session.sessionId)
      const result = await getProductWarehouses(productId)
      return NextResponse.json({ ok: true, ...result })
    }

    return NextResponse.json({ ok: false, message: "Accion no reconocida." }, { status: 400 })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "Error al procesar la solicitud." },
      { status: 400 },
    )
  }
}
