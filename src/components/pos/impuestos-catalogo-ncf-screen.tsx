"use client"

import { useEffect, useMemo, useState, useTransition } from "react"
import { FileCheck, Loader2, Pencil, Save, Search, X, Zap } from "lucide-react"
import { toast } from "sonner"
import { apiUrl } from "@/lib/client-config"
import { useI18n } from "@/lib/i18n"
import type { CatalogoNCFRecord } from "@/lib/pos-data"

type Form = {
  id: number
  nombreInterno: string
  active: boolean
}

export function ImpuestosCatalogoNCFScreen({ initialData }: { initialData: CatalogoNCFRecord[] }) {
  const { t } = useI18n()
  const [items, setItems] = useState<CatalogoNCFRecord[]>(initialData)
  const [query, setQuery] = useState("")
  const [filterElectronico, setFilterElectronico] = useState<"all" | "fisico" | "electronico">("all")
  const [selectedId, setSelectedId] = useState<number | null>(initialData[0]?.id ?? null)
  const [form, setForm] = useState<Form | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [isPending, startTransition] = useTransition()

  const filteredItems = useMemo(() => {
    let list = items
    if (filterElectronico === "fisico") list = list.filter((i) => !i.esElectronico)
    if (filterElectronico === "electronico") list = list.filter((i) => i.esElectronico)
    const q = query.toLowerCase().trim()
    if (q) list = list.filter((i) => i.codigo.toLowerCase().includes(q) || i.nombre.toLowerCase().includes(q) || (i.nombreInterno || "").toLowerCase().includes(q))
    return list
  }, [items, query, filterElectronico])

  const selected = useMemo(() => items.find((i) => i.id === selectedId) ?? null, [items, selectedId])

  useEffect(() => {
    if (selected) {
      setForm({ id: selected.id, nombreInterno: selected.nombreInterno || "", active: selected.active })
    }
  }, [selected])

  function selectItem(id: number) {
    setSelectedId(id)
    setIsEditing(false)
  }

  function openEdit() {
    if (!selected) return
    setForm({ id: selected.id, nombreInterno: selected.nombreInterno || "", active: selected.active })
    setIsEditing(true)
  }

  function cancelEdit() {
    if (selected) setForm({ id: selected.id, nombreInterno: selected.nombreInterno || "", active: selected.active })
    setIsEditing(false)
  }

  async function onSave() {
    if (!form) return
    startTransition(async () => {
      try {
        const response = await fetch(`${apiUrl("/api/config/impuestos/tipos-comprobantes")}/${form.id}`, {
          method: "PUT",
          credentials: "include",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ nombreInterno: form.nombreInterno || null, active: form.active }),
        })
        const result = (await response.json()) as { ok: boolean; message?: string; data?: CatalogoNCFRecord }
        if (!response.ok || !result.ok) { toast.error(result.message ?? "No se pudo guardar."); return }

        toast.success("Tipo de comprobante actualizado")
        setItems((prev) => prev.map((i) => (i.id === form.id ? result.data! : i)))
        setIsEditing(false)
      } catch {
        toast.error("Error al guardar.")
      }
    })
  }

  const flagBadge = (label: string, value: boolean) => (
    <span
      style={{
        display: "inline-flex", alignItems: "center", gap: "0.25rem",
        padding: "0.15rem 0.5rem", borderRadius: "4px", fontSize: "0.7rem", fontWeight: 600,
        background: value ? "#d1fae5" : "#fee2e2",
        color: value ? "#065f46" : "#991b1b",
        opacity: value ? 1 : 0.75,
      }}
    >
      {label}
    </span>
  )

  return (
    <section className="data-panel">
      <div className="price-lists-layout">
        {/* Sidebar */}
        <aside className="price-lists-sidebar">
          <div className="price-lists-sidebar__header">
            <div className="price-lists-sidebar__title">
              <FileCheck size={17} />
              <h2>Tipos de Comprobante</h2>
            </div>
          </div>

          {/* Filtro tipo */}
          <div style={{ display: "flex", gap: "0.35rem", padding: "0.5rem 0.75rem 0" }}>
            {(["all", "fisico", "electronico"] as const).map((f) => (
              <button
                key={f}
                type="button"
                onClick={() => setFilterElectronico(f)}
                style={{
                  flex: 1, fontSize: "0.68rem", padding: "0.25rem 0.3rem", borderRadius: "4px", border: "1px solid var(--border)",
                  background: filterElectronico === f ? "var(--brand)" : "transparent",
                  color: filterElectronico === f ? "#fff" : "var(--text-muted)",
                  cursor: "pointer", fontWeight: filterElectronico === f ? 600 : 400,
                }}
              >
                {f === "all" ? "Todos" : f === "fisico" ? "Físicos" : "e-CF"}
              </button>
            ))}
          </div>

          <div className="price-lists-sidebar__search">
            <Search size={13} className="price-lists-sidebar__search-icon" />
            <input
              type="text"
              placeholder="Buscar código o nombre..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>

          <div className="price-lists-sidebar__list">
            {filteredItems.map((item) => (
              <div
                key={item.id}
                className={`price-lists-sidebar__item${selectedId === item.id ? " is-selected" : ""}${!item.active ? " is-disabled" : ""}`}
                onClick={() => selectItem(item.id)}
              >
                <div className="price-lists-sidebar__item-top">
                  <span className={`price-lists-badge${item.active ? " is-active" : " is-inactive"}`}>
                    {item.active ? t("common.active") : t("common.inactive")}
                  </span>
                  {item.esElectronico && (
                    <span style={{ display: "flex", alignItems: "center", gap: "0.2rem", fontSize: "0.68rem", color: "var(--brand)", fontWeight: 600 }}>
                      <Zap size={10} /> e-CF
                    </span>
                  )}
                </div>
                <p className="price-lists-sidebar__desc">
                  <strong>{item.codigo}</strong> — {item.nombreInterno || item.nombre}
                </p>
              </div>
            ))}
          </div>
        </aside>

        {/* Detail */}
        <main className="price-lists-main">
          {selected && form ? (
            <div className="price-lists-form">
              <div className="price-lists-form__header">
                <div className="price-lists-sidebar__title">
                  <FileCheck size={17} />
                  <h3>
                    {selected.codigo}
                    {selected.esElectronico && (
                      <span style={{ marginLeft: "0.5rem", fontSize: "0.7rem", fontWeight: 600, color: "var(--brand)", background: "#eff6ff", padding: "0.15rem 0.4rem", borderRadius: "4px", verticalAlign: "middle" }}>
                        e-CF
                      </span>
                    )}
                  </h3>
                </div>
                <div className="price-lists-form__actions">
                  {isEditing ? (
                    <>
                      <button type="button" className="secondary-button" onClick={cancelEdit}>
                        <X size={15} /> {t("common.cancel")}
                      </button>
                      <button type="button" className="primary-button" disabled={isPending} onClick={onSave}>
                        {isPending ? <Loader2 size={15} className="spin" /> : <Save size={15} />}
                        {t("common.save")}
                      </button>
                    </>
                  ) : (
                    <button type="button" className="secondary-button" onClick={openEdit}>
                      <Pencil size={15} /> {t("common.edit")}
                    </button>
                  )}
                </div>
              </div>

              <div className="form-grid">
                <label className="form-grid__full">
                  <span>Nombre oficial DGII</span>
                  <input value={selected.nombre} disabled />
                </label>

                <label className="form-grid__full">
                  <span>Nombre interno del negocio</span>
                  <input
                    value={form.nombreInterno}
                    onChange={(e) => setForm({ ...form, nombreInterno: e.target.value })}
                    disabled={!isEditing}
                    placeholder={selected.nombre}
                  />
                </label>

                {selected.descripcion && (
                  <label className="form-grid__full">
                    <span>Descripción</span>
                    <textarea value={selected.descripcion} disabled rows={2} />
                  </label>
                )}

                <div className="form-grid__full">
                  <span>Características (catálogo oficial — no modificables)</span>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: "0.4rem", marginTop: "0.4rem" }}>
                    {flagBadge("Aplica Crédito", selected.aplicaCredito)}
                    {flagBadge("Aplica Contado", selected.aplicaContado)}
                    {flagBadge("Requiere RNC", selected.requiereRNC)}
                    {flagBadge("Aplica Impuesto", selected.aplicaImpuesto)}
                    {flagBadge("Exonera Impuesto", selected.exoneraImpuesto)}
                  </div>
                </div>

                <label className="form-grid__full" style={{ flexDirection: "row", alignItems: "center", gap: "0.75rem" }}>
                  <span>Usar en este negocio</span>
                  <button
                    type="button"
                    className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                    onClick={() => isEditing && setForm({ ...form, active: !form.active })}
                    disabled={!isEditing}
                  >
                    <span />
                  </button>
                </label>
              </div>
            </div>
          ) : (
            <div className="price-lists-empty">
              <FileCheck size={48} opacity={0.3} />
              <p>Selecciona un tipo de comprobante</p>
            </div>
          )}
        </main>
      </div>
    </section>
  )
}
