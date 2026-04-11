import { NextResponse } from "next/server"
import { getCompanyLogoBinary } from "@/lib/pos-data"

export async function GET() {
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
