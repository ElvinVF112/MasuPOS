-- TAREA 26: Paso 1 - Agregar columna Clave a Permisos y poblar con valores
-- La columna Clave almacena la permission key (ej: config.catalog.price-lists.view)
-- derivada de Pantallas.Ruta usando el mapeo de rutas

-- ══════════════════════════════════════════════════════════════
-- PASO 1: Agregar columna Clave a Permisos
-- ══════════════════════════════════════════════════════════════
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Permisos') AND name = 'Clave')
BEGIN
    ALTER TABLE dbo.Permisos ADD Clave NVARCHAR(100) NULL;
END
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 2: Poblar Clave para permisos existentes
-- Usa Pantallas.Ruta para derivar la clave de permiso
-- ══════════════════════════════════════════════════════════════
-- Actualiza permisos existentes usando el mapeo de rutas conocido
-- Cada permiso apunta a una Pantalla, cuya Ruta determina la Clave

UPDATE P SET P.Clave = CASE PA.Ruta
    -- Seguridad
    WHEN '/config/security/users' THEN 'config.security.users.view'
    WHEN '/config/security/roles' THEN 'config.security.roles.view'
    -- Catalogo
    WHEN '/config/catalog/products' THEN 'config.catalog.products.view'
    WHEN '/config/catalog/categories' THEN 'config.catalog.categories.view'
    WHEN '/config/catalog/product-types' THEN 'config.catalog.product-types.view'
    WHEN '/config/catalog/units' THEN 'config.catalog.units.view'
    WHEN '/config/catalog/price-lists' THEN 'config.catalog.price-lists.view'
    -- Monedas
    WHEN '/config/currencies' THEN 'config.currencies.view'
    WHEN '/config/currencies/rates' THEN 'config.currencies.rates.view'
    WHEN '/config/currencies/history' THEN 'config.currencies.history.view'
    -- Empresa
    WHEN '/config/company' THEN 'config.company.view'
    -- Salon (Dining Room)
    WHEN '/config/dining-room/resources' THEN 'config.dining.resources.view'
    WHEN '/config/dining-room/areas' THEN 'config.dining.areas.view'
    WHEN '/config/dining-room/resource-types' THEN 'config.dining.resource-types.view'
    WHEN '/config/dining-room/resource-categories' THEN 'config.dining.resource-categories.view'
    -- POS
    WHEN '/orders' THEN 'orders.view'
    WHEN '/orders/new' THEN 'orders.view'
    WHEN '/orders/kitchen' THEN 'orders.view'
    WHEN '/dining-room' THEN 'dining-room.view'
    WHEN '/cash-register' THEN 'cash-register.view'
    WHEN '/cash-register/payments' THEN 'cash-register.view'
    -- Root
    WHEN '/' THEN 'dashboard.view'
    WHEN '/queries' THEN 'queries.view'
    WHEN '/reports' THEN 'reports.view'
    WHEN '/reports/inventory' THEN 'reports.view'
    WHEN '/reports/staff' THEN 'reports.view'
    WHEN '/catalog' THEN 'catalog.view'
    WHEN '/security' THEN 'security.view'
    -- Legacy
    WHEN '/usuarios' THEN 'config.security.users.view'
    WHEN '/roles' THEN 'config.security.roles.view'
    WHEN '/permisos' THEN 'security.view'
    ELSE LOWER(LTRIM(RTRIM(PA.Ruta)))
END
FROM dbo.Permisos P
INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
WHERE P.RowStatus = 1 AND P.Clave IS NULL;
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 3: Hacer Clave NOT NULL con valor por defecto para nuevos inserts
-- ══════════════════════════════════════════════════════════════
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Permisos') AND name = 'Clave' AND is_nullable = 1)
BEGIN
    UPDATE P SET P.Clave = LOWER(LTRIM(RTRIM(PA.Ruta)))
    FROM dbo.Permisos P
    INNER JOIN dbo.Pantallas PA ON PA.IdPantalla = P.IdPantalla
    WHERE P.RowStatus = 1 AND P.Clave IS NULL;
