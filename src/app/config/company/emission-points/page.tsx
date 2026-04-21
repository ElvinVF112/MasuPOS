import { OrgEmissionPointsScreen } from "@/components/pos/org-emission-points-screen"
import { getBranches, getCustomers, getEmissionPoints, getFacTiposDocumento, getPriceLists } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function EmissionPointsPage() {
  const [emissionPoints, branches, priceLists, customers, documentTypes] = await Promise.all([
    getEmissionPoints(),
    getBranches(),
    getPriceLists(),
    getCustomers(),
    getFacTiposDocumento("F"),
  ])

  return (
    <section className="content-page">
        <OrgEmissionPointsScreen
          initialData={emissionPoints}
          branches={branches}
          priceLists={priceLists}
          customers={customers}
          documentTypes={documentTypes}
        />
      </section>
  )
}
