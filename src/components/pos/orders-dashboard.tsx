"use client"

import { useEffect, useMemo, useState, useTransition } from "react"
import { usePathname, useRouter, useSearchParams } from "next/navigation"
import { toast } from "sonner"
import {
  ArrowRightLeft,
  Clock3,
  GitMerge,
  CreditCard,
  PackageOpen,
  Plus,
  Receipt,
  Search,
  ShieldAlert,
  ShieldCheck,
  Split,
  StickyNote,
  Trash2,
  UserRound,
  UtensilsCrossed,
  X,
  XCircle,
} from "lucide-react"
import type { OpenOrderTicket, OrdersTrayData, ResourceOrderTray } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useFormat } from "@/lib/format-context"
import { OrdersSplitPanel } from "@/components/pos/orders-split-panel"

type AddProductTrayItem = {
  key: number
  productId: number
  name: string
  category: string
  image: string | null
  quantity: number
  personNumber: number
  note: string
  price: number
  total: number
}

type SupervisorAction =
  | { type: "cancel-order"; ticket: OpenOrderTicket }
  | { type: "delete-line"; ticket: OpenOrderTicket; lineId: number; lineName: string }

type AuthViewer = {
  userId: number
  username: string
  role: string
  userType: "A" | "S" | "O"
}

type ApiResult = {
  ok: boolean
  message?: string
}

type ResourceVisualState = "free" | "single" | "multiple" | "in-progress"

function getOrderTotals(ticket: OpenOrderTicket) {
  const tax = ticket.items.reduce((sum, item) => sum + (item.taxAmount ?? 0), 0)
  const subtotal = ticket.items.reduce((sum, item) => sum + item.total, 0)
  return { subtotal, tax, discount: 0, total: ticket.total }
}

function parseApiResult(payload: unknown): ApiResult {
  if (!payload || typeof payload !== "object") {
    return { ok: false, message: "Respuesta invalida del servidor." }
  }

  const result = payload as Record<string, unknown>
  return {
    ok: Boolean(result.ok),
    message: typeof result.message === "string" ? result.message : undefined,
  }
}

function getSupervisorActionCopy(action: SupervisorAction) {
  if (action.type === "cancel-order") {
    return {
      title: "Cancelar orden",
      subtitle: `Vas a cancelar ${action.ticket.number}. Esta acción requiere confirmación.`,
      confirmLabel: "Sí, cancelar orden",
      successMessage: "Orden cancelada correctamente.",
    }
  }

  return {
    title: "Eliminar línea",
    subtitle: `Vas a eliminar la línea ${action.lineName}. Esta acción requiere confirmación.`,
    confirmLabel: "Sí, eliminar línea",
    successMessage: "Línea eliminada correctamente.",
  }
}

function isPrivilegedUserType(userType?: string) {
  return userType === "A" || userType === "S"
}

function getTicketTone(state: string) {
  const normalized = state.trim().toLowerCase()
  if (normalized.includes("cerr")) return "success"
  if (normalized.includes("anul")) return "rose"
  if (normalized.includes("proceso")) return "info"
  if (normalized.includes("reab")) return "violet"
  return "warning"
}

function getResourceVisualState(resource: ResourceOrderTray): ResourceVisualState {
  if (resource.openCount <= 0) return "free"
  if (resource.openOrders.some((ticket) => ticket.state.toLowerCase().includes("proceso"))) return "in-progress"
  if (resource.openCount > 1) return "multiple"
  return "single"
}

function getResourceVisualMeta(resource: ResourceOrderTray) {
  const state = getResourceVisualState(resource)
  switch (state) {
    case "free":
      return { tone: "success", label: "Libre" }
    case "in-progress":
      return { tone: "info", label: "En proceso" }
    case "multiple":
      return { tone: "warning", label: "Multiples ordenes" }
    default:
      return { tone: "violet", label: "Activa" }
  }
}

function getActionMessage(action: string) {
  return `${action} estara disponible en la siguiente fase del modulo de ordenes.`
}

function groupOrderItems(items: OpenOrderTicket["items"]) {
  const grouped = new Map<string, { key: string; name: string; quantity: number }>()

  for (const item of items) {
    const key = item.name.trim().toLowerCase()
    const current = grouped.get(key)
    if (current) {
      current.quantity += item.quantity
      continue
    }

    grouped.set(key, {
      key: `${key}-${item.id}`,
      name: item.name,
      quantity: item.quantity,
    })
  }

  return Array.from(grouped.values())
}

function formatOrderLineDateTime(value?: string) {
  if (!value) return "N/D"
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return value
  return parsed.toLocaleString("es-DO", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  })
}

function getOrderLinePricing(
  item: OpenOrderTicket["items"][number],
  products: OrdersTrayData["products"],
  companyApplyTip: boolean,
  companyTipPercent: number,
) {
  const base = item.price
  const withTax = item.taxPercent > 0 ? item.price * (1 + item.taxPercent / 100) : item.price
  const product = products.find((candidate) => candidate.name === item.name)
  const hasTip = Boolean(product?.applyTip && companyApplyTip)
  const withTip = hasTip ? withTax + item.price * (companyTipPercent / 100) : null

  return { base, withTax, withTip, hasTip }
}

