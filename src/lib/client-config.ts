const rawApiBase = process.env.NEXT_PUBLIC_API_BASE_URL ?? ""

function normalizeBaseUrl(value: string) {
  const trimmed = value.trim()
  if (!trimmed) return ""
  return trimmed.endsWith("/") ? trimmed.slice(0, -1) : trimmed
}

const apiBaseUrl = normalizeBaseUrl(rawApiBase)

export function apiUrl(path: string) {
  const safePath = path.startsWith("/") ? path : `/${path}`
  return apiBaseUrl ? `${apiBaseUrl}${safePath}` : safePath
}
