"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Loader2, MoreHorizontal, Pencil, Percent, Plus, Save, Search, Trash2, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { useFormat } from "@/lib/format-context"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import type { TaxRateRecord } from "@/lib/pos-data"

type TaxRateForm = { id?: number; name: string; rate: string; code: string; active: boolean }

const emptyForm: TaxRateForm = { name: "", rate: "0", code: "", active: true }

function recordToForm(r: TaxRateRecord): TaxRateForm {
  return { id: r.id, name: r.name, rate: String(r.rate), code: r.code, active: r.active }
}

function duplicateRecordToForm(r: TaxRateRecord): TaxRateForm {
  return { name: `${r.name} COPIA`, rate: String(r.rate), code: "", active: r.active }
}

export function OrgTaxRatesScreen({ initialData }: { initialData: TaxRateRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const { formatNumber, parseNumber } = useFormat()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<TaxRateRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<TaxRateForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<TaxRateRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.name.toLowerCase().includes(q) || i.code.toLowerCase().includes(q)) : items
  }, [items, query])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])

  useEffect(() => {
    function onPointerDown(e: MouseEvent) {
      if (!menuRef.current?.contains(e.target as Node)) setMenuId(null)
    }
    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  useEffect(() => {
    if (selected) setForm(recordToForm(selected))
    else setForm(emptyForm)
    setIsEditing(false)
    setMessage(null)
  }, [selected])

  function openNew() {
    setSelectedId(null)
    setForm(emptyForm)
    setIsEditing(true)
    setMessage(null)
  }

  function openEdit(item: TaxRateRecord) {
    setSelectedId(item.id)
    setMenuId(null)
    setIsEditing(true)
    setMessage(null)
  }

  function duplicateItem(item: TaxRateRecord) {
    setSelectedId(null)
    setForm(duplicateRecordToForm(item))
    setMenuId(null)
    setIsEditing(true)
    setMessage(null)
  }

  function closeEditor() {
    setIsEditing(false)
    if (selected) setForm(recordToForm(selected))
    else { setSelectedId(null); setForm(emptyForm) }
    setMessage(null)
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }
    if (!form.code.trim()) { setMessage("El código es obligatorio."); return }
    const payload = { name: form.name, rate: parseFloat(form.rate) || 0, code: form.code, active: form.active }
    startTransition(async () => {
      try {
        const url = form.id ? apiUrl(`/api/org/tax-rates/${form.id}`) : apiUrl("/api/org/tax-rates")
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        })
        const result = (await res.json()) as { ok: boolean; data?: TaxRateRecord; message?: string }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        const saved = result.data!
        setItems(prev => form.id ? prev.map(i => i.id === saved.id ? saved : i) : [...prev, saved])
        setSelectedId(saved.id)
        setIsEditing(false)
        toast.success(form.id ? "Tasa actualizada" : "Tasa creada")
        router.refresh()
      } catch { setMessage("Error al guardar.") }
    })
  }

  async function handleDelete(id: number) {
    if (!confirm("¿Eliminar esta tasa de impuesto?")) return
    startTransition(async () => {
      try {
        const res = await fetch(apiUrl(`/api/org/tax-rates/${id}`), {
          method: "DELETE", credentials: "include",
        })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Tasa eliminada")
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

        {/* ── Sidebar ── */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Percent size={17} />
              <h2>Tasas de Impuesto</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva tasa">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder="Buscar tasa..." value={query}
              onChange={(e) => setQuery(e.target.value)} />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.map((item) => (
              <div key={item.id}
                className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`}
                onClick={() => setSelectedId(item.id)}
              >
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                    {item.active ? t("common.active") : t("common.inactive")}
                  </span>
                  <div className="price-lists-sidebar__menu-wrap">
                    <button className="price-lists-sidebar__menu-btn" type="button"
                      onClick={(e) => { e.stopPropagation(); setMenuId(menuId === item.id ? null : item.id) }}>
                      <MoreHorizontal size={14} />
                    </button>
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
                <p className="price-lists-sidebar__meta">{item.code} · {formatNumber(item.rate, 4)}%</p>
              </div>
            ))}
          </div>
        </aside>

        {/* ── Detail ── */}
        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="price-lists-form__header">
                <div className="price-lists-sidebar__title">
                  <Percent size={17} />
                  <h3>{form.id ? form.name : "Nueva Tasa de Impuesto"}</h3>
                </div>
                <div className="price-lists-form__actions">
                  {isEditing ? (
                    <>
                      <button type="button" className="secondary-button" onClick={closeEditor}>
                        <X size={15} /> {t("common.cancel")}
                      </button>
                      <button type="submit" className="primary-button" disabled={isPending}>
                        {isPending ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
                        {t("common.save")}
                      </button>
                    </>
                  ) : (
                    <button type="button" className="secondary-button" onClick={() => setIsEditing(true)}>
                      <Pencil size={15} /> {t("common.edit")}
                    </button>
                  )}
                </div>
              </div>

              {message && <div className="form-message">{message}</div>}

              <div className="form-grid">
                <label className="form-grid__full">
                  <span>Nombre *</span>
                  <input value={form.name} disabled={!isEditing} required
                    onChange={(e) => setForm({ ...form, name: e.target.value })} />
                </label>
                <label>
                  <span>Código *</span>
                  <input value={form.code} disabled={!isEditing} required
                    placeholder="Ej: ITBIS18"
                    onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })} />
                </label>
                <label>
                  <span>Tasa % *</span>
                  <input type="text" inputMode="decimal" value={formatNumber(parseFloat(form.rate) || 0, 4)} disabled={!isEditing} required
                    onChange={(e) => setForm({ ...form, rate: String(parseNumber(e.target.value)) })} />
                </label>
                <label className="form-grid__full" style={{ flexDirection: "row", alignItems: "center", gap: "0.75rem" }}>
                  <span>Activo</span>
                  <button type="button"
                    className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                    onClick={() => isEditing && setForm({ ...form, active: !form.active })}
                    disabled={!isEditing}>
                    <span />
                  </button>
                </label>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty">
              <Percent size={40} />
              <p>Selecciona una tasa de impuesto o crea una nueva</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Tasa de impuesto"
        itemName={deleteTarget?.name ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
