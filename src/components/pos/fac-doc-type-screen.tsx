"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, FileText, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, UserMinus, UserPlus, Users, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { CatalogoNCFRecord, FacTipoDocumentoRecord, FacTipoDocUsuarioRecord, FacTipoOperacion } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

type DetailTab = "general" | "users"
type UsersSubTab = "assigned" | "available"

type CurrencyOption = { id: number; code: string; name: string; symbol: string }

type ItemForm = {
  id?: number
  tipoOperacion: FacTipoOperacion
  description: string
  prefijo: string
  secuenciaInicial: number
  idMoneda: number | null
  aplicaPropina: boolean
  idCatalogoNCF: number | null
  afectaInventario: boolean
  reservaStock: boolean

  active: boolean
}

function recordToForm(r: FacTipoDocumentoRecord): ItemForm {
  return {
    id: r.id,
    tipoOperacion: r.tipoOperacion,
    description: r.description,
    prefijo: r.prefijo,
    secuenciaInicial: r.secuenciaInicial,
    idMoneda: r.idMoneda,
    aplicaPropina: r.aplicaPropina,
    idCatalogoNCF: r.idCatalogoNCF,
    afectaInventario: r.afectaInventario,
    reservaStock: r.reservaStock,
    active: r.active,
  }
}

function emptyForm(tipoOperacion: FacTipoOperacion): ItemForm {
  return {
    tipoOperacion,
    description: "",
    prefijo: "",
    secuenciaInicial: 1,
    idMoneda: null,
    aplicaPropina: false,
    idCatalogoNCF: null,
    afectaInventario: tipoOperacion === "K",
    reservaStock: tipoOperacion === "P",
    active: true,
  }
}

type Props = {
  tipoOperacion: FacTipoOperacion
  title: string
  initialData: FacTipoDocumentoRecord[]
  currencies: CurrencyOption[]
  catalogo: CatalogoNCFRecord[]
}

function getDocumentTypeLabel(tipoOperacion: FacTipoOperacion) {
  switch (tipoOperacion) {
    case "F":
      return "Tipo de factura"
    case "Q":
      return "Tipo de cotización"
    case "K":
      return "Tipo de conduce"
    case "P":
      return "Tipo de orden de pedido"
    default:
      return "Tipo de documento"
  }
}

