import { AppShell } from "@/components/pos/app-shell"
import { CatalogCustomerTypesScreen } from "@/components/pos/catalog-customer-types-screen"
import { getTiposCliente } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CustomerTypesPage() {
  const data = await getTiposCliente()
  return (
    <AppShell>
      <section className="content-page">
        <CatalogCustomerTypesScreen initialData={data} />
      </section>
    </AppShell>
  )
}
