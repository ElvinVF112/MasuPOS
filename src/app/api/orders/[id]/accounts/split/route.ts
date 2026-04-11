"use server"

import { NextRequest, NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { splitOrdenCuentas } from "@/lib/pos-data"

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrden = Number(id)
  if (isNaN(idOrden)) return NextResponse.json({ ok: false, message: "ID de orden inválido" }, { status: 400 })

  try {
    const body = (await request.json()) as {
      modo: "PERSONA" | "EQUITATIVA" | "ITEM" | "UNIFICAR"
      cantidad?: number
      payload?: string
      observacion?: string
    }

    if (!body.modo) return NextResponse.json({ ok: false, message: "modo requerido" }, { status: 400 })

    await splitOrdenCuentas(
      idOrden,
      body.modo,
      body.cantidad,
      body.payload,
      body.observacion,
      sessionResult.session!.userId,
      sessionResult.session!,
    )

    return NextResponse.json({ ok: true }, { status: 201 })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al dividir cuentas"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
