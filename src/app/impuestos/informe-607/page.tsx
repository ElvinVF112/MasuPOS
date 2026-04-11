import { AppShell } from "@/components/pos/app-shell"
import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function Tax607Page() {
  return (
    <AppShell>
      <ModuleScaffoldScreen
        eyebrow="Impuestos / Informes Fiscales"
        title="Informe Fiscal 607"
        description="Formato 607 — Envío de ventas de bienes y servicios a la DGII."
        primaryLabel="Generar informe"
        secondaryLabel="Exportar"
        chips={["607", "DGII", "Ventas"]}
        bullets={[
          "Detalle de ventas y servicios del período",
          "Validación de NCF emitidos y montos",
          "Exportación a formato DGII",
        ]}
      />
    </AppShell>
  )
}
