"use client"

import type { ComponentType } from "react"
import { Coffee, Monitor, Moon, Orbit, RotateCcw, Sun, X } from "lucide-react"
import {
  DEFAULT_VISUAL_CONFIG,
  type SidebarMode,
  type VisualConfig,
  type VisualDensity,
  type VisualFont,
  type VisualTextSize,
  type VisualTheme,
  VISUAL_HEADER_PRESETS,
  VISUAL_PRIMARY_PRESETS,
} from "@/lib/visual-config"

type VisualConfigDrawerProps = {
  open: boolean
  config: VisualConfig
  onClose: () => void
  onChange: (next: VisualConfig) => void
  onReset: () => void
}

const THEME_OPTIONS: Array<{ value: VisualTheme; label: string; icon: ComponentType<{ size?: number }> }> = [
  { value: "system", label: "Sistema", icon: Monitor },
  { value: "light", label: "Claro", icon: Sun },
  { value: "dark", label: "Oscuro", icon: Moon },
  { value: "sepia", label: "Sepia", icon: Coffee },
  { value: "midnight", label: "Midnight", icon: Orbit },
]

const FONT_OPTIONS: Array<{ value: VisualFont; label: string }> = [
  { value: "segoe", label: "Segoe" },
  { value: "system", label: "Sistema" },
  { value: "inter", label: "Inter" },
  { value: "mono", label: "Monospace" },
  { value: "serif", label: "Serif" },
]

const TEXT_SIZE_OPTIONS: Array<{ value: VisualTextSize; label: string }> = [
  { value: "sm", label: "Pequeño" },
  { value: "md", label: "Normal" },
  { value: "lg", label: "Grande" },
]

const DENSITY_OPTIONS: Array<{ value: VisualDensity; label: string }> = [
  { value: "compact", label: "Compacta" },
  { value: "normal", label: "Normal" },
  { value: "comfortable", label: "Amplia" },
]

const SIDEBAR_MODE_OPTIONS: Array<{ value: SidebarMode; label: string }> = [
  { value: "always", label: "Siempre visible" },
  { value: "autohide", label: "Auto-ocultar" },
]

function SwatchButton({
  color,
  selected,
  onClick,
}: {
  color: string
  selected: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      className={`visual-config-swatch${selected ? " is-selected" : ""}`}
      onClick={onClick}
      aria-label={`Color ${color}`}
      title={color}
    >
      <span className="visual-config-swatch__inner" style={{ background: color }} />
    </button>
  )
}

export function VisualConfigDrawer({
  open,
  config,
  onClose,
  onChange,
  onReset,
}: VisualConfigDrawerProps) {
  if (!open) return null

  return (
    <>
      <button type="button" className="visual-config-backdrop" onClick={onClose} aria-label="Cerrar configuración visual" />
      <aside className="visual-config-drawer" aria-label="Configuración visual">
        <div className="visual-config-drawer__header">
          <div>
            <h3>Configuración Visual</h3>
            <p>Personaliza la vista del sistema a tu gusto.</p>
          </div>
          <button type="button" className="ghost-button ghost-button--xs" onClick={onClose}>
            <X size={16} />
          </button>
        </div>

        <div className="visual-config-drawer__body">
          <section className="visual-config-section">
            <span className="visual-config-section__title">Tema</span>
            <div className="visual-config-choice-grid visual-config-choice-grid--4">
              {THEME_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  className={`visual-config-choice${config.theme === option.value ? " is-selected" : ""}`}
                  onClick={() => onChange({ ...config, theme: option.value })}
                >
                  <span className="visual-config-choice__icon"><option.icon size={16} /></span>
                  {option.label}
                </button>
              ))}
            </div>
          </section>

          <section className="visual-config-section">
            <span className="visual-config-section__title">Color primario</span>
            <div className="visual-config-swatches">
              {VISUAL_PRIMARY_PRESETS.map((color) => (
                <SwatchButton
                  key={color}
                  color={color}
                  selected={config.primaryColor.toLowerCase() === color.toLowerCase()}
                  onClick={() => onChange({ ...config, primaryColor: color })}
                />
              ))}
            </div>
            <input
              className="visual-config-color-input"
              type="text"
              value={config.primaryColor}
              onChange={(event) => onChange({ ...config, primaryColor: event.target.value })}
              maxLength={20}
            />
          </section>

          <section className="visual-config-section">
            <span className="visual-config-section__title">Color de header / sidebar</span>
            <div className="visual-config-swatches">
              {VISUAL_HEADER_PRESETS.map((color) => (
                <SwatchButton
                  key={color}
                  color={color}
                  selected={config.headerColor.toLowerCase() === color.toLowerCase()}
                  onClick={() => onChange({ ...config, headerColor: color })}
                />
              ))}
            </div>
            <input
              className="visual-config-color-input"
              type="text"
              value={config.headerColor}
              onChange={(event) => onChange({ ...config, headerColor: event.target.value })}
              maxLength={20}
            />
          </section>

          <section className="visual-config-section">
            <span className="visual-config-section__title">Tipografía</span>
            <div className="visual-config-choice-grid visual-config-choice-grid--2">
              {FONT_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  className={`visual-config-choice${config.fontFamily === option.value ? " is-selected" : ""}`}
                  onClick={() => onChange({ ...config, fontFamily: option.value })}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </section>

          <section className="visual-config-section">
            <span className="visual-config-section__title">Tamaño de texto</span>
            <div className="visual-config-choice-grid visual-config-choice-grid--3">
              {TEXT_SIZE_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  className={`visual-config-choice${config.textSize === option.value ? " is-selected" : ""}`}
                  onClick={() => onChange({ ...config, textSize: option.value })}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </section>

          <section className="visual-config-section">
            <span className="visual-config-section__title">Densidad</span>
            <div className="visual-config-choice-grid visual-config-choice-grid--3">
              {DENSITY_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  className={`visual-config-choice${config.density === option.value ? " is-selected" : ""}`}
                  onClick={() => onChange({ ...config, density: option.value })}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </section>

          <section className="visual-config-section">
            <span className="visual-config-section__title">Modo del menu</span>
            <div className="visual-config-choice-grid visual-config-choice-grid--2">
              {SIDEBAR_MODE_OPTIONS.map((option) => (
                <button
                  key={option.value}
                  type="button"
                  className={`visual-config-choice${config.sidebarMode === option.value ? " is-selected" : ""}`}
                  onClick={() => onChange({ ...config, sidebarMode: option.value })}
                >
                  {option.label}
                </button>
              ))}
            </div>
          </section>

          <section className="visual-config-preview">
            <span className="visual-config-section__title">Vista previa</span>
            <div className="visual-config-preview__card">
              <div className="visual-config-preview__header" style={{ background: config.headerColor }}>
                Header
              </div>
              <div className="visual-config-preview__body">
                <button
                  type="button"
                  className="visual-config-preview__primary"
                  style={{ background: config.primaryColor }}
                >
                  Botón primario
                </button>
                <div className="visual-config-preview__text">Texto de interfaz · {FONT_OPTIONS.find((item) => item.value === config.fontFamily)?.label}</div>
              </div>
            </div>
          </section>
        </div>

        <div className="visual-config-drawer__footer">
          <button type="button" className="secondary-button secondary-button--sm" onClick={() => onChange(DEFAULT_VISUAL_CONFIG)}>
            Aplicar default
          </button>
          <button type="button" className="ghost-button ghost-button--xs" onClick={onReset}>
            <RotateCcw size={15} />
            Restablecer
          </button>
        </div>
      </aside>
    </>
  )
}
