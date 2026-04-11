"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Building2, CalendarDays, Clock3, GitBranch, KeyRound, Loader2, Lock, Mail, MapPinned, MoreHorizontal, Pencil, Plus, Save, Search, Shield, Trash2, UserRound, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import type { SecurityManagerData } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { useFormat } from "@/lib/format-context"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

type UserForm = {
  id?: number
  names: string
  surnames: string
  userName: string
  userType: "A" | "S" | "O"
  roleId: string
  startScreenId: string
  email: string
  passwordHash: string
  mustChangePassword: boolean
  canDeletePosLines: boolean
  canChangePosDate: boolean
  locked: boolean
  active: boolean
  companyId: string
  divisionId: string
  branchId: string
  emissionPointId: string
  dataAccessLevel: "G" | "E" | "D" | "S" | "P" | "U"
  createdBy: number
  createdAt: string
  updatedBy: number
  updatedAt: string
}

type UserActivityData = {
  summary: {
    totalSessions: number
    lastLogin: string
    accountCreatedAt: string
    accountUpdatedAt: string
  }
  sessions: Array<{
    id: number
    channel: string
    ipAddress: string
    isActive: boolean
    startedAt: string
    lastActivityAt: string
    endedAt: string
    durationMinutes: number
  }>
}

function toForm(user: SecurityManagerData["users"][number]): UserForm {
  return {
    id: user.id,
    names: user.names,
    surnames: user.surnames,
    userName: user.userName,
    userType: user.userType,
    roleId: String(user.roleId),
    startScreenId: user.startScreenId ? String(user.startScreenId) : "",
    email: user.email,
    passwordHash: user.passwordHash,
    mustChangePassword: user.mustChangePassword,
    canDeletePosLines: user.canDeletePosLines,
    canChangePosDate: user.canChangePosDate,
    locked: user.locked,
    active: user.active,
    companyId: user.companyId ? String(user.companyId) : "",
    divisionId: user.divisionId ? String(user.divisionId) : "",
    branchId: user.branchId ? String(user.branchId) : "",
    emissionPointId: user.emissionPointId ? String(user.emissionPointId) : "",
    dataAccessLevel: user.dataAccessLevel,
    createdBy: user.createdBy,
    createdAt: user.createdAt,
    updatedBy: user.updatedBy,
    updatedAt: user.updatedAt,
  }
}

const emptyForm: UserForm = {
  names: "",
  surnames: "",
  userName: "",
  userType: "O",
  roleId: "",
  startScreenId: "",
  email: "",
  passwordHash: "",
  mustChangePassword: false,
  canDeletePosLines: false,
  canChangePosDate: false,
  locked: false,
  active: true,
  companyId: "",
  divisionId: "",
  branchId: "",
  emissionPointId: "",
  dataAccessLevel: "G",
  createdBy: 0,
  createdAt: "",
  updatedBy: 0,
  updatedAt: "",
}

function initials(names: string, surnames: string) {
  const first = names.trim()[0] ?? "U"
  const second = surnames.trim()[0] ?? ""
  return `${first}${second}`.toUpperCase()
}

