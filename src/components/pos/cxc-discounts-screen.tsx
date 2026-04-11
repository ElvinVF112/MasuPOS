"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Tag, Trash2, UserCheck, UserMinus, UserPlus, Users, UserX, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { DescuentoRecord, DiscountUser } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

type DiscountTab = "general" | "users"
type UsersSubTab = "assigned" | "available"

type ItemForm = {
  id?: number
  code: string
  name: string
  porcentaje: number
  esGlobal: boolean
  fechaInicio: string
  fechaFin: string
  active: boolean
  permiteManual: boolean
  limiteDescuentoManual: string
}

const emptyForm: ItemForm = {
  code: "",
  name: "",
  porcentaje: 0,
  esGlobal: true,
  fechaInicio: "",
  fechaFin: "",
  active: true,
  permiteManual: true,
  limiteDescuentoManual: "",
}

function recordToForm(r: DescuentoRecord): ItemForm {
  return {
    id: r.id,
    code: r.code,
    name: r.name,
    porcentaje: r.porcentaje,
    esGlobal: r.esGlobal,
    fechaInicio: r.fechaInicio,
    fechaFin: r.fechaFin,
    active: r.active,
    permiteManual: r.permiteManual,
    limiteDescuentoManual: r.limiteDescuentoManual != null ? String(r.limiteDescuentoManual) : "",
  }
}

function duplicateRecordToForm(r: DescuentoRecord): ItemForm {
  return {
    code: "",
    name: `${r.name} COPIA`,
    porcentaje: r.porcentaje,
    esGlobal: r.esGlobal,
    fechaInicio: r.fechaInicio,
    fechaFin: r.fechaFin,
    active: r.active,
    permiteManual: r.permiteManual,
    limiteDescuentoManual: r.limiteDescuentoManual != null ? String(r.limiteDescuentoManual) : "",
  }
}

function userInitials(u: DiscountUser) {
  const first = u.names?.trim()[0] ?? ""
  const last = u.surnames?.trim()[0] ?? ""
  return (first + last).toUpperCase() || (u.userName?.[0]?.toUpperCase() ?? "?")
}

