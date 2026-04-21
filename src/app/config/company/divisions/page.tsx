import { OrgDivisionsScreen } from "@/components/pos/org-divisions-screen"
import { getDivisions } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function DivisionsPage() {
  const divisions = await getDivisions()
  return (
    <section className="content-page">
        <OrgDivisionsScreen initialData={divisions} />
      </section>
  )
}
