# MASU POS V2 - QA Matrix Seguridad E2E

Fecha: 2026-03-20  
Alcance: Usuarios, Roles, Permisos y flujo de autenticacion.

## 1) CRUD Usuarios

| Precondicion | Pasos | Resultado esperado | Pass/Fail |
|---|---|---|---|
| Sesion admin activa. Pantalla `Config > Security > Users` accesible. | 1) Click `Nuevo Usuario`. 2) Completar nombres, apellidos, usuario unico, rol, clave valida. 3) Guardar. | Usuario creado en tabla. Mensaje de exito. Registro visible tras refresco. | [ ] |
| Sesion admin activa. | 1) Click `Nuevo Usuario`. 2) Dejar vacios campos obligatorios. 3) Guardar. | Se bloquea guardado y se muestra validacion de campos requeridos. | [ ] |
| Existe usuario `juan.demo`. | 1) Crear nuevo usuario con `NombreUsuario = juan.demo`. 2) Guardar. | Error de duplicado desde SP/API. No se crea registro duplicado. | [ ] |
| Existe usuario activo. | 1) Abrir `Editar`. 2) Modificar correo y rol. 3) Guardar. | Cambios persistidos en DB. Reflejados en tabla y reapertura del modal. | [ ] |
| Existe usuario activo con tab Seguridad. | 1) Abrir usuario. 2) Ir a tab `Seguridad`. 3) Definir nueva contrasena + confirmacion. 4) Guardar. | Clave actualizada (hash). No se expone valor de clave en UI. | [ ] |
| Existe usuario activo. | 1) En tab `Seguridad`, activar `Pedir nueva contrasena al iniciar login`. 2) Guardar. 3) Cerrar sesion y loguear con ese usuario. | Login obliga a flujo de cambio de clave antes de entrar al sistema. | [ ] |
| Existe usuario activo. | 1) En menu acciones usar `Bloquear Cuenta`. 2) Intentar login con ese usuario. | Usuario queda inactivo. Login rechazado por SP de autenticacion. | [ ] |
| Existe usuario activo. | 1) En menu acciones usar `Eliminar`. 2) Buscar usuario en tabla. | Soft delete aplicado (`RowStatus = 0`). No aparece en listado activo. | [ ] |

## 2) CRUD Roles

| Precondicion | Pasos | Resultado esperado | Pass/Fail |
|---|---|---|---|
| Sesion admin activa. Pantalla Roles accesible. | 1) Click `Nuevo Rol`. 2) Nombre valido unico. 3) Guardar. | Rol creado y visible en listado. | [ ] |
| Sesion admin activa. | 1) Crear rol con nombre vacio/espacios. 2) Guardar. | Validacion bloquea guardado y muestra error. | [ ] |
| Existe rol `Supervisor`. | 1) Intentar crear otro rol `Supervisor`. | Se rechaza por duplicidad (SP/API). | [ ] |
| Existe rol editable sin dependencias criticas. | 1) Editar descripcion y estado. 2) Guardar. | Cambios persistidos correctamente. | [ ] |
| Existe rol con usuarios asignados. | 1) Intentar eliminar rol. | SP debe rechazar la eliminacion con mensaje controlado. | [ ] |
| Existe rol sin usuarios asignados. | 1) Eliminar rol. | Eliminacion (o soft delete) exitosa segun regla de negocio. | [ ] |

## 3) Permisos por Rol

| Precondicion | Pasos | Resultado esperado | Pass/Fail |
|---|---|---|---|
| Rol de prueba creado. Usuario asociado al rol. | 1) Asignar permiso de vista a `Usuarios`. 2) Login con usuario de prueba. | Menu muestra `Config > Security > Users` y ruta abre correctamente. | [ ] |
| Rol de prueba con permiso previo. | 1) Retirar permiso de vista de `Usuarios`. 2) Login nuevamente con usuario de prueba. | Item desaparece del menu. Ruta devuelve `403` o bloqueo equivalente. | [ ] |
| Rol de prueba con permisos parciales. | 1) Asignar permisos adicionales en pantallas de Catalogo. 2) Refrescar sesion/login. | Menu y acceso de rutas se ajustan al nuevo set de permisos. | [ ] |
| Rol sin permisos definidos. | 1) Login con usuario de ese rol. 2) Intentar navegar a rutas protegidas. | Fallback deny: no acceso a rutas protegidas ni items de menu correspondientes. | [ ] |

## 4) Flujo Auth

| Precondicion | Pasos | Resultado esperado | Pass/Fail |
|---|---|---|---|
| Credenciales validas de usuario activo. | 1) Login con usuario y clave correctos. | Sesion creada en `SesionesActivas`, cookies validas emitidas y redireccion al inicio configurado. | [ ] |
| Usuario con flag `RequiereCambioClave = 1`. | 1) Login valido. | Se muestra modal forzado de cambio de contrasena. No entra al dashboard hasta guardar nueva clave. | [ ] |
| Credenciales invalidas. | 1) Login con clave incorrecta. | Error inline en login. No toast de error. No crea sesion. | [ ] |
| Sesion expirada o cookies invalidas. | 1) Acceder a ruta protegida con sesion vencida. | Redireccion a `/login` (UI) o `401` en APIs protegidas. | [ ] |
| Sesion activa. | 1) Ejecutar logout desde menu. 2) Reintentar ruta protegida. | Cierra sesion en DB/cookies. Nuevo acceso requiere login. | [ ] |

## Evidencia recomendada por caso

- Captura de UI (antes/despues).
- Request/response de API (status y mensaje).
- Query de verificacion en DB (cuando aplique).
- Resultado marcado en columna `Pass/Fail`.