export function CxCDiscountsScreen({ initialData }: { initialData: DescuentoRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<DescuentoRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<ItemForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<DescuentoRecord | null>(null)
  const [isPending, startTransition] = useTransition()
  const [tab, setTab] = useState<DiscountTab>("general")

  // ── Usuarios ──
  const [usersTab, setUsersTab] = useState<UsersSubTab>("assigned")
  const [assignedUsers, setAssignedUsers] = useState<DiscountUser[]>([])
  const [editingLimiteUserId, setEditingLimiteUserId] = useState<number | null>(null)
  const [editingLimiteValue, setEditingLimiteValue] = useState("")
  const [availableUsers, setAvailableUsers] = useState<DiscountUser[]>([])
  const [usersLoading, setUsersLoading] = useState(false)

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.name.toLowerCase().includes(q) || i.code.toLowerCase().includes(q)) : items
  }, [items, query])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])

  useEffect(() => {
    function onDown(e: MouseEvent) { if (!menuRef.current?.contains(e.target as Node)) setMenuId(null) }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  useEffect(() => {
    setForm(selected ? recordToForm(selected) : emptyForm)
    setIsEditing(false)
    setMessage(null)
    setTab("general")
    setAssignedUsers([])
    setAvailableUsers([])
  }, [selected])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  const loadUsers = useCallback(async (id: number) => {
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/cxc/discounts/${id}/users`), { credentials: "include" })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: DiscountUser[]; available: DiscountUser[] } }
      if (json.ok && json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
      }
    } finally {
      setUsersLoading(false)
    }
  }, [])

  useEffect(() => {
    if (selectedId && tab === "users") {
      void loadUsers(selectedId)
    }
  }, [selectedId, tab, loadUsers])

  async function toggleUser(userId: number, action: "assign" | "remove") {
    if (!selectedId) return
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/cxc/discounts/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action, userId }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: DiscountUser[]; available: DiscountUser[] } }
      if (json.ok && json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
      }
    } finally {
      setUsersLoading(false)
    }
  }

  async function assignAllUsers() {
    if (!selectedId) return
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/cxc/discounts/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "assign_all" }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: DiscountUser[]; available: DiscountUser[] } }
      if (json.ok && json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
      }
    } finally {
      setUsersLoading(false)
    }
  }

  async function removeAllUsers() {
    if (!selectedId) return
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/cxc/discounts/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "remove_all" }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: DiscountUser[]; available: DiscountUser[] } }
      if (json.ok && json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
      }
    } finally {
      setUsersLoading(false)
    }
  }

  async function saveLimiteUsuario(userId: number) {
    if (!selectedId) return
    const limite = editingLimiteValue.trim() === "" ? null : Number(editingLimiteValue)
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/cxc/discounts/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "update_limit", userId, limite }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: DiscountUser[]; available: DiscountUser[] } }
      if (json.ok && json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
        toast.success("Límite actualizado")
      }
    } finally {
      setUsersLoading(false)
      setEditingLimiteUserId(null)
    }
  }

  function selectItem(id: number) {
    const run = () => setSelectedId(id)
    if (isEditing && selectedId !== id) {
      confirmAction(run)
      return
    }
    run()
  }

  function openNew() {
    const run = () => {
      setSelectedId(null)
      setForm(emptyForm)
      setIsEditing(true)
      setMessage(null)
      setTab("general")
      setMenuId(null)
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function openEdit(item: DescuentoRecord) {
    const run = () => {
      setSelectedId(item.id)
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
    }
    if (isEditing && selectedId !== item.id) {
      confirmAction(run)
      return
    }
    run()
  }

  function duplicateItem(item: DescuentoRecord) {
    const run = () => {
      setSelectedId(null)
      setForm(duplicateRecordToForm(item))
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
      setTab("general")
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      setForm(selected ? recordToForm(selected) : emptyForm)
      setMessage(null)
      setTab("general")
      setDirty(false)
    })
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.code.trim()) { setMessage("El codigo es obligatorio."); return }
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }
    if (form.porcentaje < 0 || form.porcentaje > 100) { setMessage("El porcentaje debe estar entre 0 y 100."); return }
    if (form.fechaInicio && form.fechaFin && form.fechaFin < form.fechaInicio) {
      setMessage("La fecha fin debe ser mayor o igual a la fecha inicio."); return
    }
    startTransition(async () => {
      try {
        const url = form.id ? `${apiUrl("/api/cxc/discounts")}/${form.id}` : apiUrl("/api/cxc/discounts")
        const res = await fetch(url, { method: form.id ? "PUT" : "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify(form) })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: DescuentoRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Descuento actualizado" : "Descuento creado")
        if (form.id) {
          setItems(prev => prev.map(i => i.id === form.id ? result.data! : i))
        } else {
          setItems(prev => [...prev, result.data!])
          setSelectedId(result.data!.id)
        }
        setIsEditing(false)
        setDirty(false)
        router.refresh()
      } catch { setMessage("Error al guardar.") }
    })
  }

  async function handleDelete(id: number) {
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/cxc/discounts")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Descuento eliminado")
        setItems(prev => prev.filter(i => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm(emptyForm) }
        setMenuId(null)
        setDeleteTarget(null)
        router.refresh()
      } catch { toast.error("Error al eliminar.") }
    })
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Tag size={17} />
              <h2>Descuentos</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo descuento">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar descuento..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.map((item) => (
              <div
                key={item.id}
                className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`}
                onClick={() => selectItem(item.id)}
              >
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                    {item.active ? t("common.active") : t("common.inactive")}
                  </span>
                  <span className="price-lists-sidebar__code">{item.code}</span>
                  <div className="price-lists-sidebar__menu-wrap">
                    <button
                      className="price-lists-sidebar__menu-btn"
                      type="button"
                      onClick={(e) => { e.stopPropagation(); setMenuId(menuId === item.id ? null : item.id) }}
                    >
                      <MoreHorizontal size={14} />
                    </button>
                    {menuId === item.id && (
                      <ul className="price-lists-dropdown" ref={menuRef} onClick={(e) => e.stopPropagation()}>
                        <li>
                          <button type="button" onClick={() => openEdit(item)}>
                            <Pencil size={13} /> {t("common.edit")}
                          </button>
                        </li>
                        <li>
                          <button type="button" onClick={() => duplicateItem(item)}>
                            <Copy size={13} /> Duplicar
                          </button>
                        </li>
                        <li className="is-danger">
                          <button type="button" onClick={() => { setDeleteTarget(item); setMenuId(null) }}>
                            <Trash2 size={13} /> {t("common.delete")}
                          </button>
                        </li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__desc">{item.name}</p>
                <p className="price-lists-sidebar__meta">
                  {item.porcentaje}% &middot;{" "}
                  <span className={`price-lists-badge price-lists-badge--sm${item.esGlobal ? " is-active" : " is-inactive"}`}>
                    {item.esGlobal ? "Global" : "Por Linea"}
                  </span>
                </p>
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form onSubmit={onSubmit}>
              <div className="price-lists-detail__head">
                <div>
                  <h2>{form.id ? form.name : "Nuevo Descuento"}</h2>
                  {form.id && <p>{form.code}</p>}
                </div>
                <div className="price-lists-detail__head-actions">
                  {isEditing ? (
                    <>
                      <button type="button" className="secondary-button" onClick={closeEditor}>
                        <X size={16} /> {t("common.cancel")}
                      </button>
                      <button type="submit" className="primary-button" disabled={isPending}>
                        {isPending ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
                        {t("common.save")}
                      </button>
                    </>
                  ) : (
                    <button type="button" className="secondary-button" onClick={() => setIsEditing(true)}>
                      <Pencil size={16} /> {t("common.edit")}
                    </button>
                  )}
                </div>
              </div>

              <div className="price-lists-tabs">
                <button type="button" className={tab === "general" ? "filter-pill is-active" : "filter-pill"} onClick={() => setTab("general")}>
                  General
                </button>
                {form.id ? (
                  <button type="button" className={tab === "users" ? "filter-pill is-active" : "filter-pill"} onClick={() => setTab("users")}>
                    <Users size={13} /> Usuarios ({assignedUsers.length})
                  </button>
                ) : null}
              </div>

              {message && <div className="form-message" style={{ margin: "0.75rem 1.2rem 0" }}>{message}</div>}

              {tab === "general" && (
                <div className="price-lists-form">
                  <div className="form-grid form-grid--spaced" style={{ gridTemplateColumns: "20% 1fr" }}>
                    <label>
                      <span>Codigo *</span>
                      <input
                        value={form.code}
                        onChange={(e) => setForm({ ...form, code: e.target.value })}
                        disabled={!isEditing}
                        maxLength={10}
                        required
                      />
                    </label>

                    <label>
                      <span>Nombre *</span>
                      <input
                        value={form.name}
                        onChange={(e) => setForm({ ...form, name: e.target.value })}
                        disabled={!isEditing}
                        maxLength={80}
                        required
                      />
                    </label>

                    <div className="form-grid__full" style={{ display: "grid", gridTemplateColumns: "repeat(3, minmax(0,1fr))", gap: "0.9rem" }}>
                      <label>
                        <span>Porcentaje (%)</span>
                        <input
                          type="number"
                          min={0}
                          max={100}
                          step={0.01}
                          value={form.porcentaje}
                          onChange={(e) => setForm({ ...form, porcentaje: Number(e.target.value) })}
                          disabled={!isEditing}
                        />
                      </label>
                      <label>
                        <span>Fecha Inicio</span>
                        <input
                          type="date"
                          value={form.fechaInicio}
                          onChange={(e) => setForm({ ...form, fechaInicio: e.target.value })}
                          disabled={!isEditing}
                        />
                      </label>
                      <label>
                        <span>Fecha Fin</span>
                        <input
                          type="date"
                          value={form.fechaFin}
                          onChange={(e) => setForm({ ...form, fechaFin: e.target.value })}
                          disabled={!isEditing}
                        />
                      </label>
                    </div>

                    <label className="form-grid__full">
                      <span>Tipo de Aplicacion</span>
                      <div className="cxc-discounts-apply-options">
                        <label className="cxc-discounts-apply-option">
                          <input
                            type="radio"
                            checked={form.esGlobal}
                            onChange={() => isEditing && setForm({ ...form, esGlobal: true })}
                            disabled={!isEditing}
                          />
                          Aplica al documento completo
                        </label>
                        <label className="cxc-discounts-apply-option">
                          <input
                            type="radio"
                            checked={!form.esGlobal}
                            onChange={() => isEditing && setForm({ ...form, esGlobal: false })}
                            disabled={!isEditing}
                          />
                          Aplica por linea de item
                        </label>
                      </div>
                    </label>

                    <label className="company-active-toggle form-grid__full">
                      <div><span>Activo</span></div>
                      <button
                        type="button"
                        className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                        onClick={() => isEditing && setForm({ ...form, active: !form.active })}
                        disabled={!isEditing}
                      >
                        <span />
                      </button>
                    </label>

                    <label className="company-active-toggle form-grid__full">
                      <div>
                        <span>Permite descuento manual</span>
                        <small style={{ display: "block", color: "var(--muted)", fontSize: "0.75rem" }}>El usuario puede ingresar un monto libre al aplicar este descuento</small>
                      </div>
                      <button
                        type="button"
                        className={form.permiteManual ? "toggle-switch is-on" : "toggle-switch"}
                        onClick={() => isEditing && setForm({ ...form, permiteManual: !form.permiteManual, limiteDescuentoManual: "" })}
                        disabled={!isEditing}
                      >
                        <span />
                      </button>
                    </label>

                    {form.permiteManual && (
                      <label>
                        <span>Límite máximo manual (%)</span>
                        <input
                          type="number"
                          min={0}
                          max={100}
                          step={0.01}
                          placeholder="Sin límite"
                          value={form.limiteDescuentoManual}
                          onChange={(e) => setForm({ ...form, limiteDescuentoManual: e.target.value })}
                          disabled={!isEditing}
                        />
                      </label>
                    )}
                  </div>
                </div>
              )}


              {tab === "users" && form.id ? (
                <div className="price-lists-users">

                  <div className="price-lists-users__tabs">
                    <button
                      type="button"
                      className={usersTab === "assigned" ? "filter-pill is-active" : "filter-pill"}
                      onClick={() => setUsersTab("assigned")}
                    >
                      Asignados ({assignedUsers.length})
                    </button>
                    <button
                      type="button"
                      className={usersTab === "available" ? "filter-pill is-active" : "filter-pill"}
                      onClick={() => setUsersTab("available")}
                    >
                      Disponibles ({availableUsers.length})
                    </button>
                    {usersLoading ? <Loader2 size={14} className="spin price-lists-users__spinner" /> : null}
                  </div>

                  <div className="price-lists-users__bulk-actions">
                    {usersTab === "available" ? (
                      <button
                        type="button"
                        className="ghost-button price-lists-users__bulk-btn"
                        onClick={() => void assignAllUsers()}
                        disabled={usersLoading || availableUsers.length === 0}
                        title="Asignar todos"
                      >
                        <UserCheck size={14} /> Asignar todos
                      </button>
                    ) : (
                      <button
                        type="button"
                        className="ghost-button price-lists-users__bulk-btn"
                        onClick={() => void removeAllUsers()}
                        disabled={usersLoading || assignedUsers.length === 0}
                        title="Quitar todos"
                      >
                        <UserX size={14} /> Quitar todos
                      </button>
                    )}
                  </div>

                  <ul className="price-lists-users__list">
                    {(usersTab === "assigned" ? assignedUsers : availableUsers).map((u) => (
                      <li key={u.id} className="price-lists-users__item">
                        <div className={`price-lists-users__avatar${usersTab === "assigned" ? " is-assigned" : ""}`}>
                          {userInitials(u)}
                        </div>
                        <div className="price-lists-users__info">
                          <strong>{u.names} {u.surnames}</strong>
                          <span>@{u.userName}</span>
                        </div>
                        {/* Límite personal — solo en asignados y si el descuento permite manual */}
                        {usersTab === "assigned" && selected?.permiteManual && (
                          editingLimiteUserId === u.id ? (
                            <div className="discount-user-limit__edit">
                              <input
                                type="number"
                                min={0}
                                max={selected?.limiteDescuentoManual ?? undefined}
                                step={1}
                                placeholder="Sin límite"
                                value={editingLimiteValue}
                                autoFocus
                                onInput={(e) => {
                                  const cap = selected?.limiteDescuentoManual
                                  if (cap == null) return
                                  const val = Number((e.target as HTMLInputElement).value)
                                  if (val >= cap) toast.warning(`Máximo permitido: ${cap}%`)
                                }}
                                onChange={(e) => {
                                  const cap = selected?.limiteDescuentoManual
                                  const val = Number(e.target.value)
                                  if (cap != null && val > cap) {
                                    setEditingLimiteValue(String(cap))
                                    e.target.value = String(cap)
                                  } else {
                                    setEditingLimiteValue(e.target.value)
                                  }
                                }}
                                onKeyDown={(e) => {
                                  if (e.key === "Enter") { void saveLimiteUsuario(u.id); return }
                                  if (e.key === "Escape") { setEditingLimiteUserId(null); return }
                                  const cap = selected?.limiteDescuentoManual
                                  if (cap == null) return
                                  if (e.key === "ArrowUp") {
                                    e.preventDefault()
                                    const next = Math.min(Number(editingLimiteValue || 0) + 1, cap)
                                    if (next > cap) toast.warning(`Máximo permitido: ${cap}%`)
                                    setEditingLimiteValue(String(next))
                                  }
                                  if (e.key === "ArrowDown") {
                                    e.preventDefault()
                                    setEditingLimiteValue(String(Math.max(Number(editingLimiteValue || 0) - 1, 0)))
                                  }
                                }}
                              />
                              <button type="button" className="primary-button" onClick={() => void saveLimiteUsuario(u.id)} title="Guardar"><Save size={13} /></button>
                              <button type="button" className="secondary-button" onClick={() => setEditingLimiteUserId(null)} title="Cancelar"><X size={13} /></button>
                            </div>
                          ) : (
                            <button
                              type="button"
                              className="discount-user-limit__btn"
                              title="Editar límite manual"
                              onClick={() => { setEditingLimiteUserId(u.id); setEditingLimiteValue(u.limiteDescuentoManual != null ? String(u.limiteDescuentoManual) : "") }}
                            >
                              {u.limiteDescuentoManual != null ? `${u.limiteDescuentoManual}%` : <span className="discount-user-limit__none">Sin límite</span>}
                              <Pencil size={11} />
                            </button>
                          )
                        )}
                        {usersTab === "assigned" ? (
                          <button
                            type="button"
                            className="ghost-button price-lists-users__action is-remove"
                            onClick={() => void toggleUser(u.id, "remove")}
                            disabled={usersLoading}
                            title="Quitar usuario"
                          >
                            <UserMinus size={15} />
                          </button>
                        ) : (
                          <button
                            type="button"
                            className="ghost-button price-lists-users__action is-assign"
                            onClick={() => void toggleUser(u.id, "assign")}
                            disabled={usersLoading}
                            title="Asignar usuario"
                          >
                            <UserPlus size={15} />
                          </button>
                        )}
                      </li>
                    ))}

                    {usersTab === "assigned" && assignedUsers.length === 0 ? (
                      <li className="price-lists-users__empty">
                        <Users size={26} />
                        <p>No hay usuarios asignados.<br /><small>Sin asignaciones, el descuento aplica a todos.</small></p>
                      </li>
                    ) : null}
                    {usersTab === "available" && availableUsers.length === 0 ? (
                      <li className="price-lists-users__empty">
                        <Users size={26} />
                        <p>Todos los usuarios están asignados</p>
                      </li>
                    ) : null}
                  </ul>

                </div>
              ) : null}

            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona un descuento o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Descuento"
        itemName={deleteTarget?.name ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
