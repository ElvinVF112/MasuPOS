-- ============================================================
-- SCRIPT: 000_nucleo_base.sql
-- PROPÓSITO: Crear las 7 tablas base del sistema Masu POS V2
--
-- TABLAS CREADAS (en orden de dependencias):
-- 1. Modulos
-- 2. Roles
-- 3. Pantallas (depende de Modulos)
-- 4. Usuarios (depende de Roles + Pantallas)
-- 5. Permisos (depende de Pantallas + Usuarios)
-- 6. UsuariosRoles (depende de Usuarios + Roles)
-- 7. RolesPermisos (depende de Roles + Permisos + Usuarios)
--
-- SEED INICIAL:
-- - Rol: Administrador
-- - Usuario: admin / 123456 (SHA-256)
-- - Módulo: Configuración
-- - Pantallas: Empresa, Usuarios, Roles
-- - Rol SIN ROL (IdRol=0)
--
-- NOTA: Los SPs de CRUD para estas tablas vienen en scripts posteriores
--       (03_usuarios_un_rol.sql, etc.)
-- ============================================================

USE DbMasuPOS;
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ============================================================
-- TABLA 1: MODULOS
-- ============================================================
IF OBJECT_ID('dbo.Modulos', 'U') IS NOT NULL
    DROP TABLE dbo.Modulos;
GO

CREATE TABLE dbo.Modulos (
    IdModulo            INT             IDENTITY(1,1)   NOT NULL,
    Nombre              VARCHAR(200)                    NOT NULL,
    Icono               VARCHAR(200)                    NULL,
    Orden               INT                             NOT NULL    CONSTRAINT DF_Modulos_Orden         DEFAULT (0),
    Activo              BIT                             NOT NULL    CONSTRAINT DF_Modulos_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_Modulos_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_Modulos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_Modulos               PRIMARY KEY (IdModulo)
);

CREATE INDEX IX_Modulos_Activo ON dbo.Modulos (Activo, RowStatus);
GO

-- ============================================================
-- TABLA 2: ROLES
-- ============================================================
IF OBJECT_ID('dbo.Roles', 'U') IS NOT NULL
    DROP TABLE dbo.Roles;
GO

CREATE TABLE dbo.Roles (
    IdRol               INT             IDENTITY(1,1)   NOT NULL,
    Nombre              VARCHAR(200)                    NOT NULL,
    Descripcion         VARCHAR(500)                    NULL,
    Activo              BIT                             NOT NULL    CONSTRAINT DF_Roles_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_Roles_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_Roles_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_Roles                 PRIMARY KEY (IdRol)
);

CREATE INDEX IX_Roles_Activo ON dbo.Roles (Activo, RowStatus);
GO

-- ============================================================
-- TABLA 3: PANTALLAS (depende de Modulos)
-- ============================================================
IF OBJECT_ID('dbo.Pantallas', 'U') IS NOT NULL
    DROP TABLE dbo.Pantallas;
GO

CREATE TABLE dbo.Pantallas (
    IdPantalla          INT             IDENTITY(1,1)   NOT NULL,
    IdModulo            INT                             NOT NULL,
    Nombre              VARCHAR(200)                    NOT NULL,
    Ruta                VARCHAR(400)                    NULL,
    Controlador         VARCHAR(200)                    NULL,
    AccionVista         VARCHAR(200)                    NULL,
    Icono               VARCHAR(200)                    NULL,
    Orden               INT                             NOT NULL    CONSTRAINT DF_Pantallas_Orden         DEFAULT (0),
    Activo              BIT                             NOT NULL    CONSTRAINT DF_Pantallas_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_Pantallas_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_Pantallas_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_Pantallas             PRIMARY KEY (IdPantalla),
    CONSTRAINT FK_Pantallas_Modulos     FOREIGN KEY (IdModulo)            REFERENCES dbo.Modulos  (IdModulo)
);

CREATE INDEX IX_Pantallas_IdModulo ON dbo.Pantallas (IdModulo, Activo, RowStatus);
CREATE INDEX IX_Pantallas_Ruta ON dbo.Pantallas (Ruta);
GO

-- ============================================================
-- TABLA 4: USUARIOS (depende de Roles + Pantallas + self-ref)
-- ============================================================
IF OBJECT_ID('dbo.Usuarios', 'U') IS NOT NULL
    DROP TABLE dbo.Usuarios;
GO

