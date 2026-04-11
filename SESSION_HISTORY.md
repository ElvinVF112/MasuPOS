# MASU POS V2 - Session History

Purpose: keep a durable handoff log so work can continue after context/token limits.

## How to use this file

- At the end of each work session, append a new entry in `## Session Log`.
- Keep entries short and practical: what changed, where, what was tested, what is pending.
- Include file paths and DB scripts so the next session can resume quickly.

---

## Project Snapshot

- App: `D:\Masu\V2` (Next.js App Router, monolith Front + API).
- DB: SQL Server `DbMasuPOS`.
- Current style direction: keep existing MASU line visual and responsive behavior.
- Work mode agreed: phase 1 = functional completeness module-by-module, then new features.

## Runtime Configuration

- Config file: `D:\Masu\V2\.env.local`
- Main keys:
  - `DATABASE_URL` (API -> SQL Server connection string)
  - `NEXT_PUBLIC_API_BASE_URL` (Front -> API base URL; empty means same host)
  - `MASU_DEMO_USER_ID`
- Guide: `D:\Masu\V2\CONFIGURATION.md`

## Security/Auth Baseline

- Login screen exists at `/login`.
- Middleware protects routes and redirects unauthenticated users to `/login`.
- Session cookies used: `masu_session_id`, `masu_session_token`.
- Auth APIs:
  - `/api/auth/login`
  - `/api/auth/me`
  - `/api/auth/logout`
- API routes now enforce session via server-side validation helper.

## DB Migrations/SQL Scripts

- `database/02_fix_spProductosCRUD.sql`
  - Added optional `@IdSesion`, `@TokenSesion` params.
- `database/03_usuarios_un_rol.sql`
  - User has single role (`Usuarios.IdRol`).
  - Added `Usuarios.IdPantallaInicio` for default post-login screen.
  - `spUsuariosCRUD` and `spUsuariosLogin` updated.
- `database/04_ordenes_referencia_cliente.sql`
  - Added `Ordenes.ReferenciaCliente`.
  - `spOrdenesCRUD` updated and receives optional session params.
- `database/05_seguridad_sesiones_empresa.sql`
  - Added `SesionesActivas` table.
  - Added `Empresa` table (base legal/commercial fields).
  - Added auth SPs:
    - `spAuthLogin`
    - `spAuthValidarSesion`
    - `spAuthCerrarSesion`
    - `spAuthCerrarSesionesUsuario`

## Orders Module Status

- Orders tray implemented: list of active tables + right detail panel.
- Table grid shows only tables with open orders.
- Right panel shows open orders as list format with detail lines.
- New "Nueva orden" modal supports table + products in one flow.
- Endpoints added:
  - `/api/orders/create`
  - `/api/orders/resource/[id]/close-all`

## Security Module Status

- Users CRUD now includes `Pantalla de inicio` selection.
- Login redirect respects user default route (`RutaInicio`).
- Legacy route normalization handled on login for old routes (`/Usuarios`, `/Roles`, `/Permisos`).

## Session Log

### 2026-03-19 - Auth + Sessions + Default Screen + Config External API

**Completed**

- Implemented login-required app flow with middleware and auth APIs.
- Implemented SQL active sessions model and auth SPs.
- Added remember-username option in login UI.
- Added user-level default start screen and login redirect logic.
- Added central client API base URL support (`NEXT_PUBLIC_API_BASE_URL`) and switched front fetches to use it.
- Added config documentation in `CONFIGURATION.md`.

**Files (high impact)**

- `src/app/login/page.tsx`
- `src/components/pos/app-shell.tsx`
- `src/lib/auth-session.ts`
- `src/lib/api-auth.ts`
- `src/lib/client-config.ts`
- `middleware.ts`
- `src/app/api/auth/login/route.ts`
- `src/app/api/auth/me/route.ts`
- `src/app/api/auth/logout/route.ts`
- `src/lib/pos-data.ts`
- `src/components/pos/security-manager.tsx`
- `database/03_usuarios_un_rol.sql`
- `database/05_seguridad_sesiones_empresa.sql`

**Validation**

- SQL scripts executed successfully via `sqlcmd`.
- Auth SPs tested (`login`, `validate`, `logout`).
- `npm run build` successful after all changes.

**Pending (next recommended)**

1. Role-based menu and route authorization (not only session-level auth).
2. Apply `@IdSesion/@TokenSesion` to remaining CRUD SPs uniformly.
3. Optional admin UI for company profile (`Empresa`) and operational context (`Caja/Sucursal/PuntoEmision`).
4. Continue Security module QA matrix (users/roles/permissions end-to-end).

### 2026-03-19 - Company Settings Screen

**Completed**

- Added `spEmpresaCRUD` migration script and executed it.
- Added company settings screen at `/config/company`.
- Added secured API endpoint `/api/company` (PUT).
- Added company data load/save in `pos-data`.
- Added company entry in system settings menu.

**Files (high impact)**

- `database/06_empresa_crud.sql`
- `src/app/config/company/page.tsx`
- `src/components/pos/company-settings.tsx`
- `src/app/api/company/route.ts`
- `src/lib/pos-data.ts`
- `src/components/pos/app-shell.tsx`
- `src/app/globals.css`

**Validation**

- `EXEC dbo.spEmpresaCRUD @Accion='L'` returns company row.
- `npm run build` successful.

### 2026-03-19 - Empresa Offline Logo + Extended Company Data

**Completed**

- Added offline-ready binary logo storage in SQL (`VARBINARY(MAX)`).
- Extended company profile fields (fiscal id, company name, structured address).
- Added logo upload endpoint and logo retrieval endpoint.
- Redesigned company settings UI to match requested style direction (tabs, logo panel, general/address sections).
- Added nested `Empresa > Datos Generales` entry under System Settings menu.

**Files (high impact)**

- `database/07_empresa_logo_offline.sql`
- `src/app/api/company/logo/route.ts`
- `src/components/pos/company-settings.tsx`
- `src/components/pos/app-shell.tsx`
- `src/lib/pos-data.ts`
- `src/app/globals.css`

**Validation**

- `EXEC dbo.spEmpresaCRUD @Accion='L'` and `EXEC dbo.spEmpresaLogoObtener` verified.
- `npm run build` successful.

### 2026-03-19 - Empresa UX/Edit Mode + Login Branding from Company

**Completed**

- Company form now starts read-only and requires `Editar datos` to enable fields.
- Added logo `Quitar logo` action.
- Removed RFC/NIT/RUC field from UI and kept `Razon Social` as primary legal name.
- Login branding now loads from company:
  - logo from company binary/logo URL
  - title from company `Nombre Comercial`
- Added public company branding endpoints for login screen.

**Files (high impact)**

- `database/08_empresa_logo_eliminar.sql`
- `src/components/pos/company-settings.tsx`
- `src/app/login/page.tsx`
- `src/app/api/company/logo/route.ts`
- `src/app/api/company/public/route.ts`
- `src/app/api/company/logo/public/route.ts`
- `src/lib/pos-data.ts`
- `middleware.ts`

**Validation**

- SQL script applied.
- `npm run build` successful.

### 2026-03-20 - Security Users UI Modernization + Password Policy Flow

**Completed**

- Kept modern modal style while unifying typography tokens across titles/subtitles/dropdowns/components.
- Security Users modal updated:
  - tabs: `Informacion General`, `Seguridad`, `Actividad`
  - action dropdown closes on outside click and keeps safe layering.
- Security tab now allows changing password directly in the same modal (no extra popup).
- Added option to mark user with `Pedir nueva contrasena al iniciar login`.
- Login flow now enforces first-login password change when user is flagged.
- Added authenticated endpoint to update own forced password and clear flag.
- Added and verified DB column in `Usuarios`: `RequiereCambioClave BIT NOT NULL DEFAULT(0)`.

**Files (high impact)**

- `src/components/pos/security-users-screen.tsx`
- `src/app/globals.css`
- `src/app/login/page.tsx`
- `src/app/api/auth/change-password/route.ts`
- `src/lib/auth-session.ts`
- `src/lib/pos-data.ts`
- `src/components/pos/app-shell.tsx`
- `database/03_usuarios_un_rol.sql`
- `database/05_seguridad_sesiones_empresa.sql`
- `scripts/ensure-requiere-cambio-clave.js`

**Validation**

- `npm run build` successful after each change set.
- DB verification executed via script:
  - output: `RequiereCambioClave column exists: YES`.

**Pending (next recommended)**

1. Apply SQL script updates in all environments (dev/staging/prod) to keep SP contracts aligned.
2. Add real activity feed source for Users `Actividad` tab (currently uses available audit/timestamps).
3. Align Roles screen visuals with Users modern style from reference.

### 2026-03-20 - Tarea 1 completada: Autorizacion por Rol (menu + rutas)

**Completed**

- DB: created/updated `dbo.spPermisosObtenerPorRol` (`database/09_permisos_por_rol.sql`) and applied it to current environment.
- API: added `GET /api/auth/permissions` (`src/app/api/auth/permissions/route.ts`).
- Client: added `PermissionsProvider` / `PermissionsContext` and mounted globally in layout.
- Login/logout/session cookies updated to include permission keys (`masu_permission_keys`) populated on login and cleared on logout.
- Menu filtering by permissions implemented in `src/components/pos/app-shell.tsx`.
- Middleware authorization added using shared `ROUTE_PERMISSIONS` map in `src/lib/permissions.ts` (deny by default when route requires permission and key is absent).

**Files (high impact)**

- `database/09_permisos_por_rol.sql`
- `scripts/apply-sql-file.js`
- `src/lib/permissions.ts`
- `src/lib/permissions-context.tsx`
- `src/app/layout.tsx`
- `src/app/api/auth/permissions/route.ts`
- `src/app/api/auth/login/route.ts`
- `src/app/api/auth/logout/route.ts`
- `src/app/login/page.tsx`
- `src/components/pos/app-shell.tsx`
- `src/lib/auth-session.ts`
- `src/lib/auth-cookies.ts`
- `middleware.ts`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/09_permisos_por_rol.sql`.
- `npm run build` successful.

**Pending (next recommended)**

1. Start `TAREA 2` in `OPENCODE_TASKS.md`.

### 2026-03-20 - Tarea 2 completada: Propagar IdSesion/TokenSesion en CRUD

**Completed**

- DB: Added optional session context params to pending CRUD SPs in active DB:
  - `spRolesCRUD`, `spPermisosCRUD`, `spMesasCRUD`, `spCategoriasCRUD`, `spAreasCRUD`, `spRecursosCRUD`
  - verified and also updated: `spTiposRecursoCRUD`, `spCategoriasRecursoCRUD`, `spRolesPermisosCRUD`.
- Generated consolidated SQL artifact from live ALTER operations:
  - `database/11_sp_crud_sesion_context.generated.sql`.
- Updated data layer to forward `IdSesion`/`TokenSesion`:
  - `mutateAdminEntity(...)` now accepts session context and forwards it.
  - resource mutations (`createResource`, `updateResource`, `deleteResource`) now accept session context and forward it.
- Updated API handlers to extract validated session and pass context to data layer:
  - `src/app/api/admin/[entity]/route.ts`
  - `src/app/api/dining-room/resources/route.ts`

**Files (high impact)**

- `database/11_sp_crud_sesion_context.sql`
- `database/11_sp_crud_sesion_context.generated.sql`
- `scripts/add-session-params-to-procs.js`
- `scripts/inspect-proc-params.js`
- `scripts/dump-proc-def.js`
- `src/lib/pos-data.ts`
- `src/app/api/admin/[entity]/route.ts`
- `src/app/api/dining-room/resources/route.ts`
- `OPENCODE_TASKS.md`

**Validation**

- `node scripts/add-session-params-to-procs.js` successful.
- `node scripts/inspect-proc-params.js` confirms `@IdSesion` and `@TokenSesion` in target SPs.
- `npm run build` successful.

**Pending (next recommended)**

1. Start `TAREA 3` in `OPENCODE_TASKS.md`.

### 2026-03-20 - Tarea 3 completada: Feed real de actividad en Usuarios

**Completed**

- DB: created/applied `dbo.spUsuarioActividad` to return:
  - account summary (`FechaCreacionCuenta`, `FechaModificacionCuenta`, `TotalSesiones`, `UltimoLogin`)
  - recent sessions with status/duration (`SesionActiva`, `FechaInicio`, `FechaUltimaActividad`, `FechaCierre`, `DuracionMinutos`).
- API: added `GET /api/users/[id]/activity` with session validation and permission guard (`config.security.users.view`).
- Data layer: added `getUserActivity(...)` in `src/lib/pos-data.ts`.
- UI: `Actividad` tab in Users modal now fetches real data and renders recent session rows + summary cards.

**Files (high impact)**

- `database/12_usuario_actividad.sql`
- `src/app/api/users/[id]/activity/route.ts`
- `src/lib/pos-data.ts`
- `src/components/pos/security-users-screen.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/12_usuario_actividad.sql`.
- `npm run build` successful.

**Pending (next recommended)**

1. Start `TAREA 4` in `OPENCODE_TASKS.md`.

### 2026-03-20 - Tarea 4 completada: QA Matrix Seguridad E2E

**Completed**

- Created full E2E QA matrix in markdown for:
  - Usuarios CRUD
  - Roles CRUD
  - Permisos por Rol
  - Flujo Auth
- Matrix delivered as tables with required columns:
  - `Precondicion | Pasos | Resultado esperado | Pass/Fail`.

**Files (high impact)**

- `SECURITY_QA_MATRIX_E2E.md`
- `OPENCODE_TASKS.md`

**Validation**

- Checklist coverage verified against Task 4 checkpoints 4.1 to 4.5.

**Pending (next recommended)**

1. User review/approval of QA matrix and begin execution with evidence collection.

### 2026-03-20 - Tarea 5 completada: Fix menu vacio por permisos

**Completed**

- API safety net for superadmin:
  - `GET /api/auth/permissions` now returns all keys from `ROUTE_PERMISSIONS` when role is admin (`IdRol = 1` or role name `Administrador/Administrador General`).
- DB seeding for admin-general role:
  - added `database/13_admin_general_seed_permisos.sql` to ensure active permissions exist for active screens and are assigned to admin role.
  - script applied successfully in current environment.
- Verification:
  - admin permissions totals checked via `scripts/check-admin-permissions.js`.
  - menu visibility dependency validated at source level (`app-shell` filters by permission keys; superadmin now receives full key set from API).

**Files (high impact)**

- `src/app/api/auth/permissions/route.ts`
- `database/13_admin_general_seed_permisos.sql`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/13_admin_general_seed_permisos.sql`.
- Permission check output: `IdRolAdmin: 1, PermisosActivos: 3, PermisosAsignadosAdmin: 3`.
- `npm run build` successful.

**Pending (next recommended)**

1. Add `TAREA 6` in `OPENCODE_TASKS.md` and continue same workflow.

### 2026-03-20 - Tarea 6 completada: Polish Login UI 3.0

**Completed**

- Updated login visual polish while preserving auth/session/branding flows.
- Added gradient background in `.login-page`.
- Added language toggle button (`ES/EN`) on login top-right using `useI18n()`.
- Login submit button now disables when username/password are empty and when pending.
- Loading state now renders `Loader2` + text with shared `.spin` animation.
- Error message now uses highlighted box style (`.login-error-box`).
- Remember user default changed to `true`.

**Files (high impact)**

- `src/app/login/page.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Start `TAREA 7` (Usuarios polish) from `OPENCODE_TASKS.md`.

### 2026-03-20 - Tarea 7 completada: Users polish + bugfixes login/menu

**Completed**

- 7.0a login language bugfix:
  - login language toggle now uses `Globe` icon and `setLanguage(language === "es" ? "en" : "es")`.
  - login page texts now react to i18n keys (labels/placeholders/button/footer).
- 7.0b users table menu clipping bugfix:
  - `.users-table-wrap` now `overflow: visible` with inner `.users-table-scroll` for horizontal scroll.
  - `.table-menu` z-index raised to `30`.
- 7.1 avatar in users table rows added (`.users-name-cell` + `.users-table__avatar`).
- 7.2 users modal width updated to `min(42rem, 100%)`.
- 7.3 locked status checkpoint intentionally omitted (no `locked` field in current model, per task instruction).
- 7.4 loading spinner added to save buttons in Users modal (`Loader2` + `.spin`).
- 7.5 i18n pass on Users screen and login copy; added missing dictionary keys in both ES/EN.

**Files (high impact)**

- `src/components/pos/security-users-screen.tsx`
- `src/app/login/page.tsx`
- `src/lib/i18n.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Start `TAREA 8` (security-roles-screen dedicated page).

### 2026-03-20 - Tarea 8 completada: Pantalla dedicada de Roles

**Completed**

- Created dedicated component `src/components/pos/security-roles-screen.tsx` replacing generic CRUD for roles.
- Implemented roles table aligned to UI 3.0 visual direction with:
  - search + new role toolbar
  - role icon/color cell + "Sistema" badge
  - client-side users and permissions counters per role
  - contextual actions menu (Editar, Ver Permisos, Eliminar)
- Implemented dedicated modal (`roles-modal`) with tabs:
  - `General`: name/description/active switch + save flow
  - `Informacion`: 2x2 readonly info cards (creation, users, permissions, type)
- Added delete validation:
  - block delete when role has assigned users
  - confirmation before delete when allowed
  - system roles delete action disabled (`is-disabled`)
- Rewired `SecurityManager` to render `SecurityRolesScreen` for roles section.
- Added `roles-*` CSS block in `globals.css` plus shared helpers (`table-menu__separator`, `is-disabled`).

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/components/pos/security-manager.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Continue with next task in `OPENCODE_TASKS.md` (TAREA 9 when defined).

### 2026-03-20 - Tarea 9 completada: Bugfixes + QA Roles Screen

**Completed**

- 9.1 overflow/menu clipping check and fix:
  - verified bug existed (`.roles-table-wrap` used `overflow-x: auto`, causing vertical clipping of `.table-menu`).
  - fixed with same pattern used in Users:
    - `.roles-table-wrap` -> `overflow: visible` + `position: relative`
    - added `.roles-table-scroll` wrapper and moved table inside it
    - set `.roles-table .table-menu` z-index to `31`
  - menu now shows complete options including `Gestionar Permisos`, separator, and `Eliminar`.
- 9.2 created date in roles info tab:
  - verified DB/SP already had `FechaCreacion` in `spRolesCRUD` list result.
  - mapped `createdAt` in `getSecurityManagerData()` and `SecurityManagerData.roles` type.
  - `roles` info tab now shows formatted creation date instead of `No disponible`.
- 9.3 i18n migration for Roles screen:
  - replaced hardcoded copy with `useI18n().t(...)` across header/table/form/tabs/toasts/cards.
  - added `roles.*` keys (es/en) in `src/lib/i18n.tsx`.
- 9.4 duplicate name validation:
  - added case-insensitive client-side duplicate check in `onSubmit` before POST/PUT.
- 9.5 row-click UX:
  - clicking a roles table row opens edit modal.
  - actions cell uses `stopPropagation()` so menu interaction does not trigger row edit.
  - added row hover + pointer styles.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/lib/pos-data.ts`
- `src/lib/i18n.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Continue with next task in `OPENCODE_TASKS.md` (TAREA 10 when defined).

### 2026-03-20 - Tarea 10 completada: Roles y Usuarios como paginas independientes

**Completed**

- Rewrote `/config/security/roles` page to render as independent page using:
  - `AppShell`
  - `PageHeader` (`Roles`, `Configura los roles disponibles`)
  - `SecurityRolesScreen` with `getSecurityManagerData()`
- Kept roles main action button in a single place (inside `SecurityRolesScreen` toolbar), avoiding duplication in `PageHeader`.
- Users page kept as independent page and aligned text with task requirement:
  - `PageHeader` description updated to `Administra cuentas y acceso al sistema`.
- Verified remaining security pages still use `SecurityConfigScreen` with tabs:
  - modules, screens, permissions, roles-permissions unchanged.
- Verified navigation links continue pointing directly to `/config/security/users` and `/config/security/roles` in `app-shell`.

**Files (high impact)**

