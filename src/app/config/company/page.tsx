import { CompanySettings } from "@/components/pos/company-settings"
import { getCompanySettingsData, getCurrencies } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function CompanyConfigPage() {
  const [company, currencies] = await Promise.all([
    getCompanySettingsData(),
    getCurrencies().catch(() => []),
  ])

  return (
    <section className="content-page">
        <CompanySettings initialData={company} currencies={currencies} />
      </section>
  )
}
