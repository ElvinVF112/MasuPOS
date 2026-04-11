SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF COL_LENGTH('dbo.Usuarios', 'IdEmpresa') IS NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD IdEmpresa INT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.foreign_keys
    WHERE name = 'FK_Usuarios_Empresa'
)
AND EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.Usuarios')
      AND name = 'IdEmpresa'
)
AND OBJECT_ID('dbo.Empresa', 'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Usuarios
    ADD CONSTRAINT FK_Usuarios_Empresa
    FOREIGN KEY (IdEmpresa) REFERENCES dbo.Empresa(IdEmpresa);
END
GO

IF OBJECT_ID('dbo.spUsuariosCRUD', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.spUsuariosCRUD AS BEGIN SET NOCOUNT ON; END');
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
    @IdEmpresa INT = NULL,
    @IdDivision INT = NULL,
    @IdSucursal INT = NULL,
    @IdPuntoEmision INT = NULL,
    @NivelAcceso CHAR(1) = NULL,
    @IdSesion BIGINT = 0,
    @TokenSesion NVARCHAR(200) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @TipoUsuario = UPPER(LTRIM(RTRIM(ISNULL(@TipoUsuario, 'O'))));
    SET @NivelAcceso = UPPER(LTRIM(RTRIM(ISNULL(@NivelAcceso, 'G'))));

    IF @Accion IN ('I', 'A') AND @TipoUsuario NOT IN ('A', 'S', 'O')
    BEGIN
        RAISERROR('Debe indicar @TipoUsuario valido: A, S u O.', 16, 1);
        RETURN;
    END;

    IF @Accion IN ('I', 'A') AND @NivelAcceso NOT IN ('G', 'E', 'D', 'S', 'P', 'U')
    BEGIN
        RAISERROR('Debe indicar @NivelAcceso valido: G, E, D, S, P o U.', 16, 1);
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
            U.IdEmpresa,
            E.RazonSocial AS EmpresaNombre,
            U.IdDivision,
            D.Nombre AS DivisionNombre,
            U.IdSucursal,
            S.Nombre AS SucursalNombre,
            U.IdPuntoEmision,
            PE.Nombre AS PuntoEmisionNombre,
            U.NivelAcceso,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        LEFT JOIN dbo.Empresa E ON E.IdEmpresa = U.IdEmpresa
        LEFT JOIN dbo.Divisiones D ON D.IdDivision = U.IdDivision
        LEFT JOIN dbo.Sucursales S ON S.IdSucursal = U.IdSucursal
        LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = U.IdPuntoEmision
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
            U.IdEmpresa,
            E.RazonSocial AS EmpresaNombre,
            U.IdDivision,
            D.Nombre AS DivisionNombre,
            U.IdSucursal,
            S.Nombre AS SucursalNombre,
            U.IdPuntoEmision,
            PE.Nombre AS PuntoEmisionNombre,
            U.NivelAcceso,
            U.RowStatus,
            U.FechaCreacion,
            U.UsuarioCreacion,
            U.FechaModificacion,
            U.UsuarioModificacion
        FROM dbo.Usuarios U
        INNER JOIN dbo.Roles R ON R.IdRol = U.IdRol
        LEFT JOIN dbo.Pantallas P ON P.IdPantalla = U.IdPantallaInicio
        LEFT JOIN dbo.Empresa E ON E.IdEmpresa = U.IdEmpresa
        LEFT JOIN dbo.Divisiones D ON D.IdDivision = U.IdDivision
        LEFT JOIN dbo.Sucursales S ON S.IdSucursal = U.IdSucursal
        LEFT JOIN dbo.PuntosEmision PE ON PE.IdPuntoEmision = U.IdPuntoEmision
        WHERE U.IdUsuario = @IdUsuario;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.Usuarios
            WHERE NombreUsuario = @NombreUsuario
              AND ISNULL(RowStatus, 1) = 1
        )
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
            IdEmpresa,
            IdDivision,
            IdSucursal,
            IdPuntoEmision,
            NivelAcceso,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion
        )
        VALUES (
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
            @IdEmpresa,
            @IdDivision,
            @IdSucursal,
            @IdPuntoEmision,
            @NivelAcceso,
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
            IdEmpresa = @IdEmpresa,
            IdDivision = @IdDivision,
            IdSucursal = @IdSucursal,
            IdPuntoEmision = @IdPuntoEmision,
            NivelAcceso = ISNULL(@NivelAcceso, NivelAcceso),
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
