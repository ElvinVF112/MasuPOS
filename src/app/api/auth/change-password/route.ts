import { createHash } from "node:crypto"
import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getPool } from "@/lib/db"

function toSha256Base64(value: string) {
  return createHash("sha256").update(value).digest("base64")
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) {
    return auth.response
  }

  try {
    const body = (await request.json()) as { newPassword?: string }
    const newPassword = body.newPassword?.trim() ?? ""

    if (newPassword.length < 6) {
      return NextResponse.json({ ok: false, message: "La contraseña debe tener al menos 6 caracteres." }, { status: 400 })
    }

    const pool = await getPool()
    await pool
      .request()
      .input("IdUsuario", auth.session.userId)
      .input("ClaveHash", toSha256Base64(newPassword))
      .query(`
        UPDATE dbo.Usuarios
        SET
          ClaveHash = @ClaveHash,
          RequiereCambioClave = 0,
          FechaModificacion = GETDATE(),
          UsuarioModificacion = @IdUsuario
        WHERE IdUsuario = @IdUsuario
          AND RowStatus = 1;
      `)

    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo cambiar la contraseña." },
      { status: 400 },
    )
  }
}
