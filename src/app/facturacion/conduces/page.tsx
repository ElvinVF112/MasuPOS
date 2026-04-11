import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingDeliveryNotesPage() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Facturacion / Operaciones"
        title="Conduces"
        description="Base para manejar conduces de salida y su relacion con facturacion posterior."
        primaryLabel="Nuevo conduce"
        secondaryLabel="Tipos"
        chips={["Despacho", "Cliente", "Documento"]}
        bullets={[
          "Conduce ligado a cliente y lineas",
          "Relacion con facturacion posterior",
          "Tipos de conduce configurables",
        ]}
      />
    </AppShell>
  )
}
