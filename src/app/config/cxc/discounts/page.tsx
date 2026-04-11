import { AppShell } from "@/components/pos/app-shell"
import { CxCDiscountsScreen } from "@/components/pos/cxc-discounts-screen"
import { getDescuentos } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function DiscountsPage() {
  const data = await getDescuentos()
  return (
    <AppShell>
      <section className="content-page">
        <CxCDiscountsScreen initialData={data} />
      </section>
    </AppShell>
  )
}
