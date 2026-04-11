"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import {
  Database,
  Copy,
  Loader2,
  MoreHorizontal,
  Pencil,
  Phone,
  Plus,
  Save,
  Search,
  StickyNote,
  Trash2,
  User,
  Users,
  X,
} from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { CxPMaestrosData, TerceroRecord } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

type SupplierTab = "general" | "contacto" | "notas"

type SupplierForm = {
  id?: number
  code: string
  name: string
  shortName: string
  tipoPersona: string
  idTipoDocIdent: string
  documento: string
  idTipoProveedor: string
  idCategoriaProveedor: string
  // Contacto
  direccion: string
  ciudad: string
  telefono: string
  celular: string
  email: string
  web: string
  contacto: string
  telefonoContacto: string
  emailContacto: string
  notas: string
  active: boolean
}

const emptyForm: SupplierForm = {
  code: "",
  name: "",
  shortName: "",
  tipoPersona: "J",
  idTipoDocIdent: "",
  documento: "",
  idTipoProveedor: "",
  idCategoriaProveedor: "",
  direccion: "",
  ciudad: "",
  telefono: "",
  celular: "",
  email: "",
  web: "",
  contacto: "",
  telefonoContacto: "",
  emailContacto: "",
  notas: "",
  active: true,
}

function recordToForm(r: TerceroRecord): SupplierForm {
  return {
    id: r.id,
    code: r.code,
    name: r.name,
    shortName: r.shortName,
    tipoPersona: r.tipoPersona,
    idTipoDocIdent: r.idTipoDocIdent != null ? String(r.idTipoDocIdent) : "",
    documento: r.documento,
    idTipoProveedor: r.idTipoProveedor != null ? String(r.idTipoProveedor) : "",
    idCategoriaProveedor: r.idCategoriaProveedor != null ? String(r.idCategoriaProveedor) : "",
    direccion: r.direccion,
    ciudad: r.ciudad,
    telefono: r.telefono,
    celular: r.celular,
    email: r.email,
    web: r.web,
    contacto: r.contacto,
    telefonoContacto: r.telefonoContacto,
    emailContacto: r.emailContacto,
    notas: r.notas,
    active: r.active,
  }
}

function formToPayload(form: SupplierForm) {
  return {
    ...form,
    idTipoDocIdent: form.idTipoDocIdent ? Number(form.idTipoDocIdent) : null,
    idTipoProveedor: form.idTipoProveedor ? Number(form.idTipoProveedor) : null,
    idCategoriaProveedor: form.idCategoriaProveedor ? Number(form.idCategoriaProveedor) : null,
    esProveedor: true,
  }
}

function duplicateRecordToForm(r: TerceroRecord): SupplierForm {
  return {
    ...recordToForm(r),
    id: undefined,
    code: "",
    documento: "",
    shortName: r.shortName ? `${r.shortName} COPIA` : "",
    name: `${r.name} COPIA`,
  }
}

