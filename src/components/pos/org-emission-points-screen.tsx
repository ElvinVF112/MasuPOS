"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, X, Zap } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import type { BranchRecord, EmissionPointRecord, FacTipoDocumentoRecord, PriceListRecord, TerceroRecord } from "@/lib/pos-data"

type EmissionPointForm = {
  id?: number
  branchId: string
  name: string
  code: string
  defaultPriceListId: string
  defaultPosDocumentTypeId: string
  defaultPosCustomerId: string
  active: boolean
}

const emptyForm: EmissionPointForm = {
  branchId: "",
  name: "",
  code: "",
  defaultPriceListId: "",
  defaultPosDocumentTypeId: "",
  defaultPosCustomerId: "",
  active: true,
}

function recordToForm(r: EmissionPointRecord): EmissionPointForm {
  return {
    id: r.id,
    branchId: String(r.branchId),
    name: r.name,
    code: r.code,
    defaultPriceListId: r.defaultPriceListId ? String(r.defaultPriceListId) : "",
    defaultPosDocumentTypeId: r.defaultPosDocumentTypeId ? String(r.defaultPosDocumentTypeId) : "",
    defaultPosCustomerId: r.defaultPosCustomerId ? String(r.defaultPosCustomerId) : "",
    active: r.active,
  }
}

function duplicateRecordToForm(r: EmissionPointRecord): EmissionPointForm {
  return {
    branchId: String(r.branchId),
    name: `${r.name} COPIA`,
    code: "",
    defaultPriceListId: r.defaultPriceListId ? String(r.defaultPriceListId) : "",
    defaultPosDocumentTypeId: r.defaultPosDocumentTypeId ? String(r.defaultPosDocumentTypeId) : "",
    defaultPosCustomerId: r.defaultPosCustomerId ? String(r.defaultPosCustomerId) : "",
    active: r.active,
  }
}

