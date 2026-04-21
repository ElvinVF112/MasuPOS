import { CatalogCustomerTypesScreen } from "@/components/pos/catalog-customer-types-screen"
import { getTiposCliente } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CustomerTypesPage() {
  const data = await getTiposCliente()
  return (
    <section className="content-page">
        <CatalogCustomerTypesScreen initialData={data} />
      </section>
  )
}
