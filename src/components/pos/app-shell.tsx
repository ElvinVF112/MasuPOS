"use client"

import { useEffect, useMemo, useRef, useState } from "react"
import { usePathname, useRouter } from "next/navigation"
import { AlertTriangle, LogOut } from "lucide-react"
import { apiUrl } from "@/lib/client-config"
import { usePermissions } from "@/lib/permissions-context"
import { NAVIGATION_TREE, filterNavigationByPermission } from "@/lib/navigation"
import { Topbar } from "@/components/pos/topbar"
import { Sidebar } from "@/components/pos/sidebar"
import { AppBreadcrumbs } from "@/components/pos/breadcrumbs"
import { UnsavedGuardProvider } from "@/lib/unsaved-guard"
import { VisualConfigDrawer } from "@/components/pos/visual-config-drawer"
import { applyVisualConfig, DEFAULT_VISUAL_CONFIG, hasStoredVisualConfig, loadVisualConfig, saveVisualConfig, type VisualConfig } from "@/lib/visual-config"

type AppShellProps = {
  children: React.ReactNode
}

type EmissionPointResponse = { id: number; name: string; branchName: string }

export function AppShell({ children }: AppShellProps) {
  const pathname = usePathname()
  const router = useRouter()
  const { hasPermission } = usePermissions()

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
  const [sidebarTemporaryOpen, setSidebarTemporaryOpen] = useState(false)
  const [sidebarTemporaryCollapsed, setSidebarTemporaryCollapsed] = useState(false)
  const [sidebarRequestedModuleKey, setSidebarRequestedModuleKey] = useState<string | null>(null)
  const [lastActivityAt, setLastActivityAt] = useState(() => Date.now())
  const [idleWarningOpen, setIdleWarningOpen] = useState(false)
  const [idleCountdownMs, setIdleCountdownMs] = useState(0)
  const logoutInFlightRef = useRef(false)

  const visibleModules = useMemo(
    () => filterNavigationByPermission(NAVIGATION_TREE, (permission) => (!permission ? true : hasPermission(permission))),
    [hasPermission],
  )
  const effectiveSidebarMode = useMemo(() => {
    if (visualConfig.sidebarMode === "semi") {
      return sidebarTemporaryOpen ? "expanded" : "semi"
    }
    return sidebarTemporaryCollapsed ? "semi" : "expanded"
  }, [sidebarTemporaryCollapsed, sidebarTemporaryOpen, visualConfig.sidebarMode])

  useEffect(() => {
    applyVisualConfig(visualConfig)
  }, [visualConfig])

  useEffect(() => {
    let mounted = true

    async function loadShellData() {
      const brandingResponse = await fetch(apiUrl("/api/company/public"), { cache: "no-store", credentials: "include" })
      if (brandingResponse.ok && mounted) {
        const branding = (await brandingResponse.json()) as {
          ok: boolean
          data?: { tradeName?: string; hasLogoBinary?: boolean; logoUrl?: string }
        }

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
      if (hasStoredVisualConfig(visualKey)) {
        setVisualConfig(storedVisualConfig)
      } else {
        setVisualConfig({
          ...storedVisualConfig,
          sidebarMode: pathname.startsWith("/facturacion/pos") ? "semi" : storedVisualConfig.sidebarMode,
        })
      }

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
        .map((point) => ({
          id: String(point.id),
          label: point.branchName ? `${point.branchName} - ${point.name}` : point.name,
        }))

      if (options.length === 0) return
      setEmissionPoints(options)

      const stored = window.localStorage.getItem("masu_selected_emission_point_id")
      const selected = stored && options.some((point) => point.id === stored) ? stored : options[0].id
      setSelectedEmissionPointId(selected)
    }

    void loadShellData()
    return () => {
      mounted = false
    }
  }, [router])

  useEffect(() => {
    if (!userVisualKey || userVisualKey === "guest") return
    if (hasStoredVisualConfig(userVisualKey)) return
    setVisualConfig((current) => {
      const nextMode = pathname.startsWith("/facturacion/pos") ? "semi" : "expanded"
      if (current.sidebarMode === nextMode) return current
      return { ...current, sidebarMode: nextMode }
    })
  }, [pathname, userVisualKey])

  useEffect(() => {
    if (visualConfig.sidebarMode === "semi") {
      setSidebarTemporaryCollapsed(false)
    } else {
      setSidebarTemporaryOpen(false)
      setSidebarRequestedModuleKey(null)
    }
  }, [visualConfig.sidebarMode])

  useEffect(() => {
    if (visualConfig.sidebarMode === "semi") {
      setSidebarTemporaryOpen(false)
      setSidebarRequestedModuleKey(null)
    }
  }, [pathname, visualConfig.sidebarMode])

  useEffect(() => {
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
  }, [])

  useEffect(() => {
    const idleMs = sessionIdleMinutes * 60 * 1000
    const warningMs = Math.max(0, idleMs - (2 * 60 * 1000))

    async function logoutForIdle() {
      if (logoutInFlightRef.current) return
      logoutInFlightRef.current = true
      try {
        await fetch(apiUrl("/api/auth/logout"), { method: "POST", credentials: "include" })
      } catch {
        // ignore
      }
      router.replace("/login?reason=idle")
      router.refresh()
    }

    const timer = window.setInterval(() => {
      const elapsed = Date.now() - lastActivityAt
      const remaining = idleMs - elapsed
      setIdleCountdownMs(Math.max(0, remaining))
      setIdleWarningOpen(elapsed >= warningMs && remaining > 0)

      if (elapsed >= idleMs) {
        void logoutForIdle()
      }
    }, 1000)

    return () => window.clearInterval(timer)
  }, [lastActivityAt, router, sessionIdleMinutes])

  useEffect(() => {
    const heartbeat = window.setInterval(async () => {
      try {
        const response = await fetch(apiUrl("/api/auth/heartbeat"), {
          method: "POST",
          credentials: "include",
          cache: "no-store",
        })

        if (response.status === 401) {
          if (logoutInFlightRef.current) return
          logoutInFlightRef.current = true
          await fetch(apiUrl("/api/auth/logout"), { method: "POST", credentials: "include" }).catch(() => undefined)
          router.replace("/login?reason=idle")
          router.refresh()
        }
      } catch {
        // ignore transient heartbeat errors
      }
    }, 5 * 60 * 1000)

    return () => window.clearInterval(heartbeat)
  }, [router])

  function toggleSidebar() {
    if (visualConfig.sidebarMode === "semi") {
      setSidebarTemporaryOpen((current) => {
        const next = !current
        if (!next) setSidebarRequestedModuleKey(null)
        return next
      })
      return
    }
    setSidebarTemporaryCollapsed((current) => !current)
  }

  function openSidebarFromSemi(moduleKey: string) {
    if (visualConfig.sidebarMode !== "semi") return
    setSidebarRequestedModuleKey(moduleKey)
    setSidebarTemporaryOpen(true)
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
    const totalSeconds = Math.max(0, Math.ceil(idleCountdownMs / 1000))
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${String(seconds).padStart(2, "0")}`
  }, [idleCountdownMs])

  return (
    <UnsavedGuardProvider>
    <div className={effectiveSidebarMode === "semi" ? "app-shell app-shell--collapsed" : "app-shell"}>
      {idleWarningOpen ? (
        <div className="session-idle-banner" role="status" aria-live="polite">
          <AlertTriangle size={16} />
          <span>Su sesion expirara en {countdownText} por inactividad.</span>
        </div>
      ) : null}
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

      <Sidebar
        modules={visibleModules}
        pathname={pathname}
        mode={effectiveSidebarMode}
        semiCompactBaseMode={visualConfig.sidebarMode === "semi"}
        requestedModuleKey={sidebarRequestedModuleKey}
        onRequestExpandFromSemi={openSidebarFromSemi}
      />

      <main className="app-main erp-main">
        <div className="erp-main__breadcrumbs-wrap">
          <AppBreadcrumbs pathname={pathname} modules={visibleModules} />
        </div>
        {children}
      </main>

      {confirmLogout ? (
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
              <button type="button" className="secondary-button" onClick={() => setConfirmLogout(false)}>
                Cancelar
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={() => {
                  setConfirmLogout(false)
                  void logout()
                }}
              >
                <LogOut size={15} /> Si, cerrar sesion
              </button>
            </div>
          </div>
        </div>
      ) : null}

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
