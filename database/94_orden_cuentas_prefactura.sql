USE DbMasuPOS;
GO

SET NOCOUNT ON;
GO

PRINT '=== Script 94: Division de Cuentas - Tablas, SPs y Prefactura ===';
GO

-- ============================================================================
-- 1. TABLA: EstadosCuenta
-- ============================================================================

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

-- Seed: Estados de subcuenta
IF NOT EXISTS (SELECT 1 FROM dbo.EstadosCuenta WHERE Nombre = 'Abierta')
BEGIN
  INSERT INTO dbo.EstadosCuenta (Nombre, Descripcion)
  VALUES
    ('Abierta', 'Subcuenta disponible para edicion'),
    ('EnCaja', 'Enviada a caja, bloqueada para operacion'),
    ('Anulada', 'Cancelada por usuario');
END
GO

-- ============================================================================
-- 2. TABLA: OrdenCuentas
-- ============================================================================

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
    CONSTRAINT FK_OrdenCuentas_Estado FOREIGN KEY (IdEstadoCuenta) REFERENCES dbo.EstadosCuenta (IdEstadoCuenta),
    CONSTRAINT UX_OrdenCuentas_NumeroUnico UNIQUE (IdOrden, NumeroCuenta) WHERE RowStatus = 1
  );
END
GO

CREATE INDEX IX_OrdenCuentas_IdOrden ON dbo.OrdenCuentas (IdOrden) WHERE RowStatus = 1;
GO

-- ============================================================================
-- 3. TABLA: OrdenCuentaDetalle
-- ============================================================================

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

    CONSTRAINT FK_OrdenCuentaDetalle_Cuenta FOREIGN KEY (IdOrdenCuenta) REFERENCES dbo.OrdenCuentas (IdOrdenCuenta),
    CONSTRAINT FK_OrdenCuentaDetalle_Detalle FOREIGN KEY (IdOrdenDetalle) REFERENCES dbo.OrdenesDetalle (IdOrdenDetalle)
  );
END
GO

CREATE INDEX IX_OrdenCuentaDetalle_Cuenta ON dbo.OrdenCuentaDetalle (IdOrdenCuenta) WHERE RowStatus = 1;
CREATE INDEX IX_OrdenCuentaDetalle_Detalle ON dbo.OrdenCuentaDetalle (IdOrdenDetalle) WHERE RowStatus = 1;
GO

-- ============================================================================
-- 4. TABLA: OrdenCuentaMovimientos
-- ============================================================================

IF OBJECT_ID('dbo.OrdenCuentaMovimientos', 'U') IS NULL
BEGIN
  CREATE TABLE dbo.OrdenCuentaMovimientos (
    IdOrdenCuentaMovimiento INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    IdOrdenCuenta INT NOT NULL,
    IdOrden INT NOT NULL,
    TipoMovimiento VARCHAR(50) NOT NULL,
    Observacion VARCHAR(500) NULL,
    FechaMovimiento DATETIME NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_FechaMovimiento DEFAULT (GETDATE()),
    UsuarioMovimiento INT NULL,
    Activo BIT NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_Activo DEFAULT (1),
    RowStatus BIT NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_RowStatus DEFAULT (1),
    FechaCreacion DATETIME NOT NULL CONSTRAINT DF_OrdenCuentaMovimientos_FechaCreacion DEFAULT (GETDATE()),
    UsuarioCreacion INT NULL,

    CONSTRAINT FK_OrdenCuentaMovimientos_Cuenta FOREIGN KEY (IdOrdenCuenta) REFERENCES dbo.OrdenCuentas (IdOrdenCuenta),
    CONSTRAINT FK_OrdenCuentaMovimientos_Orden FOREIGN KEY (IdOrden) REFERENCES dbo.Ordenes (IdOrden)
  );
END
GO

CREATE INDEX IX_OrdenCuentaMovimientos_Orden ON dbo.OrdenCuentaMovimientos (IdOrden) WHERE RowStatus = 1;
GO

