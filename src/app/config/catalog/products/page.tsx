import { AppShell } from "@/components/pos/app-shell"
import { CatalogProductsScreen } from "@/components/pos/catalog-products-screen"
import { getCatalogManagerData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CatalogProductsPage() {
  const data = await getCatalogManagerData()

  return (
    <AppShell>
      <section className="content-page">
        <CatalogProductsScreen data={data} />
      </section>
    </AppShell>
  )
}
