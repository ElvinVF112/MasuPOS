"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { GitBranch, Loader2, MoreHorizontal, Pencil, Plus, Save, Search, Share2, Trash2, X, Zap } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"
import type { CatalogoNCFRecord, SecuenciasNCFRecord } from "@/lib/pos-data"

type EmisionOption = { id: number; nombre: string }

type Form = {
  id?: number
  idCatalogoNCF: number | null
  idPuntoEmision: number | null
  idSecuenciaMadre: number | null
  usoComprobante: "D" | "O"
  descripcion: string
  esElectronico: boolean
  digitosSecuencia: 8 | 10
  prefijo: string
  rangoDesde: string
  rangoHasta: string
  secuenciaActual: string
  fechaVencimiento: string
  colaPrefijo: string
  colaRangoDesde: string
  colaRangoHasta: string
  colaFechaVencimiento: string
  minimoParaAlertar: string
  rellenoAutomatico: string
  active: boolean
}

const emptyForm: Form = {
  idCatalogoNCF: null,
  idPuntoEmision: null,
  idSecuenciaMadre: null,
  usoComprobante: "D",
  descripcion: "",
  esElectronico: false,
  digitosSecuencia: 8,
  prefijo: "",
  rangoDesde: "1",
  rangoHasta: "",
  secuenciaActual: "0",
  fechaVencimiento: "",
  colaPrefijo: "",
  colaRangoDesde: "",
  colaRangoHasta: "",
  colaFechaVencimiento: "",
  minimoParaAlertar: "10",
  rellenoAutomatico: "",
  active: true,
}

function recordToForm(r: SecuenciasNCFRecord): Form {
  return {
    id: r.id,
    idCatalogoNCF: r.idCatalogoNCF,
    idPuntoEmision: r.idPuntoEmision,
    idSecuenciaMadre: r.idSecuenciaMadre,
    usoComprobante: r.usoComprobante,
    descripcion: r.descripcion,
    esElectronico: r.esElectronico,
    digitosSecuencia: (r.digitosSecuencia === 10 ? 10 : 8) as 8 | 10,
    prefijo: r.prefijo,
    rangoDesde: String(r.rangoDesde),
    rangoHasta: String(r.rangoHasta),
    secuenciaActual: String(r.secuenciaActual),
    fechaVencimiento: r.fechaVencimiento,
    colaPrefijo: r.colaPrefijo,
    colaRangoDesde: r.colaRangoDesde != null ? String(r.colaRangoDesde) : "",
    colaRangoHasta: r.colaRangoHasta != null ? String(r.colaRangoHasta) : "",
    colaFechaVencimiento: r.colaFechaVencimiento,
    minimoParaAlertar: String(r.minimoParaAlertar),
    rellenoAutomatico: r.RellenoAutomatico != null ? String(r.RellenoAutomatico) : "",
    active: r.active,
  }
}

function formToPayload(form: Form) {
  return {
    idCatalogoNCF: form.idCatalogoNCF,
    idPuntoEmision: form.usoComprobante === "O" ? (form.idPuntoEmision || null) : null,
    idSecuenciaMadre: form.usoComprobante === "O" ? form.idSecuenciaMadre : null,
    usoComprobante: form.usoComprobante,
    descripcion: form.descripcion || null,
    esElectronico: form.esElectronico,
    digitosSecuencia: form.digitosSecuencia,
    prefijo: form.prefijo || null,
    rangoDesde: Number(form.rangoDesde),
    rangoHasta: Number(form.rangoHasta),
    secuenciaActual: form.secuenciaActual ? Number(form.secuenciaActual) : null,
    fechaVencimiento: form.fechaVencimiento || null,
    colaPrefijo: form.colaPrefijo || null,
    colaRangoDesde: form.colaRangoDesde ? Number(form.colaRangoDesde) : null,
    colaRangoHasta: form.colaRangoHasta ? Number(form.colaRangoHasta) : null,
    colaFechaVencimiento: form.colaFechaVencimiento || null,
    minimoParaAlertar: Number(form.minimoParaAlertar) || 10,
    RellenoAutomatico: form.rellenoAutomatico ? Number(form.rellenoAutomatico) : null,
    active: form.active,
  }
}

