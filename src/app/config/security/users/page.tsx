import { AppShell } from "@/components/pos/app-shell"
import { SecurityUsersScreen } from "@/components/pos/security-users-screen"
import { getSecurityManagerData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function SecurityUsersConfigPage() {
  const data = await getSecurityManagerData()

  return (
    <AppShell>
      <section className="content-page">
        <SecurityUsersScreen data={data} />
      </section>
    </AppShell>
  )
}
