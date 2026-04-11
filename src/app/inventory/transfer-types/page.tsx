import { AppShell } from "@/components/pos/app-shell"
import { InvDocTypeScreen } from "@/components/pos/inv-doc-type-screen"
import { getCurrencies, getInvTiposDocumento } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function TransferTypesPage() {
  const [data, currencies, entryTypes, exitTypes] = await Promise.all([
    getInvTiposDocumento("T"),
    getCurrencies(),
    getInvTiposDocumento("E"),
    getInvTiposDocumento("S"),
  ])
  const currencyOptions = currencies
    .filter(c => c.active)
    .map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))
  const entryDocTypeOptions = entryTypes
    .filter((item) => item.active)
    .map((item) => ({ id: item.id, description: item.description, prefijo: item.prefijo }))
  const exitDocTypeOptions = exitTypes
    .filter((item) => item.active)
    .map((item) => ({ id: item.id, description: item.description, prefijo: item.prefijo }))

  return (
    <AppShell>
      <section className="content-page">
        <InvDocTypeScreen
          tipoOperacion="T"
          title="Tipos de Transferencias"
          initialData={data}
          currencies={currencyOptions}
          entryDocTypes={entryDocTypeOptions}
          exitDocTypes={exitDocTypeOptions}
        />
      </section>
    </AppShell>
  )
}
