# Configuration Guide

You can change all runtime endpoints with a text editor.

## 1) API and DB configuration

Edit `.env.local` on the server:

```env
DATABASE_URL="Server=localhost;Database=DbMasuPOS;User Id=Masu;Password=...;TrustServerCertificate=True;MultipleActiveResultSets=True"
MASU_DEMO_USER_ID="1"
NEXT_PUBLIC_API_BASE_URL=""
```

- `DATABASE_URL`: SQL Server connection string used by the API layer.
- `MASU_DEMO_USER_ID`: fallback user id used by legacy operations.
- `NEXT_PUBLIC_API_BASE_URL`:
  - Empty (`""`) => front calls same host (`/api/...`).
  - Filled (example `"https://api.mycompany.com"`) => front calls external API host.

## 2) Deployment models

### Single app (current default)
- Deploy this Next.js app.
- Keep `NEXT_PUBLIC_API_BASE_URL=""`.

### Split front and API (your IIS style)
- Front host points to external API URL via `NEXT_PUBLIC_API_BASE_URL`.
- API host uses its own `DATABASE_URL`.
- Keep DB credentials only on API host.

## 3) Notes

- Restart the app process after editing `.env.local`.
- Do not commit real credentials to git.
- For split-domain cookies, configure HTTPS and CORS in API before production.
