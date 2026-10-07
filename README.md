# FinArk Paysprint Distributed Platform: Reference Architecture Blueprint

The **FinArk Paysprint Platform** is a production-grade, polyglot reference architecture designed to demonstrate how enterprise financial technology grids transition from traditional relational storage models to highly scalable, asynchronous, **Event-Driven Architectures (EDA)** backed by stateless perimeter security canopies.

The entire cluster operates within a secure, containerized private network mesh, combining a **Typescript/NestJS Edge Proxy**, long-running **Python sidecar synchronization daemons**, an immutable **Java 25/Spring Boot trading engine**, and an automated, alpha-numeric **PostgreSQL analytical warehouse**.

---

## 🏗️ Core Architectural Philosophy

Most technical sandboxes treat system components in strict isolation. This platform bridges that gap by modeling the complete, uncompromised lifecycle of a high-frequency financial transaction—from perimeter admission and pre-trade invariant checking to atomic append-only ledger allocation, trigger-based drift scanning, and asynchronous event streaming.

```text
  [ Inbound Edge REST Traffic ]
                │
                ▼ (Port 3000: Stateless Token Validation & O(1) Blacklist Sweep)
     [ NestJS api-gateway Proxy ]
                │
                ▼ (Private Mesh Link: Propagates Trust via X-User-Id Header)
     [ Spring Boot order-placement-service ]
                │
                ├─► 1. Pre-Trade Invariant Evaluation (Java 25 / JRE)
                ├─► 2. Append Intent to Immutable Ledger (MyBatis 3.x XML Mapper)
                │
                ▼ (PostgreSQL ACID Atomicity Boundary: Trigger Interception)
     [ Relational Data Layer Warehouse ]
                │
                ├─► 1. Synch-Settle Quantity Balance Cache (client_instrument)
                ├─► 2. Evaluate Tolerance Bands & Construct JSONB Event Frames
                │
                ▼ (Asynchronous Daemon Layer Polling: FOR UPDATE SKIP LOCKED)
     [ Python orchestrator-sidecar Poller ]
                │
                ▼ (Distributed Low-Latency Transport Core)
   [ Apache Kafka (KRaft Mode) Brokers ] ──► Topics: execution-ledger & compliance-alerts
```

---

## 🗺️ Project Roadmap & Milestone Progression

The platform is engineered across a progressive pedagogical toolchain designed to mirror the scaling challenges of live banking networks:

### 🟩 A. Completed Milestones
* **Milestone 1: Relational & Analytical Foundations (`db/core_ddl/`)**
  Established a lowercase PostgreSQL database tier standardized strictly to `UTC` with `GENERATED ALWAYS AS IDENTITY` primary keys. Hardened input perimeters with explicit non-zero, non-whitespace database check constraints. Engineered modular analytical view structures leveraging window function windowing (`SUM() OVER (PARTITION BY...)`) and row-number ranking to evaluate real-time model portfolio compliance and absolute asset drift variance without collapsing baseline visibility.
* **Milestone 2: Relational Ingestion & Read-Through Caching (`tasks/market_sync.py`)**
  Constructed a transaction-insulated market prefetch loop in Python. Bypassed transaction read-snapshot races by front-loading reference data mappings into local memory upfront. Configured an extreme-scale read-through caching pipeline that paginates security parameters into 25-item API chunk flights, hydrates the **Valkey memory grid** with a secure 1-hour pre-warm TTL buffer, and gracefully steps down to an aggressive 90-second maintenance lifecycle during live synchronization passes.
* **Milestone 3: Asynchronous Transactional Outbox Streaming (`tasks/outbox_poller.py`)**
  Shifted from direct table-mutation anti-patterns to an append-only outbox design. Designed an asynchronous Python event relayer coroutine utilizing non-blocking `asyncpg` and `aiokafka` driver configurations. Configured high-performance concurrency isolation primitives using `FOR UPDATE SKIP LOCKED` queries to poll pending binary JSONB records out of the database tier atomically. Implemented Inversion of Control (IoC) via anonymous callback closures to decouple scheduling mechanics, ensuring the poller self-reschedules dynamically only after completing its active disk workload.

