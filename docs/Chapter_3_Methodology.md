# CHAPTER 3: METHODOLOGY

## Design and Development Methodology for a Logistics Warehouse and Inventory Tracking System

---

**Document type:** Thesis Chapter 3 (Methodology)  
**System name:** Logistics Warehouse and Inventory Tracking System  
**Tech stack:** MERN (MongoDB, Express.js, React, Node.js)  
**Related chapters:** Chapter 1 (Introduction), Chapter 2 (Literature Review), Chapter 4 (System Implementation), Chapter 5 (Conclusion and Recommendations)

---

## 3.1 Introduction

This chapter describes the **research methodology**, **system design approach**, and **technical framework** used to develop the **Logistics Warehouse and Inventory Tracking System** proposed in Chapter 1. Chapter 1 established that many organizations—especially small and medium enterprises—still depend on manual or semi-automated processes that limit real-time visibility, integration, and decision-making (Richards, 2018; Piasecki, 2009). Chapter 2 reviewed related literature on warehouse management systems (WMS), inventory control, and information technology in logistics.

The purpose of this chapter is to explain **how** the Logistics Warehouse and Inventory Tracking System was designed before its full implementation in Chapter 4. The methodology combines **design and development research** with an **iterative software engineering process** to produce a working web-based system that supports the general objective: *to create and implement an all-in-one logistics and inventory monitoring system that improves operational smoothness, accuracy, and speed.*

---

## 3.2 Research Design

### 3.2.1 Research approach

This study adopts an **applied research design** focused on solving a practical operational problem through the development of the **Logistics Warehouse and Inventory Tracking System**. It follows a **Design and Development Research (DDR)** approach common in Computer Science and Information Systems theses, where the primary output is a **functional software artifact** supported by documented analysis, design, and evaluation.

The research aligns with the following questions stated in Chapter 1:

| Research question | How this chapter addresses it |
|-------------------|-------------------------------|
| What are the problems with present warehouse and inventory solutions? | Requirements analysis (Section 3.4) |
| How can logistics and inventory monitoring be integrated into one system? | Unified architecture for the Logistics Warehouse and Inventory Tracking System (Sections 3.5–3.7) |
| Which technologies work best for real-time inventory tracking? | Technology selection (Section 3.6) |
| How can real-time tracking improve warehouse efficiency? | Movement engine and audit trail design (Section 3.7) |

### 3.2.2 Research strategy

The strategy involved four main activities:

1. **Problem identification** — Analysis of manual and disconnected systems (Chapter 1).
2. **Literature review** — Examination of WMS, RFID, barcodes, and integrated logistics (Chapter 2).
3. **System design** — Architecture, database, and modules for the Logistics Warehouse and Inventory Tracking System (this chapter).
4. **System implementation and testing** — Coding and verification (Chapter 4).

Data for design decisions came from **document analysis** (literature and WMS standards), **functional decomposition** of warehouse operations (receiving, storage, picking, shipping, transfer), and **iterative prototyping** during development.

### 3.2.3 Development methodology

The Logistics Warehouse and Inventory Tracking System was built using an **iterative and incremental** development model. Each iteration delivered a testable module before moving to the next.

**Table 3.1: Development phases of the Logistics Warehouse and Inventory Tracking System**

| Phase | Activities | Alignment with objectives |
|-------|------------|---------------------------|
| 1 | Environment setup, authentication, user roles | Secure access foundation |
| 2 | Product catalog, categories, warehouses | Master data for integrated tracking |
| 3 | Inventory lines, stock movements, audit log | Real-time stock visibility |
| 4 | Orders, dashboard, reports, PDF export | Decision support and reporting |
| 5 | Condition tracking, routing fields, validation | Accuracy and error reduction |
| 6 | Task assignment, warehouse staff linking, user profile | Workforce coordination |
| 7 | Real-time notifications (Socket.io), stock status engine | Live alerts and accurate KPIs |

---

## 3.3 Population and Sample (Context of Application)