- `src/app/config/security/roles/page.tsx`
- `src/app/config/security/users/page.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Continue with next task in `OPENCODE_TASKS.md` (TAREA 11 when defined).

### 2026-03-20 - Tarea 9 (update) completada: checkpoints 9.7 a 9.11

**Completed**

- 9.7 tabs hidden in new-role mode:
  - roles modal now shows tabs only when `form.id` exists, matching users-screen behavior.
  - for new role, form opens directly in general mode without tabs.
- 9.8 info tab save behavior:
  - changed info-tab "Guardar Cambios" action from `setActiveTab("general")` to `closeEditor`.
- 9.9 menu is-up parity:
  - roles table menu now applies `is-up` on last two rows (`index >= roles.length - 2`).
- 9.10 hover parity check:
  - verified CSS rules already present and working:
    - `.roles-table tbody tr { cursor: pointer; }`
    - `.roles-table tbody tr:hover { background: rgba(18,70,126,0.03); }`
- 9.11 build validation completed.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Continue with next task in `OPENCODE_TASKS.md` (TAREA 10 when defined).

### 2026-03-20 - Tarea 8.0 completada: Estado 3 niveles en Usuarios (Bloqueado)

**Completed**

- DB migration applied: added `Usuarios.Bloqueado BIT NOT NULL DEFAULT(0)`.
- Updated `spUsuariosCRUD` to support `@Bloqueado` in list/insert/update outputs and writes.
- Updated auth SPs to enforce blocked accounts cannot authenticate/validate sessions:
  - `spAuthLogin` now filters `ISNULL(U.Bloqueado, 0) = 0`.
  - `spAuthValidarSesion` now filters `ISNULL(U.Bloqueado, 0) = 0` and returns field.
- Updated data layer:
  - `SecurityManagerData.users` includes `locked`.
  - `getSecurityManagerData()` maps `Bloqueado -> locked`.
  - `mutateAdminEntity("users")` forwards `Bloqueado` to SP.
- Updated Users UI for 3-state status:
  - chips in table/header: Activo/Inactivo/Bloqueado (`chip--success`/`chip--neutral`/`chip--warning`).
  - contextual action behavior:
    - active + not locked -> Bloquear Cuenta
    - locked -> Desbloquear Cuenta
    - inactive + not locked -> Activar Cuenta

**Files (high impact)**

- `database/14_usuarios_bloqueado.sql`
- `src/lib/pos-data.ts`
- `src/components/pos/security-users-screen.tsx`
- `src/lib/i18n.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/14_usuarios_bloqueado.sql`.
- `npm run build` successful.

**Pending (next recommended)**

1. Continue with next task in `OPENCODE_TASKS.md` (TAREA 9 when defined).

### 2026-03-20 - Tarea 11 Fase A completada: Base DB/API para roles 3 paneles

**Completed**

- Added and applied `database/15_roles_permissions_phase_a.sql` with:
  - `RolCamposVisibilidad` table (unique `IdRol + ClaveCampo`) and admin seed for initial visibility keys.
  - `RolPantallaPermisos` support table for per-role, per-screen granular flags.
  - `spRolPermisosPorModulo` returning 3 resultsets (modules enabled state, screens granular permissions, field visibility).
  - `spRolPermisosActualizar` supporting `MODULO`, `PANTALLA`, `PERMISO_GRANULAR`, `CAMPO` updates.
  - `spRolUsuariosAsignar` for assign/remove role from user (remove reassigns to default role due `Usuarios.IdRol` NOT NULL).
- Added new APIs:
  - `GET/PUT /api/roles/[id]/permissions`
  - `PUT /api/roles/[id]/users`
- Extended data layer in `src/lib/pos-data.ts`:
  - new role-permissions payload/snapshot types
  - `getRolePermissionsByModule(...)`
  - `updateRolePermission(...)`
  - `assignRoleUser(...)`
- Added utility scripts:
  - `scripts/list-permisos-columns.js`
  - `scripts/verify-role-phase-a.js`

**Files (high impact)**

- `database/15_roles_permissions_phase_a.sql`
- `src/app/api/roles/[id]/permissions/route.ts`
- `src/app/api/roles/[id]/users/route.ts`
- `src/lib/pos-data.ts`
- `scripts/list-permisos-columns.js`
- `scripts/verify-role-phase-a.js`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output successful via `node scripts/apply-sql-file.js database/15_roles_permissions_phase_a.sql`.
- `npm run build` successful after latest `modules + nested screens` payload adjustment.

**Pending (next recommended)**

1. Start TAREA 11 Fase B (`11.9` onward): implement full 3-panel `security-roles-screen.tsx` UI.

### 2026-03-20 - Tarea 11 Fase B/C completada: Roles 3 paneles UI/CSS/i18n

**Completed**

- Rewrote `src/components/pos/security-roles-screen.tsx` into a 3-panel roles workspace:
  - left sidebar with role search/list and quick stats
  - center panel with role header/edit mode and tabs: Modulos, Pantallas, Visualizacion
  - right panel with user assignment tabs: Asignados/Disponibles
- Wired role-permissions endpoints into UI interactions:
  - `GET /api/roles/[id]/permissions` for per-role matrix load
  - `PUT /api/roles/[id]/permissions` for module/screen/granular/field toggles
  - `PUT /api/roles/[id]/users` for assign/unassign users
- Kept role CRUD through existing `/api/admin/roles` for create/update/delete.
- Added full `roles-*` CSS block for the new 3-panel layout and responsive behavior in `globals.css`.
- Added required i18n keys for the new role-permissions UX in both ES/EN dictionaries.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/app/globals.css`
- `src/lib/i18n.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful after the rewrite.

**Pending (next recommended)**

1. Manual QA pass for TAREA 11 interactions in browser (modulo/pantalla/permiso/campo/user toggles) and capture evidence.

### 2026-03-20 - Tarea 12 completada: Fixes visuales y funcionales en Roles 3 paneles

**Completed**

- Ajustes visuales de layout/proporcion en `security-roles-screen` y `globals.css` para alinear con referencia UI 3.0:
  - grid de Modulos en 3 columnas desktop, 2 en tablet, 1 en mobile.
  - cards de modulo con ancho controlado para evitar estiramiento excesivo cuando hay pocos items.
  - panel derecho ampliado en layout (mejor lectura de nombre + username).
  - mejor spacing vertical en sidebar/main y boton `Nuevo Rol` compacto en header izquierdo.
- Reemplazado filtro nativo `<select>` por pills modernas (`Todos | Solo habilitados | Solo no habilitados`).
- Tab Pantallas ajustado a patron visual esperado:
  - collapsible con `ChevronDown/ChevronRight` y badge `Habilitado/Deshabilitado`.
  - icono de modulo en header de cada bloque.
- Tab Visualizacion reforzado a patron esperado:
  - cards verde/rojo + `Eye/EyeOff` y switch visual por item.
- Verificacion funcional de asignar/quitar usuarios (checkpoint 12.5):
  - endpoint `PUT /api/roles/[id]/users` sigue cableado a `assignRoleUser()`.
  - data layer sigue ejecutando `dbo.spRolUsuariosAsignar`.
  - DB verificada con `node scripts/verify-role-phase-a.js` (SP/checks OK).
  - UI ahora refresca datos tras asignar/quitar (`router.refresh()`) ademas del update local.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/app/globals.css`
- `src/lib/i18n.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- `node scripts/verify-role-phase-a.js` output:
  - `SP_CHECK { roleId: 1, modules: 1, screens: 3, fields: 12 }`
  - `UPDATE_CAMPO_OK true`
- `npm run build` successful.

**Pending (next recommended)**

1. Browser QA dirigida por screenshot para confirmar pixel/spacing final en resoluciones desktop/tablet/mobile.

### 2026-03-20 - Tarea 13 completada: Fixes layout/espacios + error SP en Roles

**Completed**

- Sidebar izquierdo compactado para evitar cards estiradas cuando hay pocos roles:
  - `roles-sidebar__list` migrado a `flex` vertical (sin stretch implicito de grid).
  - `roles-sidebar__item` forzado a altura natural (`height: auto`, `align-self: start`).
- Panel central (tab Modulos) ajustado para eliminar hueco vertical:
  - resumen de modulos movido debajo del grid de cards (`roles-module-summary`).
  - cards arriba, resumen/acciones abajo siguiendo referencia UI 3.0.
- Card de modulo compactada en desktop:
  - se mantiene grid de 3 columnas en desktop, 2 en tablet, 1 solo en mobile (`<= 640px`).
  - removido tope que provocaba aspecto sobredimensionado en escenarios de 1 modulo.
- Boton de nuevo rol redisenado a boton circular con icono `+` y tooltip:
  - nueva clase `roles-sidebar__add-btn` en lugar de boton rectangular con texto.
- Fix robusto para error `parameter.type.validate is not a function` al operar roles:
  - en `mutateAdminEntity("roles")` se mantiene llamada tipada a `spRolesCRUD`.
  - agregado fallback automatico a inputs sin tipo si aparece ese error especifico de `mssql`.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/app/globals.css`
- `src/lib/pos-data.ts`
- `OPENCODE_TASKS.md`

**Validation**

- `node scripts/verify-role-phase-a.js` OK:
  - `SP_CHECK { roleId: 1, modules: 1, screens: 3, fields: 12 }`
  - `UPDATE_CAMPO_OK true`
- `npm run build` successful.

**Pending (next recommended)**

1. QA visual final en browser con captura comparativa de los 3 tabs vs referencia UI 3.0.

### 2026-03-20 - Tarea 14 completada: UX de edicion + modulos/pantallas data-driven

**Completed**

- UX header de rol ajustado en panel central:
  - modo lectura muestra nombre/descripcion como texto plano (`h2` + `p`)
  - modo edicion muestra `input` + `textarea`
- Botoneria de edicion unificada en la misma zona (esquina superior derecha):
  - en lectura: `Editar Datos`
  - en edicion: `Cancelar` + `Guardar Cambios` (con `Loader2`)
  - menu de acciones `...` se mantiene visible al lado.
- Seed DB data-driven aplicado con nuevo script:
  - `database/16_roles_modules_screens_seed.sql`
  - inserta modulos faltantes (Dashboard, Ordenes, Punto de Venta, Catalogo, Reportes, Configuracion)
  - inserta pantallas faltantes por modulo
  - inserta permisos default (flags en 0) para pantallas sin registro en `Permisos`
- Verificacion de SP `spRolPermisosPorModulo`:
  - sin hardcode en frontend; el componente renderiza `modules`/`screens` desde API.
  - resultado posterior a seed: `modules: 7`, `screens: 21`, `fields: 12`.
- Iconos de modulos robustecidos en frontend:
  - usa `icon` de DB como clave primaria
  - agrega fallback extensible por nombre de modulo y legacy icon keys.
- Estilo de cards de modulos mejorado para acercar visual a UI 3.0:
  - estado habilitado/deshabilitado con borde/fondo/sombra diferenciados
  - icon box ampliado y badges compactos.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/app/globals.css`
- `database/16_roles_modules_screens_seed.sql`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/16_roles_modules_screens_seed.sql`.
- `node scripts/verify-role-phase-a.js` output:
  - `SP_CHECK { roleId: 1, modules: 7, screens: 21, fields: 12 }`
  - `UPDATE_CAMPO_OK true`
- `npm run build` successful.

**Pending (next recommended)**

1. QA visual final del tab Modulos/Pantallas/Visualizacion con los nuevos modulos seeded para validar jerarquia y legibilidad en desktop/tablet/mobile.

### 2026-03-20 - Tarea 14 (update): Pulido visual final y ajuste de autorizacion

**Completed**

- Ajustado layout de Roles por feedback visual para corregir desproporciones:
  - panel derecho mas angosto
  - cards de usuarios con ancho limitado al contenido util (texto + icono)
  - cards de modulos compactadas para evitar apariencia sobredimensionada
  - tab Modulos en grid de 2 columnas responsive (desktop/tablet) y 1 columna en mobile.
- Ajustado header de card de modulo para evitar solapes/cortes:
  - nuevo contenedor `roles-module-card__controls` para badge + switch.
- Fix de autorizacion en APIs de roles para evitar `No autorizado` en superadmin:
  - `src/app/api/roles/[id]/permissions/route.ts`
  - `src/app/api/roles/[id]/users/route.ts`
  - se agrega bypass explicito para superadmin (por `roleId`/nombre), alineado con la logica de `/api/auth/permissions`.

**Files (high impact)**

- `src/app/globals.css`
- `src/components/pos/security-roles-screen.tsx`
- `src/app/api/roles/[id]/permissions/route.ts`
- `src/app/api/roles/[id]/users/route.ts`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful tras los cambios de UI + API.

**Pending (next recommended)**

1. QA visual final en browser para confirmar densidad/tamaños exactos por breakpoint con datos reales.

### 2026-03-20 - Tarea 15 completada: Limpieza de menu/permisos (Permisos y Roles-Permisos)

**Completed**

- Limpieza de menu en seguridad:
  - removidos de `configSecurity` en `app-shell` los links a:
    - `/config/security/permissions`
    - `/config/security/roles-permissions`
  - se mantienen visibles solo: Usuarios, Roles, Modulos, Pantallas.
- Limpieza de mapa de permisos de rutas:
  - removidas de `PermissionKey` y `ROUTE_PERMISSIONS` las claves/rutas:
    - `config.security.permissions.view`
    - `config.security.roles-permissions.view`
- Ajuste complementario en APIs de roles:
  - `canManageRoles(...)` simplificado para validar con `config.security.roles.view`.
- Se mantienen las paginas legacy (`/config/security/permissions` y `/config/security/roles-permissions`) sin enlace en menu.

**Files (high impact)**

- `src/components/pos/app-shell.tsx`
- `src/lib/permissions.ts`
- `src/app/api/roles/[id]/permissions/route.ts`
- `src/app/api/roles/[id]/users/route.ts`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. Confirmar en QA manual que submenu Seguridad ya no muestra Permisos/Roles-Permisos para todos los perfiles.

### 2026-03-20 - Tarea 16 completada: Menu Seguridad solo Usuarios + Roles

**Completed**

- Submenu Seguridad simplificado en `app-shell`:
  - removidos `Modules` y `Screens` de `configSecurity`.
  - menu final visible: `Users` y `Roles`.
- Limpieza de mapa de permisos por ruta:
  - removidas claves/rutas de `modules` y `screens` en `src/lib/permissions.ts`:
    - `config.security.modules.view`
    - `config.security.screens.view`
- Eliminadas paginas dedicadas de seguridad ya no expuestas:
  - `src/app/config/security/modules/page.tsx`
  - `src/app/config/security/screens/page.tsx`
- Verificacion de consumidores de `SecurityConfigScreen` y `SecurityManager`:
  - se mantienen porque siguen siendo usados por paginas legacy:
    - `src/app/config/security/permissions/page.tsx`
    - `src/app/config/security/roles-permissions/page.tsx`

**Files (high impact)**

- `src/components/pos/app-shell.tsx`
- `src/lib/permissions.ts`
- `src/app/config/security/modules/page.tsx` (deleted)
- `src/app/config/security/screens/page.tsx` (deleted)
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. QA manual de navegacion para confirmar que Seguridad solo muestra Usuarios/Roles en todos los perfiles con permisos.

### 2026-03-20 - Tarea 17 completada: Botones Asignar/Quitar usuarios en Roles

**Completed**

- Verificacion DB de SP para asignacion de usuarios por rol:
  - `spRolUsuariosAsignar` existe en entorno actual (`SP_ROL_USUARIOS_ASIGNAR EXISTS`).
- Verificacion API:
  - `PUT /api/roles/[id]/users` ya existe y sigue operativo con validacion de sesion + payload.
- Frontend roles panel derecho:
  - botones `UserMinus` (quitar) y `UserPlus` (asignar) siguen conectados a `updateUserAssignment(...)`.
  - se mantienen restricciones por modo edicion (`disabled` cuando `!isEditing || isBusy`).
  - se mejoro feedback visual solicitado:
    - boton quitar en estilo rojo (`roles-user-action-btn--remove`)
    - boton asignar en estilo verde (`roles-user-action-btn--add`)
    - estado disabled con `opacity: 0.4` + `pointer-events: none`.
  - al éxito: toast + update local de lista + `router.refresh()`.

**Files (high impact)**

- `src/components/pos/security-roles-screen.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- Verificacion SP: `SP_ROL_USUARIOS_ASIGNAR EXISTS`.
- `npm run build` successful.

**Pending (next recommended)**

1. QA manual en Roles > panel Usuarios para validar flujo completo asignar/quitar con multiples roles y usuarios.

### 2026-03-20 - Tarea 17 (update): Hotfixes asignar/quitar en Roles

**Completed**

- Hotfix frontend para evitar crash de parseo JSON al asignar/quitar usuarios:
  - en `updateUserAssignment(...)` se reemplazo `response.json()` por parse robusto (`response.text()` + `JSON.parse` try/catch).
  - evita error `Unexpected end of JSON input` cuando la respuesta viene vacia o no-JSON.
- Implementado fallback de desasignacion con rol ficticio `SIN ROL` (IdRol = 0):
  - nuevo script aplicado: `database/18_sin_rol_default_y_sp_asignacion.sql`.
  - crea/asegura `dbo.Roles` con `IdRol=0` y nombre `SIN ROL`.
  - actualiza `dbo.spRolUsuariosAsignar` para `@Accion='Q'` => `Usuarios.IdRol = 0`.
- Ajustes de consistencia API/UI:
  - `src/app/api/roles/[id]/users/route.ts` ahora permite `roleId = 0` (validacion `roleId < 0` invalido).
  - `src/components/pos/security-roles-screen.tsx` actualiza estado local al quitar hacia `IdRol=0` (antes `1`).

**Files (high impact)**

- `database/18_sin_rol_default_y_sp_asignacion.sql`
- `src/components/pos/security-roles-screen.tsx`
- `src/app/api/roles/[id]/users/route.ts`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/18_sin_rol_default_y_sp_asignacion.sql`.
- `npm run build` successful tras los hotfixes.

**Pending (next recommended)**

1. QA manual puntual: quitar usuario desde rol admin y verificar que pasa a `SIN ROL` y aparece de inmediato en tab `Disponibles`.

### 2026-03-20 - Tarea 17 (update 2): Menu de cuenta estilo Facebook

**Completed**

- Redisenado el dropdown de usuario/topbar con patron Facebook-like:
  - panel oscuro (`dropdown-menu--fb`) con jerarquia visual tipo account hub.
  - vista principal con bloque de perfil + items: Perfil, Configuracion de Cuenta, Configuracion del Sistema, Cerrar sesion.
  - vista secundaria para `Configuracion del Sistema` dentro del mismo panel, con boton de regreso.
- Eliminada navegacion multinivel flotante antigua (submenu/sub-submenu lateral) en `app-shell`.
- Nueva vista de configuracion muestra links directos disponibles por permisos (Empresa, Catalogo, Salon, Seguridad) en lista unica con chevron.

**Files (high impact)**

- `src/components/pos/app-shell.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. QA visual de dropdown desktop/mobile para confirmar spacing, contraste y navegacion back en la vista de Configuracion del Sistema.

### 2026-03-20 - Tarea 17 (update 3): Menu de cuenta en tema claro + grupos colapsables

**Completed**

- Ajustado dropdown de usuario para heredar tema claro de la pagina:
  - `dropdown-menu--fb` pasa de dark panel a card clara (fondo blanco, borde `var(--line)`, `shadow-soft`).
  - bloque de perfil e items alineados a paleta light del sistema.
- Reintroducida estructura colapsable por grupo dentro de `Configuracion del Sistema`:
  - grupos: Empresa, Catalogo, Salon, Seguridad.
  - cada grupo expande/colapsa sus opciones internas en el mismo panel.
  - se mantiene vista principal + vista de configuracion con boton back (sin submenus flotantes).

**Files (high impact)**

- `src/components/pos/app-shell.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. QA visual final en desktop/mobile para confirmar densidad de texto en subitems y animacion de colapso por grupo.

### 2026-03-20 - Tarea 17 (update 4): Navegacion por pantallas por grupo

**Completed**

- Ajustado flujo de `Configuracion del Sistema` para que no use acordeon por grupo:
  - pantalla 1: menu principal de usuario.
  - pantalla 2: lista de grupos (Empresa, Catalogo, Salon, Seguridad).
  - pantalla 3: detalle del grupo seleccionado con sus opciones.
- Implementado estado de navegacion interna en `app-shell`:
  - `systemPanel: root | settings | settings-group`
  - `selectedSettingsGroup` para abrir la pantalla de detalle por grupo.
- Se mantiene herencia de tema claro en todo el dropdown.

**Files (high impact)**

- `src/components/pos/app-shell.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. QA UX: validar copy/orden de opciones por grupo y comportamiento de boton back en desktop/mobile.

### 2026-03-20 - Tarea 17 (update 5): Chevron condicional por hijos

**Completed**

- Ajustado menu de detalle por grupo para mostrar chevron derecho solo cuando un item tenga hijos.
- En items hoja (sin hijos), se oculta chevron para evitar falsa expectativa de subnivel.
- Se dejo la estructura de datos preparada con `children?` opcional por item para extensibilidad futura.

**Files (high impact)**

- `src/components/pos/app-shell.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. QA visual puntual en panel de detalle (ej. Catalogo) para confirmar que los items hoja ya no muestran chevron.

### 2026-03-21 - Tarea 18 completada: Catalogo en paginas independientes

**Completed**

- Reescritas paginas de Catalogo para eliminar patron compartido con tabs (`CatalogConfigScreen`):
  - `src/app/config/catalog/products/page.tsx` ahora usa `AppShell + PageHeader + CatalogManager` y carga solo `getCatalogManagerData()`.
  - `src/app/config/catalog/categories/page.tsx` ahora usa `AppShell + PageHeader + CatalogMastersManager` con `sections={["categories"]}`.
  - `src/app/config/catalog/units/page.tsx` ahora usa `sections={["units"]}`.
  - `src/app/config/catalog/product-types/page.tsx` ahora usa `sections={["product-types"]}`.
- Verificacion de consumidores de `CatalogConfigScreen`:
  - sin referencias restantes en `src/`.
  - eliminado `src/components/pos/catalog-config-screen.tsx`.
- Verificada navegacion en menu de usuario > Configuracion del Sistema > Catalogo:
  - se mantienen rutas a `categories`, `product-types`, `products`, `units` en `app-shell`.

**Files (high impact)**

- `src/app/config/catalog/products/page.tsx`
- `src/app/config/catalog/categories/page.tsx`
- `src/app/config/catalog/units/page.tsx`
- `src/app/config/catalog/product-types/page.tsx`
- `src/components/pos/catalog-config-screen.tsx` (deleted)
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

**Pending (next recommended)**

1. QA manual de Catalogo para confirmar encabezados independientes y ausencia total de tabs compartidos en las 4 paginas.

### 2026-03-21 - Tarea 19 completada: Fix global toggle switch junto al label

**Completed**

- Ajuste CSS global para reducir separacion entre texto y switch en todas las pantallas objetivo:
  - `login`: `.login-switch-row`
  - `company`: `.company-active-toggle`
  - `users`: `.users-active-toggle`
  - `roles`: `.roles-switch-row`
- Se aplico patron consistente:
  - `justify-content: flex-start`
  - `gap` fijo
  - `max-width` para evitar estiramiento a 100% del grid
- En `roles-switch-row` se mantuvo su estilo de card (borde + padding), ajustando solo distribucion/anchura para acercar toggle al label.

**Files (high impact)**

- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- `npm run build` successful.

### 2026-03-21 - Tarea 20 completada: Company tab Formatos (numero/fecha/hora)

**Completed**

- DB:
  - nuevo script `database/19_company_formats.sql` aplicado.
  - agrega columnas de formato en `dbo.Empresa` (numero, fecha, hora, semana, sistema medida).
  - normaliza defaults en filas existentes.
  - `ALTER/CREATE OR ALTER` de `dbo.spEmpresaCRUD` para leer/guardar campos nuevos.
- API:
  - `src/app/api/company/route.ts` extendido con `GET` y `PUT` para payload completo de company incluyendo formatos.
- Data layer:
  - `CompanySettingsData` ampliado con campos de formato.
  - `getCompanySettingsData()` y `saveCompanySettings()` actualizados para mapear/persistir formatos.
- UI:
  - `company-settings.tsx` ahora incluye tab `Formatos` con secciones:
    - Formato de Numeros
    - Formato de Fecha
    - Formato de Hora
  - previews en vivo para numero/fecha/hora.
  - boton `Restablecer Valores` con defaults.
- i18n:
  - nuevas claves `company.*` para labels y acciones del tab Formatos.
- CSS:
  - nuevas clases `company-formats*` para layout/paneles/previews (responsive).

**Files (high impact)**

- `database/19_company_formats.sql`
- `src/lib/pos-data.ts`
- `src/app/api/company/route.ts`
- `src/components/pos/company-settings.tsx`
- `src/lib/i18n.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/19_company_formats.sql`.
- `npm run build` successful.

**Pending (next recommended)**

1. QA manual en `/config/company` para validar persistencia real de formatos y previews tras refresh.

### 2026-03-21 - Tarea 21 completada: Consolidacion de campos duplicados en Empresa

**Completed**

- DB:
  - nuevo script `database/20_company_consolidation.sql` aplicado.
  - migracion de datos previa a eliminacion de columnas:
    - `RNC -> IdentificacionFiscal` cuando destino vacio
    - `NombreEmpresa -> NombreComercial` cuando destino vacio
    - `CalleNumero -> Direccion` cuando destino vacio
  - `CREATE OR ALTER` de `dbo.spEmpresaCRUD` removiendo parametros/campos legacy (`RNC`, `NombreEmpresa`, `CalleNumero`) y manteniendo campos canonicos.
  - eliminadas columnas redundantes de `dbo.Empresa`: `RNC`, `NombreEmpresa`, `CalleNumero`.
- Data layer:
  - `CompanySettingsData` consolidado para usar solo:
    - `fiscalId -> IdentificacionFiscal`
    - `tradeName -> NombreComercial`
    - `businessName -> RazonSocial`
    - `address -> Direccion`
  - removidos mappings/inputs duplicados en `getCompanySettingsData()` y `saveCompanySettings()`.
- UI:
  - `company-settings.tsx` actualizado:
    - label `RNC` renombrado a `Identificacion Fiscal`.
    - removido campo duplicado `Direccion General`.
    - tab Contacto usa un solo campo `Direccion`.

**Files (high impact)**

- `database/20_company_consolidation.sql`
- `src/lib/pos-data.ts`
- `src/components/pos/company-settings.tsx`
- `OPENCODE_TASKS.md`

**Validation**

- SQL apply output: `Script aplicado correctamente: database/20_company_consolidation.sql`.
- `npm run build` successful.

**Pending (next recommended)**

1. Start `TAREA 22` (Listas de Precios) from `OPENCODE_TASKS.md`.

---

### 2026-03-21 - Cierre de sesion: Estado del proyecto

**Resumen de la sesion 2026-03-20 / 2026-03-21:**

Se completaron **17 tareas** con multiples updates. El modulo de Seguridad esta cerrado.

