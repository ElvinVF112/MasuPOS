import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { getCompanyLogoBinary, getCompanySettingsData, removeCompanyLogoBinary, saveCompanyLogoBinary } from "@/lib/pos-data"

const MAX_LOGO_BYTES = 2 * 1024 * 1024
const ALLOWED_MIME = new Set(["image/png", "image/jpeg", "image/jpg", "image/webp"])

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  const logo = await getCompanyLogoBinary()
  if (!logo) {
    return new NextResponse(null, { status: 404 })
  }

  return new NextResponse(new Uint8Array(logo.data), {
    status: 200,
    headers: {
      "Content-Type": logo.mimeType,
      "Cache-Control": "no-store",
    },
  })
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const form = await request.formData()
    const file = form.get("logo")

    if (!(file instanceof File)) {
      return NextResponse.json({ ok: false, message: "Debes enviar el archivo logo." }, { status: 400 })
    }

    if (!ALLOWED_MIME.has(file.type.toLowerCase())) {
      return NextResponse.json({ ok: false, message: "Formato no permitido. Usa PNG, JPG o WEBP." }, { status: 400 })
    }

    if (file.size <= 0 || file.size > MAX_LOGO_BYTES) {
      return NextResponse.json({ ok: false, message: "El logo debe ser mayor a 0 y maximo 2MB." }, { status: 400 })
    }

    const company = await getCompanySettingsData()
    if (!company.id) {
      return NextResponse.json({ ok: false, message: "No se encontro empresa para guardar el logo." }, { status: 400 })
    }

    const bytes = await file.arrayBuffer()
    await saveCompanyLogoBinary({
      companyId: company.id,
      fileName: file.name || "logo",
      mimeType: file.type,
      fileData: Buffer.from(bytes),
    })

    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo guardar el logo." },
      { status: 400 },
    )
  }
}

export async function DELETE(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const company = await getCompanySettingsData()
    if (!company.id) {
      return NextResponse.json({ ok: false, message: "No se encontro empresa." }, { status: 400 })
    }

    await removeCompanyLogoBinary(company.id)
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json(
      { ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el logo." },
      { status: 400 },
    )
  }
}
