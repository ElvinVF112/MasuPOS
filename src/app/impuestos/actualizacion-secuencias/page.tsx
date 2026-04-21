import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function TaxesSequenceUpdatePage() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Impuestos / Operaciones"
        title="Actualizacion de Secuencias"
        description="Proceso para actualizar, controlar y revisar el consumo de secuencias fiscales."
        primaryLabel="Actualizar"
        secondaryLabel="Ver historial"
        chips={["NCF", "Secuencias", "Control"]}
        bullets={[
          "Actualizar disponibilidad de secuencias",
          "Verificar rangos y consumo",
          "Preparar reportes fiscales del modulo",
        ]}
      />
  )
}
