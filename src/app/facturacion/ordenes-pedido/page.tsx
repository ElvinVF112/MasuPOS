import { ModuleScaffoldScreen } from "@/components/pos/module-scaffold-screen"

export default function BillingSalesOrdersPage() {
  return (
    <ModuleScaffoldScreen
        eyebrow="Facturacion / Operaciones"
        title="Ordenes de Pedido"
        description="Base para pedidos de clientes que luego pueden importarse a cotizacion o punto de ventas."
        primaryLabel="Nueva orden"
        secondaryLabel="Importar"
        chips={["Cliente", "Entrega", "Referencia"]}
        bullets={[
          "Pedidos de cliente previos a la venta",
          "Importacion al punto de ventas",
          "Tipos de orden configurables",
        ]}
      />
  )
}
