import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCompanySettingsData, saveCompanySettings, type CompanySettingsData } from "@/lib/pos-data"

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const data = await getCompanySettingsData()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar la empresa." },
      { status: 400 },
    )
  }
}

export async function PUT(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = (await request.json()) as CompanySettingsData
    await saveCompanySettings(body)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo guardar la empresa." },
      { status: 400 },
    )
  }
}
