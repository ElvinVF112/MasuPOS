import { AppShell } from "@/components/pos/app-shell"
import { CatalogCustomerCategoriesScreen } from "@/components/pos/catalog-customer-categories-screen"
import { getCategoriasCliente } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CustomerCategoriesPage() {
  const data = await getCategoriasCliente()
  return (
    <AppShell>
      <section className="content-page">
        <CatalogCustomerCategoriesScreen initialData={data} />
      </section>
    </AppShell>
  )
}
