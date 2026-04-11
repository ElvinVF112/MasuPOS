import Link from "next/link"
import { AppShell } from "@/components/pos/app-shell"
import { PageHeader } from "@/components/pos/page-header"
import { SecurityManager } from "@/components/pos/security-manager"
import { getSecurityManagerData } from "@/lib/pos-data"

type SecuritySection = "users" | "roles" | "modules" | "screens" | "permissions" | "roles-permissions"

const items: Array<{ key: SecuritySection; label: string; href: string }> = [
  { key: "users", label: "Usuarios", href: "/config/security/users" },
  { key: "roles", label: "Roles", href: "/config/security/roles" },
  { key: "modules", label: "Módulos", href: "/config/security/modules" },
  { key: "screens", label: "Pantallas", href: "/config/security/screens" },
  { key: "permissions", label: "Permisos", href: "/config/security/permissions" },
  { key: "roles-permissions", label: "Roles y Permisos", href: "/config/security/roles-permissions" },
]

export async function SecurityConfigScreen({ section }: { section: SecuritySection }) {
  const manager = await getSecurityManagerData()

  const sectionMap: Record<SecuritySection, Array<"users" | "roles" | "permissions" | "role-permissions" | "modules" | "screens">> = {
    users: ["users"],
    roles: ["roles"],
    modules: ["modules"],
    screens: ["screens"],
    permissions: ["permissions"],
    "roles-permissions": ["role-permissions"],
  }

  return (
    <AppShell>
      <section className="content-page">
        <PageHeader title="Configuración · Seguridad" description="Pantalla unificada para administrar usuarios, roles y permisos del sistema." />

        <div className="config-subnav">
          {items.map((item) => (
            <Link key={item.key} href={item.href} className={section === item.key ? "config-pill is-active" : "config-pill"}>
              {item.label}
            </Link>
          ))}
        </div>

        <SecurityManager data={manager} sections={sectionMap[section]} />
      </section>
    </AppShell>
  )
}
