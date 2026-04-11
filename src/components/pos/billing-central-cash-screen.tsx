"use client"

import { AlertTriangle, ArrowRightLeft, Banknote, CreditCard, RefreshCw, Store, Undo2, User, Wallet, X, XCircle } from "lucide-react"
import { useMemo, useState } from "react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"

type CashStatus = "Pendiente" | "Prefactura" | "Lista para cobro" | "Devuelta" | "Anulada"

type LineItem = {
  item: string
  qty: string
  price: string
  amount: string
}

type CentralCashAccount = {
  id: number
  document: string
  customer: string
  docType: string
  amount: string
  date: string
  time: string
  status: CashStatus
  createdBy: string
  comment: string
  mesa: string
  waiter: string
  items: number
  subtotal: string
  itbis: string
  legalTip: string
  discount: string
  total: string
  note: string
  lines: LineItem[]
  payments: Array<{ label: string; amount: string; icon: "cash" | "card" | "transfer" }>
}

const INITIAL_ACCOUNTS: CentralCashAccount[] = [
  {
    id: 1,
    document: "FAC-000021",
    customer: "Consumidor final",
    docType: "Factura contado",
    amount: "RD$ 1,587.20",
    date: "08/04/2026",
    time: "08:45 PM",
    status: "Pendiente",
    createdBy: "Alicia Ramirez",
    comment: "Cuenta enviada desde Facturacion para revision final.",
    mesa: "MESA-04",
    waiter: "Alicia Ramirez",
    items: 6,
    subtotal: "RD$ 1,240.00",
    itbis: "RD$ 223.20",
    legalTip: "RD$ 124.00",
    discount: "RD$ 0.00",
    total: "RD$ 1,587.20",
    note: "Cliente en mesa. Solo falta confirmar forma de pago.",
    lines: [
      { item: "Cappuccino", qty: "2", price: "RD$ 155.00", amount: "RD$ 310.00" },
      { item: "Brownie con Helado", qty: "1", price: "RD$ 225.00", amount: "RD$ 225.00" },
      { item: "Limonada Frozen", qty: "2", price: "RD$ 145.00", amount: "RD$ 290.00" },
      { item: "Hamburguesa Clasica", qty: "2", price: "RD$ 330.00", amount: "RD$ 660.00" },
    ],
    payments: [
      { label: "Efectivo", amount: "RD$ 0.00", icon: "cash" },
      { label: "Tarjeta", amount: "RD$ 0.00", icon: "card" },
      { label: "Transferencia", amount: "RD$ 0.00", icon: "transfer" },
    ],
  },
  {
    id: 2,
    document: "FAC-000022",
    customer: "Jose Perez",
    docType: "Factura fiscal",
    amount: "RD$ 922.60",
    date: "08/04/2026",
    time: "08:51 PM",
    status: "Prefactura",
    createdBy: "Administrador General",
    comment: "Take out. Requiere NCF y referencia de pago.",
    mesa: "TAKE-OUT",
    waiter: "Administrador General",
    items: 4,
    subtotal: "RD$ 820.00",
    itbis: "RD$ 147.60",
    legalTip: "RD$ 0.00",
    discount: "RD$ 45.00",
    total: "RD$ 922.60",
    note: "Take out sin propina legal. Documento listo para convertir a cobro.",
    lines: [
      { item: "Agua 500ml", qty: "2", price: "RD$ 45.00", amount: "RD$ 90.00" },
      { item: "Cafe Espresso", qty: "2", price: "RD$ 120.00", amount: "RD$ 240.00" },
      { item: "Wrap de Pollo", qty: "1", price: "RD$ 290.00", amount: "RD$ 290.00" },
      { item: "Brownie", qty: "1", price: "RD$ 200.00", amount: "RD$ 200.00" },
    ],
    payments: [
      { label: "Efectivo", amount: "RD$ 0.00", icon: "cash" },
      { label: "Tarjeta", amount: "RD$ 0.00", icon: "card" },
      { label: "Transferencia", amount: "RD$ 0.00", icon: "transfer" },
    ],
  },
  {
    id: 3,
    document: "FAC-000023",
    customer: "Mariela Gomez",
    docType: "Factura contado",
    amount: "RD$ 2,946.40",
    date: "08/04/2026",
    time: "09:03 PM",
    status: "Lista para cobro",
    createdBy: "Carlos Diaz",
    comment: "Cliente lista para pagar mixto: tarjeta + efectivo.",
    mesa: "MESA-09",
    waiter: "Carlos Diaz",
    items: 9,
    subtotal: "RD$ 2,380.00",
    itbis: "RD$ 428.40",
    legalTip: "RD$ 238.00",
    discount: "RD$ 100.00",
    total: "RD$ 2,946.40",
    note: "Cuenta lista para cerrar. Falta aplicar forma de pago mixta.",
    lines: [
      { item: "Mojito Clasico", qty: "3", price: "RD$ 280.00", amount: "RD$ 840.00" },
      { item: "Picadera Mixta", qty: "1", price: "RD$ 780.00", amount: "RD$ 780.00" },
      { item: "Agua con Gas", qty: "2", price: "RD$ 85.00", amount: "RD$ 170.00" },
      { item: "Brownie con Helado", qty: "2", price: "RD$ 225.00", amount: "RD$ 450.00" },
    ],
    payments: [
      { label: "Efectivo", amount: "RD$ 900.00", icon: "cash" },
      { label: "Tarjeta", amount: "RD$ 2,046.40", icon: "card" },
      { label: "Transferencia", amount: "RD$ 0.00", icon: "transfer" },
    ],
  },
]

