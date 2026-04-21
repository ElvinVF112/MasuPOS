"use client"

import { type FormEvent, useCallback, useEffect, useMemo, useRef, useState, useTransition } from "react"
import {
  Ban, ChevronDown, ChevronLeft, ChevronRight, ChevronUp, ChevronsLeft, ChevronsRight, Eye, FileText, Filter, Loader2, Pencil, Plus, Printer, RefreshCw, Save, Search, Trash2, X,
} from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { usePermissions } from "@/lib/permissions-context"
import { useFormat } from "@/lib/format-context"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import type {
  InvDocumentoRecord, InvDocumentoDetalleRecord, InvDocumentoDetalleHistoryRecord,
  InvDocumentosListResult,
  InvTipoDocumentoRecord, InvTipoOperacion, InvProductoParaDocumento, InvSupplierOption, UnidadOpcion,
  WarehouseRecord,
} from "@/lib/pos-data"

// ── Types ─────────────────────────────────────────────────────────

type LineaDetalle = {
  key: string
  idProducto: number | null
  codigo: string
  descripcion: string
  existenciaActual: number | null
  existenciaBase: number | null
  costoBase: number | null
  idUnidadBase: number | null
  unidad: string
  idUnidadMedida: number | null
  cantidad: number
  costo: number
  total: number
  pideUnidadInventario: boolean
  unidadesDisponibles: UnidadOpcion[]
}

type DocForm = {
  idTipoDocumento: number | null
  fecha: string
  periodo: string
  idAlmacen: number | null
  idMoneda: number | null
  simboloMoneda: string
  tasaCambio: number
  referencia: string
  observacion: string
  idProveedor: number | null
  noFactura: string
  ncf: string
  fechaFactura: string
}

type Props = {
  tipoOperacion: InvTipoOperacion
  title: string
  docTypes: InvTipoDocumentoRecord[]
  warehouses: WarehouseRecord[]
  suppliers?: InvSupplierOption[]
  initialList: InvDocumentosListResult
  initialFechaDesde?: string
  initialFechaHasta?: string
}

// ── Helpers ───────────────────────────────────────────────────────

function today() {
  return new Date().toISOString().slice(0, 10)
}

function toPeriodo(fecha: string) {
  return fecha.replace(/-/g, "").slice(0, 6)
}

function emptyLine(): LineaDetalle {
  return {
    key: crypto.randomUUID(),
    idProducto: null,
    codigo: "",
    descripcion: "",
    existenciaActual: null,
    existenciaBase: null,
    costoBase: null,
    idUnidadBase: null,
    unidad: "",
    idUnidadMedida: null,
    cantidad: 0,
    costo: 0,
    total: 0,
    pideUnidadInventario: false,
    unidadesDisponibles: [],
  }
}

function emptyForm(): DocForm {
  return {
    idTipoDocumento: null,
    fecha: today(),
    periodo: toPeriodo(today()),
    idAlmacen: null,
    idMoneda: null,
    simboloMoneda: "",
    tasaCambio: 1,
    referencia: "",
    observacion: "",
    idProveedor: null,
    noFactura: "",
    ncf: "",
    fechaFactura: "",
  }
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;")
}

function formatDocPreview(tipo?: InvTipoDocumentoRecord | null) {
  if (!tipo) return ""
  const nextSecuencia = Math.max((tipo.secuenciaActual ?? 0) + 1, tipo.secuenciaInicial || 1)
  const secuencia = String(nextSecuencia).padStart(4, "0")
  const prefijo = (tipo.prefijo || "").trim()
  return prefijo ? `${prefijo}-${secuencia}` : secuencia
}

function unitFactor(unit?: UnidadOpcion | null) {
  if (!unit) return 1
  const baseA = unit.baseA && unit.baseA > 0 ? unit.baseA : 1
  const baseB = unit.baseB && unit.baseB > 0 ? unit.baseB : 1
  return baseB / baseA
}

function convertQuantityBetweenUnits(quantity: number, fromUnit?: UnidadOpcion | null, toUnit?: UnidadOpcion | null) {
  const fromFactor = unitFactor(fromUnit)
  const toFactor = unitFactor(toUnit)
  if (!Number.isFinite(quantity) || toFactor === 0) return 0
  return Number(((quantity * fromFactor) / toFactor).toFixed(4))
}

function convertCostFromBase(costBase: number, baseUnit?: UnidadOpcion | null, selectedUnit?: UnidadOpcion | null) {
  const baseFactor = unitFactor(baseUnit)
  const selectedFactor = unitFactor(selectedUnit)
  if (!Number.isFinite(costBase) || baseFactor === 0) return 0
  return Number(((costBase * selectedFactor) / baseFactor).toFixed(4))
}

function toDateTimeText(value: string) {
  if (!value) return "-"
  const asDate = new Date(value)
  if (!Number.isNaN(asDate.getTime())) {
    const yyyy = asDate.getFullYear()
    const mm = String(asDate.getMonth() + 1).padStart(2, "0")
    const dd = String(asDate.getDate()).padStart(2, "0")
    const hh = String(asDate.getHours()).padStart(2, "0")
    const mi = String(asDate.getMinutes()).padStart(2, "0")
    const ss = String(asDate.getSeconds()).padStart(2, "0")
    return `${yyyy}-${mm}-${dd} ${hh}:${mi}:${ss}`
  }
  return value.slice(0, 19)
}

// ── Component ─────────────────────────────────────────────────────

