import { OrdersDashboard } from "@/components/pos/orders-dashboard"
import { getOrdersTrayData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function OrdersPage() {
  const data = await getOrdersTrayData()

  return (
    <OrdersDashboard data={data} />
  )
}
