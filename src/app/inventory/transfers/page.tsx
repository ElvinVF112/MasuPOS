import { InvTransferScreen } from "@/components/pos/inv-transfer-screen"
import { getInvTiposDocumento, getWarehouses, listInvTransferencias } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

function formatDateLocal(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, "0")
  const day = String(date.getDate()).padStart(2, "0")
  return `${year}-${month}-${day}`
}

export default async function TransfersPage() {
  const today = new Date()
  const firstDay = new Date(today.getFullYear(), today.getMonth(), 1)
  const fechaDesde = formatDateLocal(firstDay)
  const fechaHasta = formatDateLocal(today)

  const [docTypes, warehouses, documents] = await Promise.all([
    getInvTiposDocumento("T"),
    getWarehouses(),
    listInvTransferencias({ page: 1, pageSize: 20, fechaDesde, fechaHasta }),
  ])

  return (
    <section className="content-page">
        <InvTransferScreen
          title="Transferencias de Inventario"
          docTypes={docTypes}
          warehouses={warehouses}
          initialList={documents}
          initialFechaDesde={fechaDesde}
          initialFechaHasta={fechaHasta}
        />
      </section>
  )
}
