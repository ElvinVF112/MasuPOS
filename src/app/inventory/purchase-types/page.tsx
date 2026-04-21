import { InvDocTypeScreen } from "@/components/pos/inv-doc-type-screen"
import { getCurrencies, getInvTiposDocumento } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function PurchaseTypesPage() {
  const [data, currencies] = await Promise.all([
    getInvTiposDocumento("C"),
    getCurrencies(),
  ])
  const currencyOptions = currencies
    .filter(c => c.active)
    .map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))

  return (
    <section className="content-page">
        <InvDocTypeScreen
          tipoOperacion="C"
          title="Tipos Entradas por Compras"
          initialData={data}
          currencies={currencyOptions}
        />
      </section>
  )
}
