"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, Warehouse, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import type { WarehouseRecord } from "@/lib/pos-data"

type WarehouseType = "C" | "V" | "T" | "N" | "O"

const WAREHOUSE_TYPES: { value: WarehouseType; label: string }[] = [
  { value: "C", label: "Central" },
  { value: "V", label: "Venta" },
  { value: "T", label: "Tránsito" },
  { value: "N", label: "Consignación" },
  { value: "O", label: "Otro" },
]

type WarehouseForm = {
  id?: number
  description: string
  initials: string
  type: WarehouseType
  transitWarehouseId: number | null
  active: boolean
}

const emptyForm: WarehouseForm = { description: "", initials: "", type: "O", transitWarehouseId: null, active: true }

function recordToForm(r: WarehouseRecord): WarehouseForm {
  return {
    id: r.id,
    description: r.description,
    initials: r.initials,
    type: r.type,
    transitWarehouseId: r.transitWarehouseId,
    active: r.active,
  }
}

function duplicateRecordToForm(r: WarehouseRecord): WarehouseForm {
  return {
    description: `${r.description} COPIA`,
    initials: "",
    type: r.type,
    transitWarehouseId: r.transitWarehouseId,
    active: r.active,
  }
}

export function OrgWarehousesScreen({ initialData }: { initialData: WarehouseRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<WarehouseRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<WarehouseForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<WarehouseRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.description.toLowerCase().includes(q) || i.initials.toLowerCase().includes(q)) : items
  }, [items, query])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])
  const transitWarehouses = useMemo(
    () => items.filter((item) => item.type === "T" && item.active && item.id !== form.id),
    [form.id, items],
  )
  const requiresTransitWarehouse = form.type !== "T"

  const typeLabel = (t: WarehouseType) => WAREHOUSE_TYPES.find(wt => wt.value === t)?.label ?? t

  useEffect(() => {
    function onDown(e: MouseEvent) { if (!menuRef.current?.contains(e.target as Node)) setMenuId(null) }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  useEffect(() => {
    setForm(selected ? recordToForm(selected) : emptyForm)
    setIsEditing(false)
    setMessage(null)
  }, [selected])

  function openNew() { setSelectedId(null); setForm(emptyForm); setIsEditing(true); setMessage(null) }
  function openEdit(item: WarehouseRecord) { setSelectedId(item.id); setIsEditing(true); setMenuId(null); setMessage(null) }
  function duplicateItem(item: WarehouseRecord) { setSelectedId(null); setForm(duplicateRecordToForm(item)); setIsEditing(true); setMenuId(null); setMessage(null) }
  function closeEditor() { setIsEditing(false); setForm(selected ? recordToForm(selected) : emptyForm); setMessage(null) }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.description.trim()) { setMessage("La descripcion es obligatoria."); return }
    if (!form.initials.trim()) { setMessage("Las siglas son obligatorias."); return }
    if (requiresTransitWarehouse && !form.transitWarehouseId) { setMessage("Debe seleccionar un almacen de transito."); return }
    startTransition(async () => {
      try {
        const url = form.id ? `${apiUrl("/api/org/warehouses")}/${form.id}` : apiUrl("/api/org/warehouses")
        const payload = {
          ...form,
          description: (form.description || "").toUpperCase(),
          transitWarehouseId: requiresTransitWarehouse ? form.transitWarehouseId : null,
        }
        const res = await fetch(url, { method: form.id ? "PUT" : "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: WarehouseRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Almacen actualizado" : "Almacen creado")
        if (form.id) {
          setItems(prev => prev.map(i => i.id === form.id ? result.data! : i))
        } else {
          setItems(prev => [...prev, result.data!])
          setSelectedId(result.data!.id)
        }
        setIsEditing(false)
        router.refresh()
      } catch { setMessage("Error al guardar.") }
    })
  }

  async function handleDelete(id: number) {
    if (!confirm("¿Eliminar este almacen?")) return
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/org/warehouses")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Almacen eliminado")
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
            <div className="price-lists-sidebar__title"><Warehouse size={17} /><h2>Almacenes</h2></div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo almacen"><Plus size={15} /></button>
          </div>
          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder="Buscar almacen..." value={query} onChange={e => setQuery(e.target.value)} />
          </div>
          <div className="price-lists-sidebar__list">
            {filteredItems.map(item => (
              <div key={item.id} className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`} onClick={() => setSelectedId(item.id)}>
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>{item.active ? t("common.active") : t("common.inactive")}</span>
                  <span className="price-lists-sidebar__code">{item.initials}</span>
                  <div className="price-lists-sidebar__menu-wrap">
                    <button className="price-lists-sidebar__menu-btn" type="button" onClick={e => { e.stopPropagation(); setMenuId(menuId === item.id ? null : item.id) }}><MoreHorizontal size={14} /></button>
                    {menuId === item.id && (
                      <ul className="price-lists-dropdown" ref={menuRef} onClick={e => e.stopPropagation()}>
                        <li><button type="button" onClick={() => openEdit(item)}><Pencil size={13} /> {t("common.edit")}</button></li>
                        <li><button type="button" onClick={() => duplicateItem(item)}><Copy size={13} /> Duplicar</button></li>
                        <li className="is-danger"><button type="button" onClick={() => { setDeleteTarget(item); setMenuId(null) }}><Trash2 size={13} /> {t("common.delete")}</button></li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__desc">{item.description}</p>
                <p className="price-lists-sidebar__meta">{typeLabel(item.type)}</p>
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="price-lists-form__header">
                <h3>{form.id ? form.description : "Nuevo Almacen"}</h3>
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
                  <span>Descripcion *</span>
                  <input value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} disabled={!isEditing} required />
                </label>
                <label>
                  <span>Siglas *</span>
                  <input value={form.initials} onChange={e => setForm({ ...form, initials: e.target.value })} disabled={!isEditing} maxLength={20} required placeholder="Ej: ALM-01" />
                </label>
                <label className="form-grid__full">
                  <span>Tipo de Almacen</span>
                  <div className="warehouse-type-selector">
                    {WAREHOUSE_TYPES.map(wt => (
                      <button key={wt.value} type="button"
                        className={`warehouse-type-btn${form.type === wt.value ? " is-active" : ""}`}
                        onClick={() => isEditing && setForm({ ...form, type: wt.value })}
                        disabled={!isEditing}>
                        {wt.label}
                      </button>
                    ))}
                  </div>
                </label>
                {requiresTransitWarehouse ? (
                  <label className="form-grid__full">
                    <span>Almacen de Transito *</span>
                    <select
                      value={form.transitWarehouseId ?? ""}
                      onChange={e => setForm({ ...form, transitWarehouseId: e.target.value ? Number(e.target.value) : null })}
                      disabled={!isEditing}
                      required
                    >
                      <option value="">Selecciona un almacen de transito</option>
                      {transitWarehouses.map((warehouse) => (
                        <option key={warehouse.id} value={warehouse.id}>
                          {warehouse.description} ({warehouse.initials})
                        </option>
                      ))}
                    </select>
                  </label>
                ) : null}
                <label className="company-active-toggle">
                  <span>Activo</span>
                  <button type="button" className={form.active ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, active: !form.active })} disabled={!isEditing}><span /></button>
                </label>
                {!isEditing && selected ? (
                  <label className="form-grid__full">
                    <span>Almacen de Transito</span>
                    <input value={selected.transitWarehouseName || "No aplica"} disabled />
                  </label>
                ) : null}
              </div>
            </form>
          ) : (
            <div className="price-lists-empty"><Database size={48} opacity={0.3} /><p>Selecciona un almacen o crea uno nuevo</p></div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Almacen"
        itemName={deleteTarget?.description ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
