import { CatalogDocTypesScreen } from "@/components/pos/catalog-doc-types-screen"
import { getDocIdentOptions } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function DocTypesPage() {
  const data = await getDocIdentOptions()
  return (
    <section className="content-page">
        <CatalogDocTypesScreen initialData={data} />
      </section>
  )
}