The **Logistics Warehouse and Inventory Tracking System** is intended for organizations that manage physical stock across one or more warehouses—particularly **small and medium enterprises (SMEs)** that cannot afford commercial ERP/WMS licenses but require better control than paper-based methods.

The study does not use statistical sampling of human subjects. The **target context** is defined as:

- Businesses with multiple stock-keeping units (SKUs)
- One or more storage locations (warehouses)
- Need for inbound, outbound, transfer, and adjustment transactions
- Users in distinct roles (Admin, Supervisor, Staff)

The prototype is validated through **scenario-based testing** (Chapter 4), consistent with the limitation on prototype/simulated environments noted in Chapter 1.7.

---

## 3.4 Requirements Analysis

Requirements were derived from the problem statement (Chapter 1, Section 1.2), research objectives (Section 1.3), and scope (Section 1.6).

### 3.4.1 Functional requirements

**Table 3.2: Functional requirements — Logistics Warehouse and Inventory Tracking System**

| ID | Requirement | Problem addressed |
|----|-------------|-------------------|
| FR-01 | Secure login with role-based menus | Weak access control |
| FR-02 | Admin user management (create, edit, archive, promote) | Manual user records |
| FR-03 | Product registration without initial quantity | Catalog vs. stock separation |
| FR-04 | Multi-warehouse inventory by product and condition | Lack of real-time visibility |
| FR-05 | Inbound stock receipt with audit notes | Manual receiving errors |
| FR-06 | Outbound shipment with mandatory customer destination | Poor shipping traceability |
| FR-07 | Inter-warehouse stock transfer | Disconnected warehouse records |
| FR-08 | Stock adjustment and return handling | Inventory inconsistencies |
| FR-09 | Movement history with source and destination locations | No integrated audit trail |
| FR-10 | Block outbound/transfer when stock insufficient | Over-issue and shortages |
| FR-11 | Order creation and status tracking | Poor coordination with inventory |
| FR-12 | Dashboard KPIs and inventory reports | Weak decision support |
| FR-13 | Exportable PDF audit report | Manual reporting burden |
| FR-14 | Record creator on all major entities | Accountability |
| FR-15 | Barcode field on products (barcode-ready design) | Barcode scope (Chapter 1.6) |
| FR-16 | Staff task assignment (create, assign, track status) | Weak workforce coordination |
| FR-17 | Warehouse–staff assignment (staff linked to warehouses) | Incorrect task allocation |
| FR-18 | Real-time notifications for tasks, orders, inventory, warehouses | Delayed operational awareness |
| FR-19 | User profile (details, avatar, appearance preferences) | Limited personalization and accountability |
| FR-20 | Dynamic stock status (In Stock, Low Stock, Out of Stock) from live quantity | Stale or incorrect inventory labels |

### 3.4.2 Non-functional requirements

**Table 3.3: Non-functional requirements**

| ID | Category | Requirement |
|----|----------|-------------|
| NFR-01 | Security | Hashed passwords; JWT authentication; archived users blocked |
| NFR-02 | Usability | Clear web interface for warehouse staff |
| NFR-03 | Performance | Indexed database queries; responsive lists |
| NFR-04 | Reliability | Server-side validation on all stock changes |
| NFR-05 | Maintainability | Modular routes, controllers, services, models |
| NFR-06 | Scalability | MongoDB and REST API support data growth |
| NFR-07 | Auditability | Every movement logged with reason, routing, timestamp, user |
| NFR-08 | Real-time responsiveness | Socket.io push updates; no full-page refresh for alerts |
| NFR-09 | Data consistency | Stock status derived from quantity, not stored separately |

### 3.4.3 Scope alignment

In line with Chapter 1, Section 1.6, the design **includes**:

- Warehouse operations management
- Inventory tracking and control
- Barcode-ready product identification
- Design and construction of the Logistics Warehouse and Inventory Tracking System

The design **excludes**:

- Transportation management
- Supplier relationship management
- Full supply chain optimization

**Note on RFID:** Chapter 1 identifies RFID as a valuable tracking technology (Finkenzeller, 2010). The current prototype implements **real-time, database-driven tracking** through the web application and REST API. RFID hardware integration is a **future extension**; the architecture supports posting scan events to the same movement API without redesigning the core schema.

