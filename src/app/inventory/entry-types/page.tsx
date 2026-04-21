import { InvDocTypeScreen } from "@/components/pos/inv-doc-type-screen"
import { getCurrencies, getInvTiposDocumento } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function EntryTypesPage() {
  const [data, currencies] = await Promise.all([
    getInvTiposDocumento("E"),
    getCurrencies(),
  ])
  const currencyOptions = currencies
    .filter(c => c.active)
    .map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))

  return (
    <section className="content-page">
        <InvDocTypeScreen
          tipoOperacion="E"
          title="Tipos de Entradas"
          initialData={data}
          currencies={currencyOptions}
        />
      </section>
  )
}
