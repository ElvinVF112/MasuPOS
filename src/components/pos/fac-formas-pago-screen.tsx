"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { ArrowLeftRight, Banknote, Building2, CircleDollarSign, Copy, CreditCard, Database, DollarSign, Gift, HandCoins, Landmark, Loader2, MoreHorizontal, Pencil, Plus, Receipt, Save, Search, Send, Smartphone, Trash2, Wallet, X } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { FacFormaPagoRecord } from "@/lib/pos-data"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

type DetailTab = "general" | "otros"

type CurrencyOption = { id: number; code: string; name: string; symbol: string }
type PuntoEmisionOption = { id: number; nombre: string }

const TIPO_VALOR_OPTIONS = [
  { value: "EF", label: "Efectivo" },
  { value: "TC", label: "Tarjetas Db/Cr" },
  { value: "NC", label: "Nota de Crédito" },
  { value: "AN", label: "Anticipos" },
  { value: "PM", label: "Pagos Mixtos" },
  { value: "CH", label: "Cheques" },
  { value: "DV", label: "Divisas" },
  { value: "AB", label: "Abonos" },
  { value: "VC", label: "Ventas a Crédito" },
  { value: "OV", label: "Otros Valores" },
] as const

const TIPO_VALOR_607_OPTIONS = [
  { value: "", label: "Sin asignar" },
  { value: "EF", label: "Efectivo" },
  { value: "TA", label: "Tarjetas" },
  { value: "PE", label: "Permutas" },
  { value: "BO", label: "Bonos" },
  { value: "CH", label: "Cheques" },
  { value: "CR", label: "Crédito" },
  { value: "OT", label: "Otros" },
] as const

const sectionTitle: React.CSSProperties = { fontSize: "0.78rem", fontWeight: 700, color: "var(--brand)", textTransform: "uppercase", letterSpacing: "0.05em", borderBottom: "2px solid var(--brand)", paddingBottom: "0.25rem", marginBottom: "0.7rem" }

const ICON_OPTIONS = [
  { value: "banknote", label: "Efectivo", Icon: Banknote },
  { value: "credit-card", label: "Tarjeta", Icon: CreditCard },
  { value: "landmark", label: "Banco", Icon: Landmark },
  { value: "send", label: "Transferencia", Icon: Send },
  { value: "receipt", label: "Recibo", Icon: Receipt },
  { value: "wallet", label: "Billetera", Icon: Wallet },
  { value: "hand-coins", label: "Monedas", Icon: HandCoins },
  { value: "circle-dollar", label: "Dólar", Icon: CircleDollarSign },
  { value: "dollar-sign", label: "Signo $", Icon: DollarSign },
  { value: "smartphone", label: "Móvil", Icon: Smartphone },
  { value: "gift", label: "Bono/Regalo", Icon: Gift },
  { value: "building", label: "Empresa", Icon: Building2 },
  { value: "arrow-lr", label: "Cambio", Icon: ArrowLeftRight },
] as const

function getIconComponent(value: string) {
  return ICON_OPTIONS.find(o => o.value === value)?.Icon ?? Banknote
}

function tipoValorLabel(code: string): string {
  return TIPO_VALOR_OPTIONS.find(o => o.value === code)?.label ?? code
}

type ItemForm = {
  id?: number
  descripcion: string
  comentario: string
  tipoValor: string
  tipoValor607: string
  idMonedaBase: number | null
  idMonedaOrigen: number | null
  tasaCambioOrigen: number
  tasaCambioBase: number
  factor: number
  mostrarEnPantallaCobro: boolean
  autoConsumo: boolean
  mostrarEnCobrosMixtos: boolean
  afectaCuadreCaja: boolean
  abreCajon: boolean
  requiereReferencia: boolean
  requiereAutorizacion: boolean
  posicion: number
  cantidadImpresiones: number
  colorFondo: string
  colorTexto: string
  icono: string
  active: boolean
}

