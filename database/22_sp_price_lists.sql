SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- SP principal CRUD de listas de precios (sin cambios de interfaz, solo regenerar)
CREATE OR ALTER PROCEDURE dbo.spListasPreciosCRUD
    @Accion CHAR(1),
    @IdListaPrecio INT = NULL OUTPUT,
    @Codigo NVARCHAR(20) = NULL,
    @Descripcion NVARCHAR(200) = NULL,
    @Abreviatura NVARCHAR(10) = NULL,
    @IdMoneda INT = NULL,
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(100) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- L: Listar todas activas
    IF @Accion = 'L'
    BEGIN
        SELECT
            LP.IdListaPrecio,
            LP.Codigo,
            LP.Descripcion,
            LP.Abreviatura,
            LP.IdMoneda,
            LP.FechaInicio,
            LP.FechaFin,
            LP.Activo,
            LP.FechaCreacion,
            LP.FechaModificacion,
            (SELECT COUNT(*) FROM dbo.ListaPrecioUsuarios LU
             WHERE LU.IdListaPrecio = LP.IdListaPrecio AND LU.RowStatus = 1) AS TotalUsuarios
        FROM dbo.ListasPrecios LP
        WHERE LP.RowStatus = 1
        ORDER BY LP.Codigo;
        RETURN;
    END;

    -- O: Obtener una por ID
    IF @Accion = 'O'
    BEGIN
        SELECT
            LP.IdListaPrecio,
            LP.Codigo,
            LP.Descripcion,
            LP.Abreviatura,
            LP.IdMoneda,
            LP.FechaInicio,
            LP.FechaFin,
            LP.Activo,
            LP.FechaCreacion,
            LP.FechaModificacion,
            (SELECT COUNT(*) FROM dbo.ListaPrecioUsuarios LU
             WHERE LU.IdListaPrecio = LP.IdListaPrecio AND LU.RowStatus = 1) AS TotalUsuarios
        FROM dbo.ListasPrecios LP
        WHERE LP.IdListaPrecio = @IdListaPrecio
          AND LP.RowStatus = 1;
        RETURN;
    END;

    -- I: Insertar
    IF @Accion = 'I'
    BEGIN
        IF NULLIF(LTRIM(RTRIM(ISNULL(@Codigo, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @Codigo.', 16, 1); RETURN; END;
        IF NULLIF(LTRIM(RTRIM(ISNULL(@Descripcion, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @Descripcion.', 16, 1); RETURN; END;
        IF NULLIF(LTRIM(RTRIM(ISNULL(@FechaInicio, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @FechaInicio.', 16, 1); RETURN; END;
        IF NULLIF(LTRIM(RTRIM(ISNULL(@FechaFin, ''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @FechaFin.', 16, 1); RETURN; END;
        IF EXISTS (SELECT 1 FROM dbo.ListasPrecios WHERE Codigo = LTRIM(RTRIM(@Codigo)) AND RowStatus = 1)
        BEGIN RAISERROR('Ya existe una lista de precios con ese Codigo.', 16, 1); RETURN; END;

        INSERT INTO dbo.ListasPrecios
            (Codigo, Descripcion, Abreviatura, IdMoneda, FechaInicio, FechaFin,
             Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (LTRIM(RTRIM(@Codigo)),
             LTRIM(RTRIM(@Descripcion)),
             NULLIF(LTRIM(RTRIM(ISNULL(@Abreviatura,''))), ''),
             @IdMoneda, @FechaInicio, @FechaFin,
             ISNULL(@Activo, 1), 1, SYSDATETIME(), @UsuarioCreacion);

        SET @IdListaPrecio = SCOPE_IDENTITY();
        EXEC dbo.spListasPreciosCRUD @Accion='O', @IdListaPrecio=@IdListaPrecio;
        RETURN;
    END;

    -- A: Actualizar
    IF @Accion = 'A'
    BEGIN
        IF NULLIF(LTRIM(RTRIM(ISNULL(@Descripcion,''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @Descripcion.', 16, 1); RETURN; END;
        IF NULLIF(LTRIM(RTRIM(ISNULL(@FechaInicio,''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @FechaInicio.', 16, 1); RETURN; END;
        IF NULLIF(LTRIM(RTRIM(ISNULL(@FechaFin,''))), '') IS NULL
        BEGIN RAISERROR('Debe enviar @FechaFin.', 16, 1); RETURN; END;
        IF EXISTS (SELECT 1 FROM dbo.ListasPrecios
                   WHERE Codigo = LTRIM(RTRIM(@Codigo))
                     AND IdListaPrecio <> @IdListaPrecio
                     AND RowStatus = 1)
        BEGIN RAISERROR('Ya existe otra lista con ese Codigo.', 16, 1); RETURN; END;

        UPDATE dbo.ListasPrecios SET
            Descripcion          = LTRIM(RTRIM(@Descripcion)),
            Abreviatura          = NULLIF(LTRIM(RTRIM(ISNULL(@Abreviatura,''))), ''),
            IdMoneda             = @IdMoneda,
            FechaInicio          = @FechaInicio,
            FechaFin             = @FechaFin,
            Activo               = ISNULL(@Activo, Activo),
            FechaModificacion    = SYSDATETIME(),
            UsuarioModificacion  = @UsuarioModificacion
        WHERE IdListaPrecio = @IdListaPrecio AND RowStatus = 1;

        EXEC dbo.spListasPreciosCRUD @Accion='O', @IdListaPrecio=@IdListaPrecio;
        RETURN;
    END;

    -- D: Soft delete
    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.ListasPrecios SET
            RowStatus           = 0,
            FechaModificacion   = SYSDATETIME(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdListaPrecio = @IdListaPrecio AND RowStatus = 1;

        UPDATE dbo.ListaPrecioUsuarios SET RowStatus = 0
        WHERE IdListaPrecio = @IdListaPrecio;

        SELECT @IdListaPrecio AS IdListaPrecio;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, I, A o D.', 16, 1);
END;
GO
-- SP usuarios de lista: acciones LA (asignados), LD (disponibles), A (asignar), Q (quitar)
CREATE OR ALTER PROCEDURE dbo.spListaPrecioUsuarios
    @Accion CHAR(2),
    @IdListaPrecio INT,
    @IdUsuario INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- LA: Listar usuarios Asignados a la lista
    IF @Accion = 'LA'
    BEGIN
        SELECT
            U.IdUsuario,
            U.NombreUsuario,
            U.Nombres,
            U.Apellidos
        FROM dbo.ListaPrecioUsuarios LU
        INNER JOIN dbo.Usuarios U ON U.IdUsuario = LU.IdUsuario
        WHERE LU.IdListaPrecio = @IdListaPrecio
          AND LU.RowStatus = 1
          AND U.RowStatus = 1
        ORDER BY U.NombreUsuario;
        RETURN;
    END;

    -- LD: Listar usuarios Disponibles (no asignados)
    IF @Accion = 'LD'
    BEGIN
        SELECT
            U.IdUsuario,
            U.NombreUsuario,
            U.Nombres,
            U.Apellidos
        FROM dbo.Usuarios U
        WHERE U.RowStatus = 1
          AND U.Activo = 1
          AND NOT EXISTS (
              SELECT 1 FROM dbo.ListaPrecioUsuarios LU
              WHERE LU.IdUsuario = U.IdUsuario
                AND LU.IdListaPrecio = @IdListaPrecio
                AND LU.RowStatus = 1
          )
        ORDER BY U.NombreUsuario;
        RETURN;
    END;

    -- A: Asignar usuario
    IF @Accion = 'A'
    BEGIN
        IF EXISTS (
            SELECT 1 FROM dbo.ListaPrecioUsuarios
            WHERE IdListaPrecio = @IdListaPrecio AND IdUsuario = @IdUsuario AND RowStatus = 0
        )
        BEGIN
            UPDATE dbo.ListaPrecioUsuarios SET RowStatus = 1, FechaCreacion = SYSDATETIME()
            WHERE IdListaPrecio = @IdListaPrecio AND IdUsuario = @IdUsuario AND RowStatus = 0;
        END
        ELSE IF NOT EXISTS (
            SELECT 1 FROM dbo.ListaPrecioUsuarios
            WHERE IdListaPrecio = @IdListaPrecio AND IdUsuario = @IdUsuario
        )
        BEGIN
            INSERT INTO dbo.ListaPrecioUsuarios (IdListaPrecio, IdUsuario, RowStatus, FechaCreacion)
            VALUES (@IdListaPrecio, @IdUsuario, 1, SYSDATETIME());
        END;

        EXEC dbo.spListaPrecioUsuarios @Accion='LA', @IdListaPrecio=@IdListaPrecio;
        EXEC dbo.spListaPrecioUsuarios @Accion='LD', @IdListaPrecio=@IdListaPrecio;
        RETURN;
    END;

    -- Q: Quitar usuario
    IF @Accion = 'Q'
    BEGIN
        UPDATE dbo.ListaPrecioUsuarios SET RowStatus = 0
        WHERE IdListaPrecio = @IdListaPrecio
          AND IdUsuario = @IdUsuario
          AND RowStatus = 1;

        EXEC dbo.spListaPrecioUsuarios @Accion='LA', @IdListaPrecio=@IdListaPrecio;
        EXEC dbo.spListaPrecioUsuarios @Accion='LD', @IdListaPrecio=@IdListaPrecio;
        RETURN;
    END;

    -- AA: Asignar TODOS los usuarios disponibles
    IF @Accion = 'AA'
    BEGIN
        UPDATE dbo.ListaPrecioUsuarios SET RowStatus = 1, FechaCreacion = SYSDATETIME()
        WHERE IdListaPrecio = @IdListaPrecio AND RowStatus = 0
          AND EXISTS (SELECT 1 FROM dbo.Usuarios U WHERE U.IdUsuario = ListaPrecioUsuarios.IdUsuario AND U.RowStatus = 1 AND U.Activo = 1);

        INSERT INTO dbo.ListaPrecioUsuarios (IdListaPrecio, IdUsuario, RowStatus, FechaCreacion)
        SELECT @IdListaPrecio, U.IdUsuario, 1, SYSDATETIME()
        FROM dbo.Usuarios U
        WHERE U.RowStatus = 1 AND U.Activo = 1
          AND NOT EXISTS (SELECT 1 FROM dbo.ListaPrecioUsuarios LU
                          WHERE LU.IdListaPrecio = @IdListaPrecio AND LU.IdUsuario = U.IdUsuario);

        EXEC dbo.spListaPrecioUsuarios @Accion='LA', @IdListaPrecio=@IdListaPrecio;
        EXEC dbo.spListaPrecioUsuarios @Accion='LD', @IdListaPrecio=@IdListaPrecio;
        RETURN;
    END;

    -- QA: Quitar TODOS los usuarios asignados
    IF @Accion = 'QA'
    BEGIN
        UPDATE dbo.ListaPrecioUsuarios SET RowStatus = 0
        WHERE IdListaPrecio = @IdListaPrecio AND RowStatus = 1;

        EXEC dbo.spListaPrecioUsuarios @Accion='LA', @IdListaPrecio=@IdListaPrecio;
        EXEC dbo.spListaPrecioUsuarios @Accion='LD', @IdListaPrecio=@IdListaPrecio;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use LA, LD, A, Q, AA o QA.', 16, 1);
END;
GO
UPDATE dbo.ListasPrecios SET FechaInicio = '2018-01-01', FechaFin = '2099-12-31'
WHERE (FechaInicio IS NULL OR FechaFin IS NULL) AND RowStatus = 1;
GO
SELECT 'SPs actualizados correctamente' AS Result;
GO
