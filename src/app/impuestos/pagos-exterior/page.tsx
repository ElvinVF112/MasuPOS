import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function TaxesForeignPaymentsPage() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Impuestos / Operaciones"
        title="Pagos al Exterior"
        description="Base para operaciones fiscales especiales de pagos al exterior."
        primaryLabel="Nuevo pago"
        secondaryLabel="Consultar"
        chips={["Moneda", "Retencion", "Beneficiario"]}
        bullets={[
          "Pagos al exterior con su tratamiento fiscal",
          "Control de moneda y retenciones",
          "Preparar reportes propios del modulo",
        ]}
      />
    </AppShell>
  )
}
