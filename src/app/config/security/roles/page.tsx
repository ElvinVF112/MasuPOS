import { AppShell } from "@/components/pos/app-shell"
import { SecurityRolesScreen } from "@/components/pos/security-roles-screen"
import { getSecurityManagerData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function SecurityRolesConfigPage() {
  const data = await getSecurityManagerData()

  return (
    <AppShell>
      <section className="content-page">
        <SecurityRolesScreen data={data} />
      </section>
    </AppShell>
  )
}
