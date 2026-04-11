SET NOCOUNT ON;
GO

IF COL_LENGTH('dbo.Usuarios', 'IdRol') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios ADD IdRol INT NULL;
END
GO

IF COL_LENGTH('dbo.Usuarios', 'IdPantallaInicio') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios ADD IdPantallaInicio INT NULL;
END
GO

IF COL_LENGTH('dbo.Usuarios', 'RequiereCambioClave') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD RequiereCambioClave BIT NOT NULL
        CONSTRAINT DF_Usuarios_RequiereCambioClave DEFAULT (0);
END
GO

;WITH RolPreferido AS (
    SELECT
        UR.IdUsuario,
        UR.IdRol,
        ROW_NUMBER() OVER (
            PARTITION BY UR.IdUsuario
            ORDER BY CASE WHEN UR.Activo = 1 THEN 0 ELSE 1 END, UR.IdUsuarioRol DESC
        ) AS RN
    FROM dbo.UsuariosRoles UR
    WHERE UR.RowStatus = 1
)
UPDATE U
SET U.IdRol = RP.IdRol
FROM dbo.Usuarios U
INNER JOIN RolPreferido RP ON RP.IdUsuario = U.IdUsuario AND RP.RN = 1
WHERE U.IdRol IS NULL;
GO

DECLARE @RolDefault INT;
SELECT TOP (1) @RolDefault = R.IdRol
FROM dbo.Roles R
WHERE R.RowStatus = 1 AND R.Activo = 1
ORDER BY R.IdRol;

IF @RolDefault IS NULL
BEGIN
    RAISERROR('No existe un rol activo en dbo.Roles para asignar a Usuarios.', 16, 1);
    RETURN;
END;

UPDATE dbo.Usuarios
SET IdRol = @RolDefault
WHERE IdRol IS NULL;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Usuarios_Roles_IdRol'
)
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD CONSTRAINT FK_Usuarios_Roles_IdRol
    FOREIGN KEY (IdRol) REFERENCES dbo.Roles (IdRol);
END
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Usuarios') AND name = 'IdRol' AND is_nullable = 1)
BEGIN
    ALTER TABLE dbo.Usuarios ALTER COLUMN IdRol INT NOT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Usuarios') AND name = 'IX_Usuarios_IdRol'
)
BEGIN
    CREATE INDEX IX_Usuarios_IdRol ON dbo.Usuarios (IdRol);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Usuarios_Pantallas_IdPantallaInicio'
)
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD CONSTRAINT FK_Usuarios_Pantallas_IdPantallaInicio
    FOREIGN KEY (IdPantallaInicio) REFERENCES dbo.Pantallas (IdPantalla);
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.Usuarios') AND name = 'IX_Usuarios_IdPantallaInicio'
)
BEGIN
    CREATE INDEX IX_Usuarios_IdPantallaInicio ON dbo.Usuarios (IdPantallaInicio);
END
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spUsuariosCRUD
    @Accion CHAR(1),
    @IdUsuario INT = NULL OUTPUT,
    @IdRol INT = NULL,
    @IdPantallaInicio INT = NULL,
    @Nombres NVARCHAR(150) = NULL,
    @Apellidos NVARCHAR(150) = NULL,
    @NombreUsuario NVARCHAR(100) = NULL,
    @Correo NVARCHAR(150) = NULL,
    @ClaveHash NVARCHAR(500) = NULL,
    @RequiereCambioClave BIT = NULL,
    @Activo BIT = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.IdPantallaInicio,
            ISNULL(P.Nombre, '') AS PantallaInicio,
            ISNULL(P.Ruta, '/') AS RutaInicio,
            R.Nombre AS Rol,
            U.Nombres,
            U.Apellidos,
            U.NombreUsuario,
            U.Correo,
            U.RequiereCambioClave,
            U.Activo,
            U.RowStatus,
            U.FechaCreacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        WHERE U.RowStatus = 1
        ORDER BY U.NombreUsuario;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.IdPantallaInicio,
            ISNULL(P.Nombre, '') AS PantallaInicio,
            ISNULL(P.Ruta, '/') AS RutaInicio,
            R.Nombre AS Rol,
            U.Nombres,
            U.Apellidos,
            U.NombreUsuario,
            U.Correo,
            U.ClaveHash,
            U.RequiereCambioClave,
            U.Activo,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        WHERE U.IdUsuario = @IdUsuario
          AND U.RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF @IdRol IS NULL
        BEGIN
            RAISERROR('Debe enviar @IdRol para crear el usuario.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Usuarios
            (IdRol, IdPantallaInicio, Nombres, Apellidos, NombreUsuario, Correo, ClaveHash, RequiereCambioClave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdRol, NULLIF(@IdPantallaInicio, 0), LTRIM(RTRIM(@Nombres)), LTRIM(RTRIM(@Apellidos)), LTRIM(RTRIM(@NombreUsuario)), NULLIF(LTRIM(RTRIM(@Correo)), ''), @ClaveHash, ISNULL(@RequiereCambioClave, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        SET @IdUsuario = SCOPE_IDENTITY();
        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Usuarios
        SET
            IdRol = ISNULL(@IdRol, IdRol),
            IdPantallaInicio = CASE WHEN @IdPantallaInicio IS NULL THEN IdPantallaInicio ELSE NULLIF(@IdPantallaInicio, 0) END,
            Nombres = LTRIM(RTRIM(@Nombres)),
            Apellidos = LTRIM(RTRIM(@Apellidos)),
            NombreUsuario = LTRIM(RTRIM(@NombreUsuario)),
            Correo = NULLIF(LTRIM(RTRIM(@Correo)), ''),
            RequiereCambioClave = ISNULL(@RequiereCambioClave, RequiereCambioClave),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario
          AND RowStatus = 1;

        IF @ClaveHash IS NOT NULL AND LEN(@ClaveHash) > 0
        BEGIN
            UPDATE dbo.Usuarios
            SET ClaveHash = @ClaveHash
            WHERE IdUsuario = @IdUsuario
              AND RowStatus = 1;
        END;

        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Usuarios
        SET
            RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario
          AND RowStatus = 1;

        EXEC dbo.spUsuariosCRUD @Accion='O', @IdUsuario=@IdUsuario, @IdSesion=@IdSesion, @TokenSesion=@TokenSesion;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spUsuariosLogin
    @NombreUsuario NVARCHAR(150),
    @ClaveHash NVARCHAR(500),
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF LTRIM(RTRIM(@NombreUsuario)) = ''
    BEGIN
        RAISERROR('Debe enviar @NombreUsuario.', 16, 1);
        RETURN;
    END;

    IF @ClaveHash IS NULL
    BEGIN
        RAISERROR('Debe enviar @ClaveHash.', 16, 1);
        RETURN;
    END;

    SELECT
        U.IdUsuario,
        U.IdRol,
        U.IdPantallaInicio,
        ISNULL(P.Ruta, '/') AS RutaInicio,
        R.Nombre AS Rol,
        U.Nombres,
        U.Apellidos,
        U.NombreUsuario,
        U.Correo,
        U.Activo,
        U.FechaCreacion
    FROM dbo.Usuarios U
    INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
    LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
    WHERE U.NombreUsuario = LTRIM(RTRIM(@NombreUsuario))
      AND U.ClaveHash = @ClaveHash
      AND U.RowStatus = 1;
END;
GO
