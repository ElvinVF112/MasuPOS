import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { heartbeatSession } from "@/lib/auth-session"

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  await heartbeatSession({
    sessionId: auth.session.sessionId,
    token: auth.session.token,
  })

  return NextResponse.json({ ok: true })
}
