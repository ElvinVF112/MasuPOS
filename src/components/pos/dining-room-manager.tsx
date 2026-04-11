"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { Copy, Database, MapPinned, MoreHorizontal, Pencil, Plus, Save, Search, Trash2, UtensilsCrossed, XCircle } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import type { DiningRoomManagerData } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

type ResourceFormState = {
  id?: number
  categoryId: string
  name: string
  state: string
  seats: number
  active: boolean
}

const emptyForm: ResourceFormState = { categoryId: "", name: "", state: "Libre", seats: 4, active: true }

function toForm(resource: DiningRoomManagerData["resources"][number]): ResourceFormState {
  return {
    id: resource.id,
    categoryId: String(resource.categoryId),
    name: resource.name,
    state: resource.state,
    seats: resource.seats,
    active: resource.active,
  }
}

export function DiningRoomManager({ data, showBoard = true, showCrud = true }: { data: DiningRoomManagerData; showBoard?: boolean; showCrud?: boolean }) {
  const router = useRouter()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [selectedCrudId, setSelectedCrudId] = useState<number | null>(data.resources[0]?.id ?? null)
  const [form, setForm] = useState<ResourceFormState>(data.resources[0] ? toForm(data.resources[0]) : emptyForm)
  const [search, setSearch] = useState("")
  const [message, setMessage] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [isPending, startTransition] = useTransition()

  const selectedCrud = useMemo(() => data.resources.find((item) => item.id === selectedCrudId) ?? null, [data.resources, selectedCrudId])

  const filteredResources = useMemo(() => {
    const term = search.trim().toLowerCase()
    if (!term) return data.resources
    return data.resources.filter((resource) => {
      const category = data.lookups.resourceCategories.find((item) => item.id === resource.categoryId)
      return [resource.name, category?.name, category?.area, category?.type]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(term))
    })
  }, [data.lookups.resourceCategories, data.resources, search])

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
    if (selectedCrud && !isEditing) {
      setForm(toForm(selectedCrud))
      return
    }
    if (!selectedCrudId && !isEditing) {
      setForm(emptyForm)
    }
  }, [isEditing, selectedCrud, selectedCrudId])

  useEffect(() => {
    if (isEditing || selectedCrudId != null || data.resources.length === 0) return
    setSelectedCrudId(data.resources[0].id)
  }, [data.resources, isEditing, selectedCrudId])

  useEffect(() => {
    return () => setDirty(false)
  }, [setDirty])

  function updateForm(next: Partial<ResourceFormState>) {
    setForm((current) => ({ ...current, ...next }))
  }

  function openNew() {
    confirmAction(() => {
      setSelectedCrudId(null)
      setForm(emptyForm)
      setIsEditing(true)
      setDirty(true)
      setMessage(null)
      setMenuId(null)
    })
  }

  function selectItem(id: number) {
    confirmAction(() => {
      setSelectedCrudId(id)
      setIsEditing(false)
      setDirty(false)
      setMessage(null)
      setMenuId(null)
    })
  }

  function openEdit(resourceId: number) {
    const resource = data.resources.find((item) => item.id === resourceId)
    if (!resource) return
    confirmAction(() => {
      setSelectedCrudId(resource.id)
      setForm(toForm(resource))
      setIsEditing(true)
      setDirty(true)
      setMessage(null)
      setMenuId(null)
    })
  }

  function duplicateResource(resourceId: number) {
    const resource = data.resources.find((item) => item.id === resourceId)
    if (!resource) return
    confirmAction(() => {
      setSelectedCrudId(null)
      setForm({
        ...toForm(resource),
        id: undefined,
        name: `Copia de ${resource.name}`,
      })
      setIsEditing(true)
      setDirty(true)
      setMessage(null)
      setMenuId(null)
    })
  }

  function deleteResourceItem(resourceId: number) {
    const resource = data.resources.find((item) => item.id === resourceId)
    if (!resource) return

    if (!window.confirm(`Eliminar el recurso ${resource.name}?`)) {
      return
    }

    setMessage(null)
    startTransition(async () => {
      const response = await fetch(apiUrl("/api/dining-room/resources"), {
        method: "DELETE",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: resourceId }),
      })
      const result = (await response.json()) as { ok: boolean; message?: string }

      if (!response.ok || !result.ok) {
        toast.error(result.message ?? "No se pudo eliminar el recurso.")
        return
      }

      toast.success("Recurso eliminado")
      setMenuId(null)
      setIsEditing(false)
      setDirty(false)
      setSelectedCrudId((current) => (current === resourceId ? null : current))
      router.refresh()
    })
  }

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      setDirty(false)
      setMessage(null)
      setMenuId(null)
      if (selectedCrud) {
        setForm(toForm(selectedCrud))
      } else {
        setForm(emptyForm)
      }
    })
  }

  function runRequest(method: "POST" | "PUT", body: object) {
    setMessage(null)

    startTransition(async () => {
      const response = await fetch(apiUrl("/api/dining-room/resources"), {
        method,
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
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

    if (!form.categoryId || !form.name.trim()) {
      setMessage("Completa la categoria y el nombre del recurso.")
      return
    }

    runRequest(form.id ? "PUT" : "POST", {
      id: form.id,
      categoryId: Number(form.categoryId),
      name: form.name,
      state: form.state,
      seats: form.seats,
      active: form.active,
    })
  }

  const managerCrud = (
    <section className="data-panel">
      <div className="price-lists-layout">
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <MapPinned size={17} />
              <h2>Recursos del salon</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo recurso">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar recurso..."
              value={search}
              onChange={(event) => setSearch(event.target.value)}
            />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredResources.length ? (
              filteredResources.map((resource) => {
                const category = data.lookups.resourceCategories.find((item) => item.id === resource.categoryId)
                return (
                  <div
                    key={resource.id}
                    className={`price-lists-sidebar__item${selectedCrudId === resource.id ? " is-selected" : ""}`}
                    onClick={() => selectItem(resource.id)}
                  >
                    <div className="price-lists-sidebar__item-top">
                      <span className={`price-lists-badge${resource.active ? " is-active" : " is-inactive"}`}>
                        {resource.active ? "Activo" : "Inactivo"}
                      </span>
                      <div className="price-lists-sidebar__menu-wrap">
                        <button
                          className="price-lists-sidebar__menu-btn"
                          type="button"
                          aria-label="Abrir menu"
                          title="Mas acciones"
                          onClick={(event) => {
                            event.stopPropagation()
                            setMenuId(menuId === resource.id ? null : resource.id)
                          }}
                        >
                          <MoreHorizontal size={16} strokeWidth={2.4} />
                        </button>
                        {menuId === resource.id ? (
                          <ul className="price-lists-dropdown" ref={menuRef} onClick={(event) => event.stopPropagation()}>
                            <li>
                              <button type="button" onClick={() => openEdit(resource.id)}>
                                <Pencil size={13} /> Editar
                              </button>
                            </li>
                            <li>
                              <button type="button" onClick={() => duplicateResource(resource.id)}>
                                <Copy size={13} /> Duplicar
                              </button>
                            </li>
                            <li className="is-danger">
                              <button type="button" onClick={() => deleteResourceItem(resource.id)}>
                                <Trash2 size={13} /> Eliminar
                              </button>
                            </li>
                          </ul>
                        ) : null}
                      </div>
                    </div>
                    <p className="price-lists-sidebar__desc">{resource.name}</p>
                    <p className="price-lists-sidebar__meta">
                      {resource.seats} sillas · {category ? category.name : "Sin categoria"}
                    </p>
                  </div>
                )
              })
            ) : (
              <div className="price-lists-empty">
                <UtensilsCrossed size={42} opacity={0.3} />
                <p>No hay recursos que coincidan con la busqueda</p>
              </div>
            )}
          </div>
        </aside>

        <main className="price-lists-main">
          {selectedCrud || isEditing ? (
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
                <div className="form-grid__row-with-toggle">
                  <label>
                    <span>Nombre *</span>
                    <input
                      value={form.name}
                      onChange={(event) => updateForm({ name: event.target.value })}
                      disabled={!isEditing}
                      required
                    />
                  </label>
                  <label className="form-grid__toggle">
                    <span>Activo</span>
                    <button
                      type="button"
                      className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                      onClick={() => isEditing && updateForm({ active: !form.active })}
                      disabled={!isEditing}
                    >
                      <span />
                    </button>
                  </label>
                </div>

                <label>
                  <span>Estado base</span>
                  <select value={form.state} onChange={(event) => updateForm({ state: event.target.value })} disabled={!isEditing}>
                    <option>Libre</option>
                    <option>Ocupado</option>
                    <option>Reservado</option>
                    <option>Mantenimiento</option>
                  </select>
                </label>

                <label>
                  <span>Sillas</span>
                  <input
                    type="number"
                    min={1}
                    max={20}
                    value={String(form.seats)}
                    onChange={(event) => updateForm({ seats: Number(event.target.value || 1) })}
                    disabled={!isEditing}
                  />
                </label>

                <label className="form-grid__full">
                  <span>Categoria de recurso</span>
                  <select value={form.categoryId} onChange={(event) => updateForm({ categoryId: event.target.value })} disabled={!isEditing}>
                    <option value="">Selecciona una categoria</option>
                    {data.lookups.resourceCategories.map((item) => (
                      <option key={item.id} value={item.id}>{item.name}</option>
                    ))}
                  </select>
                </label>
              </div>
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona un recurso o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>
    </section>
  )

  if (!showCrud) {
    return managerCrud
  }

  return <div className="management-layout management-layout--stacked salon-manager-page">{managerCrud}</div>
}