export function CxPSuppliersScreen({ data }: { data: CxPMaestrosData }) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<TerceroRecord[]>(data.suppliers)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<SupplierForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()
  const [tab, setTab] = useState<SupplierTab>("general")
  const [loadingDetail, setLoadingDetail] = useState(false)

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    if (!q) return items
    return items.filter(i =>
      i.name.toLowerCase().includes(q) ||
      i.code.toLowerCase().includes(q) ||
      i.documento.toLowerCase().includes(q)
    )
  }, [items, query])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])

  const selectedDocType = useMemo(() => {
    if (!form.idTipoDocIdent) return null
    return data.lookups.docTypes.find(d => String(d.id) === form.idTipoDocIdent) ?? null
  }, [form.idTipoDocIdent, data.lookups.docTypes])

  useEffect(() => {
    function onDown(e: MouseEvent) { if (!menuRef.current?.contains(e.target as Node)) setMenuId(null) }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  async function loadSupplierDetail(id: number) {
    setLoadingDetail(true)
    try {
      const res = await fetch(`${apiUrl("/api/cxp/suppliers")}/${id}`, { credentials: "include" })
      const result = (await res.json()) as { ok: boolean; data?: TerceroRecord }
      if (result.ok && result.data) {
        setForm(recordToForm(result.data))
        setItems(prev => prev.map(i => i.id === id ? result.data! : i))
      } else {
        setForm(selected ? recordToForm(selected) : emptyForm)
      }
    } catch {
      setForm(selected ? recordToForm(selected) : emptyForm)
    } finally {
      setLoadingDetail(false)
    }
    setIsEditing(false)
    setMessage(null)
    setTab("general")
  }

  useEffect(() => {
    if (selectedId) {
      loadSupplierDetail(selectedId)
    } else {
      setForm(emptyForm)
      setIsEditing(false)
      setMessage(null)
      setTab("general")
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedId])

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

  function openEdit(item: TerceroRecord) {
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

  function duplicateItem(item: TerceroRecord) {
    const run = () => {
      setSelectedId(null)
      setForm(duplicateRecordToForm(item))
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

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      setForm(selected ? recordToForm(selected) : emptyForm)
      setMessage(null)
      setDirty(false)
    })
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.code.trim()) { setMessage("El codigo es obligatorio."); return }
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }
    startTransition(async () => {
      try {
        const url = form.id ? `${apiUrl("/api/cxp/suppliers")}/${form.id}` : apiUrl("/api/cxp/suppliers")
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(formToPayload(form)),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: TerceroRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Proveedor actualizado" : "Proveedor creado")
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
    if (!confirm("¿Eliminar este proveedor?")) return
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/cxp/suppliers")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Proveedor eliminado")
        setItems(prev => prev.filter(i => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm(emptyForm) }
        setMenuId(null)
        router.refresh()
      } catch { toast.error("Error al eliminar.") }
    })
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        {/* ── Sidebar ── */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Users size={17} />
              <h2>Proveedores</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo proveedor">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar nombre, codigo, documento..."
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
                          <button type="button" onClick={() => handleDelete(item.id)}>
                            <Trash2 size={13} /> {t("common.delete")}
                          </button>
                        </li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__item-name">{item.name}</p>
                <p className="price-lists-sidebar__meta">
                  {item.code}
                  {item.codigoDocIdent && item.documento && (
                    <> &middot; {item.codigoDocIdent} {item.documento}</>
                  )}
                </p>
              </div>
            ))}
          </div>
        </aside>

        {/* ── Main ── */}
        <main className="price-lists-main">
          {loadingDetail ? (
            <div className="price-lists-empty">
              <Loader2 size={32} className="spin" opacity={0.5} />
              <p>Cargando...</p>
            </div>
          ) : selected || isEditing ? (
            <form onSubmit={onSubmit} style={{ display: "flex", flexDirection: "column", height: "100%" }}>
              <div className="price-lists-detail__head">
                <div>
                  <h2>{form.id ? form.name : "Nuevo Proveedor"}</h2>
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

              {/* Tabs */}
              <div className="price-lists-tabs">
                <button type="button" className={tab === "general" ? "filter-pill is-active" : "filter-pill"} onClick={() => setTab("general")}>
                  <User size={13} /> General
                </button>
                <button type="button" className={tab === "contacto" ? "filter-pill is-active" : "filter-pill"} onClick={() => setTab("contacto")}>
                  <Phone size={13} /> Contacto
                </button>
                <button type="button" className={tab === "notas" ? "filter-pill is-active" : "filter-pill"} onClick={() => setTab("notas")}>
                  <StickyNote size={13} /> Notas
                </button>
              </div>

              {message && <div className="form-message" style={{ margin: "0.75rem 1.2rem 0" }}>{message}</div>}

              {/* Tab: General */}
              {tab === "general" && (
                <div className="price-lists-form">
                  <div className="form-grid form-grid--spaced">
                    <label>
                      <span>Codigo *</span>
                      <input
                        value={form.code}
                        onChange={(e) => setForm({ ...form, code: e.target.value })}
                        disabled={!isEditing}
                        maxLength={20}
                        required
                      />
                    </label>

                    <label>
                      <span>Nombre *</span>
                      <input
                        value={form.name}
                        onChange={(e) => setForm({ ...form, name: e.target.value })}
                        disabled={!isEditing}
                        maxLength={150}
                        required
                      />
                    </label>

                    <label>
                      <span>Nombre Corto</span>
                      <input
                        value={form.shortName}
                        onChange={(e) => setForm({ ...form, shortName: e.target.value })}
                        disabled={!isEditing}
                        maxLength={50}
                      />
                    </label>

                    <label>
                      <span>Tipo Persona</span>
                      <select
                        value={form.tipoPersona}
                        onChange={(e) => setForm({ ...form, tipoPersona: e.target.value })}
                        disabled={!isEditing}
                      >
                        <option value="J">J - Juridica</option>
                        <option value="F">F - Fisica</option>
                      </select>
                    </label>

                    <label>
                      <span>Tipo Documento</span>
                      <select
                        value={form.idTipoDocIdent}
                        onChange={(e) => setForm({ ...form, idTipoDocIdent: e.target.value })}
                        disabled={!isEditing}
                      >
                        <option value="">-- Sin tipo --</option>
                        {data.lookups.docTypes.map(d => (
                          <option key={d.id} value={String(d.id)}>{d.code} - {d.name}</option>
                        ))}
                      </select>
                    </label>

                    <label>
                      <span>Numero Documento</span>
                      <input
                        value={form.documento}
                        onChange={(e) => setForm({ ...form, documento: e.target.value })}
                        disabled={!isEditing}
                        maxLength={30}
                      />
                      {selectedDocType && (
                        <span className="cxc-field-hint">
                          Entre {selectedDocType.minLen} y {selectedDocType.maxLen} caracteres
                        </span>
                      )}
                    </label>

                    <label>
                      <span>Tipo Proveedor</span>
                      <select
                        value={form.idTipoProveedor}
                        onChange={(e) => setForm({ ...form, idTipoProveedor: e.target.value })}
                        disabled={!isEditing}
                      >
                        <option value="">-- Sin tipo --</option>
                        {data.lookups.supplierTypes.map(s => (
                          <option key={s.id} value={String(s.id)}>{s.code} - {s.name}</option>
                        ))}
                      </select>
                    </label>

                    <label>
                      <span>Categoria Proveedor</span>
                      <select
                        value={form.idCategoriaProveedor}
                        onChange={(e) => setForm({ ...form, idCategoriaProveedor: e.target.value })}
                        disabled={!isEditing}
                      >
                        <option value="">-- Sin categoria --</option>
                        {data.lookups.supplierCategories.map(c => (
                          <option key={c.id} value={String(c.id)}>{c.code} - {c.name}</option>
                        ))}
                      </select>
                    </label>

                    <label className="company-active-toggle">
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
                </div>
              )}

              {/* Tab: Contacto */}
              {tab === "contacto" && (
                <div className="price-lists-form">
                  <div className="form-grid form-grid--spaced">
                    <label className="form-grid__full">
                      <span>Direccion</span>
                      <input
                        value={form.direccion}
                        onChange={(e) => setForm({ ...form, direccion: e.target.value })}
                        disabled={!isEditing}
                        maxLength={300}
                      />
                    </label>

                    <label>
                      <span>Ciudad</span>
                      <input
                        value={form.ciudad}
                        onChange={(e) => setForm({ ...form, ciudad: e.target.value })}
                        disabled={!isEditing}
                        maxLength={100}
                      />
                    </label>

                    <label>
                      <span>Telefono</span>
                      <input
                        value={form.telefono}
                        onChange={(e) => setForm({ ...form, telefono: e.target.value })}
                        disabled={!isEditing}
                        maxLength={30}
                      />
                    </label>

                    <label>
                      <span>Celular</span>
                      <input
                        value={form.celular}
                        onChange={(e) => setForm({ ...form, celular: e.target.value })}
                        disabled={!isEditing}
                        maxLength={30}
                      />
                    </label>

                    <label>
                      <span>Email</span>
                      <input
                        type="email"
                        value={form.email}
                        onChange={(e) => setForm({ ...form, email: e.target.value })}
                        disabled={!isEditing}
                        maxLength={150}
                      />
                    </label>

                    <label>
                      <span>Sitio Web</span>
                      <input
                        value={form.web}
                        onChange={(e) => setForm({ ...form, web: e.target.value })}
                        disabled={!isEditing}
                        maxLength={200}
                      />
                    </label>

                    <label>
                      <span>Contacto</span>
                      <input
                        value={form.contacto}
                        onChange={(e) => setForm({ ...form, contacto: e.target.value })}
                        disabled={!isEditing}
                        maxLength={100}
                      />
                    </label>

                    <label>
                      <span>Telefono Contacto</span>
                      <input
                        value={form.telefonoContacto}
                        onChange={(e) => setForm({ ...form, telefonoContacto: e.target.value })}
                        disabled={!isEditing}
                        maxLength={30}
                      />
                    </label>

                    <label>
                      <span>Email Contacto</span>
                      <input
                        type="email"
                        value={form.emailContacto}
                        onChange={(e) => setForm({ ...form, emailContacto: e.target.value })}
                        disabled={!isEditing}
                        maxLength={150}
                      />
                    </label>
                  </div>
                </div>
              )}

              {/* Tab: Notas */}
              {tab === "notas" && (
                <div className="price-lists-form" style={{ flex: 1, display: "flex", flexDirection: "column" }}>
                  <textarea
                    value={form.notas}
                    onChange={(e) => setForm({ ...form, notas: e.target.value })}
                    disabled={!isEditing}
                    placeholder="Notas internas sobre el proveedor..."
                    style={{ flex: 1, minHeight: "200px", resize: "vertical", width: "100%", padding: "0.6rem 0.75rem", borderRadius: "0.45rem", border: "1px solid #cbd5e1", fontSize: "0.875rem", lineHeight: "1.5", fontFamily: "inherit" }}
                  />
                </div>
              )}
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona un proveedor o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>
    </section>
  )
}
