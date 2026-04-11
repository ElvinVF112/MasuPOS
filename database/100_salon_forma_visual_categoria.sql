SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF COL_LENGTH('dbo.CategoriasRecurso', 'FormaVisual') IS NULL
BEGIN
  ALTER TABLE dbo.CategoriasRecurso ADD FormaVisual VARCHAR(20) NULL;
END;
GO

UPDATE dbo.CategoriasRecurso
SET FormaVisual =
  CASE
    WHEN LOWER(ISNULL(Nombre, '')) LIKE '%barra%' THEN 'bar'
    WHEN LOWER(ISNULL(Nombre, '')) LIKE '%vip%' OR LOWER(ISNULL(Nombre, '')) LIKE '%lounge%' THEN 'lounge'
    WHEN LOWER(ISNULL(Nombre, '')) LIKE '%terraza%' OR LOWER(ISNULL(Nombre, '')) LIKE '%redond%' THEN 'round'
    ELSE 'square'
  END
WHERE FormaVisual IS NULL OR LTRIM(RTRIM(FormaVisual)) = '';
GO

ALTER TABLE dbo.CategoriasRecurso
ALTER COLUMN FormaVisual VARCHAR(20) NOT NULL;
GO

ALTER PROCEDURE dbo.spCategoriasRecursoCRUD
    @Accion char(1),
    @IdCategoriaRecurso int = null output,
    @IdTipoRecurso int = null,
    @IdArea int = null,
    @Nombre varchar(100) = null,
    @Descripcion varchar(250) = null,
    @ColorTema nvarchar(7) = null,
    @FormaVisual varchar(20) = null,
    @Activo bit = null,
    @UsuarioCreacion int = null,
    @UsuarioModificacion int = null,
    @IdSesion INT = NULL,
    @TokenSesion NVARCHAR(128) = NULL
as
begin
    set nocount on;
    if @Accion = 'L'
    begin
        select IdCategoriaRecurso,
               IdTipoRecurso,
               IdArea,
               Nombre,
               Descripcion,
               ColorTema,
               FormaVisual,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.CategoriasRecurso
         where RowStatus = 1
         order by Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select IdCategoriaRecurso,
               IdTipoRecurso,
               IdArea,
               Nombre,
               Descripcion,
               ColorTema,
               FormaVisual,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
          from dbo.CategoriasRecurso
         where IdCategoriaRecurso = @IdCategoriaRecurso;
        return;
    end;
    if @Accion = 'I'
    begin
        insert into dbo.CategoriasRecurso
            (IdTipoRecurso, IdArea, Nombre, Descripcion, ColorTema, FormaVisual, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (@IdTipoRecurso,
                @IdArea,
                ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@ColorTema, '#3b82f6'),
                case when isnull(@FormaVisual, '') in ('square','round','lounge','bar') then @FormaVisual else 'square' end,
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdCategoriaRecurso = scope_identity();
        select IdCategoriaRecurso,
               IdTipoRecurso,
               IdArea,
               Nombre,
               Descripcion,
               ColorTema,
               FormaVisual,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.CategoriasRecurso
         where IdCategoriaRecurso = @IdCategoriaRecurso;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.CategoriasRecurso
           set IdTipoRecurso = @IdTipoRecurso,
               IdArea = @IdArea,
               Nombre = ltrim(rtrim(@Nombre)),
               Descripcion = nullif(ltrim(rtrim(@Descripcion)), ''),
               ColorTema = isnull(@ColorTema, ColorTema),
               FormaVisual = case when isnull(@FormaVisual, '') in ('square','round','lounge','bar') then @FormaVisual else FormaVisual end,
               Activo = isnull(@Activo, Activo),
               FechaModificacion = getdate(),
               UsuarioModificacion = @UsuarioModificacion
         where IdCategoriaRecurso = @IdCategoriaRecurso;
        select IdCategoriaRecurso,
               IdTipoRecurso,
               IdArea,
               Nombre,
               Descripcion,
               ColorTema,
               FormaVisual,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.CategoriasRecurso
         where IdCategoriaRecurso = @IdCategoriaRecurso;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.CategoriasRecurso
           set RowStatus = 0,
               FechaModificacion = getdate(),
               UsuarioModificacion = @UsuarioModificacion
         where IdCategoriaRecurso = @IdCategoriaRecurso;
        select IdCategoriaRecurso,
               IdTipoRecurso,
               IdArea,
               Nombre,
               Descripcion,
               ColorTema,
               FormaVisual,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.CategoriasRecurso
         where IdCategoriaRecurso = @IdCategoriaRecurso;
        return;
    end;

    raiserror('La accion enviada no es valida. Use L, O, I, A o D.', 16, 1);
end;
GO
