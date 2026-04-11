import { AppShell } from "@/components/pos/app-shell"
import { CatalogSupplierTypesScreen } from "@/components/pos/catalog-supplier-types-screen"
import { getTiposProveedor } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function SupplierTypesPage() {
  const data = await getTiposProveedor()
  return (
    <AppShell>
      <section className="content-page">
        <CatalogSupplierTypesScreen initialData={data} />
      </section>
    </AppShell>
  )
}
