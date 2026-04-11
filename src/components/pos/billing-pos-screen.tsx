"use client"

import {
  ChevronDown,
  CreditCard,
  Loader2,
  FileClock,
  FilePlus2,
  HandCoins,
  Layers3,
  PackageSearch,
  Pencil,
  Percent,
  Plus,
  Search,
  ShieldAlert,
  ShieldCheck,
  SlidersHorizontal,
  Ticket,
  Trash2,
  UserRound,
  Warehouse,
  X,
} from "lucide-react"
import { useEffect, useMemo, useRef, useState } from "react"
import { toast } from "sonner"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import type {
  BranchRecord,
  CatalogoNCFRecord,
  CategoryRecord,
  CompanySettingsData,
  CurrencyRecord,
  DescuentoForUser,
  DescuentoRecord,
  EmissionPointRecord,
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
}

type QuickTrayItem = BillingPosLine & { key: string }

type CurrentViewer = {
  userId: number
  userType: "A" | "S" | "O"
  canDeletePosLines?: boolean
  canChangePosDate?: boolean
  username?: string
  fullName?: string
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

export function BillingPosScreen({ company, branches, emissionPoints, customers, categories, products, documentTypes, taxVoucherTypes, currencies, warehouses, discounts }: Props) {
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
  const [liveTime, setLiveTime] = useState("")
  const [quickSearch, setQuickSearch] = useState("")
  const [activeLineKey, setActiveLineKey] = useState<string | null>(null)
  const [pickerTargetLineKey, setPickerTargetLineKey] = useState<string | null>(null)
  const [productSearchOpen, setProductSearchOpen] = useState(false)
  const [productSearchQuery, setProductSearchQuery] = useState("")
  const [productSearchCommitted, setProductSearchCommitted] = useState("")
  const [productSearchAutomode, setProductSearchAutomode] = useState(true)
  const [productSearchSelected, setProductSearchSelected] = useState<Map<number, number>>(new Map())
  const [currentViewer, setCurrentViewer] = useState<CurrentViewer | null>(null)
  const [confirmReset, setConfirmReset] = useState(false)
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
  const [confirmDeleteLine, setConfirmDeleteLine] = useState<BillingPosLine | null>(null)
  const [supervisorDeleteLine, setSupervisorDeleteLine] = useState<BillingPosLine | null>(null)
  const [supervisorUsername, setSupervisorUsername] = useState("")
  const [supervisorPassword, setSupervisorPassword] = useState("")
  const [protectedMessage, setProtectedMessage] = useState<string | null>(null)
  const optionsRef = useRef<HTMLDivElement | null>(null)
  const lineKeyCounterRef = useRef(2)
  const getNextLineKey = () => {
    const nextKey = `line-${lineKeyCounterRef.current}`
    lineKeyCounterRef.current += 1
    return nextKey
  }
  const [lines, setLines] = useState<BillingPosLine[]>(() => [buildEmptyLine(INITIAL_LINE_KEY)])
  const [quickTray, setQuickTray] = useState<QuickTrayItem[]>([])
  const [selectedDocumentId, setSelectedDocumentId] = useState<number | null>(null)
  const [selectedWarehouseId, setSelectedWarehouseId] = useState<number | null>(warehouses[0]?.id ?? null)
  const [selectedCustomerId, setSelectedCustomerId] = useState<number | null>(null)
  const [sellerName, setSellerName] = useState("")
  const [referenceValue, setReferenceValue] = useState("")
  const [invoiceDateValue, setInvoiceDateValue] = useState("")

  const selectedBranch = branches[0] ?? null
  const selectedEmissionPoint = emissionPoints.find((item) => item.branchId === selectedBranch?.id) ?? emissionPoints[0] ?? null
  const cajaPosName = "Principal 01"
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
    if (!invoiceDateValue) {
      setInvoiceDateValue(getTodayIsoDate())
    }
  }, [invoiceDateValue])

  useEffect(() => {
    function formatNow() {
      return new Intl.DateTimeFormat("en-GB", {
        day: "2-digit",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
        hour12: true,
      }).format(new Date()).replace(",", "")
    }

    setLiveTime(formatNow())
    const interval = window.setInterval(() => setLiveTime(formatNow()), 1000)
    return () => window.clearInterval(interval)
  }, [])

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
    setInvoiceDateValue(getTodayIsoDate())
    setActiveLineKey(null)
    setOptionsOpen(false)
    setQuickPanelOpen(false)
    resetDeleteAuthorizationFlow()
  }

  function addProductToTray(product: OrderProductOption) {
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

  function handleCodeKeyDown(event: React.KeyboardEvent, line: BillingPosLine) {
    if (event.key === "Enter" || event.key === "Tab") {
      event.preventDefault()
      const resolved = resolveLineByCode(line.key, line.code)
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

  function openProductSearch() {
    setProductSearchQuery("")
    setProductSearchCommitted("")
    setProductSearchSelected(new Map())
    setProductSearchOpen(true)
  }

  function commitProductSearch() {
    setProductSearchCommitted(productSearchQuery)
  }

  function toggleProductSearchItem(productId: number) {
    setProductSearchSelected((current) => {
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
    if (!productSearchSelected.size) { setProductSearchOpen(false); return }
    setLines((current) => {
      const next = [...current]
      for (const [productId, qty] of productSearchSelected.entries()) {
        const product = products.find((p) => p.id === productId)
        if (!product) continue
        const existingIndex = next.findIndex((line) => line.productId === productId && productId > 0)
        if (existingIndex >= 0) {
          next[existingIndex] = { ...next[existingIndex], quantity: next[existingIndex].quantity + qty }
        } else {
          next.push({ ...buildLine(product, getNextLineKey()), quantity: qty })
        }
      }
      return next
    })
    setProductSearchOpen(false)
  }

  function applyProductToLine(lineKey: string, product: OrderProductOption) {
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

  function resolveLineByCode(lineKey: string, rawCode: string) {
    const code = rawCode.trim().toLowerCase()
    if (!code) return false
    const match = products.find((product) => {
      const productCode = (product.code || "").trim().toLowerCase()
      const productName = product.name.trim().toLowerCase()
      return productCode === code || productName === code || productCode.startsWith(code)
    })
    if (match) {
      applyProductToLine(lineKey, match)
      return true
    }

    setLines((current) => current.map((line) => {
      if (line.key !== lineKey) return line
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
    }))
    setActiveLineKey(lineKey)
    toast.warning(`No existe un producto con el codigo "${rawCode.trim()}".`)
    return false
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
              <div className="billing-pos__info-cell billing-pos__info-cell--time">
                <span className="billing-pos__info-label">Fecha / Hora</span>
                <strong className="billing-pos__info-value billing-pos__info-value--mono">{liveTime}</strong>
              </div>
              <div className="billing-pos__info-cell billing-pos__info-cell--caja">
                <span className="billing-pos__info-label">Caja POS</span>
                <strong className="billing-pos__info-value">{cajaPosName}</strong>
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
                          onBlur={() => resolveLineByCode(line.key, line.code)}
                          onKeyDown={(event) => handleCodeKeyDown(event, line)}
                        />
                        <button
                          type="button"
                          className="billing-pos__search-btn"
                          title="Buscar producto"
                          onClick={() => {
                            setPickerTargetLineKey(line.key)
                            setQuickPanelOpen(true)
                          }}
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
                      <button
                        type="button"
                        className="ghost-icon-button billing-pos__line-remove"
                        onClick={() => requestRemoveLine(line)}
                        aria-label={`Quitar ${line.description || line.code || "linea"}`}
                      >
                        <Trash2 size={15} />
                      </button>
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

          <div className="billing-pos__brand-panel">
            <div className="billing-pos__brand-card">
              {company.logoUrl || company.hasLogoBinary ? (
                <img
                  src={company.logoUrl || apiUrl("/api/company/logo/public")}
                  alt={company.tradeName || company.businessName || "Logo empresa"}
                  className="billing-pos__brand-logo"
                />
              ) : (
                <>
                  <strong>{company.tradeName || company.businessName || "Masu POS"}</strong>
                  <span>Logo empresa</span>
                </>
              )}
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
          <button type="button" className="secondary-button" onClick={openProductSearch}><PackageSearch size={16} /> Productos</button>
          <button type="button" className="secondary-button" onClick={() => {
            const line = lines.find((l) => l.key === activeLineKey && l.productId > 0) ?? null
            if (!line) { toast.warning("Selecciona una línea con producto para cambiar el precio."); return }
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
          <button type="button" className="secondary-button"><FileClock size={16} /> Fac. pendiente</button>
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
          <button type="button" className="primary-button billing-pos__pay-button"><CreditCard size={16} /> Cobrar</button>
        </div>
      </section>

      {quickPanelOpen ? (
        <section className="order-modal-backdrop" onClick={() => { setQuickPanelOpen(false); setPickerTargetLineKey(null) }}>
          <article className="data-panel order-modal order-modal--pos billing-pos__product-modal" onClick={(event) => event.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
              <div className="order-modal__titleline">
                <h2>{pickerTargetLineKey ? "Buscar producto" : "Venta rapida"}</h2>
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
        <div className="modal-backdrop" onClick={() => setEditPriceLine(null)}>
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
        <div className="modal-backdrop" onClick={closeDiscountModal}>
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
          <section className="order-modal-backdrop" onClick={() => { setCustomerModalOpen(false); setCustomerSearch("") }}>
            <article className="data-panel order-modal order-modal--product-search" onClick={(e) => e.stopPropagation()}>

              <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
                <div className="order-modal__titleline">
                  <h2>Seleccionar cliente</h2>
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
              <button type="button" className="danger-button" onClick={() => { resetPos(); setConfirmReset(false) }}>
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

      {productSearchOpen ? (
        <section className="order-modal-backdrop" onClick={() => setProductSearchOpen(false)}>
          <article className="data-panel order-modal order-modal--product-search" onClick={(event) => event.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
              <div className="order-modal__titleline">
                <h2>Buscar productos</h2>
                <p>{productSearchSelected.size > 0 ? `${productSearchSelected.size} producto(s) seleccionado(s)` : "Selecciona uno o más productos para agregar al documento."}</p>
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
                <button className="secondary-button secondary-button--sm" type="button" onClick={() => setProductSearchOpen(false)}>
                  Cerrar
                </button>
                <button
                  className="primary-button primary-button--sm"
                  type="button"
                  onClick={confirmProductSearch}
                  disabled={productSearchSelected.size === 0}
                >
                  Agregar {productSearchSelected.size > 0 ? `(${productSearchSelected.size})` : ""}
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
                        <th className="billing-pos__search-col--qty">Cantidad</th>
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
