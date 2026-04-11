# MASU POS V2 - QA Checklist Phase 1

Goal: track functional readiness module-by-module before adding new features.

Legend:
- `[ ]` pending
- `[~]` in progress
- `[x]` done

---

## 0) Global Gates

- [x] Build passes (`npm run build`)
- [~] Login/session flow active and route protection enforced
- [ ] Role-based authorization enforced in menu + API + pages
- [ ] Error messages standardized (ES) across modules
- [ ] Responsive smoke pass (desktop/tablet/mobile)

---

## 1) Security

### 1.1 Login / Session
- [x] Login page shown when no session
- [x] Successful login creates active session in DB
- [x] Logout revokes DB session and clears cookies
- [x] Remember username option works
- [x] Default start route supported per user
- [ ] Invalid credentials UX copy finalized
- [ ] Session expiration UX flow verified

### 1.2 Users
- [~] CRUD basic flow
- [x] One user = one role (`Usuarios.IdRol`)
- [x] User default screen (`IdPantallaInicio`) available in form
- [ ] Duplicate username/email constraints verified
- [ ] Soft delete behavior verified

### 1.3 Roles / Permissions
- [~] Roles CRUD basic flow
- [~] Permissions CRUD basic flow
- [~] Role-Permissions CRUD basic flow
- [ ] Effective permission resolution by logged user
- [ ] Unauthorized route/API access blocked by role

---

## 2) Catalog

### 2.1 Masters
- [ ] Categories CRUD
- [ ] Product Types CRUD
- [ ] Units CRUD (base/factor validations)

### 2.2 Products
- [~] Products CRUD basic flow
- [ ] Unit combinations and alternates validation
- [ ] Price and required fields validation
- [ ] Soft delete behavior verified

---

## 3) Dining Room

### 3.1 Masters
- [ ] Areas CRUD
- [ ] Resource Types CRUD
- [ ] Resource Categories CRUD

### 3.2 Resources
- [~] Resources CRUD basic flow
- [ ] Resource state transitions validated
- [ ] Resource board reflects order status correctly

---

## 4) Orders

### 4.1 Tray by Table
- [x] Grid shows only tables with open orders
- [x] Row click opens detail panel
- [x] Right panel shows list-style order details
- [x] New order modal (table + items) works
- [x] Close single order action
- [x] Close all orders for resource action
- [ ] Progress action state transitions fully validated
- [ ] Tax/subtotal calculations cross-checked with DB

### 4.2 Rules
- [x] Multiple open orders per table supported
- [x] Customer reference on order (`ReferenciaCliente`)
- [ ] Edge cases (invalid items/zero qty/concurrent updates)

---

## 5) Cash Register

- [ ] Receive orders ready for charge
- [ ] Full/partial charge flow
- [ ] Session/cash drawer context (`IdCaja`) behavior
- [ ] Daily close baseline flow

---

## 6) Queries

- [ ] Operational query screens load correctly
- [ ] Filter combinations validated
- [ ] Performance sanity checks

---

## 7) Reports (Phase 1 baseline)

- [ ] Minimum reports available
- [ ] Date range filters
- [ ] Data consistency vs DB totals

---

## 8) Company / Future-Ready Data

- [x] `Empresa` table created
- [x] Admin UI for company data (RNC, razon social, contactos, logo)
- [x] Offline logo binary storage in SQL (`VARBINARY`) + upload endpoint
- [x] Company screen with edit mode (`Editar datos`) and protected fields by default
- [x] Login branding inherits company logo + trade name
- [x] Session table prepared for `IdCaja`, `IdSucursal`, `IdPuntoEmision`
- [ ] UI workflow to set session operational context

---

## Current Focus (Next)

1. Complete Security QA: Users + Roles + Permissions with authorization enforcement.
2. Validate login behavior in real browser sessions (happy path + invalid + logout + timeout).
3. Start Catalog master data full QA.
