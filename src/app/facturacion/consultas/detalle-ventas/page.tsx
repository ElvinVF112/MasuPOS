import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingSalesDetailPage() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Facturacion / Consultas"
        title="Detalle de Ventas"
        description="Consulta detallada de ventas por documento, cliente, caja, usuario y moneda."
        primaryLabel="Filtrar"
        secondaryLabel="Exportar"
        chips={["Documentos", "Cliente", "Caja", "Usuario"]}
        bullets={[
          "Detalle de ventas por documento",
          "Filtros por fecha, caja, usuario y moneda",
          "Base para exportacion y reportes",
        ]}
      />
    </AppShell>
  )
}
