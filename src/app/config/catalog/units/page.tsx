import { AppShell } from "@/components/pos/app-shell"
import { CatalogUnitsScreen } from "@/components/pos/catalog-units-screen"
import { getUnits } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CatalogUnitsPage() {
  const units = await getUnits()

  return (
    <AppShell>
      <section className="content-page">
        <CatalogUnitsScreen initialData={units} />
      </section>
    </AppShell>
  )
}
