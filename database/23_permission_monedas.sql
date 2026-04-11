SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo)
SELECT M.IdModulo, 'Monedas', '/config/currencies', 'Catalog', 'Currencies', 'Coins', 5, 1
FROM dbo.Modulos M WHERE M.Nombre = 'Configuracion' AND M.Activo = 1
AND NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/currencies');

INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo)
SELECT M.IdModulo, 'Tasas Diarias', '/config/currencies/rates', 'Catalog', 'CurrencyRates', 'TrendingUp', 6, 1
FROM dbo.Modulos M WHERE M.Nombre = 'Configuracion' AND M.Activo = 1
AND NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/currencies/rates');

INSERT INTO dbo.Pantallas (IdModulo, Nombre, Ruta, Controlador, Accion, Icono, Orden, Activo)
SELECT M.IdModulo, 'Historial de Tasas', '/config/currencies/history', 'Catalog', 'CurrencyHistory', 'History', 7, 1
FROM dbo.Modulos M WHERE M.Nombre = 'Configuracion' AND M.Activo = 1
AND NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE Ruta = '/config/currencies/history');
GO

DECLARE @IdPantallaC INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta = '/config/currencies');
DECLARE @IdPantallaR INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta = '/config/currencies/rates');
DECLARE @IdPantallaH INT = (SELECT IdPantalla FROM dbo.Pantallas WHERE Ruta = '/config/currencies/history');

IF @IdPantallaC IS NOT NULL
BEGIN
    INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Activo)
    SELECT @IdPantallaC, 'Ver Monedas', 'Ver pantalla de configuracion de monedas', 1
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla = @IdPantallaC);
END

IF @IdPantallaR IS NOT NULL
BEGIN
    INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Activo)
    SELECT @IdPantallaR, 'Ver Tasas Diarias', 'Ver pantalla de tasas diarias de cambio', 1
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla = @IdPantallaR);
END

IF @IdPantallaH IS NOT NULL
BEGIN
    INSERT INTO dbo.Permisos (IdPantalla, Nombre, Descripcion, Activo)
    SELECT @IdPantallaH, 'Ver Historial de Tasas', 'Ver historial de tasas de cambio', 1
    WHERE NOT EXISTS (SELECT 1 FROM dbo.Permisos WHERE IdPantalla = @IdPantallaH);
END
GO

INSERT INTO dbo.RolesPermisos (IdRol, IdPermiso)
SELECT 1, P.IdPermiso
FROM dbo.Permisos P
INNER JOIN dbo.Pantallas S ON S.IdPantalla = P.IdPantalla
WHERE S.Ruta IN ('/config/currencies', '/config/currencies/rates', '/config/currencies/history')
AND NOT EXISTS (
    SELECT 1 FROM dbo.RolesPermisos RP
    WHERE RP.IdRol = 1 AND RP.IdPermiso = P.IdPermiso
);
GO

SELECT 'Permisos de monedas creados correctamente' AS Result;
GO
