# Plan de Implementacion del Modulo de Ordenes

## Contexto
- Proyecto real actual: `Next.js App Router + React + TypeScript + SQL Server`
- Acceso a datos centralizado en `src/lib/pos-data.ts`
- Regla de arquitectura: la logica transaccional debe vivir en stored procedures versionados en `database/`
- Base visual actual del modulo: `src/app/orders/page.tsx` y `src/components/pos/orders-dashboard.tsx`
- Patron UX actual valido: `bandeja por mesa + panel lateral de ordenes abiertas + creacion rapida`

## A. Analisis Funcional del Modulo

### Componentes principales
- Bandeja de mesas o recursos
- Panel lateral de ordenes activas por mesa
- Editor de orden
- Flujo touch para venta rapida
- Historial de ordenes
- Operaciones especiales sobre mesas y cuentas

### Flujos operativos que debe soportar
- Crear, editar, consultar, cancelar, cerrar, facturar y reabrir orden
- Varias ordenes activas por una misma mesa
- Cambio de mesa y transferencia de orden
- Union de ordenes
- Division de cuenta por productos, cliente o porcentaje
- Canal de venta por orden: mesa, para llevar, delivery, barra
- Atencion por camarero y trazabilidad por usuario

### Escenarios reales cubiertos
- Restaurante con multiples tickets por mesa
- Bar con consumo incremental
- Mostrador o barra con venta rapida touch
- Delivery con cliente formal o referencia manual
- Grupos grandes con division de cuenta
- Rotacion de mesas con estado pendiente de limpieza

## B. Diseno de Base de Datos

### Entidades principales
- `Ordenes`
  - encabezado comercial, estado, mesa/recurso, cliente, camarero, canal, moneda, totales, timestamps
- `OrdenesDetalle`
  - lineas de producto, unidad, cantidad, precio, descuento, impuesto, observacion, estado de linea
- `EstadosOrden`
  - `Abierta`, `EnPreparacion`, `Servida`, `EnEspera`, `CuentaSolicitada`, `Facturada`, `Cancelada`, `Reabierta`
- `EstadosDetalleOrden`
  - `Pendiente`, `EnPreparacion`, `Servido`, `Cancelado`
- `EstadosMesa`
  - `Libre`, `Ocupada`, `CuentaSolicitada`, `PendienteLimpieza`, `Bloqueada`
- `OrdenesMovimientos`
  - bitacora de transiciones de negocio
- `TouchCategorias`
  - grupos visuales touch
- `TouchProductosConfiguracion`
  - mapeo categoria touch -> producto
- `OrdenesDetalleModificadores`
  - extras, modificadores y complementos por linea

### Recomendacion clave
- Separar `estado de orden`, `estado de detalle` y `estado de mesa`
- Mantener `Recursos` como base si ya modela mesas; especializar comportamiento desde ordenes

## C. Stored Procedures

### SPs principales sugeridos
- `spOrdenesCRUD`
  - `L`, `O`, `I`, `U`, `D`, `X`, `C`, `R`, `F`
- `spOrdenesDetalleCRUD`
  - `L`, `O`, `I`, `U`, `D`, `X`
- `spOrdenesOperacion`
  - `M` mover mesa
  - `T` transferir orden
  - `J` unir ordenes
  - `P` dividir cuenta
  - `Q` marcar cuenta solicitada
  - `K` enviar a cocina/bar
- `spMesasCRUD` o extension de SPs de recursos
- `spEstadosOrdenCRUD`
- `spEstadosMesaCRUD`
- `spEstadosDetalleOrdenCRUD`
- `spTouchConfigCRUD`
- `spOrdenesDashboard`
- `spOrdenesHistorial`

### Convencion de acciones
- `L` listar
- `O` obtener
- `I` insertar
- `U` actualizar
- `D` eliminar logico
- `X` cancelar
- `C` cerrar
- `R` reabrir
- `F` facturar
- `M` mover
- `T` transferir
- `J` unir
- `P` partir cuenta
- `Q` cuenta solicitada
- `K` enviar a cocina/bar

## D. Backend

### Data layer
- Extender `src/lib/pos-data.ts` con funciones por caso de uso:
  - `getOrdersDashboard`
  - `getOrderById`
  - `listOrders`
  - `createOrder`
  - `updateOrderHeader`
  - `cancelOrder`
  - `closeOrder`
  - `reopenOrder`
  - `moveOrderToResource`
  - `transferOrder`
  - `mergeOrders`
  - `splitOrder`
  - `addOrderLine`
  - `updateOrderLine`
  - `removeOrderLine`
  - `sendOrderToKitchen`
  - `getOrderHistory`
  - `listTouchCategories`
  - `listTouchProductsByCategory`

