"use client"

type ModuleScaffoldScreenProps = {
  eyebrow: string
  title: string
  description: string
  primaryLabel: string
  secondaryLabel: string
  bullets: string[]
  chips?: string[]
}

export function ModuleScaffoldScreen({
  eyebrow,
  title,
  description,
  primaryLabel,
  secondaryLabel,
  bullets,
  chips = [],
}: ModuleScaffoldScreenProps) {
  return (
    <section className="content-page module-workspace">
      <div className="module-workspace__hero">
        <div>
          <p className="module-workspace__eyebrow">{eyebrow}</p>
          <h1 className="module-workspace__title">{title}</h1>
          <p className="module-workspace__description">{description}</p>
        </div>
        <div className="module-workspace__hero-actions">
          <button type="button" className="secondary-button">
            {secondaryLabel}
          </button>
          <button type="button" className="primary-button">
            {primaryLabel}
          </button>
        </div>
      </div>

      {chips.length > 0 ? (
        <div className="module-workspace__chips">
          {chips.map((chip) => (
            <span key={chip} className="module-workspace__chip">
              {chip}
            </span>
          ))}
        </div>
      ) : null}

      <div className="module-workspace__grid">
        <article className="module-workspace__card">
          <h2>Vista de trabajo</h2>
          <p>
            Este espacio ya queda preparado con la navegacion y la estructura del modulo para que
            construyamos la operacion real sobre una base estable.
          </p>
          <ul className="module-workspace__list">
            {bullets.map((bullet) => (
              <li key={bullet}>{bullet}</li>
            ))}
          </ul>
        </article>

        <article className="module-workspace__card module-workspace__card--accent">
          <h2>Proximo paso</h2>
          <p>
            Ahora podemos conectar datos reales, SPs y acciones operativas sin volver a rehacer el
            layout del modulo.
          </p>
        </article>
      </div>
    </section>
  )
}
