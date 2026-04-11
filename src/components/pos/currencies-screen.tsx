"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState } from "react"
import {
  Banknote,
  Coins,
  Copy,
  DollarSign,
  Euro,
  Loader2,
  MoreHorizontal,
  Pencil,
  Plus,
  PoundSterling,
  Save,
  Search,
  Settings,
  Trash2,
  X,
} from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import type { CurrencyRecord } from "@/lib/pos-data"
import { useFormat } from "@/lib/format-context"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

const emptyForm: CurrencyForm = {
  id: 0,
  code: "",
  isLocal: false,
  name: "",
  symbol: "",
  symbolAlt: "",
  bankCode: "",
  factorConversionLocal: "1",
  factorConversionUSD: "1",
  showInPOS: true,
  acceptPayments: true,
  decimalPOS: "2",
  active: true,
  rateAdministrative: "",
  rateOperative: "",
  ratePurchase: "",
  rateSale: "",
  lastRateDate: "",
}

type CurrencyForm = {
  id: number
  code: string
  isLocal: boolean
  name: string
  symbol: string
  symbolAlt: string
  bankCode: string
  factorConversionLocal: string
  factorConversionUSD: string
  showInPOS: boolean
  acceptPayments: boolean
  decimalPOS: string
  active: boolean
  rateAdministrative: string
  rateOperative: string
  ratePurchase: string
  rateSale: string
  lastRateDate: string
}

function recordToForm(r: CurrencyRecord): CurrencyForm {
  return {
    id: r.id,
    code: r.code,
    isLocal: r.isLocal,
    name: r.name,
    symbol: r.symbol ?? "",
    symbolAlt: r.symbolAlt ?? "",
    bankCode: r.bankCode ?? "",
    factorConversionLocal: String(r.factorConversionLocal),
    factorConversionUSD: String(r.factorConversionUSD),
    showInPOS: r.showInPOS,
    acceptPayments: r.acceptPayments,
    decimalPOS: String(r.decimalPOS),
    active: r.active,
    rateAdministrative: r.rateAdministrative != null ? String(r.rateAdministrative) : "",
    rateOperative: r.rateOperative != null ? String(r.rateOperative) : "",
    ratePurchase: r.ratePurchase != null ? String(r.ratePurchase) : "",
    rateSale: r.rateSale != null ? String(r.rateSale) : "",
    lastRateDate: r.lastRateDate,
  }
}

function duplicateRecordToForm(r: CurrencyRecord): CurrencyForm {
  return {
    ...recordToForm(r),
    id: 0,
    code: "",
    name: `${r.name} COPIA`,
  }
}

function getCurrencyIcon(code: string) {
  switch (code) {
    case "USD": return <DollarSign size={18} />
    case "EUR": return <Euro size={18} />
    case "GBP": return <PoundSterling size={18} />
    default: return <Banknote size={18} />
  }
}

