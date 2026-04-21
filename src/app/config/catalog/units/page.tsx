import { CatalogUnitsScreen } from "@/components/pos/catalog-units-screen"
import { getUnits } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CatalogUnitsPage() {
  const units = await getUnits()

  return (
    <section className="content-page">
        <CatalogUnitsScreen initialData={units} />
      </section>
  )
}