---

## 3.5 System Architecture of the Logistics Warehouse and Inventory Tracking System

### 3.5.1 Architectural overview

A **three-tier client–server architecture** was selected to separate presentation, business logic, and data storage.

```
┌──────────────────────────────────────────────────────────────┐
│  PRESENTATION TIER — React (Vite), Tailwind CSS, React Query │
│  Logistics Warehouse and Inventory Tracking System (Web UI)  │
│  Dashboard | Products | Inventory | Movements | Orders |     │
│  Tasks | Warehouses | Reports | Notifications | Profile       │
└────────────────────────────┬─────────────────────────────────┘
                             │ JSON / REST (HTTP) + WebSocket (Socket.io)
                             ▼
┌──────────────────────────────────────────────────────────────┐
│  APPLICATION TIER — Node.js, Express.js, Socket.io           │
│  Routes → Controllers → Services → Validation / DTOs         │
│  Middleware: JWT authentication, role authorization          │
│  Real-time: user rooms, notification + inventory emitters      │
└────────────────────────────┬─────────────────────────────────┘
                             │ Mongoose ODM
                             ▼
┌──────────────────────────────────────────────────────────────┐
│  DATA TIER — MongoDB                                         │
│  users | products | categories | warehouses | inventories |  │
│  movements | orders | tasks | notifications                │
└──────────────────────────────────────────────────────────────┘
```

**Figure 3.1: Three-tier architecture of the Logistics Warehouse and Inventory Tracking System**

### 3.5.2 Integration principle

Unlike disconnected tools described in Chapter 1.2, all modules share **one database** and **one API**. When a movement is recorded, inventory quantities and movement history update in the same logical operation, providing a **single source of truth** for stock levels and transactions.

### 3.5.3 RESTful API design

| Module | API prefix | Main operations |
|--------|------------|-----------------|
| Authentication | `/api/auth` | Login, session profile, first-admin setup |
| Users | `/api/users` | List, create, update, archive, promote (Admin) |
| Products | `/api/products` | CRUD, search |
| Categories | `/api/categories` | CRUD |
| Inventory | `/api/inventory` | Stock lines, warehouses, movements |
| Dashboard | `/api/dashboard` | Summary statistics |
| Orders | `/api/orders` | Order lifecycle |
| Reports | `/api/reports` | Inventory audit datasets |
| Tasks | `/api/tasks` | Task CRUD, assignment, status updates |
| Notifications | `/api/notifications` | List, read, delete, unread count |
| Profile | `/api/profile` | User profile and preferences |

**Real-time channel:** Socket.io (`/socket.io`) with JWT handshake; events include `notification:new`, `notifications:unread`, and `inventory:changed`.

---

## 3.6 Technology Selection

**Table 3.4: Technology stack — Logistics Warehouse and Inventory Tracking System**

| Component | Technology | Justification |
|-----------|------------|---------------|
| Runtime | Node.js (≥18) | Efficient I/O for web APIs |
| Backend framework | Express.js | Lightweight REST services |
| Database | MongoDB | Flexible documents for orders and movements |
| ODM | Mongoose | Schema validation, indexes, middleware |
| Frontend | React 18 + Vite | Component-based UI |
| Styling | Tailwind CSS | Modern enterprise appearance |
| HTTP client | Axios | API communication |
| State / cache | TanStack React Query | List refresh; invalidated on socket events |
| Real-time transport | Socket.io (server + client) | Instant notifications and inventory sync |
| Authentication | JSON Web Token (JWT) | Stateless session model; socket auth via token |
| Password security | bcryptjs | One-way password hashing |
| Charts | Recharts | Dashboard visualization |
| PDF export | jsPDF, jspdf-autotable | Audit reports |

**Table 3.5: Development tools**

| Tool | Purpose |
|------|---------|
| Cursor IDE / Visual Studio Code | Development |
| Git | Version control |
| npm | Package management |
| MongoDB (local or Atlas) | Database |
| Browser DevTools / Postman | Testing |

