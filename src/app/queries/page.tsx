import { Database, Download, FileSpreadsheet, Filter } from "lucide-react"

export const dynamic = "force-dynamic"

const queryModules = [
  { name: "Ventas", queries: ["Ventas por fecha", "Ventas por producto", "Ventas por mesero"] },
  { name: "Inventario", queries: ["Niveles de stock", "Movimientos de inventario"] },
  { name: "Caja", queries: ["Movimientos de caja", "Cortes de caja"] },
  { name: "Salon", queries: ["Ocupacion de recursos", "Reservaciones"] },
]

export default function QueriesPage() {
  return (
    <section className="content-page">
        <div className="queries-layout">
          <aside className="data-panel">
            <div className="data-panel__header"><h2>Modulos</h2><p>Catalogo inicial importado desde UI 2.0.</p></div>
            <div className="stack-list">
              {queryModules.map((module) => (
                <article className="stack-item" key={module.name}>
                  <strong>{module.name}</strong>
                  <span>{module.queries.join(" · ")}</span>
                </article>
              ))}
            </div>
          </aside>

          <section className="data-panel">
            <div className="data-panel__header data-panel__header--actions">
              <div>
                <h2>Constructor de consulta</h2>
                <p>Queda listo el entrypoint funcional para conectar filtros y ejecucion real contra SQL Server.</p>
              </div>
              <div className="toolbar-row">
                <button className="secondary-button" type="button"><Filter size={16} />Filtros</button>
                <button className="secondary-button" type="button"><FileSpreadsheet size={16} />Excel</button>
                <button className="secondary-button" type="button"><Download size={16} />PDF</button>
              </div>
            </div>

            <div className="detail-empty detail-empty--compact">
              <Database size={32} />
              <h3>Merge aplicado</h3>
              <p>Esta pantalla ya existe en la app principal y sirve como base para traer la logica avanzada de consultas de `D:\Masu\UI 2.0\app\queries\page.tsx` en la siguiente iteracion.</p>
            </div>
          </section>
        </div>
      </section>
  )
}
