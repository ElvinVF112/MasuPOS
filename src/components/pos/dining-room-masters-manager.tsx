"use client"

import { type CSSProperties, type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Layers3, MoreHorizontal, Pencil, Plus, Save, Search, Shapes, Tag, Trash2, XCircle } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import type { AdminEntityName, DiningMastersData } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

type DiningMasterSection = "areas" | "resource-types" | "resource-categories"

type FieldOption = { value: string; label: string }

type FieldConfig =
  | { name: string; label: string; type: "text" | "textarea" | "number" }
  | { name: string; label: string; type: "select"; options: FieldOption[] }
  | { name: string; label: string; type: "color" }
  | { name: string; label: string; type: "checkbox" }

type MasterMeta = {
  title: string
  icon: typeof Layers3
}

const masterMeta: Record<DiningMasterSection, MasterMeta> = {
  areas: { title: "Areas", icon: Layers3 },
  "resource-types": { title: "Tipos de recurso", icon: Shapes },
  "resource-categories": { title: "Categorias de recurso", icon: Tag },
}

const salonCategoryColors = [
  "#1e3a5f", "#12467e", "#2563eb", "#0f766e", "#059669", "#16a34a", "#65a30d", "#ca8a04",
  "#ea580c", "#dc2626", "#db2777", "#9333ea", "#7c3aed", "#475569", "#0ea5e9", "#f97316",
  "#f8fafc", "#f1f5f9", "#e2e8f0", "#cbd5e1", "#94a3b8", "#64748b", "#334155", "#1e293b",
  "#0f172a", "#000000", "#14532d", "#166534", "#15803d", "#22c55e", "#86efac", "#fef9c3",
  "#7c2d12", "#9a3412", "#c2410c", "#fb923c", "#fdba74", "#ffedd5", "#4c1d95",
  "#5b21b6", "#6d28d9", "#8b5cf6", "#a78bfa", "#c4b5fd", "#ede9fe",
]

const salonShapeOptions: FieldOption[] = [
  { value: "square", label: "Cuadrada" },
  { value: "round", label: "Redonda" },
  { value: "lounge", label: "Lounge" },
  { value: "bar", label: "Barra" },
]

type MasterCrudProps<T extends Record<string, unknown>> = {
  title: string
  entity: AdminEntityName
  icon: typeof Layers3
  items: T[]
  getId: (item: T) => number
  getTitle: (item: T) => string
  getMeta: (item: T) => string
  getAccentColor?: (item: T) => string | null
  searchPlaceholder: string
  fields: FieldConfig[]
  toForm: (item: T) => Record<string, unknown>
  emptyForm: Record<string, unknown>
}

function SalonShapePreview({ shape, color }: { shape: string; color: string }) {
  const safeColor = /^#[0-9a-fA-F]{6}$/.test(color) ? color : "#10b981"
  const variant = (shape || "square").toLowerCase()

  if (variant === "bar") {
    return (
      <div className="salon-shape-preview salon-shape-preview--bar" style={{ "--preview-color": safeColor } as CSSProperties}>
        <span className="salon-shape-preview__seat salon-shape-preview__seat--top" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--bottom" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--left" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--right" />
        <span className="salon-shape-preview__table" />
      </div>
    )
  }

  if (variant === "round") {
    return (
      <div className="salon-shape-preview salon-shape-preview--round" style={{ "--preview-color": safeColor } as CSSProperties}>
        <span className="salon-shape-preview__seat salon-shape-preview__seat--top" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--bottom" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--left" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--right" />
        <span className="salon-shape-preview__table" />
      </div>
    )
  }

  if (variant === "lounge") {
    return (
      <div className="salon-shape-preview salon-shape-preview--lounge" style={{ "--preview-color": safeColor } as CSSProperties}>
        <span className="salon-shape-preview__seat salon-shape-preview__seat--top" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--bottom" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--left" />
        <span className="salon-shape-preview__seat salon-shape-preview__seat--right" />
        <span className="salon-shape-preview__table" />
      </div>
    )
  }

  return (
    <div className="salon-shape-preview salon-shape-preview--square" style={{ "--preview-color": safeColor } as CSSProperties}>
      <span className="salon-shape-preview__seat salon-shape-preview__seat--top" />
      <span className="salon-shape-preview__seat salon-shape-preview__seat--bottom" />
      <span className="salon-shape-preview__seat salon-shape-preview__seat--left" />
      <span className="salon-shape-preview__seat salon-shape-preview__seat--right" />
      <span className="salon-shape-preview__table" />
    </div>
  )
}

