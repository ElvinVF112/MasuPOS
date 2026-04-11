"use client"

import { useEffect, useMemo, useState } from "react"
import { BarChart3, Clock3, Layers3, Search, UserRound, UtensilsCrossed, Wallet, X } from "lucide-react"
import type { DiningRoomManagerData, ResourceBoardItem, ResourceStatus } from "@/lib/pos-data"

const statusStyles: Record<ResourceStatus, { chip: string; label: string; tone: string }> = {
  disponible: { chip: "chip chip--success", label: "Libre", tone: "available" },
  ocupada: { chip: "chip chip--info", label: "Ocupada", tone: "occupied" },
  pendiente: { chip: "chip chip--warning", label: "Pendiente", tone: "pending" },
  lista: { chip: "chip chip--violet", label: "Lista", tone: "ready" },
  pagando: { chip: "chip chip--rose", label: "Pagando", tone: "paying" },
}

type DiningRoomFloorViewProps = {
  data: DiningRoomManagerData
}

type VisualVariant = "square" | "round" | "lounge" | "bar"

function formatMoney(value: number, decimals = 2): string {
  return new Intl.NumberFormat("en-US", {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  }).format(value)
}

function getVisualVariant(resource: ResourceBoardItem): VisualVariant {
  if (resource.categoryShape === "square" || resource.categoryShape === "round" || resource.categoryShape === "lounge" || resource.categoryShape === "bar") {
    return resource.categoryShape
  }
  const signature = `${resource.category} ${resource.name} ${resource.area}`.toLowerCase()
  if (/(barra|counter|bar)/.test(signature)) return "bar"
  if (/(vip|booth|sofa|lounge)/.test(signature)) return "lounge"
  if (/(terraza|redonda|round|patio)/.test(signature)) return "round"
  if (resource.seats >= 6) return "bar"
  if (resource.seats <= 3) return "round"
  return "square"
}

