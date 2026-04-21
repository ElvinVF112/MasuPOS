"use client"

import {
  Ban,
  ChevronDown,
  ChevronRight,
  CreditCard,
  Eye,
  FileText,
  Loader2,
  Pencil,
  Printer,
  RotateCcw,
  Search,
  X,
} from "lucide-react"
import { Fragment, useCallback, useEffect, useState } from "react"
import { usePermissions } from "@/lib/permissions-context"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"

type DocEstado = "I" | "P" | "N"

type FacDocumentoRow = {
  idDocumento: number
  tipoPrefijo: string
  tipoDocumentoNombre: string
  documentoSecuencia: string
  secuencia: number
  ncf: string | null
  fechaDocumento: string
  nombreCliente: string | null
  rncCliente: string | null
  subTotal: number
  descuento: number
  impuesto: number
  propina: number
  total: number
  totalPagado: number
  estado: DocEstado
  puntoEmisionNombre: string | null
  usuarioNombre: string | null
  totalRegistros: number
}

type FacDocumentoDetalle = {
  idDocumentoDetalle: number
  numeroLinea: number
  codigo: string | null
  descripcion: string
  cantidad: number
  unidad: string | null
  precioBase: number
  porcentajeImpuesto: number
  aplicaImpuesto: boolean
  descuentoLinea: number
  comentarioLinea: string | null
  subTotalLinea: number
  impuestoLinea: number
  totalLinea: number
}

type FacPagoRow = {
  idPago: number
  formaPagoNombre: string
  tipoValor: string
  monto: number
  referencia: string | null
}

type DevLinea = FacDocumentoDetalle & { cantDevolucion: number }

type DocDetalle = {
  doc: FacDocumentoRow
  lineas: FacDocumentoDetalle[]
  pagos: FacPagoRow[]
}

const ESTADO_LABELS: Record<DocEstado, string> = {
  I: "Pendiente",
  P: "Posteado",
  N: "Anulado",
}

const ESTADO_COLORS: Record<DocEstado, string> = {
  I: "var(--warn-bg,#fff8e1)",
  P: "var(--success-bg,#e9f8f0)",
  N: "var(--rose-bg,#ffecef)",
}

const ESTADO_TEXT: Record<DocEstado, string> = {
  I: "var(--warn-text,#b07000)",
  P: "var(--success-text,#11875c)",
  N: "var(--rose-text,#d91c5c)",
}

function formatMoney(v: number) {
  return new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v)
}

function EstadoBadge({ estado }: { estado: DocEstado }) {
  return (
    <span style={{
      background: ESTADO_COLORS[estado],
      color: ESTADO_TEXT[estado],
      fontSize: "0.68rem", fontWeight: 700,
      padding: "2px 8px", borderRadius: 4,
      textTransform: "uppercase", letterSpacing: "0.04em",
      whiteSpace: "nowrap",
    }}>
      {ESTADO_LABELS[estado]}
    </span>
  )
}