function recordToForm(r: FacFormaPagoRecord): ItemForm {
  return {
    id: r.id,
    descripcion: r.descripcion,
    comentario: r.comentario,
    tipoValor: r.tipoValor,
    tipoValor607: r.tipoValor607,
    idMonedaBase: r.idMonedaBase,
    idMonedaOrigen: r.idMonedaOrigen,
    tasaCambioOrigen: r.tasaCambioOrigen,
    tasaCambioBase: r.tasaCambioBase,
    factor: r.factor,
    mostrarEnPantallaCobro: r.mostrarEnPantallaCobro,
    autoConsumo: r.autoConsumo,
    mostrarEnCobrosMixtos: r.mostrarEnCobrosMixtos,
    afectaCuadreCaja: r.afectaCuadreCaja,
    abreCajon: r.abreCajon,
    requiereReferencia: r.requiereReferencia,
    requiereAutorizacion: r.requiereAutorizacion,
    posicion: r.posicion,
    cantidadImpresiones: r.cantidadImpresiones,
    colorFondo: r.colorFondo,
    colorTexto: r.colorTexto,
    icono: r.icono,
    active: r.active,
  }
}

const emptyForm: ItemForm = {
  descripcion: "",
  comentario: "",
  tipoValor: "EF",
  tipoValor607: "",
  idMonedaBase: null,
  idMonedaOrigen: null,
  tasaCambioOrigen: 1,
  tasaCambioBase: 1,
  factor: 1,
  mostrarEnPantallaCobro: true,
  autoConsumo: false,
  mostrarEnCobrosMixtos: false,
  afectaCuadreCaja: true,
  abreCajon: false,
  requiereReferencia: false,
  requiereAutorizacion: false,
  posicion: 0,
  cantidadImpresiones: 1,
  colorFondo: "#3b82f6",
  colorTexto: "#ffffff",
  icono: "banknote",
  active: true,
}

type Props = {
  initialData: FacFormaPagoRecord[]
  currencies: { id: number; code: string; name: string; symbol: string }[]
  puntosEmision: { id: number; nombre: string }[]
}

const API_BASE = "/api/config/facturacion/formas-pago"