Environment variables: `MONGODB_URI`, `JWT_SECRET`, `PORT` (default 5000).

---

## 3.7 System Design

### 3.7.1 Conceptual database design

**Main entities:**

- **User** — system operators with roles
- **Category** — product classification
- **Product** — SKU master data (quantity not stored on product)
- **Warehouse** — storage location
- **Inventory** — quantity of product at warehouse for a given condition
- **Movement** — audit record of stock change
- **Order** — customer demand with line items and status history
- **Task** — warehouse work item assigned to staff (type, priority, due date, status history)
- **Notification** — per-user alert stored in MongoDB and pushed in real time

**Figure 3.2: Conceptual entity relationships**

```
Category ──< Product ──< Inventory >── Warehouse
                │              │
                │              └── (condition, quantity, bin)
                │
                ├──< Movement >── User
                │       └── (optional toWarehouse for TRANSFER)
                │
                └──< Order (items: product + warehouse + qty)

User ──< Task (assignedTo, assignedBy, createdBy)
User ──< Notification (recipient)
Warehouse ──< Task
Warehouse.assignedStaffIds ──> User (Staff)
```

### 3.7.2 Logical schema (key collections)

#### Users

| Field | Description |
|-------|-------------|
| username, email | Unique identifiers |
| password | Hashed; minimum length enforced |
| role | Admin, Supervisor, or Staff |
| archived | Prevents login when true |

#### Products

| Field | Description |
|-------|-------------|
| sku | Unique stock-keeping unit |
| name, description, categoryId | Catalog data |
| unitCost, unitPrice, minStockThreshold | Valuation and alerts |
| barcode | Optional; barcode-ready |
| createdBy | Audit reference to User |

#### Warehouses

| Field | Description |
|-------|-------------|
| name, location, capacity | Site definition |
| assignedStaffIds | Staff users allowed for that warehouse |
| createdBy | Audit reference |

#### Tasks

| Field | Description |
|-------|-------------|
| title, description, taskType | Work definition (e.g. Stock Count, Pack Order) |
| priority, status, dueDate | Scheduling and workflow |
| assignedToId, assignedById, createdById | Responsibility chain |
| warehouseId | Location of work |
| relatedOrderId, relatedProductId | Optional links to orders/inventory |
| statusHistory | Audit of status changes with user and timestamp |

#### Notifications

| Field | Description |
|-------|-------------|
| recipientId | Target user |
| title, message, type, priority, category | Alert content |
| read, readAt | Unread tracking |
| relatedEntityId, relatedEntityType, href | Deep link to module |
| dedupeKey | Prevents duplicate unread alerts |

#### Inventory

| Field | Description |
|-------|-------------|
| productId, warehouseId | Stock location |
| condition | Available / Good; Damaged / Defective; Under Inspection |
| quantity | Non-negative on-hand amount |
| binLocation | Optional physical slot |

**Unique index:** `(productId, warehouseId, condition)`

#### Movements

| Field | Description |
|-------|-------------|
| type | INBOUND, OUTBOUND, TRANSFER, RETURN, ADJUSTMENT |
| quantity, delta | Amount and signed change |
| reason | Notes (minimum 10 characters) |
| source_location, destination_location | Routing labels |
| warehouseId, toWarehouseId | Source and destination sites |
| userId, createdBy, timestamp | Audit trail |

### 3.7.3 Stock routing model (Odoo-style double-entry labels)

**Table 3.6: Movement routing rules**

| Movement type | source_location | destination_location |
|---------------|-----------------|----------------------|
| INBOUND | External Vendor / Supplier | Warehouse name |
| OUTBOUND | Warehouse name | Customer name |
| TRANSFER | From warehouse name | To warehouse name |
| RETURN | External Vendor / Supplier | Warehouse name |
| ADJUSTMENT | Warehouse name | Warehouse name |

### 3.7.4 Inventory and movement processing logic

- **Inbound / Return:** Increase quantity on inventory line (upsert if absent).
- **Outbound:** Verify stock; only **Available / Good** may ship; decrement; deny if insufficient.
- **Transfer:** Decrement source; increment destination; log both warehouses.
- **Adjustment:** Set target quantity; store computed delta.

