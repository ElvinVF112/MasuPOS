import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  return NextResponse.json({
    ok: true,
    user: auth.session,
    sessionIdleMinutes: auth.session.sessionIdleMinutes,
  })
}
