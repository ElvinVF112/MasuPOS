import { ArrowRight, CheckCircle2 } from "lucide-react"

type ModuleOverviewProps = {
  title: string
  count: number
  detail: string
}

export function ModuleOverview({ title, count, detail }: ModuleOverviewProps) {
  return (
    <article className="module-card">
      <div className="module-card__icon">
        <CheckCircle2 size={18} />
      </div>
      <div>
        <h3>{title}</h3>
        <strong className="module-card__count">{count}</strong>
        <p>{detail}</p>
      </div>
      <ArrowRight size={16} />
    </article>
  )
}
