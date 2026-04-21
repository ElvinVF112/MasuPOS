"use client"

import {
  Banknote,
  ChevronDown,
  Clock3,
  CreditCard,
  FileText,
  Landmark,
  Loader2,
  FileClock,
  FilePlus2,
  HandCoins,
  Layers3,
  LogIn,
  MessageSquare,
  PackageSearch,
  Pencil,
  Percent,
  Plus,
  Search,
  ShieldAlert,
  ShieldCheck,
  ShoppingCart,
  SlidersHorizontal,
  Ticket,
  Trash2,
  UserRound,
  Warehouse,
  X,
} from "lucide-react"
import { useCallback, useEffect, useMemo, useRef, useState } from "react"
import { usePermissions } from "@/lib/permissions-context"
import { toast } from "sonner"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { navigateToWorkspaceTarget } from "@/lib/workspace-navigation"
import type {
  BranchRecord,
  CatalogoNCFRecord,
  CategoryRecord,
  CompanySettingsData,
  CurrencyRecord,
  DescuentoForUser,
  DescuentoRecord,
  EmissionPointRecord,
  FacDocumentoPOS,
  FacDocumentoPOSDetalle,
  FacFormaPagoRecord,
  FacTipoDocumentoRecord,
  OrderProductOption,
  PriceListWithProductPrice,
  TerceroRecord,
  WarehouseRecord,
} from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"

type BillingPosLine = {
  key: string
  productId: number
  code: string
  description: string
  quantity: number
  unit: string
  basePrice: number
  taxRate: number
  applyTax: boolean
  applyTip: boolean
  lineDiscount: number
  lineComment: string
}

type QuickTrayItem = BillingPosLine & { key: string }

type CurrentViewer = {
  userId: number
  idCaja?: number | null
  userType: "A" | "S" | "O"
  canDeletePosLines?: boolean
  canChangePosDate?: boolean
  username?: string
  fullName?: string
}

type LiveClockState = {
  date: string
  time: string
}

type Props = {
  company: CompanySettingsData
  branches: BranchRecord[]
  emissionPoints: EmissionPointRecord[]
  customers: TerceroRecord[]
  categories: CategoryRecord[]
  products: OrderProductOption[]
  documentTypes: FacTipoDocumentoRecord[]
  taxVoucherTypes: CatalogoNCFRecord[]
  currencies: CurrencyRecord[]
  warehouses: WarehouseRecord[]
  discounts: DescuentoRecord[]
}

const SIDE_ACTIONS = [
  { label: "Tipo de Documento", icon: Ticket },
  { label: "Cambiar Almacen", icon: Warehouse },
  { label: "Asignar Vendedor", icon: UserRound },
  { label: "Recibir Anticipo", icon: HandCoins },
  { label: "Importar Cotizaciones", icon: FilePlus2 },
  { label: "Importar Ordenes de Pedido", icon: Layers3 },
  { label: "Importar Conduces", icon: PackageSearch },
]

const INITIAL_LINE_KEY = "line-initial"