Insufficient stock message: *"Transaction Denied: Insufficient stock available in this warehouse."*

### 3.7.5 Stock status derivation (not stored in database)

Inventory **status is never saved** as a permanent field. On every API response and UI render, status is **recalculated** from:

- `current_quantity` (sum of on-hand units per product × warehouse)
- `minStockThreshold` (from product master data)

**Table 3.6a: Stock status rules**

| Status | Rule |
|--------|------|
| Out of Stock | `current_quantity <= 0` |
| Low Stock | `current_quantity > 0` **and** `current_quantity <= minStockThreshold` |
| In Stock | `current_quantity > minStockThreshold` |

After any inbound, outbound, transfer, adjustment, or order-related stock change, the system:

1. Recomputes status for affected lines
2. Updates dashboard KPIs (total units, in stock, low stock, out of stock)
3. Emits `inventory:changed` over Socket.io so the UI refreshes without manual reload

This design prevents the error where quantity is zero but an old label still shows *Low Stock*.

### 3.7.6 Real-time notification design

Notifications are **persisted in MongoDB** and **delivered instantly** via Socket.io.

**Table 3.6b: Notification categories**

| Category | Example triggers |
|----------|------------------|
| task | Task assigned, status updated, completed, overdue |
| order | Order created; status → Processing, Packed, Shipped, Delivered |
| inventory | Low stock, out of stock, movement, adjustment, transfer |
| warehouse | New warehouse, staff assignment changes |
| user / system | User lifecycle, login alerts (Admin) |

**Role-based delivery:**

| Role | Receives |
|------|----------|
| Admin | Major operational and system alerts |
| Supervisor | Warehouse, task, order, inventory alerts |
| Staff | Direct alerts (e.g. assigned tasks, warehouse assignment) |

**Socket rooms:** Each authenticated user joins `user:{userId}` so events target only the intended recipient. Unread count updates on the navbar bell in real time.

### 3.7.7 Module design

**Table 3.7: System modules**

| Module | Responsibility | Primary users |
|--------|----------------|---------------|
| Authentication | Login, JWT, session | All |
| User management | CRUD, archive, promote | Admin |
| User profile | Profile, avatar, appearance preferences | All |
| Product catalog | SKU, pricing, categories, images | All operational roles |
| Inventory tracking | Live stock by warehouse and condition; dynamic status | All operational roles |
| Stock movements | Inbound, outbound, transfer, return, adjustment | All operational roles |
| Warehouse management | Register warehouses; assign staff to sites | Admin, Supervisor |
| Tasks | Create, assign, monitor, complete warehouse tasks | Admin, Supervisor (create); Staff (own tasks) |
| Orders | Customer orders and status workflow | All operational roles |
| Notifications | Real-time alerts; full notification page | All |
| Dashboard | KPIs and summary | All |
| Reports | Audit trail, charts, PDF | Admin, Supervisor |

### 3.7.8 Role-based access control (RBAC)

**Table 3.8: Role permissions**

| Function | Admin | Supervisor | Staff |
|----------|-------|------------|-------|
| Dashboard, products, inventory, movements, orders, tasks | ✓ | ✓ | ✓ (tasks: own only) |
| Create / assign / edit tasks | ✓ | ✓ | — |
| Delete tasks | ✓ | — | — |
| Update own task status | ✓ | ✓ | ✓ |
| Create warehouse; assign staff to warehouse | ✓ | ✓ | — |
| Reports | ✓ | ✓ | — |
| User management | ✓ | — | — |
| Receive operational notifications | ✓ | ✓ | Assigned tasks only |

### 3.7.9 User interface design

- Sidebar navigation for major modules; profile link under Account
- Navbar notification bell with live unread count (Socket.io)
- Data tables with Created By and timestamps
- Move Stock modal: Inbound (+), Outbound (−), Transfer, Return
- Color-coded quantities (green inbound, red outbound)
- Stock status badges: green (In Stock), amber (Low Stock), red (Out of Stock)
- Dark/light mode via user appearance preferences
- Inline validation for notes, customer name, and stock availability

