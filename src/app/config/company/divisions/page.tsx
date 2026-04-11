import { AppShell } from "@/components/pos/app-shell"
import { OrgDivisionsScreen } from "@/components/pos/org-divisions-screen"
import { getDivisions } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function DivisionsPage() {
  const divisions = await getDivisions()
  return (
    <AppShell>
      <section className="content-page">
        <OrgDivisionsScreen initialData={divisions} />
      </section>
    </AppShell>
  )
}
