import { AppShell } from "@/components/pos/app-shell"
import { BillingPosScreen } from "@/components/pos/billing-pos-screen"
import { getBranches, getCategories, getCatalogoNCF, getCompanySettingsData, getCurrencies, getCustomers, getDescuentos, getEmissionPoints, getFacTiposDocumento, getProductsForOrderCapture, getWarehouses } from "@/lib/pos-data"

export default async function BillingPosPage() {
  const [company, branches, emissionPoints, customers, categories, products, documentTypes, taxVoucherTypes, currencies, warehouses, discounts] = await Promise.all([
    getCompanySettingsData(),
    getBranches().catch(() => []),
    getEmissionPoints().catch(() => []),
    getCustomers().catch(() => []),
    getCategories().catch(() => []),
    getProductsForOrderCapture().catch(() => []),
    getFacTiposDocumento("F").catch(() => []),
    getCatalogoNCF().catch(() => []),
    getCurrencies().catch(() => []),
    getWarehouses().catch(() => []),
    getDescuentos().catch(() => []),
  ])

  return (
    <AppShell>
      <BillingPosScreen
        company={company}
        branches={branches}
        emissionPoints={emissionPoints}
        customers={customers}
        categories={categories}
        products={products}
        documentTypes={documentTypes}
        taxVoucherTypes={taxVoucherTypes}
        currencies={currencies}
        warehouses={warehouses}
        discounts={discounts}
      />
    </AppShell>
  )
}
