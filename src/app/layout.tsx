import type { Metadata } from "next"
import "./globals.css"
import { I18nProvider } from "@/lib/i18n"
import { PermissionsProvider } from "@/lib/permissions-context"
import { FormatProvider } from "@/lib/format-context"
import { GlobalToaster } from "@/components/pos/global-toaster"
import { RootShell } from "@/components/pos/root-shell"

export const metadata: Metadata = {
  title: "Masu POS V2",
  description: "Frontend moderno para la migracion de Masu POS.",
}

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="es">
      <body>
        <I18nProvider>
          <PermissionsProvider>
            <FormatProvider>
              <RootShell>{children}</RootShell>
              <GlobalToaster />
            </FormatProvider>
          </PermissionsProvider>
        </I18nProvider>
      </body>
    </html>
  )
}