export function CurrenciesScreen() {
  const { formatDate, formatNumber } = useFormat()
  const { setDirty, confirmAction } = useUnsavedGuard()
  const [items, setItems] = useState<CurrencyRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [query, setQuery] = useState("")
  const menuRef = useRef<HTMLUListElement | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [isCreating, setIsCreating] = useState(false)
  const [isBusy, setIsBusy] = useState(false)
  const [form, setForm] = useState<CurrencyForm | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [menuOpenId, setMenuOpenId] = useState<number | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<CurrencyRecord | null>(null)

  const loadData = useCallback(async () => {
    setLoading(true)
    try {
      const res = await fetch(apiUrl("/api/currencies"), { credentials: "include" })
      const json = (await res.json()) as { ok: boolean; data?: CurrencyRecord[] }
      if (json.ok && json.data) {
        console.log("API currencies:", json.data.map(d => `${d.code} rateOp=${d.rateOperative}`))
        setItems(json.data)
        if (json.data.length > 0 && !selectedId) {
          setSelectedId(json.data[0].id)
          setForm(recordToForm(json.data[0]))
        }
      }
    } finally {
      setLoading(false)
    }
  }, [selectedId])

  useEffect(() => { void loadData() }, [loadData])

  function selectItem(item: CurrencyRecord) {
    confirmAction(() => {
      setIsEditing(false)
      setDirty(false)
      setSelectedId(item.id)
      console.log("SELECT ITEM:", item.code, "rateOperative=", item.rateOperative)
      setForm(recordToForm(item))
      setMessage(null)
    })
    return
  }

  function beginEdit() {
    setMessage(null)
    setIsEditing(true)
    setDirty(true)
  }

  function cancelEdit() {
    if (isCreating) {
      setIsCreating(false)
      setForm(selectedId ? recordToForm(items.find(i => i.id === selectedId)!) : null)
    } else {
      const current = items.find(i => i.id === selectedId)
      if (current) setForm(recordToForm(current))
    }
    setMessage(null)
    setIsEditing(false)
    setDirty(false)
  }

  function handleNew() {
    setIsCreating(true)
    setIsEditing(true)
    setDirty(true)
    setSelectedId(null)
    setForm({ ...emptyForm })
    setMessage(null)
  }

  function handleDuplicate(item: CurrencyRecord) {
    setIsCreating(true)
    setIsEditing(true)
    setDirty(true)
    setSelectedId(null)
    setForm(duplicateRecordToForm(item))
    setMessage(null)
    setMenuOpenId(null)
  }

  async function handleDelete(id: number) {
    if (!confirm("¿Eliminar esta moneda?")) return
    try {
      const res = await fetch(apiUrl(`/api/currencies/${id}`), { method: "DELETE", credentials: "include" })
      const json = (await res.json()) as { ok: boolean; message?: string }
      if (!res.ok || !json.ok) { toast.error(json.message ?? "No se pudo eliminar."); return }
      toast.success("Moneda eliminada")
      setMenuOpenId(null)
      if (selectedId === id) { setSelectedId(null); setForm(null) }
      void loadData()
    } catch { toast.error("Error al eliminar.") }
  }

  async function submitNew(event: FormEvent) {
    event.preventDefault()
    if (!form) return
    if (!form.code.trim()) { setMessage("El código es obligatorio."); return }
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }

    setIsBusy(true)
    setMessage(null)
    try {
      const res = await fetch(apiUrl("/api/currencies"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          code: form.code.trim().toUpperCase(),
          name: form.name.trim(),
          symbol: form.symbol || null,
          symbolAlt: form.symbolAlt || null,
          bankCode: form.bankCode || null,
          factorConversionLocal: form.factorConversionLocal ? Number(form.factorConversionLocal) : 1,
          factorConversionUSD: form.factorConversionUSD ? Number(form.factorConversionUSD) : 1,
          showInPOS: form.showInPOS,
          acceptPayments: form.acceptPayments,
          decimalPOS: form.decimalPOS ? Number(form.decimalPOS) : 2,
        }),
      })
      const json = (await res.json()) as { ok: boolean; id?: number; message?: string }
      if (!res.ok || !json.ok) { setMessage(json.message ?? "No se pudo crear."); return }
      toast.success("Moneda creada")
      setIsCreating(false)
      setIsEditing(false)
      setDirty(false)
      setSelectedId(json.id ?? null)
      void loadData()
    } finally {
      setIsBusy(false)
    }
  }

  function update<K extends keyof CurrencyForm>(key: K, value: CurrencyForm[K]) {
    setForm(prev => prev ? { ...prev, [key]: value } : prev)
  }

  async function submit(event: FormEvent) {
    event.preventDefault()
    if (!isEditing || !form) return
    if (!form.name.trim()) { setMessage("El nombre es obligatorio."); return }

    setIsBusy(true)
    setMessage(null)
    try {
      const res = await fetch(apiUrl("/api/currencies"), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: form.id,
          name: form.name,
          symbol: form.symbol || null,
          symbolAlt: form.symbolAlt || null,
          bankCode: form.bankCode || null,
          factorConversionLocal: form.factorConversionLocal ? Number(form.factorConversionLocal) : 1,
          factorConversionUSD: form.factorConversionUSD ? Number(form.factorConversionUSD) : 1,
          showInPOS: form.showInPOS,
          acceptPayments: form.acceptPayments,
          decimalPOS: form.decimalPOS ? Number(form.decimalPOS) : 2,
          active: form.active,
        }),
      })
      const json = (await res.json()) as { ok: boolean; message?: string }
      if (!res.ok || !json.ok) {
        const msg = json.message ?? "No se pudo guardar."
        setMessage(msg)
        toast.error("Error al guardar", { description: msg })
        return
      }
      toast.success("Cambios guardados")
      setIsEditing(false)
      setDirty(false)
      void loadData()
    } finally {
      setIsBusy(false)
    }
  }

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return items
    return items.filter(i =>
      i.name.toLowerCase().includes(q) ||
      i.code.toLowerCase().includes(q) ||
      (i.symbol ?? "").toLowerCase().includes(q)
    )
  }, [items, query])

  const selected = useMemo(() => items.find(i => i.id === selectedId) ?? null, [items, selectedId])

  return (
    <div className="currencies-layout">
      <aside className="currencies-sidebar">
        <div className="currencies-sidebar__header">
          <h2 className="currencies-sidebar__title"><Coins size={16} /> Monedas</h2>
          <button className="sidebar__add-btn" type="button" onClick={handleNew} title="Nueva moneda">
            <Plus size={15} />
          </button>
        </div>
        <div className="currencies-sidebar__search">
          <Search size={13} className="currencies-sidebar__search-icon" />
          <input
            type="text"
            placeholder="Buscar moneda..."
            value={query}
            onChange={e => setQuery(e.target.value)}
            className="currencies-sidebar__search-input"
          />
        </div>

        {loading ? (
          <div className="currencies-loading"><Loader2 size={20} className="spin" /></div>
        ) : (
          <ul className="currencies-sidebar__list">
            {filtered.map(item => (
              <li key={item.id} className={`currencies-sidebar__item${selectedId === item.id ? " is-selected" : ""}`} onClick={() => selectItem(item)}>
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                    {item.active ? "Activo" : "Inactivo"}
                  </span>
                  {item.isLocal && <span className="currencies-sidebar__badge">Local</span>}
                  <div className="price-lists-sidebar__menu-wrap">
                    <button
                      className="price-lists-sidebar__menu-btn"
                      type="button"
                      onClick={e => { e.stopPropagation(); setMenuOpenId(menuOpenId === item.id ? null : item.id) }}
                    >
                      <MoreHorizontal size={14} />
                    </button>
                    {menuOpenId === item.id && (
                      <ul className="price-lists-dropdown" ref={menuRef} onClick={e => e.stopPropagation()}>
                        <li>
                          <button type="button" onClick={() => handleDuplicate(item)}>
                            <Copy size={13} /> Duplicar
                          </button>
                        </li>
                        {!item.isLocal && (
                          <li className="is-danger">
                            <button type="button" onClick={() => void handleDelete(item.id)}>
                              <Trash2 size={13} /> Eliminar
                            </button>
                          </li>
                        )}
                      </ul>
                    )}
                  </div>
                </div>
                <div className="currencies-sidebar__info">
                  <strong>{item.symbol || item.code}</strong>
                  <span>{item.name}</span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </aside>

      {(selected || isCreating) && form ? (
        <section className="currencies-detail">
          <div className="currencies-detail__header">
            <div className="currencies-detail__title-row">
              <div className={`currencies-detail__icon${form.isLocal ? " is-local" : ""}`}>
                {getCurrencyIcon(form.code)}
              </div>
              <div>
                <h1 className="currencies-detail__name">{isCreating ? "Nueva Moneda" : form.name}</h1>
                {!isCreating && <span className="currencies-detail__subtitle">{form.symbol} — {form.code}</span>}
              </div>
            </div>
            <div className="currencies-detail__actions">
              {isEditing ? (
                <>
                  <button type="button" className="ghost-button" onClick={cancelEdit} disabled={isBusy}>
                    <X size={15} /> Cancelar
                  </button>
                  <button type="button" className="primary-button" onClick={e => void (isCreating ? submitNew(e) : submit(e))} disabled={isBusy}>
                    {isBusy ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
                    {isCreating ? "Crear" : "Guardar"}
                  </button>
                </>
              ) : (
                <button type="button" className="primary-button" onClick={beginEdit}>
                  <Pencil size={15} /> Editar Datos
                </button>
              )}
            </div>
          </div>

          {message ? <div className="currencies-detail__message">{message}</div> : null}

          <div className="currencies-detail__body">
            <form onSubmit={submit}>
              <div className="form-grid form-grid--spaced">
                <label className="form-grid__full"><span>Nombre</span><input
                    type="text"
                    value={form.name}
                    onChange={e => update("name", e.target.value)}
                    disabled={!isEditing}
                    required
                  /></label>

                <label><span>Simbolo Primario</span><input type="text" value={form.symbol} onChange={e => update("symbol", e.target.value)} disabled={!isEditing} /></label>

                <label><span>Codigo Referencia Bancos</span><input type="text" value={form.bankCode} onChange={e => update("bankCode", e.target.value)} disabled={!isEditing} /></label>

                <label><span>Simbolo Alterno</span><input type="text" value={form.symbolAlt} onChange={e => update("symbolAlt", e.target.value)} disabled={!isEditing} /></label>

                <label><span>Codigo</span><input type="text" value={form.code} onChange={e => update("code", e.target.value.toUpperCase())} disabled={!isCreating} maxLength={5} /></label>

                <label className="company-active-toggle form-grid__full">
                  <div><span>Activo</span></div>
                  <button
                    className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                    type="button"
                    onClick={() => isEditing && update("active", !form.active)}
                    disabled={!isEditing}
                    aria-label="Activo"
                  >
                    <span />
                  </button>
                </label>
              </div>

              <h3 className="currencies-form__section-title"><Settings size={14} /> Configuracion POS</h3>
              <div className="form-grid form-grid--spaced">
                <label className="company-active-toggle form-grid__full">
                  <div><span>Mostrar en POS</span></div>
                  <button
                    className={form.showInPOS ? "toggle-switch is-on" : "toggle-switch"}
                    type="button"
                    onClick={() => isEditing && update("showInPOS", !form.showInPOS)}
                    disabled={!isEditing}
                    aria-label="Mostrar en POS"
                  >
                    <span />
                  </button>
                </label>

                <label className="company-active-toggle form-grid__full">
                  <div><span>Acepta Pagos</span></div>
                  <button
                    className={form.acceptPayments ? "toggle-switch is-on" : "toggle-switch"}
                    type="button"
                    onClick={() => isEditing && update("acceptPayments", !form.acceptPayments)}
                    disabled={!isEditing}
                    aria-label="Acepta Pagos"
                  >
                    <span />
                  </button>
                </label>

                <label><span>Decimales POS</span><input type="number" min="0" max="4" value={form.decimalPOS} onChange={e => update("decimalPOS", e.target.value)} disabled={!isEditing} /></label>

                <label><span>Factor Conversion DOP</span><input type="number" step="0.000001" value={form.factorConversionLocal} onChange={e => update("factorConversionLocal", e.target.value)} disabled={!isEditing || form.code === "DOP"} /></label>

                <label><span>Factor Conversion USD</span><input type="number" step="0.000001" value={form.factorConversionUSD} onChange={e => update("factorConversionUSD", e.target.value)} disabled={!isEditing || form.code === "DOP"} /></label>
              </div>

              {!form.isLocal && (
                <>
                  <h3 className="currencies-form__section-title"><Coins size={14} /> Tasas de Cambio</h3>
                  <div className="form-grid form-grid--spaced">
                    <label><span>Tasa Administrativa</span>
                      {isEditing ? (
                        <input type="number" step="0.0001" value={form.rateAdministrative} onChange={e => update("rateAdministrative", e.target.value)} disabled={!isEditing} className="currencies-form__number" />
                      ) : (
                        <span className="currencies-form__formatted-rate">{form.rateAdministrative ? formatNumber(parseFloat(form.rateAdministrative), 4) : "—"}</span>
                      )}
                    </label>
                    <label><span>Tasa Operativa</span>
                      {isEditing ? (
                        <input type="number" step="0.0001" value={form.rateOperative} onChange={e => update("rateOperative", e.target.value)} disabled={!isEditing} className="currencies-form__number" />
                      ) : (
                        <span className="currencies-form__formatted-rate">{form.rateOperative ? formatNumber(parseFloat(form.rateOperative), 4) : "—"}</span>
                      )}
                    </label>
                    <label><span>Tasa de Compra</span>
                      {isEditing ? (
                        <input type="number" step="0.0001" value={form.ratePurchase} onChange={e => update("ratePurchase", e.target.value)} disabled={!isEditing} className="currencies-form__number" />
                      ) : (
                        <span className="currencies-form__formatted-rate">{form.ratePurchase ? formatNumber(parseFloat(form.ratePurchase), 4) : "—"}</span>
                      )}
                    </label>
                    <label><span>Tasa de Venta</span>
                      {isEditing ? (
                        <input type="number" step="0.0001" value={form.rateSale} onChange={e => update("rateSale", e.target.value)} disabled={!isEditing} className="currencies-form__number" />
                      ) : (
                        <span className="currencies-form__formatted-rate">{form.rateSale ? formatNumber(parseFloat(form.rateSale), 4) : "—"}</span>
                      )}
                    </label>
                  </div>
                  <p className="currencies-form__hint">Ultima actualizacion: {form.lastRateDate ? formatDate(form.lastRateDate, "short") : "—"}</p>
                </>
              )}
            </form>
          </div>
        </section>
      ) : (
        <section className="currencies-empty">
          <Coins size={44} />
          <p>Selecciona una moneda</p>
        </section>
      )}
    </div>
  )
}
