"use client"

import { type FormEvent, useEffect, useMemo, useRef, useState, useTransition } from "react"
import {
  BarChart3, Database, DollarSign, Loader2, MoreHorizontal, Package,
  Pencil, Percent, Plus, RefreshCw, Save, Search, Settings, Tag, Trash2, Copy,
  Warehouse, X, ChevronRight, ChevronLeft, ImageIcon,
} from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import type { CatalogManagerData, InvMovimientoRecord, ProductRecord, ProductStockRow, ProductWarehouseRecord, WarehouseOption } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import { useFormat } from "@/lib/format-context"
import { useUnsavedGuard } from "@/lib/unsaved-guard"
import { DeleteConfirmModal } from "@/components/pos/delete-confirm-modal"

// ---------- types ----------
type ProductForm = {
  id?: number
  code: string
  name: string
  description: string
  comment: string
  imagen: string
  categoryId: string
  typeId: string
  unitBaseId: string
  unitSaleId: string
  unitPurchaseId: string
  unitAlt1Id: string
  unitAlt2Id: string
  unitAlt3Id: string
  price: string
  active: boolean
}

type PriceRow = {
  priceListId: number
  price: number; profitPercent: number; tax: number; priceWithTax: number
  // Raw strings the user is typing â€” used as input value to avoid cursor-jumping
  priceStr: string; priceWithTaxStr: string; profitPercentStr: string
}

type Costs = {
  currencyId: string
  providerDiscount: number
  providerCost: number
  providerCostWithTax: number
  averageCost: number
  allowManualAverageCost: boolean
}

type Offer = { active: boolean; price: number; startDate: string; endDate: string }

type Options = {
  canSellInBilling: boolean
  allowDiscount: boolean
  allowPriceChange: boolean
  allowManualPrice: boolean
  requestUnit: boolean
  requestUnitInventory: boolean
  allowDecimals: boolean
  sellWithoutStock: boolean
  applyTip: boolean
  managesStock: boolean
}

// ---------- defaults ----------
const emptyForm: ProductForm = {
  code: "", name: "", description: "", comment: "", imagen: "", categoryId: "", typeId: "",
  unitBaseId: "", unitSaleId: "", unitPurchaseId: "",
  unitAlt1Id: "", unitAlt2Id: "", unitAlt3Id: "",
  price: "0", active: true,
}

const defaultCosts: Costs = {
  currencyId: "", providerDiscount: 0, providerCost: 0,
  providerCostWithTax: 0, averageCost: 0, allowManualAverageCost: false,
}

const defaultOffer: Offer = { active: false, price: 0, startDate: "", endDate: "" }

function withImageVersion(src: string | null | undefined) {
  if (!src) return ""
  const version = `${src.length}-${src.slice(0, 12).length}-${src.slice(-12).length}`
  if (src.startsWith("data:")) return `${src}#v=${version}`
  return src.includes("?") ? `${src}&v=${version}` : `${src}?v=${version}`
}

const defaultOptions: Options = {
  canSellInBilling: true, allowDiscount: true, allowPriceChange: true,
  allowManualPrice: true, requestUnit: false, requestUnitInventory: false, allowDecimals: false,
  sellWithoutStock: true, applyTip: false, managesStock: true,
}

function recordToForm(p: ProductRecord): ProductForm {
  return {
    id: p.id, code: p.code, name: p.name, description: p.description, comment: p.comment, imagen: p.imagen || "",
    categoryId: String(p.categoryId), typeId: String(p.typeId),
    unitBaseId: String(p.unitBaseId), unitSaleId: String(p.unitSaleId),
    unitPurchaseId: String(p.unitPurchaseId),
    unitAlt1Id: p.unitAlt1Id ? String(p.unitAlt1Id) : "",
    unitAlt2Id: p.unitAlt2Id ? String(p.unitAlt2Id) : "",
    unitAlt3Id: p.unitAlt3Id ? String(p.unitAlt3Id) : "",
    price: p.price.toFixed(2), active: p.active,
  }
}

type Tab = "precios" | "general" | "almacenes" | "existencia" | "movimientos"