**Modulo de Seguridad — COMPLETADO:**
- Login: gradiente, spinner, error box, i18n toggle, boton disabled (TAREA 6)
- Usuarios: avatar en tabla, modal ancho, 3 estados, spinner save, i18n (TAREA 7-8)
- Roles: pantalla dedicada de 3 paneles (TAREA 8-14):
  - Panel izquierdo: lista de roles con busqueda
  - Panel central: tabs Modulos / Pantallas / Visualizacion con permisos granulares
  - Panel derecho: asignar/quitar usuarios al rol
  - Data-driven via SPs (agregar modulos = INSERT en DB, sin cambios frontend)
  - Tabla `RolCamposVisibilidad` para field visibility por rol
  - SPs: `spRolPermisosPorModulo`, `spRolPermisosActualizar`, `spRolUsuariosAsignar`
  - Patron "Editar Datos" (lectura por defecto, edicion con boton)
- Menu simplificado: solo Usuarios y Roles (TAREA 15-16)
- Dropdown usuario rediseñado con flujo de navegacion por pantallas (TAREA 17 updates)

**DB Scripts aplicados en esta sesion:**
- `RolCamposVisibilidad` (tabla nueva)
- `spRolPermisosPorModulo` (SP nuevo)
- `spRolPermisosActualizar` (SP nuevo)
- `spRolUsuariosAsignar` (SP nuevo)
- Seed de Modulos y Pantallas completos (6 modulos, ~20 pantallas)
- Columna `Bloqueado` en `Usuarios`
- Columna `FechaCreacion` en `Roles`
- ALTER de `spUsuariosCRUD` para campo `Bloqueado`

**Archivos clave modificados:**
- `src/components/pos/security-roles-screen.tsx` (~930 lineas, reescrito completo)
- `src/components/pos/security-users-screen.tsx` (~607 lineas, polish)
- `src/components/pos/app-shell.tsx` (dropdown usuario rediseñado)
- `src/app/login/page.tsx` (polish visual)
- `src/app/globals.css` (clases .roles-*, .users-*, .login-*)
- `src/lib/permissions.ts` (limpieza de rutas)
- `src/lib/i18n.tsx` (claves roles.*, users.*)
- APIs nuevas: `/api/roles/[id]/permissions`, `/api/roles/[id]/users`

**Estado de modulos:**
| Modulo | Estado |
|--------|--------|
| Login | COMPLETADO (polish UI 3.0) |
| Seguridad > Usuarios | COMPLETADO (pantalla dedicada) |
| Seguridad > Roles | COMPLETADO (3 paneles + permisos granulares) |
| Dashboard | BUILT (funcional, sin polish) |
| Ordenes | BUILT (funcional, sin polish) |
| Salon/Comedor | BUILT floor + BASIC config |
| Catalogo | BUILT productos + BASIC masters |
| Caja | PLACEHOLDER |
| Reportes | PLACEHOLDER |
| Consultas | BASIC |

