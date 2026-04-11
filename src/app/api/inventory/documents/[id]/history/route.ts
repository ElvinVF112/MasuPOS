import { NextResponse } from "next/server"
import { getPermissionKeysByRole } from "@/lib/auth-session"
import { requireApiSession } from "@/lib/api-auth"
import { getInvDocumentoDetalleHistory } from "@/lib/pos-data"

type Context = { params: Promise<{ id: string }> }

function isSuperAdmin(roleId: number, roleName: string) {
  const normalized = roleName.trim().toLowerCase()
  return roleId === 1 || normalized === "administrador" || normalized === "administrador general"
}

export async function GET(request: Request, { params }: Context) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const permissionKeys = await getPermissionKeysByRole(auth.session.roleId)
    const canViewHistory = permissionKeys.includes("inventory.documents.history.view")

    if (!isSuperAdmin(auth.session.roleId, auth.session.role) && !canViewHistory) {
      return NextResponse.json({ ok: false, message: "No autorizado." }, { status: 403 })
    }

    const { id } = await params
    const documentId = Number(id)
    if (!Number.isFinite(documentId) || documentId <= 0) {
      return NextResponse.json({ ok: false, message: "Id de documento invalido." }, { status: 400 })
    }

    const data = await getInvDocumentoDetalleHistory(documentId)
    return NextResponse.json({ ok: true, data })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cargar el historico." },
      { status: 400 },
    )
  }
}
