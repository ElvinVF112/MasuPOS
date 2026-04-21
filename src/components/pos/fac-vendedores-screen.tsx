"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Briefcase, Copy, Database, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { VendedorRecord } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

type ItemForm = {
  id?: number
  code: string
  nombre: string
  apellido: string
  email: string
  telefono: string
  comisionPct: string
  active: boolean
}

const emptyForm: ItemForm = {
  code: "",
  nombre: "",
  apellido: "",
  email: "",
  telefono: "",
  comisionPct: "0",
  active: true,
}

function recordToForm(r: VendedorRecord): ItemForm {
  return {
    id: r.id,
    code: r.code,
    nombre: r.nombre,
    apellido: r.apellido,
    email: r.email,
    telefono: r.telefono,
    comisionPct: String(r.comisionPct),
    active: r.active,
  }
}

function duplicateRecordToForm(r: VendedorRecord): ItemForm {
  return {
    code: "",
    nombre: `${r.nombre} COPIA`,
    apellido: r.apellido,
    email: "",
    telefono: r.telefono,
    comisionPct: String(r.comisionPct),
    active: r.active,
  }
}

export function FacVendedoresScreen({ initialData }: { initialData: VendedorRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<VendedorRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<ItemForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<VendedorRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q
      ? items.filter(i =>
          i.nombre.toLowerCase().includes(q) ||
          i.apellido.toLowerCase().includes(q) ||
          i.code.toLowerCase().includes(q)
        )
      : items
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

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  function selectItem(id: number) {
    const run = () => setSelectedId(id)
    if (isEditing && selectedId !== id) { confirmAction(run); return }
    run()
  }

  function openNew() {
    const run = () => {
      setSelectedId(null)
      setForm(emptyForm)
      setIsEditing(true)
      setMessage(null)
      setMenuId(null)
    }
    if (isEditing) { confirmAction(run); return }
    run()
  }

  function openEdit(item: VendedorRecord) {
    const run = () => {
      setSelectedId(item.id)
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
    }
    if (isEditing && selectedId !== item.id) { confirmAction(run); return }
    run()
  }

  function duplicateItem(item: VendedorRecord) {
    const run = () => {
      setSelectedId(null)
      setForm(duplicateRecordToForm(item))
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
    }
    if (isEditing) { confirmAction(run); return }
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
    if (!form.nombre.trim()) { setMessage("El nombre es obligatorio."); return }
    startTransition(async () => {
      try {
        const url = form.id
          ? `${apiUrl("/api/facturacion/vendedores")}/${form.id}`
          : apiUrl("/api/facturacion/vendedores")
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            ...form,
            comisionPct: Number(form.comisionPct) || 0,
          }),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: VendedorRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Vendedor actualizado" : "Vendedor creado")
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
        const res = await fetch(`${apiUrl("/api/facturacion/vendedores")}/${id}`, {
          method: "DELETE",
          credentials: "include",
        })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Vendedor eliminado")
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
              <Briefcase size={17} />
              <h2>Vendedores</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo vendedor">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar vendedor..."
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
                <p className="price-lists-sidebar__desc">{item.nombre} {item.apellido}</p>
                {item.comisionPct > 0 && (
                  <p className="price-lists-sidebar__meta">{item.comisionPct}% comisión</p>
                )}
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form onSubmit={onSubmit}>
              <div className="price-lists-detail__head">
                <div>
                  <h2>{form.id ? `${form.nombre} ${form.apellido}`.trim() : "Nuevo Vendedor"}</h2>
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

              {message && <div className="form-message" style={{ margin: "0.75rem 1.2rem 0" }}>{message}</div>}

              <div className="price-lists-form">
                <div className="form-grid form-grid--spaced" style={{ gridTemplateColumns: "20% 1fr 1fr" }}>
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
                      value={form.nombre}
                      onChange={(e) => setForm({ ...form, nombre: e.target.value })}
                      disabled={!isEditing}
                      maxLength={80}
                      required
                    />
                  </label>

                  <label>
                    <span>Apellido</span>
                    <input
                      value={form.apellido}
                      onChange={(e) => setForm({ ...form, apellido: e.target.value })}
                      disabled={!isEditing}
                      maxLength={80}
                    />
                  </label>

                  <label>
                    <span>Comisión (%)</span>
                    <input
                      type="number"
                      min={0}
                      max={100}
                      step={0.01}
                      value={form.comisionPct}
                      onChange={(e) => setForm({ ...form, comisionPct: e.target.value })}
                      disabled={!isEditing}
                    />
                  </label>

                  <label>
                    <span>Email</span>
                    <input
                      type="email"
                      value={form.email}
                      onChange={(e) => setForm({ ...form, email: e.target.value })}
                      disabled={!isEditing}
                      maxLength={120}
                    />
                  </label>

                  <label>
                    <span>Teléfono</span>
                    <input
                      value={form.telefono}
                      onChange={(e) => setForm({ ...form, telefono: e.target.value })}
                      disabled={!isEditing}
                      maxLength={30}
                    />
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
                </div>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona un vendedor o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Vendedor"
        itemName={deleteTarget ? `${deleteTarget.nombre} ${deleteTarget.apellido}`.trim() : ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
