import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function TaxesInformalSuppliersPage() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Impuestos / Operaciones"
        title="Proveedores Informales"
        description="Base para registrar pagos y comprobantes asociados a proveedores informales."
        primaryLabel="Nuevo registro"
        secondaryLabel="Historial"
        chips={["Proveedor", "Retencion", "Soporte"]}
        bullets={[
          "Registro fiscal de proveedor informal",
          "Base para reportes e impuestos",
          "Preparar secuencias y control documental",
        ]}
      />
  )
}