CREATE TABLE dbo.Usuarios (
    IdUsuario           INT             IDENTITY(1,1)   NOT NULL,
    IdRol               INT                             NOT NULL,
    TipoUsuario         CHAR(1)                         NOT NULL    CONSTRAINT DF_Usuarios_TipoUsuario  DEFAULT ('O'),
    IdPantallaInicio    INT                             NULL,
    Nombres             NVARCHAR(150)                   NOT NULL,
    Apellidos           NVARCHAR(150)                   NOT NULL,
    NombreUsuario       NVARCHAR(100)                   NOT NULL,
    Correo              NVARCHAR(150)                   NULL,
    ClaveHash           NVARCHAR(500)                   NOT NULL,
    RequiereCambioClave BIT                             NOT NULL    CONSTRAINT DF_Usuarios_RequiereCambioClave DEFAULT (0),
    Bloqueado           BIT                             NOT NULL    CONSTRAINT DF_Usuarios_Bloqueado           DEFAULT (0),
    Activo              BIT                             NOT NULL    CONSTRAINT DF_Usuarios_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_Usuarios_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_Usuarios_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_Usuarios              PRIMARY KEY (IdUsuario),
    CONSTRAINT FK_Usuarios_Roles_IdRol  FOREIGN KEY (IdRol)               REFERENCES dbo.Roles    (IdRol),
    CONSTRAINT FK_Usuarios_Pantallas_IdPantallaInicio
                                        FOREIGN KEY (IdPantallaInicio)    REFERENCES dbo.Pantallas (IdPantalla),
    CONSTRAINT FK_Usuarios_UsuarioCrea  FOREIGN KEY (UsuarioCreacion)     REFERENCES dbo.Usuarios (IdUsuario),
    CONSTRAINT FK_Usuarios_UsuarioMod   FOREIGN KEY (UsuarioModificacion) REFERENCES dbo.Usuarios (IdUsuario),
    CONSTRAINT CK_Usuarios_TipoUsuario  CHECK (TipoUsuario IN ('A', 'S', 'O')),
    CONSTRAINT UX_Usuarios_NombreUsuario UNIQUE (NombreUsuario)
);

CREATE INDEX IX_Usuarios_IdRol             ON dbo.Usuarios (IdRol);
CREATE INDEX IX_Usuarios_IdPantallaInicio  ON dbo.Usuarios (IdPantallaInicio);
CREATE INDEX IX_Usuarios_Activo            ON dbo.Usuarios (Activo, RowStatus);
GO

-- ============================================================
-- TABLA 5: PERMISOS (depende de Pantallas + Usuarios)
-- ============================================================
IF OBJECT_ID('dbo.Permisos', 'U') IS NOT NULL
    DROP TABLE dbo.Permisos;
GO

CREATE TABLE dbo.Permisos (
    IdPermiso           INT             IDENTITY(1,1)   NOT NULL,
    IdPantalla          INT                             NOT NULL,
    Nombre              VARCHAR(300)                    NOT NULL,
    Descripcion         VARCHAR(500)                    NULL,
    Clave               NVARCHAR(100)                   NULL,
    PuedeVer            BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeVer      DEFAULT (0),
    PuedeCrear          BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeCrear    DEFAULT (0),
    PuedeEditar         BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeEditar   DEFAULT (0),
    PuedeEliminar       BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeEliminar DEFAULT (0),
    PuedeAprobar        BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeAprobar  DEFAULT (0),
    PuedeAnular         BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeAnular   DEFAULT (0),
    PuedeImprimir       BIT                             NOT NULL    CONSTRAINT DF_Permisos_PuedeImprimir DEFAULT (0),
    Activo              BIT                             NOT NULL    CONSTRAINT DF_Permisos_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_Permisos_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_Permisos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_Permisos              PRIMARY KEY (IdPermiso),
    CONSTRAINT FK_Permisos_Pantallas    FOREIGN KEY (IdPantalla)          REFERENCES dbo.Pantallas (IdPantalla),
    CONSTRAINT FK_Permisos_UsuarioCrea  FOREIGN KEY (UsuarioCreacion)     REFERENCES dbo.Usuarios  (IdUsuario),
    CONSTRAINT FK_Permisos_UsuarioMod   FOREIGN KEY (UsuarioModificacion) REFERENCES dbo.Usuarios  (IdUsuario)
);

CREATE INDEX IX_Permisos_IdPantalla ON dbo.Permisos (IdPantalla, Activo);
CREATE INDEX IX_Permisos_Clave ON dbo.Permisos (Clave) WHERE Clave IS NOT NULL;
GO

-- ============================================================
-- TABLA 6: USUARIOSROLES (depende de Usuarios + Roles)
-- ============================================================
IF OBJECT_ID('dbo.UsuariosRoles', 'U') IS NOT NULL
    DROP TABLE dbo.UsuariosRoles;
GO

