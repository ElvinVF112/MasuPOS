"use client"

import { useEffect, useRef, useState } from "react"
import { X, PanelTopClose, ChevronLeft, ChevronRight } from "lucide-react"

export type AppTab = {
  key: string
  href: string
  label: string
}

type Props = {
  tabs: AppTab[]
  activeKey: string | null
  onActivate: (key: string) => void
  onClose: (key: string) => void
  onCloseAll: () => void
}

export function TabBar({ tabs, activeKey, onActivate, onClose, onCloseAll }: Props) {
  const scrollRef = useRef<HTMLDivElement>(null)
  const [canScrollLeft, setCanScrollLeft] = useState(false)
  const [canScrollRight, setCanScrollRight] = useState(false)

  function checkScroll() {
    const el = scrollRef.current
    if (!el) return
    setCanScrollLeft(el.scrollLeft > 4)
    setCanScrollRight(el.scrollLeft + el.clientWidth < el.scrollWidth - 4)
  }

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    checkScroll()
    el.addEventListener("scroll", checkScroll, { passive: true })
    const ro = new ResizeObserver(checkScroll)
    ro.observe(el)
    return () => { el.removeEventListener("scroll", checkScroll); ro.disconnect() }
  }, [tabs])

  // Scroll al tab activo cuando cambia
  useEffect(() => {
    const el = scrollRef.current
    if (!el || !activeKey) return
    const btn = el.querySelector<HTMLElement>(`[data-tab-key="${activeKey}"]`)
    btn?.scrollIntoView({ inline: "nearest", block: "nearest", behavior: "smooth" })
  }, [activeKey])

  function scrollBy(dir: -1 | 1) {
    scrollRef.current?.scrollBy({ left: dir * 160, behavior: "smooth" })
  }

  if (tabs.length === 0) return null

  return (
    <div className="tab-bar">
      {canScrollLeft && (
        <button type="button" className="tab-bar__scroll-btn" onClick={() => scrollBy(-1)} aria-label="Scroll izquierda">
          <ChevronLeft size={13} />
        </button>
      )}

      <div className={`tab-bar__tabs${canScrollRight ? " tab-bar__tabs--fade-right" : ""}`} ref={scrollRef}>
        {tabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            data-tab-key={tab.key}
            className={`tab-bar__tab${tab.key === activeKey ? " is-active" : ""}`}
            onClick={() => onActivate(tab.key)}
            title={tab.label}
          >
            <span className="tab-bar__tab-label">{tab.label}</span>
            <span
              className="tab-bar__tab-close"
              role="button"
              tabIndex={-1}
              aria-label={`Cerrar ${tab.label}`}
              onClick={(e) => { e.stopPropagation(); onClose(tab.key) }}
            >
              <X size={11} />
            </span>
          </button>
        ))}
      </div>

      {canScrollRight && (
        <button type="button" className="tab-bar__scroll-btn" onClick={() => scrollBy(1)} aria-label="Scroll derecha">
          <ChevronRight size={13} />
        </button>
      )}

      {tabs.length > 1 && (
        <button
          type="button"
          className="tab-bar__close-all"
          onClick={onCloseAll}
          title="Cerrar todas las pestañas"
        >
          <PanelTopClose size={13} />
          <span>Cerrar todo</span>
        </button>
      )}
    </div>
  )
}