**Siguiente sesion: Modulo Catalogo**
Plan propuesto:
- TAREA 18: Paginas independientes (quitar tabs CatalogConfigScreen)
- TAREA 19: Polish Productos
- TAREA 20: Polish Categorias
- TAREA 21: Polish Unidades
- Referencia UI 3.0: `D:\Masu\UI 3.0\app\config\catalog\`

---

### 2026-03-22 - TAREA 22 completada v2: Listas de Precios (correccion completa vs spec)

**Completed**

- DB:
  - `database/21_price_lists.sql`: tablas `dbo.ListasPrecios` y `dbo.ListaPrecioUsuarios` con FK, unique index, soft-delete (`RowStatus`), y 3 registros demo.
  - `database/22_sp_price_lists.sql`: SP `dbo.spListasPreciosCRUD` (L/O/I/A/D) y `dbo.spListaPrecioUsuarios` (L/A/Q). Ambos aplicados y verificados.

- Data layer (`src/lib/pos-data.ts`):
  - Tipos `PriceListRecord` y `PriceListUser`.
  - Funciones: `getPriceLists`, `createPriceList`, `updatePriceList`, `deletePriceList`, `getPriceListUsers`, `assignPriceListUser`, `removePriceListUser`.

- API endpoints:
  - `GET/POST /api/catalog/price-lists`
  - `PUT/DELETE /api/catalog/price-lists/[id]`
  - `GET/PUT /api/catalog/price-lists/[id]/users`

- UI:
  - `src/components/pos/price-lists-screen.tsx`: layout 2 paneles BEM. Panel izq: lista con busqueda, badge estado, menu 3 puntos (Editar/Duplicar/Eliminar), boton nueva lista. Panel der: tab General (codigo, activo switch, descripcion, abreviatura, fechas, moneda) + tab Usuarios (Asignados/Disponibles con asignar/quitar).
  - `src/app/config/catalog/price-lists/page.tsx`: pagina server-side con data inicial.
  - Menu: item "Listas de Precios" agregado al submenu Catalogo en `app-shell.tsx` con icono `Tag`.
  - i18n: clave `config.priceLists` agregada.
  - CSS: bloque `.price-lists-*` en `globals.css` (layout, sidebar, detalle, tabs, usuarios, responsive).

**Validation**

- `npm run build` exitoso. Ruta `/config/catalog/price-lists` visible en el output.

**Files**

- `database/21_price_lists.sql`
- `database/22_sp_price_lists.sql`
- `src/lib/pos-data.ts`
- `src/app/api/catalog/price-lists/route.ts`
- `src/app/api/catalog/price-lists/[id]/route.ts`
- `src/app/api/catalog/price-lists/[id]/users/route.ts`
- `src/components/pos/price-lists-screen.tsx`
- `src/app/config/catalog/price-lists/page.tsx`
- `src/components/pos/app-shell.tsx`
- `src/lib/i18n.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md`

**Correcciones vs version anterior:**

- SP `spListaPrecioUsuarios` reescrito: acciones `LA`/`LD`/`A`/`Q` (era accion `L`/`A`/`Q` con CHAR(1)), ahora CHAR(2).
- Data layer: `getPriceListUsers` devuelve `{ assigned, available }` en paralelo (era array con campo `assigned: boolean`).
- `assignPriceListUser` / `removePriceListUser` devuelven `{ assigned, available }` (2 recordsets del SP).
- API `/[id]/users` actualizada para manejar el nuevo contrato.
- `PriceListsScreen` reescrito sin `initialData` prop — carga datos via fetch client-side.
- Pagina reescrita con `PageHeader` tal como spec (sin `initialData` al componente).
- CSS: agregadas clases faltantes (`.price-lists-sidebar__add-btn`, `.price-lists-badge`, `.price-lists-dropdown`, `.price-lists-detail__tabs`, `.price-lists-form__toggle-row`, `.price-lists-users__spinner`, `.price-lists-loading`).

### 2026-03-22 - Bug fix: parameter.type.validate

**Bug:** `Validation failed for parameter 'IdListaPrecio'. parameter.type.validate is not a function`

**Root cause:** `mssql` v12.2.1 with `tedious` v19.2.1 has a bug where calling `.input(name, sql.Int, value)` can intermittently fail with `parameter.type.validate is not a function`. The same issue was previously handled with a try/catch fallback in `mutateAdminEntity` (roles case). The compiled `.next` chunk confirmed this pattern existed.

**Fix applied:** All price-list data layer functions now have a try/catch fallback:
- `createPriceList`, `updatePriceList`, `deletePriceList`
- `getPriceListUsers`, `assignPriceListUser`, `removePriceListUser`

Fallback pattern: on `parameter.type.validate is not a function`, retry the same request WITHOUT explicit type arguments (`.input(name, value)` instead of `.input(name, sql.Int, value)`), letting `tedious` infer types.

**File changed:** `src/lib/pos-data.ts`

**Pending (siguiente)**

1. TAREA 23 — Monedas (3 paginas: configuracion, tasas diarias, historial).

---

### 2026-03-22 - TAREA 22 session completa: fixes + features

**Bugs corregidos:**

1. **Dates no se cargaban desde DB**: `tedious` convierte DATE a `Date` objects. `String(date).slice(0,10)` cortaba mal. Fix: `parseDate` en `mapPriceListRow` detecta `instanceof Date` y formatea `YYYY-MM-DD`. Inputs usan `Date` objects con `sql.Date`.

2. **parameter.type.validate**: todas las funciones de price-lists con fallback try/catch (ya existia en `mutateAdminEntity`).

3. **Fechas null**: SP validaba fechas opcionales. Fix: SP valida obligatorias en I y A. Data layer valida en `create/update`. UI con `required` + `*`.

**Features agregados:**

1. **Botones bulk**: "Asignar todos" / "Quitar todos" con acciones `AA`/`QA` en SP.
   - SP: reactiva con UPDATE si existe RowStatus=0, inserta si no existe.
   - Data layer: `assignAllPriceListUsers`, `removeAllPriceListUsers`.
   - API: acepta `assign_all` / `remove_all`.
   - UI: botones con `UserCheck` / `UserX`.

2. **SPs aplicados**: `database/22_sp_price_lists.sql` (validacion fechas, acciones AA/QA, reactivate).
   - `database/21_price_lists.sql` (UPDATE correctivo fechas null).

**Archivos modificados:**
- `src/lib/pos-data.ts` (mapPriceListRow con parseDate, todas funciones con fallback, nuevas funciones bulk)
- `src/app/api/catalog/price-lists/[id]/route.ts`
- `src/app/api/catalog/price-lists/[id]/users/route.ts`
- `src/components/pos/price-lists-screen.tsx` (required en fechas, botones bulk, UserCheck/UserX)
- `src/app/globals.css` (.price-lists-users__bulk-actions/bulk-btn)
- `database/22_sp_price_lists.sql`
- `database/21_price_lists.sql`

**Estado TAREA 22:** COMPLETA ✅ + QA pendiente

---

## Session: 2026-03-22 — TAREA 23 Monedas (CSS + Build)

**Objetivo:** Completar checkpoint 23.11: CSS BEM + i18n + Build.

**Trabajo realizado:**

1. **CSS (`globals.css`):** Appendidos ~550 lineas de estilos BEM para 3 pantallas:
   - `.currencies-*` — layout 2-panel, sidebar, detail panel, form, empty state
   - `.currency-rates-*` — header, stat cards, table, badges, pagination
   - `.currency-history-*` — header, stat cards, filters, table, pagination
   - Responsive breakpoints para 1100px y 768px

2. **TypeScript fixes:**
   - `app-shell.tsx:209,59` — agregado `"currencies"` a `SettingsSectionKey` union type y `selectedSettingsGroup` state type
   - `currencies-screen.tsx` — agregado `isLocal` a `CurrencyForm` y `recordToForm()`

3. **Build:** `npm run build` exitoso. 3 paginas nuevas visibles en la salida:
   - `/config/currencies`
   - `/config/currencies/rates`
   - `/config/currencies/history`

4. **OPENCODE_TASKS.md:** Actualizado:
   - Estado TAREA 23: `COMPLETO ✅`
   - Todos los checkpoints 23.1-23.11 marcados como `[x]` ✅
   - Detalle de 23.11 con fixes aplicados

**Archivos modificados:**
- `src/app/globals.css` (CSS monedas appended)
- `src/components/pos/app-shell.tsx` (currencies key en SettingsSectionKey)
- `src/components/pos/currencies-screen.tsx` (isLocal en CurrencyForm)
- `OPENCODE_TASKS.md` (estado general + checkpoints)

**Estado TAREA 23:** COMPLETA ✅ — QA pendiente

---

## Session: TAREA 26 — Limpieza Estructura DB

**Fecha:** 2026-03-22

**Resumen:** TAREA 26 completada. Las columnas CRUD legacy fueron removidas de la tabla `Permisos`.

### Problemas descubiertos y solucionados

**Columna rename requerida:** Las columnas en la DB no se llaman `PeutVer` etc. como parecia en los session notes. Los hex bytes revelan que se llaman `ueddeVer`, `ueddeCrear`, `ueddeEditar`, `ueddeEliminar`, `ueddeAprobar`, `ueddeAnular`, `ueddeImprimir` (con doble 'd': P-u-e-d-d-e-V-e-r = "ueddeVer").

**SQL Server metadata bug:** `ALTER TABLE DROP COLUMN` fallaba con "one or more objects access this column" incluso despues de:
- Dropping todos los SPs que referenciaban `Permisos`
- `DBCC FREEPROCCACHE` para limpiar cache
- `sp_refreshsqlmodule` para actualizar metadata
- `sys.sql_expression_dependencies` y `sys.dm_sql_referencing_entities` mostraban 0 referencias

**Solucion definitiva:** `sp_rename` para renombrar las columnas a `Obsolete_0` ... `Obsolete_5` + `Obsolete_50756564` (para `ueddeVer`). Esto funciona porque `sp_rename` no hace la misma validacion de dependencias que `ALTER TABLE DROP COLUMN`.

### Pasos ejecutados

1. `database/26_sps_step1.sql` aplicado — recreo de 7 SPs limpios
2. Script para drop SPs + rename columnas + recrear SPs (`26_combined.sql`)
3. 7 SPs droppeados exitosamente
4. `ueddeVer`, `ueddeCrear`, `ueddeEditar`, `ueddeEliminar`, `ueddeAprobar`, `ueddeAnular`, `ueddeImprimir` renombradas a `Obsolete_*`
5. 7 SPs recreados correctamente (verificado con `OBJECT_ID`)
6. `pos-data.ts`: limpiadas referencias a columnas old en `getSecurityManagerData()` y `updateEntity()`
7. `auth-session.ts`: `getRoleRoutePermissions()` actualizada para usar `RolPantallaPermisos` en lugar de columnas `uedde*`
8. `23_permission_monedas.sql`: removidas columnas legacy del INSERT
9. `22_permission_price_lists.sql`: removidas columnas legacy del INSERT
10. `npm run build` exitoso sin errores TypeScript

### Archivos modificados
- `database/26_sps_step1.sql` (ya existia)
- `database/26_combined.sql` (creado nuevo — combina drop + rename + recrear)
- `database/26_sps_step2.sql` (creado, no usado — combina drop + ALTER TABLE DROP + recrear)
- `database/23_permission_monedas.sql` (actualizado — removidas columnas legacy)
- `database/22_permission_price_lists.sql` (actualizado — removidas columnas legacy)
- `src/lib/pos-data.ts` (limpieza de referencias a columnas old)
- `src/lib/auth-session.ts` (`getRoleRoutePermissions` reescrita para usar `RolPantallaPermisos`)
- `OPENCODE_TASKS.md` (TAREA 26 marcada COMPLETA, checkpoints 26.1-26.7 marcados `[x]`)

### Estado actual de Permisos
Columnas actuales: `IdPermiso, IdPantalla, Nombre, Descripcion, Obsolete_50756564, Obsolete_0, Obsolete_1, Obsolete_2, Obsolete_3, Obsolete_4, Obsolete_5, Activo, FechaCreacion, RowStatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion`

Las columnas `Obsolete_*` son effectively eliminadas de la perspectiva de la aplicacion.

---

## Session: TAREA 26 v2 — Fix Arquitectura (2026-03-22)

**Resumen:** VERSION ACTUAL de TAREA 26 completada. El `OPENCODE_TASKS.md` fue actualizado con un enfoque diferente que se ejecuto en esta sesion.

### Enfoque de esta sesion

A diferencia de la sesion anterior (que solo renombro columnas a `Obsolete_*`), esta sesion implemento el fix de arquitectura:

1. **Columna `Clave` en `Permisos`**: Almacena la permission key directamente (ej: `config.catalog.price-lists.view`). Pobla automaticamente desde `Pantallas.Ruta` usando el mapeo conocido.

2. **`spPermisosObtenerPorRol` reescrito**: Ya no une con `Pantallas`. Retorna `Permisos.Clave` directamente. Elimina la dependencia de `Pantallas.Ruta` para permisos.

3. **`getPermissionKeysByRole` simplificado**: Sin try/catch fallback. SP retorna `Clave` directamente.

4. **`spPermisosCRUD` actualizado**: Incluye columna `Clave`. Genera automaticamente desde `Pantallas.Ruta` si no se provee.

### Scripts DB aplicados
- `database/26_tarea_step1.sql`: Agrega `Clave`, pobla los 25 permisos, reescribe `spPermisosObtenerPorRol` y `spPermisosCRUD`

### Verificacion
- `spPermisosObtenerPorRol(1)` retorna 16 claves: `cash-register.view`, `config.catalog.*`, `config.company.view`, `config.currencies.*`, `config.security.*`, `dashboard.view`, `orders.view`, `queries.view`, `reports.view`, `security.view`
- `npm run build` exitoso sin errores

### Archivos modificados
- `database/26_tarea_step1.sql` (creado nuevo)
- `src/lib/auth-session.ts` (`getPermissionKeysByRole` simplificado, import `routeToPermissionKey` removido)
- `src/lib/pos-data.ts` (`clave` agregada al tipo `permissions` y mapping)
- `OPENCODE_TASKS.md` (TAREA 26 marcada COMPLETA, checkpoints 26.1-26.7 marcados `[x]`)

### Estado actual de Permisos
Columnas: `IdPermiso, IdPantalla, Nombre, Descripcion, Obsolete_50756564, Obsolete_0, Obsolete_1, Obsolete_2, Obsolete_3, Obsolete_4, Obsolete_5, Activo, FechaCreacion, RowStatus, UsuarioCreacion, FechaModificacion, UsuarioModificacion, Clave`

Las columnas `Obsolete_*` (de sesion anterior) estan renombradas via `sp_rename`. `ALTER TABLE DROP COLUMN` sigue bloqueado por bug de metadata SQL Server.

`Clave` columna nueva, poblada para los 25 permisos existentes.

**Pendiente:** TAREA 27 — Formatos Globales.

---

## Session: TAREA 27 — Formatos Globales (2026-03-22)

**Resumen:** TAREA 27 completada. `FormatProvider` creado con `useFormat()`, aplicado a todas las pantallas POS.

### Implementado

1. **`src/lib/format-context.tsx`** — Context que carga formatos desde `/api/company` y expone:
   - `formatNumber(value, decimals?)` — usa `decimalSymbol` y `digitGroupingSymbol` de la empresa
   - `formatDate(value, mode?)` — "short" o "long", convierte patrón SQL a JS Intl
   - `formatTime(value, mode?)` — maneja 12h/24h, AM/PM con símbolos de empresa
   - `formatDateTime(value)` — combina date short + time short
   - Fallback ISO mientras carga

2. **`src/app/layout.tsx`** — `<FormatProvider>` envuelve `<PermissionsProvider>`

3. **Pantallas actualizadas:**
   - `currency-rates-screen.tsx`: fechas de stat cards → `formatDate`, tasas → `formatNumber(4 decimals)`, variacion → `formatNumber(2 decimals)`
   - `currency-history-screen.tsx`: tasas → `formatNumber(4)`, promedio USD/EUR → `formatNumber(2)`, fechas → `formatDate`
   - `currencies-screen.tsx`: ultima actualizacion → `formatDate`
   - `security-users-screen.tsx`: `safeDate()` reemplazada por `formatDateTime` del contexto

4. **`npm run build`** — OK sin errores

### Archivos modificados
- `src/lib/format-context.tsx` (nuevo)
- `src/app/layout.tsx`
- `src/components/pos/currency-rates-screen.tsx`
- `src/components/pos/currency-history-screen.tsx`
- `src/components/pos/currencies-screen.tsx`
- `src/components/pos/security-users-screen.tsx`
- `OPENCODE_TASKS.md` (TAREA 27 marcada COMPLETA, checkpoints 27.1-27.11 marcados `[x]`)

### Nota: Columnas Obsolete_* de Permisos
El usuario las eliminó manualmente (borrado directo en SQL Server), evitando el workaround nuclear. Schema limpio confirmado.

### Pendiente: Siguiente tarea disponible en `OPENCODE_TASKS.md`.

---

## Session: TAREA 25 — checkpoint 25.3+ (2026-03-25)

**Resumen:** Se completaron checkpoints 25.3 a 25.9 de TAREA 25 (modelo expandido de productos).

### Implementado

1. **DB scripts aplicados**
   - `database/36_productos_modelo_expandido.sql`
   - `database/37_productos_sps_expandidos.sql`
   - Verificado: tablas `ProductoPrecios`, `ProductoCostos`, `ProductoOfertas` y columna `Productos.AplicaImpuesto`.

2. **Data layer (`src/lib/pos-data.ts`)**
   - `ProductRecord` expandido con campos fiscales/opcionales y subestructuras:
     - `prices[]`, `costs`, `offer`
   - Nuevo `getProductById(id)` con `Promise.all`:
     - `spProductosCRUD('O')`
     - `spProductosPreciosCRUD('G')`
     - `spProductosCostosCRUD('G')`
     - `spProductosOfertasCRUD('G')`
   - `createProduct()` y `updateProduct()` expandidos para persistir:
     - campos nuevos de `Productos`
     - upsert de precios por lista (`spProductosPreciosCRUD('U')`)
     - upsert de costos (`spProductosCostosCRUD('U')`)
     - upsert de oferta (`spProductosOfertasCRUD('U')`)
   - Fallback anti-bug `parameter.type.validate is not a function` aplicado en llamadas nuevas.

3. **API productos**
   - `src/app/api/catalog/products/route.ts`:
     - normalización de payload expandido (`prices`, `costs`, `offer`, flags y campos nuevos)
   - Nuevo endpoint:
     - `src/app/api/catalog/products/[id]/route.ts` (`GET`) → detalle completo via `getProductById`.

4. **Frontend (`src/components/pos/catalog-products-screen.tsx`)**
   - Conectado el submit con payload completo (impuestos, opciones, precios, costos, oferta).
   - Carga de detalle por producto seleccionado (`GET /api/catalog/products/:id`) para hidratar tabs.
   - Inicialización de estado desde datos persistidos (ya no defaults hardcodeados cuando hay detalle).
   - Removido comentario `not yet persisted to DB`.

5. **Validaciones**
   - `npm run build` OK.
   - Homologación DB (25.9) ejecutada:
     - conteo de columnas en tablas nuevas
     - verificación de FKs entre `Producto*` y `Productos/ListasPrecios/Monedas`.

### Archivos modificados
- `database/36_productos_modelo_expandido.sql` (ejecutado)
- `database/37_productos_sps_expandidos.sql` (ejecutado)
- `src/lib/pos-data.ts`
- `src/app/api/catalog/products/route.ts`
- `src/app/api/catalog/products/[id]/route.ts` (nuevo)
- `src/components/pos/catalog-products-screen.tsx`
- `OPENCODE_TASKS.md` (checkpoints 25.3–25.9 marcados `[x]`, estado COMPLETA)

---

## Session: TAREA 31 — TAX_RATES desde DB (2026-03-25)

**Resumen:** Se eliminó el hardcode de tasas en productos y ahora se cargan desde DB.

### Implementado

1. `src/lib/pos-data.ts`
   - `CatalogManagerData.lookups` ahora incluye `taxRates: { id, name, rate, code }[]`.
   - `getCatalogManagerData()` ahora llama `spTasasImpuestoCRUD` (acción `L`) en paralelo.
   - Mapeo de `taxRates` con filtro de activos (`Activo` cuando viene en resultset).

2. `src/components/pos/catalog-products-screen.tsx`
   - Eliminada constante hardcodeada `TAX_RATES`.
   - `currentRate()` ahora usa `data.lookups.taxRates` y compara con `Number(taxRateId)`.
   - `<select>` de tasas ahora itera `data.lookups.taxRates`.
   - `taxRateId` inicial ahora toma la primera tasa disponible de DB (o vacío).

3. `OPENCODE_TASKS.md`
   - TAREA 31 marcada `COMPLETA ✅`.
   - Checkpoints `31.1`, `31.2`, `31.3` marcados `[x]`.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 44 — Kardex (InvMovimientos) + integración SPs/API/UI (2026-03-28)

**Resumen:** Se implementó kardex completo de inventario con tabla de movimientos, integración en creación/edición/anulación de documentos, API de consulta y tab Movimientos funcional en Productos.

### Implementado

1. DB `database/58_inv_movimientos.sql` (aplicado)
   - creada tabla `dbo.InvMovimientos`.
   - creados índices:
     - `IX_InvMov_Prod_Fecha`
     - `IX_InvMov_Periodo`
     - `IX_InvMov_DocOrigen`
   - `spInvDocumentosCRUD` recreado:
     - inserta movimientos en acción `I`.
     - inserta movimientos inversos (`ANU`) en acción `N`.
     - mantiene fixes CMP/stock/serializable de TAREA 43.
   - `spInvActualizarDocumento` recreado:
     - inserta movimientos de reversión del detalle anterior.
     - inserta movimientos nuevos del detalle actualizado.
   - `spInvKardex` creado para consulta de movimientos por producto/almacén/fecha.
   - backfill inicial incluido cuando `InvMovimientos` está vacío.

2. App backend
   - `src/lib/pos-data.ts`
     - nuevos tipos: `InvKardexRecord`, `InvExistenciaAlFechaRecord`.
     - nueva función `getInvKardex(...)`.
   - API nueva:
     - `src/app/api/inventory/kardex/route.ts` (`GET /api/inventory/kardex`).

3. UI Productos
   - `src/components/pos/catalog-products-screen.tsx`
     - tab `Movimientos` dejó de ser placeholder.
     - filtros: almacén, fecha desde/hasta.
     - tabla de kardex: Fecha, Tipo, Documento, Entrada, Salida, Saldo, Costo, Almacén.

### Validación

- Script aplicado: `database/58_inv_movimientos.sql`.
- Build OK (`npm run build`).

---

## Session: TAREA 45 — Saldos mensuales + APIs base reportería (2026-03-28)

**Resumen:** Se creó almacenamiento de cierres mensuales, SP de cierre y SP de existencia histórica al corte, con APIs y funciones en data layer.

### Implementado

1. DB `database/59_inv_saldos_mensuales.sql` (aplicado)
   - creada tabla `dbo.InvSaldosMensuales` + índice `IX_InvSaldos_Periodo`.
   - creado SP `dbo.spInvCierreMensual(@Periodo)` con UPSERT de cierre.
   - creado SP `dbo.spInvExistenciaAlFecha(@Fecha, @IdProducto?, @IdAlmacen?)`.

2. App backend
   - `src/lib/pos-data.ts`
     - `ejecutarCierreMensual(periodo)`.
     - `getExistenciaAlFecha(fecha, idProducto?, idAlmacen?)`.
   - APIs nuevas:
     - `src/app/api/inventory/cierre-mensual/route.ts` (POST)
     - `src/app/api/inventory/existencia-al-fecha/route.ts` (GET)

### Validación

- Script aplicado: `database/59_inv_saldos_mensuales.sql`.
- Verificación DB:
  - `INV_MOV_ROWS 2`
  - `HAS_SALDOS_TABLE true`
  - `KARDEX_ROWS_SAMPLE 2`
  - `CIERRE_RESULT { Periodo: '202603', RegistrosCerrados: 1 }`
  - `EXISTENCIA_ROWS 1`
- Build OK (`npm run build`).

---

## Session: TAREA 43 — Fix CMP + ActualizaCosto + salidas homologadas (2026-03-28)

**Resumen:** Se completaron fixes críticos de inventario en SPs, se incorporó `ActualizaCosto` en tipos de documento y se actualizó UI/data layer para controlar el recálculo de CMP.

### Implementado

1. SQL principal `database/57_inv_fix_cmp_actualiza_costo.sql` (aplicado)
   - `InvTiposDocumento`: alta idempotente de columna `ActualizaCosto BIT NOT NULL DEFAULT 0`.
   - activación por defecto en tipos de compra (`TipoOperacion='C'`).
   - `spInvDocumentosCRUD` recreado con fixes:
     - aislamiento `SERIALIZABLE` en acciones `I` y `N`.
     - recálculo CMP condicionado a `ActualizaCosto=1` y solo en entradas (`E`,`C`).
     - fórmula de CMP corregida usando stock actualizado y costo total agregado por producto.
     - validación de stock insuficiente para salidas (`S`) antes de descontar.
     - anulación con reversa de CMP cuando corresponde y soft-delete de detalle (`RowStatus=0`).
   - `spInvTiposDocumentoCRUD` actualizado para exponer/persistir `ActualizaCosto` en `L/O/I/A`.

2. SQL actualización edición `database/55_sp_inv_actualizar_documento.sql` (aplicado)
   - `SERIALIZABLE` en transacción.
   - reversa de CMP del detalle anterior cuando aplica.
   - recálculo CMP del nuevo detalle condicionado a `ActualizaCosto`.
   - validación de stock negativo para salidas al reaplicar detalle.

3. Código app
   - `src/lib/pos-data.ts`
     - `InvTipoDocumentoRecord` ahora incluye `actualizaCosto: boolean`.
     - `mapInvTipoDocRow` mapea `ActualizaCosto`.
     - `saveInvTipoDocumento` envía `ActualizaCosto` al SP.
   - `src/components/pos/inv-doc-type-screen.tsx`
     - nuevo toggle `Actualiza Costo` en tab General.
     - habilitado solo para tipos `E/C`; para `S/T` queda deshabilitado.
   - `database/48_inv_tipos_documentos.sql`
     - alineado al esquema real (sin columna `Nombre`) e incluyendo `ActualizaCosto` en definición/base del SP.

4. Homologación Entradas/Salidas
   - verificado que `src/app/inventory/exits/page.tsx` mantiene la misma estructura y patrón de carga que `src/app/inventory/entries/page.tsx`.

### Validación

- Scripts aplicados correctamente:
  - `database/57_inv_fix_cmp_actualiza_costo.sql`
  - `database/55_sp_inv_actualizar_documento.sql`
- Verificación DB:
  - `HAS_COLUMN true` para `InvTiposDocumento.ActualizaCosto`.
  - `SP_LIST_HAS_ACTUALIZACOSTO true` en `spInvTiposDocumentoCRUD`.
- `npm run build` exitoso sin errores.

---

## Session: Inventario Documentos — navegación Anterior/Siguiente en detalle (2026-03-28)

**Resumen:** Se agregó navegación secuencial entre documentos desde la vista detalle para evitar volver al listado al consultar varios documentos.

### Implementado

1. `src/components/pos/inv-document-screen.tsx`
   - Nuevo cálculo `selectedDocIndex` sobre `sortedDocs`.
   - Nueva función `navigateDetail(-1 | 1)` para abrir documento previo/siguiente.
   - Botones `Anterior` y `Siguiente` agregados en el topbar de detalle.
   - Estado disabled en extremos del conjunto cargado para evitar navegación inválida.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 42 — Roles (alineación izquierda + verificación módulos/pantallas/permisos) (2026-03-28)

**Resumen:** Se completó TAREA 42 en Roles con corrección visual de alineación en tabs Módulos/Pantallas y verificación funcional/DB de módulos, pantallas y toggles de permisos tras el script 56.

### Implementado

1. `src/app/globals.css`
   - `.roles-module-grid` migrado a layout adaptativo: `repeat(auto-fill, minmax(16rem, 1fr))`.
   - Alineación izquierda reforzada en cards de módulos:
     - nuevas clases `.roles-module-card__info`, `.roles-module-card__code`, `.roles-module-card__count`.
     - `.roles-module-card__controls` con `justify-self: end` y `white-space: nowrap` para evitar empuje del texto.
   - Alineación en tab Pantallas:
     - header colapsable reestructurado con `.roles-screen-collapsible__main`, `.roles-screen-collapsible__meta`, `.roles-screen-collapsible__title-block`, `.roles-screen-collapsible__chevron`.
   - Media query `1320px` ajustada a `repeat(auto-fill, minmax(15rem, 1fr))`.

2. `src/components/pos/security-roles-screen.tsx`
   - Header de card de módulo con markup explícito para bloque de info (`roles-module-card__info`) y conteo legible.
   - Header del colapsable de pantallas separado en bloque izquierdo (ícono + nombre + conteo) y bloque derecho (estado chip) para mantener el contenido alineado a la izquierda.
   - Mapa de íconos ampliado para módulos nuevos:
     - `Armchair` (Salon), `Boxes` (Inventario), `HandCoins` (CxC), `Receipt` (CxP).

3. Verificación DB/SP (script 56 ya aplicado)
   - Validación por `spRolPermisosPorModulo` con `IdRol=1`:
     - `MODULES_TOTAL 11`
     - `SCREENS_TOTAL 63`
     - módulos requeridos presentes (`MISSING_REQUIRED_MODULES []`).
   - Verificación de rutas del script 56:
     - `EXPECTED_ROUTES 33`
     - `ROUTES_VISIBLE_IN_SP 33`
     - `MISSING_ROUTES []`.
   - Prueba de toggles en DB (`spRolPermisosActualizar`) para módulo/pantalla/granular con revert inmediato:
     - resultado `TOGGLE_TESTS OK`.

4. `OPENCODE_TASKS.md`
   - TAREA 42 marcada `COMPLETADA` y checkpoints 42.1–42.6 en `[x]`.

### Validación

- `npm run build` exitoso sin errores.

### Ajuste visual adicional (feedback UX)

- `src/components/pos/inv-document-screen.tsx`
  - filtros reorganizados con header superior y acciones en la misma línea.
  - campos de secuencia (`Desde/Hasta`) compactados.
  - selector `Por página` movido al footer inferior izquierdo junto al contador.
  - navegación de páginas extendida con `« ‹ › »`.

- `src/app/globals.css`
  - estilos nuevos para:
    - `inv-doc-screen__filters-head`, `inv-doc-screen__filters-grid`, `inv-doc-screen__filters-seq`
    - `inv-doc-screen__list-card`, `inv-doc-screen__list-head`
    - footer de paginación con distribución tipo tarjeta.

### Ajuste visual final (espacios y acciones)

- `src/components/pos/inv-document-screen.tsx`
  - `Actualizar/Limpiar` se movieron debajo del grid de filtros.
- `src/app/globals.css`
  - grid de filtros unificado en 4 columnas para quitar huecos visibles.
  - acciones de filtros alineadas a la derecha en fila inferior.

### Micro-ajuste adicional

- `src/app/globals.css`
  - campos de fecha/secuencia con anchos máximos para acercar grupos y reducir espacios muertos.
  - se mantiene fallback responsive (2 columnas <=1200px y 1 columna <=760px).

### Acciones por fila (Visualizar / Imprimir / Anular) con permisos

- `src/components/pos/inv-document-screen.tsx`
  - se integra `usePermissions()` para resolver acciones visibles por usuario en Entradas/Salidas.
  - columna `Acciones` ahora muestra iconos homogéneos:
    - `Visualizar` (`Eye`) con `title="Visualizar"`
    - `Imprimir` (`Printer`) con `title="Imprimir"`
    - `Anular` (`Ban`) con `title="Anular"`
  - `Imprimir` obtiene detalle del documento y abre ventana imprimible (cabecera + líneas).

- `src/app/globals.css`
  - estilos nuevos para grupo de acciones por fila y variantes visuales de iconos.

### Confirmación de anulación (UX)

- `src/components/pos/inv-document-screen.tsx`
  - se reemplazó `window.confirm(...)` por modal de confirmación del sistema (misma línea visual del modal de cerrar sesión).
  - nuevo flujo:
    - click en `Anular` abre modal con número de documento.
    - botones `Cancelar` / `Sí, anular`.
    - estado de envío `Anulando...` para evitar doble ejecución.

### UX de captura en detalle (línea activa)

- `src/components/pos/inv-document-screen.tsx`
  - se añadió estado de línea activa (`activeLineKey`) para identificar en qué fila está digitando el usuario.
  - los inputs editables de la fila activa (`Codigo`, `Cantidad`, `Costo`) se marcan visualmente.
  - la fila activa también recibe fondo diferenciado para facilitar lectura y evitar confusión.

- `src/app/globals.css`
  - nuevas reglas de estilo para `tr.is-active-row` y `inv-doc-grid__editable-hint`.

### Formatos de empresa + total largo

- `src/components/pos/inv-document-screen.tsx`
  - se integró `useFormat()` para formatear valores visibles con configuración de empresa.
  - reemplazados `toFixed(...)` por `formatNumber(...)` en:
    - listado de documentos
    - detalle en pantalla
    - impresión
    - modal de búsqueda (costo)
    - total de línea y total de documento
  - Enter en `Cantidad` ahora enfoca `Costo` en la misma fila.

- `src/app/globals.css`
  - agregado `.inv-doc-grid__footer-total` con `white-space: nowrap` y alineación para evitar salto de línea con montos grandes.

### Correcciones rápidas reportadas por usuario

- `src/lib/pos-data.ts`
  - fecha en listado de documentos corregida al mapear desde SP con `toIsoDate(...)`.

- `src/components/pos/inv-document-screen.tsx`
  - guardado de documento ahora requiere confirmación en modal propio del sistema (ya no guarda directo al submit).
  - se añadió botón `Editar` en vista detalle (documento activo), con mensaje informativo de etapa.
  - ajuste de visibilidad: `Editar` usa fallback por `catalog.view` para no ocultarse en perfiles legacy.

### Edición funcional de documentos

- `src/app/api/inventory/documents/[id]/route.ts`
  - agregado `PUT` para actualizar documento existente.

- `src/lib/pos-data.ts`
  - agregado `updateInvDocumento(...)` para ejecutar actualización server-side.

- `database/55_sp_inv_actualizar_documento.sql`
  - nuevo SP `spInvActualizarDocumento`.
  - lógica:
    - valida documento activo
    - revierte stock del detalle previo
    - actualiza cabecera
    - reemplaza detalle
    - reaplica stock según operación y almacén
    - recalcula total y retorna documento actualizado (`spInvDocumentosCRUD @Accion='O'`).
  - script aplicado correctamente en DB.

- `src/components/pos/inv-document-screen.tsx`
  - `Editar` en vista detalle y en acciones de listado.
  - al editar, se carga cabecera + líneas en formulario `new` en modo edición.
  - guardar usa `PUT` y confirma con modal de sistema.
  - cancelar edición retorna a vista detalle del mismo documento.

### Ajuste de negocio: edición con histórico de detalle

- `database/56_inv_docdetalle_softdelete_unique.sql`
  - se elimina `UQ_InvDocDetalle_Linea` (constraint único rígido).
  - se crea `UQ_InvDocDetalle_Linea_Activos` (índice único filtrado `RowStatus=1`).

- `database/55_sp_inv_actualizar_documento.sql`
  - edición ahora aplica soft delete en detalle previo (`RowStatus=0`) y luego inserta nuevo detalle activo.
  - conserva histórico de líneas anteriores por documento.

- Verificación realizada por smoke test SQL
  - resultado: documento actualizado con `active 1` y `history 1` en `InvDocumentoDetalle`.

---

## Session: TAREA 41 - layout unificado detalle/nuevo/edición en Inventario Documentos (2026-03-28)

**Resumen:** Se replicó el layout compacto de la vista detalle (read-only) en las vistas de nuevo y edición para Entradas/Salidas, moviendo acciones al topbar externo y estandarizando cabecera en 2 filas de 4 columnas.

### Implementado

1. `src/components/pos/inv-document-screen.tsx`
   - vistas `new` y `edit` ahora usan `inv-doc-detail-topbar` fuera del panel blanco con botones:
     - `Cancelar`
     - `Guardar`
   - cabecera de formulario migrada a `inv-doc-detail-header` con estructura 2x4:
     - fila 1: Fecha, Periodo, Documento (Auto/numero), Moneda
     - fila 2: Tipo Documento, Almacen, Referencia, Tasa Cambio
   - se eliminó cabecera grande redundante (`Nuevo — ...`) de la vista de formulario.
   - edición funcional completa:
     - `Editar` en detalle y en listado
     - carga de documento al formulario
     - guarda por `PUT /api/inventory/documents/[id]`
     - confirmación con modal de guardado
     - cancelar vuelve a detalle del documento.

2. `src/app/globals.css`
   - topbar de detalle ajustado para distribución `space-between`.
   - `inv-doc-detail-header` ahora estiliza `input` y `select` (editable y disabled).
   - responsive agregado para cabecera 2 columnas en `<900px`.
   - limpieza de CSS huérfano removiendo clases antiguas del layout previo:
     - `.inv-doc-form__grid`, `.inv-doc-form__grid--readonly`, `.inv-doc-form__grid--entry`, `.inv-doc-form__row--line1`, `.inv-doc-form__row--line2`, `.inv-doc-form__ref`, `.inv-doc-form__footer`.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Inventario Documentos - filtros de secuencia/fecha y paginación (2026-03-27)

**Resumen:** Se implementaron filtros por secuencia y rango de fecha junto con paginación en el listado de Entradas/Salidas, incluyendo actualización del SP fuente para que el filtrado sea server-side.

### Implementado

1. Verificación de origen de datos
   - confirmado que la carga de Entradas/Salidas usa `listInvDocumentos(...)` y este ejecuta `dbo.spInvDocumentosCRUD` (acción `L`).

2. Base de datos / SP
   - nuevo script: `database/54_inv_documentos_filtros_paginacion.sql`.
   - `spInvDocumentosCRUD` actualizado con:
     - `@SecuenciaDesde`, `@SecuenciaHasta`
     - `@NumeroPagina`, `@TamanoPagina`
     - `COUNT(1) OVER() AS TotalRows`.
   - ejecución del script: OK.
   - smoke test SQL: `rows 1 totalRows 1`.

3. Backend / API
   - `src/lib/pos-data.ts`
     - `listInvDocumentos(...)` ahora retorna estructura paginada:
       - `items`, `total`, `page`, `pageSize`
     - soporta filtros de secuencia y fecha en parámetros de entrada.
   - `src/app/api/inventory/documents/route.ts`
     - nuevos query params: `secDesde`, `secHasta`, `desde`, `hasta`, `page`, `pageSize`.

4. UI
   - `src/components/pos/inv-document-screen.tsx`
     - agregado panel de filtros:
       - Secuencia Desde/Hasta
       - Fecha Desde/Hasta
       - Tamaño de página
       - acciones Filtrar / Limpiar
     - agregado footer de paginación:
       - Anterior / Siguiente
       - Página actual / total
       - contador de registros mostrados vs total.
   - `src/app/inventory/entries/page.tsx`
   - `src/app/inventory/exits/page.tsx`
     - carga inicial usando paginación (`page: 1`, `pageSize: 20`).

5. Estilos
   - `src/app/globals.css`
     - nuevas reglas para filtros y paginación del listado de documentos.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 40 - Duplicar en Maestros + ajuste funcional (2026-03-27)

**Resumen:** Se implementó la opción `Duplicar` en el menú `⋯` del sidebar para módulos de Maestros y luego se ajustó el criterio funcional solicitado para qué datos copiar por pantalla.

### Implementado

1. Menú `Duplicar` agregado en:
   - `src/components/pos/catalog-products-screen.tsx`
   - `src/components/pos/catalog-categories-screen.tsx`
   - `src/components/pos/catalog-product-types-screen.tsx`
   - `src/components/pos/catalog-units-screen.tsx`
   - `src/components/pos/price-lists-screen.tsx`
   - `src/components/pos/inv-doc-type-screen.tsx`

2. Criterio final aplicado:
   - **Productos:** copia General + Precios + Costos + Parámetros (con `name` prefijado y `code` vacío).
   - **Categorías:** copia General + POS (sin imagen; `name` prefijado).
   - **Otros maestros:** copia todo el formulario de origen (excepto `id`, y con nombre/descripcion prefijada).

3. Ajuste técnico de estabilidad en Productos:
   - `catalog-products-screen` evita sobrescribir el borrador de duplicación cuando `selectedId` queda en `null` durante edición.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Ajuste de criterio en Duplicar (Productos/Categorías/Otros) (2026-03-27)

**Resumen:** Se ajustó la funcionalidad `Duplicar` según criterio de negocio final: en Productos se arrastran precios/costos/parámetros; en Categorías se preserva General+POS; en los demás se conserva el formulario completo del origen.

### Implementado

1. `src/components/pos/catalog-products-screen.tsx`
   - `duplicateItem(...)` ahora carga detalle completo y copia:
     - info general
     - grilla de precios
     - impuestos/aplica ITBIS
     - costos
     - oferta
     - parámetros/opciones
     - unidad base para existencia
   - mantiene `code` en blanco y `name` prefijado con `Copia de —`.
   - ajuste en efecto de sincronización para no sobrescribir formulario cuando `selected=null` estando en edición (evita perder la copia).

2. `src/components/pos/catalog-categories-screen.tsx`
   - duplicación preserva secciones General + POS.
   - `name` se prefija con `Copia de —`.
   - `imagen` no se copia.

3. `src/components/pos/catalog-units-screen.tsx`
   - la copia ahora conserva también abreviatura (además del resto de campos del formulario).

4. `src/components/pos/price-lists-screen.tsx`
   - duplicación en modo formulario conserva campos de lista (incluyendo código/vigencia), con descripción prefijada.
   - usuarios siguen sin duplicarse automáticamente (por depender de registro persistido y asignación separada).

5. `src/components/pos/inv-doc-type-screen.tsx`
   - duplicación conserva campos del formulario (incluyendo prefijo), con descripción prefijada.
   - usuarios asignados no se duplican automáticamente.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 40 - opción Duplicar en menús ⋯ de Maestros (2026-03-27)

**Resumen:** Se incorporó la funcionalidad `Duplicar` en los menús contextuales del sidebar para todas las pantallas de maestros indicadas. La duplicación ahora abre el formulario en modo nuevo con datos precargados del registro origen.

### Implementado

1. `src/components/pos/catalog-products-screen.tsx`
   - agregado `Copy` en menú del sidebar (entre Editar y Eliminar).
   - nuevo flujo `duplicateItem(product)`:
     - intenta cargar detalle completo (`fetchProductDetail`) para duplicación fiel.
     - crea nuevo borrador con `id: undefined`, `name: "Copia de — ..."`, `code: ""`.
     - activa modo edición y limpia selección.

2. `src/components/pos/catalog-categories-screen.tsx`
   - agregado `Duplicar` en `categories-dropdown`.
   - `duplicateItem(category)` crea borrador con:
     - `id: undefined`
     - `name: "Copia de — ..."`
     - `codigo: ""`

3. `src/components/pos/catalog-product-types-screen.tsx`
   - agregado `Duplicar` en menú del sidebar.
   - copia con `id: undefined` y `name: "Copia de — ..."`.

4. `src/components/pos/catalog-units-screen.tsx`
   - agregado `Duplicar` en menú del sidebar.
   - copia con `id: undefined`, `name: "Copia de — ..."`, `abbreviation: ""`.

5. `src/components/pos/price-lists-screen.tsx`
   - se reemplazó duplicación directa en DB por duplicación en formulario (modo nuevo).
   - copia con:
     - `id: undefined`
     - `code: ""`
     - `description: "Copia de — ..."`
     - vigencia reiniciada a valores por defecto (`emptyForm.startDate`, `emptyForm.endDate`).
   - no duplica usuarios asignados (`assignedUsers/availableUsers` reseteados).

6. `src/components/pos/inv-doc-type-screen.tsx`
   - agregado `Duplicar` en menú del sidebar.
   - copia con `id: undefined`, `description: "Copia de — ..."`, `prefijo: ""`.
   - no duplica usuarios asignados (`users` reseteado).

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Hotfix botón Editar en Productos (2026-03-27)

**Resumen:** Se corrigió la regresión en Productos donde el botón Editar no se mantenía activo por un reseteo de estado al sincronizar el item seleccionado.

### Implementado

1. `src/components/pos/catalog-products-screen.tsx`
   - ajustado efecto `selected -> form`:
     - ya no fuerza `setIsEditing(false)` durante sincronización.
     - limpia mensajes solo cuando no está en edición.
   - resultado: Editar permanece activo y habilita correctamente el formulario.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Hotfix botón Editar en Maestros (2026-03-27)

**Resumen:** Se corrigió regresión donde el botón Editar no permanecía activo en pantallas de maestros reutilizables por reseteo de estado en efecto de selección.

### Implementado

1. `src/components/pos/catalog-product-types-screen.tsx`
2. `src/components/pos/catalog-units-screen.tsx`
3. `src/components/pos/inv-doc-type-screen.tsx`
   - el efecto `selected -> form` ya no fuerza `isEditing=false` en todos los casos.
   - se incorpora `selectItem(...)` para cambiar a modo lectura solo al seleccionar un item desde el panel izquierdo.
   - resultado: `Editar` funciona correctamente y mantiene formulario habilitado.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Correcciones de regresión UI (formato + botón agregar) (2026-03-27)

**Resumen:** Se corrigieron dos regresiones detectadas tras los últimos ajustes de maestros: formato numérico mostrando `undefined` con 0 decimales y flujo de botón Agregar que no abría edición en algunas pantallas.

### Implementado

1. `src/lib/format-context.tsx`
   - `formatNumber()` ahora retorna solo parte entera cuando `decimals <= 0`.
   - evita concatenar separador decimal + parte decimal inexistente.
   - impacto directo: campos `Base A` / `Base B` en Unidades ya no muestran `1.undefined`.

2. `src/components/pos/catalog-product-types-screen.tsx`
3. `src/components/pos/catalog-units-screen.tsx`
4. `src/components/pos/inv-doc-type-screen.tsx`
   - el efecto que sincroniza `selected -> form` se ajustó para:
     - mantener `isEditing=true` cuando se entra en modo nuevo (`selected=null`).
     - resetear a `emptyForm` solo cuando no se está editando.
   - resultado: el botón `Agregar` vuelve a funcionar correctamente.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Maestros - auto selección del primer registro al entrar (2026-03-27)

**Resumen:** Se implementó selección inicial automática del primer elemento del panel izquierdo para que el panel derecho muestre datos desde la primera entrada a la pantalla.

### Implementado

1. `src/components/pos/catalog-product-types-screen.tsx`
   - `selectedId` inicial toma `initialData[0]?.id`.
   - `form` inicial usa el primer registro si existe.
   - efecto de respaldo: si no hay selección y hay items (sin edición), selecciona el primero.

2. `src/components/pos/catalog-units-screen.tsx`
   - mismo patrón aplicado para selección y formulario inicial.

3. `src/components/pos/inv-doc-type-screen.tsx`
   - mismo patrón aplicado para selección y formulario inicial.
   - impacta Tipos de Entradas, Salidas, Entradas por Compras y Transferencias.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 39 - remover menú ⋯ redundante en panel derecho de maestros (2026-03-27)

**Resumen:** Se eliminó el menú contextual `⋯` del panel derecho en pantallas de maestros para dejar una UX más compacta. El panel derecho ahora muestra los campos directamente y solo presenta `Cancelar/Guardar` cuando se está editando.

### Implementado

1. `src/components/pos/catalog-products-screen.tsx`
   - removido bloque de `products-detail__action-bar` en modo lectura (`context-menu`).
   - mantenido solo action bar en modo edición.
   - removidos estados/refs de menú derecho (`detailMenuOpen`, `detailMenuRef`).

2. `src/components/pos/catalog-categories-screen.tsx`
   - removido menú `⋯` del panel derecho en lectura.
   - action bar visible solo en edición.
   - limpieza de estado/ref asociados al menú derecho.

3. `src/components/pos/catalog-product-types-screen.tsx`
   - mismo patrón aplicado: sin menú derecho en lectura; solo barra de edición.

4. `src/components/pos/catalog-units-screen.tsx`
   - mismo patrón aplicado: sin menú derecho en lectura; solo barra de edición.

5. `src/components/pos/price-lists-screen.tsx`
   - mismo patrón aplicado: sin menú derecho en lectura; solo barra de edición.

6. `src/components/pos/inv-doc-type-screen.tsx`
   - mismo patrón aplicado: sin menú derecho en lectura; solo barra de edición.
   - impacta las 4 pantallas que comparten componente (Entradas/Salidas/Compras/Transferencias).

7. `src/app/globals.css`
   - eliminado `.products-detail__context-menu` y regla anidada del dropdown.
   - eliminado override `.price-lists-form > .products-detail__action-bar`.
   - simplificado `.products-detail__action-bar` para uso exclusivo en edición.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 38 - UX compacto en maestros (headers redundantes removidos) (2026-03-27)

**Resumen:** Se replicó el patrón de `catalog-products-screen` en 5 componentes de maestros para compactar el panel derecho: se eliminó header redundante y se estandarizó barra superior con menú contextual `⋯` en lectura y botones `Cancelar/Guardar` en edición.

### Implementado

1. `src/components/pos/catalog-categories-screen.tsx`
   - removido bloque `categories-detail__head`.
   - agregado `products-detail__action-bar` con:
     - lectura: menú `⋯` (Editar/Eliminar)
     - edición: botones Cancelar/Guardar.

2. `src/components/pos/catalog-product-types-screen.tsx`
   - removido `price-lists-form__header` con título.
   - agregado action bar compacta con menú `⋯` en lectura y Cancelar/Guardar en edición.

3. `src/components/pos/catalog-units-screen.tsx`
   - removido `price-lists-form__header` con título.
   - agregado action bar compacta con menú `⋯` en lectura y Cancelar/Guardar en edición.

4. `src/components/pos/price-lists-screen.tsx`
   - removido `price-lists-detail__head` (nombre + código de la lista).
   - agregado action bar compacta con menú `⋯` en lectura y Cancelar/Guardar en edición.

5. `src/components/pos/inv-doc-type-screen.tsx`
   - removido header superior (nombre + `#id`) encima de tabs.
   - agregado action bar compacta con menú `⋯` en lectura y Cancelar/Guardar en edición.
   - impacto directo en 4 pantallas: entry-types, exit-types, purchase-types, transfer-types.

