"use client"

import { EntityCrudSection } from "@/components/pos/entity-crud-section"
import type { CatalogMastersData } from "@/lib/pos-data"

type CatalogMasterSection = "categories" | "product-types" | "units"

export function CatalogMastersManager({ data, sections }: { data: CatalogMastersData; sections?: CatalogMasterSection[] }) {
  const visible = new Set(sections ?? ["categories", "product-types", "units"])

  return (
    <div className="management-layout management-layout--stacked">
      {visible.has("categories") ? (
        <EntityCrudSection
          title="Categorias"
          description="CRUD de categorias comerciales."
          entity="categories"
          items={data.categories}
          getId={(item) => item.id}
          columns={[{ header: "Nombre", render: (item) => item.name }, { header: "Descripcion", render: (item) => item.description || "-" }]}
          fields={[{ name: "name", label: "Nombre", type: "text", required: true }, { name: "description", label: "Descripcion", type: "textarea" }, { name: "active", label: "Activo", type: "checkbox" }]}
          toForm={(item) => ({ id: item.id, name: item.name, description: item.description, active: item.active })}
          emptyForm={{ name: "", description: "", active: true }}
        />
      ) : null}

      {visible.has("product-types") ? (
        <EntityCrudSection
          title="Tipos de producto"
          description="CRUD de tipos funcionales del catalogo."
          entity="product-types"
          items={data.productTypes}
          getId={(item) => item.id}
          columns={[{ header: "Nombre", render: (item) => item.name }, { header: "Descripcion", render: (item) => item.description || "-" }]}
          fields={[{ name: "name", label: "Nombre", type: "text", required: true }, { name: "description", label: "Descripcion", type: "textarea" }, { name: "active", label: "Activo", type: "checkbox" }]}
          toForm={(item) => ({ id: item.id, name: item.name, description: item.description, active: item.active })}
          emptyForm={{ name: "", description: "", active: true }}
        />
      ) : null}

      {visible.has("units") ? (
        <EntityCrudSection
          title="Unidades de medida"
          description="CRUD de equivalencias BaseA x BaseB."
          entity="units"
          items={data.units}
          getId={(item) => item.id}
          columns={[{ header: "Nombre", render: (item) => item.name }, { header: "Abrev.", render: (item) => item.abbreviation }, { header: "Factor", render: (item) => item.factor }]}
          fields={[{ name: "name", label: "Nombre", type: "text", required: true }, { name: "abbreviation", label: "Abreviatura", type: "text", required: true }, { name: "baseA", label: "BaseA", type: "number", required: true }, { name: "baseB", label: "BaseB", type: "number", required: true }, { name: "active", label: "Activo", type: "checkbox" }]}
          toForm={(item) => ({ id: item.id, name: item.name, abbreviation: item.abbreviation, baseA: item.baseA, baseB: item.baseB, active: item.active })}
          emptyForm={{ name: "", abbreviation: "", baseA: 1, baseB: 1, active: true }}
        />
      ) : null}
    </div>
  )
}
