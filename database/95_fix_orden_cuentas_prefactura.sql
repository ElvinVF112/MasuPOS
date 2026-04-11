USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

PRINT '=== Script 95: Fix OrdenCuentas / Prefactura ===';
GO

IF OBJECT_ID('dbo.EstadosCuenta', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.EstadosCuenta (
    IdEstadoCuenta INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL UNIQUE,
    Descripcion VARCHAR(250) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_EstadosCuenta_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_EstadosCuenta_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_EstadosCuenta_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.EstadosCuenta WHERE Nombre = 'Abierta')
  INSERT INTO dbo.EstadosCuenta (Nombre, Descripcion) VALUES ('Abierta', 'Subcuenta disponible para edicion');
IF NOT EXISTS (SELECT 1 FROM dbo.EstadosCuenta WHERE Nombre = 'EnCaja')
  INSERT INTO dbo.EstadosCuenta (Nombre, Descripcion) VALUES ('EnCaja', 'Enviada a caja, bloqueada para operacion');
IF NOT EXISTS (SELECT 1 FROM dbo.EstadosCuenta WHERE Nombre = 'Anulada')
  INSERT INTO dbo.EstadosCuenta (Nombre, Descripcion) VALUES ('Anulada', 'Cancelada por usuario');
GO

IF OBJECT_ID('dbo.OrdenCuentas', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdenCuentas (
    IdOrdenCuenta INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdOrden INT NOT NULL,
    NumeroCuenta INT NOT NULL,
    Nombre VARCHAR(100) NULL,
    Subtotal DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentas_Subtotal DEFAULT (0),
    Impuesto DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentas_Impuesto DEFAULT (0),
    Descuento DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentas_Descuento DEFAULT (0),
    Propina DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentas_Propina DEFAULT (0),
    Total DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentas_Total DEFAULT (0),
    IdEstadoCuenta INT NOT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_OrdenCuentas_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_OrdenCuentas_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_OrdenCuentas_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL,
    FechaModificacion DATETIME NULL,
    UsuarioModificacion INT NULL,
    CONSTRAINT FK_OrdenCuentas_Orden FOREIGN KEY (IdOrden) REFERENCES dbo.Ordenes (IdOrden),
    CONSTRAINT FK_OrdenCuentas_Estado FOREIGN KEY (IdEstadoCuenta) REFERENCES dbo.EstadosCuenta (IdEstadoCuenta)
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.OrdenCuentas') AND name = 'UX_OrdenCuentas_NumeroUnico')
BEGIN
  CREATE UNIQUE INDEX UX_OrdenCuentas_NumeroUnico ON dbo.OrdenCuentas (IdOrden, NumeroCuenta) WHERE RowStatus = 1;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.OrdenCuentas') AND name = 'IX_OrdenCuentas_IdOrden')
BEGIN
  CREATE INDEX IX_OrdenCuentas_IdOrden ON dbo.OrdenCuentas (IdOrden) WHERE RowStatus = 1;
END
GO

IF OBJECT_ID('dbo.OrdenCuentaDetalle', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdenCuentaDetalle (
    IdOrdenCuentaDetalle INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdOrdenCuenta INT NOT NULL,
    IdOrdenDetalle INT NOT NULL,
    CantidadAsignada DECIMAL(12,2) NOT NULL,
    SubtotalLinea DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentaDetalle_SubtotalLinea DEFAULT (0),
    MontoImpuesto DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentaDetalle_MontoImpuesto DEFAULT (0),
    TotalLinea DECIMAL(12,2) NOT NULL CONSTRAINT DF_OrdenCuentaDetalle_TotalLinea DEFAULT (0),
    Activo BIT NOT NULL CONSTRAINT DF_OrdenCuentaDetalle_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_OrdenCuentaDetalle_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_OrdenCuentaDetalle_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL,
    FechaModificacion DATETIME NULL,
    UsuarioModificacion INT NULL,
    CONSTRAINT FK_OrdenCuentaDetalle_Cuenta FOREIGN KEY (IdOrdenCuenta) REFERENCES dbo.OrdenCuentas (IdOrdenCuenta),
    CONSTRAINT FK_OrdenCuentaDetalle_Detalle FOREIGN KEY (IdOrdenDetalle) REFERENCES dbo.OrdenesDetalle (IdOrdenDetalle)
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.OrdenCuentaDetalle') AND name = 'IX_OrdenCuentaDetalle_Cuenta')
BEGIN
  CREATE INDEX IX_OrdenCuentaDetalle_Cuenta ON dbo.OrdenCuentaDetalle (IdOrdenCuenta) WHERE RowStatus = 1;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.OrdenCuentaDetalle') AND name = 'IX_OrdenCuentaDetalle_Detalle')
BEGIN
  CREATE INDEX IX_OrdenCuentaDetalle_Detalle ON dbo.OrdenCuentaDetalle (IdOrdenDetalle) WHERE RowStatus = 1;
END
GO

IF OBJECT_ID('dbo.OrdenCuentaMovimientos', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdenCuentaMovimientos (
    IdOrdenCuentaMovimiento INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdOrdenCuenta INT NULL,
    IdOrden INT NOT NULL,
    TipoMovimiento VARCHAR(50) NOT NULL,
    Observacion VARCHAR(500) NULL,
    FechaMovimiento DATETIME NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_FechaMovimiento DEFAULT (GETDATE()),
    UsuarioMovimiento INT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL,
    CONSTRAINT FK_OrdenCuentaMovimientos_Orden FOREIGN KEY (IdOrden) REFERENCES dbo.Ordenes (IdOrden)
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.OrdenCuentaMovimientos') AND name = 'IX_OrdenCuentaMovimientos_Orden')
BEGIN
  CREATE INDEX IX_OrdenCuentaMovimientos_Orden ON dbo.OrdenCuentaMovimientos (IdOrden) WHERE RowStatus = 1;
END
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasRegistrarMovimiento
  @IdOrden INT,
  @IdOrdenCuenta INT = NULL,
  @TipoMovimiento VARCHAR(50),
  @Observacion VARCHAR(500) = NULL,
  @UsuarioCreacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  INSERT INTO dbo.OrdenCuentaMovimientos (
    IdOrdenCuenta, IdOrden, TipoMovimiento, Observacion, UsuarioMovimiento, UsuarioCreacion
  )
  VALUES (
    @IdOrdenCuenta, @IdOrden, @TipoMovimiento, @Observacion, @UsuarioCreacion, @UsuarioCreacion
  );
END
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasRecalcular
  @IdOrdenCuenta INT,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @Subtotal DECIMAL(12,2) = 0;
  DECLARE @Impuesto DECIMAL(12,2) = 0;
  DECLARE @Descuento DECIMAL(12,2) = 0;
  DECLARE @Propina DECIMAL(12,2) = 0;
  DECLARE @Total DECIMAL(12,2) = 0;

  SELECT
    @Subtotal = ISNULL(SUM(SubtotalLinea), 0),
    @Impuesto = ISNULL(SUM(MontoImpuesto), 0)
  FROM dbo.OrdenCuentaDetalle
  WHERE IdOrdenCuenta = @IdOrdenCuenta AND RowStatus = 1;

  SELECT
    @Descuento = ISNULL(Descuento, 0),
    @Propina = ISNULL(Propina, 0)
  FROM dbo.OrdenCuentas
  WHERE IdOrdenCuenta = @IdOrdenCuenta;

  SET @Total = @Subtotal + @Impuesto - @Descuento + @Propina;

  UPDATE dbo.OrdenCuentas
  SET
    Subtotal = @Subtotal,
    Impuesto = @Impuesto,
    Total = @Total,
    FechaModificacion = GETDATE(),
    UsuarioModificacion = @UsuarioModificacion
  WHERE IdOrdenCuenta = @IdOrdenCuenta;
END
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasCRUD
  @Accion CHAR(1),
  @IdOrdenCuenta INT = NULL,
  @IdOrden INT = NULL,
  @NumeroCuenta INT = NULL,
  @Nombre VARCHAR(100) = NULL,
  @IdEstadoCuenta INT = NULL,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  IF @Accion = 'I'
  BEGIN
    INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
    VALUES (@IdOrden, @NumeroCuenta, @Nombre, @IdEstadoCuenta, @UsuarioModificacion);

    SELECT SCOPE_IDENTITY() AS IdOrdenCuenta;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    UPDATE dbo.OrdenCuentas
    SET
      Nombre = COALESCE(@Nombre, Nombre),
      IdEstadoCuenta = COALESCE(@IdEstadoCuenta, IdEstadoCuenta),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenCuenta = @IdOrdenCuenta AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'X'
  BEGIN
    UPDATE dbo.OrdenCuentas
    SET
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenCuenta = @IdOrdenCuenta AND RowStatus = 1;
    RETURN;
  END

  IF @Accion = 'L'
  BEGIN
    SELECT
      oc.IdOrdenCuenta,
      oc.IdOrden,
      oc.NumeroCuenta,
      oc.Nombre,
      oc.Subtotal,
      oc.Impuesto,
      oc.Descuento,
      oc.Propina,
      oc.Total,
      ec.Nombre AS NombreEstado,
      oc.FechaCreacion,
      oc.UsuarioCreacion
    FROM dbo.OrdenCuentas oc
    INNER JOIN dbo.EstadosCuenta ec ON ec.IdEstadoCuenta = oc.IdEstadoCuenta
    WHERE oc.IdOrden = @IdOrden AND oc.RowStatus = 1
    ORDER BY oc.NumeroCuenta;
    RETURN;
  END

  IF @Accion = 'O'
  BEGIN
    SELECT
      oc.IdOrdenCuenta,
      oc.IdOrden,
      oc.NumeroCuenta,
      oc.Nombre,
      oc.Subtotal,
      oc.Impuesto,
      oc.Descuento,
      oc.Propina,
      oc.Total,
      ec.Nombre AS NombreEstado,
      oc.FechaCreacion,
      oc.UsuarioCreacion
    FROM dbo.OrdenCuentas oc
    INNER JOIN dbo.EstadosCuenta ec ON ec.IdEstadoCuenta = oc.IdEstadoCuenta
    WHERE oc.IdOrdenCuenta = @IdOrdenCuenta AND oc.RowStatus = 1;
    RETURN;
  END
END
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentaDetalleCRUD
  @Accion CHAR(1),
  @IdOrdenCuentaDetalle INT = NULL,
  @IdOrdenCuenta INT = NULL,
  @IdOrdenDetalle INT = NULL,
  @CantidadAsignada DECIMAL(12,2) = NULL,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @PrecioUnitario DECIMAL(12,2);
  DECLARE @PorcentajeImpuesto DECIMAL(5,2);
  DECLARE @SubtotalLinea DECIMAL(12,2);
  DECLARE @MontoImpuesto DECIMAL(12,2);
  DECLARE @TotalLinea DECIMAL(12,2);
  DECLARE @CuentaRecalculo INT;

  IF @Accion = 'I'
  BEGIN
    SELECT
      @PrecioUnitario = od.PrecioUnitario,
      @PorcentajeImpuesto = od.PorcentajeImpuesto
    FROM dbo.OrdenesDetalle od
    WHERE od.IdOrdenDetalle = @IdOrdenDetalle AND od.RowStatus = 1;

    SET @SubtotalLinea = @CantidadAsignada * ISNULL(@PrecioUnitario, 0);
    SET @MontoImpuesto = @SubtotalLinea * ISNULL(@PorcentajeImpuesto, 0) / 100;
    SET @TotalLinea = @SubtotalLinea + @MontoImpuesto;

    INSERT INTO dbo.OrdenCuentaDetalle (
      IdOrdenCuenta, IdOrdenDetalle, CantidadAsignada,
      SubtotalLinea, MontoImpuesto, TotalLinea, UsuarioCreacion
    )
    VALUES (
      @IdOrdenCuenta, @IdOrdenDetalle, @CantidadAsignada,
      @SubtotalLinea, @MontoImpuesto, @TotalLinea, @UsuarioModificacion
    );

    EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta = @IdOrdenCuenta, @UsuarioModificacion = @UsuarioModificacion;
    SELECT SCOPE_IDENTITY() AS IdOrdenCuentaDetalle;
    RETURN;
  END

  IF @Accion = 'A'
  BEGIN
    SELECT
      @CuentaRecalculo = ocd.IdOrdenCuenta,
      @PrecioUnitario = od.PrecioUnitario,
      @PorcentajeImpuesto = od.PorcentajeImpuesto
    FROM dbo.OrdenCuentaDetalle ocd
    INNER JOIN dbo.OrdenesDetalle od ON od.IdOrdenDetalle = ocd.IdOrdenDetalle
    WHERE ocd.IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle;

    SET @SubtotalLinea = @CantidadAsignada * ISNULL(@PrecioUnitario, 0);
    SET @MontoImpuesto = @SubtotalLinea * ISNULL(@PorcentajeImpuesto, 0) / 100;
    SET @TotalLinea = @SubtotalLinea + @MontoImpuesto;

    UPDATE dbo.OrdenCuentaDetalle
    SET
      CantidadAsignada = @CantidadAsignada,
      SubtotalLinea = @SubtotalLinea,
      MontoImpuesto = @MontoImpuesto,
      TotalLinea = @TotalLinea,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle AND RowStatus = 1;

    EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta = @CuentaRecalculo, @UsuarioModificacion = @UsuarioModificacion;
    RETURN;
  END

  IF @Accion = 'D'
  BEGIN
    SELECT @CuentaRecalculo = IdOrdenCuenta
    FROM dbo.OrdenCuentaDetalle
    WHERE IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle;

    UPDATE dbo.OrdenCuentaDetalle
    SET
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle AND RowStatus = 1;

    EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta = @CuentaRecalculo, @UsuarioModificacion = @UsuarioModificacion;
    RETURN;
  END

  IF @Accion = 'L'
  BEGIN
    SELECT
      ocd.IdOrdenCuentaDetalle,
      ocd.IdOrdenDetalle,
      ocd.CantidadAsignada,
      od.Cantidad,
      od.PrecioUnitario,
      od.PorcentajeImpuesto,
      ocd.SubtotalLinea,
      ocd.MontoImpuesto,
      ocd.TotalLinea,
      p.Codigo,
      p.Descripcion
    FROM dbo.OrdenCuentaDetalle ocd
    INNER JOIN dbo.OrdenesDetalle od ON od.IdOrdenDetalle = ocd.IdOrdenDetalle
    INNER JOIN dbo.Productos p ON p.IdProducto = od.IdProducto
    WHERE ocd.IdOrdenCuenta = @IdOrdenCuenta AND ocd.RowStatus = 1
    ORDER BY ocd.FechaCreacion;
    RETURN;
  END
END
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasDividir
  @IdOrden INT,
  @ModoDivision VARCHAR(20),
  @CantidadSubcuentas INT = NULL,
  @PayloadJson NVARCHAR(MAX) = NULL,
  @Observacion VARCHAR(500) = NULL,
  @UsuarioCreacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @IdEstadoAbierta INT;
  DECLARE @NumPersona INT;
  DECLARE @NumeroCuenta INT;
  DECLARE @IdOrdenCuenta INT;
  DECLARE @IdOrdenDetalle INT;
  DECLARE @CantidadDisponible DECIMAL(12,2);
  DECLARE @CantidadParcial DECIMAL(12,4);
  DECLARE @CantidadAcumulada DECIMAL(12,4);
  DECLARE @contador INT;
  DECLARE @TipoMovimiento VARCHAR(50);

  SELECT @IdEstadoAbierta = IdEstadoCuenta FROM dbo.EstadosCuenta WHERE Nombre = 'Abierta';

  IF @ModoDivision IN ('PERSONA', 'EQUITATIVA')
  BEGIN
    DELETE ocd
    FROM dbo.OrdenCuentaDetalle ocd
    INNER JOIN dbo.OrdenCuentas oc ON oc.IdOrdenCuenta = ocd.IdOrdenCuenta
    WHERE oc.IdOrden = @IdOrden;

    DELETE FROM dbo.OrdenCuentas
    WHERE IdOrden = @IdOrden;
  END

  IF @ModoDivision = 'PERSONA'
  BEGIN
    IF OBJECT_ID('tempdb..#Personas') IS NOT NULL DROP TABLE #Personas;
    SELECT DISTINCT NumeroPersona INTO #Personas
    FROM dbo.OrdenesDetalle
    WHERE IdOrden = @IdOrden AND RowStatus = 1 AND NumeroPersona IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM #Personas)
      THROW 50063, 'No hay personas asignadas en la orden para dividir por persona.', 1;

    SET @NumeroCuenta = 0;
    DECLARE cur_personas CURSOR LOCAL FAST_FORWARD FOR SELECT NumeroPersona FROM #Personas ORDER BY NumeroPersona;
    OPEN cur_personas;
    FETCH NEXT FROM cur_personas INTO @NumPersona;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @NumeroCuenta = @NumeroCuenta + 1;

      INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
      VALUES (@IdOrden, @NumeroCuenta, CONCAT('Persona ', @NumPersona), @IdEstadoAbierta, @UsuarioCreacion);

      SET @IdOrdenCuenta = SCOPE_IDENTITY();

      DECLARE cur_items CURSOR LOCAL FAST_FORWARD FOR
        SELECT IdOrdenDetalle, Cantidad
        FROM dbo.OrdenesDetalle
        WHERE IdOrden = @IdOrden AND NumeroPersona = @NumPersona AND RowStatus = 1;
      OPEN cur_items;
      FETCH NEXT FROM cur_items INTO @IdOrdenDetalle, @CantidadDisponible;

      WHILE @@FETCH_STATUS = 0
      BEGIN
        EXEC dbo.spOrdenCuentaDetalleCRUD
          @Accion='I',
          @IdOrdenCuenta=@IdOrdenCuenta,
          @IdOrdenDetalle=@IdOrdenDetalle,
          @CantidadAsignada=@CantidadDisponible,
          @UsuarioModificacion=@UsuarioCreacion;
        FETCH NEXT FROM cur_items INTO @IdOrdenDetalle, @CantidadDisponible;
      END
      CLOSE cur_items;
      DEALLOCATE cur_items;

      FETCH NEXT FROM cur_personas INTO @NumPersona;
    END

    CLOSE cur_personas;
    DEALLOCATE cur_personas;
    DROP TABLE #Personas;
  END
  ELSE IF @ModoDivision = 'EQUITATIVA'
  BEGIN
    IF ISNULL(@CantidadSubcuentas, 0) < 2
      THROW 50060, 'La division equitativa requiere al menos 2 subcuentas.', 1;

    SET @contador = 1;
    WHILE @contador <= @CantidadSubcuentas
    BEGIN
      INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
      VALUES (@IdOrden, @contador, CONCAT('Cuenta ', @contador), @IdEstadoAbierta, @UsuarioCreacion);
      SET @contador = @contador + 1;
    END

    DECLARE cur_items_eq CURSOR LOCAL FAST_FORWARD FOR
      SELECT IdOrdenDetalle, Cantidad
      FROM dbo.OrdenesDetalle
      WHERE IdOrden = @IdOrden AND RowStatus = 1;
    OPEN cur_items_eq;
    FETCH NEXT FROM cur_items_eq INTO @IdOrdenDetalle, @CantidadDisponible;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @contador = 1;
      SET @CantidadAcumulada = 0;

      WHILE @contador < @CantidadSubcuentas
      BEGIN
        SET @CantidadParcial = FLOOR((@CantidadDisponible / @CantidadSubcuentas) * 10000) / 10000;
        SELECT @IdOrdenCuenta = IdOrdenCuenta
        FROM dbo.OrdenCuentas
        WHERE IdOrden = @IdOrden AND NumeroCuenta = @contador AND RowStatus = 1;

        EXEC dbo.spOrdenCuentaDetalleCRUD
          @Accion='I',
          @IdOrdenCuenta=@IdOrdenCuenta,
          @IdOrdenDetalle=@IdOrdenDetalle,
          @CantidadAsignada=@CantidadParcial,
          @UsuarioModificacion=@UsuarioCreacion;

        SET @CantidadAcumulada = @CantidadAcumulada + @CantidadParcial;
        SET @contador = @contador + 1;
      END

      SET @CantidadParcial = @CantidadDisponible - @CantidadAcumulada;
      SELECT @IdOrdenCuenta = IdOrdenCuenta
      FROM dbo.OrdenCuentas
      WHERE IdOrden = @IdOrden AND NumeroCuenta = @CantidadSubcuentas AND RowStatus = 1;

      EXEC dbo.spOrdenCuentaDetalleCRUD
        @Accion='I',
        @IdOrdenCuenta=@IdOrdenCuenta,
        @IdOrdenDetalle=@IdOrdenDetalle,
        @CantidadAsignada=@CantidadParcial,
        @UsuarioModificacion=@UsuarioCreacion;

      FETCH NEXT FROM cur_items_eq INTO @IdOrdenDetalle, @CantidadDisponible;
    END

    CLOSE cur_items_eq;
    DEALLOCATE cur_items_eq;
  END
  ELSE IF @ModoDivision = 'ITEM'
  BEGIN
    THROW 50061, 'El modo ITEM aun no esta desplegado en esta base.', 1;
  END
  ELSE IF @ModoDivision = 'UNIFICAR'
  BEGIN
    THROW 50062, 'El modo UNIFICAR aun no esta desplegado en esta base.', 1;
  END

  SET @TipoMovimiento = 'DIVIDIR_' + ISNULL(@ModoDivision, '');

  EXEC dbo.spOrdenCuentasRegistrarMovimiento
    @IdOrden = @IdOrden,
    @IdOrdenCuenta = NULL,
    @TipoMovimiento = @TipoMovimiento,
    @Observacion = @Observacion,
    @UsuarioCreacion = @UsuarioCreacion;
END
GO

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasPrefactura
  @IdOrdenCuenta INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    oc.IdOrdenCuenta,
    oc.IdOrden,
    oc.NumeroCuenta,
    oc.Nombre,
    o.NumeroOrden,
    o.ReferenciaCliente,
    r.Nombre AS NombreMesa,
    oc.Subtotal,
    oc.Impuesto,
    oc.Descuento,
    oc.Propina,
    oc.Total,
    ec.Nombre AS EstadoCuenta,
    oc.FechaCreacion,
    u.NombreUsuario AS UsuarioCreacion
  FROM dbo.OrdenCuentas oc
  INNER JOIN dbo.Ordenes o ON o.IdOrden = oc.IdOrden
  LEFT JOIN dbo.Recursos r ON r.IdRecurso = o.IdRecurso
  INNER JOIN dbo.EstadosCuenta ec ON ec.IdEstadoCuenta = oc.IdEstadoCuenta
  LEFT JOIN dbo.Usuarios u ON u.IdUsuario = oc.UsuarioCreacion
  WHERE oc.IdOrdenCuenta = @IdOrdenCuenta AND oc.RowStatus = 1;

  SELECT
    p.Codigo,
    p.Descripcion,
    ocd.CantidadAsignada,
    ocd.SubtotalLinea,
    ocd.MontoImpuesto,
    ocd.TotalLinea
  FROM dbo.OrdenCuentaDetalle ocd
  INNER JOIN dbo.OrdenesDetalle od ON od.IdOrdenDetalle = ocd.IdOrdenDetalle
  INNER JOIN dbo.Productos p ON p.IdProducto = od.IdProducto
  WHERE ocd.IdOrdenCuenta = @IdOrdenCuenta AND ocd.RowStatus = 1
  ORDER BY ocd.FechaCreacion;
END
GO

PRINT '=== Script 95: Fix OrdenCuentas / Prefactura completado ===';
GO
