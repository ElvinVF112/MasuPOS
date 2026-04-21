"use client"

import {
  Ban, ChevronDown, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight,
  Eye, FileText, Filter, Loader2, Pencil, Plus, Printer, RefreshCw, RotateCcw, Save, Search, Trash2, X,
} from "lucide-react"
import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { usePermissions } from "@/lib/permissions-context"
import type {
  FacTipoDocumentoRecord, TerceroRecord, CatalogoNCFRecord, FacDocumentoRecord,
  FacDocumentoDetalleRecord, FacDocumentoPagoRecord, EmissionPointRecord, ProductRecord,
} from "@/lib/pos-data"

// ── Types ──────────────────────────────────────────────────────────

type DocEstado = "I" | "P" | "N"

type Linea = {
  key: string
  idProducto: number | null
  codigo: string
  descripcion: string
  cantidad: number
  precioBase: number
  porcentajeImpuesto: number
  aplicaImpuesto: boolean
  descuentoLinea: number
  subTotal: number
  impuesto: number
  total: number
}

type ProductoSearch = {
  id: number
  code: string
  name: string
  price: number
  taxRate?: number
  applyTax?: boolean
}

type Props = {
  tiposDocumento: FacTipoDocumentoRecord[]
  customers: TerceroRecord[]
  tiposNCF: CatalogoNCFRecord[]
  emissionPoints: EmissionPointRecord[]
}

// ── Helpers ─────────────────────────────────────────────────────────

function today() { return new Date().toISOString().slice(0, 10) }

function normalizeDateInput(value: string | null | undefined) {
  if (!value) return ""
  const raw = String(value).trim()
  const isoMatch = raw.match(/^(\d{4})-(\d{2})-(\d{2})/)
  if (isoMatch) return `${isoMatch[1]}-${isoMatch[2]}-${isoMatch[3]}`
  const displayMatch = raw.match(/^(\d{2})\/(\d{2})\/(\d{4})$/)
  if (displayMatch) return `${displayMatch[3]}-${displayMatch[2]}-${displayMatch[1]}`
  const englishMonthMatch = raw.match(/^(?:[A-Za-z]{3}\s+)?([A-Za-z]{3})\s+(\d{1,2})(?:\s+\d{2}:\d{2}:\d{2})?(?:\s+[A-Z]{3,4})?(?:\s+\(.*\))?\s+(\d{4})$/)
  if (englishMonthMatch) {
    const monthMap: Record<string, string> = {
      Jan: "01", Feb: "02", Mar: "03", Apr: "04", May: "05", Jun: "06",
      Jul: "07", Aug: "08", Sep: "09", Oct: "10", Nov: "11", Dec: "12",
    }
    const month = monthMap[englishMonthMatch[1]]
    if (month) return `${englishMonthMatch[3]}-${month}-${String(englishMonthMatch[2]).padStart(2, "0")}`
  }
  const parsed = new Date(raw)
  if (Number.isNaN(parsed.getTime())) return ""
  const year = parsed.getFullYear()
  const month = String(parsed.getMonth() + 1).padStart(2, "0")
  const day = String(parsed.getDate()).padStart(2, "0")
  return `${year}-${month}-${day}`
}

function formatDateDisplay(value: string | null | undefined) {
  const iso = normalizeDateInput(value)
  if (!iso) return ""
  const [year, month, day] = iso.split("-")
  return `${day}/${month}/${year}`
}

function parseDisplayDateInput(value: string | null | undefined) {
  if (!value) return ""
  const raw = String(value).trim()
  const match = raw.match(/^(\d{2})\/(\d{2})\/(\d{4})$/)
  if (!match) return normalizeDateInput(raw)
  const [, day, month, year] = match
  return `${year}-${month}-${day}`
}

function emptyLinea(): Linea {
  return {
    key: crypto.randomUUID(),
    idProducto: null,
    codigo: "",
    descripcion: "",
    cantidad: 1,
    precioBase: 0,
    porcentajeImpuesto: 18,
    aplicaImpuesto: true,
    descuentoLinea: 0,
    subTotal: 0,
    impuesto: 0,
    total: 0,
  }
}

function calcLinea(l: Linea): Linea {
  const sub = l.cantidad * l.precioBase
  const desc = l.descuentoLinea
  const imp = l.aplicaImpuesto ? (sub - desc) * (l.porcentajeImpuesto / 100) : 0
  return { ...l, subTotal: sub, impuesto: imp, total: sub - desc + imp }
}

function fmt(v: number) {
  return new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(v)
}

function escapeHtml(value: string) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;")
}

const ESTADO_LABEL: Record<DocEstado, string> = { I: "Pendiente", P: "Posteado", N: "Anulado" }
const ESTADO_BG: Record<DocEstado, string> = { I: "rgba(245,158,11,0.12)", P: "rgba(16,185,129,0.12)", N: "rgba(244,63,94,0.1)" }
const ESTADO_COLOR: Record<DocEstado, string> = { I: "#b45309", P: "#11875c", N: "#b4233d" }

function EstadoBadge({ e }: { e: DocEstado }) {
  return (
    <span style={{ background: ESTADO_BG[e], color: ESTADO_COLOR[e], fontSize: "0.67rem", fontWeight: 700, padding: "2px 8px", borderRadius: 4, textTransform: "uppercase", letterSpacing: "0.04em", whiteSpace: "nowrap" }}>
      {ESTADO_LABEL[e]}
    </span>
  )
}

// ── Component ─────────────────────────────────────────────────────