function createRuntimeKey(prefix: string) {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function getTodayIsoDate() {
  const now = new Date()
  const offsetMs = now.getTimezoneOffset() * 60000
  return new Date(now.getTime() - offsetMs).toISOString().slice(0, 10)
}

function hexToRgb(hex: string) {
  const normalized = hex.replace("#", "").trim()
  if (![3, 6].includes(normalized.length)) return null
  const full = normalized.length === 3
    ? normalized.split("").map((char) => char + char).join("")
    : normalized
  const value = Number.parseInt(full, 16)
  if (Number.isNaN(value)) return null
  return {
    r: (value >> 16) & 255,
    g: (value >> 8) & 255,
    b: value & 255,
  }
}

function rgbToHex(r: number, g: number, b: number) {
  return `#${[r, g, b].map((v) => Math.max(0, Math.min(255, Math.round(v))).toString(16).padStart(2, "0")).join("")}`
}

function softenHexColor(hex: string, amount = 0.82) {
  const rgb = hexToRgb(hex)
  if (!rgb) return "#eef4ff"
  return rgbToHex(
    rgb.r + (255 - rgb.r) * amount,
    rgb.g + (255 - rgb.g) * amount,
    rgb.b + (255 - rgb.b) * amount,
  )
}

function getReadableInk(hex: string) {
  const rgb = hexToRgb(hex)
  if (!rgb) return "#16324f"
  const luminance = (0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b) / 255
  return luminance > 0.65 ? "#16324f" : "#ffffff"
}

function roundMoney(value: number) {
  return Math.round(value * 100) / 100
}

function formatMoney(value: number) {
  return new Intl.NumberFormat("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value)
}

function toPositiveNumber(value: string | number, fallback = 0) {
  const normalized = typeof value === "number" ? value : Number(value)
  if (!Number.isFinite(normalized)) return fallback
  return normalized
}

function buildLine(product: OrderProductOption, key = INITIAL_LINE_KEY): BillingPosLine {
  return {
    key,
    productId: product.id,
    code: product.code || `PROD-${product.id}`,
    description: product.name,
    quantity: 1,
    unit: product.unitName || "UND",
    basePrice: product.price,
    taxRate: product.taxRate,
    applyTax: product.applyTax,
    applyTip: product.applyTip,
    lineDiscount: 0,
    lineComment: "",
  }
}

function buildEmptyLine(key = INITIAL_LINE_KEY): BillingPosLine {
  return {
    key,
    productId: 0,
    code: "",
    description: "",
    quantity: 1,
    unit: "UND",
    basePrice: 0,
    taxRate: 18,
    applyTax: true,
    applyTip: true,
    lineDiscount: 0,
    lineComment: "",
  }
}

function clearLineProductState(line: BillingPosLine): BillingPosLine {
  return {
    ...line,
    productId: 0,
    description: "",
    unit: "UND",
    basePrice: 0,
    taxRate: 18,
    applyTax: true,
    applyTip: true,
    lineDiscount: 0,
  }
}

function buildTrayItem(product: OrderProductOption): QuickTrayItem {
  const key = createRuntimeKey(`tray-${product.id}`)
  return {
    ...buildLine(product, key),
    key,
  }
}

function computeLineTotals(line: BillingPosLine, company: CompanySettingsData, selectedDocument: FacTipoDocumentoRecord | null) {
  const lineBase = roundMoney(line.basePrice * line.quantity)
  const lineTax = line.applyTax ? roundMoney(lineBase * (line.taxRate / 100)) : 0
  const lineTip = company.applyTip && selectedDocument?.aplicaPropina && line.applyTip
    ? roundMoney(lineBase * ((company.tipPercent || 0) / 100))
    : 0
  const finalPrice = roundMoney(
    line.basePrice
    + (line.applyTax ? line.basePrice * (line.taxRate / 100) : 0)
    + ((company.applyTip && selectedDocument?.aplicaPropina && line.applyTip) ? line.basePrice * ((company.tipPercent || 0) / 100) : 0),
  )
  const lineTotal = roundMoney(lineBase + lineTax + lineTip - line.lineDiscount)
  return { lineBase, lineTax, lineTip, finalPrice, lineTotal }
}

function isPrivilegedUserType(userType?: string | null) {
  return userType === "A" || userType === "S"
}

function withImageVersion(src: string | null | undefined) {
  if (!src) return ""
  const version = `${src.length}-${src.slice(0, 12).length}-${src.slice(-12).length}`
  if (src.startsWith("data:")) return `${src}#v=${version}`
  return src.includes("?") ? `${src}&v=${version}` : `${src}?v=${version}`
}

function getFormaPagoIcon(tipoValor: string, size = 28) {
  switch (tipoValor) {
    case "EF": return <Banknote size={size} />
    case "TC": return <CreditCard size={size} />
    case "CH": return <FileText size={size} />
    case "OV": return <Landmark size={size} />
    case "VC": return <HandCoins size={size} />
    case "NC": return <Percent size={size} />
    case "DV": return <Banknote size={size} />
    default:   return <CreditCard size={size} />
  }
}

export function BillingPosScreen({ company, branches, emissionPoints, customers, categories, products, documentTypes, taxVoucherTypes, currencies, warehouses, discounts }: Props) {
  const { hasPermission } = usePermissions()
  const [isClosingPos, setIsClosingPos] = useState(false)

  const visibleCategories = useMemo(() => {
    const allowed = categories.filter((category) => category.mostrarEnPOS)
    return allowed.length ? allowed : categories
  }, [categories])

  const productCategoryMeta = useMemo(() => {
    const map = new Map<string, {
      background: string
      button: string
      text: string
      image: string | null
      pastel: string
      ink: string
      border: string
    }>()
    for (const product of products) {
      if (!map.has(product.category)) {
        const base = product.categoryButtonColor || product.categoryButtonBackground || "#12467e"
        const pastel = softenHexColor(base, 0.82)
        map.set(product.category, {
          background: product.categoryButtonBackground,
          button: product.categoryButtonColor,
          text: product.categoryButtonText,
          image: product.categoryImage ?? null,
          pastel,
          ink: getReadableInk(pastel),
          border: softenHexColor(base, 0.55),
        })
      }
    }
    return map
  }, [products])

  const [selectedCategory, setSelectedCategory] = useState("all")
  const [optionsOpen, setOptionsOpen] = useState(false)
  const [quickPanelOpen, setQuickPanelOpen] = useState(false)
  const [liveClock, setLiveClock] = useState<LiveClockState>({ date: "", time: "" })
  const [clockUse24Hour, setClockUse24Hour] = useState(true)
  const [quickSearch, setQuickSearch] = useState("")
  const [activeLineKey, setActiveLineKey] = useState<string | null>(null)
  const [pickerTargetLineKey, setPickerTargetLineKey] = useState<string | null>(null)
  const [productSearchOpen, setProductSearchOpen] = useState(false)
  const [productSearchQuery, setProductSearchQuery] = useState("")
  const [productSearchCommitted, setProductSearchCommitted] = useState("")
  const [productSearchAutomode, setProductSearchAutomode] = useState(true)
  const [productSearchSelected, setProductSearchSelected] = useState<Map<number, number>>(new Map())
  const [currentViewer, setCurrentViewer] = useState<CurrentViewer | null>(null)
  const [activeCajaPosName, setActiveCajaPosName] = useState("Caja activa")
  const [confirmReset, setConfirmReset] = useState(false)
  const [confirmClosePos, setConfirmClosePos] = useState(false)
  const [editPriceLine, setEditPriceLine] = useState<BillingPosLine | null>(null)
  const [editPriceBase, setEditPriceBase] = useState("")
  const [editPriceFinal, setEditPriceFinal] = useState("")
  const [priceListsForLine, setPriceListsForLine] = useState<PriceListWithProductPrice[]>([])
  const [priceListsLoading, setPriceListsLoading] = useState(false)
  const [editDiscountLine, setEditDiscountLine] = useState<BillingPosLine | null>(null)
  const [discountModalOpen, setDiscountModalOpen] = useState(false)
  const [editDiscountValue, setEditDiscountValue] = useState("")
  const [editDiscountPct, setEditDiscountPct] = useState("")
  const [editDiscountFinal, setEditDiscountFinal] = useState("")
  const [discountsForUser, setDiscountsForUser] = useState<DescuentoForUser[]>([])
  const [discountsLoading, setDiscountsLoading] = useState(false)
  const [discountMode, setDiscountMode] = useState<"list" | "manual">("list")
  const [customerModalOpen, setCustomerModalOpen] = useState(false)
  const [customerSearch, setCustomerSearch] = useState("")
  const [customerCommitted, setCustomerCommitted] = useState("")
  const [customerAutomode, setCustomerAutomode] = useState(true)
  const [customerApplying, setCustomerApplying] = useState(false)
  // Facturas pendientes
  const [pendingModalOpen, setPendingModalOpen] = useState(false)
  const [pendingDocs, setPendingDocs] = useState<FacDocumentoPOS[]>([])
  const [pendingLoading, setPendingLoading] = useState(false)
  const [pendingLoadingId, setPendingLoadingId] = useState<number | null>(null)
  const [activePosDocId, setActivePosDocId] = useState<number | null>(null) // doc cargado en edicion
  const [pendingCount, setPendingCount] = useState(0)
  // Modal de referencia (pedir referencia al pausar)
  const [refModalOpen, setRefModalOpen] = useState(false)
  const [refModalThenOpenPending, setRefModalThenOpenPending] = useState(false)
  const [refReferencia, setRefReferencia] = useState("")
  const [refSaving, setRefSaving] = useState(false)
  const [confirmDeleteLine, setConfirmDeleteLine] = useState<BillingPosLine | null>(null)
  const [supervisorDeleteLine, setSupervisorDeleteLine] = useState<BillingPosLine | null>(null)
  const [supervisorUsername, setSupervisorUsername] = useState("")
  const [supervisorPassword, setSupervisorPassword] = useState("")
  const [protectedMessage, setProtectedMessage] = useState<string | null>(null)
  // Anular pendiente con supervisor
  const [confirmAnularDoc, setConfirmAnularDoc] = useState<FacDocumentoPOS | null>(null)
  const [supervisorAnularDoc, setSupervisorAnularDoc] = useState<FacDocumentoPOS | null>(null)
  const [supervisorAnularUsername, setSupervisorAnularUsername] = useState("")
  const [supervisorAnularPassword, setSupervisorAnularPassword] = useState("")
  const [supervisorAnularMessage, setSupervisorAnularMessage] = useState<string | null>(null)
  const optionsRef = useRef<HTMLDivElement | null>(null)
  const lineKeyCounterRef = useRef(2)
  const getNextLineKey = () => {
    const nextKey = `line-${lineKeyCounterRef.current}`
    lineKeyCounterRef.current += 1
    return nextKey
  }
  const [lines, setLines] = useState<BillingPosLine[]>(() => [buildEmptyLine(INITIAL_LINE_KEY)])
  const lineCodeLookupRef = useRef(new Map<string, string>())
  const [quickTray, setQuickTray] = useState<QuickTrayItem[]>([])
  const [selectedDocumentId, setSelectedDocumentId] = useState<number | null>(null)
  const [selectedWarehouseId, setSelectedWarehouseId] = useState<number | null>(warehouses[0]?.id ?? null)
  const [selectedCustomerId, setSelectedCustomerId] = useState<number | null>(null)
  const [sellerName, setSellerName] = useState("")
  const [referenceValue, setReferenceValue] = useState("")
  const [comentarioGeneral, setComentarioGeneral] = useState("")
  const [invoiceDateValue, setInvoiceDateValue] = useState("")
  const [comentarioGeneralModalOpen, setComentarioGeneralModalOpen] = useState(false)
  const [comentarioLineaModalOpen, setComentarioLineaModalOpen] = useState(false)
  const [editComentarioLinea, setEditComentarioLinea] = useState("")

  // Cobrar
  const [cobrarModalOpen, setCobrarModalOpen] = useState(false)
  const [formasPago, setFormasPago] = useState<FacFormaPagoRecord[]>([])
  const [formasPagoLoading, setFormasPagoLoading] = useState(false)
  const [montoRecibido, setMontoRecibido] = useState("")
  const [cobrarProcessing, setCobrarProcessing] = useState(false)
  // Mixto sub-modal
  const [mixtoOpen, setMixtoOpen] = useState(false)
  type MixtoLinea = { idFormaPago: number; monto: string; referencia: string }
  const [mixtoLineas, setMixtoLineas] = useState<MixtoLinea[]>([])

  const selectedBranch = branches[0] ?? null
  const selectedEmissionPoint = emissionPoints.find((item) => item.branchId === selectedBranch?.id) ?? emissionPoints[0] ?? null
  const cajaPosName = activeCajaPosName
  const selectedDocument = documentTypes.find((item) => item.id === selectedDocumentId) ?? documentTypes[0] ?? null
  const selectedWarehouse = warehouses.find((item) => item.id === selectedWarehouseId) ?? warehouses[0] ?? null
  const selectedCustomer = customers.find((item) => item.id === selectedCustomerId) ?? null
  const customerPreferredDocumentId = selectedCustomer?.idDocumentoVenta ?? null
  const emissionPointPreferredDocumentId = selectedEmissionPoint?.defaultPosDocumentTypeId ?? null
  const customerPreferredTaxVoucherId = selectedCustomer?.idTipoComprobante ?? null
  const documentPreferredTaxVoucherId = selectedDocument?.idCatalogoNCF ?? null
  const selectedTaxVoucher = taxVoucherTypes.find((item) => item.id === (customerPreferredTaxVoucherId ?? documentPreferredTaxVoucherId ?? 0)) ?? null
  const selectedCurrency = currencies.find((item) => item.id === selectedDocument?.idMoneda) ?? null
  const currencyLabel = selectedDocument?.nombreMoneda || selectedCurrency?.code || company.currency || "DOP"
  const secondaryCurrencyCode = (company.secondaryCurrency || "").trim()
  const secondaryCurrency = secondaryCurrencyCode
    ? currencies.find((item) => item.code.toUpperCase() === secondaryCurrencyCode.toUpperCase()) ?? null
    : null
  const exchangeRateValue = selectedCurrency
    ? (selectedCurrency.isLocal ? 1 : (selectedCurrency.rateSale ?? selectedCurrency.rateOperative ?? selectedCurrency.rateAdministrative ?? 1))
    : 1
  const secondaryExchangeRate = secondaryCurrency?.rateSale
    ?? secondaryCurrency?.rateOperative
    ?? secondaryCurrency?.rateAdministrative
    ?? secondaryCurrency?.factorConversionLocal
    ?? 0
  const exchangeRate = exchangeRateValue.toFixed(4)
  const comprobanteFiscal = selectedTaxVoucher?.nombreInterno || selectedTaxVoucher?.nombre || selectedDocument?.nombreNCF || "Sin comprobante"
  const customerName = selectedCustomer?.name || selectedEmissionPoint?.defaultPosCustomerName || "Cliente final"
  const invoiceDateLabel = useMemo(() => {
    if (!invoiceDateValue) return ""
    const value = new Date(`${invoiceDateValue}T00:00:00`)
    return new Intl.DateTimeFormat("en-GB", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    }).format(value)
  }, [invoiceDateValue])
  const liveDateLabel = liveClock.date
  const liveTimeLabel = liveClock.time

  const productSearchActiveTerm = productSearchAutomode ? productSearchQuery : productSearchCommitted
  const productSearchActive = productSearchActiveTerm.trim().length > 0

  const productSearchResults = useMemo(() => {
    const term = productSearchActiveTerm.trim().toLowerCase()
    if (!term) return []
    return products.filter((item) =>
      item.name.toLowerCase().includes(term)
      || item.code.toLowerCase().includes(term)
      || item.category.toLowerCase().includes(term),
    )
  }, [products, productSearchActiveTerm])

  const visibleQuickItems = useMemo(() => {
    const term = quickSearch.trim().toLowerCase()
    return products.filter((item) => {
      const matchesCategory = term ? true : selectedCategory === "all" || item.category === selectedCategory
      const matchesSearch = !term
        || item.name.toLowerCase().includes(term)
        || item.category.toLowerCase().includes(term)
        || item.code.toLowerCase().includes(term)
      return matchesCategory && matchesSearch
    })
  }, [products, quickSearch, selectedCategory])

  const totals = useMemo(() => {
    let subtotal = 0
    let tax = 0
    let tip = 0
    let discount = 0
    let taxExempt = 0

    for (const line of lines) {
      const lineTotals = computeLineTotals(line, company, selectedDocument)
      subtotal += lineTotals.lineBase
      tax += lineTotals.lineTax
      tip += lineTotals.lineTip
      discount += line.lineDiscount
      if (!line.applyTax) {
        taxExempt += lineTotals.lineBase
      }
    }

    subtotal = roundMoney(subtotal)
    tax = roundMoney(tax)
    tip = roundMoney(tip)
    discount = roundMoney(discount)
    taxExempt = roundMoney(taxExempt)
    const total = roundMoney(subtotal + tax + tip - discount)
    return { subtotal, tax, tip, discount, taxExempt, total }
  }, [company, lines, selectedDocument])
  const showSecondaryCurrencyTotal = Boolean(secondaryCurrencyCode && secondaryCurrency && secondaryExchangeRate > 0)
  const showTipCol = Boolean(company.applyTip && selectedDocument?.aplicaPropina)
  const totalSecondaryCurrency = showSecondaryCurrencyTotal ? roundMoney(totals.total / secondaryExchangeRate) : 0

  const quickTrayTotal = useMemo(
    () => quickTray.reduce((sum, item) => sum + computeLineTotals(item, company, selectedDocument).lineTotal, 0),
    [company, quickTray, selectedDocument],
  )

  const { setDirty } = useUnsavedGuard()

  useEffect(() => {
    const hasData = lines.some((l) => l.productId > 0)
    setDirty(hasData)
  }, [lines, setDirty])

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (!optionsRef.current) return
      if (!optionsRef.current.contains(event.target as Node)) {
        setOptionsOpen(false)
      }
    }

    document.addEventListener("mousedown", handleClickOutside)
    return () => document.removeEventListener("mousedown", handleClickOutside)
  }, [])

  useEffect(() => {
    let cancelled = false
    void fetch(apiUrl("/api/auth/me"), { cache: "no-store", credentials: "include" })
      .then(async (response) => {
        const result = (await response.json()) as { ok?: boolean; user?: CurrentViewer }
        if (!cancelled && response.ok && result.ok && result.user) {
          setCurrentViewer(result.user)
        }
      })
      .catch(() => undefined)
    return () => { cancelled = true }
  }, [])

  useEffect(() => {
    if (!currentViewer?.idCaja) {
      setActiveCajaPosName("Caja activa")
      return
    }

    let cancelled = false

    void fetch(apiUrl("/api/config/facturacion/cajas-pos"), { cache: "no-store", credentials: "include" })
      .then(async (response) => {
        if (!response.ok) return
        const result = (await response.json()) as { ok?: boolean; data?: Array<{ id: number; descripcion: string }> }
        if (!result.ok || !Array.isArray(result.data) || cancelled) return
        const activeCaja = result.data.find((item) => item.id === currentViewer.idCaja)
        if (activeCaja?.descripcion) {
          setActiveCajaPosName(activeCaja.descripcion)
        }
      })
      .catch(() => undefined)

    return () => {
      cancelled = true
    }
  }, [currentViewer?.idCaja])

  useEffect(() => {
    if (!invoiceDateValue) {
      setInvoiceDateValue(getTodayIsoDate())
    }
  }, [invoiceDateValue])

  // Carga el conteo de pendientes en background
  const refreshPendingCount = useCallback(() => {
    const id = selectedEmissionPoint?.id
    if (!id) return
    void fetch(apiUrl(`/api/facturacion/pos-documentos?idPuntoEmision=${id}`), { credentials: "include" })
      .then(async (res) => {
        const json = (await res.json()) as { ok?: boolean; data?: FacDocumentoPOS[] }
        if (json.ok && json.data) setPendingCount(json.data.length)
      })
      .catch(() => undefined)
  }, [selectedEmissionPoint?.id])

  useEffect(() => {
    refreshPendingCount()
  }, [refreshPendingCount])

  useEffect(() => {
    if (typeof window === "undefined") return
    const systemPrefers24Hour = (() => {
      const options = new Intl.DateTimeFormat(undefined, { hour: "numeric" }).resolvedOptions()
      return options.hourCycle === "h23" || options.hourCycle === "h24"
    })()
    if (!currentViewer?.userId) {
      setClockUse24Hour(systemPrefers24Hour)
      return
    }
    const stored = window.localStorage.getItem(`masu-pos-clock-24h:${currentViewer.userId}`)
    if (stored === "true" || stored === "false") {
      setClockUse24Hour(stored === "true")
      return
    }
    setClockUse24Hour(systemPrefers24Hour)
  }, [currentViewer?.userId])

  useEffect(() => {
    if (typeof window === "undefined" || !currentViewer?.userId) return
    window.localStorage.setItem(`masu-pos-clock-24h:${currentViewer.userId}`, String(clockUse24Hour))
  }, [clockUse24Hour, currentViewer?.userId])

  useEffect(() => {
    function formatNow() {
      const now = new Date()
      const date = new Intl.DateTimeFormat(undefined, {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
      }).format(now)
      const time = new Intl.DateTimeFormat(undefined, {
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hour12: !clockUse24Hour,
      }).format(now)
      return { date, time }
    }

    setLiveClock(formatNow())
    const interval = window.setInterval(() => setLiveClock(formatNow()), 1000)
    return () => window.clearInterval(interval)
  }, [clockUse24Hour])

  useEffect(() => {
    if (!selectedWarehouseId && warehouses[0]?.id) {
      setSelectedWarehouseId(warehouses[0].id)
    }
    if (!selectedCustomerId && selectedEmissionPoint?.defaultPosCustomerId) {
      setSelectedCustomerId(selectedEmissionPoint.defaultPosCustomerId)
    }
  }, [selectedCustomerId, selectedEmissionPoint, selectedWarehouseId, warehouses])

  useEffect(() => {
    const resolvedDocumentId =
      customerPreferredDocumentId
      ?? emissionPointPreferredDocumentId
      ?? documentTypes[0]?.id
      ?? null

    if (resolvedDocumentId && resolvedDocumentId !== selectedDocumentId) {
      setSelectedDocumentId(resolvedDocumentId)
    }
  }, [customerPreferredDocumentId, documentTypes, emissionPointPreferredDocumentId, selectedDocumentId])

  useEffect(() => {
    if (!sellerName) {
      setSellerName(currentViewer?.fullName || currentViewer?.username || "Vendedor principal")
    }
  }, [currentViewer, sellerName])

  function resetPos() {
    lineKeyCounterRef.current = 2
    setLines([buildEmptyLine(INITIAL_LINE_KEY)])
    setQuickTray([])
    setSelectedCustomerId(selectedEmissionPoint?.defaultPosCustomerId ?? null)
    setSelectedDocumentId(
      emissionPointPreferredDocumentId ?? documentTypes[0]?.id ?? null
    )
    setSelectedWarehouseId(warehouses[0]?.id ?? null)
    setReferenceValue("")
    setComentarioGeneral("")
    setInvoiceDateValue(getTodayIsoDate())
    setActiveLineKey(null)
    setOptionsOpen(false)
    setQuickPanelOpen(false)
    resetDeleteAuthorizationFlow()
    setActivePosDocId(null)
  }

  function addProductToTray(product: OrderProductOption) {
    if (!validateProductForSale(product)) return
    setQuickTray((current) => {
      const existing = current.find((item) => item.productId === product.id)
      if (existing) {
        return current.map((item) => item.productId === product.id ? { ...item, quantity: item.quantity + 1 } : item)
      }
      return [...current, buildTrayItem(product)]
    })
  }

  function updateTrayQuantity(key: string, nextQuantity: number) {
    setQuickTray((current) => current.map((item) => item.key === key ? { ...item, quantity: Math.max(1, nextQuantity) } : item))
  }

  function removeTrayItem(key: string) {
    setQuickTray((current) => current.filter((item) => item.key !== key))
  }

  function saveTrayToLines() {
    if (!quickTray.length) {
      setQuickPanelOpen(false)
      return
    }

    setLines((current) => {
      const next = [...current]
      for (const item of quickTray) {
        const existingIndex = next.findIndex((line) => line.productId === item.productId && line.productId > 0)
        if (existingIndex >= 0) {
          next[existingIndex] = {
            ...next[existingIndex],
            quantity: next[existingIndex].quantity + item.quantity,
          }
        } else {
          const { key: _key, ...line } = item
          next.push({ ...line, key: getNextLineKey() })
        }
      }
      return next
    })

    setQuickTray([])
    setQuickSearch("")
    setQuickPanelOpen(false)
    setPickerTargetLineKey(null)
  }

  function addEmptyLine() {
    const line = buildEmptyLine(getNextLineKey())
    setLines((current) => [...current, line])
    setActiveLineKey(line.key)
    focusLineField(line.key, "code")
    return line.key
  }

  function focusLineField(lineKey: string, field: "code" | "qty") {
    setTimeout(() => {
      const selector = field === "code"
        ? `[data-line="${lineKey}"][data-field="code"]`
        : `[data-line="${lineKey}"][data-field="qty"]`
      const el = document.querySelector<HTMLElement>(selector)
      el?.focus()
      if (el instanceof HTMLInputElement) el.select()
    }, 30)
  }

  async function handleCodeKeyDown(event: React.KeyboardEvent, line: BillingPosLine) {
    if (event.key === "Enter" || event.key === "Tab") {
      event.preventDefault()
      const resolved = await resolveLineByCode(line.key, line.code)
      if (resolved) {
        focusLineField(line.key, "qty")
      } else {
        focusLineField(line.key, "code")
      }
    }
  }

  function handleQtyKeyDown(event: React.KeyboardEvent, line: BillingPosLine) {
    if (event.key === "Enter" || (event.key === "Tab" && !event.shiftKey)) {
      event.preventDefault()
      const isLast = lines[lines.length - 1]?.key === line.key
      if (isLast) {
        const newKey = addEmptyLine()
        focusLineField(newKey, "code")
      } else {
        const idx = lines.findIndex((l) => l.key === line.key)
        const nextKey = lines[idx + 1]?.key
        if (nextKey) focusLineField(nextKey, "code")
      }
    }
  }

  function updateLine(lineKey: string, patch: Partial<BillingPosLine>) {
    setLines((current) => current.map((line) => (line.key === lineKey ? { ...line, ...patch } : line)))
  }

  function updateLineQuantity(lineKey: string, nextQuantity: number) {
    setLines((current) => current.map((line) => (
      line.key === lineKey
        ? { ...line, quantity: Math.max(1, Math.round(toPositiveNumber(nextQuantity, 1))) }
        : line
    )))
  }

  function updateLineDiscount(lineKey: string, nextDiscount: number) {
    setLines((current) => current.map((line) => {
      if (line.key !== lineKey) return line
      return { ...line, lineDiscount: Math.max(0, roundMoney(toPositiveNumber(nextDiscount, 0))) }
    }))
  }

  function applyGlobalDiscount(totalDiscountAmount: number) {
    setLines((current) => {
      const filledLines = current.filter((l) => l.productId > 0)
      if (filledLines.length === 0) return current
      const docSubtotal = filledLines.reduce((sum, l) => sum + roundMoney(l.basePrice * l.quantity), 0)
      if (docSubtotal <= 0) return current
      let distributed = 0
      const updated = current.map((line, idx) => {
        if (line.productId === 0) return line
        const lineBase = roundMoney(line.basePrice * line.quantity)
        const isLast = idx === current.length - 1 || current.slice(idx + 1).every((l) => l.productId === 0)
        const share = isLast
          ? roundMoney(totalDiscountAmount - distributed)
          : roundMoney(totalDiscountAmount * (lineBase / docSubtotal))
        distributed += share
        return { ...line, lineDiscount: Math.max(0, share) }
      })
      return updated
    })
  }

  async function applyCustomer(customer: TerceroRecord | null) {
    setCustomerApplying(true)
    try {
      // 1. Cambiar cliente y tipo de documento
      setSelectedCustomerId(customer?.id ?? null)
      if (customer?.idDocumentoVenta) {
        const docExists = documentTypes.find((d) => d.id === customer.idDocumentoVenta)
        if (docExists) setSelectedDocumentId(customer.idDocumentoVenta)
      }

      // 2. Aplicar lista de precios del cliente a todas las líneas con producto
      if (customer?.idListaPrecio) {
        const res = await fetch(apiUrl(`/api/facturacion/prices-by-list?listId=${customer.idListaPrecio}`), { credentials: "include" })
        const json = (await res.json()) as { ok?: boolean; data?: { productId: number; price: number }[] }
        if (json.ok && json.data) {
          const priceMap = new Map(json.data.map((p) => [p.productId, p.price]))
          setLines((current) => current.map((line) => {
            if (line.productId === 0) return line
            const newPrice = priceMap.get(line.productId)
            if (newPrice == null) return line
            return { ...line, basePrice: newPrice, lineDiscount: 0 }
          }))
        }
      }

      // 3. Aplicar descuento del cliente (global, proporcional)
      const descuento = customer?.idDescuento ? discounts.find((d) => d.id === customer.idDescuento) : null
      if (descuento && descuento.porcentaje > 0) {
        setLines((current) => {
          const filledLines = current.filter((l) => l.productId > 0)
          if (filledLines.length === 0) return current
          const docSubtotal = filledLines.reduce((sum, l) => sum + roundMoney(l.basePrice * l.quantity), 0)
          if (docSubtotal <= 0) return current
          const totalDiscount = roundMoney(docSubtotal * (descuento.porcentaje / 100))
          let distributed = 0
          return current.map((line, idx) => {
            if (line.productId === 0) return line
            const lineBase = roundMoney(line.basePrice * line.quantity)
            const isLast = idx === current.length - 1 || current.slice(idx + 1).every((l) => l.productId === 0)
            const share = isLast
              ? roundMoney(totalDiscount - distributed)
              : roundMoney(totalDiscount * (lineBase / docSubtotal))
            distributed += share
            return { ...line, lineDiscount: Math.max(0, share) }
          })
        })
      }
    } finally {
      setCustomerApplying(false)
      setCustomerModalOpen(false)
      setCustomerSearch("")
    }
  }

  // Determina si el cliente activo requiere pedir referencia al pausar/enviar
  function needsRefModal(): boolean {
    if (!selectedCustomer) return false
    return selectedCustomer.pedirReferencia
  }

  // Construye el payload de lineas para guardar en DB
  function buildLineasPayload() {
    return lines
      .filter((l) => l.productId > 0)
      .map((l, idx) => ({
        numLinea: idx + 1,
        productId: l.productId,
        code: l.code,
        description: l.description,
        quantity: l.quantity,
        unit: l.unit,
        basePrice: l.basePrice,
        taxRate: l.taxRate,
        applyTax: l.applyTax,
        applyTip: l.applyTip,
        lineDiscount: l.lineDiscount,
        lineComment: l.lineComment || null,
      }))
  }

  async function closePosToWorkspace() {
    if (isClosingPos) return
    setIsClosingPos(true)
    try {
      await navigateToWorkspaceTarget({ push: (href: string) => { window.location.href = href } })
    } finally {
      setIsClosingPos(false)
    }
  }

  function handleClosePos() {
    const hasItems = buildLineasPayload().length > 0
    if (!hasItems) {
      void closePosToWorkspace()
      return
    }
    setConfirmClosePos(true)
  }

  async function executeGuardarPendiente(referencia?: string) {
    const lineas = buildLineasPayload()
    if (lineas.length === 0) { toast.warning("Agrega al menos un ítem antes de guardar."); return }
    const idPuntoEmision = selectedEmissionPoint?.id
    if (!idPuntoEmision) { toast.error("No hay punto de emisión configurado."); return }
    setRefSaving(true)
    try {
      const payload = {
        idPuntoEmision,
        idCliente: selectedCustomerId,
        referencia: referencia ?? null,
        comentarioGeneral: comentarioGeneral || null,
        idTipoDocumento: selectedDocumentId,
        idAlmacen: selectedWarehouseId,
        fechaDocumento: invoiceDateValue,
        vendedor: sellerName,
        idMoneda: selectedDocument?.idMoneda ?? null,
        tasaCambio: 1,
        lineas,
      }
      let savedId: number
      if (activePosDocId) {
        const res = await fetch(apiUrl(`/api/facturacion/pos-documentos/${activePosDocId}`), {
          method: "PUT",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ ...payload, accion: "guardar" }),
        })
        const json = (await res.json()) as { ok?: boolean; message?: string }
        if (!json.ok) throw new Error(json.message ?? "Error al guardar")
        savedId = activePosDocId
      } else {
        const res = await fetch(apiUrl("/api/facturacion/pos-documentos"), {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        })
        const json = (await res.json()) as { ok?: boolean; data?: { id?: number }; message?: string }
        if (!json.ok) throw new Error(json.message ?? "Error al guardar")
        savedId = json.data?.id ?? 0
      }
      setActivePosDocId(null)
      resetPos()
      toast.success(`Factura guardada.${savedId ? ` #${savedId}` : ""}`)
      setRefModalOpen(false)
      refreshPendingCount()
      if (refModalThenOpenPending) {
        setRefModalThenOpenPending(false)
        const idPuntoEmision2 = selectedEmissionPoint?.id
        if (idPuntoEmision2) {
          setPendingDocs([])
          setPendingLoading(true)
          setPendingModalOpen(true)
          void fetch(apiUrl(`/api/facturacion/pos-documentos?idPuntoEmision=${idPuntoEmision2}`), { credentials: "include" })
            .then(async (res2) => {
              const json2 = (await res2.json()) as { ok?: boolean; data?: FacDocumentoPOS[] }
              if (json2.ok && json2.data) setPendingDocs(json2.data)
            })
            .catch(() => undefined)
            .finally(() => setPendingLoading(false))
        }
      }
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Error al guardar")
    } finally {
      setRefSaving(false)
    }
  }

  function handlePausar() {
    const lineas = buildLineasPayload()
    if (lineas.length === 0) { toast.warning("Agrega al menos un ítem antes de guardar."); return }
    if (needsRefModal()) {
      setRefReferencia(referenceValue)
      setRefModalOpen(true)
    } else {
      void executeGuardarPendiente(referenceValue || undefined)
    }
  }

  async function handleCargarPendiente(doc: FacDocumentoPOS) {
    setPendingLoadingId(doc.id)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/pos-documentos/${doc.id}`), {
        credentials: "include",
      })
      const json = (await res.json()) as { ok?: boolean; data?: FacDocumentoPOSDetalle; message?: string }
      if (!json.ok || !json.data) throw new Error(json.message ?? "Error al cargar")
      const det = json.data
      // Restaurar estado del POS
      lineKeyCounterRef.current = det.lineas.length + 1
      setLines([
        ...det.lineas.map((l, idx) => ({
          key: `line-loaded-${idx}`,
          productId: l.productId,
          code: l.code,
          description: l.description,
          quantity: l.quantity,
          unit: l.unit,
          basePrice: l.basePrice,
          taxRate: l.taxRate,
          applyTax: l.applyTax,
          applyTip: l.applyTip,
          lineDiscount: l.lineDiscount,
          lineComment: l.lineComment ?? "",
        })),
        buildEmptyLine(getNextLineKey()),
      ])
      if (det.idCliente) setSelectedCustomerId(det.idCliente)
      if (det.idTipoDocumento) setSelectedDocumentId(det.idTipoDocumento)
      if (det.idAlmacen) setSelectedWarehouseId(det.idAlmacen)
      if (det.fechaDocumento) setInvoiceDateValue(det.fechaDocumento)
      if (det.vendedor) setSellerName(det.vendedor)
      if (det.referencia) setReferenceValue(det.referencia)
      setComentarioGeneral(det.comentarioGeneral ?? "")
      setActivePosDocId(doc.id)
      setPendingDocs((prev) => prev.filter((d) => d.id !== doc.id))
      setPendingCount((prev) => Math.max(0, prev - 1))
      setPendingModalOpen(false)
      toast.success(`Factura #${doc.id} cargada para edición.`)
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Error al cargar la factura")
    } finally {
      setPendingLoadingId(null)
    }
  }

  function handleAnularPendiente(doc: FacDocumentoPOS) {
    // Supervisor/Admin anulan directo, operador pide confirmación + credenciales
    if (isPrivilegedUserType(currentViewer?.userType)) {
      setConfirmAnularDoc(doc)
    } else {
      setConfirmAnularDoc(doc)
    }
  }

  function confirmAnularAndContinue() {
    if (!confirmAnularDoc) return
    if (isPrivilegedUserType(currentViewer?.userType)) {
      void executeAnularPendiente(confirmAnularDoc)
    } else {
      setSupervisorAnularDoc(confirmAnularDoc)
      setConfirmAnularDoc(null)
      setSupervisorAnularMessage(null)
    }
  }

  async function executeAnularPendiente(doc: FacDocumentoPOS) {
    setPendingLoadingId(doc.id)
    try {
      const res = await fetch(apiUrl(`/api/facturacion/pos-documentos/${doc.id}`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accion: "anular" }),
      })
      const json = (await res.json()) as { ok?: boolean; message?: string }
      if (!json.ok) throw new Error(json.message ?? "Error al anular")
      setPendingDocs((prev) => prev.filter((d) => d.id !== doc.id))
      if (activePosDocId === doc.id) setActivePosDocId(null)
      setConfirmAnularDoc(null)
      setSupervisorAnularDoc(null)
      setSupervisorAnularUsername("")
      setSupervisorAnularPassword("")
      setSupervisorAnularMessage(null)
      refreshPendingCount()
      toast.success("Factura anulada.")
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Error al anular")
    } finally {
      setPendingLoadingId(null)
    }
  }

  async function verifySupervisorAndAnularDoc() {
    if (!supervisorAnularDoc) return
    if (!supervisorAnularUsername.trim() || !supervisorAnularPassword) {
      setSupervisorAnularMessage("Indica usuario y clave del supervisor.")
      return
    }
    const response = await fetch(apiUrl("/api/auth/supervisor-verify"), {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: supervisorAnularUsername.trim(),
        password: supervisorAnularPassword,
        permissionKey: "facturacion.pos.delete-line",
      }),
    })
    const result = (await response.json()) as { ok?: boolean; message?: string }
    if (!response.ok || !result.ok) {
      setSupervisorAnularMessage(result.message ?? "No se pudo validar el supervisor.")
      return
    }
    void executeAnularPendiente(supervisorAnularDoc)
  }

  function updateLinePrice(lineKey: string, nextPrice: number) {
    setLines((current) => current.map((line) => (
      line.key === lineKey
        ? { ...line, basePrice: Math.max(0, roundMoney(toPositiveNumber(nextPrice, 0))) }
        : line
    )))
  }

  function removeLine(lineKey: string) {
    setLines((current) => current.filter((line) => line.key !== lineKey))
    setActiveLineKey((current) => current === lineKey ? null : current)
  }

  function resetDeleteAuthorizationFlow() {
    setConfirmDeleteLine(null)
    setSupervisorDeleteLine(null)
    setSupervisorUsername("")
    setSupervisorPassword("")
    setProtectedMessage(null)
  }

  function requestRemoveLine(line: BillingPosLine) {
    if (currentViewer?.canDeletePosLines || isPrivilegedUserType(currentViewer?.userType)) {
      removeLine(line.key)
      return
    }
    setConfirmDeleteLine(line)
    setSupervisorDeleteLine(null)
    setSupervisorUsername("")
    setSupervisorPassword("")
    setProtectedMessage(null)
  }

  function confirmDeleteLineAndContinue() {
    if (!confirmDeleteLine) return
    if (currentViewer?.canDeletePosLines || isPrivilegedUserType(currentViewer?.userType)) {
      removeLine(confirmDeleteLine.key)
      resetDeleteAuthorizationFlow()
      return
    }
    setSupervisorDeleteLine(confirmDeleteLine)
    setConfirmDeleteLine(null)
    setProtectedMessage(null)
  }

  async function verifySupervisorAndRemoveLine() {
    if (!supervisorDeleteLine) return
    if (!supervisorUsername.trim() || !supervisorPassword) {
      setProtectedMessage("Indica usuario y clave del supervisor.")
      return
    }

    const response = await fetch(apiUrl("/api/auth/supervisor-verify"), {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: supervisorUsername.trim(),
        password: supervisorPassword,
        permissionKey: "facturacion.pos.delete-line",
      }),
    })

    const result = (await response.json()) as { ok?: boolean; message?: string }
    if (!response.ok || !result.ok) {
      setProtectedMessage(result.message ?? "No se pudo validar el supervisor.")
      return
    }

    removeLine(supervisorDeleteLine.key)
    resetDeleteAuthorizationFlow()
  }

  function closeProductSearch() {
    setProductSearchOpen(false)
    setPickerTargetLineKey(null)
  }

  function openProductSearch(targetLineKey?: string) {
    setProductSearchQuery("")
    setProductSearchCommitted("")
    setProductSearchSelected(new Map())
    setPickerTargetLineKey(targetLineKey ?? null)
    setProductSearchOpen(true)
  }

  function commitProductSearch() {
    setProductSearchCommitted(productSearchQuery)
  }

  function toggleProductSearchItem(productId: number) {
    setProductSearchSelected((current) => {
      if (pickerTargetLineKey) {
        if (current.has(productId)) {
          return new Map()
        }
        return new Map([[productId, 1]])
      }
      const next = new Map(current)
      if (next.has(productId)) {
        next.delete(productId)
      } else {
        next.set(productId, 1)
      }
      return next
    })
  }

  function setProductSearchQty(productId: number, qty: number) {
    setProductSearchSelected((current) => {
      const next = new Map(current)
      const safeQty = Math.max(1, Math.round(qty))
      if (next.has(productId)) next.set(productId, safeQty)
      return next
    })
  }

  function confirmProductSearch() {
    if (!productSearchSelected.size) { closeProductSearch(); return }
    if (pickerTargetLineKey) {
      const [selectedEntry] = Array.from(productSearchSelected.entries())
      const product = selectedEntry ? products.find((p) => p.id === selectedEntry[0]) : null
      if (!product) {
        closeProductSearch()
        return
      }
      if (!validateProductForSale(product)) return
      applyProductToLine(pickerTargetLineKey, product)
      closeProductSearch()
      return
    }
    const blocked: string[] = []
    setLines((current) => {
      const next = [...current]
      for (const [productId, qty] of productSearchSelected.entries()) {
        const product = products.find((p) => p.id === productId)
        if (!product) continue
        if (!product.canSellInBilling) { blocked.push(product.name); continue }
        if (product.managesStock && !product.sellWithoutStock && product.stock <= 0) { blocked.push(product.name); continue }
        const existingIndex = next.findIndex((line) => line.productId === productId && productId > 0)
        if (existingIndex >= 0) {
          next[existingIndex] = { ...next[existingIndex], quantity: next[existingIndex].quantity + qty }
        } else {
          next.push({ ...buildLine(product, getNextLineKey()), quantity: qty })
        }
      }
      return next
    })
    if (blocked.length) toast.warning(`No se agregaron: ${blocked.join(", ")} (sin permiso o sin existencia).`)
    closeProductSearch()
  }

  function validateProductForSale(product: OrderProductOption): boolean {
    if (!product.canSellInBilling) {
      toast.error(`"${product.name}" no está habilitado para venta en facturación.`)
      return false
    }
    if (product.managesStock && !product.sellWithoutStock && product.stock <= 0) {
      toast.error(`"${product.name}" no tiene existencia disponible (${product.stock} unidades).`)
      return false
    }
    return true
  }

  function applyProductToLine(lineKey: string, product: OrderProductOption) {
    if (!validateProductForSale(product)) return
    setLines((current) => current.map((line) => {
      if (line.key !== lineKey) return line
      return {
        ...line,
        productId: product.id,
        code: product.code || `PROD-${product.id}`,
        description: product.name,
        unit: product.unitName || "UND",
        basePrice: product.price,
        taxRate: product.taxRate,
        applyTax: product.applyTax,
        applyTip: product.applyTip,
      }
    }))
    setActiveLineKey(lineKey)
  }

  async function resolveLineByCode(lineKey: string, rawCode: string, options?: { notifyOnMissing?: boolean }) {
    const trimmedCode = rawCode.trim()
    if (!trimmedCode) return false

    lineCodeLookupRef.current.set(lineKey, trimmedCode)

    try {
      const response = await fetch(apiUrl(`/api/facturacion/products/by-code?code=${encodeURIComponent(trimmedCode)}`), {
        cache: "no-store",
        credentials: "include",
      })
      const result = (await response.json()) as { ok?: boolean; data?: OrderProductOption; message?: string }

      if (lineCodeLookupRef.current.get(lineKey) !== trimmedCode) return false

      if (response.ok && result.ok && result.data) {
        if (!validateProductForSale(result.data)) return false
        applyProductToLine(lineKey, result.data)
        return true
      }

      setLines((current) => current.map((line) => (line.key === lineKey ? clearLineProductState(line) : line)))
      setActiveLineKey(lineKey)
      if (options?.notifyOnMissing ?? true) {
        toast.warning(result.message ?? `No existe un producto con el codigo "${trimmedCode}".`)
      }
      return false
    } catch (error) {
      if (lineCodeLookupRef.current.get(lineKey) !== trimmedCode) return false
      toast.error(error instanceof Error ? error.message : "No se pudo validar el codigo digitado.")
      return false
    }
  }

    return (
      <section className="content-page billing-pos">
        <section className="billing-pos__board">
          <div className="billing-pos__context-strip">
            <div className="billing-pos__info-bar">
              <div className="billing-pos__info-cell billing-pos__info-cell--empresa">
                <span className="billing-pos__info-label">Empresa</span>
                <strong className="billing-pos__info-value">{company.tradeName || company.businessName || "Empresa"}</strong>
              </div>
              <div className="billing-pos__info-cell billing-pos__info-cell--pe">
                <span className="billing-pos__info-label">Punto de Emisión</span>
                <strong className="billing-pos__info-value">{selectedEmissionPoint?.name || selectedBranch?.name || "—"}</strong>
              </div>
              <div className="billing-pos__info-cell billing-pos__info-cell--client">
                <span className="billing-pos__info-label">Cliente</span>
                <strong className="billing-pos__info-value">{customerName}</strong>
              </div>
              <div className="billing-pos__info-cell billing-pos__info-cell--voucher">
                <span className="billing-pos__info-label">Tipo Comprobante</span>
                <strong className="billing-pos__info-value">{comprobanteFiscal}</strong>
              </div>
              <div className="billing-pos__info-cell billing-pos__info-cell--lines">
                <span className="billing-pos__info-label">Líneas</span>
                <strong className="billing-pos__info-value">{lines.length}</strong>
              </div>
              <button
                type="button"
                className="billing-pos__close-btn"
                onClick={handleClosePos}
                title="Cerrar punto de ventas"
              >
                <X size={14} />
              </button>
            </div>
          </div>

          <div className="billing-pos__table-wrap">
            <table className="billing-pos__table">
            <thead>
              <tr>
                <th className="billing-pos__col billing-pos__col--add">
                  <button type="button" className="ghost-icon-button billing-pos__table-add-btn" onClick={addEmptyLine} title="Nueva linea">
                    <Plus size={15} />
                  </button>
                </th>
                <th className="billing-pos__col billing-pos__col--code">Código</th>
                <th className="billing-pos__col billing-pos__col--desc">Descripción</th>
                <th className="billing-pos__col billing-pos__col--qty">Cantidad</th>
                <th className="billing-pos__col billing-pos__col--unit">Unidad</th>
                <th className="billing-pos__col billing-pos__col--price">P. Base</th>
                <th className="billing-pos__col billing-pos__col--tax">ITBIS</th>
                <th className="billing-pos__col billing-pos__col--num">P. Final</th>
                <th className="billing-pos__col billing-pos__col--num">Subtotal</th>
                <th className="billing-pos__col billing-pos__col--pct">% Desc.</th>
                <th className="billing-pos__col billing-pos__col--discount">Descuento</th>
                {showTipCol && <th className="billing-pos__col billing-pos__col--tip">{company.tipName || "Propina"}</th>}
                <th className="billing-pos__col billing-pos__col--num billing-pos__col--total">Total</th>
                <th className="billing-pos__col billing-pos__col--action"></th>
              </tr>
            </thead>
            <tbody>
              {lines.map((line) => {
                const lineTotals = computeLineTotals(line, company, selectedDocument)
                const discountPercent = lineTotals.lineBase > 0 ? roundMoney((line.lineDiscount / lineTotals.lineBase) * 100) : 0
                return (
                  <tr key={line.key} className={activeLineKey === line.key ? "is-active-row" : undefined} onClick={() => setActiveLineKey(line.key)}>
                    <td className="billing-pos__col billing-pos__col--add-spacer"></td>
                    <td>
                      <div className="billing-pos__code-cell">
                        <input
                          className="billing-pos__cell-input billing-pos__cell-input--code"
                          data-line={line.key}
                          data-field="code"
                          value={line.code}
                          placeholder="Codigo o scan"
                          onFocus={() => setActiveLineKey(line.key)}
                          onChange={(event) => updateLine(line.key, { code: event.target.value })}
                          onBlur={() => { void resolveLineByCode(line.key, line.code, { notifyOnMissing: false }) }}
                          onKeyDown={(event) => handleCodeKeyDown(event, line)}
                        />
                        <button
                          type="button"
                          className="billing-pos__search-btn"
                          title="Buscar producto"
                          onClick={() => openProductSearch(line.key)}
                        >
                          <Search size={13} />
                        </button>
                      </div>
                    </td>
                    <td>{line.description}</td>
                    <td className="billing-pos__col billing-pos__col--qty">
                      <input
                        className="billing-pos__cell-input billing-pos__cell-input--qty"
                        data-line={line.key}
                        data-field="qty"
                        type="number"
                        min="1"
                        step="1"
                        value={line.quantity}
                        disabled={line.productId <= 0}
                        onChange={(event) => updateLineQuantity(line.key, Number(event.target.value || 1))}
                        onKeyDown={(event) => handleQtyKeyDown(event, line)}
                      />
                    </td>
                    <td className="billing-pos__col billing-pos__col--unit">{line.unit}</td>
                    <td className="billing-pos__col billing-pos__col--price">{formatMoney(line.basePrice)}</td>
                    <td className="billing-pos__col billing-pos__col--tax">
                      {line.applyTax ? formatMoney(lineTotals.lineTax / (line.quantity || 1)) : <span className="billing-pos__no-tax">—</span>}
                    </td>
                    <td className="billing-pos__col billing-pos__col--num">{formatMoney(lineTotals.finalPrice)}</td>
                    <td className="billing-pos__col billing-pos__col--num">{formatMoney(roundMoney(line.basePrice * line.quantity))}</td>
                    <td className="billing-pos__col billing-pos__col--pct">{discountPercent > 0 ? <span className="billing-pos__pct-badge">{discountPercent}%</span> : <span className="billing-pos__no-tax">—</span>}</td>
                    <td className="billing-pos__col billing-pos__col--discount">{line.lineDiscount > 0 ? formatMoney(line.lineDiscount) : <span className="billing-pos__no-tax">—</span>}</td>
                    {showTipCol && <td className="billing-pos__col billing-pos__col--tip">{line.applyTip ? formatMoney(lineTotals.lineTip) : <span className="billing-pos__no-tax">—</span>}</td>}
                    <td className="billing-pos__col billing-pos__col--num billing-pos__col--total">{formatMoney(lineTotals.lineTotal)}</td>
                    <td className="billing-pos__col billing-pos__col--action">
                      <div style={{ display: "flex", gap: "2px", alignItems: "center" }}>
                        <button
                          type="button"
                          className="ghost-icon-button"
                          title={line.lineComment || "Agregar comentario de línea"}
                          style={{ color: line.lineComment ? "var(--info, #2563eb)" : "var(--muted-text)" }}
                          onClick={() => {
                            setActiveLineKey(line.key)
                            setEditComentarioLinea(line.lineComment)
                            setComentarioLineaModalOpen(true)
                          }}
                        >
                          <MessageSquare size={14} />
                        </button>
                        <button
                          type="button"
                          className="ghost-icon-button billing-pos__line-remove"
                          onClick={() => requestRemoveLine(line)}
                          aria-label={`Quitar ${line.description || line.code || "linea"}`}
                        >
                          <Trash2 size={15} />
                        </button>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
            </table>
          </div>

        <div className="billing-pos__summary-layout">
          <div className="billing-pos__document-panel">
            <div className="billing-pos__document-stack">
              <label className="billing-pos__field">
                <span>Fecha Fact.</span>
                <input
                  type={currentViewer?.canChangePosDate ? "date" : "text"}
                  value={currentViewer?.canChangePosDate ? invoiceDateValue : invoiceDateLabel}
                  onChange={(event) => currentViewer?.canChangePosDate && setInvoiceDateValue(event.target.value)}
                  readOnly={!currentViewer?.canChangePosDate}
                />
              </label>
              <label className="billing-pos__field">
                <span>Moneda / Tasa</span>
                <input type="text" value={`${currencyLabel} / ${exchangeRate}`} readOnly />
              </label>
              <label className="billing-pos__field billing-pos__field--doc">
                <span>Tipo Documento</span>
                <input type="text" value={selectedDocument?.description || "Sin documento"} readOnly />
              </label>
              <label className="billing-pos__field">
                <span>Vendedor</span>
                <input type="text" value={sellerName} readOnly />
              </label>
              <label className="billing-pos__field">
                <span>Referencia</span>
                <input type="text" value={referenceValue || "Sin referencia"} readOnly />
              </label>
              <label className="billing-pos__field">
                <span>Almacen</span>
                <input type="text" value={selectedWarehouse?.description || "Sin almacen"} readOnly />
              </label>
            </div>
          </div>

          <div className="billing-pos__clock-panel">
            <div className="billing-pos__clock-card">
              <button
                type="button"
                className="billing-pos__clock-format-toggle"
                onClick={() => setClockUse24Hour((current) => !current)}
                aria-label={`Cambiar a formato ${clockUse24Hour ? "12" : "24"} horas`}
              >
                <Clock3 size={15} />
                <span>{clockUse24Hour ? "24H" : "12H"}</span>
              </button>
              <strong className="billing-pos__clock-time">{liveTimeLabel}</strong>
              <span className="billing-pos__clock-date">{liveDateLabel}</span>
              <span className="billing-pos__clock-caption">Caja activa · {cajaPosName}</span>
            </div>
          </div>


          <div className="billing-pos__totals-stack">
            <div className="billing-pos__footer-box">Subtotal <strong>RD$ {formatMoney(totals.subtotal)}</strong></div>
            <div className="billing-pos__footer-box">{company.taxName || "ITBIS"} <strong>RD$ {formatMoney(totals.tax)}</strong></div>
            <div className="billing-pos__footer-box">ITBIS Exonerado <strong>RD$ {formatMoney(totals.taxExempt)}</strong></div>
            {totals.discount > 0 && (
              <div className="billing-pos__footer-box billing-pos__footer-box--discount">Descuento <strong>- RD$ {formatMoney(totals.discount)}</strong></div>
            )}
            {selectedDocument?.aplicaPropina && company.applyTip && (
              <div className="billing-pos__footer-box">{company.tipName || "Propina legal"} <strong>RD$ {formatMoney(totals.tip)}</strong></div>
            )}
            <div className="billing-pos__footer-box billing-pos__footer-box--total">Total <strong>RD$ {formatMoney(totals.total)}</strong></div>
            {showSecondaryCurrencyTotal ? (
              <div className="billing-pos__footer-box billing-pos__footer-box--foreign">Total {secondaryCurrencyCode} <strong>{secondaryCurrency?.symbol || secondaryCurrencyCode} {formatMoney(totalSecondaryCurrency)}</strong></div>
            ) : null}
          </div>
        </div>

        <div className="billing-pos__toolbar billing-pos__toolbar--footer">
          <button type="button" className="secondary-button" onClick={() => setConfirmReset(true)}><Trash2 size={16} /> Cancelar</button>
          <button
            type="button"
            className={quickPanelOpen ? "secondary-button is-active" : "secondary-button"}
            onClick={() => {
              setPickerTargetLineKey(null)
              setQuickPanelOpen(true)
            }}
          >
            <Plus size={16} /> Venta rapida
          </button>
          <button type="button" className="secondary-button" onClick={() => openProductSearch()}><PackageSearch size={16} /> Productos</button>
          <button type="button" className="secondary-button" onClick={() => {
            const line = lines.find((l) => l.key === activeLineKey && l.productId > 0) ?? null
            if (!line) { toast.warning("Selecciona una línea con producto para cambiar el precio."); return }
            const product = products.find((p) => p.id === line.productId)
            if (product && !product.allowPriceChange) {
              toast.warning(`"${product.name}" no permite cambio de precio.`)
              return
            }
            const taxFactor = line.applyTax ? (1 + line.taxRate / 100) : 1
            setEditPriceLine(line)
            setEditPriceBase(line.basePrice.toFixed(4))
            setEditPriceFinal((line.basePrice * taxFactor).toFixed(4))
            setPriceListsForLine([])
            setPriceListsLoading(true)
            void fetch(apiUrl(`/api/facturacion/price-lists-for-user?productId=${line.productId}`), { credentials: "include" })
              .then(async (res) => {
                const json = (await res.json()) as { ok?: boolean; data?: PriceListWithProductPrice[] }
                if (json.ok && json.data) setPriceListsForLine(json.data)
              })
              .catch(() => undefined)
              .finally(() => setPriceListsLoading(false))
          }}><Pencil size={16} /> Cambiar precio</button>
          <button type="button" className="secondary-button" onClick={() => {
            const hasItems = lines.some((l) => l.productId > 0)
            if (!hasItems) { toast.warning("Agrega al menos un ítem antes de aplicar un descuento."); return }
            const line = lines.find((l) => l.key === activeLineKey && l.productId > 0) ?? null
            if (line) {
              const product = products.find((p) => p.id === line.productId)
              if (product && !product.allowDiscount) {
                toast.warning(`"${product.name}" no permite descuento.`)
                return
              }
            }
            setEditDiscountLine(line)
            setEditDiscountValue(line ? String(line.lineDiscount) : "")
            setEditDiscountPct("")
            setEditDiscountFinal("")
            setDiscountMode("list")
            setDiscountsForUser([])
            setDiscountsLoading(true)
            setDiscountModalOpen(true)
            void fetch(apiUrl("/api/facturacion/discounts-for-user"), { credentials: "include" })
              .then(async (res) => {
                const json = (await res.json()) as { ok?: boolean; data?: DescuentoForUser[] }
                if (json.ok && json.data) setDiscountsForUser(json.data)
              })
              .catch(() => undefined)
              .finally(() => setDiscountsLoading(false))
          }}><Percent size={16} /> Descuento</button>
          <button type="button" className="secondary-button" onClick={() => { setCustomerSearch(""); setCustomerCommitted(""); setCustomerModalOpen(true) }}>
            <UserRound size={16} /> Clientes
          </button>
          <button
            type="button"
            className="secondary-button"
            onClick={() => {
              const hasItems = lines.some((l) => l.productId > 0)
              const idPuntoEmision = selectedEmissionPoint?.id
              if (!idPuntoEmision) return

              function openPendingList() {
                setPendingDocs([])
                setPendingLoading(true)
                setPendingModalOpen(true)
                void fetch(apiUrl(`/api/facturacion/pos-documentos?idPuntoEmision=${idPuntoEmision}`), { credentials: "include" })
                  .then(async (res) => {
                    const json = (await res.json()) as { ok?: boolean; data?: FacDocumentoPOS[] }
                    if (json.ok && json.data) { setPendingDocs(json.data); setPendingCount(json.data.length) }
                  })
                  .catch(() => undefined)
                  .finally(() => setPendingLoading(false))
              }

              if (hasItems) {
                if (needsRefModal()) {
                  // Pedir referencia; al confirmar guardará y abrirá la lista
                  setRefReferencia(referenceValue)
                  setRefModalThenOpenPending(true)
                  setRefModalOpen(true)
                } else {
                  // Guardar silenciosamente y luego abrir lista
                  void (async () => {
                    await executeGuardarPendiente(referenceValue || undefined)
                    openPendingList()
                  })()
                }
              } else {
                openPendingList()
              }
            }}
          >
            <FileClock size={16} /> Fac. pendiente
            {pendingCount > 0 && <span className="billing-pos__pending-badge">{pendingCount}</span>}
          </button>
          <button
            type="button"
            className={comentarioGeneral ? "secondary-button is-active" : "secondary-button"}
            title={comentarioGeneral || undefined}
            onClick={() => setComentarioGeneralModalOpen(true)}
          >
            <MessageSquare size={16} /> Coment. Gral.
          </button>
          <div className="billing-pos__toolbar-menu billing-pos__toolbar-menu--footer" ref={optionsRef}>
            <button
              type="button"
              className={optionsOpen ? "secondary-button is-active" : "secondary-button"}
              onClick={() => setOptionsOpen((current) => !current)}
            >
              <SlidersHorizontal size={15} /> Opciones <ChevronDown size={13} />
            </button>
            {optionsOpen ? (
              <div className="billing-pos__toolbar-dropdown billing-pos__toolbar-dropdown--footer">
                {SIDE_ACTIONS.map((action) => {
                  const Icon = action.icon
                  return (
                    <button key={action.label} type="button" className="billing-pos__toolbar-dropdown-item" onClick={() => setOptionsOpen(false)}>
                      <Icon size={17} />
                      <span>{action.label}</span>
                    </button>
                  )
                })}
              </div>
            ) : null}
          </div>
          <button
            type="button"
            className="primary-button billing-pos__pay-button"
            onClick={() => {
              const hasItems = lines.some((l) => l.productId > 0)
              if (!hasItems) { toast.warning("Agrega al menos un ítem antes de cobrar."); return }
              const idPuntoEmision = selectedEmissionPoint?.id
              if (!idPuntoEmision) { toast.error("No hay punto de emisión configurado."); return }
              setMontoRecibido(totals.total.toFixed(2))
              setCobrarModalOpen(true)
              setFormasPago([])
              setFormasPagoLoading(true)
              void fetch(apiUrl(`/api/facturacion/formas-pago-cobro?idPuntoEmision=${idPuntoEmision}`), { credentials: "include" })
                .then(async (res) => {
                  const json = (await res.json()) as { ok?: boolean; data?: FacFormaPagoRecord[] }
                  if (json.ok && json.data) setFormasPago(json.data)
                })
                .catch(() => undefined)
                .finally(() => setFormasPagoLoading(false))
            }}
          >
            <CreditCard size={16} /> Cobrar
          </button>
        </div>
      </section>

      {quickPanelOpen ? (
        <section className="order-modal-backdrop" onClick={() => { setQuickPanelOpen(false); setPickerTargetLineKey(null) }}>
          <article className="data-panel order-modal order-modal--pos billing-pos__product-modal" onClick={(event) => event.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
              <div className="order-modal__titleline">
                <h2>{pickerTargetLineKey ? <><PackageSearch size={20} style={{ marginRight: 8, verticalAlign: "middle" }} />Buscar producto</> : <><Layers3 size={20} style={{ marginRight: 8, verticalAlign: "middle" }} />Venta rapida</>}</h2>
                <p>{pickerTargetLineKey ? "Selecciona un producto para completar la linea actual." : "Agrega productos al punto de ventas desde categorias reales."}</p>
              </div>
              <div className="order-modal__header-actions">
                <button className="secondary-button secondary-button--sm" type="button" onClick={() => { setQuickPanelOpen(false); setPickerTargetLineKey(null) }}>
                  Cancelar
                </button>
                {!pickerTargetLineKey ? (
                  <button className="primary-button primary-button--sm" type="button" onClick={saveTrayToLines}>
                    Guardar
                  </button>
                ) : null}
              </div>
            </div>

            <div className="order-create-form">
              <div className="order-pos-picker">
                <aside className="order-pos-picker__categories">
                  <button
                    type="button"
                    className={`order-pos-category${selectedCategory === "all" ? " is-selected" : ""}`}
                    onClick={() => setSelectedCategory("all")}
                  >
                    Todas
                  </button>
                  {visibleCategories.map((category) => {
                    const meta = productCategoryMeta.get(category.name)
                    return (
                      <button
                        key={category.id}
                        type="button"
                        className={`order-pos-category${selectedCategory === category.name ? " is-selected" : ""}${meta?.image ? " has-image" : ""}`}
                        onClick={() => setSelectedCategory(category.name)}
                        style={{
                          background: meta?.pastel ?? undefined,
                          color: meta?.ink ?? undefined,
                          borderColor: meta?.border ?? undefined,
                        }}
                      >
                        {meta?.image ? <span className="order-pos-category__image" style={{ backgroundImage: `url(${withImageVersion(meta.image)})` }} /> : null}
                        <span className="order-pos-category__label">{category.name}</span>
                      </button>
                    )
                  })}
                </aside>

                <div className="order-pos-picker__products">
                  <div className="orders-search-input orders-search-input--compact">
                    <Search size={16} />
                    <input
                      value={quickSearch}
                      onChange={(event) => setQuickSearch(event.target.value)}
                      placeholder="Buscar item en cualquier categoría"
                    />
                  </div>

                  <div className="order-pos-product-grid">
                    {visibleQuickItems.length ? visibleQuickItems.map((product) => (
                      <button
                        key={product.id}
                        type="button"
                        className={`order-pos-product${product.image ? " has-image" : ""}`}
                        onClick={() => {
                          if (pickerTargetLineKey) {
                            applyProductToLine(pickerTargetLineKey, product)
                            setQuickPanelOpen(false)
                            setPickerTargetLineKey(null)
                            return
                          }
                          addProductToTray(product)
                        }}
                        style={product.image ? {
                          background: `linear-gradient(180deg, rgba(255,255,255,0.05) 0%, rgba(15,23,42,0.46) 100%), url(${withImageVersion(product.image)}) center/cover no-repeat`,
                          color: "#ffffff",
                          borderColor: product.itemButtonBackground || undefined,
                        } : {
                          background: softenHexColor(product.itemButtonColor || product.itemButtonBackground || "#12467e", 0.82),
                          color: "#16324f",
                          borderColor: softenHexColor(product.itemButtonColor || product.itemButtonBackground || "#12467e", 0.58),
                        }}
                      >
                        {product.image ? <span className="order-pos-product__image" style={{ backgroundImage: `url(${withImageVersion(product.image)})` }} /> : null}
                        <div className="order-pos-product__body">
                          <strong>{product.name}</strong>
                          <span>{product.category}</span>
                        </div>
                        <div className="order-pos-product__pricing">
                          <b>{formatMoney(product.price)}</b>
                        </div>
                      </button>
                    )) : (
                      <div className="detail-empty detail-empty--compact">
                        <PackageSearch size={22} />
                        <h3>Sin productos</h3>
                        <p>No hay items para los filtros actuales.</p>
                      </div>
                    )}
                  </div>
                </div>

                {!pickerTargetLineKey ? (
                  <aside className="order-pos-tray">
                    <div className="order-pos-tray__header">
                      <strong>Bandeja</strong>
                      <span>{quickTray.length} item(s)</span>
                    </div>
                    <div className="order-pos-tray__list">
                      {quickTray.length ? quickTray.map((item) => {
                        const lineTotals = computeLineTotals(item, company, selectedDocument)
                        return (
                          <article key={item.key} className="order-pos-tray__item">
                            <div className="order-pos-tray__item-top">
                              <div className="order-pos-tray__item-main">
                                <div className="order-pos-tray__item-title">
                                  <strong>{item.description}</strong>
                                </div>
                                <span>{item.code} · {item.unit}</span>
                              </div>
                            </div>
                            <div className="order-pos-tray__controls">
                              <div className="order-pos-tray__controls-row">
                                <div className="order-pos-tray__qty order-pos-tray__qty--negative">
                                  {([-10, -5, -1] as const).map((delta) => (
                                    <button
                                      key={delta}
                                      type="button"
                                      className="order-pos-tray__qty-btn"
                                      onClick={() => updateTrayQuantity(item.key, item.quantity + delta)}
                                    >
                                      {String(delta)}
                                    </button>
                                  ))}
                                </div>
                                <input
                                  className="order-pos-tray__qty-input"
                                  type="number"
                                  min="1"
                                  step="1"
                                  value={item.quantity}
                                  onChange={(event) => updateTrayQuantity(item.key, Number(event.target.value || 1))}
                                />
                                <div className="order-pos-tray__qty order-pos-tray__qty--positive">
                                  {([1, 5, 10] as const).map((delta) => (
                                    <button
                                      key={delta}
                                      type="button"
                                      className="order-pos-tray__qty-btn is-positive"
                                      onClick={() => updateTrayQuantity(item.key, item.quantity + delta)}
                                    >
                                      {`+${delta}`}
                                    </button>
                                  ))}
                                </div>
                              </div>
                              <div className="order-pos-tray__controls-meta">
                                <b className="order-pos-tray__line-total">RD$ {formatMoney(lineTotals.lineTotal)}</b>
                                <button type="button" className="ghost-icon-button" onClick={() => removeTrayItem(item.key)}>
                                  <Trash2 size={15} />
                                </button>
                              </div>
                            </div>
                          </article>
                        )
                      }) : (
                        <div className="detail-empty detail-empty--compact">
                          <CreditCard size={20} />
                          <h3>Bandeja vacía</h3>
                          <p>Selecciona productos y agrégalos para confirmar en lote.</p>
                        </div>
                      )}
                    </div>
                    <div className="order-pos-tray__footer">
                      <span>Total bandeja</span>
                      <strong>RD$ {formatMoney(quickTrayTotal)}</strong>
                    </div>
                  </aside>
                ) : null}
              </div>
            </div>
          </article>
        </section>
      ) : null}

      {editPriceLine ? (() => {
        const taxFactor = editPriceLine.applyTax ? (1 + editPriceLine.taxRate / 100) : 1
        const applyBase = (raw: string) => {
          const base = Math.max(0, Number(raw) || 0)
          setEditPriceBase(raw)
          setEditPriceFinal((base * taxFactor).toFixed(4))
        }
        const applyFinal = (raw: string) => {
          const final = Math.max(0, Number(raw) || 0)
          setEditPriceFinal(raw)
          setEditPriceBase((final / taxFactor).toFixed(4))
        }
        const applyAndClose = () => {
          updateLinePrice(editPriceLine.key, Math.max(0, Number(editPriceBase) || 0))
          setEditPriceLine(null)
        }
        return (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--lg modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><Pencil size={18} /></div>
              <div>
                <h3 className="modal-card__title">Cambiar precio</h3>
                <p className="modal-card__subtitle">{editPriceLine.description || editPriceLine.code || "Línea sin descripción"}</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--price">

              {/* Listas de precios */}
              <div className="billing-pos__price-lists-section">
                <span className="billing-pos__price-lists-section-title">Listas de precios</span>
                {priceListsLoading ? (
                  <p className="billing-pos__price-lists-loading">Cargando...</p>
                ) : priceListsForLine.length === 0 ? (
                  <p className="billing-pos__price-lists-empty">No hay listas de precios disponibles.</p>
                ) : (
                  <table className="billing-pos__price-table">
                    <thead>
                      <tr>
                        <th>Lista</th>
                        <th className="billing-pos__price-table-num">Precio base</th>
                        {editPriceLine.applyTax ? <th className="billing-pos__price-table-num">Precio final</th> : null}
                      </tr>
                    </thead>
                    <tbody>
                      {priceListsForLine.map((list) => (
                        <tr
                          key={list.id}
                          className={`billing-pos__price-table-row${list.price == null ? " is-empty" : ""}`}
                          onClick={() => {
                            if (list.price != null) {
                              setEditPriceBase(list.price.toFixed(4))
                              setEditPriceFinal((list.price * taxFactor).toFixed(4))
                            }
                          }}
                        >
                          <td>{list.description}</td>
                          <td className="billing-pos__price-table-num">
                            {list.price != null ? formatMoney(list.price) : "—"}
                          </td>
                          {editPriceLine.applyTax ? (
                            <td className="billing-pos__price-table-num billing-pos__price-table-final">
                              {list.price != null ? formatMoney(list.price * taxFactor) : "—"}
                            </td>
                          ) : null}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>

              {/* Precio manual */}
              <div className="billing-pos__price-manual-section">
                <span className="billing-pos__price-manual-section-title">Precio manual</span>
                <div className="billing-pos__price-manual-row">
                  <label className="billing-pos__price-manual-field">
                    <span>Precio base</span>
                    <input
                      type="number"
                      min="0"
                      step="0.0001"
                      autoFocus
                      value={editPriceBase}
                      onChange={(e) => applyBase(e.target.value)}
                      onKeyDown={(e) => { if (e.key === "Enter") applyAndClose() }}
                    />
                  </label>
                  {editPriceLine.applyTax ? (
                    <label className="billing-pos__price-manual-field">
                      <span>Precio final ({editPriceLine.taxRate}% ITBIS)</span>
                      <input
                        type="number"
                        min="0"
                        step="0.0001"
                        value={editPriceFinal}
                        onChange={(e) => applyFinal(e.target.value)}
                        onKeyDown={(e) => { if (e.key === "Enter") applyAndClose() }}
                      />
                    </label>
                  ) : null}
                </div>
              </div>

            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setEditPriceLine(null)}>Cancelar</button>
              <button type="button" className="primary-button" onClick={applyAndClose}>
                Aplicar precio
              </button>
            </div>
          </div>
        </div>
        )
      })() : null}

      {discountModalOpen ? (() => {
        const isLineMode = editDiscountLine != null
        const lineBase = isLineMode ? roundMoney(editDiscountLine!.basePrice * editDiscountLine!.quantity) : null
        const lineFinalPrice = isLineMode ? roundMoney(computeLineTotals(editDiscountLine!, company, selectedDocument).lineBase + computeLineTotals(editDiscountLine!, company, selectedDocument).lineTax) : null
        const docSubtotal = totals.subtotal
        const manualLimit = discountsForUser.find(d => d.limiteDescuentoManual != null)?.limiteDescuentoManual ?? null
        const manualBase = isLineMode ? lineBase! : docSubtotal
        const manualMaxAmount = manualLimit != null ? roundMoney(manualBase * (manualLimit / 100)) : null
        const manualValue = Number(editDiscountValue || 0)
        const manualExceeds = manualMaxAmount != null && manualValue > manualMaxAmount
        function closeDiscountModal() { setDiscountModalOpen(false); setEditDiscountLine(null) }

        function setFromPct(raw: string) {
          const pct = Math.max(0, Number(raw) || 0)
          const cap = manualLimit
          const clampedPct = cap != null ? Math.min(pct, cap) : pct
          const amt = roundMoney(manualBase * (clampedPct / 100))
          setEditDiscountPct(raw)
          setEditDiscountValue(String(amt))
          if (lineFinalPrice != null) setEditDiscountFinal(String(roundMoney(lineFinalPrice - amt)))
          setDiscountMode("manual")
        }

        function setFromAmount(raw: string) {
          const amt = Math.max(0, Number(raw) || 0)
          const cap = manualMaxAmount
          const clamped = cap != null ? Math.min(amt, cap) : amt
          setEditDiscountValue(String(clamped))
          setEditDiscountPct(manualBase > 0 ? String(roundMoney((clamped / manualBase) * 100)) : "")
          if (lineFinalPrice != null) setEditDiscountFinal(String(roundMoney(lineFinalPrice - clamped)))
          setDiscountMode("manual")
        }

        function setFromFinal(raw: string) {
          if (lineFinalPrice == null) return
          const final = Math.max(0, Number(raw) || 0)
          const disc = Math.max(0, roundMoney(lineFinalPrice - final))
          const cap = manualMaxAmount
          const clamped = cap != null ? Math.min(disc, cap) : disc
          setEditDiscountFinal(raw)
          setEditDiscountValue(String(clamped))
          setEditDiscountPct(manualBase > 0 ? String(roundMoney((clamped / manualBase) * 100)) : "")
          setDiscountMode("manual")
        }

        function applyDiscount(amount: number, esGlobal: boolean) {
          if (esGlobal || !isLineMode) {
            applyGlobalDiscount(amount)
          } else {
            updateLineDiscount(editDiscountLine!.key, amount)
          }
          closeDiscountModal()
        }

        return (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--md modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><Percent size={18} /></div>
              <div>
                <h3 className="modal-card__title">Aplicar descuento</h3>
                <p className="modal-card__subtitle">{isLineMode ? (editDiscountLine!.description || editDiscountLine!.code || "Línea sin descripción") : "Descuento al documento completo"}</p>
              </div>
            </div>

            <div className="modal-card__body modal-card__body--price">

              {/* ── Sección lista de descuentos ── */}
              <div className="billing-pos__price-lists-section">
                <div className="billing-pos__price-lists-section-title">DESCUENTOS DISPONIBLES</div>
                {discountsLoading ? (
                  <div className="billing-pos__price-loading"><Loader2 size={16} className="spin" /> Cargando...</div>
                ) : discountsForUser.length === 0 ? (
                  <p className="billing-pos__price-loading">No hay descuentos disponibles para tu usuario.</p>
                ) : (
                  <table className="billing-pos__price-table">
                    <thead>
                      <tr>
                        <th>Descuento</th>
                        <th className="billing-pos__price-table-num">%</th>
                        <th className="billing-pos__price-table-num">Monto</th>
                        <th className="billing-pos__price-table-num">Aplica a</th>
                      </tr>
                    </thead>
                    <tbody>
                      {discountsForUser.filter((d) => isLineMode || d.esGlobal).map((d) => {
                        const base = d.esGlobal ? docSubtotal : lineBase!
                        const amount = roundMoney(base * (d.porcentaje / 100))
                        return (
                          <tr
                            key={d.id}
                            className="billing-pos__price-table-row"
                            onClick={() => applyDiscount(amount, d.esGlobal)}
                            title={d.esGlobal ? "Aplica a todo el documento" : "Aplica a la línea seleccionada"}
                          >
                            <td>{d.name}</td>
                            <td className="billing-pos__price-table-num">{d.porcentaje}%</td>
                            <td className="billing-pos__price-table-num billing-pos__price-table-final">{formatMoney(amount)}</td>
                            <td className="billing-pos__price-table-num">{d.esGlobal ? "Documento" : "Línea"}</td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                )}
              </div>

              {/* ── Sección descuento manual ── */}
              <div className="billing-pos__price-manual-section">
                <div className="billing-pos__price-manual-section-title">
                  DESCUENTO MANUAL
                  {manualLimit != null && <span className="billing-pos__price-manual-limit-badge">Límite {manualLimit}% — máx {formatMoney(manualMaxAmount!)}</span>}
                  {!isLineMode && <span className="billing-pos__price-manual-limit-badge" style={{background:"var(--blue-soft,#dbeafe)",color:"var(--blue-text,#1d4ed8)"}}>Se aplica al documento completo</span>}
                </div>
                <div className="billing-pos__price-manual-row">
                  <div className="billing-pos__price-manual-field">
                    <span>% Descuento</span>
                    <input
                      type="number"
                      min="0"
                      max={manualLimit ?? undefined}
                      step="1"
                      placeholder="0"
                      value={editDiscountPct}
                      onChange={(e) => setFromPct(e.target.value)}
                      onKeyDown={(e) => { if (e.key === "Enter" && !manualExceeds) applyDiscount(manualValue, false) }}
                    />
                  </div>
                  <div className="billing-pos__price-manual-field">
                    <span>Monto descuento</span>
                    <input
                      type="number"
                      min="0"
                      max={manualMaxAmount ?? undefined}
                      step="0.01"
                      placeholder="0.00"
                      value={editDiscountValue || ""}
                      onChange={(e) => setFromAmount(e.target.value)}
                      onFocus={() => setDiscountMode("manual")}
                      onKeyDown={(e) => { if (e.key === "Enter" && !manualExceeds) applyDiscount(manualValue, false) }}
                      style={manualExceeds ? { borderColor: "var(--rose-text, #d91c5c)" } : undefined}
                      autoFocus
                    />
                  </div>
                  {isLineMode && (
                  <div className="billing-pos__price-manual-field">
                    <span>Precio final c/desc.</span>
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      placeholder={formatMoney(lineFinalPrice!)}
                      value={editDiscountFinal}
                      onChange={(e) => setFromFinal(e.target.value)}
                      onKeyDown={(e) => { if (e.key === "Enter" && !manualExceeds) applyDiscount(manualValue, false) }}
                    />
                  </div>
                  )}
                </div>
                {manualExceeds && (
                  <p className="billing-pos__discount-limit-warn">
                    Excede el límite permitido de {formatMoney(manualMaxAmount!)}
                  </p>
                )}
              </div>

            </div>

            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={closeDiscountModal}>Cancelar</button>
              <button
                type="button"
                className="primary-button"
                disabled={discountMode === "manual" && manualExceeds}
                onClick={() => applyDiscount(discountMode === "manual" ? manualValue : 0, !isLineMode)}
              >
                Aplicar descuento
              </button>
            </div>
          </div>
        </div>
        )
      })() : null}

      {customerModalOpen ? (() => {
        const activeTerm = customerAutomode ? customerSearch : customerCommitted
        const q = activeTerm.trim().toLowerCase()
        const filtered = q.length < 2
          ? []
          : customers.filter((c) =>
              c.name.toLowerCase().includes(q) ||
              c.shortName.toLowerCase().includes(q) ||
              c.documento.toLowerCase().includes(q) ||
              c.code.toLowerCase().includes(q)
            )

        return (
          <section className="order-modal-backdrop">
            <article className="data-panel order-modal order-modal--product-search" onClick={(e) => e.stopPropagation()}>

              <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
                <div className="order-modal__titleline">
                  <h2><UserRound size={20} style={{ marginRight: 8, verticalAlign: "middle" }} />Clientes</h2>
                  <p>{selectedCustomer ? `Cliente actual: ${selectedCustomer.name}` : "Selecciona un cliente para aplicar su lista de precios, descuento y comprobante."}</p>
                </div>
                <div className="order-modal__header-actions">
                  <label className="billing-pos__search-automode-toggle">
                    <button
                      type="button"
                      className={customerAutomode ? "toggle-switch is-on" : "toggle-switch"}
                      onClick={() => { const next = !customerAutomode; setCustomerAutomode(next); if (next) setCustomerCommitted(customerSearch) }}
                    >
                      <span />
                    </button>
                    <span className="billing-pos__search-automode-label">Auto</span>
                  </label>
                  {selectedCustomer && (
                    <button
                      type="button"
                      className="secondary-button secondary-button--sm"
                      onClick={() => void applyCustomer(null)}
                      disabled={customerApplying}
                    >
                      <X size={14} /> Cerrar
                    </button>
                  )}
                  <button className="secondary-button secondary-button--sm" type="button" onClick={() => { setCustomerModalOpen(false); setCustomerSearch("") }}>
                    Cerrar
                  </button>
                </div>
              </div>

              <div className="billing-pos__search-modal-body">
                <div className="billing-pos__search-modal-filters">
                  <div className="billing-pos__search-input-row">
                    <div className="orders-search-input">
                      <Search size={16} />
                      <input
                        autoFocus
                        value={customerSearch}
                        onChange={(e) => { setCustomerSearch(e.target.value); if (customerAutomode) setCustomerCommitted(e.target.value) }}
                        onKeyDown={(e) => { if (e.key === "Enter" && !customerAutomode) setCustomerCommitted(customerSearch) }}
                        placeholder="Buscar por nombre, RNC/cédula o código..."
                      />
                      {customerSearch ? (
                        <button type="button" className="ghost-icon-button" onClick={() => { setCustomerSearch(""); setCustomerCommitted("") }}>
                          <X size={14} />
                        </button>
                      ) : null}
                    </div>
                    {!customerAutomode && (
                      <button type="button" className="primary-button primary-button--sm" onClick={() => setCustomerCommitted(customerSearch)}>
                        <Search size={14} /> Buscar
                      </button>
                    )}
                  </div>
                </div>

                <div className="billing-pos__search-modal-list">
                  {q.length < 2 ? (
                    <div className="detail-empty">
                      <Search size={28} />
                      <h3>Escribe para buscar</h3>
                      <p>Ingresa al menos 2 caracteres para ver clientes.</p>
                    </div>
                  ) : filtered.length === 0 ? (
                    <div className="detail-empty">
                      <Search size={28} />
                      <h3>Sin resultados</h3>
                      <p>No se encontraron clientes con ese criterio.</p>
                    </div>
                  ) : (
                    <table className="billing-pos__search-table">
                      <thead>
                        <tr>
                          <th className="billing-pos__search-col--code">Código</th>
                          <th className="billing-pos__search-col--name">Nombre</th>
                          <th>RNC / Cédula</th>
                          <th>Lista de precios</th>
                          <th>Comprobante</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filtered.map((c) => {
                          const isActive = c.id === selectedCustomerId
                          const taxVoucher = taxVoucherTypes.find((t) => t.id === c.idTipoComprobante)
                          return (
                            <tr
                              key={c.id}
                              className={`billing-pos__search-row${isActive ? " is-selected" : ""}`}
                              onClick={() => { if (!customerApplying) void applyCustomer(c) }}
                            >
                              <td className="billing-pos__search-col--code">{c.code || "—"}</td>
                              <td className="billing-pos__search-col--name">
                                {c.name}
                                {c.shortName && c.shortName !== c.name && (
                                  <span style={{ color: "var(--muted-text)", fontSize: "0.78em", marginLeft: 6 }}>{c.shortName}</span>
                                )}
                              </td>
                              <td>{c.documento || "—"}</td>
                              <td>{c.nombreListaPrecio || "—"}</td>
                              <td>{taxVoucher?.nombreInterno || taxVoucher?.nombre || "—"}</td>
                            </tr>
                          )
                        })}
                      </tbody>
                    </table>
                  )}

                  {customerApplying && (
                    <div className="billing-pos__price-loading" style={{ padding: "12px 0" }}>
                      <Loader2 size={15} className="spin" /> Aplicando precios y descuentos...
                    </div>
                  )}
                </div>
              </div>

            </article>
          </section>
        )
      })() : null}

      {/* ── Modal: pedir nombre + referencia ──────────────────── */}
      {refModalOpen ? (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><FileClock size={18} /></div>
              <div>
                <h3 className="modal-card__title">Guardar factura</h3>
                <p className="modal-card__subtitle">Ingresa una referencia para identificar este documento.</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <label style={{ display: "grid", gridTemplateColumns: "auto 1fr", alignItems: "center", gap: "10px" }}>
                <span style={{ fontSize: "0.875rem", fontWeight: 500, color: "var(--muted-text)", whiteSpace: "nowrap" }}>Referencia</span>
                <input
                  className="input"
                  type="text"
                  autoFocus
                  value={refReferencia}
                  onChange={(e) => setRefReferencia(e.target.value)}
                  placeholder="Ej: Mesa 5, Pedido web, Habitación 12..."
                  onKeyDown={(e) => { if (e.key === "Enter") void executeGuardarPendiente(refReferencia) }}
                />
              </label>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setRefModalOpen(false)} disabled={refSaving}>
                Cancelar
              </button>
              <button
                type="button"
                className="primary-button"
                disabled={refSaving}
                onClick={() => void executeGuardarPendiente(refReferencia.trim() || undefined)}
              >
                {refSaving ? <><Loader2 size={14} className="spin" /> Guardando...</> : "Guardar"}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {/* ── Modal: Cobrar ────────────────── */}
      {cobrarModalOpen ? (() => {
        const monto = parseFloat(montoRecibido) || 0
        const vuelto = roundMoney(monto - totals.total)
        const currSymbol = currencies.find((c) => c.id === (selectedDocument?.idMoneda ?? null))?.symbol ?? "RD$"

        async function confirmarCobro(idFormaPago: number) {
          if (cobrarProcessing) return
          // Build pagos array
          let pagos: Array<{ idFormaPago: number; monto: number; referencia?: string }> = []
          if (idFormaPago === 0) {
            // Mixto: use mixtoLineas
            pagos = mixtoLineas
              .filter((l) => parseFloat(l.monto) > 0)
              .map((l) => ({ idFormaPago: l.idFormaPago, monto: parseFloat(l.monto), referencia: l.referencia || undefined }))
          } else {
            pagos = [{ idFormaPago, monto: monto }]
          }
          if (pagos.length === 0) { toast.error("Ingresa el monto recibido."); return }
          // Need a saved borrador to emit
          const idPuntoEmision = selectedEmissionPoint?.id
          if (!idPuntoEmision) { toast.error("No hay punto de emisión configurado."); return }
          setCobrarProcessing(true)
          try {
            // 1. Save/update borrador if not yet saved
            let idDocumentoPOS = activePosDocId
            if (!idDocumentoPOS) {
              const lineas = buildLineasPayload()
              if (lineas.length === 0) { toast.warning("Agrega al menos un ítem."); setCobrarProcessing(false); return }
              const saveRes = await fetch(apiUrl("/api/facturacion/pos-documentos"), {
                method: "POST", credentials: "include",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  idPuntoEmision,
                  idCliente: selectedCustomerId,
                  idTipoDocumento: selectedDocumentId,
                  idAlmacen: selectedWarehouseId,
                  fechaDocumento: invoiceDateValue,
                  vendedor: sellerName,
                  comentarioGeneral: comentarioGeneral || null,
                  idMoneda: selectedDocument?.idMoneda ?? null,
                  tasaCambio: 1,
                  lineas,
                }),
              })
              const saveJson = (await saveRes.json()) as { ok?: boolean; data?: { id?: number }; message?: string }
              if (!saveJson.ok) throw new Error(saveJson.message ?? "Error al guardar borrador")
              idDocumentoPOS = saveJson.data?.id ?? null
            }
            if (!idDocumentoPOS) throw new Error("No se pudo obtener el ID del documento borrador")
            // 2. Emit
            const emitRes = await fetch(apiUrl("/api/facturacion/pos-cobros"), {
              method: "POST", credentials: "include",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ idDocumentoPOS, idSesionCaja: null, pagos }),
            })
            const emitJson = (await emitRes.json()) as { ok?: boolean; data?: { idDocumento?: number; secuencia?: number; ncf?: string; documentoSecuencia?: string; total?: number }; message?: string }
            if (!emitJson.ok) throw new Error(emitJson.message ?? "Error al emitir factura")
            const doc = emitJson.data
            setCobrarModalOpen(false)
            setActivePosDocId(null)
            const seqLabel = doc?.secuencia ? ` #${doc.secuencia}` : ""
            const ncfLabel = doc?.ncf ? ` NCF: ${doc.ncf}` : ""
            if (vuelto > 0) toast.success(`Factura emitida${seqLabel}${ncfLabel}. Vuelto: ${currSymbol} ${formatMoney(vuelto)}`)
            else toast.success(`Factura emitida${seqLabel}${ncfLabel}`)
            resetPos()
            refreshPendingCount()
          } catch (err) {
            toast.error(err instanceof Error ? err.message : "Error al cobrar")
          } finally {
            setCobrarProcessing(false)
          }
        }

        return (
          <div className="modal-backdrop">
            <div className="cobrar-modal" onClick={(e) => e.stopPropagation()}>

              {/* Barra de acciones secundarias */}
              <div className="cobrar-modal__actions-bar">
                <button type="button" className="cobrar-modal__action-btn cobrar-modal__action-btn--cancel" onClick={() => setCobrarModalOpen(false)} disabled={cobrarProcessing}>
                  <X size={20} />
                  <span>Cancelar</span>
                </button>
                {hasPermission("facturacion.cotizaciones.view") && (
                  <button type="button" className="cobrar-modal__action-btn" onClick={() => { setCobrarModalOpen(false); toast.info("Enviar a Cotización — próximamente") }}>
                    <FilePlus2 size={20} />
                    <span>Enviar a Cotización</span>
                  </button>
                )}
                {hasPermission("facturacion.ordenes-pedido.view") && (
                  <button type="button" className="cobrar-modal__action-btn" onClick={() => { setCobrarModalOpen(false); toast.info("Enviar a Pedidos — próximamente") }}>
                    <Layers3 size={20} />
                    <span>Enviar a Pedidos</span>
                  </button>
                )}
                {hasPermission("facturacion.conduces.view") && (
                  <button type="button" className="cobrar-modal__action-btn" onClick={() => { setCobrarModalOpen(false); toast.info("Enviar a Conduce — próximamente") }}>
                    <PackageSearch size={20} />
                    <span>Enviar a Conduce</span>
                  </button>
                )}
              </div>

              {/* Cuerpo: izquierda (totales + monto recibido) + derecha (formas de pago) */}
              <div className="cobrar-modal__body">

                {/* Panel izquierdo */}
                <div className="cobrar-modal__left">
                  <table className="cobrar-modal__totals-table">
                    <tbody>
                      <tr>
                        <td>Sub-Total</td>
                        <td className="cobrar-modal__amount">{currSymbol} {formatMoney(totals.subtotal)}</td>
                      </tr>
                      <tr>
                        <td>- Descuentos</td>
                        <td className="cobrar-modal__amount">- {currSymbol} {formatMoney(totals.discount)}</td>
                      </tr>
                      <tr>
                        <td>+ {company.taxName || "ITBIS"}</td>
                        <td className="cobrar-modal__amount">{currSymbol} {formatMoney(totals.tax)}</td>
                      </tr>
                      {totals.tip > 0 && (
                        <tr>
                          <td>+ {company.tipName || "Propina legal"}</td>
                          <td className="cobrar-modal__amount">{currSymbol} {formatMoney(totals.tip)}</td>
                        </tr>
                      )}
                      <tr className="cobrar-modal__totals-table--total">
                        <td>Total a Cobrar</td>
                        <td className="cobrar-modal__amount">{currSymbol} {formatMoney(totals.total)}</td>
                      </tr>
                    </tbody>
                  </table>

                  {/* Monto recibido */}
                  <div className="cobrar-modal__monto-row">
                    <label className="cobrar-modal__monto-label">Monto Recibido</label>
                    <input
                      className="input cobrar-modal__monto-input"
                      type="text"
                      inputMode="decimal"
                      autoFocus
                      value={montoRecibido}
                      onChange={(e) => setMontoRecibido(e.target.value)}
                      onFocus={(e) => e.target.select()}
                    />
                  </div>

                  {/* Devuelta */}
                  <div className="cobrar-modal__devuelta-row">
                    <span>Devuelta</span>
                    <span className={`cobrar-modal__devuelta-value${vuelto > 0 ? " cobrar-modal__devuelta-value--ok" : vuelto < 0 ? " cobrar-modal__devuelta-value--warn" : ""}`}>
                      {vuelto >= 0 ? `${currSymbol} ${formatMoney(vuelto)}` : `- ${currSymbol} ${formatMoney(Math.abs(vuelto))}`}
                    </span>
                  </div>

                  {showSecondaryCurrencyTotal && (
                    <div className="cobrar-modal__secondary-currency">
                      <span>Total {secondaryCurrencyCode}</span>
                      <span>{secondaryCurrency?.symbol ?? secondaryCurrencyCode} {formatMoney(totalSecondaryCurrency)}</span>
                    </div>
                  )}

                  <p className="cobrar-modal__hint">Selecciona una forma de pago →</p>
                </div>

                {/* Panel derecho: grid de formas de pago */}
                <div className="cobrar-modal__right">
                  {formasPagoLoading ? (
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", color: "var(--muted, #61728d)" }}>
                      <Loader2 size={24} className="spin" />
                    </div>
                  ) : formasPago.length === 0 ? (
                    <p style={{ color: "var(--muted, #61728d)", fontSize: "0.875rem", padding: "1rem" }}>Sin formas de pago configuradas.</p>
                  ) : (
                    <div className="cobrar-modal__fp-grid">
                      {formasPago.map((fp, idx) => (
                        <button
                          key={fp.id}
                          type="button"
                          className="cobrar-modal__fp-btn"
                          style={fp.colorFondo ? { borderColor: fp.colorFondo } : {}}
                          disabled={cobrarProcessing || monto < totals.total}
                          onClick={() => confirmarCobro(fp.id)}
                        >
                          <span className="cobrar-modal__fp-num">{idx + 1}</span>
                          <span className="cobrar-modal__fp-icon">{getFormaPagoIcon(fp.tipoValor, 26)}</span>
                          <span className="cobrar-modal__fp-name">{fp.descripcion}</span>
                        </button>
                      ))}
                      {formasPago.some((fp) => fp.mostrarEnCobrosMixtos) && (
                        <button
                          type="button"
                          className="cobrar-modal__fp-btn cobrar-modal__fp-btn--mixto"
                          disabled={cobrarProcessing}
                          onClick={() => {
                            const mixtas = formasPago.filter((fp) => fp.mostrarEnCobrosMixtos)
                            setMixtoLineas(mixtas.map((fp) => ({ idFormaPago: fp.id, monto: "", referencia: "" })))
                            setMixtoOpen(true)
                          }}
                        >
                          <span className="cobrar-modal__fp-num">{formasPago.length + 1}</span>
                          <span className="cobrar-modal__fp-icon"><Layers3 size={26} /></span>
                          <span className="cobrar-modal__fp-name">Mixto</span>
                        </button>
                      )}
                    </div>
                  )}
                </div>
              </div>

              {/* ── Sub-modal Pago Mixto ─────────────────────── */}
              {mixtoOpen ? (() => {
                const mixtoTotal = roundMoney(mixtoLineas.reduce((sum, l) => sum + (parseFloat(l.monto) || 0), 0))
                const mixtoFaltante = roundMoney(totals.total - mixtoTotal)
                const mixtoListo = mixtoTotal >= totals.total
                return (
                  <div className="modal-backdrop">
                    <div className="modal-card modal-card--elevated" style={{ width: "min(560px, 94vw)" }} onClick={(e) => e.stopPropagation()}>
                      <div className="modal-card__header">
                        <div className="modal-card__header-icon"><Layers3 size={18} /></div>
                        <div>
                          <h3 className="modal-card__title">Detalle de Pago Mixto</h3>
                          <p className="modal-card__subtitle">Total a cobrar: {currSymbol} {formatMoney(totals.total)}</p>
                        </div>
                        <button type="button" className="modal-card__close" onClick={() => setMixtoOpen(false)}><X size={16} /></button>
                      </div>
                      <div className="modal-card__body" style={{ padding: 0 }}>
                        <table className="mixto-table">
                          <thead>
                            <tr>
                              <th>Forma de Pago</th>
                              <th>Monto Recibido</th>
                              <th>Devuelta</th>
                            </tr>
                          </thead>
                          <tbody>
                            {mixtoLineas.map((linea) => {
                              const fp = formasPago.find((f) => f.id === linea.idFormaPago)
                              const montoLinea = parseFloat(linea.monto) || 0
                              const devueltaLinea = montoLinea > 0 ? roundMoney(montoLinea - 0) : 0
                              return (
                                <tr key={linea.idFormaPago}>
                                  <td className="mixto-table__fp-name">{fp?.descripcion ?? "—"}</td>
                                  <td>
                                    <input
                                      className="input mixto-table__input"
                                      type="text"
                                      inputMode="decimal"
                                      placeholder="0.00"
                                      value={linea.monto}
                                      onChange={(e) => setMixtoLineas((prev) => prev.map((l) => l.idFormaPago === linea.idFormaPago ? { ...l, monto: e.target.value } : l))}
                                      onFocus={(e) => e.target.select()}
                                    />
                                  </td>
                                  <td className="mixto-table__devuelta">
                                    {montoLinea > 0 ? `${currSymbol} ${formatMoney(montoLinea)}` : ""}
                                  </td>
                                </tr>
                              )
                            })}
                          </tbody>
                          <tfoot>
                            <tr>
                              <td colSpan={2} style={{ textAlign: "right", fontWeight: 700, padding: "0.5rem 0.75rem" }}>
                                {mixtoFaltante > 0
                                  ? <span style={{ color: "#dc2626" }}>Diferencia: - {currSymbol} {formatMoney(mixtoFaltante)}</span>
                                  : mixtoFaltante < 0
                                  ? <span style={{ color: "#16a34a" }}>Devuelta: {currSymbol} {formatMoney(Math.abs(mixtoFaltante))}</span>
                                  : <span style={{ color: "#16a34a" }}>Cubierto ✓</span>}
                              </td>
                              <td className="mixto-table__devuelta" style={{ fontWeight: 700 }}>
                                {currSymbol} {formatMoney(mixtoTotal)}
                              </td>
                            </tr>
                          </tfoot>
                        </table>
                      </div>
                      <div className="modal-card__footer">
                        <button type="button" className="secondary-button" onClick={() => setMixtoOpen(false)}>Cancelar</button>
                        <button
                          type="button"
                          className="primary-button"
                          disabled={!mixtoListo || cobrarProcessing}
                          onClick={() => {
                            setMixtoOpen(false)
                            confirmarCobro(0)
                          }}
                        >
                          <CreditCard size={15} /> Aceptar
                        </button>
                      </div>
                    </div>
                  </div>
                )
              })() : null}

            </div>
          </div>
        )
      })() : null}

      {/* ── Modal: Comentario General ────────────────── */}
      {comentarioGeneralModalOpen ? (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><MessageSquare size={18} /></div>
              <div>
                <h3 className="modal-card__title">Comentario General</h3>
                <p className="modal-card__subtitle">Nota interna del documento (no impresa).</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <textarea
                className="input"
                rows={4}
                autoFocus
                value={comentarioGeneral}
                onChange={(e) => setComentarioGeneral(e.target.value)}
                placeholder="Comentario o instrucción general para este documento..."
                maxLength={500}
                style={{ resize: "vertical", minHeight: 90 }}
              />
              <span style={{ fontSize: "0.75rem", color: "var(--muted-text)", textAlign: "right" }}>{comentarioGeneral.length}/500</span>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setComentarioGeneralModalOpen(false)}>Cancelar</button>
              <button type="button" className="primary-button" onClick={() => setComentarioGeneralModalOpen(false)}>Aceptar</button>
            </div>
          </div>
        </div>
      ) : null}

      {/* ── Modal: Comentario de Línea ────────────────── */}
      {comentarioLineaModalOpen ? (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header">
              <div className="modal-card__header-icon"><MessageSquare size={18} /></div>
              <div>
                <h3 className="modal-card__title">Comentario de Línea</h3>
                <p className="modal-card__subtitle">
                  {lines.find((l) => l.key === activeLineKey)?.description || "Línea seleccionada"}
                </p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <textarea
                className="input"
                rows={3}
                autoFocus
                value={editComentarioLinea}
                onChange={(e) => setEditComentarioLinea(e.target.value)}
                placeholder="Instrucción o nota para esta línea (ej: sin cebolla, bien cocido)..."
                maxLength={300}
                style={{ resize: "vertical", minHeight: 72 }}
              />
              <span style={{ fontSize: "0.75rem", color: "var(--muted-text)", textAlign: "right" }}>{editComentarioLinea.length}/300</span>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setComentarioLineaModalOpen(false)}>Cancelar</button>
              <button
                type="button"
                className="primary-button"
                onClick={() => {
                  if (activeLineKey) {
                    setLines((prev) => prev.map((l) => l.key === activeLineKey ? { ...l, lineComment: editComentarioLinea } : l))
                  }
                  setComentarioLineaModalOpen(false)
                }}
              >
                Aceptar
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {/* ── Modal: lista de facturas pendientes ────────────────── */}
      {pendingModalOpen ? (
        <section className="order-modal-backdrop" onClick={() => setPendingModalOpen(false)}>
          <article className="data-panel order-modal order-modal--product-search" onClick={(e) => e.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
              <div className="order-modal__titleline">
                <h2><FileClock size={20} style={{ marginRight: 8, verticalAlign: "middle" }} />Facturas pendientes</h2>
              </div>
              <div className="order-modal__header-actions">
                <button className="secondary-button secondary-button--sm" type="button" onClick={() => setPendingModalOpen(false)}>
                  Cerrar
                </button>
              </div>
            </div>

            <div className="billing-pos__search-modal-body">
              <div className="billing-pos__search-modal-list">
                {pendingLoading ? (
                  <div className="detail-empty">
                    <Loader2 size={28} className="spin" />
                    <h3>Cargando...</h3>
                  </div>
                ) : pendingDocs.length === 0 ? (
                  <div className="detail-empty">
                    <FileClock size={28} />
                    <h3>Sin facturas pendientes</h3>
                    <p>No hay documentos pausados ni retornados en este punto de emisión.</p>
                  </div>
                ) : (
                  <table className="billing-pos__search-table">
                    <thead>
                      <tr>
                        <th className="billing-pos__search-col--code">#</th>
                        <th className="billing-pos__search-col--name">Cliente</th>
                        <th>Referencia</th>
                        <th>Origen</th>
                        <th>Tipo</th>
                        <th className="billing-pos__price-table-num">Items</th>
                        <th className="billing-pos__price-table-num">Total</th>
                        <th className="billing-pos__price-table-num">Fecha</th>
                        <th></th>
                      </tr>
                    </thead>
                    <tbody>
                      {pendingDocs.map((doc) => {
                        const isActive = doc.id === activePosDocId
                        const isLoading = pendingLoadingId === doc.id
                        const canLoad = !isLoading && !pendingLoadingId
                        const fechaStr = doc.fechaCreacion
                          ? new Date(doc.fechaCreacion.includes("T") ? doc.fechaCreacion : `${doc.fechaCreacion}T00:00:00`).toLocaleDateString()
                          : "—"
                        return (
                          <tr
                            key={doc.id}
                            className={`billing-pos__search-row${isActive ? " is-selected" : ""}`}
                            onDoubleClick={() => { if (canLoad) void handleCargarPendiente(doc) }}
                          >
                            <td className="billing-pos__search-col--code">{doc.id}</td>
                            <td className="billing-pos__search-col--name">{doc.referenciaCliente || "—"}</td>
                            <td>{doc.referencia || "—"}</td>
                            <td>
                              <span className="origin-badge origin-badge--pos" title="Borrador del Punto de Ventas">
                                <ShoppingCart size={10} /> POS
                              </span>
                            </td>
                            <td>{doc.nombreTipoDocumento || "—"}</td>
                            <td className="billing-pos__price-table-num">{doc.cantidadLineas}</td>
                            <td className="billing-pos__price-table-num">{doc.totalEstimado != null ? formatMoney(doc.totalEstimado) : "—"}</td>
                            <td className="billing-pos__price-table-num" style={{ fontSize: "0.8em", color: "var(--muted-text)" }}>
                              {fechaStr}
                            </td>
                            <td onClick={(e) => e.stopPropagation()} style={{ whiteSpace: "nowrap" }}>
                              {isLoading ? (
                                <Loader2 size={14} className="spin" />
                              ) : (
                                <div style={{ display: "flex", gap: "4px", alignItems: "center" }}>
                                  <button
                                    type="button"
                                    className="ghost-icon-button"
                                    title="Cargar en POS"
                                    disabled={!canLoad}
                                    style={{ color: "var(--brand)", background: "color-mix(in srgb, var(--brand) 8%, transparent)", border: "1px solid color-mix(in srgb, var(--brand) 20%, transparent)" }}
                                    onClick={() => { if (canLoad) void handleCargarPendiente(doc) }}
                                  >
                                    <LogIn size={16} />
                                  </button>
                                  <button
                                    type="button"
                                    className="ghost-icon-button"
                                    title="Anular"
                                    onClick={() => handleAnularPendiente(doc)}
                                  >
                                    <X size={16} />
                                  </button>
                                </div>
                              )}
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </article>
        </section>
      ) : null}

      {/* ── Confirmar anular pendiente ─────────────────────────── */}
      {confirmAnularDoc ? (
        <div className="modal-backdrop" onClick={() => setConfirmAnularDoc(null)}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--danger-soft">
              <div className="modal-card__header-icon modal-card__header-icon--danger"><X size={20} /></div>
              <div>
                <h3 className="modal-card__title">Anular factura pendiente</h3>
                <p className="modal-card__subtitle">#{confirmAnularDoc.id} — {confirmAnularDoc.referenciaCliente || "Sin referencia"}</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p className="modal-confirm-copy">
                {isPrivilegedUserType(currentViewer?.userType)
                  ? "¿Confirmas que deseas anular este documento? Esta acción no se puede deshacer."
                  : "Tu usuario no puede anular documentos directamente. Se requerirán credenciales de supervisor."}
              </p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setConfirmAnularDoc(null)}>Cancelar</button>
              <button type="button" className="danger-button" onClick={confirmAnularAndContinue}>
                {isPrivilegedUserType(currentViewer?.userType) ? "Anular" : "Continuar"}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {/* ── Supervisor: anular pendiente ───────────────────────── */}
      {supervisorAnularDoc ? (
        <div className="modal-backdrop">
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon"><ShieldAlert size={20} /></div>
              <div>
                <h3 className="modal-card__title">Autorización requerida</h3>
                <p className="modal-card__subtitle">Anular factura #{supervisorAnularDoc.id}</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <p className="modal-confirm-copy">Ingresa credenciales de un supervisor o administrador para continuar.</p>
              <label className="field-label">
                Usuario
                <input
                  className="input"
                  type="text"
                  autoFocus
                  value={supervisorAnularUsername}
                  onChange={(e) => setSupervisorAnularUsername(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") void verifySupervisorAndAnularDoc() }}
                />
              </label>
              <label className="field-label">
                Contraseña
                <input
                  className="input"
                  type="password"
                  value={supervisorAnularPassword}
                  onChange={(e) => setSupervisorAnularPassword(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") void verifySupervisorAndAnularDoc() }}
                />
              </label>
              {supervisorAnularMessage && <p className="modal-error-msg">{supervisorAnularMessage}</p>}
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => { setSupervisorAnularDoc(null); setSupervisorAnularMessage(null) }}>Cancelar</button>
              <button type="button" className="danger-button" onClick={() => void verifySupervisorAndAnularDoc()}>Autorizar y anular</button>
            </div>
          </div>
        </div>
      ) : null}

      {confirmReset ? (
        <div className="modal-backdrop" onClick={() => setConfirmReset(false)}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--danger-soft">
              <div className="modal-card__header-icon modal-card__header-icon--danger">
                <Trash2 size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Cancelar documento</h3>
                <p className="modal-card__subtitle">Punto de Ventas</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <div className="modal-confirm-copy">
                <strong>{lines.length} {lines.length === 1 ? "linea en el documento" : "lineas en el documento"}</strong>
                <p>Esta accion eliminara todas las lineas y reiniciara el POS a sus parametros base. No se puede deshacer.</p>
              </div>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setConfirmReset(false)}>
                Volver
              </button>
              <button type="button" className="danger-button" onClick={() => {
                resetPos()
                setConfirmReset(false)
              }}>
                <Trash2 size={15} /> Cancelar documento
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {confirmDeleteLine ? (
        <div className="modal-backdrop" onClick={resetDeleteAuthorizationFlow}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--danger-soft">
              <div className="modal-card__header-icon modal-card__header-icon--danger">
                <ShieldAlert size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Eliminar linea</h3>
                <p className="modal-card__subtitle">Punto de Ventas</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <div className="modal-confirm-copy">
                <strong>{confirmDeleteLine.description || confirmDeleteLine.code || "Linea sin descripcion"}</strong>
                {currentViewer?.canDeletePosLines || isPrivilegedUserType(currentViewer?.userType) ? (
                  <p>Tu perfil ya puede eliminar lineas del POS. Confirma si deseas continuar.</p>
                ) : (
                  <p>Tu usuario no puede eliminar lineas del POS directamente. Te pediremos credenciales de supervisor para continuar.</p>
                )}
              </div>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={resetDeleteAuthorizationFlow}>
                Volver
              </button>
              <button type="button" className="danger-button" onClick={confirmDeleteLineAndContinue}>
                Eliminar linea
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {confirmClosePos ? (
        <div className="modal-backdrop" onClick={() => setConfirmClosePos(false)}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--danger-soft">
              <div className="modal-card__header-icon modal-card__header-icon--danger">
                <X size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Cerrar punto de ventas</h3>
                <p className="modal-card__subtitle">Hay ítems digitados en documento actual.</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p className="modal-confirm-copy">
                Si cierras ahora, perderás cambios no guardados. Puedes guardarla como pendiente antes de salir, o cerrar de todas formas si no deseas conservarla.
              </p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setConfirmClosePos(false)}>
                Volver
              </button>
              <button
                type="button"
                className="primary-button"
                onClick={() => {
                  setConfirmClosePos(false)
                  handlePausar()
                }}
              >
                Guardar pendiente
              </button>
              <button type="button" className="danger-button" onClick={() => void closePosToWorkspace()} disabled={isClosingPos}>
                <X size={15} /> {isClosingPos ? "Saliendo..." : "Cerrar"}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {productSearchOpen ? (
        <section className="order-modal-backdrop">
          <article className="data-panel order-modal order-modal--product-search" onClick={(event) => event.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
              <div className="order-modal__titleline">
                <h2><PackageSearch size={20} style={{ marginRight: 8, verticalAlign: "middle" }} />Buscar productos</h2>
                <p>
                  {pickerTargetLineKey
                    ? "Selecciona un producto para completar la línea actual."
                    : productSearchSelected.size > 0
                      ? `${productSearchSelected.size} producto(s) seleccionado(s)`
                      : "Selecciona uno o más productos para agregar al documento."}
                </p>
              </div>
              <div className="order-modal__header-actions">
                <label className="billing-pos__search-automode-toggle">
                  <button
                    type="button"
                    className={productSearchAutomode ? "toggle-switch is-on" : "toggle-switch"}
                    onClick={() => {
                      const next = !productSearchAutomode
                      setProductSearchAutomode(next)
                      if (next) setProductSearchCommitted(productSearchQuery)
                    }}
                  >
                    <span />
                  </button>
                  <span className="billing-pos__search-automode-label">Auto</span>
                </label>
                <button className="secondary-button secondary-button--sm" type="button" onClick={closeProductSearch}>
                  Cerrar
                </button>
                <button
                  className="primary-button primary-button--sm"
                  type="button"
                  onClick={confirmProductSearch}
                  disabled={productSearchSelected.size === 0}
                >
                  {pickerTargetLineKey ? "Aplicar" : `Agregar${productSearchSelected.size > 0 ? ` (${productSearchSelected.size})` : ""}`}
                </button>
              </div>
            </div>

            <div className="billing-pos__search-modal-body">
              <div className="billing-pos__search-modal-filters">
                <div className="billing-pos__search-input-row">
                  <div className="orders-search-input">
                    <Search size={16} />
                    <input
                      autoFocus
                      value={productSearchQuery}
                      onChange={(event) => setProductSearchQuery(event.target.value)}
                      onKeyDown={(event) => {
                        if (event.key === "Enter" && !productSearchAutomode) commitProductSearch()
                      }}
                      placeholder="Buscar por nombre, código o categoría..."
                    />
                    {productSearchQuery ? (
                      <button type="button" className="ghost-icon-button" onClick={() => { setProductSearchQuery(""); setProductSearchCommitted("") }}>
                        <X size={14} />
                      </button>
                    ) : null}
                  </div>
                  {!productSearchAutomode ? (
                    <button type="button" className="primary-button primary-button--sm" onClick={commitProductSearch}>
                      <Search size={14} /> Buscar
                    </button>
                  ) : null}
                </div>
              </div>

              <div className="billing-pos__search-modal-list">
                {!productSearchActive ? (
                  <div className="detail-empty">
                    <Search size={28} />
                    <h3>Escribe para buscar</h3>
                    <p>Ingresa un nombre o código para ver productos.</p>
                  </div>
                ) : productSearchResults.length ? (
                  <table className="billing-pos__search-table">
                    <thead>
                      <tr>
                        <th className="billing-pos__search-col--check"></th>
                        <th className="billing-pos__search-col--code">Código</th>
                        <th className="billing-pos__search-col--name">Descripción</th>
                        <th className="billing-pos__search-col--cat">Categoría</th>
                        <th className="billing-pos__search-col--unit">Unidad</th>
                        <th className="billing-pos__search-col--price">Precio</th>
                        {!pickerTargetLineKey ? <th className="billing-pos__search-col--qty">Cantidad</th> : null}
                      </tr>
                    </thead>
                    <tbody>
                      {productSearchResults.map((product) => {
                        const isSelected = productSearchSelected.has(product.id)
                        const qty = productSearchSelected.get(product.id) ?? 1
                        return (
                          <tr
                            key={product.id}
                            className={`billing-pos__search-row${isSelected ? " is-selected" : ""}`}
                            onClick={() => toggleProductSearchItem(product.id)}
                          >
                            <td className="billing-pos__search-col--check">
                              <input
                                type="checkbox"
                                checked={isSelected}
                                readOnly
                                className="billing-pos__search-checkbox"
                              />
                            </td>
                            <td className="billing-pos__search-col--code">{product.code || "—"}</td>
                            <td className="billing-pos__search-col--name">{product.name}</td>
                            <td className="billing-pos__search-col--cat">{product.category}</td>
                            <td className="billing-pos__search-col--unit">{product.unitName || "UND"}</td>
                            <td className="billing-pos__search-col--price">{formatMoney(product.price)}</td>
                            {!pickerTargetLineKey ? (
                              <td className="billing-pos__search-col--qty" onClick={(e) => e.stopPropagation()}>
                                {isSelected ? (
                                  <input
                                    type="number"
                                    min="1"
                                    step="1"
                                    className="billing-pos__search-qty-input"
                                    value={qty}
                                    onChange={(e) => setProductSearchQty(product.id, Number(e.target.value || 1))}
                                  />
                                ) : (
                                  <span className="billing-pos__search-qty-placeholder">—</span>
                                )}
                              </td>
                            ) : null}
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                ) : (
                  <div className="detail-empty">
                    <PackageSearch size={28} />
                    <h3>Sin resultados</h3>
                    <p>No hay productos para los filtros actuales.</p>
                  </div>
                ) }
              </div>
            </div>
          </article>
        </section>
      ) : null}

      {supervisorDeleteLine ? (
        <div className="modal-backdrop" onClick={resetDeleteAuthorizationFlow}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand-soft">
              <div className="modal-card__header-icon modal-card__header-icon--brand">
                <ShieldCheck size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Credenciales de supervisor</h3>
                <p className="modal-card__subtitle">Introduce las credenciales para autorizar esta accion.</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <div className="modal-confirm-copy">
                <strong>Eliminar linea</strong>
                <p>{supervisorDeleteLine.description || supervisorDeleteLine.code || "Linea sin descripcion"}</p>
              </div>
              <label className="field-group">
                <span>Usuario supervisor</span>
                <input
                  value={supervisorUsername}
                  onChange={(event) => setSupervisorUsername(event.target.value)}
                  placeholder="Nombre de usuario"
                  autoComplete="username"
                />
              </label>
              <label className="field-group">
                <span>Clave supervisor</span>
                <input
                  type="password"
                  value={supervisorPassword}
                  onChange={(event) => setSupervisorPassword(event.target.value)}
                  placeholder="Clave"
                  autoComplete="current-password"
                />
              </label>
              {protectedMessage ? <p className="form-message">{protectedMessage}</p> : null}
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={resetDeleteAuthorizationFlow}>
                Cancelar
              </button>
              <button type="button" className="primary-button" onClick={() => { void verifySupervisorAndRemoveLine() }}>
                Autorizar y eliminar
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  )
}
