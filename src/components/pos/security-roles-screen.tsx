"use client"

import { type FormEvent, useEffect, useMemo, useState } from "react"
import {
  Armchair,
  ArrowDownUp,
  BarChart3,
  Boxes,
  ChevronDown,
  ChevronRight,
  Copy,
  Download,
  Eye,
  EyeOff,
  Filter,
  Grid3x3,
  Hash,
  HandCoins,
  Key,
  LayoutGrid,
  Loader2,
  Monitor,
  MoreHorizontal,
  Package,
  Pencil,
  Plus,
  Save,
  Search,
  Receipt,
  Settings,
  Shield,
  ShoppingCart,
  Trash2,
  UserMinus,
  UserPlus,
  Users,
  type LucideIcon,
} from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import type {
  RoleFieldVisibilityKey,
  RolePermissionsPayload,
  RoleScreenPermissionSnapshot,
  SecurityManagerData,
} from "@/lib/pos-data"

type ModuleFilter = "all" | "enabled" | "disabled"
type MainTab = "modules" | "screens" | "visibility" | "users"
type GranularPermissionKey = "canCreate" | "canEdit" | "canDelete" | "canApprove" | "canView" | "canCancel" | "canPrint"

type RoleForm = {
  id?: number
  name: string
  description: string
  active: boolean
}

const emptyRoleForm: RoleForm = {
  name: "",
  description: "",
  active: true,
}

const roleColors = ["var(--brand)", "#10b981", "#3b82f6", "#8b5cf6", "#f97316", "#ec4899"]

const moduleIconMap: Record<string, LucideIcon> = {
  Armchair,
  Boxes,
  HandCoins,
  Receipt,
  LayoutGrid,
  Grid3x3,
  Shield,
  ShoppingCart,
  Monitor,
  Package,
  BarChart3,
  Settings,
}

const moduleNameIconFallback: Record<string, LucideIcon> = {
  dashboard: LayoutGrid,
  ordenes: ShoppingCart,
  "punto de venta": Monitor,
  pos: Monitor,
  menu: Package,
  catalogo: Package,
  "menu/catalogo": Package,
  reportes: BarChart3,
  configuracion: Settings,
  seguridad: Shield,
  salon: Armchair,
  inventario: Boxes,
  "cuentas por cobrar": HandCoins,
  "cuentas por pagar": Receipt,
}

function isSystemRole(role: SecurityManagerData["roles"][number] | null) {
  if (!role) return false
  const normalized = role.name.trim().toLowerCase()
  return role.id === 1 || normalized === "admin" || normalized === "administrador" || normalized === "administrador general"
}

function roleColor(index: number) {
  return roleColors[index % roleColors.length]
}

function resolveModuleIcon(moduleName: string, iconKey: string) {
  const direct = moduleIconMap[iconKey]
  if (direct) return direct

  const normalizedKey = iconKey.trim().toLowerCase()
  if (normalizedKey.startsWith("fa-shield")) return Shield
  if (normalizedKey.startsWith("fa-shopping-cart")) return ShoppingCart
  if (normalizedKey.startsWith("fa-chart")) return BarChart3
  if (normalizedKey.startsWith("fa-cog") || normalizedKey.startsWith("fa-gear")) return Settings

  const fallback = moduleNameIconFallback[moduleName.trim().toLowerCase()]
  return fallback ?? LayoutGrid
}

function buildUserRoleMap(users: SecurityManagerData["users"]) {
  const next: Record<number, number> = {}
  for (const user of users) {
    next[user.id] = user.roleId
  }
  return next
}

