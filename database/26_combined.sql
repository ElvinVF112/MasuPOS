-- TAREA 26: Script completo - Drop SPs -> Drop columns -> Recreate SPs
-- Un solo paso atomico que debe funcionar

DBCC FREEPROCCACHE WITH NO_INFOMSGS;
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 1: Drop SPs que referencian Permisos
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spPermisosObtenerPorRol', 'P') IS NOT NULL DROP PROCEDURE dbo.spPermisosObtenerPorRol;
GO
IF OBJECT_ID('dbo.spPermisosCRUD', 'P') IS NOT NULL DROP PROCEDURE dbo.spPermisosCRUD;
GO
IF OBJECT_ID('dbo.spRolesPermisosCRUD', 'P') IS NOT NULL DROP PROCEDURE dbo.spRolesPermisosCRUD;
GO
IF OBJECT_ID('dbo.spRolesPermisosListar', 'P') IS NOT NULL DROP PROCEDURE dbo.spRolesPermisosListar;
GO
IF OBJECT_ID('dbo.spRolesPermisosAsignar', 'P') IS NOT NULL DROP PROCEDURE dbo.spRolesPermisosAsignar;
GO
IF OBJECT_ID('dbo.spRolPermisosActualizar', 'P') IS NOT NULL DROP PROCEDURE dbo.spRolPermisosActualizar;
GO
IF OBJECT_ID('dbo.spRolPermisosPorModulo', 'P') IS NOT NULL DROP PROCEDURE dbo.spRolPermisosPorModulo;
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 2: Drop columnas CRUD (nombres confirmados del sys.columns)
-- ══════════════════════════════════════════════════════════════
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeVer];
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeCrear];
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeEditar];
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeEliminar];
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeAprobar];
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeAnular];
ALTER TABLE Permisos DROP COLUMN IF EXISTS [ueddeImprimir];
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 3: Recrear SPs limpios
-- ══════════════════════════════════════════════════════════════
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
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Activo, P.RowStatus, P.FechaCreacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.RowStatus = 1
        ORDER BY M.Orden, PA.Orden, P.Nombre;
        RETURN;
    END;
    IF @Accion = 'O'
    BEGIN
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Activo, P.RowStatus, P.FechaCreacion,
               P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso AND P.RowStatus = 1;
        RETURN;
    END;
    IF @Accion = 'I'
    BEGIN
        INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdPantalla, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
                ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);
        SET @IdPermiso = SCOPE_IDENTITY();
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Activo, P.RowStatus, P.FechaCreacion,
               P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso;
        RETURN;
    END;
    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.Permisos
        SET IdPantalla = @IdPantalla, Nombre = LTRIM(RTRIM(@Nombre)),
            Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPermiso = @IdPermiso AND RowStatus = 1;
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Activo, P.RowStatus, P.FechaCreacion,
               P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso AND P.RowStatus = 1;
        RETURN;
    END;
    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.Permisos
        SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
        WHERE IdPermiso = @IdPermiso AND RowStatus = 1;
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Activo, P.RowStatus, P.FechaCreacion,
               P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso;
        RETURN;
    END;
    RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
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
        SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
               P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
               RP.Activo, RP.RowStatus, RP.FechaCreacion
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
        SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
               P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
               RP.Activo, RP.RowStatus, RP.FechaCreacion,
               RP.UsuarioCreacion, RP.FechaModificacion, RP.UsuarioModificacion
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
        IF EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso AND RowStatus = 1)
        BEGIN RAISERROR('El rol ya tiene este permiso asignado.', 16, 1); RETURN; END;
        INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdRol, @IdPermiso, ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);
        SET @IdRolPermiso = SCOPE_IDENTITY();
        SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
               P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
               RP.Activo, RP.RowStatus, RP.FechaCreacion,
               RP.UsuarioCreacion, RP.FechaModificacion, RP.UsuarioModificacion
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
        SET IdRol = @IdRol, IdPermiso = @IdPermiso,
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso AND RowStatus = 1;
        SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
               P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
               RP.Activo, RP.RowStatus, RP.FechaCreacion,
               RP.UsuarioCreacion, RP.FechaModificacion, RP.UsuarioModificacion
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
        SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
        WHERE IdRolPermiso = @IdRolPermiso AND RowStatus = 1;
        SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
               P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
               RP.Activo, RP.RowStatus, RP.FechaCreacion,
               RP.UsuarioCreacion, RP.FechaModificacion, RP.UsuarioModificacion
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