function statusClassName(status: CashStatus) {
  switch (status) {
    case "Pendiente":
      return "billing-central__status billing-central__status--pending"
    case "Prefactura":
      return "billing-central__status billing-central__status--prefactura"
    case "Lista para cobro":
      return "billing-central__status billing-central__status--ready"
    case "Devuelta":
      return "billing-central__status billing-central__status--returned"
    case "Anulada":
      return "billing-central__status billing-central__status--annulled"
    default:
      return "billing-central__status"
  }
}

function paymentIcon(type: "cash" | "card" | "transfer") {
  switch (type) {
    case "cash":
      return Banknote
    case "card":
      return CreditCard
    default:
      return Wallet
  }
}

export function BillingCentralCashScreen() {
  const router = useRouter()
  const [accounts, setAccounts] = useState<CentralCashAccount[]>(INITIAL_ACCOUNTS)
  const [selectedId, setSelectedId] = useState<number>(INITIAL_ACCOUNTS[0].id)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [paymentOpen, setPaymentOpen] = useState(false)
  const [returnOpen, setReturnOpen] = useState(false)
  const [annulOpen, setAnnulOpen] = useState(false)

  const visibleAccounts = useMemo(
    () => accounts.filter((account) => account.status === "Pendiente" || account.status === "Prefactura" || account.status === "Lista para cobro"),
    [accounts],
  )

  const selected = useMemo(() => {
    const current = visibleAccounts.find((account) => account.id === selectedId)
    return current ?? visibleAccounts[0] ?? accounts[0] ?? null
  }, [accounts, selectedId, visibleAccounts])

  function updateSelectedStatus(nextStatus: CashStatus, successTitle: string, successDesc: string) {
    if (!selected) return
    setAccounts((current) => current.map((account) => account.id === selected.id ? { ...account, status: nextStatus } : account))
    toast.success(successTitle, { description: successDesc })
  }

  return (
    <section className="content-page billing-central">
      <div className="billing-central__toolbar">
        <button type="button" className="secondary-button" onClick={() => toast.success("Bandeja actualizada", { description: "Se recargo la lista de pendientes de cobro." })}>
          <RefreshCw size={16} /> Actualizar
        </button>
        <button type="button" className="secondary-button" onClick={() => router.push("/facturacion/punto-de-ventas")}>
          <Store size={16} /> Punto de Ventas
        </button>
      </div>

      <section className="billing-central__panel billing-central__panel--grid">
        <div className="billing-central__table-wrap">
          <table className="billing-central__table">
            <thead>
              <tr>
                <th>Documento</th>
                <th>Cliente</th>
                <th>Tipo comprobante</th>
                <th>Valor</th>
                <th>Fecha-Hora</th>
                <th>Creado por</th>
                <th>Comentario</th>
              </tr>
            </thead>
            <tbody>
              {visibleAccounts.map((account) => (
                <tr
                  key={account.id}
                  className={selected?.id === account.id ? "is-selected" : ""}
                  onClick={() => {
                    setSelectedId(account.id)
                    setIsDetailOpen(true)
                  }}
                >
                  <td>{account.document}</td>
                  <td>{account.customer}</td>
                  <td>{account.docType}</td>
                  <td>{account.amount}</td>
                  <td>{account.date} - {account.time}</td>
                  <td>{account.createdBy}</td>
                  <td>{account.comment}</td>
                </tr>
              ))}
              {visibleAccounts.length === 0 ? (
                <tr>
                  <td colSpan={7}><div className="billing-central__empty">No hay documentos en esta bandeja.</div></td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </section>

      {selected && isDetailOpen ? (
        <>
          <button
            type="button"
            className="orders-drawer-backdrop"
            aria-label="Cerrar detalle"
            onClick={() => setIsDetailOpen(false)}
          />
          <aside className="orders-drawer" aria-label="Detalle de caja central">
            <div className="orders-drawer__header">
              <div>
                <h3>{selected.document}</h3>
                <p>{selected.customer} - {selected.mesa}</p>
              </div>
              <div className="orders-drawer__header-actions">
                <span className={statusClassName(selected.status)}>{selected.status}</span>
                <button className="ghost-button ghost-button--xs" type="button" onClick={() => setIsDetailOpen(false)}>
                  <X size={14} />
                </button>
              </div>
            </div>

            <section className="orders-detail-card">
              <div className="orders-detail-card__row">
                <span>Documento</span>
                <strong>{selected.docType}</strong>
              </div>
              <div className="orders-detail-card__row">
                <span>Enviado</span>
                <strong>{selected.date} - {selected.time}</strong>
              </div>
              <div className="orders-detail-card__row">
                <span>Creado por</span>
                <strong>{selected.createdBy}</strong>
              </div>
              <div className="orders-detail-card__row">
                <span>Comentario</span>
                <strong>{selected.comment || "Sin comentario"}</strong>
              </div>
            </section>

            <section className="orders-detail-lines">
              <div className="orders-detail-lines__header">
                <h3>Articulos</h3>
              </div>
              <div className="billing-central__document">
                <div className="billing-central__document-head">
                  <span>Articulo</span>
                  <span>Cant.</span>
                  <span>Precio</span>
                  <span>Importe</span>
                </div>
                {selected.lines.map((line) => (
                  <div key={`${selected.id}-${line.item}`} className="billing-central__document-row">
                    <span>{line.item}</span>
                    <span>{line.qty}</span>
                    <span>{line.price}</span>
                    <strong>{line.amount}</strong>
                  </div>
                ))}
              </div>
            </section>

            <section className="orders-detail-actions billing-central__drawer-actions">
              <button
                className="primary-button billing-central__drawer-button billing-central__drawer-button--primary"
                type="button"
                onClick={() => setPaymentOpen(true)}
                disabled={selected.status === "Anulada" || selected.status === "Devuelta"}
              >
                <CreditCard size={16} />
                Cobrar
              </button>
              <button
                className="secondary-button billing-central__drawer-button billing-central__drawer-button--secondary"
                type="button"
                onClick={() => setReturnOpen(true)}
                disabled={selected.status === "Devuelta" || selected.status === "Anulada"}
              >
                <ArrowRightLeft size={16} />
                Retornar
              </button>
              <button
                className="ghost-button billing-central__drawer-button billing-central__drawer-button--danger"
                type="button"
                onClick={() => setAnnulOpen(true)}
                disabled={selected.status === "Anulada"}
              >
                <XCircle size={16} />
                Anular
              </button>
            </section>
          </aside>
        </>
      ) : null}

      {paymentOpen && selected ? (
        <div className="modal-backdrop" onClick={() => setPaymentOpen(false)}>
          <div className="modal-card modal-card--lg" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon"><CreditCard size={18} /></div>
              <div>
                <h3 className="modal-card__title">Cobrar documento</h3>
                <p className="modal-card__subtitle">{selected.document}</p>
              </div>
            </div>
            <div className="modal-card__body billing-central__payment-modal">
              <div className="billing-central__payment-summary">
                <strong>{selected.customer}</strong>
                <span>{selected.docType}</span>
                <div className="billing-central__payment-total">{selected.total}</div>
              </div>
              <div className="billing-central__payment-methods">
                <h3>Formas de pago</h3>
                {selected.payments.map((method) => {
                  const Icon = paymentIcon(method.icon)
                  return (
                    <div key={method.label} className="billing-central__payment-method">
                      <div>
                        <span><Icon size={15} /> {method.label}</span>
                        <small>Monto aplicado</small>
                      </div>
                      <strong>{method.amount}</strong>
                    </div>
                  )
                })}
              </div>
              <div className="billing-central__payment-hints">
                <p>Preparado para pagos simples, mixtos y multimoneda.</p>
                <p>Aqui luego conectaremos referencia, autorizacion, vuelto y conversiones.</p>
              </div>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setPaymentOpen(false)}>Cancelar</button>
              <button
                type="button"
                className="primary-button"
                onClick={() => {
                  updateSelectedStatus("Lista para cobro", "Cobro preparado", "La cuenta quedo lista para finalizar el pago desde Caja Central.")
                  setPaymentOpen(false)
                }}
              >
                Finalizar cobro
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {returnOpen && selected ? (
        <div className="modal-backdrop" onClick={() => setReturnOpen(false)}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon"><Undo2 size={18} /></div>
              <div>
                <h3 className="modal-card__title">Retornar a Facturacion</h3>
                <p className="modal-card__subtitle">{selected.document}</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>La pre-factura volvera a Facturacion para correccion. Luego podremos mostrarla en una bandeja de devueltas.</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setReturnOpen(false)}>Cancelar</button>
              <button
                type="button"
                className="primary-button"
                onClick={() => {
                  updateSelectedStatus("Devuelta", "Documento devuelto", "La cuenta quedo marcada para correccion en Facturacion.")
                  setReturnOpen(false)
                }}
              >
                Retornar
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {annulOpen && selected ? (
        <div className="modal-backdrop" onClick={() => setAnnulOpen(false)}>
          <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon"><AlertTriangle size={18} /></div>
              <div>
                <h3 className="modal-card__title">Anular operacion</h3>
                <p className="modal-card__subtitle">{selected.document}</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>Esta accion debe pedir motivo y dejar trazabilidad. En este primer corte la cuenta quedara marcada como anulada.</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={() => setAnnulOpen(false)}>Cancelar</button>
              <button
                type="button"
                className="danger-button"
                onClick={() => {
                  updateSelectedStatus("Anulada", "Operacion anulada", "La cuenta quedo anulada en Caja Central.")
                  setAnnulOpen(false)
                }}
              >
                Anular
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </section>
  )
}
