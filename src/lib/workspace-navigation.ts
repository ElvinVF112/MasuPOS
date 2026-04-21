"use client"

import { apiUrl } from "@/lib/client-config"

type StoredTab = {
  key: string
  href: string
  label: string
}

type StoredTabsState = {
  tabs: StoredTab[]
  activeTabKey: string | null
}

const APP_TABS_STORAGE_KEY = "masu_app_tabs_state"
const FULLSCREEN_ROUTES = ["/facturacion/pos", "/orders", "/dining-room", "/facturacion/caja-central"]

export function resolveStartRoute(rawRoute?: string) {
  const route = (rawRoute || "").trim()
  if (!route) return "/dashboard"

  const normalized = route.toLowerCase()
  const legacyMap: Record<string, string> = {
    "/": "/dashboard",
    "/usuarios": "/config/security/users",
    "/roles": "/config/security/roles",
    "/permisos": "/config/security/roles",
  }

  return legacyMap[normalized] || route || "/dashboard"
}

function readTabsState(): StoredTabsState {
  if (typeof window === "undefined") return { tabs: [], activeTabKey: null }

  try {
    const raw = window.sessionStorage.getItem(APP_TABS_STORAGE_KEY)
    if (!raw) return { tabs: [], activeTabKey: null }

    const parsed = JSON.parse(raw) as Partial<StoredTabsState>
    const tabs = Array.isArray(parsed.tabs)
      ? parsed.tabs.filter((tab): tab is StoredTab => Boolean(tab && typeof tab.key === "string" && typeof tab.href === "string"))
      : []
    const activeTabKey = typeof parsed.activeTabKey === "string" ? parsed.activeTabKey : null

    return { tabs, activeTabKey }
  } catch {
    return { tabs: [], activeTabKey: null }
  }
}

function normalizePath(path: string) {
  const clean = (path || "").trim()
  if (!clean) return "/"

  const [withoutHash] = clean.split("#")
  const [withoutQuery] = withoutHash.split("?")
  if (!withoutQuery) return "/"

  const normalized = withoutQuery !== "/" ? withoutQuery.replace(/\/+$/, "") : "/"
  return normalized || "/"
}

function isFullscreenRoute(path: string) {
  const normalized = normalizePath(path)
  return FULLSCREEN_ROUTES.some((route) => normalized === route || normalized.startsWith(`${route}/`))
}

function getCurrentPath() {
  if (typeof window === "undefined") return "/"
  return normalizePath(window.location.pathname)
}

type WorkspaceNavigator = {
  push: (href: string) => void
}

export async function navigateToWorkspaceTarget(router: WorkspaceNavigator) {
  const stored = readTabsState()
  const currentPath = getCurrentPath()
  const activeTab = stored.tabs.find((tab) => tab.key === stored.activeTabKey)
  const activeTabHref = activeTab ? normalizePath(activeTab.href) : null

  if (activeTab?.href && activeTabHref && activeTabHref !== currentPath) {
    router.push(activeTab.href)
    return
  }

  const fallbackTab = [...stored.tabs]
    .reverse()
    .find((tab) => {
      const href = normalizePath(tab.href)
      return href !== currentPath && !isFullscreenRoute(href)
    })

  if (fallbackTab?.href) {
    router.push(fallbackTab.href)
    return
  }

  try {
    const response = await fetch(apiUrl("/api/auth/me"), { cache: "no-store", credentials: "include" })
    if (!response.ok) {
      router.push("/dashboard")
      return
    }

    const result = (await response.json()) as { ok?: boolean; user?: { defaultRoute?: string } }
    const startRoute = resolveStartRoute(result.user?.defaultRoute)
    router.push(normalizePath(startRoute) === currentPath ? "/dashboard" : startRoute)
  } catch {
    router.push(currentPath === "/dashboard" ? "/" : "/dashboard")
  }
}
