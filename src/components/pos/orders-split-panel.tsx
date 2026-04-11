"use client"

import { useEffect, useMemo, useState } from "react"
import { Check, Circle, Eye, Plus } from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { OpenOrderTicket, OrdenCuenta, OrdenCuentaDetalleItem, OrdenCuentaPrefactura } from "@/lib/pos-data"

type OrdersSplitPanelProps = {
  orderId: number
  order: OpenOrderTicket
  onClose: () => void
}

type AccountsResponse = { ok: boolean; data?: OrdenCuenta[]; message?: string }
type DetailResponse = { ok: boolean; data?: OrdenCuentaDetalleItem[]; message?: string }
type PrefacturaResponse = { ok: boolean; data?: OrdenCuentaPrefactura; message?: string }

type ItemAssignment = {
  item: OpenOrderTicket["items"][number]
  qty: number
}

export function OrdersSplitPanel({ orderId, order, onClose }: OrdersSplitPanelProps) {
  const [cuentas, setCuentas] = useState<OrdenCuenta[]>([])
  const [detallePorCuenta, setDetallePorCuenta] = useState<Record<number, OrdenCuentaDetalleItem[]>>({})
  const [selectedCuenta, setSelectedCuenta] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)
  const [isPending, setIsPending] = useState(false)
  const [prefacturaData, setPrefacturaData] = useState<OrdenCuentaPrefactura | null>(null)
  const [showEquitativaModal, setShowEquitativaModal] = useState(false)
  const [showResetConfirm, setShowResetConfirm] = useState(false)
  const [sendToCashTarget, setSendToCashTarget] = useState<OrdenCuenta | null>(null)
  const [equitativaCantidad, setEquitativaCantidad] = useState(2)
  const [itemMode, setItemMode] = useState(false)
  const [itemQuantities, setItemQuantities] = useState<Record<number, number>>({})
  const [selectedItemIds, setSelectedItemIds] = useState<number[]>([])

  useEffect(() => {
    void loadCuentas()
  }, [])

  const selectedAccountDetail = selectedCuenta ? detallePorCuenta[selectedCuenta] : undefined
  const availableAccounts = useMemo(
    () => cuentas.filter((cuenta) => cuenta.nombreEstado !== "EnCaja"),
    [cuentas],
  )
  const assignedByOrderItem = useMemo(() => {
    const totals: Record<number, number> = {}
    Object.values(detallePorCuenta)
      .flat()
      .forEach((item) => {
        totals[item.idOrdenDetalle] = (totals[item.idOrdenDetalle] || 0) + item.cantidadAsignada
      })
    return totals
  }, [detallePorCuenta])

  const pendingItems = useMemo(
    () =>
      order.items
        .map((item) => {
          const assigned = assignedByOrderItem[item.id] || 0
          const remaining = Math.max(0, item.quantity - assigned)
          return {
            item,
            assigned,
            remaining,
          }
        })
        .filter((entry) => entry.remaining > 0),
    [order.items, assignedByOrderItem],
  )

  const selectedPendingItems = useMemo(
    () => pendingItems.filter((entry) => selectedItemIds.includes(entry.item.id)),
    [pendingItems, selectedItemIds],
  )

  const selectedPendingItem = selectedPendingItems[0] ?? null

  const selectedItemNameMap = useMemo(
    () => Object.fromEntries(order.items.map((item) => [item.id, item.name])) as Record<number, string>,
    [order.items],
  )

  const sharedSelectedQuantity = useMemo(() => {
    if (selectedItemIds.length === 0) return ""
    const values = selectedItemIds.map((id) => itemQuantities[id] ?? 1)
    return values.every((value) => value === values[0]) ? String(values[0]) : ""
  }, [itemQuantities, selectedItemIds])

  function getCuentaShortLabel(cuenta: OrdenCuenta) {
    const nombre = (cuenta.nombre || "").trim().toLowerCase()
    if (nombre.startsWith("persona ")) {
      const suffix = nombre.replace("persona ", "").trim()
      return suffix ? `P${suffix}` : `P${cuenta.numeroCuenta}`
    }
    return `C${cuenta.numeroCuenta}`
  }

  function clampItemQuantity(itemId: number, nextValue: number) {
    const item = pendingItems.find((candidate) => candidate.item.id === itemId)
    const maxQuantity = item?.remaining ?? 0
    return Math.max(0, Math.min(nextValue, maxQuantity))
  }

  function updateItemQuantity(itemId: number, nextValue: number) {
    setItemQuantities((current) => ({
      ...current,
      [itemId]: clampItemQuantity(itemId, nextValue),
    }))
  }

  function adjustItemQuantity(itemId: number, delta: number) {
    const currentValue = itemQuantities[itemId] || 0
    updateItemQuantity(itemId, currentValue + delta)
  }

  function toggleItemSelection(itemId: number) {
    setSelectedItemIds((current) => {
      if (current.includes(itemId)) {
        return current.filter((id) => id !== itemId)
      }
      setItemQuantities((quantities) => ({
        ...quantities,
        [itemId]: quantities[itemId] && quantities[itemId] > 0 ? quantities[itemId] : 1,
      }))
      return [...current, itemId]
    })
  }

  function adjustSelectedItems(delta: number) {
    setItemQuantities((current) => {
      const next = { ...current }
      selectedItemIds.forEach((itemId) => {
        const currentValue = next[itemId] ?? 1
        next[itemId] = clampItemQuantity(itemId, currentValue + delta)
      })
      return next
    })
  }

  function setSelectedItemsQuantity(nextValue: number) {
    setItemQuantities((current) => {
      const next = { ...current }
      selectedItemIds.forEach((itemId) => {
        next[itemId] = clampItemQuantity(itemId, nextValue)
      })
      return next
    })
  }

  function formatMoney(value: number) {
    return new Intl.NumberFormat("es-DO", {
      style: "currency",
      currency: "DOP",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value)
  }

  useEffect(() => {
    if (!itemMode) return
    const validIds = new Set(pendingItems.map((entry) => entry.item.id))
    setSelectedItemIds((current) => current.filter((id) => validIds.has(id)))
  }, [itemMode, pendingItems])

  async function loadCuentas(preferredCuentaId?: number | null) {
    setLoading(true)
    try {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts`), {
        credentials: "include",
        cache: "no-store",
      })
      const payload = (await response.json()) as AccountsResponse
      if (!payload.ok || !payload.data) {
        throw new Error(payload.message || "No fue posible cargar las subcuentas.")
      }

      setCuentas(payload.data)
      const detailEntries = await Promise.all(
        payload.data.map(async (cuenta) => [cuenta.idOrdenCuenta, await loadDetalleForCuenta(cuenta.idOrdenCuenta, false)] as const),
      )
      setDetallePorCuenta(
        Object.fromEntries(detailEntries.map(([idCuenta, detalle]) => [idCuenta, detalle ?? []])) as Record<number, OrdenCuentaDetalleItem[]>,
      )

      if (payload.data.length === 0) {
        setSelectedCuenta(null)
        return
      }

      const nextSelected =
        preferredCuentaId && payload.data.some((cuenta) => cuenta.idOrdenCuenta === preferredCuentaId)
          ? preferredCuentaId
          : payload.data[0].idOrdenCuenta

      setSelectedCuenta(nextSelected)
    } catch (error) {
      console.error("Error loading accounts:", error)
      toast.error(error instanceof Error ? error.message : "No fue posible cargar las subcuentas.")
    } finally {
      setLoading(false)
    }
  }

  async function loadDetalleForCuenta(idCuenta: number, updateState = true) {
    try {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/${idCuenta}/lines`), {
        credentials: "include",
        cache: "no-store",
      })
      const payload = (await response.json()) as DetailResponse
      if (!payload.ok || !payload.data) {
        throw new Error(payload.message || "No fue posible cargar el detalle de la subcuenta.")
      }

      if (updateState) {
        setDetallePorCuenta((current) => ({
          ...current,
          [idCuenta]: payload.data ?? [],
        }))
      }
      return payload.data ?? []
    } catch (error) {
      console.error("Error loading detail:", error)
      toast.error(error instanceof Error ? error.message : "No fue posible cargar el detalle de la subcuenta.")
      return []
    }
  }

  async function handleSelectCuenta(idCuenta: number) {
    setSelectedCuenta(idCuenta)
    if (!detallePorCuenta[idCuenta]) {
      await loadDetalleForCuenta(idCuenta)
    }
  }

  async function executeAction(action: () => Promise<void>) {
    if (isPending) return
    setIsPending(true)
    try {
      await action()
    } finally {
      setIsPending(false)
    }
  }

  async function handleDividirPorPersona() {
    await executeAction(async () => {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/split`), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ modo: "PERSONA" }),
      })
      const payload = (await response.json()) as { ok: boolean; message?: string }
      if (!payload.ok) {
        throw new Error(payload.message || "No fue posible dividir la orden por persona.")
      }

      setItemMode(false)
      setItemQuantities({})
      setSelectedItemIds([])
      await loadCuentas()
      toast.success("La orden se dividio por persona.")
    })
  }

  async function handleActivateItemMode() {
    if (availableAccounts.length === 0) {
      const createdId = await handleCrearCuenta(true)
      if (!createdId) return
    }
    setSelectedItemIds([])
    setItemMode(true)
  }

  function handleDividirEquitativa() {
    setShowEquitativaModal(true)
  }

  async function confirmEquitativa() {
    if (!equitativaCantidad || equitativaCantidad < 2) {
      toast.error("Ingresa un numero valido (minimo 2).")
      return
    }

    setShowEquitativaModal(false)
    await executeAction(async () => {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/split`), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ modo: "EQUITATIVA", cantidad: equitativaCantidad }),
      })
      const payload = (await response.json()) as { ok: boolean; message?: string }
      if (!payload.ok) {
        throw new Error(payload.message || "No fue posible dividir la orden equitativamente.")
      }

      setEquitativaCantidad(2)
      await loadCuentas()
      toast.success("La orden se dividio equitativamente.")
    })
  }

  async function assignSelectedItemToAccount(accountId: number) {
    if (selectedPendingItems.length === 0) {
      toast.error("Selecciona al menos un item pendiente.")
      return
    }
    const assignments: ItemAssignment[] = selectedPendingItems
      .map((entry) => ({ item: entry.item, qty: itemQuantities[entry.item.id] || 0 }))
      .filter((entry) => entry.qty > 0)

    if (assignments.length === 0) {
      toast.error("Indica una cantidad mayor que cero para los items seleccionados.")
      return
    }
    await executeAction(async () => {
      for (const assignment of assignments) {
        const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/${accountId}/lines`), {
          method: "POST",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            idOrdenDetalle: assignment.item.id,
            cantidadAsignada: assignment.qty,
          }),
        })
        const payload = (await response.json()) as { ok: boolean; message?: string }
        if (!payload.ok) {
          throw new Error(payload.message || `No fue posible asignar ${assignment.item.name}.`)
        }
      }

      setItemQuantities((current) => {
        const next = { ...current }
        assignments.forEach((assignment) => {
          next[assignment.item.id] = 0
        })
        return next
      })
      setSelectedItemIds([])
      await loadCuentas(accountId)
      toast.success(assignments.length === 1 ? `${assignments[0].item.name} fue asignado a la subcuenta.` : "Los items seleccionados fueron asignados a la subcuenta.")
    })
  }

  async function handleCrearCuenta(silent = false) {
    try {
      const nextNum = Math.max(...cuentas.map((cuenta) => cuenta.numeroCuenta), 0) + 1
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts`), {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ numeroCuenta: nextNum, nombre: `Cuenta ${nextNum}` }),
      })
      const payload = (await response.json()) as { ok: boolean; data?: { idOrdenCuenta?: number }; message?: string }
      if (!payload.ok) {
        throw new Error(payload.message || "No fue posible crear la subcuenta.")
      }

      const createdId = payload.data?.idOrdenCuenta ?? null
      await loadCuentas(createdId)
      if (!silent) {
        toast.success(`Se creo la Cuenta ${nextNum}.`)
      }
      return createdId
    } catch (error) {
      console.error("Error creating account:", error)
      toast.error(error instanceof Error ? error.message : "No fue posible crear la subcuenta.")
      return null
    }
  }

  async function handleEnviarACaja(idCuenta: number) {
    await executeAction(async () => {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/${idCuenta}/send-to-cash`), {
        method: "POST",
        credentials: "include",
      })
      const payload = (await response.json()) as { ok: boolean; message?: string }
      if (!payload.ok) {
        throw new Error(payload.message || "No fue posible enviar la subcuenta a caja.")
      }

      await loadCuentas(idCuenta)
      toast.success("La subcuenta fue enviada a caja.")
    })
  }

  async function handleVerPrefactura(idCuenta: number) {
    await executeAction(async () => {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/${idCuenta}/prefactura`), {
        credentials: "include",
        cache: "no-store",
      })
      const payload = (await response.json()) as PrefacturaResponse
      if (!payload.ok || !payload.data) {
        throw new Error(payload.message || "No fue posible cargar la pre-factura.")
      }

      setPrefacturaData(payload.data)
    })
  }

  async function handleResetSplit() {
    if (cuentas.some((cuenta) => cuenta.nombreEstado === "EnCaja")) {
      toast.error("No se puede empezar de cero mientras haya subcuentas enviadas a caja.")
      return
    }

    await executeAction(async () => {
      for (const cuenta of cuentas) {
        const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/${cuenta.idOrdenCuenta}`), {
          method: "DELETE",
          credentials: "include",
        })
        const payload = (await response.json()) as { ok: boolean; message?: string }
        if (!payload.ok) {
          throw new Error(payload.message || `No fue posible anular ${cuenta.nombre || `Cuenta ${cuenta.numeroCuenta}`}.`)
        }
      }

      setItemMode(false)
      setItemQuantities({})
      setSelectedItemIds([])
      setSelectedCuenta(null)
      setDetallePorCuenta({})
      await loadCuentas()
      toast.success("La division fue limpiada. Ya puedes empezar de cero.")
    })
  }

  async function handleUnassignDetalle(idCuenta: number, idOrdenCuentaDetalle: number, descripcion: string) {
    await executeAction(async () => {
      const response = await fetch(apiUrl(`/api/orders/${orderId}/accounts/${idCuenta}/lines`), {
        method: "DELETE",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ idOrdenCuentaDetalle }),
      })
      const payload = (await response.json()) as { ok: boolean; message?: string }
      if (!payload.ok) {
        throw new Error(payload.message || `No fue posible devolver ${descripcion}.`)
      }

      await loadCuentas(idCuenta)
      toast.success(`${descripcion} volvio a pendientes.`)
    })
  }

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="orders-split-panel" onClick={(event) => event.stopPropagation()}>
        <div className="orders-split-header">
          <h3>Division de Cuentas - Orden #{order.number}</h3>
          <div className="orders-split-header-actions">
            <div className="orders-split-actions orders-split-actions--header">
              <button className="secondary-button secondary-button--sm" onClick={() => void handleDividirPorPersona()} disabled={isPending}>
                Por persona
              </button>
              <button
                className={itemMode ? "primary-button primary-button--sm" : "secondary-button secondary-button--sm"}
                onClick={() => void handleActivateItemMode()}
                disabled={isPending}
              >
                Por item
              </button>
              <button className="secondary-button secondary-button--sm" onClick={handleDividirEquitativa} disabled={isPending}>
                Equitativa
              </button>
            </div>
            <button className="ghost-button ghost-button--sm" onClick={onClose}>
              x
            </button>
          </div>
        </div>

        <div className="orders-split-container">
          <div className="orders-split-left">
            <div className="orders-split-section-head">
              <h4>Items de la orden {itemMode ? "(Modo asignacion)" : ""}</h4>
              {itemMode ? (
                <div className="orders-split-toolbar">
                  <div className="orders-split-toolbar__summary">
                    {selectedItemIds.length > 0 ? `${selectedItemIds.length} seleccionados` : ""}
                  </div>
                </div>
              ) : null}
            </div>
            <div className="orders-split-items">
              {(itemMode ? pendingItems.map((entry) => entry.item) : order.items).map((item) => {
                return (
                <div key={item.id} className={`orders-split-item${itemMode ? " orders-split-item--assigning" : ""}`}>
                  {itemMode ? (
                    <>
                      <div className="orders-split-item-info">
                        <strong>{item.name}</strong>
                        <span className="orders-split-item-qty">
                          Pendiente x{pendingItems.find((entry) => entry.item.id === item.id)?.remaining ?? item.quantity}
                        </span>
                      </div>
                      <div className="orders-split-item-row-actions">
                        <div className="orders-split-qty-control orders-split-qty-control--row">
                          {[-10, -5, -1].map((delta) => (
                            <button
                              key={`row-minus-${item.id}-${delta}`}
                              type="button"
                              className="orders-split-step-btn orders-split-step-btn--minus"
                              onClick={() => {
                                if (!selectedItemIds.includes(item.id)) toggleItemSelection(item.id)
                                adjustItemQuantity(item.id, delta)
                              }}
                            >
                              {delta}
                            </button>
                          ))}
                          <input
                            className="orders-split-qty-input"
                            type="number"
                            min="0"
                            max={pendingItems.find((entry) => entry.item.id === item.id)?.remaining ?? item.quantity}
                            value={itemQuantities[item.id] || 0}
                            onFocus={() => {
                              if (!selectedItemIds.includes(item.id)) toggleItemSelection(item.id)
                            }}
                            onChange={(event) => updateItemQuantity(item.id, Number(event.target.value || 0))}
                            placeholder="0"
                          />
                          {[1, 5, 10].map((delta) => (
                            <button
                              key={`row-plus-${item.id}-${delta}`}
                              type="button"
                              className="orders-split-step-btn orders-split-step-btn--plus"
                              onClick={() => {
                                if (!selectedItemIds.includes(item.id)) toggleItemSelection(item.id)
                                adjustItemQuantity(item.id, delta)
                              }}
                            >
                              +{delta}
                            </button>
                          ))}
                        </div>
                        <button
                          type="button"
                          className={`orders-split-pending-select ${selectedPendingItems.some((entry) => entry.item.id === item.id) ? "orders-split-pending-select--active" : ""}`}
                          onClick={() => toggleItemSelection(item.id)}
                          title={selectedPendingItems.some((entry) => entry.item.id === item.id) ? "Quitar de la seleccion" : "Agregar a la seleccion"}
                          aria-label={selectedPendingItems.some((entry) => entry.item.id === item.id) ? "Quitar de la seleccion" : "Agregar a la seleccion"}
                        >
                        {selectedPendingItems.some((entry) => entry.item.id === item.id) ? (
                          <>
                            <Check size={12} />
                          </>
                        ) : (
                          <Circle size={12} />
                        )}
                      </button>
                      </div>
                    </>
                  ) : (
                    <>
                      <div className="orders-split-item-info">
                        <strong>{item.name}</strong>
                        <span className="orders-split-item-qty">x{item.quantity}</span>
                      </div>
                      <div className="orders-split-item-total">{formatMoney(item.total)}</div>
                    </>
                  )}
                </div>
                )
              })}
              {itemMode && pendingItems.length === 0 ? (
                <div className="orders-split-empty orders-split-empty--soft">
                  Todo esta asignado. Haz clic en un item dentro de una subcuenta para devolverlo a pendientes.
                </div>
              ) : null}
            </div>
            <div className="orders-split-total">
              <strong>Total: {formatMoney(order.total)}</strong>
            </div>
          </div>

          <div className="orders-split-right">
            <div className="orders-split-accounts">
              <div className="orders-split-accounts-head">
                <h4>Subcuentas</h4>
                <div className="orders-split-accounts-head-actions">
                  {itemMode ? (
                    <button className="primary-button primary-button--xs" onClick={() => void handleCrearCuenta()} disabled={isPending}>
                      <Plus size={14} /> Nueva
                    </button>
                  ) : null}
                  {cuentas.length > 0 ? (
                    <button
                      type="button"
                      className="ghost-button ghost-button--xs orders-split-reset-button"
                      onClick={() => setShowResetConfirm(true)}
                      disabled={isPending}
                    >
                      Limpiar todo
                    </button>
                  ) : null}
                </div>
              </div>
              {cuentas.length > 0 ? (
                <></>
              ) : null}
              {loading ? (
                <p className="orders-split-empty">Cargando subcuentas...</p>
              ) : cuentas.length === 0 ? (
                <p className="orders-split-empty">Sin subcuentas. Divide la orden para comenzar.</p>
              ) : (
                <div className="orders-split-account-list">
                  {cuentas.map((cuenta) => (
                    <div
                      key={cuenta.idOrdenCuenta}
                      className={`orders-split-account ${
                        selectedCuenta === cuenta.idOrdenCuenta ? "orders-split-account--selected" : ""
                      } ${cuenta.nombreEstado === "EnCaja" ? "orders-split-account--sent" : ""}`}
                      onClick={() => void handleSelectCuenta(cuenta.idOrdenCuenta)}
                    >
                      <div className="orders-split-account-header">
                        <div>
                          <strong>{cuenta.nombre || `Cuenta ${cuenta.numeroCuenta}`}</strong>
                          <span className="orders-split-account-status">{cuenta.nombreEstado}</span>
                        </div>
                        <div className="orders-split-account-total">{formatMoney(cuenta.total)}</div>
                      </div>
                      {itemMode || selectedCuenta === cuenta.idOrdenCuenta ? (
                        <div className="orders-split-account-actions">
                          {itemMode && cuenta.nombreEstado !== "EnCaja" ? (
                            <button
                              className="primary-button primary-button--xs"
                              onClick={(event) => {
                                event.stopPropagation()
                                void assignSelectedItemToAccount(cuenta.idOrdenCuenta)
                              }}
                              disabled={isPending || !selectedPendingItem || (itemQuantities[selectedPendingItem.item.id] || 0) <= 0}
                            >
                              <Check size={12} /> Asignar aqui
                            </button>
                          ) : null}
                          <button
                            className="ghost-button ghost-button--xs"
                            onClick={(event) => {
                              event.stopPropagation()
                              void handleVerPrefactura(cuenta.idOrdenCuenta)
                            }}
                          >
                            <Eye size={12} /> Pre-factura
                          </button>
                          {cuenta.nombreEstado !== "EnCaja" ? (
                            <button
                              className="secondary-button secondary-button--xs"
                              onClick={(event) => {
                                event.stopPropagation()
                                setSendToCashTarget(cuenta)
                              }}
                            >
                              Enviar a caja
                            </button>
                          ) : null}
                        </div>
                      ) : null}
                      {(detallePorCuenta[cuenta.idOrdenCuenta]?.length ?? 0) > 0 ? (
                        <div className="orders-split-account-detail-list">
                          {detallePorCuenta[cuenta.idOrdenCuenta].map((item) => (
                            <button
                              key={item.idOrdenCuentaDetalle}
                              type="button"
                              className={`orders-split-account-detail-row${itemMode ? " orders-split-account-detail-row--interactive" : ""}`}
                              onClick={
                                itemMode
                                  ? (event) => {
                                      event.stopPropagation()
                                      void handleUnassignDetalle(cuenta.idOrdenCuenta, item.idOrdenCuentaDetalle, item.descripcion)
                                    }
                                  : undefined
                              }
                              title={itemMode ? "Haz clic para devolver a pendientes" : undefined}
                            >
                              <span className="orders-split-account-detail-name">{selectedItemNameMap[item.idOrdenDetalle] || item.descripcion}</span>
                              <span className="orders-split-account-detail-qty">x{item.cantidadAsignada}</span>
                              <span className="orders-split-account-detail-total">{formatMoney(item.totalLinea)}</span>
                            </button>
                          ))}
                        </div>
                      ) : null}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {prefacturaData ? (
          <div className="modal-backdrop" onClick={() => setPrefacturaData(null)}>
            <div className="modal-card modal-card--md" onClick={(event) => event.stopPropagation()}>
              <div className="modal-card__header modal-card__header--brand">
                <div className="modal-card__header-icon">
                  <Check size={20} />
                </div>
                <div>
                  <h3 className="modal-card__title">Pre-factura</h3>
                  <p className="modal-card__subtitle">Cuenta #{prefacturaData.numeroCuenta}</p>
                </div>
              </div>
              <div className="modal-card__body">
                <div style={{ marginBottom: "12px" }}>
                  <p style={{ margin: "4px 0" }}>
                    <strong>Orden:</strong> {prefacturaData.numeroOrden}
                  </p>
                  {prefacturaData.referenciaCliente ? (
                    <p style={{ margin: "4px 0" }}>
                      <strong>Ref Cliente:</strong> {prefacturaData.referenciaCliente}
                    </p>
                  ) : null}
                  {prefacturaData.nombreMesa ? (
                    <p style={{ margin: "4px 0" }}>
                      <strong>Mesa:</strong> {prefacturaData.nombreMesa}
                    </p>
                  ) : null}
                </div>

                <div style={{ borderTop: "1px solid #ccc", paddingTop: "12px", marginBottom: "12px" }}>
                  <div className="orders-split-detail-items">
                    {prefacturaData.detalle.map((item) => (
                      <div key={`${item.codigo}-${item.descripcion}-${item.cantidadAsignada}`} className="orders-split-detail-item">
                        <span>{item.descripcion}</span>
                        <span className="orders-split-detail-qty">x{item.cantidadAsignada}</span>
                        <span>{formatMoney(item.totalLinea)}</span>
                      </div>
                    ))}
                  </div>
                </div>

                <div style={{ borderTop: "1px solid #ccc", paddingTop: "12px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
                    <span>Subtotal:</span>
                    <span>{formatMoney(prefacturaData.subtotal)}</span>
                  </div>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
                    <span>Impuesto:</span>
                    <span>{formatMoney(prefacturaData.impuesto)}</span>
                  </div>
                  {prefacturaData.descuento > 0 ? (
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
                      <span>Descuento:</span>
                      <span>-{formatMoney(prefacturaData.descuento)}</span>
                    </div>
                  ) : null}
                  {prefacturaData.propina > 0 ? (
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "4px" }}>
                      <span>Propina:</span>
                      <span>{formatMoney(prefacturaData.propina)}</span>
                    </div>
                  ) : null}
                  <div style={{ display: "flex", justifyContent: "space-between", borderTop: "1px solid #ddd", paddingTop: "8px" }}>
                    <strong>Total:</strong>
                    <strong>{formatMoney(prefacturaData.total)}</strong>
                  </div>
                </div>
              </div>
              <div className="modal-card__footer">
                <button className="secondary-button" onClick={() => setPrefacturaData(null)}>
                  Cerrar
                </button>
              </div>
            </div>
          </div>
        ) : null}

        {showEquitativaModal ? (
          <div className="modal-backdrop" onClick={() => setShowEquitativaModal(false)}>
            <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
              <div className="modal-card__header modal-card__header--brand">
                <div>
                  <h3 className="modal-card__title">Division Equitativa</h3>
                  <p className="modal-card__subtitle">Cuantas cuentas deseas crear?</p>
                </div>
              </div>
              <div className="modal-card__body">
                <input
                  type="number"
                  min="2"
                  value={equitativaCantidad}
                  onChange={(event) => setEquitativaCantidad(Number(event.target.value))}
                  style={{
                    width: "100%",
                    padding: "12px",
                    fontSize: "16px",
                    border: "1px solid var(--line)",
                    borderRadius: "var(--radius-sm)",
                    boxSizing: "border-box",
                  }}
                  autoFocus
                />
              </div>
              <div className="modal-card__footer">
                <button className="secondary-button" onClick={() => setShowEquitativaModal(false)}>
                  Cancelar
                </button>
                <button className="primary-button" onClick={() => void confirmEquitativa()} disabled={isPending}>
                  Dividir
                </button>
              </div>
            </div>
          </div>
        ) : null}

        {showResetConfirm ? (
          <div className="modal-backdrop" onClick={() => setShowResetConfirm(false)}>
            <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
              <div className="modal-card__header modal-card__header--brand">
                <div>
                  <h3 className="modal-card__title">Empezar de cero</h3>
                  <p className="modal-card__subtitle">Limpiar division actual</p>
                </div>
              </div>
              <div className="modal-card__body">
                <p className="modal-card__copy">
                  Esto eliminara todas las subcuentas abiertas y devolvera todos los items a pendientes.
                </p>
              </div>
              <div className="modal-card__footer">
                <button className="secondary-button" onClick={() => setShowResetConfirm(false)}>
                  Cancelar
                </button>
                <button
                  className="primary-button"
                  onClick={() => {
                    setShowResetConfirm(false)
                    void handleResetSplit()
                  }}
                  disabled={isPending}
                >
                  Aceptar
                </button>
              </div>
            </div>
          </div>
        ) : null}

        {sendToCashTarget ? (
          <div className="modal-backdrop" onClick={() => setSendToCashTarget(null)}>
            <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
              <div className="modal-card__header modal-card__header--brand">
                <div>
                  <h3 className="modal-card__title">Enviar a caja</h3>
                  <p className="modal-card__subtitle">{sendToCashTarget.nombre || `Cuenta ${sendToCashTarget.numeroCuenta}`}</p>
                </div>
              </div>
              <div className="modal-card__body">
                <p className="modal-card__copy">
                  Esta subcuenta quedara lista para caja y ya no podra modificarse desde ordenes.
                </p>
              </div>
              <div className="modal-card__footer">
                <button className="secondary-button" onClick={() => setSendToCashTarget(null)}>
                  Cancelar
                </button>
                <button
                  className="primary-button"
                  onClick={() => {
                    const target = sendToCashTarget
                    setSendToCashTarget(null)
                    if (target) {
                      void handleEnviarACaja(target.idOrdenCuenta)
                    }
                  }}
                  disabled={isPending}
                >
                  Aceptar
                </button>
              </div>
            </div>
          </div>
        ) : null}

        <div className="orders-split-footer">
          <button className="secondary-button" onClick={onClose}>
            Cerrar
          </button>
        </div>
      </div>
    </div>
  )
}
