import { CatalogProductTypesScreen } from "@/components/pos/catalog-product-types-screen"
import { getProductTypes } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CatalogProductTypesPage() {
  const initialData = await getProductTypes()

  return (
    <section className="content-page">
        <CatalogProductTypesScreen initialData={initialData} />
      </section>
  )
}