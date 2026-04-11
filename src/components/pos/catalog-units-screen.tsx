"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, Loader2, MoreHorizontal, Pencil, Plus, Ruler, Save, Search, Trash2, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { useFormat } from "@/lib/format-context"
import type { UnitRecord } from "@/lib/pos-data"

type UnitForm = {
  id?: number
  name: string
  abbreviation: string
  baseA: number
  baseB: number
  active: boolean
}

const emptyForm: UnitForm = {
  name: "",
  abbreviation: "",
  baseA: 1,
  baseB: 1,
  active: true,
}

function recordToForm(r: UnitRecord): UnitForm {
  return {
    id: r.id,
    name: r.name,
    abbreviation: r.abbreviation,
    baseA: r.baseA,
    baseB: r.baseB,
    active: r.active,
  }
}

export function CatalogUnitsScreen({ initialData }: { initialData: UnitRecord[] }) {
  const router = useRouter()
  const { t } = useI18n()
  const { formatNumber, parseNumber } = useFormat()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<UnitRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(initialData[0]?.id ?? null)
  const [form, setForm] = useState<UnitForm>(initialData[0] ? recordToForm(initialData[0]) : emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<UnitRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    if (!query.trim()) return items
    const q = query.toLowerCase()
    return items.filter(
      (i) => i.name.toLowerCase().includes(q) || i.abbreviation.toLowerCase().includes(q),
    )
  }, [items, query])

  const selected = useMemo(() => items.find((i) => i.id === selectedId) || null, [items, selectedId])

  useEffect(() => {
    function onPointerDown(event: MouseEvent) {
      if (!menuRef.current?.contains(event.target as Node)) {
        setMenuId(null)
      }
    }
    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  useEffect(() => {
    if (selected) {
      setForm(recordToForm(selected))
      return
    }

    if (!isEditing) {
      setForm(emptyForm)
    }
  }, [isEditing, selected])

  function selectItem(id: number) {
    setSelectedId(id)
    setIsEditing(false)
    setMessage(null)
  }

  useEffect(() => {
    if (isEditing || selectedId != null || items.length === 0) return
    setSelectedId(items[0].id)
  }, [isEditing, items, selectedId])

  function openNew() {
    setSelectedId(null)
    setForm(emptyForm)
    setIsEditing(true)
    setMessage(null)
  }

  function openEdit(unit: UnitRecord) {
    setSelectedId(unit.id)
    setForm(recordToForm(unit))
    setIsEditing(true)
    setMenuId(null)
    setMessage(null)
  }

  function closeEditor() {
    setIsEditing(false)
    if (selected) {
      setForm(recordToForm(selected))
    } else {
      setForm(emptyForm)
    }
    setMessage(null)
  }

  async function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setMessage(null)

    if (!form.name.trim()) {
      setMessage("El nombre es obligatorio.")
      return
    }
    if (!form.abbreviation.trim()) {
      setMessage("La abreviatura es obligatoria.")
      return
    }

    startTransition(async () => {
      try {
        const url = form.id
          ? `${apiUrl("/api/catalog/units")}/${form.id}`
          : apiUrl("/api/catalog/units")
        const method = form.id ? "PUT" : "POST"

        const response = await fetch(url, {
          method,
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...form, name: (form.name || "").toUpperCase() }),
        })

        const result = (await response.json()) as { ok: boolean; message?: string; data?: UnitRecord }
        if (!response.ok || !result.ok) {
          setMessage(result.message ?? "No se pudo guardar.")
          return
        }

        toast.success(form.id ? "Unidad actualizada" : "Unidad creada")

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

  async function confirmDelete(id: number) {
    startTransition(async () => {
      try {
        const response = await fetch(`${apiUrl("/api/catalog/units")}/${id}`, {
          method: "DELETE",
          credentials: "include",
        })

        const result = (await response.json()) as { ok: boolean; message?: string }
        if (!response.ok || !result.ok) {
          toast.error(result.message ?? "No se pudo eliminar.")
          return
        }

        toast.success("Unidad eliminada")
        setItems((prev) => prev.filter((i) => i.id !== id))
        if (selectedId === id) {
          setSelectedId(null)
          setForm(emptyForm)
        }
        setDeleteTarget(null)
        setMenuId(null)
        router.refresh()
      } catch {
        toast.error("Error al eliminar.")
      }
    })
  }

  function duplicateItem(item: UnitRecord) {
    setSelectedId(null)
    setForm({
      ...recordToForm(item),
      id: undefined,
      name: `${item.name} COPIA`,
    })
    setIsEditing(true)
    setMenuId(null)
    setMessage(null)
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Ruler size={17} />
              <h2>Unidades de Medida</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva unidad">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar unidad..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.map((unit) => (
              <div
                key={unit.id}
                className={`price-lists-sidebar__item${selectedId === unit.id ? " is-selected" : ""}`}
                onClick={() => selectItem(unit.id)}
              >
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${unit.active ? " is-active" : " is-inactive"}`}>
                    {unit.active ? t("common.active") : t("common.inactive")}
                  </span>
                  <span className="price-lists-sidebar__code">{unit.abbreviation}</span>
                  <div className="price-lists-sidebar__menu-wrap">
                    <button
                      className="price-lists-sidebar__menu-btn"
                      type="button"
                      onClick={(e) => {
                        e.stopPropagation()
                        setMenuId(menuId === unit.id ? null : unit.id)
                      }}
                    >
                      <MoreHorizontal size={14} />
                    </button>
                    {menuId === unit.id && (
                      <ul className="price-lists-dropdown" ref={menuRef} onClick={(e) => e.stopPropagation()}>
                        <li>
                          <button type="button" onClick={() => openEdit(unit)}>
                            <Pencil size={13} /> {t("common.edit")}
                          </button>
                        </li>
                        <li>
                          <button type="button" onClick={() => duplicateItem(unit)}>
                            <Copy size={13} /> Duplicar
                          </button>
                        </li>
                        <li className="is-danger">
                          <button type="button" onClick={() => { setDeleteTarget(unit); setMenuId(null) }}>
                            <Trash2 size={13} /> {t("common.delete")}
                          </button>
                        </li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__desc">{unit.name}</p>
                  <p className="price-lists-sidebar__meta">
                    <Ruler size={11} /> {unit.baseA}/{unit.baseB} - Factor: {unit.factor}
                  </p>
              </div>
            ))}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              <div className="products-detail__action-bar">
                {isEditing ? (
                  <div className="products-detail__action-bar-btns">
                    <button type="button" className="secondary-button" onClick={closeEditor}>
                      <X size={16} />
                      {t("common.cancel")}
                    </button>
                    <button type="submit" className="primary-button" disabled={isPending}>
                      {isPending ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
                      {t("common.save")}
                    </button>
                  </div>
                ) : null}
              </div>

              {message && <div className="form-message">{message}</div>}

              <div className="form-grid">
                <div className="form-grid__row-with-toggle">
                  <label>
                    <span>Nombre *</span>
                    <input
                      value={form.name}
                      onChange={(e) => setForm({ ...form, name: e.target.value })}
                      disabled={!isEditing}
                      required
                    />
                  </label>
                  <label>
                    <span>Abreviatura *</span>
                    <input
                      value={form.abbreviation}
                      onChange={(e) => setForm({ ...form, abbreviation: e.target.value })}
                      disabled={!isEditing}
                      maxLength={20}
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

                <label>
                  <span>Base A</span>
                  <input
                    type="text"
                    inputMode="decimal"
                    value={formatNumber(form.baseA, 0)}
                    onChange={(e) => setForm({ ...form, baseA: parseNumber(e.target.value) || 1 })}
                    disabled={!isEditing}
                  />
                </label>

                <label>
                  <span>Base B</span>
                  <input
                    type="text"
                    inputMode="decimal"
                    value={formatNumber(form.baseB, 0)}
                    onChange={(e) => setForm({ ...form, baseB: parseNumber(e.target.value) || 1 })}
                    disabled={!isEditing}
                  />
                </label>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona una unidad de medida o crea una nueva</p>
            </div>
          )}
        </main>
      </div>

      {deleteTarget ? (
        <div className="modal-backdrop" onClick={() => setDeleteTarget(null)}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <Trash2 size={18} />
              </div>
              <div>
                <h3 className="modal-card__title">Eliminar</h3>
                <p className="modal-card__subtitle">Unidad de medida</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>
                Vas a eliminar la unidad <strong>{deleteTarget.name}</strong>. Esta accion no se puede deshacer.
              </p>
            </div>
            <div className="modal-card__footer">
              <button
                type="button"
                className="secondary-button"
                onClick={() => setDeleteTarget(null)}
                disabled={isPending}
              >
                Cancelar
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={() => void confirmDelete(deleteTarget.id)}
                disabled={isPending}
              >
                {isPending ? <Loader2 size={16} className="spin" /> : <Trash2 size={16} />}
                Eliminar
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  )
}

