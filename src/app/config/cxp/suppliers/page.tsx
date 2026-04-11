import { AppShell } from "@/components/pos/app-shell"
import { CxPSuppliersScreen } from "@/components/pos/cxp-suppliers-screen"
import { getCxPMaestrosData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CxPSuppliersPage() {
  const data = await getCxPMaestrosData()
  return (
    <AppShell>
      <section className="content-page">
        <CxPSuppliersScreen data={data} />
      </section>
    </AppShell>
  )
}
