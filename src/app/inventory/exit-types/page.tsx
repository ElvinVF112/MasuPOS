import { AppShell } from "@/components/pos/app-shell"
import { InvDocTypeScreen } from "@/components/pos/inv-doc-type-screen"
import { getCurrencies, getInvTiposDocumento } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function ExitTypesPage() {
  const [data, currencies] = await Promise.all([
    getInvTiposDocumento("S"),
    getCurrencies(),
  ])
  const currencyOptions = currencies
    .filter(c => c.active)
    .map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))

  return (
    <AppShell>
      <section className="content-page">
        <InvDocTypeScreen
          tipoOperacion="S"
          title="Tipos de Salidas"
          initialData={data}
          currencies={currencyOptions}
        />
      </section>
    </AppShell>
  )
}
