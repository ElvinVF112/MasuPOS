import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function Tax606Page() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Impuestos / Informes Fiscales"
        title="Informe Fiscal 606"
        description="Formato 606 — Envío de compras de bienes y servicios a la DGII."
        primaryLabel="Generar informe"
        secondaryLabel="Exportar"
        chips={["606", "DGII", "Compras"]}
        bullets={[
          "Detalle de compras y servicios del período",
          "Validación de NCF y montos",
          "Exportación a formato DGII",
        ]}
      />
  )
}