CREATE PROCEDURE dbo.spRolesPermisosListar
    @IdRol INT = NULL,
    @IdPermiso INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
           P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
           RP.Activo, RP.RowStatus, RP.FechaCreacion
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

CREATE PROCEDURE dbo.spRolesPermisosAsignar
    @IdRol INT, @IdPermiso INT, @Activo BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    IF ISNULL(@IdRol, 0) = 0 BEGIN RAISERROR('Debe enviar @IdRol.', 16, 1); RETURN; END;
    IF ISNULL(@IdPermiso, 0) = 0 BEGIN RAISERROR('Debe enviar @IdPermiso.', 16, 1); RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE IdRol = @IdRol)
    BEGIN RAISERROR('El rol indicado no existe.', 16, 1); RETURN; END;
    IF NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPermiso = @IdPermiso)
    BEGIN RAISERROR('El permiso indicado no existe.', 16, 1); RETURN; END;
    IF EXISTS (SELECT 1 FROM dbo.RolesPermisos WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso)
    BEGIN
        UPDATE dbo.RolesPermisos SET Activo = ISNULL(@Activo, 1)
        WHERE IdRol = @IdRol AND IdPermiso = @IdPermiso;
        SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
               P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
               RP.Activo, RP.FechaCreacion
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
    SELECT RP.IdRolPermiso, RP.IdRol, R.Nombre AS Rol, RP.IdPermiso,
           P.Nombre AS Permiso, M.Nombre AS Modulo, PA.Nombre AS Pantalla,
           RP.Activo, RP.FechaCreacion
    FROM dbo.RolesPermisos RP
    INNER JOIN dbo.Roles R ON R.IdRol = RP.IdRol
    INNER JOIN dbo.Permisos P ON P.IdPermiso = RP.IdPermiso
    INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
    INNER JOIN dbo.Modulos M ON M.IdModulo = PA.IdModulo
    WHERE RP.IdRolPermiso = SCOPE_IDENTITY();
END;
GO

