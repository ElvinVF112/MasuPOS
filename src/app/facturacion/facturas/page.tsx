import { FacDocumentosScreen } from "@/components/pos/fac-documentos-screen"
import { getCatalogoNCF, getCustomers, getEmissionPoints, getFacTiposDocumento } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function FacDocumentosPage() {
  const [tiposDocumento, customers, tiposNCF, emissionPoints] = await Promise.all([
    getFacTiposDocumento("F").catch(() => []),
    getCustomers().catch(() => []),
    getCatalogoNCF().catch(() => []),
    getEmissionPoints().catch(() => []),
  ])

  return (
    <FacDocumentosScreen
        tiposDocumento={tiposDocumento}
        customers={customers}
        tiposNCF={tiposNCF}
        emissionPoints={emissionPoints}
      />
  )
}
