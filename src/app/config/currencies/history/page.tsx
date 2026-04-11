import { AppShell } from "@/components/pos/app-shell"
import { CurrencyHistoryScreen } from "@/components/pos/currency-history-screen"

export const dynamic = "force-dynamic"

export default function CurrencyHistoryPage() {
  return (
    <AppShell>
      <section className="content-page">
        <CurrencyHistoryScreen />
      </section>
    </AppShell>
  )
}
