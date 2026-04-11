import { AppShell } from "@/components/pos/app-shell"
import { ImpuestosSecuenciasNCFScreen } from "@/components/pos/impuestos-secuencias-ncf-screen"
import { getCatalogoNCF, getSecuenciasNCF, getEmissionPoints } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function TaxesFiscalSequencesPage() {
  const [secuencias, catalogo, puntos] = await Promise.all([
    getSecuenciasNCF(),
    getCatalogoNCF(),
    getEmissionPoints(),
  ])

  const puntosEmision = puntos.map((p) => ({ id: p.id, nombre: `${p.branchName} / ${p.name}` }))

  return (
    <AppShell>
      <section className="content-page">
        <ImpuestosSecuenciasNCFScreen
          initialData={secuencias}
          catalogo={catalogo}
          puntosEmision={puntosEmision}
        />
      </section>
    </AppShell>
  )
}
