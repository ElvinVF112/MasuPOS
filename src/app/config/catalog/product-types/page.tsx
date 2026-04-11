import { AppShell } from "@/components/pos/app-shell"
import { CatalogProductTypesScreen } from "@/components/pos/catalog-product-types-screen"
import { getProductTypes } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CatalogProductTypesPage() {
  const initialData = await getProductTypes()

  return (
    <AppShell>
      <section className="content-page">
        <CatalogProductTypesScreen initialData={initialData} />
      </section>
    </AppShell>
  )
}