// ---------- component ----------
export function CatalogProductsScreen({ data }: { data: CatalogManagerData }) {
  const router = useRouter()
  const { t } = useI18n()
  const { formatNumber, parseNumber } = useFormat()
  const { setDirty, confirmAction } = useUnsavedGuard()
  // parseNumber is used inside updateNetPrice/updateGrossPrice/updateProfitPercent
  const menuRef = useRef<HTMLUListElement | null>(null)
  const justSaved = useRef(false) // skip price reset when selected updates after a save

  // sidebar state
  const [items, setItems] = useState<ProductRecord[]>([])
  const [loadingItems, setLoadingItems] = useState(false)
  const [hasSearched, setHasSearched] = useState(false)
  const [searchError, setSearchError] = useState<string | null>(null)
  const [query, setQuery] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [menuId, setMenuId] = useState<number | null>(null)
  const [selectedDetail, setSelectedDetail] = useState<ProductRecord | null>(null)
  const [loadingDetail, setLoadingDetail] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<ProductRecord | null>(null)

  // detail state
  const [form, setForm] = useState<ProductForm>(emptyForm)
  const [isEditing, setIsEditing] = useState(false)
  const [activeTab, setActiveTab] = useState<Tab>("precios")
  const [message, setMessage] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  // extended local state
  const [prices, setPrices] = useState<PriceRow[]>([])
  const [applyTax, setApplyTax] = useState(false)
  const [taxRateId, setTaxRateId] = useState("")
  const [costs, setCosts] = useState<Costs>(defaultCosts)
  const [offer, setOffer] = useState<Offer>(defaultOffer)
  const [options, setOptions] = useState<Options>(defaultOptions)
  const [assignedWarehouses, setAssignedWarehouses] = useState<ProductWarehouseRecord[]>([])
  const [availableWarehouses, setAvailableWarehouses] = useState<WarehouseOption[]>([])
  const [loadingWarehouses, setLoadingWarehouses] = useState(false)
  const [productStock, setProductStock] = useState<ProductStockRow[]>([])
  const [loadingStock, setLoadingStock] = useState(false)
  const [movementRows, setMovementRows] = useState<InvMovimientoRecord[]>([])
  const [loadingMovements, setLoadingMovements] = useState(false)
  const [kardexAlmacenId, setKardexAlmacenId] = useState("")
  const [kardexDesde, setKardexDesde] = useState("")
  const [kardexHasta, setKardexHasta] = useState("")
  const [selAvailable, setSelAvailable] = useState<number[]>([])
  const [selAssigned, setSelAssigned] = useState<number[]>([])

  const defaultTaxRateId = useMemo(() => {
    return data.lookups.taxRates[0] ? String(data.lookups.taxRates[0].id) : ""
  }, [data.lookups.taxRates])

  useEffect(() => {
    if (!taxRateId) setTaxRateId(defaultTaxRateId)
  }, [defaultTaxRateId, taxRateId])

  useEffect(() => {
    const today = new Date()
    const firstDay = new Date(today.getFullYear(), today.getMonth(), 1)
    const formatDateLocal = (date: Date) => {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, "0")
      const day = String(date.getDate()).padStart(2, "0")
      return `${year}-${month}-${day}`
    }
    setKardexDesde(formatDateLocal(firstDay))
    setKardexHasta(formatDateLocal(today))
  }, [])

  async function loadItems(searchValue: string) {
    setLoadingItems(true)
    setSearchError(null)
    try {
      const res = await fetch(apiUrl("/api/catalog/products/search"), {
        method: "POST",
        credentials: "include",
        cache: "no-store",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ q: searchValue.trim(), limit: 80 }),
      })
      const result = (await res.json()) as { ok: boolean; message?: string; items?: Array<Pick<ProductRecord, "id" | "code" | "name" | "price" | "active" | "category" | "type" | "imagen">> }
      if (res.ok && result.ok && Array.isArray(result.items)) {
        setItems(result.items.map((item) => ({
          id: item.id,
          code: item.code,
          name: item.name,
          imagen: item.imagen ?? null,
          description: "",
          comment: "",
          categoryId: 0,
          typeId: 0,
          unitBaseId: 0,
          unitSaleId: 0,
          unitPurchaseId: 0,
          price: item.price,
          applyTax: false,
          taxRateId: null,
          taxRate: 0,
          stockUnitBase: "measure",
          canSellInBilling: true,
          allowDiscount: true,
          allowPriceChange: true,
          allowManualPrice: true,
          requestUnit: false,
          requestUnitInventory: false,
          allowDecimals: false,
          sellWithoutStock: true,
          applyTip: false,
          managesStock: true,
          prices: [],
          costs: {
            currencyId: null,
            providerDiscount: 0,
            providerCost: 0,
            providerCostWithTax: 0,
            averageCost: 0,
            allowManualAvgCost: false,
          },
          offer: {
            active: false,
            price: 0,
            startDate: "",
            endDate: "",
          },
          active: item.active,
          category: item.category,
          type: item.type,
          unitBase: "",
          unitSale: "",
          unitPurchase: "",
        })))
      }
      else {
        setItems([])
        setSearchError(result.message || "No se pudo ejecutar la busqueda.")
      }
    } catch {
      setItems([])
      setSearchError("No se pudo ejecutar la busqueda.")
    } finally {
      setLoadingItems(false)
    }
  }

  function handleSearchSubmit() {
    setHasSearched(true)
    void loadItems(query)
  }

  const selectedSummary = useMemo(() => items.find((i) => i.id === selectedId) || null, [items, selectedId])
  const selected = selectedDetail ?? selectedSummary

  async function fetchProductDetail(productId: number) {
    const res = await fetch(apiUrl(`/api/catalog/products/${productId}`), { credentials: "include", cache: "no-store" })
    const dataResult = (await res.json()) as { ok: boolean; message?: string; product?: ProductRecord }
    if (!res.ok || !dataResult.ok || !dataResult.product) throw new Error(dataResult.message ?? "No se pudo cargar el producto.")
    return dataResult.product
  }

  useEffect(() => {
    if (!selectedId) {
      setSelectedDetail(null)
      return
    }

    let cancelled = false
    setLoadingDetail(true)
    void fetchProductDetail(selectedId)
      .then((product) => {
        if (!cancelled) setSelectedDetail(product)
      })
      .catch(() => {
        if (!cancelled) setSelectedDetail(null)
      })
      .finally(() => {
        if (!cancelled) setLoadingDetail(false)
      })

    return () => {
      cancelled = true
    }
  }, [selectedId])

  useEffect(() => {
    function onPointerDown(e: MouseEvent) {
      if (!menuRef.current?.contains(e.target as Node)) setMenuId(null)
    }
    window.addEventListener("mousedown", onPointerDown)
    return () => window.removeEventListener("mousedown", onPointerDown)
  }, [])

  useEffect(() => {
    setDirty(isEditing)
    return () => setDirty(false)
  }, [isEditing, setDirty])

  useEffect(() => {
    // After a save, skip the reset â€” prices/tax already reflect the saved state
    if (justSaved.current) {
      justSaved.current = false
      setIsEditing(false)
      setMessage(null)
      return
    }
    if (selected) {
      setForm(recordToForm(selected))
      // init price rows from price lists
      const pricesByList = new Map(selected.prices.map((row) => [row.priceListId, row]))
      setPrices(data.lookups.priceLists.map((pl) => {
        const existing = pricesByList.get(pl.id)
        const p = existing?.price ?? (pl.id === data.lookups.priceLists[0]?.id ? selected.price : 0)
        const profitPercent = existing?.profitPercent ?? 0
        const tax = existing?.tax ?? 0
        const priceWithTax = existing?.priceWithTax ?? (p + tax)
        return {
          priceListId: pl.id,
          price: p,
          profitPercent,
          tax,
          priceWithTax,
          priceStr: p.toFixed(4),
          priceWithTaxStr: priceWithTax.toFixed(4),
          profitPercentStr: profitPercent.toFixed(2),
        }
      }))
      setApplyTax(selected.applyTax)
      setTaxRateId(String(selected.taxRateId ?? defaultTaxRateId))
      setCosts({
        currencyId: selected.costs.currencyId != null ? String(selected.costs.currencyId) : String(data.lookups.currencies[0]?.id ?? ""),
        providerDiscount: selected.costs.providerDiscount,
        providerCost: selected.costs.providerCost,
        providerCostWithTax: selected.costs.providerCostWithTax,
        averageCost: selected.costs.averageCost,
        allowManualAverageCost: selected.costs.allowManualAvgCost,
      })
      setOffer(selected.offer)
      setOptions({
        canSellInBilling: selected.canSellInBilling,
        allowDiscount: selected.allowDiscount,
        allowPriceChange: selected.allowPriceChange,
        allowManualPrice: selected.allowManualPrice,
        requestUnit: selected.requestUnit,
        requestUnitInventory: selected.requestUnitInventory,
        allowDecimals: selected.allowDecimals,
        sellWithoutStock: selected.sellWithoutStock,
        applyTip: selected.applyTip,
        managesStock: selected.managesStock,
      })
      setAssignedWarehouses([])
      setAvailableWarehouses([])
      setMovementRows([])
    } else {
      if (!isEditing) {
        setForm(emptyForm)
        setPrices([])
        setSelectedDetail(null)
        setMovementRows([])
      }
    }
    if (!isEditing) {
      setMessage(null)
    }
  }, [isEditing, selected, data.lookups.priceLists, data.lookups.currencies])

  // price helpers â€” rate always computed from taxRateId for the price table display;
  // applyTax is a billing flag only (whether tax is charged at point of sale)
  function currentRate() {
    const selectedRate = data.lookups.taxRates.find((r) => r.id === Number(taxRateId))
    return applyTax ? (selectedRate?.rate ?? 0) : 0
  }

  function applyRateToRow(row: PriceRow, rate: number): PriceRow {
    const tax = row.price * (rate / 100)
    const priceWithTax = row.price + tax
    return { ...row, tax, priceWithTax, priceStr: row.price.toFixed(4), priceWithTaxStr: priceWithTax.toFixed(4) }
  }

  // Recalculate all rows when tax settings change
  useEffect(() => {
    const rate = currentRate()
    setPrices(prev => prev.map(row => applyRateToRow(row, rate)))
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [applyTax, taxRateId])

  // Update from net price string â†’ compute tax and gross; preserve priceStr as typed
  function updateNetPrice(plId: number, str: string) {
    const price = parseNumber(str)
    const rate = currentRate()
    const tax = price * (rate / 100)
    const priceWithTax = price + tax
    setPrices(prev => prev.map(row =>
      row.priceListId !== plId ? row : { ...row, price, tax, priceWithTax, priceStr: str, priceWithTaxStr: priceWithTax.toFixed(4) }
    ))
  }

  // Update from gross price string â†’ reverse-calculate; preserve priceWithTaxStr as typed
  function updateGrossPrice(plId: number, str: string) {
    const priceWithTax = parseNumber(str)
    const rate = currentRate()
    const price = rate > 0 ? priceWithTax / (1 + rate / 100) : priceWithTax
    const tax = priceWithTax - price
    setPrices(prev => prev.map(row =>
      row.priceListId !== plId ? row : { ...row, price, tax, priceWithTax, priceStr: price.toFixed(4), priceWithTaxStr: str }
    ))
  }

  function updateProfitPercent(plId: number, str: string) {
    const profitPercent = parseNumber(str)
    setPrices(prev => prev.map(row =>
      row.priceListId !== plId ? row : { ...row, profitPercent, profitPercentStr: str }
    ))
  }

  function openNew() {
    const run = () => {
      setSelectedId(null)
      setSelectedDetail(null)
      setForm(emptyForm)
      setPrices(data.lookups.priceLists.map((pl) => ({ priceListId: pl.id, price: 0, profitPercent: 0, tax: 0, priceWithTax: 0, priceStr: "0.0000", priceWithTaxStr: "0.0000", profitPercentStr: "0.00" })))
      setApplyTax(false)
      setTaxRateId(defaultTaxRateId)
      setCosts({ ...defaultCosts, currencyId: String(data.lookups.currencies[0]?.id ?? "") })
      setOffer(defaultOffer)
      setOptions(defaultOptions)
      setIsEditing(true)
      setMessage(null)
      setActiveTab("precios")
      setAssignedWarehouses([])
      setAvailableWarehouses([])
      setProductStock([])
      setMovementRows([])
      setMenuId(null)
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function openEdit(product: ProductRecord) {
    const run = () => {
      setSelectedId(product.id)
      setMenuId(null)
      setMessage(null)
      setLoadingDetail(true)
      void fetchProductDetail(product.id)
        .then((full) => {
          setSelectedDetail(full)
          setForm(recordToForm(full))
          setIsEditing(true)
        })
        .catch(() => {
          setForm(recordToForm(product))
          setIsEditing(true)
        })
        .finally(() => setLoadingDetail(false))
    }
    if (isEditing && selectedId !== product.id) {
      confirmAction(run)
      return
    }
    run()
  }

  function applyDuplicateFromProduct(product: ProductRecord) {
    const pricesByList = new Map(product.prices.map((row) => [row.priceListId, row]))
    const duplicatedPrices = data.lookups.priceLists.map((pl) => {
      const existing = pricesByList.get(pl.id)
      const p = existing?.price ?? (pl.id === data.lookups.priceLists[0]?.id ? product.price : 0)
      const profitPercent = existing?.profitPercent ?? 0
      const tax = existing?.tax ?? 0
      const priceWithTax = existing?.priceWithTax ?? (p + tax)
      return {
        priceListId: pl.id,
        price: p,
        profitPercent,
        tax,
        priceWithTax,
        priceStr: p.toFixed(4),
        priceWithTaxStr: priceWithTax.toFixed(4),
        profitPercentStr: profitPercent.toFixed(2),
      }
    })

    setSelectedId(null)
    setSelectedDetail(null)
    setForm({
      ...recordToForm(product),
      id: undefined,
      name: `Copia de ${product.name}`,
      code: "",
    })
    setPrices(duplicatedPrices)
    setApplyTax(product.applyTax)
    setTaxRateId(String(product.taxRateId ?? defaultTaxRateId))
    setCosts({
      currencyId: product.costs.currencyId != null ? String(product.costs.currencyId) : String(data.lookups.currencies[0]?.id ?? ""),
      providerDiscount: product.costs.providerDiscount,
      providerCost: product.costs.providerCost,
      providerCostWithTax: product.costs.providerCostWithTax,
      averageCost: product.costs.averageCost,
      allowManualAverageCost: product.costs.allowManualAvgCost,
    })
    setOffer(product.offer)
    setOptions({
      canSellInBilling: product.canSellInBilling,
      allowDiscount: product.allowDiscount,
      allowPriceChange: product.allowPriceChange,
      allowManualPrice: product.allowManualPrice,
      requestUnit: product.requestUnit,
      requestUnitInventory: product.requestUnitInventory,
      allowDecimals: product.allowDecimals,
      sellWithoutStock: product.sellWithoutStock,
      applyTip: product.applyTip,
      managesStock: product.managesStock,
    })
    setAssignedWarehouses([])
    setAvailableWarehouses([])
    setProductStock([])
    setMenuId(null)
    setMessage(null)
    setIsEditing(true)
    setActiveTab("precios")
  }

  function duplicateItem(product: ProductRecord) {
    const run = () => {
      setMenuId(null)
      setLoadingDetail(true)
      void fetchProductDetail(product.id)
        .then((full) => applyDuplicateFromProduct(full))
        .catch(() => applyDuplicateFromProduct(product))
        .finally(() => setLoadingDetail(false))
    }
    if (isEditing) {
      confirmAction(run)
      return
    }
    run()
  }

  function closeEditor() {
    confirmAction(() => {
      setIsEditing(false)
      if (selected) setForm(recordToForm(selected))
      else { setSelectedId(null); setForm(emptyForm) }
      setMessage(null)
      setDirty(false)
    })
  }

  function selectItem(id: number) {
    const run = () => setSelectedId(id)
    if (isEditing && selectedId !== id) {
      confirmAction(run)
      return
    }
    run()
  }

  async function loadWarehouses(productId: number) {
    setLoadingWarehouses(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/products/${productId}/warehouses`), { credentials: "include" })
      const result = (await res.json()) as { ok: boolean; assigned?: ProductWarehouseRecord[]; available?: WarehouseOption[] }
      if (result.ok) {
        setAssignedWarehouses(result.assigned ?? [])
        setAvailableWarehouses(result.available ?? [])
      }
    } catch { /* silent */ }
    finally { setLoadingWarehouses(false) }
  }

  async function loadProductStock(productId: number) {
    setLoadingStock(true)
    try {
      const res = await fetch(apiUrl(`/api/catalog/products/${productId}/stock`), { credentials: "include", cache: "no-store" })
      const result = (await res.json()) as { ok: boolean; stock?: ProductStockRow[] }
      if (result.ok) setProductStock(result.stock ?? [])
      else setProductStock([])
    } catch {
      setProductStock([])
    } finally {
      setLoadingStock(false)
    }
  }

  async function loadMovements(productId: number) {
    setLoadingMovements(true)
    try {
      const params = new URLSearchParams()
      params.set("producto", String(productId))
      if (kardexAlmacenId) params.set("almacen", kardexAlmacenId)
      if (kardexDesde) params.set("desde", kardexDesde)
      if (kardexHasta) params.set("hasta", kardexHasta)
      const res = await fetch(apiUrl(`/api/inventory/movements?${params.toString()}`), { credentials: "include", cache: "no-store" })
      const result = (await res.json()) as { ok: boolean; data?: InvMovimientoRecord[]; message?: string }
      if (result.ok) setMovementRows(result.data ?? [])
      else {
        setMovementRows([])
        toast.error(result.message ?? "No se pudo cargar movimientos.")
      }
    } catch {
      setMovementRows([])
      toast.error("No se pudo cargar movimientos.")
    } finally {
      setLoadingMovements(false)
    }
  }

  function handleTabChange(tab: Tab) {
    setActiveTab(tab)
    if (tab === "almacenes" && selectedId) {
      void loadWarehouses(selectedId)
    }
    if (tab === "existencia" && selectedId) void loadProductStock(selectedId)
    if (tab === "movimientos" && selectedId) void loadMovements(selectedId)
  }

  async function handleWarehouseAssign() {
    if (!selectedId || selAvailable.length === 0) return
    for (const wId of selAvailable) {
      const res = await fetch(apiUrl(`/api/catalog/products/${selectedId}/warehouses`), {
        method: "PUT", credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "assign", warehouseId: wId }),
      })
      const result = (await res.json()) as { ok: boolean; assigned?: ProductWarehouseRecord[]; available?: WarehouseOption[] }
      if (result.ok) {
        setAssignedWarehouses(result.assigned ?? [])
        setAvailableWarehouses(result.available ?? [])
      }
    }
    setSelAvailable([])
  }

  async function handleWarehouseRemove() {
    if (!selectedId || selAssigned.length === 0) return
    for (const wId of selAssigned) {
      const res = await fetch(apiUrl(`/api/catalog/products/${selectedId}/warehouses`), {
        method: "PUT", credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "remove", warehouseId: wId }),
      })
      const result = (await res.json()) as { ok: boolean; assigned?: ProductWarehouseRecord[]; available?: WarehouseOption[] }
      if (result.ok) {
        setAssignedWarehouses(result.assigned ?? [])
        setAvailableWarehouses(result.available ?? [])
      }
    }
    setSelAssigned([])
  }

  async function onSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setMessage(null)
    const effectiveUnitBaseId = Number(form.unitBaseId || form.unitSaleId || form.unitPurchaseId || 0)
    if (!form.name.trim() || !form.categoryId || !form.typeId || !effectiveUnitBaseId) {
      setMessage("Completa descripcion, categoria, tipo y unidades.")
      return
    }
    const payload = {
      id: form.id,
      code: form.code,
      name: form.name,
      description: form.name,
      reference: form.description,
      comment: form.comment,
      imagen: form.imagen || null,
      categoryId: Number(form.categoryId), typeId: Number(form.typeId),
      unitBaseId: effectiveUnitBaseId,
      unitSaleId: Number(form.unitSaleId || effectiveUnitBaseId),
      unitPurchaseId: Number(form.unitPurchaseId || effectiveUnitBaseId),
      unitAlt1Id: form.unitAlt1Id ? Number(form.unitAlt1Id) : undefined,
      unitAlt2Id: form.unitAlt2Id ? Number(form.unitAlt2Id) : undefined,
      unitAlt3Id: form.unitAlt3Id ? Number(form.unitAlt3Id) : undefined,
      price: Number(prices[0]?.price ?? form.price),
      applyTax,
      taxRateId: Number(taxRateId || 0) || null,
      stockUnitBase: "measure",
      canSellInBilling: options.canSellInBilling,
      allowDiscount: options.allowDiscount,
      allowPriceChange: options.allowPriceChange,
      allowManualPrice: options.allowManualPrice,
      requestUnit: options.requestUnit,
      requestUnitInventory: options.requestUnitInventory,
      allowDecimals: options.allowDecimals,
      sellWithoutStock: options.sellWithoutStock,
      applyTip: options.applyTip,
      managesStock: options.managesStock,
      prices: prices.map((row) => ({
        priceListId: row.priceListId,
        profitPercent: row.profitPercent,
        price: row.price,
        tax: row.tax,
        priceWithTax: row.priceWithTax,
      })),
      costs: {
        currencyId: costs.currencyId ? Number(costs.currencyId) : null,
        providerDiscount: costs.providerDiscount,
        providerCost: costs.providerCost,
        providerCostWithTax: costs.providerCostWithTax,
        averageCost: costs.averageCost,
        allowManualAvgCost: costs.allowManualAverageCost,
      },
      offer: {
        active: offer.active,
        price: offer.price,
        startDate: offer.startDate,
        endDate: offer.endDate,
      },
      active: form.active,
    }
    startTransition(async () => {
      try {
        const res = await fetch(apiUrl("/api/catalog/products"), {
          method: form.id ? "PUT" : "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(payload),
        })
        const result = (await res.json()) as { ok: boolean; message?: string; product?: ProductRecord }
        if (!res.ok || !result.ok) { setMessage(result.message ?? "No se pudo guardar."); return }
        toast.success(form.id ? "Producto actualizado" : "Producto creado")
        if (result.product) {
          const savedProduct = result.product
          setSelectedId(savedProduct.id)
          setSelectedDetail(savedProduct)
          setForm(recordToForm(savedProduct))
          if (form.id) {
            const savedPrice = prices[0]?.price ?? Number(form.price)
            setItems(prev => prev.map(i => i.id === form.id ? { ...i, price: savedPrice, code: savedProduct.code, name: savedProduct.name } : i))
            justSaved.current = true
          }
        }
        setIsEditing(false)
        setDirty(false)
        void loadItems(query)
        router.refresh()
      } catch { setMessage("Error al guardar.") }
    })
  }

  function handleProductImageChange(file: File | null) {
    if (!file) return
    if (file.size > 2 * 1024 * 1024) {
      toast.error("La imagen debe ser menor a 2MB")
      return
    }
    const reader = new FileReader()
    reader.onload = (event) => {
      const result = typeof event.target?.result === "string" ? event.target.result : ""
      setForm((prev) => ({ ...prev, imagen: result }))
    }
    reader.readAsDataURL(file)
  }

  async function handleDelete(id: number) {
    startTransition(async () => {
      try {
        const res = await fetch(apiUrl("/api/catalog/products"), {
          method: "DELETE", credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id }),
        })
        const result = (await res.json()) as { ok: boolean; message?: string }
        if (!res.ok || !result.ok) { toast.error(result.message ?? "No se pudo eliminar."); return }
        toast.success("Producto eliminado")
        setItems((prev) => prev.filter((i) => i.id !== id))
        if (selectedId === id) { setSelectedId(null); setForm(emptyForm) }
        setMenuId(null)
        setDeleteTarget(null)
        void loadItems(query)
        router.refresh()
      } catch { toast.error("Error al eliminar.") }
    })
  }

  const getCurrencySymbol = (currencyId: number | null) => {
    if (!currencyId) return ""
    return data.lookups.currencies.find((c) => c.id === currencyId)?.symbol ?? ""
  }

  // ---------- render ----------
  return (
    <section className="data-panel">
      <div className="price-lists-layout">

        {/* Sidebar */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <Package size={17} />
              <h2>Productos</h2>
            </div>
            <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo producto">
              <Plus size={15} />
            </button>
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input type="text" placeholder="Buscar por descripcion, referencia o codigo..." value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") {
                  e.preventDefault()
                  handleSearchSubmit()
                }
              }} />
            <button type="button" className="price-lists-sidebar__search-btn" disabled={loadingItems} onClick={handleSearchSubmit}>
              {loadingItems ? "Buscando..." : "Buscar"}
            </button>
          </div>
          {searchError ? <p className="price-lists-sidebar__empty">{searchError}</p> : null}

          <div className="price-lists-sidebar__list">
            {items.map((product) => (
              <div key={product.id}
                className={`price-lists-sidebar__item${selectedId === product.id ? " is-selected" : ""}`}
                onClick={() => selectItem(product.id)}
              >
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${product.active ? " is-active" : " is-inactive"}`}>
                    {product.active ? t("common.active") : t("common.inactive")}
                  </span>
                  <div className="price-lists-sidebar__menu-wrap">
                    <button className="price-lists-sidebar__menu-btn" type="button"
                      onClick={(e) => { e.stopPropagation(); setMenuId(menuId === product.id ? null : product.id) }}>
                      <MoreHorizontal size={14} />
                    </button>
                    {menuId === product.id && (
                      <ul className="price-lists-dropdown" ref={menuRef} onClick={(e) => e.stopPropagation()}>
                        <li><button type="button" onClick={() => openEdit(product)}><Pencil size={13} /> {t("common.edit")}</button></li>
                        <li><button type="button" onClick={() => duplicateItem(product)}><Copy size={13} /> Duplicar</button></li>
                        <li className="is-danger"><button type="button" onClick={() => { setDeleteTarget(product); setMenuId(null) }}><Trash2 size={13} /> {t("common.delete")}</button></li>
                      </ul>
                    )}
                  </div>
                </div>
                <div className="products-sidebar__summary">
                  {product.imagen ? (
                    <span className="products-sidebar__thumb">
                      <img src={withImageVersion(product.imagen)} alt={product.name} />
                    </span>
                  ) : null}
                  <div className="products-sidebar__text">
                    <p className="price-lists-sidebar__desc">{product.name}</p>
                    <p className="price-lists-sidebar__meta">{product.code ? `${product.code} - ` : ""}{product.category} - {formatNumber(product.price, 2)}</p>
                  </div>
                </div>
              </div>
            ))}
            {!loadingItems && hasSearched && items.length === 0 ? <p className="price-lists-sidebar__empty">Sin resultados</p> : null}
          </div>
        </aside>

        {/* Detail panel */}
        <main className="price-lists-main">
          {selected || isEditing ? (
            <form className="products-detail" onSubmit={onSubmit}>

              {isEditing && (
                <div className="products-detail__action-bar">
                  <div className="products-detail__action-bar-btns">
                    <button type="button" className="secondary-button" onClick={closeEditor}>
                      <X size={15} /> {t("common.cancel")}
                    </button>
                    <button type="submit" className="primary-button" disabled={isPending}>
                      {isPending ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
                      {t("common.save")}
                    </button>
                  </div>
                </div>
              )}

              {message && <div className="form-message products-detail__message">{message}</div>}

              {/* Basic info bar */}
              <div className="products-info-bar">
                <label className="products-info-bar__field">
                  <span>Codigo / Barra</span>
                  <input maxLength={60} value={form.code} disabled={!isEditing}
                    onChange={(e) => setForm({ ...form, code: e.target.value })} />
                </label>
                <label className="products-info-bar__field products-info-bar__field--wide">
                  <span>Descripcion *</span>
                  <input maxLength={100} value={form.name} disabled={!isEditing} required
                    onChange={(e) => setForm({ ...form, name: e.target.value })} />
                </label>
                <label className="products-info-bar__field">
                  <span>Categoria *</span>
                  <select value={form.categoryId} disabled={!isEditing} required
                    onChange={(e) => setForm({ ...form, categoryId: e.target.value })}>
                    <option value="">Selecciona</option>
                    {data.lookups.categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                  </select>
                </label>
                <label className="products-info-bar__field">
                  <span>Tipo *</span>
                  <select value={form.typeId} disabled={!isEditing} required
                    onChange={(e) => setForm({ ...form, typeId: e.target.value })}>
                    <option value="">Selecciona</option>
                    {data.lookups.productTypes.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
                  </select>
                </label>
                <label className="products-info-bar__toggle">
                  <span>Activo</span>
                  <button type="button"
                    className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                    onClick={() => isEditing && setForm({ ...form, active: !form.active })}
                    disabled={!isEditing}>
                    <span />
                  </button>
                </label>
              </div>

              {/* Tabs */}
              <div className="products-tabs">
                {([
                  { id: "precios", label: "Precios y Costos", icon: <DollarSign size={14} /> },
                  { id: "general", label: "Parametros", icon: <Settings size={14} /> },
                  { id: "almacenes", label: "Almacenes", icon: <Warehouse size={14} /> },
                  { id: "existencia", label: "Existencia", icon: <Package size={14} /> },
                  { id: "movimientos", label: "Movimientos", icon: <BarChart3 size={14} /> },
                ] as { id: Tab; label: string; icon: React.ReactNode }[]).map((tab) => (
                  <button key={tab.id} type="button"
                    className={`products-tab${activeTab === tab.id ? " is-active" : ""}`}
                    onClick={() => handleTabChange(tab.id)}>
                    {tab.icon} {tab.label}
                  </button>
                ))}
              </div>

              {/* TAB: Precios y Costos */}
              {activeTab === "precios" && (
                <div className="products-tab-body">

                  {/* Precios de venta */}
                  <div className="products-section">
                    <h4 className="products-section__title">
                      <Tag size={14} /> Precios de Venta
                    </h4>
                    <div className="products-price-table-wrap">
                      <table className="products-price-table">
                        <thead>
                          <tr>
                            <th></th>
                            <th>Lista de Precios</th>
                            <th>Moneda</th>
                            <th className="text-center">% Ganancia</th>
                            <th className="text-right">Precio</th>
                            <th className="text-right">Impuesto</th>
                            <th className="text-right">Precio + Imp.</th>
                          </tr>
                        </thead>
                        <tbody>
                          {data.lookups.priceLists.length === 0 && (
                            <tr><td colSpan={7} className="products-price-table__empty">No hay listas de precios configuradas</td></tr>
                          )}
                          {data.lookups.priceLists.map((pl, idx) => {
                            const row = prices.find((p) => p.priceListId === pl.id) ?? { priceListId: pl.id, price: 0, profitPercent: 0, tax: 0, priceWithTax: 0, priceStr: "0.0000", priceWithTaxStr: "0.0000", profitPercentStr: "0.00" }
                            const sym = getCurrencySymbol(pl.currencyId)
                            return (
                              <tr key={pl.id} className={idx === 0 ? "is-default" : ""}>
                                <td>{idx === 0 && <span className="products-price-dot" />}</td>
                                <td>
                                  <span className="products-price-name">{pl.description || pl.code}</span>
                                  {idx === 0 && <span className="products-price-badge">Predeterminado</span>}
                                </td>
                                <td><span className="products-currency-badge">{sym || pl.code}</span></td>
                                <td>
                                  <input type="text" inputMode="decimal" className="products-price-input text-center"
                                    value={isEditing ? row.profitPercentStr : formatNumber(row.profitPercent, 2)}
                                    disabled={!isEditing}
                                    onChange={(e) => updateProfitPercent(pl.id, e.target.value)} />
                                </td>
                                <td>
                                  <input type="text" inputMode="decimal" className="products-price-input text-right"
                                    value={isEditing ? row.priceStr : formatNumber(row.price, 4)}
                                    disabled={!isEditing}
                                    onChange={(e) => updateNetPrice(pl.id, e.target.value)} />
                                </td>
                                <td className="text-right products-price-computed">
                                  {formatNumber(row.tax, 4)}
                                </td>
                                <td>
                                  <input type="text" inputMode="decimal" className="products-price-input text-right"
                                    value={isEditing ? row.priceWithTaxStr : formatNumber(row.priceWithTax, 4)}
                                    disabled={!isEditing}
                                    onChange={(e) => updateGrossPrice(pl.id, e.target.value)} />
                                </td>
                              </tr>
                            )
                          })}
                        </tbody>
                      </table>
                    </div>
                  </div>

                  {/* Tax config */}
                  <div className="products-tax-row">
                    <label className="products-tax-check">
                      <span>Aplicar Impuestos en Ventas</span>
                      <button type="button"
                        className={applyTax ? "toggle-switch is-on" : "toggle-switch"}
                        onClick={() => isEditing && setApplyTax(!applyTax)}
                        disabled={!isEditing}>
                        <span />
                      </button>
                    </label>
                    <label className="products-tax-select">
                      <span>Tasa de Impuesto</span>
                      <select value={taxRateId} disabled={!isEditing || !applyTax}
                        onChange={(e) => setTaxRateId(e.target.value)}>
                        {data.lookups.taxRates.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
                      </select>
                    </label>
                  </div>

                  {/* Costs + Offer */}
                  <div className="products-cards-row">
                    {/* Costos */}
                    <div className="products-card">
                      <h4 className="products-card__title"><Percent size={14} /> Costos Ultima Compra</h4>
                      <div className="products-card__rows">
                        <label><span>Moneda</span>
                          {isEditing ? (
                            <select value={costs.currencyId}
                              onChange={(e) => setCosts({ ...costs, currencyId: e.target.value })}>
                              <option value="">Sin moneda</option>
                              {data.lookups.currencies.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                            </select>
                          ) : (
                            <input value={costs.currencyId ? (data.lookups.currencies.find((c) => String(c.id) === costs.currencyId)?.name ?? "-") : "-"} disabled className="input-readonly" />
                          )}
                        </label>
                        <label><span>Desc. Proveedor %</span>
                          <input type="number" step="0.01" value={costs.providerDiscount} disabled={!isEditing}
                            className={isEditing ? "" : "input-readonly"}
                            onChange={(e) => setCosts({ ...costs, providerDiscount: Number(e.target.value) })} />
                        </label>
                        <label><span>Costo Proveedor</span>
                          <input type="number" step="0.01" value={costs.providerCost} disabled={!isEditing}
                            className={isEditing ? "" : "input-readonly"}
                            onChange={(e) => {
                              const providerCost = Number(e.target.value)
                              const rate = data.lookups.taxRates.find((r) => r.id === Number(taxRateId))?.rate ?? 0
                              const providerCostWithTax = providerCost * (1 + (applyTax ? rate : 0) / 100)
                              setCosts({ ...costs, providerCost, providerCostWithTax })
                            }} />
                        </label>
                        <label><span>Costo + Impuesto</span>
                          <input type="number" step="0.01" value={costs.providerCostWithTax} disabled={!isEditing}
                            className={isEditing ? "" : "input-readonly"}
                            onChange={(e) => setCosts({ ...costs, providerCostWithTax: Number(e.target.value) })} />
                        </label>
                        <label><span>Costo Promedio</span>
                          <input type="number" step="0.01" value={costs.averageCost} disabled={!isEditing || !costs.allowManualAverageCost}
                            className={isEditing && costs.allowManualAverageCost ? "" : "input-readonly"}
                            onChange={(e) => setCosts({ ...costs, averageCost: Number(e.target.value) })} />
                        </label>
                        <div className="products-option-row">
                          <span>Costo promedio manual</span>
                          <button type="button"
                            className={costs.allowManualAverageCost ? "toggle-switch is-on" : "toggle-switch"}
                            onClick={() => isEditing && setCosts({ ...costs, allowManualAverageCost: !costs.allowManualAverageCost })}
                            disabled={!isEditing}><span /></button>
                        </div>
                      </div>
                    </div>

                    {/* Oferta */}
                    <div className="products-card">
                      <h4 className="products-card__title"><Tag size={14} /> Configuracion de la Oferta</h4>
                      <div className="products-card__rows">
                        <div className="products-option-row">
                          <span>Oferta activa</span>
                          <button type="button"
                            className={offer.active ? "toggle-switch is-on" : "toggle-switch"}
                            onClick={() => isEditing && setOffer({ ...offer, active: !offer.active })}
                            disabled={!isEditing}><span /></button>
                        </div>
                        <label><span>Precio de oferta</span>
                          <input type="number" step="0.01" value={offer.price} disabled={!isEditing}
                            className={isEditing ? "" : "input-readonly"}
                            onChange={(e) => setOffer({ ...offer, price: Number(e.target.value) })} />
                        </label>
                        <label><span>Fecha de inicio</span>
                          <input type="date" value={offer.startDate} disabled={!isEditing}
                            className={isEditing ? "" : "input-readonly"}
                            onChange={(e) => setOffer({ ...offer, startDate: e.target.value })} />
                        </label>
                        <label><span>Fecha de fin</span>
                          <input type="date" value={offer.endDate} disabled={!isEditing}
                            className={isEditing ? "" : "input-readonly"}
                            onChange={(e) => setOffer({ ...offer, endDate: e.target.value })} />
                        </label>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* TAB: Parametros Generales */}
              {activeTab === "general" && (
                <div className="products-tab-body">
                  <div className="products-params-layout">

                    {/* Columna izquierda */}
                    <div className="products-params-main">

                  {/* Referencia + Comentario */}
                  <div className="products-section">
                    <h4 className="products-section__title">Detalle</h4>
                    <div className="form-grid">
                      <label className="form-grid__full">
                        <span>Referencia</span>
                        <input maxLength={100} value={form.description} disabled={!isEditing}
                          onChange={(e) => setForm({ ...form, description: e.target.value })} />
                      </label>
                      <label className="form-grid__full">
                        <span>Comentario</span>
                        <textarea rows={3} value={form.comment} disabled={!isEditing}
                          onChange={(e) => setForm({ ...form, comment: e.target.value })} />
                      </label>
                    </div>
                  </div>

                  {/* Unidades de Medida */}
                  <div className="products-section">
                    <h4 className="products-section__title">Unidades de Medida</h4>
                    <div className="products-params-grid">
                      <label className="products-param-row">
                        <span>Unidad venta</span>
                        <select
                          value={String(form.unitSaleId ?? "")}
                          disabled={!isEditing}
                          onChange={(e) => {
                            const val = e.target.value
                            setForm({
                              ...form,
                              unitSaleId: val,
                              unitBaseId: form.unitBaseId || val,
                            })
                          }}
                        >
                          <option value="">Ninguna</option>
                          {data.lookups.units.map((u) => (
                            <option key={u.id} value={u.id}>{u.name} ({u.abbreviation})</option>
                          ))}
                        </select>
                      </label>

                      <label className="products-param-row">
                        <span>Alterna 1</span>
                        <select
                          value={String(form.unitAlt1Id ?? "")}
                          disabled={!isEditing}
                          onChange={(e) => setForm({ ...form, unitAlt1Id: e.target.value })}
                        >
                          <option value="">Ninguna</option>
                          {data.lookups.units.map((u) => (
                            <option key={u.id} value={u.id}>{u.name} ({u.abbreviation})</option>
                          ))}
                        </select>
                      </label>

                      <label className="products-param-row">
                        <span>Unidad compra</span>
                        <select
                          value={String(form.unitPurchaseId ?? "")}
                          disabled={!isEditing}
                          onChange={(e) => {
                            const val = e.target.value
                            setForm({
                              ...form,
                              unitPurchaseId: val,
                              unitBaseId: form.unitBaseId || val,
                            })
                          }}
                        >
                          <option value="">Ninguna</option>
                          {data.lookups.units.map((u) => (
                            <option key={u.id} value={u.id}>{u.name} ({u.abbreviation})</option>
                          ))}
                        </select>
                      </label>

                      <label className="products-param-row">
                        <span>Alterna 2</span>
                        <select
                          value={String(form.unitAlt2Id ?? "")}
                          disabled={!isEditing}
                          onChange={(e) => setForm({ ...form, unitAlt2Id: e.target.value })}
                        >
                          <option value="">Ninguna</option>
                          {data.lookups.units.map((u) => (
                            <option key={u.id} value={u.id}>{u.name} ({u.abbreviation})</option>
                          ))}
                        </select>
                      </label>

                      <label className="products-param-row">
                        <span>Unidad base para reportes</span>
                        <select
                          value={String(form.unitBaseId || form.unitSaleId || form.unitPurchaseId || "")}
                          disabled={!isEditing}
                          onChange={(e) => setForm({ ...form, unitBaseId: e.target.value })}
                        >
                          <option value="">Ninguna</option>
                          {data.lookups.units.map((u) => (
                            <option key={u.id} value={u.id}>{u.name} ({u.abbreviation})</option>
                          ))}
                        </select>
                      </label>

                      <label className="products-param-row">
                        <span>Alterna 3</span>
                        <select
                          value={String(form.unitAlt3Id ?? "")}
                          disabled={!isEditing}
                          onChange={(e) => setForm({ ...form, unitAlt3Id: e.target.value })}
                        >
                          <option value="">Ninguna</option>
                          {data.lookups.units.map((u) => (
                            <option key={u.id} value={u.id}>{u.name} ({u.abbreviation})</option>
                          ))}
                        </select>
                      </label>
                    </div>
                  </div>

                  {/* Opciones */}
                  <div className="products-section">
                    <h4 className="products-section__title">Opciones de Articulo / Servicio</h4>
                    <div className="products-options-list">
                      {([
                        { key: "canSellInBilling", label: "Se puede vender en facturacion" },
                        { key: "allowDiscount", label: "Permitir descuento en facturacion" },
                        { key: "allowPriceChange", label: "Permitir cambio de precio en facturacion" },
                        { key: "allowManualPrice", label: "Permitir precio manual en facturacion" },
                        { key: "requestUnit", label: "Permite cambiar la unidad de medida en facturacion" },
                        { key: "requestUnitInventory", label: "Permite cambiar la unidad de medida en inventario" },
                        { key: "allowDecimals", label: "Permitir fracciones decimales" },
                        { key: "sellWithoutStock", label: "Vender con existencia menor de cero" },
                        { key: "applyTip", label: "Aplicar propina legal en facturacion" },
                        { key: "managesStock", label: "Articulo maneja existencia" },
                      ] as { key: keyof Options; label: string }[]).map(({ key, label }) => (
                        <div key={key} className="products-option-row">
                          <span>{label}</span>
                          <button type="button"
                            className={options[key] ? "toggle-switch is-on" : "toggle-switch"}
                            onClick={() => isEditing && setOptions({ ...options, [key]: !options[key] })}
                            disabled={!isEditing}>
                            <span />
                          </button>
                        </div>
                      ))}
                    </div>
                  </div>

                    </div>{/* /products-params-main */}

                    {/* Columna derecha: Imagen */}
                    <div className="products-params-aside">
                      <div className="products-section">
                        <h4 className="products-section__title">Imagen del Articulo</h4>
                        <div className="categories-image">
                          {form.imagen ? (
                            <div className="categories-image__preview">
                              <div className="products-image-card__preview">
                                <img src={withImageVersion(form.imagen)} alt={form.name || "Imagen del articulo"} />
                              </div>
                              <p className="products-image-card__hint">{form.name || "Articulo"}</p>
                              {isEditing ? (
                                <div className="products-image-card__actions">
                                  <label className="primary-button categories-image__upload-btn">
                                    <input type="file" accept="image/*" style={{ display: "none" }}
                                      onChange={(e) => handleProductImageChange(e.target.files?.[0] ?? null)} />
                                    <Plus size={14} /> Cambiar Imagen
                                  </label>
                                  <button type="button" className="ghost-button danger-button"
                                    onClick={() => setForm((prev) => ({ ...prev, imagen: "" }))}>
                                    <Trash2 size={14} /> Quitar
                                  </button>
                                </div>
                              ) : null}
                            </div>
                          ) : (
                            <div className="categories-image__drop">
                              <div className="products-image-card__placeholder">
                                <ImageIcon size={28} />
                              </div>
                              <p>Sin imagen cargada</p>
                              {isEditing ? (
                                <label className="primary-button categories-image__upload-btn">
                                  <input type="file" accept="image/*" style={{ display: "none" }}
                                    onChange={(e) => handleProductImageChange(e.target.files?.[0] ?? null)} />
                                  <Plus size={14} /> Subir imagen
                                </label>
                              ) : null}
                              <small>Sube una imagen del articulo. Maximo 2MB.</small>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>{/* /products-params-aside */}

                  </div>{/* /products-params-layout */}
                </div>
              )}

              {/* TAB: Almacenes */}
              {activeTab === "almacenes" && (
                <div className="products-tab-body">
                  {loadingWarehouses ? (
                    <div className="products-coming-soon"><Loader2 size={28} className="spin" /><p>Cargando almacenes...</p></div>
                  ) : !selectedId ? (
                    <div className="products-coming-soon"><Warehouse size={36} opacity={0.25} /><p>Guarda el producto antes de asignar almacenes</p></div>
                  ) : (
                    <div className="products-warehouse-transfer">
                      {/* No asignados */}
                      <div className="products-warehouse-panel">
                        <div className="products-warehouse-panel__header">Almacenes No Asignados</div>
                        <div className="products-warehouse-panel__list">
                          {availableWarehouses.length === 0
                            ? <p className="products-warehouse-empty">No hay almacenes disponibles</p>
                            : availableWarehouses.map((w) => (
                              <div key={w.id}
                                className={`products-warehouse-item${selAvailable.includes(w.id) ? " is-selected" : ""}`}
                                onClick={() => setSelAvailable((p) => p.includes(w.id) ? p.filter((x) => x !== w.id) : [...p, w.id])}>
                                <span className="products-warehouse-item__name">{w.name}</span>
                                <span className="products-warehouse-item__siglas">{w.initials}</span>
                              </div>
                            ))
                          }
                        </div>
                      </div>

                      {/* Botones */}
                      <div className="products-warehouse-btns">
                        <button type="button" className="secondary-button secondary-button--xs"
                          disabled={selAvailable.length === 0}
                          onClick={() => void handleWarehouseAssign()}>
                          <ChevronRight size={15} />
                        </button>
                        <button type="button" className="secondary-button secondary-button--xs"
                          disabled={selAssigned.length === 0}
                          onClick={() => void handleWarehouseRemove()}>
                          <ChevronLeft size={15} />
                        </button>
                      </div>

                      {/* Asignados */}
                      <div className="products-warehouse-panel">
                        <div className="products-warehouse-panel__header">Almacenes Asignados</div>
                        <div className="products-warehouse-panel__list">
                          {assignedWarehouses.length === 0
                            ? <p className="products-warehouse-empty">Sin almacenes asignados</p>
                            : assignedWarehouses.map((w) => (
                              <div key={w.warehouseId}
                                className={`products-warehouse-item${selAssigned.includes(w.warehouseId) ? " is-selected" : ""}`}
                                onClick={() => setSelAssigned((p) => p.includes(w.warehouseId) ? p.filter((x) => x !== w.warehouseId) : [...p, w.warehouseId])}>
                                <span className="products-warehouse-item__name">{w.warehouseName}</span>
                                <span className="products-warehouse-item__siglas">{w.initials}</span>
                              </div>
                            ))
                          }
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}

              {/* TAB: Existencia */}
              {activeTab === "existencia" && (
                <div className="products-tab-body">
                  <div className="products-section">
                    <div className="products-warehouse-panel__header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span>Existencias por Almacen</span>
                      <button
                        type="button"
                        className="secondary-button secondary-button--xs"
                        disabled={loadingStock || !selectedId}
                        onClick={() => selectedId && void loadProductStock(selectedId)}
                      >
                        {loadingStock ? <Loader2 size={14} className="spin" /> : <RefreshCw size={14} />} Actualizar
                      </button>
                    </div>

                    {loadingStock ? (
                      <div className="products-coming-soon"><Loader2 size={28} className="spin" /><p>Cargando existencia...</p></div>
                    ) : productStock.length === 0 ? (
                      <div className="detail-empty"><p>No hay almacenes asignados a este producto</p></div>
                    ) : (
                      <div className="products-stock-table-wrap">
                        <table className="data-table products-stock-table">
                          <thead>
                            <tr>
                              <th>Almacen</th>
                              <th className="text-right">Minimo</th>
                              <th className="text-right">Maximo</th>
                              <th className="text-right">Reorden</th>
                              <th className="text-right">Existencia</th>
                              <th className="text-right">Existencia Real</th>
                              <th className="text-right">Reservado</th>
                              <th className="text-right">Disponible ({productStock[0]?.unitAbbrev || "UND"})</th>
                              {productStock[0]?.unitCompraAbbrev ? <th className="text-right">Disponible {productStock[0].unitCompraAbbrev}</th> : null}
                              {productStock[0]?.alterna1 ? <th className="text-right">Disponible {productStock[0].alterna1.abbrev}</th> : null}
                              {productStock[0]?.alterna2 ? <th className="text-right">Disponible {productStock[0].alterna2.abbrev}</th> : null}
                              {productStock[0]?.alterna3 ? <th className="text-right">Disponible {productStock[0].alterna3.abbrev}</th> : null}
                            </tr>
                          </thead>
                          <tbody>
                            {productStock.map((row) => {
                              const lowStock = row.puntoReorden != null && row.puntoReorden > 0 && row.existencia < row.puntoReorden
                              return (
                                <tr key={row.warehouseId} className={lowStock ? "products-stock-badge--alert" : ""}>
                                  <td>{row.warehouseName}</td>
                                  <td className="text-right">{row.minimo == null ? "-" : formatNumber(row.minimo, 4)}</td>
                                  <td className="text-right">{row.maximo == null ? "-" : formatNumber(row.maximo, 4)}</td>
                                  <td className="text-right">{row.puntoReorden == null ? "-" : formatNumber(row.puntoReorden, 4)}</td>
                                  <td className="text-right">{formatNumber(row.existencia, 4)}</td>
                                  <td className="text-right">{formatNumber(row.existenciaReal, 4)}</td>
                                  <td className="text-right">{formatNumber(row.reservado, 4)}</td>
                                  <td className="text-right">{formatNumber(row.disponibleBase, 4)}</td>
                                  {productStock[0]?.unitCompraAbbrev ? <td className="text-right">{row.unitCompraDisponible != null ? formatNumber(row.unitCompraDisponible, 4) : "-"}</td> : null}
                                  {productStock[0]?.alterna1 ? <td className="text-right">{row.alterna1 ? formatNumber(row.alterna1.disponible, 4) : "-"}</td> : null}
                                  {productStock[0]?.alterna2 ? <td className="text-right">{row.alterna2 ? formatNumber(row.alterna2.disponible, 4) : "-"}</td> : null}
                                  {productStock[0]?.alterna3 ? <td className="text-right">{row.alterna3 ? formatNumber(row.alterna3.disponible, 4) : "-"}</td> : null}
                                </tr>
                              )
                            })}
                          </tbody>
                          <tfoot className="products-stock-footer">
                            <tr>
                              <td>Totales</td>
                              <td className="text-right">-</td>
                              <td className="text-right">-</td>
                              <td className="text-right">-</td>
                              <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + row.existencia, 0), 4)}</td>
                              <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + row.existenciaReal, 0), 4)}</td>
                              <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + row.reservado, 0), 4)}</td>
                              <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + row.disponibleBase, 0), 4)}</td>
                              {productStock[0]?.unitCompraAbbrev ? <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + (row.unitCompraDisponible ?? 0), 0), 4)}</td> : null}
                              {productStock[0]?.alterna1 ? <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + (row.alterna1?.disponible ?? 0), 0), 4)}</td> : null}
                              {productStock[0]?.alterna2 ? <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + (row.alterna2?.disponible ?? 0), 0), 4)}</td> : null}
                              {productStock[0]?.alterna3 ? <td className="text-right">{formatNumber(productStock.reduce((acc, row) => acc + (row.alterna3?.disponible ?? 0), 0), 4)}</td> : null}
                            </tr>
                          </tfoot>
                        </table>
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* TAB: Movimientos */}
              {activeTab === "movimientos" && (
                <div className="products-tab-body">
                  <div className="products-section">
                    <div className="products-warehouse-panel__header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span>Movimientos del producto</span>
                      <div style={{ display: "inline-flex", gap: "0.6rem", alignItems: "center", flexWrap: "wrap" }}>
                        <label style={{ display: "inline-flex", alignItems: "center", gap: "0.4rem", fontSize: "0.85rem" }}>
                          <span style={{ color: "var(--muted)" }}>Almacen</span>
                          <select
                            value={kardexAlmacenId}
                            onChange={(e) => setKardexAlmacenId(e.target.value)}
                            className="filter-input"
                            style={{ width: "140px" }}
                          >
                            <option value="">Todos</option>
                            {data.lookups.warehouses.map((w) => (
                              <option key={w.id} value={w.id}>{w.name}</option>
                            ))}
                          </select>
                        </label>
                        <label style={{ display: "inline-flex", alignItems: "center", gap: "0.4rem", fontSize: "0.85rem" }}>
                          <span style={{ color: "var(--muted)" }}>Desde</span>
                          <input
                            type="date"
                            value={kardexDesde}
                            onChange={(e) => setKardexDesde(e.target.value)}
                            className="filter-input"
                            style={{ width: "120px" }}
                          />
                        </label>
                        <label style={{ display: "inline-flex", alignItems: "center", gap: "0.4rem", fontSize: "0.85rem" }}>
                          <span style={{ color: "var(--muted)" }}>Hasta</span>
                          <input
                            type="date"
                            value={kardexHasta}
                            onChange={(e) => setKardexHasta(e.target.value)}
                            className="filter-input"
                            style={{ width: "120px" }}
                          />
                        </label>
                        <button
                          type="button"
                          className="secondary-button secondary-button--xs"
                          disabled={loadingMovements || !selectedId}
                          onClick={() => selectedId && void loadMovements(selectedId)}
                        >
                          {loadingMovements ? <Loader2 size={14} className="spin" /> : <RefreshCw size={14} />} Actualizar
                        </button>
                      </div>
                    </div>

                    {loadingMovements ? (
                      <div className="products-coming-soon"><Loader2 size={28} className="spin" /><p>Cargando movimientos...</p></div>
                    ) : movementRows.length === 0 ? (
                      <div className="detail-empty"><p>No hay movimientos para los filtros seleccionados</p></div>
                    ) : (
                      <div className="products-stock-table-wrap">
                        <table className="data-table products-stock-table">
                          <thead>
                            <tr>
                              <th>Fecha</th>
                              <th>Documento</th>
                              <th>Almacen</th>
                              <th className="text-right">Entrada</th>
                              <th className="text-right">Salida</th>
                              <th className="text-right">Balance</th>
                            </tr>
                          </thead>
                          <tbody>
                            {movementRows.map((row, idx) => {
                              const balance = movementRows
                                .slice(0, idx + 1)
                                .reduce((sum, r) => sum + r.entrada - r.salida, 0)
                              return (
                                <tr key={row.idMovimiento}>
                                  <td>{row.fecha}</td>
                                  <td>{row.numeroDocumento || "-"}</td>
                                  <td>{row.nombreAlmacen}</td>
                                  <td className="text-right">{formatNumber(row.entrada, 4)}</td>
                                  <td className="text-right">{formatNumber(row.salida, 4)}</td>
                                  <td className="text-right">{formatNumber(balance, 4)}</td>
                                </tr>
                              )
                            })}
                          </tbody>
                        </table>
                      </div>
                    )}
                  </div>
                </div>
              )}

            </form>
          ) : (
            <div className="price-lists-empty">
              <Database size={48} opacity={0.3} />
              <p>Selecciona un producto o crea uno nuevo</p>
            </div>
          )}
        </main>
      </div>
      <DeleteConfirmModal
        open={Boolean(deleteTarget)}
        entityLabel="Producto"
        itemName={deleteTarget?.name ?? ""}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => deleteTarget && void handleDelete(deleteTarget.id)}
      />
    </section>
  )
}

