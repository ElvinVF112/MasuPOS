"use client"

import { ChevronDown, ChevronRight, CreditCard, FileText, Loader2, Search } from "lucide-react"
import { Fragment, useCallback, useEffect, useState } from "react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"

type DetalleRow = {
  idDocumento: number
  tipoPrefijo: string
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
  estado: string
  puntoEmisionNombre: string | null
  usuarioNombre: string | null
  // Formas de pago (join en la query)
  pagoEfectivo: number
  pagoTarjeta: number
  pagoCheque: number
  pagoTransferencia: number
  pagoCredito: number
  pagoOtros: number
  totalRegistros: number
}

function formatMoney(v: number) {
  return new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v)
}

export function FacDetalleVentasScreen() {
  const [fechaDesde, setFechaDesde] = useState(() => {
    const d = new Date(); d.setDate(1)
    return d.toISOString().slice(0, 10)
  })
  const [fechaHasta, setFechaHasta] = useState(() => new Date().toISOString().slice(0, 10))
  const [secuenciaDesde, setSecuenciaDesde] = useState("")
  const [secuenciaHasta, setSecuenciaHasta] = useState("")
  const [soloTipo, setSoloTipo] = useState("")
  const [busqueda, setBusqueda] = useState("")
  const [rows, setRows] = useState<DetalleRow[]>([])
  const [loading, setLoading] = useState(false)
  const [totalRegistros, setTotalRegistros] = useState(0)
  const [expandedId, setExpandedId] = useState<number | null>(null)
  const pageSize = 100
  const [pageOffset, setPageOffset] = useState(0)

  // Totales del resultado actual
  const totales = rows.reduce((acc, r) => ({
    subTotal: acc.subTotal + r.subTotal,
    descuento: acc.descuento + r.descuento,
    impuesto: acc.impuesto + r.impuesto,
    propina: acc.propina + r.propina,
    total: acc.total + r.total,
    efectivo: acc.efectivo + r.pagoEfectivo,
    tarjeta: acc.tarjeta + r.pagoTarjeta,
    cheque: acc.cheque + r.pagoCheque,
    transferencia: acc.transferencia + r.pagoTransferencia,
    credito: acc.credito + r.pagoCredito,
    otros: acc.otros + r.pagoOtros,
  }), { subTotal: 0, descuento: 0, impuesto: 0, propina: 0, total: 0, efectivo: 0, tarjeta: 0, cheque: 0, transferencia: 0, credito: 0, otros: 0 })

  const fetchRows = useCallback(async (offset = 0) => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        fechaDesde, fechaHasta,
        pageSize: String(pageSize),
        pageOffset: String(offset),
        incluirPagos: "1",
      })
      if (soloTipo) params.set("soloTipo", soloTipo)
      if (secuenciaDesde) params.set("secuenciaDesde", secuenciaDesde)
      if (secuenciaHasta) params.set("secuenciaHasta", secuenciaHasta)

      const res = await fetch(apiUrl(`/api/facturacion/documentos?${params}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: DetalleRow[] }
      if (json.ok && json.data) {
        setRows(json.data)
        setTotalRegistros(json.data[0]?.totalRegistros ?? 0)
        setPageOffset(offset)
      }
    } catch {
      toast.error("Error al cargar detalle de ventas.")
    } finally {
      setLoading(false)
    }
  }, [fechaDesde, fechaHasta, soloTipo, secuenciaDesde, secuenciaHasta])

  useEffect(() => { void fetchRows(0) }, [fetchRows])

  const filtered = busqueda.trim()
    ? rows.filter((r) => {
        const q = busqueda.toLowerCase()
        return r.ncf?.toLowerCase().includes(q) ||
               r.nombreCliente?.toLowerCase().includes(q) ||
               r.rncCliente?.toLowerCase().includes(q) ||
               String(r.secuencia).includes(q)
      })
    : rows

  return (
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
              <label>
                <span>Tipo</span>
                <select value={soloTipo} onChange={(e) => setSoloTipo(e.target.value)}>
                  <option value="">Todos</option>
                </select>
              </label>
              <label style={{ flex: "2 1 180px" }}>
                <span>Buscar</span>
                <input type="text" placeholder="NCF, cliente, RNC..."
                  value={busqueda} onChange={(e) => setBusqueda(e.target.value)} />
              </label>
            </div>
            <div className="inv-doc-screen__filters-actions inv-doc-screen__filters-actions--bottom">
              <button type="button" className="primary-button" onClick={() => void fetchRows(0)} disabled={loading}>
                <Search size={14} className={loading ? "spin" : ""} /> {loading ? "Cargando..." : "Buscar"}
              </button>
            </div>
          </div>
        </div>

        {/* Lista */}
        {filtered.length === 0 && !loading ? (
          <div className="inv-doc-screen__empty">
            <FileText size={48} opacity={0.25} />
            <p>Sin documentos para los filtros seleccionados.</p>
          </div>
        ) : (
          <div className="inv-doc-screen__list-card">
            <div className="inv-doc-screen__list-head">
              <h3><FileText size={14} /> Detalle de Ventas</h3>
              <span>{totalRegistros} documento{totalRegistros !== 1 ? "s" : ""}</span>
            </div>
            <div className="inv-doc-screen__table-wrap">
              <table className="inv-doc-screen__table">
                <thead>
                  <tr>
                    <th style={{ width: 28 }} />
                    <th>Tipo</th><th>#</th><th>NCF</th><th>Fecha</th><th>Cliente</th>
                    <th className="text-right">Sub-Total</th>
                    <th className="text-right">ITBIS</th>
                    <th className="text-right">Total</th>
                    <th className="text-right">Efectivo</th>
                    <th className="text-right">Tarjeta</th>
                    <th className="text-right">Cheque</th>
                    <th className="text-right">Transfer.</th>
                    <th className="text-right">Crédito</th>
                    <th className="text-right">Otros</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && rows.length === 0 ? (
                    <tr><td colSpan={15} style={{ textAlign: "center", padding: "2rem", color: "var(--muted)" }}><Loader2 size={18} className="spin" /> Cargando...</td></tr>
                  ) : filtered.map((row) => (
                    <Fragment key={row.idDocumento}>
                      <tr
                        className={row.estado === "N" ? "is-voided" : ""}
                        onClick={() => setExpandedId(expandedId === row.idDocumento ? null : row.idDocumento)}
                        style={{ cursor: "pointer", background: expandedId === row.idDocumento ? "#f0f6ff" : undefined }}
                      >
                        <td style={{ color: "var(--muted)" }}>
                          {expandedId === row.idDocumento ? <ChevronDown size={13} /> : <ChevronRight size={13} />}
                        </td>
                        <td><span className="fac-ops__tipo-badge">{row.tipoPrefijo}</span></td>
                        <td>{row.documentoSecuencia || row.secuencia}</td>
                        <td style={{ fontFamily: "monospace", fontSize: "0.78rem" }}>{row.ncf ?? "—"}</td>
                        <td style={{ whiteSpace: "nowrap" }}>{row.fechaDocumento?.slice(0, 10)}</td>
                        <td style={{ maxWidth: 160, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.nombreCliente ?? "—"}</td>
                        <td className="text-right">{formatMoney(row.subTotal)}</td>
                        <td className="text-right">{formatMoney(row.impuesto)}</td>
                        <td className="text-right" style={{ fontWeight: 600 }}>{formatMoney(row.total)}</td>
                        <td className="text-right">{row.pagoEfectivo > 0 ? formatMoney(row.pagoEfectivo) : "—"}</td>
                        <td className="text-right">{row.pagoTarjeta > 0 ? formatMoney(row.pagoTarjeta) : "—"}</td>
                        <td className="text-right">{row.pagoCheque > 0 ? formatMoney(row.pagoCheque) : "—"}</td>
                        <td className="text-right">{row.pagoTransferencia > 0 ? formatMoney(row.pagoTransferencia) : "—"}</td>
                        <td className="text-right">{row.pagoCredito > 0 ? formatMoney(row.pagoCredito) : "—"}</td>
                        <td className="text-right">{row.pagoOtros > 0 ? formatMoney(row.pagoOtros) : "—"}</td>
                      </tr>
                      {expandedId === row.idDocumento && (
                        <tr>
                          <td colSpan={15} style={{ padding: "0.5rem 0.75rem 0.5rem 2rem", background: "#f8faff", fontSize: "0.8rem", color: "var(--muted)" }}>
                            <span style={{ display: "inline-flex", gap: "1.5rem", flexWrap: "wrap" }}>
                              {row.puntoEmisionNombre && <span>Punto: <strong style={{ color: "var(--ink)" }}>{row.puntoEmisionNombre}</strong></span>}
                              {row.usuarioNombre && <span>Usuario: <strong style={{ color: "var(--ink)" }}>{row.usuarioNombre}</strong></span>}
                              {row.rncCliente && <span>RNC: <strong style={{ color: "var(--ink)" }}>{row.rncCliente}</strong></span>}
                              {row.estado === "N" && <span style={{ color: "#b4233d", fontWeight: 700 }}>ANULADO</span>}
                            </span>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  ))}
                </tbody>
                {filtered.length > 0 && (
                  <tfoot>
                    <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                      <td colSpan={6} style={{ textAlign: "right", paddingRight: "0.75rem" }}>Totales</td>
                      <td className="text-right">{formatMoney(totales.subTotal)}</td>
                      <td className="text-right">{formatMoney(totales.impuesto)}</td>
                      <td className="text-right">{formatMoney(totales.total)}</td>
                      <td className="text-right">{totales.efectivo > 0 ? formatMoney(totales.efectivo) : "—"}</td>
                      <td className="text-right">{totales.tarjeta > 0 ? formatMoney(totales.tarjeta) : "—"}</td>
                      <td className="text-right">{totales.cheque > 0 ? formatMoney(totales.cheque) : "—"}</td>
                      <td className="text-right">{totales.transferencia > 0 ? formatMoney(totales.transferencia) : "—"}</td>
                      <td className="text-right">{totales.credito > 0 ? formatMoney(totales.credito) : "—"}</td>
                      <td className="text-right">{totales.otros > 0 ? formatMoney(totales.otros) : "—"}</td>
                    </tr>
                  </tfoot>
                )}
              </table>
            </div>

            {/* Paginación */}
            {totalRegistros > pageSize && (
              <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.6rem 0.75rem", borderTop: "1px solid var(--line)", fontSize: "0.82rem", color: "var(--muted)" }}>
                <span>Por página {pageSize} &nbsp;·&nbsp; {pageOffset + 1}–{Math.min(pageOffset + pageSize, totalRegistros)} de {totalRegistros}</span>
                <div style={{ display: "flex", gap: "0.4rem" }}>
                  <button type="button" className="ghost-button" disabled={pageOffset === 0 || loading} onClick={() => void fetchRows(0)}>«</button>
                  <button type="button" className="ghost-button" disabled={pageOffset === 0 || loading} onClick={() => void fetchRows(Math.max(0, pageOffset - pageSize))}>‹</button>
                  <span style={{ padding: "0.25rem 0.5rem" }}>Página {Math.floor(pageOffset / pageSize) + 1} de {Math.ceil(totalRegistros / pageSize)}</span>
                  <button type="button" className="ghost-button" disabled={pageOffset + pageSize >= totalRegistros || loading} onClick={() => void fetchRows(pageOffset + pageSize)}>›</button>
                  <button type="button" className="ghost-button" disabled={pageOffset + pageSize >= totalRegistros || loading} onClick={() => void fetchRows((Math.ceil(totalRegistros / pageSize) - 1) * pageSize)}>»</button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </section>
  )
}
