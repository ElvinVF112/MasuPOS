"use client"

import { useCallback, useEffect, useMemo, useState } from "react"
import {
  Banknote,
  ChevronLeft,
  ChevronRight,
  DollarSign,
  Euro,
  History,
  Loader2,
  Search,
} from "lucide-react"
import { apiUrl } from "@/lib/client-config"
import type { CurrencyHistoryRecord } from "@/lib/pos-data"
import { useFormat } from "@/lib/format-context"

function getCurrencyIcon(code: string) {
  switch (code) {
    case "USD": return <DollarSign size={14} />
    case "EUR": return <Euro size={14} />
    default: return <Banknote size={14} />
  }
}

export function CurrencyHistoryScreen() {
  const { formatDate, formatNumber } = useFormat()
  const [items, setItems] = useState<CurrencyHistoryRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState("")
  const [currencyFilter, setCurrencyFilter] = useState<string>("all")
  const [dateFrom, setDateFrom] = useState("")
  const [dateTo, setDateTo] = useState("")
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [totalRecords, setTotalRecords] = useState(0)

  const loadData = useCallback(async (page = 1) => {
    setLoading(true)
    try {
      const params = new URLSearchParams({ page: String(page) })
      if (currencyFilter !== "all") params.set("currencyId", currencyFilter)
      if (dateFrom) params.set("dateFrom", dateFrom)
      if (dateTo) params.set("dateTo", dateTo)
      const res = await fetch(apiUrl(`/api/currencies/history?${params}`), { credentials: "include" })
      const json = (await res.json()) as { ok: boolean; data?: CurrencyHistoryRecord[] }
      if (json.ok && json.data && json.data.length > 0) {
        const first = json.data[0]
        setItems(json.data)
        setTotalPages(first.totalPages)
        setTotalRecords(first.totalRecords)
      } else {
        setItems([])
        setTotalPages(1)
        setTotalRecords(0)
      }
    } finally {
      setLoading(false)
    }
  }, [currencyFilter, dateFrom, dateTo])

  useEffect(() => {
    setCurrentPage(1)
    void loadData(1)
  }, [loadData])

  useEffect(() => { void loadData(currentPage) }, [currentPage, loadData])

  const uniqueCodes = useMemo(() => Array.from(new Set(items.map(i => i.currencyCode))), [items])

  const avgUSD = useMemo(() => {
    const usd = items.filter(i => i.currencyCode === "USD")
    if (!usd.length) return 0
    return usd.reduce((s, r) => s + (r.rateOperative ?? 0), 0) / usd.length
  }, [items])

  const avgEUR = useMemo(() => {
    const eur = items.filter(i => i.currencyCode === "EUR")
    if (!eur.length) return 0
    return eur.reduce((s, r) => s + (r.rateOperative ?? 0), 0) / eur.length
  }, [items])

  const startIdx = (currentPage - 1) * 50 + 1
  const endIdx = Math.min(currentPage * 50, totalRecords)

  return (
    <div className="currency-history">
      <div className="currency-history__header">
        <div className="currency-history__header-title">
          <div className="currency-history__header-icon"><History size={22} /></div>
          <div>
            <h1>Historico de Tasas</h1>
            <p>Consulta el historial de cambios en las tasas de cambio</p>
          </div>
        </div>
      </div>

      <div className="currency-history__stats">
        <div className="currency-history__stat-card">
          <History size={18} />
          <div>
            <span>Total Registros</span>
            <strong>{totalRecords}</strong>
          </div>
        </div>
        <div className="currency-history__stat-card">
          <DollarSign size={18} />
          <div>
            <span>Tasa USD Promedio</span>
            <strong>{formatNumber(avgUSD, 2)}</strong>
          </div>
        </div>
        <div className="currency-history__stat-card">
          <Euro size={18} />
          <div>
            <span>Tasa EUR Promedio</span>
            <strong>{formatNumber(avgEUR, 2)}</strong>
          </div>
        </div>
        <div className="currency-history__stat-card">
          <History size={18} />
          <div>
            <span>Monedas Activas</span>
            <strong>{uniqueCodes.length}</strong>
          </div>
        </div>
      </div>

      <div className="currency-history__filters">
        <div className="currency-history__search">
          <Search size={14} />
          <input
            type="text"
            placeholder="Buscar moneda..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        <select
          value={currencyFilter}
          onChange={e => { setCurrencyFilter(e.target.value); setCurrentPage(1) }}
          className="currency-history__select"
        >
          <option value="all">Todas las monedas</option>
          {uniqueCodes.map(code => (
            <option key={code} value={code}>{code}</option>
          ))}
        </select>

        <div className="currency-history__date-range">
          <span>Desde</span>
          <input type="date" value={dateFrom} onChange={e => { setDateFrom(e.target.value); setCurrentPage(1) }} />
          <span>hasta</span>
          <input type="date" value={dateTo} onChange={e => { setDateTo(e.target.value); setCurrentPage(1) }} />
        </div>
      </div>

      <div className="currency-history__table-wrap">
        {loading ? (
          <div className="currency-history__loading"><Loader2 size={28} className="spin" /></div>
        ) : items.length === 0 ? (
          <div className="currency-history__empty">
            <History size={32} />
            <p>No hay registros</p>
          </div>
        ) : (
          <table className="currency-history__table">
            <thead>
              <tr>
                <th>Fecha</th>
                <th>Moneda</th>
                <th className="text-right">Tasa Admin.</th>
                <th className="text-right">Tasa Operat.</th>
                <th className="text-right">Tasa Compra</th>
                <th className="text-right">Tasa Venta</th>
                <th>Usuario</th>
              </tr>
            </thead>
            <tbody>
              {items
                .filter(r =>
                  (!search || r.currencyName.toLowerCase().includes(search.toLowerCase()) || r.currencyCode.toLowerCase().includes(search.toLowerCase()))
                )
                .map(row => (
                  <tr key={row.id}>
                    <td className="currency-history__date">{formatDate(row.date, "short")}</td>
                    <td>
                      <div className="currency-history__currency-cell">
                        <div className="currency-history__currency-icon">{getCurrencyIcon(row.currencyCode)}</div>
                        <div>
                          <strong>{row.symbol || row.currencyCode}</strong>
                          <span>{row.currencyCode}</span>
                        </div>
                      </div>
                    </td>
                    <td className="text-right currency-history__rate">{row.rateAdministrative != null ? formatNumber(row.rateAdministrative, 4) : "—"}</td>
                    <td className="text-right currency-history__rate">{row.rateOperative != null ? formatNumber(row.rateOperative, 4) : "—"}</td>
                    <td className="text-right currency-history__rate">{row.ratePurchase != null ? formatNumber(row.ratePurchase, 4) : "—"}</td>
                    <td className="text-right currency-history__rate">{row.rateSale != null ? formatNumber(row.rateSale, 4) : "—"}</td>
                    <td>{row.userName || "—"}</td>
                  </tr>
                ))}
            </tbody>
          </table>
        )}
      </div>

      {!loading && items.length > 0 && (
        <div className="currency-history__pagination">
          <span>
            Mostrando {startIdx} a {endIdx} de {totalRecords} registros
          </span>
          <div className="currency-history__pagination-controls">
            <button type="button" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>
              <ChevronLeft size={16} />
            </button>
            <span>Pagina {currentPage} de {totalPages}</span>
            <button type="button" onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))} disabled={currentPage === totalPages}>
              <ChevronRight size={16} />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
