# FinArk Lesson: Apache Kafka Distributed Event Streaming Infrastructure

## 🧠 The Architectural Goal
Up to this point, our data engine has operated purely inside relational boundaries. When an append-only trade execution arrives, database triggers successfully calculate clearing balances and stage a snapshot packet inside our transactional outbox log. 

To bridge this data to the rest of the enterprise network, we must transition from passive database storage to an active event streaming topology. This chapter documents the multi-container choreography, routing rules, image selections, and automation structures used to stand up a production-grade Apache Kafka broker.

---

## 🏗️ Section 13.1: The KRaft Topology & Split-Listener Network Mapping

### 1. Eliminating ZooKeeper via Native KRaft Consensus
Historically, Apache Kafka relied on a separate infrastructure layer called Apache ZooKeeper to manage cluster metadata, coordinate broker consensus, and track partition states. ZooKeeper required separate containers, separate network ports, and introduced severe operational synchronization overhead.

FinArk implements **KRaft Mode** (Kafka Raft Metadata Mode). Under this architecture, the Kafka broker manages its own internal consensus log natively. It handles cluster state tracking internally within an isolated memory directory pool (`/tmp/kraft-combined-logs`), cutting container infrastructure overhead exactly in half.

### 2. Deconstructing the Listener Configuration Matrix
In cloud-native enterprise deployments, a message broker must simultaneously handle internal network queries from companion backend microservices while allowing external developer machines or analytics dashboards to connect. Attempting to route both traffic profiles over a single network port creates severe routing mapping errors.

FinArk resolves this by implementing an explicit **Split-Listener Configuration Mapping**:

