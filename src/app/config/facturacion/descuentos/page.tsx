import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingDiscountsPage() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Facturacion / Maestros"
        title="Descuentos"
        description="Base para descuentos por linea y descuentos generales aplicables a la factura."
        primaryLabel="Nuevo descuento"
        secondaryLabel="Politicas"
        chips={["Linea", "General", "Porcentaje", "Monto"]}
        bullets={[
          "Descuentos reutilizables en POS y facturacion",
          "Aplicacion por linea o general",
          "Preparar restricciones por cliente o usuario",
        ]}
      />
  )
}
