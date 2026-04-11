# MASU POS V2 â€” OpenCode Task Queue

> Documento vivo. Actualizar al inicio/fin de cada sesion.
> Leer `SESSION_HISTORY.md` para contexto completo del proyecto antes de ejecutar cualquier tarea.

---

## Como usar este archivo

1. Leer `SESSION_HISTORY.md` para entender el estado actual del proyecto.
2. Ejecutar las tareas en el orden indicado.
3. Marcar cada checkpoint al completarlo: cambiar `[ ]` por `[x]`.
4. Al terminar la sesion, registrar resultado en la seccion `## Log de Sesiones` al final.

---

## Stack de referencia

- App: `D:\Masu\V2` (Next.js App Router, monolith Front + API)
- DB: SQL Server `DbMasuPOS`
- Auth: cookies `masu_session_id` / `masu_session_token`, validacion via `spAuthValidarSesion`
- Session helper: `src/lib/auth-session.ts`
- Data layer: `src/lib/pos-data.ts`
- Menu/shell: `src/components/pos/app-shell.tsx`
- Middleware: `middleware.ts`

---

## TAREA 1 â€” Autorizacion por Rol (Menu + Rutas)

**Estado:** `COMPLETADA`

**Contexto:**
- Auth de sesion ya esta implementado y funcionando.
- El usuario tiene un solo rol (`Usuarios.IdRol`).
- Existen tablas `Roles` y `Permisos` en DB con sus SPs CRUD.
- El menu se renderiza en `src/components/pos/app-shell.tsx`.
- El middleware esta en `middleware.ts`.

**Objetivo:** Implementar autorizacion por rol sobre el auth de sesion existente sin romper nada.

### Checkpoints

- [x] **1.1** DB: Crear o actualizar SP `spPermisosObtenerPorRol` que recibe `@IdRol INT`
      y retorna la lista de claves de rutas/modulos permitidos para ese rol.

- [x] **1.2** API: Agregar endpoint `GET /api/auth/permissions` que lee el rol del usuario
      en sesion y retorna sus permisos como array plano de claves de ruta.

- [x] **1.3** Client: Crear `PermissionsContext` (React context) que se puebla al hacer login
      y queda disponible en toda la app.

- [x] **1.4** Menu: En `app-shell.tsx` filtrar items del menu para mostrar solo los que
      el rol del usuario tiene permitidos.

- [x] **1.5** Middleware: Extender `middleware.ts` con un mapa `ROUTE_PERMISSIONS` que asocia
      cada patron de ruta a una clave de permiso y rechaza requests no autorizados.

- [x] **1.6** Build: `npm run build` sin errores.

**Restricciones:**
- No cambiar nombres de cookies ni flujo de validacion de sesion.
- Los cambios deben ser compatibles con usuarios sin permisos definidos (fallback a deny).

---

## TAREA 2 â€” Propagar `@IdSesion/@TokenSesion` a SPs CRUD Restantes

**Estado:** `COMPLETADA`

**Contexto:**
- SPs ya migrados: `spProductosCRUD`, `spOrdenesCRUD`.
- SPs pendientes de recibir los parametros opcionales: `spRolesCRUD`, `spPermisosCRUD`,
  `spMesasCRUD`, `spCategoriasCRUD` (verificar si hay otros en DB).
- Los parametros deben ser opcionales y no bloquear ejecucion si son NULL (retrocompatibles).

### Checkpoints

- [x] **2.1** DB: Generar script `ALTER` para cada SP pendiente agregando al final:
      `@IdSesion INT = NULL, @TokenSesion NVARCHAR(128) = NULL`
      Un script consolidado por SP.

- [x] **2.2** `pos-data.ts`: Actualizar cada funcion que llama a esos SPs para pasar
      `IdSesion` y `TokenSesion` extraidos de la sesion validada.

- [x] **2.3** API routes: Actualizar los handlers correspondientes para extraer la sesion
      y forwarding los valores a las funciones de pos-data.

- [x] **2.4** Build: `npm run build` sin errores.

---

## TAREA 3 â€” Feed de Actividad Real en Tab `Actividad` del Usuario

**Estado:** `COMPLETADA`

**Contexto:**
- UI: `src/components/pos/security-users-screen.tsx`, tab `Actividad` actualmente con datos placeholder.
- DB: tabla `SesionesActivas` con columnas `IdSesion`, `IdUsuario`, `FechaInicio`,
  `FechaUltima`, `TokenSesion`, `Activa`.
- Tabla `Usuarios` tiene timestamps de creacion, modificacion y ultimo login.

### Checkpoints

- [x] **3.1** DB: Crear SP `spUsuarioActividad` que recibe `@IdUsuario INT` y retorna:
      - Ultimas N sesiones (fecha, duracion, estado activa/cerrada)
      - Fecha creacion y ultima modificacion de cuenta
      - Total de sesiones historicas

- [x] **3.2** API: Agregar endpoint `GET /api/users/[id]/activity` con validacion de sesion
      admin que llama a `spUsuarioActividad`.

- [x] **3.3** UI: Poblar el tab `Actividad` con lista de sesiones recientes (fecha, badge
      activa/cerrada) y stats resumen (total sesiones, ultimo login).
      Respetar los tokens de tipografia y estilo visual del modal existente.

- [x] **3.4** Build: `npm run build` sin errores.

---

## TAREA 4 â€” QA Matrix Seguridad (Usuarios / Roles / Permisos E2E)

**Estado:** `COMPLETADA`

**Contexto:**
- Modulo seguridad con 3 pantallas: Usuarios, Roles, Permisos.
- SPs: `spUsuariosCRUD`, `spRolesCRUD`, `spPermisosCRUD`.
- Auth requerido en todos los endpoints protegidos.

**Objetivo:** Generar documento QA matriz completa en markdown con casos de prueba E2E.

### Checkpoints

- [x] **4.1** Casos CRUD Usuarios:
      Crear (valido / campos faltantes / usuario duplicado), editar, cambiar password,
      flag forzar cambio de clave, eliminar/desactivar.

- [x] **4.2** Casos CRUD Roles:
      Crear (valido / nombre duplicado / nombre vacio), editar, eliminar con usuarios
      asignados (esperar error), eliminar sin usuarios.

- [x] **4.3** Casos Permisos:
      Asignar permiso a rol, quitar permiso, verificar que el menu filtra correctamente
      tras el cambio.

- [x] **4.4** Casos flujo Auth:
      Login valido, login con flag cambio forzado (redirige), credenciales invalidas,
      sesion expirada redirige a login, logout limpia sesion.

- [x] **4.5** Entregar como tablas markdown con columnas: Precondicion | Pasos | Resultado
      esperado | Pass/Fail.

---

## TAREA 5 â€” BUG FIX: Menu de Navegacion Vacio por Filtro de Permisos

**Estado:** `COMPLETADA`

**Contexto:**
- El menu principal (topnav) no muestra opciones porque `hasPermission()` retorna `false`
  para todas las claves cuando el rol no tiene permisos asignados en DB.
- Flujo actual: `app-shell.tsx` llama `hasPermission(key)` -> `permissions-context.tsx`
  verifica contra array de permisos -> array viene de `GET /api/auth/permissions` ->
  `getPermissionKeysByRole()` en `auth-session.ts` -> SP `spPermisosObtenerPorRol` retorna vacio.
- El mapa maestro de claves de permiso esta en `ROUTE_PERMISSIONS` de `src/lib/permissions.ts`.

**Objetivo:** Restaurar visibilidad del menu para Administrador General y dejar la base
para que otros roles funcionen al asignarles permisos.

### Checkpoints

- [x] **5.1** API: En `src/app/api/auth/permissions/route.ts`, agregar logica server-side:
      si el rol del usuario es "Administrador" o "Administrador General" (o IdRol = 1,
      verificar cual aplica en DB), retornar TODAS las claves `.key` de `ROUTE_PERMISSIONS`
      definidas en `src/lib/permissions.ts` sin consultar la DB. Esto actua como safety net
      para el superadmin.

- [x] **5.2** DB: Generar script SQL `INSERT` para poblar la tabla de permisos-por-rol
      con todas las rutas/permisos para el rol Administrador General, asi cuando otros
      roles se configuren el sistema ya tiene datos de referencia.

- [x] **5.3** Verificar que el menu principal y los submenus de configuracion (Seguridad,
      Catalogo, Comedor, Empresa) se renderizan correctamente para el usuario admin.

- [x] **5.4** Build: `npm run build` sin errores.

**Restricciones:**
- NO cambiar el flujo de `hasPermission` en `permissions-context.tsx` â€” el fix debe ser server-side.
- NO modificar cookies ni flujo de sesion existente.

---

## TAREA 6 â€” Polish Login: Alinear con UI 3.0

**Estado:** `COMPLETADA`

**Contexto:**
- Login actual: `src/app/login/page.tsx`. CSS vanilla en `src/app/globals.css` (clases `.login-*`).
- Referencia visual: `D:\Masu\UI 3.0\app\login\page.tsx` (Tailwind/shadcn).
- V2 ya tiene features superiores a UI 3.0: branding dinamico desde API, force password change,
  remember username con localStorage. Esos se MANTIENEN. Solo se adoptan mejoras visuales.

**Objetivo:** Adoptar mejoras visuales y UX de UI 3.0 sin perder funcionalidad existente.

### Checkpoints

- [x] **6.1** CSS: Agregar fondo con gradiente al `.login-page`:
      `background: linear-gradient(to bottom right, #f1f5f9, #f8fafc, #eff6ff);`
      Reemplazar el fondo plano actual.

- [x] **6.2** Boton login: deshabilitar cuando usuario o clave estan vacios.
      Agregar `disabled={!username.trim() || !password.trim() || isPending}` al boton.
      CSS para estado disabled: `opacity: 0.5; pointer-events: none;`

- [x] **6.3** Loading state: reemplazar texto "Entrando..." por icono Loader2 animado + texto.
      Importar `Loader2` de lucide-react. Agregar clase CSS `.spin` con
      `animation: spin 1s linear infinite` y `@keyframes spin { to { transform: rotate(360deg) } }`.

- [x] **6.4** Error styling: envolver mensaje de error en un div con fondo coloreado:
      clase `.login-error-box` con `background: rgba(239,68,68,0.08); border: 1px solid rgba(239,68,68,0.2);
      border-radius: 0.6rem; padding: 0.75rem; color: #dc2626; font-size: 0.88rem;`

- [x] **6.5** Remember user: cambiar valor default de `false` a `true`.

- [x] **6.6** Selector de idioma: agregar boton ES/EN en esquina superior derecha del `.login-page`
      usando `useI18n()`. Posicion absoluta, clase `.login-lang-toggle`.
      CSS: `position: absolute; top: 1rem; right: 1rem;` con estilo similar a `.icon-button--lang`.

- [x] **6.7** Build: `npm run build` sin errores.

**Restricciones:**
- NO tocar el flujo de auth, cookies, ni force-password-change.
- NO reemplazar logo dinamico por SVG hardcoded â€” mantener fetch desde API.
- Cambios solo en `src/app/login/page.tsx` y `src/app/globals.css`.

---

## TAREA 7 â€” Polish Usuarios: Alinear con UI 3.0

**Estado:** `COMPLETADA`

**Contexto:**
- Pantalla actual: `src/components/pos/security-users-screen.tsx` (572 lineas).
- CSS en `src/app/globals.css` (clases `.users-*`).
- Referencia visual: `D:\Masu\UI 3.0\app\config\security\users\page.tsx` (Tailwind/shadcn).
- V2 ya tiene features superiores: activity feed real con sesiones/IP/canal,
  force password change, pantalla de inicio, username separado. Esos se MANTIENEN.

**Objetivo:** Adoptar mejoras visuales y campos faltantes de UI 3.0 sin perder funcionalidad.

### Checkpoints

- [x] **7.0a** BUG FIX: Selector de idioma en Login no funciona.
      **Problema:** El boton ES/EN agregado en TAREA 6.6 no cambia el idioma al hacer click.
      **Fix requerido:**
      1. Verificar que el boton llama a `setLanguage()` del hook `useI18n()` correctamente.
         Debe alternar: `onClick={() => setLanguage(language === "es" ? "en" : "es")}`.
      2. Verificar que el componente Login esta envuelto en `I18nProvider`. Si el login
         esta fuera del provider (porque esta fuera del layout protegido), envolver el
         contenido del login page en `<I18nProvider>` o mover el provider al root layout.
      3. Agregar icono `Globe` de lucide-react al boton, antes del texto "ES"/"EN".
         Patron visual: `<Globe size={16} /> <span>ES</span>` â€” mismo estilo que el
         selector de idioma del `app-shell.tsx` (clase `.icon-button--lang` + `.lang-pill`).
      4. Verificar que al cambiar idioma, los textos del login (titulo, placeholders,
         boton, footer) se actualizan.

- [x] **7.0b** BUG FIX: Menu contextual cortado en tabla de usuarios.
      **Problema:** El menu `.table-menu` (position: absolute) se recorta porque el
      contenedor `.table-wrap` tiene `overflow: auto`. Cuando CSS tiene `overflow-x: auto`
      en un eje, el browser FUERZA `overflow-y: auto` tambien (spec CSS), asi que
      `overflow-y: visible` en `.users-table-wrap` no tiene efecto real.
      El primer item "Editar" queda oculto arriba del menu en la primera fila.

      **Fix requerido â€” dos cambios:**

      1. En `src/app/globals.css`, cambiar `.users-table-wrap` para quitar overflow del
         wrapper y dejar que el menu se desborde:
         ```css
         .users-table-wrap {
           overflow: visible;
           position: relative;
         }
         ```
         Si se necesita scroll horizontal para tablas anchas, envolver la `<table>` en un
         `<div>` interno con `overflow-x: auto` DENTRO del `.users-table-wrap`, pero el
         wrapper externo debe ser `overflow: visible` para que los menus no se corten.

      2. Subir z-index del `.table-menu` a al menos `z-index: 30` (actualmente es 24)
         para que pase por encima de otros elementos.

      3. Verificar que el menu se ve completo en la primera fila (4 opciones visibles:
         Editar, Cambiar Contrasena, Bloquear Cuenta, Eliminar) y en las ultimas filas
         (clase `.is-up` para abrir hacia arriba).

- [x] **7.1** Avatar en filas de tabla: agregar circulo con iniciales en la columna "Nombre".
      Reutilizar funcion `initials()` ya existente. Crear clase `.users-table__avatar`:
      `width: 2.2rem; height: 2.2rem; border-radius: 999px; background: #dbeafe;
      color: #1d4d86; font-weight: 800; font-size: 0.75rem; display: grid; place-items: center;`
      Envolver en flex con gap: `<td><div class="users-name-cell"><avatar/><span>nombre</span></div></td>`

- [x] **7.2** Ampliar modal: cambiar ancho de `.users-modal` de `min(34rem, 100%)` a `min(42rem, 100%)`.

- [x] **7.3** Estado 3 niveles: agregar estado "Bloqueado" ademas de Activo/Inactivo. *(omitido por instruccion: no existe campo `locked` en modelo actual)*
      - Agregar chip: `.chip--warning` (ya existe en CSS: `background: var(--warning-bg); color: var(--warning-text)`).
      - En la tabla y modal, si `user.active === false && user.locked === true` (o logica equivalente
        segun el campo disponible en DB), mostrar chip "Bloqueado" con `.chip--warning`.
      - Si el campo `locked` no existe en el tipo `users`, OMITIR este checkpoint y
        dejar solo Activo/Inactivo. No modificar la DB por esto.

- [x] **7.4** Loading spinner en save: agregar icono `Loader2` con animacion spin al boton
      Guardar mientras `isPending === true`. Reutilizar la clase `.spin` creada en TAREA 6.
      Patron: `{isPending ? <><Loader2 size={16} className="spin"/> Guardando...</> : <><Save size={16}/> Guardar</>}`

- [x] **7.5** i18n: reemplazar textos hardcoded en espanol por claves de traduccion usando `useI18n()`.
      - Verificar que `useI18n` ya esta importado o importarlo.
      - Reemplazar al menos: titulos de tabs, labels de formulario, textos de botones,
        mensajes de toast, headers de tabla.
      - Verificar que las claves existen en `src/lib/i18n.tsx`. Si no existen, agregarlas
        en ambos idiomas (es/en).
      - NO es necesario traducir TODOS los textos en una pasada â€” priorizar los visibles
        en tabla y modal header.

- [x] **7.6** Build: `npm run build` sin errores.

**Restricciones:**
- NO agregar campo telefono ni notas por ahora (se evalua en fase posterior).
- NO agregar PIN â€” V2 usa password, no PIN.
- NO cambiar la API ni los SPs â€” cambios solo en el componente y CSS.
- Mantener las features existentes de V2: activity feed, force password change,
  pantalla de inicio, username separado.

---

## TAREA 8 â€” Pantalla Dedicada: Gestion de Roles (security-roles-screen)

**Estado:** `COMPLETADA`

**Contexto:**
- Actualmente Roles usa el componente generico `EntityCrudSection` en `security-manager.tsx` (lineas 32-42).
- La pantalla de Usuarios (`security-users-screen.tsx`) ya esta polished (TAREA 7) y es la referencia de patron.
- El diseno visual de referencia esta en `D:\Masu\UI 3.0\app\config\security\roles\page.tsx`.
  Ese archivo usa Tailwind/shadcn pero V2 usa CSS vanilla en `src/app/globals.css`.
  HAY QUE TRADUCIR el diseno, NO copiar clases de Tailwind.
- Datos disponibles en `SecurityManagerData`: `roles` (id, name, description, active),
  `rolePermissions` (roleId, roleName, permissionId, permissionName, module, screen, active).
- API CRUD existente: `POST/PUT/DELETE /api/admin/roles` via `mutateAdminEntity` en `pos-data.ts`.

**Objetivo:** Crear componente dedicado `security-roles-screen.tsx` visualmente alineado con
el diseno de `D:\Masu\UI 3.0\app\config\security\roles\page.tsx`, pero implementado con el
sistema CSS vanilla de V2 (`globals.css`, clases BEM). Reemplaza el `EntityCrudSection` generico.
Ejecutar DESPUES de TAREA 7 para que el patron de usuarios ya este actualizado.

### Referencia de diseno (UI 3.0 -> V2 CSS)

Mapeo de componentes UI 3.0 a clases CSS existentes en V2:
- `Card` + `CardHeader` + `CardContent` -> `.data-panel` + `.data-panel__header`
- `Table/TableHeader/TableRow/TableCell` -> `.data-table` (dentro de `.table-wrap`)
- `Badge` -> `.chip` + variantes (`.chip--success`, `.chip--neutral`, `.chip--info`)
- `Button` primary -> `.primary-button`
- `Button` outline -> `.secondary-button`
- `Button` destructive -> `.danger-button`
- `Input` search con icono -> `.searchbar` + `.searchbar input`
- `Dialog` -> `.users-modal-backdrop` + `.roles-modal` (nuevo, clonar de `.users-modal`)
- `Tabs/TabsList/TabsTrigger` -> `.users-modal__tabs` + `.users-tab` (renombrar a `.modal-tabs` + `.modal-tab` o reutilizar las de users)
- `DropdownMenu` -> `.table-menu` (ya existe en V2)
- `Switch` -> checkbox con clase `.form-switch` (o usar `<input type="checkbox">` con estilo existente)
- `FieldGroup/Field/FieldLabel` -> `.form-grid` + `.form-group` + `label`

Iconos de Lucide a usar: `Shield`, `Users`, `Key`, `MoreHorizontal`, `Pencil`, `Trash2`,
`Plus`, `Search`, `Save`, `X`, `Clock`, `Calendar`.

### Checkpoints

- [x] **8.0** Estado 3 niveles en Usuarios (pendiente de TAREA 7.3).
      Ahora SI hay acceso completo a modificar la base de datos.

      **DB:**
      1. Agregar columna `Bloqueado BIT NOT NULL DEFAULT 0` a la tabla `Usuarios`.
         Script: `ALTER TABLE dbo.Usuarios ADD Bloqueado BIT NOT NULL CONSTRAINT DF_Usuarios_Bloqueado DEFAULT 0;`
      2. Verificar que `spUsuariosCRUD` maneja el campo `Bloqueado` en las acciones
         I (insert), A (update) y L (list). Si no lo tiene, hacer `ALTER PROCEDURE`
         para agregarlo como parametro opcional `@Bloqueado BIT = 0` y mapearlo en
         el INSERT/UPDATE. En el SELECT (accion L), incluirlo en el resultset.

      **Data layer (`pos-data.ts`):**
      3. Agregar `locked: boolean` al tipo de usuarios en `SecurityManagerData`.
      4. En `getSecurityManagerData()`, mapear la columna `Bloqueado` -> `locked`.
      5. En `mutateAdminEntity("users", ...)`, pasar el campo `locked`/`Bloqueado` al SP.

      **UI (`security-users-screen.tsx`):**
      6. Agregar `locked: boolean` al tipo `UserForm` y al `emptyForm` (default `false`).
      7. En la tabla, columna Estado: 3 estados con chips:
         - `active && !locked` -> `.chip--success` "Activo"
         - `!active && !locked` -> `.chip--neutral` "Inactivo"
         - `locked` (sin importar active) -> `.chip--warning` "Bloqueado"
      8. En el menu contextual, actualizar la accion de bloqueo:
         - Si activo y no bloqueado: "Bloquear Cuenta" (setea `locked=true`)
         - Si bloqueado: "Desbloquear Cuenta" (setea `locked=false`)
         - Si inactivo y no bloqueado: "Activar Cuenta" (setea `active=true`)
      9. En el modal header, mostrar el chip correcto segun los 3 estados.

      **Build:** `npm run build` sin errores.

- [ ] **8.1** Crear `src/components/pos/security-roles-screen.tsx`:

      **TABLA PRINCIPAL** (traduccion exacta del Card + Table de UI 3.0):
      ```
      <section class="data-panel">
        <div class="data-panel__header data-panel__header--actions">
          <div>
            <h2>Gestion de Roles</h2>
            <p>Administra roles, permisos y niveles de acceso.</p>
          </div>
          <div class="roles-toolbar">  <!-- mismo patron que .users-toolbar -->
            <label class="searchbar roles-search">
              <Search icon/> <input placeholder="Buscar roles..."/>
            </label>
            <button class="primary-button"> <Plus icon/> Nuevo Rol </button>
          </div>
        </div>
        <div class="table-wrap roles-table-wrap">
          <table class="data-table roles-table">
            <thead>
              <tr>
                <th>Rol</th>           <!-- icono Shield color + nombre + badge "Sistema" si aplica -->
                <th>Descripcion</th>
                <th>Usuarios</th>      <!-- icono Users + count -->
                <th>Permisos</th>      <!-- icono Key + count -->
                <th>Estado</th>        <!-- chip success/neutral -->
                <th>Acciones</th>      <!-- MoreHorizontal con table-menu -->
              </tr>
            </thead>
          </table>
        </div>
      </section>
      ```

      Columna "Rol": renderizar un cuadrado de color 2rem x 2rem con icono Shield blanco
      + nombre del rol a la derecha. Colores por indice ciclico:
      `var(--brand)`, `#10b981`, `#3b82f6`, `#8b5cf6`, `#f97316`, `#ec4899`.

      Columna "Usuarios": icono `Users` 16px muted + numero. Obtener count de `data.users`
      filtrado por `roleId` (client-side).

      Columna "Permisos": icono `Key` 16px muted + numero. Obtener count de
      `data.rolePermissions` filtrado por `roleId`.

      Menu contextual (`.table-menu`): Editar | Ver Permisos | separador | Eliminar (`.is-danger`).

      **MODAL DE EDICION/CREACION** (traduccion del Dialog de UI 3.0):
      ```
      <div class="users-modal-backdrop">  <!-- reutilizar backdrop existente -->
        <section class="roles-modal">     <!-- clonar estilos de .users-modal -->
          <!-- HEADER -->
          <div class="roles-modal__header">
            <!-- Si edicion: icono Shield con color + nombre + descripcion + chip estado -->
            <!-- Si nuevo: titulo "Nuevo Rol" + descripcion -->
            <div class="roles-modal__header-actions">
              <span class="chip chip--success/neutral">Activo/Inactivo</span>
              <button class="icon-button" onclick=close><X/></button>
            </div>
          </div>

          <!-- TABS (reutilizar clases .users-modal__tabs / .users-tab) -->
          <div class="users-modal__tabs">
            <button class="users-tab is-active"><Shield/> General</button>
            <button class="users-tab"><Clock/> Informacion</button>
          </div>

          <!-- TAB GENERAL: formulario -->
          <form class="form-grid">
            Nombre (input text, required)
            Descripcion (textarea, 3 rows)
            Estado activo (checkbox/switch con label y descripcion en linea,
                          dentro de un div con borde redondeado y padding,
                          clase .roles-switch-row)
          </form>

          <!-- TAB INFORMACION: 4 cards en grid 2x2 -->
          <div class="roles-info-grid">  <!-- display: grid; grid-template-columns: 1fr 1fr; gap: 1rem -->
            <div class="roles-info-card">  <!-- border 1px solid var(--line); border-radius: 0.72rem; padding: 1rem -->
              <span class="roles-info-card__label"><Calendar/> Fecha Creacion</span>
              <p class="roles-info-card__value">2023-01-01</p>
            </div>
            <div class="roles-info-card">
              <span class="roles-info-card__label"><Users/> Usuarios Asignados</span>
              <p class="roles-info-card__value">2 usuarios</p>
            </div>
            <div class="roles-info-card">
              <span class="roles-info-card__label"><Key/> Permisos</span>
              <p class="roles-info-card__value">24 permisos</p>
            </div>
            <div class="roles-info-card">
              <span class="roles-info-card__label"><Shield/> Tipo</span>
              <p class="roles-info-card__value">Sistema / Personalizado</p>
            </div>
          </div>

          <!-- FOOTER: botones -->
          <div class="form-actions">
            <button class="secondary-button">Cancelar</button>
            <button class="primary-button"><Save/> Guardar Cambios</button>
          </div>
        </section>
      </div>
      ```

      Logica React: mismos patrones que `security-users-screen.tsx`:
      - `useState` para: query, isEditorOpen, form, menuId, activeTab, message, isPending
      - `useTransition` para submit
      - `useMemo` para filteredRoles
      - `useEffect` para cerrar menu al click fuera
      - `toast` de sonner para confirmacion/error
      - `useRouter` + `router.refresh()` despues de mutacion exitosa

- [x] **8.2** Contar usuarios y permisos por rol (client-side):
      - `data.users` ya esta en `SecurityManagerData`, calcular:
        `const userCountByRole = new Map<number, number>()` iterando `data.users`.
      - `data.rolePermissions` ya existe, calcular:
        `const permCountByRole = new Map<number, number>()` iterando `data.rolePermissions`.
      - Si `data.users` no esta disponible en el scope de roles, verificar
        `getSecurityManagerData()` en `pos-data.ts` y asegurar que el campo `users` se carga
        tambien cuando `section === "roles"`. Ajustar si es necesario.

- [x] **8.3** Validacion de eliminacion:
      - Si `userCountByRole.get(roleId) > 0`: toast error
        "No se puede eliminar un rol con usuarios asignados." y NO enviar DELETE.
      - Si tiene 0 usuarios: mostrar `window.confirm()` o modal de confirmacion antes de DELETE.
      - Roles de sistema (`isSystem`): deshabilitar boton eliminar (clase `.is-disabled`,
        `pointer-events: none; opacity: 0.5`).

- [x] **8.4** Actualizar `security-manager.tsx`:
      - Reemplazar el bloque `EntityCrudSection` de roles (lineas 32-42) por:
        `{visible.has("roles") ? <SecurityRolesScreen data={data} /> : null}`
      - Importar: `import { SecurityRolesScreen } from "./security-roles-screen"`

- [x] **8.5** CSS en `src/app/globals.css`: agregar AL FINAL del archivo (antes del ultimo `}`
      si hay media queries, o al final absoluto) las siguientes clases nuevas:

      ```css
      /* --- Roles Screen --- */
      .roles-toolbar { display: flex; align-items: center; gap: 0.6rem; }
      .roles-search { min-width: 16rem; }
      .roles-table-wrap { overflow-x: auto; overflow-y: visible; }
      .roles-table th:last-child,
      .roles-table td:last-child { text-align: center; }
      .roles-table .table-actions--menu { justify-content: center; }
      .roles-table .table-menu { left: auto; right: 0; top: calc(100% - 0.1rem); }
      .roles-table .table-menu.is-up { top: auto; bottom: calc(100% - 0.1rem); }

      .roles-name-cell { display: flex; align-items: center; gap: 0.75rem; }
      .roles-name-cell__icon {
        width: 2rem; height: 2rem; border-radius: 0.5rem;
        display: grid; place-items: center; color: #fff; flex-shrink: 0;
      }
      .roles-name-cell__badge { margin-left: 0.5rem; }

      .roles-stat-cell { display: inline-flex; align-items: center; gap: 0.4rem; color: var(--muted); }
      .roles-stat-cell span { color: var(--ink); }

      /* Roles Modal (clon de users-modal) */
      .roles-modal {
        width: min(38rem, 100%); max-height: calc(100vh - 6.4rem); overflow: auto;
        padding: 1.1rem; border-radius: 0.9rem; background: #eef3f9;
        border: 1px solid var(--line); box-shadow: 0 22px 44px rgba(16, 35, 61, 0.2);
      }
      .roles-modal__header {
        display: flex; align-items: flex-start; justify-content: space-between; gap: 0.75rem;
      }
      .roles-modal__identity { display: flex; align-items: center; gap: 0.7rem; }
      .roles-modal__identity h3 { margin: 0; font-size: 1.6rem; font-weight: 700; }
      .roles-modal__identity p { margin: 0.2rem 0 0; color: var(--muted); font-size: 0.92rem; }
      .roles-modal__header-actions { display: inline-flex; align-items: center; gap: 0.45rem; }

      .roles-modal__icon {
        width: 3rem; height: 3rem; border-radius: 0.6rem;
        display: grid; place-items: center; color: #fff; flex-shrink: 0;
      }

      /* Switch row (active toggle) */
      .roles-switch-row {
        display: flex; align-items: center; justify-content: space-between;
        padding: 1rem; border: 1px solid var(--line); border-radius: 0.72rem;
      }
      .roles-switch-row p:first-child { font-weight: 600; color: var(--ink); margin: 0; }
      .roles-switch-row p:last-child { font-size: 0.85rem; color: var(--muted); margin: 0.15rem 0 0; }

      /* Info grid (tab Informacion) */
      .roles-info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-top: 0.5rem; }
      .roles-info-card {
        padding: 1rem; border: 1px solid var(--line); border-radius: 0.72rem; background: transparent;
      }
      .roles-info-card__label {
        display: flex; align-items: center; gap: 0.4rem;
        font-size: 0.82rem; color: var(--muted); margin-bottom: 0.35rem;
      }
      .roles-info-card__value { margin: 0; font-weight: 600; color: var(--ink); }
      ```

      Estas clases son consistentes con los tokens de `globals.css`:
      - `var(--line)` para bordes (#d5deea)
      - `var(--muted)` para texto secundario (#61728d)
      - `var(--ink)` para texto principal (#10233d)
      - border-radius `0.72rem` / `0.9rem` del sistema existente
      - Sombra `0 22px 44px rgba(16,35,61,0.2)` del modal de usuarios

- [x] **8.6** Build: `npm run build` sin errores.

**Restricciones:**
- Reutilizar clases existentes: `data-panel`, `data-table`, `chip`, `primary-button`,
  `secondary-button`, `danger-button`, `searchbar`, `icon-button`, `table-menu`,
  `users-modal-backdrop`, `users-modal__tabs`, `users-tab`, `form-grid`, `form-actions`.
- Las clases NUEVAS usan prefijo `roles-` para evitar colisiones.
- NO usar Tailwind ni clases utilitarias â€” todo va en `globals.css` como CSS vanilla BEM.
- NO crear componentes abstractos â€” este es un componente dedicado para Roles.
- Mantener la API CRUD existente (`/api/admin/roles`), no crear endpoints nuevos.
- El tab "Informacion" es solo lectura (stats del rol). La asignacion de permisos se
  hace en la pantalla Roles-Permisos, no aqui.

---

## TAREA 9 â€” Bugfixes + QA Roles Screen

**Estado:** `COMPLETADA`

**Contexto:**
- Pantalla de roles creada en TAREA 8: `src/components/pos/security-roles-screen.tsx` (375 lineas).
- CSS en `src/app/globals.css` (clases `.roles-*`).
- Mismo bug de overflow de TAREA 7.0b afecta la tabla de roles: el menu contextual
  se corta y no muestra "Eliminar" en las filas del medio/final.

### Checkpoints

- [x] **9.1** BUG FIX: Menu contextual cortado en tabla de roles.
      Mismo problema que 7.0b: `.roles-table-wrap` tiene `overflow-x: auto` que fuerza
      `overflow-y: auto` por spec CSS, cortando el `.table-menu` posicionado con absolute.

      **Fix:** Aplicar la misma solucion que se uso en `.users-table-wrap` en TAREA 7.0b.
      Verificar como quedo `.users-table-wrap` despues del fix de 7.0b y replicar el
      mismo patron para `.roles-table-wrap`. Si la solucion fue `overflow: visible` con
      inner wrapper para scroll, hacer lo mismo aqui.

      Ademas subir `z-index` del `.table-menu` dentro de `.roles-table` si es necesario.

      Verificar que las 4 opciones se ven: Editar, Gestionar Permisos, separador, Eliminar.

- [x] **9.2** BUG FIX: En tab "Informacion", el campo "Fecha Creacion" muestra "No disponible".
      - Verificar si la tabla `Roles` en DB tiene columna de fecha de creacion
        (`FechaCreacion`, `CreatedAt`, o similar).
      - Si existe: mapear en `getSecurityManagerData()` de `pos-data.ts`, agregar al tipo
        `roles` y mostrar en el card de info.
      - Si NO existe: agregar columna `FechaCreacion DATETIME DEFAULT GETDATE()` a la tabla
        `Roles`, actualizar el SP `spRolesCRUD` accion L para incluirla en el SELECT,
        mapear en data layer y mostrar formateada en el card.
      - Tiene acceso completo a modificar la DB.

- [x] **9.3** i18n: Reemplazar textos hardcoded en `security-roles-screen.tsx` por claves
      de traduccion `useI18n()`.
      - Importar `useI18n` y obtener `t`.
      - Traducir: titulo, subtitulo, headers de tabla, labels del formulario, textos de
        botones, toasts, tabs, info cards.
      - Verificar que las claves existen en `src/lib/i18n.tsx`. Si no existen, agregarlas
        en ambos idiomas (es/en). Claves sugeridas con prefijo `roles.*`:
        `roles.title`, `roles.subtitle`, `roles.searchPlaceholder`, `roles.newRole`,
        `roles.name`, `roles.description`, `roles.activeToggle`, `roles.activeToggleDesc`,
        `roles.generalTab`, `roles.infoTab`, `roles.createdAt`, `roles.usersAssigned`,
        `roles.permissionsCount`, `roles.type`, `roles.system`, `roles.custom`,
        `roles.updated`, `roles.created`, `roles.deleted`, `roles.deleteConfirm`,
        `roles.cannotDeleteWithUsers`, `roles.nameRequired`.

- [x] **9.4** Validacion nombre duplicado: en `onSubmit`, antes de enviar, verificar
      client-side que no exista otro rol con el mismo nombre (case-insensitive).
      `data.roles.some(r => r.name.trim().toLowerCase() === form.name.trim().toLowerCase() && r.id !== form.id)`
      Si duplicado, mostrar mensaje y no enviar.

- [x] **9.5** UX: Al hacer click en una fila de la tabla (no solo en el menu), abrir el
      modal de edicion. Agregar `onClick={() => openEdit(role)}` al `<tr>` y
      `onClick={(e) => e.stopPropagation()}` al `<td>` de acciones para que el menu
      no dispare la edicion. Mismo patron que UI 3.0 (`cursor-pointer hover:bg-muted/50`).
      CSS: `.roles-table tbody tr { cursor: pointer; }` y
      `.roles-table tbody tr:hover { background: rgba(18,70,126,0.03); }`

- [x] **9.6** Build: `npm run build` sin errores.

- [x] **9.7** Paridad con users-screen â€” Tabs en modo nuevo:
      En `security-roles-screen.tsx`, ocultar los tabs cuando `!form.id` (rol nuevo).
      El tab "Informacion" no tiene datos utiles para un rol que aun no existe.
      Mismo patron que users-screen linea 457: `{form.id ? <div className="users-modal__tabs">...</div> : null}`
      Mostrar directamente el formulario General sin tabs cuando es nuevo.

- [x] **9.8** Paridad con users-screen â€” Boton Save en tab Informacion:
      Actualmente el boton "Guardar Cambios" en el tab Info ejecuta
      `onClick={() => setActiveTab("general")}` (cambia de tab, no guarda nada).
      Esto es confuso. Cambiar a `onClick={closeEditor}` igual que en users-screen
      tab Activity (linea 596). El boton debe cerrar el modal, no cambiar de tab.

- [x] **9.9** Paridad con users-screen â€” Menu is-up en ultimas 2 filas:
      Cambiar la condicion del menu `is-up` de `index === roles.length - 1` (solo
      ultima fila) a `index >= roles.length - 2` (ultimas 2 filas). Esto evita que
      el menu se corte por el borde inferior del panel cuando hay pocas filas.

- [x] **9.10** Paridad con users-screen â€” Hover CSS en filas:
      Verificar que existen estas reglas CSS en `globals.css`:
      ```css
      .roles-table tbody tr { cursor: pointer; }
      .roles-table tbody tr:hover { background: rgba(18,70,126,0.03); }
      ```
      Si no existen, agregarlas. Si ya existen (de 9.5), verificar que funcionan.

- [x] **9.11** Build: `npm run build` sin errores.

**Restricciones:**
- NO cambiar la API ni crear endpoints nuevos.
- Reutilizar patrones CSS y React existentes de users-screen.
- Referencia directa: `src/components/pos/security-users-screen.tsx` (607 lineas).

---

## TAREA 10 â€” Pagina Independiente de Roles (sin tabs de seguridad)

**Estado:** `COMPLETADA`

**Contexto:**
- Actualmente `/config/security/roles/page.tsx` delega a `SecurityConfigScreen` que renderiza
  un header "Configuracion Â· Seguridad", tabs de navegacion (Usuarios, Roles, Modulos, Pantallas,
  Permisos, Roles y Permisos) y luego el `SecurityManager` que renderiza `SecurityRolesScreen`.
- La referencia visual UI 3.0 (`D:\Masu\UI 3.0\app\config\security\roles\page.tsx`) es una pagina
  independiente con header "Roles" + subtitulo + boton "+ Nuevo Rol", sin tabs de navegacion.
- La pantalla de Usuarios (`/config/security/users`) ya deberia seguir el mismo patron
  independiente (verificar y aplicar si es necesario).

**Objetivo:** Hacer que `/config/security/roles` sea una pagina independiente con su propio
`PageHeader` y sin los tabs de navegacion de `SecurityConfigScreen`. Igual para Usuarios.

### Checkpoints

- [x] **10.1** Reescribir `src/app/config/security/roles/page.tsx`:
      - NO usar `SecurityConfigScreen`. Renderizar directamente:
        ```tsx
        import { AppShell } from "@/components/pos/app-shell"
        import { PageHeader } from "@/components/pos/page-header"
        import { SecurityRolesScreen } from "@/components/pos/security-roles-screen"
        import { getSecurityManagerData } from "@/lib/pos-data"

        export const dynamic = "force-dynamic"

        export default async function SecurityRolesPage() {
          const data = await getSecurityManagerData()
          return (
            <AppShell>
              <section className="content-page">
                <PageHeader title="Roles" description="Configura los roles disponibles">
                  {/* El boton "+ Nuevo Rol" ya esta dentro de SecurityRolesScreen */}
                </PageHeader>
                <SecurityRolesScreen data={data} />
              </section>
            </AppShell>
          )
        }
        ```
      - SIN tabs de navegacion. SIN header "Configuracion Â· Seguridad".

- [x] **10.2** Ajustar `SecurityRolesScreen` para evitar duplicacion de header:
      - Actualmente el componente tiene su propio header interno con titulo "Gestion de Roles",
        subtitulo, buscador y boton "+ Nuevo Rol" dentro del `.data-panel`.
      - Decidir: **Opcion A** mover el boton "+ Nuevo Rol" al `PageHeader` como `action` y
        quitar el header interno del data-panel. **Opcion B** mantener el data-panel con su
        header interno y usar el `PageHeader` solo como titulo de pagina (sin accion).
      - **Elegir Opcion B** (es mas simple y consistente con UI 3.0 donde el PageHeader tiene
        titulo+subtitulo+boton Y ademas el card tiene su propio titulo "Gestion de Roles").
      - Solo asegurar que no se duplique el boton â€” el boton debe estar en UN solo lugar.
        Si PageHeader tiene el boton, quitarlo del data-panel. Si data-panel lo tiene,
        no ponerlo en PageHeader.

- [x] **10.3** Misma transformacion para Usuarios:
      Reescribir `src/app/config/security/users/page.tsx` con el mismo patron:
      ```tsx
      import { AppShell } from "@/components/pos/app-shell"
      import { PageHeader } from "@/components/pos/page-header"
      import { SecurityUsersScreen } from "@/components/pos/security-users-screen"
      import { getSecurityManagerData } from "@/lib/pos-data"

      export const dynamic = "force-dynamic"

      export default async function SecurityUsersPage() {
        const data = await getSecurityManagerData()
        return (
          <AppShell>
            <section className="content-page">
              <PageHeader title="Usuarios" description="Administra cuentas y acceso al sistema" />
              <SecurityUsersScreen data={data} />
            </section>
          </AppShell>
        )
      }
      ```
      SIN tabs de navegacion. SIN header "Configuracion Â· Seguridad".

- [x] **10.4** Las demas paginas de seguridad (Modulos, Pantallas, Permisos, Roles-Permisos)
      SIGUEN usando `SecurityConfigScreen` con tabs por ahora â€” no cambiarlas.
      Solo Usuarios y Roles se independizan.

- [x] **10.5** Verificar que la navegacion del menu lateral/topbar sigue funcionando
      correctamente para llegar a Usuarios y Roles. Los links en `app-shell.tsx` ya
      apuntan a `/config/security/users` y `/config/security/roles` directamente.

- [x] **10.6** Build: `npm run build` sin errores.

**Restricciones:**
- NO eliminar `SecurityConfigScreen` â€” sigue siendo usada por Modulos, Pantallas, Permisos, Roles-Permisos.
- NO eliminar `SecurityManager` â€” sigue siendo usada por las pantallas que usan `EntityCrudSection`.
- NO crear endpoints nuevos.
- El boton de accion principal (Nuevo Rol / Nuevo Usuario) debe aparecer en UN solo lugar,
  no duplicado entre PageHeader y data-panel.

---

## TAREA 11 â€” Rediseno Roles: 3 Paneles con Permisos Granulares

**Estado:** `COMPLETADA`

**Contexto:**
- Diseno de referencia completo: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`
  (1,052 lineas, Tailwind/shadcn). HAY QUE TRADUCIR a CSS vanilla BEM de V2.
- Reemplaza completamente `src/components/pos/security-roles-screen.tsx` actual (375 lineas,
  tabla simple con modal).
- Datos existentes en V2 que se reutilizan:
  - `modules`: id, name, icon, order, active
  - `screens`: id, moduleId, name, route, icon, order, active
  - `permissions`: id, screenId, name, canView, canCreate, canEdit, canDelete, canApprove,
    canCancel, canPrint, active
  - `rolePermissions`: id, roleId, permissionId, active (junction table)
- Dato NUEVO que no existe: **Field Visibility** por rol (tabla nueva en DB).
- Acceso completo a modificar la base de datos.

**Objetivo:** Reescribir la pantalla de Roles como un sistema de 3 paneles con gestion
de permisos granulares, siguiendo el diseno de UI 3.0/Roles.

### Fase A â€” Data Layer (DB + API)

- [x] **11.1** DB: Crear tabla `RolCamposVisibilidad` para field visibility por rol:
      ```sql
      CREATE TABLE dbo.RolCamposVisibilidad (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        IdRol INT NOT NULL REFERENCES dbo.Roles(IdRol),
        ClaveCampo NVARCHAR(50) NOT NULL,  -- ej: 'precios', 'costos', 'impuestos'
        Visible BIT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_RolCampo UNIQUE (IdRol, ClaveCampo)
      );
      ```
      Insertar campos iniciales para el rol Admin con todos visibles.
      Campos: `id_registros`, `precios`, `costos`, `cantidades`, `descuentos`,
      `impuestos`, `subtotales`, `totales_netos`, `margenes`, `comisiones`,
      `info_cliente`, `metodos_pago`.

- [x] **11.2** DB: Crear SP `spRolPermisosPorModulo` que recibe `@IdRol INT` y retorna:
      - Resultset 1: Modulos con flag `Habilitado` (1 si el rol tiene al menos 1 permiso
        activo en alguna pantalla del modulo, 0 si no).
      - Resultset 2: Pantallas con sus permisos granulares para ese rol
        (access, canCreate, canEdit, canDelete, canView, canApprove, canCancel, canPrint).
      - Resultset 3: Campos de visibilidad del rol (de `RolCamposVisibilidad`).

- [x] **11.3** DB: Crear SP `spRolPermisosActualizar` que recibe `@IdRol INT`, `@Tipo`
      (MODULO/PANTALLA/CAMPO), `@IdObjeto INT o @ClaveCampo NVARCHAR(50)`, `@Valor BIT`,
      y `@CampoPermiso NVARCHAR(50) = NULL` (para permisos granulares: canCreate, canEdit, etc).
      - Tipo MODULO: habilitar/deshabilitar TODOS los permisos de TODAS las pantallas del modulo.
      - Tipo PANTALLA: habilitar/deshabilitar acceso a una pantalla (toggle access).
      - Tipo PERMISO_GRANULAR: actualizar un permiso especifico (canCreate, canEdit, etc.) de una pantalla.
      - Tipo CAMPO: actualizar visibilidad de un campo en `RolCamposVisibilidad`.

- [x] **11.4** DB: Crear SP `spRolUsuariosAsignar` que recibe `@IdRol INT`, `@IdUsuario INT`,
      `@Accion CHAR(1)` ('A' = asignar, 'Q' = quitar).
      - Accion A: UPDATE Usuarios SET IdRol = @IdRol WHERE IdUsuario = @IdUsuario.
      - Accion Q: UPDATE Usuarios SET IdRol = NULL (o rol default) WHERE IdUsuario = @IdUsuario.

- [x] **11.5** API: Crear endpoint `GET /api/roles/[id]/permissions` que llama a
      `spRolPermisosPorModulo` y retorna:
      ```json
      {
        "ok": true,
        "modules": [{ "id": 1, "name": "Dashboard", "icon": "LayoutGrid", "enabled": true, "screens": [...] }],
        "screens": [{ "id": 1, "moduleId": 1, "name": "Panel Principal", "access": true, "canCreate": true, ... }],
        "fieldVisibility": { "precios": true, "costos": false, ... }
      }
      ```

- [x] **11.6** API: Crear endpoint `PUT /api/roles/[id]/permissions` que recibe el tipo
      de actualizacion y llama a `spRolPermisosActualizar`.

- [x] **11.7** API: Crear endpoint `PUT /api/roles/[id]/users` que recibe `userId` y `action`
      y llama a `spRolUsuariosAsignar`.

- [x] **11.8** Build: `npm run build` sin errores.

### Fase B â€” Componente UI: Layout 3 Paneles

- [x] **11.9** Crear nuevo `src/components/pos/security-roles-screen.tsx` (reescritura completa).
      Referencia: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.

      **LAYOUT 3 PANELES** â€” estructura CSS:
      ```css
      .roles-layout { display: flex; gap: 1rem; min-height: calc(100vh - 10rem); }
      .roles-sidebar { width: 18rem; flex-shrink: 0; }
      .roles-main { flex: 1; min-width: 0; }
      .roles-users-panel { width: 16rem; flex-shrink: 0; }
      ```

      **PANEL IZQUIERDO (`.roles-sidebar`):**
      - Header: titulo "Roles" + boton "+ Nuevo Rol" (abre dialog/modal de creacion)
      - Buscador de roles
      - Lista scrollable de roles, cada item muestra:
        - Icono Shield coloreado + nombre + badge "Sistema"
        - Descripcion (1 linea truncada)
        - Stats: icono Users + count, icono Key + count modulos
      - Item seleccionado: borde izquierdo azul + fondo primario tenue
      - Hover: fondo muted
      - Auto-seleccionar primer rol al cargar

      **PANEL CENTRAL (`.roles-main`):**
      - **Cabecera**: icono Shield grande + nombre del rol + descripcion
        - Boton "Editar Datos" (toggle `isEditing`)
        - Menu 3 puntos con opcion Eliminar (deshabilitado para sistema)
        - Fila info: codigo (badge mono), estado (switch), badge sistema
        - Filtro: select "Todos / Solo habilitados / Solo no habilitados"
      - **3 Tabs**: Modulos | Pantallas | Visualizacion

      **PANEL DERECHO (`.roles-users-panel`):**
      - 2 tabs: "Asignados" (con count) | "Disponibles" (con count)
      - Lista compacta: avatar inicial + nombre + boton asignar/quitar
      - Botones deshabilitados si `!isEditing`

- [x] **11.10** Tab Modulos:
      - Grid de cards (2 cols desktop, 1 col mobile)
      - Cada card: icono modulo + codigo + nombre + "X pantallas" + switch toggle
      - Card habilitada: fondo primario tenue + borde primario
      - Card deshabilitada: fondo neutro + borde gris
      - Al habilitar: mostrar lista de pantallas incluidas como badges
      - Seccion resumen: "X de Y modulos habilitados"
      - Botones "Habilitar todos" / "Deshabilitar todos" (solo si `isEditing`)
      - Fetch data desde `GET /api/roles/[id]/permissions`
      - Update via `PUT /api/roles/[id]/permissions` con tipo MODULO

- [x] **11.11** Tab Pantallas:
      - Collapsibles por modulo (expandir/colapsar con chevron)
      - Header modulo: icono + nombre + count pantallas + badge habilitado/deshabilitado
      - Cada pantalla:
        - Switch de acceso + nombre + badge con count permisos activos
        - Grid de 7 permisos granulares (solo si acceso habilitado):
          Agregar (Plus), Editar (Pencil), Borrar (Trash2), Copiar (Copy),
          Filtrar (Filter), Sortear (ArrowUpDown), Exportar (Download)
        - Cada permiso: icono + label + mini switch
        - Fondo primario si activo, muted si inactivo
      - Modulos expandidos por defecto
      - Update via `PUT /api/roles/[id]/permissions` con tipo PANTALLA o PERMISO_GRANULAR

- [x] **11.12** Tab Visualizacion:
      - Card info arriba: "Controla que campos puede visualizar este rol..."
      - Grid de 12 campos (2 cols):
        - Cada card: icono Eye/EyeOff + nombre campo + switch
        - Visible: fondo verde tenue + borde verde + icono Eye verde
        - Oculto: fondo rojo tenue + borde rojo + icono EyeOff rojo
      - Resumen: "X visibles" (punto verde) + "X ocultos" (punto rojo)
      - Botones "Mostrar todos" / "Ocultar todos" (solo si `isEditing`)
      - Update via `PUT /api/roles/[id]/permissions` con tipo CAMPO

- [x] **11.13** Panel Usuarios (derecho):
      - Tab "Asignados": listar `data.users.filter(u => u.roleId === selectedRole.id)`
        con boton rojo UserMinus para quitar
      - Tab "Disponibles": listar `data.users.filter(u => u.roleId !== selectedRole.id)`
        con boton verde UserPlus para asignar
      - Accion via `PUT /api/roles/[id]/users`
      - Toast de confirmacion al asignar/quitar
      - Botones deshabilitados si `!isEditing`

### Fase C â€” CSS + Polish

- [x] **11.14** CSS en `globals.css`: agregar todas las clases nuevas con prefijo `roles-`.
      Traducir los estilos de Tailwind del archivo de referencia a CSS vanilla.
      Clases clave:
      - `.roles-layout`, `.roles-sidebar`, `.roles-main`, `.roles-users-panel`
      - `.roles-sidebar__item`, `.roles-sidebar__item.is-selected`
      - `.roles-header`, `.roles-header__icon`, `.roles-header__info`
      - `.roles-module-grid`, `.roles-module-card`, `.roles-module-card.is-enabled`
      - `.roles-screen-collapsible`, `.roles-screen-card`, `.roles-perm-grid`, `.roles-perm-item`
      - `.roles-field-grid`, `.roles-field-card`, `.roles-field-card.is-visible`, `.roles-field-card.is-hidden`
      - `.roles-users-list`, `.roles-user-item`, `.roles-user-avatar`
      Usar tokens existentes: `var(--brand)`, `var(--line)`, `var(--muted)`, `var(--ink)`,
      `var(--success-bg)`, `var(--success-text)`, `var(--rose-bg)`, `var(--rose-text)`.

- [x] **11.15** i18n: agregar todas las claves de traduccion necesarias en `src/lib/i18n.tsx`.
      Prefijo `roles.*` para claves nuevas del sistema de 3 paneles.

- [x] **11.16** Build: `npm run build` sin errores.

**Restricciones:**
- TODO el CSS debe ser vanilla BEM en `globals.css` â€” NO Tailwind.
- Referencia visual: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.
- Reutilizar tokens CSS existentes y patrones de componentes de V2.
- Los permisos granulares de pantalla deben mapearse a las columnas existentes de la tabla
  `Permisos`: canView, canCreate, canEdit, canDelete, canApprove, canCancel, canPrint.
  Mapeo a los 7 de UI 3.0: Agregar=canCreate, Editar=canEdit, Borrar=canDelete,
  Copiar=canApprove (reutilizar), Filtrar=canView (reutilizar), Sortear=canCancel (reutilizar),
  Exportar=canPrint (reutilizar). O agregar columnas nuevas si se prefiere.
- Patron "Editar Datos": toda la UI empieza en modo lectura, se habilita al presionar el boton.
- Acceso completo a DB para crear tablas, SPs, y alterar estructuras existentes.

---

## TAREA 12 â€” Roles 3 Paneles: Fixes Visuales y Funcionales

**Estado:** `COMPLETADA`

**Contexto:**
- Pantalla de 3 paneles creada en TAREA 11: `src/components/pos/security-roles-screen.tsx` (930 lineas).
- CSS en `src/app/globals.css` (clases `.roles-*`).
- Referencia visual: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.
- El usuario reporto 5 issues tras probar en browser.

### Checkpoints

- [x] **12.1** FIX: Cards de modulos ocupan todo el ancho (se ve feo con 1 solo modulo).
      **Problema:** Cuando hay pocos modulos (ej: solo "Seguridad"), la card ocupa todo el
      ancho del grid porque el grid es 2 cols y hay 1 sola card.
      **Fix:**
      - Cambiar `.roles-module-grid` a `grid-template-columns: repeat(3, minmax(0, 1fr))`
        para 3 columnas en desktop (como UI 3.0: `grid-cols-2 lg:grid-cols-3`).
      - Asi una sola card ocupa ~33% del ancho, no 50% ni 100%.
      - Verificar media query en linea ~3579: en mobile mantener 1 col, en tablet 2 cols.
      - Ademas: las cards deben tener un `max-width` o un tamano fijo para que no se
        estiren demasiado. Revisar `.roles-module-card` y agregar proporcion adecuada.

- [x] **12.2** FIX: Boton "Nuevo Rol" desproporcionado y mal ubicado.
      **Problema:** En el panel izquierdo el boton "Nuevo Rol" esta grande y desproporcionado.
      Segun la referencia UI 3.0, deberia ser un boton pequeno en la esquina superior derecha
      del panel izquierdo, al lado del titulo "Roles" (o "Gestion de Roles").
      **Fix:**
      - En `.roles-sidebar__header`, el boton debe ser compacto:
        `padding: 0.45rem 0.75rem; font-size: 0.82rem; border-radius: 0.6rem;`
      - Verificar que no tiene padding excesivo del `.primary-button` base.
      - El layout del header debe ser: `titulo a la izquierda | boton pequeno a la derecha`.
      - Tambien se puede usar un boton icono `+` si el espacio es muy limitado.

- [x] **12.3** FIX: Desproporcion general en los 3 paneles.
      **Problema:** Los paneles no tienen las proporciones correctas comparado con UI 3.0.
      **Fix en `globals.css`:**
      - Panel izquierdo: `18rem` esta bien pero necesita padding interno consistente.
        Los items de la lista necesitan mas espacio vertical y menos apretados.
      - Panel central: es `minmax(0, 1fr)` OK, pero el contenido interno (cabecera,
        tabs, area de modulos) necesita mejor spacing.
      - Panel derecho: `16rem` puede ser poco. Cambiarlo a `17rem` o `18rem` para que
        los nombres de usuario + username no se corten.
      - Verificar que `.roles-sidebar`, `.roles-main`, `.roles-users-panel` tienen
        `background`, `border`, `border-radius` y `padding` consistentes con el diseno
        (cards con fondo blanco, borde sutil, border-radius `var(--radius-lg)` o `0.9rem`).
      - Referencia: en UI 3.0 cada panel es un `Card` con fondo blanco, sombra suave.

- [x] **12.4** FIX: Selector de filtro no va acorde al estilo moderno.
      **Problema:** El `<select>` nativo de HTML para "Todos/Habilitados/No habilitados" se
      ve fuera de lugar en el diseno moderno.
      **Fix:**
      - Reemplazar el `<select>` por un grupo de botones pill (como los tabs):
        3 botones: "Todos" | "Habilitados" | "No habilitados"
      - Reutilizar las clases `.users-tab` / `.users-modal__tabs` o crear nuevas:
        `.roles-filter-pills` (contenedor) + `.roles-filter-pill` (cada boton)
        + `.roles-filter-pill.is-active` (seleccionado).
      - CSS: mismas propiedades que `.users-tab` (padding, border-radius: 999px,
        font-size, font-weight, background al activo).
      - O como alternativa: usar un custom dropdown con las clases existentes de
        `.table-menu` como referencia visual.

- [x] **12.5** FIX: Boton asignar/quitar usuarios necesita SP funcional.
      **Problema:** Los botones de asignar/quitar usuarios en el panel derecho pueden no
      estar conectados al backend correctamente.
      **Fix:**
      - Verificar que el SP `spRolUsuariosAsignar` fue creado en la DB (TAREA 11.4).
        Si no existe, crearlo:
        ```sql
        CREATE PROCEDURE dbo.spRolUsuariosAsignar
          @IdRol INT,
          @IdUsuario INT,
          @Accion CHAR(1)  -- 'A' = asignar, 'Q' = quitar
        AS
        BEGIN
          IF @Accion = 'A'
            UPDATE dbo.Usuarios SET IdRol = @IdRol WHERE IdUsuario = @IdUsuario;
          ELSE IF @Accion = 'Q'
            UPDATE dbo.Usuarios SET IdRol = 1 WHERE IdUsuario = @IdUsuario;  -- rol default
        END
        ```
      - Verificar que el endpoint `PUT /api/roles/[id]/users` existe y llama al SP.
      - Verificar que el boton en el componente llama al endpoint con el `userId` y `action` correctos.
      - Verificar que despues de asignar/quitar, la lista se actualiza (refresh o state update).
      - Toast de confirmacion al completar la accion.
      - Tiene acceso completo a modificar la DB.

- [x] **12.6** Build: `npm run build` sin errores.

**Restricciones:**
- CSS vanilla BEM en `globals.css` â€” NO Tailwind.
- Referencia visual: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.
- Acceso completo a DB.

---

## TAREA 13 â€” Roles: Fixes Layout, Espacio y Error SP

**Estado:** `COMPLETADA`

**Contexto:**
- Screenshot real de V2 muestra 3 problemas persistentes tras TAREA 12.
- Componente: `src/components/pos/security-roles-screen.tsx` (930 lineas).
- CSS: `src/app/globals.css` (clases `.roles-*`).
- Referencia visual: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.

### Checkpoints

- [x] **13.1** FIX: Sidebar izquierdo â€” rol card ocupa todo el alto.
      **Problema:** Cuando hay 1 solo rol (Administrador), la card se estira y ocupa todo
      el alto disponible del sidebar. Hay demasiado espacio vacio entre la descripcion
      y los stats (usuarios/modulos) en la parte inferior.
      **Fix CSS:**
      - La card `.roles-sidebar__item` NO debe crecer verticalmente.
        Agregar `align-self: start;` o `height: auto;` para que solo ocupe lo necesario.
      - La lista `.roles-sidebar__list` NO debe usar `grid` con stretch implÃ­cito.
        Cambiar a: `display: flex; flex-direction: column; gap: 0.55rem; align-items: stretch;`
        y asegurar que los items no se estiran en alto.
      - Cada item debe tener un alto fijo/natural basado en su contenido, no estirarse.
      - Referencia UI 3.0: los items son compactos (~4-5rem de alto), uno debajo del otro,
        sin estirarse.

- [x] **13.2** FIX: Panel central â€” "1/1 modulos habilitados" con demasiado espacio.
      **Problema:** El resumen "1 / 1 modulos habilitados" esta arriba del area de cards
      y hay un hueco enorme entre ese texto y la card de "Seguridad".
      **Fix:**
      - El resumen debe ir AL FINAL del area de modulos (debajo de las cards), no arriba.
        En UI 3.0 el resumen esta abajo: `<div class="roles-module-summary">`.
      - Mover el `<div>` del resumen DESPUES del grid de cards en el componente.
      - Las cards de modulos deben estar arriba, el resumen abajo.
      - Ademas: el area de contenido del tab no debe tener `flex-grow` ni estirarse â€”
        debe empezar desde arriba y fluir naturalmente hacia abajo.

- [x] **13.3** FIX: Card de modulo â€” sigue siendo 1 sola card que se ve grande.
      **Problema:** Con 1 solo modulo "Seguridad", la card ocupa mucho espacio.
      El grid deberia mostrar la card con un tamano compacto, no llenar todo el ancho.
      **Fix CSS:**
      - `.roles-module-grid` debe mantener `grid-template-columns: repeat(3, minmax(0, 1fr))`
        asi la card de 1 solo modulo ocupa 1/3 del ancho.
      - Verificar que el media query NO esta sobreescribiendo a `1fr` en desktop.
        El media query `1fr` solo debe aplicar en pantallas < 640px.
      - `.roles-module-card` debe tener `max-width: none` y dejar que el grid controle.
      - Verificar en `globals.css` que no hay un override que fuerce 1 columna.

- [x] **13.4** BUG: Error de validacion en SP.
      **Problema:** Aparece error rojo:
      `Validation failed for parameter 'Nombre'. parameter.type.validate is not a function`
      Esto es un error de `mssql` (node-mssql) al pasar un parametro con tipo incorrecto.
      **Fix:**
      - Buscar en `pos-data.ts` o en los archivos de API donde se llama al SP que recibe
        `@Nombre` â€” probablemente `spRolesCRUD` o `spRolPermisosActualizar`.
      - El error indica que `.input("Nombre", value)` no tiene tipo especificado o tiene
        un tipo invalido. Debe ser: `.input("Nombre", sql.NVarChar, value)`.
      - Buscar TODOS los `.input(` en los archivos de API/data-layer relacionados con roles
        y verificar que tienen el tipo SQL correcto como segundo parametro.
      - Import de `sql` desde `mssql`: `import sql from "mssql"`.
      - Tiene acceso completo a modificar la DB y codigo.

- [x] **13.5** Boton "Nuevo Rol" â€” sigue grande.
      **Problema:** El boton "Nuevo Rol" en el sidebar sigue siendo demasiado grande.
      En UI 3.0 es un circulo pequeno azul con icono `+` (sin texto).
      **Fix:**
      - Reemplazar el boton rectangular "Nuevo Rol" por un boton circular solo con `+`:
        ```html
        <button class="roles-sidebar__add-btn" onClick={openNewRoleDialog}>
          <Plus size={16} />
        </button>
        ```
      - CSS: `.roles-sidebar__add-btn`:
        `width: 2rem; height: 2rem; border-radius: 999px; background: var(--brand);
        color: #fff; display: grid; place-items: center; border: none; cursor: pointer;`
      - Al hacer hover: `background: var(--brand-strong);`
      - Title tooltip: `title="Nuevo Rol"`

- [x] **13.6** Build: `npm run build` sin errores.

**Restricciones:**
- CSS vanilla BEM en `globals.css` â€” NO Tailwind.
- Referencia visual: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.
- Acceso completo a DB y codigo.

---

## TAREA 14 â€” Roles: UX Edicion + Modulos Data-Driven via SP

**Estado:** `COMPLETADA`

**Contexto:**
- Screenshot real de V2 muestra que el header del rol tiene inputs editables SIEMPRE,
  incluso en "Modo Lectura". Debe ser texto plano en lectura, inputs solo al editar.
- El boton "Guardar Cambios" aparece como elemento separado en la fila de info.
  Debe reemplazar al boton "Editar Datos" en el mismo lugar.
- Solo hay 1 modulo "Seguridad" con 3 pantallas. El sistema debe mostrar TODOS los modulos
  y pantallas definidos en DB. La estructura de modulos/pantallas debe ser data-driven
  para que agregar nuevos modulos sea solo un INSERT en DB, sin tocar frontend.
- Referencia visual: `D:\Masu\UI 3.0\Roles\app\config\security\roles\page.tsx`.
- Acceso completo a DB.

### Checkpoints

- [x] **14.1** FIX UX: Header del rol â€” Modo Lectura vs Modo Edicion.
      **Problema:** El nombre y descripcion del rol se muestran como `<input>` y `<textarea>`
      siempre, incluso cuando `isEditing === false`.
      **Fix en `security-roles-screen.tsx`:**
      - En el header del panel central, cuando `!isEditing`:
        Mostrar nombre como `<h2>` y descripcion como `<p>` (texto plano, no editable).
      - Cuando `isEditing`:
        Mostrar nombre como `<input>` y descripcion como `<textarea>` (editables).
      - Patron:
        ```jsx
        {isEditing ? (
          <input value={editForm.name} onChange={...} />
        ) : (
          <h2>{selectedRole.name}</h2>
        )}
        ```
      - Lo mismo para la descripcion.

- [x] **14.2** FIX UX: Boton Editar/Guardar en el mismo espacio.
      **Problema:** "Guardar Cambios" aparece como boton separado en la fila de info/filtros.
      Deberia reemplazar al boton "Editar Datos" / "Modo Lectura" en la esquina superior derecha.
      **Fix:**
      - En el header (esquina superior derecha), renderizar UN solo boton condicional:
        ```jsx
        {isEditing ? (
          <>
            <button class="secondary-button" onClick={cancelEdit}>Cancelar</button>
            <button class="primary-button" onClick={saveChanges}>
              {saving ? <Loader2 class="spin"/> : <Save/>} Guardar
            </button>
          </>
        ) : (
          <button class="secondary-button" onClick={() => setIsEditing(true)}>
            <Pencil/> Editar Datos
          </button>
        )}
        ```
      - Eliminar el boton "Guardar Cambios" de cualquier otro lugar donde aparezca
        (la fila de info, el area de modulos, etc.).
      - El menu "..." (3 puntos) siempre visible al lado del boton.

- [x] **14.3** DB: Seed de modulos y pantallas completos.
      **Principio:** La estructura de modulos/pantallas/permisos debe ser data-driven.
      Agregar un nuevo modulo al sistema debe ser solo un INSERT en DB, sin cambios en frontend.

      **Verificar y poblar la tabla `Modulos` con TODOS los modulos del sistema:**
      ```
      ID | Codigo | Nombre          | Icono
      1  | 10     | Dashboard       | LayoutGrid
      2  | 20     | Ordenes         | ShoppingCart
      3  | 30     | Punto de Venta  | Monitor
      4  | 40     | Menu/Catalogo   | Package
      5  | 50     | Reportes        | BarChart3
      6  | 60     | Configuracion   | Settings
      ```
      (Verificar IDs reales en DB y ajustar. Si ya existen algunos, solo insertar los faltantes.)

      **Verificar y poblar la tabla `Pantallas` con las pantallas de cada modulo:**
      ```
      Modulo Dashboard:   Panel Principal, Analiticas
      Modulo Ordenes:     Lista de Ordenes, Nueva Orden, Pantalla Cocina
      Modulo POS:         Terminal POS, Pagos, Caja
      Modulo Catalogo:    Productos, Categorias, Modificadores
      Modulo Reportes:    Ventas, Inventario, Personal
      Modulo Config:      Empresa, Usuarios, Roles, Catalogo
      ```
      (Verificar pantallas existentes y solo insertar las faltantes.)

      **Para cada pantalla, verificar que existe al menos 1 registro en tabla `Permisos`**
      con los flags granulares (canView, canCreate, canEdit, canDelete, etc.).
      Si no existe, insertar un permiso default con todos los flags en 0.

- [x] **14.4** SP: Verificar que `spRolPermisosPorModulo` retorna TODOS los modulos y pantallas.
      **Problema:** Actualmente solo retorna "Seguridad" con 3 pantallas porque es el unico
      modulo con permisos asignados al rol Administrador.
      **Fix:**
      - El SP debe retornar TODOS los modulos activos de la tabla `Modulos`, no solo los
        que tienen permisos. Para modulos sin permisos asignados al rol, retornar `Habilitado = 0`.
      - LEFT JOIN desde `Modulos` hacia las tablas de permisos/rolePermisos.
      - Lo mismo para pantallas: retornar TODAS las pantallas activas, con sus permisos
        del rol (si existen) o flags en 0 si no tiene permisos asignados.
      - Verificar el SP actual y hacer ALTER PROCEDURE si es necesario.
      - El frontend NO debe filtrar ni hardcodear modulos â€” solo renderizar lo que viene del SP.

- [x] **14.5** Frontend: Verificar que el componente renderiza los modulos del API.
      En `security-roles-screen.tsx`, verificar que:
      - Los modulos se obtienen del endpoint `GET /api/roles/[id]/permissions`.
      - NO hay lista hardcodeada de modulos en el frontend.
      - El grid de modulos renderiza `modules.map(...)` con los datos del API.
      - Las pantallas en el tab "Pantallas" vienen del mismo endpoint.
      - Los iconos de modulos se mapean por nombre o por campo `icon` de la DB.
        Si la DB tiene un campo `Icono` en la tabla `Modulos`, usarlo. Si no, crear
        un mapa de fallback `{ Dashboard: LayoutGrid, Ordenes: ShoppingCart, ... }`
        pero que sea extensible.

- [x] **14.6** Estilo moderno para cards de modulos.
      **Problema:** La card de modulo se ve basica/fea comparada con UI 3.0.
      **Fix CSS** â€” la card `.roles-module-card` debe tener:
      - Cuando habilitada: fondo `rgba(18,70,126,0.04)`, borde `1px solid rgba(18,70,126,0.2)`,
        border-radius `0.75rem`, padding `1rem`, shadow sutil.
      - Cuando deshabilitada: fondo `var(--panel)`, borde `1px solid var(--line)`,
        sin shadow, opacidad sutil en el contenido.
      - El icono del modulo debe estar en un cuadrado coloreado (como en UI 3.0):
        `width: 2.5rem; height: 2.5rem; border-radius: 0.6rem; background: rgba(18,70,126,0.1);
        color: var(--brand); display: grid; place-items: center;`
      - El switch toggle a la derecha, alineado con el nombre.
      - Las pantallas incluidas como badges compactos debajo.
      - El badge "Habilitado" al lado del nombre en color primario.
      - Referencia exacta: ver card de "Dashboard" en la screenshot de UI 3.0.

- [x] **14.7** Build: `npm run build` sin errores.

**Restricciones:**
- CSS vanilla BEM en `globals.css` â€” NO Tailwind.
- El principio clave es: **agregar modulos/pantallas = INSERT en DB, NO cambios en frontend**.
- El frontend renderiza lo que viene del SP/API, sin listas hardcodeadas.
- Acceso completo a DB.

---

## TAREA 15 â€” Limpieza Menu: Quitar Permisos y Roles-Permisos

**Estado:** `COMPLETADA`

**Contexto:**
- La pantalla de Roles ahora unifica la gestion de permisos (modulos, pantallas, permisos
  granulares, visibilidad de campos, asignacion de usuarios) en una sola interfaz de 3 paneles.
- Las pantallas independientes "Permisos" y "Roles y Permisos" ya no son necesarias.
- Hay que quitarlas del menu de navegacion y de las rutas protegidas.

### Checkpoints

- [x] **15.1** Menu: En `src/components/pos/app-shell.tsx`, quitar del array `configSecurity`
      los items con href:
      - `/config/security/permissions`
      - `/config/security/roles-permissions`
      Mantener: Users, Roles, Modules, Screens.

- [x] **15.2** Permisos en `src/lib/permissions.ts`: quitar de `ROUTE_PERMISSIONS` las entradas:
      - `config.security.permissions.view`
      - `config.security.roles-permissions.view`
      Para que el middleware no las requiera.

- [x] **15.3** Las rutas/archivos de pagina se pueden mantener (no rompen nada) pero ya no
      son accesibles desde el menu. Si se quiere limpiar, eliminar:
      - `src/app/config/security/permissions/page.tsx`
      - `src/app/config/security/roles-permissions/page.tsx`
      Opcional â€” marcar como hecho si se decide mantenerlos como legacy. (Se mantienen como legacy.)

- [x] **15.4** Build: `npm run build` sin errores.

**Restricciones:**
- NO eliminar los SPs ni tablas de permisos en DB â€” siguen siendo usados por el sistema
  de roles 3 paneles.
- NO eliminar `SecurityConfigScreen` si aun es usada por Modulos y Pantallas.

---

## TAREA 16 â€” Quitar Modulos y Pantallas del Menu (solo Usuarios + Roles)

**Estado:** `COMPLETADA`

**Contexto:**
- TAREA 15 quito Permisos y Roles-Permisos del menu.
- Modulos y Pantallas son metadata de infraestructura gestionada directo en DB + codigo.
- El submenu de Seguridad debe quedar solo con: **Usuarios** y **Roles**.

### Checkpoints

- [x] **16.1** Menu: En `src/components/pos/app-shell.tsx`, quitar del array `configSecurity`
      los items `/config/security/modules` y `/config/security/screens`.
      Dejar solo: `/config/security/users` y `/config/security/roles`.

- [x] **16.2** En `src/lib/permissions.ts`, quitar de `ROUTE_PERMISSIONS`:
      `config.security.modules.view` y `config.security.screens.view`.

- [x] **16.3** Eliminar archivos de pagina:
      `src/app/config/security/modules/page.tsx` y `src/app/config/security/screens/page.tsx`.

- [x] **16.4** Verificar si `SecurityConfigScreen` y `SecurityManager` aun tienen consumidores.
      Si ninguna pagina los importa, eliminarlos. Si aun los usa otra pagina, mantenerlos.

- [x] **16.5** Build: `npm run build` sin errores.

**Restricciones:**
- NO eliminar tablas ni SPs de Modulos/Pantallas en DB â€” siguen siendo usados por Roles.

---

## TAREA 17 â€” Fix: Botones Asignar/Quitar Usuarios en Panel Roles

**Estado:** `COMPLETADA`

**Contexto:**
- El panel derecho de la pantalla de Roles muestra usuarios Asignados y Disponibles.
- Los botones (icono UserMinus para quitar, UserPlus para asignar) no estan funcionales.
- Necesitan SP + endpoint + logica en el componente.
- Acceso completo a DB.

### Checkpoints

- [x] **17.1** DB: Verificar que existe SP `spRolUsuariosAsignar`. Si no, crearlo:
      ```sql
      CREATE PROCEDURE dbo.spRolUsuariosAsignar
        @IdRol INT, @IdUsuario INT, @Accion CHAR(1)  -- 'A' = asignar, 'Q' = quitar
      AS
      BEGIN
        IF @Accion = 'A'
          UPDATE dbo.Usuarios SET IdRol = @IdRol WHERE IdUsuario = @IdUsuario;
        ELSE IF @Accion = 'Q'
          UPDATE dbo.Usuarios SET IdRol = 1 WHERE IdUsuario = @IdUsuario;
      END
      ```

- [x] **17.2** API: Verificar que existe `PUT /api/roles/[id]/users`.
      Si no existe, crear `src/app/api/roles/[id]/users/route.ts`:
      - Validar sesion con `requireApiSession`.
      - Recibir body: `{ userId: number, action: "A" | "Q" }`.
      - Llamar al SP `spRolUsuariosAsignar` con los parametros.
      - Retornar `{ ok: true }` o error.

- [x] **17.3** Frontend: En `security-roles-screen.tsx`, conectar los botones:
      - Boton UserMinus (quitar): `onClick` llama a `PUT /api/roles/{roleId}/users`
        con `{ userId: user.id, action: "Q" }`.
      - Boton UserPlus (asignar): `onClick` llama a `PUT /api/roles/{roleId}/users`
        con `{ userId: user.id, action: "A" }`.
      - Los botones solo funcionan cuando `isEditing === true`.
        Cuando `!isEditing`: `disabled` + `opacity: 0.4; pointer-events: none`.
      - Al completar la accion exitosa:
        Toast confirmacion ("Usuario asignado al rol" / "Usuario removido del rol")
        + actualizar lista local (mover usuario entre Asignados y Disponibles)
        sin recargar pagina completa, o usar `router.refresh()`.
      - Toast de error si falla.

- [x] **17.4** Build: `npm run build` sin errores.

**Restricciones:**
- Acceso completo a DB.
- Boton rojo para quitar (UserMinus), verde para asignar (UserPlus).

---

## TAREA 18 â€” Catalogo: Paginas Independientes (sin tabs compartidos)

**Estado:** `COMPLETADA`

**Contexto:**
- Actualmente las 4 paginas de catalogo delegan a `CatalogConfigScreen` que renderiza
  header "Configuracion Â· Catalogo", tabs de navegacion y luego el componente de seccion.
- Mismo patron que tenia Seguridad antes de TAREA 10.
- Productos usa `CatalogManager`, los demas usan `CatalogMastersManager` + `EntityCrudSection`.
- Referencia: `D:\Masu\UI 3.0\app\config\catalog\` (paginas independientes sin tabs).

**Objetivo:** Hacer que cada pagina de catalogo sea independiente con su propio `PageHeader`,
sin tabs de navegacion compartidos. Mismo patron aplicado en Seguridad (TAREA 10).

### Checkpoints

- [x] **18.1** Reescribir `src/app/config/catalog/products/page.tsx`:
      ```tsx
      import { AppShell } from "@/components/pos/app-shell"
      import { PageHeader } from "@/components/pos/page-header"
      import { CatalogManager } from "@/components/pos/catalog-manager"
      import { getCatalogManagerData } from "@/lib/pos-data"

      export const dynamic = "force-dynamic"

      export default async function CatalogProductsPage() {
        const data = await getCatalogManagerData()
        return (
          <AppShell>
            <section className="content-page">
              <PageHeader title="Productos" description="Administra el catalogo de productos" />
              <CatalogManager data={data} />
            </section>
          </AppShell>
        )
      }
      ```

- [x] **18.2** Reescribir `src/app/config/catalog/categories/page.tsx`:
      ```tsx
      import { AppShell } from "@/components/pos/app-shell"
      import { PageHeader } from "@/components/pos/page-header"
      import { CatalogMastersManager } from "@/components/pos/catalog-masters-manager"
      import { getCatalogMastersData } from "@/lib/pos-data"

      export const dynamic = "force-dynamic"

      export default async function CatalogCategoriesPage() {
        const data = await getCatalogMastersData()
        return (
          <AppShell>
            <section className="content-page">
              <PageHeader title="Categorias" description="Administra las categorias de productos" />
              <CatalogMastersManager data={data} sections={["categories"]} />
            </section>
          </AppShell>
        )
      }
      ```

- [x] **18.3** Reescribir `src/app/config/catalog/units/page.tsx` con mismo patron:
      PageHeader title="Unidades de Medida", description="Administra las unidades de medida".

- [x] **18.4** Reescribir `src/app/config/catalog/product-types/page.tsx` con mismo patron:
      PageHeader title="Tipos de Producto", description="Administra los tipos de producto".

- [x] **18.5** Verificar si `CatalogConfigScreen` aun tiene consumidores.
      Si ninguna pagina la importa, eliminar `src/components/pos/catalog-config-screen.tsx`.

- [x] **18.6** Verificar que la navegacion del menu (dropdown usuario > Configuracion > Catalogo)
      sigue funcionando correctamente para llegar a cada pagina.

- [x] **18.7** Build: `npm run build` sin errores.

**Restricciones:**
- NO eliminar `CatalogManager`, `CatalogMastersManager` ni `EntityCrudSection` â€” siguen en uso.
- NO cambiar la API ni los SPs.
- Cada pagina carga solo los datos que necesita (products page no necesita masters data y viceversa).

---

## TAREA 19 â€” Fix Global: Toggle Switch separado del label en todas las pantallas

**Estado:** `COMPLETADA`

**Contexto:**
- En todas las pantallas, los toggle switch (ej: "Empresa activa", "Activo", "Forzar cambio
  de clave") estan demasiado separados del label porque usan `justify-content: space-between`
  en contenedores que ocupan todo el ancho del grid (100% del form).
- Afecta: Company (`.company-active-toggle`), Usuarios (`.users-active-toggle`),
  Roles (`.roles-switch-row`), Login (`.login-switch-row`).
- El toggle deberia estar cerca del label, no empujado al extremo opuesto.

**Objetivo:** Reducir la separacion visual entre label y toggle en todas las pantallas.

### Checkpoints

- [x] **19.1** Fix CSS global: el patron toggle con label no debe ocupar todo el ancho.
      **Solucion â€” elegir una de estas:**

      **Opcion A (recomendada):** Agregar `max-width` a los contenedores de toggle:
      ```css
      .company-active-toggle,
      .users-active-toggle,
      .roles-switch-row,
      .login-switch-row {
        max-width: 24rem;
      }
      ```
      Esto limita el ancho del row para que el switch quede cerca del texto.

      **Opcion B:** Cambiar de `justify-content: space-between` a un layout inline:
      ```css
      .company-active-toggle,
      .users-active-toggle {
        justify-content: flex-start;
        gap: 1rem;
      }
      ```
      Esto pone el switch justo despues del texto con gap fijo.

      Elegir la opcion que se vea mejor y sea consistente en todas las pantallas.
      Verificar visualmente en: Login, Company, Usuarios (tab General + tab Seguridad), Roles.

- [x] **19.2** Verificar que `.roles-switch-row` (que tiene borde y padding) tambien se
      ajusta correctamente. Esta clase tiene estilo diferente (card con borde) â€”
      puede necesitar un tratamiento distinto (mantener ancho completo pero con el
      switch mas cerca, o reducir el ancho del card).

- [x] **19.3** Build: `npm run build` sin errores.

**Restricciones:**
- Solo cambios CSS en `globals.css`. NO cambiar HTML/JSX de los componentes.
- La solucion debe ser consistente en TODAS las pantallas que usan toggle switches.

---

## TAREA 20 â€” Company: Formatos (Numero, Fecha, Hora)
> (antes TAREA 19)

**Estado:** `COMPLETADA`

**Contexto:**
- Pagina existente: `/config/company` con `CompanySettings` (294 lineas, 3 tabs: general/contacto/social).
- UI 4.0 agrega seccion de Formatos en `D:\Masu\UI 4.0\app\config\company\general\page.tsx`
  con configuracion de formatos de numero, fecha y hora + previews en vivo.
- Es la tarea mas simple â€” agregar un tab nuevo a la pagina existente.
- Acceso completo a DB.

**Objetivo:** Agregar tab "Formatos" a la pagina de Company con configuracion de formatos
de numero, fecha y hora, siguiendo el diseno de UI 4.0.

### Checkpoints

- [x] **20.1** DB: Crear tabla o agregar columnas para formatos de empresa.
      Verificar si la tabla `Empresa` ya tiene campos de formato. Si no:
      ```sql
      ALTER TABLE dbo.Empresa ADD
        FormatoDecimal NVARCHAR(10) DEFAULT '.',
        DigitosDecimales INT DEFAULT 2,
        SeparadorMiles NVARCHAR(10) DEFAULT ',',
        SimboloNegativo NVARCHAR(5) DEFAULT '-',
        FormatoFechaCorta NVARCHAR(20) DEFAULT 'dd/MM/yyyy',
        FormatoFechaLarga NVARCHAR(50) DEFAULT 'dddd, d ''de'' MMMM ''de'' yyyy',
        FormatoHoraCorta NVARCHAR(20) DEFAULT 'h:mm tt',
        FormatoHoraLarga NVARCHAR(20) DEFAULT 'h:mm:ss tt',
        SimboloAM NVARCHAR(5) DEFAULT 'AM',
        SimboloPM NVARCHAR(5) DEFAULT 'PM',
        PrimerDiaSemana INT DEFAULT 1,
        SistemaMedida NVARCHAR(20) DEFAULT 'Metrico';
      ```
      Actualizar SP de empresa para leer/guardar estos campos.

- [x] **20.2** API: Extender endpoints de company para incluir formatos en GET/PUT.

- [x] **20.3** UI: Agregar tab "Formatos" a `company-settings.tsx` con 3 secciones:
      - **Formato de Numeros:** simbolo decimal, digitos despues del decimal, separador de miles,
        simbolo negativo, preview del formato.
      - **Formato de Fecha:** formato corto, formato largo, primer dia de la semana, preview.
      - **Formato de Hora:** formato corto, formato largo, AM/PM simbolos, preview.
      - Boton "Restablecer Valores" para volver a defaults.
      - Referencia: `D:\Masu\UI 4.0\app\config\company\general\page.tsx`

- [x] **20.4** i18n: Agregar claves de traduccion para formatos.

- [x] **20.5** Build: `npm run build` sin errores.

**Restricciones:**
- Agregar tab nuevo a la pagina existente, NO crear pagina nueva.
- CSS vanilla BEM. Referencia: UI 4.0.

---

## TAREA 21 â€” Limpieza DB: Campos Duplicados en Tabla Empresa

**Estado:** `COMPLETADA`

**Contexto:**
- La tabla `Empresa` tiene campos duplicados/redundantes que guardan el mismo dato:
  - `RNC` y `IdentificacionFiscal` â€” mismo dato (identificacion fiscal)
  - `NombreComercial` y `NombreEmpresa` â€” mismo dato (nombre comercial)
  - `CalleNumero` y `Direccion` â€” mismo concepto (direccion)
  - `RazonSocial` es unico y se mantiene.
- En `pos-data.ts` linea 1609-1610, `NombreEmpresa` y `RazonSocial` ambos reciben
  `input.businessName`, lo cual es incorrecto.
- Acceso completo a DB.

**Objetivo:** Consolidar campos duplicados, mantener nombres genericos (internacionales),
actualizar SP + data layer + UI.

### Checkpoints

- [x] **21.1** DB: Consolidar campos en tabla `Empresa`. Plan de mapeo:

      | Conservar | Eliminar | Razon |
      |-----------|----------|-------|
      | `IdentificacionFiscal` | `RNC` | Nombre generico, aplica a cualquier pais |
      | `NombreComercial` | `NombreEmpresa` | Trade name es el standard |
      | `RazonSocial` | â€” | Se mantiene (nombre legal) |
      | `Direccion` | `CalleNumero` | Un solo campo de direccion |

      **Script SQL:**
      1. Migrar datos de campos a eliminar a los que se conservan (si tienen valor):
         ```sql
         UPDATE dbo.Empresa SET IdentificacionFiscal = RNC WHERE IdentificacionFiscal IS NULL OR IdentificacionFiscal = '';
         UPDATE dbo.Empresa SET Direccion = CalleNumero WHERE Direccion IS NULL OR Direccion = '';
         ```
      2. Eliminar columnas redundantes (o marcar como deprecated si se prefiere):
         ```sql
         ALTER TABLE dbo.Empresa DROP COLUMN RNC;
         ALTER TABLE dbo.Empresa DROP COLUMN NombreEmpresa;
         ALTER TABLE dbo.Empresa DROP COLUMN CalleNumero;
         ```
      Si el SP usa estas columnas, hacer ALTER PROCEDURE primero.

- [x] **21.2** DB: Actualizar SP de empresa (`spEmpresaCRUD` o similar):
      - Quitar parametros `@RNC`, `@NombreEmpresa`, `@CalleNumero`.
      - Asegurar que `@IdentificacionFiscal`, `@NombreComercial`, `@RazonSocial`,
        `@Direccion` estan en el INSERT/UPDATE/SELECT.

- [x] **21.3** Data layer (`pos-data.ts`):
      - Quitar mapeos de `rnc`, `streetAddress` y cualquier referencia a columnas eliminadas.
      - Consolidar: `fiscalId` mapea a `IdentificacionFiscal`, `tradeName` a `NombreComercial`,
        `businessName` a `RazonSocial`, `address` a `Direccion`.
      - Quitar el `.input("NombreEmpresa", ...)` duplicado (linea 1609).
      - Quitar `.input("RNC", ...)` (linea 1607).
      - Quitar `.input("CalleNumero", ...)` (linea 1613).

- [x] **21.4** UI (`company-settings.tsx`):
      - Quitar campo "Direccion General" (duplicado de "Calle y Numero").
      - Renombrar label "RNC" a "Identificacion Fiscal" (o mantener "RNC" como label
        pero usando el campo `fiscalId` internamente â€” a discrecion del pais).
      - Verificar que todos los campos del form apuntan a las propiedades correctas.

- [x] **21.5** Build: `npm run build` sin errores.

**Restricciones:**
- Migrar datos ANTES de eliminar columnas.
- Acceso completo a DB.
- NO romper el endpoint de company public (usado en login para branding).

---

## TAREA 22 â€” Listas de Precios (Modulo Nuevo)
> (antes TAREA 21)

**Estado:** `COMPLETADA`

**Contexto:**
- No existe en V2. Es un modulo completamente nuevo.
- UI 4.0 referencia: `D:\Masu\UI 4.0\app\config\catalog\price-lists\page.tsx`
- Layout: 2 paneles (lista izquierda + detalle derecho con tabs General/Usuarios).
- Patron similar a Roles (panel izquierdo + panel central).
- Acceso completo a DB.

**Objetivo:** Crear modulo de Listas de Precios con CRUD completo y asignacion de usuarios.

### Checkpoints

- [x] **22.1** DB: Crear tabla `ListasPrecios` + `ListaPrecioUsuarios` con FK, unique index, soft-delete (RowStatus). Seed con 3 registros. Scripts: `database/21_price_lists.sql`.

- [x] **22.2** DB: SP `spListasPreciosCRUD` (L/O/I/A/D) y `spListaPrecioUsuarios` (LA/LD con CHAR(2), A/reactivate/Q, AA/QA). Script: `database/22_sp_price_lists.sql`.

- [x] **22.3** API: GET/POST `/api/catalog/price-lists`, PUT/DELETE `/api/catalog/price-lists/[id]`, GET/PUT `/api/catalog/price-lists/[id]/users` (soporta assign_all/remove_all).

- [x] **22.4** Data layer: `getPriceLists`, `createPriceList`, `updatePriceList`, `deletePriceList`, `getPriceListUsers` (LA+LD paralelo), `assignPriceListUser`, `removePriceListUser`, `assignAllPriceListUsers`, `removeAllPriceListUsers`. Todas con fallback try/catch para `parameter.type.validate`.

- [x] **22.5** UI: `price-lists-screen.tsx` â€” layout 2 paneles. Panel izq: lista con busqueda, badge estado, menu 3ptos (Editar/Duplicar/Eliminar), boton nueva. Panel der: tab General (codigo readonly, switch activo, descripcion, abreviatura, fechas, moneda) + tab Usuarios (Asignados/Disponibles con asignar/quitar individual y bulk "Asignar todos"/"Quitar todos").

- [x] **22.6** Pagina: `src/app/config/catalog/price-lists/page.tsx` con PageHeader.

- [x] **22.7** Menu: item "Listas de Precios" en submenu Catalogo de `app-shell.tsx`.

- [x] **22.8** Permisos: screen + permiso + rol en DB (`database/22_permission_price_lists.sql`).

- [x] **22.9** CSS + i18n + Build.

### Correcciones realizadas

- SP `spListaPrecioUsuarios`: acciones originales `L/A/Q` con CHAR(1) corregidas a `LA/LD/A/Q` con CHAR(2). LA=listar asignados, LD=listar disponibles.

- SP: accion `A` corregida para reactivate con UPDATE + INSERT (si existe RowStatus=0, actualiza; si no existe, inserta).

- SP: acciones `AA` (asignar todos) y `QA` (quitar todos) agregadas.

- SP: validacion obligatoria de `@FechaInicio` y `@FechaFin` en acciones I y A.

- Data layer: `mapPriceListRow` con `parseDate` que maneja tanto `Date` objects (tedious) como strings.

- Data layer: fechas enviadas como `Date` objects con `sql.Date` (no NVarChar) para correcta conversion.

- Data layer: todas las funciones de price-lists con fallback try/catch para `parameter.type.validate is not a function`.

- UI: fechas obligatorias (`required`, `*` en labels), validacion en submit.

- UI: botones "Asignar todos" / "Quitar todos" con `UserCheck` / `UserX`.

- SQL: UPDATE correctivo para registros con fechas NULL.

---

## TAREA 22.1 â€” Correccion de Bug: parameter.type.validate

**Sintoma:** `Validation failed for parameter 'IdListaPrecio'. parameter.type.validate is not a function`

**Causa raiz:** `mssql` v12.2.1 con `tedious` v19.2.1 tiene bug intermitente donde `.input(name, sql.Int, value)` falla. El mismo patron de error ya estaba manejado con fallback en `mutateAdminEntity` del rol.

**Solucion:** todas las funciones de price-lists en `pos-data.ts` ahora tienen try/catch que, al detectar ese error especifico, reintenta sin tipos explicitos (`.input(name, value)`), dejando que tedious infiera el tipo.

---

## TAREA 22.2 â€” Correccion de Bug: Fechas no se cargaban desde DB

**Sintoma:** `startDate` y `endDate` llegaban vacios al form.

**Causa raiz:** `tedious` convierte columnas DATE a `Date` objects de JS. `String(date)` devolvia `"Mon Jan 01 2018..."` y `.slice(0,10)` cortaba mal.

**Solucion:** `parseDate` en `mapPriceListRow` detecta `instanceof Date` y formatea manualmente `YYYY-MM-DD`. Inputs de fecha ahora usan `Date` objects con `sql.Date`.

---

## TAREA 22.3 â€” Mejora: Botones Asignar/Quitar todos

- SP: acciones `AA` y `QA`
- Data layer: `assignAllPriceListUsers`, `removeAllPriceListUsers`
- API: acepta `assign_all` y `remove_all`
- UI: botones "Asignar todos" / "Quitar todos" con `UserCheck` / `UserX`

---

## TAREA 22.4 â€” Mejora: Fechas obligatorias

- SP: validacion obligatoria de `@FechaInicio` y `@FechaFin` en INSERT y UPDATE
- UI: `required`, `*` en labels, validacion en submit
- Data layer: validacion en `createPriceList` y `updatePriceList`
- SQL: UPDATE correctivo para fechas NULL existentes

---

## TAREA 23 â€” Monedas (Modulo Nuevo â€” 3 Paginas)

**Estado:** `COMPLETO âœ…`

**Contexto:**
- No existe en V2. Modulo completamente nuevo con 3 paginas.
- UI 4.0 referencia: `D:\Masu\UI 4.0\app\config\currencies\` (3 archivos).
- Acceso completo a DB.

**Objetivo:** Crear modulo Monedas con configuracion, tasas diarias e historial.

**Objetos DB afectados:**
| Objeto | Tipo | Accion |
|--------|------|--------|
| `dbo.Monedas` | Tabla | CREATE |
| `dbo.MonedaTasas` | Tabla | CREATE |
| `dbo.spMonedasCRUD` | SP | CREATE |
| `dbo.spMonedaTasasGuardar` | SP | CREATE |
| `dbo.spMonedaTasasHistorial` | SP | CREATE |
| `dbo.Permisos` | Tabla | INSERT x3 claves |
| `dbo.RolesPermisos` | Tabla | INSERT x3 (IdRol=1) |

### Checkpoints

- [x] **23.1 âœ…** DB: Crear tablas `Monedas` y `MonedaTasas`:
      ```sql
      CREATE TABLE dbo.Monedas (
        IdMoneda INT IDENTITY(1,1) PRIMARY KEY,
        Codigo NVARCHAR(5) NOT NULL UNIQUE,
        Nombre NVARCHAR(100) NOT NULL,
        Simbolo NVARCHAR(10),
        SimboloAlt NVARCHAR(10),
        EsLocal BIT NOT NULL DEFAULT 0,
        CodigoBanco NVARCHAR(20),
        FactorConversionLocal DECIMAL(18,6) DEFAULT 1,
        FactorConversionUSD DECIMAL(18,6) DEFAULT 1,
        MostrarEnPOS BIT DEFAULT 1,
        AceptaPagos BIT DEFAULT 1,
        DecimalesPOS INT DEFAULT 2,
        Activo BIT NOT NULL DEFAULT 1
      );

      CREATE TABLE dbo.MonedaTasas (
        IdTasa INT IDENTITY(1,1) PRIMARY KEY,
        IdMoneda INT NOT NULL REFERENCES dbo.Monedas(IdMoneda),
        Fecha DATE NOT NULL,
        TasaAdministrativa DECIMAL(18,6),
        TasaOperativa DECIMAL(18,6),
        TasaCompra DECIMAL(18,6),
        TasaVenta DECIMAL(18,6),
        IdUsuario INT,
        FechaRegistro DATETIME DEFAULT GETDATE(),
        CONSTRAINT UQ_MonedaFecha UNIQUE (IdMoneda, Fecha)
      );
      ```
      Seed:
      ```sql
      INSERT INTO dbo.Monedas (Codigo, Nombre, Simbolo, SimboloAlt, EsLocal, MostrarEnPOS, AceptaPagos, DecimalesPOS, Activo)
      VALUES
        ('DOP', 'Peso Dominicano', 'RD$', '$', 1, 1, 1, 2, 1),
        ('USD', 'Dolar Estadounidense', 'US$', '$', 0, 1, 1, 2, 1),
        ('EUR', 'Euro', 'â‚¬', 'â‚¬', 0, 0, 0, 2, 1)

      INSERT INTO dbo.MonedaTasas (IdMoneda, Fecha, TasaAdministrativa, TasaOperativa, TasaCompra, TasaVenta)
      SELECT IdMoneda, CAST(GETDATE() AS DATE), 59.50, 59.80, 59.20, 60.10
      FROM dbo.Monedas WHERE Codigo = 'USD'

      INSERT INTO dbo.MonedaTasas (IdMoneda, Fecha, TasaAdministrativa, TasaOperativa, TasaCompra, TasaVenta)
      SELECT IdMoneda, CAST(GETDATE() AS DATE), 64.20, 64.50, 63.90, 65.00
      FROM dbo.Monedas WHERE Codigo = 'EUR'
      ```

- [x] **23.2 âœ…** DB: Crear SPs:

      `spMonedasCRUD` con acciones:
      - `L` â€” Listar todas con ultima tasa via LEFT JOIN a MonedaTasas
      - `O` â€” Obtener una por IdMoneda
      - `A` â€” Actualizar configuracion de moneda

      `spMonedaTasasGuardar` â€” Upsert (INSERT si no existe, UPDATE si existe) para (IdMoneda, Fecha).
      Parametros: `@IdMoneda`, `@Fecha`, `@TasaAdministrativa`, `@TasaOperativa`,
      `@TasaCompra`, `@TasaVenta`, `@IdUsuario`.

      `spMonedaTasasHistorial` â€” Historial paginado.
      Parametros: `@IdMoneda INT = NULL`, `@FechaDesde DATE = NULL`, `@FechaHasta DATE = NULL`,
      `@Pagina INT = 1`, `@TamanoPagina INT = 50`.
      Retorna filas + total de registros.

      Todos con `@IdSesion INT = NULL, @TokenSesion NVARCHAR(100) = NULL`.

- [x] **23.3 âœ…** API: Crear endpoints:
      - `src/app/api/currencies/route.ts` â€” `GET` (listar), `PUT` (actualizar moneda)
      - `src/app/api/currencies/rates/route.ts` â€” `GET` (tasas del dia), `PUT` (guardar tasas bulk)
      - `src/app/api/currencies/history/route.ts` â€” `GET` con query params: `idMoneda`, `fechaDesde`, `fechaHasta`, `pagina`

- [x] **23.4 âœ…** Data layer: Agregar en `src/lib/pos-data.ts`:
      - `getCurrencies()` â€” `spMonedasCRUD` accion `L`
      - `updateCurrency(id, data)` â€” accion `A`
      - `saveCurrencyRate(data)` â€” `spMonedaTasasGuardar`
      - `getCurrencyHistory(filters)` â€” `spMonedaTasasHistorial`

- [x] **23.5 âœ…** UI: Crear `src/components/pos/currencies-screen.tsx`:
      Layout 2 paneles (patron igual a `price-lists-screen.tsx`):
      - **Panel izquierdo (280px):** lista de monedas, badge "Local" para EsLocal=1,
        simbolo y nombre. Sin boton nuevo (monedas son fijas).
      - **Panel derecho:** modo lectura, boton "Editar Datos":
        - Tab **General:** nombre, simbolo, simbolo alt, codigo banco, switch Activo
        - Tab **POS:** switch MostrarEnPOS, switch AceptaPagos, input DecimalesPOS
        - Tab **Tasas:** tabla con TasaAdministrativa/Operativa/Compra/Venta + fecha ultima actualizacion
      - Referencia: `D:\Masu\UI 4.0\app\config\currencies\page.tsx`

- [x] **23.6 âœ…** UI: Crear `src/components/pos/currency-rates-screen.tsx`:
      - 4 stat cards: Fecha actual | Monedas activas | Ultima actualizacion | Estado (Al dia/Pendiente)
      - Tabla editable: Moneda | Simbolo | Tasa Admin | Tasa Operativa | Tasa Compra | Tasa Venta | Ultima Actualizacion
        - Las 4 columnas de tasa son inputs numericos editables inline
        - Badge variacion % respecto a tasa anterior
      - Boton "Obtener del Banco Central" (UI solamente, no funcional)
      - Boton "Guardar Tasas" â€” llama `PUT /api/currencies/rates`
      - Referencia: `D:\Masu\UI 4.0\app\config\currencies\rates\page.tsx`

- [x] **23.7 âœ…** UI: Crear `src/components/pos/currency-history-screen.tsx`:
      - 4 stat cards: Total registros | Promedio USD | Promedio EUR | Monedas activas
      - Filtros: input busqueda + dropdown moneda + date range (desde/hasta)
      - Tabla paginada: Fecha | Moneda | Tasa Admin | Tasa Operativa | Tasa Compra | Tasa Venta | Usuario
      - Boton "Exportar" (UI solamente, no funcional)
      - Referencia: `D:\Masu\UI 4.0\app\config\currencies\history\page.tsx`

- [x] **23.8 âœ…** Menu: En `src/components/pos/app-shell.tsx` agregar grupo "Monedas" en
      submenu Configuracion con 3 items:
      - Configuracion â†’ `/config/currencies` (icono: `DollarSign`)
      - Tasas Diarias â†’ `/config/currencies/rates` (icono: `TrendingUp`)
      - Historial â†’ `/config/currencies/history` (icono: `History`)

- [x] **23.9 âœ…** Paginas independientes â€” crear los 3 archivos `page.tsx`:
      - `src/app/config/currencies/page.tsx` â€” `AppShell` + `PageHeader` title="Monedas" + `CurrenciesScreen`
      - `src/app/config/currencies/rates/page.tsx` â€” title="Tasas del Dia" + `CurrencyRatesScreen`
      - `src/app/config/currencies/history/page.tsx` â€” title="Historial de Tasas" + `CurrencyHistoryScreen`
      Sin tabs compartidos. Sin `SecurityConfigScreen`. `export const dynamic = "force-dynamic"`.

- [x] **23.10 âœ…** DB: Registrar permisos en base de datos:
      ```sql
      INSERT INTO dbo.Permisos (Clave, Descripcion, Activo) VALUES
        ('config.currencies.view', 'Ver Monedas', 1),
        ('config.currencies.rates.view', 'Ver Tasas Diarias', 1),
        ('config.currencies.history.view', 'Ver Historial de Tasas', 1)

      INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso)
      SELECT 1, IdPermiso FROM dbo.Permisos
      WHERE Clave IN (
        'config.currencies.view',
        'config.currencies.rates.view',
        'config.currencies.history.view'
      )
      AND NOT EXISTS (
        SELECT 1 FROM dbo.RolesPermisos rp
        WHERE rp.IdRol = 1 AND rp.IdPermiso = dbo.Permisos.IdPermiso
      )
      ```
      Agregar las 3 claves al tipo `PermissionKey` en `src/lib/permissions.ts`
      y sus entradas en `ROUTE_PERMISSIONS`.

- [x] **23.11** CSS + i18n + Build: âœ… Completado
      - Estilos BEM en `globals.css`: prefijos `.currencies-*`, `.currency-rates-*`, `.currency-history-*`
      - Claves i18n existentes en `lib/i18n.tsx` (lÃ­neas 66-68)
      - `npm run build` sin errores TypeScript (3 fixes: `SettingsSectionKey` union, state type, `CurrencyForm.isLocal`)
      - Fixes adicionales: `app-shell.tsx` â€” agregado `"currencies"` a `SettingsSectionKey` y state type; `currencies-screen.tsx` â€” agregado `isLocal` a `CurrencyForm` y `recordToForm`

**Restricciones:**
- CSS vanilla BEM unicamente, sin Tailwind.
- Paginas 100% independientes, sin tabs compartidos.
- Patron de autenticacion igual al existente en `pos-data.ts`.
- Referencia directa: `D:\Masu\UI 4.0\app\config\currencies\`

---

## TAREA 24 â€” Categorias: Rediseno con Arbol Jerarquico + Tabs POS
> (antes TAREA 23)

**Estado:** `COMPLETA` âœ…

**Contexto:**
- V2 actual: usa `EntityCrudSection` generico (tabla simple con modal).
- UI 4.0 referencia: `D:\Masu\UI 4.0\app\config\catalog\categories\page.tsx`
- Diseno: arbol jerarquico izquierdo + tabs (General / POS con preview live / Imagen).
- Requiere soporte para categorias padre/hijo en DB.
- Acceso completo a DB.

**Objetivo:** Reescribir Categorias como pantalla de 2 paneles con arbol jerarquico
y configuracion POS con preview en vivo.

### Fase A â€” DB

- [x] **23.1 âœ…** DB: Columnas POS + IdCategoriaPadre agregadas a `Categorias`
- [x] **23.2 âœ…** DB: `spCategoriasCRUD` reescrito completo con campos POS y jerarquia

### Fase B â€” UI

- [x] **23.3 âœ…** UI: `src/components/pos/catalog-categories-screen.tsx` con 3 tabs
- [x] **23.4 âœ…** Pagina `src/app/config/catalog/categories/page.tsx` actualizada
- [x] **23.5 âœ…** API: `/api/catalog/categories` con CRUD completo
- [x] **23.6 âœ…** CSS vanilla BEM + pos-data.ts con tipos y funciones nuevas + Build OK

---

## TAREA 29.5 â€” Tipos de Producto: Rediseno 2 Paneles

**Estado:** `COMPLETA` âœ…

**Contexto:**
- Pantalla actual: `EntityCrudSection` generica (tabla simple + modal). Muy basica.
- No hay referencia en UI 4.0 para esta pantalla â€” seguir el patron de Categorias y Listas de Precios.
- Componente actual: `catalog-masters-manager.tsx` con `EntityCrudSection`.
- Reemplazar con un componente dedicado `catalog-product-types-screen.tsx`.
- DB: tabla `dbo.TiposProducto` (IdTipoProducto, Nombre, Descripcion, Activo, RowStatus, FechaCreacion).
- SP existente: manejado por `/api/admin/[entity]` con `spTiposProductoCRUD` o similar.
- Acceso completo a DB.

**Objetos DB afectados:**
| Objeto | Tipo | Accion |
|--------|------|--------|
| `dbo.TiposProducto` | Tabla | Verificar columnas existentes |
| `dbo.spTiposProductoCRUD` | SP | Verificar/crear si no existe con acciones L/I/A/D |
| `dbo.Permisos` | Tabla | INSERT (Clave: config.catalog.product-types.view) |
| `dbo.RolesPermisos` | Tabla | INSERT (IdRol=1) |

### Checkpoints

- [x] **29.5.1** DB: Verificar que `spTiposProductoCRUD` existe con acciones L/I/A/D.
      Si no existe, crearlo:
      ```sql
      CREATE OR ALTER PROCEDURE dbo.spTiposProductoCRUD
        @Accion NVARCHAR(1),
        @IdTipoProducto INT = NULL,
        @Nombre NVARCHAR(100) = NULL,
        @Descripcion NVARCHAR(500) = NULL,
        @Activo BIT = 1,
        @IdSesion INT = NULL,
        @TokenSesion NVARCHAR(100) = NULL
      AS BEGIN
        SET NOCOUNT ON;
        IF @Accion = 'L'
          SELECT IdTipoProducto, Nombre, Descripcion, Activo FROM dbo.TiposProducto
          WHERE RowStatus = 1 ORDER BY Nombre;
        ELSE IF @Accion = 'I'
          INSERT INTO dbo.TiposProducto (Nombre, Descripcion, Activo)
          VALUES (@Nombre, @Descripcion, @Activo);
        ELSE IF @Accion = 'A'
          UPDATE dbo.TiposProducto SET Nombre=@Nombre, Descripcion=@Descripcion, Activo=@Activo
          WHERE IdTipoProducto=@IdTipoProducto AND RowStatus=1;
        ELSE IF @Accion = 'D'
          UPDATE dbo.TiposProducto SET RowStatus=0 WHERE IdTipoProducto=@IdTipoProducto;
      END;
      ```

- [x] **29.5.2** DB: Registrar permiso:
      ```sql
      IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.catalog.product-types.view')
        INSERT INTO dbo.Permisos (Clave, Descripcion, Activo)
        VALUES ('config.catalog.product-types.view', 'Ver Tipos de Producto', 1)

      INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso)
      SELECT 1, IdPermiso FROM dbo.Permisos
      WHERE Clave = 'config.catalog.product-types.view'
      AND NOT EXISTS (
        SELECT 1 FROM dbo.RolesPermisos rp
        WHERE rp.IdRol = 1 AND rp.IdPermiso = dbo.Permisos.IdPermiso)
      ```

- [x] **29.5.3** API: Crear `src/app/api/catalog/product-types/route.ts` (GET listar, POST crear)
      y `src/app/api/catalog/product-types/[id]/route.ts` (PUT actualizar, DELETE eliminar).
      Patron identico a `src/app/api/catalog/price-lists/route.ts`.

- [x] **29.5.4** Data layer: Agregar en `src/lib/pos-data.ts`:
      `getProductTypes()`, `createProductType(data)`, `updateProductType(id, data)`, `deleteProductType(id)`.

- [x] **29.5.5** UI: Crear `src/components/pos/catalog-product-types-screen.tsx`:
      Layout 2 paneles (igual que `price-lists-screen.tsx`):
      - **Panel izquierdo (320px):** busqueda + boton "+ Nuevo Tipo", lista de tipos con
        badge Activo/Inactivo, menu 3 puntos (Editar, Eliminar).
      - **Panel derecho:** titulo del tipo seleccionado, patron "Editar Datos":
        - Campo Nombre (requerido)
        - Campo Descripcion (textarea)
        - Switch Activo
        - Contador de productos asignados a este tipo (readonly, consulta en SP accion L)
      - Estado vacio cuando no hay tipo seleccionado.
      CSS BEM prefijo `.product-types-*`.

- [x] **29.5.6** Pagina: Actualizar `src/app/config/catalog/product-types/page.tsx`
      para usar `CatalogProductTypesScreen` en lugar de `CatalogMastersManager`.

- [x] **29.5.7** CSS + Build: Estilos en `globals.css`. `npm run build` sin errores.

- [x] **29.5.8** Homologacion DB:
      ```sql
      SELECT TABLE_NAME, COLUMN_NAME, COUNT(*) AS veces
      FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo'
      GROUP BY TABLE_NAME, COLUMN_NAME HAVING COUNT(*) > 1;

      SELECT TABLE_NAME, COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = 'dbo'
        AND (COLUMN_NAME LIKE 'p[A-Z]%' OR COLUMN_NAME LIKE 'Puede%')
      ORDER BY TABLE_NAME, COLUMN_NAME;
      ```

**Restricciones:**
- CSS vanilla BEM. Patron de 2 paneles igual a `price-lists-screen.tsx`.
- No modificar `catalog-masters-manager.tsx` ni `EntityCrudSection`.

---

## TAREA 26 â€” Limpieza Estructura DB: Roles-Permisos (Fix Arquitectura)

**Estado:** `COMPLETA` âœ…

**Analisis del estado actual (verificado en codigo):**

El flujo real de permisos para usuarios NO-admin es:
```
spPermisosObtenerPorRol(@IdRol)
  â†’ JOIN RolesPermisos â†’ Permisos â†’ Pantallas
  â†’ WHERE pVer=1 (o PuedeVer=1)
  â†’ retorna PA.Ruta (ej: /config/catalog/price-lists)
  â†’ getPermissionKeysByRole() convierte ruta â†’ clave via routeToPermissionKey()
```

Problema: Los permisos nuevos (Clave='config.catalog.price-lists.view') que insertamos
NO tienen `pVer=1` ni `IdPantalla`, asi que el SP nunca los retorna para no-admins.
Solo el superadmin (IdRol=1) los ve porque hay bypass en `/api/auth/permissions`
que devuelve todos los keys de ROUTE_PERMISSIONS directamente.

**Objetivo:** Reescribir `spPermisosObtenerPorRol` para usar `Permisos.Clave` directamente,
eliminando la dependencia de `Pantallas` y de columnas CRUD (`pVer`/`PuedeVer`).

**Objetos DB afectados:**
| Objeto | Tipo | Accion |
|--------|------|--------|
| `dbo.Permisos` | Tabla | ALTER DROP columnas CRUD legacy |
| `dbo.spPermisosObtenerPorRol` | SP | ALTER â€” reescribir logica |
| `dbo.spPermisosCRUD` | SP | ALTER â€” quitar params CRUD |
| `src/lib/auth-session.ts` | Code | Simplificar mapeo de claves |

### Checkpoints

- [x] **26.1** DB: Verificar columnas actuales de `Permisos`:
      Confirmar cuales existen de: `Clave`, `IdPantalla`, `pVer`, `pCrear`, `pEditar`,
      `pEliminar`, `pAprobar`, `pAnular`, `pImprimir`, `PeutVer`, `PeutCrear`,
      `PeutEditar`, `PeutEliminar`, `PeutAprobar`, `PeutAnular`, `PeutImprimir`.

- [x] **26.2** DB: Reescribir `spPermisosObtenerPorRol` para usar `Permisos.Clave`:
      Script: `database/26_tarea_step1.sql`. SP ahora retorna `Clave` directamente.
      Pobla `Clave` para los 25 permisos existentes desde `Pantallas.Ruta`.

- [x] **26.3** Code: Actualizar `src/lib/auth-session.ts` â€” funcion `getPermissionKeysByRole`:
      Simplificado: SP retorna `Clave` directamente. Sin try/catch fallback.
      Import de `routeToPermissionKey` removido.

- [x] **26.4** DB: Eliminar columnas CRUD redundantes de `Permisos` (las que existan segun 26.1):
      `ALTER TABLE DROP COLUMN` bloqueado por bug de metadata SQL Server (error 4922).
      Solucion: `sp_rename` para renombrar a `Obsolete_*` (aplicado en sesion anterior).
      Columnas efectivas removidas de acceso de la aplicacion.

- [x] **26.5** DB: Actualizar `spPermisosCRUD`:
      Script: `database/26_tarea_step1.sql`. SP ahora incluye columna `Clave`.
      Parametro `Clave` agregado. Genera automaticamente desde `Pantallas.Ruta` si no se provee.

- [x] **26.6** Code: Buscar y eliminar referencias a columnas eliminadas en `src/`:
      `pos-data.ts`: agregado `clave` al tipo `permissions` y al mapping.
      `auth-session.ts`: `getPermissionKeysByRole` simplificado.
      `npm run build` sin errores.

- [x] **26.7** Verificacion: `spPermisosObtenerPorRol(1)` retorna 16 claves para admin:
      `cash-register.view`, `config.catalog.*`, `config.company.view`, `config.currencies.*`,
      `config.security.*`, `dashboard.view`, `orders.view`, `queries.view`, `reports.view`, `security.view`.

**Restricciones:**
- NO tocar `RolPantallaPermisos` ni `RolCamposVisibilidad`.
- NO tocar `RolesPermisos`.
- El SP `spPermisosObtenerPorRol` en `database/09_permisos_por_rol.sql` debe actualizarse
  con la nueva version para mantener el historial de scripts.
- Acceso completo a DB.

---

## TAREA 27 â€” Formatos Globales: Numeros y Fechas desde Empresa

**Estado:** `COMPLETA` âœ…

**Contexto:**
- La tabla `Empresa` ya tiene los campos de formato: `FormatoDecimal`, `SeparadorMiles`,
  `DigitosDecimales`, `SimboloNegativo`, `FormatoFechaCorta`, `FormatoFechaLarga`,
  `FormatoHoraCorta`, `FormatoHoraLarga`, `SimboloAM`, `SimboloPM`.
- El SP `spEmpresaCRUD` accion `L` ya los retorna.
- El API `/api/company` ya los expone.

**Objetivo:** Crear un contexto React de formatos y aplicarlo a todas las pantallas que
muestran numeros o fechas.

**Objetos DB afectados:** Ninguno â€” la DB ya esta correcta.

### Checkpoints

- [x] **27.1** Crear `src/lib/format-context.tsx`:
      Context que carga los formatos de empresa desde `/api/company` y expone funciones:
      ```ts
      type FormatContextValue = {
        formatNumber: (value: number, decimals?: number) => string
        formatDate: (value: string | Date, mode?: "short" | "long") => string
        formatTime: (value: string | Date, mode?: "short" | "long") => string
        formatDateTime: (value: string | Date) => string
        isLoading: boolean
      }
      ```
      Implementacion de `formatNumber`:
      - Usa `FormatoDecimal` como separador decimal (ej: "." o ",")
      - Usa `SeparadorMiles` como separador de miles (ej: "," o ".")
      - Usa `DigitosDecimales` como precision por defecto (sobreescribible con param `decimals`)
      - Usa `SimboloNegativo` para negativos

      Implementacion de `formatDate`:
      - Convierte el patron `FormatoFechaCorta` (ej: "dd/MM/yyyy") a formato JS
      - `mode: "short"` â†’ `FormatoFechaCorta`, `mode: "long"` â†’ `FormatoFechaLarga`
      - Manejar inputs: string ISO ("2026-03-21"), string con tiempo, Date object
      - Fallback: si no hay formato cargado aun, mostrar ISO "yyyy-MM-dd"

      Implementacion de `formatTime`:
      - `mode: "short"` â†’ `FormatoHoraCorta`, `mode: "long"` â†’ `FormatoHoraLarga`
      - Reemplazar "tt" con AM/PM usando `SimboloAM`/`SimboloPM`

      `formatDateTime`: combina `formatDate("short")` + " " + `formatTime("short")`.

- [x] **27.2** Agregar `FormatProvider` al layout raiz:
      En `src/app/layout.tsx` (o donde esta `PermissionsProvider`), envolver con `<FormatProvider>`.
      El provider debe hacer fetch a `/api/company` una sola vez al montar.

- [x] **27.3** Crear hook `useFormat` en `src/lib/format-context.tsx`:
      ```ts
      export function useFormat() {
        const ctx = useContext(FormatContext)
        if (!ctx) throw new Error("useFormat must be inside FormatProvider")
        return ctx
      }
      ```

- [x] **27.4** Aplicar en `src/components/pos/currency-rates-screen.tsx`:
      - Stat card "Fecha" â†’ `formatDate(new Date(), "short")`
      - Stat card "Ultima Actualizacion" â†’ `formatDate(ultimaActualizacion, "short")`
      - Columna "Ultima Actualizacion" en tabla â†’ `formatDate(fecha, "short")`
      - Columna "Tasa Actual" â†’ `formatNumber(tasa, 4)` (4 decimales para tasas)
      - Inputs "Nueva Tasa" â†’ mantener como inputs numericos nativos (no formatear inputs)

- [x] **27.5** Aplicar en `src/components/pos/currency-history-screen.tsx`:
      - Columna "Fecha" â†’ `formatDate(fecha, "short")`
      - Columnas de tasas â†’ `formatNumber(tasa, 4)`
      - Stat cards de promedios â†’ `formatNumber(valor, 4)`

- [x] **27.6** Aplicar en `src/components/pos/currencies-screen.tsx`:
      - Tab "Tasas": valores de tasa â†’ `formatNumber(tasa, 4)`
      - Campo "Fecha ultima actualizacion" â†’ `formatDate(fecha, "short")`

- [x] **27.7** Aplicar en `src/components/pos/price-lists-screen.tsx`:
      - Campos de fecha (FechaInicio, FechaFin) en modo lectura â†’ `formatDate(fecha, "short")`
      - Inputs de fecha en modo edicion â†’ mantener como `<input type="date">` (valor ISO)

- [x] **27.8** Aplicar en `src/components/pos/security-users-screen.tsx`:
      - Cualquier fecha visible (FechaCreacion, ultima actividad, etc.) â†’ `formatDate`

- [x] **27.9** Aplicar en `src/components/pos/security-roles-screen.tsx`:
      - Cualquier fecha visible â†’ `formatDate`

- [x] **27.10** Buscar en `src/components/pos/` cualquier otro uso de fechas o numeros hardcodeados:
      ```
      grep -r "toLocaleDateString\|toLocaleString\|toISOString\|new Date.*toString\|\.slice(0,10)" src/components/
      ```
      Reemplazar con `formatDate` / `formatNumber` del contexto.

- [x] **27.11** Build: `npm run build` sin errores TypeScript.

**Restricciones:**
- El `FormatProvider` NO debe bloquear el render â€” mostrar fallback ISO mientras carga.
- Inputs de formulario (`<input type="date">`, `<input type="number">`) mantienen
  sus valores en formato nativo. Solo formatear valores en modo **lectura/display**.
- No modificar el SP ni el API de Empresa.
- CSS vanilla BEM. Sin Tailwind.

---

## TAREA 28 â€” Categorias: Permiso DB + Tab Productos con Asignacion

**Estado:** `COMPLETA` âœ…

**Contexto:**
- TAREA 24 (Categorias) esta completa pero le faltan 2 cosas:
  1. El permiso `config.catalog.categories.view` no fue insertado en DB.
  2. El panel derecho solo tiene tabs General/POS/Imagen â€” falta tab Productos
     con la misma mecanica de asignacion que "Usuarios" en Roles.
- Los productos ya tienen `IdCategoria` en `dbo.Productos` â€” la asignacion
  es simplemente un UPDATE de ese campo (no una tabla junction).
- Referencia de patron: tab Usuarios en `security-roles-screen.tsx`
  (sub-tabs Asignados/Disponibles, botones asignar/quitar individual y bulk).

**Objetos DB afectados:**
| Objeto | Tipo | Accion |
|--------|------|--------|
| `dbo.Permisos` | Tabla | INSERT (Clave: config.catalog.categories.view) |
| `dbo.RolesPermisos` | Tabla | INSERT (IdRol=1) |
| `dbo.spCategoriasCRUD` | SP | ALTER â€” agregar acciones LP (listar productos asignados) y LD (disponibles) |
| `dbo.Productos` | Tabla | UPDATE IdCategoria (asignar/quitar) |

### Checkpoints

- [x] **28.1** DB: Registrar permiso de Categorias:
      ```sql
      IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE Clave = 'config.catalog.categories.view')
        INSERT INTO dbo.Permisos (Clave, Descripcion, Activo)
        VALUES ('config.catalog.categories.view', 'Ver Categorias', 1)

      INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso)
      SELECT 1, IdPermiso FROM dbo.Permisos
      WHERE Clave = 'config.catalog.categories.view'
      AND NOT EXISTS (
        SELECT 1 FROM dbo.RolesPermisos rp
        WHERE rp.IdRol = 1 AND rp.IdPermiso = dbo.Permisos.IdPermiso
      )
      ```

- [x] **28.2** DB: Agregar acciones a `spCategoriaProductos` (nuevo SP):
      ```sql
      CREATE OR ALTER PROCEDURE dbo.spCategoriaProductos
        @Accion NVARCHAR(2),   -- 'LA' = listar asignados, 'LD' = listar disponibles
        @IdCategoria INT = NULL,
        @IdProducto INT = NULL,
        @IdSesion INT = NULL,
        @TokenSesion NVARCHAR(100) = NULL
      AS
      BEGIN
        SET NOCOUNT ON;

        -- LA: Listar productos ASIGNADOS a la categoria
        IF @Accion = 'LA'
        BEGIN
          SELECT P.IdProducto, P.Codigo, P.Nombre, P.Activo,
                 PT.Nombre AS TipoProducto
          FROM dbo.Productos P
          LEFT JOIN dbo.TiposProducto PT ON PT.IdTipoProducto = P.IdTipoProducto
          WHERE P.IdCategoria = @IdCategoria
            AND P.RowStatus = 1
          ORDER BY P.Nombre;
          RETURN;
        END;

        -- LD: Listar productos DISPONIBLES (sin categoria o de otra)
        IF @Accion = 'LD'
        BEGIN
          SELECT P.IdProducto, P.Codigo, P.Nombre, P.Activo,
                 PT.Nombre AS TipoProducto
          FROM dbo.Productos P
          LEFT JOIN dbo.TiposProducto PT ON PT.IdTipoProducto = P.IdTipoProducto
          WHERE (P.IdCategoria IS NULL OR P.IdCategoria != @IdCategoria)
            AND P.RowStatus = 1
          ORDER BY P.Nombre;
          RETURN;
        END;

        -- A: Asignar producto a categoria
        IF @Accion = 'A'
        BEGIN
          UPDATE dbo.Productos SET IdCategoria = @IdCategoria
          WHERE IdProducto = @IdProducto AND RowStatus = 1;
          RETURN;
        END;

        -- Q: Quitar producto de categoria (dejar sin categoria)
        IF @Accion = 'Q'
        BEGIN
          UPDATE dbo.Productos SET IdCategoria = NULL
          WHERE IdProducto = @IdProducto
            AND IdCategoria = @IdCategoria
            AND RowStatus = 1;
          RETURN;
        END;
      END;
      ```

- [x] **28.3** API: Crear endpoint `src/app/api/catalog/categories/[id]/products/route.ts`:
      - `GET` â€” llama `spCategoriaProductos` acciones `LA` y `LD` en paralelo,
        retorna `{ assigned: [...], available: [...] }`
      - `PUT` â€” body `{ action: "assign" | "remove", productId: number }`,
        llama accion `A` o `Q`

- [x] **28.4** Data layer: Agregar en `src/lib/pos-data.ts`:
      - `getCategoryProducts(categoryId)` â€” llama SP acciones LA+LD en paralelo
      - `assignProductToCategory(categoryId, productId)`
      - `removeProductFromCategory(categoryId, productId)`

- [x] **28.5** UI: Agregar tab "Productos" en `src/components/pos/catalog-categories-screen.tsx`:
      Panel derecho â€” nuevo tab **Productos** (al lado de General/POS/Imagen):
      - Sub-tabs: **Asignados** | **Disponibles**
      - Sub-tab Asignados: lista de productos con Codigo, Nombre, TipoProducto,
        boton "Quitar" por fila + boton "Quitar todos" en header.
      - Sub-tab Disponibles: lista de productos sin categoria o de otra categoria,
        boton "Asignar" por fila + boton "Asignar todos" en header.
      - Patron identico al tab Usuarios en `security-roles-screen.tsx`.
      - Sin modo "Editar Datos" â€” este tab siempre es interactivo.

- [x] **28.6** CSS + Build:
      Agregar estilos necesarios en `globals.css` (reutilizar clases existentes
      `.roles-users-*` o crear `.category-products-*` si hay diferencias).
      `npm run build` sin errores.

**Restricciones:**
- Patron de UI identico a tab Usuarios en Roles â€” no inventar nueva UX.
- La asignacion es UPDATE en `dbo.Productos.IdCategoria`, no tabla junction.
- CSS vanilla BEM. Acceso completo a DB.

| Fecha      | Tareas trabajadas | Checkpoints completados | Notas                          |
|------------|-------------------|-------------------------|--------------------------------|
| 2026-03-20 | â€”                 | â€”                       | Archivo creado, tareas listas  |
| 2026-03-20 | TAREA 1           | 1.1, 1.2, 1.3, 1.4, 1.5, 1.6 | SP aplicado en DB y build OK |
| 2026-03-20 | TAREA 2           | 2.1, 2.2, 2.3, 2.4 | SPs actualizados con contexto de sesion y build OK |
| 2026-03-20 | TAREA 3           | 3.1, 3.2, 3.3, 3.4 | Feed actividad real listo y build OK |
| 2026-03-20 | TAREA 4           | 4.1, 4.2, 4.3, 4.4, 4.5 | Matriz QA E2E entregada en markdown |
| 2026-03-20 | TAREA 5           | 5.1, 5.2, 5.3, 5.4 | Safety net superadmin + seed permisos admin aplicado |
| 2026-03-20 | TAREA 6           | 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7 | Login polished con i18n toggle y loader |
| 2026-03-20 | TAREA 7           | 7.0a, 7.0b, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6 | Users polished + bugfix idioma login/menu cortado |
| 2026-03-20 | TAREA 8           | 8.1, 8.2, 8.3, 8.4, 8.5, 8.6 | Pantalla dedicada de roles + validaciones + build OK |
| 2026-03-20 | TAREA 8 (update)  | 8.0 | Estado 3 niveles en usuarios + DB/SPs actualizados |
| 2026-03-20 | TAREA 9           | 9.1, 9.2, 9.3, 9.4, 9.5, 9.6 | Roles bugfixes + i18n + UX fila editable + build OK |
| 2026-03-20 | TAREA 9 (update)  | 9.7, 9.8, 9.9, 9.10, 9.11 | Paridad final roles/users cerrada + build OK |
| 2026-03-20 | TAREA 10          | 10.1, 10.2, 10.3, 10.4, 10.5, 10.6 | Usuarios/Roles independientes sin tabs de seguridad |
| 2026-03-20 | TAREA 11 (Fase A) | 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8 | Base DB/API completada para roles 3 paneles + build OK |
| 2026-03-20 | TAREA 11 (Fase B/C) | 11.9, 11.10, 11.11, 11.12, 11.13, 11.14, 11.15, 11.16 | Roles 3 paneles implementado (UI/CSS/i18n) + build OK |
| 2026-03-20 | TAREA 12          | 12.1, 12.2, 12.3, 12.4, 12.5, 12.6 | Fixes visuales/funcionales roles 3 paneles + build OK |
| 2026-03-20 | TAREA 13          | 13.1, 13.2, 13.3, 13.4, 13.5, 13.6 | Ajustes finales de layout/espacios + fix SP roles + build OK |
| 2026-03-20 | TAREA 14          | 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7 | UX header edit/save + seed DB data-driven + build OK |
| 2026-03-20 | TAREA 14 (update) | UX polishing post-feedback | Ajustes de proporcion visual (modulos/usuarios), grid 2 columnas responsive y fix autorizacion APIs roles |
| 2026-03-20 | TAREA 15          | 15.1, 15.2, 15.3, 15.4 | Limpieza menu/permisos de Seguridad (sin Permisos ni Roles-Permisos) + build OK |
| 2026-03-20 | TAREA 16          | 16.1, 16.2, 16.3, 16.4, 16.5 | Submenu Seguridad reducido a Usuarios/Roles + routes modules/screens retiradas + build OK |
| 2026-03-20 | TAREA 17          | 17.1, 17.2, 17.3, 17.4 | Botones asignar/quitar usuarios validados y pulidos (estados + estilo rojo/verde) + build OK |
| 2026-03-20 | TAREA 17 (update) | Hotfix post-QA | Fix parse robusto de respuesta API, rol fallback `SIN ROL` (IdRol=0), SP `spRolUsuariosAsignar` ajustado y sincronizacion de estado local/UI |
| 2026-03-20 | TAREA 17 (update 2) | UX menu account | RediseÃ±o dropdown de usuario estilo Facebook (panel oscuro + vista principal + vista Configuracion del Sistema con back) + build OK |
| 2026-03-20 | TAREA 17 (update 3) | UX menu account light | Dropdown de usuario hereda tema claro y Configuracion del Sistema vuelve a grupos colapsables (Empresa/Catalogo/Salon/Seguridad) |
| 2026-03-20 | TAREA 17 (update 4) | UX menu account flow | Configuracion del Sistema ahora navega por pantallas: root -> grupos -> detalle de grupo (sin acordeon) |
| 2026-03-20 | TAREA 17 (update 5) | UX menu chevrons | Chevron derecho en pantalla de detalle solo se muestra para items con hijos |
| 2026-03-21 | TAREA 18          | 18.1, 18.2, 18.3, 18.4, 18.5, 18.6, 18.7 | Catalogo migrado a paginas independientes (sin tabs compartidos) + build OK |
| 2026-03-21 | TAREA 19          | 19.1, 19.2, 19.3 | Fix global de toggle switches (separacion label/switch) en Login, Company, Usuarios y Roles + build OK |
| 2026-03-21 | TAREA 20          | 20.1, 20.2, 20.3, 20.4, 20.5 | Tab Formatos en Company con soporte DB/API, previews y reset + build OK |
| 2026-03-21 | TAREA 21          | 21.1, 21.2, 21.3, 21.4, 21.5 | Consolidacion de campos duplicados en Empresa (migracion previa + SP + data layer + UI) y build OK |
| 2026-03-22 | TAREA 26 v2       | 26.1, 26.2, 26.3, 26.4, 26.5, 26.6, 26.7 | Fix arquitectura permisos: columna Clave en Permisos, spPermisosObtenerPorRol retorna Clave directo, getPermissionKeysByRole simplificado, build OK |
| 2026-03-22 | TAREA 27          | 27.1, 27.2, 27.3, 27.4, 27.5, 27.6, 27.7, 27.8, 27.9, 27.10, 27.11 | FormatProvider con useFormat() creado, aplicado a pantallas de monedas, tasas, historial y usuarios. Build OK |
| 2026-03-22 | TAREA 24          | 24.1, 24.2, 24.3, 24.4, 24.5, 24.6 | Categorias reescrito con arbol jerarquico, 3 tabs (General/POS/Imagen), SP actualizado, API CRUD, pos-data nuevo, Build OK |
| 2026-03-24 | TAREA 28          | 28.1, 28.2, 28.3, 28.4, 28.5, 28.6 | Permiso DB categories.view + Tab Productos en Categorias con asignacion (LA/LD/A/Q actions), API route, Build OK |
| 2026-03-24 | TAREA 29          | 29.1, 29.2, 29.3, 29.4, 29.5 | Login split layout: panel izquierdo branding (logo/nombre/eslogan desde DB), panel derecho formulario, i18n brandTagline, Build OK |
| 2026-03-24 | TAREA 29.5       | 29.5.1, 29.5.2, 29.5.3, 29.5.4, 29.5.5, 29.5.6, 29.5.7 | Tipos de Producto rediseno 2 paneles: SP verificado, permiso existe, API routes GET/POST/PUT/DELETE, data layer getProductTypes/create/update/delete, UI component catalog-product-types-screen.tsx, pagina actualizada, Build OK |
| 2026-03-25 | TAREA 29.5 (29.5.8) | 29.5.8 | Homologacion DB: sin columnas duplicadas, columnas legacy ya limpias desde TAREA 26. TAREA 29.5 CERRADA. |
| 2026-03-25 | TAREA 32 (prep)   | â€”      | Sesion de diseno: Left Sidebar Navigation + Dashboard Landing. Tarea escrita en OPENCODE_TASKS. Logout modal + toasts con tema implementados como mejoras independientes. |

**Estado:** `COMPLETA` âœ…

**Contexto:**
- Layout actual: tarjeta centrada en fondo neutro.
- Layout deseado: 2 columnas 50/50:
  - **Panel izquierdo** â€” fondo azul oscuro (`#0f2d4a` aprox), con logo de empresa,
    nombre del negocio, tagline configurable y decoracion de fondo (patron o gradiente).
  - **Panel derecho** â€” fondo blanco/gris claro, con el formulario de login existente.
- El logo ya se carga desde `/api/company/public` â†’ `brandLogo` y `brandName` existen en el componente.
- Si no hay logo, mostrar icono `Building2` con el nombre de la empresa como fallback.
- La logica de autenticacion, cambio de password forzado y selector de idioma no cambian.
- Referencia visual: screenshot proporcionado por usuario (split azul oscuro / blanco).

**Objetos DB afectados:** Ninguno.

### Checkpoints

- [x] **29.1** CSS: Reescribir estilos de `.login-page` en `globals.css`:
      Layout split 50/50 con `display: grid; grid-template-columns: 1fr 1fr`:
      ```
      .login-page {
        display: grid;
        grid-template-columns: 1fr 1fr;
        min-height: 100vh;
      }
      /* Panel izquierdo */
      .login-brand-panel {
        background: linear-gradient(160deg, #0f2d4a 0%, #12467e 100%);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 3rem;
        position: relative;
        overflow: hidden;
      }
      /* Panel derecho */
      .login-form-panel {
        background: #f8f9fb;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 3rem;
      }
      /* Responsive: stack vertical en mobile */
      @media (max-width: 768px) {
        .login-page { grid-template-columns: 1fr; }
        .login-brand-panel { min-height: 220px; padding: 2rem; }
      }
      ```
      Eliminar estilos del layout anterior (`.login-card` como contenedor centrado flotante).

- [x] **29.2** JSX: Reestructurar `src/app/login/page.tsx`:
      Reemplazar el `<main className="login-page">` actual con:
      ```
      <main className="login-page">
        {/* Panel izquierdo â€” branding */}
        <div className="login-brand-panel">
          <div className="login-brand-panel__logo">
            {brandLogo
              ? <img src={brandLogo} alt={brandName} className="login-brand-logo" />
              : <Building2 size={64} color="#ffffff" opacity={0.9} />
            }
          </div>
          <h1 className="login-brand-panel__name">{brandName}</h1>
          <p className="login-brand-panel__tagline">{t("login.brandTagline")}</p>
        </div>

        {/* Panel derecho â€” formulario */}
        <div className="login-form-panel">
          {/* selector de idioma arriba a la derecha */}
          <div className="login-lang" ref={langMenuRef}>
            {/* ... igual que hoy ... */}
          </div>
          <section className="login-card">
            {/* ... mismo formulario que hoy sin el header de logo/nombre ... */}
          </section>
          <footer className="login-footer">
            {/* ... igual que hoy ... */}
          </footer>
        </div>
      ```
      El panel derecho NO tiene el logo ni el nombre â€” solo el formulario.
      El `login-lang` se mueve al panel derecho (esquina superior derecha de ese panel).

- [x] **29.3** CSS: Estilos del panel izquierdo:
      ```
      .login-brand-panel__logo { margin-bottom: 1.5rem; }
      .login-brand-logo { max-width: 160px; max-height: 80px; object-fit: contain; filter: brightness(0) invert(1); }
      .login-brand-panel__name { color: #ffffff; font-size: 2rem; font-weight: 700; text-align: center; margin: 0 0 0.5rem; }
      .login-brand-panel__tagline { color: rgba(255,255,255,0.7); font-size: 1rem; text-align: center; max-width: 280px; }
      ```
      Agregar decoracion sutil de fondo (patron de puntos o lineas con opacity baja).

- [x] **29.4** i18n: Agregar clave `login.brandTagline` en los archivos de traduccion:
      - ES: `"Accede a tus herramientas en un solo lugar"`
      - EN: `"Access all your tools in one place"`

- [x] **29.5** Build: `npm run build` sin errores TypeScript ni CSS.

**Restricciones:**
- NO modificar la logica de autenticacion, cambio de password ni selector de idioma.
- CSS vanilla BEM unicamente, sin Tailwind.
- El formulario del panel derecho debe quedar identico al actual en funcionalidad.
- El `login-card` puede mantener su estructura interna actual, solo cambia donde vive en el layout.

---

## TAREA 30 â€” Usuarios: Homologar a Layout 2 Paneles

**Estado:** `COMPLETADA`

**Contexto:**
- Pantalla actual: tabla full-width con toolbar arriba (busqueda + boton nuevo).
- Layout deseado: 2 paneles igual que Categorias, Listas de Precios, Tipos de Producto.
  - **Panel izquierdo (320px):** lista de usuarios con busqueda + boton `sidebar__add-btn`.
    Cada item: badge estado (Activo/Bloqueado/Inactivo), menu 3 puntos (Editar, Bloquear, Eliminar), nombre + username abajo.
  - **Panel derecho (flex-1):** detalle del usuario seleccionado con patron "Editar Datos":
    tabs General (nombre, usuario, email, rol, estado) y Actividad (feed existente).
- Referencia de patron: `price-lists-screen.tsx`, `catalog-categories-screen.tsx`.
- Componente: `src/components/pos/security-users-screen.tsx`.
- La logica de CRUD (crear, editar, bloquear, eliminar) ya existe â€” solo cambia el layout.
- CSS vanilla BEM. Clases prefijadas `.users-*` ya existen, reutilizar donde sea posible.
- Acceso completo a DB.

**Objetos DB afectados:** Ninguno (solo refactor de UI).

### Checkpoints

- [x] **30.1** Restructurar JSX: reemplazar layout tabla por 2 paneles.
      Panel izquierdo: `<aside className="users-sidebar">` con header (titulo + `sidebar__add-btn`),
      busqueda y lista de items en el patron de card igual a price-lists.
      Panel derecho: `<section className="users-detail">` con el form actual reorganizado en tabs.

- [x] **30.2** Items del sidebar: cada usuario como card con:
      - Top row: badge estado + menu 3 puntos (derecha).
      - Nombre completo (bold).
      - Username y Rol abajo (meta).
      Badge estados: Activo (verde), Bloqueado (naranja), Inactivo (gris).

- [x] **30.3** Panel derecho â€” Tab General: campos nombre, apellido, usuario, email,
      rol (dropdown), estado (switch Activo + switch Bloqueado), boton "Editar Datos" / "Guardar".

- [x] **30.4** Panel derecho â€” Tab Actividad: mover el feed de actividad existente aqui.

- [x] **30.5** CSS: agregar `.users-sidebar`, `.users-sidebar__*`, `.users-detail`, `.users-detail__*`
      siguiendo el mismo patron de espaciado y colores que `price-lists-sidebar`.

- [x] **30.6** Build: `npm run build` sin errores.

**Restricciones:**
- NO cambiar logica de negocio ni endpoints API â€” solo refactor de presentacion.
- CSS vanilla BEM. Reutilizar clases `.users-*` existentes donde sea posible.
- El modal de cambio de password forzado debe mantenerse igual.

---

## TAREA 25 â€” Productos: Modelo Expandido (Precios, Costos, Oferta, Opciones)

**Estado:** `COMPLETA` âœ…

**Contexto:**
La pantalla de productos (`src/components/pos/catalog-products-screen.tsx`) ya tiene el UI completo
con 5 pestaÃ±as (Precios y Costos, ParÃ¡metros Generales, Almacenes, Existencia, Movimientos),
implementado en sesiones anteriores siguiendo el diseÃ±o de referencia UI 4.0.

**El problema:** Los campos de las pestaÃ±as Precios y Costos, y las opciones de ParÃ¡metros,
viven solo en estado local React y NO se persisten en DB cuando se guarda.
Solo se guardan los campos base que ya existÃ­an en `spProductosCRUD`:
nombre, descripcion, categorÃ­a, tipo, unidades, precio (solo el primero), activo.

**Objetivo:** Crear las tablas y SPs necesarios, expandir `spProductosCRUD`, y conectar
el frontend para que TODO lo que el usuario ingresa en las pestaÃ±as se persista correctamente.

**Archivos clave:**
- `src/components/pos/catalog-products-screen.tsx` â€” UI ya completo, solo conectar al API
- `src/lib/pos-data.ts` â€” tipos `ProductRecord`, `CatalogManagerData`, funciones de mutaciÃ³n
- `src/app/api/catalog/products/route.ts` â€” endpoint POST/PUT/DELETE
- `database/` â€” scripts numerados a partir de 34

---

### Estado actual del schema (tabla `Productos`)

Columnas que YA existen (confirmadas vÃ­a `spProductosCRUD`):
`IdProducto, IdCategoria, IdTipoProducto, IdUnidadMedidaBase, IdUnidadMedidaVenta,
IdUnidadMedidaCompra, IdUnidadAlterna1, IdUnidadAlterna2, IdUnidadAlterna3,
Nombre, Descripcion, Precio, Activo, RowStatus, FechaCreacion, UsuarioCreacion,
FechaModificacion, UsuarioModificacion`

Columnas que FALTAN (a agregar en esta tarea):
`AplicaImpuesto BIT, TasaImpuesto DECIMAL(5,2), UnidadBaseExistencia NVARCHAR(20),
SeVendeEnFactura BIT, PermiteDescuento BIT, PermiteCambioPrecio BIT,
PermitePrecioManual BIT, PideUnidad BIT, PermiteFraccionesDecimales BIT,
VenderSinExistencia BIT, AplicaPropina BIT, ManejaExistencia BIT`

---

### Tablas nuevas a crear

**`ProductoPrecios`** â€” Un registro por producto por lista de precios:
```sql
IdProductoPrecio  INT IDENTITY PK
IdProducto        INT FK â†’ Productos
IdListaPrecio     INT FK â†’ ListasPrecios
PorcentajeGanancia DECIMAL(18,4) DEFAULT 0
Precio            DECIMAL(18,4) DEFAULT 0
Impuesto          DECIMAL(18,4) DEFAULT 0
PrecioConImpuesto DECIMAL(18,4) DEFAULT 0
RowStatus BIT, FechaCreacion DATETIME, UsuarioCreacion INT,
FechaModificacion DATETIME, UsuarioModificacion INT
UNIQUE (IdProducto, IdListaPrecio)
```

**`ProductoCostos`** â€” Un registro por producto (Ãºltima compra):
```sql
IdProductoCosto   INT IDENTITY PK
IdProducto        INT FK â†’ Productos UNIQUE
IdMoneda          INT NULL FK â†’ Monedas
DescuentoProveedor    DECIMAL(18,4) DEFAULT 0
CostoProveedor        DECIMAL(18,4) DEFAULT 0
CostoConImpuesto      DECIMAL(18,4) DEFAULT 0
CostoPromedio         DECIMAL(18,4) DEFAULT 0
PermitirCostoManual   BIT DEFAULT 0
RowStatus BIT, FechaCreacion DATETIME, UsuarioCreacion INT,
FechaModificacion DATETIME, UsuarioModificacion INT
```

**`ProductoOfertas`** â€” Un registro por producto (oferta vigente):
```sql
IdProductoOferta  INT IDENTITY PK
IdProducto        INT FK â†’ Productos UNIQUE
Activo            BIT DEFAULT 0
PrecioOferta      DECIMAL(18,4) DEFAULT 0
FechaInicio       DATE NULL
FechaFin          DATE NULL
RowStatus BIT, FechaCreacion DATETIME, UsuarioCreacion INT,
FechaModificacion DATETIME, UsuarioModificacion INT
```

---

### Checkpoints

- [x] **25.1** DB â€” Script `36_productos_modelo_expandido.sql` â€” ESCRITO por Claude Code.
  Incluye: DROP COLUMN Precio, ADD 12 columnas nuevas a Productos, CREATE ProductoPrecios,
  CREATE ProductoCostos, CREATE ProductoOfertas, FK a TasasImpuesto.

- [x] **25.2** DB â€” Script `37_productos_sps_expandidos.sql` â€” ESCRITO por Claude Code.
  Incluye: CREATE OR ALTER spProductosCRUD (expandido con L/O/I/A/D),
  CREATE spProductosPreciosCRUD (G/U), CREATE spProductosCostosCRUD (G/U),
  CREATE spProductosOfertasCRUD (G/U).

- [x] **25.3** Ejecutar scripts `36_` y `37_` en `DbMasuPOS` via `sqlcmd`.
  Verificar con:
  ```sql
  SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
  WHERE TABLE_NAME IN ('ProductoPrecios','ProductoCostos','ProductoOfertas');

  SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME='Productos' AND COLUMN_NAME='AplicaImpuesto';
  ```

- [x] **25.4** `src/lib/pos-data.ts` â€” Expandir tipos y funciones:
  - Extender `ProductRecord` con todos los nuevos campos:
    ```typescript
    applyTax: boolean
    taxRate: number           // porcentaje, ej: 18
    stockUnitBase: string     // "measure"|"purchase"|"alternate1"|"alternate2"|"alternate3"
    // options
    canSellInBilling: boolean
    allowDiscount: boolean
    allowPriceChange: boolean
    allowManualPrice: boolean
    requestUnit: boolean
    allowDecimals: boolean
    sellWithoutStock: boolean
    applyTip: boolean
    managesStock: boolean
    // precios por lista (array)
    prices: Array<{ priceListId: number; profitPercent: number; price: number; tax: number; priceWithTax: number }>
    // costos
    costs: {
      currencyId: number | null
      providerDiscount: number
      providerCost: number
      providerCostWithTax: number
      averageCost: number
      allowManualAvgCost: boolean
    }
    // oferta
    offer: { active: boolean; price: number; startDate: string; endDate: string }
    ```
  - Actualizar `mapProductRow()` para leer las nuevas columnas. Los sub-objetos `prices`,
    `costs` y `offer` se cargan desde los nuevos SPs en `getProductById(id)`.
  - Crear funciÃ³n `getProductById(id: number): Promise<ProductRecord>` que llama
    spProductosCRUD 'O' + spProductosPreciosCRUD 'G' + spProductosCostosCRUD 'G' + spProductosOfertasCRUD 'G'
    en paralelo con `Promise.all` y ensambla el resultado.
  - Actualizar `createProduct()` y `updateProduct()` para:
    1. Llamar `spProductosCRUD` 'I'/'A' con todos los campos expandidos.
    2. Por cada fila de precios recibida: llamar `spProductosPreciosCRUD` 'U'.
    3. Llamar `spProductosCostosCRUD` 'U'.
    4. Llamar `spProductosOfertasCRUD` 'U'.
    5. Retornar `getProductById(id)` para devolver el record completo.

- [x] **25.5** `src/app/api/catalog/products/route.ts` â€” Expandir los handlers:
  - POST body: agregar todos los campos nuevos (`applyTax`, `taxRate`, `stockUnitBase`,
    las 9 opciones booleanas, array `prices[]`, objeto `costs`, objeto `offer`).
  - PUT body: igual.
  - Pasar todos los campos a `createProduct()`/`updateProduct()`.
  - Asegurarse que `prices` sea un array, que `costs` y `offer` sean objetos; si vienen
    undefined usar defaults (array vacÃ­o / objeto con ceros).

- [x] **25.6** `src/components/pos/catalog-products-screen.tsx` â€” Conectar local state al API:
  - En `onSubmit`: incluir en el `payload` todos los estados locales actuales:
    `applyTax`, `taxRateId` (como nÃºmero), `baseUnitForStock`, las 9 opciones de `options`,
    el array `prices` completo, el objeto `costs` (con currencyId como nÃºmero), el objeto `offer`.
  - En `recordToForm()` y en el `useEffect` que inicializa el estado al seleccionar un producto:
    poblar `prices`, `costs`, `offer`, `options`, `applyTax`, `taxRateId`, `baseUnitForStock`
    desde `selected.prices`, `selected.costs`, `selected.offer`, `selected.options`, etc.
    (ya no usar defaults hardcodeados cuando hay datos del servidor).
  - Eliminar los comentarios `// not yet persisted to DB` del componente.

- [x] **25.7** `src/app/config/catalog/products/page.tsx` â€” El `getCatalogManagerData()`
  ya carga la lista. Verificar que al seleccionar un producto desde el sidebar se haga
  un fetch a `/api/catalog/products/:id` para cargar el record completo con precios/costos/oferta.
  Si el detail panel carga desde el array de la lista (que no tiene sub-entidades), agregar
  un `useEffect` que haga `GET /api/catalog/products/:id` al seleccionar y actualice el estado
  del form con los datos completos. Agregar endpoint `GET /api/catalog/products/[id]/route.ts`
  que llame `getProductById(id)`.

- [x] **25.8** Build: `npm run build` sin errores.

- [x] **25.9** Checkpoint DB â€” HomologaciÃ³n:
  ```sql
  -- Verificar que las tablas tienen PK y no hay columnas huerfanas
  SELECT t.TABLE_NAME, COUNT(c.COLUMN_NAME) AS columnas
  FROM INFORMATION_SCHEMA.TABLES t
  JOIN INFORMATION_SCHEMA.COLUMNS c ON c.TABLE_NAME = t.TABLE_NAME
  WHERE t.TABLE_NAME IN ('ProductoPrecios','ProductoCostos','ProductoOfertas')
  GROUP BY t.TABLE_NAME;

  -- Verificar FKs
  SELECT fk.name, tp.name AS tabla_padre, tc.name AS tabla_hija
  FROM sys.foreign_keys fk
  JOIN sys.tables tp ON fk.referenced_object_id = tp.object_id
  JOIN sys.tables tc ON fk.parent_object_id = tc.object_id
  WHERE tc.name IN ('ProductoPrecios','ProductoCostos','ProductoOfertas');
  ```

**Objetos DB afectados:**

| Objeto | Tipo | Accion |
|--------|------|--------|
| dbo.Productos | TABLE | ALTER â€” 12 columnas nuevas |
| dbo.ProductoPrecios | TABLE | CREATE |
| dbo.ProductoCostos | TABLE | CREATE |
| dbo.ProductoOfertas | TABLE | CREATE |
| dbo.spProductosCRUD | SP | ALTER â€” parametros y SELECT expandidos |
| dbo.spProductosPreciosCRUD | SP | CREATE |
| dbo.spProductosCostosCRUD | SP | CREATE |
| dbo.spProductosOfertasCRUD | SP | CREATE |

**Restricciones:**
- La accion `'L'` de `spProductosCRUD` NO cambia â€” solo retorna campos base para el sidebar.
  El detalle completo solo se carga con `'O'` (por ID).
- Los nuevos parametros de `'I'` y `'A'` deben ser todos opcionales (`= NULL`) para
  mantener retrocompatibilidad con cualquier llamada existente.
- No cambiar el CSS ni el layout del componente â€” solo conectar datos.
- Usar `Promise.all` en `getProductById` para no serializar las 4 llamadas a DB.
- El array `prices` en el payload puede tener 0 filas si no hay listas de precios configuradas;
  el SP `spProductosPreciosCRUD` debe tolerarlo sin error.

---

## TAREA 31 â€” Productos: Reemplazar TAX_RATES Hardcodeado con Datos de DB

**Estado:** `COMPLETA` âœ…

**Contexto:**
En `src/components/pos/catalog-products-screen.tsx` existe una constante hardcodeada:
```typescript
const TAX_RATES = [
  { id: "1", name: "Exento", rate: 0 },
  { id: "2", name: "ITBIS 18%", rate: 18 },
  { id: "3", name: "ITBIS 16%", rate: 16 },
]
```
Esta constante se usÃ³ como puente hasta tener la tabla `TasasImpuesto` en DB.
La tabla ya existe (creada en script 34) y tiene su propio CRUD completo.
`taxRateId` ahora es un ID real de DB (nÃºmero), no una cadena de porcentaje.

**Objetivo:** Cargar las tasas de impuesto desde DB via `CatalogManagerData.lookups.taxRates`
y eliminar la constante hardcodeada del componente.

---

### Checkpoints

- [x] **31.1** `src/lib/pos-data.ts` â€” Agregar `taxRates` a `CatalogManagerData`:
  - En el tipo `CatalogManagerData`, agregar al objeto `lookups`:
    ```typescript
    taxRates: Array<{ id: number; name: string; rate: number; code: string }>
    ```
  - En `getCatalogManagerData()`, agregar al `Promise.all`:
    ```typescript
    pool.request().input("Accion", "L").execute("dbo.spTasasImpuestoCRUD").catch(() => ({ recordset: [] })),
    ```
  - Mapear el resultado a `taxRates` en el objeto `lookups` retornado.

- [x] **31.2** `src/components/pos/catalog-products-screen.tsx`:
  - Eliminar la constante `TAX_RATES` (lÃ­neas con el array hardcodeado).
  - Reemplazar todos los usos de `TAX_RATES` con `data.lookups.taxRates`.
  - `currentRate()` debe buscar en `data.lookups.taxRates` por `r.id === Number(taxRateId)`.
  - El `<select>` de tasa debe iterar `data.lookups.taxRates`.
  - `taxRateId` inicial: usar el ID de la primera tasa activa o vacÃ­o si no hay ninguna.

- [x] **31.3** Build: `npm run build` sin errores.

**Archivos afectados:**
- `src/lib/pos-data.ts`
- `src/components/pos/catalog-products-screen.tsx`

**Restricciones:**
- No cambiar el CSS ni el layout.
- No tocar los SPs ni la DB.
- `taxRateId` debe seguir siendo `string` en el estado local del componente (para el `<select>`),
  pero compararse con `Number(taxRateId)` al buscar en el array.

---

## TAREA 32 â€” Left Sidebar Navigation + Dashboard Landing

**Estado:** `COMPLETA` âœ…

**Prerequisitos:** Ninguno. Puede ejecutarse como siguiente tarea.

### Objetivo

Reemplazar la navegaciÃ³n horizontal del topbar por un sidebar izquierdo con jerarquÃ­a MÃ³dulo â†’ CategorÃ­a â†’ OpciÃ³n. Agregar pantalla Dashboard como landing. Usar `IdPantallaInicio` del usuario como ruta de inicio post-login.

### Contexto clave

- `AppShell`: `src/components/pos/app-shell.tsx` â€” topnav horizontal a eliminar. LÃ³gica de `settingsGroups`/`systemPanel` del user-menu tambiÃ©n se elimina (va al sidebar).
- `navigation.ts`: `src/lib/navigation.ts` â€” lista plana, reemplazar.
- `AuthSession.defaultRoute` (`src/lib/auth-session.ts` lÃ­nea 54): ya viene del SP `spAuthValidarSesion` â†’ `RutaInicio` (join `Usuarios.IdPantallaInicio` â†’ `Pantallas.Ruta`). Actualmente no se usa para redirigir post-login.
- Tabla `Pantallas` en DB: rutas legacy con mayÃºscula (`/Usuarios`, `/Roles`). Necesitan mapa de compatibilidad a rutas V2.
- BotÃ³n logout con modal ya estÃ¡ implementado en AppShell (TAREA 32 prep âœ…).
- Toasts con tema ya implementados (TAREA 32 prep âœ…).

### Layout objetivo

```
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  [Logo] [Brand]            [Search]  [Bell]  [User] [â†’] â”‚  topbar 56px fijo
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                   â”‚                                      â”‚
â”‚  sidebar-left     â”‚   main-content (scrollable)          â”‚
â”‚  220px expandido  â”‚                                      â”‚
â”‚   56px colapsado  â”‚                                      â”‚
â”‚  [â‰¡] toggle       â”‚                                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”´â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

**Reglas de navegaciÃ³n:**
- **MÃ³dulo sin categorÃ­as** â†’ `<Link>` directo al hacer clic.
- **MÃ³dulo con categorÃ­as** â†’ accordion in-place, NO navega Ã©l mismo.
- **CategorÃ­a** â†’ solo label uppercase, NO clickeable.
- **OpciÃ³n** â†’ `<Link href>`, Ãºnico elemento que abre pantalla.
- Colapsado: solo iconos, `title` tooltip en hover.
- Estado colapso persistido en `localStorage("masu_sidebar_collapsed")`.
- Mobile (< 768px): colapsado por defecto.

### MÃ³dulos iniciales

```
Dashboard     â†’ /dashboard     (sin categorÃ­as)
Pedidos       â†’ /orders
SalÃ³n         â†’ /dining-room
Caja          â†’ /cash-register
Reportes      â†’ /reports
Consultas     â†’ /queries
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€  (divider)
ConfiguraciÃ³n  (con categorÃ­as):
  EMPRESA
    Datos Generales â†’ /config/company
    Divisiones      â†’ /config/company/divisions
    Sucursales      â†’ /config/company/branches
    Puntos EmisiÃ³n  â†’ /config/company/emission-points
    Almacenes       â†’ /config/company/warehouses
    Tasas Impuesto  â†’ /config/company/tax-rates
  CATÃLOGO
    Productos       â†’ /config/catalog/products
    CategorÃ­as      â†’ /config/catalog/categories
    Tipos           â†’ /config/catalog/product-types
    Unidades        â†’ /config/catalog/units
    Listas Precios  â†’ /config/catalog/price-lists
  MONEDAS
    Monedas         â†’ /config/currencies
    Tasas de Cambio â†’ /config/currencies/rates
    HistÃ³rico       â†’ /config/currencies/history
  SEGURIDAD
    Usuarios        â†’ /config/security/users
    Roles           â†’ /config/security/roles
```

### Checkpoints

- [x] **32.1** Crear `src/lib/navigation-config.ts`
  - Tipos: `NavOption`, `NavCategory`, `NavModule` (con `href` opcional si sin categorÃ­as).
  - Exportar `NAV_MODULES: NavModule[]` con todos los mÃ³dulos del sistema (tabla arriba).
  - Cada item con `permission?: string` para filtrar con `hasPermission()`.
  - `navigation.ts` existente: agregar comentario `// deprecated â€” ver navigation-config.ts`.

- [x] **32.2** Crear pÃ¡gina `/dashboard`
  - `src/app/dashboard/page.tsx` â€” server component, protegida.
  - Contenido: 4 tarjetas KPI placeholder (Ventas del dÃ­a, Pedidos activos, Mesas ocupadas, Stock crÃ­tico). Sin datos reales aÃºn â€” solo estructura visual con `AppShell` + `PageHeader`.
  - Permiso: `dashboard.view`. Agregar en `src/lib/permissions.ts` â†’ `ROUTE_PERMISSIONS`.
  - DB: `INSERT` en `Permisos` (Clave=`dashboard.view`) + `INSERT` en `RolesPermisos` para `IdRol=1`.

- [x] **32.3** Redirigir post-login a `defaultRoute`
  - Encontrar dÃ³nde se hace el redirect tras login exitoso (probablemente en `src/app/api/auth/login/route.ts` o en el cliente).
  - Usar `session.defaultRoute` en vez de `/` fijo.
  - Si vacÃ­o o nulo â†’ fallback `/dashboard`.
  - Diccionario de compatibilidad rutas legacy:
    ```ts
    const LEGACY_ROUTE_MAP: Record<string, string> = {
      "/":          "/dashboard",
      "/Usuarios":  "/config/security/users",
      "/Roles":     "/config/security/roles",
      "/Permisos":  "/config/security/roles",
    }
    ```

- [x] **32.4** Crear `src/components/pos/sidebar-nav.tsx`
  - `"use client"`.
  - Props: `modules: NavModule[]`, `pathname: string`.
  - Estado interno: `collapsed` (init desde `localStorage`), `expandedModule` (string key del mÃ³dulo abierto).
  - Toggle colapso: botÃ³n `[â‰¡]` en header del sidebar, persiste en `localStorage`.
  - MÃ³dulo activo: el que contiene la opciÃ³n cuyo `href === pathname` (o `pathname.startsWith(href)` para mÃ³dulos directos).
  - Accordion: al hacer clic en mÃ³dulo con categorÃ­as â†’ toggle `expandedModule`. Auto-expande si alguna opciÃ³n hija es la ruta activa.
  - Filtrar mÃ³dulos y opciones con `hasPermission()` del contexto.
  - Colapsado: mostrar solo iconos, ocultar textos con `overflow: hidden` y ancho del sidebar, no `display:none` (para transiciÃ³n CSS).

- [x] **32.5** Actualizar `AppShell`
  - Eliminar `<nav className="topnav">` del topbar.
  - Eliminar estados: `systemPanel`, `selectedSettingsGroup`, `activeChildren`, `parentGroup`, `settingsGroups`.
  - Eliminar toda la lÃ³gica del dropdown de configuraciÃ³n del user-menu.
  - User-menu queda solo con: perfil (placeholder) + idioma + (logout ya en topbar).
  - Renderizar `<SidebarNav modules={NAV_MODULES} pathname={pathname} />` entre header y main.
  - Imports limpiar: quitar iconos no usados.

- [x] **32.6** CSS en `globals.css`
  - Grid del app-shell:
    ```css
    .app-shell {
      display: grid;
      grid-template-rows: 56px 1fr;
      grid-template-columns: var(--sidebar-w) 1fr;
      height: 100dvh;
    }
    .topbar  { grid-column: 1 / -1; }
    .sidebar { grid-row: 2; grid-column: 1; }
    .app-main { grid-row: 2; grid-column: 2; overflow-y: auto; }
    ```
  - Variables: `--sidebar-w: 220px` expandido â†’ `56px` colapsado con `transition: 200ms ease`.
  - Clases BEM: `.sidebar`, `.sidebar--collapsed`, `.sidebar__toggle`, `.sidebar__module`, `.sidebar__module-header`, `.sidebar__module-header.is-active`, `.sidebar__category`, `.sidebar__option`, `.sidebar__option.is-active`, `.sidebar__divider`.
  - Mobile `< 768px`: `--sidebar-w: 0` por defecto, overlay al abrir.

- [x] **32.7** Middleware + redirect raÃ­z
  - `middleware.ts`: agregar `/dashboard` a rutas protegidas.
  - Redirect `/` â†’ `/dashboard`.

- [x] **32.8** Build: `npm run build` sin errores.

**Archivos afectados:**
- `src/lib/navigation-config.ts` (nuevo)
- `src/lib/navigation.ts` (deprecar)
- `src/lib/permissions.ts`
- `src/app/dashboard/page.tsx` (nuevo)
- `src/app/api/auth/login/route.ts` (o cliente login)
- `src/components/pos/sidebar-nav.tsx` (nuevo)
- `src/components/pos/app-shell.tsx`
- `src/app/globals.css`
- `middleware.ts`

**Restricciones:**
- CSS vanilla BEM en `globals.css`. NO Tailwind, NO CSS modules.
- Usar tokens existentes: `var(--brand)`, `var(--line)`, `var(--ink)`, `var(--muted)`.
- El dropdown de configuraciÃ³n del user-menu se elimina completamente â€” su contenido va al sidebar.
- `NavModule` con `href` directo NO debe tener `categories`. Validar en tiempo de desarrollo con TypeScript discriminated union si es posible.
- Referencia visual para sidebar: `price-lists-screen.tsx` (sidebar izquierdo + detalle derecho).

---

## AJUSTE PERF PRODUCTOS â€” BÃºsqueda remota + CÃ³digo/Barra (2026-03-26)

**Estado:** `COMPLETA` âœ…

- [x] Evitar carga masiva inicial de productos en `getCatalogManagerData()`.
- [x] Crear bÃºsqueda server-side `GET /api/catalog/products?q=&limit=`.
- [x] Soportar filtro por `Nombre`, `Descripcion` y `Codigo` (barcode = code).
- [x] Agregar campo `Codigo / Barra` en formulario de producto y persistencia.
- [x] Ajustar sidebar de productos para bÃºsqueda remota con debounce.
- [x] Build: `npm run build` sin errores.

---

## AJUSTE CAMPOS PRODUCTOS â€” DescripciÃ³n/Referencia/Comentario (2026-03-26)

**Estado:** `COMPLETA` âœ…

- [x] Alinear semÃ¡ntica de campos:
  - `Nombre` (tabla) se usa como **DescripciÃ³n** (100)
  - `Descripcion` (tabla) se usa como **Referencia** (100)
- [x] Agregar columna `Comentario` (texto largo) en `Productos`.
- [x] Actualizar API/UI para enviar/mostrar:
  - `Descripcion` (principal)
  - `Referencia`
  - `Comentario`
- [x] Mantener bÃºsqueda por descripciÃ³n/referencia/cÃ³digo.
- [x] Build: `npm run build` sin errores.

---

## AJUSTE PRODUCTOS â€” CÃ³digo/Barra Ãºnico (2026-03-26)

**Estado:** `COMPLETA` âœ…

- [x] Validar unicidad de cÃ³digo/barra al guardar (create/update).
- [x] Crear Ã­ndice Ãºnico filtrado en DB para cÃ³digo activo.
- [x] Mantener mensaje claro al usuario si el cÃ³digo ya existe.
- [x] Build: `npm run build` sin errores.

---

## AJUSTE PRODUCTOS â€” BÃºsqueda por SP dedicado (2026-03-26)

**Estado:** `COMPLETA` âœ…

- [x] Crear `dbo.spBuscarProductos(@Busqueda, @Top)`.
- [x] Prioridad de bÃºsqueda: CÃ³digo -> DescripciÃ³n -> Referencia -> cualquiera de los 3.
- [x] Conectar API/app para que la bÃºsqueda de productos ejecute el SP.
- [x] Mantener ejecuciÃ³n por botÃ³n `Buscar` (submit explÃ­cito).
- [x] Build: `npm run build` sin errores.

---

## AJUSTE INVENTARIO â€” Limites por Almacen (2026-03-26)

**Estado:** `COMPLETA` âœ…

- [x] Unificar `dbo.spProductoAlmacenesLimitesCRUD` con acciones estilo CRUD (`L/O/I/A/D/U`).
- [x] Mantener compatibilidad con `U` (upsert).
- [x] Agregar opciÃ³n `Minimo, Maximo, Reorden` en `Inventario >> Maestros`.
- [x] Crear ruta ` /config/catalog/stock-limits ` para evitar enlace roto.
- [x] Build: `npm run build` sin errores.

---

## AJUSTE UX (POST-TAREA 32) â€” Shell ERP 3 niveles (2026-03-26)

**Estado:** `COMPLETA` âœ…

- [x] Migrar navegaciÃ³n a fuente Ãºnica en `src/lib/navigation.ts` con jerarquÃ­a `Modulo > Categoria > Opcion`.
- [x] Separar shell en componentes reutilizables: `topbar.tsx`, `sidebar.tsx`, `breadcrumbs.tsx`.
- [x] Topbar ERP contextual:
  - toggle sidebar
  - busqueda global con hint `Ctrl+K`
  - selector empresa
  - selector sucursal
  - notificaciones + ayuda
  - menu usuario con `Cerrar sesion` dentro del dropdown
- [x] Sidebar 3 niveles con estados activos por modulo/categoria/opcion.
- [x] Sidebar colapsado con submenu flotante por hover/click.
- [x] Breadcrumb funcional `Modulo / Categoria / Opcion` arriba del contenido.
- [x] Filtrado por permisos sin renderizar modulos/categorias vacias.
- [x] Build: `npm run build` sin errores.

---

## TAREA 33 â€” Existencias por AlmacÃ©n (Tab Existencia en Productos)

**Estado:** `COMPLETA` âœ…

**Fecha planificada:** 2026-03-26

**Contexto:**
- `ProductoAlmacenes` ya existe con saldo corriente (`Cantidad`, `CantidadReservada`, `CantidadTransito`).
- Productos tienen hasta 3 unidades alternas (`IdUnidadAlterna1/2/3`) con factor `BaseA/BaseB` en `UnidadesMedida`.
- El tab Existencia actual solo muestra Cantidad editable inline â€” se reemplaza por tabla completa read-only.
- El tab Movimientos sigue como placeholder (requiere modulo de compras/entradas).

**Enfoque de performance:**
- Running balance: `ProductoAlmacenes.Cantidad` es el saldo vivo. Las queries son O(1) por producto/almacen.
- No se recalcula desde transacciones â€” es la arquitectura correcta para POS.
- SP parametrico `@IdProducto` con JOINs directos a las tablas de saldo, limites y unidades.

**Objetos DB afectados:**
| Objeto | Tipo | Accion |
|--------|------|--------|
| `dbo.ProductoAlmacenesLimites` | Tabla | CREATE |
| `dbo.spProductoAlmacenesLimitesCRUD` | SP | CREATE |
| `dbo.spProductoExistencias` | SP | CREATE |

---

### Fase A â€” DB

- [x] **33.1** DB: Crear tabla `dbo.ProductoAlmacenesLimites`:
      ```sql
      CREATE TABLE dbo.ProductoAlmacenesLimites (
        IdProductoAlmacenLimite INT IDENTITY(1,1) PRIMARY KEY,
        IdProducto              INT NOT NULL,
        IdAlmacen               INT NOT NULL,
        Minimo                  DECIMAL(18,4) NOT NULL DEFAULT 0,
        Maximo                  DECIMAL(18,4) NOT NULL DEFAULT 0,
        PuntoReorden            DECIMAL(18,4) NOT NULL DEFAULT 0,
        RowStatus               BIT NOT NULL DEFAULT 1,
        FechaCreacion           DATETIME DEFAULT GETDATE(),
        UsuarioCreacion         INT NULL,
        FechaModificacion       DATETIME NULL,
        UsuarioModificacion     INT NULL,
        CONSTRAINT UQ_ProductoAlmacenLimites UNIQUE (IdProducto, IdAlmacen),
        CONSTRAINT FK_PAL_Producto FOREIGN KEY (IdProducto) REFERENCES dbo.Productos(IdProducto),
        CONSTRAINT FK_PAL_Almacen  FOREIGN KEY (IdAlmacen)  REFERENCES dbo.Almacenes(IdAlmacen)
      );
      ```

- [x] **33.2** DB: Crear SP `dbo.spProductoAlmacenesLimitesCRUD`:
      Acciones:
      - `L` â€” Listar limites de un producto (`@IdProducto`). Retorna todos los almacenes asignados con sus limites (LEFT JOIN a `ProductoAlmacenesLimites`).
      - `U` â€” Upsert: si existe fila para (IdProducto, IdAlmacen) â†’ UPDATE; si no â†’ INSERT.
        Parametros: `@IdProducto`, `@IdAlmacen`, `@Minimo`, `@Maximo`, `@PuntoReorden`, `@IdSesion`, `@TokenSesion`.

- [x] **33.3** DB: Crear SP `dbo.spProductoExistencias`:
      Parametros: `@IdProducto INT`, `@IdSesion INT = NULL`, `@TokenSesion NVARCHAR(100) = NULL`.

      Retorna una fila por almacen asignado al producto (`ProductoAlmacenes.RowStatus = 1`):

      **Columnas de almacen:**
      - `IdAlmacen`, `NombreAlmacen`

      **Columnas de limites** (de `ProductoAlmacenesLimites`, NULL si no existen):
      - `Minimo`, `Maximo`, `PuntoReorden`

      **Columnas de stock** (de `ProductoAlmacenes`):
      - `Existencia` = `Cantidad`
      - `PendienteRecibir` = 0 (placeholder hasta modulo compras)
      - `PendienteEntregar` = 0 (placeholder hasta modulo ventas pendientes)
      - `ExistenciaReal` = `Cantidad + CantidadTransito`
      - `Reservado` = `CantidadReservada`
      - `DisponibleBase` = `Cantidad - CantidadReservada`

      **Columnas de unidad base** (JOIN `UnidadesMedida` via `Productos.IdUnidadVenta`):
      - `IdUnidadVenta`, `NombreUnidadVenta`, `AbreviaturaUnidadVenta`

      **Columnas por unidad alterna** (LEFT JOIN â€” solo si `IdUnidadAlternaX IS NOT NULL`):
      Para cada alterna (1, 2, 3):
      - `IdUnidadAlternaX`, `NombreAlternaX`, `AbreviaturaAlternaX`
      - `BaseAX`, `BaseBX` (factor de conversion de `UnidadesMedida`)
      - `DisponibleAlternaX` = `FLOOR(DisponibleBase / (BaseAX / BaseBX))`

      Logica: si el producto tiene `IdUnidadAlterna1 = NULL`, la columna retorna NULL y la UI omite esa columna.

      Ordenar por `al.Nombre ASC`.

---

### Fase B â€” Data Layer y API

- [x] **33.4** Data layer (`src/lib/pos-data.ts`): Agregar tipo `ProductStockRow`:
      ```ts
      type ProductStockRow = {
        warehouseId: number
        warehouseName: string
        minimo: number | null
        maximo: number | null
        puntoReorden: number | null
        existencia: number
        pendienteRecibir: number
        pendienteEntregar: number
        existenciaReal: number
        reservado: number
        disponibleBase: number
        // Unidad venta
        unitName: string
        unitAbbrev: string
        // Alternas (null si no aplica)
        alterna1?: { name: string; abbrev: string; disponible: number } | null
        alterna2?: { name: string; abbrev: string; disponible: number } | null
        alterna3?: { name: string; abbrev: string; disponible: number } | null
      }
      ```
      Agregar funcion `getProductStock(productId: number): Promise<ProductStockRow[]>`.
      Ejecuta `spProductoExistencias` con fallback mssql estandar del proyecto.

- [x] **33.5** API: Crear `src/app/api/catalog/products/[id]/stock/route.ts`:
      - `GET` â†’ `requireApiSession` â†’ `getProductStock(id)` â†’ `{ ok: true, stock: ProductStockRow[] }`.
      - `export const dynamic = "force-dynamic"`.

---

### Fase C â€” UI

- [x] **33.6** UI (`src/components/pos/catalog-products-screen.tsx`): Reemplazar el tab Existencia:

      **Estado nuevo:**
      ```ts
      const [productStock, setProductStock] = useState<ProductStockRow[]>([])
      const [loadingStock, setLoadingStock] = useState(false)
      ```

      **Carga:** en `handleTabChange("existencia")` â†’ fetch `GET /api/catalog/products/{id}/stock`.
      Tambien en el botton "Actualizar".

      **Tabla read-only:**
      - Una fila por almacen asignado.
      - Columnas fijas: Almacen, Minimo, Maximo, Reorden, Existencia, Existencia Real, Reservado, Disponible (unidad base con abreviatura en header).
      - Columnas dinamicas: por cada alterna distinta de null en el primer row â†’ agregar columna "Disponible {abreviatura}".
      - Footer con totales de columnas numericas.
      - Badge de alerta si `existencia < puntoReorden` (cuando reorden > 0).
      - Spinner mientras carga, empty state si no hay almacenes asignados.

      **Boton "Actualizar"** en el header del tab (icono `RefreshCw`).

- [x] **33.7** CSS (`src/app/globals.css`): Agregar clases necesarias:
      - `.products-stock-table-wrap` â€” wrapper con scroll horizontal.
      - `.products-stock-badge--alert` â€” fondo amarillo tenue para fila con existencia baja.
      - `.products-stock-footer` â€” fila de totales con fondo muted y font-weight bold.
      Reutilizar clases existentes `.data-table`, `.detail-empty` para estados vacios.

- [x] **33.8** Build: `npm run build` sin errores.

**Restricciones:**
- Tab Existencia: read-only, sin edicion inline (se elimina la edicion de Cantidad que existe actualmente).
- Tab Movimientos: mantener placeholder "Proxima version" â€” requiere modulo de compras/entradas.
- CSS vanilla BEM. No Tailwind.
- Columnas de unidades alternas: dinamicas segun el producto â€” NO hardcoded.
- El SP debe funcionar aunque el producto no tenga limites definidos (LEFT JOIN, retorna NULL en Minimo/Maximo/Reorden).
- Usar fallback mssql estandar del proyecto en todas las funciones nuevas del data layer.


---

## CONVENCIÃ“N GLOBAL â€” Campos de Control (aplica desde aquÃ­ en adelante)

Todas las tablas DB deben incluir estos 6 campos de control sin excepciÃ³n:

```sql
Activo               BIT      NOT NULL DEFAULT 1,
RowStatus            TINYINT  NOT NULL DEFAULT 1,
FechaCreacion        DATETIME NOT NULL DEFAULT GETDATE(),
UsuarioCreacion      INT      NULL,
FechaModificacion    DATETIME NULL,
UsuarioModificacion  INT      NULL
```

Los SPs deben recibir `@UsuarioSesion INT = NULL` y `@IdSesion INT = NULL`.
En INSERT poblar `FechaCreacion = GETDATE(), UsuarioCreacion = @UsuarioSesion`.
En UPDATE/DELETE poblar `FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioSesion`.

---

## TAREA 34 â€” Estructura Base: MÃ³dulos CxC + CxP + Documentos Identidad en Empresa

**Estado:** `COMPLETA` âœ…

**Objetivo:**
1. Registrar mÃ³dulos "Cuentas por Cobrar" y "Cuentas por Pagar" en la navegaciÃ³n.
2. Agregar "Referencias >> Documentos Identidad" en el mÃ³dulo ConfiguraciÃ³n > Empresa.
3. Agregar iconos CxC y CxP en el sidebar.
4. Crear pÃ¡ginas placeholder para operaciones y consultas.
Sin cambios en DB en esta tarea.

---

### Checkpoints

- [x] **34.1** `src/lib/navigation.ts` â€” Tres cambios:

  **A) Agregar a `NavIconKey`:**
  ```typescript
  | "cxc"
  | "cxp"
  ```

  **B) Agregar dos mÃ³dulos al `NAVIGATION_TREE` antes de `configuration`:**
  ```typescript
  {
    key: "cxc",
    label: "Cuentas por Cobrar",
    icon: "cxc",
    categories: [
      {
        key: "operations", label: "Operaciones",
        options: [
          { key: "cxc-invoices",     label: "Facturas a Credito",    href: "/cxc/invoices",     permission: "cxc.invoices.view" },
          { key: "cxc-credit-notes", label: "Notas de Credito",      href: "/cxc/credit-notes", permission: "cxc.credit-notes.view" },
          { key: "cxc-debit-notes",  label: "Notas de Debito",       href: "/cxc/debit-notes",  permission: "cxc.debit-notes.view" },
        ],
      },
      {
        key: "masters", label: "Maestros",
        options: [
          { key: "cxc-customers",           label: "Clientes",               href: "/config/cxc/customers",            permission: "config.cxc.customers.view" },
          { key: "cxc-customer-types",      label: "Tipos de Clientes",      href: "/config/cxc/customer-types",       permission: "config.cxc.customer-types.view" },
          { key: "cxc-customer-categories", label: "Categorias de Clientes", href: "/config/cxc/customer-categories",  permission: "config.cxc.customer-categories.view" },
          { key: "cxc-discounts",           label: "Descuentos",             href: "/config/cxc/discounts",            permission: "config.cxc.discounts.view" },
        ],
      },
      {
        key: "queries", label: "Consultas",
        options: [
          { key: "cxc-queries", label: "Consultas CxC", href: "/cxc/queries", permission: "cxc.queries.view" },
        ],
      },
    ],
  },
  {
    key: "cxp",
    label: "Cuentas por Pagar",
    icon: "cxp",
    categories: [
      {
        key: "operations", label: "Operaciones",
        options: [
          { key: "cxp-invoices",     label: "Facturas de Proveedores",      href: "/cxp/invoices",     permission: "cxp.invoices.view" },
          { key: "cxp-credit-notes", label: "Notas de Credito Proveedores", href: "/cxp/credit-notes", permission: "cxp.credit-notes.view" },
          { key: "cxp-debit-notes",  label: "Notas de Debito Proveedores",  href: "/cxp/debit-notes",  permission: "cxp.debit-notes.view" },
        ],
      },
      {
        key: "masters", label: "Maestros",
        options: [
          { key: "cxp-suppliers",            label: "Proveedores",               href: "/config/cxp/suppliers",            permission: "config.cxp.suppliers.view" },
          { key: "cxp-supplier-types",       label: "Tipos de Proveedores",      href: "/config/cxp/supplier-types",       permission: "config.cxp.supplier-types.view" },
          { key: "cxp-supplier-categories",  label: "Categorias de Proveedores", href: "/config/cxp/supplier-categories",  permission: "config.cxp.supplier-categories.view" },
        ],
      },
      {
        key: "queries", label: "Consultas",
        options: [
          { key: "cxp-queries", label: "Consultas CxP", href: "/cxp/queries", permission: "cxp.queries.view" },
        ],
      },
    ],
  },
  ```

  **C) En el modulo `configuration`, agregar categoria `referencias`** (dentro de `categories`, junto a `company`, `currencies`, `security`):
  ```typescript
  {
    key: "referencias",
    label: "Referencias",
    options: [
      { key: "doc-types", label: "Documentos Identidad", href: "/config/company/doc-types", permission: "config.company.doc-types.view" },
    ],
  },
  ```

- [x] **34.2** `src/lib/permissions.ts` â€” Agregar todas las permission keys:
  ```typescript
  | "cxc.invoices.view"
  | "cxc.credit-notes.view"
  | "cxc.debit-notes.view"
  | "cxc.queries.view"
  | "config.cxc.customers.view"
  | "config.cxc.customer-types.view"
  | "config.cxc.customer-categories.view"
  | "config.cxc.discounts.view"
  | "cxp.invoices.view"
  | "cxp.credit-notes.view"
  | "cxp.debit-notes.view"
  | "cxp.queries.view"
  | "config.cxp.suppliers.view"
  | "config.cxp.supplier-types.view"
  | "config.cxp.supplier-categories.view"
  | "config.company.doc-types.view"
  ```

  En `ROUTE_PERMISSIONS` agregar:
  ```typescript
  { pattern: "/cxc/invoices",                   key: "cxc.invoices.view" },
  { pattern: "/cxc/credit-notes",               key: "cxc.credit-notes.view" },
  { pattern: "/cxc/debit-notes",                key: "cxc.debit-notes.view" },
  { pattern: "/cxc/queries",                    key: "cxc.queries.view" },
  { pattern: "/config/cxc/customers",           key: "config.cxc.customers.view" },
  { pattern: "/config/cxc/customer-types",      key: "config.cxc.customer-types.view" },
  { pattern: "/config/cxc/customer-categories", key: "config.cxc.customer-categories.view" },
  { pattern: "/config/cxc/discounts",           key: "config.cxc.discounts.view" },
  { pattern: "/cxp/invoices",                   key: "cxp.invoices.view" },
  { pattern: "/cxp/credit-notes",               key: "cxp.credit-notes.view" },
  { pattern: "/cxp/debit-notes",                key: "cxp.debit-notes.view" },
  { pattern: "/cxp/queries",                    key: "cxp.queries.view" },
  { pattern: "/config/cxp/suppliers",           key: "config.cxp.suppliers.view" },
  { pattern: "/config/cxp/supplier-types",      key: "config.cxp.supplier-types.view" },
  { pattern: "/config/cxp/supplier-categories", key: "config.cxp.supplier-categories.view" },
  { pattern: "/config/company/doc-types",       key: "config.company.doc-types.view" },
  ```

- [x] **34.3** `src/components/pos/sidebar.tsx` â€” Agregar iconos:
  ```typescript
  import { Receipt, Wallet } from "lucide-react"
  // En objeto ICONS:
  cxc: Receipt,
  cxp: Wallet,
  ```

- [x] **34.4** Crear 8 paginas placeholder para operaciones y consultas de CxC y CxP:
  `src/app/cxc/invoices/page.tsx`, `src/app/cxc/credit-notes/page.tsx`,
  `src/app/cxc/debit-notes/page.tsx`, `src/app/cxc/queries/page.tsx`,
  `src/app/cxp/invoices/page.tsx`, `src/app/cxp/credit-notes/page.tsx`,
  `src/app/cxp/debit-notes/page.tsx`, `src/app/cxp/queries/page.tsx`

  Cada una:
  ```typescript
  import { AppShell } from "@/components/pos/app-shell"
  export default function Page() {
    return <AppShell><section className="content-page">
      <p style={{ padding: "2rem", color: "var(--text-muted)" }}>Proxmamente</p>
    </section></AppShell>
  }
  ```

- [x] **34.5** Build: `npm run build` sin errores.

**Archivos afectados:** `src/lib/navigation.ts`, `src/lib/permissions.ts`,
`src/components/pos/sidebar.tsx`, 8 nuevas paginas placeholder.

**Restricciones:** Sin DB. Sin pantallas funcionales. Solo estructura.

---

## TAREA 35 â€” CxC Maestros: Documentos Identidad + Clientes + Tipos + Categorias + Descuentos

**Estado:** `COMPLETA` âœ…

**Prerequisito:** TAREA 34 completada.

**Objetivo:** Toda la capa DB y UI de Maestros CxC mas la pantalla de administracion de
Documentos Identidad en Empresa > Referencias > Documentos Identidad.

---

### Checkpoints

- [ ] **35.1** `database/46_cxc_maestros.sql` â€” Script en bloques:

  **Tabla DocumentosIdentificacion:**
  ```sql
  CREATE TABLE dbo.DocumentosIdentificacion (
    IdTipoDocIdentificacion INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo                  VARCHAR(10) NOT NULL,
    Nombre                  VARCHAR(80) NOT NULL,
    LongitudMin             TINYINT     NOT NULL DEFAULT 0,
    LongitudMax             TINYINT     NOT NULL DEFAULT 50,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_DocIdent_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.DocumentosIdentificacion (Codigo, Nombre, LongitudMin, LongitudMax, UsuarioCreacion)
  VALUES ('CED','Cedula',11,11,1), ('RNC','RNC',9,9,1), ('PAS','Pasaporte',6,20,1), ('OTR','Otro',1,30,1);
  ```

  **Tabla TiposCliente:**
  ```sql
  CREATE TABLE dbo.TiposCliente (
    IdTipoCliente INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo        VARCHAR(10) NOT NULL,
    Nombre        VARCHAR(80) NOT NULL,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_TipoCliente_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.TiposCliente (Codigo, Nombre, UsuarioCreacion)
  VALUES ('NAT','Natural',1), ('EMP','Empresa',1), ('GOB','Gobierno',1), ('OTR','Otro',1);
  ```

  **Tabla CategoriasCliente:**
  ```sql
  CREATE TABLE dbo.CategoriasCliente (
    IdCategoriaCliente INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo             VARCHAR(10) NOT NULL,
    Nombre             VARCHAR(80) NOT NULL,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_CatCli_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.CategoriasCliente (Codigo, Nombre, UsuarioCreacion)
  VALUES ('VIP','VIP',1), ('MAY','Mayorista',1), ('MIN','Minorista',1), ('GEN','General',1);
  ```

  **Tabla Descuentos** (siempre porcentaje; puede ser global o por linea):
  ```sql
  CREATE TABLE dbo.Descuentos (
    IdDescuento INT            IDENTITY(1,1) PRIMARY KEY,
    Codigo      VARCHAR(20)    NOT NULL,
    Nombre      VARCHAR(100)   NOT NULL,
    Porcentaje  DECIMAL(5,2)   NOT NULL DEFAULT 0,  -- 0.00 a 100.00
    EsGlobal    BIT            NOT NULL DEFAULT 1,  -- 1=aplica al documento completo, 0=por linea
    FechaInicio DATE           NULL,
    FechaFin    DATE           NULL,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_Descuentos_Codigo UNIQUE (Codigo),
    CONSTRAINT CK_Descuentos_Pct CHECK (Porcentaje BETWEEN 0 AND 100)
  );
  ```

  **Tabla Terceros:**
  ```sql
  CREATE TABLE dbo.Terceros (
    IdTercero                INT            IDENTITY(1,1) PRIMARY KEY,
    Codigo                   VARCHAR(20)    NOT NULL,
    Nombre                   VARCHAR(150)   NOT NULL,
    NombreCorto              VARCHAR(50)    NULL,
    TipoPersona              CHAR(1)        NOT NULL DEFAULT 'J',
    IdTipoDocIdentificacion  INT            NULL,
    DocumentoIdentificacion  VARCHAR(30)    NULL,
    EsCliente                BIT            NOT NULL DEFAULT 0,
    IdTipoCliente            INT            NULL,
    IdCategoriaCliente       INT            NULL,
    EsProveedor              BIT            NOT NULL DEFAULT 0,
    IdTipoProveedor          INT            NULL,
    IdCategoriaProveedor     INT            NULL,
    Direccion                VARCHAR(300)   NULL,
    Ciudad                   VARCHAR(100)   NULL,
    Telefono                 VARCHAR(30)    NULL,
    Celular                  VARCHAR(30)    NULL,
    Email                    VARCHAR(150)   NULL,
    Web                      VARCHAR(200)   NULL,
    Contacto                 VARCHAR(100)   NULL,
    TelefonoContacto         VARCHAR(30)    NULL,
    EmailContacto            VARCHAR(150)   NULL,
    IdListaPrecio            INT            NULL,
    LimiteCredito            DECIMAL(18,2)  NOT NULL DEFAULT 0,
    DiasCredito              INT            NOT NULL DEFAULT 0,
    IdDocumentoVenta         INT            NULL,
    IdTipoComprobante        INT            NULL,
    IdDescuento              INT            NULL,
    Notas                    NVARCHAR(MAX)  NULL,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_Terceros_Codigo       UNIQUE (Codigo),
    CONSTRAINT FK_Terceros_ListaPrecio  FOREIGN KEY (IdListaPrecio)          REFERENCES dbo.ListasPrecios(IdListaPrecio),
    CONSTRAINT FK_Terceros_TipoDoc      FOREIGN KEY (IdTipoDocIdentificacion) REFERENCES dbo.DocumentosIdentificacion(IdTipoDocIdentificacion),
    CONSTRAINT FK_Terceros_TipoCli      FOREIGN KEY (IdTipoCliente)           REFERENCES dbo.TiposCliente(IdTipoCliente),
    CONSTRAINT FK_Terceros_CategCli     FOREIGN KEY (IdCategoriaCliente)      REFERENCES dbo.CategoriasCliente(IdCategoriaCliente)
    -- FK_Terceros_TipoProv y FK_Terceros_CategProv se agregan en TAREA 36
  );
  ```

  **SPs a crear** (todos con firma completa + campos de control en audit):
  - `dbo.spDocumentosIdentificacionCRUD` â€” L/O/I/A/D, parametros: Codigo, Nombre, LongitudMin, LongitudMax, Activo
  - `dbo.spTiposClienteCRUD` â€” L/O/I/A/D, parametros: Codigo, Nombre, Activo
  - `dbo.spCategoriasClienteCRUD` â€” idem
  - `dbo.spDescuentosCRUD` â€” L/O/I/A/D, parametros: Codigo, Nombre, Porcentaje, EsGlobal, FechaInicio, FechaFin, Activo
  - `dbo.spTercerosCRUD` â€” L/O/I/A/D:
    - Accion 'L': acepta `@EsCliente BIT = NULL` y `@EsProveedor BIT = NULL`.
      Si `@EsCliente=1` filtra `WHERE t.EsCliente=1 AND t.RowStatus=1`.
      Si `@EsProveedor=1` filtra `WHERE t.EsProveedor=1 AND t.RowStatus=1`.
      Sin filtro retorna todos con `RowStatus=1`.
      LEFT JOIN a TiposCliente, CategoriasCliente, DocumentosIdentificacion, ListasPrecios.
    - Accion 'O': mismo JOIN, filtrado por `@IdTercero`.
    - Acciones I/A/D: poblar auditoria.

  **Permisos:**
  ```sql
  INSERT INTO dbo.Pantallas (Clave, Nombre, Descripcion)
  SELECT v.Clave, v.Nombre, v.Desc FROM (VALUES
    ('config.cxc.customers.view',           'Clientes',              'Gestion de clientes'),
    ('config.cxc.customer-types.view',      'Tipos de Clientes',     'Tipos de clientes'),
    ('config.cxc.customer-categories.view', 'Categorias Clientes',   'Categorias de clientes'),
    ('config.cxc.discounts.view',           'Descuentos',            'Descuentos a clientes'),
    ('config.company.doc-types.view',       'Documentos Identidad',  'Tipos de documento de identificacion')
  ) AS v(Clave, Nombre, Desc)
  WHERE NOT EXISTS (SELECT 1 FROM dbo.Pantallas p WHERE p.Clave = v.Clave);

  INSERT INTO dbo.RolesPantallas (IdRol, IdPantalla)
  SELECT 1, p.IdPantalla FROM dbo.Pantallas p
  WHERE p.Clave IN (
    'config.cxc.customers.view','config.cxc.customer-types.view',
    'config.cxc.customer-categories.view','config.cxc.discounts.view',
    'config.company.doc-types.view'
  )
  AND NOT EXISTS (SELECT 1 FROM dbo.RolesPantallas rp
    WHERE rp.IdRol=1 AND rp.IdPantalla=p.IdPantalla);
  ```

- [ ] **35.2** `src/lib/pos-data.ts` â€” Tipos y funciones:

  ```typescript
  export type DocIdentOption     = { id: number; code: string; name: string; minLen: number; maxLen: number; active: boolean }
  export type TipoClienteOption  = { id: number; code: string; name: string }
  export type CategClienteOption = { id: number; code: string; name: string }

  export type DescuentoRecord = {
    id: number; code: string; name: string
    percentage: number    // 0-100
    isGlobal: boolean     // true=documento, false=linea
    startDate: string | null; endDate: string | null; active: boolean
  }

  export type TerceroRecord = {
    id: number; code: string; name: string; shortName: string | null
    personType: "F" | "J"
    docTypeId: number | null; docTypeName: string | null; docTypeCode: string | null
    docMinLen: number | null; docMaxLen: number | null; documentId: string | null
    isCustomer: boolean; customerTypeId: number | null; customerCategoryId: number | null
    isSupplier: boolean; supplierTypeId: number | null; supplierCategoryId: number | null
    address: string | null; city: string | null; phone: string | null; mobile: string | null
    email: string | null; web: string | null
    contact: string | null; contactPhone: string | null; contactEmail: string | null
    priceListId: number | null; priceListCode: string | null
    creditLimit: number; creditDays: number
    saleDocumentId: number | null; fiscalReceiptTypeId: number | null; discountId: number | null
    notes: string | null; active: boolean
  }

  export type CxCMaestrosData = {
    customers: TerceroRecord[]
    discounts: DescuentoRecord[]
    lookups: {
      customerTypes: TipoClienteOption[]
      customerCategories: CategClienteOption[]
      docTypes: DocIdentOption[]
      priceLists: Array<{ id: number; code: string; description: string }>
    }
  }

  // Funciones:
  export async function getCxCMaestrosData(): Promise<CxCMaestrosData>
    // Promise.all: spTercerosCRUD(@EsCliente=1) + spDescuentosCRUD('L') + lookups

  export async function getCustomerById(id: number): Promise<TerceroRecord | null>
  export async function saveCustomer(input: Partial<TerceroRecord>, userId: number, session: SessionData): Promise<TerceroRecord>
    // Siempre fuerza EsCliente=true antes de llamar spTercerosCRUD
  export async function deleteCustomer(id: number, session: SessionData): Promise<void>

  export async function getDocIdentOptions(): Promise<DocIdentOption[]>
  export async function saveDocIdent(input, userId, session): Promise<DocIdentOption>
  export async function deleteDocIdent(id, session): Promise<void>

  export async function getDescuentos(): Promise<DescuentoRecord[]>
  export async function saveDescuento(input, userId, session): Promise<DescuentoRecord>
  export async function deleteDescuento(id, session): Promise<void>
  ```

- [ ] **35.3** Endpoints API:
  - `src/app/api/cxc/customers/route.ts` â€” GET + POST
  - `src/app/api/cxc/customers/[id]/route.ts` â€” GET + PUT + DELETE
  - `src/app/api/cxc/discounts/route.ts` â€” GET + POST
  - `src/app/api/cxc/discounts/[id]/route.ts` â€” PUT + DELETE
  - `src/app/api/company/doc-types/route.ts` â€” GET + POST
  - `src/app/api/company/doc-types/[id]/route.ts` â€” PUT + DELETE

- [ ] **35.4** Paginas servidor:
  - `src/app/config/cxc/customers/page.tsx` â€” carga `getCxCMaestrosData()`
  - `src/app/config/cxc/customer-types/page.tsx`
  - `src/app/config/cxc/customer-categories/page.tsx`
  - `src/app/config/cxc/discounts/page.tsx`
  - `src/app/config/company/doc-types/page.tsx`

- [ ] **35.5** Componentes:

  **`catalog-customer-types-screen.tsx`** â€” 2 paneles simples:
  Sidebar: Codigo + Nombre + Activo | Detalle: Codigo*, Nombre*, Activo

  **`catalog-customer-categories-screen.tsx`** â€” identico patron.

  **`catalog-doc-types-screen.tsx`** â€” 2 paneles (Empresa > Referencias):
  Sidebar: Codigo + Nombre + `"min X / max Y"` + Activo
  Detalle: Codigo*, Nombre*, Longitud Minima (0-99), Longitud Maxima (1-99), Activo
  Validacion: LongitudMax >= LongitudMin

  **`cxc-discounts-screen.tsx`** â€” 2 paneles + 2 tabs:
  Sidebar: Codigo + Nombre + `XX.XX%` + badge `Global`/`Por Linea` + Activo

  *Tab "General":*
  - Codigo* (required), Nombre* (required)
  - Porcentaje: input decimal 0-100, sufijo `%` (`useFormat()`)
  - Aplicacion: radio/toggle "Global (documento completo)" / "Por Linea (cada item)"
  - Activo (toggle)

  *Tab "Vigencia":*
  - Fecha Inicio (date, nullable)
  - Fecha Fin (date, nullable)
  - Si FechaFin < FechaInicio mostrar error de validacion

  **`cxc-customers-screen.tsx`** â€” 2 paneles + 4 tabs:

  Sidebar: busqueda | lista Nombre (L1), `Codigo | TipoDoc NumDoc` (L2) + badges tipo/categ | Boton "Nuevo"
  Al seleccionar: fetch GET `/api/cxc/customers/:id` -> llenar form completo.

  *Tab "General":*
  - Codigo*, Nombre*, NombreCorto
  - TipoPersona: Fisica / Juridica
  - Tipo Documento: select `docTypes` â€” al cambiar actualizar validacion del campo Numero
  - Numero Documento: input + hint dinamico `"Entre X y Y caracteres"` + validacion al guardar
  - Tipo Cliente: select nullable
  - Categoria Cliente: select nullable
  - Activo (toggle)

  *Tab "Contacto":*
  - Direccion, Ciudad, Telefono, Celular, Email, Web
  - Contacto (persona), TelefonoContacto, EmailContacto

  *Tab "Comercial":*
  - Lista de Precios: select nullable ("Sin lista")
  - Limite Credito: input decimal (`useFormat()`)
  - Dias Credito: input entero >= 0
  - Descuento: select de Descuentos activos (nullable)
  - Documento Venta: `<select disabled>` "Proxmamente"
  - Tipo Comprobante: `<select disabled>` "Proximamente"

  *Tab "Notas":* textarea full-height

  `saveCustomer` siempre fuerza `EsCliente=true`.

- [ ] **35.6** Build: `npm run build` sin errores.

- [ ] **35.7** Checkpoint DB:
  ```sql
  -- Verificar 6 campos de control en cada tabla
  SELECT TABLE_NAME, COUNT(*) AS campos_control
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME IN ('DocumentosIdentificacion','TiposCliente','CategoriasCliente','Descuentos','Terceros')
    AND COLUMN_NAME IN ('Activo','RowStatus','FechaCreacion','UsuarioCreacion','FechaModificacion','UsuarioModificacion')
  GROUP BY TABLE_NAME;
  -- Resultado esperado: 6 por cada tabla (5 tablas = 5 filas)

  -- Verificar semilla
  SELECT 'DocIdent' t, COUNT(*) n FROM dbo.DocumentosIdentificacion UNION ALL
  SELECT 'TipoCli', COUNT(*) FROM dbo.TiposCliente UNION ALL
  SELECT 'CategCli', COUNT(*) FROM dbo.CategoriasCliente;

  -- Verificar FKs de Terceros
  SELECT fk.name, tp.name AS tabla_padre
  FROM sys.foreign_keys fk
  JOIN sys.tables tp ON fk.referenced_object_id = tp.object_id
  JOIN sys.tables tc ON fk.parent_object_id = tc.object_id
  WHERE tc.name = 'Terceros';

  -- Verificar permisos
  SELECT Clave FROM dbo.Pantallas
  WHERE Clave IN ('config.cxc.customers.view','config.cxc.customer-types.view',
    'config.cxc.customer-categories.view','config.cxc.discounts.view',
    'config.company.doc-types.view');
  ```

**Objetos DB afectados:**

| Objeto | Tipo | Accion |
|--------|------|--------|
| dbo.DocumentosIdentificacion | TABLE | CREATE + 4 filas |
| dbo.TiposCliente | TABLE | CREATE + 4 filas |
| dbo.CategoriasCliente | TABLE | CREATE + 4 filas |
| dbo.Descuentos | TABLE | CREATE |
| dbo.Terceros | TABLE | CREATE |
| dbo.spDocumentosIdentificacionCRUD | SP | CREATE |
| dbo.spTiposClienteCRUD | SP | CREATE |
| dbo.spCategoriasClienteCRUD | SP | CREATE |
| dbo.spDescuentosCRUD | SP | CREATE |
| dbo.spTercerosCRUD | SP | CREATE |
| dbo.Pantallas | TABLE | INSERT 5 filas |
| dbo.RolesPantallas | TABLE | INSERT 5 filas |

---

## TAREA 36 â€” CxP Maestros: Proveedores + Tipos + Categorias

**Estado:** `COMPLETA` âœ…

**Prerequisito:** TAREA 35 completada (tabla Terceros ya existe).

**Objetivo:** Tablas TiposProveedor y CategoriasProveedor, sus FKs en Terceros,
pantallas de administracion y pantalla principal de Proveedores.

---

### Checkpoints

- [ ] **36.1** `database/47_cxp_maestros.sql`:

  **Tabla TiposProveedor:**
  ```sql
  CREATE TABLE dbo.TiposProveedor (
    IdTipoProveedor INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo          VARCHAR(10) NOT NULL,
    Nombre          VARCHAR(80) NOT NULL,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_TipoProv_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.TiposProveedor (Codigo, Nombre, UsuarioCreacion)
  VALUES ('FAB','Fabricante',1), ('DIS','Distribuidor',1), ('IMP','Importador',1),
         ('SER','Servicios',1), ('OTR','Otro',1);
  ```

  **Tabla CategoriasProveedor:**
  ```sql
  CREATE TABLE dbo.CategoriasProveedor (
    IdCategoriaProveedor INT         IDENTITY(1,1) PRIMARY KEY,
    Codigo               VARCHAR(10) NOT NULL,
    Nombre               VARCHAR(80) NOT NULL,
    Activo              BIT      NOT NULL DEFAULT 1,
    RowStatus           TINYINT  NOT NULL DEFAULT 1,
    FechaCreacion       DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion     INT      NULL,
    FechaModificacion   DATETIME NULL,
    UsuarioModificacion INT      NULL,
    CONSTRAINT UQ_CategProv_Codigo UNIQUE (Codigo)
  );
  INSERT INTO dbo.CategoriasProveedor (Codigo, Nombre, UsuarioCreacion)
  VALUES ('A','Nivel A',1), ('B','Nivel B',1), ('C','Nivel C',1),
         ('LOC','Local',1), ('INT','Internacional',1);
  ```

  **Agregar FKs a Terceros:**
  ```sql
  ALTER TABLE dbo.Terceros
    ADD CONSTRAINT FK_Terceros_TipoProv  FOREIGN KEY (IdTipoProveedor)
      REFERENCES dbo.TiposProveedor(IdTipoProveedor),
        CONSTRAINT FK_Terceros_CategProv FOREIGN KEY (IdCategoriaProveedor)
      REFERENCES dbo.CategoriasProveedor(IdCategoriaProveedor);
  ```

  **SPs:** `dbo.spTiposProveedorCRUD` y `dbo.spCategoriasProveedorCRUD`
  (mismo patron L/O/I/A/D con auditoria completa).

  **Permisos:**
  ```sql
  INSERT INTO dbo.Pantallas (Clave, Nombre, Descripcion)
  SELECT v.Clave, v.Nombre, v.Desc FROM (VALUES
    ('config.cxp.suppliers.view',           'Proveedores',              'Gestion de proveedores'),
    ('config.cxp.supplier-types.view',      'Tipos de Proveedores',     'Tipos de proveedores'),
    ('config.cxp.supplier-categories.view', 'Categorias Proveedores',   'Categorias de proveedores')
  ) AS v(Clave, Nombre, Desc)
  WHERE NOT EXISTS (SELECT 1 FROM dbo.Pantallas p WHERE p.Clave = v.Clave);

  INSERT INTO dbo.RolesPantallas (IdRol, IdPantalla)
  SELECT 1, p.IdPantalla FROM dbo.Pantallas p
  WHERE p.Clave IN (
    'config.cxp.suppliers.view','config.cxp.supplier-types.view',
    'config.cxp.supplier-categories.view'
  )
  AND NOT EXISTS (SELECT 1 FROM dbo.RolesPantallas rp
    WHERE rp.IdRol=1 AND rp.IdPantalla=p.IdPantalla);
  ```

- [ ] **36.2** `src/lib/pos-data.ts` â€” Agregar tipos y funciones CxP:

  ```typescript
  export type TipoProveedorOption  = { id: number; code: string; name: string }
  export type CategProveedorOption = { id: number; code: string; name: string }

  export type CxPMaestrosData = {
    suppliers: TerceroRecord[]   // spTercerosCRUD con @EsProveedor=1
    lookups: {
      supplierTypes: TipoProveedorOption[]
      supplierCategories: CategProveedorOption[]
      docTypes: DocIdentOption[]
    }
  }

  export async function getCxPMaestrosData(): Promise<CxPMaestrosData>
  export async function getSupplierById(id: number): Promise<TerceroRecord | null>
  export async function saveSupplier(input: Partial<TerceroRecord>, userId: number, session: SessionData): Promise<TerceroRecord>
    // Siempre fuerza EsProveedor=true
  export async function deleteSupplier(id: number, session: SessionData): Promise<void>
  ```

- [ ] **36.3** Endpoints:
  - `src/app/api/cxp/suppliers/route.ts` â€” GET + POST (fuerza EsProveedor=true)
  - `src/app/api/cxp/suppliers/[id]/route.ts` â€” GET + PUT + DELETE

- [ ] **36.4** Paginas servidor:
  - `src/app/config/cxp/suppliers/page.tsx` â€” carga `getCxPMaestrosData()`
  - `src/app/config/cxp/supplier-types/page.tsx`
  - `src/app/config/cxp/supplier-categories/page.tsx`

- [ ] **36.5** Componentes:

  **`catalog-supplier-types-screen.tsx`** â€” 2 paneles simples (Codigo, Nombre, Activo).
  **`catalog-supplier-categories-screen.tsx`** â€” idem.

  **`cxp-suppliers-screen.tsx`** â€” 2 paneles + 3 tabs:

  Sidebar: busqueda | Nombre (L1), `Codigo | TipoDoc NumDoc` (L2) + badges | Boton "Nuevo"
  Al seleccionar: fetch GET `/api/cxp/suppliers/:id` -> llenar form.

  *Tab "General":*
  - Codigo*, Nombre*, NombreCorto
  - TipoPersona: Fisica / Juridica
  - Tipo Documento: select `docTypes` (min/max dinamico)
  - Numero Documento: input + hint + validacion al guardar
  - Tipo Proveedor: select nullable
  - Categoria Proveedor: select nullable
  - Activo (toggle)

  *Tab "Contacto":* Direccion, Ciudad, Telefono, Celular, Email, Web, Contacto, TelefonoContacto, EmailContacto

  *Tab "Notas":* textarea full-height

  `saveSupplier` siempre fuerza `EsProveedor=true`.

- [ ] **36.6** Build: `npm run build` sin errores.

- [ ] **36.7** Checkpoint DB:
  ```sql
  -- Control fields en nuevas tablas
  SELECT TABLE_NAME, COUNT(*) AS campos_control
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME IN ('TiposProveedor','CategoriasProveedor')
    AND COLUMN_NAME IN ('Activo','RowStatus','FechaCreacion','UsuarioCreacion','FechaModificacion','UsuarioModificacion')
  GROUP BY TABLE_NAME;
  -- Debe ser 6 por cada tabla

  -- Semilla
  SELECT 'TipoProv' t, COUNT(*) n FROM dbo.TiposProveedor UNION ALL
  SELECT 'CategProv', COUNT(*) FROM dbo.CategoriasProveedor;

  -- FKs nuevas en Terceros
  SELECT fk.name, tp.name AS tabla_padre
  FROM sys.foreign_keys fk
  JOIN sys.tables tp ON fk.referenced_object_id = tp.object_id
  JOIN sys.tables tc ON fk.parent_object_id = tc.object_id
  WHERE tc.name = 'Terceros' AND fk.name LIKE '%Prov%';

  -- Permisos
  SELECT Clave FROM dbo.Pantallas WHERE Clave LIKE 'config.cxp.%';
  ```

**Objetos DB afectados:**

| Objeto | Tipo | Accion |
|--------|------|--------|
| dbo.TiposProveedor | TABLE | CREATE + 5 filas |
| dbo.CategoriasProveedor | TABLE | CREATE + 5 filas |
| dbo.spTiposProveedorCRUD | SP | CREATE |
| dbo.spCategoriasProveedorCRUD | SP | CREATE |
| dbo.Terceros | TABLE | ALTER (2 FKs) |
| dbo.Pantallas | TABLE | INSERT 3 filas |
| dbo.RolesPantallas | TABLE | INSERT 3 filas |

**Restricciones globales TAREAS 34-36:**
- Los 6 campos de control deben estar en TODAS las tablas sin excepcion.
- Los SPs siempre poblan campos de auditoria en INSERT y UPDATE/DELETE.
- `spTercerosCRUD` accion 'L' filtra: `@EsCliente=1` para Clientes, `@EsProveedor=1` para Proveedores.
- La pantalla Clientes nunca muestra proveedores y viceversa.
- Soft delete en todas las tablas (RowStatus=0, Activo=0).
- Codigo unico en Terceros â€” error amigable al usuario.
- `useFormat()` en LimiteCredito.
- Descuentos: `Porcentaje` entre 0 y 100, `EsGlobal` true=documento / false=linea.

---

## AJUSTE POSTERIOR â€” Seguridad (Roles/Usuarios) idioma + proporciones (2026-03-26)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.1** `src/lib/i18n.tsx` â€” Aplicado fallback operacional para mantener interfaz protegida en espanol:
  - en rutas distintas de `/login`, idioma efectivo forzado a `es`.
  - persiste `masu-language=es` para evitar quedar bloqueado en ingles tras remover toggle global.

- [x] **A.2** `src/app/globals.css` â€” Ajustadas proporciones de pantallas de Seguridad:
  - `users-layout` migrado a grid (`20rem + detalle`) con mejor distribucion de espacio.
  - removidos limites de alto rigidos en `users-sidebar` y `users-detail`.
  - `roles-layout` rebalanceado a `19rem / 1fr / 18rem`.
  - panel de usuarios en Roles ahora usa ancho completo por item (sin cards comprimidas).

- [x] **A.3** Responsive:
  - `users-layout` ahora colapsa correctamente en breakpoints `1320px` y `980px`.

- [x] **A.4** Build: `npm run build` sin errores.

- [x] **A.5** Hotfix adicional tras QA visual:
  - `src/components/pos/security-users-screen.tsx`: cambio de clave i18n invalida `users.editData` por `users.editUser` para evitar render del key literal.
  - `src/app/globals.css`: ajuste del header de Roles para evitar compresion/solapamiento en modo edicion (`roles-header__identity` y `roles-header__info` con flex, acciones con wrap y alineacion a la derecha).

- [x] **A.6** Ajuste de alineacion + ahorro de espacio en Roles:
  - `src/app/globals.css`: cards de sidebar de roles ahora ocupan el 100% de ancho (se elimina desalineacion visual por items estrechos).
  - `src/components/pos/security-roles-screen.tsx`: selector `Asignados/Disponibles` movido a la misma franja de tabs `Modulos/Pantallas/Visualizacion`.
  - `src/app/globals.css`: nuevo contenedor `roles-main__tabsbar`; panel derecho de usuarios queda solo para listado.

- [x] **A.7** Build: `npm run build` sin errores.

- [x] **A.8** Ajuste de layout segun feedback visual:
  - `Asignados/Disponibles` retirado del panel central y devuelto al panel derecho de usuarios.
  - correccion del sidebar de roles para eliminar franja lateral visual (item al 100% con `box-sizing: border-box` y sin `padding-right` en lista).
  - alineacion general de barra de tabs principal en Roles.

- [x] **A.9** Build: `npm run build` sin errores.

- [x] **A.10** CxC Descuentos - correccion visual de radios en una sola linea:
  - `src/components/pos/cxc-discounts-screen.tsx`: reemplazo de estilos inline por clases dedicadas para opciones de tipo de aplicacion.
  - `src/app/globals.css`: agregado bloque `cxc-discounts-apply-*` con `white-space: nowrap` y ajuste responsive.

- [x] **A.11** Inventario/Maestros - Tipos de Documento: Codigo + Prefijo + Secuencia en misma fila:
  - `src/components/pos/inv-doc-type-screen.tsx`: label `ID` renombrado a `Codigo`.
  - `src/components/pos/inv-doc-type-screen.tsx`: campos `Codigo`, `Prefijo` y `Secuencia Inicial` agrupados en una misma linea.
  - aplica automaticamente a: Tipos de Entradas, Tipos de Salidas, Tipos Entradas por Compras y Tipos de Transferencias.
  - `src/app/globals.css`: nuevas clases `inv-doc-code-row` y `inv-doc-code-row.is-new` con responsive para mobile.

- [x] **A.12** Ajuste de ancho para `Codigo` (entero):
  - `src/app/globals.css`: en `inv-doc-code-row`, primera columna reducida a ancho corto (`minmax(6.5rem, 8.5rem)`) para reflejar que `Codigo` no requiere campo largo.

- [x] **A.13** Sidebar ERP - persistencia de foco/posicion al navegar:
  - `src/components/pos/sidebar.tsx`: persistencia de modulos expandidos en `localStorage` (`masu_sidebar_expanded_modules`).
  - `src/components/pos/sidebar.tsx`: persistencia/restauracion del scroll interno del sidebar en `sessionStorage` (`masu_sidebar_scroll_top`).
  - `src/components/pos/sidebar.tsx`: `Link` del menu con `scroll={false}` para evitar salto de scroll al navegar.
  - `src/components/pos/app-shell.tsx`: carga de datos del shell deja de ejecutarse por cada cambio de ruta (effect dependiente solo de `router`).

- [x] **A.14** Build: `npm run build` sin errores.

- [x] **A.15** Sidebar TreeView - mantener seleccion en opcion hija:
  - `src/components/pos/sidebar.tsx`: agregado estado persistente `masu_sidebar_active_option_key` para recordar opcion hija seleccionada.
  - activo del menu ahora se calcula por `option.key` (no solo por `href`) para evitar que rutas compartidas devuelvan foco visual a otra opcion de nivel superior.
  - se guarda el `option.key` al hacer click en opciones normales y flotantes.

- [x] **A.16** Build: `npm run build` sin errores.

**Archivos afectados:** `src/lib/i18n.tsx`, `src/app/globals.css`, `src/components/pos/security-users-screen.tsx`, `src/components/pos/security-roles-screen.tsx`, `src/components/pos/cxc-discounts-screen.tsx`, `src/components/pos/inv-doc-type-screen.tsx`.

---

## TAREA 37 â€” Ejecutar Scripts SQL: MÃ³dulo Operaciones de Inventario

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** Ninguno. Los scripts ya estÃ¡n creados en `database/`.

**Objetivo:** Ejecutar los scripts SQL que crean las tablas y SPs necesarios para el mÃ³dulo de Entradas y Salidas de Inventario. Estos scripts ya fueron generados â€” solo necesitan ejecutarse en `DbMasuPOS` en el orden indicado.

---

### Checkpoints

- [x] **37.1** Ejecutar `database/51_inv_sp_recreate_fix.sql` en `DbMasuPOS`:
  - Recrea el SP `spInvTiposDocumentoCRUD` con la versiÃ³n correcta (fix de columnas `Nombres` y `Correo` en acciÃ³n `LU`).
  - Verifica que la acciÃ³n `LU` retorne usuarios (tabla `Usuarios` con `RowStatus = 1`).

- [x] **37.2** Ejecutar `database/52_inv_documentos.sql` en `DbMasuPOS`:
  - Crea tabla `InvDocumentos` (cabecera de documento):
    - `IdDocumento` PK IDENTITY, `IdTipoDocumento` FK, `TipoOperacion` CHAR(1), `Periodo` VARCHAR(6), `Secuencia` INT, `NumeroDocumento` VARCHAR(30), `Fecha` DATE, `IdAlmacen` FK, `IdMoneda` FK, `TasaCambio` DECIMAL(18,6), `Referencia`, `Observacion`, `TotalDocumento`, `Estado` ('A'/'N'), campos de control completos.
    - UNIQUE: `(IdTipoDocumento, Secuencia)`.
  - Crea tabla `InvDocumentoDetalle` (lÃ­neas):
    - `IdDetalle` PK IDENTITY, `IdDocumento` FK, `NumeroLinea`, `IdProducto` FK, `Codigo`, `Descripcion`, `IdUnidadMedida`, `NombreUnidad`, `Cantidad`, `Costo`, `Total`, campos de control.
    - UNIQUE: `(IdDocumento, NumeroLinea)`.
  - Crea Ã­ndices: `IX_InvDocumentos_TipoOp_Fecha`, `IX_InvDocDetalle_Doc`.

- [x] **37.3** Ejecutar `database/53_sp_inv_documentos.sql` en `DbMasuPOS`:
  - Crea SP `spInvDocumentosCRUD` con acciones:
    - `L` â€” Listar documentos con filtros (TipoOperacion, Almacen, Fechas).
    - `O` â€” Obtener documento por ID (2 recordsets: cabecera + detalle).
    - `I` â€” Insertar documento completo (cabecera + detalle JSON via `OPENJSON`). Genera secuencia atomica, construye NumeroDocumento, actualiza stock en `ProductoAlmacenes`, recalcula `CostoPromedio` en `Productos` para entradas.
    - `N` â€” Anular documento (reversa stock, marca `Estado='N'`).
    - `LT` â€” Listar tipos de documento asignados al usuario actual (JOIN con `InvTipoDocUsuario`).
  - Crea SP `spInvBuscarProducto` con modos:
    - `E` â€” BÃºsqueda exacta por cÃ³digo (para escÃ¡ner/Enter).
    - `P` â€” BÃºsqueda parcial por cÃ³digo o nombre (para modal, TOP 50).
    - Ambos retornan: `IdProducto`, `Codigo`, `Nombre`, `IdUnidadMedida`, `NombreUnidad`, `AbreviaturaUnidad`, `CostoPromedio`, `ManejaExistencia`, `Existencia` (del almacÃ©n seleccionado).

- [x] **37.4** Verificar que las pÃ¡ginas funcionan:
  - Abrir `/inventory/entries` â†’ debe mostrar "Entradas de Inventario" con botÃ³n "Nuevo Documento".
  - Abrir `/inventory/exits` â†’ debe mostrar "Salidas de Inventario" con botÃ³n "Nuevo Documento".
  - En "Nuevo Documento": seleccionar Tipo de Documento, Fecha, AlmacÃ©n. Verificar que Moneda se pre-carga del tipo.
  - En la grilla: digitar un cÃ³digo de producto y presionar Enter â†’ debe traer descripciÃ³n, unidad y costo promedio.
  - Hacer click en la lupa â†’ debe abrir modal de bÃºsqueda de productos.
  - Guardar un documento â†’ debe generar secuencia y nÃºmero automÃ¡ticamente.

- [x] **37.5** Build: `npm run build` sin errores.

---

### Objetos de base de datos afectados

| Objeto | Tipo | AcciÃ³n |
|---|---|---|
| `InvDocumentos` | Tabla | CREAR |
| `InvDocumentoDetalle` | Tabla | CREAR |
| `IX_InvDocumentos_TipoOp_Fecha` | Ãndice | CREAR |
| `IX_InvDocDetalle_Doc` | Ãndice | CREAR |
| `spInvDocumentosCRUD` | SP | CREAR |
| `spInvBuscarProducto` | SP | CREAR |
| `spInvTiposDocumentoCRUD` | SP | RECREAR (fix) |

### Archivos de cÃ³digo ya creados/modificados (NO modificar, solo verificar)

| Archivo | DescripciÃ³n |
|---|---|
| `src/lib/pos-data.ts` | Tipos + funciones: `InvDocumentoRecord`, `InvDocumentoDetalleRecord`, `InvProductoParaDocumento`, `listInvDocumentos`, `getInvDocumento`, `createInvDocumento`, `anularInvDocumento`, `getInvTiposDocumentoParaUsuario`, `searchInvProducto`, `getInvProductoPorCodigo` |
| `src/components/pos/inv-document-screen.tsx` | Componente principal con 3 vistas: lista, nuevo, detalle |
| `src/app/api/inventory/documents/route.ts` | GET + POST |
| `src/app/api/inventory/documents/[id]/route.ts` | GET + DELETE (anular) |
| `src/app/api/inventory/documents/doc-types-for-user/route.ts` | GET tipos del usuario |
| `src/app/api/inventory/products/search/route.ts` | GET bÃºsqueda parcial |
| `src/app/api/inventory/products/by-code/route.ts` | GET cÃ³digo exacto |
| `src/app/inventory/entries/page.tsx` | Page con `tipoOperacion="E"` |
| `src/app/inventory/exits/page.tsx` | Page con `tipoOperacion="S"` |
| `src/app/globals.css` | Estilos `.inv-doc-screen`, `.inv-doc-form`, `.inv-doc-grid`, `.inv-product-modal` |

---

## TAREA 38 â€” UX Compacto: Eliminar Headers Redundantes en 8 Pantallas de Maestros

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** Ninguno.

**Objetivo:** Replicar el cambio de UX ya aplicado en Productos: eliminar el header redundante (tÃ­tulo + subtÃ­tulo del item seleccionado) que ocupa espacio vertical innecesario, ya que esa info ya aparece en los campos del formulario o en el sidebar. Mover los botones Editar/Eliminar a un menÃº contextual de 3 puntos (`â‹¯`) en la esquina superior derecha del panel de detalle.

**Referencia visual:** Ver cÃ³mo quedÃ³ `src/components/pos/catalog-products-screen.tsx`:
- Sin `products-detail__header` â€” eliminado completamente
- MenÃº `â‹¯` con Editar/Eliminar aparece en una barra compacta (`products-detail__action-bar`) arriba del formulario cuando NO se estÃ¡ editando
- Al editar: la barra muestra Cancelar + Guardar en su lugar
- El sidebar mantiene su propio menÃº `â‹¯` con Editar/Eliminar (ya existente)

---

### Checkpoints

- [x] **38.1** `src/components/pos/catalog-categories-screen.tsx`:
  - Eliminar el bloque `.categories-detail__head` (h2 con nombre de categorÃ­a y subtÃ­tulo).
  - Agregar barra compacta con menÃº `â‹¯` (Editar/Eliminar) en modo lectura, y botones Cancelar/Guardar en modo ediciÃ³n.
  - Los campos del formulario quedan como primera fila visible.

- [x] **38.2** `src/components/pos/catalog-product-types-screen.tsx`:
  - Eliminar el bloque `.price-lists-form__header` (h3 con nombre del tipo o "Nuevo Tipo de Producto").
  - Agregar barra compacta con menÃº `â‹¯` (Editar/Eliminar) en modo lectura, y botones Cancelar/Guardar en modo ediciÃ³n.

- [x] **38.3** `src/components/pos/catalog-units-screen.tsx`:
  - Eliminar el bloque `.price-lists-form__header` (h3 con nombre de unidad o "Nueva Unidad de Medida").
  - Agregar barra compacta con menÃº `â‹¯` (Editar/Eliminar) en modo lectura, y botones Cancelar/Guardar en modo ediciÃ³n.

- [x] **38.4** `src/components/pos/price-lists-screen.tsx`:
  - Eliminar el bloque `.price-lists-detail__head` (h2 con descripciÃ³n y cÃ³digo de lista).
  - Agregar barra compacta con menÃº `â‹¯` (Editar/Eliminar) en modo lectura, y botones Cancelar/Guardar en modo ediciÃ³n.

- [x] **38.5** `src/components/pos/inv-doc-type-screen.tsx` (afecta las 4 pantallas de inventario):
  - Eliminar el bloque con el tÃ­tulo del tipo (nombre + `#id`) que estÃ¡ encima de los tabs General/Usuarios.
  - Agregar barra compacta con menÃº `â‹¯` (Editar/Eliminar) en modo lectura, y botones Cancelar/Guardar en modo ediciÃ³n.
  - **Nota:** Este componente es compartido por las 4 pÃ¡ginas: Tipos de Entradas, Tipos de Salidas, Tipos Entradas por Compras, y Tipos de Transferencias.

- [x] **38.6** CSS: Eliminar o limpiar estilos huÃ©rfanos:
  - `.categories-detail__head` y sus hijos (si ya no se usan).
  - `.products-detail__header`, `.products-detail__header-left`, `.products-detail__header-actions`, `.products-detail__title`, `.products-detail__subtitle`, `.products-detail__icon` (ya eliminados del HTML).
  - Verificado que `.price-lists-form__header` sigue en uso en otras pantallas; se conserva para no romper mÃ³dulos no incluidos en esta tarea.

- [x] **38.7** Build: `npm run build` sin errores.

---

### PatrÃ³n a seguir (referencia de Productos)

**Modo lectura (item seleccionado, no editando):**
```tsx
<div className="products-detail__action-bar">
  <div className="products-detail__context-menu">
    <button type="button" className="price-lists-sidebar__menu-btn"
      onClick={() => setDetailMenuOpen(prev => !prev)}>
      <MoreHorizontal size={16} />
    </button>
    {detailMenuOpen && (
      <ul className="price-lists-dropdown" ref={detailMenuRef}>
        <li><button onClick={() => setIsEditing(true)}>
          <Pencil size={13} /> Editar
        </button></li>
        <li className="is-danger"><button onClick={() => handleDelete(id)}>
          <Trash2 size={13} /> Eliminar
        </button></li>
      </ul>
    )}
  </div>
</div>
```

**Modo ediciÃ³n:**
```tsx
<div className="products-detail__action-bar">
  <div className="products-detail__action-bar-btns">
    <button className="secondary-button" onClick={closeEditor}>
      <X size={15} /> Cancelar
    </button>
    <button type="submit" className="primary-button" disabled={isPending}>
      <Save size={15} /> Guardar
    </button>
  </div>
</div>
```

**CSS necesario** (ya existe en globals.css):
```css
.products-detail__action-bar { ... }
.products-detail__action-bar-btns { ... }
.products-detail__context-menu { ... }
```

Renombrar estas clases a algo genÃ©rico (ej: `detail-action-bar`, `detail-context-menu`) para reutilizar en todas las pantallas, o reusar las mismas clases `products-detail__*`.

---

### Archivos afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/catalog-categories-screen.tsx` | Eliminar header, agregar menÃº `â‹¯` + barra ediciÃ³n |
| `src/components/pos/catalog-product-types-screen.tsx` | Eliminar header, agregar menÃº `â‹¯` + barra ediciÃ³n |
| `src/components/pos/catalog-units-screen.tsx` | Eliminar header, agregar menÃº `â‹¯` + barra ediciÃ³n |
| `src/components/pos/price-lists-screen.tsx` | Eliminar header, agregar menÃº `â‹¯` + barra ediciÃ³n |
| `src/components/pos/inv-doc-type-screen.tsx` | Eliminar header, agregar menÃº `â‹¯` + barra ediciÃ³n (4 pÃ¡ginas) |
| `src/app/globals.css` | Limpiar estilos huÃ©rfanos, posiblemente renombrar clases genÃ©ricas |

## AJUSTE POSTERIOR â€” Inventario Documentos (optimizaciÃ³n layout + tab observaciones) (2026-03-27)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.1** Reordenar encabezado del formulario "Nuevo Documento" en 2 lÃ­neas:
  - LÃ­nea 1: `Tipo Documento`, `Almacen`, `Periodo`, `Fecha`.
  - LÃ­nea 2: `Moneda`, `Tasa Cambio`, `Referencia`.

- [x] **A.2** Agregar tab junto a `Detalle` para `Comentarios / Observaciones`:
  - nuevo tab en `src/components/pos/inv-document-screen.tsx`.
  - textarea para observaciones generales del documento.

- [x] **A.3** Persistencia de observaciones en guardado:
  - `payload` de creaciÃ³n ahora envÃ­a `observacion`.

- [x] **A.4** CSS responsive actualizado para nuevo layout:
  - `inv-doc-form__grid--entry`, `inv-doc-form__row--line1`, `inv-doc-form__row--line2`.
  - `inv-doc-grid__tabs` y `inv-doc-notes`.

- [x] **A.5** Build: `npm run build` sin errores.

---

## TAREA 39 â€” Eliminar MenÃº â‹¯ del Panel Derecho en Todas las Pantallas de Maestros

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** TAREA 38 completada.

**Objetivo:** Eliminar el menÃº contextual de 3 puntos (`â‹¯`) del panel derecho (detalle) en todas las pantallas de maestros. El usuario ya puede Editar/Eliminar desde el menÃº `â‹¯` del panel izquierdo (sidebar/listado), por lo que el menÃº del panel derecho es redundante y ocupa espacio vertical innecesario.

**Resultado esperado:** Al seleccionar un item del listado, el panel derecho muestra directamente los campos del formulario sin ninguna barra de acciÃ³n encima. Solo cuando el usuario da click en "Editar" desde el sidebar, aparecen los botones Cancelar/Guardar.

---

### Checkpoints

- [x] **39.1** `src/components/pos/catalog-products-screen.tsx`:
  - Eliminar el bloque `products-detail__action-bar` con `products-detail__context-menu` que se muestra en modo lectura (`!isEditing && selected`).
  - Mantener SOLO el bloque `products-detail__action-bar` con botones Cancelar/Guardar que aparece en modo ediciÃ³n (`isEditing`).
  - Eliminar el state `detailMenuOpen` y `detailMenuRef` si ya no se usan.

- [x] **39.2** `src/components/pos/catalog-categories-screen.tsx`:
  - Mismo cambio: eliminar el bloque del menÃº `â‹¯` en modo lectura.
  - Mantener solo Cancelar/Guardar en modo ediciÃ³n.

- [x] **39.3** `src/components/pos/catalog-product-types-screen.tsx`:
  - Mismo cambio.

- [x] **39.4** `src/components/pos/catalog-units-screen.tsx`:
  - Mismo cambio.

- [x] **39.5** `src/components/pos/price-lists-screen.tsx`:
  - Mismo cambio.

- [x] **39.6** `src/components/pos/inv-doc-type-screen.tsx`:
  - Mismo cambio (afecta 4 pÃ¡ginas: Tipos de Entradas, Salidas, Compras, Transferencias).

- [x] **39.7** CSS cleanup en `src/app/globals.css`:
  - Eliminar `.products-detail__context-menu` y su regla `.price-lists-dropdown`.
  - Eliminar `.price-lists-form > .products-detail__action-bar` (override de margin ya no necesario).
  - Simplificar `.products-detail__action-bar`: solo necesita flex + justify-content: flex-end para los botones de ediciÃ³n.

- [x] **39.8** Build: `npm run build` sin errores.

---

### PatrÃ³n a seguir

**Antes (eliminar):**
```tsx
{isEditing ? (
  <div className="products-detail__action-bar">
    <div className="products-detail__action-bar-btns">
      <button>Cancelar</button>
      <button>Guardar</button>
    </div>
  </div>
) : selected && (
  <div className="products-detail__action-bar">        â† ELIMINAR ESTE BLOQUE
    <div className="products-detail__context-menu">
      <button><MoreHorizontal /></button>
      {detailMenuOpen && <ul>Editar/Eliminar</ul>}
    </div>
  </div>
)}
```

**DespuÃ©s:**
```tsx
{isEditing && (
  <div className="products-detail__action-bar">
    <div className="products-detail__action-bar-btns">
      <button>Cancelar</button>
      <button>Guardar</button>
    </div>
  </div>
)}
```

---

### Archivos afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/catalog-products-screen.tsx` | Eliminar menÃº `â‹¯` modo lectura, limpiar states |
| `src/components/pos/catalog-categories-screen.tsx` | Eliminar menÃº `â‹¯` modo lectura |
| `src/components/pos/catalog-product-types-screen.tsx` | Eliminar menÃº `â‹¯` modo lectura |
| `src/components/pos/catalog-units-screen.tsx` | Eliminar menÃº `â‹¯` modo lectura |
| `src/components/pos/price-lists-screen.tsx` | Eliminar menÃº `â‹¯` modo lectura |
| `src/components/pos/inv-doc-type-screen.tsx` | Eliminar menÃº `â‹¯` modo lectura |
| `src/app/globals.css` | Limpiar CSS huÃ©rfano |

---

## AJUSTE POSTERIOR â€” SelecciÃ³n inicial automÃ¡tica en Maestros (2026-03-27)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.1** Mostrar automÃ¡ticamente el primer registro del panel izquierdo en el panel derecho al entrar por primera vez.

- [x] **A.2** Pantallas ajustadas:
  - `src/components/pos/catalog-product-types-screen.tsx`
  - `src/components/pos/catalog-units-screen.tsx`
  - `src/components/pos/inv-doc-type-screen.tsx`

- [x] **A.3** Comportamiento preservado:
  - al crear nuevo (`isEditing=true`), no se fuerza reselecciÃ³n automÃ¡tica.
  - cuando no hay selecciÃ³n y existen items, se selecciona el primero.

- [x] **A.4** Build: `npm run build` sin errores.

---

## AJUSTE POSTERIOR â€” Correcciones de regresiÃ³n (2026-03-27)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **R.1** Formato numÃ©rico con 0 decimales:
  - `src/lib/format-context.tsx`: `formatNumber()` ya no concatena separador decimal cuando `decimals=0`.
  - corrige visualizaciÃ³n `1.undefined` en campos enteros (ej. Base A / Base B en Unidades).

- [x] **R.2** BotÃ³n Agregar en maestros reutilizables:
  - `src/components/pos/catalog-product-types-screen.tsx`
  - `src/components/pos/catalog-units-screen.tsx`
  - `src/components/pos/inv-doc-type-screen.tsx`
  - ajuste del efecto de sincronizaciÃ³n para no forzar `isEditing=false` cuando `selected=null` por flujo de nuevo registro.

- [x] **R.3** Build: `npm run build` sin errores.

- [x] **R.4** Hotfix botÃ³n Editar en maestros reutilizables:
  - `src/components/pos/catalog-product-types-screen.tsx`
  - `src/components/pos/catalog-units-screen.tsx`
  - `src/components/pos/inv-doc-type-screen.tsx`
  - se corrigiÃ³ el efecto de sincronizaciÃ³n para no desactivar ediciÃ³n al entrar en modo editar sobre un registro seleccionado.
  - se agregÃ³ `selectItem(...)` para reset controlado a modo lectura cuando el usuario selecciona explÃ­citamente desde el listado.

- [x] **R.5** Build: `npm run build` sin errores.

- [x] **R.6** Hotfix botÃ³n Editar en Productos:
  - `src/components/pos/catalog-products-screen.tsx`: el efecto de sincronizaciÃ³n de `selected` ya no fuerza salida de ediciÃ³n.
  - se mantiene sincronizaciÃ³n de formulario, pero el modo ediciÃ³n solo se cierra por acciones explÃ­citas del usuario.

- [x] **R.7** Build: `npm run build` sin errores.

---

## TAREA 40 â€” Funcionalidad "Duplicar" en MenÃº â‹¯ del Sidebar (Todas las Pantallas de Maestros)

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** TAREA 39 completada.

**Objetivo:** Agregar opciÃ³n "Duplicar" al menÃº contextual de 3 puntos (`â‹¯`) del sidebar en todas las pantallas de maestros que tienen layout de 2 paneles. Al duplicar, se crea un nuevo registro con los mismos datos del original (excepto el ID y el cÃ³digo/nombre que se modifica para indicar que es copia).

**Comportamiento esperado:**
1. Usuario hace click en `â‹¯` â†’ aparece menÃº con Editar / Duplicar / Eliminar
2. Click en "Duplicar" â†’ se abre el formulario en modo ediciÃ³n (como si fuera "Nuevo") con los datos pre-llenados del item seleccionado
3. El campo Nombre/DescripciÃ³n se prefija con "Copia de â€” " para diferenciarlo
4. El ID no se envÃ­a (es un registro nuevo)
5. El usuario puede modificar los campos y guardar normalmente

---

### Checkpoints

- [x] **40.1** `src/components/pos/catalog-products-screen.tsx`:
  - Agregar opciÃ³n "Duplicar" en el menÃº `â‹¯` del sidebar (entre Editar y Eliminar).
  - Icono: `Copy` de lucide-react.
  - Al click: llamar funciÃ³n `duplicateItem(product)` que hace:
    - `setSelectedId(null)` (nuevo registro)
    - `setForm({ ...recordToForm(product), id: undefined, name: "Copia de â€” " + product.name, code: "" })`
    - `setIsEditing(true)`
  - El cÃ³digo/barra se limpia (el usuario debe asignar uno nuevo o dejarlo vacÃ­o).

- [x] **40.2** `src/components/pos/catalog-categories-screen.tsx`:
  - Agregar "Duplicar" en menÃº `â‹¯` del sidebar.
  - Al duplicar: `name: "Copia de â€” " + category.name`, `codigo: ""`, `id: undefined`.

- [x] **40.3** `src/components/pos/catalog-product-types-screen.tsx`:
  - Agregar "Duplicar" en menÃº `â‹¯` del sidebar.
  - Al duplicar: `name: "Copia de â€” " + type.name`, `id: undefined`.

- [x] **40.4** `src/components/pos/catalog-units-screen.tsx`:
  - Agregar "Duplicar" en menÃº `â‹¯` del sidebar.
  - Al duplicar: `name: "Copia de â€” " + unit.name`, `abbreviation: ""`, `id: undefined`.

- [x] **40.5** `src/components/pos/price-lists-screen.tsx`:
  - Agregar "Duplicar" en menÃº `â‹¯` del sidebar.
  - Al duplicar: `description: "Copia de â€” " + list.description`, `code: ""`, `id: undefined`.
  - **Nota:** NO duplicar usuarios asignados ni fechas de vigencia â€” el usuario las configura en la copia.

- [x] **40.6** `src/components/pos/inv-doc-type-screen.tsx` (afecta 4 pÃ¡ginas):
  - Agregar "Duplicar" en menÃº `â‹¯` del sidebar.
  - Al duplicar: `description: "Copia de â€” " + item.description`, `prefijo: ""`, `id: undefined`.
  - NO duplicar usuarios asignados.

- [x] **40.7** Build: `npm run build` sin errores.

---

## AJUSTE POSTERIOR â€” TAREA 40 (criterio funcional de duplicaciÃ³n) (2026-03-27)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.1** Productos: duplicaciÃ³n ahora copia tambiÃ©n `precios`, `costos` y `parÃ¡metros` ademÃ¡s de datos generales.

- [x] **A.2** CategorÃ­as: duplicaciÃ³n preserva bloques `General` + `POS` (imagen no se arrastra en la copia).

- [x] **A.3** Resto de maestros: duplicaciÃ³n configurada para conservar todos los campos del formulario de origen (excepto `id`, y nombre/descripcion con prefijo `Copia de â€”`).

- [x] **A.4** Build: `npm run build` sin errores.

---

### PatrÃ³n a seguir

**MenÃº del sidebar (agregar entre Editar y Eliminar):**
```tsx
<ul className="price-lists-dropdown" ref={menuRef}>
  <li>
    <button type="button" onClick={() => openEdit(item)}>
      <Pencil size={13} /> Editar
    </button>
  </li>
  <li>
    <button type="button" onClick={() => duplicateItem(item)}>
      <Copy size={13} /> Duplicar
    </button>
  </li>
  <li className="is-danger">
    <button type="button" onClick={() => handleDelete(item.id)}>
      <Trash2 size={13} /> Eliminar
    </button>
  </li>
</ul>
```

**FunciÃ³n duplicateItem (ejemplo para productos):**
```tsx
function duplicateItem(product: ProductRecord) {
  setSelectedId(null)
  setForm({
    ...recordToForm(product),
    id: undefined,
    name: "Copia de â€” " + product.name,
    code: "",
  })
  setIsEditing(true)
  setMenuId(null)
  setMessage(null)
}
```

**Import necesario:** Agregar `Copy` al import de `lucide-react` en cada archivo.

---

### Archivos afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/catalog-products-screen.tsx` | Agregar Duplicar en menÃº + funciÃ³n `duplicateItem` |
| `src/components/pos/catalog-categories-screen.tsx` | Agregar Duplicar en menÃº + funciÃ³n `duplicateItem` |
| `src/components/pos/catalog-product-types-screen.tsx` | Agregar Duplicar en menÃº + funciÃ³n `duplicateItem` |
| `src/components/pos/catalog-units-screen.tsx` | Agregar Duplicar en menÃº + funciÃ³n `duplicateItem` |
| `src/components/pos/price-lists-screen.tsx` | Agregar Duplicar en menÃº + funciÃ³n `duplicateItem` |
| `src/components/pos/inv-doc-type-screen.tsx` | Agregar Duplicar en menÃº + funciÃ³n `duplicateItem` |

---

## AJUSTE POSTERIOR â€” Inventario Documentos (filtros + paginaciÃ³n + SP) (2026-03-27)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.1** VerificaciÃ³n tÃ©cnica previa:
  - confirmado que Entradas/Salidas cargan desde `spInvDocumentosCRUD` vÃ­a `listInvDocumentos(...)`.

- [x] **A.2** SP actualizado con nuevos filtros y paginaciÃ³n:
  - script: `database/54_inv_documentos_filtros_paginacion.sql`.
  - cambios en acciÃ³n `L`:
    - filtros `@SecuenciaDesde`, `@SecuenciaHasta`, `@FechaDesde`, `@FechaHasta`.
    - paginaciÃ³n `@NumeroPagina`, `@TamanoPagina`.
    - total de registros con `COUNT(1) OVER() AS TotalRows`.
  - script ejecutado en DB: `Script aplicado correctamente`.

- [x] **A.3** Backend/API adaptados:
  - `src/lib/pos-data.ts`: `listInvDocumentos(...)` ahora soporta filtros de secuencia y paginaciÃ³n y retorna `{ items, total, page, pageSize }`.
  - `src/app/api/inventory/documents/route.ts`: recibe `secDesde`, `secHasta`, `desde`, `hasta`, `page`, `pageSize`.

- [x] **A.4** UI de Entradas/Salidas:
  - `src/components/pos/inv-document-screen.tsx`:
    - filtros de `Secuencia Desde/Hasta` y `Fecha Desde/Hasta`.
    - botÃ³n `Filtrar` + `Limpiar`.
    - paginaciÃ³n `Anterior/Siguiente`, indicador de pÃ¡gina y tamaÃ±o de pÃ¡gina.
  - `src/app/inventory/entries/page.tsx` y `src/app/inventory/exits/page.tsx` cargan pÃ¡gina inicial paginada.

- [x] **A.5** Estilos nuevos:
  - `src/app/globals.css`: bloque visual de filtros y footer de paginaciÃ³n para listado de documentos.

- [x] **A.6** Validaciones:
  - smoke test SP con filtros/paginaciÃ³n OK (`rows` + `TotalRows`).
  - `npm run build` sin errores.

- [x] **A.7** Refinamiento visual solicitado (layout filtros/paginaciÃ³n):
  - `Secuencia Desde/Hasta` compactados para usar menos ancho.
  - acciones `Actualizar` y `Limpiar` en la misma lÃ­nea del header de filtros.
  - `TamaÃ±o pÃ¡gina` ubicado en el footer inferior izquierdo junto al contador de registros.

- [x] **A.8** Ajuste final de espacios (feedback visual):
  - filtros recompactados a 4 columnas homogÃ©neas, eliminando huecos intermedios.
  - `Actualizar/Limpiar` movidos debajo de los filtros y alineados a la derecha.

- [x] **A.9** Micro-ajuste de densidad visual:
  - fechas y secuencias compactadas con anchos mÃ¡ximos para reducir separaciÃ³n horizontal.
  - acciones inferiores conservadas en fila Ãºnica y alineadas a la derecha.

- [x] **A.10** Acciones por fila en Documentos (iconos + tooltip + permisos):
  - agregado bloque de acciones uniformes `Visualizar / Imprimir / Anular` en columna `Acciones`.
  - tooltips vÃ­a atributo `title` al pasar el mouse.
  - visibilidad condicionada por permisos del usuario para la pantalla:
    - visualizar: `inventory.entries.view` / `inventory.exits.view` (fallback `catalog.view`)
    - imprimir: permiso `.print` o fallback de visualizaciÃ³n
    - anular: permiso `.void` / `.delete` / `.edit` (o `catalog.delete` / `catalog.edit`)
  - `Imprimir` genera salida en ventana de impresiÃ³n con cabecera + detalle del documento.

- [x] **A.11** ConfirmaciÃ³n de anulaciÃ³n con modal del sistema:
  - removido `confirm()` nativo del navegador para anular documentos.
  - implementado modal propio (`modal-backdrop` / `modal-card`) consistente con cierre de sesiÃ³n.
  - acciones del modal: `Cancelar` y `SÃ­, anular` con estado `Anulando...`.

- [x] **A.12** UX de lÃ­nea activa en detalle de documento:
  - en `inv-document-screen` se rastrea la lÃ­nea activa mientras el usuario digita.
  - resaltado visual de fila activa y de campos editables (`Codigo`, `Cantidad`, `Costo`).
  - mejora de orientaciÃ³n para captura rÃ¡pida en tabla de detalle.

- [x] **A.13** Formatos de empresa aplicados en Inventario Documentos:
  - `inv-document-screen` ahora usa `useFormat().formatNumber(...)` para montos y cantidades mostradas.
  - se reemplazaron `toFixed(...)` en listados, detalle, impresiÃ³n y totales por formato corporativo (separador de miles/decimal).
  - total de pie de tabla ajustado para no romper lÃ­nea con importes largos (`white-space: nowrap`) y desplazado hacia la izquierda.

- [x] **A.14** UX de captura rÃ¡pida:
  - al presionar `Enter` en `Cantidad`, el foco salta automÃ¡ticamente al campo `Costo` de la misma lÃ­nea.

- [x] **A.15** Correcciones adicionales Inventario Documentos:
  - fecha en listado corregida (`mapInvDocumentoRow` ahora usa `toIsoDate(row.Fecha)`).
  - agregado modal de confirmaciÃ³n para guardado de documento (mismo estilo modal del sistema).
  - acciÃ³n `Editar` visible en detalle (estado activo) con comportamiento informativo temporal.

- [x] **A.16** Ajuste visibilidad botÃ³n `Editar`:
  - `inv-document-screen` amplÃ­a fallback de permiso para mostrar `Editar` cuando el usuario tiene `catalog.view` y el documento estÃ¡ activo.

- [x] **A.17** EdiciÃ³n de documento de inventario (flujo funcional):
  - API `PUT /api/inventory/documents/[id]` habilitada.
  - `pos-data` incorpora `updateInvDocumento(...)`.
  - nuevo SP `database/55_sp_inv_actualizar_documento.sql` (`spInvActualizarDocumento`) para actualizar cabecera + detalle y recalcular stock.
  - en UI, `Editar` carga documento activo a formulario, permite modificar y guardar cambios con modal de confirmaciÃ³n.
  - en ediciÃ³n, cancelar retorna a detalle del documento.

- [x] **A.18** Reglas de guardado + historial detalle en ediciÃ³n:
  - creaciÃ³n mantiene bloqueo sin detalle (UI + API).
  - ediciÃ³n ajustada a soft delete en detalle (`RowStatus=0`) e inserciÃ³n de nuevo detalle (`RowStatus=1`).
  - agregado script `database/56_inv_docdetalle_softdelete_unique.sql` para permitir histÃ³rico por lÃ­nea:
    - elimina constraint Ãºnico rÃ­gido por lÃ­nea
    - crea Ã­ndice Ãºnico filtrado para activos (`RowStatus=1`).
  - `spInvActualizarDocumento` re-aplicado y validado con histÃ³rico (`active=1`, `history=1`).

---

## TAREA 41 â€” Optimizar Layout Detalle de Documentos de Inventario (Entradas/Salidas)

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** Ninguno. Los cambios base ya estÃ¡n aplicados en `inv-document-screen.tsx`.

**Objetivo:** Replicar y pulir el layout compacto del detalle de documentos de inventario para maximizar el espacio del detalle (lÃ­neas). Aplicar el mismo patrÃ³n a las 3 vistas: detalle (read-only), nuevo documento, y ediciÃ³n.

**Referencia:** Ver el estado actual de `src/components/pos/inv-document-screen.tsx` â€” la vista de detalle (read-only) ya tiene el nuevo layout implementado. Las vistas de nuevo/ediciÃ³n deben seguir el mismo patrÃ³n.

---

### DiseÃ±o objetivo

**Botones fuera del panel blanco**, en la misma lÃ­nea del breadcrumb (arriba a la derecha):
```
Inventario / Operaciones / Entradas    ðŸŸ¢Activo [Editar] [Anular] [Cerrar]
```

**Cabecera del documento en 2 filas dentro del panel** (grid 4 columnas):
```
Fila 1: Fecha | Periodo | Documento (Secuencia) | Moneda
Fila 2: Tipo Documento | Almacen | Referencia | Tasa Cambio
```

**Esto aplica a las 3 vistas:**
- **Detalle (read-only)**: inputs disabled, botones Editar/Anular/Cerrar arriba
- **Nuevo documento**: inputs editables, botones Cancelar/Guardar arriba
- **EdiciÃ³n**: inputs editables, botones Cancelar/Guardar arriba

---

### Checkpoints

- [x] **41.1** Vista **Detalle (read-only)** â€” ya implementada, verificar que funciona:
  - Botones fuera del panel en `.inv-doc-detail-topbar`
  - Cabecera en `.inv-doc-detail-header` con 2 filas de 4 columnas
  - La secuencia/nÃºmero de documento estÃ¡ en la cabecera (no duplicada arriba)

- [x] **41.2** Vista **Nuevo documento** â€” aplicar mismo layout:
  - Mover botones Cancelar/Guardar fuera del panel (`.inv-doc-detail-topbar`)
  - Reorganizar campos de cabecera en 2 filas de 4 columnas:
    - Fila 1: Fecha* (date input) | Periodo (disabled, auto) | Documento (disabled, se genera al guardar, puede mostrar "Auto") | Moneda (disabled, viene del tipo)
    - Fila 2: Tipo Documento* (select) | Almacen* (select) | Referencia (text input) | Tasa Cambio (number input)
  - Usar las mismas clases CSS: `.inv-doc-detail-topbar`, `.inv-doc-detail-header`, `.inv-doc-detail-header__row`
  - El grid de detalle (lÃ­neas) debe quedar justo debajo sin espacio extra

- [x] **41.3** Vista **EdiciÃ³n** â€” aplicar mismo layout:
  - Mismo patrÃ³n que nuevo documento pero con datos pre-llenados
  - Botones Cancelar/Guardar fuera del panel
  - Campos editables segÃºn corresponda (Tipo Documento y AlmacÃ©n pueden ser no editables en ediciÃ³n si se desea)

- [x] **41.4** CSS: Verificar que las clases existentes cubren los 3 casos:
  - `.inv-doc-detail-topbar` y `.inv-doc-detail-topbar__actions` â€” botones fuera del panel
  - `.inv-doc-detail-header` y `.inv-doc-detail-header__row` â€” cabecera 2 filas
  - Inputs editables vs disabled deben verse distintos (background diferente)
  - Responsive: en pantallas < 900px, las filas de 4 columnas pueden pasar a 2 columnas

- [x] **41.5** Eliminar la cabecera grande de la vista "Nuevo" (`inv-doc-screen__header` con tÃ­tulo "Nuevo â€” Entradas de Inventario") si es redundante â€” el breadcrumb ya indica la pantalla.

- [x] **41.6** Eliminar CSS huÃ©rfano:
  - `.inv-doc-form__grid` y `.inv-doc-form__grid--readonly` si ya no se usan
  - `.inv-doc-form__grid--entry` si fue reemplazado
  - `.inv-doc-form__ref` si ya no se usa
  - Verificar que no rompa nada antes de eliminar

- [x] **41.7** Build: `npm run build` sin errores.

---

### Archivos afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/inv-document-screen.tsx` | Reorganizar las 3 vistas (detalle/nuevo/ediciÃ³n) con layout compacto |
| `src/app/globals.css` | Pulir/limpiar CSS, verificar responsive |

---

## AJUSTE POSTERIOR â€” Inventario Documentos (secuencia + histÃ³rico cambios) (2026-03-28)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.19** Secuencia de documento en creaciÃ³n aumenta de uno en uno:
  - `inv-document-screen` ahora muestra preview de documento basado en `Prefijo + (SecuenciaActual + 1)`.
  - al crear documento, se sincroniza `SecuenciaActual` local con la secuencia retornada por backend para mantener el incremento consecutivo en la misma sesiÃ³n.
  - filtros `Secuencia Desde/Hasta` reforzados con `step=1`.

- [x] **A.20** HistÃ³rico de cambios del detalle (tab read-only) con permiso:
  - nuevo endpoint: `GET /api/inventory/documents/[id]/history`.
  - data layer: `getInvDocumentoDetalleHistory(...)` en `pos-data.ts` (incluye activos e histÃ³ricos por `RowStatus`).
  - UI detalle: pestaÃ±as `Detalle actual` / `Historico de cambios` (visible con permiso `inventory.documents.history.view` o superadmin).
  - script aplicado: `database/57_perm_historial_cambios_inventario.sql`.

- [x] **A.21** Limpieza de mapeo de permisos duplicado:
  - removida regla duplicada de `ROUTE_PERMISSIONS` para `/inventory/entries` con clave de histÃ³rico.
  - se dejÃ³ clave de histÃ³rico en patrÃ³n tÃ©cnico dedicado (`/inventory/documents/history`) para que superadmin reciba la key sin interferir con autorizaciÃ³n de ruta real.

- [x] **A.22** Build: `npm run build` sin errores.

---

## TAREA 42 â€” Fix Roles: Alinear MÃ³dulos a la Izquierda + Actualizar Pantallas/Permisos en UI

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** Script `database/56_pantallas_permisos_completos.sql` ya ejecutado en la DB.

**Objetivo:** Corregir la visualizaciÃ³n de mÃ³dulos en la pantalla de Roles para que el contenido se vea correctamente alineado a la izquierda, y verificar que las nuevas pantallas/permisos insertados por el script 56 se muestran correctamente en los tabs de MÃ³dulos y Pantallas.

---

### Checkpoints

- [x] **42.1** Fix visual: MÃ³dulos tab en Roles â€” alinear contenido a la izquierda:
  - `src/app/globals.css`: El grid `.roles-module-grid` usa `grid-template-columns: repeat(2, minmax(18rem, 1fr))` que puede causar overflow horizontal cuando el panel es angosto. Cambiar a un layout que se adapte mejor:
    - OpciÃ³n: `grid-template-columns: repeat(auto-fill, minmax(16rem, 1fr))` para que se ajuste automÃ¡ticamente.
  - `.roles-module-card > header`: Verificar que el texto del nombre del mÃ³dulo y conteo de pantallas estÃ© alineado a la izquierda (actualmente puede empujarse a la derecha por el grid `auto minmax(0,1fr) auto`).
  - `.roles-module-card__controls`: Verificar que el chip "Habilitado" y el toggle no empujen el texto fuera del card.
  - El nombre del mÃ³dulo y el conteo de pantallas deben ser visibles completos sin truncar.

- [x] **42.2** Fix visual: Pantallas tab en Roles â€” misma correcciÃ³n de alineaciÃ³n:
  - `.roles-screen-list` y `.roles-screen-collapsible`: verificar que los mÃ³dulos colapsibles muestran el Ã­cono + nombre + conteo de pantallas + chip alineados a la izquierda.
  - `.roles-screen-collapsible__header`: debe tener el texto alineado a la izquierda, no centrado ni empujado a la derecha.

- [x] **42.3** Verificar que los nuevos mÃ³dulos aparecen en el tab MÃ³dulos:
  - Los 4 mÃ³dulos nuevos (Salon, Inventario, Cuentas por Cobrar, Cuentas por Pagar) deben aparecer como cards con sus pantallas.
  - Los mÃ³dulos existentes (Dashboard, Ordenes, Punto de Venta, CatÃ¡logo, Reportes, ConfiguraciÃ³n, Seguridad) deben seguir mostrÃ¡ndose correctamente.
  - Si algÃºn mÃ³dulo nuevo no aparece, verificar que el SP que carga los mÃ³dulos de un rol (`spRolesCRUD` o similar) incluye los mÃ³dulos nuevos.

- [x] **42.4** Verificar que las nuevas pantallas aparecen en el tab Pantallas:
  - Al expandir cada mÃ³dulo en el tab Pantallas, deben aparecer todas sus pantallas con los toggles granulares (CanCreate, CanEdit, CanDelete, CanView, etc.).
  - Las 33 pantallas nuevas del script 56 deben estar visibles.
  - Si no aparecen, verificar el SP que carga las pantallas por rol.

- [x] **42.5** Verificar que al asignar/quitar permisos desde Roles funciona:
  - Toggle de mÃ³dulo on/off debe funcionar para los mÃ³dulos nuevos.
  - Toggle de pantalla on/off debe funcionar para las pantallas nuevas.
  - Los permisos granulares (CanCreate, CanEdit, CanDelete) deben poder togglarse.

- [x] **42.6** Build: `npm run build` sin errores.

---

### Referencia visual del problema

En el screenshot de Roles > tab MÃ³dulos, las cards muestran:
```
>                    Seguridad  3 Pantallas  Habilitado
>                    Dashboard  2 Pantallas  Habilitado
>                    Ordenes    3 Pantallas  Habilitado
```
El texto estÃ¡ empujado a la derecha y no se ve bien. Debe verse:
```
ðŸ”’ Seguridad    3 Pantallas    [Habilitado â—]
ðŸ“Š Dashboard    2 Pantallas    [Habilitado â—]
ðŸ›’ Ordenes      3 Pantallas    [Habilitado â—]
```
Con Ã­cono + nombre alineados a la izquierda y los controles a la derecha.

---

### Archivos afectados

| Archivo | Cambio |
|---|---|
| `src/app/globals.css` | Fix `.roles-module-grid`, `.roles-module-card`, `.roles-screen-collapsible` |
| `src/components/pos/security-roles-screen.tsx` | Posibles ajustes de markup si el CSS solo no resuelve |

---

## AJUSTE POSTERIOR â€” Inventario Documentos (navegaciÃ³n Anterior/Siguiente) (2026-03-28)

**Estado:** `COMPLETADA` âœ…

### Checkpoints

- [x] **A.23** Agregar navegaciÃ³n entre documentos en vista detalle:
  - `src/components/pos/inv-document-screen.tsx`:
    - aÃ±adidos botones `Anterior` y `Siguiente` en `inv-doc-detail-topbar__actions`.
    - navegaciÃ³n basada en el orden actual del listado (`sortedDocs`) respetando orden/ordenamiento activo.
    - botones se deshabilitan en primer/Ãºltimo documento del conjunto cargado.

- [x] **A.24** Build: `npm run build` sin errores.

---

## TAREA 43 â€” Fixes Urgentes Inventario + Columna ActualizaCosto + Fix CMP

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** Scripts 52-55 ejecutados en DB.

**Objetivo:** Corregir bugs crÃ­ticos en los SPs de inventario, agregar columna `ActualizaCosto` a `InvTiposDocumento` para controlar si un tipo de documento recalcula el Costo Medio Ponderado, y corregir la fÃ³rmula de CMP.

---

### Contexto: Costo Medio Ponderado (CMP)

```
Nuevo CMP = (CMP actual Ã— Stock actual + Costo entrada Ã— Cantidad entrada)
            Ã· (Stock actual + Cantidad entrada)
```

- **Solo se recalcula** cuando el tipo de documento tiene `ActualizaCosto = 1`
- **No se recalcula** en salidas, transferencias, ni entradas donde `ActualizaCosto = 0`
- **En anulaciones**: si el documento original tenÃ­a `ActualizaCosto = 1`, se reversa el CMP

---

### Checkpoints

- [x] **43.1** Script SQL `database/57_inv_fix_cmp_actualiza_costo.sql`:

  **a) Agregar columna `ActualizaCosto` a `InvTiposDocumento`:**
  ```sql
  ALTER TABLE dbo.InvTiposDocumento ADD ActualizaCosto BIT NOT NULL DEFAULT 0;

  -- Activar por defecto para tipo Compra (C)
  UPDATE dbo.InvTiposDocumento SET ActualizaCosto = 1 WHERE TipoOperacion = 'C';
  ```

  **b) Corregir bug de cÃ¡lculo de CMP en `spInvDocumentosCRUD` acciÃ³n I.**

  Bug actual (lÃ­nea ~243):
  ```sql
  -- INCORRECTO: resta det.Cantidad ANTES de haberla sumado
  SELECT ISNULL(SUM(pa2.Cantidad), 0) - det.Cantidad AS TotalQty
  ```

  CorrecciÃ³n:
  ```sql
  -- CORRECTO: stock ANTERIOR a la entrada (ya fue sumado en el paso anterior, restar para obtener el anterior)
  SELECT ISNULL(SUM(pa2.Cantidad), 0) - det.Cantidad AS TotalQtyAnterior
  -- O mejor: capturar el stock ANTES del UPDATE en una variable/CTE
  ```

  **c) Condicionar recÃ¡lculo de CMP a `ActualizaCosto`:**

  En acciÃ³n I, despuÃ©s de actualizar stock:
  ```sql
  -- Obtener si el tipo actualiza costo
  DECLARE @ActualizaCosto BIT;
  SELECT @ActualizaCosto = ActualizaCosto FROM dbo.InvTiposDocumento WHERE IdTipoDocumento = @IdTipoDocumento;

  -- Solo recalcular CMP si ActualizaCosto = 1 Y es entrada (E o C)
  IF @TipoOp IN ('E', 'C') AND @ActualizaCosto = 1
  BEGIN
    -- FÃ³rmula correcta del CMP:
    UPDATE p SET
      p.CostoPromedio = CASE
        WHEN (stockAnterior + det.Cantidad) > 0
        THEN ROUND((p.CostoPromedio * stockAnterior + det.Costo * det.Cantidad) / (stockAnterior + det.Cantidad), 4)
        ELSE det.Costo
      END
    ...
  END
  ```

  **d) Corregir anulaciÃ³n (acciÃ³n N) para reversar CMP:**
  ```sql
  -- Si el tipo original tenÃ­a ActualizaCosto = 1, reversar CMP
  DECLARE @ActualizaCostoOrig BIT;
  SELECT @ActualizaCostoOrig = t.ActualizaCosto
  FROM dbo.InvDocumentos d
  INNER JOIN dbo.InvTiposDocumento t ON t.IdTipoDocumento = d.IdTipoDocumento
  WHERE d.IdDocumento = @IdDocumento;

  IF @DocTipoOp IN ('E', 'C') AND @ActualizaCostoOrig = 1
  BEGIN
    -- Reversar CMP: quitar la entrada del promedio
    UPDATE p SET
      p.CostoPromedio = CASE
        WHEN (stockActual - det.Cantidad) > 0
        THEN ROUND((p.CostoPromedio * stockActual - det.Costo * det.Cantidad) / (stockActual - det.Cantidad), 4)
        ELSE p.CostoPromedio  -- si queda en 0, mantener Ãºltimo costo
      END
    ...
  END
  ```

  **e) Soft-delete detalle al anular:**
  ```sql
  -- En acciÃ³n N, despuÃ©s de reversar stock:
  UPDATE dbo.InvDocumentoDetalle SET RowStatus = 0
  WHERE IdDocumento = @IdDocumento AND RowStatus = 1;
  ```

  **f) Validar stock negativo en salidas:**
  ```sql
  -- En acciÃ³n I, antes de restar stock (solo para salidas S):
  IF @TipoOp = 'S'
  BEGIN
    IF EXISTS (
      SELECT 1 FROM dbo.InvDocumentoDetalle det
      INNER JOIN dbo.ProductoAlmacenes pa ON pa.IdProducto = det.IdProducto AND pa.IdAlmacen = @IdAlmacen
      INNER JOIN dbo.Productos p ON p.IdProducto = det.IdProducto
      WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1
        AND p.ManejaExistencia = 1 AND p.VenderSinExistencia = 0
        AND pa.Cantidad < det.Cantidad
    )
      THROW 50020, 'Stock insuficiente para uno o mas productos.', 1;
  END
  ```

  **g) Agregar SERIALIZABLE en transacciones crÃ­ticas:**
  ```sql
  -- Al inicio de acciÃ³n I y N:
  SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
  ```

- [x] **43.2** Actualizar `spInvActualizarDocumento` (script 55) con los mismos fixes:
  - Condicionar recÃ¡lculo de CMP a `ActualizaCosto`
  - Usar fÃ³rmula correcta de CMP
  - Agregar validaciÃ³n de stock negativo
  - Agregar SERIALIZABLE

- [x] **43.3** Actualizar `spInvTiposDocumentoCRUD` para incluir `ActualizaCosto`:
  - Agregar parÃ¡metro `@ActualizaCosto BIT = 0`
  - En acciones I y A: incluir el campo en INSERT/UPDATE
  - En acciones L y O: incluir el campo en SELECT

- [x] **43.4** Actualizar `src/lib/pos-data.ts`:
  - Agregar `actualizaCosto: boolean` a `InvTipoDocumentoRecord`
  - Actualizar `mapInvTipoDocRow` para mapear `ActualizaCosto`
  - Actualizar `saveInvTipoDocumento` para enviar `ActualizaCosto`

- [x] **43.5** Actualizar UI del formulario de Tipos de Documentos:
  - `src/components/pos/inv-doc-type-screen.tsx`: agregar toggle "Actualiza Costo" en el tab General, debajo de Moneda.
  - Solo visible/relevante para tipos de operaciÃ³n E y C (entradas). Para S y T puede mostrarse deshabilitado o no mostrarse.

- [x] **43.6** Homologar pantalla Salidas de Inventario con Entradas:
  - `src/app/inventory/exits/page.tsx` debe tener exactamente la misma estructura que `entries/page.tsx` (formatDateLocal, fechaDesde/fechaHasta, props initialList/initialFechaDesde/initialFechaHasta).
  - El componente `InvDocumentScreen` ya es compartido â€” verificar que con `tipoOperacion="S"` funciona idÃ©ntico al de "E": misma cabecera compacta (2 filas), mismo layout de detalle, mismos botones fuera del panel, misma grilla editable.
  - Verificar que la validaciÃ³n de stock negativo (checkpoint 43.1f) solo aplica a salidas, no a entradas.
  - Probar flujo completo: crear salida, editar, anular.

- [x] **43.7** Build: `npm run build` sin errores.

### Evidencia de cierre

- Scripts aplicados en DB:
  - `database/57_inv_fix_cmp_actualiza_costo.sql`
  - `database/55_sp_inv_actualizar_documento.sql`
- VerificaciÃ³n DB:
  - columna `InvTiposDocumento.ActualizaCosto` existe (`HAS_COLUMN true`).
  - `spInvTiposDocumentoCRUD` lista `ActualizaCosto` (`SP_LIST_HAS_ACTUALIZACOSTO true`).
  - resumen por tipo confirma activaciÃ³n por defecto en compras (`TipoOperacion='C'`).
- HomologaciÃ³n entradas/salidas validada: `src/app/inventory/exits/page.tsx` ya coincide estructuralmente con `src/app/inventory/entries/page.tsx`.

---

### Objetos de base de datos afectados

| Objeto | Tipo | AcciÃ³n |
|---|---|---|
| `InvTiposDocumento` | Tabla | ALTER â€” agregar `ActualizaCosto BIT` |
| `spInvDocumentosCRUD` | SP | RECREAR â€” fix CMP, anulaciÃ³n, validaciones |
| `spInvActualizarDocumento` | SP | RECREAR â€” mismos fixes |
| `spInvTiposDocumentoCRUD` | SP | RECREAR â€” incluir ActualizaCosto |

### Archivos de cÃ³digo afectados

| Archivo | Cambio |
|---|---|
| `src/lib/pos-data.ts` | Agregar `actualizaCosto` al tipo y funciones |
| `src/components/pos/inv-doc-type-screen.tsx` | Toggle "Actualiza Costo" en formulario |

---

## TAREA 44 â€” Tabla InvMovimientos (Kardex) + IntegraciÃ³n con SPs

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** TAREA 43 completada.

**Objetivo:** Crear la tabla de movimientos de inventario (Kardex) que registra cada operaciÃ³n con saldo anterior/nuevo, e integrarla en todos los SPs que modifican stock. Esto permite auditorÃ­a, consultas histÃ³ricas y es la base para reporterÃ­a.

---

### Checkpoints

- [x] **44.1** Script SQL `database/58_inv_movimientos.sql`:

  **a) Crear tabla `InvMovimientos`:**
  ```sql
  CREATE TABLE dbo.InvMovimientos (
    IdMovimiento       INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto         INT NOT NULL REFERENCES dbo.Productos(IdProducto),
    IdAlmacen          INT NOT NULL REFERENCES dbo.Almacenes(IdAlmacen),
    TipoMovimiento     VARCHAR(3) NOT NULL,  -- 'ENT','SAL','COM','TRF','ANU','AJU'
    Signo              SMALLINT NOT NULL,     -- +1 o -1
    IdDocumentoOrigen  INT NULL,              -- FK a InvDocumentos
    TipoDocOrigen      VARCHAR(20) NOT NULL,  -- 'InvDocumento','Factura','Ajuste'
    NumeroDocumento    VARCHAR(30) NULL,
    NumeroLinea        INT NULL,
    Cantidad           DECIMAL(18,4) NOT NULL,
    CostoUnitario      DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoTotal         DECIMAL(18,4) NOT NULL DEFAULT 0,
    SaldoAnterior      DECIMAL(18,4) NOT NULL,
    SaldoNuevo         DECIMAL(18,4) NOT NULL,
    CostoPromedioAnterior DECIMAL(10,4) NULL,
    CostoPromedioNuevo    DECIMAL(10,4) NULL,
    Fecha              DATE NOT NULL,
    Periodo            VARCHAR(6) NOT NULL,   -- YYYYMM
    Observacion        NVARCHAR(250) NULL,
    RowStatus          INT NOT NULL DEFAULT 1,
    FechaCreacion      DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion    INT NOT NULL DEFAULT 1
  );
  ```

  **b) Ãndices:**
  ```sql
  -- Kardex por producto (consulta principal)
  CREATE INDEX IX_InvMov_Prod_Fecha ON InvMovimientos (IdProducto, Fecha, IdMovimiento)
    INCLUDE (IdAlmacen, Cantidad, Signo, SaldoNuevo, CostoUnitario);

  -- Consultas por periodo (reportes mensuales)
  CREATE INDEX IX_InvMov_Periodo ON InvMovimientos (Periodo, IdAlmacen)
    INCLUDE (IdProducto, Cantidad, Signo, CostoTotal);

  -- Consultas por documento origen
  CREATE INDEX IX_InvMov_DocOrigen ON InvMovimientos (IdDocumentoOrigen)
    INCLUDE (IdProducto, Cantidad, Signo);
  ```

- [x] **44.2** Modificar `spInvDocumentosCRUD` acciÃ³n I â€” insertar movimientos:

  DespuÃ©s de actualizar stock en `ProductoAlmacenes`, por cada lÃ­nea del detalle:
  ```sql
  INSERT INTO dbo.InvMovimientos (
    IdProducto, IdAlmacen, TipoMovimiento, Signo,
    IdDocumentoOrigen, TipoDocOrigen, NumeroDocumento, NumeroLinea,
    Cantidad, CostoUnitario, CostoTotal,
    SaldoAnterior, SaldoNuevo,
    CostoPromedioAnterior, CostoPromedioNuevo,
    Fecha, Periodo, UsuarioCreacion
  )
  SELECT
    det.IdProducto,
    @IdAlmacen,
    CASE @TipoOp WHEN 'E' THEN 'ENT' WHEN 'S' THEN 'SAL' WHEN 'C' THEN 'COM' WHEN 'T' THEN 'TRF' END,
    CASE WHEN @TipoOp IN ('E','C') THEN 1 ELSE -1 END,
    @NewDocId, 'InvDocumento', @NumDoc, det.NumeroLinea,
    det.Cantidad, det.Costo, det.Total,
    pa.Cantidad - CASE WHEN @TipoOp IN ('E','C') THEN det.Cantidad ELSE -det.Cantidad END,  -- saldo anterior
    pa.Cantidad,  -- saldo nuevo (ya actualizado)
    NULL, NULL,  -- CMP se actualiza despuÃ©s si aplica
    @Fecha, @Periodo, @IdUsuario
  FROM dbo.InvDocumentoDetalle det
  INNER JOIN dbo.ProductoAlmacenes pa ON pa.IdProducto = det.IdProducto AND pa.IdAlmacen = @IdAlmacen
  WHERE det.IdDocumento = @NewDocId AND det.RowStatus = 1;
  ```

  Si `ActualizaCosto = 1`, actualizar `CostoPromedioAnterior` y `CostoPromedioNuevo` en los movimientos insertados.

- [x] **44.3** Modificar `spInvDocumentosCRUD` acciÃ³n N â€” insertar movimientos de anulaciÃ³n:

  Al anular, insertar movimientos inversos:
  ```sql
  -- TipoMovimiento = 'ANU', Signo invertido
  -- SaldoAnterior = stock antes de reversar, SaldoNuevo = stock despuÃ©s de reversar
  ```

- [x] **44.4** Modificar `spInvActualizarDocumento` â€” insertar movimientos de reversiÃ³n + nuevos:

  Al editar un documento:
  1. Insertar movimientos de reversiÃ³n del detalle anterior (como anulaciÃ³n parcial)
  2. Insertar movimientos nuevos del detalle actualizado

- [x] **44.5** Crear SP `spInvKardex`:
  ```sql
  CREATE PROCEDURE dbo.spInvKardex
    @IdProducto  INT,
    @IdAlmacen   INT = NULL,
    @FechaDesde  DATE = NULL,
    @FechaHasta  DATE = NULL
  AS
  BEGIN
    SELECT
      m.IdMovimiento,
      m.Fecha,
      m.TipoMovimiento,
      m.NumeroDocumento,
      m.Observacion,
      CASE WHEN m.Signo = 1 THEN m.Cantidad ELSE 0 END AS Entrada,
      CASE WHEN m.Signo = -1 THEN m.Cantidad ELSE 0 END AS Salida,
      m.SaldoNuevo AS Saldo,
      m.CostoUnitario,
      m.CostoTotal,
      m.CostoPromedioNuevo AS CostoPromedio,
      a.Descripcion AS NombreAlmacen
    FROM dbo.InvMovimientos m
    LEFT JOIN dbo.Almacenes a ON a.IdAlmacen = m.IdAlmacen
    WHERE m.IdProducto = @IdProducto
      AND m.RowStatus = 1
      AND (@IdAlmacen IS NULL OR m.IdAlmacen = @IdAlmacen)
      AND (@FechaDesde IS NULL OR m.Fecha >= @FechaDesde)
      AND (@FechaHasta IS NULL OR m.Fecha <= @FechaHasta)
    ORDER BY m.Fecha, m.IdMovimiento;
  END
  ```

- [x] **44.6** Crear API y funciÃ³n en pos-data.ts:
  - `getInvKardex(idProducto, idAlmacen?, fechaDesde?, fechaHasta?)` en pos-data.ts
  - API `GET /api/inventory/kardex?producto=X&almacen=Y&desde=Z&hasta=W`

- [x] **44.7** Tab "Movimientos" en Productos:
  - En `src/components/pos/catalog-products-screen.tsx`, el tab "Movimientos" ya existe (placeholder).
  - Implementar: tabla con columnas Fecha, Tipo, Documento, Entrada, Salida, Saldo, Costo, AlmacÃ©n.
  - Filtros: AlmacÃ©n (select), Fecha desde/hasta.

- [x] **44.8** Backfill: Generar movimientos para documentos existentes:
  - Script SQL que recorre `InvDocumentos` activos ordenados por fecha y genera los movimientos correspondientes en `InvMovimientos`.
  - Solo ejecutar una vez despuÃ©s de crear la tabla.

- [x] **44.9** Build: `npm run build` sin errores.

---

### Objetos de base de datos afectados

| Objeto | Tipo | AcciÃ³n |
|---|---|---|
| `InvMovimientos` | Tabla | CREAR |
| `IX_InvMov_Prod_Fecha` | Ãndice | CREAR |
| `IX_InvMov_Periodo` | Ãndice | CREAR |
| `IX_InvMov_DocOrigen` | Ãndice | CREAR |
| `spInvDocumentosCRUD` | SP | RECREAR â€” integrar movimientos |
| `spInvActualizarDocumento` | SP | RECREAR â€” integrar movimientos |
| `spInvKardex` | SP | CREAR |

### Archivos de cÃ³digo afectados

| Archivo | Cambio |
|---|---|
| `src/lib/pos-data.ts` | Tipo `InvKardexRecord`, funciÃ³n `getInvKardex` |
| `src/app/api/inventory/kardex/route.ts` | API GET kardex |
| `src/components/pos/catalog-products-screen.tsx` | Tab Movimientos con tabla de kardex |

---

## TAREA 48 â€” Unidades de Medida: Rediseno 2 Paneles

**Estado:** `COMPLETADA`

**Contexto:**
- Pantalla actual: `src/app/config/catalog/units/page.tsx` usa `CatalogMastersManager` que a su vez usa `EntityCrudSection` (tabla simple + modal).
- Se debe seguir el patrÃ³n de 2 paneles ya implementado en Tipos de Producto, Listas de Precios, etc.
- DB: tabla `dbo.UnidadesMedida` (IdUnidadMedida, Nombre, Abreviatura, BaseA, BaseB, Activo, ...).
- SP: `dbo.spUnidadesMedidaCRUD` ya existe y fue actualizado en `database/31_unidades_medida_crud_return.sql` para retornar la fila en I y A.
- Acceso completo a DB.

**Objetivo:** Reemplazar el `EntityCrudSection` genÃ©rico por un componente dedicado `catalog-units-screen.tsx` con layout de 2 paneles.

### Checkpoints

- [ ] **48.1** API: Crear `src/app/api/catalog/units/route.ts` (GET listar, POST crear) y `src/app/api/catalog/units/[id]/route.ts` (PUT actualizar, DELETE eliminar). Usar `spUnidadesMedidaCRUD`.

- [ ] **48.2** Data layer: Agregar en `src/lib/pos-data.ts`: `getUnits()`, `createUnit(data)`, `updateUnit(id, data)`, `deleteUnit(id)`.

- [ ] **48.3** UI: Crear `src/components/pos/catalog-units-screen.tsx`:
      Layout 2 paneles (igual que `price-lists-screen.tsx`):
      - **Panel izquierdo (320px):** busqueda + boton "+ Nueva Unidad", lista de unidades con badge Activo/Inactivo, menu 3 puntos (Editar, Duplicar, Eliminar).
      - **Panel derecho:** titulo de la unidad seleccionada, patron "Editar Datos":
        - Campo Nombre (requerido)
        - Campo Abreviatura
        - Campo Base A (entero)
        - Campo Base B (entero)
        - Campo Unidades Calculadas (readonly, `BaseA / BaseB`)
        - Switch Activo
      - Estado vacio cuando no hay unidad seleccionada.
      - CSS BEM prefijo `.units-*`.

- [ ] **48.4** Pagina: Actualizar `src/app/config/catalog/units/page.tsx` para usar `CatalogUnitsScreen` en lugar de `CatalogMastersManager`.

- [ ] **48.5** CSS + Build: Estilos en `globals.css`. `npm run build` sin errores.

---

## TAREA 45 â€” Saldos Mensuales + ReporterÃ­a Base

**Estado:** `COMPLETADA` âœ…

**Prerequisito:** TAREA 44 completada.

**Objetivo:** Crear tabla de saldos mensuales para reporterÃ­a rÃ¡pida sin recorrer todo el histÃ³rico de movimientos, y los reportes base de inventario.

---

### Checkpoints

- [x] **45.1** Script SQL `database/59_inv_saldos_mensuales.sql`:

  **a) Crear tabla `InvSaldosMensuales`:**
  ```sql
  CREATE TABLE dbo.InvSaldosMensuales (
    IdSaldoMensual    INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto        INT NOT NULL REFERENCES dbo.Productos(IdProducto),
    IdAlmacen         INT NOT NULL REFERENCES dbo.Almacenes(IdAlmacen),
    Periodo           VARCHAR(6) NOT NULL,    -- YYYYMM
    SaldoInicial      DECIMAL(18,4) NOT NULL DEFAULT 0,
    Entradas          DECIMAL(18,4) NOT NULL DEFAULT 0,
    Salidas           DECIMAL(18,4) NOT NULL DEFAULT 0,
    SaldoFinal        DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoPromedio     DECIMAL(10,4) NOT NULL DEFAULT 0,
    ValorInventario   DECIMAL(18,4) NOT NULL DEFAULT 0,
    FechaCierre       DATETIME NULL,
    RowStatus         INT NOT NULL DEFAULT 1,
    FechaCreacion     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_InvSaldosMensuales UNIQUE (IdProducto, IdAlmacen, Periodo)
  );

  CREATE INDEX IX_InvSaldos_Periodo ON InvSaldosMensuales (Periodo)
    INCLUDE (IdProducto, SaldoFinal, ValorInventario);
  ```

  **b) SP de cierre mensual `spInvCierreMensual`:**
  ```sql
  -- Recibe @Periodo VARCHAR(6) (ej: '202603')
  -- Para cada combinaciÃ³n producto/almacÃ©n:
  --   SaldoInicial = SaldoFinal del mes anterior (o 0 si no existe)
  --   Entradas = SUM(Cantidad) de movimientos con Signo=+1 del periodo
  --   Salidas = SUM(Cantidad) de movimientos con Signo=-1 del periodo
  --   SaldoFinal = SaldoInicial + Entradas - Salidas
  --   CostoPromedio = Ãºltimo CostoPromedioNuevo del periodo (o del anterior)
  --   ValorInventario = SaldoFinal * CostoPromedio
  -- UPSERT: INSERT si no existe, UPDATE si ya existe (re-cierre)
  ```

  **c) SP de consulta `spInvExistenciaAlFecha`:**
  ```sql
  -- Recibe @Fecha DATE, @IdProducto INT (opcional), @IdAlmacen INT (opcional)
  -- Estrategia:
  --   1. Buscar Ãºltimo SaldoMensual antes del mes de @Fecha
  --   2. Sumar movimientos desde ese cierre hasta @Fecha
  --   3. Retornar existencia a esa fecha
  ```

- [x] **45.2** Crear API:
  - `POST /api/inventory/cierre-mensual` â€” ejecuta cierre de un periodo
  - `GET /api/inventory/existencia-al-fecha?fecha=X&producto=Y&almacen=Z`

- [x] **45.3** Funciones en pos-data.ts:
  - `ejecutarCierreMensual(periodo: string)`
  - `getExistenciaAlFecha(fecha, idProducto?, idAlmacen?)`

- [x] **45.4** Build: `npm run build` sin errores.

### Evidencia de cierre 44/45

- Scripts aplicados en DB:
  - `database/58_inv_movimientos.sql`
  - `database/59_inv_saldos_mensuales.sql`
- VerificaciÃ³n tÃ©cnica:
  - `INV_MOV_ROWS 2`
  - `HAS_SALDOS_TABLE true`
  - `KARDEX_ROWS_SAMPLE 2`
  - `CIERRE_RESULT { Periodo: '202603', RegistrosCerrados: 1 }`
  - `EXISTENCIA_ROWS 1`
- APIs nuevas visibles en build:
  - `/api/inventory/kardex`
  - `/api/inventory/cierre-mensual`
  - `/api/inventory/existencia-al-fecha`

---

### Objetos de base de datos afectados

| Objeto | Tipo | AcciÃ³n |
|---|---|---|
| `InvSaldosMensuales` | Tabla | CREAR |
| `spInvCierreMensual` | SP | CREAR |
| `spInvExistenciaAlFecha` | SP | CREAR |

### Archivos de cÃ³digo afectados

| Archivo | Cambio |
|---|---|
| `src/lib/pos-data.ts` | Funciones de cierre y consulta histÃ³rica |
| `src/app/api/inventory/cierre-mensual/route.ts` | API POST cierre |
| `src/app/api/inventory/existencia-al-fecha/route.ts` | API GET existencia |

---

## TAREA 46 â€” PideUnidadInventario: SelecciÃ³n de Unidad de Medida en Detalle de Documentos de Inventario

**Estado:** `COMPLETADA` âœ…

**Contexto:**
- La tabla `Productos` ya tiene `PideUnidad BIT` para facturaciÃ³n (punto de venta).
- Se requiere un campo equivalente `PideUnidadInventario BIT DEFAULT 0` que controle si al agregar un producto a operaciones de inventario (Entradas, Salidas, Compras, Transferencias) el usuario puede cambiar la unidad de medida.
- El producto puede tener hasta 5 unidades: `IdUnidadMedida` (base), `IdUnidadVenta`, `IdUnidadCompra`, `IdUnidadAlterna1`, `IdUnidadAlterna2`, `IdUnidadAlterna3`.
- El componente compartido `src/components/pos/inv-document-screen.tsx` maneja el detalle de todos los tipos de operaciÃ³n.
- El SP de bÃºsqueda de productos para documentos es `dbo.spInvBuscarProducto`.
- El tipo TypeScript del producto es `InvProductoParaDocumento` en `src/lib/pos-data.ts`.
- La lÃ­nea de detalle es `LineaDetalle` (tipo local en inv-document-screen.tsx) con campo `idUnidadMedida: number | null` y `unidad: string`.
- Actualmente el campo Unidad en la grilla estÃ¡ como `<input value={line.unidad} disabled className="inv-doc-grid__readonly" />`.

**Objetivo:** Cuando `PideUnidadInventario = 1` en un producto, al seleccionarlo/escanearlo en la grilla de detalle de inventario, el campo Unidad se convierte en un `<select>` con todas las unidades disponibles del producto. La unidad y cantidad seleccionadas se guardan en `InvDocumentoDetalle`.

### Checkpoints

- [x] **46.1** DB â€” Crear script `database/60_productos_pide_unidad_inventario.sql`:

  **a) Agregar columna a Productos:**
  ```sql
  -- Verificar si ya existe antes de agregar
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Productos' AND COLUMN_NAME = 'PideUnidadInventario'
  )
  BEGIN
    ALTER TABLE Productos ADD PideUnidadInventario BIT NOT NULL DEFAULT 0
  END
  ```

  **b) Actualizar SP `spProductosCRUD`** (acciÃ³n 'U' e 'I') para incluir `@PideUnidadInventario BIT = 0` como parÃ¡metro y guardarlo en la tabla.

  **c) Actualizar SP `spInvBuscarProducto`** para retornar:
  - `PideUnidadInventario` (de Productos)
  - Las unidades disponibles del producto: `IdUnidadMedida`, `NombreUnidad` (join UnidadesMedida), `AbreviaturaUnidad`
  - `IdUnidadVenta`, `NombreUnidadVenta`, `AbreviaturaUnidadVenta`
  - `IdUnidadCompra`, `NombreUnidadCompra`, `AbreviaturaUnidadCompra`
  - `IdUnidadAlterna1`, `NombreUnidadAlterna1`, `AbreviaturaUnidadAlterna1` (nullable)
  - `IdUnidadAlterna2`, `NombreUnidadAlterna2`, `AbreviaturaUnidadAlterna2` (nullable)
  - `IdUnidadAlterna3`, `NombreUnidadAlterna3`, `AbreviaturaUnidadAlterna3` (nullable)

  Los joins adicionales son LEFT JOIN a UnidadesMedida (aliased um2, um3, um4, um5, um6) para cada unidad alternativa.

  **IMPORTANTE:** El SP debe omitir duplicados â€” si IdUnidadVenta == IdUnidadMedida, no listarlo dos veces. La lÃ³gica de deduplicaciÃ³n puede hacerse en el SP o en el mapper TypeScript.

- [x] **46.2** TypeScript â€” Actualizar `src/lib/pos-data.ts`:

  **a) Extender `InvProductoParaDocumento`:**
  ```typescript
  export type UnidadOpcion = {
    id: number
    nombre: string
    abreviatura: string
  }

  export type InvProductoParaDocumento = {
    id: number
    codigo: string
    nombre: string
    idUnidadMedida: number | null
    nombreUnidad: string
    abreviaturaUnidad: string
    costoPromedio: number
    manejaExistencia: boolean
    existencia: number
    pideUnidadInventario: boolean   // NUEVO
    unidades: UnidadOpcion[]        // NUEVO: lista de unidades disponibles (sin duplicados)
  }
  ```

  **b) Actualizar `mapInvProductoParaDocRow`** para mapear los nuevos campos:
  ```typescript
  function mapInvProductoParaDocRow(row: QueryRow): InvProductoParaDocumento {
    const unidades: UnidadOpcion[] = []
    const seen = new Set<number>()

    // FunciÃ³n helper para agregar unidad sin duplicar
    function addUnit(id: number | null, nombre: string, abrev: string) {
      if (id && !seen.has(id)) {
        seen.add(id)
        unidades.push({ id, nombre, abreviatura: abrev })
      }
    }

    addUnit(row.IdUnidadMedida ? toNumber(row.IdUnidadMedida) : null, toText(row.NombreUnidad), toText(row.AbreviaturaUnidad))
    addUnit(row.IdUnidadVenta ? toNumber(row.IdUnidadVenta) : null, toText(row.NombreUnidadVenta), toText(row.AbreviaturaUnidadVenta))
    addUnit(row.IdUnidadCompra ? toNumber(row.IdUnidadCompra) : null, toText(row.NombreUnidadCompra), toText(row.AbreviaturaUnidadCompra))
    addUnit(row.IdUnidadAlterna1 ? toNumber(row.IdUnidadAlterna1) : null, toText(row.NombreUnidadAlterna1), toText(row.AbreviaturaUnidadAlterna1))
    addUnit(row.IdUnidadAlterna2 ? toNumber(row.IdUnidadAlterna2) : null, toText(row.NombreUnidadAlterna2), toText(row.AbreviaturaUnidadAlterna2))
    addUnit(row.IdUnidadAlterna3 ? toNumber(row.IdUnidadAlterna3) : null, toText(row.NombreUnidadAlterna3), toText(row.AbreviaturaUnidadAlterna3))

    return {
      id: toNumber(row.IdProducto),
      codigo: toText(row.Codigo),
      nombre: toText(row.Nombre),
      idUnidadMedida: row.IdUnidadMedida != null ? toNumber(row.IdUnidadMedida) : null,
      nombreUnidad: toText(row.NombreUnidad),
      abreviaturaUnidad: toText(row.AbreviaturaUnidad),
      costoPromedio: Number(row.CostoPromedio ?? 0),
      manejaExistencia: Boolean(row.ManejaExistencia),
      existencia: Number(row.Existencia ?? 0),
      pideUnidadInventario: Boolean(row.PideUnidadInventario),
      unidades,
    }
  }
  ```

- [x] **46.3** TypeScript â€” Actualizar `src/components/pos/inv-document-screen.tsx`:

  **a) Extender `LineaDetalle`** (tipo local) para incluir:
  ```typescript
  type LineaDetalle = {
    key: string
    idProducto: number | null
    codigo: string
    descripcion: string
    unidad: string
    idUnidadMedida: number | null
    cantidad: number
    costo: number
    total: number
    pideUnidadInventario: boolean      // NUEVO
    unidadesDisponibles: UnidadOpcion[] // NUEVO
  }
  ```

  **b) Actualizar `emptyLine()`** para incluir los nuevos campos con valores default (`false`, `[]`).

  **c) Actualizar `lookupCode()` y `selectProduct()`** para poblar `pideUnidadInventario` y `unidadesDisponibles` desde el producto retornado por la API.

  **d) Reemplazar el campo Unidad en la grilla:**

  Antes (readonly):
  ```tsx
  <td><input value={line.unidad} disabled className="inv-doc-grid__readonly" /></td>
  ```

  DespuÃ©s (condicional):
  ```tsx
  <td>
    {line.pideUnidadInventario && line.unidadesDisponibles.length > 1 ? (
      <select
        className="inv-doc-grid__unit-select"
        value={line.idUnidadMedida ?? ""}
        onChange={e => {
          const selected = line.unidadesDisponibles.find(u => u.id === Number(e.target.value))
          if (selected) {
            updateLine(line.key, {
              idUnidadMedida: selected.id,
              unidad: selected.abreviatura || selected.nombre,
            })
          }
        }}
      >
        {line.unidadesDisponibles.map(u => (
          <option key={u.id} value={u.id}>{u.nombre} ({u.abreviatura})</option>
        ))}
      </select>
    ) : (
      <input value={line.unidad} disabled className="inv-doc-grid__readonly" />
    )}
  </td>
  ```

  **e) CSS:** Agregar en el archivo CSS correspondiente (o en `globals.css`):
  ```css
  .inv-doc-grid__unit-select {
    width: 100%;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    padding: 2px 4px;
    font-size: inherit;
    background: var(--bg-input, #fff);
  }
  ```

- [x] **46.4** TypeScript â€” Actualizar `src/components/pos/catalog-products-screen.tsx`:

  Agregar el toggle `PideUnidadInventario` en la tab "ParÃ¡metros" junto al toggle existente `PideUnidad` (facturaciÃ³n). El toggle debe seguir el mismo patrÃ³n visual que los demÃ¡s toggles en esa secciÃ³n.

  El campo en el formulario del producto (local state) se llama `requestUnitInventory: boolean` y se mapea a `PideUnidadInventario` en el SP.

  Actualizar tambiÃ©n:
  - El tipo local del formulario de producto (si existe) para agregar `requestUnitInventory`
  - El mapper que convierte el row de DB al estado del form (agregar `requestUnitInventory: Boolean(row.PideUnidadInventario ?? false)`)
  - El payload al guardar (agregar `PideUnidadInventario: formData.requestUnitInventory`)
  - En `pos-data.ts`, agregar `requestUnitInventory: boolean` al tipo `CatalogProduct` y en el mapper `mapCatalogProductRow`, y en los inputs de `createCatalogProduct` / `updateCatalogProduct`.

- [x] **46.5** Build: Ejecutar `npm run build` y confirmar 0 errores TypeScript. Verificar visualmente que:
  Nota 2026-03-29: `npm run build` bloqueado por `EPERM` sobre `D:\Masu\V2\.next\app-path-routes-manifest.json` (archivo en uso). ValidaciÃ³n alternativa ejecutada: `npx tsc --noEmit` OK.
  - En la pantalla de productos, aparece el nuevo toggle "Pedir unidad de medida en inventario" en la tab ParÃ¡metros.
  - En Entradas/Salidas, al seleccionar un producto con `PideUnidadInventario=1` y mÃ¡s de 1 unidad disponible, el campo Unidad muestra un `<select>` con todas las unidades.
  - Al seleccionar una unidad diferente en el select, se actualiza correctamente el campo `unidad` e `idUnidadMedida` en la lÃ­nea.

### Checkpoint de permisos

No se requieren nuevas claves de permiso para esta tarea (es una mejora a funcionalidad existente).

### Objetos de base de datos afectados

| Objeto | Tipo | AcciÃ³n |
|---|---|---|
| `Productos` | Tabla | ALTER â€” agregar columna `PideUnidadInventario BIT DEFAULT 0` |
| `spProductosCRUD` | SP | RECREAR â€” agregar parÃ¡metro `@PideUnidadInventario` en I/U |
| `spInvBuscarProducto` | SP | RECREAR â€” retornar `PideUnidadInventario` + unidades alternas |

### Archivos de cÃ³digo afectados

| Archivo | Cambio |
|---|---|
| `database/60_productos_pide_unidad_inventario.sql` | Script SQL nuevo |
| `src/lib/pos-data.ts` | Tipo `InvProductoParaDocumento` + `UnidadOpcion` + mapper + tipo `CatalogProduct` + funciones create/update |
| `src/components/pos/inv-document-screen.tsx` | `LineaDetalle` + `emptyLine` + `lookupCode` + `selectProduct` + render Unidad condicional + CSS |
| `src/components/pos/catalog-products-screen.tsx` | Toggle `PideUnidadInventario` en tab ParÃ¡metros |

---

## TAREA 47 â€” Reemplazar Radio Buttons "Unidad Base para Existencia" por Dropdown

**Estado:** `COMPLETADA` âœ…

**Contexto:**
- En la pantalla de productos (`src/components/pos/catalog-products-screen.tsx`), tab "Unidades", existe un bloque "UNIDAD BASE PARA CONSULTAS DE EXISTENCIA" con 5 radio buttons: Medida, Compra, Alterna 1, Alterna 2, Alterna 3.
- Este bloque se ve duplicado visualmente respecto al dropdown "Unidad base *" que estÃ¡ justo arriba.
- El valor se persiste en `Productos.UnidadBaseExistencia` (NVarChar) con los valores: `"measure"`, `"purchase"`, `"alternate1"`, `"alternate2"`, `"alternate3"`.
- La lÃ³gica existe y funciona â€” solo hay que cambiar el control de UI (radios â†’ select).
- El estado local es `baseUnitForStock: BaseUnitForStock` controlado por `setBaseUnitForStock`.
- El tipo `BaseUnitForStock = "measure" | "purchase" | "alternate1" | "alternate2" | "alternate3"`.

**Objetivo:** Reemplazar el bloque de radio buttons por un `<select>` con las mismas 5 opciones hardcodeadas, manteniendo la misma lÃ³gica de estado y persistencia. No se toca la DB ni pos-data.ts.

### Checkpoints

- [x] **47.1** En `src/components/pos/catalog-products-screen.tsx`, localizar el bloque:
  ```tsx
  <div className="products-base-unit">
    <p className="products-base-unit__label">Unidad base para consultas de existencia</p>
    <div className="products-base-unit__options">
      {(["measure", "purchase", "alternate1", "alternate2", "alternate3"] as BaseUnitForStock[]).map((val) => (
        <label key={val} className="products-radio">
          <input type="radio" name="baseUnit" value={val} disabled={!isEditing}
            checked={baseUnitForStock === val}
            onChange={() => setBaseUnitForStock(val)} />
          {{ measure: "Medida", purchase: "Compra", alternate1: "Alterna 1", alternate2: "Alterna 2", alternate3: "Alterna 3" }[val]}
        </label>
      ))}
    </div>
  </div>
  ```

  Reemplazarlo por:
  ```tsx
  <div className="products-field-row">
    <label className="products-field-label">Unidad base para existencias</label>
    <select
      className="products-select"
      value={baseUnitForStock}
      disabled={!isEditing}
      onChange={e => setBaseUnitForStock(e.target.value as BaseUnitForStock)}
    >
      <option value="measure">Unidad de Medida (Base)</option>
      <option value="purchase">Unidad de Compra</option>
      <option value="alternate1">Alterna 1</option>
      <option value="alternate2">Alterna 2</option>
      <option value="alternate3">Alterna 3</option>
    </select>
  </div>
  ```

  Usar las clases CSS existentes del formulario (`products-field-row`, `products-field-label`, `products-select`) para que quede consistente con el resto de la secciÃ³n.

- [x] **47.2** Eliminar o dejar de usar las clases CSS `products-base-unit`, `products-base-unit__label`, `products-base-unit__options`, `products-radio` si ya no se usan en ningÃºn otro lugar del archivo. Buscar con grep antes de eliminar.

- [x] **47.3** Build: `npm run build` sin errores TypeScript.

### Objetos de base de datos afectados

Ninguno â€” cambio exclusivo de UI.

### Archivos de cÃ³digo afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/catalog-products-screen.tsx` | Reemplazar bloque radio buttons por `<select>` |

---

## TAREA 49 — Transferencias de Inventario (Pantalla Completa)

**Estado:** `COMPLETADA` ✅

**Contexto:**
- La pantalla `/inventory/transfers` es un stub ("Proximamente").
- `InvDocumentos` soporta `TipoOperacion='T'` pero no tiene logica implementada.
- `ProductoAlmacenes` tiene columna `CantidadTransito` (sin uso actual).
- La tabla `Almacenes` soporta `TipoAlmacen='T'` (transito).
- El componente `inv-document-screen.tsx` maneja E/S/C pero transfers necesita flujo propio (2 almacenes + estados).

**Objetivo:** Implementar transferencias de inventario con flujo multi-paso:
1. Crear transferencia (borrador): elegir tipo, almacen origen/destino, fecha, productos.
2. Guardar: solo persiste cabecera + detalle, sin movimiento de stock.
3. Generar Salida: resta stock de origen, suma en almacen de transito del origen.
4. Confirmar Recepcion: resta stock de transito, suma en almacen destino.

**Decisiones de diseno:**
- Transito via almacen fisico tipo T (cada almacen tiene su transito predeterminado via `Almacenes.IdAlmacenTransito`).
- Tabla separada `InvTransferencias` (1:1 con `InvDocumentos`) para almacen destino, transito y estado.
- Estados: `B` (Borrador), `T` (En Transito), `C` (Completado), `N` (Anulado).
- Transferencias completadas NO se pueden anular (crear transferencia inversa manual).
- `IdAlmacenTransito` obligatorio al crear/editar almacenes (tipos C, V, N, O).

### Checkpoints

- [ ] **49.1** DB: Crear `database/63_inv_transferencias.sql` con:

  **a) Columna `IdAlmacenTransito` en `Almacenes`:**
  ```sql
  IF COL_LENGTH('dbo.Almacenes', 'IdAlmacenTransito') IS NULL
  BEGIN
    ALTER TABLE dbo.Almacenes
      ADD IdAlmacenTransito INT NULL
      CONSTRAINT FK_Almacenes_AlmacenTransito FOREIGN KEY REFERENCES dbo.Almacenes(IdAlmacen);
  END
  ```

  **b) Almacen de transito por defecto:** Insertar almacen tipo T ("Transito General", siglas "TRN") si no existe. Asignar como default a todos los almacenes que no tengan transito asignado.

  **c) Actualizar `spAlmacenesCRUD`:**
  - Acciones I/A: agregar parametro `@IdAlmacenTransito INT = NULL`. Si `TipoAlmacen <> 'T'`, validar que no sea NULL y que apunte a almacen tipo T activo.
  - Acciones L/O: retornar `IdAlmacenTransito` + nombre del almacen de transito (LEFT JOIN).

  **d) Tabla `InvTransferencias`:**
  ```sql
  CREATE TABLE dbo.InvTransferencias (
    IdDocumento           INT NOT NULL PRIMARY KEY
                          CONSTRAINT FK_InvTransf_Doc FOREIGN KEY REFERENCES dbo.InvDocumentos(IdDocumento),
    IdAlmacenDestino      INT NOT NULL
                          CONSTRAINT FK_InvTransf_AlmDest FOREIGN KEY REFERENCES dbo.Almacenes(IdAlmacen),
    IdAlmacenTransito     INT NOT NULL
                          CONSTRAINT FK_InvTransf_AlmTran FOREIGN KEY REFERENCES dbo.Almacenes(IdAlmacen),
    EstadoTransferencia   CHAR(1) NOT NULL DEFAULT 'B'
                          CONSTRAINT CK_InvTransf_Estado CHECK (EstadoTransferencia IN ('B','T','C','N')),
    FechaSalida           DATETIME NULL,
    FechaRecepcion        DATETIME NULL,
    UsuarioSalida         INT NULL,
    UsuarioRecepcion      INT NULL,
    IdSesionSalida        INT NULL,
    IdSesionRecepcion     INT NULL,
    RowStatus             INT NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion       INT NOT NULL,
    FechaModificacion     DATETIME NULL,
    UsuarioModificacion   INT NULL
  );
  ```

  **e) SP `spInvTransferenciasCRUD`** con acciones:
  - `I` (Insert): Crea InvDocumentos(TipoOp='T') + detalle JSON + InvTransferencias(estado='B'). Lee IdAlmacenTransito del almacen origen (snapshot). **Sin movimiento de stock.** Retorna documento.
  - `U` (Update): Solo si estado='B'. Actualiza cabecera + soft-delete detalle + inserta nuevo. Si cambio almacen origen, re-lee IdAlmacenTransito. **Sin stock.**
  - `GS` (Generar Salida): Solo estado='B'. SERIALIZABLE. Valida stock suficiente en origen. `Cantidad -= X` en origen, `Cantidad += X` en transito (INSERT si no existe ProductoAlmacenes). Estadoâ†’'T', FechaSalida.
  - `CR` (Confirmar Recepcion): Solo estado='T'. SERIALIZABLE. `Cantidad -= X` en transito, `Cantidad += X` en destino (INSERT si no existe). Actualiza CostoPromedio en destino. Estadoâ†’'C', FechaRecepcion.
  - `N` (Anular): Bâ†’marca anulado. Tâ†’revierte salida (origen+, transito-). Câ†’RECHAZAR "Transferencias completadas no pueden anularse."
  - `O` (Obtener): JOIN InvDocumentos + InvTransferencias + Almacenes(origen/destino/transito). 2 recordsets.
  - `L` (Listar): Filtros fechas, almacen, tipoDoc, estadoTransferencia. Columnas extra: NombreAlmacenDestino, EstadoTransferencia.

  **f) Guardia en `spInvDocumentosCRUD`:** Rechazar TipoOp='T' en acciones I y N con THROW 50030.

- [ ] **49.2** DB: Crear `database/64_inv_transferencias_permisos.sql`:
  Insertar en `Pantallas` y permisos para:
  - `inventory.transfers.view`
  - `inventory.transfers.edit`
  - `inventory.transfers.void`
  - `inventory.transfers.print`
  - `inventory.transfers.generate-exit`
  - `inventory.transfers.confirm-reception`
  Asignar todas al rol admin (IdRol=1).

- [ ] **49.3** TypeScript â€” Actualizar `src/lib/pos-data.ts`:

  **a) Actualizar `WarehouseRecord`:** Agregar `transitWarehouseId: number | null` y `transitWarehouseName: string`. Actualizar `mapWarehouseRow`. Actualizar `createWarehouse`/`updateWarehouse` para enviar `@IdAlmacenTransito`.

  **b) Tipos nuevos:**
  ```typescript
  export type InvTransferenciaEstado = "B" | "T" | "C" | "N"

  export type InvTransferenciaRecord = InvDocumentoRecord & {
    idAlmacenDestino: number
    nombreAlmacenDestino: string
    idAlmacenTransito: number
    nombreAlmacenTransito: string
    estadoTransferencia: InvTransferenciaEstado
    fechaSalida: string
    fechaRecepcion: string
  }

  export type InvTransferenciasListResult = {
    items: InvTransferenciaRecord[]
    total: number
    page: number
    pageSize: number
  }
  ```

  **c) Funciones nuevas (7):**
  - `createInvTransferencia(input, session)` â†’ SP accion I
  - `updateInvTransferencia(id, input, session)` â†’ SP accion U
  - `getInvTransferencia(id)` â†’ SP accion O
  - `listInvTransferencias(filters)` â†’ SP accion L (filtro extra: estadoTransferencia)
  - `generarSalidaTransferencia(id, session)` â†’ SP accion GS
  - `confirmarRecepcionTransferencia(id, session)` â†’ SP accion CR
  - `anularTransferencia(id, session)` â†’ SP accion N

  Todas con try/catch fallback para bug mssql.

- [ ] **49.4** TypeScript â€” Actualizar `src/components/pos/org-warehouses-screen.tsx`:
  Agregar campo "Almacen de Transito" (dropdown filtrado a almacenes tipo T) en form de crear/editar almacen. Obligatorio para tipos C, V, N, O. Oculto para tipo T. Mostrar en vista de detalle.

- [ ] **49.5** TypeScript â€” Crear API routes:

  **a) `src/app/api/inventory/transfers/route.ts`:** GET (list), POST (create). Usar `validateApiSession`.

  **b) `src/app/api/inventory/transfers/[id]/route.ts`:** GET (get), PUT (update), DELETE (void).

  **c) `src/app/api/inventory/transfers/[id]/generate-exit/route.ts`:** POST. Llama `generarSalidaTransferencia`.

  **d) `src/app/api/inventory/transfers/[id]/confirm-reception/route.ts`:** POST. Llama `confirmarRecepcionTransferencia`.

- [ ] **49.6** TypeScript â€” Actualizar `src/lib/permissions.ts`:
  Agregar al tipo PermissionKey:
  `"inventory.transfers.view"`, `"inventory.transfers.edit"`, `"inventory.transfers.void"`, `"inventory.transfers.print"`, `"inventory.transfers.generate-exit"`, `"inventory.transfers.confirm-reception"`.
  Actualizar route rule de `/inventory/transfers` de `catalog.view` a `inventory.transfers.view`.

- [ ] **49.7** TypeScript â€” Crear `src/components/pos/inv-transfer-screen.tsx`:
  Adaptado de `inv-document-screen.tsx` con:
  - Dos dropdowns de almacen (origen y destino), filtrados para excluir tipo T.
  - Validacion: origen !== destino.
  - Sin campos de compra (proveedor, NCF, fechaFactura).
  - Lista con columnas extra: "Destino" y "Estado" (badges: B=gris, T=naranja, C=verde, N=rojo).
  - Detalle con badge de estado + botones segun estado:
    - B: [Editar] [Generar Salida] [Anular]
    - T: [Confirmar Recepcion] [Anular]
    - C: [Imprimir]
    - N: [Imprimir]
  - Dialogos de confirmacion para "Generar Salida" y "Confirmar Recepcion".
  - POST/PUT a `/api/inventory/transfers/`.

- [ ] **49.8** TypeScript â€” Actualizar `src/app/inventory/transfers/page.tsx`:
  Reemplazar stub por server component que llama `getInvTiposDocumento("T")`, `getWarehouses()`, `listInvTransferencias(...)` y renderiza `<InvTransferScreen>`.

- [ ] **49.9** CSS â€” Agregar en `src/app/globals.css`:
  Clases BEM `.inv-transfer-badge` + `--draft` (gris), `--transit` (naranja), `--completed` (verde), `--voided` (rojo). `.inv-transfer-warehouses` (2 dropdowns lado a lado). Reusar `.inv-doc-*` para grilla de lineas.

- [ ] **49.10** Build: `npm run build` sin errores TypeScript. Verificar flujo completo:
  - Crear transferencia (borrador) â†’ sin movimiento de stock.
  - Editar en borrador â†’ guardar cambios.
  - Generar salida â†’ stock baja en origen, sube en transito.
  - Confirmar recepcion â†’ stock baja en transito, sube en destino.
  - Anular desde B (sin cambio), desde T (revertir), desde C (rechazado).
  - Validaciones: stock insuficiente, origen !== destino, permisos.

### Checkpoint de permisos

| Clave | Descripcion |
|---|---|
| `inventory.transfers.view` | Ver listado y detalle de transferencias |
| `inventory.transfers.edit` | Crear y editar transferencias en borrador |
| `inventory.transfers.void` | Anular transferencias (B y T) |
| `inventory.transfers.print` | Imprimir transferencias |
| `inventory.transfers.generate-exit` | Ejecutar "Generar Salida" |
| `inventory.transfers.confirm-reception` | Ejecutar "Confirmar Recepcion" |

### Objetos de base de datos afectados

| Objeto | Tipo | Accion |
|---|---|---|
| `Almacenes` | Tabla | ALTER â€” agregar columna `IdAlmacenTransito INT NULL FK` |
| `Almacenes` | Datos | INSERT almacen "Transito General" tipo T si no existe |
| `spAlmacenesCRUD` | SP | RECREAR â€” parametro `@IdAlmacenTransito`, validacion, retorno en L/O |
| `InvTransferencias` | Tabla | CREATE â€” tabla 1:1 con InvDocumentos |
| `spInvTransferenciasCRUD` | SP | CREATE â€” acciones I, U, GS, CR, N, O, L |
| `spInvDocumentosCRUD` | SP | MODIFICAR â€” guardia para rechazar TipoOp='T' |
| `Pantallas` + `RolPantallaPermisos` | Datos | INSERT â€” 6 claves de permiso para transferencias |

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `database/63_inv_transferencias.sql` | Script SQL nuevo (columna, almacen default, tabla, SP, guardia) |
| `database/64_inv_transferencias_permisos.sql` | Script SQL nuevo (permisos) |
| `src/lib/pos-data.ts` | Actualizar WarehouseRecord + 7 funciones + 3 tipos transferencia |
| `src/lib/permissions.ts` | 6 permission keys + route rule actualizada |
| `src/components/pos/org-warehouses-screen.tsx` | Campo transito en form de almacen |
| `src/app/api/inventory/transfers/route.ts` | Archivo nuevo (GET, POST) |
| `src/app/api/inventory/transfers/[id]/route.ts` | Archivo nuevo (GET, PUT, DELETE) |
| `src/app/api/inventory/transfers/[id]/generate-exit/route.ts` | Archivo nuevo (POST) |
| `src/app/api/inventory/transfers/[id]/confirm-reception/route.ts` | Archivo nuevo (POST) |
| `src/components/pos/inv-transfer-screen.tsx` | Componente nuevo |
| `src/app/inventory/transfers/page.tsx` | Reemplazar stub |
| `src/app/globals.css` | Clases .inv-transfer-* |

---

## TAREA 50 — Fix Permisos Transferencias: Alinear Fallbacks con inv-document-screen

**Estado:** `COMPLETADA` ✅

**Contexto:**
- En `inv-document-screen.tsx` (E/S/C), `canEdit` incluye `hasPermission("catalog.view")` como fallback, por lo que usuarios con ese permiso pueden ver botones y operar.
- En `inv-transfer-screen.tsx`, `canEdit` solo tiene `inventory.transfers.edit` y `catalog.edit` â€” falta `catalog.view` como fallback.
- Resultado: el boton "+ Nuevo Documento" y otros botones de accion no aparecen para usuarios que solo tienen `catalog.view`.

**Objetivo:** Alinear las variables de permisos de `inv-transfer-screen.tsx` con el patron de `inv-document-screen.tsx`, agregando `catalog.view` como fallback.

### Checkpoints

- [ ] **50.1** En `src/components/pos/inv-transfer-screen.tsx`, actualizar las variables de permisos:

  **Antes:**
  ```typescript
  const canEdit = hasLegacyFallback || hasPermission("inventory.transfers.edit") || hasPermission("catalog.edit")
  const canVoid = hasLegacyFallback || hasPermission("inventory.transfers.void") || hasPermission("catalog.delete")
  const canPrint = hasLegacyFallback || hasPermission("inventory.transfers.print") || hasPermission("inventory.transfers.view")
  const canGenerateExit = hasLegacyFallback || hasPermission("inventory.transfers.generate-exit") || hasPermission("inventory.transfers.edit")
  const canConfirmReception = hasLegacyFallback || hasPermission("inventory.transfers.confirm-reception") || hasPermission("inventory.transfers.edit")
  ```

  **Despues (agregar fallbacks como inv-document-screen):**
  ```typescript
  const canVisualize = hasLegacyFallback || hasPermission("inventory.transfers.view") || hasPermission("catalog.view")
  const canEdit = hasLegacyFallback || hasPermission("inventory.transfers.edit") || hasPermission("catalog.edit") || hasPermission("catalog.view")
  const canVoid = hasLegacyFallback || hasPermission("inventory.transfers.void") || hasPermission("inventory.transfers.edit") || hasPermission("catalog.delete") || hasPermission("catalog.edit") || hasPermission("catalog.view")
  const canPrint = hasLegacyFallback || hasPermission("inventory.transfers.print") || canVisualize
  const canGenerateExit = hasLegacyFallback || hasPermission("inventory.transfers.generate-exit") || hasPermission("inventory.transfers.edit") || hasPermission("catalog.view")
  const canConfirmReception = hasLegacyFallback || hasPermission("inventory.transfers.confirm-reception") || hasPermission("inventory.transfers.edit") || hasPermission("catalog.view")
  ```

- [ ] **50.2** Build: `npx tsc --noEmit` sin errores. Verificar que el boton "+ Nuevo Documento" aparece en la pantalla de Transferencias.

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/inv-transfer-screen.tsx` | Agregar `catalog.view` como fallback en variables de permisos |

---

## TAREA 51 â€” Alinear UI del Formulario de Transferencias con inv-document-screen

**Estado:** `HECHO`

**Contexto:**
- El formulario "Nueva Transferencia" (form view) y la vista de detalle de `inv-transfer-screen.tsx` usan clases y estructura diferente al formulario de Entradas/Salidas/Compras (`inv-document-screen.tsx`).
- Entradas usa: `inv-doc-detail-topbar` para botones Cancelar/Guardar fuera del panel, `inv-doc-detail-header` con `inv-doc-detail-header__row` (grid 4 columnas), `inv-doc-grid` con tabs "Detalle"/"Comentarios", tabla con clases `inv-doc-grid__table`, columna `#`, celda de codigo con boton buscar, `tfoot` con total.
- Transferencias usa: `price-lists-form` con `form-grid` (layout generico), `inv-doc-screen__table` sin columna `#` ni boton buscar, total con `div` inline style.

**Objetivo:** Reescribir la vista form y detail de `inv-transfer-screen.tsx` usando exactamente las mismas clases CSS y estructura HTML que `inv-document-screen.tsx`, adaptando solo los campos propios de transferencias (Origen, Destino, Estado).

### Checkpoints

- [x] **51.1** Vista Form â€” Topbar y layout general:

  Mover los botones Cancelar y Guardar a un `div.inv-doc-detail-topbar` **fuera** del `section.data-panel` (igual que inv-document-screen linea 1201-1222). Actualmente estan dentro del panel como `price-lists-form__header`.

  Estructura objetivo:
  ```
  <div class="inv-doc-detail-topbar">
    {chip si editando}
    <div class="inv-doc-detail-topbar__actions">
      <button> X Cancelar</button>
      <button> Guardar</button>
    </div>
  </div>
  <section class="data-panel">
    <div class="inv-doc-screen">
      <form>...</form>
    </div>
  </section>
  ```

- [x] **51.2** Vista Form â€” Header fields con `inv-doc-detail-header`:

  Reemplazar el `div.form-grid` actual por `div.inv-doc-detail-header` con filas `inv-doc-detail-header__row` (4 columnas por fila):

  **Fila 1:** Fecha * | Periodo (auto, disabled) | Documento (auto/editando, disabled) | Moneda (auto, disabled)
  **Fila 2:** Tipo Documento * | Almacen Origen * | Almacen Destino * | Referencia

  Notas:
  - Agregar campo `periodo` al form state (auto-calculado desde fecha: YYYYMM).
  - Documento: mostrar preview del numero auto-generado o el numero existente si editando.
  - Moneda: mostrar simbolo de moneda del tipo de documento seleccionado.
  - Observacion pasa a la tab "Comentarios / Observaciones" (no en el header).

- [x] **51.3** Vista Form â€” Grilla de detalle con `inv-doc-grid`:

  Reemplazar el bloque actual (`inv-doc-screen__list-card` + `inv-doc-screen__table`) por la estructura de `inv-doc-grid`:

  ```
  <div class="inv-doc-grid">
    <div class="inv-doc-grid__header">
      <div class="inv-doc-grid__tabs">
        <button class="filter-pill is-active">Detalle</button>
        <button class="filter-pill">Comentarios / Observaciones</button>
      </div>
      {tab === "detail" ? <button>+ Linea</button> : null}
    </div>
    {tab === "detail" ? <table class="inv-doc-grid__table">...</table> : <textarea>...</textarea>}
  </div>
  ```

  Tabla con clases `inv-doc-grid__table`:
  - Columnas: `#` | Codigo | Descripcion | Cantidad | Unidad | Costo | Total | (acciones)
  - Celda Codigo: `div.inv-doc-grid__code-cell` con input + boton buscar (`inv-doc-grid__search-btn`)
  - Total en `<tfoot>` con `Total Documento` (no un div suelto)
  - Fila activa: clase `is-active-row` + hint visual en inputs editables

- [x] **51.4** Vista Detail â€” Topbar con botones de accion:

  Mover los botones de accion (Imprimir, Editar, Generar Salida, Confirmar Recepcion, Anular, Cerrar) a un `div.inv-doc-detail-topbar` fuera del panel, con badge de estado. Reemplazar `price-lists-form__header`.

  Estructura:
  ```
  <div class="inv-doc-detail-topbar">
    <span class="inv-transfer-badge inv-transfer-badge--{estado}">{label}</span>
    <div class="inv-doc-detail-topbar__actions">
      {botones segun estado}
      <button> X Cerrar</button>
    </div>
  </div>
  ```

- [x] **51.5** Vista Detail â€” Header con `inv-doc-detail-header`:

  Reemplazar `form-grid` por `inv-doc-detail-header` con filas de 4 columnas:

  **Fila 1:** Fecha | Periodo | Documento | Moneda
  **Fila 2:** Tipo Documento | Almacen Origen | Almacen Destino | Referencia
  **Fila 3:** Transito | Estado (badge) | (vacio) | (vacio)

  Todos los campos disabled. Observacion visible como tab o campo extra debajo.

- [x] **51.6** Vista Detail â€” Tabla de lineas con `inv-doc-grid__table`:

  Usar mismas clases que el formulario: `inv-doc-grid__table` con columnas `#`, Codigo, Descripcion, Cantidad, Unidad, Costo, Total. `<tfoot>` con total del documento.

- [x] **51.7** Build: `npx tsc --noEmit` sin errores. Verificar visualmente que:
  - Formulario "Nueva Transferencia" se ve igual que "Nueva Entrada de Inventario" (misma estructura visual).
  - Vista detalle se ve igual que vista detalle de Entradas (topbar con botones, header con rows, tabla con tfoot).

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `src/components/pos/inv-transfer-screen.tsx` | Reescribir vistas form y detail con clases de inv-document-screen |

---

## TAREA 52 — Fix Reporte Existencias por Almacen: Conversion Unidades Alternas Invertida + Duplicados

**Estado:** `COMPLETADA` ✅

**Contexto:**
- En la pantalla de productos, tab "Existencia", el reporte "EXISTENCIAS POR ALMACEN" muestra columnas "Disponible C10", "Disponible C10".
- Con 4 unidades base disponibles, el reporte muestra "40" cajas en vez de "0" (4 unidades no alcanzan para una caja de 10).
- El SP `spProductoExistencias` calcula `DisponibleAlterna = FLOOR(disponible / (BaseA / BaseB))`. Si la conversion esta invertida (BaseA=1, BaseB=10 para "Caja de 10"), el calculo da `FLOOR(4 / 0.1) = 40` en vez de `FLOOR(4 / 10) = 0`.
- Ademas, si una unidad alternativa tiene el mismo IdUnidad que la unidad de venta u otra alterna, se muestra como columna duplicada.

**Objetivo:** Corregir dos bugs:
1. La formula de conversion en el SP para que el disponible en unidades alternas sea correcto.
2. En el frontend/mapper, ocultar columnas de unidades alternas duplicadas.

### Checkpoints

- [ ] **52.1** DB: Investigar la semantica de `BaseA` y `BaseB` en la tabla `UnidadesMedida`:

  Consultar datos reales:
  ```sql
  SELECT IdUnidadMedida, Nombre, Abreviatura, BaseA, BaseB
  FROM UnidadesMedida WHERE Abreviatura LIKE 'C%' OR Nombre LIKE '%caja%'
  ```
  Determinar si el bug esta en la formula del SP o en los datos de BaseA/BaseB.

  **Formula actual del SP (linea 147 de `44_tarea33_existencias_por_almacen.sql`):**
  ```sql
  FLOOR((disponible) / (CAST(ua1.BaseA AS DECIMAL(18,6)) / NULLIF(CAST(ua1.BaseB AS DECIMAL(18,6)), 0)))
  ```
  Esto equivale a `FLOOR(disponible * BaseB / BaseA)`.
  - Si "Caja de 10" tiene BaseA=10, BaseB=1 â†’ `FLOOR(4 * 1 / 10)` = 0 âœ“
  - Si "Caja de 10" tiene BaseA=1, BaseB=10 â†’ `FLOOR(4 * 10 / 1)` = 40 âœ— â† **este es el caso actual**

- [ ] **52.2** DB: Corregir la formula o los datos segun el resultado del 52.1:

  **Opcion A (corregir SP):** Si los datos tienen BaseA=1, BaseB=10 para "Caja de 10" (es decir, 1 caja = 10 unidades base), cambiar la formula a:
  ```sql
  FLOOR(disponible / (CAST(ua1.BaseB AS DECIMAL(18,6)) / NULLIF(CAST(ua1.BaseA AS DECIMAL(18,6)), 0)))
  ```
  Esto seria `FLOOR(disponible * BaseA / BaseB)` = `FLOOR(4 * 1 / 10)` = 0 âœ“

  **Opcion B (corregir datos):** Si la semantica correcta es BaseA=factor, cambiar los datos de las unidades para que BaseA=10, BaseB=1 para "Caja de 10".

  Crear script `database/65_fix_conversion_existencias.sql`.

- [ ] **52.3** TypeScript â€” Filtrar columnas de unidades alternas duplicadas:

  En `mapProductStockRow` de `src/lib/pos-data.ts`, el SP ya retorna `IdUnidadVenta`, `IdUnidadAlterna1`, `IdUnidadAlterna2`, `IdUnidadAlterna3`. Setear `alterna1/2/3 = null` si:
  - Su IdUnidad coincide con `IdUnidadVenta` (ya mostrada como columna "Disponible (UND)")
  - Su IdUnidad coincide con una alterna anterior ya incluida

  Para esto, actualizar el SP para que tambien retorne `p.IdUnidadMedida` (actualmente no lo retorna), o hacer la deduplicacion comparando los IDs de las alternas entre si y contra IdUnidadVenta.

- [ ] **52.4** Build: `npx tsc --noEmit` sin errores. Verificar que:
  - Con 4 unidades base y "Caja de 10", la columna muestra 0 (no 40).
  - Si la unidad alterna es la misma que la de venta, no aparece columna duplicada.
  - Los totales de la fila "Totales" son correctos.

### Objetos de base de datos afectados

| Objeto | Tipo | Accion |
|---|---|---|
| `spProductoExistencias` | SP | RECREAR â€” corregir formula de conversion |

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `database/65_fix_conversion_existencias.sql` | Script SQL nuevo |
| `src/lib/pos-data.ts` | `mapProductStockRow` â€” filtrar alternas duplicadas por IdUnidad |

---

## TAREA 53 — Auto-logout por Inactividad + Limpieza de Sesiones

**Estado:** `COMPLETADA` ✅

**Contexto:**
- Las sesiones tienen `FechaExpiracion` (8h hardcoded en `spAuthLogin`) pero no hay idle timeout.
- `FechaUltimaActividad` se escribe en login pero nunca se actualiza despues.
- No hay auto-logout en el frontend ni aviso al usuario antes de expirar.
- No hay configuracion por empresa para duracion de sesion.
- La tabla `SesionesActivas` acumula registros sin limpiarse nunca.
- Cookies duran 12h pero la DB expira en 8h (mismatch).

**Objetivo:** Implementar:
1. Idle timeout configurable por empresa (default 30 min).
2. Sesion absoluta configurable (default 10h).
3. Heartbeat que actualiza `FechaUltimaActividad` cada 5 min.
4. Auto-logout en frontend con aviso 2 min antes.
5. Limpieza automatica de sesiones cerradas (>30 dias) al cerrar una sesion.

**Valores default:**

| Tipo | Valor | Configurable en |
|------|-------|-----------------|
| Sesion absoluta | 600 min (10h) | `Empresa.SesionDuracionMinutos` |
| Inactividad (idle) | 30 min | `Empresa.SesionIdleMinutos` |
| Aviso pre-expiracion | 2 min antes del idle | Hardcoded |
| Heartbeat | cada 5 min | Hardcoded |
| Limpieza sesiones cerradas | >30 dias | Hardcoded |

### Checkpoints

- [ ] **53.1** DB: Crear `database/66_sesiones_idle_timeout.sql` con:

  **a) Campos de configuracion en `Empresa`:**
  ```sql
  IF COL_LENGTH('dbo.Empresa', 'SesionDuracionMinutos') IS NULL
    ALTER TABLE dbo.Empresa ADD SesionDuracionMinutos INT NOT NULL DEFAULT 600;
  IF COL_LENGTH('dbo.Empresa', 'SesionIdleMinutos') IS NULL
    ALTER TABLE dbo.Empresa ADD SesionIdleMinutos INT NOT NULL DEFAULT 30;
  ```

  **b) Actualizar `spAuthLogin`:** Leer `SesionDuracionMinutos` de `Empresa` (activo) en vez del hardcoded 480. Usar ese valor para `FechaExpiracion`. Retornar `SesionDuracionMinutos` y `SesionIdleMinutos` en el resultado para que el code pueda setear cookies y frontend.

  **c) Nuevo SP `spAuthHeartbeat`:**
  ```sql
  CREATE OR ALTER PROCEDURE dbo.spAuthHeartbeat
    @IdSesion BIGINT = NULL,
    @TokenSesion UNIQUEIDENTIFIER = NULL
  AS BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.SesionesActivas
    SET FechaUltimaActividad = SYSDATETIME()
    WHERE (IdSesion = @IdSesion OR TokenSesion = @TokenSesion)
      AND SesionActiva = 1;
  END
  ```

  **d) Actualizar `spAuthValidarSesion`:** Agregar validacion de idle:
  ```sql
  DECLARE @IdleMin INT;
  SELECT TOP 1 @IdleMin = ISNULL(SesionIdleMinutos, 30) FROM dbo.Empresa WHERE Activo = 1;
  -- Agregar al WHERE:
  AND (s.FechaUltimaActividad IS NULL
       OR DATEADD(MINUTE, @IdleMin, s.FechaUltimaActividad) >= SYSDATETIME())
  ```

  **e) Actualizar `spAuthCerrarSesion`:** Agregar limpieza al final:
  ```sql
  DELETE FROM dbo.SesionesActivas
  WHERE SesionActiva = 0
    AND FechaCierre IS NOT NULL
    AND FechaCierre < DATEADD(DAY, -30, SYSDATETIME());
  ```

  **f) Actualizar `spEmpresaCRUD`:** Agregar parametros `@SesionDuracionMinutos`, `@SesionIdleMinutos` en acciones I/A. Retornarlos en L/O.

- [ ] **53.2** TypeScript â€” Actualizar `src/lib/pos-data.ts`:

  **a) Nueva funcion `heartbeatSession(sessionId, token)`:** Llama `spAuthHeartbeat`. Retorna void.

  **b) Actualizar tipo de empresa** para incluir `sessionDurationMinutes: number` y `sessionIdleMinutes: number`.

- [ ] **53.3** TypeScript â€” Actualizar `src/lib/auth-session.ts`:

  Actualizar `loginSession` para leer la duracion de la DB (del resultado del SP) y retornarla. El cookie `maxAge` debe coincidir con `SesionDuracionMinutos * 60` (en segundos).

- [ ] **53.4** TypeScript â€” Crear `src/app/api/auth/heartbeat/route.ts`:

  ```typescript
  POST: validar sesion con cookies â†’ llamar heartbeatSession() â†’ retornar { ok: true }
  Si sesion invalida â†’ 401
  ```
  Endpoint ligero, sin payload.

- [ ] **53.5** TypeScript â€” Actualizar `src/app/api/auth/me/route.ts`:

  Retornar `sessionIdleMinutes` en la respuesta para que el frontend sepa cuanto tiempo esperar.

- [ ] **53.6** TypeScript â€” Actualizar `src/app/api/auth/login/route.ts`:

  Usar `SesionDuracionMinutos` del resultado del SP para setear `maxAge` de las cookies dinamicamente (en vez del hardcoded 43200).

- [ ] **53.7** TypeScript â€” Actualizar `src/components/pos/app-shell.tsx`:

  **a) Timer de inactividad:**
  - Escuchar eventos `mousemove`, `keydown`, `click`, `scroll` â†’ resetear `lastActivity`.
  - Timer que cada segundo compara `Date.now() - lastActivity`:
    - Si >= `(idleMinutes - 2) * 60 * 1000` â†’ mostrar banner de aviso.
    - Si >= `idleMinutes * 60 * 1000` â†’ ejecutar auto-logout.

  **b) Heartbeat:**
  - `setInterval` cada 5 minutos â†’ `POST /api/auth/heartbeat`.
  - Si retorna 401 â†’ auto-logout inmediato (sesion ya expirada en server).

  **c) Banner de aviso:**
  - Banner fijo arriba (tipo toast o barra) con countdown: "Su sesion expirara en X:XX por inactividad."
  - Si el usuario interactua â†’ cerrar banner, resetear timer.

  **d) Auto-logout:**
  - `POST /api/auth/logout`
  - `router.push("/login?reason=idle")`

- [ ] **53.8** TypeScript â€” Actualizar `src/app/login/page.tsx`:

  Leer query param `reason=idle`. Si presente, mostrar mensaje informativo: "Su sesion fue cerrada por inactividad. Inicie sesion nuevamente."

- [ ] **53.9** Build: `npm run build` sin errores. Verificar:
  - Login â†’ esperar idle timeout â†’ auto-logout + mensaje en login.
  - Login â†’ mover mouse antes del timeout â†’ timer se resetea.
  - Banner de aviso aparece 2 min antes del idle.
  - Heartbeat visible en Network tab cada 5 min.
  - Cerrar sesion â†’ sesiones cerradas de >30 dias eliminadas de la tabla.
  - Cambiar `SesionIdleMinutos` en Empresa â†’ nuevo login usa valor nuevo.

### Objetos de base de datos afectados

| Objeto | Tipo | Accion |
|---|---|---|
| `Empresa` | Tabla | ALTER â€” agregar `SesionDuracionMinutos`, `SesionIdleMinutos` |
| `spAuthLogin` | SP | RECREAR â€” leer duracion de Empresa, retornar config |
| `spAuthValidarSesion` | SP | RECREAR â€” agregar validacion idle timeout |
| `spAuthCerrarSesion` | SP | RECREAR â€” agregar limpieza de sesiones >30 dias |
| `spAuthHeartbeat` | SP | CREATE â€” actualizar FechaUltimaActividad |
| `spEmpresaCRUD` | SP | RECREAR â€” agregar parametros de sesion |

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `database/66_sesiones_idle_timeout.sql` | Script SQL nuevo |
| `src/lib/pos-data.ts` | `heartbeatSession()` + tipo empresa |
| `src/lib/auth-session.ts` | Cookie maxAge dinamico |
| `src/app/api/auth/heartbeat/route.ts` | Archivo nuevo |
| `src/app/api/auth/me/route.ts` | Retornar idleMinutes |
| `src/app/api/auth/login/route.ts` | Cookie maxAge dinamico |
| `src/components/pos/app-shell.tsx` | Idle timer + heartbeat + banner + auto-logout |
| `src/app/login/page.tsx` | Mensaje reason=idle |

---

## TAREA 54 — Consulta de Movimientos de Inventario (Listado de Documentos Activos con Conversion a Unidad Base)

**Estado:** `COMPLETADA` ✅

**Contexto:**
- La seccion "Consultas" de Inventario apunta a `/catalog` (placeholder). No existe una pantalla de consulta de movimientos.
- Se necesita un listado de todos los documentos de inventario activos (E, S, C, T) en una sola vista.
- Las cantidades en los documentos se guardan en la unidad de medida que selecciono el usuario al crear el documento. Para reportes, deben mostrarse convertidas a la **unidad base para reportes** del producto (`Productos.UnidadBaseExistencia`).
- La funcion `dbo.fnConvertirUnidad(@IdUnidadBase, @IdUnidadMedida, @Cantidad)` ya existe en `database/68_fix_conversion_unidades_documentos.sql` y usa `BaseB/BaseA` como factor de conversion.

**Objetivo:** Crear pantalla de consulta de movimientos que muestre documentos activos de todos los tipos con cantidades convertidas a la unidad base para reportes.

### Checkpoints

- [ ] **54.1** DB: Crear `database/67_sp_inv_consulta_movimientos.sql` con SP `spInvConsultaMovimientos`:

  **Parametros:** `@FechaDesde DATE`, `@FechaHasta DATE`, `@TipoOperacion CHAR(1) = NULL` (filtro opcional E/S/C/T), `@IdAlmacen INT = NULL`, `@IdProducto INT = NULL`, `@NumeroPagina INT = 1`, `@TamanoPagina INT = 20`.

  **Query principal:** JOIN `InvDocumentos` + `InvDocumentoDetalle` + `Productos` + `Almacenes` + `InvTiposDocumento` + `UnidadesMedida`.

  **Columnas retornadas:**
  - Del documento: NumeroDocumento, Fecha, TipoOperacion, NombreTipoDocumento, NombreAlmacen, Referencia, Estado
  - Del detalle: Codigo, Descripcion producto, Cantidad (original), NombreUnidad (original), IdUnidadMedida (del detalle)
  - **Convertido:** CantidadBase = `dbo.fnConvertirUnidad(p.IdUnidadMedida, det.IdUnidadMedida, det.Cantidad)` â€” convierte la cantidad a la unidad de medida base del producto. NombreUnidadBase, AbreviaturaUnidadBase.
  - Costo, Total

  **Filtros:** `d.Estado = 'A'` (solo activos), `d.RowStatus = 1`, `det.RowStatus = 1`.

  **Paginacion:** `OFFSET/FETCH` + `COUNT(*) OVER()` para total.

  **Orden:** Fecha DESC, IdDocumento DESC, NumeroLinea ASC.

- [ ] **54.2** TypeScript â€” Agregar en `src/lib/pos-data.ts`:

  **a) Tipo nuevo:**
  ```typescript
  export type InvMovimientoConsultaRecord = {
    idDocumento: number
    numeroDocumento: string
    fecha: string
    tipoOperacion: string
    nombreTipoDocumento: string
    nombreAlmacen: string
    referencia: string
    codigo: string
    descripcion: string
    cantidadOriginal: number
    unidadOriginal: string
    cantidadBase: number
    unidadBase: string
    abreviaturaUnidadBase: string
    costo: number
    total: number
  }

  export type InvMovimientoConsultaResult = {
    items: InvMovimientoConsultaRecord[]
    total: number
    page: number
    pageSize: number
  }
  ```

  **b) Funcion:** `listInvMovimientosConsulta(filters)` â†’ llama `spInvConsultaMovimientos`.

- [ ] **54.3** TypeScript â€” Crear `src/app/api/inventory/movements/route.ts`:

  `GET`: recibe query params (desde, hasta, tipo, almacen, producto, page, pageSize). Llama `listInvMovimientosConsulta`. Retorna `{ ok, data }`.

- [ ] **54.4** TypeScript â€” Crear `src/components/pos/inv-movements-query-screen.tsx`:

  Pantalla de consulta (solo lectura, no CRUD) con:

  **Filtros:** Tipo Operacion (select: Todos/Entradas/Salidas/Compras/Transferencias), Fecha Desde, Fecha Hasta, Almacen (select), Producto (busqueda texto). Botones Actualizar + Limpiar. Usar mismas clases `inv-doc-screen__filters-*`.

  **Tabla:** Columnas: Numero, Fecha, Tipo, Almacen, Codigo, Producto, Cant. Original, Unidad, **Cant. Base**, **Unidad Base**, Costo, Total.

  **Paginacion:** Mismo patron que inv-document-screen (Por pagina 10/20/50, navegacion).

  **Click en numero:** Navega al detalle del documento correspondiente (link a `/inventory/entries`, `/inventory/exits`, `/inventory/purchases` o `/inventory/transfers` segun tipo).

- [ ] **54.5** TypeScript â€” Actualizar `src/app/inventory/queries/page.tsx` (crear si no existe):

  Server component que renderiza `<InvMovementsQueryScreen>` con datos iniciales (almacenes, fecha actual).

- [ ] **54.6** TypeScript â€” Actualizar `src/lib/navigation.ts`:

  Cambiar el href de "Consultas de Inventario" de `/catalog` a `/inventory/queries`.

- [ ] **54.7** TypeScript â€” Actualizar `src/lib/permissions.ts`:

  Agregar permission key `inventory.queries.view`. Agregar route rule `{ pattern: "/inventory/queries", key: "inventory.queries.view" }`.

- [ ] **54.8** CSS + Build: Estilos reusan `.inv-doc-screen__*`. `npm run build` sin errores. Verificar:
  - Listado muestra documentos de todos los tipos (E, S, C, T) activos.
  - Cantidad Base esta correctamente convertida (ej: si se ingresaron 2 cajas de 10 en unidad "C10", la columna Cant. Base muestra 20 en unidad "UND").
  - Filtros por tipo, almacen, fecha funcionan.
  - Paginacion funciona.

### Objetos de base de datos afectados

| Objeto | Tipo | Accion |
|---|---|---|
| `spInvConsultaMovimientos` | SP | CREATE â€” consulta de documentos activos con conversion de unidades |

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `database/67_sp_inv_consulta_movimientos.sql` | Script SQL nuevo |
| `src/lib/pos-data.ts` | Tipo + funcion `listInvMovimientosConsulta` |
| `src/app/api/inventory/movements/route.ts` | Archivo nuevo (GET) |
| `src/components/pos/inv-movements-query-screen.tsx` | Componente nuevo |
| `src/app/inventory/queries/page.tsx` | Archivo nuevo (o modificar si existe) |
| `src/lib/navigation.ts` | Cambiar href de consultas inventario |
| `src/lib/permissions.ts` | Agregar `inventory.queries.view` |

## TAREA 55 â€” Acciones del Panel de Detalle de Orden: Dividir, Mover, Cobrar, Cancelar con Gate de Supervisor, Eliminar LÃ­nea

**Estado:** CERRADA

### Objetivo

Implementar las 5 acciones pendientes del panel de detalle de orden. **Todas las operaciones de DB deben pasar por SPs â€” sin SQL directo en TypeScript.**

1. **Cobrar** â†’ placeholder "PrÃ³ximamente" (no ejecuta cierre)
2. **Dividir orden** â†’ modal para separar Ã­tems en nueva orden en el mismo recurso
3. **Mover orden** â†’ modal para mover la orden a otro recurso/mesa
4. **Cancelar orden** â†’ gate de permisos: si no tiene `orders.cancel` â†’ prompt de credenciales supervisor
5. **Eliminar lÃ­nea de detalle** â†’ nuevo botÃ³n por Ã­tem + gate `orders.delete` â†’ mismo prompt supervisor

### SPs nuevos requeridos

| SP | Tipo | AcciÃ³n |
|---|---|---|
| `dbo.spAuthVerificarSupervisor` | Nuevo SP dedicado | Valida creds + verifica permiso del rol. No crea sesiÃ³n. |
| `dbo.spOrdenesDividir` | Nuevo SP dedicado | Crea nueva orden, mueve lÃ­neas seleccionadas (por CSV de IDs), recalcula totales en ambas Ã³rdenes |
| `dbo.spOrdenesCRUD @Accion='A'` | YA EXISTE | Ya actualiza `IdRecurso` (no requiere cambios) |

### Subtareas

- [x] **55.1** SQL â€” Crear script `database/90_orders_dividir_supervisor.sql`:
  - `DROP PROCEDURE IF EXISTS dbo.spOrdenesCerrar, dbo.spOrdenesAnular, dbo.spOrdenesReabrir` â€” eliminar 3 wrappers redundantes.
  - `CREATE OR ALTER PROCEDURE dbo.spAuthVerificarSupervisor (@NombreUsuario, @ClaveHash, @ClavePermiso)` â€” valida creds inline (lÃ³gica de spAuthLogin) + verifica permiso en RolPantallaPermisos. Retorna `@Autorizado BIT, @Mensaje`.
  - `CREATE OR ALTER PROCEDURE dbo.spOrdenesDividir (@IdOrden, @LineasIds VARCHAR(MAX) CSV, @UsuarioCreacion, @IdSesion, @TokenSesion)` â€” crea nueva orden en mismo recurso, copia lÃ­neas seleccionadas, desactiva originales (`RowStatus=0`), recalcula totales en ambas, registra `ORDEN_DIVIDIDA`. Retorna `IdOrdenNueva`.
  - INSERT `orders.delete` en `Pantallas` + asignar a roles Administrador + Supervisor en `RolPantallaPermisos`.
  - **Notas:** `spOrdenesCRUD @Accion='A'` ya actualiza `IdRecurso`. `spOrdenesCRUD` acciones 'C'(cerrar)/'X'(anular)/'R'(reabrir) se llamarÃ¡n directo desde pos-data.ts, no via wrappers.

- [x] **55.2** TypeScript â€” `src/lib/permissions.ts`: agregar `"orders.delete"` al union `PermissionKey`.

- [x] **55.3** TypeScript â€” `src/lib/pos-data.ts` â€” REFACTOR 3 funciones existentes:
  - `closeOrder(orderId, ...)` â€” cambiar de `.execute("dbo.spOrdenesCerrar")` a `.execute("dbo.spOrdenesCRUD")` con `Accion='C'`
  - `cancelOrder(orderId, ...)` â€” cambiar de `.execute("dbo.spOrdenesAnular")` a `.execute("dbo.spOrdenesCRUD")` con `Accion='X'`
  - `reopenOrder(orderId, ...)` â€” cambiar de `.execute("dbo.spOrdenesReabrir")` a `.execute("dbo.spOrdenesCRUD")` con `Accion='R'`

- [x] **55.4** TypeScript â€” `src/lib/pos-data.ts` â€” AGREGAR 3 funciones nuevas (patrÃ³n try/catch typed/untyped igual que `removeOrderLine`):
  - `verifySupervisorCredentials(username, passwordHash, requiredPermission)` â†’ llama `dbo.spAuthVerificarSupervisor`, retorna `{ authorized: boolean; message?: string }`
  - `moveOrderToResource(orderId, resourceId, userId?, session?)` â†’ llama `dbo.spOrdenesCRUD` con `Accion='A'` + `@IdRecurso`
  - `splitOrder(orderId, lineIds[], userId?, session?)` â†’ llama `dbo.spOrdenesDividir` con `@LineasIds` como CSV, retorna `{ newOrderId: number }`

- [x] **55.5** TypeScript â€” Crear `src/app/api/auth/supervisor-verify/route.ts` (POST):
  - `validateApiSession` â€” requiere sesiÃ³n activa del usuario actual
  - Body: `{ username, password, requiredPermission }`
  - Hashea password, llama `verifySupervisorCredentials`
  - Retorna `{ ok: boolean; message?: string }`

- [x] **55.5** TypeScript â€” `src/app/api/orders/[id]/move/route.ts` (POST, archivo nuevo):
  - `requireOrderPermission(session, "orders.edit")`
  - Body: `{ resourceId: number }`
  - Llama `moveOrderToResource(id, resourceId, ...)`

- [x] **55.6** TypeScript â€” `src/app/api/orders/[id]/split/route.ts` (POST, archivo nuevo):
  - `requireOrderPermission(session, "orders.edit")`
  - Body: `{ lineIds: number[] }`
  - Llama `splitOrder(id, lineIds, ...)`
  - Retorna `{ ok: true; newOrderId: number }`

- [x] **55.7** TypeScript â€” `src/app/api/orders/[id]/lines/route.ts`: agregar handler `DELETE { lineId: number }`:
  - `requireOrderPermission(session, "orders.delete", ["orders.edit"])`
  - Llama `removeOrderLine(lineId, ...)` (ya existe en pos-data.ts â†’ `spOrdenesDetalleCRUD 'D'`)

- [x] **55.8** TypeScript â€” `src/components/pos/orders-dashboard.tsx` â€” SupervisorVerifyModal + helper:
  - Estado: `supervisorModal: { permission: string; onSuccess: () => void } | null`
  - `requireSupervisor(permission, action)`: si `hasPermission(permission)` â†’ ejecutar directo; si no â†’ abrir modal
  - Modal: `modal-backdrop > modal-card modal-card--sm`, header `ShieldAlert`, inputs username + password, error inline
  - Al submit: POST `/api/auth/supervisor-verify` â†’ si ok â†’ `onSuccess()` + cerrar

- [x] **55.9** TypeScript â€” Cobrar â†’ Proximamente:
  - Reemplazar `closeTicket(selectedTicket)` por `showPendingAction("Cobrar â€” prÃ³ximamente disponible")`

- [x] **55.10** TypeScript â€” Modal Mover orden:
  - Estado: `moveOrderOpen: boolean`, `moveTargetResourceId: number | null`
  - BotÃ³n "Mover" abre modal; lista `data.resources` sin el recurso actual
  - Al confirmar: POST `/api/orders/{id}/move` con `{ resourceId }` â†’ `router.refresh()`

- [x] **55.11** TypeScript â€” Modal Dividir orden:
  - Estado: `splitOrderOpen: boolean`, `splitSelectedLines: Set<number>`
  - BotÃ³n "Dividir" abre modal; lista Ã­tems con checkboxes
  - Al confirmar: POST `/api/orders/{id}/split` con `{ lineIds }` â†’ `router.refresh()`

- [x] **55.12** TypeScript â€” Cancelar + Eliminar lÃ­nea con gate:
  - `cancelTicket(ticket)` â†’ `requireSupervisor("orders.cancel", () => setConfirmCancelTicket(ticket))`
  - BotÃ³n `Trash2 size={12}` en cada Ã­tem del detalle (ghost-button--xs)
  - `onClick` â†’ `requireSupervisor("orders.delete", () => deleteOrderLine(item.id))`
  - `deleteOrderLine(lineId)`: DELETE `/api/orders/{id}/lines` con `{ lineId }`
  - Importar `usePermissions` en el componente

- [x] **55.13** CSS â€” `src/app/globals.css`:
  - `.orders-detail-item__delete { opacity: 0; transition: opacity 0.15s; }`
  - `.orders-detail-item:hover .orders-detail-item__delete { opacity: 1; }`

- [x] **55.14** Build + VerificaciÃ³n:
  - `npm run build` sin errores TypeScript
  - Ejecutar `database/90_...sql` en DB
  - Mover: orden aparece en nueva mesa tras confirmar
  - Dividir: nueva orden creada con Ã­tems seleccionados, orden original sin ellos
  - Cobrar: muestra "prÃ³ximamente"
  - Cancelar sin permiso: gate supervisor â†’ creds â†’ confirmaciÃ³n â†’ anulada
  - Cancelar con permiso: directo a confirmaciÃ³n
  - Eliminar lÃ­nea: botÃ³n al hover â†’ gate â†’ lÃ­nea eliminada
  - DB: `SELECT * FROM Pantallas WHERE ClavePermiso = 'orders.delete'` retorna 1 fila

### Objetos de base de datos afectados

| Objeto | Tipo | AcciÃ³n |
|---|---|---|
| `dbo.spOrdenesCerrar` | SP | DROP â€” redundante, reemplazado por spOrdenesCRUD acciÃ³n 'C' |
| `dbo.spOrdenesAnular` | SP | DROP â€” redundante, reemplazado por spOrdenesCRUD acciÃ³n 'X' |
| `dbo.spOrdenesReabrir` | SP | DROP â€” redundante, reemplazado por spOrdenesCRUD acciÃ³n 'R' |
| `dbo.spAuthVerificarSupervisor` | SP | CREATE nuevo |
| `dbo.spOrdenesDividir` | SP | CREATE nuevo |
| `dbo.spOrdenesCRUD` | SP | SIN CAMBIOS â€” acciÃ³n 'A' ya actualiza `IdRecurso` |
| `Pantallas` | Tabla | INSERT `orders.delete` |
| `RolPantallaPermisos` | Tabla | INSERT asignaciÃ³n a roles Administrador + Supervisor |

### Archivos de cÃ³digo afectados

| Archivo | Cambio |
|---|---|
| `database/90_orders_dividir_supervisor.sql` | Script nuevo |
| `src/lib/permissions.ts` | Agregar `"orders.delete"` |
| `src/lib/pos-data.ts` | Refactor closeOrder/cancelOrder/reopenOrder + 3 funciones nuevas |
| `src/app/api/auth/supervisor-verify/route.ts` | Archivo nuevo (POST) |
| `src/app/api/orders/[id]/move/route.ts` | Archivo nuevo (POST) |
| `src/app/api/orders/[id]/split/route.ts` | Archivo nuevo (POST) |
| `src/app/api/orders/[id]/lines/route.ts` | Agregar handler DELETE |
| `src/components/pos/orders-dashboard.tsx` | SupervisorVerifyModal, modales Mover/Dividir, gates, botÃ³n eliminar |
| `src/app/globals.css` | Hover botÃ³n eliminar lÃ­nea |


## TAREA 56 - Division de Cuentas: Subcuentas Operativas + Pre-Factura + Enviar a Caja

**Estado:** CERRADA

### Objetivo

Implementar una division de cuentas robusta para restaurante/bar siguiendo arquitectura POS profesional: **la cocina trabaja con una orden madre; operacion divide o unifica subcuentas; caja recibe esas subcuentas en bandeja para hacer la factura final.**

Esta tarea **no incluye cobros ni registro de pagos dentro de Ordenes**. El foco es:

- dividir cuentas
- unificar cuentas
- recalcular totales
- generar pre-factura
- enviar subcuentas a caja

### Principios de diseno

- OrdenesDetalle nunca se duplica fisicamente. OrdenCuentaDetalle solo asigna cantidades de cada linea a una subcuenta
- `SUM(CantidadAsignada)` por `IdOrdenDetalle` nunca puede superar `OrdenesDetalle.Cantidad`
- Una subcuenta `Enviada a Caja` queda bloqueada para dividir, unificar o editar salvo permiso supervisor
- Si todas las subcuentas de una orden fueron enviadas a caja, la orden madre pasa a estado operativo tipo `CuentaSolicitada` o `EnCaja`, **no** a `Facturada`
- La facturacion final ocurre en Caja, no en Ordenes
- Redondeo: la diferencia de centavos va a la primera subcuenta al recalcular
- Toda operacion relevante registra auditoria: usuario, fecha/hora, accion, observacion

### Modos de division soportados

| Modo | Descripcion |
|---|---|
| `PERSONA` | Agrupa items por `OrdenesDetalle.NumeroPersona` |
| `EQUITATIVA` | Divide el total entre N subcuentas, ajustando centavos al primero |
| `ITEM` | Usuario asigna items o cantidades manualmente mediante payload |
| `UNIFICAR` | Fusiona una o varias subcuentas origen en una subcuenta destino |

### Diseno de SPs

Para simplificar mantenimiento y mantener consistencia, la tarea usara **menos SPs y mas reutilizacion**:

- `spOrdenCuentasCRUD`
  - crear cuenta manual
  - actualizar referencia/observacion
  - anular cuenta
  - reabrir cuenta si aplica
  - marcar `Enviada a Caja`
  - revertir envio si supervisor
- `spOrdenCuentaDetalleCRUD`
  - asignar linea
  - actualizar cantidad asignada
  - quitar linea
- `spOrdenCuentasDividir`
  - un solo SP para `PERSONA`, `EQUITATIVA`, `ITEM`, `UNIFICAR`
  - recibe `@ModoDivision` y `@PayloadJson` cuando aplique
- `spOrdenCuentasRecalcular`
  - recalcula subtotal, ITBIS, propina legal, total, diferencias de centavos
- `spOrdenCuentasPrefactura`
  - devuelve snapshot listo para preview / impresion / envio a caja
- `spOrdenCuentasRegistrarMovimiento`
  - auditoria de dividir, unificar, enviar a caja, revertir, anular, etc.

### Subtareas

- [x] **56.1** SQL - Crear script `database/94_orden_cuentas_prefactura.sql` con tablas nuevas:
  - `EstadosCuenta`
  - `OrdenCuentas`
  - `OrdenCuentaDetalle`
  - `OrdenCuentaMovimientos`
  - seed de estados y permisos:
    - `orders.split.view`
    - `orders.split.manage`
    - `orders.send-to-cash`
    - `orders.prefactura.view`

- [x] **56.2** SQL - En el mismo script crear/alterar SPs:
  - `spOrdenCuentasCRUD`
  - `spOrdenCuentaDetalleCRUD`
  - `spOrdenCuentasDividir`
  - `spOrdenCuentasRecalcular`
  - `spOrdenCuentasPrefactura`
  - `spOrdenCuentasRegistrarMovimiento`

- [x] **56.3** SQL - `spOrdenCuentasDividir` debe soportar un unico contrato:
  - `@IdOrden`
  - `@IdUsuario`
  - `@ModoDivision = 'PERSONA' | 'EQUITATIVA' | 'ITEM' | 'UNIFICAR'`
  - `@CantidadSubcuentas = NULL`
  - `@PayloadJson = NULL`
  - `@Observacion = NULL`

- [x] **56.4** SQL - Definir validaciones obligatorias:
  - no dividir una orden cancelada o facturada
  - no dividir una subcuenta ya enviada a caja
  - no unificar subcuentas si alguna esta enviada a caja
  - `SUM(CantidadAsignada) <= Cantidad`
  - recalculo obligatorio despues de cada cambio

- [x] **56.5** TypeScript - `src/lib/permissions.ts`:
  - agregar 4 claves nuevas:
    - `orders.split.view`
    - `orders.split.manage`
    - `orders.send-to-cash`
    - `orders.prefactura.view`

- [x] **56.6** TypeScript - `src/lib/pos-data.ts`:
  - tipos:
    - `OrdenCuenta`
    - `OrdenCuentaDetalleItem`
    - `OrdenCuentaMovimiento`
    - `OrdenCuentaPrefactura`
  - funciones:
    - `listOrdenCuentas`
    - `createOrdenCuenta`
    - `updateOrdenCuenta`
    - `cancelOrdenCuenta`
    - `assignLineToAccount`
    - `removeLineFromAccount`
    - `updateAssignedQuantity`
    - `splitAccounts`
    - `sendAccountToCash`
    - `revertAccountSentToCash`
    - `getOrdenCuentaPrefactura`
    - `listOrdenCuentaMovements`

- [x] **56.7** TypeScript - Rutas API nuevas:
  - `src/app/api/orders/[id]/accounts/route.ts` (`GET/POST`)
  - `src/app/api/orders/[id]/accounts/[accountId]/route.ts` (`PUT/DELETE`)
  - `src/app/api/orders/[id]/accounts/[accountId]/lines/route.ts` (`POST/PUT/DELETE`)
  - `src/app/api/orders/[id]/accounts/split/route.ts` (`POST`)
  - `src/app/api/orders/[id]/accounts/[accountId]/send-to-cash/route.ts` (`POST`)
  - `src/app/api/orders/[id]/accounts/[accountId]/prefactura/route.ts` (`GET`)

- [x] **56.8** TypeScript - Crear `src/components/pos/orders-split-panel.tsx`:
  - panel 2 columnas
  - izquierda = lineas de la orden con cantidad disponible / asignada
  - derecha = subcuentas con totales y estado
  - botones rapidos:
    - `Por persona`
    - `Equitativa`
    - `Nueva cuenta`
    - `Unificar`
    - `Pre-factura`
    - `Enviar a caja`

- [x] **56.9** TypeScript - `src/components/pos/orders-dashboard.tsx`:
  - boton `Dividir` abre `OrdersSplitPanel`
  - accion `Unificar` visible dentro del split panel
  - accion `Pre-factura` abre preview
  - accion `Enviar a caja` mueve la subcuenta a bandeja de caja

- [x] **56.10** CSS - `src/app/globals.css`:
  - estilos `.orders-split-panel`
  - `.orders-split-account`
  - `.orders-split-account--sent`
  - `.orders-split-unassigned`
  - `.orders-prefactura-preview`

- [x] **56.11** Negocio - Definir politica clara de bloqueo:
  - una subcuenta `Enviada a Caja` no admite cambios operativos normales
  - revertir envio requiere permiso supervisor
  - una orden no debe poder seguir dividiendose si todas sus subcuentas ya fueron enviadas

- [x] **56.12** UX - La pre-factura debe mostrar:
  - orden madre
  - mesa
  - subcuenta
  - cliente o referencia
  - lineas con cantidades asignadas
  - subtotal
  - ITBIS
  - propina legal
  - total
  - fecha/hora
  - usuario

- [x] **56.13** UX - La bandeja de caja debe recibir:
  - orden madre
  - subcuenta
  - mesa
  - referencia
  - total
  - fecha/hora de envio
  - usuario que envio
  - estado

- [x] **56.14** Build + Verificacion:
  - `npm run build` sin errores
  - orden 4 items 4 personas -> `PERSONA` -> 4 subcuentas
  - `EQUITATIVA 2` -> 2 subcuentas con totales correctos
  - `ITEM` -> asignacion parcial de cantidades
  - `UNIFICAR` -> fusion correcta de subcuentas
  - `Pre-factura` muestra lineas y totales correctos
  - `Enviar a caja` bloquea edicion operativa de la subcuenta
  - `SP` valida `SUM(CantidadAsignada) <= Cantidad`

### Objetos de base de datos afectados

| Objeto | Tipo | Accion |
|---|---|---|
| `dbo.EstadosCuenta` | Tabla | `CREATE` |
| `dbo.OrdenCuentas` | Tabla | `CREATE` |
| `dbo.OrdenCuentaDetalle` | Tabla | `CREATE` |
| `dbo.OrdenCuentaMovimientos` | Tabla | `CREATE` |
| `dbo.spOrdenCuentasCRUD` | SP | `CREATE/ALTER` |
| `dbo.spOrdenCuentaDetalleCRUD` | SP | `CREATE/ALTER` |
| `dbo.spOrdenCuentasDividir` | SP | `CREATE` |
| `dbo.spOrdenCuentasRecalcular` | SP | `CREATE` |
| `dbo.spOrdenCuentasPrefactura` | SP | `CREATE` |
| `dbo.spOrdenCuentasRegistrarMovimiento` | SP | `CREATE` |
| `Pantallas` | Tabla | `INSERT 4 claves` |
| `RolPantallaPermisos` | Tabla | `INSERT asignaciones` |

### Archivos de codigo afectados

| Archivo | Cambio |
|---|---|
| `database/94_orden_cuentas_prefactura.sql` | Script nuevo |
| `src/lib/permissions.ts` | 4 claves nuevas |
| `src/lib/pos-data.ts` | Tipos + funciones nuevas |
| `src/app/api/orders/[id]/accounts/` | Rutas nuevas |
| `src/components/pos/orders-split-panel.tsx` | Componente nuevo |
| `src/components/pos/orders-dashboard.tsx` | Integrar split panel |
| `src/app/globals.css` | Estilos split panel / prefactura |


## TAREA 57 - Homologar el modulo de Salon como mapa visual y homologar sus maestros

**Estado:** CERRADA

### Objetivo

Rehacer el alcance de `Salon` para dejarlo alineado con la realidad operativa del sistema:

- `Salon` debe funcionar como **mapa visual y resumen del negocio**
- `Salon` **no** debe operar ordenes ni mostrar detalle profundo de ordenes
- los **maestros y configuracion** de `Salon` siguen sin estar homologados y deben rehacerse con la UX moderna del sistema

### Resultado esperado

Al terminar esta tarea:

- `/dining-room` se comporta como un tablero visual del salon
- muestra estado resumido del negocio por recurso/mesa
- no crea ni edita ordenes desde esa pantalla
- no lista ordenes detalladas ni flujo transaccional
- `Recursos`, `Areas`, `Tipos de Recurso` y `Categorias de Recurso` quedan homologados con el resto del POS

### Hallazgos de la auditoria

1. `Salon` fue llevado a una direccion equivocada:
   - hoy intenta cargar ordenes por recurso
   - muestra tickets/ordenes en el panel derecho
   - incluso abre modal de nueva orden
   - eso **no** corresponde al alcance correcto del modulo

2. Los maestros/configuracion **no** estan homologados:
   - `DiningRoomConfigScreen` y `DiningRoomMastersManager` siguen apoyandose en `EntityCrudSection`
   - conservan look/flow generico legacy
   - no comparten de verdad la densidad, formularios ni jerarquia moderna del sistema

3. El copy y la estructura siguen mezclando lenguaje nuevo con residuos legacy.

### Subtareas

- [x] **57.1** Redefinir `Salon` como mapa visual:
  - eliminar captura de ordenes desde `Salon`
  - eliminar listado de ordenes por recurso
  - eliminar CTA de `Nueva orden` dentro del mapa
  - dejar solo informacion resumida del recurso seleccionado

- [x] **57.2** Homologar la vista principal `/dining-room`:
  - mantener layout limpio de 2 zonas:
    - izquierda = filtros + recursos/mesas
    - derecha = resumen visual del recurso seleccionado
  - usar lenguaje visual homologado con `Ordenes`
  - quitar tabs/stats/cards legacy innecesarias

- [x] **57.3** Recursos/mesas:
  - tiles compactos
  - estado
  - total actual
  - hora
  - usuario/camarero si aplica
  - indicador de multiples ordenes si existe
  - sin acciones transaccionales desde el tile

- [x] **57.4** Detalle resumido del recurso:
  - nombre del recurso
  - area/categoria
  - estado
  - total actual
  - cantidad de ordenes activas
  - cantidad de items
  - usuario/camarero
  - hora
  - referencia corta si existe
  - no mostrar lineas detalladas de productos
  - no mostrar acciones de dividir/mover/agregar/cancelar

- [x] **57.5** Homologar toolbar/filtros:
  - filtros compactos por area, estado y busqueda
  - copy en espanol
  - misma densidad visual del resto del sistema

- [x] **57.6** Homologar `DiningRoomManager`:
  - revisar CRUD de recursos
  - compactar formularios
  - mejorar jerarquia visual
  - quitar apariencia de pantalla generica heredada
  - usar botones y acciones consistentes con `Usuarios`, `Empresa`, `Ordenes`

- [x] **57.7** Homologar `DiningRoomConfigScreen`:
  - subnav compacta moderna
  - encabezado consistente
  - copy correcto en espanol
  - mejor estructura visual entre secciones

- [x] **57.8** Homologar `DiningRoomMastersManager`:
  - `Areas`
  - `Tipos de Recurso`
  - `Categorias de Recurso`
  - dejar formularios y listados con lenguaje visual del sistema
  - si `EntityCrudSection` no alcanza, ajustar o reemplazar la presentacion

- [x] **57.9** Auto-refresh silencioso en `Salon`:
  - refrescar estado de recursos/mesas
  - no cerrar paneles ni romper el flujo visual
  - sin comportamiento agresivo

- [x] **57.10** Copy e idioma:
  - todo en espanol
  - estados homogoneos
  - eliminar residuos tipo `Floor`, `Sections`, `Available`, etc.

- [x] **57.11** Build + Verificacion:
  - `npx tsc --noEmit`
  - `npm run build`
  - revisar `/dining-room`
  - revisar configuracion/maestros:
    - `/config/dining-room/resources`
    - `/config/dining-room/areas`
    - `/config/dining-room/resource-types`
    - `/config/dining-room/resource-categories`

### Estado actual

Ya quedaron implementados en esta tarea:

- `Salon` como mapa visual y resumen del negocio
- KPI en una sola franja superior
- filtros rapidos y busqueda compacta
- click en mesa/recurso con drawer resumen estilo sistema
- formatos monetarios homologados (`RD$ 5,858.70`)
- formas visuales de mesas controladas por categoria
- CRUD homologado para:
  - `Recursos`
  - `Areas`
  - `Tipos de Recurso`
  - `Categorias de Recurso`
- `Categorias de Recurso` con:
  - color picker homologado
  - forma visual configurable
  - generacion de recursos por SP
- fixes de fallback para errores legacy de parametros tipados:
  - `IdArea`
  - `IdCategoriaRecurso`
  - `IdRecurso`

### Cierre

- QA de `Salon` completado por usuario
- `npm run build` OK
- `npx tsc --noEmit` OK
- `TAREA 57` queda cerrada funcionalmente

### Criterios de aceptacion

1. `Salon` queda como pantalla de monitoreo visual, no operativa de ordenes
2. El panel derecho de `Salon` muestra solo resumen ejecutivo del recurso
3. No quedan modales o acciones para crear/operar ordenes dentro de `Salon`
4. Los maestros/configuracion quedan realmente homologados con el sistema
5. Todo el copy queda en espanol coherente
6. `npx tsc --noEmit` y `npm run build` pasan

### Archivos principales a tocar

| Archivo | Cambio esperado |
|---|---|
| `src/components/pos/dining-room-floor-view.tsx` | Rehacer la pantalla como mapa visual/resumen |
| `src/components/pos/dining-room-manager.tsx` | Homologar CRUD de recursos |
| `src/components/pos/dining-room-config-screen.tsx` | Homologar configuracion |
| `src/components/pos/dining-room-masters-manager.tsx` | Homologar maestros |
| `src/components/pos/entity-crud-section.tsx` | Evaluar ajuste visual o reemplazo parcial |
| `src/app/globals.css` | Estilos globales homologados de Salon |

---

## TAREA 58 - Facturacion / Caja: Punto de Ventas, Caja Central y flujo final de cobro

**Estado:** ABIERTA

### Objetivo

Construir el modulo de `Facturacion / Caja` como la estacion transaccional comercial del sistema, separando claramente:

- `Punto de Ventas`
- `Caja Central`
- `Cotizaciones`
- `Conduces`
- `Ordenes de Pedido`
- `Devoluciones de Mercancia`
- `Maestros` de facturacion

Esta tarea NO incluye el modulo fiscal profundo; eso queda en `Impuestos`.

### Alcance funcional confirmado

- distintas formas de pago
- multimoneda
- pagos mixtos
- bandeja de cuentas enviadas a caja
- bandeja de caja central
- pre-factura
- descuentos por linea y generales
- importacion de cotizaciones y ordenes de pedido
- cambio de cliente y comentarios por linea / generales
- cajas POS y cierres segun configuracion de sucursal
- venta rapida con panel derecho de categorias/items

### Resultado esperado

Al terminar esta tarea:

- existe el modulo `Facturacion` completo en navegacion
- `Punto de Ventas` funciona como estacion de captura y facturacion
- `Caja Central` funciona como bandeja de revision, pre-factura y cobro
- se soportan formas de pago simples, mixtas y multimoneda
- los maestros base de facturacion quedan listos
- el flujo queda separado de `Ordenes` y de `Impuestos`

### Subtareas

- [ ] **58.1** Auditoria del modulo `Facturacion`
  - revisar navegacion, rutas y scaffolds ya creados
  - confirmar entrypoints de:
    - `Punto de Ventas`
    - `Caja Central`
    - `Cotizaciones`
    - `Conduces`
    - `Ordenes de Pedido`
    - `Devoluciones de Mercancia`

- [x] **58.2** `Punto de Ventas` *(completado 2026-04-11)*
  - [x] layout base definitivo (encabezado, lineas, totales, panel derecho)
  - [x] descuentos por linea y descuento general proporcional
  - [x] descuento manual bidireccional (%, monto, precio final) con fix de rounding
  - [x] modal de seleccion de cliente con lista de precios, descuento y comprobante
  - [x] navigation guard al navegar con datos sin guardar
  - [ ] comentarios por linea / comentarios generales
  - [ ] cobrar (formas de pago)
  - [ ] guardar/emitir documento

- [ ] **58.3** `Caja Central`
  - bandeja/listado superior de documentos pendientes de cobro enviados desde `Facturacion`
  - columnas base:
    - documento
    - cliente
    - tipo comprobante
    - valor
    - fecha
    - hora
    - estatus
    - creado por
    - comentario
  - al hacer click en una fila:
    - mostrar detalle del documento en panel fijo a la derecha
    - mantener visible el listado principal
  - acciones prioritarias:
    - `Cobrar`
    - `Retornar`
    - `Anular`
    - shortcut a `Punto de Ventas`
  - `Cobrar` debe abrir selector/modal de formas de pago:
    - pago simple
    - pago mixto
    - multimoneda
    - vuelto
    - referencia/autorizacion si aplica
  - `Retornar` debe devolver la pre-factura/documento a `Facturacion`
    - dejar trazabilidad para ver devueltas o pendientes de correccion
  - `Anular` debe requerir motivo y dejar trazabilidad
  - `Visualizar` e `Imprimir` se mantienen
  - `Imprimir detallado` y `Excel` no son prioridad en esta fase
  - cierre del flujo sin mezclar la operacion de `Ordenes`

- [ ] **58.4** Formas de pago
  - CRUD real de `Formas de Pago`
  - soportar:
    - efectivo
    - tarjeta
    - transferencia
    - cheque si aplica
    - otras
  - base para pagos mixtos y multimoneda

- [ ] **58.5** `Cajas POS`
  - CRUD real
  - definir caja / terminal / sesion
  - relacion con sucursal / punto de emision
  - soporte para cierres segun configuracion

- [ ] **58.6** Tipos de documentos comerciales
  - `Tipos de Facturas`
  - `Tipos de Conduce`
  - `Tipos de Ordenes de Pedido`
  - permitir:
    - moneda
    - aplica 10% de propina legal
    - tipo de comprobante predeterminado
    - regla:
      - tomar del cliente primero
      - si no, tomar del tipo de documento

- [ ] **58.7** Cotizaciones y Ordenes de Pedido
  - flujo base y layout
  - importacion hacia `Punto de Ventas`
  - mantener trazabilidad

- [x] **58.8** Descuentos *(completado 2026-04-11)*
  - [x] CRUD descuentos con usuarios, limite manual y limite por usuario
  - [x] descuentos por usuario en POS (solo muestra los habilitados)
  - [x] descuento manual con limite proporcional
  - [x] descuento global afecta todas las lineas proporcionalmente
  - [x] totales muestran descuento en footer

- [ ] **58.9** Caja operativa
  - desembolso de caja
  - pre-base para arqueo y cierre
  - trazabilidad por sesion / caja / sucursal

- [ ] **58.10** Bandejas y consultas
  - detalle de ventas
  - resumen de ventas
  - estados base para facturacion

- [ ] **58.11** Build + QA
  - `npx tsc --noEmit`
  - `npm run build`
  - QA de:
    - `/facturacion/punto-de-ventas`
    - `/facturacion/caja-central`
    - `/config/facturacion/cajas-pos`
    - `/config/facturacion/formas-pago`
    - `/config/facturacion/tipos-facturas`

### Criterios de aceptacion

1. `Facturacion` queda navegable y coherente
2. `Punto de Ventas` y `Caja Central` estan claramente separados
3. Se soportan descuentos, comentarios y cliente en el POS
4. Existen formas de pago y base para pagos mixtos/multimoneda
5. Existen `Cajas POS` y configuracion ligada a sucursal / punto de emision
6. Tipos de documentos comerciales ya soportan reglas de moneda / 10% / comprobante por defecto
7. `npx tsc --noEmit` y `npm run build` pasan

### Archivos principales a tocar

| Archivo | Cambio esperado |
|---|---|
| `src/components/pos/billing-pos-screen.tsx` | Pantalla principal de Punto de Ventas |
| `src/app/facturacion/caja-central/page.tsx` | Pantalla principal de Caja Central |
| `src/components/pos/module-scaffold-screen.tsx` | Ir reemplazando scaffolds por pantallas reales |
| `src/lib/pos-data.ts` | Data layer del modulo |
| `src/app/api/facturacion/*` | APIs nuevas de facturacion / caja |
| `src/app/globals.css` | Estilos homologados del modulo |
| `database/*` | SPs / scripts nuevos para facturacion y caja |

---

## TAREA 60 - Impuestos: secuencias fiscales, operaciones especiales y reportes

**Estado:** EN PROGRESO (DB + Catálogo + Secuencias + Navegación completados)

### Objetivo

Construir el modulo `Impuestos` como modulo separado de `Facturacion`, responsable de:

- catálogo oficial NCF (tipos de comprobantes DGII)
- secuencias fiscales con modelo madre/hija
- operaciones especiales fiscales
- informes fiscales (606/607)
- registro de terceros (clientes/proveedores)

### Subtareas

- [x] **60.1** Estructura del módulo y navegación
  - Navegación final:
    - `Terceros` → Clientes (→ /config/cxc/customers), Proveedores (→ /config/cxp/suppliers)
    - `Operaciones` → Facturas Fiscales, Gastos Menores, Proveedores Informales, Pagos al Exterior, Actualización de Secuencias
    - `Consultas` → Informe Fiscal 606, Informe Fiscal 607
    - `Configuración` → Tipos de Comprobantes, Secuencias Fiscales

- [x] **60.2** DB: Schema completo (script 128 reescrito)
  - 4 tablas: `CatalogoNCF`, `SecuenciasNCF`, `HistorialDistribucionNCF`, `SecuenciasNCF_PuntosEmision`
  - 3 SPs: `spCatalogoNCFCRUD` (L/O/A), `spSecuenciasNCFCRUD` (L/O/I/A/D/DIST/FILL/SWAP/STATUS/LP/SP), `spHistorialDistribucionNCF` (L)
  - Seed: 17 tipos DGII oficiales (B01,B02,B11,B14-B17 físicos + E31-E47 electrónicos)
  - Scripts 129 (seed prueba) y 130 (seed madres 1-100 todos los tipos)
  - Script 131: acciones LP/SP para gestionar puntos de emisión compartidos

- [x] **60.3** `Tipos de Comprobantes` (CatalogoNCF)
  - Pantalla read-only del catálogo oficial DGII
  - Filtro Todos/Físicos/e-CF
  - Edición de nombre interno y activación por negocio
  - Badges de características (AplicaCredito, AplicaContado, RequiereRNC, etc.)

- [x] **60.4** `Secuencias Fiscales` (SecuenciasNCF)
  - CRUD completo con modelo madre (Distribución) / hija (Operación)
  - Tabla compacta dual En Uso / En Cola (prefijo, sec. inicial, sec. final, fecha vencimiento)
  - Parámetros: mínimo alertar, relleno automático, cantidad restante, secuencia actual
  - Distribución madre→hija con modal y registro en historial
  - Comprobante compartido: sección con checkboxes de puntos de emisión (SecuenciasNCF_PuntosEmision)
  - Madres no tienen punto de emisión; hijas sí (campo + compartir)

- [x] **60.5** Páginas scaffold de operaciones
  - Facturas Fiscales (`/impuestos/facturas-fiscales`) — scaffold
  - Gastos Menores (`/impuestos/gastos-menores`) — scaffold existente
  - Proveedores Informales (`/impuestos/proveedores-informales`) — scaffold existente
  - Pagos al Exterior (`/impuestos/pagos-exterior`) — scaffold existente
  - Actualización de Secuencias (`/impuestos/actualizacion-secuencias`) — scaffold existente

- [x] **60.6** Informes fiscales
  - Informe Fiscal 606 (`/impuestos/informe-606`) — scaffold
  - Informe Fiscal 607 (`/impuestos/informe-607`) — scaffold

- [ ] **60.7** Integración con Facturación
  - `Tipos de Facturas` pueden definir comprobante por defecto
  - Cliente puede definir comprobante por defecto
  - Regla: tomar del cliente primero, si no, del tipo de documento

- [x] **60.8** Build + QA parcial
  - `npm run build` pasa sin errores ✓
  - Pantallas Catálogo NCF y Secuencias NCF funcionales ✓
  - Permisos y pantallas registradas en DB para asignación a roles ✓

### Archivos creados/modificados

| Archivo | Acción |
|---|---|
| `database/128_impuestos_comprobantes_secuencias.sql` | Reescrito — schema completo |
| `database/129_seed_secuencias_prueba.sql` | Nuevo — seed de prueba |
| `database/130_seed_secuencias_todos_tipos.sql` | Nuevo — madres 1-100 para 17 tipos |
| `database/131_secuencias_puntos_emisión.sql` | Nuevo — acciones LP/SP en SP |
| `src/lib/pos-data.ts` | Modificado — tipos y funciones NCF |
| `src/lib/navigation.ts` | Modificado — menú Impuestos completo |
| `src/lib/permissions.ts` | Modificado — permisos nuevos |
| `src/components/pos/impuestos-catalogo-ncf-screen.tsx` | Nuevo |
| `src/components/pos/impuestos-secuencias-ncf-screen.tsx` | Nuevo |
| `src/app/config/impuestos/tipos-comprobantes/page.tsx` | Reescrito |
| `src/app/config/impuestos/secuencias-fiscales/page.tsx` | Reescrito |
| `src/app/api/config/impuestos/tipos-comprobantes/route.ts` | Reescrito |
| `src/app/api/config/impuestos/tipos-comprobantes/[id]/route.ts` | Reescrito |
| `src/app/api/config/impuestos/secuencias-fiscales/route.ts` | Reescrito |
| `src/app/api/config/impuestos/secuencias-fiscales/[id]/route.ts` | Reescrito |
| `src/app/api/config/impuestos/secuencias-fiscales/[id]/distribuir/route.ts` | Nuevo |
| `src/app/api/config/impuestos/secuencias-fiscales/[id]/puntos/route.ts` | Nuevo |
| `src/app/api/config/impuestos/secuencias-fiscales/historial/route.ts` | Nuevo |
| `src/app/impuestos/facturas-fiscales/page.tsx` | Nuevo — scaffold |
| `src/app/impuestos/informe-606/page.tsx` | Nuevo — scaffold |
| `src/app/impuestos/informe-607/page.tsx` | Nuevo — scaffold |

---

## TAREA 59 - Restaurar y homologar el modulo de Productos

**Estado:** `COMPLETADA` ✅ — QA confirmado por usuario 2026-04-07

### Objetivo

Recuperar el modulo grande de `Productos` que aun existe en el proyecto, devolverle sus opciones y consultas reales, y homologarlo al lenguaje visual y de interaccion del resto del sistema.

### Contexto confirmado

La pantalla grande de `Productos` sigue existiendo en:

- `src/components/pos/catalog-products-screen.tsx`

Y ya incluye una base funcional importante:

- busqueda real
- detalle por producto
- precios por lista
- costos
- oferta
- parametros
- asignacion de almacenes
- existencia por almacen
- movimientos / kardex

El problema actual no es ausencia total del modulo, sino:

- partes a medio restaurar
- encoding roto en varios labels
- UX no completamente homologada
- necesidad de QA real tab por tab

### Subtareas

- [ ] **59.1** Auditoria tecnica de `Productos`
  - revisar `catalog-products-screen.tsx`
  - revisar APIs asociadas:
    - `/api/catalog/products`
    - `/api/catalog/products/search`
    - `/api/catalog/products/[id]`
    - `/api/catalog/products/[id]/stock`
    - `/api/catalog/products/[id]/warehouses`
    - `/api/inventory/movements`
  - confirmar que todo endpoint requerido responda sin error

- [ ] **59.2** Limpieza de encoding / copy
  - corregir `Ã`, `Â`, `â€”` y textos rotos
  - dejar labels consistentes en espanol:
    - `Precios y Costos`
    - `Parametros`
    - `Almacenes`
    - `Existencia`
    - `Movimientos`

- [ ] **59.3** Homologacion visual
  - alinear la pantalla a los CRUD/paneles modernos del sistema
  - revisar:
    - sidebar
    - cards/listado
    - tabs
    - action bar
    - botones y modales

- [ ] **59.4** Restaurar flujo de `Precios y Costos`
  - listas de precios
  - costos de ultima compra
  - costo promedio
  - oferta
  - impuestos / precio con impuesto

- [ ] **59.5** Restaurar `Parametros`
  - opciones de POS/facturacion:
    - vender en facturacion
    - permitir descuento
    - cambio de precio
    - precio manual
    - pedir unidad
    - vender sin stock
    - aplicar propina
    - maneja existencia

- [ ] **59.6** Restaurar `Almacenes`
  - asignar/quitar almacenes
  - validar lista de asignados y disponibles
  - corregir cualquier flujo roto de seleccion multiple

- [ ] **59.7** Restaurar `Existencia`
  - existencia por almacen
  - min / max / reorden
  - conversion por unidades alternas
  - totales

- [ ] **59.8** Restaurar `Movimientos`
  - filtros por almacen
  - desde / hasta
  - carga del kardex real
  - costos unitarios y totales

- [ ] **59.9** Guard y modales del sistema
  - aplicar `Cambios sin guardar`
  - modales de eliminar/duplicar consistentes
  - evitar `confirm()` nativo

- [ ] **59.10** Build y QA
  - `npx tsc --noEmit`
  - `npm run build`
  - QA real de:
    - crear producto
    - editar producto
    - duplicar
    - eliminar
    - precios
    - almacenes
    - existencia
    - movimientos

### Criterios de aceptacion

1. `Productos` vuelve a funcionar como modulo completo, no solo CRUD simple
2. Las tabs `Precios y Costos`, `Parametros`, `Almacenes`, `Existencia`, `Movimientos` funcionan
3. No quedan textos rotos ni encoding dañado
4. La UX queda homologada con el sistema actual
5. Los modales y guards siguen el patron del sistema
6. `npx tsc --noEmit` y `npm run build` pasan

### Archivos principales a tocar

| Archivo | Cambio esperado |
|---|---|
| `src/components/pos/catalog-products-screen.tsx` | Restauracion principal del modulo |
| `src/app/config/catalog/products/page.tsx` | Mantener entrypoint limpio |
| `src/app/api/catalog/products/route.ts` | Validar create/update/delete |
| `src/app/api/catalog/products/[id]/route.ts` | Validar detalle |
| `src/app/api/catalog/products/[id]/stock/route.ts` | Validar existencia |
| `src/app/api/catalog/products/[id]/warehouses/route.ts` | Validar asignacion de almacenes |
| `src/app/api/inventory/movements/route.ts` | Validar movimientos / kardex |
| `src/lib/pos-data.ts` | Ajustes de data layer y compatibilidad |
| `src/app/globals.css` | Homologacion visual del modulo |

---

## TAREA 61 — Transferencias de Inventario: Arquitectura + Validaciones

**Estado:** `COMPLETADA`

**Contexto:**
- Las transferencias entre almacenes NO deben usar tabla `InvDocumentos` (son operaciones internas, no documentos contables)
- Require tabla de control `InvTransferencias` + líneas en `InvTransferenciasDetalle` + movimientos directos en `InvMovimientos`
- Flujo de 3 pasos: Crear (Borrador B) → Generar Salida (En Tránsito T) → Confirmar Recepción (Completada C)
- Validaciones críticas: no editar después de generar salida, no editar movimientos de transferencia (triggers), no anular completadas

**Scripts creados:**
- `database/123_transferencias_sin_documentos.sql` — tablas + SPs generarSalida/confirmarRecepción
- `database/124_validaciones_transferencias.sql` — triggers + SP anular + vista de saldo
- `TRANSFER_FLOW.md` — documentación completa de flujo y restricciones

### Checkpoints

- [x] **61.1** DB: Script 123 — Crear tabla `InvTransferenciasDetalle`, SP `spInvTransferenciasGenerarSalida`, SP `spInvTransferenciasConfirmarRecepcion`, SP `spInvTransferenciasActualizar`
      - Validar: BD scripts ejecutan sin error
      - SPs manejan estados correctamente (B→T→C)
      - Movimientos se generan en InvMovimientos con TipoDocOrigen='TRF'

- [x] **61.2** DB: Script 124 — Triggers de inmutabilidad (no editar/eliminar movimientos TRF), SP `spInvTransferenciasAnular`, vista `vw_InvTransferenciasSaldo`
      - Validar: Triggers previenen edición de movimientos de transferencia
      - SP Anular revierte stock en estado T
      - No permite anular en estado C

- [x] **61.3** Documentación: `TRANSFER_FLOW.md` con flujo completo, diagrama de estados, restricciones, SPs y movimientos
      - Actualizar `SESSION_HISTORY.md` y `OPENCODE_TASKS.md` con resumen

- [x] **61.4** API: Crear endpoint `POST /api/inventory/transfers/[id]/generate-exit` que llame `spInvTransferenciasGenerarSalida`
      - Capturar THROW de SP y retornar como JSON error
      - Respuesta exitosa retorna transferencia actualizada

- [x] **61.5** API: Crear endpoint `POST /api/inventory/transfers/[id]/confirm-receipt` que llame `spInvTransferenciasConfirmarRecepcion`
      - Capturar THROW de SP y retornar como JSON error
      - Respuesta exitosa retorna transferencia actualizada

- [x] **61.6** API: Crear endpoint DELETE `/api/inventory/transfers/[id]` llama `anularTransferencia`
      - Capturar THROW de SP y retornar como JSON error
      - Valida que solo permite en estados B/T (el SP lo valida)

- [x] **61.7** Frontend: Errores SQL THROW se capturan en API y retornan como JSON { message }
      - Cliente muestra via toast.error() con el mensaje del servidor
      - Errores 50047-50052 se propagan correctamente

- [x] **61.8** Frontend: Validaciones de UI por estado implementadas
      - Generar Salida: solo si estado='B'
      - Confirmar Recepción: solo si estado='T'
      - Anular: solo si estado='B' o 'T'
      - Editar: solo si estado='B'

- [x] **61.9** Frontend: Pantalla de transferencias con listado, filtros y acciones implementada
      - Lista con filtros: almacén origen/destino, estado, fechas, secuencia
      - Acciones: Generar Salida, Confirmar Recepción, Anular por estado
      - Estado visual: badges por color (Borrador/Tránsito/Completada/Anulada)

- [x] **61.10** QA: Build + Flujo completo
      - Build: `npm run build` sin errores ✓ (2026-04-07)
      - Validaciones UI por estado: implementadas en frontend ✓
      - Nota: flujo end-to-end en BD requiere ejecutar scripts 123 y 124 en prod

### Criterios de aceptacion

1. Transferencias NO crean registros en InvDocumentos
2. SPs y triggers ejecutan correctamente en BD
3. Errores THROW se capturan en API y muestran en app como toast
4. Estados B/T/C se respetan (no se puede editar/anular en estado T/C)
5. Movimientos son inmutables (triggers)
6. Kardex muestra transferencias con TipoDocOrigen='TRF'
7. Build limpio, sin errores TS

### Archivos involucrados

| Archivo | Estado |
|---|---|
| `database/123_transferencias_sin_documentos.sql` | ✓ Creado |
| `database/124_validaciones_transferencias.sql` | ✓ Creado |
| `TRANSFER_FLOW.md` | ✓ Creado |
| `src/app/api/inventory/transfers/[id]/generate-exit/route.ts` | ⏳ Pendiente |
| `src/app/api/inventory/transfers/[id]/confirm-receipt/route.ts` | ⏳ Pendiente |
| `src/app/api/inventory/transfers/[id]/cancel/route.ts` | ⏳ Pendiente |
| `src/components/pos/inventory-transfers-screen.tsx` (o módulo correspondiente) | ⏳ Pendiente |
| `src/lib/pos-data.ts` | ⏳ Actualizar con SPs de transferencias |

---

## TAREA 62 — Restauración BD: Módulo Órdenes y Salón

**Estado:** `COMPLETADA` ✅ — 2026-04-07

**Contexto:**
- La BD `DbMasuPOS` fue restaurada desde cero. Las tablas base de Órdenes y Salón venían de V1 y no tenían scripts de creación en V2.

**Scripts creados y ejecutados:**
- `database/126_orders_salon_base_tables.sql` — 7 tablas: Areas, TiposRecurso, CategoriasRecurso, Recursos, EstadosOrden, Ordenes, OrdenesDetalle + seed mínimo
- `database/127_salon_sps_crud.sql` — SPs CRUD: spAreasCRUD, spTiposRecursoCRUD, spCategoriasRecursoCRUD, spRecursosCRUD (con ColorTema/Area/Categoria en SELECT)
- Scripts 81–100 re-ejecutados para SPs y columnas adicionales

**Fixes adicionales:**
- `spOrdenesDashboard` actualizado para incluir `ColorTema` y `CantidadPersonas`
- `spRecursosCRUD` acción 'L' ahora devuelve `Area`, `Categoria`, `ColorTema`, `FormaVisual`
- `pos-data.ts` — mapeo de `area`, `category`, `categoryColor` desde SP en `getOrdersTrayData()`
- `ResourceOrderTray` type — agregado campo `categoryColor`
- `orders-dashboard.tsx` — cards de recursos muestran color de categoría via CSS var `--cat-color`
- Dropdown "Nueva Orden" muestra `Nombre — Area / Categoria`

**QA:** Módulo de Órdenes confirmado funcional por usuario.