export function FacOperacionesScreen() {
  const { hasPermission } = usePermissions()

  // Filtros
  const [fechaDesde, setFechaDesde] = useState(() => {
    const d = new Date(); d.setDate(1)
    return d.toISOString().slice(0, 10)
  })
  const [fechaHasta, setFechaHasta] = useState(() => new Date().toISOString().slice(0, 10))
  const [secuenciaDesde, setSecuenciaDesde] = useState("")
  const [secuenciaHasta, setSecuenciaHasta] = useState("")
  const [clienteFiltro, setClienteFiltro] = useState("")

  // Datos
  const [rows, setRows] = useState<FacDocumentoRow[]>([])
  const [loading, setLoading] = useState(false)
  const [totalRegistros, setTotalRegistros] = useState(0)
  const pageSize = 50
  const [pageOffset, setPageOffset] = useState(0)

  // Detalle expandido inline
  const [expandedId, setExpandedId] = useState<number | null>(null)
  const [detalleLoading, setDetalleLoading] = useState(false)
  const [detalle, setDetalle] = useState<DocDetalle | null>(null)

  // Modal anular
  const [anularId, setAnularId] = useState<number | null>(null)
  const [motivoAnulacion, setMotivoAnulacion] = useState("")
  const [anulando, setAnulando] = useState(false)

  // Modal devolución
  const [devolucionDoc, setDevolucionDoc] = useState<FacDocumentoRow | null>(null)
  const [devolucionLineas, setDevolucionLineas] = useState<DevLinea[]>([])
  const [devolucionMotivo, setDevolucionMotivo] = useState("")
  const [devolucionLoading, setDevolucionLoading] = useState(false)
  const [generando, setGenerando] = useState(false)

  const fetchDocs = useCallback(async (offset = 0) => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        fechaDesde,
        fechaHasta,
        pageSize: String(pageSize),
        pageOffset: String(offset),
      })
      if (secuenciaDesde) params.set("secuenciaDesde", secuenciaDesde)
      if (secuenciaHasta) params.set("secuenciaHasta", secuenciaHasta)

      const res = await fetch(apiUrl(`/api/facturacion/documentos?${params}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: FacDocumentoRow[] }
      if (json.ok && json.data) {
        setRows(json.data)
        setTotalRegistros(json.data[0]?.totalRegistros ?? 0)
        setPageOffset(offset)
      }
    } catch {
      toast.error("Error al cargar documentos.")
    } finally {
      setLoading(false)
    }
  }, [fechaDesde, fechaHasta, secuenciaDesde, secuenciaHasta])

  useEffect(() => { void fetchDocs(0) }, [fetchDocs])

  async function loadDetalle(idDocumento: number) {
    if (expandedId === idDocumento) { setExpandedId(null); return }
    setExpandedId(idDocumento)
    setDetalle(null)
    setDetalleLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${idDocumento}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: { doc?: FacDocumentoRow; lineas?: FacDocumentoDetalle[]; pagos?: FacPagoRow[] } }
      if (json.ok && json.data?.doc) {
        setDetalle({ doc: json.data.doc, lineas: json.data.lineas ?? [], pagos: json.data.pagos ?? [] })
      }
    } catch {
      toast.error("Error al cargar detalle.")
    } finally {
      setDetalleLoading(false)
    }
  }

  async function ejecutarAnulacion() {
    if (!anularId || !motivoAnulacion.trim()) return
    setAnulando(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${anularId}`), {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ accion: "anular", motivoAnulacion: motivoAnulacion.trim() }),
      })
      const json = (await res.json()) as { ok?: boolean; error?: string }
      if (json.ok) {
        toast.success("Documento anulado.")
        setAnularId(null)
        setMotivoAnulacion("")
        void fetchDocs(pageOffset)
      } else {
        toast.error(json.error ?? "Error al anular.")
      }
    } catch {
      toast.error("Error al anular.")
    } finally {
      setAnulando(false)
    }
  }

  async function abrirDevolucion(row: FacDocumentoRow) {
    setDevolucionDoc(row)
    setDevolucionMotivo("")
    setDevolucionLineas([])
    setDevolucionLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${row.idDocumento}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: { lineas?: FacDocumentoDetalle[] } }
      if (json.ok && json.data?.lineas) {
        setDevolucionLineas(json.data.lineas.map((l) => ({ ...l, cantDevolucion: l.cantidad })))
      }
    } catch {
      toast.error("Error al cargar líneas del documento.")
    } finally {
      setDevolucionLoading(false)
    }
  }

  async function ejecutarDevolucion() {
    if (!devolucionDoc) return
    const lineas = devolucionLineas
      .filter((l) => l.cantDevolucion > 0)
      .map((l) => ({ idDocumentoDetalle: l.idDocumentoDetalle, cantidadDevolucion: l.cantDevolucion }))
    if (lineas.length === 0) { toast.error("Seleccione al menos una línea para devolver."); return }
    setGenerando(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${devolucionDoc.idDocumento}`), {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ accion: "devolucion", motivo: devolucionMotivo.trim() || undefined, lineas }),
      })
      const json = (await res.json()) as { ok?: boolean; data?: { idDocumento: number; secuencia: number }; message?: string }
      if (json.ok && json.data) {
        toast.success(`Nota de Crédito NC-${json.data.secuencia} generada correctamente.`)
        setDevolucionDoc(null)
        void fetchDocs(pageOffset)
      } else {
        toast.error(json.message ?? "Error al generar la nota de crédito.")
      }
    } catch {
      toast.error("Error al generar la nota de crédito.")
    } finally {
      setGenerando(false)
    }
  }

  const filteredRows = clienteFiltro.trim()
    ? rows.filter((r) => {
        const q = clienteFiltro.toLowerCase()
        return (
          r.nombreCliente?.toLowerCase().includes(q) ||
          r.rncCliente?.toLowerCase().includes(q)
        )
      })
    : rows

  return (
    <>
    <section className="data-panel">
      <div className="inv-doc-screen">

        {/* Filtros */}
        <div className="inv-doc-screen__filters">
          <div className="inv-doc-screen__filters-head">
            <h3><Search size={14} /> Filtros</h3>
          </div>
          <div className="inv-doc-screen__filters-row">
            <div className="inv-doc-screen__filters-grid">
              <label className="inv-doc-screen__filters-date">
                <span>Fecha Desde</span>
                <input type="date" value={fechaDesde} onChange={(e) => setFechaDesde(e.target.value)} />
              </label>
              <label className="inv-doc-screen__filters-date">
                <span>Fecha Hasta</span>
                <input type="date" value={fechaHasta} onChange={(e) => setFechaHasta(e.target.value)} />
              </label>
              <label className="inv-doc-screen__filters-seq">
                <span>Secuencia Desde</span>
                <input type="number" min={1} step={1} placeholder="Ej. 1" value={secuenciaDesde} onChange={(e) => setSecuenciaDesde(e.target.value)} />
              </label>
              <label className="inv-doc-screen__filters-seq">
                <span>Secuencia Hasta</span>
                <input type="number" min={1} step={1} placeholder="Ej. 500" value={secuenciaHasta} onChange={(e) => setSecuenciaHasta(e.target.value)} />
              </label>
              <label style={{ flex: "2 1 200px" }}>
                <span>Cliente</span>
                <input
                  type="text"
                  placeholder="Nombre o RNC..."
                  value={clienteFiltro}
                  onChange={(e) => setClienteFiltro(e.target.value)}
                />
              </label>
            </div>
            <div className="inv-doc-screen__filters-actions inv-doc-screen__filters-actions--bottom">
              <button type="button" className="primary-button" onClick={() => void fetchDocs(0)} disabled={loading}>
                <Search size={14} className={loading ? "spin" : ""} /> {loading ? "Cargando..." : "Buscar"}
              </button>
            </div>
          </div>
        </div>

        {/* Lista */}
        {filteredRows.length === 0 && !loading ? (
          <div className="inv-doc-screen__empty">
            <FileText size={48} opacity={0.25} />
            <p>Sin documentos para los filtros seleccionados.</p>
          </div>
        ) : (
          <div className="inv-doc-screen__list-card">
            <div className="inv-doc-screen__list-head">
              <h3><FileText size={14} /> Documentos</h3>
              <span>{totalRegistros} documento{totalRegistros !== 1 ? "s" : ""}</span>
            </div>
            <div className="inv-doc-screen__table-wrap">
              <table className="inv-doc-screen__table">
                <thead>
                  <tr>
                    <th style={{ width: 28 }} />
                    <th>Tipo</th>
                    <th>#</th>
                    <th>NCF</th>
                    <th>Fecha</th>
                    <th>Cliente</th>
                    <th className="text-right">Total</th>
                    <th className="text-right">Pagado</th>
                    <th>Estado</th>
                    <th className="text-center">Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && rows.length === 0 ? (
                    <tr><td colSpan={10} style={{ textAlign: "center", padding: "2rem", color: "var(--muted)" }}><Loader2 size={18} className="spin" /> Cargando...</td></tr>
                  ) : filteredRows.map((row) => (
                    <Fragment key={row.idDocumento}>
                      <tr
                        className={row.estado === "N" ? "is-voided" : ""}
                        onClick={() => void loadDetalle(row.idDocumento)}
                        style={{ cursor: "pointer", background: expandedId === row.idDocumento ? "#f0f6ff" : undefined }}
                      >
                        <td style={{ width: 28, color: "var(--muted)" }}>
                          {expandedId === row.idDocumento
                            ? <ChevronDown size={14} />
                            : <ChevronRight size={14} />}
                        </td>
                        <td><span className="fac-ops__tipo-badge">{row.tipoPrefijo}</span></td>
                        <td style={{ fontVariantNumeric: "tabular-nums" }}>{row.documentoSecuencia || row.secuencia}</td>
                        <td style={{ fontFamily: "monospace", fontSize: "0.8rem" }}>{row.ncf ?? "—"}</td>
                        <td style={{ whiteSpace: "nowrap" }}>{row.fechaDocumento?.slice(0, 10)}</td>
                        <td style={{ maxWidth: 200, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                          {row.nombreCliente ?? <span style={{ color: "var(--muted)" }}>Consumidor Final</span>}
                        </td>
                        <td className="text-right" style={{ fontVariantNumeric: "tabular-nums" }}>{formatMoney(row.total)}</td>
                        <td className="text-right" style={{ fontVariantNumeric: "tabular-nums" }}>{formatMoney(row.totalPagado)}</td>
                        <td><EstadoBadge estado={row.estado} /></td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <div className="inv-doc-screen__row-actions">
                            <button type="button" title="Visualizar" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--view" onClick={() => void loadDetalle(row.idDocumento)}>
                              <Eye size={14} />
                            </button>
                            {hasPermission("facturacion.operaciones.reimprimir") ? (
                              <button type="button" title="Reimprimir" className="inv-doc-screen__action-btn inv-doc-screen__action-btn--print" onClick={() => toast.info("Reimprimir — próximamente")}>
                                <Printer size={14} />
                              </button>
                            ) : null}
                            {hasPermission("facturacion.operaciones.edit") && row.estado === "I" ? (
                              <button type="button" title="Editar" className="inv-doc-screen__action-btn inv-doc-screen__action-btn--edit" onClick={() => toast.info("Editar — próximamente")}>
                                <Pencil size={14} />
                              </button>
                            ) : null}
                            {hasPermission("facturacion.operaciones.devolucion") && row.estado !== "N" && row.tipoPrefijo.toUpperCase().startsWith("FAC") ? (
                              <button type="button" title="Devolución / Nota de Crédito" className="inv-doc-screen__action-btn inv-doc-screen__action-btn--return" onClick={() => void abrirDevolucion(row)}>
                                <RotateCcw size={14} />
                              </button>
                            ) : null}
                            {hasPermission("facturacion.operaciones.anular") && row.estado === "I" ? (
                              <button type="button" title="Anular" className="inv-doc-screen__action-btn inv-doc-screen__action-btn--void"
                                onClick={() => { setAnularId(row.idDocumento); setMotivoAnulacion("") }}>
                                <Ban size={14} />
                              </button>
                            ) : null}
                          </div>
                        </td>
                      </tr>

                      {/* Fila expandida con detalle */}
                      {expandedId === row.idDocumento && (
                        <tr>
                          <td colSpan={10} style={{ padding: 0, background: "#f8faff" }}>
                            {detalleLoading ? (
                              <div style={{ padding: "1.5rem", textAlign: "center", color: "var(--muted)" }}>
                                <Loader2 size={16} className="spin" /> Cargando detalle...
                              </div>
                            ) : detalle ? (
                              <div className="fac-ops__detail-body">
                                <div className="fac-ops__detail-section">
                                  <p className="fac-ops__detail-section-title"><FileText size={13} /> Líneas del documento</p>
                                  <table className="fac-ops__inner-table">
                                    <thead>
                                      <tr>
                                        <th>#</th><th>Código</th><th>Descripción</th>
                                        <th className="text-right">Cant.</th>
                                        <th className="text-right">Precio</th>
                                        <th className="text-right">ITBIS</th>
                                        <th className="text-right">Desc.</th>
                                        <th className="text-right">Total</th>
                                      </tr>
                                    </thead>
                                    <tbody>
                                      {detalle.lineas.map((l) => (
                                        <tr key={l.idDocumentoDetalle}>
                                          <td>{l.numeroLinea}</td>
                                          <td style={{ fontFamily: "monospace", fontSize: "0.78rem" }}>{l.codigo ?? "—"}</td>
                                          <td>{l.descripcion}{l.comentarioLinea && <span className="fac-ops__line-comment"> · {l.comentarioLinea}</span>}</td>
                                          <td className="text-right">{l.cantidad}</td>
                                          <td className="text-right">{formatMoney(l.precioBase)}</td>
                                          <td className="text-right">{formatMoney(l.impuestoLinea)}</td>
                                          <td className="text-right">{l.descuentoLinea > 0 ? formatMoney(l.descuentoLinea) : "—"}</td>
                                          <td className="text-right" style={{ fontWeight: 600 }}>{formatMoney(l.totalLinea)}</td>
                                        </tr>
                                      ))}
                                    </tbody>
                                  </table>
                                </div>
                                <div className="fac-ops__detail-section">
                                  <p className="fac-ops__detail-section-title"><CreditCard size={13} /> Pagos recibidos</p>
                                  {detalle.pagos.length === 0 ? (
                                    <p style={{ fontSize: "0.8rem", color: "var(--muted)", padding: "0.4rem 0" }}>Sin pagos registrados.</p>
                                  ) : (
                                    <table className="fac-ops__inner-table">
                                      <thead>
                                        <tr><th>Forma de Pago</th><th>Tipo Valor</th><th className="text-right">Monto</th><th>Referencia</th></tr>
                                      </thead>
                                      <tbody>
                                        {detalle.pagos.map((p) => (
                                          <tr key={p.idPago}>
                                            <td>{p.formaPagoNombre}</td>
                                            <td><span className="fac-ops__tipo-badge">{p.tipoValor}</span></td>
                                            <td className="text-right" style={{ fontWeight: 600 }}>{formatMoney(p.monto)}</td>
                                            <td>{p.referencia ?? "—"}</td>
                                          </tr>
                                        ))}
                                      </tbody>
                                    </table>
                                  )}
                                </div>
                              </div>
                            ) : null}
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Paginación */}
            {totalRegistros > pageSize && (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.6rem 0.75rem", borderTop: "1px solid var(--line)", fontSize: "0.82rem", color: "var(--muted)" }}>
                <span>Por página {pageSize} &nbsp;·&nbsp; {pageOffset + 1}–{Math.min(pageOffset + pageSize, totalRegistros)} de {totalRegistros}</span>
                <div style={{ display: "flex", gap: "0.4rem" }}>
                  <button type="button" className="ghost-button" disabled={pageOffset === 0 || loading} onClick={() => void fetchDocs(0)}>«</button>
                  <button type="button" className="ghost-button" disabled={pageOffset === 0 || loading} onClick={() => void fetchDocs(Math.max(0, pageOffset - pageSize))}>‹</button>
                  <span style={{ padding: "0.25rem 0.5rem" }}>Página {Math.floor(pageOffset / pageSize) + 1} de {Math.ceil(totalRegistros / pageSize)}</span>
                  <button type="button" className="ghost-button" disabled={pageOffset + pageSize >= totalRegistros || loading} onClick={() => void fetchDocs(pageOffset + pageSize)}>›</button>
                  <button type="button" className="ghost-button" disabled={pageOffset + pageSize >= totalRegistros || loading} onClick={() => void fetchDocs((Math.ceil(totalRegistros / pageSize) - 1) * pageSize)}>»</button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </section>

    {/* Modal: Anular */}
    {anularId !== null && (
      <div className="modal-backdrop">
        <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
          <div className="modal-card__header">
            <div className="modal-card__header-icon" style={{ background: "var(--rose-bg,#ffecef)", color: "var(--rose-text,#d91c5c)" }}>
              <Ban size={18} />
            </div>
            <div>
              <h3 className="modal-card__title">Anular Documento</h3>
              <p className="modal-card__subtitle">Esta acción no se puede deshacer.</p>
            </div>
            <button type="button" className="modal-card__close" onClick={() => setAnularId(null)}><X size={16} /></button>
          </div>
          <div className="modal-card__body modal-card__body--stack">
            <label className="field-label">Motivo de anulación <span style={{ color: "var(--rose-text,#d91c5c)" }}>*</span></label>
            <textarea className="input" rows={3} autoFocus value={motivoAnulacion}
              onChange={(e) => setMotivoAnulacion(e.target.value)}
              placeholder="Describe el motivo de la anulación..." maxLength={500} />
            <span style={{ fontSize: "0.72rem", color: "var(--muted)", textAlign: "right" }}>{motivoAnulacion.length}/500</span>
          </div>
          <div className="modal-card__footer">
            <button type="button" className="secondary-button" onClick={() => setAnularId(null)} disabled={anulando}>Cancelar</button>
            <button type="button" className="danger-button" disabled={!motivoAnulacion.trim() || anulando} onClick={() => void ejecutarAnulacion()}>
              {anulando ? <><Loader2 size={14} className="spin" /> Anulando...</> : <><Ban size={14} /> Confirmar anulación</>}
            </button>
          </div>
        </div>
      </div>
    )}

    {/* Modal: Devolución / Nota de Crédito */}
    {devolucionDoc !== null && (
      <div className="modal-backdrop">
        <div className="modal-card modal-card--elevated" style={{ maxWidth: 680 }} onClick={(e) => e.stopPropagation()}>
          <div className="modal-card__header">
            <div className="modal-card__header-icon" style={{ background: "rgba(245,158,11,0.12)", color: "#b45309" }}>
              <RotateCcw size={18} />
            </div>
            <div>
              <h3 className="modal-card__title">Devolución — Nota de Crédito</h3>
              <p className="modal-card__subtitle">
                Factura #{devolucionDoc.secuencia} · {devolucionDoc.nombreCliente ?? "Sin cliente"}
              </p>
            </div>
            <button type="button" className="modal-card__close" onClick={() => setDevolucionDoc(null)} disabled={generando}><X size={16} /></button>
          </div>

          <div className="modal-card__body modal-card__body--stack">
            {devolucionLoading ? (
              <div style={{ textAlign: "center", padding: "1.5rem", color: "var(--muted)" }}>
                <Loader2 size={18} className="spin" /> Cargando líneas...
              </div>
            ) : (
              <>
                <p style={{ fontSize: "0.8rem", color: "var(--muted)", marginBottom: "0.25rem" }}>
                  Ajusta las cantidades a devolver. Poner 0 excluye la línea.
                </p>
                <div style={{ overflowX: "auto" }}>
                  <table className="inv-doc-screen__table" style={{ fontSize: "0.82rem" }}>
                    <thead>
                      <tr>
                        <th>Descripción</th>
                        <th className="text-right">Cant. Original</th>
                        <th className="text-right">Cant. Devolver</th>
                        <th className="text-right">Precio</th>
                        <th className="text-right">Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      {devolucionLineas.map((l, i) => (
                        <tr key={l.idDocumentoDetalle}>
                          <td>{l.descripcion}</td>
                          <td className="text-right">{l.cantidad}</td>
                          <td className="text-right" style={{ width: 90 }}>
                            <input
                              type="number"
                              min={0}
                              max={l.cantidad}
                              step={1}
                              value={l.cantDevolucion}
                              style={{ width: "100%", textAlign: "right", padding: "2px 4px", border: "1px solid var(--line)", borderRadius: 4, fontSize: "0.82rem" }}
                              onChange={(e) => {
                                const val = Math.min(l.cantidad, Math.max(0, Number(e.target.value)))
                                setDevolucionLineas((prev) => prev.map((x, j) => j === i ? { ...x, cantDevolucion: val } : x))
                              }}
                            />
                          </td>
                          <td className="text-right">{formatMoney(l.precioBase)}</td>
                          <td className="text-right" style={{ fontWeight: 600 }}>
                            {formatMoney(l.totalLinea * (l.cantDevolucion / (l.cantidad || 1)))}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                        <td colSpan={4} style={{ textAlign: "right", paddingRight: "0.75rem" }}>Total a devolver</td>
                        <td className="text-right">
                          {formatMoney(devolucionLineas.reduce((sum, l) => sum + l.totalLinea * (l.cantDevolucion / (l.cantidad || 1)), 0))}
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>

                <label className="field-label" style={{ marginTop: "0.5rem" }}>Motivo (opcional)</label>
                <textarea className="input" rows={2} value={devolucionMotivo}
                  onChange={(e) => setDevolucionMotivo(e.target.value)}
                  placeholder="Razón de la devolución..." maxLength={500} />
              </>
            )}
          </div>

          <div className="modal-card__footer">
            <button type="button" className="secondary-button" onClick={() => setDevolucionDoc(null)} disabled={generando}>Cancelar</button>
            <button
              type="button"
              className="primary-button"
              disabled={devolucionLoading || generando || devolucionLineas.every((l) => l.cantDevolucion === 0)}
              onClick={() => void ejecutarDevolucion()}
              style={{ background: "#b45309" }}
            >
              {generando
                ? <><Loader2 size={14} className="spin" /> Generando...</>
                : <><RotateCcw size={14} /> Generar Nota de Crédito</>}
            </button>
          </div>
        </div>
      </div>
    )}
    </>
  )
}
