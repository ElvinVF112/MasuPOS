"use client"

import { useEffect, useMemo, useRef, useState } from "react"
import { useRouter } from "next/navigation"
import {
  BarChart3,
  Building2,
  Calculator,
  ChevronDown,
  Coins,
  Database,
  LayoutDashboard,
  Package,
  Receipt,
  Settings,
  Shield,
  ShoppingCart,
  Star,
  Utensils,
  Wallet,
} from "lucide-react"
import type { NavigationModule } from "@/lib/navigation"
import { isRouteMatch } from "@/lib/navigation"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import type { SidebarMode } from "@/lib/visual-config"

const ICONS = {
  dashboard: LayoutDashboard,
  orders: ShoppingCart,
  dining: Utensils,
  cash: Calculator,
  invoice: Receipt,
  tax: Coins,
  reports: BarChart3,
  queries: Database,
  cxc: Receipt,
  cxp: Wallet,
  settings: Settings,
  building: Building2,
  inventory: Package,
  currency: Coins,
  security: Shield,
} as const

type SidebarProps = {
  modules: NavigationModule[]
  pathname: string
  mode: SidebarMode
  semiCompactBaseMode: boolean
  requestedModuleKey?: string | null
  onRequestExpandFromSemi?: (moduleKey: string) => void
  onOpenTab?: (href: string, label: string) => void
  userKey?: string
}

const SIDEBAR_EXPANDED_KEY = "masu_sidebar_expanded_modules"
const SIDEBAR_SCROLL_KEY = "masu_sidebar_scroll_top"
const SIDEBAR_ACTIVE_OPTION_KEY = "masu_sidebar_active_option_key"
const SIDEBAR_FAVORITES_KEY = "masu_sidebar_favorites"
const SIDEBAR_TAB_KEY = "masu_sidebar_tab"

type SidebarTab = "menu" | "favorites" | "config"

function favKey(userKey?: string) {
  return userKey ? `${SIDEBAR_FAVORITES_KEY}_${userKey}` : SIDEBAR_FAVORITES_KEY
}

function readExpandedFromStorage(): Record<string, boolean> {
  try {
    const raw = window.localStorage.getItem(SIDEBAR_EXPANDED_KEY)
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, boolean>
    if (parsed && typeof parsed === "object") return parsed
  } catch { }
  return {}
}

function readFavoritesFromStorage(userKey?: string): string[] {
  try {
    const raw = window.localStorage.getItem(favKey(userKey))
    if (!raw) return []
    const parsed = JSON.parse(raw) as string[]
    if (Array.isArray(parsed)) return parsed
  } catch { }
  return []
}