export function FacDocTypeScreen({ tipoOperacion, title, initialData, currencies, catalogo }: Props) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<FacTipoDocumentoRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(initialData[0]?.id ?? null)
  const [form, setForm] = useState<ItemForm>(initialData[0] ? recordToForm(initialData[0]) : emptyForm(tipoOperacion))
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [tab, setTab] = useState<DetailTab>("general")
  const [usersSubTab, setUsersSubTab] = useState<UsersSubTab>("assigned")
  const [users, setUsers] = useState<FacTipoDocUsuarioRecord[]>([])
  const [usersLoading, setUsersLoading] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<FacTipoDocumentoRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.description.toLowerCase().includes(q)) : items
  }, [items, query])
  const entityLabel = useMemo(() => getDocumentTypeLabel(tipoOperacion), [tipoOperacion])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])
  const assignedUsers = useMemo(() => users.filter(u => u.assigned), [users])
  const availableUsers = useMemo(() => users.filter(u => !u.assigned), [users])

  useEffect(() => {
    function onDown(e: MouseEvent) { if (!menuRef.current?.contains(e.target as Node)) setMenuId(null) }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  useEffect(() => {
    if (selected) {
      setForm(recordToForm(selected))
      setMessage(null)
      setTab("general")
      setUsers([])
      return
    }

    if (!isEditing) {
      setForm(emptyForm(tipoOperacion))
      setMessage(null)
      setTab("general")
      setUsers([])
    }
  }, [isEditing, selected, tipoOperacion])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

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

  useEffect(() => {
    if (isEditing || selectedId != null || items.length === 0) return
    setSelectedId(items[0].id)
  }, [isEditing, items, selectedId])

  useEffect(() => {
    if (tab === "users" && selectedId != null) {
      void loadUsers(selectedId)
    }
  }, [tab, selectedId])

  async function loadUsers(id: number) {
    setUsersLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/config/facturacion/doc-types/${id}?section=users`), { credentials: "include" })
      const result = (await res.json()) as { ok: boolean; data?: FacTipoDocUsuarioRecord[]; message?: string }
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
      setForm(emptyForm(tipoOperacion))
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

  function openEdit(item: FacTipoDocumentoRecord) {
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
      setForm(selected ? recordToForm(selected) : emptyForm(tipoOperacion))
      setMessage(null)
      setDirty(false)
    })
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.description.trim()) { setMessage("La descripción es obligatoria."); return }
    if (form.secuenciaInicial < 1) { setMessage("La secuencia inicial debe ser mayor a 0."); return }

    startTransition(async () => {
      try {
        const url = form.id
          ? apiUrl(`/api/config/facturacion/doc-types/${form.id}`)
          : apiUrl("/api/config/facturacion/doc-types")
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            ...form,
            description: (form.description || "").toUpperCase(),
          }),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: FacTipoDocumentoRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }

        toast.success(form.id ? "Tipo actualizado" : "Tipo creado")
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
        const res = await fetch(apiUrl(`/api/config/facturacion/doc-types/${id}`), { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Tipo eliminado")
        setItems(prev => prev.filter(i => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm(emptyForm(tipoOperacion)) }
        setMenuId(null)
        setDeleteTarget(null)
        router.refresh()
      } catch { toast.error("Error al eliminar.") }
    })
  }

  function duplicateItem(item: FacTipoDocumentoRecord) {
    const run = () => {
      setSelectedId(null)
      setForm({
        ...recordToForm(item),
        id: undefined,
        description: `${item.description} COPIA`,
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

  async function handleToggleUser(userId: number, currentlyAssigned: boolean) {
    if (!selectedId) return
    const newIds = currentlyAssigned
      ? assignedUsers.filter(u => u.id !== userId).map(u => u.id)
      : [...assignedUsers.map(u => u.id), userId]

    try {
      const res = await fetch(apiUrl(`/api/config/facturacion/doc-types/${selectedId}`), {
        method: "PATCH",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userIds: newIds }),
      })
      const result = (await res.json()) as { ok: boolean; data?: FacTipoDocUsuarioRecord[] }
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
              <FileText size={17} />
              <h2>{title}</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo tipo">
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
              <p className="price-lists-empty-msg">No hay tipos configurados</p>
            )}
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
                <p className="price-lists-sidebar__desc">{item.description}</p>
                <p className="price-lists-sidebar__meta">
                  {item.prefijo ? `${item.prefijo}-` : ""}
                  {String(item.secuenciaInicial).padStart(4, "0")}
                  {item.simboloMoneda ? ` \u00b7 ${item.simboloMoneda}` : ""}
                </p>
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
                    <div className="form-grid__row-with-toggle">
                      <div className={`inv-doc-code-row${form.id ? "" : " is-new"}`}>
                        {form.id ? (
                          <label>
                            <span>ID</span>
                            <input value={form.id} disabled />
                          </label>
                        ) : null}

                        <label>
                          <span>Prefijo</span>
                          <input
                            value={form.prefijo}
                            onChange={(e) => setForm({ ...form, prefijo: e.target.value })}
                            disabled={!isEditing}
                            maxLength={10}
                            placeholder="Ej: FAC"
                          />
                        </label>

                        <label>
                          <span>Secuencia Inicial</span>
                          <input
                            type="number"
                            min={1}
                            value={form.secuenciaInicial}
                            onChange={(e) => setForm({ ...form, secuenciaInicial: Number(e.target.value) })}
                            disabled={!isEditing}
                          />
                        </label>
                      </div>
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

                    <label className="form-grid__full">
                      <span>Descripción *</span>
                      <input
                        value={form.description}
                        onChange={(e) => setForm({ ...form, description: e.target.value })}
                        disabled={!isEditing}
                        maxLength={250}
                        required
                      />
                    </label>

                    <label>
                      <span>Moneda</span>
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

                    <label className="form-grid__toggle">
                      <span>Aplica Propina 10%</span>
                      <button
                        type="button"
                        className={form.aplicaPropina ? "toggle-switch is-on" : "toggle-switch"}
                        onClick={() => isEditing && setForm((prev) => ({ ...prev, aplicaPropina: !prev.aplicaPropina }))}
                        disabled={!isEditing}
                      >
                        <span />
                      </button>
                    </label>

                    <label>
                      <span>Tipo de Comprobante NCF</span>
                      <select
                        value={form.idCatalogoNCF ?? ""}
                        onChange={(e) => setForm({ ...form, idCatalogoNCF: e.target.value ? Number(e.target.value) : null })}
                        disabled={!isEditing}
                      >
                        <option value="">Sin comprobante</option>
                        {catalogo.map(c => (
                          <option key={c.id} value={c.id}>{c.codigo} - {c.nombre}</option>
                        ))}
                      </select>
                    </label>

                    {/* Campos operativos - solo para Conduces (K), Cotizaciones (Q) y Órdenes de Pedido (P) */}
                    {(tipoOperacion === "K" || tipoOperacion === "P" || tipoOperacion === "Q") && (
                      <div className="form-grid__row-with-toggle" style={{ marginTop: "0.25rem" }}>
                        <label className="form-grid__toggle">
                          <span>Afecta Inventario</span>
                          <button type="button" className={form.afectaInventario ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm((prev) => ({ ...prev, afectaInventario: !prev.afectaInventario }))} disabled={!isEditing}><span /></button>
                        </label>
                        <label className="form-grid__toggle">
                          <span>Reserva Stock</span>
                          <button type="button" className={form.reservaStock ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm((prev) => ({ ...prev, reservaStock: !prev.reservaStock }))} disabled={!isEditing}><span /></button>
                        </label>
                      </div>
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
              <p>Selecciona un tipo o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel={entityLabel}
        itemName={deleteTarget?.description ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
