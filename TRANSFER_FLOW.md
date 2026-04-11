# Flujo de Transferencias de Inventario

## Arquitectura

Las transferencias **NO se guardan en `InvDocumentos`**. Solo usan:
- **`InvTransferencias`**: Tabla de control (metadatos)
- **`InvTransferenciasDetalle`**: Líneas de transferencia
- **`InvMovimientos`**: Registro de movimientos reales

## Estados

| Estado | Código | Descripción |
|--------|--------|-------------|
| Borrador | `B` | Transferencia creada pero no generada |
| En Tránsito | `T` | Salida generada, en almacén de tránsito |
| Completada | `C` | Recepción confirmada en almacén destino |
| Anulada | `N` | Transferencia cancelada |

## Flujo de Estados

```
┌─────────────────────────────────────────────────────────┐
│ 1. CREAR TRANSFERENCIA (Borrador)                       │
│ - Se crea registro en InvTransferencias (EstadoTransf='B')
│ - Se agregan líneas en InvTransferenciasDetalle         │
│ - NO se crean movimientos aún                           │
└─────────────────────────────────────────────────────────┘
                        │
                        ↓ (spInvTransferenciasGenerarSalida)
┌─────────────────────────────────────────────────────────┐
│ 2. GENERAR SALIDA (En Tránsito)                         │
│                                                          │
│ Almacén Origen:                                          │
│  - Se crea movimiento SAL (salida)                       │
│  - Se resta cantidad del stock                           │
│                                                          │
│ Almacén Tránsito:                                        │
│  - Se crea movimiento ENT (entrada)                      │
│  - Se suma cantidad al stock                             │
│                                                          │
│ InvTransferencias.EstadoTransferencia = 'T'              │
└─────────────────────────────────────────────────────────┘
                        │
                        ↓ (spInvTransferenciasConfirmarRecepcion)
┌─────────────────────────────────────────────────────────┐
│ 3. CONFIRMAR RECEPCIÓN (Completada)                     │
│                                                          │
│ Almacén Tránsito:                                        │
│  - Se crea movimiento SAL (salida de tránsito)          │
│  - Se resta cantidad del stock                          │
│                                                          │
│ Almacén Destino:                                         │
│  - Se crea movimiento ENT (entrada)                      │
│  - Se suma cantidad al stock                             │
│                                                          │
│ InvTransferencias.EstadoTransferencia = 'C'              │
└─────────────────────────────────────────────────────────┘
```

## Tablas

### InvTransferencias
- `IdTransferencia` (PK) - ID de la transferencia
- `IdDocumento` - LEGACY (para compatibilidad)
- `IdAlmacenDestino` - Almacén destino
- `IdAlmacenTransito` - Almacén de tránsito del origen
- `EstadoTransferencia` - B/T/C/N
- `FechaSalida` - Fecha de generación de salida
- `FechaRecepcion` - Fecha de confirmación de recepción
- `UsuarioSalida` - Usuario que generó salida
- `UsuarioRecepcion` - Usuario que confirmó recepción
- Campos de auditoría (RowStatus, FechaCreacion, etc.)

### InvTransferenciasDetalle
- `IdDetalle` (PK) - ID de la línea
- `IdTransferencia` (FK) - Referencia a InvTransferencias
- `NumeroLinea` - Número de línea (1, 2, 3...)
- `IdProducto` - Producto a transferir
- `Cantidad` - Cantidad a transferir
- `Costo` - Costo unitario
- `Total` - Costo total de la línea
- Campos de auditoría

### InvMovimientos
Registros de movimientos generados con:
- `TipoDocOrigen = 'TRF'` para transferencias
- `IdDocumentoOrigen = IdTransferencia` para rastrear
- `NumeroDocumento = 'TRF-{IdTransferencia}'` para identificación

## Procedimientos Almacenados

