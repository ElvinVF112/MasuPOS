"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react"
import {
  Calendar,
  Copy,
  Loader2,
  MoreHorizontal,
  Pencil,
  Plus,
  Save,
  Search,
  Tag,
  Trash2,
  UserCheck,
  UserMinus,
  UserPlus,
  Users,
  UserX,
  X,
} from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import type { PriceListRecord, PriceListUser } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

// ── Constantes ────────────────────────────────────────────────────────────────

const CURRENCIES = [
  { id: "", label: "— Sin moneda —" },
  { id: "1", label: "DOP — Peso Dominicano" },
  { id: "2", label: "USD — Dólar Estadounidense" },
  { id: "3", label: "EUR — Euro" },
]

// ── Tipos internos ────────────────────────────────────────────────────────────

type PriceListTab = "general" | "users"
type UsersTab = "assigned" | "available"

type PriceListForm = {
  id?: number
  code: string
  description: string
  abbreviation: string
  currencyId: string
  startDate: string
  endDate: string
  active: boolean
}

const emptyForm: PriceListForm = {
  code: "",
  description: "",
  abbreviation: "",
  currencyId: "",
  startDate: new Date().toISOString().slice(0, 10),
  endDate: "2099-12-31",
  active: true,
}

function recordToForm(r: PriceListRecord): PriceListForm {
  return {
    id: r.id,
    code: r.code,
    description: r.description,
    abbreviation: r.abbreviation,
    currencyId: r.currencyId != null ? String(r.currencyId) : "",
    startDate: r.startDate || new Date().toISOString().slice(0, 10),
    endDate: r.endDate || "2099-12-31",
    active: r.active,
  }
}

// ── Componente principal ──────────────────────────────────────────────────────