export function SecurityRolesScreen({ data }: { data: SecurityManagerData }) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()

  const [query, setQuery] = useState("")
  const [mainTab, setMainTab] = useState<MainTab>("modules")
  const [usersSubTab, setUsersSubTab] = useState<"assigned" | "available">("assigned")
  const [moduleFilter, setModuleFilter] = useState<ModuleFilter>("all")
  const [selectedRoleId, setSelectedRoleId] = useState<number | null>(data.roles[0]?.id ?? null)
  const [expandedModules, setExpandedModules] = useState<Record<number, boolean>>({})
  const [isEditing, setIsEditing] = useState(false)
  const [isBusy, setIsBusy] = useState(false)
  const [permissionsLoading, setPermissionsLoading] = useState(false)
  const [permissions, setPermissions] = useState<RolePermissionsPayload | null>(null)
  const [actionMenuOpen, setActionMenuOpen] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteModalOpen, setDeleteModalOpen] = useState(false)

  const [userRoleMap, setUserRoleMap] = useState<Record<number, number>>(() => buildUserRoleMap(data.users))

  const [createOpen, setCreateOpen] = useState(false)
  const [createForm, setCreateForm] = useState<RoleForm>(emptyRoleForm)

  const [editForm, setEditForm] = useState<RoleForm>(emptyRoleForm)

  useEffect(() => {
    setUserRoleMap(buildUserRoleMap(data.users))
  }, [data.users])

  useEffect(() => {
    setDirty(isEditing || createOpen)
    return () => setDirty(false)
  }, [createOpen, isEditing, setDirty])

  const filteredRoles = useMemo(() => {
    const normalized = query.trim().toLowerCase()
    if (!normalized) return data.roles
    return data.roles.filter((role) => `${role.name} ${role.description}`.toLowerCase().includes(normalized))
  }, [data.roles, query])

  useEffect(() => {
    if (!data.roles.length) {
      setSelectedRoleId(null)
      return
    }
    if (!selectedRoleId || !data.roles.some((role) => role.id === selectedRoleId)) {
      setSelectedRoleId(data.roles[0].id)
    }
  }, [data.roles, selectedRoleId])

  const selectedRole = useMemo(() => data.roles.find((role) => role.id === selectedRoleId) ?? null, [data.roles, selectedRoleId])

  useEffect(() => {
    if (!selectedRole) {
      setEditForm(emptyRoleForm)
      setIsEditing(false)
      return
    }
    setEditForm({
      id: selectedRole.id,
      name: selectedRole.name,
      description: selectedRole.description,
      active: selectedRole.active,
    })
    setIsEditing(false)
  }, [selectedRole])

  useEffect(() => {
    async function loadPermissions(roleId: number) {
      setPermissionsLoading(true)
      setMessage(null)
      try {
        const response = await fetch(apiUrl(`/api/roles/${roleId}/permissions`), {
          credentials: "include",
        })
        const result = (await response.json()) as RolePermissionsPayload & { ok: boolean; message?: string }
        if (!response.ok || !result.ok) {
          setPermissions(null)
          setMessage(result.message ?? t("roles.permissionsLoadError"))
          return
        }

        const modulesExpanded: Record<number, boolean> = {}
        for (const moduleItem of result.modules) {
          modulesExpanded[moduleItem.id] = true
        }
        setExpandedModules(modulesExpanded)
        setPermissions({
          modules: result.modules,
          screens: result.screens,
          fieldVisibility: result.fieldVisibility,
        })
      } catch {
        setPermissions(null)
        setMessage(t("roles.permissionsLoadError"))
      } finally {
        setPermissionsLoading(false)
      }
    }

    if (selectedRoleId) {
      setActionMenuOpen(false)
      void loadPermissions(selectedRoleId)
    }
  }, [selectedRoleId, t])

  useEffect(() => {
    function onPointerDown(event: MouseEvent) {
      const target = event.target as HTMLElement | null
      if (!target) return
      if (target.closest(".roles-header__actions")) return
      setActionMenuOpen(false)
    }

    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  const userCountByRole = useMemo(() => {
    const map = new Map<number, number>()
    for (const user of data.users) {
      const roleId = userRoleMap[user.id] ?? user.roleId
      map.set(roleId, (map.get(roleId) ?? 0) + 1)
    }
    return map
  }, [data.users, userRoleMap])

  const moduleCountByRole = useMemo(() => {
    const count = new Map<number, number>()
    for (const role of data.roles) {
      count.set(role.id, 0)
    }
    if (!permissions || !selectedRole) return count
    count.set(selectedRole.id, permissions.modules.filter((item) => item.enabled).length)
    return count
  }, [data.roles, permissions, selectedRole])

  const assignedUsers = useMemo(() => {
    if (!selectedRole) return []
    return data.users.filter((user) => (userRoleMap[user.id] ?? user.roleId) === selectedRole.id)
  }, [data.users, selectedRole, userRoleMap])

  const availableUsers = useMemo(() => {
    if (!selectedRole) return []
    return data.users.filter((user) => (userRoleMap[user.id] ?? user.roleId) !== selectedRole.id)
  }, [data.users, selectedRole, userRoleMap])

  const screensByModule = useMemo(() => {
    const map = new Map<number, RoleScreenPermissionSnapshot[]>()
    if (!permissions) return map
    for (const screen of permissions.screens) {
      const list = map.get(screen.moduleId) ?? []
      list.push(screen)
      map.set(screen.moduleId, list)
    }
    return map
  }, [permissions])

  const filteredModules = useMemo(() => {
    if (!permissions) return []
    if (moduleFilter === "enabled") return permissions.modules.filter((moduleItem) => moduleItem.enabled)
    if (moduleFilter === "disabled") return permissions.modules.filter((moduleItem) => !moduleItem.enabled)
    return permissions.modules
  }, [moduleFilter, permissions])

  async function reloadPermissions() {
    if (!selectedRoleId) return
    setPermissionsLoading(true)
    try {
      const response = await fetch(apiUrl(`/api/roles/${selectedRoleId}/permissions`), {
        credentials: "include",
      })
      const result = (await response.json()) as RolePermissionsPayload & { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        setMessage(result.message ?? t("roles.permissionsLoadError"))
        return
      }
      setPermissions({ modules: result.modules, screens: result.screens, fieldVisibility: result.fieldVisibility })
    } finally {
      setPermissionsLoading(false)
    }
  }

  async function updatePermission(payload: {
    type: "MODULO" | "PANTALLA" | "PERMISO_GRANULAR" | "CAMPO"
    objectId?: number
    fieldKey?: string
    value: boolean
    permissionField?: string
  }, { quiet = false, skipReload = false }: { quiet?: boolean; skipReload?: boolean } = {}) {
    if (!selectedRoleId) return
    setIsBusy(true)
    setMessage(null)
    try {
      const response = await fetch(apiUrl(`/api/roles/${selectedRoleId}/permissions`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        throw new Error(result.message ?? t("roles.operationFailed"))
      }
      if (!skipReload) {
        await reloadPermissions()
      }
      if (!quiet) {
        toast.success(t("common.savedChanges"))
      }
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  async function saveRoleChanges() {
    if (!selectedRole) return
    if (!editForm.name.trim()) {
      setMessage(t("roles.nameRequired"))
      return
    }

    const duplicate = data.roles.some(
      (role) => role.id !== selectedRole.id && role.name.trim().toLowerCase() === editForm.name.trim().toLowerCase(),
    )
    if (duplicate) {
      setMessage(t("roles.duplicateName"))
      return
    }

    setIsBusy(true)
    setMessage(null)
    try {
      const response = await fetch(apiUrl("/api/admin/roles"), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(editForm),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        throw new Error(result.message ?? t("roles.operationFailed"))
      }
      setIsEditing(false)
      setDirty(false)
      toast.success(t("roles.updated"), { description: t("roles.updatedDesc") })
      router.refresh()
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  function cancelRoleEdit() {
    confirmAction(() => {
      if (!selectedRole) {
        setIsEditing(false)
        setDirty(false)
        return
      }
      setEditForm({
        id: selectedRole.id,
        name: selectedRole.name,
        description: selectedRole.description,
        active: selectedRole.active,
      })
      setMessage(null)
      setIsEditing(false)
      setDirty(false)
    })
  }

  async function onCreateRole(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!createForm.name.trim()) {
      setMessage(t("roles.nameRequired"))
      return
    }
    const duplicate = data.roles.some((role) => role.name.trim().toLowerCase() === createForm.name.trim().toLowerCase())
    if (duplicate) {
      setMessage(t("roles.duplicateName"))
      return
    }

    setIsBusy(true)
    setMessage(null)
    try {
      const response = await fetch(apiUrl("/api/admin/roles"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(createForm),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        throw new Error(result.message ?? t("roles.operationFailed"))
      }

      setCreateOpen(false)
      setCreateForm(emptyRoleForm)
      setDirty(false)
      toast.success(t("roles.created"), { description: t("roles.createdDesc") })
      router.refresh()
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  async function removeSelectedRole() {
    if (!selectedRole || isSystemRole(selectedRole)) return
    if ((userCountByRole.get(selectedRole.id) ?? 0) > 0) {
      toast.error(t("roles.cannotDeleteWithUsers"))
      return
    }

    setIsBusy(true)
    setActionMenuOpen(false)
    try {
      const response = await fetch(apiUrl("/api/admin/roles"), {
        method: "DELETE",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: selectedRole.id }),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        throw new Error(result.message ?? t("roles.operationFailed"))
      }

      toast.success(t("roles.deleted"), { description: t("roles.deletedDesc") })
      setSelectedRoleId(null)
      router.refresh()
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  async function runBulkRequests(requests: Array<Promise<Response>>) {
    const responses = await Promise.all(requests)
    for (const response of responses) {
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        throw new Error(result.message ?? t("roles.operationFailed"))
      }
    }
  }

  async function updateUserAssignment(userId: number, action: "A" | "Q") {
    if (!selectedRole) return
    setIsBusy(true)
    setMessage(null)
    try {
      const response = await fetch(apiUrl(`/api/roles/${selectedRole.id}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId, action }),
      })
      const raw = await response.text()
      let result: { ok: boolean; message?: string }
      try {
        result = raw ? (JSON.parse(raw) as { ok: boolean; message?: string }) : { ok: response.ok }
      } catch {
        result = { ok: false, message: raw || `HTTP ${response.status}` }
      }
      if (!response.ok || !result.ok) {
        throw new Error(result.message ?? t("roles.operationFailed"))
      }

      setUserRoleMap((current) => ({
        ...current,
        [userId]: action === "A" ? selectedRole.id : 0,
      }))
      toast.success(action === "A" ? t("roles.userAssigned") : t("roles.userUnassigned"))
      router.refresh()
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  async function bulkModuleChange(value: boolean) {
    if (!permissions || !isEditing) return
    setIsBusy(true)
    try {
      await runBulkRequests(
        permissions.modules.map((moduleItem) =>
          fetch(apiUrl(`/api/roles/${selectedRoleId}/permissions`), {
            method: "PUT",
            credentials: "include",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ type: "MODULO", objectId: moduleItem.id, value }),
          }),
        ),
      )
      await reloadPermissions()
      toast.success(t("common.savedChanges"))
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  async function bulkFieldChange(value: boolean) {
    if (!isEditing) return
    const keys: RoleFieldVisibilityKey[] = [
      "id_registros",
      "precios",
      "costos",
      "cantidades",
      "descuentos",
      "impuestos",
      "subtotales",
      "totales_netos",
      "margenes",
      "comisiones",
      "info_cliente",
      "metodos_pago",
    ]
    setIsBusy(true)
    try {
      await runBulkRequests(
        keys.map((fieldKey) =>
          fetch(apiUrl(`/api/roles/${selectedRoleId}/permissions`), {
            method: "PUT",
            credentials: "include",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ type: "CAMPO", fieldKey, value }),
          }),
        ),
      )
      await reloadPermissions()
      toast.success(t("common.savedChanges"))
    } catch (error) {
      const text = error instanceof Error ? error.message : t("roles.operationFailed")
      setMessage(text)
      toast.error(t("common.saveError"), { description: text })
    } finally {
      setIsBusy(false)
    }
  }

  const selectedRoleIndex = selectedRole ? data.roles.findIndex((role) => role.id === selectedRole.id) : 0
  const safeRoleIndex = selectedRoleIndex >= 0 ? selectedRoleIndex : 0

  const granularItems: Array<{ key: GranularPermissionKey; label: string; icon: LucideIcon }> = [
    { key: "canCreate", label: t("roles.permCreate"), icon: Plus },
    { key: "canEdit", label: t("roles.permEdit"), icon: Pencil },
    { key: "canDelete", label: t("roles.permDelete"), icon: Trash2 },
    { key: "canApprove", label: t("roles.permCopy"), icon: Copy },
    { key: "canView", label: t("roles.permFilter"), icon: Filter },
    { key: "canCancel", label: t("roles.permSort"), icon: ArrowDownUp },
    { key: "canPrint", label: t("roles.permExport"), icon: Download },
  ]

  const fieldItems: Array<{ key: RoleFieldVisibilityKey; label: string; icon: LucideIcon }> = [
    { key: "id_registros", label: t("roles.field.id_registros"), icon: Hash },
    { key: "precios", label: t("roles.field.precios"), icon: Key },
    { key: "costos", label: t("roles.field.costos"), icon: Key },
    { key: "cantidades", label: t("roles.field.cantidades"), icon: Key },
    { key: "descuentos", label: t("roles.field.descuentos"), icon: Key },
    { key: "impuestos", label: t("roles.field.impuestos"), icon: Key },
    { key: "subtotales", label: t("roles.field.subtotales"), icon: Key },
    { key: "totales_netos", label: t("roles.field.totales_netos"), icon: Key },
    { key: "margenes", label: t("roles.field.margenes"), icon: Key },
    { key: "comisiones", label: t("roles.field.comisiones"), icon: Key },
    { key: "info_cliente", label: t("roles.field.info_cliente"), icon: Key },
    { key: "metodos_pago", label: t("roles.field.metodos_pago"), icon: Key },
  ]

  const visibleFieldCount = fieldItems.filter((item) => permissions?.fieldVisibility[item.key] ?? false).length
  const hiddenFieldCount = fieldItems.length - visibleFieldCount

  return (
    <>
      <section className="roles-layout">
        <aside className="roles-sidebar">
          <div className="roles-sidebar__header">
            <h2>{t("roles.title")}</h2>
            <button
              className="roles-sidebar__add-btn"
              type="button"
              title={t("roles.newRole")}
              onClick={() => confirmAction(() => {
                setCreateOpen(true)
                setCreateForm(emptyRoleForm)
                setMessage(null)
              })}
            >
              <Plus size={16} />
            </button>
          </div>

          <label className="searchbar roles-search">
            <Search size={16} />
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder={t("roles.searchPlaceholder")} />
          </label>

          <div className="roles-sidebar__list">
            {filteredRoles.map((role, index) => (
              <button
                key={role.id}
                type="button"
                className={selectedRoleId === role.id ? "roles-sidebar__item is-selected" : "roles-sidebar__item"}
                onClick={() => confirmAction(() => {
                  setSelectedRoleId(role.id)
                  setIsEditing(false)
                  setMessage(null)
                })}
              >
                <span className="roles-sidebar__icon" style={{ background: roleColor(index) }}>
                  <Shield size={14} />
                </span>
                <span className="roles-sidebar__content">
                  <span className="roles-sidebar__title">
                    {role.name}
                    {isSystemRole(role) ? <span className="chip chip--info">{t("roles.system")}</span> : null}
                  </span>
                  <span className="roles-sidebar__desc">{role.description || t("roles.noDescription")}</span>
                  <span className="roles-sidebar__meta">
                    <Users size={13} /> {userCountByRole.get(role.id) ?? 0}
                    <Key size={13} /> {moduleCountByRole.get(role.id) ?? 0}
                  </span>
                </span>
              </button>
            ))}
          </div>
        </aside>

        <section className="roles-main data-panel">
          {!selectedRole ? (
            <p className="roles-empty">{t("roles.noRoles")}</p>
          ) : (
            <>
              <header className="roles-header">
                <div className="roles-header__top">
                <div className="roles-header__identity">
                  <span className="roles-header__icon" style={{ background: roleColor(safeRoleIndex) }}>
                    <Shield size={20} />
                  </span>
                  <div className="roles-header__info">
                    {isEditing ? (
                      <>
                        <input value={editForm.name} onChange={(event) => setEditForm((current) => ({ ...current, name: event.target.value }))} />
                        <textarea rows={2} value={editForm.description} onChange={(event) => setEditForm((current) => ({ ...current, description: event.target.value }))} />
                      </>
                    ) : (
                      <>
                        <h2>{selectedRole.name}</h2>
                        <p>{selectedRole.description || t("roles.noDescription")}</p>
                      </>
                    )}
                  </div>
                </div>

                <div className="roles-header__actions">
                  {isEditing ? (
                    <>
                      <button className="secondary-button" type="button" onClick={cancelRoleEdit}>
                        {t("common.cancel")}
                      </button>
                      <button className="primary-button" type="button" disabled={isBusy} onClick={() => void saveRoleChanges()}>
                        {isBusy ? <Loader2 size={15} className="spin" /> : <Save size={15} />} {t("config.saveChanges")}
                      </button>
                    </>
                  ) : (
                    <button className="secondary-button" type="button" onClick={() => setIsEditing(true)}>
                      <Pencil size={15} /> {t("roles.editData")}
                    </button>
                  )}

                  <button className="icon-button" type="button" onClick={() => setActionMenuOpen((current) => !current)}>
                    <MoreHorizontal size={16} />
                  </button>

                  {actionMenuOpen ? (
                    <div className="table-menu roles-header__menu">
                      <button
                        type="button"
                        className={isSystemRole(selectedRole) ? "is-danger is-disabled" : "is-danger"}
                        onClick={() => {
                          if (isSystemRole(selectedRole)) return
                          setDeleteModalOpen(true)
                          setActionMenuOpen(false)
                        }}
                      >
                        <Trash2 size={14} /> {t("common.delete")}
                      </button>
                    </div>
                  ) : null}
                </div>
                </div>

                <div className="roles-header__meta">
                  <span className="chip chip--neutral">#{selectedRole.id}</span>
                  <button
                    type="button"
                    className={editForm.active ? "toggle-switch is-on" : "toggle-switch"}
                    disabled={!isEditing}
                    onClick={() => {
                      if (!isEditing) return
                      setEditForm((current) => ({ ...current, active: !current.active }))
                    }}
                  >
                    <span />
                  </button>
                  <span className={editForm.active ? "chip chip--success" : "chip chip--neutral"}>{editForm.active ? t("common.active") : t("common.inactive")}</span>
                  {isSystemRole(selectedRole) ? <span className="chip chip--info">{t("roles.system")}</span> : null}
                </div>
              </header>

              <div className="roles-main__tabsbar">
                <div className="users-modal__tabs roles-main__tabs">
                  <button type="button" className={mainTab === "modules" ? "users-tab is-active" : "users-tab"} onClick={() => setMainTab("modules")}>{t("config.modules")}</button>
                  <button type="button" className={mainTab === "screens" ? "users-tab is-active" : "users-tab"} onClick={() => setMainTab("screens")}>{t("config.screens")}</button>
                  <button type="button" className={mainTab === "visibility" ? "users-tab is-active" : "users-tab"} onClick={() => setMainTab("visibility")}>{t("roles.visualizationTab")}</button>
                  <button type="button" className={mainTab === "users" ? "users-tab is-active" : "users-tab"} onClick={() => setMainTab("users")}>
                    {t("roles.usersTab")}
                  </button>
                </div>
              </div>
              {mainTab !== "users" ? (
                <div className="roles-filter-pills" role="tablist" aria-label={t("roles.filterAriaLabel")}>
                  <button type="button" className={moduleFilter === "all" ? "roles-filter-pill is-active" : "roles-filter-pill"} onClick={() => setModuleFilter("all")}>{t("roles.filterAll")}</button>
                  <button type="button" className={moduleFilter === "enabled" ? "roles-filter-pill is-active" : "roles-filter-pill"} onClick={() => setModuleFilter("enabled")}>{t("roles.filterEnabled")}</button>
                  <button type="button" className={moduleFilter === "disabled" ? "roles-filter-pill is-active" : "roles-filter-pill"} onClick={() => setModuleFilter("disabled")}>{t("roles.filterDisabled")}</button>
                </div>
              ) : null}

              {permissionsLoading ? <p className="roles-empty">{t("roles.loading")}</p> : null}

              {!permissionsLoading && mainTab === "modules" ? (
                <>
                  <div className="roles-module-grid">
                    {filteredModules.map((moduleItem) => {
                      const ModuleIcon = resolveModuleIcon(moduleItem.name, moduleItem.icon)
                      const screens = screensByModule.get(moduleItem.id) ?? []
                      return (
                        <article key={moduleItem.id} className={moduleItem.enabled ? "roles-module-card is-enabled" : "roles-module-card"}>
                          <header>
                            <span className="roles-module-card__icon"><ModuleIcon size={16} /></span>
                            <div className="roles-module-card__info">
                              <p className="roles-module-card__code">#{moduleItem.id}</p>
                              <h4>{moduleItem.name}</h4>
                              <small className="roles-module-card__count">{screens.length} {t("config.screens")}</small>
                            </div>
                            <div className="roles-module-card__controls">
                              <span className={moduleItem.enabled ? "chip chip--success" : "chip chip--neutral"}>
                                {moduleItem.enabled ? t("roles.enabled") : t("roles.disabled")}
                              </span>
                              <button
                                type="button"
                                className={moduleItem.enabled ? "toggle-switch is-on" : "toggle-switch"}
                                disabled={!isEditing || isBusy}
                                onClick={() => {
                                  if (!isEditing) return
                                  void updatePermission({ type: "MODULO", objectId: moduleItem.id, value: !moduleItem.enabled }, { quiet: true })
                                }}
                              >
                                <span />
                              </button>
                            </div>
                          </header>
                          {moduleItem.enabled ? (
                            <div className="roles-module-card__badges">
                              {screens.map((screen) => (
                                <span key={screen.id} className="chip chip--neutral">{screen.name}</span>
                              ))}
                            </div>
                          ) : null}
                        </article>
                      )
                    })}
                  </div>

                  <div className="roles-module-summary">
                    <p>{(permissions?.modules.filter((moduleItem) => moduleItem.enabled).length ?? 0)} / {permissions?.modules.length ?? 0} {t("roles.modulesEnabled")}</p>
                    {isEditing ? (
                      <div className="roles-main__toolbar-actions">
                        <button className="secondary-button" type="button" disabled={isBusy} onClick={() => void bulkModuleChange(true)}>{t("roles.enableAll")}</button>
                        <button className="secondary-button" type="button" disabled={isBusy} onClick={() => void bulkModuleChange(false)}>{t("roles.disableAll")}</button>
                      </div>
                    ) : null}
                  </div>
                </>
              ) : null}

              {!permissionsLoading && mainTab === "screens" ? (
                <div className="roles-screen-list">
                  {(permissions?.modules ?? []).map((moduleItem) => {
                    const screens = screensByModule.get(moduleItem.id) ?? []
                    const isExpanded = expandedModules[moduleItem.id] ?? true
                    const enabledScreens = screens.filter((screen) => screen.access).length
                    const ModuleIcon = resolveModuleIcon(moduleItem.name, moduleItem.icon)
                    return (
                      <article key={moduleItem.id} className="roles-screen-collapsible">
                        <button
                          type="button"
                          className="roles-screen-collapsible__header"
                          onClick={() => setExpandedModules((current) => ({ ...current, [moduleItem.id]: !isExpanded }))}
                        >
                          <div className="roles-screen-collapsible__main">
                            <span className="roles-screen-collapsible__chevron">{isExpanded ? <ChevronDown size={14} /> : <ChevronRight size={14} />}</span>
                            <span className="roles-screen-collapsible__icon"><ModuleIcon size={15} /></span>
                            <div className="roles-screen-collapsible__title-block">
                              <strong>{moduleItem.name}</strong>
                              <small>{screens.length} {t("config.screens")}</small>
                            </div>
                          </div>
                          <div className="roles-screen-collapsible__meta">
                            <span className={enabledScreens > 0 ? "chip chip--success" : "chip chip--neutral"}>{enabledScreens > 0 ? t("roles.enabled") : t("roles.disabled")}</span>
                          </div>
                        </button>

                        {isExpanded ? (
                          <div className="roles-screen-collapsible__body">
                            {screens.map((screen) => {
                              const activeGranular = granularItems.filter((item) => screen[item.key]).length
                              return (
                                <div key={screen.id} className="roles-screen-card">
                                  <div className="roles-screen-card__header">
                                    <button
                                      type="button"
                                      className={screen.access ? "toggle-switch is-on" : "toggle-switch"}
                                      disabled={!isEditing || isBusy}
                                      onClick={() => {
                                        if (!isEditing) return
                                        void updatePermission({ type: "PANTALLA", objectId: screen.id, value: !screen.access }, { quiet: true })
                                      }}
                                    >
                                      <span />
                                    </button>
                                    <div>
                                      <h5>{screen.name}</h5>
                                      <p>{screen.route}</p>
                                    </div>
                                    <span className="chip chip--neutral">{activeGranular} {t("roles.activePermissions")}</span>
                                  </div>

                                  {screen.access ? (
                                    <div className="roles-perm-grid">
                                      {granularItems.map((permItem) => {
                                        const PermIcon = permItem.icon
                                        return (
                                          <button
                                            key={permItem.key}
                                            type="button"
                                            className={screen[permItem.key] ? "roles-perm-item is-active" : "roles-perm-item"}
                                            disabled={!isEditing || isBusy}
                                            onClick={() => {
                                              if (!isEditing) return
                                              void updatePermission(
                                                {
                                                  type: "PERMISO_GRANULAR",
                                                  objectId: screen.id,
                                                  value: !screen[permItem.key],
                                                  permissionField: permItem.key,
                                                },
                                                { quiet: true },
                                              )
                                            }}
                                          >
                                            <PermIcon size={14} />
                                            <span>{permItem.label}</span>
                                          </button>
                                        )
                                      })}
                                    </div>
                                  ) : null}
                                </div>
                              )
                            })}
                          </div>
                        ) : null}
                      </article>
                    )
                  })}
                </div>
              ) : null}

              {!permissionsLoading && mainTab === "visibility" ? (
                <>
                  <article className="roles-visibility-info">
                    <p>{t("roles.visibilityInfo")}</p>
                    {isEditing ? (
                      <div className="roles-main__toolbar-actions">
                        <button className="secondary-button" type="button" disabled={isBusy} onClick={() => void bulkFieldChange(true)}>{t("roles.showAll")}</button>
                        <button className="secondary-button" type="button" disabled={isBusy} onClick={() => void bulkFieldChange(false)}>{t("roles.hideAll")}</button>
                      </div>
                    ) : null}
                  </article>

                  <div className="roles-field-grid">
                    {fieldItems.map((fieldItem) => {
                      const visible = permissions?.fieldVisibility[fieldItem.key] ?? false
                      const FieldIcon = fieldItem.icon
                      return (
                        <button
                          key={fieldItem.key}
                          type="button"
                          className={visible ? "roles-field-card is-visible" : "roles-field-card is-hidden"}
                          disabled={!isEditing || isBusy}
                          onClick={() => {
                            if (!isEditing) return
                            void updatePermission({ type: "CAMPO", fieldKey: fieldItem.key, value: !visible }, { quiet: true })
                          }}
                        >
                          <span className="roles-field-card__icon">{visible ? <Eye size={15} /> : <EyeOff size={15} />}</span>
                          <div>
                            <p>{fieldItem.label}</p>
                            <small>{visible ? t("roles.visible") : t("roles.hidden")}</small>
                          </div>
                          <div className="roles-field-card__actions">
                            <FieldIcon size={14} />
                            <span className={visible ? "toggle-switch is-on" : "toggle-switch"}>
                              <span />
                            </span>
                          </div>
                        </button>
                      )
                    })}
                  </div>

                  <div className="roles-visibility-summary">
                    <span><i className="is-visible" /> {visibleFieldCount} {t("roles.visible")}</span>
                    <span><i className="is-hidden" /> {hiddenFieldCount} {t("roles.hidden")}</span>
                  </div>
                </>
              ) : null}

              {!permissionsLoading && mainTab === "users" ? (
                <div className="roles-users-tab">
                  <div className="users-modal__tabs roles-users-tab__subtabs">
                    <button type="button" className={usersSubTab === "assigned" ? "users-tab is-active" : "users-tab"} onClick={() => setUsersSubTab("assigned")}>
                      {t("roles.assignedTab")} ({assignedUsers.length})
                    </button>
                    <button type="button" className={usersSubTab === "available" ? "users-tab is-active" : "users-tab"} onClick={() => setUsersSubTab("available")}>
                      {t("roles.availableTab")} ({availableUsers.length})
                    </button>
                  </div>
                  <div className="roles-users-list">
                    {(usersSubTab === "assigned" ? assignedUsers : availableUsers).map((user) => (
                      <article key={user.id} className="roles-user-item">
                        <span className="roles-user-avatar">{`${user.names.charAt(0)}${user.surnames.charAt(0)}`.toUpperCase()}</span>
                        <div>
                          <p>{`${user.names} ${user.surnames}`}</p>
                          <small>@{user.userName}</small>
                        </div>
                        {usersSubTab === "assigned" ? (
                          <button className="icon-button roles-user-action-btn roles-user-action-btn--remove" type="button" disabled={isBusy} onClick={() => void updateUserAssignment(user.id, "Q")}>
                            <UserMinus size={15} />
                          </button>
                        ) : (
                          <button className="icon-button roles-user-action-btn roles-user-action-btn--add" type="button" disabled={isBusy} onClick={() => void updateUserAssignment(user.id, "A")}>
                            <UserPlus size={15} />
                          </button>
                        )}
                      </article>
                    ))}
                    {(usersSubTab === "assigned" ? assignedUsers : availableUsers).length === 0 ? (
                      <p className="roles-empty">{usersSubTab === "assigned" ? t("roles.noAssignedUsers") : t("roles.noAvailableUsers")}</p>
                    ) : null}
                  </div>
                </div>
              ) : null}

              {message ? <p className="form-message">{message}</p> : null}
            </>
          )}
        </section>
      </section>

      {createOpen ? (
        <div className="users-modal-backdrop" onClick={() => confirmAction(() => { setCreateOpen(false); setCreateForm(emptyRoleForm); setDirty(false) })}>
          <section className="roles-modal" onClick={(event) => event.stopPropagation()}>
            <div className="roles-modal__header">
              <h3>{t("roles.newRole")}</h3>
            </div>
            <form className="form-grid form-grid--spaced" onSubmit={(event) => void onCreateRole(event)}>
              <label>
                <span>{t("roles.name")}</span>
                <input value={createForm.name} onChange={(event) => setCreateForm((current) => ({ ...current, name: event.target.value }))} required />
              </label>

              <label className="form-grid__full">
                <span>{t("roles.description")}</span>
                <textarea rows={3} value={createForm.description} onChange={(event) => setCreateForm((current) => ({ ...current, description: event.target.value }))} />
              </label>

              <div className="form-grid__full roles-switch-row">
                <p>{t("roles.activeToggle")}</p>
                <button
                  type="button"
                  className={createForm.active ? "toggle-switch is-on" : "toggle-switch"}
                  onClick={() => setCreateForm((current) => ({ ...current, active: !current.active }))}
                >
                  <span />
                </button>
              </div>

              <div className="form-actions">
                <button className="secondary-button" type="button" onClick={() => confirmAction(() => { setCreateOpen(false); setCreateForm(emptyRoleForm); setDirty(false) })}>{t("common.cancel")}</button>
                <button className="primary-button" type="submit" disabled={isBusy}>
                  {isBusy ? <Loader2 size={15} className="spin" /> : <Plus size={15} />} {t("roles.newRole")}
                </button>
              </div>
            </form>
          </section>
        </div>
      ) : null}
      {deleteModalOpen && selectedRole ? (
        <div className="modal-backdrop" onClick={() => setDeleteModalOpen(false)}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <Trash2 size={18} />
              </div>
              <div>
                <h3 className="modal-card__title">{t("common.delete")}</h3>
                <p className="modal-card__subtitle">Rol</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>{t("roles.deleteConfirm").replace("{role}", selectedRole.name)}</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setDeleteModalOpen(false)}>
                {t("common.cancel")}
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={() => {
                  setDeleteModalOpen(false)
                  void removeSelectedRole()
                }}
              >
                {t("common.delete")}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  )
}
