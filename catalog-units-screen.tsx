"use client"

import { useState, useEffect, useMemo, useRef, useTransition } from "react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { useI18n } from "@/lib/i18n"
import { useFormat } from "@/lib/format-context"
import {
  Copy,
  Edit,
  Loader2,
  MoreHorizontal,
  Pencil,
  Plus,
  Save,
  Search,
  Trash2,
  X,
} from "lucide-react"

// Tipos asumidos que estarían en pos-data.ts
type UnitRecord = {
  id: number
  name: string
  abbreviation: string | null
  baseA: number
  baseB: number
  calculatedUnits: number | null
  active: boolean
}

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

export function CatalogUnitsScreen() {
  const { t } = useI18n()
  const { formatNumber } = useFormat()
  const router = useRouter()
  const [isPending, startTransition] = useTransition()

  const [units, setUnits] = useState<UnitRecord[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [form, setForm] = useState<UnitForm>(emptyForm)
  const [menuId, setMenuId] = useState<number | null>(null)
  const menuRef = useRef<HTMLUListElement>(null)

  useEffect(() => {
    async function fetchData() {
      try {
        const res = await fetch("/api/catalog/units")
        if (!res.ok) throw new Error("Failed to fetch units")
        const data = await res.json()
        setUnits(data)
        if (data.length > 0) {
          setSelectedId(data[0].id)
        }
      } catch (error) {
        toast.error("Error al cargar las unidades de medida.")
      } finally {
        setIsLoading(false)
      }
    }
    fetchData()
  }, [])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setMenuId(null)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  const filteredUnits = useMemo(() => {
    if (!query) return units
    return units.filter(
      (u) =>
        u.name.toLowerCase().includes(query.toLowerCase()) ||
        u.abbreviation?.toLowerCase().includes(query.toLowerCase())
    )
  }, [units, query])

  const selectedUnit = useMemo(() => {
    return units.find((u) => u.id === selectedId)
  }, [units, selectedId])

  useEffect(() => {
    if (selectedUnit && !isEditing) {
      setForm({
        id: selectedUnit.id,
        name: selectedUnit.name,
        abbreviation: selectedUnit.abbreviation || "",
        baseA: selectedUnit.baseA,
        baseB: selectedUnit.baseB,
        active: selectedUnit.active,
      })
    }
  }, [selectedUnit, isEditing])

  const handleSelect = (id: number) => {
    setSelectedId(id)
    setIsEditing(false)
  }

  const handleNew = () => {
    setSelectedId(null)
    setForm(emptyForm)
    setIsEditing(true)
  }

  const handleEdit = (unit: UnitRecord) => {
    setSelectedId(unit.id)
    setForm({
      id: unit.id,
      name: unit.name,
      abbreviation: unit.abbreviation || "",
      baseA: unit.baseA,
      baseB: unit.baseB,
      active: unit.active,
    })
    setIsEditing(true)
    setMenuId(null)
  }

  const handleDuplicate = (unit: UnitRecord) => {
    setSelectedId(null)
    setForm({
      name: `Copia de - ${unit.name}`,
      abbreviation: unit.abbreviation || "",
      baseA: unit.baseA,
      baseB: unit.baseB,
      active: true,
    })
    setIsEditing(true)
    setMenuId(null)
  }

  const handleDelete = (id: number) => {
    if (!window.confirm("¿Está seguro de que desea eliminar esta unidad?")) return

    startTransition(async () => {
      const res = await fetch(`/api/catalog/units/${id}`, { method: "DELETE" })
      if (res.ok) {
        toast.success("Unidad eliminada correctamente.")
        router.refresh()
        if (selectedId === id) {
          setSelectedId(units.length > 1 ? units.find(u => u.id !== id)!.id : null)
        }
      } else {
        toast.error("Error al eliminar la unidad.")
      }
    })
  }

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    if (!form.name) {
      toast.error("El nombre de la unidad es requerido.")
      return
    }

    startTransition(async () => {
      const url = form.id ? `/api/catalog/units/${form.id}` : "/api/catalog/units"
      const method = form.id ? "PUT" : "POST"

      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      })

      if (res.ok) {
        const savedUnit = await res.json()
        toast.success(`Unidad ${form.id ? "actualizada" : "creada"} correctamente.`)
        setIsEditing(false)
        router.refresh()
        if (!form.id) {
          setSelectedId(savedUnit.id)
        }
      } else {
        const error = await res.json()
        toast.error(error.message || "Error al guardar la unidad.")
      }
    })
  }

  if (isLoading) {
    return (
      <div className="price-lists-loading">
        <Loader2 className="spin" />
        <span>Cargando unidades...</span>
      </div>
    )
  }

  return (
    <div className="price-lists-layout">
      <aside className="price-lists-sidebar">
        <div className="price-lists-sidebar__header">
          <div className="price-lists-sidebar__title">
            <h2>Unidades</h2>
          </div>
          <button className="sidebar__add-btn" title="Nueva Unidad" onClick={handleNew}>
            <Plus size={16} />
          </button>
        </div>
        <div className="price-lists-sidebar__search">
          <Search size={16} className="price-lists-sidebar__search-icon" />
          <input
            type="text"
            placeholder="Buscar por nombre o abrev."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
        <ul className="price-lists-sidebar__list">
          {filteredUnits.map((unit) => (
            <li
              key={unit.id}
              className={`price-lists-sidebar__item ${selectedId === unit.id ? "is-selected" : ""}`}
              onClick={() => handleSelect(unit.id)}
            >
              <div className="price-lists-sidebar__item-info">
                <div className="price-lists-sidebar__item-top">
                  <span className="price-lists-sidebar__item-name">{unit.name}</span>
                  <span
                    className={`price-lists-badge ${unit.active ? "is-active" : "is-inactive"}`}
                  >
                    {unit.active ? "Activa" : "Inactiva"}
                  </span>
                </div>
                <span className="price-lists-sidebar__item-desc">
                  {unit.abbreviation}
                </span>
              </div>
              <div className="price-lists-sidebar__menu-wrap">
                <button
                  className="price-lists-sidebar__menu-btn"
                  onClick={(e) => {
                    e.stopPropagation()
                    setMenuId(menuId === unit.id ? null : unit.id)
                  }}
                >
                  <MoreHorizontal size={16} />
                </button>
                {menuId === unit.id && (
                  <ul className="price-lists-dropdown" ref={menuRef}>
                    <li>
                      <button onClick={() => handleEdit(unit)}>
                        <Pencil size={13} /> Editar
                      </button>
                    </li>
                    <li>
                      <button onClick={() => handleDuplicate(unit)}>
                        <Copy size={13} /> Duplicar
                      </button>
                    </li>
                    <li className="is-danger">
                      <button onClick={() => handleDelete(unit.id)}>
                        <Trash2 size={13} /> Eliminar
                      </button>
                    </li>
                  </ul>
                )}
              </div>
            </li>
          ))}
        </ul>
      </aside>

      <main className="price-lists-detail">
        {selectedId || isEditing ? (
          <form onSubmit={handleSubmit} className="price-lists-form">
            <div className="price-lists-form__header">
              <h3>{form.id ? "Editar Unidad" : "Nueva Unidad"}</h3>
              <div className="price-lists-form__actions">
                {isEditing ? (
                  <>
                    <button type="button" className="secondary-button" onClick={() => setIsEditing(false)}>
                      <X size={16} /> Cancelar
                    </button>
                    <button type="submit" className="primary-button" disabled={isPending}>
                      {isPending ? <Loader2 className="spin" /> : <Save size={16} />}
                      Guardar
                    </button>
                  </>
                ) : (
                  <button type="button" className="secondary-button" onClick={() => setIsEditing(true)}>
                    <Pencil size={16} /> Editar Datos
                  </button>
                )}
              </div>
            </div>

            <div className="form-grid">
              <label className="form-grid__full">
                <span>Nombre</span>
                <input
                  type="text"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  disabled={!isEditing}
                  required
                />
              </label>
              <label>
                <span>Abreviatura</span>
                <input
                  type="text"
                  value={form.abbreviation}
                  onChange={(e) => setForm({ ...form, abbreviation: e.target.value })}
                  disabled={!isEditing}
                />
              </label>
              <div className="price-lists-form__toggle-row">
                <div>
                  <strong>Activa</strong>
                  <small>Permite usar esta unidad en el sistema.</small>
                </div>
                <button
                  type="button"
                  className={`toggle-switch ${form.active ? "is-on" : ""} ${!isEditing ? "is-disabled" : ""}`}
                  onClick={() => isEditing && setForm({ ...form, active: !form.active })}
                  disabled={!isEditing}
                >
                  <span />
                </button>
              </div>
              <label>
                <span>Base A (Factor)</span>
                <input
                  type="number"
                  value={form.baseA}
                  onChange={(e) => setForm({ ...form, baseA: parseInt(e.target.value) || 1 })}
                  disabled={!isEditing}
                  min="1"
                />
              </label>
              <label>
                <span>Base B (Divisor)</span>
                <input
                  type="number"
                  value={form.baseB}
                  onChange={(e) => setForm({ ...form, baseB: parseInt(e.target.value) || 1 })}
                  disabled={!isEditing}
                  min="1"
                />
              </label>
              <label className="form-grid__full">
                <span>Unidades Calculadas (A / B)</span>
                <div className="input-readonly" style={{ padding: "0.8rem 0.9rem" }}>
                  {formatNumber(form.baseA / form.baseB, 4)}
                </div>
              </label>
            </div>
          </form>
        ) : (
          <div className="price-lists-empty">
            <p>Seleccione una unidad para ver sus detalles o cree una nueva.</p>
          </div>
        )}
      </main>
    </div>
  )
}

