"use server"

import { NextRequest, NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { updateOrdenCuenta, getEstadoCuentaId } from "@/lib/pos-data"

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    // Obtener IdEstadoCuenta de "EnCaja" y actualizar
    const idEstadoEnCaja = await getEstadoCuentaId("EnCaja")
    await updateOrdenCuenta(idOrdenCuenta, { idEstadoCuenta: idEstadoEnCaja }, sessionResult.session!.userId, sessionResult.session!)
    return NextResponse.json({ ok: true })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al enviar a caja"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