-- ============================================================================
-- 5. SP: spOrdenCuentasCRUD
-- ============================================================================

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
    -- Insertar nueva cuenta
    INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
    VALUES (@IdOrden, @NumeroCuenta, @Nombre, @IdEstadoCuenta, @UsuarioModificacion);

    SELECT IdOrdenCuenta FROM dbo.OrdenCuentas
    WHERE IdOrden = @IdOrden AND NumeroCuenta = @NumeroCuenta AND RowStatus = 1;
  END

  ELSE IF @Accion = 'A'
  BEGIN
    -- Actualizar cuenta (solo si no esta EnCaja, salvo supervisor)
    UPDATE dbo.OrdenCuentas
    SET
      Nombre = ISNULL(@Nombre, Nombre),
      IdEstadoCuenta = ISNULL(@IdEstadoCuenta, IdEstadoCuenta),
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenCuenta = @IdOrdenCuenta AND RowStatus = 1;
  END

  ELSE IF @Accion = 'X'
  BEGIN
    -- Anular cuenta
    UPDATE dbo.OrdenCuentas
    SET
      RowStatus = 0,
      FechaModificacion = GETDATE(),
      UsuarioModificacion = @UsuarioModificacion
    WHERE IdOrdenCuenta = @IdOrdenCuenta;
  END

  ELSE IF @Accion = 'L'
  BEGIN
    -- Listar cuentas de una orden
    SELECT
      IdOrdenCuenta, IdOrden, NumeroCuenta, Nombre,
      Subtotal, Impuesto, Descuento, Propina, Total,
      (SELECT Nombre FROM dbo.EstadosCuenta WHERE IdEstadoCuenta = oc.IdEstadoCuenta) AS NombreEstado,
      FechaCreacion, UsuarioCreacion
    FROM dbo.OrdenCuentas oc
    WHERE IdOrden = @IdOrden AND oc.RowStatus = 1
    ORDER BY NumeroCuenta;
  END

  ELSE IF @Accion = 'O'
  BEGIN
    -- Obtener cuenta + detalle
    SELECT
      IdOrdenCuenta, IdOrden, NumeroCuenta, Nombre,
      Subtotal, Impuesto, Descuento, Propina, Total,
      (SELECT Nombre FROM dbo.EstadosCuenta WHERE IdEstadoCuenta = oc.IdEstadoCuenta) AS NombreEstado,
      FechaCreacion, UsuarioCreacion
    FROM dbo.OrdenCuentas oc
    WHERE IdOrdenCuenta = @IdOrdenCuenta AND oc.RowStatus = 1;
  END
END
GO

