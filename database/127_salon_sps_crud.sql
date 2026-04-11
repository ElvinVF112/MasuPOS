-- ============================================================
-- Script: 127_salon_sps_crud.sql
-- Propósito: Crear/recrear SPs CRUD del módulo Salón con
--            CREATE OR ALTER (compatibles con tablas V2 RowStatus).
--            Consolida versiones de 002/11/92/97/98/100.
-- ============================================================

USE DbMasuPOS;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. spAreasCRUD
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spAreasCRUD
  @Accion              CHAR(1),
  @IdArea              INT           = NULL OUTPUT,
  @Nombre              NVARCHAR(100) = NULL,
  @Descripcion         NVARCHAR(250) = NULL,
  @Orden               INT           = NULL,
  @Activo              BIT           = NULL,
  @UsuarioCreacion     INT           = NULL,
  @UsuarioModificacion INT           = NULL,
  @IdSesion            INT           = NULL,
  @TokenSesion         NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT IdArea, Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion
    FROM dbo.Areas
    WHERE RowStatus = 1
    ORDER BY Orden, Nombre;
    RETURN;
  END;

  IF @Accion = 'O'
  BEGIN
    SELECT IdArea, Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion,
           UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.Areas WHERE IdArea = @IdArea;
    RETURN;
  END;

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.Areas (Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            ISNULL(@Orden, 0), ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);
    SET @IdArea = SCOPE_IDENTITY();
    SELECT IdArea, Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion
    FROM dbo.Areas WHERE IdArea = @IdArea;
    RETURN;
  END;

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Areas
    SET Nombre      = LTRIM(RTRIM(@Nombre)),
        Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
        Orden       = ISNULL(@Orden, Orden),
        Activo      = ISNULL(@Activo, Activo),
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
    WHERE IdArea = @IdArea;
    SELECT IdArea, Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion
    FROM dbo.Areas WHERE IdArea = @IdArea;
    RETURN;
  END;

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Areas
    SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdArea = @IdArea;
    SELECT IdArea, Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion
    FROM dbo.Areas WHERE IdArea = @IdArea;
    RETURN;
  END;

  RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

PRINT 'spAreasCRUD creado/actualizado.';
GO

