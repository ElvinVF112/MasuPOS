SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE dbo.spRolUsuariosAsignar
  @IdRol INT,
  @IdUsuario INT,
  @Accion CHAR(1)
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion NOT IN ('A', 'Q')
  BEGIN
    RAISERROR('Accion invalida. Use A o Q.', 16, 1);
    RETURN;
  END

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.Usuarios
    WHERE IdUsuario = @IdUsuario
      AND RowStatus = 1
  )
  BEGIN
    RAISERROR('Usuario no encontrado.', 16, 1);
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Usuarios
    SET IdRol = @IdRol,
        FechaModificacion = GETDATE()
    WHERE IdUsuario = @IdUsuario
      AND RowStatus = 1;

    RETURN;
  END

  DECLARE @IdRolDestino INT;

  IF @IdRol <> 1
  BEGIN
    IF EXISTS (
      SELECT 1
      FROM dbo.Roles
      WHERE IdRol = 1
        AND RowStatus = 1
        AND Activo = 1
    )
    BEGIN
      SET @IdRolDestino = 1;
    END
  END

  IF @IdRolDestino IS NULL
  BEGIN
    SELECT TOP (1) @IdRolDestino = R.IdRol
    FROM dbo.Roles R
    WHERE R.RowStatus = 1
      AND R.Activo = 1
      AND R.IdRol <> @IdRol
    ORDER BY CASE WHEN R.IdRol = 1 THEN 0 ELSE 1 END, R.IdRol;
  END

  IF @IdRolDestino IS NULL
  BEGIN
    RAISERROR('No existe un rol alternativo activo para reasignar usuario.', 16, 1);
    RETURN;
  END

  UPDATE dbo.Usuarios
  SET IdRol = @IdRolDestino,
      FechaModificacion = GETDATE()
  WHERE IdUsuario = @IdUsuario
    AND RowStatus = 1
    AND IdRol = @IdRol;

  IF @@ROWCOUNT = 0
  BEGIN
    RAISERROR('El usuario no pertenece al rol indicado.', 16, 1);
    RETURN;
  END
END
GO
