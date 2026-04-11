USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

DECLARE @IdModuloInventario INT = (
  SELECT TOP 1 IdModulo
  FROM dbo.Modulos
  WHERE RowStatus = 1
    AND Activo = 1
    AND LOWER(LTRIM(RTRIM(Nombre))) = 'inventario'
);

IF NOT EXISTS (
  SELECT 1
  FROM dbo.Pantallas
  WHERE RowStatus = 1
    AND LOWER(LTRIM(RTRIM(Ruta))) = '/inventory/transfers'
)
BEGIN
  INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Icono, Orden, Activo, FechaCreacion, RowStatus, UsuarioCreacion)
  VALUES (@IdModuloInventario, N'Transferencias', N'/inventory/transfers', N'ArrowLeftRight', 4, 1, GETDATE(), 1, 1);
END
GO

IF OBJECT_ID('tempdb..#TransferPerms') IS NOT NULL DROP TABLE #TransferPerms;
CREATE TABLE #TransferPerms (
  Clave NVARCHAR(100) NOT NULL,
  Nombre NVARCHAR(120) NOT NULL,
  Descripcion NVARCHAR(250) NOT NULL
);

INSERT INTO #TransferPerms (Clave, Nombre, Descripcion)
VALUES
  (N'inventory.transfers.view', N'Transferencias', N'Ver listado y detalle de transferencias'),
  (N'inventory.transfers.edit', N'Editar transferencias', N'Crear y editar transferencias en borrador'),
  (N'inventory.transfers.void', N'Anular transferencias', N'Anular transferencias en borrador o en transito'),
  (N'inventory.transfers.print', N'Imprimir transferencias', N'Imprimir transferencias'),
  (N'inventory.transfers.generate-exit', N'Generar salida transferencia', N'Ejecutar el paso Generar Salida'),
  (N'inventory.transfers.confirm-reception', N'Confirmar recepcion transferencia', N'Ejecutar el paso Confirmar Recepcion');

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
FROM #TransferPerms T
INNER JOIN dbo.Pantallas P
  ON P.RowStatus = 1
 AND LOWER(LTRIM(RTRIM(P.Ruta))) = '/inventory/transfers'
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
    'inventory.transfers.view',
    'inventory.transfers.edit',
    'inventory.transfers.void',
    'inventory.transfers.print',
    'inventory.transfers.generate-exit',
    'inventory.transfers.confirm-reception'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = 1
      AND RP.IdPermiso = P.IdPermiso
      AND RP.RowStatus = 1
  );
GO

PRINT '64_inv_transferencias_permisos.sql ejecutado correctamente.';
GO
