import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingReturnsPage() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Facturacion / Operaciones"
        title="Devoluciones de Mercancia"
        description="Base para devoluciones, notas relacionadas y trazabilidad posterior en facturacion."
        primaryLabel="Nueva devolucion"
        secondaryLabel="Buscar documento"
        chips={["Factura origen", "Motivo", "Totales"]}
        bullets={[
          "Tomar factura origen y lineas",
          "Aplicar cantidades y motivo de devolucion",
          "Preparar enlace con nota de credito o ajuste",
        ]}
      />
    </AppShell>
  )
}
