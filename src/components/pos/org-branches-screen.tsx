"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, GitBranch, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import type { BranchRecord, DivisionRecord } from "@/lib/pos-data"

type BranchForm = { id?: number; divisionId: string; name: string; description: string; address: string; active: boolean }

const emptyForm: BranchForm = { divisionId: "", name: "", description: "", address: "", active: true }

function recordToForm(r: BranchRecord): BranchForm {
  return { id: r.id, divisionId: String(r.divisionId), name: r.name, description: r.description, address: r.address, active: r.active }
}

function duplicateRecordToForm(r: BranchRecord): BranchForm {
  return { divisionId: String(r.divisionId), name: `${r.name} COPIA`, description: r.description, address: r.address, active: r.active }
}

export function OrgBranchesScreen({ initialData, divisions }: { initialData: BranchRecord[]; divisions: DivisionRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<BranchRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<BranchForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<BranchRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.name.toLowerCase().includes(q) || i.divisionName.toLowerCase().includes(q)) : items
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
  }, [selected])

  function openNew() { setSelectedId(null); setForm(emptyForm); setIsEditing(true); setMessage(null) }
  function openEdit(item: BranchRecord) { setSelectedId(item.id); setIsEditing(true); setMenuId(null); setMessage(null) }
  function duplicateItem(item: BranchRecord) { setSelectedId(null); setForm(duplicateRecordToForm(item)); setIsEditing(true); setMenuId(null); setMessage(null) }
  function closeEditor() { setIsEditing(false); setForm(selected ? recordToForm(selected) : emptyForm); setMessage(null) }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }
    if (!form.divisionId) { setMessage("Selecciona una division."); return }
    const payload = { ...form, divisionId: Number(form.divisionId), name: (form.name || "").toUpperCase(), description: (form.description || "").toUpperCase() }
    startTransition(async () => {
      try {
        const url = form.id ? `${apiUrl("/api/org/branches")}/${form.id}` : apiUrl("/api/org/branches")
        const res = await fetch(url, { method: form.id ? "PUT" : "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: BranchRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Sucursal actualizada" : "Sucursal creada")
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
    if (!confirm("¿Eliminar esta sucursal?")) return
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/org/branches")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Sucursal eliminada")
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
            <div className="price-lists-sidebar__title"><GitBranch size={17} /><h2>Sucursales</h2></div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva sucursal"><Plus size={15} /></button>
          </div>
          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder="Buscar sucursal..." value={query} onChange={e => setQuery(e.target.value)} />
          </div>
          <div className="price-lists-sidebar__list">
            {filteredItems.map(item => (
              <div key={item.id} className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`} onClick={() => setSelectedId(item.id)}>
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>{item.active ? t("common.active") : t("common.inactive")}</span>
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
                <p className="price-lists-sidebar__desc">{item.name}</p>
                <p className="price-lists-sidebar__meta">{item.divisionName}</p>
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="price-lists-form__header">
                <h3>{form.id ? form.name : "Nueva Sucursal"}</h3>
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
                  <span>Division *</span>
                  <select value={form.divisionId} onChange={e => setForm({ ...form, divisionId: e.target.value })} disabled={!isEditing} required>
                    <option value="">Selecciona</option>
                    {divisions.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
                  </select>
                </label>
                <label>
                  <span>Nombre *</span>
                  <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} disabled={!isEditing} required />
                </label>
                <label>
                  <span>Descripcion</span>
                  <input value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} disabled={!isEditing} />
                </label>
                <label className="form-grid__full">
                  <span>Direccion</span>
                  <input value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} disabled={!isEditing} />
                </label>
                <label className="company-active-toggle">
                  <span>Activo</span>
                  <button type="button" className={form.active ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, active: !form.active })} disabled={!isEditing}><span /></button>
                </label>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty"><Database size={48} opacity={0.3} /><p>Selecciona una sucursal o crea una nueva</p></div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Sucursal"
        itemName={deleteTarget?.name ?? deleteTarget?.description ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
