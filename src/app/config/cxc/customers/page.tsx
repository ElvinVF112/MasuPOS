import { CxCCustomersScreen } from "@/components/pos/cxc-customers-screen"
import { getCxCMaestrosData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CxCCustomersPage() {
  const data = await getCxCMaestrosData()
  return (
    <section className="content-page">
        <CxCCustomersScreen data={data} />
      </section>
  )
}
