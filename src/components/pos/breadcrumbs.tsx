"use client"

import Link from "next/link"
import type { NavigationModule } from "@/lib/navigation"
import { getNavigationTrail } from "@/lib/navigation"

export function AppBreadcrumbs({ pathname, modules }: { pathname: string; modules: NavigationModule[] }) {
  const trail = getNavigationTrail(pathname, modules)

  if (!trail) return null

  return (
    <nav className="erp-breadcrumbs" aria-label="Breadcrumb">
      <Link href={trail.option.href}>{trail.module.label}</Link>
      <span>/</span>
      <span>{trail.category.label}</span>
      <span>/</span>
      <strong>{trail.option.label}</strong>
    </nav>
  )
}