### API routes sugeridas
- `/api/orders`
- `/api/orders/[id]`
- `/api/orders/[id]/cancel`
- `/api/orders/[id]/close`
- `/api/orders/[id]/reopen`
- `/api/orders/[id]/move`
- `/api/orders/[id]/transfer`
- `/api/orders/[id]/merge`
- `/api/orders/[id]/split`
- `/api/orders/[id]/send-kitchen`
- `/api/orders/history`
- `/api/orders/touch/categories`
- `/api/orders/touch/products`
- `/api/orders/resources/board`

### Permisos sugeridos
- `orders.view`
- `orders.create`
- `orders.edit`
- `orders.cancel`
- `orders.close`
- `orders.reopen`
- `orders.move`
- `orders.transfer`
- `orders.merge`
- `orders.split`
- `orders.kitchen.send`
- `orders.history.view`

## E. Frontend / UX

### Pantallas necesarias
- Dashboard de mesas
- Lista de ordenes activas
- Lista de ordenes cerradas
- Historial de ordenes
- Panel lateral de detalle
- Editor de orden
- Pantalla touch de categorias y productos
- Modal mover orden
- Modal transferir orden
- Modal unir ordenes
- Modal dividir cuenta
- Modal cambiar cliente o referencia

### Lineamientos UX
- Mantener el patron actual `bandeja izquierda + detalle derecha`
- Optimizar para touch con botones grandes
- Resumen de totales siempre visible
- Colores de estado claros por mesa y orden
- Acciones rapidas visibles para operacion: cerrar, mover, dividir, enviar a cocina
- Filtros por area, camarero, canal y estado

## F. Fases de Implementacion

### Fase 1. Base de datos
- modelado de ordenes, detalle, estados, bitacora y touch
- scripts SQL secuenciales en `database/`

### Fase 2. CRUD base de ordenes
- crear, editar, consultar, cancelar, cerrar, reabrir

### Fase 3. Integracion con mesas
- multiples ordenes activas
- estados de mesa
- mover y transferir

### Fase 4. Detalle de productos
- lineas, observaciones, descuentos, impuestos y permisos

### Fase 5. Touch / venta rapida
- categorias touch
- productos touch
- favoritos y productos recientes

### Fase 6. Estados y auditoria
- estados separados
- bitacora
- timestamps y usuario por transicion

### Fase 7. Cierre y facturacion
- cuenta solicitada
- envio a caja
- cierre comercial

### Fase 8. Reportes y consultas
- historial
- tiempos de atencion
- ventas por canal, mesa y camarero

## G. Riesgos y Recomendaciones

### Riesgos
- concurrencia entre camareros sobre la misma orden
- cierre, cancelacion o movimiento simultaneo
- integridad con inventario y caja
- duplicidad o perdida de impresion cocina/bar
- crecimiento funcional distinto entre mesa, delivery y takeout

### Reglas de negocio recomendadas
- no cerrar orden vacia
- no mover orden facturada o cancelada
- no reabrir sin permiso especial
- no mezclar monedas distintas al unir
- no dividir una orden ya enviada a caja sin politica explicita
- no cambiar precios sin permiso granular
- no borrar lineas impresas sin bitacora o reversa
- validar mesa destino segun estado y capacidad

## Tareas Iniciales Propuestas

### Bloque 1. Modelo y base
- `ORD-01` Definir modelo final de `Ordenes`, `OrdenesDetalle`, `EstadosOrden`, `EstadosMesa`, `EstadosDetalleOrden`
- `ORD-02` Diseñar `OrdenesMovimientos` y politica de auditoria
- `ORD-03` Diseñar tablas touch y modificadores
- `ORD-04` Preparar mapa de migraciones SQL del modulo

### Bloque 2. Operacion base
- `ORD-05` Redefinir `spOrdenesCRUD` para cubrir ciclo completo
- `ORD-06` Crear `spOrdenesDetalleCRUD`
- `ORD-07` Crear `spOrdenesDashboard`
- `ORD-08` Exponer APIs base del modulo

### Bloque 3. Mesas y flujo operativo
- `ORD-09` Soportar multiples ordenes activas por mesa
- `ORD-10` Implementar mover y transferir orden
- `ORD-11` Implementar unir ordenes
- `ORD-12` Implementar dividir cuenta

### Bloque 4. Touch y productividad
- `ORD-13` Implementar categorias y productos touch
- `ORD-14` Implementar extras/modificadores
- `ORD-15` Agregar acciones rapidas y permisos en UI

### Bloque 5. Cierre y consulta
- `ORD-16` Implementar cierre/facturacion y cuenta solicitada
- `ORD-17` Implementar reapertura controlada
- `ORD-18` Implementar historial y timeline de movimientos
- `ORD-19` Integrar impresion cocina/bar y puntos de control

## Siguiente Paso Recomendado
- Convertir estas tareas en backlog ejecutable y decidir si el primer entregable sera:
  - `core operativo de ordenes`
  - `mesas + multiples tickets`
  - `touch + venta rapida`
