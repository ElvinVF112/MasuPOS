-- ============================================================
-- Script 140: DescuentoUsuarios - Asignación de usuarios a descuentos
-- Homologa el patrón de ListaPrecioUsuarios
-- ============================================================

-- 1. Tabla DescuentoUsuarios
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'DescuentoUsuarios' AND type = 'U')
BEGIN
  CREATE TABLE dbo.DescuentoUsuarios (
    Id                   INT IDENTITY(1,1) NOT NULL,
    IdDescuento          INT NOT NULL,
    IdUsuario            INT NOT NULL,
    RowStatus            BIT NOT NULL DEFAULT 1,
    FechaCreacion        DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreacion      INT NULL,
    FechaModificacion    DATETIME NULL,
    UsuarioModificacion  INT NULL,
    CONSTRAINT PK_DescuentoUsuarios PRIMARY KEY (Id),
    CONSTRAINT UQ_DescuentoUsuarios UNIQUE (IdDescuento, IdUsuario, RowStatus),
    CONSTRAINT FK_DescuentoUsuarios_Descuento FOREIGN KEY (IdDescuento) REFERENCES dbo.Descuentos(IdDescuento),
    CONSTRAINT FK_DescuentoUsuarios_Usuario   FOREIGN KEY (IdUsuario)   REFERENCES dbo.Usuarios(IdUsuario)
  )
  PRINT 'Tabla DescuentoUsuarios creada.'
END
ELSE
  PRINT 'Tabla DescuentoUsuarios ya existe.'
GO

-- 2. SP spDescuentoUsuarios
-- Acciones: LA (listar asignados), LD (listar disponibles),
--           A (asignar), Q (quitar), AA (asignar todos), QA (quitar todos)
IF OBJECT_ID('dbo.spDescuentoUsuarios', 'P') IS NOT NULL
  DROP PROCEDURE dbo.spDescuentoUsuarios
GO

CREATE PROCEDURE dbo.spDescuentoUsuarios
  @Accion      NVARCHAR(5),
  @IdDescuento INT         = NULL,
  @IdUsuario   INT         = NULL
AS
BEGIN
  SET NOCOUNT ON

  -- LA: Listar usuarios asignados
  IF @Accion = 'LA'
  BEGIN
    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento
      AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- LD: Listar usuarios disponibles (no asignados)
  IF @Accion = 'LD'
  BEGIN
    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario
          AND DU.IdDescuento = @IdDescuento
          AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- A: Asignar usuario
  IF @Accion = 'A'
  BEGIN
    IF NOT EXISTS (
      SELECT 1 FROM dbo.DescuentoUsuarios
      WHERE IdDescuento = @IdDescuento AND IdUsuario = @IdUsuario AND RowStatus = 1
    )
    BEGIN
      INSERT INTO dbo.DescuentoUsuarios (IdDescuento, IdUsuario, FechaCreacion)
      VALUES (@IdDescuento, @IdUsuario, GETDATE())
    END

    -- Devuelve asignados y disponibles
    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- Q: Quitar usuario
  IF @Accion = 'Q'
  BEGIN
    UPDATE dbo.DescuentoUsuarios
    SET RowStatus = 0, FechaModificacion = GETDATE()
    WHERE IdDescuento = @IdDescuento AND IdUsuario = @IdUsuario AND RowStatus = 1

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- AA: Asignar todos los usuarios disponibles
  IF @Accion = 'AA'
  BEGIN
    INSERT INTO dbo.DescuentoUsuarios (IdDescuento, IdUsuario, FechaCreacion)
    SELECT @IdDescuento, U.IdUsuario, GETDATE()
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END

  -- QA: Quitar todos los usuarios asignados
  IF @Accion = 'QA'
  BEGIN
    UPDATE dbo.DescuentoUsuarios
    SET RowStatus = 0, FechaModificacion = GETDATE()
    WHERE IdDescuento = @IdDescuento AND RowStatus = 1

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    INNER JOIN dbo.DescuentoUsuarios DU ON DU.IdUsuario = U.IdUsuario
      AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
    WHERE U.Activo = 1
    ORDER BY U.Nombres, U.Apellidos

    SELECT U.IdUsuario, U.NombreUsuario, U.Nombres, U.Apellidos
    FROM dbo.Usuarios U
    WHERE U.Activo = 1
      AND NOT EXISTS (
        SELECT 1 FROM dbo.DescuentoUsuarios DU
        WHERE DU.IdUsuario = U.IdUsuario AND DU.IdDescuento = @IdDescuento AND DU.RowStatus = 1
      )
    ORDER BY U.Nombres, U.Apellidos
    RETURN
  END
END
GO

PRINT 'SP spDescuentoUsuarios creado correctamente.'
GO
