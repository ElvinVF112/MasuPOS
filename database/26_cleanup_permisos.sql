-- TAREA 26: Limpieza Estructura DB: Roles-Permisos-Visualizacion
-- Capa 1 (Permisos) solo contiene route keys para el menu
-- Capa 2 (RolPantallaPermisos) es la unica fuente de CRUD granular
-- Capa 3 (RolCamposVisibilidad) correcta, no tocar

-- ══════════════════════════════════════════════════════════════
-- 26.3: Actualizar spPermisosObtenerPorRol
-- Quitar logica de compatibilidad pVer/PuedeVer y filtro redundant
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spPermisosObtenerPorRol', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spPermisosObtenerPorRol
GO

CREATE PROCEDURE dbo.spPermisosObtenerPorRol
  @IdRol INT
AS
BEGIN
  SET NOCOUNT ON;

  IF @IdRol IS NULL OR @IdRol <= 0
  BEGIN
    RAISERROR('Debe enviar @IdRol valido.', 16, 1);
    RETURN;
  END;

  SELECT DISTINCT
    LOWER(LTRIM(RTRIM(PA.Ruta))) AS ClaveRuta
  FROM dbo.RolesPermisos RP
  INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
  INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = PE.IdPantalla
  WHERE RP.RowStatus = 1
    AND RP.Activo = 1
    AND PE.RowStatus = 1
    AND PE.Activo = 1
    AND PA.RowStatus = 1
    AND PA.Activo = 1
    AND RP.IdRol = @IdRol
    AND NULLIF(LTRIM(RTRIM(PA.Ruta)), '''') IS NOT NULL
  ORDER BY ClaveRuta;
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 26.4: Actualizar spPermisosCRUD
-- Quitar parametros y logica de columnas CRUD eliminadas
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spPermisosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spPermisosCRUD
GO

CREATE PROCEDURE dbo.spPermisosCRUD
    @Accion CHAR(1),
    @IdPermiso INT = NULL OUTPUT,
    @IdPantalla INT = NULL,
    @Nombre NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT P.IdPermiso,
               P.IdPantalla,
               PA.Nombre AS Pantalla,
               M.Nombre AS Modulo,
               P.Nombre,
               P.Descripcion,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.RowStatus = 1
        ORDER BY M.Orden, PA.Orden, P.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT P.IdPermiso,
               P.IdPantalla,
               PA.Nombre AS Pantalla,
               M.Nombre AS Modulo,
               P.Nombre,
               P.Descripcion,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso AND P.RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Permisos
            (IdPantalla, Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdPantalla,
             LTRIM(RTRIM(@Nombre)),
             NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
             ISNULL(@Activo, 1),
             1,
             GETDATE(),
             @UsuarioCreacion);
        SET @IdPermiso = SCOPE_IDENTITY();
        SELECT P.IdPermiso,
               P.IdPantalla,
               PA.Nombre AS Pantalla,
               M.Nombre AS Modulo,
               P.Nombre,
               P.Descripcion,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Permisos
        SET IdPantalla = @IdPantalla,
            Nombre = LTRIM(RTRIM(@Nombre)),
            Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPermiso = @IdPermiso AND RowStatus = 1;
        SELECT P.IdPermiso,
               P.IdPantalla,
               PA.Nombre AS Pantalla,
               M.Nombre AS Modulo,
               P.Nombre,
               P.Descripcion,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso AND P.RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Permisos
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPermiso = @IdPermiso AND RowStatus = 1;
        SELECT P.IdPermiso,
               P.IdPantalla,
               PA.Nombre AS Pantalla,
               M.Nombre AS Modulo,
               P.Nombre,
               P.Descripcion,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 26.2: Eliminar columnas CRUD redundantes de Permisos
-- ══════════════════════════════════════════════════════════════
ALTER TABLE dbo.Permisos DROP COLUMN
  PuedeVer,
  PuedeCrear,
  PuedeEditar,
  PuedeEliminar,
  PuedeAprobar,
  PuedeAnular,
  PuedeImprimir
GO

-- Verificar que las columnas se eliminaron
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Permisos' AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION
GO

-- ══════════════════════════════════════════════════════════════
-- 26.3 (complemento): Actualizar spRolesPermisosCRUD
-- Quitar columnas CRUD de SELECT (ya no existen en Permisos)
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spRolesPermisosCRUD', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spRolesPermisosCRUD
GO

CREATE PROCEDURE dbo.spRolesPermisosCRUD
    @Accion CHAR(1),
    @IdRolPermiso INT = NULL OUTPUT,
    @IdRol INT = NULL,
    @IdPermiso INT = NULL,
    @Activo BIT = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre AS Rol,
               RP.IdPermiso,
               P.Nombre AS Permiso,
               M.Nombre AS Modulo,
               PA.Nombre AS Pantalla,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON RP.IdRol = R.IdRol
        INNER JOIN dbo.Permisos P ON RP.IdPermiso = P.IdPermiso
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE RP.RowStatus = 1
        ORDER BY R.Nombre, M.Orden, PA.Orden, P.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre AS Rol,
               RP.IdPermiso,
               P.Nombre AS Permiso,
               M.Nombre AS Modulo,
               PA.Nombre AS Pantalla,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON RP.IdRol = R.IdRol
        INNER JOIN dbo.Permisos P ON RP.IdPermiso = P.IdPermiso
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE RP.IdRolPermiso = @IdRolPermiso AND RP.RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.RolesPermisos
                   WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso AND RowStatus = 1)
        BEGIN
            RAISERROR('El rol ya tiene este permiso asignado.', 16, 1);
            RETURN;
        END;
        INSERT INTO dbo.RolesPermisos
            (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdRol, @IdPermiso, ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);
        SET @IdRolPermiso = SCOPE_IDENTITY();
        SELECT RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre AS Rol,
               RP.IdPermiso,
               P.Nombre AS Permiso,
               M.Nombre AS Modulo,
               PA.Nombre AS Pantalla,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON RP.IdRol = R.IdRol
        INNER JOIN dbo.Permisos P ON RP.IdPermiso = P.IdPermiso
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE RP.IdRolPermiso = @IdRolPermiso;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.RolesPermisos
        SET IdRol = @IdRol,
            IdPermiso = @IdPermiso,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso AND RowStatus = 1;
        SELECT RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre AS Rol,
               RP.IdPermiso,
               P.Nombre AS Permiso,
               M.Nombre AS Modulo,
               PA.Nombre AS Pantalla,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON RP.IdRol = R.IdRol
        INNER JOIN dbo.Permisos P ON RP.IdPermiso = P.IdPermiso
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE RP.IdRolPermiso = @IdRolPermiso AND RP.RowStatus = 1;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.RolesPermisos
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso AND RowStatus = 1;
        SELECT RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre AS Rol,
               RP.IdPermiso,
               P.Nombre AS Permiso,
               M.Nombre AS Modulo,
               PA.Nombre AS Pantalla,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON RP.IdRol = R.IdRol
        INNER JOIN dbo.Permisos P ON RP.IdPermiso = P.IdPermiso
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE RP.IdRolPermiso = @IdRolPermiso;
        RETURN;
    END;

    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 26.3 (complemento): Actualizar spRolesPermisosListar
-- Quitar columnas CRUD de SELECT
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spRolesPermisosListar', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spRolesPermisosListar
GO

CREATE PROCEDURE dbo.spRolesPermisosListar
    @IdRol INT = NULL,
    @IdPermiso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RP.IdRolPermiso,
           RP.IdRol,
           R.Nombre AS Rol,
           RP.IdPermiso,
           P.Nombre AS Permiso,
           M.Nombre AS Modulo,
           PA.Nombre AS Pantalla,
           RP.Activo,
           RP.RowStatus,
           RP.FechaCreacion
    FROM dbo.RolesPermisos RP
    INNER JOIN dbo.Roles R ON R.IdRol = RP.IdRol
    INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
    INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
    INNER JOIN dbo.Modulos M ON M.IdModulo = PA.IdModulo
    WHERE (@IdRol IS NULL OR RP.IdRol = @IdRol)
          AND (@IdPermiso IS NULL OR RP.IdPermiso = @IdPermiso)
          AND RP.RowStatus = 1
    ORDER BY R.Nombre, M.Orden, PA.Orden, P.Nombre;
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 26.3 (complemento): Actualizar spRolesPermisosAsignar
-- Quitar columnas CRUD de SELECT
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spRolesPermisosAsignar', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spRolesPermisosAsignar
GO

CREATE PROCEDURE dbo.spRolesPermisosAsignar
    @IdRol INT,
    @IdPermiso INT,
    @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@IdRol, 0) = 0
    BEGIN
        RAISERROR('Debe enviar @IdRol.', 16, 1);
        RETURN;
    END;

    IF ISNULL(@IdPermiso, 0) = 0
    BEGIN
        RAISERROR('Debe enviar @IdPermiso.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE IdRol = @IdRol)
    BEGIN
        RAISERROR('El rol indicado no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPermiso = @IdPermiso)
    BEGIN
        RAISERROR('El permiso indicado no existe.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso)
    BEGIN
        UPDATE dbo.RolesPermisos
        SET Activo = ISNULL(@Activo, 1)
        WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso;

        SELECT RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre AS Rol,
               RP.IdPermiso,
               P.Nombre AS Permiso,
               M.Nombre AS Modulo,
               PA.Nombre AS Pantalla,
               RP.Activo,
               RP.FechaCreacion
        FROM dbo.RolesPermisos RP
        INNER JOIN dbo.Roles R ON R.IdRol = RP.IdRol
        INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
        INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
        INNER JOIN dbo.Modulos M ON M.IdModulo = PA.IdModulo
        WHERE RP.IdRol = @IdRol AND RP.IdPermiso = @IdPermiso;
        RETURN;
    END;

    INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, FechaCreacion)
    VALUES (@IdRol, @IdPermiso, ISNULL(@Activo, 1), GETDATE());

    SELECT RP.IdRolPermiso,
           RP.IdRol,
           R.Nombre AS Rol,
           RP.IdPermiso,
           P.Nombre AS Permiso,
           M.Nombre AS Modulo,
           PA.Nombre AS Pantalla,
           RP.Activo,
           RP.FechaCreacion
    FROM dbo.RolesPermisos RP
    INNER JOIN dbo.Roles R ON R.IdRol = RP.IdRol
    INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
    INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
    INNER JOIN dbo.Modulos M ON M.IdModulo = PA.IdModulo
    WHERE RP.IdRolPermiso = SCOPE_IDENTITY();
END;
GO

-- ══════════════════════════════════════════════════════════════
-- 26.3 (complemento): Actualizar spRolPermisosPorModulo
-- ScreenPermissionBase ahora usa valores default 0
-- (RolPantallaPermisos es la unica fuente de CRUD)
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spRolPermisosPorModulo', 'P') IS NOT NULL
    DROP PROCEDURE dbo.spRolPermisosPorModulo
GO

CREATE PROCEDURE dbo.spRolPermisosPorModulo
  @IdRol INT
AS
BEGIN
  SET NOCOUNT ON;

  IF @IdRol IS NULL OR @IdRol <= 0
  BEGIN
    RAISERROR('Debe enviar @IdRol valido.', 16, 1);
    RETURN;
  END;

  IF OBJECT_ID('tempdb..#ScreenPermissionMerged') IS NOT NULL DROP TABLE #ScreenPermissionMerged;

  ;WITH ScreenPermissionBase AS (
      SELECT
        P.IdPantalla,
        MAX(CASE WHEN RP.IdRolPermiso IS NOT NULL AND RP.Activo = 1 AND RP.RowStatus = 1 THEN 1 ELSE 0 END) AS AccessByRolePerm
      FROM dbo.Pantallas P
      LEFT JOIN dbo.Permisos PE ON PE.IdPantalla = P.IdPantalla AND PE.RowStatus = 1 AND PE.Activo = 1
      LEFT JOIN dbo.RolesPermisos RP ON RP.IdPermiso = PE.IdPermiso AND RP.IdRol = @IdRol
      WHERE P.RowStatus = 1 AND P.Activo = 1
      GROUP BY P.IdPantalla
  )
  SELECT
    P.IdPantalla,
    P.IdModulo,
    M.Nombre AS Modulo,
    P.Nombre AS Pantalla,
    P.Ruta,
    CAST(CASE
      WHEN RPP.Id IS NOT NULL THEN ISNULL(RPP.AccessEnabled, 0)
      ELSE ISNULL(SPB.AccessByRolePerm, 0)
    END AS BIT) AS AccessEnabled,
    CAST(COALESCE(RPP.CanCreate, 0) AS BIT) AS CanCreate,
    CAST(COALESCE(RPP.CanEdit, 0) AS BIT) AS CanEdit,
    CAST(COALESCE(RPP.CanDelete, 0) AS BIT) AS CanDelete,
    CAST(COALESCE(RPP.CanView, 0) AS BIT) AS CanView,
    CAST(COALESCE(RPP.CanApprove, 0) AS BIT) AS CanApprove,
    CAST(COALESCE(RPP.CanCancel, 0) AS BIT) AS CanCancel,
    CAST(COALESCE(RPP.CanPrint, 0) AS BIT) AS CanPrint
  INTO #ScreenPermissionMerged
  FROM dbo.Pantallas P
  INNER JOIN dbo.Modulos M ON M.IdModulo = P.IdModulo
  LEFT JOIN ScreenPermissionBase SPB ON SPB.IdPantalla = P.IdPantalla
  LEFT JOIN dbo.RolPantallaPermisos RPP ON RPP.IdRol = @IdRol AND RPP.IdPantalla = P.IdPantalla
  WHERE P.RowStatus = 1 AND P.Activo = 1
    AND M.RowStatus = 1 AND M.Activo = 1;

  SELECT
    M.IdModulo,
    M.Nombre,
    M.Icono,
    CAST(CASE WHEN EXISTS (
      SELECT 1
      FROM #ScreenPermissionMerged SPM
      WHERE SPM.IdModulo = M.IdModulo
        AND SPM.AccessEnabled = 1
    ) THEN 1 ELSE 0 END AS BIT) AS Habilitado
  FROM dbo.Modulos M
  WHERE M.RowStatus = 1 AND M.Activo = 1
  ORDER BY ISNULL(M.Orden, 999), M.Nombre;

  SELECT
    SPM.IdPantalla,
    SPM.IdModulo,
    SPM.Modulo,
    SPM.Pantalla,
    SPM.Ruta,
    SPM.AccessEnabled,
    SPM.CanCreate,
    SPM.CanEdit,
    SPM.CanDelete,
    SPM.CanView,
    SPM.CanApprove,
    SPM.CanCancel,
    SPM.CanPrint
  FROM #ScreenPermissionMerged SPM
  ORDER BY SPM.Modulo, SPM.Pantalla;

  ;WITH Campos AS (
    SELECT CAST('id_registros' AS NVARCHAR(50)) AS ClaveCampo UNION ALL
    SELECT 'precios' UNION ALL
    SELECT 'costos' UNION ALL
    SELECT 'cantidades' UNION ALL
    SELECT 'descuentos' UNION ALL
    SELECT 'impuestos' UNION ALL
    SELECT 'subtotales' UNION ALL
    SELECT 'totales_netos' UNION ALL
    SELECT 'margenes' UNION ALL
    SELECT 'comisiones' UNION ALL
    SELECT 'info_cliente' UNION ALL
    SELECT 'metodos_pago'
  )
  SELECT
    C.ClaveCampo,
    CAST(ISNULL(RCV.Visible, 1) AS BIT) AS Visible
  FROM Campos C
  LEFT JOIN dbo.RolCamposVisibilidad RCV ON RCV.IdRol = @IdRol AND RCV.ClaveCampo = C.ClaveCampo
  ORDER BY C.ClaveCampo;
END;
GO
