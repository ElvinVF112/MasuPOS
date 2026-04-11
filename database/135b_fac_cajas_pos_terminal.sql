-- ============================================================
-- Script 135b: Agrega IdTerminal a FacCajasPOS y actualiza SP
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'FacCajasPOS' AND COLUMN_NAME = 'IdTerminal')
  ALTER TABLE dbo.FacCajasPOS ADD IdTerminal VARCHAR(50) NULL;
GO

-- TipoCierre: U=Usuario, T=Terminal, P=Punto Emision, S=Sucursal
ALTER TABLE dbo.Sucursales DROP CONSTRAINT IF EXISTS CK_Sucursales_TipoCierre;
ALTER TABLE dbo.Sucursales ADD CONSTRAINT CK_Sucursales_TipoCierre CHECK (TipoCierre IN ('U','T','P','S'));
GO

CREATE OR ALTER PROCEDURE dbo.spFacCajasPOSCRUD
  @Accion               NVARCHAR(10)   = 'L',
  @IdCajaPOS            INT            = NULL,
  @Descripcion          NVARCHAR(150)  = NULL,
  @IdSucursal           INT            = NULL,
  @IdPuntoEmision       INT            = NULL,
  @IdMoneda             INT            = NULL,
  @IdTerminal           VARCHAR(50)    = NULL,
  @ManejaFondo          BIT            = NULL,
  @FondoFijo            BIT            = NULL,
  @FondoCaja            DECIMAL(18,2)  = NULL,
  @Activo               BIT            = NULL,
  @UsuarioAccion        INT            = NULL,
  @UsuariosAsignados    NVARCHAR(MAX)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT c.IdCajaPOS, c.Descripcion,
           c.IdSucursal, s.Nombre AS NombreSucursal, s.TipoCierre,
           c.IdPuntoEmision, pe.Nombre AS NombrePuntoEmision,
           c.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           c.IdTerminal,
           c.CajaAbierta, c.FechaApertura, c.FechaCierre,
           c.ManejaFondo, c.FondoFijo, c.FondoCaja,
           c.Activo,
           c.FechaCreacion, c.UsuarioCreacion, c.FechaModificacion, c.UsuarioModificacion
    FROM   dbo.FacCajasPOS c
    JOIN   dbo.Sucursales s ON s.IdSucursal = c.IdSucursal
    LEFT JOIN dbo.PuntosEmision pe ON pe.IdPuntoEmision = c.IdPuntoEmision
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = c.IdMoneda
    WHERE  c.RowStatus = 1
      AND  (@IdSucursal IS NULL OR c.IdSucursal = @IdSucursal)
    ORDER BY s.Nombre, c.Descripcion
    RETURN
  END

  IF @Accion = 'O'
  BEGIN
    SELECT c.IdCajaPOS, c.Descripcion,
           c.IdSucursal, s.Nombre AS NombreSucursal, s.TipoCierre,
           c.IdPuntoEmision, pe.Nombre AS NombrePuntoEmision,
           c.IdMoneda, m.Nombre AS NombreMoneda, m.Simbolo AS SimboloMoneda,
           c.IdTerminal,
           c.CajaAbierta, c.FechaApertura, c.FechaCierre,
           c.ManejaFondo, c.FondoFijo, c.FondoCaja,
           c.Activo,
           c.FechaCreacion, c.UsuarioCreacion, c.FechaModificacion, c.UsuarioModificacion
    FROM   dbo.FacCajasPOS c
    JOIN   dbo.Sucursales s ON s.IdSucursal = c.IdSucursal
    LEFT JOIN dbo.PuntosEmision pe ON pe.IdPuntoEmision = c.IdPuntoEmision
    LEFT JOIN dbo.Monedas m ON m.IdMoneda = c.IdMoneda
    WHERE  c.IdCajaPOS = @IdCajaPOS AND c.RowStatus = 1
    RETURN
  END

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.FacCajasPOS (
      Descripcion, IdSucursal, IdPuntoEmision, IdMoneda, IdTerminal,
      ManejaFondo, FondoFijo, FondoCaja, Activo, UsuarioCreacion
    ) VALUES (
      @Descripcion, @IdSucursal, @IdPuntoEmision, @IdMoneda, @IdTerminal,
      ISNULL(@ManejaFondo, 0), ISNULL(@FondoFijo, 0), ISNULL(@FondoCaja, 0),
      ISNULL(@Activo, 1), @UsuarioAccion
    )
    DECLARE @NewId INT = SCOPE_IDENTITY()
    EXEC dbo.spFacCajasPOSCRUD @Accion = 'O', @IdCajaPOS = @NewId
    RETURN
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.FacCajasPOS
    SET    Descripcion       = ISNULL(@Descripcion, Descripcion),
           IdSucursal        = ISNULL(@IdSucursal, IdSucursal),
           IdPuntoEmision    = @IdPuntoEmision,
           IdMoneda          = @IdMoneda,
           IdTerminal        = @IdTerminal,
           ManejaFondo       = ISNULL(@ManejaFondo, ManejaFondo),
           FondoFijo         = ISNULL(@FondoFijo, FondoFijo),
           FondoCaja         = ISNULL(@FondoCaja, FondoCaja),
           Activo            = ISNULL(@Activo, Activo),
           FechaModificacion = GETDATE(),
           UsuarioModificacion = @UsuarioAccion
    WHERE  IdCajaPOS = @IdCajaPOS AND RowStatus = 1
    EXEC dbo.spFacCajasPOSCRUD @Accion = 'O', @IdCajaPOS = @IdCajaPOS
    RETURN
  END

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.FacCajasPOS SET RowStatus = 0, Activo = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioAccion WHERE IdCajaPOS = @IdCajaPOS
    DELETE FROM dbo.FacCajaPOSUsuario WHERE IdCajaPOS = @IdCajaPOS
    SELECT 'OK' AS Resultado
    RETURN
  END

  IF @Accion = 'LU'
  BEGIN
    SELECT u.IdUsuario, u.NombreUsuario, u.Nombres, u.Correo,
           CASE WHEN cu.IdCajaPOS IS NOT NULL AND cu.Activo = 1 THEN 1 ELSE 0 END AS Asignado
    FROM   dbo.Usuarios u
    LEFT JOIN dbo.FacCajaPOSUsuario cu ON cu.IdUsuario = u.IdUsuario AND cu.IdCajaPOS = @IdCajaPOS
    WHERE  u.RowStatus = 1
    ORDER BY Asignado DESC, u.Nombres
    RETURN
  END

  IF @Accion = 'U'
  BEGIN
    UPDATE dbo.FacCajaPOSUsuario SET Activo = 0 WHERE IdCajaPOS = @IdCajaPOS
    IF @UsuariosAsignados IS NOT NULL AND LEN(@UsuariosAsignados) > 0
    BEGIN
      INSERT INTO dbo.FacCajaPOSUsuario (IdCajaPOS, IdUsuario, UsuarioCreacion)
      SELECT @IdCajaPOS, TRY_CAST(value AS INT), @UsuarioAccion
      FROM STRING_SPLIT(@UsuariosAsignados, ',')
      WHERE TRY_CAST(value AS INT) IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM dbo.FacCajaPOSUsuario WHERE IdCajaPOS = @IdCajaPOS AND IdUsuario = TRY_CAST(value AS INT))

      UPDATE dbo.FacCajaPOSUsuario SET Activo = 1
      WHERE IdCajaPOS = @IdCajaPOS
        AND IdUsuario IN (SELECT TRY_CAST(value AS INT) FROM STRING_SPLIT(@UsuariosAsignados, ',') WHERE TRY_CAST(value AS INT) IS NOT NULL)
    END
    EXEC dbo.spFacCajasPOSCRUD @Accion = 'LU', @IdCajaPOS = @IdCajaPOS
    RETURN
  END
END
GO

PRINT '=== Script 135b completado ==='
GO
