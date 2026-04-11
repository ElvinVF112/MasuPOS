USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

PRINT '=== Script 83: permisos base del modulo de ordenes ===';
GO

IF NOT EXISTS (
  SELECT 1
  FROM dbo.Pantallas
  WHERE RowStatus = 1
    AND LOWER(LTRIM(RTRIM(Ruta))) = '/orders'
)
BEGIN
  DECLARE @IdModuloPedidos INT = (
    SELECT TOP 1 IdModulo
    FROM dbo.Modulos
    WHERE RowStatus = 1
      AND Activo = 1
      AND LOWER(LTRIM(RTRIM(Nombre))) IN ('pedidos', 'ordenes', 'orders')
  );

  IF @IdModuloPedidos IS NULL
  BEGIN
    SELECT TOP 1 @IdModuloPedidos = IdModulo
    FROM dbo.Modulos
    WHERE RowStatus = 1
      AND Activo = 1
    ORDER BY IdModulo;
  END

  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  VALUES (@IdModuloPedidos, N'Gestion de Pedidos', N'/orders', N'Receipt', 1, 1, GETDATE(), 1, 1);
END
GO

IF OBJECT_ID('tempdb..#OrderPerms') IS NOT NULL DROP TABLE #OrderPerms;
CREATE TABLE #OrderPerms (
  Clave NVARCHAR(100) NOT NULL,
  Nombre NVARCHAR(120) NOT NULL,
  Descripcion NVARCHAR(250) NOT NULL
);

INSERT INTO #OrderPerms (Clave, Nombre, Descripcion)
VALUES
  (N'orders.view', N'Ver pedidos', N'Ver listado y detalle del modulo de pedidos'),
  (N'orders.create', N'Crear pedidos', N'Crear nuevas ordenes'),
  (N'orders.edit', N'Editar pedidos', N'Editar cabecera y detalle de ordenes abiertas'),
  (N'orders.cancel', N'Anular pedidos', N'Anular ordenes'),
  (N'orders.close', N'Cerrar pedidos', N'Cerrar ordenes'),
  (N'orders.reopen', N'Reabrir pedidos', N'Reabrir ordenes cerradas o anuladas'),
  (N'orders.history.view', N'Ver historial pedidos', N'Consultar historial de movimientos de ordenes');

INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Clave, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
SELECT
  P.IdPantalla,
  T.Nombre,
  T.Descripcion,
  T.Clave,
  1,
  1,
  GETDATE(),
  1
FROM #OrderPerms T
INNER JOIN dbo.Pantallas P
  ON P.RowStatus = 1
 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/orders'
WHERE NOT EXISTS (
  SELECT 1
  FROM dbo.Permisos X
  WHERE X.RowStatus = 1
    AND LOWER(LTRIM(RTRIM(X.Clave))) = LOWER(LTRIM(RTRIM(T.Clave)))
);
GO

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
SELECT
  1,
  P.IdPermiso,
  1,
  1,
  GETDATE(),
  1
FROM dbo.Permisos P
WHERE P.RowStatus = 1
  AND P.Activo = 1
  AND P.Clave IN (
    'orders.view',
    'orders.create',
    'orders.edit',
    'orders.cancel',
    'orders.close',
    'orders.reopen',
    'orders.history.view'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = 1
      AND RP.IdPermiso = P.IdPermiso
      AND RP.RowStatus = 1
  );
GO

PRINT '83_orders_permissions.sql ejecutado correctamente.';
GO
