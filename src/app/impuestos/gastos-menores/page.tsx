import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function TaxesMinorExpensesPage() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Impuestos / Operaciones"
        title="Gastos Menores"
        description="Base para registrar gastos menores con su tratamiento fiscal propio."
        primaryLabel="Nuevo gasto"
        secondaryLabel="Consultar"
        chips={["Fiscal", "Caja", "Soporte"]}
        bullets={[
          "Registro de gasto menor con soporte",
          "Impacto en caja y reportes fiscales",
          "Base para cierres y arqueos",
        ]}
      />
  )
}
