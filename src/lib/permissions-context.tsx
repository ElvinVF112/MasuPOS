"use client"

import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react"
import { apiUrl } from "@/lib/client-config"

type PermissionsContextValue = {
  permissions: string[]
  isLoading: boolean
  hasPermission: (permissionKey: string) => boolean
  refreshPermissions: () => Promise<void>
  setPermissions: (permissionKeys: string[]) => void
}

const PermissionsContext = createContext<PermissionsContextValue | null>(null)

export function PermissionsProvider({ children }: { children: ReactNode }) {
  const [permissions, setPermissionsState] = useState<string[]>([])
  const [isLoading, setIsLoading] = useState(true)

  async function refreshPermissions() {
    setIsLoading(true)
    try {
      const response = await fetch(apiUrl("/api/auth/permissions"), { cache: "no-store", credentials: "include" })
      if (!response.ok) {
        setPermissionsState([])
        return
      }

      const result = (await response.json()) as { ok: boolean; permissions?: string[] }
      setPermissionsState(result.ok ? (result.permissions ?? []) : [])
    } catch {
      setPermissionsState([])
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    void refreshPermissions()
  }, [])

  const value = useMemo<PermissionsContextValue>(
    () => ({
      permissions,
      isLoading,
      hasPermission: (permissionKey: string) => permissions.includes(permissionKey),
      refreshPermissions,
      setPermissions: (permissionKeys: string[]) => setPermissionsState(permissionKeys),
    }),
    [permissions, isLoading],
  )

  return <PermissionsContext.Provider value={value}>{children}</PermissionsContext.Provider>
}

export function usePermissions() {
  const context = useContext(PermissionsContext)
  if (!context) {
    throw new Error("usePermissions must be used within PermissionsProvider")
  }
  return context
}
