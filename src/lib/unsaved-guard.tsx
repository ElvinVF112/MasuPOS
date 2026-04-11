"use client"

import { createContext, useCallback, useContext, useRef, useState, type ReactNode } from "react"

type UnsavedGuardContextValue = {
  isDirty: boolean
  setDirty: (dirty: boolean) => void
  requestNavigate: (href: string, onConfirm: () => void) => void
  confirmAction: (onConfirm: () => void) => void
}

const UnsavedGuardContext = createContext<UnsavedGuardContextValue>({
  isDirty: false,
  setDirty: () => undefined,
  requestNavigate: (_href, onConfirm) => onConfirm(),
  confirmAction: (onConfirm) => onConfirm(),
})

export function UnsavedGuardProvider({ children }: { children: ReactNode }) {
  const [isDirty, setIsDirty] = useState(false)
  const [pendingHref, setPendingHref] = useState<string | null>(null)
  const pendingCallbackRef = useRef<(() => void) | null>(null)

  const setDirty = useCallback((dirty: boolean) => {
    setIsDirty(dirty)
  }, [])

  const requestNavigate = useCallback((href: string, onConfirm: () => void) => {
    if (!isDirty) {
      onConfirm()
      return
    }
    pendingCallbackRef.current = onConfirm
    setPendingHref(href)
  }, [isDirty])

  const confirmAction = useCallback((onConfirm: () => void) => {
    if (!isDirty) {
      onConfirm()
      return
    }
    pendingCallbackRef.current = onConfirm
    setPendingHref("__action__")
  }, [isDirty])

  function confirm() {
    setIsDirty(false)
    setPendingHref(null)
    pendingCallbackRef.current?.()
    pendingCallbackRef.current = null
  }

  function cancel() {
    setPendingHref(null)
    pendingCallbackRef.current = null
  }

  return (
    <UnsavedGuardContext.Provider value={{ isDirty, setDirty, requestNavigate, confirmAction }}>
      {children}
      {pendingHref !== null ? (
        <div className="modal-backdrop" onClick={cancel}>
          <div className="modal-card modal-card--sm" onClick={(e) => e.stopPropagation()}>
            <div className="modal-card__header modal-card__header--brand">
              <div className="modal-card__header-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
              </div>
              <div>
                <h3 className="modal-card__title">Cambios sin guardar</h3>
                <p className="modal-card__subtitle">Tienes cambios pendientes</p>
              </div>
            </div>
            <div className="modal-card__body">
              <p>Si sales ahora perderas los cambios que no has guardado. ¿Deseas continuar?</p>
            </div>
            <div className="modal-card__footer">
              <button type="button" className="secondary-button" onClick={cancel}>
                Seguir editando
              </button>
              <button type="button" className="danger-button" onClick={confirm}>
                Salir sin guardar
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </UnsavedGuardContext.Provider>
  )
}

export function useUnsavedGuard() {
  return useContext(UnsavedGuardContext)
}
