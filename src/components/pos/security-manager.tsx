"use client"

import { EntityCrudSection } from "@/components/pos/entity-crud-section"
import { SecurityRolesScreen } from "@/components/pos/security-roles-screen"
import type { SecurityManagerData } from "@/lib/pos-data"

type SecuritySection = "users" | "roles" | "modules" | "screens" | "permissions" | "role-permissions"

export function SecurityManager({ data, sections }: { data: SecurityManagerData; sections?: SecuritySection[] }) {
  const visible = new Set(sections ?? ["users", "roles", "modules", "screens", "permissions", "role-permissions"])

  return (
    <div className="management-layout management-layout--stacked">
      {visible.has("users") ? <EntityCrudSection
        title="Usuarios"
        description="CRUD de usuarios del sistema. `ClaveHash` se almacena como valor enviado al SP actual."
        entity="users"
        items={data.users}
        getId={(item) => item.id}
        columns={[{ header: "Usuario", render: (item) => item.userName }, { header: "Nombres", render: (item) => `${item.names} ${item.surnames}` }, { header: "Tipo", render: (item) => item.userType }, { header: "Rol", render: (item) => item.roleName }, { header: "Inicio", render: (item) => item.startScreen || item.startRoute || "/" }, { header: "Correo", render: (item) => item.email || "-" }]}
        fields={[
          { name: "names", label: "Nombres", type: "text", required: true },
          { name: "surnames", label: "Apellidos", type: "text", required: true },
          { name: "userName", label: "Nombre de usuario", type: "text", required: true },
          { name: "userType", label: "Tipo de usuario", type: "select", required: true, options: [{ value: "A", label: "A · Administrador" }, { value: "S", label: "S · Supervisor" }, { value: "O", label: "O · Operativo" }] },
          { name: "roleId", label: "Rol", type: "select", required: true, options: data.lookups.roles.map((item) => ({ value: String(item.id), label: item.name })) },
          { name: "startScreenId", label: "Pantalla de inicio", type: "select", options: data.lookups.screens.map((item) => ({ value: String(item.id), label: item.name })) },
          { name: "email", label: "Correo", type: "text" },
          { name: "active", label: "Activo", type: "checkbox" },
        ]}
        toForm={(item) => ({ id: item.id, names: item.names, surnames: item.surnames, userName: item.userName, userType: item.userType, roleId: String(item.roleId), startScreenId: item.startScreenId ? String(item.startScreenId) : "", email: item.email, active: item.active })}
        emptyForm={{ names: "", surnames: "", userName: "", userType: "O", roleId: "", startScreenId: "", email: "", active: true }}
      /> : null}
      {visible.has("roles") ? <SecurityRolesScreen data={data} /> : null}
      {visible.has("modules") ? <EntityCrudSection
        title="Modulos"
        description="CRUD de modulos visibles en navegacion/seguridad."
        entity="modules"
        items={data.modules}
        getId={(item) => item.id}
        columns={[{ header: "Modulo", render: (item) => item.name }, { header: "Icono", render: (item) => item.icon || "-" }, { header: "Orden", render: (item) => item.order }]}
        fields={[{ name: "name", label: "Nombre", type: "text", required: true }, { name: "icon", label: "Icono", type: "text" }, { name: "order", label: "Orden", type: "number", required: true }, { name: "active", label: "Activo", type: "checkbox" }]}
        toForm={(item) => ({ id: item.id, name: item.name, icon: item.icon, order: item.order, active: item.active })}
        emptyForm={{ name: "", icon: "", order: 0, active: true }}
      /> : null}
      {visible.has("screens") ? <EntityCrudSection
        title="Pantallas"
        description="CRUD de pantallas asociadas a modulos."
        entity="screens"
        items={data.screens}
        getId={(item) => item.id}
        columns={[{ header: "Pantalla", render: (item) => item.name }, { header: "Modulo", render: (item) => item.module }, { header: "Ruta", render: (item) => item.route || "-" }]}
        fields={[{ name: "name", label: "Nombre", type: "text", required: true }, { name: "moduleId", label: "Modulo", type: "select", required: true, options: data.lookups.modules.map((item) => ({ value: String(item.id), label: item.name })) }, { name: "route", label: "Ruta", type: "text" }, { name: "controller", label: "Controlador", type: "text" }, { name: "actionName", label: "Accion", type: "text" }, { name: "icon", label: "Icono", type: "text" }, { name: "order", label: "Orden", type: "number", required: true }, { name: "active", label: "Activo", type: "checkbox" }]}
        toForm={(item) => ({ id: item.id, name: item.name, moduleId: String(item.moduleId), route: item.route, controller: item.controller, actionName: item.action, icon: item.icon, order: item.order, active: item.active })}
        emptyForm={{ name: "", moduleId: "", route: "", controller: "", actionName: "", icon: "", order: 0, active: true }}
      /> : null}
      {visible.has("permissions") ? <EntityCrudSection
        title="Permisos"
        description="CRUD de permisos por pantalla."
        entity="permissions"
        items={data.permissions}
        getId={(item) => item.id}
        columns={[{ header: "Permiso", render: (item) => item.name }, { header: "Pantalla", render: (item) => item.screen }, { header: "Modulo", render: (item) => item.module }]}
        fields={[
          { name: "name", label: "Nombre", type: "text", required: true },
          { name: "screenId", label: "Pantalla", type: "select", required: true, options: data.lookups.screens.map((item) => ({ value: String(item.id), label: item.name })) },
          { name: "description", label: "Descripcion", type: "textarea" },
          { name: "canView", label: "Puede ver", type: "checkbox" },
          { name: "canCreate", label: "Puede crear", type: "checkbox" },
          { name: "canEdit", label: "Puede editar", type: "checkbox" },
          { name: "canDelete", label: "Puede eliminar", type: "checkbox" },
          { name: "canApprove", label: "Puede aprobar", type: "checkbox" },
          { name: "canCancel", label: "Puede anular", type: "checkbox" },
          { name: "canPrint", label: "Puede imprimir", type: "checkbox" },
          { name: "active", label: "Activo", type: "checkbox" },
        ]}
        toForm={(item) => ({ id: item.id, name: item.name, screenId: String(item.screenId), description: item.description, canView: item.canView, canCreate: item.canCreate, canEdit: item.canEdit, canDelete: item.canDelete, canApprove: item.canApprove, canCancel: item.canCancel, canPrint: item.canPrint, active: item.active })}
        emptyForm={{ name: "", screenId: "", description: "", canView: true, canCreate: false, canEdit: false, canDelete: false, canApprove: false, canCancel: false, canPrint: false, active: true }}
      /> : null}
      {visible.has("role-permissions") ? <EntityCrudSection
        title="Roles por permiso"
        description="Asignaciones entre roles y permisos de pantalla."
        entity="role-permissions"
        items={data.rolePermissions}
        getId={(item) => item.id}
        columns={[{ header: "Rol", render: (item) => item.roleName }, { header: "Permiso", render: (item) => item.permissionName }, { header: "Pantalla", render: (item) => `${item.module} · ${item.screen}` }]}
        fields={[
          { name: "roleId", label: "Rol", type: "select", required: true, options: data.lookups.roles.map((item) => ({ value: String(item.id), label: item.name })) },
          { name: "permissionId", label: "Permiso", type: "select", required: true, options: data.lookups.permissions.map((item) => ({ value: String(item.id), label: item.name })) },
          { name: "active", label: "Activo", type: "checkbox" },
        ]}
        toForm={(item) => ({ id: item.id, roleId: String(item.roleId), permissionId: String(item.permissionId), active: item.active })}
        emptyForm={{ roleId: "", permissionId: "", active: true }}
      /> : null}
    </div>
  )
}