CREATE TABLE dbo.UsuariosRoles (
    IdUsuarioRol        INT             IDENTITY(1,1)   NOT NULL,
    IdUsuario           INT                             NOT NULL,
    IdRol               INT                             NOT NULL,
    Activo              BIT                             NOT NULL    CONSTRAINT DF_UsuariosRoles_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_UsuariosRoles_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_UsuariosRoles_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_UsuariosRoles             PRIMARY KEY (IdUsuarioRol),
    CONSTRAINT FK_UsuariosRoles_Usuarios    FOREIGN KEY (IdUsuario)           REFERENCES dbo.Usuarios (IdUsuario),
    CONSTRAINT FK_UsuariosRoles_Roles       FOREIGN KEY (IdRol)               REFERENCES dbo.Roles    (IdRol),
    CONSTRAINT FK_UsuariosRoles_UsuarioCrea FOREIGN KEY (UsuarioCreacion)     REFERENCES dbo.Usuarios (IdUsuario),
    CONSTRAINT FK_UsuariosRoles_UsuarioMod  FOREIGN KEY (UsuarioModificacion) REFERENCES dbo.Usuarios (IdUsuario)
);

CREATE INDEX IX_UsuariosRoles_IdUsuario ON dbo.UsuariosRoles (IdUsuario, Activo);
CREATE INDEX IX_UsuariosRoles_IdRol ON dbo.UsuariosRoles (IdRol, Activo);
GO

-- ============================================================
-- TABLA 7: ROLESPERMISOS (depende de Roles + Permisos + Usuarios)
-- ============================================================
IF OBJECT_ID('dbo.RolesPermisos', 'U') IS NOT NULL
    DROP TABLE dbo.RolesPermisos;
GO

CREATE TABLE dbo.RolesPermisos (
    IdRolPermiso        INT             IDENTITY(1,1)   NOT NULL,
    IdRol               INT                             NOT NULL,
    IdPermiso           INT                             NOT NULL,
    Activo              BIT                             NOT NULL    CONSTRAINT DF_RolesPermisos_Activo        DEFAULT (1),
    RowStatus           BIT                             NOT NULL    CONSTRAINT DF_RolesPermisos_RowStatus     DEFAULT (1),
    FechaCreacion       DATETIME                        NOT NULL    CONSTRAINT DF_RolesPermisos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion     INT                             NULL,
    FechaModificacion   DATETIME                        NULL,
    UsuarioModificacion INT                             NULL,

    CONSTRAINT PK_RolesPermisos             PRIMARY KEY (IdRolPermiso),
    CONSTRAINT FK_RolesPermisos_Roles       FOREIGN KEY (IdRol)               REFERENCES dbo.Roles    (IdRol),
    CONSTRAINT FK_RolesPermisos_Permisos    FOREIGN KEY (IdPermiso)           REFERENCES dbo.Permisos (IdPermiso),
    CONSTRAINT FK_RolesPermisos_UsuarioCrea FOREIGN KEY (UsuarioCreacion)     REFERENCES dbo.Usuarios (IdUsuario),
    CONSTRAINT FK_RolesPermisos_UsuarioMod  FOREIGN KEY (UsuarioModificacion) REFERENCES dbo.Usuarios (IdUsuario)
);

CREATE INDEX IX_RolesPermisos_IdRol ON dbo.RolesPermisos (IdRol, Activo);
CREATE INDEX IX_RolesPermisos_IdPermiso ON dbo.RolesPermisos (IdPermiso, Activo);
GO

-- ============================================================
-- SEED INICIAL
-- ============================================================

-- Desactivar identity_insert temporalmente para inserts con IdRol=0
SET IDENTITY_INSERT dbo.Roles ON;

-- Rol especial: SIN ROL (fallback para usuarios desasignados)
INSERT INTO dbo.Roles (IdRol, Nombre, Descripcion, Activo, RowStatus)
VALUES (0, 'SIN ROL', 'Rol de fallback para usuarios sin asignación', 0, 1);

SET IDENTITY_INSERT dbo.Roles OFF;
GO

-- Rol Administrador (IdRol=1, creado por IDENTITY)
INSERT INTO dbo.Roles (Nombre, Descripcion, Activo, RowStatus)
VALUES ('Administrador', 'Acceso total al sistema', 1, 1);

-- Rol Gerente (opcional, para estructura básica)
INSERT INTO dbo.Roles (Nombre, Descripcion, Activo, RowStatus)
VALUES ('Gerente', 'Acceso a pantallas de administración', 1, 1);

-- Rol Usuario Básico (opcional)
INSERT INTO dbo.Roles (Nombre, Descripcion, Activo, RowStatus)
VALUES ('Usuario', 'Acceso limitado a operaciones básicas', 1, 1);

PRINT 'Roles insertados correctamente';
GO

-- Módulo Configuración
INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, RowStatus)
VALUES ('Configuración', 'Settings', 100, 1, 1);

-- Módulo Dashboard (opcional)
INSERT INTO dbo.Modulos (Nombre, Icono, Orden, Activo, RowStatus)
VALUES ('Dashboard', 'BarChart3', 1, 1, 1);