export function PriceListsScreen() {
  const router = useRouter()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLDivElement | null>(null)

  // ── Estado listas ──
  const [items, setItems] = useState<PriceListRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [query, setQuery] = useState("")

  // ── Estado panel derecho ──
  const [tab, setTab] = useState<PriceListTab>("general")
  const [usersTab, setUsersTab] = useState<UsersTab>("assigned")
  const [isEditing, setIsEditing] = useState(false)
  const [isBusy, setIsBusy] = useState(false)
  const [form, setForm] = useState<PriceListForm>(emptyForm)
  const [message, setMessage] = useState<string | null>(null)
  const [menuOpenId, setMenuOpenId] = useState<number | null>(null)

  // ── Estado usuarios ──
  const [assignedUsers, setAssignedUsers] = useState<PriceListUser[]>([])
  const [availableUsers, setAvailableUsers] = useState<PriceListUser[]>([])
  const [usersLoading, setUsersLoading] = useState(false)

  // ── Carga inicial ──
  useEffect(() => {
    void (async () => {
      try {
        const res = await fetch(apiUrl("/api/catalog/price-lists"), { credentials: "include" })
        const json = (await res.json()) as { ok: boolean; data?: PriceListRecord[] }
        if (json.ok && json.data) {
          setItems(json.data)
          if (json.data.length > 0) {
            setSelectedId(json.data[0].id)
            setForm(recordToForm(json.data[0]))
          }
        }
      } finally {
        setLoading(false)
      }
    })()
  }, [])

  // ── Carga usuarios cuando cambia selectedId o tab ──
  const loadUsers = useCallback(async (id: number) => {
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/price-lists/${id}/users`), { credentials: "include" })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: PriceListUser[]; available: PriceListUser[] } }
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

  // ── Cerrar menú al click fuera ──
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setMenuOpenId(null)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  // ── Derived ──
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return items
    return items.filter(
      (i) =>
        i.description.toLowerCase().includes(q) ||
        i.code.toLowerCase().includes(q) ||
        i.abbreviation.toLowerCase().includes(q),
    )
  }, [items, query])

  const selected = useMemo(() => items.find((i) => i.id === selectedId) ?? null, [items, selectedId])

  // ── Handlers ──
  function selectItem(item: PriceListRecord) {
    confirmAction(() => {
      setIsEditing(false)
      setDirty(false)
      setSelectedId(item.id)
      setForm(recordToForm(item))
      setTab("general")
      setMessage(null)
      setMenuOpenId(null)
    })
    return
  }

  function beginEdit() {
    setMessage(null)
    setIsEditing(true)
    setDirty(true)
  }

  function cancelEdit() {
    if (selected) setForm(recordToForm(selected))
    setMessage(null)
    setIsEditing(false)
    setDirty(false)
  }

  function update<K extends keyof PriceListForm>(key: K, value: PriceListForm[K]) {
    setForm((prev) => ({ ...prev, [key]: value }))
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!isEditing) return
    if (!form.description.trim()) { setMessage("La descripción es obligatoria."); return }
    if (!form.code.trim()) { setMessage("El código es obligatorio."); return }
    if (!form.startDate.trim()) { setMessage("La fecha de inicio es obligatoria."); return }
    if (!form.endDate.trim()) { setMessage("La fecha de fin es obligatoria."); return }

    setIsBusy(true)
    setMessage(null)
    try {
      const isNew = !form.id
      const url = isNew ? apiUrl("/api/catalog/price-lists") : apiUrl(`/api/catalog/price-lists/${form.id}`)
      const res = await fetch(url, {
        method: isNew ? "POST" : "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          code: form.code,
          description: form.description,
          abbreviation: form.abbreviation || null,
          currencyId: form.currencyId ? Number(form.currencyId) : null,
          startDate: form.startDate,
          endDate: form.endDate,
          active: form.active,
        }),
      })
      const json = (await res.json()) as { ok: boolean; data?: PriceListRecord; message?: string }
      if (!res.ok || !json.ok) {
        const msg = json.message ?? "No se pudo guardar."
        setMessage(msg)
        toast.error("Error al guardar", { description: msg })
        return
      }
      const saved = json.data!
      setItems((prev) => (isNew ? [...prev, saved] : prev.map((i) => (i.id === saved.id ? saved : i))))
      setSelectedId(saved.id)
      setForm(recordToForm(saved))
      setIsEditing(false)
      setDirty(false)
      toast.success(isNew ? "Lista creada" : "Cambios guardados")
      router.refresh()
    } finally {
      setIsBusy(false)
    }
  }

  async function handleDelete(item: PriceListRecord) {
    if (!confirm(`¿Eliminar la lista "${item.description}"?`)) return
    setMenuOpenId(null)
    setIsBusy(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/price-lists/${item.id}`), { method: "DELETE", credentials: "include" })
      const json = (await res.json()) as { ok: boolean; message?: string }
      if (!res.ok || !json.ok) { toast.error("Error", { description: json.message ?? "No se pudo eliminar." }); return }
      const remaining = items.filter((i) => i.id !== item.id)
      setItems(remaining)
      if (selectedId === item.id) {
        const next = remaining[0] ?? null
        setSelectedId(next?.id ?? null)
        setForm(next ? recordToForm(next) : emptyForm)
      }
      toast.success("Lista eliminada")
      router.refresh()
    } finally {
      setIsBusy(false)
    }
  }

  function handleDuplicate(item: PriceListRecord) {
    setSelectedId(null)
    setForm({
      ...recordToForm(item),
      id: undefined,
      description: `Copia de — ${item.description}`,
    })
    setAssignedUsers([])
    setAvailableUsers([])
    setTab("general")
    setUsersTab("assigned")
    setIsEditing(true)
    setDirty(true)
    setMenuOpenId(null)
    setMessage(null)
  }

  function handleNewList() {
    confirmAction(() => {
      setSelectedId(null)
      setForm(emptyForm)
      setIsEditing(true)
      setDirty(true)
      setTab("general")
      setMessage(null)
    })
    return
  }

  async function toggleUser(userId: number, action: "assign" | "remove") {
    if (!selectedId) return
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/price-lists/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action, userId }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: PriceListUser[]; available: PriceListUser[] }; message?: string }
      if (!res.ok || !json.ok) { toast.error("Error", { description: json.message ?? "No se pudo actualizar." }); return }
      if (json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
        setItems((prev) =>
          prev.map((i) => (i.id === selectedId ? { ...i, totalUsers: json.data!.assigned.length } : i)),
        )
      }
    } finally {
      setUsersLoading(false)
    }
  }

  async function assignAllUsers() {
    if (!selectedId) return
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/price-lists/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "assign_all" }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: PriceListUser[]; available: PriceListUser[] }; message?: string }
      if (!res.ok || !json.ok) { toast.error("Error", { description: json.message ?? "No se pudo asignar todos." }); return }
      if (json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
        setItems((prev) =>
          prev.map((i) => (i.id === selectedId ? { ...i, totalUsers: json.data!.assigned.length } : i)),
        )
        toast.success(`${json.data.assigned.length} usuario(s) asignado(s)`)
      }
    } finally {
      setUsersLoading(false)
    }
  }

  async function removeAllUsers() {
    if (!selectedId) return
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/price-lists/${selectedId}/users`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "remove_all" }),
      })
      const json = (await res.json()) as { ok: boolean; data?: { assigned: PriceListUser[]; available: PriceListUser[] }; message?: string }
      if (!res.ok || !json.ok) { toast.error("Error", { description: json.message ?? "No se pudo quitar todos." }); return }
      if (json.data) {
        setAssignedUsers(json.data.assigned)
        setAvailableUsers(json.data.available)
        setItems((prev) =>
          prev.map((i) => (i.id === selectedId ? { ...i, totalUsers: json.data!.assigned.length } : i)),
        )
        toast.success("Todos los usuarios removidos")
      }
    } finally {
      setUsersLoading(false)
    }
  }

  function userInitials(u: PriceListUser) {
    const a = u.names?.[0] ?? ""
    const b = u.surnames?.[0] ?? ""
    return (a + b).toUpperCase() || u.userName.slice(0, 2).toUpperCase()
  }

  // ── Render ────────────────────────────────────────────────────────────────

  if (loading) {
    return (
      <div className="price-lists-loading">
        <Loader2 size={28} className="spin" />
        <p>Cargando listas de precios...</p>
      </div>
    )
  }

  return (
    <div className="price-lists-layout" ref={menuRef as React.RefObject<HTMLDivElement>}>

      {/* ══ Panel izquierdo ══════════════════════════════════════════════════ */}
      <aside className="price-lists-sidebar">

        <div className="price-lists-sidebar__header">
          <div className="price-lists-sidebar__title">
            <Tag size={17} />
            <h2>Listas de Precios</h2>
          </div>
          <button className="price-lists-sidebar__add-btn" type="button" onClick={handleNewList} title="Nueva lista">
            <Plus size={15} />
          </button>
        </div>

        <div className="price-lists-sidebar__search">
          <Search size={13} className="price-lists-sidebar__search-icon" />
          <input
            type="text"
            placeholder="Buscar lista..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>

        <ul className="price-lists-sidebar__list">
          {filtered.map((item) => (
            <li
              key={item.id}
              className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`}
              onClick={() => selectItem(item)}
            >
              <div className="price-lists-sidebar__item-top">
                <span className="price-lists-sidebar__code">#{item.code}</span>
                <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                  {item.active ? "Activo" : "Inactivo"}
                </span>
                <div className="price-lists-sidebar__menu-wrap">
                  <button
                    className="price-lists-sidebar__menu-btn"
                    type="button"
                    onClick={(e) => {
                      e.stopPropagation()
                      setMenuOpenId(menuOpenId === item.id ? null : item.id)
                    }}
                  >
                    <MoreHorizontal size={14} />
                  </button>
                  {menuOpenId === item.id ? (
                    <ul className="price-lists-dropdown" onClick={(e) => e.stopPropagation()}>
                      <li>
                        <button type="button" onClick={() => { selectItem(item); beginEdit() }}>
                          <Pencil size={13} /> Editar
                        </button>
                      </li>
                      <li>
                        <button type="button" onClick={() => handleDuplicate(item)}>
                          <Copy size={13} /> Duplicar
                        </button>
                      </li>
                      <li className="is-danger">
                        <button type="button" onClick={() => handleDelete(item)}>
                          <Trash2 size={13} /> Eliminar
                        </button>
                      </li>
                    </ul>
                  ) : null}
                </div>
              </div>
              <p className="price-lists-sidebar__desc">{item.description || "(sin descripción)"}</p>
              <p className="price-lists-sidebar__meta">
                <Users size={11} /> {item.totalUsers} usuario{item.totalUsers !== 1 ? "s" : ""}
              </p>
            </li>
          ))}
          {filtered.length === 0 ? (
            <li className="price-lists-sidebar__empty">Sin resultados</li>
          ) : null}
        </ul>

        <div className="price-lists-sidebar__footer">
          {filtered.length} lista{filtered.length !== 1 ? "s" : ""}
        </div>
      </aside>

      {/* ══ Panel derecho ════════════════════════════════════════════════════ */}
      {selectedId !== null || isEditing ? (
        <section className="price-lists-detail">

          {/* Cabecera */}
          <div className="products-detail__action-bar">
            {isEditing ? (
              <div className="products-detail__action-bar-btns">
                <button className="secondary-button" type="button" onClick={cancelEdit} disabled={isBusy}>
                  <X size={14} /> Cancelar
                </button>
                <button className="primary-button" type="button" onClick={(e) => void submit(e as unknown as FormEvent)} disabled={isBusy}>
                  {isBusy ? <Loader2 size={14} className="spin" /> : <Save size={14} />}
                  {isBusy ? "Guardando..." : "Guardar"}
                </button>
              </div>
            ) : null}
          </div>

          {/* Tabs */}
          <div className="price-lists-detail__tabs">
            <button
              type="button"
              className={tab === "general" ? "filter-pill is-active" : "filter-pill"}
              onClick={() => setTab("general")}
            >
              <Tag size={13} /> General
            </button>
            {form.id ? (
              <button
                type="button"
                className={tab === "users" ? "filter-pill is-active" : "filter-pill"}
                onClick={() => setTab("users")}
              >
                <Users size={13} /> Usuarios ({selected?.totalUsers ?? 0})
              </button>
            ) : null}
          </div>

          {/* ── Tab General ── */}
          {tab === "general" ? (
            <form className="data-panel price-lists-form" onSubmit={(e) => void submit(e)}>
              <div className="form-grid form-grid--spaced">

                <div className="form-grid__row-with-toggle">
                  <label>
                    <span>Código</span>
                    <input
                      value={form.code}
                      onChange={(e) => update("code", e.target.value)}
                      disabled={!!form.id || !isEditing}
                      required
                      maxLength={20}
                      placeholder="Ej: GENERAL"
                    />
                  </label>
                  <label className="form-grid__toggle">
                    <span>Activo</span>
                    <button
                      type="button"
                      className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                      onClick={() => isEditing && update("active", !form.active)}
                      disabled={!isEditing}
                    >
                      <span />
                    </button>
                  </label>
                </div>

                <label className="form-grid__full">
                  <span>Descripción</span>
                  <input
                    value={form.description}
                    onChange={(e) => update("description", e.target.value)}
                    disabled={!isEditing}
                    required
                    maxLength={200}
                    placeholder="Nombre completo de la lista"
                  />
                </label>

                <label>
                  <span>Abreviatura</span>
                  <input
                    value={form.abbreviation}
                    onChange={(e) => update("abbreviation", e.target.value)}
                    disabled={!isEditing}
                    maxLength={10}
                    placeholder="Ej: GEN"
                  />
                </label>

                <label>
                  <span>Moneda</span>
                  <select
                    value={form.currencyId}
                    onChange={(e) => update("currencyId", e.target.value)}
                    disabled={!isEditing}
                  >
                    {CURRENCIES.map((c) => (
                      <option key={c.id} value={c.id}>{c.label}</option>
                    ))}
                  </select>
                </label>

                <label>
                  <span><Calendar size={13} /> Inicio de Vigencia *</span>
                  <input
                    type="date"
                    value={form.startDate}
                    onChange={(e) => update("startDate", e.target.value)}
                    disabled={!isEditing}
                    required
                  />
                </label>

                <label>
                  <span><Calendar size={13} /> Fin de Vigencia *</span>
                  <input
                    type="date"
                    value={form.endDate}
                    onChange={(e) => update("endDate", e.target.value)}
                    disabled={!isEditing}
                    required
                  />
                </label>

              </div>
              {message ? <p className="form-message">{message}</p> : null}
            </form>
          ) : null}

          {/* ── Tab Usuarios ── */}
          {tab === "users" && form.id ? (
            <div className="data-panel price-lists-users">

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
                    <UserCheck size={14} />
                    Asignar todos
                  </button>
                ) : (
                  <button
                    type="button"
                    className="ghost-button price-lists-users__bulk-btn"
                    onClick={() => void removeAllUsers()}
                    disabled={usersLoading || assignedUsers.length === 0}
                    title="Quitar todos"
                  >
                    <UserX size={14} />
                    Quitar todos
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
                    <p>No hay usuarios asignados</p>
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

        </section>
      ) : (
        <section className="price-lists-empty">
          <Tag size={44} />
          <p>Selecciona una lista o crea una nueva</p>
        </section>
      )}

    </div>
  )
}
