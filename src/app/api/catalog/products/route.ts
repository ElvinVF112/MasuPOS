import { NextResponse } from "next/server"
import { requireApiSession } from "@/lib/api-auth"
import { createProduct, deleteProduct, searchProducts, updateProduct } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

function normalizeProductPayload(body: Record<string, unknown>) {
  const prices = Array.isArray(body.prices) ? body.prices : []
  const costs = typeof body.costs === "object" && body.costs !== null ? body.costs as Record<string, unknown> : {}
  const offer = typeof body.offer === "object" && body.offer !== null ? body.offer as Record<string, unknown> : {}

  return {
    id: Number(body.id ?? 0),
    code: String(body.code ?? ""),
    categoryId: Number(body.categoryId ?? 0),
    typeId: Number(body.typeId ?? 0),
    unitBaseId: Number(body.unitBaseId ?? 0),
    unitSaleId: Number(body.unitSaleId ?? body.unitBaseId ?? 0),
    unitPurchaseId: Number(body.unitPurchaseId ?? body.unitBaseId ?? 0),
    unitAlt1Id: body.unitAlt1Id != null ? Number(body.unitAlt1Id) : undefined,
    unitAlt2Id: body.unitAlt2Id != null ? Number(body.unitAlt2Id) : undefined,
    unitAlt3Id: body.unitAlt3Id != null ? Number(body.unitAlt3Id) : undefined,
    name: String(body.description ?? body.name ?? ""),
    description: String(body.reference ?? body.description ?? ""),
    comment: String(body.comment ?? ""),
    imagen: String(body.imagen ?? "") || null,
    price: Number(body.price ?? 0),
    applyTax: Boolean(body.applyTax ?? false),
    taxRateId: body.taxRateId != null ? Number(body.taxRateId) : null,
    stockUnitBase: "measure",
    canSellInBilling: Boolean(body.canSellInBilling ?? true),
    allowDiscount: Boolean(body.allowDiscount ?? true),
    allowPriceChange: Boolean(body.allowPriceChange ?? true),
    allowManualPrice: Boolean(body.allowManualPrice ?? true),
    requestUnit: Boolean(body.requestUnit ?? false),
    requestUnitInventory: Boolean(body.requestUnitInventory ?? false),
    allowDecimals: Boolean(body.allowDecimals ?? false),
    sellWithoutStock: Boolean(body.sellWithoutStock ?? true),
    applyTip: Boolean(body.applyTip ?? false),
    managesStock: Boolean(body.managesStock ?? true),
    prices: prices.map((row) => {
      const item = typeof row === "object" && row !== null ? row as Record<string, unknown> : {}
      return {
        priceListId: Number(item.priceListId ?? 0),
        profitPercent: Number(item.profitPercent ?? 0),
        price: Number(item.price ?? 0),
        tax: Number(item.tax ?? 0),
        priceWithTax: Number(item.priceWithTax ?? 0),
      }
    }),
    costs: {
      currencyId: costs.currencyId != null ? Number(costs.currencyId) : null,
      providerDiscount: Number(costs.providerDiscount ?? 0),
      providerCost: Number(costs.providerCost ?? 0),
      providerCostWithTax: Number(costs.providerCostWithTax ?? 0),
      averageCost: Number(costs.averageCost ?? 0),
      allowManualAvgCost: Boolean(costs.allowManualAvgCost ?? false),
    },
    offer: {
      active: Boolean(offer.active ?? false),
      price: Number(offer.price ?? 0),
      startDate: String(offer.startDate ?? ""),
      endDate: String(offer.endDate ?? ""),
    },
    active: Boolean(body.active ?? true),
  }
}

export async function GET(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const query = searchParams.get("q") ?? ""
    const limit = Number(searchParams.get("limit") ?? "60")
    const items = await searchProducts({ query, limit: Number.isFinite(limit) ? limit : 60 })
    return NextResponse.json({ ok: true, items })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo listar productos." }, { status: 400 })
  }
}

export async function POST(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json() as Record<string, unknown>
    const product = await createProduct(normalizeProductPayload(body))
    return NextResponse.json({ ok: true, product })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo crear el producto." }, { status: 400 })
  }
}

export async function PUT(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json() as Record<string, unknown>
    const payload = normalizeProductPayload(body)
    const product = await updateProduct(Number(body.id), payload)
    return NextResponse.json({ ok: true, product })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo actualizar el producto." }, { status: 400 })
  }
}

export async function DELETE(request: Request) {
  const auth = await requireApiSession(request)
  if (!auth.ok) return auth.response

  try {
    const body = await request.json()
    await deleteProduct(Number(body.id))
    return NextResponse.json({ ok: true })
  } catch (error) {
    return NextResponse.json({ ok: false, message: error instanceof Error ? error.message : "No se pudo eliminar el producto." }, { status: 400 })
  }
}
