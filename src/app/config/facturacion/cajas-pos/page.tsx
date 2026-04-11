import { AppShell } from "@/components/pos/app-shell"
import { FacCajasPOSScreen } from "@/components/pos/fac-cajas-pos-screen"
import { getBranches, getCurrencies, getEmissionPoints, getFacCajasPOS } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CajasPOSPage() {
  const [data, branches, emissionPoints, currencies] = await Promise.all([
    getFacCajasPOS(),
    getBranches(),
    getEmissionPoints(),
    getCurrencies(),
  ])

  const sucursales = branches.filter(b => b.active).map(b => ({ id: b.id, nombre: b.name }))
  const puntosEmision = emissionPoints.filter(p => p.active).map(p => ({ id: p.id, nombre: `${p.branchName} / ${p.name}`, idSucursal: p.branchId }))
  const currencyOptions = currencies.filter(c => c.active).map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))

  return (
    <AppShell>
      <section className="content-page">
        <FacCajasPOSScreen
          initialData={data}
          sucursales={sucursales}
          puntosEmision={puntosEmision}
          currencies={currencyOptions}
        />
      </section>
    </AppShell>
  )
}
