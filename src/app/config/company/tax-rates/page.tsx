import { AppShell } from "@/components/pos/app-shell"
import { OrgTaxRatesScreen } from "@/components/pos/org-tax-rates-screen"
import { getTaxRates } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function TaxRatesPage() {
  const taxRates = await getTaxRates()
  return (
    <AppShell>
      <section className="content-page">
        <OrgTaxRatesScreen initialData={taxRates} />
      </section>
    </AppShell>
  )
}