export function DiningRoomFloorView({ data }: DiningRoomFloorViewProps) {
  const [selectedResourceId, setSelectedResourceId] = useState<number | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [areaFilter, setAreaFilter] = useState<string>("all")
  const [stateFilter, setStateFilter] = useState<string>("all")
  const [search, setSearch] = useState<string>("")

  const areaOptions = useMemo(() => {
    const areas = new Set(data.board.map((resource) => resource.area))
    return Array.from(areas).sort()
  }, [data.board])

  const quickStates = [
    { key: "all", label: "Todos" },
    { key: "free", label: "Libres" },
    { key: "occupied", label: "Ocupadas" },
    { key: "in_progress", label: "En proceso" },
  ]

  const filteredResources = useMemo(() => {
    return data.board.filter((resource) => {
      if (areaFilter !== "all" && resource.area !== areaFilter) return false
      if (stateFilter !== "all") {
        const stateMap: Record<string, ResourceStatus[]> = {
          free: ["disponible"],
          occupied: ["ocupada"],
          in_progress: ["pendiente", "lista", "pagando"],
        }
        const allowed = stateMap[stateFilter] || []
        if (!allowed.includes(resource.status)) return false
      }
      if (search) {
        const term = search.toLowerCase()
        return [resource.name, resource.area, resource.category, resource.orderNumber, resource.waiter]
          .filter(Boolean)
          .some((value) => String(value).toLowerCase().includes(term))
      }
      return true
    })
  }, [areaFilter, data.board, search, stateFilter])

  const resourcesByArea = useMemo(() => {
    const groups = new Map<string, ResourceBoardItem[]>()
    filteredResources.forEach((resource) => {
      const list = groups.get(resource.area) || []
      list.push(resource)
      groups.set(resource.area, list)
    })
    return Array.from(groups.entries())
      .map(([area, resources]) => ({ area, resources }))
      .sort((a, b) => a.area.localeCompare(b.area))
  }, [filteredResources])

  const boardSummary = useMemo(() => {
    const occupied = filteredResources.filter((resource) => resource.status !== "disponible").length
    const totalOpen = filteredResources.reduce((acc, resource) => acc + (resource.total ?? 0), 0)
    const activeOrders = filteredResources.filter((resource) => resource.orderId).length
    return {
      visible: filteredResources.length,
      occupied,
      free: filteredResources.length - occupied,
      activeOrders,
      totalOpen,
      occupancyRate: filteredResources.length ? Math.round((occupied / filteredResources.length) * 100) : 0,
    }
  }, [filteredResources])

  const selectedResource = useMemo(
    () => data.board.find((resource) => resource.id === selectedResourceId) ?? null,
    [data.board, selectedResourceId],
  )

  useEffect(() => {
    if (!filteredResources.length) {
      setSelectedResourceId(null)
      setIsDetailOpen(false)
      return
    }

    if (!selectedResourceId || !filteredResources.some((resource) => resource.id === selectedResourceId)) {
      setSelectedResourceId(filteredResources[0].id)
    }
  }, [filteredResources, selectedResourceId])

  const selectedCategory = selectedResource
    ? data.lookups.resourceCategories.find((item) => item.name === selectedResource.category && item.area === selectedResource.area)
    : null

  return (
    <section className="orders-layout orders-layout--redesign salon-plan-layout">
      <div className="orders-workspace salon-plan-workspace salon-plan-workspace--single">
        <section className="data-panel salon-plan__surface">
          <div className="salon-summary-strip salon-summary-strip--compact salon-summary-strip--top">
            <article className="salon-summary-pill">
              <span className="salon-summary-pill__icon"><BarChart3 size={15} /></span>
              <div>
                <strong>{boardSummary.occupancyRate}%</strong>
                <span>Ocupacion</span>
              </div>
            </article>
            <article className="salon-summary-pill">
              <span className="salon-summary-pill__icon"><Layers3 size={15} /></span>
              <div>
                <strong>{boardSummary.activeOrders}</strong>
                <span>Ordenes activas</span>
              </div>
            </article>
            <article className="salon-summary-pill">
              <span className="salon-summary-pill__icon"><Clock3 size={15} /></span>
              <div>
                <strong>{boardSummary.occupied}</strong>
                <span>Mesas ocupadas</span>
              </div>
            </article>
            <article className="salon-summary-pill">
              <span className="salon-summary-pill__icon"><UtensilsCrossed size={15} /></span>
              <div>
                <strong>RD$ {formatMoney(boardSummary.totalOpen)}</strong>
                <span>Total abierto</span>
              </div>
            </article>
          </div>

          <div className="salon-plan__controls">
            <div className="salon-plan__quickbar">
              <div className="salon-plan__quickbar-group">
                <span>Vista rapida</span>
                <div className="salon-plan__quickbar-actions">
                  {quickStates.map((item) => (
                    <button
                      key={item.key}
                      type="button"
                      className={`salon-quick-filter${stateFilter === item.key ? " is-active" : ""}`}
                      onClick={() => setStateFilter(item.key)}
                    >
                      {item.label}
                    </button>
                  ))}
                </div>
              </div>
              <div className="salon-plan__quickbar-group">
                <span>Areas</span>
                <div className="salon-plan__quickbar-actions">
                  <button type="button" className={`salon-quick-filter${areaFilter === "all" ? " is-active" : ""}`} onClick={() => setAreaFilter("all")}>
                    Todas
                  </button>
                  {areaOptions.map((area) => (
                    <button key={area} type="button" className={`salon-quick-filter${areaFilter === area ? " is-active" : ""}`} onClick={() => setAreaFilter(area)}>
                      {area}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            <div className="salon-plan__filters orders-filters">
              <label className="orders-filter-field orders-filter-field--search">
                <span>Buscar</span>
                <div className="orders-search-input">
                  <Search size={16} />
                  <input
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Mesa, area, categoria o usuario"
                  />
                </div>
              </label>
            </div>
          </div>

          <div className="salon-plan__board">
            {resourcesByArea.length ? (
              resourcesByArea.map((group) => {
                const occupied = group.resources.filter((resource) => resource.status !== "disponible").length
                return (
                  <section key={group.area} className="salon-plan-zone">
                    <header className="salon-plan-zone__header">
                      <div>
                        <h3>{group.area}</h3>
                        <p>{occupied} ocupadas - {group.resources.length - occupied} libres</p>
                      </div>
                      <span>{group.resources.length} mesas</span>
                    </header>
                    <div className="salon-plan-zone__grid">
                      {group.resources.map((resource, index) => {
                        const isSelected = selectedResourceId === resource.id
                        const status = statusStyles[resource.status]
                        const variant = getVisualVariant(resource)
                        const category = data.lookups.resourceCategories.find((item) => item.name === resource.category && item.area === resource.area)
                        return (
                          <button
                            key={resource.id}
                            type="button"
                            className={`salon-resource-seat salon-resource-seat--${variant} salon-resource-seat--${status.tone}${isSelected ? " is-selected" : ""}`}
                            onClick={() => {
                              setSelectedResourceId(resource.id)
                              setIsDetailOpen(true)
                            }}
                            style={{ ["--salon-category-color" as string]: category?.color ?? resource.categoryColor ?? "#3b82f6" }}
                          >
                            <div className="salon-resource-seat__visual" aria-hidden="true">
                              {Array.from({ length: Math.max(1, Math.min(resource.seats, 10)) }).map((_, chairIndex) => {
                                const chairClass =
                                  chairIndex % 4 === 0 ? "chair--top" : chairIndex % 4 === 1 ? "chair--right" : chairIndex % 4 === 2 ? "chair--bottom" : "chair--left"
                                const offsetClass = chairIndex >= 4 ? " is-offset" : ""
                                return <span key={`${resource.id}-${chairIndex}`} className={`salon-resource-seat__chair ${chairClass}${offsetClass}`} />
                              })}
                              <span className="salon-resource-seat__table" />
                            </div>
                            <div className="salon-resource-seat__info">
                              <strong>{resource.name}</strong>
                              <span>{status.label}</span>
                              <span>{resource.seats} sillas</span>
                              <small>{resource.orderId ? `RD$ ${formatMoney(resource.total ?? 0)}` : "Sin consumo"}</small>
                            </div>
                          </button>
                        )
                      })}
                    </div>
                  </section>
                )
              })
            ) : (
              <div className="detail-empty detail-empty--compact">
                <UtensilsCrossed size={26} />
                <h3>Sin resultados</h3>
                <p>No hay recursos que coincidan con los filtros actuales.</p>
              </div>
            )}
          </div>
        </section>
      </div>

      {selectedResource && isDetailOpen ? (
        <>
          <button
            type="button"
            className="orders-drawer-backdrop"
            aria-label="Cerrar detalle"
            onClick={() => setIsDetailOpen(false)}
          />
          <aside className="orders-drawer salon-drawer" aria-label="Detalle del recurso">
            <div className="orders-drawer__header">
              <div>
                <h3>{selectedResource.name}</h3>
                <p>{selectedResource.area} - {selectedResource.category}</p>
              </div>
              <div className="orders-drawer__header-actions">
                <span className={statusStyles[selectedResource.status].chip}>{statusStyles[selectedResource.status].label}</span>
                <button type="button" className="ghost-icon-button" onClick={() => setIsDetailOpen(false)} aria-label="Cerrar">
                  <X size={18} />
                </button>
              </div>
            </div>

            <div
              className={`salon-resource-seat salon-resource-seat--hero salon-resource-seat--${getVisualVariant(selectedResource)} salon-resource-seat--${statusStyles[selectedResource.status].tone}`}
              style={{ ["--salon-category-color" as string]: selectedCategory?.color ?? selectedResource.categoryColor ?? "#3b82f6" }}
            >
              <div className="salon-resource-seat__visual" aria-hidden="true">
                {Array.from({ length: Math.max(1, Math.min(selectedResource.seats, 10)) }).map((_, chairIndex) => {
                  const chairClass =
                    chairIndex % 4 === 0 ? "chair--top" : chairIndex % 4 === 1 ? "chair--right" : chairIndex % 4 === 2 ? "chair--bottom" : "chair--left"
                  const offsetClass = chairIndex >= 4 ? " is-offset" : ""
                  return <span key={`${selectedResource.id}-hero-${chairIndex}`} className={`salon-resource-seat__chair ${chairClass}${offsetClass}`} />
                })}
                <span className="salon-resource-seat__table" />
              </div>
              <div className="salon-resource-seat__info">
                <strong>{selectedResource.name}</strong>
                <span>{selectedResource.resourceState}</span>
                <small>{selectedResource.orderNumber ?? "Sin orden activa"}</small>
              </div>
            </div>

            <div className="salon-detail-card salon-detail-card--visual">
              <div className="salon-detail-card__headline">
                <div className="salon-detail-card__headline-copy">
                  <span>Resumen ejecutivo</span>
                  <strong>{selectedResource.orderId ? "Mesa con actividad" : "Mesa sin consumo"}</strong>
                </div>
                <div className="salon-detail-card__headline-total">
                  <span>Total abierto</span>
                  <strong>{selectedResource.orderId ? `RD$ ${formatMoney(selectedResource.total ?? 0)}` : "RD$ 0.00"}</strong>
                </div>
              </div>

              <div className="salon-detail-card__stats">
                <article className="salon-detail-card__stat">
                  <span>Orden activa</span>
                  <strong>{selectedResource.orderNumber ?? "Sin orden activa"}</strong>
                </article>
                <article className="salon-detail-card__stat">
                  <span>Items cargados</span>
                  <strong>{selectedResource.items.length}</strong>
                </article>
                <article className="salon-detail-card__stat">
                  <span>Camarero</span>
                  <strong>{selectedResource.waiter ?? "No asignado"}</strong>
                </article>
                <article className="salon-detail-card__stat">
                  <span>Capacidad</span>
                  <strong>{selectedResource.seats}</strong>
                </article>
                <article className="salon-detail-card__stat">
                  <span>Hora</span>
                  <strong>{selectedResource.time ?? "-"}</strong>
                </article>
                <article className="salon-detail-card__stat">
                  <span>Estado orden</span>
                  <strong>{selectedResource.orderState ?? "Sin actividad"}</strong>
                </article>
              </div>

              <div className="salon-detail-card__summary">
                <div>
                  <span>Estado del recurso</span>
                  <strong>{selectedResource.resourceState}</strong>
                </div>
                <div>
                  <span>Categoria</span>
                  <strong>{selectedResource.category}</strong>
                </div>
                <div>
                  <span>Lectura rapida</span>
                  <strong>{selectedResource.items.length ? `${selectedResource.items.length} items en mesa` : "Sin consumo"}</strong>
                </div>
                <div>
                  <span>Area</span>
                  <strong>{selectedResource.area}</strong>
                </div>
              </div>

              <div className="salon-detail-card__note">
                <Wallet size={15} />
                <p>
                  Vista de monitoreo del salon. Para operar o editar una orden, continua en <strong>Ordenes</strong>.
                </p>
              </div>
            </div>
          </aside>
        </>
      ) : null}
    </section>
  )
}