### 🟨 B. Upcoming Sprints
* **Milestone 4: Downstream Consumption Microservices**
  Staging long-running reactive consumer daemons (such as an isolated *Clearing House Accounting Ledger* and a real-time *Advisor Dashboard Monitor*) to subscribe to our production Kafka topics and process published wire streams.
* **Milestone 5: Continuous Delivery Snapshot Caching**
  Transitioning static End-of-Day (EOD) historical regulatory reports to hardware-materialized views to eliminate high-volume runtime CPU thashing over core data tables.

---

## 📚 Technical Documentation Directory

The repository maintains an exhaustive index of architectural specifications and design rationale files. Review these modules to trace the low-level contracts governing individual cluster domains:

### Relational Layer & Analytics View Specs
* [`docs/01-understanding-the-demo.md`](docs/01-understanding-the-demo.md) – Native initialization mechanics and host network topology mappings.
* [`docs/02-understanding-views.md`](docs/02-understanding-views.md) – Decoupled UI logic and standard view design constraints.
* [`docs/03-model-compliance.md`](docs/03-model-compliance.md) – Comparative sum aggregation trade-offs (Inline Windows vs. Row Collapsing).
* [`docs/04-portfolio-audit.md`](docs/04-portfolio-audit.md) – Timeline auditing mechanics and the microsecond tie-breaking trap.
* [`docs/05-eod-regulatory.md`](docs/05-eod-regulatory.md) – Mitigating view processing bloat via administrative materialized refresh protocols.
* [`docs/06-drift-view.sql`](docs/06-drift-view.sql) – Database metrics mapping live asset variance math.
* [`docs/21-cash-settlement-architecture.md`](docs/21-cash-settlement-architecture.md) – Structural rules computing rolling T+1 available purchasing power.

### Security, Perimeter, & Trust Canopy Specs
* [`docs/06-security-audit-findings.md`](docs/06-security-audit-findings.md) – Initial risk report mapping credential, privilege, and parameter injection flaws.
* [`docs/07-remediation-docker-secrets.md`](docs/07-remediation-docker-secrets.md) – Hardening environments via file-based in-memory Docker Secrets.
* [`docs/08-remediation-least-privilege.md`](docs/08-remediation-least-privilege.md) – Database-level sandboxing (RBAC) isolating the `paysprint_app` role.
* [`docs/10-security-remediation-overview.md`](docs/10-security-remediation-overview.md) – Master audit remediation ledger and defense-in-depth parameters.
* [`docs/11-parameterized-injection-defenses.md`](docs/11-parameterized-injection-defenses.md) – Pre-compilation blueprints blocking raw SQL concatenation strings.
* [`docs/14-token-authorization-boundaries.md`](docs/14-token-authorization-boundaries.md) – Hybrid identity token validation and time-bounded memory blacklisting.
* [`docs/15-api-microgateway-routing.md`](docs/15-api-microgateway-routing.md) – Perimeter admission control and context-path reverse proxy middleware.
* [`docs/20-distributed-trust-invariants.md`](docs/20-distributed-trust-invariants.md) – High-order polyglot cross-language state invariants.

### Ingestion & Asynchronous Streaming Specs
* [`docs/09-immutable-transaction-ledger.md`](docs/09-immutable-transaction-ledger.md) – Philosophy governing append-only accounting and transactional outbox staging.
* [`docs/13-event-streaming-infrastructure.md`](docs/13-event-streaming-infrastructure.md) – KRaft metadata consensus structures, split-listener configuration maps, and provisioning sidecars.
* [`docs/17-market-ingestion-architecture.md`](docs/17-market-ingestion-architecture.md) – Eviction timelines, mutex protections, and synchronous caching contracts.
* [`docs/18-transactional-outbox-poller.md`](docs/18-transactional-outbox-poller.md) – Scoped multi-context canopies, row isolation primitives, and self-pacing loop lifecycles.

---

## ⚡ Global Dependency Stack & Technical Rationale

The platform selectively avoids monolithic runtime frameworks, pairing microservices with highly targeted native package drivers to achieve maximum execution velocity with a minimized cryptographic attack surface:

* **Eclipse Temurin JDK/JRE 25 (LTS) & Spring Boot 4.1.1**  
  *Usage:* Provisions our high-performance trading engine backend runtime. Chosen for its enterprise thread containment wrappers and graceful shutdown pipelines. Details: [`docs/16-polyglot-trust-canopy.md`](docs/16-polyglot-trust-canopy.md).