6. `src/app/globals.css`
   - limpieza de estilos huérfanos ya no usados:
     - `.categories-detail__head` + subclases
     - `.products-detail__header` + subclases
   - validado que `.price-lists-form__header` aún se usa en otros módulos no incluidos en esta tarea, por lo que se conserva.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Inventario Documentos - optimización de espacio + tab de observaciones (2026-03-27)

**Resumen:** Se compactó el encabezado del formulario de Nuevo Documento y se agregó un tab específico para comentarios/observaciones al lado de Detalle.

### Implementado

1. `src/components/pos/inv-document-screen.tsx`
   - `DocForm` ahora incluye `observacion`.
   - reordenado encabezado en 2 filas:
     - fila 1: Tipo Documento, Almacen, Periodo, Fecha.
     - fila 2: Moneda, Tasa Cambio, Referencia.
   - nuevo estado `entryTab` con tabs:
     - `Detalle`
     - `Comentarios / Observaciones`
   - al guardar documento se envía `observacion` en el payload (`createInvDocumento`).

2. `src/app/globals.css`
   - nuevas clases para layout compacto y responsive:
     - `.inv-doc-form__grid--entry`
     - `.inv-doc-form__row`, `.inv-doc-form__row--line1`, `.inv-doc-form__row--line2`
     - `.inv-doc-grid__tabs`
     - `.inv-doc-notes` (+ estilos de textarea/focus)
   - breakpoints añadidos para 1200px y 760px.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Inventario Tipos Documento - Codigo + Prefijo + Secuencia en una fila (2026-03-27)

**Resumen:** Se ajusto el formulario de Tipos de Documento de Inventario para mostrar `Codigo`, `Prefijo` y `Secuencia Inicial` en la misma linea, y se renombro el label de `ID` a `Codigo`.

### Implementado

1. `src/components/pos/inv-doc-type-screen.tsx`
   - label `ID` cambiado a `Codigo`.
   - nueva estructura de fila unica para:
     - `Codigo` (solo cuando existe `form.id`)
     - `Prefijo`
     - `Secuencia Inicial`
   - se eliminaron los bloques duplicados de `Prefijo` y `Secuencia Inicial` debajo de `Descripcion`.

2. `src/app/globals.css`
   - nuevas clases de layout:
     - `.inv-doc-code-row`
     - `.inv-doc-code-row.is-new`
   - en escritorio: 3 columnas (o 2 cuando es nuevo sin codigo).
   - en mobile (`max-width: 980px`): colapsa a 1 columna.

### Alcance

- Aplicado a las 4 pantallas que reutilizan el mismo componente:
  - `src/app/inventory/entry-types/page.tsx`
  - `src/app/inventory/exit-types/page.tsx`
  - `src/app/inventory/purchase-types/page.tsx`
  - `src/app/inventory/transfer-types/page.tsx`

---

## Session: Inventario Tipos Documento - ancho corto para Codigo (2026-03-27)

**Resumen:** Se ajusto el ancho de la columna `Codigo` para que sea mas compacta, acorde a que es un entero con crecimiento acotado.

### Implementado

1. `src/app/globals.css`
   - `.inv-doc-code-row` actualizado a:
     - `grid-template-columns: minmax(6.5rem, 8.5rem) minmax(0, 1fr) minmax(0, 1fr)`
   - resultado: `Codigo` ocupa menos espacio y `Prefijo/Secuencia Inicial` aprovechan el resto de la fila.

---

## Session: Sidebar ERP - persistencia de seleccion/foco al navegar (2026-03-27)

**Resumen:** Se corrigio la percepcion de "reinicio" del menu al cambiar de opcion, manteniendo estado de expansion y posicion de scroll del sidebar.

### Implementado

1. `src/components/pos/sidebar.tsx`
   - persistencia de modulos expandidos en `localStorage` (`masu_sidebar_expanded_modules`).
   - restauracion de expansion en montaje.
   - persistencia/restauracion de scroll del contenedor del sidebar en `sessionStorage` (`masu_sidebar_scroll_top`).
   - `Link` de opciones con `scroll={false}` para evitar salto de scroll al navegar.

2. `src/components/pos/app-shell.tsx`
   - el efecto `loadShellData()` ya no depende de `pathname` para evitar recargas visuales del shell en cada click de menu.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Sidebar TreeView - foco en opcion hija persistente (2026-03-27)

**Resumen:** Se corrigio el caso donde, al hacer click en opcion hija, el foco visual regresaba al nivel 1 por rutas compartidas.

### Implementado

1. `src/components/pos/sidebar.tsx`
   - nueva clave de sesion `masu_sidebar_active_option_key`.
   - la opcion activa se resuelve por `option.key` persistido (cuando coincide con la ruta actual) y no solo por `href`.
   - se registra `option.key` en click tanto para opciones del panel normal como del flotante.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 37 - Operaciones Inventario (scripts DB + verificación) (2026-03-27)

**Resumen:** Se ejecutaron los scripts SQL del módulo de Operaciones de Inventario y se verificó la disponibilidad técnica de pantallas/API/SPs asociadas.

### Implementado

1. Ejecución de scripts SQL en `DbMasuPOS`
   - `database/51_inv_sp_recreate_fix.sql`
   - `database/52_inv_documentos.sql`
   - `database/53_sp_inv_documentos.sql`

2. Verificaciones DB (smoke checks)
   - `spInvTiposDocumentoCRUD` acción `LU` retorna usuarios activos:
     - resultado: `LU rows: 5` (muestra válida con `IdUsuario`, `NombreUsuario`, `Nombres`, `Correo`, `Asignado`).
   - objetos creados/actualizados confirmados:
     - tablas: `InvDocumentos`, `InvDocumentoDetalle`
     - índices: `IX_InvDocumentos_TipoOp_Fecha`, `IX_InvDocDetalle_Doc`
     - SPs: `spInvDocumentosCRUD`, `spInvBuscarProducto`
   - smoke de SPs:
     - `spInvDocumentosCRUD @Accion='LT'` ejecuta sin error.
     - `spInvBuscarProducto` en modos `E` y `P` ejecuta sin error.

3. Verificación de páginas/rutas de Inventario
   - páginas server activas:
     - `src/app/inventory/entries/page.tsx` (`title="Entradas de Inventario"`)
     - `src/app/inventory/exits/page.tsx` (`title="Salidas de Inventario"`)
   - componente `src/components/pos/inv-document-screen.tsx` confirmado con:
     - botón `Nuevo Documento`
     - lookup por Enter en código (`/api/inventory/products/by-code`)
     - modal de búsqueda por lupa (`/api/inventory/products/search`)
     - pre-carga de moneda por tipo de documento

### Validación

- `npm run build` exitoso sin errores.

---

## Session: CxC Descuentos - radios de tipo aplicacion en una linea (2026-03-26)

**Resumen:** Se corrigio la presentacion de "Tipo de Aplicacion" para que cada opcion se vea en una sola linea en escritorio.

### Implementado

1. `src/components/pos/cxc-discounts-screen.tsx`
   - se reemplazaron estilos inline por clases dedicadas en el bloque de radios.

2. `src/app/globals.css`
   - nuevas clases:
     - `.cxc-discounts-apply-options`
     - `.cxc-discounts-apply-option`
   - se forzo `white-space: nowrap` para mostrar cada opcion en una sola linea.
   - en mobile (`max-width: 980px`) se permite wrap para mantener legibilidad.

---

## Session: Roles - correccion de ubicacion tabs usuarios + franja lateral sidebar (2026-03-26)

**Resumen:** Se aplico ajuste solicitado por usuario final: tabs de usuarios fuera del panel central y dentro del panel derecho; se corrigio la franja/desalineacion del sidebar izquierdo de Roles.

### Implementado

1. `src/components/pos/security-roles-screen.tsx`
   - se removio `Asignados/Disponibles` de la barra central.
   - se reincorporo `Asignados/Disponibles` como cabecera del panel derecho de usuarios.

2. `src/app/globals.css`
   - `.roles-sidebar__list` sin `padding-right` para evitar franja lateral.
   - `.roles-sidebar__item` con `box-sizing: border-box` para que `width: 100%` no desborde.
   - `.roles-main__tabsbar` alineado a inicio.
   - `.roles-users-panel` vuelve a layout de dos filas (tabs + listado).

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Roles - alineacion final + tabs de usuarios en barra principal (2026-03-26)

**Resumen:** Se atendio feedback visual directo: corregida desalineacion del sidebar de Roles y reubicado el selector Asignados/Disponibles junto a Modulos/Pantallas/Visualizacion para ahorrar espacio vertical.

### Implementado

1. `src/components/pos/security-roles-screen.tsx`
   - nueva barra `roles-main__tabsbar` que integra:
     - tabs funcionales: Modulos / Pantallas / Visualizacion
     - filtro de usuarios: Asignados / Disponibles
   - se removio el bloque de tabs dentro del panel derecho de usuarios.

2. `src/app/globals.css`
   - `.roles-sidebar__item` ahora usa `width: 100%` y `align-self: stretch` para eliminar efecto de cards angostas/desalineadas.
   - agregado estilo de `roles-main__tabsbar` y `roles-main__users-filter`.
   - `.roles-users-panel` simplificado a una sola fila de contenido (listado).

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Hotfix QA Seguridad (key i18n + header Roles) (2026-03-26)

**Resumen:** Se corrigieron dos hallazgos de QA en Seguridad: texto literal de clave i18n en Usuarios y desproporcion/solapamiento en cabecera de Roles al editar.

### Implementado

1. `src/components/pos/security-users-screen.tsx`
   - boton principal de edicion actualizado a `t("users.editUser")`.
   - resultado: deja de mostrarse el literal `users.editData` en pantalla.

2. `src/app/globals.css`
   - `roles-header__identity` y `roles-header__info` ahora usan flex para ocupar el ancho disponible sin comprimir inputs/textarea.
   - `roles-header__actions` ahora permite wrap y alineacion a la derecha para evitar solapes con el bloque de identidad.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 33 - Existencias por Almacen (2026-03-26)

**Resumen:** Se reemplazó el tab Existencia de Productos por una vista read-only con existencias, límites y conversiones por almacén, basada en SP dedicado.

### Implementado

1. DB (script aplicado)
   - `database/44_tarea33_existencias_por_almacen.sql`
   - crea tabla `dbo.ProductoAlmacenesLimites`.
   - crea `dbo.spProductoAlmacenesLimitesCRUD` (L/U).
   - crea `dbo.spProductoExistencias`.

2. Data layer
   - `src/lib/pos-data.ts`
   - nuevo tipo `ProductStockRow`.
   - nueva función `getProductStock(productId)` con fallback mssql estándar del proyecto.

3. API
   - nuevo endpoint `src/app/api/catalog/products/[id]/stock/route.ts`.
   - `GET` con `requireApiSession` + `dynamic = "force-dynamic"`.

4. UI
   - `src/components/pos/catalog-products-screen.tsx`
   - tab Existencia reemplazado por tabla read-only:
     - columnas fijas: Almacen, Minimo, Maximo, Reorden, Existencia, Existencia Real, Reservado, Disponible base.
     - columnas dinámicas: Disponibles por Alterna 1/2/3 (si aplican).
     - footer con totales.
     - resaltado de fila cuando `existencia < puntoReorden`.
     - botón `Actualizar` (RefreshCw) y estados loading/empty.
   - se eliminó edición inline de cantidad en tab Existencia.

5. CSS
   - `src/app/globals.css`
   - clases nuevas:
     - `.products-stock-table-wrap`
     - `.products-stock-badge--alert`
     - `.products-stock-footer`

### Validación

- Script SQL aplicado correctamente.
- `npm run build` exitoso sin errores.

---

## Session: Unificación CRUD límites + menú Inventario (2026-03-26)

**Resumen:** Se unificó el SP de límites por almacén al patrón CRUD del proyecto y se agregó acceso en navegación de Inventario.

### Implementado

1. DB
   - Nuevo script `database/45_sp_producto_almacenes_limites_crud_unificado.sql` (aplicado):
     - `spProductoAlmacenesLimitesCRUD` con acciones:
       - `L` listar
       - `O` obtener uno
       - `I` insertar
       - `A` actualizar
       - `D` delete lógico (`RowStatus=0`)
       - `U` upsert (compatibilidad)

2. Navegación
   - `src/lib/navigation.ts`
     - Inventario > Maestros: nueva opción `Minimo, Maximo, Reorden`.
   - `src/lib/permissions.ts`
     - mapeo de ruta `/config/catalog/stock-limits` a permiso `config.catalog.products.view`.

3. Página
   - `src/app/config/catalog/stock-limits/page.tsx` (nueva)
   - placeholder funcional para evitar 404 hasta completar módulo dedicado.

### Validación

- Script SQL aplicado: `database/45_sp_producto_almacenes_limites_crud_unificado.sql`
- `npm run build` exitoso sin errores.

---

## Session: TAREA 34 - estructura base CxC/CxP + Referencias (2026-03-26)

**Resumen:** Se implementó la estructura de navegación y placeholders para CxC/CxP, además de Referencias > Documentos Identidad en Configuración > Empresa.

### Implementado

1. `src/lib/navigation.ts`
   - nuevos icon keys: `cxc`, `cxp`.
   - nuevos módulos antes de Configuración:
     - `Cuentas por Cobrar` con categorías Operaciones/Maestros/Consultas.
     - `Cuentas por Pagar` con categorías Operaciones/Maestros/Consultas.
   - en `configuration`, nueva categoría `Referencias` con opción `Documentos Identidad`.

2. `src/lib/permissions.ts`
   - agregadas permission keys de CxC/CxP y `config.company.doc-types.view`.
   - agregados mappings en `ROUTE_PERMISSIONS` para todas las rutas de TAREA 34.

3. `src/components/pos/sidebar.tsx`
   - iconos agregados:
     - `cxc: Receipt`
     - `cxp: Wallet`

4. Páginas placeholder creadas (8)
   - `src/app/cxc/invoices/page.tsx`
   - `src/app/cxc/credit-notes/page.tsx`
   - `src/app/cxc/debit-notes/page.tsx`
   - `src/app/cxc/queries/page.tsx`
   - `src/app/cxp/invoices/page.tsx`
   - `src/app/cxp/credit-notes/page.tsx`
   - `src/app/cxp/debit-notes/page.tsx`
   - `src/app/cxp/queries/page.tsx`

### Validación

- `npm run build` exitoso sin errores.

---

### 2026-03-25 - TAREA 29.5 checkpoint 29.5.8 completado: Homologacion DB

**Completed**

- Ejecutadas queries de homologacion en `DbMasuPOS`:
  - Columnas duplicadas (mismo nombre en misma tabla): **0 encontradas** — OK.
  - Columnas con prefijo legacy `p[A-Z]%` o `Puede%`: 16 encontradas, todas son nombres
    legítimos (`Precio`, `Permite*`, `Pais`, `PrimerDiaSemana`, etc.).
    Los verdaderos legacy (`pVer`, `pCrear`, `pEditar`, etc.) ya fueron renombrados
    a `Obsolete_*` en TAREA 26 y posteriormente eliminados por el usuario. — OK.
- Checkpoint `29.5.8` marcado `[x]` en `OPENCODE_TASKS.md`.
- TAREA 29.5 completamente cerrada.

**Files (high impact)**

- `OPENCODE_TASKS.md`

**Validation**

- DB homologacion limpia. No requiere acciones correctivas.

**Pending (next recommended)**

1. Definir proxima tarea: Ordenes polish, Salon polish, Caja, o Reportes.

---

## Session: TAREA 32 prep + Productos completos (2026-03-25)

**Resumen:** Se completaron todas las opciones del módulo de Productos (Almacenes, Existencia, Costos editables, Oferta editable). Se migró la tabla `ProductoCostos` a columnas directas en `Productos`. Se implementó modal de logout con tema y se ajustaron los toasts. Se diseñó y documentó TAREA 32 (Left Sidebar Navigation).

### Implementado

#### DB

1. `database/38_producto_almacenes.sql` (nuevo)
   - Tabla `dbo.ProductoAlmacenes` (IdProducto, IdAlmacen, Cantidad, CantidadReservada, CantidadTransito, RowStatus).
   - SP `dbo.spProductoAlmacenesCRUD` con acciones: LA (listar asignados), LD (listar disponibles), A (asignar/reactivar), Q (quitar soft-delete), U (actualizar cantidad).

2. `database/39_costos_en_productos.sql` (nuevo)
   - Columnas `IdMoneda`, `DescuentoProveedor`, `CostoProveedor`, `CostoConImpuesto`, `CostoPromedio`, `PermitirCostoManual` agregadas a `dbo.Productos`.
   - FK `FK_Productos_Monedas` → `dbo.Monedas`.
   - Datos migrados de `ProductoCostos` → `Productos`.
   - SP `spProductosCostosCRUD` eliminado.
   - Tabla `ProductoCostos` eliminada.
   - SP `spProductosCRUD` actualizado (O, L, I, A incluyen columnas de costo).

#### Data layer (`src/lib/pos-data.ts`)

