import { requireApiSession } from "@/lib/api-auth"
import { getPricesByList } from "@/lib/pos-data"
import { NextRequest, NextResponse } from "next/server"

export const dynamic = "force-dynamic"

export async function GET(request: NextRequest) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response
  const { searchParams } = new URL(request.url)
  const listId = Number(searchParams.get("listId"))
  if (!listId || isNaN(listId)) return NextResponse.json({ ok: false, message: "listId requerido" }, { status: 400 })
  try {
    const prices = await getPricesByList(listId)
    return NextResponse.json({ ok: true, data: prices })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "Error" }, { status: 500 })
  }
}