* KAFKA_LISTENERS: Instructs the inner container interface to spin up three distinct network gateways: PLAINTEXT (internal traffic on port 29092), CONTROLLER (internal KRaft consensus routing on port 29093), and PLAINTEXT_HOST (host-facing mapping on port 9092).
* KAFKA_ADVERTISED_LISTENERS: The metadata token array passed back to connecting clients. Internal apps connect directly via the private network service address (PLAINTEXT://paysprint-kafka:29092), while local developer tools hook cleanly via the host interface (PLAINTEXT_HOST://localhost:9092).

---

## 🏗️ Section 13.2: Automated Multi-Topic Provisioning Sidecars

When a fresh Kafka container service spins up for the very first time, it initializes as a completely blank message broker—it holds zero network event streaming topics. If a backend application attempts to publish data records into a missing channel, the transaction will fail or lock while waiting for automatic topic creation rules, which is an unstable approach for enterprise production.

To guarantee a completely deterministic environment, FinArk integrates an **Automated Provisioning Sidecar Container** (paysprint-kafka-init):

* The Initialization Sidecar Pattern: We launch a separate, lightweight service that shares the internal virtual bridge network topology.
* Synchronization Dependency Gates: The sidecar loops and blocks its own execution until it validates that the primary Kafka broker container is online and responding.
* Topic Instantiation: Once verified, it executes native Kafka binary administrative scripts to establish our production event routing channels cleanly before any application connects:
  1. execution-ledger: Dedicated streaming pipeline for asset balances and TRADE_EXECUTED frames.
  2. compliance-alerts: Real-time compliance monitoring feed capturing DRIFT_ALERT messages.

---

## 🏗️ Section 13.3: Engineering Rationale: Image Strategy & Container Hardening

### Why Confluent Enterprise Images Over Raw Upstream Apache?
When deploying containerized message brokers, a common student misconception is that you should always pull the generic vanilla image from the parent open-source project (e.g., `apache/kafka`). For enterprise cloud-native software pipelines, FinArk intentionally standardizes on the Confluent Platform image (`confluentinc/cp-kafka`). This choice is driven by three critical architectural requirements:

1. Native Administrative Tooling & Built-in Health Gates
The raw upstream Apache container images frequently adopt bare, minimalist runtimes that completely strip away underlying command-line diagnostics. Confluent embeds the full array of native Kafka administrative shell binaries (such as `kafka-topics` and `kafka-configs`) directly into the core engine layer. This allows us to write elegant, localized container health check gates natively:
   test: ["CMD-SHELL", "kafka-topics --bootstrap-server localhost:9092 --list || exit 1"]
The cluster validates its own health continuously without requiring us to inject external shell utilities or scripts after boot.

2. Declared Environmental Configuration Mappings
Vanilla Apache Kafka requires engineers to maintain and edit physical `.properties` text configuration files hidden deep within the server's internal directories. Confluent engineered a brilliant boot-strapping abstraction wrapper that automatically intercepts standard container environment variables (prefixed with `KAFKA_`) and translates them into physical broker rules at runtime. This allows the platform to declare split-listener matrix maps, node IDs, and storage vectors cleanly inside a single, readable `docker-compose.yaml` text format.

3. Resolution of KRaft Quorum Volume Race Conditions
While Apache Kafka natively supports KRaft mode, vanilla Apache container wrappers frequently suffer from volatile race conditions when trying to auto-format storage logs on ephemeral docker volumes. Confluent's image collection is hard-tested across the financial technology industry, offering a highly resilient cluster metadata boot-cycle. Students can spin the sandbox up and down repeatedly without causing cluster state corruption.

---

## 🏗️ Section 13.4: Multi-Tenant Architecture & Domain Caching Boundaries

### Structural Boundary Isolation: Decoupling Database and Stream Profiles
A critical architectural pitfall in microservice staging environments is coupling test runners across distinct layers. If your data-tier testing harness blocks while waiting for an external event broker to initialize, the development loop breaks. 

FinArk completely decouples these concerns inside `docker-compose.yaml` using strict isolation primitives:
1. `--profile db_tests`: Spins up an ephemeral container (`test-runner`) that depends strictly and exclusively on the database service layer (`paysprint-postgres`). It executes our sequential relational assertion scripts with zero external dependencies.
2. Domain-Isolated Kafka Topics: Instead of utilizing a monolithic communication channel, events are siphoned into single-responsibility streaming streams:
   * execution-ledger: Captures the core financial facts of a trade, pushed by append-only ledger triggers.
   * compliance-alerts: Captures downstream regulatory violations when real-time positions shift past strict safety limits.

---

## 🏗️ Section 13.5: Blueprint Layout for Upcoming Services

Before executing code for background worker daemons, the multi-container microservices pipeline layout must be established to trace how rows leave a secure table across the streaming fabric to reactive consumers:

```text
[ Data Tier (ACID) ]                     [ Streaming Fabric ]            [ Downstream Tier (Eventual) ]
┌───────────────────────────┐            ┌──────────────────┐            ┌────────────────────────────┐
│ db/08: trade_execution    │            │                  │            │ app/advisor_dashboard.py   │
│            │ (Trigger)    │            │                  │            │ (Consumes:                 │
│            ▼              │            │ Topic:           │            │  compliance-alerts)        │
│ db/07: outbox (PENDING)   │ ──(Poll)──>│ compliance-alerts│ ──(Stream)─>│                            │
│            │              │            │                  │            └────────────────────────────┘
│            ▼              │            ├──────────────────┤            ┌────────────────────────────┐
│ app/poller.py             │            │ Topic:           │            │ app/client_ledger.py       │
│ (SKIP LOCKED Ingestion)   │ ──(Push)──>│ execution-ledger │ ──(Stream)─>│ (Consumes:                 │
│                           │            │                  │            │  execution-ledger)         │
└───────────────────────────┘            └──────────────────┘            └────────────────────────────┘
```

### 1. The Outbox Relayer (app/poller.py)
A background daemon that handles inter-process communication. It authenticates as the low-privilege `paysprint_app` role to execute `FOR UPDATE SKIP LOCKED` database queries. This isolates a single `PENDING` outbox entry, publishes its internal JSONB payload onto the target Kafka topic, and sets the state flag to `SENT` inside an atomic transaction block.

### 2. The Clearing House Accounting Consumer (app/client_ledger.py)
A downstream microservice that subscribes to the `execution-ledger` Kafka topic. On message arrival, it writes a long-term historical transaction log on an independent storage tier to decouple heavy client auditing tasks from the main database operations.

### 3. The Advisor Dashboard Monitor (app/advisor_dashboard.py)
A reactive real-time monitor service that listens to the `compliance-alerts` topic. It intercepts drift breach payloads and signals alerts to investment managers instantly, avoiding continuous polling overhead over core customer tables.