-- ============================================================================
-- 6. SP: spOrdenCuentaDetalleCRUD
-- ============================================================================

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

  IF @Accion = 'I'
  BEGIN
    -- Obtener datos del item original
    SELECT
      @PrecioUnitario = PrecioUnitario,
      @PorcentajeImpuesto = PorcentajeImpuesto
    FROM dbo.OrdenesDetalle
    WHERE IdOrdenDetalle = @IdOrdenDetalle AND RowStatus = 1;

    -- Calcular linea
    SET @SubtotalLinea = @CantidadAsignada * @PrecioUnitario;
    SET @MontoImpuesto = @SubtotalLinea * @PorcentajeImpuesto / 100;
    SET @TotalLinea = @SubtotalLinea + @MontoImpuesto;

    -- Insertar
    INSERT INTO dbo.OrdenCuentaDetalle (
      IdOrdenCuenta, IdOrdenDetalle, CantidadAsignada,
      SubtotalLinea, MontoImpuesto, TotalLinea, UsuarioCreacion
    )
    VALUES (
      @IdOrdenCuenta, @IdOrdenDetalle, @CantidadAsignada,
      @SubtotalLinea, @MontoImpuesto, @TotalLinea, @UsuarioModificacion
    );

    SELECT IdOrdenCuentaDetalle FROM dbo.OrdenCuentaDetalle
    WHERE IdOrdenCuenta = @IdOrdenCuenta AND IdOrdenDetalle = @IdOrdenDetalle AND RowStatus = 1;
  END

  ELSE IF @Accion = 'A'
  BEGIN
    -- Actualizar cantidad asignada
    SELECT
      @PrecioUnitario = PrecioUnitario,
      @PorcentajeImpuesto = PorcentajeImpuesto
    FROM dbo.OrdenesDetalle
    WHERE IdOrdenDetalle = (SELECT IdOrdenDetalle FROM dbo.OrdenCuentaDetalle WHERE IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle);

    SET @SubtotalLinea = @CantidadAsignada * @PrecioUnitario;
    SET @MontoImpuesto = @SubtotalLinea * @PorcentajeImpuesto / 100;
    SET @TotalLinea = @SubtotalLinea + @MontoImpuesto;

    UPDATE dbo.OrdenCuentaDetalle
    SET
      CantidadAsignada = @CantidadAsignada,
      SubtotalLinea = @SubtotalLinea,
      MontoImpuesto = @MontoImpuesto,
      TotalLinea = @TotalLinea
    WHERE IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle;
  END

  ELSE IF @Accion = 'D'
  BEGIN
    -- Eliminar asignacion
    UPDATE dbo.OrdenCuentaDetalle
    SET RowStatus = 0
    WHERE IdOrdenCuentaDetalle = @IdOrdenCuentaDetalle;
  END

  ELSE IF @Accion = 'L'
  BEGIN
    -- Listar items asignados a cuenta
    SELECT
      ocd.IdOrdenCuentaDetalle, ocd.IdOrdenDetalle, ocd.CantidadAsignada,
      od.Cantidad, od.PrecioUnitario, od.PorcentajeImpuesto,
      ocd.SubtotalLinea, ocd.MontoImpuesto, ocd.TotalLinea,
      p.Codigo, p.Descripcion
    FROM dbo.OrdenCuentaDetalle ocd
    JOIN dbo.OrdenesDetalle od ON ocd.IdOrdenDetalle = od.IdOrdenDetalle
    JOIN dbo.Productos p ON od.IdProducto = p.IdProducto
    WHERE ocd.IdOrdenCuenta = @IdOrdenCuenta AND ocd.RowStatus = 1
    ORDER BY ocd.FechaCreacion;
  END
END
GO

-- ============================================================================
-- 7. SP: spOrdenCuentasRecalcular
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasRecalcular
  @IdOrdenCuenta INT,
  @UsuarioModificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Subtotal DECIMAL(12,2) = 0;
  DECLARE @Impuesto DECIMAL(12,2) = 0;
  DECLARE @Total DECIMAL(12,2) = 0;

  -- Sumar detalles
  SELECT
    @Subtotal = ISNULL(SUM(SubtotalLinea), 0),
    @Impuesto = ISNULL(SUM(MontoImpuesto), 0)
  FROM dbo.OrdenCuentaDetalle
  WHERE IdOrdenCuenta = @IdOrdenCuenta AND RowStatus = 1;

  SET @Total = @Subtotal + @Impuesto;

  -- Actualizar cuenta
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