export function SecurityUsersScreen({ data }: { data: SecurityManagerData }) {
  const router = useRouter()
  const { t } = useI18n()
  const { formatDateTime } = useFormat()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [isCreating, setIsCreating] = useState(false)
  const [isEditing, setIsEditing] = useState(false)
  const [form, setForm] = useState<UserForm>(emptyForm)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [activeTab, setActiveTab] = useState<"general" | "administrative" | "security" | "activity">("general")
  const [message, setMessage] = useState<string | null>(null)
  const [securityPassword, setSecurityPassword] = useState("")
  const [securityConfirmPassword, setSecurityConfirmPassword] = useState("")
  const [securityMessage, setSecurityMessage] = useState<string | null>(null)
  const [activityData, setActivityData] = useState<UserActivityData | null>(null)
  const [activityError, setActivityError] = useState<string | null>(null)
  const [currentUserId, setCurrentUserId] = useState<number | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<SecurityManagerData["users"][number] | null>(null)
  const [isActivityLoading, setIsActivityLoading] = useState(false)
  const [isPending, startTransition] = useTransition()

  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    if (!normalized) return data.users
    return data.users.filter((user) => {
      const text = `${user.names} ${user.surnames} ${user.userName} ${user.email} ${user.roleName}`.toLowerCase()
      return text.includes(normalized)
    })
  }, [data.users, query])

  const selected = useMemo(() => data.users.find(u => u.id === selectedId) ?? null, [data.users, selectedId])
  const filteredBranches = useMemo(() => {
    if (!form.divisionId) return data.lookups.branches
    return data.lookups.branches.filter((branch) => String(branch.divisionId) === form.divisionId)
  }, [data.lookups.branches, data.users, form.divisionId])
  const filteredEmissionPoints = useMemo(() => {
    if (!form.branchId) return data.lookups.emissionPoints
    return data.lookups.emissionPoints.filter((point) => String(point.branchId) === form.branchId)
  }, [data.lookups.emissionPoints, form.branchId])

  useEffect(() => {
    let cancelled = false
    void fetch(apiUrl("/api/auth/me"), { cache: "no-store", credentials: "include" })
      .then(async (response) => {
        const result = (await response.json()) as { ok: boolean; user?: { userId: number } }
        if (!cancelled && response.ok && result.ok && result.user?.userId) {
          setCurrentUserId(result.user.userId)
        }
      })
      .catch(() => undefined)
    return () => { cancelled = true }
  }, [])

  useEffect(() => {
    function onPointerDown(event: MouseEvent) {
      const target = event.target as HTMLElement | null
      if (!target) return
      if (target.closest(".users-sidebar__menu-wrap")) return
      setMenuId(null)
    }
    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  useEffect(() => {
    if (!selectedId || activeTab !== "activity") return
    let cancelled = false
    setIsActivityLoading(true)
    setActivityError(null)
    void fetch(apiUrl(`/api/users/${selectedId}/activity`), { cache: "no-store", credentials: "include" })
      .then(async (response) => {
        const result = (await response.json()) as { ok: boolean; data?: UserActivityData; message?: string }
        if (!response.ok || !result.ok) throw new Error(result.message ?? t("users.activityLoadError"))
        if (!cancelled) setActivityData(result.data ?? null)
      })
      .catch((error) => {
        if (!cancelled) {
          setActivityData(null)
          setActivityError(error instanceof Error ? error.message : t("users.activityLoadError"))
        }
      })
      .finally(() => { if (!cancelled) setIsActivityLoading(false) })
    return () => { cancelled = true }
  }, [activeTab, selectedId, t])

  function resetDetail() {
    setMessage(null)
    setSecurityPassword("")
    setSecurityConfirmPassword("")
    setSecurityMessage(null)
    setActivityData(null)
    setActivityError(null)
    setIsActivityLoading(false)
    setActiveTab("general")
  }

  function selectUser(user: SecurityManagerData["users"][number]) {
    confirmAction(() => {
      setIsCreating(false)
      setIsEditing(false)
      setDirty(false)
      setSelectedId(user.id)
      setForm(toForm(user))
      resetDetail()
    })
    return
  }

  function openNew() {
    confirmAction(() => {
      setIsCreating(true)
      setIsEditing(true)
      setDirty(true)
      setSelectedId(null)
      setForm({ ...emptyForm, companyId: data.lookups.companies[0] ? String(data.lookups.companies[0].id) : "" })
      resetDetail()
    })
    return
  }

  function cancelEdit() {
    confirmAction(() => {
      if (isCreating) {
        setIsCreating(false)
        setIsEditing(false)
        setSelectedId(null)
        setForm(emptyForm)
      } else {
        const current = data.users.find(u => u.id === selectedId)
        if (current) setForm(toForm(current))
        setIsEditing(false)
      }
      setDirty(false)
      setMessage(null)
    })
  }

  function safeDate(value: string) {
    if (!value) return "-"
    const date = new Date(value)
    if (Number.isNaN(date.getTime())) return value
    return formatDateTime(date)
  }

  function submit(
    method: "POST" | "PUT" | "DELETE",
    payload?: Record<string, unknown>,
    options?: { title?: string; description?: string; onSuccess?: () => void },
  ) {
    setMessage(null)
    setSecurityMessage(null)
    startTransition(async () => {
      const response = await fetch(apiUrl("/api/admin/users"), {
        method,
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: payload ? JSON.stringify(payload) : undefined,
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        const error = result.message ?? t("users.operationFailed")
        setMessage(error)
        setSecurityMessage(error)
        toast.error(t("common.saveError"), { description: error })
        return
      }
      toast.success(options?.title ?? t("common.savedChanges"), { description: options?.description })
      options?.onSuccess?.()
      router.refresh()
    })
  }

  function saveSecurity() {
    if (!form.id) return
    const password = securityPassword.trim()
    const confirm = securityConfirmPassword.trim()
    if ((password || confirm) && password.length < 6) { setSecurityMessage(t("users.passwordMin")); return }
    if ((password || confirm) && password !== confirm) { setSecurityMessage(t("users.passwordMismatch")); return }
    submit("PUT", {
      id: form.id, names: form.names, surnames: form.surnames, userName: form.userName,
      userType: form.userType,
      roleId: form.roleId, startScreenId: form.startScreenId || null, email: form.email,
      companyId: form.companyId || null, divisionId: form.divisionId || null, branchId: form.branchId || null,
      emissionPointId: form.emissionPointId || null, dataAccessLevel: form.dataAccessLevel,
      locked: form.locked, active: form.active, mustChangePassword: form.mustChangePassword,
      canDeletePosLines: form.canDeletePosLines,
      canChangePosDate: form.canChangePosDate,
      passwordHash: password || null,
    }, { title: t("users.securityUpdated"), description: t("users.securityUpdatedDesc"), onSuccess: () => { setIsEditing(false); setDirty(false) } })
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!form.names.trim() || !form.surnames.trim() || !form.userName.trim() || !form.roleId) {
      const error = t("users.requiredFields")
      setMessage(error)
      toast.error(t("common.saveError"), { description: error })
      return
    }
    if (!form.id && !form.passwordHash.trim()) {
      const error = t("users.definePasswordForNew")
      setMessage(error)
      toast.error(t("common.saveError"), { description: error })
      return
    }

    submit(form.id ? "PUT" : "POST", { ...form, id: form.id }, {
      title: form.id ? t("users.userUpdated") : t("users.userCreated"),
      description: form.id ? t("users.userUpdatedDesc") : t("users.userCreatedDesc"),
      onSuccess: () => { setIsEditing(false); setIsCreating(false); setDirty(false) },
    })
  }

  function getStatus(active: boolean, locked: boolean) {
    if (locked) return { label: t("users.locked"), cls: "price-lists-badge is-warning" }
    if (active) return { label: t("common.active"), cls: "price-lists-badge is-active" }
    return { label: t("common.inactive"), cls: "price-lists-badge is-inactive" }
  }

  function updateAccountStatus(user: SecurityManagerData["users"][number]) {
    if (currentUserId && user.id === currentUserId) {
      toast.error(t("common.saveError"), { description: "No puedes bloquear o desactivar tu propia cuenta desde esta pantalla." })
      setMenuId(null)
      return
    }
    const next = user.locked
      ? { active: user.active, locked: false, title: t("users.accountUnlocked") }
      : user.active
        ? { active: user.active, locked: true, title: t("users.accountBlocked") }
        : { active: true, locked: false, title: t("users.accountActivated") }
    submit("PUT", {
      id: user.id, names: user.names, surnames: user.surnames, userName: user.userName,
      userType: user.userType,
      roleId: user.roleId, startScreenId: user.startScreenId ?? null, email: user.email,
      companyId: user.companyId ?? null, divisionId: user.divisionId ?? null, branchId: user.branchId ?? null,
      emissionPointId: user.emissionPointId ?? null, dataAccessLevel: user.dataAccessLevel,
      passwordHash: user.passwordHash, mustChangePassword: user.mustChangePassword,
      canDeletePosLines: user.canDeletePosLines,
      canChangePosDate: user.canChangePosDate,
      locked: next.locked, active: next.active,
    }, { title: next.title, description: t("users.accountStatusUpdated") })
    setMenuId(null)
  }

  function openDeleteConfirmation(user: SecurityManagerData["users"][number]) {
    if (currentUserId && user.id === currentUserId) {
      toast.error(t("common.saveError"), { description: "No puedes eliminar tu propia cuenta." })
      setMenuId(null)
      return
    }
    setDeleteTarget(user)
    setMenuId(null)
  }

  function updateForm<K extends keyof UserForm>(key: K, value: UserForm[K]) {
    setForm((current) => {
      const next = { ...current, [key]: value }
      if (key === "divisionId") {
        next.branchId = ""
        next.emissionPointId = ""
      }
      if (key === "branchId") {
        next.emissionPointId = ""
      }
      return next
    })
    if (isEditing) setDirty(true)
  }

  const dataAccessOptions = [
    { id: "G", name: "Global" },
    { id: "E", name: "Empresa" },
    { id: "D", name: "Division" },
    { id: "S", name: "Sucursal" },
    { id: "P", name: "Punto de emision" },
    { id: "U", name: "Usuario" },
  ] as const

  return (
    <section className="data-panel">
      <div className="users-layout">

        {/* â”€â”€ Panel izquierdo â”€â”€ */}
        <aside className="users-sidebar">
          <div className="users-sidebar__header">
            <div className="users-sidebar__title">
              <UserRound size={17} />
              <h2>{t("users.managementTitle")}</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title={t("users.newUser")}>
              <Plus size={15} />
            </button>
          </div>

          <div className="users-sidebar__search">
            <Search size={13} className="users-sidebar__search-icon" />
            <input
              type="text"
              placeholder={t("users.searchUsers")}
              value={query}
              onChange={e => setQuery(e.target.value)}
            />
          </div>

          <ul className="users-sidebar__list">
            {filtered.map(user => {
              const status = getStatus(user.active, user.locked)
              return (
                <li
                  key={user.id}
                  className={`users-sidebar__item${selectedId === user.id ? " is-selected" : ""}`}
                  onClick={() => selectUser(user)}
                >
                  <div className="price-lists-sidebar__item-top">
                    <span className={status.cls}>{status.label}</span>
                    <div className="users-sidebar__menu-wrap">
                      <button
                        className="price-lists-sidebar__menu-btn"
                        type="button"
                        onClick={e => { e.stopPropagation(); setMenuId(menuId === user.id ? null : user.id) }}
                      >
                        <MoreHorizontal size={14} />
                      </button>
                      {menuId === user.id && (
                        <ul className="price-lists-dropdown" ref={menuRef} onClick={e => e.stopPropagation()}>
                          <li><button type="button" onClick={() => { selectUser(user); setIsEditing(true); setDirty(true) }}><Pencil size={13} /> {t("common.edit")}</button></li>
                          <li><button type="button" onClick={() => { selectUser(user); setActiveTab("security"); setIsEditing(true); setDirty(true) }}><KeyRound size={13} /> {t("users.changePassword")}</button></li>
                          <li><button type="button" onClick={() => updateAccountStatus(user)}><Lock size={13} /> {user.locked ? t("users.unlockAccount") : user.active ? t("users.blockAccount") : t("users.activateAccount")}</button></li>
                          <li className="is-danger"><button type="button" onClick={() => openDeleteConfirmation(user)}><Trash2 size={13} /> {t("common.delete")}</button></li>
                        </ul>
                      )}
                    </div>
                  </div>
                  <p className="users-sidebar__name">{`${user.names} ${user.surnames}`.trim()}</p>
                  <p className="users-sidebar__meta">@{user.userName} · {user.roleName}</p>
                </li>
              )
            })}
          </ul>
        </aside>

        {/* â”€â”€ Panel derecho â”€â”€ */}
        {(selected || isCreating) ? (
          <section className="users-detail">
            {/* Header */}
            <div className="users-detail__header">
              <div className="users-detail__identity">
                {!isCreating && (
                  <div className="users-detail__avatar">
                    {initials(form.names, form.surnames)}
                  </div>
                )}
                <div>
                  <h2 className="users-detail__name">
                    {isCreating ? t("users.newUser") : `${form.names} ${form.surnames}`.trim()}
                  </h2>
                  {!isCreating && <p className="users-detail__sub"><Mail size={13} /> {form.email || t("users.noEmail")}</p>}
                </div>
              </div>
              <div className="users-detail__actions">
                {isEditing ? (
                  <>
                    <button type="button" className="ghost-button" onClick={cancelEdit} disabled={isPending}>
                      <X size={15} /> {t("common.cancel")}
                    </button>
                    <button type="button" className="primary-button" onClick={e => { if (activeTab === "security") saveSecurity(); else void onSubmit(e as unknown as FormEvent<HTMLFormElement>) }} disabled={isPending}>
                      {isPending ? <Loader2 size={15} className="spin" /> : <Save size={15} />} {t("common.save")}
                    </button>
                  </>
                ) : (
                  <button type="button" className="primary-button" onClick={() => { setIsEditing(true); setDirty(true) }}>
                    <Pencil size={15} /> {t("users.editUser")}
                  </button>
                )}
              </div>
            </div>

            {/* Tabs (solo para usuario existente) */}
            {!isCreating && (
              <div className="users-detail__tabs">
                <button type="button" className={activeTab === "general" ? "users-tab is-active" : "users-tab"} onClick={() => setActiveTab("general")}>
                  <UserRound size={13} /> {t("users.generalInfo")}
                </button>
                <button type="button" className={activeTab === "administrative" ? "users-tab is-active" : "users-tab"} onClick={() => setActiveTab("administrative")}>
                  <Building2 size={13} /> Datos Administrativos
                </button>
                <button type="button" className={activeTab === "security" ? "users-tab is-active" : "users-tab"} onClick={() => setActiveTab("security")}>
                  <Shield size={13} /> {t("nav.security")}
                </button>
                <button type="button" className={activeTab === "activity" ? "users-tab is-active" : "users-tab"} onClick={() => setActiveTab("activity")}>
                  <Clock3 size={13} /> {t("users.activity")}
                </button>
              </div>
            )}

            {/* Tab General / Form Nuevo */}
            {(isCreating || activeTab === "general") && (
              <form className="users-detail__body form-grid form-grid--spaced" onSubmit={onSubmit}>
                <label><span>{t("users.firstNames")} *</span><input value={form.names} onChange={e => updateForm("names", e.target.value)} disabled={!isEditing} required /></label>
                <label><span>{t("users.lastNames")} *</span><input value={form.surnames} onChange={e => updateForm("surnames", e.target.value)} disabled={!isEditing} required /></label>
                <label><span>{t("security.emailAddress")}</span><input value={form.email} onChange={e => updateForm("email", e.target.value)} disabled={!isEditing} /></label>
                <label><span>{t("login.username")} *</span><input value={form.userName} onChange={e => updateForm("userName", e.target.value)} disabled={!isEditing} required /></label>
                <label>
                  <span>Tipo de usuario *</span>
                  <select value={form.userType} onChange={e => updateForm("userType", e.target.value as "A" | "S" | "O")} disabled={!isEditing} required>
                    <option value="A">Administrador</option>
                    <option value="S">Supervisor</option>
                    <option value="O">Operativo</option>
                  </select>
                </label>
                <label>
                  <span>{t("security.role")} *</span>
                  <select value={form.roleId} onChange={e => updateForm("roleId", e.target.value)} disabled={!isEditing} required>
                    <option value="">{t("users.selectOption")}</option>
                    {data.lookups.roles.map(role => <option key={role.id} value={role.id}>{role.name}</option>)}
                  </select>
                </label>
                <label>
                  <span>{t("users.startScreen")}</span>
                  <select value={form.startScreenId} onChange={e => updateForm("startScreenId", e.target.value)} disabled={!isEditing}>
                    <option value="">{t("users.notDefined")}</option>
                    {data.lookups.screens.map(screen => <option key={screen.id} value={screen.id}>{screen.name}</option>)}
                  </select>
                </label>
                {isCreating && (
                  <label className="form-grid__full">
                    <span>{t("login.password")} *</span>
                    <input type="password" value={form.passwordHash} onChange={e => updateForm("passwordHash", e.target.value)} placeholder={t("users.enterPassword")} autoComplete="new-password" />
                  </label>
                )}
                {isEditing && (
                  <>
                    <label className="users-active-toggle form-grid__full">
                      <div><span>{t("common.active")}</span><small>{t("users.enableAccess")}</small></div>
                      <button className={form.active ? "toggle-switch is-on" : "toggle-switch"} type="button" onClick={() => updateForm("active", !form.active)}>
                        <span />
                      </button>
                    </label>
                    {isCreating && (
                      <label className="users-active-toggle form-grid__full">
                        <div><span>{t("users.forcePasswordChange")}</span><small>{t("users.forcePasswordChangeDesc")}</small></div>
                        <button className={form.mustChangePassword ? "toggle-switch is-on" : "toggle-switch"} type="button" onClick={() => updateForm("mustChangePassword", !form.mustChangePassword)}>
                          <span />
                        </button>
                      </label>
                    )}
                  </>
                )}
              </form>
            )}

            {!isCreating && activeTab === "administrative" && (
              <section className="users-detail__body form-grid form-grid--spaced">
                <label>
                  <span>Empresa</span>
                  <select value={form.companyId} onChange={e => updateForm("companyId", e.target.value)} disabled={!isEditing}>
                    <option value="">Selecciona una empresa</option>
                    {data.lookups.companies.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}
                  </select>
                </label>
                <label>
                  <span>Division</span>
                  <select value={form.divisionId} onChange={e => updateForm("divisionId", e.target.value)} disabled={!isEditing}>
                    <option value="">Selecciona una division</option>
                    {data.lookups.divisions.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}
                  </select>
                </label>
                <label>
                  <span>Sucursal</span>
                  <select value={form.branchId} onChange={e => updateForm("branchId", e.target.value)} disabled={!isEditing}>
                    <option value="">Selecciona una sucursal</option>
                    {filteredBranches.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}
                  </select>
                </label>
                <label>
                  <span>Punto de emision</span>
                  <select value={form.emissionPointId} onChange={e => updateForm("emissionPointId", e.target.value)} disabled={!isEditing}>
                    <option value="">Selecciona un punto de emision</option>
                    {filteredEmissionPoints.map(item => <option key={item.id} value={item.id}>{item.name}</option>)}
                  </select>
                </label>
                <label className="form-grid__full">
                  <span>Nivel de acceso a datos</span>
                  <div className="users-access-levels">
                    {dataAccessOptions.map(option => (
                      <button
                        key={option.id}
                        type="button"
                        className={form.dataAccessLevel === option.id ? "filter-pill is-active" : "filter-pill"}
                        onClick={() => isEditing && updateForm("dataAccessLevel", option.id)}
                        disabled={!isEditing}
                      >
                        {option.name}
                      </button>
                    ))}
                  </div>
                </label>
                <article className="users-admin-summary form-grid__full">
                  <div className="users-admin-summary__item">
                    <Building2 size={14} />
                    <div>
                      <strong>Empresa</strong>
                      <span>{data.lookups.companies.find((item) => String(item.id) === form.companyId)?.name || "Sin definir"}</span>
                    </div>
                  </div>
                  <div className="users-admin-summary__item">
                    <GitBranch size={14} />
                    <div>
                      <strong>Estructura</strong>
                      <span>{[
                        data.lookups.divisions.find((item) => String(item.id) === form.divisionId)?.name,
                        data.lookups.branches.find((item) => String(item.id) === form.branchId)?.name,
                        data.lookups.emissionPoints.find((item) => String(item.id) === form.emissionPointId)?.name,
                      ].filter(Boolean).join(" - ") || "Sin definir"}</span>
                    </div>
                  </div>
                  <div className="users-admin-summary__item">
                    <MapPinned size={14} />
                    <div>
                      <strong>Nivel de acceso</strong>
                      <span>{dataAccessOptions.find((item) => item.id === form.dataAccessLevel)?.name || "Global"}</span>
                    </div>
                  </div>
                </article>
              </section>
            )}

            {/* Tab Seguridad */}
            {!isCreating && activeTab === "security" && (
              <section className="users-detail__body users-security-pane">
                <article className="users-security-card">
                  <h4>{t("users.passwordTitle")}</h4>
                  <p>{t("users.passwordSubtitle")}</p>
                  <div className="form-grid form-grid--spaced users-security-form">
                    <label className="form-grid__full">
                      <span>{t("users.newPassword")}</span>
                      <input type="password" value={securityPassword} onChange={e => setSecurityPassword(e.target.value)} autoComplete="new-password" placeholder={t("users.newPasswordPlaceholder")} disabled={!isEditing} />
                    </label>
                    <label className="form-grid__full">
                      <span>{t("users.confirmPassword")}</span>
                      <input type="password" value={securityConfirmPassword} onChange={e => setSecurityConfirmPassword(e.target.value)} autoComplete="new-password" placeholder={t("users.confirmPasswordPlaceholder")} disabled={!isEditing} />
                    </label>
                    <label className="users-active-toggle form-grid__full">
                      <div><span>{t("users.forcePasswordChange")}</span><small>{t("users.forcePasswordChangeDesc")}</small></div>
                      <button className={form.mustChangePassword ? "toggle-switch is-on" : "toggle-switch"} type="button" onClick={() => isEditing && updateForm("mustChangePassword", !form.mustChangePassword)} disabled={!isEditing}>
                        <span />
                      </button>
                    </label>
                    <label className="users-active-toggle form-grid__full">
                      <div>
                        <span>Puede eliminar lineas en POS</span>
                        <small>Permite quitar lineas del documento sin autorizacion de supervisor.</small>
                      </div>
                      <button className={form.canDeletePosLines ? "toggle-switch is-on" : "toggle-switch"} type="button" onClick={() => isEditing && updateForm("canDeletePosLines", !form.canDeletePosLines)} disabled={!isEditing}>
                        <span />
                      </button>
                    </label>
                    <label className="users-active-toggle form-grid__full">
                      <div>
                        <span>Puede cambiar fecha en POS</span>
                        <small>Permite modificar la fecha del documento desde el punto de ventas.</small>
                      </div>
                      <button className={form.canChangePosDate ? "toggle-switch is-on" : "toggle-switch"} type="button" onClick={() => isEditing && updateForm("canChangePosDate", !form.canChangePosDate)} disabled={!isEditing}>
                        <span />
                      </button>
                    </label>
                  </div>
                </article>
                {securityMessage && <p className="form-message">{securityMessage}</p>}
              </section>
            )}

            {/* Tab Actividad */}
            {!isCreating && activeTab === "activity" && (
              <section className="users-detail__body users-activity-pane">
                <div className="users-audit-grid">
                  <article className="users-audit-card">
                    <span><CalendarDays size={14} /> {t("users.createdAt")}</span>
                    <strong>{safeDate(activityData?.summary.accountCreatedAt || form.createdAt)}</strong>
                  </article>
                  <article className="users-audit-card">
                    <span><Clock3 size={14} /> {t("security.lastAccess")}</span>
                    <strong>{safeDate(activityData?.summary.lastLogin || "")}</strong>
                  </article>
                </div>
                <article className="users-audit-table">
                  <h4>{t("users.recentActivity")}</h4>
                  {isActivityLoading && <div><span>{t("users.loadingActivity")}</span><strong>-</strong></div>}
                  {!isActivityLoading && activityError && (
                    <div><span>{activityError}</span><strong>-</strong></div>
                  )}
                  {!isActivityLoading && activityData?.sessions.map(item => (
                    <div key={item.id}>
                      <span>{`${item.channel || "WEB"} · ${item.ipAddress || t("users.ipUnavailable")}`}</span>
                      <strong>{`${safeDate(item.startedAt)} (${item.durationMinutes} min)`}</strong>
                    </div>
                  ))}
                  {!isActivityLoading && !activityError && !activityData?.sessions.length && (
                    <div><span>{t("users.accountCreated")}</span><strong>{safeDate(form.createdAt)}</strong></div>
                  )}
                </article>
              </section>
            )}
          </section>
        ) : (
          <section className="users-detail users-detail--empty">
            <UserRound size={44} />
            <p>Selecciona un usuario o crea uno nuevo</p>
          </section>
        )}
      </div>
      {deleteTarget ? (
        <div className="modal-backdrop" onClick={() => setDeleteTarget(null)}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <Trash2 size={18} />
              </div>
              <div>
                <h3 className="modal-card__title">{t("common.delete")}</h3>
                <p className="modal-card__subtitle">Usuario</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>{`Se eliminara el usuario ${deleteTarget.names} ${deleteTarget.surnames}. Esta accion no se puede deshacer.`}</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setDeleteTarget(null)}>
                {t("common.cancel")}
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={() => {
                  submit("DELETE", { id: deleteTarget.id }, {
                    title: t("users.userDeleted"),
                    description: t("users.userDeletedDesc"),
                    onSuccess: () => setDeleteTarget(null),
                  })
                }}
              >
                {t("common.delete")}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  )
}

