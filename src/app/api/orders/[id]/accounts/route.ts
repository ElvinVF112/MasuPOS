"use server"

import { NextRequest, NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { listOrdenCuentas, createOrdenCuenta } from "@/lib/pos-data"

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrden = Number(id)
  if (isNaN(idOrden)) return NextResponse.json({ ok: false, message: "ID de orden inválido" }, { status: 400 })

  try {
    const cuentas = await listOrdenCuentas(idOrden)
    return NextResponse.json({ ok: true, data: cuentas })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al listar cuentas"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrden = Number(id)
  if (isNaN(idOrden)) return NextResponse.json({ ok: false, message: "ID de orden inválido" }, { status: 400 })

  try {
    const body = (await request.json()) as {
      numeroCuenta?: number
      nombre?: string | null
    }

    if (body.numeroCuenta === undefined) {
      return NextResponse.json({ ok: false, message: "numeroCuenta requerido" }, { status: 400 })
    }

    const idOrdenCuenta = await createOrdenCuenta(idOrden, body.numeroCuenta, body.nombre || null, sessionResult.session!.userId, sessionResult.session!)
    return NextResponse.json({ ok: true, data: { idOrdenCuenta } }, { status: 201 })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al crear cuenta"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
