import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getDiscountUsers, assignDiscountUser, removeDiscountUser, assignAllDiscountUsers, removeAllDiscountUsers, updateDiscountUserLimit } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { id } = await params
    const data = await getDiscountUsers(Number(id))
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
    const discountId = Number(id)
    const body = (await request.json()) as { action: "assign" | "remove" | "assign_all" | "remove_all" | "update_limit"; userId?: number; limite?: number | null }

    if (!Number.isFinite(discountId) || discountId <= 0) {
      return NextResponse.json({ ok: false, message: "Id invalido." }, { status: 400 })
    }

    let data
    if (body.action === "assign_all") {
      data = await assignAllDiscountUsers(discountId)
    } else if (body.action === "remove_all") {
      data = await removeAllDiscountUsers(discountId)
    } else {
      const userId = Number(body.userId)
      if (!Number.isFinite(userId) || userId <= 0) {
        return NextResponse.json({ ok: false, message: "userId invalido." }, { status: 400 })
      }
      if (body.action === "assign") {
        data = await assignDiscountUser(discountId, userId)
      } else if (body.action === "remove") {
        data = await removeDiscountUser(discountId, userId)
      } else if (body.action === "update_limit") {
        const limite = body.limite != null ? Number(body.limite) : null
        data = await updateDiscountUserLimit(discountId, userId, limite)
      } else {
        return NextResponse.json({ ok: false, message: "Accion no valida." }, { status: 400 })
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
