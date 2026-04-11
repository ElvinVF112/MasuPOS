"use client"

import { type KeyboardEvent as ReactKeyboardEvent, useEffect, useRef, useState } from "react"
import { ChevronDown, Menu, Search, User, LogOut, GitBranch, SlidersHorizontal } from "lucide-react"
import { useI18n } from "@/lib/i18n"

type Option = { id: string; label: string }

type TopbarProps = {
  brandName: string
  brandLogo: string
  sessionName: string
  sessionRole: string
  emissionPoints: Option[]
  selectedEmissionPointId: string
  onSelectEmissionPoint: (id: string) => void
  onToggleSidebar: () => void
  onOpenVisualConfig: () => void
  onLogout: () => void
}

function stopSubmitOnEnter(event: ReactKeyboardEvent<HTMLInputElement>) {
  if (event.key === "Enter") event.preventDefault()
}

export function Topbar({
  brandName,
  brandLogo,
  sessionName,
  sessionRole,
  emissionPoints,
  selectedEmissionPointId,
  onSelectEmissionPoint,
  onToggleSidebar,
  onOpenVisualConfig,
  onLogout,
}: TopbarProps) {
  const { t } = useI18n()
  const [menuOpen, setMenuOpen] = useState(false)
  const searchRef = useRef<HTMLInputElement | null>(null)
  const menuRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    function onPointerDown(event: MouseEvent) {
      if (!menuRef.current) return
      if (!menuRef.current.contains(event.target as Node)) setMenuOpen(false)
    }

    function onKeyboard(event: KeyboardEvent) {
      if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
        event.preventDefault()
        searchRef.current?.focus()
      }
    }

    window.addEventListener("mousedown", onPointerDown)
    window.addEventListener("keydown", onKeyboard)
    return () => {
      window.removeEventListener("mousedown", onPointerDown)
      window.removeEventListener("keydown", onKeyboard)
    }
  }, [])

  return (
    <header className="topbar erp-topbar">
      <button className="erp-topbar__toggle" type="button" aria-label="Colapsar menu" onClick={onToggleSidebar}>
        <Menu size={18} />
      </button>

      <div className="brand erp-topbar__brand">
        <div className={brandLogo ? "brand__mark brand__mark--image" : "brand__mark"}>
          {brandLogo ? <img src={brandLogo} alt="Logo empresa" /> : <span>40</span>}
        </div>
        <div className="brand__text"><span>{brandName}</span></div>
      </div>

      <label className="searchbar erp-topbar__search">
        <Search size={16} />
        <input
          ref={searchRef}
          type="search"
          placeholder="Buscar pantallas, productos, clientes..."
          onKeyDown={stopSubmitOnEnter}
        />
        <span className="erp-topbar__shortcut">Ctrl+K</span>
      </label>

      <div className="erp-topbar__selectors">
        <label className="erp-topbar__select-wrap" title="Sucursal - Punto de emision">
          <GitBranch size={14} />
          <select value={selectedEmissionPointId} onChange={(event) => onSelectEmissionPoint(event.target.value)}>
            {emissionPoints.map((option) => <option key={option.id} value={option.id}>{option.label}</option>)}
          </select>
        </label>
      </div>

      <div className="topbar__right erp-topbar__actions">
        <button className="erp-topbar__icon-btn" type="button" onClick={onOpenVisualConfig} title="Configuración visual">
          <SlidersHorizontal size={16} />
        </button>
        <div className="user-menu" ref={menuRef}>
          <button className="user-chip user-chip--button erp-topbar__user-chip" type="button" onClick={() => setMenuOpen((current) => !current)}>
            <div className="user-chip__avatar"><User size={16} /></div>
            <div>
              <strong>{sessionName}</strong>
              <span>{sessionRole || t("common.manager")}</span>
            </div>
            <ChevronDown size={14} />
          </button>

          {menuOpen ? (
            <div className="dropdown-menu dropdown-menu--user dropdown-menu--fb erp-topbar__menu">
              <div className="fb-menu-profile">
                <div className="fb-menu-profile__avatar"><User size={16} /></div>
                <div>
                  <strong>{sessionName}</strong>
                  <span>{sessionRole || t("common.manager")}</span>
                </div>
              </div>

              <button className="dropdown-item dropdown-item--fb" type="button">
                <User size={16} /> Perfil
              </button>
              <button className="dropdown-item dropdown-item--fb is-danger" type="button" onClick={onLogout}>
                <LogOut size={16} /> Cerrar sesion
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </header>
  )
}
