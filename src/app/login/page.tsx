"use client"

import { Suspense, type CSSProperties, type FormEvent, useEffect, useRef, useState } from "react"
import { useRouter, useSearchParams } from "next/navigation"
import { Building2, Check, Eye, EyeOff, Globe, Loader2, LockKeyhole, LogIn, UserRound } from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { usePermissions } from "@/lib/permissions-context"
import { useI18n } from "@/lib/i18n"

function resolveStartRoute(rawRoute?: string) {
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

function LoginPageContent() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const { setPermissions, refreshPermissions } = usePermissions()
  const { language, setLanguage, t } = useI18n()
  const langMenuRef = useRef<HTMLDivElement | null>(null)
  const [username, setUsername] = useState("")
  const [password, setPassword] = useState("")
  const [rememberUsername, setRememberUsername] = useState(true)
  const [brandName, setBrandName] = useState("Masu POS")
  const [brandLogo, setBrandLogo] = useState("")
  const [brandSlogan, setBrandSlogan] = useState("")
  const [showPassword, setShowPassword] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [isPending, setIsPending] = useState(false)
  const [forcePasswordChange, setForcePasswordChange] = useState(false)
  const [pendingRoute, setPendingRoute] = useState("/")
  const [newPassword, setNewPassword] = useState("")
  const [confirmNewPassword, setConfirmNewPassword] = useState("")
  const [passwordChangeMessage, setPasswordChangeMessage] = useState<string | null>(null)
  const [langMenuOpen, setLangMenuOpen] = useState(false)

  const brandPanelStyle = brandLogo
    ? ({
        ["--login-brand-image" as string]: `url("${brandLogo}")`,
      } as CSSProperties)
    : undefined

  useEffect(() => {
    function onPointerDown(event: MouseEvent) {
      if (!langMenuRef.current) return
      if (!langMenuRef.current.contains(event.target as Node)) {
        setLangMenuOpen(false)
      }
    }
    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  useEffect(() => {
    if (searchParams.get("reason") === "idle") {
      setMessage("Su sesion fue cerrada por inactividad. Inicie sesion nuevamente.")
    }
  }, [searchParams])

  useEffect(() => {
    const storedUsername = window.localStorage.getItem("masu-remember-username")
    if (storedUsername) {
      setUsername(storedUsername)
      setRememberUsername(true)
    }

    let mounted = true
    async function checkSession() {
      const brandingResponse = await fetch(apiUrl("/api/company/public"), { cache: "no-store" })
      if (brandingResponse.ok && mounted) {
        const branding = (await brandingResponse.json()) as {
          ok: boolean
          data?: { tradeName?: string; hasLogoBinary?: boolean; logoUrl?: string; slogan?: string }
        }

        if (branding.ok && branding.data) {
          setBrandName(branding.data.tradeName || "Masu POS")
          if (branding.data.slogan) {
            setBrandSlogan(branding.data.slogan)
          }
          if (branding.data.hasLogoBinary) {
            setBrandLogo(`${apiUrl("/api/company/logo/public")}?v=${Date.now()}`)
          } else if (branding.data.logoUrl) {
            setBrandLogo(branding.data.logoUrl)
          }
        }
      }

      const response = await fetch(apiUrl("/api/auth/me"), { cache: "no-store", credentials: "include" })
      if (!mounted) return
      if (response.ok) {
        const result = (await response.json()) as { ok: boolean; user?: { defaultRoute?: string } }
        router.replace(resolveStartRoute(result.user?.defaultRoute))
      }
    }
    void checkSession()
    return () => {
      mounted = false
    }
  }, [router])

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setMessage(null)
    setIsPending(true)

    try {
      const response = await fetch(apiUrl("/api/auth/login"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      })

      const result = (await response.json()) as { ok: boolean; message?: string; user?: { defaultRoute?: string; mustChangePassword?: boolean }; permissions?: string[] }
      if (!response.ok || !result.ok) {
        const errorMessage = result.message ?? "Credenciales invalidas."
        setMessage(errorMessage)
        return
      }

      if (rememberUsername) {
        window.localStorage.setItem("masu-remember-username", username.trim())
      } else {
        window.localStorage.removeItem("masu-remember-username")
      }

      const targetRoute = resolveStartRoute(result.user?.defaultRoute)
      const permissions = result.permissions ?? []
      setPermissions(permissions)

      if (result.user?.mustChangePassword) {
        setPendingRoute(targetRoute)
        setForcePasswordChange(true)
        setPasswordChangeMessage(null)
        setNewPassword("")
        setConfirmNewPassword("")
        return
      }

      toast.success("Bienvenido de nuevo", {
        description: "Has iniciado sesión correctamente",
      })

      await new Promise((resolve) => setTimeout(resolve, 900))

      router.replace(targetRoute)
      router.refresh()
      void refreshPermissions()
    } catch {
      setMessage("No se pudo iniciar sesion.")
    } finally {
      setIsPending(false)
    }
  }

  async function onForcePasswordSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setPasswordChangeMessage(null)

    if (newPassword.trim().length < 6) {
      setPasswordChangeMessage("La contraseña debe tener al menos 6 caracteres.")
      return
    }

    if (newPassword !== confirmNewPassword) {
      setPasswordChangeMessage("Las contraseñas no coinciden.")
      return
    }

    setIsPending(true)
    try {
      const response = await fetch(apiUrl("/api/auth/change-password"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ newPassword }),
      })

      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        setPasswordChangeMessage(result.message ?? "No se pudo actualizar la contraseña.")
        return
      }

      toast.success("Bienvenido de nuevo", {
        description: "Contraseña actualizada correctamente",
      })

      router.replace(pendingRoute || "/")
      router.refresh()
    } catch {
      setPasswordChangeMessage("No se pudo actualizar la contraseña.")
    } finally {
      setIsPending(false)
    }
  }

  return (
    <main className="login-page">
      {/* Panel izquierdo — branding */}
      <div className={brandLogo ? "login-brand-panel login-brand-panel--with-image" : "login-brand-panel"} style={brandPanelStyle}>
        <div className="login-brand-content">
          {brandLogo ? null : (
            <div className="login-brand-panel__logo">
              <Building2 size={64} color="#ffffff" opacity={0.9} />
            </div>
          )}
          <h1 className="login-brand-panel__name">{brandName}</h1>
          <p className="login-brand-panel__tagline">{brandSlogan || t("login.brandTagline")}</p>
        </div>
        <footer className="login-brand-footer">
          <span>{t("login.version")}</span>
          <small>{t("login.copyright").replace("{brand}", "Masu POS")}</small>
        </footer>
      </div>

      {/* Panel derecho — formulario */}
      <div className="login-form-panel">
        <div className="login-lang" ref={langMenuRef}>
          <button
            className="login-lang-button"
            type="button"
            aria-label={t("language.select")}
            onClick={() => setLangMenuOpen((value) => !value)}
          >
            <Globe size={16} />
            <span>{language === "es" ? "Espanol" : "English"}</span>
          </button>

          {langMenuOpen ? (
            <div className="login-lang-menu">
              <button className="login-lang-item" type="button" onClick={() => { setLanguage("es"); setLangMenuOpen(false) }}>
                <span>ES</span>
                <span>Espanol</span>
                {language === "es" ? <Check size={16} /> : null}
              </button>
              <button className="login-lang-item" type="button" onClick={() => { setLanguage("en"); setLangMenuOpen(false) }}>
                <span>US</span>
                <span>English</span>
                {language === "en" ? <Check size={16} /> : null}
              </button>
            </div>
          ) : null}
        </div>

        <section className="login-card">
          <form className="login-form" onSubmit={onSubmit}>
            <label>
              <span>{t("login.username")}</span>
              <div className="login-input-wrap">
                <UserRound size={16} />
                <input value={username} onChange={(event) => setUsername(event.target.value)} autoComplete="username" placeholder={t("login.usernamePlaceholder")} />
              </div>
            </label>

            <label>
              <span>{t("login.password")}</span>
              <div className="login-input-wrap">
                <LockKeyhole size={16} />
                <input type={showPassword ? "text" : "password"} value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" placeholder={t("login.passwordPlaceholder")} />
                <button className="login-visibility" type="button" aria-label={showPassword ? t("login.hidePassword") : t("login.showPassword")} onClick={() => setShowPassword((value) => !value)}>
                  {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
                </button>
              </div>
            </label>

            {message ? <div className="login-error-box"><p className="login-message">{message}</p></div> : null}

            <label className="login-switch-row">
              <span>{t("login.rememberUser")}</span>
              <button
                className={rememberUsername ? "toggle-switch is-on" : "toggle-switch"}
                type="button"
                onClick={() => setRememberUsername((value) => !value)}
                aria-label={t("login.rememberUser")}
              >
                <span />
              </button>
            </label>

            <button className="primary-button" type="submit" disabled={!username.trim() || !password.trim() || isPending}>
              {isPending ? <><Loader2 size={16} className="spin" /> {t("login.signingIn")}</> : <><LogIn size={16} /> {t("login.signIn")}</>}
            </button>

          </form>
        </section>
      </div>

      {forcePasswordChange ? (
        <div className="users-modal-backdrop" onClick={(event) => event.stopPropagation()}>
          <section className="users-modal users-modal--compact" onClick={(event) => event.stopPropagation()}>
            <div className="users-modal__header">
              <div className="users-modal__identity users-modal__identity--stacked">
                <div>
                  <h3>Cambiar contraseña</h3>
                  <p>Debes crear tu propia contraseña para continuar.</p>
                </div>
              </div>
            </div>

            <form className="form-grid form-grid--spaced" onSubmit={onForcePasswordSubmit}>
              <label className="form-grid__full">
                <span>Nueva contraseña</span>
                <input
                  type="password"
                  value={newPassword}
                  onChange={(event) => setNewPassword(event.target.value)}
                  autoComplete="new-password"
                  required
                />
              </label>

              <label className="form-grid__full">
                <span>Confirmar contraseña</span>
                <input
                  type="password"
                  value={confirmNewPassword}
                  onChange={(event) => setConfirmNewPassword(event.target.value)}
                  autoComplete="new-password"
                  required
                />
              </label>

              {passwordChangeMessage ? <p className="form-message">{passwordChangeMessage}</p> : null}

              <div className="form-actions">
                <button className="primary-button" type="submit" disabled={isPending}>
                  {isPending ? "Guardando..." : "Guardar contraseña"}
                </button>
              </div>
            </form>
          </section>
        </div>
      ) : null}
    </main>
  )
}

export default function LoginPage() {
  return (
    <Suspense fallback={<main className="login-page" />}>
      <LoginPageContent />
    </Suspense>
  )
}
