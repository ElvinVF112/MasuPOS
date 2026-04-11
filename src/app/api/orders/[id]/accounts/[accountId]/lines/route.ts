"use server"

import { NextRequest, NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { listOrdenCuentaDetalle, createOrdenCuentaDetalle, updateOrdenCuentaDetalle, deleteOrdenCuentaDetalle } from "@/lib/pos-data"

export async function GET(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    const detalle = await listOrdenCuentaDetalle(idOrdenCuenta)
    return NextResponse.json({ ok: true, data: detalle })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al listar detalle"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}

export async function POST(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  const idOrdenCuenta = Number(accountId)
  if (isNaN(idOrdenCuenta)) return NextResponse.json({ ok: false, message: "ID de cuenta inválido" }, { status: 400 })

  try {
    const body = (await request.json()) as {
      idOrdenDetalle: number
      cantidadAsignada: number
    }

    if (!body.idOrdenDetalle || !body.cantidadAsignada) {
      return NextResponse.json({ ok: false, message: "Parámetros requeridos: idOrdenDetalle, cantidadAsignada" }, { status: 400 })
    }

    const idOrdenCuentaDetalle = await createOrdenCuentaDetalle(
      idOrdenCuenta,
      body.idOrdenDetalle,
      body.cantidadAsignada,
      sessionResult.session!.userId,
    )
    return NextResponse.json({ ok: true, data: { idOrdenCuentaDetalle } }, { status: 201 })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al agregar línea"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}

export async function PUT(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  try {
    const body = (await request.json()) as {
      idOrdenCuentaDetalle: number
      cantidadAsignada: number
    }

    if (!body.idOrdenCuentaDetalle || !body.cantidadAsignada) {
      return NextResponse.json({ ok: false, message: "Parámetros requeridos: idOrdenCuentaDetalle, cantidadAsignada" }, { status: 400 })
    }

    await updateOrdenCuentaDetalle(
      body.idOrdenCuentaDetalle,
      body.cantidadAsignada,
      sessionResult.session!.userId,
    )
    return NextResponse.json({ ok: true })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al actualizar línea"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}

export async function DELETE(request: NextRequest, { params }: { params: Promise<{ id: string; accountId: string }> }) {
  const { accountId } = await params
  const sessionResult = await requireApiSession(request)
  if (!sessionResult.ok) return sessionResult.response

  try {
    const body = (await request.json()) as {
      idOrdenCuentaDetalle: number
    }

    if (!body.idOrdenCuentaDetalle) {
      return NextResponse.json({ ok: false, message: "idOrdenCuentaDetalle requerido" }, { status: 400 })
    }

    await deleteOrdenCuentaDetalle(
      body.idOrdenCuentaDetalle,
      sessionResult.session!.userId,
    )
    return NextResponse.json({ ok: true })
  } catch (err) {
    const message = err instanceof Error ? err.message : "Error al eliminar línea"
    return NextResponse.json({ ok: false, message }, { status: 500 })
  }
}
