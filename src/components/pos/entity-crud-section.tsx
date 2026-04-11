"use client"

import { type FormEvent, useEffect, useMemo, useState, useTransition } from "react"
import { ArrowLeft, Pencil, Plus, Trash2 } from "lucide-react"
import { usePathname, useRouter, useSearchParams } from "next/navigation"
import type { AdminEntityName } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

type FieldOption = { value: string; label: string }

type FieldConfig =
  | { name: string; label: string; type: "text" | "textarea" | "number"; required?: boolean }
  | { name: string; label: string; type: "select"; options: FieldOption[]; required?: boolean }
  | { name: string; label: string; type: "checkbox"; required?: boolean }

type EntityCrudSectionProps<T extends Record<string, unknown>> = {
  title: string
  description: string
  entity: AdminEntityName
  items: T[]
  getId: (item: T) => number
  columns: Array<{ header: string; render: (item: T) => string | number }>
  fields: FieldConfig[]
  toForm: (item: T) => Record<string, unknown>
  emptyForm: Record<string, unknown>
}

export function EntityCrudSection<T extends Record<string, unknown>>({ title, description, entity, items, getId, columns, fields, toForm, emptyForm }: EntityCrudSectionProps<T>) {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const router = useRouter()
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const [form, setForm] = useState<Record<string, unknown>>(emptyForm)
  const [message, setMessage] = useState<string | null>(null)
  const [isPending, startTransition] = useTransition()

  const { setDirty, confirmAction } = useUnsavedGuard()

  const mode = searchParams.get("mode")
  const selectedEntity = searchParams.get("entity")
  const editId = searchParams.get("id")

  const isEditor = selectedEntity === entity && (mode === "new" || mode === "edit")

  useEffect(() => {
    setDirty(isEditor)
    return () => setDirty(false)
  }, [isEditor, setDirty])
  const selected = useMemo(() => items.find((item) => getId(item) === selectedId) ?? null, [items, selectedId, getId])

  useEffect(() => {
    if (!isEditor) {
      return
    }

    if (mode === "new") {
      setSelectedId(null)
      setForm(emptyForm)
      setMessage(null)
      return
    }

    if (mode === "edit") {
      const id = Number(editId)
      const item = items.find((candidate) => getId(candidate) === id)
      if (item) {
        setSelectedId(id)
        setForm(toForm(item))
        setMessage(null)
      }
    }
  }, [isEditor, mode, editId, items, getId, toForm, emptyForm])

  function resetForm() {
    setSelectedId(null)
    setForm(emptyForm)
  }

  function openNew() {
    router.push(`${pathname}?entity=${entity}&mode=new`)
  }

  function openEdit(item: T) {
    router.push(`${pathname}?entity=${entity}&mode=edit&id=${getId(item)}`)
  }

  function closeEditor() {
    confirmAction(() => {
      setDirty(false)
      router.push(pathname)
    })
  }

  function submit(method: "POST" | "PUT" | "DELETE", payload?: Record<string, unknown>) {
    setMessage(null)
    startTransition(async () => {
      const response = await fetch(apiUrl(`/api/admin/${entity}`), {
        method,
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: payload ? JSON.stringify(payload) : undefined,
      })
      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        setMessage(result.message ?? "No se pudo completar la operacion.")
        return
      }
      setDirty(false)
      router.push(pathname)
      router.refresh()
    })
  }

  function onSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const payload = { ...form }
    const invalidRequired = fields.some((field) => field.required && !String(payload[field.name] ?? "").trim())
    if (invalidRequired) {
      setMessage("Completa los campos obligatorios.")
      return
    }
    submit(mode === "edit" ? "PUT" : "POST", payload)
  }

  if (isEditor) {
    return (
      <section className="data-panel">
        <div className="data-panel__header data-panel__header--actions">
          <div>
            <h2>{mode === "edit" ? `Editar ${title}` : `Nuevo ${title}`}</h2>
            <p>{mode === "edit" && selected ? `Editando registro #${getId(selected)}` : description}</p>
          </div>
          <button className="secondary-button" type="button" onClick={closeEditor}>
            <ArrowLeft size={16} />
            Volver al listado
          </button>
        </div>

        <form className="form-grid form-grid--spaced" onSubmit={onSubmit}>
          {fields.map((field) => {
            if (field.type === "checkbox") {
              return <label className="checkbox-field" key={field.name}><input type="checkbox" checked={Boolean(form[field.name])} onChange={(e) => setForm({ ...form, [field.name]: e.target.checked })} /><span>{field.label}</span></label>
            }

            if (field.type === "textarea") {
              return <label className="form-grid__full" key={field.name}><span>{field.label}</span><textarea value={String(form[field.name] ?? "")} onChange={(e) => setForm({ ...form, [field.name]: e.target.value })} /></label>
            }

            if (field.type === "select") {
              return (
                <label key={field.name}>
                  <span>{field.label}</span>
                  <select value={String(form[field.name] ?? "")} onChange={(e) => setForm({ ...form, [field.name]: e.target.value })}>
                    <option value="">Selecciona</option>
                    {field.options.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
                  </select>
                </label>
              )
            }

            return <label key={field.name}><span>{field.label}</span><input type={field.type === "number" ? "number" : "text"} value={String(form[field.name] ?? "")} onChange={(e) => setForm({ ...form, [field.name]: field.type === "number" ? Number(e.target.value) : e.target.value })} /></label>
          })}

          {message ? <p className="form-message">{message}</p> : null}
          <div className="form-actions">
            <button className="secondary-button" type="button" onClick={closeEditor}>Cancelar</button>
            <button className="primary-button" type="submit" disabled={isPending}>{mode === "edit" ? "Guardar cambios" : "Crear registro"}</button>
          </div>
        </form>
      </section>
    )
  }

  return (
    <section className="data-panel">
      <div className="data-panel__header data-panel__header--actions">
        <div>
          <h2>{title}</h2>
          <p>{description}</p>
        </div>
        <button className="sidebar__add-btn" type="button" onClick={openNew} title="Nuevo"><Plus size={15} /></button>
      </div>

      <div className="table-wrap">
        <table className="data-table">
          <thead>
            <tr>{columns.map((column) => <th key={column.header}>{column.header}</th>)}<th></th></tr>
          </thead>
          <tbody>
            {items.map((item) => (
              <tr key={getId(item)}>
                {columns.map((column) => <td key={`${getId(item)}-${column.header}`}>{column.render(item)}</td>)}
                <td className="table-actions">
                  <button className="secondary-button secondary-button--xs" type="button" onClick={() => openEdit(item)}><Pencil size={14} />Editar</button>
                  <button className="ghost-button ghost-button--xs" type="button" onClick={() => submit("DELETE", { id: getId(item) })} disabled={isPending}><Trash2 size={14} />Eliminar</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
