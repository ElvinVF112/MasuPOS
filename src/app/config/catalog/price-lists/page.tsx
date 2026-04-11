import { AppShell } from "@/components/pos/app-shell"
import { PriceListsScreen } from "@/components/pos/price-lists-screen"

export const dynamic = "force-dynamic"

export default async function PriceListsPage() {
  return (
    <AppShell>
      <section className="content-page">
        <PriceListsScreen />
      </section>
    </AppShell>
  )
}
