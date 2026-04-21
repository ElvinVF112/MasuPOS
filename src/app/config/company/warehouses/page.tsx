import { OrgWarehousesScreen } from "@/components/pos/org-warehouses-screen"
import { getWarehouses } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function WarehousesPage() {
  const warehouses = await getWarehouses()
  return (
    <section className="content-page">
        <OrgWarehousesScreen initialData={warehouses} />
      </section>
  )
}
