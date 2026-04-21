"use client"

import { FileText, Loader2, Search } from "lucide-react"
import { useCallback, useEffect, useState } from "react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"

type ResumenRow = {
  fechaDocumento: string
  tipoPrefijo: string
  cantidadDocumentos: number
  subTotal: number
  descuento: number
  impuesto: number
  propina: number
  total: number
  pagoEfectivo: number
  pagoTarjeta: number
  pagoCheque: number
  pagoTransferencia: number
  pagoCredito: number
  pagoOtros: number
}

function formatMoney(v: number) {
  return new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v)
}

type AgrupadorKey = "dia" | "semana" | "mes" | "tipo"

export function FacResumenVentasScreen() {
  const [fechaDesde, setFechaDesde] = useState(() => {
    const d = new Date(); d.setDate(1)
    return d.toISOString().slice(0, 10)
  })
  const [fechaHasta, setFechaHasta] = useState(() => new Date().toISOString().slice(0, 10))
  const [agrupador, setAgrupador] = useState<AgrupadorKey>("dia")
  const [rows, setRows] = useState<ResumenRow[]>([])
  const [loading, setLoading] = useState(false)

  const totales = rows.reduce((acc, r) => ({
    cantidadDocumentos: acc.cantidadDocumentos + r.cantidadDocumentos,
    subTotal: acc.subTotal + r.subTotal,
    descuento: acc.descuento + r.descuento,
    impuesto: acc.impuesto + r.impuesto,
    total: acc.total + r.total,
    efectivo: acc.efectivo + r.pagoEfectivo,
    tarjeta: acc.tarjeta + r.pagoTarjeta,
    cheque: acc.cheque + r.pagoCheque,
    transferencia: acc.transferencia + r.pagoTransferencia,
    credito: acc.credito + r.pagoCredito,
    otros: acc.otros + r.pagoOtros,
  }), { cantidadDocumentos: 0, subTotal: 0, descuento: 0, impuesto: 0, total: 0, efectivo: 0, tarjeta: 0, cheque: 0, transferencia: 0, credito: 0, otros: 0 })

  const fetchResumen = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({ fechaDesde, fechaHasta, agrupador, resumen: "1" })
      const res = await fetch(apiUrl(`/api/facturacion/documentos/resumen?${params}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: ResumenRow[] }
      if (json.ok && json.data) setRows(json.data)
    } catch {
      toast.error("Error al cargar resumen de ventas.")
    } finally {
      setLoading(false)
    }
  }, [fechaDesde, fechaHasta, agrupador])

  useEffect(() => { void fetchResumen() }, [fetchResumen])

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
              <label>
                <span>Agrupar por</span>
                <select value={agrupador} onChange={(e) => setAgrupador(e.target.value as AgrupadorKey)}>
                  <option value="dia">Día</option>
                  <option value="semana">Semana</option>
                  <option value="mes">Mes</option>
                  <option value="tipo">Tipo Documento</option>
                </select>
              </label>
            </div>
            <div className="inv-doc-screen__filters-actions inv-doc-screen__filters-actions--bottom">
              <button type="button" className="primary-button" onClick={() => void fetchResumen()} disabled={loading}>
                <Search size={14} className={loading ? "spin" : ""} /> {loading ? "Generando..." : "Generar"}
              </button>
            </div>
          </div>
        </div>

        {/* KPIs */}
        {rows.length > 0 && (
          <div className="fac-resumen__kpis">
            <div className="fac-resumen__kpi"><span className="fac-resumen__kpi-label">Total Ventas</span><span className="fac-resumen__kpi-value">{formatMoney(totales.total)}</span></div>
            <div className="fac-resumen__kpi"><span className="fac-resumen__kpi-label">Documentos</span><span className="fac-resumen__kpi-value">{totales.cantidadDocumentos}</span></div>
            <div className="fac-resumen__kpi"><span className="fac-resumen__kpi-label">ITBIS</span><span className="fac-resumen__kpi-value">{formatMoney(totales.impuesto)}</span></div>
            <div className="fac-resumen__kpi"><span className="fac-resumen__kpi-label">Efectivo</span><span className="fac-resumen__kpi-value">{formatMoney(totales.efectivo)}</span></div>
            <div className="fac-resumen__kpi"><span className="fac-resumen__kpi-label">Tarjeta</span><span className="fac-resumen__kpi-value">{formatMoney(totales.tarjeta)}</span></div>
            <div className="fac-resumen__kpi"><span className="fac-resumen__kpi-label">Crédito</span><span className="fac-resumen__kpi-value">{formatMoney(totales.credito)}</span></div>
          </div>
        )}

        {/* Tabla */}
        {rows.length === 0 && !loading ? (
          <div className="inv-doc-screen__empty">
            <FileText size={48} opacity={0.25} />
            <p>Sin datos para el período seleccionado.</p>
          </div>
        ) : (
          <div className="inv-doc-screen__list-card">
            <div className="inv-doc-screen__list-head">
              <h3><FileText size={14} /> Resumen de Ventas</h3>
              <span>{rows.length} período{rows.length !== 1 ? "s" : ""}</span>
            </div>
            <div className="inv-doc-screen__table-wrap">
              <table className="inv-doc-screen__table">
                <thead>
                  <tr>
                    <th>{agrupador === "tipo" ? "Tipo Doc." : "Período"}</th>
                    <th className="text-right">Docs.</th>
                    <th className="text-right">Sub-Total</th>
                    <th className="text-right">Desc.</th>
                    <th className="text-right">ITBIS</th>
                    <th className="text-right" style={{ fontWeight: 700 }}>Total</th>
                    <th className="text-right">Efectivo</th>
                    <th className="text-right">Tarjeta</th>
                    <th className="text-right">Cheque</th>
                    <th className="text-right">Transfer.</th>
                    <th className="text-right">Crédito</th>
                    <th className="text-right">Otros</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr><td colSpan={12} style={{ textAlign: "center", padding: "2rem", color: "var(--muted)" }}><Loader2 size={18} className="spin" /> Generando...</td></tr>
                  ) : rows.map((r, i) => (
                    <tr key={i}>
                      <td style={{ fontWeight: 500 }}>
                        {agrupador === "tipo" ? <span className="fac-ops__tipo-badge">{r.tipoPrefijo}</span> : r.fechaDocumento}
                      </td>
                      <td className="text-right">{r.cantidadDocumentos}</td>
                      <td className="text-right">{formatMoney(r.subTotal)}</td>
                      <td className="text-right">{r.descuento > 0 ? formatMoney(r.descuento) : "—"}</td>
                      <td className="text-right">{formatMoney(r.impuesto)}</td>
                      <td className="text-right" style={{ fontWeight: 700 }}>{formatMoney(r.total)}</td>
                      <td className="text-right">{r.pagoEfectivo > 0 ? formatMoney(r.pagoEfectivo) : "—"}</td>
                      <td className="text-right">{r.pagoTarjeta > 0 ? formatMoney(r.pagoTarjeta) : "—"}</td>
                      <td className="text-right">{r.pagoCheque > 0 ? formatMoney(r.pagoCheque) : "—"}</td>
                      <td className="text-right">{r.pagoTransferencia > 0 ? formatMoney(r.pagoTransferencia) : "—"}</td>
                      <td className="text-right">{r.pagoCredito > 0 ? formatMoney(r.pagoCredito) : "—"}</td>
                      <td className="text-right">{r.pagoOtros > 0 ? formatMoney(r.pagoOtros) : "—"}</td>
                    </tr>
                  ))}
                </tbody>
                {rows.length > 1 && (
                  <tfoot>
                    <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                      <td>Total General</td>
                      <td className="text-right">{totales.cantidadDocumentos}</td>
                      <td className="text-right">{formatMoney(totales.subTotal)}</td>
                      <td className="text-right">{totales.descuento > 0 ? formatMoney(totales.descuento) : "—"}</td>
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
          </div>
        )}
      </div>
    </section>
  )
}