function SalonMasterCrudSection<T extends Record<string, unknown>>({
  title,
  entity,
  icon: Icon,
  items,
  getId,
  getTitle,
  getMeta,
  getAccentColor,
  searchPlaceholder,
  fields,
  toForm,
  emptyForm,
}: MasterCrudProps<T>) {
  const router = useRouter()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [selectedId, setSelectedId] = useState<number | null>(items[0] ? getId(items[0]) : null)
  const [form, setForm] = useState<Record<string, unknown>>(items[0] ? toForm(items[0]) : emptyForm)
  const [search, setSearch] = useState("")
  const [message, setMessage] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [isPending, startTransition] = useTransition()
  const [showGenerateModal, setShowGenerateModal] = useState(false)
  const [generateForm, setGenerateForm] = useState({
    prefix: "",
    quantity: 5,
    startAt: 1,
    seats: 4,
    state: "Libre",
  })

  const selected = useMemo(() => items.find((item) => getId(item) === selectedId) ?? null, [items, selectedId, getId])

  const filteredItems = useMemo(() => {
    const term = search.trim().toLowerCase()
    if (!term) return items
    return items.filter((item) => {
      const haystack = `${getTitle(item)} ${getMeta(item)}`.toLowerCase()
      return haystack.includes(term)
    })
  }, [getMeta, getTitle, items, search])

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
    if (selected && !isEditing) {
      setForm(toForm(selected))
      return
    }
    if (!selectedId && !isEditing) {
      setForm(emptyForm)
    }
  }, [emptyForm, isEditing, selected, selectedId, toForm])

  useEffect(() => {
    if (isEditing || selectedId != null || items.length === 0) return
    setSelectedId(getId(items[0]))
  }, [getId, isEditing, items, selectedId])

  useEffect(() => {
    return () => setDirty(false)
  }, [setDirty])

  function buildDefaultPrefix(value: string) {
    const cleaned = value
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-zA-Z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .toUpperCase()
    return cleaned || "MESA"
  }

  useEffect(() => {
    if (entity !== "resource-categories") return
    const nextPrefix = selected ? buildDefaultPrefix(getTitle(selected)) : "MESA"
    setGenerateForm((current) => ({ ...current, prefix: nextPrefix || current.prefix }))
  }, [entity, selected, getTitle])

  function updateForm(name: string, value: unknown) {
    setForm((current) => ({ ...current, [name]: value }))
  }

  function openNew() {
    confirmAction(() => {
      setSelectedId(null)
      setForm(emptyForm)
      setIsEditing(true)
      setDirty(true)
      setMessage(null)
      setMenuId(null)
    })
  }

  function selectItem(id: number) {
    confirmAction(() => {
      setSelectedId(id)
      setIsEditing(false)
      setDirty(false)
      setMessage(null)
      setMenuId(null)
    })
  }

  function openEdit(itemId: number) {
    const item = items.find((candidate) => getId(candidate) === itemId)
    if (!item) return
    confirmAction(() => {
      setSelectedId(itemId)
      setForm(toForm(item))
      setIsEditing(true)
      setDirty(true)
      setMessage(null)
      setMenuId(null)
    })
  }

  function duplicateItem(itemId: number) {
    const item = items.find((candidate) => getId(candidate) === itemId)
    if (!item) return
    confirmAction(() => {
      const nextForm = { ...toForm(item), id: undefined, name: `Copia de ${String(item.name ?? getTitle(item))}` }
      setSelectedId(null)
      setForm(nextForm)
      setIsEditing(true)
      setDirty(true)
      setMessage(null)
      setMenuId(null)
    })
  }

  function deleteItem(itemId: number) {
    const item = items.find((candidate) => getId(candidate) === itemId)
    if (!item) return
    confirmAction(() => {
      startTransition(async () => {
        const response = await fetch(apiUrl(`/api/admin/${entity}`), {
          method: "DELETE",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id: itemId }),
        })
        const result = (await response.json()) as { ok: boolean; message?: string }
        if (!response.ok || !result.ok) {
          toast.error(result.message ?? "No se pudo eliminar el registro.")
          return
        }

        toast.success("Registro eliminado")
        setMenuId(null)
        setIsEditing(false)
        setDirty(false)
        setSelectedId((current) => (current === itemId ? null : current))
        router.refresh()
      })
    })
  }

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      setDirty(false)
      setMessage(null)
      setMenuId(null)
      if (selected) {
        setForm(toForm(selected))
      } else {
        setForm(emptyForm)
      }
    })
  }

  const canGenerateResources = entity === "resource-categories" && Boolean(selected)

  function openGenerateModal() {
    if (!selected) return
    setGenerateForm((current) => ({
      ...current,
      prefix: buildDefaultPrefix(getTitle(selected)),
    }))
    setShowGenerateModal(true)
  }

  function submitGenerateResources() {
    if (!selected) return

    startTransition(async () => {
      const response = await fetch(apiUrl("/api/dining-room/resource-categories/generate"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          categoryId: getId(selected),
          prefix: generateForm.prefix,
          quantity: generateForm.quantity,
          startAt: generateForm.startAt,
          seats: generateForm.seats,
          state: generateForm.state,
        }),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        toast.error(result.message ?? "No se pudieron generar los recursos.")
        return
      }

      toast.success("Recursos generados")
      setShowGenerateModal(false)
      router.refresh()
    })
  }

  function submit(method: "POST" | "PUT", payload: object) {
    setMessage(null)
    startTransition(async () => {
      const response = await fetch(apiUrl(`/api/admin/${entity}`), {
        method,
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        setMessage(result.message ?? "No se pudo completar la operacion.")
        return
      }

      setIsEditing(false)
      setDirty(false)
      setMessage(null)
      router.refresh()
    })
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const payload = { ...form }

    const invalidRequired = fields.some((field) => {
      if (field.type === "checkbox") return false
      return !String(payload[field.name] ?? "").trim()
    })

    if (invalidRequired) {
      setMessage("Completa los campos obligatorios.")
      return
    }

    submit(form.id ? "PUT" : "POST", payload)
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Icon size={17} />
              <h2>{title}</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo registro">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder={searchPlaceholder} value={search} onChange={(event) => setSearch(event.target.value)} />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.length ? (
              filteredItems.map((item) => (
                <div
                  key={getId(item)}
                  className={`price-lists-sidebar__item${selectedId === getId(item) ? " is-selected" : ""}`}
                  style={
                    getAccentColor
                      ? ({ "--salon-accent-color": getAccentColor(item) ?? "#d8e2ef" } as CSSProperties)
                      : undefined
                  }
                  onClick={() => selectItem(getId(item))}
                >
                  <div className="price-lists-sidebar__item-top">
                    <span className={`price-lists-badge${Boolean(item.active) ? " is-active" : " is-inactive"}`}>
                      {Boolean(item.active) ? "Activo" : "Inactivo"}
                    </span>
                    <div className="price-lists-sidebar__menu-wrap">
                      <button
                        className="price-lists-sidebar__menu-btn"
                        type="button"
                        aria-label="Abrir menu"
                        title="Mas acciones"
                        onClick={(event) => {
                          event.stopPropagation()
                          setMenuId(menuId === getId(item) ? null : getId(item))
                        }}
                      >
                        <MoreHorizontal size={16} strokeWidth={2.4} />
                      </button>
                      {menuId === getId(item) ? (
                        <ul className="price-lists-dropdown" ref={menuRef} onClick={(event) => event.stopPropagation()}>
                          <li>
                            <button type="button" onClick={() => openEdit(getId(item))}>
                              <Pencil size={13} /> Editar
                            </button>
                          </li>
                          <li>
                            <button type="button" onClick={() => duplicateItem(getId(item))}>
                              <Copy size={13} /> Duplicar
                            </button>
                          </li>
                          <li className="is-danger">
                            <button type="button" onClick={() => deleteItem(getId(item))}>
                              <Trash2 size={13} /> Eliminar
                            </button>
                          </li>
                        </ul>
                      ) : null}
                    </div>
                  </div>
                  <p className="price-lists-sidebar__desc">{getTitle(item)}</p>
                  <p className="price-lists-sidebar__meta">{getMeta(item)}</p>
                  {getAccentColor ? <span className="salon-master-accent" aria-hidden="true" /> : null}
                </div>
              ))
            ) : (
              <div className="price-lists-empty">
                <Icon size={42} opacity={0.3} />
                <p>No hay registros que coincidan con la busqueda</p>
              </div>
            )}
          </div>
        </aside>

        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={handleSubmit}>
              {isEditing ? (
                <div className="products-detail__action-bar">
                  <div className="products-detail__action-bar-btns">
                    <button type="button" className="secondary-button" onClick={closeEditor}>
                      <XCircle size={16} />
                      Cancelar
                    </button>
                    <button type="submit" className="primary-button" disabled={isPending}>
                      <Save size={16} />
                      Guardar
                    </button>
                  </div>
                </div>
              ) : null}

              {message ? <div className="form-message">{message}</div> : null}

              <div className="form-grid">
                {(() => {
                  const activeField = fields.find((field) => field.type === "checkbox" && field.name === "active")
                  const otherFields = fields.filter((field) => !(field.type === "checkbox" && field.name === "active"))
                  const isResourceCategories = entity === "resource-categories"

                  if (isResourceCategories) {
                    const colorValue = String(form.color ?? "#3b82f6") || "#3b82f6"
                    const areaField = fields.find((field): field is Extract<FieldConfig, { type: "select" }> => field.name === "areaId" && field.type === "select")
                    const typeField = fields.find((field): field is Extract<FieldConfig, { type: "select" }> => field.name === "typeId" && field.type === "select")
                    const shapeField = fields.find((field): field is Extract<FieldConfig, { type: "select" }> => field.name === "shape" && field.type === "select")

                    return (
                      <>
                        <div className="form-grid__row-with-toggle">
                          <label>
                            <span>Nombre *</span>
                            <input
                              type="text"
                              value={String(form.name ?? "")}
                              onChange={(event) => updateForm("name", event.target.value)}
                              disabled={!isEditing}
                            />
                          </label>
                          <label>
                            <span>Tipo</span>
                            <select value={String(form.typeId ?? "")} onChange={(event) => updateForm("typeId", event.target.value)} disabled={!isEditing}>
                              <option value="">Selecciona</option>
                              {typeField && typeField.options.map((option: FieldOption) => (
                                <option key={option.value} value={option.value}>{option.label}</option>
                              ))}
                            </select>
                          </label>
                          {activeField ? (
                            <label className="form-grid__toggle">
                              <span>{activeField.label}</span>
                              <button
                                type="button"
                                className={Boolean(form[activeField.name]) ? "toggle-switch is-on" : "toggle-switch"}
                                onClick={() => isEditing && updateForm(activeField.name, !Boolean(form[activeField.name]))}
                                disabled={!isEditing}
                              >
                                <span />
                              </button>
                            </label>
                          ) : null}
                        </div>

                        <div className="form-grid__full salon-category-top-row">
                          <label>
                            <span>Area</span>
                            <select value={String(form.areaId ?? "")} onChange={(event) => updateForm("areaId", event.target.value)} disabled={!isEditing}>
                              <option value="">Selecciona</option>
                              {areaField && areaField.options.map((option: FieldOption) => (
                                <option key={option.value} value={option.value}>{option.label}</option>
                              ))}
                            </select>
                          </label>
                          <label className="salon-shape-select-field">
                            <span>Forma visual</span>
                            <select
                              className="salon-shape-select"
                              value={String(form.shape ?? "")}
                              onChange={(event) => updateForm("shape", event.target.value)}
                              disabled={!isEditing}
                            >
                              <option value="">Selecciona</option>
                              {shapeField && shapeField.options.map((option: FieldOption) => (
                                <option key={option.value} value={option.value}>{option.label}</option>
                              ))}
                            </select>
                          </label>
                          {canGenerateResources ? (
                            <div className="salon-category-top-row__action">
                              <button type="button" className="ghost-button salon-inline-actions__button" onClick={openGenerateModal}>
                                <Plus size={15} />
                                Generar recursos
                              </button>
                            </div>
                          ) : null}
                        </div>

                        <label className="form-grid__full salon-color-field">
                          <div className="color-picker">
                            <span className="color-picker__label">Color base</span>
                            <div className="salon-color-layout">
                              <div className="color-picker__swatches salon-color-grid">
                                {salonCategoryColors.map((preset) => (
                                  <button
                                    key={preset}
                                    type="button"
                                    className={`color-picker__swatch${colorValue.toLowerCase() === preset.toLowerCase() ? " is-selected" : ""}`}
                                    style={{ background: preset } as CSSProperties}
                                    onClick={() => isEditing && updateForm("color", preset)}
                                    disabled={!isEditing}
                                    aria-label={`Usar color ${preset}`}
                                    title={preset}
                                  />
                                ))}
                              </div>
                              <div className="salon-color-layout__side">
                                <div className="color-picker__actions">
                                  <div className="color-picker__preview-wrap">
                                    <input
                                      type="text"
                                      className="color-picker__hex"
                                      value={colorValue}
                                      onChange={(event) => updateForm("color", event.target.value)}
                                      disabled={!isEditing}
                                      maxLength={7}
                                      placeholder="#000000"
                                    />
                                  </div>
                                  <input
                                    type="color"
                                    value={/^#[0-9a-fA-F]{6}$/.test(colorValue) ? colorValue : "#000000"}
                                    onChange={(event) => updateForm("color", event.target.value)}
                                    disabled={!isEditing}
                                    aria-label="Color base"
                                    className="color-picker__native"
                                  />
                                </div>
                              </div>
                            </div>
                            <div className="salon-color-layout__preview">
                              <SalonShapePreview shape={String(form.shape ?? "square")} color={colorValue} />
                            </div>
                          </div>
                        </label>

                        <label className="form-grid__full">
                          <span>Descripcion</span>
                          <textarea value={String(form.description ?? "")} onChange={(event) => updateForm("description", event.target.value)} disabled={!isEditing} />
                        </label>
                      </>
                    )
                  }

                  return (
                    <>
                      {otherFields[0] ? (
                        <div className="form-grid__row-with-toggle">
                          <label>
                            <span>{otherFields[0].label}{otherFields[0].type !== "checkbox" ? " *" : ""}</span>
                            {otherFields[0].type === "select" ? (
                              <select value={String(form[otherFields[0].name] ?? "")} onChange={(event) => updateForm(otherFields[0].name, event.target.value)} disabled={!isEditing}>
                                <option value="">Selecciona</option>
                                {otherFields[0].options.map((option) => (
                                  <option key={option.value} value={option.value}>{option.label}</option>
                                ))}
                              </select>
                            ) : otherFields[0].type === "textarea" ? (
                              <textarea value={String(form[otherFields[0].name] ?? "")} onChange={(event) => updateForm(otherFields[0].name, event.target.value)} disabled={!isEditing} />
                            ) : (
                              <input
                                type={otherFields[0].type === "number" ? "number" : "text"}
                                value={String(form[otherFields[0].name] ?? "")}
                                onChange={(event) => updateForm(otherFields[0].name, otherFields[0].type === "number" ? Number(event.target.value) : event.target.value)}
                                disabled={!isEditing}
                              />
                            )}
                          </label>
                          {activeField ? (
                            <label className="form-grid__toggle">
                              <span>{activeField.label}</span>
                              <button
                                type="button"
                                className={Boolean(form[activeField.name]) ? "toggle-switch is-on" : "toggle-switch"}
                                onClick={() => isEditing && updateForm(activeField.name, !Boolean(form[activeField.name]))}
                                disabled={!isEditing}
                              >
                                <span />
                              </button>
                            </label>
                          ) : null}
                        </div>
                      ) : null}

                      {otherFields.slice(1).map((field) => {
                        if (field.type === "textarea") {
                          return (
                            <label key={field.name} className="form-grid__full">
                              <span>{field.label}</span>
                              <textarea value={String(form[field.name] ?? "")} onChange={(event) => updateForm(field.name, event.target.value)} disabled={!isEditing} />
                            </label>
                          )
                        }

                        if (field.type === "select") {
                          if (field.name === "shape" && canGenerateResources) {
                            return (
                              <div key={field.name} className="form-grid__full salon-shape-row">
                                <label className="salon-shape-row__field">
                                  <span>{field.label}</span>
                                  <select value={String(form[field.name] ?? "")} onChange={(event) => updateForm(field.name, event.target.value)} disabled={!isEditing}>
                                    <option value="">Selecciona</option>
                                    {field.options.map((option) => (
                                      <option key={option.value} value={option.value}>{option.label}</option>
                                    ))}
                                  </select>
                                </label>
                                <div className="salon-shape-row__action">
                                  <button type="button" className="ghost-button salon-inline-actions__button" onClick={openGenerateModal}>
                                    <Plus size={15} />
                                    Generar recursos
                                  </button>
                                </div>
                              </div>
                            )
                          }
                          return (
                            <label key={field.name} className={field.name === "areaId" || field.name === "typeId" || field.name === "color" ? "" : field.name.includes("description") ? "form-grid__full" : ""}>
                              <span>{field.label}</span>
                              <select value={String(form[field.name] ?? "")} onChange={(event) => updateForm(field.name, event.target.value)} disabled={!isEditing}>
                                <option value="">Selecciona</option>
                                {field.options.map((option) => (
                                  <option key={option.value} value={option.value}>{option.label}</option>
                                ))}
                              </select>
                            </label>
                          )
                        }

                        if (field.type === "color") {
                          const colorValue = String(form[field.name] ?? "#3b82f6") || "#3b82f6"
                          return (
                            <label key={field.name} className="form-grid__full salon-color-field">
                              <div className="color-picker">
                                <span className="color-picker__label">{field.label}</span>
                                <div className="color-picker__swatches">
                                  {salonCategoryColors.map((preset) => (
                                    <button
                                      key={preset}
                                      type="button"
                                      className={`color-picker__swatch${colorValue.toLowerCase() === preset.toLowerCase() ? " is-selected" : ""}`}
                                      style={{ background: preset } as CSSProperties}
                                      onClick={() => isEditing && updateForm(field.name, preset)}
                                      disabled={!isEditing}
                                      aria-label={`Usar color ${preset}`}
                                      title={preset}
                                    />
                                  ))}
                                </div>
                                <div className="color-picker__actions">
                                  <div className="color-picker__preview-wrap">
                                    <div className="color-picker__preview" style={{ background: /^#[0-9a-fA-F]{6}$/.test(colorValue) ? colorValue : "#ccc" }} />
                                    <input
                                      type="text"
                                      className="color-picker__hex"
                                      value={colorValue}
                                      onChange={(event) => updateForm(field.name, event.target.value)}
                                      disabled={!isEditing}
                                      maxLength={7}
                                      placeholder="#000000"
                                    />
                                  </div>
                                  <input
                                    type="color"
                                    value={/^#[0-9a-fA-F]{6}$/.test(colorValue) ? colorValue : "#000000"}
                                    onChange={(event) => updateForm(field.name, event.target.value)}
                                    disabled={!isEditing}
                                    aria-label={field.label}
                                    className="color-picker__native"
                                  />
                                </div>
                              </div>
                            </label>
                          )
                        }

                        return (
                          <label key={field.name} className={field.type === "text" && (field.name === "description" || field.name === "color") ? "form-grid__full" : ""}>
                            <span>{field.label}</span>
                            <input
                              type={field.type === "number" ? "number" : "text"}
                              value={String(form[field.name] ?? "")}
                              onChange={(event) => updateForm(field.name, field.type === "number" ? Number(event.target.value) : event.target.value)}
                              disabled={!isEditing}
                            />
                          </label>
                        )
                      })}
                    </>
                  )
                })()}
              </div>
            </form>
          ) : (
            <div className="price-lists-empty">
              <Icon size={48} opacity={0.3} />
              <p>Selecciona un registro o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>

      {showGenerateModal ? (
        <div className="modal-backdrop" onClick={() => setShowGenerateModal(false)}>
          <div className="data-panel salon-generate-modal" onClick={(event) => event.stopPropagation()}>
            <div className="salon-generate-modal__header">
              <div>
                <h3>Generar recursos</h3>
                <p>{selected ? `Categoria: ${getTitle(selected)}` : "Categoria seleccionada"}</p>
              </div>
              <button type="button" className="icon-button" onClick={() => setShowGenerateModal(false)} aria-label="Cerrar">
                <XCircle size={18} />
              </button>
            </div>

            <div className="form-grid">
              <label>
                <span>Prefijo *</span>
                <input
                  type="text"
                  value={generateForm.prefix}
                  onChange={(event) => setGenerateForm((current) => ({ ...current, prefix: event.target.value }))}
                />
              </label>
              <label>
                <span>Cantidad *</span>
                <input
                  type="number"
                  min={1}
                  max={200}
                  value={generateForm.quantity}
                  onChange={(event) => setGenerateForm((current) => ({ ...current, quantity: Number(event.target.value) || 1 }))}
                />
              </label>
              <label>
                <span>Numero inicial *</span>
                <input
                  type="number"
                  min={1}
                  value={generateForm.startAt}
                  onChange={(event) => setGenerateForm((current) => ({ ...current, startAt: Number(event.target.value) || 1 }))}
                />
              </label>
              <label>
                <span>Sillas *</span>
                <input
                  type="number"
                  min={1}
                  value={generateForm.seats}
                  onChange={(event) => setGenerateForm((current) => ({ ...current, seats: Number(event.target.value) || 1 }))}
                />
              </label>
              <label>
                <span>Estado base *</span>
                <select
                  value={generateForm.state}
                  onChange={(event) => setGenerateForm((current) => ({ ...current, state: event.target.value }))}
                >
                  <option value="Libre">Libre</option>
                  <option value="Reservada">Reservada</option>
                  <option value="Inactiva">Inactiva</option>
                </select>
              </label>
            </div>

            <div className="salon-generate-modal__footer">
              <button type="button" className="secondary-button" onClick={() => setShowGenerateModal(false)}>
                Cancelar
              </button>
              <button
                type="button"
                className="primary-button"
                disabled={isPending || !generateForm.prefix.trim() || generateForm.quantity < 1}
                onClick={submitGenerateResources}
              >
                <Save size={16} />
                Generar
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  )
}

export function DiningRoomMastersManager({ data, sections }: { data: DiningMastersData; sections?: DiningMasterSection[] }) {
  const visible = sections ?? ["areas", "resource-types", "resource-categories"]

  return (
    <div className="salon-masters-shell">
      {visible.map((section) => {
        const meta = masterMeta[section]
        if (section === "areas") {
          return (
            <SalonMasterCrudSection
              key={section}
              title={meta.title}
              icon={meta.icon}
              entity="areas"
              items={data.areas}
              getId={(item) => item.id}
              getTitle={(item) => String(item.name)}
              getMeta={(item) => `Orden ${item.order}${item.description ? ` - ${item.description}` : ""}`}
              searchPlaceholder="Buscar area..."
              fields={[
                { name: "name", label: "Nombre", type: "text" },
                { name: "order", label: "Orden", type: "number" },
                { name: "description", label: "Descripcion", type: "textarea" },
                { name: "active", label: "Activo", type: "checkbox" },
              ]}
              toForm={(item) => ({ id: item.id, name: item.name, order: item.order, description: item.description, active: item.active })}
              emptyForm={{ name: "", order: 0, description: "", active: true }}
            />
          )
        }

        if (section === "resource-types") {
          return (
            <SalonMasterCrudSection
              key={section}
              title={meta.title}
              icon={meta.icon}
              entity="resource-types"
              items={data.resourceTypes}
              getId={(item) => item.id}
              getTitle={(item) => String(item.name)}
              getMeta={(item) => String(item.description || "Sin descripcion")}
              searchPlaceholder="Buscar tipo..."
              fields={[
                { name: "name", label: "Nombre", type: "text" },
                { name: "description", label: "Descripcion", type: "textarea" },
                { name: "active", label: "Activo", type: "checkbox" },
              ]}
              toForm={(item) => ({ id: item.id, name: item.name, description: item.description, active: item.active })}
              emptyForm={{ name: "", description: "", active: true }}
            />
          )
        }

        return (
          <SalonMasterCrudSection
            key={section}
            title={meta.title}
            icon={meta.icon}
            entity="resource-categories"
            items={data.resourceCategories}
              getId={(item) => item.id}
              getTitle={(item) => String(item.name)}
              getMeta={(item) => `${item.area} - ${item.type}`}
              getAccentColor={(item) => String(item.color || "#3b82f6")}
              searchPlaceholder="Buscar categoria..."
              fields={[
                { name: "name", label: "Nombre", type: "text" },
                { name: "areaId", label: "Area", type: "select", options: data.lookups.areas.map((item) => ({ value: String(item.id), label: item.name })) },
                { name: "typeId", label: "Tipo", type: "select", options: data.lookups.resourceTypes.map((item) => ({ value: String(item.id), label: item.name })) },
                { name: "shape", label: "Forma visual", type: "select", options: salonShapeOptions },
                { name: "color", label: "Color base", type: "color" },
                { name: "description", label: "Descripcion", type: "textarea" },
                { name: "active", label: "Activo", type: "checkbox" },
              ]}
            toForm={(item) => ({ id: item.id, name: item.name, areaId: String(item.areaId), typeId: String(item.typeId), shape: item.shape || "square", color: item.color, description: item.description, active: item.active })}
            emptyForm={{ name: "", areaId: "", typeId: "", shape: "square", color: "#3b82f6", description: "", active: true }}
          />
        )
      })}
    </div>
  )
}
