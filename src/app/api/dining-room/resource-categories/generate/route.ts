import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { generateResourcesFromCategory } from "@/lib/pos-data"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  try {
    const body = await request.json()
    await generateResourcesFromCategory(
      {
        categoryId: Number(body.categoryId),
        prefix: String(body.prefix ?? ""),
        quantity: Number(body.quantity ?? 1),
        startAt: Number(body.startAt ?? 1),
        seats: Number(body.seats ?? 4),
        state: String(body.state ?? "Libre"),
      },
      {
        sessionId: auth.session.sessionId,
        token: auth.session.token,
        userType: auth.session.userType,
      },
    )

    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        message: error instanceof Error ? error.message : "No se pudieron generar los recursos.",
      },
      { status: 400 },
    )
  }
}
