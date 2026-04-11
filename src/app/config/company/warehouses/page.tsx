import { AppShell } from "@/components/pos/app-shell"
import { OrgWarehousesScreen } from "@/components/pos/org-warehouses-screen"
import { getWarehouses } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function WarehousesPage() {
  const warehouses = await getWarehouses()
  return (
    <AppShell>
      <section className="content-page">
        <OrgWarehousesScreen initialData={warehouses} />
      </section>
    </AppShell>
  )
}