CREATE PROCEDURE dbo.spRolPermisosPorModulo @IdRol INT
AS
BEGIN
  SET NOCOUNT ON;
  IF @IdRol IS NULL OR @IdRol <= 0
  BEGIN RAISERROR('Debe enviar @IdRol valido.', 16, 1); RETURN; END;
  IF OBJECT_ID('tempdb..#SPM') IS NOT NULL DROP TABLE #SPM;
  ;WITH SPB AS (
      SELECT P.IdPantalla,
             MAX(CASE WHEN RP.IdRolPermiso IS NOT NULL AND RP.Activo = 1 AND RP.RowStatus = 1 THEN 1 ELSE 0 END) AS AccessByRolePerm
      FROM dbo.Pantallas P
      LEFT JOIN dbo.Permisos PE ON PE.IdPantalla = P.IdPantalla AND PE.RowStatus = 1 AND PE.Activo = 1
      LEFT JOIN dbo.RolesPermisos RP ON RP.IdPermiso = PE.IdPermiso AND RP.IdRol = @IdRol
      WHERE P.RowStatus = 1 AND P.Activo = 1
      GROUP BY P.IdPantalla
  )
  SELECT P.IdPantalla, P.IdModulo, M.Nombre AS Modulo, P.Nombre AS Pantalla, P.Ruta,
    CAST(CASE WHEN RPP.Id IS NOT NULL THEN ISNULL(RPP.AccessEnabled, 0) ELSE ISNULL(SPB.AccessByRolePerm, 0) END AS BIT) AS AccessEnabled,
    CAST(COALESCE(RPP.CanCreate, 0) AS BIT) AS CanCreate,
    CAST(COALESCE(RPP.CanEdit, 0) AS BIT) AS CanEdit,
    CAST(COALESCE(RPP.CanDelete, 0) AS BIT) AS CanDelete,
    CAST(COALESCE(RPP.CanView, 0) AS BIT) AS CanView,
    CAST(COALESCE(RPP.CanApprove, 0) AS BIT) AS CanApprove,
    CAST(COALESCE(RPP.CanCancel, 0) AS BIT) AS CanCancel,
    CAST(COALESCE(RPP.CanPrint, 0) AS BIT) AS CanPrint
  INTO #SPM
  FROM dbo.Pantallas P
  INNER JOIN dbo.Modulos M ON M.IdModulo = P.IdModulo
  LEFT JOIN SPB ON SPB.IdPantalla = P.IdPantalla
  LEFT JOIN dbo.RolPantallaPermisos RPP ON RPP.IdRol = @IdRol AND RPP.IdPantalla = P.IdPantalla
  WHERE P.RowStatus = 1 AND P.Activo = 1 AND M.RowStatus = 1 AND M.Activo = 1;
  SELECT M.IdModulo, M.Nombre, M.Icono,
    CAST(CASE WHEN EXISTS (SELECT 1 FROM #SPM WHERE IdModulo = M.IdModulo AND AccessEnabled = 1) THEN 1 ELSE 0 END AS BIT) AS Habilitado
  FROM dbo.Modulos M WHERE M.RowStatus = 1 AND M.Activo = 1
  ORDER BY ISNULL(M.Orden, 999), M.Nombre;
  SELECT IdPantalla, IdModulo, Modulo, Pantalla, Ruta, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint
  FROM #SPM ORDER BY Modulo, Pantalla;
  SELECT C.ClaveCampo, CAST(ISNULL(RCV.Visible, 1) AS BIT) AS Visible
  FROM (VALUES
    ('id_registros'),('precios'),('costos'),('cantidades'),('descuentos'),
    ('impuestos'),('subtotales'),('totales_netos'),('margenes'),
    ('comisiones'),('info_cliente'),('metodos_pago')
  ) C(ClaveCampo)
  LEFT JOIN dbo.RolCamposVisibilidad RCV ON RCV.IdRol = @IdRol AND RCV.ClaveCampo = C.ClaveCampo
  ORDER BY C.ClaveCampo;
END;
GO

CREATE PROCEDURE dbo.spRolPermisosActualizar
  @IdRol INT, @Tipo NVARCHAR(30), @IdObjeto INT = NULL,
  @ClaveCampo NVARCHAR(50) = NULL, @Valor BIT, @CampoPermiso NVARCHAR(50) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  IF @IdRol IS NULL OR @IdRol <= 0 BEGIN RAISERROR('Debe enviar @IdRol valido.', 16, 1); RETURN; END;
  DECLARE @TipoNorm NVARCHAR(30) = UPPER(LTRIM(RTRIM(ISNULL(@Tipo, ''))));
  IF @TipoNorm = 'MODULO'
  BEGIN
    IF @IdObjeto IS NULL OR @IdObjeto <= 0 BEGIN RAISERROR('Debe enviar @IdObjeto (IdModulo) valido.', 16, 1); RETURN; END;
    MERGE dbo.RolPantallaPermisos AS T
    USING (SELECT P.IdPantalla FROM dbo.Pantallas P WHERE P.IdModulo = @IdObjeto AND P.RowStatus = 1) AS S
    ON (T.IdRol = @IdRol AND T.IdPantalla = S.IdPantalla)
    WHEN MATCHED THEN UPDATE SET AccessEnabled = @Valor, CanCreate = @Valor, CanEdit = @Valor, CanDelete = @Valor,
      CanView = @Valor, CanApprove = @Valor, CanCancel = @Valor, CanPrint = @Valor
    WHEN NOT MATCHED THEN INSERT (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
      VALUES (@IdRol, S.IdPantalla, @Valor, @Valor, @Valor, @Valor, @Valor, @Valor, @Valor, @Valor);
    IF @Valor = 1
    BEGIN
      INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
      SELECT @IdRol, PE.IdPermiso, 1, 1, GETDATE(), 1
      FROM dbo.Permisos PE INNER JOIN dbo.Pantallas P ON P.IdPantalla = PE.IdPantalla
      WHERE P.IdModulo = @IdObjeto AND PE.RowStatus = 1 AND PE.Activo = 1
        AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos RP WHERE RP.IdRol = @IdRol AND RP.IdPermiso = PE.IdPermiso AND RP.RowStatus = 1);
      UPDATE RP SET RP.Activo = 1, RP.FechaModificacion = GETDATE(), RP.UsuarioModificacion = 1
      FROM dbo.RolesPermisos RP
      INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
      INNER JOIN dbo.Pantallas P ON P.IdPantalla = PE.IdPantalla
      WHERE RP.IdRol = @IdRol AND P.IdModulo = @IdObjeto AND RP.RowStatus = 1;
    END ELSE
    BEGIN
      UPDATE RP SET RP.Activo = 0, RP.FechaModificacion = GETDATE(), RP.UsuarioModificacion = 1
      FROM dbo.RolesPermisos RP
      INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
      INNER JOIN dbo.Pantallas P ON P.IdPantalla = PE.IdPantalla
      WHERE RP.IdRol = @IdRol AND P.IdModulo = @IdObjeto AND RP.RowStatus = 1;
    END;
    RETURN;
  END;
  IF @TipoNorm = 'PANTALLA'
  BEGIN
    IF @IdObjeto IS NULL OR @IdObjeto <= 0 BEGIN RAISERROR('Debe enviar @IdObjeto (IdPantalla) valido.', 16, 1); RETURN; END;
    MERGE dbo.RolPantallaPermisos AS T
    USING (SELECT @IdRol AS IdRol, @IdObjeto AS IdPantalla) AS S
    ON (T.IdRol = S.IdRol AND T.IdPantalla = S.IdPantalla)
    WHEN MATCHED THEN UPDATE SET AccessEnabled = @Valor,
      CanCreate = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanCreate END,
      CanEdit = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanEdit END,
      CanDelete = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanDelete END,
      CanView = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanView END,
      CanApprove = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanApprove END,
      CanCancel = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanCancel END,
      CanPrint = CASE WHEN @Valor = 0 THEN 0 ELSE T.CanPrint END
    WHEN NOT MATCHED THEN INSERT (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
      VALUES (@IdRol, @IdObjeto, @Valor, 0, 0, 0, 0, 0, 0, 0);
    IF @Valor = 1
    BEGIN
      INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
      SELECT @IdRol, PE.IdPermiso, 1, 1, GETDATE(), 1
      FROM dbo.Permisos PE
      WHERE PE.IdPantalla = @IdObjeto AND PE.RowStatus = 1 AND PE.Activo = 1
        AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos RP WHERE RP.IdRol = @IdRol AND RP.IdPermiso = PE.IdPermiso AND RP.RowStatus = 1);
      UPDATE RP SET RP.Activo = 1, RP.FechaModificacion = GETDATE(), RP.UsuarioModificacion = 1
      FROM dbo.RolesPermisos RP
      INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
      WHERE RP.IdRol = @IdRol AND PE.IdPantalla = @IdObjeto AND RP.RowStatus = 1;
    END ELSE
    BEGIN
      UPDATE RP SET RP.Activo = 0, RP.FechaModificacion = GETDATE(), RP.UsuarioModificacion = 1
      FROM dbo.RolesPermisos RP
      INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
      WHERE RP.IdRol = @IdRol AND PE.IdPantalla = @IdObjeto AND RP.RowStatus = 1;
    END;
    RETURN;
  END;
  IF @TipoNorm = 'PERMISO_GRANULAR'
  BEGIN
    IF @IdObjeto IS NULL OR @IdObjeto <= 0 BEGIN RAISERROR('Debe enviar @IdObjeto (IdPantalla) valido.', 16, 1); RETURN; END;
    DECLARE @CampoNorm NVARCHAR(50) = UPPER(LTRIM(RTRIM(ISNULL(@CampoPermiso, ''))));
    IF @CampoNorm = '' BEGIN RAISERROR('Debe enviar @CampoPermiso para tipo PERMISO_GRANULAR.', 16, 1); RETURN; END;
    MERGE dbo.RolPantallaPermisos AS T
    USING (SELECT @IdRol AS IdRol, @IdObjeto AS IdPantalla) AS S
    ON (T.IdRol = S.IdRol AND T.IdPantalla = S.IdPantalla)
    WHEN NOT MATCHED THEN INSERT (IdRol, IdPantalla, AccessEnabled, CanCreate, CanEdit, CanDelete, CanView, CanApprove, CanCancel, CanPrint)
      VALUES (@IdRol, @IdObjeto, 1, 0, 0, 0, 0, 0, 0, 0);
    UPDATE dbo.RolPantallaPermisos SET
      AccessEnabled = 1,
      CanCreate = CASE WHEN @CampoNorm = 'CANCREATE' THEN @Valor ELSE CanCreate END,
      CanEdit = CASE WHEN @CampoNorm = 'CANEDIT' THEN @Valor ELSE CanEdit END,
      CanDelete = CASE WHEN @CampoNorm = 'CANDELETE' THEN @Valor ELSE CanDelete END,
      CanView = CASE WHEN @CampoNorm = 'CANVIEW' THEN @Valor ELSE CanView END,
      CanApprove = CASE WHEN @CampoNorm = 'CANAPPROVE' THEN @Valor ELSE CanApprove END,
      CanCancel = CASE WHEN @CampoNorm = 'CANCANCEL' THEN @Valor ELSE CanCancel END,
      CanPrint = CASE WHEN @CampoNorm = 'CANPRINT' THEN @Valor ELSE CanPrint END
    WHERE IdRol = @IdRol AND IdPantalla = @IdObjeto;
    IF EXISTS (SELECT 1 FROM dbo.RolPantallaPermisos WHERE IdRol = @IdRol AND IdPantalla = @IdObjeto AND AccessEnabled = 1)
    BEGIN
      INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
      SELECT @IdRol, PE.IdPermiso, 1, 1, GETDATE(), 1
      FROM dbo.Permisos PE
      WHERE PE.IdPantalla = @IdObjeto AND PE.RowStatus = 1 AND PE.Activo = 1
        AND NOT EXISTS (SELECT 1 FROM dbo.RolesPermisos RP WHERE RP.IdRol = @IdRol AND RP.IdPermiso = PE.IdPermiso AND RP.RowStatus = 1);
      UPDATE RP SET RP.Activo = 1, RP.FechaModificacion = GETDATE(), RP.UsuarioModificacion = 1
      FROM dbo.RolesPermisos RP
      INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
      WHERE RP.IdRol = @IdRol AND PE.IdPantalla = @IdObjeto AND RP.RowStatus = 1;
    END;
    RETURN;
  END;
  IF @TipoNorm = 'CAMPO'
  BEGIN
    DECLARE @ClaveNorm NVARCHAR(50) = LOWER(LTRIM(RTRIM(ISNULL(@ClaveCampo, ''))));
    IF @ClaveNorm = '' BEGIN RAISERROR('Debe enviar @ClaveCampo para tipo CAMPO.', 16, 1); RETURN; END;
    MERGE dbo.RolCamposVisibilidad AS T
    USING (SELECT @IdRol AS IdRol, @ClaveNorm AS ClaveCampo) AS S
    ON (T.IdRol = S.IdRol AND T.ClaveCampo = S.ClaveCampo)
    WHEN MATCHED THEN UPDATE SET Visible = @Valor
    WHEN NOT MATCHED THEN INSERT (IdRol, ClaveCampo, Visible) VALUES (@IdRol, @ClaveNorm, @Valor);
    RETURN;
  END;
  RAISERROR('Tipo no valido. Use MODULO, PANTALLA, PERMISO_GRANULAR o CAMPO.', 16, 1);
END;
GO

PRINT 'TAREA 26 completado: columnas eliminadas y SPs recreados.';