**Navigation (web application):**

| Menu | Route |
|------|-------|
| Dashboard | `/dashboard` |
| Products | `/products` |
| Inventory Tracking | `/inventory-tracking` |
| Stock Movements | `/stock-movements` |
| Warehouses | `/warehouses` |
| Orders | `/orders` |
| Tasks | `/tasks` (Staff: My Tasks) |
| Reports | `/reports` |
| Notifications | `/notifications` |
| Profile | `/profile` |
| User management | `/users` (Admin only) |

---

## 3.8 Data Collection and Analysis Procedures (Design Phase)

| Procedure | Description |
|-----------|-------------|
| Document review | Chapters 1 and 2 literature |
| Functional analysis | Receive, store, move, pick, ship workflows |
| Benchmarking | Standard WMS features |
| Prototyping | Incremental build and test |
| Design verification | Checklist against FR/NFR |

Implementation testing is documented in **Chapter 4: System Implementation**.

---

## 3.9 Ethical Considerations

- Passwords stored only in hashed form
- Test accounts should use fictional data unless consent is obtained
- Production deployment requires HTTPS and strong secrets
- Academic integrity: third-party libraries acknowledged

---

## 3.10 Limitations of the Methodology

1. Prototype context — controlled scenarios, not long-term multi-firm deployment
2. Time constraint — core WMS features prioritized over full RFID hardware
3. Resource constraint — open-source stack vs. commercial WMS
4. RFID scope — web/database real-time tracking; physical RFID readers not in prototype
5. Transportation excluded per Chapter 1.6

---

## 3.11 Chapter Summary

This chapter presented the **methodology** for designing and developing the **Logistics Warehouse and Inventory Tracking System**. An iterative MERN approach translated Chapter 1 problems into requirements, architecture, database design, and modules. The system separates product master data from warehouse stock lines, enforces condition-aware outbound rules, and records source/destination routing on every movement.

Additional design elements include **staff task assignment** linked to warehouses, a **real-time notification layer** (Socket.io + MongoDB), **dynamic stock status** derived from live quantities, and **role-based delivery** of alerts. Together, these support faster coordination between supervisors and warehouse staff without relying on manual refresh or disconnected tools.

**Chapter 4** presents the implementation of this system, including source code structure, user interfaces, and testing.

---

## Appendix A: Alignment with Chapter 1

| Chapter 1 section | Chapter 3 coverage |
|-------------------|-------------------|
| 1.2 Problem Statement | §3.4 Requirements |
| 1.3 Objectives | §3.2, §3.4, §3.7 |
| 1.4 Research Questions | §3.2.1 |
| 1.5 Significance | §3.7.7, §3.10 |
| 1.6 Scope | §3.4.3 |
| 1.7 Limitations | §3.10 |
| 1.8 Organization (5 chapters) | §3.11 → Ch. 4–5 |

---

## Appendix B: Suggested figures for Word/PDF thesis

| Figure | Title |
|--------|-------|
| 3.1 | Three-tier architecture of the Logistics Warehouse and Inventory Tracking System |
| 3.2 | Conceptual entity-relationship diagram |
| 3.3 | Stock movement process flow (Inbound, Outbound, Transfer) |
| 3.4 | Use case diagram (Admin, Supervisor, Staff) |

---

## Appendix C: Project source reference

| Layer | Location in repository |
|-------|------------------------|
| Backend API | `server/` |
| Frontend UI | `client/` |
| Database models | `server/models/` |
| Movement logic | `server/utils/movementService.js` |
| Stock status rules | `server/utils/stockStatus.js` |
| Task services | `server/services/taskService.js` |
| Notifications + Socket.io | `server/services/notificationService.js`, `server/realtime/` |
| Move Stock UI | `client/src/components/inventory/MoveStockPanel.jsx` |
| Tasks UI | `client/src/pages/TasksPage.jsx` |
| Notifications UI | `client/src/components/layout/NotificationsDropdown.jsx` |

---

*End of Chapter 3 Documentation*
