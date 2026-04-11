"use client"

import { type FormEvent, useMemo, useState, useTransition } from "react"
import { Package, Pencil, Plus, Trash2 } from "lucide-react"
import { useRouter } from "next/navigation"
import type { CatalogManagerData, ProductRecord } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"

type ProductFormState = {
  id?: number
  name: string
  description: string
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

const emptyForm: ProductFormState = {
  name: "",
  description: "",
  categoryId: "",
  typeId: "",
  unitBaseId: "",
  unitSaleId: "",
  unitPurchaseId: "",
  unitAlt1Id: "",
  unitAlt2Id: "",
  unitAlt3Id: "",
  price: "0",
  active: true,
}

function toForm(product: ProductRecord): ProductFormState {
  return {
    id: product.id,
    name: product.name,
    description: product.description,
    categoryId: String(product.categoryId),
    typeId: String(product.typeId),
    unitBaseId: String(product.unitBaseId),
    unitSaleId: String(product.unitSaleId),
    unitPurchaseId: String(product.unitPurchaseId),
    unitAlt1Id: product.unitAlt1Id ? String(product.unitAlt1Id) : "",
    unitAlt2Id: product.unitAlt2Id ? String(product.unitAlt2Id) : "",
    unitAlt3Id: product.unitAlt3Id ? String(product.unitAlt3Id) : "",
    price: product.price.toFixed(2),
    active: product.active,
  }
}

export function CatalogManager({ data }: { data: CatalogManagerData }) {
  const router = useRouter()
  const [selectedId, setSelectedId] = useState<number | null>(data.products[0]?.id ?? null)
  const [form, setForm] = useState<ProductFormState>(data.products[0] ? toForm(data.products[0]) : emptyForm)
  const [message, setMessage] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  const selected = useMemo(() => data.products.find((product) => product.id === selectedId) ?? null, [data.products, selectedId])

  function resetForm() {
    setSelectedId(null)
    setForm(emptyForm)
  }

  function loadProduct(product: ProductRecord) {
    setSelectedId(product.id)
    setForm(toForm(product))
  }

  function runRequest(method: "POST" | "PUT" | "DELETE", body?: object) {
    setMessage(null)

    startTransition(async () => {
      const response = await fetch(apiUrl("/api/catalog/products"), {
        method,
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: body ? JSON.stringify(body) : undefined,
      })
      const result = (await response.json()) as { ok: boolean; message?: string }

      if (!response.ok || !result.ok) {
        setMessage(result.message ?? "No se pudo completar la operacion.")
        return
      }

      router.refresh()
      if (method !== "PUT") {
        resetForm()
      }
    })
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()

    const payload = {
      id: form.id,
      name: form.name,
      description: form.description,
      categoryId: Number(form.categoryId),
      typeId: Number(form.typeId),
      unitBaseId: Number(form.unitBaseId),
      unitSaleId: Number(form.unitSaleId || form.unitBaseId),
      unitPurchaseId: Number(form.unitPurchaseId || form.unitBaseId),
      unitAlt1Id: form.unitAlt1Id ? Number(form.unitAlt1Id) : undefined,
      unitAlt2Id: form.unitAlt2Id ? Number(form.unitAlt2Id) : undefined,
      unitAlt3Id: form.unitAlt3Id ? Number(form.unitAlt3Id) : undefined,
      price: Number(form.price),
      active: form.active,
    }

    if (!payload.name || !payload.categoryId || !payload.typeId || !payload.unitBaseId || Number.isNaN(payload.price)) {
      setMessage("Completa nombre, categoria, tipo, unidad base y precio.")
      return
    }

    runRequest(form.id ? "PUT" : "POST", payload)
  }

  return (
    <div className="management-layout">
      <section className="data-panel">
        <div className="data-panel__header data-panel__header--actions">
          <div>
            <h2>Productos</h2>
            <p>CRUD real sobre `Productos` usando stored procedures.</p>
          </div>
          <button className="primary-button" type="button" onClick={resetForm}>
            <Plus size={16} />
            Nuevo producto
          </button>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr><th>Producto</th><th>Categoria</th><th>Tipo</th><th>Venta</th><th>Precio</th><th></th></tr>
            </thead>
            <tbody>
              {data.products.map((product) => (
                <tr key={product.id} className={selectedId === product.id ? "is-selected-row" : ""}>
                  <td>{product.name}</td>
                  <td>{product.category}</td>
                  <td>{product.type}</td>
                  <td>{product.unitSale}</td>
                  <td>${product.price.toFixed(2)}</td>
                  <td className="table-actions">
                    <button className="secondary-button secondary-button--xs" type="button" onClick={() => loadProduct(product)}>
                      <Pencil size={14} /> Editar
                    </button>
                    <button className="ghost-button ghost-button--xs" type="button" onClick={() => runRequest("DELETE", { id: product.id })} disabled={isPending}>
                      <Trash2 size={14} /> Eliminar
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="data-panel">
        <div className="data-panel__header">
          <h2>{form.id ? "Editar producto" : "Crear producto"}</h2>
          <p>{selected ? `${selected.name} · ${selected.category}` : "Captura los datos para crear un producto nuevo."}</p>
        </div>

        <form className="form-grid" onSubmit={handleSubmit}>
          <label><span>Nombre</span><input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></label>
          <label><span>Precio</span><input type="number" step="0.01" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} /></label>
          <label className="form-grid__full"><span>Descripcion</span><textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></label>
          <label><span>Categoria</span><select value={form.categoryId} onChange={(e) => setForm({ ...form, categoryId: e.target.value })}><option value="">Selecciona</option>{data.lookups.categories.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label><span>Tipo</span><select value={form.typeId} onChange={(e) => setForm({ ...form, typeId: e.target.value })}><option value="">Selecciona</option>{data.lookups.productTypes.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label><span>Unidad base</span><select value={form.unitBaseId} onChange={(e) => setForm({ ...form, unitBaseId: e.target.value, unitSaleId: e.target.value, unitPurchaseId: e.target.value })}><option value="">Selecciona</option>{data.lookups.units.map((item) => <option key={item.id} value={item.id}>{item.name} ({item.abbreviation})</option>)}</select></label>
          <label><span>Unidad venta</span><select value={form.unitSaleId} onChange={(e) => setForm({ ...form, unitSaleId: e.target.value })}><option value="">Selecciona</option>{data.lookups.units.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label><span>Unidad compra</span><select value={form.unitPurchaseId} onChange={(e) => setForm({ ...form, unitPurchaseId: e.target.value })}><option value="">Selecciona</option>{data.lookups.units.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label><span>Alterna 1</span><select value={form.unitAlt1Id} onChange={(e) => setForm({ ...form, unitAlt1Id: e.target.value })}><option value="">Ninguna</option>{data.lookups.units.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label><span>Alterna 2</span><select value={form.unitAlt2Id} onChange={(e) => setForm({ ...form, unitAlt2Id: e.target.value })}><option value="">Ninguna</option>{data.lookups.units.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label><span>Alterna 3</span><select value={form.unitAlt3Id} onChange={(e) => setForm({ ...form, unitAlt3Id: e.target.value })}><option value="">Ninguna</option>{data.lookups.units.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}</select></label>
          <label className="checkbox-field"><input type="checkbox" checked={form.active} onChange={(e) => setForm({ ...form, active: e.target.checked })} /><span>Activo</span></label>

          {message ? <p className="form-message">{message}</p> : null}

          <div className="form-actions">
            <button className="secondary-button" type="button" onClick={resetForm}>Limpiar</button>
            <button className="primary-button" type="submit" disabled={isPending}><Package size={16} />{form.id ? "Guardar cambios" : "Crear producto"}</button>
          </div>
        </form>
      </section>
    </div>
  )
}