function getResourceShortName(name: string) {
  const normalized = name.trim().toUpperCase()
  const match = normalized.match(/(\d+)/)
  if (match) {
    return `M${match[1].padStart(2, "0")}`
  }
  return normalized.replace(/\s+/g, "").slice(0, 3) || "M"
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
  return `#${[r, g, b].map((value) => Math.max(0, Math.min(255, Math.round(value))).toString(16).padStart(2, "0")).join("")}`
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

function withImageVersion(src: string | null | undefined) {
  if (!src) return ""
  const version = `${src.length}-${src.slice(0, 12).length}-${src.slice(-12).length}`
  if (src.startsWith("data:")) return `${src}#v=${version}`
  return src.includes("?") ? `${src}&v=${version}` : `${src}?v=${version}`
}

type OrdersDashboardProps = {
  data: OrdersTrayData
}

export function OrdersDashboard({ data }: OrdersDashboardProps) {
  const pathname = usePathname()
  const router = useRouter()
  const searchParams = useSearchParams()
  const { formatNumber, formatDateTime } = useFormat()
  const [liveData, setLiveData] = useState(data)
  const formatMoney = (value: number, decimals = 2) => `${liveData.currencySymbol} ${formatNumber(value, decimals)}`
  const renderMoneyAccent = (value: number, decimals = 2) => (
    <>
      <span className="orders-money-symbol">{liveData.currencySymbol}</span>
      <span>{formatNumber(value, decimals)}</span>
    </>
  )
  const allResources = useMemo(() => liveData.resources, [liveData.resources])
  const [search, setSearch] = useState("")
  const [areaFilter, setAreaFilter] = useState("all")
  const [stateFilter, setStateFilter] = useState("all")
  const [selectedId, setSelectedId] = useState<number | null>(allResources[0]?.id ?? null)
  const [selectedTicketId, setSelectedTicketId] = useState<number | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [isQuickCreateOpen, setIsQuickCreateOpen] = useState(false)
  const [confirmCloseQuickCreate, setConfirmCloseQuickCreate] = useState(false)
  const [quickResourceId, setQuickResourceId] = useState<string>(allResources[0] ? String(allResources[0].id) : "")
  const [quickReference, setQuickReference] = useState("")
  const [quickGuestCount, setQuickGuestCount] = useState("1")
  const [isAddProductOpen, setIsAddProductOpen] = useState(false)
  const [addProductSearch, setAddProductSearch] = useState("")
  const [selectedProductCategory, setSelectedProductCategory] = useState("all")
  const [addProductTray, setAddProductTray] = useState<AddProductTrayItem[]>([])
  const [confirmCloseAddProduct, setConfirmCloseAddProduct] = useState(false)
  const [moveTicket, setMoveTicket] = useState<OpenOrderTicket | null>(null)
  const [moveResourceId, setMoveResourceId] = useState("")
  const [splitTicket, setSplitTicket] = useState<OpenOrderTicket | null>(null)
  const [isMergeOpen, setIsMergeOpen] = useState(false)
  const [mergeTargetId, setMergeTargetId] = useState<number | null>(null)
  const [mergeSourceIds, setMergeSourceIds] = useState<number[]>([])
  const [currentViewer, setCurrentViewer] = useState<AuthViewer | null>(null)
  const [confirmProtectedAction, setConfirmProtectedAction] = useState<SupervisorAction | null>(null)
  const [supervisorAction, setSupervisorAction] = useState<SupervisorAction | null>(null)
  const [supervisorUsername, setSupervisorUsername] = useState("")
  const [supervisorPassword, setSupervisorPassword] = useState("")
  const [message, setMessage] = useState<string | null>(null)
  const [selectedPersonFilter, setSelectedPersonFilter] = useState<number | "all">("all")
  const [isPending, startTransition] = useTransition()

  useEffect(() => {
    setLiveData(data)
  }, [data])

  useEffect(() => {
    if (!message) return
    toast(message)
    setMessage(null)
  }, [message])

  const pauseAutoRefresh = isPending
    || isQuickCreateOpen
    || confirmCloseQuickCreate
    || isAddProductOpen
    || confirmCloseAddProduct
    || Boolean(moveTicket)
    || Boolean(splitTicket)
    || isMergeOpen
    || Boolean(confirmProtectedAction)
    || Boolean(supervisorAction)

  useEffect(() => {
    if (pauseAutoRefresh) return

    let cancelled = false

    const refreshTrayData = async () => {
      if (document.hidden) return
      try {
        const response = await fetch(apiUrl("/api/orders/tray"), {
          credentials: "include",
          cache: "no-store",
        })
        const payload = await response.json()
        const parsed = parseApiResult(payload)
        if (!response.ok || !parsed.ok) return
        if (cancelled) return
        const nextData = (payload as { data?: OrdersTrayData }).data
        if (nextData) {
          setLiveData(nextData)
        }
      } catch {
        // Silent background refresh: avoid disrupting the workflow.
      }
    }

    const intervalId = window.setInterval(refreshTrayData, 8000)
    const visibilityHandler = () => {
      if (!document.hidden) {
        void refreshTrayData()
      }
    }

    document.addEventListener("visibilitychange", visibilityHandler)
    return () => {
      cancelled = true
      window.clearInterval(intervalId)
      document.removeEventListener("visibilitychange", visibilityHandler)
    }
  }, [pauseAutoRefresh])

  const areaOptions = useMemo(
    () => [...new Set(allResources.map((resource) => resource.area).filter(Boolean))].sort((a, b) => a.localeCompare(b, "es")),
    [allResources],
  )

  const visibleResources = useMemo(() => {
    const normalized = search.trim().toLowerCase()
    return allResources.filter((resource) => {
      const resourceState = getResourceVisualState(resource)
      const haystack = [
        resource.name,
        resource.area,
        resource.category,
        ...resource.openOrders.flatMap((ticket) => [ticket.number, ticket.reference, ticket.waiter]),
      ]
        .join(" ")
        .toLowerCase()

      const matchArea = areaFilter === "all" || resource.area === areaFilter
      const matchState = stateFilter === "all" || resourceState === stateFilter
      const matchSearch = !normalized || haystack.includes(normalized)

      return matchArea && matchState && matchSearch
    })
  }, [allResources, areaFilter, search, stateFilter])

  useEffect(() => {
    let cancelled = false

    fetch(apiUrl("/api/auth/me"), { credentials: "include" })
      .then(async (response) => {
        if (!response.ok) return null
        return response.json()
      })
      .then((payload) => {
        if (cancelled || !payload || typeof payload !== "object") return
        const user = (payload as { user?: { userId?: number; username?: string; role?: string; userType?: "A" | "S" | "O" } }).user
        if (!user) return
        setCurrentViewer({
          userId: typeof user.userId === "number" ? user.userId : 0,
          username: typeof user.username === "string" ? user.username : "",
          role: typeof user.role === "string" ? user.role : "",
          userType: user.userType === "A" || user.userType === "S" || user.userType === "O" ? user.userType : "O",
        })
      })
      .catch(() => {})

    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (!visibleResources.length) {
      setSelectedId(null)
      return
    }

    const exists = visibleResources.some((resource) => resource.id === selectedId)
    if (!exists) {
      setSelectedId(visibleResources[0].id)
    }
  }, [visibleResources, selectedId])

  const selectedResource = visibleResources.find((resource) => resource.id === selectedId) ?? visibleResources[0] ?? null
  const viewerIsPrivileged = isPrivilegedUserType(currentViewer?.userType)
  const mergeVisibleOrders = useMemo(() => {
    if (!selectedResource) return [] as OpenOrderTicket[]
    if (viewerIsPrivileged || !currentViewer?.userId) return selectedResource.openOrders
    return selectedResource.openOrders.filter((ticket) => ticket.ownerUserId === currentViewer.userId)
  }, [selectedResource, viewerIsPrivileged, currentViewer?.userId])
  const resourceLockedByAnotherUser = Boolean(
    selectedResource
    && liveData.companyLockTablesByUser
    && !viewerIsPrivileged
    && selectedResource.lockedByUserId
    && selectedResource.lockedByUserId !== currentViewer?.userId,
  )
  const selectedResourceLockMessage = resourceLockedByAnotherUser
    ? `Mesa bloqueada por ${selectedResource?.lockedByUsername || "otro usuario"}.`
    : null

  useEffect(() => {
    if (!selectedResource) {
      setSelectedTicketId(null)
      setIsDetailOpen(false)
      return
    }

    const exists = selectedResource.openOrders.some((ticket) => ticket.id === selectedTicketId)
    if (!exists) {
      setSelectedTicketId(null)
      setIsDetailOpen(false)
    }
  }, [selectedResource, selectedTicketId])

  useEffect(() => {
    const openOrderId = Number(searchParams.get("openOrderId"))
    if (!Number.isInteger(openOrderId) || openOrderId <= 0) return

    const resourceMatch = allResources.find((resource) => resource.openOrders.some((ticket) => ticket.id === openOrderId))
    if (!resourceMatch) return

    setSearch("")
    setAreaFilter("all")
    setStateFilter("all")
    setSelectedId(resourceMatch.id)
    setSelectedTicketId(openOrderId)
    setIsDetailOpen(true)
    setIsAddProductOpen(searchParams.get("openAddProduct") === "1")

    const nextParams = new URLSearchParams(searchParams.toString())
    nextParams.delete("openOrderId")
    nextParams.delete("openAddProduct")
    const nextUrl = nextParams.toString() ? `${pathname}?${nextParams.toString()}` : pathname
    router.replace(nextUrl, { scroll: false })
  }, [allResources, pathname, router, searchParams])

  const selectedTicket = selectedResource?.openOrders.find((ticket) => ticket.id === selectedTicketId) ?? selectedResource?.openOrders[0] ?? null
  const filteredSelectedTicketItems = useMemo(() => {
    if (!selectedTicket) return []
    if (selectedPersonFilter === "all") return selectedTicket.items
    return selectedTicket.items.filter((item) => (item.personNumber ?? 1) === selectedPersonFilter)
  }, [selectedPersonFilter, selectedTicket])
  const selectedTicketTotals = useMemo(() => {
    if (!selectedTicket) return null
    const base = getOrderTotals(selectedTicket)
    // Propina: si empresa la habilita, buscar si algún item del ticket tiene applyTip en el catálogo
    let tip = 0
    if (liveData.companyApplyTip) {
      const tipRate = liveData.companyTipPercent / 100
      for (const item of selectedTicket.items) {
        const product = liveData.products.find(p => p.name === item.name)
        if (product?.applyTip) {
          tip += item.price * item.quantity * tipRate
        }
      }
    }
    return { ...base, tip }
  }, [selectedTicket, liveData.companyApplyTip, liveData.companyTipPercent, liveData.products])
  const resourcesByArea = useMemo(() => {
    const grouped = new Map<string, ResourceOrderTray[]>()
    for (const resource of visibleResources) {
      const area = resource.area || "Sin area"
      const list = grouped.get(area) ?? []
      list.push(resource)
      grouped.set(area, list)
    }

    return Array.from(grouped.entries())
      .map(([area, resources]) => ({
        area,
        resources: [...resources].sort((a, b) => a.name.localeCompare(b.name, "es")),
      }))
      .sort((a, b) => a.area.localeCompare(b.area, "es"))
  }, [visibleResources])

  const productCategories = useMemo(
    () => [...new Set(liveData.products.map((product) => product.category).filter(Boolean))].sort((a, b) => a.localeCompare(b, "es")),
    [liveData.products],
  )

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

    for (const product of liveData.products) {
      if (!map.has(product.category)) {
        const base = product.categoryButtonColor || product.categoryButtonBackground || "#12467e"
        const pastel = softenHexColor(base, 0.82)
        map.set(product.category, {
          background: product.categoryButtonBackground,
          button: product.categoryButtonColor,
          text: product.categoryButtonText,
          image: product.categoryImage,
          pastel,
          ink: getReadableInk(pastel),
          border: softenHexColor(base, 0.55),
        })
      }
    }

    return map
  }, [liveData.products])

  const visibleAddProducts = useMemo(() => {
    const normalized = addProductSearch.trim().toLowerCase()
    return liveData.products.filter((product) => {
      const matchCategory = normalized ? true : selectedProductCategory === "all" || product.category === selectedProductCategory
      const matchSearch =
        !normalized ||
        product.name.toLowerCase().includes(normalized) ||
        product.category.toLowerCase().includes(normalized)
      return matchCategory && matchSearch
    })
  }, [addProductSearch, liveData.products, selectedProductCategory])

  function tryCloseAddProduct() {
    if (addProductTray.length > 0) {
      setConfirmCloseAddProduct(true)
    } else {
      resetAddProductForm()
      setIsAddProductOpen(false)
    }
  }

  function quickCreateHasData() {
    return quickReference.trim() !== "" || quickGuestCount !== "1"
  }

  function tryCloseQuickCreate() {
    if (quickCreateHasData()) {
      setConfirmCloseQuickCreate(true)
    } else {
      setIsQuickCreateOpen(false)
    }
  }

  function resetQuickDraft() {
    setQuickReference("")
    setQuickResourceId(allResources[0] ? String(allResources[0].id) : "")
    setQuickGuestCount("1")
  }

  function resetAddProductForm() {
    setAddProductSearch("")
    setSelectedProductCategory("all")
    setAddProductTray([])
  }

  function runOrderAction(url: string, body?: object, onSuccess?: () => void) {
    setMessage(null)

    startTransition(async () => {
      const response = await fetch(apiUrl(url), {
        method: "POST",
        credentials: "include",
        headers: body ? { "Content-Type": "application/json" } : undefined,
        body: body ? JSON.stringify(body) : undefined,
      })

      const parsed = parseApiResult(await response.json())
      if (!response.ok || !parsed.ok) {
        setMessage(parsed.message ?? "No se pudo completar la accion.")
        return
      }

      onSuccess?.()
      router.refresh()
    })
  }

  function createQuickOrder() {
    const resourceId = Number(quickResourceId)
    if (!resourceId) {
      setMessage("Selecciona una mesa para crear la orden.")
      return
    }
    if (!quickReference.trim()) {
      setMessage("La referencia es obligatoria para crear la orden.")
      return
    }
    const guestCount = Math.max(1, Math.floor(Number(quickGuestCount) || 1))

    setMessage(null)
    startTransition(async () => {
      const response = await fetch(apiUrl("/api/orders"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          resourceId,
          reference: quickReference.trim(),
          guestCount,
        }),
      })

      const payload = await response.json()
      const parsed = parseApiResult(payload)
      if (!response.ok || !parsed.ok) {
        setMessage(parsed.message ?? "No se pudo crear la orden.")
        return
      }

      const orderId = Number((payload as { orderId?: number }).orderId)
      setIsQuickCreateOpen(false)
      resetQuickDraft()
      router.replace(`${pathname}?openOrderId=${orderId}&openAddProduct=1`, { scroll: false })
      router.refresh()
    })
  }

  function cancelTicket(ticket: OpenOrderTicket) {
    setConfirmProtectedAction({ type: "cancel-order", ticket })
    setSupervisorAction(null)
    setSupervisorUsername("")
    setSupervisorPassword("")
    setMessage(null)
  }

  function showPendingAction(action: string) {
    setMessage(getActionMessage(action))
  }

  function addProductToTray(product: OrdersTrayData["products"][number]) {
    const maxPersonNumber = Math.max(1, selectedTicket?.guestCount ?? 1)
    const defaultPersonNumber =
      selectedPersonFilter === "all"
        ? 1
        : Math.min(Math.max(1, selectedPersonFilter), maxPersonNumber)
    setAddProductTray((current) => [
      ...current,
      {
        key: Date.now() + Math.floor(Math.random() * 1000),
        productId: product.id,
        name: product.name,
        category: product.category,
        image: product.image,
        quantity: 1,
        personNumber: defaultPersonNumber,
        note: "",
        price: product.price,
        total: product.price,
      },
    ])
    setMessage(null)
  }

  function removeTrayItem(key: number) {
    setAddProductTray((current) => current.filter((item) => item.key !== key))
  }

  const addProductTrayTotal = useMemo(
    () => addProductTray.reduce((sum, item) => sum + item.total, 0),
    [addProductTray],
  )

  function adjustTrayItemQuantity(key: number, delta: number) {
    setAddProductTray((current) =>
      current.map((item) => {
        if (item.key !== key) return item
        const quantity = Math.max(1, item.quantity + delta)
        return {
          ...item,
          quantity,
          total: item.price * quantity,
        }
      }),
    )
  }

  function setTrayItemQuantity(key: number, rawValue: string) {
    const next = Number(rawValue)
    setAddProductTray((current) =>
      current.map((item) => {
        if (item.key !== key) return item
        const quantity = Number.isFinite(next) && next > 0 ? Math.floor(next) : 1
        return {
          ...item,
          quantity,
          total: item.price * quantity,
        }
      }),
    )
  }

  function setTrayItemPerson(key: number, rawValue: string) {
    const next = Math.max(1, Math.floor(Number(rawValue) || 1))
    const max = Math.max(1, selectedTicket?.guestCount ?? 1)
    setAddProductTray((current) =>
      current.map((item) => (
        item.key === key
          ? { ...item, personNumber: Math.min(next, max) }
          : item
      )),
    )
  }

  function openTrayComments() {
    setMessage("Los comentarios predefinidos para productos estarán en la siguiente fase de esta pantalla.")
  }

  function openMoveTicket(ticket: OpenOrderTicket) {
    setMoveTicket(ticket)
    setMoveResourceId("")
    setMessage(null)
  }

  function openSplitTicket(ticket: OpenOrderTicket) {
    setSplitTicket(ticket)
    setMessage(null)
  }

  function openMergeOrders() {
    if (!selectedResource || mergeVisibleOrders.length < 2) {
      setMessage("Necesitas al menos dos ordenes abiertas en la misma mesa para unificar.")
      return
    }
    const [firstOrder, ...restOrders] = mergeVisibleOrders
    setMergeTargetId(firstOrder?.id ?? null)
    setMergeSourceIds(restOrders.map((ticket) => ticket.id))
    setIsMergeOpen(true)
    setMessage(null)
  }

  function closeMergeOrders() {
    setIsMergeOpen(false)
    setMergeTargetId(null)
    setMergeSourceIds([])
  }

  function toggleMergeSource(orderId: number) {
    setMergeSourceIds((current) => (
      current.includes(orderId)
        ? current.filter((value) => value !== orderId)
        : [...current, orderId]
    ))
  }

  function confirmMergeOrders() {
    if (!selectedResource) return
    const targetOrderId = mergeTargetId ?? 0
    const sourceOrderIds = mergeSourceIds.filter((value) => value !== targetOrderId)

    if (!Number.isInteger(targetOrderId) || targetOrderId <= 0) {
      setMessage("Selecciona la orden destino.")
      return
    }

    if (!sourceOrderIds.length) {
      setMessage("Selecciona al menos una orden origen para unificar.")
      return
    }

    setMessage(null)
    startTransition(async () => {
      const response = await fetch(apiUrl("/api/orders/merge"), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          targetOrderId,
          sourceOrderIds,
        }),
      })

      const parsed = parseApiResult(await response.json())
      if (!response.ok || !parsed.ok) {
        setMessage(parsed.message ?? "No se pudo unificar las ordenes.")
        return
      }

      closeMergeOrders()
      setSelectedTicketId(targetOrderId)
      setIsDetailOpen(true)
      setMessage("Ordenes unificadas correctamente.")
      router.refresh()
    })
  }

  function confirmMoveTicket() {
    if (!moveTicket) return
    const resourceId = Number(moveResourceId)
    if (!Number.isInteger(resourceId) || resourceId <= 0) {
      setMessage("Selecciona una mesa destino válida.")
      return
    }
    runOrderAction(`/api/orders/${moveTicket.id}/move`, { resourceId }, () => {
      setMoveTicket(null)
      setMoveResourceId("")
      setMessage("Orden movida correctamente.")
    })
  }

  function requestDeleteLine(ticket: OpenOrderTicket, lineId: number, lineName: string) {
    setConfirmProtectedAction({ type: "delete-line", ticket, lineId, lineName })
    setSupervisorAction(null)
    setSupervisorUsername("")
    setSupervisorPassword("")
    setMessage(null)
  }

  function updateLinePerson(ticket: OpenOrderTicket, lineId: number, personNumber: number) {
    setMessage(null)

    startTransition(async () => {
      const response = await fetch(apiUrl(`/api/orders/${ticket.id}/lines`), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ orderLineId: lineId, personNumber }),
      })

      const parsed = parseApiResult(await response.json())
      if (!response.ok || !parsed.ok) {
        setMessage(parsed.message ?? "No se pudo actualizar la persona de la linea.")
        return
      }

      router.refresh()
    })
  }

  function runProtectedAction(action: SupervisorAction, options?: { requireSupervisor?: boolean }) {
    startTransition(async () => {
      if (options?.requireSupervisor) {
        if (!supervisorUsername.trim() || !supervisorPassword) {
          setMessage("Indica usuario y clave del supervisor.")
          return
        }

        const permissionKey = action.type === "cancel-order" ? "orders.cancel" : "orders.delete"
        const verifyResponse = await fetch(apiUrl("/api/auth/supervisor-verify"), {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            username: supervisorUsername.trim(),
            password: supervisorPassword,
            permissionKey,
          }),
        })

        const verifyParsed = parseApiResult(await verifyResponse.json())
        if (!verifyResponse.ok || !verifyParsed.ok) {
          setMessage(verifyParsed.message ?? "No se pudo validar el supervisor.")
          return
        }
      }

      if (action.type === "cancel-order") {
        const ticket = action.ticket
        const response = await fetch(apiUrl(`/api/orders/${ticket.id}/cancel`), {
          method: "POST",
          credentials: "include",
        })
        const parsed = parseApiResult(await response.json())
        if (!response.ok || !parsed.ok) {
          setMessage(parsed.message ?? "No se pudo cancelar la orden.")
          return
        }
        setConfirmProtectedAction(null)
        setSupervisorAction(null)
        setMessage(getSupervisorActionCopy(action).successMessage)
        router.refresh()
        return
      }

      const response = await fetch(apiUrl(`/api/orders/${action.ticket.id}/lines`), {
        method: "DELETE",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ orderLineId: action.lineId }),
      })
      const parsed = parseApiResult(await response.json())
      if (!response.ok || !parsed.ok) {
        setMessage(parsed.message ?? "No se pudo eliminar la línea.")
        return
      }
      setConfirmProtectedAction(null)
      setSupervisorAction(null)
      setMessage(getSupervisorActionCopy(action).successMessage)
      router.refresh()
    })
  }

  function confirmProtectedActionAndContinue() {
    if (!confirmProtectedAction) return
    const privileged = isPrivilegedUserType(currentViewer?.userType)
    if (privileged) {
      runProtectedAction(confirmProtectedAction)
      return
    }

    setSupervisorAction(confirmProtectedAction)
    setConfirmProtectedAction(null)
    setSupervisorUsername("")
    setSupervisorPassword("")
  }

  function verifySupervisorAndContinue() {
    if (!supervisorAction) return
    runProtectedAction(supervisorAction, { requireSupervisor: true })
  }

  function saveTrayToSelectedOrder() {
    if (!selectedTicket) {
      setMessage("Selecciona una orden antes de agregar productos.")
      return
    }

    if (!addProductTray.length) {
      setMessage("Agrega al menos un producto a la bandeja.")
      return
    }

    setMessage(null)
    startTransition(async () => {
      for (const item of addProductTray) {
        const response = await fetch(apiUrl(`/api/orders/${selectedTicket.id}/lines`), {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            productId: item.productId,
            quantity: item.quantity,
            personNumber: item.personNumber,
            note: item.note,
          }),
        })

        const parsed = parseApiResult(await response.json())
        if (!response.ok || !parsed.ok) {
          setMessage(parsed.message ?? `No se pudo agregar ${item.name}.`)
          return
        }
      }

      setIsAddProductOpen(false)
      resetAddProductForm()
      router.refresh()
    })
  }

  return (
    <section className="orders-layout orders-layout--redesign">
      <div className="orders-workspace">
        <section className="data-panel orders-column orders-column--resources">
          <div className="data-panel__header">
            <div>
              <h2>Mesas</h2>
            </div>
          </div>

          <div className="orders-filters">
            <label className="orders-filter-field">
              <span>Área</span>
              <select value={areaFilter} onChange={(event) => setAreaFilter(event.target.value)}>
                <option value="all">Todas</option>
                {areaOptions.map((area) => (
                  <option key={area} value={area}>{area}</option>
                ))}
              </select>
            </label>
            <label className="orders-filter-field">
              <span>Estado</span>
              <select value={stateFilter} onChange={(event) => setStateFilter(event.target.value)}>
                <option value="all">Todos</option>
                <option value="free">Libres</option>
                <option value="single">Activa</option>
                <option value="multiple">Múltiples</option>
                <option value="in-progress">En proceso</option>
              </select>
            </label>
            <label className="orders-filter-field orders-filter-field--search">
              <span>Buscar</span>
              <div className="orders-search-input">
                <Search size={16} />
                <input
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="Mesa, orden, cliente, camarero"
                />
              </div>
            </label>
          </div>

          <div className="orders-resource-list">
            {resourcesByArea.length ? resourcesByArea.map((group) => (
              <section key={group.area} className="orders-resource-group">
                <header className="orders-resource-group__header">
                  <h3>{group.area}</h3>
                </header>
                <div className="orders-resource-tiles">
                  {group.resources.map((resource) => {
                    const isSelected = selectedResource?.id === resource.id
                    const visual = getResourceVisualMeta(resource)
                    const isLockedByAnotherUser = Boolean(
                      liveData.companyLockTablesByUser
                      && !viewerIsPrivileged
                      && resource.lockedByUserId
                      && resource.lockedByUserId !== currentViewer?.userId,
                    )
                    return (
                      <button
                        key={resource.id}
                        type="button"
                        className={`orders-resource-card orders-resource-card--${visual.tone}${isSelected ? " is-selected" : ""}`}
                        style={{ "--cat-color": resource.categoryColor || "var(--brand)" } as Record<string, string>}
                        onClick={() => setSelectedId(resource.id)}
                        title={`${resource.name}\n${resource.area} · ${resource.category}\nÓrdenes abiertas: ${resource.openCount}\nPrimera orden: ${resource.firstOrderTime}\nTotal acumulado: ${formatMoney(resource.totalOpen)}\nEstado: ${visual.label}${isLockedByAnotherUser ? `\nBloqueada por: ${resource.lockedByUsername || "otro usuario"}` : ""}`}
                      >
                        <div className="orders-resource-card__topline">
                          <h4>{getResourceShortName(resource.name)}</h4>
                        </div>
                        <div className="orders-resource-card__amount">{formatMoney(resource.totalOpen)}</div>
                        <div className="orders-resource-card__meta">
                          <span>{visual.label}</span>
                          <span>{resource.firstOrderTime}</span>
                        </div>
                      </button>
                    )
                  })}
                </div>
              </section>
            )) : (
              <div className="detail-empty detail-empty--compact">
                <Receipt size={26} />
                <h3>Sin resultados</h3>
                <p>No hay mesas que coincidan con los filtros actuales.</p>
              </div>
            )}
          </div>
        </section>

        <section className="data-panel orders-column orders-column--tickets">
          <div className="data-panel__header data-panel__header--actions">
            <div>
              <h2>{selectedResource ? `Órdenes abiertas de ${selectedResource.name}` : "Órdenes abiertas"}</h2>
              {selectedResource ? <p>{selectedResource.openCount} órdenes activas</p> : null}
            </div>
            <div className="orders-tickets-header-actions">
              {selectedResource && mergeVisibleOrders.length > 1 ? (
                <button
                  className="secondary-button"
                  type="button"
                  onClick={openMergeOrders}
                  disabled={isPending}
                >
                  <GitMerge size={16} />
                  Unificar
                </button>
              ) : null}
              <button
                className="primary-button"
                type="button"
                onClick={() => {
                  if (selectedResource) setQuickResourceId(String(selectedResource.id))
                  setIsQuickCreateOpen(true)
                }}
                disabled={!selectedResource || resourceLockedByAnotherUser}
                title={selectedResourceLockMessage ?? undefined}
              >
                <Plus size={16} />
                Nueva
              </button>
            </div>
          </div>

          {selectedResource ? (
            <div className="order-ticket-listing order-ticket-listing--cards">
              {selectedResource.openOrders.length ? selectedResource.openOrders.map((ticket) => {
                const totals = getOrderTotals(ticket)
                const tone = getTicketTone(ticket.state)
                const isSelected = selectedTicket?.id === ticket.id
                const ownedByAnotherUser = Boolean(
                  liveData.companyRestrictOrdersByUser
                  && !viewerIsPrivileged
                  && ticket.ownerUserId
                  && ticket.ownerUserId !== currentViewer?.userId,
                )
                return (
                  <button
                    key={ticket.id}
                    type="button"
                    className={`order-sheet order-sheet--${tone}${isSelected ? " is-selected" : ""}`}
                    onClick={() => {
                      if (ownedByAnotherUser) {
                        setMessage("Solo el propietario o un supervisor puede entrar o modificar esta orden.")
                        return
                      }
                      setSelectedTicketId(ticket.id)
                      setSelectedPersonFilter("all")
                      setIsDetailOpen(true)
                    }}
                    title={ownedByAnotherUser ? "Solo el propietario o un supervisor puede entrar o modificar esta orden." : undefined}
                  >
                    <div className="order-sheet__head">
                      <div>
                        <h4>{ticket.number}</h4>
                        <p>{ticket.reference || "Sin referencia de cliente"}</p>
                      </div>
                      <span className={`chip chip--${tone}`}>{ticket.state}</span>
                    </div>

                    <div className="order-sheet__meta">
                      <span><UserRound size={14} /> {ticket.waiter}</span>
                      <span><Clock3 size={14} /> {ticket.createdAt ? formatDateTime(ticket.createdAt) : ticket.time}</span>
                    </div>

                    <div className="order-sheet__footer">
                      <span className="order-sheet__summary">
                        {ticket.items.reduce((sum, item) => sum + item.quantity, 0)} item(s)
                      </span>
                      <strong>{renderMoneyAccent(totals.total)}</strong>
                    </div>
                  </button>
                )
              }) : (
                <div className="detail-empty detail-empty--compact">
                  <Receipt size={28} />
                  <h3>Sin órdenes abiertas</h3>
                  <p>Esta mesa no tiene tickets activos por el momento.</p>
                </div>
              )}
            </div>
          ) : (
            <div className="detail-empty detail-empty--compact">
              <Receipt size={28} />
              <h3>Selecciona una mesa</h3>
              <p>La columna central mostrará aquí todas las órdenes abiertas de la mesa elegida.</p>
            </div>
          )}
        </section>

      </div>

      {selectedResource && selectedTicket && selectedTicketTotals && isDetailOpen ? (
        <>
          <button
            type="button"
            className="orders-drawer-backdrop"
            aria-label="Cerrar detalle"
            onClick={() => setIsDetailOpen(false)}
          />
          <aside className="orders-drawer" aria-label="Detalle de la orden">
            <div className="orders-drawer__header">
              <div>
                <h3>{selectedTicket.number}</h3>
                <p>{selectedResource.name} · {selectedResource.area}</p>
              </div>
              <div className="orders-drawer__header-actions">
                <span className={`chip chip--${getTicketTone(selectedTicket.state)}`}>{selectedTicket.state}</span>
                <button className="ghost-button ghost-button--xs" type="button" onClick={() => setIsDetailOpen(false)}>
                  <X size={14} />
                </button>
              </div>
            </div>

            <section className="orders-detail-card">
              <div className="orders-detail-card__row">
                <span>Cliente / Referencia</span>
                <strong>{selectedTicket.reference || "Sin referencia"}</strong>
              </div>
              <div className="orders-detail-card__row">
                <span>Camarero</span>
                <strong>{selectedTicket.waiter}</strong>
              </div>
              <div className="orders-detail-card__row">
                <span>Hora</span>
                <strong>{selectedTicket.time}</strong>
              </div>
              <div className="orders-detail-card__row">
                <span>PAX</span>
                <strong>{selectedTicket.guestCount}</strong>
              </div>
            </section>

            <section className="orders-detail-lines">
              <div className="orders-detail-lines__header">
                <h3>Productos</h3>
                {selectedTicket.guestCount > 1 ? (
                  <div className="orders-detail-lines__filters" role="tablist" aria-label="Filtrar productos por persona">
                    <button
                      type="button"
                      className={selectedPersonFilter === "all" ? "filter-pill is-active" : "filter-pill"}
                      onClick={() => setSelectedPersonFilter("all")}
                    >
                      Ver todos
                    </button>
                    {Array.from({ length: selectedTicket.guestCount }, (_, index) => index + 1).map((person) => (
                      <button
                        key={person}
                        type="button"
                        className={selectedPersonFilter === person ? "filter-pill is-active" : "filter-pill"}
                        onClick={() => setSelectedPersonFilter(person)}
                      >
                        {person}
                      </button>
                    ))}
                  </div>
                ) : null}
              </div>
              {filteredSelectedTicketItems.length ? (
                <div className="orders-detail-lines__list">
                  {filteredSelectedTicketItems.map((item) => (
                    <article key={`${selectedTicket.id}-${item.id}`} className="order-line-item order-line-item--detail">
                      <div className="order-line-item__head">
                        <div className="order-line-item__head-main">
                          <span className="order-line-item__qty">{item.quantity}x</span>
                          <strong>{item.name}</strong>
                        </div>
                        <div className="order-line-item__head-actions">
                          {selectedTicket.guestCount > 1 ? (
                            <select
                              className="orders-detail-line__person-select"
                              value={item.personNumber ?? 1}
                              onChange={(event) => updateLinePerson(selectedTicket, item.id, Number(event.target.value))}
                              disabled={isPending}
                              title="Cambiar persona"
                            >
                              {Array.from({ length: selectedTicket.guestCount }, (_, index) => index + 1).map((value) => (
                                <option key={value} value={value}>
                                  P{value}
                                </option>
                              ))}
                            </select>
                          ) : null}
                          <button
                            type="button"
                            className="ghost-icon-button"
                            onClick={() => requestDeleteLine(selectedTicket, item.id, item.name)}
                            disabled={isPending}
                            title="Eliminar línea"
                          >
                            <Trash2 size={15} />
                          </button>
                        </div>
                      </div>
                      {(() => {
                        const pricing = getOrderLinePricing(item, liveData.products, liveData.companyApplyTip, liveData.companyTipPercent)
                        return (
                          <div className="orders-detail-line__pricing">
                            <div className="orders-detail-line__price-box">
                              <span className="orders-detail-line__price-label">Base</span>
                              <strong>{renderMoneyAccent(pricing.base)}</strong>
                            </div>
                            <div className="orders-detail-line__price-box">
                              <span className="orders-detail-line__price-label">+ ITBIS</span>
                              <strong>{renderMoneyAccent(pricing.withTax)}</strong>
                            </div>
                            {pricing.hasTip ? (
                              <div className="orders-detail-line__price-box orders-detail-line__price-box--accent">
                                <span className="orders-detail-line__price-label">+ Propina legal</span>
                                <strong>{renderMoneyAccent(pricing.withTip ?? pricing.withTax)}</strong>
                              </div>
                            ) : null}
                          </div>
                        )
                      })()}
                      {item.note ? <p className="order-line-item__note">{item.note}</p> : null}
                      <div className="orders-detail-line__meta orders-detail-line__meta--secondary orders-detail-line__meta--footer">
                        <span>{formatOrderLineDateTime(item.createdAt)} · {item.createdBy || "N/D"}</span>
                      </div>
                    </article>
                  ))}
                </div>
              ) : (
                <div className="detail-empty detail-empty--compact">
                  <UtensilsCrossed size={24} />
                  <h3>Sin productos</h3>
                  <p>Agrega productos a esta orden para continuar.</p>
                </div>
              )}
            </section>

            <section className="orders-detail-summary">
              <div><span>Subtotal</span><strong>{renderMoneyAccent(selectedTicketTotals.subtotal)}</strong></div>
              <div><span>Impuesto</span><strong>{renderMoneyAccent(selectedTicketTotals.tax)}</strong></div>
              {selectedTicketTotals.tip > 0 && (
                <div><span>Propina ({liveData.companyTipPercent}%)</span><strong>{renderMoneyAccent(selectedTicketTotals.tip)}</strong></div>
              )}
              <div><span>Descuento</span><strong>{renderMoneyAccent(selectedTicketTotals.discount)}</strong></div>
              <div className="orders-detail-summary__total"><span>Total</span><strong>{renderMoneyAccent(selectedTicketTotals.total)}</strong></div>
            </section>

              <section className="orders-detail-actions">
              <button
                className="secondary-button"
                type="button"
                onClick={() => {
                  setIsAddProductOpen(true)
                  setSelectedProductCategory("all")
                  setMessage(null)
                }}
              >
                <Plus size={16} />
                Agregar
              </button>
              <button className="secondary-button" type="button" onClick={() => openSplitTicket(selectedTicket)}>
                <Split size={16} />
                Dividir
              </button>
              <button className="secondary-button" type="button" onClick={() => openMoveTicket(selectedTicket)}>
                <ArrowRightLeft size={16} />
                Mover
              </button>
              <button
                className="primary-button orders-detail-actions__checkout"
                type="button"
                onClick={() => showPendingAction("Enviar a caja")}
                disabled={isPending}
              >
                <CreditCard size={16} />
                Enviar a caja
              </button>
              <button className="ghost-button orders-detail-actions__cancel" type="button" onClick={() => cancelTicket(selectedTicket)} disabled={isPending}>
                <XCircle size={16} />
                Cancelar orden
              </button>
            </section>
          </aside>
        </>
      ) : null}

      {isAddProductOpen && selectedTicket ? (
        <section className="order-modal-backdrop" onClick={tryCloseAddProduct}>
          <article className="data-panel order-modal order-modal--pos" onClick={(event) => event.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions order-modal__header-sticky">
              <div className="order-modal__titleline">
                <h2>Agregar producto</h2>
                <p>{selectedTicket.number} · {selectedResource?.name ?? "Orden seleccionada"}</p>
              </div>
              <div className="order-modal__header-actions">
                <button
                  className="secondary-button secondary-button--sm"
                  type="button"
                  onClick={tryCloseAddProduct}
                  disabled={isPending}
                >
                  Cancelar
                </button>
                <button className="primary-button primary-button--sm" type="button" onClick={saveTrayToSelectedOrder} disabled={isPending}>
                  Guardar
                </button>
              </div>
            </div>

            <div className="order-create-form">
              <div className="order-pos-picker">
                <aside className="order-pos-picker__categories">
                  <button
                    type="button"
                    className={`order-pos-category${selectedProductCategory === "all" ? " is-selected" : ""}`}
                    onClick={() => setSelectedProductCategory("all")}
                  >
                    Todas
                  </button>
                  {productCategories.map((category) => (
                    (() => {
                      const meta = productCategoryMeta.get(category)
                      return (
                    <button
                      key={category}
                      type="button"
                      className={`order-pos-category${selectedProductCategory === category ? " is-selected" : ""}${meta?.image ? " has-image" : ""}`}
                      onClick={() => setSelectedProductCategory(category)}
                      style={{
                        background: meta?.pastel ?? undefined,
                        color: meta?.ink ?? undefined,
                        borderColor: meta?.border ?? undefined,
                      }}
                    >
                      {meta?.image ? <span className="order-pos-category__image" style={{ backgroundImage: `url(${withImageVersion(meta.image)})` }} /> : null}
                      <span className="order-pos-category__label">{category}</span>
                    </button>
                      )
                    })()
                  ))}
                </aside>

                <div className="order-pos-picker__products">
                  <div className="orders-search-input orders-search-input--compact">
                    <Search size={16} />
                    <input
                      value={addProductSearch}
                      onChange={(event) => setAddProductSearch(event.target.value)}
                      placeholder="Buscar item en cualquier categoría"
                    />
                  </div>

                  <div className="order-pos-product-grid">
                    {visibleAddProducts.length ? visibleAddProducts.map((product) => (
                      <button
                        key={product.id}
                        type="button"
                        className={`order-pos-product${product.image ? " has-image" : ""}`}
                        onClick={() => addProductToTray(product)}
                        style={product.image ? {
                          background: `linear-gradient(180deg, rgba(255,255,255,0.05) 0%, rgba(15,23,42,0.46) 100%), url(${withImageVersion(product.image)}) center/cover no-repeat`,
                          color: "#ffffff",
                          borderColor: product.itemButtonBackground,
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
                        <Receipt size={22} />
                        <h3>Sin productos</h3>
                        <p>No hay items para los filtros actuales.</p>
                      </div>
                    )}
                  </div>
                </div>

                <aside className="order-pos-tray">
                  <div className="order-pos-tray__header">
                    <strong>Bandeja</strong>
                    <span>{addProductTray.length} item(s)</span>
                  </div>
                  <div className="order-pos-tray__list">
                    {addProductTray.length ? addProductTray.map((item) => (
                      <article key={item.key} className="order-pos-tray__item">
                        <div className="order-pos-tray__item-top">
                          <div className="order-pos-tray__item-title">
                            <strong>{item.name}</strong>
                          </div>
                          <div className="order-pos-tray__item-actions">
                            {selectedTicket.guestCount > 1 ? (
                              <label className="order-pos-tray__person-field">
                                <select
                                  value={item.personNumber}
                                  onChange={(event) => setTrayItemPerson(item.key, event.target.value)}
                                  disabled={isPending}
                                >
                                  {Array.from({ length: selectedTicket.guestCount }, (_, index) => index + 1).map((value) => (
                                    <option key={value} value={value}>
                                      P{value}
                                    </option>
                                  ))}
                                </select>
                              </label>
                            ) : null}
                          </div>
                        </div>
                        <div className="order-pos-tray__controls">
                          <div className="order-pos-tray__controls-row">
                            <div className="order-pos-tray__qty order-pos-tray__qty--negative">
                              {[-10, -5, -1].map((delta) => (
                                <button
                                  key={delta}
                                  type="button"
                                  className="order-pos-tray__qty-btn"
                                  onClick={() => adjustTrayItemQuantity(item.key, delta)}
                                  disabled={isPending}
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
                              onChange={(event) => setTrayItemQuantity(item.key, event.target.value)}
                              disabled={isPending}
                            />
                            <div className="order-pos-tray__qty order-pos-tray__qty--positive">
                              {[1, 5, 10].map((delta) => (
                                <button
                                  key={delta}
                                  type="button"
                                  className="order-pos-tray__qty-btn is-positive"
                                  onClick={() => adjustTrayItemQuantity(item.key, delta)}
                                  disabled={isPending}
                                >
                                  {`+${delta}`}
                                </button>
                              ))}
                            </div>
                          </div>
                          <div className="order-pos-tray__controls-meta">
                            <button
                              type="button"
                              className="order-pos-tray__note-btn"
                              onClick={openTrayComments}
                              disabled={isPending}
                            >
                              <StickyNote size={14} />
                              Notas
                            </button>
                            <b className="order-pos-tray__line-total">{renderMoneyAccent(item.total)}</b>
                            <button type="button" className="ghost-icon-button" onClick={() => removeTrayItem(item.key)} disabled={isPending}>
                              <Trash2 size={15} />
                            </button>
                          </div>
                        </div>
                      </article>
                    )) : (
                      <div className="detail-empty detail-empty--compact">
                        <Receipt size={20} />
                        <h3>Bandeja vacia</h3>
                        <p>Selecciona productos y agrégalos para confirmar en lote.</p>
                      </div>
                    )}
                  </div>
                  <div className="order-pos-tray__footer">
                    <span>Total bandeja</span>
                    <strong>{renderMoneyAccent(addProductTrayTotal)}</strong>
                  </div>
                </aside>
              </div>

            </div>
          </article>
        </section>
      ) : null}

      {isQuickCreateOpen ? (
        <section className="order-modal-backdrop" onClick={tryCloseQuickCreate}>
          <article className="data-panel order-modal" onClick={(event) => event.stopPropagation()}>
            <div className="data-panel__header data-panel__header--actions">
              <div>
                <h2>Nueva orden</h2>
              </div>
              <button className="secondary-button secondary-button--sm" type="button" onClick={tryCloseQuickCreate}>
                Cancelar
              </button>
            </div>

            <div className="order-create-form">
              <label>
                <span>Mesa *</span>
                <select value={quickResourceId} onChange={(event) => setQuickResourceId(event.target.value)} required>
                  <option value="">Selecciona mesa</option>
                  {allResources.map((resource) => (
                    <option key={resource.id} value={resource.id}>
                      {resource.name} — {resource.area} / {resource.category}
                    </option>
                  ))}
                </select>
              </label>

              <label>
                <span>Cliente o referencia *</span>
                <input
                  value={quickReference}
                  onChange={(event) => setQuickReference(event.target.value)}
                  placeholder="Ej: Cuenta 4 / Juan Perez"
                  maxLength={200}
                  required
                />
              </label>

              <label>
                <span>PAX / Personas</span>
                <div className="order-create-pax-grid" role="listbox" aria-label="Seleccionar cantidad de personas">
                  {Array.from({ length: 20 }, (_, index) => {
                    const value = String(index + 1)
                    const isActive = quickGuestCount === value
                    return (
                      <button
                        key={value}
                        type="button"
                        className={isActive ? "order-create-pax is-active" : "order-create-pax"}
                        aria-selected={isActive}
                        onClick={() => setQuickGuestCount(value)}
                      >
                        {value}
                      </button>
                    )
                  })}
                </div>
              </label>

              <div className="order-detail__actions order-detail__actions--inline">
                <button className="secondary-button" type="button" onClick={tryCloseQuickCreate} disabled={isPending}>
                  Cancelar
                </button>
                <button className="primary-button" type="button" onClick={createQuickOrder} disabled={isPending}>
                  Crear orden
                </button>
              </div>
            </div>
          </article>
        </section>
      ) : null}

      {moveTicket ? (
        <div className="modal-backdrop" onClick={() => setMoveTicket(null)}>
          <div className="modal-card modal-card--sm" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <ArrowRightLeft size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Mover orden</h3>
                <p className="modal-card__subtitle">{moveTicket.number}</p>
              </div>
            </div>
            <div className="modal-card__body">
              <label className="field-group">
                <span>Mesa destino</span>
                <select value={moveResourceId} onChange={(event) => setMoveResourceId(event.target.value)}>
                  <option value="">Selecciona mesa</option>
                  {allResources
                    .filter((resource) => resource.id !== selectedResource?.id)
                    .map((resource) => (
                      <option key={resource.id} value={resource.id}>
                        {resource.name} — {resource.area} / {resource.category}
                      </option>
                    ))}
                </select>
              </label>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setMoveTicket(null)}>
                Cancelar
              </button>
              <button type="button" className="primary-button" onClick={confirmMoveTicket} disabled={isPending}>
                Mover
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {splitTicket ? (
        <OrdersSplitPanel
          orderId={splitTicket.id}
          order={splitTicket}
          onClose={() => setSplitTicket(null)}
        />
      ) : null}

      {isMergeOpen && selectedResource ? (
        <div className="modal-backdrop" onClick={closeMergeOrders}>
          <div className="modal-card modal-card--md" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <GitMerge size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Unificar ordenes</h3>
                <p className="modal-card__subtitle">{selectedResource.name} · {mergeVisibleOrders.length} ordenes disponibles</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <div className="merge-orders-help">
                <p>{viewerIsPrivileged ? "Selecciona una orden destino y marca las ordenes origen que deseas absorber." : "Solo se muestran tus ordenes activas en esta mesa para unificarlas."}</p>
              </div>
              <div className="merge-orders-list">
                {mergeVisibleOrders.map((ticket) => {
                  const isTarget = mergeTargetId === ticket.id
                  const isSource = mergeSourceIds.includes(ticket.id)
                  return (
                    <article key={ticket.id} className={`merge-order-card${isTarget ? " is-target" : ""}${isSource ? " is-source" : ""}`}>
                      <div className="merge-order-card__top">
                        <div className="merge-order-card__left">
                          <strong>{ticket.number}</strong>
                          <span className="merge-order-card__ref">{ticket.reference || "Sin referencia"}</span>
                        </div>
                        <div className="merge-order-card__selectors">
                          <label className="merge-order-card__radio">
                            <input
                              type="radio"
                              name="merge-target-order"
                              checked={isTarget}
                              onChange={() => {
                                setMergeTargetId(ticket.id)
                                setMergeSourceIds((current) => current.filter((value) => value !== ticket.id))
                              }}
                            />
                            <span>Destino</span>
                          </label>
                          <label className="merge-order-card__check">
                            <input
                              type="checkbox"
                              checked={isSource}
                              disabled={isTarget}
                              onChange={() => toggleMergeSource(ticket.id)}
                            />
                            <span>Origen</span>
                          </label>
                        </div>
                      </div>
                      <div className="merge-order-card__footer">
                        <span><UserRound size={13} /> {ticket.waiter}</span>
                        <span><Clock3 size={13} /> {ticket.createdAt ? formatDateTime(ticket.createdAt) : ticket.time}</span>
                        <span>{ticket.items.reduce((sum, item) => sum + item.quantity, 0)} item(s)</span>
                        <strong>{renderMoneyAccent(ticket.total)}</strong>
                      </div>
                    </article>
                  )
                })}
              </div>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={closeMergeOrders}>
                Cancelar
              </button>
              <button type="button" className="primary-button" onClick={confirmMergeOrders} disabled={isPending}>
                Unificar ordenes
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {confirmProtectedAction ? (
        <div className="modal-backdrop" onClick={() => setConfirmProtectedAction(null)}>
          <div className="modal-card modal-card--sm modal-card--elevated" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--danger-soft">
              <div className="modal-card__header-icon modal-card__header-icon--danger">
                <ShieldAlert size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">{getSupervisorActionCopy(confirmProtectedAction).title}</h3>
                <p className="modal-card__subtitle">{getSupervisorActionCopy(confirmProtectedAction).subtitle}</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <div className="modal-confirm-copy">
                {isPrivilegedUserType(currentViewer?.userType) ? (
                  <p>Tu perfil ya tiene autorización para continuar. Solo confirma si deseas ejecutar esta acción.</p>
                ) : (
                  <p>Primero confirma la acción. Luego te pediremos credenciales de supervisor para continuar.</p>
                )}
              </div>
            </div>
            <div className="modal-card__footer">
              <button
                type="button"
                className="secondary-button"
                onClick={() => {
                  setConfirmProtectedAction(null)
                  setMessage(null)
                }}
              >
                Volver
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={confirmProtectedActionAndContinue}
                disabled={isPending}
              >
                {getSupervisorActionCopy(confirmProtectedAction).confirmLabel}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {supervisorAction ? (
        <div className="modal-backdrop" onClick={() => setSupervisorAction(null)}>
          <div className="modal-card modal-card--sm" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand-soft">
              <div className="modal-card__header-icon modal-card__header-icon--brand">
                <ShieldCheck size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Credenciales de supervisor</h3>
                <p className="modal-card__subtitle">Introduce las credenciales para autorizar esta acción.</p>
              </div>
            </div>
            <div className="modal-card__body modal-card__body--stack">
              <div className="modal-confirm-copy">
                <strong>{getSupervisorActionCopy(supervisorAction).title}</strong>
                <p>{supervisorAction.type === "cancel-order" ? supervisorAction.ticket.number : supervisorAction.lineName}</p>
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
                <span>Clave</span>
                <input
                  type="password"
                  value={supervisorPassword}
                  onChange={(event) => setSupervisorPassword(event.target.value)}
                  placeholder="Clave"
                  autoComplete="current-password"
                />
              </label>
            </div>
            <div className="modal-card__footer">
              <button
                type="button"
                className="secondary-button"
                onClick={() => {
                  setSupervisorAction(null)
                  setMessage(null)
                }}
              >
                Cancelar
              </button>
              <button type="button" className="primary-button" onClick={verifySupervisorAndContinue} disabled={isPending}>
                Autorizar
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {confirmCloseAddProduct ? (
        <div className="modal-backdrop" onClick={() => setConfirmCloseAddProduct(false)}>
          <div className="modal-card modal-card--sm" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <PackageOpen size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Descartar bandeja</h3>
                <p className="modal-card__subtitle">{addProductTray.length} item(s) en bandeja</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>Si cancelas ahora se perderan los productos que agregaste a la bandeja. ¿Deseas continuar?</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setConfirmCloseAddProduct(false)}>
                Seguir agregando
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={() => {
                  setConfirmCloseAddProduct(false)
                  resetAddProductForm()
                  setIsAddProductOpen(false)
                }}
              >
                Descartar y cerrar
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {confirmCloseQuickCreate ? (
        <div className="modal-backdrop" onClick={() => setConfirmCloseQuickCreate(false)}>
          <div className="modal-card modal-card--sm" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <Plus size={20} />
              </div>
              <div>
                <h3 className="modal-card__title">Descartar orden</h3>
                <p className="modal-card__subtitle">Tienes datos sin guardar</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>Si cierras ahora perderas los datos de la nueva orden. ¿Deseas continuar?</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setConfirmCloseQuickCreate(false)}>
                Seguir editando
              </button>
              <button
                type="button"
                className="danger-button"
                onClick={() => {
                  setConfirmCloseQuickCreate(false)
                  resetQuickDraft()
                  setIsQuickCreateOpen(false)
                }}
              >
                Descartar y cerrar
              </button>
            </div>
          </div>
        </div>
      ) : null}

    </section>
  )
}
