import { CatalogSupplierCategoriesScreen } from "@/components/pos/catalog-supplier-categories-screen"
import { getCategoriasProveedor } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function SupplierCategoriesPage() {
  const data = await getCategoriasProveedor()
  return (
    <section className="content-page">
        <CatalogSupplierCategoriesScreen initialData={data} />
      </section>
  )
}
