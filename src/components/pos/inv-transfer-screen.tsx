"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react"
import { ArrowRight, Ban, ChevronDown, ChevronUp, Eye, FileText, Filter, Loader2, Pencil, Plus, Printer, RefreshCw, Save, Search, Send, Trash2, Truck, Undo2, X } from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { usePermissions } from "@/lib/permissions-context"
import { useFormat } from "@/lib/format-context"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import type { InvDocumentoDetalleRecord, InvProductoParaDocumento, InvTipoDocumentoRecord, InvTransferenciaEstado, InvTransferenciaRecord, InvTransferenciasListResult, UnidadOpcion, WarehouseRecord } from "@/lib/pos-data"

type TransferLine = {
  key: string
  idProducto: number | null
  codigo: string
  descripcion: string
  existenciaActual: number | null
  existenciaBase: number | null
  costoBase: number | null
  idUnidadBase: number | null
  idUnidadMedida: number | null
  unidad: string
  cantidad: number
  costo: number
  total: number
  pideUnidadInventario: boolean
  unidadesDisponibles: UnidadOpcion[]
}

type TransferForm = {
  idTipoDocumento: number | null
  fecha: string
  periodo: string
  idAlmacen: number | null
  idAlmacenDestino: number | null
  referencia: string
  observacion: string
}

type Props = {
  title: string
  docTypes: InvTipoDocumentoRecord[]
  warehouses: WarehouseRecord[]
  initialList: InvTransferenciasListResult
  initialFechaDesde?: string
  initialFechaHasta?: string
}

function today() { return new Date().toISOString().slice(0, 10) }
function toPeriodo(fecha: string) { return fecha.replace(/-/g, "").slice(0, 6) }
function formatDocPreview(tipo?: InvTipoDocumentoRecord | null) {
  if (!tipo) return ""
  const nextSecuencia = Math.max((tipo.secuenciaActual ?? 0) + 1, tipo.secuenciaInicial || 1)
  const secuencia = String(nextSecuencia).padStart(4, "0")
  const prefijo = (tipo.prefijo || "").trim()
  return prefijo ? `${prefijo}-${secuencia}` : secuencia
}
function emptyLine(): TransferLine { return { key: crypto.randomUUID(), idProducto: null, codigo: "", descripcion: "", existenciaActual: null, existenciaBase: null, costoBase: null, idUnidadBase: null, idUnidadMedida: null, unidad: "", cantidad: 0, costo: 0, total: 0, pideUnidadInventario: false, unidadesDisponibles: [] } }
function emptyForm(): TransferForm { return { idTipoDocumento: null, fecha: today(), periodo: toPeriodo(today()), idAlmacen: null, idAlmacenDestino: null, referencia: "", observacion: "" } }
function stateLabel(state: InvTransferenciaEstado) { return state === "B" ? "Borrador" : state === "T" ? "En Transito" : state === "C" ? "Completado" : "Anulado" }
function stateClass(state: InvTransferenciaEstado) { return state === "B" ? "inv-transfer-badge inv-transfer-badge--draft" : state === "T" ? "inv-transfer-badge inv-transfer-badge--transit" : state === "C" ? "inv-transfer-badge inv-transfer-badge--completed" : "inv-transfer-badge inv-transfer-badge--voided" }
function formatDateTimeLabel(value?: string) {
  if (!value) return "N/D"
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  }).format(date)
}
function unitFactor(unit?: UnidadOpcion | null) { if (!unit) return 1; const baseA = unit.baseA && unit.baseA > 0 ? unit.baseA : 1; const baseB = unit.baseB && unit.baseB > 0 ? unit.baseB : 1; return baseB / baseA }
function convertQuantityBetweenUnits(quantity: number, fromUnit?: UnidadOpcion | null, toUnit?: UnidadOpcion | null) { const fromFactor = unitFactor(fromUnit); const toFactor = unitFactor(toUnit); if (!Number.isFinite(quantity) || toFactor === 0) return 0; return Number(((quantity * fromFactor) / toFactor).toFixed(4)) }
function convertCostFromBase(costBase: number, baseUnit?: UnidadOpcion | null, selectedUnit?: UnidadOpcion | null) { const baseFactor = unitFactor(baseUnit); const selectedFactor = unitFactor(selectedUnit); if (!Number.isFinite(costBase) || baseFactor === 0) return 0; return Number(((costBase * selectedFactor) / baseFactor).toFixed(4)) }

