import { NextRequest, NextResponse } from "next/server";
import { requireApiSession } from "@/lib/api-auth";
import { assignProductToCategory, getCategoryProducts, removeProductFromCategory } from "@/lib/pos-data";

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const auth = await requireApiSession(request);
  if (!auth.ok) return auth.response;

  const { session } = auth;
  const { id: categoryId } = await params;
  const idCat = parseInt(categoryId, 10);

  if (isNaN(idCat)) {
    return NextResponse.json({ error: "ID de categoría inválido" }, { status: 400 });
  }

  try {
    const { assigned, available } = await getCategoryProducts(idCat, session);

    return NextResponse.json({
      ok: true,
      assigned,
      available,
    });
  } catch (error) {
    console.error("Error fetching category products:", error);
    return NextResponse.json({ error: "Error al obtener productos" }, { status: 500 });
  }
}

export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const auth = await requireApiSession(request);
  if (!auth.ok) return auth.response;

  const { session } = auth;
  const { id: categoryId } = await params;
  const idCat = parseInt(categoryId, 10);

  if (isNaN(idCat)) {
    return NextResponse.json({ error: "ID de categoría inválido" }, { status: 400 });
  }

  try {
    const body = await request.json();
    const { action, productId } = body;

    if (!action || !productId) {
      return NextResponse.json({ error: "Faltan parámetros" }, { status: 400 });
    }

    if (action === "assign") {
      await assignProductToCategory(idCat, Number(productId), session);
    } else {
      await removeProductFromCategory(idCat, Number(productId), session);
    }

    return NextResponse.json({ ok: true });
  } catch (error) {
    console.error("Error updating category product:", error);
    return NextResponse.json({ error: "Error al actualizar producto" }, { status: 500 });
  }
}