export function OrgEmissionPointsScreen({
  initialData,
  branches,
  priceLists,
  customers,
  documentTypes,
}: {
  initialData: EmissionPointRecord[]
  branches: BranchRecord[]
  priceLists: PriceListRecord[]
  customers: TerceroRecord[]
  documentTypes: FacTipoDocumentoRecord[]
}) {
  const router = useRouter()
  const { t } = useI18n()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<EmissionPointRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<EmissionPointForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<EmissionPointRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q
      ? items.filter((i) =>
          i.name.toLowerCase().includes(q)
          || i.code.toLowerCase().includes(q)
          || i.branchName.toLowerCase().includes(q),
        )
      : items
  }, [items, query])

  const selected = useMemo(() => items.find((i) => i.id === selectedId) ?? null, [items, selectedId])

  useEffect(() => {
    function onDown(e: MouseEvent) {
      if (!menuRef.current?.contains(e.target as Node)) setMenuId(null)
    }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  useEffect(() => {
    setForm(selected ? recordToForm(selected) : emptyForm)
    setIsEditing(false)
    setMessage(null)
  }, [selected])

  function openNew() {
    setSelectedId(null)
    setForm(emptyForm)
    setIsEditing(true)
    setMessage(null)
  }

  function openEdit(item: EmissionPointRecord) {
    setSelectedId(item.id)
    setIsEditing(true)
    setMenuId(null)
    setMessage(null)
  }

  function duplicateItem(item: EmissionPointRecord) {
    setSelectedId(null)
    setForm(duplicateRecordToForm(item))
    setIsEditing(true)
    setMenuId(null)
    setMessage(null)
  }

  function closeEditor() {
    setIsEditing(false)
    setForm(selected ? recordToForm(selected) : emptyForm)
    setMessage(null)
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.name.trim()) {
      setMessage("El nombre es obligatorio.")
      return
    }
    if (!form.branchId) {
      setMessage("Selecciona una sucursal.")
      return
    }

    const payload = {
      ...form,
      branchId: Number(form.branchId),
      defaultPriceListId: form.defaultPriceListId ? Number(form.defaultPriceListId) : null,
      defaultPosDocumentTypeId: form.defaultPosDocumentTypeId ? Number(form.defaultPosDocumentTypeId) : null,
      defaultPosCustomerId: form.defaultPosCustomerId ? Number(form.defaultPosCustomerId) : null,
      name: (form.name || "").toUpperCase(),
    }

    startTransition(async () => {
      try {
        const url = form.id ? `${apiUrl("/api/org/emission-points")}/${form.id}` : apiUrl("/api/org/emission-points")
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: EmissionPointRecord }
        if (!res.ok || !result.ok) {
          setMessage(result.message ?? "No se pudo guardar.")
          return
        }
        toast.success(form.id ? "Punto de emision actualizado" : "Punto de emision creado")
        if (form.id) {
          setItems((prev) => prev.map((i) => (i.id === form.id ? result.data! : i)))
        } else {
          setItems((prev) => [...prev, result.data!])
          setSelectedId(result.data!.id)
        }
        setIsEditing(false)
        router.refresh()
      } catch {
        setMessage("Error al guardar.")
      }
    })
  }

  async function handleDelete(id: number) {
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/org/emission-points")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) {
          toast.error(result.message ?? "No se pudo eliminar.")
          return
        }
        toast.success("Punto de emision eliminado")
        setItems((prev) => prev.filter((i) => i.id !== id))
        if (selectedId === id) {
          setSelectedId(null)
          setForm(emptyForm)
        }
        setMenuId(null)
        setDeleteTarget(null)
        router.refresh()
      } catch {
        toast.error("Error al eliminar.")
      }
    })
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title"><Zap size={17} /><h2>Puntos de Emision</h2></div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo punto"><Plus size={15} /></button>
          </div>
          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder="Buscar punto..." value={query} onChange={(e) => setQuery(e.target.value)} />
          </div>
          <div className="price-lists-sidebar__list">
            {filteredItems.map((item) => (
              <div key={item.id} className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`} onClick={() => setSelectedId(item.id)}>
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>{item.active ? t("common.active") : t("common.inactive")}</span>
                  {item.code && <span className="price-lists-sidebar__code">{item.code}</span>}
                  <div className="price-lists-sidebar__menu-wrap">
                    <button className="price-lists-sidebar__menu-btn" type="button" onClick={(e) => { e.stopPropagation(); setMenuId(menuId === item.id ? null : item.id) }}><MoreHorizontal size={14} /></button>
                    {menuId === item.id && (
                      <ul className="price-lists-dropdown" ref={menuRef} onClick={(e) => e.stopPropagation()}>
                        <li><button type="button" onClick={() => openEdit(item)}><Pencil size={13} /> {t("common.edit")}</button></li>
                        <li><button type="button" onClick={() => duplicateItem(item)}><Copy size={13} /> Duplicar</button></li>
                        <li className="is-danger"><button type="button" onClick={() => { setDeleteTarget(item); setMenuId(null) }}><Trash2 size={13} /> {t("common.delete")}</button></li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__desc">{item.name}</p>
                <p className="price-lists-sidebar__meta">{item.branchName} - {item.divisionName}</p>
                {item.defaultPriceListName && <p className="price-lists-sidebar__meta">{item.defaultPriceListName}</p>}
                {item.defaultPosDocumentTypeName && <p className="price-lists-sidebar__meta">Factura POS: {item.defaultPosDocumentTypeName}</p>}
                {item.defaultPosCustomerName && <p className="price-lists-sidebar__meta">Cliente POS: {item.defaultPosCustomerName}</p>}
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="price-lists-form__header">
                <h3>{form.id ? form.name : "Nuevo Punto de Emision"}</h3>
                <div className="price-lists-form__actions">
                  {isEditing ? (
                    <>
                      <button type="button" className="secondary-button" onClick={closeEditor}><X size={16} />{t("common.cancel")}</button>
                      <button type="submit" className="primary-button" disabled={isPending}>{isPending ? <Loader2 size={16} className="spin" /> : <Save size={16} />}{t("common.save")}</button>
                    </>
                  ) : (
                    <button type="button" className="secondary-button" onClick={() => setIsEditing(true)}><Pencil size={16} />{t("common.edit")}</button>
                  )}
                </div>
              </div>
              {message && <div className="form-message">{message}</div>}
              <div className="form-grid form-grid--spaced">
                <label>
                  <span>Sucursal *</span>
                  <select value={form.branchId} onChange={(e) => setForm({ ...form, branchId: e.target.value })} disabled={!isEditing} required>
                    <option value="">Selecciona</option>
                    {branches.map((b) => <option key={b.id} value={b.id}>{b.name} ({b.divisionName})</option>)}
                  </select>
                </label>
                <label>
                  <span>Nombre *</span>
                  <input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} disabled={!isEditing} required />
                </label>
                <label>
                  <span>Codigo</span>
                  <input value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} disabled={!isEditing} maxLength={20} placeholder="Ej: PE-001" />
                </label>
                <label>
                  <span>Lista de Precio Predeterminada</span>
                  <select value={form.defaultPriceListId} onChange={(e) => setForm({ ...form, defaultPriceListId: e.target.value })} disabled={!isEditing}>
                    <option value="">- Sin predeterminar -</option>
                    {priceLists.map((pl) => <option key={pl.id} value={pl.id}>{pl.description || pl.code}</option>)}
                  </select>
                </label>
                <label>
                  <span>Factura Predeterminada en POS</span>
                  <select value={form.defaultPosDocumentTypeId} onChange={(e) => setForm({ ...form, defaultPosDocumentTypeId: e.target.value })} disabled={!isEditing}>
                    <option value="">- Sin predeterminar -</option>
                    {documentTypes.map((item) => <option key={item.id} value={item.id}>{item.description}</option>)}
                  </select>
                </label>
                <label>
                  <span>Cliente Predeterminado en POS</span>
                  <select value={form.defaultPosCustomerId} onChange={(e) => setForm({ ...form, defaultPosCustomerId: e.target.value })} disabled={!isEditing}>
                    <option value="">- Sin predeterminar -</option>
                    {customers.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
                  </select>
                </label>
                <label className="company-active-toggle">
                  <span>Activo</span>
                  <button type="button" className={form.active ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, active: !form.active })} disabled={!isEditing}><span /></button>
                </label>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty"><Database size={48} opacity={0.3} /><p>Selecciona un punto de emision o crea uno nuevo</p></div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Punto de emision"
        itemName={deleteTarget?.name ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
