import type { LucideIcon } from "lucide-react"

type StatCardProps = {
  title: string
  value: string
  detail?: string
  icon: LucideIcon
  accent?: "green" | "blue" | "cyan" | "amber"
}

export function StatCard({ title, value, detail, icon: Icon, accent = "blue" }: StatCardProps) {
  return (
    <article className="stat-card stat-card--with-icon">
      <div className="stat-card__row">
        <div>
          <span>{title}</span>
          <strong>{value}</strong>
          {detail ? <p>{detail}</p> : null}
        </div>
        <div className={`stat-card__icon stat-card__icon--${accent}`}>
          <Icon size={18} />
        </div>
      </div>
    </article>
  )
}
