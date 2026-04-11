import { AppShell } from "@/components/pos/app-shell"
import { FacFormasPagoScreen } from "@/components/pos/fac-formas-pago-screen"
import { getCurrencies, getEmissionPoints, getFacFormasPago } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function PaymentMethodsPage() {
  const [data, currencies, puntos] = await Promise.all([
    getFacFormasPago(),
    getCurrencies(),
    getEmissionPoints(),
  ])
  const currencyOptions = currencies
    .filter(c => c.active)
    .map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))
  const puntosEmision = puntos.map(p => ({ id: p.id, nombre: `${p.branchName} / ${p.name}` }))

  return (
    <AppShell>
      <section className="content-page">
        <FacFormasPagoScreen
          initialData={data}
          currencies={currencyOptions}
          puntosEmision={puntosEmision}
        />
      </section>
    </AppShell>
  )
}
