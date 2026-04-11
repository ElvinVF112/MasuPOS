"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Tag, Trash2, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { TipoClienteOption } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

type ItemForm = { id?: number; code: string; name: string; active: boolean }
const emptyForm: ItemForm = { code: "", name: "", active: true }

function recordToForm(r: TipoClienteOption): ItemForm {
  return { id: r.id, code: r.code, name: r.name, active: r.active }
}

function duplicateRecordToForm(r: TipoClienteOption): ItemForm {
  return { code: "", name: `${r.name} COPIA`, active: r.active }
}

export function CatalogCustomerTypesScreen({ initialData }: { initialData: TipoClienteOption[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<TipoClienteOption[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<ItemForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<TipoClienteOption | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.name.toLowerCase().includes(q) || i.code.toLowerCase().includes(q)) : items
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
      setMenuId(null)
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function openEdit(item: TipoClienteOption) {
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

  function duplicateItem(item: TipoClienteOption) {
    const run = () => {
      setSelectedId(null)
      setForm(duplicateRecordToForm(item))
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
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
        const url = form.id ? `${apiUrl("/api/cxc/customer-types")}/${form.id}` : apiUrl("/api/cxc/customer-types")
        const res = await fetch(url, { method: form.id ? "PUT" : "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ ...form, name: (form.name || "").toUpperCase() }) })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: TipoClienteOption }
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
    if (!confirm("¿Eliminar este tipo de cliente?")) return
    startTransition(async () => {
      try {
        const res = await fetch(`${apiUrl("/api/cxc/customer-types")}/${id}`, { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Tipo eliminado")
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
              <Tag size={17} />
              <h2>Tipos de Cliente</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo tipo">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar tipo..."
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
                <p className="price-lists-sidebar__desc">{item.name}</p>
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="price-lists-form__header">
                <h3>{form.id ? form.name : "Nuevo Tipo de Cliente"}</h3>
                <div className="price-lists-form__actions">
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

              {message && <div className="form-message">{message}</div>}

              <div className="form-grid">
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
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    disabled={!isEditing}
                    maxLength={80}
                    required
                  />
                </label>

                <label className="price-lists-active-toggle">
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
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona un tipo de cliente o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Tipo de Cliente"
        itemName={deleteTarget?.name ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