export function Sidebar({ modules, pathname, mode, semiCompactBaseMode, requestedModuleKey, onRequestExpandFromSemi, onOpenTab, userKey }: SidebarProps) {
  const collapsed = mode === "semi"
  const [activeTab, setActiveTab] = useState<SidebarTab>("menu")

  useEffect(() => {
    const stored = window.sessionStorage.getItem(SIDEBAR_TAB_KEY) as SidebarTab | null
    if (stored && stored !== "menu") setActiveTab(stored)
  }, [])
  const [expandedModules, setExpandedModules] = useState<Record<string, boolean>>(() => {
    if (typeof window === "undefined") return {}
    return readExpandedFromStorage()
  })
  const [lastOptionKey, setLastOptionKey] = useState<string | null>(() => {
    if (typeof window === "undefined") return null
    return window.sessionStorage.getItem(SIDEBAR_ACTIVE_OPTION_KEY)
  })
  const [favorites, setFavorites] = useState<string[]>(() => {
    if (typeof window === "undefined") return []
    return readFavoritesFromStorage(userKey)
  })
  const scrollRef = useRef<HTMLDivElement | null>(null)

  // Separar módulos: config vs resto
  const menuModules = useMemo(() => modules.filter((m) => m.key !== "configuration"), [modules])
  const configModule = useMemo(() => modules.find((m) => m.key === "configuration") ?? null, [modules])

  const activeModuleKey = useMemo(() => {
    let match: { moduleKey: string; hrefLength: number } | null = null
    for (const module of modules) {
      for (const category of module.categories) {
        for (const option of category.options) {
          if (!isRouteMatch(pathname, option.href)) continue
          const hrefLength = option.href.length
          if (!match || hrefLength > match.hrefLength) match = { moduleKey: module.key, hrefLength }
        }
      }
    }
    return match?.moduleKey ?? null
  }, [modules, pathname])

  const activeOptionKey = useMemo(() => {
    let best: { key: string; hrefLength: number } | null = null
    const matches: Array<{ key: string; hrefLength: number }> = []
    for (const module of modules) {
      for (const category of module.categories) {
        for (const option of category.options) {
          if (!isRouteMatch(pathname, option.href)) continue
          const match = { key: option.key, hrefLength: option.href.length }
          matches.push(match)
          if (!best || match.hrefLength > best.hrefLength) best = match
        }
      }
    }
    if (lastOptionKey && matches.some((e) => e.key === lastOptionKey)) return lastOptionKey
    return best?.key ?? null
  }, [lastOptionKey, modules, pathname])

  // Favoritos agrupados por módulo
  const favoritesByModule = useMemo(() => {
    const groups: Array<{ moduleKey: string; moduleLabel: string; options: Array<{ optionKey: string; label: string; href: string }> }> = []
    for (const module of modules) {
      const opts: Array<{ optionKey: string; label: string; href: string }> = []
      for (const category of module.categories) {
        for (const option of category.options) {
          if (favorites.includes(option.key)) {
            opts.push({ optionKey: option.key, label: option.label, href: option.href })
          }
        }
      }
      if (opts.length > 0) groups.push({ moduleKey: module.key, moduleLabel: module.label, options: opts })
    }
    return groups
  }, [favorites, modules])

  const router = useRouter()
  const { requestNavigate } = useUnsavedGuard()

  function handleOptionClick(optionKey: string, href: string, label: string) {
    if (onOpenTab) {
      setLastOptionKey(optionKey)
      window.sessionStorage.setItem(SIDEBAR_ACTIVE_OPTION_KEY, optionKey)
      onOpenTab(href, label)
      return
    }
    requestNavigate(href, () => {
      setLastOptionKey(optionKey)
      window.sessionStorage.setItem(SIDEBAR_ACTIVE_OPTION_KEY, optionKey)
      router.push(href)
    })
  }

  function toggleFavorite(optionKey: string, e: React.MouseEvent) {
    e.stopPropagation()
    setFavorites((current) => {
      const next = current.includes(optionKey)
        ? current.filter((k) => k !== optionKey)
        : [...current, optionKey]
      try { window.localStorage.setItem(favKey(userKey), JSON.stringify(next)) } catch { }
      return next
    })
  }

  function openModuleFromCollapsed(moduleKey: string) {
    setExpandedModules((current) => ({ ...current, [moduleKey]: true }))
    onRequestExpandFromSemi?.(moduleKey)
  }

  function switchTab(tab: SidebarTab) {
    setActiveTab(tab)
    try { window.sessionStorage.setItem(SIDEBAR_TAB_KEY, tab) } catch { }
  }

  useEffect(() => {
    if (!activeModuleKey) return
    setExpandedModules((current) => {
      if (current[activeModuleKey]) return current
      return { ...current, [activeModuleKey]: true }
    })
  }, [activeModuleKey])

  useEffect(() => {
    if (!requestedModuleKey) return
    setExpandedModules((current) => ({ ...current, [requestedModuleKey]: true }))
  }, [requestedModuleKey])

  useEffect(() => {
    if (!activeOptionKey || !scrollRef.current) return
    const el = scrollRef.current.querySelector<HTMLElement>(`[data-option-key="${activeOptionKey}"]`)
    if (!el) return
    el.scrollIntoView({ block: "nearest", behavior: "smooth" })
  }, [activeOptionKey])

  useEffect(() => {
    try { window.localStorage.setItem(SIDEBAR_EXPANDED_KEY, JSON.stringify(expandedModules)) } catch { }
  }, [expandedModules])

  // Re-leer favoritos cuando el userKey llega (carga async desde AppShell)
  useEffect(() => {
    if (!userKey || userKey === "guest") return
    setFavorites(readFavoritesFromStorage(userKey))
  }, [userKey])

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    const raw = window.sessionStorage.getItem(SIDEBAR_SCROLL_KEY)
    if (!raw) return
    const next = Number(raw)
    if (Number.isFinite(next) && next >= 0) el.scrollTop = next
  }, [])

  useEffect(() => {
    const el = scrollRef.current
    if (!el) return
    const onScroll = () => { window.sessionStorage.setItem(SIDEBAR_SCROLL_KEY, String(el.scrollTop)) }
    el.addEventListener("scroll", onScroll, { passive: true })
    return () => el.removeEventListener("scroll", onScroll)
  }, [])

  function renderModuleList(list: NavigationModule[]) {
    return list.map((module) => {
      const Icon = ICONS[module.icon] ?? Package
      const isExpanded = Boolean(expandedModules[module.key])
      const moduleHasActive = module.categories.some((c) => c.options.some((o) => isRouteMatch(pathname, o.href)))
      return (
        <section key={module.key} className="erp-sidebar__module">
          <button
            type="button"
            className={moduleHasActive ? "erp-sidebar__module-btn is-active" : "erp-sidebar__module-btn"}
            title={collapsed ? module.label : undefined}
            onClick={() => {
              if (collapsed && semiCompactBaseMode) openModuleFromCollapsed(module.key)
              if (!expandedModules[module.key]) {
                setExpandedModules({ [module.key]: true })
              } else {
                setExpandedModules((current) => ({ ...current, [module.key]: false }))
              }
            }}
          >
            <Icon size={18} />
            <span>{module.label}</span>
            <ChevronDown size={14} className={isExpanded ? "erp-sidebar__caret is-open" : "erp-sidebar__caret"} />
          </button>

          {!collapsed ? (
            <div className={isExpanded ? "erp-sidebar__module-body is-open" : "erp-sidebar__module-body"}>
              {module.categories.map((category) => {
                const categoryActive = category.options.some((o) => isRouteMatch(pathname, o.href))
                return (
                  <div key={category.key} className={categoryActive ? "erp-sidebar__category is-active" : "erp-sidebar__category"}>
                    <p>{category.label}</p>
                    <div className="erp-sidebar__options">
                      {category.options.map((option) => {
                        const active = option.key === activeOptionKey
                        const isFav = favorites.includes(option.key)
                        return (
                          <div key={option.key} className="erp-sidebar__option-wrap">
                            <button
                              type="button"
                              data-option-key={option.key}
                              className={active ? "erp-sidebar__option is-active" : "erp-sidebar__option"}
                              onClick={() => handleOptionClick(option.key, option.href, option.label)}
                            >
                              {option.label}
                            </button>
                            <button
                              type="button"
                              className={isFav ? "erp-sidebar__fav-btn erp-sidebar__fav-btn--active" : "erp-sidebar__fav-btn"}
                              onClick={(e) => toggleFavorite(option.key, e)}
                              title={isFav ? "Quitar de favoritos" : "Agregar a favoritos"}
                            >
                              <Star size={15} fill={isFav ? "currentColor" : "none"} />
                            </button>
                          </div>
                        )
                      })}
                    </div>
                  </div>
                )
              })}
            </div>
          ) : null}
        </section>
      )
    })
  }

  return (
    <aside className={collapsed ? "sidebar erp-sidebar sidebar--collapsed" : "sidebar erp-sidebar"}>
      {/* ── Tab switcher ─────────────────────────────────── */}
      {!collapsed && (
        <div className="erp-sidebar__tabs">
          <button
            type="button"
            className={activeTab === "menu" ? "erp-sidebar__tab is-active" : "erp-sidebar__tab"}
            onClick={() => switchTab("menu")}
          >
            Menú
          </button>
          <button
            type="button"
            className={activeTab === "favorites" ? "erp-sidebar__tab is-active" : "erp-sidebar__tab"}
            onClick={() => switchTab("favorites")}
          >
            <Star size={11} fill={activeTab === "favorites" ? "currentColor" : "none"} />
            Favoritos
            {favorites.length > 0 && <span className="erp-sidebar__tab-badge">{favorites.length}</span>}
          </button>
          <button
            type="button"
            className={activeTab === "config" ? "erp-sidebar__tab is-active" : "erp-sidebar__tab"}
            onClick={() => switchTab("config")}
          >
            <Settings size={11} />
            Config
          </button>
        </div>
      )}

      <div className="erp-sidebar__scroll" ref={scrollRef}>

        {/* ── Tab: Menú ─────────────────────────────────── */}
        {activeTab === "menu" && renderModuleList(menuModules)}

        {/* ── Tab: Favoritos ────────────────────────────── */}
        {!collapsed && activeTab === "favorites" && (
          favoritesByModule.length === 0 ? (
            <div className="erp-sidebar__empty">
              <Star size={28} />
              <span>Sin favoritos</span>
              <small>Marca opciones con ★ desde el Menú</small>
            </div>
          ) : (
            favoritesByModule.map((group) => (
              <section key={group.moduleKey} className="erp-sidebar__module">
                <p className="erp-sidebar__fav-module-label">{group.moduleLabel}</p>
                <div className="erp-sidebar__options erp-sidebar__options--favorites">
                  {group.options.map((fav) => {
                    const active = fav.optionKey === activeOptionKey
                    return (
                      <div key={fav.optionKey} className="erp-sidebar__option-wrap">
                        <button
                          type="button"
                          data-option-key={fav.optionKey}
                          className={active ? "erp-sidebar__option is-active" : "erp-sidebar__option"}
                          onClick={() => handleOptionClick(fav.optionKey, fav.href, fav.label)}
                        >
                          {fav.label}
                        </button>
                        <button
                          type="button"
                          className="erp-sidebar__fav-btn erp-sidebar__fav-btn--active"
                          onClick={(e) => toggleFavorite(fav.optionKey, e)}
                          title="Quitar de favoritos"
                        >
                          <Star size={15} fill="currentColor" />
                        </button>
                      </div>
                    )
                  })}
                </div>
              </section>
            ))
          )
        )}

        {/* ── Tab: Configuración ────────────────────────── */}
        {!collapsed && activeTab === "config" && configModule && configModule.categories.map((category) => {
          const categoryActive = category.options.some((o) => isRouteMatch(pathname, o.href))
          return (
            <section key={category.key} className="erp-sidebar__module">
              <div className={categoryActive ? "erp-sidebar__category is-active" : "erp-sidebar__category"}>
                <p>{category.label}</p>
                <div className="erp-sidebar__options">
                  {category.options.map((option) => {
                    const active = option.key === activeOptionKey
                    const isFav = favorites.includes(option.key)
                    return (
                      <div key={option.key} className="erp-sidebar__option-wrap">
                        <button
                          type="button"
                          data-option-key={option.key}
                          className={active ? "erp-sidebar__option is-active" : "erp-sidebar__option"}
                          onClick={() => handleOptionClick(option.key, option.href, option.label)}
                        >
                          {option.label}
                        </button>
                        <button
                          type="button"
                          className={isFav ? "erp-sidebar__fav-btn erp-sidebar__fav-btn--active" : "erp-sidebar__fav-btn"}
                          onClick={(e) => toggleFavorite(option.key, e)}
                          title={isFav ? "Quitar de favoritos" : "Agregar a favoritos"}
                        >
                          <Star size={15} fill={isFav ? "currentColor" : "none"} />
                        </button>
                      </div>
                    )
                  })}
                </div>
              </div>
            </section>
          )
        })}
        {!collapsed && activeTab === "config" && !configModule && (
          <div className="erp-sidebar__empty">
            <Settings size={28} />
            <span>Sin acceso</span>
            <small>No tienes permisos de configuración</small>
          </div>
        )}

      </div>
    </aside>
  )
}