export function FacDocumentosScreen({ tiposDocumento, customers, tiposNCF, emissionPoints }: Props) {
  const { hasPermission } = usePermissions()
  const canView    = hasPermission("facturacion.facturas.view")
  const canCreate  = hasPermission("facturacion.facturas.create")
  const canEdit    = hasPermission("facturacion.facturas.edit")
  const canVoid    = hasPermission("facturacion.facturas.anular")
  const canPrint   = hasPermission("facturacion.facturas.reimprimir")
  const canReturn  = hasPermission("facturacion.facturas.devolucion")

  const defaultPuntoEmisionId = emissionPoints[0]?.id ?? 0
  const tipoFAC = tiposDocumento.find((t) => t.prefijo.toUpperCase().startsWith("FAC")) ?? tiposDocumento[0] ?? null

  // ── View state
  const [view, setView] = useState<"list" | "new" | "detail">("list")
  const [editingId, setEditingId] = useState<number | null>(null)

  // ── List state
  const [rows, setRows] = useState<FacDocumentoRecord[]>([])
  const [totalRegistros, setTotalRegistros] = useState(0)
  const [listLoading, setListLoading] = useState(false)
  const [pageSize, setPageSize] = useState(10)
  const [pageOffset, setPageOffset] = useState(0)
  const [fFechaDesde, setFFechaDesde] = useState(() => { const d = new Date(); d.setDate(1); return d.toISOString().slice(0, 10) })
  const [fFechaHasta, setFFechaHasta] = useState(() => today())
  const [fSecuenciaDesde, setFSecuenciaDesde] = useState("")
  const [fSecuenciaHasta, setFSecuenciaHasta] = useState("")
  const [fCliente, setFCliente] = useState("")

  // ── Detail state
  const [selectedDoc, setSelectedDoc] = useState<{ doc: FacDocumentoRecord; lineas: FacDocumentoDetalleRecord[]; pagos: FacDocumentoPagoRecord[] } | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)
  const [detailTab, setDetailTab] = useState<"detail" | "history">("detail")

  // ── Form state
  const [idTipoDocumento, setIdTipoDocumento] = useState<number | null>(tipoFAC?.id ?? null)
  const [idPuntoEmision, setIdPuntoEmision] = useState<number>(defaultPuntoEmisionId)
  const [fecha, setFecha] = useState(today())
  const [fechaInput, setFechaInput] = useState(() => formatDateDisplay(today()))
  const [idCliente, setIdCliente] = useState<number | null>(null)
  const [nombreClienteManual, setNombreClienteManual] = useState("")
  const [rncCliente, setRncCliente] = useState("")
  const [ncf, setNcf] = useState("")
  const [idTipoNCF, setIdTipoNCF] = useState<number | null>(null)
  const [comentario, setComentario] = useState("")
  const [lineas, setLineas] = useState<Linea[]>([emptyLinea()])
  const [saving, setSaving] = useState(false)
  const [formTab, setFormTab] = useState<"detail" | "comments">("detail")
  const [editingDocumentoNumero, setEditingDocumentoNumero] = useState("")
  const [editingTipoDocumentoLabel, setEditingTipoDocumentoLabel] = useState("")
  const [editingClienteLabel, setEditingClienteLabel] = useState("")
  const [editingTipoNCFLabel, setEditingTipoNCFLabel] = useState("")
  const [editingPuntoEmisionLabel, setEditingPuntoEmisionLabel] = useState("")

  // ── Product search modal
  const [searchOpen, setSearchOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState("")
  const [searchResults, setSearchResults] = useState<ProductoSearch[]>([])
  const [searchLoading, setSearchLoading] = useState(false)
  const [searchTargetKey, setSearchTargetKey] = useState<string | null>(null)
  const searchInputRef = useRef<HTMLInputElement | null>(null)

  // ── Anular modal
  const [anularId, setAnularId] = useState<number | null>(null)
  const [motivoAnulacion, setMotivoAnulacion] = useState("")
  const [anulando, setAnulando] = useState(false)

  // ── Devolución modal
  type DevLinea = FacDocumentoDetalleRecord & { cantDevolucion: number }
  const [devDoc, setDevDoc] = useState<FacDocumentoRecord | null>(null)
  const [devLineas, setDevLineas] = useState<DevLinea[]>([])
  const [devMotivo, setDevMotivo] = useState("")
  const [devLoading, setDevLoading] = useState(false)
  const [devGenerando, setDevGenerando] = useState(false)
  const [printDoc, setPrintDoc] = useState<FacDocumentoRecord | null>(null)
  const [printingFormat, setPrintingFormat] = useState<"letter" | "ticket" | null>(null)

  // ── Derived
  const totales = useMemo(() => lineas.reduce((a, l) => ({
    sub: a.sub + l.subTotal,
    desc: a.desc + l.descuentoLinea,
    imp: a.imp + l.impuesto,
    total: a.total + l.total,
  }), { sub: 0, desc: 0, imp: 0, total: 0 }), [lineas])

  const tipoSeleccionado = tiposDocumento.find((t) => t.id === idTipoDocumento) ?? null
  const clienteSeleccionado = customers.find((c) => c.id === idCliente) ?? null
  const nombreCliente = clienteSeleccionado?.name ?? nombreClienteManual
  const hasTipoDocumentoOption = idTipoDocumento != null && tiposDocumento.some((t) => t.id === idTipoDocumento)
  const hasClienteOption = idCliente != null && customers.some((c) => c.id === idCliente)
  const hasTipoNCFOption = idTipoNCF != null && tiposNCF.some((n) => n.id === idTipoNCF)
  const hasPuntoEmisionOption = idPuntoEmision > 0 && emissionPoints.some((p) => p.id === idPuntoEmision)
  const documentoPreview = editingId
    ? (editingDocumentoNumero || "—")
    : (tipoSeleccionado ? `${tipoSeleccionado.prefijo}-${String((tipoSeleccionado.secuenciaActual ?? 0) + 1).padStart(7, "0")}` : "—")

  const filteredRows = useMemo(() => {
    if (!fCliente.trim()) return rows
    const q = fCliente.toLowerCase()
    return rows.filter((r) => r.nombreCliente?.toLowerCase().includes(q) || r.rncCliente?.toLowerCase().includes(q))
  }, [rows, fCliente])

  const totalPages = useMemo(() => {
    if (pageSize <= 0) return 1
    return Math.max(1, Math.ceil(totalRegistros / pageSize))
  }, [pageSize, totalRegistros])

  const currentPage = useMemo(() => {
    if (pageSize <= 0) return 1
    return Math.floor(pageOffset / pageSize) + 1
  }, [pageOffset, pageSize])

  // ── List
  const loadList = useCallback(async (offset = 0, nextPageSize = pageSize) => {
    setListLoading(true)
    try {
      const effectivePageSize = nextPageSize === 0 ? Math.max(totalRegistros, rows.length, 1000) : nextPageSize
      const params = new URLSearchParams({
        fechaDesde: fFechaDesde,
        fechaHasta: fFechaHasta,
        pageSize: String(effectivePageSize),
        pageOffset: String(nextPageSize === 0 ? 0 : offset),
      })
      if (fSecuenciaDesde) params.set("secuenciaDesde", fSecuenciaDesde)
      if (fSecuenciaHasta) params.set("secuenciaHasta", fSecuenciaHasta)
      const res = await fetch(apiUrl(`/api/facturacion/documentos?${params}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: FacDocumentoRecord[] }
      if (json.ok && json.data) {
        setRows(json.data)
        setTotalRegistros(json.data[0]?.totalRegistros ?? 0)
        setPageOffset(nextPageSize === 0 ? 0 : offset)
      }
    } catch { toast.error("Error al cargar documentos.") }
    finally { setListLoading(false) }
  }, [fFechaDesde, fFechaHasta, fSecuenciaDesde, fSecuenciaHasta, pageSize, rows.length, totalRegistros])

  useEffect(() => { void loadList(0) }, [loadList])

  // ── Detail load
  async function openDetail(idDocumento: number) {
    setDetailLoading(true)
    setSelectedDoc(null)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${idDocumento}`), { credentials: "include" })
      const json = (await res.json()) as {
        ok?: boolean
        data?: { doc: FacDocumentoRecord; lineas: FacDocumentoDetalleRecord[]; pagos: FacDocumentoPagoRecord[] }
        message?: string
      }
      if (!res.ok || !json.ok || !json.data) {
        toast.error(json.message ?? "No se pudo cargar el documento.")
        setView("list")
        return
      }
      setSelectedDoc(json.data)
      setDetailTab("detail")
      setView("detail")
    } catch {
      toast.error("Error al cargar documento.")
      setView("list")
    }
    finally { setDetailLoading(false) }
  }

  // ── Navigate detail
  const selectedIndex = useMemo(() => selectedDoc ? filteredRows.findIndex((r) => r.idDocumento === selectedDoc.doc.idDocumento) : -1, [selectedDoc, filteredRows])

  async function navigateDetail(dir: "first" | "prev" | "next" | "last") {
    let idx = selectedIndex
    if (dir === "first") idx = 0
    else if (dir === "prev") idx = Math.max(0, idx - 1)
    else if (dir === "next") idx = Math.min(filteredRows.length - 1, idx + 1)
    else idx = filteredRows.length - 1
    const target = filteredRows[idx]
    if (target) await openDetail(target.idDocumento)
  }

  // ── Form reset
  function resetForm() {
    setEditingId(null)
    setIdTipoDocumento(tipoFAC?.id ?? null)
    setIdPuntoEmision(defaultPuntoEmisionId)
    setFecha(today())
    setFechaInput(formatDateDisplay(today()))
    setIdCliente(null)
    setNombreClienteManual("")
    setRncCliente("")
    setNcf("")
    setIdTipoNCF(null)
    setComentario("")
    setLineas([emptyLinea()])
    setFormTab("detail")
    setEditingDocumentoNumero("")
    setEditingTipoDocumentoLabel("")
    setEditingClienteLabel("")
    setEditingTipoNCFLabel("")
    setEditingPuntoEmisionLabel("")
  }

  // ── Load form for edit
  async function openEdit(doc: FacDocumentoRecord) {
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${doc.idDocumento}`), { credentials: "include" })
      const json = (await res.json()) as {
        ok?: boolean
        data?: { doc: FacDocumentoRecord; lineas?: FacDocumentoDetalleRecord[] }
        message?: string
      }
      if (!res.ok || !json.ok || !json.data) {
        toast.error(json.message ?? "Error al cargar documento.")
        return
      }
      const d = json.data.doc
      const customerExists = d.idCliente != null && customers.some((c) => c.id === d.idCliente)
      setEditingId(d.idDocumento)
      setFormTab("detail")
      setIdTipoDocumento(d.idTipoDocumento)
      setIdPuntoEmision(d.idPuntoEmision ?? defaultPuntoEmisionId)
      const normalizedFecha = normalizeDateInput(d.fechaDocumento) || today()
      setFecha(normalizedFecha)
      setFechaInput(formatDateDisplay(normalizedFecha))
      setIdCliente(customerExists ? (d.idCliente ?? null) : null)
      setNombreClienteManual(d.nombreCliente ?? "")
      setRncCliente(d.rncCliente ?? "")
      setNcf(d.ncf ?? "")
      setIdTipoNCF(d.idTipoNCF ?? null)
      setComentario(d.comentario ?? "")
      setEditingDocumentoNumero(d.documentoSecuencia || `${d.tipoPrefijo}-${String(d.secuencia).padStart(7, "0")}`)
      setEditingTipoDocumentoLabel(d.tipoDocumentoNombre ? `${d.tipoPrefijo} — ${d.tipoDocumentoNombre}` : d.tipoPrefijo)
      setEditingClienteLabel(d.nombreCliente ?? "")
      setEditingTipoNCFLabel(d.tipoNCFNombre ?? "")
      setEditingPuntoEmisionLabel(d.puntoEmisionNombre ?? "")
      const editLines = (json.data.lineas ?? []).map((l) => calcLinea({
        key: crypto.randomUUID(),
        idProducto: l.idProducto,
        codigo: l.codigo ?? "",
        descripcion: l.descripcion,
        cantidad: l.cantidad,
        precioBase: l.precioBase,
        porcentajeImpuesto: l.porcentajeImpuesto,
        aplicaImpuesto: l.aplicaImpuesto,
        descuentoLinea: l.descuentoLinea,
        subTotal: 0, impuesto: 0, total: 0,
      }))
      setLineas(editLines.length > 0 ? editLines : [emptyLinea()])
      setView("new")
    } catch { toast.error("Error al cargar documento para editar.") }
  }

  // ── Line helpers
  function updateLinea(key: string, patch: Partial<Linea>) {
    setLineas((prev) => prev.map((l) => l.key === key ? calcLinea({ ...l, ...patch }) : l))
  }
  function removeLinea(key: string) {
    setLineas((prev) => prev.length > 1 ? prev.filter((l) => l.key !== key) : prev)
  }
  function addLinea() { setLineas((prev) => [...prev, emptyLinea()]) }

  // ── Product search
  useEffect(() => {
    if (!searchOpen || !searchQuery.trim()) { setSearchResults([]); return }
    const timer = setTimeout(async () => {
      setSearchLoading(true)
      try {
        const res = await fetch(apiUrl("/api/catalog/products/search"), {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          credentials: "include",
          body: JSON.stringify({ q: searchQuery, limit: 50 }),
        })
        const json = (await res.json()) as { ok?: boolean; items?: ProductoSearch[] }
        if (json.ok) setSearchResults(json.items ?? [])
      } catch { /* ignore */ }
      finally { setSearchLoading(false) }
    }, 300)
    return () => clearTimeout(timer)
  }, [searchQuery, searchOpen])

  function openSearch(lineKey: string) {
    setSearchTargetKey(lineKey)
    setSearchQuery("")
    setSearchResults([])
    setSearchOpen(true)
    setTimeout(() => searchInputRef.current?.focus(), 50)
  }

  async function applyProductToLine(lineKey: string, p: ProductoSearch) {
    setSearchLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/products/${p.id}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; product?: ProductRecord | null }
      const product = json.ok ? (json.product ?? null) : null
      updateLinea(lineKey, {
        idProducto: p.id,
        codigo: product?.code ?? p.code,
        descripcion: product?.name ?? p.name,
        precioBase: product?.price ?? p.price,
        porcentajeImpuesto: product?.taxRate ?? p.taxRate ?? 18,
        aplicaImpuesto: product?.applyTax ?? p.applyTax ?? true,
      })
    } catch {
      updateLinea(lineKey, {
        idProducto: p.id,
        codigo: p.code,
        descripcion: p.name,
        precioBase: p.price,
        porcentajeImpuesto: p.taxRate ?? 18,
        aplicaImpuesto: p.applyTax ?? true,
      })
    } finally {
      setSearchLoading(false)
    }
  }

  async function selectProduct(p: ProductoSearch) {
    if (!searchTargetKey) return
    await applyProductToLine(searchTargetKey, p)
    setSearchOpen(false)
    setSearchTargetKey(null)
  }

  async function resolveLineByCode(lineKey: string, rawCode: string) {
    const code = rawCode.trim()
    if (!code) return
    setSearchLoading(true)
    try {
      const res = await fetch(apiUrl("/api/catalog/products/search"), {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ q: code, limit: 10 }),
      })
      const json = (await res.json()) as { ok?: boolean; items?: ProductoSearch[] }
      const exact = (json.items ?? []).find((item) => item.code?.trim().toLowerCase() === code.toLowerCase()) ?? (json.items ?? [])[0]
      if (!res.ok || !json.ok || !exact) {
        toast.error(`No se encontro el articulo ${code}.`)
        return
      }
      await applyProductToLine(lineKey, exact)
    } catch {
      toast.error("Error al buscar articulo por codigo.")
    } finally {
      setSearchLoading(false)
    }
  }

  // ── Save
  async function saveDocument() {
    const validLines = lineas.filter((l) => l.descripcion.trim() && l.cantidad > 0)
    const normalizedFecha = parseDisplayDateInput(fechaInput)
    if (validLines.length === 0) { toast.error("Agrega al menos una línea válida."); return }
    if (!idTipoDocumento) { toast.error("Selecciona el tipo de documento."); return }
    if (!idPuntoEmision) { toast.error("No hay punto de emisión configurado."); return }
    if (!normalizedFecha) { toast.error("La fecha debe estar en formato dd/MM/yyyy."); return }
    setFecha(normalizedFecha)
    setFechaInput(formatDateDisplay(normalizedFecha))
    setSaving(true)
    try {
      const payload = {
        idTipoDocumento,
        idPuntoEmision,
        idCliente: idCliente ?? null,
        rncCliente: rncCliente.trim() || null,
        ncf: ncf.trim() || null,
        idTipoNCF: idTipoNCF ?? null,
        fecha: normalizedFecha,
        comentario: comentario.trim() || null,
        lineas: validLines.map((l) => ({
          idProducto: l.idProducto,
          codigo: l.codigo || null,
          descripcion: l.descripcion,
          cantidad: l.cantidad,
          precioBase: l.precioBase,
          porcentajeImpuesto: l.porcentajeImpuesto,
          aplicaImpuesto: l.aplicaImpuesto,
          descuentoLinea: l.descuentoLinea,
        })),
      }

      const url = editingId
        ? apiUrl(`/api/facturacion/documentos/${editingId}`)
        : apiUrl("/api/facturacion/documentos")
      const method = editingId ? "PUT" : "POST"
      const body = editingId ? JSON.stringify({ accion: "editar", ...payload }) : JSON.stringify(payload)

      const res = await fetch(url, { method, headers: { "Content-Type": "application/json" }, credentials: "include", body })
      const json = (await res.json()) as { ok?: boolean; data?: { idDocumento: number; secuencia: number }; message?: string }
      if (json.ok && json.data) {
        toast.success(editingId
          ? `Documento actualizado.`
          : `${tipoSeleccionado?.prefijo ?? "FAC"}-${String(json.data.secuencia).padStart(7, "0")} creado.`)
        resetForm()
        setView("list")
        void loadList(0)
      } else {
        toast.error(json.message ?? "Error al guardar.")
      }
    } catch { toast.error("Error al guardar.") }
    finally { setSaving(false) }
  }

  // ── Anular
  async function ejecutarAnulacion() {
    if (!anularId || !motivoAnulacion.trim()) return
    setAnulando(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${anularId}`), {
        method: "PUT", headers: { "Content-Type": "application/json" }, credentials: "include",
        body: JSON.stringify({ accion: "anular", motivo: motivoAnulacion.trim() }),
      })
      const json = (await res.json()) as { ok?: boolean; message?: string }
      if (json.ok) {
        toast.success("Documento anulado.")
        setAnularId(null)
        setMotivoAnulacion("")
        if (view === "detail") await openDetail(anularId)
        void loadList(pageOffset)
      } else { toast.error(json.message ?? "Error al anular.") }
    } catch { toast.error("Error al anular.") }
    finally { setAnulando(false) }
  }

  // ── Devolución
  async function abrirDevolucion(doc: FacDocumentoRecord) {
    setDevDoc(doc)
    setDevMotivo("")
    setDevLineas([])
    setDevLoading(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${doc.idDocumento}`), { credentials: "include" })
      const json = (await res.json()) as { ok?: boolean; data?: { lineas?: FacDocumentoDetalleRecord[] } }
      if (json.ok && json.data?.lineas) {
        setDevLineas(json.data.lineas.map((l) => ({ ...l, cantDevolucion: l.cantidad })))
      }
    } catch { toast.error("Error al cargar líneas.") }
    finally { setDevLoading(false) }
  }

  async function ejecutarDevolucion() {
    if (!devDoc) return
    const lineas2send = devLineas.filter((l) => l.cantDevolucion > 0)
      .map((l) => ({ idDocumentoDetalle: l.idDocumentoDetalle, cantidadDevolucion: l.cantDevolucion }))
    if (lineas2send.length === 0) { toast.error("Seleccione al menos una línea."); return }
    setDevGenerando(true)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/documentos/${devDoc.idDocumento}`), {
        method: "PUT", headers: { "Content-Type": "application/json" }, credentials: "include",
        body: JSON.stringify({ accion: "devolucion", motivo: devMotivo.trim() || undefined, lineas: lineas2send }),
      })
      const json = (await res.json()) as { ok?: boolean; data?: { secuencia: number }; message?: string }
      if (json.ok && json.data) {
        toast.success(`Nota de Crédito NC-${json.data.secuencia} generada.`)
        setDevDoc(null)
        void loadList(pageOffset)
      } else { toast.error(json.message ?? "Error al generar NC.") }
    } catch { toast.error("Error al generar NC.") }
    finally { setDevGenerando(false) }
  }

  async function printFactura(doc: FacDocumentoRecord, format: "letter" | "ticket") {
    setPrintingFormat(format)
    const printWindow = window.open("", "_blank", "width=960,height=720")
    if (!printWindow) {
      toast.error("Permite pop-ups para imprimir el documento.")
      setPrintingFormat(null)
      return
    }
    try {
      const [detailRes, brandingRes] = await Promise.all([
        fetch(apiUrl(`/api/facturacion/documentos/${doc.idDocumento}`), { credentials: "include" }),
        fetch(apiUrl("/api/company/public"), { credentials: "include", cache: "no-store" }),
      ])

      const detailJson = (await detailRes.json()) as {
        ok?: boolean
        data?: { doc: FacDocumentoRecord; lineas: FacDocumentoDetalleRecord[]; pagos: FacDocumentoPagoRecord[] }
      }
      const brandingJson = (await brandingRes.json()) as {
        ok?: boolean
        data?: { tradeName?: string; slogan?: string; logoUrl?: string | null }
      }

      if (!detailJson.ok || !detailJson.data) {
        printWindow.close()
        toast.error("No se pudo cargar la factura para imprimir.")
        return
      }

      const payload = detailJson.data
      const branding = brandingJson.ok ? brandingJson.data : undefined
      const title = payload.doc.documentoSecuencia || `${payload.doc.tipoPrefijo}-${String(payload.doc.secuencia).padStart(7, "0")}`

      const rowsHtml = payload.lineas.map((line) => `
        <tr>
          <td>${line.numeroLinea}</td>
          <td>${escapeHtml(line.codigo ?? "")}</td>
          <td>${escapeHtml(line.descripcion)}</td>
          <td class="text-right">${fmt(line.cantidad)}</td>
          <td class="text-right">${fmt(line.precioBase)}</td>
          <td class="text-right">${fmt(line.descuentoLinea)}</td>
          <td class="text-right">${fmt(line.impuestoLinea)}</td>
          <td class="text-right total-cell">${fmt(line.totalLinea)}</td>
        </tr>
      `).join("")

      const pagosHtml = payload.pagos.length > 0
        ? payload.pagos.map((payment) => `
          <tr>
            <td>${escapeHtml(payment.formaPagoNombre)}</td>
            <td>${escapeHtml(payment.referencia ?? "—")}</td>
            <td class="text-right">${fmt(payment.monto)}</td>
          </tr>
        `).join("")
        : ""

      const companyName = escapeHtml(branding?.tradeName || "Masu POS")
      const slogan = branding?.slogan ? `<p class="slogan">${escapeHtml(branding.slogan)}</p>` : ""
      const logo = branding?.logoUrl ? `<img src="${branding.logoUrl}" alt="Logo" class="logo" />` : ""
      const docDate = escapeHtml(payload.doc.fechaDocumento.slice(0, 10))
      const client = escapeHtml(payload.doc.nombreCliente || "Cliente final")
      const rnc = escapeHtml(payload.doc.rncCliente || "—")
      const ncf = escapeHtml(payload.doc.ncf || "—")
      const comment = payload.doc.comentario ? `<div class="comment"><strong>Comentario:</strong> ${escapeHtml(payload.doc.comentario)}</div>` : ""

      const html = format === "letter"
        ? `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>${title}</title>
  <style>
    @page { size: letter; margin: 0.5in; }
    body { font-family: "Segoe UI", Arial, sans-serif; color: #0f172a; margin: 0; }
    .sheet { width: 100%; }
    .header { display:flex; justify-content:space-between; gap:24px; border-bottom:2px solid #d9e4f2; padding-bottom:16px; margin-bottom:18px; }
    .brand { display:flex; gap:14px; align-items:flex-start; }
    .logo { width:64px; height:64px; object-fit:contain; }
    .brand h1 { margin:0; font-size:24px; }
    .slogan { margin:4px 0 0; color:#64748b; font-size:12px; }
    .doc-box { text-align:right; }
    .doc-box h2 { margin:0; font-size:20px; color:#12467e; }
    .doc-box p { margin:4px 0 0; font-size:12px; color:#475569; }
    .meta { display:grid; grid-template-columns:repeat(2, minmax(0,1fr)); gap:12px 20px; margin-bottom:18px; }
    .meta-card { border:1px solid #d9e4f2; border-radius:10px; padding:10px 12px; background:#fbfdff; }
    .meta-card span { display:block; font-size:11px; text-transform:uppercase; color:#64748b; margin-bottom:4px; }
    .meta-card strong { font-size:14px; }
    table { width:100%; border-collapse:collapse; font-size:12px; }
    th, td { border:1px solid #d9e4f2; padding:8px 10px; }
    th { background:#eef4fb; text-align:left; }
    .text-right { text-align:right; }
    .total-cell { font-weight:700; }
    .summary { margin-top:14px; margin-left:auto; width:280px; }
    .summary td { border:none; border-bottom:1px solid #e2e8f0; }
    .summary tr:last-child td { border-bottom:2px solid #0f172a; font-size:14px; font-weight:700; }
    .payments { margin-top:18px; }
    .payments h3 { margin:0 0 8px; font-size:14px; }
    .comment { margin-top:14px; font-size:12px; color:#334155; }
  </style>
</head>
<body>
  <div class="sheet">
    <div class="header">
      <div class="brand">
        ${logo}
        <div>
          <h1>${companyName}</h1>
          ${slogan}
        </div>
      </div>
      <div class="doc-box">
        <h2>${escapeHtml(payload.doc.tipoDocumentoNombre || "Factura")}</h2>
        <p><strong>${escapeHtml(title)}</strong></p>
        <p>Fecha: ${docDate}</p>
      </div>
    </div>

    <div class="meta">
      <div class="meta-card"><span>Cliente</span><strong>${client}</strong></div>
      <div class="meta-card"><span>Estado</span><strong>${escapeHtml(payload.doc.estado)}</strong></div>
      <div class="meta-card"><span>RNC/Cédula</span><strong>${rnc}</strong></div>
      <div class="meta-card"><span>NCF</span><strong>${ncf}</strong></div>
      <div class="meta-card"><span>Punto Emisión</span><strong>${escapeHtml(payload.doc.puntoEmisionNombre || "—")}</strong></div>
      <div class="meta-card"><span>Usuario</span><strong>${escapeHtml(payload.doc.usuarioNombre || "—")}</strong></div>
    </div>

    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Código</th>
          <th>Descripción</th>
          <th class="text-right">Cant.</th>
          <th class="text-right">Precio</th>
          <th class="text-right">Desc.</th>
          <th class="text-right">ITBIS</th>
          <th class="text-right">Total</th>
        </tr>
      </thead>
      <tbody>${rowsHtml}</tbody>
    </table>

    <table class="summary">
      <tr><td>Sub-total</td><td class="text-right">${fmt(payload.doc.subTotal)}</td></tr>
      <tr><td>Descuento</td><td class="text-right">${fmt(payload.doc.descuento)}</td></tr>
      <tr><td>ITBIS</td><td class="text-right">${fmt(payload.doc.impuesto)}</td></tr>
      <tr><td>Propina</td><td class="text-right">${fmt(payload.doc.propina)}</td></tr>
      <tr><td>Total</td><td class="text-right">${fmt(payload.doc.total)}</td></tr>
    </table>

    ${pagosHtml ? `<div class="payments"><h3>Pagos</h3><table><thead><tr><th>Forma</th><th>Referencia</th><th class="text-right">Monto</th></tr></thead><tbody>${pagosHtml}</tbody></table></div>` : ""}
    ${comment}
  </div>
</body>
</html>`
        : `<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>${title}</title>
  <style>
    @page { size: 80mm auto; margin: 4mm; }
    body { font-family: "Consolas", "Courier New", monospace; width: 72mm; margin: 0 auto; color:#111827; }
    .ticket { width: 100%; }
    .center { text-align:center; }
    .logo { width:48px; height:48px; object-fit:contain; display:block; margin:0 auto 6px; }
    h1 { font-size:16px; margin:0; }
    .slogan, .muted { font-size:10px; color:#4b5563; margin:2px 0; }
    .divider { border-top:1px dashed #94a3b8; margin:8px 0; }
    .meta, .totals { font-size:11px; }
    .line { display:flex; justify-content:space-between; gap:8px; }
    table { width:100%; border-collapse:collapse; font-size:10px; }
    th { text-align:left; border-bottom:1px solid #cbd5e1; padding:3px 0; }
    td { padding:4px 0; vertical-align:top; }
    .qty, .money { text-align:right; white-space:nowrap; }
    .desc { width:100%; padding-right:8px; }
    .strong { font-weight:700; }
    .totals .line { padding:2px 0; }
  </style>
</head>
<body>
  <div class="ticket">
    <div class="center">
      ${logo}
      <h1>${companyName}</h1>
      ${slogan}
      <div class="muted">${escapeHtml(payload.doc.tipoDocumentoNombre || "Factura")}</div>
      <div class="strong">${escapeHtml(title)}</div>
    </div>
    <div class="divider"></div>
    <div class="meta">
      <div class="line"><span>Fecha</span><span>${docDate}</span></div>
      <div class="line"><span>Cliente</span><span>${client}</span></div>
      <div class="line"><span>RNC</span><span>${rnc}</span></div>
      <div class="line"><span>NCF</span><span>${ncf}</span></div>
      <div class="line"><span>Cajero</span><span>${escapeHtml(payload.doc.usuarioNombre || "—")}</span></div>
    </div>
    <div class="divider"></div>
    <table>
      <thead>
        <tr><th>Descripción</th><th class="qty">Cant.</th><th class="money">Total</th></tr>
      </thead>
      <tbody>
        ${payload.lineas.map((line) => `
          <tr>
            <td class="desc">${escapeHtml(line.descripcion)}<br><span class="muted">${escapeHtml(line.codigo ?? "")} @ ${fmt(line.precioBase)}</span></td>
            <td class="qty">${fmt(line.cantidad)}</td>
            <td class="money strong">${fmt(line.totalLinea)}</td>
          </tr>
        `).join("")}
      </tbody>
    </table>
    <div class="divider"></div>
    <div class="totals">
      <div class="line"><span>Sub-total</span><span>${fmt(payload.doc.subTotal)}</span></div>
      <div class="line"><span>Descuento</span><span>${fmt(payload.doc.descuento)}</span></div>
      <div class="line"><span>ITBIS</span><span>${fmt(payload.doc.impuesto)}</span></div>
      <div class="line"><span>Propina</span><span>${fmt(payload.doc.propina)}</span></div>
      <div class="line strong"><span>Total</span><span>${fmt(payload.doc.total)}</span></div>
    </div>
    ${payload.pagos.length > 0 ? `<div class="divider"></div><div class="meta">${payload.pagos.map((payment) => `<div class="line"><span>${escapeHtml(payment.formaPagoNombre)}</span><span>${fmt(payment.monto)}</span></div>`).join("")}</div>` : ""}
    ${payload.doc.comentario ? `<div class="divider"></div><div class="muted">${escapeHtml(payload.doc.comentario)}</div>` : ""}
  </div>
</body>
</html>`

      printWindow.document.write(html)
      printWindow.document.close()
      printWindow.focus()
      printWindow.print()
      setPrintDoc(null)
    } catch {
      printWindow.close()
      toast.error("Error al imprimir factura.")
    } finally {
      setPrintingFormat(null)
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // RENDER: LIST
  // ══════════════════════════════════════════════════════════════════
  if (view === "list") {
    return (
      <>
      <section className="data-panel">
        <div className="inv-doc-screen">
          <header className="inv-doc-screen__header">
            <div className="inv-doc-screen__title">
              <FileText size={18} />
              <h2>Facturas</h2>
            </div>
            {canCreate && (
              <button type="button" className="primary-button inv-doc-screen__action-wide" onClick={() => { resetForm(); setView("new") }}>
                <Plus size={14} /> Nuevo Documento
              </button>
            )}
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
                  <input type="number" min={1} step={1} placeholder="Ej. 100" value={fSecuenciaDesde} onChange={(e) => setFSecuenciaDesde(e.target.value)} />
                </label>
                <label className="inv-doc-screen__filters-seq">
                  <span>Secuencia Hasta</span>
                  <input type="number" min={1} step={1} placeholder="Ej. 500" value={fSecuenciaHasta} onChange={(e) => setFSecuenciaHasta(e.target.value)} />
                </label>
                <label style={{ flex: "2 1 200px" }}>
                  <span>Cliente</span>
                  <input type="text" placeholder="Nombre o RNC..." value={fCliente} onChange={(e) => setFCliente(e.target.value)} />
                </label>
              </div>
              <div className="inv-doc-screen__filters-actions inv-doc-screen__filters-actions--bottom">
                <button type="button" className="primary-button inv-doc-screen__action-wide" onClick={() => void loadList(0)} disabled={listLoading}>
                  <RefreshCw size={14} className={listLoading ? "spin" : ""} /> {listLoading ? "Cargando..." : "Actualizar"}
                </button>
                <button type="button" className="ghost-button inv-doc-screen__action-wide" onClick={() => { const d = new Date(); d.setDate(1); const desde = d.toISOString().slice(0, 10); const hasta = today(); setFFechaDesde(desde); setFFechaHasta(hasta); setFSecuenciaDesde(""); setFSecuenciaHasta(""); setFCliente(""); void loadList(0) }} disabled={listLoading}>
                  × Limpiar
                </button>
              </div>
            </div>
          </div>

          {filteredRows.length === 0 && !listLoading ? (
            <div className="inv-doc-screen__empty">
              <FileText size={48} opacity={0.25} />
              <p>Sin documentos para los filtros seleccionados.</p>
            </div>
          ) : (
            <div className="inv-doc-screen__list-card">
              <div className="inv-doc-screen__list-head">
                <h3><FileText size={14} /> Documentos</h3>
                <span>{totalRegistros} registros encontrados</span>
              </div>
              <div className="inv-doc-screen__table-wrap">
                <table className="inv-doc-screen__table">
                  <thead>
                    <tr>
                      <th>Documento</th>
                      <th>Fecha</th>
                      <th>Tipo</th>
                      <th>Cliente</th>
                      <th>NCF</th>
                      <th className="text-right">Total</th>
                      <th>Estado</th>
                      <th className="text-center">Acciones</th>
                    </tr>
                  </thead>
                  <tbody>
                    {listLoading && rows.length === 0 ? (
                      <tr><td colSpan={8} style={{ textAlign: "center", padding: "2rem", color: "var(--muted)" }}><Loader2 size={18} className="spin" /> Cargando...</td></tr>
                    ) : filteredRows.map((row) => (
                      <tr key={row.idDocumento} className={row.estado === "N" ? "is-voided" : ""}>
                        <td style={{ fontWeight: 600 }}>
                          <span className="inv-doc-screen__link">
                            {row.documentoSecuencia || `${row.tipoPrefijo}-${String(row.secuencia).padStart(7, "0")}`}
                          </span>
                        </td>
                        <td style={{ whiteSpace: "nowrap" }}>{formatDateDisplay(row.fechaDocumento) || "—"}</td>
                        <td><span className="fac-ops__tipo-badge">{row.tipoPrefijo}</span></td>
                        <td style={{ maxWidth: 180, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{row.nombreCliente ?? "—"}</td>
                        <td style={{ fontFamily: "monospace", fontSize: "0.78rem" }}>{row.ncf ?? "—"}</td>
                        <td className="text-right" style={{ fontWeight: 600 }}>{fmt(row.total)}</td>
                        <td><EstadoBadge e={row.estado as DocEstado} /></td>
                        <td onClick={(e) => e.stopPropagation()}>
                          <div className="inv-doc-screen__row-actions">
                            {canView ? (
                              <button type="button" title="Visualizar" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--view" onClick={() => void openDetail(row.idDocumento)}>
                                <Eye size={14} />
                              </button>
                            ) : null}
                            {canPrint ? (
                              <button type="button" title="Reimprimir" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--print" onClick={() => setPrintDoc(row)}>
                                <Printer size={14} />
                              </button>
                            ) : null}
                            {canEdit && row.estado === "I" ? (
                              <button type="button" title="Editar" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--edit" onClick={() => void openEdit(row)}>
                                <Pencil size={14} />
                              </button>
                            ) : null}
                            {canReturn && row.estado !== "N" && row.tipoPrefijo.toUpperCase().startsWith("FAC") ? (
                              <button type="button" title="Devolución / NC" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--return" onClick={() => void abrirDevolucion(row)}>
                                <RotateCcw size={14} />
                              </button>
                            ) : null}
                            {canVoid && row.estado === "I" ? (
                              <button type="button" title="Anular" className="icon-button inv-doc-screen__action-btn inv-doc-screen__action-btn--void" onClick={() => { setAnularId(row.idDocumento); setMotivoAnulacion("") }}>
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

              {totalRegistros > 0 && (
                <div className="inv-doc-screen__pagination">
                  <div className="inv-doc-screen__pagination-info">
                    <label>
                      <span>Por página</span>
                      <select
                        value={pageSize === 0 ? "all" : String(pageSize)}
                        onChange={(e) => {
                          const nextPageSize = e.target.value === "all" ? 0 : Number(e.target.value)
                          setPageSize(nextPageSize)
                          void loadList(0, nextPageSize)
                        }}
                      >
                        <option value="10">10</option>
                        <option value="25">25</option>
                        <option value="50">50</option>
                        <option value="100">100</option>
                        <option value="all">Ver todos</option>
                      </select>
                    </label>
                    <span>
                      {pageSize === 0 ? rows.length : pageOffset + 1}
                      –{pageSize === 0 ? rows.length : Math.min(pageOffset + pageSize, totalRegistros)} de {totalRegistros}
                    </span>
                  </div>
                  <div className="inv-doc-screen__pagination-actions">
                    <button type="button" className="secondary-button" disabled={pageSize === 0 || pageOffset === 0 || listLoading} onClick={() => void loadList(0)}>«</button>
                    <button type="button" className="secondary-button" disabled={pageSize === 0 || pageOffset === 0 || listLoading} onClick={() => void loadList(Math.max(0, pageOffset - pageSize))}>‹</button>
                    <span>Página {currentPage} de {totalPages}</span>
                    <button type="button" className="secondary-button" disabled={pageSize === 0 || pageOffset + pageSize >= totalRegistros || listLoading} onClick={() => void loadList(pageOffset + pageSize)}>›</button>
                    <button type="button" className="secondary-button" disabled={pageSize === 0 || pageOffset + pageSize >= totalRegistros || listLoading} onClick={() => void loadList((totalPages - 1) * pageSize)}>»</button>
                  </div>
                </div>
              )}

              {false && totalRegistros > pageSize && (
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0.6rem 0.75rem", borderTop: "1px solid var(--line)", fontSize: "0.82rem", color: "var(--muted)" }}>
                  <span>Por página {pageSize} · {pageOffset + 1}–{Math.min(pageOffset + pageSize, totalRegistros)} de {totalRegistros}</span>
                  <div style={{ display: "flex", gap: "0.4rem" }}>
                    <button type="button" className="ghost-button" disabled={pageOffset === 0 || listLoading} onClick={() => void loadList(0)}>«</button>
                    <button type="button" className="ghost-button" disabled={pageOffset === 0 || listLoading} onClick={() => void loadList(Math.max(0, pageOffset - pageSize))}>‹</button>
                    <span style={{ padding: "0.25rem 0.5rem" }}>Página {Math.floor(pageOffset / pageSize) + 1} de {Math.ceil(totalRegistros / pageSize)}</span>
                    <button type="button" className="ghost-button" disabled={pageOffset + pageSize >= totalRegistros || listLoading} onClick={() => void loadList(pageOffset + pageSize)}>›</button>
                    <button type="button" className="ghost-button" disabled={pageOffset + pageSize >= totalRegistros || listLoading} onClick={() => void loadList((Math.ceil(totalRegistros / pageSize) - 1) * pageSize)}>»</button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </section>

      {/* Modal Anular */}
      {anularId !== null && (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon" style={{ background: "var(--rose-bg,#ffecef)", color: "var(--rose-text,#d91c5c)" }}><Ban size={18} /></div>
              <div><h3 className="modal-card__title">Anular Documento</h3><p className="modal-card__subtitle">Esta acción no se puede deshacer.</p></div>
              <button type="button" className="modal-card__close" onClick={() => setAnularId(null)}><X size={16} /></button>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <label className="field-label">Motivo <span style={{ color: "var(--rose-text,#d91c5c)" }}>*</span></label>
              <textarea className="input" rows={3} autoFocus value={motivoAnulacion} onChange={(e) => setMotivoAnulacion(e.target.value)} placeholder="Describe el motivo..." maxLength={500} />
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setAnularId(null)} disabled={anulando}>Cancelar</button>
              <button type="button" className="danger-button" disabled={!motivoAnulacion.trim() || anulando} onClick={() => void ejecutarAnulacion()}>
                {anulando ? <><Loader2 size={14} className="spin" /> Anulando...</> : <><Ban size={14} /> Confirmar</>}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Devolución */}
      {devDoc !== null && (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--elevated" style={{ maxWidth: 680 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon" style={{ background: "rgba(245,158,11,0.12)", color: "#b45309" }}><RotateCcw size={18} /></div>
              <div><h3 className="modal-card__title">Devolución — Nota de Crédito</h3><p className="modal-card__subtitle">Factura #{devDoc.secuencia} · {devDoc.nombreCliente ?? "Sin cliente"}</p></div>
              <button type="button" className="modal-card__close" onClick={() => setDevDoc(null)} disabled={devGenerando}><X size={16} /></button>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              {devLoading ? (
                <div style={{ textAlign: "center", padding: "1.5rem", color: "var(--muted)" }}><Loader2 size={18} className="spin" /> Cargando...</div>
              ) : (
                <>
                  <p style={{ fontSize: "0.8rem", color: "var(--muted)" }}>Ajusta las cantidades a devolver. Poner 0 excluye la línea.</p>
                  <div style={{ overflowX: "auto" }}>
                    <table className="inv-doc-screen__table" style={{ fontSize: "0.82rem" }}>
                      <thead><tr><th>Descripción</th><th className="text-right">Cant. Orig.</th><th className="text-right">Devolver</th><th className="text-right">Precio</th><th className="text-right">Total</th></tr></thead>
                      <tbody>
                        {devLineas.map((l, i) => (
                          <tr key={l.idDocumentoDetalle}>
                            <td>{l.descripcion}</td>
                            <td className="text-right">{l.cantidad}</td>
                            <td className="text-right" style={{ width: 90 }}>
                              <input type="number" min={0} max={l.cantidad} step={1} value={l.cantDevolucion}
                                style={{ width: "100%", textAlign: "right", padding: "2px 4px", border: "1px solid var(--line)", borderRadius: 4, fontSize: "0.82rem" }}
                                onChange={(e) => { const v = Math.min(l.cantidad, Math.max(0, Number(e.target.value))); setDevLineas((prev) => prev.map((x, j) => j === i ? { ...x, cantDevolucion: v } : x)) }} />
                            </td>
                            <td className="text-right">{fmt(l.precioBase)}</td>
                            <td className="text-right" style={{ fontWeight: 600 }}>{fmt(l.totalLinea * (l.cantDevolucion / (l.cantidad || 1)))}</td>
                          </tr>
                        ))}
                      </tbody>
                      <tfoot>
                        <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                          <td colSpan={4} style={{ textAlign: "right", paddingRight: "0.75rem" }}>Total a devolver</td>
                          <td className="text-right">{fmt(devLineas.reduce((s, l) => s + l.totalLinea * (l.cantDevolucion / (l.cantidad || 1)), 0))}</td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>
                  <label className="field-label" style={{ marginTop: "0.5rem" }}>Motivo (opcional)</label>
                  <textarea className="input" rows={2} value={devMotivo} onChange={(e) => setDevMotivo(e.target.value)} placeholder="Razón de la devolución..." maxLength={500} />
                </>
              )}
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setDevDoc(null)} disabled={devGenerando}>Cancelar</button>
              <button type="button" className="warning-button" disabled={devLoading || devGenerando || devLineas.every((l) => l.cantDevolucion === 0)} onClick={() => void ejecutarDevolucion()}>
                {devGenerando ? <><Loader2 size={14} className="spin" /> Generando...</> : <><RotateCcw size={14} /> Generar Nota de Crédito</>}
              </button>
            </div>
          </div>
        </div>
      )}
      {printDoc !== null && (
        <div className="modal-backdrop" onClick={() => printingFormat ? null : setPrintDoc(null)}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><Printer size={18} /></div>
              <div>
                <h3 className="modal-card__title">Formato de impresión</h3>
                <p className="modal-card__subtitle">{printDoc.documentoSecuencia || `${printDoc.tipoPrefijo}-${String(printDoc.secuencia).padStart(7, "0")}`}</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <button type="button" className="secondary-button" onClick={() => void printFactura(printDoc, "letter")} disabled={printingFormat !== null}>
                <Printer size={14} /> {printingFormat === "letter" ? "Generando..." : "POS 8 1/2 x 11"}
              </button>
              <button type="button" className="secondary-button" onClick={() => void printFactura(printDoc, "ticket")} disabled={printingFormat !== null}>
                <Printer size={14} /> {printingFormat === "ticket" ? "Generando..." : "POS 80mm"}
              </button>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="ghost-button" onClick={() => setPrintDoc(null)} disabled={printingFormat !== null}>Cancelar</button>
            </div>
          </div>
        </div>
      )}
      </>
    )
  }

  // ══════════════════════════════════════════════════════════════════
  // RENDER: DETAIL
  // ══════════════════════════════════════════════════════════════════
  if (view === "detail") {
    const d = selectedDoc
    return (
      <>
      <section className="data-panel">
        <div className="inv-doc-screen">

          {/* Top bar */}
          <div className="inv-doc-detail-topbar">
            {/* legacy nav removed
              <button type="button" className="inv-doc-detail-topbar__nav-button" onClick={() => setView("list")}>
                <ChevronLeft size={14} /> Lista
              </button>
              <button type="button" className="icon-button inv-doc-detail-topbar__arrow-button" disabled={selectedIndex <= 0} onClick={() => void navigateDetail("first")} title="Primero"><ChevronsLeft size={14} /></button>
              <button type="button" className="icon-button inv-doc-detail-topbar__arrow-button" disabled={selectedIndex <= 0} onClick={() => void navigateDetail("prev")} title="Anterior"><ChevronLeft size={14} /></button>
              <span className="inv-doc-detail-topbar__position">
                {selectedIndex >= 0 ? `${selectedIndex + 1} / ${filteredRows.length}` : "—"}
              </span>
              <button type="button" className="icon-button inv-doc-detail-topbar__arrow-button" disabled={selectedIndex >= filteredRows.length - 1} onClick={() => void navigateDetail("next")} title="Siguiente"><ChevronRight size={14} /></button>
              <button type="button" className="icon-button inv-doc-detail-topbar__arrow-button" disabled={selectedIndex >= filteredRows.length - 1} onClick={() => void navigateDetail("last")} title="Último"><ChevronsRight size={14} /></button>
            </div>
            */}
            <div className="inv-doc-detail-topbar__actions">
              <button type="button" className="secondary-button" disabled={selectedIndex <= 0} onClick={() => void navigateDetail("first")}>
                <ChevronsLeft size={14} /> Primero
              </button>
              <button type="button" className="secondary-button" disabled={selectedIndex <= 0} onClick={() => void navigateDetail("prev")}>
                <ChevronLeft size={14} /> Anterior
              </button>
              <button type="button" className="secondary-button" disabled={selectedIndex >= filteredRows.length - 1} onClick={() => void navigateDetail("next")}>
                Siguiente <ChevronRight size={14} />
              </button>
              <button type="button" className="secondary-button" disabled={selectedIndex >= filteredRows.length - 1} onClick={() => void navigateDetail("last")}>
                Ultimo <ChevronsRight size={14} />
              </button>
              {d && canPrint && d.doc.estado !== "N" && (
                <button type="button" className="secondary-button" onClick={() => setPrintDoc(d.doc)}><Printer size={14} /> Reimprimir</button>
              )}
              {d && canEdit && d.doc.estado === "I" && (
                <button type="button" className="secondary-button" onClick={() => void openEdit(d.doc)}><Pencil size={14} /> Editar</button>
              )}
              {d && canReturn && d.doc.estado !== "N" && d.doc.tipoPrefijo.toUpperCase().startsWith("FAC") && (
                <button type="button" className="warning-button" onClick={() => void abrirDevolucion(d.doc)}><RotateCcw size={14} /> Devolución</button>
              )}
              {d && canVoid && d.doc.estado === "I" && (
                <button type="button" className="danger-button" onClick={() => { setAnularId(d.doc.idDocumento); setMotivoAnulacion("") }}><Ban size={14} /> Anular</button>
              )}
              <button type="button" className="secondary-button" onClick={() => setView("list")}>
                <X size={14} /> Cerrar
              </button>
            </div>
          </div>

          {detailLoading || !d ? (
            <div style={{ textAlign: "center", padding: "3rem", color: "var(--muted)" }}><Loader2 size={24} className="spin" /></div>
          ) : (
            <>
              {/* Header info */}
              <div className="inv-doc-detail-header">
                <div className="inv-doc-detail-header__grid">
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">Fecha</span>
                    <span className="inv-doc-detail-header__value">{formatDateDisplay(d.doc.fechaDocumento) || "—"}</span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">Documento</span>
                    <span className="inv-doc-detail-header__value" style={{ fontWeight: 700 }}>{d.doc.documentoSecuencia || `${d.doc.tipoPrefijo}-${String(d.doc.secuencia).padStart(7, "0")}`}</span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">Estado</span>
                    <span className="inv-doc-detail-header__value"><EstadoBadge e={d.doc.estado as DocEstado} /></span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">Cliente</span>
                    <span className="inv-doc-detail-header__value">{d.doc.nombreCliente ?? "—"}</span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">RNC</span>
                    <span className="inv-doc-detail-header__value" style={{ fontFamily: "monospace" }}>{d.doc.rncCliente ?? "—"}</span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">NCF</span>
                    <span className="inv-doc-detail-header__value" style={{ fontFamily: "monospace" }}>{d.doc.ncf ?? "—"}</span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">Punto Emisión</span>
                    <span className="inv-doc-detail-header__value">{d.doc.puntoEmisionNombre ?? "—"}</span>
                  </div>
                  <div className="inv-doc-detail-header__field">
                    <span className="inv-doc-detail-header__label">Usuario</span>
                    <span className="inv-doc-detail-header__value">{d.doc.usuarioNombre ?? "—"}</span>
                  </div>
                  {d.doc.comentario && (
                    <div className="inv-doc-detail-header__field" style={{ gridColumn: "1 / -1" }}>
                      <span className="inv-doc-detail-header__label">Comentario</span>
                      <span className="inv-doc-detail-header__value">{d.doc.comentario}</span>
                    </div>
                  )}
                </div>
              </div>

              <div className="inv-doc-screen__table-wrap" style={{ marginTop: "0.75rem" }}>
                <div className="inv-doc-grid__tabs" style={{ marginBottom: "0.6rem" }}>
                  <button type="button" className={detailTab === "detail" ? "filter-pill is-active" : "filter-pill"} onClick={() => setDetailTab("detail")}>
                    Detalle actual
                  </button>
                  <button type="button" className={detailTab === "history" ? "filter-pill is-active" : "filter-pill"} onClick={() => setDetailTab("history")}>
                    Historial de cambios
                  </button>
                </div>
                {detailTab === "detail" ? null : (
                  <table className="inv-doc-grid__table" style={{ marginBottom: "0.75rem" }}>
                    <thead>
                      <tr>
                        <th>Estado</th>
                        <th>Fecha</th>
                        <th>Usuario</th>
                        <th>Comentario</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr>
                        <td>{ESTADO_LABEL[d.doc.estado as DocEstado] ?? d.doc.estado}</td>
                        <td>{formatDateDisplay(d.doc.fechaDocumento) || "â€”"}</td>
                        <td>{d.doc.usuarioNombre ?? "â€”"}</td>
                        <td>Historial aun no conectado para Facturas.</td>
                      </tr>
                    </tbody>
                  </table>
                )}
              </div>

              {/* Lines */}
              {detailTab === "detail" && <div className="inv-doc-screen__list-card" style={{ marginTop: "0.75rem" }}>
                <div className="inv-doc-screen__list-head">
                  <h3><FileText size={14} /> Líneas del Documento</h3>
                </div>
                <div className="inv-doc-screen__table-wrap">
                  <table className="inv-doc-screen__table">
                    <thead>
                      <tr>
                        <th>#</th><th>Código</th><th>Descripción</th>
                        <th className="text-right">Cant.</th>
                        <th className="text-right">Precio</th>
                        <th className="text-right">ITBIS%</th>
                        <th className="text-right">Desc.</th>
                        <th className="text-right">Sub-Total</th>
                        <th className="text-right">ITBIS</th>
                        <th className="text-right">Total</th>
                      </tr>
                    </thead>
                    <tbody>
                      {d.lineas.map((l) => (
                        <tr key={l.idDocumentoDetalle}>
                          <td>{l.numeroLinea}</td>
                          <td style={{ fontFamily: "monospace", fontSize: "0.78rem" }}>{l.codigo ?? "—"}</td>
                          <td>{l.descripcion}</td>
                          <td className="text-right">{l.cantidad}</td>
                          <td className="text-right">{fmt(l.precioBase)}</td>
                          <td className="text-right">{l.aplicaImpuesto ? `${l.porcentajeImpuesto}%` : "—"}</td>
                          <td className="text-right">{l.descuentoLinea > 0 ? fmt(l.descuentoLinea) : "—"}</td>
                          <td className="text-right">{fmt(l.subTotalLinea)}</td>
                          <td className="text-right">{fmt(l.impuestoLinea)}</td>
                          <td className="text-right" style={{ fontWeight: 600 }}>{fmt(l.totalLinea)}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                        <td colSpan={7} style={{ textAlign: "right", paddingRight: "0.75rem" }}>Totales</td>
                        <td className="text-right">{fmt(d.lineas.reduce((s, l) => s + l.subTotalLinea, 0))}</td>
                        <td className="text-right">{fmt(d.lineas.reduce((s, l) => s + l.impuestoLinea, 0))}</td>
                        <td className="text-right">{fmt(d.lineas.reduce((s, l) => s + l.totalLinea, 0))}</td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              </div>}

              {/* Pagos */}
              {d.pagos.length > 0 && (
                <div className="inv-doc-screen__list-card" style={{ marginTop: "0.75rem" }}>
                  <div className="inv-doc-screen__list-head"><h3><FileText size={14} /> Formas de Pago</h3></div>
                  <div className="inv-doc-screen__table-wrap">
                    <table className="inv-doc-screen__table">
                      <thead><tr><th>Forma de Pago</th><th>Tipo</th><th className="text-right">Monto</th><th>Referencia</th></tr></thead>
                      <tbody>
                        {d.pagos.map((p) => (
                          <tr key={p.idPago}>
                            <td>{p.formaPagoNombre}</td>
                            <td>{p.tipoValor}</td>
                            <td className="text-right" style={{ fontWeight: 600 }}>{fmt(p.monto)}</td>
                            <td>{p.referencia ?? "—"}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </section>

      {printDoc !== null && (
        <div className="modal-backdrop" onClick={() => printingFormat ? null : setPrintDoc(null)}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><Printer size={18} /></div>
              <div>
                <h3 className="modal-card__title">Formato de impresiÃ³n</h3>
                <p className="modal-card__subtitle">{printDoc.documentoSecuencia || `${printDoc.tipoPrefijo}-${String(printDoc.secuencia).padStart(7, "0")}`}</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <button type="button" className="secondary-button" onClick={() => void printFactura(printDoc, "letter")} disabled={printingFormat !== null}>
                <Printer size={14} /> {printingFormat === "letter" ? "Generando..." : "POS 8 1/2 x 11"}
              </button>
              <button type="button" className="secondary-button" onClick={() => void printFactura(printDoc, "ticket")} disabled={printingFormat !== null}>
                <Printer size={14} /> {printingFormat === "ticket" ? "Generando..." : "POS 80mm"}
              </button>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="ghost-button" onClick={() => setPrintDoc(null)} disabled={printingFormat !== null}>Cancelar</button>
            </div>
          </div>
        </div>
      )}

      {/* Modals (same as list) */}
      {anularId !== null && (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon" style={{ background: "var(--rose-bg,#ffecef)", color: "var(--rose-text,#d91c5c)" }}><Ban size={18} /></div>
              <div><h3 className="modal-card__title">Anular Documento</h3><p className="modal-card__subtitle">Esta acción no se puede deshacer.</p></div>
              <button type="button" className="modal-card__close" onClick={() => setAnularId(null)}><X size={16} /></button>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <label className="field-label">Motivo <span style={{ color: "var(--rose-text,#d91c5c)" }}>*</span></label>
              <textarea className="input" rows={3} autoFocus value={motivoAnulacion} onChange={(e) => setMotivoAnulacion(e.target.value)} placeholder="Describe el motivo..." maxLength={500} />
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setAnularId(null)} disabled={anulando}>Cancelar</button>
              <button type="button" className="danger-button" disabled={!motivoAnulacion.trim() || anulando} onClick={() => void ejecutarAnulacion()}>
                {anulando ? <><Loader2 size={14} className="spin" /> Anulando...</> : <><Ban size={14} /> Confirmar</>}
              </button>
            </div>
          </div>
        </div>
      )}
      {devDoc !== null && (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--elevated" style={{ maxWidth: 680 }} onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon" style={{ background: "rgba(245,158,11,0.12)", color: "#b45309" }}><RotateCcw size={18} /></div>
              <div><h3 className="modal-card__title">Devolución — Nota de Crédito</h3><p className="modal-card__subtitle">Factura #{devDoc.secuencia} · {devDoc.nombreCliente ?? "Sin cliente"}</p></div>
              <button type="button" className="modal-card__close" onClick={() => setDevDoc(null)} disabled={devGenerando}><X size={16} /></button>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              {devLoading ? (
                <div style={{ textAlign: "center", padding: "1.5rem", color: "var(--muted)" }}><Loader2 size={18} className="spin" /> Cargando...</div>
              ) : (
                <>
                  <p style={{ fontSize: "0.8rem", color: "var(--muted)" }}>Ajusta las cantidades a devolver. Poner 0 excluye la línea.</p>
                  <div style={{ overflowX: "auto" }}>
                    <table className="inv-doc-screen__table" style={{ fontSize: "0.82rem" }}>
                      <thead><tr><th>Descripción</th><th className="text-right">Cant. Orig.</th><th className="text-right">Devolver</th><th className="text-right">Precio</th><th className="text-right">Total</th></tr></thead>
                      <tbody>
                        {devLineas.map((l, i) => (
                          <tr key={l.idDocumentoDetalle}>
                            <td>{l.descripcion}</td>
                            <td className="text-right">{l.cantidad}</td>
                            <td className="text-right" style={{ width: 90 }}>
                              <input type="number" min={0} max={l.cantidad} step={1} value={l.cantDevolucion}
                                style={{ width: "100%", textAlign: "right", padding: "2px 4px", border: "1px solid var(--line)", borderRadius: 4, fontSize: "0.82rem" }}
                                onChange={(e) => { const v = Math.min(l.cantidad, Math.max(0, Number(e.target.value))); setDevLineas((prev) => prev.map((x, j) => j === i ? { ...x, cantDevolucion: v } : x)) }} />
                            </td>
                            <td className="text-right">{fmt(l.precioBase)}</td>
                            <td className="text-right" style={{ fontWeight: 600 }}>{fmt(l.totalLinea * (l.cantDevolucion / (l.cantidad || 1)))}</td>
                          </tr>
                        ))}
                      </tbody>
                      <tfoot>
                        <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                          <td colSpan={4} style={{ textAlign: "right", paddingRight: "0.75rem" }}>Total a devolver</td>
                          <td className="text-right">{fmt(devLineas.reduce((s, l) => s + l.totalLinea * (l.cantDevolucion / (l.cantidad || 1)), 0))}</td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>
                  <label className="field-label" style={{ marginTop: "0.5rem" }}>Motivo (opcional)</label>
                  <textarea className="input" rows={2} value={devMotivo} onChange={(e) => setDevMotivo(e.target.value)} placeholder="Razón de la devolución..." maxLength={500} />
                </>
              )}
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setDevDoc(null)} disabled={devGenerando}>Cancelar</button>
              <button type="button" className="warning-button" disabled={devLoading || devGenerando || devLineas.every((l) => l.cantDevolucion === 0)} onClick={() => void ejecutarDevolucion()}>
                {devGenerando ? <><Loader2 size={14} className="spin" /> Generando...</> : <><RotateCcw size={14} /> Generar Nota de Crédito</>}
              </button>
            </div>
          </div>
        </div>
      )}
      </>
    )
  }

  // ══════════════════════════════════════════════════════════════════
  // RENDER: NEW / EDIT FORM
  // ══════════════════════════════════════════════════════════════════
  return (
    <>
    <section className="data-panel">
      <div className="inv-doc-screen">

        {/* Top bar */}
        <div className="inv-doc-detail-topbar">
          {editingId ? <span className="chip chip--neutral">Editando FAC-{String(editingId).padStart(4, "0")}</span> : null}
          <div className="inv-doc-detail-topbar__actions">
            <button type="button" className="secondary-button" onClick={() => { resetForm(); setView("list") }}>
              <X size={14} /> Cancelar
            </button>
            <button type="button" className="primary-button" onClick={() => void saveDocument()} disabled={saving}>
              {saving ? <><Loader2 size={14} className="spin" /> Guardando...</> : <><Save size={14} /> Guardar</>}
            </button>
          </div>
        </div>

        {/* Header fields */}
        <div className="inv-doc-detail-header">
          <div className="inv-doc-detail-header__grid">
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">Tipo Documento <span style={{ color: "var(--rose-text,#d91c5c)" }}>*</span></span>
              <select className="input" value={idTipoDocumento ?? ""} onChange={(e) => setIdTipoDocumento(e.target.value ? Number(e.target.value) : null)}>
                <option value="">— Seleccionar —</option>
                {!hasTipoDocumentoOption && idTipoDocumento != null && editingTipoDocumentoLabel ? <option value={idTipoDocumento}>{editingTipoDocumentoLabel}</option> : null}
                {tiposDocumento.map((t) => <option key={t.id} value={t.id}>{t.prefijo} — {t.description}</option>)}
              </select>
            </label>
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">Fecha <span style={{ color: "var(--rose-text,#d91c5c)" }}>*</span></span>
              <input
                type="text"
                inputMode="numeric"
                className="input"
                value={fechaInput}
                placeholder="dd/MM/yyyy"
                onChange={(e) => setFechaInput(e.target.value)}
                onBlur={() => {
                  const normalized = parseDisplayDateInput(fechaInput)
                  if (!normalized) {
                    setFechaInput(formatDateDisplay(fecha))
                    toast.error("La fecha debe estar en formato dd/MM/yyyy.")
                    return
                  }
                  setFecha(normalized)
                  setFechaInput(formatDateDisplay(normalized))
                }}
              />
            </label>
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">Punto Emisión <span style={{ color: "var(--rose-text,#d91c5c)" }}>*</span></span>
              <select className="input" value={idPuntoEmision || ""} onChange={(e) => setIdPuntoEmision(e.target.value ? Number(e.target.value) : 0)}>
                <option value="">— Seleccionar —</option>
                {!hasPuntoEmisionOption && idPuntoEmision > 0 && editingPuntoEmisionLabel ? <option value={idPuntoEmision}>{editingPuntoEmisionLabel}</option> : null}
                {emissionPoints.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </label>
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">Documento (auto)</span>
              <input type="text" className="input" readOnly disabled value={documentoPreview} />
            </label>
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">Cliente</span>
              <select className="input" value={idCliente ?? ""} onChange={(e) => { const v = e.target.value ? Number(e.target.value) : null; setIdCliente(v); if (v) { const c = customers.find((x) => x.id === v); setRncCliente(c?.documento ?? ""); } }}>
                <option value="">— Sin cliente / manual —</option>
                {!hasClienteOption && idCliente != null && editingClienteLabel ? <option value={idCliente}>{editingClienteLabel}</option> : null}
                {customers.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </label>
            {!idCliente && (
              <label className="inv-doc-detail-header__field">
                <span className="inv-doc-detail-header__label">Nombre Cliente (manual)</span>
                <input type="text" className="input" value={nombreClienteManual} onChange={(e) => setNombreClienteManual(e.target.value)} placeholder="Nombre del cliente..." maxLength={200} />
              </label>
            )}
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">RNC / Cédula</span>
              <input type="text" className="input" value={rncCliente} onChange={(e) => setRncCliente(e.target.value)} placeholder="000-0000000-0" maxLength={11} />
            </label>
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">Tipo NCF</span>
              <select className="input" value={idTipoNCF ?? ""} onChange={(e) => setIdTipoNCF(e.target.value ? Number(e.target.value) : null)}>
                <option value="">— Sin NCF —</option>
                {!hasTipoNCFOption && idTipoNCF != null && editingTipoNCFLabel ? <option value={idTipoNCF}>{editingTipoNCFLabel}</option> : null}
                {tiposNCF.map((n) => <option key={n.id} value={n.id}>{n.codigo} — {n.nombre}</option>)}
              </select>
            </label>
            <label className="inv-doc-detail-header__field">
              <span className="inv-doc-detail-header__label">NCF</span>
              <input type="text" className="input" value={ncf} onChange={(e) => setNcf(e.target.value)} placeholder="B0100000001" maxLength={19} style={{ fontFamily: "monospace" }} />
            </label>
          </div>
        </div>

        <div className="inv-doc-grid" style={{ marginTop: "0.75rem" }}>
          <div className="inv-doc-grid__header">
            <div className="inv-doc-grid__tabs">
              <button type="button" className={formTab === "detail" ? "filter-pill is-active" : "filter-pill"} onClick={() => setFormTab("detail")}>
                Detalle
              </button>
              <button type="button" className={formTab === "comments" ? "filter-pill is-active" : "filter-pill"} onClick={() => setFormTab("comments")}>
                Comentarios / Observaciones
              </button>
            </div>
            {formTab === "detail" ? (
              <button type="button" className="secondary-button" onClick={addLinea} style={{ marginLeft: "auto" }}>
                <Plus size={13} /> Linea
              </button>
            ) : null}
          </div>
          {formTab === "detail" ? (
            <table className="inv-doc-grid__table">
              <thead>
                <tr>
                  <th className="col-linea">#</th>
                  <th className="col-codigo">Codigo</th>
                  <th className="col-desc">Descripcion</th>
                  <th className="col-cant">Cantidad</th>
                  <th className="col-costo">Precio</th>
                  <th className="col-costo">ITBIS%</th>
                  <th className="col-costo">Desc.</th>
                  <th className="col-costo">Sub-Total</th>
                  <th className="col-total">Total</th>
                  <th className="col-actions" />
                </tr>
              </thead>
              <tbody>
                {lineas.map((l, index) => (
                  <tr key={l.key}>
                    <td className="text-center">{index + 1}</td>
                    <td>
                      <div className="inv-doc-grid__code-cell">
                        <input
                          type="text"
                          value={l.codigo}
                          placeholder="Codigo o scan"
                          onChange={(e) => updateLinea(l.key, { codigo: e.target.value })}
                          onBlur={() => void resolveLineByCode(l.key, l.codigo)}
                          onKeyDown={(e) => {
                            if (e.key === "Enter") {
                              e.preventDefault()
                              void resolveLineByCode(l.key, l.codigo)
                            }
                          }}
                          style={{ fontFamily: "monospace" }}
                        />
                        <button type="button" className="inv-doc-grid__search-btn" title="Buscar producto" onClick={() => openSearch(l.key)}>
                          <Search size={14} />
                        </button>
                      </div>
                    </td>
                    <td><input type="text" value={l.descripcion} placeholder="Descripcion..." onChange={(e) => updateLinea(l.key, { descripcion: e.target.value })} /></td>
                    <td><input type="number" min={0} step={0.01} value={l.cantidad} className="text-right" onChange={(e) => updateLinea(l.key, { cantidad: Number(e.target.value) })} /></td>
                    <td><input type="number" min={0} step={0.01} value={l.precioBase} className="text-right" onChange={(e) => updateLinea(l.key, { precioBase: Number(e.target.value) })} /></td>
                    <td><input type="number" min={0} max={100} step={1} value={l.porcentajeImpuesto} className="text-right" onChange={(e) => updateLinea(l.key, { porcentajeImpuesto: Number(e.target.value) })} /></td>
                    <td><input type="number" min={0} step={0.01} value={l.descuentoLinea} className="text-right" onChange={(e) => updateLinea(l.key, { descuentoLinea: Number(e.target.value) })} /></td>
                    <td className="text-right inv-doc-grid__total">{fmt(l.subTotal)}</td>
                    <td className="text-right inv-doc-grid__total">{fmt(l.total)}</td>
                    <td>
                      <button type="button" className="icon-button inv-doc-grid__remove-btn" onClick={() => removeLinea(l.key)} title="Eliminar">
                        <Trash2 size={13} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr>
                  <td colSpan={7} className="text-right">
                    <span style={{ fontSize: "0.78rem", color: "var(--muted)", fontWeight: 500 }}>Sub: {fmt(totales.sub)} | Desc: {fmt(totales.desc)} | ITBIS: {fmt(totales.imp)}</span>
                  </td>
                  <td className="text-right inv-doc-grid__footer-total"><strong>Total Documento</strong></td>
                  <td colSpan={2} className="text-right inv-doc-grid__footer-total"><strong>{fmt(totales.total)}</strong></td>
                </tr>
              </tfoot>
            </table>
          ) : (
            <div style={{ padding: "0.9rem" }}>
              <label className="field-label" style={{ marginBottom: "0.45rem", display: "block" }}>Comentarios / Observaciones</label>
              <textarea className="input" rows={5} value={comentario} onChange={(e) => setComentario(e.target.value)} placeholder="Observaciones..." maxLength={500} style={{ width: "100%", resize: "vertical" }} />
            </div>
          )}
        </div>

        {false && (<>
          <div className="inv-doc-screen__list-card" style={{ marginTop: "0.75rem" }}>
          <div className="inv-doc-screen__list-head" style={{ justifyContent: "space-between" }}>
            <h3><FileText size={14} /> Líneas del Documento</h3>
            <button type="button" className="ghost-button" onClick={addLinea}><Plus size={13} /> Agregar Línea</button>
          </div>
          <div className="inv-doc-screen__table-wrap">
            <table className="inv-doc-screen__table" style={{ tableLayout: "fixed" }}>
              <colgroup>
                <col style={{ width: 130 }} />
                <col />
                <col style={{ width: 80 }} />
                <col style={{ width: 100 }} />
                <col style={{ width: 70 }} />
                <col style={{ width: 90 }} />
                <col style={{ width: 90 }} />
                <col style={{ width: 90 }} />
                <col style={{ width: 36 }} />
              </colgroup>
              <thead>
                <tr>
                  <th>Código</th>
                  <th>Descripción</th>
                  <th className="text-right">Cant.</th>
                  <th className="text-right">Precio</th>
                  <th className="text-right">ITBIS%</th>
                  <th className="text-right">Desc.</th>
                  <th className="text-right">Sub-Total</th>
                  <th className="text-right">Total</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {lineas.map((l) => (
                  <tr key={l.key}>
                    <td>
                      <div style={{ display: "flex", gap: 2 }}>
                        <input
                          type="text"
                          className="input"
                          value={l.codigo}
                          placeholder="Código..."
                          style={{ flex: 1, minWidth: 0, fontSize: "0.78rem", fontFamily: "monospace" }}
                          onChange={(e) => updateLinea(l.key, { codigo: e.target.value })}
                        />
                        <button type="button" className="icon-button" style={{ width: 26, height: 26, flexShrink: 0 }} title="Buscar producto" onClick={() => openSearch(l.key)}>
                          <Search size={12} />
                        </button>
                      </div>
                    </td>
                    <td>
                      <input type="text" className="input" value={l.descripcion} placeholder="Descripción..." style={{ width: "100%", fontSize: "0.82rem" }}
                        onChange={(e) => updateLinea(l.key, { descripcion: e.target.value })} />
                    </td>
                    <td>
                      <input type="number" className="input" value={l.cantidad} min={0} step={0.01} style={{ width: "100%", textAlign: "right", fontSize: "0.82rem" }}
                        onChange={(e) => updateLinea(l.key, { cantidad: Number(e.target.value) })} />
                    </td>
                    <td>
                      <input type="number" className="input" value={l.precioBase} min={0} step={0.01} style={{ width: "100%", textAlign: "right", fontSize: "0.82rem" }}
                        onChange={(e) => updateLinea(l.key, { precioBase: Number(e.target.value) })} />
                    </td>
                    <td>
                      <input type="number" className="input" value={l.porcentajeImpuesto} min={0} max={100} step={1} style={{ width: "100%", textAlign: "right", fontSize: "0.82rem" }}
                        onChange={(e) => updateLinea(l.key, { porcentajeImpuesto: Number(e.target.value) })} />
                    </td>
                    <td>
                      <input type="number" className="input" value={l.descuentoLinea} min={0} step={0.01} style={{ width: "100%", textAlign: "right", fontSize: "0.82rem" }}
                        onChange={(e) => updateLinea(l.key, { descuentoLinea: Number(e.target.value) })} />
                    </td>
                    <td className="text-right" style={{ fontFamily: "monospace", fontSize: "0.82rem" }}>{fmt(l.subTotal)}</td>
                    <td className="text-right" style={{ fontWeight: 600, fontFamily: "monospace", fontSize: "0.82rem" }}>{fmt(l.total)}</td>
                    <td>
                      <button type="button" className="icon-button" style={{ width: 26, height: 26, color: "var(--rose-text,#d91c5c)" }} onClick={() => removeLinea(l.key)} title="Eliminar línea">
                        <X size={12} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr style={{ background: "#f0f4f9", fontWeight: 700, borderTop: "2px solid var(--line)" }}>
                  <td colSpan={6} style={{ textAlign: "right", paddingRight: "0.75rem" }}>
                    <span style={{ fontSize: "0.78rem", color: "var(--muted)", fontWeight: 400 }}>Sub: {fmt(totales.sub)} | Desc: {fmt(totales.desc)} | ITBIS: {fmt(totales.imp)}</span>
                  </td>
                  <td colSpan={2} className="text-right" style={{ fontSize: "1rem" }}>Total: {fmt(totales.total)}</td>
                  <td />
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        </>)}
      </div>
    </section>

    {/* Product search modal */}
    {searchOpen && (
      <div className="modal-backdrop" onClick={() => setSearchOpen(false)}>
        <div className="modal-card" style={{ maxWidth: 560 }} onClick={(e) => e.stopPropagation()}>
          <div className="modal-card__header">
            <div className="modal-card__header-icon"><Search size={18} /></div>
            <div><h3 className="modal-card__title">Buscar Producto</h3></div>
            <button type="button" className="modal-card__close" onClick={() => setSearchOpen(false)}><X size={16} /></button>
          </div>
          <div className="modal-card__body" style={{ padding: "0.75rem" }}>
            <input ref={searchInputRef} type="text" className="input" placeholder="Buscar por código, nombre..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} autoFocus />
            <div style={{ maxHeight: 320, overflowY: "auto", marginTop: "0.5rem" }}>
              {searchLoading ? (
                <div style={{ textAlign: "center", padding: "1rem", color: "var(--muted)" }}><Loader2 size={16} className="spin" /> Buscando...</div>
              ) : searchResults.length === 0 && searchQuery.trim() ? (
                <div style={{ textAlign: "center", padding: "1rem", color: "var(--muted)", fontSize: "0.82rem" }}>Sin resultados.</div>
              ) : (
                <table className="inv-doc-screen__table" style={{ fontSize: "0.82rem" }}>
                  <thead><tr><th>Código</th><th>Nombre</th><th className="text-right">Precio</th></tr></thead>
                  <tbody>
                    {searchResults.map((p) => (
                      <tr key={p.id} style={{ cursor: "pointer" }} onClick={() => selectProduct(p)}>
                        <td style={{ fontFamily: "monospace" }}>{p.code}</td>
                        <td>{p.name}</td>
                        <td className="text-right">{fmt(p.price)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        </div>
      </div>
    )}
    </>
  )
}
