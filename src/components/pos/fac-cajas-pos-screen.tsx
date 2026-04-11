"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Loader2, Monitor, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, UserMinus, UserPlus, Users, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { FacCajaPOSRecord, FacCajaPOSUsuarioRecord } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

type DetailTab = "general" | "users"
type UsersSubTab = "assigned" | "available"

type CurrencyOption = { id: number; code: string; name: string; symbol: string }

type ItemForm = {
  id?: number
  descripcion: string
  idSucursal: number | null
  idPuntoEmision: number | null
  idMoneda: number | null
  cajaAbierta: boolean
  manejaFondo: boolean
  fondoFijo: boolean
  fondoCaja: number
  active: boolean
}

function recordToForm(r: FacCajaPOSRecord): ItemForm {
  return {
    id: r.id,
    descripcion: r.descripcion,
    idSucursal: r.idSucursal,
    idPuntoEmision: r.idPuntoEmision,
    idMoneda: r.idMoneda,
    cajaAbierta: r.cajaAbierta,
    manejaFondo: r.manejaFondo,
    fondoFijo: r.fondoFijo,
    fondoCaja: r.fondoCaja,
    active: r.active,
  }
}

const emptyForm: ItemForm = {
  descripcion: "",
  idSucursal: null,
  idPuntoEmision: null,
  idMoneda: null,
  cajaAbierta: false,
  manejaFondo: false,
  fondoFijo: false,
  fondoCaja: 0,
  active: true,
}

const sectionTitle: React.CSSProperties = {
  fontSize: "0.78rem",
  fontWeight: 700,
  color: "var(--brand)",
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  borderBottom: "2px solid var(--brand)",
  paddingBottom: "0.25rem",
  marginBottom: "0.7rem",
}

type Props = {
  initialData: FacCajaPOSRecord[]
  sucursales: { id: number; nombre: string }[]
  puntosEmision: { id: number; nombre: string; idSucursal: number }[]
  currencies: CurrencyOption[]
}

const API_BASE = "/api/config/facturacion/cajas-pos"

