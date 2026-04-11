import { AppShell } from "@/components/pos/app-shell"
import { DiningRoomManager } from "@/components/pos/dining-room-manager"
import { DiningRoomMastersManager } from "@/components/pos/dining-room-masters-manager"
import { getDiningMastersData, getDiningRoomManagerData } from "@/lib/pos-data"

type DiningSection = "resources" | "areas" | "resource-types" | "resource-categories"

export async function DiningRoomConfigScreen({ section }: { section: DiningSection }) {
  const [dining, masters] = await Promise.all([getDiningRoomManagerData(), getDiningMastersData()])

  return (
    <AppShell>
      <section className="content-page salon-config-page">
        {section === "resources" ? <DiningRoomManager data={dining} showBoard={false} /> : null}
        {section === "areas" ? <DiningRoomMastersManager data={masters} sections={["areas"]} /> : null}
        {section === "resource-types" ? <DiningRoomMastersManager data={masters} sections={["resource-types"]} /> : null}
        {section === "resource-categories" ? <DiningRoomMastersManager data={masters} sections={["resource-categories"]} /> : null}
      </section>
    </AppShell>
  )
}