END
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 4: Reescribir spPermisosObtenerPorRol para retornar Clave
-- Ya no une con Pantallas ni depende de columnas CRUD
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spPermisosObtenerPorRol', 'P') IS NOT NULL DROP PROCEDURE dbo.spPermisosObtenerPorRol;
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
    LOWER(LTRIM(RTRIM(PE.Clave))) AS Clave
  FROM dbo.RolesPermisos RP
  INNER JOIN dbo.Permisos PE ON PE.IdPermiso = RP.IdPermiso
  WHERE RP.RowStatus = 1
    AND RP.Activo = 1
    AND PE.RowStatus = 1
    AND PE.Activo = 1
    AND NULLIF(LTRIM(RTRIM(PE.Clave)), '') IS NOT NULL
    AND RP.IdRol = @IdRol
  ORDER BY Clave;
END;
GO

-- ══════════════════════════════════════════════════════════════
-- PASO 5: Reescribir spPermisosCRUD para manejar Clave
-- Mantiene la misma logica CRUD pero incluye la columna Clave
-- ══════════════════════════════════════════════════════════════
IF OBJECT_ID('dbo.spPermisosCRUD', 'P') IS NOT NULL DROP PROCEDURE dbo.spPermisosCRUD;
GO
CREATE PROCEDURE dbo.spPermisosCRUD
    @Accion CHAR(1),
    @IdPermiso INT = NULL OUTPUT,
    @IdPantalla INT = NULL,
    @Nombre NVARCHAR(150) = NULL,
    @Descripcion NVARCHAR(250) = NULL,
    @Clave NVARCHAR(100) = NULL,
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
               P.Nombre, P.Descripcion, P.Clave, P.Activo, P.RowStatus, P.FechaCreacion
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
               P.Nombre, P.Descripcion, P.Clave, P.Activo, P.RowStatus, P.FechaCreacion,
               P.UsuarioCreacion, P.FechaModificacion, P.UsuarioModificacion
        FROM dbo.Permisos P
        INNER JOIN dbo.Pantallas PA ON P.IdPantalla = PA.IdPantalla
        INNER JOIN dbo.Modulos M ON PA.IdModulo = M.IdModulo
        WHERE P.IdPermiso = @IdPermiso AND P.RowStatus = 1;
        RETURN;
    END;
    IF @Accion = 'I'
    BEGIN
        DECLARE @GeneratedClave NVARCHAR(100);
        SET @GeneratedClave = LTRIM(RTRIM(ISNULL(@Clave, '')));
        IF @GeneratedClave = '' AND @IdPantalla IS NOT NULL
        BEGIN
            SET @GeneratedClave = LOWER(LTRIM(RTRIM(ISNULL((SELECT Ruta FROM dbo.Pantallas WHERE IdPantalla = @IdPantalla), ''))));
        END
        INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES (@IdPantalla, LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
                NULLIF(@GeneratedClave, ''), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);
        SET @IdPermiso = SCOPE_IDENTITY();
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Clave, P.Activo, P.RowStatus, P.FechaCreacion,
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
            Clave = NULLIF(LTRIM(RTRIM(ISNULL(@Clave, Clave))), ''),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdPermiso = @IdPermiso AND RowStatus = 1;
        SELECT P.IdPermiso, P.IdPantalla, PA.Nombre AS Pantalla, M.Nombre AS Modulo,
               P.Nombre, P.Descripcion, P.Clave, P.Activo, P.RowStatus, P.FechaCreacion,
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
               P.Nombre, P.Descripcion, P.Clave, P.Activo, P.RowStatus, P.FechaCreacion,
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

-- ══════════════════════════════════════════════════════════════
-- PASO 6: Verificar
-- ══════════════════════════════════════════════════════════════
SELECT TOP 10 IdPermiso, Nombre, Clave, IdPantalla FROM dbo.Permisos WHERE RowStatus = 1 ORDER BY IdPermiso;
SELECT 'SPs y Clave poblados correctamente' AS Result;
GO
