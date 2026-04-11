"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react"
import {
  Archive,
  ChevronDown,
  ChevronRight,
  FolderTree,
  Image as ImageIcon,
  Layers,
  Loader2,
  Minus,
  MoreHorizontal,
  Package,
  Palette,
  Pencil,
  Plus,
  Copy,
  Save,
  Search,
  Tag,
  Trash2,
  X,
} from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import { apiUrl } from "@/lib/client-config"
import type { CategoryRecord } from "@/lib/pos-data"
import { useI18n } from "@/lib/i18n"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

type CategoryForm = {
  id?: number
  name: string
  description: string
  active: boolean
  codigo: string
  codigoCorto: string
  nombreCorto: string
  idCategoriaPadre: number | null
  idMoneda: number | null
  colorFondo: string
  colorBoton: string
  colorTexto: string
  colorFondoItem: string
  colorBotonItem: string
  colorTextoItem: string
  tamanoTexto: number
  columnasPOS: number
  mostrarEnPOS: boolean
  imagen: string
}

const emptyForm: CategoryForm = {
  name: "",
  description: "",
  active: true,
  codigo: "",
  codigoCorto: "",
  nombreCorto: "",
  idCategoriaPadre: null,
  idMoneda: null,
  colorFondo: "#1e3a5f",
  colorBoton: "#12467e",
  colorTexto: "#ffffff",
  colorFondoItem: "#1e3a5f",
  colorBotonItem: "#12467e",
  colorTextoItem: "#ffffff",
  tamanoTexto: 14,
  columnasPOS: 3,
  mostrarEnPOS: true,
  imagen: "",
}

const COLOR_PRESETS = [
  "#1e3a5f", "#12467e", "#2563eb", "#0f766e", "#059669", "#16a34a",
  "#65a30d", "#ca8a04", "#ea580c", "#dc2626", "#db2777", "#9333ea",
  "#7c3aed", "#475569", "#0ea5e9", "#f97316",
]

const TEXT_COLOR_PRESETS = [
  "#ffffff", "#f8fafc", "#f1f5f9", "#e2e8f0", "#cbd5e1",
  "#94a3b8", "#64748b", "#475569", "#334155", "#1e293b",
  "#0f172a", "#000000", "#1e3a5f", "#12467e", "#2563eb",
  "#dc2626", "#db2777", "#059669", "#16a34a",
]

const PALETTE_PRESETS = [
  "#1e3a5f", "#12467e", "#2563eb", "#0f766e", "#059669", "#16a34a", "#65a30d", "#ca8a04",
  "#ea580c", "#dc2626", "#db2777", "#9333ea", "#7c3aed", "#475569", "#0ea5e9", "#f97316",
  "#f8fafc", "#f1f5f9", "#e2e8f0", "#cbd5e1", "#94a3b8", "#64748b", "#334155", "#1e293b",
  "#0f172a", "#000000", "#14532d", "#166534", "#15803d", "#22c55e", "#86efac", "#fef9c3",
  "#7c2d12", "#9a3412", "#c2410c", "#fb923c", "#fdba74", "#ffedd5", "#4c1d95",
  "#5b21b6", "#6d28d9", "#8b5cf6", "#a78bfa", "#c4b5fd", "#ede9fe",
]

function withImageVersion(src: string | null | undefined) {
  if (!src) return ""
  const version = `${src.length}-${src.slice(0, 12).length}-${src.slice(-12).length}`
  if (src.startsWith("data:")) return `${src}#v=${version}`
  return src.includes("?") ? `${src}&v=${version}` : `${src}?v=${version}`
}

function getCategoryCardStyle(category: Pick<CategoryRecord, "colorFondo" | "colorTexto" | "colorBoton">, selected: boolean) {
  if (!selected) return undefined
  return {
    background: category.colorFondo || "#eef6ff",
    color: category.colorTexto || "#0f172a",
    borderColor: category.colorBoton || category.colorFondo || "#2563eb",
    boxShadow: `inset 0 0 0 1px ${category.colorBoton || category.colorFondo || "#2563eb"}`,
  }
}

function getCategoryMetaStyle(category: Pick<CategoryRecord, "colorTexto">, selected: boolean) {
  if (!selected) return undefined
  return {
    color: category.colorTexto || "#0f172a",
    opacity: 0.8,
  }
}

type ColorPickerProps = {
  value: string
  onChange: (color: string) => void
  disabled?: boolean
  label: string
}

