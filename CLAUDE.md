# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Masu POS V2** — A full-stack Point of Sale system for restaurants/retail. Built with Next.js 16 (App Router) + React 19 + TypeScript, backed by SQL Server (`DbMasuPOS`).

## Commands

```bash
# Development
npm run dev        # Start dev server at localhost:3000
npm run build      # Production build
npm run start      # Start production server
npm run lint       # ESLint

# Database migrations: apply SQL scripts in /database/ sequentially (01, 02, ...)
# No automated migration runner — execute scripts manually via SSMS or sqlcmd
```

## Environment

Copy `.env.example` to `.env.local`:
```env
DATABASE_URL="Server=localhost;Database=DbMasuPOS;User Id=Masu;Password=...;TrustServerCertificate=True;MultipleActiveResultSets=True"
MASU_DEMO_USER_ID="1"
NEXT_PUBLIC_API_BASE_URL=""   # empty = same host; fill for split deployment
```

## Architecture

### Data Flow

```
Browser → middleware.ts (auth/permission check via cookies)
       → Next.js App Router page or API route
       → src/lib/pos-data.ts (data access layer, ~6000 lines)
       → src/lib/db.ts (MSSQL connection pool singleton → DbMasuPOS)
```

### Key Files

| File | Role |
|---|---|
| `src/lib/pos-data.ts` | Central data access layer — 100+ exported async functions for all CRUD operations. Add new DB queries here. |
| `src/lib/db.ts` | SQL Server pool. Exports `getPool()`, `sql`, and `TYPES`. Always import `TYPES` from here (not directly from `mssql`) to avoid webpack duplication issues. |
| `middleware.ts` | Edge middleware — validates `masu_session_id` + `masu_session_token` cookies, checks permission keys cookie against route requirements. Runs on every request. |
| `src/lib/permissions.ts` | Maps URL paths → permission keys. Add new routes here when creating protected pages/APIs. |
| `src/lib/auth-session.ts` | Session management: create, validate, close sessions via `SesionesActivas` table. |
| `src/lib/api-auth.ts` | Middleware for API routes to validate session server-side (used inside API handlers). |
| `src/lib/navigation.ts` | App navigation tree. Add entries here when adding new pages. |
| `src/lib/i18n.tsx` | i18n context with ES/EN translations. Use `useI18n()` hook in components. |

### Module Structure

Pages live in `src/app/<module>/page.tsx` and render a single screen component from `src/components/pos/`. API routes for each module live in `src/app/api/<module>/`.

Modules: `dashboard`, `orders`, `catalog`, `cash-register`, `dining-room`, `cxc` (receivables), `cxp` (payables), `inventory`, `reports`, `queries`, `config`, `security`.

### Authentication & Permissions

- Login via `POST /api/auth/login` → calls `spAuthLogin` stored procedure → sets three cookies: `masu_session_id`, `masu_session_token`, `masu_permission_keys`.
- Middleware reads cookies and calls `getPermissionKeyByPath(pathname)` — if a permission is required and not in the cookie, it returns 401/403.
- Public paths (no auth): `/login`, `/api/auth/login`, `/api/auth/logout`, `/api/auth/me`, `/api/company/public`, `/api/company/logo/public`.
- When adding a new protected page: register its permission key in `src/lib/permissions.ts`, and add it to the DB tables `Pantallas` + `RolPantallaPermisos`.

### Database Conventions

- Stored procedures follow the pattern `sp<Entity>CRUD` (e.g., `spProductosCRUD`, `spOrdenesCRUD`).
- New DB migrations go in `database/` as sequentially numbered `.sql` files.
- The pool singleton is stored on `globalThis.masuPool` to survive Next.js hot-reload in dev.

### Adding a New API Route

1. Create `src/app/api/<module>/<entity>/route.ts`.
2. Call `validateApiSession(request)` from `@/lib/api-auth` at the top of each handler.
3. Add the DB query function to `src/lib/pos-data.ts`.
4. Register the route permission in `src/lib/permissions.ts` if it needs access control.

### Adding a New Page Module

1. Create `src/app/<module>/page.tsx` (render a component from `src/components/pos/`).
2. Add the route to `src/lib/navigation.ts`.
3. Register the permission key in `src/lib/permissions.ts`.

## Project Tracking

- `SESSION_HISTORY.md` — log of completed work per session.
- `OPENCODE_TASKS.md` — ongoing task backlog.
- `QA_CHECKLIST_PHASE1.md` — QA status per module.
- `database/` — numbered SQL migration scripts (applied manually).
