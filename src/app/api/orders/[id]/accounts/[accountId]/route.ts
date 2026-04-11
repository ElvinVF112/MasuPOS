"use server"

import { NextRequest, NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getOrdenCuenta, updateOrdenCuenta, deleteOrdenCuenta } from "@/lib/pos-data"

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    const cuenta = await getOrdenCuenta(idOrdenCuenta)
    if (!cuenta) return NextResponse.json({ ok: false, message: "Cuenta no encontrada" }, { status: 404 })
    return NextResponse.json({ ok: true, data: cuenta })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al obtener cuenta"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}

export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    const body = (await request.json()) as {
      nombre?: string | null
      idEstadoCuenta?: number
    }

    await updateOrdenCuenta(idOrdenCuenta, body, sessionResult.session!.userId, sessionResult.session!)
    return NextResponse.json({ ok: true })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al actualizar cuenta"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    // Anular cuenta (acción 'X' del SP)
    await deleteOrdenCuenta(idOrdenCuenta, sessionResult.session!.userId, sessionResult.session!)
    return NextResponse.json({ ok: true })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al anular cuenta"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
