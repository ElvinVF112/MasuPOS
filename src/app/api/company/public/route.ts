import { NextResponse } from "next/server"
import { getCompanyBrandingData } from "@/lib/pos-data"

export async function GET() {
  try {
    const data = await getCompanyBrandingData()
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar empresa." },
      { status: 400 },
    )
  }
}
