import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPriceListUsers, assignPriceListUser, removePriceListUser, assignAllPriceListUsers, removeAllPriceListUsers } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const data = await getPriceListUsers(Number(id))
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar usuarios." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const priceListId = Number(id)
    const body = (await request.json()) as { action: "assign" | "remove" | "assign_all" | "remove_all"; userId?: number }

    if (!Number.isFinite(priceListId) || priceListId <= 0) {
      return NextResponse.json({ ok: false, message: "Id invalido." }, { status: 400 })
    }

    let data
    if (body.action === "assign_all") {
      data = await assignAllPriceListUsers(priceListId)
    } else if (body.action === "remove_all") {
      data = await removeAllPriceListUsers(priceListId)
    } else {
      const userId = Number(body.userId)
      if (!Number.isFinite(userId) || userId <= 0) {
        return NextResponse.json({ ok: false, message: "userId invalido." }, { status: 400 })
      }
      if (body.action === "assign") {
        data = await assignPriceListUser(priceListId, userId)
      } else if (body.action === "remove") {
        data = await removePriceListUser(priceListId, userId)
      } else {
        return NextResponse.json({ ok: false, message: "Accion no valida. Use assign, remove, assign_all o remove_all." }, { status: 400 })
      }
    }

    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar usuarios." },
      { status: 400 },
    )
  }
}
