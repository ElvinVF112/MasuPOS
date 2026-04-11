import { AppShell } from "@/components/pos/app-shell"
import { CurrencyRatesScreen } from "@/components/pos/currency-rates-screen"

export const dynamic = "force-dynamic"

export default function CurrencyRatesPage() {
  return (
    <AppShell>
      <section className="content-page">
        <CurrencyRatesScreen />
      </section>
    </AppShell>
  )
}
