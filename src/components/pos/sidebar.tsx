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
}

const SIDEBAR_EXPANDED_KEY = "masu_sidebar_expanded_modules"
const SIDEBAR_SCROLL_KEY = "masu_sidebar_scroll_top"
const SIDEBAR_ACTIVE_OPTION_KEY = "masu_sidebar_active_option_key"

function readExpandedFromStorage(): Record<string, boolean> {
  try {
    const raw = window.localStorage.getItem(SIDEBAR_EXPANDED_KEY)
    if (!raw) return {}
    const parsed = JSON.parse(raw) as Record<string, boolean>
    if (parsed && typeof parsed === "object") return parsed
  } catch {
    // no-op
  }
  return {}
}

export function Sidebar({ modules, pathname, mode, semiCompactBaseMode, requestedModuleKey, onRequestExpandFromSemi }: SidebarProps) {
  const collapsed = mode === "semi"
  const [expandedModules, setExpandedModules] = useState<Record<string, boolean>>(() => {
    if (typeof window === "undefined") return {}
    return readExpandedFromStorage()
  })
  const [lastOptionKey, setLastOptionKey] = useState<string | null>(() => {
    if (typeof window === "undefined") return null
    return window.sessionStorage.getItem(SIDEBAR_ACTIVE_OPTION_KEY)
  })
  const scrollRef = useRef<HTMLDivElement | null>(null)

  const activeModuleKey = useMemo(() => {
    let match: { moduleKey: string; hrefLength: number } | null = null
    for (const module of modules) {
      for (const category of module.categories) {
        for (const option of category.options) {
          if (!isRouteMatch(pathname, option.href)) continue
          const hrefLength = option.href.length
          if (!match || hrefLength > match.hrefLength) {
            match = { moduleKey: module.key, hrefLength }
          }
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

    if (lastOptionKey && matches.some((entry) => entry.key === lastOptionKey)) {
      return lastOptionKey
    }

    return best?.key ?? null
  }, [lastOptionKey, modules, pathname])

  const router = useRouter()
  const { requestNavigate } = useUnsavedGuard()

  function handleOptionClick(optionKey: string, href: string) {
    requestNavigate(href, () => {
      setLastOptionKey(optionKey)
      window.sessionStorage.setItem(SIDEBAR_ACTIVE_OPTION_KEY, optionKey)
      router.push(href)
    })
  }

  function openModuleFromCollapsed(moduleKey: string) {
    setExpandedModules((current) => ({ ...current, [moduleKey]: true }))
    onRequestExpandFromSemi?.(moduleKey)
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
    try {
      window.localStorage.setItem(SIDEBAR_EXPANDED_KEY, JSON.stringify(expandedModules))
    } catch {
      // no-op
    }
  }, [expandedModules])

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
    const onScroll = () => {
      window.sessionStorage.setItem(SIDEBAR_SCROLL_KEY, String(el.scrollTop))
    }
    el.addEventListener("scroll", onScroll, { passive: true })
    return () => el.removeEventListener("scroll", onScroll)
  }, [])

  return (
    <aside className={collapsed ? "sidebar erp-sidebar sidebar--collapsed" : "sidebar erp-sidebar"}>
      <div className="erp-sidebar__scroll" ref={scrollRef}>
        {modules.map((module) => {
          const Icon = ICONS[module.icon] ?? Package
          const isExpanded = Boolean(expandedModules[module.key])
          const moduleHasActive = module.categories.some((category) => category.options.some((option) => isRouteMatch(pathname, option.href)))

          return (
            <section key={module.key} className="erp-sidebar__module">
              <button
                type="button"
                className={moduleHasActive ? "erp-sidebar__module-btn is-active" : "erp-sidebar__module-btn"}
                title={collapsed ? module.label : undefined}
                onClick={() => {
                  if (collapsed && semiCompactBaseMode) {
                    openModuleFromCollapsed(module.key)
                  }
                  const isExpanding = !expandedModules[module.key]
                  if (isExpanding) {
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
                    const categoryActive = category.options.some((option) => isRouteMatch(pathname, option.href))
                    return (
                      <div key={category.key} className={categoryActive ? "erp-sidebar__category is-active" : "erp-sidebar__category"}>
                        <p>{category.label}</p>
                        <div className="erp-sidebar__options">
                          {category.options.map((option) => {
                            const active = option.key === activeOptionKey
                            return (
                              <button
                                key={option.key}
                                type="button"
                                data-option-key={option.key}
                                className={active ? "erp-sidebar__option is-active" : "erp-sidebar__option"}
                                onClick={() => handleOptionClick(option.key, option.href)}
                              >
                                {option.label}
                              </button>
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
        })}
      </div>
    </aside>
  )
}
