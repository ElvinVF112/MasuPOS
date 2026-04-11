import { AppShell } from "@/components/pos/app-shell"
import { DiningRoomFloorView } from "@/components/pos/dining-room-floor-view"
import { getDiningRoomManagerData } from "@/lib/pos-data"

export const dynamic = "force-dynamic"

export default async function DiningRoomPage() {
  const diningRoom = await getDiningRoomManagerData()

  return (
    <AppShell>
      <section className="content-page">
        <DiningRoomFloorView data={diningRoom} />
      </section>
    </AppShell>
  )
}
