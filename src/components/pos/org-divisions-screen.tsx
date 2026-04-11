"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Layers, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import type { DivisionRecord } from "@/lib/pos-data"

type DivisionForm = { id?: number; name: string; description: string; active: boolean }

const emptyForm: DivisionForm = { name: "", description: "", active: true }

function recordToForm(r: DivisionRecord): DivisionForm {
  return { id: r.id, name: r.name, description: r.description, active: r.active }
}

function duplicateRecordToForm(r: DivisionRecord): DivisionForm {
  return { name: `${r.name} COPIA`, description: r.description, active: r.active }
}

export function OrgDivisionsScreen({ initialData }: { initialData: DivisionRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<DivisionRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<DivisionForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<DivisionRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.name.toLowerCase().includes(q)) : items
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
  function openEdit(item: DivisionRecord) { setSelectedId(item.id); setIsEditing(true); setMenuId(null); setMessage(null) }
  function duplicateItem(item: DivisionRecord) { setSelectedId(null); setForm(duplicateRecordToForm(item)); setIsEditing(true); setMenuId(null); setMessage(null) }
  function closeEditor() { setIsEditing(false); setForm(selected ? recordToForm(selected) : emptyForm); setMessage(null) }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }
    startTransition(async () => {
      try {
        const url = form.id ? `${apiUrl("/api/org/divisions")}/${form.id}` : apiUrl("/api/org/divisions")
        const res = await fetch(url, { method: form.id ? "PUT" : "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ...form, name: (form.name || "").toUpperCase(), description: (form.description || "").toUpperCase() }) })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: DivisionRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Division actualizada" : "Division creada")
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
    if (!confirm("¿Eliminar esta division?")) return
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/org/divisions")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Division eliminada")
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
            <div className="price-lists-sidebar__title"><Layers size={17} /><h2>Divisiones</h2></div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva division"><Plus size={15} /></button>
          </div>
          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder="Buscar division..." value={query} onChange={e => setQuery(e.target.value)} />
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
                        <li className="is-danger"><button type="button" onClick={() => handleDelete(item.id)}><Trash2 size={13} /> {t("common.delete")}</button></li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__desc">{item.name}</p>
                {item.description && <p className="price-lists-sidebar__meta">{item.description}</p>}
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="price-lists-form__header">
                <h3>{form.id ? form.name : "Nueva Division"}</h3>
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
              <div className="form-grid">
                <label className="form-grid__full">
                  <span>Nombre *</span>
                  <input value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} disabled={!isEditing} required />
                </label>
                <label className="form-grid__full">
                  <span>Descripcion</span>
                  <input value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} disabled={!isEditing} />
                </label>
                <label className="price-lists-active-toggle">
                  <span>Activo</span>
                  <button type="button" className={form.active ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, active: !form.active })} disabled={!isEditing}><span /></button>
                </label>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty"><Database size={48} opacity={0.3} /><p>Selecciona una division o crea una nueva</p></div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Division"
        itemName={deleteTarget?.name ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
