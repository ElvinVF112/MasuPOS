import { AppShell } from "@/components/pos/app-shell"
import { CatalogCategoriesScreen } from "@/components/pos/catalog-categories-screen"

export const dynamic = "force-dynamic"

export default async function CatalogCategoriesPage() {
  return (
    <AppShell>
      <section className="content-page">
        <CatalogCategoriesScreen />
      </section>
    </AppShell>
  )
}
