import { AppShell } from "@/components/pos/app-shell"
import { InvDocumentScreen } from "@/components/pos/inv-document-screen"
import { getInvTiposDocumento, getWarehouses, listInvDocumentos, listInvSuppliers } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

function formatDateLocal(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, "0")
  const day = String(date.getDate()).padStart(2, "0")
  return `${year}-${month}-${day}`
}

export default async function PurchasesPage() {
  const today = new Date()
  const firstDay = new Date(today.getFullYear(), today.getMonth(), 1)
  const fechaDesde = formatDateLocal(firstDay)
  const fechaHasta = formatDateLocal(today)

  const [docTypes, warehouses, documents, suppliers] = await Promise.all([
    getInvTiposDocumento("C"),
    getWarehouses(),
    listInvDocumentos({ tipoOperacion: "C", page: 1, pageSize: 20, fechaDesde, fechaHasta }),
    listInvSuppliers(),
  ])

  return (
    <AppShell>
      <section className="content-page">
        <InvDocumentScreen
          tipoOperacion="C"
          title="Entradas por Compras"
          docTypes={docTypes}
          warehouses={warehouses}
          suppliers={suppliers}
          initialList={documents}
          initialFechaDesde={fechaDesde}
          initialFechaHasta={fechaHasta}
        />
      </section>
    </AppShell>
  )
}
