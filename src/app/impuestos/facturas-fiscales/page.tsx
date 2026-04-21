import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function TaxesFiscalInvoicesPage() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Impuestos / Operaciones"
        title="Facturas Fiscales"
        description="Gestión de facturas con comprobantes fiscales NCF para cumplimiento DGII."
        primaryLabel="Nueva factura"
        secondaryLabel="Consultar"
        chips={["NCF", "DGII", "Fiscal"]}
        bullets={[
          "Emisión de facturas con NCF asignado automáticamente",
          "Soporte para crédito fiscal y consumo",
          "Integración con secuencias madre/hija",
        ]}
      />
  )
}
