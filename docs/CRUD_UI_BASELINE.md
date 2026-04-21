# CRUD UI Baseline

Base visual y de comportamiento para los CRUDs de documentos en MasuPOS.

## Alcance actual

Aplicado como referencia en:

- `Facturas`
- `Entradas de Inventario`
- `Salidas de Inventario`
- `Compras de Inventario`
- `Transferencias de Inventario`

## Reglas de interacción

### Listado

- El detalle solo se abre desde el botón de acción `Visualizar`.
- El número del documento no abre el detalle.
- La fila completa no abre el detalle.
- Las demás acciones (`Editar`, `Imprimir`, `Anular`, etc.) viven únicamente en la columna `Acciones`.

### Topbar de detalle

- Usar la topbar compartida `inv-doc-detail-topbar`.
- Botones con métrica tipo input:
  - altura `2.15rem`
  - radio `0.35rem`
  - texto `0.85rem`
- Mantener `danger-button` para acciones destructivas como `Anular`.

### Filtros y acciones del listado

- Botones de filtro y CTA principales con la misma caja visual que los textbox.
- `Nuevo Documento`, `Actualizar` y `Limpiar` deben usar ancho uniforme.
- La paginación del listado debe usar:
  - `10`
  - `25`
  - `50`
  - `100`
  - `Ver todos`
- Valor por defecto: `10`.

## Clases compartidas

### Topbar detalle

- `inv-doc-detail-topbar`
- `inv-doc-detail-topbar__actions`
- `inv-doc-detail-topbar__cluster`
- `inv-doc-detail-topbar__nav-button`
- `inv-doc-detail-topbar__position`
- `inv-doc-detail-topbar__arrow-button`

### Listado / filtros / paginación

- `inv-doc-screen__action-wide`
- `inv-doc-screen__pagination`
- `inv-doc-screen__pagination-info`
- `inv-doc-screen__pagination-actions`
- `inv-doc-screen__row-actions`

## Checklist para nuevos módulos

1. No abrir detalle por click en fila.
2. No abrir detalle por click en número.
3. Abrir detalle solo desde `Visualizar`.
4. Reutilizar la topbar compacta compartida.
5. Igualar botones de filtros al tamaño de los inputs.
6. Usar paginación estándar con default `10`.
7. Mantener acciones destructivas diferenciadas con `danger-button`.