export function FacFormasPagoScreen({ initialData, currencies, puntosEmision }: Props) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<FacFormaPagoRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(initialData[0]?.id ?? null)
  const [form, setForm] = useState<ItemForm>(initialData[0] ? recordToForm(initialData[0]) : { ...emptyForm })
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [tab, setTab] = useState<DetailTab>("general")
  const [deleteTarget, setDeleteTarget] = useState<FacFormaPagoRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  // Puntos de emisión asociados
  const [puntosAsociados, setPuntosAsociados] = useState<number[]>([])
  const [puntosLoading, setPuntosLoading] = useState(false)

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q ? items.filter(i => i.descripcion.toLowerCase().includes(q)) : items
  }, [items, query])

  // Agrupar por moneda base para la sidebar
  const groupedItems = useMemo(() => {
    const groups: { moneda: string; items: FacFormaPagoRecord[] }[] = []
    const map = new Map<string, FacFormaPagoRecord[]>()
    for (const item of filteredItems) {
      const key = item.nombreMonedaBase || "Sin moneda asignada"
      if (!map.has(key)) { map.set(key, []); groups.push({ moneda: key, items: map.get(key)! }) }
      map.get(key)!.push(item)
    }
    return groups
  }, [filteredItems])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])

  // Close menu on outside click
  useEffect(() => {
    function onDown(e: MouseEvent) { if (!menuRef.current?.contains(e.target as Node)) setMenuId(null) }
    window.addEventListener("mousedown", onDown)
    return () => window.removeEventListener("mousedown", onDown)
  }, [])

  // Load puntos asociados
  const loadPuntosAsociados = useCallback(async (id: number) => {
    setPuntosLoading(true)
    try {
      const res = await fetch(apiUrl(`${API_BASE}/${id}/puntos`), { credentials: "include" })
      const result = await res.json() as { ok: boolean; data?: { idPuntoEmision: number }[] }
      if (result.ok && result.data) {
        setPuntosAsociados(result.data.map(p => p.idPuntoEmision))
      } else {
        setPuntosAsociados([])
      }
    } catch {
      setPuntosAsociados([])
    } finally {
      setPuntosLoading(false)
    }
  }, [])

  // Sync form when selection changes
  useEffect(() => {
    if (selected) {
      setForm(recordToForm(selected))
      setMessage(null)
      setTab("general")
      setPuntosAsociados([])
      return
    }
    if (!isEditing) {
      setForm({ ...emptyForm })
      setMessage(null)
      setTab("general")
      setPuntosAsociados([])
    }
  }, [isEditing, selected])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  // Auto-select first item
  useEffect(() => {
    if (isEditing || selectedId != null || items.length === 0) return
    setSelectedId(items[0].id)
  }, [isEditing, items, selectedId])

  // Load puntos when switching to "otros" tab
  useEffect(() => {
    if (tab === "otros" && selectedId != null) {
      void loadPuntosAsociados(selectedId)
    }
  }, [tab, selectedId, loadPuntosAsociados])

  function selectItem(id: number) {
    const run = () => {
      setSelectedId(id)
      setIsEditing(false)
      setMessage(null)
      setTab("general")
    }
    if (isEditing && selectedId !== id) {
      confirmAction(run)
      return
    }
    run()
  }

  function openNew() {
    const run = () => {
      setSelectedId(null)
      setForm({ ...emptyForm })
      setIsEditing(true)
      setMessage(null)
      setTab("general")
      setPuntosAsociados([])
      setMenuId(null)
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function openEdit(item: FacFormaPagoRecord) {
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

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      setForm(selected ? recordToForm(selected) : { ...emptyForm })
      setMessage(null)
      setDirty(false)
    })
  }

  function duplicateItem(item: FacFormaPagoRecord) {
    const run = () => {
      setSelectedId(null)
      setForm({
        ...recordToForm(item),
        id: undefined,
        descripcion: `${item.descripcion} COPIA`,
      })
      setIsEditing(true)
      setMenuId(null)
      setMessage(null)
      setTab("general")
      setPuntosAsociados([])
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function togglePuntoAsociado(idPunto: number) {
    setPuntosAsociados(prev =>
      prev.includes(idPunto) ? prev.filter(p => p !== idPunto) : [...prev, idPunto]
    )
  }

  async function savePuntosAsociados(id: number) {
    await fetch(apiUrl(`${API_BASE}/${id}/puntos`), {
      method: "PUT",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ puntosEmision: puntosAsociados }),
    })
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.descripcion.trim()) { setMessage("La descripción es obligatoria."); return }

    startTransition(async () => {
      try {
        const url = form.id
          ? apiUrl(`${API_BASE}/${form.id}`)
          : apiUrl(API_BASE)
        const res = await fetch(url, {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...form, descripcion: (form.descripcion || "").toUpperCase() }),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; data?: FacFormaPagoRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }

        const savedId = result.data!.id
        await savePuntosAsociados(savedId)

        toast.success(form.id ? "Forma de pago actualizada" : "Forma de pago creada")
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
        const res = await fetch(apiUrl(`${API_BASE}/${id}`), { method: "DELETE", credentials: "include" })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Forma de pago eliminada")
        setItems(prev => prev.filter(i => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm({ ...emptyForm }); setPuntosAsociados([]) }
        setMenuId(null)
        setDeleteTarget(null)
        router.refresh()
      } catch { toast.error("Error al eliminar.") }
    })
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        {/* -- Sidebar -- */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <CreditCard size={17} />
              <h2>Formas de Pago</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva forma de pago">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.length === 0 && (
              <p className="price-lists-empty-msg">No hay formas de pago configuradas</p>
            )}
            {groupedItems.map((group) => (
              <div key={group.moneda}>
                <div style={{ padding: "0.45rem 0.7rem", fontSize: "0.72rem", fontWeight: 700, color: "var(--brand)", textTransform: "uppercase", letterSpacing: "0.04em", background: "var(--bg, #f8fafc)", borderBottom: "1px solid var(--line)", position: "sticky", top: 0, zIndex: 1 }}>
                  Moneda Base : {group.moneda}
                </div>
                {group.items.map((item) => (
                  <div
                    key={item.id}
                    className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}`}
                    onClick={() => selectItem(item.id)}
                  >
                    <div className="price-lists-sidebar__item-top">
                      <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                        {item.active ? t("common.active") : t("common.inactive")}
                      </span>
                      <span className="price-lists-sidebar__code">#{item.id}</span>
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
                    <p className="price-lists-sidebar__desc">{item.descripcion}</p>
                    <p className="price-lists-sidebar__meta">
                      {tipoValorLabel(item.tipoValor)} · {item.nombreMonedaOrigen || "—"}
                    </p>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </aside>

        {/* -- Panel Principal -- */}
        <main className="price-lists-main">
          {selected || isEditing ? (
            <form onSubmit={onSubmit} style={{ display: "flex", flexDirection: "column", height: "100%" }}>
              <div className="products-detail__action-bar">
                {isEditing ? (
                  <div className="products-detail__action-bar-btns">
                    <button type="button" className="secondary-button" onClick={closeEditor}>
                      <X size={16} /> {t("common.cancel")}
                    </button>
                    <button type="submit" className="primary-button" disabled={isPending}>
                      {isPending ? <Loader2 size={16} className="spin" /> : <Save size={16} />}
                      {t("common.save")}
                    </button>
                  </div>
                ) : null}
              </div>

              {/* Tabs */}
              <div className="price-lists-tabs">
                <button
                  type="button"
                  className={tab === "general" ? "filter-pill is-active" : "filter-pill"}
                  onClick={() => setTab("general")}
                >
                  Datos Generales
                </button>
                {form.id && (
                  <button
                    type="button"
                    className={tab === "otros" ? "filter-pill is-active" : "filter-pill"}
                    onClick={() => setTab("otros")}
                  >
                    Otros Parámetros
                  </button>
                )}
              </div>

              {message && <div className="form-message" style={{ margin: "0.75rem 1.2rem 0" }}>{message}</div>}

              {/* Tab Datos Generales */}
              {tab === "general" && (
                <div className="price-lists-form">
                  <div className="form-grid">
                    {/* Row 1: Descripción + Activo */}
                    <div className="form-grid__row-with-toggle">
                      <label style={{ flex: "1 1 0" }}>
                        <span>Descripción *</span>
                        <input
                          value={form.descripcion}
                          onChange={(e) => setForm({ ...form, descripcion: e.target.value })}
                          disabled={!isEditing}
                          maxLength={150}
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

                    {/* Row 2: Comentario */}
                    <label className="form-grid__full">
                      <span>Comentario</span>
                      <textarea
                        rows={2}
                        value={form.comentario}
                        onChange={(e) => setForm({ ...form, comentario: e.target.value })}
                        disabled={!isEditing}
                        maxLength={500}
                      />
                    </label>

                    {/* Section: Tipo de Valor */}
                    <div className="form-grid__full" style={{ marginTop: "0.25rem" }}>
                      <div style={sectionTitle}>Tipo de Valor</div>
                    </div>

                    <label>
                      <span>Tipo de Valor</span>
                      <select
                        value={form.tipoValor}
                        onChange={(e) => setForm({ ...form, tipoValor: e.target.value })}
                        disabled={!isEditing}
                      >
                        {TIPO_VALOR_OPTIONS.map(o => (
                          <option key={o.value} value={o.value}>{o.label}</option>
                        ))}
                      </select>
                    </label>

                    <label>
                      <span>Tipo de Valor 607</span>
                      <select
                        value={form.tipoValor607}
                        onChange={(e) => setForm({ ...form, tipoValor607: e.target.value })}
                        disabled={!isEditing}
                      >
                        {TIPO_VALOR_607_OPTIONS.map(o => (
                          <option key={o.value} value={o.value}>{o.label}</option>
                        ))}
                      </select>
                    </label>

                    {/* Section: Monedas y Conversión */}
                    <div className="form-grid__full" style={{ marginTop: "0.25rem" }}>
                      <div style={sectionTitle}>Monedas y Conversión</div>
                    </div>

                    <label>
                      <span>Moneda Base</span>
                      <select
                        value={form.idMonedaBase ?? ""}
                        onChange={(e) => setForm({ ...form, idMonedaBase: e.target.value ? Number(e.target.value) : null })}
                        disabled={!isEditing}
                      >
                        <option value="">Sin moneda asignada</option>
                        {currencies.map(c => (
                          <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                        ))}
                      </select>
                    </label>

                    <label>
                      <span>Moneda Origen</span>
                      <select
                        value={form.idMonedaOrigen ?? ""}
                        onChange={(e) => setForm({ ...form, idMonedaOrigen: e.target.value ? Number(e.target.value) : null })}
                        disabled={!isEditing}
                      >
                        <option value="">Sin moneda asignada</option>
                        {currencies.map(c => (
                          <option key={c.id} value={c.id}>{c.code} - {c.name}</option>
                        ))}
                      </select>
                    </label>

                    <label>
                      <span>Tasa Cambio Origen</span>
                      <input
                        type="number"
                        step="0.000001"
                        min={0}
                        value={form.tasaCambioOrigen}
                        onChange={(e) => setForm({ ...form, tasaCambioOrigen: Number(e.target.value) })}
                        disabled={!isEditing}
                      />
                    </label>

                    <label>
                      <span>Tasa Cambio Base</span>
                      <input
                        type="number"
                        step="0.000001"
                        min={0}
                        value={form.tasaCambioBase}
                        onChange={(e) => setForm({ ...form, tasaCambioBase: Number(e.target.value) })}
                        disabled={!isEditing}
                      />
                    </label>

                    <label>
                      <span>Factor</span>
                      <input
                        type="number"
                        step="0.000001"
                        min={0}
                        value={form.factor}
                        onChange={(e) => setForm({ ...form, factor: Number(e.target.value) })}
                        disabled={!isEditing}
                      />
                    </label>

                    {/* Section: Opciones de Cobro */}
                    <div className="form-grid__full" style={{ marginTop: "0.25rem" }}>
                      <div style={sectionTitle}>Opciones de Cobro</div>
                    </div>

                    <div className="form-grid__full" style={{ display: "flex", flexWrap: "wrap", gap: "1.2rem" }}>
                      <label className="form-grid__toggle">
                        <span>Mostrar en Pantalla de Cobro</span>
                        <button
                          type="button"
                          className={form.mostrarEnPantallaCobro ? "toggle-switch is-on" : "toggle-switch"}
                          onClick={() => isEditing && setForm({ ...form, mostrarEnPantallaCobro: !form.mostrarEnPantallaCobro })}
                          disabled={!isEditing}
                        >
                          <span />
                        </button>
                      </label>

                      <label className="form-grid__toggle">
                        <span>Auto-Consumo</span>
                        <button
                          type="button"
                          className={form.autoConsumo ? "toggle-switch is-on" : "toggle-switch"}
                          onClick={() => isEditing && setForm({ ...form, autoConsumo: !form.autoConsumo })}
                          disabled={!isEditing}
                        >
                          <span />
                        </button>
                      </label>

                      <label className="form-grid__toggle">
                        <span>Mostrar en Cobros Mixtos</span>
                        <button
                          type="button"
                          className={form.mostrarEnCobrosMixtos ? "toggle-switch is-on" : "toggle-switch"}
                          onClick={() => isEditing && setForm({ ...form, mostrarEnCobrosMixtos: !form.mostrarEnCobrosMixtos })}
                          disabled={!isEditing}
                        >
                          <span />
                        </button>
                      </label>

                      <label className="form-grid__toggle">
                        <span>Afecta Cuadre de Caja</span>
                        <button type="button" className={form.afectaCuadreCaja ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, afectaCuadreCaja: !form.afectaCuadreCaja })} disabled={!isEditing}><span /></button>
                      </label>

                      <label className="form-grid__toggle">
                        <span>Abre Cajón</span>
                        <button type="button" className={form.abreCajon ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, abreCajon: !form.abreCajon })} disabled={!isEditing}><span /></button>
                      </label>

                      <label className="form-grid__toggle">
                        <span>Requiere Referencia</span>
                        <button type="button" className={form.requiereReferencia ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, requiereReferencia: !form.requiereReferencia })} disabled={!isEditing}><span /></button>
                      </label>

                      <label className="form-grid__toggle">
                        <span>Requiere Autorización</span>
                        <button type="button" className={form.requiereAutorizacion ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, requiereAutorizacion: !form.requiereAutorizacion })} disabled={!isEditing}><span /></button>
                      </label>
                    </div>

                    {/* Posición + Grupo Cierre */}
                    <label>
                      <span>Posición en Pantalla</span>
                      <input
                        type="number"
                        min={0}
                        value={form.posicion}
                        onChange={(e) => setForm({ ...form, posicion: Number(e.target.value) })}
                        disabled={!isEditing}
                      />
                    </label>

                  </div>
                </div>
              )}

              {/* Tab Otros Parámetros */}
              {tab === "otros" && (
                <div className="price-lists-form">
                  <div className="form-grid">
                    {/* Section: Puntos de Emisión Asociados */}
                    <div className="form-grid__full">
                      <div style={sectionTitle}>Puntos de Emisión Asociados</div>
                      {puntosLoading ? (
                        <div style={{ display: "flex", alignItems: "center", gap: "0.4rem", color: "var(--muted)", fontSize: "0.82rem" }}>
                          <Loader2 size={13} className="spin" /> Cargando puntos...
                        </div>
                      ) : (
                        <div style={{ border: "1px solid var(--line)", borderRadius: "0.7rem", overflow: "hidden" }}>
                          <div style={{ padding: "0.5rem 0.75rem", background: "var(--bg, #f8fafc)", borderBottom: "1px solid var(--line)", fontSize: "0.8rem", color: "var(--muted)" }}>
                            Seleccione los Puntos de Emisión donde estará disponible esta forma de pago
                          </div>
                          <div>
                            {puntosEmision.length === 0 ? (
                              <div style={{ padding: "0.6rem 0.75rem", fontSize: "0.82rem", color: "var(--muted)" }}>No hay puntos de emisión configurados.</div>
                            ) : (
                              puntosEmision.map((p) => (
                                <label key={p.id} style={{ display: "flex", alignItems: "center", gap: "0.55rem", padding: "0.4rem 0.75rem", borderBottom: "1px solid var(--line)", cursor: isEditing ? "pointer" : "default", fontSize: "0.85rem", color: "var(--ink)" }}>
                                  <input type="checkbox" checked={puntosAsociados.includes(p.id)} onChange={() => isEditing && togglePuntoAsociado(p.id)} disabled={!isEditing} style={{ width: "14px", height: "14px", flexShrink: 0, accentColor: "var(--brand)" }} />
                                  {p.nombre}
                                </label>
                              ))
                            )}
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Section: Personalización */}
                    <div className="form-grid__full" style={{ marginTop: "0.5rem" }}>
                      <div style={sectionTitle}>Personalización</div>
                    </div>

                    <label>
                      <span>Cantidad de Impresiones</span>
                      <input
                        type="number"
                        min={0}
                        value={form.cantidadImpresiones}
                        onChange={(e) => setForm({ ...form, cantidadImpresiones: Number(e.target.value) })}
                        disabled={!isEditing}
                      />
                    </label>

                    {/* Icono */}
                    <div className="form-grid__full">
                      <span style={{ fontSize: "0.85rem", color: "var(--muted)", fontWeight: 700, marginBottom: "0.35rem", display: "block" }}>Icono</span>
                      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(70px, 1fr))", gap: "0.4rem" }}>
                        {ICON_OPTIONS.map(({ value, label, Icon }) => (
                          <button
                            key={value}
                            type="button"
                            onClick={() => isEditing && setForm({ ...form, icono: value })}
                            disabled={!isEditing}
                            style={{
                              display: "flex", flexDirection: "column", alignItems: "center", gap: "0.2rem",
                              padding: "0.5rem 0.25rem", borderRadius: "0.55rem", cursor: isEditing ? "pointer" : "default",
                              border: form.icono === value ? "2px solid var(--brand)" : "1px solid var(--line)",
                              background: form.icono === value ? "var(--brand-light, #eff6ff)" : "#fff",
                              color: form.icono === value ? "var(--brand)" : "var(--muted)",
                              fontSize: "0.65rem", fontWeight: form.icono === value ? 700 : 400,
                              transition: "all 120ms ease",
                            }}
                          >
                            <Icon size={18} />
                            {label}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Colores */}
                    <div className="form-grid__full" style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: "0.9rem", alignItems: "start" }}>
                      <label>
                        <span>Color de Fondo</span>
                        <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                          <input
                            type="color"
                            value={form.colorFondo || "#3b82f6"}
                            onChange={(e) => setForm({ ...form, colorFondo: e.target.value })}
                            disabled={!isEditing}
                            style={{ width: "3rem", height: "2.2rem", padding: "0.1rem", border: "1px solid var(--line)", borderRadius: "0.5rem", cursor: isEditing ? "pointer" : "default" }}
                          />
                          <input
                            value={form.colorFondo || "#3b82f6"}
                            onChange={(e) => setForm({ ...form, colorFondo: e.target.value })}
                            disabled={!isEditing}
                            maxLength={7}
                            style={{ flex: 1, fontFamily: "monospace", fontSize: "0.82rem" }}
                          />
                        </div>
                      </label>
                      <label>
                        <span>Color de Texto</span>
                        <div style={{ display: "flex", alignItems: "center", gap: "0.5rem" }}>
                          <input
                            type="color"
                            value={form.colorTexto || "#ffffff"}
                            onChange={(e) => setForm({ ...form, colorTexto: e.target.value })}
                            disabled={!isEditing}
                            style={{ width: "3rem", height: "2.2rem", padding: "0.1rem", border: "1px solid var(--line)", borderRadius: "0.5rem", cursor: isEditing ? "pointer" : "default" }}
                          />
                          <input
                            value={form.colorTexto || "#ffffff"}
                            onChange={(e) => setForm({ ...form, colorTexto: e.target.value })}
                            disabled={!isEditing}
                            maxLength={7}
                            style={{ flex: 1, fontFamily: "monospace", fontSize: "0.82rem" }}
                          />
                        </div>
                      </label>

                      {/* Vista Previa */}
                      <label>
                        <span>Vista Previa</span>
                        {(() => { const PreviewIcon = getIconComponent(form.icono); return (
                          <div
                            style={{
                              display: "inline-flex", alignItems: "center", gap: "0.5rem",
                              padding: "0.6rem 1.2rem", borderRadius: "0.7rem",
                              backgroundColor: form.colorFondo || "#3b82f6",
                              color: form.colorTexto || "#ffffff",
                              fontWeight: 700, fontSize: "0.85rem",
                            }}
                          >
                            <PreviewIcon size={18} />
                            {form.descripcion || "Forma de Pago"}
                          </div>
                        ); })()}
                      </label>
                    </div>
                  </div>
                </div>
              )}
            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona una forma de pago o crea una nueva</p>
            </div>
          )}
        </main>
      </div>

      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Forma de pago"
        itemName={deleteTarget?.descripcion ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}