type Props = {
  initialData: SecuenciasNCFRecord[]
  catalogo: CatalogoNCFRecord[]
  puntosEmision: EmisionOption[]
}

// ── Tabla compacta de secuencias ─────────────────────────────
const tbl: React.CSSProperties = { width: "100%", borderCollapse: "collapse", fontSize: "0.82rem" }
const thBase: React.CSSProperties = { padding: "0.4rem 0.6rem", fontWeight: 700, fontSize: "0.78rem", color: "var(--muted)", borderBottom: "2px solid var(--line)", borderRight: "1px solid var(--line)", whiteSpace: "nowrap", textTransform: "uppercase", letterSpacing: "0.04em" }
const tdLabel: React.CSSProperties = { padding: "0.35rem 0.5rem", color: "var(--muted)", whiteSpace: "nowrap", borderBottom: "1px solid var(--line)", fontSize: "0.82rem", fontWeight: 700 }
const tdInput: React.CSSProperties = { padding: "0.2rem 0.4rem", borderBottom: "1px solid var(--line)", borderRight: "1px solid var(--line)" }
const inputSm: React.CSSProperties = { padding: "0.45rem 0.6rem", fontSize: "0.82rem", width: "100%", minWidth: 0, textAlign: "right", border: "1px solid var(--line)", borderRadius: "0.55rem", background: "#fff", color: "var(--ink)", fontFamily: "inherit" }
const inputDate: React.CSSProperties = { padding: "0.45rem 0.6rem", fontSize: "0.82rem", width: "100%", border: "1px solid var(--line)", borderRadius: "0.55rem", background: "#fff", color: "var(--ink)", fontFamily: "inherit" }
const sectionTitle: React.CSSProperties = { fontSize: "0.78rem", fontWeight: 700, color: "var(--brand)", textTransform: "uppercase", letterSpacing: "0.05em", borderBottom: "2px solid var(--brand)", paddingBottom: "0.25rem", marginBottom: "0.7rem" }
const paramLabel: React.CSSProperties = { fontSize: "0.78rem", color: "var(--muted)", fontWeight: 700, whiteSpace: "nowrap" }