* **MyBatis 3.x Parameterized XML Mappers**  
  *Usage:* Handles type-safe relational database access inside the Java layer. Bypasses the heavy lookup caching bloat of traditional ORMs, compiling raw parameterized SQL blueprints directly down to the metal JDBC lanes. Details: [`docs/11-parameterized-injection-defenses.md`](docs/11-parameterized-injection-defenses.md).
* **NestJS & Node.js 24 (V8 Engine)**  
  *Usage:* Hosts our single-origin Microgateway perimeter firewall reverse proxy. Leverages the asynchronous, single-threaded non-blocking event loop to stream incoming TCP payloads down to internal microservices with ultra-low context-switching overhead. Details: [`docs/15-api-microgateway-routing.md`](docs/15-api-microgateway-routing.md).
* **Valkey 7.2 (High-Speed alpine RAM Data Grid)**  
  *Usage:* Hosts our shared in-memory keyspace mapping registry (`auth_session:*`) and hot-path asset pricing pipelines. Operates at O(1) mathematical complexity to complete token validation and session status sweeps in microseconds. Details: [`docs/14-token-authorization-boundaries.md`](docs/14-token-authorization-boundaries.md).
* **Apache Kafka 8.3 (Confluent CP-Platform Architecture)**  
  *   *Usage:* Serves as our enterprise distributed messaging bus topology. Enforces KRaft-mode consensus loops to manage cluster metadata natively, completely eliminating legacy ZooKeeper dependencies. Details: [`docs/13-event-streaming-infrastructure.md`](docs/13-event-streaming-infrastructure.md).
*   **Python 3.14 (Alpine Bytecode Runtime Environment)**  
  *   *Usage:* Drives the long-running sidecar orchestrator task manager heap. Uses pure-Python drivers (`pg8000`, `requests`) for low-risk edge services alongside compiled native C-extension drivers (`asyncpg`, `aiokafka`) to ensure maximum data throughput during transactional outbox sweeps. Details: [`docs/17-market-ingestion-architecture.md`](docs/17-market-ingestion-architecture.md).

---

## 🚀 Acquiring & Launching the Cluster Sandbox

### 1. Prerequisites & Virtual Workstation Requirements
*   **Operating System:** Linux Kernel environment (Ubuntu 22.04 LTS or native Alpine distribution verified).
*   **Container Architecture:** Docker Engine v24.0.0+ with BuildKit compilation enabled natively.
*   **Orchestration Engine:** Docker Compose v2.20.0+.
*   **Session State:** Active, authenticated Docker Hub user profile session (Execute **`docker login`** prior to running bootstrap scripts to prevent anonymous image pull quota restriction throttling locks across upstream Confluent and Eclipse base images).

### 2. Microcluster Orchestration Commands
The cluster ecosystem features location-independent bootstrap executables that automatically handle generating unique base64 secret tokens, configuring process environment variables, compiling native wheel dependencies, and monitoring internal service health check gates:

```bash
# Clone the master platform reference architecture repository branch
git clone https://github.com/NoelJB/FinArk.git
cd FinArk

# Grant executable shell validation rights on the cluster coordinator script
chmod u+x run-demo.sh

# BRANCH 1: Launch the persistent serving layer pre-populated with seeded demo accounts
./run-demo.sh --demo

# BRANCH 2: Launch a pristine, clean-room production topology (No seed accounts)
./run-demo.sh --serve

# BRANCH 3: Trigger the ephemeral automated integration regression testing loop pass
./run-demo.sh --tests
```

### 3. Monitoring Infrastructure Logs & Key Metrics
Once the cluster completes its multi-stage compilation loop and declares its status gates as healthy, trace live execution and database storage metrics using these three precise diagnostics commands:

```bash
# Stream unbuffered logging output directly from the sidecar task scheduler heap
docker logs -f orchestrator-sidecar

# Verify that the outbox table rows successfully stream and flip states natively to SENT
docker exec -it paysprint-postgres psql -U postgres -d paysprint -c "SELECT status, count(*) FROM outbox GROUP BY status;"

# Scan the hot-path memory grid cache to confirm all 557 symbols are live in RAM
docker exec -it paysprint-cache valkey-cli KEYS "market_price:*" | wc -l
```