export function InvDocumentScreen({ tipoOperacion, title, docTypes, warehouses, suppliers = [], initialList, initialFechaDesde = "", initialFechaHasta = "" }: Props) {
  const { formatNumber } = useFormat()
  const { hasPermission, isLoading: permissionsLoading, permissions } = usePermissions()
  const permissionPrefix = tipoOperacion === "E"
    ? "inventory.entries"
    : tipoOperacion === "S"
      ? "inventory.exits"
      : tipoOperacion === "C"
        ? "inventory.purchases"
        : "inventory.transfers"
  const isPurchase = tipoOperacion === "C"
  const supplierOptions = useMemo(() => suppliers.filter((item) => item.id > 0), [suppliers])
  const hasLegacyFallback = permissionsLoading || permissions.length === 0
  const canVisualize = hasLegacyFallback || hasPermission(`${permissionPrefix}.view`) || hasPermission("catalog.view")
  const canPrint = hasLegacyFallback || hasPermission(`${permissionPrefix}.print`) || canVisualize
  const canEdit =
    hasLegacyFallback ||
    hasPermission(`${permissionPrefix}.edit`) ||
    hasPermission("catalog.edit") ||
    hasPermission("catalog.view")
  const canVoid =
    hasLegacyFallback ||
    hasPermission(`${permissionPrefix}.void`) ||
    hasPermission(`${permissionPrefix}.delete`) ||
    hasPermission(`${permissionPrefix}.edit`) ||
    hasPermission("catalog.delete") ||
    hasPermission("catalog.edit") ||
    hasPermission("catalog.view")
  const canViewHistory = hasLegacyFallback || hasPermission("inventory.documents.history.view")

  // ── State: list view vs form view
  const [availableDocTypes, setAvailableDocTypes] = useState<InvTipoDocumentoRecord[]>(docTypes)
  const [view, setView] = useState<"list" | "new" | "detail">("list")
  const { setDirty, confirmAction } = useUnsavedGuard()
  const [documents, setDocuments] = useState<InvDocumentoRecord[]>(initialList.items)
  const [totalRows, setTotalRows] = useState(initialList.total)
  const [selectedDoc, setSelectedDoc] = useState<{ header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] } | null>(null)
  const [editingDoc, setEditingDoc] = useState<{ id: number; numero: string } | null>(null)
  const [listLoading, setListLoading] = useState(false)
  const [voidTarget, setVoidTarget] = useState<InvDocumentoRecord | null>(null)
  const [voidSubmitting, setVoidSubmitting] = useState(false)

  // ── State: list filters + pagination
  const [fSecuenciaDesde, setFSecuenciaDesde] = useState("")
  const [fSecuenciaHasta, setFSecuenciaHasta] = useState("")
  const [fFechaDesde, setFFechaDesde] = useState(initialFechaDesde)
  const [fFechaHasta, setFFechaHasta] = useState(initialFechaHasta)
  const [page, setPage] = useState(initialList.page)
  const [pageSize, setPageSize] = useState(initialList.pageSize)

  // ── State: new document form
  const [form, setForm] = useState<DocForm>(emptyForm())
  const [lines, setLines] = useState<LineaDetalle[]>([emptyLine()])
  const [activeLineKey, setActiveLineKey] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()
  const [saveConfirmOpen, setSaveConfirmOpen] = useState(false)
  const [message, setMessage] = useState<string | null>(null)
  const [entryTab, setEntryTab] = useState<"detail" | "notes">("detail")
  const [detailTab, setDetailTab] = useState<"detail" | "history">("detail")
  const [historyRows, setHistoryRows] = useState<InvDocumentoDetalleHistoryRecord[]>([])
  const [historyDocId, setHistoryDocId] = useState<number | null>(null)
  const [historyLoading, setHistoryLoading] = useState(false)

  // ── State: product search modal
  const [searchOpen, setSearchOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")
  const [searchResults, setSearchResults] = useState<InvProductoParaDocumento[]>([])
  const [searchLoading, setSearchLoading] = useState(false)
  const [searchTargetLineKey, setSearchTargetLineKey] = useState<string | null>(null)

  // ── State: list sort
  const [sortField, setSortField] = useState<"fecha" | "numero" | "total">("fecha")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("desc")

  const codeInputRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const costInputRefs = useRef<Record<string, HTMLInputElement | null>>({})
  const formRef = useRef<HTMLFormElement | null>(null)

  // ── Derived
  const totalDoc = useMemo(() => lines.reduce((s, l) => s + l.total, 0), [lines])
  const isHeaderReadyForDetail = Boolean(form.fecha && form.idTipoDocumento && form.idAlmacen)
  const detailLockedMessage = "Complete Fecha, Tipo Documento y Almacen para habilitar el detalle."
  const selectedDocType = useMemo(
    () => availableDocTypes.find((item) => item.id === form.idTipoDocumento) ?? null,
    [availableDocTypes, form.idTipoDocumento],
  )

  const sortedDocs = useMemo(() => {
    const sorted = [...documents]
    sorted.sort((a, b) => {
      let cmp = 0
      if (sortField === "fecha") cmp = a.fecha.localeCompare(b.fecha)
      else if (sortField === "numero") cmp = a.numeroDocumento.localeCompare(b.numeroDocumento)
      else if (sortField === "total") cmp = a.totalDocumento - b.totalDocumento
      return sortDir === "desc" ? -cmp : cmp
    })
    return sorted
  }, [documents, sortField, sortDir])

  const totalPages = useMemo(() => Math.max(1, Math.ceil(totalRows / pageSize)), [totalRows, pageSize])
  const selectedDocIndex = useMemo(() => {
    const currentId = selectedDoc?.header.id
    if (!currentId) return -1
    return sortedDocs.findIndex((doc) => doc.id === currentId)
  }, [selectedDoc?.header.id, sortedDocs])

  function syncTipoSecuencia(tipoId: number, nuevaSecuencia: number) {
    setAvailableDocTypes((prev) => prev.map((item) => (
      item.id === tipoId
        ? { ...item, secuenciaActual: Math.max(item.secuenciaActual, nuevaSecuencia) }
        : item
    )))
  }

  async function loadDocumentHistory(id: number) {
    if (!canViewHistory) return
    if (historyDocId === id && historyRows.length > 0) return

    setHistoryLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/inventory/documents/${id}/history`), {
        credentials: "include",
        cache: "no-store",
      })
      const result = (await res.json()) as {
        ok: boolean
        data?: InvDocumentoDetalleHistoryRecord[]
        message?: string
      }
      if (!res.ok || !result.ok) {
        toast.error(result.message ?? "No se pudo cargar el historico.")
        return
      }
      setHistoryRows(result.data ?? [])
      setHistoryDocId(id)
    } catch {
      toast.error("Error al cargar historico de cambios.")
    } finally {
      setHistoryLoading(false)
    }
  }

  async function loadDocuments(
    nextPage = page,
    nextPageSize = pageSize,
    override?: { secuenciaDesde?: string; secuenciaHasta?: string; fechaDesde?: string; fechaHasta?: string },
  ) {
    setListLoading(true)
    try {
      const secuenciaDesde = override?.secuenciaDesde ?? fSecuenciaDesde
      const secuenciaHasta = override?.secuenciaHasta ?? fSecuenciaHasta
      const fechaDesde = override?.fechaDesde ?? fFechaDesde
      const fechaHasta = override?.fechaHasta ?? fFechaHasta
      const params = new URLSearchParams()
      params.set("tipo", tipoOperacion)
      params.set("page", String(nextPage))
      params.set("pageSize", String(nextPageSize))
      if (fechaDesde) params.set("desde", fechaDesde)
      if (fechaHasta) params.set("hasta", fechaHasta)
      if (secuenciaDesde) params.set("secDesde", secuenciaDesde)
      if (secuenciaHasta) params.set("secHasta", secuenciaHasta)

      const res = await fetch(apiUrl(`/api/inventory/documents?${params.toString()}`), {
        credentials: "include",
        cache: "no-store",
      })
      const result = (await res.json()) as {
        ok: boolean
        data?: { items: InvDocumentoRecord[]; total: number; page: number; pageSize: number }
        message?: string
      }
      if (!res.ok || !result.ok || !result.data) {
        toast.error(result.message ?? "No se pudo cargar el listado.")
        return
      }
      setDocuments(result.data.items)
      setTotalRows(result.data.total)
      setPage(result.data.page)
      setPageSize(result.data.pageSize)
    } catch {
      toast.error("Error al cargar documentos.")
    } finally {
      setListLoading(false)
    }
  }

  // ── Handlers: form field changes
  function onTipoDocumentoChange(idTipoDoc: number) {
    const tipo = availableDocTypes.find(t => t.id === idTipoDoc)
    setForm(prev => ({
      ...prev,
      idTipoDocumento: idTipoDoc,
      idMoneda: tipo?.idMoneda ?? null,
      simboloMoneda: tipo?.simboloMoneda ?? "",
    }))
  }

  function onFechaChange(fecha: string) {
    setForm(prev => ({ ...prev, fecha, periodo: toPeriodo(fecha) }))
  }

  // ── Handlers: lines
  function updateLine(key: string, patch: Partial<LineaDetalle>) {
    setLines(prev => prev.map(l => {
      if (l.key !== key) return l
      const updated = { ...l, ...patch }
      updated.total = Math.round(updated.cantidad * updated.costo * 10000) / 10000
      return updated
    }))
  }

  function removeLine(key: string) {
    setLines(prev => {
      const next = prev.filter(l => l.key !== key)
      if (activeLineKey === key) {
        setActiveLineKey(next[0]?.key ?? null)
      }
      return next.length > 0 ? next : [emptyLine()]
    })
  }

  function addEmptyLine() {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    const newLine = emptyLine()
    setLines(prev => [...prev, newLine])
    setActiveLineKey(newLine.key)
    setTimeout(() => codeInputRefs.current[newLine.key]?.focus(), 50)
  }

  // ── Handlers: code lookup (Enter/Tab on code field)
  async function lookupCode(lineKey: string, code: string) {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    if (!code.trim()) return
    try {
      const almParam = form.idAlmacen ? `&almacen=${form.idAlmacen}` : ""
      const res = await fetch(apiUrl(`/api/inventory/products/by-code?code=${encodeURIComponent(code.trim())}${almParam}`), { credentials: "include" })
      const result = (await res.json()) as { ok: boolean; data?: InvProductoParaDocumento; message?: string }
      if (!result.ok || !result.data) {
        toast.error(result.message ?? "Producto no encontrado.")
        return
      }
      const p = result.data
      const baseUnit = p.unidades.find((item) => item.id === p.idUnidadBase) ?? null
      const selectedUnit = p.unidades.find((item) => item.id === p.idUnidadVenta) ?? p.unidades.find((item) => item.id === p.idUnidadMedida) ?? null
      const selectedUnitId = selectedUnit?.id ?? p.idUnidadMedida
      updateLine(lineKey, {
        idProducto: p.id,
        codigo: p.codigo,
        descripcion: p.nombre,
        existenciaActual: convertQuantityBetweenUnits(p.existencia, baseUnit, selectedUnit),
        existenciaBase: p.existencia,
        costoBase: p.costoPromedio,
        idUnidadBase: p.idUnidadBase,
        unidad: selectedUnit?.abreviatura || selectedUnit?.nombre || p.abreviaturaUnidad || p.nombreUnidad,
        idUnidadMedida: selectedUnitId,
        costo: convertCostFromBase(p.costoPromedio, baseUnit, selectedUnit),
        cantidad: 1,
        pideUnidadInventario: p.pideUnidadInventario,
        unidadesDisponibles: p.unidades,
      })
      // Auto add new empty line if this was the last
      setLines(prev => {
        const idx = prev.findIndex(l => l.key === lineKey)
        if (idx === prev.length - 1) return [...prev, emptyLine()]
        return prev
      })
    } catch {
      toast.error("Error al buscar producto.")
    }
  }

  // ── Handlers: product search modal
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

  async function doSearch(q: string) {
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
  }

  function selectProduct(product: InvProductoParaDocumento) {
    if (!isHeaderReadyForDetail) {
      toast.warning(detailLockedMessage)
      return
    }
    if (!searchTargetLineKey) return
    const baseUnit = product.unidades.find((item) => item.id === product.idUnidadBase) ?? null
    const selectedUnit = product.unidades.find((item) => item.id === product.idUnidadVenta) ?? product.unidades.find((item) => item.id === product.idUnidadMedida) ?? null
    const selectedUnitId = selectedUnit?.id ?? product.idUnidadMedida
    updateLine(searchTargetLineKey, {
      idProducto: product.id,
      codigo: product.codigo,
      descripcion: product.nombre,
      existenciaActual: convertQuantityBetweenUnits(product.existencia, baseUnit, selectedUnit),
      existenciaBase: product.existencia,
      costoBase: product.costoPromedio,
      idUnidadBase: product.idUnidadBase,
      unidad: selectedUnit?.abreviatura || selectedUnit?.nombre || product.abreviaturaUnidad || product.nombreUnidad,
      idUnidadMedida: selectedUnitId,
      costo: convertCostFromBase(product.costoPromedio, baseUnit, selectedUnit),
      cantidad: 1,
      pideUnidadInventario: product.pideUnidadInventario,
      unidadesDisponibles: product.unidades,
    })
    setSearchOpen(false)
    // Auto add new empty line if this was the last
    setLines(prev => {
      const idx = prev.findIndex(l => l.key === searchTargetLineKey)
      if (idx === prev.length - 1) return [...prev, emptyLine()]
      return prev
    })
  }

  // ── Handlers: submit document
  function buildSavePayload() {
    setMessage(null)
    if (!form.idTipoDocumento) { setMessage("Seleccione un tipo de documento."); return }
    if (!form.idAlmacen) { setMessage("Seleccione un almacen."); return }

    const productIdByCode = new Map<string, number>()
    if (editingDoc && selectedDoc?.lines) {
      for (const row of selectedDoc.lines) {
        const key = row.codigo.trim().toLowerCase()
        if (key) productIdByCode.set(key, row.idProducto)
      }
    }

    const normalizedLines = lines.map((l) => {
      if (l.idProducto && l.idProducto > 0) return l
      const key = l.codigo.trim().toLowerCase()
      const inferredId = key ? (productIdByCode.get(key) ?? null) : null
      return { ...l, idProducto: inferredId }
    })

    const validLines = normalizedLines.filter(l => l.idProducto && l.cantidad > 0)
    if (validLines.length === 0) { setMessage("Agregue al menos una linea con producto y cantidad."); return }

    return {
      idTipoDocumento: form.idTipoDocumento,
      fecha: form.fecha,
      idAlmacen: form.idAlmacen,
      idMoneda: form.idMoneda,
      tasaCambio: form.tasaCambio,
      referencia: form.referencia || null,
      observacion: form.observacion || null,
      idProveedor: isPurchase ? form.idProveedor : null,
      noFactura: isPurchase ? (form.noFactura.trim() || null) : null,
      ncf: isPurchase ? (form.ncf.trim() || null) : null,
      fechaFactura: isPurchase ? (form.fechaFactura || null) : null,
      lineas: validLines.map((l, idx) => ({
        linea: idx + 1,
        idProducto: l.idProducto,
        codigo: l.codigo,
        descripcion: l.descripcion,
        idUnidadMedida: l.idUnidadMedida,
        unidad: l.unidad,
        cantidad: l.cantidad,
        costo: l.costo,
      })),
    }
  }

  function onSubmit(e: FormEvent) {
    e.preventDefault()
    const payload = buildSavePayload()
    if (!payload) return
    setSaveConfirmOpen(true)
  }

  function confirmSaveDocument() {
    const payload = buildSavePayload()
    if (!payload) {
      setSaveConfirmOpen(false)
      return
    }

    setSaveConfirmOpen(false)
    startTransition(async () => {
      try {
        const isEditing = Boolean(editingDoc)
        const endpoint = isEditing ? apiUrl(`/api/inventory/documents/${editingDoc?.id}`) : apiUrl("/api/inventory/documents")
        const res = await fetch(endpoint, {
          method: isEditing ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        })
        const result = (await res.json()) as {
          ok: boolean
          message?: string
          data?: { header: InvDocumentoRecord; lines?: InvDocumentoDetalleRecord[] }
        }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar el documento."); return }
        if (isEditing) {
          toast.success(`Documento ${result.data?.header.numeroDocumento} actualizado`)
          const updated = await fetchDocumentDetail(editingDoc!.id)
          if (updated) {
            setSelectedDoc(updated)
            setDetailTab("detail")
            setHistoryRows([])
            setHistoryDocId(null)
            setDirty(false)
            setView("detail")
          } else {
            setDirty(false)
            setView("list")
          }
          setEditingDoc(null)
          await loadDocuments(page, pageSize)
        } else {
          if (result.data?.header?.idTipoDocumento) {
            syncTipoSecuencia(result.data.header.idTipoDocumento, result.data.header.secuencia)
          }
          toast.success(`Documento ${result.data?.header.numeroDocumento} creado`)
          resetForm()
          setDirty(false)
          setView("list")
          await loadDocuments(1, pageSize)
        }
      } catch {
        setMessage("Error al guardar el documento.")
      }
    })
  }

  function resetForm() {
    setForm(emptyForm())
    const line = emptyLine()
    setLines([line])
    setActiveLineKey(line.key)
    setEditingDoc(null)
    setMessage(null)
    setEntryTab("detail")
    setDetailTab("detail")
  }

  async function getProductoDocumentoByCode(code: string, idAlmacen: number | null): Promise<InvProductoParaDocumento | null> {
    const normalizedCode = code.trim()
    if (!normalizedCode) return null
    try {
      const almParam = idAlmacen ? `&almacen=${idAlmacen}` : ""
      const res = await fetch(
        apiUrl(`/api/inventory/products/by-code?code=${encodeURIComponent(normalizedCode)}${almParam}`),
        { credentials: "include" },
      )
      const result = (await res.json()) as { ok: boolean; data?: InvProductoParaDocumento }
      if (!res.ok || !result.ok || !result.data) return null
      return result.data
    } catch {
      return null
    }
  }

  async function loadFormFromDocument(data: { header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] }) {
    setForm({
      idTipoDocumento: data.header.idTipoDocumento,
      fecha: data.header.fecha,
      periodo: data.header.periodo,
      idAlmacen: data.header.idAlmacen,
      idMoneda: data.header.idMoneda,
      simboloMoneda: data.header.simboloMoneda,
      tasaCambio: data.header.tasaCambio,
      referencia: data.header.referencia,
      observacion: data.header.observacion,
      idProveedor: data.header.idProveedor,
      noFactura: data.header.noFactura,
      ncf: data.header.ncf,
      fechaFactura: data.header.fechaFactura,
    })

    const mappedLines: LineaDetalle[] = await Promise.all(data.lines.map(async (line) => {
      const product = await getProductoDocumentoByCode(line.codigo, data.header.idAlmacen)
      const isSameProduct = product?.id === line.idProducto
      const resolvedProduct = isSameProduct ? product : null
      const resolvedUnitId = line.idUnidadMedida ?? resolvedProduct?.idUnidadMedida ?? null
      const resolvedUnits = resolvedProduct?.unidades ?? []
      const selectedUnit = resolvedUnits.find((unit) => unit.id === resolvedUnitId)
      const baseUnit = resolvedUnits.find((unit) => unit.id === resolvedProduct?.idUnidadBase)

      return {
        key: String(crypto.randomUUID()),
        idProducto: line.idProducto,
        codigo: line.codigo,
        descripcion: line.descripcion,
        existenciaActual: resolvedProduct ? convertQuantityBetweenUnits(resolvedProduct.existencia, baseUnit, selectedUnit) : null,
        existenciaBase: resolvedProduct?.existencia ?? null,
        costoBase: resolvedProduct?.costoPromedio ?? (line.cantidad > 0 ? Number((line.total / line.cantidad).toFixed(4)) : line.costo),
        idUnidadBase: resolvedProduct?.idUnidadBase ?? null,
        unidad: selectedUnit ? (selectedUnit.abreviatura || selectedUnit.nombre) : line.nombreUnidad,
        idUnidadMedida: resolvedUnitId,
        cantidad: line.cantidad,
        costo: line.costo,
        total: line.total,
        pideUnidadInventario: Boolean(resolvedProduct?.pideUnidadInventario),
        unidadesDisponibles: resolvedUnits,
      }
    }))

    const nextLines = mappedLines.length > 0 ? [...mappedLines, emptyLine()] : [emptyLine()]
    setLines(nextLines)
    setActiveLineKey(nextLines[0]?.key ?? null)
    setEntryTab("detail")
    setDetailTab("detail")
    setMessage(null)
  }

  async function fetchDocumentDetail(id: number) {
    const res = await fetch(apiUrl(`/api/inventory/documents/${id}`), { credentials: "include" })
    const result = (await res.json()) as { ok: boolean; data?: { header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] } }
    return result.ok && result.data ? result.data : null
  }

  // ── Handlers: view document detail
  async function viewDocument(doc: InvDocumentoRecord) {
    if (!canVisualize) return
    try {
      const detail = await fetchDocumentDetail(doc.id)
      if (detail) {
        setSelectedDoc(detail)
        setDetailTab("detail")
        setHistoryRows([])
        setHistoryDocId(null)
        setView("detail")
      }
    } catch {
      toast.error("Error al cargar documento.")
    }
  }

  async function printDocument(doc: InvDocumentoRecord) {
    if (!canPrint) return
    try {
      const detail = await fetchDocumentDetail(doc.id)
      if (!detail) {
        toast.error("No se pudo cargar el documento para imprimir.")
        return
      }

      const printWindow = window.open("", "_blank", "noopener,noreferrer,width=900,height=700")
      if (!printWindow) {
        toast.error("Permite pop-ups para imprimir el documento.")
        return
      }

      const header = detail.header
      const rows = detail.lines
        .map((line) => `
          <tr>
            <td>${line.numeroLinea}</td>
            <td>${escapeHtml(line.codigo)}</td>
            <td>${escapeHtml(line.descripcion)}</td>
            <td style="text-align:right">${formatNumber(line.cantidad, 2)}</td>
            <td>${escapeHtml(line.nombreUnidad)}</td>
            <td style="text-align:right">${formatNumber(line.costo, 4)}</td>
            <td style="text-align:right">${formatNumber(line.total, 4)}</td>
          </tr>`)
        .join("")

      printWindow.document.write(`<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Imprimir ${escapeHtml(header.numeroDocumento)}</title>
  <style>
    body{font-family:Segoe UI,Arial,sans-serif;padding:20px;color:#0f172a}
    h1{font-size:18px;margin:0 0 8px}
    .meta{font-size:12px;color:#475569;margin:0 0 16px}
    table{width:100%;border-collapse:collapse;font-size:12px}
    th,td{border:1px solid #cbd5e1;padding:6px}
    th{background:#f1f5f9;text-align:left}
    tfoot td{font-weight:700}
  </style>
</head>
<body>
  <h1>${escapeHtml(header.numeroDocumento)}</h1>
  <p class="meta">Fecha: ${escapeHtml(header.fecha.slice(0, 10))} · Tipo: ${escapeHtml(header.nombreTipoDocumento)} · Almacen: ${escapeHtml(header.nombreAlmacen)}</p>
  <table>
    <thead>
      <tr><th>#</th><th>Codigo</th><th>Descripcion</th><th>Cantidad</th><th>Unidad</th><th>Costo</th><th>Total</th></tr>
    </thead>
    <tbody>${rows}</tbody>
    <tfoot><tr><td colspan="6" style="text-align:right">Total</td><td style="text-align:right">${escapeHtml(header.simboloMoneda)} ${formatNumber(header.totalDocumento, 2)}</td></tr></tfoot>
  </table>
</body>
</html>`)
      printWindow.document.close()
      printWindow.focus()
      printWindow.print()
    } catch {
      toast.error("Error al imprimir documento.")
    }
  }

  function navigateDetail(direction: -1 | 1) {
    if (!selectedDoc) return
    const idx = sortedDocs.findIndex((doc) => doc.id === selectedDoc.header.id)
    if (idx < 0) return
    const target = sortedDocs[idx + direction]
    if (!target) return
    void viewDocument(target)
  }

  function navigateToIndex(index: number) {
    const target = sortedDocs[index]
    if (!target) return
    void viewDocument(target)
  }

  // ── Handlers: void document
  async function voidDocument(id: number) {
    setVoidSubmitting(true)
    try {
      const res = await fetch(apiUrl(`/api/inventory/documents/${id}`), { method: "DELETE", credentials: "include" })
      const result = (await res.json()) as { ok: boolean; data?: { header: InvDocumentoRecord }; message?: string }
      if (!result.ok) { toast.error(result.message ?? "No se pudo anular."); return }
      toast.success("Documento anulado")
      await loadDocuments(page, pageSize)
      if (selectedDoc?.header.id === id) {
        setSelectedDoc(null)
        setView("list")
      }
      setVoidTarget(null)
    } catch {
      toast.error("Error al anular documento.")
    } finally {
      setVoidSubmitting(false)
    }
  }

  function requestVoid(doc: InvDocumentoRecord) {
    if (!canVoid || doc.estado !== "A") return
    setVoidTarget(doc)
  }

  function requestEdit(doc: InvDocumentoRecord) {
    if (!canEdit || doc.estado !== "A") return
    setMessage(null)
    const openEditor = async (data: { header: InvDocumentoRecord; lines: InvDocumentoDetalleRecord[] }) => {
      await loadFormFromDocument(data)
      setEditingDoc({ id: data.header.id, numero: data.header.numeroDocumento })
      setDirty(true)
      setView("new")
    }

    if (selectedDoc && selectedDoc.header.id === doc.id) {
      void openEditor(selectedDoc)
      return
    }

    void fetchDocumentDetail(doc.id)
      .then((data) => {
        if (!data) {
          toast.error("No se pudo cargar el documento para editar.")
          return
        }
        setSelectedDoc(data)
        void openEditor(data)
      })
      .catch(() => {
        toast.error("No se pudo cargar el documento para editar.")
      })
  }

  // ── Sort handler
  function toggleSort(field: typeof sortField) {
    if (sortField === field) setSortDir(d => d === "asc" ? "desc" : "asc")
    else { setSortField(field); setSortDir("desc") }
  }

  const SortIcon = ({ field }: { field: typeof sortField }) => {
    if (sortField !== field) return null
    return sortDir === "desc" ? <ChevronDown size={12} /> : <ChevronUp size={12} />
  }

  const voidConfirmModal = voidTarget ? (
    <div className="modal-backdrop" onClick={() => !voidSubmitting && setVoidTarget(null)}>
      <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
        <div className="modal-card__header modal-card__header--brand">
          <div className="modal-card__header-icon"><Ban size={20} /></div>
          <div>
            <h3 className="modal-card__title">Confirmar anulación</h3>
            <p className="modal-card__subtitle">{voidTarget.numeroDocumento}</p>
          </div>
        </div>
        <div className="modal-card__body">
          <p>¿Seguro que deseas anular este documento? Esta acción reversará el movimiento de stock.</p>
        </div>
        <div className="modal-card__footer">
          <button type="button" className="secondary-button" onClick={() => setVoidTarget(null)} disabled={voidSubmitting}>
            Cancelar
          </button>
          <button type="button" className="danger-button" onClick={() => void voidDocument(voidTarget.id)} disabled={voidSubmitting}>
            <Ban size={15} /> {voidSubmitting ? "Anulando..." : "Sí, anular"}
          </button>
        </div>
      </div>
    </div>
  ) : null

  // ── Search with debounce
  useEffect(() => {
    if (!searchOpen) return
    const timer = setTimeout(() => { void doSearch(searchQuery) }, 300)
    return () => clearTimeout(timer)
  }, [searchQuery, searchOpen])

  useEffect(() => {
    if (view !== "new") return
    if (activeLineKey || lines.length === 0) return
    setActiveLineKey(lines[0].key)
  }, [activeLineKey, lines, view])

  // ── Render: List view ──────────────────────────────────────────
  if (view === "list") {
    return (
      <>
      <section className="data-panel">
        <div className="inv-doc-screen">
          <header className="inv-doc-screen__header">
            <div className="inv-doc-screen__title">
              <FileText size={18} />
              <h2>{title}</h2>
            </div>
            <button type="button" className="primary-button" onClick={() => { resetForm(); setDirty(true); setView("new") }}>
              <Plus size={14} /> Nuevo Documento
            </button>
          </header>

          <div className="inv-doc-screen__filters">
            <div className="inv-doc-screen__filters-head">
              <h3><Filter size={14} /> Filtros</h3>
            </div>

            <div className="inv-doc-screen__filters-row">
              <div className="inv-doc-screen__filters-grid">
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

              <div className="inv-doc-screen__filters-actions inv-doc-screen__filters-actions--bottom">
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
                    void loadDocuments(1, pageSize, { secuenciaDesde: "", secuenciaHasta: "", fechaDesde: "", fechaHasta: "" })
                  }}
                  disabled={listLoading}
                >
                  <X size={14} /> Limpiar
                </button>
              </div>
            </div>
          </div>

          {documents.length === 0 ? (
            <div className="inv-doc-screen__empty">
              <FileText size={48} opacity={0.25} />
              <p>{listLoading ? "Cargando documentos..." : "No hay documentos para los filtros seleccionados"}</p>
            </div>
          ) : (
            <div className="inv-doc-screen__list-card">
              <div className="inv-doc-screen__list-head">
                <h3><FileText size={14} /> Documentos</h3>
                <span>{totalRows} registros encontrados</span>
              </div>
            <div className="inv-doc-screen__table-wrap">
              <table className="inv-doc-screen__table">
                <thead>
                  <tr>
                    <th onClick={() => toggleSort("numero")}>Documento <SortIcon field="numero" /></th>
                    <th onClick={() => toggleSort("fecha")}>Fecha <SortIcon field="fecha" /></th>
                    <th>Tipo</th>
                    <th>Almacen</th>
                    <th>Referencia</th>
                    {isPurchase ? <th>Proveedor</th> : null}
                    {isPurchase ? <th>NCF</th> : null}
                    <th onClick={() => toggleSort("total")} className="text-right">Total <SortIcon field="total" /></th>
                    <th className="text-center">Estado</th>
                     <th className="text-center">Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  {sortedDocs.map(doc => (
                    <tr key={doc.id} className={doc.estado === "N" ? "is-voided" : ""}>
                      <td>
                        <span className="inv-doc-screen__link">
                          {doc.numeroDocumento}
                        </span>
                      </td>
                      <td>{doc.fecha.slice(0, 10)}</td>
                      <td>{doc.nombreTipoDocumento}</td>
                      <td>{doc.nombreAlmacen}</td>
                      <td>{doc.referencia || "—"}</td>
                      {isPurchase ? <td>{doc.nombreProveedor || "—"}</td> : null}
                      {isPurchase ? <td>{doc.ncf || "—"}</td> : null}
                      <td className="text-right">{doc.simboloMoneda} {formatNumber(doc.totalDocumento, 2)}</td>
                      <td className="text-center">
                        <span className={doc.estado === "A" ? "chip chip--success" : "chip chip--danger"}>
                          {doc.estado === "A" ? "Activo" : "Anulado"}
                        </span>
                      </td>
                      <td>
                        <div className="inv-doc-screen__row-actions">
                          {canVisualize ? (
                            <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--view" title="Visualizar" onClick={() => void viewDocument(doc)}>
                              <Eye size={14} />
                            </button>
                          ) : null}
                          {canEdit && doc.estado === "A" ? (
                            <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--edit" title="Editar" onClick={() => requestEdit(doc)}>
                              <Pencil size={14} />
                            </button>
                          ) : null}
                          {canPrint ? (
                            <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--print" title="Imprimir" onClick={() => void printDocument(doc)}>
                              <Printer size={14} />
                            </button>
                          ) : null}
                          {canVoid && doc.estado === "A" ? (
                            <button type="button" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--void" title="Anular" onClick={() => requestVoid(doc)}>
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
                <span>{documents.length} de {totalRows}</span>
              </div>
              <div className="inv-doc-screen__pagination-actions">
                <button type="button" className="secondary-button" onClick={() => void loadDocuments(1, pageSize)} disabled={listLoading || page <= 1}>
                  «
                </button>
                <button type="button" className="secondary-button" onClick={() => void loadDocuments(page - 1, pageSize)} disabled={listLoading || page <= 1}>
                  ‹
                </button>
                <span>Pagina {page} de {totalPages}</span>
                <button type="button" className="secondary-button" onClick={() => void loadDocuments(page + 1, pageSize)} disabled={listLoading || page >= totalPages}>
                  ›
                </button>
                <button type="button" className="secondary-button" onClick={() => void loadDocuments(totalPages, pageSize)} disabled={listLoading || page >= totalPages}>
                  »
                </button>
              </div>
            </div>
            </div>
          )}
        </div>
      </section>
      {voidConfirmModal}
      </>
    )
  }

  // ── Render: Detail view (read-only) ────────────────────────────
  if (view === "detail" && selectedDoc) {
    const h = selectedDoc.header
    return (
      <>
      {/* Botones fuera del panel, alineados con el breadcrumb */}
      <div className="inv-doc-detail-topbar">
        <span className={h.estado === "A" ? "chip chip--success" : "chip chip--danger"}>
          {h.estado === "A" ? "Activo" : "Anulado"}
        </span>
        <div className="inv-doc-detail-topbar__actions">
          <button
            type="button"
            className="secondary-button"
            onClick={() => navigateToIndex(0)}
            disabled={selectedDocIndex <= 0}
          >
            <ChevronsLeft size={14} /> Primero
          </button>
          <button
            type="button"
            className="secondary-button"
            onClick={() => navigateDetail(-1)}
            disabled={selectedDocIndex <= 0}
          >
            <ChevronLeft size={14} /> Anterior
          </button>
          <button
            type="button"
            className="secondary-button"
            onClick={() => navigateDetail(1)}
            disabled={selectedDocIndex < 0 || selectedDocIndex >= sortedDocs.length - 1}
          >
            Siguiente <ChevronRight size={14} />
          </button>
          <button
            type="button"
            className="secondary-button"
            onClick={() => navigateToIndex(sortedDocs.length - 1)}
            disabled={selectedDocIndex < 0 || selectedDocIndex >= sortedDocs.length - 1}
          >
            Ultimo <ChevronsRight size={14} />
          </button>
          {h.estado === "A" && canEdit ? (
            <button type="button" className="secondary-button" onClick={() => requestEdit(h)}>
              <Pencil size={14} /> Editar
            </button>
          ) : null}
          {h.estado === "A" && (
            <button type="button" className="secondary-button" onClick={() => requestVoid(h)}>
              <Ban size={14} /> Anular
            </button>
          )}
          <button type="button" className="secondary-button" onClick={() => setView("list")}>
            <X size={14} /> Cerrar
          </button>
        </div>
      </div>
      <section className="data-panel">
        <div className="inv-doc-screen">
          <div className="inv-doc-detail-header">
            <div className="inv-doc-detail-header__row">
              <label><span>Fecha</span><input value={h.fecha.slice(0, 10)} disabled /></label>
              <label><span>Periodo</span><input value={h.periodo} disabled /></label>
              <label><span>Documento</span><input value={h.numeroDocumento} disabled /></label>
              <label><span>Moneda</span><input value={h.nombreMoneda || "—"} disabled /></label>
            </div>
            <div className="inv-doc-detail-header__row">
              <label><span>Tipo Documento</span><input value={h.nombreTipoDocumento} disabled /></label>
              <label><span>Almacen</span><input value={h.nombreAlmacen} disabled /></label>
              <label><span>Referencia</span><input value={h.referencia || "—"} disabled /></label>
              <label><span>Tasa Cambio</span><input value={h.tasaCambio} disabled /></label>
            </div>
            {isPurchase ? (
              <div className="inv-doc-detail-header__row">
                <label><span>Proveedor</span><input value={h.nombreProveedor || "—"} disabled /></label>
                <label><span>No. Factura</span><input value={h.noFactura || "—"} disabled /></label>
                <label><span>NCF</span><input value={h.ncf || "—"} disabled /></label>
                <label><span>Fecha Factura</span><input value={h.fechaFactura || "—"} disabled /></label>
              </div>
            ) : null}
          </div>

          <div className="inv-doc-screen__table-wrap">
            <div className="inv-doc-grid__tabs" style={{ marginBottom: "0.6rem" }}>
              <button
                type="button"
                className={detailTab === "detail" ? "filter-pill is-active" : "filter-pill"}
                onClick={() => setDetailTab("detail")}
              >
                Detalle actual
              </button>
              {canViewHistory ? (
                <button
                  type="button"
                  className={detailTab === "history" ? "filter-pill is-active" : "filter-pill"}
                  onClick={() => {
                    setDetailTab("history")
                    void loadDocumentHistory(h.id)
                  }}
                >
                  Historico de cambios
                </button>
              ) : null}
            </div>

            {detailTab === "detail" ? (
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
                  {selectedDoc.lines.map(l => (
                    <tr key={l.id}>
                      <td className="text-center">{l.numeroLinea}</td>
                      <td>{l.codigo}</td>
                      <td>{l.descripcion}</td>
                      <td className="text-right">{l.cantidad}</td>
                      <td>{l.nombreUnidad}</td>
                      <td className="text-right">{formatNumber(l.costo, 4)}</td>
                      <td className="text-right">{formatNumber(l.total, 4)}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr>
                    <td colSpan={6} className="text-right"><strong>Total</strong></td>
                    <td className="text-right"><strong>{h.simboloMoneda} {formatNumber(h.totalDocumento, 2)}</strong></td>
                  </tr>
                </tfoot>
              </table>
            ) : (
              <table className="inv-doc-grid__table">
                <thead>
                  <tr>
                    <th>Fecha</th>
                    <th>Estado</th>
                    <th className="col-linea">#</th>
                    <th className="col-codigo">Codigo</th>
                    <th className="col-desc">Descripcion</th>
                    <th className="col-cant">Cantidad</th>
                    <th className="col-costo">Costo</th>
                    <th className="col-total">Total</th>
                  </tr>
                </thead>
                <tbody>
                  {historyLoading ? (
                    <tr>
                      <td colSpan={8} className="text-center">Cargando historico...</td>
                    </tr>
                  ) : historyRows.length === 0 ? (
                    <tr>
                      <td colSpan={8} className="text-center">Sin cambios historicos para este documento.</td>
                    </tr>
                  ) : historyRows.map((row) => (
                    <tr key={row.id}>
                      <td>{toDateTimeText(row.fechaCreacion)}</td>
                      <td>
                        <span className={row.rowStatus === 1 ? "chip chip--success" : "chip chip--neutral"}>
                          {row.rowStatus === 1 ? "Actual" : "Historico"}
                        </span>
                      </td>
                      <td className="text-center">{row.numeroLinea}</td>
                      <td>{row.codigo}</td>
                      <td>{row.descripcion}</td>
                      <td className="text-right">{formatNumber(row.cantidad, 2)}</td>
                      <td className="text-right">{formatNumber(row.costo, 4)}</td>
                      <td className="text-right">{formatNumber(row.total, 4)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </section>
      {voidConfirmModal}
      </>
    )
  }

  // ── Render: New document form ──────────────────────────────────
  return (
    <>
    <div className="inv-doc-detail-topbar">
      {editingDoc ? <span className="chip chip--neutral">Editando {editingDoc.numero}</span> : null}
      <div className="inv-doc-detail-topbar__actions">
        <button
          type="button"
          className="secondary-button"
          onClick={() => confirmAction(() => {
            resetForm()
            setDirty(false)
            if (editingDoc && selectedDoc?.header.id === editingDoc.id) {
              setView("detail")
            } else {
              setView("list")
            }
          })}
        >
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
          {/* ── Header fields ── */}
          <div className="inv-doc-detail-header">
            <div className="inv-doc-detail-header__row">
              <label>
                <span>Fecha *</span>
                <input type="date" value={form.fecha} onChange={e => onFechaChange(e.target.value)} required />
              </label>

              <label>
                <span>Periodo</span>
                <input value={form.periodo} disabled />
              </label>

              <label>
                <span>Documento</span>
                <input value={editingDoc?.numero ?? (formatDocPreview(selectedDocType) || "Auto")} disabled />
              </label>

              <label>
                <span>Moneda</span>
                <input value={form.simboloMoneda || "Sin moneda"} disabled />
              </label>
            </div>

            <div className="inv-doc-detail-header__row">
              <label>
                <span>Tipo Documento *</span>
                <select
                  value={form.idTipoDocumento ?? ""}
                  onChange={e => e.target.value ? onTipoDocumentoChange(Number(e.target.value)) : setForm(prev => ({ ...prev, idTipoDocumento: null }))}
                  required
                >
                  <option value="">Seleccionar...</option>
                  {availableDocTypes.map(dt => (
                    <option key={dt.id} value={dt.id}>{dt.description}</option>
                  ))}
                </select>
              </label>

              <label>
                <span>Almacen *</span>
                <select
                  value={form.idAlmacen ?? ""}
                  onChange={e => setForm(prev => ({ ...prev, idAlmacen: e.target.value ? Number(e.target.value) : null }))}
                  required
                >
                  <option value="">Seleccionar...</option>
                  {warehouses.filter(w => w.active).map(w => (
                    <option key={w.id} value={w.id}>{w.description} ({w.initials})</option>
                  ))}
                </select>
              </label>

              <label>
                <span>Referencia</span>
                <input
                  value={form.referencia}
                  onChange={e => setForm(prev => ({ ...prev, referencia: e.target.value }))}
                  maxLength={250}
                  placeholder="Referencia del documento"
                />
              </label>

              <label className="inv-doc-form__field--short">
                <span>Tasa Cambio</span>
                <input
                  type="number"
                  lang="en-US"
                  inputMode="decimal"
                  step="1"
                  min={0}
                  value={form.tasaCambio}
                  onChange={e => setForm(prev => ({ ...prev, tasaCambio: Number(e.target.value) }))}
                />
              </label>
            </div>
            {isPurchase ? (
              <div className="inv-doc-detail-header__row">
                <label>
                  <span>Proveedor</span>
                  <select
                    value={form.idProveedor ?? ""}
                    onChange={(e) => setForm((prev) => ({ ...prev, idProveedor: e.target.value ? Number(e.target.value) : null }))}
                  >
                    <option value="">Seleccionar...</option>
                    {supplierOptions.map((supplier) => (
                      <option key={supplier.id} value={supplier.id}>{supplier.code} - {supplier.name}</option>
                    ))}
                  </select>
                </label>

                <label>
                  <span>No. Factura</span>
                  <input
                    value={form.noFactura}
                    onChange={(e) => setForm((prev) => ({ ...prev, noFactura: e.target.value }))}
                    maxLength={50}
                    placeholder="Numero de factura"
                  />
                </label>

                <label>
                  <span>NCF</span>
                  <input
                    value={form.ncf}
                    onChange={(e) => setForm((prev) => ({ ...prev, ncf: e.target.value }))}
                    maxLength={50}
                    placeholder="NCF"
                  />
                </label>

                <label>
                  <span>Fecha Factura</span>
                  <input
                    type="date"
                    value={form.fechaFactura}
                    onChange={(e) => setForm((prev) => ({ ...prev, fechaFactura: e.target.value }))}
                  />
                </label>
              </div>
            ) : null}

            {!isHeaderReadyForDetail ? (
              <div className="inv-doc-header-hint">
                <span className="inv-doc-header-hint__dot" />
                Completa los campos requeridos (<strong>*</strong>) para habilitar el detalle
              </div>
            ) : null}
          </div>

          {/* ── Detail grid ── */}
          <div className="inv-doc-grid">
            <div className="inv-doc-grid__header">
              <div className="inv-doc-grid__tabs">
                <button
                  type="button"
                  className={entryTab === "detail" ? "filter-pill is-active" : "filter-pill"}
                  onClick={() => setEntryTab("detail")}
                >
                  Detalle
                </button>
                <button
                  type="button"
                  className={entryTab === "notes" ? "filter-pill is-active" : "filter-pill"}
                  onClick={() => setEntryTab("notes")}
                >
                  Comentarios / Observaciones
                </button>
              </div>
              {entryTab === "detail" ? (
                <button type="button" className="secondary-button" onClick={addEmptyLine} disabled={!isHeaderReadyForDetail} title={!isHeaderReadyForDetail ? detailLockedMessage : undefined}>
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
                              ref={el => { codeInputRefs.current[line.key] = el }}
                              className={activeLineKey === line.key ? "inv-doc-grid__editable-hint" : undefined}
                              value={line.codigo}
                              disabled={!isHeaderReadyForDetail}
                              onFocus={() => setActiveLineKey(line.key)}
                              onChange={e => updateLine(line.key, { codigo: e.target.value })}
                              onKeyDown={e => {
                                if (e.key === "Enter") { e.preventDefault(); void lookupCode(line.key, line.codigo) }
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
                            type="number"
                            lang="en-US"
                            inputMode="decimal"
                            min={0}
                            step="1"
                            className={activeLineKey === line.key ? "text-right inv-doc-grid__editable-hint" : "text-right"}
                            value={line.cantidad || ""}
                            disabled={!isHeaderReadyForDetail}
                            onFocus={() => setActiveLineKey(line.key)}
                            onKeyDown={e => {
                              if (e.key === "Enter") {
                                e.preventDefault()
                                costInputRefs.current[line.key]?.focus()
                                costInputRefs.current[line.key]?.select()
                              }
                            }}
                            onChange={e => updateLine(line.key, { cantidad: Number(e.target.value) })}
                          />
                        </td>
                        <td>
                          {line.pideUnidadInventario && line.unidadesDisponibles.length > 1 ? (
                            <select
                              className="inv-doc-grid__unit-select"
                              value={line.idUnidadMedida ?? ""}
                              disabled={!isHeaderReadyForDetail}
                              onChange={(e) => {
                                const selected = line.unidadesDisponibles.find((u) => u.id === Number(e.target.value))
                                if (!selected) return
                                const baseUnit = line.unidadesDisponibles.find((u) => u.id === line.idUnidadBase) ?? null
                                updateLine(line.key, {
                                  idUnidadMedida: selected.id,
                                  unidad: selected.abreviatura || selected.nombre,
                                  existenciaActual: line.existenciaBase != null ? convertQuantityBetweenUnits(line.existenciaBase, baseUnit, selected) : null,
                                  costo: line.costoBase != null ? convertCostFromBase(line.costoBase, baseUnit, selected) : line.costo,
                                })
                              }}
                            >
                              {line.unidadesDisponibles.map((u) => (
                                <option key={u.id} value={u.id}>
                                  {u.nombre} ({u.abreviatura || u.nombre})
                                </option>
                              ))}
                            </select>
                          ) : (
                            <input value={line.unidad} disabled className="inv-doc-grid__readonly" />
                          )}
                        </td>
                        <td>
                          <input
                            ref={el => { costInputRefs.current[line.key] = el }}
                            type="number"
                            lang="en-US"
                            inputMode="decimal"
                            min={0}
                            step="1"
                            className={activeLineKey === line.key ? "text-right inv-doc-grid__editable-hint" : "text-right"}
                            value={line.costo || ""}
                            disabled={!isHeaderReadyForDetail}
                            onFocus={() => setActiveLineKey(line.key)}
                            onChange={e => updateLine(line.key, { costo: Number(e.target.value) })}
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
                      <td colSpan={2} className="inv-doc-grid__footer-total"><strong>{form.simboloMoneda} {formatNumber(totalDoc, 2)}</strong></td>
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
                    onChange={e => setForm(prev => ({ ...prev, observacion: e.target.value }))}
                    maxLength={500}
                    placeholder="Comentarios u observaciones generales del movimiento..."
                  />
                </label>
              </div>
            )}
          </div>

        </form>
      </div>

      {saveConfirmOpen ? (
        <div className="modal-backdrop" onClick={() => setSaveConfirmOpen(false)}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon"><Save size={20} /></div>
              <div>
                <h3 className="modal-card__title">Confirmar guardado</h3>
                <p className="modal-card__subtitle">{editingDoc ? `Editar ${editingDoc.numero}` : title}</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>{editingDoc ? "¿Deseas guardar los cambios del documento?" : "¿Deseas guardar este documento?"}</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setSaveConfirmOpen(false)}>
                Cancelar
              </button>
              <button type="button" className="primary-button" onClick={confirmSaveDocument} disabled={isPending}>
                <Save size={15} /> {isPending ? "Guardando..." : "Si, guardar"}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {/* ── Product search modal ── */}
      {searchOpen && (
        <div className="inv-product-modal__backdrop" onClick={() => setSearchOpen(false)}>
          <div className="inv-product-modal" onClick={e => e.stopPropagation()}>
            <header className="inv-product-modal__header">
              <h3>Buscar Producto</h3>
              <button type="button" className="icon-button" onClick={() => setSearchOpen(false)}>
                <X size={16} />
              </button>
            </header>

            <div className="inv-product-modal__search">
              <Search size={14} />
              <input
                autoFocus
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                placeholder="Buscar por codigo o nombre..."
              />
            </div>

            <div className="inv-product-modal__list">
              {searchLoading && <div className="inv-product-modal__loading"><Loader2 size={18} className="spin" /></div>}
              {!searchLoading && searchResults.length === 0 && searchQuery.trim() && (
                <p className="inv-product-modal__empty">Sin resultados</p>
              )}
              {searchResults.map(p => (
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
      )}
    </section>
    {voidConfirmModal}
    </>
  )
}



