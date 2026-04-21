import { PageHeader } from "@/components/pos/page-header"

export const dynamic = "force-dynamic"

export default function CatalogStockLimitsPage() {
  return (
    <section className="content-page">
        <PageHeader title="Minimo, Maximo, Reorden" description="Administra limites por producto y almacen" />
        <div className="detail-empty">
          <p>Esta vista se encuentra en implementacion. Mientras tanto, gestiona los limites desde Productos &gt; Existencia.</p>
        </div>
      </section>
  )
}
