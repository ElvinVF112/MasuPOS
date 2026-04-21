import { FacDocTypeScreen } from "@/components/pos/fac-doc-type-screen"
import { getCatalogoNCF, getCurrencies, getFacTiposDocumento } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function SalesOrderTypesPage() {
  const [data, currencies, catalogo] = await Promise.all([
    getFacTiposDocumento("P"),
    getCurrencies(),
    getCatalogoNCF(),
  ])
  const currencyOptions = currencies
    .filter(c => c.active)
    .map(c => ({ id: c.id, code: c.code, name: c.name, symbol: c.symbol ?? "" }))

  return (
    <section className="content-page">
        <FacDocTypeScreen
          tipoOperacion="P"
          title="Tipos de Órdenes de Pedido"
          initialData={data}
          currencies={currencyOptions}
          catalogo={catalogo}
        />
      </section>
  )
}
