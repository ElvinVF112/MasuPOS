"use client"

import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { usePathname, useRouter } from "next/navigation"
import { AlertTriangle, LogOut } from "lucide-react"

import { Sidebar } from "@/components/pos/sidebar"
import { TabBar, type AppTab } from "@/components/pos/tab-bar"
import { Topbar } from "@/components/pos/topbar"
import { VisualConfigDrawer } from "@/components/pos/visual-config-drawer"
import { apiUrl } from "@/lib/client-config"
import { NAVIGATION_TREE, filterNavigationByPermission } from "@/lib/navigation"
import { usePermissions } from "@/lib/permissions-context"
import { UnsavedGuardProvider } from "@/lib/unsaved-guard"
import { applyVisualConfig, DEFAULT_VISUAL_CONFIG, hasStoredVisualConfig, loadVisualConfig, saveVisualConfig, type VisualConfig } from "@/lib/visual-config"

const FULLSCREEN_ROUTES = ["/facturacion/pos", "/orders", "/facturacion/caja-central"]
const APP_TABS_STORAGE_KEY = "masu_app_tabs_state"

type AppShellProps = { children: React.ReactNode }
type EmissionPointResponse = { id: number; name: string; branchName: string }
type StoredTabsState = { tabs: AppTab[]; activeTabKey: string | null }

let tabKeyCounter = 1

function isFullscreenRoute(pathname: string) {
  return FULLSCREEN_ROUTES.some((route) => pathname === route || pathname.startsWith(`${route}/`))
}

function nextTabKey() {
  return `tab-${tabKeyCounter++}`
}

function readTabsState(): StoredTabsState {
  if (typeof window === "undefined") return { tabs: [], activeTabKey: null }

  try {
    const raw = window.sessionStorage.getItem(APP_TABS_STORAGE_KEY)
    if (!raw) return { tabs: [], activeTabKey: null }

    const parsed = JSON.parse(raw) as Partial<StoredTabsState>
    const tabs = Array.isArray(parsed.tabs)
      ? parsed.tabs.filter((tab): tab is AppTab => Boolean(tab && typeof tab.key === "string" && typeof tab.href === "string" && typeof tab.label === "string"))
      : []
    const activeTabKey = typeof parsed.activeTabKey === "string" ? parsed.activeTabKey : null

    return { tabs, activeTabKey }
  } catch {
    return { tabs: [], activeTabKey: null }
  }
}

