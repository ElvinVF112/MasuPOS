IF OBJECT_ID('dbo.spUsuariosCRUD', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.spUsuariosCRUD AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE dbo.spUsuariosCRUD
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
    @Bloqueado BIT = NULL,
    @Activo BIT = NULL,
    @TipoUsuario CHAR(1) = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @TipoUsuario = UPPER(LTRIM(RTRIM(ISNULL(@TipoUsuario, 'O'))));

    IF @Accion IN ('I', 'A') AND @TipoUsuario NOT IN ('A', 'S', 'O')
    BEGIN
        RAISERROR('Debe indicar @TipoUsuario valido: A, S u O.', 16, 1);
        RETURN;
    END;

    IF @Accion = 'L'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.TipoUsuario,
            U.IdPantallaInicio,
            ISNULL(P.Nombre, '') AS PantallaInicio,
            ISNULL(P.Ruta, '/') AS RutaInicio,
            R.Nombre AS Rol,
            U.Nombres,
            U.Apellidos,
            U.NombreUsuario,
            U.Correo,
            U.RequiereCambioClave,
            U.Bloqueado,
            U.Activo,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        WHERE ISNULL(U.RowStatus, 1) = 1
        ORDER BY U.NombreUsuario;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            U.IdUsuario,
            U.IdRol,
            U.TipoUsuario,
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
            U.Bloqueado,
            U.Activo,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        WHERE U.IdUsuario = @IdUsuario;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.Usuarios WHERE NombreUsuario = @NombreUsuario AND ISNULL(RowStatus, 1) = 1)
        BEGIN
            RAISERROR('Ya existe un usuario con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Usuarios (
            IdRol,
            TipoUsuario,
            IdPantallaInicio,
            Nombres,
            Apellidos,
            NombreUsuario,
            Correo,
            ClaveHash,
            RequiereCambioClave,
            Bloqueado,
            Activo,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion
        ) VALUES (
            @IdRol,
            @TipoUsuario,
            @IdPantallaInicio,
            @Nombres,
            @Apellidos,
            @NombreUsuario,
            @Correo,
            @ClaveHash,
            ISNULL(@RequiereCambioClave, 0),
            ISNULL(@Bloqueado, 0),
            ISNULL(@Activo, 1),
            1,
            GETDATE(),
            @UsuarioCreacion
        );

        SET @IdUsuario = SCOPE_IDENTITY();
        SELECT @IdUsuario AS IdUsuario;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.Usuarios
            WHERE NombreUsuario = @NombreUsuario
              AND IdUsuario <> @IdUsuario
              AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe un usuario con ese nombre.', 16, 1);
            RETURN;
        END;

        UPDATE dbo.Usuarios
        SET
            IdRol = ISNULL(@IdRol, IdRol),
            TipoUsuario = ISNULL(@TipoUsuario, TipoUsuario),
            IdPantallaInicio = @IdPantallaInicio,
            Nombres = ISNULL(@Nombres, Nombres),
            Apellidos = ISNULL(@Apellidos, Apellidos),
            NombreUsuario = ISNULL(@NombreUsuario, NombreUsuario),
            Correo = @Correo,
            ClaveHash = ISNULL(NULLIF(@ClaveHash, ''), ClaveHash),
            RequiereCambioClave = ISNULL(@RequiereCambioClave, RequiereCambioClave),
            Bloqueado = ISNULL(@Bloqueado, Bloqueado),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Usuarios
        SET
            RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUsuario = @IdUsuario;
        RETURN;
    END;
END
GO