-- ============================================================================
-- 8. SP: spOrdenCuentasDividir (PERSONA, EQUITATIVA, ITEM, UNIFICAR)
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasDividir
  @IdOrden INT,
  @ModoDivision VARCHAR(20),  -- 'PERSONA', 'EQUITATIVA', 'ITEM', 'UNIFICAR'
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
  DECLARE @CantidadPorCuenta DECIMAL(12,2);
  DECLARE @contador INT;
  DECLARE @sumAsignado DECIMAL(12,2);
  DECLARE @SaldoRedondeo DECIMAL(12,2);

  -- Obtener estado Abierta
  SELECT @IdEstadoAbierta = IdEstadoCuenta FROM dbo.EstadosCuenta WHERE Nombre = 'Abierta';

  IF @ModoDivision = 'PERSONA'
  BEGIN
    -- Agrupar por NumeroPersona
    SELECT DISTINCT NumeroPersona INTO #Personas
    FROM dbo.OrdenesDetalle
    WHERE IdOrden = @IdOrden AND RowStatus = 1 AND NumeroPersona IS NOT NULL;

    SET @NumeroCuenta = 0;

    DECLARE cur_personas CURSOR FOR SELECT NumeroPersona FROM #Personas;
    OPEN cur_personas;
    FETCH NEXT FROM cur_personas INTO @NumPersona;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @NumeroCuenta = @NumeroCuenta + 1;

      -- Crear subcuenta
      INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
      VALUES (@IdOrden, @NumeroCuenta, CONCAT('Persona ', @NumPersona), @IdEstadoAbierta, @UsuarioCreacion);

      SET @IdOrdenCuenta = SCOPE_IDENTITY();

      -- Asignar items de esa persona
      DECLARE cur_items CURSOR FOR
        SELECT IdOrdenDetalle, Cantidad FROM dbo.OrdenesDetalle
        WHERE IdOrden = @IdOrden AND NumeroPersona = @NumPersona AND RowStatus = 1;
      OPEN cur_items;
      FETCH NEXT FROM cur_items INTO @IdOrdenDetalle, @CantidadDisponible;

      WHILE @@FETCH_STATUS = 0
      BEGIN
        EXEC dbo.spOrdenCuentaDetalleCRUD @Accion='I', @IdOrdenCuenta=@IdOrdenCuenta,
          @IdOrdenDetalle=@IdOrdenDetalle, @CantidadAsignada=@CantidadDisponible, @UsuarioModificacion=@UsuarioCreacion;
        FETCH NEXT FROM cur_items INTO @IdOrdenDetalle, @CantidadDisponible;
      END
      CLOSE cur_items;
      DEALLOCATE cur_items;

      -- Recalcular
      EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta=@IdOrdenCuenta, @UsuarioModificacion=@UsuarioCreacion;

      FETCH NEXT FROM cur_personas INTO @NumPersona;
    END
    CLOSE cur_personas;
    DEALLOCATE cur_personas;
    DROP TABLE #Personas;
  END

  ELSE IF @ModoDivision = 'EQUITATIVA'
  BEGIN
    -- Crear N cuentas vacias, luego asignar cada item prorratadamente
    SET @contador = 1;
    WHILE @contador <= @CantidadSubcuentas
    BEGIN
      INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
      VALUES (@IdOrden, @contador, CONCAT('Cuenta ', @contador), @IdEstadoAbierta, @UsuarioCreacion);

      SET @contador = @contador + 1;
    END

    -- Asignar items prorratadamente a cada cuenta
    DECLARE cur_items_eq CURSOR FOR
      SELECT IdOrdenDetalle, Cantidad FROM dbo.OrdenesDetalle
      WHERE IdOrden = @IdOrden AND RowStatus = 1;
    OPEN cur_items_eq;
    FETCH NEXT FROM cur_items_eq INTO @IdOrdenDetalle, @CantidadDisponible;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @contador = 1;
      DECLARE @CantidadAcumulada DECIMAL(12,2) = 0;

      -- Para cuentas 1..N-1: FLOOR(Cantidad/@CantidadSubcuentas * 10000)/10000
      WHILE @contador < @CantidadSubcuentas
      BEGIN
        SET @CantidadParcial = FLOOR(@CantidadDisponible / @CantidadSubcuentas * 10000) / 10000;

        -- Obtener IdOrdenCuenta de esta cuenta
        SELECT @IdOrdenCuenta = IdOrdenCuenta FROM dbo.OrdenCuentas
        WHERE IdOrden = @IdOrden AND NumeroCuenta = @contador AND RowStatus = 1;

        EXEC dbo.spOrdenCuentaDetalleCRUD @Accion='I', @IdOrdenCuenta=@IdOrdenCuenta,
          @IdOrdenDetalle=@IdOrdenDetalle, @CantidadAsignada=@CantidadParcial, @UsuarioModificacion=@UsuarioCreacion;

        SET @CantidadAcumulada = @CantidadAcumulada + @CantidadParcial;
        SET @contador = @contador + 1;
      END

      -- Ultima cuenta: recibe el resto exacto
      SET @CantidadParcial = @CantidadDisponible - @CantidadAcumulada;
      SELECT @IdOrdenCuenta = IdOrdenCuenta FROM dbo.OrdenCuentas
      WHERE IdOrden = @IdOrden AND NumeroCuenta = @CantidadSubcuentas AND RowStatus = 1;

      EXEC dbo.spOrdenCuentaDetalleCRUD @Accion='I', @IdOrdenCuenta=@IdOrdenCuenta,
        @IdOrdenDetalle=@IdOrdenDetalle, @CantidadAsignada=@CantidadParcial, @UsuarioModificacion=@UsuarioCreacion;

      FETCH NEXT FROM cur_items_eq INTO @IdOrdenDetalle, @CantidadDisponible;
    END
    CLOSE cur_items_eq;
    DEALLOCATE cur_items_eq;

    -- Recalcular todas las cuentas creadas
    DECLARE cur_cuentas_eq CURSOR FOR
      SELECT IdOrdenCuenta FROM dbo.OrdenCuentas WHERE IdOrden = @IdOrden AND RowStatus = 1;
    OPEN cur_cuentas_eq;
    FETCH NEXT FROM cur_cuentas_eq INTO @IdOrdenCuenta;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta=@IdOrdenCuenta, @UsuarioModificacion=@UsuarioCreacion;
      FETCH NEXT FROM cur_cuentas_eq INTO @IdOrdenCuenta;
    END
    CLOSE cur_cuentas_eq;
    DEALLOCATE cur_cuentas_eq;
  END

  ELSE IF @ModoDivision = 'ITEM'
  BEGIN
    -- Payload: { "cuentas": [{ "nombre": "Juan|null", "items": [{ "idOrdenDetalle": 10, "cantidadAsignada": 2.0 }] }] }
    DECLARE @cta_index INT = 0;
    DECLARE @cta_nombre NVARCHAR(100);
    DECLARE @item_index INT = 0;
    DECLARE @item_idOrdenDetalle INT;
    DECLARE @item_cantidadAsignada DECIMAL(12,2);

    -- Crear cuentas desde payload
    DECLARE cur_ctas CURSOR FOR
      SELECT [key], JSON_VALUE([value], '$.nombre') as nombre FROM OPENJSON(@PayloadJson, '$.cuentas') WITH (nombre NVARCHAR(100) '$.nombre')
      WHERE [value] IS NOT NULL;

    OPEN cur_ctas;
    FETCH NEXT FROM cur_ctas INTO @cta_index, @cta_nombre;

    SET @NumeroCuenta = 0;
    WHILE @@FETCH_STATUS = 0
    BEGIN
      SET @NumeroCuenta = @NumeroCuenta + 1;

      INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
      VALUES (@IdOrden, @NumeroCuenta, @cta_nombre, @IdEstadoAbierta, @UsuarioCreacion);

      SET @IdOrdenCuenta = SCOPE_IDENTITY();

      -- Asignar items de esta cuenta desde payload
      DECLARE cur_items_payload CURSOR FOR
        SELECT JSON_VALUE(item_value, '$.idOrdenDetalle') as idOrdenDetalle,
               JSON_VALUE(item_value, '$.cantidadAsignada') as cantidadAsignada
        FROM OPENJSON(@PayloadJson, CONCAT('$.cuentas[', @cta_index, '].items')) AS item_value
        WHERE item_value IS NOT NULL;

      OPEN cur_items_payload;
      FETCH NEXT FROM cur_items_payload INTO @item_idOrdenDetalle, @item_cantidadAsignada;

      WHILE @@FETCH_STATUS = 0
      BEGIN
        EXEC dbo.spOrdenCuentaDetalleCRUD @Accion='I', @IdOrdenCuenta=@IdOrdenCuenta,
          @IdOrdenDetalle=@item_idOrdenDetalle, @CantidadAsignada=@item_cantidadAsignada, @UsuarioModificacion=@UsuarioCreacion;

        FETCH NEXT FROM cur_items_payload INTO @item_idOrdenDetalle, @item_cantidadAsignada;
      END
      CLOSE cur_items_payload;
      DEALLOCATE cur_items_payload;

      -- Recalcular
      EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta=@IdOrdenCuenta, @UsuarioModificacion=@UsuarioCreacion;

      FETCH NEXT FROM cur_ctas INTO @cta_index, @cta_nombre;
    END
    CLOSE cur_ctas;
    DEALLOCATE cur_ctas;
  END

  ELSE IF @ModoDivision = 'UNIFICAR'
  BEGIN
    -- Payload: { "cuentas": [idCuenta1, idCuenta2, ...] }
    -- Crear nueva cuenta, mover items, soft-delete cuentas originales
    DECLARE @MaxNumeroCuenta INT;
    DECLARE @CuentaUnificada INT;
    DECLARE @CuentaOriginal INT;

    -- Obtener MAX numero de cuenta actual
    SELECT @MaxNumeroCuenta = ISNULL(MAX(NumeroCuenta), 0) FROM dbo.OrdenCuentas WHERE IdOrden = @IdOrden;
    SET @MaxNumeroCuenta = @MaxNumeroCuenta + 1;

    -- Crear nueva cuenta unificada
    INSERT INTO dbo.OrdenCuentas (IdOrden, NumeroCuenta, Nombre, IdEstadoCuenta, UsuarioCreacion)
    VALUES (@IdOrden, @MaxNumeroCuenta, 'Unificada', @IdEstadoAbierta, @UsuarioCreacion);

    SET @CuentaUnificada = SCOPE_IDENTITY();

    -- Reasignar items desde las cuentas a unificar a la nueva cuenta
    DECLARE cur_cuentas_unif CURSOR FOR
      SELECT JSON_VALUE([value], '$') FROM OPENJSON(@PayloadJson, '$.cuentas');

    OPEN cur_cuentas_unif;
    FETCH NEXT FROM cur_cuentas_unif INTO @CuentaOriginal;

    WHILE @@FETCH_STATUS = 0
    BEGIN
      -- Mover todos los OrdenCuentaDetalle activos de la cuenta original a la nueva
      UPDATE dbo.OrdenCuentaDetalle
      SET IdOrdenCuenta = @CuentaUnificada
      WHERE IdOrdenCuenta = @CuentaOriginal AND RowStatus = 1;

      -- Anular la cuenta original
      EXEC dbo.spOrdenCuentasCRUD @Accion='X', @IdOrdenCuenta=@CuentaOriginal, @UsuarioModificacion=@UsuarioCreacion;

      FETCH NEXT FROM cur_cuentas_unif INTO @CuentaOriginal;
    END
    CLOSE cur_cuentas_unif;
    DEALLOCATE cur_cuentas_unif;

    -- Recalcular la cuenta unificada
    EXEC dbo.spOrdenCuentasRecalcular @IdOrdenCuenta=@CuentaUnificada, @UsuarioModificacion=@UsuarioCreacion;
  END

  EXEC dbo.spOrdenCuentasRegistrarMovimiento
    @IdOrden=@IdOrden, @IdOrdenCuenta=NULL, @TipoMovimiento=CONCAT('DIVIDIR_', @ModoDivision),
    @Observacion=@Observacion, @UsuarioCreacion=@UsuarioCreacion;
