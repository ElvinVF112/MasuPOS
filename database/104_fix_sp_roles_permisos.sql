IF OBJECT_ID('dbo.spRolesPermisosCRUD', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.spRolesPermisosCRUD AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE dbo.spRolesPermisosCRUD
    @Accion CHAR(2),
    @IdRolPermiso INT = NULL,
    @IdRol INT = NULL,
    @IdPermiso INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @SessionId UNIQUEIDENTIFIER = NULL,
    @TokenSesion UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            RP.IdRolPermiso,
            RP.IdRol,
            R.Nombre AS RolNombre,
            RP.IdPermiso,
            P.Nombre AS PermisoNombre,
            RP.Activo,
            RP.RowStatus,
            RP.FechaCreacion,
            RP.UsuarioCreacion,
            RP.FechaModificacion,
            RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON R.IdRol = RP.IdRol
        INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
        WHERE ISNULL(RP.RowStatus, 1) = 1
        ORDER BY R.Nombre, P.Nombre;
        RETURN;
    END

    IF @Accion = 'LR'
    BEGIN
        SELECT
            RP.IdRolPermiso,
            RP.IdRol,
            RP.IdPermiso,
            RP.Activo,
            RP.RowStatus,
            RP.FechaCreacion,
            RP.UsuarioCreacion,
            RP.FechaModificacion,
            RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        WHERE RP.IdRol = @IdRol
          AND ISNULL(RP.RowStatus, 1) = 1;
        RETURN;
    END

    IF @Accion = 'O'
    BEGIN
        SELECT
            RP.IdRolPermiso,
            RP.IdRol,
            RP.IdPermiso,
            RP.Activo,
            RP.RowStatus,
            RP.FechaCreacion,
            RP.UsuarioCreacion,
            RP.FechaModificacion,
            RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        WHERE RP.IdRolPermiso = @IdRolPermiso;
        RETURN;
    END

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.RolesPermisos
            WHERE IdRol = @IdRol
              AND IdPermiso = @IdPermiso
              AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('El rol ya tiene este permiso asignado.', 16, 1);
            RETURN;
        END

        INSERT INTO dbo.RolesPermisos (
            IdRol,
            IdPermiso,
            Activo,
            RowStatus,
            FechaCreacion,
            UsuarioCreacion
        )
        VALUES (
            @IdRol,
            @IdPermiso,
            ISNULL(@Activo, 1),
            1,
            GETDATE(),
            @UsuarioCreacion
        );

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS IdRolPermiso;
        RETURN;
    END

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.RolesPermisos
        SET
            IdRol = ISNULL(@IdRol, IdRol),
            IdPermiso = ISNULL(@IdPermiso, IdPermiso),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso;

        RETURN;
    END

    IF @Accion = 'E'
    BEGIN
        UPDATE dbo.RolesPermisos
        SET
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso;

        RETURN;
    END

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.RolesPermisos
        SET
            RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso;

        RETURN;
    END
END
GO
