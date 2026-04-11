"use client"

import { type ChangeEvent, useCallback, useEffect, useMemo, useState } from "react"
import {
  Banknote,
  Calendar,
  CheckCircle,
  Coins,
  DollarSign,
  Euro,
  Loader2,
  RefreshCw,
  Save,
  TrendingDown,
  TrendingUp,
  AlertCircle,
} from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import type { CurrencyRecord } from "@/lib/pos-data"
import { useFormat } from "@/lib/format-context"

type RateRow = {
  id: number
  code: string
  name: string
  symbol: string
  currentRate: number
  newRate: number
  change: number
  lastUpdate: string
  isLocal: boolean
}

function getCurrencyIcon(code: string) {
  switch (code) {
    case "USD": return <DollarSign size={18} />
    case "EUR": return <Euro size={18} />
    default: return <Banknote size={18} />
  }
}

export function CurrencyRatesScreen() {
  const { formatDate, formatDateTime, formatNumber, parseNumber } = useFormat()
  const [items, setItems] = useState<CurrencyRecord[]>([])
  const [rows, setRows] = useState<RateRow[]>([])
  const [draftRates, setDraftRates] = useState<Record<number, string>>({})
  const [loading, setLoading] = useState(true)
  const [isSaving, setIsSaving] = useState(false)
  const [lastSaved, setLastSaved] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch(apiUrl("/api/currencies/rates"), { credentials: "include" })
      const json = (await res.json()) as { ok: boolean; data?: CurrencyRecord[] }
      if (json.ok && json.data) {
        setItems(json.data)
        const nextRows = json.data
          .filter(c => !c.isLocal && c.active)
          .map(c => ({
            id: c.id,
            code: c.code,
            name: c.name,
            symbol: c.symbol ?? c.code,
            currentRate: c.rateOperative ?? 0,
            newRate: c.rateOperative ?? 0,
            change: 0,
            lastUpdate: c.lastRateDate,
            isLocal: c.isLocal,
          }))
        setRows(nextRows)
        setDraftRates(Object.fromEntries(nextRows.map((row) => [row.id, formatNumber(row.newRate, 4)])))
      }
    } finally {
      setLoading(false)
    }
  }, [formatNumber])

  useEffect(() => { void loadData() }, [loadData])

  function updateRate(id: number, value: number) {
    setRows(prev => prev.map(r => {
      if (r.id !== id) return r
      const change = r.currentRate > 0 ? ((value - r.currentRate) / r.currentRate) * 100 : 0
      return { ...r, newRate: value, change }
    }))
  }

  function handleDraftChange(id: number, value: string) {
    setDraftRates((current) => ({ ...current, [id]: value }))
    const parsed = parseNumber(value)
    updateRate(id, Number.isFinite(parsed) ? parsed : 0)
  }

  function handleDraftBlur(id: number) {
    const parsed = parseNumber(draftRates[id] ?? "0")
    const normalized = formatNumber(Number.isFinite(parsed) ? parsed : 0, 4)
    setDraftRates((current) => ({ ...current, [id]: normalized }))
  }

  const hasChanges = useMemo(() => rows.some(r => r.newRate !== r.currentRate), [rows])

  async function handleSave() {
    setIsSaving(true)
    try {
      const today = new Date().toISOString().slice(0, 10)
      const res = await fetch(apiUrl("/api/currencies/rates"), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          items: rows.map(r => ({
            currencyId: r.id,
            date: today,
            operativeRate: r.newRate,
          })),
        }),
      })
      const json = (await res.json()) as { ok: boolean; message?: string }
      if (!res.ok || !json.ok) {
        toast.error("Error", { description: json.message ?? "No se pudo guardar." })
        return
      }
      setRows(prev => prev.map(r => ({
        ...r,
        currentRate: r.newRate,
        lastUpdate: today,
        change: 0,
      })))
      setDraftRates((current) => {
        const next = { ...current }
        for (const row of rows) next[row.id] = formatNumber(row.newRate, 4)
        return next
      })
      setLastSaved(formatDateTime(new Date()))
      toast.success("Tasas guardadas correctamente")
      void loadData()
    } finally {
      setIsSaving(false)
    }
  }

  const today = formatDate(new Date(), "short")
  const activeCount = items.filter(c => !c.isLocal && c.active).length
  const localDate = rows[0]?.lastUpdate ? formatDate(rows[0].lastUpdate, "short") : ""

  return (
    <div className="currency-rates">
      <div className="currency-rates__header">
        <div className="currency-rates__header-title">
          <div className="currency-rates__header-icon"><TrendingUp size={22} /></div>
          <div>
            <h1>Actualizar Tasas del Dia</h1>
            <p>Actualiza las tasas de cambio para todas las monedas</p>
          </div>
        </div>
        <div className="currency-rates__header-actions">
          <button
            type="button"
            className="primary-button"
            onClick={() => void handleSave()}
            disabled={isSaving || !hasChanges}
          >
            {isSaving ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
            Guardar Tasas
          </button>
        </div>
      </div>

      <div className="currency-rates__stats">
        <div className="currency-rates__stat-card">
          <Calendar size={18} />
          <div>
            <span>Fecha</span>
            <strong>{today}</strong>
          </div>
        </div>
        <div className="currency-rates__stat-card">
          <Coins size={18} />
          <div>
            <span>Monedas Activas</span>
            <strong>{activeCount}</strong>
          </div>
        </div>
        <div className="currency-rates__stat-card">
          <RefreshCw size={18} />
          <div>
            <span>Ultima Actualizacion</span>
            <strong>{lastSaved || localDate || "—"}</strong>
          </div>
        </div>
        <div className="currency-rates__stat-card">
          {hasChanges ? <AlertCircle size={18} /> : <CheckCircle size={18} />}
          <div>
            <span>Estado</span>
            <strong>{hasChanges ? "Cambios Pendientes" : "Actualizado"}</strong>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="currency-rates__loading"><Loader2 size={28} className="spin" /></div>
      ) : (
        <div className="currency-rates__table-wrap">
          <table className="currency-rates__table">
            <thead>
              <tr>
                <th>Moneda</th>
                <th className="text-right">Tasa Actual</th>
                <th className="text-right">Nueva Tasa</th>
                <th className="text-right">Variacion</th>
                <th className="text-right">Ultima Actualizacion</th>
              </tr>
            </thead>
            <tbody>
              {rows.map(row => {
                const isChanged = row.newRate !== row.currentRate
                return (
                  <tr key={row.id} className={isChanged ? "is-changed" : ""}>
                    <td>
                      <div className="currency-rates__currency-cell">
                        <div className="currency-rates__currency-icon">{getCurrencyIcon(row.code)}</div>
                        <div>
                          <strong>{row.symbol}</strong>
                          <span>{row.name}</span>
                        </div>
                      </div>
                    </td>
                    <td className="text-right currency-rates__rate">{formatNumber(row.currentRate, 4)}</td>
                    <td className="text-right currency-rates__new-rate-cell">
                      <input
                        type="text"
                        inputMode="decimal"
                        value={draftRates[row.id] ?? formatNumber(row.newRate, 4)}
                        onChange={(e: ChangeEvent<HTMLInputElement>) => handleDraftChange(row.id, e.target.value)}
                        onBlur={() => handleDraftBlur(row.id)}
                        className="currency-rates__input"
                      />
                      <span className="currency-rates__new-rate-preview">{formatNumber(row.newRate, 4)}</span>
                    </td>
                    <td className="text-right">
                      {row.change !== 0 && (
                        <span className={`currency-rates__badge ${row.change > 0 ? "is-up" : "is-down"}`}>
                          {row.change > 0 ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
                          {row.change > 0 ? "+" : ""}{formatNumber(row.change, 2)}%
                        </span>
                      )}
                    </td>
                    <td className="text-right currency-rates__date">{row.lastUpdate ? formatDate(row.lastUpdate, "short") : "—"}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