END
GO

-- ============================================================================
-- 9. SP: spOrdenCuentasRegistrarMovimiento
-- ============================================================================

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

-- ============================================================================
-- 10. SP: spOrdenCuentasPrefactura
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.spOrdenCuentasPrefactura
  @IdOrdenCuenta INT
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    oc.IdOrdenCuenta, oc.IdOrden, oc.NumeroCuenta, oc.Nombre,
    o.NumeroOrden, o.ReferenciaCliente, r.Recurso AS NombreMesa,
    oc.Subtotal, oc.Impuesto, oc.Descuento, oc.Propina, oc.Total,
    (SELECT Nombre FROM dbo.EstadosCuenta WHERE IdEstadoCuenta = oc.IdEstadoCuenta) AS EstadoCuenta,
    oc.FechaCreacion, u.NombreCompleto AS UsuarioCreacion
  FROM dbo.OrdenCuentas oc
  JOIN dbo.Ordenes o ON oc.IdOrden = o.IdOrden
  JOIN dbo.Recursos r ON o.IdRecurso = r.IdRecurso
  LEFT JOIN dbo.Usuarios u ON oc.UsuarioCreacion = u.IdUsuario
  WHERE oc.IdOrdenCuenta = @IdOrdenCuenta AND oc.RowStatus = 1;

  -- Detalle
  SELECT
    p.Codigo, p.Descripcion, ocd.CantidadAsignada,
    ocd.SubtotalLinea, ocd.MontoImpuesto, ocd.TotalLinea
  FROM dbo.OrdenCuentaDetalle ocd
  JOIN dbo.OrdenesDetalle od ON ocd.IdOrdenDetalle = od.IdOrdenDetalle
  JOIN dbo.Productos p ON od.IdProducto = p.IdProducto
  WHERE ocd.IdOrdenCuenta = @IdOrdenCuenta AND ocd.RowStatus = 1
  ORDER BY ocd.FechaCreacion;
