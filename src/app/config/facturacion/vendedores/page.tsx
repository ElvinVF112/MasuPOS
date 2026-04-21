import { FacVendedoresScreen } from "@/components/pos/fac-vendedores-screen"
import { getVendedores } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function VendedoresPage() {
  const data = await getVendedores()
  return (
    <section className="content-page">
        <FacVendedoresScreen initialData={data} />
      </section>
  )
}
