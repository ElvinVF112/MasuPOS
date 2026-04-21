import { AlertTriangle, ShoppingCart, Store, Wallet } from "lucide-react"

export const dynamic = "force-dynamic"

const KPIS = [
  { key: "sales", label: "Ventas del dia", value: "--", icon: Wallet },
  { key: "orders", label: "Órdenes activas", value: "--", icon: ShoppingCart },
  { key: "tables", label: "Mesas ocupadas", value: "--", icon: Store },
  { key: "stock", label: "Stock critico", value: "--", icon: AlertTriangle },
]

export default function DashboardPage() {
  return (
    <section className="content-page dashboard-landing">

        <div className="dashboard-kpi-grid">
          {KPIS.map((item) => {
            const Icon = item.icon
            return (
              <article key={item.key} className="dashboard-kpi-card">
                <div className="dashboard-kpi-card__icon"><Icon size={18} /></div>
                <p className="dashboard-kpi-card__label">{item.label}</p>
                <strong className="dashboard-kpi-card__value">{item.value}</strong>
              </article>
            )
          })}
        </div>
      </section>
  )
}
