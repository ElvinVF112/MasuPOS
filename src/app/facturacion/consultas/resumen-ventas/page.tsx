import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingSalesSummaryPage() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Facturacion / Consultas"
        title="Resumen de Ventas"
        description="Resumen ejecutivo de ventas por periodo, caja, sucursal, punto de emision y usuario."
        primaryLabel="Generar resumen"
        secondaryLabel="Exportar"
        chips={["Periodo", "Caja", "Sucursal"]}
        bullets={[
          "Resumen consolidado de ventas",
          "Vista por sucursal, terminal o usuario",
          "Base para reportes comerciales",
        ]}
      />
    </AppShell>
  )
}
