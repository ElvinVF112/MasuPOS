SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.spUsuarioActividad
  @IdUsuario INT,
  @TopN INT = 10
AS
BEGIN
  SET NOCOUNT ON;

  IF @IdUsuario IS NULL OR @IdUsuario <= 0
  BEGIN
    RAISERROR('Debe enviar @IdUsuario valido.', 16, 1);
    RETURN;
  END;

  IF @TopN IS NULL OR @TopN <= 0
    SET @TopN = 10;

  SELECT
    U.IdUsuario,
    U.FechaCreacion AS FechaCreacionCuenta,
    U.FechaModificacion AS FechaModificacionCuenta,
    (
      SELECT COUNT(1)
      FROM dbo.SesionesActivas S
      WHERE S.IdUsuario = U.IdUsuario
    ) AS TotalSesiones,
    (
      SELECT MAX(S.FechaInicio)
      FROM dbo.SesionesActivas S
      WHERE S.IdUsuario = U.IdUsuario
    ) AS UltimoLogin
  FROM dbo.Usuarios U
  WHERE U.IdUsuario = @IdUsuario
    AND U.RowStatus = 1;

  SELECT TOP (@TopN)
    S.IdSesion,
    S.Canal,
    S.IpAddress,
    S.SesionActiva,
    S.FechaInicio,
    S.FechaUltimaActividad,
    S.FechaCierre,
    CASE
      WHEN S.FechaInicio IS NULL THEN 0
      ELSE DATEDIFF(MINUTE, S.FechaInicio, ISNULL(S.FechaCierre, ISNULL(S.FechaUltimaActividad, SYSDATETIME())))
    END AS DuracionMinutos
  FROM dbo.SesionesActivas S
  WHERE S.IdUsuario = @IdUsuario
  ORDER BY S.FechaInicio DESC, S.IdSesion DESC;
END;
GO