export function InvTransferScreen({ title, docTypes, warehouses, initialList, initialFechaDesde = "", initialFechaHasta = "" }: Props) {
  const { formatNumber } = useFormat()
  const { hasPermission, isLoading: permissionsLoading, permissions } = usePermissions()
  const hasLegacyFallback = permissionsLoading || permissions.length === 0
  const canVisualize = hasLegacyFallback || hasPermission("inventory.transfers.view") || hasPermission("catalog.view")
  const canEdit = hasLegacyFallback || hasPermission("inventory.transfers.edit") || hasPermission("catalog.edit") || hasPermission("catalog.view")
  const canVoid = hasLegacyFallback || hasPermission("inventory.transfers.void") || hasPermission("inventory.transfers.edit") || hasPermission("catalog.delete") || hasPermission("catalog.edit") || hasPermission("catalog.view")
  const canPrint = hasLegacyFallback || hasPermission("inventory.transfers.print") || canVisualize
  const canGenerateExit = hasLegacyFallback || hasPermission("inventory.transfers.generate-exit") || hasPermission("inventory.transfers.edit") || hasPermission("catalog.view")
  const canConfirmReception = hasLegacyFallback || hasPermission("inventory.transfers.confirm-reception") || hasPermission("inventory.transfers.edit") || hasPermission("catalog.view")

  const businessWarehouses = useMemo(() => warehouses.filter((item) => item.type !== "T"), [warehouses])
  const [view, setView] = useState<"list" | "form" | "detail">("list")
  const { setDirty, confirmAction } = useUnsavedGuard()
  const [items, setItems] = useState(initialList.items)
  const [selected, setSelected] = useState<{ header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] } | null>(null)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [form, setForm] = useState<TransferForm>(emptyForm())
  const [lines, setLines] = useState<TransferLine[]>([emptyLine()])
  const [message, setMessage] = useState<string | null>(null)
  const [fFechaDesde, setFFechaDesde] = useState(initialFechaDesde)
  const [fFechaHasta, setFFechaHasta] = useState(initialFechaHasta)
  const [fEstado, setFEstado] = useState("")
  const [fSecuenciaDesde, setFSecuenciaDesde] = useState("")
  const [fSecuenciaHasta, setFSecuenciaHasta] = useState("")
  const [page, setPage] = useState(initialList.page)
  const [pageSize, setPageSize] = useState(initialList.pageSize)
  const [totalRows, setTotalRows] = useState(initialList.total)
  const [listLoading, setListLoading] = useState(false)
  const [isPending, startTransition] = useTransition()
  const totalPages = Math.max(1, Math.ceil(totalRows / pageSize))
  const codeRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const cantidadRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const unitRefs = useRef<Record<string, HTMLSelectElement | null>>({})
  const costInputRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const formRef = useRef<HTMLFormElement | null>(null)
  const [entryTab, setEntryTab] = useState<"detail" | "notes">("detail")
  const [detailTab, setDetailTab] = useState<"detail" | "notes">("detail")
  const [detailSections, setDetailSections] = useState({ summary: true, salida: true, recepcion: true })
  const [activeLineKey, setActiveLineKey] = useState<string | null>(null)
  const [searchOpen, setSearchOpen] = useState(false)
  const [searchTargetLineKey, setSearchTargetLineKey] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState("")
  const [searchResults, setSearchResults] = useState<InvProductoParaDocumento[]>([])
  const [searchLoading, setSearchLoading] = useState(false)

  const total = useMemo(() => lines.reduce((sum, line) => sum + line.total, 0), [lines])
  const selectedDocType = useMemo(() => docTypes.find((item) => item.id === form.idTipoDocumento) ?? null, [docTypes, form.idTipoDocumento])
  const isHeaderReadyForDetail = Boolean(form.fecha && form.idTipoDocumento && form.idAlmacen && form.idAlmacenDestino && form.idAlmacen !== form.idAlmacenDestino)
  const detailLockedMessage = "Complete Fecha, Tipo Documento, Almacen Origen y Almacen Destino para habilitar el detalle."
  const docNumeroPreview = useMemo(() => {
    if (editingId && selected) return selected.header.numeroDocumento
    return formatDocPreview(selectedDocType) || "Auto"
  }, [editingId, selected, selectedDocType])

  useEffect(() => {
    if (!selected) return
    setDetailSections({
      summary: true,
      salida: true,
      recepcion: selected.header.estadoTransferencia === "C",
    })
  }, [selected])

  function updateLine(key: string, update: (line: TransferLine) => TransferLine) { setLines((prev) => prev.map((line) => line.key === key ? update(line) : line)) }
  function addLine() {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    const line = emptyLine()
    setLines((prev) => [...prev, line])
    setTimeout(() => codeRefs.current[line.key]?.focus(), 10)
  }
  function removeLine(key: string) { setLines((prev) => prev.filter((line) => line.key !== key).length ? prev.filter((line) => line.key !== key) : [emptyLine()]) }

  const loadDocuments = useCallback(async (p: number, ps: number, overrides?: { fechaDesde?: string; fechaHasta?: string; secuenciaDesde?: string; secuenciaHasta?: string; estado?: string }) => {
    setListLoading(true)
    try {
      const params = new URLSearchParams()
      params.set("page", String(p))
      params.set("pageSize", String(ps))
      const fd = overrides?.fechaDesde ?? fFechaDesde
      const fh = overrides?.fechaHasta ?? fFechaHasta
      const sd = overrides?.secuenciaDesde ?? fSecuenciaDesde
      const sh = overrides?.secuenciaHasta ?? fSecuenciaHasta
      const est = overrides?.estado ?? fEstado
      if (fd) params.set("desde", fd)
      if (fh) params.set("hasta", fh)
      if (sd) params.set("secuenciaDesde", sd)
      if (sh) params.set("secuenciaHasta", sh)
      if (est) params.set("estado", est)
      const res = await fetch(apiUrl(`/api/inventory/transfers?${params.toString()}`), { credentials: "include", cache: "no-store" })
      const result = await res.json() as { ok: boolean; data?: InvTransferenciasListResult; message?: string }
      if (!res.ok || !result.ok || !result.data) throw new Error(result.message ?? "No se pudo cargar el listado.")
      setItems(result.data.items)
      setTotalRows(result.data.total)
      setPage(result.data.page)
      setPageSize(result.data.pageSize)
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "No se pudo cargar el listado.")
    } finally {
      setListLoading(false)
    }
  }, [fFechaDesde, fFechaHasta, fSecuenciaDesde, fSecuenciaHasta, fEstado])

  async function viewTransfer(id: number) {
    try {
      const res = await fetch(apiUrl(`/api/inventory/transfers/${id}`), { credentials: "include", cache: "no-store" })
      const result = await res.json() as { ok: boolean; data?: { header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }; message?: string }
      if (!res.ok || !result.ok || !result.data) throw new Error(result.message ?? "No se pudo cargar la transferencia.")
      setSelected(result.data)
      setDetailTab("detail")
      setView("detail")
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "No se pudo cargar la transferencia.")
    }
  }

  async function lookupProduct(key: string, code: string) {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    if (!code.trim()) return
    try {
      const almParam = form.idAlmacen ? `&almacen=${form.idAlmacen}` : ""
      const res = await fetch(apiUrl(`/api/inventory/products/by-code?code=${encodeURIComponent(code.trim())}${almParam}`), { credentials: "include" })
      const result = await res.json() as { ok: boolean; data?: InvProductoParaDocumento; message?: string }
      if (!res.ok || !result.ok || !result.data) throw new Error(result.message ?? "Producto no encontrado.")
      const product = result.data
      const baseUnit = product.unidades.find((item) => item.id === product.idUnidadBase) ?? null
      const selectedUnit = product.unidades.find((item) => item.id === product.idUnidadVenta) ?? product.unidades.find((item) => item.id === product.idUnidadMedida) ?? null
      const selectedUnitId = selectedUnit?.id ?? product.idUnidadMedida
      const selectedCost = convertCostFromBase(product.costoPromedio, baseUnit, selectedUnit)
      updateLine(key, (line) => ({ ...line, idProducto: product.id, codigo: product.codigo, descripcion: product.nombre, existenciaActual: convertQuantityBetweenUnits(product.existencia, baseUnit, selectedUnit), existenciaBase: product.existencia, costoBase: product.costoPromedio, idUnidadBase: product.idUnidadBase, idUnidadMedida: selectedUnitId, unidad: selectedUnit?.abreviatura ?? product.abreviaturaUnidad, costo: selectedCost, total: Number((line.cantidad * selectedCost).toFixed(4)), pideUnidadInventario: product.pideUnidadInventario, unidadesDisponibles: product.unidades }))
      // Mover focus a cantidad después del lookup
      setTimeout(() => {
        cantidadRefs.current[key]?.focus()
        cantidadRefs.current[key]?.select()
      }, 30)
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Producto no encontrado.")
    }
  }

  async function getProductoDocumentoByCode(code: string, idAlmacen: number | null): Promise<InvProductoParaDocumento | null> {
    const normalizedCode = code.trim()
    if (!normalizedCode) return null
    try {
      const almParam = idAlmacen ? `&almacen=${idAlmacen}` : ""
      const res = await fetch(apiUrl(`/api/inventory/products/by-code?code=${encodeURIComponent(normalizedCode)}${almParam}`), { credentials: "include" })
      const result = await res.json() as { ok: boolean; data?: InvProductoParaDocumento }
      if (!res.ok || !result.ok || !result.data) return null
      return result.data
    } catch {
      return null
    }
  }

  const openSearch = useCallback((lineKey: string) => {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    setSearchTargetLineKey(lineKey)
    setSearchOpen(true)
    setSearchQuery("")
    setSearchResults([])
  }, [detailLockedMessage, isHeaderReadyForDetail])

  const doSearch = useCallback(async (q: string) => {
    if (!q.trim()) { setSearchResults([]); return }
    setSearchLoading(true)
    try {
      const almParam = form.idAlmacen ? `&almacen=${form.idAlmacen}` : ""
      const res = await fetch(apiUrl(`/api/inventory/products/search?q=${encodeURIComponent(q.trim())}${almParam}`), { credentials: "include" })
      const result = (await res.json()) as { ok: boolean; data?: InvProductoParaDocumento[] }
      if (result.ok && result.data) setSearchResults(result.data)
    } catch {
      toast.error("Error al buscar.")
    } finally {
      setSearchLoading(false)
    }
  }, [form.idAlmacen])

  function selectProduct(product: InvProductoParaDocumento) {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    if (!searchTargetLineKey) return
    const key = searchTargetLineKey
    const baseUnit = product.unidades.find((item) => item.id === product.idUnidadBase) ?? null
    const unit = product.unidades.find((item) => item.id === product.idUnidadVenta) ?? product.unidades.find((item) => item.id === product.idUnidadMedida) ?? null
    const costo = convertCostFromBase(product.costoPromedio, baseUnit, unit)
    const cantidad = 1
    updateLine(key, (line) => ({
      ...line,
      idProducto: product.id,
      codigo: product.codigo,
      descripcion: product.nombre,
      existenciaActual: convertQuantityBetweenUnits(product.existencia, baseUnit, unit),
      existenciaBase: product.existencia,
      costoBase: product.costoPromedio,
      idUnidadBase: product.idUnidadBase,
      idUnidadMedida: unit?.id ?? product.idUnidadMedida ?? null,
      unidad: unit?.abreviatura ?? product.abreviaturaUnidad,
      cantidad,
      costo,
      total: Number((cantidad * costo).toFixed(4)),
      pideUnidadInventario: product.pideUnidadInventario,
      unidadesDisponibles: product.unidades,
    }))
    setSearchOpen(false)
    setLines((prev) => {
      const idx = prev.findIndex((l) => l.key === key)
      if (idx === prev.length - 1) return [...prev, emptyLine()]
      return prev
    })
  }

  useEffect(() => {
    if (!searchOpen) return
    const timer = setTimeout(() => { void doSearch(searchQuery) }, 300)
    return () => clearTimeout(timer)
  }, [searchQuery, searchOpen, doSearch])

  useEffect(() => {
    if (view !== "form") return
    if (activeLineKey || lines.length === 0) return
    setActiveLineKey(lines[0].key)
  }, [activeLineKey, lines, view])

  function onFechaChange(fecha: string) {
    setForm((prev) => ({ ...prev, fecha, periodo: toPeriodo(fecha) }))
  }

  function openNew() {
    setForm(emptyForm())
    setLines([emptyLine()])
    setEditingId(null)
    setMessage(null)
    setEntryTab("detail")
    setActiveLineKey(null)
    setDirty(true)
    setView("form")
  }
  async function openEdit() {
    if (!selected) return
    const fecha = selected.header.fecha.slice(0, 10)
    const mappedLines = await Promise.all(selected.lines.map(async (line) => {
      const product = await getProductoDocumentoByCode(line.codigo, selected.header.idAlmacen)
      const isSameProduct = product?.id === line.idProducto
      const resolvedProduct = isSameProduct ? product : null
      return {
        key: crypto.randomUUID(),
        idProducto: line.idProducto,
        codigo: line.codigo,
        descripcion: line.descripcion,
        existenciaActual: resolvedProduct ? convertQuantityBetweenUnits(resolvedProduct.existencia, resolvedProduct.unidades.find((item) => item.id === resolvedProduct.idUnidadBase) ?? null, resolvedProduct.unidades.find((item) => item.id === line.idUnidadMedida) ?? null) : null,
        existenciaBase: resolvedProduct?.existencia ?? null,
        costoBase: resolvedProduct?.costoPromedio ?? (line.cantidad > 0 ? Number((line.total / line.cantidad).toFixed(4)) : line.costo),
        idUnidadBase: resolvedProduct?.idUnidadBase ?? null,
        idUnidadMedida: line.idUnidadMedida,
        unidad: line.nombreUnidad,
        cantidad: line.cantidad,
        costo: line.costo,
        total: line.total,
        pideUnidadInventario: Boolean(resolvedProduct?.pideUnidadInventario),
        unidadesDisponibles: resolvedProduct?.unidades ?? (line.idUnidadMedida ? [{ id: line.idUnidadMedida, nombre: line.nombreUnidad, abreviatura: line.nombreUnidad }] : []),
      }
    }))
    setForm({
      idTipoDocumento: selected.header.idTipoDocumento,
      fecha,
      periodo: selected.header.periodo?.replace(/\D/g, "").slice(0, 6) || toPeriodo(fecha),
      idAlmacen: selected.header.idAlmacen,
      idAlmacenDestino: selected.header.idAlmacenDestino,
      referencia: selected.header.referencia,
      observacion: selected.header.observacion,
    })
    setLines(mappedLines)
    setEditingId(selected.header.id)
    setMessage(null)
    setEntryTab("detail")
    setActiveLineKey(null)
    setDirty(true)
    setView("form")
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    if (!form.idTipoDocumento) { setMessage("El tipo de documento es obligatorio."); return }
    if (!form.idAlmacen || !form.idAlmacenDestino) { setMessage("Debe seleccionar almacen origen y destino."); return }
    if (form.idAlmacen === form.idAlmacenDestino) { setMessage("El almacen origen debe ser diferente al destino."); return }
    const payload = {
      idTipoDocumento: form.idTipoDocumento,
      fecha: form.fecha,
      idAlmacen: form.idAlmacen,
      idAlmacenDestino: form.idAlmacenDestino,
      referencia: form.referencia,
      observacion: form.observacion,
      lineas: lines.filter((line) => line.idProducto && line.cantidad > 0).map((line, index) => ({ linea: index + 1, idProducto: line.idProducto, codigo: line.codigo, descripcion: line.descripcion, idUnidadMedida: line.idUnidadMedida, unidad: line.unidad, cantidad: line.cantidad, costo: line.costo })),
    }
    if (payload.lineas.length === 0) { setMessage("Debe agregar al menos una linea valida."); return }
    startTransition(async () => {
      try {
        const url = editingId ? apiUrl(`/api/inventory/transfers/${editingId}`) : apiUrl("/api/inventory/transfers")
        const res = await fetch(url, { method: editingId ? "PUT" : "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) })
        const result = await res.json() as { ok: boolean; data?: { header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }; message?: string }
        if (!res.ok || !result.ok || !result.data) throw new Error(result.message ?? "No se pudo guardar.")
        await loadDocuments(page, pageSize)
        setSelected(result.data)
        setDirty(false)
        setView("detail")
        setEditingId(null)
        toast.success(editingId ? "Transferencia actualizada" : "Transferencia creada")
      } catch (error) {
        setMessage(error instanceof Error ? error.message : "No se pudo guardar.")
      }
    })
  }

  async function runAction(action: "generate-exit" | "confirm-reception" | "void") {
    if (!selected) return
    startTransition(async () => {
      try {
        const url = action === "void" ? apiUrl(`/api/inventory/transfers/${selected.header.id}`) : apiUrl(`/api/inventory/transfers/${selected.header.id}/${action}`)
        const res = await fetch(url, { method: action === "void" ? "DELETE" : "POST", credentials: "include" })
        const result = await res.json() as { ok: boolean; data?: { header: InvTransferenciaRecord; lines: InvDocumentoDetalleRecord[] }; message?: string }
        if (!res.ok || !result.ok || !result.data) throw new Error(result.message ?? "No se pudo completar la accion.")
        setSelected(result.data)
        await loadDocuments(page, pageSize)
        toast.success(action === "generate-exit" ? "Salida generada" : action === "confirm-reception" ? "Recepcion confirmada" : "Transferencia anulada")
      } catch (error) {
        toast.error(error instanceof Error ? error.message : "No se pudo completar la accion.")
      }
    })
  }

  function printCurrentTransfer() {
    if (typeof window !== "undefined") {
      window.print()
    }
  }

  if (view === "list") {
    return (
      <section className="data-panel">
        <div className="inv-doc-screen">
          <header className="inv-doc-screen__header">
            <div className="inv-doc-screen__title">
              <FileText size={18} />
              <h2>{title}</h2>
            </div>
            {canEdit ? (
              <button type="button" className="primary-button" onClick={openNew}>
                <Plus size={14} /> Nuevo Documento
              </button>
            ) : null}
          </header>

          <div className="inv-doc-screen__filters">
            <div className="inv-doc-screen__filters-head">
              <h3><Filter size={14} /> Filtros</h3>
            </div>

            <div className="inv-doc-screen__filters-row">
              <div className="inv-doc-screen__filters-grid">
                <label className="inv-doc-screen__filters-date">
                  <span>Estado</span>
                  <select value={fEstado} onChange={(e) => setFEstado(e.target.value)}>
                    <option value="">Todos</option>
                    <option value="B">Borrador</option>
                    <option value="T">En Transito</option>
                    <option value="C">Completado</option>
                    <option value="N">Anulado</option>
                  </select>
                </label>
                <label className="inv-doc-screen__filters-date">
                  <span>Fecha Desde</span>
                  <input type="date" value={fFechaDesde} onChange={(e) => setFFechaDesde(e.target.value)} />
                </label>
                <label className="inv-doc-screen__filters-date">
                  <span>Fecha Hasta</span>
                  <input type="date" value={fFechaHasta} onChange={(e) => setFFechaHasta(e.target.value)} />
                </label>
                <label className="inv-doc-screen__filters-seq">
                  <span>Secuencia Desde</span>
                  <input type="number" lang="en-US" inputMode="numeric" min={1} step={1} value={fSecuenciaDesde} onChange={(e) => setFSecuenciaDesde(e.target.value)} placeholder="Ej. 100" />
                </label>
                <label className="inv-doc-screen__filters-seq">
                  <span>Secuencia Hasta</span>
                  <input type="number" lang="en-US" inputMode="numeric" min={1} step={1} value={fSecuenciaHasta} onChange={(e) => setFSecuenciaHasta(e.target.value)} placeholder="Ej. 500" />
                </label>
              </div>

              <div className="inv-doc-screen__filters-actions">
                <button type="button" className="primary-button" onClick={() => void loadDocuments(1, pageSize)} disabled={listLoading}>
                  <RefreshCw size={14} className={listLoading ? "spin" : ""} /> {listLoading ? "Cargando..." : "Actualizar"}
                </button>
                <button
                  type="button"
                  className="ghost-button"
                  onClick={() => {
                    setFSecuenciaDesde("")
                    setFSecuenciaHasta("")
                    setFFechaDesde("")
                    setFFechaHasta("")
                    setFEstado("")
                    void loadDocuments(1, pageSize, { secuenciaDesde: "", secuenciaHasta: "", fechaDesde: "", fechaHasta: "", estado: "" })
                  }}
                  disabled={listLoading}
                >
                  <X size={14} /> Limpiar
                </button>
              </div>
            </div>
          </div>

          {items.length === 0 ? (
            <div className="inv-doc-screen__empty">
              <FileText size={48} opacity={0.25} />
              <p>{listLoading ? "Cargando documentos..." : "No hay documentos para los filtros seleccionados"}</p>
            </div>
          ) : (
            <div className="inv-doc-screen__list-card">
              <div className="inv-doc-screen__list-head">
                <h3><FileText size={14} /> Transferencias</h3>
                <span>{totalRows} registros encontrados</span>
              </div>
              <div className="inv-doc-screen__table-wrap">
                <table className="inv-doc-screen__table">
                  <thead>
                    <tr>
                      <th>Numero</th>
                      <th>Fecha</th>
                      <th>Tipo</th>
                      <th>Origen</th>
                      <th>Destino</th>
                      <th>Referencia</th>
                      <th className="text-right">Total</th>
                      <th className="text-center">Estado</th>
                      <th className="text-center">Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {items.map((item) => (
                      <tr key={item.id} className={item.estadoTransferencia === "N" ? "is-voided" : ""}>
                        <td>
                          <button type="button" className="inv-doc-screen__link" onClick={() => void viewTransfer(item.id)}>
                            {item.numeroDocumento}
                          </button>
                        </td>
                        <td>{item.fecha.slice(0, 10)}</td>
                        <td>{item.nombreTipoDocumento}</td>
                        <td>{item.nombreAlmacen}</td>
                        <td>{item.nombreAlmacenDestino}</td>
                        <td>{item.referencia || "—"}</td>
                        <td className="text-right">{item.simboloMoneda} {formatNumber(item.totalDocumento, 2)}</td>
                        <td className="text-center">
                          <span className={stateClass(item.estadoTransferencia)}>{stateLabel(item.estadoTransferencia)}</span>
                        </td>
                        <td>
                          <div className="inv-doc-screen__row-actions">
                            <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--view" title="Visualizar" onClick={() => void viewTransfer(item.id)}>
                              <Eye size={14} />
                            </button>
                            {canEdit && item.estadoTransferencia === "B" ? (
                              <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--edit" title="Editar" onClick={() => void viewTransfer(item.id)}>
                                <Pencil size={14} />
                              </button>
                            ) : null}
                            {canPrint ? (
                              <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--print" title="Imprimir" onClick={() => void viewTransfer(item.id)}>
                                <Printer size={14} />
                              </button>
                            ) : null}
                            {canVoid && (item.estadoTransferencia === "B" || item.estadoTransferencia === "T") ? (
                              <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--void" title="Anular" onClick={() => void viewTransfer(item.id)}>
                                <Ban size={14} />
                              </button>
                            ) : null}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="inv-doc-screen__pagination">
                <div className="inv-doc-screen__pagination-info">
                  <label>
                    <span>Por página</span>
                    <select value={pageSize} onChange={(e) => void loadDocuments(1, Number(e.target.value))}>
                      <option value={10}>10</option>
                      <option value={20}>20</option>
                      <option value={50}>50</option>
                    </select>
                  </label>
                  <span>{items.length} de {totalRows}</span>
                </div>
                <div className="inv-doc-screen__pagination-actions">
                  <button type="button" className="secondary-button" onClick={() => void loadDocuments(1, pageSize)} disabled={listLoading || page <= 1}>«</button>
                  <button type="button" className="secondary-button" onClick={() => void loadDocuments(page - 1, pageSize)} disabled={listLoading || page <= 1}>‹</button>
                  <span>Pagina {page} de {totalPages}</span>
                  <button type="button" className="secondary-button" onClick={() => void loadDocuments(page + 1, pageSize)} disabled={listLoading || page >= totalPages}>›</button>
                  <button type="button" className="secondary-button" onClick={() => void loadDocuments(totalPages, pageSize)} disabled={listLoading || page >= totalPages}>»</button>
                </div>
              </div>
            </div>
          )}
        </div>
      </section>
    )
  }

  function cancelForm() {
    confirmAction(() => {
      setDirty(false)
      if (editingId && selected?.header.id === editingId) {
        setView("detail")
      } else {
        setView("list")
      }
    })
  }

  const monedaLabel = selectedDocType?.simboloMoneda || "Sin moneda"

  return (
    <>
      {view === "form" ? (
        <>
          <div className="inv-doc-detail-topbar">
            {editingId ? <span className="chip chip--neutral">Editando {docNumeroPreview}</span> : null}
            <div className="inv-doc-detail-topbar__actions">
              <button type="button" className="secondary-button" onClick={cancelForm}>
                <X size={14} /> Cancelar
              </button>
              <button type="button" className="primary-button" onClick={() => formRef.current?.requestSubmit()} disabled={isPending}>
                {isPending ? <Loader2 size={14} className="spin" /> : <Save size={14} />} Guardar
              </button>
            </div>
          </div>
          <section className="data-panel">
            <div className="inv-doc-screen">
              <form ref={formRef} onSubmit={onSubmit}>
                <div className="inv-doc-detail-header">
                  <div className="inv-doc-detail-header__row">
                    <label>
                      <span>Fecha *</span>
                      <input type="date" value={form.fecha} onChange={(e) => onFechaChange(e.target.value)} required />
                    </label>
                    <label>
                      <span>Periodo</span>
                      <input value={form.periodo} disabled />
                    </label>
                    <label>
                      <span>Documento</span>
                      <input value={docNumeroPreview} disabled />
                    </label>
                    <label>
                      <span>Moneda</span>
                      <input value={monedaLabel} disabled />
                    </label>
                  </div>
                  <div className="inv-doc-detail-header__row">
                    <label>
                      <span>Tipo Documento *</span>
                      <select
                        value={form.idTipoDocumento ?? ""}
                        onChange={(e) => setForm({ ...form, idTipoDocumento: e.target.value ? Number(e.target.value) : null })}
                        required
                      >
                        <option value="">Seleccionar...</option>
                        {docTypes.map((item) => (
                          <option key={item.id} value={item.id}>{item.description}</option>
                        ))}
                      </select>
                    </label>
                    <label>
                      <span>Almacen Origen *</span>
                      <select
                        value={form.idAlmacen ?? ""}
                        onChange={(e) => setForm({ ...form, idAlmacen: e.target.value ? Number(e.target.value) : null })}
                        required
                      >
                        <option value="">Seleccionar...</option>
                        {businessWarehouses.map((item) => (
                          <option key={item.id} value={item.id}>{item.description}</option>
                        ))}
                      </select>
                    </label>
                    <label>
                      <span>Almacen Destino *</span>
                      <select
                        value={form.idAlmacenDestino ?? ""}
                        onChange={(e) => setForm({ ...form, idAlmacenDestino: e.target.value ? Number(e.target.value) : null })}
                        required
                      >
                        <option value="">Seleccionar...</option>
                        {businessWarehouses.map((item) => (
                          <option key={item.id} value={item.id}>{item.description}</option>
                        ))}
                      </select>
                    </label>
                    <label>
                      <span>Referencia</span>
                      <input value={form.referencia} onChange={(e) => setForm({ ...form, referencia: e.target.value })} maxLength={250} placeholder="Referencia del documento" />
                    </label>
                  </div>
                </div>

                {!isHeaderReadyForDetail ? (
                  <div className="inv-doc-header-hint">
                    <span className="inv-doc-header-hint__dot" />
                    Completa los campos requeridos (<strong>*</strong>) para habilitar el detalle
                  </div>
                ) : null}

                <div className="inv-doc-grid">
                  <div className="inv-doc-grid__header">
                    <div className="inv-doc-grid__tabs">
                      <button type="button" className={entryTab === "detail" ? "filter-pill is-active" : "filter-pill"} onClick={() => setEntryTab("detail")}>
                        Detalle
                      </button>
                      <button type="button" className={entryTab === "notes" ? "filter-pill is-active" : "filter-pill"} onClick={() => setEntryTab("notes")}>
                        Comentarios / Observaciones
                      </button>
                    </div>
                    {entryTab === "detail" ? (
                      <button type="button" className="secondary-button" onClick={addLine} disabled={!isHeaderReadyForDetail} title={!isHeaderReadyForDetail ? detailLockedMessage : undefined}>
                        <Plus size={13} /> Linea
                      </button>
                    ) : null}
                  </div>

                  {entryTab === "detail" ? (
                    <div className="inv-doc-screen__table-wrap">
                      <table className="inv-doc-grid__table">
                        <thead>
                          <tr>
                            <th className="col-linea">#</th>
                            <th className="col-codigo">Codigo</th>
                            <th className="col-desc">Descripcion</th>
                            <th className="col-cant text-right">Existencia</th>
                            <th className="col-cant">Cantidad</th>
                            <th className="col-unidad">Unidad</th>
                            <th className="col-costo">Costo</th>
                            <th className="col-total">Total</th>
                            <th className="col-actions" />
                          </tr>
                        </thead>
                        <tbody>
                          {lines.map((line, idx) => (
                            <tr key={line.key} className={activeLineKey === line.key ? "is-active-row" : ""} onClick={() => setActiveLineKey(line.key)}>
                              <td className="text-center">{idx + 1}</td>
                              <td>
                                <div className="inv-doc-grid__code-cell">
                                  <input
                                    ref={(node) => { codeRefs.current[line.key] = node }}
                                    className={activeLineKey === line.key ? "inv-doc-grid__editable-hint" : undefined}
                                    value={line.codigo}
                                    disabled={!isHeaderReadyForDetail}
                                    onFocus={() => setActiveLineKey(line.key)}
                                    onChange={(e) => updateLine(line.key, (current) => ({ ...current, codigo: e.target.value }))}
                                    onBlur={() => void lookupProduct(line.key, line.codigo)}
                                    onKeyDown={(e) => {
                                      if (e.key === "Enter") {
                                        e.preventDefault()
                                        void lookupProduct(line.key, line.codigo)
                                      }
                                    }}
                                    placeholder="Codigo o scan"
                                  />
                                  <button type="button" className="inv-doc-grid__search-btn" title="Buscar producto" onClick={() => openSearch(line.key)} disabled={!isHeaderReadyForDetail}>
                                    <Search size={13} />
                                  </button>
                                </div>
                              </td>
                              <td><input value={line.descripcion} disabled className="inv-doc-grid__readonly" /></td>
                              <td className="text-right inv-doc-grid__total">{line.existenciaActual != null ? formatNumber(line.existenciaActual, 4) : ""}</td>
                              <td>
                                <input
                                  ref={(el) => { cantidadRefs.current[line.key] = el }}
                                  type="number"
                                  lang="en-US"
                                  inputMode="decimal"
                                  min={0}
                                  step="1"
                                  className={activeLineKey === line.key ? "text-right inv-doc-grid__editable-hint" : "text-right"}
                                  value={line.cantidad || ""}
                                  disabled={!isHeaderReadyForDetail}
                                  onFocus={() => setActiveLineKey(line.key)}
                                  onKeyDown={(e) => {
                                    if (e.key === "Enter" || e.key === "Tab") {
                                      e.preventDefault()
                                      // Si tiene unidades disponibles, ir al select; si no, ir a costo
                                      if (line.pideUnidadInventario && line.unidadesDisponibles.length > 1) {
                                        unitRefs.current[line.key]?.focus()
                                      } else {
                                        costInputRefs.current[line.key]?.focus()
                                        costInputRefs.current[line.key]?.select()
                                      }
                                    }
                                  }}
                                  onChange={(e) => updateLine(line.key, (current) => ({
                                    ...current,
                                    cantidad: Number(e.target.value),
                                    total: Number((Number(e.target.value) * current.costo).toFixed(4)),
                                  }))}
                                />
                              </td>
                              <td>
                                {line.pideUnidadInventario && line.unidadesDisponibles.length > 1 ? (
                                  <select
                                    ref={(el) => { unitRefs.current[line.key] = el }}
                                    className="inv-doc-grid__unit-select"
                                    value={line.idUnidadMedida ?? ""}
                                    disabled={!isHeaderReadyForDetail}
                                    onKeyDown={(e) => {
                                      if (e.key === "Enter" || e.key === "Tab") {
                                        e.preventDefault()
                                        costInputRefs.current[line.key]?.focus()
                                        costInputRefs.current[line.key]?.select()
                                      }
                                    }}
                                    onChange={(e) => {
                                      const u = line.unidadesDisponibles.find((item) => item.id === Number(e.target.value))
                                      if (!u) return
                                      const baseUnit = line.unidadesDisponibles.find((item) => item.id === line.idUnidadBase) ?? null
                                      updateLine(line.key, (current) => ({
                                        ...current,
                                        idUnidadMedida: u.id,
                                        unidad: u.abreviatura || u.nombre,
                                        existenciaActual: current.existenciaBase != null ? convertQuantityBetweenUnits(current.existenciaBase, baseUnit, u) : null,
                                        costo: current.costoBase != null ? convertCostFromBase(current.costoBase, baseUnit, u) : current.costo,
                                        total: Number((current.cantidad * (current.costoBase != null ? convertCostFromBase(current.costoBase, baseUnit, u) : current.costo)).toFixed(4)),
                                      }))
                                    }}
                                  >
                                    {line.unidadesDisponibles.map((u) => (
                                      <option key={u.id} value={u.id}>{u.nombre} ({u.abreviatura || u.nombre})</option>
                                    ))}
                                  </select>
                                ) : (
                                  <input value={line.unidad} disabled className="inv-doc-grid__readonly" />
                                )}
                              </td>
                              <td>
                                <input
                                  ref={(el) => { costInputRefs.current[line.key] = el }}
                                  type="number"
                                  lang="en-US"
                                  inputMode="decimal"
                                  min={0}
                                  step="1"
                                  className={activeLineKey === line.key ? "text-right inv-doc-grid__editable-hint" : "text-right"}
                                  value={line.costo || ""}
                                  disabled={!isHeaderReadyForDetail}
                                  onFocus={() => setActiveLineKey(line.key)}
                                  onKeyDown={(e) => {
                                    if (e.key === "Enter" || e.key === "Tab") {
                                      e.preventDefault()
                                      // Ir al código de la siguiente línea, o crear una nueva
                                      const currentIdx = lines.findIndex((l) => l.key === line.key)
                                      const nextLine = lines[currentIdx + 1]
                                      if (nextLine) {
                                        codeRefs.current[nextLine.key]?.focus()
                                        codeRefs.current[nextLine.key]?.select()
                                      } else {
                                        // Crear nueva línea y hacer focus
                                        const newLine = emptyLine()
                                        setLines((prev) => [...prev, newLine])
                                        setTimeout(() => codeRefs.current[newLine.key]?.focus(), 10)
                                      }
                                    }
                                  }}
                                  onChange={(e) => updateLine(line.key, (current) => ({
                                    ...current,
                                    costo: Number(e.target.value),
                                    total: Number((current.cantidad * Number(e.target.value)).toFixed(4)),
                                  }))}
                                />
                              </td>
                              <td className="text-right inv-doc-grid__total">{line.total > 0 ? formatNumber(line.total, 4) : ""}</td>
                              <td>
                                <button type="button" className="icon-button inv-doc-grid__remove-btn" onClick={() => removeLine(line.key)} title="Eliminar">
                                  <Trash2 size={13} />
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                        <tfoot>
                          <tr>
                            <td colSpan={7} className="text-right"><strong>Total Documento</strong></td>
                            <td colSpan={2} className="inv-doc-grid__footer-total"><strong>{monedaLabel} {formatNumber(total, 2)}</strong></td>
                          </tr>
                        </tfoot>
                      </table>
                    </div>
                  ) : (
                    <div className="inv-doc-notes">
                      <label>
                        <span>Observaciones del documento</span>
                        <textarea
                          value={form.observacion}
                          onChange={(e) => setForm({ ...form, observacion: e.target.value })}
                          maxLength={500}
                          placeholder="Comentarios u observaciones generales del movimiento..."
                        />
                      </label>
                    </div>
                  )}
                </div>
              </form>
            </div>
          </section>

          {searchOpen ? (
            <div className="inv-product-modal__backdrop" onClick={() => setSearchOpen(false)}>
              <div className="inv-product-modal" onClick={(e) => e.stopPropagation()}>
                <header className="inv-product-modal__header">
                  <h3>Buscar Producto</h3>
                  <button type="button" className="icon-button" onClick={() => setSearchOpen(false)}>
                    <X size={16} />
                  </button>
                </header>
                <div className="inv-product-modal__search">
                  <Search size={14} />
                  <input autoFocus value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} placeholder="Buscar por codigo o nombre..." />
                </div>
                <div className="inv-product-modal__list">
                  {searchLoading ? <div className="inv-product-modal__loading"><Loader2 size={18} className="spin" /></div> : null}
                  {!searchLoading && searchResults.length === 0 && searchQuery.trim() ? <p className="inv-product-modal__empty">Sin resultados</p> : null}
                  {searchResults.map((p) => (
                    <button key={p.id} type="button" className="inv-product-modal__item" onClick={() => selectProduct(p)}>
                      <div>
                        <strong>{p.codigo}</strong>
                        <span>{p.nombre}</span>
                      </div>
                      <div className="inv-product-modal__item-meta">
                        <span>{p.abreviaturaUnidad || p.nombreUnidad}</span>
                        <span>Costo: {formatNumber(p.costoPromedio, 4)}</span>
                        <span>Exist: {p.existencia}</span>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          ) : null}
        </>
      ) : null}

      {view === "detail" && selected != null ? (
        <>
          <div className="inv-doc-detail-topbar">
            <div className="inv-doc-detail-topbar__actions">
              {canPrint ? (
                <button type="button" className="secondary-button" onClick={printCurrentTransfer}>
                  <Printer size={14} /> Imprimir
                </button>
              ) : null}
              {canEdit && selected.header.estadoTransferencia === "B" ? (
                <button type="button" className="secondary-button" onClick={openEdit}>
                  <Pencil size={14} /> Editar
                </button>
              ) : null}
              {canGenerateExit && selected.header.estadoTransferencia === "B" ? (
                <button type="button" className="primary-button" disabled={isPending} onClick={() => void runAction("generate-exit")}>
                  {isPending ? <Loader2 size={14} className="spin" /> : <Send size={14} />} Generar Salida
                </button>
              ) : null}
              {canConfirmReception && selected.header.estadoTransferencia === "T" ? (
                <button type="button" className="primary-button" disabled={isPending} onClick={() => void runAction("confirm-reception")}>
                  {isPending ? <Loader2 size={14} className="spin" /> : <Undo2 size={14} />} Confirmar Recepcion
                </button>
              ) : null}
              {canVoid && (selected.header.estadoTransferencia === "B" || selected.header.estadoTransferencia === "T") ? (
                <button type="button" className="secondary-button" disabled={isPending} onClick={() => void runAction("void")}>
                  {isPending ? <Loader2 size={14} className="spin" /> : <Ban size={14} />} Anular
                </button>
              ) : null}
              <button type="button" className="secondary-button" onClick={() => setView("list")}>
                <X size={14} /> Cerrar
              </button>
            </div>
          </div>
          <section className="data-panel">
            <div className="inv-doc-screen">
              <div className="inv-transfer-detail">
                {detailSections.summary ? (
                  <section className="inv-transfer-section inv-transfer-section--summary">
                    <button
                      type="button"
                      className="inv-transfer-section__header"
                      onClick={() => setDetailSections((prev) => ({ ...prev, summary: !prev.summary }))}
                    >
                      <span className="inv-transfer-section__title"><FileText size={18} /> Resumen del documento</span>
                      <ChevronUp size={18} />
                    </button>
                    <div className="inv-transfer-section__body">
                      <div className="inv-transfer-summary-grid inv-transfer-summary-grid--top">
                        <label className="inv-transfer-summary-grid__compact"><span>Fecha</span><input value={selected.header.fecha.slice(0, 10)} disabled /></label>
                        <label className="inv-transfer-summary-grid__compact"><span>Periodo</span><input value={selected.header.periodo} disabled /></label>
                        <label className="inv-transfer-summary-grid__compact"><span>Documento</span><input value={selected.header.numeroDocumento} disabled /></label>
                        <label><span>Tipo Documento</span><input value={selected.header.nombreTipoDocumento} disabled /></label>
                        <label className="inv-transfer-summary-grid__status">
                          <span>Estado actual</span>
                          <div className="inv-transfer-summary-grid__status-pill">
                            <span className={stateClass(selected.header.estadoTransferencia)}>{stateLabel(selected.header.estadoTransferencia)}</span>
                          </div>
                        </label>
                      </div>
                      <div className="inv-transfer-summary-grid inv-transfer-summary-grid--bottom">
                        <label><span>Almacen Origen</span><input value={selected.header.nombreAlmacen} disabled /></label>
                        <label><span>Almacen Destino</span><input value={selected.header.nombreAlmacenDestino} disabled /></label>
                        <label className="inv-transfer-summary-grid__reference"><span>Referencia</span><input value={selected.header.referencia || "N/D"} disabled /></label>
                      </div>
                    </div>
                  </section>
                ) : (
                  <section className="inv-transfer-section inv-transfer-section--collapsed">
                    <button
                      type="button"
                      className="inv-transfer-section__header"
                      onClick={() => setDetailSections((prev) => ({ ...prev, summary: !prev.summary }))}
                    >
                      <span className="inv-transfer-section__title"><FileText size={18} /> Resumen del documento</span>
                      <ChevronDown size={18} />
                    </button>
                  </section>
                )}

                <section className={`inv-transfer-section inv-transfer-section--salida${selected.header.estadoTransferencia !== "B" ? " is-accent" : ""}`}>
                  <button
                    type="button"
                    className="inv-transfer-section__header"
                    onClick={() => setDetailSections((prev) => ({ ...prev, salida: !prev.salida }))}
                  >
                    <span className="inv-transfer-section__title"><ArrowRight size={18} /> Trazabilidad de salida</span>
                    {detailSections.salida ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                  </button>
                  {detailSections.salida ? (
                    <div className="inv-transfer-section__body">
                      <div className="inv-transfer-trace-grid">
                        <label><span>Doc. Salida</span><input value={selected.header.referenciaDocumentoSalida || "Pendiente"} disabled /></label>
                        <label><span>Doc. Ent. Transito</span><input value={selected.header.referenciaDocumentoTransitoEntrada || "Pendiente"} disabled /></label>
                        <label><span>Fecha Salida</span><input value={formatDateTimeLabel(selected.header.fechaSalida)} disabled /></label>
                        <label><span>Usuario Salida</span><input value={selected.header.usuarioSalida || "Pendiente"} disabled /></label>
                      </div>
                    </div>
                  ) : null}
                </section>

                <section className={`inv-transfer-section inv-transfer-section--recepcion${selected.header.estadoTransferencia === "C" ? " is-complete" : " is-pending"}`}>
                  <button
                    type="button"
                    className="inv-transfer-section__header"
                    onClick={() => setDetailSections((prev) => ({ ...prev, recepcion: !prev.recepcion }))}
                  >
                    <span className="inv-transfer-section__title"><Truck size={18} /> Trazabilidad de recepcion</span>
                    {detailSections.recepcion ? <ChevronUp size={18} /> : <ChevronDown size={18} />}
                  </button>
                  {detailSections.recepcion ? (
                    <div className="inv-transfer-section__body">
                      <div className="inv-transfer-trace-grid">
                        <label><span>Doc. Sal. Transito</span><input value={selected.header.referenciaDocumentoTransitoSalida || "Pendiente"} disabled /></label>
                        <label><span>Doc. Entrada</span><input value={selected.header.referenciaDocumentoEntrada || "Pendiente"} disabled /></label>
                        <label><span>Fecha Entrada</span><input value={formatDateTimeLabel(selected.header.fechaRecepcion)} disabled /></label>
                        <label><span>Usuario Entrada</span><input value={selected.header.usuarioRecepcion || "Pendiente"} disabled /></label>
                      </div>
                    </div>
                  ) : null}
                </section>
              </div>

              <div className="inv-doc-grid">
                <div className="inv-doc-grid__header">
                  <div className="inv-doc-grid__tabs">
                    <button type="button" className={detailTab === "detail" ? "filter-pill is-active" : "filter-pill"} onClick={() => setDetailTab("detail")}>
                      Detalle
                    </button>
                    <button type="button" className={detailTab === "notes" ? "filter-pill is-active" : "filter-pill"} onClick={() => setDetailTab("notes")}>
                      Comentarios / Observaciones
                    </button>
                  </div>
                </div>
                {detailTab === "detail" ? (
                  <div className="inv-doc-screen__table-wrap">
                    <table className="inv-doc-grid__table">
                      <thead>
                        <tr>
                          <th className="col-linea">#</th>
                          <th className="col-codigo">Codigo</th>
                          <th className="col-desc">Descripcion</th>
                          <th className="col-cant">Cantidad</th>
                          <th className="col-unidad">Unidad</th>
                          <th className="col-costo">Costo</th>
                          <th className="col-total">Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        {selected.lines.map((line) => (
                          <tr key={line.id}>
                            <td className="text-center">{line.numeroLinea}</td>
                            <td>{line.codigo}</td>
                            <td>{line.descripcion}</td>
                            <td className="text-right">{formatNumber(line.cantidad, 4)}</td>
                            <td>{line.nombreUnidad}</td>
                            <td className="text-right">{formatNumber(line.costo, 4)}</td>
                            <td className="text-right">{formatNumber(line.total, 4)}</td>
                          </tr>
                        ))}
                      </tbody>
                      <tfoot>
                        <tr>
                          <td colSpan={6} className="text-right"><strong>Total Documento</strong></td>
                          <td className="text-right"><strong>{selected.header.simboloMoneda} {formatNumber(selected.header.totalDocumento, 2)}</strong></td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>
                ) : (
                  <div className="inv-doc-notes">
                    <label>
                      <span>Observaciones del documento</span>
                      <textarea value={selected.header.observacion || ""} disabled rows={5} />
                    </label>
                  </div>
                )}
              </div>
            </div>
          </section>
        </>
      ) : null}
    </>
  )
}

