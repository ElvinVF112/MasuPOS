"use client"

import { usePathname } from "next/navigation"

import { AppShell } from "@/components/pos/app-shell"

type RootShellProps = {
  children: React.ReactNode
}

const SHELL_EXCLUDED_ROUTES = ["/login"]

export function RootShell({ children }: RootShellProps) {
  const pathname = usePathname()

  if (SHELL_EXCLUDED_ROUTES.some((route) => pathname === route || pathname.startsWith(`${route}/`))) {
    return <>{children}</>
  }

  return <AppShell>{children}</AppShell>
}
