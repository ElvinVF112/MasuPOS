import { AppShell } from "@/components/pos/app-shell"
import { ImpuestosCatalogoNCFScreen } from "@/components/pos/impuestos-catalogo-ncf-screen"
import { getCatalogoNCF } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function TaxesVoucherTypesPage() {
  const data = await getCatalogoNCF()
  return (
    <AppShell>
      <section className="content-page">
        <ImpuestosCatalogoNCFScreen initialData={data} />
      </section>
    </AppShell>
  )
}
