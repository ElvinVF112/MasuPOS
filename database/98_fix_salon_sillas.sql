SET NOCOUNT ON;

IF COL_LENGTH('dbo.Recursos', 'CantidadSillas') IS NULL
BEGIN
  ALTER TABLE dbo.Recursos ADD CantidadSillas INT NULL;
END
GO

UPDATE dbo.Recursos
SET CantidadSillas = 4
WHERE CantidadSillas IS NULL;
GO

IF EXISTS (
  SELECT 1
  FROM sys.columns
  WHERE object_id = OBJECT_ID('dbo.Recursos')
    AND name = 'CantidadSillas'
    AND is_nullable = 1
)
BEGIN
  ALTER TABLE dbo.Recursos ALTER COLUMN CantidadSillas INT NOT NULL;
END
GO

IF NOT EXISTS (
  SELECT 1
  FROM sys.default_constraints
  WHERE parent_object_id = OBJECT_ID('dbo.Recursos')
    AND name = 'DF_Recursos_CantidadSillas'
)
BEGIN
  ALTER TABLE dbo.Recursos
  ADD CONSTRAINT DF_Recursos_CantidadSillas DEFAULT (4) FOR CantidadSillas;
END
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
