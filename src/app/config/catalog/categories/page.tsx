import { CatalogCategoriesScreen } from "@/components/pos/catalog-categories-screen"

export const dynamic = "force-dynamic"

export default async function CatalogCategoriesPage() {
  return (
    <section className="content-page">
        <CatalogCategoriesScreen />
      </section>
  )
}
