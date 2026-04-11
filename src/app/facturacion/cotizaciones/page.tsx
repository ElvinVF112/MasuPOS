import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingQuotesPage() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Facturacion / Operaciones"
        title="Cotizaciones"
        description="Espacio base para construir cotizaciones, convertirlas y traerlas al punto de ventas."
        primaryLabel="Nueva cotizacion"
        secondaryLabel="Importar"
        chips={["Cliente", "Moneda", "Validez"]}
        bullets={[
          "Crear cotizaciones con cliente, lineas y comentarios",
          "Importar cotizaciones al punto de ventas",
          "Preparar ciclo de aprobacion y conversion",
        ]}
      />
    </AppShell>
  )
}
