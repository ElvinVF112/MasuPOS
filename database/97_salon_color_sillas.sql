SET NOCOUNT ON;

IF COL_LENGTH('dbo.Recursos', 'CantidadSillas') IS NULL
BEGIN
  ALTER TABLE dbo.Recursos ADD CantidadSillas INT NULL;
  UPDATE dbo.Recursos SET CantidadSillas = 4 WHERE CantidadSillas IS NULL;
  ALTER TABLE dbo.Recursos ALTER COLUMN CantidadSillas INT NOT NULL;
  ALTER TABLE dbo.Recursos ADD CONSTRAINT DF_Recursos_CantidadSillas DEFAULT (4) FOR CantidadSillas;
END
ELSE
BEGIN
  UPDATE dbo.Recursos SET CantidadSillas = 4 WHERE CantidadSillas IS NULL;
END
GO

IF COL_LENGTH('dbo.CategoriasRecurso', 'ColorTema') IS NULL
BEGIN
  ALTER TABLE dbo.CategoriasRecurso ADD ColorTema NVARCHAR(7) NULL;
END
GO

UPDATE dbo.CategoriasRecurso
SET ColorTema = CASE (ABS(CHECKSUM(IdCategoriaRecurso)) % 8)
  WHEN 0 THEN '#3b82f6'
  WHEN 1 THEN '#10b981'
  WHEN 2 THEN '#f59e0b'
  WHEN 3 THEN '#8b5cf6'
  WHEN 4 THEN '#ec4899'
  WHEN 5 THEN '#06b6d4'
  WHEN 6 THEN '#ef4444'
  ELSE '#14b8a6'
END
WHERE ColorTema IS NULL OR LTRIM(RTRIM(ColorTema)) = '';
GO

ALTER PROCEDURE dbo.spRecursosCRUD
    @Accion char(2),
    @IdRecurso int = null output,
    @IdCategoriaRecurso int = null,
    @Nombre varchar(100) = null,
    @Estado varchar(20) = null,
    @CantidadSillas int = null,
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
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.Recursos
         where RowStatus = 1
         order by Nombre;
        return;
    end;
    if @Accion = 'LC'
    begin
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.Recursos
         where IdCategoriaRecurso = @IdCategoriaRecurso
           and RowStatus = 1
         order by Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
          from dbo.Recursos
         where IdRecurso = @IdRecurso;
        return;
    end;
    if @Accion = 'I'
    begin
        insert into dbo.Recursos
            (IdCategoriaRecurso, Nombre, Estado, CantidadSillas, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (@IdCategoriaRecurso,
                ltrim(rtrim(@Nombre)),
                isnull(@Estado, 'Libre'),
                isnull(@CantidadSillas, 4),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdRecurso = scope_identity();
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.Recursos
         where IdRecurso = @IdRecurso;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.Recursos
           set IdCategoriaRecurso = @IdCategoriaRecurso,
               Nombre = ltrim(rtrim(@Nombre)),
               Estado = isnull(@Estado, Estado),
               CantidadSillas = isnull(@CantidadSillas, CantidadSillas),
               Activo = isnull(@Activo, Activo),
               FechaModificacion = getdate(),
               UsuarioModificacion = @UsuarioModificacion
         where IdRecurso = @IdRecurso;
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.Recursos
         where IdRecurso = @IdRecurso;
        return;
    end;
    if @Accion = 'CE'
    begin
        update dbo.Recursos
           set Estado = @Estado,
               FechaModificacion = getdate(),
               UsuarioModificacion = @UsuarioModificacion
         where IdRecurso = @IdRecurso;
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.Recursos
         where IdRecurso = @IdRecurso;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.Recursos
           set RowStatus = 0,
               FechaModificacion = getdate(),
               UsuarioModificacion = @UsuarioModificacion
         where IdRecurso = @IdRecurso;
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
               CantidadSillas,
               Activo,
               RowStatus,
               FechaCreacion
          from dbo.Recursos
         where IdRecurso = @IdRecurso;
        return;
    end;

    raiserror('La accion enviada no es valida. Use L, LC, O, I, A, CE o D.', 16, 1);
end;
GO

ALTER PROCEDURE dbo.spCategoriasRecursoCRUD
    @Accion char(1),
    @IdCategoriaRecurso int = null output,
    @IdTipoRecurso int = null,
    @IdArea int = null,
    @Nombre varchar(100) = null,
    @Descripcion varchar(250) = null,
    @ColorTema nvarchar(7) = null,
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
            (IdTipoRecurso, IdArea, Nombre, Descripcion, ColorTema, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (@IdTipoRecurso,
                @IdArea,
                ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@ColorTema, '#3b82f6'),
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
