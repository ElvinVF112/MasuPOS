import { redirect } from "next/navigation"

export default function SecurityPage() {
  redirect("/config/security/users")
}
