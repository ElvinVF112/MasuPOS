IF COL_LENGTH('dbo.UnidadesMedida', 'BaseA') IS NULL
BEGIN
  ALTER TABLE dbo.UnidadesMedida ADD BaseA INT NOT NULL CONSTRAINT DF_UnidadesMedida_BaseA DEFAULT (1);
END;

IF COL_LENGTH('dbo.UnidadesMedida', 'BaseB') IS NULL
BEGIN
  ALTER TABLE dbo.UnidadesMedida ADD BaseB INT NOT NULL CONSTRAINT DF_UnidadesMedida_BaseB DEFAULT (1);
END;
GO

CREATE OR ALTER PROCEDURE dbo.spUnidadesMedidaCRUD
    @Accion CHAR(2),
    @IdUnidadMedida INT = NULL,
    @Nombre NVARCHAR(100) = NULL,
    @Abreviatura NVARCHAR(20) = NULL,
    @BaseA INT = NULL,
    @BaseB INT = NULL,
    @Activo BIT = NULL,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL,
    @UsuarioCreacion INT = NULL,
    @UsuarioModificacion INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'L'
    BEGIN
        SELECT
            UM.IdUnidadMedida,
            UM.Nombre,
            UM.Abreviatura,
            ISNULL(UM.BaseA, 1) AS BaseA,
            ISNULL(UM.BaseB, 1) AS BaseB,
            CASE WHEN ISNULL(UM.BaseB, 1) = 0 THEN NULL
                 ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,4)) / ISNULL(UM.BaseB, 1)
            END AS UnidadesCalculadas,
            ISNULL(UM.Activo, 1) AS Activo
        FROM dbo.UnidadesMedida UM
        WHERE ISNULL(UM.RowStatus, 1) = 1
        ORDER BY UM.Nombre;
        RETURN;
    END;

    IF @Accion = 'O'
    BEGIN
        SELECT
            UM.IdUnidadMedida,
            UM.Nombre,
            UM.Abreviatura,
            ISNULL(UM.BaseA, 1) AS BaseA,
            ISNULL(UM.BaseB, 1) AS BaseB,
            CASE WHEN ISNULL(UM.BaseB, 1) = 0 THEN NULL
                 ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,4)) / ISNULL(UM.BaseB, 1)
            END AS UnidadesCalculadas,
            ISNULL(UM.Activo, 1) AS Activo
        FROM dbo.UnidadesMedida UM
        WHERE UM.IdUnidadMedida = @IdUnidadMedida
          AND ISNULL(UM.RowStatus, 1) = 1;
        RETURN;
    END;

    IF @Accion = 'I'
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dbo.UnidadesMedida
            WHERE Nombre = LTRIM(RTRIM(@Nombre))
              AND ISNULL(RowStatus, 1) = 1
        )
        BEGIN
            RAISERROR('Ya existe una unidad de medida con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.UnidadesMedida (
            Nombre,
            Abreviatura,
            BaseA,
            BaseB,
            Activo,
            FechaCreacion,
            UsuarioCreacion,
            RowStatus
        )
        VALUES (
            LTRIM(RTRIM(@Nombre)),
            LTRIM(RTRIM(@Abreviatura)),
            ISNULL(@BaseA, 1),
            ISNULL(@BaseB, 1),
            ISNULL(@Activo, 1),
            GETDATE(),
            @UsuarioCreacion,
            1
        );

        DECLARE @NuevoId INT = SCOPE_IDENTITY();
        EXEC dbo.spUnidadesMedidaCRUD @Accion = 'O', @IdUnidadMedida = @NuevoId;
        RETURN;
    END;

    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.UnidadesMedida
        SET Nombre = LTRIM(RTRIM(@Nombre)),
            Abreviatura = LTRIM(RTRIM(@Abreviatura)),
            BaseA = ISNULL(@BaseA, BaseA),
            BaseB = ISNULL(@BaseB, BaseB),
            Activo = ISNULL(@Activo, Activo),
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUnidadMedida = @IdUnidadMedida
          AND ISNULL(RowStatus, 1) = 1;

        EXEC dbo.spUnidadesMedidaCRUD @Accion = 'O', @IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.UnidadesMedida
        SET RowStatus = 0,
            FechaModificacion = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, I, A o D.', 16, 1);
END;
GO
