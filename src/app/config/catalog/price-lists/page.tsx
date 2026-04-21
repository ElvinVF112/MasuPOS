import { PriceListsScreen } from "@/components/pos/price-lists-screen"

export const dynamic = "force-dynamic"

export default async function PriceListsPage() {
  return (
    <section className="content-page">
        <PriceListsScreen />
      </section>
  )
}