PRINT 'Módulos insertados correctamente';
GO

-- Pantalla: Dashboard (ruta /)
INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Orden, Activo, RowStatus)
SELECT IdModulo, 'Panel Principal', '/', 1, 1, 1
FROM dbo.Modulos WHERE Nombre = 'Dashboard';

-- Pantalla: Empresa (ruta /config/company)
INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Orden, Activo, RowStatus)
SELECT IdModulo, 'Empresa', '/config/company', 10, 1, 1
FROM dbo.Modulos WHERE Nombre = 'Configuración';

-- Pantalla: Usuarios (ruta /config/security/users)
INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Orden, Activo, RowStatus)
SELECT IdModulo, 'Usuarios', '/config/security/users', 20, 1, 1
FROM dbo.Modulos WHERE Nombre = 'Configuración';

-- Pantalla: Roles (ruta /config/security/roles)
INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Orden, Activo, RowStatus)
SELECT IdModulo, 'Roles', '/config/security/roles', 30, 1, 1
FROM dbo.Modulos WHERE Nombre = 'Configuración';

-- Pantalla: Seguridad (ruta /config/security)
INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Orden, Activo, RowStatus)
SELECT IdModulo, 'Seguridad', '/config/security', 5, 1, 1
FROM dbo.Modulos WHERE Nombre = 'Configuración';

PRINT 'Pantallas insertadas correctamente';
GO

-- Usuario admin (IdUsuario=1, con IdRol=1 que es Administrador)
-- ClaveHash: SHA-256(base64) de "123456" = jZae727K08KaOmKSgOaGzww/XVqGr/PKEgIMkjrcbJI=
INSERT INTO dbo.Usuarios (
    IdRol,
    TipoUsuario,
    Nombres,
    Apellidos,
    NombreUsuario,
    Correo,
    ClaveHash,
    RequiereCambioClave,
    Bloqueado,
    Activo,
    RowStatus
) VALUES (
    1,
    'A',
    'Administrador',
    'Sistema',
    'admin',
    'admin@masu.local',
    'jZae727K08KaOmKSgOaGzww/XVqGr/PKEgIMkjrcbJI=',
    0,
    0,
    1,
    1
);

PRINT 'Usuario admin insertado correctamente';
PRINT '  - usuario: admin';
PRINT '  - clave: 123456 (SHA-256 base64: jZae727K08KaOmKSgOaGzww/XVqGr/PKEgIMkjrcbJI=)';
GO

-- Permisos base para cada pantalla (crear permiso "Acceso Total" con todos los flags en 1)
INSERT INTO dbo.Permisos (
    IdPantalla, Nombre, Descripcion, Clave,
    PuedeVer, PuedeCrear, PuedeEditar, PuedeEliminar, PuedeAprobar, PuedeAnular, PuedeImprimir,
    Activo, RowStatus
)
SELECT
    p.IdPantalla,
    'Acceso Total a ' + p.Nombre,
    'Permiso completo para ' + p.Nombre,
    LOWER(REPLACE(p.Ruta, '/', '.')) + '.manage',
    1, 1, 1, 1, 1, 1, 1,
    1, 1
FROM dbo.Pantallas p
WHERE p.RowStatus = 1;

PRINT 'Permisos base insertados correctamente';
GO

-- Asignar todos los permisos al rol Administrador
INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus)
SELECT
    r.IdRol,
    p.IdPermiso,
    1, 1
FROM dbo.Roles r
CROSS JOIN dbo.Permisos p
WHERE r.Nombre = 'Administrador'
  AND r.RowStatus = 1
  AND p.RowStatus = 1
  AND NOT EXISTS (
      SELECT 1 FROM dbo.RolesPermisos rp
      WHERE rp.IdRol = r.IdRol
        AND rp.IdPermiso = p.IdPermiso
        AND rp.RowStatus = 1
  );

PRINT 'Permisos asignados al rol Administrador';
GO

PRINT '============================================================';
PRINT 'SCRIPT 000_nucleo_base.sql COMPLETADO EXITOSAMENTE';
PRINT '============================================================';
PRINT 'Tablas creadas: Modulos, Roles, Pantallas, Usuarios, Permisos, UsuariosRoles, RolesPermisos';
PRINT 'Datos iniciales:';
PRINT '  - Rol Administrador + SIN ROL';
PRINT '  - Usuario admin (clave: 123456)';
PRINT '  - Módulos: Dashboard, Configuración';
PRINT '  - Pantallas: Panel Principal, Empresa, Usuarios, Roles, Seguridad';
PRINT '  - Permisos: Acceso Total para cada pantalla (asignados a Administrador)';
PRINT '============================================================';