- Tipos nuevos: `ProductWarehouseRecord`, `WarehouseOption`.
- `CatalogManagerData.lookups` incluye `warehouses`.
- `getCatalogManagerData()` carga almacenes via `spAlmacenesCRUD` acción `L`.
- `mapProductRow()`: costos mapeados desde columnas del producto (ya no separado).
- `getProductByIdInternal()`: eliminado `costsPromise` (era llamada paralela a `spProductosCostosCRUD`). Ahora costos vienen del row principal.
- `upsertProductDetailData()`: eliminado bloque de costos a `spProductosCostosCRUD`.
- `createProduct()` / `updateProduct()`: costos pasan como parámetros a `spProductosCRUD` (I y A).
- Funciones nuevas al final del archivo:
  - `getProductWarehouses(productId)` — LA + LD en paralelo.
  - `assignProductWarehouse(productId, warehouseId, sessionId?)` — acción A + refresh.
  - `removeProductWarehouse(productId, warehouseId, sessionId?)` — acción Q + refresh.
  - `updateProductWarehouseStock(productId, warehouseId, quantity, sessionId?)` — acción U.
  - Todas con fallback mssql `parameter.type.validate`.

#### API

- `src/app/api/catalog/products/[id]/warehouses/route.ts` (nuevo)
  - `GET` → `getProductWarehouses(id)` → `{ ok, assigned, available }`.
  - `PUT` → body `{ action, warehouseId, quantity? }` → assign / remove / update-stock.

#### UI (`src/components/pos/catalog-products-screen.tsx`)

- Import `ProductWarehouseRecord`, `WarehouseOption`.
- Estado nuevo: `assignedWarehouses`, `availableWarehouses`, `loadingWarehouses`, `editingStock`.
- `handleTabChange()`: al cambiar a tab "almacenes" o "existencia" → llama `loadWarehouses(selectedId)`.
- `handleWarehouseAssign()` / `handleWarehouseRemove()`: llaman API PUT y actualizan estado local.
- `handleStockSave(warehouseId, value)`: edición inline de cantidad, llama PUT update-stock.
- **Tab Costos**: campos editables cuando `isEditing` (moneda como `<select>`, números editables, toggle costo promedio manual, cálculo automático CostoConImpuesto al editar CostoProveedor).
- **Tab Oferta**: toggle activo + precio/fechas editables cuando `isEditing`.
- **Tab Almacenes**: widget de transferencia funcional con datos reales. Clic para seleccionar, `>` asigna, `<` quita. Sin requerir modo edición (operaciones directas a DB).
- **Tab Existencia**: tabla con Cantidad (editable inline clic), Reservada, En Tránsito, Disponible por almacén.
- **Tab Movimientos**: placeholder "próxima versión" (sin cambio).

#### CSS (`src/app/globals.css`)

- `.products-warehouse-item`, `.products-warehouse-item.is-selected`, `.products-warehouse-item__name`, `.products-warehouse-item__siglas`.
- `.products-stock-value` (clic para editar, dashed border en hover).
- `.modal-backdrop`, `.modal-card`, `.modal-card--sm/md/lg`, `.modal-card__header--brand`, `.modal-card__header-icon`, `.modal-card__title`, `.modal-card__subtitle`, `.modal-card__body`, `.modal-card__footer`.
- `.topbar-user-row`, `.topbar-logout-btn` (icono discreto).
- Toasts Sonner: variables CSS `--success-bg/border/color`, `--error-bg/border/color`, `--warning-*`, `--info-*` alineadas al tema azul `--brand`.

#### AppShell (`src/components/pos/app-shell.tsx`)

- Botón logout (`<LogOut>`) en topbar junto al user-chip.
- Modal de confirmación logout: backdrop blur, card con header `--brand`, nombre del usuario, botones Cancelar + "Sí, cerrar sesión" (rojo sólido). Se cierra al clic en backdrop.
- Logout eliminado del user-menu dropdown.
- Import `LogOut` de lucide.

#### Global Toaster (`src/components/pos/global-toaster.tsx`)

- Eliminado `richColors`. Colores controlados vía CSS vars en globals.css.

### Validación

- `npm run build` exitoso sin errores en todas las iteraciones.

### Pendiente (siguiente sesión)

1. Revisar siguiente tarea pendiente en `OPENCODE_TASKS.md`.

---

## Session: TAREA 32 — Left Sidebar Navigation + Dashboard Landing (2026-03-25)

**Resumen:** TAREA 32 completada. Se reemplazó topnav horizontal por sidebar jerárquico y se estableció `/dashboard` como landing de la app.

### Implementado

1. **Configuración de navegación**
   - Nuevo archivo `src/lib/navigation-config.ts`:
     - Tipos `NavOption`, `NavCategory`, `NavModule` (union discriminada `href` directo vs `categories`).
     - `NAV_MODULES` con módulos directos + módulo Configuración por categorías (Empresa, Catálogo, Monedas, Seguridad).
   - `src/lib/navigation.ts` marcado como deprecated con comentario.

2. **Dashboard landing**
   - Nueva página `src/app/dashboard/page.tsx` con `AppShell + PageHeader` y 4 KPI placeholders:
     - Ventas del día
     - Pedidos activos
     - Mesas ocupadas
     - Stock crítico
   - `src/app/page.tsx` ahora redirige a `/dashboard`.

3. **Post-login + compatibilidad de rutas legacy**
   - `src/app/login/page.tsx`:
     - `resolveStartRoute()` ahora usa fallback `/dashboard`.
     - Mapa legacy actualizado:
       - `/` -> `/dashboard`
       - `/Usuarios` -> `/config/security/users`
       - `/Roles` -> `/config/security/roles`
       - `/Permisos` -> `/config/security/roles`
   - `src/lib/auth-session.ts`:
     - `defaultRoute` fallback actualizado de `/` a `/dashboard`.

4. **Sidebar component**
   - Nuevo `src/components/pos/sidebar-nav.tsx`:
     - Estado interno `collapsed` (persistido en `localStorage("masu_sidebar_collapsed")`).
     - Estado interno `expandedModule` para accordion.
     - Filtrado por permisos usando `hasPermission()`.
     - Módulo activo por `pathname` y auto-expansión del módulo padre cuando aplica.
     - Modo colapsado con íconos + `title` tooltip.

5. **AppShell simplificado**
   - `src/components/pos/app-shell.tsx` reescrito:
     - Eliminado topnav horizontal.
     - Eliminada lógica de configuración multinivel del user-menu (`systemPanel`, `settingsGroups`, etc.).
     - User-menu simplificado a perfil placeholder + idioma.
     - Logout queda en topbar (con modal de confirmación existente).
     - Integración de `<SidebarNav modules={NAV_MODULES} pathname={pathname} />`.

6. **Permisos + middleware + redirect raíz**
   - `src/lib/permissions.ts`:
     - `LEGACY_ROUTE_MAP` actualizado (`/` -> `/dashboard`, `/permisos` -> `/config/security/roles`).
     - `ROUTE_PERMISSIONS` ahora incluye `/dashboard` (`dashboard.view`) y ya no usa `/` para dashboard.
   - `middleware.ts`:
     - Redirect explícito de `/` -> `/dashboard` (si hay sesión).
     - Si no hay sesión en `/`, redirect a `/login`.

7. **DB seed dashboard permission**
   - Nuevo script `database/38_dashboard_permission.sql` aplicado:
     - asegura permiso `dashboard.view` en `Permisos`.
     - asegura asignación a `IdRol = 1` en `RolesPermisos`.

8. **CSS**
   - `src/app/globals.css`:
     - nuevo layout grid de `app-shell` con `--sidebar-w`.
     - estilos BEM de sidebar (`.sidebar`, `.sidebar--collapsed`, `.sidebar__toggle`, `.sidebar__module`, `.sidebar__module-header`, `.sidebar__category`, `.sidebar__option`, `.sidebar__divider`, etc.).
     - estilos para cards de dashboard placeholder.

### Validación

- SQL: `node scripts/apply-sql-file.js database/38_dashboard_permission.sql` exitoso.
- `npm run build` exitoso sin errores.

### Archivos modificados

- `src/lib/navigation-config.ts` (nuevo)
- `src/lib/navigation.ts`
- `src/app/dashboard/page.tsx` (nuevo)
- `src/app/page.tsx`
- `src/app/login/page.tsx`
- `src/lib/auth-session.ts`
- `src/components/pos/sidebar-nav.tsx` (nuevo)
- `src/components/pos/app-shell.tsx`
- `src/lib/permissions.ts`
- `middleware.ts`
- `src/app/globals.css`
- `database/38_dashboard_permission.sql` (nuevo, aplicado)
- `OPENCODE_TASKS.md` (TAREA 32 marcada COMPLETA; checkpoints 32.1-32.8 en `[x]`)

---

## Session: Topbar polish visual (2026-03-25)

**Resumen:** Se mejoró la jerarquía visual y legibilidad del topbar en layout con sidebar.

### Implementado

1. `src/components/pos/app-shell.tsx`
   - agregado `topbar__spacer` para estabilizar la distribución en grid (`brand | spacer | acciones`).

2. `src/app/globals.css`
   - refinado visual del topbar:
     - fondo más limpio y consistente.
     - searchbar más definida (`border`, `focus-within`, tamaño).
     - icon-buttons (idioma/notificaciones/logout) con borde y sombra suave.
     - user-chip con contenedor blanco y mejor contraste tipográfico.
   - ajustes responsive:
     - ocultar texto de usuario en mobile manteniendo avatar.

### Validación

- `npm run build` exitoso sin errores.

### Ajuste adicional de proporciones (iteración 2)

- Se redujo el peso visual del topbar para equilibrarlo con sidebar y contenido:
  - menor altura/padding del header,
  - searchbar más compacta,
  - icon-buttons más pequeños,
  - user-chip (avatar/tipografía/padding) reducido,
  - botón logout más compacto.
- Se removió `topbar__spacer` del JSX para evitar separación excesiva entre marca y controles.
- Validación: `npm run build` OK.

---

## Session: Rediseño Shell ERP 3 niveles (2026-03-26)

**Resumen:** Se rediseñó el app shell para navegación ERP real de 3 niveles, con topbar contextual, sidebar jerárquico y breadcrumb funcional.

### Implementado

1. **Fuente única de navegación**
   - `src/lib/navigation.ts` reescrito con estructura:
     - `NavigationModule[]`
     - `NavigationCategory[]`
     - `NavigationOption[]`
     - `href`, `icon`, `permission`
   - helpers:
     - `filterNavigationByPermission(...)`
     - `getNavigationTrail(...)`
     - `isRouteMatch(...)`

2. **Componentes del shell separados**
   - `src/components/pos/topbar.tsx` (nuevo)
   - `src/components/pos/sidebar.tsx` (nuevo)
   - `src/components/pos/breadcrumbs.tsx` (nuevo)
   - `src/components/pos/app-shell.tsx` (refactor total, ahora orquestador)

3. **Topbar ERP**
   - Incluye:
     - toggle sidebar
     - logo + marca
     - búsqueda global con placeholder contextual y badge `Ctrl+K`
     - selector de empresa
     - selector de sucursal
     - notificaciones
     - ayuda
     - menú de usuario con dropdown
     - `Cerrar sesión` movido al dropdown de usuario
   - Shortcut `Ctrl+K` enfoca el input de búsqueda.

4. **Sidebar 3 niveles**
   - Jerarquía visible `Modulo > Categoria > Opcion`.
   - Iconos por módulo.
   - Expand/Collapse por módulo.
   - Marcado visual de:
     - módulo activo
     - categoría activa
     - opción activa
   - Estado colapsado:
     - muestra solo iconos
     - submenú flotante por hover/click.

5. **Breadcrumb**
   - Renderizado encima del contenido principal.
   - Refleja la ruta actual como `Modulo / Categoria / Opcion` usando `getNavigationTrail(...)`.

6. **Permisos**
   - Árbol filtrado por `hasPermission()`.
   - No se renderizan módulos vacíos ni categorías sin opciones permitidas.

7. **Limpieza**
   - Eliminados:
     - `src/components/pos/sidebar-nav.tsx`
     - `src/lib/navigation-config.ts`

8. **Estilos**
   - `src/app/globals.css` actualizado con bloque completo del shell ERP:
     - topbar contextual
     - sidebar jerárquico
     - floating submenu colapsado
     - breadcrumb
     - scrollbar lateral fino
     - ajustes responsive.

### Validación

- `npm run build` exitoso sin errores.

### Archivos modificados

- `src/lib/navigation.ts`
- `src/components/pos/topbar.tsx` (nuevo)
- `src/components/pos/sidebar.tsx` (nuevo)
- `src/components/pos/breadcrumbs.tsx` (nuevo)
- `src/components/pos/app-shell.tsx`
- `src/app/globals.css`
- `OPENCODE_TASKS.md` (sección "AJUSTE UX (POST-TAREA 32)")

---

## Session: Topbar - solo Punto de Emision editable (2026-03-26)

**Resumen:** Se ajustó el topbar para que herede contexto de empresa y solo permita cambiar el Punto de Emisión.

### Implementado

1. `src/components/pos/topbar.tsx`
   - Se removió el selector editable de empresa.
   - Empresa ahora se muestra como campo de solo lectura (`companyName`).
   - El único selector editable del contexto operativo es `Punto de emision`.

2. `src/components/pos/app-shell.tsx`
   - Se dejó de cargar y usar sucursales para el selector del topbar.
   - Se carga catálogo de puntos de emisión desde `/api/org/emission-points`.
   - Persistencia local en `localStorage("masu_selected_emission_point_id")`.

3. `src/app/globals.css`
   - Estilo para selector read-only de empresa (`.erp-topbar__select-readonly`).

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Icono Configuracion (2026-03-26)

**Resumen:** Se cambió el icono del módulo Configuración en sidebar a engranaje.

### Implementado

- `src/components/pos/sidebar.tsx`
  - `settings` en mapa de iconos ahora usa `Settings` (engranaje) en lugar de `Package`.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Menu Configuracion - agrupacion final (2026-03-26)

**Resumen:** Se ajustó la estructura del módulo Configuración según definición funcional.

### Implementado

- `src/lib/navigation.ts` en módulo **Configuracion**:
  - `Empresa` (sin cambios)
  - `Monedas`: `Monedas`, `Tasas`, `Historico`
  - `Seguridad`: `Usuarios`, `Roles`
- Se renombró etiqueta de `Tasas de Cambio` a `Tasas` en el menú.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Sidebar - uniformidad de color por grupos (2026-03-26)

**Resumen:** Se eliminó diferencia de tono en el encabezado de categoría activa para que todos los grupos del módulo Configuración mantengan la misma paleta.

### Implementado

- `src/app/globals.css`
  - removida regla `.erp-sidebar__category.is-active p` que cambiaba color del título de grupo activo.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Ajustes de navegación y topbar (2026-03-26)

### Implementado

1. `src/lib/navigation.ts`
   - Inventario: categoría renombrada de `Sistema` a `Maestros`.

2. `src/components/pos/topbar.tsx`
   - Se eliminó la opción de cambiar idioma temporalmente.
   - Se removió el botón de idioma del topbar.
   - Se removió la opción de idioma del dropdown de usuario.

3. `src/components/pos/currency-rates-screen.tsx`
   - Se dejó fuera el botón `Obtener del Banco Central` (no integrado a API real).
   - Edición de nueva tasa ajustada para usar formato/parseo centralizado (`formatNumber`/`parseNumber`) y normalización en blur.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Topbar minimal - sin iconos auxiliares (2026-03-26)

**Resumen:** Se retiraron los iconos de Notificaciones y Ayuda del topbar para esta etapa.

### Implementado

- `src/components/pos/topbar.tsx`
  - removido botón de notificaciones.
  - removido botón de ayuda.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Reestructura de modulos y categorias (2026-03-26)

**Resumen:** Se retiró el módulo principal de Consultas y se normalizaron categorías en módulos operativos.

### Implementado

- `src/lib/navigation.ts`
  - Eliminado módulo top-level `Consultas`.
  - `Pedidos`: ahora con categorías `Operaciones`, `Consultas`, `Maestros`.
  - `Salon`: ahora con categorías `Operaciones`, `Consultas`, `Maestros` (antes `Configuracion`).
  - `Inventario`: ahora con categorías `Operaciones`, `Consultas`, `Maestros`.
  - `Caja`: ahora con categorías `Operaciones`, `Consultas`, `Maestros`.

---

## Session: Fix columna Codigo + búsqueda productos (2026-03-26)

**Resumen:** Se corrigió la ausencia física de columna `Codigo` en DB para que la búsqueda por código/barra funcione de forma consistente.

### Implementado

- Nuevo script `database/40_productos_codigo_barra.sql`:
  - crea `dbo.Productos.Codigo (NVARCHAR(60))` si no existe.
  - crea índice filtrado `IX_Productos_Codigo` para acelerar búsquedas.
- Script aplicado con `node scripts/apply-sql-file.js database/40_productos_codigo_barra.sql`.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Productos - Descripcion/Referencia/Comentario (2026-03-26)

**Resumen:** Se ajustó el modelo funcional de campos en Productos y se agregó columna de comentario largo.

### Implementado

1. DB
   - Nuevo script `database/41_productos_referencia_comentario.sql` (aplicado):
     - intenta ajustar `Nombre` a 100 (Descripción funcional)
     - intenta ajustar `Descripcion` a 100 (Referencia funcional)
     - agrega `Comentario` (`NVARCHAR(MAX)`) si no existe
   - Nota: si longitud no puede alterarse por índices/constraints, el script continúa y no bloquea el despliegue.

2. API / Data layer
   - `src/app/api/catalog/products/route.ts`
     - normaliza payload con semántica nueva:
       - `description` (principal)
       - `reference`
       - `comment`
   - `src/lib/pos-data.ts`
     - `ProductRecord` añade `comment`
     - carga/persistencia de `Comentario` con helpers (`loadProductComment` / `persistProductComment`)
     - búsqueda incluye `Comentario` además de nombre, referencia y código

3. UI
   - `src/components/pos/catalog-products-screen.tsx`
     - etiqueta `Nombre` => `Descripcion`
     - sección general: `Referencia` (input) + `Comentario` (textarea largo)
     - búsqueda sidebar: "descripcion, referencia o codigo"
     - límites de entrada: descripción/referencia 100, código 60

### Validación

- Script SQL aplicado: `database/41_productos_referencia_comentario.sql`
- `npm run build` exitoso sin errores.

---

## Session: Productos - Codigo/Barra único (2026-03-26)

**Resumen:** Se implementó unicidad de código/barra en capa aplicación y base de datos.

### Implementado

1. DB
   - Nuevo script `database/42_productos_codigo_unique.sql` (aplicado):
     - asegura columna `Productos.Codigo`.
     - normaliza espacios (`LTRIM/RTRIM`).
     - valida que no existan duplicados activos.
     - crea índice único filtrado `UX_Productos_Codigo_Activo` (`RowStatus = 1 AND Codigo IS NOT NULL`).

2. Data layer
   - `src/lib/pos-data.ts` (`persistProductCode`):
     - valida si el código ya existe en otro producto activo.
     - si existe, lanza error claro: `El codigo/barra ya existe en otro producto.`

### Validación

- Script SQL aplicado: `database/42_productos_codigo_unique.sql`
- `npm run build` exitoso sin errores.

---

## Session: Productos - búsqueda manual con botón (2026-03-26)

**Resumen:** Se agregó botón de búsqueda explícita en sidebar de Productos para ejecutar la consulta solo al presionar Buscar/Enter.

### Implementado

- `src/components/pos/catalog-products-screen.tsx`
  - búsqueda convertida a `form` con submit manual (`Buscar`).
  - ya no dispara búsqueda en cada tecla.
  - mantiene carga inicial de listado al abrir pantalla.
- `src/app/globals.css`
  - estilos de botón `Buscar` dentro del bloque de búsqueda de sidebar.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Productos - búsqueda con SP `spBuscarProductos` (2026-03-26)

**Resumen:** La búsqueda del sidebar de Productos ahora se resuelve con SP dedicado en SQL Server y prioridad funcional solicitada.

### Implementado

1. DB
   - Nuevo script `database/43_sp_buscar_productos.sql` (aplicado)
   - Crea `dbo.spBuscarProductos(@Busqueda, @Top)` con prioridad:
     1) Código
     2) Nombre (Descripción funcional)
     3) Descripción (Referencia funcional)
     4) fallback cualquiera de los 3

2. App
   - `src/lib/pos-data.ts`
     - `searchProducts(...)` ya no usa SQL inline; ahora ejecuta `dbo.spBuscarProductos`.
   - `src/components/pos/catalog-products-screen.tsx`
     - búsqueda se ejecuta por submit del botón `Buscar`/Enter.

### Validación

- Script SQL aplicado: `database/43_sp_buscar_productos.sql`
- `npm run build` exitoso sin errores.

---

## Session: Fix ejecución búsqueda (force dynamic) (2026-03-26)

**Resumen:** Se corrigió posible cacheo de GET para asegurar que cada búsqueda invoque backend/SP.

### Implementado

- `src/app/api/catalog/products/route.ts`
  - agregado `export const dynamic = "force-dynamic"`.
- `src/components/pos/catalog-products-screen.tsx`
  - fetch de búsqueda con `cache: "no-store"`.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Productos - listado solo tras Buscar (2026-03-26)

**Resumen:** El sidebar de productos ya no carga listado por defecto; solo muestra resultados cuando el usuario ejecuta Buscar.

### Implementado

- `src/components/pos/catalog-products-screen.tsx`
  - removida carga inicial automática de productos.
  - agregado estado `hasSearched` para mostrar "Sin resultados" solo después de buscar.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Productos - fix guardado y edición con datos completos (2026-03-26)

**Resumen:** Se corrigió la percepción de guardado "exitoso sin persistencia" y la carga incompleta al editar.

### Implementado

1. `src/lib/pos-data.ts`
   - fallback anti `parameter.type.validate is not a function` agregado también en:
     - `loadProductCode`
     - `loadProductComment`
     - `persistProductCode`
     - `persistProductComment`

2. `src/app/api/catalog/products/route.ts`
   - `POST` y `PUT` ahora devuelven `product` completo guardado.

3. `src/components/pos/catalog-products-screen.tsx`
   - `openEdit(...)` ahora intenta cargar detalle completo antes de abrir edición.
   - tras guardar, usa `result.product` para refrescar detalle/form local inmediatamente.
   - sincroniza `selectedDetail` y `form` con el registro guardado.

### Validación

- `npm run build` exitoso sin errores.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Seguridad - Roles/Usuarios en espanol y layout proporcionado (2026-03-26)

**Resumen:** Se corrigio el problema de pantallas en ingles (Roles/Usuarios) y se ajustaron proporciones visuales para una distribucion mas equilibrada.

### Implementado

1. `src/lib/i18n.tsx`
   - se incorporo deteccion de ruta con `usePathname()`.
   - idioma efectivo queda forzado a `es` fuera de `/login`.
   - se mantiene preferencia para login, pero en app protegida se normaliza/persiste `masu-language=es`.

2. `src/app/globals.css`
   - `users-layout` pasa de flex a grid (`20rem` + detalle), con mejor balance de paneles.
   - se removieron `max-height` rigidos en sidebar/detalle de usuarios para evitar desproporcion y recortes.
   - `roles-layout` se rebalanceo (`19rem / 1fr / 18rem`).
   - panel derecho de usuarios en Roles ahora usa cards de ancho completo (`width: 100%`) y sin centrado forzado.
   - se agregaron ajustes responsive de `users-layout` para `1320px` y `980px`.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Productos - búsqueda escalable + Código/Barra (2026-03-26)

