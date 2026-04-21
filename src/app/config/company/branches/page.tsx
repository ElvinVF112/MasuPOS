import { OrgBranchesScreen } from "@/components/pos/org-branches-screen"
import { getBranches, getDivisions } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function BranchesPage() {
  const [branches, divisions] = await Promise.all([getBranches(), getDivisions()])
  return (
    <section className="content-page">
        <OrgBranchesScreen initialData={branches} divisions={divisions} />
      </section>
  )
}
