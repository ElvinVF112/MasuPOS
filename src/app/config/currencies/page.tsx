import { AppShell } from "@/components/pos/app-shell"
import { CurrenciesScreen } from "@/components/pos/currencies-screen"

export const dynamic = "force-dynamic"

export default function CurrenciesPage() {
  return (
    <AppShell>
      <section className="content-page">
        <CurrenciesScreen />
      </section>
    </AppShell>
  )
}
