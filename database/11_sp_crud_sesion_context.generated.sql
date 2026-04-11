-- spRolesCRUD

ALTER PROCEDURE dbo.spRolesCRUD
    @Accion char(1),
    @IdRol int = null output,
    @Nombre nvarchar(100) = null,
    @Descripcion nvarchar(250) = null,
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
        select IdRol,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.Roles
            where RowStatus = 1
            order by Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select IdRol,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.Roles
            where IdRol = @IdRol
                  and RowStatus = 1;
        return;
    end;
    if @Accion = 'I'
    begin
        insert into dbo.Roles
            (Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdRol = scope_identity();
        select IdRol,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.Roles
            where IdRol = @IdRol;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.Roles
            set Nombre = ltrim(rtrim(@Nombre)),
                Descripcion = nullif(ltrim(rtrim(@Descripcion)), ''),
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdRol = @IdRol
                  and RowStatus = 1;
        select IdRol,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.Roles
            where IdRol = @IdRol
                  and RowStatus = 1;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.Roles
            set RowStatus = 0,
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdRol = @IdRol
                  and RowStatus = 1;
        select IdRol,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.Roles
            where IdRol = @IdRol;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO

-- spPermisosCRUD

ALTER PROCEDURE dbo.spPermisosCRUD
    @Accion char(1),
    @IdPermiso int = null output,
    @IdPantalla int = null,
    @Nombre nvarchar(150) = null,
    @Descripcion nvarchar(250) = null,
    @pVer bit = null,
    @pCrear bit = null,
    @pEditar bit = null,
    @pEliminar bit = null,
    @pAprobar bit = null,
    @pAnular bit = null,
    @pImprimir bit = null,
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
        select P.IdPermiso,
               P.IdPantalla,
               PA.Nombre as Pantalla,
               M.Nombre as Modulo,
               P.Nombre,
               P.Descripcion,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion
            from dbo.Permisos P
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where P.RowStatus = 1
            order by M.Orden,
                     PA.Orden,
                     P.Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select P.IdPermiso,
               P.IdPantalla,
               PA.Nombre as Pantalla,
               M.Nombre as Modulo,
               P.Nombre,
               P.Descripcion,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
            from dbo.Permisos P
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where P.IdPermiso = @IdPermiso
                  and P.RowStatus = 1;
        return;
    end;
    if @Accion = 'I'
    begin
        insert into dbo.Permisos
            (IdPantalla,
             Nombre,
             Descripcion,
             PuedeVer,
             PuedeCrear,
             PuedeEditar,
             PuedeEliminar,
             PuedeAprobar,
             PuedeAnular,
             PuedeImprimir,
             Activo,
             RowStatus,
             FechaCreacion,
             UsuarioCreacion)
        values (@IdPantalla,
                ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@pVer, 0),
                isnull(@pCrear, 0),
                isnull(@pEditar, 0),
                isnull(@pEliminar, 0),
                isnull(@pAprobar, 0),
                isnull(@pAnular, 0),
                isnull(@pImprimir, 0),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdPermiso = scope_identity();
        select P.IdPermiso,
               P.IdPantalla,
               PA.Nombre as Pantalla,
               M.Nombre as Modulo,
               P.Nombre,
               P.Descripcion,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
            from dbo.Permisos P
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where P.IdPermiso = @IdPermiso;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.Permisos
            set IdPantalla = @IdPantalla,
                Nombre = ltrim(rtrim(@Nombre)),
                Descripcion = nullif(ltrim(rtrim(@Descripcion)), ''),
                PuedeVer = isnull(@pVer, PuedeVer),
                PuedeCrear = isnull(@pCrear, PuedeCrear),
                PuedeEditar = isnull(@pEditar, PuedeEditar),
                PuedeEliminar = isnull(@pEliminar, PuedeEliminar),
                PuedeAprobar = isnull(@pAprobar, PuedeAprobar),
                PuedeAnular = isnull(@pAnular, PuedeAnular),
                PuedeImprimir = isnull(@pImprimir, PuedeImprimir),
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdPermiso = @IdPermiso
                  and RowStatus = 1;
        select P.IdPermiso,
               P.IdPantalla,
               PA.Nombre as Pantalla,
               M.Nombre as Modulo,
               P.Nombre,
               P.Descripcion,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
            from dbo.Permisos P
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where P.IdPermiso = @IdPermiso
                  and P.RowStatus = 1;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.Permisos
            set RowStatus = 0,
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdPermiso = @IdPermiso
                  and RowStatus = 1;
        select P.IdPermiso,
               P.IdPantalla,
               PA.Nombre as Pantalla,
               M.Nombre as Modulo,
               P.Nombre,
               P.Descripcion,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               P.Activo,
               P.RowStatus,
               P.FechaCreacion,
               P.UsuarioCreacion,
               P.FechaModificacion,
               P.UsuarioModificacion
            from dbo.Permisos P
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where P.IdPermiso = @IdPermiso;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO

-- spCategoriasCRUD

ALTER PROCEDURE dbo.spCategoriasCRUD
    @Accion char(1),
    @IdCategoria int = null,
    @Nombre nvarchar(100) = null,
    @Descripcion nvarchar(250) = null,
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
        select IdCategoria,
               Nombre,
               Descripcion,
               Activo,
               FechaCreacion,
               RowStatus
            from dbo.Categorias
            where RowStatus = 1
            order by Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        if isnull(@IdCategoria, 0) = 0
        begin
            raiserror('Debe enviar @IdCategoria para la accion O.', 16, 1);
            return;
        end;
        select IdCategoria,
               Nombre,
               Descripcion,
               Activo,
               FechaCreacion,
               RowStatus,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.Categorias
            where IdCategoria = @IdCategoria;
        return;
    end;
    if @Accion = 'I'
    begin
        if isnull(ltrim(rtrim(@Nombre)), '') = ''
        begin
            raiserror('Debe enviar @Nombre para la accion I.', 16, 1);
            return;
        end;
        if exists (select 1
                       from dbo.Categorias
                       where Nombre = ltrim(rtrim(@Nombre))
                             and RowStatus = 1)
        begin
            raiserror('Ya existe una categoría con ese Nombre.', 16, 1);
            return;
        end;
        insert into dbo.Categorias
            (Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        select IdCategoria,
               Nombre,
               Descripcion,
               Activo,
               FechaCreacion,
               RowStatus
            from dbo.Categorias
            where IdCategoria = scope_identity();
        return;
    end;
    if @Accion = 'A'
    begin
        if isnull(@IdCategoria, 0) = 0
        begin
            raiserror('Debe enviar @IdCategoria para la accion A.', 16, 1);
            return;
        end;
        if not exists (select 1
                           from dbo.Categorias
                           where IdCategoria = @IdCategoria)
        begin
            raiserror('La categoría indicada no existe.', 16, 1);
            return;
        end;
        if isnull(ltrim(rtrim(@Nombre)), '') = ''
        begin
            raiserror('Debe enviar @Nombre para la accion A.', 16, 1);
            return;
        end;
        if exists (select 1
                       from dbo.Categorias
                       where Nombre = ltrim(rtrim(@Nombre))
                             and IdCategoria <> @IdCategoria
                             and RowStatus = 1)
        begin
            raiserror('Ya existe otra categoría con ese Nombre.', 16, 1);
            return;
        end;
        update dbo.Categorias
            set Nombre = ltrim(rtrim(@Nombre)),
                Descripcion = nullif(ltrim(rtrim(@Descripcion)), ''),
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdCategoria = @IdCategoria;
        select IdCategoria,
               Nombre,
               Descripcion,
               Activo,
               FechaCreacion,
               RowStatus
            from dbo.Categorias
            where IdCategoria = @IdCategoria;
        return;
    end;
    if @Accion = 'D'
    begin
        if isnull(@IdCategoria, 0) = 0
        begin
            raiserror('Debe enviar @IdCategoria para la accion D.', 16, 1);
            return;
        end;
        update dbo.Categorias
            set RowStatus = 0,
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdCategoria = @IdCategoria;
        select IdCategoria,
               Nombre,
               Descripcion,
               Activo,
               FechaCreacion,
               RowStatus
            from dbo.Categorias
            where IdCategoria = @IdCategoria;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO

-- spAreasCRUD

ALTER PROCEDURE dbo.spAreasCRUD
    @Accion char(1),
    @IdArea int = null output,
    @Nombre varchar(100) = null,
    @Descripcion varchar(250) = null,
    @Orden int = null,
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
        select IdArea,
               Nombre,
               Descripcion,
               Orden,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.Areas
            where RowStatus = 1
            order by Orden,
                     Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select IdArea,
               Nombre,
               Descripcion,
               Orden,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.Areas
            where IdArea = @IdArea;
        return;
    end;
    if @Accion = 'I'
    begin
        insert into dbo.Areas
            (Nombre, Descripcion, Orden, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@Orden, 0),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdArea = scope_identity();
        select IdArea,
               Nombre,
               Descripcion,
               Orden,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.Areas
            where IdArea = @IdArea;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.Areas
            set Nombre = ltrim(rtrim(@Nombre)),
                Descripcion = nullif(ltrim(rtrim(@Descripcion)), ''),
                Orden = isnull(@Orden, Orden),
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdArea = @IdArea;
        select IdArea,
               Nombre,
               Descripcion,
               Orden,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.Areas
            where IdArea = @IdArea;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.Areas
            set RowStatus = 0,
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdArea = @IdArea;
        select IdArea,
               Nombre,
               Descripcion,
               Orden,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.Areas
            where IdArea = @IdArea;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO

-- spRecursosCRUD

ALTER PROCEDURE dbo.spRecursosCRUD
    @Accion char(2),
    @IdRecurso int = null output,
    @IdCategoriaRecurso int = null,
    @Nombre varchar(100) = null,
    @Estado varchar(20) = null,
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
            (IdCategoriaRecurso, Nombre, Estado, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (@IdCategoriaRecurso,
                ltrim(rtrim(@Nombre)),
                isnull(@Estado, 'Libre'),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdRecurso = scope_identity();
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
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
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdRecurso = @IdRecurso;
        select IdRecurso,
               IdCategoriaRecurso,
               Nombre,
               Estado,
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
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.Recursos
            where IdRecurso = @IdRecurso;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, LC, O, I, A, CE o D.', 16, 1);
end;

GO

-- spTiposRecursoCRUD

ALTER PROCEDURE dbo.spTiposRecursoCRUD
    @Accion char(1),
    @IdTipoRecurso int = null output,
    @Nombre varchar(100) = null,
    @Descripcion varchar(250) = null,
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
        select IdTipoRecurso,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.TiposRecurso
            where RowStatus = 1
            order by Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select IdTipoRecurso,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion,
               UsuarioCreacion,
               FechaModificacion,
               UsuarioModificacion
            from dbo.TiposRecurso
            where IdTipoRecurso = @IdTipoRecurso;
        return;
    end;
    if @Accion = 'I'
    begin
        insert into dbo.TiposRecurso
            (Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdTipoRecurso = scope_identity();
        select IdTipoRecurso,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.TiposRecurso
            where IdTipoRecurso = @IdTipoRecurso;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.TiposRecurso
            set Nombre = ltrim(rtrim(@Nombre)),
                Descripcion = nullif(ltrim(rtrim(@Descripcion)), ''),
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdTipoRecurso = @IdTipoRecurso;
        select IdTipoRecurso,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.TiposRecurso
            where IdTipoRecurso = @IdTipoRecurso;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.TiposRecurso
            set RowStatus = 0,
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdTipoRecurso = @IdTipoRecurso;
        select IdTipoRecurso,
               Nombre,
               Descripcion,
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.TiposRecurso
            where IdTipoRecurso = @IdTipoRecurso;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO

-- spCategoriasRecursoCRUD

ALTER PROCEDURE dbo.spCategoriasRecursoCRUD
    @Accion char(1),
    @IdCategoriaRecurso int = null output,
    @IdTipoRecurso int = null,
    @IdArea int = null,
    @Nombre varchar(100) = null,
    @Descripcion varchar(250) = null,
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
            (IdTipoRecurso, IdArea, Nombre, Descripcion, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (@IdTipoRecurso,
                @IdArea,
                ltrim(rtrim(@Nombre)),
                nullif(ltrim(rtrim(@Descripcion)), ''),
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
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdCategoriaRecurso = @IdCategoriaRecurso;
        select IdCategoriaRecurso,
               IdTipoRecurso,
               IdArea,
               Nombre,
               Descripcion,
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
               Activo,
               RowStatus,
               FechaCreacion
            from dbo.CategoriasRecurso
            where IdCategoriaRecurso = @IdCategoriaRecurso;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO

-- spRolesPermisosCRUD

ALTER PROCEDURE dbo.spRolesPermisosCRUD
    @Accion char(1),
    @IdRolPermiso int = null output,
    @IdRol int = null,
    @IdPermiso int = null,
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
        select RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre as Rol,
               RP.IdPermiso,
               P.Nombre as Permiso,
               M.Nombre as Modulo,
               PA.Nombre as Pantalla,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion
            from dbo.RolesPermisos RP
                inner join dbo.Roles R on RP.IdRol = R.IdRol
                inner join dbo.Permisos P on RP.IdPermiso = P.IdPermiso
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where RP.RowStatus = 1
            order by R.Nombre,
                     M.Orden,
                     PA.Orden,
                     P.Nombre;
        return;
    end;
    if @Accion = 'O'
    begin
        select RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre as Rol,
               RP.IdPermiso,
               P.Nombre as Permiso,
               M.Nombre as Modulo,
               PA.Nombre as Pantalla,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
            from dbo.RolesPermisos RP
                inner join dbo.Roles R on RP.IdRol = R.IdRol
                inner join dbo.Permisos P on RP.IdPermiso = P.IdPermiso
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where RP.IdRolPermiso = @IdRolPermiso
                  and RP.RowStatus = 1;
        return;
    end;
    if @Accion = 'I'
    begin
        if exists (select 1
                       from dbo.RolesPermisos
                       where IdRol = @IdRol
                             and IdPermiso = @IdPermiso
                             and RowStatus = 1)
        begin
            raiserror('El rol ya tiene este permiso asignado.', 16, 1);
            return;
        end;
        insert into dbo.RolesPermisos
            (IdRol, IdPermiso, Activo, RowStatus, FechaCreacion, UsuarioCreacion)
        values (@IdRol,
                @IdPermiso,
                isnull(@Activo, 1),
                1,
                getdate(),
                @UsuarioCreacion);
        set @IdRolPermiso = scope_identity();
        select RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre as Rol,
               RP.IdPermiso,
               P.Nombre as Permiso,
               M.Nombre as Modulo,
               PA.Nombre as Pantalla,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
            from dbo.RolesPermisos RP
                inner join dbo.Roles R on RP.IdRol = R.IdRol
                inner join dbo.Permisos P on RP.IdPermiso = P.IdPermiso
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where RP.IdRolPermiso = @IdRolPermiso;
        return;
    end;
    if @Accion = 'A'
    begin
        update dbo.RolesPermisos
            set IdRol = @IdRol,
                IdPermiso = @IdPermiso,
                Activo = isnull(@Activo, Activo),
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdRolPermiso = @IdRolPermiso
                  and RowStatus = 1;
        select RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre as Rol,
               RP.IdPermiso,
               P.Nombre as Permiso,
               M.Nombre as Modulo,
               PA.Nombre as Pantalla,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
            from dbo.RolesPermisos RP
                inner join dbo.Roles R on RP.IdRol = R.IdRol
                inner join dbo.Permisos P on RP.IdPermiso = P.IdPermiso
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where RP.IdRolPermiso = @IdRolPermiso
                  and RP.RowStatus = 1;
        return;
    end;
    if @Accion = 'D'
    begin
        update dbo.RolesPermisos
            set RowStatus = 0,
                FechaModificacion = getdate(),
                UsuarioModificacion = @UsuarioModificacion
            where IdRolPermiso = @IdRolPermiso
                  and RowStatus = 1;
        select RP.IdRolPermiso,
               RP.IdRol,
               R.Nombre as Rol,
               RP.IdPermiso,
               P.Nombre as Permiso,
               M.Nombre as Modulo,
               PA.Nombre as Pantalla,
               P.PuedeVer,
               P.PuedeCrear,
               P.PuedeEditar,
               P.PuedeEliminar,
               P.PuedeAprobar,
               P.PuedeAnular,
               P.PuedeImprimir,
               RP.Activo,
               RP.RowStatus,
               RP.FechaCreacion,
               RP.UsuarioCreacion,
               RP.FechaModificacion,
               RP.UsuarioModificacion
            from dbo.RolesPermisos RP
                inner join dbo.Roles R on RP.IdRol = R.IdRol
                inner join dbo.Permisos P on RP.IdPermiso = P.IdPermiso
                inner join dbo.Pantallas PA on P.IdPantalla = PA.IdPantalla
                inner join dbo.Modulos M on PA.IdModulo = M.IdModulo
            where RP.IdRolPermiso = @IdRolPermiso;
        return;
    end;
    raiserror('La acción enviada no es válida. Use L, O, I, A o D.', 16, 1);
end;

GO
