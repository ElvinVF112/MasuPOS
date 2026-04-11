import { AppShell } from "@/components/pos/app-shell"
import { OrdersDashboard } from "@/components/pos/orders-dashboard"
import { getOrdersTrayData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function OrdersPage() {
  const data = await getOrdersTrayData()

  return (
    <AppShell>
      <OrdersDashboard data={data} />
    </AppShell>
  )
}