export function ImpuestosSecuenciasNCFScreen({ initialData, catalogo, puntosEmision }: Props) {
  const router = useRouter()
  const { t } = useI18n()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const menuRef = useRef<HTMLUListElement | null>(null)

  const [items, setItems] = useState<SecuenciasNCFRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(initialData[0]?.id ?? null)
  const [form, setForm] = useState<Form>(initialData[0] ? recordToForm(initialData[0]) : emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<SecuenciasNCFRecord | null>(null)
  const [isPending, startTransition] = useTransition()

  // Puntos compartidos (solo para hijas)
  const [puntosCompartidos, setPuntosCompartidos] = useState<number[]>([])
  const [puntosLoading, setPuntosLoading] = useState(false)

  // Distribuir modal
  const [distribuirTarget, setDistribuirTarget] = useState<SecuenciasNCFRecord | null>(null)
  const [distribuirCantidad, setDistribuirCantidad] = useState("")
  const [distribuirObs, setDistribuirObs] = useState("")
  const [distribuirPending, startDistribuirTransition] = useTransition()

  const madresDisponibles = useMemo(
    () => items.filter((i) => i.usoComprobante === "D" && i.active),
    [items]
  )

  const filteredItems = useMemo(() => {
    const q = query.toLowerCase().trim()
    return q
      ? items.filter((i) =>
          i.descripcion.toLowerCase().includes(q) ||
          i.codigoNCF.toLowerCase().includes(q) ||
          i.nombreNCF.toLowerCase().includes(q)
        )
      : items
  }, [items, query])

  const selected = useMemo(() => items.find((i) => i.id === selectedId) ?? null, [items, selectedId])

  const cantidadRestante = useMemo(() => {
    if (!selected) return 0
    if (selected.secuenciaActual === 0) return selected.rangoHasta - selected.rangoDesde + 1
    return selected.rangoHasta - selected.secuenciaActual
  }, [selected])

  const enAlerta = selected ? cantidadRestante <= selected.minimoParaAlertar : false

  // Cargar puntos compartidos cuando se selecciona una hija
  const loadPuntosCompartidos = useCallback(async (id: number) => {
    setPuntosLoading(true)
    try {
      const res = await fetch(`${apiUrl("/api/config/impuestos/secuencias-fiscales")}/${id}/puntos`, { credentials: "include" })
      const result = await res.json() as { ok: boolean; data?: { idPuntoEmision: number }[] }
      if (result.ok && result.data) {
        setPuntosCompartidos(result.data.map((p) => p.idPuntoEmision))
      } else {
        setPuntosCompartidos([])
      }
    } catch {
      setPuntosCompartidos([])
    } finally {
      setPuntosLoading(false)
    }
  }, [])

  useEffect(() => {
    function onPointerDown(e: MouseEvent) {
      if (!menuRef.current?.contains(e.target as Node)) setMenuId(null)
    }
    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  useEffect(() => {
    if (selected) {
      setForm(recordToForm(selected))
      if (selected.usoComprobante === "O") {
        void loadPuntosCompartidos(selected.id)
      } else {
        setPuntosCompartidos([])
      }
      return
    }
    if (!isEditing) { setForm(emptyForm); setPuntosCompartidos([]) }
  }, [isEditing, selected, loadPuntosCompartidos])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  useEffect(() => {
    if (isEditing || selectedId != null || items.length === 0) return
    setSelectedId(items[0].id)
  }, [isEditing, items, selectedId])

  function selectItem(id: number) {
    const run = () => { setSelectedId(id); setIsEditing(false); setMessage(null) }
    if (isEditing && selectedId !== id) { confirmAction(run); return }
    run()
  }

  function openNew() {
    const run = () => { setSelectedId(null); setForm(emptyForm); setPuntosCompartidos([]); setIsEditing(true); setMessage(null) }
    if (isEditing) { confirmAction(run); return }
    run()
  }

  function openEdit(item: SecuenciasNCFRecord) {
    const run = () => { setSelectedId(item.id); setForm(recordToForm(item)); setIsEditing(true); setMenuId(null); setMessage(null) }
    if (isEditing && selectedId !== item.id) { confirmAction(run); return }
    run()
  }

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      if (selected) setForm(recordToForm(selected))
      else { setForm(emptyForm); setPuntosCompartidos([]) }
      setMessage(null)
      setDirty(false)
    })
  }

  async function savePuntosCompartidos(id: number) {
    if (form.usoComprobante !== "O") return
    await fetch(`${apiUrl("/api/config/impuestos/secuencias-fiscales")}/${id}/puntos`, {
      method: "PUT",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ puntosEmision: puntosCompartidos }),
    })
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.idCatalogoNCF) { setMessage("El tipo de comprobante es obligatorio."); return }
    if (!form.rangoHasta) { setMessage("El rango final es obligatorio."); return }
    if (form.usoComprobante === "O" && !form.idSecuenciaMadre) { setMessage("Una secuencia de Operación requiere una secuencia madre."); return }

    startTransition(async () => {
      try {
        const url = form.id
          ? `${apiUrl("/api/config/impuestos/secuencias-fiscales")}/${form.id}`
          : apiUrl("/api/config/impuestos/secuencias-fiscales")
        const method = form.id ? "PUT" : "POST"
        const response = await fetch(url, {
          method,
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(formToPayload(form)),
        })
        const result = (await response.json()) as { ok: boolean; message?: string; data?: SecuenciasNCFRecord }
        if (!response.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }

        const savedId = result.data!.id
        await savePuntosCompartidos(savedId)

        toast.success(form.id ? "Secuencia actualizada" : "Secuencia creada")
        if (form.id) {
          setItems((prev) => prev.map((i) => (i.id === form.id ? result.data! : i)))
        } else {
          setItems((prev) => [...prev, result.data!])
          setSelectedId(savedId)
        }
        setIsEditing(false)
        setDirty(false)
        router.refresh()
      } catch {
        setMessage("Error al guardar.")
      }
    })
  }

  async function handleDelete(id: number) {
    startTransition(async () => {
      try {
        const response = await fetch(`${apiUrl("/api/config/impuestos/secuencias-fiscales")}/${id}`, {
          method: "DELETE",
          credentials: "include",
        })
        const result = (await response.json()) as { ok: boolean; message?: string }
        if (!response.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Secuencia eliminada")
        setItems((prev) => prev.filter((i) => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm(emptyForm); setPuntosCompartidos([]) }
        setDeleteTarget(null)
        router.refresh()
      } catch {
        toast.error("Error al eliminar.")
      }
    })
  }

  async function handleDistribuir() {
    if (!distribuirTarget || !distribuirCantidad) return
    startDistribuirTransition(async () => {
      try {
        const response = await fetch(
          `${apiUrl("/api/config/impuestos/secuencias-fiscales")}/${distribuirTarget.id}/distribuir`,
          {
            method: "POST",
            credentials: "include",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              idSecuenciaMadre: distribuirTarget.idSecuenciaMadre,
              cantidadDistribuir: Number(distribuirCantidad),
              observacion: distribuirObs || null,
            }),
          }
        )
        const result = (await response.json()) as { ok: boolean; message?: string; data?: SecuenciasNCFRecord }
        if (!response.ok || !result.ok) { toast.error(result.message ?? "No se pudo distribuir."); return }
        toast.success("Distribución realizada")
        setItems((prev) => prev.map((i) => (i.id === result.data!.id ? result.data! : i)))
        if (selectedId === result.data!.id) setForm(recordToForm(result.data!))
        setDistribuirTarget(null)
        setDistribuirCantidad("")
        setDistribuirObs("")
      } catch {
        toast.error("Error al distribuir.")
      }
    })
  }

  function togglePuntoCompartido(idPunto: number) {
    setPuntosCompartidos((prev) =>
      prev.includes(idPunto) ? prev.filter((p) => p !== idPunto) : [...prev, idPunto]
    )
  }

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        {/* ── Sidebar ── */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <GitBranch size={17} />
              <h2>Secuencias NCF</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nueva secuencia">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar secuencia..."
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
                  {item.usoComprobante === "D" ? (
                    <span style={{ fontSize: "0.65rem", background: "#fef3c7", color: "#92400e", padding: "0.1rem 0.35rem", borderRadius: "3px", fontWeight: 600 }}>MADRE</span>
                  ) : (
                    <span style={{ fontSize: "0.65rem", background: "#e0f2fe", color: "#0369a1", padding: "0.1rem 0.35rem", borderRadius: "3px", fontWeight: 600 }}>HIJA</span>
                  )}
                  {item.esElectronico && <Zap size={11} style={{ color: "var(--brand)" }} />}
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
                        <li><button type="button" onClick={() => openEdit(item)}><Pencil size={13} /> {t("common.edit")}</button></li>
                        {item.usoComprobante === "O" && item.idSecuenciaMadre && (
                          <li>
                            <button type="button" onClick={() => { setDistribuirTarget(item); setMenuId(null) }}>
                              <Share2 size={13} /> Distribuir desde madre
                            </button>
                          </li>
                        )}
                        <li className="is-danger"><button type="button" onClick={() => { setDeleteTarget(item); setMenuId(null) }}><Trash2 size={13} /> {t("common.delete")}</button></li>
                      </ul>
                    )}
                  </div>
                </div>
                <p className="price-lists-sidebar__desc">
                  <strong>{item.codigoNCF}</strong> — {item.descripcion || item.nombreNCF}
                </p>
                {item.idPuntoEmision && (
                  <p className="price-lists-sidebar__meta">{item.nombrePuntoEmision}</p>
                )}
              </div>
            ))}
          </div>
        </aside>

        {/* ── Main form ── */}
        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="price-lists-form" onSubmit={onSubmit}>
              {/* Header */}
              <div className="price-lists-form__header">
                <div className="price-lists-sidebar__title">
                  <GitBranch size={17} />
                  <h3>{form.id ? (form.descripcion || "Secuencia NCF") : "Nueva Secuencia NCF"}</h3>
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
                    selected && (
                      <>
                        <button type="button" className="secondary-button" onClick={() => openEdit(selected)}>
                          <Pencil size={15} /> {t("common.edit")}
                        </button>
                        {selected.usoComprobante === "O" && selected.idSecuenciaMadre && (
                          <button type="button" className="primary-button" onClick={() => setDistribuirTarget(selected)}>
                            <Share2 size={15} /> Distribuir desde Madre
                          </button>
                        )}
                      </>
                    )
                  )}
                </div>
              </div>

              {message && <div className="form-message">{message}</div>}

              <div className="form-grid">

                {/* ── Fila 1: Descripción + Tipo de Comprobante + e-CF + Activo ── */}
                <div className="form-grid__row-with-toggle">
                  <label style={{ flex: "1 1 0" }}>
                    <span>Descripción</span>
                    <input
                      value={form.descripcion}
                      onChange={(e) => setForm({ ...form, descripcion: e.target.value })}
                      disabled={!isEditing}
                      placeholder="Ej. Facturas de consumo — Tienda Centro"
                    />
                  </label>
                  <label style={{ flex: "1 1 0" }}>
                    <span>Tipo de Comprobante *</span>
                    <select
                      value={form.idCatalogoNCF ?? ""}
                      onChange={(e) => {
                        const id = e.target.value ? Number(e.target.value) : null
                        const cat = catalogo.find((c) => c.id === id)
                        setForm({ ...form, idCatalogoNCF: id, esElectronico: cat?.esElectronico ?? false })
                      }}
                      disabled={!isEditing}
                      required
                    >
                      <option value="">— Seleccionar tipo —</option>
                      {catalogo.filter((c) => c.active).map((c) => (
                        <option key={c.id} value={c.id}>{c.codigo} — {c.nombreInterno || c.nombre}</option>
                      ))}
                    </select>
                  </label>
                  <label className="form-grid__toggle">
                    <span>e-CF</span>
                    <button type="button" className={form.esElectronico ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, esElectronico: !form.esElectronico })} disabled={!isEditing}><span /></button>
                  </label>
                  <label className="form-grid__toggle">
                    <span>Activo</span>
                    <button type="button" className={form.active ? "toggle-switch is-on" : "toggle-switch"} onClick={() => isEditing && setForm({ ...form, active: !form.active })} disabled={!isEditing}><span /></button>
                  </label>
                </div>

                {/* ── Fila 2: Secuencia Madre + Uso + Dígitos ── */}
                {form.usoComprobante === "O" ? (
                  <div className="form-grid__row-with-toggle">
                    <label style={{ flex: "1 1 0" }}>
                      <span>Secuencia Madre *</span>
                      <select value={form.idSecuenciaMadre ?? ""} onChange={(e) => setForm({ ...form, idSecuenciaMadre: e.target.value ? Number(e.target.value) : null })} disabled={!isEditing} required>
                        <option value="">— Seleccionar madre —</option>
                        {madresDisponibles.map((m) => (
                          <option key={m.id} value={m.id}>{m.codigoNCF} — {m.descripcion || m.nombreNCF}</option>
                        ))}
                      </select>
                    </label>
                    <label style={{ flex: "1 1 0" }}>
                      <span>Uso del Comprobante</span>
                      <select value={form.usoComprobante} onChange={(e) => { const val = e.target.value as "D" | "O"; setForm({ ...form, usoComprobante: val, idSecuenciaMadre: val === "D" ? null : form.idSecuenciaMadre, idPuntoEmision: val === "D" ? null : form.idPuntoEmision }); if (val === "D") setPuntosCompartidos([]) }} disabled={!isEditing}>
                        <option value="D">Distribución (Madre)</option>
                        <option value="O">Operación (Hija)</option>
                      </select>
                    </label>
                    <label style={{ flex: "0 0 auto", minWidth: "150px" }}>
                      <span>Dígitos de Secuencia</span>
                      <select value={form.digitosSecuencia} onChange={(e) => setForm({ ...form, digitosSecuencia: Number(e.target.value) as 8 | 10 })} disabled={!isEditing}>
                        <option value={8}>8 dígitos</option>
                        <option value={10}>10 dígitos</option>
                      </select>
                    </label>
                  </div>
                ) : (
                  <div className="form-grid__row-with-toggle">
                    <label style={{ flex: "1 1 0" }}>
                      <span>Uso del Comprobante</span>
                      <select value={form.usoComprobante} onChange={(e) => { const val = e.target.value as "D" | "O"; setForm({ ...form, usoComprobante: val, idSecuenciaMadre: null, idPuntoEmision: null }); setPuntosCompartidos([]) }} disabled={!isEditing}>
                        <option value="D">Distribución (Madre)</option>
                        <option value="O">Operación (Hija)</option>
                      </select>
                    </label>
                    <label style={{ flex: "0 0 auto", minWidth: "150px" }}>
                      <span>Dígitos de Secuencia</span>
                      <select value={form.digitosSecuencia} onChange={(e) => setForm({ ...form, digitosSecuencia: Number(e.target.value) as 8 | 10 })} disabled={!isEditing}>
                        <option value={8}>8 dígitos</option>
                        <option value={10}>10 dígitos</option>
                      </select>
                    </label>
                  </div>
                )}

                {/* ── Control de Secuencias: tabla + campos lado a lado ── */}
                <div className="form-grid__full" style={{ display: "grid", gridTemplateColumns: "3fr 2fr", gap: "1.2rem", alignItems: "start", marginTop: "0.25rem" }}>

                  {/* Tabla En Uso / En Cola */}
                  <div>
                    <div style={sectionTitle}>Control de Secuencias</div>
                    <table style={tbl}>
                      <thead>
                        <tr>
                          <th style={{ ...thBase, textAlign: "left", borderRight: "none", width: "28%" }}></th>
                          <th style={{ ...thBase, textAlign: "center", color: "var(--brand)", width: "36%" }}>En Uso</th>
                          <th style={{ ...thBase, textAlign: "center", borderRight: "none", width: "36%" }}>En Cola</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr>
                          <td style={tdLabel}>Prefijo</td>
                          <td style={tdInput}><input style={{ ...inputSm, textAlign: "left" }} value={form.prefijo} onChange={(e) => setForm({ ...form, prefijo: e.target.value.toUpperCase() })} disabled={!isEditing} maxLength={10} placeholder="B01" /></td>
                          <td style={{ ...tdInput, borderRight: "none" }}><input style={{ ...inputSm, textAlign: "left" }} value={form.colaPrefijo} onChange={(e) => setForm({ ...form, colaPrefijo: e.target.value.toUpperCase() })} disabled={!isEditing} maxLength={10} /></td>
                        </tr>
                        <tr>
                          <td style={tdLabel}>Sec. Inicial</td>
                          <td style={tdInput}><input style={inputSm} type="number" min={1} value={form.rangoDesde} onChange={(e) => setForm({ ...form, rangoDesde: e.target.value })} disabled={!isEditing} required /></td>
                          <td style={{ ...tdInput, borderRight: "none" }}><input style={inputSm} type="number" min={1} value={form.colaRangoDesde} onChange={(e) => setForm({ ...form, colaRangoDesde: e.target.value })} disabled={!isEditing} /></td>
                        </tr>
                        <tr>
                          <td style={tdLabel}>Sec. Final</td>
                          <td style={tdInput}><input style={inputSm} type="number" min={1} value={form.rangoHasta} onChange={(e) => setForm({ ...form, rangoHasta: e.target.value })} disabled={!isEditing} required /></td>
                          <td style={{ ...tdInput, borderRight: "none" }}><input style={inputSm} type="number" min={1} value={form.colaRangoHasta} onChange={(e) => setForm({ ...form, colaRangoHasta: e.target.value })} disabled={!isEditing} /></td>
                        </tr>
                        <tr>
                          <td style={{ ...tdLabel, borderBottom: "none" }}>Fecha Vencim.</td>
                          <td style={{ ...tdInput, borderBottom: "none" }}><input style={inputDate} type="date" value={form.fechaVencimiento} onChange={(e) => setForm({ ...form, fechaVencimiento: e.target.value })} disabled={!isEditing} /></td>
                          <td style={{ ...tdInput, borderBottom: "none", borderRight: "none" }}><input style={inputDate} type="date" value={form.colaFechaVencimiento} onChange={(e) => setForm({ ...form, colaFechaVencimiento: e.target.value })} disabled={!isEditing} /></td>
                        </tr>
                      </tbody>
                    </table>
                  </div>

                  {/* Mín / Relleno / Restante / Actual — compactos a la derecha */}
                  <div>
                    <div style={sectionTitle}>Parámetros</div>
                    <div style={{ display: "grid", gap: "0.45rem" }}>
                      <label style={{ display: "grid", gridTemplateColumns: "1fr 1fr", alignItems: "center", gap: "0.5rem" }}>
                        <span style={paramLabel}>Mínimo para Alertar</span>
                        <input style={inputSm} type="number" min={0} value={form.minimoParaAlertar} onChange={(e) => setForm({ ...form, minimoParaAlertar: e.target.value })} disabled={!isEditing} />
                      </label>
                      <label style={{ display: "grid", gridTemplateColumns: "1fr 1fr", alignItems: "center", gap: "0.5rem" }}>
                        <span style={paramLabel}>Relleno Automático</span>
                        <input style={inputSm} type="number" min={1} value={form.rellenoAutomatico} onChange={(e) => setForm({ ...form, rellenoAutomatico: e.target.value })} disabled={!isEditing || form.usoComprobante === "D"} placeholder="Manual" />
                      </label>
                      <label style={{ display: "grid", gridTemplateColumns: "1fr 1fr", alignItems: "center", gap: "0.5rem" }}>
                        <span style={paramLabel}>Cantidad Restante</span>
                        <input style={{ ...inputSm, color: enAlerta ? "var(--rose-text, #ef4444)" : undefined, fontWeight: enAlerta ? 700 : undefined }} value={selected ? cantidadRestante.toLocaleString() : "—"} disabled />
                      </label>
                      {!isEditing && selected && (
                        <label style={{ display: "grid", gridTemplateColumns: "1fr 1fr", alignItems: "center", gap: "0.5rem" }}>
                          <span style={paramLabel}>Secuencia Actual</span>
                          <input style={inputSm} value={selected.secuenciaActual === 0 ? "No iniciada" : selected.secuenciaActual.toLocaleString()} disabled />
                        </label>
                      )}
                    </div>
                  </div>
                </div>

                {/* ── Comprobante Compartido — sección aparte, solo hijas ── */}
                {form.usoComprobante === "O" && (
                  <div className="form-grid__full" style={{ marginTop: "0.25rem" }}>
                    <div style={sectionTitle}>Comprobante Compartido</div>
                    {puntosLoading ? (
                      <div style={{ display: "flex", alignItems: "center", gap: "0.4rem", color: "var(--muted)", fontSize: "0.82rem" }}>
                        <Loader2 size={13} className="spin" /> Cargando puntos...
                      </div>
                    ) : (
                      <div style={{ border: "1px solid var(--line)", borderRadius: "0.7rem", overflow: "hidden" }}>
                        <div style={{ padding: "0.5rem 0.75rem", background: "var(--bg, #f8fafc)", borderBottom: "1px solid var(--line)", fontSize: "0.8rem", color: "var(--muted)" }}>
                          Compartir con los Puntos de Emisión seleccionados
                        </div>
                        <div>
                          {puntosEmision.length === 0 ? (
                            <div style={{ padding: "0.6rem 0.75rem", fontSize: "0.82rem", color: "var(--muted)" }}>No hay puntos de emisión configurados.</div>
                          ) : (
                            puntosEmision.map((p) => (
                              <label key={p.id} style={{ display: "flex", alignItems: "center", gap: "0.55rem", padding: "0.4rem 0.75rem", borderBottom: "1px solid var(--line)", cursor: isEditing ? "pointer" : "default", fontSize: "0.85rem", color: "var(--ink)" }}>
                                <input type="checkbox" checked={puntosCompartidos.includes(p.id)} onChange={() => isEditing && togglePuntoCompartido(p.id)} disabled={!isEditing} style={{ width: "14px", height: "14px", flexShrink: 0, accentColor: "var(--brand)" }} />
                                {p.nombre}
                              </label>
                            ))
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </form>
          ) : (
            <div className="price-lists-empty">
              <GitBranch size={48} opacity={0.3} />
              <p>Selecciona una secuencia NCF o crea una nueva</p>
            </div>
          )}
        </main>
      </div>

      {/* Modal eliminar */}
      {deleteTarget && (
        <DeleteConfirmModal
          open={true}
          entityLabel="Secuencia NCF"
          itemName={deleteTarget.descripcion || `${deleteTarget.codigoNCF} — ${deleteTarget.nombreNCF}`}
          onConfirm={() => handleDelete(deleteTarget.id)}
          onCancel={() => setDeleteTarget(null)}
        />
      )}

      {/* Modal distribuir */}
      {distribuirTarget && (
        <div className="modal-backdrop" role="presentation" onClick={() => setDistribuirTarget(null)}>
          <div className="modal-card modal-card--sm" role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon"><Share2 size={18} /></div>
              <div>
                <h3 className="modal-card__title">Distribuir desde Madre</h3>
                <p className="modal-card__subtitle">{distribuirTarget.descripcion || distribuirTarget.nombreNCF}</p>
              </div>
            </div>
            <div className="modal-card__body">
              <div className="form-grid">
                <label>
                  <span>Cantidad a distribuir *</span>
                  <input
                    type="number"
                    min={1}
                    value={distribuirCantidad}
                    onChange={(e) => setDistribuirCantidad(e.target.value)}
                    autoFocus
                  />
                </label>
                <label>
                  <span>Observación</span>
                  <input
                    value={distribuirObs}
                    onChange={(e) => setDistribuirObs(e.target.value)}
                    placeholder="Opcional"
                  />
                </label>
              </div>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setDistribuirTarget(null)}>
                Cancelar
              </button>
              <button
                type="button"
                className="primary-button"
                disabled={!distribuirCantidad || distribuirPending}
                onClick={handleDistribuir}
              >
                {distribuirPending ? <Loader2 size={16} className="spin" /> : <Share2 size={16} />}
                Distribuir
              </button>
            </div>
          </div>
        </div>
      )}
    </section>
  )
}
