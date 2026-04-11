-- TAREA 31 — Actualizar spUnidadesMedidaCRUD para retornar fila en I y A
-- Ejecutar en DbMasuPOS antes de usar el nuevo CRUD de Unidades de Medida

-- Verificar estructura actual
-- SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.spUnidadesMedidaCRUD'))

CREATE OR ALTER PROCEDURE dbo.spUnidadesMedidaCRUD
    @Accion         CHAR(2),
    @IdUnidadMedida INT               = NULL,
    @Nombre         NVARCHAR(100)     = NULL,
    @Abreviatura    NVARCHAR(20)      = NULL,
    @BaseA          INT               = NULL,
    @BaseB          INT               = NULL,
    @Activo         BIT               = NULL,
    @IdSesion       INT               = NULL,
    @TokenSesion    NVARCHAR(128)     = NULL,
    @UsuarioCreacion      INT         = NULL,
    @UsuarioModificacion  INT         = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- L: Listar todas las unidades activas (RowStatus = 1)
    IF @Accion = 'L'
    BEGIN
        SELECT UM.IdUnidadMedida,
               UM.Nombre,
               UM.Abreviatura,
               ISNULL(UM.BaseA, 1)         AS BaseA,
               ISNULL(UM.BaseB, 1)         AS BaseB,
               CASE WHEN ISNULL(UM.BaseB, 1) = 0 THEN NULL
                    ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,4)) / ISNULL(UM.BaseB, 1)
               END                         AS UnidadesCalculadas,
               UM.Activo
        FROM dbo.UnidadesMedida UM
        WHERE ISNULL(UM.RowStatus, 1) = 1
        ORDER BY UM.Nombre;
        RETURN;
    END;

    -- O: Obtener una unidad por ID
    IF @Accion = 'O'
    BEGIN
        SELECT UM.IdUnidadMedida,
               UM.Nombre,
               UM.Abreviatura,
               ISNULL(UM.BaseA, 1)         AS BaseA,
               ISNULL(UM.BaseB, 1)         AS BaseB,
               CASE WHEN ISNULL(UM.BaseB, 1) = 0 THEN NULL
                    ELSE CAST(ISNULL(UM.BaseA, 1) AS DECIMAL(18,4)) / ISNULL(UM.BaseB, 1)
               END                         AS UnidadesCalculadas,
               UM.Activo
        FROM dbo.UnidadesMedida UM
        WHERE UM.IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    -- I: Insertar nueva unidad
    IF @Accion = 'I'
    BEGIN
        -- Validar nombre unico
        IF EXISTS (SELECT 1 FROM dbo.UnidadesMedida WHERE Nombre = LTRIM(RTRIM(@Nombre)) AND ISNULL(RowStatus,1)=1)
        BEGIN
            RAISERROR('Ya existe una unidad de medida con ese nombre.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.UnidadesMedida
            (Nombre, Abreviatura, BaseA, BaseB, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        VALUES
            (LTRIM(RTRIM(@Nombre)), LTRIM(RTRIM(@Abreviatura)),
             ISNULL(@BaseA, 1), ISNULL(@BaseB, 1),
             ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);

        DECLARE @NuevoId INT = SCOPE_IDENTITY();
        EXEC dbo.spUnidadesMedidaCRUD @Accion = 'O', @IdUnidadMedida = @NuevoId;
        RETURN;
    END;

    -- A: Actualizar unidad existente
    IF @Accion = 'A'
    BEGIN
        UPDATE dbo.UnidadesMedida
        SET Nombre               = LTRIM(RTRIM(@Nombre)),
            Abreviatura          = LTRIM(RTRIM(@Abreviatura)),
            BaseA                = ISNULL(@BaseA, BaseA),
            BaseB                = ISNULL(@BaseB, BaseB),
            Activo               = ISNULL(@Activo, Activo),
            FechaModificacion    = GETDATE(),
            UsuarioModificacion  = @UsuarioModificacion
        WHERE IdUnidadMedida = @IdUnidadMedida
          AND ISNULL(RowStatus, 1) = 1;

        EXEC dbo.spUnidadesMedidaCRUD @Accion = 'O', @IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    -- D: Eliminar (soft-delete)
    IF @Accion = 'D'
    BEGIN
        UPDATE dbo.UnidadesMedida
        SET RowStatus           = 0,
            FechaModificacion   = GETDATE(),
            UsuarioModificacion = @UsuarioModificacion
        WHERE IdUnidadMedida = @IdUnidadMedida;
        RETURN;
    END;

    RAISERROR('Accion no valida. Use L, O, I, A o D.', 16, 1);
END;
GO
