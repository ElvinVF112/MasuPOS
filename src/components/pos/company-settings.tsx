"use client"

import { type ChangeEvent, type FormEvent, useMemo, useRef, useState, useTransition } from "react"
import { Building2, Clock3, Globe2, HandCoins, PencilLine, Phone, Save, Settings2, Upload } from "lucide-react"
import { useRouter } from "next/navigation"
import { toast } from "sonner"
import type { CompanySettingsData, CurrencyRecord } from "@/lib/pos-data"
import { apiUrl } from "@/lib/client-config"
import { useUnsavedGuard } from "@/lib/unsaved-guard"

const MAX_LOGO_BYTES = 2 * 1024 * 1024
const ALLOWED_MIME = new Set(["image/png", "image/jpeg", "image/jpg", "image/webp"])

type CompanyTab = "general" | "contact" | "social" | "operations"

function formatBytes(value: number) {
  if (value < 1024) return `${value} B`
  const kb = value / 1024
  if (kb < 1024) return `${kb.toFixed(1)} KB`
  return `${(kb / 1024).toFixed(2)} MB`
}

function formatMimeLabel(mime: string) {
  const normalized = mime.toLowerCase()
  if (normalized === "image/png") return "PNG"
  if (normalized === "image/jpeg" || normalized === "image/jpg") return "JPG"
  if (normalized === "image/webp") return "WEBP"
  return mime || "-"
}

