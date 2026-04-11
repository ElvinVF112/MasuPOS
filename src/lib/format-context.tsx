"use client"

import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react"
import { apiUrl } from "@/lib/client-config"
import type { CompanySettingsData } from "@/lib/pos-data"

type FormatSettings = {
  decimalSymbol: string
  digitGroupingSymbol: string
  digitsAfterDecimal: number
  negativeSignSymbol: string
  shortDateFormat: string
  longDateFormat: string
  shortTimeFormat: string
  longTimeFormat: string
  amSymbol: string
  pmSymbol: string
}

type FormatContextValue = {
  formatNumber: (value: number, decimals?: number) => string
  parseNumber: (str: string) => number
  decimalSymbol: string
  formatDate: (value: string | Date, mode?: "short" | "long") => string
  formatTime: (value: string | Date, mode?: "short" | "long") => string
  formatDateTime: (value: string | Date) => string
  isLoading: boolean
}

const DEFAULT_FORMAT: FormatSettings = {
  decimalSymbol: ".",
  digitGroupingSymbol: ",",
  digitsAfterDecimal: 2,
  negativeSignSymbol: "-",
  shortDateFormat: "dd/MM/yyyy",
  longDateFormat: "dddd, d 'de' MMMM 'de' yyyy",
  shortTimeFormat: "h:mm tt",
  longTimeFormat: "h:mm:ss tt",
  amSymbol: "AM",
  pmSymbol: "PM",
}

const FormatContext = createContext<FormatContextValue | null>(null)


export function FormatProvider({ children }: { children: ReactNode }) {
  const [settings, setSettings] = useState<FormatSettings>(DEFAULT_FORMAT)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    async function load() {
      try {
        const res = await fetch(apiUrl("/api/company"), { cache: "no-store", credentials: "include" })
        if (res.ok) {
          const json = (await res.json()) as { ok: boolean; data: CompanySettingsData }
          if (json.ok && json.data) {
            setSettings({ ...DEFAULT_FORMAT, ...json.data } as FormatSettings)
          }
        }
      } catch {
      } finally {
        setIsLoading(false)
      }
    }
    void load()
  }, [])

  const value = useMemo<FormatContextValue>(() => {
    function formatNumber(val: number, decimals?: number): string {
      const dec = decimals ?? settings.digitsAfterDecimal
      const abs = Math.abs(val)
      const sign = val < 0 ? settings.negativeSignSymbol : ""

      const fixed = abs.toFixed(dec)
      const [intPart, decPart] = fixed.split(".")
      const grouped = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, settings.digitGroupingSymbol)

      if (dec <= 0) {
        return sign + grouped
      }

      return sign + grouped + settings.decimalSymbol + (decPart ?? "")
    }

    function parseNumber(str: string): number {
      if (!str) return 0
      // Remove digit grouping symbols, then replace decimal symbol with "."
      const cleaned = str
        .replace(new RegExp(`\\${settings.digitGroupingSymbol}`, "g"), "")
        .replace(settings.decimalSymbol, ".")
      return parseFloat(cleaned) || 0
    }

    function toDate(v: string | Date): Date {
      if (v instanceof Date) return isNaN(v.getTime()) ? new Date() : v
      const d = new Date(v)
      return isNaN(d.getTime()) ? new Date() : d
    }

    function formatDate(val: string | Date, mode: "short" | "long" = "short"): string {
      let year: number, month: number, day: number

      if (typeof val === "string") {
        const parts = val.split("T")[0].split("-")
        if (parts.length >= 3) {
          year = parseInt(parts[0], 10)
          month = parseInt(parts[1], 10)
          day = parseInt(parts[2], 10)
        } else {
          return val
        }
      } else {
        const d = toDate(val)
        year = d.getFullYear()
        month = d.getMonth() + 1
        day = d.getDate()
      }

      const pad = (n: number) => String(n).padStart(2, "0")

      if (mode === "long") {
        const monthNames = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
        const weekdays = ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]
        const wd = new Date(year, month - 1, day).getDay()
        return `${weekdays[wd]}, ${day} de ${monthNames[month - 1]} de ${year}`
      }

      // Apply shortDateFormat from company settings (tokens: yyyy, yy, MM, M, dd, d)
      return settings.shortDateFormat
        .replace("yyyy", String(year))
        .replace("yy", String(year).slice(-2))
        .replace("MM", pad(month))
        .replace("M", String(month))
        .replace("dd", pad(day))
        .replace("d", String(day))
    }

    function formatTime(val: string | Date, mode: "short" | "long" = "short"): string {
      const date = toDate(val)
      const pattern = mode === "short" ? settings.shortTimeFormat : settings.longTimeFormat
      const lower = pattern.toLowerCase()
      const is12 = lower.includes("tt")
      const showSecs = lower.includes("ss")

      let h = date.getHours()
      let m = date.getMinutes()
      let s = date.getSeconds()

      if (is12) {
        const isPM = h >= 12
        if (h === 0) h = 12
        else if (h > 12) h -= 12
        const ampm = isPM ? settings.pmSymbol : settings.amSymbol
        if (showSecs) return `${h}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")} ${ampm}`
        return `${h}:${m.toString().padStart(2, "0")} ${ampm}`
      }
      if (showSecs) return `${h.toString().padStart(2, "0")}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`
      return `${h.toString().padStart(2, "0")}:${m.toString().padStart(2, "0")}`
    }

    function formatDateTime(val: string | Date): string {
      return `${formatDate(val, "short")} ${formatTime(val, "short")}`
    }

    return { formatNumber, parseNumber, decimalSymbol: settings.decimalSymbol, formatDate, formatTime, formatDateTime, isLoading }
  }, [settings, isLoading])

  return <FormatContext.Provider value={value}>{children}</FormatContext.Provider>
}

export function useFormat(): FormatContextValue {
  const ctx = useContext(FormatContext)
  if (!ctx) throw new Error("useFormat must be used within FormatProvider")
  return ctx
}