### spInvTransferenciasGenerarSalida
```sql
EXEC dbo.spInvTransferenciasGenerarSalida
  @IdTransferencia = 1,
  @IdAlmacenOrigen = 2,
  @IdUsuario = 1,
  @IdSesion = NULL,
  @Observacion = 'Transferencia de stock'
```

**Precondiciones:**
- EstadoTransferencia = 'B'
- Stock suficiente en almacén origen

**Acciones:**
1. Crea movimiento SAL en almacén origen
2. Crea movimiento ENT en almacén tránsito
3. Actualiza stock en ProductoAlmacenes
4. Cambia estado a 'T'

### spInvTransferenciasConfirmarRecepcion
```sql
EXEC dbo.spInvTransferenciasConfirmarRecepcion
  @IdTransferencia = 1,
  @IdUsuario = 1,
  @IdSesion = NULL,
  @Observacion = 'Recibido sin novedad'
```

**Precondiciones:**
- EstadoTransferencia = 'T'

**Acciones:**
1. Crea movimiento SAL en almacén tránsito
2. Crea movimiento ENT en almacén destino
3. Actualiza stock en ProductoAlmacenes
4. Cambia estado a 'C'

## Movimientos Generados

**En Generar Salida:**
- `TipoMovimiento = 'SAL'` en almacén origen (reduce stock)
- `TipoMovimiento = 'ENT'` en almacén tránsito (aumenta stock)

**En Confirmar Recepción:**
- `TipoMovimiento = 'SAL'` en almacén tránsito (reduce stock)
- `TipoMovimiento = 'ENT'` en almacén destino (aumenta stock)

**Total de movimientos por transferencia:** 4 movimientos (2 al generar, 2 al recibir)

## Inversión de Movimientos

Si se anula una transferencia en estado 'T':
1. Los movimientos SAL/ENT se invierten (se crean movimientos opuestos)
2. El estado cambia a 'N'
3. Los movimientos de la anulación también se registran en InvMovimientos

## Kardex

El kardex muestra:
- Todas las transferencias (identificables por `TipoDocOrigen = 'TRF'`)
- Entrada y salida en cada almacén
- Saldo acumulativo por almacén
- Trazabilidad completa con `IdDocumentoOrigen` y `NumeroDocumento`

## Restricciones y Validaciones

### Transferencias
- ✓ Las transferencias **NO crean registros en InvDocumentos**
- ✓ Solo tabla de control en InvTransferencias
- ✓ Movimientos directos en InvMovimientos
- ✓ Almacén de tránsito es obligatorio por almacén origen
- ✓ **Solo se puede editar en estado 'B'** (Borrador)
  - Una vez generada la salida (estado 'T'), NO se puede editar
  - Usa `spInvTransferenciasActualizar` solo en borrador
- ✓ **Solo se puede anular en estado 'B' o 'T'** (NO en 'C')
  - No se puede anular transferencias completadas
  - Al anular en 'T', se revierten los movimientos de stock
  - Usa `spInvTransferenciasAnular`

### Movimientos de Transferencia
- ✓ **NO se pueden editar** movimientos de transferencia (TipoDocOrigen='TRF')
  - Trigger: `TR_InvMovimientos_PreventirEditTransfer`
- ✓ **NO se pueden eliminar** movimientos de transferencia
  - Trigger: `TR_InvMovimientos_PreventirDeleteTransfer`
- ✓ Para deshacer: Usar `spInvTransferenciasAnular` (solo en B/T)

## Validaciones de Negocio (Triggers)

| Trigger | Tabla | Evento | Condición | Acción |
|---------|-------|--------|-----------|--------|
| `TR_InvMovimientos_PreventirEditTransfer` | InvMovimientos | UPDATE | TipoDocOrigen='TRF' | ROLLBACK con error |
| `TR_InvMovimientos_PreventirDeleteTransfer` | InvMovimientos | DELETE | TipoDocOrigen='TRF' | ROLLBACK con error |
