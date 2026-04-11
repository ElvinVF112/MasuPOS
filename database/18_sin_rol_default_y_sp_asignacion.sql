SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
  Crea/asegura rol ficticio SIN ROL (IdRol = 0)
  y ajusta spRolUsuariosAsignar para desasignar a IdRol = 0.
*/

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE IdRol = 0)
BEGIN
  SET IDENTITY_INSERT dbo.Roles ON;

  INSERT INTO dbo.Roles
    (IdRol, Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
  VALUES
    (0, N'SIN ROL', N'Rol de fallback para usuarios desasignados.', 1, 1, GETDATE(), 1);

  SET IDENTITY_INSERT dbo.Roles OFF;
END
ELSE
BEGIN
  UPDATE dbo.Roles
  SET Nombre = N'SIN ROL',
      Descripcion = N'Rol de fallback para usuarios desasignados.',
      Activo = 1,
      RowStatus = 1,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = 1
  WHERE IdRol = 0;
END
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

  IF NOT EXISTS (
    SELECT 1
    FROM dbo.Roles
    WHERE IdRol = 0
      AND RowStatus = 1
      AND Activo = 1
  )
  BEGIN
    RAISERROR('No existe rol SIN ROL (IdRol=0) activo.', 16, 1);
    RETURN;
  END

  UPDATE dbo.Usuarios
  SET IdRol = 0,
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
