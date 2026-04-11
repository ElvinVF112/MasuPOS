-- ============================================================
-- SCRIPT 35: Puntos de Emision - Lista de Precio Predeterminada
-- Agrega IdListaPrecioPredeterminada FK a ListasPrecios
-- Actualiza spPuntosEmisionCRUD (L/O/I/A incluyen la nueva col)
-- ============================================================

-- ── Columna ──────────────────────────────────────────────────
IF NOT EXISTS (
  SELECT 1 FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.PuntosEmision')
    AND name = 'IdListaPrecioPredeterminada'
)
BEGIN
  ALTER TABLE dbo.PuntosEmision
    ADD IdListaPrecioPredeterminada INT NULL;

  ALTER TABLE dbo.PuntosEmision
    ADD CONSTRAINT FK_PuntosEmision_ListaPrecios
    FOREIGN KEY (IdListaPrecioPredeterminada)
    REFERENCES dbo.ListasPrecios(IdListaPrecio);
END
GO

-- ── SP actualizado ────────────────────────────────────────────
ALTER PROCEDURE dbo.spPuntosEmisionCRUD
    @Accion                     CHAR(1),
    @IdPuntoEmision             INT           = NULL,
    @IdSucursal                 INT           = NULL,
    @Nombre                     NVARCHAR(100) = NULL,
    @Codigo                     NVARCHAR(20)  = NULL,
    @IdListaPrecioPredeterminada INT          = NULL,
    @Activo                     BIT           = NULL,
    @UsuarioCreacion            INT           = NULL,
    @UsuarioModificacion        INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT PE.IdPuntoEmision, PE.IdSucursal, S.Nombre AS NombreSucursal,
               S.IdDivision, D.Nombre AS NombreDivision,
               PE.Nombre, ISNULL(PE.Codigo,'') AS Codigo,
               PE.IdListaPrecioPredeterminada,
               LP.Descripcion AS NombreListaPrecio,
               PE.Activo
        FROM dbo.PuntosEmision PE
        INNER JOIN dbo.Sucursales S ON S.IdSucursal = PE.IdSucursal AND ISNULL(S.RowStatus,1) = 1
        INNER JOIN dbo.Divisiones D ON D.IdDivision = S.IdDivision AND ISNULL(D.RowStatus,1) = 1
        LEFT  JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PE.IdListaPrecioPredeterminada
        WHERE ISNULL(PE.RowStatus,1) = 1
          AND (@IdSucursal IS NULL OR PE.IdSucursal = @IdSucursal)
        ORDER BY D.Nombre, S.Nombre, PE.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT PE.IdPuntoEmision, PE.IdSucursal, S.Nombre AS NombreSucursal,
               S.IdDivision, D.Nombre AS NombreDivision,
               PE.Nombre, ISNULL(PE.Codigo,'') AS Codigo,
               PE.IdListaPrecioPredeterminada,
               LP.Descripcion AS NombreListaPrecio,
               PE.Activo
        FROM dbo.PuntosEmision PE
        INNER JOIN dbo.Sucursales S ON S.IdSucursal = PE.IdSucursal
        INNER JOIN dbo.Divisiones D ON D.IdDivision = S.IdDivision
        LEFT  JOIN dbo.ListasPrecios LP ON LP.IdListaPrecio = PE.IdListaPrecioPredeterminada
        WHERE PE.IdPuntoEmision = @IdPuntoEmision;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.Sucursales WHERE IdSucursal = @IdSucursal AND ISNULL(RowStatus,1) = 1)
        BEGIN
            RAISERROR('La sucursal no existe o esta inactiva.', 16, 1);
            RETURN;
        END;
        INSERT INTO dbo.PuntosEmision
            (IdSucursal, Nombre, Codigo, IdListaPrecioPredeterminada, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (@IdSucursal, LTRIM(RTRIM(@Nombre)), LTRIM(RTRIM(ISNULL(@Codigo,''))),
             @IdListaPrecioPredeterminada, ISNULL(@Activo,1), 1, GETDATE(), @UsuarioCreacion);
        DECLARE @NuevoIdP INT = SCOPE_IDENTITY();
        EXEC dbo.spPuntosEmisionCRUD @Accion = 'O', @IdPuntoEmision = @NuevoIdP;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.PuntosEmision
        SET IdSucursal                  = ISNULL(@IdSucursal, IdSucursal),
            Nombre                      = LTRIM(RTRIM(@Nombre)),
            Codigo                      = LTRIM(RTRIM(ISNULL(@Codigo,''))),
            IdListaPrecioPredeterminada = @IdListaPrecioPredeterminada,
            Activo                      = ISNULL(@Activo, Activo),
            FechaModificacion           = GETDATE(),
            UsuarioModificacion         = @UsuarioModificacion
        WHERE IdPuntoEmision = @IdPuntoEmision AND ISNULL(RowStatus,1) = 1;
        EXEC dbo.spPuntosEmisionCRUD @Accion = 'O', @IdPuntoEmision = @IdPuntoEmision;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.PuntosEmision
        SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
        WHERE IdPuntoEmision = @IdPuntoEmision;
        RETURN;
    END;

    RAISERROR('Accion no valida.', 16, 1);
END;
GO

PRINT 'Script 35 completado.'
GO
