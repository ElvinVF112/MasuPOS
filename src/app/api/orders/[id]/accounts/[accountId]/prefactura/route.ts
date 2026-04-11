"use server"

import { NextRequest, NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getOrdenCuentaPrefactura } from "@/lib/pos-data"

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    const prefactura = await getOrdenCuentaPrefactura(idOrdenCuenta)
    if (!prefactura) return NextResponse.json({ ok: false, message: "Pre-factura no encontrada" }, { status: 404 })
    return NextResponse.json({ ok: true, data: prefactura })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al obtener pre-factura"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
