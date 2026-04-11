import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { addOrderLine, getProductsForOrderCapture, removeOrderLine, updateOrderLine } from "@/lib/pos-data"
import { requireOrderPermission } from "@/lib/orders-api-auth"

type Context = {
  params: Promise<{ id: string }>
}

export async function POST(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.edit")
  if (denied) return denied

  const { id } = await context.params

  try {
    const orderId = Number(id)
    if (!Number.isInteger(orderId) || orderId <= 0) {
      throw new Error("Orden invalida.")
    }

    const body = await request.json()
    const productId = Number(body?.productId)
    const quantity = Number(body?.quantity)
    const personNumber = Number(body?.personNumber ?? 1)
    const note = typeof body?.note === "string" ? body.note : ""

    if (!Number.isInteger(productId) || productId <= 0) {
      throw new Error("Selecciona un producto valido.")
    }

    if (!Number.isFinite(quantity) || quantity <= 0) {
      throw new Error("La cantidad debe ser mayor que cero.")
    }

    if (!Number.isFinite(personNumber) || personNumber <= 0) {
      throw new Error("Selecciona una persona válida.")
    }

    const products = await getProductsForOrderCapture()
    const product = products.find((item: { id: number }) => item.id === productId)
    if (!product) {
      throw new Error("Producto no disponible para la orden.")
    }

    const line = await addOrderLine(
      orderId,
      {
        productId,
        unitId: product.unitId,
        quantity,
        personNumber,
        units: 1,
        price: product.price,
        taxPercent: product.applyTax ? product.taxRate : 0,
        note,
      },
      auth.session.userId,
      {
        sessionId: auth.session.sessionId,
        token: auth.session.token,
        userType: auth.session.userType,
      },
    )

    return NextResponse.json({ ok: true, line })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo agregar el producto." },
      { status: 400 },
    )
  }
}

export async function DELETE(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.delete")
  if (denied) return denied

  const { id } = await context.params

  try {
    const orderId = Number(id)
    if (!Number.isInteger(orderId) || orderId <= 0) {
      throw new Error("Orden invalida.")
    }

    const body = await request.json()
    const orderLineId = Number(body?.orderLineId)
    if (!Number.isInteger(orderLineId) || orderLineId <= 0) {
      throw new Error("Linea invalida.")
    }

    await removeOrderLine(orderLineId, auth.session.userId, {
      sessionId: auth.session.sessionId,
      token: auth.session.token,
      userType: auth.session.userType,
    })

    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar la linea." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request, context: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const denied = await requireOrderPermission(auth.session, "orders.edit")
  if (denied) return denied

  try {
    const body = await request.json()
    const orderLineId = Number(body?.orderLineId)
    const personNumber = Number(body?.personNumber)

    if (!Number.isInteger(orderLineId) || orderLineId <= 0) {
      throw new Error("Linea invalida.")
    }

    if (!Number.isFinite(personNumber) || personNumber <= 0) {
      throw new Error("Selecciona una persona valida.")
    }

    const line = await updateOrderLine(
      orderLineId,
      { personNumber },
      auth.session.userId,
      {
        sessionId: auth.session.sessionId,
        token: auth.session.token,
        userType: auth.session.userType,
      },
    )

    return NextResponse.json({ ok: true, line })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar la linea." },
      { status: 400 },
    )
  }
}