-- ============================================================
-- 2. spTiposRecursoCRUD
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spTiposRecursoCRUD
  @Accion              CHAR(1),
  @IdTipoRecurso       INT           = NULL OUTPUT,
  @Nombre              NVARCHAR(100) = NULL,
  @Descripcion         NVARCHAR(250) = NULL,
  @Activo              BIT           = NULL,
  @UsuarioCreacion     INT           = NULL,
  @UsuarioModificacion INT           = NULL,
  @IdSesion            INT           = NULL,
  @TokenSesion         NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT IdTipoRecurso, Nombre, Descripcion, Activo, RowStatus, FechaCreacion
    FROM dbo.TiposRecurso WHERE RowStatus = 1 ORDER BY Nombre;
    RETURN;
  END;

  IF @Accion = 'O'
  BEGIN
    SELECT IdTipoRecurso, Nombre, Descripcion, Activo, RowStatus, FechaCreacion,
           UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.TiposRecurso WHERE IdTipoRecurso = @IdTipoRecurso;
    RETURN;
  END;

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.TiposRecurso (Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (LTRIM(RTRIM(@Nombre)), NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
            ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion);
    SET @IdTipoRecurso = SCOPE_IDENTITY();
    SELECT IdTipoRecurso, Nombre, Descripcion, Activo, RowStatus, FechaCreacion
    FROM dbo.TiposRecurso WHERE IdTipoRecurso = @IdTipoRecurso;
    RETURN;
  END;

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.TiposRecurso
    SET Nombre      = LTRIM(RTRIM(@Nombre)),
        Descripcion = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
        Activo      = ISNULL(@Activo, Activo),
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoRecurso = @IdTipoRecurso;
    SELECT IdTipoRecurso, Nombre, Descripcion, Activo, RowStatus, FechaCreacion
    FROM dbo.TiposRecurso WHERE IdTipoRecurso = @IdTipoRecurso;
    RETURN;
  END;

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.TiposRecurso
    SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdTipoRecurso = @IdTipoRecurso;
    SELECT IdTipoRecurso, Nombre, Descripcion, Activo, RowStatus, FechaCreacion
    FROM dbo.TiposRecurso WHERE IdTipoRecurso = @IdTipoRecurso;
    RETURN;
  END;

  RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

PRINT 'spTiposRecursoCRUD creado/actualizado.';
GO

-- ============================================================
-- 3. spCategoriasRecursoCRUD
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spCategoriasRecursoCRUD
  @Accion              CHAR(1),
  @IdCategoriaRecurso  INT           = NULL OUTPUT,
  @IdTipoRecurso       INT           = NULL,
  @IdArea              INT           = NULL,
  @Nombre              NVARCHAR(100) = NULL,
  @Descripcion         NVARCHAR(250) = NULL,
  @ColorTema           NVARCHAR(7)   = NULL,
  @FormaVisual         VARCHAR(20)   = NULL,
  @Activo              BIT           = NULL,
  @UsuarioCreacion     INT           = NULL,
  @UsuarioModificacion INT           = NULL,
  @IdSesion            INT           = NULL,
  @TokenSesion         NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT IdCategoriaRecurso, IdTipoRecurso, IdArea, Nombre, Descripcion,
           ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion
    FROM dbo.CategoriasRecurso WHERE RowStatus = 1 ORDER BY Nombre;
    RETURN;
  END;

  IF @Accion = 'O'
  BEGIN
    SELECT IdCategoriaRecurso, IdTipoRecurso, IdArea, Nombre, Descripcion,
           ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion,
           UsuarioCreacion, FechaModificacion, UsuarioModificacion
    FROM dbo.CategoriasRecurso WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    RETURN;
  END;

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.CategoriasRecurso
      (IdTipoRecurso, IdArea, Nombre, Descripcion, ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES (
      @IdTipoRecurso, @IdArea,
      LTRIM(RTRIM(@Nombre)),
      NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
      ISNULL(@ColorTema, '#3b82f6'),
      CASE WHEN ISNULL(@FormaVisual, '') IN ('square','round','lounge','bar') THEN @FormaVisual ELSE 'square' END,
      ISNULL(@Activo, 1), 1, GETDATE(), @UsuarioCreacion
    );
    SET @IdCategoriaRecurso = SCOPE_IDENTITY();
    SELECT IdCategoriaRecurso, IdTipoRecurso, IdArea, Nombre, Descripcion,
           ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion
    FROM dbo.CategoriasRecurso WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    RETURN;
  END;

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.CategoriasRecurso
    SET IdTipoRecurso = @IdTipoRecurso,
        IdArea        = @IdArea,
        Nombre        = LTRIM(RTRIM(@Nombre)),
        Descripcion   = NULLIF(LTRIM(RTRIM(@Descripcion)), ''),
        ColorTema     = ISNULL(@ColorTema, ColorTema),
        FormaVisual   = CASE WHEN ISNULL(@FormaVisual, '') IN ('square','round','lounge','bar') THEN @FormaVisual ELSE FormaVisual END,
        Activo        = ISNULL(@Activo, Activo),
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
    WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    SELECT IdCategoriaRecurso, IdTipoRecurso, IdArea, Nombre, Descripcion,
           ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion
    FROM dbo.CategoriasRecurso WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    RETURN;
  END;

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.CategoriasRecurso
    SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    SELECT IdCategoriaRecurso, IdTipoRecurso, IdArea, Nombre, Descripcion,
           ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion
    FROM dbo.CategoriasRecurso WHERE IdCategoriaRecurso = @IdCategoriaRecurso;
    RETURN;
  END;

  RAISERROR('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
END;
GO

PRINT 'spCategoriasRecursoCRUD creado/actualizado.';
GO

-- ============================================================
-- 4. spRecursosCRUD (versión final con CantidadSillas + bloqueo)
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.spRecursosCRUD
  @Accion              CHAR(2),
  @IdRecurso           INT           = NULL OUTPUT,
  @IdCategoriaRecurso  INT           = NULL,
  @Nombre              NVARCHAR(100) = NULL,
  @Estado              VARCHAR(20)   = NULL,
  @CantidadSillas      INT           = NULL,
  @Activo              BIT           = NULL,
  @UsuarioCreacion     INT           = NULL,
  @UsuarioModificacion INT           = NULL,
  @IdSesion            INT           = NULL,
  @TokenSesion         NVARCHAR(128) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'L'
  BEGIN
    SELECT R.IdRecurso, R.IdCategoriaRecurso, R.Nombre, R.Estado, R.CantidadSillas,
           R.Activo, R.IdUsuarioBloqueoOrdenes, R.FechaBloqueoOrdenes,
           ISNULL(U.NombreUsuario, '') AS UsuarioBloqueo, R.RowStatus, R.FechaCreacion,
           ISNULL(CR.Nombre, '') AS Categoria,
           ISNULL(A.Nombre, '') AS Area,
           ISNULL(CR.ColorTema, '#3b82f6') AS ColorTema,
           ISNULL(CR.FormaVisual, 'square') AS FormaVisual
    FROM dbo.Recursos R
    LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
    LEFT JOIN dbo.CategoriasRecurso CR ON CR.IdCategoriaRecurso = R.IdCategoriaRecurso
    LEFT JOIN dbo.Areas A ON A.IdArea = CR.IdArea
    WHERE R.RowStatus = 1 ORDER BY A.Nombre, CR.Nombre, R.Nombre;
    RETURN;
  END;

  IF @Accion = 'LC'
  BEGIN
    SELECT R.IdRecurso, R.IdCategoriaRecurso, R.Nombre, R.Estado, R.CantidadSillas,
           R.Activo, R.IdUsuarioBloqueoOrdenes, R.FechaBloqueoOrdenes,
           ISNULL(U.NombreUsuario, '') AS UsuarioBloqueo, R.RowStatus, R.FechaCreacion,
           ISNULL(CR.Nombre, '') AS Categoria,
           ISNULL(A.Nombre, '') AS Area
    FROM dbo.Recursos R
    LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
    LEFT JOIN dbo.CategoriasRecurso CR ON CR.IdCategoriaRecurso = R.IdCategoriaRecurso
    LEFT JOIN dbo.Areas A ON A.IdArea = CR.IdArea
    WHERE R.IdCategoriaRecurso = @IdCategoriaRecurso AND R.RowStatus = 1
    ORDER BY R.Nombre;
    RETURN;
  END;

  IF @Accion = 'O'
  BEGIN
    SELECT R.IdRecurso, R.IdCategoriaRecurso, R.Nombre, R.Estado, R.CantidadSillas,
           R.Activo, R.IdUsuarioBloqueoOrdenes, R.FechaBloqueoOrdenes,
           ISNULL(U.NombreUsuario, '') AS UsuarioBloqueo,
           R.RowStatus, R.FechaCreacion, R.UsuarioCreacion, R.FechaModificacion, R.UsuarioModificacion,
           ISNULL(CR.Nombre, '') AS Categoria,
           ISNULL(A.Nombre, '') AS Area
    FROM dbo.Recursos R
    LEFT JOIN dbo.Usuarios U ON U.IdUsuario = R.IdUsuarioBloqueoOrdenes
    LEFT JOIN dbo.CategoriasRecurso CR ON CR.IdCategoriaRecurso = R.IdCategoriaRecurso
    LEFT JOIN dbo.Areas A ON A.IdArea = CR.IdArea
    WHERE R.IdRecurso = @IdRecurso;
    RETURN;
  END;

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.Recursos
      (IdCategoriaRecurso, Nombre, Estado, CantidadSillas, Activo,
       IdUsuarioBloqueoOrdenes, FechaBloqueoOrdenes, RowStatus, FechaCreacion, UsuarioCreacion)
    VALUES
      (@IdCategoriaRecurso, LTRIM(RTRIM(@Nombre)), ISNULL(@Estado, 'Libre'),
       ISNULL(@CantidadSillas, 4), ISNULL(@Activo, 1), NULL, NULL, 1, GETDATE(), @UsuarioCreacion);
    SET @IdRecurso = SCOPE_IDENTITY();
    EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
    RETURN;
  END;

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.Recursos
    SET IdCategoriaRecurso = @IdCategoriaRecurso,
        Nombre             = LTRIM(RTRIM(@Nombre)),
        Estado             = ISNULL(@Estado, Estado),
        CantidadSillas     = ISNULL(@CantidadSillas, CantidadSillas),
        Activo             = ISNULL(@Activo, Activo),
        FechaModificacion   = GETDATE(),
        UsuarioModificacion = @UsuarioModificacion
    WHERE IdRecurso = @IdRecurso;
    EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
    RETURN;
  END;

  IF @Accion = 'CE'
  BEGIN
    UPDATE dbo.Recursos
    SET Estado = @Estado, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdRecurso = @IdRecurso;
    EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
    RETURN;
  END;

  IF @Accion = 'D'
  BEGIN
    UPDATE dbo.Recursos
    SET RowStatus = 0, FechaModificacion = GETDATE(), UsuarioModificacion = @UsuarioModificacion
    WHERE IdRecurso = @IdRecurso;
    EXEC dbo.spRecursosCRUD @Accion = 'O', @IdRecurso = @IdRecurso;
    RETURN;
  END;

  RAISERROR('La accion enviada no es valida. Use L, LC, O, I, A, CE o D.', 16, 1);
END;
GO

PRINT 'spRecursosCRUD creado/actualizado.';
GO

PRINT 'Script 127_salon_sps_crud.sql ejecutado correctamente.';
GO