export function AppShell({ children }: AppShellProps) {
  const pathname = usePathname()
  const router = useRouter()
  const { hasPermission } = usePermissions()

  const [isEmbedded, setIsEmbedded] = useState(false)
  useEffect(() => {
    setIsEmbedded(new URLSearchParams(window.location.search).get("_tab") === "1")
  }, [])

  const [sessionName, setSessionName] = useState("-")
  const [sessionRole, setSessionRole] = useState("")
  const [brandName, setBrandName] = useState("Masu POS")
  const [brandLogo, setBrandLogo] = useState("")
  const [confirmLogout, setConfirmLogout] = useState(false)
  const [emissionPoints, setEmissionPoints] = useState<Array<{ id: string; label: string }>>([{ id: "main", label: "Principal" }])
  const [selectedEmissionPointId, setSelectedEmissionPointId] = useState("main")
  const [sessionIdleMinutes, setSessionIdleMinutes] = useState(30)
  const [userVisualKey, setUserVisualKey] = useState("guest")
  const [visualConfig, setVisualConfig] = useState<VisualConfig>(DEFAULT_VISUAL_CONFIG)
  const [visualConfigOpen, setVisualConfigOpen] = useState(false)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [sidebarHidden, setSidebarHidden] = useState(false)
  const [lastActivityAt, setLastActivityAt] = useState(() => Date.now())
  const [idleWarningOpen, setIdleWarningOpen] = useState(false)
  const [idleCountdownMs, setIdleCountdownMs] = useState(0)
  const logoutInFlightRef = useRef(false)

  const [tabs, setTabs] = useState<AppTab[]>([])
  const [activeTabKey, setActiveTabKey] = useState<string | null>(null)
  const [tabsHydrated, setTabsHydrated] = useState(false)

  const openTab = useCallback((href: string, label: string) => {
    if (isFullscreenRoute(href)) {
      router.push(href)
      return
    }

    setTabs((current) => {
      const existing = current.find((tab) => tab.href === href)
      if (existing) {
        setActiveTabKey(existing.key)
        return current
      }

      const key = nextTabKey()
      setActiveTabKey(key)
      return [...current, { key, href, label }]
    })
  }, [router])

  const closeTab = useCallback((key: string) => {
    setTabs((current) => {
      const index = current.findIndex((tab) => tab.key === key)
      if (index === -1) return current

      const next = current.filter((tab) => tab.key !== key)
      setActiveTabKey((active) => {
        if (active !== key) return active
        const sibling = next[index] ?? next[index - 1] ?? null
        return sibling?.key ?? null
      })

      return next
    })
  }, [])

  const closeAllTabs = useCallback(() => {
    setTabs([])
    setActiveTabKey(null)
  }, [])

  const activateTab = useCallback((key: string) => {
    setActiveTabKey(key)
  }, [])

  useEffect(() => {
    const stored = readTabsState()
    setTabs(stored.tabs)
    setActiveTabKey(stored.activeTabKey)
    setTabsHydrated(true)
  }, [])

  useEffect(() => {
    if (!tabsHydrated || typeof window === "undefined") return

    const nextState: StoredTabsState = {
      tabs,
      activeTabKey: tabs.some((tab) => tab.key === activeTabKey) ? activeTabKey : null,
    }

    window.sessionStorage.setItem(APP_TABS_STORAGE_KEY, JSON.stringify(nextState))
  }, [activeTabKey, tabs, tabsHydrated])

  useEffect(() => {
    if (tabs.length === 0) return

    const maxCounter = tabs.reduce((max, tab) => {
      const match = /^tab-(\d+)$/.exec(tab.key)
      const value = match ? Number(match[1]) : 0
      return Number.isFinite(value) ? Math.max(max, value) : max
    }, 0)

    if (maxCounter >= tabKeyCounter) {
      tabKeyCounter = maxCounter + 1
    }
  }, [tabs])

  const visibleModules = useMemo(
    () => filterNavigationByPermission(NAVIGATION_TREE, (permission) => (!permission ? true : hasPermission(permission))),
    [hasPermission],
  )

  const fullscreen = isFullscreenRoute(pathname)
  const hasTabs = tabs.length > 0
  const sidebarFixed = visualConfig.sidebarMode === "always"
  const showFixedSidebar = sidebarFixed && !fullscreen && !sidebarHidden

  useEffect(() => {
    applyVisualConfig(visualConfig)
  }, [visualConfig])

  useEffect(() => {
    if (isEmbedded) return

    let mounted = true

    async function loadShellData() {
      const brandingResponse = await fetch(apiUrl("/api/company/public"), { cache: "no-store", credentials: "include" })
      if (brandingResponse.ok && mounted) {
        const branding = (await brandingResponse.json()) as { ok: boolean; data?: { tradeName?: string; hasLogoBinary?: boolean; logoUrl?: string } }
        if (branding.ok && branding.data) {
          setBrandName(branding.data.tradeName || "Masu POS")
          if (branding.data.hasLogoBinary) setBrandLogo(`${apiUrl("/api/company/logo/public")}?v=${Date.now()}`)
          else setBrandLogo(branding.data.logoUrl || "")
        }
      }

      const response = await fetch(apiUrl("/api/auth/me"), { cache: "no-store", credentials: "include" })
      if (!mounted) return
      if (!response.ok) {
        router.replace("/login")
        return
      }

      const result = (await response.json()) as { ok: boolean; user?: { fullName: string; role: string }; sessionIdleMinutes?: number }
      if (!result.ok || !result.user) {
        router.replace("/login")
        return
      }

      const authUser = result.user as typeof result.user & { userId?: number; username?: string }
      const visualKey = authUser?.userId ? String(authUser.userId) : authUser?.username || "guest"
      setUserVisualKey(visualKey)

      const storedVisualConfig = loadVisualConfig(visualKey)
      setVisualConfig(hasStoredVisualConfig(visualKey) ? storedVisualConfig : {
        ...storedVisualConfig,
        sidebarMode: pathname.startsWith("/facturacion/pos") ? "autohide" : storedVisualConfig.sidebarMode,
      })

      setSessionName(result.user.fullName || "Usuario")
      setSessionRole(result.user.role || "")
      setSessionIdleMinutes(Math.max(1, result.sessionIdleMinutes ?? 30))
      setLastActivityAt(Date.now())

      const emissionResponse = await fetch(apiUrl("/api/org/emission-points"), { cache: "no-store", credentials: "include" })
      if (!mounted || !emissionResponse.ok) return

      const emissionData = (await emissionResponse.json()) as { ok: boolean; data?: EmissionPointResponse[] }
      if (!emissionData.ok || !Array.isArray(emissionData.data) || emissionData.data.length === 0) return

      const options = emissionData.data
        .filter((point) => point && typeof point.id === "number")
        .map((point) => ({ id: String(point.id), label: point.branchName ? `${point.branchName} - ${point.name}` : point.name }))
      if (options.length === 0) return

      setEmissionPoints(options)

      const stored = window.localStorage.getItem("masu_selected_emission_point_id")
      setSelectedEmissionPointId(stored && options.some((point) => point.id === stored) ? stored : options[0].id)
    }

    void loadShellData()
    return () => { mounted = false }
  }, [isEmbedded, pathname, router])

  useEffect(() => {
    if (!userVisualKey || userVisualKey === "guest") return
    if (hasStoredVisualConfig(userVisualKey)) return
    if (pathname.startsWith("/facturacion/pos")) {
      setVisualConfig((current) => current.sidebarMode === "autohide" ? current : { ...current, sidebarMode: "autohide" })
    }
  }, [pathname, userVisualKey])

  useEffect(() => {
    setDrawerOpen(false)
  }, [pathname])

  useEffect(() => {
    if (isEmbedded) return

    const onActivity = () => {
      setLastActivityAt(Date.now())
      setIdleWarningOpen(false)
    }

    window.addEventListener("mousemove", onActivity)
    window.addEventListener("keydown", onActivity)
    window.addEventListener("click", onActivity)
    window.addEventListener("scroll", onActivity, true)

    return () => {
      window.removeEventListener("mousemove", onActivity)
      window.removeEventListener("keydown", onActivity)
      window.removeEventListener("click", onActivity)
      window.removeEventListener("scroll", onActivity, true)
    }
  }, [isEmbedded])

  useEffect(() => {
    if (isEmbedded) return

    const idleMs = sessionIdleMinutes * 60 * 1000
    const warningMs = Math.max(0, idleMs - 2 * 60 * 1000)

    async function logoutForIdle() {
      if (logoutInFlightRef.current) return
      logoutInFlightRef.current = true
      try { await fetch(apiUrl("/api/auth/logout"), { method: "POST", credentials: "include" }) } catch { }
      router.replace("/login?reason=idle")
      router.refresh()
    }

    const timer = window.setInterval(() => {
      const elapsed = Date.now() - lastActivityAt
      const remaining = idleMs - elapsed
      setIdleCountdownMs(Math.max(0, remaining))
      setIdleWarningOpen(elapsed >= warningMs && remaining > 0)
      if (elapsed >= idleMs) void logoutForIdle()
    }, 1000)

    return () => window.clearInterval(timer)
  }, [isEmbedded, lastActivityAt, router, sessionIdleMinutes])

  useEffect(() => {
    if (isEmbedded) return

    const heartbeat = window.setInterval(async () => {
      try {
        const response = await fetch(apiUrl("/api/auth/heartbeat"), { method: "POST", credentials: "include", cache: "no-store" })
        if (response.status === 401) {
          if (logoutInFlightRef.current) return
          logoutInFlightRef.current = true
          await fetch(apiUrl("/api/auth/logout"), { method: "POST", credentials: "include" }).catch(() => undefined)
          router.replace("/login?reason=idle")
          router.refresh()
        }
      } catch { }
    }, 5 * 60 * 1000)

    return () => window.clearInterval(heartbeat)
  }, [isEmbedded, router])

  function toggleSidebar() {
    if (sidebarFixed && !fullscreen) {
      setSidebarHidden((current) => !current)
      return
    }

    setDrawerOpen((current) => !current)
  }

  function selectEmissionPoint(id: string) {
    setSelectedEmissionPointId(id)
    window.localStorage.setItem("masu_selected_emission_point_id", id)
  }

  function updateVisualConfig(next: VisualConfig) {
    setVisualConfig(next)
    saveVisualConfig(userVisualKey, next)
  }

  function resetVisualConfig() {
    setVisualConfig(DEFAULT_VISUAL_CONFIG)
    saveVisualConfig(userVisualKey, DEFAULT_VISUAL_CONFIG)
  }

  async function logout() {
    await fetch(apiUrl("/api/auth/logout"), { method: "POST", credentials: "include" })
    router.replace("/login")
    router.refresh()
  }

  const countdownText = useMemo(() => {
    const total = Math.max(0, Math.ceil(idleCountdownMs / 1000))
    return `${Math.floor(total / 60)}:${String(total % 60).padStart(2, "0")}`
  }, [idleCountdownMs])

  if (isEmbedded) {
    return (
      <UnsavedGuardProvider>
        <div className="app-shell--embedded">
          {children}
        </div>
      </UnsavedGuardProvider>
    )
  }

  return (
    <UnsavedGuardProvider>
      <div className={[
        "app-shell",
        !showFixedSidebar ? "app-shell--collapsed" : "",
        fullscreen ? "app-shell--fullscreen" : "",
      ].filter(Boolean).join(" ")}>
        {idleWarningOpen && (
          <div className="session-idle-banner" role="status" aria-live="polite">
            <AlertTriangle size={16} />
            <span>Su sesion expirara en {countdownText} por inactividad.</span>
          </div>
        )}

        <Topbar
          brandName={brandName}
          brandLogo={brandLogo}
          sessionName={sessionName}
          sessionRole={sessionRole}
          emissionPoints={emissionPoints}
          selectedEmissionPointId={selectedEmissionPointId}
          onSelectEmissionPoint={selectEmissionPoint}
          onToggleSidebar={toggleSidebar}
          onOpenVisualConfig={() => setVisualConfigOpen(true)}
          onLogout={() => setConfirmLogout(true)}
        />

        {showFixedSidebar && (
          <Sidebar
            modules={visibleModules}
            pathname={pathname}
            mode="expanded"
            semiCompactBaseMode={false}
            requestedModuleKey={null}
            onOpenTab={openTab}
            userKey={userVisualKey}
          />
        )}

        {drawerOpen && (
          <>
            <div className="sidebar-drawer-backdrop" onClick={() => setDrawerOpen(false)} />
            <div className="sidebar-drawer">
              <Sidebar
                modules={visibleModules}
                pathname={pathname}
                mode="expanded"
                semiCompactBaseMode={false}
                requestedModuleKey={null}
                onOpenTab={(href, label) => {
                  openTab(href, label)
                  setDrawerOpen(false)
                }}
                userKey={userVisualKey}
              />
            </div>
          </>
        )}

        <main className={`app-main erp-main${hasTabs && !fullscreen ? " erp-main--tabs" : ""}`}>
          {hasTabs && !fullscreen && (
            <TabBar
              tabs={tabs}
              activeKey={activeTabKey}
              onActivate={activateTab}
              onClose={closeTab}
              onCloseAll={closeAllTabs}
            />
          )}

          {hasTabs ? (
            <div className={`tab-content${fullscreen ? " tab-content--hidden" : ""}`}>
              {tabs.map((tab) => (
                <iframe
                  key={tab.key}
                  src={`${tab.href}${tab.href.includes("?") ? "&" : "?"}_tab=1`}
                  className={`tab-content__frame${tab.key === activeTabKey ? " is-active" : ""}`}
                  title={tab.label}
                />
              ))}
            </div>
          ) : null}

          {fullscreen ? children : (!hasTabs ? children : null)}
        </main>

        {confirmLogout && (
          <div className="modal-backdrop" onClick={() => setConfirmLogout(false)}>
            <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
              <div className="modal-card__header modal-card__header--brand">
                <div className="modal-card__header-icon"><LogOut size={20} /></div>
                <div>
                  <h3 className="modal-card__title">Cerrar sesion</h3>
                  <p className="modal-card__subtitle">Sesion de {sessionName}</p>
                </div>
              </div>
              <div className="modal-card__body">
                <p>Estas seguro que deseas cerrar sesion? Deberas iniciar sesion nuevamente para continuar.</p>
              </div>
              <div className="modal-card__footer">
                <button type="button" className="secondary-button" onClick={() => setConfirmLogout(false)}>Cancelar</button>
                <button type="button" className="danger-button" onClick={() => { setConfirmLogout(false); void logout() }}>
                  <LogOut size={15} /> Si, cerrar sesion
                </button>
              </div>
            </div>
          </div>
        )}

        <VisualConfigDrawer
          open={visualConfigOpen}
          config={visualConfig}
          onClose={() => setVisualConfigOpen(false)}
          onChange={updateVisualConfig}
          onReset={resetVisualConfig}
        />
      </div>
    </UnsavedGuardProvider>
  )
}
