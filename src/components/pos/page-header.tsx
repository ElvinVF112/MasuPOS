type PageHeaderProps = {
  title: string
  description?: string
  action?: React.ReactNode
  children?: React.ReactNode
}

export function PageHeader({ title, description, action, children }: PageHeaderProps) {
  return (
    <div className="page-header">
      <div>
        <h1>{title}</h1>
        {description ? <p>{description}</p> : null}
      </div>
      {action || children ? <div className="page-header__action">{action ?? children}</div> : null}
    </div>
  )
}