function ColorPicker({ value, onChange, disabled, label }: ColorPickerProps) {
  const [hexInput, setHexInput] = useState(value)

  useEffect(() => { setHexInput(value) }, [value])

  function handleHexChange(val: string) {
    setHexInput(val)
    const clean = val.startsWith("#") ? val : `#${val}`
    if (/^#[0-9a-fA-F]{6}$/.test(clean)) {
      onChange(clean)
    }
  }

  function handleHexBlur() {
    const clean = hexInput.startsWith("#") ? hexInput : `#${hexInput}`
    if (/^#[0-9a-fA-F]{6}$/.test(clean)) {
      onChange(clean)
    } else {
      setHexInput(value)
    }
  }

  return (
    <div className="color-picker">
      <label className="color-picker__label">{label}</label>
      <div className="color-picker__swatches">
        {PALETTE_PRESETS.map(c => (
          <button
            key={c}
            type="button"
            className={`color-picker__swatch${value === c ? " is-selected" : ""}`}
            style={{ background: c }}
            onClick={() => { onChange(c); setHexInput(c) }}
            disabled={disabled}
            title={c}
          />
        ))}
      </div>
      <div className="color-picker__actions">
        <div className="color-picker__preview-wrap">
          <div className="color-picker__preview" style={{ background: /^#[0-9a-fA-F]{6}$/.test(value) ? value : "#ccc" }} />
          <input
            type="text"
            className="color-picker__hex"
            value={hexInput}
            onChange={e => handleHexChange(e.target.value)}
            onBlur={handleHexBlur}
            onKeyDown={e => e.key === "Enter" && handleHexBlur()}
            disabled={disabled}
            maxLength={7}
            placeholder="#000000"
          />
        </div>
        <input
          type="color"
          value={/^#[0-9a-fA-F]{6}$/.test(value) ? value : "#000000"}
          onChange={e => { onChange(e.target.value); setHexInput(e.target.value) }}
          disabled={disabled}
          className="color-picker__native"
        />
      </div>
    </div>
  )
}

function TextColorPicker({ value, onChange, disabled, label }: ColorPickerProps) {
  const [hexInput, setHexInput] = useState(value)

  useEffect(() => { setHexInput(value) }, [value])

  function handleHexChange(val: string) {
    setHexInput(val)
    const clean = val.startsWith("#") ? val : `#${val}`
    if (/^#[0-9a-fA-F]{6}$/.test(clean)) {
      onChange(clean)
    }
  }

  function handleHexBlur() {
    const clean = hexInput.startsWith("#") ? hexInput : `#${hexInput}`
    if (/^#[0-9a-fA-F]{6}$/.test(clean)) {
      onChange(clean)
    } else {
      setHexInput(value)
    }
  }

  return (
    <div className="color-picker">
      <label className="color-picker__label">{label}</label>
      <div className="color-picker__swatches">
        {PALETTE_PRESETS.map(c => (
          <button
            key={c}
            type="button"
            className={`color-picker__swatch${value === c ? " is-selected" : ""}`}
            style={{ background: c, border: "1px solid #e2e8f0" }}
            onClick={() => { onChange(c); setHexInput(c) }}
            disabled={disabled}
            title={c}
          />
        ))}
      </div>
      <div className="color-picker__actions">
        <div className="color-picker__preview-wrap">
          <div className="color-picker__preview" style={{ background: /^#[0-9a-fA-F]{6}$/.test(value) ? value : "#ccc" }} />
          <input
            type="text"
            className="color-picker__hex"
            value={hexInput}
            onChange={e => handleHexChange(e.target.value)}
            onBlur={handleHexBlur}
            onKeyDown={e => e.key === "Enter" && handleHexBlur()}
            disabled={disabled}
            maxLength={7}
            placeholder="#ffffff"
          />
        </div>
        <input
          type="color"
          value={/^#[0-9a-fA-F]{6}$/.test(value) ? value : "#ffffff"}
          onChange={e => { onChange(e.target.value); setHexInput(e.target.value) }}
          disabled={disabled}
          className="color-picker__native"
        />
      </div>
    </div>
  )
}

type TreeNode = CategoryRecord & { children: TreeNode[]; level: number }

function buildTree(flat: CategoryRecord[]): TreeNode[] {
  const map = new Map<number, TreeNode>()
  const roots: TreeNode[] = []

  for (const cat of flat) {
    map.set(cat.id, { ...cat, children: [], level: 0 })
  }

  for (const node of map.values()) {
    if (node.idCategoriaPadre == null) {
      roots.push(node)
    } else {
      const parent = map.get(node.idCategoriaPadre)
      if (parent) {
        node.level = parent.level + 1
        parent.children.push(node)
      } else {
        roots.push(node)
      }
    }
  }

  roots.sort((a, b) => a.name.localeCompare(b.name))
  return roots
}

function flattenTree(nodes: TreeNode[]): TreeNode[] {
  const result: TreeNode[] = []
  function walk(n: TreeNode[]) {
    for (const node of n) {
      result.push(node)
      if (node.children.length) walk(node.children)
    }
  }
  walk(nodes)
  return result
}

function recordToForm(r: CategoryRecord): CategoryForm {
  return {
    id: r.id,
    name: r.name,
    description: r.description,
    active: r.active,
    codigo: r.codigo ?? "",
    codigoCorto: r.codigoCorto ?? "",
    nombreCorto: r.nombreCorto ?? "",
    idCategoriaPadre: r.idCategoriaPadre,
    idMoneda: r.idMoneda,
    colorFondo: r.colorFondo || "#1e3a5f",
    colorBoton: r.colorBoton || "#12467e",
    colorTexto: r.colorTexto || "#ffffff",
    colorFondoItem: r.colorFondoItem || r.colorFondo || "#1e3a5f",
    colorBotonItem: r.colorBotonItem || r.colorBoton || "#12467e",
    colorTextoItem: r.colorTextoItem || r.colorTexto || "#ffffff",
    tamanoTexto: r.tamanoTexto || 14,
    columnasPOS: r.columnasPOS || 3,
    mostrarEnPOS: r.mostrarEnPOS,
    imagen: r.imagen ?? "",
  }
}

export function CatalogCategoriesScreen() {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLDivElement | null>(null)

  const [items, setItems] = useState<CategoryRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [query, setQuery] = useState("")
  const [expanded, setExpanded] = useState<Set<number>>(new Set())
  const [isEditing, setIsEditing] = useState(false)
  const [isBusy, setIsBusy] = useState(false)
  const [form, setForm] = useState<CategoryForm>(emptyForm)
  const [message, setMessage] = useState<string | null>(null)
  const [menuOpenId, setMenuOpenId] = useState<number | null>(null)
  const [activeTab, setActiveTab] = useState<"general" | "pos" | "imagen" | "productos">("general")
  const [copiedStyle, setCopiedStyle] = useState<Partial<CategoryForm> | null>(null)
  const [productsTab, setProductsTab] = useState<"assigned" | "available">("assigned")
  const [categoryProducts, setCategoryProducts] = useState<{ assigned: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }>; available: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }> }>({ assigned: [], available: [] })
  const [loadingProducts, setLoadingProducts] = useState(false)
  const [bulkProductsModal, setBulkProductsModal] = useState<null | { action: "assign" | "remove"; count: number }>(null)

  const loadProducts = useCallback(async (categoryId: number) => {
    setLoadingProducts(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/categories/${categoryId}/products`), { credentials: "include", cache: "no-store" })
      if (!res.ok) {
        console.error("Error fetching products:", res.status)
        return
      }
      const json = (await res.json()) as { ok?: boolean; assigned?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }>; available?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }> }
      if (json.ok && json.assigned && json.available) {
        setCategoryProducts({ assigned: json.assigned, available: json.available })
        setItems((prev) =>
          prev.map((item) =>
            item.id === categoryId
              ? {
                ...item,
                totalProductos: json.assigned?.length ?? item.totalProductos,
              }
              : item,
          ),
        )
      }
    } catch (err) {
      console.error("Error loading products:", err)
    } finally {
      setLoadingProducts(false)
    }
  }, [])

  useEffect(() => {
    if (activeTab !== "productos" || !selectedId) return
    loadProducts(selectedId)
  }, [activeTab, selectedId, loadProducts])

  const flat = useMemo(() => buildTree(items), [items])
  const flatFiltered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return flat
    return flat.filter(n => n.name.toLowerCase().includes(q) || (n.codigo ?? "").toLowerCase().includes(q))
  }, [flat, query])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])
  const parentOptions = useMemo(() => flat.filter(n => n.id !== selectedId), [flat, selectedId])

  useEffect(() => {
    void (async () => {
      try {
        const res = await fetch(apiUrl("/api/catalog/categories"), { credentials: "include", cache: "no-store" })
        const json = (await res.json()) as { ok: boolean; data?: CategoryRecord[] }
        if (json.ok && json.data) {
          setItems(json.data)
          if (json.data.length > 0 && !selectedId) {
            setSelectedId(json.data[0].id)
            setForm(recordToForm(json.data[0]))
          }
        }
      } finally {
        setLoading(false)
      }
    })()
  }, [])

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setMenuOpenId(null)
      }
    }
    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  async function executeBulkProductsAction() {
    if (!selectedId || !bulkProductsModal) return
    const source = bulkProductsModal.action === "remove" ? categoryProducts.assigned : categoryProducts.available
    if (source.length === 0) {
      setBulkProductsModal(null)
      return
    }

    setLoadingProducts(true)
    try {
      for (const p of source) {
        await fetch(apiUrl(`/api/catalog/categories/${selectedId}/products`), {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ action: bulkProductsModal.action, productId: p.idProducto }),
        })
      }
      const res = await fetch(apiUrl(`/api/catalog/categories/${selectedId}/products`), { credentials: "include", cache: "no-store" })
      const json = (await res.json()) as { ok?: boolean; assigned?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }>; available?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }> }
      if (json.ok && json.assigned && json.available) {
        const assignedCount = json.assigned.length
        setCategoryProducts({ assigned: json.assigned, available: json.available })
        setItems((prev) =>
          prev.map((item) =>
            item.id === selectedId
              ? {
                ...item,
                totalProductos: assignedCount,
              }
              : item,
          ),
        )
      }
      toast.success(bulkProductsModal.action === "remove" ? "Productos removidos" : "Productos asignados")
    } finally {
      setLoadingProducts(false)
      setBulkProductsModal(null)
    }
  }

  function toggleExpand(id: number) {
    setExpanded(prev => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  function selectItem(item: CategoryRecord) {
    confirmAction(() => {
      setIsEditing(false)
      setDirty(false)
      setSelectedId(item.id)
      setForm(recordToForm(item))
      setActiveTab("general")
      setMessage(null)
      setMenuOpenId(null)
    })
    return
  }

  function beginEdit() {
    setMessage(null)
    setIsEditing(true)
    setDirty(true)
  }

  function cancelEdit() {
    if (selected) setForm(recordToForm(selected))
    setMessage(null)
    setIsEditing(false)
    setDirty(false)
  }

  function update<K extends keyof CategoryForm>(key: K, value: CategoryForm[K]) {
    setForm(prev => ({ ...prev, [key]: value }))
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }

    setIsBusy(true)
    setMessage(null)
    try {
      const isNew = !form.id
      const url = isNew ? apiUrl("/api/catalog/categories") : apiUrl("/api/catalog/categories")
      const method = isNew ? "POST" : "PUT"
      const res = await fetch(url, {
        method,
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: form.id,
          name: (form.name || "").toUpperCase(),
          description: form.description ? form.description.toUpperCase() : null,
          active: form.active,
          codigo: form.codigo || null,
          codigoCorto: form.codigoCorto || null,
          nombreCorto: form.nombreCorto ? form.nombreCorto.toUpperCase() : null,
          idCategoriaPadre: form.idCategoriaPadre,
          idMoneda: form.idMoneda,
          colorFondo: form.colorFondo,
          colorBoton: form.colorBoton,
          colorTexto: form.colorTexto,
          colorFondoItem: form.colorFondoItem,
          colorBotonItem: form.colorBotonItem,
          colorTextoItem: form.colorTextoItem,
          tamanoTexto: form.tamanoTexto,
          columnasPOS: form.columnasPOS,
          mostrarEnPOS: form.mostrarEnPOS,
          imagen: form.imagen || null,
        }),
      })
      const json = (await res.json()) as { ok: boolean; data?: CategoryRecord; message?: string }
      if (!res.ok || !json.ok) {
        setMessage(json.message ?? "No se pudo guardar.")
        toast.error("Error al guardar", { description: json.message ?? "No se pudo guardar." })
        return
      }
      const saved = json.data!
      setItems(prev => isNew ? [...prev, saved] : prev.map(i => i.id === saved.id ? saved : i))
      setSelectedId(saved.id)
      setForm(recordToForm(saved))
      setIsEditing(false)
      setDirty(false)
      toast.success(isNew ? "Categoría creada" : "Cambios guardados")
      router.refresh()
    } finally {
      setIsBusy(false)
    }
  }

  async function handleDelete(item: CategoryRecord) {
    if (item.totalProductos > 0) {
      toast.error("No se puede eliminar", { description: "La categoría tiene productos asociados." })
      return
    }
    if (item.totalSubcategorias > 0) {
      toast.error("No se puede eliminar", { description: "La categoría tiene subcategorías." })
      return
    }
    if (!confirm(`¿Eliminar la categoría "${item.name}"?`)) return
    setMenuOpenId(null)
    setIsBusy(true)
    try {
      const res = await fetch(apiUrl("/api/catalog/categories"), {
        method: "DELETE",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id: item.id }),
      })
      const json = (await res.json()) as { ok: boolean; message?: string }
      if (!res.ok || !json.ok) { toast.error("Error", { description: json.message ?? "No se pudo eliminar." }); return }
      const remaining = items.filter(i => i.id !== item.id)
      setItems(remaining)
      if (selectedId === item.id) {
        const next = remaining[0] ?? null
        setSelectedId(next?.id ?? null)
        setForm(next ? recordToForm(next) : emptyForm)
      }
      toast.success("Categoría eliminada")
      router.refresh()
    } finally {
      setIsBusy(false)
    }
  }

  function handleNew() {
    confirmAction(() => {
      setSelectedId(null)
      setForm(emptyForm)
      setIsEditing(true)
      setDirty(true)
      setActiveTab("general")
      setMessage(null)
    })
    return
  }

  function duplicateItem(item: CategoryRecord) {
    setSelectedId(null)
    setForm({
      ...recordToForm(item),
      id: undefined,
      name: `Copia de ${item.name}`,
      imagen: "",
      colorFondoItem: "#1e3a5f",
      colorBotonItem: "#12467e",
      colorTextoItem: "#ffffff",
    })
    setIsEditing(true)
    setDirty(true)
    setActiveTab("general")
    setMessage(null)
    setMenuOpenId(null)
  }

  function copyStyle() {
    setCopiedStyle({
      colorFondo: form.colorFondo,
      colorBoton: form.colorBoton,
      colorTexto: form.colorTexto,
      colorFondoItem: form.colorFondoItem,
      colorBotonItem: form.colorBotonItem,
      colorTextoItem: form.colorTextoItem,
      tamanoTexto: form.tamanoTexto,
      columnasPOS: form.columnasPOS,
    })
    toast.success("Estilo copiado")
  }

  function pasteStyle() {
    if (!copiedStyle) return
    if (copiedStyle.colorFondo) update("colorFondo", copiedStyle.colorFondo)
    if (copiedStyle.colorBoton) update("colorBoton", copiedStyle.colorBoton)
    if (copiedStyle.colorTexto) update("colorTexto", copiedStyle.colorTexto)
    if (copiedStyle.colorFondoItem) update("colorFondoItem", copiedStyle.colorFondoItem)
    if (copiedStyle.colorBotonItem) update("colorBotonItem", copiedStyle.colorBotonItem)
    if (copiedStyle.colorTextoItem) update("colorTextoItem", copiedStyle.colorTextoItem)
    if (copiedStyle.tamanoTexto) update("tamanoTexto", copiedStyle.tamanoTexto)
    if (copiedStyle.columnasPOS) update("columnasPOS", copiedStyle.columnasPOS)
    toast.success("Estilo aplicado")
  }

  if (loading) {
    return (
      <div className="categories-loading">
        <Loader2 size={28} className="spin" />
        <p>Cargando categorías...</p>
      </div>
    )
  }

  return (
    <div className="categories-layout" ref={menuRef as React.RefObject<HTMLDivElement>}>

      {/* Panel izquierdo */}
      <aside className="categories-sidebar">
        <div className="categories-sidebar__header">
          <div className="categories-sidebar__title">
            <FolderTree size={17} />
            <h2>Categorías</h2>
          </div>
          <button className="categories-sidebar__add-btn" type="button" onClick={handleNew} title="Nueva categoría">
            <Plus size={15} />
          </button>
        </div>

        <div className="categories-sidebar__search">
          <Search size={13} className="categories-sidebar__search-icon" />
          <input type="text" placeholder="Buscar categoría..." value={query} onChange={e => setQuery(e.target.value)} />
        </div>

        <ul className="categories-sidebar__list">
          {flatFiltered.map(node => (
            <li key={node.id}>
              <div
                className={`categories-sidebar__item${selectedId === node.id ? " is-selected" : ""}`}
                style={getCategoryCardStyle(node, selectedId === node.id)}
                onClick={() => selectItem(node)}
              >
                <span className="categories-sidebar__indent" style={{ width: node.level * 16 }} />
                {node.children.length > 0 ? (
                  <button
                    type="button"
                    className="categories-sidebar__expand"
                    onClick={e => { e.stopPropagation(); toggleExpand(node.id) }}
                  >
                    {expanded.has(node.id) ? <ChevronDown size={12} /> : <ChevronRight size={12} />}
                  </button>
                ) : (
                  <span className="categories-sidebar__expand-placeholder" />
                )}
                {node.imagen ? (
                  <span className="categories-sidebar__avatar categories-sidebar__avatar--image">
                    <img src={withImageVersion(node.imagen)} alt={node.name} />
                  </span>
                ) : (
                  <span
                    className="categories-sidebar__avatar"
                    style={{ background: node.colorFondo, color: node.colorTexto }}
                  >
                    {node.name.charAt(0).toUpperCase()}
                  </span>
                )}
                <div className="categories-sidebar__info">
                  <span
                    className="categories-sidebar__name"
                    style={selectedId === node.id ? { color: node.colorTexto || "#0f172a" } : undefined}
                  >
                    {node.name}
                  </span>
                  <span
                    className="categories-sidebar__meta"
                    style={getCategoryMetaStyle(node, selectedId === node.id)}
                  >
                    <Layers size={10} /> {node.totalSubcategorias} subcategoría{node.totalSubcategorias !== 1 ? "s" : ""}
                    <Package size={10} /> {node.totalProductos} producto{node.totalProductos !== 1 ? "s" : ""}
                  </span>
                </div>
                <div className="categories-sidebar__menu-wrap">
                  <button
                    type="button"
                    className="categories-sidebar__menu-btn"
                    onClick={e => { e.stopPropagation(); setMenuOpenId(menuOpenId === node.id ? null : node.id) }}
                  >
                    <MoreHorizontal size={14} />
                  </button>
                  {menuOpenId === node.id ? (
                    <ul className="categories-dropdown" onClick={e => e.stopPropagation()}>
                      <li>
                        <button type="button" onClick={() => { selectItem(node); beginEdit() }}>
                          <Pencil size={13} /> Editar
                        </button>
                      </li>
                      <li>
                        <button type="button" onClick={() => duplicateItem(node)}>
                          <Copy size={13} /> Duplicar
                        </button>
                      </li>
                      <li className="is-danger">
                        <button type="button" onClick={() => handleDelete(node)}>
                          <Trash2 size={13} /> Eliminar
                        </button>
                      </li>
                    </ul>
                  ) : null}
                </div>
              </div>
              {expanded.has(node.id) && node.children.length > 0 ? (
                <ul className="categories-sidebar__children">
                  {node.children.map(child => (
                    <li key={child.id}>
                      <div
                        className={`categories-sidebar__item is-child${selectedId === child.id ? " is-selected" : ""}`}
                        style={getCategoryCardStyle(child, selectedId === child.id)}
                        onClick={() => selectItem(child)}
                      >
                        <span className="categories-sidebar__indent" style={{ width: (node.level + 1) * 16 }} />
                        {child.imagen ? (
                          <span className="categories-sidebar__avatar categories-sidebar__avatar--sm categories-sidebar__avatar--image">
                            <img src={withImageVersion(child.imagen)} alt={child.name} />
                          </span>
                        ) : (
                          <span
                            className="categories-sidebar__avatar categories-sidebar__avatar--sm"
                            style={{ background: child.colorFondo, color: child.colorTexto }}
                          >
                            {child.name.charAt(0).toUpperCase()}
                          </span>
                        )}
                        <div className="categories-sidebar__info">
                          <span
                            className="categories-sidebar__name"
                            style={selectedId === child.id ? { color: child.colorTexto || "#0f172a" } : undefined}
                          >
                            {child.name}
                          </span>
                          <span
                            className="categories-sidebar__meta"
                            style={getCategoryMetaStyle(child, selectedId === child.id)}
                          >
                            <Layers size={10} /> {child.totalSubcategorias} subcategoría{child.totalSubcategorias !== 1 ? "s" : ""}
                            <Package size={10} /> {child.totalProductos} producto{child.totalProductos !== 1 ? "s" : ""}
                          </span>
                        </div>
                      </div>
                    </li>
                  ))}
                </ul>
              ) : null}
            </li>
          ))}
          {flatFiltered.length === 0 ? (
            <li className="categories-sidebar__empty">Sin resultados</li>
          ) : null}
        </ul>

        <div className="categories-sidebar__footer">
          {flatFiltered.length} categoría{flatFiltered.length !== 1 ? "s" : ""}
        </div>
      </aside>

      {/* Panel derecho */}
      {selectedId !== null || isEditing ? (
        <section className="categories-detail">
          <div className="products-detail__action-bar">
            {isEditing ? (
              <div className="products-detail__action-bar-btns">
                <button className="secondary-button" type="button" onClick={cancelEdit} disabled={isBusy}>
                  <X size={14} /> Cancelar
                </button>
                <button className="primary-button" type="button" onClick={e => void submit(e as unknown as FormEvent)} disabled={isBusy}>
                  {isBusy ? <Loader2 size={14} className="spin" /> : <Save size={14} />}
                  {isBusy ? "Guardando..." : "Guardar"}
                </button>
              </div>
            ) : null}
          </div>

          <div className="categories-detail__tabs">
            <button type="button" className={activeTab === "general" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("general")}>
              <Tag size={13} /> General
            </button>
            <button type="button" className={activeTab === "pos" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("pos")}>
              <Palette size={13} /> POS
            </button>
            <button type="button" className={activeTab === "imagen" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("imagen")}>
              <ImageIcon size={13} /> Imagen
            </button>
            <button type="button" className={activeTab === "productos" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("productos")}>
              <Archive size={13} /> Productos
            </button>
          </div>

          {/* Tab General */}
          {activeTab === "general" ? (
            <form className="data-panel categories-form" onSubmit={e => void submit(e)}>
              <div className="form-grid form-grid--spaced">
                <div className="form-grid__row-with-toggle">
                  <label>
                    <span>Nombre *</span>
                    <input value={form.name} onChange={e => update("name", e.target.value)} disabled={!isEditing} required maxLength={100} placeholder="Nombre de la categoría" />
                  </label>
                  <label>
                    <span>Código</span>
                    <input value={form.codigo} onChange={e => update("codigo", e.target.value)} disabled={!isEditing} maxLength={20} placeholder="Código corto" />
                  </label>
                  <label className="form-grid__toggle">
                    <span>Activo</span>
                    <button type="button" className={form.active ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && update("active", !form.active)} disabled={!isEditing}>
                      <span />
                    </button>
                  </label>
                </div>
                <label className="form-grid__full">
                  <span>Descripción</span>
                  <textarea value={form.description} onChange={e => update("description", e.target.value)} disabled={!isEditing} rows={3} maxLength={250} placeholder="Descripción opcional" />
                </label>
                <label>
                  <span>Categoría Padre</span>
                  <select value={form.idCategoriaPadre ?? ""} onChange={e => update("idCategoriaPadre", e.target.value ? Number(e.target.value) : null)} disabled={!isEditing}>
                    <option value="">— Ninguna —</option>
                    {parentOptions.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                  </select>
                </label>
                <label>
                  <span>Moneda</span>
                  <select value={form.idMoneda ?? ""} onChange={e => update("idMoneda", e.target.value ? Number(e.target.value) : null)} disabled={!isEditing}>
                    <option value="">— Predeterminada —</option>
                    <option value="1">DOP — Peso Dominicano</option>
                    <option value="2">USD — Dólar Estadounidense</option>
                    <option value="3">EUR — Euro</option>
                  </select>
                </label>
                {selected ? (
                  <div className="categories-form__stats form-grid__full">
                    <div className="categories-stat">
                      <Layers size={16} />
                      <span>{selected.totalSubcategorias} subcategoría{selected.totalSubcategorias !== 1 ? "s" : ""}</span>
                    </div>
                    <div className="categories-stat">
                      <Tag size={16} />
                      <span>{selected.totalProductos} producto{selected.totalProductos !== 1 ? "s" : ""}</span>
                    </div>
                  </div>
                ) : null}
              </div>
              {message ? <p className="form-message">{message}</p> : null}
            </form>
          ) : null}

          {/* Tab POS */}
          {activeTab === "pos" ? (
            <div className="data-panel categories-form">
              <div className="categories-pos">
                <div className="categories-pos__config">
                  <label className="categories-form__toggle-row">
                    <div><span>Mostrar en POS</span></div>
                    <button type="button" className={form.mostrarEnPOS ? "toggle-switch is-on" : "toggle-switch"} onClick={() => update("mostrarEnPOS", !form.mostrarEnPOS)} disabled={!isEditing}>
                      <span />
                    </button>
                  </label>

                  <label>
                    <span>Nombre Corto (POS)</span>
                    <input value={form.nombreCorto} onChange={e => update("nombreCorto", e.target.value)} disabled={!isEditing} maxLength={30} placeholder="Nombre corto para el botón" />
                  </label>

                  <ColorPicker value={form.colorFondo} onChange={c => update("colorFondo", c)} disabled={!isEditing} label="Color de Fondo" />

                  <ColorPicker value={form.colorBoton} onChange={c => update("colorBoton", c)} disabled={!isEditing} label="Color del Botón" />

                  <TextColorPicker value={form.colorTexto} onChange={c => update("colorTexto", c)} disabled={!isEditing} label="Color del Texto" />

                  <div className="categories-pos__section-label">Botón de Items</div>

                  <ColorPicker value={form.colorFondoItem} onChange={c => update("colorFondoItem", c)} disabled={!isEditing} label="Color de Fondo (Item)" />

                  <ColorPicker value={form.colorBotonItem} onChange={c => update("colorBotonItem", c)} disabled={!isEditing} label="Color del Botón (Item)" />

                  <TextColorPicker value={form.colorTextoItem} onChange={c => update("colorTextoItem", c)} disabled={!isEditing} label="Color del Texto (Item)" />

                  <label>
                    <span>Tamaño del Texto: {form.tamanoTexto}px</span>
                    <input type="range" min={10} max={24} value={form.tamanoTexto} onChange={e => update("tamanoTexto", Number(e.target.value))} disabled={!isEditing} className="categories-slider" />
                  </label>

                  <label>
                    <span>Columnas en POS: {form.columnasPOS}</span>
                    <input type="range" min={2} max={6} value={form.columnasPOS} onChange={e => update("columnasPOS", Number(e.target.value))} disabled={!isEditing} className="categories-slider" />
                  </label>

                  <div className="categories-form__style-actions">
                    <button type="button" className="ghost-button" onClick={copyStyle} disabled={!isEditing} title="Copiar estilo">
                      <Palette size={13} /> Copiar Estilo
                    </button>
                    <button type="button" className="ghost-button" onClick={pasteStyle} disabled={!isEditing || !copiedStyle} title="Pegar estilo">
                      <Save size={13} /> Pegar Estilo
                    </button>
                  </div>
                </div>

                <div className="categories-pos__preview">
                  <h4>Vista Previa</h4>
                  <div
                    className="categories-pos__preview-stage"
                    style={{
                      background: "transparent",
                      borderColor: form.colorBoton || "#bfdbfe",
                      color: form.colorTexto || "#0f172a",
                    }}
                  >
                    <div className="categories-pos__preview-grid" style={{ gridTemplateColumns: `repeat(${form.columnasPOS}, 1fr)` }}>
                      <button
                        className="categories-pos__preview-btn"
                        style={{
                          background: form.colorBoton,
                          color: form.colorTexto,
                          fontSize: `${form.tamanoTexto}px`,
                        }}
                      >
                        {form.nombreCorto || form.name || "Categoria"}
                      </button>
                    </div>
                    <div className="categories-pos__preview-grid categories-pos__preview-grid--items">
                      <button
                        className="categories-pos__preview-btn"
                        style={{
                          background: form.colorBotonItem,
                          color: form.colorTextoItem,
                          fontSize: `${Math.max(form.tamanoTexto - 1, 12)}px`,
                        }}
                      >
                        Item POS
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ) : null}

          {/* Tab Imagen */}
          {activeTab === "imagen" ? (
            <div className="data-panel categories-form">
              <div className="categories-image">
                {form.imagen ? (
                  <div className="categories-image__preview">
                    <img src={withImageVersion(form.imagen)} alt={form.name} />
                    {isEditing && (
                      <button type="button" className="ghost-button danger-button" onClick={() => update("imagen", "")}>
                        <Trash2 size={13} /> Eliminar Imagen
                      </button>
                    )}
                  </div>
                ) : (
                  <div className="categories-image__drop">
                    <ImageIcon size={32} />
                    <p>Arrastra una imagen aquí o</p>
                    {isEditing && (
                      <label className="primary-button categories-image__upload-btn">
                        <input type="file" accept="image/*" style={{ display: "none" }} onChange={e => {
                          const file = e.target.files?.[0]
                          if (!file) return
                          if (file.size > 2 * 1024 * 1024) { toast.error("La imagen debe ser menor a 2MB"); return }
                          const reader = new FileReader()
                          reader.onload = ev => update("imagen", ev.target?.result as string)
                          reader.readAsDataURL(file)
                        }} />
                        <Plus size={14} /> Subir Imagen
                      </label>
                    )}
                    <small>Máximo 2MB</small>
                  </div>
                )}
              </div>
            </div>
          ) : null}

          {/* Tab Productos */}
          {activeTab === "productos" ? (
            <div className="data-panel categories-form">
              {loadingProducts ? (
                <div className="categories-products__loading">
                  <Loader2 size={24} className="spin" />
                  <span>Cargando productos...</span>
                </div>
              ) : (
                <>
                  <div className="categories-products__subtabs">
                    <button type="button" className={productsTab === "assigned" ? "filter-pill is-active" : "filter-pill"} onClick={() => setProductsTab("assigned")}>
                      Asignados ({categoryProducts.assigned.length})
                    </button>
                    <button type="button" className={productsTab === "available" ? "filter-pill is-active" : "filter-pill"} onClick={() => setProductsTab("available")}>
                      Disponibles ({categoryProducts.available.length})
                    </button>
                  </div>
                  <div className="categories-products__list">
                    {productsTab === "assigned" ? (
                      categoryProducts.assigned.length === 0 ? (
                        <div className="categories-products__empty">
                          <Package size={24} />
                          <span>No hay productos asignados a esta categoría</span>
                        </div>
                      ) : (
                        <>
                          <div className="categories-products__header">
                            <button type="button" className="ghost-button" onClick={() => {
                              if (!selectedId || categoryProducts.assigned.length === 0) return
                              setBulkProductsModal({ action: "remove", count: categoryProducts.assigned.length })
                            }}>
                              <Minus size={14} /> Quitar todos
                            </button>
                          </div>
                          <ul className="categories-products__items">
                            {categoryProducts.assigned.map(p => (
                              <li key={p.idProducto} className="categories-products__item">
                                <div className="categories-products__item-info">
                                  <span className="categories-products__item-name">{p.nombre}</span>
                                  <span className="categories-products__item-type">{p.tipoProducto || "Sin tipo"}</span>
                                </div>
                                <button type="button" className="ghost-button danger-button" onClick={async () => {
                                  if (!selectedId) return
                                  setLoadingProducts(true)
                                  try {
                                    await fetch(apiUrl(`/api/catalog/categories/${selectedId}/products`), {
                                      method: "PUT",
                                      headers: { "Content-Type": "application/json" },
                                      credentials: "include",
                                      body: JSON.stringify({ action: "remove", productId: p.idProducto }),
                                    })
                                    const res = await fetch(apiUrl(`/api/catalog/categories/${selectedId}/products`), { credentials: "include" })
                                    const json = (await res.json()) as { ok?: boolean; assigned?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }>; available?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }> }
                                    if (json.ok && json.assigned && json.available) {
                                      setCategoryProducts({ assigned: json.assigned, available: json.available })
                                    }
                                    toast.success("Producto removido")
                                  } finally {
                                    setLoadingProducts(false)
                                  }
                                }}>
                                  <Minus size={14} />
                                </button>
                              </li>
                            ))}
                          </ul>
                        </>
                      )
                    ) : (
                      categoryProducts.available.length === 0 ? (
                        <div className="categories-products__empty">
                          <Package size={24} />
                          <span>No hay productos disponibles</span>
                        </div>
                      ) : (
                        <>
                          <div className="categories-products__header">
                            <button type="button" className="ghost-button" onClick={() => {
                              if (!selectedId || categoryProducts.available.length === 0) return
                              setBulkProductsModal({ action: "assign", count: categoryProducts.available.length })
                            }}>
                              <Plus size={14} /> Asignar todos
                            </button>
                          </div>
                          <ul className="categories-products__items">
                            {categoryProducts.available.map(p => (
                              <li key={p.idProducto} className="categories-products__item">
                                <div className="categories-products__item-info">
                                  <span className="categories-products__item-name">{p.nombre}</span>
                                  <span className="categories-products__item-type">{p.tipoProducto || "Sin tipo"}</span>
                                </div>
                                <button type="button" className="ghost-button primary-button" onClick={async () => {
                                  if (!selectedId) return
                                  setLoadingProducts(true)
                                  try {
                                    await fetch(apiUrl(`/api/catalog/categories/${selectedId}/products`), {
                                      method: "PUT",
                                      headers: { "Content-Type": "application/json" },
                                      credentials: "include",
                                      body: JSON.stringify({ action: "assign", productId: p.idProducto }),
                                    })
                                    const res = await fetch(apiUrl(`/api/catalog/categories/${selectedId}/products`), { credentials: "include" })
                                    const json = (await res.json()) as { ok?: boolean; assigned?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }>; available?: Array<{ idProducto: number; nombre: string; activo: boolean; tipoProducto: string | null }> }
                                    if (json.ok && json.assigned && json.available) {
                                      setCategoryProducts({ assigned: json.assigned, available: json.available })
                                    }
                                    toast.success("Producto asignado")
                                  } finally {
                                    setLoadingProducts(false)
                                  }
                                }}>
                                  <Plus size={14} />
                                </button>
                              </li>
                            ))}
                          </ul>
                        </>
                      )
                    )}
                  </div>
                </>
              )}
            </div>
          ) : null}

        </section>
      ) : (
        <section className="categories-empty">
          <FolderTree size={44} />
          <p>Selecciona una categoría o crea una nueva</p>
        </section>
      )}
      <DeleteConfirmModal
        open={bulkProductsModal !== null}
        entityLabel={bulkProductsModal?.action === "remove" ? "Productos asignados" : "Productos disponibles"}
        itemName={`${bulkProductsModal?.count ?? 0} productos`}
        confirmLabel={bulkProductsModal?.action === "remove" ? "Quitar" : "Asignar"}
        onCancel={() => setBulkProductsModal(null)}
        onConfirm={() => void executeBulkProductsAction()}
      >
        <p>
          {bulkProductsModal?.action === "remove"
            ? `Se quitaran ${bulkProductsModal?.count ?? 0} productos de esta categoria.`
            : `Se asignaran ${bulkProductsModal?.count ?? 0} productos a esta categoria.`}
        </p>
      </DeleteConfirmModal>
    </div>
  )
}


