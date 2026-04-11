SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spPermisosObtenerPorRol
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
