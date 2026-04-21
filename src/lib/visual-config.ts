export type VisualTheme = "system" | "light" | "dark" | "sepia" | "midnight"
export type VisualFont = "system" | "segoe" | "inter" | "mono" | "serif"
export type VisualTextSize = "sm" | "md" | "lg"
export type VisualDensity = "compact" | "normal" | "comfortable"
export type SidebarMode = "always" | "autohide"

export type VisualConfig = {
  theme: VisualTheme
  primaryColor: string
  headerColor: string
  fontFamily: VisualFont
  textSize: VisualTextSize
  density: VisualDensity
  sidebarMode: SidebarMode
}

export const DEFAULT_VISUAL_CONFIG: VisualConfig = {
  theme: "system",
  primaryColor: "#12467e",
  headerColor: "#f4f8fd",
  fontFamily: "segoe",
  textSize: "md",
  density: "normal",
  sidebarMode: "always",
}

export const VISUAL_PRIMARY_PRESETS = [
  "#12467e",
  "#2563eb",
  "#4f46e5",
  "#7c3aed",
  "#e11d48",
  "#0f766e",
  "#059669",
  "#d97706",
  "#ea580c",
  "#0891b2",
]

export const VISUAL_HEADER_PRESETS = [
  "#f4f8fd",
  "#eff4fa",
  "#eaf2fb",
  "#0f172a",
  "#111827",
  "#1e293b",
  "#2b2d42",
  "#1f3b5a",
  "#264653",
  "#4338ca",
]

function getStorageKey(userKey: string) {
  return `masu.visual.${userKey}`
}

function safeParse<T>(value: string | null): T | null {
  if (!value) return null
  try {
    return JSON.parse(value) as T
  } catch {
    return null
  }
}

export function loadVisualConfig(userKey: string): VisualConfig {
  if (typeof window === "undefined") return DEFAULT_VISUAL_CONFIG
  const parsed = safeParse<Partial<VisualConfig & { sidebarMode: string }>>(window.localStorage.getItem(getStorageKey(userKey)))
  const raw = { ...DEFAULT_VISUAL_CONFIG, ...(parsed ?? {}) }
  // Migrar valores legacy
  if (raw.sidebarMode === ("expanded" as string)) raw.sidebarMode = "always"
  if (raw.sidebarMode === ("semi" as string)) raw.sidebarMode = "autohide"
  return raw
}

export function hasStoredVisualConfig(userKey: string) {
  if (typeof window === "undefined") return false
  return window.localStorage.getItem(getStorageKey(userKey)) !== null
}

export function saveVisualConfig(userKey: string, config: VisualConfig) {
  if (typeof window === "undefined") return
  window.localStorage.setItem(getStorageKey(userKey), JSON.stringify(config))
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

function mixHex(baseHex: string, targetHex: string, ratio: number) {
  const base = hexToRgb(baseHex)
  const target = hexToRgb(targetHex)
  if (!base || !target) return baseHex
  return rgbToHex(
    base.r + (target.r - base.r) * ratio,
    base.g + (target.g - base.g) * ratio,
    base.b + (target.b - base.b) * ratio,
  )
}

function getThemeTokens(theme: VisualTheme) {
  switch (theme) {
    case "dark":
      return {
        bg: "#0b1220",
        panel: "#111827",
        panelSoft: "#162133",
        ink: "#f5f7fb",
        muted: "#9fb0c8",
        line: "#263246",
        shellTopbarBg: "#0f172a",
        shellSidebarBg: "#0b1220",
        shellChromeText: "#eaf1fb",
      }
    case "sepia":
      return {
        bg: "#f4ecdf",
        panel: "#fff8ee",
        panelSoft: "#f8efdf",
        ink: "#49321b",
        muted: "#8a6d4e",
        line: "#dfceb7",
        shellTopbarBg: "#f7eedf",
        shellSidebarBg: "#f6ecdb",
        shellChromeText: "#49321b",
      }
    case "midnight":
      return {
        bg: "#12192c",
        panel: "#16213a",
        panelSoft: "#1c2945",
        ink: "#eef5ff",
        muted: "#9cb2d4",
        line: "#30415f",
        shellTopbarBg: "#17233d",
        shellSidebarBg: "#12192c",
        shellChromeText: "#eef5ff",
      }
    case "light":
    case "system":
    default:
      return {
        bg: "#e8eef6",
        panel: "#ffffff",
        panelSoft: "#f7f9fc",
        ink: "#10233d",
        muted: "#61728d",
        line: "#d5deea",
        shellTopbarBg: "#f4f8fd",
        shellSidebarBg: "#f8fafd",
        shellChromeText: "#10233d",
      }
  }
}

function getFontFamily(fontFamily: VisualFont) {
  switch (fontFamily) {
    case "inter":
      return "Inter, 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif"
    case "mono":
      return "'IBM Plex Mono', 'Consolas', monospace"
    case "serif":
      return "Georgia, 'Times New Roman', serif"
    case "system":
      return "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
    case "segoe":
    default:
      return "\"Segoe UI\", Tahoma, Geneva, Verdana, sans-serif"
  }
}

function getTextScale(textSize: VisualTextSize) {
  switch (textSize) {
    case "sm": return "0.95"
    case "lg": return "1.05"
    case "md":
    default: return "1"
  }
}

function getDensityScale(density: VisualDensity) {
  switch (density) {
    case "compact": return "0.92"
    case "comfortable": return "1.08"
    case "normal":
    default: return "1"
  }
}

export function applyVisualConfig(config: VisualConfig) {
  if (typeof document === "undefined") return
  const root = document.documentElement
  const theme = getThemeTokens(config.theme)

  root.style.setProperty("--bg", theme.bg)
  root.style.setProperty("--panel", theme.panel)
  root.style.setProperty("--panel-soft", theme.panelSoft)
  root.style.setProperty("--ink", theme.ink)
  root.style.setProperty("--muted", theme.muted)
  root.style.setProperty("--line", theme.line)
  root.style.setProperty("--brand", config.primaryColor)
  root.style.setProperty("--brand-strong", mixHex(config.primaryColor, "#001b37", 0.22))
  root.style.setProperty("--shell-topbar-bg", config.headerColor || theme.shellTopbarBg)
  root.style.setProperty("--shell-sidebar-bg", mixHex(config.headerColor || theme.shellSidebarBg, theme.panel, 0.45))
  root.style.setProperty("--shell-chrome-text", theme.shellChromeText)
  root.style.setProperty("--font-ui", getFontFamily(config.fontFamily))
  root.style.setProperty("--ui-scale", getTextScale(config.textSize))
  root.style.setProperty("--density-scale", getDensityScale(config.density))
}
