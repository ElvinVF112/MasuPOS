"use client"

import type { ReactNode } from "react"
import { Trash2 } from "lucide-react"

type DeleteConfirmModalProps = {
  open: boolean
  entityLabel: string
  itemName: string
  onCancel: () => void
  onConfirm: () => void
  confirmLabel?: string
  children?: ReactNode
}

export function DeleteConfirmModal({
  open,
  entityLabel,
  itemName,
  onCancel,
  onConfirm,
  confirmLabel = "Eliminar",
  children,
}: DeleteConfirmModalProps) {
  if (!open) return null

  return (
    <div className="modal-backdrop" onClick={onCancel}>
      <div className="modal-card modal-card--sm" onClick={(event) => event.stopPropagation()}>
        <div className="modal-card__header modal-card__header--brand">
          <div className="modal-card__header-icon">
            <Trash2 size={18} />
          </div>
          <div>
            <h3 className="modal-card__title">Eliminar</h3>
            <p className="modal-card__subtitle">{entityLabel}</p>
          </div>
        </div>
        <div className="modal-card__body">
          {children ?? (
            <p>
              Se eliminará {entityLabel.toLowerCase()} <strong>{itemName}</strong>. Esta acción no se puede deshacer.
            </p>
          )}
        </div>
        <div className="modal-card__footer">
          <button type="button" className="secondary-button" onClick={onCancel}>
            Cancelar
          </button>
          <button type="button" className="danger-button" onClick={onConfirm}>
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  )
}