export function FacCajasPOSScreen({ initialData, sucursales, puntosEmision, currencies }: Props) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<FacCajaPOSRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(initialData[0]?.id ?? null)
  const [form, setForm] = useState<ItemForm>(initialData[0] ? recordToForm(initialData[0]) : { ...emptyForm })
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [tab, setTab] = useState<DetailTab>("general")
  const [usersSubTab, setUsersSubTab] = useState<UsersSubTab>("assigned")
  const [users, setUsers] = useState<FacCajaPOSUsuarioRecord[]>([])
  const [usersLoading, setUsersLoading] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<FacCajaPOSRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.descripcion.toLowerCase().includes(q)) : items
  }, [items, query])

  // Group sidebar items by sucursal
  const groupedItems = useMemo(() => {
    const groups: { sucursal: string; items: FacCajaPOSRecord[] }[] = []
    const map = new Map<string, FacCajaPOSRecord[]>()
    for (const item of filteredItems) {
      const key = item.nombreSucursal || "Sin sucursal"
      if (!map.has(key)) { map.set(key, []); groups.push({ sucursal: key, items: map.get(key)! }) }
      map.get(key)!.push(item)
    }
    return groups
  }, [filteredItems])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])
  const assignedUsers = useMemo(() => users.filter(u => u.assigned), [users])
  const availableUsers = useMemo(() => users.filter(u => !u.assigned), [users])

  // Filtered puntos de emision based on selected sucursal
  const filteredPuntos = useMemo(
    () => form.idSucursal ? puntosEmision.filter(p => p.idSucursal === form.idSucursal) : [],
    [form.idSucursal, puntosEmision],
  )

  // Close menu on outside click
  useEffect(() => {
    function onDown(e: MouseEvent) { if (!menuRef.current?.contains(e.target as Node)) setMenuId(null) }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  // Sync form when selection changes
  useEffect(() => {
    if (selected) {
      setForm(recordToForm(selected))
      setMessage(null)
      setTab("general")
      setUsers([])
      return
    }
    if (!isEditing) {
      setForm({ ...emptyForm })
      setMessage(null)
      setTab("general")
      setUsers([])
    }
  }, [isEditing, selected])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  // Auto-select first item
  useEffect(() => {
    if (isEditing || selectedId != null || items.length === 0) return
    setSelectedId(items[0].id)
  }, [isEditing, items, selectedId])

  // Load users when switching to "users" tab
  useEffect(() => {
    if (tab === "users" && selectedId != null) {
      void loadUsers(selectedId)
    }
  }, [tab, selectedId])

  function selectItem(id: number) {
    const run = () => {
      setSelectedId(id)
      setIsEditing(false)
      setMessage(null)
      setTab("general")
    }
    if (isEditing && selectedId !== id) {
      confirmAction(run)
      return
    }
    run()
  }

  async function loadUsers(id: number) {
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`${API_BASE}/${id}?section=users`), { credentials: "include" })
      const result = (await res.json()) as { ok: boolean; data?: FacCajaPOSUsuarioRecord[]; message?: string }
      if (result.ok && result.data) {
        setUsers(result.data)
      } else {
        toast.error(result.message ?? "No se pudieron cargar los usuarios.")
      }
    } catch {
      toast.error("Error al cargar usuarios.")
    } finally {
      setUsersLoading(false)
    }
  }

  function openNew() {
    const run = () => {
      setSelectedId(null)
      setForm({ ...emptyForm })
      setIsEditing(true)
      setMessage(null)
      setTab("general")
      setUsers([])
      setMenuId(null)
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function openEdit(item: FacCajaPOSRecord) {
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

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      setForm(selected ? recordToForm(selected) : { ...emptyForm })
      setMessage(null)
      setDirty(false)
    })
  }

  function duplicateItem(item: FacCajaPOSRecord) {
    const run = () => {
      setSelectedId(null)
      setForm({
        ...recordToForm(item),
        id: undefined,
        descripcion: `${item.descripcion} COPIA`,
        cajaAbierta: false,
      })
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
      setTab("general")
      setUsers([])
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.descripcion.trim()) { setMessage("La descripcion es obligatoria."); return }
    if (!form.idSucursal) { setMessage("La sucursal es obligatoria."); return }

    startTransition(async () => {
      try {
        const url = form.id
          ? apiUrl(`${API_BASE}/${form.id}`)
          : apiUrl(API_BASE)
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            ...form,
            descripcion: (form.descripcion || "").toUpperCase(),
          }),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: FacCajaPOSRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }

        toast.success(form.id ? "Caja POS actualizada" : "Caja POS creada")
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
        const res = await fetch(apiUrl(`${API_BASE}/${id}`), { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Caja POS eliminada")
        setItems(prev => prev.filter(i => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm({ ...emptyForm }) }
        setMenuId(null)
        setDeleteTarget(null)
        router.refresh()
      } catch { toast.error("Error al eliminar.") }
    })
  }

  async function handleToggleUser(userId: number, currentlyAssigned: boolean) {
    if (!selectedId) return
    const newIds = currentlyAssigned
      ? assignedUsers.filter(u => u.id !== userId).map(u => u.id)
      : [...assignedUsers.map(u => u.id), userId]

    try {
      const res = await fetch(apiUrl(`${API_BASE}/${selectedId}`), {
        method: "PATCH",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userIds: newIds }),
      })
      const result = (await res.json()) as { ok: boolean; data?: FacCajaPOSUsuarioRecord[] }
      if (result.ok && result.data) {
        setUsers(result.data)
        toast.success(currentlyAssigned ? "Usuario removido" : "Usuario asignado")
      }
    } catch { toast.error("Error al actualizar usuarios.") }
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        {/* -- Sidebar -- */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Monitor size={17} />
              <h2>Cajas POS</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva caja POS">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.length === 0 && (
              <p className="price-lists-empty-msg">No hay cajas POS configuradas</p>
            )}
            {groupedItems.map((group) => (
              <div key={group.sucursal}>
                <div style={{ padding: "0.45rem 0.7rem", fontSize: "0.72rem", fontWeight: 700, color: "var(--brand)", textTransform: "uppercase", letterSpacing: "0.04em", background: "var(--bg, #f8fafc)", borderBottom: "1px solid var(--line)", position: "sticky", top: 0, zIndex: 1 }}>
                  Sucursal : {group.sucursal}
                </div>
                {group.items.map((item) => (
                  <div
                    key={item.id}
                    className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`}
                    onClick={() => selectItem(item.id)}
                  >
                    <div className="price-lists-sidebar__item-top">
                      <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                        {item.active ? t("common.active") : t("common.inactive")}
                      </span>
                      <span className="price-lists-sidebar__code">#{item.id}</span>
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
                    <p className="price-lists-sidebar__desc">{item.descripcion}</p>
                    <p className="price-lists-sidebar__meta">
                      {item.nombreSucursal}{item.nombrePuntoEmision ? ` / ${item.nombrePuntoEmision}` : ""}
                    </p>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </aside>

        {/* -- Panel Principal -- */}
        <main className="price-lists-main">
          {selected || isEditing ? (
            <form onSubmit={onSubmit} style={{ display: "flex", flexDirection: "column", height: "100%" }}>
              <div className="products-detail__action-bar">
                {isEditing ? (
                  <div className="products-detail__action-bar-btns">
                    <button type="button" className="secondary-button" onClick={closeEditor}>
                      <X size={16} /> {t("common.cancel")}
                    </button>
                    <button type="submit" className="primary-button" disabled={isPending}>
                      {isPending ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
                      {t("common.save")}
                    </button>
                  </div>
                ) : null}
              </div>

              {/* Tabs */}
              <div className="price-lists-tabs">
                <button
                  type="button"
                  className={tab === "general" ? "filter-pill is-active" : "filter-pill"}
                  onClick={() => setTab("general")}
                >
                  General
                </button>
                {form.id && (
                  <button
                    type="button"
                    className={tab === "users" ? "filter-pill is-active" : "filter-pill"}
                    onClick={() => setTab("users")}
                  >
                    <Users size={13} /> Usuarios ({assignedUsers.length})
                  </button>
                )}
              </div>

              {message && <div className="form-message" style={{ margin: "0.75rem 1.2rem 0" }}>{message}</div>}

              {/* Tab General */}
              {tab === "general" && (
                <div className="price-lists-form">
                  <div className="form-grid">
                    {/* Row 1: Descripcion + Activo */}
                    <div className="form-grid__row-with-toggle">
                      <label style={{ flex: "1 1 0" }}>
                        <span>Descripcion *</span>
                        <input
                          value={form.descripcion}
                          onChange={(e) => setForm({ ...form, descripcion: e.target.value })}
                          disabled={!isEditing}
                          maxLength={150}
                          required
                        />
                      </label>
                      <label className="form-grid__toggle">
                        <span>Activo</span>
                        <button
                          type="button"
                          className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                          onClick={() => isEditing && setForm({ ...form, active: !form.active })}
                          disabled={!isEditing}
                        >
                          <span />
                        </button>
                      </label>
                    </div>

                    {/* Sucursal */}
                    <label>
                      <span>Sucursal *</span>
                      <select
                        value={form.idSucursal ?? ""}
                        onChange={(e) => {
                          const val = e.target.value ? Number(e.target.value) : null
                          setForm(prev => ({ ...prev, idSucursal: val, idPuntoEmision: null }))
                        }}
                        disabled={!isEditing}
                        required
                      >
                        <option value="">Seleccionar sucursal</option>
                        {sucursales.map(s => (
                          <option key={s.id} value={s.id}>{s.nombre}</option>
                        ))}
                      </select>
                    </label>

                    {/* Punto de Emision (filtered by sucursal) */}
                    <label>
                      <span>Punto de Emision</span>
                      <select
                        value={form.idPuntoEmision ?? ""}
                        onChange={(e) => setForm({ ...form, idPuntoEmision: e.target.value ? Number(e.target.value) : null })}
                        disabled={!isEditing || !form.idSucursal}
                      >
                        <option value="">Sin punto de emision</option>
                        {filteredPuntos.map(p => (
                          <option key={p.id} value={p.id}>{p.nombre}</option>
                        ))}
                      </select>
                    </label>

                    {/* Moneda Base */}
                    <label>
                      <span>Moneda Base</span>
                      <select
                        value={form.idMoneda ?? ""}
                        onChange={(e) => setForm({ ...form, idMoneda: e.target.value ? Number(e.target.value) : null })}
                        disabled={!isEditing}
                      >
                        <option value="">Sin moneda asignada</option>
                        {currencies.map(c => (
                          <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                        ))}
                      </select>
                    </label>

                    {/* Section: Fondo de Caja */}
                    <div className="form-grid__full" style={{ marginTop: "0.5rem" }}>
                      <p style={sectionTitle}>Fondo de Caja</p>
                    </div>

                    <label className="form-grid__toggle">
                      <span>Caja Abierta</span>
                      <button
                        type="button"
                        className={form.cajaAbierta ? "toggle-switch is-on" : "toggle-switch"}
                        disabled
                      >
                        <span />
                      </button>
                    </label>

                    <label className="form-grid__toggle">
                      <span>Maneja Fondo</span>
                      <button
                        type="button"
                        className={form.manejaFondo ? "toggle-switch is-on" : "toggle-switch"}
                        onClick={() => isEditing && setForm(prev => ({
                          ...prev,
                          manejaFondo: !prev.manejaFondo,
                          ...(!prev.manejaFondo ? {} : { fondoFijo: false, fondoCaja: 0 }),
                        }))}
                        disabled={!isEditing}
                      >
                        <span />
                      </button>
                    </label>

                    <label className="form-grid__toggle">
                      <span>Fondo Fijo</span>
                      <button
                        type="button"
                        className={form.fondoFijo ? "toggle-switch is-on" : "toggle-switch"}
                        onClick={() => isEditing && form.manejaFondo && setForm(prev => ({ ...prev, fondoFijo: !prev.fondoFijo }))}
                        disabled={!isEditing || !form.manejaFondo}
                      >
                        <span />
                      </button>
                    </label>

                    <label>
                      <span>Fondo de Caja</span>
                      <input
                        type="number"
                        min={0}
                        step="0.01"
                        value={form.fondoCaja}
                        onChange={(e) => setForm({ ...form, fondoCaja: Number(e.target.value) })}
                        disabled={!isEditing || !form.manejaFondo}
                      />
                    </label>

                    {/* Fechas operativas: solo en modo vista con registro existente */}
                    {!isEditing && selected && (
                      <>
                        <label>
                          <span>Fecha Apertura</span>
                          <input value={selected.fechaApertura || "---"} disabled />
                        </label>
                        <label>
                          <span>Fecha Cierre</span>
                          <input value={selected.fechaCierre || "---"} disabled />
                        </label>
                      </>
                    )}
                  </div>
                </div>
              )}

              {/* Tab Usuarios */}
              {tab === "users" && (
                <div className="inv-doc-users">
                  <div className="price-lists-tabs inv-doc-users__subtabs">
                    <button
                      type="button"
                      className={usersSubTab === "assigned" ? "filter-pill is-active" : "filter-pill"}
                      onClick={() => setUsersSubTab("assigned")}
                    >
                      Asignados ({assignedUsers.length})
                    </button>
                    <button
                      type="button"
                      className={usersSubTab === "available" ? "filter-pill is-active" : "filter-pill"}
                      onClick={() => setUsersSubTab("available")}
                    >
                      Disponibles ({availableUsers.length})
                    </button>
                  </div>

                  {usersLoading ? (
                    <div className="inv-doc-users__loading"><Loader2 size={20} className="spin" /></div>
                  ) : (
                    <div className="roles-users-list">
                      {(usersSubTab === "assigned" ? assignedUsers : availableUsers).map(user => (
                        <article key={user.id} className="roles-user-item">
                          <span className="roles-user-avatar">
                            {(user.nombres[0] ?? user.username[0] ?? "U").toUpperCase()}
                          </span>
                          <div>
                            <p>{user.nombres || user.username}</p>
                            <small>@{user.username}</small>
                          </div>
                          {usersSubTab === "assigned" ? (
                            <button
                              type="button"
                              className="icon-button roles-user-action-btn roles-user-action-btn--remove"
                              title="Quitar"
                              onClick={() => void handleToggleUser(user.id, true)}
                            >
                              <UserMinus size={15} />
                            </button>
                          ) : (
                            <button
                              type="button"
                              className="icon-button roles-user-action-btn roles-user-action-btn--add"
                              title="Asignar"
                              onClick={() => void handleToggleUser(user.id, false)}
                            >
                              <UserPlus size={15} />
                            </button>
                          )}
                        </article>
                      ))}
                      {(usersSubTab === "assigned" ? assignedUsers : availableUsers).length === 0 && (
                        <p className="roles-empty">{usersSubTab === "assigned" ? "Sin usuarios asignados" : "Sin usuarios disponibles"}</p>
                      )}
                    </div>
                  )}
                </div>
              )}
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona una caja o crea una nueva</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Caja POS"
        itemName={deleteTarget?.descripcion ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