END
GO

-- ============================================================================
-- 11. SEED: Permisos nuevos en Pantallas
-- ============================================================================

DECLARE @IdPantalla INT;

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE ClavePermiso = 'orders.split.view')
BEGIN
  INSERT INTO dbo.Pantallas (Nombre, ClavePermiso, Descripcion, Modulo, Activo, RowStatus, UsuarioCreacion)
  VALUES ('Ver Division de Cuentas', 'orders.split.view', 'Ver subcuentas de una orden', 'Ordenes', 1, 1, NULL);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE ClavePermiso = 'orders.split.manage')
BEGIN
  INSERT INTO dbo.Pantallas (Nombre, ClavePermiso, Descripcion, Modulo, Activo, RowStatus, UsuarioCreacion)
  VALUES ('Editar Division de Cuentas', 'orders.split.manage', 'Crear, dividir y unificar cuentas', 'Ordenes', 1, 1, NULL);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE ClavePermiso = 'orders.send-to-cash')
BEGIN
  INSERT INTO dbo.Pantallas (Nombre, ClavePermiso, Descripcion, Modulo, Activo, RowStatus, UsuarioCreacion)
  VALUES ('Enviar a Caja', 'orders.send-to-cash', 'Enviar subcuenta a caja', 'Ordenes', 1, 1, NULL);
END

IF NOT EXISTS (SELECT 1 FROM dbo.Pantallas WHERE ClavePermiso = 'orders.prefactura.view')
BEGIN
  INSERT INTO dbo.Pantallas (Nombre, ClavePermiso, Descripcion, Modulo, Activo, RowStatus, UsuarioCreacion)
  VALUES ('Ver Pre-Factura', 'orders.prefactura.view', 'Ver pre-factura de subcuenta', 'Ordenes', 1, 1, NULL);
END

GO

PRINT '=== Script 94: Completado ===';
GO