export function CompanySettings({ initialData, currencies }: { initialData: CompanySettingsData; currencies: CurrencyRecord[] }) {
  const router = useRouter()
  const fileInputRef = useRef<HTMLInputElement | null>(null)
  const formRef = useRef<HTMLFormElement | null>(null)
  const [form, setForm] = useState<CompanySettingsData>(initialData)
  const [activeTab, setActiveTab] = useState<CompanyTab>("general")
  const [message, setMessage] = useState<string | null>(null)
  const [selectedLogoInfo, setSelectedLogoInfo] = useState<string>("")
  const [isEditing, setIsEditing] = useState(false)
  const { setDirty, confirmAction } = useUnsavedGuard()
  const [isPending, startTransition] = useTransition()

  const previewSrc = useMemo(() => {
    if (form.hasLogoBinary) {
      const stamp = form.logoUpdatedAt ? encodeURIComponent(form.logoUpdatedAt) : Date.now()
      return `${apiUrl("/api/company/logo")}?v=${stamp}`
    }
    return form.logoUrl || ""
  }, [form.hasLogoBinary, form.logoUpdatedAt, form.logoUrl])

  const currencyOptions = useMemo(() => {
    const activeCurrencies = currencies.filter((currency) => currency.active)
    const source = activeCurrencies.length ? activeCurrencies : currencies
    const existingCodes = new Set(source.map((currency) => currency.code.toUpperCase()))
    const fallback = ["DOP", "USD"].filter((code) => !existingCodes.has(code)).map((code) => ({
      id: -code.length,
      code,
      name: code,
      symbol: null,
      symbolAlt: null,
      isLocal: code === "DOP",
      bankCode: null,
      factorConversionLocal: 1,
      factorConversionUSD: code === "USD" ? 1 : 0,
      showInPOS: true,
      acceptPayments: true,
      decimalPOS: 2,
      active: true,
      lastRateDate: "",
      rateAdministrative: null,
      rateOperative: null,
      ratePurchase: null,
      rateSale: null,
    }))
    return [...source, ...fallback]
  }, [currencies])

  function update<K extends keyof CompanySettingsData>(key: K, value: CompanySettingsData[K]) {
    setForm((current) => ({ ...current, [key]: value }))
  }

  function beginEdit() {
    setMessage(null)
    setIsEditing(true)
    setDirty(true)
  }

  function cancelEdit() {
    confirmAction(() => {
      setForm(initialData)
      setMessage(null)
      setSelectedLogoInfo("")
      setIsEditing(false)
      setDirty(false)
    })
  }

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!isEditing) return
    setMessage(null)

    if (!form.businessName.trim()) {
      setMessage("La razon social es obligatoria.")
      return
    }

    if (!Number.isFinite(form.sessionDurationMinutes) || form.sessionDurationMinutes < 1) {
      setMessage("La duracion de sesion debe ser mayor a 0 minutos.")
      return
    }

    if (!Number.isFinite(form.sessionIdleMinutes) || form.sessionIdleMinutes < 1) {
      setMessage("El tiempo de inactividad debe ser mayor a 0 minutos.")
      return
    }

    startTransition(async () => {
      const response = await fetch(apiUrl("/api/company"), {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      })

      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        const errorMessage = result.message ?? "No se pudo guardar la informacion de la empresa."
        setMessage(errorMessage)
        toast.error("Error al guardar", { description: errorMessage })
        return
      }

      setMessage(null)
      toast.success("Cambios guardados exitosamente", {
        description: "Los datos de la empresa se han actualizado correctamente",
      })
      setIsEditing(false)
      setDirty(false)
      router.refresh()
    })
  }

  function uploadLogo(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file || !form.id || !isEditing) return

    setSelectedLogoInfo(`Archivo: ${file.name} · ${formatBytes(file.size)} · ${formatMimeLabel(file.type)}`)

    if (!ALLOWED_MIME.has(file.type.toLowerCase())) {
      setMessage("Formato no permitido. Usa PNG, JPG o WEBP.")
      event.target.value = ""
      return
    }

    if (file.size <= 0 || file.size > MAX_LOGO_BYTES) {
      setMessage("El logo debe ser mayor a 0 y maximo 2MB.")
      event.target.value = ""
      return
    }

    setMessage(null)
    startTransition(async () => {
      const payload = new FormData()
      payload.append("logo", file)

      const response = await fetch(apiUrl("/api/company/logo"), {
        method: "POST",
        credentials: "include",
        body: payload,
      })

      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        const errorMessage = result.message ?? "No se pudo subir el logo."
        setMessage(errorMessage)
        toast.error("Error al guardar", { description: errorMessage })
        event.target.value = ""
        return
      }

      setForm((current) => ({ ...current, hasLogoBinary: true, logoUpdatedAt: String(Date.now()) }))
      setMessage(null)
      toast.success("Cambios guardados exitosamente", {
        description: "Los datos de la empresa se han actualizado correctamente",
      })
      event.target.value = ""
      router.refresh()
    })
  }

  function removeLogo() {
    if (!form.id || !isEditing) return
    setMessage(null)

    startTransition(async () => {
      const response = await fetch(apiUrl("/api/company/logo"), {
        method: "DELETE",
        credentials: "include",
      })

      const result = (await response.json()) as { ok: boolean; message?: string }
      if (!response.ok || !result.ok) {
        const errorMessage = result.message ?? "No se pudo eliminar el logo."
        setMessage(errorMessage)
        toast.error("Error al guardar", { description: errorMessage })
        return
      }

      setForm((current) => ({ ...current, hasLogoBinary: false, logoUpdatedAt: String(Date.now()) }))
      setMessage(null)
      toast.success("Cambios guardados exitosamente", {
        description: "Los datos de la empresa se han actualizado correctamente",
      })
      setSelectedLogoInfo("")
      router.refresh()
    })
  }


  return (
    <section className="company-settings">
      <div className="company-head">
        <div></div>
        {isEditing ? (
          <div className="company-head__actions">
            <button className="primary-button" type="button" onClick={() => formRef.current?.requestSubmit()} disabled={isPending}>
              <Save size={16} />
              {isPending ? "Guardando..." : "Guardar Datos"}
            </button>
            <button className="danger-button" type="button" onClick={cancelEdit} disabled={isPending}>
              Cancelar
            </button>
          </div>
        ) : (
          <button className="primary-button" type="button" onClick={beginEdit}>
            <PencilLine size={16} />
            Editar Datos
          </button>
        )}
      </div>

      <div className="company-tabs">
        <button type="button" className={activeTab === "general" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("general")}>
          <Building2 size={14} /> Datos Generales
        </button>
        <button type="button" className={activeTab === "contact" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("contact")}>
          <Phone size={14} /> Informacion de Contacto
        </button>
        <button type="button" className={activeTab === "social" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("social")}>
          <Globe2 size={14} /> Redes Sociales
        </button>
        <button type="button" className={activeTab === "operations" ? "filter-pill is-active" : "filter-pill"} onClick={() => setActiveTab("operations")}>
          <Settings2 size={14} /> Operaciones
        </button>
      </div>

      <form ref={formRef} onSubmit={submit}>
        {activeTab === "general" ? (
          <section className="data-panel company-tab-panel">
            <div className="company-grid">
              <section className="company-logo-panel">
                <h2>Logo de la Empresa</h2>
                <p>Sube el logo en PNG, JPG o WEBP (maximo 2MB).</p>
                <div className="company-logo-uploader">
                  {previewSrc ? (
                    <img src={previewSrc} alt="Logo de la empresa" />
                  ) : (
                    <div className="company-logo-placeholder"><Building2 size={30} /><span>Logo</span></div>
                  )}

                  <input ref={fileInputRef} type="file" accept="image/png,image/jpeg,image/jpg,image/webp" onChange={uploadLogo} hidden />
                  <button className="secondary-button" type="button" onClick={() => fileInputRef.current?.click()} disabled={isPending || !form.id || !isEditing}><Upload size={16} />Subir logo</button>
                  <button className="ghost-button" type="button" onClick={removeLogo} disabled={isPending || !form.id || !form.hasLogoBinary || !isEditing}>Quitar logo</button>
                  {selectedLogoInfo ? <p className="company-logo-fileinfo">{selectedLogoInfo}</p> : null}
                </div>
              </section>

                <section>
                <div className="form-grid form-grid--spaced">
                  <label><span>Nombre Comercial</span><input value={form.tradeName} onChange={(event) => update("tradeName", event.target.value)} disabled={!isEditing} /></label>
                  <label className="form-grid__full"><span>Eslogan</span><input value={form.slogan} onChange={(event) => update("slogan", event.target.value)} disabled={!isEditing} placeholder="Ej: Tu socio de negocios" /></label>
                  <label><span>Razon Social</span><input value={form.businessName} onChange={(event) => update("businessName", event.target.value)} required disabled={!isEditing} /></label>
                  <label><span>Identificacion Fiscal</span><input value={form.fiscalId} maxLength={30} onChange={(event) => update("fiscalId", event.target.value)} disabled={!isEditing} /></label>
                  <label><span>Pais</span><input value={form.country} onChange={(event) => update("country", event.target.value)} disabled={!isEditing} /></label>
                  <div className="company-currency-row form-grid__full">
                    <label>
                      <span>Moneda Base</span>
                      <select value={form.currency} onChange={(event) => update("currency", event.target.value)} disabled={!isEditing}>
                        {currencyOptions.map((currency) => (
                          <option key={`base-${currency.code}-${currency.id}`} value={currency.code}>
                            {currency.code} - {currency.name}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label>
                      <span>Moneda Secundaria</span>
                      <select value={form.secondaryCurrency || ""} onChange={(event) => update("secondaryCurrency", event.target.value)} disabled={!isEditing}>
                        <option value="">-- Sin moneda secundaria --</option>
                        {currencyOptions.map((currency) => (
                          <option key={`secondary-${currency.code}-${currency.id}`} value={currency.code}>
                            {currency.code} - {currency.name}
                          </option>
                        ))}
                      </select>
                    </label>
                  </div>
                  <label className="company-active-toggle form-grid__full">
                    <div>
                      <span>Empresa activa</span>
                    </div>
                    <button
                      className={form.active ? "toggle-switch is-on" : "toggle-switch"}
                      type="button"
                      onClick={() => isEditing && update("active", !form.active)}
                      disabled={!isEditing}
                      aria-label="Cambiar estado activo"
                    >
                      <span />
                    </button>
                  </label>
                </div>
              </section>
            </div>
          </section>
        ) : null}

        {activeTab === "contact" ? (
          <section className="data-panel company-tab-panel">
            <h2>Informacion de Contacto</h2>
            <div className="form-grid form-grid--spaced">
              <label className="form-grid__full"><span>Direccion</span><textarea value={form.address} onChange={(event) => update("address", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Ciudad</span><input value={form.city} onChange={(event) => update("city", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Estado / Provincia</span><input value={form.stateProvince} onChange={(event) => update("stateProvince", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Codigo Postal</span><input value={form.postalCode} onChange={(event) => update("postalCode", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Telefono 1</span><input value={form.phone1} onChange={(event) => update("phone1", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Telefono 2</span><input value={form.phone2} onChange={(event) => update("phone2", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Correo</span><input type="email" value={form.email} onChange={(event) => update("email", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Sitio Web</span><input value={form.website} onChange={(event) => update("website", event.target.value)} disabled={!isEditing} /></label>
            </div>
          </section>
        ) : null}

        {activeTab === "social" ? (
          <section className="data-panel company-tab-panel">
            <h2>Redes Sociales</h2>
            <div className="form-grid form-grid--spaced">
              <label><span>Instagram</span><input value={form.instagram} onChange={(event) => update("instagram", event.target.value)} disabled={!isEditing} /></label>
              <label><span>Facebook</span><input value={form.facebook} onChange={(event) => update("facebook", event.target.value)} disabled={!isEditing} /></label>
              <label><span>X / Twitter</span><input value={form.x} onChange={(event) => update("x", event.target.value)} disabled={!isEditing} /></label>
              <label className="form-grid__full"><span>Logo URL (opcional)</span><input value={form.logoUrl} onChange={(event) => update("logoUrl", event.target.value)} disabled={!isEditing} /></label>
            </div>
          </section>
        ) : null}

        {activeTab === "operations" ? (
          <section className="data-panel company-tab-panel">
            <div className="company-ops-grid">

              {/* Impuesto */}
              <div className="company-format-section">
                <h2><HandCoins size={16} /> Impuesto</h2>
                <div className="form-grid form-grid--spaced">
                  <label className="company-active-toggle form-grid__full">
                    <div><span>Maneja impuesto</span></div>
                    <button
                      className={form.applyTax ? "toggle-switch is-on" : "toggle-switch"}
                      type="button"
                      onClick={() => isEditing && update("applyTax", !form.applyTax)}
                      disabled={!isEditing}
                      aria-label="Activar impuesto"
                    >
                      <span />
                    </button>
                  </label>
                  <label>
                    <span>Nombre</span>
                    <input
                      type="text"
                      maxLength={50}
                      value={form.taxName}
                      onChange={(event) => update("taxName", event.target.value)}
                      disabled={!isEditing || !form.applyTax}
                      placeholder="Ej: ITBIS"
                    />
                  </label>
                  <label>
                    <span>Porcentaje (%)</span>
                    <input
                      type="number"
                      min={0}
                      max={100}
                      step={0.01}
                      value={form.taxPercent}
                      onChange={(event) => update("taxPercent", Math.max(0, Number(event.target.value) || 0))}
                      disabled={!isEditing || !form.applyTax}
                    />
                  </label>
                </div>
              </div>

              {/* Propina Legal */}
              <div className="company-format-section">
                <h2><HandCoins size={16} /> Propina Legal</h2>
                <div className="form-grid form-grid--spaced">
                  <label className="company-active-toggle form-grid__full">
                    <div><span>Maneja propina legal</span></div>
                    <button
                      className={form.applyTip ? "toggle-switch is-on" : "toggle-switch"}
                      type="button"
                      onClick={() => isEditing && update("applyTip", !form.applyTip)}
                      disabled={!isEditing}
                      aria-label="Activar propina legal"
                    >
                      <span />
                    </button>
                  </label>
                  <label>
                    <span>Nombre</span>
                    <input
                      type="text"
                      maxLength={50}
                      value={form.tipName}
                      onChange={(event) => update("tipName", event.target.value)}
                      disabled={!isEditing || !form.applyTip}
                      placeholder="Ej: Propina Legal"
                    />
                  </label>
                  <label>
                    <span>Porcentaje (%)</span>
                    <input
                      type="number"
                      min={0}
                      max={100}
                      step={0.01}
                      value={form.tipPercent}
                      onChange={(event) => update("tipPercent", Math.max(0, Number(event.target.value) || 0))}
                      disabled={!isEditing || !form.applyTip}
                    />
                  </label>
                </div>
              </div>

            </div>

              <div className="company-format-section">
                <h2><Clock3 size={16} /> Sesiones</h2>
                <div className="form-grid form-grid--spaced">
                <label>
                  <span>Duracion maxima de sesion (min)</span>
                  <input
                    type="number"
                    min={1}
                    step={1}
                    value={form.sessionDurationMinutes}
                    onChange={(event) => update("sessionDurationMinutes", Math.max(1, Number(event.target.value) || 1))}
                    disabled={!isEditing}
                  />
                </label>
                <label>
                  <span>Logout por inactividad (min)</span>
                  <input
                    type="number"
                    min={1}
                    step={1}
                    value={form.sessionIdleMinutes}
                    onChange={(event) => update("sessionIdleMinutes", Math.max(1, Number(event.target.value) || 1))}
                    disabled={!isEditing}
                  />
                </label>
              </div>
            </div>

            <div className="company-format-section">
              <h2><Settings2 size={16} /> Reglas de Ordenes</h2>
              <div className="form-grid form-grid--spaced">
                <label className="company-operation-rule form-grid__full">
                  <div className="company-operation-rule__head">
                    <span>Restringir ordenes por usuario</span>
                    <button
                      className={form.restrictOrdersByUser ? "toggle-switch is-on" : "toggle-switch"}
                      type="button"
                      onClick={() => isEditing && update("restrictOrdersByUser", !form.restrictOrdersByUser)}
                      disabled={!isEditing}
                      aria-label="Activar restriccion de ordenes por usuario"
                    >
                      <span />
                    </button>
                  </div>
                  <small>Un operativo no puede entrar, modificar o cancelar ordenes de otro usuario.</small>
                </label>

                <label className="company-operation-rule form-grid__full">
                  <div className="company-operation-rule__head">
                    <span>Bloquear mesa por usuario</span>
                    <button
                      className={form.lockTablesByUser ? "toggle-switch is-on" : "toggle-switch"}
                      type="button"
                      onClick={() => isEditing && update("lockTablesByUser", !form.lockTablesByUser)}
                      disabled={!isEditing}
                      aria-label="Activar bloqueo de mesa por usuario"
                    >
                      <span />
                    </button>
                  </div>
                  <small>La mesa queda reservada al usuario dueno de la primera orden abierta en ese recurso.</small>
                </label>
              </div>
            </div>
          </section>
        ) : null}

        {message ? <p className="form-message company-message">{message}</p> : null}
      </form>
    </section>
  )
}