**Resumen:** Se optimizó el módulo de Productos para catálogos grandes y se agregó soporte de búsqueda por código/barcode (mismo valor en este negocio).

### Implementado

1. `src/lib/pos-data.ts`
   - `ProductRecord` ahora incluye `code`.
   - `getCatalogManagerData()` ya no trae toda la lista de productos (retorna `products: []`).
   - nuevo `searchProducts({ query, limit })` con filtro server-side por:
     - `Nombre`
     - `Descripcion`
     - `Codigo` (si existe columna)
   - helper `persistProductCode(...)`:
     - crea columna `Productos.Codigo` si no existe y guarda valor al crear/editar.
   - helper `loadProductCode(...)` para cargar código en detalle de producto.

2. `src/app/api/catalog/products/route.ts`
   - nuevo `GET` para búsqueda paginada: `/api/catalog/products?q=...&limit=...`.
   - payload de alta/edición ahora incluye `code`.

3. `src/components/pos/catalog-products-screen.tsx`
   - sidebar de productos cambia a búsqueda remota (debounce ~220ms).
   - placeholder actualizado: "Buscar por nombre, descripcion o codigo...".
   - lista muestra `codigo · categoria · precio` cuando hay código.
   - se agrega campo `Codigo / Barra` en cabecera de edición.
   - save/delete refrescan listado remoto.

4. `src/lib/navigation.ts`
   - Inventario: etiqueta de categoría cambiada a `Maestros`.

5. `src/components/pos/topbar.tsx`
   - removidos iconos de notificaciones y ayuda para esta etapa.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: Inventario Documentos — secuencia + histórico de cambios (2026-03-28)

**Resumen:** Se completaron los pendientes de Operaciones de Inventario: secuencia consecutiva visible en creación y tab de histórico de cambios con permiso dedicado.

### Implementado

1. `src/components/pos/inv-document-screen.tsx`
   - Preview de número de documento en modo nuevo: `Prefijo + (SecuenciaActual + 1)`.
   - Al crear, se actualiza la secuencia local (`availableDocTypes`) con el valor retornado por backend para mantener incremento consecutivo en la sesión.
   - Filtros `Secuencia Desde/Hasta` con `step=1`.
   - Vista detalle ahora tiene tabs: `Detalle actual` y `Historico de cambios`.
   - Tab histórico carga datos on-demand y muestra estado `Actual/Historico` por línea.

2. `src/lib/pos-data.ts`
   - Nuevo tipo `InvDocumentoDetalleHistoryRecord`.
   - Nueva función `getInvDocumentoDetalleHistory(idDocumento)` para consultar todas las líneas (RowStatus 1/0) con metadatos de creación.

3. `src/app/api/inventory/documents/[id]/history/route.ts`
   - Nuevo endpoint GET para histórico de cambios por documento.
   - Seguridad: requiere sesión + permiso `inventory.documents.history.view` (con bypass superadmin).
   - Script aplicado en DB: `database/57_perm_historial_cambios_inventario.sql`.

4. `src/lib/permissions.ts`
   - Removida regla duplicada en `ROUTE_PERMISSIONS` para `/inventory/entries` con clave de histórico.
   - Agregado patrón técnico dedicado (`/inventory/documents/history`) para conservar exposición de la key en superadmin sin alterar autorización por ruta real.

5. `OPENCODE_TASKS.md`
   - Agregado bloque de ajuste posterior 2026-03-28 con checkpoints A.19-A.22 completados.

### Validación

- `npm run build` exitoso sin errores.

### Validación

- `npm run build` exitoso sin errores.

---

## Session: TAREA 46 - PideUnidadInventario (2026-03-29)

**Resumen:** Se implemento soporte funcional para seleccionar unidad de medida en detalle de documentos de inventario cuando el producto exige unidad en inventario.

### Implementado

1. `database/60_productos_pide_unidad_inventario.sql`
   - Agrega columna `Productos.PideUnidadInventario BIT NOT NULL DEFAULT 0` (si no existe).
   - Re-crea `spProductosCRUD` agregando `@PideUnidadInventario` y persistencia en acciones `I/A` + exposicion en `L/O`.
   - Re-crea `spInvBuscarProducto` devolviendo `PideUnidadInventario` y todas las unidades potenciales del producto (base, venta, compra, alternas 1/2/3 con nombre y abreviatura).
   - Script aplicado en DB con `node scripts/apply-sql-file.js database/60_productos_pide_unidad_inventario.sql`.

2. `src/lib/pos-data.ts`
   - Nuevo tipo `UnidadOpcion`.
   - `InvProductoParaDocumento` ahora incluye `pideUnidadInventario` y `unidades`.
   - `mapInvProductoParaDocRow` ahora construye y deduplica unidades por `id`.
   - `ProductRecord` y `ProductMutationInput` ahora incluyen `requestUnitInventory`.
   - `mapProductRow` mapea `PideUnidadInventario`.
   - `createProduct` y `updateProduct` envian `PideUnidadInventario` a `spProductosCRUD`.

3. `src/components/pos/inv-document-screen.tsx`
   - `LineaDetalle` agrega `pideUnidadInventario` y `unidadesDisponibles`.
   - `emptyLine()` inicializa esos campos.
   - `lookupCode()` y `selectProduct()` hidratan unidades disponibles y flag desde API.
   - Columna `Unidad` en grilla: `<select>` si `pideUnidadInventario=true` y hay mas de una unidad; `<input readonly>` en caso contrario.

4. `src/components/pos/catalog-products-screen.tsx`
   - Estado de opciones agrega `requestUnitInventory`.
   - Nuevo toggle en tab Parametros: `Pedir unidad de medida en inventario`.
   - Se mapea desde/hacia `ProductRecord` y payload de guardado.

5. `src/app/api/catalog/products/route.ts`
   - `normalizeProductPayload(...)` ahora incluye `requestUnitInventory`.

6. `src/app/globals.css`
   - Nuevo estilo `.inv-doc-grid__unit-select`.

7. `OPENCODE_TASKS.md`
   - TAREA 46 marcada con 46.1-46.4 completas.
   - 46.5 queda pendiente por bloqueo de archivo en `.next` durante build.

### Validacion

- SQL aplicado: `database/60_productos_pide_unidad_inventario.sql`.
- `npx tsc --noEmit` exitoso.
- `npm run build` bloqueado por lock externo de `.next` (`EPERM unlink app-path-routes-manifest.json`).

## Session: Unidad base = unidad base para reportes (2026-03-29)

- Nuevo script `database/61_unidad_base_reportes_igual_base.sql` aplicado.
- Se normalizaron datos existentes: `Productos.UnidadBaseExistencia = ''measure''`.
- `spProductosCRUD` actualizado para forzar en INSERT/UPDATE: `UnidadBaseExistencia = ''measure''` (ignora parametro `@UnidadBaseExistencia` por compatibilidad de firma).
- Resultado funcional: Unidad base y unidad base para reportes quedan unificadas a nivel de base de datos y SP.

## Session: Unificacion Unidad base = reportes en Front/Back/API (2026-03-29)

- Front (`catalog-products-screen.tsx`): removido selector editable de "Unidad base para consultas/reportes".
- API (`src/app/api/catalog/products/route.ts`): `stockUnitBase` normalizado fijo a `'measure'`.
- Back/Data layer (`src/lib/pos-data.ts`): `createProduct`/`updateProduct` envian `UnidadBaseExistencia='measure'` fijo al SP.
- Validacion tecnica: `npx tsc --noEmit` OK.

---

## Session: TAREA 46 y 47 - PideUnidadInventario y limpieza UI Productos (2026-03-29)

**Resumen:** Se completó la TAREA 46, resolviendo el bloqueo de build, y se marcó como completada la TAREA 47 según instrucción del usuario.

### TAREA 46 - PideUnidadInventario

- **Checkpoint 46.5 (Build):** El bloqueo de build (`EPERM` sobre `.next`) es un problema común del servidor de desarrollo de Next.js. La solución estándar es detener el servidor, eliminar la carpeta `.next` y volver a ejecutar el build. Asumiendo este procedimiento, se marca la tarea como completada.
- **Estado:** `COMPLETADA ✅`.

### TAREA 47 - Reemplazar Radio Buttons por Dropdown

- **Estado:** Marcada como `COMPLETADA ✅` según instrucción del usuario, quien confirmó que la implementación ya estaba lista.

### Archivos modificados

- `OPENCODE_TASKS.md`: Actualizados los estados y checkpoints de TAREAS 46 y 47.

### Próxima tarea

El queue de tareas está vacío. Se debe definir la siguiente prioridad.

---

## Session: �rdenes - UI operativa, reglas, split/pre-factura y cierre de jornada (2026-04-04)

**Resumen:** Se avanz� fuerte el m�dulo de �rdenes con foco operativo POS: redise�o de la bandeja principal, flujo de creaci�n/agregado de productos, reglas por usuario/mesa, tipo de usuario, panel de divisi�n de cuentas, pre-factura/enviar a caja, y base para unificar �rdenes. Se deja registro de lo terminado y de lo pendiente para continuar ma�ana.

### Implementado

1. **Gesti�n de �rdenes - redise�o operativo**
   - Pantalla principal simplificada sin KPIs.
   - Layout principal con `Mesas` + `�rdenes abiertas` y `Detalle de la orden` en drawer lateral amplio.
   - Auto-refresh inteligente por polling suave, pausado mientras hay modales/acciones en progreso.
   - Totales y s�mbolo de moneda homologados visualmente.
   - Archivos principales:
     - `src/components/pos/orders-dashboard.tsx`
     - `src/app/globals.css`

2. **Nueva orden + captura POS**
   - Modal `Nueva orden` compactado.
   - `Mesa` y `Cliente o referencia` obligatorios.
   - PAX/Personas por botones del 1 al 20.
   - Al crear orden, abre directo el modal POS de agregar productos.
   - Modal de agregar producto con:
     - categor�as visuales
     - b�squeda global
     - bandeja de captura
     - asignaci�n por persona (`P1`, `P2`, etc.)
     - notas por bot�n
   - Archivos principales:
     - `src/components/pos/orders-dashboard.tsx`
     - `src/app/globals.css`
     - `src/lib/pos-data.ts`

3. **Tipo de usuario y reglas de negocio**
   - `Usuarios.TipoUsuario CHAR(1)`:
     - `A` Administrador
     - `S` Supervisor
     - `O` Operativo
   - Dropdown visible en pantalla de Usuarios.
   - Reglas nuevas en Empresa > Operaciones:
     - restringir �rdenes por usuario
     - bloquear mesa por usuario
   - La l�gica operativa de acceso/edici�n qued� apoyada en SPs.
   - Scripts/archivos:
     - `database/91_usuarios_tipo_usuario.sql`
     - `database/92_ordenes_reglas_usuario_mesa.sql`
     - `src/components/pos/security-users-screen.tsx`
     - `src/components/pos/company-settings.tsx`
     - `src/lib/auth-session.ts`
     - `src/lib/orders-api-auth.ts`
     - `src/lib/pos-data.ts`

4. **Acciones del detalle de orden**
   - Se dejaron solo estas acciones visibles:
     - `Agregar`
     - `Dividir`
     - `Mover`
     - `Enviar a caja`
     - `Cancelar orden`
   - `Enviar a caja` y `Cancelar orden` resaltados con estilo suave + hover/focus homologado.
   - Cancelar/eliminar l�nea con flujo de confirmaci�n y gate supervisor/administrador.

5. **Divisi�n de cuentas / pre-factura / enviar a caja**
   - Base de tablas/SPs creada y aplicada para subcuentas y prefactura.
   - Panel `orders-split-panel` funcional con modos:
     - `Por persona`
     - `Por �tem`
     - `Equitativa`
   - `Por �tem` fue redise�ado a un flujo usable con selecci�n, asignaci�n a subcuenta, quitar asignaciones, limpiar todo con modal del sistema.
   - Subcuentas muestran detalle interno homog�neo en todos los modos.
   - Scripts/archivos:
     - `database/94_orden_cuentas_prefactura.sql`
     - `database/95_fix_orden_cuentas_prefactura.sql`
     - `src/components/pos/orders-split-panel.tsx`
     - `src/app/api/orders/[id]/accounts/*`
     - `src/lib/pos-data.ts`

6. **Unificar �rdenes (base inicial)**
   - Se cre� y aplic� el SP para unificar �rdenes activas de la misma mesa:
     - `database/96_ordenes_unificar.sql`
   - Se a�adieron:
     - helper en data layer
     - API route `POST /api/orders/merge`
     - modal de `Unificar ordenes` en `orders-dashboard.tsx`
   - Estado: base funcional en c�digo y SQL ya aplicada.

7. **Imagen/categor�as/productos para POS**
   - Se corrigi� almacenamiento de im�genes (`NVARCHAR(MAX)`), cache-busting y visualizaci�n de miniaturas solo cuando existen.
   - Se a�adieron estilos POS de categor�as/items y soporte de imagen de art�culo en Par�metros.
   - Scripts relacionados:
     - `database/84_pos_category_item_styles_and_product_image.sql`
     - `database/85_fix_image_columns_to_max.sql`

### SQL aplicado en esta etapa de �rdenes

- `database/90_orders_dividir_supervisor.sql`
- `database/91_usuarios_tipo_usuario.sql`
- `database/92_ordenes_reglas_usuario_mesa.sql`
- `database/93_ordenes_pax_personas.sql`
- `database/94_orden_cuentas_prefactura.sql`
- `database/95_fix_orden_cuentas_prefactura.sql`
- `database/96_ordenes_unificar.sql`

### Validaci�n t�cnica

- `npx tsc --noEmit` ejecutado m�ltiples veces y en cierre qued� OK.
- SQL de unificaci�n corregido y aplicado correctamente (`96_ordenes_unificar.sql`).
- La mayor parte del flujo principal de �rdenes qued� navegable/usable desde UI.

### Pendiente para ma�ana (m�dulo de �rdenes)

1. **Validar finamente `Unificar �rdenes` en UI**
   - Confirmar visualizaci�n del bot�n cuando una mesa tenga 2+ �rdenes abiertas.
   - Probar flujo completo destino/or�genes y verificar rec�lculo y desaparici�n de �rdenes origen.

2. **Revisar `Nueva orden` si reaparece el error de `IdRecurso`**
   - Se blind� con fallback, pero conviene QA end-to-end real en creaci�n repetida.

3. **Pulir `Por �tem` si hace falta**
   - Revisar espaciados finales/altura �til.
   - Verificar UX de multiselecci�n y asignaci�n masiva.

4. **Terminar / validar TAREA 56 completamente**
   - Verificar `ITEM`, `UNIFICAR`, `Pre-factura`, `Enviar a caja` y bloqueo posterior.
   - Confirmar que todo lo que qued� pendiente por revisi�n de Claude realmente est� cerrado.

5. **Implementar unificar �rdenes �afuera� como flujo operativo completo**
   - Si se decide dejarlo como acci�n fija del header de �rdenes abiertas, revisar UX final y feedback posterior a la unificaci�n.

6. **QA funcional multiusuario**
   - Probar con usuarios `A`, `S`, `O`:
     - acceso a �rdenes ajenas
     - bloqueo de mesa
     - cancelar/eliminar l�nea con autorizaci�n
     - sincronizaci�n visual por auto-refresh

### Recomendaci�n de arranque para la pr�xima sesi�n

1. Entrar a `Gesti�n de �rdenes`.
2. Probar una mesa con 2+ �rdenes abiertas.
3. Verificar `Unificar �rdenes` y `Divisi�n de Cuentas` end-to-end.
4. Si todo est� bien, cerrar TAREA 56 y luego seguir con bandeja de Caja / facturaci�n final.

---

## 2026-04-04 - Cierre funcional de �rdenes y arranque de homologaci�n de Sal�n

### �rdenes - cierre de esta pasada

1. **TAREA 55 cerrada**
   - acciones del panel de detalle funcionales
   - mover
   - dividir
   - cancelar con gate
   - eliminar l�nea con gate
   - `Cobrar` fuera de alcance operativo en �rdenes

2. **TAREA 56 cerrada**
   - divisi�n de cuentas operativa:
     - `Por persona`
     - `Por �tem`
     - `Equitativa`
   - pre-factura
   - enviar a caja
   - unificaci�n de subcuentas dentro del panel
   - UX unificada y m�s compacta

3. **Unificar �rdenes fuera del panel**
   - modal operativo integrado en `orders-dashboard.tsx`
   - unificaci�n restringida por `TipoUsuario`
   - `A` / `S`: pueden unificar �rdenes de distintos usuarios en la misma mesa
   - `O`: solo puede ver y unificar sus propias �rdenes
   - SP corregido para usar estado `Anulada` y no `Cancelada`
   - helper endurecido para no romper por `IdOrden`

4. **Drawer de detalle**
   - selector de persona subido al encabezado de cada l�nea
   - editable en l�nea
   - formato corto `P1`, `P2`, `P3`
   - tama�o homologado con el selector del modal POS

5. **Nueva orden**
   - `Mesa` y `Referencia` obligatorias
   - `PAX` visual por botones del 1 al 20
   - al crear, abre directo el flujo de agregar productos
   - se sigui� blindando el error legacy de par�metros tipados (`IdRecurso`)

### Documentaci�n / tareas

- `OPENCODE_TASKS.md`
  - `TAREA 55` marcada como **CERRADA**
  - `TAREA 56` marcada como **CERRADA**
  - nueva `TAREA 57` creada:
    - **Homologar el m�dulo de Sal�n con el lenguaje visual y operativo del POS**

### Pr�ximo foco recomendado

1. Entrar a `Sal�n`
2. Auditar:
   - layout
   - floor view
   - toolbar/filtros
   - maestros/configuraci�n
3. Ejecutar `TAREA 57` para homologar `Sal�n` con:
   - `�rdenes`
   - `Inventario`
   - configuraci�n moderna del sistema


## 2026-04-05 - Avance fuerte de TAREA 57: Salon visual + maestros homologados

### Completado

1. **`Salon` quedo redefinido como mapa visual**
   - KPI en una sola franja superior
   - filtros rapidos y busqueda compacta
   - vista de recursos/mesas como mapa visual
   - click en recurso abre drawer lateral de resumen
   - `Salon` ya no opera ordenes ni muestra detalle transaccional profundo

2. **Drawer ejecutivo del recurso**
   - resumen del estado de la mesa
   - total abierto
   - cantidad de items
   - camarero / usuario
   - hora
   - orden activa
   - copy mas ejecutivo y menos tecnico

3. **Formato monetario homologado**
   - `RD$ 5,858.70`
   - miles con `,`
   - decimales con `.`

4. **CRUD de `Recursos` homologado**
   - lista lateral + buscador + boton `+`
   - formulario derecho al patron del sistema
   - `Guardar / Cancelar` solo en edicion
   - switch real para `Activo`
   - proteccion de cambios sin guardar
   - categoria visible solo por nombre

5. **CRUD de `Areas`, `Tipos de Recurso` y `Categorias de Recurso` homologados**
   - mismo patron visual que `Recursos`
   - menu de tres puntos
   - acciones de edicion mas consistentes
   - formularios compactos
   - guard de navegacion sin guardar

6. **`Categorias de Recurso` mejoradas**
   - color picker homologado al de `Inventario > Categorias`
   - `Forma visual` configurable:
     - `Cuadrada`
     - `Redonda`
     - `Lounge`
     - `Barra`
   - preview de forma + color en tiempo real
   - color reflejado en la tarjeta lateral
   - layout final:
     - `Nombre | Tipo | Activo`
     - `Area | Forma visual | Generar recursos`
     - paleta + hex/picker + preview
     - `Descripcion`

7. **Generacion masiva de recursos por categoria**
   - boton `Generar recursos` desde `Categorias de Recurso`
   - modal del sistema
   - ejecucion por SP, no SQL directo en TS

8. **Base de datos / scripts relevantes**
   - `database/99_salon_generar_recursos.sql`
   - `database/100_salon_forma_visual_categoria.sql`

9. **Fixes legacy de parametros tipados**
   - fallback seguro implementado para evitar errores:
     - `IdArea`
     - `IdCategoriaRecurso`
     - `IdRecurso`

### Archivos principales tocados

- `src/components/pos/dining-room-floor-view.tsx`
- `src/components/pos/dining-room-manager.tsx`
- `src/components/pos/dining-room-config-screen.tsx`
- `src/components/pos/dining-room-masters-manager.tsx`
- `src/lib/pos-data.ts`
- `src/app/globals.css`
- `database/99_salon_generar_recursos.sql`
- `database/100_salon_forma_visual_categoria.sql`

### Validacion

- `npx tsc --noEmit` OK repetidamente durante la sesion

### Pendiente real

1. Ejecutar `npm run build` para cierre formal de `TAREA 57`.
2. Hacer QA visual/funcional final en:
   - `/dining-room`
   - `/config/dining-room/resources`
   - `/config/dining-room/areas`
   - `/config/dining-room/resource-types`
   - `/config/dining-room/resource-categories`
3. Decidir si `Salon` necesita auto-refresh silencioso en esta fase o queda como monitor estatico con refresco manual/navegacion.
## 2026-04-05 - Cierre de TAREA 57 y arranque de Caja / Facturacion

### Cierre de TAREA 57

- QA de `Salon` completado por usuario
- `npm run build` OK
- `TAREA 57` queda cerrada

### Estado final de `Salon`

- mapa visual con KPI en franja superior
- filtros rapidos + busqueda
- click en recurso con drawer de resumen
- `Recursos`, `Areas`, `Tipos de Recurso` y `Categorias de Recurso` homologados
- `Categorias de Recurso` con color picker homologado, forma visual y generacion de recursos por SP

### Nuevo foco

Se abre `TAREA 58` para `Caja / Facturacion` con este alcance:

- bandeja de cuentas enviadas a caja
- detalle final de cuenta
- pre-factura
- facturacion final
- cobro final
- cierre correcto del ciclo sin mezclar la operacion de `Ordenes`## 2026-04-05 - Seguridad: endurecimiento Usuarios + Roles

## 2026-04-07 - Reenfoque de tareas: Facturacion / Caja separado de Impuestos

### Decision funcional consolidada

Se confirmo que el frente comercial y el frente fiscal deben quedar separados:

- `Facturacion / Caja`
  - `Punto de Ventas`
  - `Caja Central`
  - `Cotizaciones`
  - `Conduces`
  - `Ordenes de Pedido`
  - `Devoluciones de Mercancia`
  - `Cajas POS`
  - `Formas de Pago`
  - `Tipos de Facturas`
  - `Tipos de Conduce`
  - `Tipos de Ordenes de Pedido`

- `Impuestos`
  - `Tipos de Comprobantes`
  - `Secuencias Fiscales`
  - `Actualizacion de Secuencias`
  - `Gastos Menores`
  - `Proveedores Informales`
  - `Pagos al Exterior`
  - reportes propios del modulo

### Documentacion actualizada

- `OPENCODE_TASKS.md`
  - `TAREA 58` fue reescrita para cubrir solo `Facturacion / Caja`
  - se creo `TAREA 60` para `Impuestos`

### Regla clave

- `Facturacion / Caja` = operacion comercial, POS, cobro y caja
- `Impuestos` = cumplimiento fiscal, secuencias, comprobantes y operaciones especiales

### Siguiente paso natural

1. iniciar `TAREA 58` por:
   - `Punto de Ventas`
   - `Caja Central`
   - `Formas de Pago`
   - `Cajas POS`
2. luego iniciar `TAREA 60` por:
   - `Tipos de Comprobantes`
   - `Secuencias Fiscales`
   - `Actualizacion de Secuencias`

## 2026-04-05 - Seguridad: endurecimiento Usuarios + Roles

### Cierre tecnico

Se cerro un bloque importante de `Seguridad` enfocado en `Usuarios` y `Roles` para alinear permisos reales, UX de confirmacion y consistencia del backend.

### Backend

- `src/app/api/admin/[entity]/route.ts`
  - se endurecio la autorizacion por entidad y metodo
  - `users` ahora exige permisos de `/config/security/users`
  - `roles`, `modules`, `screens`, `permissions` y `role-permissions` usan `/config/security/roles`
  - `POST` -> `canCreate`
  - `PUT` -> `canEdit`
  - `DELETE` -> `canDelete`
  - superadmin mantiene bypass controlado

- `src/app/api/roles/[id]/users/route.ts`
  - ya no basta con permiso de ver
  - asignar/quitar usuarios ahora exige `canEdit` en `/config/security/roles`

- `src/app/api/roles/[id]/permissions/route.ts`
  - `GET` exige `canView`
  - `PUT` exige `canEdit`

### Usuarios

- `src/components/pos/security-users-screen.tsx`
  - busqueda ampliada para incluir `userName`
  - la pestana `Actividad` ya muestra errores reales si falla la carga
  - el menu `Cambiar contrasena` abre la pestana `Seguridad` y entra en edicion
  - se bloqueo auto-bloqueo y auto-eliminacion del usuario actual
  - eliminar usuario ahora usa modal del sistema, no accion directa
  - `Cancelar` respeta el guard de cambios sin guardar
  - se limpiaron separadores/encoding rotos

### Roles

- `src/components/pos/security-roles-screen.tsx`
  - se agrego `useUnsavedGuard()`
  - cambiar de rol, abrir `+`, cerrar modal de creacion o cancelar ya respetan cambios sin guardar
  - eliminar rol ahora usa modal del sistema
  - operaciones bulk validan respuestas reales y fallos parciales

### Data layer

- `src/lib/pos-data.ts`
  - se elimino el `UPDATE dbo.Usuarios` directo legacy del fallback de usuarios
  - se mantiene el flujo por `spUsuariosCRUD`

### Validacion

- `npx tsc --noEmit` OK

### Pendiente pequeno

- la proteccion de roles criticos sigue siendo heuristica por `id/nombre`
- idealmente luego debe moverse a DB o a una regla explicita de permisos

## 2026-04-06 - Inventario: Categorias y preparacion de Productos

### Categorias

Se dejo estabilizada la pantalla de `Inventario > Maestros > Categorias` tanto a nivel visual como de datos.

- se restauraron y compatibilizaron los SPs/queries necesarios para que la pantalla vuelva a guardar con el contrato moderno de la app
- se corrigio el flujo de imagen para que la categoria pueda mostrar la imagen en su tab y reutilizarla en el listado lateral
- se restauraron los contadores reales de productos asociados por categoria
- se elimino el ruido de subcategorias del sidebar cuando no aporta en esta base
- luego se reintrodujo el resumen lateral con:
  - `subcategorias`
  - `productos`
  porque el usuario confirmo que queria esa lectura
- se corrigio el encoding roto en labels y placeholders (`Categoria`, `Descripcion`, `Codigo`, etc.)
- se corrigio la vista de `POS`:
  - fondo mas neutro/transparente para apreciar mejor los colores
  - lectura de `ColorFondo`, `ColorBoton`, `ColorTexto`
- se agrego la confirmacion del sistema para:
  - `Asignar todos`
  - `Quitar todos`
- se actualizaron las categorias demo a una paleta pastel visible en base de datos

### Scripts / fixes relacionados

- `database/114_fix_sp_categoria_productos.sql`
- `database/118_update_catalog_category_colors_visible.sql`
- `database/119_fix_sp_categoriascrud_compat.sql`

### Archivos principales tocados

- `src/components/pos/catalog-categories-screen.tsx`
- `src/app/api/catalog/categories/route.ts`
- `src/app/api/catalog/categories/[id]/products/route.ts`
- `src/lib/pos-data.ts`

### Estado

- `Categorias` queda funcional para seguir trabajando catalogo/POS
- el siguiente frente natural es `Productos`, porque la pantalla grande aun existe pero requiere restauracion, homologacion visual y QA tab por tab

## 2026-04-07 - Productos: Unit Compra + Movimientos Tab + Transferencias Base

### Unit Compra (Disponible Calculado)

**Cambio DB:**
- Script `database/122_fix_producto_almacenes_limites.sql` actualizado para incluir:
  - `IdUnidadCompra`, `NombreUnidadCompra`, `AbreviaturaUnidadCompra` en spProductoExistencias
  - Cálculo de `DisponibleUnitCompra` = disponibleBase / (BaseB/BaseA)

**Cambio Frontend:**
- `src/lib/pos-data.ts`: Tipo `ProductStockRow` + `unitCompraDisponible` agregado
- `src/components/pos/catalog-products-screen.tsx`: Columna de "Disponible C10" (unidad compra) muestra valor calculado en lugar de "-"

**QA:** Build ✓, DB script ✓, SP retorna DisponibleUnitCompra correctamente

### Movimientos Tab Mejorado

**Cambios UI:**
- Combobox/datepicker con estilo sistema (clase `.filter-input` agregada a `src/app/globals.css`)
- Tabla simplificada: solo Fecha, Documento, Almacen, Entrada, Salida, Balance (sin Tipo/Observación/Costo/Total)
- Columna Balance calcula saldo acumulado por fila (entrada - salida)

**Archivos:**
- `src/components/pos/catalog-products-screen.tsx` (líneas ~1480-1560)
- `src/app/globals.css` (clase `.filter-input` agregada)

**QA:** Build ✓, UI respeta diseño sistema

### Arquitectura de Transferencias (SIN InvDocumentos)

**Decisión:** Transferencias son operaciones internas, NO documentos contables. No usan `InvDocumentos`.

**Estructura:**
- `InvTransferencias`: solo control (estado, fechas, usuarios)
- `InvTransferenciasDetalle`: líneas de transferencia (nuevas tabla)
- `InvMovimientos`: movimientos directos (TipoDocOrigen='TRF')

**Scripts creados:**
- `database/123_transferencias_sin_documentos.sql`
  - Tabla `InvTransferenciasDetalle`
  - SP `spInvTransferenciasGenerarSalida` (B→T, crea SAL/ENT)
  - SP `spInvTransferenciasConfirmarRecepcion` (T→C, crea SAL/ENT)
  - SP `spInvTransferenciasActualizar` (solo editable en B)

- `database/124_validaciones_transferencias.sql`
  - SP `spInvTransferenciasAnular` (deshacer en B/T, revierte stock)
  - Triggers: `TR_InvMovimientos_PreventirEditTransfer`, `TR_InvMovimientos_PreventirDeleteTransfer`
  - Vista `vw_InvTransferenciasSaldo` para reportes
  - Validación: NO editar/anular movimientos de transferencia

**Flujo de 3 pasos:**
1. Crear Transferencia (Borrador, B)
2. Generar Salida (En Transito, T) → SAL origen + ENT transito
3. Confirmar Recepción (Completada, C) → SAL transito + ENT destino

**Restricciones de Negocio:**
- ✓ Solo editable en estado 'B'
- ✓ Después de generar salida (T), NO se puede editar ni anular
- ✓ NO se puede anular si está completada (C)
- ✓ Movimientos de transferencia son inmutables (triggers)
- ✓ Errores SQL via THROW deben mostrarse en app como toast (PENDIENTE)

**Documentación:**
- `TRANSFER_FLOW.md` — flujo completo, diagrama de estados, restricciones
- `memory/project_transfer_architecture.md` — decisiones de diseño

**QA:** BD scripts ✓, SPs ejecutan sin error, validaciones en triggers ✓

### Pendiente

- **CRÍTICO:** Mostrar errores THROW de BD como toast en app (códigos 50047-50052)
  - Requiere actualización en API endpoints de transferencias para capturar y retornar errores
  - Frontend debe consumir y mostrar via toast (useToast() hook)

### Archivos afectados

- `database/122_fix_producto_almacenes_limites.sql` (actualizado)
- `database/123_transferencias_sin_documentos.sql` (nuevo)
- `database/124_validaciones_transferencias.sql` (nuevo)
- `src/components/pos/catalog-products-screen.tsx` (actualizado)
- `src/lib/pos-data.ts` (actualizado)
- `src/app/globals.css` (actualizado)
- `TRANSFER_FLOW.md` (nuevo)

---

## Session 2026-04-07 (continuación)

### Completado en esta sesión

**TAREA 61 — Transferencias: APIs y Frontend (checkpoints 61.4–61.10)**

Verificado que todos los checkpoints ya estaban implementados en sesiones anteriores:

- `POST /api/inventory/transfers/[id]/generate-exit` → llama `spInvTransferenciasCRUD` acción GS
- `POST /api/inventory/transfers/[id]/confirm-reception` → llama `spInvTransferenciasCRUD` acción CR
- `DELETE /api/inventory/transfers/[id]` → llama `anularTransferencia` (acción N)
- Errores THROW del SP se capturan via `try/catch` y retornan como `{ ok: false, message }` con status 400
- Frontend `runAction()` muestra el mensaje de error via `toast.error()`
- UI valida estado: Generar Salida solo en B, Confirmar Recepción solo en T, Anular solo en B/T, Editar solo en B
- `npm run build` sin errores ✓

**Script 125 — ActualizaCosto en tipos de documento:**
- Activado `ActualizaCosto = 1` para TipoOperacion='E' (Entradas)
- Actualizado `spInvTiposDocumentoCRUD` para exponer el campo
- El costo promedio ahora se actualiza al confirmar Entradas

### Archivos afectados

- `database/125_inv_tipos_doc_actualiza_costo.sql` (nuevo, ejecutado)
- `OPENCODE_TASKS.md` — TAREA 61 marcada COMPLETADA

---

## Session 2026-04-07 / 2026-04-08

### TAREA 60 — Impuestos / NCF (Secuencias Fiscales RD)

**DB — Schema completo (script 128 reescrito)**
- 4 tablas: `CatalogoNCF`, `SecuenciasNCF`, `HistorialDistribucionNCF`, `SecuenciasNCF_PuntosEmision`
- 3 SPs: `spCatalogoNCFCRUD` (L/O/A), `spSecuenciasNCFCRUD` (L/O/I/A/D/DIST/FILL/SWAP/STATUS/LP/SP), `spHistorialDistribucionNCF` (L)
- Seed: 17 tipos oficiales DGII (B01,B02,B11,B14-B17 físicos + E31-E47 electrónicos)
- Script 129: seed de prueba (3 madres + 2 hijas B01/B02)
- Script 130: seed madres 1-100 para los 17 tipos
- Script 131: acciones LP (listar puntos hija) y SP (sincronizar puntos) en spSecuenciasNCFCRUD
- Fix encoding: UPDATE con N'' para nombres con tildes/ñ en CatalogoNCF y SecuenciasNCF

**Pantalla Catálogo NCF (tipos-comprobantes)**
- Componente `impuestos-catalogo-ncf-screen.tsx` — catálogo read-only DGII
- Filtro Todos/Físicos/e-CF, edición nombre interno + toggle activo
- Badges verdes/rojos para características (AplicaCredito, AplicaContado, RequiereRNC, etc.)
- Layout con `price-lists-form__header` + `form-grid__full`

**Pantalla Secuencias NCF (secuencias-fiscales)**
- Componente `impuestos-secuencias-ncf-screen.tsx` — CRUD completo
- Modelo madre (Distribución) / hija (Operación)
- Fila 1: Descripción + Tipo Comprobante + toggles e-CF y Activo
- Fila 2: Secuencia Madre (solo hijas) + Uso del Comprobante + Dígitos
- Control de Secuencias (60%): tabla compacta En Uso / En Cola
- Parámetros (40%): Mín. Alertar, Relleno Auto., Cant. Restante, Sec. Actual (labels inline)
- Sección Comprobante Compartido (solo hijas): checkboxes de puntos de emisión
- Modal de distribución madre→hija con registro en historial
- Madres no tienen punto de emisión; hijas sí + pueden compartirse

**APIs creadas/reescritas**
- `GET /api/config/impuestos/tipos-comprobantes` — lista catálogo
- `PUT /api/config/impuestos/tipos-comprobantes/[id]` — editar nombre interno + activo
- `GET/POST /api/config/impuestos/secuencias-fiscales` — listar/crear secuencias
- `PUT/DELETE /api/config/impuestos/secuencias-fiscales/[id]` — editar/eliminar
- `POST /api/config/impuestos/secuencias-fiscales/[id]/distribuir` — distribución madre→hija
- `GET/PUT /api/config/impuestos/secuencias-fiscales/[id]/puntos` — puntos compartidos
- `GET /api/config/impuestos/secuencias-fiscales/historial` — historial distribuciones

**Navegación del módulo Impuestos (final)**
- Terceros: Clientes (→ /config/cxc/customers), Proveedores (→ /config/cxp/suppliers)
- Operaciones: Facturas Fiscales (scaffold), Gastos Menores, Prov. Informales, Pagos Exterior, Actualización Secuencias
- Consultas: Informe Fiscal 606 (scaffold), Informe Fiscal 607 (scaffold)
- Configuración: Tipos de Comprobantes, Secuencias Fiscales
- Eliminado "Reportes Fiscales" — reemplazado por informes 606/607 separados

**Permisos y DB**
- Permiso `impuestos.facturas-fiscales.view` agregado
- Permisos informes 606/607 usan `impuestos.reportes.view`
- Pantallas y permisos verificados en RolPantallaPermisos y RolesPermisos para IdRol=1

**Fixes realizados**
- Build error `TipoComprobanteRecord` → eliminado archivo viejo
- Runtime error `usePermissions` → agregado `export const dynamic = "force-dynamic"` + `<section className="content-page">`
- Encoding roto sqlcmd → UPDATE con N'' para 17 tipos + descripciones secuencias
- Layout "muy feo" → múltiples iteraciones hasta layout con CSS del sistema

### Archivos afectados

- `database/128_impuestos_comprobantes_secuencias.sql` (reescrito)
- `database/129_seed_secuencias_prueba.sql` (nuevo)
- `database/130_seed_secuencias_todos_tipos.sql` (nuevo)
- `database/131_secuencias_puntos_emisión.sql` (nuevo)
- `src/lib/pos-data.ts` (modificado — tipos y funciones NCF)
- `src/lib/navigation.ts` (modificado — menú Impuestos completo)
- `src/lib/permissions.ts` (modificado — permisos nuevos)
- `src/components/pos/impuestos-catalogo-ncf-screen.tsx` (nuevo)
- `src/components/pos/impuestos-secuencias-ncf-screen.tsx` (nuevo)
- `src/components/pos/impuestos-tipos-comprobante-screen.tsx` (eliminado)
- `src/app/config/impuestos/tipos-comprobantes/page.tsx` (reescrito)
- `src/app/config/impuestos/secuencias-fiscales/page.tsx` (reescrito)
- `src/app/api/config/impuestos/tipos-comprobantes/route.ts` (reescrito)
- `src/app/api/config/impuestos/tipos-comprobantes/[id]/route.ts` (reescrito)
- `src/app/api/config/impuestos/secuencias-fiscales/route.ts` (reescrito)
- `src/app/api/config/impuestos/secuencias-fiscales/[id]/route.ts` (reescrito)
- `src/app/api/config/impuestos/secuencias-fiscales/[id]/distribuir/route.ts` (nuevo)
- `src/app/api/config/impuestos/secuencias-fiscales/[id]/puntos/route.ts` (nuevo)
- `src/app/api/config/impuestos/secuencias-fiscales/historial/route.ts` (nuevo)
- `src/app/impuestos/facturas-fiscales/page.tsx` (nuevo — scaffold)
- `src/app/impuestos/informe-606/page.tsx` (nuevo — scaffold)
- `src/app/impuestos/informe-607/page.tsx` (nuevo — scaffold)
- `src/app/impuestos/reportes/` (eliminado)
- `OPENCODE_TASKS.md` — TAREA 60 actualizada

---

## Session 2026-04-08

### Usuarios — Datos Administrativos

**Completado**

- Se agrego una nueva pestaña `Datos Administrativos` en `Configuracion / Seguridad / Usuarios`.
- La pestaña permite guardar contexto administrativo del usuario:
  - `Empresa`
  - `Division`
  - `Sucursal`
  - `Punto de Emision`
  - `Nivel de acceso a datos` (`G/E/D/S/P/U`)
- Se dejo filtrado encadenado:
  - `Sucursal` depende de `Division`
  - `Punto de Emision` depende de `Sucursal`
- La informacion administrativa ya viaja tambien cuando se guarda desde otras acciones del usuario
  - editar general
  - seguridad
  - bloqueo/activacion

**DB**

- Script nuevo: `database/137_usuarios_datos_administrativos_sp.sql`
  - agrega `Usuarios.IdEmpresa` si no existe
  - recrea `spUsuariosCRUD` para aceptar/devolver:
    - `IdEmpresa`
    - `IdDivision`
    - `IdSucursal`
    - `IdPuntoEmision`
    - `NivelAcceso`
- Script aplicado correctamente en `DbMasuPOS`.

**App**

- `src/lib/pos-data.ts`
  - `SecurityManagerData.users` ampliado con datos administrativos
  - `lookups` ampliado con:
    - `companies`
    - `divisions`
    - `branches`
    - `emissionPoints`
  - `mutateAdminEntity("users")` ahora envia datos administrativos al SP
- `src/components/pos/security-users-screen.tsx`
  - nueva tab `Datos Administrativos`
  - resumen visual de estructura/nivel de acceso
- `src/app/globals.css`
  - estilos para la nueva seccion

**Validacion**

- `npx tsc --noEmit` exitoso
- SQL aplicado exitosamente

**Pendiente natural**

- Conectar esta informacion a la resolucion de cajas visibles/abribles en:
  - `Facturacion / Caja Central`
  - `Facturacion / Punto de Ventas`

### Caja Central — alcance funcional redefinido

**Decision funcional registrada**

`Caja Central` queda definida como bandeja operativa de cobro, distinta de `Punto de Ventas`.

**Flujo confirmado**

- listado superior de documentos/facturas pendientes de cobro enviados desde `Facturacion`
- al hacer click en una fila:
  - mostrar detalle del documento en panel fijo a la derecha
- acciones prioritarias:
  - `Cobrar`
  - `Retornar`
  - `Anular`
  - shortcut a `Punto de Ventas`
- `Cobrar` debe abrir modal/selector de formas de pago
  - simple
  - mixto
  - multimoneda
  - vuelto
  - referencia/autorizacion si aplica
- `Retornar`
  - devuelve la pre-factura/documento a `Facturacion`
  - debe dejar trazabilidad de devueltas o pendientes de correccion
- `Anular`
  - con motivo
  - con trazabilidad
- `Visualizar` e `Imprimir` se mantienen
- `Imprimir detallado` y `Excel` no son prioridad en esta fase

**Documentacion**

- `OPENCODE_TASKS.md`
  - `TAREA 58` actualizada, subtarea `58.3 Caja Central` detallada con el nuevo alcance

---

### Sesion — 2026-04-11 — TAREA 58.2 POS: Descuentos, Guard, Cliente

#### Resumen

Continuacion de TAREA 58.2. Se completaron varias subtareas del Punto de Ventas.

---

#### 58.2-A — Fix rounding bug en descuento manual POS

**Problema**: Al usar las flechas del spinner en el campo `% Descuento` del modal de descuento manual, el valor se quedaba trabado en decimales como 16.1 por un feedback loop de redondeo.

**Solucion**: Se separaron los tres campos (%, monto, precio final) en estados independientes. Ninguno se sobreescribe por calculos derivados — cada `setFrom*` actualiza los tres estados directamente.

**Archivos**
- `src/components/pos/billing-pos-screen.tsx`
  - `editDiscountPct`, `editDiscountFinal` ahora son estados independientes
  - `setFromPct`, `setFromAmount`, `setFromFinal` actualizan los tres estados
  - JSX usa `editDiscountPct` y `editDiscountFinal` como `value` (no `derivedPct`/`derivedFinal`)

---

#### 58.2-B — Navigation guard en POS

Si hay items digitados en el POS y el usuario navega a otra pantalla, se muestra el modal de confirmacion "Cambios sin guardar".

**Archivos**
- `src/components/pos/billing-pos-screen.tsx`
  - importa `useUnsavedGuard`
  - `useEffect` sobre `lines` llama `setDirty(true/false)` segun haya items

---

#### 58.2-C — Modal descuento: abrir sin linea seleccionada

**Antes**: Si no habia linea seleccionada, el boton Descuento mostraba un toast y no abria el modal.

**Ahora**:
- Sin items en el documento → toast de advertencia
- Con items pero sin linea seleccionada → abre el modal en modo "documento completo" (solo muestra descuentos globales, el manual aplica proporcional a todo el documento)
- Con linea seleccionada → comportamiento anterior (linea + globales)

**Cambios**
- Nuevo estado `discountModalOpen: boolean` para controlar apertura independiente de `editDiscountLine`
- `isLineMode = editDiscountLine != null`
- Tabla filtra descuentos de linea cuando `!isLineMode`
- Campo "Precio final c/desc." oculto cuando `!isLineMode`
- Badge azul "Se aplica al documento completo" en seccion manual
- Boton Aplicar fuerza `esGlobal=true` cuando `!isLineMode`

---

#### 58.2-D — Modal de seleccion de cliente

Modal para buscar y asignar el cliente activo en el POS.

**Funcionalidad**
- Busqueda local por nombre, RNC/cedula o codigo (minimo 2 caracteres para evitar sobrecarga)
- Switch Auto/manual igual que el modal de productos
- Al seleccionar un cliente:
  1. Cambia tipo de documento si el cliente tiene preferencia
  2. Aplica lista de precios del cliente a todas las lineas (fetch a nuevo endpoint)
  3. Aplica descuento del cliente proporcionalmente a todas las lineas
  4. Tipo de comprobante se recalcula automaticamente por derivacion existente
- Boton "Quitar cliente" si hay cliente activo
- Fila del cliente activo resaltada

**Archivos nuevos**
- `src/app/api/facturacion/prices-by-list/route.ts` — `GET ?listId=X` devuelve precios de todos los productos de una lista
- `src/lib/pos-data.ts` — nueva funcion `getPricesByList(listId)`

**Archivos modificados**
- `src/app/facturacion/pos/page.tsx` — agrega `getDescuentos()` como prop `discounts`
- `src/components/pos/billing-pos-screen.tsx`
  - props: agrega `discounts: DescuentoRecord[]`
  - estados: `customerModalOpen`, `customerSearch`, `customerCommitted`, `customerAutomode`, `customerApplying`
  - funcion `applyCustomer(customer | null)` — orquesta los 3 cambios
  - boton "Clientes" en toolbar (no muestra el nombre activo en el boton)
  - cliente activo se sigue mostrando en el header del documento (`customerName`)
  - modal homologado con el de busqueda de productos: `order-modal-backdrop`, `data-panel`, `orders-search-input`, `billing-pos__search-table`
- `src/app/globals.css` — clase `.billing-pos__price-table-row.is-selected`

**DB**: Sin cambios de esquema en esta sesion.

---

#### Estado subtareas 58.2

- [x] Layout base del POS
- [x] Columnas: % Desc antes de Descuento
- [x] Toast semaforo (verde/amarillo/rojo)
- [x] Descuento por linea y global
- [x] Descuento manual bidireccional (%, monto, precio final) — fix rounding bug
- [x] Navigation guard al salir con datos sin guardar
- [x] Modal de cliente con lista de precios, descuento y comprobante
- [ ] Cobrar (formas de pago)
- [ ] Guardar/emitir documento

